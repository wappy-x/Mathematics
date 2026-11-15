// Duhamel's principle -- the check behind the card.  Rust std only.
// A 1 m copper rod, 1 cm^2 section, room temperature everywhere.  At t = 5 s a
// 10 W heater band at its middle (x = 0) switches on.  u = rise above room, K.
// Roads: the Duhamel integral by Simpson's rule; its closed form (erfc written
// out); an explicit grid with insulated ends; the residual u_t - kappa u_xx;
// the heat budget; the slope jump at the heater.  Then a string pushed at 5 s.
use std::f64::consts::PI;

const K: f64 = 1.11e-4; const RC: f64 = 3.45e6; const A: f64 = 1e-4; const P: f64 = 10.0; const T0: f64 = 5.0;
const Q: f64 = P / (RC * A); // source strength, K m/s

fn sci(v: f64) -> String { // e-notation with the same digits as Python
    let e = v.abs().log10().floor() as i32; let m = v / 10f64.powi(e);
    format!("{:.3}e{}{:02}", m, if e < 0 { '-' } else { '+' }, e.abs())
}

fn erfc(z: f64) -> f64 { // z >= 0: series near 0, continued fraction far out
    if z > 3.0 {
        let mut f = z;
        for k in (1..=60).rev() { f = z + (k as f64 / 2.0) / f; }
        return (-z * z).exp() / (PI.sqrt() * f);
    }
    let (mut term, mut s, mut n) = (z, z, 0);
    while term > 1e-17 * s { n += 1; term *= 2.0 * z * z / (2 * n + 1) as f64; s += term; }
    1.0 - 2.0 / PI.sqrt() * (-z * z).exp() * s
}

fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = 0.0;
    for i in 1..n { s += (if i % 2 == 1 { 4.0 } else { 2.0 }) * f(a + i as f64 * h); }
    h / 3.0 * (f(a) + f(b) + s)
}

fn kernel(x: f64, age: f64) -> f64 { (-x * x / (4.0 * K * age)).exp() / (4.0 * PI * K * age).sqrt() }

fn duhamel(x: f64, t: f64) -> f64 { // road 1: add up fresh starts, age a = w^2
    if t <= T0 { return 0.0; }
    let f = |w: f64| if w > 0.0 { Q * 2.0 * w * kernel(x, w * w) } else if x == 0.0 { Q / (PI * K).sqrt() } else { 0.0 };
    simpson(&f, 0.0, (t - T0).sqrt(), 400)
}

fn closed_from(x: f64, t: f64, start: f64) -> f64 { // road 2: the same integral done by hand
    if t <= start { return 0.0; }
    let tau = t - start; let z = x.abs() / (2.0 * (K * tau).sqrt());
    Q * ((tau / (PI * K)).sqrt() * (-z * z).exp() - x.abs() / (2.0 * K) * erfc(z))
}
fn closed(x: f64, t: f64) -> f64 { closed_from(x, t, T0) }

fn grid(dx: f64) -> (f64, f64) { // road 3: explicit grid, heater in the middle cell
    let (t1, half) = (65.0, 0.5);
    let n = (2.0 * half / dx).round() as usize; let m = n / 2;
    let steps = ((t1 - T0) * 4.0 * K / (dx * dx)).ceil(); let dt = (t1 - T0) / steps; let r = K * dt / (dx * dx);
    let mut u = vec![0.0; n + 1];
    for _ in 0..steps as usize {
        let mut v = vec![0.0; n + 1];
        for i in 0..=n {
            let l = if i > 0 { u[i - 1] } else { u[1] }; let rr = if i < n { u[i + 1] } else { u[n - 1] };
            v[i] = u[i] + r * (l - 2.0 * u[i] + rr);
        }
        v[m] += Q * dt / dx; u = v;
    }
    (u[m], u[m + (0.02 / dx).round() as usize])
}

fn join(v: &[f64]) -> String { v.iter().map(|x| format!("{:.2}", x)).collect::<Vec<_>>().join(", ") }

fn main() {
    println!("source strength Q = P/(rho c A) = {:.7} K m/s", Q);
    let band: Vec<f64> = (0..14).map(|i| closed(0.0, 5.0 * i as f64)).collect();
    println!("chart, heater band, t = 0..65 s by 5 s: {}", join(&band));
    for t in [15.0, 35.0, 65.0] {
        let pr: Vec<f64> = (-5..=5).map(|i| closed(0.02 * i as f64, t)).collect();
        println!("chart, profile at t = {:.0} s, x = -10..10 cm by 2 cm: {}", t, join(&pr));
    }
    println!("before switch-on, t = 4 s, x = 0: {:.6} K, {:.6} K", duhamel(0.0, 4.0), closed(0.0, 4.0));
    println!("t s | x m | Duhamel integral K | closed form K");
    for t in [15.0, 35.0, 65.0] {
        for x in [0.0, 0.02, 0.05] {
            let (d, c) = (duhamel(x, t), closed(x, t));
            assert!((d - c).abs() < 1e-9);
            println!("{:4.0} | {:.2} | {:.6} | {:.6}", t, x, d, c);
        }
    }
    let (u10, u40) = (closed(0.0, 15.0), closed(0.0, 45.0));
    assert!((u40 / u10 - 2.0).abs() < 1e-12); // square-root law
    println!("heater band after 10 s and 40 s: {:.4} K, {:.4} K; ratio {:.4}", u10, u40, u40 / u10);

    println!("grid at t = 65 s | dx cm | u(0) K | u(2 cm) K | error at 0");
    let mut errs = vec![];
    for dx in [0.02, 0.01, 0.005] {
        let (g0, g2) = grid(dx); let e = (g0 - closed(0.0, 65.0)).abs(); errs.push(e);
        println!("grid | {:.1} | {:.5} | {:.5} | {}", dx * 100.0, g0, g2, sci(e));
    }
    let orders: Vec<f64> = (0..2).map(|i| (errs[i] / errs[i + 1]).log2()).collect();
    assert!(errs[2] < 0.01 && orders.iter().all(|&p| 1.7 < p && p < 2.3));
    println!("observed order: {:.2}, {:.2}", orders[0], orders[1]);
    println!("first omitted term, the two end images at x = 0, t = 65 s: {} K", sci(2.0 * closed(1.0, 65.0)));

    for h in [1e-3, 5e-4] { // road 4: residual at x = 2 cm, t = 15 s
        let (x, t) = (0.02, 15.0);
        let ut = (closed(x, t + h * 10.0) - closed(x, t - h * 10.0)) / (20.0 * h);
        let uxx = (closed(x + h, t) - 2.0 * closed(x, t) + closed(x - h, t)) / (h * h);
        assert!((ut - K * uxx).abs() < 1e-4 * ut.abs());
        println!("residual, step {:.1} mm: u_t = {:.6} K/s, kappa u_xx = {:.6} K/s", h * 1000.0, ut, K * uxx);
    }

    let u65 = |x: f64| closed(x, 65.0); // u is even in x
    let heat = 2.0 * RC * A * simpson(&u65, 0.0, 1.0, 800);
    let past = 2.0 * RC * A * simpson(&u65, 0.5, 1.0, 800);
    assert!((heat - P * 60.0).abs() < 1e-8 * P * 60.0); // road 5: the heat budget
    println!("heat on the line at 65 s: {:.4} J; heater gave {:.1} J; past the rod ends {} J", heat, P * 60.0, sci(past));
    for tau in [10.0, 60.0] { // road 6: slope jump carries the power
        let s = (closed(1e-6, T0 + tau) - closed(0.0, T0 + tau)) / 1e-6;
        assert!((s + Q / (2.0 * K)).abs() < 1e-3 * Q / (2.0 * K));
        println!("slope beside the heater, t_on = {:.0} s: {:.3} K/m (exact -Q/(2 kappa) = {:.3}); flow out both sides {:.4} W",
                 tau, s, -Q / (2.0 * K), -2.0 * K * RC * A * s);
    }
    println!("air cooling, illustrative 10 W/(m^2 K) on a 4 cm rim: {:.2} J of 600 J, {:.2} %",
             10.0 * 0.04 * Q * 1800.0, 10.0 * 0.04 * Q * 1800.0 / 6.0);
    println!("conductivity these values imply, kappa rho c = {:.1} W/(m K), {:.1} % below 401 W/(m K)", K * RC, 100.0 * (1.0 - K * RC / 401.0));

    let z = 0.02 / (2.0 * (K * 10.0).sqrt()); // by hand at t = 15 s
    println!("by hand: rho c A = {:.1} J/(K m); sqrt(10/(pi kappa)) = {:.3} s/m; at 2 cm: z = {:.5}, e^(-z^2) = {:.5}, erfc(z) = {:.5}, x/(2 kappa) = {:.3} s/m",
             RC * A, (10.0 / (PI * K)).sqrt(), z, (-z * z).exp(), erfc(z), 0.02 / (2.0 * K));
    let (t1, t2) = ((10.0 / (PI * K)).sqrt() * (-z * z).exp(), 0.02 / (2.0 * K) * erfc(z));
    println!("by hand at 2 cm: {:.3} - {:.3} = {:.3} s/m; times Q: {:.4} K", t1, t2, t1 - t2, Q * (t1 - t2));
    println!("what breaks, at x = 0, t = 15 s:");
    println!("  stream started at 0 s, not 5 s: {:.4} K, not {:.4}", closed_from(0.0, 15.0, 0.0), u10);
    let wrong = simpson(&|_s: f64| Q * kernel(0.0, 15.0), T0, 15.0, 10);
    println!("  kernel fed the clock t, not the age t - tau: {:.4} K", wrong);
    println!("  power not divided by rho c A: {:.1} K", P / Q * u10);

    let (f, ts, mu): (f64, f64, f64) = (0.2, 100.0, 0.01); // the wave: string, N, N, kg/m
    let c = (ts / mu).sqrt();
    let tent = |x: f64, t: f64| f / (2.0 * mu * c) * ((t - T0) - x.abs() / c).max(0.0);
    let kicks = |x: f64, t: f64, n: usize| { // each kick: d'Alembert box of height F/(2 mu c)
        let ds = (t - T0) / n as f64; let mut s = 0.0;
        for k in 0..n { if x.abs() < c * (t - T0 - (k as f64 + 0.5) * ds) { s += f / (2.0 * mu * c) * ds; } }
        s
    };
    println!("string: c = {:.1} m/s; centre speed F/(2 mu c) = {:.4} m/s", c, f / (2.0 * mu * c));
    for x in [0.0, 0.1, 0.3] {
        let (a, b) = (tent(x, 5.004), kicks(x, 5.004, 4000));
        assert!((a - b).abs() < 1e-3 * a + 1e-9);
        println!("string at t = 5.004 s, x = {:.1} m: tent {:.4} mm, sum of 4000 kicks {:.4} mm", x, a * 1000.0, b * 1000.0);
    }
    let mom = mu * simpson(&|x: f64| (tent(x, 5.0041) - tent(x, 5.0039)) / 2e-4, -0.5, 0.5, 2000);
    assert!((mom - f * 0.004).abs() < 1e-3 * f * 0.004);
    println!("string momentum at 5.004 s: {:.4} g m/s; impulse F (t - 5) = {:.4} g m/s", mom * 1000.0, f * 4.0);
    let off = closed(0.0, 125.0) - closed_from(0.0, 125.0, 65.0); // try changing
    println!("try: heater off at 65 s, x = 0 at 125 s: {:.4} K; tension 200 N: centre speed {:.4} m/s", off, f / (2.0 * (200.0 * mu).sqrt()));
    println!("ALL CHECKS PASS");
}
