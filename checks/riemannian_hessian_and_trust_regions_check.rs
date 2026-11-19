// Riemannian Hessian -- the same check as riemannian_hessian_and_trust_regions_check.py,
// in Rust.  Standard library only, no crates.
// A rank-1 music recommender: 4 listeners rate 3 songs (matrix M).  The taste
// direction x is a unit vector, a point on the sphere S^2.  Its error is
// f(x) = |M|^2 - x^T C x with C = M^T M.  A trust region minimises f using the
// Riemannian Hessian, steps in the tangent plane and returns by a retraction.
// Compile: rustc --edition 2021 -O riemannian_hessian_and_trust_regions_check.rs
type V3 = [f64; 3]; type M2 = [[f64; 2]; 2];
const M: [[f64; 3]; 4] = [[5., 4., 1.], [4., 5., 2.], [1., 2., 5.], [2., 1., 4.]];
struct P { c: [[f64; 3]; 3], tot: f64 }
fn dot(a: &V3, b: &V3) -> f64 { a.iter().zip(b).fold(0.0, |s, (p, q)| s + p * q) }
fn dot2(a: &[f64; 2], b: &[f64; 2]) -> f64 { a[0] * b[0] + a[1] * b[1] }
fn comb(a: f64, x: &V3, b: f64, y: &V3) -> V3 { [a * x[0] + b * y[0], a * x[1] + b * y[1], a * x[2] + b * y[2]] }
fn z(v: f64) -> f64 { if v.abs() < 5e-5 { 0.0 } else { v } } // print -0.0000 as 0.0000
fn unit(v: &V3) -> V3 { let n = dot(v, v).sqrt(); [v[0] / n, v[1] / n, v[2] / n] }
fn tf(b: bool) -> &'static str { if b { "True" } else { "False" } }
impl P {
    fn cv(&self, v: &V3) -> V3 { [dot(&self.c[0], v), dot(&self.c[1], v), dot(&self.c[2], v)] }
    fn f(&self, x: &V3) -> f64 { self.tot - dot(x, &self.cv(x)) } // the formula, used on all of R^3
    fn egrad(&self, x: &V3) -> V3 { let c = self.cv(x); [-2. * c[0], -2. * c[1], -2. * c[2]] }
    fn rgrad(&self, x: &V3) -> V3 { proj(x, &self.egrad(x)) }
    fn rhess(&self, x: &V3, v: &V3, curv: bool) -> V3 { // P_x(-2 C v) - (x . egrad) v
        let c = self.cv(v);
        comb(1.0, &proj(x, &[-2. * c[0], -2. * c[1], -2. * c[2]]), if curv { -dot(x, &self.egrad(x)) } else { 0.0 }, v)
    }
    fn model(&self, x: &V3, curv: bool) -> ([V3; 2], [f64; 2], M2) {
        let e = basis(x);
        let (rg, mut h) = (self.rgrad(x), [[0.0; 2]; 2]);
        let g = [dot(&e[0], &rg), dot(&e[1], &rg)];
        for i in 0..2 { for j in 0..2 { h[i][j] = dot(&e[i], &self.rhess(x, &e[j], curv)); } }
        (e, g, h)
    }
    fn tr_run(&self, x0: &V3, d0: f64, curv: bool, kmax: usize, quiet: bool) -> (V3, usize, usize, f64) {
        let (eta, cap, mut x, mut d, mut tries, mut refused) = (0.1, 3.0, *x0, d0, 0, 0);
        for k in 0..kmax {
            let (e, g, h) = self.model(&x, curv);
            if g[0].hypot(g[1]) < 1e-8 { break; }
            let (s, v) = (subproblem(&h, &g, d), tangent_step(&e, &g, &h, d));
            let (pred, act) = (promise(&g, &h, &s), self.f(&x) - self.f(&retract(&x, &v)));
            let rho = act / pred;
            let ok = rho > eta || pred < 1e-6; // a fall below 1e-6 is rounding noise
            tries += 1; refused += !ok as usize;
            let sl = s[0].hypot(s[1]);
            if !quiet && pred > 1e-6 {
                println!("{:2} {:10.6} {:5.3} {:8.6} {:11.6} {:10.6} {:7.4} {:7.4} {}", k, self.f(&x), d, sl, pred, act, rho, 1.0 / (1.0 + dot2(&s, &s)), if ok { "keep" } else { "refuse" });
                assert!((rho - 1.0 / (1.0 + dot2(&s, &s))).abs() < 1e-9); // the closed form of Step 3
            } else if !quiet {
                println!("{:2} {:10.6} {:5.3} {:8.6}  promised fall below 1e-6: {}", k, self.f(&x), d, sl, if ok { "keep" } else { "refuse" });
            }
            if ok { x = retract(&x, &v); }
            if rho < 0.25 { d /= 4.0; } else if rho > 0.75 && (sl - d).abs() < 1e-9 { d = (2.0 * d).min(cap); }
        }
        let g = self.model(&x, true).1;
        (x, tries, refused, g[0].hypot(g[1]))
    }
}
fn proj(x: &V3, u: &V3) -> V3 { comb(1.0, u, -dot(x, u), x) } // P_x u = u - (x.u) x
fn basis(x: &V3) -> [V3; 2] { // two orthonormal tangent vectors
    let mut out: Vec<V3> = Vec::new();
    for e in [[1.0, 0., 0.], [0., 1.0, 0.], [0., 0., 1.0]] {
        let mut w = proj(x, &e);
        for b in out.clone() { w = comb(1.0, &w, -dot(&w, &b), &b); }
        if out.len() < 2 && dot(&w, &w).sqrt() > 0.3 { out.push(unit(&w)); }
    }
    [out[0], out[1]]
}
fn eig2(h: &M2) -> (f64, f64) {
    let (m, d) = ((h[0][0] + h[1][1]) / 2.0, ((h[0][0] - h[1][1]) / 2.0).hypot(h[0][1]));
    (m - d, m + d)
}
fn solve2(h: &M2, g: &[f64; 2], lam: f64) -> [f64; 2] { // (H + lam I) s = -g
    let (a, b, c) = (h[0][0] + lam, h[0][1], h[1][1] + lam);
    [-(c * g[0] - b * g[1]) / (a * c - b * b), -(a * g[1] - b * g[0]) / (a * c - b * b)]
}
fn subproblem(h: &M2, g: &[f64; 2], d: f64) -> [f64; 2] { // exact lowest point of the model in the disc
    let lo = eig2(h).0;
    let n = solve2(h, g, 0.0);
    if lo > 0.0 && n[0].hypot(n[1]) <= d { return n; }
    let (mut a, mut b) = (0f64.max(-lo) + 1e-12, 0f64.max(-lo) + 1e6);
    for _ in 0..200 {
        let (m, s) = ((a + b) / 2.0, solve2(h, g, (a + b) / 2.0));
        if s[0].hypot(s[1]) > d { a = m; } else { b = m; }
    }
    solve2(h, g, b)
}
fn tangent_step(e: &[V3; 2], g: &[f64; 2], h: &M2, d: f64) -> V3 { let s = subproblem(h, g, d); comb(s[0], &e[0], s[1], &e[1]) }
fn promise(g: &[f64; 2], h: &M2, s: &[f64; 2]) -> f64 { -(dot2(g, s) + 0.5 * dot2(s, &[dot2(&h[0], s), dot2(&h[1], s)])) }
fn retract(x: &V3, v: &V3) -> V3 { unit(&comb(1.0, x, 1.0, v)) }
fn geodesic(x: &V3, v: &V3, t: f64) -> V3 { let n = dot(v, v).sqrt(); comb((t * n).cos(), x, (t * n).sin() / n, v) } // great circle
fn jacobi(a0: &[[f64; 3]; 3]) -> (V3, [V3; 3]) { // eigenvalues and vectors of symmetric 3x3
    let (mut a, mut vv) = (*a0, [[1.0, 0., 0.], [0., 1.0, 0.], [0., 0., 1.0]]);
    for _ in 0..30 {
        for (p, q) in [(0, 1), (0, 2), (1, 2)] {
            if a[p][q].abs() < 1e-14 { continue; }
            let t = 0.5 * (2.0 * a[p][q]).atan2(a[q][q] - a[p][p]);
            let (c, s) = (t.cos(), t.sin()); // one Jacobi rotation
            for k in 0..3 { let (x, y) = (a[k][p], a[k][q]); a[k][p] = c * x - s * y; a[k][q] = s * x + c * y; }
            for k in 0..3 { let (x, y) = (a[p][k], a[q][k]); a[p][k] = c * x - s * y; a[q][k] = s * x + c * y; }
            for k in 0..3 { let (x, y) = (vv[k][p], vv[k][q]); vv[k][p] = c * x - s * y; vv[k][q] = s * x + c * y; }
        }
    }
    let mut idx = [0usize, 1, 2];
    idx.sort_by(|&i, &j| a[j][j].partial_cmp(&a[i][i]).unwrap());
    let (mut lam, mut vec) = ([0.0; 3], [[0.0; 3]; 3]);
    for (n, &i) in idx.iter().enumerate() {
        lam[n] = a[i][i];
        let col = [vv[0][i], vv[1][i], vv[2][i]];
        vec[n] = if col[0] + col[1] + col[2] > 0.0 { unit(&col) } else { [-col[0], -col[1], -col[2]] };
    }
    (lam, vec)
}
fn main() {
    let row = |r: &[f64; 3]| format!("[{}, {}, {}]", r[0], r[1], r[2]);
    let mut c = [[0.0; 3]; 3];
    for i in 0..3 { for j in 0..3 { c[i][j] = M.iter().fold(0.0, |s, r| s + r[i] * r[j]); } }
    let p = P { c, tot: M.iter().flatten().fold(0.0, |s, v| s + v * v) };
    // ---- the data and the start: all weight on song 3 ----
    println!("C = M^T M rows: {}, {}, {}; |M|^2 = {}", row(&c[0]), row(&c[1]), row(&c[2]), p.tot);
    let x0: V3 = [0.0, 0.0, 1.0];
    let (e, g, h) = p.model(&x0, true);
    let (hflat, eg) = (p.model(&x0, false).2, p.egrad(&x0));
    println!("start x0 = (0, 0, 1): f = {:.6}, ordinary gradient ({:.1}, {:.1}, {:.1}), radial part x.grad = {:.1}", p.f(&x0), eg[0], eg[1], eg[2], dot(&x0, &eg));
    println!("grad f = ({:.1}, {:.1}); projected part {:.1}, {:.1}, {:.1}; curvature term +{:.1}", g[0], g[1], hflat[0][0], hflat[0][1], hflat[1][1], -dot(&x0, &eg));
    println!("Hess f at x0 = [[{:.1}, {:.1}], [{:.1}, {:.1}]], eigenvalues {:.4}, {:.4}; flat part alone {:.4}, {:.4}", h[0][0], h[0][1], h[1][0], h[1][1], eig2(&h).0, eig2(&h).1, eig2(&hflat).0, eig2(&hflat).1);
    // ---- road 1: second derivative along great circles and along the retraction ----
    let hh = 1e-4; // finite-difference step
    for v in [[1.0, 0., 0.], [0., 1.0, 0.], [1.0, 1.0, 0.], [1.0, -2.0, 0.]] {
        let geo = (p.f(&geodesic(&x0, &v, hh)) - 2.0 * p.f(&x0) + p.f(&geodesic(&x0, &v, -hh))) / (hh * hh);
        let ret = (p.f(&retract(&x0, &comb(hh, &v, 0.0, &v))) - 2.0 * p.f(&x0) + p.f(&retract(&x0, &comb(-hh, &v, 0.0, &v)))) / (hh * hh);
        let form = dot(&v, &p.rhess(&x0, &v, true));
        assert!((geo - form).abs() < 1e-4 && (ret - form).abs() < 1e-4);
        println!("v = ({:.0}, {:.0}, 0): <v, Hess v> = {:9.4}; great circle {:9.4}; retraction {:9.4}", v[0], v[1], z(form), z(geo), z(ret));
    }
    let sn = solve2(&h, &g, 0.0); // the plain Newton step
    println!("pure Newton step: length {:.6}, f goes 92 -> {:.6}", sn[0].hypot(sn[1]), p.f(&retract(&x0, &comb(sn[0], &e[0], sn[1], &e[1]))));
    let v1 = tangent_step(&e, &g, &h, 1.0);
    let off = comb(1.0, &x0, 1.0, &v1); // the step added in R^3, never pulled back
    println!("radius-1 step v = ({:.6}, {:.6}, {:.6}); x0 + v off the sphere: f = {:.6}, |x0 + v| = {:.6}", v1[0], v1[1], v1[2], p.f(&off), dot(&off, &off).sqrt());
    let pr: Vec<String> = (1..9).map(|i| format!("{:.2}", promise(&g, &h, &subproblem(&h, &g, 0.25 * i as f64)))).collect();
    let de: Vec<String> = (1..9).map(|i| format!("{:.2}", p.f(&x0) - p.f(&retract(&x0, &tangent_step(&e, &g, &h, 0.25 * i as f64))))).collect();
    println!("chart, radius 0.25 to 2.00, promised: {}", pr.join(", "));
    println!("chart, radius 0.25 to 2.00, delivered: {}", de.join(", "));
    // ---- the run, radius 1, eta 0.1 ----
    println!(" k          f     D     step    promised  delivered     rho 1/(1+s^2)");
    let ((xs, tries, _, gend), (lam, vec)) = (p.tr_run(&x0, 1.0, true, 30, false), jacobi(&c));
    println!("end x* = ({:.6}, {:.6}, {:.6}), f = {:.6}, after {} tries, slope below 1e-8: {}", xs[0], xs[1], xs[2], p.f(&xs), tries, tf(gend < 1e-8));
    println!("eigen-solver: lambda = {:.6}, {:.6}, {:.6}; top vector ({:.6}, {:.6}, {:.6}); |M|^2 - lambda1 = {:.6}", lam[0], lam[1], lam[2], vec[0][0], vec[0][1], vec[0][2], p.tot - lam[0]);
    assert!((p.f(&xs) - (p.tot - lam[0])).abs() < 1e-9 && (0..3).all(|i| (xs[i] - vec[0][i]).abs() < 1e-8));
    let (s1, hs, hsf) = (dot(&M[0], &xs), p.model(&xs, true).2, p.model(&xs, false).2);
    println!("rms error per rating {:.4} stars; share of |M|^2 captured {:.4}; listener 1 predicted {:.2}, {:.2}, {:.2}", (p.f(&xs) / 12.0).sqrt(), lam[0] / p.tot, s1 * xs[0], s1 * xs[1], s1 * xs[2]);
    println!("Hess f at x*: eigenvalues {:.4}, {:.4}; 2(l1-l2), 2(l1-l3) = {:.4}, {:.4}", eig2(&hs).0, eig2(&hs).1, 2.0 * (lam[0] - lam[1]), 2.0 * (lam[0] - lam[2]));
    assert!((eig2(&hs).0 - 2.0 * (lam[0] - lam[1])).abs() < 1e-6 && (eig2(&hs).1 - 2.0 * (lam[0] - lam[2])).abs() < 1e-6);
    println!("flat part alone at x*: {:.4}, {:.4}; curvature term +{:.4}", eig2(&hsf).0, eig2(&hsf).1, 2.0 * lam[0]);
    // ---- what breaks ----
    let (_, t2, r2, g2) = p.tr_run(&x0, 1.0, false, 10, true);
    println!("no curvature term: after {} tries, {} refused, slope still {:.4}", t2, r2, g2);
    let (_, gv, hv) = p.model(&vec[1], true);
    println!("saddle (song mix 5, 4, -11): slope below 1e-8: {}, Hess eigenvalues {:.4}, {:.4}", tf(gv[0].hypot(gv[1]) < 1e-8), eig2(&hv).0, eig2(&hv).1);
    assert!((eig2(&hv).0 - 2.0 * (lam[1] - lam[0])).abs() < 1e-6 && eig2(&hv).1 > 0.0 && (dot(&vec[1], &[5., 4., -11.]).abs() - 162f64.sqrt()).abs() < 1e-9);
    println!("convexity along the great circle x* -> saddle, lowest Hess eigenvalue:");
    for deg in [0, 15, 30, 45, 60] {
        let t = deg as f64 * std::f64::consts::PI / 180.0;
        let low = eig2(&p.model(&comb(t.cos(), &vec[0], t.sin(), &vec[1]), true).2).0;
        println!("  {:2} deg: {:9.4}   2(l1-l2)cos(2t) = {:9.4}", deg, z(low), z(2.0 * (lam[0] - lam[1]) * (2.0 * t).cos()));
    }
    let ((xe, te, _, _), ts, s2) = (p.tr_run(&[1.0, 0., 0.], 1.0, true, 30, true), p.tr_run(&vec[1], 1.0, true, 30, true).1, subproblem(&h, &g, 2.0));
    println!("try: radius 2 first ratio {:.4}; start (1, 0, 0): f = {:.6} -> {:.6} after {} tries; start at the saddle: {} tries",
             (p.f(&x0) - p.f(&retract(&x0, &tangent_step(&e, &g, &h, 2.0)))) / promise(&g, &h, &s2), p.f(&[1.0, 0., 0.]), p.f(&xe), te, ts);
    println!("ALL CHECKS PASS");
}
