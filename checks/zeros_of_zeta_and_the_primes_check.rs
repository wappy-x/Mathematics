// Zeta's zeros and the primes -- the same check as the Python, in Rust.  No crates.  Primes by a
// sieve and by Legendre; li by series and by integral; the first zero by a chase and by a box.
use std::collections::HashMap;
use std::f64::consts::PI;
#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
fn c(re: f64, im: f64) -> C { C { re, im } }
fn add(a: C, b: C) -> C { c(a.re + b.re, a.im + b.im) }  fn sub(a: C, b: C) -> C { c(a.re - b.re, a.im - b.im) }
fn mul(a: C, b: C) -> C { c(a.re * b.re - a.im * b.im, a.re * b.im + a.im * b.re) }
fn div(a: C, b: C) -> C { let d = b.re * b.re + b.im * b.im; c((a.re * b.re + a.im * b.im) / d, (a.im * b.re - a.re * b.im) / d) }
fn sc(k: f64, a: C) -> C { c(k * a.re, k * a.im) }  fn md(a: C) -> f64 { a.re.hypot(a.im) }
fn pw(x: f64, s: C) -> C { let (m, t) = ((s.re * x.ln()).exp(), s.im * x.ln()); c(m * t.cos(), m * t.sin()) } // x^s
fn phi(x: u64, a: usize, pr: &[u64], memo: &mut HashMap<(u64, usize), i64>) -> i64 { // none of the first a primes
    if a == 0 || x == 0 { return x as i64 } if let Some(&v) = memo.get(&(x, a)) { return v }
    let v = phi(x, a - 1, pr, memo) - phi(x / pr[a - 1], a - 1, pr, memo); memo.insert((x, a), v); v
}
fn zeta(s: C) -> C { // head sum + tail integral + end corrections (Euler-Maclaurin)
    let r = |m: usize| mul((0..m).fold(c(1.0, 0.0), |p, j| mul(p, add(s, c(j as f64, 0.0)))), pw(50.0, sub(c(-(m as f64), 0.0), s)));
    let z = (1..50).fold(c(0.0, 0.0), |z, k| add(z, pw(k as f64, sc(-1.0, s))));
    let z = add(add(z, div(pw(50.0, sub(c(1.0, 0.0), s)), sub(s, c(1.0, 0.0)))), sc(0.5, pw(50.0, sc(-1.0, s))));
    add(sub(add(z, sc(1.0 / 12.0, r(1))), sc(1.0 / 720.0, r(3))), sc(1.0 / 30240.0, r(5)))
}
fn secant(mut a: C, mut b: C) -> C { // chase a zero of zeta through the complex plane
    for _ in 0..60 { if md(zeta(b)) > 1e-12 { let nb = sub(b, div(mul(zeta(b), sub(b, a)), sub(zeta(b), zeta(a)))); a = b; b = nb; } } b
}
fn mid(f: &dyn Fn(f64) -> f64, a: f64, b: f64) -> f64 { let h = (b - a) / 40000.0; h * (0..40000).map(|k| f(a + (k as f64 + 0.5) * h)).sum::<f64>() }
fn row(v: &[f64]) -> String { v.iter().map(|u| format!("{:.2}", u)).collect::<Vec<_>>().join(", ") }
fn main() {
    let (big, mut memo) = (1_000_000usize, HashMap::new()); let mut flag = vec![true; big + 1]; flag[0] = false; flag[1] = false;
    for p in 2..1001 { if flag[p] { let mut m = p * p; while m <= big { flag[m] = false; m += p } } }
    let primes: Vec<u64> = (0..=big as u64).filter(|&p| flag[p as usize]).collect();
    let mut powers: Vec<(f64, f64)> = Vec::new(); // (p, p^k)
    for &p in &primes { let mut q = p; while q <= big as u64 { powers.push((p as f64, q as f64)); q *= p } }
    let psi = |x: f64| powers.iter().filter(|w| w.1 <= x).map(|w| w.0.ln()).sum::<f64>() + 0.0; // ln p per power
    let lam: f64 = powers.iter().map(|w| w.0.ln() / (w.1 * w.1)).sum(); // -zeta'/zeta(2), cut at 10^6
    let gam = (1..1001).map(|k| 1.0 / k as f64).sum::<f64>() - 1000f64.ln() - 1.0 / 2000.0 + 1.0 / 12e6;
    let li_series = |y: f64| { let (mut t, mut s) = (1.0, 0.0); for k in 1..150 { t *= y / k as f64; s += t / k as f64 } gam + y.ln() + s };
    let li_integral = |y: f64| mid(&|u: f64| 2.0 * u.sinh() / u, 0.0, y) - mid(&|u: f64| (-u).exp() / u, y, y + 60.0);
    let cs = [c(0.0, 10.0), c(1.0, 10.0), c(1.0, 20.0), c(0.0, 20.0), c(0.0, 10.0)]; // the box
    let bx: Vec<C> = cs.windows(2).flat_map(|w| (0..2000).map(move |k| add(w[0], sc(k as f64 / 2000.0, sub(w[1], w[0]))))).chain([cs[0]]).collect();
    let (mut count, mut wh) = (c(0.0, 0.0), c(0.0, 0.0));
    for w in bx.windows(2) { // step-by-step ratios of zeta round the box
        let u = div(zeta(w[1]), zeta(w[0])); let d = c(md(u).ln(), u.im.atan2(u.re)); count = add(count, d); wh = add(wh, mul(sc(0.5, add(w[0], w[1])), d));
    }
    let (count, wh) = (div(count, c(0.0, 2.0 * PI)), div(wh, c(0.0, 2.0 * PI)));
    let z1 = secant(c(0.6, 14.0), c(0.6, 14.3));
    let slope = -(zeta(c(2.00001, 0.0)).re - zeta(c(1.99999, 0.0)).re) / 2e-5 / zeta(c(2.0, 0.0)).re;
    let mo: Vec<f64> = (0..1001).map(|k| md(zeta(c(0.5, k as f64 / 10.0)))).collect(); // mo[k] at t = k/10
    let mut zeros: Vec<C> = Vec::new();
    for k in 2..1000 { // every dip of |zeta| on the line, chased to a zero
        if mo[k] > mo[k - 1].min(mo[k + 1]) { continue }
        let z = secant(c(0.5, k as f64 / 10.0), c(0.5, k as f64 / 10.0 + 0.05));
        if z.im > 1.0 && zeros.iter().all(|&w| md(sub(z, w)) > 1e-6) { zeros.push(z) }
    }
    let rebuild = |x: f64, kk: usize| x - (2.0 * PI).ln() - (1.0 - x.powi(-2)).ln() / 2.0 - 2.0 * zeros[..kk].iter().map(|&r| div(pw(x, r), r).re).sum::<f64>();
    let xs: Vec<f64> = (1..30).map(|k| k as f64 + 0.5).collect();
    for (x, a) in [(100u64, 4usize), (1000, 11), (1_000_000, 168)] { // a = number of primes up to sqrt(x)
        let (pi, y) = (primes.iter().filter(|&&p| p <= x).count(), (x as f64).ln());
        println!("x = {}: pi sieve {}, Legendre {}; x/ln x {:.2}; li series {:.2}, integral {:.2}; pi - li {:.2}", x, pi,
            phi(x, a, &primes, &mut memo) + a as i64 - 1, x as f64 / y, li_series(y), li_integral(y), pi as f64 - li_series(y));
    }
    println!("RH bound at 10^6, valid from x = 2657: sqrt(x) ln x / (8 pi) = {:.2}", 1000.0 * 1e6f64.ln() / (8.0 * PI));
    let only: f64 = primes.iter().map(|&p| (p as f64).ln() / (p * p) as f64).sum();
    println!("-zeta'/zeta(2): prime powers to 10^6 {:.5}; slope of zeta {:.5}; primes only {:.5}", lam, slope, only);
    println!("first zero, chased from 0.6 + 14i: {:.6} + {:.6}i\nbox 0..1 x 10..20: turns {:.6}; zero located {:.6} + {:.6}i", z1.re, z1.im, count.re, wh.re, wh.im);
    let ((lo, hi), hs): ((f64, f64), Vec<String>) = (zeros.iter().fold((9.0, 0.0), |(l, h), z| (l.min(z.re), h.max(z.re))), zeros[..6].iter().map(|z| format!("{:.3}", z.im)).collect());
    println!("zeros up to height 100: {}, real parts {:.5} to {:.5}; heights {} ...", zeros.len(), lo, hi, hs.join(" "));
    let (p0, r0, r29): (Vec<f64>, Vec<f64>, Vec<f64>) = (xs.iter().map(|&x| psi(x)).collect(), xs.iter().map(|&x| rebuild(x, 0)).collect(), xs.iter().map(|&x| rebuild(x, 29)).collect());
    println!("chart at x = 1.5, 2.5, ..., 29.5, psi: {}\nchart no zeros: {}\nchart {} zero pairs: {}", row(&p0), row(&r0), zeros.len(), row(&r29));
    let miss = |r: &[f64]| p0.iter().zip(r).map(|(a, b)| (a - b).abs()).fold(0.0, f64::max);
    let err = miss(&r29);
    println!("largest miss at the half-integers: no zeros {:.2}, 29 pairs {:.2}; log base 10 at 10^6: {:.0}", miss(&r0), err, 1e6 / 6.0);
    println!("figure, x = 60 + 120 Re s, y = 230 - 6 Im s: line x 120; heights y {}", zeros[..6].iter().map(|z| format!("{:.1}", 230.0 - 6.0 * z.im)).collect::<Vec<_>>().join(" "));
    assert!(primes.len() == 78498 && phi(1_000_000, 168, &primes, &mut memo) + 167 == 78498); // two counts, one number
    assert!((li_series(1e6f64.ln()) - li_integral(1e6f64.ln())).abs() < 1e-3); // two roads to li
    assert!(md(sub(z1, wh)) < 1e-6 && md(sub(z1, c(0.5, 14.134725142))) < 1e-8 && md(sub(count, c(1.0, 0.0))) < 1e-9); // chase, box, table
    assert!((lam - slope).abs() < 1e-5 && err < 0.5); // series vs slope; rebuild
    println!("ALL CHECKS PASS");
}
