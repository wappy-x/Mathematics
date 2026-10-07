// Hypothesis tests and p-values -- the same check as the Python, in Rust.  No crates.
// A drug trial: 45 of 100 recovered on the drug, 35 of 100 on placebo.  Is the gap
// more than chance?  Road 1: the z statistic and its tail from the bell's Taylor
// series.  Road 2: the same tail by Simpson's rule.  Road 3: all 101 x 101 outcomes
// under the null, enumerated exactly.  Road 4: 20,000 seeded null trials.
use std::f64::consts::PI;

const N: usize = 100; const A: usize = 45; const B: usize = 35;
const R: usize = 20000; const SEED: u64 = 20260928;

fn phi(x: f64) -> f64 {                          // bell area left of x, by its Taylor series
    let (mut term, mut total) = (x, x);
    for k in 1..200 {
        let k = k as f64;
        term *= -x * x / (2.0 * k);
        total += term / (2.0 * k + 1.0);
    }
    0.5 + total / (2.0 * PI).sqrt()
}

fn bell(u: f64) -> f64 { (-u * u / 2.0).exp() / (2.0 * PI).sqrt() }

fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64) -> f64 {   // integral of f, 4000 steps
    let m = 4000;
    let h = (b - a) / m as f64;
    let mut s = f(a) + f(b);
    for i in 1..m { s += (if i % 2 == 1 { 4.0 } else { 2.0 }) * f(a + i as f64 * h) }
    s * h / 3.0
}

fn zstat(a: usize, b: usize, n: usize) -> f64 { // gap in rates over its pooled standard error
    let nf = n as f64;
    let r = (a + b) as f64 / (2.0 * nf);
    if r <= 0.0 || r >= 1.0 { return 0.0 }
    (a as f64 / nf - b as f64 / nf) / (r * (1.0 - r) * 2.0 / nf).sqrt()
}

fn binom(r: f64) -> Vec<f64> {                   // P(K = k) for k = 0..N, K ~ Binomial(N, r)
    let mut pm = vec![(1.0 - r).powi(N as i32)];
    for k in 0..N {
        pm.push(pm[k] * (N - k) as f64 / (k + 1) as f64 * r / (1.0 - r));
    }
    pm
}

fn enumerate(ra: f64, rb: f64, cut: f64) -> f64 {   // exact chance that |z| >= cut, every outcome
    let (pa, pb) = (binom(ra), binom(rb));
    let mut s = 0.0;
    for a in 0..=N { for b in 0..=N {
        if zstat(a, b, N).abs() >= cut - 1e-12 { s += pa[a] * pb[b] }
    } }
    s
}

struct Rng(u64);
impl Rng {
    fn splitmix(&mut self) -> u64 {              // SplitMix64, seed 20260928
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut x = self.0;
        x = (x ^ (x >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        x = (x ^ (x >> 27)).wrapping_mul(0x94D049BB133111EB);
        x ^ (x >> 31)
    }
    fn trial(&mut self, ra: f64, rb: f64) -> Vec<f64> {   // recoveries after 20, 40, .., 100 per arm
        let mut arms: Vec<Vec<usize>> = Vec::new();
        for r in [ra, rb] {
            let (mut c, mut marks) = (0, Vec::new());
            for i in 1..=N {
                if ((self.splitmix() >> 11) as f64 / 9007199254740992.0) < r { c += 1 }
                if i % 20 == 0 { marks.push(c) }
            }
            arms.push(marks);
        }
        (0..5).map(|j| zstat(arms[0][j], arms[1][j], 20 * (j + 1))).collect()
    }
}

fn rate(k: usize) -> (f64, f64) {
    let q = k as f64 / R as f64;
    (q, (q * (1.0 - q) / R as f64).sqrt())
}

fn bin(z: f64) -> usize { ((10.0 * 2.0 * (1.0 - phi(z.abs()))) as usize).min(9) }

fn main() {
    let rbar = (A + B) as f64 / (2.0 * N as f64);
    let se = (rbar * (1.0 - rbar) * 2.0 / N as f64).sqrt();
    let z0 = zstat(A, B, N);
    let p1 = 2.0 * (1.0 - phi(z0));
    let p2 = 2.0 * simpson(bell, z0, 12.0);
    let p3 = enumerate(rbar, rbar, z0);
    let (mut lo, mut hi) = (0.0, 10.0);
    for _ in 0..100 {                            // bisection: the cutoff with two-sided area 0.05
        let mid = (lo + hi) / 2.0;
        if 2.0 * (1.0 - phi(mid)) > 0.05 { lo = mid } else { hi = mid }
    }
    let zc = (lo + hi) / 2.0;
    let (size, power) = (enumerate(rbar, rbar, zc), enumerate(0.45, 0.35, zc));
    let nf = N as f64;
    println!("data: drug {}/{} = {:.2}, placebo {}/{} = {:.2}, gap {:.2}; {} of {} recovered", A, N, A as f64 / nf, B, N, B as f64 / nf, (A - B) as f64 / nf, A + B, 2 * N);
    println!("pooled rate {:.2}, variance of the gap {:.6}, standard error {:.6}, z = {:.6}", rbar, se * se, se, z0);
    println!("road 1, Taylor series: two-sided p = {:.6}, one-sided p = {:.6}", p1, p1 / 2.0);
    println!("road 2, Simpson's rule: two-sided p = {:.6}", p2);
    println!("road 3, all {} outcomes at rate {:.2}: exact p = {:.6}", (N + 1) * (N + 1), rbar, p3);
    println!("cutoff for level 0.05: {:.6}; exact size of 'reject if |z| >= cutoff' {:.4}", zc, size);
    println!("exact power against 0.45 vs 0.35: {:.4}", power);

    let mut rng = Rng(SEED);
    let (mut h0, mut h1) = ([0usize; 10], [0usize; 10]);
    let (mut far, mut rej0, mut peek, mut rej1) = (0, 0, 0, 0);
    for _ in 0..R {
        let zs = rng.trial(rbar, rbar);
        let last = zs[4];
        if last.abs() >= z0 - 1e-12 { far += 1 }
        if last.abs() >= zc { rej0 += 1 }
        if zs.iter().any(|z| z.abs() >= zc) { peek += 1 }
        h0[bin(last)] += 1;
    }
    for _ in 0..R {
        let z = rng.trial(0.45, 0.35)[4];
        if z.abs() >= zc { rej1 += 1 }
        h1[bin(z)] += 1;
    }
    let ((q4, e4), (q0, e0), (qp, ep), (q1, e1)) = (rate(far), rate(rej0), rate(peek), rate(rej1));
    println!("road 4, {} null trials, seed {}: share with |z| >= {:.4} is {:.4} +/- {:.4}", R, SEED, z0, q4, e4);
    println!("  rejected at 0.05 when the drug does nothing: {:.4} +/- {:.4}", q0, e0);
    println!("  rejected at 0.05 when it lifts 0.35 to 0.45: {:.4} +/- {:.4}", q1, e1);
    println!("  peeking after 20, 40, 60, 80, 100 per arm, stop at first |z| >= cutoff: {:.4} +/- {:.4}", qp, ep);
    for (k, v) in [("null", h0), ("drug works", h1)] {
        let row: Vec<String> = v.iter().map(|&c| format!("{:.2}", 100.0 * c as f64 / R as f64)).collect();
        println!("p-value histogram, {}, percent per bin of width 0.1: {}", k, row.join(", "));
    }

    let mut w = vec![1.0f64];                    // permutation (Fisher) law of drug-arm recoveries, 80 in all
    for x in 0..80 {
        let xf = x as f64;
        w.push(w[x] * (80.0 - xf) * (100.0 - xf) / ((xf + 1.0) * (21.0 + xf)));
    }
    let tails = (0..=80).filter(|&x| (x as i64 - 40).abs() >= 5).fold(0.0, |s, x| s + w[x]);
    let fisher = tails / w.iter().fold(0.0, |s, x| s + x);
    let (ra, rb, gap) = (A as f64 / nf, B as f64 / nf, (A - B) as f64 / nf);
    let seu = (ra * (1.0 - ra) / nf + rb * (1.0 - rb) / nf).sqrt();
    println!("permutation test (Fisher), same data: p = {:.4}", fisher);
    println!("95% interval for the gap, standard error from each arm's own rate {:.6}: {:.2} +/- {:.4} = [{:.4}, {:.4}]", seu, gap, zc * seu, gap - zc * seu, gap + zc * seu);
    let (zb, zt) = (zstat(450, 350, 1000), zstat(7200, 7000, 20000));
    println!("ten times the patients, 450/1000 vs 350/1000: z = {:.4}, p = {:.7}", zb, 2.0 * (1.0 - phi(zb)));
    println!("tiny gap, 7200/20000 vs 7000/20000: z = {:.4}, p = {:.4}", zt, 2.0 * (1.0 - phi(zt)));
    for share in [0.5, 0.1] {                    // of drugs tested, the share that truly work
        let ex = (1.0 - share) * size / ((1.0 - share) * size + share * power);
        let sm = (1.0 - share) * q0 / ((1.0 - share) * q0 + share * q1);
        println!("if {:.1} of drugs work: rejections that are false alarms, exact {:.4}, simulated {:.4}", share, ex, sm);
    }

    let (s, base) = (40.0, 190.0);               // figure: x in bell units -> 180 + 40 x, y -> 190 - 360 f
    let pt = |u: f64| format!("{:.1},{:.1}", 180.0 + s * u, base - 360.0 * bell(u));
    let row: Vec<String> = (0..29).map(|i| pt(-3.5 + 0.25 * i as f64)).collect();
    println!("figure, bell: {}", row.join(" "));
    let tail: Vec<f64> = std::iter::once(z0).chain((0..9).map(|i| 1.5 + 0.25 * i as f64)).collect();
    let right: Vec<String> = tail.iter().map(|&u| pt(u)).collect();
    let left: Vec<String> = tail.iter().map(|&u| pt(-u)).collect();
    println!("figure, right tail: {} {:.1},{:.1} {:.1},{:.1}", right.join(" "), 180.0 + s * 3.5, base, 180.0 + s * z0, base);
    println!("figure, left tail: {} {:.1},{:.1} {:.1},{:.1}", left.join(" "), 180.0 - s * 3.5, base, 180.0 - s * z0, base);

    assert!((p1 - p2).abs() < 1e-9);             // series and integral: two roads to the bell's tail
    assert!((p3 - p1).abs() < 0.005);            // exact enumeration agrees with the bell to half a point
    assert!((q4 - p3).abs() < 4.0 * e4);         // simulation agrees with enumeration
    assert!((q0 - size).abs() < 4.0 * e0 && (q1 - power).abs() < 4.0 * e1);
    assert!(qp - size > 4.0 * ep);               // peeking breaks the 5 percent promise
    println!("ALL CHECKS PASS");
}
