// Computing on secrets -- the same check as the Python, in Rust.  No crates.
// Additive shares mod 2^32, one Beaver-triple multiplication, toy Paillier (n = 77)
// and a toy integer FHE.  TOY SIZES, INSECURE: real Paillier uses n of 3072 bits
// (ISO/IEC 18033-6); real FHE uses lattice (LWE) schemes with far larger keys.
const M: u128 = 1 << 32;

struct SplitMix64 { s: u64 }                       // seeded generator, same in Python
impl SplitMix64 {
    fn next(&mut self) -> u128 {
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        (z ^ (z >> 31)) as u128
    }
}
fn power(b: u128, mut e: u128, m: u128) -> u128 {  // square-and-multiply, written out
    let (mut out, mut b) = (1u128, b % m);
    while e > 0 {
        if e & 1 == 1 { out = out * b % m }
        b = b * b % m;
        e >>= 1;
    }
    out
}
fn gcd(mut a: u128, mut b: u128) -> u128 { while b > 0 { let t = a % b; a = b; b = t; } a }
fn inverse(a: u128, m: u128) -> u128 {              // extended Euclid: a * inverse = 1 mod m
    let (mut r0, mut r1, mut t0, mut t1) = (m as i128, (a % m) as i128, 0i128, 1i128);
    while r1 != 0 {
        let k = r0 / r1;
        (r0, r1, t0, t1) = (r1, r0 - k * r1, t1, t0 - k * t1);
    }
    t0.rem_euclid(m as i128) as u128
}
fn share(rng: &mut SplitMix64, x: u128) -> Vec<u128> { // three random shares adding to x mod 2^32
    let (s1, s2) = (rng.next() % M, rng.next() % M);
    vec![s1, s2, (x + 2 * M - s1 - s2) % M]
}
fn pounds(p: u128) -> String {
    let (w, mut s) = ((p / 100).to_string(), String::new());
    for (i, ch) in w.chars().enumerate() {
        if i > 0 && (w.len() - i) % 3 == 0 { s.push(',') }
        s.push(ch);
    }
    format!("£{}.{:02}", s, p % 100)
}
fn yn(t: bool) -> &'static str { if t { "yes" } else { "no" } }

fn main() {
    let mut rng = SplitMix64 { s: 2026 };
    // ---- 1. the sum: three branches, takings in pence, shares mod 2^32 ----
    let names = ["Leeds", "York", "Hull"];
    let takings: [u128; 3] = [184250, 231675, 150920];
    let sh: Vec<Vec<u128>> = takings.iter().map(|&t| share(&mut rng, t)).collect();
    for i in 0..3 { println!("{} takes {} = {} p; shares {:?}", names[i], pounds(takings[i]), takings[i], sh[i]) }
    let held: Vec<u128> = (0..3).map(|j| (0..3).map(|i| sh[i][j]).sum::<u128>() % M).collect();
    let (total, direct) = (held.iter().sum::<u128>() % M, takings.iter().sum::<u128>());
    println!("each branch adds what it holds: {:?}", held);
    println!("published sums added mod 2^32 = {} p = {}; direct sum {}; Leeds infers York + Hull = {} p; ceiling 2^32 p = {}",
             total, pounds(total), direct, total - takings[0], pounds(M));
    let mut cnt = vec![0u32; 8 * 3 * 64];                // privacy, modulus 8, every coin
    for t in 0..8 { for s1 in 0..8 { for s2 in 0..8 {
        let v = [s1, s2, (t + 16 - s1 - s2) % 8];
        for (k, (i, j)) in [(0, 1), (0, 2), (1, 2)].iter().enumerate() { cnt[(t * 3 + k) * 64 + v[*i] * 8 + v[*j]] += 1 }
    } } }
    let uniform = cnt.iter().all(|&c| c == 1);
    println!("privacy, modulus 8: any two of three shares take all 64 value pairs once each, for all 8 inputs: {}", yn(uniform));
    let (w1, w2) = (rng.next() % 10000, rng.next() % 10000); let leak = takings[0] - w1 - w2;   // break 1: narrow shares, no wrap
    println!("break 1, shares 0..9,999 p with no wrap: Hull holds {} p, so Leeds took {} to {}", leak, pounds(leak), pounds(leak + 19998));
    // ---- 2. one product with a Beaver triple ----
    let (x, y) = (120u128, 1840u128);              // sacks of flour (Hull), pence per sack (York)
    let (a0, b0, c0, d0, e0) = (100u128, 1000u128, 100000u128, x - 100, y - 1000);   // a small triple, by hand
    let hand = c0 + d0 * b0 + e0 * a0 + d0 * e0;
    println!("by hand: a = {}, b = {}, c = {}; d = {}, e = {}; c + d b + e a + d e = {} + {} + {} + {} = {}",
             a0, b0, c0, d0, e0, c0, d0 * b0, e0 * a0, d0 * e0, hand);
    let (a, b) = (rng.next() % M, rng.next() % M);
    let c = a * b % M;
    let (xs, ys, as_, bs, cs) = (share(&mut rng, x), share(&mut rng, y), share(&mut rng, a), share(&mut rng, b), share(&mut rng, c));
    let d = (0..3).map(|i| xs[i] + M - as_[i]).sum::<u128>() % M;   // opened in public
    let e = (0..3).map(|i| ys[i] + M - bs[i]).sum::<u128>() % M;
    let z: Vec<u128> = (0..3).map(|i| (cs[i] + d * bs[i] + e * as_[i] + if i == 0 { d * e } else { 0 }) % M).collect();
    let prod_xy = z.iter().sum::<u128>() % M;
    println!("triple: a = {}, b = {}, c = ab mod 2^32 = {}", a, b, c);
    println!("opened: d = x - a = {}, e = y - b = {} (mod 2^32)", d, e);
    println!("product shares {:?}; sum mod 2^32 = {} p = {}; direct {} * {} = {}", z, prod_xy, pounds(prod_xy), x, y, x * y);
    let mut ident = true;
    for xx in 0..16u128 { for yy in 0..16u128 { for aa in 0..16u128 { for bb in 0..16u128 {
        let (dd, ee) = ((xx + 16 - aa) % 16, (yy + 16 - bb) % 16);
        if (aa * bb + dd * bb + ee * aa + dd * ee) % 16 != xx * yy % 16 { ident = false }
    } } } }
    let dun = (0..16u128).all(|xx| { let mut seen = [false; 16]; for aa in 0..16u128 { seen[((xx + 16 - aa) % 16) as usize] = true } seen.iter().all(|&s| s) });
    println!("identity mod 16, all 65536 (x, y, a, b): {}; d takes all 16 values for every x: {}", yn(ident), yn(dun));
    let (x2, d2) = (95u128, (95 + M - a) % M);    // break 2: the same triple reused
    println!("break 2, triple reused for x' = {}: d - d' = {} = x - x', leaked", x2, (d + M - d2) % M);
    // ---- 3. toy Paillier, n = 7 * 11 = 77 ----
    let (p, q) = (7u128, 11u128);
    let (n, n2, g, lam) = (p * q, p * q * p * q, p * q + 1, (p - 1) * (q - 1) / gcd(p - 1, q - 1));
    let l = |u: u128| (u - 1) / n;
    let mu = inverse(l(power(g, lam, n2)), n);
    let enc = |m: u128, r: u128| power(g, m, n2) * power(r, n, n2) % n2;
    let dec = |ct: u128| l(power(ct, lam, n2)) * mu % n;
    println!("Paillier: n = {}, n^2 = {}, g = {}, lambda = {}, mu = {}; real n 3072 bits (about 2^128 work), ciphertexts {} bits", n, n2, g, lam, mu, 2 * 3072);
    let (ms, rs) = ([18u128, 23, 15], [5u128, 13, 20]);   // takings in hundreds of pounds, rounded
    let cts: Vec<u128> = (0..3).map(|i| enc(ms[i], rs[i])).collect();
    for i in 0..3 {
        println!("  {}: m = {}, r = {}: g^m = {}, r^n = {}, Enc = {}, decrypts to {}", names[i], ms[i], rs[i],
                 power(g, ms[i], n2), power(rs[i], n, n2), cts[i], dec(cts[i]));
    }
    let prod = cts[0] * cts[1] % n2 * cts[2] % n2;
    let msum: u128 = ms.iter().sum();
    println!("product of ciphertexts mod n^2 = {}; to the lambda mod n^2 = {}, L = {}, times mu mod n = {}; sum {}",
             prod, power(prod, lam, n2), l(power(prod, lam, n2)), dec(prod), msum);
    let binom = (0..n).all(|m| power(g, m, n2) == (1 + m * n) % n2);
    let mut table: Vec<Option<u128>> = vec![None; n2 as usize];
    let mut pairs = 0u128;
    for m in 0..n { for r in 1..n { if gcd(r, n) == 1 { table[enc(m, r) as usize] = Some(m); pairs += 1 } } }
    let distinct = table.iter().filter(|t| t.is_some()).count() as u128;
    let units = (1..n2).filter(|&u| gcd(u, n2) == 1).count() as u128;
    let look = (0..n2).all(|ct| match table[ct as usize] { Some(m) => dec(ct) == m, None => true });
    let hom = (0..n).all(|m1| (0..n).all(|m2| dec(enc(m1, 5) * enc(m2, 13) % n2) == (m1 + m2) % n));
    let mut seen18 = vec![false; n2 as usize];
    for r in 1..n { if gcd(r, n) == 1 { seen18[enc(18, r) as usize] = true } }
    let same = seen18.iter().filter(|&&s| s).count();
    println!("(1 + n)^m = 1 + mn mod n^2 for all 77 m: {}; {} (m, r) pairs give {} distinct ciphertexts = {} units mod n^2",
             yn(binom), pairs, distinct, units);
    println!("lookup agrees with decryption: {}; Dec(Enc(m1) Enc(m2)) = m1 + m2 mod n for all 5929 pairs: {}; 18 encrypts {} ways",
             yn(look), yn(hom), same);
    let c1 = enc(18, 1);                           // break 3: r = 1, no randomness
    println!("break 3, r = 1: Enc(18) = {}; anyone computes ({} - 1)/{} = {}", c1, c1, n, (c1 - 1) / n);
    let week = power(prod, 7, n2);                 // break 4: past n the sum wraps
    println!("break 4, a week, Enc(56)^7: decrypts to {}, not {}", dec(week), 7 * msum);
    let f = (2..n).find(|k| n % k == 0).unwrap();
    let lam2 = (f - 1) * (n / f - 1) / gcd(f - 1, n / f - 1);
    let crack = (power(prod, lam2, n2) - 1) / n * inverse(lam2, n) % n;
    println!("break 5, trial division splits 77 = {} * {} after {} tries; total read without the key: {}", f, n / f, f - 1, crack);
    // ---- 4. toy FHE over the integers: secret odd K, noise grows ----
    let (kk, u0, xm) = (1000003u128, 4294967311u128, 1000003u128 * 4294967311);   // xm: public multiple of K
    let mut fenc = |bit: i128| -> (u128, i128) {
        let nu = 2 * ((rng.next() % 9) as i128 - 4) + bit;   // noise: small, with the bit as its parity
        ((kk * (rng.next() % u0) + xm).wrapping_add_signed(nu) % xm, nu)
    };
    let fdec = |ct: u128| -> i128 { let v = (ct % kk) as i128; (if v > (kk / 2) as i128 { v - kk as i128 } else { v }).rem_euclid(2) };
    let ((e1, v1), (e2, v2)) = (fenc(1), fenc(0));
    println!("FHE toy: K = {}, X = K * {}; Enc(1) noise {}, Enc(0) noise {}; add -> {} (1 XOR 0), multiply -> {} (1 AND 0)",
             kk, u0, v1, v2, fdec((e1 + e2) % xm), fdec(e1 * e2 % xm));
    let (mut tot, mut nz, mut par) = (0u128, 0i128, 0i128);
    for _ in 0..1000 { let (ct, nu) = fenc(1); tot = (tot + ct) % xm; nz += nu; par ^= 1; }
    println!("1000 additions of Enc(1): noise {}, decrypts to {}, true XOR {}", nz, fdec(tot), par);
    let (mut acc, mut noise, mut bits) = (e1, vec![v1], Vec::new());
    while bits.len() < 14 {                        // multiply by fresh Enc(1), 14 times
        let (ct, nu) = fenc(1);
        acc = acc * ct % xm;
        noise.push(noise[noise.len() - 1] * nu);
        bits.push(fdec(acc));
    }
    let first = (0..noise.len()).find(|&k| noise[k].unsigned_abs() > kk / 2).unwrap();
    let lg: Vec<String> = noise.iter().map(|v| format!("{:.1}", (v.unsigned_abs() as f64).log2())).collect();
    println!("chain of multiplications by Enc(1), noise after each: {:?}", noise);
    println!("chart, log2 |noise| after 0..14 multiplications: [{}]; limit log2(K/2) = {:.1}", lg.join(", "), ((kk / 2) as f64).log2());
    println!("decrypted bit after each (true value 1): {:?}; noise passes K/2 = {} at multiplication {}", bits, kk / 2, first);
    assert!(total == direct && direct == 566845 && uniform);              // sum, two roads
    assert!(leak == (takings[0] + 2 * M - w1 - w2) % M && leak <= takings[0] && takings[0] <= leak + 19998);   // break 1: Hull's share by share()'s rule
    assert!(hand == prod_xy && prod_xy == x * y && ident && (d + M - d2) % M == x - x2);
    assert!(mu * lam % n == 1 && dec(prod) == msum && msum == 56 && binom && look && hom);
    assert!(distinct == units && units == 4620 && pairs == 4620 && same == 60 && (c1 - 1) / n == 18);
    assert!(dec(week) == 7 * msum % n && crack == 56 && f == p);
    assert!(fdec((e1 + e2) % xm) == 1 && fdec(e1 * e2 % xm) == 0 && fdec(tot) == par);
    assert!((1..first).all(|k| bits[k - 1] == 1) && bits[first - 1..].contains(&0));
    println!("ALL CHECKS PASS");
}
