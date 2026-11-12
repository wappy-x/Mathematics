// Every root at once -- the check behind the card, in Rust.  std only, no crates.
// Roots of a lease's degree-6 polynomial by bisection, Newton with deflation, and companion eigenvalues.
use std::ops::{Add, Div, Mul, Sub};
const U: f64 = 1.0 / 9007199254740992.0;            // the unit roundoff u = 2^-53
#[derive(Clone, Copy, PartialEq)]
struct Z { re: f64, im: f64 }
fn z(re: f64, im: f64) -> Z { Z { re, im } }
impl Add for Z { type Output = Z; fn add(self, o: Z) -> Z { z(self.re + o.re, self.im + o.im) } }
impl Sub for Z { type Output = Z; fn sub(self, o: Z) -> Z { z(self.re - o.re, self.im - o.im) } }
impl Mul for Z { type Output = Z; fn mul(self, o: Z) -> Z { z(self.re * o.re - self.im * o.im, self.re * o.im + self.im * o.re) } }
impl Div for Z { type Output = Z; fn div(self, o: Z) -> Z { let d = o.re * o.re + o.im * o.im;
    z((self.re * o.re + self.im * o.im) / d, (self.im * o.re - self.re * o.im) / d) } }
fn r(x: f64) -> Z { z(x, 0.0) }                    // a real number as a complex one
fn conj(a: Z) -> Z { z(a.re, -a.im) }
fn cabs(a: Z) -> f64 { (a.re * a.re + a.im * a.im).sqrt() }
fn pos(x: f64) -> f64 { if x > 0.0 { x } else { 0.0 } }
fn csqrt(a: Z) -> Z { let m = cabs(a); z(pos((m + a.re) / 2.0).sqrt(), pos((m - a.re) / 2.0).sqrt().copysign(a.im)) }
fn sci(v: f64) -> String { format!("{:.2e}", v) }
fn trim(v: f64) -> String { let s = format!("{:.7}", v); s.trim_end_matches('0').trim_end_matches('.').to_string() }
fn horner(a: &[Z], x: Z) -> (Z, Z, Vec<Z>) {      // a: highest power first; p(x), p'(x), quotient
    let (mut b, mut d, mut q) = (a[0], r(0.0), vec![]);
    for &c in &a[1..] {
        q.push(b);                                     // the partial sums are the quotient p/(x - z)
        d = d * x + b; b = b * x + c;
    }
    (b, d, q)
}
fn cx(a: &[f64]) -> Vec<Z> { a.iter().map(|&c| r(c)).collect() }
fn backward(a: &[f64], x: Z) -> f64 {              // |p(x)| / sum |a_k| |x|^k, in units of u
    let s: f64 = a.iter().enumerate().map(|(k, c)| c.abs() * cabs(x).powi((a.len() - 1 - k) as i32)).sum();
    cabs(horner(&cx(a), x).0) / s / U
}
fn newton(a: &[Z], mut x: Z, steps: usize) -> (Z, usize) {
    for k in 0..steps {
        let (f, d, _) = horner(a, x);
        let s = f / d; x = x - s;
        if cabs(s) <= 4.0 * U * cabs(x) { return (x, k + 1) }
    }
    (x, steps)
}
fn companion(a: &[f64], sign: f64) -> Vec<Vec<Z>> { // top row -a_(n-1)/a_n ... -a_0/a_n, ones below
    let n = a.len() - 1; let mut c: Vec<Vec<Z>> = (0..n).map(|i| (0..n).map(|j| r(if i == j + 1 { 1.0 } else { 0.0 })).collect()).collect();
    c[0] = a[1..].iter().map(|&v| r(sign * v / a[0])).collect();
    c
}
fn eig(mut h: Vec<Vec<Z>>) -> (Vec<Z>, usize, usize) { // shifted QR by Givens rotations, Hessenberg h
    let (mut m, mut out, mut steps, mut mults) = (h.len(), vec![], 0, 0);
    while m > 1 {
        if cabs(h[m - 1][m - 2]) <= U * (cabs(h[m - 1][m - 1]) + cabs(h[m - 2][m - 2])) {
            out.push(h[m - 1][m - 1]); m -= 1; continue;
        }
        let (a, b, c, d) = (h[m - 2][m - 2], h[m - 2][m - 1], h[m - 1][m - 2], h[m - 1][m - 1]);
        let g = csqrt((a - d) * (a - d) * r(0.25) + b * c); // shift: eigenvalue of the corner nearer d
        let (m1, m2) = ((a + d) * r(0.5) + g, (a + d) * r(0.5) - g);
        let mu = if cabs(m2 - d) < cabs(m1 - d) { m2 } else { m1 }; steps += 1;
        let mut rots = vec![]; assert!(steps < 1000);  // QR must converge, never loop forever
        for i in 0..m { h[i][i] = h[i][i] - mu; }
        for k in 0..m - 1 {                           // h - mu I = Q R, one rotation per column
            let (x, y) = (h[k][k], h[k + 1][k]);
            let rr = (x.re * x.re + x.im * x.im + y.re * y.re + y.im * y.im).sqrt();
            let (cs, sn) = if rr > 0.0 { (x / r(rr), y / r(rr)) } else { (r(1.0), r(0.0)) };
            for j in k..m {
                let (u, v) = (h[k][j], h[k + 1][j]);
                h[k][j] = conj(cs) * u + conj(sn) * v; h[k + 1][j] = cs * v - sn * u;
            }
            rots.push((cs, sn)); mults += 4 * (m - k);
        }
        for (k, &(cs, sn)) in rots.iter().enumerate() { // then R Q + mu I: same eigenvalues
            for i in 0..(k + 2).min(m) {
                let (u, v) = (h[i][k], h[i][k + 1]);
                h[i][k] = u * cs + v * sn; h[i][k + 1] = v * conj(cs) - u * conj(sn);
            }
            mults += 4 * (k + 2).min(m);
        }
        for i in 0..m { h[i][i] = h[i][i] + mu; } }
    out.push(h[0][0]); (out, steps, mults) }
fn order(mut v: Vec<Z>) -> Vec<Z> {                 // largest real part first, then upper half first
    v.sort_by(|p, q| (-(p.re * 1e9).round(), -p.im).partial_cmp(&(-(q.re * 1e9).round(), -q.im)).unwrap()); v }
fn show(x: Z) -> String { let s = format!("{:.10}", x.re);
    if x.im.abs() > 1e-12 { format!("{} {} {:.10}i", s, if x.im < 0.0 { '-' } else { '+' }, x.im.abs()) } else { s } }
fn main() {
    // ---- the lease: p(x) = 10000x^6 - 1500x^5 - 2000x^4 - 2000x^3 - 2500x^2 - 2500x - 1500 ----
    let a = [10000.0, -1500.0, -2000.0, -2000.0, -2500.0, -2500.0, -1500.0];
    let (n, ac) = (a.len() - 1, cx(&a));
    let (p5, dp5, q5) = horner(&ac, r(1.05));
    let (p5, dp5) = (p5.re, dp5.re);
    let naive: f64 = (0..=n).map(|k| a[k] * 1.05f64.powi((n - k) as i32)).sum();
    println!("Horner at x = 1.05: {}", q5.iter().map(|t| trim(t.re)).chain([trim(p5)]).collect::<Vec<_>>().join(", "));
    println!("p(1.05) = {:.7}; by powers {:.7}; p'(1.05) = {:.7}; NPV at 5% = {:.2} dollars; cost {} multiplications and {} additions, by powers {} multiplications",
             p5, naive, dp5, -p5 / 1.05f64.powi(6), n, n, n * (n + 1) / 2);
    assert!((p5 - naive).abs() < 1e-9 && (p5 + 140.9784375).abs() < 1e-9);
    let npv: Vec<String> = (0..11).map(|k| 1.0 + k as f64 / 100.0).map(|x| format!("{:.0}", -horner(&ac, r(x)).0.re / (x * x * x * x * x * x))).collect();
    println!("chart, NPV in dollars at 0% to 10%: {}", npv.join(" "));
    let (mut lo, mut hi) = (1.0f64, 1.1f64);          // road 1: bisection, signs only, to the last bit
    while lo < (lo + hi) / 2.0 && (lo + hi) / 2.0 < hi {
        let mid = (lo + hi) / 2.0; if horner(&ac, r(mid)).0.re < 0.0 { lo = mid } else { hi = mid } }
    let (xn, kn) = newton(&ac, r(1.05), 60);
    println!("bisection root {:.16}; Newton from 1.05: step 1 {:.10}, root {:.16} in {} steps", lo, 1.05 - p5 / dp5, xn.re, kn);
    let (pl, dpl, ql) = horner(&ac, r(lo));
    println!("deflated quotient: {}; remainder {}", ql.iter().map(|c| format!("{:.4}", c.re)).collect::<Vec<_>>().join(", "), sci(pl.re));
    let (mut roads, mut nsteps, mut qd, mut drift) = (vec![], 0, ac.clone(), 0.0f64); // road 2: Newton, deflate, polish on p
    while qd.len() > 1 {
        let (x0, k) = newton(&qd, z(0.5, 0.5), 60); let (x, k2) = newton(&ac, x0, 60); // polish: how far had x0 drifted?
        roads.push(x); nsteps += k + k2; qd = horner(&qd, x).2; drift = drift.max(cabs(x - x0));
    }
    let c = companion(&a, -1.0);
    println!("companion top row: {}", c[0].iter().map(|v| format!("{:.2}", v.re)).collect::<Vec<_>>().join(", "));
    let (ev, qsteps, qmults) = eig(c);                 // road 3: eigenvalues of the companion matrix
    let (ev, roads) = (order(ev), order(roads));
    println!("eigenvalues: {} QR steps, {} complex multiplications; Newton + deflation: {} steps, polishing moved a root at most {}", qsteps, qmults, nsteps, sci(drift));
    for (&x, &w) in ev.iter().zip(roads.iter()) {
        let (e1, e2) = (backward(&a, x), backward(&a, w));
        println!("  {:<31} backward error {:4.1} u, Newton's {:3.1} u, gap {}", show(x), e1, e2, sci(cabs(x - w)));
        assert!(e1 < 50.0 && e2 < 2.0 && cabs(x - w) < 1e-14);
    }
    let (irr, mut s, mut pr) = (ev[0].re, r(0.0), r(1.0));
    for &x in &ev { s = s + x; pr = pr * x; }
    println!("Vieta: sum of roots {:.12} (want 0.15), product {:.12} (want -0.15)", s.re, pr.re);
    assert!((s.re - 0.15).abs() < 1e-13 && (pr.re + 0.15).abs() < 1e-13 && ev[0].im.abs() < 1e-14);
    let sm: f64 = a.iter().enumerate().map(|(k, c)| c.abs() * irr.powi((n - k) as i32)).sum();
    let (kap, rho) = (sm / (irr * dpl.re), 2.0 * n as f64 * U / (1.0 - 2.0 * n as f64 * U) * sm / dpl.re);
    let est = kap * backward(&a, ev[0]) * U * irr;
    println!("IRR = {:.4}% a year; kappa = {:.4}; noise radius {}; QR minus bisection {}, minus Newton {}, estimate kappa eta x* {}",
             100.0 * (irr - 1.0), kap, sci(rho), sci(irr - lo), sci(irr - xn.re), sci(est));
    assert!((irr - lo).abs().max((irr - xn.re).abs()).max((lo - xn.re).abs()) <= 2.0 * rho
            && 0.5 < (irr - xn.re).abs() / est && (irr - xn.re).abs() / est < 2.0);
    let pert: Vec<f64> = a.iter().enumerate().map(|(k, &c)| if k == 0 { c * 1.01 } else { c * 0.99 }).collect();
    let x2 = order(eig(companion(&pert, -1.0)).0)[0].re;
    println!("price +1%, rents -1%: root moves {:.6}, first-order 0.01 kappa x* = {:.6}, IRR {:.4}%", irr - x2, 0.01 * kap * irr, 100.0 * (x2 - 1.0));
    assert!(0.98 < (irr - x2) / (0.01 * kap * irr) && (irr - x2) / (0.01 * kap * irr) < 1.0);
    let dbl = order(eig(companion(&[1.0, -2.7, 2.3625, -0.6615], -1.0)).0); // (x - 1.05)^2 (x - 0.6)
    println!("double root 1.05 of (x - 1.05)^2 (x - 0.6): computed {}, error {}", show(dbl[0]), sci(cabs(dbl[0] - r(1.05))));
    assert!(1e-9 < cabs(dbl[0] - r(1.05)) && cabs(dbl[0] - r(1.05)) < 1e-7);
    let bad = eig(companion(&a, 1.0)).0;               // the top row without its minus signs
    println!("top row without minus signs: {} real eigenvalues, largest real part {:.4}", bad.iter().filter(|x| x.im.abs() < 1e-9).count(), bad.iter().map(|x| x.re).fold(f64::MIN, f64::max));
    assert!(bad.iter().all(|x| x.im.abs() > 0.1));
    let mut same: Vec<String> = [-1.0, -0.6, -0.2, 0.2, 0.6, 1.0].iter().map(|&s| show(newton(&ac, z(s, 0.5), 60).0)).collect();
    same.sort(); same.dedup();                         // no deflation, six starts
    println!("no deflation: six Newton runs from x + 0.5i, x = -1 to 1, give {} distinct roots: {}", same.len(), same.join(", "));
    // ---- Wilkinson's polynomial (x - 1)(x - 2)...(x - 20) ----
    let mut w: Vec<i128> = vec![1];
    for k in 1..=20i128 {                              // multiply by (x - k), exactly in integers
        let prev = w.clone(); w.push(0);
        for j in 1..w.len() { w[j] = prev.get(j).copied().unwrap_or(0) - k * prev[j - 1]; }
    }
    let wf: Vec<f64> = w.iter().map(|&c| c as f64).collect();
    println!("Wilkinson: x^19 coefficient {}, constant {}; {} of 21 not exact as doubles", w[1], w[20], w.iter().filter(|&&c| (c as f64) as i128 != c).count());
    let we = eig(companion(&wf, -1.0)).0;
    let errs: Vec<f64> = (1..=20).map(|k| we.iter().map(|&x| cabs(x - r(k as f64))).fold(f64::MAX, f64::min)).collect();
    let kw: Vec<f64> = (1..=20i128).map(|k| {
        let s: f64 = wf.iter().enumerate().map(|(j, c)| c.abs() * k.pow(20 - j as u32) as f64).sum();
        s / ((k * (1..k).product::<i128>() * (1..=20 - k).product::<i128>()) as f64) // |p'(k)| = (k-1)!(20-k)!
    }).collect();
    for k in [1usize, 5, 10, 16, 20] {
        println!("  root {:>2}: kappa {}, computed error {}, u kappa x* {}", k, sci(kw[k - 1]), sci(errs[k - 1]), sci(U * kw[k - 1] * k as f64)); }
    let worst = (0..20).fold(0, |b, j| if errs[j] > errs[b] { j } else { b });
    assert!((0..20).all(|j| errs[j] <= 50.0 * U * kw[j] * (j + 1) as f64) && errs[worst] > 1e-3);
    println!("  worst computed error {:.4}, at root {}", errs[worst], worst + 1);
    for z0 in [21.0, 0.0] { let (mut qd, mut got) = (cx(&wf), vec![]); // deflate without polishing, from the top and from the bottom
        while qd.len() > 1 { let x = newton(&qd, r(z0), 60).0; got.push(x); qd = horner(&qd, x).2; }
        let dw = (1..=20).map(|k| got.iter().map(|&x| cabs(x - r(k as f64))).fold(f64::MAX, f64::min)).fold(0.0, f64::max);
        assert!((dw > 1.0) == (z0 > 20.0)); println!("  unpolished deflation, Newton started at {:.0}: worst error {:.4}", z0, dw); }
    println!("  first-order shift of root 16 for -2^-23 on x^19: {:.1}", 2f64.powi(-23) * 16f64.powi(19) / horner(&cx(&wf), r(16.0)).1.re);
    let mut wp = wf.clone(); wp[1] = wf[1] - 2f64.powi(-23);
    let pw: Vec<Z> = order(eig(companion(&wp, -1.0)).0).into_iter().filter(|x| x.im > -1e-6).collect();
    let ps: Vec<String> = pw.iter().rev().map(|x| if x.im > 1e-6 { format!("{:.2} +- {:.2}i", x.re, x.im) } else { format!("{:.2}", x.re) }).collect();
    println!("  roots after -2^-23 on x^19: {}", ps.join(", "));
    assert!(pw.iter().any(|&x| cabs(x - z(16.730737466, 2.812624896)) < 1e-3));
    println!("ALL CHECKS PASS");
}
