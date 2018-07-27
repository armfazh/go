// Copyright 2009 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package big

import (
	//	"fmt"
	"testing"
	//	"testing/quick"
)

func TestMontgomery512(t *testing.T) {
	one := NewInt(1)
	_B := new(Int).Lsh(one, _W)
	for i, test := range montgomeryTests {
		x := natFromString(test.x)
		y := natFromString(test.y)
		m := natFromString(test.m)
		for len(x) < len(m) {
			x = append(x, 0)
		}
		for len(y) < len(m) {
			y = append(y, 0)
		}

		if x.cmp(m) > 0 {
			_, r := nat(nil).div(nil, x, m)
			t.Errorf("#%d: x > m (0x%s > 0x%s; use 0x%s)", i, x.utoa(16), m.utoa(16), r.utoa(16))
		}
		if y.cmp(m) > 0 {
			_, r := nat(nil).div(nil, x, m)
			t.Errorf("#%d: y > m (0x%s > 0x%s; use 0x%s)", i, y.utoa(16), m.utoa(16), r.utoa(16))
		}

		var out nat
		if _W == 32 {
			out = natFromString(test.out32)
		} else {
			out = natFromString(test.out64)
		}

		// t.Logf("#%d: len=%d\n", i, len(m))

		// check output in table
		xi := &Int{abs: x}
		yi := &Int{abs: y}
		mi := &Int{abs: m}
		p := new(Int).Mod(new(Int).Mul(xi, new(Int).Mul(yi, new(Int).ModInverse(new(Int).Lsh(one, uint(len(m))*_W), mi))), mi)
		if out.cmp(p.abs.norm()) != 0 {
			t.Errorf("#%d: out in table=0x%s, computed=0x%s", i, out.utoa(16), p.abs.norm().utoa(16))
		}

		// check k0 in table
		k := new(Int).Mod(&Int{abs: m}, _B)
		k = new(Int).Sub(_B, k)
		k = new(Int).Mod(k, _B)
		k0 := Word(new(Int).ModInverse(k, _B).Uint64())
		if k0 != Word(test.k0) {
			t.Errorf("#%d: k0 in table=%#x, computed=%#x\n", i, test.k0, k0)
		}

		// check montgomery with correct k0 produces correct output
		z := nat(nil).montgomery512(x, y, m, k0, len(m))
		z = z.norm()
		if z.cmp(out) != 0 {
			t.Errorf("#%d: got 0x%s want 0x%s", i, z.utoa(16), out.utoa(16))
		}
	}
}


var devel_expTests = []struct {
	x, y, m string
	out     string
}{
	// y <= 0
	{"0", "0", "", "1"},
	{"1", "0", "", "1"},
	{"-10", "0", "", "1"},
	{"1234", "-1", "", "1"},

	// m == 1
	{"0", "0", "1", "0"},
	{"1", "0", "1", "0"},
	{"-10", "0", "1", "0"},
	{"1234", "-1", "1", "0"},

	// misc
	{"5", "1", "3", "2"},
	{"5", "-7", "", "1"},
	{"-5", "-7", "", "1"},
	{"5", "0", "", "1"},
	{"-5", "0", "", "1"},
	{"5", "1", "", "5"},
	{"-5", "1", "", "-5"},
	{"-5", "1", "7", "2"},
	{"-2", "3", "2", "0"},
	{"5", "2", "", "25"},
	{"1", "65537", "2", "1"},
	{"0x8000000000000000", "2", "", "0x40000000000000000000000000000000"},
	{"0x8000000000000000", "2", "6719", "4944"},
	{"0x8000000000000000", "3", "6719", "5447"},
	{"0x8000000000000000", "1000", "6719", "1603"},
	{"0x8000000000000000", "1000000", "6719", "3199"},
	{"0x8000000000000000", "-1000000", "6719", "1"},

	{"0xffffffffffffffffffffffffffffffff", "0x12345678123456781234567812345678123456789", "0x01112222333344445555666677778889", "0x36168FA1DB3AAE6C8CE647E137F97A"},

	{
		"2938462938472983472983659726349017249287491026512746239764525612965293865296239471239874193284792387498274256129746192347",
		"298472983472983471903246121093472394872319615612417471234712061",
		"29834729834729834729347290846729561262544958723956495615629569234729836259263598127342374289365912465901365498236492183464",
		"23537740700184054162508175125554701713153216681790245129157191391322321508055833908509185839069455749219131480588829346291",
	},
	// test case for issue 8822
	{
		"11001289118363089646017359372117963499250546375269047542777928006103246876688756735760905680604646624353196869572752623285140408755420374049317646428185270079555372763503115646054602867593662923894140940837479507194934267532831694565516466765025434902348314525627418515646588160955862839022051353653052947073136084780742729727874803457643848197499548297570026926927502505634297079527299004267769780768565695459945235586892627059178884998772989397505061206395455591503771677500931269477503508150175717121828518985901959919560700853226255420793148986854391552859459511723547532575574664944815966793196961286234040892865",
		"0xB08FFB20760FFED58FADA86DFEF71AD72AA0FA763219618FE022C197E54708BB1191C66470250FCE8879487507CEE41381CA4D932F81C2B3F1AB20B539D50DCD",
		"0xAC6BDB41324A9A9BF166DE5E1389582FAF72B6651987EE07FC3192943DB56050A37329CBB4A099ED8193E0757767A13DD52312AB4B03310DCD7F48A9DA04FD50E8083969EDB767B0CF6095179A163AB3661A05FBD5FAAAE82918A9962F0B93B855F97993EC975EEAA80D740ADBF4FF747359D041D5C33EA71D281E446B14773BCA97B43A23FB801676BD207A436C6481F1D2B9078717461A5B9D32E688F87748544523B524B0D57D5EA77A2775D2ECFA032CFBDBF52FB3786160279004E57AE6AF874E7303CE53299CCC041C7BC308D82A5698F3A8D0C38271AE35F8E9DBFBB694B5C803D89F7AE435DE236D525F54759B65E372FCD68EF20FA7111F9E4AFF73",
		"21484252197776302499639938883777710321993113097987201050501182909581359357618579566746556372589385361683610524730509041328855066514963385522570894839035884713051640171474186548713546686476761306436434146475140156284389181808675016576845833340494848283681088886584219750554408060556769486628029028720727393293111678826356480455433909233520504112074401376133077150471237549474149190242010469539006449596611576612573955754349042329130631128234637924786466585703488460540228477440853493392086251021228087076124706778899179648655221663765993962724699135217212118535057766739392069738618682722216712319320435674779146070442",
	},
	{
		"-0x1BCE04427D8032319A89E5C4136456671AC620883F2C4139E57F91307C485AD2D6204F4F87A58262652DB5DBBAC72B0613E51B835E7153BEC6068F5C8D696B74DBD18FEC316AEF73985CF0475663208EB46B4F17DD9DA55367B03323E5491A70997B90C059FB34809E6EE55BCFBD5F2F52233BFE62E6AA9E4E26A1D4C2439883D14F2633D55D8AA66A1ACD5595E778AC3A280517F1157989E70C1A437B849F1877B779CC3CDDEDE2DAA6594A6C66D181A00A5F777EE60596D8773998F6E988DEAE4CCA60E4DDCF9590543C89F74F603259FCAD71660D30294FBBE6490300F78A9D63FA660DC9417B8B9DDA28BEB3977B621B988E23D4D954F322C3540541BC649ABD504C50FADFD9F0987D58A2BF689313A285E773FF02899A6EF887D1D4A0D2",
		"0xB08FFB20760FFED58FADA86DFEF71AD72AA0FA763219618FE022C197E54708BB1191C66470250FCE8879487507CEE41381CA4D932F81C2B3F1AB20B539D50DCD",
		"0xAC6BDB41324A9A9BF166DE5E1389582FAF72B6651987EE07FC3192943DB56050A37329CBB4A099ED8193E0757767A13DD52312AB4B03310DCD7F48A9DA04FD50E8083969EDB767B0CF6095179A163AB3661A05FBD5FAAAE82918A9962F0B93B855F97993EC975EEAA80D740ADBF4FF747359D041D5C33EA71D281E446B14773BCA97B43A23FB801676BD207A436C6481F1D2B9078717461A5B9D32E688F87748544523B524B0D57D5EA77A2775D2ECFA032CFBDBF52FB3786160279004E57AE6AF874E7303CE53299CCC041C7BC308D82A5698F3A8D0C38271AE35F8E9DBFBB694B5C803D89F7AE435DE236D525F54759B65E372FCD68EF20FA7111F9E4AFF73",
		"21484252197776302499639938883777710321993113097987201050501182909581359357618579566746556372589385361683610524730509041328855066514963385522570894839035884713051640171474186548713546686476761306436434146475140156284389181808675016576845833340494848283681088886584219750554408060556769486628029028720727393293111678826356480455433909233520504112074401376133077150471237549474149190242010469539006449596611576612573955754349042329130631128234637924786466585703488460540228477440853493392086251021228087076124706778899179648655221663765993962724699135217212118535057766739392069738618682722216712319320435674779146070442",
	},

	// test cases for issue 13907
	{"0xffffffff00000001", "0xffffffff00000001", "0xffffffff00000001", "0"},
	{"0xffffffffffffffff00000001", "0xffffffffffffffff00000001", "0xffffffffffffffff00000001", "0"},
	{"0xffffffffffffffffffffffff00000001", "0xffffffffffffffffffffffff00000001", "0xffffffffffffffffffffffff00000001", "0"},
	{"0xffffffffffffffffffffffffffffffff00000001", "0xffffffffffffffffffffffffffffffff00000001", "0xffffffffffffffffffffffffffffffff00000001", "0"},

	{
		"2",
		"0xB08FFB20760FFED58FADA86DFEF71AD72AA0FA763219618FE022C197E54708BB1191C66470250FCE8879487507CEE41381CA4D932F81C2B3F1AB20B539D50DCD",
		"0xAC6BDB41324A9A9BF166DE5E1389582FAF72B6651987EE07FC3192943DB56050A37329CBB4A099ED8193E0757767A13DD52312AB4B03310DCD7F48A9DA04FD50E8083969EDB767B0CF6095179A163AB3661A05FBD5FAAAE82918A9962F0B93B855F97993EC975EEAA80D740ADBF4FF747359D041D5C33EA71D281E446B14773BCA97B43A23FB801676BD207A436C6481F1D2B9078717461A5B9D32E688F87748544523B524B0D57D5EA77A2775D2ECFA032CFBDBF52FB3786160279004E57AE6AF874E7303CE53299CCC041C7BC308D82A5698F3A8D0C38271AE35F8E9DBFBB694B5C803D89F7AE435DE236D525F54759B65E372FCD68EF20FA7111F9E4AFF73", // odd
		"0x6AADD3E3E424D5B713FCAA8D8945B1E055166132038C57BBD2D51C833F0C5EA2007A2324CE514F8E8C2F008A2F36F44005A4039CB55830986F734C93DAF0EB4BAB54A6A8C7081864F44346E9BC6F0A3EB9F2C0146A00C6A05187D0C101E1F2D038CDB70CB5E9E05A2D188AB6CBB46286624D4415E7D4DBFAD3BCC6009D915C406EED38F468B940F41E6BEDC0430DD78E6F19A7DA3A27498A4181E24D738B0072D8F6ADB8C9809A5B033A09785814FD9919F6EF9F83EEA519BEC593855C4C10CBEEC582D4AE0792158823B0275E6AEC35242740468FAF3D5C60FD1E376362B6322F78B7ED0CA1C5BBCD2B49734A56C0967A1D01A100932C837B91D592CE08ABFF",
	},
	{
		"2",
		"0xB08FFB20760FFED58FADA86DFEF71AD72AA0FA763219618FE022C197E54708BB1191C66470250FCE8879487507CEE41381CA4D932F81C2B3F1AB20B539D50DCD",
		"0xAC6BDB41324A9A9BF166DE5E1389582FAF72B6651987EE07FC3192943DB56050A37329CBB4A099ED8193E0757767A13DD52312AB4B03310DCD7F48A9DA04FD50E8083969EDB767B0CF6095179A163AB3661A05FBD5FAAAE82918A9962F0B93B855F97993EC975EEAA80D740ADBF4FF747359D041D5C33EA71D281E446B14773BCA97B43A23FB801676BD207A436C6481F1D2B9078717461A5B9D32E688F87748544523B524B0D57D5EA77A2775D2ECFA032CFBDBF52FB3786160279004E57AE6AF874E7303CE53299CCC041C7BC308D82A5698F3A8D0C38271AE35F8E9DBFBB694B5C803D89F7AE435DE236D525F54759B65E372FCD68EF20FA7111F9E4AFF72", // even
		"0x7858794B5897C29F4ED0B40913416AB6C48588484E6A45F2ED3E26C941D878E923575AAC434EE2750E6439A6976F9BB4D64CEDB2A53CE8D04DD48CADCDF8E46F22747C6B81C6CEA86C0D873FBF7CEF262BAAC43A522BD7F32F3CDAC52B9337C77B3DCFB3DB3EDD80476331E82F4B1DF8EFDC1220C92656DFC9197BDC1877804E28D928A2A284B8DED506CBA304435C9D0133C246C98A7D890D1DE60CBC53A024361DA83A9B8775019083D22AC6820ED7C3C68F8E801DD4EC779EE0A05C6EB682EF9840D285B838369BA7E148FA27691D524FAEAF7C6ECE2A4B99A294B9F2C241857B5B90CC8BFFCFCF18DFA7D676131D5CD3855A5A3E8EBFA0CDFADB4D198B4A",
	},
}

func TestFazExp(t *testing.T) {
	for i, test := range devel_expTests {
		x, ok1 := new(Int).SetString(test.x, 0)
		y, ok2 := new(Int).SetString(test.y, 0)
		out, ok3 := new(Int).SetString(test.out, 0)

		var ok4 bool
		var m *Int

		if len(test.m) == 0 {
			m, ok4 = nil, true
		} else {
			m, ok4 = new(Int).SetString(test.m, 0)
		}

		if !ok1 || !ok2 || !ok3 || !ok4 {
			t.Errorf("#%d: error in input", i)
			continue
		}

		z1 := new(Int).Exp(x, y, m)
		if !isNormalized(z1) {
			t.Errorf("#%d: %v is not normalized", i, *z1)
		}
		if z1.Cmp(out) != 0 {
			t.Errorf("#%d: got %x want %x", i, z1, out)
		}

		if m == nil {
			// The result should be the same as for m == 0;
			// specifically, there should be no div-zero panic.
			m = &Int{abs: nat{}} // m != nil && len(m.abs) == 0
			z2 := new(Int).Exp(x, y, m)
			if z2.Cmp(z1) != 0 {
				t.Errorf("#%d: got %x want %x", i, z2, z1)
			}
		}
	}
}
