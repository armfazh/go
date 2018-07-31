// +build !math_big_pure_go

package big

// implemented in devel_$GOARCH.s
func addMulVVW_unrolled(z, x []Word, y Word, cin Word) (cout Word)
func intmaddNxN(z, x, y []Word)
func addmulNxN(z, x, y []Word)
func intmadd1x512(z, x, y []Word)

// implemented using MULX
func intmadd512x512(z, x, y []Word)
func intmadd64x512(z, x []Word, y Word, n int, cin Word) (cout Word)
