// Navier-Stokes existence and smoothness -- the same check as the Python, in Rust.
// No crates.  It tests the hypotheses of the Clay versions A to D on concrete
// data; it does not, and cannot, test the conjecture itself.
// Units: lengths in cm, speeds in m/s, so time is in units of 0.01 s and water's
// kinematic viscosity 1.0e-6 m^2/s becomes NU = 1.0e-4.
use std::f64::consts::PI;
const NU: f64 = 1.0e-6 / (0.01 * 1.0);
type Field = dyn Fn(f64, f64, f64) -> [f64; 3];

fn swirl(x: f64, y: f64, z: f64, g: fn(f64) -> f64) -> [f64; 3] {
    let s = g((x * x + y * y + z * z).sqrt()); // u = (-y, x, 0) g(r): water turning about z
    [-y * s, x * s, 0.0]
}
fn gauss(r: f64) -> f64 { 2.0 * (-r * r).exp() } // version A datum: dies off fast
fn slow(r: f64) -> f64 { (1.0 + r * r).powf(-1.5) } // smooth, finite energy, slow tail
fn div(f: &Field, x: f64, y: f64, z: f64) -> f64 { // divergence by central differences
    let d = 1e-4;
    ((f(x + d, y, z)[0] - f(x - d, y, z)[0]) + (f(x, y + d, z)[1] - f(x, y - d, z)[1])
        + (f(x, y, z + d)[2] - f(x, y, z - d)[2])) / (2.0 * d)
}
fn tg(x: f64, y: f64, t: f64) -> [f64; 2] { // Taylor-Green flow in the unit cube
    let kw = 2.0 * PI;
    let f = (-2.0 * kw * kw * NU * t).exp();
    [(kw * x).sin() * (kw * y).cos() * f, -(kw * x).cos() * (kw * y).sin() * f]
}
fn tgp(x: f64, y: f64, t: f64) -> f64 {
    let kw = 2.0 * PI;
    0.25 * ((2.0 * kw * x).cos() + (2.0 * kw * y).cos()) * (-4.0 * kw * kw * NU * t).exp()
}
fn residual(x: f64, y: f64, t: f64, p: &dyn Fn(f64, f64, f64) -> f64) -> f64 {
    let (e, u) = (1e-4, tg(x, y, t)); // Navier-Stokes, term by term, by differences
    let mut out: f64 = 0.0;
    for c in 0..2 {
        let dt = (tg(x, y, t + e)[c] - tg(x, y, t - e)[c]) / (2.0 * e);
        let dx = (tg(x + e, y, t)[c] - tg(x - e, y, t)[c]) / (2.0 * e);
        let dy = (tg(x, y + e, t)[c] - tg(x, y - e, t)[c]) / (2.0 * e);
        let lap = (tg(x + e, y, t)[c] + tg(x - e, y, t)[c] + tg(x, y + e, t)[c] + tg(x, y - e, t)[c] - 4.0 * u[c]) / (e * e);
        let gp = (if c == 0 { p(x + e, y, t) - p(x - e, y, t) } else { p(x, y + e, t) - p(x, y - e, t) }) / (2.0 * e);
        out = out.max((dt + u[0] * dx + u[1] * dy + gp - NU * lap).abs());
    }
    out
}
fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }
fn join(v: &[f64]) -> String { v.iter().map(|x| format!("{:.3}", x)).collect::<Vec<_>>().join(", ") }

fn main() {
    // ---- road 1: grid sums over the cube [-6, 6]^3, spacing 0.25 ----
    let (h, n, d) = (0.25f64, 24i32, 1e-4f64);
    let (mut e0, mut y0, mut w0) = (0.0f64, 0.0f64, 0.0f64);
    for i in -n..=n { for j in -n..=n { for k in -n..=n {
        let (x, y, z) = (i as f64 * h, j as f64 * h, k as f64 * h);
        let u = swirl(x, y, z, gauss);
        e0 += 0.5 * (u[0] * u[0] + u[1] * u[1] + u[2] * u[2]);
        for s in [[d, 0.0, 0.0], [0.0, d, 0.0], [0.0, 0.0, d]] { // gradient by differences
            let up = swirl(x + s[0], y + s[1], z + s[2], gauss);
            let um = swirl(x - s[0], y - s[1], z - s[2], gauss);
            y0 += (0..3).map(|c| ((up[c] - um[c]) / (2.0 * d)).powi(2)).sum::<f64>();
        }
        let ex = (-(x * x + y * y + z * z)).exp(); // vorticity, by hand
        w0 += (4.0 * x * z * ex).powi(2) + (4.0 * y * z * ex).powi(2) + ((4.0 - 4.0 * (x * x + y * y)) * ex).powi(2);
    } } }
    let (e0, y0, w0) = (e0 * h.powi(3), y0 * h.powi(3), w0 * h.powi(3));
    let e_exact = (PI / 2.0).powf(1.5);
    println!("house: Clay list 7 problems, 1 solved (Poincare), 6 open; nu = {:.1e} in cm, m/s units", NU);
    println!("swirl peak speed {:.4} m/s at {:.4} cm from the axis", 2.0 * 0.5f64.sqrt() * (-0.5f64).exp(), 0.5f64.sqrt());
    println!("swirl energy E0: grid {:.6}, closed form (pi/2)^1.5 = {:.6}", e0, e_exact);
    println!("swirl in joules (x 1000 kg/m^3 x 1e-6 m^3/cm^3): {:.4e} J", e0 * 1e-3);
    println!("swirl enstrophy: grad u squared {:.6}; vorticity squared {:.6}", y0, w0);
    let sw: &Field = &|a, b, c| swirl(a, b, c, gauss);
    let divs = [div(sw, 0.3, -0.7, 0.5), div(sw, 1.1, 0.4, -0.9)];
    let dmax = divs[0].abs().max(divs[1].abs());
    println!("swirl divergence at two points ~0: {}", yn(dmax < 1e-6));
    let squeeze: &Field = &|a, _b, _c| [a * (-a * a).exp(), 0.0, 0.0];
    println!("a squeezing field (x e^(-x^2), 0, 0) at x = 0: divergence {:.4}", div(squeeze, 0.0, 0.0, 0.0));
    let prod = (2.0 * e0).sqrt() * y0.sqrt();
    println!("small-start size |u0| |grad u0| = {:.4} = {:.4e} nu^2", prod, prod / (NU * NU));
    println!("speed scale that brings it to 1 nu^2: {:.4e} of the swirl's", 1.0 / (prod / (NU * NU)).sqrt());

    // ---- the decay condition (4) along the x-axis: (1 + r)^3 |u(r, 0, 0)| ----
    let rs = [0.0f64, 1.0, 2.0, 4.0, 8.0, 16.0, 32.0, 64.0];
    let fa: Vec<f64> = rs.iter().map(|&r| (1.0 + r).powi(3) * r * gauss(r)).collect();
    let fs: Vec<f64> = rs.iter().map(|&r| (1.0 + r).powi(3) * r * slow(r)).collect();
    println!("chart, r (cm): {}", rs.iter().map(|r| format!("{}", r)).collect::<Vec<_>>().join(", "));
    println!("chart, Gaussian swirl (1+r)^3 |u|: {}", join(&fa));
    println!("chart, slow swirl (1+r)^3 |u|: {}", join(&fs));
    for kk in [3i32, 6, 10] { // largest value of (1+r)^K |u| on the grid
        let (mut mx, mut at) = (-1.0f64, 0.0f64);
        for q in 0..=6400 {
            let r = q as f64 / 100.0;
            let v = (1.0 + r).powi(kk) * r * gauss(r);
            if v > mx { mx = v; at = r; }
        }
        println!("Gaussian swirl: largest (1+r)^{} |u| on a 0.01 cm grid to r = 64 is {:.4}, at r = {:.2}", kk, mx, at);
        assert!(65f64.powi(kk) * 64.0 * gauss(64.0) < 1e-100 && 1e-100 < mx);
    }
    // slow swirl energy: (4 pi / 3) int r^4 SLOW(r)^2 dr; put r = tan(t), so dr = (1 + r^2) dt
    let m = 2000;
    let simp = (0..=m).map(|q| {
        let wq = if q == 0 || q == m { 1.0 } else if q % 2 == 1 { 4.0 } else { 2.0 };
        let rt = (q as f64 * PI / 2.0 / m as f64).tan();
        wq * rt.powi(4) * slow(rt).powi(2) * (1.0 + rt * rt)
    }).sum::<f64>() * (PI / 2.0 / m as f64) / 3.0;
    println!("slow swirl energy: Simpson {:.6}, closed form pi^2/4 = {:.6}", 4.0 * PI / 3.0 * simp, PI * PI / 4.0);

    // ---- the periodic case: Taylor-Green flow in the unit cube, an exact solution ----
    let pts = [(0.13, 0.71, 0.0), (0.42, 0.05, 50.0), (0.88, 0.37, 400.0)];
    let res = pts.iter().map(|&(x, y, t)| residual(x, y, t, &tgp)).fold(0.0, f64::max);
    let flip = |a: f64, b: f64, c: f64| -tgp(a, b, c);
    let bad = pts.iter().map(|&(x, y, t)| residual(x, y, t, &flip)).fold(0.0, f64::max);
    println!("Taylor-Green: residual below 1e-5 at 3 points: {}; pressure sign flipped: residual {:.4}", yn(res < 1e-5), bad);
    let mut cell = 0.0;
    for i in 0..8 { for j in 0..8 {
        let u = tg(i as f64 / 8.0, j as f64 / 8.0, 0.0);
        cell += 0.5 * (u[0] * u[0] + u[1] * u[1]);
    } }
    cell /= 64.0;
    println!("Taylor-Green energy per unit cell: grid {:.6}, by hand 1/4 = {:.6}", cell, 0.25);
    for nn in [1i32, 10, 100] {
        println!("same flow read on all of space: energy in {}^3 cells = {:.2}", nn, cell * (nn as f64).powi(3));
    }
    let half = 2f64.ln() / (4.0 * 4.0 * PI * PI * NU);
    println!("half-life of its energy: ln 2 / (4 k^2 nu) = {:.4} units = {:.4} s", half, half * 0.01);
    println!("Gaussian swirl is not periodic: |u(1.5,0,0) - u(0.5,0,0)| = {:.4}",
             (swirl(1.5, 0.0, 0.0, gauss)[1] - swirl(0.5, 0.0, 0.0, gauss)[1]).abs());

    // ---- A against C: a toy world with D data and F forces (one of them zero) ----
    let tally = |dd: u32, ff: u32| -> [u64; 4] { // bit (d, f) set: that pair breaks down
        let mut cnt = [0u64; 4];
        for w in 0u64..(1 << (dd * ff)) {
            let a = (0..dd).all(|d| (w >> (d * ff)) & 1 == 0); // force 0 never breaks
            cnt[2 * a as usize + (w != 0) as usize] += 1; // C: some pair breaks
        }
        cnt
    };
    let t = tally(2, 2);
    println!("toy worlds 16: A and C {}, A only {}, C only {}, neither {}", t[3], t[2], t[1], t[0]);
    println!("checked for D, F <= 3: 'neither' never happens");
    for d2 in 1..4u32 { for f2 in 1..4u32 {
        let (all, a_true) = (1u64 << (d2 * f2), 1u64 << (d2 * (f2 - 1)));
        assert_eq!(tally(d2, f2), [0, all - a_true, 1, a_true - 1]);
    } }
    assert!((e0 - e_exact).abs() < 1e-9 && (y0 - w0).abs() < 1e-6 * w0); // two roads, twice
    assert!((4.0 * PI / 3.0 * simp - PI * PI / 4.0).abs() < 1e-9);
    assert!(dmax < 1e-6 && (div(squeeze, 0.0, 0.0, 0.0) - 1.0).abs() < 1e-6);
    assert!(res < 1e-5 && bad > 0.1 && (cell - 0.25f64).abs() < 1e-12);
    assert!(fs[7] > fs[6] && fs[6] > fs[5] && fs[5] > fs[4] && fs[7] > 60.0 && fa[7] < 1e-100);
    println!("ALL CHECKS PASS");
}
