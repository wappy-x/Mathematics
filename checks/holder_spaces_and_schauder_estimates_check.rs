// Schauder estimates -- the same check as holder_spaces_and_schauder_estimates_check.py, in Rust.
// Standard library only, no crates.  Scaled units: lengths in m, heights in m, T = 200 N/m, load q = T*f in Pa.
// Equation -Lap u = f on the disc r < 1/2.  Phi = -(1/2pi) ln|x| is the point-source potential.
use std::f64::consts::PI;
const T: f64 = 200.0; const R: f64 = 0.5; const N: usize = 1000;

// ---- A. a continuous source that is not Hoelder: u1 = (x^2 - y^2) sqrt(ln(1/r)) ----
fn u1(x: f64, y: f64) -> f64 { (x * x - y * y) * (1.0 / (x * x + y * y).sqrt()).ln().sqrt() }
fn f1(x: f64, y: f64) -> f64 {                         // -Lap u1, worked out by hand on the card
    let r2 = x * x + y * y; let l = (1.0 / r2.sqrt()).ln();
    (x * x - y * y) / r2 * (2.0 / l.sqrt() + 0.25 / l.powf(1.5))
}
fn bend1(r: f64) -> f64 { let l = (1.0 / r).ln(); 2.0 * l.sqrt() + 0.5 / l.sqrt() }   // u1_xx on the y-axis

// ---- B. a Hoelder source: f2 = r^(1/2); its Newtonian potential on the disc is -(4/25) r^(5/2) + const ----
fn f2(x: f64, y: f64) -> f64 { (x * x + y * y).powf(0.25) }
fn d2w(x: f64, y: f64) -> [f64; 3] {                   // (w_xx, w_xy, w_yy) of w = -(4/25) r^(5/2), by hand
    let r = (x * x + y * y).sqrt();
    if r == 0.0 { return [0.0, 0.0, 0.0]; }
    let (c, s) = (x / r, y / r);
    [-r.sqrt() * (0.6 * c * c + 0.4 * s * s), -0.2 * r.sqrt() * c * s, -r.sqrt() * (0.6 * s * s + 0.4 * c * c)]
}
fn korn_xx(x: f64, y: f64, n: usize) -> f64 {          // road 2: the proof's formula, polar about x
    let (fx, mut tot) = (f2(x, y), 0.0);
    for i in 0..n {
        let ph = (i as f64 + 0.5) * 2.0 * PI / n as f64; let (ex, ey) = (ph.cos(), ph.sin());
        let b = x * ex + y * ey; let l = -b + (b * b + R * R - x * x - y * y).sqrt();   // ray length to the rim
        let mut s = 0.0;
        for j in 0..n { let rho = (j as f64 + 0.5) * l / n as f64; s += (f2(x + rho * ex, y + rho * ey) - fx) / rho; }
        tot += -(2.0 * ph).cos() / (2.0 * PI) * (s * l / n as f64 + fx * l.ln());
    }
    -(tot * 2.0 * PI / n as f64 + fx / 2.0)
}
fn simpson<F: Fn(f64) -> f64>(g: F, a: f64, b: f64, n: usize) -> f64 {
    let (h, mut s) = ((b - a) / n as f64, 0.0);
    for i in 1..n { s += (if i % 2 == 1 { 4.0 } else { 2.0 }) * g(a + i as f64 * h); }
    (g(a) + g(b) + s) * h / 3.0
}
fn gauss_slope(r: f64) -> f64 { -simpson(|t| t * t.powf(0.5), 0.0, r, 2000) / r }   // road 3: Gauss's law
fn semi(vals: &[f64], pts: &[(f64, f64)], a: f64) -> f64 {   // largest Hoelder quotient over all pairs
    let mut m = f64::NEG_INFINITY;
    for i in 0..pts.len() { for j in 0..i {
        let d = ((pts[i].0 - pts[j].0) * (pts[i].0 - pts[j].0) + (pts[i].1 - pts[j].1) * (pts[i].1 - pts[j].1)).sqrt();
        m = m.max((vals[i] - vals[j]).abs() / d.powf(a));
    } }
    m
}

// ---- C. method of continuity: -a_t u'' = 1 on (0, 1), u(0) = u(1) = 0, a_t = 1 + t (a - 1) ----
fn solve(at: &[f64], g: &[f64], hx: f64) -> Vec<f64> {  // tridiagonal (Thomas) solve of -at u'' = g
    let n = N - 1;
    let (mut cp, mut dp) = (vec![0.0; n], vec![0.0; n]);
    for k in 0..n {
        let (lo, di) = (-at[k + 1] / (hx * hx), 2.0 * at[k + 1] / (hx * hx)); let hi = lo;
        let m = di - if k > 0 { lo * cp[k - 1] } else { 0.0 };
        cp[k] = hi / m;
        dp[k] = (g[k + 1] - if k > 0 { lo * dp[k - 1] } else { 0.0 }) / m;
    }
    let mut u = vec![0.0; N + 1];
    for k in (0..n).rev() { u[k + 1] = dp[k] - if k < n - 1 { cp[k] * u[k + 2] } else { 0.0 }; }
    u
}
fn d2(u: &[f64], hx: f64) -> Vec<f64> {
    let mut v = vec![0.0; N + 1];
    for i in 1..N { v[i] = (u[i + 1] - 2.0 * u[i] + u[i - 1]) / (hx * hx); }
    v
}
fn step(mut u: Vec<f64>, a: &[f64], s: f64, t: f64, iters: usize, hx: f64) -> (Vec<f64>, Vec<f64>) {
    let (at, mut ch): (Vec<f64>, Vec<f64>) = (a.iter().map(|ai| 1.0 + s * (ai - 1.0)).collect(), Vec::new());
    for _ in 0..iters {                                // u <- L_s^(-1)[f - (t - s)(L_1 - L_0) u]
        let g: Vec<f64> = a.iter().zip(d2(&u, hx)).map(|(ai, v)| 1.0 + (t - s) * (ai - 1.0) * v).collect();
        let un = solve(&at, &g, hx);
        ch.push(un.iter().zip(&u).map(|(p, q)| (p - q).abs()).fold(f64::NEG_INFINITY, f64::max)); u = un;
        if *ch.last().unwrap() < 1e-13 { break; }
    }
    (u, ch)
}

fn main() {
    println!("A. continuous source f1 = -Lap[(x^2 - y^2) sqrt(ln 1/r)], read on the y-axis at distance r");
    println!("     r (m)   f1 (1/m)   load (Pa)    |f1|/r^0.5  u_xx (1/m)  2 sqrt(ln 1/r)");
    let ks = [1i32, 2, 4, 8, 16];
    for k in ks {
        let r = 10f64.powf(-k as f64);
        println!("     1e-{:02} {:10.4} {:10.2} {:12.1} {:12.4} {:14.4}", k, f1(0.0, r), T * f1(0.0, r),
                 f1(0.0, r).abs() / r.sqrt(), bend1(r), 2.0 * (1.0 / r).ln().sqrt());
    }
    let mut fd = Vec::new();
    for r in [1e-1, 1e-2] {
        let h = r / 100.0; let uxx = (u1(h, r) - 2.0 * u1(0.0, r) + u1(-h, r)) / (h * h);
        let lap = (u1(h, r) + u1(-h, r) + u1(0.0, r + h) + u1(0.0, r - h) - 4.0 * u1(0.0, r)) / (h * h);
        fd.push((r, uxx, -lap));
        println!("  centred differences, h = r/100, r = 1e-0{}: bend {:.4}, -Lap u1 {:.4}", fd.len(), uxx, -lap);
    }
    println!("  by hand at r = 1e-02: ell {:.4}, sqrt(ell) {:.4}, r^0.5 {:.4}", 100f64.ln(), 100f64.ln().sqrt(), 0.01f64.sqrt());

    println!("B. Hoelder source f2 = r^0.5 on the disc r < 0.5, Newtonian potential w");
    let mut roads = Vec::new();
    for (x, y) in [(0.2f64, 0.0f64), (0.12, 0.16)] {
        let (r, e) = ((x * x + y * y).sqrt(), 1e-4);
        let w2 = (gauss_slope(r + e) - gauss_slope(r - e)) / (2.0 * e);
        let g3 = w2 * x * x / (r * r) + gauss_slope(r) / r * y * y / (r * r);
        roads.push((d2w(x, y)[0], korn_xx(x, y, 400), g3));
        println!("  bend w_xx at ({:.2}, {:.2}): by hand {:.6}, proof's formula {:.6}, Gauss's law {:.6}", x, y, roads[roads.len() - 1].0, roads[roads.len() - 1].1, g3);
        println!("     load there {:.2} Pa; -Lap w = w_xx + w_yy by hand {:.6}, f2 {:.6}", T * f2(x, y),
                 -d2w(x, y)[0] - d2w(x, y)[2], f2(x, y));
    }
    println!("  disc radius rho: sup|f2|  [f2]_0.5  sup|D2w|  [D2w]_0.5   (129 sample points)");
    let mut disc = Vec::new();
    for rho in [0.5f64, 0.05, 0.005, 0.0005] {
        let mut pts = vec![(0.0f64, 0.0f64)];
        for k in 1..9 { for m in 0..16 { let (rr, an) = (rho * k as f64 / 8.0, m as f64 * PI / 8.0); pts.push((rr * an.cos(), rr * an.sin())); } }
        let dd: Vec<[f64; 3]> = pts.iter().map(|p| d2w(p.0, p.1)).collect();
        let sup2 = dd.iter().flat_map(|d| d.iter()).fold(f64::NEG_INFINITY, |m, v| m.max(v.abs()));
        let comp = |c: usize, a: f64| semi(&dd.iter().map(|d| d[c]).collect::<Vec<_>>(), &pts, a);
        let h5 = comp(0, 0.5).max(comp(1, 0.5)).max(comp(2, 0.5));
        let fv: Vec<f64> = pts.iter().map(|p| f2(p.0, p.1)).collect(); let hf = semi(&fv, &pts, 0.5);
        disc.push((rho, hf, sup2, h5));
        println!("  {:16.4} {:8.4} {:9.4} {:9.4} {:10.4}", rho, fv.iter().cloned().fold(f64::NEG_INFINITY, f64::max), hf, sup2, h5);
    }
    let q6: Vec<f64> = [0.1f64, 1e-3, 1e-6, 1e-12].iter().map(|&e| { let (p, q) = (d2w(e, 0.0), d2w(0.0, 0.0));
        (0..3).map(|c| (p[c] - q[c]).abs()).fold(f64::NEG_INFINITY, f64::max) / e.powf(0.6) }).collect();
    println!("  exponent 0.6: D2w quotient from the centre to 10 cm, 1 mm, 1 um, 1e-12 m: {}", q6.iter().map(|q| format!("{:.4}", q)).collect::<Vec<_>>().join(", "));

    let hx = 1.0 / N as f64;
    let xs: Vec<f64> = (0..=N).map(|i| i as f64 * hx).collect();
    let a: Vec<f64> = xs.iter().map(|x| 1.0 + 2.0 * (2.0 * x - 1.0).abs().sqrt()).collect();   // Hoelder 1/2
    let ones = vec![1.0; N + 1]; println!("C. method of continuity, -a_t u'' = 1, a = 1 + 2 sqrt|2x - 1|, 1000 grid steps");
    let (mut u, ts) = (solve(&ones, &ones, hx), [0.0, 0.25, 0.5, 0.75, 1.0]);
    for w in ts.windows(2) {
        let (s, t) = (w[0], w[1]);
        let qb = (t - s) * a.iter().map(|ai| (ai - 1.0) / (1.0 + s * (ai - 1.0))).fold(f64::NEG_INFINITY, f64::max);
        let (un, ch) = step(u, &a, s, t, 100, hx); u = un; let nc = ch.len();
        println!("  step {:.2} -> {:.2}: bound on the factor {:.4}, change ratio near the end {:.2}, {} iterations, u(1/2) = {:.6} m",
                 s, t, qb, ch[nc - 2] / ch[nc - 3], nc, u[N / 2]);
    }
    let (_, big) = step(solve(&ones, &ones, hx), &a, 0.0, 1.0, 20, hx);
    println!("  one step 0 -> 1: bound on the factor {:.4}, change after 1, 10, 20 iterations {:.4}, {:.4}, {:.4} m",
             a.iter().map(|ai| ai - 1.0).fold(f64::NEG_INFINITY, f64::max), big[0], big[9], big[19]);
    let ud = solve(&a, &ones, hx); let exact = simpson(|s| (1.0 - s * s) * s / (2.0 * (1.0 + 2.0 * s)), 0.0, 1.0, 2000);
    println!("  u(1/2): continuity {:.8}, direct solve {:.8}, integral {:.8} m", u[N / 2], ud[N / 2], exact);
    let sub: Vec<usize> = (0..=N).step_by(5).collect();
    for t in [0.25f64, 0.5, 1.0] {
        let v: Vec<f64> = sub.iter().map(|&i| -1.0 / (1.0 + t * (a[i] - 1.0))).collect();
        let p: Vec<(f64, f64)> = sub.iter().map(|&i| (xs[i], 0.0)).collect();
        let (meas, b) = (semi(&v, &p, 0.5), t * 2.0 * 2f64.sqrt());
        let near = (1.0 - 1.0 / (1.0 + t * 2.0 * 2e-12f64.sqrt())) / 1e-12f64.sqrt();   // x = 1/2 against 1/2 + 1e-12
        println!("  t = {:.2}: [u'']_0.5 quotient on a 5 mm sample {:.4}, pair 1e-12 m apart at x = 1/2 {:.4}; bound [a_t]_0.5 * sup|f| / theta^2 = {:.4}", t, meas, near, b);
        assert!(meas < near && near < b && b < near + 1e-4, "the bound is reached as the pair closes in on x = 1/2");
    }
    println!("  coefficient a = 1 + 1/ln(1/|2x - 1|), only continuous: [u'']_0.5 quotient at distance d from x = 1/2");
    for k in [2i32, 4, 8] {
        let d = 10f64.powf(-k as f64); println!("     d = 1e-{:02}: {:.4}", k, (1.0 - 1.0 / (1.0 + 1.0 / (1.0 / (2.0 * d)).ln())) / d.sqrt());
    }
    println!("chart, k in r = 10^-k: 1, 2, 4, 8, 16");
    let b: Vec<String> = ks.iter().map(|&k| format!("{:.2}", bend1(10f64.powf(-k as f64)))).collect();
    println!("chart, bend under f1 (1/m): {}", b.join(", "));
    let fs: Vec<String> = ks.iter().map(|&k| format!("{:.2}", f1(0.0, 10f64.powf(-k as f64)).abs())).collect();
    println!("chart, size of f1 (1/m): {}", fs.join(", "));

    for (r, uxx, lap) in &fd {                         // roads agree: hand formulas against centred differences
        assert!((uxx - bend1(*r)).abs() < 1e-3 * bend1(*r) && (lap - f1(0.0, *r)).abs() < 1e-3 * f1(0.0, *r).abs()); }
    assert!(bend1(1e-16) > 2.5 * bend1(1e-2) && f1(0.0, 1e-16).abs() < f1(0.0, 1e-2).abs(), "source shrinks, bend grows");
    for (hand, korn, gauss) in &roads { assert!((korn - hand).abs() < 1e-5 && (gauss - hand).abs() < 1e-6, "three roads to the bend"); }
    assert!(disc.iter().all(|d| (d.3 - 0.6).abs() < 1e-9), "[D2w]_0.5 = 0.6 [f2]_0.5 on every disc");
    assert!((q6[3] / q6[1] - 1e9f64.powf(0.1)).abs() < 1e-9, "[D2w]_0.6 quotient grows like eta^-0.1 without bound");
    assert!((u[N / 2] - ud[N / 2]).abs() < 1e-11 && (ud[N / 2] - exact).abs() < 1e-4, "continuity = direct = integral");
    assert!(big[19] > 1e3 * big[0], "one giant step must diverge");
    println!("ALL CHECKS PASS");
}
