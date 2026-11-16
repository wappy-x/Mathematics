// Dirichlet's theorem on a sawtooth, the same checks as the Python script.
// Standard library only, no crates. Every sum, kernel and integral (Simpson's rule) is written out.
use std::f64::consts::PI;

fn fmt(v: f64) -> String {
    format!("{:.6}", if v.abs() < 5e-13 { 0.0 } else { v })
}
fn saw(u: f64) -> f64 { u / PI } // the sawtooth, in volts
fn saw_sum(n_max: usize, x: f64) -> f64 {
    let mut s = 0.0;
    for n in 1..=n_max {
        let sg = if n % 2 == 1 { 1.0 } else { -1.0 };
        s += sg * (n as f64 * x).sin() / n as f64;
    }
    2.0 * s / PI
}
fn ramp_sum(n_max: usize, x: f64) -> f64 { // half ramp g: u/pi on (0, pi), 0 on (-pi, 0)
    let mut s = 0.25;
    for n in 1..=n_max {
        let (sg, nf) = (if n % 2 == 1 { 1.0 } else { -1.0 }, n as f64);
        s += -(1.0 + sg) / (PI * PI * nf * nf) * (nf * x).cos() + sg / (PI * nf) * (nf * x).sin();
    }
    s
}
fn tri(x: f64) -> f64 { 1.0 - 2.0 * x.abs() / PI }
fn tri_sum(n_max: usize, x: f64) -> f64 {
    let mut s = 0.0;
    let mut n = 1;
    while n <= n_max {
        let nf = n as f64;
        s += (nf * x).cos() / (nf * nf);
        n += 2;
    }
    8.0 * s / (PI * PI)
}
fn simpson<F: Fn(f64) -> f64>(g: F, a: f64, b: f64, m: usize) -> f64 {
    let h = (b - a) / m as f64;
    let mut s = g(a) + g(b);
    for k in 1..m {
        s += if k % 2 == 1 { 4.0 } else { 2.0 } * g(a + k as f64 * h);
    }
    s * h / 3.0
}
fn dirichlet(n: usize, t: f64) -> f64 {
    let d = (t / 2.0).sin();
    if d.abs() < 1e-12 { 2.0 * n as f64 + 1.0 } else { ((n as f64 + 0.5) * t).sin() / d }
}
fn kernel(sig: fn(f64) -> f64, a: f64, b: f64, n: usize, x: f64) -> f64 {
    simpson(|u| sig(u) * dirichlet(n, x - u), a, b, 20000) / (2.0 * PI)
}
fn odd_tail(start: usize, scale: f64) -> f64 { // sum of scale/n^2 over odd n from start, to 2,000,000
    let mut s = 0.0;
    let mut n = start;
    while n < 2000001 {
        s += scale / (n as f64 * n as f64);
        n += 2;
    }
    s
}
fn join(v: Vec<String>, sep: &str) -> String { v.join(sep) }

fn main() {
    let ns = [10usize, 90, 1000];
    println!("sawtooth f(x) = x/pi volts on (-pi, pi), snapping from +1 V to -1 V at x = pi");
    println!("at 220 Hz the harmonics below 20000 Hz are n = 1..{}, top {} Hz", 20000 / 220, 220 * 90);
    println!("one cycle = {:.6} ms; x = pi/2 is {:.6} ms after the ramp starts; x = 0.99 pi and 0.999 pi are {:.3} and {:.3} microseconds before the snap",
        1000.0 / 220.0, 0.75 * 1000.0 / 220.0, 0.005e6 / 220.0, 0.0005e6 / 220.0);
    let mut row = vec![];
    for &n in &[1usize, 2, 90] {
        let num = simpson(|u| saw(u) * (n as f64 * u).sin(), -PI, PI, 40000) / (2.0 * PI);
        let exact = 1.0 / (PI * n as f64);
        assert!((num.abs() - exact).abs() < 1e-9);
        row.push(format!("n = {}: {} by Simpson, {} = 1/(pi n)", n, fmt(num.abs()), fmt(exact)));
    }
    println!("coefficient size |f^(n)|: {}", join(row, "; "));
    let snap: Vec<f64> = ns.iter().map(|&n| saw_sum(n, PI)).collect();
    assert!(snap.iter().all(|v| v.abs() < 1e-9));
    println!("at the snap x = pi: {}; midpoint (1 + (-1))/2 = 0",
        join(ns.iter().zip(&snap).map(|(n, v)| format!("S_{} = {}", n, fmt(*v))).collect(), ", "));
    println!("at x = pi/2 by hand: {}",
        join([1usize, 3, 5].iter().map(|&n| format!("S_{} = {}", n, fmt(saw_sum(n, PI / 2.0)))).collect(), ", "));
    let err: Vec<f64> = ns.iter().map(|&n| saw_sum(n, PI / 2.0) - 0.5).collect();
    assert!(err[0].abs() > err[1].abs() && err[1].abs() > err[2].abs() && err[2].abs() < 1e-3);
    println!("at x = pi/2, f = 0.5 V, error S_N - f: {}",
        join(ns.iter().zip(&err).map(|(n, e)| format!("N = {}: {}", n, fmt(*e))).collect(), ", "));
    let k90 = kernel(saw, -PI, PI, 90, PI / 2.0);
    assert!((k90 - saw_sum(90, PI / 2.0)).abs() < 1e-9);
    println!("at x = pi/2, N = 90: by the terms {}, by the kernel integral {}", fmt(saw_sum(90, PI / 2.0)), fmt(k90));
    let row: Vec<String> = [0.5, 0.9, 0.99, 0.999].iter()
        .map(|&c: &f64| format!("x = {} pi: {}", c, fmt(saw_sum(90, c * PI) - c))).collect();
    assert!((saw_sum(5000, 0.9 * PI) - 0.9).abs() < 1e-3); // far from the snap the ramp is reached
    println!("error at N = 90, f = x/pi: {}", join(row, ", "));
    let gap: Vec<f64> = ns.iter().map(|&n| saw(PI - 1e-6) - saw_sum(n, PI - 1e-6)).collect();
    assert!(gap.iter().all(|&g| g > 0.99));
    println!("just left of the snap, x = pi - 0.000001, gap f - S_N: {}",
        join(ns.iter().zip(&gap).map(|(n, g)| format!("N = {}: {}", n, fmt(*g))).collect(), ", "));
    let mut row = vec![];
    for &n in &ns {
        let mut tot = 0.0;
        for k in 1..=n { tot += 1.0 / (PI * k as f64); }
        tot *= 2.0;
        let nf = n as f64;
        let lg = (2.0 / PI) * (nf.ln() + 0.5772156649015329 + 1.0 / (2.0 * nf) - 1.0 / (12.0 * nf * nf));
        assert!((tot - lg).abs() < 1e-6);
        row.push(format!("N = {}: {}", n, fmt(tot)));
    }
    println!("sizes added, sum of |f^(n)| for 0 < |n| <= N: {}; grows like (2/pi) log N", join(row, ", "));
    println!("half ramp g: equals f on (0, pi), is 0 on (-pi, 0); S_1 g(pi/2) = {}, S_1 f(pi/2) = {}, difference {}",
        fmt(ramp_sum(1, PI / 2.0)), fmt(saw_sum(1, PI / 2.0)), fmt(saw_sum(1, PI / 2.0) - ramp_sum(1, PI / 2.0)));
    let dif: Vec<f64> = ns.iter().map(|&n| saw_sum(n, PI / 2.0) - ramp_sum(n, PI / 2.0)).collect();
    let kd = kernel(saw, -PI, 0.0, 90, PI / 2.0);
    assert!((kd - dif[1]).abs() < 1e-9 && dif[2].abs() < 1e-3 && 1e-3 < dif[0].abs());
    println!("at x = pi/2, S_N f - S_N g: {}; by the kernel at N = 90: {}",
        join(ns.iter().zip(&dif).map(|(n, d)| format!("N = {}: {}", n, fmt(*d))).collect(), ", "), fmt(kd));
    let mut row = vec![];
    for &n in &ns {
        let mut worst: f64 = 0.0;
        for k in 0..2001 {
            let x = PI * (k as f64 - 1000.0) / 1000.0;
            worst = worst.max((tri(x) - tri_sum(n, x)).abs());
        }
        let cap = odd_tail(n + 1 + n % 2, 8.0 / (PI * PI)) + 4.0 / (PI * PI * 2000001.0);
        assert!((worst - cap).abs() < 1e-6);
        row.push(format!("N = {}: worst {}, tail {}", n, fmt(worst), fmt(cap)));
    }
    println!("triangle T(x) = 1 - 2|x|/pi volts, worst error over the cycle against the M-test tail:");
    println!("  {}", join(row, "; "));
    let tot = 2.0 * odd_tail(1, 4.0 / (PI * PI)) + 4.0 / (PI * PI * 2000001.0);
    assert!((tot - 1.0).abs() < 1e-6);
    let d2 = simpson(|_u| (2.0 / PI) * (2.0 / PI), -PI, PI, 2) / (2.0 * PI);
    let p2 = 2.0 * odd_tail(1, 16.0 / PI.powi(4)) + 8.0 / (PI.powi(4) * 2000001.0);
    assert!((d2 - p2).abs() < 1e-6);
    let bound = PI / 3f64.sqrt() * d2.sqrt();
    assert!(bound > tot); // the bound sits above the true total
    println!("sum of |T^(n)| = {}; ||T'|| = {} (by coefficients {}); bound (pi/sqrt 3) ||T'|| = {}; ratio {}",
        fmt(tot), fmt(d2.sqrt()), fmt(p2.sqrt()), fmt(bound), fmt(tot / bound));
    let first = 8.0 / (PI * PI * 91.0 * 91.0);
    let true90 = 1.0 - tri_sum(90, 0.0);
    assert!(true90 > 40.0 * first);
    println!("what breaks: first omitted cap at N = 90 is {}; true worst error {}, {:.1} times larger", fmt(first), fmt(true90), true90 / first);
    let xs: Vec<f64> = (0..21).map(|k| k as f64 * PI / 20.0).collect();
    println!("figure, x: {}", join(xs.iter().map(|x| format!("{:.2}", x)).collect(), ", "));
    println!("figure, f: {}", join(xs.iter().map(|&x| format!("{:.2}", saw(x))).collect(), ", "));
    for &n in &[5usize, 90] {
        println!("figure, S_{}: {}", n, join(xs.iter().map(|&x| {
            let v = saw_sum(n, x);
            format!("{:.2}", if v.abs() < 5e-3 { 0.0 } else { v })
        }).collect(), ", "));
    }
    println!("ALL CHECKS PASS");
}
