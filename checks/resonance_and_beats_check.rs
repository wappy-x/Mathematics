// Resonance and beats -- the same check as the Python, in Rust.  No crates.
// A footbridge deck, natural frequency 1 Hz, pushed from rest by F cos(wt)
// per kg, F = 0.1 m/s^2:  y'' + b y' + w0^2 y = F cos(wt).  Road one is the
// closed form; road two steps the equation with Euler's rule, which never
// uses a sine formula, and the error halves as the step halves.
use std::f64::consts::PI;
const F: f64 = 0.1;
const W0: f64 = 2.0 * PI;

fn euler(w: f64, b: f64, t_end: f64, h: f64, tail: f64) -> f64 { // new = old + step x rate
    let (mut y, mut v, mut t, mut top) = (0.0f64, 0.0f64, 0.0f64, 0.0f64);
    for _ in 0..(t_end / h).round() as usize {
        let a = F * (w * t).cos() - b * v - W0 * W0 * y;
        y += h * v;
        v += h * a;
        t += h;
        if t > t_end - tail { top = top.max(y.abs()) }
    }
    if tail > 0.0 { top } else { y }
}

fn beat(w: f64, t: f64) -> f64 { F * ((w * t).cos() - (W0 * t).cos()) / (W0 * W0 - w * w) }
fn res(t: f64) -> f64 { F * t * (W0 * t).sin() / (2.0 * W0) }
fn amp(f: f64, b: f64) -> f64 {
    let w = 2.0 * PI * f;
    F / ((W0 * W0 - w * w).powi(2) + (b * w).powi(2)).sqrt()
}
fn mm(x: f64) -> String { format!("{:.2}", 1000.0 * x) }
fn row(xs: Vec<String>) -> String { xs.join(" ") }

fn main() {
    let (w, b) = (2.0 * PI * 0.9, 2.0 * 0.01 * W0);          // damping ratio 1%
    let hs = [1e-4, 5e-5];
    let d = W0 * W0 - w * w;
    let eb: Vec<f64> = hs.iter().map(|&h| (euler(w, 0.0, 5.0, h, 0.0) - beat(w, 5.0)).abs()).collect();
    let er: Vec<f64> = hs.iter().map(|&h| (euler(W0, 0.0, 10.25, h, 0.0) - res(10.25)).abs()).collect();
    let pk: Vec<f64> = hs.iter().map(|&h| euler(W0, b, 150.0, h, 2.0)).collect();
    let ed: Vec<f64> = pk.iter().map(|p| (p - amp(1.0, b)).abs()).collect();
    let near = beat(W0 * (1.0 - 1e-6), 10.25);
    let prod = 2.0 * F / d * ((W0 - w) * 5.0 / 2.0).sin() * ((W0 + w) * 5.0 / 2.0).sin();
    let fs = ["0.8", "0.85", "0.9", "0.95", "0.98", "1.0", "1.02", "1.05", "1.1", "1.15", "1.2"];
    let ts: Vec<f64> = (0..11).map(|i| 2.0 * i as f64).collect();
    println!("w0 = {:.4} rad/s; w at 0.9 Hz = {:.4} rad/s; w0^2 - w^2 = {:.4} per s^2", W0, w, d);
    println!("0.9 Hz from rest: y(5) = {} mm; product form {} mm; y(10) = {} mm", mm(beat(w, 5.0)), mm(prod), mm(beat(w, 10.0)));
    println!("steady part alone peaks at {} mm; beats peak at 2F/(w0^2 - w^2) = {} mm", mm(F / d), mm(2.0 * F / d));
    println!("1 Hz from rest: envelope grows {} mm/s; y(10.25) = {} mm", mm(F / (2.0 * W0)), mm(res(10.25)));
    println!("beat formula at w = w0(1 - 1e-6), t = 10.25: {} mm", mm(near));
    println!("Euler errors, h = 1e-4, 5e-5: beats {:.4} {:.4} mm; resonance {} {} mm", eb[0] * 1000.0, eb[1] * 1000.0, mm(er[0]), mm(er[1]));
    println!("envelopes cross at 4 w0/(w0^2 - w^2) = {:.2} s", 4.0 * W0 / d);
    println!("t (s):                 {}", row(ts.iter().map(|t| format!("{}", t)).collect()));
    println!("resonance envelope mm: {}", row(ts.iter().map(|t| mm(F * t / (2.0 * W0))).collect()));
    println!("beat envelope mm:      {}", row(ts.iter().map(|t| mm(2.0 * F / d * ((W0 - w) * t / 2.0).sin().abs())).collect()));
    println!("damped: zeta = {:.2}, b = {:.4} per s; static F/w0^2 = {} mm; peak F/(b w0) = {} mm; ratio {:.1}", b / (2.0 * W0), b, mm(F / (W0 * W0)), mm(F / (b * W0)), (F / (b * W0)) / (F / (W0 * W0)));
    println!("damped peak by Euler to t = 150 s, h = 1e-4, 5e-5: {} {} mm; errors {} {} mm", mm(pk[0]), mm(pk[1]), mm(ed[0]), mm(ed[1]));
    println!("forcing f (Hz):   {}", fs.join(" "));
    println!("steady amp (mm):  {}", row(fs.iter().map(|f| mm(amp(f.parse().unwrap(), b))).collect()));
    println!("mistake, plain guess C cos(w0 t) at 1 Hz: coefficient w0^2 - w0^2 = {:.1}, so 0 x C = F", W0 * W0 - W0 * W0);
    println!("mistake, beat period read as 2/(f0 - f) = {:.0} s; loud peaks come every 1/(f0 - f) = {:.0} s", 2.0 / (1.0 - 0.9), 1.0 / (1.0 - 0.9));
    println!("mistake, damping ignored at 0.99 Hz: {} mm, true {} mm", mm(amp(0.99, 0.0)), mm(amp(0.99, b)));
    assert!(eb[1] < 1e-4 && eb[0] / eb[1] > 1.8 && eb[0] / eb[1] < 2.2);    // Euler meets the beat formula
    assert!(er[1] < 1e-3 && er[0] / er[1] > 1.8 && er[0] / er[1] < 2.2);    // Euler meets t sin t
    assert!((near - res(10.25)).abs() < 1e-6);                              // beats tend to resonance
    assert!(ed[1] < 3e-3 && ed[0] / ed[1] > 1.8 && ed[0] / ed[1] < 2.2);    // long run settles to F/(b w0)
    println!("ALL CHECKS PASS");
}
