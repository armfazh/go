// @author Armando Faz


// +build !math_big_pure_go

#include "textflag.h"

#define MUL64x512_MULX \
	MULXQ  0(SI), AX,  R9;  ADCQ AX,  R8;  MOVQ  R8,  0(DI)  \
	MULXQ  8(SI), AX, R10;  ADCQ AX,  R9;  MOVQ  R9,  8(DI)  \
	MULXQ 16(SI), AX, R11;  ADCQ AX, R10;  MOVQ R10, 16(DI)  \
	MULXQ 24(SI), AX, R12;  ADCQ AX, R11;  MOVQ R11, 24(DI)  \
	MULXQ 32(SI), AX, R13;  ADCQ AX, R12;  MOVQ R12, 32(DI)  \ 
	MULXQ 40(SI), AX, R14;  ADCQ AX, R13;  MOVQ R13, 40(DI)  \
	MULXQ 48(SI), AX, R15;  ADCQ AX, R14;  MOVQ R14, 48(DI)  \
	MULXQ 56(SI), AX,  R8;  ADCQ AX, R15;  MOVQ R15, 56(DI)


#define MADD64x512_MULX  \
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
	MOVQ y+48(FP), BP

	MOVQ $0, R8
	// Loop for x (8 words per iteration).
	MOVQ x_len+32(FP), BX
	SHRQ $3, BX
	JZ L_X8_Y1_END
	
	MOVQ 0(BP), DX
	CLC
L_X1TIMES_START:
		MUL64x512_MULX
		LEAQ 64(SI), SI
		LEAQ 64(DI), DI
		DECQ BX
	JNZ L_X1TIMES_START
	ADCQ $0, R8
L_X8_Y1_END:

	// Loop for x (1 word per iteration).
	MOVQ x_len+32(FP), BX
	ANDQ $0x7, BX
	JZ L_X1_Y1_END

	MOVQ 0(BP), DX
	CLC
L_X1_Y1_START:
		MULXQ 0(SI), AX, R9
		ADCQ AX, R8
		MOVQ R8, 0(DI)
		MOVQ R9, R8
		LEAQ 8(SI), SI
		LEAQ 8(DI), DI
		DECQ BX
	JNZ	L_X1_Y1_START
	ADCQ $0, R8
L_X1_Y1_END:
	MOVQ R8, 0(DI)
	MOVQ y_len+56(FP), CX
	SUBQ $1, CX
	JZ L_END

	// Loop for y runs CX=len(y)-1 iterations.
L_YTIMES:
	MOVQ z+ 0(FP), DI
	MOVQ x+24(FP), SI
	MOVQ y+48(FP), BP
	MOVQ y_len+56(FP), AX
	SUBQ CX, AX
	LEAQ (DI)(AX*8), DI
	LEAQ (BP)(AX*8), BP
	
	MOVQ $0, R8
	// Loop for x (8 words per iteration).
	MOVQ x_len+32(FP), BX
	SHRQ $3, BX
	JZ L_X8_END
	CLC
L_X8_START:
		MOVQ 0(BP), DX
		MADD64x512_MULX
		LEAQ 64(SI), SI
		LEAQ 64(DI), DI
		DECQ BX
	JNZ L_X8_START
	ADCQ $0, R8
L_X8_END:

	// Loop for x (1 word per iteration).
	MOVQ x_len+32(FP), BX
	ANDQ $0x7, BX
	JZ L_X_END
	MOVQ 0(BP), DX
	CLC
L_X1_START:
		MULXQ 0(SI), AX, R9
		ADCQ AX, R8
		ADCQ $0, R9
		ADDQ 0(DI), R8 
		MOVQ R8, 0(DI)
		MOVQ R9, R8
		LEAQ 8(SI), SI
		LEAQ 8(DI), DI
		DECQ BX
	JNZ	L_X1_START
	ADCQ $0, R8
L_X_END:
	MOVQ R8, 0(DI)
	DECQ CX
	JNZ	L_YTIMES
L_END:
	RET   // End of intmult_mulx function

#define MUL64x64_MULQ(zz) \
	MOVQ zz(SI), AX \
	ADCQ $0, R8     \
	MULQ BX         \
	ADDQ AX, R8     \
	MOVQ R8, zz(DI) \
	MOVQ DX, R8
	
#define MUL64x512_MULQ \
	MUL64x64_MULQ( 0); MUL64x64_MULQ( 8) \
	MUL64x64_MULQ(16); MUL64x64_MULQ(24) \
	MUL64x64_MULQ(32); MUL64x64_MULQ(40) \
	MUL64x64_MULQ(48); MUL64x64_MULQ(56) 

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
	MOVQ y_len+56(FP), CX

	MOVQ $0, R8
	MOVQ 0(DX), BX
	
	// Loop for x (8 words per iteration).
	MOVQ x_len+32(FP), BP
	SHRQ $3, BP
	JZ L_X8_Y1_END
	
	CLC
L_X1TIMES_START:
		MUL64x512_MULQ
		LEAQ 64(SI), SI
		LEAQ 64(DI), DI
		DECQ BP
	JNZ L_X1TIMES_START
	ADCQ $0, R8
L_X8_Y1_END:

	// Loop for x (1 word per iteration).
	MOVQ x_len+32(FP), BP
	ANDQ $0x7, BP
	JZ L_X1_Y1_END

	CLC
L_X1_Y1_START:
		MUL64x64_MULQ(0)
		LEAQ 8(SI), SI
		LEAQ 8(DI), DI
		DECQ BP
	JNZ	L_X1_Y1_START
	ADCQ $0, R8
L_X1_Y1_END:
	MOVQ R8, 0(DI)
	DECQ CX
	JZ L_END

	// Loop for y runs CX=len(y)-1 iterations.
L_YTIMES:
	MOVQ z+ 0(FP), DI
	MOVQ x+24(FP), SI
	MOVQ y+48(FP), DX
	MOVQ y_len+56(FP), AX
	SUBQ CX, AX
	LEAQ (DI)(AX*8), DI
	LEAQ (DX)(AX*8), DX
	
	MOVQ $0, R8
	MOVQ 0(DX), BX
	
	// Loop for x (8 words per iteration).
	MOVQ x_len+32(FP), BP
	SHRQ $3, BP
	JZ L_X8_END
	
	CLC
L_X8_START:
		MAD64x512_MULQ
		LEAQ 64(SI), SI
		LEAQ 64(DI), DI
		DECQ BP
	JNZ L_X8_START
	ADCQ $0, R8
L_X8_END:

	// Loop for x (1 word per iteration).
	MOVQ x_len+32(FP), BP
	ANDQ $0x7, BP
	JZ L_X_END

	CLC
L_X1_START:
		MAD64x64_MULQ(0)
		LEAQ 8(SI), SI
		LEAQ 8(DI), DI
		DECQ BP
	JNZ	L_X1_START
	ADCQ $0, R8
L_X_END:
	MOVQ R8, 0(DI)
	DECQ CX
	JNZ	L_YTIMES
L_END:
	RET   // End of intmult_mulq function

/////////////////////////////////////////////////
// func intmadd64x512N(z, x []Word, k Word) (cout Word)
TEXT ·intmadd64x512N(SB),NOSPLIT,$0
	MOVQ $0, cout+56(FP)
	//Early return 
	// if len(x) == 0 then goto END
	MOVQ x_len+32(FP), AX
	CMPQ AX, $0
	JEQ L_END

	MOVQ x_len+32(FP), CX
L_NTIMES	:
	MOVQ z+ 0(FP), DI
	MOVQ x+24(FP), SI
	MOVQ x_len+32(FP), AX
	SUBQ CX, AX
	LEAQ (DI)(AX*8), DI

	MOVQ k+48(FP), BP
	IMULQ (DI), BP
	
	MOVQ $0, R8
	MOVQ x_len+32(FP), BX
	SHRQ $3, BX
	JZ L_X8_END
	
	CLC
L_X8_START:
		MOVQ BP, DX
		MADD64x512_MULX
		LEAQ 64(SI), SI
		LEAQ 64(DI), DI
		DECQ BX
	JNZ L_X8_START
	ADCQ $0, R8
L_X8_END:
	MOVQ x_len+32(FP), BX
	ANDQ $0x7, BX
	JZ L_X_END

	MOVQ BP, DX
	CLC
L_X1_START:
		MULXQ 0(SI), AX, R9
		ADCQ AX, R8
		ADCQ $0, R9
		ADDQ 0(DI), R8 
		MOVQ R8, 0(DI)
		MOVQ R9, R8
		LEAQ 8(SI), SI
		LEAQ 8(DI), DI
		DECQ BX
	JNZ	L_X1_START
	ADCQ $0, R8
L_X_END:
	MOVQ $0, AX
	ADDQ 0(DI), R8
	ADCQ $0, AX
	ADDQ cout+56(FP), R8
	ADCQ $0, AX	
	MOVQ R8, 0(DI)
	MOVQ AX, cout+56(FP)	
	DECQ CX
	JNZ L_NTIMES		
L_END:
	RET // End of intmadd64x512N
