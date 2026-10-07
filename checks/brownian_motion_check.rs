// Brownian motion: a grain's sideways position W_t, in micrometres (um), t seconds
// after it was first seen; its variance grows by 1 square um per second.
// Question: P(W_10 > 5), the chance it is more than 5 um right of its start at 10 s.
// Three roads: the Gaussian formula; the exact law of a walk with n steps a second,
// each +-1/sqrt(n) um; 100,000 seeded paths sampled every second.  Std only, no crates.
use std::f64::consts::PI;
const T: usize = 10;
const A: f64 = 5.0;

fn phi(x: f64) -> f64 { (-x * x / 2.0).exp() / (2.0 * PI).sqrt() } // standard normal density
fn big_phi(x: f64) -> f64 { // its CDF: 1/2 plus Simpson's rule on [0, x]
    let m = 2000;
    let h = x / m as f64;
    let inner: f64 = (1..m).map(|i| (if i % 2 == 1 { 4.0 } else { 2.0 }) * phi(i as f64 * h)).sum();
    0.5 + (phi(0.0) + phi(x) + inner) * h / 3.0
}
fn tail(a: f64, var: f64) -> f64 { 1.0 - big_phi(a / var.sqrt()) } // P(N(0, var) > a)
// N fair +-1 steps, height k = 2j - N: the law, P(k >= kmin), and the mean of k^2
fn walk(lf: &[f64], n: usize, kmin: i64) -> (Vec<f64>, f64, f64) {
    let w: Vec<f64> = (0..=n).map(|j| (lf[n] - lf[j] - lf[n - j] - n as f64 * 2f64.ln()).exp()).collect();
    let k = |j: usize| 2 * j as i64 - n as i64;
    let p: f64 = w.iter().enumerate().filter(|(j, _)| k(*j) >= kmin).map(|(_, x)| *x).sum();
    let m2: f64 = w.iter().enumerate().map(|(j, x)| x * (k(j) * k(j)) as f64).sum();
    (w, p, m2)
}
fn first_k(n: usize, ok: impl Fn(i64) -> bool) -> i64 { // smallest height k > 0, parity of N, passing ok
    let mut k = 1i64;
    while (k - n as i64) % 2 != 0 || !ok(k) { k += 1; }
    k
}
fn persistent(n: usize, r: f64, kmin: i64) -> (f64, f64) { // each step repeats the last with chance r
    let mut w = [[0.0f64; 2]].repeat(2 * n + 1); // w[k + N][d]: height k, last step d
    w[n + 1][1] = 0.5;
    w[n - 1][0] = 0.5;
    for _ in 0..n - 1 {
        let mut new = [[0.0f64; 2]].repeat(2 * n + 1);
        for i in 1..2 * n {
            new[i + 1][1] += w[i][1] * r + w[i][0] * (1.0 - r);
            new[i - 1][0] += w[i][0] * r + w[i][1] * (1.0 - r);
        }
        w = new;
    }
    let tot: Vec<f64> = w.iter().map(|x| x[0] + x[1]).collect();
    let h = |i: usize| i as i64 - n as i64;
    let p: f64 = tot.iter().enumerate().filter(|(i, _)| h(*i) >= kmin).map(|(_, x)| *x).sum();
    (p, tot.iter().enumerate().map(|(i, x)| x * (h(i) * h(i)) as f64).sum())
}
struct Rng(u64);
impl Rng {
    fn unif(&mut self) -> f64 { // SplitMix64, mapped into (0, 1]
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = (self.0 ^ (self.0 >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        (((z ^ (z >> 31)) >> 11) + 1) as f64 / 2f64.powi(53)
    }
    fn normal(&mut self) -> f64 { // Box-Muller, cosine half only
        let (u, v) = (self.unif(), self.unif());
        (-2.0 * u.ln()).sqrt() * (2.0 * PI * v).cos()
    }
}
fn row(label: &str, x: f64) { println!("{:<44}{:>10.4}", label, x); }
fn row_se(label: &str, (x, se): (f64, f64)) { println!("{:<44}{:>10.4}   se {:.4}", label, x, se); }
fn mean_se(xs: &[f64]) -> (f64, f64) {
    let m = xs.iter().sum::<f64>() / xs.len() as f64;
    let ss: f64 = xs.iter().map(|x| (x - m) * (x - m)).sum();
    (m, (ss / (xs.len() - 1) as f64 / xs.len() as f64).sqrt())
}
fn join(v: impl Iterator<Item = String>) -> String { v.collect::<Vec<_>>().join(" ") }

fn main() {
    let tf = T as f64;
    let mut lf = vec![0.0f64]; // lf[k] = ln k!
    for i in 1..=T * 10000 { let last = lf[i - 1]; lf.push(last + (i as f64).ln()); }
    println!("== road one: the Gaussian formula ==");
    let exact = tail(A, tf);
    row("z = 5 / sqrt(10)", A / tf.sqrt());
    row("Phi(z)", big_phi(A / tf.sqrt()));
    row("P(W_10 > 5) = 1 - Phi(z)", exact);
    row("P(|W_10| <= sqrt(10))", 2.0 * big_phi(1.0) - 1.0);
    let cond = tail(A - 2.0, tf - 4.0);
    row("P(W_10 > 5 | W_4 = 2) = P(N(0,6) > 3)", cond);
    row("Cov(W_4, W_10) = min(4, 10)", 4.0);
    row("correlation sqrt(4/10)", (4.0 / tf).sqrt());
    println!("== road two: exact law of the walk, n steps a second ==");
    let (law1, p1, _) = walk(&lf, T, 6); // n = 1: one +-1 um step a second
    row("n = 1, one 1 um step a second: P(S > 5)", p1);
    let ns = [4usize, 16, 64, 256, 1024, 4096];
    let mut errs = vec![];
    for &n in &ns {
        let big_n = T * n;
        let k = first_k(big_n, |k| k * k > 25 * n as i64); // k / sqrt(n) > 5
        let (_, p, m2) = walk(&lf, big_n, k);
        errs.push(p - exact);
        assert!((m2 / n as f64 - tf).abs() < 1e-6, "walk variance is not 10");
        println!("n = {:>4}: P(S > 5) = {:.6}, error {:+.6}, error x sqrt(n) {:+.4}", n, p, p - exact, (p - exact) * (n as f64).sqrt());
    }
    let half_atom = -phi(A / tf.sqrt()) / tf.sqrt(); // minus half the lattice step 2/sqrt(n) times the density at 5
    row("predicted error x sqrt(n): -phi(z)/sqrt(10)", half_atom);
    assert!(errs.iter().zip(&ns).skip(1).all(|(e, n)| (e * (*n as f64).sqrt() - half_atom).abs() < 0.004), "error is not half an atom");
    println!("== road three: 100,000 paths sampled every second ==");
    let mut g = Rng(2026);
    let mut path = vec![0.0f64];
    for i in 0..20 { let z = g.normal(); path.push(path[i] + 0.5f64.sqrt() * z); } // chart path: steps of 0.5 s
    let (mut w4, mut w10) = (vec![], vec![]);
    for _ in 0..100000 {
        let mut w = 0.0f64;
        for t in 1..=T {
            w += g.normal(); // W_t - W_(t-1) ~ N(0, 1)
            if t == 4 { w4.push(w); }
        }
        w10.push(w);
    }
    let r = w10.len() as f64;
    let (m, se) = mean_se(&w10);
    row_se("mean of W_10", (m, se));
    let v = w10.iter().map(|x| (x - m) * (x - m)).sum::<f64>() / (r - 1.0);
    let vse = ((w10.iter().map(|x| (x - m).powi(4)).sum::<f64>() / r - v * v) / r).sqrt();
    row_se("variance of W_10", (v, vse));
    assert!((v - tf).abs() < 4.0 * vse, "simulated variance is not 10");
    let ind = |xs: &[f64], f: &dyn Fn(f64) -> bool| -> Vec<f64> { xs.iter().map(|x| if f(*x) { 1.0 } else { 0.0 }).collect() };
    let (ps, pse) = mean_se(&ind(&w10, &|x| x > A));
    row_se("P(W_10 > 5)", (ps, pse));
    assert!((ps - exact).abs() < 4.0 * pse, "simulation disagrees with the formula");
    row_se("P(|W_10| <= sqrt(10))", mean_se(&ind(&w10, &|x| x.abs() <= tf.sqrt())));
    let m4 = w4.iter().sum::<f64>() / r;
    let (cv, cse) = mean_se(&w4.iter().zip(&w10).map(|(a, b)| (a - m4) * (b - m)).collect::<Vec<_>>());
    row_se("Cov(W_4, W_10)", (cv, cse));
    assert!((cv - 4.0).abs() < 4.0 * cse, "simulated covariance is not 4");
    row_se("Cov(W_4, W_10 - W_4)", mean_se(&w4.iter().zip(&w10).map(|(a, b)| (a - m4) * (b - a)).collect::<Vec<_>>()));
    let near: Vec<f64> = w4.iter().zip(&w10).filter(|(a, _)| (1.9..=2.1).contains(*a)).map(|(_, b)| *b).collect();
    let (pc, pcse) = mean_se(&ind(&near, &|b| b > A));
    println!("paths with 1.9 <= W_4 <= 2.1: {}", near.len());
    row_se("P(W_10 > 5 | W_4 near 2)", (pc, pcse));
    assert!((pc - cond).abs() < 4.0 * pcse, "fresh-start rule fails");
    println!("== what breaks ==");
    let (_, p, m2) = walk(&lf, 1000, first_k(1000, |k| k > 500)); // steps 1/100 um, 100 a second
    row("steps 1/n: n = 100, variance", m2 / 100f64.powi(2));
    row("steps 1/n: n = 100, P(S > 5)", p);
    let (_, p, m2) = walk(&lf, 1000, first_k(1000, |k| k > 5)); // steps 1 um, 100 a second
    row("steps 1 um: n = 100, variance", m2);
    row("steps 1 um: n = 100, P(S > 5)", p);
    row("spread taken as t: P(N(0, 100) > 5)", tail(A, 100.0));
    row("W_4 = 2 ignored: P(W_10 > 5)", exact);
    let (pp, pv) = persistent(1000, 0.75, first_k(1000, |k| k * k > 2500));
    let pf = 1000.0 + 2.0 * (1..1000).map(|k| (1000 - k) as f64 * 0.5f64.powi(k)).sum::<f64>();
    assert!((pv - pf).abs() < 1e-6, "persistent walk: exact law disagrees with the sum");
    row("repeating steps: variance, exact law", pv / 100.0);
    row("repeating steps: variance, sum of covariances", pf / 100.0);
    row("repeating steps: P(S > 5), exact law", pp);
    row("repeating steps: limit P(N(0, 30) > 5)", tail(A, 30.0));
    println!("== charts ==");
    println!("chart, t (s)       {}", join((0..21).map(|i| format!("{}", 0.5 * i as f64))));
    println!("chart, path (um)   {}", join(path.iter().map(|x| format!("{:.2}", x))));
    println!("chart, +sqrt(t)    {}", join((0..21).map(|i| format!("{:.2}", (0.5 * i as f64).sqrt()))));
    println!("chart, -sqrt(t)    {}", join((0..21).map(|i| format!("{:.2}", -(0.5 * i as f64).sqrt() + 0.0))));
    println!("chart, k (um)      {}", join((0..11).map(|j| format!("{}", 2 * j - 10))));
    println!("chart, walk law (%)    {}", join(law1.iter().map(|x| format!("{:.2}", 100.0 * x))));
    println!("chart, 2 x density (%) {}", join((0..11).map(|j| format!("{:.2}", 200.0 * phi((2 * j - 10) as f64 / tf.sqrt()) / tf.sqrt()))));
    println!("ALL CHECKS PASS");
}
