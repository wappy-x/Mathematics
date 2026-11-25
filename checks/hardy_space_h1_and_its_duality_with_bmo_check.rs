// Hardy space H1 and its duality with BMO -- the check behind the card.
// std only.  x counts milliseconds; signals are in volts.
// Atom pair a = +1 V on (0, 1), -1 V on (-1, 0).  Gate b = 1 V on (0, 1).  phi(x) = log|x - 1/2|.
use std::f64::consts::{E, PI};

fn ha(x: f64) -> f64 { (x * x / (x * x - 1.0).abs()).ln() / PI } // Hilbert transform of a
fn hb(x: f64) -> f64 { (x / (x - 1.0)).abs().ln() / PI }         // Hilbert transform of b
fn a(x: f64) -> f64 {
    (if 0.0 < x && x < 1.0 { 1.0 } else { 0.0 }) - (if -1.0 < x && x < 0.0 { 1.0 } else { 0.0 })
}
fn midpoint(f: &dyn Fn(f64) -> f64, lo: f64, hi: f64, n: usize) -> f64 {
    let h = (hi - lo) / n as f64;
    h * (0..n).map(|k| f(lo + (k as f64 + 0.5) * h)).sum::<f64>()
}
fn pv(x: f64, n: usize) -> f64 { // (1/pi) p.v. integral of a(x - u)/u du
    let pos = midpoint(&|s: f64| a(x - s.exp()), 1e-6f64.ln(), 20f64.ln(), n);
    let neg = midpoint(&|s: f64| a(x + s.exp()), 1e-6f64.ln(), 20f64.ln(), n);
    (pos - neg) / PI
}
fn g(x: f64) -> f64 { 2.0 * x * x.ln() - (x - 1.0) * (x - 1.0).abs().ln() - (x + 1.0) * (x + 1.0).ln() }
fn pieces(f: &dyn Fn(f64) -> f64, n: usize) -> [f64; 4] { // (0,1/2), (1/2,1), (1,2), (2,inf)
    let r = 0.5f64.sqrt();
    [midpoint(&|v: f64| 2.0 * v * f(v * v), 0.0, r, n), midpoint(&|v: f64| 2.0 * v * f(1.0 - v * v), 0.0, r, n),
     midpoint(&|v: f64| 2.0 * v * f(1.0 + v * v), 0.0, 1.0, n), midpoint(&|w: f64| f(1.0 / w) / (w * w), 0.0, 0.5, n)]
}
fn k(x: f64) -> f64 { x * x.abs().ln() - (x - 1.0) * (x - 1.0).abs().ln() }
fn l(x: f64) -> f64 { (x + 1.0) * (x + 1.0).abs().ln() - x * x.abs().ln() }
fn gate_area(r: f64) -> f64 { (k(r) + k(-r) - 2.0 * k(0.5)) / PI }
fn decade(w: f64) -> f64 { // area of |H(b - w c)| added between 1000 and 10000, both sides
    let p2 = |x: f64| (k(x) - w * l(x)) / PI;
    (p2(1e4) - p2(1e3)).abs() + (p2(-1e3) - p2(-1e4)).abs()
}
fn ff(x: f64) -> f64 { if x != 0.0 { x * x.abs().ln() - x } else { 0.0 } } // antiderivative of log|x|
fn osc(lo: f64, hi: f64) -> (f64, f64) { // mean of log|x| on (lo, hi) and its mean oscillation, exact
    let m = (ff(hi) - ff(lo)) / (hi - lo);
    let mut cuts = vec![lo, hi];
    for p in [-m.exp(), 0.0, m.exp()] { if lo < p && p < hi { cuts.push(p); } }
    cuts.sort_by(|x, y| x.partial_cmp(y).unwrap());
    let s: f64 = cuts.windows(2).map(|w| (ff(w[1]) - ff(w[0]) - m * (w[1] - w[0])).abs()).sum();
    (m, s / (hi - lo))
}

fn main() {
    for x in [0.3, 1.5, 3.0, 10.0] {
        let kr = pv(x, 400000);
        println!("Ha({:.1}): closed form {:.6} V, kernel road {:.6} V", x, ha(x), kr);
        assert!((kr - ha(x)).abs() < 1e-4);
    }
    for x in [10.0f64, 100.0] {
        println!("tail at x = {}: x^2 Ha = {:.6}, x Hb = {:.6}, 1/pi = {:.6}", x as i64, x * x * ha(x), x * hb(x), 1.0 / PI);
    }
    assert!((1e4 * ha(100.0) - 1.0 / PI).abs() < 1e-4);
    assert!((100.0 * hb(100.0) - 1.0 / PI).abs() < 2e-3);
    for kk in 1..7 {
        let x = 10f64.powf(kk as f64 / 2.0);
        println!("chart log10 x = {:.1}: log10 Ha = {:.3}, log10 Hb = {:.3}", kk as f64 / 2.0, ha(x).ln() / 10f64.ln(), hb(x).ln() / 10f64.ln());
    }
    // Area of |Ha|: antiderivative G against the integrator on four pieces of x > 0.
    let s = 1.0 / 2f64.sqrt();
    let p_abs = pieces(&|x: f64| ha(x).abs(), 200000);
    let p = pieces(&ha, 200000);
    let (area_exact, area_num) = (-4.0 * g(s) / PI, 2.0 * p_abs.iter().sum::<f64>());
    let tot: f64 = p.iter().sum();
    println!("Ha changes sign at x = {:.6}, where G = {:.6}", s, g(s));
    println!("area of |Ha|: antiderivative {:.6}, integrator {:.6} V ms", area_exact, area_num);
    println!("size of the total of Ha: integrator {:.6} V ms (antiderivative: exactly 0)", (2.0 * tot).abs());
    assert!((area_num - area_exact).abs() < 1e-5);
    assert!((2.0 * tot).abs() < 1e-5);
    let (near, far) = (2.0 * (p_abs[0] + p_abs[1] + p_abs[2]), 2.0 * p_abs[3]);
    let b = 3f64.ln() / PI; // Hormander constant of 1/(pi t)
    let hor = midpoint(&|v: f64| 1.0 / (2.0 * v.exp() - 1.0) + 1.0 / (2.0 * v.exp() + 1.0), 0.0, 50.0, 100000) / PI; // its integral, x = +-2e^v
    println!("Hormander constant B: ln 3/pi = {:.6}; integral of |K(x - 1) - K(x)| over |x| > 2 = {:.6}", b, hor);
    assert!((hor - b).abs() < 1e-6);
    let r2 = 2.0 * 2f64.sqrt();
    println!("near part |x| < 2: {:.6}, bound 2 sqrt 2 = {:.6}; far part: {:.6}, bound 2B = {:.6}", near, r2, far, 2.0 * b);
    assert!((far - 2.0 * -g(2.0) / PI).abs() < 1e-5);
    assert!(near < r2);
    assert!(far < 2.0 * b);
    println!("atom bound for a = 2(sqrt 2 + B), also the L-infinity to BMO constant: {:.6}; true area {:.6}; ratio {:.6}", r2 + 2.0 * b, area_exact, area_exact / (r2 + 2.0 * b));
    // The gate fails: the area of |Hb| inside |x| < R grows by (2/pi) ln 10 per factor of ten.
    let hba = |x: f64| hb(x).abs();
    let num = midpoint(&|v: f64| 2.0 * v * hba(-v * v), 0.0, 10f64.sqrt(), 400000) + midpoint(&|v: f64| 2.0 * v * hba(v * v), 0.0, 0.5f64.sqrt(), 200000)
        + midpoint(&|v: f64| 2.0 * v * hba(1.0 - v * v), 0.0, 0.5f64.sqrt(), 200000) + midpoint(&|v: f64| 2.0 * v * hba(1.0 + v * v), 0.0, 3.0, 400000);
    println!("area of |Hb| inside |x| < 10: antiderivative {:.6}, integrator {:.6} V ms", gate_area(10.0), num);
    assert!((num - gate_area(10.0)).abs() < 1e-4);
    println!("area of |Hb| inside 100, 1000, 10000: {:.6}, {:.6}, {:.6} V ms", gate_area(100.0), gate_area(1000.0), gate_area(10000.0));
    for (w, name) in [(0.0, "gate b"), (0.9, "10% imbalance"), (1.0, "atom pair a")] {
        println!("decade 1000 to 10000, {}: {:.6} V ms", name, decade(w));
    }
    assert!((decade(0.9) - 0.1 * 2.0 * 10f64.ln() / PI).abs() < 1e-4);
    assert!((decade(1.0) - (2.0 / PI) * (1e-3 - 1e-4)).abs() < 1e-6);
    // Pairing a with phi(x) = log|x - 1/2|: exact, integrator, and through the Hilbert transform.
    let (right, left) = (ff(0.5) - ff(-0.5), ff(1.5) - ff(0.5));
    let pair = right - left;
    println!("hand steps: ln 2 = {:.6}, ln 1.5 = {:.6}, ln 3 = {:.6}, 0.5 ln 0.5 - 0.5 = {:.6}, 1.5 ln 1.5 - 1.5 = {:.6}",
             2f64.ln(), 1.5f64.ln(), 3f64.ln(), ff(0.5), ff(1.5));
    let num_r = 2.0 * midpoint(&|v: f64| 2.0 * v * (v * v).ln(), 0.0, 0.5f64.sqrt(), 200000);
    let num_l = midpoint(&|x: f64| (x - 0.5).abs().ln(), -1.0, 0.0, 200000);
    println!("phi over (0,1): {:.6}; over (-1,0): {:.6}; pairing {:.6} V ms, -1.5 ln 3 = {:.6}", right, left, pair, -1.5 * 3f64.ln());
    let road_h = -(PI / 2.0) * ((p[1] + p[2] + p[3]) - (tot + p[0])); // -(pi/2) integral of Ha sgn(x - 1/2)
    println!("pairing by integrator {:.6}; by Hilbert road -(pi/2) int Ha sgn(x - 1/2): {:.6} V ms", num_r - num_l, road_h);
    assert!((pair + 1.5 * 3f64.ln()).abs() < 1e-12);
    assert!((num_r - num_l - pair).abs() < 1e-5);
    assert!((road_h - pair).abs() < 1e-5);
    // Mean oscillation of phi on I = (-1, 1), which is log|u| on (-1.5, 0.5).
    let (m, o) = osc(-1.5, 0.5);
    let o_num = (midpoint(&|v: f64| 2.0 * v * ((v * v).ln() - m).abs(), 0.0, 1.5f64.sqrt(), 200000)
        + midpoint(&|v: f64| 2.0 * v * ((v * v).ln() - m).abs(), 0.0, 0.5f64.sqrt(), 200000)) / 2.0;
    println!("on I = (-1,1): mean of phi {:.6}, mean oscillation exact {:.6}, integrator {:.6}", m, o, o_num);
    assert!((o_num - o).abs() < 1e-5);
    println!("atom bound 2 x oscillation = {:.6} >= |pairing| {:.6}, ratio {:.6}", 2.0 * o, -pair, -pair / (2.0 * o));
    assert!(-pair <= 2.0 * o);
    let mut best = (0.0f64, 0.0f64); // (oscillation, centre/radius), scanned from 0 to 4
    for kk in 0..4001 {
        let c = kk as f64 / 1000.0;
        let v = osc(c - 1.0, c + 1.0).1;
        if (v, c) > best { best = (v, c); }
    }
    let (mut lo, mut hi) = (best.1 - 0.001, best.1 + 0.001);
    for _ in 0..60 { // golden-section search for the peak
        let (pp, q) = (hi - (hi - lo) * 0.618034, lo + (hi - lo) * 0.618034);
        if osc(pp - 1.0, pp + 1.0).1 > osc(q - 1.0, q + 1.0).1 { hi = q; } else { lo = pp; }
    }
    let bmo = osc(lo - 1.0, lo + 1.0).1;
    println!("BMO norm of log|x|: centred intervals {:.6} = 2/e {:.6}; largest {:.6} at centre/radius {:.4}", osc(-1.0, 1.0).1, 2.0 / E, bmo, lo);
    assert!((osc(-1.0, 1.0).1 - 2.0 / E).abs() < 1e-12);
    assert!(bmo >= best.0);
    assert!(bmo >= o);
    let mut grid = f64::NEG_INFINITY; // road 2: intervals [u, 1], u = -1 to 0.999
    for kk in 0..2000 { grid = grid.max(osc(kk as f64 / 1000.0 - 1.0, 1.0).1); }
    println!("BMO norm, second road: largest over 2000 intervals [u, 1]: {:.6}", grid);
    assert!(-1e-12 < bmo - grid && bmo - grid < 1e-5);
    println!("duality bound |pairing| <= 2 x BMO norm = {:.6}; Hilbert-road bound (pi/2) x area |Ha| = {:.6}", 2.0 * bmo, PI / 2.0 * area_exact);
    // L1 is not enough: gates of area 1 squeezed onto phi's spike pair to log(eps/2) - 1, without limit.
    for eps in [0.1f64, 0.01, 0.001] {
        println!("gate of width {:.3} at 1/2, area 1: pairing {:.6}", eps, (eps / 2.0).ln() - 1.0);
    }
    let nar = 2.0 * midpoint(&|v: f64| 2.0 * v * (v * v).ln(), 0.0, 0.05f64.sqrt(), 200000) / 0.1;
    assert!((nar - (0.05f64.ln() - 1.0)).abs() < 1e-5);
    println!("ALL CHECKS PASS");
}
