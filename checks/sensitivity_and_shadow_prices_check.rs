// Shadow prices: the workshop LP, the same three roads as the Python, in Rust.
// Maximise 19x1 + 20x2 pounds (x1 tables, x2 chairs); timber 4x1 + 2x2 <= 160 m,
// labour 3x1 + x2 <= 120 h, finish x1 + 2x2 <= 64 l.  Roads: the final simplex
// tableau, the dual's corners, re-solving at shifted limits.  Exact fractions, no crates.
use std::{cmp::Ordering, ops::{Add, Div, Mul, Neg, Sub}};
#[derive(Clone, Copy, PartialEq, Debug)]
struct Q(i64, i64); // numerator, denominator > 0, lowest terms
fn gcd(a: i64, b: i64) -> i64 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i64, d: i64) -> Q { let g = gcd(n, d) * d.signum(); Q(n / g, d / g) }
fn w(n: i64) -> Q { Q(n, 1) }
impl Add for Q { type Output = Q; fn add(self, o: Q) -> Q { q(self.0 * o.1 + o.0 * self.1, self.1 * o.1) } }
impl Sub for Q { type Output = Q; fn sub(self, o: Q) -> Q { q(self.0 * o.1 - o.0 * self.1, self.1 * o.1) } }
impl Mul for Q { type Output = Q; fn mul(self, o: Q) -> Q { q(self.0 * o.0, self.1 * o.1) } }
impl Div for Q { type Output = Q; fn div(self, o: Q) -> Q { q(self.0 * o.1, self.1 * o.0) } }
impl Neg for Q { type Output = Q; fn neg(self) -> Q { Q(-self.0, self.1) } }
impl PartialOrd for Q {
    fn partial_cmp(&self, o: &Q) -> Option<Ordering> { (self.0 * o.1).partial_cmp(&(o.0 * self.1)) }
}
fn f64q(x: Q) -> f64 { x.0 as f64 / x.1 as f64 }
fn fmt(x: Q) -> String { // whole, short decimal, or a/b
    if x.1 == 1 { return x.0.to_string(); }
    for k in 1..4 { if 10i64.pow(k as u32) % x.1 == 0 { return format!("{:.*}", k, f64q(x)); } }
    format!("{}/{}", x.0, x.1)
}
fn join(v: &[Q], sep: &str) -> String { v.iter().map(|&x| fmt(x)).collect::<Vec<_>>().join(sep) }
fn solve(m: &[Vec<Q>], v: &[Q]) -> Option<Vec<Q>> { // Gaussian elimination
    let n = v.len();
    let mut m: Vec<Vec<Q>> = m.iter().zip(v).map(|(r, &x)| { let mut r = r.clone(); r.push(x); r }).collect();
    for k in 0..n {
        let p = (k..n).find(|&r| m[r][k] != w(0))?;
        m.swap(k, p);
        for r in 0..n {
            if r != k && m[r][k] != w(0) {
                let f = m[r][k] / m[k][k];
                m[r] = (0..=n).map(|j| m[r][j] - f * m[k][j]).collect();
            }
        }
    }
    Some((0..n).map(|i| m[i][n] / m[i][i]).collect())
}
fn picks(m: usize, n: usize, start: usize, cur: &mut Vec<usize>, out: &mut Vec<Vec<usize>>) {
    if cur.len() == n { out.push(cur.clone()); return; }
    for i in start..m { cur.push(i); picks(m, n, i + 1, cur, out); cur.pop(); }
}
fn best(c: &[Q], a: &[Vec<Q>], b: &[Q]) -> (Q, Vec<Q>) { // max c.x, Ax <= b, x >= 0
    let n = c.len();
    let mut rows = a.to_vec();
    for i in 0..n { rows.push((0..n).map(|j| if i == j { w(-1) } else { w(0) }).collect()); }
    let mut rhs = b.to_vec(); rhs.extend(vec![w(0); n]);
    let (mut all, mut top): (Vec<Vec<usize>>, Option<(Q, Vec<Q>)>) = (vec![], None);
    picks(rows.len(), n, 0, &mut vec![], &mut all);
    for pk in all {
        let m: Vec<Vec<Q>> = pk.iter().map(|&i| rows[i].clone()).collect();
        let v: Vec<Q> = pk.iter().map(|&i| rhs[i]).collect();
        let x = match solve(&m, &v) { Some(x) => x, None => continue };
        let dot = |r: &Vec<Q>| r.iter().zip(&x).fold(w(0), |s, (&p, &xi)| s + p * xi);
        if rows.iter().zip(&rhs).any(|(r, &h)| dot(r) > h) { continue; }
        let z = c.iter().zip(&x).fold(w(0), |s, (&p, &xi)| s + p * xi);
        if top.as_ref().map_or(true, |t| z > t.0) { top = Some((z, x)); }
    }
    top.unwrap()
}
fn main() {
    let (c, b) = (vec![w(19), w(20)], vec![w(160), w(120), w(64)]);
    let a = vec![vec![w(4), w(2)], vec![w(3), w(1)], vec![w(1), w(2)]];
    let (names, cols) = (["timber", "labour", "finish"], ["x1", "x2", "s1", "s2", "s3"]);
    let z_at = |i: usize, level: Q| { let mut bb = b.clone(); bb[i] = level; best(&c, &a, &bb).0 };
    // Road 1: simplex, Dantzig's rule
    let mut t: Vec<Vec<Q>> = (0..3).map(|i| {
        let mut r = a[i].clone(); for j in 0..3 { r.push(w((i == j) as i64)); } r.push(b[i]); r }).collect();
    let mut z: Vec<Q> = vec![w(-19), w(-20), w(0), w(0), w(0), w(0)];
    let (mut basis, mut path) = (vec![2usize, 3, 4], vec![]);
    loop {
        let e = (0..5).fold(0, |m, k| if z[k] < z[m] { k } else { m });
        if !(z[e] < w(0)) { break; }
        let r = (0..3).filter(|&i| t[i][e] > w(0))
            .fold(None, |m: Option<usize>, i| match m { Some(k) if !(t[i][5] / t[i][e] < t[k][5] / t[k][e]) => Some(k), _ => Some(i) }).unwrap();
        path.push(format!("{} in, {} out", cols[e], cols[basis[r]])); basis[r] = e;
        let p = t[r][e]; t[r] = t[r].iter().map(|&x| x / p).collect();
        for i in 0..3 { if i != r { let f = t[i][e]; t[i] = (0..6).map(|j| t[i][j] - f * t[r][j]).collect(); } }
        let f = z[e]; z = (0..6).map(|j| z[j] - f * t[r][j]).collect();
    }
    println!("pivots: {}", path.join("; "));
    let mut head = format!("{:<14}", "final tableau");
    for h in cols.iter().chain(["rhs"].iter()) { head.push_str(&format!("{:>7}", h)); }
    println!("{}", head);
    let line = |name: String, r: &[Q]| { let mut s = format!("{:<14}", name);
        for &x in r { s.push_str(&format!("{:>7}", fmt(x))); } println!("{}", s); };
    for i in 0..3 { line(format!("row {}", cols[basis[i]]), &t[i]); }
    line("profit row".to_string(), &z);
    let y: Vec<Q> = (0..3).map(|i| z[2 + i]).collect();
    println!("shadow prices, pounds per unit: {}", (0..3).map(|i| format!("{} {}", names[i], fmt(y[i]))).collect::<Vec<_>>().join(", "));
    let mut ranges: Vec<(Q, Option<Q>)> = vec![];
    for i in 0..3 { // basic values move by delta * slack column
        let (mut lo, mut hi): (Option<Q>, Option<Q>) = (None, None);
        for r in 0..3 {
            let (av, v) = (t[r][2 + i], t[r][5]);
            if av > w(0) { let s = -v / av; lo = Some(match lo { Some(l) if l > s => l, _ => s }); }
            if av < w(0) { let s = v / -av; hi = Some(match hi { Some(h) if h < s => h, _ => s }); }
        }
        ranges.push((b[i] + lo.unwrap(), hi.map(|h| b[i] + h)));
        println!("{} price {} holds from {} to {}", names[i], fmt(y[i]), fmt(ranges[i].0),
                 ranges[i].1.map_or("no limit".to_string(), fmt));
    }
    let mut margins: Vec<(Q, Q)> = vec![];
    for j in 0..2 { // a margin moves the profit row by eps * its row
        let r = basis.iter().position(|&k| k == j).unwrap();
        let out: Vec<usize> = (0..5).filter(|k| !basis.contains(k)).collect();
        let lo = out.iter().filter(|&&k| t[r][k] > w(0)).map(|&k| -z[k] / t[r][k]).fold(None, |m: Option<Q>, s| Some(match m { Some(v) if v > s => v, _ => s })).unwrap();
        let hi = out.iter().filter(|&&k| t[r][k] < w(0)).map(|&k| z[k] / -t[r][k]).fold(None, |m: Option<Q>, s| Some(match m { Some(v) if v < s => v, _ => s })).unwrap();
        margins.push((c[j] + lo, c[j] + hi));
        println!("{} margin {}: plan stays best from {} to {}", ["table", "chair"][j], fmt(c[j]), fmt(c[j] + lo), fmt(c[j] + hi));
    }
    // Road 2: the dual by its corners
    let at: Vec<Vec<Q>> = (0..2).map(|j| (0..3).map(|i| -a[i][j]).collect()).collect();
    let (dv, dy) = best(&b.iter().map(|&x| -x).collect::<Vec<_>>(), &at, &c.iter().map(|&x| -x).collect::<Vec<_>>());
    println!("dual by its corners: y = {} | dual value {}", join(&dy, ", "), fmt(-dv));
    // Road 3: re-solve by listing corners, at shifted limits
    let (zs, xs) = best(&c, &a, &b);
    println!("primal by its corners: tables {}, chairs {}, profit {}", fmt(xs[0]), fmt(xs[1]), fmt(zs));
    for i in 0..3 {
        let (lo, top) = (ranges[i].0, ranges[i].1.unwrap_or(ranges[i].0 + w(50)));
        let v: Vec<Q> = [lo - w(1), lo, top, top + w(1)].iter().map(|&l| z_at(i, l)).collect();
        println!("{} at {}, {}, {}, {}: profit {}", names[i], fmt(lo - w(1)), fmt(lo), fmt(top), fmt(top + w(1)), join(&v, ", "));
    }
    let lab = (z_at(1, w(112)) - z_at(1, w(32))) / w(80);
    println!("labour below 112 h: profit {} at 111 h; price {} an hour from 32 to 112", fmt(z_at(1, w(111))), fmt(lab));
    let stool = [w(1), w(1), w(1)];
    let a3: Vec<Vec<Q>> = (0..3).map(|i| { let mut r = a[i].clone(); r.push(stool[i]); r }).collect();
    let (mut z3, mut r_last) = (w(0), w(0));
    for m in [9, 11] {
        let r_j = (0..3).fold(w(0), |s, i| s + y[i] * stool[i]) - w(m); // value used minus margin
        let (zz, x3) = best(&[w(19), w(20), w(m)], &a3, &b); z3 = zz; r_last = r_j;
        println!("stool at {}: profit-row entry {}; re-solved tables {}, chairs {}, stools {}, profit {}", m, fmt(r_j), fmt(x3[0]), fmt(x3[1]), fmt(x3[2]), fmt(zz));
    }
    let force = |k: i64| { let mut a4 = a3.clone(); a4.push(vec![w(0), w(0), w(-1)]);
        let mut b4 = b.clone(); b4.push(w(-k)); best(&[w(19), w(20), w(9)], &a4, &b4).0 };
    println!("stool at 9, forced: 1 stool {}, 16 stools {}", fmt(force(1)), fmt(force(16)));
    println!("finish at 40: one litre more adds {}, one fewer loses {}", fmt(z_at(2, w(41)) - z_at(2, w(40))), fmt(z_at(2, w(40)) - z_at(2, w(39))));
    println!("mistake, 100 more litres at 7: predicts {}, true {}", fmt(zs + w(700)), fmt(z_at(2, w(164))));
    println!("mistake, labour at its average: {:.2} an hour, true {}", f64q(zs / b[1]), fmt(z_at(1, w(121)) - zs));
    println!("mistake, one fewer litre at 40 at 7: predicts {}, true {}", fmt(z_at(2, w(40)) - w(7)), fmt(z_at(2, w(39))));
    let pts: Vec<i64> = (0..=200).step_by(20).collect();
    println!("chart, finish litres: {}", pts.iter().map(|p| p.to_string()).collect::<Vec<_>>().join(" "));
    println!("chart, best profit: {}", join(&pts.iter().map(|&p| z_at(2, w(p))).collect::<Vec<_>>(), " "));
    let pt = |tt: Q, cc: Q| format!("({:.1} {:.1})", f64q(w(50) + q(16, 5) * tt), f64q(w(300) - q(16, 5) * cc));
    println!("figure, best {} origin {} timber {} {} finish64 {} {} labour {} finish40 {} finish160 {}",
             pt(w(32), w(16)), pt(w(0), w(0)), pt(w(0), w(80)), pt(w(40), w(0)), pt(w(0), w(32)), pt(w(64), w(0)),
             pt(q(35, 3), w(85)), pt(w(0), w(20)), pt(w(64), w(48)));
    assert!(y == dy && -dv == zs && zs == z[5] && zs == w(928)); // tableau prices = dual corners
    let bi = |j: usize| basis.iter().position(|&k| k == j).unwrap();
    assert!(xs == vec![t[bi(0)][5], t[bi(1)][5]] && xs == vec![w(32), w(16)]);
    for i in 0..3 { // re-solves confirm price and ends
        let (lo, hi) = ranges[i]; let top = hi.unwrap_or(lo + w(50));
        assert!(z_at(i, top) - z_at(i, lo) == y[i] * (top - lo));
        assert!(z_at(i, lo) - z_at(i, lo - w(1)) != y[i]);
        assert!(hi.map_or(true, |h| z_at(i, h + w(1)) - z_at(i, h) != y[i]));
    }
    assert!(ranges[2] == (w(40), Some(w(160))) && ranges[0] == (w(64), Some(q(848, 5))) && lab == q(18, 5));
    assert!(z_at(1, w(72)) * w(2) == z_at(1, w(32)) + z_at(1, w(112)) && z_at(1, w(32)) - z_at(1, w(31)) != lab);
    assert!(force(1) == zs - w(1) && force(16) == zs - w(16) && z3 == zs - w(16) * r_last); // reduced cost x stools
    assert!(z_at(2, w(65)) - zs == y[2] && z_at(0, w(161)) - zs == y[0] && z_at(1, w(121)) == zs);
    for (j, &(lo, hi)) in margins.iter().enumerate() { // re-solve at, and past, each margin end
        for (m, stays) in [(lo, true), (hi, true), (lo - w(1), false), (hi + w(1), false)] {
            let mut c2 = c.clone(); c2[j] = m;
            assert!((best(&c2, &a, &b).0 == c2[0] * w(32) + c2[1] * w(16)) == stays);
        }
    }
    println!("ALL CHECKS PASS");
}
