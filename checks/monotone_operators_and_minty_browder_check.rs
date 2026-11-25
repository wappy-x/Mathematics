// Monotone operators and Minty-Browder -- the same check as the Python file, in Rust.  std only, no crates.
// Problem (scaled): -((u')^3)' + u' = 1 on 0 < x < 1, u(0) = u(1) = 0.  Three roads to u:
// a closed form after integrating once, RK4 shooting, and Galerkin on hat functions.
use std::f64::consts::PI;

fn cbrt(y: f64) -> f64 { if y >= 0.0 { y.powf(1.0 / 3.0) } else { -(-y).powf(1.0 / 3.0) } }
fn g_of(t: f64) -> f64 { 3.0 * (t * t / 2.0 + t + (1.0 - t).ln()) }   // x = G(t) - G(t0) along the solution

fn bisect<F: Fn(f64) -> f64>(f: F, mut lo: f64, mut hi: f64, n: usize) -> f64 {
    let mut flo = f(lo);
    for _ in 0..n {
        let mid = (lo + hi) / 2.0;
        let fm = f(mid);
        if (fm > 0.0) == (flo > 0.0) { lo = mid; flo = fm; } else { hi = mid; }
    }
    (lo + hi) / 2.0
}

fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut acc = 0.0;
    for i in 1..n { acc += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    h / 3.0 * (f(a) + f(b) + acc)
}

fn sci(v: f64, p: usize) -> String {                                   // Python-style e-notation: 6.6e-06
    let s = format!("{:.*e}", p, v);
    let (m, e) = s.split_once('e').unwrap();
    let e: i32 = e.parse().unwrap();
    format!("{}e{}{:02}", m, if e < 0 { '-' } else { '+' }, e.abs())
}

fn shoot(cc: f64, n: usize) -> f64 {
    let (h, mut u) = (1.0 / n as f64, 0.0);
    let f = |x: f64, u: f64| cbrt(u - x - cc);
    for i in 0..n {
        let x = i as f64 * h;
        let k1 = f(x, u); let k2 = f(x + h / 2.0, u + h / 2.0 * k1);
        let k3 = f(x + h / 2.0, u + h / 2.0 * k2); let k4 = f(x + h, u + h * k3);
        u += h * (k1 + 2.0 * k2 + 2.0 * k3 + k4) / 6.0;
    }
    u
}

fn galerkin(n: usize, b: f64) -> Vec<f64> {                           // hats, drift strength b, Newton
    let h = 1.0 / n as f64;
    let mut u: Vec<f64> = (0..=n).map(|i| { let x = i as f64 * h; x * (1.0 - x) }).collect();
    for _ in 0..60 {
        let s: Vec<f64> = (0..n).map(|e| (u[e + 1] - u[e]) / h).collect();
        let mut r: Vec<f64> = (1..n).map(|i| s[i - 1].powi(3) - s[i].powi(3) + b * (u[i + 1] - u[i - 1]) / 2.0 - h).collect();
        let lo: Vec<f64> = (1..n).map(|i| -3.0 * s[i - 1] * s[i - 1] / h - b / 2.0).collect();
        let mut di: Vec<f64> = (1..n).map(|i| 3.0 * (s[i - 1] * s[i - 1] + s[i] * s[i]) / h).collect();
        let up: Vec<f64> = (1..n).map(|i| -3.0 * s[i] * s[i] / h + b / 2.0).collect();
        let m = n - 1;
        for i in 1..m { let w = lo[i] / di[i - 1]; di[i] -= w * up[i - 1]; r[i] -= w * r[i - 1]; }
        let mut d = vec![0.0; m];
        d[m - 1] = r[m - 1] / di[m - 1];
        for i in (0..m - 1).rev() { d[i] = (r[i] - up[i] * d[i + 1]) / di[i]; }
        for i in 0..m { u[i + 1] -= d[i]; }
        if d.iter().fold(0.0_f64, |a, v| a.max(v.abs())) < 1e-14 { break; }
    }
    u
}

fn main() {
    // ---- road 1: integrate once, separate variables, one equation for t0 = u'(0)
    let t0 = bisect(|s| g_of(cbrt(s.powi(3) - 1.0)) - g_of(s) - 1.0, 0.0, 0.999, 80);
    let (t1, c) = (cbrt(t0.powi(3) - 1.0), -t0.powi(3));
    let xpk = -g_of(t0); let upk = xpk + c;
    let u_exact = |x: f64| -> f64 {
        if x <= 0.0 || x >= 1.0 { return 0.0; }
        let t = bisect(|s| g_of(s) - g_of(t0) - x, t1, t0, 80);
        t.powi(3) + c + x
    };
    let dxdt = |t: f64| 3.0 * t * t / (1.0 - t);
    let energy = simpson(|t| t.powi(4) * dxdt(t), t1, t0, 2000);
    let mass = simpson(|t| (t.powi(3) + c + g_of(t) - g_of(t0)) * dxdt(t), t1, t0, 2000);
    println!("road 1 closed form: u'(0) = {:.9}, u'(1) = {:.9}, c = {:.9}", t0, t1, c);
    println!("  G(u'(0)) = {:.6}, G(u'(1)) = {:.6}, difference = {:.6} m", g_of(t0), g_of(t1), g_of(t1) - g_of(t0));
    println!("  by hand: z0^2/2 = {:.6}, 1 - z0 = {:.6}, z1^2/2 = {:.6}, 1 - z1 = {:.6}", t0 * t0 / 2.0, 1.0 - t0, t1 * t1 / 2.0, 1.0 - t1);
    println!("  peak u = {:.9} at x = {:.9} m", upk, xpk);
    println!("  test with u: int (u')^4 = {:.9}, int u = {:.9}, ||u'||_4 = {:.6}", energy, mass, energy.powf(0.25));

    // ---- road 2: shooting by RK4, bisect on c until u(1) = 0
    let shots: Vec<f64> = [1000usize, 4000].iter().map(|&n| bisect(|cc| shoot(cc, n), -1.0, 0.0, 60)).collect();
    for (n, cs) in [1000, 4000].iter().zip(&shots) {
        println!("road 2 shooting, {} RK4 steps: c = {:.9}, |error| = {}", n, cs, sci((cs - c).abs(), 1));
    }
    println!("  error ratio, 1000 to 4000 steps: {:.1}", (shots[0] - c).abs() / (shots[1] - c).abs());

    // ---- road 3: Galerkin on hat functions
    let ns = [40usize, 80, 160, 320, 640, 1280];
    let mut errs = Vec::new();
    let (mut u, mut kk) = (Vec::new(), 0);
    for &n in &ns {
        u = galerkin(n, 1.0);
        errs.push((1..n).map(|i| (u[i] - u_exact(i as f64 / n as f64)).abs()).fold(0.0_f64, f64::max));
        let mut k = 0;
        for i in 0..=n { if u[i] > u[k] { k = i; } }
        kk = k;
        println!("road 3 Galerkin h = 1/{:<4}: max node error {}, top node u = {:.6} at x = {:.6} m",
                 n, sci(errs[errs.len() - 1], 3), u[k], k as f64 / n as f64);
    }
    println!("  overall order from h = 1/80 to 1/1280: {:.3}", (errs[1] / errs[5]).ln() / 16f64.ln());
    println!("  error ratios: 1/80 to 1/160 {:.1}, 1/320 to 1/640 {:.1}", errs[1] / errs[2], errs[3] / errs[4]);
    let sh: Vec<f64> = (0..1280).map(|i| (u[i + 1] - u[i]) * 1280.0).collect();
    println!("  h = 1/1280 tested with u_h: int (u_h')^4 = {:.9}, int u_h = {:.9}",
             sh.iter().map(|v| v.powi(4)).sum::<f64>() / 1280.0, u.iter().sum::<f64>() / 1280.0);
    let u0 = |x: f64| 0.75 * (0.5f64.powf(4.0 / 3.0) - (0.5 - x).abs().powf(4.0 / 3.0));
    let uz = galerkin(80, 0.0);
    let e0 = (1..80).map(|i| (uz[i] - u0(i as f64 / 80.0)).abs()).fold(0.0_f64, f64::max);
    println!("no drift: peak u = {:.9} at x = 0.5 m; Galerkin h = 1/80 max node error {}", u0(0.5), sci(e0, 3));
    println!("  the flow moves the peak {:.4} m downstream and lowers it by {:.4}", xpk - 0.5, u0(0.5) - upk);
    let xs: Vec<f64> = (0..11).map(|i| i as f64 / 10.0).collect();
    let row = |f: &dyn Fn(f64) -> String| xs.iter().map(|&x| f(x)).collect::<Vec<_>>().join(" ");
    println!("{:<17}{}", "chart x (m)", row(&|x| format!("{:5.1}", x)));
    println!("{:<17}{}", "chart with drift", row(&|x| format!("{:5.3}", u_exact(x))));
    println!("{:<17}{}", "chart no drift", row(&|x| format!("{:5.3}", u0(x))));

    // ---- monotone: u = x(1 - x), v = sin(pi x)/4
    let du = |x: f64| 1.0 - 2.0 * x;
    let dv = |x: f64| PI * (PI * x).cos() / 4.0;
    let mono_cube = simpson(|x| (du(x).powi(3) - dv(x).powi(3)) * (du(x) - dv(x)), 0.0, 1.0, 2000);
    let mono_drift = simpson(|x| (du(x) - dv(x)) * (x * (1.0 - x) - (PI * x).sin() / 4.0), 0.0, 1.0, 2000);
    println!("monotone check: cubic part {:.9}, drift part {:.9}", mono_cube, mono_drift.abs());

    // ---- no energy: work of A around the loop g(s) = cos(s) sin(pi x) + sin(s) sin(2 pi x)
    let (mm, mut cube, mut drift) = (200, 0.0, 0.0);
    for j in 0..mm {
        let s = 2.0 * PI * j as f64 / mm as f64;
        let dg = |x: f64| s.cos() * PI * (PI * x).cos() + s.sin() * 2.0 * PI * (2.0 * PI * x).cos();
        let gs = |x: f64| -s.sin() * (PI * x).sin() + s.cos() * (2.0 * PI * x).sin();
        let dgs = |x: f64| -s.sin() * PI * (PI * x).cos() + s.cos() * 2.0 * PI * (2.0 * PI * x).cos();
        cube += simpson(|x| dg(x).powi(3) * dgs(x), 0.0, 1.0, 400) * 2.0 * PI / mm as f64;
        drift += simpson(|x| dg(x) * gs(x), 0.0, 1.0, 400) * 2.0 * PI / mm as f64;
    }
    println!("loop work: cubic part {:.9}, drift part = {:.9}, 8 pi/3 = {:.9}", cube.abs(), drift, 8.0 * PI / 3.0);

    // ---- why a weak limit needs Minty: slopes 2 on the first half of each of m periods, else 0
    let mut b_last = 0.0;
    for m in [10.0f64, 1000.0] {
        let w = |x: f64| if (x * m) % 1.0 < 0.5 { 2.0 } else { 0.0 };
        let n = 20000;
        let a = (0..n).map(|i| { let x = (i as f64 + 0.5) / n as f64; w(x) * x }).sum::<f64>() / n as f64;
        let b = (0..n).map(|i| { let x = (i as f64 + 0.5) / n as f64; w(x).powi(3) * x }).sum::<f64>() / n as f64;
        println!("m = {}: int w_m x dx = {:.6} (1/2 - 1/(4m) = {:.6}), int w_m^3 x dx = {:.6}", m, a, 0.5 - 0.25 / m, b);
        b_last = b;
    }
    println!("weak limit w = 1: int 1^3 x dx = {:.6}; limit of int w_m^3 x dx = {:.6} = 4 x 0.5", 0.5, 2.0);

    // ---- what breaks: one-dimensional operators, each missing one hypothesis
    println!("not coercive: arctan(x) = 2 has no root; arctan(1e6) = {:.6}, pi/2 = {:.6}", 1e6f64.atan(), PI / 2.0);
    let jump = |x: f64| x + if x >= 0.0 { 1.0 } else { 0.0 };
    println!("not hemicontinuous: x + [x >= 0] = 0.5 has no root; value {:.6} at x = -0.001, {:.6} at 0", jump(-1e-3), jump(0.0));
    let roots: Vec<String> = [(-2.5, -1.0), (-1.0, 1.2), (1.0, 2.5)].iter()
        .map(|&(a, b)| (bisect(|x| x.powi(3) - 3.0 * x, a, b, 80) * 1e6).round() / 1e6 + 0.0)
        .map(|r| format!("{:.6}", r)).collect();
    println!("not monotone: x^3 - 3x = 0 has roots {}", roots.join(", "));

    assert!((energy - mass).abs() < 1e-9, "testing with u: int (u')^4 must equal int u");
    assert!((u[kk] - upk).abs() < 2e-5 && (kk as f64 / 1280.0 - xpk).abs() < 2.0 / 1280.0, "Galerkin top node lands on the closed-form peak");
    assert!(shots.iter().all(|cs| (cs - c).abs() < 1e-4), "shooting lands on the closed form's c");
    assert!(errs[5] < 2e-5 && errs[0] > errs[1] && errs[1] > errs[5], "Galerkin settles on the closed form");
    assert!(e0 < 2e-4, "Galerkin without drift lands on the energy case's formula");
    assert!(mono_cube > 0.0 && mono_drift.abs() < 1e-9, "monotone: cubic part positive, drift part zero");
    assert!((drift - 8.0 * PI / 3.0).abs() < 1e-8 && cube.abs() < 1e-8, "loop work: drift 8 pi/3, cubic part 0");
    assert!((b_last - (2.0 - 1.0 / 1000.0)).abs() < 1e-9, "weak limit of the cubes is 2, not the cube of the weak limit");
    println!("ALL CHECKS PASS");
}
