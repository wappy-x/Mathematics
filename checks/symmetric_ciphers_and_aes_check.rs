// AES-256 and GCM -- the same check as symmetric_ciphers_and_aes_check.py, in Rust.
// Standard library only, no crates.  The field GF(2^8), the S-box, the cipher, its
// inverse and GCM are all written out.  The key is a published test key (FIPS 197).
// Compile: rustc --edition 2021 -O symmetric_ciphers_and_aes_check.rs -o /tmp/aes_check
fn xt(a: u8) -> u8 { if a & 0x80 != 0 { (a << 1) ^ 0x1B } else { a << 1 } } // times x, wrapped
fn gmul(mut a: u8, mut b: u8) -> u8 {                                       // multiply in GF(2^8)
    let mut p = 0;
    while b != 0 { if b & 1 != 0 { p ^= a; } a = xt(a); b >>= 1; } p
}
fn inv_search(a: u8) -> u8 { (1..=255u8).find(|&b| gmul(a, b) == 1).unwrap_or(0) }
fn inv_power(a: u8) -> u8 { (0..254).fold(1u8, |r, _| gmul(r, a)) }       // a^254 is a^-1
fn affine(b: u8) -> u8 { b ^ b.rotate_left(1) ^ b.rotate_left(2) ^ b.rotate_left(3) ^ b.rotate_left(4) ^ 0x63 }
const M: [[u8; 4]; 4] = [[2, 3, 1, 1], [1, 2, 3, 1], [1, 1, 2, 3], [3, 1, 1, 2]];
const MI: [[u8; 4]; 4] = [[14, 11, 13, 9], [9, 14, 11, 13], [13, 9, 14, 11], [11, 13, 9, 14]];
type B = Vec<u8>;
fn mix(a: &[[u8; 4]; 4], s: &[u8]) -> B {                                 // each column of s times a
    (0..16).map(|i| (0..4).fold(0, |v, j| v ^ gmul(a[i % 4][j], s[4 * (i / 4) + j]))).collect()
}
fn shift(s: &[u8], d: i32) -> B { (0..16i32).map(|i| s[(i % 4 + 4 * (i / 4 + d * (i % 4)).rem_euclid(4)) as usize]).collect() }
fn xor(a: &[u8], b: &[u8]) -> B { a.iter().zip(b).map(|(x, y)| x ^ y).collect() }
fn hx(b: &[u8]) -> String { b.iter().map(|x| format!("{:02x}", x)).collect() }
fn py(b: bool) -> &'static str { if b { "True" } else { "False" } }
struct Aes { sbox: [u8; 256], inv: [u8; 256] }
impl Aes {
    fn expand(&self, key: &[u8]) -> Vec<B> {                                // 32-byte key -> 15 round keys
        let mut w: Vec<B> = (0..8).map(|i| key[4 * i..4 * i + 4].to_vec()).collect();
        let mut rc = 1u8;
        for i in 8..60 {
            let mut t = w[i - 1].clone();
            if i % 8 == 0 {
                t.rotate_left(1); t = t.iter().map(|&b| self.sbox[b as usize]).collect(); t[0] ^= rc; rc = xt(rc);
            } else if i % 8 == 4 { t = t.iter().map(|&b| self.sbox[b as usize]).collect(); }
            w.push(xor(&w[i - 8], &t));
        }
        (0..15).map(|r| w[4 * r..4 * r + 4].concat()).collect()
    }
    fn rounds(&self, rk: &[B], block: &[u8], mixing: bool, sbox: &[u8; 256]) -> Vec<B> {
        let mut s = xor(block, &rk[0]);
        let mut out = vec![];
        for r in 1..15 {
            s = shift(&s.iter().map(|&b| sbox[b as usize]).collect::<B>(), 1);
            if mixing && r < 14 { s = mix(&M, &s); }
            s = xor(&s, &rk[r]); out.push(s.clone());
        }
        out
    }
    fn e(&self, rk: &[B], b: &[u8]) -> B { self.rounds(rk, b, true, &self.sbox)[13].clone() }
    fn d(&self, rk: &[B], b: &[u8]) -> B {                                  // the inverse cipher
        let mut s = b.to_vec();
        for r in (1..15).rev() {
            s = xor(&s, &rk[r]);
            if r < 14 { s = mix(&MI, &s); }
            s = shift(&s, -1).iter().map(|&x| self.inv[x as usize]).collect();
        }
        xor(&s, &rk[0])
    }
}
fn gf128(x: u128, mut y: u128) -> u128 {                                   // GF(2^128), GCM's bit order
    let mut z = 0;
    for i in (0..128).rev() {
        if (x >> i) & 1 == 1 { z ^= y; }
        y = if y & 1 == 1 { (y >> 1) ^ (0xE1u128 << 120) } else { y >> 1 };
    }
    z
}
fn num(b: &[u8]) -> u128 { b.iter().fold(0, |v, &x| (v << 8) | x as u128) }
fn blk(n: u128) -> B { n.to_be_bytes().to_vec() }
fn pieces(c: &[u8]) -> Vec<u128> {                                         // padded blocks, then lengths
    let mut bs: Vec<u128> = c.chunks(16).map(|p| { let mut v = p.to_vec(); v.resize(16, 0); num(&v) }).collect();
    bs.push(c.len() as u128 * 8); bs
}
fn ghash(h: u128, bs: &[u128]) -> u128 { bs.iter().fold(0, |x, &b| gf128(x ^ b, h)) }
fn ghash_sum(h: u128, bs: &[u128]) -> u128 {                               // sum of block_j times H^(n+1-j)
    let (mut total, mut p) = (0, h);
    for &b in bs.iter().rev() { total ^= gf128(b, p); p = gf128(p, h); } total
}
fn ctr(a: &Aes, rk: &[B], j0: u128, data: &[u8]) -> B {
    data.chunks(16).enumerate().flat_map(|(i, p)| xor(p, &a.e(rk, &blk(j0 + 1 + i as u128)))).collect()
}
fn tag(a: &Aes, key: &[u8], nonce: &[u8], c: &[u8]) -> u128 {            // E(nonce || 1) xor GHASH
    let rk = a.expand(key);
    let j0 = num(&[nonce, &[0, 0, 0, 1]].concat());
    num(&a.e(&rk, &blk(j0))) ^ ghash(num(&a.e(&rk, &[0; 16])), &pieces(c))
}
fn gcm(a: &Aes, key: &[u8], nonce: &[u8], data: &[u8]) -> (B, u128) {
    let c = ctr(a, &a.expand(key), num(&[nonce, &[0, 0, 0, 1]].concat()), data);
    let t = tag(a, key, nonce, &c); (c, t)
}
fn opens(a: &Aes, key: &[u8], nonce: &[u8], c: &[u8], t: u128) -> bool { tag(a, key, nonce, c) == t }
fn unhex(s: &str) -> B { (0..s.len()).step_by(2).map(|i| u8::from_str_radix(&s[i..i + 2], 16).unwrap()).collect() }
fn changed(u: &[B], v: &[B]) -> Vec<usize> { u.iter().zip(v).map(|(s1, s2)| s1.iter().zip(s2).filter(|(x, y)| x != y).count()).collect() }
fn bits(u: &[u8], v: &[u8]) -> u32 { u.iter().zip(v).map(|(x, y)| (x ^ y).count_ones()).sum() }
fn main() {
    let (mut sbox, mut inv) = ([0u8; 256], [0u8; 256]);
    for a in 0..256 { sbox[a] = affine(inv_search(a as u8)); inv[sbox[a] as usize] = a as u8; }
    let aes = Aes { sbox, inv };
    let (key, pt): (B, B) = ((0..32).collect(), unhex("00112233445566778899aabbccddeeff"));
    let rk = aes.expand(&key);
    println!("AES-256: key {} bits, block {} bits, {} rounds; GCM nonce 96 bits, tag 128 bits", 8 * key.len(), 8 * pt.len(), rk.len() - 1);
    println!("S(00) S(50) S(a0) S(f0) S(53): {}", [0, 0x50, 0xA0, 0xF0, 0x53].iter().map(|&a| format!("{:02x}", sbox[a])).collect::<Vec<_>>().join(" "));
    println!("inverse of 50: by search {:02x}, by power 254 {:02x}, 50 x it = {:02x}", inv_search(0x50), inv_power(0x50), gmul(0x50, inv_power(0x50)));
    println!("affine(ed): xor of {} and 63 = {:02x}", (0..5).map(|n| format!("{:02x}", 0xEDu8.rotate_left(n))).collect::<Vec<_>>().join(" "), affine(0xED));
    let eye: B = (0..16).map(|i| (i % 4 == i / 4) as u8).collect();
    let mi_cols: B = (0..16).map(|i| MI[i % 4][i / 4]).collect();
    let mmi = mix(&M, &mi_cols);                                            // M times MI, column by column
    println!("M times its inverse is the identity: {}", py(mmi == eye));
    let st = xor(&pt, &rk[0]);
    let sb: B = st.iter().map(|&b| sbox[b as usize]).collect();
    let (sr, mc) = (shift(&sb, 1), mix(&M, &shift(&sb, 1)));
    for (name, v) in [("start", &st), ("s_box", &sb), ("s_row", &sr), ("m_col", &mc), ("k_sch", &rk[1]), ("end", &xor(&mc, &rk[1]))] {
        println!("round 1 {:<6}{}", name, hx(v));
    }
    let (a, b) = (gmul(2, 0x63), gmul(3, 0x53));                           // one column, by hand
    println!("column 0 by hand: 02.63={:02x} 02.53={:02x} 03.53={:02x}; {:02x}^{:02x}={:02x} ^e0={:02x} ^8c={:02x}", a, gmul(2, 0x53), b, a, b, a ^ b, a ^ b ^ 0xE0, a ^ b ^ 0xE0 ^ 0x8C);
    let ct = aes.e(&rk, &pt);
    println!("FIPS 197 C.3 ciphertext {} decrypts to {}", hx(&ct), hx(&aes.d(&rk, &ct)));
    let mut flip = pt.clone(); flip[0] ^= 1;
    let diff = changed(&aes.rounds(&rk, &pt, true, &sbox), &aes.rounds(&rk, &flip, true, &sbox));
    let total: u32 = (0..128).map(|i| { let mut f = pt.clone(); f[i / 8] ^= 1 << (i % 8); bits(&ct, &aes.e(&rk, &f)) }).sum();
    let avg = total as f64 / 128.0;
    let nomix = changed(&aes.rounds(&rk, &pt, false, &sbox), &aes.rounds(&rk, &flip, false, &sbox));
    println!("one plaintext bit flipped, bytes changed after rounds 1-4: {:?} after 14: {}", &diff[..4], diff[13]);
    println!("bits changed: this flip {} of 128, average over all 128 flips {:.2}", bits(&ct, &aes.e(&rk, &flip)), avg);
    println!("no MixColumns, bytes changed after 14 rounds: {}", nomix[13]);
    let ident: [u8; 256] = std::array::from_fn(|i| i as u8);
    let (m2, m3): (B, B) = (vec![7; 16], (16..32).collect());
    let lin = |s: &[u8; 256]| {
        let f = |m: &[u8]| aes.rounds(&rk, m, true, s)[13].clone();
        xor(&xor(&f(&pt), &f(&m2)), &f(&m3)) == f(&xor(&xor(&pt, &m2), &m3))
    };
    println!("E(a)^E(b)^E(c) == E(a^b^c): identity S-box {} | real S-box {} | blocks to solve a linear one, 128 + 1: {}", py(lin(&ident)), py(lin(&sbox)), 8 * pt.len() + 1);
    let (_, t13) = gcm(&aes, &[0; 32], &[0; 12], &[]);
    let (c14, t14) = gcm(&aes, &[0; 32], &[0; 12], &[0; 16]);
    println!("GCM test 13 tag {:032x}", t13);
    println!("GCM test 14 ct {} tag {:032x}", hx(&c14), t14);
    let (h0, bs) = (num(&aes.e(&aes.expand(&[0; 32]), &[0; 16])), pieces(&c14));
    println!("GHASH by Horner equals GHASH as a sum of powers: {}", py(ghash(h0, &bs) == ghash_sum(h0, &bs)));
    let nonce = unhex("cafebabefacedbaddecaf888");
    let backup: B = [b"BACKUP v1 part 1".to_vec(), vec![0; 48]].concat();
    let ecb: Vec<String> = backup.chunks(16).map(|p| hx(&aes.e(&rk, p))[..8].to_string()).collect();
    let (cg, tg) = gcm(&aes, &key, &nonce, &backup);
    let gc: Vec<String> = cg.chunks(16).map(|p| hx(p)[..8].to_string()).collect();
    let distinct = |v: &Vec<String>| v.iter().enumerate().filter(|(i, x)| !v[..*i].contains(x)).count();
    println!("backup, 4 blocks, ECB: {} distinct {}", ecb.join(" "), distinct(&ecb));
    println!("backup, 4 blocks, GCM: {} distinct {}", gc.join(" "), distinct(&gc));
    let mut bad = cg.clone(); bad[0] ^= 1;
    let j0 = num(&[&nonce[..], &[0, 0, 0, 1]].concat());
    let read = ctr(&aes, &rk, j0, &bad)[..16].iter().map(|&x| x as char).collect::<String>();
    println!("one bit flipped: counter mode alone reads {} | GCM accepts: {} | untouched: {}", read, py(opens(&aes, &key, &nonce, &bad, tg)), py(opens(&aes, &key, &nonce, &cg, tg)));
    let (m1, m2b) = (b"balance: 1200.00".to_vec(), b"balance: 9875.50".to_vec());
    let (k1, k2) = (gcm(&aes, &key, &nonce, &m1).0, gcm(&aes, &key, &nonce, &m2b).0);
    let got = xor(&xor(&k1, &k2), &m1).iter().map(|&x| x as char).collect::<String>();
    println!("nonce reused: c1^c2 == m1^m2: {} | m1 known, so m2 = {}", py(xor(&k1, &k2) == xor(&m1, &m2b)), got);
    let (size, q): (u128, u128) = (4 << 30, 1 << 32);
    let nb = size / 16;
    let log2 = |n: u128| 127 - n.leading_zeros() as i64;
    println!("4 GB backup: {} bytes = {} blocks; AES calls {}; GHASH multiplies {}; stored extra {} bytes", size, nb, nb + 2, nb + 1, 12 + 16);
    println!("one GCM message may hold at most {} bytes", ((1u128 << 32) - 2) * 16);
    println!("random 96-bit nonces, {} messages: repeat chance about 1 in {}", q, (1u128 << 97) / (q * (q - 1)));
    println!("tag forgery per try at most about 2^{}; block birthday 2^{}", log2(nb + 1) - 128, 2 * log2(nb) - 129);
    assert!(sbox[0x00] == 0x63 && sbox[0x53] == 0xED && (0..=255u8).all(|a| sbox[a as usize] == affine(inv_power(a))));
    assert_eq!(hx(&mc), "5f72641557f5bc92f7be3b291db9f91a");               // FIPS 197 C.3, round[1].m_col
    assert!(hx(&ct) == "8ea2b7ca516745bfeafc49904b496089" && aes.d(&rk, &ct) == pt);
    assert!(t13 == 0x530f8afbc74536b9a963b4f1c4cb738b && hx(&c14) == "cea7403d4d606b6e074ec5d3baf39d18");
    assert!(t14 == 0xd0d1c8a799996bf0265b98b5d48ab919 && ghash(h0, &bs) == ghash_sum(h0, &bs));
    assert!(diff[..2] == [4, 16] && nomix[13] == 1 && 60.0 < avg && avg < 68.0 && lin(&ident) && !lin(&sbox));
    assert!(distinct(&ecb) == 2 && distinct(&gc) == 4 && !opens(&aes, &key, &nonce, &bad, tg) && opens(&aes, &key, &nonce, &cg, tg));
    assert!(got == "balance: 9875.50" && mmi == eye);
    println!("ALL CHECKS PASS");
}
