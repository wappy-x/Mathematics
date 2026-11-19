// The von Mangoldt function -- the same check as the Python, in Rust.  No
// crates.  Lambda(n) is ln p when n is a power of a prime p, and 0 otherwise.
// Every prime here comes from a sieve written out below; nothing imported
// knows a prime.  Roads: the sieve, trial division, an lcm built by Euclid's
// gcd, Mobius signs, partial summation, and zeta by Euler-Maclaurin.
const N: usize = 1_000_000;

fn lam(spf: &[usize], n: usize) -> f64 {           // von Mangoldt, from the sieve
    if n < 2 { return 0.0 }
    let (p, mut m) = (spf[n], n);
    while m % p == 0 { m /= p }
    if m == 1 { (p as f64).ln() } else { 0.0 }
}

fn mu(spf: &[usize], mut n: usize) -> i64 {        // Mobius: 0 if a square divides n
    let mut s = 1;
    while n > 1 {
        let p = spf[n]; n /= p;
        if n % p == 0 { return 0 }
        s = -s;
    }
    s
}

fn gcd(mut a: u64, mut b: u64) -> u64 { while b != 0 { (a, b) = (b, a % b) } a }   // Euclid

fn is_prime(n: usize) -> bool { n > 1 && (2..).take_while(|d| d * d <= n).all(|d| n % d != 0) }

// A big whole number as base-2^32 limbs, lowest first: just enough for lcm(1..100).
fn big_mod(a: &[u32], m: u64) -> u64 { a.iter().rev().fold(0, |r, &l| ((r << 32) | l as u64) % m) }
fn big_mul(a: &mut Vec<u32>, m: u64) {
    let mut carry = 0u64;
    for l in a.iter_mut() { let t = *l as u64 * m + carry; *l = t as u32; carry = t >> 32 }
    while carry > 0 { a.push(carry as u32); carry >>= 32 }
}
fn big_div(a: &mut Vec<u32>, m: u64) -> u64 {
    let mut r = 0u64;
    for l in a.iter_mut().rev() { let t = (r << 32) | *l as u64; *l = (t / m) as u32; r = t % m }
    while a.len() > 1 && *a.last().unwrap() == 0 { a.pop(); }
    r
}
fn big_ln(a: &[u32]) -> f64 {
    let k = a.len();
    let top = a[k - 1] as f64 * 4294967296.0 + a[k - 2] as f64;
    top.ln() + 32.0 * (k as f64 - 2.0) * 2f64.ln()
}
fn big_digits(a: &[u32]) -> usize {
    let (mut b, mut d) = (a.to_vec(), 0);
    while !(b.len() == 1 && b[0] == 0) { big_div(&mut b, 10); d += 1 }
    d
}

fn iroot(x: u64, k: u32) -> u64 { let mut m = 1; while (m + 1u64).pow(k) <= x { m += 1 } m }   // largest m^k <= x

fn main() {
    let mut spf: Vec<usize> = (0..=N).collect();
    for p in 2..=1000 {
        if spf[p] == p { let mut m = p * p; while m <= N { if spf[m] == m { spf[m] = p } m += p } }
    }
    let mut marks: Vec<usize> = (10..=100).step_by(10).collect();
    marks.extend([1000, 10_000, 100_000, 1_000_000]);
    let (mut pi, mut th, mut ps) = (0usize, 0.0f64, 0.0f64);
    let mut at = std::collections::HashMap::new();
    let mut primes: Vec<usize> = Vec::new();
    let mut l = vec![0.0f64; N + 1];
    for n in 2..=N {
        l[n] = lam(&spf, n);
        ps += l[n];
        if spf[n] == n { pi += 1; th += (n as f64).ln(); primes.push(n) }
        if marks.contains(&n) { at.insert(n, (pi, th, ps)); }
    }
    let (pi100, th100, ps100) = at[&100];
    let trial = (2..=100).filter(|&n| is_prime(n)).count();
    println!("primes to 100: sieve {}, trial division {}", pi100, trial);
    println!("psi(100) = {:.2}; theta(100) = {:.2}; prime powers p^2, p^3, ... add {:.2}", ps100, th100, ps100 - th100);
    let mut big = vec![1u32];
    for n in 1..=100u64 { let g = gcd(big_mod(&big, n), n); big_mul(&mut big, n / g) }   // never names a prime
    let lnbig = big_ln(&big);
    println!("lcm(1..100), built by gcd: {} digits, ln = {:.6}; psi(100) = {:.6}", big_digits(&big), lnbig, ps100);
    let theta_upto = |m: u64| -> f64 { primes.iter().filter(|&&p| p as u64 <= m).map(|&p| (p as f64).ln()).sum() };
    let parts: Vec<f64> = (1..=6).map(|k| theta_upto(iroot(100, k))).collect();
    let joined: Vec<String> = parts.iter().map(|t| format!("{:.2}", t)).collect();
    let psum: f64 = parts.iter().sum();
    println!("psi(100) as theta(100) + theta(10) + theta(4) + theta(3) + theta(2) + theta(2) = {} = {:.2}", joined.join(" + "), psum);
    let cheb: f64 = (2..=100).map(|d| l[d] * (100 / d) as f64).sum();
    let lnfact: f64 = (2..=100).map(|n| (n as f64).ln()).sum();
    println!("sum of Lambda(d) floor(100/d) = {:.6}; ln(100!) = {:.6}", cheb, lnfact);
    let h = 720720usize;
    let divs: Vec<usize> = (1..=h).filter(|d| h % d == 0).collect();
    let pp: Vec<usize> = divs.iter().copied().filter(|&d| l[d] > 0.0).collect();
    let ppsum: f64 = pp.iter().map(|&d| l[d]).sum();
    println!("720720: {} divisors, {} of them prime powers; their Lambda add to {:.6}; ln 720720 = {:.6}",
             divs.len(), pp.len(), ppsum, (h as f64).ln());
    let m = 10_000usize;
    let (mut one_lam, mut mu_log) = (vec![0.0f64; m + 1], vec![0.0f64; m + 1]);
    for d in 1..=m {
        let (md, ld) = (mu(&spf, d) as f64, (d as f64).ln());
        let mut k = d;
        while k <= m { one_lam[k] += l[d]; mu_log[k] -= md * ld; k += d }
    }
    let e1 = (1..=m).map(|n| (one_lam[n] - (n as f64).ln()).abs()).fold(0.0, f64::max);
    let e2 = (1..=m).map(|n| (mu_log[n] - l[n]).abs()).fold(0.0, f64::max);
    let yn = |c: bool| if c { "yes" } else { "no" };
    println!("up to {}: sum of Lambda(d) over d | n equals ln n: {}", m, yn(e1 < 1e-12));
    println!("up to {}: minus sum of mu(d) ln d over d | n equals Lambda(n): {}", m, yn(e2 < 1e-12));
    let upto = |x: usize| -> Vec<usize> { primes.iter().copied().filter(|&p| p <= x).collect() };
    let pi_from_theta = |x: usize| -> f64 {         // partial summation, theta -> pi
        let ps_ = upto(x);
        let (mut t, mut out) = (0.0f64, 0.0f64);
        for (i, &p) in ps_.iter().enumerate() {
            t += (p as f64).ln();
            let nxt = if i + 1 < ps_.len() { ps_[i + 1] } else { x };
            out += t * (1.0 / (p as f64).ln() - 1.0 / (nxt as f64).ln());
        }
        t / (x as f64).ln() + out
    };
    let theta_from_pi = |x: usize| -> f64 {         // partial summation, pi -> theta
        let ps_ = upto(x);
        let mut out = 0.0f64;
        for (i, &p) in ps_.iter().enumerate() {
            let nxt = if i + 1 < ps_.len() { ps_[i + 1] } else { x };
            out += (i + 1) as f64 * ((nxt as f64).ln() - (p as f64).ln());
        }
        ps_.len() as f64 * (x as f64).ln() - out
    };
    let (r100, r6, t100) = (pi_from_theta(100), pi_from_theta(N), theta_from_pi(100));
    println!("pi from theta by partial summation: pi(100) = {:.6}, pi(10^6) = {:.6}", r100, r6);
    println!("theta from pi by partial summation: theta(100) = {:.6}", t100);
    let dsum: f64 = (2..=N).map(|n| l[n] / (n as f64).powi(2)).sum::<f64>() + 1.0 / N as f64;
    let kk = 1000.0f64;
    let z2: f64 = (1..=1000).map(|n| 1.0 / (n as f64).powi(2)).sum::<f64>() + 1.0 / kk - 1.0 / (2.0 * kk * kk) + 1.0 / (6.0 * kk.powi(3));
    let lk = kk.ln();
    let dz2: f64 = (2..=1000).map(|n| (n as f64).ln() / (n as f64).powi(2)).sum::<f64>()
        + (lk + 1.0) / kk - lk / (2.0 * kk * kk) - (1.0 - 2.0 * lk) / (12.0 * kk.powi(3));
    println!("zeta(2) = {:.6}; -zeta'(2) = {:.6}; -zeta'(2)/zeta(2) = {:.5}", z2, dz2, dz2 / z2);
    println!("sum of Lambda(n)/n^2 to 10^6, plus tail 1/10^6 = {:.5}", dsum);
    println!("x | pi(x) | theta(x) | psi(x) | psi - theta | psi/x | pi ln x / x");
    for &x in &[100usize, 1000, 10_000, 100_000, 1_000_000] {
        let (a, b, c) = at[&x];
        let xf = x as f64;
        println!("{} | {} | {:.2} | {:.2} | {:.2} | {:.4} | {:.4}", x, a, b, c, c - b, c / xf, a as f64 * xf.ln() / xf);
    }
    let ten = &marks[..10];
    let row = |f: &dyn Fn(usize) -> String| ten.iter().map(|&x| f(x)).collect::<Vec<_>>().join(", ");
    println!("chart x: {}", row(&|x| x.to_string()));
    println!("chart psi: {}", row(&|x| format!("{:.2}", at[&x].2)));
    println!("chart theta: {}", row(&|x| format!("{:.2}", at[&x].1)));
    println!("chart pi: {}", row(&|x| at[&x].0.to_string()));
    let npp = (2..=100).filter(|&n| l[n] > 0.0).count();
    let whole: f64 = (2..=100).filter(|&n| l[n] > 0.0).map(|n| (n as f64).ln()).sum();
    println!("mistake 1, primes only: theta(100) = {:.2}, not {:.2}; at n = 8 the divisor sum gives {:.4}, not ln 8 = {:.4}",
             th100, ps100, 2f64.ln(), 8f64.ln());
    println!("mistake 2, weight ln n at each prime power: {:.2}, not {:.2}", whole, ps100);
    println!("mistake 3, weight 1 at each prime power: {}; pi(100) x ln 100 = {:.2}", npp, pi100 as f64 * 100f64.ln());
    println!("mistake 4, log base 10: {:.2}, not {:.2}", ps100 / 10f64.ln(), ps100);
    assert!(pi100 == trial && trial == 25);                       // sieve against trial division
    assert!((lnbig - ps100).abs() < 1e-9);                        // lcm road against Lambda road
    assert!((psum - ps100).abs() < 1e-9 && (cheb - lnfact).abs() < 1e-9);
    assert!(e1 < 1e-9 && e2 < 1e-9);                              // 1*Lambda = ln, mu*ln = Lambda
    assert!((r100 - 25.0).abs() < 1e-9 && (r6 - at[&N].0 as f64).abs() < 1e-6 && (t100 - th100).abs() < 1e-9);
    assert!((dsum - dz2 / z2).abs() < 1e-5);                      // Dirichlet series = -zeta'/zeta
    println!("ALL CHECKS PASS");
}
