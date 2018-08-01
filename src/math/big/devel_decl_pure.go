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

func intmadd64x512(z, x []Word, y Word, cin Word) (cout Word) {
	z[0] = x[0] + y
	return cin + 5
}
func intmadd64x1024(z, x []Word, y Word, cin Word) (cout Word) {
	z[0] = x[0] + y
	return cin + 5
}
func intmadd64x1536(z, x []Word, y Word, cin Word) (cout Word) {
	z[0] = x[0] + y
	return cin + 5
}
func intmadd64x2048(z, x []Word, y Word, cin Word) (cout Word) {
	z[0] = x[0] + y
	return cin + 5
}

func intmadd512Nx512N(z, x, y []Word) {
	z[0] = x[0] + y[0]
	return
}
func intmadd512x512(z, x, y []Word) {
	z[0] = x[0] + y[0]
	return
}
func intmadd1024x1024(z, x, y []Word) {
	z[0] = x[0] + y[0]
	return
}
func intmadd1536x1536(z, x, y []Word) {
	z[0] = x[0] + y[0]
	return
}
func intmadd2048x2048(z, x, y []Word) {
	z[0] = x[0] + y[0]
	return
}
