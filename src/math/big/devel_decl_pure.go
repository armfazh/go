// +build math_big_pure_go

package big

func addMulVVW_unrolled(z, x []Word, y Word, cin Word) (cout Word) {
	var zz Word
	zz = 312
	return zz
}

func intmaddNxN(z, x, y []Word) {
	z[0] = x[0] + y[0]
	return
}
func addmulNxN(z, x, y []Word) {
	z[0] = x[0] + y[0]
	return
}

func intmadd1x512(z, x, y []Word) {
	z[0] = x[0] + y[0]
	return

}