// The Fourier transform on L1 and Riemann-Lebesgue -- the same check as the Python, in Rust.
// No crates.  Convention: fhat(xi) = integral of f(t) e^(-2 pi i xi t) dt, t in seconds,
// xi in hertz, so fhat is in seconds; it is printed in milliseconds.  A complex number is
// a pair (real part, imaginary part).  The shutter is open (f = 1) for one millisecond.
use std::f64::consts::PI;

const T: f64 = 0.001; // shutter open time, seconds

fn ms(x: f64) -> f64 { // seconds to milliseconds, tiny values zeroed
    let v = 1000.0 * x;
    if v.abs() < 5e-10 { 0.0 } else { v }
}

fn gate_hat(xi: f64, a: f64, b: f64) -> (f64, f64) { // transform of 1 on [a, b), closed form
    if xi == 0.0 { return (b - a, 0.0) }
    let w = 2.0 * PI * xi; // (e^(-iwa) - e^(-iwb)) / (iw)
    (((w * b).sin() - (w * a).sin()) / w, ((w * b).cos() - (w * a).cos()) / w)
}

fn by_integral(f: &dyn Fn(f64) -> f64, a: f64, b: f64, xi: f64, n: usize) -> (f64, f64) {
    let (h, mut re, mut im) = ((b - a) / n as f64, 0.0, 0.0); // midpoint rule, n cells
    for k in 0..n {
        let t = a + (k as f64 + 0.5) * h;
        re += f(t) * (2.0 * PI * xi * t).cos() * h;
        im -= f(t) * (2.0 * PI * xi * t).sin() * h;
    }
    (re, im)
}

fn size(z: (f64, f64)) -> f64 { (z.0.powi(2) + z.1.powi(2)).sqrt() }

fn leaf(t: f64) -> f64 { 0.0f64.max(1.0f64.min((T / 2.0 - t.abs()) / 0.0002)) }

fn leaf_hat(xi: f64) -> f64 { // gate of 0.8 ms smoothed by a 0.2 ms ramp
    if xi == 0.0 { return T * 0.8 }
    (PI * xi * 0.0008).sin() / (PI * xi) * (PI * xi * 0.0002).sin() / (PI * xi * 0.0002)
}

fn staircase(n: usize) -> Vec<(f64, f64, f64)> { // n equal cells, each at the leaf's middle value
    let w = T / n as f64;
    (0..n).map(|k| (-T / 2.0 + k as f64 * w, -T / 2.0 + (k + 1) as f64 * w,
                    leaf(-T / 2.0 + (k as f64 + 0.5) * w))).collect()
}

fn stair_hat(st: &[(f64, f64, f64)], xi: f64) -> (f64, f64) {
    let zs: Vec<(f64, f64)> = st.iter().map(|&(a, b, _)| gate_hat(xi, a, b)).collect();
    (st.iter().zip(&zs).fold(0.0, |s, (p, z)| s + p.2 * z.0),
     st.iter().zip(&zs).fold(0.0, |s, (p, z)| s + p.2 * z.1))
}

fn l1_gap(st: &[(f64, f64, f64)], n: usize) -> f64 { // area of |leaf - staircase|, midpoint rule
    let f = |t: f64| (leaf(t) - st[(n - 1).min(((t + T / 2.0) / (T / n as f64)) as usize)].2).abs();
    by_integral(&f, -T / 2.0, T / 2.0, 0.0, 40000).0
}

fn spike_hat(x: f64, n: usize) -> (f64, f64) { // t = T u^2: integral of 2T e^(-2 pi i x u^2), Simpson
    let (mut re, mut im) = (0.0, 0.0);
    for k in 0..=n {
        let u = k as f64 / n as f64;
        let wt = if k == 0 || k == n { 1.0 } else if k % 2 == 1 { 4.0 } else { 2.0 };
        re += wt * (2.0 * PI * x * u * u).cos();
        im -= wt * (2.0 * PI * x * u * u).sin();
    }
    (2.0 * T * re / (3.0 * n as f64), 2.0 * T * im / (3.0 * n as f64))
}

fn main() {
    let gate = |t: f64| if -T / 2.0 <= t && t < T / 2.0 { 1.0 } else { 0.0 };
    println!("shutter: open 1 ms; area of |f| = {:.6} ms", ms(T));
    println!("xi Hz | closed form ms | integral n=8000 ms | gap n=4000 vs 8000 | share of xi = 0");
    let mut worst: f64 = 0.0;
    for xi in [0.0, 120.0, 500.0, 1000.0, 1500.0, 2500.0, 20500.0] {
        let c = gate_hat(xi, -T / 2.0, T / 2.0).0;
        let (n1, n2) = (by_integral(&gate, -T / 2.0, T / 2.0, xi, 4000), by_integral(&gate, -T / 2.0, T / 2.0, xi, 8000));
        worst = worst.max((c - n2.0).abs()).max(n2.1.abs());
        println!("{:5} | {:.6} | {:.6} | {:.9} | {:.6}", xi as i64, ms(c), ms(n2.0), ms((n1.0 - n2.0).abs()), ms(c) / ms(T));
    }
    println!("largest gap, closed form vs integral: {:.9} ms", ms(worst));
    assert!(worst < 1e-9); // road 1 = road 2

    // Third road: a light flickering 100% at 120 Hz, exposure for two shutter start times.
    let xi = 120.0;
    let expo = |t0: f64| by_integral(&|t: f64| 1.0 + (2.0 * PI * xi * (t - t0)).cos(), -T / 2.0, T / 2.0, 0.0, 4000).0;
    let (e_hi, e_lo) = (expo(0.0), expo(1.0 / (2.0 * xi)));
    println!("120 Hz flicker: exposure {:.6} ms to {:.6} ms; half the swing {:.6} ms = fhat(120)",
             ms(e_hi), ms(e_lo), ms((e_hi - e_lo) / 2.0));
    assert!(((e_hi - e_lo) / 2.0 - gate_hat(120.0, -T / 2.0, T / 2.0).0).abs() < 1e-11);
    println!("by hand at 120 Hz: pi xi T = {:.6}, sin of it = {:.6}, pi xi = {:.3} per second",
             PI * 120.0 * T, (PI * 120.0 * T).sin(), PI * 120.0);

    // Bounded: |fhat| <= area of |f|.  Continuous: one roof 2|f| for every frequency.
    let top = (-400..=400).map(|k| size(gate_hat(50.0 * k as f64, -T / 2.0, T / 2.0))).fold(0.0, f64::max);
    println!("largest |fhat| on -20 to 20 kHz: {:.6} ms, bound {:.6} ms", ms(top), ms(T));
    let h = 10.0;
    let jump = (0..=5000).map(|x| (gate_hat(x as f64 + h, -T / 2.0, T / 2.0).0 - gate_hat(x as f64, -T / 2.0, T / 2.0).0).abs())
        .fold(0.0, f64::max);
    let roof = 4.0 / (PI * h) * (1.0 - (PI * h * T / 2.0).cos()); // integral of |f| |e^(-2 pi i h t) - 1|
    let roof_n = by_integral(&|t: f64| size(((2.0 * PI * h * t).cos() - 1.0, (2.0 * PI * h * t).sin())), -T / 2.0, T / 2.0, 0.0, 4000).0;
    println!("step h = {} Hz: largest change {:.6} ms; bound {:.6} ms (integral {:.6}); ratio {:.3}",
             h, ms(jump), ms(roof), ms(roof_n), jump / roof);
    assert!(top <= T + 1e-15 && jump <= roof && (roof - roof_n).abs() < 1e-12);

    let xs: Vec<String> = (0..21).map(|k| (250 * k).to_string()).collect();
    let fs: Vec<String> = (0..21).map(|k| format!("{:.3}", ms(gate_hat(250.0 * k as f64, -T / 2.0, T / 2.0).0))).collect();
    let bs: Vec<String> = (0..21).map(|k| if k == 0 { "1.000".to_string() }
        else { format!("{:.3}", 1.0f64.min(ms(1.0 / (PI * 250.0 * k as f64)))) }).collect();
    println!("chart xi Hz: [{}]", xs.join(", "));
    println!("chart fhat ms: [{}]", fs.join(", "));
    println!("chart bound ms: [{}]", bs.join(", "));
    println!("gate at 20500 Hz: |fhat| {:.6} ms, fade bound 1/(pi xi) {:.6} ms",
             ms(gate_hat(20500.0, -T / 2.0, T / 2.0).0.abs()), ms(1.0 / (PI * 20500.0)));

    // Riemann-Lebesgue by approximation: a leaf shutter with 0.2 ms ramps, matched by staircases.
    let lh = by_integral(&leaf, -T / 2.0, T / 2.0, 3000.0, 8000);
    println!("leaf shutter at 3000 Hz: closed form {:.6} ms, integral {:.6} ms (gap {:.9} ms)",
             ms(leaf_hat(3000.0)), ms(lh.0), ms((leaf_hat(3000.0) - lh.0).abs()));
    assert!((leaf_hat(3000.0) - lh.0).abs() < 1e-10);
    for n in [5usize, 10, 20, 40] {
        let st = staircase(n);
        let l1 = l1_gap(&st, n);
        let gap = (0..=10000).map(|k| { let x = 5.0 * k as f64; let s = stair_hat(&st, x);
            size((leaf_hat(x) - s.0, s.1)) }).fold(0.0, f64::max);
        println!("staircase {:2} steps: area of |leaf - stair| {:.6} ms; largest spectrum gap, 5 Hz grid {:.6} ms", n, ms(l1), ms(gap));
        assert!(gap <= l1 + 1e-12 && (l1 - 0.0005 / n as f64).abs() < 1e-9);
    }
    let steps = 200usize; // the staircase used in the epsilon argument
    let st = staircase(steps);
    let jumps = (0..steps).map(|k| (st[k].2 - if k > 0 { st[k - 1].2 } else { 0.0 }).abs()).fold(0.0, |s, v| s + v) + st[steps - 1].2;
    let (eps, l1) = (0.00001, l1_gap(&st, steps));
    let xi0 = jumps / (2.0 * PI * (eps - l1)); // staircase fades like jumps / (2 pi xi)
    println!("target {:.3} ms: {} steps, gap {:.4} ms, left for the staircase {:.4} ms, total jump {:.6}; beyond {:.1} Hz",
             ms(eps), steps, ms(l1), ms(eps - l1), jumps, xi0);
    println!("leaf |fhat| at that frequency: {:.8} ms", ms(leaf_hat(xi0).abs()));
    assert!(leaf_hat(xi0).abs() < eps && size(stair_hat(&st, xi0)) <= jumps / (2.0 * PI * xi0));

    // An unbounded signal, sqrt(T/t) for 0 < t < T: no piecewise-smooth proof applies, yet it fades.
    println!("spike: area of |f| = {:.6} ms", ms(2.0 * T));
    for x in [1.0f64, 10.0, 100.0] { // x = xi T, a whole number
        let (a, b) = (spike_hat(x, 20000), spike_hat(x, 40000));
        let far = (T / (2.0 * x.sqrt()), -T / (2.0 * x.sqrt()) + T / (2.0 * PI * x)); // Fresnel, less the tail past u = 1
        println!("spike at {:6} Hz: |fhat| {:.6} ms, step gap {:.9}, Fresnel {:.6} ms; xi |fhat| {:.4}",
                 (1000.0 * x) as i64, ms(size(b)), ms(size((a.0 - b.0, a.1 - b.1))), ms(size(far)), 1000.0 * x * size(b));
        assert!(size(b) <= 2.0 * T && (size(a) - size(b)).abs() < 1e-12);
        assert!(x == 1.0 || (size(b) - size(far)).abs() < T / x.powi(2));
    }

    for l in [1.0, 1.0 + 1.0 / 480.0, 1.0 + 3.0 / 480.0] { // constant light: no finite area
        println!("mistake 1, constant light, integral over -L to L = {:.5} s at 120 Hz: {:.6} ms",
                 l, ms((2.0 * PI * 120.0 * l).sin() / (PI * 120.0)));
    }
    println!("mistake 2, omega form fed hertz: 2 sin(500 T/2)/500 = {:.6} ms, true {:.6} ms",
             ms(2.0 * (500.0 * T / 2.0).sin() / 500.0), ms(gate_hat(500.0, -T / 2.0, T / 2.0).0));
    let pulse = |t: f64| if t < 0.0 { 1.0 } else { -1.0 }; // +1 then -1: not even, so it pins the sign
    let (p, q) = (gate_hat(1000.0, -T / 2.0, 0.0), gate_hat(1000.0, 0.0, T / 2.0));
    let (pm, pn) = ((p.0 - q.0, p.1 - q.1), by_integral(&pulse, -T / 2.0, T / 2.0, 1000.0, 8000));
    println!("mistake 3, +1 then -1 pulse: net area {:.3} ms, but fhat(1000) = {:.6}i ms (integral {:.6}i ms), size {:.6} ms",
             ms(by_integral(&pulse, -T / 2.0, T / 2.0, 0.0, 8000).0), ms(pm.1), ms(pn.1), ms(size(pm)));
    assert!((pm.0 - pn.0).abs() < 1e-10 && (pm.1 - pn.1).abs() < 1e-10); // the sign of the exponent
    println!("ALL CHECKS PASS");
}
