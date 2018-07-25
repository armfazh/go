package big

import (
	"fmt"
	"testing"
)


func BenchmarkFazMontgomery(b *testing.B) {
	
	mulx := natFromString("0x2acb12106b44f6632bef94318715f512852b73a92340543c1b72899ebc7ac24816c39c7b1d67528d8a3927ef14a22434bbac41e6731f52ee8f0e425b9df0cc7122f85255696e7019d5f88d062b1c356fb09757f6b2c8ea38f4bff44f757afe8bac0d2e7e0b946169b349eb4178309597f7b537ef4015bb61ac229d29c94a7734")
	muly := natFromString("0x6de8e597bf03ee5209a2395dbbad963ddc86f9dcfc32f8c91db039b388b5a78462a8ca7913eba135c146085fa317da0dd02031b11518eb781f9f945057e9b341c902e26a0c13f563dcce8b5805fd69bbd8160640b738c8db8683653b4336b1176b2801892196a6e1b3fe88e51d6476f86e47d99d4d67ee861def612c3877cf07")
	mod  := natFromString("0x15cec62c593e3bd389f348ebae6e4ccf10d18d54003fe946b35f3fe539b10e8b850e911e18a3bd1e55d3f999ef33e3f89c021bcb8655e377ba5d95187b45e727d3a088049649154304c8e8bcf5668ff8928c95f4284706d1dd0e7ce45feb07e0d27fa84e27acf16d87ac58043815bce11b892feb929ee887e5ed0de22b92a375")

	var z nat
	n := len(mulx)
	z = z.make(2 * n)

	var k Word
	k = (1 << 64) - 1

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		z.montgomery(mulx, muly, mod, k, n)
	}
}

func BenchmarkFazMul512(b *testing.B) {
	x := natFromString("0x2acb12106b44f6632bef94318715f512852b73a92340543c1b72899ebc7ac24816c39c7b1d67528d8a3927ef14a22434bbac41e6731f52ee8f0e425b9df0cc7122f85255696e7019d5f88d062b1c356fb09757f6b2c8ea38f4bff44f757afe8bac0d2e7e0b946169b349eb4178309597f7b537ef4015bb61ac229d29c94a7734")
	y := natFromString("0x6de8e597bf03ee5209a2395dbbad963ddc86f9dcfc32f8c91db039b388b5a78462a8ca7913eba135c146085fa317da0dd02031b11518eb781f9f945057e9b341c902e26a0c13f563dcce8b5805fd69bbd8160640b738c8db8683653b4336b1176b2801892196a6e1b3fe88e51d6476f86e47d99d4d67ee861def612c3877cf07")

	var z nat
	z = z.make(len(x)+len(y))
	
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		intmaddNxN(z,x,y)
	}
}

func BenchmarkFazMulSingle(b *testing.B) {
	x := natFromString("0x2acb12106b44f6632bef94318715f512852b73a92340543c1b72899ebc7ac24816c39c7b1d67528d8a3927ef14a22434bbac41e6731f52ee8f0e425b9df0cc7122f85255696e7019d5f88d062b1c356fb09757f6b2c8ea38f4bff44f757afe8bac0d2e7e0b946169b349eb4178309597f7b537ef4015bb61ac229d29c94a7734")
	y := natFromString("0x6de8e597bf03ee5209a2395dbbad963ddc86f9dcfc32f8c91db039b388b5a78462a8ca7913eba135c146085fa317da0dd02031b11518eb781f9f945057e9b341c902e26a0c13f563dcce8b5805fd69bbd8160640b738c8db8683653b4336b1176b2801892196a6e1b3fe88e51d6476f86e47d99d4d67ee861def612c3877cf07")

	var z nat
	z = z.make(len(x)+len(y))
	
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		addmulNxN(z,x,y)
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

func BenchmarkFazMul(b *testing.B) {
	mulx := natFromString("0x2acb12106b44f6632bef94318715f512852b73a92340543c1b72899ebc7ac24816c39c7b1d67528d8a3927ef14a22434bbac41e6731f52ee8f0e425b9df0cc7122f85255696e7019d5f88d062b1c356fb09757f6b2c8ea38f4bff44f757afe8bac0d2e7e0b946169b349eb4178309597f7b537ef4015bb61ac229d29c94a7734")
	muly := natFromString("0x6de8e597bf03ee5209a2395dbbad963ddc86f9dcfc32f8c91db039b388b5a78462a8ca7913eba135c146085fa317da0dd02031b11518eb781f9f945057e9b341c902e26a0c13f563dcce8b5805fd69bbd8160640b738c8db8683653b4336b1176b2801892196a6e1b3fe88e51d6476f86e47d99d4d67ee861def612c3877cf07")
	
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		var z nat
		z.mul(mulx, muly)
	}
}

func BenchmarkFazbasicMul(b *testing.B) {
	mulx := natFromString("0x2acb12106b44f6632bef94318715f512852b73a92340543c1b72899ebc7ac24816c39c7b1d67528d8a3927ef14a22434bbac41e6731f52ee8f0e425b9df0cc7122f85255696e7019d5f88d062b1c356fb09757f6b2c8ea38f4bff44f757afe8bac0d2e7e0b946169b349eb4178309597f7b537ef4015bb61ac229d29c94a7734")
	muly := natFromString("0x6de8e597bf03ee5209a2395dbbad963ddc86f9dcfc32f8c91db039b388b5a78462a8ca7913eba135c146085fa317da0dd02031b11518eb781f9f945057e9b341c902e26a0c13f563dcce8b5805fd69bbd8160640b738c8db8683653b4336b1176b2801892196a6e1b3fe88e51d6476f86e47d99d4d67ee861def612c3877cf07")
	
	var z nat
	n := len(mulx)
	z = z.make(2 * n)

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		basicMul(z, mulx, muly)
	}
}

func BenchmarkFazSqr(b *testing.B) {
	var mulx nat
	mulx = natFromString("812057848953725743532498894375134890158458463578463856324783543381205784895372574353249889437513489015845846357846385632478354338120578489537257435324988943751348901584584635784638563247835433812057848953725743532498894375134890158458463578463856324783543381205784895372574353249889437513489015845846357846385632478354338120578489537257435324988943751348901584584635784638563247835433")

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		var z nat
		z.sqr(mulx)
	}
}

func BenchmarkFazbasicSqr(b *testing.B) {
	var mulx nat
	mulx = natFromString("812057848953725743532498894375134890158458463578463856324783543381205784895372574353249889437513489015845846357846385632478354338120578489537257435324988943751348901584584635784638563247835433812057848953725743532498894375134890158458463578463856324783543381205784895372574353249889437513489015845846357846385632478354338120578489537257435324988943751348901584584635784638563247835433")

	var z nat
	n := len(mulx)
	z = z.make(2 * n)

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		basicSqr(z, mulx)
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

