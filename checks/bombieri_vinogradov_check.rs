// Bombieri-Vinogradov -- the check behind the card.  std only.  For every modulus q up to root x
// it finds the worst class error E(q) = max over a of |pi(x; q, a) - li(x)/phi(q)| and adds them
// up, at x = 10^4, 10^5 and 10^6.  Class counts come from a sieve read in steps of q and, as a
// second road, from residues of a trial-division prime list; li(x) from its series and Simpson's rule.
const X: usize = 1_000_000;
const GAMMA: f64 = 0.5772156649015329; // Euler's constant, quoted

fn gcd(a: usize, b: usize) -> usize { if b == 0 { a } else { gcd(b, a % b) } }
fn isqrt(n: usize) -> usize { let mut r = (n as f64).sqrt() as usize; while r * r > n { r -= 1; } while (r + 1) * (r + 1) <= n { r += 1; } r }
fn coprime(q: usize) -> Vec<usize> { (1..=q).filter(|&a| gcd(a, q) == 1).collect() }
fn li_series(x: f64) -> f64 { // li(x) = gamma + ln ln x + sum (ln x)^n / (n n!)
    let (u, mut term, mut s, mut n) = (x.ln(), 1.0f64, 0.0f64, 0.0f64);
    loop {
        n += 1.0; term *= u / n; s += term / n;
        if term / n < 1e-17 * s { return GAMMA + u.ln() + s; }
    }
}
fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, m: usize) -> f64 {
    let h = (b - a) / m as f64;
    let mut inner = 0.0;
    for k in 1..m { inner += (if k % 2 == 1 { 4.0 } else { 2.0 }) * f(a + k as f64 * h); }
    h / 3.0 * (f(a) + f(b) + inner)
}
fn step_count(flag: &[bool], start: usize, x: usize, q: usize) -> usize { (start..=x).step_by(q).filter(|&n| flag[n]).count() }
fn counts_sieve(flag: &[bool], x: usize, q: usize) -> Vec<usize> { coprime(q).iter().map(|&a| step_count(flag, a, x, q)).collect() }
fn counts_res(ps: &[usize], q: usize) -> Vec<usize> { // the same, by residues of a prime list
    let mut c = vec![0usize; q + 1];
    for &p in ps { let r = if q == 1 { 1 } else { p % q }; c[r] += 1; }
    coprime(q).iter().map(|&a| c[a]).collect()
}
fn worst(c: &[usize], share: f64) -> f64 { c.iter().map(|&v| (v as f64 - share).abs()).fold(0.0, f64::max) }

fn main() {
    let mut flag = vec![true; X + 1]; flag[0] = false; flag[1] = false; // road 1: sieve
    for p in 2..1001 { if flag[p] { let mut m = p * p; while m <= X { flag[m] = false; m += p; } } }
    let primes: Vec<usize> = (0..=X).filter(|&p| flag[p]).collect();
    let small: Vec<usize> = (2..1001).filter(|&p| (2..isqrt(p) + 1).all(|d| p % d != 0)).collect();
    let is_prime_td = |n: usize| -> bool { // road 2: trial division
        for &d in &small { if d * d > n { return true; } if n % d == 0 { return false; } }
        true
    };
    let td: Vec<usize> = (2..=X).filter(|&n| is_prime_td(n)).collect();
    println!("primes below 10^6: sieve {}; trial division {}", primes.len(), td.len());
    let li_b = simpson(|u: f64| u.exp() / u, 2f64.ln(), (X as f64).ln(), 20000) + li_series(2.0);
    println!("li(10^6): series {:.2}; Simpson from 2 plus li(2) {:.2}", li_series(X as f64), li_b);
    let check_q: Vec<usize> = (1..101).chain([997, 1000]).collect();
    let agree = check_q.iter().all(|&q| counts_sieve(&flag, X, q) == counts_res(&td, q));
    println!("class counts, sieve against trial division: agree on all {} moduli tested: {}", check_q.len(),
        if agree { "True" } else { "False" });
    let mut ratios = vec![]; let mut e6 = vec![0.0f64; 1001];
    for e in [4u32, 5, 6] {
        let x = 10usize.pow(e); let qmax = isqrt(x); let li = li_series(x as f64); let xf = x as f64;
        let mut ev = vec![0.0f64; qmax + 1];
        for q in 1..=qmax { let c = counts_sieve(&flag, x, q); ev[q] = worst(&c, li / c.len() as f64); }
        let s: f64 = ev[1..].iter().sum(); ratios.push(s / (xf / xf.ln()));
        let rel = |q: usize| ev[q] * coprime(q).len() as f64 / li;
        let mut wq = 1; for q in 1..=qmax { if rel(q) > rel(wq) { wq = q; } }
        println!("x = 10^{}: Q = {}; S = sum of E(q) = {:.2}; x/ln x = {:.2}; ratio {:.4}; mean E(q) {:.2}; worst relative miss {:.2} percent at q = {}",
            e, qmax, s, xf / xf.ln(), ratios[ratios.len() - 1], s / qmax as f64, 100.0 * rel(wq), wq);
        if e == 6 { e6 = ev; }
    }
    let (li, pi, xf) = (li_series(X as f64), primes.len(), X as f64);
    let s: f64 = e6[1..].iter().sum();
    println!("E(1) = {:.2} = li - pi; E(2) = {:.2}; E(7) = {:.2}; E(1000) = {:.2}", e6[1], e6[2], e6[7], e6[1000]);
    let c7 = counts_sieve(&flag, X, 7); println!("q = 7: share li/6 = {:.2}; classes hold {} to {}", li / 6.0, c7.iter().min().unwrap(), c7.iter().max().unwrap());
    let bl: Vec<String> = [(1, 10), (11, 100), (101, 1000)].iter()
        .map(|&(a, b)| format!("q {} to {}: {:.2}", a, b, e6[a..=b].iter().sum::<f64>())).collect();
    println!("block sums: {}", bl.join("; "));
    let triv: f64 = (1..=1000).map(|q| xf / q as f64).sum();
    println!("trivial bound sum of x/q to 1000: {:.0}; S is {:.2} percent of it", triv, 100.0 * s / triv);
    println!("mean E(q) {:.2} against sqrt(x) = {:.0} and sqrt(x) ln x = {:.0}", s / 1000.0, xf.sqrt(), xf.sqrt() * xf.ln());
    println!("large sieve size N + Q^2 with N = x: Q = 1000 gives {}; Q = 10000 gives {}", X + 1000 * 1000, X + 10000 * 10000);
    let sqf: Vec<usize> = (1..=1000).step_by(2).filter(|&d| small.iter().all(|&p| p * p > d || d % (p * p) != 0)).collect();
    let mut rem = 0.0;
    for &d in &sqf {
        let cnt = if d > 1 { step_count(&flag, d - 2, X, d) } else { pi };
        rem += (cnt as f64 - li / coprime(d).len() as f64).abs();
    }
    let twins = primes.iter().filter(|&&p| p + 2 <= X && flag[p + 2]).count();
    println!("twin pairs below 10^6: {}; twin sieve: {} odd squarefree d up to 1000; sum of |pi(x; d, -2) - li(x)/phi(d)| = {:.2}", twins, sqf.len(), rem);
    let mut big = vec![];
    for q in [1009usize, 10007, 99991, 999983] {
        let mut c = std::collections::HashMap::new();
        for &p in &primes { if q % p != 0 { *c.entry(p % q).or_insert(0usize) += 1; } }
        let f = coprime(q).len(); let share = li / f as f64;
        let lo = if c.len() == f { *c.values().min().unwrap() } else { 0 }; let hi = *c.values().max().unwrap();
        let r = (hi as f64 - share).max(share - lo as f64) / share; big.push(r);
        println!("q = {}: phi {}; share {:.3}; classes hold {} to {}; relative miss {:.1} percent", q, f, share, lo, hi, 100.0 * r);
    }
    println!("q from 500001 to 1000000: each E(q) >= 1/2, so they add at least {}; that is {:.2} times x/ln x", X / 4, xf / 4.0 / (xf / xf.ln()));
    let mut s_all = 0.0; let mut s_q = 0.0;
    for q in 1..=1000usize {
        let share = li / coprime(q).len() as f64;
        s_all += (0..q).map(|a| (step_count(&flag, a, X, q) as f64 - share).abs()).fold(0.0, f64::max);
        s_q += worst(&counts_sieve(&flag, X, q), li / q as f64);
    }
    println!("breaks: all classes, not only coprime ones: S = {:.2}; share li/q in place of li/phi(q): S = {:.2}", s_all, s_q);
    assert!(primes.len() == 78498 && td.len() == 78498 && agree && twins == 8169); // two roads to every class count
    assert!((1..=1000).all(|q| counts_sieve(&flag, X, q).iter().sum::<usize>() == pi - small.iter().filter(|&&p| q % p == 0).count()));
    assert!((li - li_b).abs() < 1e-4 && (li - 78627.55).abs() < 0.001); // li two ways, and the house table
    assert!((e6[1] - (li_b - td.len() as f64)).abs() < 1e-4); // q = 1 against Simpson's li and trial division
    let res100: f64 = (1..=100).map(|q| { let c = counts_res(&td, q); worst(&c, li / c.len() as f64) }).sum();
    assert!((e6[1..=100].iter().sum::<f64>() - res100).abs() < 1e-6); // E(q) to 100 by the second road
    assert!(ratios.iter().all(|&r| r < 1.0) && ratios[0] > ratios[1] && ratios[1] > ratios[2]); // S below x/ln x, falling
    assert!(s < 0.01 * triv && big.iter().cloned().fold(f64::INFINITY, f64::min) > 0.2 && big[3] > 1.0); // far below trivial
    assert!(s_all > 2.0 * s && s_q > 2.0 * s); // the broken versions really break
    println!("ALL CHECKS PASS");
}
