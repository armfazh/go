// +build math_big_pure_go

package big

func (z nat) montgomery(x, y, m, buffer_mult nat, k Word) nat {
	z = z.montgomery_gen(x, y, m, k, len(m))
	return z
}
