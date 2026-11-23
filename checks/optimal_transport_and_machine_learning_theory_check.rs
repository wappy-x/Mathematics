// Optimal transport check: a sand pile moved into a trench, W1 and W2 by four roads,
// Monge's problem failing on a split, and the VC bound for a network that fits any labels.
// std only: the fractions, the integrals, the brute force and the bound are written out.

#[derive(Clone, Copy, PartialEq)]
struct Fr { n: i128, d: i128 }
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn fr(n: i128, d: i128) -> Fr { let g = gcd(n, d) * if d < 0 { -1 } else { 1 }; Fr { n: n / g, d: d / g } }
impl std::ops::Add for Fr { type Output = Fr; fn add(self, o: Fr) -> Fr { fr(self.n * o.d + o.n * self.d, self.d * o.d) } }
impl std::ops::Sub for Fr { type Output = Fr; fn sub(self, o: Fr) -> Fr { fr(self.n * o.d - o.n * self.d, self.d * o.d) } }
impl std::ops::Mul for Fr { type Output = Fr; fn mul(self, o: Fr) -> Fr { fr(self.n * o.n, self.d * o.d) } }
impl std::fmt::Display for Fr {
    fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
        if self.d == 1 { write!(f, "{}", self.n) } else { write!(f, "{}/{}", self.n, self.d) }
    }
}
fn fl(a: Fr) -> f64 { a.n as f64 / a.d as f64 }
fn int(k: i128) -> Fr { fr(k, 1) }
fn pw(b: Fr, k: usize) -> Fr { let mut r = int(1); for _ in 0..k { r = r * b; } r }
fn integ(c: &[Fr], a: i128, b: i128) -> Fr { // integral of sum c[k] x^k from a to b
    let mut s = int(0);
    for (k, ck) in c.iter().enumerate() { s = s + *ck * (pw(int(b), k + 1) - pw(int(a), k + 1)) * fr(1, k as i128 + 1); }
    s
}

// Pile: triangle cross-section on [0, 2] m, peak 1 m high at x = 1. Trench: [3, 4] m, 1 m deep.
fn f_cdf(x: f64) -> f64 {
    if x <= 0.0 { 0.0 } else if x <= 1.0 { x * x / 2.0 } else if x <= 2.0 { 1.0 - (2.0 - x) * (2.0 - x) / 2.0 } else { 1.0 }
}
fn g_cdf(y: f64) -> f64 { (y - 3.0).max(0.0).min(1.0) }
fn finv(u: f64) -> f64 { if u <= 0.5 { (2.0 * u).sqrt() } else { 2.0 - (2.0 * (1.0 - u)).sqrt() } }
fn ginv(u: f64) -> f64 { 3.0 + u }
fn pile(x: f64) -> f64 { if 0.0 <= x && x <= 2.0 { 1.0 - (x - 1.0).abs() } else { 0.0 } } // the roof's height in m: its density

fn perms(n: usize) -> Vec<Vec<usize>> { // lexicographic order, as Python's itertools
    if n == 0 { return vec![vec![]]; }
    let mut out = vec![];
    fn rec(rest: &mut Vec<usize>, cur: &mut Vec<usize>, out: &mut Vec<Vec<usize>>) {
        if rest.is_empty() { out.push(cur.clone()); return; }
        for i in 0..rest.len() { let v = rest.remove(i); cur.push(v); rec(rest, cur, out); cur.pop(); rest.insert(i, v); }
    }
    rec(&mut (0..n).collect(), &mut vec![], &mut out);
    out
}

const EPS: f64 = 0.05;
const DELTA: f64 = 0.01;
fn log2_bound(m: u64, d: u64) -> f64 { 1.0 + d as f64 * (2.0 * std::f64::consts::E * m as f64 / d as f64).log2() - EPS * m as f64 / 2.0 }
fn vc_m(d: u64) -> u64 {
    let mut lo = ((8.0 / EPS) as f64).ceil().max(d as f64) as u64; let mut hi = lo;
    while log2_bound(hi, d) > DELTA.log2() { hi *= 2; }
    while lo < hi { let mid = (lo + hi) / 2; if log2_bound(mid, d) > DELTA.log2() { lo = mid + 1; } else { hi = mid; } }
    lo
}
fn join(v: &[String]) -> String { v.join(" ") }

fn main() {
    let n_big = 200000usize;
    let us: Vec<f64> = (0..n_big).map(|k| (k as f64 + 0.5) / n_big as f64).collect();
    // ---- road 1: exact fractions
    let (z, h) = (int(0), fr(1, 2));
    let mx = integ(&[z, z, int(1)], 0, 1) + integ(&[z, int(2), int(-1)], 1, 2);
    let mx2 = integ(&[z, z, z, int(1)], 0, 1) + integ(&[z, z, int(2), int(-1)], 1, 2);
    let mxf = integ(&[z, z, z, z, h], 0, 1) + integ(&[z, int(2), int(-1), int(-1), h], 0, 1);
    let (my, my2) = (fr(7, 2), fr(37, 3));
    let w1x = my - mx;
    let w2x = mx2 + my2 - int(2) * (int(3) * mx + mxf);
    let anti = mx2 + my2 - int(2) * (int(4) * mx - mxf);
    let indep = mx2 + my2 - int(2) * mx * my;
    println!("exact: E[X] = {}, E[X^2] = {}, E[X F(X)] = {}, trench E[Y] = {}, E[Y^2] = {}", mx, mx2, mxf, my, my2);
    println!("exact pieces: E[X^2] = {} + {}, E[X F(X)] = {} + {}", integ(&[z, z, z, int(1)], 0, 1),
             integ(&[z, z, int(2), int(-1)], 1, 2), integ(&[z, z, z, z, h], 0, 1), integ(&[z, int(2), int(-1), int(-1), h], 0, 1));
    println!("exact: E[XY] in the monotone plan = 3 E[X] + E[X F(X)] = {}", int(3) * mx + mxf);
    println!("exact: W1 = {} m, W2^2 = {} m^2 = (5/2)^2 + {}", w1x, w2x, w2x - w1x * w1x);
    assert!(mx == int(1) && mx2 == fr(7, 6) && w1x == fr(5, 2) && w2x == fr(94, 15));
    // ---- road 2: quantile integral
    let nf = n_big as f64;
    let q1 = us.iter().fold(0.0, |s, &u| s + (finv(u) - ginv(u)).abs()) / nf;
    let q2 = us.iter().fold(0.0, |s, &u| { let e = finv(u) - ginv(u); s + e * e }) / nf;
    let qa = us.iter().fold(0.0, |s, &u| { let e = finv(u) - ginv(1.0 - u); s + e * e }) / nf;
    println!("quantile road: W1 = {:.6} m, W2^2 = {:.6} m^2, W2 = {:.6} m", q1, q2, q2.sqrt());
    assert!((q1 - fl(w1x)).abs() < 1e-6 && (q2 - fl(w2x)).abs() < 1e-6 && (qa - fl(anti)).abs() < 1e-6);
    // ---- road 3: area between the cumulative curves
    let mm = 400000usize;
    let mut cdf = 0.0;
    for k in 0..mm { let x = 4.0 * (k as f64 + 0.5) / mm as f64; cdf += (f_cdf(x) - g_cdf(x)).abs(); }
    cdf = cdf * 4.0 / mm as f64;
    println!("area road: W1 = {:.6} m", cdf);
    assert!((cdf - fl(w1x)).abs() < 1e-6);
    let kk = 4000usize; // midpoint sums over the two densities, not the moments of road 1
    let floor = (0..kk).fold(0.0, |s, k| s + 3.0 + (k as f64 + 0.5) / kk as f64) / kk as f64
        - (0..kk).fold(0.0, |s, k| { let x = 2.0 * (k as f64 + 0.5) / kk as f64; s + x * pile(x) }) * 2.0 / kk as f64;
    println!("dual road: price f(x) = x gives floor {:.6} m; the monotone plan costs {:.6} m", floor, q1);
    assert!((floor - q1).abs() < 1e-6);
    // ---- road 4: brute force over 720 plans
    let n = 6usize;
    let xs: Vec<f64> = (0..n).map(|k| finv((k as f64 + 0.5) / n as f64)).collect();
    let ys: Vec<f64> = (0..n).map(|k| ginv((k as f64 + 0.5) / n as f64)).collect();
    let ps = perms(n);
    let c1: Vec<f64> = ps.iter().map(|s| (0..n).fold(0.0, |a, i| a + (xs[i] - ys[s[i]]).abs()) / n as f64).collect();
    let c2: Vec<f64> = ps.iter().map(|s| (0..n).fold(0.0, |a, i| { let e = xs[i] - ys[s[i]]; a + e * e }) / n as f64).collect();
    let best = c2.iter().cloned().fold(f64::INFINITY, f64::min);
    let (min1, max1) = (c1.iter().cloned().fold(f64::INFINITY, f64::min), c1.iter().cloned().fold(f64::NEG_INFINITY, f64::max));
    let arg: Vec<&Vec<usize>> = ps.iter().zip(c2.iter()).filter(|(_, &c)| c - best < 1e-12).map(|(s, _)| s).collect();
    let ties = c1.iter().filter(|&&c| (c - min1).abs() < 1e-12).count();
    let in_order = *arg[0] == (0..n).collect::<Vec<usize>>();
    println!("loads at x = {} m", join(&xs.iter().map(|x| format!("{:.4}", x)).collect::<Vec<_>>()));
    println!("brute force, {} plans: W1 cost {:.6} m, tied by {} plans; worst {:.6}", c1.len(), min1, ties, max1);
    println!("brute force: best W2^2 {:.6}, {} best plan(s), in order: {}; reversed {:.6}", best, arg.len(),
             if in_order { "True" } else { "False" }, c2[c2.len() - 1]);
    assert!(ties == 720 && arg.len() == 1 && in_order && (min1 - 2.5).abs() < 1e-12);
    let worst = (0..c2.len()).fold(0, |b, i| if c2[i] > c2[b] { i } else { b });
    assert!(worst == c2.len() - 1); // the last plan, (5, 4, 3, 2, 1, 0), fully reversed, is the worst
    for n2 in [60usize, 600] {
        let d2 = (0..n2).fold(0.0, |a, k| { let u = (k as f64 + 0.5) / n2 as f64; let e = finv(u) - ginv(u); a + e * e }) / n2 as f64;
        println!("{} loads in order: W2^2 {:.6}", n2, d2);
    }
    // ---- Monge's map T(x) = 3 + F(x)
    for x in [0.0, 0.5, 1.0, 1.5, 2.0] {
        println!("Monge map: sand at {:.2} m goes to {:.4} m, carried {:.4} m", x, 3.0 + f_cdf(x), 3.0 + f_cdf(x) - x);
    }
    let fig: Vec<String> = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75].iter().map(|&a| format!("{:.2}>{:.4}", a, 3.0 + f_cdf(a))).collect();
    println!("figure, arrows {}", join(&fig));
    // ---- what breaks
    println!("reversed plan (near sand to near end): W1 {:.6}, W2 {:.6} (exact W2^2 {})", fl(w1x), fl(anti).sqrt(), anti);
    println!("independent plan (each grain spread over the trench): W2 {:.6} (exact W2^2 {})", fl(indep).sqrt(), indep);
    let mut dbl = 0.0;
    for i in 0..1000 { let x = 2.0 * (i as f64 + 0.5) / 1000.0; for j in 0..500 { let y = 3.0 + (j as f64 + 0.5) / 500.0; dbl += (x - y) * (x - y) * pile(x); } }
    assert!((dbl * (2.0 / 1000.0) * (1.0 / 500.0) - fl(indep)).abs() < 1e-5); // double integral over the densities
    let mass = integ(&[z, int(1)], 0, 1) + integ(&[int(2), int(-1)], 1, 2); // the pile's area, exact: 1
    for far in [3i64, 100] {
        let mut tv = 0.0;
        for k in 0..((far + 2) * 1000) {
            let x = k as f64 * 0.001 + 0.0005;
            let hole = if far as f64 <= x && x <= far as f64 + 1.0 { 1.0 } else { 0.0 };
            tv += (pile(x) - hole).abs();
        }
        tv = tv * 0.001 / 2.0;
        println!("trench at {} m: height difference {:.6}, W1 {:.6} m", far, tv, far as f64 + 0.5 - 1.0);
        assert!((tv - fl(mass + int(1)) / 2.0).abs() < 1e-9); // no overlap, so half of (pile's mass + trench's mass)
    }
    let dst = [(-1.0f64, 0.5f64), (1.0, 0.5)];
    let maps_ok = (0..2).filter(|&t| dst.iter().enumerate().all(|(j, &(_, m))| (m - if j == t { 1.0 } else { 0.0 }).abs() < 1e-12)).count();
    let split = dst.iter().fold(0.0, |a, &(y, m)| a + m * (y - 0.0f64).abs());
    println!("split: maps that fill both holes {} of 2; Kantorovich plan half each, cost {:.6} m", maps_ok, split);
    assert!((fl(anti).sqrt() - qa.sqrt()).abs() < 1e-6);
    // ---- the VC bound from the PAC card
    let (m1, mbig) = (vc_m(1), vc_m(50000));
    println!("VC bound, d = 1 (PAC card's caps): {} sales", m1);
    println!("VC bound, d = 50000 (network fitting any labels of 50000 photos): {} photos", mbig);
    println!("bound at m = 50000, d = 50000: log10 = {:.1}", log2_bound(50000, 50000) * 2f64.log10());
    assert!(m1 == 789 && mbig > 400 * 50000 && log2_bound(50000, 50000) > 0.0);
    // ---- try changing: a far trench, the power p = 3, a smaller network
    let far1 = us.iter().fold(0.0, |s, &u| s + (finv(u) - ginv(u) - 7.0).abs()) / nf;
    let far2 = us.iter().fold(0.0, |s, &u| { let e = finv(u) - ginv(u) - 7.0; s + e * e }) / nf;
    let w3 = us.iter().fold(0.0, |s, &u| { let e = finv(u) - ginv(u); s + e.abs() * e * e }) / nf;
    println!("try: trench at [10, 11] m: W1 {:.6} m, W2 {:.6} m; p = 3: W3 {:.6} m", far1, far2.sqrt(), w3.powf(1.0 / 3.0));
    println!("try: VC bound, d = 1000: {} photos", vc_m(1000));
    assert!((far2 - (9.5 * 9.5 + 1.0 / 60.0)).abs() < 1e-6);
    // ---- chart
    let row = |g: &dyn Fn(f64) -> f64| join(&(0..17).map(|k| format!("{:.3}", g(k as f64 / 4.0))).collect::<Vec<_>>());
    println!("chart, x {}", join(&(0..17).map(|k| format!("{:.2}", k as f64 / 4.0)).collect::<Vec<_>>()));
    println!("chart, F {}", row(&f_cdf));
    println!("chart, G {}", row(&g_cdf));
    println!("ALL CHECKS PASS");
}
