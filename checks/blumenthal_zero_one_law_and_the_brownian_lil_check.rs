// Blumenthal's zero-one law and the Brownian LIL, for a grain spreading 1 um^2 per second.
// Roads: normal tails three ways; exact sign-change and Borel-Cantelli sums; seeded simulation.
use std::f64::consts::PI;

struct Rng { s: u64, spare: Option<f64> } // SplitMix64, then Box-Muller for normal draws
impl Rng {
    fn u64(&mut self) -> u64 {
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    }
    fn normal(&mut self) -> f64 {
        if let Some(z) = self.spare.take() { return z; }
        let u1 = ((self.u64() >> 11) + 1) as f64 / 2f64.powi(53);
        let u2 = (self.u64() >> 11) as f64 / 2f64.powi(53);
        let r = (-2.0 * u1.ln()).sqrt();
        self.spare = Some(r * (2.0 * PI * u2).sin());
        r * (2.0 * PI * u2).cos()
    }
}

fn phi(z: f64) -> f64 { (-z * z / 2.0).exp() / (2.0 * PI).sqrt() }
fn q_series(z: f64) -> f64 { // P(Z > z) from the Taylor series of erf
    let x = z / 2f64.sqrt();
    let (mut s, mut term, mut k) = (0.0, x, 0u32);
    while k < 5 || term.abs() > 1e-17 {
        s += term / (2 * k + 1) as f64; k += 1; term *= -x * x / k as f64;
    }
    0.5 - s / PI.sqrt()
}
fn q_cf(z: f64, kmax: u32) -> f64 { // P(Z > z) from the continued fraction of the Mills ratio
    let mut f = z;
    for k in (1..=kmax).rev() { f = z + k as f64 / f; }
    phi(z) / f
}
fn q_simpson(z: f64, n: usize) -> f64 { // P(Z > z) as the area under phi from z to z + 12
    let hh = 12.0 / n as f64;
    let mut s = phi(z) + phi(z + 12.0);
    for i in 1..n { s += (if i % 2 == 1 { 4.0 } else { 2.0 }) * phi(z + i as f64 * hh); }
    s * hh / 3.0
}
fn tail(z: f64) -> f64 { if z >= 2.0 { q_cf(z, 100) } else { q_series(z) } }
fn env(t: f64) -> f64 { (2.0 * t * t.ln().ln()).sqrt() } // the LIL envelope h(t)
fn mean_se(c: &[f64]) -> (f64, f64) {
    let n = c.len() as f64;
    let m = c.iter().sum::<f64>() / n;
    (m, (c.iter().map(|x| (x - m) * (x - m)).sum::<f64>() / (n - 1.0) / n).sqrt())
}
fn exact_changes(m: usize) -> f64 { // sum over neighbours of P(opposite signs) = arccos(rho) / pi
    (1..m).map(|i| (i as f64 / (i + 1) as f64).sqrt().acos()).sum::<f64>() / PI
}
fn row(label: &str, xs: &[f64], w: usize, d: usize) -> String {
    format!("{:<42}{}", label, xs.iter().map(|x| format!("{:w$.d$}", x, w = w, d = d)).collect::<String>())
}

fn main() {
    let t = 1e6;
    let z = env(t) / t.sqrt();
    println!("{:<42}{:12.4}{:10.4}", "sqrt(t), t = 1e6 s; t in days", t.sqrt(), t / 86400.0);
    println!("{:<42}{:12.4}{:10.4}", "ln t, then ln ln t", t.ln(), t.ln().ln());
    println!("{:<42}{:12.4}", "envelope h(t) = sqrt(2 t ln ln t), um", env(t));
    println!("{:<42}{:12.4}", "h(t) / sqrt(t)", z);
    println!("{:<42}{:12.6}{:10.6}{:10.6}", "P(W_t > h(t)): series, fraction, Simpson", q_series(z), q_cf(z, 400), q_simpson(z, 4000));
    assert!((env(t) - 2291.6).abs() < 0.1, "envelope against the hand value sqrt(2e6 x 2.626)");
    for zz in [1.0, 1.5, z, 3.0] {
        assert!((q_series(zz) - q_cf(zz, 400)).abs() < 1e-13 && (q_simpson(zz, 4000) - q_cf(zz, 400)).abs() < 1e-12);
    }
    let facs: Vec<f64> = [1e3, 1e6, 1e12, 1e100].iter().map(|&s| env(s) / s.sqrt()).collect();
    println!("{}", row("factor at t = 1e3, 1e6, 1e12, 1e100 s", &facs, 8, 4));
    println!("{:<42}{:12.6}{:10.1}", "wrong: P(W_t > 3 sqrt t); sqrt(2 t ln t)", tail(3.0), (2.0 * t * t.ln()).sqrt());
    println!("{:<42}{:12.7}", "time inversion: envelope at 1 us, um", (2e-6 * 1e6f64.ln().ln()).sqrt());
    let mut ri = Rng { s: 7, spare: None }; // time inversion simulated: Cov(X_0.5, X_4) = E[0.5 W_2 * 4 W_0.25] must be min(0.5, 4) = 0.5
    let pr: Vec<f64> = (0..20000).map(|_| { let a = 0.5 * ri.normal(); 0.5 * (a + 1.75f64.sqrt() * ri.normal()) * 4.0 * a }).collect();
    let (pm, pse) = mean_se(&pr);
    println!("{:<42}{:12.4}{:10.4}", "time inversion: Cov(X_0.5, X_4), sim; se", pm, pse); assert!((pm - 0.5).abs() < 4.0 * pse);

    // Blumenthal: the first millisecond, sampled every 1 us, coarsened to 10 and 100 us.
    let mut rng = Rng { s: 20261123, spare: None };
    let (paths, m) = (2000usize, 1000usize);
    let grids = [100usize, 10, 1];
    let (mut chg, mut pos) = (vec![Vec::new(); 3], [0usize; 3]);
    for _ in 0..paths {
        let mut w = 0.0;
        let path: Vec<f64> = (0..m).map(|_| { w += 1e-6f64.sqrt() * rng.normal(); w }).collect();
        for (j, &g) in grids.iter().enumerate() {
            let pts: Vec<f64> = path.iter().skip(g - 1).step_by(g).cloned().collect();
            chg[j].push(pts.windows(2).filter(|p| p[0] * p[1] < 0.0).count() as f64);
            if pts.iter().any(|&p| p > 0.0) { pos[j] += 1; }
        }
    }
    println!("first ms   samples   exact mean changes   simulated   std err   positive somewhere");
    for (j, &g) in grids.iter().enumerate() {
        let mm = m / g;
        let ex = exact_changes(mm);
        let (mean, se) = mean_se(&chg[j]);
        println!("{:10}{:8}{:21.4}{:12.4}{:10.4}{:16.4}", "", mm, ex, mean, se, pos[j] as f64 / paths as f64);
        assert!((mean - ex).abs() < 4.0 * se, "simulated sign changes against the exact sum");
    }
    assert!(pos[2] as f64 / paths as f64 > 0.5 + 4.0 * (0.25 / paths as f64).sqrt(), "beats the 1/2 of a single time");
    let big = exact_changes(1_000_000);
    println!("{:<42}{:12.4}{:10.4}", "exact mean changes, 1e6 samples (1 ns)", big, 2.0 / PI * 1000.0);
    assert!((big / (2.0 / PI * 1000.0) - 1.0).abs() < 0.01, "changes grow like (2/pi) root m");

    // Borel-Cantelli, upper half: blocks [2^n, 2^(n+1)], max passing 2 h(2^n), by reflection.
    let ln2 = 2f64.ln();
    let a_term = |n: f64| 2.0 * tail(2.0 * (n * ln2).ln().sqrt()); // 2 h(2^n) / sqrt(2^(n+1))
    assert!((2.0 * env(2f64.powi(30)) / 2f64.powi(31).sqrt() - 2.0 * (30.0 * ln2).ln().sqrt()).abs() < 1e-12);
    let mills_bound = |n: f64| { let l = (n * ln2).ln(); 2.0 * phi(2.0 * l.sqrt()) / (2.0 * l.sqrt()) };
    let (mut sums, mut acc) = (Vec::new(), 0.0);
    for n in 20..=10_000u32 {
        acc += a_term(n as f64);
        if [20, 100, 1000, 10_000].contains(&n) { sums.push(acc); }
    }
    let rest_after = |nn: f64| 1.0 / ((2.0 * PI).sqrt() * ln2 * ln2 * (nn * ln2).ln().sqrt() * nn);
    println!("{}", row("upper: term 20; sums to 1e2, 1e3, 1e4", &sums, 10, 6));
    println!("{:<42}{:12}{:10.6}", "upper: block 20 starts (s); bound after 1e4", 1u64 << 20, rest_after(1e4));
    println!("{:<42}{:12.4}{:10.4}", "blocks of 2 for factor 1.1: exponent; 1.1", 1.1f64.powi(2) / 2.0, 1.1f64.powi(2) / 1.1);
    assert!(a_term(500.0) < mills_bound(500.0) && sums[3] - sums[2] < rest_after(1e3));
    // Borel-Cantelli, lower half: q = 100, independent jumps D_n beyond sqrt(1 - 1/q) h(t_n).
    let ln100 = 100f64.ln(); let b_term = |n: f64| tail((2.0 * (n * ln100).ln()).sqrt());
    let (mut bs, mut acc) = (Vec::new(), 0.0);
    for n in 3..=100_000u32 {
        acc += b_term(n as f64);
        if [10, 100, 1000, 10_000, 100_000].contains(&n) { bs.push(acc); }
    }
    println!("{}", row("lower: sums to 1e1 .. 1e5 blocks", &bs, 8, 4));
    let grow = ((1e5 * ln100).ln().sqrt() - (1e4 * ln100).ln().sqrt()) / (PI.sqrt() * ln100);
    println!("{:<42}{:12.6}{:10.4}{:10.4}", "lower: block 3 (1e6 s); last decade, integral", b_term(3.0), bs[4] - bs[3], grow);
    assert!(((bs[4] - bs[3]) / grow - 1.0).abs() < 0.1, "lower series grows like root ln N");
    let (nb, npath) = (150u32, 20000usize); let expect: f64 = (3..=nb).map(|n| b_term(n as f64)).sum();
    let cnt: Vec<f64> = (0..npath).map(|_| (3..=nb).filter(|&n| rng.normal() >= (2.0 * (n as f64 * ln100).ln()).sqrt()).count() as f64).collect();
    let (cm, cse) = mean_se(&cnt);
    println!("{:<42}{:12.4}{:10.4}{:10.4}", "blocks 3..150 hit: expected, simulated, se", expect, cm, cse);
    assert!((cm - expect).abs() < 4.0 * cse, "simulated count of lower events against the sum");
    let lb: Vec<f64> = [100.0f64, 1e4, 1e6].iter().map(|&q| (1.0 - 1.0 / q).sqrt() - 2.0 / q.sqrt()).collect();
    println!("{}", row("lower bound, q = 100, 1e4, 1e6", &lb, 8, 4));

    // LIL simulation on times 1.2^k from 10 s to 1e300 s.
    let (lp, r) = (500usize, 1.2f64);
    let starts = [1e6f64, 1e30, 1e100];
    let (mut over11, mut over09) = ([0usize; 3], 0usize);
    let (mut hi, mut lo) = (vec![-9.0f64; 15], vec![9.0f64; 15]);
    for p in 0..lp {
        let (mut t, mut w) = (10.0f64, 10f64.sqrt() * rng.normal());
        let mut best = [-9.0f64; 3];
        while t < 1e300 {
            let t2 = t * r;
            w += (t2 - t).sqrt() * rng.normal();
            t = t2;
            let ratio = w / env(t);
            for (j, &s) in starts.iter().enumerate() { if t >= s { best[j] = best[j].max(ratio); } }
            if p == 0 {
                let k = ((t.log10() / 20.0).floor() as usize).min(14);
                lo[k] = lo[k].min(ratio); hi[k] = hi[k].max(ratio);
            }
        }
        for j in 0..3 { if best[j] > 1.1 { over11[j] += 1; } }
        if best[2] > 0.9 { over09 += 1; }
    }
    let sh: Vec<f64> = over11.iter().map(|&c| c as f64 / lp as f64).collect();
    println!("{}", row("share over 1.1 h after 1e6, 1e30, 1e100", &sh, 8, 3));
    println!("{:<42}{:8.3}", "share over 0.9 h after 1e100", over09 as f64 / lp as f64);
    assert!(sh[0] > sh[2] + 4.0 * (sh[0] * (1.0 - sh[0]) / lp as f64).sqrt(), "overshoots thin out with time");
    println!("chart, window start 1e(20k), k =  {}", (0..15).map(|k| format!("{:5}", k)).collect::<Vec<_>>().join(" "));
    println!("chart, path 1, max W/h          {}", hi.iter().map(|x| format!("{:5.2}", x)).collect::<Vec<_>>().join(" "));
    println!("chart, path 1, min W/h          {}", lo.iter().map(|x| format!("{:5.2}", x)).collect::<Vec<_>>().join(" "));
    println!("ALL CHECKS PASS");
}
