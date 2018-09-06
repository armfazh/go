// @author Armando Faz

// +build !math_big_pure_go,amd64

package big

import "internal/cpu"

var intMult func(x, y, z []Word)
var reductionMontgomery func(x, y []Word, k Word) (cout Word)

func init() {
	if cpu.X86.HasBMI2 {
		if cpu.X86.HasADX {
			intMult = intMultMulxAdx
			reductionMontgomery = montReductionMulxAdx
		} else {
			intMult = intMultMulx
			reductionMontgomery = montReductionMulx
		}
	} else {
		intMult = intMultMulq
		reductionMontgomery = montReductionMulq
	}
}

//go:noescape
func intMultMulxAdx(z, x, y []Word)

//go:noescape
func intMultMulx(z, x, y []Word)

//go:noescape
func intMultMulq(z, x, y []Word)

//go:noescape
func montReductionMulxAdx(z, x []Word, k Word) (cout Word)

//go:noescape
func montReductionMulx(z, x []Word, k Word) (cout Word)

//go:noescape
func montReductionMulq(z, x []Word, k Word) (cout Word)

// montgomery computes z mod m = x*y*2**(-n*_W) mod m,
// assuming k = -1/m mod 2**_W.
// z is used for storing the result which is returned;
// z must not alias x, y or m.
// See Gueron, "Efficient Software Implementations of Modular Exponentiation".
// https://eprint.iacr.org/2011/239.pdf
// In the terminology of that paper, this is an "Almost Montgomery Multiplication":
// x and y are required to satisfy 0 <= z < 2**(n*_W) and then the result
// z is guaranteed to satisfy 0 <= z < 2**(n*_W), but it may not be < m.

// Pre-conditions:
// 1) This code assumes x, y, m are all the same length.
// 2) It also assumes that x, y are already reduced mod m,
//    or else the result will not be properly reduced.
// 3) buffer_mult is an allocated array of length len(x)+len(y)
func (z nat) montgomery(x, y, m, buffer nat, k Word) nat {
	var c Word
	n := len(m)
	z = z.make(n)

	intMult(buffer, x, y)
	reductionMontgomery(buffer, m, k)
	subVV(buffer[0:n], buffer[n:2*n], m)

	// ConstantTimeCopy adapted from bytes to Words
	xmask := Word(c - 1)
	ymask := Word(^(c - 1))
	for i := 0; i < len(z); i++ {
		z[i] = buffer[n+i]&xmask | buffer[i]&ymask
	}
	return z
}
