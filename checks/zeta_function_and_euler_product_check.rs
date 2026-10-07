// The zeta function and the Euler product -- the same check as the Python, in Rust.  No crates.
// zeta(s) = sum of n^-s with n^-s = e^(-s ln n).  zeta(2) three ways: 1000 terms plus a tail bracket,
// the product over primes, pi^2/6 from the sine product.  Then 6/pi^2 by counting coprime ticket pairs.
use std::f64::consts::PI;
#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
fn c(re: f64, im: f64) -> C { C { re, im } }
fn add(a: C, b: C) -> C { c(a.re + b.re, a.im + b.im) }
fn sub(a: C, b: C) -> C { c(a.re - b.re, a.im - b.im) }
fn div(a: C, b: C) -> C { let m = b.re * b.re + b.im * b.im; c((a.re * b.re + a.im * b.im) / m, (a.im * b.re - a.re * b.im) / m) }
fn md(a: C) -> f64 { a.re.hypot(a.im) }
fn sieve(m: usize) -> Vec<usize> { // the primes up to m, Eratosthenes
    let mut flag = vec![true; m + 1]; flag[0] = false; flag[1] = false;
    let mut p = 2;
    while p * p <= m { if flag[p] { let mut k = p * p; while k <= m { flag[k] = false; k += p; } } p += 1; }
    (0..=m).filter(|&k| flag[k]).collect()
}
fn npow(n: usize, s: C) -> C { // n^-s = e^(-s ln n): size n^-(Re s), turn -(Im s) ln n
    let l = (n as f64).ln(); let (r, t) = ((-s.re * l).exp(), -s.im * l);
    c(r * t.cos(), r * t.sin())
}
fn euler(pr: &[usize], s: C, p_max: usize) -> C { // product over primes p <= P of 1/(1 - p^-s)
    pr.iter().take_while(|&&p| p <= p_max).fold(c(1.0, 0.0), |e, &p| div(e, sub(c(1.0, 0.0), npow(p, s))))
}
fn show(w: C) -> String { // 'a + bi', six decimals
    let a = format!("{:.6}", w.re); let a = if a == "-0.000000" { "0.000000".to_string() } else { a };
    let b = format!("{:.6}", w.im.abs());
    format!("{} {} {}i", a, if w.im < 0.0 && b != "0.000000" { '-' } else { '+' }, b)
}
fn gcd(a: usize, b: usize) -> usize { if b == 0 { a } else { gcd(b, a % b) } } // Euclid's algorithm
fn main() {
    let (n, pm) = (1000usize, 1000usize);
    let (pr, z2) = (sieve(100000), PI * PI / 6.0);
    let s1: f64 = (1..=n).map(|k| 1.0 / (k * k) as f64).sum(); // road 1: 1000 terms, tail between 1/(N+1) and 1/N
    let (lo, hi) = (s1 + 1.0 / (n + 1) as f64, s1 + 1.0 / n as f64);
    println!("zeta(2), 1000 terms: sum {:.8}, bracket [{:.8}, {:.8}], both ends {:.4} {:.4}", s1, lo, hi, lo, hi);
    let e2 = euler(&pr, c(2.0, 0.0), pm).re; // road 2: 168 primes up to 1000
    println!("Euler product, {} primes <= 1000: {:.8}, gap to pi^2/6 {:.8}, bound 1/P {:.8}",
        pr.iter().filter(|&&p| p <= pm).count(), e2, (e2 - z2).abs(), 1.0 / pm as f64);
    let sp: f64 = (1..=100000).map(|k| 1.0 - 0.25 / (k as f64 * k as f64)).product(); // road 3: the sine product at x = 1/2
    println!("road 3: pi^2/6 = {:.8}; sine product at x = 1/2, 100000 factors {:.6}, 2/pi {:.6}", z2, sp, 2.0 / PI);
    let s = c(2.0, 1.0);
    let ser = (1..=n).fold(c(0.0, 0.0), |a, k| add(a, npow(k, s)));
    let eul = euler(&pr, s, pm);
    println!("s = 2 + i: 1000 terms {}, product {}, gap {:.6}; |5^-s| = {:.6}", show(ser), show(eul), md(sub(ser, eul)), md(npow(5, s)));
    let d: Vec<C> = [c(1e-6, 0.0), c(0.0, 1e-6)].iter().map(|&h| div(sub((1..=n).fold(c(0.0, 0.0), |a, k| add(a, npow(k, add(s, h)))), ser), h)).collect(); // holomorphy
    println!("slope of the 1000-term sum at 2 + i: step along 1 {}, step along i {}", show(d[0]), show(d[1]));
    let mut cp = vec![0usize; n + 1]; // cp[M] = coprime pairs (a, b) with 1 <= a, b <= M
    for m in 1..=n {
        cp[m] = cp[m - 1] + 2 * (1..=m).filter(|&a| gcd(a, m) == 1).count() - if m == 1 { 1 } else { 0 };
    }
    let share = cp[n] as f64 / (n * n) as f64;
    println!("tickets 1 to 1000: {} of {} pairs coprime, share {:.6}; 6/pi^2 {:.6}; 1/product {:.6}", cp[n], n * n, share, 1.0 / z2, 1.0 / e2);
    let s4: f64 = (1..5).map(|k| 1.0 / (k * k) as f64).sum();
    println!("by hand: 4 terms {:.6}, bracket [{:.6}, {:.6}]; primes 2, 3, 5: {:.6}; tickets 1 to 6: {} of 36",
        s4, s4 + 1.0 / 5.0, s4 + 1.0 / 4.0, euler(&pr, c(2.0, 0.0), 5).re, cp[6]);
    let split: usize = (1..=n).map(|g| cp[n / g]).sum();
    println!("split every pair by its gcd g: sum of C(N//g) = {}", split);
    let xs = [10usize, 100, 1000, 10000, 100000];
    let rp: Vec<f64> = xs.iter().map(|&x| pr.iter().filter(|&&p| p <= x).map(|&p| 1.0 / p as f64).sum()).collect();
    let row = |v: Vec<f64>| v.iter().map(|y| format!("{:.2}", y)).collect::<Vec<_>>().join(", ");
    println!("chart, sum of 1/p for p <= x: {}", row(rp.clone()));
    println!("chart, ln ln x: {}", row(xs.iter().map(|&x| (x as f64).ln().ln()).collect()));
    println!("floor ln ln(x+1) - 1: {}", row(xs.iter().map(|&x| ((x + 1) as f64).ln().ln() - 1.0).collect()));
    let h: f64 = (1..=pm).map(|k| 1.0 / k as f64).sum();
    let e1 = pr[..168].iter().fold(1.0, |e, &p| e / (1.0 - 1.0 / p as f64));
    println!("at s = 1: harmonic sum to 1000 {:.6}, product over primes <= 1000 {:.6}", h, e1);
    let all: f64 = (2..=n).map(|k| 1.0 / (1.0 - 1.0 / (k * k) as f64)).product();
    println!("mistake, product over all n from 2 to 1000: {:.6}", all);
    println!("figure, 60 per unit, 0 at (60, 150): s = 1 at ({}, 150), s = 2 at ({}, 150), s = 2 + i at ({}, {})",
        60 + 60 * 1, 60 + 60 * 2, 60 + 60 * 2, 150 - 60 * 1);
    assert!(lo <= z2 && z2 <= hi && (e2 - z2).abs() < 1.0 / pm as f64); // three roads to zeta(2) agree
    assert!(md(sub(ser, eul)) <= 1.0 / n as f64 + 1.0 / pm as f64 && md(sub(d[0], d[1])) < 1e-4 && (sp - 2.0 / PI).abs() <= 0.25 / 100000.0); // complex s; holomorphy; sine product
    assert!(split == n * n && (share - 1.0 / z2).abs() < (n as f64).ln() / n as f64); // the count meets 6/pi^2
    assert!(xs.iter().zip(&rp).all(|(&x, &v)| v >= ((x + 1) as f64).ln().ln() - 1.0) && e1 >= h); // sum of 1/p grows
    println!("ALL CHECKS PASS");
}
