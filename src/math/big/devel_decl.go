// +build !math_big_pure_go

package big

// implemented in devel_$GOARCH.s
//go:noescape
func intmult_mulq(z, x, y []Word)

//go:noescape
func intmult_mulx(z, x, y []Word)

//go:noescape
func montReduction_mulx(z, x []Word, k Word) (cout Word)

//go:noescape
func montReduction_mulq(z, x []Word, k Word) (cout Word)
