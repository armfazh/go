package big

import (
	"internal/cpu"
)

var hasBMI2 = cpu.X86.HasBMI2
var hasADX = cpu.X86.HasADX

// ConstantTimeCopy copies the contents of y into x (a slice of equal length)
// if v == 1. If v == 0, x is left unchanged. Its behavior is undefined if v
// takes any other value.

// montgomery computes z mod m = x*y*2**(-n*_W) mod m,
// assuming k = -1/m mod 2**_W.
// z is used for storing the result which is returned;
// z must not alias x, y or m.
// See Gueron, "Efficient Software Implementations of Modular Exponentiation".
// https://eprint.iacr.org/2011/239.pdf
// In the terminology of that paper, this is an "Almost Montgomery Multiplication":
// x and y are required to satisfy 0 <= z < 2**(n*_W) and then the result
// z is guaranteed to satisfy 0 <= z < 2**(n*_W), but it may not be < m.
func (z nat) montgomery_opt(x, y, m, buffer_mult nat, k Word) nat {
	// This code assumes x, y, m are all the same length, n.
	// It also assumes that x, y are already reduced mod m,
	// or else the result will not be properly reduced.
	var c Word
	n := len(m)
	z = z.make(n)
	if hasBMI2 {
		if hasADX {
			intmult_mulx_adx(buffer_mult, x, y)
			c = montReduction_mulx_adx(buffer_mult, m, k)
		} else {
			intmult_mulx(buffer_mult, x, y)
			c = montReduction_mulx(buffer_mult, m, k)
		}
	} else {
		intmult_mulq(buffer_mult, x, y)
		c = montReduction_mulq(buffer_mult, m, k)
	}
	subVV(buffer_mult[0:n], buffer_mult[n:2*n], m)

	// constantTimeCopy taken from crypto/subtle
	xmask := Word(c - 1)
	ymask := Word(^(c - 1))
	for i := 0; i < len(z); i++ {
		z[i] = buffer_mult[n+i]&xmask | buffer_mult[i]&ymask
	}
	return z
}
