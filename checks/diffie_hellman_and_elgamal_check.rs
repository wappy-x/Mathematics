// Diffie-Hellman and ElGamal -- the same check as the Python twin, in Rust.  No crates.
// TOY SIZES, INSECURE: a 15-bit prime stands in for the 3,072-bit prime of RFC 7919.
use std::collections::HashMap;
const P: u64 = 20123;         // the clock: a prime with P = 2Q + 1
const Q: u64 = (P - 1) / 2;   // 10061, also prime: the order of the group we use
const G: u64 = 4;             // 2 squared; its powers are the Q squares on the clock
const ROOT: u64 = 2;          // a primitive root: its powers reach all P - 1 slots
fn power(b: u64, mut e: u64, p: u64) -> u64 {        // square and multiply
    let (mut out, mut b) = (1, b % p);
    while e > 0 {
        if e & 1 == 1 { out = out * b % p; }
        b = b * b % p; e >>= 1;
    }
    out
}
fn inverse(a: u64, p: u64) -> u64 {                  // extended Euclid
    let (mut t0, mut t1, mut s0, mut s1) = (p as i64, (a % p) as i64, 0i64, 1i64);
    while t1 != 0 {
        let k = t0 / t1;
        (t0, t1) = (t1, t0 - k * t1);
        (s0, s1) = (s1, s0 - k * s1);
    }
    s0.rem_euclid(p as i64) as u64
}
fn is_prime(n: u64) -> bool { n > 1 && (2..=((n as f64).sqrt() as u64)).all(|d| n % d != 0) }
fn is_square(y: u64, p: u64) -> bool { power(y, (p - 1) / 2, p) == 1 }   // Euler's test
fn isqrt1(q: u64) -> u64 { (q as f64).sqrt() as u64 + 1 }
struct Rng(u64);              // SplitMix64, seed 2026: stands in for the laptops' coins
impl Rng {
    fn next(&mut self) -> u64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    }
    fn secret(&mut self, q: u64) -> u64 { self.next() % (q - 1) + 1 }
}
fn brute_log(y: u64, g: u64, p: u64) -> (u64, u64) { // road 1: try every count in turn
    let (mut x, mut t) = (0, 1);
    while t != y { t = t * g % p; x += 1; }
    (x, x)
}
fn bsgs_log(y: u64, q: u64, g: u64, p: u64) -> (u64, u64) { // road 2: about 2 sqrt(q) steps
    let m = isqrt1(q);
    let mut baby = HashMap::new();
    let mut t = 1;
    for j in 0..m { baby.entry(t).or_insert(j); t = t * g % p; }
    let (shift, mut gamma) = (inverse(power(g, m, p), p), y);
    for i in 0..m {
        if let Some(j) = baby.get(&gamma) { return (i * m + j, m + i + 1); }
        gamma = gamma * shift % p;
    }
    panic!("no log found")
}
fn bits(n: u64) -> u32 { 64 - n.leading_zeros() }
fn sq(y: u64) -> &'static str { if is_square(y, P) { "True" } else { "False" } }
fn main() {
    let mut rng = Rng(2026);
    assert!(is_prime(P) && is_prime(Q) && power(G, Q, P) == 1);
    assert!(power(ROOT, Q, P) == P - 1 && power(ROOT, 2, P) != 1);
    println!("group: clock P = {}, order Q = {} (prime), generator G = {}; TOY SIZE, INSECURE", P, Q, G);
    println!("G = {} has order {}: {}^{} = {}; ROOT = {} has order {}: {}^{} = {}", G, Q, G, Q, power(G, Q, P), ROOT, P - 1, ROOT, Q, power(ROOT, Q, P));
    // ---- the exchange over cafe wifi ----
    let (a, b) = (rng.secret(Q), rng.secret(Q));
    let (ca, cb) = (power(G, a, P), power(G, b, P));
    let (key_a, key_b, key_direct) = (power(cb, a, P), power(ca, b, P), power(G, a * b % Q, P));
    println!("laptop 1 keeps a = {}, sends A = {}; laptop 2 keeps b = {}, sends B = {}", a, ca, b, cb);
    println!("laptop 1: B^a = {}; laptop 2: A^b = {}; G^(ab mod Q) = {}", key_a, key_b, key_direct);
    assert!(key_a == key_b && key_b == key_direct && is_square(key_a, P));
    println!("laptop 1's work: a has {} bits, {} of them 1s, so {} squarings and {} multiplications", bits(a), a.count_ones(), bits(a) - 1, a.count_ones() - 1);
    // ---- the listener: two roads to the discrete log ----
    let (x1, n1) = brute_log(ca, G, P);
    let (x2, n2) = bsgs_log(ca, Q, G, P);
    println!("listener, every count in turn: a = {} after {} multiplications", x1, n1);
    let m = isqrt1(Q);
    println!("listener, baby-step giant-step: a = {} = {} x {} + {} after {} steps ({} baby, {} giant)", x2, x2 / m, m, x2 % m, n2, m, n2 - m);
    assert!(x1 == a && x2 == a && n2 <= 2 * isqrt1(Q) && n2 < n1);
    println!("cost:              bits(P)       Q  worst: every count   baby-giant   one run: every count vs baby-giant");
    for p in [2063u64, 20123, 524387, 8389163] {
        let q = (p - 1) / 2;
        let y = power(4, rng.secret(q), p);
        let (xb, nb) = brute_log(y, 4, p);
        let (xg, ng) = bsgs_log(y, q, 4, p);
        assert!(xb == xg && power(4, xg, p) == y && ng <= 2 * isqrt1(q));
        println!("cost, p = {:>7}: {:>9} {:>7} {:>20} {:>12} {:>20} vs {}", p, bits(p), q, q - 1, 2 * isqrt1(q), nb, ng);
    }
    println!("real size, RFC 7919 ffdhe3072: P of 3072 bits, counts of 275+ bits; a 256-bit count takes about 2^{} baby-giant steps", 256 / 2);
    // ---- ElGamal: laptop 2 publishes H = G^x once; laptop 1 sends a PIN with no reply needed ----
    let x = rng.secret(Q);
    let h = power(G, x, P);
    let pin = 4071u64;
    let enc = if is_square(pin, P) { pin } else { P - pin }; // put the PIN inside the group
    assert!(is_square(enc, P));
    let encrypt = |e: u64, r: u64| (power(G, r, P), e * power(h, r, P) % P);
    let decrypt = |c1: u64, c2: u64| {
        let e = c2 * inverse(power(c1, x, P), P) % P;    // road 1: extended Euclid
        let e2 = c2 * power(c1, Q - x, P) % P;           // road 2: c1^(Q-x) undoes c1^x
        assert!(e == e2);
        e.min(P - e)
    };
    let (r1, r2) = (rng.secret(Q), rng.secret(Q));
    let (c, c_again) = (encrypt(enc, r1), encrypt(enc, r2));
    println!("laptop 2: x = {}, publishes H = {}", x, h);
    println!("PIN {} is a square: {}; sent inside the group as {}", pin, sq(pin), enc);
    println!("encrypt with r = {}: (c1, c2) = ({}, {}); mask H^r = {}", r1, c.0, c.1, power(h, r1, P));
    println!("decrypt: c1^x = {}, its inverse {}, PIN = {}", power(c.0, x, P), inverse(power(c.0, x, P), P), decrypt(c.0, c.1));
    println!("same PIN, fresh r = {}: (c1, c2) = ({}, {}), PIN = {}", r2, c_again.0, c_again.1, decrypt(c_again.0, c_again.1));
    assert!(decrypt(c.0, c.1) == pin && decrypt(c_again.0, c_again.1) == pin && c != c_again && power(h, r1, P) == power(c.0, x, P));
    // ---- what breaks ----
    let pin2 = 9306u64;
    let enc2 = if is_square(pin2, P) { pin2 } else { P - pin2 };
    let d = encrypt(enc2, r1);                            // the same r used twice
    let leak = c.1 * inverse(d.1, P) % P;
    let guess = enc * inverse(leak, P) % P;
    println!("break, reuse r: second PIN {}; c2/c2' = {}; knowing the first PIN gives {}", pin2, leak, guess.min(P - guess));
    assert!(guess.min(P - guess) == pin2);
    let bad = P - 1;                                      // a forged B of order 2
    let mut vals: Vec<u64> = Vec::new();
    for t in 1..5 { let v = power(bad, t, P); if !vals.contains(&v) { vals.push(v); } }
    println!("break, unchecked B = {}: shared key B^a = {}, one of only {} values", bad, power(bad, a, P), vals.len());
    assert!(power(bad, a, P) == (if a % 2 == 0 { 1 } else { P - 1 }) && vals.len() == 2 && !is_square(bad, P));
    let wrong = power(G, a * b % P, P);
    println!("break, exponent reduced mod P not mod Q: {} instead of {}", wrong, key_a);
    assert!(wrong != key_a);
    let raw = pin2;                                       // skip the encoding step
    let cr = encrypt(raw, r2);
    println!("break, raw PIN {} outside the group: c2 is a square: {}, so the PIN is not", raw, sq(cr.1));
    assert!(!is_square(cr.1, P) && !is_square(raw, P));
    // ---- the parity leak: a DDH guessing game, 4000 rounds each ----
    let mut ddh_game = |g: u64, q: u64| {               // q: the size of the group g generates
        let mut wins = 0u32;
        for _ in 0..4000 {
            let (u, v, w) = (rng.secret(q), rng.secret(q), rng.secret(q));
            let real = rng.next() % 2 == 1;
            let z = if real { power(g, u * v, P) } else { power(g, w, P) };
            let predicted = is_square(power(g, u, P), P) || is_square(power(g, v, P), P);
            let says_real = is_square(z, P) == predicted;
            if says_real == real { wins += 1; }
        }
        wins as f64 / 4000.0
    };
    let (win_root, win_sub) = (ddh_game(ROOT, P - 1), ddh_game(G, Q));
    println!("break, DDH game with generator {} (all {} slots), 4000 rounds: guesser wins {:.4}; theory 0.75", ROOT, P - 1, win_root);
    println!("DDH game with generator {} (the {} squares), 4000 rounds: guesser wins {:.4}; theory 0.50", G, Q, win_sub);
    assert!((win_root - 0.75).abs() < 0.03 && (win_sub - 0.5).abs() < 0.03);
    println!("ALL CHECKS PASS");
}
