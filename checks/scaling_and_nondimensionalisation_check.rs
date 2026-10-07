// Scaling and nondimensionalisation -- the same check as the Python, in Rust.  Std only, no crates.
// Water in a 0.1 m pipe, pushed from rest by a steady pressure drop per metre G.
// Rescaled: du/dtau = 1 + eps * (1/r) d/dr (r du/dr), u = 0 at the wall r = 1, u = 0 at tau = 0.
// Road 1: the exact Bessel series.  Road 2: Crank-Nicolson finite differences.
// Road 3: eps -> 0 (the plug), plus its wall-layer correction.
use std::f64::consts::PI;

const RHO: f64 = 1000.0; // kg/m^3, water near 20 C, rounded
const NU: f64 = 1.0e-6; // m^2/s
const D: f64 = 0.1; // m
const MU: f64 = RHO * NU;
const R: f64 = D / 2.0;

fn bessel(n: f64, x: f64) -> f64 { // J_n(x) = (1/pi) int_0^pi cos(n t - x sin t) dt, trapezoid
    let m = 600;
    let h = PI / m as f64;
    let mut s = 0.5 * (1.0 + (n * PI).cos());
    for k in 1..m {
        let t = k as f64 * h;
        s += (n * t - x * t.sin()).cos();
    }
    s * h / PI
}

fn zeros() -> Vec<(f64, f64)> { // zeros of J_0 by Newton, J_0' = -J_1
    (1..151).map(|k| {
        let mut x = (k as f64 - 0.25) * PI;
        for _ in 0..6 { x += bessel(0.0, x) / bessel(1.0, x); }
        (x, bessel(1.0, x))
    }).collect()
}

fn series_mean(z: &[(f64, f64)], eps: f64, tau: f64) -> f64 { // road 1: mean speed / U
    1.0 / (8.0 * eps) - z.iter().map(|&(l, _)| 4.0 / (eps * l.powi(4)) * (-eps * l * l * tau).exp()).sum::<f64>()
}

fn series_u(z: &[(f64, f64)], eps: f64, tau: f64, r: f64) -> f64 { // road 1: speed / U at r / R
    (1.0 - r * r) / (4.0 * eps)
        - z.iter().map(|&(l, j1)| 2.0 * bessel(0.0, l * r) / (eps * l.powi(3) * j1) * (-eps * l * l * tau).exp()).sum::<f64>()
}

fn simulate(eps: f64, tau_end: f64, n: usize, steps: usize) -> (f64, f64) { // road 2: Crank-Nicolson
    let (h, dt) = (1.0 / n as f64, tau_end / steps as f64);
    let mut lo = vec![0.0; n];
    let mut up = vec![0.0; n];
    up[0] = 4.0 / (h * h);
    for i in 1..n {
        lo[i] = (i as f64 - 0.5) / (i as f64 * h * h);
        up[i] = (i as f64 + 0.5) / (i as f64 * h * h);
    }
    let c = 0.5 * eps * dt;
    let mut u = vec![0.0; n + 1]; // u[n] is the wall, held at 0
    let (mut cp, mut dp, mut rhs) = (vec![0.0; n], vec![0.0; n], vec![0.0; n]);
    for _ in 0..steps {
        for i in 0..n {
            let left = if i > 0 { u[i - 1] } else { 0.0 };
            rhs[i] = u[i] + dt + c * (lo[i] * left - (lo[i] + up[i]) * u[i] + up[i] * u[i + 1]);
        }
        for i in 0..n { // Thomas algorithm
            let (a, b, cc) = (-c * lo[i], 1.0 + c * (lo[i] + up[i]), -c * up[i]);
            let den = b - if i > 0 { a * cp[i - 1] } else { 0.0 };
            cp[i] = cc / den;
            dp[i] = (rhs[i] - if i > 0 { a * dp[i - 1] } else { 0.0 }) / den;
        }
        for i in (0..n).rev() { u[i] = dp[i] - cp[i] * u[i + 1]; }
    }
    let mean: f64 = (1..n).map(|i| 2.0 * (i as f64 * h) * u[i] * h).sum(); // trapezoid of 2 r u dr
    (mean, u[0])
}

fn prandtl_f(re: f64) -> f64 { // smooth-pipe law 1/sqrt f = 2 log10(Re sqrt f) - 0.8
    let mut g: f64 = 0.02;
    for _ in 0..50 { g = 1.0 / (2.0 * (re * g.sqrt()).log10() - 0.8).powi(2); }
    g
}

fn row(label: &str, v: &[f64]) -> String {
    format!("{:<22}{}", label, v.iter().map(|x| format!("{:5.2}", x)).collect::<Vec<_>>().join(" "))
}

fn main() {
    let z = zeros();
    let k_layer = 8.0 / (3.0 * PI.sqrt()); // mean deficit = K sqrt(eps tau): the wall-layer road
    println!("inputs: rho 1000 kg/m^3, nu 1.0e-6 m^2/s, D = 0.1 m; NIST, 20 C: rho 998.21, mu 1.0016e-3 Pa s, nu {:.4}e-6 m^2/s",
             1.0016e-3 / 998.21 * 1e6);
    let mut cases = vec![];
    for &(re, laminar) in &[(2000.0_f64, true), (200000.0, false)] {
        let u_d = re * NU / D;
        let f = if laminar { 64.0 / re } else { prandtl_f(re) };
        let g = f * RHO * u_d * u_d / (2.0 * D); // Pa/m the steady flow needs
        let t = RHO * u_d / g; // s: time for G alone to bring water to U
        let eps = MU * u_d / (g * R * R);
        cases.push((u_d, g, t, eps, f));
        let (sm, sc) = simulate(eps, 1.0, 400, 2000);
        let (em, ec) = (series_mean(&z, eps, 1.0), series_u(&z, eps, 1.0, 0.0));
        println!("Re {:>6}: U = {:.2} m/s, 1/Re = {:.6}, f = {:.5}, G = {:.3} Pa/m", re, u_d, 1.0 / re, f, g);
        println!("   T = rho U / G = {:.2} s, D/U = {:.2} s, eps = mu U/(G R^2) = {:.5}, 8/(f Re) = {:.5}",
                 t, D / u_d, eps, 8.0 / (f * re));
        println!("   wall layer sqrt(nu T) = {:.2} mm, sqrt(eps) = {:.4} of R", (NU * t).sqrt() * 1000.0, eps.sqrt());
        println!("   at tau = 1, mean/U: series {:.5}  simulation {:.5}  plug 1.00000  plug - layer {:.5}",
                 em, sm, 1.0 - k_layer * eps.sqrt());
        println!("   at tau = 1, centre/U: series {:.5}  simulation {:.5}  plug 1.00000", ec, sc);
        println!("   mean speed at T: {:.4} m/s, deficit / sqrt(eps) = {:.4}", em * u_d, (1.0 - em) / eps.sqrt());
        assert!((sm - em).abs() < 1e-4, "simulation and series disagree on the mean");
        assert!((sc - ec).abs() < 1e-4, "simulation and series disagree at the centre");
        assert!((eps * f * re / 8.0 - 1.0).abs() < 1e-12, "mu U/(G R^2) and 8/(f Re) disagree");
    }
    let (_, _, t_a, eps_a, _) = cases[0];
    let (u_b, g_b, _, eps_b, f_b) = cases[1];
    let (mut lo_t, mut hi_t) = (0.0_f64, 20.0_f64); // case A: time to 99% of the steady mean
    for _ in 0..60 {
        let mid = 0.5 * (lo_t + hi_t);
        if series_mean(&z, eps_a, mid) < 0.99 / (8.0 * eps_a) { lo_t = mid; } else { hi_t = mid; }
    }
    let l1 = z[0].0;
    let t99_mode = (32.0 / l1.powi(4) / 0.01).ln() / (eps_a * l1 * l1);
    println!("Re 2000 to 99% of steady: tau {:.4} (series), {:.4} (first mode) = {:.0} s", lo_t, t99_mode, lo_t * t_a);
    println!("K = 8/(3 sqrt pi) = {:.4}; first zero of J0 = {:.5}; viscous time R^2/nu = {:.0} s", k_layer, l1, R * R / NU);
    println!("wrong: laminar G at Re 200000 = {:.2} Pa/m, needed {:.2} Pa/m (x{:.1})",
             8.0 * MU * u_b / (R * R), g_b, g_b * R * R / (8.0 * MU * u_b));
    println!("wrong: drop the acceleration at Re 200000: mean = {:.2} m/s", g_b * R * R / (8.0 * MU));
    println!("wrong: plug-minus-layer at Re 2000 = {:.4}, true {:.4}", 1.0 - k_layer * eps_a.sqrt(), series_mean(&z, eps_a, 1.0));
    for &re in &[4000.0_f64, 2000000.0] {
        let f = prandtl_f(re);
        let e = 8.0 / (f * re);
        let m = series_mean(&z, e, 1.0);
        println!("try: Re {:>7}: f = {:.5}, eps = {:.5}, mean/U at tau 1 = {:.4}, deficit/sqrt(eps) = {:.4}",
                 re, f, e, m, (1.0 - m) / e.sqrt());
    }
    println!("try: Re 200000 on 25 cells: simulation mean {:.4}", simulate(eps_b, 1.0, 25, 200).0);
    let f_h = (-1.8 * (6.9 / 200000.0_f64).log10()).powi(-2); // Haaland's explicit smooth-pipe fit: a second road to f
    println!("friction at Re 200000: Prandtl {:.5}, Haaland {:.5}, gap {:.1}%", f_b, f_h, (f_b / f_h - 1.0) * 100.0);
    let taus: Vec<f64> = (0..11).map(|k| k as f64 / 10.0).collect();
    let rads: Vec<f64> = (0..11).map(|k| 0.5 + k as f64 / 20.0).collect();
    println!("{}", row("chart, tau", &taus));
    println!("{}", row("chart, plug mean", &taus));
    for &(lab, e) in &[("Re 200000", eps_b), ("Re 2000", eps_a)] {
        let v: Vec<f64> = taus.iter().map(|&t| series_mean(&z, e, t)).collect();
        println!("{}", row(&format!("chart, mean {}", lab), &v));
    }
    println!("{}", row("chart, r/R", &rads));
    for &(lab, e) in &[("Re 200000", eps_b), ("Re 2000", eps_a)] {
        let v: Vec<f64> = rads.iter().map(|&r| series_u(&z, e, 1.0, r).max(0.0)).collect();
        println!("{}", row(&format!("chart, prof {}", lab), &v));
    }
    let m_b = series_mean(&z, eps_b, 1.0);
    assert!((m_b - (1.0 - k_layer * eps_b.sqrt())).abs() < 0.005, "wall-layer road misses the exact mean at Re 200000");
    assert!((series_u(&z, eps_b, 1.0, 0.0) - 1.0).abs() < 1e-3, "the plug must be exact at the centre at Re 200000");
    assert!((lo_t - t99_mode).abs() < 1e-3, "bisection and first-mode settling times disagree");
    assert!((f_b / f_h - 1.0).abs() < 0.02, "Prandtl and Haaland friction factors disagree");
    assert!(series_mean(&z, eps_a, 1.0) < 0.6, "at Re 2000 the plug must fail badly");
    println!("ALL CHECKS PASS");
}
