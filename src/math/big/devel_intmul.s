// @author Armando Faz


// +build !math_big_pure_go

#include "textflag.h"

#define MUL64x512N  \
	MULXQ  0(SI), AX,  R9;  ADCQ AX,  R8;  MOVQ  R8,  0(DI)  \
	MULXQ  8(SI), AX, R10;  ADCQ AX,  R9;  MOVQ  R9,  8(DI)  \
	MULXQ 16(SI), AX, R11;  ADCQ AX, R10;  MOVQ R10, 16(DI)  \
	MULXQ 24(SI), AX, R12;  ADCQ AX, R11;  MOVQ R11, 24(DI)  \
	MULXQ 32(SI), AX, R13;  ADCQ AX, R12;  MOVQ R12, 32(DI)  \ 
	MULXQ 40(SI), AX, R14;  ADCQ AX, R13;  MOVQ R13, 40(DI)  \
	MULXQ 48(SI), AX, R15;  ADCQ AX, R14;  MOVQ R14, 48(DI)  \
	MULXQ 56(SI), AX,  DX;  ADCQ AX, R15;  MOVQ R15, 56(DI)  \
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;  MOVQ  DX, R8 
	
#define MADD64x512N  \
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

// func intmadd512Nx512N(z, x, y []Word)
TEXT ·intmadd512Nx512N(SB),NOSPLIT,$0
	//Early return 
	// if len(x) == 0 then goto END
	MOVQ x_len+32(FP), DX
	CMPQ DX, $0
	JEQ L_END
	
	// if len(y) == 0 then goto END
	MOVQ y_len+56(FP), DX
	CMPQ DX, $0
	JEQ L_END

	MOVQ z+ 0(FP), DI
	MOVQ x+24(FP), SI
	MOVQ y+48(FP), BP

	MOVQ $0, R8
	MOVQ x_len+32(FP), BX
	SHRQ $3, BX
	JZ L_X8_Y1_END
	CLC
	L_X1TIMES_START:
		MOVQ 0(BP), DX
		MUL64x512N
		LEAQ 64(SI), SI
		LEAQ 64(DI), DI
		DECQ BX
	JNZ L_X1TIMES_START
	ADCQ $0, R8
	L_X8_Y1_END:
		
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
	
L_YTIMES:
	MOVQ z+ 0(FP), DI
	MOVQ x+24(FP), SI
	MOVQ y+48(FP), BP
	MOVQ y_len+56(FP), AX
	SUBQ CX, AX
	LEAQ (DI)(AX*8), DI
	LEAQ (BP)(AX*8), BP
	
	MOVQ $0, R8
	MOVQ x_len+32(FP), BX
	SHRQ $3, BX
	JZ L_X8_END
	CLC
	L_X8_START:
		MOVQ 0(BP), DX
		MADD64x512N
		LEAQ 64(SI), SI
		LEAQ 64(DI), DI
		DECQ BX
	JNZ L_X8_START
	ADCQ $0, R8
	L_X8_END:
		
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
	RET   // End of intmadd512Nx512N function

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

	MOVQ k+48(FP), AX
	MULQ (DI)
	MOVQ AX, BP
	
	MOVQ $0, R8
	MOVQ x_len+32(FP), BX
	SHRQ $3, BX
	JZ L_X8_END
	
	CLC
	L_X8_START:
		MOVQ BP, DX
		MADD64x512N
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
