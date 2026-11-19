// Multiplicative functions and Dirichlet convolution -- the same check as the
// Python, in Rust.  No crates.  The number is 720720 = 2^4 * 3^2 * 5 * 7 * 11 * 13.
// Road one lists divisors and counts by brute force.  Road two rebuilds each
// function from its values at prime powers.  Road three sieves every n up to a
// million.  Dirichlet inverses come by a recursion and by prime powers.
const N0: i64 = 720720;
const LIMIT: usize = 1_000_000;

fn gcd(mut a: i64, mut b: i64) -> i64 {          // Euclid's algorithm, written out
    while b != 0 { (a, b) = (b, a % b) }
    a
}

fn factor(mut n: i64) -> Vec<(i64, u32)> {       // trial division: [(p, a), ...]
    let (mut out, mut p) = (Vec::new(), 2);
    while p * p <= n {
        let mut a = 0;
        while n % p == 0 { n /= p; a += 1 }
        if a > 0 { out.push((p, a)) }
        p += 1;
    }
    if n > 1 { out.push((n, 1)) }
    out
}

fn divisors(n: i64) -> Vec<i64> {                // brute force: try every d up to sqrt(n)
    let mut out = Vec::new();
    let mut d = 1;
    while d * d <= n {
        if n % d == 0 { out.push(d); if d * d != n { out.push(n / d) } }
        d += 1;
    }
    out.sort();
    out
}

fn rebuild(n: i64, at_pp: &dyn Fn(i64, u32) -> i64) -> i64 {   // product over p^a exactly dividing n
    factor(n).iter().map(|&(p, a)| at_pp(p, a)).product()
}

fn tau_pp(_p: i64, a: u32) -> i64 { a as i64 + 1 }
fn sigma_pp(p: i64, a: u32) -> i64 { (p.pow(a + 1) - 1) / (p - 1) }
fn sigma2_pp(p: i64, a: u32) -> i64 { (p.pow(2 * a + 2) - 1) / (p * p - 1) }
fn phi_pp(p: i64, a: u32) -> i64 { p.pow(a - 1) * (p - 1) }
fn mu_pp(_p: i64, a: u32) -> i64 { if a == 1 { -1 } else { 0 } }

fn conv(f: &dyn Fn(i64) -> i64, g: &dyn Fn(i64) -> i64, n: i64) -> i64 {   // Dirichlet convolution at n
    divisors(n).iter().map(|&d| f(d) * g(n / d)).sum()
}

fn inverse(f: &dyn Fn(i64) -> i64, ds: &[i64]) -> std::collections::HashMap<i64, i64> {
    let mut inv = std::collections::HashMap::new();   // Dirichlet inverse, f(1) = 1
    for &m in ds {
        let v = if m == 1 { 1 } else {
            -ds.iter().filter(|&&d| d < m && m % d == 0).map(|&d| f(m / d) * inv[&d]).sum::<i64>()
        };
        inv.insert(m, v);
    }
    inv
}

fn yn(claim: bool) -> &'static str { if claim { "yes" } else { "no" } }

fn first_failure(f: &dyn Fn(i64) -> i64, pairs: &[(i64, i64)]) -> String {
    for &(m, n) in pairs {
        if f(m * n) != f(m) * f(n) {
            return format!("no, {} x {} gives {} against {}", m, n, f(m * n), f(m) * f(n));
        }
    }
    "yes".to_string()
}

fn main() {
    let ds = divisors(N0);
    let names = ["tau", "sigma", "sigma_2", "phi"];
    let brute = [ds.len() as i64, ds.iter().sum(), ds.iter().map(|d| d * d).sum(),
                 (1..=N0).filter(|&m| gcd(m, N0) == 1).count() as i64];
    let pps: [&dyn Fn(i64, u32) -> i64; 4] = [&tau_pp, &sigma_pp, &sigma2_pp, &phi_pp];
    let fs = factor(N0);
    let parts: Vec<String> = fs.iter().map(|(p, a)| format!("{}^{}", p, a)).collect();
    println!("720720 = {}", parts.join(" * "));
    println!("p^a   tau  sigma  sigma_2  phi");
    for &(p, a) in &fs {
        println!("{:<5} {:>3} {:>6} {:>8} {:>4}", p.pow(a), tau_pp(p, a), sigma_pp(p, a), sigma2_pp(p, a), phi_pp(p, a));
    }
    for i in 0..4 {
        let r = rebuild(N0, pps[i]);
        println!("{}(720720): by listing {}, from prime powers {}", names[i], brute[i], r);
        assert!(brute[i] == r);                       // road one against road two, four functions
    }
    println!("720720 = 16 x {}: {} divisors = 5 x {}; gcd(360, 2002) = {}", N0 / 16, ds.len(), divisors(N0 / 16).len(), gcd(360, 2002));

    let mut tau = vec![0i64; LIMIT + 1];              // road three: 1 * 1 summed literally
    for d in 1..=LIMIT { let mut m = d; while m <= LIMIT { tau[m] += 1; m += d } }
    let mut spf: Vec<usize> = (0..=LIMIT).collect();  // smallest prime factor of every n
    let mut p = 2;
    while p * p <= LIMIT {
        if spf[p] == p { let mut m = p * p; while m <= LIMIT { if spf[m] == m { spf[m] = p } m += p } }
        p += 1;
    }
    let mut phi: Vec<i64> = (0..=LIMIT as i64).collect();   // phi by the product sieve
    for p in 2..=LIMIT {
        if spf[p] == p { let mut m = p; while m <= LIMIT { phi[m] -= phi[m] / p as i64; m += p } }
    }
    let mut phi_sum = vec![0i64; LIMIT + 1];          // (phi * 1)(n), summed literally
    for d in 1..=LIMIT { let mut m = d; while m <= LIMIT { phi_sum[m] += phi[d]; m += d } }
    let tau_from_spf = |mut n: usize| -> i64 {        // road two again, from the smallest-factor table
        let mut out = 1;
        while n > 1 { let (p, mut a) = (spf[n], 0); while n % p == 0 { n /= p; a += 1 } out *= a + 1 }
        out
    };

    let mut coprime = Vec::new();
    let mut every = Vec::new();
    for m in 2..=100i64 { for n in m..=100 { every.push((m, n)); if gcd(m, n) == 1 { coprime.push((m, n)) } } }
    let tf = |n: i64| tau[n as usize];
    let pf = |n: i64| phi[n as usize];
    let sf = |n: i64| rebuild(n, &sigma_pp);
    let np1 = |n: i64| n + 1;
    let omega = |n: i64| factor(n).len() as i64;
    let cands: [(&str, &dyn Fn(i64) -> i64); 5] =
        [("tau", &tf), ("sigma", &sf), ("phi", &pf), ("n + 1", &np1), ("distinct-prime count", &omega)];
    println!("f(mn) = f(m) f(n) on all coprime m, n up to 100:");
    for (name, f) in cands.iter() { println!("  {}: {}", name, first_failure(*f, &coprime)) }
    println!("f(mn) = f(m) f(n) on all m, n up to 100, coprime or not:");
    println!("  n^2: {}; tau: {}", first_failure(&|n| n * n, &every), first_failure(&tf, &every));
    let agree = (1..=LIMIT).all(|n| tau[n] == tau_from_spf(n));
    let top = *tau.iter().max().unwrap();
    let champs: Vec<usize> = (1..=LIMIT).filter(|&n| tau[n] == top).collect();
    let id_all = (1..=LIMIT).all(|n| phi_sum[n] == n as i64);
    let one = |_n: i64| 1i64;
    let id = |n: i64| n;
    println!("tau to 1000000, divisor sieve against prime-power rebuild: {}", if agree { "all agree" } else { "MISMATCH" });
    println!("largest tau to 1000000: {}, at {:?}", top, champs);
    println!("(phi * 1)(720720) over its {} divisors: {}", ds.len(), conv(&pf, &one, N0));
    println!("(phi * 1)(n) = n for every n to 1000000: {}", yn(id_all));
    println!("(id * 1)(720720) = {}; (1 * 1)(720720) = {}", conv(&id, &one, N0), conv(&one, &one, N0));
    assert!(agree && champs[0] as i64 == N0 && top == brute[0]);      // sieve against rebuild
    assert!(id_all);                                                  // phi * 1 = id, every n
    let sigma_pp_n0 = rebuild(N0, &sigma_pp);
    assert!(conv(&id, &one, N0) == sigma_pp_n0 && sigma_pp_n0 == 3249792);   // id * 1 against prime powers

    let (inv_phi, inv_tau, inv_one, inv_id) = (inverse(&pf, &ds), inverse(&tf, &ds), inverse(&one, &ds), inverse(&id, &ds));
    let one_minus_p = |p: i64, _a: u32| 1 - p;
    let tau_inv_pp = |_p: i64, a: u32| if a < 3 { [1, -2, 1][a as usize] } else { 0 };
    let tv: Vec<i64> = (0..5).map(|k| inv_tau[&(1i64 << k)]).collect();
    let pv: Vec<i64> = (0..5).map(|k| phi[1usize << k]).collect();
    println!("at 1, 2, 4, 8, 16: phi {:?}, tau inverse by recursion {:?}", pv, tv);
    println!("phi inverse at 720720: by recursion {}, product of (1 - p) {}", inv_phi[&N0], rebuild(N0, &one_minus_p));
    println!("id inverse at 30: {}; 1's inverse at 30: {}", inv_id[&30], inv_one[&30]);
    let checks = [ds.iter().all(|&d| inv_phi[&d] == rebuild(d, &one_minus_p)),
                  ds.iter().all(|&d| inv_tau[&d] == rebuild(d, &tau_inv_pp)),
                  ds.iter().all(|&d| inv_one[&d] == rebuild(d, &mu_pp)),
                  ds.iter().all(|&d| inv_id[&d] == d * rebuild(d, &mu_pp)),
                  ds.iter().all(|&d| conv(&pf, &|n| inv_phi[&n], d) == if d == 1 { 1 } else { 0 })];
    let words: Vec<&str> = checks.iter().map(|&c| yn(c)).collect();
    println!("recursion against prime powers on all 240 divisors (phi, tau, 1, id), and phi * inverse = epsilon: {}", words.join(" "));
    assert!(checks.iter().all(|&c| c));                               // two roads to each inverse

    println!("mistake 1, tau(360) x tau(2002) = {} x {} = {}, not {}", tau[360], tau[2002], tau[360] * tau[2002], tau[N0 as usize]);
    println!("mistake 2, phi(360) x phi(2002) = {} x {} = {}, not {}", phi[360], phi[2002], phi[360] * phi[2002], phi[N0 as usize]);
    println!("mistake 3, phi(p^a) taken as p^a - 1: {}, not {}", rebuild(N0, &|p, a| p.pow(a) - 1), phi[N0 as usize]);
    println!("mistake 4, phi times 1 value by value: {} at 720720, not {}", phi[N0 as usize] * 1, phi_sum[N0 as usize]);
    println!("ALL CHECKS PASS");
}
