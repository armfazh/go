package big

import (
	"fmt"
	"strings"
)

func (i Int) MasPruebas() {
	
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
