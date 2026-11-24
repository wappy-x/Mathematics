// Implicit Runge-Kutta: the check behind the card.  Rust std only.  A valve servo pulls y towards the
// target cos t at 1000 per s (illustrative): y' = -1000(y - cos t) - sin t, y(0) = 1, exact y = cos t.
// Two-stage Gauss and Radau IIA built by collocation; R(z); stages by simplified Newton; SDIRK for cost.
#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
fn c(re: f64, im: f64) -> C { C { re, im } }
fn add(a: C, b: C) -> C { c(a.re + b.re, a.im + b.im) }
fn sub(a: C, b: C) -> C { c(a.re - b.re, a.im - b.im) }
fn mul(a: C, b: C) -> C { c(a.re * b.re - a.im * b.im, a.re * b.im + a.im * b.re) }
fn div(a: C, b: C) -> C { let d = b.re * b.re + b.im * b.im; c((a.re * b.re + a.im * b.im) / d, (a.im * b.re - a.re * b.im) / d) }
fn sc(a: C, s: f64) -> C { c(a.re * s, a.im * s) }
fn abs(a: C) -> f64 { (a.re * a.re + a.im * a.im).sqrt() }
fn sci(v: f64, d: usize) -> String { format!("{:.*e}", d, v) }
fn f6(v: f64) -> String { format!("{:.6}", if v.abs() >= 5e-7 { v } else { 0.0 }) }
type Tab = ([[f64; 2]; 2], [f64; 2], [f64; 2]);
fn quad_roots(a: f64, b: f64, cc: f64) -> [f64; 2] { let d = (b * b - 4.0 * a * cc).sqrt(); [(-b - d) / (2.0 * a), (-b + d) / (2.0 * a)] }
fn colloc(cn: [f64; 2]) -> Tab {                  // a_ij = integral of l_j from 0 to c_i; b_j = from 0 to 1
    let mut l: Vec<Vec<f64>> = vec![];
    for j in 0..2 {                                // Lagrange basis l_j, coefficients lowest power first
        let mut p = vec![1.0];
        for k in 0..2 { if k != j {
            let mut q = vec![0.0; p.len() + 1];
            for (i, v) in p.iter().enumerate() { q[i] -= cn[k] * v / (cn[j] - cn[k]); q[i + 1] += v / (cn[j] - cn[k]); }
            p = q;
        } }
        l.push(p);
    }
    let integ = |p: &Vec<f64>, x: f64| p.iter().enumerate().map(|(i, v)| v * x.powi(i as i32 + 1) / (i as f64 + 1.0)).sum::<f64>();
    let mut a = [[0.0; 2]; 2];
    for i in 0..2 { for j in 0..2 { a[i][j] = integ(&l[j], cn[i]); } }
    (a, [integ(&l[0], 1.0), integ(&l[1], 1.0)], cn)
}
fn orders(t: &Tab) -> (usize, usize) {             // p: sum b c^(k-1) = 1/k for k <= p; q: the same for each row
    let (a, b, cn) = t;
    let p = (1..9).find(|&k| ((0..2).map(|i| b[i] * cn[i].powi(k - 1)).sum::<f64>() - 1.0 / k as f64).abs() > 1e-13).unwrap() - 1;
    let q = (1..9).find(|&k| (0..2).map(|i| ((0..2).map(|j| a[i][j] * cn[j].powi(k - 1)).sum::<f64>() - cn[i].powi(k) / k as f64).abs()).fold(0.0, f64::max) > 1e-13).unwrap() - 1;
    (p as usize, q as usize)
}
fn rz(t: &Tab, z: C) -> C {                        // 1 + z b^T (I - zA)^-1 (1, 1), by Cramer's rule
    let (a, b, _) = t; let one = c(1.0, 0.0);
    let (m11, m12, m21, m22) = (sub(one, sc(z, a[0][0])), sc(z, -a[0][1]), sc(z, -a[1][0]), sub(one, sc(z, a[1][1])));
    let d = sub(mul(m11, m22), mul(m12, m21));
    add(one, div(mul(z, add(sc(sub(m22, m12), b[0]), sc(sub(m11, m21), b[1]))), d))
}
fn r(t: &Tab, z: f64) -> f64 { rz(t, c(z, 0.0)).re }
fn pade_g(z: C) -> C { let q = sc(mul(z, z), 1.0 / 12.0); div(add(add(c(1.0, 0.0), sc(z, 0.5)), q), add(sub(c(1.0, 0.0), sc(z, 0.5)), q)) }
fn pade_r(z: C) -> C { div(add(c(1.0, 0.0), sc(z, 1.0 / 3.0)), add(sub(c(1.0, 0.0), sc(z, 2.0 / 3.0)), sc(mul(z, z), 1.0 / 6.0))) }
fn step(t: &Tab, f: &dyn Fn(f64, f64) -> f64, jf: &dyn Fn(f64, f64) -> f64, t0: f64, y: f64, h: f64, full: bool) -> (f64, usize) {
    let (a, b, cn) = t; let (mut z, mut its) = ([0.0f64; 2], 0);
    loop {                                         // Z_i = h sum_j a_ij f(t + c_j h, y + Z_j), Newton on Z
        its += 1;
        let ff = [f(t0 + cn[0] * h, y + z[0]), f(t0 + cn[1] * h, y + z[1])];
        let rr = [z[0] - h * (a[0][0] * ff[0] + a[0][1] * ff[1]), z[1] - h * (a[1][0] * ff[0] + a[1][1] * ff[1])];
        let j = if full { [jf(t0 + cn[0] * h, y + z[0]), jf(t0 + cn[1] * h, y + z[1])] } else { [jf(t0, y); 2] };
        let (m11, m12, m21, m22) = (1.0 - h * a[0][0] * j[0], -h * a[0][1] * j[1], -h * a[1][0] * j[0], 1.0 - h * a[1][1] * j[1]);
        let d = m11 * m22 - m12 * m21; let (d0, d1) = ((m12 * rr[1] - m22 * rr[0]) / d, (m21 * rr[0] - m11 * rr[1]) / d);
        z = [z[0] + d0, z[1] + d1];
        if d0.abs().max(d1.abs()) < 1e-13 { break; }
    }
    if *b == a[1] { return (y + z[1], its); }     // stiffly accurate (Radau IIA, SDIRK): y_(n+1) is the last stage
    let ff = [f(t0 + cn[0] * h, y + z[0]), f(t0 + cn[1] * h, y + z[1])];
    (y + h * (b[0] * ff[0] + b[1] * ff[1]), its)
}
fn run(t: &Tab, lam: f64, h: f64, nonlin: bool, full: bool, tend: f64, jolt: bool) -> (f64, usize) {
    let f: Box<dyn Fn(f64, f64) -> f64> = if nonlin { Box::new(|t: f64, y: f64| -500.0 * (y * y - t.cos().powi(2)) - t.sin()) }
        else if jolt { Box::new(move |_t: f64, y: f64| lam * y) }      // the fast part alone: y' = lam y
        else { Box::new(move |t: f64, y: f64| lam * (y - t.cos()) - t.sin()) };
    let jf: Box<dyn Fn(f64, f64) -> f64> = if nonlin { Box::new(|_t: f64, y: f64| -1000.0 * y) } else { Box::new(move |_t: f64, _y: f64| lam) };
    let (n, mut y, mut its) = ((tend / h).round() as usize, 1.0, 0);
    for i in 0..n { let (yn, k) = step(t, &*f, &*jf, i as f64 * h, y, h, full); y = yn; its += k; }
    (y - if jolt { 0.0 } else { (n as f64 * h).cos() }, its)
}
fn main() {
    let (cg, cr) = (quad_roots(6.0, -6.0, 1.0), quad_roots(6.0, -8.0, 2.0));   // shifted Legendre; Radau 2(3x - 1)(x - 1)
    let g = 1.0 - 2f64.sqrt() / 2.0;               // SDIRK: L-stable, order 2, both diagonal entries g
    let m: Vec<(&str, Tab)> = vec![("Gauss", colloc(cg)), ("Radau IIA", colloc(cr)), ("SDIRK", ([[g, 0.0], [1.0 - g, g]], [1.0 - g, g], [g, 1.0]))];
    let (tg, tr) = (m[0].1, m[1].1);
    println!("tableaux by collocation:");
    for (k, (a, b, cn)) in &m[..2] {
        println!("  {}: c = {:.6}, {:.6}; A = [[{}, {}], [{}, {}]]; b = {:.6}, {:.6}", k, cn[0], cn[1], f6(a[0][0]), f6(a[0][1]), f6(a[1][0]), f6(a[1][1]), b[0], b[1]);
    }
    assert!((tg.0[0][1] - (0.25 - 3f64.sqrt() / 6.0)).abs() < 1e-15 && (tr.0[0][0] - 5.0 / 12.0).abs() < 1e-15, "against the closed forms");
    assert!((tr.0[0][1] + 1.0 / 12.0).abs() < 1e-15 && (tr.0[1][0] - 0.75).abs() < 1e-15 && (tr.1[0] - 0.75).abs() < 1e-15);
    println!("method: order p, stage order q, R(-100), R(-1e8), |R(10i)|, largest |R| on a left half-plane grid");
    let mut info = vec![];
    for (k, t) in &m {
        let (p, q) = orders(t);
        let mut lh: f64 = 0.0;
        for x in 1..200 { for y in -400..401 { lh = lh.max(abs(rz(t, c(-((x * x) as f64) / 50.0, y as f64 / 5.0)))); } }
        println!("  {}: p = {}, q = {}, {:.6}, {}, {:.6}, {:.6}", k, p, q, r(t, -100.0), sci(r(t, -1e8), 3), abs(rz(t, c(0.0, 10.0))), lh);
        info.push((p, q, lh));
    }
    let r4 = 1.0 - 100.0 + 100f64.powi(2) / 2.0 - 100f64.powi(3) / 6.0 + 100f64.powi(4) / 24.0;   // explicit RK4 at z = -100
    println!("  RK4 (explicit), for comparison: R(-100) = {}, after 10 steps {}", sci(r4, 3), sci(r4.powi(10), 3));
    let k1 = -100.0f64; let k2 = -100.0 * (1.0 + k1 / 2.0); let k3 = -100.0 * (1.0 + k2 / 2.0); let k4 = -100.0 * (1.0 + k3);   // RK4's stages on y' = lambda y from y = 1
    assert!(((1.0 + (k1 + 2.0 * k2 + 2.0 * k3 + k4) / 6.0) / r4 - 1.0).abs() < 1e-12, "RK4 two ways: its stages against the Taylor polynomial");
    assert!((r(&tg, -100.0) - 2353.0 / 2653.0).abs() < 1e-14 && (r(&tr, -100.0) + 97.0 / 5203.0).abs() < 1e-15);
    assert!(info.iter().map(|x| (x.0, x.1)).collect::<Vec<_>>() == vec![(4, 2), (3, 2), (2, 1)], "orders 2s and 2s - 1 from collocation");
    assert!(info.iter().all(|x| x.2 < 1.0), "A-stable: no grid point with |R| above 1");
    for z in [c(-100.0, 0.0), c(-0.7, 0.0), c(-3.0, 40.0), c(0.0, 2.5)] {
        assert!(abs(sub(rz(&tg, z), pade_g(z))) < 1e-13 && abs(sub(rz(&tr, z), pade_r(z))) < 1e-13, "R two ways");
    }
    assert!((abs(rz(&tg, c(0.0, 7.0))) - 1.0).abs() < 1e-14 && r(&tr, -1e8).abs() < 1e-7 && 1e-7 < 1.0 - r(&tg, -1e8) && 1.0 - r(&tg, -1e8) < 1e-6);
    println!("algebraic stability matrix BA + A^T B - b b^T and its smallest eigenvalue:");
    let mut los = vec![];
    for (k, (a, b, _)) in &m {
        let mut mm = [[0.0; 2]; 2];
        for i in 0..2 { for j in 0..2 { mm[i][j] = b[i] * a[i][j] + b[j] * a[j][i] - b[i] * b[j]; } }
        let lo = (mm[0][0] + mm[1][1]) / 2.0 - (((mm[0][0] - mm[1][1]) / 2.0).powi(2) + mm[0][1].powi(2)).sqrt();
        println!("  {}: [[{}, {}], [{}, {}]], {}", k, f6(mm[0][0]), f6(mm[0][1]), f6(mm[1][0]), f6(mm[1][1]), f6(lo));
        los.push(lo);
    }
    assert!(los[0].abs() < 1e-15 && los[1] > -1e-15 && los[2] < -0.08);
    println!("the example, h = 0.1 to t = 1 (z = -100): error at t = 1; what is left of a jolt of 1.0 at t = 0");
    for (k, t) in &m {
        let (e, gap1, gap) = (run(t, -1000.0, 0.1, false, false, 1.0, false).0, run(t, -1000.0, 0.1, false, false, 0.1, true).0, run(t, -1000.0, 0.1, false, false, 1.0, true).0);
        println!("  {}: error {}; jolt after 1 step {:.6}, after 10 steps {}", k, sci(e, 3), gap1, sci(gap, 3));
        assert!((gap1 - r(t, -100.0)).abs() < 1e-13 && (gap / r(t, -100.0).powi(10) - 1.0).abs() < 1e-10, "R(z)^n");
    }
    let hs = [0.2, 0.1, 0.05, 0.025, 0.0125];
    let mut o = std::collections::HashMap::new();
    for lam in [-1.0, -1000.0, -1e6] {
        println!("errors at t = 1 for h = 0.2 down to 0.0125, lambda = {}; observed orders", sci(lam, 0));
        for (i, (k, t)) in m.iter().enumerate() {
            let e: Vec<f64> = hs.iter().map(|&h| run(t, lam, h, false, false, 1.0, false).0.abs()).collect();
            let od: Vec<f64> = (0..4).map(|i| (e[i] / e[i + 1]).log10() / 2f64.log10()).collect();
            println!("  {}: {}; {}", k, e.iter().map(|&x| sci(x, 3)).collect::<Vec<_>>().join(", "), od.iter().map(|x| format!("{:.2}", x)).collect::<Vec<_>>().join(", "));
            o.insert((i, lam as i64), (e, od));
        }
    }
    println!("chart, log10 h: {}", hs.iter().map(|h| format!("{:.2}", h.log10())).collect::<Vec<_>>().join(", "));
    for i in 0..2 { println!("chart, log10 error, {}, lambda = -1000: {}", m[i].0, o[&(i, -1000)].0.iter().map(|e| format!("{:.2}", e.log10())).collect::<Vec<_>>().join(", ")); }
    for (i, p, q) in [(0, 4.0, 2.0), (1, 3.0, 2.0), (2, 2.0, 1.0)] {
        assert!((o[&(i, -1)].1[3] - p).abs() < 0.1 && (o[&(i, -1000000)].1[2] - q).abs() < 0.1, "order p when gentle, q when stiff");
    }
    assert!(o[&(0, -1000)].1[0] < 2.6 && o[&(0, -1000)].1[3] > 3.8, "Gauss recovers once |z| is small");
    let ((es, is), (ef, i_f)) = (run(&tr, 0.0, 0.1, true, false, 1.0, false), run(&tr, 0.0, 0.1, true, true, 1.0, false));
    println!("nonlinear pull y' = -500(y^2 - cos^2 t) - sin t, Radau IIA, h = 0.1, 10 steps:");
    println!("  simplified Newton {} iterations, error {}; full Newton {} iterations, error {}", is, sci(es, 3), i_f, sci(ef, 3));
    assert!((es - ef).abs() < 1e-10 && 1e-7 < es.abs() && es.abs() < 1e-5 && i_f < is, "same answer, more but cheaper iterations");
    for n in [100.0f64, 1000.0] {
        let (lu, bs) = (2.0 * (2.0 * n).powi(3) / 3.0, 2.0 * (2.0 * n).powi(2));
        println!("n = {}: one LU, Radau IIA (size {}) {}, SDIRK (size {}) {} flops; 10 Radau steps: simplified {}, full {}", n, 2.0 * n, sci(lu, 3), n, sci(2.0 * n.powi(3) / 3.0, 3), sci(10.0 * lu + is as f64 * bs, 3), sci(i_f as f64 * (lu + bs), 3));
    }
    for (k, t) in &m[..2] {                        // eigenvalues of A^-1 = the poles of R(z)
        let a = t.0; let d = a[0][0] * a[1][1] - a[0][1] * a[1][0]; let (tr_, dt) = ((a[0][0] + a[1][1]) / d, 1.0 / d);
        let (re, im) = (tr_ / 2.0, (dt - tr_ * tr_ / 4.0).sqrt());
        println!("eigenvalues of A^-1, {}: {:.6} +/- {:.6}i", k, re, im);
        assert!(abs(div(c(1.0, 0.0), rz(t, c(re, im)))) < 1e-12, "a pole of R in the right half-plane");
    }
    println!("ALL CHECKS PASS");
}
