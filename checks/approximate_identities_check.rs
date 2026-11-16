// Approximate identities -- the check behind the card.  Rust std only, no crates.
// A thermocouple moves from 20 C air into stirred 60 C tea at t = 0 s; it reads
// 1,000 times a second with 0.5 C of noise.  A centred moving average of width eps
// is convolution with the box K_eps(s) = 1/eps on |s| < eps/2.  Roads: the box's
// closed form, the moving average of the readings (midpoint sum), and Simpson's
// rule on the convolution integral.
use std::f64::consts::PI;

fn f(t: f64) -> f64 { if t < 0.0 { 20.0 } else { 60.0 + 2.0 * (2.0 * PI * t).sin() } } // true temperature, C
fn fl(t: f64) -> f64 { if t <= 0.0 { 20.0 } else { f(t) } } // f with its left limit at the jump
fn big_f(t: f64) -> f64 { if t < 0.0 { 20.0 * t } else { 60.0 * t - (2.0 * PI * t).cos() / PI + 1.0 / PI } }
fn boxavg(x: f64, e: f64) -> f64 { (big_f(x + e / 2.0) - big_f(x - e / 2.0)) / e } // road 1: closed form
fn sinc(u: f64) -> f64 { (PI * u).sin() / (PI * u) }

fn simpson(g: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut acc = 0.0;
    for i in 1..n { acc += (if i % 2 == 1 { 4.0 } else { 2.0 }) * g(a + i as f64 * h); }
    (g(a) + g(b) + acc) * h / 3.0
}

// road 3: integral of K(s) f(x - s), split at the jump s = x
fn conv(k: &dyn Fn(f64) -> f64, lo: f64, hi: f64, x: f64, n: usize) -> f64 {
    if !(lo < x && x < hi) { return simpson(&|s| k(s) * f(x - s), lo, hi, n); }
    simpson(&|s| k(s) * f(x - s), lo, x, n) + simpson(&|s| k(s) * fl(x - s), x, hi, n)
}

// road 2: average of the clean readings inside the window
fn midpoint(x: f64, e: f64) -> f64 {
    let n = (e * 1000.0).round() as i64;
    let k0 = ((x - e / 2.0) * 1000.0).round() as i64;
    let mut acc = 0.0;
    for k in 0..n { acc += f(((k0 + k) as f64 + 0.5) / 1000.0); }
    acc / n as f64
}

// integral of |box average - f| over the record -1..2 s
fn l1_gap(e: f64) -> f64 {
    let pts = [-1.0, -e / 2.0, 0.0, e / 2.0, 2.0];
    let mut acc = 0.0; // left of 0, the left limit 20 C
    for i in 0..4 { acc += simpson(&|x| (boxavg(x, e) - if i < 2 { fl(x) } else { f(x) }).abs(), pts[i], pts[i + 1], 4000); }
    acc
}

struct Rng(u64); // SplitMix64, seed 2026
impl Rng {
    fn uniform(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
    fn noise(&mut self) -> f64 { // sd exactly 0.5 C
        let mut acc = 0.0;
        for _ in 0..12 { acc += self.uniform(); }
        0.5 * (acc - 6.0)
    }
}

fn join(v: &[f64]) -> String { v.iter().map(|x| format!("{:.2}", x)).collect::<Vec<_>>().join(" ") }

fn main() {
    let e = 0.1;
    println!("signal: 20 C before 0 s, 60 + 2 sin(2 pi t) C after; box width eps = 0.1 s");
    let (b1, b2) = (boxavg(0.25, e), midpoint(0.25, e));
    let b3 = conv(&|_s| 1.0 / e, -e / 2.0, e / 2.0, 0.25, 2000);
    let bias_est = -2.0 * (2.0 * PI).powi(2) * e * e / 24.0; // f'' * eps^2 / 24 at the peak
    println!("t=0.25 s: true 62.000000  closed {:.6}  100 readings {:.6}  simpson {:.6}", b1, b2, b3);
    println!("t=0.25 s: gap {:.6}  curvature estimate f''*eps^2/24 {:.6}", b1 - 62.0, bias_est);
    assert!((b1 - b2).abs() < 1e-4 && (b1 - b3).abs() < 1e-9);
    assert!(((b1 - 62.0) - bias_est).abs() < 0.001);
    let (j1, j2) = (boxavg(0.0, e), midpoint(0.0, e));
    let jf = 40.0 + (1.0 - (PI * e).cos()) / (PI * e);
    println!("t=0 s jump: left 20  right 60  closed {:.6}  100 readings {:.6}  formula 40+(1-cos(pi eps))/(pi eps) {:.6}", j1, j2, jf);
    assert!((j1 - j2).abs() < 1e-4 && (j1 - jf).abs() < 1e-9);

    println!("eps sweep: eps s | gap at 0.25 s | average at 0 s | worst gap | L1 gap on record C*s | L1/eps");
    for &ep in &[0.2, 0.1, 0.05, 0.025, 0.0125] {
        let l = l1_gap(ep);
        let worst = boxavg(0.0, ep) - 20.0; // just left of the jump
        let mut grid: f64 = 0.0;
        let mut xi = -10000;
        while xi <= 20000 { let x = xi as f64 / 1e4; grid = grid.max((boxavg(x, ep) - f(x)).abs()); xi += 7; }
        println!("  {:.4} | {:.6} | {:.6} | {:.6} | {:.6} | {:.4}", ep, boxavg(0.25, ep) - 62.0, boxavg(0.0, ep), worst, l, l / ep);
        assert!(grid <= worst + 1e-9 && worst > 20.0); // the worst gap never falls below 20 C
        assert!((l - (10.0 * ep + 8.0 / PI * (1.0 - sinc(ep)))).abs() < 1e-6); // jump part J*eps/4 plus the swing part
    }

    println!("noise: one reading sd 0.5 C; mean of n readings sd 0.5/sqrt(n)");
    for &ep in &[0.025, 0.05, 0.1, 0.2, 0.4] {
        let n = (ep * 1000.0f64).round() as i64;
        println!("  eps {:.3} s: n {:3}  noise sd {:.4}  bias at peak {:.4}", ep, n, 0.5 / (n as f64).sqrt(), 2.0 * (1.0 - sinc(ep)));
    }
    let mut rng = Rng(2026);
    let mut means = Vec::new();
    for _ in 0..2000 { let mut a = 0.0; for _ in 0..100 { a += rng.noise(); } means.push(a / 100.0); }
    let mut m = 0.0; for x in &means { m += x; } m /= 2000.0;
    let mut v = 0.0; for x in &means { v += (x - m).powi(2); }
    let sd = (v / 1999.0).sqrt();
    println!("simulated: 2000 windows of 100 readings, sd of the window mean {:.4} (theory 0.0500)", sd);
    assert!((sd - 0.05).abs() < 4.0 * 0.05 / (2.0f64 * 1999.0).sqrt());
    let noisy: Vec<f64> = (200..300).map(|k| f((k as f64 + 0.5) / 1000.0) + rng.noise()).collect();
    let mut a = 0.0; for x in &noisy { a += x; }
    println!("one noisy run: reading at 0.2495 s {:.4}  moving average at 0.25 s {:.4}", noisy[49], a / 100.0);
    let mut errs: Vec<f64> = (0..100).map(|k| (noisy[k] - f((k as f64 + 200.5) / 1000.0)).abs()).collect();
    errs.sort_by(|x, y| x.partial_cmp(y).unwrap());
    println!("  its 100 readings: median error {:.4}  largest {:.4}  average's error {:.4}", (errs[49] + errs[50]) / 2.0, errs[99], (a / 100.0 - 62.0).abs());
    println!("faster stirring, 5 Hz swing: peak 62 reads {:.6}", 60.0 + 2.0 * sinc(0.5));

    println!("what breaks, at t = 0.25 s, eps = 0.1 s unless said");
    println!("  weights add to 0.9: {:.6}  limit {:.6}", 0.9 * b1, 0.9 * 62.0);
    let tr = conv(&|_s| 1.0 / e, 0.0, e, 0.25, 2000);
    println!("  trailing window (past 0.1 s only): {:.6}  gap {:.6}  at the jump {:.6}", tr, tr - 62.0, (big_f(0.0) - big_f(-e)) / e);
    assert!((tr - (60.0 + ((0.3 * PI).cos() - (0.5 * PI).cos()) / (0.1 * PI))).abs() < 1e-9);
    let leak = 0.9 * 62.0 + 0.1 * (big_f(0.75) - big_f(-0.25));
    println!("  10% of weight on a fixed 1 s average: limit {:.6}", leak);

    // density of smooth signals: the bump eta(u) = exp(-1/(1-u^2))/Z, half-width eps
    let raw = |u: f64| if u.abs() < 1.0 { (-1.0 / (1.0 - u * u)).exp() } else { 0.0 };
    let z = simpson(&raw, -1.0, 1.0, 4000);
    let m1 = simpson(&|u: f64| u.abs() * raw(u), -1.0, 1.0, 4000) / z;
    assert!((z - simpson(&raw, -1.0, 1.0, 2000)).abs() < 1e-9);
    println!("bump: Z {:.6}  mean distance m1 {:.6}", z, m1);
    for &ep in &[0.05, 0.01] {
        let sm = |x: f64| conv(&|s| raw(s / ep) / (z * ep), -ep, ep, x, 200);
        let gap = simpson(&|x| (sm(x) - fl(x)).abs(), -ep, 0.0, 200) + simpson(&|x| (sm(x) - f(x)).abs(), 0.0, ep, 200);
        println!("  eps {:.2} s: L1 gap near the jump {:.6} C*s  predicted 40*m1*eps {:.6}", ep, gap, 40.0 * m1 * ep);
        assert!((gap - 40.0 * m1 * ep).abs() < 0.001 * 40.0 * m1 * ep); // the window around the jump
    }

    let ts: Vec<f64> = (0..14).map(|i| ((-0.15 + 0.05 * i as f64) * 100.0).round() / 100.0).collect();
    println!("chart t: {}", join(&ts));
    println!("chart f: {}", join(&ts.iter().map(|&t| f(t)).collect::<Vec<_>>()));
    println!("chart box 0.1: {}", join(&ts.iter().map(|&t| boxavg(t, 0.1)).collect::<Vec<_>>()));
    println!("chart box 0.02: {}", join(&ts.iter().map(|&t| boxavg(t, 0.02)).collect::<Vec<_>>()));
    println!("ALL CHECKS PASS");
}
