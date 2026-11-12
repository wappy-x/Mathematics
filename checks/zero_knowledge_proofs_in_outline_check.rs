// Zero-knowledge in outline -- the same check as the Python, in Rust.  No crates.
// Schnorr's proof that the laptop knows x with y = g^x mod p, in a TOY group:
// p = 23, q = 11, g = 4.  INSECURE: real proofs use a q of 256 bits (RFC 8235).
// The hash is FNV-1a, also a toy; real Fiat-Shamir uses SHA-256 or better.
const P: u64 = 23;
const Q: u64 = 11;
const G: u64 = 4;

fn power(b: u64, mut e: u64, m: u64) -> u64 {      // square-and-multiply, written out
    let (mut out, mut b) = (1u64, b % m);
    while e > 0 {
        if e & 1 == 1 { out = out * b % m }
        b = b * b % m;
        e >>= 1;
    }
    out
}

fn fnv(text: &str) -> u64 {                        // FNV-1a, 64 bits: a toy hash, NOT secure
    let mut h: u64 = 0xCBF29CE484222325;
    for ch in text.bytes() { h = (h ^ ch as u64).wrapping_mul(0x100000001B3) }
    h
}

struct SplitMix64 { s: u64 }                       // seeded generator, same in Python
impl SplitMix64 {
    fn next(&mut self) -> u64 {
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    }
}

fn verify(y: u64, t: u64, c: u64, s: u64) -> bool {   // the bank's one test: g^s = t * y^c
    power(G, s, P) == t * power(y, c, P) % P
}

fn fake_t(y: u64, c: u64, s: u64) -> u64 {         // t made backwards: g^s * y^(-c)
    power(G, s, P) * power(y, Q - c, P) % P
}

fn fs(y: u64, t: u64, msg: &str) -> u64 {           // Fiat-Shamir challenge from the hash
    fnv(&format!("{}|{}|{}|{}", G, y, t, msg)) % Q
}

fn fs_weak(_y: u64, t: u64, _msg: &str) -> u64 {    // a flawed challenge: hashes t only, ignores msg
    fnv(&format!("{}", t)) % Q
}

fn accepts(y: u64, t: u64, s: u64, msg: &str, ch: fn(u64, u64, &str) -> u64) -> bool { // check a proof (t, s) for msg
    verify(y, t, ch(y, t, msg), s)
}

fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }

fn main() {
    assert!(fnv("a") == 0xAF63DC4C8601EC8C);           // FNV-1a's published 64-bit test value
    println!("FNV-1a test vector: fnv('a') = {:016x}, matches", fnv("a"));
    // ---- the example: a password becomes x; the bank keeps only y ----
    let pw = "blue-kettle-17";
    let x = 1 + fnv(pw) % (Q - 1);
    let y = power(G, x, P);
    let pows: Vec<u64> = (0..Q).map(|k| power(G, k, P)).collect();
    println!("group: p = {}, q = {}, g = {}; powers of g: {:?}", P, Q, G, pows);
    println!("password '{}' -> secret x = {}; bank stores y = g^x mod p = {}", pw, x, y);
    let (r, c) = (5u64, 3u64);
    let (t, s) = (power(G, r, P), (r + c * x) % Q);
    println!("one round: r = {}, t = g^r = {}; challenge c = {}; s = r + c*x = {} -> mod q {}",
             r, t, c, r + c * x, s);
    println!("check: g^s = {}, t * y^c = {} * {} mod p = {} -> accept: {}", power(G, s, P), t,
             power(y, c, P), t * power(y, c, P) % P, yn(verify(y, t, c, s)));
    let mut ok = 0u64;
    for a in 0..Q { for b in 0..Q { if verify(y, power(G, a, P), b, (a + b * x) % Q) { ok += 1 } } }
    println!("completeness: {} of {} (r, c) pairs accepted", ok, Q * Q);
    // ---- soundness: two answers to one t give x away ----
    let c2 = 8u64;
    let s2 = (r + c2 * x) % Q;
    let (ds, inv) = ((s + Q - s2) % Q, power((c + Q - c2) % Q, Q - 2, Q));   // inverse by Fermat
    let xx = ds * inv % Q;
    println!("extraction: same t, c = {} and {} give s = {} and {}; x = ({} - {}) / ({} - {}) = {} * {} mod {} = {}",
             c, c2, s, s2, s, s2, c, c2, ds, inv, Q, xx);
    let mut wins = 0u64;
    for g_ in 0..Q { for s_ in 0..Q { for c_ in 0..Q {
        if verify(y, fake_t(y, g_, s_), c_, s_) { wins += 1 }
    } } }
    println!("cheater without x, exact: {} of {} (guess, s, c) cases pass = {:.4}; 1/q = {:.4}",
             wins, Q * Q * Q, wins as f64 / (Q * Q * Q) as f64, 1.0 / Q as f64);
    let (mut rng, n, mut hits) = (SplitMix64 { s: 2026 }, 100000u64, 0u64);
    for _ in 0..n {
        let (g_, s_, c_) = (rng.next() % Q, rng.next() % Q, rng.next() % Q);
        if verify(y, fake_t(y, g_, s_), c_, s_) { hits += 1 }
    }
    let pq = 1.0 / Q as f64;
    let (rate, se) = (hits as f64 / n as f64, (pq * (1.0 - pq) / n as f64).sqrt());
    println!("cheater, simulated over {} rounds (seed 2026): {:.4}, standard error {:.4}", n, rate, se);
    let mut rounds = 1u32;
    while Q.pow(rounds) < 1_000_000 { rounds += 1 }
    println!("rounds for under 1 in a million: {} ({}^{} = {})", rounds, Q, rounds, Q.pow(rounds));
    println!("real sizes: q of 256 bits, p of 3072 bits; cheater 2^-256 per round; \
              finding x from y about 2^128 operations");
    // ---- zero knowledge: a simulator that never sees x ----
    let mut real: Vec<(u64, u64, u64)> = Vec::new();
    let mut sim: Vec<(u64, u64, u64)> = Vec::new();
    for a in 0..Q { for b in 0..Q { real.push((power(G, a, P), b, (a + b * x) % Q)) } }
    for s_ in 0..Q { for b in 0..Q { sim.push((fake_t(y, b, s_), b, s_)) } }
    real.sort();
    sim.sort();
    let mut uniq = real.clone();
    uniq.dedup();
    println!("simulator: {} real transcripts, {} simulated; same list: {}; all distinct: {}",
             real.len(), sim.len(), yn(real == sim), yn(uniq.len() == real.len()));
    // ---- Fiat-Shamir: the hash plays the bank ----
    let (msg, r3) = ("login 2026-11-11 session 41", 9u64);
    let t3 = power(G, r3, P);
    let c3 = fs(y, t3, msg);
    let s3 = (r3 + c3 * x) % Q;
    println!("Fiat-Shamir: msg '{}', r = {}, t = {}, c = h(g|y|t|msg) mod q = {}, s = {}; verifies: {}",
             msg, r3, t3, c3, s3, yn(verify(y, t3, fs(y, t3, msg), s3)));
    // ---- what breaks ----
    let (mut tries, mut rng, mut forged, mut distinct) = (0u64, SplitMix64 { s: 7 }, 0u64, Vec::new());
    while forged < 1000 && tries < 100000 {      // 1000 successful forgeries, by trial and error
        tries += 1;
        let (g_, s_) = (rng.next() % Q, rng.next() % Q);
        let t_ = fake_t(y, g_, s_);
        if fs(y, t_, msg) == g_ && verify(y, t_, fs(y, t_, msg), s_) {
            forged += 1;
            if !distinct.contains(&(t_, s_)) { distinct.push((t_, s_)) }
        }
    }
    let each = tries as f64 / forged.max(1) as f64;
    println!("break 1, toy q: forger without x grinds the hash: {} valid proofs ({} distinct), {:.2} tries each; q = {}",
             forged, distinct.len(), each, Q);
    let msg2 = "login 2026-11-12 session 42";
    let s4 = (r3 + fs_weak(y, t3, msg) * x) % Q;    // a proof for msg under the flawed hash
    let replay = accepts(y, t3, s4, msg2, fs_weak); // the same proof, checked for msg2
    println!("break 2, hash of t only: copied proof replayed on '{}' accepted: {}; with msg hashed: {}",
             msg2, yn(replay), yn(accepts(y, t3, s3, msg2, fs)));
    println!("break 3, r reused for c = {} and {}: x = {} (same as extraction)", c, c2, xx);
    let early = (0..Q).filter(|&b| verify(y, fake_t(y, b, 0), b, 0)).count() as u64;
    println!("break 4, challenge known before t: cheater passes {} of {}", early, Q);
    let dl = (0..Q).find(|&k| power(G, k, P) == y).unwrap();
    println!("break 5, toy group: brute force finds x = {} from y = {} in {} tries", dl, y, dl + 1);
    assert!(ok == Q * Q && verify(y, t, c, s));                       // completeness
    assert!(xx == x && dl == x);                                      // two roads to x
    assert!(wins * Q == Q * Q * Q && (rate - pq).abs() < 4.0 * se);   // exact, formula, simulated
    assert!(real == sim && uniq.len() as u64 == Q * Q);               // simulator matches
    assert!(verify(y, t3, c3, s3) && !verify(y, t3, fs(y, t3, msg2), s3));
    assert!(replay && early == Q && (each - Q as f64).abs() < 1.5 && distinct.len() as u64 <= Q); // breaks 1, 2, 4
    println!("ALL CHECKS PASS");
}
