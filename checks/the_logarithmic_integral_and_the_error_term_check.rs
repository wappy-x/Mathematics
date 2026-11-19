// The logarithmic integral and the error term -- the same check as the Python, in Rust.  No crates.
// Primes by a sieve and by Legendre's count; li by its series and by an integral; the error of
// x/ln x against the expansion of li; Trudgian's explicit classical bound; the prime-square bias.
use std::collections::HashMap;

struct Primes { count: Vec<u32>, small: Vec<u64>, memo: HashMap<(u64, usize), u64> }

impl Primes {
    fn pi(&self, x: u64) -> u64 { self.count[x as usize] as u64 } // pi(x), read off the sieve
    fn phi(&mut self, x: u64, a: usize) -> u64 { // numbers up to x free of the first a primes
        if a == 0 { return x; }
        if x < self.small[a - 1] { return if x >= 1 { 1 } else { 0 }; }
        if let Some(&v) = self.memo.get(&(x, a)) { return v; }
        let v = self.phi(x, a - 1) - self.phi(x / self.small[a - 1], a - 1);
        self.memo.insert((x, a), v);
        v
    }
    fn legendre(&mut self, x: u64) -> u64 { // Legendre: pi(x) = phi(x, a) + a - 1, a = pi(sqrt x)
        let a = self.small.iter().filter(|&&p| p * p <= x).count();
        self.phi(x, a) + a as u64 - 1
    }
    fn big_pi(&self, x: u64) -> f64 { // Riemann's weighted count: prime powers p^k weigh 1/k
        let bits = 64 - x.leading_zeros() as u64;
        (1..bits).map(|k| self.pi(iroot(x, k as u32)) as f64 / k as f64).sum()
    }
}

fn iroot(x: u64, k: u32) -> u64 { // largest r with r^k <= x, exactly
    let mut r = (x as f64).powf(1.0 / k as f64).round() as u64;
    while r.checked_pow(k).map_or(true, |v| v > x) { r -= 1; }
    while (r + 1).checked_pow(k).map_or(false, |v| v <= x) { r += 1; }
    r
}

fn li(x: f64, gam: f64) -> f64 { // li(x) = gamma + ln ln x + sum (ln x)^k / (k k!)
    let (l, mut term, mut s) = (x.ln(), 1.0f64, 0.0f64);
    for k in 1..200 { term *= l / k as f64; s += term / k as f64; }
    gam + l.ln() + s
}

fn li_integral(x: f64) -> f64 { // Li(x) = integral of e^u / u, u from ln 2 to ln x (Simpson)
    let (a, b, n) = (2f64.ln(), x.ln(), 20000);
    let h = (b - a) / n as f64;
    let f = |u: f64| u.exp() / u;
    let inner: f64 = (1..n).map(|k| (if k % 2 == 1 { 4.0 } else { 2.0 }) * f(a + k as f64 * h)).sum();
    h / 3.0 * (f(a) + f(b) + inner)
}

fn trud(x: f64) -> f64 { 0.2795 * x / x.ln().powf(0.75) * (-(x.ln() / 6.455).sqrt()).exp() } // x >= 229
fn ratio(l: f64) -> f64 { 0.2795 * l.powf(1.25) * (-(l / 6.455).sqrt()).exp() }      // bound / (x/L^2)
fn join(v: &[f64]) -> String { v.iter().map(|t| format!("{:.2}", t)).collect::<Vec<_>>().join(", ") }

fn main() {
    const X: u64 = 10_000_000;
    let mut flag = vec![true; X as usize + 1];
    flag[0] = false; flag[1] = false;
    for p in 2..3163usize { // sieve of Eratosthenes up to 10^7
        if flag[p] { let mut m = p * p; while m <= X as usize { flag[m] = false; m += p; } }
    }
    let mut count = vec![0u32; X as usize + 1];
    let mut run = 0u32;
    for n in 0..=X as usize { if flag[n] { run += 1; } count[n] = run; }
    let small: Vec<u64> = (2..3163u64).filter(|&p| flag[p as usize]).collect(); // the 446 primes up to sqrt(10^7)
    let mut pr = Primes { count, small, memo: HashMap::new() };
    let gam = (1..=1000).map(|k| 1.0 / k as f64).sum::<f64>() - 1000f64.ln() - 1.0 / 2000.0 + 1.0 / 12e6 - 1.0 / 120e12;
    let lix = |x: f64| li(x, gam);
    let li2 = lix(2.0);
    println!("li(2) = {:.5}; li(10^6) = {:.2}, Li(10^6) = {:.2}; pi(10^6) = {}", li2, lix(1e6), lix(1e6) - li2, pr.pi(1_000_000));
    println!("x | pi sieve | pi Legendre | x/ln x | li series | Li integral + li(2) | li - pi | pi - x/ln x");
    for e in 3..8u32 {
        let x = 10u64.pow(e); let xf = x as f64; let p = pr.pi(x) as f64;
        println!("10^{} | {} | {} | {:.2} | {:.2} | {:.2} | {:.2} | {:.2}", e, pr.pi(x), pr.legendre(x), xf / xf.ln(),
            lix(xf), li_integral(xf) + li2, lix(xf) - p, p - xf / xf.ln());
    }
    let (xf, l, p) = (X as f64, (X as f64).ln(), pr.pi(X) as f64);
    println!("at 10^7: ratio pi/(x/ln x) {:.5}; x/ln x low by {:.2} percent; li high by {:.3} percent; Li(10^7) = {:.2}",
        p / (xf / l), 100.0 * (1.0 - xf / l / p), 100.0 * (lix(xf) / p - 1.0), lix(xf) - li2);
    let (mut part, mut terms, mut fact) = (0.0f64, Vec::new(), 1.0f64);
    for k in 0..5 { if k > 0 { fact *= k as f64; } part += fact * xf / l.powi(k + 1); terms.push(part); }
    println!("expansion x/L (1 + 1/L + 2!/L^2 + 3!/L^3 + 4!/L^4), partial sums: {}", join(&terms));
    println!("pi - x/ln x = {:.2}; x/L^2 = {:.2}; x/L^2 + 2x/L^3 + 6x/L^4 = {:.2}", p - xf / l, xf / l.powi(2), terms[3] - terms[0]);
    let leg = xf / (l - 1.08366);
    println!("Legendre x/(L - 1.08366): {:.2}, off {:.2}; x/(L - 1): {:.2}, off {:.2}; ln base 10: {:.2}",
        leg, leg - p, xf / (l - 1.0), xf / (l - 1.0) - p, xf / xf.log10());
    println!("Trudgian's bound at 10^7: {:.2}; true |pi - li| {:.2}; RH bound sqrt(x) ln x/(8 pi) {:.2}",
        trud(xf), lix(xf) - p, xf.sqrt() * l / (8.0 * std::f64::consts::PI));
    let ls = [16, 50, 100, 200, 400, 1000];
    let parts: Vec<String> = ls.iter().map(|&q| format!("{}: {:.3}", q, ratio(q as f64))).collect();
    println!("bound / (x/L^2) at L = {}", parts.join(", "));
    let first = (16..2000).find(|&q| ratio(q as f64) < 1.0).unwrap();
    println!("bound / (x/L^2), with L = ln x, first below 1 at L = {}, x about 10^{:.1}", first, first as f64 / 10f64.ln());
    let u = xf.sqrt() / l; // the natural unit for the error: sqrt(x)/ln x
    println!("at 10^7: unit sqrt(x)/ln x {:.2}; Pi(x) {:.2}; li - Pi {:.2}; half pi(sqrt x) {:.1}; Pi - pi {:.2}",
        u, pr.big_pi(X), lix(xf) - pr.big_pi(X), pr.pi(iroot(X, 2)) as f64 / 2.0, pr.big_pi(X) - p);
    let miss: Vec<f64> = (3..8u32).map(|e| { let x = 10f64.powi(e as i32); pr.pi(10u64.pow(e)) as f64 - x / x.ln() }).collect();
    println!("log 10 = {:.6}; log 10^7 = {:.3}; sqrt(10^7) = {:.2}; primes up to it: {}; x^0.9 at 10^7 = {:.2}",
        10f64.ln(), l, xf.sqrt(), pr.small.len(), xf.powf(0.9));
    let grow: Vec<String> = miss.windows(2).map(|w| format!("{:.2}", w[1] / w[0])).collect();
    println!("x/ln x miss grows per factor 10: {}; x/ln x miss / li miss {:.1}; Trudgian / true gap {:.1}",
        grow.join(", "), (p - xf / l) / (lix(xf) - p), trud(xf) / (lix(xf) - p));
    println!("in units at 10^7: Pi - pi {:.2}; half pi(sqrt x) {:.2}; first wave 2/14.134725 = {:.2}; log log log(1.4 x 10^316) = {:.2}",
        (pr.big_pi(X) - p) / u, pr.pi(iroot(X, 2)) as f64 / 2.0 / u, 2.0 / 14.134725, (316.0 * 10f64.ln() + 1.4f64.ln()).ln().ln());
    let pts: [u64; 13] = [1000, 2000, 5000, 10000, 20000, 50000, 100000, 200000, 500000, 1000000, 2000000, 5000000, 10000000];
    let unit = |x: f64| x.sqrt() / x.ln();
    let g1: Vec<f64> = pts.iter().map(|&x| (lix(x as f64) - pr.pi(x) as f64) / unit(x as f64)).collect();
    let g2: Vec<f64> = pts.iter().map(|&x| (lix(x as f64) - pr.big_pi(x)) / unit(x as f64)).collect();
    println!("chart (li - pi)/unit: {}", join(&g1));
    println!("chart (li - Pi)/unit: {}", join(&g2));
    let gap: Vec<f64> = g1.iter().zip(&g2).map(|(a, b)| a - b).collect();
    println!("chart gap between the lines: {}", join(&gap));
    assert!(pr.pi(X) == pr.legendre(X) && pr.pi(X) == 664579 && pr.pi(1_000_000) == 78498); // two counts, table value
    assert!((lix(xf) - (li_integral(xf) + li2)).abs() < 1e-4 && (lix(1e6) - 78627.55).abs() < 0.01); // series vs integral
    assert!(((p - xf / l) - (terms[3] - terms[0])).abs() < xf / l.powi(4)); // x/ln x misses by the expansion's terms
    assert!(pts.iter().all(|&x| (lix(x as f64) - pr.pi(x) as f64).abs() <= trud(x as f64))); // Trudgian's bound holds
    assert!(g1.iter().all(|&v| v > 0.0) && g2[12].abs() < 0.5 && g1[12] > 1.5); // li overshoots; Pi carries no bias
    println!("ALL CHECKS PASS");
}
