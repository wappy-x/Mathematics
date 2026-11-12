// One polynomial through five swap quotes -- the same check as the Python, in Rust.  No
// crates.  Illustrative swap rates (percent) at 1, 2, 3, 5 and 10 years.  The degree-4 curve
// is built in exact fractions (the known answer), then by Lagrange, Newton, Vandermonde and
// barycentric in floats, with errors and operation counts.  Then a 7-year quote arrives.
use std::ops::{Add, Div, Mul, Sub};

#[derive(Clone, Copy, PartialEq, Debug)]
struct Q { n: i128, d: i128 }                  // an exact fraction n/d, d > 0, reduced
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i128, d: i128) -> Q { let g = gcd(n, d).max(1) * if d < 0 { -1 } else { 1 }; Q { n: n / g, d: d / g } }
impl Add for Q { type Output = Q; fn add(self, o: Q) -> Q { q(self.n * o.d + o.n * self.d, self.d * o.d) } }
impl Sub for Q { type Output = Q; fn sub(self, o: Q) -> Q { q(self.n * o.d - o.n * self.d, self.d * o.d) } }
impl Mul for Q { type Output = Q; fn mul(self, o: Q) -> Q { q(self.n * o.n, self.d * o.d) } }
impl Div for Q { type Output = Q; fn div(self, o: Q) -> Q { q(self.n * o.d, self.d * o.n) } }
impl PartialOrd for Q { fn partial_cmp(&self, o: &Q) -> Option<std::cmp::Ordering> { (self.n * o.d).partial_cmp(&(o.n * self.d)) } }
trait Num: Copy + PartialOrd + Add<Output = Self> + Sub<Output = Self> + Mul<Output = Self> + Div<Output = Self> {
    fn from_i(i: i64) -> Self;
    fn absv(self) -> Self { if self < Self::from_i(0) { Self::from_i(0) - self } else { self } }
}
impl Num for f64 { fn from_i(i: i64) -> f64 { i as f64 } }
impl Num for Q { fn from_i(i: i64) -> Q { q(i as i128, 1) } }
fn e(v: f64) -> String { format!("{:.1e}", v) }
fn lagrange<T: Num>(xs: &[T], ys: &[T], t: T, ops: &mut u64) -> T {   // road 1
    let mut s = T::from_i(0);
    for j in 0..xs.len() {
        let mut l = T::from_i(1);
        for k in 0..xs.len() {
            if k != j { l = l * (t - xs[k]) / (xs[j] - xs[k]); *ops += 4 }
        }
        s = s + ys[j] * l; *ops += 2;
    }
    s
}
fn divided(xs: &[f64], ys: &[f64], ops: &mut u64) -> Vec<Vec<f64>> { // road 2: Newton's table
    let mut tab = vec![ys.to_vec()];                // level k, entry i: f[x_i, ..., x_(i+k)]
    for k in 1..xs.len() {
        let p = tab[k - 1].clone(); *ops += 3 * (p.len() as u64 - 1);
        tab.push((0..p.len() - 1).map(|i| (p[i + 1] - p[i]) / (xs[i + k] - xs[i])).collect());
    }
    tab
}
fn nested(xs: &[f64], c: &[f64], t: f64, ops: &mut u64) -> f64 {     // Newton form, inside out
    (0..c.len() - 1).rev().fold(c[c.len() - 1], |p, i| { *ops += 3; p * (t - xs[i]) + c[i] })
}
fn solve<T: Num>(a: &[Vec<T>], b: &[T], ops: &mut u64) -> (Vec<T>, T) { // partial pivoting
    let n = b.len();
    let mut m: Vec<Vec<T>> = a.iter().zip(b).map(|(r, &bi)| { let mut r = r.clone(); r.push(bi); r }).collect();
    let mut det = T::from_i(1);
    for i in 0..n {
        let mut piv = i;
        for r in i..n { if m[r][i].absv() > m[piv][i].absv() { piv = r } }
        if piv != i { m.swap(i, piv); det = T::from_i(0) - det }
        det = det * m[i][i];
        for r in i + 1..n {
            let f = m[r][i] / m[i][i]; *ops += 1;
            for c in i..=n { m[r][c] = m[r][c] - f * m[i][c]; *ops += 2 }
        }
    }
    let mut x = vec![T::from_i(0); n];
    for i in (0..n).rev() {
        let mut s = m[i][n];
        for k in i + 1..n { s = s - m[i][k] * x[k]; *ops += 2 }
        x[i] = s / m[i][i]; *ops += 1;
    }
    (x, det)
}
fn horner(a: &[f64], t: f64, ops: &mut u64) -> f64 {                // monomial form
    a[..a.len() - 1].iter().rev().fold(a[a.len() - 1], |p, &c| { *ops += 2; p * t + c })
}
fn bary_weights(xs: &[f64], ops: &mut u64) -> Vec<f64> {            // road 4: weights
    let mut w = Vec::new();
    for j in 0..xs.len() {
        let mut d = 1.0;
        for k in 0..xs.len() { if k != j { d = d * (xs[j] - xs[k]); *ops += 2 } }
        w.push(1.0 / d); *ops += 1;
    }
    w
}
fn bary(xs: &[f64], ys: &[f64], w: &[f64], t: f64, ops: &mut u64) -> f64 {
    let (mut num, mut den) = (0.0, 0.0);
    for j in 0..xs.len() { let qj = w[j] / (t - xs[j]); num = num + qj * ys[j]; den = den + qj; *ops += 5 }
    *ops += 1;
    num / den
}
fn vander<T: Num>(xs: &[T]) -> Vec<Vec<T>> {
    xs.iter().map(|&x| { let mut r = vec![T::from_i(1)]; for _ in 1..xs.len() { let l = r[r.len() - 1]; r.push(l * x) } r }).collect()
}
fn kappa(xs: &[Q]) -> f64 {                     // infinity-norm condition number, exact
    let n = xs.len();
    let inv: Vec<Vec<Q>> = (0..n).map(|j| solve(&vander(xs), &(0..n).map(|i| Q::from_i((i == j) as i64)).collect::<Vec<_>>(), &mut 0).0).collect();
    let norm = |m: &Vec<Vec<Q>>| m.iter().map(|r| r.iter().fold(Q::from_i(0), |s, &v| s + v.absv()))
        .fold(Q::from_i(0), |a, b| if b > a { b } else { a });
    let invt: Vec<Vec<Q>> = (0..n).map(|i| (0..n).map(|j| inv[j][i]).collect()).collect();
    let k = norm(&vander(xs)) * norm(&invt);
    k.n as f64 / k.d as f64
}
fn l_coeffs(xs: &[Q], j: usize) -> Vec<Q> {     // x^k coefficients of l_j: column j of V^-1, a second road
    let (mut c, z) = (vec![Q::from_i(1)], Q::from_i(0));
    for m in (0..xs.len()).filter(|&m| m != j) {
        c = (0..=c.len()).map(|k| ((if k > 0 { c[k - 1] } else { z }) - xs[m] * (if k < c.len() { c[k] } else { z })) / (xs[j] - xs[m])).collect();
    }
    c
}

fn main() {
    let (x, y, t) = (vec![1.0, 2.0, 3.0, 5.0, 10.0], vec![4.20, 3.95, 3.85, 3.90, 4.15], 7.0);
    let xq: Vec<Q> = x.iter().map(|&v| q(v as i128, 1)).collect();
    let yq: Vec<Q> = y.iter().map(|&v| q((v * 100.0f64).round() as i128, 100)).collect();
    let exact = lagrange(&xq, &yq, q(7, 1), &mut 0); let ex = exact.n as f64 / exact.d as f64;
    let qs: Vec<String> = x.iter().zip(&y).map(|(a, b)| format!("{:.0}: {:.2}", a, b)).collect();
    println!("quotes (years: percent) {}", qs.join(", "));
    println!("exact 7-year reading {}/{} = {:.6} percent", exact.n, exact.d, ex);
    let (mut nc, mut nw, mut na) = (0, 0, 0);
    let (tab, w) = (divided(&x, &y, &mut nc), bary_weights(&x, &mut nw));
    let c: Vec<f64> = tab.iter().map(|col| col[0]).collect();
    let a = solve(&vander(&x), &y, &mut na).0;
    let (mut o1, mut o2, mut o3, mut o4) = (0, 0, 0, 0);
    let roads = [("Lagrange", lagrange(&x, &y, t, &mut o1), o1, 0), ("Newton", nested(&x, &c, t, &mut o2), o2, nc),
                 ("Vandermonde", horner(&a, t, &mut o3), o3, na), ("barycentric", bary(&x, &y, &w, t, &mut o4), o4, nw)];
    for (name, v, n_eval, n_setup) in roads {
        println!("{:12} 7y {:.15}  error {}  ops setup {:3}, per reading {:3}", name, v, e(v - ex), n_setup, n_eval);
        assert!((v - ex).abs() < 1e-13);        // four float roads meet the exact answer
    }
    let fj = |v: Vec<f64>, d: usize| v.iter().map(|z| format!("{:.*}", d, z)).collect::<Vec<_>>().join(", ");
    for k in 1..5 { println!("divided differences, level {}: {}", k, fj(tab[k].clone(), 7)) }
    println!("Newton coefficients {}", fj(c.clone(), 10));
    println!("Newton terms at 7y {}", fj(c.iter().zip([1.0, 6.0, 30.0, 120.0, 240.0]).map(|(a, g)| a * g).collect(), 6));
    let basis = (0..5).map(|j| lagrange(&x, &(0..5).map(|i| (i == j) as i64 as f64).collect::<Vec<_>>(), t, &mut 0));
    println!("Lagrange basis at 7y {}\nmonomial coefficients {}", fj(basis.collect(), 6), fj(a.clone(), 10));
    let det = solve(&vander(&xq), &vec![Q::from_i(0); 5], &mut 0).1;
    let mut prod = Q::from_i(1);
    for i in 0..5 { for j in i + 1..5 { prod = prod * (xq[j] - xq[i]) } }
    println!("det V by elimination {}, by product of node gaps {}", det.n, prod.n);
    assert!(det == prod && det.n != 0);         // unique: V can be inverted
    let scaled: Vec<Q> = xq.iter().map(|&v| (Q::from_i(2) * v - Q::from_i(11)) / Q::from_i(9)).collect();
    let k1 = kappa(&xq); println!("kappa(V) years 1..10 {:.1}; rescaled to [-1, 1] {:.1}", k1, kappa(&scaled));
    let rows: Vec<Q> = (0..5).map(|k| (0..5).fold(Q::from_i(0), |s, j| s + l_coeffs(&xq, j)[k].absv())).collect(); // V^-1 rebuilt
    let qmax = |v: Vec<Q>| v.into_iter().fold(Q::from_i(0), |m, r| if r > m { r } else { m });
    let kb = qmax(vander(&xq).iter().map(|r| r.iter().fold(Q::from_i(0), |s, &v| s + v)).collect()) * qmax(rows);
    assert!((k1 - kb.n as f64 / kb.d as f64).abs() < 1e-9 * k1);
    let q7 = 4.00;
    let (x6, y6): (Vec<f64>, Vec<f64>) = ([x.clone(), vec![t]].concat(), [y.clone(), vec![q7]].concat());
    println!("7y quote arrives {:.2}: curve read {:.6}, true error {:.2} bp; line 5y-10y read {:.6}", q7, ex, (ex - q7) * 100.0, y[3] + (y[4] - y[3]) * (t - x[3]) / (x[4] - x[3]));
    let mut nu = 0; let c6: Vec<f64> = divided(&x6, &y6, &mut nu).iter().map(|col| col[0]).collect();
    let mut nfull = 0; solve(&vander(&x6), &y6, &mut nfull);
    println!("new Newton term {:.10}; update ops Newton {}, Vandermonde redo {}", c6[5], nu - nc, nfull);
    assert!(c6[..5] == c[..]);                   // old Newton coefficients survive unchanged
    let n = 4u64; let elim = |nn: u64| (nn - 1) * nn * (2 * nn - 1) / 3 + 5 * nn * (nn - 1) / 2 + nn * nn; // this solve, nn unknowns
    assert!([o1, o2, o3, o4] == [(4 * n + 2) * (n + 1), 3 * n, 2 * n, 5 * (n + 1) + 1]); // counts against closed forms
    assert!([nc, nw, na, nu - nc, nfull] == [3 * n * (n + 1) / 2, (2 * n + 1) * (n + 1), elim(n + 1), 3 * (n + 1), elim(n + 2)]);
    let (r4, r4n) = (nested(&x, &c, 4.0, &mut 0), nested(&x6, &c6, 4.0, &mut 0));
    let r4q = lagrange(&[xq.clone(), vec![q(7, 1)]].concat(), &[yq.clone(), vec![q(4, 1)]].concat(), q(4, 1), &mut 0);
    let r4x = r4q.n as f64 / r4q.d as f64;
    println!("4y reading before {:.6}, after {:.6}, exact after {:.6}", r4, r4n, r4x);
    assert!((r4n - r4x).abs() < 1e-13 && (nested(&x6, &c6, t, &mut 0) - q7).abs() < 1e-13);
    let dup = divided(&[1.0, 2.0, 3.0, 5.0, 5.0], &[4.20, 3.95, 3.85, 3.90, 3.92], &mut 0);
    let bad = if dup.iter().flatten().any(|v| !v.is_finite()) { "division by zero" } else { "no error" };
    let wx = x.iter().fold(1.0, |p, &xi| p * (t - xi)); // omega(x) = (x - 1)(x - 2)(x - 3)(x - 5)(x - 10)
    println!("mistake 1, two 5y quotes 3.90 and 3.92: {}\nmistake 2, degree 5 adds 0.0001 x omega(x), omega(7) = {:.0}: 7y reads {:.6}",
             bad, wx, ex + 1e-4 * wx);
    let ar: Vec<f64> = a.iter().map(|v| (v * 1e4).round() / 1e4).collect();
    let (h10, h7) = (horner(&ar, 10.0, &mut 0), horner(&ar, t, &mut 0));
    println!("mistake 3, coefficients to 4 decimals: 10y reads {:.6}, 7y {:.6}", h10, h7);
    let r30 = nested(&x, &c, 30.0, &mut 0);
    println!("mistake 4, read at 30 years: {:.6} percent", r30);
    assert!((h10 - 4.15).abs() > 0.03 && r30 > 90.0);
    let fig: Vec<String> = (0..13).map(|s| format!("{:.4}", nested(&x, &c, s as f64, &mut 0))).collect();
    println!("figure, {}", fig.join(", "));
    println!("ALL CHECKS PASS");
}
