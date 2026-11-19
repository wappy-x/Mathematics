// The Riemann hypothesis and three equivalents -- the same check as the Python, in Rust.  No crates.
// Primes by a sieve and by Legendre's count; Li by series and by Simpson's rule; M(x) by the Mobius
// sieve and by the recursion sum M(x/n) = 1; psi checked by Chebyshev's identity sum psi(x/n) = log x!.
use std::collections::HashMap;
use std::f64::consts::{E, PI};
fn phi(x: u64, a: usize, pr: &[u64], memo: &mut HashMap<(u64, usize), i64>) -> i64 { // Legendre
    if a == 0 || x == 0 { return x as i64 }
    if let Some(&v) = memo.get(&(x, a)) { return v }
    let v = phi(x, a - 1, pr, memo) - phi(x / pr[a - 1], a - 1, pr, memo);
    memo.insert((x, a), v); v
}
fn mert(x: u64, memo: &mut HashMap<u64, i64>) -> i64 { // M(x) from sum_{n<=x} M(x/n) = 1 alone
    if let Some(&v) = memo.get(&x) { return v }
    let (mut total, mut n) = (1i64, 2u64);
    while n <= x { let v = x / n; let n2 = x / v; total -= (n2 - n + 1) as i64 * mert(v, memo); n = n2 + 1; }
    memo.insert(x, total); total
}
fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64) -> f64 {
    let n = 20000; let h = (b - a) / n as f64;
    let mut s = 0.0; for k in 1..n { s += (if k % 2 == 1 { 4.0 } else { 2.0 }) * f(a + k as f64 * h); }
    h / 3.0 * (f(a) + f(b) + s)
}
fn zeta(s: f64) -> f64 { // Euler-Maclaurin, valid for real s > -5, s != 1
    let nn = 50.0f64;
    let r = |m: usize| (0..m).fold(1.0, |p, j| p * (s + j as f64)) * nn.powf(-s - m as f64);
    let head: f64 = (1..50).map(|n| (n as f64).powf(-s)).sum();
    head + nn.powf(1.0 - s) / (s - 1.0) + nn.powf(-s) / 2.0 + r(1) / 12.0 - r(3) / 720.0 + r(5) / 30240.0
}
fn sigma_by_factors(mut n: u64) -> u64 { // product of (p^(k+1) - 1)/(p - 1), by trial division
    let (mut out, mut p) = (1u64, 2u64);
    while n > 1 { let mut pk = 1u64; while n % p == 0 { n /= p; pk *= p; } out *= (pk * p - 1) / (p - 1); p += 1; }
    out
}
fn join<T: ToString>(v: impl Iterator<Item = T>) -> String { v.map(|u| u.to_string()).collect::<Vec<_>>().join(", ") }
fn main() {
    const X: usize = 1_000_000; let sizes = [10_000usize, 100_000, 1_000_000];
    let mut flag = vec![true; X + 1]; flag[0] = false; flag[1] = false;
    let (mut mu, mut sig) = (vec![1i64; X + 1], vec![0u64; X + 1]);
    for p in 2..=X { // sieve: primes, and mu(n) one prime at a time
        if !flag[p] { continue }
        let mut m = p * p; while m <= X { flag[m] = false; m += p }
        let mut m = p; while m <= X { mu[m] = -mu[m]; m += p }
        let mut m = p * p; while m <= X { mu[m] = 0; m += p * p }
    }
    let primes: Vec<u64> = (2..=X).filter(|&p| flag[p]).map(|p| p as u64).collect();
    for d in 1..=X { let mut m = d; while m <= X { sig[m] += d as u64; m += d } } // sigma(n)
    let mut lam = vec![0.0f64; X + 1];
    for &p in &primes { let mut q = p as usize; while q <= X { lam[q] = (p as f64).ln(); q *= p as usize } }
    let (mut mc, mut psic) = (vec![0i64; X + 1], vec![0.0f64; X + 1]); let (mut m, mut ps) = (0i64, 0.0f64);
    for n in 1..=X { m += mu[n]; ps += lam[n]; mc[n] = m; psic[n] = ps } // running M(n), psi(n)
    let (mut pmemo, mut mmemo) = (HashMap::new(), HashMap::new());
    let gam = (1..1001).map(|k| 1.0 / k as f64).sum::<f64>() - 1000f64.ln() - 1.0 / 2000.0 + 1.0 / 12e6;
    let li = |y: f64| { let (mut t, mut s) = (1.0f64, 0.0); for k in 1..150 { t *= y / k as f64; s += t / k as f64 } gam + y.ln() + s };
    let li_ser = |x: f64| li(x.ln()) - li(2f64.ln());
    let li_int = |x: f64| simpson(&|u: f64| u.exp() / u, 2f64.ln(), x.ln());
    println!("1. The prime count against Li(x), and the RH-sized error");
    for &x in &sizes {
        let pi = primes.iter().filter(|&&p| p as usize <= x).count();
        let a = primes.iter().filter(|&&p| (p * p) as usize <= x).count();
        let (xf, b) = (x as f64, (x as f64).sqrt() * (x as f64).ln());
        println!("x = {}: pi sieve {}, Legendre {}; Li series {:.2}, Simpson {:.2}; pi - Li {:.2}; sqrt(x) log x {:.2}; /(8 pi) {:.2}",
            x, pi, phi(x as u64, a, &primes, &mut pmemo) + a as i64 - 1, li_ser(xf), li_int(xf), pi as f64 - li_ser(xf), b, b / (8.0 * PI));
    }
    let xf = X as f64; let xl = xf / xf.ln();
    println!("li(2) = {:.4}; pi - li at 10^6 {:.2}; x/log x at 10^6 {:.2}, gap {:.2}, ratio {:.4}",
        li(2f64.ln()), 78498.0 - li(xf.ln()), xl, 78498.0 - xl, 78498.0 / xl);
    println!("2. Chebyshev's psi(x) against x");
    for &x in &sizes {
        let f = x as f64;
        println!("x = {}: psi {:.2}; psi - x {:.2}; sqrt(x) log^2 x / (8 pi) {:.2}", x, psic[x], psic[x] - f, f.sqrt() * f.ln().powi(2) / (8.0 * PI));
    }
    let lhs: f64 = (1..=X).map(|n| psic[X / n]).sum(); let rhs: f64 = (2..=X).map(|k| (k as f64).ln()).sum();
    println!("Chebyshev at 10^6: sum psi(x/n) {:.2}; log x! {:.2}", lhs, rhs);
    println!("3. The Mertens function M(x); mu(6), mu(30), mu(12): {} {} {}", mu[6], mu[30], mu[12]);
    let best = |lo: usize| { let mut w = (0.0f64, 0usize); for n in lo..=X { let r = mc[n].abs() as f64 / (n as f64).sqrt(); if r >= w.0 { w = (r, n) } } w };
    let (worst, late) = (best(2), best(1000));
    for &x in &sizes {
        let f = x as f64;
        println!("x = {}: M sieve {}, recursion {}; |M|/sqrt(x) {:.4}; x^0.6 {:.1}", x, mc[x], mert(x as u64, &mut mmemo), mc[x].abs() as f64 / f.sqrt(), f.powf(0.6));
    }
    println!("largest |M(x)|/sqrt(x), 2 <= x <= 10^6: {:.4} at x = {} (M = {}); from 1000 on: {:.4} at x = {} (M = {})",
        worst.0, worst.1, mc[worst.1], late.0, late.1, mc[late.1]);
    println!("4. The Mellin step: sum mu(n)/n^s against 1/zeta(s)");
    let (mut miss75, mut abel75, mut acc75) = (0.0, 0.0, 0.0);
    for (s, lab) in [(2.0f64, "2.0"), (0.75, "0.75"), (0.6, "0.6")] {
        let (mut part, mut acc) = (Vec::new(), 0.0f64);
        for n in 1..=X { if mu[n] != 0 { acc += mu[n] as f64 * (n as f64).powf(-s) } if sizes.contains(&n) { part.push(acc) } }
        let mut abel = mc[X] as f64 * xf.powf(-s);
        for n in 1..X { abel += mc[n] as f64 * ((n as f64).powf(-s) - ((n + 1) as f64).powf(-s)) }
        println!("s = {}: 1/zeta {:.6}; partial sums to 10^4, 10^5, 10^6: {}; M-integral form at 10^6 {:.6}",
            lab, 1.0 / zeta(s), join(part.iter().map(|v| format!("{:.6}", v))), abel);
        if s == 0.75 { miss75 = (part[2] - 1.0 / zeta(s)).abs(); abel75 = abel; acc75 = acc }
    }
    println!("zeta(0.75) {:.6}; 6/pi^2 {:.6}", zeta(0.75), 6.0 / (PI * PI));
    println!("5. Robin's inequality sigma(n) < e^gamma n log log n");
    let gam2 = (1..=X).map(|k| 1.0 / k as f64).sum::<f64>() - xf.ln() - 1.0 / (2.0 * xf); // second road, 10^6 terms
    println!("Euler's constant: 1000 terms + corrections {:.10}; 10^6 terms {:.10}", gam, gam2);
    let eg = gam.exp(); let ratio = |n: usize| sig[n] as f64 / (n as f64 * (n as f64).ln().ln());
    let bad: Vec<usize> = (3..=X).filter(|&n| ratio(n) >= eg).collect();
    let mut top = (0.0f64, 0usize); for n in 5041..=X { if ratio(n) >= top.0 { top = (ratio(n), n) } }
    println!("e^gamma {:.6}; failures for 3 <= n <= 10^6: {}, largest {}; sigma(5040) {}, ratio {:.6}",
        eg, bad.len(), bad[bad.len() - 1], sig[5040], ratio(5040));
    println!("failures: {}", bad.iter().map(|n| n.to_string()).collect::<Vec<_>>().join(" "));
    println!("largest ratio for 5040 < n <= 10^6: {:.6} at n = {}, sigma {}", top.0, top.1, sig[top.1]);
    println!("6. The zeros' waves, and one zero off the line at height 14.134725");
    let t = 1000.0f64; let lg = (t / (2.0 * PI)).ln().powi(2) / (2.0 * PI);
    println!("T = 1000: zeros N(T) by the main term (T/2pi) log(T/(2pi e)) + 7/8 = {:.2}; sum of 1/|rho| about log^2(T/2pi) / (2pi) = {:.4}; times sqrt(x) {:.1}",
        t / (2.0 * PI) * (t / (2.0 * PI * E)).ln() + 7.0 / 8.0, lg, 1000.0 * lg);
    for (beta, lab) in [(0.5f64, "0.5"), (0.6, "0.6")] {
        println!("real part {}: wave size 2 x^beta / |rho| at 10^6 = {:.1}", lab, 2.0 * xf.powf(beta) / beta.hypot(14.134725));
    }
    println!("chart x = 20000k: M {}", join((1..51).map(|k| mc[20000 * k])));
    println!("chart sqrt(x): {}", join((1..51).map(|k| format!("{:.0}", ((20000 * k) as f64).sqrt()))));
    println!("chart -sqrt(x): {}", join((1..51).map(|k| format!("{:.0}", -((20000 * k) as f64).sqrt()))));
    assert!(primes.len() == 78498 && phi(X as u64, 168, &primes, &mut pmemo) + 167 == 78498); // two prime counts
    assert!(sizes.iter().all(|&x| (li_ser(x as f64) - li_int(x as f64)).abs() < 1e-4));     // two roads to Li
    assert!(sizes.iter().all(|&x| mc[x] == mert(x as u64, &mut mmemo)) && mc[X] == 212);     // two roads to M
    assert!((lhs - rhs).abs() < 1e-6 * rhs);                                                  // Chebyshev's identity
    assert!((abel75 - acc75).abs() < 1e-9 && miss75 < 0.01);                                  // Abel step; Mellin evidence
    assert!(sig[5040] == sigma_by_factors(5040) && sig[top.1] == sigma_by_factors(top.1 as u64) && bad[bad.len() - 1] == 5040);
    assert!((gam - gam2).abs() < 1e-10 && bad.len() == 26);                                    // two roads to gamma; Robin's list
    assert!(sizes.iter().all(|&x| (psic[x] - x as f64).abs() < (x as f64).sqrt() * (x as f64).ln().powi(2) / (8.0 * PI)));
    println!("ALL CHECKS PASS");
}
