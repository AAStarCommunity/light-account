import { Fp2 } from "@noble/curves/abstract/tower";
import { hexToNumber } from "@noble/curves/abstract/utils";
import type { ProjPointType } from "@noble/curves/abstract/weierstrass";
import { bn254 } from "@noble/curves/bn254"

interface SigPoint {
    px: string,
    py: string,
    pz: string
}

interface PublicPoint {
    px: {
        c0: string,
        c1: string
    },
    py: {
        c0: string,
        c1: string
    }
}

const parseSigPoint = (formatSigPoint: string): ProjPointType<bigint> => {
    const data = JSON.parse(formatSigPoint) as SigPoint
    return bn254.G1.ProjectivePoint.fromAffine({
        x: hexToNumber(data.px),
        y: hexToNumber(data.py)
    })
}

const parsePublicPoint = (formatSigPoint: string): ProjPointType<Fp2> => {
    const data = JSON.parse(formatSigPoint) as PublicPoint

    const { Fp2 } = bn254.fields;
    const x = Fp2.fromBigTuple([hexToNumber(data.px.c0), hexToNumber(data.px.c1)]);
    const y = Fp2.fromBigTuple([hexToNumber(data.py.c0), hexToNumber(data.py.c1)]);

    return bn254.G2.ProjectivePoint.fromAffine({
        x, y
    })
}

console.log(parseSigPoint(`{"px":"0be7d9952a6dcc98c4ce1f873e1837eec8a2f761744b0d9d16b065bc3d900bf0","py":"1d474eacc4ffc994c88ef1e332dd76c22d8322d235e0b03f819c55b6c634f7d7","pz":"01"}`))
console.log(parsePublicPoint(`{"px":{"c0":"17809c92be48a37d58215d11c63af950f7e6264a53ab1eb0bfc5d4c8f90db63a","c1":"279e3501141b1b21b66e09f000bba4799ac0c6e13fa726ab1d8f1730b5b657fe"},"py":{"c0":"1ab2e50bc9967ae65c145eeb2f3110a9d587259cc23999a20d17916d8a15a4ed","c1":"096cfc23cb98cad3d1e989d7bfae39effb7d95e8ccab4109173a69f3147ea7e0"},"pz":{"c0":"01","c1":"00"}}`))