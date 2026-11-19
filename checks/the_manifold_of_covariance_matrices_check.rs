// Covariance matrices: blend two risk estimates by the log-Euclidean and affine-invariant means.
type M = [f64; 4]; // a 2x2 matrix, row by row
const I: M = [1.0, 0.0, 0.0, 1.0];
fn mul(x: M, y: M) -> M {
    [x[0]*y[0] + x[1]*y[2], x[0]*y[1] + x[1]*y[3], x[2]*y[0] + x[3]*y[2], x[2]*y[1] + x[3]*y[3]]
}
fn lin(x: M, y: M, s: f64, t: f64) -> M { [s*x[0] + t*y[0], s*x[1] + t*y[1], s*x[2] + t*y[2], s*x[3] + t*y[3]] }
fn det(x: M) -> f64 { x[0]*x[3] - x[1]*x[2] }
fn tr(x: M) -> f64 { x[0] + x[3] }
fn inv(x: M) -> M { let d = det(x); [x[3]/d, -x[1]/d, -x[2]/d, x[0]/d] }
fn fro(x: M) -> f64 { x.iter().map(|v| v*v).sum::<f64>().sqrt() }
fn corr(m: M) -> f64 { m[1] / (m[0]*m[3]).sqrt() }
fn gap(x: M, y: M) -> f64 { (0..4).map(|i| (x[i] - y[i]).abs()).fold(0.0, f64::max) }
fn yn(ok: bool) -> &'static str { if ok { "yes" } else { "no" } }
// road 1: closed-form eigenvalues of a symmetric 2x2 matrix, smallest first
fn eig(m: M) -> (f64, f64) {
    let c = (m[0] + m[3]) / 2.0; let r = ((m[0] - m[3]) / 2.0).hypot((m[1] + m[2]) / 2.0); (c - r, c + r)
}
// road 1: f applied along the eigenvectors (rotation angle th)
fn fun(m: M, f: &dyn Fn(f64) -> f64) -> M {
    let th = 0.5 * (m[1] + m[2]).atan2(m[0] - m[3]); let (c, s) = (th.cos(), th.sin());
    let (lo, hi) = eig(m); let (f1, f2) = (f(hi), f(lo));
    [f1*c*c + f2*s*s, (f1 - f2)*c*s, (f1 - f2)*c*s, f1*s*s + f2*c*c]
}
// Denman-Beavers square root, no eigenvectors: road 3 of the mean, inside road 2's log
fn sqrt_db(m: M) -> M {
    let (mut y, mut z) = (m, I);
    for _ in 0..60 { let (y2, z2) = (lin(y, inv(z), 0.5, 0.5), lin(z, inv(y), 0.5, 0.5)); y = y2; z = z2; }
    y
}
// road 2: take square roots until near I, then the artanh series
fn log_ser(m: M) -> M {
    let (mut m, mut k) = (m, 0);
    while fro(lin(m, I, 1.0, -1.0)) > 0.05 { m = sqrt_db(m); k += 1; }
    let u = mul(lin(m, I, 1.0, -1.0), inv(lin(m, I, 1.0, 1.0)));
    let (u2, mut p, mut s) = (mul(u, u), u, [0.0; 4]);
    for j in 0..30 { s = lin(s, p, 1.0, 2.0 / (2 * j + 1) as f64); p = mul(p, u2); }
    lin(s, s, 2f64.powi(k), 0.0)
}
// road 2: Taylor series on X/1024, then square ten times
fn exp_ser(x: M) -> M {
    let (y, mut p, mut s) = (lin(x, x, 1.0 / 1024.0, 0.0), I, I);
    for j in 1..20 { p = lin(mul(p, y), p, 1.0 / j as f64, 0.0); s = lin(s, p, 1.0, 1.0); }
    for _ in 0..10 { s = mul(s, s); }
    s
}
fn show(name: &str, m: M) { println!("{}: [[{:.4}, {:.4}], [{:.4}, {:.4}]]", name, m[0], m[1], m[2], m[3]); }
// affine-invariant geodesic A^(1/2) (A^(-1/2) B A^(-1/2))^t A^(1/2)
fn geo(a: M, b: M, t: f64) -> M {
    let (h, ih) = (fun(a, &|x: f64| x.sqrt()), fun(a, &|x: f64| 1.0 / x.sqrt()));
    mul(mul(h, fun(mul(mul(ih, b), ih), &|x: f64| x.powf(t))), h)
}
fn ai_log(p: M, q: M) -> M { let ih = fun(p, &|x: f64| 1.0 / x.sqrt()); fun(mul(mul(ih, q), ih), &f64::ln) }
fn d_ai(p: M, q: M) -> f64 { fro(ai_log(p, q)) }
fn d_le(p: M, q: M) -> f64 { fro(lin(fun(p, &f64::ln), fun(q, &f64::ln), 1.0, -1.0)) }
fn mean_le(p: M, q: M) -> M { fun(lin(fun(p, &f64::ln), fun(q, &f64::ln), 0.5, 0.5), &f64::exp) }
// road 2: add up sqrt(tr((P^-1 dP)^2)) over n small steps
fn length(path: &dyn Fn(f64) -> M, n: usize) -> f64 {
    let mut tot = 0.0;
    for k in 0..n {
        let (p0, p1) = (path(k as f64 / n as f64), path((k + 1) as f64 / n as f64));
        let x = mul(inv(lin(p0, p1, 0.5, 0.5)), lin(p1, p0, 1.0, -1.0));
        tot += tr(mul(x, x)).sqrt();
    }
    tot
}
fn ang(x: M, y: M) -> f64 { (tr(mul(x, y)) / (fro(x) * fro(y))).acos().to_degrees() }
fn main() {
    let (a, b): (M, M) = ([16.0, 2.0, 2.0, 4.0], [36.0, 9.0, 9.0, 9.0]); // calm and stress estimates, monthly returns in %
    show("calm A", a); show("stress B", b);
    for (nm, m) in [("A", a), ("B", b), ("C", [9.0, -3.0, -3.0, 9.0])] {
        println!("{}: stock volatility {:.2}%, bond volatility {:.2}%, correlation {:.4}", nm, m[0].sqrt(), m[3].sqrt(), corr(m));
    }
    println!("one asset: growth {:.2}, arithmetic {:.6}, geometric {:.6}, ratio {:.6}, distance {:.6}", 36.0 / 16.0, (16.0 + 36.0) / 2.0, (16.0f64 * 36.0).sqrt(), (36.0f64 / 16.0).sqrt(), (36.0f64 / 16.0).ln());
    let aib = mul(inv(a), b); let q = (tr(aib).powi(2) - 4.0 * det(aib)).sqrt(); let (l1, l2) = ((tr(aib) + q) / 2.0, (tr(aib) - q) / 2.0);
    println!("A^-1 B: trace {:.6}, det {:.6}, eigenvalues {:.6} and {:.6}", tr(aib), det(aib), l1, l2);
    let qf = |m: M, w: (f64, f64)| m[0]*w.0*w.0 + 2.0*m[1]*w.0*w.1 + m[3]*w.1*w.1;
    let rq: Vec<f64> = (0..20000).map(|k| { let th = k as f64 * std::f64::consts::PI / 20000.0; let w = (th.cos(), th.sin()); qf(b, w) / qf(a, w) }).collect();
    let (mx, mn) = (rq.iter().cloned().fold(f64::MIN, f64::max), rq.iter().cloned().fold(f64::MAX, f64::min));
    println!("scan of mixes: largest risk ratio {:.6}, smallest {:.6}", mx, mn);
    assert!((mx - l1).abs() < 1e-6 && (mn - l2).abs() < 1e-6);
    let dai = (l1.ln().powi(2) + l2.ln().powi(2)).sqrt();
    println!("ln {:.1} = {:.6}, ln {:.1} = {:.6}, affine-invariant distance {:.6}", l1, l1.ln(), l2, l2.ln(), dai);
    assert!((dai - d_ai(a, b)).abs() < 1e-12);
    let g1 = geo(a, b, 0.5);
    let (al, be) = (det(a).sqrt(), det(b).sqrt()); let s = lin(a, b, 1.0 / al, 1.0 / be);
    println!("closed form: sqrt det A {:.6}, sqrt det B {:.6}, det S {:.6}, scale {:.6}", al, be, det(s), (al * be / det(s)).sqrt());
    show("S = A/sqrt det A + B/sqrt det B", s);
    let g2 = lin(s, s, (al * be / det(s)).sqrt(), 0.0); // road 2: 2x2 closed form
    let h = sqrt_db(a); let ih = inv(h); let g3 = mul(mul(h, sqrt_db(mul(mul(ih, b), ih))), h); // road 3: Denman-Beavers
    show("affine-invariant mean", g1);
    println!("closed form and Denman-Beavers roads agree within 1e-9: {}", yn(gap(g1, g2) < 1e-9 && gap(g1, g3) < 1e-9));
    assert!(gap(g1, g2) < 1e-9 && gap(g1, g3) < 1e-9);
    println!("G A^-1 G = B within 1e-9: {}", yn(gap(mul(mul(g1, inv(a)), g1), b) < 1e-9));
    assert!(gap(mul(mul(g1, inv(a)), g1), b) < 1e-9);
    let d = mul(inv(a), g1); let qd = (tr(d).powi(2) - 4.0 * det(d)).sqrt();
    println!("ratios of G to A: {:.6} and {:.6}, square roots of {:.1} and {:.1}", (tr(d) + qd) / 2.0, (tr(d) - qd) / 2.0, l1, l2);
    assert!(((tr(d) + qd) / 2.0 - l1.sqrt()).abs() < 1e-9 && ((tr(d) - qd) / 2.0 - l2.sqrt()).abs() < 1e-9);
    println!("d(A, G) {:.6}, d(G, B) {:.6}, half of d(A, B) {:.6}", d_ai(a, g1), d_ai(g1, b), dai / 2.0);
    assert!((d_ai(a, g1) - dai / 2.0).abs() < 1e-9 && (d_ai(g1, b) - dai / 2.0).abs() < 1e-9);
    let (gp, sp) = (|t: f64| geo(a, b, t), |t: f64| lin(a, b, 1.0 - t, t));
    for n in [10, 100] { println!("length by {} steps: geodesic {:.6}, straight line {:.6}", n, length(&gp, n), length(&sp, n)); }
    assert!((length(&gp, 100) - dai).abs() < 1e-4 && length(&sp, 100) > dai + 0.001);
    let (la, lb) = (fun(a, &f64::ln), fun(b, &f64::ln));
    println!("eigenvalues: A {:.6}, {:.6}; B {:.6}, {:.6}", eig(a).1, eig(a).0, eig(b).1, eig(b).0);
    show("log A", la); show("log B", lb);
    println!("log by series agrees within 1e-9: {}", yn(gap(la, log_ser(a)).max(gap(lb, log_ser(b))) < 1e-9));
    assert!(gap(la, log_ser(a)) < 1e-9 && gap(lb, log_ser(b)) < 1e-9);
    let dle = fro(lin(la, lb, 1.0, -1.0)); let le1 = mean_le(a, b); let le2 = exp_ser(lin(log_ser(a), log_ser(b), 0.5, 0.5));
    show("average of logs", lin(la, lb, 0.5, 0.5)); println!("log-Euclidean distance {:.6}", dle);
    show("log-Euclidean mean", le1); println!("series road agrees within 1e-9: {}", yn(gap(le1, le2) < 1e-9));
    assert!(gap(le1, le2) < 1e-9);
    let (ar, hm) = (lin(a, b, 0.5, 0.5), inv(lin(inv(a), inv(b), 0.5, 0.5)));
    show("arithmetic mean", ar); show("mean of inverses, inverted", hm);
    for (nm, m) in [("arithmetic", ar), ("inverses", hm), ("log-Euclidean", le1), ("affine-invariant", g1)] {
        println!("{}: det {:.6}, smallest variance {:.6}, correlation {:.6}", nm, det(m), eig(m).0, corr(m));
    }
    println!("det A {:.6}, det B {:.6}, sqrt(det A det B) {:.6}", det(a), det(b), (det(a) * det(b)).sqrt());
    println!("arithmetic det over geometric det: {:.4}", det(ar) / (det(a) * det(b)).sqrt());
    assert!((det(g1) - (det(a) * det(b)).sqrt()).abs() < 1e-9 && (det(le1) - (det(a) * det(b)).sqrt()).abs() < 1e-9);
    let (ia, il) = (gap(inv(geo(inv(a), inv(b), 0.5)), g1) < 1e-9, gap(inv(mean_le(inv(a), inv(b))), le1) < 1e-9);
    println!("mean of inverses, inverted, equals the mean: affine-invariant {}, log-Euclidean {}", yn(ia), yn(il));
    assert!(ia && il);
    let w: M = [1.0, 0.0, 0.0, 100.0]; let (a2, b2) = (mul(mul(w, a), w), mul(mul(w, b), w)); // bonds in basis points
    let (g4, l4) = (geo(a2, b2, 0.5), mean_le(a2, b2));
    println!("bonds in basis points: affine-invariant distance {:.6}, log-Euclidean distance {:.6}", d_ai(a2, b2), d_le(a2, b2));
    println!("stock variance of mean: affine-invariant {:.4} (was {:.4}), log-Euclidean {:.4} (was {:.4})", g4[0], g1[0], l4[0], le1[0]);
    println!("correlation of mean: affine-invariant {:.6}, log-Euclidean {:.6}", corr(g4), corr(l4));
    assert!((d_ai(a2, b2) - dai).abs() < 1e-9 && gap(g4, mul(mul(w, g1), w)) < 1e-6 && (l4[0] - le1[0]).abs() > 0.3);
    let (e1, e2) = (lin(a, b, 2.0, -1.0), geo(a, b, -1.0));
    show("straight line at t = -1", e1); show("geodesic at t = -1", e2); show("A B^-1 A", mul(mul(a, inv(b)), a));
    assert!(gap(e2, mul(mul(a, inv(b)), a)) < 1e-9 && e1[0] < 0.0 && eig(e2).0 > 0.0);
    let ts: Vec<f64> = (0..9).map(|k| k as f64 / 4.0 - 1.0).collect();
    let row = |f: &dyn Fn(f64) -> String| ts.iter().map(|&t| f(t)).collect::<Vec<_>>().join(", ");
    println!("chart t: {}", row(&|t| format!("{:.2}", t)));
    println!("chart straight: {}", row(&|t| format!("{:.2}", eig(lin(a, b, 1.0 - t, t)).0)));
    println!("chart geodesic: {}", row(&|t| format!("{:.2}", eig(geo(a, b, t)).0)));
    let cm: M = [9.0, -3.0, -3.0, 9.0]; // third estimate, from a decade when bonds hedged stocks
    show("third estimate C", cm);
    let tri = [(a, b, cm), (b, cm, a), (cm, a, b)];
    let sai: f64 = tri.iter().map(|&(p, q, r)| ang(ai_log(p, q), ai_log(p, r))).sum();
    let lg = |p: M, q: M| lin(fun(q, &f64::ln), fun(p, &f64::ln), 1.0, -1.0);
    let sle: f64 = tri.iter().map(|&(p, q, r)| ang(lg(p, q), lg(p, r))).sum();
    println!("triangle A, B, C angle sum: affine-invariant {:.4} deg, log-Euclidean {:.4} deg", sai, sle);
    assert!(sai < 179.0 && (sle - 180.0).abs() < 1e-9);
    // try changing: the box's four answers, computed without editing the settings above
    let (f0, w10, bn): (M, M, M) = ([16.0, 0.0, 0.0, 4.0], [1.0, 0.0, 0.0, 10.0], [20.0, 3.0, 3.0, 5.0]);
    let rn = mul(inv(a), bn); let qn = (tr(rn).powi(2) - 4.0 * det(rn)).sqrt();
    let sflat: f64 = [(a, b, f0), (b, f0, a), (f0, a, b)].iter().map(|&(p, q, r)| ang(ai_log(p, q), ai_log(p, r))).sum();
    let dn = length(&|t| lin(a, bn, 1.0 - t, t), 100) - length(&|t| geo(a, bn, t), 100);
    println!("try: bonds in tenths of a percent, log-Euclidean stock variance {:.4}; flat triangle C = (16, 0, 0, 4), affine-invariant angle sum {:.4} deg",
             mean_le(mul(mul(w10, a), w10), mul(mul(w10, b), w10))[0], sflat);
    println!("try: B = (20, 3, 3, 5): risk ratios {:.6} and {:.6}, distance {:.6}, straight line longer by {:.6} at 100 steps", (tr(rn) + qn) / 2.0, (tr(rn) - qn) / 2.0, d_ai(a, bn), dn);
    show("try: weight one quarter, geodesic at t = 0.25", geo(a, b, 0.25));
    println!("ALL CHECKS PASS");
}
