// +build !math_big_pure_go

package big

// implemented in devel_$GOARCH.s
//go:noescape
func intmult_mulq(z, x, y []Word)

//go:noescape
func intmult_mulx(z, x, y []Word)

//go:noescape
func intmadd64x512N(z, x []Word, k Word) (cout Word)
