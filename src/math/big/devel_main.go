package big

import (
	"fmt"
	"strings"
)

func natFromString2(s string) nat {
	x, _, _, err := nat(nil).scan(strings.NewReader(s), 0, false)
	if err != nil {
		panic(err)
	}
	return x
}

func (x nat) PrintHex() {
	fmt.Print("[")
	for i := range x {
		fmt.Printf("0x%016x,", x[i])
	}
	fmt.Println("]")
}

func intmult(z, x, y nat) {

	//	n := len(y)
	//	blocks := n/8
	//	remainder := n%8

	//	zz := nat(nil).make(len(z))
	//	zz.clear()
	//	addmul64xN(zz,x[:16],y)
	//	zz.PrintHex()

	//	intmaddNxN(z, x, y)
	intmadd1x512(z, x[:16], y)

	//	for i, v := range z {
	//		if v != zz[i] {
	//			fmt.Printf("[NoEqual]\n")
	//		}
	//	}
	return
}

func test_montgo() {
//	x := natFromString2("0x42d6a0e4cff274f79d86193a51bc588c337e4774ded7691ea5a7f21609422e05fb6e7123ff9d98c44ec46973e579c654174d4e4c17501ee2142342847329432234284732230743298bacaacdefacafceafceefacafacdec9432347daf46d7be6a3f563dcce8b5805fd69bbd8160640b738c8db8683653b433cadecafceaecfa9874231749237429723504385704570435943f563dcce8b5805fd69bbd8160")
//	y := natFromString2("0xe8b2ba200c3bf580ae036abdebee429b22ca7ba788ede537046d07e3b2b83e0d0bdb0f3395b5e7cb2c0afd98183071073a3872a8939e4e5c6392c4b397a5307148237013275813240273208538473483243984328bb48320432423894732840237423b48320432423894732840237423b48320432423894732840237423b48320432423894732840237423b48320432423894732840237423428473294321")
//	m := natFromString2("0x0732104832148325826538246381274832740126136532643265326de8e597bf03ee5209a2395dbbad963ddc86f9dcfc32f8c91db039b388b5a78462a8ca7913eba135c146085fa317da0dd02031b11518eb781f9f945057e9b341c902e26a0c13f563dcce8b5805fd69bbd8160640b738c8db8683653b4336b1176b2801892196a6e1b3fe88e51d6476f86e47d99d4d67ee861d4321423ef612c3877cf07")
	//	m := natFromString2("0xe8b2ba200c3bf580ae036abdebee429b22ca7ba788ede537046d07e3b2b83e0d0bdb0f3395b5e7cb2c0afd98183071073a3872a8939e4e5c6392c4b397a531d7")

	x := nat(nil).make(21)
	y := nat(nil).make(21)
	m := nat(nil).make(21)

	for i := range(x) {
		x[i] = 0xffffffffffffffff
	}
	for i := range(y) {
		y[i] = 0xffffffffffffffff
	}
	for i := range(m) {
		m[i] = 0xffffffffffffffff
	}

	x.PrintHex()
	y.PrintHex()
	m.PrintHex()

	var k0 Word
	k0 = 0xdecc8f1249812adf
	var z nat
	z = nat(nil).montgomery(x, y, m, k0, len(m))
//	z.PrintHex()

	f := nat(nil).montgomery512(x, y, m, k0, len(m))
	f.PrintHex()

	if z.cmp(f) != 0 {
		fmt.Println("Error")
	}

	//	z := nat(nil).make(len(x) + len(y))
	//	z.clear()
	//	fmt.Printf("lx: %d ly: %d\n", len(x), len(y))
	//	intmult(z, x, y)
	//	z.PrintHex()
}

func test_intmult() {
	x := natFromString2("0x2acb12106b44f6632bef94318715f512852b73a92340543c1b72899ebc7ac24816c39c7b1d67528d8a3927ef14a22434bbac41e6731f52ee8f0e425b9df0cc7122f85255696e7019d5f88d062b1c356fb09757f6b2c8ea38f4bff44f757afe8bac0d2e7e0b946169b349eb4178309597f7b537ef4015bb61ac229d29c94a773470984321709832174210342187340832142431513")
	y := natFromString2("0x0732104832148325826538246381274832740126136532643265326de8e597bf03ee5209a2395dbbad963ddc86f9dcfc32f8c91db039b388b5a78462a8ca7913eba135c146085fa317da0dd02031b11518eb781f9f945057e9b341c902e26a0c13f563dcce8b5805fd69bbd8160640b738c8db8683653b4336b1176b2801892196a6e1b3fe88e51d6476f86e47d99d4d67ee861d4321423ef612c3877cf07")
	x.PrintHex()
	y.PrintHex()

	z := nat(nil).make(len(x) + len(y))
	z.clear()
	fmt.Printf("lx: %d ly: %d\n", len(x), len(y))
	intmult(z, x, y)
	z.PrintHex()
}

func test_nat() {

	x, _, _, err := nat(nil).scan(strings.NewReader("AABBCCDDEEFF11223344556677"), 16, false)
	if err != nil {
		panic(err)
	}

	fmt.Printf("val: %x\n", x)

	var s uint
	var z nat
	s = 1024
	m := len(x)
	if m == 0 {

		fmt.Printf("ret 0")
	}
	// m > 0
	n := m + int(s/_W)
	fmt.Printf("n: %x\n", n)
	z = z.make(n + 1)
	fmt.Printf("z: %x\n", z)
	z[n] = shlVU(z[n-m:n], x, s%_W)

	fmt.Printf("z: %x\n", z)
	z[0 : n-m].clear()
	fmt.Printf("z: %x\n", z)
	y := z.norm()
	fmt.Printf("y: %x cap: %v\n", y, cap(y))

	x, _, _, err = nat(nil).scan(strings.NewReader("AABBCCDDEEFF11223344556677"), 16, false)
	if err != nil {
		panic(err)
	}

	q := x.make(20)
	// var q nat
	q.shl(x, s)
	fmt.Printf("val: %x cap: %v\n", q, cap(q))

}

func (i Int) MasPruebas() {

	//	test_nat()
	//	test_intmult()
	test_montgo()

}
