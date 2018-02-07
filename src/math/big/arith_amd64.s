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



// mul512_red(z, m []Word, k0 Word)
TEXT ·mul512_red(SB),NOSPLIT,$0
    MOVQ z+0(FP),  DI
    MOVQ x+24(FP), SI
    //MOVQ y+48(FP), BX

    MOVQ (DI), R8
    MOVQ (8)(DI), R9
    MOVQ (16)(DI), R10
    MOVQ (24)(DI), R11
    MOVQ (32)(DI), R12
    MOVQ (40)(DI), R13
    MOVQ (48)(DI), R14
    MOVQ (56)(DI), R15

    MOVQ $0, CX

L_ite2:
    MOVQ (DI)(CX*8), AX // ti
    MOVQ y+48(FP), BX // k0
    IMULQ AX, BX

    MOVQ (SI), AX
    MULQ BX
    ADDQ AX, R8
    MOVQ R8, (DI)(CX*8)
    MOVQ DX, R8
    ADCQ $0, R8

    MOVQ (8)(SI), AX
    MULQ BX
    ADDQ AX, R9
    ADCQ $0, DX
    ADDQ R9, R8
    MOVQ DX, R9
    ADCQ $0, R9

    MOVQ (16)(SI), AX
    MULQ BX
    ADDQ AX, R10
    ADCQ $0, DX
    ADDQ R10, R9
    MOVQ DX, R10
    ADCQ $0, R10

    MOVQ (24)(SI), AX
    MULQ BX
    ADDQ AX, R11
    ADCQ $0, DX
    ADDQ R11, R10
    MOVQ DX, R11
    ADCQ $0, R11

    MOVQ (32)(SI), AX
    MULQ BX
    ADDQ AX, R12
    ADCQ $0, DX
    ADDQ R12, R11
    MOVQ DX, R12
    ADCQ $0, R12

    MOVQ (40)(SI), AX
    MULQ BX
    ADDQ AX, R13
    ADCQ $0, DX
    ADDQ R13, R12
    MOVQ DX, R13
    ADCQ $0, R13

    MOVQ (48)(SI), AX
    MULQ BX
    ADDQ AX, R14
    ADCQ $0, DX
    ADDQ R14, R13
    MOVQ DX, R14
    ADCQ $0, R14

    MOVQ (56)(SI), AX
    MULQ BX
    ADDQ AX, R15
    ADCQ $0, DX
    ADDQ R15, R14
    MOVQ DX, R15
    ADCQ $0, R15

    MOVQ (64)(SI), AX
    MULQ BX
    ADDQ (64)(DI)(CX*8), AX
    ADCQ (72)(DI)(CX*8), DX
    ADDQ R15, AX
    ADCQ $0, DX
    MOVQ AX, (64)(DI)(CX*8)
    MOVQ DX, (72)(DI)(CX*8)

    MOVQ (72)(SI), AX
    MULQ BX
    ADDQ (72)(DI)(CX*8), AX
    ADCQ (80)(DI)(CX*8), DX
    ADCQ $0, (88)(DI)(CX*8)
    MOVQ AX, (72)(DI)(CX*8)
    MOVQ DX, (80)(DI)(CX*8)

    MOVQ (80)(SI), AX
    MULQ BX
    ADDQ (80)(DI)(CX*8), AX
    ADCQ (88)(DI)(CX*8), DX
    ADCQ $0, (96)(DI)(CX*8)
    MOVQ AX, (80)(DI)(CX*8)
    MOVQ DX, (88)(DI)(CX*8)

    MOVQ (88)(SI), AX
    MULQ BX
    ADDQ (88)(DI)(CX*8), AX
    ADCQ (96)(DI)(CX*8), DX
    ADCQ $0, (104)(DI)(CX*8)
    MOVQ AX, (88)(DI)(CX*8)
    MOVQ DX, (96)(DI)(CX*8)

    MOVQ (96)(SI), AX
    MULQ BX
    ADDQ (96)(DI)(CX*8), AX
    ADCQ (104)(DI)(CX*8), DX
    ADCQ $0, (112)(DI)(CX*8)
    MOVQ AX, (96)(DI)(CX*8)
    MOVQ DX, (104)(DI)(CX*8)

    MOVQ (104)(SI), AX
    MULQ BX
    ADDQ (104)(DI)(CX*8), AX
    ADCQ (112)(DI)(CX*8), DX
    ADCQ $0, (120)(DI)(CX*8)
    MOVQ AX, (104)(DI)(CX*8)
    MOVQ DX, (112)(DI)(CX*8)

    MOVQ (112)(SI), AX
    MULQ BX
    ADDQ (112)(DI)(CX*8), AX
    ADCQ (120)(DI)(CX*8), DX
    ADCQ $0, (128)(DI)(CX*8)
    MOVQ AX, (112)(DI)(CX*8)
    MOVQ DX, (120)(DI)(CX*8)

    MOVQ (120)(SI), AX
    MULQ BX
    ADDQ (120)(DI)(CX*8), AX
    ADCQ (128)(DI)(CX*8), DX
    ADCQ $0, (136)(DI)(CX*8)
    MOVQ AX, (120)(DI)(CX*8)
    MOVQ DX, (128)(DI)(CX*8)

    ADDQ $1, CX
    CMPQ CX, $16
    JL L_ite2

   MOVQ R8,  (0)(DI)(CX*8)
   MOVQ R9,  (8)(DI)(CX*8)
   MOVQ R10, (16)(DI)(CX*8)
   MOVQ R11, (24)(DI)(CX*8)
   MOVQ R12, (32)(DI)(CX*8)
   MOVQ R13, (40)(DI)(CX*8)
   MOVQ R14, (48)(DI)(CX*8)
   //MOVQ R15, (56)(DI)(CX*8)

    RET

//func mul512x1024(z, x, y []Word) (c Word)
TEXT ·mul512x1024(SB),NOSPLIT,$0
    MOVQ z+0(FP),  DI
    MOVQ x+24(FP), SI
    //MOVQ y+48(FP), BX

    MOVQ (DI), R8
    MOVQ (8)(DI), R9
    MOVQ (16)(DI), R10
    MOVQ (24)(DI), R11
    MOVQ (32)(DI), R12
    MOVQ (40)(DI), R13
    MOVQ (48)(DI), R14
    MOVQ (56)(DI), R15

    MOVQ $0, CX

L_ite:
    MOVQ y+48(FP), BX
    MOVQ (BX)(CX*8), BX

    MOVQ (SI), AX
    MULQ BX
    ADDQ AX, R8
    MOVQ R8, (DI)(CX*8)
    MOVQ DX, R8
    ADCQ $0, R8

    MOVQ (8)(SI), AX
    MULQ BX
    ADDQ AX, R9
    ADCQ $0, DX
    ADDQ R9, R8
    MOVQ DX, R9
    ADCQ $0, R9

    MOVQ (16)(SI), AX
    MULQ BX
    ADDQ AX, R10
    ADCQ $0, DX
    ADDQ R10, R9
    MOVQ DX, R10
    ADCQ $0, R10

    MOVQ (24)(SI), AX
    MULQ BX
    ADDQ AX, R11
    ADCQ $0, DX
    ADDQ R11, R10
    MOVQ DX, R11
    ADCQ $0, R11

    MOVQ (32)(SI), AX
    MULQ BX
    ADDQ AX, R12
    ADCQ $0, DX
    ADDQ R12, R11
    MOVQ DX, R12
    ADCQ $0, R12

    MOVQ (40)(SI), AX
    MULQ BX
    ADDQ AX, R13
    ADCQ $0, DX
    ADDQ R13, R12
    MOVQ DX, R13
    ADCQ $0, R13

    MOVQ (48)(SI), AX
    MULQ BX
    ADDQ AX, R14
    ADCQ $0, DX
    ADDQ R14, R13
    MOVQ DX, R14
    ADCQ $0, R14

    MOVQ (56)(SI), AX
    MULQ BX
    ADDQ AX, R15
    ADCQ $0, DX
    ADDQ R15, R14
    MOVQ DX, R15
    ADCQ (64)(DI)(CX*8), R15
    ADCQ $0, (72)(DI)(CX*8)

    ADDQ $1, CX
    CMPQ CX, $16
    JL L_ite

    ADDQ R8,  (0)(DI)(CX*8)
    ADCQ R9,  (8)(DI)(CX*8)
    ADCQ R10, (16)(DI)(CX*8)
    ADCQ R11, (24)(DI)(CX*8)
    ADCQ R12, (32)(DI)(CX*8)
    ADCQ R13, (40)(DI)(CX*8)
    ADCQ R14, (48)(DI)(CX*8)
    ADCQ R15, (56)(DI)(CX*8)

    RET

//func fios(z, x []Word, y Word, m []Word, k Word)
TEXT ·fios(SB),NOSPLIT,$0
    MOVQ z+0(FP), R10
    MOVQ x+24(FP), R8
    MOVQ y+48(FP), R9
    MOVQ m+56(FP), R13
    MOVQ k+80(FP), R14
    MOVQ $0, BX		// i = 0

    //unroll first iteration
    // (C,S) := t[0] + a[0]*b[i]
    MOVQ (R8)(BX*8), AX
    MULQ R9
    ADDQ (R10)(BX*8), AX
    ADCQ $0, DX
    // DX = S
    // CX = S
    MOVQ AX, R12
    MOVQ AX, R15
    // ADD(t[1],C)
    XORQ R11,R11
    ADDQ (8)(R10)(BX*8), DX
    ADCQ (16)(R10)(BX*8), R11
    MOVQ DX, (8)(R10)(BX*8)
    MOVQ R11, (16)(R10)(BX*8)

    // m := S*n'[0] mod W
    // Cx = m = S * k
    IMULQ R12, R14

    // (C,S) := S + m*n[0]
    MOVQ (R13)(BX*8), AX
    MULQ R14
    ADDQ R15, AX
    ADCQ $0, DX
    MOVQ DX, CX
    ADDQ $1, BX		// i++

    MOVQ    (R10)(BX*8), R11
    MOVQ (8)(R10)(BX*8), R12

L6:
    // (C,S) := t[j] + a[j]*b[i] + C
    MOVQ (R8)(BX*8), AX
    MULQ R9
    ADDQ CX, AX
    ADCQ $0, DX
    ADDQ R11, AX
    ADCQ $0, DX
    MOVQ AX, CX
    // ADD(t[j+1],C)
    XORQ R15, R15
    ADDQ R12, DX
    ADCQ (16)(R10)(BX*8), R15
    MOVQ DX, R11
    MOVQ R15, R12
    // (C,S) := S + m*n[j]
    MOVQ (R13)(BX*8), AX
    MULQ R14
    ADDQ CX, AX
    ADCQ $0, DX
    // Z[j-1] = S
    MOVQ DX, CX
    MOVQ AX, (-8)(R10)(BX*8)
    ADDQ $1, BX		// i++

E6:	CMPQ BX, $16		// i < n
    JL L6
    // (C,S) := t[s] + C
    // t[s-1] := S
    // t[s] := t[s+1] + C
    // t[s+1] := 0
    XORQ AX, AX
    ADDQ R11, CX
    MOVQ CX, (-8)(R10)(BX*8)
    ADCQ (8)(R10)(BX*8), AX
    MOVQ AX, (R10)(BX*8)
    MOVQ $0, (8)(R10)(BX*8)

	RET

// func addMul(z, x []Word, y Word) (c Word)
TEXT ·addMul(SB),NOSPLIT,$0
	MOVQ z+0(FP), R10
	MOVQ x+24(FP), R8
	MOVQ y+48(FP), R9
	MOVQ $0, BX		// i = 0
	MOVQ $0, CX		// c = 0

A61:
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
    CMPQ BX, $16
    JL A61

E61:
    XORQ DX, DX
	ADDQ CX, (R10)(BX*8)
	ADCQ (8)(R10)(BX*8), DX
	MOVQ DX, (8)(R10)(BX*8)

	MOVQ DX, c+56(FP)
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
