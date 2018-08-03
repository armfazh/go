// Copyright 2009 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// +build !math_big_pure_go

#include "textflag.h"

// This file provides fast assembly versions for the elementary
// arithmetic operations on vectors implemented in arith.go.

// func mulWW(x, y Word) (z1, z0 Word)
TEXT ·mulWW(SB),NOSPLIT,$0
	MOVQ x+0(FP), AX
	MULQ y+8(FP)
	MOVQ DX, z1+16(FP)
	MOVQ AX, z0+24(FP)
	RET


// func divWW(x1, x0, y Word) (q, r Word)
TEXT ·divWW(SB),NOSPLIT,$0
	MOVQ x1+0(FP), DX
	MOVQ x0+8(FP), AX
	DIVQ y+16(FP)
	MOVQ AX, q+24(FP)
	MOVQ DX, r+32(FP)
	RET

// The carry bit is saved with SBBQ Rx, Rx: if the carry was set, Rx is -1, otherwise it is 0.
// It is restored with ADDQ Rx, Rx: if Rx was -1 the carry is set, otherwise it is cleared.
// This is faster than using rotate instructions.

// func addVV(z, x, y []Word) (c Word)
TEXT ·addVV(SB),NOSPLIT,$0
	MOVQ z_len+8(FP), DI
	MOVQ x+24(FP), R8
	MOVQ y+48(FP), R9
	MOVQ z+0(FP), R10

	MOVQ $0, CX		// c = 0
	MOVQ $0, SI		// i = 0

	// s/JL/JMP/ below to disable the unrolled loop
	SUBQ $4, DI		// n -= 4
	JL V1			// if n < 0 goto V1

U1:	// n >= 0
	// regular loop body unrolled 4x
	ADDQ CX, CX		// restore CF
	MOVQ 0(R8)(SI*8), R11
	MOVQ 8(R8)(SI*8), R12
	MOVQ 16(R8)(SI*8), R13
	MOVQ 24(R8)(SI*8), R14
	ADCQ 0(R9)(SI*8), R11
	ADCQ 8(R9)(SI*8), R12
	ADCQ 16(R9)(SI*8), R13
	ADCQ 24(R9)(SI*8), R14
	MOVQ R11, 0(R10)(SI*8)
	MOVQ R12, 8(R10)(SI*8)
	MOVQ R13, 16(R10)(SI*8)
	MOVQ R14, 24(R10)(SI*8)
	SBBQ CX, CX		// save CF

	ADDQ $4, SI		// i += 4
	SUBQ $4, DI		// n -= 4
	JGE U1			// if n >= 0 goto U1

V1:	ADDQ $4, DI		// n += 4
	JLE E1			// if n <= 0 goto E1

L1:	// n > 0
	ADDQ CX, CX		// restore CF
	MOVQ 0(R8)(SI*8), R11
	ADCQ 0(R9)(SI*8), R11
	MOVQ R11, 0(R10)(SI*8)
	SBBQ CX, CX		// save CF

	ADDQ $1, SI		// i++
	SUBQ $1, DI		// n--
	JG L1			// if n > 0 goto L1

E1:	NEGQ CX
	MOVQ CX, c+72(FP)	// return c
	RET


// func subVV(z, x, y []Word) (c Word)
// (same as addVV except for SBBQ instead of ADCQ and label names)
TEXT ·subVV(SB),NOSPLIT,$0
	MOVQ z_len+8(FP), DI
	MOVQ x+24(FP), R8
	MOVQ y+48(FP), R9
	MOVQ z+0(FP), R10

	MOVQ $0, CX		// c = 0
	MOVQ $0, SI		// i = 0

	// s/JL/JMP/ below to disable the unrolled loop
	SUBQ $4, DI		// n -= 4
	JL V2			// if n < 0 goto V2

U2:	// n >= 0
	// regular loop body unrolled 4x
	ADDQ CX, CX		// restore CF
	MOVQ 0(R8)(SI*8), R11
	MOVQ 8(R8)(SI*8), R12
	MOVQ 16(R8)(SI*8), R13
	MOVQ 24(R8)(SI*8), R14
	SBBQ 0(R9)(SI*8), R11
	SBBQ 8(R9)(SI*8), R12
	SBBQ 16(R9)(SI*8), R13
	SBBQ 24(R9)(SI*8), R14
	MOVQ R11, 0(R10)(SI*8)
	MOVQ R12, 8(R10)(SI*8)
	MOVQ R13, 16(R10)(SI*8)
	MOVQ R14, 24(R10)(SI*8)
	SBBQ CX, CX		// save CF

	ADDQ $4, SI		// i += 4
	SUBQ $4, DI		// n -= 4
	JGE U2			// if n >= 0 goto U2

V2:	ADDQ $4, DI		// n += 4
	JLE E2			// if n <= 0 goto E2

L2:	// n > 0
	ADDQ CX, CX		// restore CF
	MOVQ 0(R8)(SI*8), R11
	SBBQ 0(R9)(SI*8), R11
	MOVQ R11, 0(R10)(SI*8)
	SBBQ CX, CX		// save CF

	ADDQ $1, SI		// i++
	SUBQ $1, DI		// n--
	JG L2			// if n > 0 goto L2

E2:	NEGQ CX
	MOVQ CX, c+72(FP)	// return c
	RET


// func addVW(z, x []Word, y Word) (c Word)
TEXT ·addVW(SB),NOSPLIT,$0
	MOVQ z_len+8(FP), DI
	MOVQ x+24(FP), R8
	MOVQ y+48(FP), CX	// c = y
	MOVQ z+0(FP), R10

	MOVQ $0, SI		// i = 0

	// s/JL/JMP/ below to disable the unrolled loop
	SUBQ $4, DI		// n -= 4
	JL V3			// if n < 4 goto V3

U3:	// n >= 0
	// regular loop body unrolled 4x
	MOVQ 0(R8)(SI*8), R11
	MOVQ 8(R8)(SI*8), R12
	MOVQ 16(R8)(SI*8), R13
	MOVQ 24(R8)(SI*8), R14
	ADDQ CX, R11
	ADCQ $0, R12
	ADCQ $0, R13
	ADCQ $0, R14
	SBBQ CX, CX		// save CF
	NEGQ CX
	MOVQ R11, 0(R10)(SI*8)
	MOVQ R12, 8(R10)(SI*8)
	MOVQ R13, 16(R10)(SI*8)
	MOVQ R14, 24(R10)(SI*8)

	ADDQ $4, SI		// i += 4
	SUBQ $4, DI		// n -= 4
	JGE U3			// if n >= 0 goto U3

V3:	ADDQ $4, DI		// n += 4
	JLE E3			// if n <= 0 goto E3

L3:	// n > 0
	ADDQ 0(R8)(SI*8), CX
	MOVQ CX, 0(R10)(SI*8)
	SBBQ CX, CX		// save CF
	NEGQ CX

	ADDQ $1, SI		// i++
	SUBQ $1, DI		// n--
	JG L3			// if n > 0 goto L3

E3:	MOVQ CX, c+56(FP)	// return c
	RET


// func subVW(z, x []Word, y Word) (c Word)
// (same as addVW except for SUBQ/SBBQ instead of ADDQ/ADCQ and label names)
TEXT ·subVW(SB),NOSPLIT,$0
	MOVQ z_len+8(FP), DI
	MOVQ x+24(FP), R8
	MOVQ y+48(FP), CX	// c = y
	MOVQ z+0(FP), R10

	MOVQ $0, SI		// i = 0

	// s/JL/JMP/ below to disable the unrolled loop
	SUBQ $4, DI		// n -= 4
	JL V4			// if n < 4 goto V4

U4:	// n >= 0
	// regular loop body unrolled 4x
	MOVQ 0(R8)(SI*8), R11
	MOVQ 8(R8)(SI*8), R12
	MOVQ 16(R8)(SI*8), R13
	MOVQ 24(R8)(SI*8), R14
	SUBQ CX, R11
	SBBQ $0, R12
	SBBQ $0, R13
	SBBQ $0, R14
	SBBQ CX, CX		// save CF
	NEGQ CX
	MOVQ R11, 0(R10)(SI*8)
	MOVQ R12, 8(R10)(SI*8)
	MOVQ R13, 16(R10)(SI*8)
	MOVQ R14, 24(R10)(SI*8)

	ADDQ $4, SI		// i += 4
	SUBQ $4, DI		// n -= 4
	JGE U4			// if n >= 0 goto U4

V4:	ADDQ $4, DI		// n += 4
	JLE E4			// if n <= 0 goto E4

L4:	// n > 0
	MOVQ 0(R8)(SI*8), R11
	SUBQ CX, R11
	MOVQ R11, 0(R10)(SI*8)
	SBBQ CX, CX		// save CF
	NEGQ CX

	ADDQ $1, SI		// i++
	SUBQ $1, DI		// n--
	JG L4			// if n > 0 goto L4

E4:	MOVQ CX, c+56(FP)	// return c
	RET


// func shlVU(z, x []Word, s uint) (c Word)
TEXT ·shlVU(SB),NOSPLIT,$0
	MOVQ z_len+8(FP), BX	// i = z
	SUBQ $1, BX		// i--
	JL X8b			// i < 0	(n <= 0)

	// n > 0
	MOVQ z+0(FP), R10
	MOVQ x+24(FP), R8
	MOVQ s+48(FP), CX
	MOVQ (R8)(BX*8), AX	// w1 = x[n-1]
	MOVQ $0, DX
	SHLQ CX, DX:AX		// w1>>ŝ
	MOVQ DX, c+56(FP)

	CMPQ BX, $0
	JLE X8a			// i <= 0

	// i > 0
L8:	MOVQ AX, DX		// w = w1
	MOVQ -8(R8)(BX*8), AX	// w1 = x[i-1]
	SHLQ CX, DX:AX		// w<<s | w1>>ŝ
	MOVQ DX, (R10)(BX*8)	// z[i] = w<<s | w1>>ŝ
	SUBQ $1, BX		// i--
	JG L8			// i > 0

	// i <= 0
X8a:	SHLQ CX, AX		// w1<<s
	MOVQ AX, (R10)		// z[0] = w1<<s
	RET

X8b:	MOVQ $0, c+56(FP)
	RET


// func shrVU(z, x []Word, s uint) (c Word)
TEXT ·shrVU(SB),NOSPLIT,$0
	MOVQ z_len+8(FP), R11
	SUBQ $1, R11		// n--
	JL X9b			// n < 0	(n <= 0)

	// n > 0
	MOVQ z+0(FP), R10
	MOVQ x+24(FP), R8
	MOVQ s+48(FP), CX
	MOVQ (R8), AX		// w1 = x[0]
	MOVQ $0, DX
	SHRQ CX, DX:AX		// w1<<ŝ
	MOVQ DX, c+56(FP)

	MOVQ $0, BX		// i = 0
	JMP E9

	// i < n-1
L9:	MOVQ AX, DX		// w = w1
	MOVQ 8(R8)(BX*8), AX	// w1 = x[i+1]
	SHRQ CX, DX:AX		// w>>s | w1<<ŝ
	MOVQ DX, (R10)(BX*8)	// z[i] = w>>s | w1<<ŝ
	ADDQ $1, BX		// i++

E9:	CMPQ BX, R11
	JL L9			// i < n-1

	// i >= n-1
X9a:	SHRQ CX, AX		// w1>>s
	MOVQ AX, (R10)(R11*8)	// z[n-1] = w1>>s
	RET

X9b:	MOVQ $0, c+56(FP)
	RET


// func mulAddVWW(z, x []Word, y, r Word) (c Word)
TEXT ·mulAddVWW(SB),NOSPLIT,$0
	MOVQ z+0(FP), R10
	MOVQ x+24(FP), R8
	MOVQ y+48(FP), R9
	MOVQ r+56(FP), CX	// c = r
	MOVQ z_len+8(FP), R11
	MOVQ $0, BX		// i = 0
	
	CMPQ R11, $4
	JL E5
	
U5:	// i+4 <= n
	// regular loop body unrolled 4x
	MOVQ (0*8)(R8)(BX*8), AX
	MULQ R9
	ADDQ CX, AX
	ADCQ $0, DX
	MOVQ AX, (0*8)(R10)(BX*8)
	MOVQ DX, CX
	MOVQ (1*8)(R8)(BX*8), AX
	MULQ R9
	ADDQ CX, AX
	ADCQ $0, DX
	MOVQ AX, (1*8)(R10)(BX*8)
	MOVQ DX, CX
	MOVQ (2*8)(R8)(BX*8), AX
	MULQ R9
	ADDQ CX, AX
	ADCQ $0, DX
	MOVQ AX, (2*8)(R10)(BX*8)
	MOVQ DX, CX
	MOVQ (3*8)(R8)(BX*8), AX
	MULQ R9
	ADDQ CX, AX
	ADCQ $0, DX
	MOVQ AX, (3*8)(R10)(BX*8)
	MOVQ DX, CX
	ADDQ $4, BX		// i += 4
	
	LEAQ 4(BX), DX
	CMPQ DX, R11
	JLE U5
	JMP E5

L5:	MOVQ (R8)(BX*8), AX
	MULQ R9
	ADDQ CX, AX
	ADCQ $0, DX
	MOVQ AX, (R10)(BX*8)
	MOVQ DX, CX
	ADDQ $1, BX		// i++

E5:	CMPQ BX, R11		// i < n
	JL L5

	MOVQ CX, c+64(FP)
	RET


// func addMulVVW(z, x []Word, y Word) (c Word)
TEXT ·addMulVVW(SB),NOSPLIT,$0
	MOVQ z+0(FP), R10
	MOVQ x+24(FP), R8
	MOVQ y+48(FP), R9
	MOVQ z_len+8(FP), R11
	MOVQ $0, BX		// i = 0
	MOVQ $0, CX		// c = 0
	MOVQ R11, R12
	ANDQ $-2, R12
	CMPQ R11, $2
	JAE A6
	JMP E6

A6:
	MOVQ (R8)(BX*8), AX
	MULQ R9
	ADDQ (R10)(BX*8), AX
	ADCQ $0, DX
	ADDQ CX, AX
	ADCQ $0, DX
	MOVQ DX, CX
	MOVQ AX, (R10)(BX*8)

	MOVQ (8)(R8)(BX*8), AX
	MULQ R9
	ADDQ (8)(R10)(BX*8), AX
	ADCQ $0, DX
	ADDQ CX, AX
	ADCQ $0, DX
	MOVQ DX, CX
	MOVQ AX, (8)(R10)(BX*8)

	ADDQ $2, BX
	CMPQ BX, R12
	JL A6
	JMP E6

L6:	MOVQ (R8)(BX*8), AX
	MULQ R9
	ADDQ CX, AX
	ADCQ $0, DX
	ADDQ AX, (R10)(BX*8)
	ADCQ $0, DX
	MOVQ DX, CX
	ADDQ $1, BX		// i++

E6:	CMPQ BX, R11		// i < n
	JL L6

	MOVQ CX, c+56(FP)
	RET


// func divWVW(z []Word, xn Word, x []Word, y Word) (r Word)
TEXT ·divWVW(SB),NOSPLIT,$0
	MOVQ z+0(FP), R10
	MOVQ xn+24(FP), DX	// r = xn
	MOVQ x+32(FP), R8
	MOVQ y+56(FP), R9
	MOVQ z_len+8(FP), BX	// i = z
	JMP E7

L7:	MOVQ (R8)(BX*8), AX
	DIVQ R9
	MOVQ AX, (R10)(BX*8)

E7:	SUBQ $1, BX		// i--
	JGE L7			// i >= 0

	MOVQ DX, r+64(FP)
	RET

#define MUL64x512N_MULX  \
	MULXQ  0(SI), AX,  R9;  ADCQ AX,  R8;  MOVQ  R8,  0(DI)  \
	MULXQ  8(SI), AX, R10;  ADCQ AX,  R9;  MOVQ  R9,  8(DI)  \
	MULXQ 16(SI), AX, R11;  ADCQ AX, R10;  MOVQ R10, 16(DI)  \
	MULXQ 24(SI), AX, R12;  ADCQ AX, R11;  MOVQ R11, 24(DI)  \
	MULXQ 32(SI), AX, R13;  ADCQ AX, R12;  MOVQ R12, 32(DI)  \ 
	MULXQ 40(SI), AX, R14;  ADCQ AX, R13;  MOVQ R13, 40(DI)  \
	MULXQ 48(SI), AX, R15;  ADCQ AX, R14;  MOVQ R14, 48(DI)  \
	MULXQ 56(SI), AX,  DX;  ADCQ AX, R15;  MOVQ R15, 56(DI)  \
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;  MOVQ  DX,     R8 
	
#define MADD64x512N_MULX  \
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
	;;;;;;;;;;;;;;;;;  MOVQ  DX,     R8

//////////////////////////////////////////////////////////
// func intmul512Nx512N(z, x, y []Word)
TEXT ·intmul512Nx512N(SB),NOSPLIT,$0
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
	SHRQ $3, BX
	XORQ R8, R8
	L_X1TIMES:
		MOVQ 0(BP), DX
		MUL64x512N_MULX
		LEAQ 64(SI), SI
		LEAQ 64(DI), DI
		DECQ BX
	JNZ	L_X1TIMES
	ADCQ $0, R8
	MOVQ R8, 0(DI)

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
		MADD64x512N_MULX
		LEAQ 64(SI), SI
		LEAQ 64(DI), DI
		DECQ BX
	JNZ	L_XTIMES
	ADCQ $0, R8
	MOVQ R8, 0(DI)
	
	DECQ CX
	JNZ	L_YTIMES
L_END:
	RET   // End of intmul512Nx512N function

//////////////////////////////////////////////////////////
// func redMontgomery512N(z, x []Word, k Word) (c Word)
TEXT ·redMontgomery512N(SB),NOSPLIT,$0
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
		MADD64x512N_MULX
		LEAQ 64(SI), SI
		LEAQ 64(DI), DI
		DECQ BX
	JNZ L_XTIMES
	MOVQ $0, AX
	ADCQ 0(DI), R8
	ADCQ $0, AX
	ADDQ c+56(FP), R8
	ADCQ $0, AX
	MOVQ R8, 0(DI)
	MOVQ AX, c+56(FP)
	
	DECQ CX
	JNZ L_NTIMES	
		
L_END:
	RET // End of redMontgomery512N

