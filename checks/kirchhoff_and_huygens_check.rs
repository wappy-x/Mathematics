// Kirchhoff and Huygens: a handclap heard 17.15 m away, in space (3D) and in a flat world (2D).
// 3D roads: the closed form from r*u obeying the 1-D wave equation; Kirchhoff's sphere mean by
// Simpson's rule; the equation's residual by centred differences. 2D roads: Poisson's formula
// around the clap, by elliptic integrals; descent, the 3D sphere mean of a cylinder, around the
// listener; a tail series for late times.
use std::f64::consts::PI;
const C: f64 = 343.0; // m/s
const R: f64 = 17.15; // m
const A: f64 = 0.1715; // m
const V: f64 = 2.4e5; // Pa/s (illustrative peak rate of the clap)
const MS: f64 = 1e-3;

fn g(s: f64) -> f64 { // the clap: the rate at which the pressure starts rising, Pa/s
    if s < A { V * (1.0 - s * s / (A * A)).powf(2.0) } else { 0.0 }
}
fn simpson(f: &dyn Fn(f64) -> f64, lo: f64, hi: f64, n: usize) -> f64 {
    let h = (hi - lo) / n as f64;
    let mut s = 0.0;
    for j in 1..n { s += (if j % 2 == 1 { 4.0 } else { 2.0 }) * f(lo + j as f64 * h); }
    (f(lo) + f(hi) + s) * h / 3.0
}
fn u3_closed(r: f64, t: f64) -> f64 { // 3D: r*u is a 1-D wave
    let d = r - C * t;
    if d.abs() < A { V * A * A * (1.0 - d * d / (A * A)).powf(3.0) / (12.0 * C * r) } else { 0.0 }
}
fn u3_mean(r: f64, t: f64) -> f64 { // 3D: Kirchhoff, t times the mean of g over the sphere of radius c t
    let rho = C * t;
    let mu0 = f64::max(-1.0, (r * r + rho * rho - A * A) / (2.0 * r * rho));
    if mu0 >= 1.0 { return 0.0; }
    t * 0.5 * simpson(&|mu: f64| g(f64::max(0.0, r * r + rho * rho - 2.0 * r * rho * mu).sqrt()), mu0, 1.0, 400)
}
fn ell_k(k: f64) -> f64 { // complete elliptic integral of the first kind, by the arithmetic-geometric mean
    let (mut a, mut b) = (1.0f64, (1.0 - k * k).sqrt());
    while (a - b).abs() > 1e-15 * a { let a2 = (a + b) / 2.0; b = (a * b).sqrt(); a = a2; }
    PI / (2.0 * a)
}
fn ring(s: f64, t: f64) -> f64 { // integral over the clap's ring of radius s of 1/sqrt(c^2 t^2 - |y - x|^2)
    let p = (C * t).powf(2.0) - R * R - s * s;
    let q = 2.0 * s * R;
    if p <= -q { return 0.0; }
    if p >= q { return 4.0 * ell_k((2.0 * q / (p + q)).sqrt()) / (p + q).sqrt(); }
    4.0 * ell_k(((p + q) / (2.0 * q)).sqrt()) / (2.0 * q).sqrt()
}
fn u2_poisson(t: f64, n: usize) -> f64 { // 2D: Poisson's formula, ring integrals summed over s
    let mut cuts = vec![0.0, A];
    for x in [C * t - R, R - C * t] { if 0.0 < x && x < A { cuts.push(x); } }
    cuts.sort_by(|a, b| a.partial_cmp(b).unwrap());
    cuts.dedup();
    let mut tot = 0.0;
    for w in cuts.windows(2) {
        let (p, q) = (w[0], w[1]);
        for j in 0..n {
            let tau = (j as f64 + 0.5) / n as f64;
            let s = p + (q - p) * (1.0 - (PI * tau).cos()) / 2.0;
            tot += s * g(s) * ring(s, t) * (q - p) * PI / 2.0 * (PI * tau).sin() / n as f64;
        }
    }
    tot / (2.0 * PI * C)
}
fn u2_descent(t: f64, n: usize) -> f64 { // 2D by descent: the 3D sphere mean of a cylinder, flattened
    let rho = C * t;
    if rho <= R - A { return 0.0; }
    let al = (A / R).asin();
    let (lo, hi) = (((R - A) / rho).asin(), f64::min(1.0, (R + A) / rho).asin());
    let inner = |ph: f64| simpson(&|ps: f64| g(f64::max(0.0, R * R + (rho * ps.sin()).powf(2.0) + 2.0 * R * rho * ps.sin() * ph.cos()).sqrt()) * ps.sin(), lo, hi, n);
    t / (2.0 * PI) * 2.0 * simpson(&inner, PI - al, PI, n)
}
fn u2_tail(t: f64) -> f64 { // 2D after the pulse: series in a^2/D, with D = c^2 t^2 - R^2
    let d = (C * t).powf(2.0) - R * R;
    V * A * A / (6.0 * C * d.sqrt()) * (1.0 + A * A / 4.0 * (1.0 / (2.0 * d) + 3.0 * R * R / (4.0 * d * d)))
}
fn u2_circle(t: f64) -> f64 { // the mistake: Kirchhoff's surface-only shape used in 2D
    let rho = C * t;
    let m = (R * R + rho * rho - A * A) / (2.0 * R * rho); // the circle meets the clap where cos(ph) > m
    if m >= 1.0 { return 0.0; }
    t / PI * simpson(&|ph: f64| g(f64::max(0.0, R * R + rho * rho - 2.0 * R * rho * ph.cos()).sqrt()), 0.0, f64::max(-1.0, m).acos(), 4000)
}
fn resid(t: f64, h: f64) -> f64 { // u_tt - c^2 (u_rr + 2 u_r / r) by centred differences, relative to c^2 u_rr
    let k = h / (2.0 * C); // a time step that is not the r-step over c, so the test is not exact by luck
    let utt = (u3_closed(R, t + k) - 2.0 * u3_closed(R, t) + u3_closed(R, t - k)) / (k * k);
    let urr = (u3_closed(R + h, t) - 2.0 * u3_closed(R, t) + u3_closed(R - h, t)) / (h * h);
    let ur = (u3_closed(R + h, t) - u3_closed(R - h, t)) / (2.0 * h);
    (utt - C * C * (urr + 2.0 * ur / R)) / (C * C * urr)
}
fn sci(x: f64) -> String { // Python's 1.234e-05 style
    let s = format!("{:.3e}", x);
    let (m, e) = s.split_once('e').unwrap();
    let ev: i32 = e.parse().unwrap();
    format!("{}e{}{:02}", m, if ev < 0 { "-" } else { "+" }, ev.abs())
}
fn join(v: Vec<f64>) -> String { v.iter().map(|x| format!("{:.4}", x)).collect::<Vec<_>>().join(", ") }

fn main() {
    println!("setup: c = {:.0} m/s, listener at R = {:.2} m, clap radius a = {:.4} m, peak rate V = {:.0} Pa/s", C, R, A, V);
    println!("sound can arrive only from (R - a)/c = {:.3} ms to (R + a)/c = {:.3} ms in 3D", (R - A) / C / MS, (R + A) / C / MS);
    println!("by hand: Q = {:.0} Pa m^2/s, D at 100 ms = {:.1} m^2, shell 2a = {:.1} cm", PI * V * A * A / 3.0, (C * 0.1).powf(2.0) - R * R, 200.0 * A);
    println!("by hand: R - ct at 49.75 ms = {:.5} m, at 50.60 ms = {:.4} m", R - C * 49.75 * MS, R - C * 50.6 * MS);
    println!("3D pressure at the listener, Pa: time, closed form, Kirchhoff sphere mean");
    for tm in [49.40, 49.75, 50.00, 50.25, 51.00, 100.0] {
        let (a3, b3) = (u3_closed(R, tm * MS), u3_mean(R, tm * MS));
        println!("  {:7.2} ms  {:.6}  {:.6}", tm, a3, b3);
        assert!((a3 - b3).abs() < 1e-9);
    }
    assert!(u3_mean(R, 50.6 * MS) == 0.0 && u3_mean(R, 100.0 * MS) == 0.0); // Huygens: silence once the shell has passed
    let (r1, r2) = (resid(49.9 * MS, 2e-3), resid(49.9 * MS, 1e-3));
    println!("3D residual of the wave equation at 49.90 ms: step 2 mm {}, step 1 mm {}, ratio {:.2}", sci(r1), sci(r2), r1 / r2);
    assert!(r1.abs() < 1e-3 && 3.5 < r1 / r2 && r1 / r2 < 4.5);
    println!("2D pressure at the listener, Pa: time, Poisson by elliptic integrals, descent");
    for tm in [49.40, 49.75, 50.00, 50.25, 50.50, 51.00] {
        let (a2, b2) = (u2_poisson(tm * MS, 1000), u2_descent(tm * MS, 200));
        println!("  {:7.2} ms  {:.6}  {:.6}", tm, a2, b2);
        assert!((a2 - b2).abs() <= 1e-4 * a2 + 1e-9);
    }
    assert!(u2_poisson(49.4 * MS, 1000) == 0.0 && u2_descent(49.4 * MS, 200) == 0.0); // nothing outruns c, in 2D too
    let (mut pk, mut tpk) = (f64::MIN, 0.0);
    for j in 0..76 {
        let x = 49.5 + 0.02 * j as f64;
        let v = u2_poisson(x * MS, 400);
        if v > pk || (v == pk && x > tpk) { pk = v; tpk = x; }
    }
    let (mut lo, mut hi) = (tpk - 0.02, tpk + 0.02); // refine the grid's best by golden-section search, ms
    for _ in 0..40 {
        let (m1, m2) = (hi - 0.618034 * (hi - lo), lo + 0.618034 * (hi - lo));
        if u2_poisson(m1 * MS, 1000) < u2_poisson(m2 * MS, 1000) { lo = m1; } else { hi = m2; }
    }
    tpk = (lo + hi) / 2.0;
    pk = u2_poisson(tpk * MS, 1000);
    println!("2D peak: {:.4} Pa at {:.3} ms", pk, tpk);
    println!("2D tail, Pa: time, Poisson, descent, tail series, crude Q/(2 pi c^2 t)");
    let (mut t55, mut t100, mut t1000) = (0.0, 0.0, 0.0);
    for tm in [55.0, 60.0, 70.0, 100.0, 200.0, 500.0, 1000.0] {
        let t = tm * MS;
        let (a2, b2, c2, d2) = (u2_poisson(t, 1000), u2_descent(t, 200), u2_tail(t), V * A * A / (6.0 * C * C * t));
        if tm == 55.0 { t55 = a2; }
        if tm == 100.0 { t100 = a2; }
        if tm == 1000.0 { t1000 = a2; }
        println!("  {:7.1} ms  {:.6}  {:.6}  {:.6}  {:.6}", tm, a2, b2, c2, d2);
        assert!((a2 - c2).abs() < 1e-4 * c2 && (b2 - c2).abs() < 1e-4 * c2);
    }
    let d5 = (C * 55.0 * MS).powf(2.0) - R * R; // the tail series' first omitted terms, all of size a^4, at 55 ms
    let om = A.powf(4.0) * (3.0 / (80.0 * d5.powf(2.0)) + 3.0 * R * R / (16.0 * d5.powf(3.0)) + 21.0 * R.powf(4.0) / (128.0 * d5.powf(4.0)));
    let gap = t55 / u2_tail(55.0 * MS) - 1.0;
    println!("tail series at 55 ms: first omitted terms {} of the tail; Poisson above the series by {}", sci(om), sci(gap));
    assert!((gap - om).abs() < 0.1 * om); // the series misses by its first omitted terms
    println!("tail as a share of the peak: 3D 0 after {:.3} ms; 2D {:.4} at 100 ms, {:.4} at 1 s", (R + A) / C / MS, t100 / pk, t1000 / pk);
    let p3 = u3_closed(R, 50.0 * MS); // the charts from 49 ms to 53 ms, each as a percent of its own peak
    let pct = |v: Vec<f64>| v.iter().map(|x| format!("{:.1}", x)).collect::<Vec<_>>().join(", ");
    println!("chart 3D, % of peak: {}", pct((0..17).map(|j| 100.0 * u3_closed(R, (49.0 + 0.25 * j as f64) * MS) / p3).collect()));
    println!("chart 2D, % of peak: {}", pct((0..17).map(|j| 100.0 * u2_poisson((49.0 + 0.25 * j as f64) * MS, 400) / pk).collect()));
    println!("chart tail 2D: {}", join([60.0, 80.0, 100.0, 150.0, 200.0, 300.0, 500.0, 700.0, 1000.0].iter().map(|x| u2_tail(x * MS)).collect()));
    let (w1, w2, w3) = (u3_mean(R, 50.0 * MS) / (50.0 * MS), u2_circle(50.0 * MS), u2_circle(51.0 * MS));
    println!("no factor t, 3D at 50.00 ms: {:.4} Pa/s, not {:.4} Pa", w1, u3_closed(R, 50.0 * MS));
    println!("circle only, 2D: {:.6} Pa at 50.00 ms, {:.6} Pa at 51.00 ms; true {:.6} and {:.6} Pa", w2, w3, u2_poisson(50.0 * MS, 1000), u2_poisson(51.0 * MS, 1000));
    assert!(w3 == 0.0 && u2_poisson(51.0 * MS, 1000) > 0.25 * pk && (w1 * 50.0 * MS - u3_closed(R, 50.0 * MS)).abs() < 1e-9);
    println!("ALL CHECKS PASS");
}
