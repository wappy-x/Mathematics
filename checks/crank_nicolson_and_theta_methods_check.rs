// Crank-Nicolson and the theta family -- the same check as the Python, in Rust.
// No crates.  A steel bar 1 m long at 100 C, both ends plunged into ice water
// (0 C) at t = 0; heat obeys u_t = alpha u_xx.  Grid: h = 0.02 m, 49 inner
// nodes.  Road 1: theta steps solved by a written-out Thomas sweep.  Road 2: the
// grid's own sine modes, each multiplied by its factor g per step (no solves).
// Road 3: the true bar, as a Fourier series.  All agree as the analysis says.
use std::f64::consts::PI;
const ALPHA: f64 = 1e-5; // m^2/s (illustrative)
const N: usize = 50;
const T: f64 = 3600.0;
const H: f64 = 1.0 / N as f64;
const M: usize = N - 1;
fn sci(v: f64) -> String { format!("{:.3e}", v) }
fn xs() -> Vec<f64> { (0..M).map(|j| (j + 1) as f64 * H).collect() }
fn thomas(a: f64, b: f64, c: f64, d: &[f64]) -> (Vec<f64>, Vec<f64>, Vec<f64>) {
    let (mut cp, mut dp) = (vec![c / b], vec![d[0] / b]);
    for i in 1..d.len() {
        let p = b - a * cp[i - 1];
        cp.push(c / p);
        dp.push((d[i] - a * dp[i - 1]) / p);
    }
    let mut y = vec![0.0; d.len()];
    y[d.len() - 1] = dp[d.len() - 1];
    for i in (0..d.len() - 1).rev() { y[i] = dp[i] - cp[i] * y[i + 1]; }
    (y, cp, dp)
}
fn step(u: &[f64], dt: f64, th: f64) -> Vec<f64> {
    let r = ALPHA * dt / (H * H);
    let mut w = vec![0.0]; w.extend_from_slice(u); w.push(0.0);
    let rhs: Vec<f64> = (0..M).map(|j| u[j] + (1.0 - th) * r * (w[j] - 2.0 * w[j + 1] + w[j + 2])).collect();
    if th == 0.0 { rhs } else { thomas(-th * r, 1.0 + 2.0 * th * r, -th * r, &rhs).0 }
}
fn run(dt: f64, th: f64, damp: bool) -> Vec<Vec<f64>> {
    let mut u = vec![100.0; M];
    let mut out = vec![u.clone()];
    let mut k = 0;
    if damp { u = step(&step(&u, dt / 2.0, 1.0), dt / 2.0, 1.0); out.push(u.clone()); k = 1; }
    for _ in 0..((T / dt).round() as usize - k) { u = step(&u, dt, th); out.push(u.clone()); }
    out
}
fn s2(k: usize) -> f64 { (k as f64 * PI * H / 2.0).sin().powi(2) }
fn lam(k: usize) -> f64 { 4.0 * ALPHA / (H * H) * s2(k) }
fn g(k: usize, r: f64, th: f64) -> f64 { (1.0 - (1.0 - th) * 4.0 * r * s2(k)) / (1.0 + th * 4.0 * r * s2(k)) }
fn modes(b: &[f64], f: &dyn Fn(usize) -> f64) -> Vec<f64> {
    xs().iter().map(|&xj| {
        let mut s = 0.0;
        for k in 1..N { s += b[k - 1] * f(k) * (k as f64 * PI * xj).sin(); }
        s
    }).collect()
}
fn centre(m: usize) -> f64 { // the grid's exact-in-time centre with m cells: each sine mode decayed exactly
    let mf = m as f64;
    (1..m).map(|k| {
        let (kf, mut s) = (k as f64, 0.0);
        for j in 1..m { s += 100.0 * (kf * PI * j as f64 / mf).sin(); }
        2.0 / mf * s * (kf * PI / 2.0).sin() * (-4.0 * ALPHA * mf * mf * (kf * PI / mf / 2.0).sin().powi(2) * T).exp()
    }).sum()
}
fn maxerr(u: &[f64], v: &[f64]) -> f64 { u.iter().zip(v).map(|(p, q)| (p - q).abs()).fold(0.0, f64::max) }
fn join(v: &[f64], d: usize) -> String { v.iter().map(|x| format!("{:.*}", d, x)).collect::<Vec<_>>().join(", ") }
fn main() {
    let x = xs();
    let b: Vec<f64> = (1..N).map(|k| {
        let mut s = 0.0;
        for &xj in &x { s += 100.0 * (k as f64 * PI * xj).sin(); }
        2.0 / N as f64 * s
    }).collect();
    let dt = 200.0; let r = ALPHA * dt / (H * H);
    println!("explicit limit h^2/(2 alpha) = {:.1} s; chosen step {:.0} s; r = {:.6}", H * H / 2.0 / ALPHA, dt, r);
    let grid = modes(&b, &|k| (-lam(k) * T).exp());
    let mut tr = 0.0;
    for k in (1..2001).step_by(2) { tr += (k as f64 * PI / 2.0).sin() / k as f64 * (-ALPHA * (k as f64 * PI).powi(2) * T).exp(); }
    let tr = 400.0 / PI * tr;
    println!("centre at 1 h: true bar {:.6}, grid exact in time {:.6}, space error {}", tr, grid[24], sci(grid[24] - tr));
    let sp: Vec<f64> = [50, 100, 200].iter().map(|&m| centre(m) - tr).collect();
    println!("space error at the centre, h = 0.02, 0.01, 0.005 m: {}; ratios {:.2}, {:.2}",
             sp.iter().map(|&v| sci(v)).collect::<Vec<_>>().join(", "), sp[0] / sp[1], sp[1] / sp[2]);
    assert!((sp[0] - (grid[24] - tr)).abs() < 1e-9 && (0..2).all(|i| 3.9 < sp[i] / sp[i + 1] && sp[i] / sp[i + 1] < 4.1)); // series: grids close in at order 2
    // one Crank-Nicolson step by hand, from 100 C everywhere
    let rhs: Vec<f64> = (0..M).map(|j| {
        let w0 = if j == 0 { 0.0 } else { 100.0 };
        let w2 = if j == M - 1 { 0.0 } else { 100.0 };
        100.0 + r / 2.0 * (w0 - 200.0 + w2)
    }).collect();
    let (u1, cp, dp) = thomas(-r / 2.0, 1.0 + r, -r / 2.0, &rhs);
    println!("CN row: {:.6}, {:.6}, {:.6}; right side node 1 {:.6}, node 2 {:.6}", -r / 2.0, 1.0 + r, -r / 2.0, rhs[0], rhs[1]);
    println!("sweep: c'1 {:.6}, d'1 {:.6}; node 2 {:.6}; node 1 = d'1 - c'1 x node 2 = {:.6}", cp[0], dp[0], u1[1], u1[0]);
    println!("settled pivot 3 + sqrt(2.75) = {:.6}; sweep pivot 24 {:.6}", 3.0 + 2.75_f64.sqrt(), (-r / 2.0) / cp[23]);
    // road 2: measured factors against the formula, mode 1 and mode 49
    for k in [1usize, 49] {
        let um: Vec<f64> = x.iter().map(|&xj| (k as f64 * PI * xj).sin()).collect();
        let meas: Vec<f64> = [0.0, 0.5, 1.0].iter().map(|&th| step(&um, dt, th)[0] / um[0]).collect();
        let form: Vec<f64> = [0.0, 0.5, 1.0].iter().map(|&th| g(k, r, th)).collect();
        let e = (-lam(k) * dt).exp();
        let es = if k == 1 { format!("{:.6}", e) } else { sci(e) };
        println!("mode {}: 4r sin^2 {:.6}; g explicit {:.6}, CN {:.6}, backward {:.6}; exact e^(-lambda dt) {}",
                 k, 4.0 * r * s2(k), meas[0], meas[1], meas[2], es);
        assert!(maxerr(&meas, &form) < 1e-12);
    }
    let z = -lam(1) * dt;
    println!("mode 1: CN g - e^z = {}, Taylor z^3/12 = {}", sci(g(1, r, 0.5) - z.exp()), sci(z.powi(3) / 12.0));
    assert!(((g(1, r, 0.5) - z.exp()) / (z.powi(3) / 12.0) - 1.0).abs() < 0.03); // second order: error z^3/12, next term 1 + z
    let rs = [1.0, 5.0, 50.0, 5000.0];
    let f = |th: f64| rs.iter().map(|&rr| format!("r={} {:.6}", rr, g(49, rr, th))).collect::<Vec<_>>().join(", ");
    println!("CN g as r grows, sharpest mode: {}", f(0.5));
    println!("backward g as r grows: {}", f(1.0));
    // road 1 against road 2: stepped Thomas runs equal the mode formula
    let (cn, cnd, be) = (run(dt, 0.5, false), run(dt, 0.5, true), run(dt, 1.0, false));
    assert!(maxerr(&cn[18], &modes(&b, &|k| g(k, r, 0.5).powi(18))) < 1e-9);
    assert!(maxerr(&cnd[18], &modes(&b, &|k| g(k, r / 2.0, 1.0).powi(2) * g(k, r, 0.5).powi(17))) < 1e-9);
    let ex: Vec<Vec<f64>> = (0..7).map(|i| modes(&b, &|k| (-lam(k) * dt * i as f64).exp())).collect();
    println!("figure, t s: {}", join(&(0..7).map(|i| dt * i as f64).collect::<Vec<_>>(), 0));
    for (name, v) in [("CN", &cn), ("CN damped", &cnd), ("exact", &ex)] {
        println!("figure, node 1, {}: {}", name, join(&(0..7).map(|i| v[i][0]).collect::<Vec<_>>(), 1));
    }
    assert!(cn[1][0] < 0.0 && cnd.iter().all(|v| v.iter().all(|&y| y > 0.0))); // CN dips below ice; damped run does not
    println!("start-up, two backward half-steps: mode 49 x {:.6}, mode 1 x {:.6}", g(49, r / 2.0, 1.0).powi(2), g(1, r / 2.0, 1.0).powi(2));
    println!("centre at 1 h, dt 200: CN {:.6}, CN damped {:.6}, backward {:.6}; damped minus true bar {} = space {} + time {}",
             cn[18][24], cnd[18][24], be[18][24], sci(cnd[18][24] - tr), sci(grid[24] - tr), sci(cnd[18][24] - grid[24]));
    // order: max error against the grid's exact-in-time answer, as dt halves
    let dts = [400.0, 200.0, 100.0, 50.0, 25.0];
    let mut tab = vec![];
    for (nm, th, dm) in [("CN", 0.5, false), ("CN damped", 0.5, true), ("backward", 1.0, false), ("theta 0.6", 0.6, false)] {
        let e: Vec<f64> = dts.iter().map(|&d| maxerr(run(d, th, dm).last().unwrap(), &grid)).collect();
        let es: Vec<String> = e.iter().map(|&v| sci(v)).collect();
        let ra: Vec<String> = (0..4).map(|i| format!("{:.2}", e[i] / e[i + 1])).collect();
        println!("max error, dt 400..25, {}: {}; ratios {}", nm, es.join(", "), ra.join(", "));
        println!("figure, log10 error, {}: {}", nm, join(&e.iter().map(|v| v.log10()).collect::<Vec<_>>(), 2));
        tab.push(e);
    }
    println!("figure, log10 dt: {}", join(&dts.iter().map(|d| d.log10()).collect::<Vec<_>>(), 2));
    assert!((1..4).all(|i| 3.9 < tab[1][i] / tab[1][i + 1] && tab[1][i] / tab[1][i + 1] < 4.1));
    assert!((1..4).all(|i| 1.9 < tab[2][i] / tab[2][i + 1] && tab[2][i] / tab[2][i + 1] < 2.1));
    let exp20 = run(20.0, 0.0, false).pop().unwrap();
    println!("explicit at 20 s (r = 0.5): centre {:.6}, max error {}", exp20[24], sci(maxerr(&exp20, &grid)));
    // what breaks: steps too long for theta below one half
    for th in [0.0, 0.4] {
        let big = run(dt, th, false)[18].iter().fold(0.0_f64, |m, v| m.max(v.abs()));
        println!("theta {:.2} at r = 5: limit r <= {:.2}; sharpest g {:.6}; largest |u| at 1 h {}", th, 1.0 / (2.0 - 4.0 * th), g(49, r, th), sci(big));
        assert!(big > 100.0 && g(49, r, th).abs() > 1.0); // hotter than the start: impossible
    }
    let fl = 8 * M - 7;
    println!("flops: Thomas {}, right side {}; CN 18 steps {}, damped {}, explicit 180 steps {}",
             fl, 5 * M, 18 * (fl + 5 * M), 2 * fl + 17 * (fl + 5 * M), 180 * 5 * M);
    println!("ALL CHECKS PASS");
}
