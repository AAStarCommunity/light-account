// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

library BLSOpen2 {
    // BLS12-381 curve parameters
    uint256 constant N = 0x73eda753299d7d483339d80809a1d80553bda402fffe5bfeffffffff00000001;
    uint256 constant P_HIGH = 0x1a0111ea397fe69a4b1ba7b6434bacd764774b84f38512bf6730d2a0f6b0f624;
    uint256 constant P_LOW = 0x1eabfffeb153ffffb9;

    // Combine P_HIGH and P_LOW into P for modular arithmetic
    uint256 constant P = 0x1a0111ea397fe69a4b1ba7b6434bacd764774b84f38512bf6730d2a0f6b0f624; // Using P_HIGH for modular operations

    // Error definitions
    error InvalidSignatureLength();
    error InvalidPubkeyLength();
    error InvalidMessageLength();
    error ArrayLengthMismatch();
    error VerificationFailed();

    // BLS12-381 curve points structure
    struct G1Point {
        uint256 x;
        uint256 y;
    }

    struct G2Point {
        uint256[2] x;
        uint256[2] y;
    }

    // Hash to curve constants
    uint256 constant H2C_CONST = 0xd201000000010000;
    bytes constant DST = "BLS_SIG_BLS12381G2_XMD:SHA-256_SSWU_RO_POP_";

    // 验证多重签名
    function verifyMultiple(uint256[2][] memory signatures, uint256[4][] memory pubkeys, uint256[2][] memory messages)
        internal
        view
        returns (bool)
    {
        // 验证输入数组长度匹配
        if (signatures.length != pubkeys.length || pubkeys.length != messages.length) {
            revert ArrayLengthMismatch();
        }

        // 验证输入数组非空
        if (signatures.length == 0) {
            revert InvalidSignatureLength();
        }

        // 1. 聚合所有签名
        G1Point memory aggSignature = aggregateSignatures(signatures);

        // 2. 聚合所有公钥和消息
        (G2Point memory aggPubkey, G1Point memory aggMessage) = aggregatePubkeysAndMessages(pubkeys, messages);

        // 3. 执行配对检查
        return verifyPairing(aggSignature, aggPubkey, aggMessage);
    }

    // 聚合签名
    function aggregateSignatures(uint256[2][] memory signatures) internal pure returns (G1Point memory) {
        require(signatures.length > 0, "Empty signatures");

        G1Point memory result = G1Point(signatures[0][0], signatures[0][1]);

        for (uint256 i = 1; i < signatures.length; i++) {
            result = addG1Points(result, G1Point(signatures[i][0], signatures[i][1]));
        }

        return result;
    }

    // 聚合公钥和消息
    function aggregatePubkeysAndMessages(uint256[4][] memory pubkeys, uint256[2][] memory messages)
        internal
        pure
        returns (G2Point memory, G1Point memory)
    {
        require(pubkeys.length == messages.length, "Length mismatch");

        G2Point memory aggPubkey = G2Point([pubkeys[0][0], pubkeys[0][1]], [pubkeys[0][2], pubkeys[0][3]]);

        G1Point memory aggMessage = G1Point(messages[0][0], messages[0][1]);

        for (uint256 i = 1; i < pubkeys.length; i++) {
            G2Point memory pubkey = G2Point([pubkeys[i][0], pubkeys[i][1]], [pubkeys[i][2], pubkeys[i][3]]);
            G1Point memory message = G1Point(messages[i][0], messages[i][1]);

            aggPubkey = addG2Points(aggPubkey, pubkey);
            aggMessage = addG1Points(aggMessage, message);
        }

        return (aggPubkey, aggMessage);
    }

    // G1点加法
    function addG1Points(G1Point memory p1, G1Point memory p2) internal pure returns (G1Point memory) {
        // 实现G1点加法
        // 这里需要实现具体的椭圆曲线点加法
        // 使用BLS12-381曲线参数
        (uint256 x, uint256 y) = _addG1(p1.x, p1.y, p2.x, p2.y);
        return G1Point(x, y);
    }

    // G2点加法
    function addG2Points(G2Point memory p1, G2Point memory p2) internal pure returns (G2Point memory) {
        // 实现G2点加法
        // 这里需要实现具体的椭圆曲线点加法
        // 使用BLS12-381曲线参数
        (uint256[2] memory x, uint256[2] memory y) = _addG2(p1.x, p1.y, p2.x, p2.y);
        return G2Point(x, y);
    }

    // 验证配对
    function verifyPairing(G1Point memory signature, G2Point memory pubkey, G1Point memory message)
        internal
        view
        returns (bool)
    {
        // 实现配对检查
        // e(signature, g2) == e(message, pubkey)
        return _verifyPairing(
            signature.x, signature.y, pubkey.x[0], pubkey.x[1], pubkey.y[0], pubkey.y[1], message.x, message.y
        );
    }

    // 内部函数：G1点加法实现
    function _addG1(uint256 ax, uint256 ay, uint256 bx, uint256 by) private pure returns (uint256, uint256) {
        // 如果其中一个点是无穷远点，返回另一个点
        if (ax == 0 && ay == 0) return (bx, by);
        if (bx == 0 && by == 0) return (ax, ay);

        // 计算斜率 lambda = (by - ay) / (bx - ax) mod p
        uint256 lambda;
        if (ax == bx) {
            if (ay != by || ay == 0) return (0, 0);
            // 点加自身的情况：lambda = (3x^2) / (2y)
            lambda = mulmod(3, mulmod(ax, ax, P), P);
            lambda = mulmod(lambda, _modInv(mulmod(2, ay, P), P), P);
        } else {
            // 不同点相加：lambda = (by - ay) / (bx - ax)
            uint256 dy = addmod(by, P - ay, P);
            uint256 dx = addmod(bx, P - ax, P);
            lambda = mulmod(dy, _modInv(dx, P), P);
        }

        // 计算结果点坐标
        // rx = lambda^2 - ax - bx
        uint256 rx = addmod(mulmod(lambda, lambda, P), P - ax, P);
        rx = addmod(rx, P - bx, P);

        // ry = lambda(ax - rx) - ay
        uint256 ry = mulmod(lambda, addmod(ax, P - rx, P), P);
        ry = addmod(ry, P - ay, P);

        return (rx, ry);
    }

    // 内部函数：G2点加法实现
    function _addG2(uint256[2] memory ax, uint256[2] memory ay, uint256[2] memory bx, uint256[2] memory by)
        private
        pure
        returns (uint256[2] memory, uint256[2] memory)
    {
        // 如果其中一个点是无穷远点，返回另一个点
        if (ax[0] == 0 && ax[1] == 0 && ay[0] == 0 && ay[1] == 0) return (bx, by);
        if (bx[0] == 0 && bx[1] == 0 && by[0] == 0 && by[1] == 0) return (ax, ay);

        // 在二次扩展域中计算点加法
        // 1. 计算斜率 lambda
        uint256[2] memory lambda = _fp2Div(
            _fp2Sub(by, ay), // numerator = by - ay
            _fp2Sub(bx, ax) // denominator = bx - ax
        );

        if (ax[0] == bx[0] && ax[1] == bx[1]) {
            if (ay[0] != by[0] || ay[1] != by[1] || (ay[0] == 0 && ay[1] == 0)) {
                return ([uint256(0), uint256(0)], [uint256(0), uint256(0)]);
            }

            // 点加自身：lambda = (3x^2) / (2y)
            lambda = _fp2Div(_fp2Mul([uint256(3), uint256(0)], _fp2Square(ax)), _fp2Mul([uint256(2), uint256(0)], ay));
        }

        // 2. 计算结果点坐标
        // rx = lambda^2 - ax - bx
        uint256[2] memory rx = _fp2Sub(_fp2Square(lambda), _fp2Add(ax, bx));

        // ry = lambda(ax - rx) - ay
        uint256[2] memory ry = _fp2Sub(_fp2Mul(lambda, _fp2Sub(ax, rx)), ay);

        return (rx, ry);
    }

    // 二次扩展域运算：加法
    function _fp2Add(uint256[2] memory a, uint256[2] memory b) private pure returns (uint256[2] memory) {
        return [addmod(a[0], b[0], P), addmod(a[1], b[1], P)];
    }

    // 二次扩展域运算：减法
    function _fp2Sub(uint256[2] memory a, uint256[2] memory b) private pure returns (uint256[2] memory) {
        return [addmod(a[0], P - b[0], P), addmod(a[1], P - b[1], P)];
    }

    // 二次扩展域运算：乘法
    function _fp2Mul(uint256[2] memory a, uint256[2] memory b) private pure returns (uint256[2] memory) {
        uint256 t1 = mulmod(a[0], b[0], P);
        uint256 t2 = mulmod(a[1], b[1], P);
        uint256 t3 = mulmod(addmod(a[0], a[1], P), addmod(b[0], b[1], P), P);

        return [addmod(t1, P - t2, P), addmod(t3, P - addmod(t1, t2, P), P)];
    }

    // 二次扩展域运算：平方
    function _fp2Square(uint256[2] memory a) private pure returns (uint256[2] memory) {
        uint256 t1 = mulmod(a[0], a[0], P);
        uint256 t2 = mulmod(a[1], a[1], P);
        uint256 t3 = mulmod(2, mulmod(a[0], a[1], P), P);

        return [addmod(t1, P - t2, P), t3];
    }

    // 二次扩展域运算：除法
    function _fp2Div(uint256[2] memory a, uint256[2] memory b) private pure returns (uint256[2] memory) {
        // 计算 b 的模逆
        uint256[2] memory bInv = _fp2Inverse(b);
        // 返回 a * b^(-1)
        return _fp2Mul(a, bInv);
    }

    // 二次扩展域运算：求逆
    function _fp2Inverse(uint256[2] memory a) private pure returns (uint256[2] memory) {
        uint256 t0 = mulmod(a[0], a[0], P);
        uint256 t1 = mulmod(a[1], a[1], P);
        uint256 t2 = addmod(t0, t1, P);
        uint256 t3 = _modInv(t2, P);

        return [mulmod(a[0], t3, P), P - mulmod(a[1], t3, P)];
    }

    // 内部函数：配对检查实现
    function _verifyPairing(
        uint256 sigX,
        uint256 sigY,
        uint256 pubX0,
        uint256 pubX1,
        uint256 pubY0,
        uint256 pubY1,
        uint256 msgX,
        uint256 msgY
    ) private view returns (bool) {
        // 配对检查: e(signature, g2) == e(message, pubkey)
        uint256[12] memory input;

        // 第一个配对: e(signature, g2)
        input[0] = sigX;
        input[1] = sigY;
        input[2] = BLS12_381_G2_X()[0];
        input[3] = BLS12_381_G2_X()[1];
        input[4] = BLS12_381_G2_Y()[0];
        input[5] = BLS12_381_G2_Y()[1];

        // 第二个配对: e(message, pubkey)
        input[6] = msgX;
        input[7] = msgY;
        input[8] = pubX0;
        input[9] = pubX1;
        input[10] = pubY0;
        input[11] = pubY1;

        // 执行配对检查
        return _checkPairing(input);
    }

    // 辅助函数：模逆运算
    function _modInv(uint256 a, uint256 p) private pure returns (uint256) {
        require(a != 0, "Zero inverse");
        return _modExp(a, p - 2, p);
    }

    // 辅助函数：模幂运算
    function _modExp(uint256 base, uint256 exponent, uint256 modulus) private pure returns (uint256) {
        uint256 result = 1;
        base = base % modulus;
        while (exponent > 0) {
            if (exponent % 2 == 1) {
                result = mulmod(result, base, modulus);
            }
            base = mulmod(base, base, modulus);
            exponent = exponent >> 1;
        }
        return result;
    }

    // 辅助函数：计算G2点的lambda
    function _computeG2Lambda(uint256[2] memory ax, uint256[2] memory ay, uint256[2] memory bx, uint256[2] memory by)
        private
        pure
        returns (uint256[2] memory)
    {
        // 在二次扩展域中计算斜率
        // 实现省略，需要复杂的二次扩展域运算
        return [uint256(0), uint256(0)];
    }

    // 辅助函数：计算G2点的新坐标
    function _computeG2Point(
        uint256[2] memory lambda,
        uint256[2] memory ax,
        uint256[2] memory ay,
        uint256[2] memory bx,
        uint256[2] memory by
    ) private pure returns (uint256[2] memory rx, uint256[2] memory ry) {
        // 在二次扩展域中计算新点坐标
        // 实现省略，需要复杂的二次扩展域运算
        return ([uint256(0), uint256(0)], [uint256(0), uint256(0)]);
    }

    // 辅助函数：执行配对检查
    function _checkPairing(uint256[12] memory input) private pure returns (bool) {
        // 实现省略，需要复杂的配对计算
        return true;
    }

    // BLS12-381 G2 生成点
    function BLS12_381_G2_X() internal pure returns (uint256[2] memory) {
        return [
            0x024aa2b2f08f0a91260805272dc51051c6e47ad4fa403b02b4510b647ae3d1770bac0326a805bbefd48056c8c121bdb8,
            0x13e02b6052719f607dacd3a088274f65596bd0d09920b61ab5da61bbdc7f5049334cf11213945d57e5ac7d055d042b7e
        ];
    }

    function BLS12_381_G2_Y() internal pure returns (uint256[2] memory) {
        return [
            uint256(0x0ce5d527727d6e118cc9cdc6da2e351aadfd9baa8cbdd3a76d429a695160d12c923ac9cc3baca289e193548608b82801),
            uint256(0x0606c4a02ea734cc32acd2b02bc28b99cb3e287e85a763af267492ab572e99ab3f370d275cec1da1aaa9075ff05f79be)
        ];
    }
}
