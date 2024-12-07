import { mod } from "@noble/curves/abstract/modular";
import { bn254 } from "@noble/curves/bn254"
import { bytesToHex, concatBytes, hexToBytes, numberToBytesBE, numberToHexUnpadded } from "@noble/curves/abstract/utils";
import type { ProjPointType } from "@noble/curves/abstract/weierstrass";
import type { Fp2 } from "@noble/curves/abstract/tower";
import { parseArgs } from "util";

const { Fp12 } = bn254.fields;

const testPrivateKey = "189b092782fb8eec32783ddcbf9da2f9fb57c76c3a72ec77adc83d559b1671c5"

export const getHm = (opHash: bigint) => {
    const ORDER = BigInt('21888242871839275222246405745257275088696311157297823662689037894645226208583');
    const hMNonce = mod(opHash, ORDER);
    const Hm = bn254.G1.ProjectivePoint.fromPrivateKey(hMNonce);
    return Hm;
}

export const getSignaturePoint = (privateKey: Uint8Array, Hm: ProjPointType<bigint>) => {
    const publicPoint = bn254.G2.ProjectivePoint.fromPrivateKey(privateKey);
    const sigPoint = Hm.multiply(bn254.G1.normPrivateKeyToScalar(privateKey));
    return { sigPoint, publicPoint };
}

export const getAggSignature = (signatures: ProjPointType<bigint>[]) => {
    const aggSignature = signatures.reduce((sum, s) => sum.add(s), bn254.G1.ProjectivePoint.ZERO);
    return aggSignature;
}

export const verifySignature = (
    aggSignature: ProjPointType<bigint>,
    publicPoints: ProjPointType<Fp2>[],
    Hm: ProjPointType<bigint>
) => {
    let pairs: any[] = [];
    pairs.push({ g1: aggSignature, g2: bn254.G2.ProjectivePoint.BASE });
    for (let i = 0; i < publicPoints.length; i++) {
        pairs.push({ g1: Hm, g2: publicPoints[i].negate() });
    }
    const f = bn254.pairingBatch(pairs);
    return Fp12.eql(f, Fp12.ONE) ? 1n : 0n;
}

export const getBigIntPoint = (point: ProjPointType<bigint>) => {
    return concatBytes(
        numberToBytesBE(point.x, 32),
        numberToBytesBE(point.y, 32),
    )
}

export const getFp2Point = (point: ProjPointType<Fp2>) => {
    return concatBytes(
        numberToBytesBE(point.x.c1, 32),
        numberToBytesBE(point.x.c0, 32),
        numberToBytesBE(point.y.c1, 32),
        numberToBytesBE(point.y.c0, 32),
    )
}

export const getAggSignatureCalldata = (
    aggSignature: ProjPointType<bigint>,
    publicPoints: ProjPointType<Fp2>[],
    Hm: ProjPointType<bigint>
) => {
    let calldata = concatBytes(getBigIntPoint(aggSignature), getFp2Point(bn254.G2.ProjectivePoint.BASE));
    for (let i = 0; i < publicPoints.length; i++) {
        calldata = concatBytes(calldata, getBigIntPoint(Hm), getFp2Point(publicPoints[i].negate()));
    }
    return calldata
}

export const formatPoint = (point: ProjPointType<bigint> | ProjPointType<Fp2>) => {
    const data = JSON.stringify(point, (key, value) =>
        typeof value === "bigint" ? numberToHexUnpadded(value) : value,
    );
    return data
}

const Hm = getHm(BigInt("0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470"));

const privateKey = hexToBytes(testPrivateKey);
const { sigPoint, publicPoint } = getSignaturePoint(privateKey, Hm);

console.log(publicPoint)
console.log(formatPoint(sigPoint))
console.log(formatPoint(publicPoint))