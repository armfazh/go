package big

// montgomery computes z mod m = x*y*2**(-n*_W) mod m,
// assuming k = -1/m mod 2**_W.
// z is used for storing the result which is returned;
// z must not alias x, y or m.
// See Gueron, "Efficient Software Implementations of Modular Exponentiation".
// https://eprint.iacr.org/2011/239.pdf
// In the terminology of that paper, this is an "Almost Montgomery Multiplication":
// x and y are required to satisfy 0 <= z < 2**(n*_W) and then the result
// z is guaranteed to satisfy 0 <= z < 2**(n*_W), but it may not be < m.

func (z nat) montgomery8x(x, y, m nat, k Word, n int) nat {
	var buffer_mult nat
	// This code assumes x, y, m are all the same length, n.
	// (required by addMulVVW and the for loop).
	// It also assumes that x, y are already reduced mod m,
	// or else the result will not be properly reduced.
	buffer_mult = buffer_mult.make(2 * n)
	buffer_mult.clear()
	intmult_mulx(buffer_mult, x, y)
	c := montReduction_mulx(buffer_mult, m, k)
	if c != 0 {
		subVV(buffer_mult[n:2*n], buffer_mult[n:2*n], m)
	}
	z = z.make(n)
	copy(z, buffer_mult[n:2*n])
	return z
}

func (z nat) montgomery8x_mulq(x, y, m nat, k Word, n int) nat {
	var buffer_mult nat
	// This code assumes x, y, m are all the same length, n.
	// (required by addMulVVW and the for loop).
	// It also assumes that x, y are already reduced mod m,
	// or else the result will not be properly reduced.
	buffer_mult = buffer_mult.make(2 * n)
	buffer_mult.clear()
	intmult_mulq(buffer_mult, x, y)
	c := montReduction_mulq(buffer_mult, m, k)
	if c != 0 {
		subVV(buffer_mult[n:2*n], buffer_mult[n:2*n], m)
	}
	z = z.make(n)
	copy(z, buffer_mult[n:2*n])
	return z
}
