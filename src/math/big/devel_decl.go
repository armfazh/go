
// +build !math_big_pure_go	

package big

// implemented in devel_$GOARCH.s
func addMulVVWunrolled(z, x []Word, y Word) (c Word)