// Erdos-Kac -- the same check as the Python, in Rust.  No crates.
// omega(n), the number of distinct primes dividing n, is built for every n up
// to a million as a literal sum of prime indicators: each prime adds 1 to each
// of its multiples.  Roads: the sieve's histogram against prime powers (the sum
// of floor(N/p) only checks the sieve's ranges); the low primes' histogram
// against an independent-indicator model; the limit law simulated with a
// SplitMix64 generator against exact Poisson sums and the bell Phi.
const N: usize = 1_000_000; const Y: usize = 100; const D: usize = 20_000; const SEED: u64 = 2026;
fn com(n: u64) -> String {
    let (s, mut out) = (n.to_string(), String::new());
    for (i, ch) in s.chars().enumerate() {
        if i > 0 && (s.len() - i) % 3 == 0 { out.push(','); }
        out.push(ch);
    }
    out
}
fn ser(z: f64) -> f64 {                          // Taylor series of the bell's area
    let (mut t, mut s, mut k) = (z, z, 0.0);
    while t.abs() > 1e-17 {
        k += 1.0;
        t *= -z * z * (2.0 * k - 1.0) / (2.0 * k * (2.0 * k + 1.0));
        s += t;
    }
    0.5 + s / (2.0 * std::f64::consts::PI).sqrt()
}
fn tail(z: f64) -> f64 {                         // area right of z > 3: continued fraction
    let mut f = z;
    for k in (1..=80).rev() { f = z + k as f64 / f; }
    (-z * z / 2.0).exp() / (2.0 * std::f64::consts::PI).sqrt() / f
}
fn phi(z: f64) -> f64 {                          // the bell's area left of z
    if z < -3.0 { tail(-z) } else if z > 3.0 { 1.0 - tail(z) } else { ser(z) }
}
fn lnln(x: f64) -> f64 { x.ln().ln() }
struct Rng(u64);
impl Rng { fn u01(&mut self) -> f64 {           // SplitMix64, top 53 bits
    self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15); let mut z = self.0;
    z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0 } }
fn main() {
    let mut isp = vec![true; N + 1]; isp[0] = false; isp[1] = false;
    for i in 2..1001 {
        if isp[i] { let mut j = i * i; while j <= N { isp[j] = false; j += i; } }
    }
    let primes: Vec<usize> = (2..=N).filter(|&p| isp[p]).collect();
    let (mut w, mut low) = (vec![0usize; N + 1], vec![0usize; N + 1]);
    for &p in &primes {
        let mut m = p;
        while m <= N { w[m] += 1; if p <= Y { low[m] += 1; } m += p; }
    }
    let nf = N as f64;
    let l = lnln(nf); let s = l.sqrt();
    let mut h = [0u64; 8];
    for n in 1..=N { h[w[n]] += 1; }
    let mut pp = 0u64;                           // prime powers
    for &p in &primes { let mut q = p as u64; while q <= N as u64 { pp += 1; q *= p as u64; } }
    println!("n <= {}: {} primes; log N = {:.4}, L = log log N = {:.4}, sqrt L = {:.4}", com(N as u64), com(primes.len() as u64), nf.ln(), l, s);
    for n in [999_999usize, N, 510_510] {
        let ps: Vec<String> = primes.iter().filter(|&&p| n % p == 0).map(|p| p.to_string()).collect();
        println!("{}: primes {}; omega {}", com(n as u64), ps.join(", "), w[n]);
    }
    println!("omega | count   | share  | bell   | bars: # = 10,000 integers (true, then bell)");
    let mut bell = vec![];
    for k in 0..8 {
        let kf = k as f64;
        let lo = if k == 0 { 0.0 } else { phi((kf - 0.5 - l) / s) };
        bell.push((nf * (phi((kf + 0.5 - l) / s) - lo)).round() as u64);
        let bt = "#".repeat((h[k] as f64 / 1e4).round() as usize);
        let bb = "#".repeat((bell[k] as f64 / 1e4).round() as usize);
        println!("{}     | {:>7} | {:.4} | {:.4} | {:<38}|{}", k, com(h[k]), h[k] as f64 / nf, bell[k] as f64 / nf, bt, bb);
    }
    let s1: u64 = w[1..].iter().map(|&v| v as u64).sum();
    let s2: u64 = w[1..].iter().map(|&v| (v * v) as u64).sum();
    let mu = s1 as f64 / nf; let var = s2 as f64 / nf - mu * mu;
    let fl: u64 = primes.iter().map(|&p| (N / p) as u64).sum();
    println!("omega = 1 count {}; prime powers {} = {} primes + {} higher powers", com(h[1]), com(pp), com(primes.len() as u64), pp - primes.len() as u64);
    println!("sum of omega {}, sum of floor(N/p) {}", com(s1), com(fl));
    let mut sp = 0.0f64; for &p in &primes { sp += 1.0 / p as f64; }
    println!("mean {:.4} (bell {:.4}, gap {:.4}; sum of 1/p {:.4}), variance {:.4}", mu, l, mu - l, sp, var);
    println!("Erdos-Kac form, n from 3 to N, z_n = (omega(n) - log log n) / sqrt(log log n):");
    for z in [-1.0f64, 0.0, 1.0] {
        let c = (3..=N).filter(|&n| w[n] as f64 - lnln(n as f64) <= z * lnln(n as f64).sqrt()).count();
        println!("share with z_n <= {:+.0}: {:.4}; bell Phi({:+.0}) = {:.4}", z, c as f64 / (N - 2) as f64, z, phi(z));
    }
    println!("x     | mean   | variance | L = log log x");
    for k in 2..7u32 {
        let x = 10usize.pow(k);
        let a1: u64 = w[1..=x].iter().map(|&v| v as u64).sum();
        let a2: u64 = w[1..=x].iter().map(|&v| (v * v) as u64).sum();
        let m = a1 as f64 / x as f64; let v2 = a2 as f64 / x as f64 - m * m;
        println!("10^{}  | {:.4} | {:.4}   | {:.4}", k, m, v2, lnln(x as f64));
    }
    let small: Vec<usize> = primes.iter().cloned().filter(|&p| p <= Y).collect();
    let mut model = vec![1.0f64];                // independent indicators, chance 1/p each
    for &p in &small {
        let mut nxt = vec![0.0; model.len() + 1];
        for (k, &q) in model.iter().enumerate() {
            nxt[k] += q * (1.0 - 1.0 / p as f64); nxt[k + 1] += q / p as f64;
        }
        model = nxt;
    }
    let mut hl = [0u64; 8];
    for n in 1..=N { hl[low[n]] += 1; }
    let gap = (0..8).map(|k| (hl[k] as f64 / nf - model[k]).abs()).fold(0.0, f64::max);
    println!("primes <= {} ({} of them): k | true share | independent model", Y, small.len());
    for k in 0..6 { println!("  {} | {:.4} | {:.4}", k, hl[k] as f64 / nf, model[k]); }
    println!("largest gap over k = 0..7: {:.4}", gap);
    let big: Vec<u64> = (1..=N).map(|n| (w[n] - low[n]) as u64).collect();
    let (mut rb, mut rv) = (0.0f64, 0.0f64);
    for &p in &primes {
        if p > Y { let r = 1.0 / p as f64; rb += r; rv += r * (1.0 - r); }
    }
    let bm = big.iter().sum::<u64>() as f64 / nf;
    let bv = big.iter().map(|b| b * b).sum::<u64>() as f64 / nf - bm * bm;
    let bmax = *big.iter().max().unwrap();
    println!("primes > {}: mean count {:.4}, model {:.4}; variance {:.4}, model {:.4}", Y, bm, rb, bv, rv);
    println!("primes > {}: most in one n {}, since {}^3 = {} > N", Y, bmax, Y + 1, com(((Y + 1) as u64).pow(3)));
    let mut indep = 0.0f64; for &p in &primes { let r = 1.0 / p as f64; indep += r * (1.0 - r); }
    for (name, lx) in [("10^9", 9.0f64), ("10^80", 80.0), ("2^2048", 2048.0 * 2f64.ln() / 10f64.ln())] {
        println!("log log {} = {:.4}", name, (lx * 10f64.ln()).ln());
    }
    for t in [l, 10.0, 100.0] {
        let d = t.exp() / 10f64.ln(); let e = d.log10().floor() as i32; let wall = (1.0 - t) / t.sqrt();
        let dd = if e < 6 { com(d.round() as u64) } else {
            format!("{:.2} x 10^{}", d / format!("1e{}", e).parse::<f64>().unwrap(), e) };
        println!("L = {:.2}: log10 x = {}; omega = 1 sits at z = {:.4}; bell area below it {:.4}", t, dd, wall, phi(wall));
    }
    let mut rng = Rng(SEED);
    println!("limit law: model count with mean L, {} draws each (seed {})", com(D as u64), SEED);
    println!("L      | sim share <= L | exact  | sim largest gap to bell | exact  | 1/sqrt L");
    let (mut worst, mut gaps) = (0.0f64, vec![]);
    for lam in [l, 10.0, 100.0] {
        let mut xs = vec![];
        for _ in 0..D {
            let (mut k, mut prod, lim) = (0usize, rng.u01(), (-lam).exp());
            while prod > lim { k += 1; prod *= rng.u01(); }
            xs.push(k);
        }
        let mut cnt = vec![0u64; xs.iter().max().unwrap() + 1];
        for &x in &xs { cnt[x] += 1; }
        let (mut pk, mut f, mut g, mut ge, mut gs, mut e0, mut j) = ((-lam).exp(), 0.0f64, 0u64, 0.0f64, 0.0f64, 0.0f64, 0usize);
        while (j as f64) < 10.0 * lam + 60.0 {   // exact Poisson staircase against the bell
            let b0 = phi((j as f64 - lam) / lam.sqrt());
            ge = ge.max((f - b0).abs()); gs = gs.max((g as f64 / D as f64 - b0).abs());
            f += pk; if j < cnt.len() { g += cnt[j]; }
            ge = ge.max((f - b0).abs()); gs = gs.max((g as f64 / D as f64 - b0).abs());
            if (j as f64) <= lam { e0 = f; }
            j += 1; pk *= lam / j as f64;
        }
        let a0 = xs.iter().filter(|&&x| (x as f64) <= lam).count() as f64 / D as f64;
        worst = worst.max((a0 - e0).abs() / (e0 * (1.0 - e0) / D as f64).sqrt());
        gaps.push(ge * lam.sqrt());
        println!("{:<6.2} | {:.4}         | {:.4} | {:.4}                  | {:.4} | {:.4}", lam, a0, e0, gs, ge, 1.0 / lam.sqrt());
    }
    let gl: Vec<String> = gaps.iter().map(|g| format!("{:.4}", g)).collect();
    println!("exact gap x sqrt L: {}; worst simulated miss {:.2} standard errors", gl.join(", "), worst);
    println!("mistake 1, bell read as a count: omega <= 0 (z <= {:.4}) for {} integers, true {}", (0.5 - l) / s, com(bell[0]), h[0]);
    println!("mistake 2, base-10 logs: centre {:.4} against {:.4}", 6f64.log10(), l);
    let pz = primes[1..].iter().filter(|&&p| 1.0 - lnln(p as f64) <= 0.0).count();
    println!("mistake 3, primes only: z_n <= 0 for {} of {} odd primes, share {:.4}, bell 0.5000",
             com(pz as u64), com((primes.len() - 1) as u64), pz as f64 / (primes.len() - 1) as f64);
    println!("mistake 4, every prime independent: variance {:.4} against {:.4}", indep, var);
    assert!(s1 == fl && h[1] == pp && h[0] == 1);
    assert!(primes.len() == 78498 && h.iter().sum::<u64>() == N as u64);   // pi(10^6), known table
    assert!(gap < 0.01 && bmax == 2 && ((Y + 1) as u64).pow(3) > N as u64); // near-independence
    assert!((ser(3.5) - 1.0 + tail(3.5)).abs() < 1e-12 && (ser(-3.5) - tail(3.5)).abs() < 1e-12); // Phi, 2 roads
    assert!(worst < 4.0 && gaps.iter().cloned().fold(0.0, f64::max) < 2.0 * gaps.iter().cloned().fold(9.0, f64::min) && (var - l).abs() > 1.0);
    println!("ALL CHECKS PASS");
}
