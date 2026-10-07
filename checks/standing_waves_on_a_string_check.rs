// Standing waves on a string -- the same check as the Python, in Rust.  No crates.
// A 1 m string, c = 1 m/s, ends fixed, pulled 1 cm aside at the middle, let go.
// Roads: the sine series (amplitudes by Simpson's rule and by formula), d'Alembert's
// two travelling halves, a grid stepped in time.  Energy: by mode and from the shape.
use std::f64::consts::PI;
const L: f64 = 1.0; const C: f64 = 1.0;
fn clean(v: f64) -> f64 { (v * 1e9).round() / 1e9 + 0.0 }   // prints -0.000000 as 0.000000
fn pluck(x: f64, a: f64) -> f64 { if x <= a { x / a } else { (L - x) / (L - a) } }
fn b_simpson(n: f64, a: f64) -> f64 {                       // (2/L) * integral of pluck * sine
    let m = 2000;
    let f = |x: f64| pluck(x, a) * (n * PI * x / L).sin();
    let mut s = f(0.0) + f(L);
    for k in 1..m { s += (if k % 2 == 1 { 4.0 } else { 2.0 }) * f(k as f64 * L / m as f64) }
    2.0 / L * s * (L / m as f64) / 3.0
}
fn b(n: f64) -> f64 { 8.0 / (n * n * PI * PI) * (n * PI / 2.0).sin() }
fn series(x: f64, t: f64, big_n: usize) -> f64 {
    (1..=big_n).map(|k| { let n = k as f64; b(n) * (n * PI * x / L).sin() * (n * PI * C * t / L).cos() }).sum()
}
fn ext(y: f64) -> f64 {                                     // the pluck reflected odd, period 2L
    let y = y.rem_euclid(2.0 * L);
    if y <= L { pluck(y, 0.5) } else { -pluck(2.0 * L - y, 0.5) }
}
fn dal(x: f64, t: f64) -> f64 { 0.5 * (ext(x - C * t) + ext(x + C * t)) }
fn grid(m: usize, t_end: f64, r: f64) -> f64 {              // leapfrog, m intervals, c*dt/dx = r
    let mut u0: Vec<f64> = (0..=m).map(|i| pluck(i as f64 / m as f64, 0.5)).collect();
    let mut u1 = vec![0.0; m + 1];
    for i in 1..m { u1[i] = u0[i] + r * r / 2.0 * (u0[i + 1] - 2.0 * u0[i] + u0[i - 1]) }
    for _ in 0..((t_end * C * m as f64 / r).round() as usize - 1) {
        let mut u2 = vec![0.0; m + 1];
        for i in 1..m { u2[i] = 2.0 * u1[i] - u0[i] + r * r * (u1[i + 1] - 2.0 * u1[i] + u1[i - 1]) }
        u0 = u1;
        u1 = u2;
    }
    (0..=m).map(|i| (u1[i] - dal(i as f64 / m as f64, t_end)).abs()).fold(0.0, f64::max)
}
fn shape_energy(t: f64) -> (f64, f64) {                     // (1/2) integral of u_t^2, and of c^2 u_x^2
    let (m, h) = (1000, 1e-7);
    let (mut kin, mut pot) = (0.0, 0.0);
    for k in 0..m {
        let x = (k as f64 + 0.5) / m as f64;
        kin += ((dal(x, t + h) - dal(x, t - h)) / (2.0 * h)).powi(2);
        pot += C * C * ((dal(x + h, t) - dal(x - h, t)) / (2.0 * h)).powi(2);
    }
    (kin / (2.0 * m as f64), pot / (2.0 * m as f64))
}
fn mode_e(n: f64, k: f64) -> f64 { L / 4.0 * (k * PI * C / L).powi(2) * b(n).powi(2) }   // k = n is right
fn main() {
    println!("string 1 m, c = 1 m/s, plucked 1 cm at the middle; harmonic 1 repeats every 2 s");
    for k in 1..=6 {
        let n = k as f64;
        println!("harmonic {}: b by Simpson {:+.6} cm, by formula {:+.6} cm, {:.1} Hz, energy share {:.2}%",
                 k, clean(b_simpson(n, 0.5)), clean(b(n)), n * C / (2.0 * L), 100.0 * mode_e(n, n) / 2.0);
    }
    println!("middle at t = 0.25 s: d'Alembert {:.6}, series to n = 21 {:.6}, to n = 201 {:.6}",
             dal(0.5, 0.25), series(0.5, 0.25, 21), series(0.5, 0.25, 201));
    let errs: Vec<f64> = [40, 80, 160].iter().map(|&m| grid(m, 0.25, 0.5)).collect();
    println!("grid, c*dt/dx = 0.5, worst error at t = 0.25 s: 40 intervals {:.4}, 80 {:.4}, 160 {:.4} cm", errs[0], errs[1], errs[2]);
    for (t, lab) in [(0.0, "0"), (0.25, "0.25"), (0.5, "0.5")] {
        let (k, p) = shape_energy(t);
        println!("energy from the shape at t = {} s: motion {:.6} + stretch {:.6} = {:.6}", lab, k, p, k + p);
    }
    let modes: Vec<f64> = [201, 2001].iter().map(|&nn| (1..=nn).map(|k| mode_e(k as f64, k as f64)).sum()).collect();
    println!("energy summed over modes: to n = 201 {:.6}, to n = 2001 {:.6}", modes[0], modes[1]);
    println!("figure, t = 0 peak (180.0, {:.1}); t = 0.25 s shoulders ({:.1}, {:.1}) ({:.1}, {:.1}); t = 0.5 s flat at {:.1}",
             190.0 - 130.0 * dal(0.5, 0.0), 40.0 + 280.0 * 0.25, 190.0 - 130.0 * dal(0.25, 0.25),
             40.0 + 280.0 * 0.75, 190.0 - 130.0 * dal(0.75, 0.25), 190.0 - 130.0 * dal(0.5, 0.5));
    let w = |x: f64, t: f64| (C * t - x).max(0.0).powi(3);  // a wave arriving from x < 0
    println!("mistake, ends not held: u = (t - x)^3 for t > x starts at rest, middle at t = 1 s {:.6} cm", w(0.5, 1.0));
    let wrong: f64 = (1..=2001).map(|k| mode_e(k as f64, 1.0)).sum();
    println!("mistake, energy as sum of b_n^2 without n^2: {:.6}", wrong);
    println!("mistake, pluck at a quarter still hollow: b_2 by Simpson {:.6} cm, not 0", b_simpson(2.0, 0.25));
    println!("mistake, series cut after harmonic 1: middle at t = 0 {:.6} cm, not 1", series(0.5, 0.0, 1));
    assert!((1..=6).all(|k| (b_simpson(k as f64, 0.5) - b(k as f64)).abs() < 1e-6));   // integral vs formula
    assert!((series(0.5, 0.25, 201) - dal(0.5, 0.25)).abs() < 1e-4 && errs[2] < errs[0] / 2.0);
    let (k, p) = shape_energy(0.25);
    assert!((modes[1] - (k + p)).abs() < 1e-3);                                          // modes vs shape
    assert!((b_simpson(2.0, 0.25) - 32.0 / (12.0 * PI * PI)).abs() < 1e-6);            // quarter pluck, b_2
    println!("ALL CHECKS PASS");
}
