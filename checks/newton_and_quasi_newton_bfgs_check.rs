type V = (f64, f64);
type M = (f64, f64, f64); // symmetric [[a, b], [b, c]]
fn f(p: V) -> f64 { (1.0 - p.0).powi(2) + 100.0 * (p.1 - p.0 * p.0).powi(2) }
fn grad(p: V) -> V { (-2.0 * (1.0 - p.0) - 400.0 * p.0 * (p.1 - p.0 * p.0), 200.0 * (p.1 - p.0 * p.0)) }
fn hess(p: V) -> M { (2.0 - 400.0 * p.1 + 1200.0 * p.0 * p.0, -400.0 * p.0 + 0.0, 200.0) }
fn solve(a: f64, b: f64, c: f64, r: V) -> V { // [[a, b], [b, c]] d = r, by elimination
    let m = b / a;
    let d2 = (r.1 - m * r.0) / (c - m * b);
    ((r.0 - b * d2) / a, d2)
}
fn lam_min(m: M) -> f64 { (m.0 + m.2) / 2.0 - (((m.0 - m.2) / 2.0).powi(2) + m.1 * m.1).sqrt() }
fn dot(u: V, v: V) -> f64 { u.0 * v.0 + u.1 * v.1 }
fn norm(u: V) -> f64 { dot(u, u).sqrt() }
fn step(p: V, d: V, t: f64) -> V { (p.0 + t * d.0, p.1 + t * d.1) }
fn err(p: V) -> f64 { norm((p.0 - 1.0, p.1 - 1.0)) }
fn neg(g: V) -> V { (-g.0, -g.1) }
fn mul(m: M, s: V) -> V { (m.0 * s.0 + m.1 * s.1, m.1 * s.0 + m.2 * s.1) }
fn e(v: f64, prec: usize) -> String { // Python-style scientific notation
    let s = format!("{:.*e}", prec, v);
    let (mant, ex) = s.split_once('e').unwrap();
    let n: i32 = ex.parse().unwrap();
    format!("{}e{}{:02}", mant, if n < 0 { '-' } else { '+' }, n.abs())
}
struct Row { k: usize, p: V, f: f64, gn: f64, tau: f64, t: f64 }
fn newton(mut p: V, delta: f64, tol: f64, search: bool, modify: bool, cap: usize) -> Vec<Row> {
    let mut rows = Vec::new();
    for k in 0..cap {
        let g = grad(p);
        let h = hess(p);
        let tau = if modify { (delta - lam_min(h)).max(0.0) } else { 0.0 };
        if norm(g) < tol { rows.push(Row { k, p, f: f(p), gn: norm(g), tau, t: 0.0 }); return rows; }
        let d = solve(h.0 + tau, h.1, h.2 + tau, neg(g));
        let mut t = 1.0;
        while search && f(step(p, d, t)) > f(p) + 1e-4 * t * dot(g, d) { t /= 2.0; }
        rows.push(Row { k, p, f: f(p), gn: norm(g), tau, t });
        p = step(p, d, t);
    }
    rows
}
fn wolfe(p: V, d: V, g: V) -> f64 { // weak Wolfe by bisection, c1 = 0.0001, c2 = 0.9
    let (mut lo, mut hi, mut t) = (0.0, f64::INFINITY, 1.0);
    for _ in 0..60 {
        if f(step(p, d, t)) > f(p) + 1e-4 * t * dot(g, d) { hi = t; }
        else if dot(grad(step(p, d, t)), d) < 0.9 * dot(g, d) { lo = t; }
        else { break; }
        t = if hi < f64::INFINITY { (lo + hi) / 2.0 } else { 2.0 * t };
    }
    t
}
fn bfgs_update(b: M, s: V, y: V) -> M {
    let bs = mul(b, s);
    let (sbs, sy) = (dot(s, bs), dot(s, y));
    (b.0 - bs.0 * bs.0 / sbs + y.0 * y.0 / sy, b.1 - bs.0 * bs.1 / sbs + y.0 * y.1 / sy,
     b.2 - bs.1 * bs.1 / sbs + y.1 * y.1 / sy)
}
fn bfgs(mut p: V, tol: f64, learn: bool, cap: usize) -> (usize, V, M, Vec<f64>, f64) {
    let (mut b, mut errs, mut worst, mut k) = ((1.0, 0.0, 1.0), Vec::new(), 0.0f64, 0);
    while k < cap {
        let g = grad(p);
        errs.push(err(p));
        if norm(g) < tol { break; }
        let d = solve(b.0, b.1, b.2, neg(g));
        let q = step(p, d, wolfe(p, d, g));
        let (s, y) = ((q.0 - p.0, q.1 - p.1), (grad(q).0 - g.0, grad(q).1 - g.1));
        if learn {
            b = bfgs_update(b, s, y);
            let bs = mul(b, s);
            worst = worst.max(norm((bs.0 - y.0, bs.1 - y.1)) / norm(y));
        }
        p = q;
        k += 1;
    }
    (k, p, b, errs, worst)
}
fn main() {
    // Road 1: modified Newton with Armijo backtracking, from (0, 1)
    let start = (0.0, 1.0);
    let h = hess(start);
    println!("start (0, 1): f = {:.0}, gradient ({:.0}, {:.0})", f(start), grad(start).0, grad(start).1);
    println!("Hessian at start [[{:.0}, {:.0}], [{:.0}, {:.0}]], lowest curvature {:.0}", h.0, h.1, h.1, h.2, lam_min(h));
    let tau0 = 1e-3 - lam_min(h);
    let d0 = solve(h.0 + tau0, h.1, h.2 + tau0, neg(grad(start)));
    println!("shifted by tau = {:.3}: [[{:.3}, {:.0}], [{:.0}, {:.3}]], step d = ({:.0}, {:.3})", tau0, h.0 + tau0, h.1, h.1, h.2 + tau0, d0.0, d0.1);
    let rows = newton(start, 1e-3, 1e-8, true, true, 1000);
    println!(" k         u          v          f     |grad|       tau     alpha");
    for r in &rows {
        let frac = if r.t == 0.0 { "-".to_string() } else if r.t == 1.0 { "1".to_string() } else { format!("1/{}", (1.0 / r.t).round()) };
        println!("{:2} {:10.6} {:10.6} {:>10} {:>9} {:9.3} {:>9}", r.k, r.p.0, r.p.1, e(r.f, 3), e(r.gn, 2), r.tau, frac);
    }
    let ne: Vec<f64> = rows.iter().map(|r| err(r.p)).collect();
    let mut line = String::from("Newton e(k+1)/e(k)^2, k = 4..7:");
    for k in 4..8 { line += &format!(" {:.2}", ne[k + 1] / ne[k].powi(2)); }
    println!("{}", line);
    // Road 2: the certificate at (1, 1): f is a sum of two squares, so f >= 0 = f(1, 1)
    let h1 = hess((1.0, 1.0));
    println!("Hessian at (1, 1) [[{:.0}, {:.0}], [{:.0}, {:.0}]], det {:.0}, lowest curvature {:.4}", h1.0, h1.1, h1.1, h1.2, h1.0 * h1.2 - h1.1 * h1.1, lam_min(h1));
    // Road 3: BFGS with weak Wolfe steps, from the same start, B_0 = identity
    let (nb, pb, b, be, worst) = bfgs(start, 1e-8, true, 50000);
    println!("BFGS steps {}, final ({:.10}, {:.10}), worst secant miss {}", nb, pb.0, pb.1, e(worst, 1));
    let mut line = String::from("BFGS e(k+1)/e(k), last five:");
    for k in nb - 5..nb { line += &format!(" {:.4}", be[k + 1] / be[k]); }
    println!("{}", line);
    println!("BFGS remembered B [[{:.1}, {:.1}], [{:.1}, {:.1}]] vs true [[802, -400], [-400, 200]]", b.0, b.1, b.1, b.2);
    // Road 4: derivatives against central differences
    let (hh, mut worst_g, mut worst_h) = (1e-5, 0.0f64, 0.0f64);
    for p in [start, (0.7, 0.5), (1.2, 1.3)] {
        for i in 0..2 {
            let (up, dn) = if i == 0 { ((p.0 + hh, p.1), (p.0 - hh, p.1)) } else { ((p.0, p.1 + hh), (p.0, p.1 - hh)) };
            let gi = if i == 0 { grad(p).0 } else { grad(p).1 };
            worst_g = worst_g.max(((f(up) - f(dn)) / (2.0 * hh) - gi).abs());
            let col = ((grad(up).0 - grad(dn).0) / (2.0 * hh), (grad(up).1 - grad(dn).1) / (2.0 * hh));
            let hp = hess(p);
            let (h0, h1) = if i == 0 { (hp.0, hp.1) } else { (hp.1, hp.2) };
            worst_h = worst_h.max((col.0 - h0).abs()).max((col.1 - h1).abs());
        }
    }
    println!("central difference miss: gradient {}, Hessian {}", e(worst_g, 1), e(worst_h, 1));
    // Road 5: on a quadratic with exact line search, BFGS learns A in two steps
    let (a, rhs) = ((3.0, 1.0, 2.0), (1.0, 1.0));
    let (mut x, mut bq) = ((0.0, 0.0), (1.0, 0.0, 1.0));
    for _ in 0..2 {
        let ax = mul(a, x);
        let g = (ax.0 - rhs.0, ax.1 - rhs.1);
        let d = solve(bq.0, bq.1, bq.2, neg(g));
        let t = -dot(g, d) / dot(d, mul(a, d));
        let s = (t * d.0, t * d.1);
        bq = bfgs_update(bq, s, mul(a, s));
        x = step(x, s, 1.0);
    }
    println!("quadratic: x_2 = ({:.6}, {:.6}), B_2 = [[{:.6}, {:.6}], [{:.6}, {:.6}]]", x.0, x.1, bq.0, bq.1, bq.1, bq.2);
    // What breaks
    let p = (0.7, 0.5);
    let (g, hp) = (grad(p), hess(p));
    let lm = lam_min(hp);
    let dp = solve(hp.0, hp.1, hp.2, neg(g));
    let dm = solve(hp.0 + 1e-3 - lm, hp.1, hp.2 + 1e-3 - lm, neg(g));
    println!("break: pure Newton at (0.7, 0.5), lowest curvature {:.4}, slope along step {:+.2}, f {:.2} -> {:.2}", lm, dot(g, dp), f(p), f(step(p, dp, 1.0)));
    println!("  modified step there: slope along step {:+.2}", dot(g, dm));
    println!("break: floor delta = 10 instead of 0.001, Newton steps {}", newton(start, 10.0, 1e-8, true, true, 1000).len() - 1);
    let wild = newton(start, 1e-3, 1e-8, false, true, 2);
    println!("break: shift but no line search, first step lands at u = {:.0}, f = {}", wild[1].p.0, e(wild[1].f, 3));
    println!("break: B never updated (gradient descent with Wolfe), steps {}", bfgs(start, 1e-8, false, 50000).0);
    let (mut pa, mut qa, mut ga) = ((-1.2, 1.0), (0.0, 0.0), (0.0, 0.0)); // BFGS fed an Armijo-only step: descent to step 30, as on Line search
    for _ in 0..31 { let (g, mut t) = (grad(pa), 1.0); while f(step(pa, g, -t)) > f(pa) - 1e-4 * t * dot(g, g) { t /= 2.0; } (qa, ga, pa) = (pa, g, step(pa, g, -t)); }
    let (sa, ya, gn) = ((pa.0 - qa.0, pa.1 - qa.1), (grad(pa).0 - ga.0, grad(pa).1 - ga.1), grad(pa));
    let ba = bfgs_update((1.0, 0.0, 1.0), sa, ya);
    println!("break: BFGS fed an Armijo-only step at step 30 from (-1.2, 1): s.y {:.2}, next slope {:+.2}", dot(sa, ya), dot(gn, solve(ba.0, ba.1, ba.2, neg(gn))));
    // Try changing
    println!("try: start (-1.2, 1): Newton {}, BFGS {}", newton((-1.2, 1.0), 1e-3, 1e-8, true, true, 1000).len() - 1, bfgs((-1.2, 1.0), 1e-8, true, 50000).0);
    let raw = newton(start, 1e-3, 1e-8, false, false, 1000);
    let top = raw[1..].iter().map(|r| r.f).fold(f64::MIN, f64::max);
    println!("try: pure Newton from (0, 1), no shift, no search: steps {}, highest f after the start {:.2}", raw.len() - 1, top);
    println!("try: tolerance 1e-12: Newton {}, BFGS {}", newton(start, 1e-3, 1e-12, true, true, 1000).len() - 1, bfgs(start, 1e-12, true, 50000).0);
    let path = |rs: &[Row]| rs.iter().map(|r| format!(" ({:.3}, {:.3})", r.p.0, r.p.1)).collect::<String>();
    println!("figure, Newton path{}", path(&rows[..5]));
    println!("figure, pure Newton path{}", path(&raw[..4]));

    let det = hp.0 * hp.2 - hp.1 * hp.1;
    assert!(rows.len() - 1 == 8 && err(rows[rows.len() - 1].p) < 1e-9, "Newton reaches (1, 1) in eight steps");
    assert!(err(pb) < 1e-8 && nb == 27, "BFGS reaches the same floor");
    assert!(det < 0.0 && dot(g, dp) > 0.0 && f(step(p, dp, 1.0)) > f(p), "pure Newton climbs at an indefinite point");
    assert!(dot(g, dm) < 0.0, "the modified step points downhill");
    assert!(worst < 1e-10, "every BFGS matrix satisfies the secant equation B s = y");
    assert!(((b.0 - 802.0) / 802.0).abs().max(((b.1 + 400.0) / 400.0).abs()).max(((b.2 - 200.0) / 200.0).abs()) < 0.01, "BFGS memory near the true Hessian");
    assert!(worst_g < 1e-4 && worst_h < 1e-3, "analytic derivatives match central differences");
    assert!((x.0 - 0.2).abs() < 1e-12 && (x.1 - 0.4).abs() < 1e-12, "quadratic minimiser by Cramer: (2 - 1, 3 - 1) / 5");
    assert!((bq.0 - 3.0).abs().max((bq.1 - 1.0).abs()).max((bq.2 - 2.0).abs()) < 1e-12, "BFGS recovers A after two exact steps");
    assert!(ne[7] / ne[6].powi(2) < 20.0 && be[nb] / be[nb - 1] < 0.01, "quadratic for Newton, superlinear for BFGS");
    println!("ALL CHECKS PASS");
}
