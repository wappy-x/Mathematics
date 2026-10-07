// Dirichlet series and Mobius inversion -- the same check as the Python, in
// Rust.  No crates.  The example is the 12-hour clock: 12 = 2 x 2 x 3, with
// divisors 1, 2, 3, 4, 6, 12.  Complex numbers are a small (re, im) pair here.
#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
fn mul(a: C, b: C) -> C { C { re: a.re * b.re - a.im * b.im, im: a.re * b.im + a.im * b.re } }
fn pw(n: i64, s: C) -> C { // n^-s = e^(-a ln n) (cos(b ln n) - i sin(b ln n)) for s = a + bi
    let l = (n as f64).ln(); let r = (-s.re * l).exp();
    C { re: r * (s.im * l).cos(), im: -r * (s.im * l).sin() }
}
fn divisors(n: i64) -> Vec<i64> { (1..=n).filter(|d| n % d == 0).collect() }
fn factor(mut n: i64) -> Vec<i64> { // exponents of the primes, in order
    let (mut out, mut p) = (vec![], 2);
    while n > 1 { let mut e = 0; while n % p == 0 { n /= p; e += 1; } if e > 0 { out.push(e); } p += 1; }
    out
}
fn mu(n: i64) -> i64 { let e = factor(n); if e.iter().any(|&k| k > 1) { 0 } else if e.len() % 2 == 0 { 1 } else { -1 } }
fn sigma(n: i64) -> i64 { divisors(n).iter().sum() }
fn peeled(n: i64) -> i64 { let d = divisors(n); sigma(n) - d[..d.len() - 1].iter().map(|&k| peeled(k)).sum::<i64>() }
fn moebius(n: i64) -> i64 { divisors(n).iter().map(|&d| mu(d) * sigma(n / d)).sum() }
fn part(c: &dyn Fn(i64) -> i64, s: C, n: i64) -> C {
    let mut t = C { re: 0.0, im: 0.0 };
    for k in 1..=n { let p = pw(k, s); t.re += c(k) as f64 * p.re; t.im += c(k) as f64 * p.im; }
    t
}
fn main() {
    let tau = |n: i64| divisors(n).len() as i64;
    let one = |_: i64| 1i64;
    let s2 = C { re: 2.0, im: 0.0 };
    let mut peel = vec![0i64; 13]; peel[1] = 1; // road 2: each divisor sum of mu vanishes past 1
    for n in 2..13usize { let d = divisors(n as i64); peel[n] = -d[..d.len() - 1].iter().map(|&k| peel[k as usize]).sum::<i64>(); }
    let mut euler = vec![(1i64, 1i64)]; // road 3: expand (1 - 2^-s)(1 - 3^-s)(1 - 5^-s)(1 - 7^-s)
    for p in [2i64, 3, 5, 7] { let add: Vec<(i64, i64)> = euler.iter().map(|&(m, c)| (m * p, -c)).collect(); euler.extend(add); }
    let eu = |n: i64| euler.iter().find(|&&(m, _)| m == n).map_or(0, |&(_, c)| c);
    let pairs = divisors(12).iter().map(|&m| (m, 12 / m)).count() as i64;
    let formula: i64 = factor(12).iter().map(|e| e + 1).product();
    let ten: Vec<i64> = (1..=10).collect();
    let d12 = divisors(12);
    println!("divisors of 12: {:?}; pairs m x k = 12: {}; (2+1)(1+1) = {}", d12, pairs, formula);
    println!("tau(4) x tau(3) = {} x {} = {}; tau(2) x tau(2) = {}, but tau(4) = {}", tau(4), tau(3), tau(4) * tau(3), tau(2) * tau(2), tau(4));
    println!("mu(1..10) from the primes:         {:?}", ten.iter().map(|&n| mu(n)).collect::<Vec<_>>());
    println!("mu(1..10) by peeling divisor sums: {:?}", ten.iter().map(|&n| peel[n as usize]).collect::<Vec<_>>());
    println!("mu(1..10) from the Euler product:  {:?}", ten.iter().map(|&n| eu(n)).collect::<Vec<_>>());
    let m12: Vec<i64> = d12.iter().map(|&d| mu(d)).collect();
    println!("mu(6) = {}, mu(12) = {}; mu over the divisors of 12: {:?}, sum {}", mu(6), mu(12), m12, m12.iter().sum::<i64>());
    for n in [6i64, 12] {
        let terms: Vec<i64> = divisors(n).iter().map(|&d| mu(d) * sigma(n / d)).collect();
        println!("sigma({}) = {}; mu-weighted sigmas {:?} sum to {}; peeling gives {}", n, sigma(n), terms, terms.iter().sum::<i64>(), peeled(n));
    }
    let fig: Vec<String> = ten.iter().map(|&n| format!("{:.2}", part(&mu, s2, n).re)).collect();
    println!("figure, partial sums of mu(n)/n^2, N = 1..10: {}", fig.join(" "));
    for n in [10i64, 100, 1000] {
        let (z, m) = (part(&one, s2, n).re, part(&mu, s2, n).re);
        println!("s = 2, N = {:4}: zeta part {:.6} x mu part {:.6} = {:.6}", n, z, m, z * m);
    }
    let pi = std::f64::consts::PI;
    println!("6/pi^2 = {:.6}, the value 1/zeta(2) from Euler's pi^2/6", 6.0 / (pi * pi));
    let s = C { re: 2.0, im: 1.0 };
    let w = mul(part(&one, s, 1000), part(&mu, s, 1000));
    println!("s = 2 + i, N = 1000: product {:.6} + {:.6}i", w.re, w.im);
    let lam = |n: i64| if factor(n).iter().sum::<i64>() % 2 == 0 { 1 } else { -1 };
    println!("mistake 1, signs counting repeated primes: sum over d | 4 = {}, not 0", divisors(4).iter().map(|&d| lam(d)).sum::<i64>());
    println!("mistake 2, coefficients multiplied, not convolved: 12^-s gets 1 x 1 = 1, not {}", pairs);
    let cut: i64 = d12.iter().filter(|&&d| d <= 10 && 12 / d <= 10).map(|&d| mu(d)).sum();
    println!("mistake 3, ten terms of each series multiplied: 12^-s gets {}, not 0", cut);
    assert!((1..13).all(|n| mu(n) == peel[n as usize])); // definition = inverse of 1
    assert!(ten.iter().all(|&n| mu(n) == eu(n))); // = Euler product expanded
    assert!((1..13).all(|n| moebius(n) == n)); // sigma inverts to n
    let m1000 = part(&mu, s2, 1000).re;
    assert!((m1000 - 6.0 / (pi * pi)).abs() < 1e-3 && ((w.re - 1.0).powi(2) + w.im * w.im).sqrt() < 4e-3); // tails under 1/N
    println!("ALL CHECKS PASS");
}
