// Dirichlet L-functions: the check behind the card.  Rust std only, no crates.
// Roads to L(1, chi_4) = pi/4: the series with its proved error bracket, pi from
// Machin's arctangent formula, and lattice points in a circle.  Primes: a sieve.

fn chi4(n: u64) -> i64 { if n % 2 == 0 { 0 } else if n % 4 == 1 { 1 } else { -1 } }
fn f(x: f64, k: usize) -> String { format!("{:.*}", k, x) }
fn isqrt(n: u64) -> u64 {
    let mut r = (n as f64).sqrt() as u64;
    while r * r > n { r -= 1; }
    while (r + 1) * (r + 1) <= n { r += 1; }
    r
}
fn atan_series(x: f64) -> f64 { // arctan x = x - x^3/3 + x^5/5 - ..., 40 terms
    let (mut total, mut power) = (0.0, x);
    for k in 0..40 {
        total += (if k % 2 == 0 { 1.0 } else { -1.0 }) * power / (2 * k + 1) as f64;
        power *= x * x;
    }
    total
}
// sum chi(n)/n^s with complex chi = (re, im), averaged over the partial sums at
// N = M .. M+q-1: the 1/M error term cancels
fn avg_tail(chi: &dyn Fn(u64) -> (f64, f64), q: u64, s: u32, m: u64) -> (f64, f64) {
    let (mut tr, mut ti, mut ar, mut ai) = (0.0, 0.0, 0.0, 0.0);
    for n in 1..m + q {
        let (cr, ci) = chi(n);
        let d = n.pow(s) as f64;
        tr += cr / d; ti += ci / d;
        if n >= m { ar += tr; ai += ti; }
    }
    (ar / q as f64, ai / q as f64)
}
fn real(g: fn(u64) -> i64) -> impl Fn(u64) -> (f64, f64) { move |n| (g(n) as f64, 0.0) }

fn main() {
    let pi = 16.0 * atan_series(1.0 / 5.0) - 4.0 * atan_series(1.0 / 239.0); let q = pi / 4.0;
    println!("pi by Machin {} | pi/4 {}", f(pi, 11), f(q, 12));

    // ---- the series L(1, chi_4) = 1 - 1/3 + 1/5 - ..., error bracket from Step 3 ----
    let (mut s, mut part) = (0.0f64, vec![]);
    for k in 0..12 { s += (if k % 2 == 0 { 1.0 } else { -1.0 }) / (2 * k + 1) as f64; part.push(f(s, 4)); }
    println!("chart, partial sums, 1 to 12 terms: {}", part.join(", "));
    println!("terms N, partial sum, error, bracket 1/(2(2N+1)) to 1/(2N+1)");
    let (mut s, mut k) = (0.0f64, 0u64);
    for &n in &[10u64, 100, 1000, 1_000_000] {
        while k < n { s += (if k % 2 == 0 { 1.0 } else { -1.0 }) / (2 * k + 1) as f64; k += 1; }
        let err = (s - q).abs();
        let (lo, hi) = (1.0 / (2 * (2 * n + 1)) as f64, 1.0 / (2 * n + 1) as f64);
        assert!(lo < err && err < hi); // Step 3's bracket
        let dp = if n == 1_000_000 { 14 } else { 9 }; // at 10^6, nine decimals would hide the gap to the low end
        println!("{} {} {} {} {}", n, f(s, 9), f(err, dp), f(lo, dp), f(hi, dp));
    }

    // ---- primes below a million, and the Euler product at s = 2 ----
    let x: u64 = 1_000_000;
    let mut sv = vec![true; x as usize]; sv[0] = false; sv[1] = false;
    for i in 2..1001usize { if sv[i] { let mut j = i * i; while j < x as usize { sv[j] = false; j += i; } } }
    let primes: Vec<u64> = (0..x).filter(|&p| sv[p as usize]).collect();
    let g = avg_tail(&real(chi4), 4, 2, x).0; // Catalan's constant, by the series
    let mut e = 1.0;
    for &p in &primes { e /= 1.0 - chi4(p) as f64 / (p * p) as f64; }
    let (mut e3, mut v) = (vec![], 1.0);
    for &p in &[3u64, 5, 7] { v /= 1.0 - chi4(p) as f64 / (p * p) as f64; e3.push(f(v, 6)); }
    println!("Euler product at s=2, primes 3; 3, 5; 3, 5, 7: {}", e3.join(", "));
    println!("L(2,chi4) series {} | Euler product, primes below 10^6 {} | gap {}", f(g, 9), f(e, 9), f((g - e).abs(), 9));
    assert!((g - e).abs() < 1e-6); // Step 2: gap below 1/1,000,000
    fn alt(n: u64) -> i64 { if n % 2 == 1 { 1 } else { -1 } } // periodic, not multiplicative
    let mut ealt = 1.0;
    for &p in &primes { ealt /= 1.0 - alt(p) as f64 / (p * p) as f64; }
    let salt = avg_tail(&real(alt), 2, 2, x).0;
    assert!((salt - pi * pi / 12.0).abs() < 1e-9 && (ealt - salt).abs() > 0.1);
    println!("weight (-1)^(n+1) at s=2: series {} = pi^2/12 {} | fake product {}", f(salt, 6), f(pi * pi / 12.0, 6), f(ealt, 6));
    let mut h = vec![];
    for &n in &[1000u64, 1_000_000] {
        let mut t = 0.0; let mut m = 1u64;
        while m <= n { t += 1.0 / m as f64; m += 2; }
        h.push(t);
    }
    println!("principal chi0 mod 4 at s=1: odd n to 10^3 {} | to 10^6 {}", f(h[0], 6), f(h[1], 6));
    let (mut r3, mut i, mut j) = (0.0f64, 0u64, 0u64); // two plus terms, one minus
    for _ in 0..300000 {
        r3 += 1.0 / (4 * i + 1) as f64 + 1.0 / (4 * i + 5) as f64 - 1.0 / (4 * j + 3) as f64; i += 2; j += 1;
    }
    let target = q + 2f64.ln() / 4.0;
    println!("rearranged 1 + 1/5 - 1/3 + ...: {} | pi/4 + (log 2)/4 {}", f(r3, 6), f(target, 6));
    assert!((r3 - target).abs() < 1e-5);

    // ---- lattice points: sum of r(n) = sum chi4(d) floor(N/d) = (points in circle)/4 ----
    let lattice = |n: u64| -> i64 { // points (a, b) with 0 < a^2 + b^2 <= n
        let r = isqrt(n) as i64;
        (-r..=r).map(|a| 2 * isqrt(n - (a * a) as u64) as i64 + 1).sum::<i64>() - 1
    };
    let mut dlast = 0i64;
    for &n in &[10u64, x] {
        let d: i64 = (1..=n).map(|d| chi4(d) * (n / d) as i64).sum();
        assert_eq!(lattice(n), 4 * d); // Jacobi's two-squares count, checked
        println!("N {} | lattice points {} | divisor sum {} | sum/N {}", n, lattice(n), d, f(d as f64 / n as f64, 6));
        dlast = d;
    }
    assert!((dlast as f64 / x as f64 - q).abs() < 2.0 / (x as f64).sqrt());
    let mut r = vec![0i64; x as usize + 1]; // r(n) = sum of chi4(d) over d | n
    let mut d = 1u64;
    while d <= x { let c = chi4(d); let mut m = d; while m <= x { r[m as usize] += c; m += d; } d += 2; }
    let rmin = *r[1..].iter().min().unwrap();
    let sqmin = (1..1001usize).map(|m| r[m * m]).min().unwrap();
    assert!(rmin >= 0 && sqmin >= 1);
    println!("r(n) for n <= 10^6: smallest {} | smallest at a square {}", rmin, sqmin);
    println!("x, A(x) = sum r(n)/sqrt(n), 2 sqrt(x) pi/4, difference, floor (log x)/2");
    let (mut a, mut n) = (0.0f64, 0usize);
    for &xx in &[100usize, 10000, 1_000_000] {
        while n < xx { n += 1; a += r[n] as f64 / (n as f64).sqrt(); }
        let main = 2.0 * (xx as f64).sqrt() * q;
        let fl = (xx as f64).ln() / 2.0;
        assert!(a >= fl && (a - main).abs() < 2.0);
        println!("{} {} {} {} {}", xx, f(a, 6), f(main, 6), f(a - main, 6), f(fl, 6));
    }

    // ---- primes in the two classes mod 4: the sum of chi4(p)/p against its predicted limit ----
    let c1 = primes.iter().filter(|&&p| p % 4 == 1).count();
    let c3 = primes.iter().filter(|&&p| p % 4 == 3).count();
    println!("primes below 10^6: 1 mod 4 {} | 3 mod 4 {}", c1, c3);
    let (mut sd, mut corr) = (0.0f64, 0.0f64); // sum of chi4(p)/p; prime powers p^k, k >= 2, in log L
    for &p in &primes {
        let t = chi4(p) as f64 / p as f64; let mut tk = t; sd += t;
        for k in 2..41 { tk *= t; corr += tk / k as f64; }
    }
    let pred = q.ln() - corr;
    assert!((sd - pred).abs() < 0.001);
    println!("sum chi4(p)/p, p below 10^6 {} | log(pi/4) {} | minus prime powers: predicted limit {} | gap {}",
             f(sd, 4), f(q.ln(), 6), f(pred, 6), f(sd - pred, 6));

    // ---- last digits: the characters mod 10, chi(3) = i^j ----
    let digits: Vec<String> = [1u64, 3, 7, 9].iter().map(|&a| primes.iter().filter(|&&p| p % 10 == a).count().to_string()).collect();
    println!("last digit 1, 3, 7, 9: {}", digits.join(", "));
    let i4 = [(1.0, 0.0), (0.0, 1.0), (-1.0, 0.0), (0.0, -1.0)]; // 3^k mod 10 is 1, 3, 9, 7
    let mut l10 = 0.0;
    for jj in 1..4usize {
        let ch = move |n: u64| -> (f64, f64) {
            match n % 10 { 1 => i4[0], 3 => i4[jj % 4], 9 => i4[2 * jj % 4], 7 => i4[3 * jj % 4], _ => (0.0, 0.0) }
        };
        let (lr, li) = avg_tail(&ch, 10, 1, x);
        let size = (lr * lr + li * li).sqrt();
        assert!(size > 0.3); // nonzero, as the theorem needs
        println!("mod 10, chi(3) = i^{}: L(1,chi) = {} {} {}i | size {}", jj, f(lr, 6), if li >= 0.0 { "+" } else { "-" }, f(li.abs(), 6), f(size, 6));
        if jj == 2 {
            l10 = lr;
            let cf = 3.0 * ((1.0 + 5f64.sqrt()) / 2.0).ln() / 5f64.sqrt();
            assert!((lr - cf).abs() < 1e-9);
            println!("closed form 3 log((1 + sqrt 5)/2)/sqrt 5 {}", f(cf, 6));
        }
    }

    // ---- two more values with closed forms ----
    let l3 = avg_tail(&real(chi4), 4, 3, x).0;
    println!("L(3,chi4) {} | pi^3/32 {}", f(l3, 6), f(pi * pi * pi / 32.0, 6));
    assert!((l3 - pi * pi * pi / 32.0).abs() < 1e-12);
    fn chi5(n: u64) -> i64 { [0, 1, -1, -1, 1][(n % 5) as usize] } // the real character mod 5, (n/5)
    let (l15, cf5) = (avg_tail(&real(chi5), 5, 1, x).0, 2.0 * ((1.0 + 5f64.sqrt()) / 2.0).ln() / 5f64.sqrt());
    println!("mod 5, L(1,chi5) {} | 2 log((1 + sqrt 5)/2)/sqrt 5 {} | mod-10 value / mod-5 value {}", f(l15, 6), f(cf5, 6), f(l10 / l15, 6));
    assert!((l15 - cf5).abs() < 1e-9 && (l10 / l15 - 1.5).abs() < 1e-9); // the mod-10 value drops the factor at 2
    println!("ALL CHECKS PASS");
}
