// Singular integrals and the Hilbert transform bound -- the check behind the card.
// Rust std only.  Signal: a gate g, 1 V while |t| < W/2, t in ms, W = 1 ms.
// Its Hilbert transform is Hg(t) = (1/pi) ln|(t + W/2)/(t - W/2)|, in volts.
use std::f64::consts::PI;

const W: f64 = 1.0; // gate width, ms
const C: f64 = W / 2.0;

fn g(t: f64) -> f64 { if t.abs() < C { 1.0 } else { 0.0 } }
fn hg(t: f64) -> f64 { ((t + C) / (t - C)).abs().ln() / PI }

fn midpoint<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    h * (0..n).map(|k| f(a + (k as f64 + 0.5) * h)).fold(0.0, |s, v| s + v)
}

// (1/pi) integral of g(t-u)/u, with the gap -e_neg < u < e_pos cut out
fn pv(t: f64, e_neg: f64, e_pos: f64) -> f64 {
    let n = 400000;
    let pos = midpoint(|s| g(t - s.exp()), e_pos.ln(), 10f64.ln(), n);
    let neg = midpoint(|s| g(t + s.exp()), e_neg.ln(), 10f64.ln(), n);
    (pos - neg) / PI
}

// integral of |Hg|^p over the line, by time: t = c -+ v^3 near the spike, t = 1/w far out
fn power_integral(p: f64) -> f64 {
    let n = 40000;
    let a = C.powf(1.0 / 3.0);
    let near = midpoint(|v| 3.0 * v * v * (hg(C - v.powf(3.0)).abs().powf(p) + hg(C + v.powf(3.0)).abs().powf(p)), 0.0, a, n);
    let far = midpoint(|w| hg(1.0 / w).abs().powf(p) / (w * w), 0.0, 1.0 / (2.0 * C), n);
    2.0 * (near + far)
}

fn m(a: f64) -> f64 { 2.0 * W / (PI * a).sinh() } // measure of {|Hg| > a}, in ms

// integral of sin(u)/u from 0 to x, by its series
fn si(x: f64) -> f64 {
    let (mut term, mut s, mut k) = (x, x, 0.0f64);
    while term.abs() > 1e-17 {
        k += 1.0;
        term *= -x * x * (2.0 * k - 1.0) / ((2.0 * k + 1.0) * (2.0 * k) * (2.0 * k + 1.0));
        s += term;
    }
    s
}

fn f_anti(t: f64) -> f64 { ((t + C) * (t + C).ln() - (t - C) * (t - C).abs().ln()) / PI }
fn area(r: f64) -> f64 { 2.0 * (f_anti(r) - f_anti(0.0)) }

fn main() {
    // The partner of the gate: kernel road against the closed form, and the logarithmic spike.
    for t in [0.3, 1.0, 2.0] {
        let k = pv(t, 1e-6, 1e-6);
        println!("Hg({:.1} ms): closed form {:.6} V, kernel road {:.6} V", t, hg(t), k);
        assert!((k - hg(t)).abs() < 1e-4);
    }
    for d in [0.1, 0.01, 0.001, 0.0001, 0.00001, 0.000001] {
        println!("spike: {:.6} ms past the edge, Hg = {:.3} V", d, hg(C + d));
    }
    println!("spike growth per factor of ten closer: ln(10)/pi = {:.6} V", 10f64.ln() / PI);

    // Energy: the multiplier -i sgn has size 1, so the energy of Hg equals the energy of g, W.
    let l = 1000.0;
    let fr = 2.0 * midpoint(|x| ((PI * W * x).sin() / (PI * x)).powf(2.0), 0.0, l, 200000);
    println!("energy of g: W = {:.6} V^2 ms", W);
    println!("frequency road: integral of |m ghat|^2 up to {:.0} kHz = {:.6}, tail at most {:.6}", l, fr, 2.0 / (PI * PI * l));
    assert!(W - fr >= 0.0 && W - fr <= 2.0 / (PI * PI * l));
    let e_time = power_integral(2.0);
    let e_dist = midpoint(|a| 2.0 * a * m(a), 0.0, 30.0, 60000);
    let e_ser = 8.0 * W / PI.powf(2.0) * (0..200000u64).map(|k| 1.0 / ((2 * k + 1) * (2 * k + 1)) as f64).fold(0.0, |s, v| s + v);
    println!("time road: integral of Hg^2 = {:.6} V^2 ms", e_time);
    println!("level-set road: integral of 2a m(a) da = {:.6} V^2 ms", e_dist);
    println!("series road: (8W/pi^2)(1 + 1/9 + 1/25 + ...) = {:.6} V^2 ms", e_ser);
    assert!((e_time - W).abs() < 1e-6 && (e_dist - W).abs() < 1e-6 && (e_ser - W).abs() < 1e-5);

    // Level sets, weak type (1,1): m(a) = 2W/sinh(pi a), counted on a grid.
    for a in [0.1, 0.5, 1.0, 2.0] {
        let r = (PI * a).exp();
        let (inner, outer) = (C * (r - 1.0) / (r + 1.0), C * (r + 1.0) / (r - 1.0));
        let h = 1e-4;
        let kmax = (2.0 * outer / h) as i64;
        let cnt = (-kmax..kmax).filter(|&k| hg((k as f64 + 0.5) * h).abs() > a).count() as f64 * h;
        println!("level {:.1} V: set from {:.6} to {:.6} ms each side; measure {:.6} ms, grid count {:.4} ms; a x measure {:.6} V ms",
                 a, inner, outer, m(a), cnt, a * m(a));
        assert!((cnt - m(a)).abs() < 2e-3 && a * cnt < 2.0 * W / PI);
    }
    let r = (PI / 2.0).exp();
    println!("by hand at level 0.5 V: r = e^(pi a) = {:.6}, r - 1 = {:.6}, r + 1 = {:.6}, sinh(pi a) = {:.6}", r, r - 1.0, r + 1.0, (PI / 2.0).sinh());
    println!("weak-type ratio a m(a) / ||g||_1 tends to 2/pi = {:.6} as a -> 0", 2.0 / PI);

    // Failure in mass: the area of |Hg| inside |t| < R grows by (2W/pi) ln 10 per factor of ten.
    let num = 2.0 * (midpoint(|v| 3.0 * v * v * (hg(C - v.powf(3.0)) + hg(C + v.powf(3.0))), 0.0, C.powf(1.0 / 3.0), 40000)
        + midpoint(hg, 2.0 * C, 10.0, 200000));
    println!("area of g: {:.6} V ms; area of |Hg| inside 10 ms: antiderivative {:.6}, integral {:.6} V ms", W, area(10.0), num);
    assert!((num - area(10.0)).abs() < 1e-6);
    for r in [100, 1000, 10000] {
        println!("area of |Hg| inside {} ms: {:.6} V ms", r, area(r as f64));
    }
    println!("growth per decade (2W/pi) ln 10 = {:.6} V ms", 2.0 * W * 10f64.ln() / PI);
    assert!((area(10000.0) - area(1000.0) - 2.0 * W * 10f64.ln() / PI).abs() < 1e-6);

    // Kernel conditions for K(t) = 1/(pi t): size, smoothness (Hormander), cancellation.
    for y in [1.0, 0.01] {
        let hor = midpoint(|s| y / (2.0 * y * s.exp() - y) + y / (2.0 * y * s.exp() + y), 0.0, 50.0, 100000) / PI;
        println!("Hormander integral at y = {:.2} ms: {:.6}, closed form ln(3)/pi = {:.6}", y, hor, 3f64.ln() / PI);
        assert!((hor - 3f64.ln() / PI).abs() < 1e-6);
    }
    let cap = 2.0 / PI * si(PI);
    println!("cut kernel's multiplier is at most (2/pi) Si(pi) = (2/pi) x {:.6} = {:.6} for every cut-off", si(PI), cap);
    assert!((si(PI) - midpoint(|u| u.sin() / u, 0.0, PI, 20000)).abs() < 1e-8);
    let eps = 0.001;
    for r in [1, 10, 100, 1000] {
        let rf = r as f64;
        let q = |xi: f64| 2.0 / PI * (si(2.0 * PI * xi * rf) - si(2.0 * PI * xi * eps)); // size of the cut multiplier, by Si
        let direct = 2.0 / PI * midpoint(|t| (PI * t / rf).sin() / t, eps, rf, 20000); // (2/pi) int sin(2 pi xi t)/t dt at xi = 1/(2R)
        let top = (1..=4000).map(|k| q(k as f64 / (2000.0 * rf))).fold(f64::MIN, f64::max); // 4000 frequencies up to 2/R
        println!("cut {:.3} < |t| < {} ms: mass of |K| {:.6}, multiplier at 1/(2R) {:.6}, direct {:.6}; largest up to 2/R {:.6}",
                 eps, r, 2.0 / PI * (rf / eps).ln(), q(1.0 / (2.0 * rf)), direct, top);
        assert!((direct - q(1.0 / (2.0 * rf))).abs() < 1e-6 && top <= cap && cap - top < 0.0021);
    }
    let lop = pv(0.0, eps, 2.0 * eps);
    println!("lopsided gap (-eps, 2eps) at t = 0: {:.6} V, true Hg(0) = {:.6} V, -ln(2)/pi = {:.6}", lop, hg(0.0), -(2f64.ln()) / PI);
    assert!((lop + 2f64.ln() / PI).abs() < 1e-4);

    // L^p: Riesz's theorem with the best constant cot(pi/2p) for p >= 2 (Pichorides); the gate at p = 4.
    let q_time = power_integral(4.0);
    let q_dist = midpoint(|a| 4.0 * a.powf(3.0) * m(a), 0.0, 30.0, 60000);
    println!("p = 4: integral of Hg^4 by time {:.6}, by level sets {:.6}; ||Hg||_4/||g||_4 = {:.6}; bound cot(pi/8) = {:.6}",
             q_time, q_dist, (q_time / W).powf(0.25), 1.0 / (PI / 8.0).tan());
    assert!((q_time - q_dist).abs() < 1e-5 && (q_time / W).powf(0.25) <= 1.0 / (PI / 8.0).tan());
    println!("p = 2 bound: 1, attained by every signal; p = 1: no bound (area above grows without limit)");

    // Chart points.
    let ts: Vec<f64> = (0..30).map(|k| -1.45 + 0.1 * k as f64).collect();
    let j = |v: Vec<String>| v.join(", ");
    println!("chart t ms: [{}]", j(ts.iter().map(|t| format!("{:.2}", t)).collect()));
    println!("chart g V: [{}]", j(ts.iter().map(|&t| format!("{:.0}", g(t))).collect()));
    println!("chart Hg V: [{}]", j(ts.iter().map(|&t| format!("{:.3}", hg(t))).collect()));
    println!("ALL CHECKS PASS");
}
