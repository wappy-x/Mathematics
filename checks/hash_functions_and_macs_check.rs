// Hashes and MACs -- the check behind the card.  std only, no crates.
// SHA-256 (FIPS 180-4), HMAC (RFC 2104) and PBKDF2 are written out.
// The attacks run on digests cut to a few bits: toy sizes, insecure on purpose.
use std::{collections::HashMap, f64::consts::PI};
use std::sync::atomic::{AtomicU64, Ordering::Relaxed};
static COUNT: AtomicU64 = AtomicU64::new(0); // compressions done: the unit of cost
fn primes(c: usize) -> Vec<u128> {
    let (mut out, mut x): (Vec<u128>, u128) = (vec![], 2);
    while out.len() < c { if out.iter().filter(|&&p| p * p <= x).all(|&p| x % p != 0) { out.push(x); } x += 1; }
    out
}
fn frac_root(r: u32, x: u128) -> u32 { // 32 bits after the point of x^(1/r), integers only
    let (mut lo, mut hi) = (0u128, 1u128 << 40);
    while lo < hi { let mid = (lo + hi + 1) / 2; if mid.pow(r) <= x << (32 * r) { lo = mid; } else { hi = mid - 1; } }
    (lo & 0xFFFF_FFFF) as u32
}
struct Sha { k: Vec<u32>, h0: [u32; 8] }
impl Sha {
    fn new() -> Sha {
        let h0: Vec<u32> = primes(8).iter().map(|&p| frac_root(2, p)).collect();
        Sha { k: primes(64).iter().map(|&p| frac_root(3, p)).collect(), h0: h0.try_into().unwrap() }
    }
    fn compress(&self, st: [u32; 8], blk: &[u8]) -> [u32; 8] {
        COUNT.fetch_add(1, Relaxed);
        let mut w = [0u32; 64];
        for i in 0..16 { w[i] = u32::from_be_bytes([blk[4 * i], blk[4 * i + 1], blk[4 * i + 2], blk[4 * i + 3]]); }
        for i in 16..64 {
            let (a, b) = (w[i - 15], w[i - 2]);
            let (s0, s1) = (a.rotate_right(7) ^ a.rotate_right(18) ^ (a >> 3), b.rotate_right(17) ^ b.rotate_right(19) ^ (b >> 10));
            w[i] = w[i - 16].wrapping_add(s0).wrapping_add(w[i - 7]).wrapping_add(s1);
        }
        let [mut a, mut b, mut c, mut d, mut e, mut f, mut g, mut h] = st;
        for i in 0..64 {
            let t1 = h.wrapping_add(e.rotate_right(6) ^ e.rotate_right(11) ^ e.rotate_right(25))
                .wrapping_add((e & f) ^ (!e & g)).wrapping_add(self.k[i]).wrapping_add(w[i]);
            let t2 = (a.rotate_right(2) ^ a.rotate_right(13) ^ a.rotate_right(22)).wrapping_add((a & b) ^ (a & c) ^ (b & c));
            h = g; g = f; f = e; e = d.wrapping_add(t1); d = c; c = b; b = a; a = t1.wrapping_add(t2);
        }
        let (v, mut out) = ([a, b, c, d, e, f, g, h], st);
        for i in 0..8 { out[i] = st[i].wrapping_add(v[i]); }
        out
    }
    fn hash_from(&self, m: &[u8], st: [u32; 8], done: usize) -> Vec<u8> { // done = bytes already folded in
        let mut s = st;
        for blk in [m, &pad(done + m.len())[..]].concat().chunks(64) { s = self.compress(s, blk); }
        s.iter().flat_map(|x| x.to_be_bytes()).collect()
    }
    fn hash(&self, m: &[u8]) -> Vec<u8> { self.hash_from(m, self.h0, 0) }
    fn hmac(&self, k: &[u8], m: &[u8]) -> Vec<u8> {
        let key = pad64(if k.len() > 64 { self.hash(k) } else { k.to_vec() });
        let inner = self.hash(&[&xor(&key, 0x36)[..], m].concat());
        self.hash(&[xor(&key, 0x5C), inner].concat())
    }
    fn pbkdf2(&self, pw: &[u8], salt: &[u8], r: usize, blocks: u32, cached: bool) -> Vec<u8> {
        let key = pad64(pw.to_vec()); // passwords here are under 64 bytes; careful code folds the key blocks once
        let (ist, ost) = if cached { (self.compress(self.h0, &xor(&key, 0x36)), self.compress(self.h0, &xor(&key, 0x5C))) } else { (self.h0, self.h0) };
        let mac = |m: &[u8]| if cached { self.hash_from(&self.hash_from(m, ist, 64), ost, 64) } else { self.hmac(pw, m) };
        let mut out = vec![];
        for j in 1..=blocks {
            let mut u = mac(&[salt, &j.to_be_bytes()[..]].concat());
            let mut acc = u.clone();
            for _ in 1..r { u = mac(&u); for i in 0..32 { acc[i] ^= u[i]; } }
            out.extend(acc);
        }
        out
    }
}
fn pad(total: usize) -> Vec<u8> { [vec![0x80u8], vec![0u8; (55 + 64 * 64 - total) % 64], (8 * total as u64).to_be_bytes().to_vec()].concat() }
fn xor(k: &[u8], b: u8) -> Vec<u8> { k.iter().map(|x| x ^ b).collect() }
fn pad64(mut k: Vec<u8>) -> Vec<u8> { k.resize(64, 0); k }
fn hex(b: &[u8]) -> String { b.iter().map(|x| format!("{:02x}", x)).collect() }
fn top(d: &[u8], bits: u32) -> u32 { u32::from_be_bytes([d[0], d[1], d[2], d[3]]) >> (32 - bits) }
fn bitdiff(a: &[u8], b: &[u8]) -> u32 { a.iter().zip(b).map(|(x, y)| (x ^ y).count_ones()).sum() }
fn exact_mean(d: f64) -> f64 { // E[T] = sum over k of P(first k values all differ)
    let (mut s, mut p, mut k) = (0.0, 1.0, 0.0);
    while p > 1e-18 { s += p; p *= 1.0 - k / d; k += 1.0; }
    s
}
fn mean_se(t: &[f64]) -> (f64, f64) {
    let (n, m) = (t.len() as f64, t.iter().sum::<f64>() / t.len() as f64);
    (m, (t.iter().map(|x| (x - m) * (x - m)).sum::<f64>() / (n - 1.0) / n).sqrt())
}
fn first_repeat(sh: &Sha, bits: u32, label: &str) -> (u64, u64, u64) {
    let mut seen: HashMap<u32, u64> = HashMap::new();
    for i in 0u64.. {
        let v = top(&sh.hash(format!("{}{}", label, i).as_bytes()), bits);
        if let Some(&j) = seen.get(&v) { return (i + 1, j, i); }
        seen.insert(v, i);
    }
    unreachable!()
}
fn main() {
    let sh = Sha::new();
    println!("== SHA-256 against FIPS 180-4 ==");
    println!("K[0] = {:08x}  K[63] = {:08x}  H0[0] = {:08x}", sh.k[0], sh.k[63], sh.h0[0]);
    let abc = hex(&sh.hash(b"abc")); println!("h(abc) = {}", abc);
    assert!(abc == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad", "FIPS vector 1");
    assert!(hex(&sh.hash(b"abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq")) == "248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1", "FIPS vector 2");
    println!("== the contract ==");
    let c: &[u8] = b"Sale of 14 Elm Road for GBP 250,000; completes 1/3/2027";
    let (dc, dc2) = (sh.hash(c), sh.hash(b"Sale of 14 Elm Road for GBP 260,000; completes 1/3/2027"));
    println!("bytes {}  h = {}\n260,000 h = {}", c.len(), hex(&dc), hex(&dc2));
    let flips: Vec<f64> = (0..8 * c.len()).map(|i| { let mut e = c.to_vec(); e[i / 8] ^= 1 << (i % 8); bitdiff(&dc, &sh.hash(&e)) as f64 }).collect();
    let ((mean, se), mn, mx) = (mean_se(&flips), flips.iter().cloned().fold(1e9, f64::min), flips.iter().cloned().fold(0.0, f64::max));
    println!("one char changed: {} of 256 bits differ", bitdiff(&dc, &dc2));
    println!("all {} one-bit edits: mean {:.2} bits differ (ideal 128, se {:.2}), min {} max {}", flips.len(), mean, se, mn, mx);
    assert!((mean - 128.0).abs() < 4.0 * se, "avalanche: a one-bit edit should flip half the bits");
    println!("pigeonhole: 2^{} messages of 33 bytes into 2^256 digests, some digest shared by >= {}", 8 * 33, 1u32 << (8 * 33 - 256));
    println!("== the bounds, for an ideal n-bit hash ==");
    let (half, avg) = ((2.0 * 2f64.ln()).sqrt(), (PI / 2.0).sqrt());
    for n in [256, 160, 64] { println!("n={}: half-chance at {:.4} x 2^{}, mean {:.4} x 2^{}, guessing 2^{}", n, half, n / 2, avg, n / 2, n); }
    println!("n=256 in tries: 2^128 = {:.4} x 10^38, half-chance {:.4} x 10^38", 2f64.powi(128) / 1e38, half * 2f64.powi(128) / 1e38);
    println!("SHA-1: promised 2^80, published attack 2^63.1, short by about 2^{} = {}", (80.0f64 - 63.1).round(), 1u64 << (80.0f64 - 63.1).round() as u32);
    println!("64-bit digest, mean tries to a collision = {:.0}", (PI / 2.0 * 2f64.powi(64)).sqrt());
    println!("== collisions on digests cut to n bits (toy, insecure) ==");
    for n in [8u32, 12, 16, 20] {
        let t: Vec<f64> = (0..40).map(|r| first_repeat(&sh, n, &format!("Elm Road draft {}.", r)).0 as f64).collect();
        let ((m, se), ex) = (mean_se(&t), exact_mean(2f64.powi(n as i32)));
        println!("n={:2} runs 40 measured {:8.2} (se {:6.2})  exact {:8.2}  sqrt(pi/2 2^n) {:8.2}", n, m, se, ex, (PI / 2.0 * 2f64.powi(n as i32)).sqrt());
        assert!((m - ex).abs() < 4.0 * se, "collision cost at n={}", n);
    }
    let l = "Sale of 14 Elm Road for GBP 250,000; ref ";
    let (tries, a, b) = first_repeat(&sh, 32, l);
    let (ha, hb) = (sh.hash(format!("{}{}", l, a).as_bytes()), sh.hash(format!("{}{}", l, b).as_bytes()));
    println!("n=32: refs {} and {} share {}, after {} tries (exact mean {:.0})", a, b, hex(&ha[..4]), tries, exact_mean(2f64.powi(32)));
    assert!(top(&ha, 32) == top(&hb, 32) && a != b, "32-bit collision");
    println!("== second preimages: match the contract's first n bits ==");
    let mut ratios = vec![];
    for n in [8u32, 10, 12] {
        let t: Vec<u64> = (0..20).map(|r| (1u64..).find(|i| top(&sh.hash(format!("Sale of 14 Elm Road for GBP 25,000; v{}.{}", r, i).as_bytes()), n) == top(&dc, n)).unwrap()).collect();
        ratios.extend(t.iter().map(|&x| x as f64 / 2f64.powi(n as i32)));
        println!("n={:2} runs 20 measured {:8.1}  ideal 2^n = {}", n, t.iter().sum::<u64>() as f64 / 20.0, 1u64 << n);
    }
    let rm = ratios.iter().sum::<f64>() / ratios.len() as f64;
    println!("all 60 runs: measured / 2^n = {:.3} (ideal 1, se {:.3})", rm, 1.0 / 60f64.sqrt());
    assert!((rm - 1.0).abs() < 4.0 / 60f64.sqrt(), "second preimage cost should be 2^n");
    println!("== MACs: one message from the laptop to the bank ==");
    let key: Vec<u8> = (0..32).collect(); // a toy key, printed, so insecure on purpose
    let (msg, ext): (&[u8], &[u8]) = (b"from=laptop&pay=250000.00&to=12345678", b"&to=66666666");
    let (naive, glue) = (sh.hash(&[&key[..], msg].concat()), pad(key.len() + msg.len()));
    let state: [u32; 8] = std::array::from_fn(|i| u32::from_be_bytes(naive[4 * i..4 * i + 4].try_into().unwrap())); // the tag IS the state
    let forged = sh.hash_from(ext, state, key.len() + msg.len() + glue.len()); // no key used
    let fmsg = [msg, &glue[..], ext].concat(); let keyed = sh.hash(&[&key[..], &fmsg[..]].concat()); // the bank uses k
    println!("naive tag h(k||m) = {}...  glue {} bytes, forged message {} bytes", &hex(&naive)[..16], glue.len(), fmsg.len());
    println!("forged tag, made without k = {}...  bank's check: {}", &hex(&forged)[..16], if forged == keyed { "accepted" } else { "rejected" });
    assert!(forged == keyed, "length extension");
    let real = sh.hmac(&key, &fmsg);
    println!("HMAC tag of forged message = {}...  bank's check: {}", &hex(&real)[..16], if forged == real { "accepted" } else { "rejected" });
    assert!(forged != real, "HMAC must not fall to length extension");
    let rfc = hex(&sh.hmac(b"Jefe", b"what do ya want for nothing?")); println!("RFC 4231 case 2: {}...", &rfc[..16]);
    assert!(rfc == "5bdcc146bf60754e6a042426089575c75a003f089d2739839dec58b964ec3843", "HMAC vector");
    println!("== password key derivation ==");
    let (v, v2) = (hex(&sh.pbkdf2(b"passwd", b"salt", 1, 2, false)), hex(&sh.pbkdf2(b"Password", b"NaCl", 80000, 1, true)));
    println!("RFC 7914 PBKDF2 vectors: r=1 {}..., r=80000 {}...", &v[..16], &v2[..16]);
    assert!(v.starts_with("55ac046e56e3089fec1691c22544b605") && v.ends_with("49ca9cccf179b645991664b39d77ef317c71b845b1e30bd509112041d3a19783"), "PBKDF2 vector"); assert!(v2 == "4ddcd8f60b98be21830cee5ef22701f9641a4418d04c0414aeff08876b34ab56", "PBKDF2 vector 2");
    let (pw, s1, s2): (&[u8], &[u8], &[u8]) = (b"letmein1", b"customer-000001", b"customer-000002");
    println!("same password, no salt: both customers store {}", &hex(&sh.hash(pw))[..8]);
    println!("same password, salted, r=1000: {} and {}", &hex(&sh.pbkdf2(pw, s1, 1000, 1, false))[..8], &hex(&sh.pbkdf2(pw, s2, 1000, 1, false))[..8]);
    let reference = sh.pbkdf2(pw, s1, 1000, 1, false);
    for cached in [false, true] {
        COUNT.store(0, Relaxed);
        let (out, cnt) = (sh.pbkdf2(pw, s1, 1000, 1, cached), COUNT.load(Relaxed));
        println!("{} code: {} compressions per guess, key {}", if cached { "cached" } else { "plain " }, cnt, &hex(&out)[..8]);
        assert!(cnt == if cached { 2 * 1000 + 2 } else { 4 * 1000 } && out == reference, "cost count");
    }
    let (g, r, u): (u128, u128, u128) = (26u128.pow(8), 100000, 1000000);
    println!("8 lower-case letters: {} guesses; plain hash {} compressions; r={}: {}", g, g, r, g * (2 * r + 2));
    println!("{} customers: unsalted, one pass {}; salted, {} passes {}", u, g * (2 * r + 2), u, g * (2 * r + 2) * u);
    println!("ALL CHECKS PASS");
}
