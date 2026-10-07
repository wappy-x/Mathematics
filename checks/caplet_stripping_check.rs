// Caplet stripping -- the same check as caplet_stripping_check.py, in Rust, std only.
// Road 1 differences cap prices and inverts Black's formula by bisection; road 2
// prices each caplet by integrating its payoff over the bell curve and solves each
// whole cap by the secant method.  Rust has no erf: N(x) is Simpson's rule.
use std::f64::consts::PI;

const L: f64 = 1_000_000.0; // notional
const TAU: f64 = 0.25; // accrual, years
const K: f64 = 0.05; // strike
const FLAT: [f64; 8] = [0.26, 0.28, 0.295, 0.305, 0.308, 0.306, 0.300, 0.294];

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }
fn simpson<G: Fn(f64) -> f64>(f: G, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    s * h / 3.0
}
fn n_cdf(x: f64) -> f64 { 0.5 + simpson(phi, 0.0, x.max(-10.0).min(10.0), 2000) }
fn d(t: f64) -> f64 { (-(0.04 + 0.005 * t) * t).exp() } // discount curve
fn tfix(i: usize) -> f64 { 0.25 * (i + 1) as f64 } // fixing dates
fn fwd(i: usize) -> f64 { let t = tfix(i); (d(t) / d(t + TAU) - 1.0) / TAU }

fn black(i: usize, s: f64) -> f64 {
    let (t, f) = (tfix(i), fwd(i));
    let v = s * t.sqrt();
    let d1 = ((f / K).ln() + 0.5 * v * v) / v;
    L * TAU * d(t + TAU) * (f * n_cdf(d1) - K * n_cdf(d1 - v))
}
fn by_integral(i: usize, s: f64) -> f64 {
    let (t, f) = (tfix(i), fwd(i));
    let v = s * t.sqrt();
    let zk = ((K / f).ln() + 0.5 * v * v) / v; // below zk the caplet pays nothing
    let pay = |z: f64| (f * (-0.5 * v * v + v * z).exp() - K) * phi(z);
    L * TAU * d(t + TAU) * simpson(pay, zk.max(-10.0), 10.0, 2000)
}
fn floor_(i: usize) -> f64 { L * TAU * d(tfix(i) + TAU) * (fwd(i) - K).max(0.0) }
fn ceil_(i: usize) -> f64 { L * TAU * d(tfix(i) + TAU) * fwd(i) }
fn bisect<G: Fn(f64) -> f64>(f: G, mut lo: f64, mut hi: f64) -> f64 {
    for _ in 0..100 {
        let m = 0.5 * (lo + hi);
        if f(m) > 0.0 { hi = m } else { lo = m }
    }
    0.5 * (lo + hi)
}
fn strip(flat: &[f64; 8]) -> (Vec<f64>, Vec<f64>, Vec<f64>) {
    let caps: Vec<f64> = (0..8).map(|k| (0..=k).map(|i| black(i, flat[k])).sum()).collect();
    let (mut sig, mut parts) = (Vec::new(), Vec::new());
    for k in 0..8 {
        let p = caps[k] - if k > 0 { caps[k - 1] } else { 0.0 };
        parts.push(p);
        sig.push(if p > floor_(k) { bisect(|s| black(k, s) - p, 1e-6, 5.0) } else { f64::NAN });
    }
    (caps, parts, sig)
}
fn join(v: &[f64], f: impl Fn(f64) -> String) -> String { v.iter().map(|x| f(*x)).collect::<Vec<_>>().join(" ") }

fn main() {
    let (caps, parts, s1) = strip(&FLAT);
    let mut s2: Vec<f64> = Vec::new(); // road 2: whole cap, secant
    for k in 0..8 {
        let target: f64 = (0..=k).map(|i| by_integral(i, FLAT[k])).sum();
        let known: f64 = (0..k).map(|i| by_integral(i, s2[i])).sum();
        let g = |s: f64| known + by_integral(k, s) - target;
        let (mut a, mut b) = (0.20, 0.40);
        let (mut ga, mut gb) = (g(a), g(b));
        while (b - a).abs() > 1e-13 {
            let nb = b - gb * (b - a) / (gb - ga);
            a = b; ga = gb; b = nb; gb = g(b);
        }
        s2.push(b);
    }
    println!(" k  fix  pay  D(pay)     F %   flat %   cap price $  caplet $   floor $   ceiling $  road1 %  road2 %");
    for k in 0..8 {
        println!("{:>2} {:4.2} {:4.2} {:.5} {:.4} {:6.2} {:12.2} {:9.2} {:9.2} {:11.2} {:8.4} {:8.4}",
            k + 1, tfix(k), tfix(k) + TAU, d(tfix(k) + TAU), 100.0 * fwd(k), 100.0 * FLAT[k],
            caps[k], parts[k], floor_(k), ceil_(k), 100.0 * s1[k], 100.0 * s2[k]);
    }
    let scan: Vec<f64> = (1..7).map(|j| black(7, 0.10 * j as f64)).collect();
    println!("caplet 8 price at vol 10..60%: {}", join(&scan, |p| format!("{:.2}", p)));
    let mut fb = FLAT; fb[6] = 0.301; // cap 7 quote up 0.1 vol point
    let bumped = strip(&fb).2;
    let dv: Vec<f64> = (0..8).map(|i| 100.0 * (bumped[i] - s1[i])).collect();
    println!("cap 7 quote +0.10 pt, caplet vol change in pts: {}", join(&dv, |x| format!("{:+.4}", x)));
    let vg: Vec<f64> = (0..7).map(|i| {
        let (t, f) = (tfix(i), fwd(i));
        L * TAU * d(t + TAU) * f * t.sqrt() * phi(((f / K).ln() + 0.5 * FLAT[6].powi(2) * t) / (FLAT[6] * t.sqrt()))
    }).collect();
    let approx = (0..7).map(|i| vg[i] * s1[i]).sum::<f64>() / vg.iter().sum::<f64>();
    println!("cap 7: vega-weighted caplet vol {:.4} % against flat {:.4} %", 100.0 * approx, 100.0 * FLAT[6]);

    let cap8 = |s: f64| (0..8).map(|i| black(i, s)).sum::<f64>();
    let lowest = bisect(|s| cap8(s) - caps[6] - floor_(7), 0.01, FLAT[7]);
    let low20 = cap8(0.20) - caps[6];
    println!("lowest cap 8 flat vol with a solution {:.4} %", 100.0 * lowest);
    println!("cap 8 quoted at 20%: caplet 8 must be worth {:.2}, below its floor {:.2}", low20, floor_(7));
    let rebuilt: f64 = (0..8).map(|i| by_integral(i, s1[i])).sum(); // cap 8 rebuilt, road 2 pricer
    println!("cap 8 rebuilt from the eight caplet vols by integral {:.2}", rebuilt);
    println!("wrong: flat 30% on caplet 7 alone {:.2}, right {:.2}", black(6, 0.30), parts[6]);
    println!("wrong: vols subtracted, 8 x 29.4 - 7 x 30.0 = {:.4} %", 100.0 * (8.0 * FLAT[7] - 7.0 * FLAT[6]));
    println!("try: all flat 30%, caplet vols {}", join(&strip(&[0.30; 8]).2, |s| format!("{:.2}", 100.0 * s)));
    let mut f31 = FLAT; f31[7] = 0.31;
    println!("try: cap 8 at 31%, caplet 8 vol {:.4} %", 100.0 * strip(&f31).2[7]);
    println!("chart, flat vol %   {}", join(&FLAT, |s| format!("{:.2}", 100.0 * s)));
    println!("chart, caplet vol % {}", join(&s1, |s| format!("{:.2}", 100.0 * s)));

    assert!((0..8).all(|i| (s1[i] - s2[i]).abs() < 1e-7), "two roads give the same eight vols");
    assert!((s1[0] - FLAT[0]).abs() < 1e-9, "a one-caplet cap: its flat vol is its caplet vol");
    assert!((0..6).all(|i| (bumped[i] - s1[i]).abs() < 1e-12), "earlier caplets untouched");
    assert!(bumped[6] - s1[6] > 1e-3, "the bumped cap's own caplet moves");
    assert!(scan.windows(2).all(|w| w[0] < w[1]), "caplet price rises with vol: one root at most");
    assert!(low20 < floor_(7), "a 20% quote leaves caplet 8 below its zero-vol floor");
    assert!((rebuilt - caps[7]).abs() < 1e-6, "road 2 pricer rebuilds the quoted cap from road 1 vols");
    assert!((approx - FLAT[6]).abs() < 0.005, "flat vol is close to the vega-weighted caplet vols");
    println!("ALL CHECKS PASS");
}
