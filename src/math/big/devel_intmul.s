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
	// if len(x) == 0 OR len(y) == 0 then goto END
	MOVQ x_len+32(FP), AX
	MOVQ y_len+56(FP), DX
	ANDQ DX, AX
	JZ L_END

	MOVQ z+ 0(FP), DI
	MOVQ x+24(FP), SI
	MOVQ y+48(FP), BP
	
	MOVQ x_len+32(FP), BX
	ANDQ $0x7, BX
	XORQ R8, R8
	L_X1:	
		MULXQ 0(SI), AX, R9;  ADCQ AX, R8;  MOVQ R8, 0(DI); MOVQ  R9, R8 
		LEAQ 8(SI), SI
		LEAQ 8(DI), DI
		DECQ BX
	JNZ	L_X1TIMES
	MOVQ x_len+32(FP), BX
	MOVQ $3, AX
	SHRXQ AX, BX, BX
	L_X1TIMES:
		MOVQ 0(BP), DX
		MUL64x512N
		LEAQ 64(SI), SI
		LEAQ 64(DI), DI
		DECQ BX
	JNZ	L_X1TIMES
	ADCQ $0, R8
	MOVQ R8, 0(DI)
	RET
	MOVQ y_len+56(FP), CX
	SUBQ $1, CX
	
L_YTIMES:
	MOVQ z+ 0(FP), DI
	MOVQ x+24(FP), SI
	MOVQ y+48(FP), BP
	MOVQ y_len+56(FP), AX
	SUBQ CX, AX
	LEAQ (DI)(AX*8), DI
	LEAQ (BP)(AX*8), BP
	
	MOVQ x_len+32(FP), BX
	SHRQ $3, BX
	XORQ R8, R8
	L_XTIMES:
		MOVQ 0(BP), DX
		MADD64x512N
		LEAQ 64(SI), SI
		LEAQ 64(DI), DI
		DECQ BX
	JNZ	L_XTIMES
	ADCQ $0, R8
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

	MOVQ x_len+32(FP), BX
	SHRQ $3, BX
	MOVQ k+48(FP), AX
	MULQ (DI)
	MOVQ AX, BP
	XORQ R8, R8
	L_XTIMES:
		MOVQ BP, DX
		MADD64x512N
		LEAQ 64(SI), SI
		LEAQ 64(DI), DI
		DECQ BX
	JNZ L_XTIMES
	MOVQ $0, AX
	ADCQ 0(DI), R8
	ADCQ $0, AX
	ADDQ cout+56(FP), R8
	ADCQ $0, AX
	MOVQ R8, 0(DI)
	MOVQ AX, cout+56(FP)
	
	DECQ CX
	JNZ L_NTIMES	
		
L_END:
	RET // End of intmadd64x512N


////////////////////////////////////////////////
//   n=512 bits
////////////////////////////////////////////////
#define MADD64x512                          \
	MOVQ 0(BP), DX                          \
	MULXQ  0(SI), R8,  R9;                  \
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
	ADCQ     $0,  DX;  MOVQ  DX, 64(DI) \
	

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
// func intmadd64x512(z, x []Word, y Word, cin Word) (cout Word)
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

	XORQ R8, R8
	MOVQ y+48(FP), DX
	MADD64x512N
	LEAQ 64(SI), SI
	LEAQ 64(DI), DI
		
	MOVQ $0, AX
	ADCQ 0(DI), R8
	ADCQ $0, AX
	
	ADDQ cin+56(FP), R8
	ADCQ $0, AX
	
	MOVQ R8, 0(DI)
	MOVQ AX, cout+64(FP)
    
L_END:
	// Pop BP
	MOVQ -8(SP), BP
	RET
	
////////////////////////////////////////////////
//   n=1024 bits
////////////////////////////////////////////////
#define MADD64x1024 \
	MOVQ 0(BP), DX  \
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
	;;;;;;;;;;;;;;;;;  MOVQ  DX, R8 \
	MOVQ 0(BP), DX  \
	MULXQ  64(SI), AX,  R9;   ADCQ AX,  R8  \ 
	MULXQ  72(SI), AX, R10;   ADCQ AX,  R9  \
	MULXQ  80(SI), AX, R11;   ADCQ AX, R10  \
	MULXQ  88(SI), AX, R12;   ADCQ AX, R11  \
	MULXQ  96(SI), AX, R13;   ADCQ AX, R12  \
	MULXQ 104(SI), AX, R14;   ADCQ AX, R13  \
	MULXQ 112(SI), AX, R15;   ADCQ AX, R14  \
	MULXQ 120(SI), AX,  DX;   ADCQ AX, R15  \
	;;;;;;;;;;;;;;;;;;;;;;;   ADCQ $0,  DX  \
	ADDQ  64(DI),  R8;  MOVQ  R8,  64(DI) \
	ADCQ  72(DI),  R9;  MOVQ  R9,  72(DI) \
	ADCQ  80(DI), R10;  MOVQ R10,  80(DI) \
	ADCQ  88(DI), R11;  MOVQ R11,  88(DI) \
	ADCQ  96(DI), R12;  MOVQ R12,  96(DI) \
	ADCQ 104(DI), R13;  MOVQ R13, 104(DI) \
	ADCQ 112(DI), R14;  MOVQ R14, 112(DI) \
	ADCQ 120(DI), R15;  MOVQ R15, 120(DI) \
	ADCQ      $0,  DX;  MOVQ  DX, 128(DI) \

// func intmadd1024x1024(z, x, y []Word)
TEXT ·intmadd1024x1024(SB),NOSPLIT,$8
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
	
	MOVQ $16, CX
L_X_16TIMES:
	MADD64x1024
	ADDQ $8, DI
	ADDQ $8, BP
	SUBQ $1, CX
	JNZ	L_X_16TIMES
    
L_END:
	// Pop BP
	MOVQ -8(SP), BP
	RET   // End of intmadd1024x1024 function

/////////////////////////////////////////////////
// func intmadd64x1024(z, x []Word, y Word, cin Word) (cout Word)
TEXT ·intmadd64x1024(SB),NOSPLIT,$8
	// Push BP
	MOVQ BP, -8(SP)
	
	//Early return 
	// if len(x) == 0 then goto END
	MOVQ x_len+32(FP), AX
	CMPQ AX, $0
	JEQ L_END
	
	MOVQ z+ 0(FP), DI
	MOVQ x+24(FP), SI
		
	XORQ R8, R8
		
	MOVQ y+48(FP), DX	
	MADD64x512N
	LEAQ 64(SI), SI
	LEAQ 64(DI), DI
		
	MOVQ y+48(FP), DX
	MADD64x512N	
	LEAQ 64(SI), SI
	LEAQ 64(DI), DI
		
	MOVQ $0, AX
	ADCQ 0(DI), R8
	ADCQ $0, AX
	
	ADDQ cin+56(FP), R8
	ADCQ $0, AX
	
	MOVQ R8, 0(DI)
	MOVQ AX, cout+64(FP)

L_END:
	// Pop BP
	MOVQ -8(SP), BP
	RET  // End of intmadd64x1024 function
	
	
////////////////////////////////////////////////
//   n=1536 bits
////////////////////////////////////////////////

#define MADD64x1536 \
	MOVQ 0(BP), DX  \
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
	ADCQ     $0,  DX;  MOVQ  DX, R8 \
	MOVQ 0(BP), DX  \	
	MULXQ  64(SI), AX,  R9;    ADCQ AX,  R8  \ 
	MULXQ  72(SI), AX, R10;    ADCQ AX,  R9  \
	MULXQ  80(SI), AX, R11;    ADCQ AX, R10  \
	MULXQ  88(SI), AX, R12;    ADCQ AX, R11  \
	MULXQ  96(SI), AX, R13;    ADCQ AX, R12  \
	MULXQ 104(SI), AX, R14;    ADCQ AX, R13  \
	MULXQ 112(SI), AX, R15;    ADCQ AX, R14  \
	MULXQ 120(SI), AX,  DX;    ADCQ AX, R15  \
	;;;;;;;;;;;;;;;;;;;;;;;    ADCQ $0,  DX  \
	ADDQ  64(DI),  R8;  MOVQ  R8,  64(DI) \
	ADCQ  72(DI),  R9;  MOVQ  R9,  72(DI) \
	ADCQ  80(DI), R10;  MOVQ R10,  80(DI) \
	ADCQ  88(DI), R11;  MOVQ R11,  88(DI) \
	ADCQ  96(DI), R12;  MOVQ R12,  96(DI) \
	ADCQ 104(DI), R13;  MOVQ R13, 104(DI) \
	ADCQ 112(DI), R14;  MOVQ R14, 112(DI) \
	ADCQ 120(DI), R15;  MOVQ R15, 120(DI) \
	ADCQ     $0,   DX;  MOVQ  DX, R8 \
	MOVQ 0(BP), DX  \
	MULXQ 128(SI), AX,  R9;    ADCQ AX,  R8  \ 
	MULXQ 136(SI), AX, R10;    ADCQ AX,  R9  \
	MULXQ 144(SI), AX, R11;    ADCQ AX, R10  \
	MULXQ 152(SI), AX, R12;    ADCQ AX, R11  \
	MULXQ 160(SI), AX, R13;    ADCQ AX, R12  \
	MULXQ 168(SI), AX, R14;    ADCQ AX, R13  \
	MULXQ 176(SI), AX, R15;    ADCQ AX, R14  \
	MULXQ 184(SI), AX,  DX;    ADCQ AX, R15  \
	;;;;;;;;;;;;;;;;;;;;;;;    ADCQ $0,  DX  \
	ADDQ 128(DI),  R8;  MOVQ  R8, 128(DI) \
	ADCQ 136(DI),  R9;  MOVQ  R9, 136(DI) \
	ADCQ 144(DI), R10;  MOVQ R10, 144(DI) \
	ADCQ 152(DI), R11;  MOVQ R11, 152(DI) \
	ADCQ 160(DI), R12;  MOVQ R12, 160(DI) \
	ADCQ 168(DI), R13;  MOVQ R13, 168(DI) \
	ADCQ 176(DI), R14;  MOVQ R14, 176(DI) \
	ADCQ 184(DI), R15;  MOVQ R15, 184(DI) \
	ADCQ 192(DI),  DX;  MOVQ  DX, 192(DI) \

// func intmadd1536x1536(z, x, y []Word)
TEXT ·intmadd1536x1536(SB),NOSPLIT,$8
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
	
	MOVQ $24, CX
L_X_24TIMES:
	MADD64x1536
	ADDQ $8, DI
	ADDQ $8, BP
	SUBQ $1, CX
	JNZ	L_X_24TIMES
    
L_END:
	// Pop BP
	MOVQ -8(SP), BP
	RET   // End of intmadd1536x1536 function

/////////////////////////////////////////////////
// func intmadd64x1536(z, x []Word, y Word, cin Word) (cout Word)
TEXT ·intmadd64x1536(SB),NOSPLIT,$8
	// Push BP
	MOVQ BP, -8(SP)
	
	//Early return 
	// if len(x) == 0 then goto END
	MOVQ x_len+32(FP), AX
	CMPQ AX, $0
	JEQ L_END
	
	MOVQ z+ 0(FP), DI
	MOVQ x+24(FP), SI	
	MOVQ y+48(FP), DX
	
	MULXQ  0(SI), R8,  R9;      
	MULXQ  8(SI), AX, R10;    ADDQ AX,  R9  
	MULXQ 16(SI), AX, R11;    ADCQ AX, R10  
	MULXQ 24(SI), AX, R12;    ADCQ AX, R11  
	MULXQ 32(SI), AX, R13;    ADCQ AX, R12  
	MULXQ 40(SI), AX, R14;    ADCQ AX, R13  
	MULXQ 48(SI), AX, R15;    ADCQ AX, R14  
	MULXQ 56(SI), AX,  DX;    ADCQ AX, R15  
	;;;;;;;;;;;;;;;;;;;;;;    ADCQ $0,  DX  
	ADDQ  0(DI),  R8;  MOVQ  R8,  0(DI) 
	ADCQ  8(DI),  R9;  MOVQ  R9,  8(DI) 
	ADCQ 16(DI), R10;  MOVQ R10, 16(DI) 
	ADCQ 24(DI), R11;  MOVQ R11, 24(DI) 
	ADCQ 32(DI), R12;  MOVQ R12, 32(DI) 
	ADCQ 40(DI), R13;  MOVQ R13, 40(DI) 
	ADCQ 48(DI), R14;  MOVQ R14, 48(DI) 
	ADCQ 56(DI), R15;  MOVQ R15, 56(DI) 
	                ;  MOVQ  DX, AX
	MOVQ y+48(FP), DX
	MULXQ  64(SI), R8,  R9;    ADCQ AX,  R8   
	MULXQ  72(SI), AX, R10;    ADCQ AX,  R9  
	MULXQ  80(SI), AX, R11;    ADCQ AX, R10  
	MULXQ  88(SI), AX, R12;    ADCQ AX, R11  
	MULXQ  96(SI), AX, R13;    ADCQ AX, R12  
	MULXQ 104(SI), AX, R14;    ADCQ AX, R13  
	MULXQ 112(SI), AX, R15;    ADCQ AX, R14  
	MULXQ 120(SI), AX,  DX;    ADCQ AX, R15
	;;;;;;;;;;;;;;;;;;;;;;;    ADCQ $0,  DX
	ADDQ  64(DI),  R8;  MOVQ  R8,  64(DI)
	ADCQ  72(DI),  R9;  MOVQ  R9,  72(DI)
	ADCQ  80(DI), R10;  MOVQ R10,  80(DI)
	ADCQ  88(DI), R11;  MOVQ R11,  88(DI)
	ADCQ  96(DI), R12;  MOVQ R12,  96(DI)
	ADCQ 104(DI), R13;  MOVQ R13, 104(DI)
	ADCQ 112(DI), R14;  MOVQ R14, 112(DI)
	ADCQ 120(DI), R15;  MOVQ R15, 120(DI)
		             ;  MOVQ  DX, AX
	MOVQ y+48(FP), DX
	MULXQ 128(SI), R8,  R9;    ADCQ AX,  R8   
	MULXQ 136(SI), AX, R10;    ADCQ AX,  R9  
	MULXQ 144(SI), AX, R11;    ADCQ AX, R10  
	MULXQ 152(SI), AX, R12;    ADCQ AX, R11  
	MULXQ 160(SI), AX, R13;    ADCQ AX, R12  
	MULXQ 168(SI), AX, R14;    ADCQ AX, R13  
	MULXQ 176(SI), AX, R15;    ADCQ AX, R14  
	MULXQ 184(SI), AX,  DX;    ADCQ AX, R15
	;;;;;;;;;;;;;;;;;;;;;;;    ADCQ $0,  DX
	XORQ AX, AX
	ADDQ 128(DI),  R8;  MOVQ  R8, 128(DI)
	ADCQ 136(DI),  R9;  MOVQ  R9, 136(DI)
	ADCQ 144(DI), R10;  MOVQ R10, 144(DI)
	ADCQ 152(DI), R11;  MOVQ R11, 152(DI)
	ADCQ 160(DI), R12;  MOVQ R12, 160(DI)
	ADCQ 168(DI), R13;  MOVQ R13, 168(DI)
	ADCQ 176(DI), R14;  MOVQ R14, 176(DI)
	ADCQ 184(DI), R15;  MOVQ R15, 184(DI)
	ADCQ 192(DI),  DX;  MOVQ  DX, 192(DI)
	ADCQ      $0,  AX
	
	ADDQ $192, DI
	ADDQ $192, SI
	
	MOVQ cin+56(FP), CX
	ADDQ CX, DX
	ADCQ $0, AX
	MOVQ DX, 0(DI)
	MOVQ AX, cout+64(FP)
    
L_END:
	// Pop BP
	MOVQ -8(SP), BP
	RET  // End of intmadd64x1536 function

////////////////////////////////////////////////
//   n=2048 bits
////////////////////////////////////////////////

#define MADD64x2048 \
	MOVQ 0(BP), DX  \
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
	ADCQ     $0,  DX;  MOVQ  DX, R8 \
	MOVQ 0(BP), DX  \	
	MULXQ  64(SI), AX,  R9;    ADCQ AX,  R8  \ 
	MULXQ  72(SI), AX, R10;    ADCQ AX,  R9  \
	MULXQ  80(SI), AX, R11;    ADCQ AX, R10  \
	MULXQ  88(SI), AX, R12;    ADCQ AX, R11  \
	MULXQ  96(SI), AX, R13;    ADCQ AX, R12  \
	MULXQ 104(SI), AX, R14;    ADCQ AX, R13  \
	MULXQ 112(SI), AX, R15;    ADCQ AX, R14  \
	MULXQ 120(SI), AX,  DX;    ADCQ AX, R15  \
	;;;;;;;;;;;;;;;;;;;;;;;    ADCQ $0,  DX  \
	ADDQ  64(DI),  R8;  MOVQ  R8,  64(DI) \
	ADCQ  72(DI),  R9;  MOVQ  R9,  72(DI) \
	ADCQ  80(DI), R10;  MOVQ R10,  80(DI) \
	ADCQ  88(DI), R11;  MOVQ R11,  88(DI) \
	ADCQ  96(DI), R12;  MOVQ R12,  96(DI) \
	ADCQ 104(DI), R13;  MOVQ R13, 104(DI) \
	ADCQ 112(DI), R14;  MOVQ R14, 112(DI) \
	ADCQ 120(DI), R15;  MOVQ R15, 120(DI) \
	ADCQ     $0,   DX;  MOVQ  DX, R8 \
	MOVQ 0(BP), DX  \
	MULXQ 128(SI), AX,  R9;    ADCQ AX,  R8  \ 
	MULXQ 136(SI), AX, R10;    ADCQ AX,  R9  \
	MULXQ 144(SI), AX, R11;    ADCQ AX, R10  \
	MULXQ 152(SI), AX, R12;    ADCQ AX, R11  \
	MULXQ 160(SI), AX, R13;    ADCQ AX, R12  \
	MULXQ 168(SI), AX, R14;    ADCQ AX, R13  \
	MULXQ 176(SI), AX, R15;    ADCQ AX, R14  \
	MULXQ 184(SI), AX,  DX;    ADCQ AX, R15  \
	;;;;;;;;;;;;;;;;;;;;;;;    ADCQ $0,  DX  \
	ADDQ 128(DI),  R8;  MOVQ  R8, 128(DI) \
	ADCQ 136(DI),  R9;  MOVQ  R9, 136(DI) \
	ADCQ 144(DI), R10;  MOVQ R10, 144(DI) \
	ADCQ 152(DI), R11;  MOVQ R11, 152(DI) \
	ADCQ 160(DI), R12;  MOVQ R12, 160(DI) \
	ADCQ 168(DI), R13;  MOVQ R13, 168(DI) \
	ADCQ 176(DI), R14;  MOVQ R14, 176(DI) \
	ADCQ 184(DI), R15;  MOVQ R15, 184(DI) \
	ADCQ     $0,   DX;  MOVQ  DX, R8 \
	MOVQ 0(BP), DX  \
	MULXQ 192(SI), AX,  R9;    ADCQ AX,  R8  \ 
	MULXQ 200(SI), AX, R10;    ADCQ AX,  R9  \
	MULXQ 208(SI), AX, R11;    ADCQ AX, R10  \
	MULXQ 216(SI), AX, R12;    ADCQ AX, R11  \
	MULXQ 224(SI), AX, R13;    ADCQ AX, R12  \
	MULXQ 232(SI), AX, R14;    ADCQ AX, R13  \
	MULXQ 240(SI), AX, R15;    ADCQ AX, R14  \
	MULXQ 248(SI), AX,  DX;    ADCQ AX, R15  \
	;;;;;;;;;;;;;;;;;;;;;;;    ADCQ $0,  DX  \
	ADDQ 192(DI),  R8;  MOVQ  R8, 192(DI) \
	ADCQ 200(DI),  R9;  MOVQ  R9, 200(DI) \
	ADCQ 208(DI), R10;  MOVQ R10, 208(DI) \
	ADCQ 216(DI), R11;  MOVQ R11, 216(DI) \
	ADCQ 224(DI), R12;  MOVQ R12, 224(DI) \
	ADCQ 232(DI), R13;  MOVQ R13, 232(DI) \
	ADCQ 240(DI), R14;  MOVQ R14, 240(DI) \
	ADCQ 248(DI), R15;  MOVQ R15, 248(DI) \
	ADCQ 256(DI),  DX;  MOVQ  DX, 256(DI) \

// func intmadd2048x2048(z, x, y []Word)
TEXT ·intmadd2048x2048(SB),NOSPLIT,$8
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
	
	MOVQ $32, CX
L_X_32TIMES:
	MADD64x2048
	ADDQ $8, DI
	ADDQ $8, BP
	SUBQ $1, CX
	JNZ	L_X_32TIMES
    
L_END:
	// Pop BP
	MOVQ -8(SP), BP
	RET   // End of intmadd2048x2048 function

/////////////////////////////////////////////////
// func intmadd64x2048(z, x []Word, y Word, cin Word) (cout Word)
TEXT ·intmadd64x2048(SB),NOSPLIT,$8
	// Push BP
	MOVQ BP, -8(SP)
	
	//Early return 
	// if len(x) == 0 then goto END
	MOVQ x_len+32(FP), AX
	CMPQ AX, $0
	JEQ L_END
	
	MOVQ z+ 0(FP), DI
	MOVQ x+24(FP), SI
	
	MOVQ y+48(FP), DX	
	MULXQ  0(SI), R8,  R9;      
	MULXQ  8(SI), AX, R10;    ADDQ AX,  R9  
	MULXQ 16(SI), AX, R11;    ADCQ AX, R10  
	MULXQ 24(SI), AX, R12;    ADCQ AX, R11  
	MULXQ 32(SI), AX, R13;    ADCQ AX, R12  
	MULXQ 40(SI), AX, R14;    ADCQ AX, R13  
	MULXQ 48(SI), AX, R15;    ADCQ AX, R14  
	MULXQ 56(SI), AX,  DX;    ADCQ AX, R15  
	;;;;;;;;;;;;;;;;;;;;;;    ADCQ $0,  DX  
	ADDQ  0(DI),  R8;  MOVQ  R8,  0(DI) 
	ADCQ  8(DI),  R9;  MOVQ  R9,  8(DI) 
	ADCQ 16(DI), R10;  MOVQ R10, 16(DI) 
	ADCQ 24(DI), R11;  MOVQ R11, 24(DI) 
	ADCQ 32(DI), R12;  MOVQ R12, 32(DI) 
	ADCQ 40(DI), R13;  MOVQ R13, 40(DI) 
	ADCQ 48(DI), R14;  MOVQ R14, 48(DI) 
	ADCQ 56(DI), R15;  MOVQ R15, 56(DI) 
	                ;  MOVQ  DX, AX
	MOVQ y+48(FP), DX
	MULXQ  64(SI), R8,  R9;    ADCQ AX,  R8   
	MULXQ  72(SI), AX, R10;    ADCQ AX,  R9  
	MULXQ  80(SI), AX, R11;    ADCQ AX, R10  
	MULXQ  88(SI), AX, R12;    ADCQ AX, R11  
	MULXQ  96(SI), AX, R13;    ADCQ AX, R12  
	MULXQ 104(SI), AX, R14;    ADCQ AX, R13  
	MULXQ 112(SI), AX, R15;    ADCQ AX, R14  
	MULXQ 120(SI), AX,  DX;    ADCQ AX, R15
	;;;;;;;;;;;;;;;;;;;;;;;    ADCQ $0,  DX
	ADDQ  64(DI),  R8;  MOVQ  R8,  64(DI)
	ADCQ  72(DI),  R9;  MOVQ  R9,  72(DI)
	ADCQ  80(DI), R10;  MOVQ R10,  80(DI)
	ADCQ  88(DI), R11;  MOVQ R11,  88(DI)
	ADCQ  96(DI), R12;  MOVQ R12,  96(DI)
	ADCQ 104(DI), R13;  MOVQ R13, 104(DI)
	ADCQ 112(DI), R14;  MOVQ R14, 112(DI)
	ADCQ 120(DI), R15;  MOVQ R15, 120(DI)
		             ;  MOVQ  DX, AX
	MOVQ y+48(FP), DX
	MULXQ 128(SI), R8,  R9;    ADCQ AX,  R8   
	MULXQ 136(SI), AX, R10;    ADCQ AX,  R9  
	MULXQ 144(SI), AX, R11;    ADCQ AX, R10  
	MULXQ 152(SI), AX, R12;    ADCQ AX, R11  
	MULXQ 160(SI), AX, R13;    ADCQ AX, R12  
	MULXQ 168(SI), AX, R14;    ADCQ AX, R13  
	MULXQ 176(SI), AX, R15;    ADCQ AX, R14  
	MULXQ 184(SI), AX,  DX;    ADCQ AX, R15
	;;;;;;;;;;;;;;;;;;;;;;;    ADCQ $0,  DX
	ADDQ 128(DI),  R8;  MOVQ  R8, 128(DI)
	ADCQ 136(DI),  R9;  MOVQ  R9, 136(DI)
	ADCQ 144(DI), R10;  MOVQ R10, 144(DI)
	ADCQ 152(DI), R11;  MOVQ R11, 152(DI)
	ADCQ 160(DI), R12;  MOVQ R12, 160(DI)
	ADCQ 168(DI), R13;  MOVQ R13, 168(DI)
	ADCQ 176(DI), R14;  MOVQ R14, 176(DI)
	ADCQ 184(DI), R15;  MOVQ R15, 184(DI)
	                 ;  MOVQ  DX, AX
	MOVQ y+48(FP), DX
	MULXQ 192(SI), R8,  R9;    ADCQ AX,  R8   
	MULXQ 200(SI), AX, R10;    ADCQ AX,  R9  
	MULXQ 208(SI), AX, R11;    ADCQ AX, R10  
	MULXQ 216(SI), AX, R12;    ADCQ AX, R11  
	MULXQ 224(SI), AX, R13;    ADCQ AX, R12  
	MULXQ 232(SI), AX, R14;    ADCQ AX, R13  
	MULXQ 240(SI), AX, R15;    ADCQ AX, R14  
	MULXQ 248(SI), AX,  DX;    ADCQ AX, R15
	;;;;;;;;;;;;;;;;;;;;;;;    ADCQ $0,  DX
	XORQ AX, AX
	ADDQ 192(DI),  R8;  MOVQ  R8, 192(DI)
	ADCQ 200(DI),  R9;  MOVQ  R9, 200(DI)
	ADCQ 208(DI), R10;  MOVQ R10, 208(DI)
	ADCQ 216(DI), R11;  MOVQ R11, 216(DI)
	ADCQ 224(DI), R12;  MOVQ R12, 224(DI)
	ADCQ 232(DI), R13;  MOVQ R13, 232(DI)
	ADCQ 240(DI), R14;  MOVQ R14, 240(DI)
	ADCQ 248(DI), R15;  MOVQ R15, 248(DI)
	ADCQ 256(DI),  DX;  MOVQ  DX, 256(DI)
	ADCQ      $0,  AX
	
	ADDQ $256, DI
	ADDQ $256, SI
	
	MOVQ cin+56(FP), CX
	ADDQ CX, DX
	ADCQ $0, AX
	MOVQ DX, 0(DI)
	MOVQ AX, cout+64(FP)
    
L_END:
	// Pop BP
	MOVQ -8(SP), BP
	RET  // End of intmadd64x2048 function

	
	