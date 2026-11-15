// The slope transform -- the check behind the card.  Rust std only, no crates.
// A washing line 2 m long at tension 100 N; a 10 N towel hangs from its middle.  A shape is the
// sag (m, down positive) at N equally spaced points; a load is a list of forces (N) there.
// Energy f(u) = T/(2h) x (sum of squared steps), in J.  Conjugate f*(F) = largest work minus energy.
// Roads: closed forms; brute-force grids; a tridiagonal solve against Green's function; the
// energy rebuilt from the conjugate alone by conjugate-gradient ascent.
const T: f64 = 100.0; const L: f64 = 2.0; const P: f64 = 10.0; const C: f64 = 0.03;
const PI: f64 = std::f64::consts::PI;

fn k1(t: f64) -> f64 { 4.0 * t / L }
fn f1(u: f64, t: f64, c: Option<f64>) -> f64 {
    match c { Some(c) if u > c + 1e-12 => f64::INFINITY, _ => 0.5 * k1(t) * u * u }
}
fn fstar1(f: f64, t: f64, c: Option<f64>) -> f64 {
    let k = k1(t);
    match c { Some(c) if f > k * c => c * f - 0.5 * k * c * c, _ => f * f / (2.0 * k) }
}
fn grid_max(fun: &dyn Fn(f64) -> f64, lo: f64, hi: f64, n: usize) -> (f64, f64) {
    let (mut best, mut arg) = (f64::NEG_INFINITY, lo);
    for i in 0..=n {
        let x = lo + (hi - lo) * i as f64 / n as f64;
        let v = fun(x);
        if v > best { best = v; arg = x; }
    }
    (best, arg)
}
fn one_point(t: f64, p: f64, c: f64) -> (f64, f64, f64, f64) {
    let k = k1(t); let s = (p / k).min(c);
    (s, fstar1(p, t, Some(c)), k * s, p - k * s)
}
fn solve(n: usize, f: &[f64]) -> Vec<f64> {
    let a = T * (n + 1) as f64 / L; let (mut cp, mut dp) = (vec![0.0; n], vec![0.0; n]);
    for i in 0..n {
        let m = 2.0 * a + if i > 0 { a * cp[i - 1] } else { 0.0 };
        cp[i] = -a / m; dp[i] = (f[i] + if i > 0 { a * dp[i - 1] } else { 0.0 }) / m;
    }
    let mut u = vec![0.0; n];
    for i in (0..n).rev() { u[i] = dp[i] - if i + 1 < n { cp[i] * u[i + 1] } else { 0.0 }; }
    u
}
fn dot(x: &[f64], y: &[f64]) -> f64 { x.iter().zip(y).map(|(p, q)| p * q).sum() }
fn fstar(n: usize, f: &[f64]) -> f64 { 0.5 * dot(f, &solve(n, f)) }
fn padded(u: &[f64]) -> Vec<f64> { let mut w = vec![0.0]; w.extend_from_slice(u); w.push(0.0); w }
fn energy(n: usize, u: &[f64]) -> f64 {
    let w = padded(u); let h = L / (n + 1) as f64;
    T / (2.0 * h) * (0..=n).map(|i| (w[i + 1] - w[i]).powi(2)).sum::<f64>()
}
fn kslope(n: usize, u: &[f64]) -> f64 {
    let w = padded(u); let h = L / (n + 1) as f64;
    ((1..=n).map(|i| (T / h * (2.0 * w[i] - w[i - 1] - w[i + 1])).powi(2)).sum::<f64>() / h).sqrt()
}
fn rebuild(n: usize, u: &[f64]) -> f64 {
    let mut f = vec![0.0; n]; let mut r = u.to_vec(); let mut p = r.clone(); let mut rr = dot(&r, &r);
    for _ in 0..3 * n + 10 {
        if rr < 1e-30 * dot(u, u) { break; }
        let mp = solve(n, &p); let al = rr / dot(&p, &mp);
        for i in 0..n { f[i] += al * p[i]; r[i] -= al * mp[i]; }
        let rn = dot(&r, &r);
        for i in 0..n { p[i] = r[i] + rn / rr * p[i]; }
        rr = rn;
    }
    dot(&f, u) - fstar(n, &f)
}

fn main() {
    // ---- one point: compute the conjugate, rebuild the energy, read the slopes at the fence ----
    println!("one point: spring rate {:.4} N/m, towel {:.4} N", k1(T), P);
    let (g, s) = grid_max(&|u| P * u - f1(u, T, None), -0.2, 0.2, 400000);
    println!("conjugate at 10 N: formula {:.6} J, grid {:.6} J at sag {:.6} m", fstar1(P, T, None), g, s);
    assert!((g - P * P / (2.0 * k1(T))).abs() < 1e-9 && (s - 0.05).abs() < 1e-6);
    let (b, _) = grid_max(&|f| 0.05 * f - fstar1(f, T, None), 0.0, 40.0, 400000);
    println!("energy at 5 cm: rebuilt from the conjugate {:.6} J, direct {:.6} J", b, f1(0.05, T, None));
    assert!((b - f1(0.05, T, None)).abs() < 1e-9);
    let (e5, c10) = (f1(0.05, T, None), fstar1(P, T, None));
    println!("Fenchel-Young: {:.6} + {:.6} = {:.6} = 10 x 0.05", e5, c10, e5 + c10);
    let (gc, sc) = grid_max(&|u| P * u - f1(u, T, Some(C)), -0.2, 0.2, 400000);
    println!("fence at 3 cm, conjugate at 10 N: formula {:.6} J, grid {:.6} J at sag {:.6} m", fstar1(P, T, Some(C)), gc, sc);
    assert!((gc - fstar1(P, T, Some(C))).abs() < 1e-9);
    let ties: Vec<f64> = (0..41).map(|f| f as f64 / 2.0)
        .filter(|&f| (f1(C, T, Some(C)) + fstar1(f, T, Some(C)) - C * f).abs() < 1e-12).collect();
    println!("slopes at the fence, read from the conjugate: {} of 41 loads tie, {:.4} N to {:.4} N", ties.len(), ties[0], ties[ties.len() - 1]);
    assert!(ties == (12..41).map(|f| f as f64 / 2.0).collect::<Vec<f64>>());
    let d = 1e-7; let left = (f1(C, T, Some(C)) - f1(C - d, T, Some(C))) / d;
    println!("left slope at 3 cm {:.4} N; right slope: none (the fence); gap at 5 N {:.6} J", left, f1(C, T, Some(C)) + fstar1(5.0, T, Some(C)) - C * 5.0);
    assert!((left - k1(T) * C).abs() < 1e-4);
    let (_, _, sp, fe) = one_point(T, P, C);
    println!("towel 10 N at the fence: spring {:.4} N, fence {:.4} N", sp, fe);
    println!("Green's function G(1, 1) {:.4} m/N; energy at the fence {:.4} J; conjugate's slope past 6 N {:.4} m", (L - 1.0) / (T * L), f1(C, T, Some(C)), (fstar1(12.0, T, Some(C)) - fstar1(10.0, T, Some(C))) / 2.0);
    for top in [100.0, 1000.0] {
        let (r, _) = grid_max(&|f| 0.04 * f - fstar1(f, T, Some(C)), 0.0, top, 100000);
        println!("rebuilt at 4 cm (past the fence), loads up to {:.0} N: {:.4} J", top, r);
        assert!((r - (0.01 * top + 0.09)).abs() < 1e-9);
    }
    let (r, _) = grid_max(&|f| 0.02 * f - fstar1(f, T, Some(C)), -20.0, 20.0, 400000);
    println!("rebuilt at 2 cm: {:.6} J, direct {:.6} J", r, f1(0.02, T, None));
    assert!((r - f1(0.02, T, None)).abs() < 1e-9);
    let free: Vec<String> = (0..7).map(|i| format!("{:.2}", fstar1(2.0 * i as f64, T, None))).collect();
    let fen: Vec<String> = (0..7).map(|i| format!("{:.2}", fstar1(2.0 * i as f64, T, Some(C)))).collect();
    println!("chart F 0..12: {} | {}", free.join(" "), fen.join(" "));
    let hk = |u: f64| 100.0 * (u * u).min((u - 0.06).powi(2));
    let cj = |f: f64| grid_max(&|u| f * u - hk(u), -0.2, 0.26, 4600).0;
    let (bb, _) = grid_max(&|f| 0.03 * f - cj(f), -20.0, 20.0, 200);
    println!("two rest positions, at 3 cm: energy {:.4} J, rebuilt {:.4} J", hk(0.03), bb);
    assert!(bb.abs() < 1e-9);

    // ---- N points: the same line, finer and finer ----
    println!("N, h; tent: energy, rebuilt, slope size; step: energy, rebuilt; sine: energy, rebuilt, slope size");
    for n in [1usize, 3, 7, 15, 31, 63, 127] {
        let h = L / (n + 1) as f64; let xs: Vec<f64> = (0..n).map(|i| h * (i + 1) as f64).collect();
        let towel: Vec<f64> = (0..n).map(|i| if i == n / 2 { P } else { 0.0 }).collect();
        let tent = solve(n, &towel);
        assert!(xs.iter().enumerate().all(|(i, &x)| (tent[i] - P * x.min(L - x) / (T * L)).abs() < 1e-12));
        assert!((fstar(n, &towel) - 0.25).abs() < 1e-12 && (energy(n, &tent) + fstar(n, &towel) - dot(&towel, &tent)).abs() < 1e-12);
        let step: Vec<f64> = xs.iter().map(|&x| if (0.5..=1.5).contains(&x) { 0.05 } else { 0.0 }).collect();
        let sine: Vec<f64> = xs.iter().map(|&x| 0.05 * (PI * x / 2.0).sin()).collect();
        let mut row = vec![];
        for (u, exact) in [(&tent, 0.25), (&step, 0.25 / h), (&sine, 0.5 * T * 0.01 * (PI * h / 4.0).sin().powi(2) / (h * h))] {
            let (e, rb) = (energy(n, u), rebuild(n, u));
            assert!((e - exact).abs() < 1e-9 * exact && (rb - e).abs() < 1e-8 * e);
            row.push(e); row.push(rb);
        }
        let (st, ss) = (kslope(n, &tent), kslope(n, &sine));
        assert!((st - P / h.sqrt()).abs() < 1e-9 * st && (ss - 0.2 * T * (PI * h / 4.0).sin().powi(2) / (h * h)).abs() < 1e-9 * ss);
        println!("{:4} {:.4}  {:.6} {:.6} {:8.4}  {:.6} {:.6}  {:.6} {:.6} {:8.4}", n, h, row[0], row[1], st, row[2], row[3], row[4], row[5], ss);
    }
    let spread = vec![P / 7.0; 7]; let towel7: Vec<f64> = (0..7).map(|i| if i == 3 { P } else { 0.0 }).collect();
    let tent7 = solve(7, &towel7);
    println!("N=7: towel spread evenly is not a slope at the tent: gap {:.6} J", energy(7, &tent7) + fstar(7, &spread) - dot(&spread, &tent7));
    println!("limits: sine energy {:.6} J, sine slope size {:.4}; tent slope grows like 10/sqrt(h)", T * 0.05f64.powi(2) * PI * PI / 8.0, T * 0.05 * PI * PI / 4.0);
    for (t, p, c) in [(T, 16.0, C), (200.0, P, C), (T, P, 0.06)] {
        let (s, fs, sp, fe) = one_point(t, p, c);
        println!("try T={:.0} N, towel {:.0} N, fence {:.0} cm: sag {:.4} m, conjugate {:.4} J, spring {:.4} N, fence {:.4} N", t, p, 100.0 * c, s, fs, sp, fe);
    }
    println!("ALL CHECKS PASS");
}
