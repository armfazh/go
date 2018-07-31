// +build !math_big_pure_go

#include "textflag.h"

#define MADD64x512 \
	MULXQ  0(SI), R8,  R9;      \
	MULXQ  8(SI), AX, R10;    ADDQ AX,  R9  \
	MULXQ 16(SI), AX, R11;    ADCQ AX, R10  \
	MULXQ 24(SI), AX, R12;    ADCQ AX, R11  \
	MULXQ 32(SI), AX, R13;    ADCQ AX, R12  \
	MULXQ 40(SI), AX, R14;    ADCQ AX, R13  \
	MULXQ 48(SI), AX, R15;    ADCQ AX, R14  \
	MULXQ 56(SI), AX,  DX;    ADCQ AX, R15  \
	;;;;;;;;;;;;;;;;;;;;;;    ADCQ $0,  DX  \
	ADDQ  0(DI),  R8;  MOVQ  R8,  0(DI) \
	ADCQ  8(DI),  R9;  MOVQ  R9,  8(DI) \
	ADCQ 16(DI), R10;  MOVQ R10, 16(DI) \
	ADCQ 24(DI), R11;  MOVQ R11, 24(DI) \
	ADCQ 32(DI), R12;  MOVQ R12, 32(DI) \
	ADCQ 40(DI), R13;  MOVQ R13, 40(DI) \
	ADCQ 48(DI), R14;  MOVQ R14, 48(DI) \
	ADCQ 56(DI), R15;  MOVQ R15, 56(DI) \
	ADCQ 64(DI),  DX;  MOVQ  DX, 64(DI) \
	

// func intmadd512x512(z, x, y []Word)
TEXT ·intmadd512x512(SB),NOSPLIT,$8
	// Push BP
	MOVQ BP, -8(SP)
	
	//Early return 
	// if len(x) == 0 OR len(y) == 0 then goto END
	MOVQ x_len+32(FP), AX
	MOVQ y_len+56(FP), DX
	ANDQ DX, AX
	JZ L_END
	
	MOVQ z+ 0(FP), DI
	MOVQ x+24(FP), SI
	MOVQ y+48(FP), BP
	
	MOVQ $8, CX
L_X_8TIMES:
	MOVQ 0(BP), DX
	MADD64x512
	ADDQ $8, DI
	ADDQ $8, BP
	SUBQ $1, CX
	JNZ	L_X_8TIMES
    
L_END:
	// Pop BP
	MOVQ -8(SP), BP
	RET   // End of intmadd512x512 function



/////////////////////////////////////////////////
// func intmadd64x512(z, x []Word, y Word, n int, cin Word) (cout Word)
TEXT ·intmadd64x512(SB),NOSPLIT,$8
	// Push BP
	MOVQ BP, -8(SP)
	
	//Early return 
	// if len(x) == 0 then goto END
	MOVQ x_len+32(FP), AX
	CMPQ AX, $0
	JEQ L_END
	
	MOVQ z+ 0(FP), DI
	MOVQ x+24(FP), SI
	MOVQ n+56(FP), CX
	
	MOVQ $0, AX
	
L_X_NTIMES:
	MOVQ y+48(FP), DX
	MULXQ  0(SI), R8,  R9;    ADDQ AX,  R8
	MULXQ  8(SI), AX, R10;    ADCQ AX,  R9
	MULXQ 16(SI), AX, R11;    ADCQ AX, R10
	MULXQ 24(SI), AX, R12;    ADCQ AX, R11
	MULXQ 32(SI), AX, R13;    ADCQ AX, R12
	MULXQ 40(SI), AX, R14;    ADCQ AX, R13  
	MULXQ 48(SI), AX, R15;    ADCQ AX, R14
	MULXQ 56(SI), AX,  DX;    ADCQ AX, R15
	;;;;;;;;;;;;;;;;;;;;;;    ADCQ $0,  DX
	XORQ AX, AX
	ADDQ  0(DI),  R8;  MOVQ  R8,  0(DI) 
	ADCQ  8(DI),  R9;  MOVQ  R9,  8(DI) 
	ADCQ 16(DI), R10;  MOVQ R10, 16(DI) 
	ADCQ 24(DI), R11;  MOVQ R11, 24(DI) 
	ADCQ 32(DI), R12;  MOVQ R12, 32(DI) 
	ADCQ 40(DI), R13;  MOVQ R13, 40(DI) 
	ADCQ 48(DI), R14;  MOVQ R14, 48(DI) 
	ADCQ 56(DI), R15;  MOVQ R15, 56(DI)
	ADCQ 64(DI),  DX;  MOVQ  DX, 64(DI)
	ADCQ     $0,  AX;

	ADDQ $64, DI
	ADDQ $64, SI
	SUBQ $1, CX
	JNZ	L_X_NTIMES
	
	MOVQ cin+64(FP), CX
	ADDQ CX, DX
	ADCQ $0, AX
	MOVQ DX, 0(DI)
	MOVQ AX, cout+72(FP)
    
L_END:
	// Pop BP
	MOVQ -8(SP), BP
	RET

