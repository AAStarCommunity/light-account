// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

import {BaseAccount} from "account-abstraction/core/BaseAccount.sol";
import {SIG_VALIDATION_FAILED, SIG_VALIDATION_SUCCESS} from "account-abstraction/core/Helpers.sol";
import {IEntryPoint} from "account-abstraction/interfaces/IEntryPoint.sol";
import {PackedUserOperation} from "account-abstraction/interfaces/PackedUserOperation.sol";
import {TokenCallbackHandler} from "account-abstraction/samples/callback/TokenCallbackHandler.sol";
// import {BLSOpen} from "account-abstraction/samples/bls/lib/BLSOpen.sol";
import {BLSOpen} from "../../lib/BLSOpen.sol";

import {UUPSUpgradeable} from "../external/solady/UUPSUpgradeable.sol";
import {ERC1271} from "./ERC1271.sol";

abstract contract BaseLightAccount is BaseAccount, TokenCallbackHandler, UUPSUpgradeable, ERC1271 {
    IEntryPoint internal immutable _ENTRY_POINT;

    /// @notice Signature types used for user operation validation and ERC-1271 signature validation.
    enum SignatureType {
        EOA,
        CONTRACT,
        CONTRACT_WITH_ADDR,
        BLS
    }

    error ArrayLengthMismatch();
    error CreateFailed();
    error InvalidSignatureType();
    error NotAuthorized(address caller);
    error ZeroAddressNotAllowed();

    modifier onlyAuthorized() {
        _onlyAuthorized();
        _;
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable virtual {}

    /// @notice Execute a transaction. This may only be called directly by an owner or by the entry point via a user
    /// operation signed by an owner.
    /// @param dest The target of the transaction.
    /// @param value The amount of wei sent in the transaction.
    /// @param func The transaction's calldata.
    function execute(address dest, uint256 value, bytes calldata func) external virtual onlyAuthorized {
        _call(dest, value, func);
    }

    /// @notice Execute a sequence of transactions.
    /// @param dest An array of the targets for each transaction in the sequence.
    /// @param func An array of calldata for each transaction in the sequence. Must be the same length as `dest`, with
    /// corresponding elements representing the parameters for each transaction.
    function executeBatch(address[] calldata dest, bytes[] calldata func) external virtual onlyAuthorized {
        if (dest.length != func.length) {
            revert ArrayLengthMismatch();
        }
        uint256 length = dest.length;
        for (uint256 i = 0; i < length; ++i) {
            _call(dest[i], 0, func[i]);
        }
    }

    /// @notice Execute a sequence of transactions.
    /// @param dest An array of the targets for each transaction in the sequence.
    /// @param value An array of value for each transaction in the sequence.
    /// @param func An array of calldata for each transaction in the sequence. Must be the same length as `dest`, with
    /// corresponding elements representing the parameters for each transaction.
    function executeBatch(address[] calldata dest, uint256[] calldata value, bytes[] calldata func)
        external
        virtual
        onlyAuthorized
    {
        if (dest.length != func.length || dest.length != value.length) {
            revert ArrayLengthMismatch();
        }
        uint256 length = dest.length;
        for (uint256 i = 0; i < length; ++i) {
            _call(dest[i], value[i], func[i]);
        }
    }

    /// @notice Creates a contract.
    /// @param value The value to send to the new contract constructor.
    /// @param initCode The initCode to deploy.
    /// @return createdAddr The created contract address.
    ///
    /// @dev Assembly procedure:
    ///     1. Load the free memory pointer.
    ///     2. Get the initCode length.
    ///     3. Copy the initCode from callata to memory at the free memory pointer.
    ///     4. Create the contract.
    ///     5. If creation failed (the address returned is zero), revert with CreateFailed().
    function performCreate(uint256 value, bytes calldata initCode)
        external
        payable
        virtual
        onlyAuthorized
        returns (address createdAddr)
    {
        assembly ("memory-safe") {
            let fmp := mload(0x40)
            let len := initCode.length
            calldatacopy(fmp, initCode.offset, len)

            createdAddr := create(value, fmp, len)

            if iszero(createdAddr) {
                mstore(0x00, 0x7e16b8cd)
                revert(0x1c, 0x04)
            }
        }
    }

    /// @notice Creates a contract using create2 deterministic deployment.
    /// @param value The value to send to the new contract constructor.
    /// @param initCode The initCode to deploy.
    /// @param salt The salt to use for the create2 operation.
    /// @return createdAddr The created contract address.
    ///
    /// @dev Assembly procedure:
    ///     1. Load the free memory pointer.
    ///     2. Get the initCode length.
    ///     3. Copy the initCode from callata to memory at the free memory pointer.
    ///     4. Create the contract using Create2 with the passed salt parameter.
    ///     5. If creation failed (the address returned is zero), revert with CreateFailed().
    function performCreate2(uint256 value, bytes calldata initCode, bytes32 salt)
        external
        payable
        virtual
        onlyAuthorized
        returns (address createdAddr)
    {
        assembly ("memory-safe") {
            let fmp := mload(0x40)
            let len := initCode.length
            calldatacopy(fmp, initCode.offset, len)

            createdAddr := create2(value, fmp, len, salt)

            if iszero(createdAddr) {
                mstore(0x00, 0x7e16b8cd)
                revert(0x1c, 0x04)
            }
        }
    }

    /// @notice Deposit more funds for this account in the entry point.
    function addDeposit() external payable {
        entryPoint().depositTo{value: msg.value}(address(this));
    }

    /// @notice Withdraw value from the account's deposit.
    /// @param withdrawAddress Target to send to.
    /// @param amount Amount to withdraw.
    function withdrawDepositTo(address payable withdrawAddress, uint256 amount) external onlyAuthorized {
        if (withdrawAddress == address(0)) {
            revert ZeroAddressNotAllowed();
        }
        entryPoint().withdrawTo(withdrawAddress, amount);
    }

    /// @notice Check current account deposit in the entry point.
    /// @return The current account deposit.
    function getDeposit() external view returns (uint256) {
        return entryPoint().balanceOf(address(this));
    }

    /// @inheritdoc BaseAccount
    function entryPoint() public view virtual override returns (IEntryPoint) {
        return _ENTRY_POINT;
    }

    /// @dev Must override to allow calls to protected functions.
    function _isFromOwner() internal view virtual returns (bool);

    /// @dev Revert if the caller is not any of:
    /// 1. The entry point
    /// 2. The account itself (when redirected through `execute`, etc.)
    /// 3. An owner
    function _onlyAuthorized() internal view {
        if (msg.sender != address(entryPoint()) && msg.sender != address(this) && !_isFromOwner()) {
            revert NotAuthorized(msg.sender);
        }
    }

    /// @dev Convert a boolean success value to a validation data value.
    /// @param success The success value to be converted.
    /// @return validationData The validation data value. 0 if success is true, 1 (SIG_VALIDATION_FAILED) if
    /// success is false.
    function _successToValidationData(bool success) internal pure returns (uint256 validationData) {
        return success ? SIG_VALIDATION_SUCCESS : SIG_VALIDATION_FAILED;
    }

    /// @dev Assembly procedure:
    ///     1. Execute the call, passing:
    ///         1. The gas
    ///         2. The target address
    ///         3. The call value
    ///         4. The pointer to the start location of the callData in memory
    ///         5. The length of the calldata
    ///     2. If the call failed, bubble up the revert reason by doing the following:
    ///         1. Load the free memory pointer
    ///         2. Copy the return data (which is the revert reason) to memory at the free memory pointer
    ///         3. Revert with the copied return data
    function _call(address target, uint256 value, bytes memory data) internal {
        assembly ("memory-safe") {
            let succ := call(gas(), target, value, add(data, 0x20), mload(data), 0x00, 0)

            if iszero(succ) {
                let fmp := mload(0x40)
                returndatacopy(fmp, 0x00, returndatasize())
                revert(fmp, returndatasize())
            }
        }
    }

    function _authorizeUpgrade(address newImplementation) internal view override onlyAuthorized {
        (newImplementation);
    }

    /// @notice BLS signature data structure
    struct BLSSignatureData {
        // uint8 signatureType; // Signature type at index 0
        uint16 nodeCount; // Number of participating nodes
        uint16 threshold; // Threshold count (currently same as nodeCount)
        uint256[2][] signatures; // Array of signatures
        uint256[4][] pubkeys; // Array of public keys
        uint256[2][] messages; // Array of messages
    }

    /// @dev Parse BLS signature data from bytes
    /// @param data Raw signature data
    /// @return Parsed BLS signature data
    function _parseBLSSignatureData(bytes memory data) internal pure returns (BLSSignatureData memory) {
        require(data.length >= 5, "Invalid signature length"); // 1 byte for type + 4 bytes for counts

        BLSSignatureData memory blsData;

        // Parse signature type and counts
        assembly {
            let first5Bytes := mload(add(data, 32))
            let signatureType := shr(248, first5Bytes) // First byte
            let nodeCount := shr(232, shl(8, first5Bytes)) // Next 2 bytes
            let threshold := shr(216, shl(24, first5Bytes)) // Next 2 bytes
        }
        // Correcting the assignment of parsed values to the struct
        blsData.nodeCount = uint16(blsData.nodeCount); // Assigning the parsed value to the struct
        blsData.threshold = uint16(blsData.threshold); // Assigning the parsed value to the struct

        // Correcting the requirement check for signature type
        require(blsData.nodeCount == blsData.threshold, "Invalid threshold");

        uint256 offset = 4; // Adjusted offset to start after counts
        uint256 itemSize = blsData.nodeCount;

        // Parse signatures
        blsData.signatures = new uint256[2][](itemSize);
        for (uint256 i = 0; i < itemSize; i++) {
            // Extract 32 bytes at a time using assembly for efficiency
            assembly {
                // Calculate the correct memory positions
                let dataPtr := add(add(data, 0x20), offset) // data.offset -> add(data, 0x20)
                let sig0 := mload(dataPtr)
                let sig1 := mload(add(dataPtr, 0x20))

                // Store in the signatures array
                let sigArrayPtr := mload(add(blsData, 0x20)) // Get pointer to signatures array
                let elementPtr := add(add(sigArrayPtr, 0x20), mul(i, 0x40)) // Calculate position for current element
                mstore(elementPtr, sig0)
                mstore(add(elementPtr, 0x20), sig1)
            }
            offset += 64;
        }

        // Parse public keys
        blsData.pubkeys = new uint256[4][](itemSize);
        for (uint256 i = 0; i < itemSize; i++) {
            assembly {
                // Calculate the base pointer for the current data position
                let dataPtr := add(add(data, 0x20), offset)

                // Load each 32-byte component
                let pk0 := mload(dataPtr)
                let pk1 := mload(add(dataPtr, 0x20))
                let pk2 := mload(add(dataPtr, 0x40))
                let pk3 := mload(add(dataPtr, 0x60))

                // Get pointer to pubkeys array
                let pubkeysArrayPtr := mload(add(blsData, 0x40)) // 0x40 is the slot for pubkeys in the struct
                // Calculate position for current element
                let elementPtr := add(add(pubkeysArrayPtr, 0x20), mul(i, 0x80)) // 0x80 = 4 * 32 bytes

                // Store the values
                mstore(elementPtr, pk0)
                mstore(add(elementPtr, 0x20), pk1)
                mstore(add(elementPtr, 0x40), pk2)
                mstore(add(elementPtr, 0x60), pk3)
            }
            offset += 128; // Move offset forward by 4 * 32 bytes
        }

        // Parse messages
        blsData.messages = new uint256[2][](itemSize);
        for (uint256 i = 0; i < itemSize; i++) {
            assembly {
                // Calculate the base pointer for current data position
                let dataPtr := add(add(data, 0x20), offset)

                // Load the two 32-byte components
                let msg0 := mload(dataPtr)
                let msg1 := mload(add(dataPtr, 0x20))

                // Get pointer to messages array
                let messagesArrayPtr := mload(add(blsData, 0x60)) // 0x60 is the slot for messages in the struct
                // Calculate position for current element
                let elementPtr := add(add(messagesArrayPtr, 0x20), mul(i, 0x40)) // 0x40 = 2 * 32 bytes

                // Store the values
                mstore(elementPtr, msg0)
                mstore(add(elementPtr, 0x20), msg1)
            }
            offset += 64; // Move offset forward by 2 * 32 bytes
        }

        return blsData;
    }

    /// @dev Validate BLS signature based on implementation from AAStarCommunity
    /// Reference: https://github.com/AAStarCommunity/account-contracts/blob/developing/src/BLS.Verifier.sol
    /// @param signature BLS signature
    /// @param pubkeys Array of BLS public keys
    /// @param messages Array of messages to verify
    /// @return True if signature is valid
    function _isValidBLSSignature(
        uint256[2] memory signature,
        uint256[4][] memory pubkeys,
        uint256[2][] memory messages
    ) internal view virtual returns (bool) {
        // Verify array lengths match
        require(pubkeys.length == messages.length, "Array length mismatch");
        require(pubkeys.length > 0, "Empty arrays not allowed");

        // Verify signature format
        require(signature[0] < BLS_MODULUS && signature[1] < BLS_MODULUS, "Invalid signature format");

        // Verify public keys format
        for (uint256 i = 0; i < pubkeys.length; i++) {
            require(
                pubkeys[i][0] < BLS_MODULUS && pubkeys[i][1] < BLS_MODULUS && pubkeys[i][2] < BLS_MODULUS
                    && pubkeys[i][3] < BLS_MODULUS,
                "Invalid public key format"
            );
        }

        // Verify messages format
        for (uint256 i = 0; i < messages.length; i++) {
            require(messages[i][0] < BLS_MODULUS && messages[i][1] < BLS_MODULUS, "Invalid message format");
        }

        // Call BLSOpen contract for signature verification
        return BLSOpen.verifyMultiple(signature, pubkeys, messages);
    }

    // BLS modulus constant
    uint256 constant BLS_MODULUS = 52435875175126190479447740508185965837690552500527637822603658699938581184513;
}
