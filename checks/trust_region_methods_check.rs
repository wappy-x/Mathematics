// Trust regions -- the same check as the Python, in Rust.  No crates.
// Rosenbrock's banana valley, f(x, y) = (1 - x)^2 + 100 (y - x^2)^2, is
// minimised from (-1.2, 1) by a trust region: a quadratic model, the dogleg
// step inside a radius, the ratio test, and the radius resized by the ratio.
type V = (f64, f64);
type M = (f64, f64, f64); // [[a, b], [b, c]]
fn f(x: f64, y: f64) -> f64 { (1.0 - x).powi(2) + 100.0 * (y - x * x).powi(2) }
fn grad(x: f64, y: f64) -> V { (-2.0 * (1.0 - x) - 400.0 * x * (y - x * x), 200.0 * (y - x * x)) }
fn hess(x: f64, y: f64) -> M { (2.0 - 400.0 * (y - x * x) + 800.0 * x * x, -400.0 * x, 200.0) }
fn len(d: V) -> f64 { d.0.hypot(d.1) }
fn promise(g: V, b: M, d: V) -> f64 { // m(0) - m(d): the fall the model promises
    -(g.0 * d.0 + g.1 * d.1 + 0.5 * (b.0 * d.0 * d.0 + 2.0 * b.1 * d.0 * d.1 + b.2 * d.1 * d.1))
}
fn solve(b: M, g: V, lam: f64) -> V { // (B + lam I) d = -g, two equations by elimination
    let (a, bb, c) = (b.0 + lam, b.1, b.2 + lam);
    let det = a * c - bb * bb;
    (-(c * g.0 - bb * g.1) / det, -(a * g.1 - bb * g.0) / det)
}
fn cauchy(g: V, b: M, r: f64) -> V { // best point straight downhill, inside radius r
    let (gn, gbg) = (len(g), b.0 * g.0 * g.0 + 2.0 * b.1 * g.0 * g.1 + b.2 * g.1 * g.1);
    let t = if gbg <= 0.0 { r / gn } else { (gn * gn / gbg).min(r / gn) };
    (-t * g.0, -t * g.1)
}
fn dogleg(g: V, b: M, r: f64) -> V {
    if b.0 <= 0.0 || b.0 * b.2 - b.1 * b.1 <= 0.0 { return cauchy(g, b, r); } // no bowl
    let dn = solve(b, g, 0.0);
    if len(dn) <= r { return dn; }                         // Newton point fits
    let du = cauchy(g, b, f64::INFINITY);                  // downhill to the turn
    if len(du) >= r { return cauchy(g, b, r); }
    let e = (dn.0 - du.0, dn.1 - du.1);                    // leg two: turn to Newton
    let (qa, qb, qc) = (e.0 * e.0 + e.1 * e.1, 2.0 * (du.0 * e.0 + du.1 * e.1), du.0 * du.0 + du.1 * du.1 - r * r);
    let t = (-qb + (qb * qb - 4.0 * qa * qc).sqrt()) / (2.0 * qa); // where leg two leaves the circle
    (du.0 + t * e.0, du.1 + t * e.1)
}
fn try_step(x: f64, y: f64, r: f64) -> (V, f64, f64, f64) {
    let (g, b) = (grad(x, y), hess(x, y));
    let d = dogleg(g, b, r);
    let (pred, act) = (promise(g, b, d), f(x, y) - f(x + d.0, y + d.1));
    (d, pred, act, act / pred)
}
// one row per try: k, x, y, f, radius, step length, promised, delivered, rho, accepted
type Row = (usize, f64, f64, f64, f64, f64, f64, f64, f64, bool);
fn run(mut x: f64, mut y: f64, mut r: f64, eta: f64, shrink: f64, grow: f64, kmax: usize) -> (f64, f64, Vec<Row>) {
    let mut tr = Vec::new();
    for k in 0..kmax {
        if len(grad(x, y)) < 1e-8 { break; }               // stopping test
        let (d, pred, act, rho) = try_step(x, y, r);
        let ok = rho > eta;
        tr.push((k, x, y, f(x, y), r, len(d), pred, act, rho, ok));
        if ok { x += d.0; y += d.1; }
        if rho < 0.25 { r *= shrink; } else if rho > 0.75 && (len(d) - r).abs() < 1e-12 { r = (grow * r).min(10.0); }
    }
    (x, y, tr)
}
fn join(v: &[f64], p: usize) -> String { v.iter().map(|q| format!("{:.*}", p, q)).collect::<Vec<_>>().join(", ") }
fn main() {
    // ---- road 1: derivatives against central differences ----
    let s0 = solve(hess(-1.2, 1.0), grad(-1.2, 1.0), 0.0);
    let (x1, y1) = (-1.2 + s0.0, 1.0 + s0.1);
    let (h, g1, b1) = (1e-5, grad(x1, y1), hess(x1, y1));
    let fd = ((f(x1 + h, y1) - f(x1 - h, y1)) / (2.0 * h), (f(x1, y1 + h) - f(x1, y1 - h)) / (2.0 * h));
    let fdb = ((grad(x1 + h, y1).0 - grad(x1 - h, y1).0) / (2.0 * h), (grad(x1, y1 + h).0 - grad(x1, y1 - h).0) / (2.0 * h));
    assert!((fd.0 - g1.0).abs().max((fd.1 - g1.1).abs()) < 1e-6 && (fdb.0 - b1.0).abs() < 1e-4 && (fdb.1 - b1.1).abs() < 1e-4);
    println!("start (-1.2, 1): f = {:.4}; step 0 is the Newton point, to ({:.6}, {:.6}), f = {:.6}", f(-1.2, 1.0), x1, y1, f(x1, y1));
    println!("at x1: gradient ({:.6}, {:.6}), Hessian a, b, c = {:.4}, {:.4}, {:.4}", g1.0, g1.1, b1.0, b1.1, b1.2);
    // ---- the overpromise at x1, and the subproblem solved three ways ----
    let (dn, du) = (solve(b1, g1, 0.0), cauchy(g1, b1, f64::INFINITY));
    println!("Newton point ({:.6}, {:.6}), length {:.6}; downhill turn at length {:.6}", dn.0, dn.1, len(dn), len(du));
    println!("radius    step x    step y   promised  delivered       rho");
    for r in [len(dn), 1.0, 0.5, 0.25, 0.125] {
        let (d, pred, act, rho) = try_step(x1, y1, r);
        println!("{:6.4} {:9.6} {:9.6} {:10.6} {:10.6} {:9.4}", r, d.0, d.1, pred, act, rho);
    }
    let falls: Vec<(f64, f64)> = (1..=10).map(|i| { let t = try_step(x1, y1, 0.1 * i as f64); (t.1, t.2) }).collect();
    println!("chart, radius 0.1 to 1.0 by 0.1, promised: {}", join(&falls.iter().map(|p| p.0).collect::<Vec<_>>(), 4));
    println!("chart, radius 0.1 to 1.0 by 0.1, delivered: {}", join(&falls.iter().map(|p| p.1).collect::<Vec<_>>(), 4));
    for r in [1.0, 0.25] {
        let (mut lo, mut hi) = (0.0, 1e6);                 // road 2: exact step, bisection on the damping
        for _ in 0..200 {
            let mid = (lo + hi) / 2.0;
            if len(solve(b1, g1, mid)) > r { lo = mid; } else { hi = mid; }
        }
        let exact = promise(g1, b1, solve(b1, g1, hi));
        let mut scan = f64::NEG_INFINITY;
        for i in 0..100000 {
            let th = 2.0 * std::f64::consts::PI * i as f64 / 100000.0;
            scan = scan.max(promise(g1, b1, (r * th.cos(), r * th.sin())));
        }
        let (dog, cau) = (promise(g1, b1, dogleg(g1, b1, r)), promise(g1, b1, cauchy(g1, b1, r)));
        println!("radius {:.2}: promised fall, Cauchy {:.6} <= dogleg {:.6} <= exact {:.6} (circle scan {:.6}), dogleg/exact {:.4}", r, cau, dog, exact, scan, dog / exact);
        assert!((exact - scan).abs() < 1e-6 && cau <= dog && dog <= exact + 1e-12 && dog >= 0.9 * exact);
    }
    let (d, pred, act, rho) = try_step(x1, y1, 1.0);       // road 3: the exact leftover terms
    let (u, v) = (d.0, d.1);                               // f is quartic, so the model misses by
    let left = 100.0 * u.powi(4) - 200.0 * u * u * (v - 2.0 * x1 * u); // exactly this much
    println!("radius 1: v - 2xu = {:.6}, leftover quartic terms {:.6}; promised - leftover = {:.6}, delivered {:.6}", v - 2.0 * x1 * u, left, pred - left, act);
    let rhos: Vec<f64> = [0.1, 0.01, 0.001].iter().map(|&r| try_step(x1, y1, r).3).collect();
    println!("rho at radius 0.1, 0.01, 0.001: {}", join(&rhos, 6));
    assert!((pred - left - act).abs() < 1e-9 && rho < 0.0);
    assert!((rhos[2] - 1.0).abs() < (rhos[1] - 1.0).abs() && (rhos[1] - 1.0).abs() < (rhos[0] - 1.0).abs() && (rhos[0] - 1.0).abs() < 0.05);
    // ---- the full run ----
    let (x, y, tr) = run(-1.2, 1.0, 1.0, 0.1, 0.25, 2.0, 200);
    println!(" k         x         y          f  radius    step  promised delivered     rho  verdict");
    for t in &tr {
        println!("{:2} {:9.6} {:9.6} {:10.6} {:7.4} {:7.4} {:9.6} {:9.6} {:7.3}  {}", t.0, t.1, t.2, t.3, t.4, t.5, t.6, t.7, t.8,
                 if t.9 { "accept" } else { "reject" });
    }
    let acc: Vec<&Row> = tr.iter().filter(|t| t.9).collect();
    let mut logs: Vec<f64> = acc.iter().map(|t| t.3.max(1e-300).log10()).collect();
    logs.push(f(x, y).max(1e-300).log10());
    println!("chart log10 f at each accepted point: {}", join(&logs, 2));
    let (gx, gy) = grad(x, y);
    let (a, b, c) = hess(x, y);
    println!("stopped after {} iterations ({} rejected) at ({:.9}, {:.9}), log10 f = {:.2}, |gradient| below 1e-8: {}",
             tr.len(), tr.len() - acc.len(), x, y, logs[logs.len() - 1], if gx.hypot(gy) < 1e-8 { "True" } else { "False" });
    println!("certificate: Hessian there a = {:.4}, det = {:.4} > 0; f is a sum of squares, f(1, 1) = {:.1}", a, a * c - b * b, f(1.0, 1.0));
    assert!((x - 1.0).hypot(y - 1.0) < 1e-8 && a > 0.0 && a * c - b * b > 0.0 && f(1.0, 1.0) == 0.0);
    assert!(acc.windows(2).all(|w| w[1].3 < w[0].3) && f(x, y) < acc[acc.len() - 1].3);
    // ---- what breaks ----
    let (mut xn, mut yn, mut newton_f) = (-1.2, 1.0, Vec::new());
    for _ in 0..20 {
        if len(grad(xn, yn)) < 1e-8 { break; }
        let d = solve(hess(xn, yn), grad(xn, yn), 0.0);
        xn += d.0; yn += d.1;
        newton_f.push(f(xn, yn));
    }
    println!("pure Newton: f after steps 1, 2, 3 = {:.6}, {:.6}, {:.6}; done in {} steps", newton_f[0], newton_f[1], newton_f[2], newton_f.len());
    let (_, _, t2) = run(-1.2, 1.0, 1.0, 0.1, 1.0, 2.0, 50);
    println!("never shrink: {} of {} tries rejected, stuck at f = {:.6}", t2.iter().filter(|t| !t.9).count(), t2.len(), t2[t2.len() - 1].3);
    let (_, _, t3) = run(-1.2, 1.0, 1.0, -1e300, 0.25, 2.0, 200);
    println!("no ratio test: f goes {:.6} -> {:.6} at k = 1; done in {} iterations", t3[1].3, t3[2].3, t3.len());
    let (_, _, t4) = run(-1.2, 1.0, 0.1, 0.1, 1.0, 1.0, 200);
    println!("radius fixed at 0.1: {} iterations, against {}", t4.len(), tr.len());
    assert!(newton_f[1] > 1000.0 && t2.len() == 50 && t2[t2.len() - 1].3 == f(x1, y1) && t3[2].3 > t3[1].3 && t4.len() > 2 * tr.len());
    let r1 = try_step(x1, y1, 1.0).0;
    println!("figure, x1 = ({:.4}, {:.4}), circles 1 and 0.25, rejected ({:.4}, {:.4}), accepted ({:.4}, {:.4}), level f = {:.4}",
             x1, y1, x1 + r1.0, y1 + r1.1, acc[2].1, acc[2].2, f(x1, y1));
    println!("ALL CHECKS PASS");
}
