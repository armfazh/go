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
	//	intmadd1x512(z, x[:16], y)

	//	for i, v := range z {
	//		if v != zz[i] {
	//			fmt.Printf("[NoEqual]\n")
	//		}
	//	}
	return
}

func test_montgo() {
	x := natFromString2("0x580886adb12c922ddb02f87e1c015244869f0afa6f213fb2dc4ed02d882803e67eb8509b324544d09ff0068eed09b0572a4791911622edbf2db96319fc05c8df6bc6ff8ff7d330a8c8db99a0236e7aeaf69d967b3557d1fa4bf95b702fa7839da27a0f4ef7786148a052b0fbab5da43d04cc083f0da8d1178f832696faf9f01ea77f93a4afcd62ff7fb6f9b29240fb96df828ef25456435a35c09bfb99a587c431a913a4b84583d211c3fa276346a590abf51448823894ed4640008ea095d09a1c9f47b22d2330da26f0b05c2107b6a47d7ed09585fb1720edecdd19b11b3c30ee5ead9f2332cd30cf1cb8174b198683c60f521c9dacb8e627360d9ec654b283")
	y := natFromString2("0xc8856e8d5a6c74c97dd55c59be6c75c95e2aed43339055e18d90e0b5a9dd017dffa13f9e8e831f4759f20bf81fcd5d87bb62f639471ab61080ddfbdd614539d5b985cd362c12960c73a9d703109867b3125c5e67d1d976207490ec7728d882d9648c657562c0be07c79208117fa2547fe9bfe183eb950040888c3a4e355c8bcb13dcd2f6432d50bae7f0f1fd9185f77f4746cfefff27f6061e46021c1663de49605dca627c13945929097f9fca26a6efc14c3e90672ae0869e559ec6efff9004b5b904f7ee8463f31245bbd075c9c3894705729652078d9dac21f86933320f198bff1bb345654cbc4461bb639ff96e81b05c5fc9dba5c1b321d43945eee82882")
	m := natFromString2("0x200803d34e9ba567304ee5c4f89b9cb1478aabd4f92bfb597a71390caca3cfe5b1f1b3f1dd380e5c72b84bc6c318b798c4515726cb457a2051fdf7607732c464d166120eb83dc0e078ced8dae9e056d81b304a9de03bf125cdbd3f91d165e088553ff36650c1b7ef8660de2840d7db23b0aa3df6c5d5ebacbd40bd7541bda6272bff6f5116b82fbeb2fbfcd5e9a3c1bb755a2d2c1fcb04878f1de4fccd5c82203daab35854cb71073eed4b7e3c47fff2c242f8b5e2356247862e419335a4c509e9ef28a5491ed79996bde1cab9ad0c481c22ef50afa63eeeb377590ab16d9d7a4de1ab952e8cc564e603db8544d2abd7c8a026f7415dac4b6a253991926e586b")

	/*n := 16
	x := nat(nil).make(n)
	y := nat(nil).make(n)
	m := nat(nil).make(n)

	for i := range x {
		x[i] = 0xffffffffffffffff
	}
	for i := range y {
		y[i] = 0xffffffffffffffff
	}
	for i := range m {
		m[i] = 0xffffffffffffffff
	}*/

	n := len(m)
	x.PrintHex()
	y.PrintHex()
	m.PrintHex()

	var k0 Word
	k0 = 0x51fae29f45bc6bbd
	var z, f nat
	z.make(len(x) + len(y))
	f.make(len(x) + len(y))

	z = z.montgomery(x, y, m, k0, n)
	z.PrintHex()

	f = f.montgomery8x(x, y, m, k0, n)
	f.PrintHex()

	if z.cmp(f) != 0 {
		fmt.Println("Error")
	}
}

func test_intmult() {
	x := natFromString2("0x2acb12106b44f6632bef94318715f512852b73a92340543c1b72899ebc7ac24816c39c7b1d67528d8a3927ef14a22434bbac41e6731f52ee8f0e425b9df0cc7122f85255696e7019d5f88d062b1c356fb09757f6b2c8ea38f4bff44f757afe8bac0d2e7e0b946169b349eb4178309597f7b537ef4015bb61ac229d29c94a773470984321709832174210342187340832142431513")
	y := natFromString2("0x0732104832148325826538246381274832740126136532643265326de8e597bf03ee5209a2395dbbad963ddc86f9dcfc32f8c91db039b388b5a78462a8ca7913eba135c146085fa317da0dd02031b11518eb781f9f945057e9b341c902e26a0c13f563dcce8b5805fd69bbd8160640b738c8db8683653b4336b1176b2801892196a6e1b3fe88e51d6476f86e47d99d4d67ee861d4321423ef612c3877cf07")
	x.PrintHex()
	y.PrintHex()

	z := nat(nil).make(len(x) + len(y))
	z.clear()
	fmt.Printf("lx: %d ly: %d\n", len(x), len(y))

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
	//test_intmult()
	test_montgo()

}
