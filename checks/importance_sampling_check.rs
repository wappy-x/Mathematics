// Importance sampling -- the same check as importance_sampling_check.py, in Rust.  Std only.
// A bolt jams when its diameter is more than c = 4.75 standard deviations above target: a chance of
// about one in a million.  Estimate it with 10,000 simulated bolts.  Same roads, same seed.
use std::f64::consts::PI;
const C: f64 = 4.75;
const N: usize = 10000;

struct SplitMix64 { s: u64 }
impl SplitMix64 {
    fn uniform(&mut self) -> f64 {                       // strictly inside (0, 1)
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        (((z ^ (z >> 31)) >> 11) as f64 + 0.5) / 9007199254740992.0
    }
    fn normal(&mut self) -> f64 {                        // Box-Muller, one draw from two uniforms
        let (u1, u2) = (self.uniform(), self.uniform());
        (-2.0 * u1.ln()).sqrt() * (2.0 * PI * u2).cos()
    }
}

fn f(y: f64) -> f64 { (-y * y / 2.0).exp() / (2.0 * PI).sqrt() }   // target: standard bell curve

fn tail_cf(x: f64) -> f64 {                              // P(X > x) by Laplace's continued fraction
    let mut t = x;
    for k in (1..=300).rev() { t = x + k as f64 / t; }
    f(x) / t
}

fn simpson<G: Fn(f64) -> f64>(g: G, lo: f64, hi: f64, n: usize) -> f64 {
    let w = (hi - lo) / n as f64;
    let mut s = g(lo) + g(hi);
    for j in 1..n { s += if j % 2 == 1 { 4.0 } else { 2.0 } * g(lo + j as f64 * w); }
    s * w / 3.0
}

fn summary(v: &[f64]) -> (f64, f64) {                    // mean and its standard error
    let n = v.len() as f64;
    let m = v.iter().sum::<f64>() / n;
    (m, (v.iter().map(|x| (x - m) * (x - m)).sum::<f64>() / (n - 1.0) / n).sqrt())
}

fn m2_shift(th: f64) -> f64 { (th * th).exp() * tail_cf(C + th) }   // proposal N(th, 1), closed form

fn rel_se(m2: f64, p: f64, n: usize) -> f64 { (m2 - p * p).sqrt() / (p * (n as f64).sqrt()) }

fn join(v: &[f64], dp: usize) -> String {
    v.iter().map(|x| format!("{:.*}", dp, x)).collect::<Vec<_>>().join(", ")
}

fn main() {
    let p = tail_cf(C);
    let p_simp = simpson(f, C, C + 30.0, 20000);
    println!("exact P(X > 4.75), continued fraction : {:.9} per million", p * 1e6);
    println!("exact P(X > 4.75), Simpson's rule     : {:.9} per million", p_simp * 1e6);
    println!("plain: expected hits in {} draws {:.4}; P(no hits) = {:.4}; rel se {:.2}%",
             N, N as f64 * p, (1.0 - p).powi(N as i32), rel_se(p, p, N) * 100.0);
    let mut rng = SplitMix64 { s: 2026 };
    let plain_hits = (0..N).filter(|_| rng.normal() > C).count();
    println!("plain run: {} hits, estimate {:.6} per million", plain_hits, plain_hits as f64 / N as f64 * 1e6);

    let g_n = |y: f64| f(y - C);                         // proposal A: bell curve moved to the line
    let w_n = |y: f64| (-C * y + C * C / 2.0).exp();     // weight f/g, simplified
    let ys: Vec<f64> = (0..N).map(|_| C + rng.normal()).collect();
    let wh: Vec<f64> = ys.iter().map(|&y| if y > C { w_n(y) } else { 0.0 }).collect();
    let (est_n, se_n) = summary(&wh);
    let hits_n = ys.iter().filter(|&&y| y > C).count();
    let m2_simp = simpson(|y| f(y) * f(y) / g_n(y), C, C + 30.0, 20000);
    println!("proposal N(4.75, 1): {} hits; estimate {:.6} per million, se {:.6}", hits_n, est_n * 1e6, se_n * 1e6);
    println!("  weight at the line e^(-c^2/2) = {:.4} per million; at y = 5.75 {:.4} per million", w_n(C) * 1e6, w_n(5.75) * 1e6);
    println!("  second moment per 10^12: closed {:.6}, Simpson {:.6}, sample {:.6}", m2_shift(C) * 1e12,
             m2_simp * 1e12, wh.iter().map(|v| v * v).sum::<f64>() / N as f64 * 1e12);
    println!("  by hand: c^2/2 = {:.5}; c^2 = {:.4}; P(X > 9.5) = {:.4} per 10^21; I^2 = {:.6} per 10^12",
             C * C / 2.0, C * C, tail_cf(9.5) * 1e21, p * p * 1e12);
    println!("  rel se: formula {:.2}%, run {:.2}%; run is {:.2} se from exact", rel_se(m2_shift(C), p, N) * 100.0,
             se_n / est_n * 100.0, (est_n - p) / se_n);
    println!("  plain draws for the same se: {:.0} million", p * (1.0 - p) / (m2_shift(C) - p * p) * N as f64 / 1e6);

    let lam = C;                                         // proposal B: exponential tail from the line
    let g_e = |y: f64| lam * (-lam * (y - C)).exp();
    let ye: Vec<f64> = (0..N).map(|_| C - rng.uniform().ln() / lam).collect();   // inverse transform
    let we: Vec<f64> = ye.iter().map(|&y| f(y) / g_e(y)).collect();
    let (est_e, se_e) = summary(&we);
    let m2_e = simpson(|y| f(y) * f(y) / g_e(y), C, C + 30.0, 20000);
    println!("proposal exponential, rate 4.75: estimate {:.6} per million, se {:.6}", est_e * 1e6, se_e * 1e6);
    println!("  rel se: formula {:.4}%, run {:.4}%; run is {:.2} se from exact", rel_se(m2_e, p, N) * 100.0,
             se_e / est_e * 100.0, (est_e - p) / se_e);
    println!("  plain draws for the same se: {:.1} billion", p * (1.0 - p) / (m2_e - p * p) * N as f64 / 1e9);

    let (mut a, mut b, gr) = (3.0_f64, 7.0_f64, (5.0_f64.sqrt() - 1.0) / 2.0);   // golden-section search
    for _ in 0..100 {
        let (x1, x2) = (b - gr * (b - a), a + gr * (b - a));
        if m2_shift(x1) < m2_shift(x2) { b = x2; } else { a = x1; }
    }
    let th_best = (a + b) / 2.0;
    println!("best shift {:.4}: rel se {:.2}%; shift 0 (plain): {:.2}%", th_best,
             rel_se(m2_shift(th_best), p, N) * 100.0, rel_se(m2_shift(0.0), p, N) * 100.0);
    let thetas: Vec<f64> = (0..9).map(|k| 3.0 + 0.5 * k as f64).collect();
    println!("figure, shift:        {}", join(&thetas, 1));
    println!("figure, rel se %:     {}", join(&thetas.iter().map(|&t| rel_se(m2_shift(t), p, N) * 100.0).collect::<Vec<_>>(), 2));
    let grid: Vec<f64> = (0..9).map(|k| k as f64).collect();
    println!("figure, y:            {}", join(&grid, 0));
    println!("figure, target f:     {}", join(&grid.iter().map(|&y| f(y)).collect::<Vec<_>>(), 2));
    println!("figure, proposal A:   {}", join(&grid.iter().map(|&y| g_n(y)).collect::<Vec<_>>(), 2));
    let tg: Vec<f64> = (0..7).map(|k| C + 0.25 * k as f64).collect();
    println!("figure, y in tail:    {}", join(&tg, 2));
    println!("figure, ideal f/I:    {}", join(&tg.iter().map(|&y| f(y) / p).collect::<Vec<_>>(), 2));
    println!("figure, proposal B:   {}", join(&tg.iter().map(|&y| g_e(y)).collect::<Vec<_>>(), 2));
    println!("figure, A in tail:    {}", join(&tg.iter().map(|&y| g_n(y)).collect::<Vec<_>>(), 2));

    // what breaks
    println!("wrong: no weights, share of proposal draws past the line {:.4}", hits_n as f64 / N as f64);
    println!("wrong: weight e^(-c y), dropping e^(c^2/2): estimate {:.8} per million, {:.0} times too small",
             est_n * (-C * C / 2.0).exp() * 1e6, (C * C / 2.0).exp());
    println!("wrong: proposal only up to 5.75 misses {:.2}% of the answer", tail_cf(5.75) / p * 100.0);
    let s = 0.5;                                         // proposal N(4.75, 0.25): tails too thin
    let w_t = |y: f64| s * (-y * y / 2.0 + (y - C) * (y - C) / (2.0 * s * s)).exp();        // f / g
    let m2_t = |y: f64| s / (2.0 * PI).sqrt() * (-y * y + (y - C) * (y - C) / (2.0 * s * s)).exp();
    let parts: Vec<f64> = [10.0, 20.0, 25.0, 30.0].iter().map(|&r| simpson(m2_t, C, r, 20000)).collect();
    let logs: Vec<String> = parts.iter().map(|v| format!("{:.1}", v.ln() / 10f64.ln())).collect();
    println!("wrong: thin proposal sd 0.5, second moment to R = 10, 20, 25, 30: 10^{}", logs.join(", 10^"));
    let wt: Vec<f64> = (0..N).map(|_| { let y = C + s * rng.normal(); if y > C { w_t(y) } else { 0.0 } }).collect();
    let (est_t, se_t) = summary(&wt);
    println!("wrong: thin proposal run: estimate {:.6} per million, printed se {:.6}", est_t * 1e6, se_t * 1e6);
    println!("try: line at c = 6, shift 6: rel se {:.2}%; P(X > 6) = {:.4} per billion",
             rel_se(36f64.exp() * tail_cf(12.0), tail_cf(6.0), N) * 100.0, tail_cf(6.0) * 1e9);
    for lam2 in [3.0_f64, 7.0] {
        let m2l = simpson(|y| f(y) * f(y) / (lam2 * (-lam2 * (y - C)).exp()), C, C + 30.0, 20000);
        println!("try: exponential rate {:.0}: rel se {:.4}%", lam2, rel_se(m2l, p, N) * 100.0);
    }

    assert!((p_simp / p - 1.0).abs() < 1e-9, "continued fraction vs integration");
    assert!((m2_simp / m2_shift(C) - 1.0).abs() < 1e-8, "completed square vs integration");
    assert!((est_n - p).abs() < 4.0 * se_n, "simulation, proposal A, vs exact");
    assert!((est_e - p).abs() < 4.0 * se_e, "simulation, proposal B, vs exact");
    assert!((se_e / est_e / rel_se(m2_e, p, N) - 1.0).abs() < 0.1, "run's error bar vs the variance formula");
    assert!(parts[3] > 1e6 * parts[1], "thin tails: the second moment explodes");
    println!("ALL CHECKS PASS");
}
