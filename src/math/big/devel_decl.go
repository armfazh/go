
// +build !math_big_pure_go	

package big

// implemented in devel_$GOARCH.s
func addMulVVW_unrolled(z, x []Word, y Word) (c Word)
func intmadd512xN(z, x, y []Word) 