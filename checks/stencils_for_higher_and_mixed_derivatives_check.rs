// Stencils to order -- the check behind the card.  std only, no crates.  Weights are
// solved from the Taylor conditions in exact fractions, and again from Lagrange's
// polynomial; the bond's slopes come from its cash flows in closed form.
#[derive(Clone, Copy, PartialEq, Debug)]
struct Q(i128, i128); // an exact fraction, numerator over a positive denominator
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i128, d: i128) -> Q { let g = gcd(n, d) * d.signum(); Q(n / g, d / g) }
impl Q {
    fn add(self, o: Q) -> Q { q(self.0 * o.1 + o.0 * self.1, self.1 * o.1) }
    fn sub(self, o: Q) -> Q { q(self.0 * o.1 - o.0 * self.1, self.1 * o.1) }
    fn mul(self, o: Q) -> Q { q(self.0 * o.0, self.1 * o.1) }
    fn div(self, o: Q) -> Q { q(self.0 * o.1, self.1 * o.0) }
    fn pw(self, m: u32) -> Q { Q(self.0.pow(m), self.1.pow(m)) }
    fn f(self) -> f64 { self.0 as f64 / self.1 as f64 }
    fn s(self) -> String { if self.1 == 1 { format!("{}", self.0) } else { format!("{}/{}", self.0, self.1) } }
}
fn fr(c: &[Q]) -> String { c.iter().map(|x| x.s()).collect::<Vec<_>>().join(" ") }
fn fact(k: u32) -> i128 { (1..=k as i128).product() }
fn e(x: f64, d: usize) -> String { format!("{:.*e}", d, x) }
fn solve(m: Vec<Vec<Q>>, rhs: Vec<Q>) -> Vec<Q> { // Gauss-Jordan elimination on exact fractions
    let n = m.len();
    let mut a: Vec<Vec<Q>> = m.into_iter().zip(rhs).map(|(mut r, b)| { r.push(b); r }).collect();
    for c in 0..n {
        let p = (c..n).find(|&r| a[r][c].0 != 0).unwrap(); a.swap(c, p);
        let piv = a[c][c]; a[c] = a[c].iter().map(|v| v.div(piv)).collect();
        for r in 0..n {
            if r != c && a[r][c].0 != 0 {
                let k = a[r][c]; let rc = a[c].clone();
                a[r] = a[r].iter().zip(&rc).map(|(x, y)| x.sub(k.mul(*y))).collect();
            }
        }
    }
    (0..n).map(|r| a[r][n]).collect()
}
fn weights(s: &[i128], k: u32) -> Vec<Q> { // undetermined coefficients
    let m = (0..s.len() as u32).map(|p| s.iter().map(|&x| q(x, 1).pw(p)).collect()).collect();
    solve(m, (0..s.len() as u32).map(|p| q(if p == k { fact(k) } else { 0 }, 1)).collect())
}
fn lagrange(s: &[i128], k: usize) -> Vec<Q> { // road two: k! times the x^k coefficient
    let mut out = vec![];
    for (j, &sj) in s.iter().enumerate() {
        let (mut poly, mut den) = (vec![q(1, 1)], 1i128);
        for (i, &si) in s.iter().enumerate() {
            if i != j {
                poly = (0..=poly.len()).map(|m| {
                    let lo = if m > 0 { poly[m - 1] } else { q(0, 1) };
                    let hi = if m < poly.len() { poly[m] } else { q(0, 1) };
                    lo.sub(q(si, 1).mul(hi)) }).collect();
                den *= sj - si;
            }
        }
        out.push(poly[k].mul(q(fact(k as u32), den)));
    }
    out
}
fn err_term(s: &[i128], c: &[Q]) -> (u32, Q) {
    for m in s.len() as u32..s.len() as u32 + 3 {
        let mut t = q(0, 1);
        for (cj, &x) in c.iter().zip(s) { t = t.add(cj.mul(q(x, 1).pw(m))); }
        let ee = t.div(q(fact(m), 1)); if ee.0 != 0 { return (m, ee); }
    }
    panic!("no error term")
}
const YEARS: usize = 30; const R0: f64 = 0.045; const BP: f64 = 1e-4;
fn cash(t: usize) -> f64 { 400_000.0 + if t == YEARS { 10_000_000.0 } else { 0.0 } }
fn disc(r: f64, t: usize) -> f64 { let mut d = 1.0; for _ in 0..t { d /= 1.0 + r; } d }
fn price(a: f64, b: f64) -> f64 { // short end moved a bp, 30-year end b bp
    (1..=YEARS).map(|t| cash(t) * disc(R0 + (a + (b - a) * t as f64 / YEARS as f64) * BP, t)).sum()
}
fn exact(m: i32, n: i32) -> f64 { // d^(m+n) P / da^m db^n in $ per bp^(m+n)
    let mut tot = 0.0;
    for t in 1..=YEARS {
        let tf = t as f64; let (wa, wb) = (1.0 - tf / YEARS as f64, tf / YEARS as f64); let mut g = 1.0;
        for i in 0..m + n { g *= -(tf + i as f64) / (1.0 + R0) * BP; }
        tot += cash(t) * disc(R0, t) * g * wa.powi(m) * wb.powi(n);
    }
    tot
}
fn par(k: i32) -> f64 { (0..=k).map(|m| (fact(k as u32) / (fact(m as u32) * fact((k - m) as u32))) as f64 * exact(m, k - m)).sum() }
fn f(x: f64) -> f64 { price(x, x) }
fn apply(s: &[i128], c: &[Q], k: i32, h: f64) -> f64 { c.iter().zip(s).map(|(cj, &x)| cj.f() * f(x as f64 * h)).sum::<f64>() / h.powi(k) }
fn main() {
    let (s3, s5): (&[i128], &[i128]) = (&[-1, 0, 1], &[-2, -1, 0, 1, 2]);
    let (sl3, sl5, cu3, cu5) = (weights(s3, 1), weights(s5, 1), weights(s3, 2), weights(s5, 2));
    let (p0, p1, p2) = (f(0.0), par(1), par(2));
    println!("$10m face, 4% annual coupon, 30 years, every zero rate 4.50%; moves in bp");
    println!("value {:.2}; slope {:.6} $/bp; curvature {:.6} $/bp^2", p0, p1, p2);
    println!("100 bp rise: slope alone {:.2}, curvature adds {:.2}, true change {:.2}", p1 * 100.0, p2 * 10000.0 / 2.0, f(100.0) - p0);
    for (name, s, k, c) in [("slope, 3 points", s3, 1, &sl3), ("slope, 5 points", s5, 1, &sl5),
                            ("curvature, 3 points", s3, 2, &cu3), ("curvature, 5 points", s5, 2, &cu5)] {
        let (m, ee) = err_term(s, c);
        assert_eq!(*c, lagrange(s, k)); // two unrelated algorithms give the same fractions
        println!("{:<20} weights {}; error {} h^{} f^({})", name, fr(c), ee.s(), m as usize - k, m);
    }
    assert!(cu5 == vec![q(-1, 12), q(4, 3), q(-5, 2), q(4, 3), q(-1, 12)] && err_term(s5, &sl5) == (5, q(-1, 30)));
    println!("at h = 1 bp, true error of each stencil, then the predicted leading term:");
    for (name, s, k, c, tru) in [("slope 3", s3, 1, &sl3, p1), ("slope 5", s5, 1, &sl5, p1),
                                 ("curvature 3", s3, 2, &cu3, p2), ("curvature 5", s5, 2, &cu5, p2)] {
        let (m, ee) = err_term(s, c);
        println!("  {:<12} {:>10}   predicted {:>10}", name, e(apply(s, c, k, 1.0) - tru, 3), e(ee.f() * par(m as i32), 3));
    }
    let fl = 2f64.powi(-53) * p0 * cu5.iter().map(|c| c.f().abs()).sum::<f64>();
    println!("  rounding estimate for curvature 5 at 1 bp: u x value x sum|w| / h^2 = {}", e(fl, 2));
    let r5 = (apply(s5, &cu5, 2, 1.0) - p2).abs();
    assert!(fl / 10.0 < r5 && r5 < 10.0 * fl && r5 > 10.0 * (q(-1, 90).f() * par(6)).abs());
    println!("curvature errors, h = 50, 25, 12.5, 6.25 bp:");
    let hs = [50.0, 25.0, 12.5, 6.25];
    let e3: Vec<f64> = hs.iter().map(|&hb| apply(s3, &cu3, 2, hb) - p2).collect();
    let e5: Vec<f64> = hs.iter().map(|&hb| apply(s5, &cu5, 2, hb) - p2).collect();
    let ords = |v: &Vec<f64>| -> Vec<f64> { (0..3).map(|i| (v[i] / v[i + 1]).log2()).collect() };
    let (o3, o5) = (ords(&e3), ords(&e5));
    let j = |v: &Vec<f64>, g: &dyn Fn(f64) -> String| v.iter().map(|x| g(*x)).collect::<Vec<_>>().join(", ");
    println!("  3 points: {}; orders {}", j(&e3, &|x| e(x, 4)), j(&o3, &|x| format!("{:.2}", x)));
    println!("  5 points: {}; orders {}", j(&e5, &|x| e(x, 4)), j(&o5, &|x| format!("{:.2}", x)));
    assert!(o3.iter().all(|o| (o - 2.0).abs() < 0.02) && o5.iter().all(|o| (o - 4.0).abs() < 0.05));
    let lead = q(-1, 90).f() * 390625.0 * par(6);
    println!("  at 25 bp: leading term {}, true over predicted {:.4}", e(lead, 4), e5[1] / lead);
    let n3: f64 = cu3.iter().zip(s3).map(|(c, &x)| c.f() * f(x as f64 * 25.0)).sum();
    let n5: f64 = cu5.iter().zip(s5).map(|(c, &x)| c.mul(q(12, 1)).f() * f(x as f64 * 25.0)).sum();
    println!("values at -50, -25, 0, +25, +50 bp: {}", s5.iter().map(|&x| format!("{:.4}", f(x as f64 * 25.0))).collect::<Vec<_>>().join(", "));
    println!("  1 -2 1 sum {:.4}, / 25^2 = {:.6}; -1 16 -30 16 -1 sum {:.4}, / (12 x 25^2) = {:.6}", n3, n3 / 625.0, n5, n5 / 7500.0);
    println!("chart, log10 h in bp: {}", j(&hs.to_vec(), &|x| format!("{:.2}", x.log10())));
    println!("chart, log10 |error| 3 points: {}", j(&e3, &|x| format!("{:.2}", x.abs().log10())));
    println!("chart, log10 |error| 5 points: {}", j(&e5, &|x| format!("{:.2}", x.abs().log10())));
    // --- the mixed derivative: four corner points (x, y), solved for d^2/dx dy ---
    let c4: [(i128, i128); 4] = [(1, 1), (1, -1), (-1, 1), (-1, -1)];
    let mon = [(0u32, 0u32), (1, 0), (0, 1), (1, 1)];
    let cx = solve(mon.iter().map(|&(p, r)| c4.iter().map(|&(x, y)| q(x, 1).pw(p).mul(q(y, 1).pw(r))).collect()).collect(),
                   mon.iter().map(|&pq| q(if pq == (1, 1) { 1 } else { 0 }, 1)).collect());
    let prod: Vec<Q> = c4.iter().map(|&(x, y)| q(x, 2).mul(q(y, 2))).collect();
    let mom = |p: u32, r: u32| { let mut t = q(0, 1);
        for (c, &(x, y)) in cx.iter().zip(&c4) { t = t.add(c.mul(q(x, 1).pw(p)).mul(q(y, 1).pw(r))); }
        t.div(q(fact(p) * fact(r), 1)) };
    println!("cross weights at (+,+) (+,-) (-,+) (-,-): {}; product of two slopes: {}", fr(&cx), fr(&prod));
    println!("cross moments: x^2 {}, y^2 {}, x^3 y {}, x y^3 {}, x^2 y^2 {}", mom(2, 0).s(), mom(0, 2).s(), mom(3, 1).s(), mom(1, 3).s(), mom(2, 2).s());
    assert!(cx == prod && mom(2, 0) == q(0, 1) && mom(3, 1) == q(1, 6));
    let (x11, x31) = (exact(1, 1), exact(3, 1) + exact(1, 3));
    let cross = |h: f64| cx.iter().zip(&c4).map(|(c, &(x, y))| c.f() * price(x as f64 * h, y as f64 * h)).sum::<f64>() / (h * h);
    let pc: Vec<f64> = c4.iter().map(|&(x, y)| price(x as f64, y as f64)).collect();
    println!("cross values at (+,+) (+,-) (-,+) (-,-), 1 bp: {}", pc.iter().map(|v| format!("{:.4}", v)).collect::<Vec<_>>().join(", "));
    println!("  ++ - +- - -+ + -- = {:.6}", pc[0] - pc[1] - pc[2] + pc[3]);
    for hb in [1.0, 25.0] {
        let v = cross(hb);
        println!("cross term, h = {} bp: stencil {:.6}, exact {:.6}, error {}, predicted {}", hb, v, x11, e(v - x11, 4), e(hb * hb / 6.0 * x31, 4));
    }
    assert!((cross(1.0) - x11).abs() < 1e-4 && ((cross(25.0) - x11) / (625.0 / 6.0 * x31) - 1.0).abs() < 0.01);
    println!("slopes: short end {:.4}, 30-year end {:.4}; own curvatures {:.6}, {:.6}", exact(1, 0), exact(0, 1), exact(2, 0), exact(0, 2));
    println!("30-year end up 1 bp: short-end slope {:.4} becomes {:.4}", exact(1, 0), exact(1, 0) + x11);
    // --- unequal spacing: scenarios stored at -10 bp, 0 and +25 bp ---
    let su: &[i128] = &[-10, 0, 25]; let cu = weights(su, 2); let (mu, eu) = err_term(su, &cu);
    let (vu, predu) = (apply(su, &cu, 2, 1.0), eu.f() * par(mu as i32));
    println!("uneven {} bp: weights {}; error {} f^({})", su.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(", "), fr(&cu), eu.s(), mu);
    println!("  curvature {:.6}, error {:.6}, predicted {:.6}", vu, vu - p2, predu);
    let s4: &[i128] = &[-10, 0, 25, 50]; let c4u = weights(s4, 2); let v4 = apply(s4, &c4u, 2, 1.0); let (_, e4) = err_term(s4, &c4u);
    println!("  add +50 bp: weights {}; error {} f^(4)", fr(&c4u), e4.s());
    println!("  curvature {:.6}, error {:.6}, predicted {:.6}", v4, v4 - p2, e4.f() * par(4));
    assert!(cu == lagrange(su, 2) && ((vu - p2) / predu - 1.0).abs() < 0.05 && (v4 - p2).abs() < (vu - p2).abs() / 5.0);
    // --- what breaks ---
    let naive = (f(25.0) - 2.0 * p0 + f(-10.0)) / 306.25;
    let both = (f(1.0) - 2.0 * p0 + f(-1.0)) / 4.0;
    let one = price(1.0, 1.0) - price(1.0, 0.0) - price(0.0, 1.0) + p0;
    let pone = (exact(2, 1) + exact(1, 2)) / 2.0;
    println!("mistake, 1 -2 1 on -10/+25 with h = 17.5 bp: {:.4}", naive);
    println!("mistake, both ends moved together, over 4 h^2: {:.6}; (P_aa + 2 P_ab + P_bb) / 4 = {:.6}", both, p2 / 4.0);
    println!("mistake, one-sided cross from up moves only: {:.6}, error {:.6}, predicted {:.6}", one, one - x11, pone);
    assert!((both - p2 / 4.0).abs() < 1e-4 && naive < 0.0 && ((one - x11) / pone - 1.0).abs() < 0.02);
    let px = |v: &[i128], o: i128, k: i128| v.iter().map(|x| (o + k * x).to_string()).collect::<Vec<_>>().join(" ");
    println!("figure, five points at x {}; uneven at x {}; cross corners at x 150 210, y 168 228", px(s5, 180, 60), px(su, 160, 6));
    println!("ALL CHECKS PASS");
}
