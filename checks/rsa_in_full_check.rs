// RSA in full -- the Python twin in Rust, std only.  A real-size key: two 1024-bit primes, a 2048-bit n, OAEP with SHA-256
// (RFC 8017).  Rust's std has no big integers and no SHA-256, so both are written out.  INSECURE: SplitMix64, seed 2026,
// draws every random number, so the twins agree; a real key needs a secret random source.  A toy key serves Pollard's rho.
use std::cmp::Ordering::{self, Less};
const E: u64 = 65537; const HL: usize = 32; const K: usize = 256;   // e; SHA-256 output and key, in bytes
type Big = Vec<u64>;                                // little-endian 64-bit limbs, no zero limbs on top
struct Rng(u64);                                    // SplitMix64
impl Rng {
    fn next(&mut self) -> u64 { self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15); let z = (self.0 ^ (self.0 >> 30)).wrapping_mul(0xBF58476D1CE4E5B9); let z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB); z ^ (z >> 31) }
    fn bytes(&mut self, k: usize) -> Vec<u8> { (0..k / 8).flat_map(|_| self.next().to_be_bytes()).collect() }
}
fn small(x: u64) -> Big { vec![x] }
fn limb(a: &Big, i: usize) -> u128 { a.get(i).copied().unwrap_or(0) as u128 }
fn trim(mut a: Big) -> Big { while a.len() > 1 && a[a.len() - 1] == 0 { a.pop(); } a }
fn cmp(a: &Big, b: &Big) -> Ordering { a.len().cmp(&b.len()).then_with(|| a.iter().rev().cmp(b.iter().rev())) }
fn add(a: &Big, b: &Big) -> Big { let mut c = 0u128; trim((0..=a.len().max(b.len())).map(|i| { c += limb(a, i) + limb(b, i); let v = c as u64; c >>= 64; v }).collect()) }
fn sub(a: &Big, b: &Big) -> Big { let mut br = 0u128; trim((0..a.len()).map(|i| { let v = (limb(a, i) | 1 << 64) - limb(b, i) - br; br = 1 - (v >> 64); v as u64 }).collect()) } // a >= b
fn mul(a: &Big, b: &Big) -> Big { let mut out = vec![0u64; a.len() + b.len()];    // schoolbook: every limb times every limb
    for i in 0..a.len() { let mut c = 0u128; for j in 0..b.len() { c += out[i + j] as u128 + limb(a, i) * limb(b, j); out[i + j] = c as u64; c >>= 64; } out[i + b.len()] = c as u64; } trim(out) }
fn shr1(a: &Big) -> Big { trim((0..a.len()).map(|i| a[i] >> 1 | (limb(a, i + 1) as u64) << 63).collect()) }
fn rem_small(a: &Big, m: u64) -> u64 { a.iter().rev().fold(0u128, |r, &x| ((r << 64) | x as u128) % m as u128) as u64 }
fn div_small(a: &Big, m: u64) -> Big { let mut r = 0u128; let mut q: Big = a.iter().rev().map(|&x| { let v = (r << 64) | x as u128; r = v % m as u128; (v / m as u128) as u64 }).collect(); q.reverse(); trim(q) }
fn bits(a: &Big) -> u32 { 64 * a.len() as u32 - a[a.len() - 1].leading_zeros() }
fn to_bytes(a: &Big, size: usize) -> Vec<u8> { (0..size).rev().map(|i| (limb(a, i / 8) >> (8 * (i % 8))) as u8).collect() }
fn from_bytes(b: &[u8]) -> Big { trim(b.rchunks(8).map(|c| c.iter().fold(0u64, |v, &x| v << 8 | x as u64)).collect()) }
fn hx(a: &Big, size: usize) -> String { let h: String = to_bytes(a, if size > 0 { size } else { (bits(a) as usize + 7) / 8 }).iter().map(|x| format!("{:02x}", x)).collect(); format!("{}...{}", &h[..8], &h[h.len() - 8..]) }
fn gcd(mut a: Big, mut b: Big) -> Big { while a != small(0) { while a[0] & 1 == 0 { a = shr1(&a); } if cmp(&a, &b) == Less { std::mem::swap(&mut a, &mut b); } a = sub(&a, &b); } b } // binary, odd b
struct Mont { n: Big, k: usize, ninv: u64, r2: Big } // Montgomery arithmetic mod an odd n, with R = 2^(64k)
impl Mont {
    fn new(n: &Big) -> Mont {                       // -1/n mod 2^64 by Newton's method; R^2 mod n by doubling
        let inv = (0..6).fold(1u64, |v, _| v.wrapping_mul(2u64.wrapping_sub(n[0].wrapping_mul(v))));
        let r2 = (0..128 * n.len()).fold(small(1), |r, _| { let r = add(&r, &r); if cmp(&r, n) != Less { sub(&r, n) } else { r } });
        Mont { n: n.clone(), k: n.len(), ninv: inv.wrapping_neg(), r2 } }
    fn fit(&self, v: Big) -> Big { if cmp(&v, &self.n) != Less { sub(&v, &self.n) } else { v } }
    fn mm(&self, a: &Big, b: &Big) -> Big {         // a b / R mod n, for a b < n R: add multiples of n until R divides
        let (k, mut t) = (self.k, mul(a, b)); t.resize(2 * k + 1, 0);
        for i in 0..k {
            let (u, mut c) = (t[i].wrapping_mul(self.ninv) as u128, 0u128);
            for j in 0..k { c += t[i + j] as u128 + u * self.n[j] as u128; t[i + j] = c as u64; c >>= 64; }
            for j in i + k..=2 * k { c += t[j] as u128; t[j] = c as u64; c >>= 64; }
        }
        self.fit(trim(t[k..].to_vec())) }
    fn mulmod(&self, a: &Big, b: &Big) -> Big { self.mm(&self.mm(a, b), &self.r2) }
    fn power(&self, b: &Big, x: &Big) -> (Big, u32) { // square and multiply, top bit down; counts multiplies
        let (bm, mut mults) = (self.mm(b, &self.r2), 0); let mut r = bm.clone();
        for i in (0..bits(x) - 1).rev() { r = self.mm(&r, &r); mults += 1; if x[i as usize / 64] >> (i % 64) & 1 == 1 { r = self.mm(&r, &bm); mults += 1; } }
        (self.mm(&r, &small(1)), mults) }
    fn reduce(&self, x: &Big) -> Big {              // x mod n, for x < n R and n >= R / 2
        let hi = if x.len() > self.k { x[self.k..].to_vec() } else { small(0) };
        self.fit(add(&self.fit(trim(x[..x.len().min(self.k)].to_vec())), &self.mm(&hi, &self.r2))) }
}
fn inverse(a: u64, m: u64) -> u64 { let (mut r0, mut r1, mut s0, mut s1) = (m as i128, (a % m) as i128, 0i128, 1i128); // extended Euclid, 64-bit
    while r1 != 0 { let k = r0 / r1; (r0, r1) = (r1, r0 - k * r1); (s0, s1) = (s1, s0 - k * s1); } s0.rem_euclid(m as i128) as u64 }
fn inv_e(m: &Big) -> Big { let k = (E - inverse(rem_small(m, E), E)) % E; div_small(&add(&mul(m, &small(k)), &small(1)), E) } // 1/e mod m = (1 + k m) / e
fn miller_rabin(n: &Big) -> bool {                  // bases: the first 12 primes, a sure answer below 3.3 x 10^24
    let (mo, nm1, mut s) = (Mont::new(n), sub(n, &small(1)), 0);
    let mut t = nm1.clone(); while t[0] & 1 == 0 { t = shr1(&t); s += 1; }
    [2u64, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37].iter().all(|&a| { let mut x = mo.power(&small(a), &t).0;
        x == small(1) || x == nm1 || (1..s).any(|_| { x = mo.mulmod(&x, &x); x == nm1 }) })
}
fn new_prime(g: &mut Rng, bits: usize) -> (Big, u32) { // odd, top two bits set; redraw until prime (about 355 draws at 1024 bits)
    (1..=20000).map(|draws| { let mut x: Big = (0..(bits + 63) / 64).map(|_| g.next()).collect(); x.reverse(); if bits < 64 { x[0] >>= 64 - bits; }
        x[(bits - 1) / 64] |= 3u64 << ((bits - 2) % 64); x[0] |= 1; (x, draws) }).find(|(x, _)| miller_rabin(x) && rem_small(x, E) != 1).expect("no prime in 20,000 draws")
}
fn by_trial(n: u128) -> bool { let mut k = 3; while k * k <= n { if n % k == 0 { return false; } k += 2; } true }
fn sha256(msg: &[u8]) -> Vec<u8> {                  // FIPS 180-4, written out as on the Hashes and MACs card
    let primes: Vec<u128> = (2u128..312).filter(|&x| (2..x).all(|p| x % p != 0)).collect(); // the first 64 primes
    let root = |x: u128, r: u32| (0..40).rev().fold(0u128, |v, b| if (v | 1 << b).pow(r) <= x << (32 * r) { v | 1 << b } else { v }) as u32;
    let (k, mut h): (Vec<u32>, Vec<u32>) = (primes.iter().map(|&p| root(p, 3)).collect(), primes[..8].iter().map(|&p| root(p, 2)).collect());
    for blk in [msg, &[0x80], &vec![0; (119 - msg.len() % 64) % 64], &(8 * msg.len() as u64).to_be_bytes()].concat().chunks(64) {
        let mut w: Vec<u32> = blk.chunks(4).map(|b| u32::from_be_bytes([b[0], b[1], b[2], b[3]])).collect();
        for i in 16..64 { let (a, b) = (w[i - 15], w[i - 2]); w.push(w[i - 16].wrapping_add(a.rotate_right(7) ^ a.rotate_right(18) ^ a >> 3).wrapping_add(w[i - 7]).wrapping_add(b.rotate_right(17) ^ b.rotate_right(19) ^ b >> 10)); }
        let v = (0..64).fold(h.clone(), |v, i| { let (a, e) = (v[0], v[4]);
            let t1 = v[7].wrapping_add(e.rotate_right(6) ^ e.rotate_right(11) ^ e.rotate_right(25)).wrapping_add(e & v[5] ^ !e & v[6]).wrapping_add(k[i]).wrapping_add(w[i]);
            let t2 = (a.rotate_right(2) ^ a.rotate_right(13) ^ a.rotate_right(22)).wrapping_add(a & v[1] ^ a & v[2] ^ v[1] & v[2]);
            vec![t1.wrapping_add(t2), a, v[1], v[2], v[3].wrapping_add(t1), e, v[5], v[6]] });
        h = h.iter().zip(&v).map(|(x, y)| x.wrapping_add(*y)).collect();
    }
    h.iter().flat_map(|x| x.to_be_bytes()).collect() }
fn mgf1(z: &[u8], n: usize) -> Vec<u8> { (0..((n + HL - 1) / HL) as u32).flat_map(|i| sha256(&[z, &i.to_be_bytes()[..]].concat())).take(n).collect() }
fn xor(a: &[u8], b: &[u8]) -> Vec<u8> { a.iter().zip(b).map(|(x, y)| x ^ y).collect() }
fn oaep_pad(msg: &[u8], seed: &[u8]) -> Big {      // RFC 8017 7.1.1: EM = 00 | maskedSeed | maskedDB
    assert!(msg.len() <= K - 2 * HL - 2, "message too long for OAEP");
    let mdb = xor(&[&sha256(b"")[..], &vec![0; K - msg.len() - 2 * HL - 2], &[1], msg].concat(), &mgf1(seed, K - HL - 1));
    from_bytes(&[&[0u8][..], &xor(seed, &mgf1(&mdb, HL)), &mdb].concat()) }
fn oaep_unpad(x: &Big) -> Option<Vec<u8>> {        // None for every kind of failure, never a reason
    let em = to_bytes(x, K); let mdb = &em[1 + HL..];
    let db = xor(mdb, &mgf1(&xor(&em[1..1 + HL], &mgf1(mdb, HL)), K - HL - 1));
    let rest: Vec<u8> = db[HL..].iter().copied().skip_while(|&b| b == 0).collect();
    if em[0] == 0 && db[..HL] == sha256(b"")[..] && rest.first() == Some(&1) { Some(rest[1..].to_vec()) } else { None } }
fn row(name: &str, v: String) { println!("{:<48}{}", name, v); }
fn yes(b: bool) -> &'static str { if b { "yes" } else { "no" } }
fn main() {
    let mut g = Rng(2026);                          // the toy key is drawn first, then 400 more toy primes
    let ((tp, tdp), (tq, tdq)) = (new_prime(&mut g, 32), new_prime(&mut g, 32));
    let draws: Vec<f64> = (0..400).map(|_| new_prime(&mut g, 32).1 as f64).collect();
    let ((p, dp_), (q, dq_), one) = (new_prime(&mut g, 1024), new_prime(&mut g, 1024), small(1));
    let (n, pm1, qm1) = (mul(&p, &q), sub(&p, &one), sub(&q, &one));
    let (phi, mp, mq, mn) = (mul(&pm1, &qm1), Mont::new(&p), Mont::new(&q), Mont::new(&n));
    let (d, dp, dq, qinv) = (inv_e(&phi), inv_e(&pm1), inv_e(&qm1), mp.power(&mp.reduce(&q), &sub(&pm1, &one)).0); // 1/q mod p = q^(p-2)
    let ed = (0..E).fold(mul(&d, &small(E)), |x, _| if cmp(&x, &phi) != Less { sub(&x, &phi) } else { x }); // e x d mod phi, by subtraction
    assert!(ed == one);                             // checked at once: the loops below rely on it
    println!("2048-bit key from SplitMix64, seed 2026: real size, INSECURE source");
    row("p: odd draws, bits, hex", format!("{}, {}, {}", dp_, bits(&p), hx(&p, 0)));
    row("q: odd draws, bits, hex", format!("{}, {}, {}", dq_, bits(&q), hx(&q, 0)));
    row("n = p x q: bits, decimal digits, hex", format!("{}, {}, {}", bits(&n), ((bits(&n) - 1) as f64 * 2f64.log10()) as u32 + 1, hx(&n, 0)));
    row("d: bits, hex; e x d mod phi", format!("{}, {}, {}", bits(&d), hx(&d, 0), ed[0]));
    row("expected odd draws, one 1024-bit prime", format!("{:.1}", (1024.0 * 2f64.ln() + 0.875f64.ln()) / 2.0));
    let (aes, seed) = (g.bytes(32), g.bytes(32));   // the AES key to send, and OAEP's fresh seed
    let em = oaep_pad(&aes, &seed); let (c, enc) = mn.power(&em, &small(E));
    row("AES key, 32 bytes; OAEP seed, 32 bytes", format!("{}, {}", hx(&from_bytes(&aes), 32), hx(&from_bytes(&seed), 32)));
    row("OAEP block EM: bytes, hex", format!("{}, {}", K, hx(&em, K)));
    row("e; c = EM^e mod n: multiplies, hex", format!("{}, {}, {}", E, enc, hx(&c, 0)));
    let crt = |c: &Big, flip: u64| {                // decrypt mod p and mod q, then glue
        let ((m1, k1), (mut m2, k2)) = (mp.power(&mp.reduce(c), &dp), mq.power(&mq.reduce(c), &dq));
        m2[0] ^= flip;                              // flip=1: one bit of the mod-q half goes wrong
        (add(&m2, &mul(&mp.mulmod(&qinv, &mp.reduce(&sub(&add(&m1, &p), &mp.reduce(&m2)))), &q)), k1, k2)
    };
    let ((em1, k_direct), (em2, k1, k2)) = (mn.power(&c, &d), crt(&c, 0)); let (ratio, back) = (4.0 * k_direct as f64 / (k1 + k2) as f64, oaep_unpad(&em2));
    assert!(em1 == em && em2 == em && back == Some(aes.clone())); // direct = CRT; OAEP round trip; checked at once
    row("decrypt: direct multiplies; CRT mod p, mod q", format!("{}, {}, {}", k_direct, k1, k2));
    row("cost: direct, CRT, speed-up", format!("{} x 4, {} x 1, {:.2}", k_direct, k1 + k2, ratio));
    row("direct and CRT both give EM; OAEP gives key", format!("{}, {}", yes(em1 == em && em2 == em), yes(back == Some(aes.clone()))));
    let c2 = mn.power(&oaep_pad(&aes, &g.bytes(32)), &small(E)).0;
    row("same key, fresh seed: c, decodes to the key", format!("{}, {}", hx(&c2, 0), yes(oaep_unpad(&crt(&c2, 0).0) == Some(aes.clone()))));
    row("OAEP, 2048-bit key: largest message, bytes", (K - 2 * HL - 2).to_string());
    let enc_e = |x: u64| mn.power(&small(x), &small(E)).0; let (m, c500) = (500u64, enc_e(500)); // a small amount, sent textbook-style
    let guess = (1..10001u64).find(|&k| enc_e(k) == c500).unwrap();
    row("break 1, textbook 500: found, encryptions", format!("{}, {}", guess, guess));
    let doubled = crt(&mn.mulmod(&c500, &enc_e(2)), 0).0;
    row("break 2, textbook c x 2^e decrypts to", doubled[0].to_string());
    let tamper = (2..202u64).filter(|&s| oaep_unpad(&crt(&mn.mulmod(&c, &enc_e(s)), 0).0).is_some()).count();
    row("break 2 on OAEP: accepted, tried; 1 in 2^", format!("{}, {}, {}", tamper, 200, 8 * HL));
    let g3 = gcd(mn.reduce(&sub(&add(&mn.power(&crt(&c, 1).0, &small(E)).0, &n), &c)), n.clone());
    row("break 3, CRT fault: gcd(bad^e - c, n)", hx(&g3, 0));
    let g4 = gcd(n.clone(), mul(&p, &new_prime(&mut g, 1024).0));
    row("break 4, shared prime: gcd(n, p x q2)", hx(&g4, 0));
    let (mut k, nm1) = (sub(&mul(&d, &small(E)), &one), sub(&n, &one));
    while k[0] & 1 == 0 { k = shr1(&k); }
    let (a, x) = (2..1000u64).find_map(|a| {        // bases sharing no factor with n; want a square root of 1 not +1 or -1
        let mut x = mn.power(&small(a), &k).0; let mut y = mn.mulmod(&x, &x);
        while y != one { x = y.clone(); y = mn.mulmod(&y, &y); } if x != one && x != nm1 { Some((a, x)) } else { None } }).unwrap();
    let g5 = gcd(sub(&x, &one), n.clone());
    row("break 5, leaked d: base used, factor", format!("{}, {}", a, hx(&g5, 0)));
    let (tp, tq) = (tp[0] as u128, tq[0] as u128);
    let (tn, td) = (tp * tq, inverse(E, ((tp - 1) * (tq - 1)) as u64));
    row("toy key, INSECURE: 32-bit p, q; n = p x q, bits", format!("{}, {}, {}, {}", tp, tq, tn, 128 - tn.leading_zeros()));
    let (mean, theory) = (draws.iter().sum::<f64>() / 400.0, (32.0 * 2f64.ln() + 0.875f64.ln()) / 2.0);
    let se = (draws.iter().map(|x| (x - mean) * (x - mean)).sum::<f64>() / 399.0 / 400.0).sqrt();
    row("odd draws: toy p, q; mean of 400; theory", format!("{}, {}, {:.2}, {:.2}", tdp, tdq, mean, theory));
    let gcd2 = |mut a: u128, mut b: u128| { while b != 0 { (a, b) = (b, a % b); } a };
    let (mut x, mut y, mut steps, mut f) = (2u128, 2u128, 0, 1u128); // Pollard rho, f(x) = x^2 + 1; the hare takes two steps
    while f == 1 { x = (x * x + 1) % tn; y = (y * y + 1) % tn; y = (y * y + 1) % tn; steps += 1; f = gcd2((x + tn - y) % tn, tn); }
    row("Pollard rho on toy n: factor, steps; sqrt(p)", format!("{}, {}, {}", f, steps, (tp as f64).sqrt() as u64));
    let (d2, v1978) = (inverse(E, ((f - 1) * (tn / f - 1)) as u64), Mont::new(&small(2773)).power(&small(920), &small(17)).0[0]);
    row("toy d rebuilt from that factor matches", yes(d2 == td).to_string());
    row("RSA 1978, p 47, q 59, e 17: d, 920^17 mod 2773", format!("{}, {}", inverse(17, 46 * 58), v1978));
    row("log2 work, 2048-bit n: trial division, rho", format!("{}, {}", 2048 / 2 - 1, 2048 / 4));
    println!("log2 work to factor: key bits, GNFS formula, NIST");
    for (b, nist) in [(1024, 80), (2048, 112), (3072, 128), (7680, 192), (15360, 256)] { let ln_n = b as f64 * 2f64.ln();
        let gnfs = (64.0f64 / 9.0).powf(1.0 / 3.0) * ln_n.powf(1.0 / 3.0) * ln_n.ln().powf(2.0 / 3.0) / 2f64.ln();
        println!("  {:>5}  {:6.1}  {:>3}", b, gnfs, nist); assert!(0.0 < gnfs - nist as f64 && gnfs - (nist as f64) < 15.0); } // no o(1): a little above
    let abc: String = sha256(b"abc").iter().map(|x| format!("{:02x}", x)).collect();
    assert!(abc == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"); // FIPS 180-4 test vector
    assert!(by_trial(tp) && by_trial(tq) && (mean - theory).abs() < 3.0 * se && c2 != c);
    assert!(k_direct == bits(&d) - 2 + d.iter().map(|x| x.count_ones()).sum::<u32>() && 3.5 < ratio && ratio < 4.5);
    assert!(guess == m && doubled == small(2 * m) && tamper == 0 && g3 == p && g4 == p && (g5 == p || g5 == q));
    assert!((f == tp || f == tq) && d2 == td && inverse(17, 2668) == 157 && v1978 == 948);
    println!("ALL CHECKS PASS");
}
