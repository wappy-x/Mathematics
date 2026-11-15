// Three Banach theorems on a footbridge joist: recovering its load from its sag.
// std only, no crates.  Every number quoted on the card is printed here.
use std::f64::consts::PI;

const L: f64 = 4.0; // span, m
const EI: f64 = 326645.0; // bending stiffness, N m^2
const Q: f64 = 500.0; // uniform load, N/m
const NOISE: f64 = 1e-5; // 0.01 mm of sag

// Thomas algorithm: (v[j-1] - 2 v[j] + v[j+1]) / h^2 = rhs[j], with v = 0 at both pins
fn solve_d2(rhs: &[f64], h: f64) -> Vec<f64> {
    let n = rhs.len();
    let (mut c, mut d, mut v) = (vec![0.0; n], vec![0.0; n], vec![0.0; n]);
    for j in 0..n {
        let piv = -2.0 - if j > 0 { c[j - 1] } else { 0.0 };
        c[j] = 1.0 / piv;
        d[j] = (rhs[j] * h * h - if j > 0 { d[j - 1] } else { 0.0 }) / piv;
    }
    for j in (0..n).rev() {
        v[j] = d[j] - c[j] * if j + 1 < n { v[j + 1] } else { 0.0 };
    }
    v
}

// T: sag from load, EI w'''' = load, w = w'' = 0 at the pins
fn beam(load: &[f64], h: f64) -> Vec<f64> {
    let m = solve_d2(&load.iter().map(|x| -x).collect::<Vec<_>>(), h); // M'' = -load
    solve_d2(&m.iter().map(|x| -x / EI).collect::<Vec<_>>(), h) // EI w'' = -M
}

fn d2(u: &[f64], h: f64) -> Vec<f64> {
    let n = u.len();
    (0..n)
        .map(|j| {
            let a = if j > 0 { u[j - 1] } else { 0.0 };
            let b = if j + 1 < n { u[j + 1] } else { 0.0 };
            (a - 2.0 * u[j] + b) / (h * h)
        })
        .collect()
}

// A: load from sag, EI times the second difference applied twice
fn load_of(v: &[f64], h: f64) -> Vec<f64> {
    d2(&d2(v, h), h).iter().map(|x| EI * x).collect()
}

// the L2 size on the grid: square root of h times the sum of squares
fn nrm(v: &[f64], h: f64) -> f64 {
    (h * v.iter().map(|x| x * x).sum::<f64>()).sqrt()
}

fn main() {
    let k1 = EI * (PI / L).powi(4); // load per unit sag in mode 1, N/m^2
    let exact = 5.0 * Q * L.powi(4) / (384.0 * EI);
    let mut series = 0.0;
    for n in (1..2000).step_by(2) {
        let nf = n as f64;
        series += 4.0 * Q / (nf * PI) / (EI * (nf * PI / L).powi(4)) * (nf * PI / 2.0).sin();
    }
    assert!((series - exact).abs() < 1e-12);
    println!("joist: span {:.0} m, EI = {:.0} N m^2, uniform load {:.0} N/m", L, EI, Q);
    println!("midspan sag: 5qL^4/384EI = {:.6} mm; sine series, 1000 modes = {:.6} mm", exact * 1e3, series * 1e3);
    println!("   N  grid sag mm  error mm   1/||T_N|| N/m^2  ||T_N^-1|| N/m^2");
    let (mut prev, mut lo) = (f64::NAN, 0.0);
    let (mut cx, mut clo, mut chi) = (vec![], vec![], vec![]);
    for &n in &[3usize, 7, 15, 31, 63, 127] {
        let h = L / (n as f64 + 1.0);
        let w = beam(&vec![Q; n], h);
        let err = w[n / 2] - exact;
        // closed form: eigenvalue k of the load-from-sag matrix
        let lam = |k: usize| EI * (4.0 / (h * h)).powi(2) * (k as f64 * PI / (2.0 * (n as f64 + 1.0))).sin().powi(4);
        let mut v = vec![1.0; n]; // road 2: inverse power iteration through the solver
        for _ in 0..60 {
            let u = beam(&v, h);
            let s = nrm(&u, h);
            v = u.iter().map(|x| x / s).collect();
        }
        lo = 1.0 / nrm(&beam(&v, h), h);
        assert!((lo / lam(1) - 1.0).abs() < 1e-9);
        // road 3: the stencil itself
        let top: Vec<f64> = (0..n).map(|j| (n as f64 * PI * (j as f64 + 1.0) / (n as f64 + 1.0)).sin()).collect();
        let res: Vec<f64> = load_of(&top, h).iter().zip(&top).map(|(a, b)| a - lam(n) * b).collect();
        assert!(nrm(&res, h) < 1e-9 * lam(n) * nrm(&top, h));
        assert!(lam(n) <= 16.0 * EI / h.powi(4)); // Gershgorin row bound
        if !prev.is_nan() {
            assert!(3.9 < prev / err && prev / err < 4.1); // error falls 4 times per halving
        }
        prev = err;
        cx.push(format!("{:.3}", (n as f64).log10()));
        clo.push(format!("{:.3}", lo.log10()));
        chi.push(format!("{:.3}", lam(n).log10()));
        println!("{:4} {:11.6} {:10.6} {:16.1} {:17.1}", n, w[n / 2] * 1e3, err * 1e3, lo, lam(n));
    }
    assert!((lo / k1 - 1.0).abs() < 1e-3);
    println!("limit: 1/||T|| = EI (pi/L)^4 = {:.1} N/m^2, so ||T|| = {:.4} micrometres of sag per N/m", k1, 1e6 / k1);
    println!("chart: log10 N {}", cx.join(", "));
    println!("chart: log10 1/||T_N|| {}", clo.join(", "));
    println!("chart: log10 ||T_N^-1|| {}", chi.join(", "));
    for &n in &[1i32, 2, 5, 10, 20] {
        println!("0.01 mm of sag noise in mode {:2} -> load error {:10.1} N/m", n, NOISE * k1 * (n as f64).powi(4));
    }

    // uniform boundedness: R_N keeps N sine modes of the sag and multiplies mode n by EI (n pi / L)^4
    println!("noisy sag: mode n has amplitude 0.01 mm / n; L2 size {:.6} mm", NOISE * (L / 2.0 * PI * PI / 6.0).sqrt() * 1e3);
    println!("   N      ||R_N|| N/m^2  ||R_N w_noisy|| N/m  ||R_N w_true - q|| N/m");
    for &nn in &[1u64, 5, 10, 20, 40, 80] {
        let s6 = nn * (nn + 1) * (2 * nn + 1) * (3 * nn.pow(4) + 6 * nn.pow(3) - 3 * nn + 1) / 42; // sum of n^6
        let noisy = (L / 2.0 * (1..=nn).map(|n| (NOISE / n as f64 * k1 * (n as f64).powi(4)).powi(2)).sum::<f64>()).sqrt();
        assert!((noisy / (NOISE * k1 * (L / 2.0 * s6 as f64).sqrt()) - 1.0).abs() < 1e-12);
        let kept: f64 = (1..=nn).step_by(2).map(|n| (4.0 * Q / (n as f64 * PI)).powi(2)).sum();
        let gap = (Q * Q * L - L / 2.0 * kept).sqrt();
        if nn == 10 {
            // road 2 for the gap: midpoint rule on (q - its first ten sine modes)^2 over the span
            let m = 20000;
            let mut quad = 0.0;
            for i in 0..m {
                let mut s = 0.0;
                for n in (1..11).step_by(2) {
                    s += 4.0 * Q / (n as f64 * PI) * (n as f64 * PI * (i as f64 + 0.5) / m as f64).sin();
                }
                quad += (Q - s).powi(2);
            }
            quad *= L / m as f64;
            assert!((quad.sqrt() / gap - 1.0).abs() < 1e-6);
        }
        println!("{:4} {:18.1} {:20.1} {:22.1}", nn, k1 * (nn as f64).powi(4), noisy, gap);
    }

    // closed graph: ripples w_n = (0.01 mm / n) sin(n pi x / L) shrink, their loads grow
    for &n in &[1i32, 10, 100] {
        let size = NOISE / n as f64 * (L / 2.0).sqrt();
        println!("ripple n = {:3}: ||w_n|| = {:.6} mm, ||A w_n|| = {:.1} N/m", n, size * 1e3, size * k1 * (n as f64).powi(4));
    }
    let h = L / 128.0;
    let rip: Vec<f64> = (0..127).map(|j| NOISE / 10.0 * (10.0 * PI * (j as f64 + 1.0) / 128.0).sin()).collect();
    assert!((nrm(&load_of(&rip, h), h) / nrm(&rip, h) / (k1 * 1e4) - 1.0).abs() < 0.02); // grid within 2%

    // completeness dropped: finite sequences only, not a Banach space under either norm
    let ones = vec![1.0f64; 1000];
    let (mx, sm) = (ones.iter().cloned().fold(0.0, f64::max), ones.iter().sum::<f64>());
    println!("finite sequences, 1000 ones: max norm {:.0}, sum norm {:.0}, inverse gain {:.0}", mx, sm, sm / mx);
    let f = |k: usize, x: &[f64]| k as f64 * x[k - 1]; // f_k(x) = k x_k on a finite sequence x
    let gains: Vec<f64> = [1usize, 10, 100].iter().map(|&k| {
        let mut e = vec![0.0; k];
        e[k - 1] = 1.0; // e_k, of max norm 1
        f(k, &e).abs()
    }).collect();
    assert!(gains == vec![1.0, 10.0, 100.0]); // and |k x_k| <= k max |x|, so ||f_k|| = k
    let gs: Vec<String> = gains.iter().map(|g| format!("{:.0}", g)).collect();
    println!("f_k(x) = k x_k, max norm: |f_k(e_k)| = {} at k = 1, 10, 100, so ||f_k|| = k", gs.join(", "));
    let mut e100 = vec![0.0; 100];
    e100[99] = 1.0;
    let xs: [Vec<f64>; 3] = [vec![0.5, -0.25, 0.125], vec![1.0; 10], e100];
    let tops: Vec<f64> = xs.iter().map(|x| (1..=x.len()).map(|k| f(k, x).abs()).fold(0.0, f64::max)).collect();
    println!("  sup over k of |f_k(x)|: {:.3} at (0.5, -0.25, 0.125); {:.3} at ten ones; {:.3} at e_100", tops[0], tops[1], tops[2]);
    println!("ALL CHECKS PASS");
}
