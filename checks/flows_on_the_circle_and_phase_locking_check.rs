// Phase locking -- the same check as the Python, in Rust.  No crates.  Two fireflies, free
// rhythms 6.0 and 6.5 rad/s, nudge each other with strength K/2, so phi' = 0.5 - K sin phi.
// Three roads: the formula, phi' summed round the circle, both fireflies stepped by RK4.
use std::f64::consts::PI;
const W1: f64 = 6.0; const W2: f64 = 6.5; const W: f64 = W2 - W1;   // free rhythms, rad/s
const DT: f64 = 0.001; const TAU: f64 = 2.0 * PI;
fn rate(a: f64, b: f64, k: f64) -> (f64, f64) {       // each firefly nudged toward the other
    (W1 + k / 2.0 * (b - a).sin(), W2 + k / 2.0 * (a - b).sin())
}
struct Run { gaps: Vec<f64>, slip: Option<f64>, mean_a: f64, end: (f64, f64) }
fn run(k: f64, t_end: f64) -> Run {                   // road 3: step both phases by RK4
    let (mut a, mut b, mut gaps, mut slip, mut a_slip) = (0.0f64, 0.0f64, vec![0.0], None, 0.0);
    for n in 1..=((t_end / DT).round() as usize) {
        let k1 = rate(a, b, k);
        let k2 = rate(a + DT / 2.0 * k1.0, b + DT / 2.0 * k1.1, k);
        let k3 = rate(a + DT / 2.0 * k2.0, b + DT / 2.0 * k2.1, k);
        let k4 = rate(a + DT * k3.0, b + DT * k3.1, k);
        let (a0, g0) = (a, b - a);
        a += DT / 6.0 * (k1.0 + 2.0 * k2.0 + 2.0 * k3.0 + k4.0);
        b += DT / 6.0 * (k1.1 + 2.0 * k2.1 + 2.0 * k3.1 + k4.1);
        if slip.is_none() && b - a >= TAU {           // first full lap, interpolated
            let f = (TAU - g0) / (b - a - g0);
            slip = Some(((n - 1) as f64 + f) * DT);
            a_slip = a0 + f * (a - a0);
        }
        if n % 2000 == 0 { gaps.push((b - a).to_degrees()); }
    }
    Run { gaps, slip, mean_a: slip.map_or(0.0, |s| a_slip / s), end: rate(a, b, k) }
}
fn summed(k: f64, lo: f64, hi: f64) -> f64 {          // road 2: add up dphi / phi'
    let (n, h) = (20000, (hi - lo) / 20000.0);
    (0..n).map(|i| h / (W - k * (lo + (i as f64 + 0.5) * h).sin())).sum()
}
fn formula(k: f64) -> f64 { TAU / (W * W - k * k).sqrt() }   // road 1: the slip period
fn exact(k: f64, p: f64) -> f64 { let r = (W * W - k * k).sqrt(); 2.0 * ((W * (p / 2.0).tan() - k) / r).atan() / r }
fn row(xs: &[f64], d: usize) -> String {
    xs.iter().map(|x| format!("{:.*}", d, x)).collect::<Vec<_>>().join(", ")
}
fn main() {
    let lock = run(1.0, 42.0); let (ra, rb) = lock.end;
    let (lag, last) = ((W / 1.0).asin().to_degrees(), lock.gaps[lock.gaps.len() - 1]);
    println!("K = 1: lag arcsin(0.5) = {:.3} deg, simulated {:.3} deg; other rest {:.3} deg", lag, last, 180.0 - lag);
    println!("K = 1: pull-back rate K cos(lag) = {:.3} per s; both run at {:.3} and {:.3} rad/s; B leads by {:.4} s",
             W / lag.to_radians().tan(), ra, rb, lag.to_radians() / rb);
    let mut slips = Vec::new();
    for k in [0.4, 0.49] {
        let r = run(k, 70.0);
        let s = r.slip.unwrap();
        println!("K = {}: slip every {:.3} s (formula), {:.3} s (summed), {:.3} s (two fireflies)",
                 k, formula(k), summed(k, 0.0, TAU), s);
        println!("K = {}: share of each slip spent between 60 and 120 deg {:.3}",
                 k, summed(k, TAU / 6.0, TAU / 3.0) / formula(k));
        slips.push((k, r));
    }
    println!("K = 0.49: edge estimate 2 pi/sqrt(2 w (w - K)) = {:.3} s", TAU / (2.0 * W * (W - 0.49)).sqrt());
    let (s4, ma) = (slips[0].1.slip.unwrap(), slips[0].1.mean_a);
    println!("K = 0.4: A averages {:.3} rad/s, B {:.3}, beat {:.3} rad/s", ma, ma + TAU / s4, TAU / s4);
    println!("worked: w^2 - K^2 = {:.4} and {:.4}, roots {:.4} and {:.4}; even share {:.3}", W * W - 0.16,
             W * W - 0.49f64.powi(2), (W * W - 0.16).sqrt(), (W * W - 0.49f64.powi(2)).sqrt(), 1.0 / 6.0);
    println!("flash every {:.3} s (A alone), {:.3} s (B alone), {:.3} s (locked)", TAU / W1, TAU / W2, TAU / ra);
    let edge = run(0.51, 200.0);
    let elast = edge.gaps[edge.gaps.len() - 1];
    println!("K = 0.51: locks at {:.3} deg (arcsin {:.3})", elast, (W / 0.51).asin().to_degrees());
    println!("chart, gap every 2 s, K = 1: {}", row(&lock.gaps[..22], 1));
    println!("chart, gap every 2 s, K = 0.4: {}", row(&slips[0].1.gaps[..22], 1));
    let periods: Vec<f64> = (0..13).map(|i| formula(0.04 * i as f64)).collect();
    println!("chart, slip period at K = 0, 0.04 .. 0.48: {}", row(&periods, 2));
    let bars: Vec<f64> = (0..12).map(|i| W - 0.4 * ((30 * i) as f64).to_radians().sin()).collect();
    println!("bars, phi' at 0, 30 .. 330 deg, K = 0.4: {}", row(&bars, 3));
    println!("mistakes: lag 0.5 rad = {:.3} deg; 2 pi/w = {:.3} s; 2 pi/(w - K) at K = 0.4: {:.3} s",
             W.to_degrees(), TAU / W, TAU / (W - 0.4));
    for (k, r) in &slips {                                   // three roads agree
        assert!((formula(*k) - summed(*k, 0.0, TAU)).abs() < 1e-6 && (formula(*k) - r.slip.unwrap()).abs() < 1e-6);
    }
    assert!((last - lag).abs() < 1e-6 && (ra - (W1 + W2) / 2.0).abs() < 1e-6 && (rb - ra).abs() < 1e-6);
    assert!((elast - (W / 0.51).asin().to_degrees()).abs() < 1e-3 && edge.slip.is_none());
    assert!((ma - (W1 + 0.2 * (W - TAU / formula(0.4)) / 0.4)).abs() < 1e-3);   // mean of sin phi
    for (k, _) in &slips { assert!((summed(*k, TAU / 6.0, TAU / 3.0) - exact(*k, TAU / 3.0) + exact(*k, TAU / 6.0)).abs() < 1e-6); }
    println!("ALL CHECKS PASS");
}
