// Dirichlet's unit theorem -- the same check as the Python, in Rust.  No crates.
// Members of Z[theta] are whole coordinate lists, multiplied exactly (i128).
// Road 1 counts places by numerical roots and by the sign of the exact
// discriminant.  Road 2 searches a box for every unit and proves the claimed
// units fundamental.  Road 3 redoes each regulator from closed forms.
use std::f64::consts::PI;
#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
impl C {
    fn add(self, o: C) -> C { C { re: self.re + o.re, im: self.im + o.im } }
    fn sub(self, o: C) -> C { C { re: self.re - o.re, im: self.im - o.im } }
    fn mul(self, o: C) -> C { C { re: self.re * o.re - self.im * o.im, im: self.re * o.im + self.im * o.re } }
    fn div(self, o: C) -> C { let d = o.re * o.re + o.im * o.im;
        C { re: (self.re * o.re + self.im * o.im) / d, im: (self.im * o.re - self.re * o.im) / d } }
    fn abs(self) -> f64 { self.re.hypot(self.im) }
    fn pw(self, k: usize) -> C { (0..k).fold(C { re: 1.0, im: 0.0 }, |a, _| a.mul(self)) }
}
type V = Vec<i128>; type Places = Vec<(C, f64)>;
fn mul(x: &V, y: &V, p: &V) -> V {
    let n = p.len(); let mut r = vec![0i128; 2 * n - 1];
    for (i, a) in x.iter().enumerate() { for (j, b) in y.iter().enumerate() { r[i + j] += a * b; } }
    for d in (n..2 * n - 1).rev() { let c = r[d]; r[d] = 0; for k in 0..n { r[d - n + k] -= c * p[k]; } }
    r.truncate(n); r
}
fn minor<T: Copy>(m: &Vec<Vec<T>>, row: usize, col: usize) -> Vec<Vec<T>> {
    m.iter().enumerate().filter(|(i, _)| *i != row)
        .map(|(_, r)| r.iter().enumerate().filter(|(j, _)| *j != col).map(|(_, v)| *v).collect()).collect()
}
fn deti(m: &Vec<Vec<i128>>) -> i128 {
    if m.len() == 1 { return m[0][0]; }
    (0..m.len()).map(|j| (if j % 2 == 0 { 1 } else { -1 }) * m[0][j] * deti(&minor(m, 0, j))).sum()
}
fn detf(m: &Vec<Vec<f64>>) -> f64 {
    if m.len() == 1 { return m[0][0]; }
    (0..m.len()).map(|j| (if j % 2 == 0 { 1.0 } else { -1.0 }) * m[0][j] * detf(&minor(m, 0, j))).sum()
}
fn e(n: usize, k: usize) -> V { (0..n).map(|i| (i == k) as i128).collect() }
fn matrix(x: &V, p: &V) -> Vec<Vec<i128>> {
    let n = p.len(); let cols: Vec<V> = (0..n).map(|j| mul(x, &power(&e(n, 1), j as i64, p), p)).collect();
    (0..n).map(|i| (0..n).map(|j| cols[j][i]).collect()).collect()
}
fn norm(x: &V, p: &V) -> i128 { deti(&matrix(x, p)) }
fn gram(p: &V) -> Vec<Vec<i128>> { let n = p.len();
    (0..n).map(|i| (0..n).map(|j| { let m = matrix(&mul(&e(n, i), &e(n, j), p), p); (0..n).map(|k| m[k][k]).sum() }).collect()).collect() }
fn inverse(u: &V, p: &V) -> V {
    let m = matrix(u, p); let d = deti(&m);
    (0..p.len()).map(|k| { let mk: Vec<Vec<i128>> = m.iter().enumerate()
        .map(|(i, r)| { let mut r = r.clone(); r[k] = (i == 0) as i128; r }).collect(); deti(&mk) / d }).collect()
}
fn power(x: &V, m: i64, p: &V) -> V {
    let b = if m >= 0 { x.clone() } else { inverse(x, p) };
    (0..m.abs()).fold(e(p.len(), 0), |y, _| mul(&y, &b, p))
}
fn places(p: &V) -> Places {
    let n = p.len();
    let f = |x: C| (0..n).fold(x.pw(n), |a, k| a.add(x.pw(k).mul(C { re: p[k] as f64, im: 0.0 })));
    let mut z: Vec<C> = (0..n).map(|k| C { re: 0.4, im: 0.9 }.pw(k)).collect();
    for _ in 0..500 {
        z = (0..n).map(|i| { let den = (0..n).filter(|&j| j != i).fold(C { re: 1.0, im: 0.0 }, |a, j| a.mul(z[i].sub(z[j])));
            z[i].sub(f(z[i]).div(den)) }).collect();
    }
    let mut real: Vec<f64> = z.iter().filter(|w| w.im.abs() < 1e-9).map(|w| w.re).collect();
    real.sort_by(|a, b| b.partial_cmp(a).unwrap());
    let mut cp: Vec<C> = z.iter().filter(|w| w.im >= 1e-9).cloned().collect();
    cp.sort_by(|a, b| a.re.partial_cmp(&b.re).unwrap());
    real.iter().map(|&t| (C { re: t, im: 0.0 }, 1.0)).chain(cp.iter().map(|&w| (w, 2.0))).collect()
}
fn sig(x: &V, z: C) -> C { x.iter().enumerate().fold(C { re: 0.0, im: 0.0 }, |a, (k, &c)| a.add(z.pw(k).mul(C { re: c as f64, im: 0.0 }))) }
fn logs(x: &V, pl: &Places) -> Vec<f64> { pl.iter().map(|&(z, w)| w * sig(x, z).abs().ln()).collect() }
fn search(p: &V, pl: &Places, b: &Vec<f64>) -> Vec<V> {
    let n = p.len(); let g = gram(p); let dg = deti(&g).abs() as f64;
    let adj: Vec<Vec<i128>> = (0..n).map(|i| (0..n).map(|j| (if (i + j) % 2 == 0 { 1 } else { -1 }) * deti(&minor(&g, j, i))).collect()).collect();
    let t: Vec<f64> = (0..n).map(|j| pl.iter().zip(b).map(|(&(z, w), &bb)| w * bb * z.abs().powi(j as i32)).sum()).collect();
    let h: Vec<i128> = (0..n).map(|k| ((0..n).map(|j| adj[k][j].abs() as f64 * t[j]).sum::<f64>() / dg) as i128 + 1).collect();
    let (mut out, mut x): (Vec<V>, V) = (vec![], h.iter().map(|v| -v).collect());
    loop {
        if x.iter().any(|&c| c != 0) && pl.iter().zip(b).all(|(&(z, _), &bb)| sig(&x, z).abs() <= bb * (1.0 + 1e-9))
            && norm(&x, p).abs() == 1 { out.push(x.clone()); }
        let mut i = n;
        loop { if i == 0 { return out; } i -= 1; if x[i] < h[i] { x[i] += 1; break; } x[i] = -h[i]; }
    }
}
fn rank(vs: &Vec<Vec<f64>>) -> usize {
    let mut bs: Vec<Vec<f64>> = vec![];
    for v0 in vs { let mut v = v0.clone();
        for b in &bs { let c: f64 = v.iter().zip(b).map(|(s, t)| s * t).sum(); v = v.iter().zip(b).map(|(s, t)| s - c * t).collect(); }
        let nv = v.iter().map(|s| s * s).sum::<f64>().sqrt(); if nv > 1e-6 { bs.push(v.iter().map(|s| s / nv).collect()); } }
    bs.len()
}
struct S { pl: Places, r1: usize, r2: usize, r: usize, d: i128, reg: f64, w: usize, n: usize, found: usize, units: Vec<V> }
fn study(p: &V, eps: &Vec<V>) -> S {
    let (n, pl) = (p.len(), places(p));
    let r1 = pl.iter().filter(|q| q.1 == 1.0).count(); let r2 = pl.len() - r1; let r = r1 + r2 - 1; let d = deti(&gram(p));
    assert_eq!(d > 0, r2 % 2 == 0);
    assert!(eps.len() == r && eps.iter().all(|u| norm(u, p).abs() == 1));
    let l: Vec<Vec<f64>> = eps.iter().map(|u| logs(u, &pl)).collect();
    let s: Vec<Vec<f64>> = (0..r).map(|i| (0..r).map(|j| l[j][i]).collect()).collect();
    let b: Vec<f64> = (0..pl.len()).map(|i| (l.iter().map(|li| li[i].abs()).sum::<f64>() / pl[i].1).exp()).collect();
    let units = search(p, &pl, &b);
    let w = units.iter().filter(|u| logs(u, &pl).iter().all(|t| t.abs() < 1e-9)).count();
    for u0 in &units {
        let lu = logs(u0, &pl); let mut u = u0.clone(); assert!(lu.iter().sum::<f64>().abs() < 1e-9); // Step 2: weighted logs add to 0
        for j in 0..r {
            let sj: Vec<Vec<f64>> = (0..r).map(|i| (0..r).map(|c| if c == j { lu[i] } else { s[i][c] }).collect()).collect();
            let k = detf(&sj) / detf(&s);
            assert!((k - k.round()).abs() < 1e-6);
            u = mul(&u, &power(&eps[j], -(k.round() as i64), p), p);
        }
        assert_eq!(power(&u, w as i64, p), e(n, 0));
    }
    let lv: Vec<Vec<f64>> = units.iter().map(|u| logs(u, &pl)).collect();
    S { r1, r2, r, d, reg: if r > 0 { detf(&s).abs() } else { 1.0 }, w, n: units.len(), found: rank(&lv), units, pl }
}
fn smallest(p: &V, b: Vec<f64>) -> (f64, V) {
    let pl = places(p); let mut best = (f64::MAX, vec![]);
    for u in search(p, &pl, &b) { let v = sig(&u, pl[0].0).re; if v > 1.0 + 1e-9 && v < best.0 { best = (v, u); } }
    best
}
fn f6(x: f64) -> String { format!("{:.6}", x) }
fn j6(v: &Vec<f64>) -> String { v.iter().map(|&x| f6(x)).collect::<Vec<_>>().join(", ") }
fn main() {
    let (c2, c4) = (2.0 * (2.0 * PI / 7.0).cos(), 2.0 * (4.0 * PI / 7.0).cos());
    let fields: Vec<(&str, V, Vec<V>, f64)> = vec![
        ("Q(root 2)", vec![-2, 0], vec![vec![1, 1]], (1.0 + 2f64.sqrt()).ln()),
        ("Q(root -5)", vec![5, 0], vec![], 1.0),
        ("Q(cbrt 2)", vec![-2, 0, 0], vec![vec![1, 1, 1]], (1.0 + (2f64.ln() / 3.0).exp() + (2.0 * 2f64.ln() / 3.0).exp()).ln()),
        ("x^3+x^2-2x-1", vec![-1, -2, 1], vec![vec![0, 1, 0], vec![1, 1, 0]],
         (c2.ln() * (1.0 + c4).abs().ln() - c4.abs().ln() * (1.0 + c2).ln()).abs()),
        ("Q(root 5)", vec![-1, -1], vec![vec![0, 1]], ((1.0 + 5f64.sqrt()) / 2.0).ln())];
    let mut info: Vec<S> = vec![];
    println!("field            d_K  r1 r2  rank r1+r2-1  rank found  w  units in box  regulator");
    for (name, p, eps, rc) in &fields {
        let s = study(p, eps);
        assert!(s.found == s.r && (s.reg - rc).abs() < 1e-9);
        println!("{:15} {:>5} {:>3} {:>2} {:>8} {:>11} {:>4} {:>9}      {}", name, s.d, s.r1, s.r2, s.r, s.found, s.w, s.n, f6(s.reg));
        info.push(s); }
    let (limit, p2) = (10000i128, vec![-2i128, 0]);
    let isq = |n: i128| { let mut k = n; while k * k > n { k = (k + n / k) / 2; } k };
    let mut found: Vec<(i128, i128, i128)> = vec![];
    for b in 1..=limit { for s in [-1i128, 1] { let a = isq(2 * b * b + s); if a * a == 2 * b * b + s { found.push((a, b, s)); } } }
    let pows: Vec<(i128, i128, i128)> = (1..12).map(|m| { let q = power(&vec![1, 1], m, &p2); (q[0], q[1], norm(&q, &p2)) }).collect();
    let z2 = smallest(&p2, vec![5.0, 5.0]);
    assert!(found == pows && power(&vec![1, 1], 12, &p2)[1] > limit && z2.1 == vec![1, 1]);
    println!("search b = 1..{}: {} units with a, b > 0; powers m = 1..{} of 1 + root 2 match", limit, found.len(), pows.len());
    println!("first five: {}", found[..5].iter().map(|(a, b, s)| format!("{} + {} root 2 (norm {:+})", a, b, s)).collect::<Vec<_>>().join(", "));
    println!("(1 + root 2)(root 2 - 1) = {:?}; (1 + root 2)^2 = {:?}; smallest unit above 1 by search = {}; L(1 + root 2) = {}",
             mul(&vec![1, 1], &vec![-1, 1], &p2), power(&vec![1, 1], 2, &p2), f6(z2.0), j6(&logs(&vec![1, 1], &places(&p2))));
    let pl2 = places(&p2);
    for m in 1..6 { let q = power(&vec![1, 1], m, &p2); let l = logs(&q, &pl2)[0];
        println!("bar {}: log({} + {} root 2) = {}  {}", m, q[0], q[1], f6(l), "#".repeat((l * 5.0).round_ties_even() as usize)); }
    let (p3, one3) = (vec![-2i128, 0, 0], vec![1i128, 1, 1]); let (pl3, s3) = (places(&p3), smallest(&p3, vec![4.0, 1.0]));
    assert!(s3.1 == one3 && mul(&one3, &vec![-1, 1, 0], &p3) == vec![1, 0, 0]);
    println!("cubic: N(1 + t + t^2) = {}, 1 + 2 + 4 - 6 = {}; (1 + t + t^2)(t - 1) = {:?}; N(t - 1) = {}", norm(&one3, &p3), 1 + 2 + 4 - 6, mul(&one3, &vec![-1, 1, 0], &p3), norm(&vec![-1, 1, 0], &p3));
    println!("cubic: real value {}, |complex value|^2 {}, cbrt 2 - 1 = {}; smallest unit above 1 by search {:?} = {}",
             f6(sig(&one3, pl3[0].0).re), f6(sig(&one3, pl3[1].0).abs().powi(2)), f6((2f64.ln() / 3.0).exp() - 1.0), s3.1, f6(s3.0));
    let pl7 = &info[3].pl; let l7: Vec<Vec<f64>> = [vec![0i128, 1, 0], vec![1, 1, 0]].iter().map(|u| logs(u, pl7)).collect();
    println!("x^3+x^2-2x-1: roots {}; logs of t: {}; logs of t + 1: {}", j6(&pl7.iter().map(|q| q.0.re).collect()), j6(&l7[0]), j6(&l7[1]));
    println!("regulator dropping place 3, 2, 1: {}", j6(&[(0, 1), (0, 2), (1, 2)].iter().map(|&(i, j)| (l7[0][i] * l7[1][j] - l7[0][j] * l7[1][i]).abs()).collect()));
    let (z5, r5) = (smallest(&vec![-5, 0], vec![5.0, 5.0]), info[4].reg);
    assert!(z5.1 == vec![2, 1] && power(&vec![0, 1], 3, &vec![-1, -1]) == vec![1, 2]);
    println!("mistake 1, Z[root 5] for the ring: smallest unit {} + {} root 5 = {} = phi^3, regulator {}, not {}; ratio {}",
             z5.1[0], z5.1[1], f6(z5.0), f6(z5.0.ln()), f6(r5), f6(z5.0.ln() / r5));
    let k = logs(&vec![1, 1], &pl2)[0] / logs(&vec![3, 2], &pl2)[0]; assert!((k - 0.5).abs() < 1e-12);
    println!("mistake 2, Pell's 3 + 2 root 2 as fundamental: regulator {}; 1 + root 2 would be its power {}, not whole", f6(logs(&vec![3, 2], &pl2)[0]), f6(k));
    let l3: Vec<f64> = [pl3[0].0, pl3[1].0, C { re: pl3[1].0.re, im: -pl3[1].0.im }].iter().map(|&z| sig(&one3, z).abs().ln()).collect();
    println!("mistake 3, Q(cbrt 2) with r2 = 2, counting complex embeddings singly: rank {} predicted; logs of 1 + t + t^2 at the real and both complex embeddings {}: the pair matches, one direction, not two", info[2].r1 + 2 - 1, j6(&l3));
    let gi = study(&vec![1, 0], &vec![]); assert_eq!(gi.w, 4);
    println!("mistake 4, units of Q(i) taken as +1, -1 only: the box holds {}: {:?}", gi.n, gi.units);
    println!("ALL CHECKS PASS");
}
