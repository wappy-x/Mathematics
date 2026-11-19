// Chebyshev's bounds -- the check behind the card.  std only, no crates.
// Rust has no big integers, so C(1000,500) is read through its prime exponents.
fn ln(x: f64) -> f64 { x.ln() }

fn legendre(n: u64, p: u64) -> u32 {          // road 1: v_p(C(2n,n)) by floors
    let (mut v, mut q) = (0, p);
    while q <= 2 * n {
        let t = 2 * n / q - 2 * (n / q);
        assert!(t <= 1);                      // each term is 0 or 1
        v += t as u32;
        q *= p;
    }
    v
}

fn carries(mut n: u64, p: u64) -> u32 {       // road 2: carries in n + n, base p
    let (mut v, mut carry) = (0, 0);
    while n > 0 || carry > 0 {
        carry = if 2 * (n % p) + carry >= p { 1 } else { 0 };
        v += carry as u32;
        n /= p;
    }
    v
}

fn main() {
    const N: usize = 1_000_000;
    let mut sieve = vec![true; N + 1];
    sieve[0] = false;
    sieve[1] = false;
    let mut i = 2;
    while i * i <= N {
        if sieve[i] { let mut j = i * i; while j <= N { sieve[j] = false; j += i; } }
        i += 1;
    }
    let mut pi = vec![0usize; N + 1];
    let mut c = 0;
    for x in 0..=N { if sieve[x] { c += 1; } pi[x] = c; }
    let primes: Vec<u64> = (2..=N).filter(|&p| sieve[p]).map(|p| p as u64).collect();

    let n: u64 = 500;
    let nxt = *primes.iter().find(|&&p| p > n).unwrap();
    let ln_c: f64 = primes.iter().filter(|&&p| p <= 2 * n).map(|&p| legendre(n, p) as f64 * ln(p as f64)).sum();
    println!("n = {}: first prime above n = {}, primes in (n, 2n] = {}", n, nxt, pi[1000] - pi[500]);
    let digits = (ln_c / ln(10.0)) as u64 + 1;
    println!("C(1000,500): {} digits, log = {:.2}", digits, ln_c);
    let nf = n as f64;
    println!("sandwich: {:.2} <= {:.2} <= {:.2}; 4^500 / C(1000,500) = {:.1}", nf * ln(4.0) - ln(2.0 * nf + 1.0), ln_c, nf * ln(4.0), (nf * ln(4.0) - ln_c).exp());
    let mut small = Vec::new();
    for &p in primes.iter().take_while(|&&p| p <= 2 * n) {
        let v = legendre(n, p);
        assert_eq!(v, carries(n, p));         // floors agree with carries
        assert!(p.pow(v) <= 2 * n);
        if p * p <= 2 * n { small.push(format!("{}^{}", p, v)); }
    }
    println!("primes up to 31 in C(1000,500): {}", small.join(" "));
    for (name, lo, hi) in [("(500, 1000]", 500, 1000), ("(333, 500]", 333, 500), ("(31, 333]", 31, 333), ("[2, 31]", 1, 31)] {
        let ps: Vec<u64> = primes.iter().cloned().filter(|&p| lo < p && p <= hi).collect();
        let hit: Vec<u64> = ps.iter().cloned().filter(|&p| legendre(n, p) > 0).collect();
        let share = hit.iter().fold(0.0, |s, &p| s + legendre(n, p) as f64 * ln(p as f64));
        println!("band {:<12} {:>3} of {:>3} primes divide, log share {:.2}", name, hit.len(), ps.len(), share);
    }
    let up = nf * ln(4.0) / ln(nf);
    let lo = ln_c / ln(2.0 * nf);
    println!("upper, primes in (500, 1000] < {:.2}, so at most {}; true {}", up, up as usize, pi[1000] - pi[500]);
    println!("lower, pi(1000) >= {:.2}, so at least {}; true {}", lo, lo as usize + 1, pi[1000]);
    assert!(pi[1000] - pi[500] <= up as usize && pi[1000] >= lo as usize + 1);
    let (l, u) = (ln(2.0) / 2.0, 4.0 * ln(2.0));
    println!("constants: log 2/2 = {:.4}, 4 log 2 = {:.4}, log 2 = {:.4}, log 4 = {:.4}", l, u, ln(2.0), ln(4.0));
    println!("logs: log 500 = {:.4}, log 1000 = {:.4}, sqrt(1000) = {:.2}", ln(500.0), ln(1000.0), 1000f64.sqrt());
    println!("x  pi(x)  x/log x  ratio  lower  upper");
    for e in 1..7 {
        let x = 10usize.pow(e);
        let m = x as f64 / ln(x as f64);
        println!("{} {} {:.2} {:.4} {:.2} {:.2}", x, pi[x], m, pi[x] as f64 / m, l * m, u * m);
        assert!(l * m <= pi[x] as f64 && pi[x] as f64 <= u * m);
    }
    assert_eq!((1..7).map(|e| pi[10usize.pow(e)]).collect::<Vec<_>>(), vec![4, 25, 168, 1229, 9592, 78498]); // OEIS A006880
    println!("below 2: floor at x = 1.5 is {:.2}, but pi(1.5) = {}", l * 1.5 / ln(1.5), pi[1]);
    let a = ln(2.0) / 2.0 + ln(3.0) / 3.0 + ln(5.0) / 5.0 - ln(30.0) / 30.0;
    println!("Chebyshev 1852 constants: {:.5} and {:.5}", a, 6.0 * a / 5.0);
    let mut lo_r = (ln(2.0) / 2.0, 2usize);   // ratio at the left of each jump
    for &q in &primes[1..] {
        let r = (pi[q as usize] - 1) as f64 * ln(q as f64) / q as f64;
        if r < lo_r.0 { lo_r = (r, q as usize); }
    }
    let r = pi[N] as f64 * ln(N as f64) / N as f64;
    if r < lo_r.0 { lo_r = (r, N); }
    let mut hi_r = (0.0, 0usize);
    for &p in &primes[1..] {
        let r = pi[p as usize] as f64 * ln(p as f64) / p as f64;
        if r > hi_r.0 { hi_r = (r, p as usize); }
    }
    println!("ratio over [2, {}]: least {:.5} at x = {}, most {:.5} at x = {}", N, lo_r.0, lo_r.1, hi_r.0, hi_r.1);
    assert!(lo_r.0 >= l - 1e-12 && hi_r.0 <= u);
    let step = |k: usize| ln(k as f64) >= 4.0 * ln(2.0) + 2.0 * ln(k as f64) / k as f64;
    let m0 = (3..100).find(|&m| (m..N).all(|k| step(k))).unwrap();
    println!("upper-bound induction step holds from m = {}", m0);
    assert!((2..m0).all(|m| pi[m] as f64 <= u * m as f64 / ln(m as f64)));
    let f = |k: f64| k * ln(4.0) / 3.0 - ln(2.0 * k + 1.0) - (2.0 * k).sqrt() * ln(2.0 * k);
    let df = |k: f64| ln(4.0) / 3.0 - 2.0 / (2.0 * k + 1.0) - (ln(2.0 * k) + 2.0) / (2.0 * k).sqrt();
    let n0 = (5..N).find(|&k| f(k as f64) > 0.0 && df(k as f64) > 0.0).unwrap();
    let (s1, s2) = (1000f64.sqrt() * ln(1000.0), 1000.0 * ln(4.0) / 3.0);
    assert!((f(nf) - (nf * ln(4.0) - ln(2.0 * nf + 1.0) - s1 - s2)).abs() < 1e-9);
    println!("Erdos at n = 500: {:.2} + {:.2} = {:.2} < {:.2}", s1, s2, s1 + s2, nf * ln(4.0) - ln(2.0 * nf + 1.0));
    println!("Erdos inequality forces a prime for every n >= {}", n0);
    assert!((1..20000).all(|k| (f(k as f64) > 0.0) == (k >= n0))); // no clash below n0
    let chain = [2usize, 3, 5, 7, 13, 23, 43, 83, 163, 317, 631];
    assert!(chain.iter().all(|&q| sieve[q]) && chain.windows(2).all(|w| w[1] < 2 * w[0]));
    let cs: Vec<String> = chain.iter().map(|q| q.to_string()).collect();
    println!("Landau chain: {} covers every n below {}", cs.join(" "), chain[10]);
    assert!(chain[10] > n0);
    assert!((1..=N / 2).all(|k| pi[2 * k] > pi[k]));
    println!("sieve: every n from 1 to {} has a prime in (n, 2n]", N / 2);
    let mut gone = Vec::new();
    for k in 2..2001u64 {
        for &p in primes.iter().take_while(|&&p| p <= k) {
            if 3 * p > 2 * k && legendre(k, p) > 0 { gone.push(format!("({}, {})", k, p)); }
        }
    }
    println!("primes in (2n/3, n] dividing C(2n,n), n up to 2000: [{}]", gone.join(", "));
    assert_eq!(gone, vec!["(2, 2)".to_string()]);
    let gap = (1..N - 30).find(|&k| pi[k + 30] == pi[k]).unwrap();
    println!("503 lies between 22^2 = {} and 23^2 = {}; x^0.525 at 10^6 = {:.2}", 22 * 22, 23 * 23, (N as f64).powf(0.525));
    println!("what breaks:");
    let half = (nf * ln(2.0) / ln(nf)) as usize;
    println!("  2^n for 4^n: at most {} primes in (500, 1000], true {}", half, pi[1000] - pi[500]);
    println!("  x/log x as a ceiling at 1000: {:.2} < {}", 1000.0 / ln(1000.0), pi[1000]);
    println!("  constant log 2 from x = 2: needs {:.2} primes, pi(2) = {}", ln(2.0) * 2.0 / ln(2.0), pi[2]);
    println!("  window (n, n + 30]: first empty at n = {}, between primes {} and {}", gap, gap, primes[pi[gap]]);
    assert!(half < pi[1000] - pi[500] && gap == 1327 && sieve[gap]);
    println!("ALL CHECKS PASS");
}
