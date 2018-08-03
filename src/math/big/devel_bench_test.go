package big

import (
	"fmt"
	"testing"
)

func BenchmarkFazmadd512N(b *testing.B) {
	var benchSizes = []int{8, 16, 24, 32}

	for _, n := range benchSizes {
		x := rndV(n)
		y := rndV(n)
		z := nat(nil).make(len(x) + len(y))
		b.Run(fmt.Sprint(n), func(b *testing.B) {
			b.SetBytes(int64(n * _W))
			for i := 0; i < b.N; i++ {
				intmadd512Nx512N(z, x, y)
			}
		})
	}
}

func BenchmarkFazMontgomery(b *testing.B) {
	var benchSizes = []int{8, 16, 24, 32}
	var k Word
	k = (1 << 64) - 1
	for _, n := range benchSizes {
		mulx := rndV(n)
		muly := rndV(n)
		mod := rndV(n)
		z := nat(nil).make(len(mulx) + len(muly))
		b.Run(fmt.Sprint(n), func(b *testing.B) {
			b.SetBytes(int64(n * _W))
			for i := 0; i < b.N; i++ {
				z.montgomery(mulx, muly, mod, k, n)
			}
		})
	}
}
