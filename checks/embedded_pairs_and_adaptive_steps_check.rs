// Embedded pairs on a model rocket's climb: where the Dormand-Prince weights come from,
// and what a tolerance does and does not control.  Standard library only.
// Road 1, exact fractions: each rooted tree with up to 5 nodes gives one linear order
//   condition, sum of b_i Phi_i(tree) = 1/gamma(tree); solving them gives the weights.
// Road 2, closed form: the climb is tanh while the motor burns and tan while it coasts,
//   checked against the adaptive solver that runs on the weights from road 1.
use std::collections::BTreeSet;
#[derive(Clone, Copy, PartialEq, Debug)] struct Q { n: i128, d: i128 } // an exact fraction
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i128, d: i128) -> Q { let g = gcd(n, d).max(1) * d.signum(); Q { n: n / g, d: d / g } }
impl std::ops::Add for Q { type Output = Q; fn add(self, o: Q) -> Q { q(self.n * o.d + o.n * self.d, self.d * o.d) } }
impl std::ops::Sub for Q { type Output = Q; fn sub(self, o: Q) -> Q { q(self.n * o.d - o.n * self.d, self.d * o.d) } }
impl std::ops::Mul for Q { type Output = Q; fn mul(self, o: Q) -> Q { q(self.n * o.n, self.d * o.d) } }
impl std::ops::Div for Q { type Output = Q; fn div(self, o: Q) -> Q { q(self.n * o.d, self.d * o.n) } }
impl std::fmt::Display for Q { fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
    if self.d == 1 { write!(f, "{}", self.n) } else { write!(f, "{}/{}", self.n, self.d) } } }
const S: usize = 7;
const FREE: [usize; 7] = [0, 1, 2, 3, 4, 5, 6]; // all seven weights free
fn tableau() -> Vec<Vec<Q>> {
    let raw: [&[(i128, i128)]; 7] = [&[], &[(1, 5)], &[(3, 40), (9, 40)], &[(44, 45), (-56, 15), (32, 9)],
        &[(19372, 6561), (-25360, 2187), (64448, 6561), (-212, 729)],
        &[(9017, 3168), (-355, 33), (46732, 5247), (49, 176), (-5103, 18656)],
        &[(35, 384), (0, 1), (500, 1113), (125, 192), (-2187, 6784), (11, 84)]];
    raw.iter().map(|r| r.iter().map(|&(n, d)| q(n, d)).collect()).collect()
}
fn forests(n: usize) -> Vec<Vec<String>> { // every sorted list of trees with n nodes in all
    let mut out: BTreeSet<Vec<String>> = BTreeSet::new();
    if n == 0 { out.insert(vec![]); }
    for k in 1..=n { for t in trees(k) { for f in forests(n - k) {
        let mut g = f.clone(); g.push(t.clone()); g.sort(); out.insert(g); } } }
    out.into_iter().collect()
}
fn trees(n: usize) -> Vec<String> { forests(n - 1).iter().map(|f| format!("[{}]", f.concat())).collect() }
fn kids(s: &str) -> Vec<String> { // the subtrees hanging from the root
    let (b, mut out, mut depth, mut start) = (s.as_bytes(), vec![], 0i32, 1usize);
    for i in 1..s.len() - 1 { depth += if b[i] == b'[' { 1 } else { -1 };
        if depth == 0 { out.push(s[start..i + 1].to_string()); start = i + 1; } }
    out
}
fn phi(a: &[Vec<Q>], s: &str) -> Vec<Q> { // Phi_i(tree) for every stage i
    let mut v = vec![q(1, 1); S];
    for k in kids(s) { let p = phi(a, &k);
        for i in 0..S { let mut t = q(0, 1); for j in 0..i { t = t + a[i][j] * p[j]; } v[i] = v[i] * t; } }
    v
}
fn gamma(s: &str) -> i128 { s.matches('[').count() as i128 * kids(s).iter().map(|k| gamma(k)).product::<i128>() }
fn conditions(a: &[Vec<Q>], p: usize) -> Vec<Vec<Q>> {
    let mut rows = vec![];
    for n in 1..=p { for t in trees(n) { let ph = phi(a, &t);
        let mut r: Vec<Q> = FREE.iter().map(|&j| ph[j]).collect(); r.push(q(1, gamma(&t))); rows.push(r); } }
    rows
}
fn solve(rows: &[Vec<Q>]) -> (usize, Vec<Q>) { // exact Gauss-Jordan: rank, and weights if unique
    let (mut m, mut rk) = (rows.to_vec(), 0);
    for col in 0..FREE.len() {
        let piv = match (rk..m.len()).find(|&r| m[r][col].n != 0) { Some(p) => p, None => continue };
        m.swap(rk, piv);
        let p = m[rk][col]; m[rk] = m[rk].iter().map(|&x| x / p).collect();
        for r in 0..m.len() { if r != rk && m[r][col].n != 0 { let (f, top) = (m[r][col], m[rk].clone());
            m[r] = m[r].iter().zip(&top).map(|(&x, &y)| x - f * y).collect(); } }
        rk += 1;
    }
    assert!(m[rk..].iter().all(|r| r[FREE.len()].n == 0)); // the conditions do not contradict each other
    let mut w = vec![q(0, 1); S];
    if rk == FREE.len() { for (i, &j) in FREE.iter().enumerate() { w[j] = m[i][FREE.len()]; } }
    (rk, w)
}
fn miss(a: &[Vec<Q>], w: &[Q], t: &str) -> Q { let ph = phi(a, t); (0..S).fold(q(0, 1), |s, i| s + w[i] * ph[i]) - q(1, gamma(t)) }
fn fr(w: &[Q]) -> String { w.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(", ") }
fn fl(x: Q) -> f64 { x.n as f64 / x.d as f64 }
// ---- the rocket: 50 m/s^2 of thrust for 1.5 s, gravity, drag 0.00225 v^2 per metre ----
const G: f64 = 9.81; const THRUST: f64 = 50.0; const TB: f64 = 1.5; const K: f64 = 0.00225;
struct Pair { a: Vec<Vec<f64>>, c: Vec<f64>, b5: Vec<f64>, b4: Vec<f64> }
fn rate(on: bool, y: [f64; 2]) -> [f64; 2] { [y[1], (if on { THRUST } else { 0.0 }) - G - K * y[1] * y[1].abs()] }
fn dot(w: &[f64], k: &[[f64; 2]], n: usize) -> f64 { let mut s = 0.0; for (a, q) in w.iter().zip(k) { s += a * q[n]; } s }
fn step(p: &Pair, t: f64, y: [f64; 2], h: f64, blind: bool, b4: &[f64]) -> ([f64; 2], [f64; 2]) {
    let mut k: Vec<[f64; 2]> = vec![];
    for i in 0..S { let yi = [y[0] + h * dot(&p.a[i], &k, 0), y[1] + h * dot(&p.a[i], &k, 1)];
        k.push(rate(if blind { t + p.c[i] * h < TB } else { t < TB }, yi)); }
    ([y[0] + h * dot(&p.b5, &k, 0), y[1] + h * dot(&p.b5, &k, 1)], [y[0] + h * dot(b4, &k, 0), y[1] + h * dot(b4, &k, 1)])
}
fn exact(t: f64) -> [f64; 2] { // closed form, valid until the top at 6.26 s
    let a = THRUST - G; let (w1, v1) = ((a * K).sqrt(), (a / K).sqrt());
    if t <= TB { return [(w1 * t).cosh().ln() / K, v1 * (w1 * t).tanh()]; }
    let (yb, vb) = ((w1 * TB).cosh().ln() / K, v1 * (w1 * TB).tanh());
    let (w, vg) = ((G * K).sqrt(), (G / K).sqrt()); let ph = (vb / vg).atan(); let s = t - TB;
    [yb + ((ph - w * s).cos() / ph.cos()).ln() / K, vg * (ph - w * s).tan()]
}
fn ratio(y: [f64; 2], y5: [f64; 2], y4: [f64; 2], tol: f64) -> f64 { // worst gap over its allowance tol (1 + size)
    (0..2).fold(0.0, |e: f64, n| e.max((y5[n] - y4[n]).abs() / (tol * (1.0 + y[n].abs().max(y5[n].abs()))))) }
struct Run { y: [f64; 2], ends: Vec<f64>, lens: Vec<f64>, path: Vec<[f64; 2]>, rej: u32 }
fn run(p: &Pair, tol: f64, unit: bool, keep5: bool, blind: bool, b4: &[f64]) -> Run {
    let (tend, mut h, mut t) = (6.0f64, 0.1f64, 0.0f64);
    let mut r = Run { y: [0.0, 0.0], ends: vec![], lens: vec![], path: vec![], rej: 0 };
    while t < tend - 1e-12 {
        let hs = if t < TB && !blind { h.min(tend - t).min(TB - t) } else { h.min(tend - t) };
        let (y5, y4) = step(p, t, r.y, hs, blind, b4);
        let err = ratio(r.y, y5, y4, tol) / (if unit { hs } else { 1.0 });
        let fac = if err == 0.0 { 5.0 } else { 5.0f64.min(0.2f64.max(0.9 * (1.0 / err).powf(if unit { 0.25 } else { 0.2 }))) };
        if err <= 1.0 {
            t += hs; r.y = if keep5 { y5 } else { y4 }; r.ends.push(t); r.lens.push(hs); r.path.push(r.y);
            h = if hs < h { h.max(hs * fac) } else { hs * fac };
        } else { r.rej += 1; h = hs * fac; }
    }
    r
}
fn err6(y: [f64; 2]) -> [f64; 2] { let e = exact(6.0); [y[0] - e[0], y[1] - e[1]] }
fn join(x: &[f64], d: usize) -> String { x.iter().map(|v| format!("{:.*}", d, v)).collect::<Vec<_>>().join(", ") }
fn main() {
    let a = tableau();
    let c: Vec<Q> = a.iter().map(|r| r.iter().fold(q(0, 1), |s, &x| s + x)).collect();
    println!("trees with 1..5 nodes: {}", (1..6).map(|n| trees(n).len().to_string()).collect::<Vec<_>>().join(" "));
    let (c4, c5) = (conditions(&a, 4), conditions(&a, 5));
    let (r4, (r5, w5)) = (solve(&c4).0, solve(&c5));
    println!("order 4: {} conditions, rank {}; order 5: {} conditions, rank {}", c4.len(), r4, c5.len(), r5);
    println!("order-5 weights b: {}", fr(&w5));
    let mut pub5 = a[6].clone(); pub5.push(q(0, 1));
    assert!(w5 == pub5); // the published fifth-order weights, b_7 = 0
    let mut rows = c4.clone(); rows.push(vec![q(0, 1), q(0, 1), q(0, 1), q(0, 1), q(0, 1), q(0, 1), q(1, 1), q(1, 40)]);
    let w4 = solve(&rows).1;
    println!("order-4 weights with bhat_7 = 1/40: {}", fr(&w4));
    assert!(w4 == vec![q(5179, 57600), q(0, 1), q(7571, 16695), q(393, 640), q(-92097, 339200), q(187, 2100), q(1, 40)]);
    println!("bhat misses order 5: bushy tree {}, tall tree {}", miss(&a, &w4, "[[][][][]]"), miss(&a, &w4, "[[[[[]]]]]"));
    let count = |w: &[Q]| trees(5).iter().filter(|t| miss(&a, w, t).n != 0).count();
    println!("bhat misses order 5 on {} of 9 trees; b on {}", count(&w4), count(&w5));
    let p = Pair { a: a.iter().map(|r| r.iter().map(|&x| fl(x)).collect()).collect(), c: c.iter().map(|&x| fl(x)).collect(),
        b5: w5.iter().map(|&x| fl(x)).collect(), b4: w4.iter().map(|&x| fl(x)).collect() };
    println!("stage times c: {}; rocket: thrust {:?} m/s^2 for {:?} s, gravity {:?} m/s^2, drag {:?} v^2 per metre", fr(&c), THRUST, TB, G, K);
    let sci = |x: f64| format!("{:.3e}", x);
    let [yb, vb] = exact(TB);
    println!("burnout, exact: height {:.6} m, speed {:.6} m/s; top at {:.4} s", yb, vb, TB + (vb / (G / K).sqrt()).atan() / (G * K).sqrt());
    let (y5, y4) = step(&p, TB, [yb, vb], 1.0, false, &p.b4); let ex = exact(TB + 1.0);
    println!("by hand, h = 1 s from burnout: fifth {:.6} m, {:.6} m/s; fourth {:.6} m, {:.6} m/s", y5[0], y5[1], y4[0], y4[1]);
    println!("gaps {} m, {} m/s; allowances {}, {}", sci(y4[0] - y5[0]), sci(y4[1] - y5[1]), sci(1e-6 * (1.0 + y5[0])), sci(1e-6 * (1.0 + vb)));
    let e = ratio([yb, vb], y5, y4, 1e-6);
    println!("worst ratio {:.4}: rejected; next try {:.4} s", e, 5.0f64.min(0.2f64.max(0.9 * (1.0 / e).powf(0.2))));
    println!("true errors at 2.5 s: fourth {} m, {} m/s; fifth {} m, {} m/s", sci(y4[0] - ex[0]), sci(y4[1] - ex[1]), sci(y5[0] - ex[0]), sci(y5[1] - ex[1]));
    assert!(((y4[0] - y5[0]) / (y4[0] - ex[0]) - 1.0).abs() < 0.05);
    let b = run(&p, 1e-6, false, true, true, &p.b4);
    let i = b.ends.iter().position(|&t| t > TB).unwrap();
    let (mn, mx) = (b.lens.iter().cloned().fold(f64::MAX, f64::min), b.lens.iter().cloned().fold(0.0, f64::max));
    println!("blind, tol 1e-6: kept {}, rejected {}, steps {:.5} s to {:.4} s", b.ends.len(), b.rej, mn, mx);
    println!("blind: speed error after the burnout step {} m/s; at 6 s {} m, {} m/s", sci(b.path[i][1] - exact(b.ends[i])[1]), sci(err6(b.y)[0]), sci(err6(b.y)[1]));
    println!("figure, step ends t: {}", join(&b.ends, 3));
    println!("figure, log10 step: {}", join(&b.lens.iter().map(|x| x.log10()).collect::<Vec<_>>(), 2));
    let l = run(&p, 1e-6, false, true, false, &p.b4);
    println!("landing on burnout: kept {}, rejected {}; at 6 s {} m, {} m/s", l.ends.len(), l.rej, sci(err6(l.y)[0]), sci(err6(l.y)[1]));
    assert!(err6(l.y)[1].abs() * 100.0 < err6(b.y)[1].abs() && err6(l.y)[0].abs() < 1e-4 && (l.ends.len(), l.rej) == (10, 0));
    let tols: [f64; 7] = [1e-4, 1e-5, 1e-6, 1e-7, 1e-8, 1e-9, 1e-10];
    println!("figure, log10 tol: {}", join(&tols.iter().map(|t| t.log10()).collect::<Vec<_>>(), 2));
    let mut slopes = vec![];
    for unit in [false, true] { for keep5 in [true, false] {
        let name = format!("{}{}", if unit { "per unit step" } else { "per step" }, if keep5 { ", keep 5th" } else { ", keep 4th" });
        let res: Vec<Run> = tols.iter().map(|&t| run(&p, t, unit, keep5, false, &p.b4)).collect();
        let ys: Vec<f64> = res.iter().map(|r| err6(r.y)[0].abs().log10()).collect();
        let xm = tols.iter().map(|t| t.log10()).sum::<f64>() / 7.0; let ym = ys.iter().sum::<f64>() / 7.0;
        let num: f64 = tols.iter().zip(&ys).map(|(t, v)| (t.log10() - xm) * (v - ym)).sum();
        let sl = num / tols.iter().map(|t| (t.log10() - xm).powi(2)).sum::<f64>();
        slopes.push(sl); assert!(res[6].ends.len() == if unit { 81 } else { 49 }); // steps at 1e-10, quoted on the card
        let th = if keep5 { if unit { 5.0 / 4.0 } else { 1.0 } } else if unit { 1.0 } else { 4.0 / 5.0 }; // Why it works, Step 5
        println!("{}: steps {}; slope {:.2}, theory {:.2}", name, res.iter().map(|r| r.ends.len().to_string()).collect::<Vec<_>>().join(" "), sl, th);
        println!("  height error at 6 s: {}", res.iter().map(|r| format!("{:.2e}", err6(r.y)[0])).collect::<Vec<_>>().join(" "));
        println!("  figure, log10 error: {}", join(&ys, 2));
    } }
    assert!(0.7 < slopes[1] && slopes[1] < 0.9 && 0.85 < slopes[3] && slopes[3] < 1.15 && 0.85 < slopes[0] && slopes[0] < 1.15);
    let z = run(&p, 1e-6, false, true, false, &p.b5);
    println!("breaks: bhat = b, so every estimate is 0: kept {}, height error {} m", z.ends.len(), sci(err6(z.y)[0]));
    println!("ALL CHECKS PASS");
}
