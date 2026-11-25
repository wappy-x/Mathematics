// Lax pairs and inverse scattering: KdV u_t - 6 u u_x + u_xxx = 0 from u(x, 0) = -6 sech^2 x (scaled).
// Roads: the Lax identity on exact integer polynomials; bound states by a Sturm count at t = 0 and on a
// KdV solve; the Gel'fand-Levitan-Marchenko (GLM) equation as a determinant and as a Simpson-rule
// linear system; the textbook two-soliton formula; conserved integrals against kappa. Units: scaled.
fn pmul(p: &[i64], q: &[i64]) -> Vec<i64> {
    let mut r = vec![0; p.len() + q.len() - 1];
    for (i, a) in p.iter().enumerate() { for (j, b) in q.iter().enumerate() { r[i + j] += a * b; } }
    r
}
fn pder(p: &[i64]) -> Vec<i64> { if p.len() < 2 { vec![0] } else { (1..p.len()).map(|i| i as i64 * p[i]).collect() } }
fn sc(c: i64, p: &[i64]) -> Vec<i64> { p.iter().map(|a| c * a).collect() }
fn padd(ps: &[Vec<i64>]) -> Vec<i64> {
    let n = ps.iter().map(|p| p.len()).max().unwrap();
    (0..n).map(|i| ps.iter().map(|p| if i < p.len() { p[i] } else { 0 }).sum()).collect()
}
fn op_l(u: &[i64], f: &[i64]) -> Vec<i64> { padd(&[sc(-1, &pder(&pder(f))), pmul(u, f)]) }
fn op_b(u: &[i64], f: &[i64], a: i64) -> Vec<i64> {
    padd(&[sc(-4, &pder(&pder(&pder(f)))), sc(a, &pmul(u, &pder(f))), sc(3, &pmul(&pder(u), f))])
}
fn lax_left(u: &[i64], f: &[i64], a: i64) -> Vec<i64> { // [B, L] f - (6 u u_x - u_xxx) f, exact
    let k = padd(&[sc(6, &pmul(u, &pder(u))), sc(-1, &pder(&pder(&pder(u))))]);
    padd(&[op_b(u, &op_l(u, f), a), sc(-1, &op_l(u, &op_b(u, f, a))), sc(-1, &pmul(&k, f))])
}
fn tau(x: f64, t: f64, s: f64) -> [f64; 3] { // det(I + A) from c1^2 = 6 e^{8t}, c2^2 = 12 e^{64t}
    let e = [(1.0, 0.0), (3.0 * (8.0 * s * t).exp(), -2.0), (3.0 * (64.0 * s * t).exp(), -4.0), ((72.0 * s * t).exp(), -6.0)];
    [0, 1, 2].map(|m| e.iter().map(|&(a, p): &(f64, f64)| a * p.powi(m) * (p * x).exp()).sum())
}
fn u_ist(x: f64, t: f64, s: f64) -> f64 { let [a, b, c] = tau(x, t, s); -2.0 * (c * a - b * b) / (a * a) }
fn u_book(x: f64, t: f64) -> f64 {
    -12.0 * (3.0 + 4.0 * (2.0 * x - 8.0 * t).cosh() + (4.0 * x - 64.0 * t).cosh())
        / ((x - 28.0 * t).cosh() * 3.0 + (3.0 * x - 36.0 * t).cosh()).powi(2)
}
fn gold(f: &dyn Fn(f64) -> f64, mut a: f64, mut b: f64) -> f64 { // golden-section search for a minimum
    let g = (5f64.sqrt() - 1.0) / 2.0;
    for _ in 0..90 { let (c, d) = (b - g * (b - a), a + g * (b - a)); if f(c) < f(d) { b = d } else { a = c } }
    (a + b) / 2.0
}
fn below(u: &[f64], h: f64, e: f64) -> usize { // Sturm count: eigenvalues of -D2 + u below e
    let (mut n, mut d) = (0, 1.0);
    for (j, &uj) in u.iter().enumerate() {
        d = 2.0 / (h * h) + uj - e - if j > 0 { (1.0 / h.powi(4)) / d } else { 0.0 }; if d < 0.0 { n += 1; }
    }
    n
}
fn eig(u: &[f64], h: f64, k: usize) -> f64 {
    let (mut lo, mut hi) = (-10.0, 0.0);
    for _ in 0..60 { let m = (lo + hi) / 2.0; if below(u, h, m) >= k { hi = m } else { lo = m } }
    (lo + hi) / 2.0
}
fn sech2(x: f64) -> f64 { 1.0 / x.cosh().powi(2) }
fn grid(h: f64) -> Vec<f64> { (0..(40.0 / h).round() as usize).map(|i| -20.0 + i as f64 * h).collect() }
fn wells(a: f64, h: f64) -> [f64; 2] { let u: Vec<f64> = grid(h).iter().map(|&x| -a * sech2(x)).collect(); [eig(&u, h, 1), eig(&u, h, 2)] }
fn kdv(h: f64, nl: f64) -> (Vec<f64>, Vec<f64>) { // periodic method of lines, RK4, dt = 0.83 h^3, to t = 0.5
    let xs = grid(h); let nn = xs.len(); let mut u: Vec<f64> = xs.iter().map(|&x| -6.0 * sech2(x)).collect();
    let n = 2 * (0.3 / h.powi(3)).round() as usize; let dt = 0.5 / n as f64;
    let f = |v: &Vec<f64>| -> Vec<f64> { (0..nn).map(|j| { let (p, p2, m, m2) = ((j + 1) % nn, (j + 2) % nn, (j + nn - 1) % nn, (j + nn - 2) % nn);
        nl * 6.0 * v[j] * (v[p] - v[m]) / (2.0 * h) - (v[p2] - 2.0 * v[p] + 2.0 * v[m] - v[m2]) / (2.0 * h.powi(3)) }).collect() };
    let add = |a: &Vec<f64>, b: &Vec<f64>, c: f64| -> Vec<f64> { a.iter().zip(b).map(|(x, y)| x + c * y).collect() };
    for _ in 0..n {
        let k1 = f(&u); let k2 = f(&add(&u, &k1, dt / 2.0)); let k3 = f(&add(&u, &k2, dt / 2.0)); let k4 = f(&add(&u, &k3, dt));
        u = (0..nn).map(|i| u[i] + dt / 6.0 * (k1[i] + 2.0 * k2[i] + 2.0 * k3[i] + k4[i])).collect();
    }
    (xs, u)
}
fn refl(a: f64, k: f64) -> f64 { // |R(k)| for u = -a sech^2 x, RK4 from x = 12 back to -12
    let (xx, n) = (12.0, 2400); let hh = 2.0 * xx / n as f64; let mut x = xx;
    let g = |x: f64, y: &[f64; 4]| { let v = -a * sech2(x) - k * k; [y[1], v * y[0], y[3], v * y[2]] };
    let st = |y: &[f64; 4], d: &[f64; 4], c: f64| [y[0] - c * d[0], y[1] - c * d[1], y[2] - c * d[2], y[3] - c * d[3]];
    let mut y = [(k * xx).cos(), -k * (k * xx).sin(), (k * xx).sin(), k * (k * xx).cos()];
    for _ in 0..n {
        let k1 = g(x, &y); let k2 = g(x - hh / 2.0, &st(&y, &k1, hh / 2.0));
        let k3 = g(x - hh / 2.0, &st(&y, &k2, hh / 2.0)); let k4 = g(x - hh, &st(&y, &k3, hh));
        for i in 0..4 { y[i] -= hh / 6.0 * (k1[i] + 2.0 * k2[i] + 2.0 * k3[i] + k4[i]); } x -= hh;
    }
    let [p, p1, q, q1] = y; (p - q1 / k).hypot(q + p1 / k) / (p + q1 / k).hypot(q - p1 / k)
}
fn refl_formula(a: f64, k: f64) -> f64 {
    let l = (-1.0 + (1.0 + 4.0 * a).sqrt()) / 2.0; let s = (std::f64::consts::PI * l).sin().powi(2);
    (s / ((std::f64::consts::PI * k).sinh().powi(2) + s)).sqrt()
}
fn glm(x: f64, t: f64, n: usize) -> f64 { // K(x, x) from the GLM equation, Simpson rule on [x, x + 20]
    let fnn = |s: f64| 6.0 * (8.0 * t - s).exp() + 12.0 * (64.0 * t - 2.0 * s).exp();
    let hh = 20.0 / n as f64; let ys: Vec<f64> = (0..=n).map(|i| x + i as f64 * hh).collect();
    let w: Vec<f64> = (0..=n).map(|i| hh / 3.0 * if i == 0 || i == n { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 }).collect();
    let mut m: Vec<Vec<f64>> = (0..=n).map(|i| { let mut r: Vec<f64> = (0..=n).map(|j| (if i == j { 1.0 } else { 0.0 }) + w[j] * fnn(ys[j] + ys[i])).collect(); r.push(-fnn(x + ys[i])); r }).collect();
    for c in 0..=n {
        let mut p = c; for r in c..=n { if m[r][c].abs() > m[p][c].abs() { p = r; } } m.swap(c, p);
        for r in c + 1..=n { let f = m[r][c] / m[c][c]; for j in c..n + 2 { let v = m[c][j]; m[r][j] -= f * v; } }
    }
    let mut s = vec![0.0; n + 1];
    for r in (0..=n).rev() { let mut acc = 0.0; for j in r + 1..=n { acc += m[r][j] * s[j]; } s[r] = (m[r][n + 1] - acc) / m[r][r]; }
    s[0]
}
fn u_glm(x: f64, t: f64, n: usize) -> f64 { -(glm(x + 1e-3, t, n) - glm(x - 1e-3, t, n)) / 1e-3 }
fn ints(u: &[f64], h: f64) -> [f64; 3] {
    let nn = u.len(); let mut r = [0.0; 3];
    for j in 0..nn { let ux = (u[(j + 1) % nn] - u[(j + nn - 1) % nn]) / (2.0 * h); r[0] += u[j]; r[1] += u[j] * u[j]; r[2] += u[j].powi(3) + ux * ux / 2.0; }
    [r[0] * h, r[1] * h, r[2] * h]
}
fn main() {
    let (uu, ff) = ([1, 2, -3, 0, 1], [2, -1, 4, 1]);
    let (good, bad) = (lax_left(&uu, &ff, 6), lax_left(&uu, &ff, 3)); let bad1: i64 = bad.iter().sum();
    println!("Lax identity, B = -4 d3 + 6u d + 3u_x: {} nonzero coefficients left", good.iter().filter(|&&c| c != 0).count());
    println!("  with 3u d in B instead: leftover at x = 1 is {}, not 0", bad1);
    assert!(good.iter().all(|&c| c == 0) && bad1 != 0);
    let hs = [0.1, 0.05]; let e: Vec<[f64; 2]> = hs.iter().map(|&h| wells(6.0, h)).collect();
    println!("bound states of L = -d2/dx2 + u at t = 0, grid on [-20, 20]:");
    for (i, &h) in hs.iter().enumerate() {
        let u: Vec<f64> = grid(h).iter().map(|&x| -6.0 * sech2(x)).collect();
        println!("  h = {:.2}: {} below zero, E = {:.6}, {:.6}", h, below(&u, h, 0.0), e[i][0], e[i][1]);
    }
    let kap: Vec<f64> = (0..2).map(|k| (-(4.0 * e[1][k] - e[0][k]) / 3.0).sqrt()).collect();
    println!("  extrapolated: kappa = {:.5}, {:.5}; depths 2 kappa^2 = {:.4}, {:.4}; speeds 4 kappa^2 = {:.4}, {:.4}", kap[0], kap[1], 2.0 * kap[0].powi(2), 2.0 * kap[1].powi(2), 4.0 * kap[0].powi(2), 4.0 * kap[1].powi(2));
    assert!((kap[0] - 2.0).abs() < 1e-4 && (kap[1] - 1.0).abs() < 1e-4);
    let psis: [(f64, fn(f64) -> f64); 2] = [(2.0, |x| sech2(x)), (1.0, |x| x.sinh() / x.cosh().powi(2))]; let mut c2 = vec![];
    for (k, psi) in psis {
        let r = [-1.3, 0.4, 2.2].iter().map(|&x| (-(psi(x + 1e-3) - 2.0 * psi(x) + psi(x - 1e-3)) / 1e-6 - 6.0 * sech2(x) * psi(x) + k * k * psi(x)).abs()).fold(0.0, f64::max);
        let norm: f64 = (0..4001).map(|i| psi(-20.0 + i as f64 * 0.01).powi(2)).sum::<f64>() * 0.01;
        c2.push(psi(10.0).powi(2) * (2.0 * k * 10.0).exp() / norm); assert!(r < 1e-4);
    }
    println!("norming constants c^2 at t = 0: {:.6} (kappa = 2), {:.6} (kappa = 1)", c2[0], c2[1]);
    assert!((c2[0] - 12.0).abs() < 1e-6 && (c2[1] - 6.0).abs() < 1e-6);
    for a in [6.0, 5.0] {
        let r = [refl(a, 0.5), refl(a, 1.0)];
        println!("u = -{} sech^2 x: |R| at k = 0.5, 1 by RK4 {:.6}, {:.6}; formula {:.6}, {:.6}", a, r[0], r[1], refl_formula(a, 0.5), refl_formula(a, 1.0));
        assert!((r[1] - refl_formula(a, 1.0)).abs() < 1e-6);
    }
    let xd = gold(&|x| u_ist(x, 0.5, 1.0), 6.0, 11.0); let xs_ = gold(&|x| u_ist(x, 0.5, 1.0), -1.0, 4.0);
    let g = [u_glm(0.0, 0.0, 200), u_glm(0.0, 0.0, 400), u_glm(xd, 0.5, 400)];
    println!("GLM as a linear system: u(0, 0) = {:.6} (n = 200), {:.6} (n = 400), order {:.2}; u({:.4}, 0.5) = {:.6}", g[0], g[1], ((g[0] + 6.0) / (g[1] + 6.0)).log2(), xd, g[2]);
    println!("  GLM determinant: u(0, 0) = {:.6}, u({:.4}, 0.5) = {:.6}", u_ist(0.0, 0.0, 1.0), xd, u_ist(xd, 0.5, 1.0));
    assert!((g[1] + 6.0).abs() < 1e-3 && (g[2] - u_ist(xd, 0.5, 1.0)).abs() < 1e-3);
    let mut dev: f64 = 0.0;
    for x in -100..=200 { for t in [0.0, 0.25, 0.5] { dev = dev.max((u_ist(x as f64 / 10.0, t, 1.0) - u_book(x as f64 / 10.0, t)).abs()); } }
    assert!(dev < 1e-12); println!("  determinant against the textbook two-soliton formula: max gap under 1e-12");
    println!("scattering data in time:  t   ln c1^2   ln c2^2   deep dip   shallow dip");
    for t in [0.0, 0.25, 0.5] {
        let a = gold(&|x| u_ist(x, t, 1.0), 16.0 * t - 2.0, 16.0 * t + 2.0); let b = gold(&|x| u_ist(x, t, 1.0), -1.0, 4.0);
        println!("  {:.2}  {:.4}  {:.4}  x = {:.4}, u = {:.4}  x = {:.4}, u = {:.4}", t, 6f64.ln() + 8.0 * t, 12f64.ln() + 64.0 * t, (a * 1e4).round() / 1e4 + 0.0, u_ist(a, t, 1.0), (b * 1e4).round() / 1e4 + 0.0, u_ist(b, t, 1.0));
    }
    let runs: Vec<(Vec<f64>, Vec<f64>)> = hs.iter().map(|&h| kdv(h, 1.0)).collect();
    let err: Vec<f64> = runs.iter().map(|(xs, u)| xs.iter().zip(u).map(|(&x, &a)| (a - u_ist(x, 0.5, 1.0)).abs()).fold(0.0, f64::max)).collect();
    let rich = (0..runs[0].0.len()).map(|i| ((4.0 * runs[1].1[2 * i] - runs[0].1[i]) / 3.0 - u_ist(runs[1].0[2 * i], 0.5, 1.0)).abs()).fold(0.0, f64::max);
    println!("KdV solve to t = 0.5, max error: h = 0.1 {:.4}, h = 0.05 {:.4}, order {:.2}; extrapolated {:.4}", err[0], err[1], (err[0] / err[1]).log2(), rich);
    assert!(err[1] < 0.3 && rich < 0.05);
    for (i, &h) in hs.iter().enumerate() {
        let ee = [eig(&runs[i].1, h, 1), eig(&runs[i].1, h, 2)];
        println!("  bound states on the solve, h = {:.2}, t = 0.5: E = {:.6}, {:.6}; drift from t = 0: {:.6}, {:.6}", h, ee[0], ee[1], ee[0] - e[i][0], ee[1] - e[i][1]);
        assert!((ee[0] - e[i][0]).abs() < 0.05 * h / 0.1 && (ee[1] - e[i][1]).abs() < 0.05 * h / 0.1);
    }
    let i0 = ints(&grid(0.05).iter().map(|&x| -6.0 * sech2(x)).collect::<Vec<f64>>(), 0.05); let i5 = ints(&runs[1].1, 0.05);
    let kk = [-4.0 * (kap[0] + kap[1]), 16.0 / 3.0 * (kap[0].powi(3) + kap[1].powi(3)), -32.0 / 5.0 * (kap[0].powi(5) + kap[1].powi(5))];
    for (i, name) in ["int u", "int u^2", "int u^3 + u_x^2/2"].iter().enumerate() {
        println!("conserved {}: grid t = 0 {:.4}, solve t = 0.5 {:.4}, from kappa {:.3}", name, i0[i], i5[i], kk[i]); assert!((i5[i] - kk[i]).abs() < 0.01 * kk[i].abs());
    }
    let lin = kdv(0.1, 0.0).1.iter().cloned().fold(f64::MAX, f64::min); let (w5, w5b) = (wells(5.0, 0.05), wells(5.0, 0.1));
    let k5: Vec<f64> = (0..2).map(|k| (-(4.0 * w5[k] - w5b[k]) / 3.0).sqrt()).collect(); let l5 = (-1.0 + 21f64.sqrt()) / 2.0;
    println!("what breaks: two separate solitons added, at x = 0, t = 0: {:.4}, not -6", -8.0 * sech2(0.0) - 2.0);
    println!("  c_n run backwards: deep dip at x = {:.4}; no 6 u u_x term: deepest u {:.4} at t = 0.5", gold(&|x| u_ist(x, 0.5, -1.0), -11.0, -6.0), lin);
    println!("  start -5 sech^2 x: kappa = {:.5}, {:.5} (exact {:.5}, {:.5}); depths {:.4}, {:.4}", k5[0], k5[1], l5, l5 - 1.0, 2.0 * k5[0].powi(2), 2.0 * k5[1].powi(2));
    assert!((k5[0] - l5).abs() < 1e-4 && (k5[1] - l5 + 1.0).abs() < 1e-4);
    let (h0, lu) = (1.0f64, 10.0f64); let c0 = (9.81 * h0).sqrt(); let (tt, hu) = (6.0 * lu.powi(3) / (c0 * h0 * h0), 2000.0 * h0.powi(3) / (3.0 * lu * lu)); // make KdV's coefficients 1, -6
    println!("canal {:.0} m deep, length unit {:.0} m: c0 = {:.4} m/s, time unit T = 6 (10 m)^3 / (c0 h0^2) = {:.2} s, height unit H = 2 h0^3 / (3 (10 m)^2) = {:.4} mm", h0, lu, c0, tt, hu);
    println!("  start {:.2} mm; solitons {:.2} mm, {:.2} mm, extra speeds {:.4}, {:.4} m/s (c0 a / 2h0 for height a: {:.4}); t = 0.5 is {:.1} s", 6.0 * hu, 8.0 * hu, 2.0 * hu, 16.0 * lu / tt, 4.0 * lu / tt, c0 * 8.0 * hu / 2000.0 / h0, tt / 2.0);
    assert!((16.0 * lu / tt - c0 * 8.0 * hu / 2000.0 / h0).abs() < 1e-12 && (4.0 * lu / tt - c0 * 2.0 * hu / 2000.0 / h0).abs() < 1e-12); // Dispersion's solitary-wave speed
    println!("  at t = 0.5 the marker has moved {:.1} m; humps {:.2} m and {:.2} m ahead of it, gap {:.2} m", c0 * tt / 2.0, 10.0 * xd, 10.0 * xs_, 10.0 * (xd - xs_));
    println!("chart: water height in mm at 2.5 m steps from -20 m to 100 m, t = 0, 0.25, 0.5:");
    for t in [0.0, 0.25, 0.5] { println!("  {}", (0..49).map(|i| format!("{:.1}", -u_ist(-2.0 + i as f64 / 4.0, t, 1.0) * hu)).collect::<Vec<_>>().join(", ")); }
    println!("ALL CHECKS PASS");
}
