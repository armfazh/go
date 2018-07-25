package big

import (
	"fmt"
	"testing"
)

func BenchmarkFazMontgomery(b *testing.B) {
	var benchSizes = []int{8, 16, 32, 64}
	var k Word
	k = (1 << 64) - 1
	for _, n := range benchSizes {
		mulx := rndV(n)
		muly := rndV(n)
		mod := rndV(n)
		z := nat(nil).make(len(mulx) + len(muly))
		b.Run(fmt.Sprint(n), func(b *testing.B) {
			b.SetBytes(int64(n * _W))
			for i := 0; i < b.N; i++ {
				z.montgomery(mulx, muly, mod, k, n)
			}
		})
	}
}

func BenchmarkFazIntMul(b *testing.B) {
	var benchSizes = []int{8, 16, 32, 64}

	for _, n := range benchSizes {
		mulx := rndV(n)
		muly := rndV(n)
		z := nat(nil).make(len(mulx) + len(muly))
		z.clear()
		b.Run(fmt.Sprint(n), func(b *testing.B) {
			b.SetBytes(int64(n * _W))
			for i := 0; i < b.N; i++ {
				intmaddNxN(z, mulx, muly)
			}
		})
	}
}

func BenchmarkFazIntMulSingle(b *testing.B) {
	var benchSizes = []int{8, 16, 32, 64}

	for _, n := range benchSizes {
		mulx := rndV(n)
		muly := rndV(n)
		z := nat(nil).make(len(mulx) + len(muly))
		z.clear()
		b.Run(fmt.Sprint(n), func(b *testing.B) {
			b.SetBytes(int64(n * _W))
			for i := 0; i < b.N; i++ {
				addmulNxN(z, mulx, muly)
			}
		})
	}
}

func BenchmarkFazMul(b *testing.B) {
	var benchSizes = []int{8, 16, 32, 64}

	for _, n := range benchSizes {
		mulx := rndV(n)
		muly := rndV(n)
		z := nat(nil).make(len(mulx) + len(muly))
		z.clear()
		b.Run(fmt.Sprint(n), func(b *testing.B) {
			b.SetBytes(int64(n * _W))
			for i := 0; i < b.N; i++ {
				z.mul(mulx, muly)
			}
		})
	}
}

func BenchmarkFazbasicMul(b *testing.B) {
	var benchSizes = []int{8, 16, 32, 64}

	for _, n := range benchSizes {
		mulx := rndV(n)
		muly := rndV(n)
		z := nat(nil).make(len(mulx) + len(muly))
		z.clear()
		b.Run(fmt.Sprint(n), func(b *testing.B) {
			b.SetBytes(int64(n * _W))
			for i := 0; i < b.N; i++ {
				basicMul(z, mulx, muly)
			}
		})
	}
}

func BenchmarkFazSqr(b *testing.B) {
	var benchSizes = []int{8, 16, 32, 64}

	for _, n := range benchSizes {
		mulx := rndV(n)
		z := nat(nil).make(2 * len(mulx))
		z.clear()
		b.Run(fmt.Sprint(n), func(b *testing.B) {
			b.SetBytes(int64(n * _W))
			for i := 0; i < b.N; i++ {
				z.sqr(mulx)
			}
		})
	}
}

func BenchmarkFazbasicSqr(b *testing.B) {
	var benchSizes = []int{8, 16, 32, 64}

	for _, n := range benchSizes {
		mulx := rndV(n)
		z := nat(nil).make(2 * len(mulx))
		z.clear()
		b.Run(fmt.Sprint(n), func(b *testing.B) {
			b.SetBytes(int64(n * _W))
			for i := 0; i < b.N; i++ {
				basicSqr(z, mulx)
			}
		})
	}
}

func BenchmarkFazAddMulVVW_unrolled(b *testing.B) {
	//	var benchSizes = []int{1, 2, 3, 4, 5, 1e1, 1e2, 1e3, 1e4, 1e5}
	var benchSizes = []int{16}

	for _, n := range benchSizes {
		x := rndV(n)
		y := rndW()
		z := make([]Word, n)
		b.Run(fmt.Sprint(n), func(b *testing.B) {
			b.SetBytes(int64(n * _W))
			for i := 0; i < b.N; i++ {
				addMulVVW_unrolled(z, x, y)
			}
		})
	}
}

func BenchmarkFazAddMulVVW(b *testing.B) {
	//	var benchSizes = []int{1, 2, 3, 4, 5, 1e1, 1e2, 1e3, 1e4, 1e5}
	var benchSizes = []int{16}

	for _, n := range benchSizes {
		x := rndV(n)
		y := rndW()
		z := make([]Word, n)
		b.Run(fmt.Sprint(n), func(b *testing.B) {
			b.SetBytes(int64(n * _W))
			for i := 0; i < b.N; i++ {
				addMulVVW(z, x, y)
			}
		})
	}
}

func BenchmarkFazMulAddVWW(b *testing.B) {
	//	var benchSizes = []int{1, 2, 3, 4, 5, 1e1, 1e2, 1e3, 1e4, 1e5}
	var benchSizes = []int{16}

	for _, n := range benchSizes {
		x := rndV(n)
		y := rndW()
		z := make([]Word, n)
		b.Run(fmt.Sprint(n), func(b *testing.B) {
			b.SetBytes(int64(n * _W))
			for i := 0; i < b.N; i++ {
				mulAddVWW(z, x, y, 0)
			}
		})
	}
}
func BenchmarkFazExp(b *testing.B) {
	x, _ := new(Int).SetString("11001289118363089646017359372117963499250546375269047542777928006103246876688756735760905680604646624353196869572752623285140408755420374049317646428185270079555372763503115646054602867593662923894140940837479507194934267532831694565516466765025434902348314525627418515646588160955862839022051353653052947073136084780742729727874803457643848197499548297570026926927502505634297079527299004267769780768565695459945235586892627059178884998772989397505061206395455591503771677500931269477503508150175717121828518985901959919560700853226255420793148986854391552859459511723547532575574664944815966793196961286234040892865", 0)
	y, _ := new(Int).SetString("0xAC6BDB41324A9A9BF166DE5E1389582FAF72B6651987EE07FC3192943DB56050A37329CBB4A099ED8193E0757767A13DD52312AB4B03310DCD7F48A9DA04FD50E8083969EDB767B0CF6095179A163AB3661A05FBD5FAAAE82918A9962F0B93B855F97993EC975EEAA80D740ADBF4FF747359D041D5C33EA71D281E446B14773BCA97B43A23FB801676BD207A436C6481F1D2B9078717461A5B9D32E688F87748544523B524B0D57D5EA77A2775D2ECFA032CFBDBF52FB3786160279004E57AE6AF874E7303CE53299CCC041C7BC308D82A5698F3A8D0C38271AE35F8E9DBFBB694B5C803D89F7AE435DE236D525F54759B65E372FCD68EF20FA7111F9E4AFF72", 0)
	n, _ := new(Int).SetString("0xAC6BDB41324A9A9BF166DE5E1389582FAF72B6651987EE07FC3192943DB56050A37329CBB4A099ED8193E0757767A13DD52312AB4B03310DCD7F48A9DA04FD50E8083969EDB767B0CF6095179A163AB3661A05FBD5FAAAE82918A9962F0B93B855F97993EC975EEAA80D740ADBF4FF747359D041D5C33EA71D281E446B14773BCA97B43A23FB801676BD207A436C6481F1D2B9078717461A5B9D32E688F87748544523B524B0D57D5EA77A2775D2ECFA032CFBDBF52FB3786160279004E57AE6AF874E7303CE53299CCC041C7BC308D82A5698F3A8D0C38271AE35F8E9DBFBB694B5C803D89F7AE435DE236D525F54759B65E372FCD68EF20FA7111F9E4AFF73", 0)
	out := new(Int)
	for i := 0; i < b.N; i++ {
		out.Exp(x, y, n)
	}
}

func BenchmarkFazExp2(b *testing.B) {
	x, _ := new(Int).SetString("2", 0)
	y, _ := new(Int).SetString("0xAC6BDB41324A9A9BF166DE5E1389582FAF72B6651987EE07FC3192943DB56050A37329CBB4A099ED8193E0757767A13DD52312AB4B03310DCD7F48A9DA04FD50E8083969EDB767B0CF6095179A163AB3661A05FBD5FAAAE82918A9962F0B93B855F97993EC975EEAA80D740ADBF4FF747359D041D5C33EA71D281E446B14773BCA97B43A23FB801676BD207A436C6481F1D2B9078717461A5B9D32E688F87748544523B524B0D57D5EA77A2775D2ECFA032CFBDBF52FB3786160279004E57AE6AF874E7303CE53299CCC041C7BC308D82A5698F3A8D0C38271AE35F8E9DBFBB694B5C803D89F7AE435DE236D525F54759B65E372FCD68EF20FA7111F9E4AFF72", 0)
	n, _ := new(Int).SetString("0xAC6BDB41324A9A9BF166DE5E1389582FAF72B6651987EE07FC3192943DB56050A37329CBB4A099ED8193E0757767A13DD52312AB4B03310DCD7F48A9DA04FD50E8083969EDB767B0CF6095179A163AB3661A05FBD5FAAAE82918A9962F0B93B855F97993EC975EEAA80D740ADBF4FF747359D041D5C33EA71D281E446B14773BCA97B43A23FB801676BD207A436C6481F1D2B9078717461A5B9D32E688F87748544523B524B0D57D5EA77A2775D2ECFA032CFBDBF52FB3786160279004E57AE6AF874E7303CE53299CCC041C7BC308D82A5698F3A8D0C38271AE35F8E9DBFBB694B5C803D89F7AE435DE236D525F54759B65E372FCD68EF20FA7111F9E4AFF73", 0)
	out := new(Int)
	for i := 0; i < b.N; i++ {
		out.Exp(x, y, n)
	}
}
