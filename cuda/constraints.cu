#include <cuda/constraints.hh>
#include <cuda/kernels.hh>
#include <cuda/helper.hh>
#include <string.h>
#include <stdio.h>
#include <assert.h>

#define CSTR_VAL_2X     CSTR_NO,  CSTR_NO
#define CSTR_VAL_4X     CSTR_VAL_2X,  CSTR_VAL_2X
#define CSTR_VAL_8X     CSTR_VAL_4X,  CSTR_VAL_4X
#define CSTR_VAL_16X    CSTR_VAL_8X,  CSTR_VAL_8X
#define CSTR_VAL_32X    CSTR_VAL_16X, CSTR_VAL_16X
#define CSTR_VAL_64X    CSTR_VAL_32X, CSTR_VAL_32X
#define CSTR_VAL_128X   CSTR_VAL_64X, CSTR_VAL_64X
#define CSTR_VAL_256X   CSTR_VAL_128X, CSTR_VAL_128X
#define CSTR_VAL_512X   CSTR_VAL_256X, CSTR_VAL_256X


CUDA_DEVICE __constant__ uintptr_t  cstrData[CSTR_MAX_CSTR * 8] = {CSTR_VAL_512X, CSTR_VAL_512X};
CUDA_DEVICE __constant__ TVarType   cstrType[CSTR_MAX_VAR];
CUDA_DEVICE __constant__ Gecode::TQuantifier cstrQuan[CSTR_MAX_VAR];
CUDA_DEVICE __constant__ int        cstrDom[CSTR_MAX_VAR];

CUDA_DEVICE cstrFuncPtr     cstrTable[64] = {
        &cstrEq,       NULL,          NULL,          NULL,
        NULL,          NULL,          NULL,          NULL,

        &cstrAndNQ,    &cstrAndEQ,    &cstrAndLQ,    &cstrAndLE,
        &cstrAndGQ,    &cstrAndGR,    NULL,          NULL,

        &cstrOrNQ,     &cstrOrEQ,     &cstrOrLQ,     &cstrOrLE,
        &cstrOrGQ,     &cstrOrGR,     NULL,          NULL,

        &cstrImpNQ,    &cstrImpEQ,    &cstrImpLQ,    &cstrImpLE,
        &cstrImpGQ,    &cstrImpGR,    NULL,          NULL,

        &cstrXorNQ,    &cstrXorEQ,    &cstrXorLQ,    &cstrXorLE,
        &cstrXorGQ,    &cstrXorGR,    NULL,          NULL,

        &cstrPlusNQ,   &cstrPlusEQ,   &cstrPlusLQ,   &cstrPlusLE,
        &cstrPlusGQ,   &cstrPlusGR,   NULL,          NULL,

        &cstrTimesNQ,  &cstrTimesEQ,  &cstrTimesLQ,  &cstrTimesLE,
        &cstrTimesGQ,  &cstrTimesGR,  NULL,          NULL,

        &cstrLinearNQ, &cstrLinearEQ, &cstrLinearLQ, &cstrLinearLE,
        &cstrLinearGQ, &cstrLinearGR, NULL,          NULL
};

CUDA_HOST   void pushVarToGPU(TVarType * type, Gecode::TQuantifier * quant, size_t size) {
    assert(size < CSTR_MAX_VAR);
    CCR(cudaMemcpyToSymbol(cstrType, type, size * sizeof(TVarType)));
    CCR(cudaMemcpyToSymbol(cstrQuan, quant, size * sizeof(Gecode::TQuantifier)));
}

CUDA_HOST void pushDomToGPU(int * dom, size_t size) {
    assert(size < CSTR_MAX_VAR);
    CCR(cudaMemcpyToSymbol(cstrDom, dom, size * sizeof(int)));
}

CUDA_HOST void pushCstrToGPU(uintptr_t * cstrs, size_t size) {
    assert(size < (CSTR_MAX_CSTR * 8));
    CCR(cudaMemcpyToSymbol(cstrData, cstrs, size * sizeof(uintptr_t)));
}

CUDA_DEVICE bool cstrValidate(int * c) {
    for (size_t i = 0; cstrData[8 * i] != CSTR_NO && (8 * i) < CSTR_MAX_CSTR; ++i) {
        if (!cstrTable[cstrData[8 * i]](cstrData + (8 * i) + 1, c)) {
            return false;
        }
    }
    return true;
}

CUDA_DEVICE bool cstrEq(uintptr_t * data, int * c) {
    size_t v0 = (size_t) data[0];
    int    val = uint2int((unsigned int) data[1]);

    return c[v0] == val;
}

CUDA_DEVICE bool cstrAndEQ(uintptr_t * data, int * c) {
    bool p0 = (bool) data[0], p1 = (bool) data[2];
    size_t v0 = (size_t) data[1], v1 = (size_t) data[3], v2 = (size_t) data[4];

    return opAnd(p0, c[v0], p1, c[v1]) == c[v2];
}

CUDA_DEVICE bool cstrAndNQ(uintptr_t * data, int * c) {
    bool p0 = (bool) data[0], p1 = (bool) data[2];
    size_t v0 = (size_t) data[1], v1 = (size_t) data[3], v2 = (size_t) data[4];

    return opAnd(p0, c[v0], p1, c[v1]) != c[v2];
}

CUDA_DEVICE bool cstrAndGQ(uintptr_t * data, int * c) {
    bool p0 = (bool) data[0], p1 = (bool) data[2];
    size_t v0 = (size_t) data[1], v1 = (size_t) data[3], v2 = (size_t) data[4];

    return opAnd(p0, c[v0], p1, c[v1]) > c[v2];
}

CUDA_DEVICE bool cstrAndGR(uintptr_t * data, int * c) {
    bool p0 = (bool) data[0], p1 = (bool) data[2];
    size_t v0 = (size_t) data[1], v1 = (size_t) data[3], v2 = (size_t) data[4];

    return opAnd(p0, c[v0], p1, c[v1]) >= c[v2];
}

CUDA_DEVICE bool cstrAndLQ(uintptr_t * data, int * c) {
    bool p0 = (bool) data[0], p1 = (bool) data[2];
    size_t v0 = (size_t) data[1], v1 = (size_t) data[3], v2 = (size_t) data[4];

    return opAnd(p0, c[v0], p1, c[v1]) < c[v2];
}

CUDA_DEVICE bool cstrAndLE(uintptr_t * data, int * c) {
    bool p0 = (bool) data[0], p1 = (bool) data[2];
    size_t v0 = (size_t) data[1], v1 = (size_t) data[3], v2 = (size_t) data[4];

    return opAnd(p0, c[v0], p1, c[v1]) <= c[v2];
}


CUDA_DEVICE bool cstrOrEQ(uintptr_t * data, int * c) {
    bool p0 = (bool) data[0], p1 = (bool) data[2];
    size_t v0 = (size_t) data[1], v1 = (size_t) data[3], v2 = (size_t) data[4];

    return opOr(p0, c[v0], p1, c[v1]) == c[v2];
}

CUDA_DEVICE bool cstrOrNQ(uintptr_t * data, int * c) {
    bool p0 = (bool) data[0], p1 = (bool) data[2];
    size_t v0 = (size_t) data[1], v1 = (size_t) data[3], v2 = (size_t) data[4];

    return opOr(p0, c[v0], p1, c[v1]) != c[v2];
}

CUDA_DEVICE bool cstrOrGQ(uintptr_t * data, int * c) {
    bool p0 = (bool) data[0], p1 = (bool) data[2];
    size_t v0 = (size_t) data[1], v1 = (size_t) data[3], v2 = (size_t) data[4];

    return opOr(p0, c[v0], p1, c[v1]) > c[v2];
}

CUDA_DEVICE bool cstrOrGR(uintptr_t * data, int * c) {
    bool p0 = (bool) data[0], p1 = (bool) data[2];
    size_t v0 = (size_t) data[1], v1 = (size_t) data[3], v2 = (size_t) data[4];

    return opOr(p0, c[v0], p1, c[v1]) >= c[v2];
}

CUDA_DEVICE bool cstrOrLQ(uintptr_t * data, int * c) {
    bool p0 = (bool) data[0], p1 = (bool) data[2];
    size_t v0 = (size_t) data[1], v1 = (size_t) data[3], v2 = (size_t) data[4];

    return opOr(p0, c[v0], p1, c[v1]) < c[v2];
}

CUDA_DEVICE bool cstrOrLE(uintptr_t * data, int * c) {
    bool p0 = (bool) data[0], p1 = (bool) data[2];
    size_t v0 = (size_t) data[1], v1 = (size_t) data[3], v2 = (size_t) data[4];

    return opOr(p0, c[v0], p1, c[v1]) <= c[v2];
}

CUDA_DEVICE bool cstrImpEQ(uintptr_t * data, int * c) {
    bool p0 = (bool) data[0], p1 = (bool) data[2];
    size_t v0 = (size_t) data[1], v1 = (size_t) data[3], v2 = (size_t) data[4];

    return opImp(p0, c[v0], p1, c[v1]) == c[v2];
}

CUDA_DEVICE bool cstrImpNQ(uintptr_t * data, int * c) {
    bool p0 = (bool) data[0], p1 = (bool) data[2];
    size_t v0 = (size_t) data[1], v1 = (size_t) data[3], v2 = (size_t) data[4];

    return opImp(p0, c[v0], p1, c[v1]) != c[v2];
}

CUDA_DEVICE bool cstrImpGQ(uintptr_t * data, int * c) {
    bool p0 = (bool) data[0], p1 = (bool) data[2];
    size_t v0 = (size_t) data[1], v1 = (size_t) data[3], v2 = (size_t) data[4];

    return opImp(p0, c[v0], p1, c[v1]) > c[v2];
}

CUDA_DEVICE bool cstrImpGR(uintptr_t * data, int * c) {
    bool p0 = (bool) data[0], p1 = (bool) data[2];
    size_t v0 = (size_t) data[1], v1 = (size_t) data[3], v2 = (size_t) data[4];

    return opImp(p0, c[v0], p1, c[v1]) >= c[v2];
}

CUDA_DEVICE bool cstrImpLQ(uintptr_t * data, int * c) {
    bool p0 = (bool) data[0], p1 = (bool) data[2];
    size_t v0 = (size_t) data[1], v1 = (size_t) data[3], v2 = (size_t) data[4];

    return opImp(p0, c[v0], p1, c[v1]) < c[v2];
}

CUDA_DEVICE bool cstrImpLE(uintptr_t * data, int * c) {
    bool p0 = (bool) data[0], p1 = (bool) data[2];
    size_t v0 = (size_t) data[1], v1 = (size_t) data[3], v2 = (size_t) data[4];

    return opImp(p0, c[v0], p1, c[v1]) <= c[v2];
}

CUDA_DEVICE bool cstrXorEQ(uintptr_t * data, int * c) {
    bool p0 = (bool) data[0], p1 = (bool) data[2];
    size_t v0 = (size_t) data[1], v1 = (size_t) data[3], v2 = (size_t) data[4];

    return opXor(p0, c[v0], p1, c[v1]) == c[v2];
}

CUDA_DEVICE bool cstrXorNQ(uintptr_t * data, int * c) {
    bool p0 = (bool) data[0], p1 = (bool) data[2];
    size_t v0 = (size_t) data[1], v1 = (size_t) data[3], v2 = (size_t) data[4];

    return opXor(p0, c[v0], p1, c[v1]) != c[v2];
}

CUDA_DEVICE bool cstrXorGQ(uintptr_t * data, int * c) {
    bool p0 = (bool) data[0], p1 = (bool) data[2];
    size_t v0 = (size_t) data[1], v1 = (size_t) data[3], v2 = (size_t) data[4];

    return opXor(p0, c[v0], p1, c[v1]) > c[v2];
}

CUDA_DEVICE bool cstrXorGR(uintptr_t * data, int * c) {
    bool p0 = (bool) data[0], p1 = (bool) data[2];
    size_t v0 = (size_t) data[1], v1 = (size_t) data[3], v2 = (size_t) data[4];

    return opXor(p0, c[v0], p1, c[v1]) >= c[v2];
}

CUDA_DEVICE bool cstrXorLQ(uintptr_t * data, int * c) {
    bool p0 = (bool) data[0], p1 = (bool) data[2];
    size_t v0 = (size_t) data[1], v1 = (size_t) data[3], v2 = (size_t) data[4];

    return opXor(p0, c[v0], p1, c[v1]) < c[v2];
}

CUDA_DEVICE bool cstrXorLE(uintptr_t * data, int * c) {
    bool p0 = (bool) data[0], p1 = (bool) data[2];
    size_t v0 = (size_t) data[1], v1 = (size_t) data[3], v2 = (size_t) data[4];

    return opXor(p0, c[v0], p1, c[v1]) <= c[v2];
}

CUDA_DEVICE bool cstrPlusEQ(uintptr_t * data, int * c) {
    int n0 = uint2int((unsigned int) data[0]), n1 = uint2int((unsigned int) data[2]);
    size_t v0 = (size_t) data[1], v1 = (size_t) data[3], v2 = (size_t) data[4];

    return opPlus(n0, c[v0], n1, c[v1]) == c[v2];
}

CUDA_DEVICE bool cstrPlusNQ(uintptr_t * data, int * c) {
    int n0 = uint2int((unsigned int) data[0]), n1 = uint2int((unsigned int) data[2]);
    size_t v0 = (size_t) data[1], v1 = (size_t) data[3], v2 = (size_t) data[4];

    return opPlus(n0, c[v0], n1, c[v1]) != c[v2];
}

CUDA_DEVICE bool cstrPlusGQ(uintptr_t * data, int * c) {
    int n0 = uint2int((unsigned int) data[0]), n1 = uint2int((unsigned int) data[2]);
    size_t v0 = (size_t) data[1], v1 = (size_t) data[3], v2 = (size_t) data[4];

    return opPlus(n0, c[v0], n1, c[v1]) > c[v2];
}

CUDA_DEVICE bool cstrPlusGR(uintptr_t * data, int * c) {
    int n0 = uint2int((unsigned int) data[0]), n1 = uint2int((unsigned int) data[2]);
    size_t v0 = (size_t) data[1], v1 = (size_t) data[3], v2 = (size_t) data[4];

    return opPlus(n0, c[v0], n1, c[v1]) >= c[v2];
}

CUDA_DEVICE bool cstrPlusLQ(uintptr_t * data, int * c) {
    int n0 = uint2int((unsigned int) data[0]), n1 = uint2int((unsigned int) data[2]);
    size_t v0 = (size_t) data[1], v1 = (size_t) data[3], v2 = (size_t) data[4];

    return opPlus(n0, c[v0], n1, c[v1]) < c[v2];
}

CUDA_DEVICE bool cstrPlusLE(uintptr_t * data, int * c) {
    int n0 = uint2int((unsigned int) data[0]), n1 = uint2int((unsigned int) data[2]);
    size_t v0 = (size_t) data[1], v1 = (size_t) data[3], v2 = (size_t) data[4];

    return opPlus(n0, c[v0], n1, c[v1]) <= c[v2];
}

CUDA_DEVICE bool cstrTimesEQ(uintptr_t * data, int * c) {
    int n = uint2int((unsigned int) data[0]);
    size_t v0 = (size_t) data[1], v1 = (size_t) data[2], v2 = (size_t) data[3];

    return opTimes(n, c[v0], c[v1]) == c[v2];
}

CUDA_DEVICE bool cstrTimesNQ(uintptr_t * data, int * c) {
    int n = uint2int((unsigned int) data[0]);
    size_t v0 = (size_t) data[1], v1 = (size_t) data[2], v2 = (size_t) data[3];

    return opTimes(n, c[v0], c[v1]) != c[v2];
}

CUDA_DEVICE bool cstrTimesGQ(uintptr_t * data, int * c) {
    int n = uint2int((unsigned int) data[0]);
    size_t v0 = (size_t) data[1], v1 = (size_t) data[2], v2 = (size_t) data[3];

    return opTimes(n, c[v0], c[v1]) > c[v2];
}

CUDA_DEVICE bool cstrTimesGR(uintptr_t * data, int * c) {
    int n = uint2int((unsigned int) data[0]);
    size_t v0 = (size_t) data[1], v1 = (size_t) data[2], v2 = (size_t) data[3];

    return opTimes(n, c[v0], c[v1]) >= c[v2];
}

CUDA_DEVICE bool cstrTimesLQ(uintptr_t * data, int * c) {
    int n = uint2int((unsigned int) data[0]);
    size_t v0 = (size_t) data[1], v1 = (size_t) data[2], v2 = (size_t) data[3];

    return opTimes(n, c[v0], c[v1]) < c[v2];
}

CUDA_DEVICE bool cstrTimesLE(uintptr_t * data, int * c) {
    int n = uint2int((unsigned int) data[0]);
    size_t v0 = (size_t) data[1], v1 = (size_t) data[2], v2 = (size_t) data[3];

    return opTimes(n, c[v0], c[v1]) <= c[v2];
}

CUDA_DEVICE bool cstrLinearEQ(uintptr_t * data, int * c) {
    size_t * v = (size_t*) data[0], size = (size_t) data[1];
    size_t v0 = (size_t) data[2];
    int sum = 0;

    opLinear(v, size, sum);
    return sum == c[v0];
}

CUDA_DEVICE bool cstrLinearNQ(uintptr_t * data, int * c) {
    size_t * v = (size_t*) data[0], size = (size_t) data[1];
    size_t v0 = (size_t) data[2];
    int sum = 0;

    opLinear(v, size, sum);
    return sum != c[v0];
}

CUDA_DEVICE bool cstrLinearGQ(uintptr_t * data, int * c) {
    size_t * v = (size_t*) data[0], size = (size_t) data[1];
    size_t v0 = (size_t) data[2];
    int sum = 0;

    opLinear(v, size, sum);
    return sum > c[v0];
}

CUDA_DEVICE bool cstrLinearGR(uintptr_t * data, int * c) {
    size_t * v = (size_t*) data[0], size = (size_t) data[1];
    size_t v0 = (size_t) data[2];
    int sum = 0;

    opLinear(v, size, sum);
    return sum >= c[v0];
}

CUDA_DEVICE bool cstrLinearLQ(uintptr_t * data, int * c) {
    size_t * v = (size_t*) data[0], size = (size_t) data[1];
    size_t v0 = (size_t) data[2];
    int sum = 0;

    opLinear(v, size, sum);
    return sum < c[v0];
}

CUDA_DEVICE bool cstrLinearLE(uintptr_t * data, int * c) {
    size_t * v = (size_t*) data[0], size = (size_t) data[1];
    size_t v0 = (size_t) data[2];
    int sum = 0;

    opLinear(v, size, sum);
    return sum <= c[v0];
}
