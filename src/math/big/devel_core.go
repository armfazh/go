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
func (z nat) montgomery512(x, y, m nat, k Word, n int) nat {
	// This code assumes x, y, m are all the same length, n.
	// (required by addMulVVW and the for loop).
	// It also assumes that x, y are already reduced mod m,
	// or else the result will not be properly reduced.
	if len(x) != n || len(y) != n || len(m) != n {
		panic("math/big: mismatched montgomery number lengths")
	}
	z = z.make(2*n + 1)
	z.clear()

	intmaddNxN(z, x[:16], y)
	z.PrintHex()
	//	var c Word
	//	for i := 0; i < n; i++ {
	//		t := z[i] * k
	//		c = addMulVVW_unrolled(z[i:], m, t, c)
	//	}
	//	if c != 0 {
	//		subVV(z[n:2*n], z[n:2*n], m)
	//	}
	//	z = z[n : 2*n]
	return z
}
