package big

import (
	"fmt"
	"testing"
)

func BenchmarkFazintmult_mulx(b *testing.B) {
	var benchSizes = []int{8, 16, 24, 32}

	for _, n := range benchSizes {
		x := rndV(n)
		y := rndV(n)
		z := nat(nil).make(len(x) + len(y))
		b.Run(fmt.Sprint(n), func(b *testing.B) {
			b.SetBytes(int64(n * _W))
			for i := 0; i < b.N; i++ {
				intmult_mulx(z, x, y)
			}
		})
	}
}

func BenchmarkFazintmult_mulx_adx(b *testing.B) {
	var benchSizes = []int{8, 16, 24, 32}

	for _, n := range benchSizes {
		x := rndV(n)
		y := rndV(n)
		z := nat(nil).make(len(x) + len(y))
		b.Run(fmt.Sprint(n), func(b *testing.B) {
			b.SetBytes(int64(n * _W))
			for i := 0; i < b.N; i++ {
				intmult_mulx_adx(z, x, y)
			}
		})
	}
}

func BenchmarkFazintmult_mulq(b *testing.B) {
	var benchSizes = []int{8, 16, 24, 32}

	for _, n := range benchSizes {
		x := rndV(n)
		y := rndV(n)
		z := nat(nil).make(len(x) + len(y))
		b.Run(fmt.Sprint(n), func(b *testing.B) {
			b.SetBytes(int64(n * _W))
			for i := 0; i < b.N; i++ {
				intmult_mulq(z, x, y)
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
		//		z := nat(nil).make(len(mulx) + len(muly))
		var z nat
		b.Run(fmt.Sprint(n), func(b *testing.B) {
			b.SetBytes(int64(n * _W))
			for i := 0; i < b.N; i++ {
				z.montgomery(mulx, muly, mod, k, n)
			}
		})
	}
}

func BenchmarkFazMontgomery_mulx(b *testing.B) {
	var benchSizes = []int{8, 16, 24, 32}
	var k Word
	k = (1 << 64) - 1
	for _, n := range benchSizes {
		mulx := rndV(n)
		muly := rndV(n)
		mod := rndV(n)
		buffer := nat(nil).make(len(mulx) + len(muly))
		var z nat
		b.Run(fmt.Sprint(n), func(b *testing.B) {
			b.SetBytes(int64(n * _W))
			for i := 0; i < b.N; i++ {
				z.montgomery_opt(mulx, muly, mod, buffer, k)
			}
		})
	}
}

/*
func BenchmarkFazMontgomery_mulq(b *testing.B) {
	var benchSizes = []int{8, 16, 24, 32}
	var k Word
	k = (1 << 64) - 1
	for _, n := range benchSizes {
		mulx := rndV(n)
		muly := rndV(n)
		mod := rndV(n)
		//		z := nat(nil).make(len(mulx) + len(muly))
		var z nat
		b.Run(fmt.Sprint(n), func(b *testing.B) {
			b.SetBytes(int64(n * _W))
			for i := 0; i < b.N; i++ {
				z.montgomery8x_mulq(mulx, muly, mod, k, n)
			}
		})
	}
}
*/
