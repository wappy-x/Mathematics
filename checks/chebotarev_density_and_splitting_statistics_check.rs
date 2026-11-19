// Chebotarev density -- the same check as the Python, in Rust.  No crates.
// Field 1: Q(sqrt-5), from x^2 + 5, group of order 2.  Field 2: the splitting
// field of x^3 - 2, group S3 of order 6.  Every prime is sieved here, every
// Frobenius found two or three ways, and the shares compared with |C|/|G|.
const N: usize = 1_000_000;

fn pow_mod(b: i64, e: i64, m: i64) -> i64 {
    let (mut r, mut b, mut e, m) = (1u128, (b.rem_euclid(m)) as u128, e, m as u128);
    while e > 0 {
        if e & 1 == 1 { r = r * b % m }
        b = b * b % m;
        e >>= 1;
    }
    r as i64
}

fn commas(n: i64) -> String {
    let s = n.abs().to_string();
    let mut out = String::new();
    for (i, ch) in s.chars().enumerate() {
        if i > 0 && (s.len() - i) % 3 == 0 { out.push(',') }
        out.push(ch);
    }
    if n < 0 { format!("-{}", out) } else { out }
}

fn reps(form: impl Fn(i64, i64) -> i64) -> Vec<bool> {   // every value of a form up to N
    let mut out = vec![false; N + 1];
    let lim = (N as f64).sqrt() as i64 + 2;
    for x in -lim..=lim {
        for y in 0..=lim {
            let v = form(x, y);
            if v > 0 && v <= N as i64 { out[v as usize] = true }
        }
    }
    out
}

fn first_rep(form: impl Fn(i64, i64) -> i64, v: i64) -> (i64, i64) {  // smallest (x, y), y first
    for y in 0..=v { for x in 0..=v { if form(x, y) == v { return (x, y) } } }
    panic!("no representation")
}

fn pct(a: usize, b: usize) -> String { format!("{:6.2}%", 100.0 * a as f64 / b as f64) }
fn yn(claim: bool) -> &'static str { if claim { "yes" } else { "no" } }
fn bar(a: usize, b: usize) -> String { "#".repeat((60.0 * a as f64 / b as f64).round() as usize) }
fn list(v: &[i64]) -> String { v.iter().map(|p| p.to_string()).collect::<Vec<_>>().join(" ") }

// Road 1: Frobenius on sqrt-5 is multiplication by (-5)^((p-1)/2) mod p.
fn frob_sign(p: i64) -> i64 { if pow_mod(-5, (p - 1) / 2, p) == 1 { 1 } else { -1 } }

fn roots_test(p: i64) -> usize {                           // roots of x^3 - 2 mod p
    if p % 3 == 2 { return 1 }
    if pow_mod(2, (p - 1) / 3, p) == 1 { 3 } else { 0 }
}

fn main() {
    let mut sieve = vec![true; N + 1];
    sieve[0] = false;
    sieve[1] = false;
    let mut i = 2;
    while i * i <= N {
        if sieve[i] { let mut j = i * i; while j <= N { sieve[j] = false; j += i } }
        i += 1;
    }
    let primes: Vec<i64> = (0..=N).filter(|&p| sieve[p]).map(|p| p as i64).collect();
    let split20 = [1, 3, 7, 9];                            // Road 2: reciprocity mod 20
    let odd: Vec<i64> = primes.iter().copied().filter(|&p| p != 2 && p != 5).collect();
    let agree = odd.iter().all(|&p| (frob_sign(p) == 1) == split20.contains(&(p % 20)));
    let brute = odd.iter().filter(|&&p| p < 10_000)        // Road 3: hunt a square root of -5
        .all(|&p| (frob_sign(p) == 1) == (0..p).any(|x| (x * x + 5) % p == 0));
    let small: Vec<i64> = primes.iter().copied().filter(|&p| p < 50).collect();
    let sp: Vec<i64> = small.iter().copied().filter(|&p| p != 2 && p != 5 && frob_sign(p) == 1).collect();
    let ine: Vec<i64> = small.iter().copied().filter(|&p| p != 2 && p != 5 && frob_sign(p) == -1).collect();
    println!("field Q(sqrt-5): polynomial x^2 + 5, discriminant -20, group of order 2");
    println!("p=3: (-5)^1 mod 3 = {} | p=11: (-5)^5 mod 11 = {}", pow_mod(-5, 1, 3), pow_mod(-5, 5, 11));
    println!("primes below 50: ramified 2 5 | split {} : {} | inert {} : {}", sp.len(), list(&sp), ine.len(), list(&ine));
    println!("house: (1 + sqrt-5)(1 - sqrt-5) = 1 + 5 = {} = 2 x 3", 1 + 5);
    println!("Euler test = residue mod 20, every prime to 1,000,000: {} | = square-root hunt, p < 10,000: {}",
             yn(agree), yn(brute));
    println!("x          pi(x)    split    inert  split share  split - inert");
    let mut rows = Vec::new();
    for &x in &[100i64, 1_000, 10_000, 100_000, 1_000_000] {
        let u: Vec<i64> = odd.iter().copied().filter(|&p| p <= x).collect();
        let s = u.iter().filter(|&&p| frob_sign(p) == 1).count();
        rows.push((u.len() + 2, s, u.len() - s));
        let d = 2 * s as i64 - u.len() as i64;
        let ds = if d >= 0 { format!("+{}", commas(d)) } else { commas(d) };
        println!("{:<9} {:>7} {:>8} {:>8}     {}  {:>6}", commas(x), commas(u.len() as i64 + 2),
                 commas(s as i64), commas((u.len() - s) as i64), pct(s, u.len()), ds);
    }
    let (pi_n, split_n, _) = rows[4];
    let fates: [(&str, [i64; 2]); 4] = [("split, principal    1 9 mod 20", [1, 9]),
        ("split, not principal 3 7 mod 20", [3, 7]), ("inert, splits in Q(i) 13 17", [13, 17]),
        ("inert, splits in Q(sqrt5) 11 19", [11, 19])];
    let counts: Vec<usize> = fates.iter().map(|(_, cl)| odd.iter().filter(|&&p| cl.contains(&(p % 20))).count()).collect();
    println!("the four fates to 1,000,000 among {} unramified primes; each predicted 25.00%", commas(odd.len() as i64));
    for ((name, _), &c) in fates.iter().zip(&counts) {
        println!("{:<32}{:>7} {} {}", name, commas(c as i64), pct(c, odd.len()), bar(c, odd.len()));
    }
    let norm1 = reps(|x, y| x * x + 5 * y * y);
    let norm2 = reps(|x, y| 2 * x * x + 2 * x * y + 3 * y * y);
    let (a, b) = (|x: i64, y: i64| x * x + 5 * y * y, |x: i64, y: i64| 2 * x * x + 2 * x * y + 3 * y * y);
    println!("29 = x^2 + 5y^2 at {:?} | 41 at {:?} | 3 = 2x^2 + 2xy + 3y^2 at {:?} | 7 at {:?}",
             first_rep(a, 29), first_rep(a, 41), first_rep(b, 3), first_rep(b, 7));
    let f1 = odd.iter().all(|&p| norm1[p as usize] == [1, 9].contains(&(p % 20)));
    let f2 = odd.iter().all(|&p| norm2[p as usize] == [3, 7].contains(&(p % 20)));
    println!("p = x^2 + 5y^2 exactly when p = 1, 9 mod 20: {} | p = 2x^2 + 2xy + 3y^2 exactly when p = 3, 7 mod 20: {}",
             yn(f1), yn(f2));
    // Field 2: x^3 - 2.  Roots mod p by the cube test (Road 1) and by brute force.
    let big: Vec<i64> = primes.iter().copied().filter(|&p| p > 3).collect();
    let cube_ok = big.iter().filter(|&&p| p < 10_000)
        .all(|&p| roots_test(p) == (0..p).filter(|&x| (x * x % p * x - 2).rem_euclid(p) == 0).count());
    println!("x^3 - 2: discriminant -108, group S3 of 6 symmetries, classes of size 1, 3, 2");
    let rts: Vec<String> = [5i64, 7, 31].iter()
        .map(|&p| format!("{:?}", (0..p).filter(|&x| (x * x * x - 2).rem_euclid(p) == 0).collect::<Vec<i64>>())).collect();
    println!("roots of x^3 - 2 mod 5, 7, 31: {} | 31 = x^2 + 27y^2 at {:?}", rts.join(" "), first_rep(|x, y| x * x + 27 * y * y, 31));
    println!("cube test = brute-force root count, every prime 5 to 10,000: {}", yn(cube_ok));
    println!("x          primes  1+1+1 (3 roots)  2+1 (1 root)   3 (0 roots)");
    let (mut s3, mut nu) = (vec![0usize; 3], 0usize);
    for &x in &[1_000i64, 10_000, 100_000, 1_000_000] {
        let u: Vec<i64> = big.iter().copied().filter(|&p| p <= x).collect();
        let c: Vec<usize> = [3, 1, 0].iter().map(|&r| u.iter().filter(|&&p| roots_test(p) == r).count()).collect();
        println!("{:<9} {:>7} {:>7} {} {:>6} {} {:>6} {}", commas(x), commas(u.len() as i64),
                 commas(c[0] as i64), pct(c[0], u.len()), commas(c[1] as i64), pct(c[1], u.len()),
                 commas(c[2] as i64), pct(c[2], u.len()));
        s3 = c;
        nu = u.len();
    }
    println!("S3 predicts                1/6 = 16.67%      1/2 = 50.00%  1/3 = 33.33%");
    for (name, k) in [("1+1+1, identity", s3[0]), ("2+1, three swaps", s3[1]), ("3, two 3-cycles", s3[2])] {
        println!("{:<17}{} {}", name, pct(k, nu), bar(k, nu));
    }
    let form27 = reps(|x, y| x * x + 27 * y * y);
    let gauss = big.iter().filter(|&&p| p % 3 == 1).all(|&p| (roots_test(p) == 3) == form27[p as usize]);
    println!("for p = 1 mod 3: 2 is a cube mod p exactly when p = x^2 + 27y^2, to 1,000,000: {}", yn(gauss));
    println!("mistake 1, Q(cbrt 2) taken as Galois: predicts 33.33% split completely, count {}", pct(s3[0], nu));
    println!("mistake 2, every pattern equally likely: predicts 33.33% each, count {} {} {}",
             pct(s3[0], nu), pct(s3[1], nu), pct(s3[2], nu));
    let r3: Vec<i64> = (0..3).filter(|&x| (x * x * x - 2i64).rem_euclid(3) == 0).collect();
    let cubed = (0..3i64).all(|x| ((x + 1).pow(3) - (x * x * x - 2)).rem_euclid(3) == 0);
    println!("mistake 3, ramified p = 3: roots {:?}, one root, looks like 2+1; but x^3 - 2 = (x + 1)^3 mod 3: {}, a triple root",
             r3, yn(cubed));
    println!("mistake 4, 'splits' read as 'p = x^2 + 5y^2': predicts 50.00%, count {}", pct(counts[0], odd.len()));
    assert!(agree && brute && f1 && f2 && cube_ok && gauss);              // roads agree
    assert!(pi_n == 78_498);                                              // sieve vs known pi(10^6)
    assert!(split_n == counts[0] + counts[1]);                            // Euler count = mod-20 count
    assert!((split_n as f64 / (pi_n - 2) as f64 - 0.5).abs() < 1.5 / ((pi_n - 2) as f64).sqrt());
    assert!(counts.iter().all(|&c| (c as f64 / odd.len() as f64 - 0.25).abs() < 0.01));
    assert!(s3.iter().zip([1.0 / 6.0, 0.5, 1.0 / 3.0]).all(|(&k, f)| (k as f64 / nu as f64 - f).abs() < 0.01));
    assert!((s3[0] as f64 / nu as f64 - 1.0 / 3.0).abs() > 0.1);          // mistake 1 really misses
    assert!(r3 == vec![2]);                                               // mistake 3: one root mod 3
    assert!(cubed);                                                       // yet a triple root
    println!("ALL CHECKS PASS");
}
