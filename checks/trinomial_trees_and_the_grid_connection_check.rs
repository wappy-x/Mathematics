// Trinomial trees and the grid connection -- the same check as the Python, in
// Rust.  No crates.  Nothing here already knows an answer: the bell-curve area
// is built by adding thin slices (Simpson's rule), and every price is a loop.
// Acme: S = 100, K = 100, r = 5 percent, q = 2 percent, sigma = 20 percent,
// T = 1 year.  Compile: rustc --edition 2021 -O trinomial_trees_and_the_grid_connection_check.rs
use std::f64::consts::PI;

const S: f64 = 100.0; const K: f64 = 100.0; const R: f64 = 0.05;
const Q: f64 = 0.02; const SIG: f64 = 0.20; const T: f64 = 1.0;

fn lam() -> f64 { 3.0_f64.sqrt() }           // the stretch: dx = lam * sigma * sqrt(dt)

fn bell(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }   // bell-curve height at x

fn ncdf(x: f64) -> f64 {                     // area to the left of x, by Simpson's rule
    if x < 0.0 { return 1.0 - ncdf(-x); }
    let (n, h) = (4000, x / 4000.0);
    let mut total = bell(0.0) + bell(x);
    for i in 1..n { total += (if i % 2 == 1 { 4.0 } else { 2.0 }) * bell(i as f64 * h); }
    0.5 + total * h / 3.0
}

fn black_scholes_call() -> f64 {             // road C: the closed form, for comparison only
    let vt = SIG * T.sqrt();
    let d1 = ((S / K).ln() + (R - Q + 0.5 * SIG * SIG) * T) / vt;
    S * (-Q * T).exp() * ncdf(d1) - K * (-R * T).exp() * ncdf(d1 - vt)
}

// three branch weights: mean and variance matched.  Returns dt, dx, nu, p_u, p_m, p_d.
fn weights(n: usize, lam: f64, tilt_on: bool) -> (f64, f64, f64, f64, f64, f64) {
    let dt = T / n as f64;
    let dx = lam * SIG * dt.sqrt();
    let nu = R - Q - 0.5 * SIG * SIG;
    let spread = (SIG * SIG * dt + nu * nu * dt * dt) / (dx * dx);      // p_u + p_d
    let tilt = if tilt_on { nu * dt / dx } else { 0.0 };                // p_u - p_d
    (dt, dx, nu, 0.5 * (spread + tilt), 1.0 - spread, 0.5 * (spread - tilt))
}

fn payoffs(n: usize, dx: f64) -> Vec<f64> {  // the payoff at every ending node, low to high
    (0..2 * n + 1).map(|k| (S * (dx * (k as f64 - n as f64)).exp() - K).max(0.0)).collect()
}

fn tree_backward(n: usize, lam: f64, tilt_on: bool, disc: Option<f64>) -> f64 {   // road A
    let (dt, dx, _, pu, pm, pd) = weights(n, lam, tilt_on);
    let step = match disc { Some(x) => x, None => (-R * dt).exp() };
    let mut v = payoffs(n, dx);
    for _ in 0..n {
        v = (0..v.len() - 2).map(|j| step * (pd * v[j] + pm * v[j + 1] + pu * v[j + 2])).collect();
    }
    v[0]
}

// road B: the tree's own ending spread of prices.  Returns price, weights, ends, average end.
fn tree_forward(n: usize, lam: f64) -> (f64, Vec<f64>, Vec<f64>, f64) {
    let (_, dx, _, pu, pm, pd) = weights(n, lam, true);
    let mut dist: Vec<f64> = vec![1.0];
    for _ in 0..n {
        let mut nxt = vec![0.0; dist.len() + 2];
        for (j, w) in dist.iter().enumerate() {
            nxt[j] += w * pd; nxt[j + 1] += w * pm; nxt[j + 2] += w * pu;
        }
        dist = nxt;
    }
    let ends: Vec<f64> = (0..dist.len()).map(|j| S * (dx * (j as f64 - n as f64)).exp()).collect();
    let pv: f64 = dist.iter().zip(ends.iter()).map(|(w, e)| w * (e - K).max(0.0)).sum();
    let mean: f64 = dist.iter().zip(ends.iter()).map(|(w, e)| w * e).sum();
    ((-R * T).exp() * pv, dist, ends, mean)
}

// road D: coefficients read off the equation itself.  Returns price, a_u, a_m, a_d, df.
fn grid_explicit(n: usize, half: usize) -> (f64, f64, f64, f64, f64) {
    let (dt, dx, nu, _, _, _) = weights(n, lam(), true);
    let a_u = dt * (0.5 * SIG * SIG / (dx * dx) + nu / (2.0 * dx));
    let a_m = 1.0 - dt * SIG * SIG / (dx * dx);
    let a_d = dt * (0.5 * SIG * SIG / (dx * dx) - nu / (2.0 * dx));
    let df = 1.0 / (1.0 + R * dt);                                     // not e^-r dt: the equation's own
    let mut v = payoffs(half, dx);
    for _ in 0..n {
        let mut nv = vec![0.0; v.len()];                               // edges held at zero
        for j in 1..v.len() - 1 { nv[j] = df * (a_d * v[j - 1] + a_m * v[j] + a_u * v[j + 1]); }
        v = nv;
    }
    (v[half], a_u, a_m, a_d, df)
}

fn crr_binomial(n: usize) -> f64 {           // two branches, for the convergence picture
    let dt = T / n as f64;
    let (u, disc) = ((SIG * dt.sqrt()).exp(), (-R * dt).exp());
    let d = 1.0 / u;
    let p = (((R - Q) * dt).exp() - d) / (u - d);
    let mut v: Vec<f64> = (0..n + 1)
        .map(|j| (S * u.powi(j as i32) * d.powi((n - j) as i32) - K).max(0.0)).collect();
    for step in (1..=n).rev() {
        v = (0..step).map(|j| disc * (p * v[j + 1] + (1.0 - p) * v[j])).collect();
    }
    v[0]
}

fn main() {
    let bs = black_scholes_call();
    let (dt3, dx3, nu3, pu3, pm3, pd3) = weights(3, lam(), true);
    let back3 = tree_backward(3, lam(), true, None);
    let (fwd3, dist3, ends3, mean3) = tree_forward(3, lam());
    let back200 = tree_backward(200, lam(), true, None);
    let (fd200, a_u, a_m, a_d, df200) = grid_explicit(200, 200);
    let (dt200, dx200, nu200, pu200, pm200, pd200) = weights(200, lam(), true);
    println!("Acme call: S {:.0}, K {:.0}, r {:.2}, q {:.2}, sigma {:.2}, T {:.0} year", S, K, R, Q, SIG, T);
    println!("road C, Black-Scholes closed form              {:12.6}", bs);
    println!("three steps: lambda {:.6}  dt {:.6}  dx {:.6}  nu {:.6}  u {:.6}  d {:.6}",
             lam(), dt3, dx3, nu3, dx3.exp(), (-dx3).exp());
    println!("three-step weights: p_u {:.6}  p_m {:.6}  p_d {:.6}  sum {:.6}", pu3, pm3, pd3, pu3 + pm3 + pd3);
    println!("three-step split: p_u + p_d {:.6}  p_u - p_d {:.6}", pu3 + pd3, pu3 - pd3);
    println!("ending nodes of the three-step tree: node, Acme price, weight, payoff");
    for j in 0..dist3.len() {
        println!("   k {:+}   {:10.6}   {:.6}   {:10.6}",
                 j as i32 - 3, ends3[j], dist3[j], (ends3[j] - K).max(0.0));
    }
    println!("road A, three-step tree, backward induction    {:12.6}", back3);
    println!("road B, three-step tree, ending sum            {:12.6}", fwd3);
    println!("three-step tree's own average ending price {:11.6}   exact S e^(r-q)T {:11.6}",
             mean3, S * ((R - Q) * T).exp());
    println!("road A, 200-step tree, backward induction      {:12.6}", back200);
    println!("road D, 200-step explicit grid                 {:12.6}", fd200);
    println!("road A, 2000-step tree                         {:12.6}", tree_backward(2000, lam(), true, None));
    println!("road D, 2000-step explicit grid                {:12.6}", grid_explicit(2000, 2000).0);
    println!("200 steps, tree weights: p_u {:.9}  p_m {:.9}  p_d {:.9}", pu200, pm200, pd200);
    println!("200 steps, grid weights: a_u {:.9}  a_m {:.9}  a_d {:.9}", a_u, a_m, a_d);
    println!("  p_u - a_u {:.9}   predicted (nu dt)^2 / (2 dx^2) {:.9}",
             pu200 - a_u, 0.5 * nu200 * nu200 * dt200 * dt200 / (dx200 * dx200));
    println!("  one step: e^-r dt {:.9}   1 / (1 + r dt) {:.9}", (-R * dt200).exp(), df200);
    println!();
    println!("convergence, cents away from 9.227006: the trinomial marches, the binomial flips");
    println!("{:>6}{:>12}{:>9}{:>12}{:>9}", "steps", "trinomial", "cents", "binomial", "cents");
    let (mut tri_cents, mut bin_cents): (Vec<f64>, Vec<f64>) = (Vec::new(), Vec::new());
    for n in 20..32 {
        let (tri, bino) = (tree_backward(n, lam(), true, None), crr_binomial(n));
        let (ct, cb) = ((tri - bs) * 100.0, (bino - bs) * 100.0);
        tri_cents.push(ct); bin_cents.push(cb);
        println!("{:>6}{:>12.6}{:>9.2}{:>12.6}{:>9.2}", n, tri, ct, bino, cb);
    }
    println!();
    println!("what breaks if a piece is dropped");
    let (pm_l1, pm_l08) = (weights(3, 1.0, true).4, weights(3, 0.8, true).4);
    let lam_min = (1.0 + nu3 * nu3 * dt3 / (SIG * SIG)).sqrt();     // where the middle weight vanishes
    println!("  the middle weight vanishes at lambda {:.6}, not at 1.000000", lam_min);
    println!("  lambda 1.00, three steps: p_m {:.6}, price {:12.6}", pm_l1, tree_backward(3, 1.0, true, None));
    println!("  lambda 0.80, three steps: p_m {:.6}, price {:12.6}", pm_l08, tree_backward(3, 0.8, true, None));
    for n in [5usize, 10, 15, 20] {
        println!("  lambda 0.80, {:>2} steps:     price {:18.6}", n, tree_backward(n, 0.8, true, None));
    }
    println!("  drift tilt dropped, 200 steps:    price {:12.6}", tree_backward(200, lam(), false, None));
    println!("  discount forgotten, 200 steps:    price {:12.6}", tree_backward(200, lam(), true, Some(1.0)));
    println!("  grid chopped to 20 nodes either side, 200 steps: price {:12.6}", grid_explicit(200, 20).0);
    assert!((back3 - fwd3).abs() < 1e-12, "backward induction must match the tree's own ending sum");
    assert!((back200 - bs).abs() < 0.01, "200-step tree lands within a cent of the closed form");
    assert!((fd200 - back200).abs() < 0.00001, "the explicit grid is the tree");
    assert!(((pu200 - a_u) - 0.5 * nu200 * nu200 * dt200 * dt200 / (dx200 * dx200)).abs() < 1e-15,
            "the gap is (nu dt)^2 / (2 dx^2)");
    assert!(weights(3, lam_min, true).4.abs() < 1e-15 && pm_l1 < 0.0 && 0.0 < pm3,
            "the middle weight vanishes at lam_min, is negative at stretch 1, positive at sqrt(3)");
    let tri_max = tri_cents.iter().cloned().fold(f64::MIN, f64::max);
    let bin_max = bin_cents.iter().cloned().fold(f64::MIN, f64::max);
    assert!(tri_max < 0.0 && 0.0 < bin_max, "the trinomial stays one side, the binomial crosses");
    println!("ALL CHECKS PASS");
}
