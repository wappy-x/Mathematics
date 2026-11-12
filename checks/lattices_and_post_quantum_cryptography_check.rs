// Lattices and post-quantum cryptography -- the check behind the card.  std only, no crates.
// Kyber-768's inner encryption (K-PKE in FIPS 203) at real sizes; INSECURE: SplitMix64, no SHAKE/NTT/FO.
use std::f64::consts::{E, PI};
struct SplitMix64 { s: u64 }
impl SplitMix64 {
    fn next(&mut self) -> u64 {
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let z = (self.s ^ (self.s >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        let z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    }
}
const Q: i64 = 3329; const N: usize = 256; const K: usize = 3;
type P = Vec<i64>;
fn cbd(rng: &mut SplitMix64, eta: u32) -> i64 { // eta coin flips minus eta coin flips: a small number
    let (x, m) = (rng.next(), (1u64 << eta) - 1);
    (x & m).count_ones() as i64 - ((x >> eta) & m).count_ones() as i64
}
fn small(rng: &mut SplitMix64, eta: u32) -> P { (0..N).map(|_| cbd(rng, eta)).collect() }
fn smalls(rng: &mut SplitMix64, eta: u32) -> Vec<P> { (0..K).map(|_| small(rng, eta)).collect() }
fn pmul(a: &P, b: &P) -> P { // polynomial product with X^256 = -1, mod q (a is small)
    let mut c = vec![0i64; 2 * N];
    for (i, &ai) in a.iter().enumerate() {
        if ai != 0 { for (j, &bj) in b.iter().enumerate() { c[i + j] += ai * bj; } }
    }
    (0..N).map(|i| (c[i] - c[i + N]).rem_euclid(Q)).collect()
}
fn padd(ps: &[P]) -> P { (0..N).map(|i| ps.iter().map(|p| p[i]).sum::<i64>().rem_euclid(Q)).collect() }
fn dotp(a: &[P], b: &[P]) -> P { padd(&(0..K).map(|i| pmul(&a[i], &b[i])).collect::<Vec<_>>()) }
fn centred(x: i64) -> i64 { let x = x.rem_euclid(Q); if x > Q / 2 { x - Q } else { x } }
fn compress(x: i64, d: u32) -> i64 { ((x << (d + 1)) + Q) / (2 * Q) % (1 << d) }
fn decompress(y: i64, d: u32) -> i64 { (y * Q * 2 + (1 << d)) >> (d + 1) }
fn pack(polys: &[P], d: u32) -> Vec<u8> { // every number in d bits, 8 bits to a byte
    let bits: Vec<u8> = polys.iter().flat_map(|p| p.iter()).flat_map(|&c| (0..d).map(move |i| ((c >> i) & 1) as u8)).collect();
    bits.chunks(8).map(|ch| ch.iter().enumerate().map(|(i, &b)| b << i).sum()).collect()
}
struct Key { a: Vec<Vec<P>>, s: Vec<P>, e: Vec<P>, t: Vec<P> }
fn keygen(rng: &mut SplitMix64, eta: u32) -> Key {
    let a: Vec<Vec<P>> = (0..K).map(|_| (0..K).map(|_| (0..N).map(|_| (rng.next() % Q as u64) as i64).collect()).collect()).collect();
    let (s, e) = (smalls(rng, eta), smalls(rng, eta));
    let t = (0..K).map(|i| padd(&[dotp(&a[i], &s), e[i].clone()])).collect(); // t = A s + e
    Key { a, s, e, t }
}
// returns compressed u, compressed v, and the raw (r, e1, e2, u, v)
fn encrypt(rng: &mut SplitMix64, k: &Key, m: &[i64], eta: u32) -> (Vec<P>, P, (Vec<P>, Vec<P>, P, Vec<P>, P)) {
    let (r, e1, e2) = (smalls(rng, eta), smalls(rng, eta), small(rng, eta));
    let u: Vec<P> = (0..K).map(|j| { let col: Vec<P> = (0..K).map(|i| k.a[i][j].clone()).collect(); padd(&[dotp(&r, &col), e1[j].clone()]) }).collect();
    let v = padd(&[dotp(&r, &k.t), e2.clone(), m.iter().map(|b| 1665 * b).collect()]); // v = t.r + e2 + 1665 m
    (u.iter().map(|p| p.iter().map(|&x| compress(x, 10)).collect()).collect(), v.iter().map(|&x| compress(x, 4)).collect(), (r, e1, e2, u, v))
}
fn decrypt(s: &[P], cu: &[P], cv: &P) -> (P, P) { // w = v - s.u, then round each number to 0 or 1665
    let u: Vec<P> = cu.iter().map(|p| p.iter().map(|&x| decompress(x, 10)).collect()).collect();
    let su = dotp(s, &u); let w: P = (0..N).map(|i| (decompress(cv[i], 4) - su[i]).rem_euclid(Q)).collect();
    (w.iter().map(|&x| compress(x, 1)).collect(), w)
}
fn run(eta: u32, trials: usize, seed: u64) -> (usize, i64, Key, Vec<P>, P, P, SplitMix64) {
    let mut rng = SplitMix64 { s: seed }; let key = keygen(&mut rng, eta);
    let (mut bad, mut big, mut last) = (0, 0, (vec![], vec![], vec![]));
    for _ in 0..trials {
        let m: P = (0..N).map(|_| (rng.next() & 1) as i64).collect();
        let (cu, cv, _) = encrypt(&mut rng, &key, &m, eta); let (got, w) = decrypt(&key.s, &cu, &cv);
        bad += (0..N).filter(|&i| got[i] != m[i]).count();
        big = big.max((0..N).map(|i| centred(w[i] - 1665 * m[i]).abs()).max().unwrap());
        last = (cu, cv, m);
    }
    (bad, big, key, last.0, last.1, last.2, rng)
}
fn mpow(b: i64, k: i64, m: i64) -> i64 { if k == 0 { 1 } else { mpow(b * b % m, k >> 1, m) * (if k & 1 == 1 { b } else { 1 }) % m } }
fn solve(a: &[Vec<i64>], b: &[i64]) -> Vec<i64> { // Gaussian elimination mod q, inverse by Fermat
    let n = a.len(); let mut mm: Vec<Vec<i64>> = (0..n).map(|i| { let mut r = a[i].clone(); r.push(b[i]); r }).collect();
    for c in 0..n {
        let p = (c..n).find(|&i| mm[i][c] != 0).unwrap(); mm.swap(c, p);
        let iv = mpow(mm[c][c], Q - 2, Q); mm[c] = mm[c].iter().map(|x| x * iv % Q).collect();
        let rc = mm[c].clone();
        for i in (0..n).filter(|&i| i != c) { let f = mm[i][c]; mm[i] = mm[i].iter().zip(&rc).map(|(x, y)| (x - f * y).rem_euclid(Q)).collect(); }
    }
    mm.iter().map(|r| centred(r[n])).collect()
}
type V = (i64, i64);
fn dot(a: V, b: V) -> i64 { a.0 * b.0 + a.1 * b.1 }  fn det(p: V, q: V) -> i64 { p.0 * q.1 - p.1 * q.0 }
fn comb(x: i64, y: i64, p: V, q: V) -> V { (x * p.0 + y * q.0, x * p.1 + y * q.1) }
fn rnd(n: i64, d: i64) -> i64 { if d > 0 { (2 * n + d).div_euclid(2 * d) } else { rnd(-n, -d) } }
fn gauss(mut a: V, mut b: V) -> (V, V, i32) { // Lagrange-Gauss: subtract the nearest multiple, swap, repeat
    for steps in 0.. {
        if dot(a, a) > dot(b, b) { std::mem::swap(&mut a, &mut b); }
        let k = rnd(dot(a, b), dot(a, a));
        if k == 0 { return (a, b, steps); }
        b = comb(-k, 1, a, b);
    }
    unreachable!()
}
fn babai(tg: V, p: V, q: V) -> V { let d = det(p, q); comb(rnd(det(tg, q), d), rnd(det(p, tg), d), p, q) }
fn delta(b: f64) -> f64 { ((PI * b).powf(1.0 / b) * b / (2.0 * PI * E)).powf(1.0 / (2.0 * (b - 1.0))) }
fn beta(n: usize, sigma: f64, q: f64, top: usize) -> usize { // smallest BKZ block size that finds the short vector
    let mut best = top; // m, the samples used, runs up to top (Kyber gives n)
    for m in n / 2..=top {
        let d = (n + m + 1) as f64;
        best = (60..best).find(|&b| { let bf = b as f64; sigma * bf.sqrt() <= delta(bf).powf(2.0 * bf - d - 1.0) * q.powf(m as f64 / d) }).unwrap_or(best);
    }
    best
}
fn gcd(x: i64, y: i64) -> i64 { if y == 0 { x } else { gcd(y, x % y) } }
fn main() {
    println!("Kyber-768 inner scheme, k = 3, n = 256, q = 3329, eta = 2; SplitMix64 seed 2026: INSECURE");
    let (bad, big, key, cu, cv, m, mut rng) = run(2, 8, 2026);
    let mut pk = pack(&key.t, 12); pk.extend([0u8; 32]); // + 32-byte seed that rebuilds A
    let mut ct = pack(&cu, 10); ct.extend(pack(&[cv], 4));
    println!("public key bytes: 3 x 256 x 12 bits / 8 = {}, + 32 = {}, packed {}", 384 * K, 384 * K + 32, pk.len());
    println!("ciphertext bytes: 3 x 256 x 10 / 8 = {}, + 256 x 4 / 8 = 128, total {}, packed {}", 320 * K, 32 * (10 * K + 4), ct.len());
    println!("secret numbers hidden in the key: {}; shared secret 32 bytes = 256 bits", K * N);
    println!("8 messages, {} bits: wrong bits {}, largest noise {}, margin q/4 = {}", 8 * N, bad, big, Q / 4);
    assert!(pk.len() == 384 * K + 32 && pk.len() == 1184 && ct.len() == 32 * (10 * K + 4) && ct.len() == 1088 && bad == 0 && big < Q / 4);
    let (r, e1, e2, u, v) = encrypt(&mut SplitMix64 { s: 5 }, &key, &m, 2).2; // Step 3's identity, uncompressed
    let su = dotp(&key.s, &u); let lhs: P = (0..N).map(|i| (v[i] - su[i]).rem_euclid(Q)).collect();
    let (er, se1) = (dotp(&r, &key.e), dotp(&key.s, &e1));
    let rhs: P = (0..N).map(|i| (er[i] - se1[i] + e2[i] + 1665 * m[i]).rem_euclid(Q)).collect();
    println!("v - s.u equals e.r - s.e1 + e2 + 1665 m in all 256 places: {}", if lhs == rhs { "True" } else { "False" });
    assert!(lhs == rhs && pmul(&(0..N).map(|j| (j == N - 1) as i64).collect(), &(0..N).map(|j| (j == 1) as i64).collect()) == (0..N).map(|j| if j == 0 { Q - 1 } else { 0 }).collect::<P>()); // and X^255 * X = -1
    println!("X25519 key 32 bytes; Kyber-768 key {:.1} times larger; hybrid shares {} and {}", pk.len() as f64 / 32.0, pk.len() + 32, ct.len() + 32);
    println!("Kyber-512: key {}, ciphertext {} bytes; Kyber-1024: key {}, ciphertext {} bytes", 384 * 2 + 32, 32 * (10 * 2 + 4), 384 * 4 + 32, 32 * (11 * 4 + 5));
    // ---- what breaks ----
    let (bad24, big24, ..) = run(24, 1, 2026);
    println!("noise too wide, eta = 24: wrong bits {} of 256, largest noise {}", bad24, big24);
    assert!(bad24 > 0 && big24 > Q / 4);
    let (m1, m2): (P, P) = ((0..N).map(|_| (rng.next() & 1) as i64).collect(), (0..N).map(|_| (rng.next() & 1) as i64).collect());
    let (v1, v2) = (encrypt(&mut SplitMix64 { s: 99 }, &key, &m1, 2).1, encrypt(&mut SplitMix64 { s: 99 }, &key, &m2, 2).1);
    let same = (0..N).filter(|&i| { let d = (v1[i] - v2[i]).rem_euclid(16); ((4..=12).contains(&d) as i64) == (m1[i] ^ m2[i]) }).count();
    println!("randomness reused for two messages: their XOR read off in {} of 256 places", same);
    assert!(same == 256);
    let mut g = SplitMix64 { s: 7 };
    let at: Vec<Vec<i64>> = (0..8).map(|_| (0..8).map(|_| (g.next() % Q as u64) as i64).collect()).collect();
    let (st, et): (Vec<i64>, Vec<i64>) = ((0..8).map(|_| cbd(&mut g, 2)).collect(), (0..8).map(|_| cbd(&mut g, 2)).collect());
    let b0: Vec<i64> = at.iter().map(|row| row.iter().zip(&st).map(|(a, x)| a * x).sum::<i64>().rem_euclid(Q)).collect();
    let (s0, s1) = (solve(&at, &b0), solve(&at, &b0.iter().zip(&et).map(|(x, y)| (x + y).rem_euclid(Q)).collect::<Vec<_>>()));
    println!("toy LWE, 8 unknowns: secret {:?}\n  no noise, elimination gives {:?}\n  with noise it gives {:?}", st, s0, s1);
    assert!(s0 == st && s1 != st);
    // ---- the lattice picture: a good basis and a bad one for the same grid ----
    let (g1, g2): (V, V) = ((4, 1), (-1, 3)); let (c1, c2) = (comb(5, 3, g1, g2), comb(3, 2, g1, g2));
    let mut brute = i64::MAX;
    for x in -20..=20 { for y in -20..=20 { let p = comb(x, y, g1, g2); if p != (0, 0) { brute = brute.min(dot(p, p)); } } }
    let (ra, rb, st2) = gauss(c1, c2);
    println!("bad basis {:?} {:?}, area {}; good basis {:?} {:?}, area {}", c1, c2, det(c1, c2), g1, g2, det(g1, g2));
    println!("Gauss reduction of the bad basis, {} steps: {:?} {:?}; shortest by brute force has length^2 {}", st2, ra, rb, brute);
    assert!(dot(ra, ra) == brute && brute == 10 && det(ra, rb).abs() == 13);
    let tg: V = (6, 10); let (okp, badp) = (babai(tg, g1, g2), babai(tg, c1, c2)); let dist2 = |a: V| (a.0 - tg.0).pow(2) + (a.1 - tg.1).pow(2);
    println!("target {:?}: rounding in good basis -> {:?}, distance^2 {}; in bad basis -> {:?}, distance^2 {}", tg, okp, dist2(okp), badp, dist2(badp));
    assert!(dist2(okp) == 2 && dist2(badp) == 25 && (-20..=20).flat_map(|x| (-20..=20).map(move |y| comb(x, y, g1, g2))).min_by_key(|&p| (dist2(p), p)) == Some(okp));
    println!("bad = 5 g1 + 3 g2 and 3 g1 + 2 g2, mix area 5 x 2 - 3 x 3 = {}; amounts good {}/13 {}/13, bad {}/13 {}/13", 5 * 2 - 3 * 3, det(tg, g2), det(g1, tg), det(tg, c2), det(c1, tg));
    println!("figure, good {:?} {:?}; bad {:?} {:?}; target {:?}; right {:?}; bad-basis answer {:?}", g1, g2, c1, c2, tg, okp, badp);
    // ---- security estimate (primal attack, core-SVP rule) and what Shor ends ----
    let bs = vec![beta(512, 1.5f64.sqrt(), Q as f64, 512), beta(768, 1.0, Q as f64, 768), beta(1024, 1.0, Q as f64, 1024)];
    let f = |c: f64| bs.iter().map(|&b| format!("{:.1}", c * b as f64)).collect::<Vec<_>>().join(" ");
    println!("block size beta for Kyber-512/768/1024: {:?} -> classical 2^(0.292 beta): {} quantum 2^(0.265 beta): {}", bs, f(0.292), f(0.265));
    assert!(bs[0] < bs[1] && bs[1] < bs[2] && 0.292 * bs[1] as f64 > 128.0);
    let nh = beta(1024, 8f64.sqrt(), 12289.0, 2048); println!("same rule on New Hope, n = 1024, q = 12289: beta {}; its paper, Table 1: 967", nh); assert!((nh as i64 - 967).abs() <= 2);
    for (nm, tau, eta, ga, gb, k, l, lam, om, want) in [("44", 39.0, 2.0, 1u64 << 17, 95232.0, 4u64, 4u64, 128u64, 80u64, 4.25),
        ("65", 49.0, 4.0, 1 << 19, 261888.0, 6, 5, 192, 55, 5.1), ("87", 60.0, 2.0, 1 << 19, 261888.0, 8, 7, 256, 75, 3.85)] {
        let reps = (256.0 * tau * eta * (l as f64 / ga as f64 + k as f64 / gb)).exp(); // expected tries before release
        let sig = lam / 4 + l * 32 * (1 + ga.trailing_zeros() as u64) + om + k;
        println!("ML-DSA-{}: public key {} bytes, signature {} bytes, expected tries {:.2}", nm, 32 + 320 * k, sig, reps);
        assert!((reps - want).abs() < 0.01 && (32 + 320 * k, sig) == match nm { "44" => (1312, 2420), "65" => (1952, 3309), _ => (2592, 4627) }); // FIPS 204, Tables 1 and 2
    }
    let (rr, a) = (3233i64, 3i64);
    let r = (1..rr).find(|&r| mpow(a, r, rr) == 1).unwrap(); // the step Shor does on a quantum computer
    let h = mpow(a, r / 2, rr); let (f1, f2) = (gcd(h - 1, rr), gcd(h + 1, rr));
    println!("Shor's idea on RSA modulus {}: period of {} is {}; {}^{} = {}; factors {} x {}", rr, a, r, a, r / 2, h, f1, f2);
    assert!(f1 * f2 == rr && 1 < f1 && f1 < rr);
    println!("period of 2 is {}: 2^390 = {} = -1, no factor", (1..rr).find(|&r| mpow(2, r, rr) == 1).unwrap(), mpow(2, 390, rr));
    println!("ALL CHECKS PASS");
}
