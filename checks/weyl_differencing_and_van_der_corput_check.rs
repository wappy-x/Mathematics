// Weyl differencing and van der Corput -- the same check as the Python, in Rust.  No crates.
// e(x) = cos 2 pi x + i sin 2 pi x; ||x|| = distance from x to the nearest whole number.
// Roads: S(N) = sum of e(root2 n^2) added term by term, against |S|^2 rebuilt from the squared
// sum's linear inner sums in closed form; van der Corput's inequality and Weyl's bound against
// both; the second-derivative test against a directly added sum of n^(-it).
use std::f64::consts::PI;
use std::ops::{Add, Mul, Sub, Div};

#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
impl Add for C { type Output = C; fn add(self, o: C) -> C { C { re: self.re + o.re, im: self.im + o.im } } }
impl Sub for C { type Output = C; fn sub(self, o: C) -> C { C { re: self.re - o.re, im: self.im - o.im } } }
impl Mul for C { type Output = C;
    fn mul(self, o: C) -> C { C { re: self.re * o.re - self.im * o.im, im: self.re * o.im + self.im * o.re } } }
impl Div for C { type Output = C;
    fn div(self, o: C) -> C { let d = o.re * o.re + o.im * o.im;
        C { re: (self.re * o.re + self.im * o.im) / d, im: (self.im * o.re - self.re * o.im) / d } } }
impl C { fn abs(self) -> f64 { self.re.hypot(self.im) } fn conj(self) -> C { C { re: self.re, im: -self.im } } }
const Z0: C = C { re: 0.0, im: 0.0 };
const ONE: u128 = 1 << 32;

fn isqrt(v: u128) -> u128 {
    let mut x = (v as f64).sqrt() as u128;
    if x > 0 { x = (x + v / x) / 2; }
    while x * x > v { x -= 1; }
    while (x + 1) * (x + 1) <= v { x += 1; }
    x
}
// {m root2} for a whole number m >= 0, exact to 2^-32, by integer square root
fn fr2(m: u128) -> f64 {
    let v = m.checked_mul(m).and_then(|a| a.checked_mul(2 * ONE * ONE)).expect("overflow");
    (isqrt(v) % ONE) as f64 / ONE as f64
}
fn e(x: f64) -> C { C { re: (2.0 * PI * x).cos(), im: (2.0 * PI * x).sin() } }
fn nrm(x: f64) -> f64 { x.min(1.0 - x) }
// sum_{n=1}^{L} e(root2 m n), a geometric series in closed form
fn lin(m: u128, l: u128) -> C {
    if l == 0 { return Z0; }
    let r = e(fr2(m)); r * (e(fr2(m * l)) - C { re: 1.0, im: 0.0 }) / (r - C { re: 1.0, im: 0.0 })
}
fn r(h: u128, m: u128) -> C { e(fr2(h * h)) * lin(2 * h, m - h) }
fn pell(q_max: u64) -> (u64, u64) {
    let (mut p, mut q) = (1u64, 1u64);
    while p + q <= q_max { let np = p + 2 * q; q = p + q; p = np; }
    (p, q)
}

fn main() {
    let n_max: usize = 10000;
    let z: Vec<C> = (0..=n_max).map(|n| e(fr2((n * n) as u128))).collect();
    let mut s = Z0; let mut run = vec![0.0f64; n_max + 1]; let mut chart = vec![];
    for n in 1..=n_max { s = s + z[n]; run[n] = s.abs(); if n % 500 == 0 { chart.push(n); } }
    println!("root2 = 1.41421356; S(N) = sum_{{n<=N}} e(root2 n^2)");
    for &m in &[1000usize, n_max] {
        let sq = m as f64 + 2.0 * (1..m).map(|h| r(h as u128, m as u128).re).sum::<f64>();
        println!("N = {:5}: |S| added term by term {:.2}; from the squared sum {:.2}; root N {:.2}; |S|/N {:.6}",
            m, run[m], sq.sqrt(), (m as f64).sqrt(), run[m] / m as f64);
        assert!((sq - run[m] * run[m]).abs() < 1e-6 * m as f64);
    }
    for h in 1..=20usize {
        let mut d = Z0;
        for n in 1..=(n_max - h) { d = d + z[n + h] * z[n].conj(); }
        assert!((d - r(h as u128, n_max as u128)).abs() < 1e-5);
    }
    println!("r(h) closed form = r(h) added directly, h = 1..20: yes");
    let j = |v: Vec<String>| v.join(", ");
    println!("chart N: {}", j(chart.iter().map(|n| n.to_string()).collect()));
    println!("chart |S|: {}", j(chart.iter().map(|&n| format!("{:.1}", run[n])).collect()));
    println!("chart root N: {}", j(chart.iter().map(|&n| format!("{:.1}", (n as f64).sqrt())).collect()));
    println!("largest |S(N)| for N <= {}: {:.2}", n_max, run.iter().cloned().fold(0.0, f64::max));
    let nf = n_max as f64;
    let rs: Vec<C> = (0..n_max).map(|h| if h == 0 { Z0 } else { r(h as u128, n_max as u128) }).collect();
    assert!((1..n_max).all(|h| rs[h].abs() <= (nf - h as f64).min(1.0 / (2.0 * nrm(fr2(2 * h as u128)))) + 1e-9));
    let hs = [1usize, 6, 35, 204, 1189];
    println!("inner caps 1/(2||2h root2||), h = 1, 6, 35, 204, 1189: {}", j(hs.iter().map(|&h| format!("{:.3}", 1.0 / (2.0 * nrm(fr2(2 * h as u128))))).collect()));
    println!("  2h root2 is nearest {}", j(hs.iter().map(|&h| format!("{}", (2.0 * h as f64 * 2f64.sqrt()).round())).collect()));
    println!("inner sizes |r(h)|, same h: {}", j(hs.iter().map(|&h| format!("{:.3}", rs[h].abs())).collect()));
    println!("without the diagonal h = 0: 2 Re sum r(h) = {:.1}", 2.0 * rs.iter().map(|x| x.re).sum::<f64>());
    println!("van der Corput, N = {}, |S|^2 = {:.1}:", n_max, run[n_max] * run[n_max]);
    for &hh in &[1usize, 10, 100, 1000, n_max] {
        let hf = hh as f64; let w = (nf + hf - 1.0) / hf;
        let ex = w * (nf + 2.0 * (1..hh).map(|h| (1.0 - h as f64 / hf) * rs[h].re).sum::<f64>());
        let ab = w * (nf + 2.0 * (1..hh).map(|h| (1.0 - h as f64 / hf) * rs[h].abs()).sum::<f64>());
        println!("  H = {:5}: right side {:.1} (root {:.2}); with |r(h)| {:.1} (root {:.2})", hh, ex, ex.sqrt(), ab, ab.sqrt());
        assert!(run[n_max] * run[n_max] <= ex + 1e-6 && ex <= ab + 1e-6);
    }
    for &m in &[1000usize, n_max] {
        let mf = m as f64;
        let b = mf + 2.0 * (1..m).map(|h| (mf - h as f64).min(1.0 / (2.0 * nrm(fr2(2 * h as u128))))).sum::<f64>();
        let lsum: f64 = (1..2 * m - 1).map(|h| mf.min(1.0 / (2.0 * nrm(fr2(h as u128))))).sum();
        let (p, q) = pell(m as u64);
        assert!(((p * p) as i64 - (2 * q * q) as i64).abs() == 1);
        let qf = q as f64;
        let w = mf + 2.0 * (2.0 * mf / qf + 1.0) * (4.0 * mf + qf * (1.0 + qf.ln()));
        println!("Weyl, N = {:5}: sum of mins B = {:.1}, root {:.2}; fraction {}/{}; block bound {:.1}, root {:.2}",
            m, b, b.sqrt(), p, q, w, w.sqrt());
        assert!(run[m] * run[m] <= b && b - mf <= 2.0 * lsum + 1e-6 && 2.0 * lsum <= w - mf);
        let (mut blks, mut h0, qu) = (vec![], 1usize, q as usize);   // the fold's lemma, one block of q shifts at a time
        while h0 < 2 * m - 1 {
            let mut bl: Vec<f64> = (h0..(h0 + qu).min(2 * m - 1)).map(|h| mf.min(1.0 / (2.0 * nrm(fr2(h as u128))))).collect();
            bl.sort_by(|x, y| y.partial_cmp(x).unwrap()); blks.push(bl); h0 += qu;
        }
        let tight = blks.iter().flat_map(|bl| bl.iter().skip(4).enumerate().map(|(i, t)| t * 2.0 * (i / 2 + 1) as f64 / qf))
            .fold(0.0, f64::max);
        let allow = 4.0 * mf + qf * (1.0 + qf.ln());
        let bmax = blks.iter().map(|bl| bl.iter().sum::<f64>()).fold(0.0, f64::max);
        println!("  {} blocks of {} shifts: largest block sum {:.1} <= 4N + q(1 + log q) = {:.1}; after each block's top four, worst term / cap q/2, q/2, q/4, ... = {:.4}",
            blks.len(), q, bmax, allow, tight);
        assert!(blks.iter().all(|bl| bl.iter().sum::<f64>() <= allow) && tight < 1.0);
    }
    let rat = |n: usize| e(((1393 * n * n) % 985) as f64 / 985.0);
    let g = (1..=985).fold(Z0, |a, n| a + rat(n)).abs();
    let mut t = vec![Z0];
    for n in 1..=n_max { let last = t[n - 1]; t.push(last + rat(n)); }
    println!("1393/985: one period |G| = {:.4}, root 985 = {:.4}; |S(9850)| = {:.2} = 10 root 985; |S(1000)| = {:.2}; |S(10000)| = {:.2}",
        g, 985f64.sqrt(), t[9850].abs(), t[1000].abs(), t[n_max].abs());
    assert!((g - 985f64.sqrt()).abs() < 1e-9 && (t[9850].abs() - 10.0 * 985f64.sqrt()).abs() < 1e-7);
    let mut bins = [0i64; 10];
    for n in 1..=n_max { bins[(10.0 * fr2((n * n) as u128)) as usize] += 1; }
    let avg: Vec<f64> = [1u128, 2, 3].iter()
        .map(|&m| (1..=n_max).fold(Z0, |a, n| a + e(fr2(m * (n * n) as u128))).abs() / nf).collect();
    println!("{{root2 n^2}}, n <= 10000, ten bins: {}", bins.iter().map(|b| b.to_string()).collect::<Vec<_>>().join(" "));
    println!("Weyl averages, spins 1, 2, 3: {}", j(avg.iter().map(|a| format!("{:.6}", a)).collect()));
    assert!(bins.iter().sum::<i64>() == n_max as i64 && bins.iter().all(|&b| (b - 1000).abs() < 60)
        && avg.iter().cloned().fold(0.0, f64::max) < 0.03);
    let c3 = (1..=1000u128).fold(Z0, |a, n| a + e(fr2(n * n * n))).abs();
    println!("cubes: |sum_{{n<=1000}} e(root2 n^3)| = {:.2}", c3);
    let (tt, mm) = (100000.0f64, 10000usize);
    let f = |x: f64| -tt * x.ln() / (2.0 * PI);
    let zz = (mm + 1..=2 * mm).fold(Z0, |a, n| a + e(f(n as f64))).abs();
    let (lam, rho) = (tt / (2.0 * PI * (2.0 * mm as f64).powi(2)), 4.0);
    let k = rho * lam * mm as f64 + 2.0;
    let bnd = k * (2.0 / lam.sqrt() + 1.0) + (k + 1.0) * (2.0 / (PI * lam.sqrt()) + 1.0);
    println!("t = {:.0}, M = {}: |sum n^(-it)| = {:.2}; second-derivative bound {:.1}; trivial {}; stationary-phase size root(t/(2 pi)) = {:.2}",
        tt, mm, zz, bnd, mm, (tt / (2.0 * PI)).sqrt());
    println!("  lambda = {:.10}, root lambda = {:.6}, rho lambda M = {:.4}", lam, lam.sqrt(), rho * lam * mm as f64);
    assert!(zz <= bnd && bnd < mm as f64 && (zz - (tt / (2.0 * PI)).sqrt()).abs() < 0.05 * zz);
    // Kusmin-Landau: f'(x) = -t/(2 pi x) stays in the safe range -1.9..-1.1 for n0 <= n <= n1
    let (n0, n1, cap) = ((tt / (2.0 * PI * 1.9)) as usize + 1, (tt / (2.0 * PI * 1.1)) as usize, 1.0 / (PI * 0.1 / 2.0).tan() + 1.0);
    let fp = |x: f64| -tt / (2.0 * PI * x);
    for a in [mm + 1, n0] {                     // a piece inside the safe range, then all of it
        let kl = (a..=n1).fold(Z0, |s, n| s + e(f(n as f64))).abs();
        println!("Kusmin-Landau, n = {}..{}, f' from {:.5} to {:.5}, delta = 0.1: |sum| = {:.4}, bound cot(pi delta/2) + 1 = {:.4}",
            a, n1, fp(a as f64), fp(n1 as f64), kl, cap);
        assert!(-1.9 <= fp(a as f64) && fp(n1 as f64) <= -1.1 && kl <= cap);
    }
    let l2 = 2.0 * 2f64.sqrt();
    let k2 = l2 * nf + 2.0;
    let blind = k2 * (2.0 / l2.sqrt() + 1.0) + (k2 + 1.0) * (2.0 / (PI * l2.sqrt()) + 1.0);
    println!("second-derivative bound applied to root2 n^2 (f'' = {:.4} > 1/4), N = {}: {:.0} > N", l2, n_max, blind);
    assert!(blind > nf);
    println!("ALL CHECKS PASS");
}
