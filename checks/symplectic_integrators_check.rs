// Symplectic steps -- the same check as the Python, in Rust, std only.
// A frictionless clock pendulum, omega = pi rad/s, released at 20 degrees, run for a million swings.
// Roads: the exact swing time by the AGM; Verlet and RK4 at several steps; the modified energy;
// one step's area factor by finite differences against 1 - z^6/72 + z^8/576; the clock's lead.
use std::f64::consts::PI;
const W2: f64 = PI * PI;
const G: f64 = 9.81;
type Step = fn(f64, f64, f64) -> (f64, f64);

fn energy(th: f64, p: f64) -> f64 { p * p / 2.0 + W2 * (1.0 - th.cos()) }
fn e2(th: f64, p: f64) -> f64 { let s = th.sin(); p * p * W2 * th.cos() / 12.0 - W2 * W2 * s * s / 24.0 }
fn amp(e: f64) -> f64 { (1.0 - e / W2).acos() * 180.0 / PI }
fn verlet(th: f64, p: f64, h: f64) -> (f64, f64) {
    let p = p - h / 2.0 * W2 * th.sin();
    let th = th + h * p;
    (th, p - h / 2.0 * W2 * th.sin())
}
fn rk4(th: f64, p: f64, h: f64) -> (f64, f64) {
    let hh = h / 2.0;
    let k1 = -W2 * th.sin();
    let k2 = -W2 * (th + hh * p).sin();
    let k3 = -W2 * (th + hh * (p + hh * k1)).sin();
    let k4 = -W2 * (th + h * (p + hh * k2)).sin();
    (th + h * (p + h / 6.0 * (k1 + k2 + k3)), p + h / 6.0 * (k1 + 2.0 * k2 + 2.0 * k3 + k4))
}
fn sci(x: f64, d: usize) -> String {                   // Python-style exponent: e-07, e+00
    let s = format!("{:.*e}", d, x);
    let (m, e) = s.split_once('e').unwrap();
    let k: i32 = e.parse().unwrap();
    format!("{}e{}{:02}", m, if k < 0 { '-' } else { '+' }, k.abs())
}
fn run_verlet(ts: f64, s: usize, swings: usize) -> (f64, f64, f64, f64, usize, Vec<f64>) {
    let (h, th0) = (ts / s as f64, 20.0 * PI / 180.0);
    let hh = h / 2.0;
    let (mut th, mut p) = (th0, 0.0f64);
    let mut f = -W2 * th.sin();
    let e0 = energy(th, p);
    let m0 = e0 + h * h * e2(th, p);
    let (mut lo, mut hi, mut mlo, mut mhi, mut cross) = (0.0f64, 0.0f64, 0.0f64, 0.0f64, 0usize);
    let mut pts = vec![amp(e0)];
    for n in 1..=s * swings {
        let old = th;
        p += hh * f; th += h * p; f = -W2 * th.sin(); p += hh * f;
        let c = th.cos();
        let e = p * p / 2.0 + W2 * (1.0 - c);
        let m = e + h * h * (p * p * W2 * c / 12.0 - f * f / 24.0);
        lo = lo.min(e - e0); hi = hi.max(e - e0); mlo = mlo.min(m - m0); mhi = mhi.max(m - m0);
        if (old > 0.0) != (th > 0.0) { cross += 1 }
        if n % (s * 100000) == 0 { pts.push(amp(e)) }
    }
    ((hi - lo) / e0, (mhi - mlo) / e0, lo / e0, hi / e0, cross, pts)
}
fn run_rk4(ts: f64, s: usize, swings: usize) -> (Vec<f64>, usize, Vec<f64>) {
    let h = ts / s as f64;
    let (mut th, mut p, mut cross) = (20.0 * PI / 180.0, 0.0f64, 0usize);
    let e0 = energy(th, p);
    let (mut pts, mut es) = (vec![amp(e0)], vec![e0]);
    for n in 1..=s * swings {
        let old = th;
        (th, p) = rk4(th, p, h);
        if (old > 0.0) != (th > 0.0) { cross += 1 }
        if n % (s * 100000) == 0 { es.push(energy(th, p)); pts.push(amp(*es.last().unwrap())) }
    }
    (es, cross, pts)
}
fn area_factor(step: Step, th: f64, p: f64, h: f64) -> f64 {   // one step's Jacobian determinant
    let d = 1e-5;
    let (a1, a2, b1, b2) = (step(th + d, p, h), step(th - d, p, h), step(th, p + d, h), step(th, p - d, h));
    ((a1.0 - a2.0) * (b1.1 - b2.1) - (b1.0 - b2.0) * (a1.1 - a2.1)) / (4.0 * d * d)
}
fn join(v: &[f64]) -> String { v.iter().map(|x| format!("{:.2}", x)).collect::<Vec<_>>().join(", ") }

fn main() {
    let th0 = 20.0 * PI / 180.0;
    let (mut a, mut b) = (1.0f64, (th0 / 2.0).cos());
    for _ in 0..6 { (a, b) = ((a + b) / 2.0, (a * b).sqrt()) }
    let ts = 1.0 / a;
    let (h, e0) = (ts / 20.0, energy(th0, 0.0));
    let z = PI * h;
    println!("pendulum: g = {} m/s^2, L = g/omega^2 = {:.4} m, release 20 deg; exact swing time {:.9} s", G, G / W2, ts);
    println!("a million swings = {:.2} days; energy at release E0 = {:.6} per m L^2 (1/s^2)", 1e6 * ts / 86400.0, e0);
    println!("20 steps a swing: h = {:.7} s, z = omega h = {:.6}", h, z);
    let mut errs = vec![];
    for s in [10usize, 20, 40] {
        let mut out = vec![];
        for step in [verlet as Step, rk4] {
            let (mut th, mut p) = (th0, 0.0);
            for _ in 0..s { (th, p) = step(th, p, ts / s as f64) }
            out.push(((th + th0).powi(2) + (p / PI).powi(2)).sqrt());
        }
        println!("one swing, {} steps: Verlet error {} rad, RK4 error {} rad", s, sci(out[0], 3), sci(out[1], 3));
        errs.push(out);
    }
    let (rv, rr) = (errs[0][0] / errs[1][0], errs[1][0] / errs[2][0]);
    let (qv, qr) = (errs[0][1] / errs[1][1], errs[1][1] / errs[2][1]);
    println!("error ratio per halving: Verlet {:.2}, {:.2} (order 2); RK4 {:.2}, {:.2} (order 4)", rv, rr, qv, qr);
    println!("one swing, 20 steps: Verlet error / RK4 error = {:.0}", errs[1][0] / errs[1][1]);
    let pb = (2.0 * e0).sqrt();
    for (name, step) in [("Verlet", verlet as Step), ("RK4", rk4)] {
        println!("area factor - 1, one step: {} at release {}, at the bottom {}, small swing {}", name,
                 sci(area_factor(step, th0, 0.0, h) - 1.0, 2), sci(area_factor(step, 0.0, pb, h) - 1.0, 2),
                 sci(area_factor(step, 0.01, 0.0, h) - 1.0, 2));
    }
    let lin = 1.0 - z.powf(6.0) / 72.0 + z.powf(8.0) / 576.0;
    println!("RK4 small-swing formula 1 - z^6/72 + z^8/576 - 1 = {}; per 100k swings (2000000 steps) {:.4}", sci(lin - 1.0, 4), lin.powf(2000000.0));
    let (band, mband, vlo, vhi, vcross, vpts) = run_verlet(ts, 20, 1000000);
    let (es, rcross, rpts) = run_rk4(ts, 20, 1000000);
    let pred = h * h * (e2(0.0, pb) - e2(th0, 0.0)) / e0;
    println!("Verlet, 1e6 swings: energy {:.3}% to {:.3}% of E0; band {:.3}%, predicted {:.3}%",
             100.0 * (1.0 + vlo), 100.0 * (1.0 + vhi), 100.0 * band, 100.0 * pred);
    println!("Verlet, 1e6 swings: modified energy E + h^2 E2 moves by {:.5}% of E0; ratio {:.0}", 100.0 * mband, band / mband);
    let (el, ep) = (es[es.len() - 1], es[es.len() - 2]);
    println!("RK4, 1e6 swings: energy left {:.3}%, reach {:.2} deg; last 100k swings x{:.4}", 100.0 * el / e0, rpts[rpts.len() - 1], el / ep);
    println!("chart, reach in degrees every 100k swings, Verlet: {}", join(&vpts));
    println!("chart, reach in degrees every 100k swings, RK4: {}", join(&rpts));
    let lead = 1e6 * (2.0 * (PI / 40.0).asin() / (PI / 20.0) - 1.0);
    println!("clock: Verlet counts {} swings, ahead by {}; estimate {:.0}; RK4 counts {}", vcross, vcross - 1000000, lead, rcross);
    println!("cost for 1e6 swings (20000000 steps): Verlet {} sines, RK4 {} sines", 20 * 1000000 + 1, 4 * 20 * 1000000);   // 1 a step + 1; 4 a step
    let mut bands = vec![(0.0, 0.0); 2];
    for (i, s) in [10usize, 40].iter().enumerate() {
        let (bb, mb, _, _, _, _) = run_verlet(ts, *s, 100000);
        bands[i] = (bb, mb);
        println!("Verlet, {} steps a swing, 1e5 swings: energy band {:.4}%, modified-energy band {}%", s, 100.0 * bb, sci(100.0 * mb, 3));
    }
    println!("band ratios per halving: energy {:.2}, {:.2}; modified {:.1}, {:.1}",
             bands[0].0 / band, band / bands[1].0, bands[0].1 / mband, mband / bands[1].1);
    let (es40, _, _) = run_rk4(ts, 40, 100000);
    println!("RK4, 40 steps a swing, 1e5 swings: energy lost {:.3}%; at 20 steps {:.2}%", 100.0 * (1.0 - es40[1] / e0), 100.0 * (1.0 - es[1] / e0));
    let (mut th, mut p, mut t) = (th0, 0.0f64, 0.0f64);            // what breaks: a step that depends on the state
    for _ in 0..2000000 {
        let hs = h * (1.0 + 0.2 * th.abs());
        (th, p) = verlet(th, p, hs); t += hs;
    }
    println!("Verlet with step h(1 + 0.2|theta|): after {:.0} swings energy {:.2}% of E0", t / ts, 100.0 * energy(th, p) / e0);
    let (mut th, mut p, mut lo, mut hi) = (th0, 0.0f64, e0, e0);
    for _ in 0..2000000 {
        p -= h * W2 * th.sin(); th += h * p;
        let e = energy(th, p); lo = lo.min(e); hi = hi.max(e);
    }
    println!("symplectic Euler (one kick, one drift), 1e5 swings: energy {:.2}% to {:.2}% of E0", 100.0 * lo / e0, 100.0 * hi / e0);
    let (mut th, mut p, mut n) = (th0, 0.0f64, 0usize);
    while energy(th, p) <= 2.0 * W2 { (th, p, n) = (th + h * p, p - h * W2 * th.sin(), n + 1) }
    println!("forward Euler: over the top after {} steps, swing {:.1}", n, n as f64 / 20.0);
    assert!(3.9 < rv && rv < 4.1 && 3.9 < rr && rr < 4.1 && 15.0 < qv && qv < 17.0 && 15.0 < qr && qr < 17.0);
    assert!((area_factor(verlet, th0, 0.0, h) - 1.0).abs() < 1e-9);                 // Verlet keeps area
    assert!(((area_factor(rk4, 0.01, 0.0, h) - 1.0) / (lin - 1.0) - 1.0).abs() < 0.01); // RK4 shrinks it so
    assert!(((el / ep) / lin.powf(2000000.0) - 1.0).abs() < 0.01);                  // the drift is that shrinkage
    assert!((band / pred - 1.0).abs() < 0.01 && band / mband > 100.0 && 3.8 < band / bands[1].0 && band / bands[1].0 < 4.2);
    assert!(14.0 < mband / bands[1].1 && mband / bands[1].1 < 18.0 && ((vcross as f64 - 1e6) / lead - 1.0).abs() < 0.01);
    assert!(el / e0 < 0.05 && vpts[vpts.len() - 1] > 19.9);                          // RK4 runs down, Verlet does not
    println!("ALL CHECKS PASS");
}
