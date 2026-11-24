// Delay equations -- the same check as the Python, in Rust.  No crates.  Shower: x is the
// water temperature above target (C) leaving the valve; the skin feels it tau seconds
// later, and the hand turns the valve at the rate x'(t) = -k x(t - tau), with k = 1 per s.
use std::f64::consts::{E, PI};
fn root(k: f64, tau: f64) -> (f64, f64) {          // Newton on f(lam) = lam + k e^(-lam tau) = 0
    let (mut re, mut im) = (0.0, 1.2);
    for _ in 0..60 {
        let (er, ei) = ((-re * tau).exp() * (im * tau).cos(), -(-re * tau).exp() * (im * tau).sin());
        let (fr, fi, dr, di) = (re + k * er, im + k * ei, 1.0 - k * tau * er, -k * tau * ei);
        let d2 = dr * dr + di * di;                 // Newton step: lam - f / f', in complex arithmetic
        (re, im) = (re - (fr * dr + fi * di) / d2, im - (fi * dr - fr * di) / d2);
    }
    (re, im)
}
fn run(tau: f64, t_end: f64, m: usize) -> (Vec<f64>, f64) {  // trapezoid stepper on a history grid
    let (h, mut x) = (tau / m as f64, vec![1.0; m + 1]);
    for _ in 0..(t_end / h).round() as usize { let n = x.len(); x.push(x[n - 1] - h * (x[n - 1 - m] + x[n - m]) / 2.0) }
    (x[m..].to_vec(), h)
}
fn yn(c: bool) -> &'static str { if c { "yes" } else { "no" } }
fn at(x: &[f64], h: f64, t: f64) -> f64 { let i = (t / h) as usize; x[i] + (x[i + 1] - x[i]) * (t / h - i as f64) }   // read between grid points
fn r4(v: f64) -> f64 { (v * 1e4).round() / 1e4 + 0.0 }
fn peaks(x: &[f64], h: f64) -> Vec<(f64, f64)> { (1..x.len() - 1).filter(|&i| x[i - 1] < x[i] && x[i] >= x[i + 1]).map(|i| (i as f64 * h, x[i])).collect() }
fn steps(n: usize, mut p: Vec<f64>) -> Vec<f64> {  // method of steps, tau = 1: exact polynomial pieces
    let mut ends = vec![];                          // p = piece on [j, j+1] as coefficients of s = t - j
    for _ in 0..n {
        let end: f64 = p.iter().sum();
        ends.push(end);
        p = std::iter::once(end).chain(p.iter().enumerate().map(|(m, c)| -c / (m as f64 + 1.0))).collect();
    }
    ends.iter().map(|&v| r4(v)).collect()
}
fn join(v: &[f64], d: usize) -> String { v.iter().map(|x| format!("{:.*}", d, x)).collect::<Vec<_>>().join(", ") }
fn hutch(tau: f64, t_end: f64) -> (Vec<f64>, f64) { // N' = r N (1 - N(t - tau)/K), Heun on a grid
    let (r, k, m) = (0.5, 1000.0, 2000usize);
    let (h, mut n) = (tau / m as f64, vec![900.0; m + 1]);
    for _ in 0..(t_end / h).round() as usize {
        let l = n.len();
        let f = r * n[l - 1] * (1.0 - n[l - 1 - m] / k); let p = n[l - 1] + h * f;
        n.push(n[l - 1] + h / 2.0 * (f + r * p * (1.0 - n[l - m] / k)));
    }
    (n[m..].to_vec(), h)
}
fn main() {
    let (ex, (xs, h)) = (steps(4, vec![1.0, -1.0]), run(1.0, 4.0, 1000));
    let num: Vec<f64> = (1..5).map(|j| r4(xs[(j as f64 / h).round() as usize])).collect();
    println!("method of steps, tau = 1: x(1..4) = {}", join(&ex, 4));
    println!("trapezoid stepper,        x(1..4) = {}", join(&num, 4));
    assert!(ex == num && ex[1] == -0.5);
    for tau in [1.0, PI / 2.0, 2.0] {
        let ((re, im), (xc, hc)) = (root(1.0, tau), run(tau, 21.0, 1000));
        let p = 2.0 * PI / im;
        let ch: Vec<f64> = (0..21).map(|j| (at(&xc, hc, j as f64) * 100.0).round() / 100.0 + 0.0).collect();
        println!("chart tau {:.4}: {}", tau, join(&ch, 2));
        let (x2, h2) = run(tau, 60.0, 2000);
        let ((t1, a1), (t2, a2)) = { let pk = peaks(&x2, h2); (pk[3], pk[4]) };
        println!("tau = {:.4}: root {:+.4} {:+.4}i, period {:.4} s, peak ratio {:.4}; simulated period {:.4} s, ratio {:.4}",
                 tau, r4(re), im, p, (re * p).exp(), t2 - t1, a2 / a1);
        assert!((t2 - t1 - p).abs() < 2e-3 && (a2 / a1 - (re * p).exp()).abs() < 2e-3);
    }
    let (mut lo, mut hi) = (1.0, 2.0);              // bisection: the delay where the root's real part is 0
    for _ in 0..50 { let mid = (lo + hi) / 2.0; if root(1.0, mid).0 < 0.0 { lo = mid } else { hi = mid } }
    println!("Hopf delay by bisection {:.4} s; pi/2 = {:.4}; lam = i solves it at tau = pi/2: {}", lo, PI / 2.0,
             yn((PI / 2.0).cos().abs() + (1.0 - (PI / 2.0).sin()).abs() < 1e-12));
    assert!((lo - PI / 2.0).abs() < 1e-6);
    let cross: Vec<bool> = [0.30, 0.45].iter().map(|&t| run(t, 30.0, 1000).0.iter().any(|&v| v < 0.0)).collect();
    println!("oscillation starts at k tau = 1/e = {:.4}: crosses zero at tau 0.30? {}; at 0.45? {}", 1.0 / E, yn(cross[0]), yn(cross[1]));
    assert!(cross == vec![false, true]);
    let ((n2, _), (n4, h4)) = (hutch(2.0, 120.0), hutch(4.0, 400.0));
    let tail = &n4[n4.len() / 2..];
    let (mn, mx) = tail.iter().fold((f64::MAX, f64::MIN), |(a, b), &v| (a.min(v), b.max(v)));
    let pk = peaks(&n4, h4);
    println!("Hutchinson r = 0.5/day, K = 1000: tau 2 d (r tau = 1) N(120) = {:.1}; tau 4 d (r tau = 2) swings {:.1} to {:.1}, period {:.2} d",
             n2[n2.len() - 1], mn, mx, pk[pk.len() - 1].0 - pk[pk.len() - 2].0);
    assert!((n2[n2.len() - 1] - 1000.0).abs() < 0.1 && mx > 1500.0);
    println!("mistake 1, drop the delay: x(2) = {:.4}, not {:.4}", (-2.0f64).exp(), ex[1]);
    println!("mistake 2, history 0 with only x(0) = 1: x(2) = {:.4}", steps(2, vec![1.0])[1]);
    println!("mistake 3, delay as half a swing: threshold pi = {:.4} s, but tau = 2 already grows at {:+.4} per s", PI, root(1.0, 2.0).0);
    println!("ALL CHECKS PASS");
}
