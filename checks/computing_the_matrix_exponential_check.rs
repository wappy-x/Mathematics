// Computing e^A -- the check behind the card.  std only, no crates.
// Moler and Van Loan's A = [[-49, 24], [-64, 31]], eigenvalues -1 and -17.
// Roads to e^A: (1) interpolating e^x at the eigenvalues, (2) eigenvectors V e^D V^-1,
// (3) the Taylor series in floating point, (4) scaling and squaring with Pade [6/6].
// Then the square root and the logarithm of e^A through its Schur form.
// f64::exp and f64::ln are the library's, used for scalars only.
type M = [[f64; 2]; 2];
const I: M = [[1.0, 0.0], [0.0, 1.0]];
const U: f64 = 1.0 / 9007199254740992.0; // 2^-53
fn mul(x: &M, y: &M) -> M {
    let f = |i: usize, j: usize| x[i][0] * y[0][j] + x[i][1] * y[1][j];
    [[f(0, 0), f(0, 1)], [f(1, 0), f(1, 1)]]
}
fn lin(a: f64, x: &M, b: f64, y: &M) -> M {
    let f = |i: usize, j: usize| a * x[i][j] + b * y[i][j];
    [[f(0, 0), f(0, 1)], [f(1, 0), f(1, 1)]]
}
fn inv(x: &M) -> M {
    let d = x[0][0] * x[1][1] - x[0][1] * x[1][0];
    [[x[1][1] / d, -x[0][1] / d], [-x[1][0] / d, x[0][0] / d]]
}
fn tr(x: &M) -> M { [[x[0][0], x[1][0]], [x[0][1], x[1][1]]] }
fn n1(x: &M) -> f64 { (0..2).map(|j| x[0][j].abs() + x[1][j].abs()).fold(f64::MIN, f64::max) } // largest column total
fn rel(x: &M, y: &M) -> f64 { n1(&lin(1.0, x, -1.0, y)) / n1(y) }
fn sci(v: f64) -> String { // Python's {:.3e}: signed two-digit exponent
    let s = format!("{:.3e}", v);
    let (m, e) = s.split_once('e').unwrap();
    let e: i32 = e.parse().unwrap();
    format!("{}e{}{:02}", m, if e < 0 { '-' } else { '+' }, e.abs())
}
fn fm(x: &M, d: usize) -> String {
    let r: Vec<String> = x.iter().map(|r| format!("{:.*}, {:.*}", d, r[0], d, r[1])).collect();
    format!("[[{}]]", r.join("], ["))
}
fn interp(x: &M, l1: f64, l2: f64) -> M { // e^X = (e^l1 (X - l2 I) - e^l2 (X - l1 I)) / (l1 - l2)
    lin(l1.exp() / (l1 - l2), &lin(1.0, x, -l2, &I), -l2.exp() / (l1 - l2), &lin(1.0, x, -l1, &I))
}
fn eigvec(x: &M, l1: f64, l2: f64) -> (M, f64) { // V e^D V^-1 with eigenvectors (x12, l - x11)
    let v = [[x[0][1], x[0][1]], [l1 - x[0][0], l2 - x[0][0]]];
    (mul(&mul(&v, &[[l1.exp(), 0.0], [0.0, l2.exp()]]), &inv(&v)), n1(&v) * n1(&inv(&v)))
}
fn taylor(x: &M, terms: usize) -> (M, Vec<f64>) {
    let (mut s, mut t, mut big) = (I, I, vec![]);
    for k in 1..terms {
        t = lin(1.0 / k as f64, &mul(&t, x), 0.0, &I);
        s = lin(1.0, &s, 1.0, &t);
        big.push(t.iter().flatten().fold(0.0, |m: f64, v| m.max(v.abs())));
    }
    (s, big)
}
fn fac(k: u64) -> f64 { (1..=k).fold(1.0, |p, i| p * i as f64) }
fn ifac(k: u64) -> u64 { (1..=k).product() }
fn gcd(a: u64, b: u64) -> u64 { if b == 0 { a } else { gcd(b, a % b) } }
fn coef() -> [f64; 7] { let mut c = [0.0; 7]; for k in 0..7 { c[k] = fac(12 - k as u64) * fac(6) / (fac(12) * fac(k as u64) * fac(6 - k as u64)); } c }
fn cerr() -> f64 { fac(6) * fac(6) / (fac(12) * fac(13)) } // e^x - r(x) ~ CERR x^13
fn pade6(x: &M) -> M { // N = E + O, D = E - O: even and odd parts, four products
    let c = coef();
    let x2 = mul(x, x); let x4 = mul(&x2, &x2); let x6 = mul(&x4, &x2);
    let e = lin(1.0, &lin(c[0], &I, c[2], &x2), 1.0, &lin(c[4], &x4, c[6], &x6));
    let o = mul(x, &lin(1.0, &lin(c[1], &I, c[3], &x2), c[5], &x4));
    mul(&inv(&lin(1.0, &e, -1.0, &o)), &lin(1.0, &e, 1.0, &o))
}
fn sc(x: &M, s: i32) -> M { lin(2f64.powi(-s), x, 0.0, &I) }
fn expm(x: &M, s: i32) -> M { let mut r = pade6(&sc(x, s)); for _ in 0..s { r = mul(&r, &r); } r }
fn pw(x: &M, k: usize) -> M { let mut p = I; for _ in 0..k { p = mul(&p, x); } p }
fn choose_s(x: &M) -> i32 { // smallest s with leading backward error CERR ||X^13|| / ||X|| <= u
    let mut s = 0;
    while cerr() * n1(&pw(&sc(x, s), 13)) / n1(&sc(x, s)) > U { s += 1; }
    s
}
fn schur(m: &M) -> (M, M) { // real 2 by 2, real eigenvalues: M = Q T Q^T
    let t = m[0][0] + m[1][1];
    let l1 = t / 2.0 + (((m[0][0] - m[1][1]).powf(2.0) / 4.0 + m[0][1] * m[1][0]).sqrt()).copysign(t);
    let (a, b) = ((m[0][1], l1 - m[0][0]), (l1 - m[1][1], m[1][0]));
    let q = if a.0.abs() + a.1.abs() >= b.0.abs() + b.1.abs() { a } else { b };
    let r = (q.0.powf(2.0) + q.1.powf(2.0)).sqrt();
    let qm = [[q.0 / r, -q.1 / r], [q.1 / r, q.0 / r]];
    (qm, mul(&tr(&qm), &mul(m, &qm)))
}
fn tsqrt(t: &M) -> M { let (r1, r2) = (t[0][0].sqrt(), t[1][1].sqrt()); [[r1, t[0][1] / (r1 + r2)], [0.0, r2]] }
fn main() {
    let a: M = [[-49.0, 24.0], [-64.0, 31.0]];
    let refm = interp(&a, -1.0, -17.0);
    let (ev, kv) = eigvec(&a, -1.0, -17.0);
    println!("A = [[-49, 24], [-64, 31]]; trace {:.1}, det {:.1} -> eigenvalues -1, -17", a[0][0] + a[1][1], a[0][0] * a[1][1] - a[0][1] * a[1][0]);
    println!("interpolation e^A = {}", fm(&refm, 7));
    println!("eigenvectors  e^A = {}; kappa(V) = {:.1}; rel diff {}", fm(&ev, 7), kv, sci(rel(&ev, &refm)));
    assert!((refm[0][0] + 2.0 * (-1f64).exp() - 3.0 * (-17f64).exp()).abs() < 1e-15 && rel(&ev, &refm) < 1e-14);
    let (ts, big) = taylor(&a, 150);
    let mut kmax = 1;
    for k in 0..big.len() { if big[k] > big[kmax - 1] { kmax = k + 1; } }
    println!("Taylor in doubles: {}; rel error {}", fm(&ts, 7), sci(rel(&ts, &refm)));
    println!("largest term entry {} at k = {}; 17^17/17! = {}; times u {}", sci(big[kmax - 1]), kmax, sci(17f64.powf(17.0) / fac(17)), sci(big[kmax - 1] * U));
    assert!(1e-10 < rel(&ts, &refm) && rel(&ts, &refm) < 1e-7);
    let fr: Vec<String> = (0..7u64).map(|k| { let (p, q) = (ifac(12 - k) * 720, ifac(12) * ifac(k) * ifac(6 - k)); format!("{}/{}", p / gcd(p, q), q / gcd(p, q)) }).collect();
    println!("Pade [6/6] c_k: {}", fr.join(", "));
    let c = coef();
    let ec: Vec<f64> = (0..14).map(|k| 1.0 / fac(k)).collect();
    let mut res = vec![];
    for k in 0..14usize { // coefficient of x^k in Q(x) e^x - P(x), Q(x) = P(-x)
        let mut acc = 0.0;
        for j in 0..=k.min(6) { acc += c[j] * (-1f64).powi(j as i32) * ec[k - j]; }
        res.push(acc - if k <= 6 { c[k] } else { 0.0 });
    }
    let r12 = res[..13].iter().fold(0.0, |m: f64, v| m.max(v.abs()));
    println!("Q e^x - P, terms x^0..x^12: max size {}; x^13 term {}; (6!)^2/(12! 13!) = {}", sci(r12), sci(res[13]), sci(cerr()));
    assert!(r12 < 1e-15 && (res[13].abs() / cerr() - 1.0).abs() < 1e-9);
    println!("s, ||X||, ||X^13||^(1/13), leading backward error:");
    for s in 3..7 {
        let x = sc(&a, s);
        println!("  {}, {:.4}, {:.4}, {}", s, n1(&x), n1(&pw(&x, 13)).powf(1.0 / 13.0), sci(cerr() * n1(&pw(&x, 13)) / n1(&x)));
    }
    let s = choose_s(&a);
    let mut mvl = 0;
    while n1(&a) * 2f64.powi(-mvl) > 0.5 { mvl += 1; }
    let eps66 = 2f64.powi(3 - 12) * fac(6) * fac(6) / (fac(12) * fac(13));
    let e = expm(&a, s);
    println!("chosen s = {}; guaranteed rule ||X|| <= 1/2 gives s = {}, bound {} ||X||", s, mvl, sci(eps66));
    println!("scaling and squaring e^A = {}", fm(&e, 7));
    println!("rel error {}; ||A|| u = {}; ratio {:.2}", sci(rel(&e, &refm)), sci(n1(&a) * U), rel(&e, &refm) / (n1(&a) * U));
    assert!(s == 5 && mvl == 8 && rel(&e, &refm) < 1e2 * n1(&a) * U);
    let b17 = cerr() * 8.0 * (17.0f64 / 8.0).powf(13.0);
    println!("s = 3: backward error on the -17 mode {}; seen in e^A as e^-17 x that = {}", sci(b17), sci((-17f64).exp() * b17));
    let sweep: Vec<f64> = (0..12).map(|k| rel(&expm(&a, k), &refm)).collect();
    println!("chart, s: {}", (0..12).map(|k| k.to_string()).collect::<Vec<_>>().join(", "));
    println!("chart, log10 rel error: {}", sweep.iter().map(|v| format!("{:.2}", v.log10())).collect::<Vec<_>>().join(", "));
    assert!(sweep[0] > 1e-3 && sweep[11] > 10.0 * sweep[5]);
    let big0: Vec<f64> = std::iter::once(1.0).chain(big.iter().cloned()).collect();
    println!("chart, log10 largest Taylor term, k = 0..40 by 4: {}", (0..41).step_by(4).map(|k| format!("{:.2}", big0[k].log10())).collect::<Vec<_>>().join(", "));
    let hump = (1..1001).map(|t| t as f64 / 1000.0).map(|tt| (n1(&interp(&lin(tt, &a, 0.0, &I), -tt, -17.0 * tt)), tt))
        .fold((0.0, 0.0), |h, v| if v.0 > h.0 { v } else { h });
    let mid: Vec<f64> = [0.125, 0.25].iter().map(|&t| n1(&interp(&lin(t, &a, 0.0, &I), -t, -17.0 * t))).collect(); // e^(A/8), e^(A/4): squarings for s = 5
    println!("hump: ||e^(tA)|| peaks at {:.4} at t = {:.3}; at t = 1/8, 1/4: {:.4}, {:.4}; at t = 1: {:.4}", hump.0, hump.1, mid[0], mid[1], n1(&refm));
    assert!(hump.0 > 4.0 && (hump.1 - 0.15f64).abs() < 0.1 && mid[0].min(mid[1]) > n1(&refm));
    let d = 2f64.powi(-30); // nearly defective: B = [[-1, 1], [0, -1 + d]]
    let b: M = [[-1.0, 1.0], [0.0, -1.0 + d]];
    let phi = 1.0 + d / 2.0 + d * d / 6.0; // (e^d - 1)/d by its series: no cancellation
    let bx: M = [[(-1f64).exp(), (-1f64).exp() * phi], [0.0, (-1.0 + d).exp()]];
    let (bv, kb) = eigvec(&b, -1.0, -1.0 + d);
    let bt = [rel(&bv, &bx), rel(&expm(&b, choose_s(&b)), &bx), rel(&taylor(&b, 40).0, &bx)];
    println!("near-defective B, gap 2^-30: kappa(V) = {}; kappa(V) u = {}", sci(kb), sci(kb * U));
    println!("  rel error: eigenvectors {}, scaling and squaring (s = {}) {}, Taylor {}; eigenvectors / (kappa(V) u) = {:.3}", sci(bt[0]), choose_s(&b), sci(bt[1]), sci(bt[2]), bt[0] / (kb * U));
    assert!(bt[0] > 1e5 * bt[1] && bt[1] < 1e-15 && bt[2] < 1e-15);
    let (q, t) = schur(&refm);
    println!("Schur form of e^A: diagonal {:.10}, {}; corner {:.7}; below {}", t[0][0], sci(t[1][1]), t[0][1], sci(t[1][0].abs()));
    let r = mul(&q, &mul(&tsqrt(&t), &tr(&q)));
    let h = interp(&lin(0.5, &a, 0.0, &I), -0.5, -8.5);
    println!("square root = {}; vs e^(A/2): rel error {}; residual R^2 - M: {}", fm(&r, 7), sci(rel(&r, &h)), sci(rel(&mul(&r, &r), &refm)));
    assert!(rel(&r, &h) < 1e-10 && rel(&mul(&r, &r), &refm) < 1e-14);
    let (mut w, mut k) = ([[t[0][0], t[0][1]], [0.0, t[1][1]]], 0);
    while (w[0][0] - 1.0).abs().max((w[1][1] - 1.0).abs()) > 0.25 { w = tsqrt(&w); k += 1; }
    let (x, mut p, mut l) = (lin(1.0, &w, -1.0, &I), I, [[0.0; 2]; 2]);
    for j in 1..40 { p = mul(&p, &x); l = lin(1.0, &l, (-1f64).powi(j + 1) / j as f64, &p); } // log(I + X)
    let lg = mul(&q, &mul(&lin(2f64.powi(k), &l, 0.0, &I), &tr(&q)));
    let dd = t[0][1] * (t[1][1].ln() - t[0][0].ln()) / (t[1][1] - t[0][0]);
    let lp = mul(&q, &mul(&[[t[0][0].ln(), dd], [0.0, t[1][1].ln()]], &tr(&q)));
    println!("log by {} square roots + series: {}; rel error vs A {}", k, fm(&lg, 9), sci(rel(&lg, &a)));
    println!("log by Parlett's divided difference: rel error vs A {}; u ||e^A|| / (e^-17 ||A||) = {}; ratio {:.2}", sci(rel(&lp, &a)), sci(U * n1(&refm) / ((-17f64).exp() * n1(&a))), rel(&lp, &a) / (U * n1(&refm) / ((-17f64).exp() * n1(&a))));
    assert!(rel(&lg, &a) < 1e-9 && rel(&lp, &lg) < 1e-12);
    println!("mistake, Pade [6/6] with no scaling (s = 0): rel error {}", sci(sweep[0]));
    println!("mistake, over-scaling s = 11: rel error {}, {:.0} times s = 5; 2^6 = {}", sci(sweep[11]), sweep[11] / sweep[5], 2i32.pow(6));
    let kt = (kmax..big.len()).find(|&k| big[k - 1] < U).unwrap();
    println!("flops at n = 100: [6/6] with s = 5: {}; Taylor, {} terms until a term < u: {}", sci(9.0 * 2e6 + 8e6 / 3.0), kt, sci(kt as f64 * 2e6));
    for g in [2f64.powi(-20), 2f64.powi(-40)] {
        let bg: M = [[-1.0, 1.0], [0.0, -1.0 + g]];
        let bgx: M = [[(-1f64).exp(), (-1f64).exp() * (1.0 + g / 2.0 + g * g / 6.0)], [0.0, (-1.0 + g).exp()]];
        println!("try: gap {}: eigenvectors {}; scaling and squaring {}", sci(g), sci(rel(&eigvec(&bg, -1.0, -1.0 + g).0, &bgx)), sci(rel(&expm(&bg, choose_s(&bg)), &bgx)));
    }
    println!("ALL CHECKS PASS");
}
