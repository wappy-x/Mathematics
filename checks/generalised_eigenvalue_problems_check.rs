// Generalised eigenproblems -- the check behind the card.  std only; nothing used holds an answer.
// Masses 2 kg and 1 kg, springs 3 N/m (wall to first mass) and 2 N/m (between): K x = lam M x.
// Roots of det(K - lam M), Cholesky reduction, M-orthogonal modes, a light second mass down to a
// massless one, eigenvalue counts by Sylvester's law, and shift-invert Lanczos on a 200-mass chain.
use std::f64::consts::PI;
const U: f64 = 1.0 / 9007199254740992.0;
const X0: [f64; 2] = [0.10, 0.0];
const T: f64 = 5.0; const H: f64 = 1e-3; const NCH: usize = 200; const KL: usize = 12;
const DIAL: [f64; 5] = [1.0, 1e-2, 1e-4, 1e-6, 1e-8];
fn sci(x: f64) -> String { format!("{:.3e}", x) }
fn row(label: &str, vals: &[f64]) { println!("{:<42}{}", label, vals.iter().map(|v| format!("{:>12.6}", v)).collect::<String>()); }
fn srow(label: &str, vals: &[f64]) { println!("{:<42}{}", label, vals.iter().map(|v| format!("{:>12}", sci(*v))).collect::<String>()); }
fn eig2(p: f64, q: f64, r: f64) -> (f64, f64) { // textbook formula for [[p, q], [q, r]]: half-trace -/+ root
    let h = (p + r) / 2.0; let s = (h * h - (p * r - q * q)).sqrt();
    (h - s, h + s)
}
fn eig3(c: (f64, f64, f64)) -> (f64, f64) { eig2(c.0, c.1, c.2) }
fn exact(m2: f64) -> (f64, f64) { // det(K - lam M) = 2 m2 lam^2 - (4 + 5 m2) lam + 6, no cancellation
    let (a, b) = (2.0 * m2, 4.0 + 5.0 * m2);
    let lo = 12.0 / (b + (b * b - 24.0 * a).sqrt());
    (lo, if a > 0.0 { 6.0 / (a * lo) } else { f64::INFINITY })
}
fn via_m(m2: f64) -> (f64, f64, f64) { // reduce with M = L L^T: C = L^-1 K L^-T
    let (l1, l2) = (2.0f64.sqrt(), m2.sqrt());
    (5.0 / (l1 * l1), -2.0 / (l1 * l2), 2.0 / (l2 * l2))
}
fn via_k(m2: f64) -> (f64, f64, f64) { // reduce with K = G G^T: B = G^-1 M G^-T has eigenvalues 1/lam
    let g11 = 5.0f64.sqrt(); let g21 = -2.0 / g11; let g22 = (2.0 - g21 * g21).sqrt();
    (2.0 / (g11 * g11), -2.0 * g21 / (g11 * g11 * g22), 2.0 * g21 * g21 / (g11 * g11 * g22 * g22) + m2 / (g22 * g22))
}
fn count_below(a: &[f64], b: &[f64], m: &[f64], s: f64) -> usize { // negative pivots of K - s M = L D L^T
    let (mut n, mut d) = (0, 1.0);
    for i in 0..a.len() {
        d = a[i] - s * m[i] - if i > 0 { b[i - 1] * b[i - 1] / d } else { 0.0 };
        if d == 0.0 { d = -1e-300; }
        if d < 0.0 { n += 1; }
    }
    n
}
fn bisect(a: &[f64], b: &[f64], m: &[f64], j: usize) -> f64 { // j-th smallest eigenvalue of the tridiagonal pencil
    let mut bb = vec![0.0]; bb.extend(b.iter().map(|v| v.abs())); bb.push(0.0);
    let mut hi = (0..a.len()).map(|i| (a[i].abs() + bb[i] + bb[i + 1]) / m[i]).fold(f64::MIN, f64::max);
    let mut lo = -hi;
    for _ in 0..200 {
        let mid = (lo + hi) / 2.0;
        if count_below(a, b, m, mid) >= j { hi = mid; } else { lo = mid; }
    }
    (lo + hi) / 2.0
}
fn mdot(x: &[f64], y: &[f64], m: &[f64]) -> f64 { let mut s = 0.0; for i in 0..x.len() { s += m[i] * x[i] * y[i]; } s }
fn kmul(a: &[f64], b: &[f64], x: &[f64]) -> Vec<f64> {
    let n = x.len();
    (0..n).map(|i| a[i] * x[i] + if i > 0 { b[i - 1] * x[i - 1] } else { 0.0 } + if i < n - 1 { b[i] * x[i + 1] } else { 0.0 }).collect()
}
fn lanczos(op: &dyn Fn(&[f64]) -> Vec<f64>, m: &[f64], k: usize) -> (Vec<f64>, Vec<f64>) { // M inner product, full reorthogonalisation
    let q = vec![1.0; m.len()]; let s = mdot(&q, &q, m);
    let mut qs: Vec<Vec<f64>> = vec![q.iter().map(|v| v / s.sqrt()).collect()];
    let (mut al, mut be) = (Vec::new(), Vec::new());
    for _ in 0..k {
        let last = qs.last().unwrap().clone();
        let mut w = op(&last); al.push(mdot(&w, &last, m));
        for _ in 0..2 { for qq in &qs { let c = mdot(&w, qq, m); for i in 0..w.len() { w[i] -= c * qq[i]; } } }
        let s = mdot(&w, &w, m).sqrt(); be.push(s); qs.push(w.iter().map(|v| v / s).collect());
    }
    (al, be)
}
fn ritz(lz: &(Vec<f64>, Vec<f64>), k: usize, j: usize, inv: bool) -> f64 {
    let ones = vec![1.0; k];
    if inv { 1.0 / bisect(&lz.0[..k], &lz.1[..k - 1], &ones, k + 1 - j) } else { bisect(&lz.0[..k], &lz.1[..k - 1], &ones, j) }
}
fn acc(x: &[f64; 2]) -> [f64; 2] { [-(5.0 * x[0] - 2.0 * x[1]) / 2.0, -(-2.0 * x[0] + 2.0 * x[1])] }
fn comma(k: usize) -> String {
    let (s, mut out) = (k.to_string(), String::new());
    for (i, ch) in s.chars().enumerate() { if i > 0 && (s.len() - i) % 3 == 0 { out.push(','); } out.push(ch); }
    out
}
fn main() {
    let (l1, l2) = exact(1.0); let om = [l1.sqrt(), l2.sqrt()];
    row("det(K - lam M) = a lam^2 + b lam + c", &[2.0, -9.0, 6.0]);
    row("lam1, lam2 (1/s^2), stable formula", &[l1, l2]);
    row("omega (rad/s), period (s)", &[om[0], om[1], 2.0 * PI / om[0], 2.0 * PI / om[1]]);
    let (a2, b2, m2v) = ([5.0, 2.0], [-2.0], [2.0, 1.0]);
    let cnt: Vec<String> = [0.5, 2.0, 4.0].iter().map(|s| count_below(&a2, &b2, &m2v, *s).to_string()).collect();
    println!("Sylvester counts below 0.5, 2, 4: [{}]", cnt.join(", "));
    let bl = [bisect(&a2, &b2, &m2v, 1), bisect(&a2, &b2, &m2v, 2)];
    row("lam1, lam2 by bisection on the counts", &bl);
    let c = via_m(1.0); let ce = eig3(c);
    row("L = chol(M) diagonal", &[2.0f64.sqrt(), 1.0]);
    row("C = L^-1 K L^-T: c11 c21 c22, trace, det", &[c.0, c.1, c.2, c.0 + c.2, c.0 * c.2 - c.1 * c.1]);
    row("eigenvalues of C", &[ce.0, ce.1]);
    let v = [[1.0, (5.0 - 2.0 * l1) / 2.0], [1.0, (5.0 - 2.0 * l2) / 2.0]];
    let y = [[c.1, ce.0 - c.0], [c.1, ce.1 - c.0]]; // eigenvectors of C
    let vb: Vec<[f64; 2]> = y.iter().map(|y| [y[0] / 2.0f64.sqrt(), y[1] / 1.0]).map(|w| [1.0, w[1] / w[0]]).collect(); // v = L^-T y
    row("mode shapes v1, v2 (second entry, first = 1)", &[v[0][1], v[1][1]]);
    row("same, from C's eigenvectors y, v = L^-T y", &[vb[0][1], vb[1][1]]);
    row("wrong: C's eigenvectors read as shapes", &[y[0][1] / y[0][0], y[1][1] / y[1][0]]);
    let (km, mm) = ([[5.0, -2.0], [-2.0, 2.0]], [2.0, 1.0]);
    let res: Vec<f64> = [(0, l1), (1, l2)].iter().map(|&(k, lam)| (0..2).map(|i| {
        let mut s = 0.0; for j in 0..2 { s += km[i][j] * v[k][j]; } (s - lam * mm[i] * v[k][i]).abs() }).fold(f64::MIN, f64::max)).collect();
    srow("residuals |K v - lam M v|", &res);
    let pdot = v[0][0] * v[1][0] + v[0][1] * v[1][1]; let mx = mdot(&v[0], &v[1], &mm);
    let mut kx = 0.0; for i in 0..2 { for j in 0..2 { kx += v[0][i] * km[i][j] * v[1][j]; } }
    println!("v1.v2 plain {:.6}   v1^T M v2 {}   v1^T K v2 {}", pdot, sci(mx), sci(kx));
    let cm: Vec<f64> = v.iter().map(|w| mdot(w, &X0, &mm) / mdot(w, w, &mm)).collect();
    let cp: Vec<f64> = v.iter().map(|w| (0.0 + w[0] * X0[0] + w[1] * X0[1]) / (0.0 + w[0] * w[0] + w[1] * w[1])).collect();
    row("release (0.1, 0): c1, c2 (m); v^T M v", &[cm[0], cm[1], mdot(&v[0], &v[0], &mm), mdot(&v[1], &v[1], &mm)]);
    row("rebuilt start c1 v1 + c2 v2 (m)", &[cm[0] * v[0][0] + cm[1] * v[1][0], cm[0] * v[0][1] + cm[1] * v[1][1]]);
    row("wrong: shares by the plain dot", &cp);
    row("wrong: rebuilt start", &[cp[0] * v[0][0] + cp[1] * v[1][0], cp[0] * v[0][1] + cp[1] * v[1][1]]);
    let en: Vec<f64> = (0..2).map(|k| 0.5 * [l1, l2][k] * cm[k] * cm[k] * mdot(&v[k], &v[k], &mm)).collect();
    let esum = 0.0 + en[0] + en[1];
    let e0 = 0.5 * (5.0 * X0[0] * X0[0] - 4.0 * X0[0] * X0[1] + 2.0 * X0[1] * X0[1]); // x^T K x / 2
    row("energy (J): start, mode 1, mode 2, sum", &[e0, en[0], en[1], esum]);
    let (mut x, mut vel) = (X0, [0.0, 0.0]); let mut a0 = acc(&x);
    for _ in 0..(T / H).round() as usize {
        for i in 0..2 { vel[i] += H / 2.0 * a0[i]; } for i in 0..2 { x[i] += H * vel[i]; }
        a0 = acc(&x); for i in 0..2 { vel[i] += H / 2.0 * a0[i]; }
    }
    let xm: Vec<f64> = (0..2).map(|i| 0.0 + cm[0] * (om[0] * T).cos() * v[0][i] + cm[1] * (om[1] * T).cos() * v[1][i]).collect();
    row("x(5 s) from modes; from 5,000 leapfrog steps", &[xm[0], xm[1], x[0], x[1]]);
    let ke = eig2(5.0, -2.0, 2.0);
    row("wrong: eigenvalues of K alone, omegas", &[ke.0, ke.1, ke.0.sqrt(), ke.1.sqrt()]);
    let mut dial = Vec::new();
    for m2 in DIAL {
        let ex = exact(m2).0; let cc = via_m(m2); let (a, big) = eig3(cc); let bk = 1.0 / eig3(via_k(m2)).1;
        let sm = (cc.0 * cc.2 - cc.1 * cc.1) / big; // same C, small root as det(C) / lam_max: no subtraction
        let (em, ek, bd, es) = ((a - ex).abs() / ex, (bk - ex).abs() / ex, U * big / ex, (sm - ex).abs() / ex);
        dial.push((em, ek, bd, es));
        println!("m2 {:>9}  lam1 {:.9}  kappa(M) {:>9}  M h-s {:>9}  M det/max {:>9}  K-route {:>9}  estimate {:>9}  ratio {:.3}",
            sci(m2), ex, sci(if m2 < 2.0 { 2.0 / m2 } else { m2 / 2.0 }), sci(em), sci(es), sci(ek), sci(bd), em / bd);
    }
    let mu = eig3(via_k(0.0));
    println!("m2 0: chol(M) fails (pivot m2 = 0); det(K - lam M) = 6 - 4 lam, lam1 = {:.6}, lam2 = {}", exact(0.0).0, exact(0.0).1);
    println!("m2 0: K-route mu {} {:.6}; lam1 = 1/mu_max = {:.6}; (alpha, beta) = (3, 2), (1, 0)", sci(mu.0), mu.1, 1.0 / mu.1);
    let mc: Vec<f64> = (0..NCH).map(|i| if i % 2 == 0 { 2.0 } else { 1.0 }).collect();
    let mut ks: Vec<f64> = (0..NCH).map(|i| if i % 2 == 0 { 3.0 } else { 2.0 }).collect(); ks.push(0.0);
    let ac: Vec<f64> = (0..NCH).map(|i| ks[i] + ks[i + 1]).collect();
    let bc: Vec<f64> = (0..NCH - 1).map(|i| -ks[i + 1]).collect();
    let rf: Vec<f64> = (1..4).map(|j| bisect(&ac, &bc, &mc, j)).collect();
    let (mut d, mut lf) = (vec![ac[0]], Vec::new());
    for i in 1..NCH { lf.push(bc[i - 1] / d[i - 1]); d.push(ac[i] - lf[i - 1] * bc[i - 1]); }
    let solve = |yv: &[f64]| -> Vec<f64> { // K x = y with the stored L D L^T: 5n - 4 flops
        let mut x = yv.to_vec();
        for i in 1..NCH { x[i] -= lf[i - 1] * x[i - 1]; }
        for i in 0..NCH { x[i] /= d[i]; }
        for i in (0..NCH - 1).rev() { x[i] -= lf[i] * x[i + 1]; }
        x
    };
    let si = lanczos(&|q: &[f64]| solve(&(0..NCH).map(|i| mc[i] * q[i]).collect::<Vec<_>>()), &mc, KL);
    let pl = lanczos(&|q: &[f64]| kmul(&ac, &bc, q).iter().enumerate().map(|(i, t)| t / mc[i]).collect(), &mc, KL);
    let sl: Vec<f64> = (1..4).map(|j| ritz(&si, KL, j, true)).collect(); let pv = ritz(&pl, KL, 1, false);
    srow("chain: lam1..3 by bisection; lam2/lam1", &[rf[0], rf[1], rf[2], rf[1] / rf[0]]);
    srow("shift-invert Lanczos, 12 steps", &sl);
    let rel: Vec<f64> = (0..3).map(|j| (sl[j] - rf[j]).abs() / rf[j]).collect();
    srow("relative gaps to bisection", &rel);
    srow("plain Lanczos lam1, relative gap", &[pv, (pv - rf[0]).abs() / rf[0]]);
    println!("cost: 12 solves of {} flops each = {} flops after the {}-flop factorisation", 5 * NCH - 4, comma(12 * (5 * NCH - 4)), 3 * (NCH - 1));
    for k in 1..=KL {
        let es = (ritz(&si, k, 1, true) - rf[0]).abs() / rf[0]; let ep = (ritz(&pl, k, 1, false) - rf[0]).abs() / rf[0];
        println!("figure, k {}, shift-invert {:.2}, plain {:.2}", k, es.max(1e-16).log10(), ep.max(1e-16).log10());
    }
    assert!([(bl[0] - l1).abs(), (bl[1] - l2).abs(), (ce.0 - l1).abs(), (ce.1 - l2).abs()].iter().all(|e| *e < 1e-12)); // three roads to lam
    assert!((0..2).all(|k| (vb[k][1] - v[k][1]).abs() < 1e-12) && res.iter().all(|r| *r < 1e-14));
    assert!(mx.abs() < 1e-14 && kx.abs() < 1e-13 && (pdot + 1.0).abs() < 1e-12); // M-orthogonal, not plain
    assert!((0..2).all(|i| (xm[i] - x[i]).abs() < 1e-5) && (esum - e0).abs() < 1e-15);
    assert!(dial.iter().all(|t| t.1 < 1e-14 && t.3 < 1e-14) && dial[4].0 > 1e-11 && dial.iter().all(|t| t.0 <= 4.0 * t.2));
    assert!((1.0 / mu.1 - exact(0.0).0).abs() < 1e-15 && rel.iter().all(|e| *e < 1e-10));
    assert!((pv - rf[0]).abs() / rf[0] > 1e-2);
    println!("ALL CHECKS PASS");
}
