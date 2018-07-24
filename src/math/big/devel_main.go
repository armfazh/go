package big

import (
	"fmt"
	"strings"
)

//func natFromString(s string) nat {
//	x, _, _, err := nat(nil).scan(strings.NewReader(s), 0, false)
//	if err != nil {
//		panic(err)
//	}
//	return x
//}

func (x nat) PrintHex() {
	fmt.Print("[")
	for i:= range(x) {
		fmt.Printf("0x%016x,",x[i])
	}
	fmt.Println("]")
}

func intmult(z, x, y nat) {
	
//	n := len(y)
//	blocks := n/8
//	remainder := n%8
	
	intmadd512x512(z[ 0:],x[0: 8],y[0: 8])
	intmadd512x512(z[ 8:],x[8:16],y[0: 8])
	intmadd512x512(z[ 8:],x[0: 8],y[8:16])
	intmadd512x512(z[16:],x[8:16],y[8:16])
//	for b := 0; b < 2; b++ {
//		intmadd512xN(z[8*b:],x[8*b:8*b+8],y)
//	}	
	return
}

func test_intmult() {
	x := natFromString("0x2acb12106b44f6632bef94318715f512852b73a92340543c1b72899ebc7ac24816c39c7b1d67528d8a3927ef14a22434bbac41e6731f52ee8f0e425b9df0cc7122f85255696e7019d5f88d062b1c356fb09757f6b2c8ea38f4bff44f757afe8bac0d2e7e0b946169b349eb4178309597f7b537ef4015bb61ac229d29c94a7734")
	y := natFromString("0x6de8e597bf03ee5209a2395dbbad963ddc86f9dcfc32f8c91db039b388b5a78462a8ca7913eba135c146085fa317da0dd02031b11518eb781f9f945057e9b341c902e26a0c13f563dcce8b5805fd69bbd8160640b738c8db8683653b4336b1176b2801892196a6e1b3fe88e51d6476f86e47d99d4d67ee861def612c3877cf07")
	x.PrintHex()
	y.PrintHex()

	n := len(x)
	z := nat(nil).make(2*n)
	z.clear()	
	fmt.Println(n)
	intmult(z,x,y)
	z.PrintHex()
}

func test_nat(){
	
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
	fmt.Printf("y: %x cap: %v\n",y,cap(y))

	
	x, _, _, err = nat(nil).scan(strings.NewReader("AABBCCDDEEFF11223344556677"), 16, false)
	if err != nil {
		panic(err)
	}
	
	
	q := x.make(20)
// var q nat
	q.shl(x, s)
	fmt.Printf("val: %x cap: %v\n", q,cap(q))
	
}
	
func (i Int) MasPruebas() {
	
//	test_nat()
	test_intmult()

}
