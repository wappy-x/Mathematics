// Leray's weak solutions -- the check behind the card. Rust std only, no crates.
// Water at 1 m/s mean speed in a 5 cm pipe, written against test functions.
use std::f64::consts::PI;

const R: f64 = 0.025; // radius, m
const U: f64 = 1.0; // mean speed, m/s
const NU: f64 = 1.0e-6; // kinematic viscosity, m^2/s
const RHO: f64 = 1000.0; // density, kg/m^3
const MU: f64 = RHO * NU; // viscosity, Pa s
const UMAX: f64 = 2.0 * U; // laminar centre speed, m/s

fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64) -> f64 {
    let (n, h) = (4000, (b - a) / 4000.0);
    h / 3.0 * (f(a) + f(b) + (1..n).map(|i| if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h)).sum::<f64>())
}
fn w(r: f64) -> f64 { UMAX * (1.0 - (r / R).powi(2)) }
fn dw(r: f64) -> f64 { -2.0 * UMAX * r / (R * R) }

// test profile (1 - ((r-c)/h)^2)^3 and its first and second slopes
fn bump(c: f64, h: f64, r: f64) -> (f64, f64, f64) {
    let q = if (r - c).abs() < h { (r - c) / h } else { 1.0 };
    let o = 1.0 - q * q;
    (o.powi(3), -6.0 * q * o * o / h, (-6.0 * o * o + 24.0 * q * q * o) / (h * h))
}
// road 1: viscous side; road 2: pressure side; road 3: very weak form
fn sides(c: f64, h: f64, gg: f64) -> (f64, f64, f64) {
    let (lo, hi) = ((c - h).max(0.0), (c + h).min(R));
    let a = simpson(&|r| MU * dw(r) * bump(c, h, r).1 * 2.0 * PI * r, lo, hi);
    let l = simpson(&|r| gg * bump(c, h, r).0 * 2.0 * PI * r, lo, hi);
    let lap = |r: f64| { let (_, d1, d2) = bump(c, h, r); d2 + if r > 0.0 { d1 / r } else { d2 } };
    let vw = simpson(&|r| -MU * w(r) * lap(r) * 2.0 * PI * r, lo, hi);
    (a, l, vw)
}

// trigonometric fields on the box: terms A sin(kx x + ky y + p)
type Field = Vec<(f64, f64, f64, f64)>;
fn ev(f: &Field, x: f64, y: f64) -> f64 { f.iter().map(|&(a, kx, ky, p)| a * (kx * x + ky * y + p).sin()).sum() }
fn d(f: &Field, ax: usize) -> Field {
    f.iter().map(|&(a, kx, ky, p)| (a * if ax == 0 { kx } else { ky }, kx, ky, p + PI / 2.0)).collect()
}
fn boxsum(fun: &dyn Fn(f64, f64) -> f64) -> f64 {
    let hb = 2.0 * PI / 32.0;
    (0..32).map(|i| (0..32).map(|j| fun(i as f64 * hb, j as f64 * hb)).sum::<f64>()).sum::<f64>() * hb * hb
}
fn bform(a1: &Field, a2: &Field) -> f64 {
    let ds = [d(a1, 0), d(a1, 1), d(a2, 0), d(a2, 1)];
    boxsum(&|x, y| {
        let (v1, v2) = (ev(a1, x, y), ev(a2, x, y));
        let g: Vec<f64> = ds.iter().map(|t| ev(t, x, y)).collect();
        v1 * (v1 * g[0] + v2 * g[1]) + v2 * (v1 * g[2] + v2 * g[3])
    })
}
fn half_div(a1: &Field, a2: &Field) -> f64 {
    let (d1, d2) = (d(a1, 0), d(a2, 1));
    boxsum(&|x, y| -0.5 * (ev(&d1, x, y) + ev(&d2, x, y)) * (ev(a1, x, y).powi(2) + ev(a2, x, y).powi(2)))
}
fn press(a1: &Field, a2: &Field, chi: &Field) -> f64 {
    let (cx, cy) = (d(chi, 0), d(chi, 1));
    boxsum(&|x, y| ev(&cx, x, y) * ev(a1, x, y) + ev(&cy, x, y) * ev(a2, x, y))
}

fn bj(m: f64, x: f64) -> f64 {
    (0..400).map(|i| { let th = (i as f64 + 0.5) * PI / 400.0; (m * th - x * th.sin()).cos() }).sum::<f64>() / 400.0
}
fn zero(k: usize) -> f64 {
    let (mut a, mut b) = ((k as f64 - 0.25) * PI - 0.5, (k as f64 - 0.25) * PI + 0.5);
    for _ in 0..60 {
        let m = (a + b) / 2.0;
        if bj(0.0, a) * bj(0.0, m) <= 0.0 { b = m } else { a = m }
    }
    (a + b) / 2.0
}
fn term(lam: &[f64], k: usize, s: f64, t: f64) -> f64 {
    8.0 * UMAX * bj(0.0, lam[k] * s) / (lam[k].powi(3) * bj(1.0, lam[k])) * (-lam[k] * lam[k] * NU * t / (R * R)).exp()
}
fn series(lam: &[f64], s: f64, t: f64) -> f64 { w(s * R) - (0..10).map(|k| term(lam, k, s, t)).sum::<f64>() }
fn galerkin(n: usize, t: f64, g: f64) -> f64 {
    let steps = 3000;
    let fm = |j: usize, k: usize| { let m = (j + k) as f64; 1.0 / (2.0 * m + 2.0) - 2.0 / (2.0 * m + 4.0) + 1.0 / (2.0 * m + 6.0) };
    let fk = |j: usize, k: usize| {
        let (jf, kf, m) = (j as f64, k as f64, (j + k) as f64);
        (if j * k > 0 { 4.0 * jf * kf / (2.0 * m) } else { 0.0 }) - (2.0 * jf * (2.0 * kf + 2.0) + (2.0 * jf + 2.0) * 2.0 * kf) / (2.0 * m + 2.0)
            + (2.0 * jf + 2.0) * (2.0 * kf + 2.0) / (2.0 * m + 4.0)
    };
    let f: Vec<f64> = (0..n).map(|j| 1.0 / (2.0 * j as f64 + 2.0) - 1.0 / (2.0 * j as f64 + 4.0)).collect();
    let (dt, a) = (t / steps as f64, NU / (R * R));
    let mut c = vec![0.0; n];
    for _ in 0..steps { // Crank-Nicolson in time, Gaussian elimination
        let mut am: Vec<Vec<f64>> = (0..n).map(|i| {
            let mut row: Vec<f64> = (0..n).map(|k| fm(i, k) + dt * a / 2.0 * fk(i, k)).collect();
            row.push((0..n).map(|k| (fm(i, k) - dt * a / 2.0 * fk(i, k)) * c[k]).sum::<f64>() + dt * g * f[i]);
            row
        }).collect();
        for p in 0..n {
            for q in p + 1..n { let fac = am[q][p] / am[p][p]; for r in 0..=n { am[q][r] -= fac * am[p][r]; } }
        }
        for p in (0..n).rev() {
            c[p] = (am[p][n] - (p + 1..n).map(|r| am[p][r] * c[r]).sum::<f64>()) / am[p][p];
        }
    }
    c[0]
}

fn main() {
    let gp = 4.0 * MU * UMAX / (R * R); // pressure drop per metre, Pa/m
    let g = gp / RHO; // per unit mass, m/s^2
    println!("pipe: R = {:.1} mm, mean {:.1} m/s, centre {:.1} m/s, Re = {:.0}", R * 1000.0, U, UMAX, U * 2.0 * R / NU);
    println!("pressure drop G = {:.4} Pa/m, wall stress {:.4} Pa", gp, 2.0 * MU * UMAX / R);
    for (name, c, h) in [("A, on the axis", 0.0, R), ("B, a ring", 0.015, 0.008)] {
        let (a, l, vw) = sides(c, h, gp);
        println!("bump {}: viscous {:.7} N/m, pressure {:.7} N/m, very weak {:.7} N/m", name, a, l, vw);
        assert!((a - l).abs() < 1e-9 && (vw - l).abs() < 1e-9);
    }
    assert!((sides(0.0, R, gp).1 - gp * PI * R * R / 4.0).abs() < 1e-12); // closed form for bump A
    let drag = -MU * (w(R + 1e-6) - w(R - 1e-6)) / 2e-6 * 2.0 * PI * R; // wall stress from the profile's slope
    println!("mistake v = 1: viscous 0.0000000 N/m, pressure {:.7} N/m = wall drag {:.7} N/m", gp * PI * R * R, drag);
    assert!((gp * PI * R * R - drag).abs() < 1e-12);
    let gw = 4.0 * MU * U / (R * R);
    let (a, l, _) = sides(0.0, R, gw);
    println!("mistake mean speed in 4 mu U/R^2: G = {:.4} Pa/m, bump A {:.7} vs {:.7} N/m", gw, a, l);

    // The nonlinear term on a swirling cell, scaled: periodic box of side 2 pi.
    let u1: Field = vec![(0.5, 1.0, 1.0, 0.0), (0.5, 1.0, -1.0, 0.0), (-0.5, 2.0, 1.0, 0.0)];
    let u2: Field = vec![(-0.5, 1.0, 1.0, 0.0), (0.5, 1.0, -1.0, 0.0), (1.0, 2.0, 1.0, 0.0)];
    let chi: Field = vec![(1.0, 1.0, 0.0, PI / 2.0)];
    let mut b1 = u1.clone();
    b1.extend(d(&chi, 0).iter().map(|&(a, k, l, p)| (0.5 * a, k, l, p)));
    let mut b2 = u2.clone();
    b2.extend(d(&chi, 1).iter().map(|&(a, k, l, p)| (0.5 * a, k, l, p)));
    let (bu, bb, hdb) = (bform(&u1, &u2), bform(&b1, &b2), half_div(&b1, &b2));
    println!("box: b(u,u,u) divergence-free {:.6}; leaking {:.6}, by -1/2 int (div u)|u|^2 {:.6}", bu.abs(), bb, hdb);
    assert!(bu.abs() < 1e-12 && (bb - hdb).abs() < 1e-10 && (bb + 3.0 * PI * PI / 8.0).abs() < 1e-10);
    let (pu, pb) = (press(&u1, &u2, &chi), press(&b1, &b2, &chi));
    println!("box: pressure term divergence-free {:.6}; leaking {:.6} (pi^2 = {:.6})", pu.abs(), pb, PI * PI);
    assert!(pu.abs() < 1e-12 && (pb - PI * PI).abs() < 1e-10);

    // Weak is not strong: a wiggle across the diameter, s from 0 to 1, size 1 m/s.
    let phi = |s: f64| 16.0 * s * s * (1.0 - s).powi(2);
    let (mut lin, mut sq, mut slope) = (0.0, 0.0, 0.0);
    for k in [1.0, 5.0, 25.0, 125.0] {
        lin = simpson(&|s| (k * PI * s).sin() * phi(s), 0.0, 1.0);
        sq = simpson(&|s| (k * PI * s).sin().powi(2) * phi(s), 0.0, 1.0);
        slope = simpson(&|s| (k * PI * (k * PI * s).cos()).powi(2), 0.0, 1.0).sqrt();
        println!("wiggle n = {:3}: |int u phi| {:.6}, int u^2 phi {:.6}, slope size {:.4} m/s per diameter", k as i64, lin.abs(), sq, slope);
    }
    assert!(lin.abs() < 1e-4 && (sq - 4.0 / 15.0).abs() < 1e-4 && (slope - 125.0 * PI / 2f64.sqrt()).abs() < 1e-6);

    // Start-up flow: Bessel series against Galerkin with N profiles (1 - s^2) s^(2k).
    let lam: Vec<f64> = (1..12).map(zero).collect();
    println!("Bessel zeros {:.6}, {:.6}; slowest time R^2/(nu z1^2) = {:.2} s", lam[0], lam[1], R * R / NU / (lam[0] * lam[0]));
    let ex = series(&lam, 0.0, 180.0);
    println!("centre at 180 s: series {:.6} m/s, first omitted term {:.2e}", ex, term(&lam, 10, 0.0, 180.0).abs());
    let gal: Vec<f64> = (1..6).map(|n| galerkin(n, 180.0, g)).collect();
    for (i, v) in gal.iter().enumerate() { println!("  Galerkin N = {}: {:.6} m/s, gap {:.6}", i + 1, v, (v - ex).abs()); }
    assert!((gal[4] - ex).abs() < 1e-6 && (gal[0] - ex).abs() > 0.05);
    assert!((g * 60.0 - series(&lam, 0.0, 60.0)).abs() < 0.03); // early on, the centre speeds up at G / rho
    let rs = [0.0, 0.005, 0.01, 0.015, 0.02, 0.025];
    for t in [60.0, 180.0, 600.0] {
        let pts: Vec<String> = rs.iter().map(|r| format!("{:.3}", series(&lam, r / R, t))).collect();
        println!("chart t = {:3} s: {}", t as i64, pts.join(" "));
    }
    let pts: Vec<String> = rs.iter().map(|&r| format!("{:.3}", w(r))).collect();
    println!("chart steady:   {}", pts.join(" "));
    println!("ALL CHECKS PASS");
}
