// @author Armando Faz

package big

import (
	"internal/cpu"
	"math/rand"
	"testing"
	"time"
)

type intmult func([]Word, []Word, []Word)
type gen_value func() Word

func testIntMult(t *testing.T, f intmult, sizes []int, value gen_value) {

	for i, x_len := range sizes {
		for j, y_len := range sizes {
			x := nat(nil).make(x_len)
			y := nat(nil).make(y_len)
			for t, _ := range x {
				x[t] = value()
			}
			for t, _ := range y {
				y[t] = value()
			}
			got := nat(nil).make(x_len + y_len)
			f(got, x, y)
			got = got.norm()

			want := nat(nil).mul(x, y)
			if got.cmp(want) != 0 {
				t.Errorf("#(%d,%d) got %s want %s", i, j, got.utoa(10), want.utoa(10))
			}
		}
	}
}

func TestIntMult(t *testing.T) {
	r := rand.New(rand.NewSource(int64(time.Now().UnixNano())))
	values := []gen_value{
		func() Word { return 0 },
		func() Word { return 1 },
		func() Word { return (1 << _W) - 1 },
		func() Word { return Word(r.Uint64()) },
	}

	length := make([]int, 64)
	for i, _ := range length {
		length[i] = i
	}

	for _, value := range values {
		testIntMult(t, intmult_mulq, length, value)
		if cpu.X86.HasBMI2 {
			testIntMult(t, intmult_mulx, length, value)
		}
		//	if cpu.X86.HasADX {
		//		testIntMult_allones(t, intmult_mulx, sizes)
		//	}
	}
}
