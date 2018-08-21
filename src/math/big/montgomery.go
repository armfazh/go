// @author Armando Faz

// +build math_big_pure_go !amd64

package big

func (z nat) montgomery(x, y, m, buffer_mult nat, k Word) nat {
	z = z.montgomery_g(x, y, m, k, len(m))
	return z
}
