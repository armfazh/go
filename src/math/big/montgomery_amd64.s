// @author Armando Faz

// +build !math_big_pure_go

#include "textflag.h"

#define INCR(n) \
	LEAQ (8*n)(SI), SI; \
	LEAQ (8*n)(DI), DI;

#define ACC(r) \
	ADCQ $0, r;

#define FOR(BEGIN,END,CTR,PRE,BODY,POST) \
	JZ END    \
	PRE;      \
BEGIN:        \
	BODY;     \
	DECQ CTR; \
	JNZ BEGIN \
	POST;     \
END:

#define MUL64x64_MULX(zz) \
	MULXQ zz(SI), AX, R9  \
	ADCQ AX, R8           \
	MOVQ R8, zz(DI)       \
	MOVQ R9, R8

#define MUL64x512_MULX \
	MULXQ  0(SI), AX,  R9;  ADCQ AX,  R8;  MOVQ  R8,  0(DI)  \
	MULXQ  8(SI), AX, R10;  ADCQ AX,  R9;  MOVQ  R9,  8(DI)  \
	MULXQ 16(SI), AX, R11;  ADCQ AX, R10;  MOVQ R10, 16(DI)  \
	MULXQ 24(SI), AX, R12;  ADCQ AX, R11;  MOVQ R11, 24(DI)  \
	MULXQ 32(SI), AX, R13;  ADCQ AX, R12;  MOVQ R12, 32(DI)  \ 
	MULXQ 40(SI), AX, R14;  ADCQ AX, R13;  MOVQ R13, 40(DI)  \
	MULXQ 48(SI), AX, R15;  ADCQ AX, R14;  MOVQ R14, 48(DI)  \
	MULXQ 56(SI), AX,  R8;  ADCQ AX, R15;  MOVQ R15, 56(DI)

#define MAD64x64_MULX(zz) \
	MULXQ zz(SI), AX, R9  \
	ADCQ AX, R8           \
	ADCQ $0, R9           \
	ADDQ zz(DI), R8       \ 
	MOVQ R8, zz(DI)       \
	MOVQ R9, R8

#define MAD64x512_MULX  \
	MOVQ BX, DX                           \
	MULXQ  0(SI), AX,  R9;  ADCQ AX,  R8  \
	MULXQ  8(SI), AX, R10;  ADCQ AX,  R9  \
	MULXQ 16(SI), AX, R11;  ADCQ AX, R10  \
	MULXQ 24(SI), AX, R12;  ADCQ AX, R11  \
	MULXQ 32(SI), AX, R13;  ADCQ AX, R12  \
	MULXQ 40(SI), AX, R14;  ADCQ AX, R13  \
	MULXQ 48(SI), AX, R15;  ADCQ AX, R14  \
	MULXQ 56(SI), AX,  DX;  ADCQ AX, R15  \
	;;;;;;;;;;;;;;;;;;;;;;  ADCQ $0,  DX  \
	ADDQ  0(DI),  R8;  MOVQ  R8,  0(DI)  \
	ADCQ  8(DI),  R9;  MOVQ  R9,  8(DI)  \
	ADCQ 16(DI), R10;  MOVQ R10, 16(DI)  \
	ADCQ 24(DI), R11;  MOVQ R11, 24(DI)  \
	ADCQ 32(DI), R12;  MOVQ R12, 32(DI)  \
	ADCQ 40(DI), R13;  MOVQ R13, 40(DI)  \
	ADCQ 48(DI), R14;  MOVQ R14, 48(DI)  \
	ADCQ 56(DI), R15;  MOVQ R15, 56(DI)  \
	;;;;;;;;;;;;;;;;;  MOVQ  DX, R8

#define MUL64x64_MULQ(zz) \
	MOVQ zz(SI), AX \
	ADCQ $0, R8     \
	MULQ BX         \
	ADDQ AX, R8     \
	MOVQ R8, zz(DI) \
	MOVQ DX, R8

#define MUL64x256_MULQ(z) \
	ADCQ $0, R8 \
	MOVQ (z+ 0)(SI), AX; MULQ BX; MOVQ AX, R13; MOVQ DX,  R9 \
	MOVQ (z+ 8)(SI), AX; MULQ BX; MOVQ AX, R14; MOVQ DX, R10 \
	MOVQ (z+16)(SI), AX; MULQ BX; MOVQ AX, R15; MOVQ DX, R11 \
	MOVQ (z+24)(SI), AX; MULQ BX; \
	ADDQ R13,  R8;  MOVQ  R8, (z+ 0)(DI) \
	ADCQ R14,  R9;  MOVQ  R9, (z+ 8)(DI) \
	ADCQ R15, R10;  MOVQ R10, (z+16)(DI) \
	ADCQ  AX, R11;  MOVQ R11, (z+24)(DI) \
	;;;;;;;;;;;;;;  MOVQ  DX, R8

#define MUL64x512_MULQ \
	MUL64x256_MULQ( 0) \
	MUL64x256_MULQ(32)

#define MAD64x64_MULQ(zz) \
	ADCQ $0, R8     \
	MOVQ zz(SI), AX \
	MULQ BX         \
	ADDQ AX, R8     \
	ADCQ $0, DX     \
	ADDQ zz(DI), R8 \
	MOVQ R8, zz(DI) \
	MOVQ DX, R8

#define MAD64x256_MULQ(z) \
	ADCQ $0, R8 \
	MOVQ (z+ 0)(SI), AX; MULQ BX; MOVQ AX, R13; MOVQ DX,  R9 \
	MOVQ (z+ 8)(SI), AX; MULQ BX; MOVQ AX, R14; MOVQ DX, R10 \
	MOVQ (z+16)(SI), AX; MULQ BX; MOVQ AX, R15; MOVQ DX, R11 \
	MOVQ (z+24)(SI), AX; MULQ BX; \
	ADDQ R13,  R8 \
	ADCQ R14,  R9 \
	ADCQ R15, R10 \
	ADCQ  AX, R11 \
	ADCQ  $0,  DX \
	ADDQ (z+ 0)(DI),  R8;  MOVQ  R8, (z+ 0)(DI) \
	ADCQ (z+ 8)(DI),  R9;  MOVQ  R9, (z+ 8)(DI) \
	ADCQ (z+16)(DI), R10;  MOVQ R10, (z+16)(DI) \
	ADCQ (z+24)(DI), R11;  MOVQ R11, (z+24)(DI) \
	;;;;;;;;;;;;;;;;;;;;;  MOVQ  DX, R8

#define MAD64x512_MULQ \
	MAD64x256_MULQ(0)  \
	MAD64x256_MULQ(32)

#define ITER_X1(MUL64,MUL512) \
	MOVQ $0, R8                                                  \
	MOVQ BX, DX                                                  \
	/* Loop for x (8 words per iteration). */                    \
	MOVQ x_len+32(FP), BP                                        \
	SHRQ $3, BP                                                  \
	FOR(LB_X8_Y1, LE_X8_Y1, BP, CLC, MUL512;  INCR(8), ACC(R8) ) \
	/* Loop for x (1 word per iteration).*/                      \
	MOVQ x_len+32(FP), BP                                        \
	ANDQ $7, BP                                                  \
	FOR(LB_X1_Y1, LE_X1_Y1, BP, CLC, MUL64(0);INCR(1), ACC(R8) ) 

#define ITER_XN(MAD64,MAD512) \
	MOVQ $0, R8                                                  \
	/* Loop for x (8 words per iteration). */                    \
	MOVQ x_len+32(FP), BP                                        \
	SHRQ $3, BP                                                  \
	FOR(LB_X8_YN, LE_X8_YN, BP, CLC, MAD512;  INCR(8), ACC(R8) ) \
	MOVQ BX, DX                                                  \
	/* Loop for x (1 word per iteration).*/                      \
	MOVQ x_len+32(FP), BP                                        \
	ANDQ $7, BP                                                  \
	FOR(LB_X1_YN, LE_X1_YN, BP, CLC, MAD64(0);INCR(1), ACC(R8) )

//////////////////////////////////////////////
// func intmult_mulx(z, x, y []Word)
// z+ 0(FP) | z_len+ 8(FP) | z_cap+16(FP)
// x+24(FP) | x_len+32(FP) | x_cap+40(FP)
// y+48(FP) | y_len+56(FP) | y_cap+64(FP)

// Assumptions:
//   1) len(z) == len(x)+len(y)
//   2) len(z),len(x), len(y) >= 0
//   3) MULX instruction is supported.
TEXT ·intmult_mulx(SB),NOSPLIT,$0

	// if len(x) == 0 then goto END
	MOVQ x_len+32(FP), AX
	CMPQ AX, $0
	JEQ L_END

	// if len(y) == 0 then goto END
	MOVQ y_len+56(FP), AX
	CMPQ AX, $0
	JEQ L_END

	// First y-iteration unrolled
	MOVQ z+ 0(FP), DI
	MOVQ x+24(FP), SI
	MOVQ y+48(FP), DX

	MOVQ 0(DX), BX
	ITER_X1(MUL64x64_MULX,MUL64x512_MULX)
	MOVQ R8, 0(DI)

	MOVQ y_len+56(FP), CX
	DECQ CX
	JZ LE_Y

	// Loop runs CX=len(y)-1 iterations.
LB_Y:
	MOVQ z+ 0(FP), DI
	MOVQ x+24(FP), SI
	MOVQ y+48(FP), DX
	MOVQ y_len+56(FP), AX
	SUBQ CX, AX
	LEAQ (DI)(AX*8), DI
	LEAQ (DX)(AX*8), DX

	MOVQ 0(DX), BX
	ITER_XN(MAD64x64_MULX,MAD64x512_MULX)
	MOVQ R8, 0(DI)

	DECQ CX
	JNZ	LB_Y
LE_Y:
L_END:
	RET   // End of intmult_mulx function

//////////////////////////////////////////
// func intmult_mulq(z, x, y []Word)
// z+ 0(FP) | z_len+ 8(FP) | z_cap+16(FP)
// x+24(FP) | x_len+32(FP) | x_cap+40(FP)
// y+48(FP) | y_len+56(FP) | y_cap+64(FP)

// Assumptions:
//   1) len(z) == len(x)+len(y)
//   2) len(z),len(x), len(y) >= 0
TEXT ·intmult_mulq(SB),NOSPLIT,$0

	// if len(x) == 0 then goto END
	MOVQ x_len+32(FP), AX
	CMPQ AX, $0
	JEQ L_END

	// if len(y) == 0 then goto END
	MOVQ y_len+56(FP), AX
	CMPQ AX, $0
	JEQ L_END

	// First y-iteration unrolled
	MOVQ z+ 0(FP), DI
	MOVQ x+24(FP), SI
	MOVQ y+48(FP), DX

	MOVQ 0(DX), BX
	ITER_X1(MUL64x64_MULQ,MUL64x512_MULQ)
	MOVQ R8, 0(DI)

	MOVQ y_len+56(FP), CX
	DECQ CX
	JZ LE_Y

	// Loop runs CX=len(y)-1 iterations.
LB_Y:
	MOVQ z+ 0(FP), DI
	MOVQ x+24(FP), SI
	MOVQ y+48(FP), DX
	MOVQ y_len+56(FP), AX
	SUBQ CX, AX
	LEAQ (DI)(AX*8), DI
	LEAQ (DX)(AX*8), DX

	MOVQ 0(DX), BX
	ITER_XN(MAD64x64_MULQ,MAD64x512_MULQ)
	MOVQ R8, 0(DI)

	DECQ CX
	JNZ	LB_Y
LE_Y:
L_END:
	RET   // End of intmult_mulq function

//////////////////////////////////////////
// func montReduction_mulx(z, x []Word, k Word) (cout Word)
// z+ 0(FP) | z_len+ 8(FP) | z_cap+16(FP) 
// x+24(FP) | x_len+32(FP) | x_cap+40(FP) 
// k+48(FP) | cout+56(FP) 
// Assumptions:
//   1) len(z) == 2*len(x)
//   2) len(z),len(x) >= 0
//   3) MULX instruction is supported.
TEXT ·montReduction_mulx(SB),NOSPLIT,$0
	// Setting by default output-carry to zero.
	MOVQ $0, cout+56(FP)

	// if len(x) == 0 then goto END
	MOVQ x_len+32(FP), CX
	CMPQ CX, $0
	JEQ LE_Y

LB_Y:
	MOVQ z+ 0(FP), DI
	MOVQ x+24(FP), SI
	MOVQ x_len+32(FP), AX
	SUBQ CX, AX
	LEAQ (DI)(AX*8), DI

	// Calculating q = X[i]*k mod 2^64
	MOVQ k+48(FP), BX
	IMULQ (DI), BX

	ITER_XN(MAD64x64_MULX, MAD64x512_MULX)

	// Accumulating last word
	MOVQ $0, AX
	ADDQ 0(DI), R8
	ADCQ $0, AX
	// Adding input carry to the (n+i)-th word
	ADDQ cout+56(FP), R8
	ADCQ $0, AX
	MOVQ R8, 0(DI)
	MOVQ AX, cout+56(FP)
	DECQ CX
	JNZ LB_Y	
LE_Y:
	RET // End of montReduction_mulx

//////////////////////////////////////////
// func montReduction_mulq(z, x []Word, k Word) (cout Word)
// z+ 0(FP) | z_len+ 8(FP) | z_cap+16(FP) 
// x+24(FP) | x_len+32(FP) | x_cap+40(FP) 
// k+48(FP) | cout+56(FP) 
// Assumptions:
//   1) len(z) == 2*len(x)
//   2) len(z),len(x) >= 0
TEXT ·montReduction_mulq(SB),NOSPLIT,$0
	// Setting by default output-carry to zero.
	MOVQ $0, cout+56(FP)

	// if len(x) == 0 then goto END
	MOVQ x_len+32(FP), CX
	CMPQ CX, $0
	JEQ LE_Y

LB_Y:
	MOVQ z+ 0(FP), DI
	MOVQ x+24(FP), SI
	MOVQ x_len+32(FP), AX
	SUBQ CX, AX
	LEAQ (DI)(AX*8), DI

	// Calculating q = X[i]*k mod 2^64
	MOVQ k+48(FP), BX
	IMULQ (DI), BX

	ITER_XN(MAD64x64_MULQ, MAD64x512_MULQ)

	// Accumulating last word
	MOVQ $0, AX
	ADDQ 0(DI), R8
	ADCQ $0, AX
	// Adding input carry to the (n+i)-th word
	ADDQ cout+56(FP), R8
	ADCQ $0, AX
	MOVQ R8, 0(DI)
	MOVQ AX, cout+56(FP)
	DECQ CX
	JNZ LB_Y	
LE_Y:
	RET // End of montReduction_mulq

#undef INCR
#undef ACC
#undef FOR
#undef MUL64x64_MULX
#undef MUL64x512_MULX
#undef MAD64x64_MULX
#undef MAD64x512_MULX
#undef MUL64x64_MULQ
#undef MUL64x256_MULQ
#undef MUL64x512_MULQ
#undef MAD64x64_MULQ
#undef MAD64x256_MULQ
#undef MAD64x512_MULQ
#undef ITER_X1
#undef ITER_XN
