// Quantum advantage -- the same check as the Python, in Rust.  No crates.
// Part 1: what a hardware run on 15 really needs, and "factoring" by coin flip.
// Part 2: random circuits on 12 qubits and the cross-entropy test (XEB).
// Part 3: the 2019 claim and the 2022 classical answer, in numbers.
#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }                        // a small complex number
fn c(re: f64, im: f64) -> C { C { re, im } }
fn mul(a: C, b: C) -> C { c(a.re * b.re - a.im * b.im, a.re * b.im + a.im * b.re) }
fn add(a: C, b: C) -> C { c(a.re + b.re, a.im + b.im) }

fn gcd(mut a: u128, mut b: u128) -> u128 {           // Euclid's algorithm, written out
    while b != 0 { let t = a % b; a = b; b = t; }
    a
}
fn powmod(a: u128, mut e: u128, n: u128) -> u128 {   // square and multiply, wrapped at n
    let (mut r, mut a) = (1u128, a % n);
    while e > 0 {
        if e & 1 == 1 { r = r * a % n; }
        a = a * a % n;
        e >>= 1;
    }
    r
}
fn order(a: u128, n: u128) -> u128 {                 // multiply until the powers return to 1
    let (mut r, mut x) = (1u128, a % n);
    while x != 1 { x = x * a % n; r += 1; }
    r
}
fn tot(xs: &[f64]) -> f64 { let mut acc = 0.0; for x in xs { acc += x; } acc }
fn is_prime(m: u128) -> bool {                       // trial division, an independent road
    let mut d = 3u128;
    while d * d <= m { if m % d == 0 { return false; } d += 2; }
    m == 2 || (m > 2 && m % 2 == 1)
}
struct Rng(u64);
impl Rng {                                           // SplitMix64, the same stream as the Python
    fn next(&mut self) -> u64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    }
    fn unif(&mut self) -> f64 { (self.next() >> 11) as f64 / 9007199254740992.0 }
}

fn main() {
    println!("Part 1: Shor's circuit for N = 15, base by base");
    let mut good = 0;
    for a in (2..15u128).filter(|&b| gcd(b, 15) == 1) {
        let r = order(a, 15);
        let bits = 127 - r.leading_zeros();            // the oracle needs only the last log2(r) bits of x
        assert!((0..256u128).all(|x| powmod(a, x, 15) == powmod(a, x % r, 15)));
        let h = powmod(a, r / 2, 15);
        let (g1, g2) = (gcd(h - 1, 15), gcd(h + 1, 15));
        if g1 != 1 && g1 != 15 { good += 1; }
        println!("  a = {:2}: period {}, oracle uses the last {} bit(s) of x, gcds {} and {}{}", a, r, bits, g1, g2,
                 if g1 == 1 { "  (fails)" } else { "" });
    }
    let t = 128 - (15u128 * 15 - 1).leading_zeros();
    println!("textbook circuit: {} counting + 4 work = {} qubits; bases that split 15: {} of 7", t, t + 4, good);
    println!("quoted runs on 15: 2001 NMR, 7 qubits; 2016 ion trap, 7 qubits + 4 cache, success over 90%");
    let (p, q) = (2147483647u128, 4294967291u128);  // the answer, known before the run
    let n = p * q;
    let a = 1 + p * ((q - 2) * powmod(p, q - 2, q) % q); // a = 1 mod p and a = -1 mod q: built from the answer
    let s = 1.0 / 2f64.sqrt();
    let mut v = [s, 0.0, s, 0.0];                    // index 2c + w; H on the counting qubit c
    v.swap(2, 3);                                    // c = 1 multiplies by a: work bit w goes 1 -> a
    v = [s * (v[0] + v[2]), s * (v[1] + v[3]), s * (v[0] - v[2]), s * (v[1] - v[3])];
    let pc = [v[0] * v[0] + v[1] * v[1], v[2] * v[2] + v[3] * v[3]];
    let (g1, g2) = (gcd(a - 1, n), gcd(a + 1, n));
    println!("pretend run, 2 qubits: N = {}, a = {}, a^2 mod N = {}", n, a, powmod(a, 2, n));
    println!("  counting qubit reads 0 with chance {:.4}, 1 with chance {:.4}: a fair coin", pc[0], pc[1]);
    println!("  reading 1 gives 1/2, period 2: gcd(a - 1, N) = {}, gcd(a + 1, N) = {}, both prime by trial division: {}", g1, g2,
             if is_prime(g1) && is_prime(g2) { "yes" } else { "no" });
    assert!(powmod(a, 2, n) == 1 && a != 1 && a != n - 1 && g1 * g2 == n && is_prime(g1) && is_prime(g2));

    let mut rng = Rng(20191023);
    let (nq, dd, cyc_n) = (12usize, 1usize << 12, 12usize); // 12 qubits on a 3 by 4 grid, 12 cycles
    let g: [[C; 4]; 3] = [[c(0.5, 0.5), c(0.5, -0.5), c(0.5, -0.5), c(0.5, 0.5)],     // square root of X
                          [c(0.5, 0.5), c(-0.5, -0.5), c(0.5, 0.5), c(0.5, 0.5)],     // square root of Y
                          [c(s, 0.0), c(-0.5, -0.5), c(0.5, -0.5), c(s, 0.0)]];       // square root of W
    let mut pairs: Vec<Vec<(usize, usize)>> = vec![vec![]; 4];
    for r in 0..3 { pairs[0].push((4 * r, 4 * r + 1)); }
    for r in 0..3 { pairs[0].push((4 * r + 2, 4 * r + 3)); }
    for r in 0..3 { pairs[1].push((4 * r + 1, 4 * r + 2)); }
    for col in 0..4 { pairs[2].push((col, 4 + col)); pairs[3].push((4 + col, 8 + col)); }
    let (mut amp, mut prev, mut e) = (vec![c(0.0, 0.0); dd], vec![3u64; nq], vec![]);
    amp[0] = c(1.0, 0.0);
    let mut pr = vec![0.0; dd];
    for cyc in 0..cyc_n {
        for k in 0..nq {
            let gi = if prev[k] == 3 { rng.next() % 3 } else { (prev[k] + 1 + rng.next() % 2) % 3 };
            prev[k] = gi;
            let (m, b) = (g[gi as usize], 1usize << k);
            for i in 0..dd {
                if i & b == 0 {
                    let (x, y) = (amp[i], amp[i | b]);
                    amp[i] = add(mul(m[0], x), mul(m[1], y));
                    amp[i | b] = add(mul(m[2], x), mul(m[3], y));
                }
            }
        }
        for &(j, k) in &pairs[cyc % 4] {             // controlled-Z: flip the sign when both qubits are 1
            for i in 0..dd { if (i >> j) & 1 == 1 && (i >> k) & 1 == 1 { amp[i] = c(-amp[i].re, -amp[i].im); } }
        }
        pr = amp.iter().map(|z| z.re * z.re + z.im * z.im).collect();
        let sq: Vec<f64> = pr.iter().map(|x| x * x).collect();
        e.push((dd as f64 * tot(&sq) - 1.0).max(0.0)); // XEB a perfect device scores: 2^n sum p^2 - 1
    }
    println!("Part 2: random circuit, {} qubits, {} cycles; total probability {:.4}", nq, cyc_n, tot(&pr));
    let es: Vec<String> = e.iter().map(|x| format!("{:.2}", x)).collect();
    println!("  exact XEB of a perfect device after each cycle: {}", es.join(", "));
    let mut cdf = Vec::with_capacity(dd);
    let mut acc = 0.0;
    for x in &pr { acc += x; cdf.push(acc); }
    let kk = 20000usize;
    let mut res = std::collections::HashMap::new();
    for (name, f) in [("perfect device", 1.0), ("noisy device, f = 0.05", 0.05), ("uniform guesser", 0.0), ("noisy device, f = 0.002", 0.002)] {
        let mut vals = Vec::with_capacity(kk);
        for _ in 0..kk {                             // right with chance f, else a uniform random string
            let x = if rng.unif() < f { let u = rng.unif(); cdf.partition_point(|&cv| cv <= u).min(dd - 1) }
                    else { (rng.next() % dd as u64) as usize };
            vals.push(dd as f64 * pr[x]);
        }
        let mu = tot(&vals) / kk as f64;
        let dev: Vec<f64> = vals.iter().map(|y| (y - mu) * (y - mu)).collect();
        let se = (tot(&dev) / (kk - 1) as f64 / kk as f64).sqrt();
        println!("  {}, {} samples: XEB {:.4}, standard error {:.4}, expected {:.4}", name, kk, mu - 1.0, se, f * e[cyc_n - 1]);
        res.insert(name, (f, mu - 1.0, se));
    }
    let share = pr.iter().filter(|&&x| dd as f64 * x > 1.0).count() as f64 / dd as f64;
    println!("  share of strings with 2^n p > 1: {:.4}; Porter-Thomas predicts exp(-1) = {:.4}", share, (-1f64).exp());
    for name in ["perfect device", "noisy device, f = 0.05", "uniform guesser"] {
        let (f, x, se) = res[name];
        assert!((x - f * e[cyc_n - 1]).abs() < 5.0 * se);  // sampled XEB against the exact sum
    }
    assert!((share - (-1f64).exp()).abs() < 0.03);
    assert!(e[0] < 1e-9 && 1e-9 < e[1]);
    assert!((tot(&pr) - 1.0).abs() < 1e-9);

    let yr = 365.25 * 86400.0;
    let (claim, chip, gpu) = (10000.0 * yr, 200.0f64, 15u64 * 3600);
    println!("Part 3: the 2019 claim, 53 qubits, 20 cycles, a million samples");
    println!("  2^53 = {} amplitudes; at 8 bytes each {} bytes", 1u64 << 53, 8u64 << 53);
    println!("  claimed classical time / chip time: {:.0}; 2022 run, 512 GPUs: {} s, {:.0} times the chip", claim / chip, gpu, gpu as f64 / chip);
    for (lab, sec) in [("claim 2019, 10000 years", claim), ("classical 2022, 15 hours", gpu as f64), ("chip 2019, 200 seconds", chip)] {
        println!("  {:25} {:24} log10 s = {:.2}", lab, "#".repeat((2.0 * sec.log10()).round() as usize), sec.log10());
    }
    let se = 1.0 / 30e6f64.sqrt();
    println!("  XEB 0.00224 from 30000000 samples: standard error {:.6}, {:.1} errors above 0", se, 0.00224 / se);
    println!("  samples to see f = 0.002 at 5 errors: (5/0.002)^2 = {:.0}", (5.0 / 0.002) * (5.0 / 0.002));
    println!("  later claims, quoted: 2020 photons, up to 76 clicks, 1e14 times; 2024 sampling, 67 qubits, 32 cycles; 2025 sampling, 83 qubits, 32 cycles, 6.4e9 years");
    println!("  2025 claim, 65 qubits: 3.2 years / 2.1 hours = {:.0}; 2^65 amplitudes at 8 bytes = {} bytes", 3.2 * yr / (2.1 * 3600.0), 8u128 << 65);
    println!("ALL CHECKS PASS");
}
