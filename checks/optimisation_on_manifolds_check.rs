// Riemannian gradient descent -- the check behind the card.  Rust std only, no crates.
// Exam scores in maths, physics and English; A is their covariance in points^2.  The weights w
// (unit length, a point on the sphere S^2) define one combined score.  f(w) is the mean squared
// distance, in points^2, of the students' score points from the line through the mean along w.
use std::f64::consts::PI;
type V = [f64; 3];
const A: [[f64; 3]; 3] = [[225.0, 144.0, 45.0], [144.0, 144.0, 30.0], [45.0, 30.0, 100.0]];
const TR: f64 = 225.0 + 144.0 + 100.0;
fn mv(v: V) -> V { [0, 1, 2].map(|i| A[i][0] * v[0] + A[i][1] * v[1] + A[i][2] * v[2]) }
fn dot(a: V, b: V) -> f64 { a[0] * b[0] + a[1] * b[1] + a[2] * b[2] }
fn norm(v: V) -> f64 { dot(v, v).sqrt() }
fn add(a: V, b: V, t: f64) -> V { [0, 1, 2].map(|i| a[i] + t * b[i]) }
fn unit(v: V) -> V { let n = norm(v); v.map(|x| x / n) }
fn neg(v: V) -> V { v.map(|x| -x) }
fn scale(t: f64, v: V) -> V { v.map(|x| t * x) }
fn f(w: V) -> f64 { TR - dot(w, mv(w)) }
fn egrad(w: V) -> V { mv(w).map(|x| -2.0 * x) } // ordinary gradient of f in 3D
fn proj(w: V, v: V) -> V { add(v, w, -dot(w, v)) } // drop the part along w
fn rgrad(w: V) -> V { proj(w, egrad(w)) } // Riemannian gradient
fn retract(w: V, v: V) -> V { unit(add(w, v, 1.0)) } // step in the plane, then rescale
fn expmap(w: V, v: V) -> V { // step along the great circle
    let t = norm(v);
    if t == 0.0 { w } else { [0, 1, 2].map(|i| t.cos() * w[i] + t.sin() * v[i] / t) }
}
fn deg(x: f64) -> f64 { x * 180.0 / PI }
fn fmt(v: V) -> String { format!("({:.6}, {:.6}, {:.6})", v[0], v[1], v[2]) }
fn sci(x: f64, d: usize) -> String { // Python-style exponent: 2.40e+01
    let s = format!("{:.*e}", d, x);
    let (m, e) = s.split_once('e').unwrap();
    let e: i32 = e.parse().unwrap();
    format!("{}e{}{:02}", m, if e < 0 { '-' } else { '+' }, e.abs())
}
fn jacobi(m: [[f64; 3]; 3]) -> (V, [V; 3]) { // road 2: eigen-solver by rotations
    let mut a = m;
    let mut v = [[1.0, 0.0, 0.0], [0.0, 1.0, 0.0], [0.0, 0.0, 1.0]];
    for _ in 0..20 {
        for (p, q) in [(0, 1), (0, 2), (1, 2)] {
            if a[p][q].abs() < 1e-14 { continue; }
            let th = (a[q][q] - a[p][p]) / (2.0 * a[p][q]);
            let t = (if th >= 0.0 { 1.0 } else { -1.0 }) / (th.abs() + (th * th + 1.0).sqrt());
            let c = 1.0 / (t * t + 1.0).sqrt();
            let s = t * c;
            for k in 0..3 { let (x, y) = (a[k][p], a[k][q]); a[k][p] = c * x - s * y; a[k][q] = s * x + c * y; }
            for k in 0..3 { let (x, y) = (a[p][k], a[q][k]); a[p][k] = c * x - s * y; a[q][k] = s * x + c * y; }
            for k in 0..3 { let (x, y) = (v[k][p], v[k][q]); v[k][p] = c * x - s * y; v[k][q] = s * x + c * y; }
        }
    }
    let mut order = [0usize, 1, 2];
    order.sort_by(|&i, &j| a[j][j].partial_cmp(&a[i][i]).unwrap());
    let vecs = order.map(|i| { let e = [v[0][i], v[1][i], v[2][i]]; if e[0] + e[1] + e[2] > 0.0 { e } else { neg(e) } });
    (order.map(|i| a[i][i]), vecs)
}
fn descend(mut w: V, alpha: f64, beta: f64, n: usize, step: fn(V, V) -> V, transport: bool) -> Vec<V> {
    let mut d = [0.0; 3];
    let mut path = vec![w];
    for _ in 0..n {
        if transport { d = proj(w, d); } // carry the old direction to T_w S^2
        d = add(neg(rgrad(w)), d, beta); // downhill, plus beta times the old way
        w = step(w, scale(alpha, d));
        path.push(w);
    }
    path
}

fn main() {
    let (lam, ev) = jacobi(A);
    let e = ev[0];
    let err = |w: V| deg(norm(proj(e, w)).atan2(dot(w, e).abs())); // angle from the answer, degrees
    let first = |p: &Vec<V>| p.iter().position(|w| err(*w) < 1e-6).unwrap();
    let (alpha, beta, n) = (0.001, 0.1, 30usize);
    let w0 = unit([1.0, 1.0, 1.0]);
    println!("total spread trace(A) = {:.0} points^2; equal weights w0 = {}", TR, fmt(w0));
    let sd = [A[0][0].sqrt(), A[1][1].sqrt(), A[2][2].sqrt()];
    println!("standard deviations {:.0} {:.0} {:.0} points; correlations {:.2} {:.2} {:.2}; row sums of A {}, sqrt 3 = {:.6}",
             sd[0], sd[1], sd[2], A[0][1] / (sd[0] * sd[1]), A[0][2] / (sd[0] * sd[2]), A[1][2] / (sd[1] * sd[2]), fmt(mv([1.0, 1.0, 1.0])), 3.0f64.sqrt());
    println!("equal weights: index variance {:.3}, f(w0) = {:.3} points^2", dot(w0, mv(w0)), f(w0));
    let (g, r) = (egrad(w0), rgrad(w0));
    println!("step 1: A w0 = {}", fmt(mv(w0)));
    println!("step 1: ordinary gradient {}, part along w0 {:.3}", fmt(g), dot(g, w0));
    println!("step 1: Riemannian gradient {}, length {:.3}, w0 . grad = {}", fmt(r), norm(r), sci(dot(w0, r), 1));
    let v = r.map(|x| -alpha * x);
    let (u, w1) = (add(w0, v, 1.0), retract(w0, v));
    println!("step 1: w0 - alpha grad = {}, length {:.6}; retracted w1 = {}", fmt(u), norm(u), fmt(w1));
    let gap1 = norm(add(expmap(w0, v), w1, -1.0));
    let c3 = norm(v).powi(3) / 3.0;
    println!("step 1: f(w1) = {:.3}; step length |v| = {:.6}; exp map lands {} from w1, |v|^3/3 = {}", f(w1), norm(v), sci(gap1, 2), sci(c3, 2));
    assert!(dot(w0, r).abs() < 1e-12 && f(w1) < f(w0) && 0.5 < gap1 / c3 && gap1 / c3 < 1.5);
    println!("road 2, eigen-solver: eigenvalues {:.6} {:.6} {:.6}; top eigenvector {}", lam[0], lam[1], lam[2], fmt(e));
    let (gd, hb) = (descend(w0, alpha, 0.0, n, retract, true), descend(w0, alpha, beta, n, retract, true));
    let (gx, hx) = (descend(w0, alpha, 0.0, n, expmap, true), descend(w0, alpha, beta, n, expmap, true));
    println!("  k | plain: f, error deg | momentum: f, error deg | exp-map steps, momentum: error deg");
    for k in [0usize, 1, 2, 3, 4, 5, 6, 8, 10, 15, 20, 30] {
        println!("{:3} | {:.6} {} | {:.6} {} | {}", k, f(gd[k]), sci(err(gd[k]), 2), f(hb[k]), sci(err(hb[k]), 2), sci(err(hx[k]), 2));
    }
    let row = |p: &Vec<V>| p[..11].iter().map(|w| format!("{:.2}", f(*w))).collect::<Vec<_>>().join(" ");
    println!("chart, plain: {}", row(&gd));
    println!("chart, momentum: {}", row(&hb));
    println!("steps to within 1e-6 deg: plain {}, momentum {}, plain exp-map {}, momentum exp-map {}", first(&gd), first(&hb), first(&gx), first(&hx));
    let wb = hb[n];
    let mult = dot(wb, mv(wb));
    let res = norm(add(mv(wb), wb, -mult));
    println!("answer w* = {}, f = {:.6}, share of spread kept {:.2}%", fmt(wb), f(wb), 100.0 * mult / TR);
    println!("Lagrange: A w* = lambda w* with lambda = {:.6}, residual {}", mult, sci(res, 1));
    assert!(err(gd[n]) < 1e-7 && err(hb[n]) < 1e-7 && err(hx[n]) < 1e-7 && (mult - lam[0]).abs() < 1e-9 && res < 1e-8);
    assert!(gx.iter().chain(hx.iter()).all(|w| (norm(*w) - 1.0).abs() < 1e-12)); // exp-map steps stay on the sphere
    let pt = |i: usize, j: usize| { let (a, b) = (i as f64 * PI / 900.0, j as f64 * PI / 900.0); unit([a.sin() * b.cos(), a.sin() * b.sin(), a.cos()]) };
    let mut best = (f64::INFINITY, 0, 0);
    for i in 0..451 { for j in 0..1800 { let fv = f(pt(i, j)); if fv < best.0 { best = (fv, i, j); } } }
    let wg = pt(best.1, best.2);
    println!("road 3, grid of 811,800 points, 0.2 deg apart in both angles: best f = {:.6}, {:.4} deg from w*", best.0, err(wg));
    assert!((best.0 - f(wb)).abs() < 1e-2 && err(wg) < 0.2);
    let hess = [2.0 * (lam[0] - lam[1]), 2.0 * (lam[0] - lam[2])];
    let pred = 1.0 - alpha * hess[0];
    println!("Riemannian Hessian at w*: {:.3} {:.3}; step limit 2/L = {:.6}", hess[0], hess[1], 2.0 / hess[1]);
    let ratio = err(gd[12]) / err(gd[11]);
    println!("rate: predicted error factor per step {:.6}, measured {:.6}", pred, ratio);
    assert!((ratio - pred).abs() < 1e-3);
    // what breaks
    let mut p = w0;
    for _ in 0..n { p = add(p, egrad(p), -alpha); }
    println!("mistake, no projection, no retraction: after {} steps |w| = {}, f = {}", n, sci(norm(p), 4), sci(f(p), 4));
    let mut q = w0;
    for _ in 0..n { let g = egrad(q); q = add(q, add(g, q, -dot(q, g) / dot(q, q)), -alpha); }
    println!("mistake, project but never retract: |w| = {:.6}, f = {:.3}, true f there {:.3}", norm(q), f(q), f(unit(q)));
    assert!(norm(p) > 1e6 && f(q) < f(wb) - 1.0 && norm(q) > 1.01);
    let big = descend(w0, 0.004, 0.0, 200, retract, true);
    println!("mistake, step 0.004 above the limit: steps 199 and 200 bounce between {} and {}, f = {:.3} and {:.3}, {:.2} and {:.2} deg from w*",
             fmt(big[199]), fmt(big[200]), f(big[199]), f(big[200]), err(big[199]), err(big[200]));
    assert!(err(big[200]) > 10.0 && err(big[199]) > 10.0);
    let d1 = neg(r);
    let tilt = deg(dot(hb[1], d1).abs().atan2(norm(proj(hb[1], d1))));
    let nt = descend(w0, alpha, beta, n, expmap, false);
    let drift = nt.iter().map(|w| (norm(*w) - 1.0).abs()).fold(0.0, f64::max);
    println!("mistake, no transport: old direction sits {:.2} deg out of the new tangent plane; with exp-map steps |w| strays by up to {}, {} steps to within 1e-6 deg",
             tilt, sci(drift, 2), first(&nt));
    assert!(tilt > 5.0 && drift > 1e-6);
    let s2 = descend(ev[1], alpha, beta, 20, retract, true);
    println!("hypothesis fails, start on a critical point (2nd eigenvector): f stays {:.3} -> {:.3}", f(s2[0]), f(s2[20]));
    assert!((f(s2[20]) - (TR - lam[1])).abs() < 1e-6);
    // try changing
    let (t1, t2, t3) = (first(&descend(w0, alpha, 0.3, 80, retract, true)), first(&descend(w0, 0.0005, 0.0, 120, retract, true)),
                        first(&descend([0.0, 0.0, 1.0], alpha, beta, 80, retract, true)));
    println!("try: momentum 0.3 needs {} steps; plain step 0.0005 needs {}; English-only start (0, 0, 1) needs {}", t1, t2, t3);
    println!("ALL CHECKS PASS");
}
