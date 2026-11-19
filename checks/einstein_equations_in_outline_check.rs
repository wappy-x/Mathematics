// Einstein equations in outline: check that the Schwarzschild metric has Ric = 0 outside the Sun,
// then trace a grazing starlight ray through it and read off the bending.
use std::f64::consts::PI;

const GM: f64 = 1.3271244e20; // Sun's GM, m^3/s^2, IAU 2015 nominal
const C: f64 = 299792458.0; // speed of light, m/s, exact
const RSUN: f64 = 6.957e8; // Sun's radius, m, IAU 2015 nominal
const ARCSEC: f64 = 648000.0 / PI; // arcseconds in one radian

fn show(label: &str, v: f64, d: usize) {
    let v = if v.abs() < 5e-13 { 0.0 } else { v };
    println!("{:<44}{:>16.*}", label, d, v);
}

// ---- road 1: Ricci tensor from the metric alone, by finite differences (units: r_s = 1, c = 1) ----
type Metric = fn(&[f64; 4]) -> [f64; 4];
fn schwarzschild(p: &[f64; 4]) -> [f64; 4] { // coordinates (t, r, phi, theta)
    let a = 1.0 - 1.0 / p[1];
    [-a, 1.0 / a, p[1] * p[1], (p[1] * p[2].sin()).powi(2)]
}
fn time_only(p: &[f64; 4]) -> [f64; 4] { // Newton's guess: slow the clocks, leave space flat
    [-(1.0 - 1.0 / p[1]), 1.0, p[1] * p[1], (p[1] * p[2].sin()).powi(2)]
}
fn shift(p: &[f64; 4], i: usize, s: f64) -> [f64; 4] {
    let mut q = *p; q[i] += s; q
}
type G3 = [[[f64; 4]; 4]; 4];
fn christoffel(metric: Metric, p: &[f64; 4], h: f64) -> G3 { // g diagonal
    let g = metric(p);
    let mut dg = [[0.0; 4]; 4];
    for m in 0..4 {
        let (a, b) = (metric(&shift(p, m, h)), metric(&shift(p, m, -h)));
        for i in 0..4 { dg[m][i] = (a[i] - b[i]) / (2.0 * h); }
    }
    let d = |m: usize, i: usize, j: usize| if i == j { dg[m][i] } else { 0.0 };
    let mut out = [[[0.0; 4]; 4]; 4];
    for l in 0..4 { for j in 0..4 { for k in 0..4 {
        out[l][j][k] = 0.5 / g[l] * (d(j, l, k) + d(k, l, j) - d(l, j, k));
    } } }
    out
}
struct Curv { rm: [[[[f64; 4]; 4]; 4]; 4], ric: [[f64; 4]; 4] }
fn curvature(metric: Metric, p: &[f64; 4], h: f64) -> Curv { // rm[l][i][j][k] = R^l_kij
    let g = christoffel(metric, p, h);
    let mut dg = [[[[0.0; 4]; 4]; 4]; 4];
    for i in 0..4 {
        let (a, b) = (christoffel(metric, &shift(p, i, h), h), christoffel(metric, &shift(p, i, -h), h));
        for l in 0..4 { for j in 0..4 { for k in 0..4 { dg[i][l][j][k] = (a[l][j][k] - b[l][j][k]) / (2.0 * h); } } }
    }
    let mut rm = [[[[0.0; 4]; 4]; 4]; 4];
    let mut ric = [[0.0; 4]; 4];
    for l in 0..4 { for i in 0..4 { for j in 0..4 { for k in 0..4 {
        let mut s = dg[i][l][j][k] - dg[j][l][i][k];
        for m in 0..4 { s += g[l][i][m] * g[m][j][k] - g[l][j][m] * g[m][i][k]; }
        rm[l][i][j][k] = s;
    } } } }
    for j in 0..4 { for k in 0..4 { for i in 0..4 { ric[j][k] += rm[i][i][j][k]; } } }
    Curv { rm, ric }
}
fn largest(ric: &[[f64; 4]; 4]) -> f64 {
    ric.iter().flatten().fold(0.0, |m: f64, x| m.max(x.abs()))
}

// ---- road 2: closed forms for -A dt^2 + B dr^2 + r^2 dOmega^2, with A = e^(2a), B = e^(2b) ----
fn ricci_closed(a1: f64, a2: f64, b1: f64, a: f64, b: f64, r: f64) -> [f64; 3] {
    [(a2 + a1 * a1 - a1 * b1 + 2.0 * a1 / r) * (2.0 * (a - b)).exp(),
     -a2 - a1 * a1 + a1 * b1 + 2.0 * b1 / r,
     (-2.0 * b).exp() * (r * (b1 - a1) - 1.0) + 1.0]
}

// ---- the ray: Hamilton's equations for light give w'' = F'(w)/2, w = r0/r, the angle as clock ----
fn bend(eps: f64, kind: &str, steps: usize) -> f64 {
    let acc = |w: f64| match kind {
        "full" => -w + 1.5 * eps * w * w,
        "time" => (1.0 - eps) * eps / (2.0 * (1.0 - eps * w).powi(2)) - w,
        _ => -0.5 * eps * (1.0 - w * w) - w * (1.0 - eps * w), // space part only
    };
    let (h, mut n, mut w, mut v) = (2.0 / steps as f64, 0usize, 1.0f64, 0.0f64);
    loop {
        let (k1w, k1v) = (v, acc(w));
        let (k2w, k2v) = (v + h / 2.0 * k1v, acc(w + h / 2.0 * k1w));
        let (k3w, k3v) = (v + h / 2.0 * k2v, acc(w + h / 2.0 * k2w));
        let (k4w, k4v) = (v + h * k3v, acc(w + h * k3w));
        let nw = w + h / 6.0 * (k1w + 2.0 * k2w + 2.0 * k3w + k4w);
        let nv = v + h / 6.0 * (k1v + 2.0 * k2v + 2.0 * k3v + k4v);
        if nw < 0.0 { return 2.0 * h * (n as f64 + w / (w - nw)) - PI; }
        n += 1; w = nw; v = nv;
    }
}

fn main() {
    let rs = 2.0 * GM / (C * C);
    let mut worst = Vec::new();
    let (mut st3, mut coarse) = (0.0, 0.0);
    for r in [1.5, 3.0, 6.0] {
        let p = [0.0, r, 1.0, 0.5];
        let cv = curvature(schwarzschild, &p, 1e-4);
        worst.push(largest(&cv.ric));
        let stretch = -cv.rm[1][1][0][0] / (1.0 - 1.0 / r);
        show(&format!("r = {:3.1} r_s: largest |Ric|, step 1e-4", r), largest(&cv.ric), 9);
        show("  radial tidal stretch -R^r_trt/A", stretch, 9);
        show("  closed form 1/r^3", 1.0 / r.powi(3), 9);
        if r == 3.0 {
            st3 = stretch;
            coarse = largest(&curvature(schwarzschild, &p, 1e-3).ric);
            show("  largest |Ric|, step 1e-3", coarse, 9);
        }
    }
    let a = 1.0 - 1.0 / 3.0;
    let (a1, a2) = (1.0 / (2.0 * 9.0 * a), -5.0 / (2.0 * 81.0 * a * a)); // a = (1/2) ln(1 - 1/r) at r = 3
    let closed = ricci_closed(a1, a2, -a1, 0.5 * a.ln(), -0.5 * a.ln(), 3.0);
    let closed_max = closed.iter().fold(0.0, |m: f64, x| m.max(x.abs()));
    show("closed form, Schwarzschild, largest |Ric|", closed_max, 9);
    let c0v = curvature(time_only, &[0.0, 3.0, 1.0, 0.5], 1e-4);
    let c0 = ricci_closed(a1, a2, 0.0, 0.5 * a.ln(), 0.0, 3.0);
    for (j, n) in ["tt", "rr", "phiphi"].iter().enumerate() {
        show(&format!("time-only metric, r = 3: Ric_{}", n), c0v.ric[j][j], 9);
        show("  closed form", c0[j], 9);
    }

    let eps = rs / RSUN;
    show("Schwarzschild radius of the Sun r_s, m", rs, 2);
    show("r_s / R_sun", eps, 10);
    let weak = 2.0 * eps;
    let (full, tpart, spart) = (bend(eps, "full", 40000), bend(eps, "time", 40000), bend(eps, "space", 40000));
    show("arcseconds in one radian", ARCSEC, 3);
    show("weak field 2 r_s / r0, radians", weak, 10);
    show("weak field 2 r_s / r0, arcsec", weak * ARCSEC, 4);
    show("ray traced, full metric, arcsec", full * ARCSEC, 4);
    show("ray traced, time part only, arcsec", tpart * ARCSEC, 4);
    show("ray traced, space part only, arcsec", spart * ARCSEC, 4);
    let second = (15.0 * PI / 16.0 - 1.0) * eps * eps;
    show("traced minus weak field, microarcsec", (full - weak) * ARCSEC * 1e6, 3);
    show("second-order term, microarcsec", second * ARCSEC * 1e6, 3);
    show("Newton's tide 2GM/R^3 at the surface, 1/s^2", 2.0 * GM / RSUN.powi(3), 12);
    show("same from r_s c^2 / r^3, 1/s^2", rs * C * C / RSUN.powi(3), 12);
    show("measured 2004: gamma", 0.99983, 5);
    show("measured 2004: (1+gamma)/2 x prediction", (1.0 + 0.99983) / 2.0 * weak * ARCSEC, 5);
    show("measured 2004: standard error, arcsec", 0.00045 / 2.0 * weak * ARCSEC, 5);

    show("wrong: sign of r_s flipped, arcsec", bend(-eps, "full", 40000) * ARCSEC, 4);
    let ns = 2.0 * 1.4 * GM / (C * C) / 12000.0; // neutron star: 1.4 Suns, radius 12 km
    show("neutron star r_s / R", ns, 4);
    show("neutron star weak field, degrees", 2.0 * ns * 180.0 / PI, 2);
    show("neutron star ray traced, degrees", bend(ns, "full", 40000) * 180.0 / PI, 2);
    show("try: Jupiter's limb, arcsec", 4.0 * 1.26686534e17 / (C * C * 7.1492e7) * ARCSEC, 4);

    let xs = [1, 2, 3, 4, 5, 6, 8, 10];
    let row = |f: &dyn Fn(f64) -> String| xs.iter().map(|&x| f(x as f64)).collect::<Vec<_>>().join(" ");
    println!("chart r0/R_sun {}", row(&|x| format!("{:6}", x as i64)));
    println!("einstein       {}", row(&|x| format!("{:6.3}", bend(eps / x, "full", 4000) * ARCSEC)));
    println!("newton         {}", row(&|x| format!("{:6.3}", bend(eps / x, "time", 4000) * ARCSEC)));

    let wmax = worst.iter().fold(0.0, |m: f64, &x| m.max(x));
    assert!(wmax < 1e-6 && coarse > 10.0 * worst[1], "Schwarzschild has Ric = 0, error shrinks with step");
    assert!((st3 - 1.0 / 27.0).abs() < 1e-6, "tidal stretch against closed form 1/r^3");
    assert!(closed_max < 1e-12, "closed-form Ric vanishes");
    assert!((c0v.ric[1][1] - c0[1]).abs() < 1e-6 && c0[1].abs() > 0.01, "time-only metric fails Ric = 0");
    assert!(((full - weak) - second).abs() < 5e-14, "traced ray against weak field plus second order");
    assert!((tpart + spart - full).abs() < 1e-10, "time half plus space half");
    assert!((bend(ns, "full", 40000) - bend(ns, "full", 80000)).abs() < 1e-9, "neutron star at two step sizes");
    println!("ALL CHECKS PASS");
}
