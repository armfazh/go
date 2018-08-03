// Copyright 2009 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package big

import (
	"fmt"
	"runtime"
	"strings"
	"testing"
)

var cmpTests = []struct {
	x, y nat
	r    int
}{
	{nil, nil, 0},
	{nil, nat(nil), 0},
	{nat(nil), nil, 0},
	{nat(nil), nat(nil), 0},
	{nat{0}, nat{0}, 0},
	{nat{0}, nat{1}, -1},
	{nat{1}, nat{0}, 1},
	{nat{1}, nat{1}, 0},
	{nat{0, _M}, nat{1}, 1},
	{nat{1}, nat{0, _M}, -1},
	{nat{1, _M}, nat{0, _M}, 1},
	{nat{0, _M}, nat{1, _M}, -1},
	{nat{16, 571956, 8794, 68}, nat{837, 9146, 1, 754489}, -1},
	{nat{34986, 41, 105, 1957}, nat{56, 7458, 104, 1957}, 1},
}

func TestCmp(t *testing.T) {
	for i, a := range cmpTests {
		r := a.x.cmp(a.y)
		if r != a.r {
			t.Errorf("#%d got r = %v; want %v", i, r, a.r)
		}
	}
}

type funNN func(z, x, y nat) nat
type argNN struct {
	z, x, y nat
}

var sumNN = []argNN{
	{},
	{nat{1}, nil, nat{1}},
	{nat{1111111110}, nat{123456789}, nat{987654321}},
	{nat{0, 0, 0, 1}, nil, nat{0, 0, 0, 1}},
	{nat{0, 0, 0, 1111111110}, nat{0, 0, 0, 123456789}, nat{0, 0, 0, 987654321}},
	{nat{0, 0, 0, 1}, nat{0, 0, _M}, nat{0, 0, 1}},
}

var prodNN = []argNN{
	{},
	{nil, nil, nil},
	{nil, nat{991}, nil},
	{nat{991}, nat{991}, nat{1}},
	{nat{991 * 991}, nat{991}, nat{991}},
	{nat{0, 0, 991 * 991}, nat{0, 991}, nat{0, 991}},
	{nat{1 * 991, 2 * 991, 3 * 991, 4 * 991}, nat{1, 2, 3, 4}, nat{991}},
	{nat{4, 11, 20, 30, 20, 11, 4}, nat{1, 2, 3, 4}, nat{4, 3, 2, 1}},
	// 3^100 * 3^28 = 3^128
	{
		natFromString("11790184577738583171520872861412518665678211592275841109096961"),
		natFromString("515377520732011331036461129765621272702107522001"),
		natFromString("22876792454961"),
	},
	// z = 111....1 (70000 digits)
	// x = 10^(99*700) + ... + 10^1400 + 10^700 + 1
	// y = 111....1 (700 digits, larger than Karatsuba threshold on 32-bit and 64-bit)
	{
		natFromString(strings.Repeat("1", 70000)),
		natFromString("1" + strings.Repeat(strings.Repeat("0", 699)+"1", 99)),
		natFromString(strings.Repeat("1", 700)),
	},
	// z = 111....1 (20000 digits)
	// x = 10^10000 + 1
	// y = 111....1 (10000 digits)
	{
		natFromString(strings.Repeat("1", 20000)),
		natFromString("1" + strings.Repeat("0", 9999) + "1"),
		natFromString(strings.Repeat("1", 10000)),
	},
}

func natFromString(s string) nat {
	x, _, _, err := nat(nil).scan(strings.NewReader(s), 0, false)
	if err != nil {
		panic(err)
	}
	return x
}

func TestSet(t *testing.T) {
	for _, a := range sumNN {
		z := nat(nil).set(a.z)
		if z.cmp(a.z) != 0 {
			t.Errorf("got z = %v; want %v", z, a.z)
		}
	}
}

func testFunNN(t *testing.T, msg string, f funNN, a argNN) {
	z := f(nil, a.x, a.y)
	if z.cmp(a.z) != 0 {
		t.Errorf("%s%+v\n\tgot z = %v; want %v", msg, a, z, a.z)
	}
}

func TestFunNN(t *testing.T) {
	for _, a := range sumNN {
		arg := a
		testFunNN(t, "add", nat.add, arg)

		arg = argNN{a.z, a.y, a.x}
		testFunNN(t, "add symmetric", nat.add, arg)

		arg = argNN{a.x, a.z, a.y}
		testFunNN(t, "sub", nat.sub, arg)

		arg = argNN{a.y, a.z, a.x}
		testFunNN(t, "sub symmetric", nat.sub, arg)
	}

	for _, a := range prodNN {
		arg := a
		testFunNN(t, "mul", nat.mul, arg)

		arg = argNN{a.z, a.y, a.x}
		testFunNN(t, "mul symmetric", nat.mul, arg)
	}
}

var mulRangesN = []struct {
	a, b uint64
	prod string
}{
	{0, 0, "0"},
	{1, 1, "1"},
	{1, 2, "2"},
	{1, 3, "6"},
	{10, 10, "10"},
	{0, 100, "0"},
	{0, 1e9, "0"},
	{1, 0, "1"},                    // empty range
	{100, 1, "1"},                  // empty range
	{1, 10, "3628800"},             // 10!
	{1, 20, "2432902008176640000"}, // 20!
	{1, 100,
		"933262154439441526816992388562667004907159682643816214685929" +
			"638952175999932299156089414639761565182862536979208272237582" +
			"51185210916864000000000000000000000000", // 100!
	},
}

func TestMulRangeN(t *testing.T) {
	for i, r := range mulRangesN {
		prod := string(nat(nil).mulRange(r.a, r.b).utoa(10))
		if prod != r.prod {
			t.Errorf("#%d: got %s; want %s", i, prod, r.prod)
		}
	}
}

// allocBytes returns the number of bytes allocated by invoking f.
func allocBytes(f func()) uint64 {
	var stats runtime.MemStats
	runtime.ReadMemStats(&stats)
	t := stats.TotalAlloc
	f()
	runtime.ReadMemStats(&stats)
	return stats.TotalAlloc - t
}

// TestMulUnbalanced tests that multiplying numbers of different lengths
// does not cause deep recursion and in turn allocate too much memory.
// Test case for issue 3807.
func TestMulUnbalanced(t *testing.T) {
	defer runtime.GOMAXPROCS(runtime.GOMAXPROCS(1))
	x := rndNat(50000)
	y := rndNat(40)
	allocSize := allocBytes(func() {
		nat(nil).mul(x, y)
	})
	inputSize := uint64(len(x)+len(y)) * _S
	if ratio := allocSize / uint64(inputSize); ratio > 10 {
		t.Errorf("multiplication uses too much memory (%d > %d times the size of inputs)", allocSize, ratio)
	}
}

func rndNat(n int) nat {
	return nat(rndV(n)).norm()
}

func BenchmarkMul(b *testing.B) {
	mulx := rndNat(1e4)
	muly := rndNat(1e4)
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		var z nat
		z.mul(mulx, muly)
	}
}

func TestNLZ(t *testing.T) {
	var x Word = _B >> 1
	for i := 0; i <= _W; i++ {
		if int(nlz(x)) != i {
			t.Errorf("failed at %x: got %d want %d", x, nlz(x), i)
		}
		x >>= 1
	}
}

type shiftTest struct {
	in    nat
	shift uint
	out   nat
}

var leftShiftTests = []shiftTest{
	{nil, 0, nil},
	{nil, 1, nil},
	{natOne, 0, natOne},
	{natOne, 1, natTwo},
	{nat{1 << (_W - 1)}, 1, nat{0}},
	{nat{1 << (_W - 1), 0}, 1, nat{0, 1}},
}

func TestShiftLeft(t *testing.T) {
	for i, test := range leftShiftTests {
		var z nat
		z = z.shl(test.in, test.shift)
		for j, d := range test.out {
			if j >= len(z) || z[j] != d {
				t.Errorf("#%d: got: %v want: %v", i, z, test.out)
				break
			}
		}
	}
}

var rightShiftTests = []shiftTest{
	{nil, 0, nil},
	{nil, 1, nil},
	{natOne, 0, natOne},
	{natOne, 1, nil},
	{natTwo, 1, natOne},
	{nat{0, 1}, 1, nat{1 << (_W - 1)}},
	{nat{2, 1, 1}, 1, nat{1<<(_W-1) + 1, 1 << (_W - 1)}},
}

func TestShiftRight(t *testing.T) {
	for i, test := range rightShiftTests {
		var z nat
		z = z.shr(test.in, test.shift)
		for j, d := range test.out {
			if j >= len(z) || z[j] != d {
				t.Errorf("#%d: got: %v want: %v", i, z, test.out)
				break
			}
		}
	}
}

type modWTest struct {
	in       string
	dividend string
	out      string
}

var modWTests32 = []modWTest{
	{"23492635982634928349238759823742", "252341", "220170"},
}

var modWTests64 = []modWTest{
	{"6527895462947293856291561095690465243862946", "524326975699234", "375066989628668"},
}

func runModWTests(t *testing.T, tests []modWTest) {
	for i, test := range tests {
		in, _ := new(Int).SetString(test.in, 10)
		d, _ := new(Int).SetString(test.dividend, 10)
		out, _ := new(Int).SetString(test.out, 10)

		r := in.abs.modW(d.abs[0])
		if r != out.abs[0] {
			t.Errorf("#%d failed: got %d want %s", i, r, out)
		}
	}
}

func TestModW(t *testing.T) {
	if _W >= 32 {
		runModWTests(t, modWTests32)
	}
	if _W >= 64 {
		runModWTests(t, modWTests64)
	}
}

var montgomeryTests = []struct {
	x, y, m      string
	k0           uint64
	out32, out64 string
}{
	{
		"0xffffffffffffffffffffffffffffffffffffffffffffffffe",
		"0xffffffffffffffffffffffffffffffffffffffffffffffffe",
		"0xfffffffffffffffffffffffffffffffffffffffffffffffff",
		1,
		"0x1000000000000000000000000000000000000000000",
		"0x10000000000000000000000000000000000",
	},
	{
		"0x000000000ffffff5",
		"0x000000000ffffff0",
		"0x0000000010000001",
		0xff0000000fffffff,
		"0x000000000bfffff4",
		"0x0000000003400001",
	},
	{
		"0x0000000080000000",
		"0x00000000ffffffff",
		"0x1000000000000001",
		0xfffffffffffffff,
		"0x0800000008000001",
		"0x0800000008000001",
	},
	{
		"0x0000000080000000",
		"0x0000000080000000",
		"0xffffffff00000001",
		0xfffffffeffffffff,
		"0xbfffffff40000001",
		"0xbfffffff40000001",
	},
	{
		"0x0000000080000000",
		"0x0000000080000000",
		"0x00ffffff00000001",
		0xfffffeffffffff,
		"0xbfffff40000001",
		"0xbfffff40000001",
	},
	{
		"0x0000000080000000",
		"0x0000000080000000",
		"0x0000ffff00000001",
		0xfffeffffffff,
		"0xbfff40000001",
		"0xbfff40000001",
	},
	{
		"0x3321ffffffffffffffffffffffffffff00000000000022222623333333332bbbb888c0",
		"0x3321ffffffffffffffffffffffffffff00000000000022222623333333332bbbb888c0",
		"0x33377fffffffffffffffffffffffffffffffffffffffffffff0000000000022222eee1",
		0xdecc8f1249812adf,
		"0x04eb0e11d72329dc0915f86784820fc403275bf2f6620a20e0dd344c5cd0875e50deb5",
		"0x0d7144739a7d8e11d72329dc0915f86784820fc403275bf2f61ed96f35dd34dbb3d6a0",
	},
	{
		"0x10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ffffffffffffffffffffffffffffffff00000000000022222223333333333444444444",
		"0x10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ffffffffffffffffffffffffffffffff999999999999999aaabbbbbbbbcccccccccccc",
		"0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff33377fffffffffffffffffffffffffffffffffffffffffffff0000000000022222eee1",
		0xdecc8f1249812adf,
		"0x5c0d52f451aec609b15da8e5e5626c4eaa88723bdeac9d25ca9b961269400410ca208a16af9c2fb07d7a11c7772cba02c22f9711078d51a3797eb18e691295293284d988e349fa6deba46b25a4ecd9f715",
		"0x92fcad4b5c0d52f451aec609b15da8e5e5626c4eaa88723bdeac9d25ca9b961269400410ca208a16af9c2fb07d799c32fe2f3cc5422f9711078d51a3797eb18e691295293284d8f5e69caf6decddfe1df6",
	},
	{ // 512-bit odd-modulus
		"0x608500810a2552000e9221251874020663480ba0081121911114d483040700a809812900c50243c8c88a84848a1a7204240501caa020c08412d44400410c18c1",
		"0x24e1480a92a7a6f539fe22fd1ee7239febc2bcbd0f75244e68b1a98f49b58db3ddba8fb2a715d90d73946f07a5fc07b3d9e1b2e72b1c916388711b85d8bcf828",
		"0x618501870bb5d2820e9f2125fb74421667484fa20a1521b3f354f5b784270de8198d2941dd2a63ccefba85c4ab9a720ee51581cff567c0c413f44528f56f3cc1",
		0x84aabff20130acbf,
		"0xf2750de6631b9bc3b980e9ef63031463cb4460a5ccc313df4802471227c9659a1774d0475e0b88119d0cf8d2554e289cf43e0e8b6d6978ed847a6fbeb2cf307",
		"0xf2750de6631b9bc3b980e9ef63031463cb4460a5ccc313df4802471227c9659a1774d0475e0b88119d0cf8d2554e289cf43e0e8b6d6978ed847a6fbeb2cf307",
	},
	{ // 1024-bit odd-modulus
		"0x1d7aa318d993dbde8d7d3c2718bde532caca727b3e2b889dbc024200a6ed0f68dd693de107d28cd8f345f04d15a42ba3c18b8fe7bd7b82edb814da79c8514eeda640d2ca52def2b3fa1bbce6dd6e8f3e0a391cb153fc0395925ced7fb75793351d1dc9b7aab10c161372dd671cead4c4ec6a73f1aa12f68cb2192d28cff31a35",
		"0x2aa23f7e23b72d0b597c3497cf30552669896b790d4874b06d6497ab7ef711539f82e4dba454734b5958bb593a63394791ad3cb758e906f8e0f49c33ae22e69ecef772245cd9db1fcddd9d6d93add8a681cd268e7a5e95fb37c74330a45babb025ea33fedc0ea866af46a9c6fed29a9a43620ed39bc243f1c9a72cef57f1ea0b",
		"0x49f5c8ab2cd9f069d04b96d73cbdf6f22fac3ec359bf60dbf8feb51eda5d511fd633a1133e59ad20a958d9449bb37015dc24eca6e4d84cf261578025ca3d436daf41652207c885ddb4f7c7542f78fdec35b6f1bf416184f9570a5c584cec443a0ee1a082f9cc5009bd101d7adf299cded7198fe5ad994e49833086b6310c6f45",
		0x6416fbe012903473,
		"0x472d1e624089cb4757f8008c59518880b0d220cb9249d9efddd1c2adc49ed0d34352b5c5cffb86af685e53b476aac0af7376dea1fa36346c4adaeda4ee1c8845f940c312f85c242d40dd4117e71f4de8ba1ed4b79c472068cf9504c2c2f7ef0a3d6a3baa68be047c0ea70ef3aee848289fdb2adcd2374da4c80f26cce997f380",
		"0x472d1e624089cb4757f8008c59518880b0d220cb9249d9efddd1c2adc49ed0d34352b5c5cffb86af685e53b476aac0af7376dea1fa36346c4adaeda4ee1c8845f940c312f85c242d40dd4117e71f4de8ba1ed4b79c472068cf9504c2c2f7ef0a3d6a3baa68be047c0ea70ef3aee848289fdb2adcd2374da4c80f26cce997f380",
	},
	{ // 1536-bit odd-modulus
		"0x3c6660449b9b18efdb4074f79b5dc9f4857cf51c11d368fef869c38c1da1d3ddca0aa22fd4cc23b0cad38afefff971de8122160c1f63991f178815e23172fd03dd21382646b9e88fa2814cc54c9aba2bae65b4d0f37ada2d32c068ebd8004d8e063280f40fda85a4f0f85e9feb0ee5e9bfd74a02781784e7c0c047f35d45a6c43de101d691b7d38af938470fe9e4eeb612785e98c10545e3e4f0a8617425d8f946c2660fd539ac1790a150452f26ff757385822a7d666f618d7e074cf546fcec",
		"0x1928f980bfc3f44c7cc3c9bd511e8a97c2a320178c7bc0c288355bcbfe665bae575e99fd5fecc5ab6b0865a62e9893e3c087102072ad083e897909c8526e0e133bd21612c83d45b9c6bafac883e6e0ab05ed031b0673191b65c66140760686f120a147dd0ccf58e04ff2b467149a0d7e03e067dbee7c82d70743565cfe484db9dfa26a2f451a4545ba037a559ae5581777c9d7fed5307f9fa52d39629aa2737a4d19ad8fb7e56114fc7cac89e2b154905863f3afb41de2460661368cf25e4458",
		"0xfbc01e5d3ed3a514218330b5b036d76f7ed4dc15cc86475e0c2414c644d6a689fc7f5e6269d4047e7d0ffe4ecf40fc70e94481aa257877ec9d891ac90097d0174b9a232f78b813966b5070e92d8cc2d0228deea1803a3580d087647c9f9ac09fd1ed39f09b77d9ca18ba6105b12acc6e174c3eeba9f77d8a9c98756d051ce1ae013f687e1f17ce5e45b704324109540c914ea163f75790ecae1f1a3d6e6e21cd718bfc5a90088dafe858eee6c71440b1fe613d792af9e30b6e01a758cab2c99f",
		0xc251481993b9eda1,
		"0x557869a92297dea238a672f6685c5e93e02a86f851f68faf15e06173d8759f4f63dc357cb1c4f27dea62fd4973e0f628359bd381501e8b77e978e74b0b601c4b2e7653cbd934bebe0734147ca72e359bcc1ebeb87957e855cb49ccc84123c80b77af3b190704ee328aa71dfdd15ec9b40cd8eee42be034f5b7d5df12f194e95f5663955d8f24fc16133f3a58a6a65779b91926d9476189b1ac7bd5272f5662999c76cfc57e0ea7e50e6526a5d3accb7c3272002c9b78469b511f7caf94c1931f",
		"0x557869a92297dea238a672f6685c5e93e02a86f851f68faf15e06173d8759f4f63dc357cb1c4f27dea62fd4973e0f628359bd381501e8b77e978e74b0b601c4b2e7653cbd934bebe0734147ca72e359bcc1ebeb87957e855cb49ccc84123c80b77af3b190704ee328aa71dfdd15ec9b40cd8eee42be034f5b7d5df12f194e95f5663955d8f24fc16133f3a58a6a65779b91926d9476189b1ac7bd5272f5662999c76cfc57e0ea7e50e6526a5d3accb7c3272002c9b78469b511f7caf94c1931f",
	},
	{ // 2048-bit odd-modulus
		"0x5c8fdc7fcf0a2de9b0855448af24e524050e298249d8acfd7ebf9ba8c10f11d1830c159229c72bab00bc38084c5505e41abc35d0357ad48baadab0a01bf359829462769dd4afb6c36021d045e73c188e25e25a781ba395a7299faf4dd73b20f71a9e923822e4952cf1164723bbaf2af2f07a7a466c19fe481a5640d1539352f90df7e47204e5ba2226d6b59688c6dba91b5032d45ea20df648902d9143502607bf87c47a244056d72a458fbceef751ac1c121aca99f2e221bb5869b81237a15e7cdf21247825415502a7ad5856ee5821051074eb5595de37d6826e7df43e2a5640d404078de62fedcd75e6d1dff62e407f6b0c96da26bddf289d0350af29836f",
		"0x2cad23818e43424f3b514523e112cfa4cd21df78863b754759750847cb48786fe8d832a984e7a84580dcc1bb691d2fa44658b34e512dd8b5343e3fb6f3b368065683b30c1e8fbad95a96a3a7d3113f7044bef4d21f9eb4022382706c91fb215a203b8906d6786b3fff0d2c1b35b4005a557652e6f6bed657fc29233a584f81d02ffe8a87b76df28d83135f7d8e02a00d17de1a45a84b8711286a26f52c38c9a21fe85858a3495ede64aba69f7fadbe5b12382c97f542d989a420cadfdc6107cd23adf826592635882208f5a57a17f6774c5ab9df2a80fb53e752551f4ed16c888a623bf14e952affeb1121106237b86a6568c95d43f93684aad2faa3dac6fae3",
		"0x7824aad0078b351d898492ce8ada3a277ff0939086686d09349aa0f9d57dc03b7c1e907e90f49e191260f4cab6b1b1e4e74948a5abbf61da9a20662cb80a5d7a2f2675d7900698bd685a3bfba9b4655fa8713ecec5565e20e63a8ebcb63cc3bf84817fdb3a6e62790d93a8070fcb70b4fd74aeef42f52ecdda018e6310fcc6a8d4ec4895a5a9585cb5363972a6d19f81d76a59508727a885d0c0449ee5b141083a00160892ea6802b63d9d6ad7f247da67aecf690983639b57419cafe570ed94b1275011af5bd82ce3d5e798079717dfaedabce4ec362a470f43e6c2fb5c859d62ccf4fcc9d9b3b90892328f0a07ed9eddf5e97b55d2e27b0a849c54af790e17",
		0xb4722ea62ba0f659,
		"0x1e6687fc08eaf3d391879e3a7f409246b848ec29ac3ae595bba77b78db4e1920dded33a17d0af6095b04278591e1d5f3e46e9858c6fc86ea01c4a9d929ee9e0aa9235b7de84ca01771dba7777a66ed748b48fc4625fe06a8dbf994736da2103d326f0896adf8949b8c9d68b3884b87c0c29c5cf556f2da69f17c64c2b86df237df12c4d080e1867766fbac2ec9d1ecfee9904d8d9a10adfe9bfd89532ddf03731f3cf2a3ad2c991d1ef0ca1e65fe76678496783dabee5a17e059d06f94c886ed885bce98fa16996370823e335f266fa64ff4750acfdb3e9f0446cb3376ebbd97e863e98534d124a92dc93f4e0576ea7f493d0ca24d6501e8515a66c61c205634",
		"0x1e6687fc08eaf3d391879e3a7f409246b848ec29ac3ae595bba77b78db4e1920dded33a17d0af6095b04278591e1d5f3e46e9858c6fc86ea01c4a9d929ee9e0aa9235b7de84ca01771dba7777a66ed748b48fc4625fe06a8dbf994736da2103d326f0896adf8949b8c9d68b3884b87c0c29c5cf556f2da69f17c64c2b86df237df12c4d080e1867766fbac2ec9d1ecfee9904d8d9a10adfe9bfd89532ddf03731f3cf2a3ad2c991d1ef0ca1e65fe76678496783dabee5a17e059d06f94c886ed885bce98fa16996370823e335f266fa64ff4750acfdb3e9f0446cb3376ebbd97e863e98534d124a92dc93f4e0576ea7f493d0ca24d6501e8515a66c61c205634",
	},
}

func TestMontgomery(t *testing.T) {
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
		z := nat(nil).montgomery(x, y, m, k0, len(m))
		z = z.norm()
		if z.cmp(out) != 0 {
			t.Errorf("#%d: got 0x%s want 0x%s", i, z.utoa(16), out.utoa(16))
		}
	}
}

var expNNTests = []struct {
	x, y, m string
	out     string
}{
	{"0", "0", "0", "1"},
	{"0", "0", "1", "0"},
	{"1", "1", "1", "0"},
	{"2", "1", "1", "0"},
	{"2", "2", "1", "0"},
	{"10", "100000000000", "1", "0"},
	{"0x8000000000000000", "2", "", "0x40000000000000000000000000000000"},
	{"0x8000000000000000", "2", "6719", "4944"},
	{"0x8000000000000000", "3", "6719", "5447"},
	{"0x8000000000000000", "1000", "6719", "1603"},
	{"0x8000000000000000", "1000000", "6719", "3199"},
	{
		"2938462938472983472983659726349017249287491026512746239764525612965293865296239471239874193284792387498274256129746192347",
		"298472983472983471903246121093472394872319615612417471234712061",
		"29834729834729834729347290846729561262544958723956495615629569234729836259263598127342374289365912465901365498236492183464",
		"23537740700184054162508175125554701713153216681790245129157191391322321508055833908509185839069455749219131480588829346291",
	},
	{
		"11521922904531591643048817447554701904414021819823889996244743037378330903763518501116638828335352811871131385129455853417360623007349090150042001944696604737499160174391019030572483602867266711107136838523916077674888297896995042968746762200926853379",
		"426343618817810911523",
		"444747819283133684179",
		"42",
	},
	{ // 512-bit exponentiation odd-modulus
		"0x7eff18a9ca2d7e30de92f3ad18f62b86f34b3bac9d31b59d15b7decb5f0f20b8a9812fb4e717dbfad8cbbe958a7ff3f52c6f77daa8a8f3b75edccc46410cd9c3",
		"0x24e1480a92a7a6f539fe22fd1ee7239febc2bcbd0f75244e68b1a98f49b58db3ddba8fb2a715d90d73946f07a5fc07b3d9e1b2e72b1c916388711b85d8bcf828",
		"0x618501870bb5d2820e9f2125fb74421667484fa20a1521b3f354f5b784270de8198d2941dd2a63ccefba85c4ab9a720ee51581cff567c0c413f44528f56f3b73",
		"0x22e618b966f89a90fd8584f19c2039098395d26061a2c75c44f64a7e2f3e219122f509ac137262aa9264177f74249fd973774d945e53f48fc7bc627d44c99559",
	},
	{ // 1024-bit exponentiation odd-modulus
		"0x1d7aa318d993dbde8d7d3c2718bde532caca727b3e2b889dbc024200a6ed0f68dd693de107d28cd8f345f04d15a42ba3c18b8fe7bd7b82edb814da79c8514eeda640d2ca52def2b3fa1bbce6dd6e8f3e0a391cb153fc0395925ced7fb75793351d1dc9b7aab10c161372dd671cead4c4ec6a73f1aa12f68cb2192d28cff31a35",
		"0x7498082950911d7529c7cb6f0bee4c189935aa3c6707d58c66634cca5954627375b685eee2ae206c02b1949dd616a95d6dd2295e3dc153eb424c1c5978602a0c7e38d74664a260fd82d564c1c326d692b784184dbbc01af48ed19f88f147efea34cbd481d5daf8706c56c741ddfc37791a7b9eb9495b923b4cd7b3a588fe5950",
		"0x49f5c8ab2cd9f069d04b96d73cbdf6f22fac3ec359bf60dbf8feb51eda5d511fd633a1133e59ad20a958d9449bb37015dc24eca6e4d84cf261578025ca3d436daf41652207c885ddb4f7c7542f78fdec35b6f1bf416184f9570a5c584cec443a0ee1a082f9cc5009bd101d7adf299cded7198fe5ad994e49833086b6310c6e71",
		"0x3ceb6fd2c5db73761fc724472a629fea9d2d9427e6c8292c8fb96abba1146e96700cce812b5fcbf64e61fd84251d8a977408cd0ab52bccd0443d830908e674ac8af8da8c6ab62f4b7f9c0e35c6ce8cd3124f2c2ede576e53c218b4d473389a003e10b8d6e7ffe2c791c9e282ee3860580edebc82bdd9d96dbd021678e62b2ef",
	},
	{ // 1536-bit exponentiation odd-modulus
		"0x3c6660449b9b18efdb4074f79b5dc9f4857cf51c11d368fef869c38c1da1d3ddca0aa22fd4cc23b0cad38afefff971de8122160c1f63991f178815e23172fd03dd21382646b9e88fa2814cc54c9aba2bae65b4d0f37ada2d32c068ebd8004d8e063280f40fda85a4f0f85e9feb0ee5e9bfd74a02781784e7c0c047f35d45a6c43de101d691b7d38af938470fe9e4eeb612785e98c10545e3e4f0a8617425d8f946c2660fd539ac1790a150452f26ff757385822a7d666f618d7e074cf546fcec",
		"0x1928f980bfc3f44c7cc3c9bd511e8a97c2a320178c7bc0c288355bcbfe665bae575e99fd5fecc5ab6b0865a62e9893e3c087102072ad083e897909c8526e0e133bd21612c83d45b9c6bafac883e6e0ab05ed031b0673191b65c66140760686f120a147dd0ccf58e04ff2b467149a0d7e03e067dbee7c82d70743565cfe484db9dfa26a2f451a4545ba037a559ae5581777c9d7fed5307f9fa52d39629aa2737a4d19ad8fb7e56114fc7cac89e2b154905863f3afb41de2460661368cf25e4458",
		"0xfbc01e5d3ed3a514218330b5b036d76f7ed4dc15cc86475e0c2414c644d6a689fc7f5e6269d4047e7d0ffe4ecf40fc70e94481aa257877ec9d891ac90097d0174b9a232f78b813966b5070e92d8cc2d0228deea1803a3580d087647c9f9ac09fd1ed39f09b77d9ca18ba6105b12acc6e174c3eeba9f77d8a9c98756d051ce1ae013f687e1f17ce5e45b704324109540c914ea163f75790ecae1f1a3d6e6e21cd718bfc5a90088dafe858eee6c71440b1fe613d792af9e30b6e01a758cab2be13",
		"0xe6769f71eb4168b55f6a1e0ae0c9e572c215f1b7bc3c283f11459bbe67f61bd06ae59085ef9bd77e6cc7247f387c5faa3218e3aa683407e2f27e7a36631841e8e96c676e2d9db8ffb17248d70689c2f45cde0ca27fa20b06bcf3b5020d9544e1d3acefc5200ae0a580d90e63ab1db7f742129411a95d513b568da33404528e536b756d781bd6e0e927a0e591666a32028bc3b72ee292dd444c54e6a6164dbb83eca54bffe0dd2664e9d3236f0e8f6135600e4570ad691cea0a6506df70a55b54",
	},
	{ // 2048-bit exponentiation odd-modulus
		"0x5c8fdc7fcf0a2de9b0855448af24e524050e298249d8acfd7ebf9ba8c10f11d1830c159229c72bab00bc38084c5505e41abc35d0357ad48baadab0a01bf359829462769dd4afb6c36021d045e73c188e25e25a781ba395a7299faf4dd73b20f71a9e923822e4952cf1164723bbaf2af2f07a7a466c19fe481a5640d1539352f90df7e47204e5ba2226d6b59688c6dba91b5032d45ea20df648902d9143502607bf87c47a244056d72a458fbceef751ac1c121aca99f2e221bb5869b81237a15e7cdf21247825415502a7ad5856ee5821051074eb5595de37d6826e7df43e2a5640d404078de62fedcd75e6d1dff62e407f6b0c96da26bddf289d0350af29836f",
		"0xa4d1ce5195ce776cc4d5d7f26bed09cc4d1273090ca3e2508e0fa941a0c638ab64f6c32815dc465e933db6861fcee1892da1fbf3fced3a8fce5ea5e3abbdc58085aa28e3ae965396c2f0dfa37cc5a4cfed3033a0e4f5122309bcff294837e519a4bd08e210e6cdb90ca0d422457f710f52eb01d639b40525d62ab19d694c487904ead31d5d174aea384998f034d43f8eef4873962f732f96f92a6b9411ea0aaa59e86e613633c6e11ae9440a57a0063579e6fc00fec63d24fb62678fc1d1f561d4d5483808820db505dedd3d81af0e56fb3576c416b7259af6963be24a2df225ed2f30ee186edeb8f3a3539f6c3fa609435eb2d899cc18ffb55796f88a4008fa",
		"0x7824aad0078b351d898492ce8ada3a277ff0939086686d09349aa0f9d57dc03b7c1e907e90f49e191260f4cab6b1b1e4e74948a5abbf61da9a20662cb80a5d7a2f2675d7900698bd685a3bfba9b4655fa8713ecec5565e20e63a8ebcb63cc3bf84817fdb3a6e62790d93a8070fcb70b4fd74aeef42f52ecdda018e6310fcc6a8d4ec4895a5a9585cb5363972a6d19f81d76a59508727a885d0c0449ee5b141083a00160892ea6802b63d9d6ad7f247da67aecf690983639b57419cafe570ed94b1275011af5bd82ce3d5e798079717dfaedabce4ec362a470f43e6c2fb5c859d62ccf4fcc9d9b3b90892328f0a07ed9eddf5e97b55d2e27b0a849c54af790c5d",
		"0x1a036bbe6991c899d4e7ec2e625505e5e8dcc5f794398b7ceff87d7218bb4720c92d506c0e57a92f1b00810580ed383a393a73edb3a0aa1d64a40e9b0f3a25729d463d6cd070387484b38da5aedfe234f5ea8e174efa6d3057d94e531ccc93595cfde5b55336a5cd7b4f81ac07da4375929b72dd180ee634eb07048cbf8314398edc4157db2ffba00c0d0ed8d158b25860452150a7262279d9dea7cb3c8d77b8825ef3270372219206d1add301af692dd1b150ae5e2233f8ffd56b3e9524308daeb181e24d8facbf97c5dde870e9384322c4c99582f05146a2af4f9a1c5c9248427ad82fa6b4b5f854d168357c7b6b9d09b0b8137cac432af2bde0d1c9f2314d",
	},
}

func TestExpNN(t *testing.T) {
	for i, test := range expNNTests {
		x := natFromString(test.x)
		y := natFromString(test.y)
		out := natFromString(test.out)

		var m nat
		if len(test.m) > 0 {
			m = natFromString(test.m)
		}

		z := nat(nil).expNN(x, y, m)
		if z.cmp(out) != 0 {
			t.Errorf("#%d got %s want %s", i, z.utoa(10), out.utoa(10))
		}
	}
}

func BenchmarkExp3Power(b *testing.B) {
	const x = 3
	for _, y := range []Word{
		0x10, 0x40, 0x100, 0x400, 0x1000, 0x4000, 0x10000, 0x40000, 0x100000, 0x400000,
	} {
		b.Run(fmt.Sprintf("%#x", y), func(b *testing.B) {
			var z nat
			for i := 0; i < b.N; i++ {
				z.expWW(x, y)
			}
		})
	}
}

func fibo(n int) nat {
	switch n {
	case 0:
		return nil
	case 1:
		return nat{1}
	}
	f0 := fibo(0)
	f1 := fibo(1)
	var f2 nat
	for i := 1; i < n; i++ {
		f2 = f2.add(f0, f1)
		f0, f1, f2 = f1, f2, f0
	}
	return f1
}

var fiboNums = []string{
	"0",
	"55",
	"6765",
	"832040",
	"102334155",
	"12586269025",
	"1548008755920",
	"190392490709135",
	"23416728348467685",
	"2880067194370816120",
	"354224848179261915075",
}

func TestFibo(t *testing.T) {
	for i, want := range fiboNums {
		n := i * 10
		got := string(fibo(n).utoa(10))
		if got != want {
			t.Errorf("fibo(%d) failed: got %s want %s", n, got, want)
		}
	}
}

func BenchmarkFibo(b *testing.B) {
	for i := 0; i < b.N; i++ {
		fibo(1e0)
		fibo(1e1)
		fibo(1e2)
		fibo(1e3)
		fibo(1e4)
		fibo(1e5)
	}
}

var bitTests = []struct {
	x    string
	i    uint
	want uint
}{
	{"0", 0, 0},
	{"0", 1, 0},
	{"0", 1000, 0},

	{"0x1", 0, 1},
	{"0x10", 0, 0},
	{"0x10", 3, 0},
	{"0x10", 4, 1},
	{"0x10", 5, 0},

	{"0x8000000000000000", 62, 0},
	{"0x8000000000000000", 63, 1},
	{"0x8000000000000000", 64, 0},

	{"0x3" + strings.Repeat("0", 32), 127, 0},
	{"0x3" + strings.Repeat("0", 32), 128, 1},
	{"0x3" + strings.Repeat("0", 32), 129, 1},
	{"0x3" + strings.Repeat("0", 32), 130, 0},
}

func TestBit(t *testing.T) {
	for i, test := range bitTests {
		x := natFromString(test.x)
		if got := x.bit(test.i); got != test.want {
			t.Errorf("#%d: %s.bit(%d) = %v; want %v", i, test.x, test.i, got, test.want)
		}
	}
}

var stickyTests = []struct {
	x    string
	i    uint
	want uint
}{
	{"0", 0, 0},
	{"0", 1, 0},
	{"0", 1000, 0},

	{"0x1", 0, 0},
	{"0x1", 1, 1},

	{"0x1350", 0, 0},
	{"0x1350", 4, 0},
	{"0x1350", 5, 1},

	{"0x8000000000000000", 63, 0},
	{"0x8000000000000000", 64, 1},

	{"0x1" + strings.Repeat("0", 100), 400, 0},
	{"0x1" + strings.Repeat("0", 100), 401, 1},
}

func TestSticky(t *testing.T) {
	for i, test := range stickyTests {
		x := natFromString(test.x)
		if got := x.sticky(test.i); got != test.want {
			t.Errorf("#%d: %s.sticky(%d) = %v; want %v", i, test.x, test.i, got, test.want)
		}
		if test.want == 1 {
			// all subsequent i's should also return 1
			for d := uint(1); d <= 3; d++ {
				if got := x.sticky(test.i + d); got != 1 {
					t.Errorf("#%d: %s.sticky(%d) = %v; want %v", i, test.x, test.i+d, got, 1)
				}
			}
		}
	}
}

func testBasicSqr(t *testing.T, x nat) {
	got := make(nat, 2*len(x))
	want := make(nat, 2*len(x))
	basicSqr(got, x)
	basicMul(want, x, x)
	if got.cmp(want) != 0 {
		t.Errorf("basicSqr(%v), got %v, want %v", x, got, want)
	}
}

func TestBasicSqr(t *testing.T) {
	for _, a := range prodNN {
		if a.x != nil {
			testBasicSqr(t, a.x)
		}
		if a.y != nil {
			testBasicSqr(t, a.y)
		}
		if a.z != nil {
			testBasicSqr(t, a.z)
		}
	}
}

func benchmarkNatSqr(b *testing.B, nwords int) {
	x := rndNat(nwords)
	var z nat
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		z.sqr(x)
	}
}

var sqrBenchSizes = []int{1, 2, 3, 5, 8, 10, 20, 30, 50, 80, 100, 200, 300, 500, 800, 1000}

func BenchmarkNatSqr(b *testing.B) {
	for _, n := range sqrBenchSizes {
		if isRaceBuilder && n > 1e3 {
			continue
		}
		b.Run(fmt.Sprintf("%d", n), func(b *testing.B) {
			benchmarkNatSqr(b, n)
		})
	}
}
