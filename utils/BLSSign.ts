import { mod } from "@noble/curves/abstract/modular";
import { bn254 } from "@noble/curves/bn254"
import { bytesToHex, concatBytes, hexToBytes, numberToBytesBE } from "@noble/curves/abstract/utils";
import type { ProjPointType } from "@noble/curves/abstract/weierstrass";
import type { Fp2 } from "@noble/curves/abstract/tower";
import { parseArgs } from "util";

const { Fp12 } = bn254.fields;

const testPrivateKey = [
    "189b092782fb8eec32783ddcbf9da2f9fb57c76c3a72ec77adc83d559b1671c5",
    "2bd823d324a317aeba80adc25961777699e93dc004ca0f9d872b460d61929829",
    "0706ea366edc43dacbca11b6083d36890f3150ecaa02f12eec40fe8e3d1f5502",
    "1e2b123a407d3796a85dd9e9d5f94a71e6dad9a0680433bd09b38dcb0a2c6a59",
    "17c6c390e5cbabb10f10a92b94a7b73b0fe99ca3cf8e68d00b3d9dca75581967"
]

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

const { values, positionals } = parseArgs({
    args: Bun.argv,
    options: {
        digest: {
            type: 'string',
        },
    },
    // strict: true,
    allowPositionals: true,
});


let sigPoints: ProjPointType<bigint>[] = [];
let publicPoints: ProjPointType<Fp2>[] = [];
const Hm = getHm(BigInt(values.digest || "0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470"));

for (let i = 0; i < 3; i++) {
    const privateKey = hexToBytes(testPrivateKey[i]);
    const { sigPoint, publicPoint } = getSignaturePoint(privateKey, Hm);
    sigPoints.push(sigPoint);
    publicPoints.push(publicPoint);
}

const aggSignature = getAggSignature(sigPoints);
const result = verifySignature(aggSignature, publicPoints, Hm);
// console.log(result);
process.stdout.write(bytesToHex(getAggSignatureCalldata(aggSignature, publicPoints, Hm)))