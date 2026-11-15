// Distributions -- the same check as the Python, in Rust.  No crates.
// A hammer tap of impulse J = 0.5 N s (illustrative) is read through a smooth
// probe: a bump centred at c = 1 ms, half-width a = 5 ms, height 1 at its centre.
// Roads: the reading by quadrature against the limit J*phi(0); the derivative
// moved onto the probe against the direct reading; exact integer sums on a grid.
use std::f64::consts::PI;
const J: f64 = 0.5;
const C: f64 = 0.001;
const A: f64 = 0.005;

fn bump(t: f64, c: f64, a: f64) -> f64 {        // the probe: smooth, zero off (c-a, c+a)
    let u = (t - c) / a;
    if u.abs() < 1.0 { (1.0 - 1.0 / (1.0 - u * u)).exp() } else { 0.0 }
}
fn phi(t: f64) -> f64 { bump(t, C, A) }
fn dphi(t: f64) -> f64 {                        // its slope, by the chain rule
    let u = (t - C) / A;
    if u.abs() < 1.0 { phi(t) * (-2.0 * u / (A * (1.0 - u * u).powi(2))) } else { 0.0 }
}
fn tap(t: f64, w: f64) -> f64 {                 // half-cosine force, width w, area J
    if t.abs() < w / 2.0 { J * PI / (2.0 * w) * (PI * t / w).cos() } else { 0.0 }
}
fn mom(t: f64, w: f64) -> f64 {                 // momentum delivered so far: its slope is tap
    if t <= -w / 2.0 { return 0.0 }
    if t >= w / 2.0 { return J }
    J * (1.0 + (PI * t / w).sin()) / 2.0
}
fn simpson(g: &dyn Fn(f64) -> f64, lo: f64, hi: f64) -> f64 {   // Simpson's rule, n = 2000
    let n = 2000;
    let h = (hi - lo) / n as f64;
    let mut s = g(lo) + g(hi);
    for k in 1..n { s += (if k % 2 == 1 { 4.0 } else { 2.0 }) * g(lo + k as f64 * h) }
    s * h / 3.0
}
fn join(v: &[String], sep: &str) -> String { v.join(sep) }

fn main() {
    let limit = J * phi(0.0);
    println!("probe: centre 1 ms, half-width 5 ms, u at the tap = {:.1}, phi(0) = {:.6}", (0.0 - C) / A, phi(0.0));
    println!("ideal tap reads J*phi(0) = {:.6} N s", limit);
    let mut gaps = vec![];
    for (name, w) in [("4 ms", 0.004f64), ("2 ms", 0.002), ("1 ms", 0.001), ("0.5 ms", 0.0005)] {
        let r = simpson(&|t| tap(t, w) * phi(t), -w / 2.0, w / 2.0);
        gaps.push(limit - r);
        println!("width {:>6}: peak force {:7.2} N, reading {:.6} N s, gap {:.7}, log10 gap {:.3}",
                 name, tap(0.0, w), r, limit - r, (limit - r).log10());
    }
    let ratios: Vec<f64> = (0..3).map(|i| gaps[i] / gaps[i + 1]).collect();
    println!("gap ratio per halving of the width: {}",
             join(&ratios.iter().map(|q| format!("{:.3}", q)).collect::<Vec<_>>(), ", "));

    let w = 0.001;                               // the 1 ms tap, read two ways
    let direct = simpson(&|t| tap(t, w) * phi(t), -w / 2.0, w / 2.0);
    let moved = -(simpson(&|t| mom(t, w) * dphi(t), -w / 2.0, w / 2.0)
                  + simpson(&|t| J * dphi(t), w / 2.0, C + A));
    let step = -simpson(&|t| J * dphi(t), 0.0, C + A);
    println!("1 ms tap read directly, integral of f*phi: {:.9} N s", direct);
    println!("its momentum p, derivative moved onto the probe, -integral of p*phi': {:.9} N s", moved);
    println!("ideal step of height J, -integral of J*phi' from 0: {:.9} N s", step);
    println!("bound: reading {:.6} <= (integral of |f|) x (largest phi) = {:.6}", direct, J);
    let far = simpson(&|t| tap(t, w) * bump(t, 0.010, A), -w / 2.0, w / 2.0);
    println!("probe moved to centre 10 ms, clear of the tap: reading {:.6} N s", far);

    let mut grid = vec![];
    for n in [10i64, 100, 1000] {                // grid rehearsal: step h = a/n
        let h = A / n as f64;
        let (mut fwd, mut back) = (0.0, 0.0);
        for k in (-n - 2)..(2 * n + 2) {         // covers the probe's support
            let p0 = if k >= 0 { J } else { 0.0 };
            let p1 = if k + 1 >= 0 { J } else { 0.0 };
            fwd += (p1 - p0) * phi(k as f64 * h);
            back -= p0 * (phi(k as f64 * h) - phi((k - 1) as f64 * h));
        }
        grid.push((h, fwd, back));
        println!("grid n = {:4}, h = {:3} us: difference reading {:.9}, moved onto probe {:.9}, gap {:.7}",
                 n, 5000 / n, fwd, back, limit - fwd);
    }
    let pv = [3i64, 1, 4, 1, 5, 9, 2, 6, 5, 3, 5, 8];   // any 12 samples
    let qv = [0i64, 1, 3, 6, 8, 9, 8, 6, 3, 1, 0, 0];   // an integer probe, zero at both ends
    let left: i64 = (0..11).map(|k| (pv[k + 1] - pv[k]) * qv[k]).sum();
    let right: i64 = -(1..12).map(|k| pv[k] * (qv[k] - qv[k - 1])).sum::<i64>();
    println!("12 integer samples: sum of differences x probe = {}; minus sum of samples x probe differences = {}",
             left, right);

    for (name, eps) in [("1 ms", 0.001f64), ("0.1 ms", 0.0001), ("0.01 ms", 0.00001)] {
        let (lo, hi) = ((-eps).max(-w / 2.0), eps.min(w / 2.0));   // shrink the probe, keep phi(0) = 1
        let r = simpson(&|t| tap(t, w) * bump(t, 0.0, eps), lo, hi);
        println!("probe half-width {:>7}: value at 0 is {:.3}, 1 ms tap reads {:.6} N s", name, bump(0.0, 0.0, eps), r);
    }

    println!("mistake 1, minus sign dropped: {:.6} N s, not {:.6}", -step, limit);
    let ramp = |t: f64| (t - C + A) / (2.0 * A);  // smooth, but 1 at the window's end
    let rd = simpson(&|t| tap(t, w) * ramp(t), -w / 2.0, w / 2.0);
    let rm = -(simpson(&|t| mom(t, w) / (2.0 * A), -w / 2.0, w / 2.0) + J * (C + A - w / 2.0) / (2.0 * A));
    println!("mistake 2, ramp probe, 1 at the window's end: direct {:.6}, moved {:.6}, gap {:.6} N s", rd, rm, rd - rm);
    let edge = C + A;                            // a box probe: 1 up to 6 ms, then 0
    let bx: Vec<f64> = [edge - 0.0001, edge, edge + 0.0001].iter().map(|&t0| mom(edge - t0, 0.0001)).collect();
    println!("mistake 3, box probe, 0.1 ms tap at 5.9, 6.0, 6.1 ms: {}",
             join(&bx.iter().map(|b| format!("{:.6}", b)).collect::<Vec<_>>(), ", "));
    println!("mistake 4, force at t = 0 of the 0.5 ms tap: {:.2} N, doubling as the width halves", tap(0.0, 0.0005));
    let ts: Vec<f64> = (-10..15).map(|k| k as f64 * 0.5).collect();
    println!("figure, t ms: {}", join(&ts.iter().map(|t| format!("{}", t)).collect::<Vec<_>>(), " "));
    println!("figure, probe: {}", join(&ts.iter().map(|t| format!("{:.2}", phi(t / 1000.0))).collect::<Vec<_>>(), " "));
    println!("figure, 4 ms tap / peak: {}", join(&ts.iter()
             .map(|t| format!("{:.2}", tap(t / 1000.0, 0.004) / tap(0.0, 0.004))).collect::<Vec<_>>(), " "));

    assert!(ratios.iter().all(|&q| 3.9 < q && q < 4.2));             // gap falls as width squared
    assert!((direct - moved).abs() < 1e-9 && (step - limit).abs() < 1e-9);   // moved derivative = reading
    assert!(grid.iter().all(|&(h, f, b)| (f - J * phi(-h)).abs() < 1e-12 && (f - b).abs() < 1e-12));
    assert!(left == right);                                          // summation by parts, exact
    assert!((rd - rm - J * ramp(C + A)).abs() < 1e-9);               // the boundary term J*psi(end)
    assert!(far == 0.0 && bx == vec![0.5, 0.25, 0.0]);
    println!("ALL CHECKS PASS");
}
