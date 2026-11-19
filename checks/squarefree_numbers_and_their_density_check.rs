// Squarefree numbers -- the same check as the Python, in Rust.  No crates.
// A number is squarefree when no square bigger than 1 divides it.  The count
// Q(x) of squarefree numbers up to x is made three ways: by striking out the
// multiples of every square, by the Mobius sieve sum of mu(d) * floor(x / d^2),
// and by the split of every number into a square times a squarefree part.
use std::f64::consts::PI;

const N: usize = 1_000_000;

fn isqrt(x: usize) -> usize {
    let mut r = (x as f64).sqrt() as usize;
    while r * r > x { r -= 1 }
    while (r + 1) * (r + 1) <= x { r += 1 }
    r
}

fn yn(claim: bool) -> &'static str { if claim { "yes" } else { "no" } }

fn main() {
    let dens = 6.0 / (PI * PI); // 1 / zeta(2), proved on the zeta card
    let mut spf: Vec<usize> = (0..=N).collect(); // smallest prime factor of each n
    for p in 2..=isqrt(N) {
        if spf[p] == p {
            let mut m = p * p;
            while m <= N { if spf[m] == m { spf[m] = p } m += p }
        }
    }
    let (mut mu, mut lam) = (vec![0i64; N + 1], vec![0i64; N + 1]);
    mu[1] = 1;
    lam[1] = 1;
    for n in 2..=N { // mu and Liouville's lambda from spf
        let (p, m) = (spf[n], n / spf[n]);
        lam[n] = -lam[m];
        mu[n] = if m % p == 0 { 0 } else { -mu[m] };
    }
    let mut free = vec![true; N + 1]; // road 1: strike multiples of d^2
    free[0] = false;
    for d in 2..=isqrt(N) {
        let mut m = d * d;
        while m <= N { free[m] = false; m += d * d }
    }
    let mut q = vec![0usize; N + 1]; // q[x] = squarefree numbers up to x
    for n in 1..=N { q[n] = q[n - 1] + free[n] as usize }
    // road 2: the Mobius sieve over d^2;  road 3: n = a^2 * (squarefree part)
    let mobius_count = |x: usize| -> i64 { (1..=isqrt(x)).map(|d| mu[d] * (x / (d * d)) as i64).sum() };
    let split_total = |x: usize| -> usize { (1..=isqrt(x)).map(|a| q[x / (a * a)]).sum() };
    let first: Vec<usize> = (1..31).filter(|&n| free[n]).collect();
    println!("first 30 numbers, squarefree ones: {:?}", first);
    println!("720720 = 144 x 5005; 5005 squarefree: {}; 720720 squarefree: {}", yn(free[5005]), yn(free[720720]));
    let terms: Vec<(usize, i64, i64)> =
        (1..32).filter(|&d| mu[d] != 0).map(|d| (d, mu[d], (1000 / (d * d)) as i64)).collect();
    println!("Mobius sieve at 1000, terms (d, mu(d), floor(1000/d^2)):");
    for chunk in terms.chunks(5) {
        let parts: Vec<String> = chunk.iter().map(|(d, m, f)| format!("({}, {:+}, {})", d, m, f)).collect();
        println!("  {}", parts.join("  "));
    }
    let omega = |d: usize| (2..=d).filter(|&p| d % p == 0 && spf[p] == p).count();
    let g: Vec<i64> = (1..=3).map(|k| terms.iter().filter(|t| omega(t.0) == k).map(|t| t.1 * t.2).sum()).collect();
    println!("grouped by primes in d: one prime {:+}, two primes {:+}, three primes {:+}", g[0], g[1], g[2]);
    let q1000 = mobius_count(1000);
    println!("numbers 1 to 1000: struck-out count {}, Mobius sum {}, split total {}", q[1000], q1000, split_total(1000));
    assert!(q[1000] == 608 && q1000 == 608 && split_total(1000) == 1000);
    let blocks: Vec<usize> = (0..1000).step_by(100).map(|k| q[k + 100] - q[k]).collect();
    println!("squarefree per block of 100, 1-100 to 901-1000: {:?}; predicted {:.2} each", blocks, 100.0 * dens);
    let mut partial = 0.0;
    for d in 1..32usize { partial += mu[d] as f64 / (d * d) as f64 }
    let mut euler = 1.0;
    for p in 2..32usize { if spf[p] == p { euler *= 1.0 - 1.0 / (p * p) as f64 } }
    println!("6/pi^2 = {:.9}; sum mu(d)/d^2 to 31 = {:.9}; product over primes to 31 = {:.9}", dens, partial, euler);
    println!("predicted at 1000: 6/pi^2 x 1000 = {:.3}; primes-to-31 product x 1000 = {:.3}", 1000.0 * dens, 1000.0 * euler);
    println!("x | Q(x) | 6x/pi^2 | E = Q - 6x/pi^2 | E/sqrt(x) | Q/(6x/pi^2) | proved bound D + x/D");
    for &x in &[1_000usize, 10_000, 100_000, 1_000_000] {
        let (pred, dd) = (x as f64 * dens, isqrt(x));
        let e = q[x] as f64 - pred;
        let bound = dd as f64 + x as f64 / dd as f64;
        println!("{} | {} | {:.3} | {:.3} | {:.5} | {:.7} | {:.1}", x, q[x], pred, e, e / (x as f64).sqrt(), q[x] as f64 / pred, bound);
        assert!(q[x] as i64 == mobius_count(x) && split_total(x) == x); // three roads agree
        assert!(e.abs() <= bound); // the proved bound
    }
    let (mut worst, mut at) = (0.0f64, 0usize);
    for x in 1..=N {
        let r = (q[x] as f64 - x as f64 * dens).abs() / (x as f64).sqrt();
        if r > worst { worst = r; at = x }
    }
    println!("largest |E(x)|/sqrt(x) for x from 1 to {}: {:.5}, at x = {}", N, worst, at);
    println!("partial summation: S(x) = sum of 1/n over squarefree n <= x, against (6/pi^2) log x");
    let mut s = 0.0;
    for n in 1..=N {
        if free[n] { s += 1.0 / n as f64 }
        if [1_000, 10_000, 100_000, 1_000_000].contains(&n) {
            let l = dens * (n as f64).ln();
            println!("  x = {}: S = {:.6}, (6/pi^2) log x = {:.6}, difference {:.6}", n, s, l, s - l);
        }
    }
    let same = (1..=N).filter(|&n| free[n]).all(|n| lam[n] == mu[n]);
    let sq = (1..=1000usize).all(|n| {
        let t: i64 = (1..=n).filter(|d| n % d == 0).map(|d| lam[d]).sum();
        (t == 1) == (isqrt(n) * isqrt(n) == n)
    });
    println!("lambda = mu on every squarefree n <= {}: {}; lambda summed over divisors is 1 exactly on squares to 1000: {}", N, yn(same), yn(sq));
    assert!(same && sq);
    let rad: usize = (2..14usize).filter(|&p| spf[p] == p && 720720 % p == 0).product();
    println!("lambda(12) = {:+}, mu(12) = {}; lambda(720720) = {:+}, mu(720720) = {}; radical of 720720 = {}", lam[12], mu[12], lam[720720], mu[720720], rad);
    assert!(lam[12] == -1 && lam[720720] == 1 && rad * 24 == 720720);
    let (mut l, mut top, mut zeros) = (0i64, -1_000_000_000i64, 0usize);
    for n in 1..=N {
        l += lam[n];
        if n >= 2 { top = top.max(l); if l == 0 { zeros += 1 } }
        if n == 1000 { println!("L(1000) = sum of lambda(n) to 1000 = {}", l) }
    }
    println!("Polya's L(x) <= 0 for 2 <= x <= {}: largest L(x) = {}, reached {} times; L({}) = {}", N, top, zeros, N, l);
    assert!(top <= 0);
    let nosign = 1000 - (2..32usize).map(|d| 1000 / (d * d)).sum::<usize>();
    let primes_only = 1000 - (2..32usize).filter(|&p| spf[p] == p).map(|p| 1000 / (p * p)).sum::<usize>();
    println!("mistake 1, strike every square's multiples with no add-back: {}", nosign);
    println!("mistake 2, prime squares only, no add-back: {}", primes_only);
    let first_run = |k: usize| (1..N).find(|&n| (0..k).all(|i| !free[n + i])).unwrap(); // first k in a row
    let (r3, r4) = (first_run(3), first_run(4));
    println!("mistake 3, density read on a short window: {}-{} has 0 of 3; {}-{} has 0 of 4", r3, r3 + 2, r4, r4 + 3);
    assert!((r3, r4) == (48, 242) && nosign < 608 && primes_only < 608);
    println!("ALL CHECKS PASS");
}
