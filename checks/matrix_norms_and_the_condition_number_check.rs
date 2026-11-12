// Matrix norms and the condition number -- the check behind the card.  std only, no crates.
// A stream carries groundwater g and rain runoff r (m^3/s).  Gauge: g + r = 10.  Chloride,
// 50 g + 48 r = 490 g/s, divided by 50: g + 0.96 r = 9.8.  Road 1: norms by their formulas.
// Road 2: norms by sweeping directions round the circle.  Road 3: power iteration for the
// 2-norm, and exact fractions for every true error.
use std::f64::consts::PI;
const U: f64 = 1.0 / 9007199254740992.0; // 2^-53, the unit roundoff

#[derive(Clone, Copy, PartialEq)]
struct Q { n: i128, d: i128 } // an exact fraction n/d, kept in lowest terms with d > 0
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i128, d: i128) -> Q { let g = gcd(n, d) * d.signum(); Q { n: n / g, d: d / g } }
impl std::ops::Add for Q { type Output = Q; fn add(self, o: Q) -> Q { q(self.n * o.d + o.n * self.d, self.d * o.d) } }
impl std::ops::Sub for Q { type Output = Q; fn sub(self, o: Q) -> Q { q(self.n * o.d - o.n * self.d, self.d * o.d) } }
impl std::ops::Mul for Q { type Output = Q; fn mul(self, o: Q) -> Q { q(self.n * o.n, self.d * o.d) } }
impl std::ops::Div for Q { type Output = Q; fn div(self, o: Q) -> Q { q(self.n * o.d, self.d * o.n) } }
impl Q { fn f(self) -> f64 { self.n as f64 / self.d as f64 } fn abs(self) -> Q { q(self.n.abs(), self.d) } }
type M = [[Q; 2]; 2];

fn mul(a: &M, x: [Q; 2]) -> [Q; 2] { [a[0][0] * x[0] + a[0][1] * x[1], a[1][0] * x[0] + a[1][1] * x[1]] }
fn mulf(a: &[[f64; 2]; 2], x: [f64; 2]) -> [f64; 2] { [a[0][0] * x[0] + a[0][1] * x[1], a[1][0] * x[0] + a[1][1] * x[1]] }
fn det(a: &M) -> Q { a[0][0] * a[1][1] - a[0][1] * a[1][0] }
fn inv(a: &M) -> M { // swap the diagonal, flip the other signs, divide by det
    let (d, z) = (det(a), q(0, 1));
    [[a[1][1] / d, (z - a[0][1]) / d], [(z - a[1][0]) / d, a[0][0] / d]]
}
fn fl(a: &M) -> [[f64; 2]; 2] { [[a[0][0].f(), a[0][1].f()], [a[1][0].f(), a[1][1].f()]] }
fn fv(x: [Q; 2]) -> [f64; 2] { [x[0].f(), x[1].f()] }
fn v1(x: [f64; 2]) -> f64 { x[0].abs() + x[1].abs() }
fn v2(x: [f64; 2]) -> f64 { (x[0] * x[0] + x[1] * x[1]).sqrt() }
fn vi(x: [f64; 2]) -> f64 { x[0].abs().max(x[1].abs()) }
fn m1(a: &M) -> f64 { (a[0][0].abs() + a[1][0].abs()).f().max((a[0][1].abs() + a[1][1].abs()).f()) } // column sums
fn mi(a: &M) -> f64 { (a[0][0].abs() + a[0][1].abs()).f().max((a[1][0].abs() + a[1][1].abs()).f()) } // row sums
fn m2(a: &M) -> f64 { // largest singular value: square root of the larger eigenvalue of A^T A
    let t: f64 = fl(a).iter().flatten().map(|v| v * v).sum();
    ((t + (t * t - 4.0 * det(a).f().powi(2)).sqrt()) / 2.0).sqrt()
}
fn sweep(a: &M, vn: fn([f64; 2]) -> f64) -> (f64, f64) { // road 2: biggest and smallest stretch
    let (af, n) = (fl(a), 200000);
    let (mut hi, mut lo) = (0.0f64, f64::INFINITY);
    for k in 0..n {
        let t = PI * k as f64 / n as f64;
        let v = [t.cos(), t.sin()];
        let s = vn(mulf(&af, v)) / vn(v);
        hi = hi.max(s);
        lo = lo.min(s);
    }
    (hi, lo)
}
fn power(a: &M) -> f64 { // road 3: power iteration on A^T A
    let af = fl(a);
    let mut m = [[0.0; 2]; 2];
    for i in 0..2 { for j in 0..2 { m[i][j] = (0..2).map(|k| af[k][i] * af[k][j]).sum(); } }
    let mut v = [1.0, 0.0];
    for _ in 0..60 { let w = mulf(&m, v); v = [w[0] / v2(w), w[1] / v2(w)]; }
    v2(mulf(&m, v)).sqrt()
}
fn solve(a: [[f64; 2]; 2], b: [f64; 2]) -> [f64; 2] { // partial pivoting: swap only if the lower pivot is larger
    let (mut a, mut b) = (a, b);
    if a[1][0].abs() > a[0][0].abs() { a.swap(0, 1); b.swap(0, 1); }
    let l = a[1][0] / a[0][0];
    let y = (b[1] - l * b[0]) / (a[1][1] - l * a[0][1]);
    [(b[0] - a[0][1] * y) / a[0][0], y]
}
fn kinf(a: &M) -> f64 { mi(a) * mi(&inv(a)) }

fn main() {
    let a: M = [[q(1, 1), q(1, 1)], [q(1, 1), q(24, 25)]];
    let (b, x) = ([q(10, 1), q(49, 5)], [q(5, 1), q(5, 1)]);
    let ai = inv(&a);
    println!("stream: g + r = 10 and 50 g + 48 r = 490, so g + 0.96 r = 9.8; true flows g = r = 5 m^3/s");
    println!("det A {:.4}; A^-1 = [[{:.0}, {:.0}], [{:.0}, {:.0}]]", det(&a).f(), ai[0][0].f(), ai[0][1].f(), ai[1][0].f(), ai[1][1].f());
    println!("x norms: 1 {:.4}, 2 {:.4}, inf {:.4}", v1(fv(x)), v2(fv(x)), vi(fv(x)));
    println!("b norms: 1 {:.4}, 2 {:.4}, inf {:.4}", v1(fv(b)), v2(fv(b)), vi(fv(b)));
    let norms: [(&str, fn(&M) -> f64, fn([f64; 2]) -> f64); 3] = [("1", m1, v1), ("2", m2, v2), ("inf", mi, vi)];
    let mut kap = [0.0; 3];
    for (i, (name, mn, vn)) in norms.iter().enumerate() {
        let (na, nai) = (mn(&a), mn(&ai));
        let (sa, sai) = (sweep(&a, *vn).0, sweep(&ai, *vn).0);
        kap[i] = na * nai;
        println!("norm {:3}: ||A|| {:.4} sweep {:.4}; ||A^-1|| {:.4} sweep {:.4}; kappa {:.4}", name, na, sa, nai, sai, kap[i]);
        assert!((sa - na).abs() < 1e-6 * na && (sai - nai).abs() < 1e-6 * nai, "sweep agrees with the formula");
    }
    let raw: M = [[q(1, 1), q(1, 1)], [q(50, 1), q(48, 1)]]; // unscaled rows: not symmetric, so row and column sums differ
    for (nm, m) in [("A", raw), ("A^-1", inv(&raw))] {
        let (s1, si) = (sweep(&m, v1).0, sweep(&m, vi).0);
        println!("unscaled rows, {}: 1-norm {:.4} sweep {:.4}; inf-norm {:.4} sweep {:.4}", nm, m1(&m), s1, mi(&m), si);
        assert!((s1 - m1(&m)).abs() < 1e-6 * s1 && (si - mi(&m)).abs() < 1e-6 * si, "1-norm by columns, inf by rows");
    }
    let (hi, lo) = sweep(&a, v2);
    let pw = power(&a);
    println!("2-norm: power iteration {:.6}, sigma_min {:.6}, sweep kappa {:.4}", pw, det(&a).abs().f() / m2(&a), hi / lo);
    println!("digits at risk log10 kappa_inf {:.2}; eigenvalues of A {:.4}, {:.4}", kap[2].log10(), 0.98 + 1.0004f64.sqrt(), 0.98 - 1.0004f64.sqrt());
    let rs: Vec<f64> = [&a, &ai].iter().flat_map(|m| (0..2).map(move |i| (m[i][0].abs() + m[i][1].abs()).f())).collect();
    let (dx0, dg) = (mul(&ai, [q(-1, 10), q(0, 1)]), 53.0 * 2f64.log10());
    println!("hand: row sums A {:.4}, {:.4}; A^-1 {:.4}, {:.4}; dx ({:.4}, {:.4}); digits in a double {:.2}, left {:.2}", rs[0], rs[1], rs[2], rs[3], dx0[0].f(), dx0[1].f(), dg, dg - kap[2].log10());
    assert!((pw - m2(&a)).abs() < 1e-12 && (hi / lo - kap[1]).abs() < 1e-3 * kap[1], "three roads to kappa_2");
    let one = q(1, 1);
    let zero = q(0, 1);
    assert!(mul(&a, [ai[0][0], ai[1][0]]) == [one, zero] && mul(&a, [ai[0][1], ai[1][1]]) == [zero, one], "A times A^-1 is I, exactly");

    let case = |label: &str, db: [Q; 2]| -> (Vec<(f64, f64)>, [Q; 2]) {
        let xs = mul(&ai, [b[0] + db[0], b[1] + db[1]]);
        let dx = fv([xs[0] - x[0], xs[1] - x[1]]);
        println!("{}: g {:.4}, r {:.4}", label, xs[0].f(), xs[1].f());
        let mut out = vec![];
        for (i, (name, _, vn)) in norms.iter().enumerate() {
            let (rb, rx) = (vn(fv(db)) / vn(fv(b)), vn(dx) / vn(fv(x)));
            println!("  norm {:3}: data {:.3} %, flows {:.2} %, amplified {:.2}, bound kappa {:.2}", name, 100.0 * rb, 100.0 * rx, rx / rb, kap[i]);
            assert!(rx <= kap[i] * rb * (1.0 + 1e-12), "the bound holds");
            out.push((rb, rx));
        }
        (out, xs)
    };
    let (_, xl) = case("gauge 1% low", [q(-1, 10), zero]);
    let (worst, _) = case("worst case", [q(-1, 10), q(1, 10)]);
    assert!((worst[2].1 / worst[2].0 - kap[2]).abs() < 1e-9, "the infinity-norm bound is attained");
    let (af, aif) = (fl(&a), fl(&ai));
    let mut best = 0.0f64; // road 2 for 'attained': sweep directions of x and of the data error
    for i in 0..360 {
        for j in 0..360 {
            let xv = [(PI * i as f64 / 180.0).cos(), (PI * i as f64 / 180.0).sin()];
            let dv = [(PI * j as f64 / 180.0).cos(), (PI * j as f64 / 180.0).sin()];
            best = best.max((vi(mulf(&aif, dv)) / vi(xv)) / (vi(dv) / vi(mulf(&af, xv))));
        }
    }
    println!("largest amplification over 129600 pairs of directions {:.4}", best);
    assert!((best - kap[2]).abs() < 1e-9 * kap[2], "the sweep finds kappa_inf");
    let ax = mul(&a, xl);
    let rw = [b[0] - ax[0], b[1] - ax[1]];
    println!("residual of the gauge-low answer ({:.4}, {:.4}), relative {:.2} %", rw[0].f(), rw[1].f(), 100.0 * (vi(fv(rw)) / vi(fv(b))));

    let a2: M = [[one, one], [one, q(24, 25) * q(99, 100)]]; // runoff chloride read 1% low: 47.52 mg/L
    let xa = mul(&inv(&a2), b);
    let five = q(5, 1);
    let (ra, rx) = ((a2[1][1] - a[1][1]).abs().f() / mi(&a), vi(fv([xa[0] - five, xa[1] - five])) / vi(fv(xa)));
    println!("A changed: 0.96 -> {:.4}: g {:.4}, r {:.4}; data {:.2} %, flows {:.2} %, bound {:.2} %, ratio {:.2}", a2[1][1].f(), xa[0].f(), xa[1].f(), 100.0 * ra, 100.0 * rx, 100.0 * kap[2] * ra, kap[2] * ra / rx);
    assert!(rx <= kap[2] * ra, "the bound for a change in A");

    let xh = solve([[1.0, 1.0], [1.0, 0.96]], [10.0, 9.8]);
    let err = (xh[0] - 5.0).abs().max((xh[1] - 5.0).abs()) / 5.0;
    println!("doubles: g {:.15}, r {:.15}; true rel error {:.2e}, kappa*u {:.2e}, ratio {:.2}", xh[0], xh[1], err, kap[2] * U, err / (kap[2] * U));
    assert!(err <= 4.0 * kap[2] * U, "a stable solve loses about log10 kappa digits, no more");

    let t = q(10, 1);
    let ten: M = [[t * a[0][0], t * a[0][1]], [t * a[1][0], t * a[1][1]]];
    let tiny: M = [[q(1, 1000), zero], [zero, q(1, 1000)]];
    println!("break: det 10A {:.4}, kappa_inf {:.4}; det 0.001 I {:.2e}, kappa_inf {:.4}", det(&ten).f(), kinf(&ten), det(&tiny).f(), kinf(&tiny));
    println!("break: rows unscaled (mg/L row) kappa_inf {:.4}; 1/|det A| {:.4}", kinf(&raw), (one / det(&a).abs()).f());
    for k in -2i128..3 { // chart: the gauge reads k/2 percent off
        let xs = mul(&ai, [b[0] * (one + q(k, 200)), b[1]]);
        println!("chart, gauge {:+.1} %, g {:.2}, r {:.2}", k as f64 / 2.0, xs[0].f(), xs[1].f());
    }
    for c in [40i128, 49, 50] { // try: runoff chloride c mg/L
        let ac: M = [[one, one], [one, q(c, 50)]];
        if det(&ac) == zero { println!("try: runoff {} mg/L: det 0, no inverse, kappa infinite", c); continue; }
        let bc = mul(&ac, x);
        let xs = mul(&inv(&ac), [bc[0] - q(1, 10), bc[1]]);
        println!("try: runoff {} mg/L: kappa_inf {:.4}, gauge 1% low moves flows {:.2} %", c, kinf(&ac), 100.0 * (vi(fv([xs[0] - five, xs[1] - five])) / 5.0));
    }
    println!("ALL CHECKS PASS");
}
