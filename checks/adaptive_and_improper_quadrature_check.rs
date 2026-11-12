// Adaptive quadrature and awkward integrals -- the same check as the Python, in Rust.
// std only: atan, cos, exp, sqrt and pi are primitives. Every rule, weight and
// integral is computed here. Load in MW, time in hours, energy in MWh.

const XK: [f64; 8] = [0.991455371120812639, 0.949107912342758525, 0.864864423359769073, 0.741531185599394440,
    0.586087235467691130, 0.405845151377397167, 0.207784955007898468, 0.0]; // Kronrod nodes, x >= 0
const WK: [f64; 8] = [0.022935322010529225, 0.063092092629978553, 0.104790010322250184, 0.140653259715525919,
    0.169004726639267903, 0.190350578064785410, 0.204432940075298892, 0.209482141084727828];
const WG: [f64; 4] = [0.129484966168869693, 0.279705391489276668, 0.381830050505118945, 0.417959183673469388];
// WG are the 7-point Gauss weights at XK[1], XK[3], XK[5] and XK[7] = 0
type Panel = (f64, f64, f64, f64); // (lo, hi, K, G)

fn ef(x: f64, d: usize) -> String { format!("{:.*e}", d, x) }

fn pw(x: f64, n: u32) -> f64 { // x to the n by repeated multiplication
    let mut r = 1.0;
    for _ in 0..n { r *= x; }
    r
}

fn legendre(n: usize, x: f64) -> (f64, f64) { // P_n(x) and its slope, three-term recurrence
    let (mut p0, mut p1) = (0.0, 1.0);
    for k in 1..=n {
        let p2 = ((2 * k - 1) as f64 * x * p1 - (k - 1) as f64 * p0) / k as f64;
        p0 = p1;
        p1 = p2;
    }
    (p1, n as f64 * (x * p1 - p0) / (x * x - 1.0))
}

fn kg(f: &dyn Fn(f64) -> f64, a: f64, b: f64) -> (f64, f64) { // Kronrod 15-point K and Gauss 7-point G
    let (c, h) = ((a + b) / 2.0, (b - a) / 2.0);
    let fc = f(c);
    let (mut k, mut g) = (WK[7] * fc, WG[3] * fc);
    for i in 0..7 {
        let s = f(c - h * XK[i]) + f(c + h * XK[i]);
        k += WK[i] * s;
        if i % 2 == 1 { g += WG[i / 2] * s; }
    }
    (k * h, g * h)
}

fn est(p: &Panel) -> f64 { (p.2 - p.3).abs() } // a panel's error estimate |K - G|

fn panel(f: &dyn Fn(f64) -> f64, lo: f64, hi: f64) -> Panel { let (k, g) = kg(f, lo, hi); (lo, hi, k, g) }

fn adaptive(f: &dyn Fn(f64) -> f64, a: f64, b: f64, tol: f64, start: usize) -> (f64, f64, usize, Vec<Panel>) {
    let cut = |j: usize| a + (b - a) * j as f64 / start as f64;
    let mut ps: Vec<Panel> = (0..start).map(|j| panel(f, cut(j), cut(j + 1))).collect();
    while ps.iter().fold(0.0, |s, p| s + est(p)) > tol && ps.len() < 500 {
        let mut w = 0;
        for j in 1..ps.len() { if est(&ps[j]) > est(&ps[w]) { w = j; } }
        let (lo, hi, _, _) = ps.remove(w);
        let mid = (lo + hi) / 2.0;
        ps.push(panel(f, lo, mid));
        ps.push(panel(f, mid, hi));
    }
    let v = ps.iter().fold(0.0, |s, p| s + p.2);
    let e = ps.iter().fold(0.0, |s, p| s + est(p));
    (v, e, 15 * (2 * ps.len() - start), ps)
}

fn uniform(f: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 {
    (0..n).fold(0.0, |s, j| s + kg(f, a + (b - a) * j as f64 / n as f64, a + (b - a) * (j + 1) as f64 / n as f64).0)
}

fn surge(w: f64) -> impl Fn(f64) -> f64 { move |t: f64| 2.0 + 8.0 / (1.0 + ((t - 18.0) / w) * ((t - 18.0) / w)) }
fn surge_exact(w: f64) -> f64 { 48.0 + 8.0 * w * ((6.0 / w).atan() + (18.0 / w).atan()) }
fn planck(x: f64) -> f64 { if x > 700.0 { 0.0 } else { x * x * x / (x.exp() - 1.0) } }

fn main() {
    // ---- 1. the rule's table, checked three ways ----
    let (mut gn, mut gw) = (vec![], vec![]);
    for i in 0..4 { // Newton on P_7 from a cosine guess
        let mut x = (std::f64::consts::PI * (i as f64 + 0.75) / 7.5).cos();
        for _ in 0..8 { let (p, dp) = legendre(7, x); x -= p / dp; }
        gn.push(x);
        let dp = legendre(7, x).1;
        gw.push(2.0 / ((1.0 - x * x) * dp * dp));
    }
    let dn = (0..4).map(|i| (gn[i] - XK[2 * i + 1]).abs()).fold(0.0, f64::max);
    let dw = (0..4).map(|i| (gw[i] - WG[i]).abs()).fold(0.0, f64::max);
    println!("Gauss nodes: Newton on P_7 vs table, max gap {}; weights 2/((1-x^2)P_7'(x)^2), max gap {}", ef(dn, 3), ef(dw, 3));
    let mut a: Vec<Vec<f64>> = (0..8).map(|m| {
        let mut row: Vec<f64> = (0..8).map(|i| legendre(2 * m, XK[i]).0 * if i < 7 { 2.0 } else { 1.0 }).collect();
        row.push(if m == 0 { 2.0 } else { 0.0 });
        row
    }).collect();
    for c in 0..8 { // Kronrod weights from 8 moment equations, Gaussian elimination
        let mut r = c;
        for j in c + 1..8 { if a[j][c].abs() > a[r][c].abs() { r = j; } }
        a.swap(c, r);
        for r in c + 1..8 {
            let q = a[r][c] / a[c][c];
            let pivot = a[c].clone();
            for (u, v) in a[r].iter_mut().zip(pivot.iter()) { *u = *u - q * v; }
        }
    }
    let mut wk = [0.0; 8];
    for c in (0..8).rev() {
        let s = (c + 1..8).fold(0.0, |s, j| s + a[c][j] * wk[j]);
        wk[c] = (a[c][8] - s) / a[c][c];
    }
    let dk = (0..8).map(|i| (wk[i] - WK[i]).abs()).fold(0.0, f64::max);
    println!("Kronrod weights from the moment equations vs table, max gap {}", ef(dk, 3));
    let ex = |n: u32| kg(&|x: f64| pw(x, n), -1.0, 1.0);
    let (e12, e14, e22, e23, e24) = (ex(12).1 - 2.0 / 13.0, ex(14).1 - 2.0 / 15.0, ex(22).0 - 2.0 / 23.0, ex(23).0, ex(24).0 - 2.0 / 25.0);
    println!("exactness on [-1, 1]: G7 errors x^12 {}, x^14 {}; K15 errors x^22 {}, x^23 {}, x^24 {}", ef(e12, 3), ef(e14, 3), ef(e22, 3), ef(e23, 3), ef(e24, 3));
    assert!(dn < 1e-15 && dw < 1e-15 && dk < 1e-14);
    assert!(e22.abs() < 1e-15 && e23.abs() < 1e-15 && e24.abs() > 1e-9 && e14.abs() > 1e-6);

    // ---- 2. the peaked load: 2 MW all day plus a surge to 10 MW at 18:00, half-width 0.25 h ----
    let (load, big_e) = (surge(0.25), surge_exact(0.25));
    println!("load: exact energy 48 + 2(atan 24 + atan 72) = {:.10} MWh", big_e);
    let (k0, g0) = kg(&load, 0.0, 24.0);
    println!("first panel, 0 to 24 h: K15 {:.10}, G7 {:.10}, estimate {}, true error {}", k0, g0, ef((k0 - g0).abs(), 3), ef((k0 - big_e).abs(), 3));
    let (v, e, n, mut ps) = adaptive(&load, 0.0, 24.0, 1e-3, 1);
    let gsum = ps.iter().fold(0.0, |s, p| s + p.3);
    println!("adaptive, tol 1e-3: {:.10} MWh, estimate {}, true error {}, estimate / true {:.0}, {} evaluations, {} panels",
             v, ef(e, 3), ef((v - big_e).abs(), 3), (e / (v - big_e)).abs(), n, ps.len());
    ps.sort_by(|p, q| p.0.partial_cmp(&q.0).unwrap());
    for p in &ps { println!("  panel {:5.2} to {:5.2} h: {:5.2} points per hour", p.0, p.1, 15.0 / (p.1 - p.0)); }
    println!("same panels, G7 values summed: {:.10} MWh, true error {}", gsum, ef((gsum - big_e).abs(), 3));
    assert!((v - big_e).abs() <= e && e <= 1e-3 && (gsum - big_e).abs() > 1e-6);
    for tol in [1e-6, 1e-9, 1e-12] {
        let (v2, e2, n2, p2) = adaptive(&load, 0.0, 24.0, tol, 1);
        println!("adaptive, tol {}: {} evaluations, {} panels, estimate {}, true error {}", ef(tol, 0), n2, p2.len(), ef(e2, 3), ef((v2 - big_e).abs(), 3));
    }
    let ms = [4usize, 8, 16, 32];
    let ue: Vec<f64> = ms.iter().map(|&m| (uniform(&load, 0.0, 24.0, m) - big_e).abs()).collect();
    for j in 0..4 {
        let order = if j > 0 { format!(", observed order {:.1}", (ue[j - 1] / ue[j]).log2()) } else { String::new() };
        println!("uniform, {} panels, {} evaluations: true error {}{}", ms[j], 15 * ms[j], ef(ue[j], 3), order);
    }
    let hh = 24.0 / 144.0;
    let trap = hh * ((0..145).fold(0.0, |s, j| s + load(j as f64 * hh)) - (load(0.0) + load(24.0)) / 2.0);
    println!("ten-minute readings, trapezoid on 145 values: {:.10} MWh, true error {}", trap, ef(trap - big_e, 3));
    assert!(ue[1] > 1e-4 && 1e-9 > (v - big_e).abs() && trap - big_e > 9e-4);

    // ---- 3. out to infinity: Planck's integral of x^3/(e^x - 1) from 0 to infinity is pi^4/15 ----
    let mapped = |t: f64| planck(t / (1.0 - t)) / ((1.0 - t) * (1.0 - t)); // x = t/(1 - t): [0, 1) to [0, infinity)
    let big_p = pw(std::f64::consts::PI, 4) / 15.0;
    let (v, e, n, _) = adaptive(&mapped, 0.0, 1.0, 1e-10, 1);
    println!("Planck: pi^4/15 = {:.11}; mapped to [0, 1): {:.11}, estimate {}, true error {}, {} evaluations", big_p, v, ef(e, 3), ef((v - big_p).abs(), 3), n);
    assert!((v - big_p).abs() < 1e-10);
    let sig = 2.0 * std::f64::consts::PI * pw(1.380649e-23, 4) * v / (pw(6.62607015e-34, 3) * pw(299792458.0, 2));
    println!("Stefan-Boltzmann constant from it: {} W/(m^2 K^4); the sun at 5772 K: {:.1} MW per m^2", ef(sig, 9), sig * pw(5772.0, 4) / 1e6);
    for l in [10.0, 20.0, 40.0] {
        let (vl, _, nl, _) = adaptive(&planck, 0.0, l, 1e-10, 1);
        println!("cut off at x = {}: {:.11}, missing {}, {} evaluations", l, vl, ef(big_p - vl, 3), nl);
    }

    // ---- 4. a spike at an end: the integral of 1/sqrt(x) from 0 to 1 is 2 ----
    let inv_sqrt = |x: f64| 1.0 / x.sqrt();
    let se: Vec<f64> = [1usize, 4, 16, 64].iter().map(|&m| uniform(&inv_sqrt, 0.0, 1.0, m) - 2.0).collect();
    println!("1/sqrt(x), uniform 1, 4, 16, 64 panels: errors {}", se.iter().map(|s| ef(*s, 3)).collect::<Vec<_>>().join(", "));
    let (v, _, n, _) = adaptive(&inv_sqrt, 0.0, 1.0, 1e-8, 1);
    let sub = kg(&|u: f64| 2.0 * u / (u * u).sqrt(), 0.0, 1.0).0;
    println!("adaptive, tol 1e-8: error {}, {} evaluations; substitute x = u^2: one panel, error {}", ef(v - 2.0, 3), n, ef(sub - 2.0, 3));
    assert!((0..3).all(|j| (se[j] / se[j + 1] - 2.0).abs() < 1e-6) && (sub - 2.0).abs() < 1e-15);

    // ---- 5. the trap: a surge 36 seconds wide (half-width 0.005 h) that one panel never sees ----
    let (spike, s) = (surge(0.005), surge_exact(0.005));
    let (v1, e1, n1, _) = adaptive(&spike, 0.0, 24.0, 1e-3, 1);
    let (v24, e24, n24, _) = adaptive(&spike, 0.0, 24.0, 1e-3, 24);
    println!("spike: exact {:.6} MWh; from 1 panel {:.6}, estimate {}, true error {}, {} evaluations", s, v1, ef(e1, 3), ef(v1 - s, 3), n1);
    println!("spike: from 24 hourly panels {:.6}, estimate {}, true error {}, {} evaluations", v24, ef(e24, 3), ef(v24 - s, 3), n24);
    assert!(s - v1 > 0.1 && 1e-3 > (v24 - s).abs());
    println!("ALL CHECKS PASS");
}
