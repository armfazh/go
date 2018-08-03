// +build !math_big_pure_go

package big

// implemented in devel_$GOARCH.s
func intmadd512Nx512N(z, x, y []Word)
func intmadd64x512N(z, x []Word, k Word) (cout Word)
