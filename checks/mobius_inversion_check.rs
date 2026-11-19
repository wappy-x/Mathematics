// The Mobius function and inversion -- the same check as the Python, in Rust.
// No crates.  The examples are a dial of 60 marks and the house number
// 720720 = 2^4 x 3^2 x 5 x 7 x 11 x 13.  Whole numbers are i128.
type Z = i128;
const N: usize = 10_000;                         // every claim is also checked for n up to N

fn gcd(mut a: Z, mut b: Z) -> Z {                // Euclid, written out here
    while b != 0 { (a, b) = (b, a % b) }
    a
}

fn primes_of(mut n: Z) -> Vec<(Z, u32)> {        // trial division: (prime, exponent)
    let (mut out, mut p) = (Vec::new(), 2);
    while p * p <= n {
        let mut e = 0;
        while n % p == 0 { n /= p; e += 1 }
        if e > 0 { out.push((p, e)) }
        p += 1;
    }
    if n > 1 { out.push((n, 1)) }
    out
}

fn mu(n: Z) -> Z {                               // 0 on a repeated prime, else (-1)^(prime count)
    let f = primes_of(n);
    if f.iter().any(|&(_, e)| e > 1) { 0 } else if f.len() % 2 == 0 { 1 } else { -1 }
}

fn divisors(n: Z) -> Vec<Z> {                    // pairs d and n/d, with d up to the square root
    let mut out = Vec::new();
    let mut d = 1;
    while d * d <= n {
        if n % d == 0 { out.push(d); if d * d != n { out.push(n / d) } }
        d += 1;
    }
    out.sort();
    out
}

fn phi_count(n: Z) -> Z { (1..=n).filter(|&k| gcd(k, n) == 1).count() as Z }      // road 1
fn phi_mobius(n: Z) -> Z { divisors(n).iter().map(|&d| mu(d) * (n / d)).sum() }  // road 2
fn phi_product(n: Z) -> Z {                                                       // road 3
    primes_of(n).iter().fold(n, |v, &(p, _)| v / p * (p - 1))
}

fn loop_length(k: Z, n: Z) -> Z {                // step a pointer k marks at a time; count ticks home
    let (mut pos, mut t) = (k % n, 1);
    while pos != 0 { pos = (pos + k) % n; t += 1 }
    t
}

fn prime_behind(n: Z) -> Z {                     // product form: n = product of r(d) over d | n
    let (mut num, mut den): (Z, Z) = (1, 1);
    for d in divisors(n) {
        if mu(d) == 1 { num = num.checked_mul(n / d).unwrap() }
        if mu(d) == -1 { den = den.checked_mul(n / d).unwrap() }
    }
    assert!(num % den == 0);
    num / den
}

fn is_primitive(s: u32, n: u32) -> bool {        // an n-bit string that is no shorter block repeated
    divisors(n as Z).iter().filter(|&&d| d < n as Z).all(|&d| {
        let block = s >> (n - d as u32);
        let rep = (0..n / d as u32).fold(0u32, |acc, _| (acc << d) | block);
        rep != s
    })
}

fn bits(x: u32) -> u32 { 32 - x.leading_zeros() }
fn has_factor(f: u32) -> bool {                  // a degree-8 polynomial over GF(2), as bits
    (2u32..32).any(|g| {                         // every polynomial of degree 1 to 4
        let mut a = f;
        while bits(a) >= bits(g) { a ^= g << (bits(a) - bits(g)) }
        a == 0
    })
}

fn main() {
    let mut divs: Vec<Vec<usize>> = vec![Vec::new(); N + 1];      // divisor lists up to N, by a sieve
    for d in 1..=N { for m in (d..=N).step_by(d) { divs[m].push(d) } }
    let mut mus: Vec<Z> = vec![0; N + 1];
    for n in 1..=N { mus[n] = mu(n as Z) }
    let mut peel: Vec<Z> = vec![0; N + 1];      // road 4: phi(n) = n minus phi of smaller divisors
    for n in 1..=N {
        let below: Z = divs[n][..divs[n].len() - 1].iter().map(|&d| peel[d]).sum();
        peel[n] = n as Z - below;
    }
    for n in 1..=N {
        let s: Z = divs[n].iter().map(|&d| mus[d]).sum();
        assert!(s == if n == 1 { 1 } else { 0 });                   // mu * 1 = epsilon
        let via: Z = divs[n].iter().map(|&d| mus[d] * (n / d) as Z).sum();
        assert!(peel[n] == via && via == phi_product(n as Z));      // inversion, n <= N
        if n <= 1000 { assert!(phi_count(n as Z) == peel[n]) }      // Gauss, n <= 1000
    }
    println!("checked n = 1..{}: mu sums to 1 at n = 1 and 0 after; peeling = inversion = product", N);
    println!("checked n = 1..1000: the gcd count equals all three");

    let dd = divisors(60);
    let tally: Vec<Z> = dd.iter().map(|&d| (1..=60).filter(|&k| loop_length(k, 60) == d).count() as Z).collect();
    let tours: Vec<Z> = (1..=60).filter(|&k| loop_length(k, 60) == 60).collect();
    let phis: Vec<Z> = dd.iter().map(|&d| phi_count(d)).collect();
    println!("divisors of 60: {:?}", dd);
    println!("jumps 1..60 sorted by loop length d: {:?}", tally);
    println!("phi(d) for the same d, by gcd count: {:?}; total {}", phis, phis.iter().sum::<Z>());
    println!("jumps that visit all 60 marks: {:?}", tours);
    println!("jump 7 comes home after {} ticks; jump 6 after {}", loop_length(7, 60), loop_length(6, 60));
    println!("mu(d) on the divisors of 60: {:?}", dd.iter().map(|&d| mu(d)).collect::<Vec<Z>>());
    let terms: Vec<Z> = dd.iter().filter(|&&d| mu(d) != 0).map(|&d| mu(d) * (60 / d)).collect();
    println!("inversion terms mu(d) x 60/d: {:?}; sum {}", terms, terms.iter().sum::<Z>());
    println!("product form: 60 x 1/2 x 2/3 x 4/5 = {}; gcd count {}", phi_product(60), phi_count(60));
    assert!(tally == phis && tours.len() as Z == phi_mobius(60) && phi_mobius(60) == 16);

    let h: Z = 720720;
    let dh = divisors(h);
    let sq = dh.iter().filter(|&&d| mu(d) != 0).count();
    let fac: Vec<String> = primes_of(h).iter().map(|(p, e)| format!("{}: {}", p, e)).collect();
    println!("720720 = {{{}}}: {} divisors, {} squarefree", fac.join(", "), dh.len(), sq);
    let total: Z = dh.iter().map(|&d| phi_product(d)).sum();
    println!("sum of phi(d) over its divisors: {}", total);
    println!("phi(720720): inversion {}, product {}, gcd count {}", phi_mobius(h), phi_product(h), phi_count(h));
    assert!(total == h && phi_mobius(h) == phi_count(h) && phi_count(h) == 138240);

    let mut t: Vec<Z> = vec![0; N + 1];          // T(x): the running total of phi up to x
    for n in 1..=N { t[n] = t[n - 1] + peel[n] }
    for &x in &[60usize, 1000, N] {
        let gauss: Z = (1..=x).map(|n| t[x / n]).sum();
        let inv: Z = (1..=x).map(|n| { let m = (x / n) as Z; mus[n] * m * (m + 1) / 2 }).sum();
        let main_term = 3.0 * (x * x) as f64 / (std::f64::consts::PI * std::f64::consts::PI);
        println!("x = {}: T(x) = {}; inverted {}; sum of T(x/n) = {} = x(x+1)/2; T(x)/(3x^2/pi^2) = {:.6}; T(x) - 3x^2/pi^2 = {:.2}",
                 x, t[x], inv, gauss, t[x] as f64 / main_term, t[x] as f64 - main_term);
        assert!(inv == t[x] && gauss == (x * (x + 1) / 2) as Z);
    }

    println!("r(n) for n = 1..12 from the product form: {:?}", (1..=12).map(prime_behind).collect::<Vec<Z>>());
    for n in 1..=2000 {
        let f = primes_of(n);
        assert!(prime_behind(n) == if f.len() == 1 { f[0].0 } else { 1 });
    }

    let prim = (0u32..256).filter(|&s| is_primitive(s, 8)).count() as Z;
    let irred = (256u32..512).filter(|&f| !has_factor(f)).count() as Z;
    let formula: Z = divisors(8).iter().map(|&d| mu(d) * (1 << (8 / d))).sum();
    println!("8-bit strings with no shorter repeat: brute force {}, inversion {}; /8 = {}; irreducible degree-8 over GF(2), brute force {}",
             prim, formula, formula / 8, irred);
    assert!(prim == formula && formula == 240 && irred == formula / 8);

    let omega = |n: Z| primes_of(n).iter().map(|&(_, e)| e).sum::<u32>();
    let m1: Z = dd.iter().map(|&d| (if omega(d) % 2 == 0 { 1 } else { -1 }) * (60 / d)).sum();
    let m2: Z = dd.iter().filter(|&&d| mu(d) != 0).map(|&d| 60 / d).sum();
    println!("mistake 1, signs counting repeated primes: {}, not 16", m1);
    println!("mistake 2, signs dropped: {}, not 16", m2);
    println!("mistake 3, the term d = 1 left out: {}, not 16", terms[1..].iter().sum::<Z>());
    println!("mistake 4, phi(360) x phi(2002) = {} x {} = {}, not {}",
             phi_product(360), phi_product(2002), phi_product(360) * phi_product(2002), phi_product(h));
    println!("ALL CHECKS PASS");
}
