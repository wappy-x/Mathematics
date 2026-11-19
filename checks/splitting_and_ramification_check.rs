// Splitting and ramification -- the same check as the Python, in Rust.  No crates.
// Field Q(sqrt-5), ring of integers Z[sqrt-5], f(x) = x^2 + 5, d_K = -20.  Every
// prime is classified three ways: road 1 counts the roots of f mod p by trying
// every residue; road 2 counts nilpotents and units in the residue ring
// O_K/pO_K, never touching f's roots; road 3 is Euler's criterion for -5 and the
// rule mod 20 that reciprocity gives.  The cubic Q(cbrt 2) shows patterns past 2.
fn primes_below(n: usize) -> Vec<i64> {                // sieve of Eratosthenes
    let mut s = vec![true; n];
    s[0] = false;
    s[1] = false;
    let mut i = 2;
    while i * i < n {
        if s[i] { let mut j = i * i; while j < n { s[j] = false; j += i; } }
        i += 1;
    }
    (0..n).filter(|&k| s[k]).map(|k| k as i64).collect()
}

fn powmod(a: i64, mut k: i64, m: i64) -> i64 {         // square-and-multiply
    let (mut out, mut a) = (1i64, a.rem_euclid(m));
    while k > 0 {
        if k & 1 == 1 { out = out * a % m; }
        a = a * a % m;
        k >>= 1;
    }
    out
}

fn roots(c: &[i64], p: i64) -> Vec<i64> {              // road 1: residues r with f(r) = 0 mod p
    (0..p).filter(|&r| {
        let (mut s, mut pw) = (0i64, 1i64);
        for &ci in c { s = (s + ci * pw).rem_euclid(p); pw = pw * r % p; }
        s == 0
    }).collect()
}

fn by_roots(p: i64) -> &'static str {                  // 2 roots split, 1 ramifies, 0 inert
    match roots(&[5, 0, 1], p).len() { 2 => "split", 1 => "ramified", _ => "inert" }
}

fn residue_ring(p: i64) -> (usize, usize, &'static str) {  // road 2: a + b sqrt-5 mod p
    let (mut nil, mut units) = (0, 0);
    for a in 0..p {
        for b in 0..p {
            if (a != 0 || b != 0) && (a * a - 5 * b * b).rem_euclid(p) == 0 && 2 * a * b % p == 0 { nil += 1; }   // the nilpotents
            if (a * a + 5 * b * b) % p != 0 { units += 1; }
        }
    }
    let kind = if nil > 0 { "ramified" } else if units as i64 == (p - 1) * (p - 1) { "split" } else { "inert" };
    (nil, units, kind)
}

fn by_euler(p: i64) -> &'static str {                  // road 3a: p | d_K ramifies, else is -5 a square?
    if 20 % p == 0 { return "ramified"; }
    if powmod(-5, (p - 1) / 2, p) == 1 { "split" } else { "inert" }
}

fn by_mod20(p: i64) -> &'static str {                  // road 3b: reciprocity's answer, a rule mod 20
    if 20 % p == 0 { "ramified" } else if [1, 3, 7, 9].contains(&(p % 20)) { "split" } else { "inert" }
}

fn mul(x: (i64, i64), y: (i64, i64)) -> (i64, i64) { (x.0 * y.0 - 5 * x.1 * y.1, x.0 * y.1 + x.1 * y.0) }  // in Z[sqrt-5]

fn is_norm(p: i64) -> bool {                           // is p = a^2 + 5b^2 for whole a, b?
    (0..).take_while(|b| 5 * b * b <= p).any(|b| {
        let t = p - 5 * b * b;
        let a = (t as f64).sqrt() as i64;
        a * a == t
    })
}

fn ef(kind: &str) -> &'static str {
    match kind { "split" => "e = 1, f = 1 twice", "inert" => "e = 1, f = 2", _ => "e = 2, f = 1" }
}

fn cubic(p: i64) -> &'static str {                     // x^3 - 2 mod p, read off its roots
    let rs = roots(&[-2, 0, 0, 1], p);
    if rs.iter().any(|&r| 3 * r * r % p == 0) { return "ramified, e = 3"; }   // also a root of f' = 3x^2
    match rs.len() { 3 => "split completely, f = 1, 1, 1", 1 => "f = 1, 2", _ => "inert, f = 3" }
}

fn yn(c: bool) -> &'static str { if c { "yes" } else { "no" } }

fn main() {
    println!("field Q(sqrt-5): f(x) = x^2 + 5, ring of integers Z[sqrt-5], d_K = 0^2 - 4*5 = {}", 0 - 4 * 5);
    for p in [2i64, 3, 5, 7, 11, 29] {
        let (nil, units, _) = residue_ring(p);
        println!("p = {}: roots of x^2 + 5 mod p {:?}; nilpotents {}, units {} of {}; {} ({})",
                 p, roots(&[5, 0, 1], p), nil, units, p * p, by_roots(p), ef(by_roots(p)));
    }
    let small = primes_below(200);
    let road2_ok = small.iter().all(|&p| residue_ring(p).2 == by_roots(p));
    println!("road 2 agrees with road 1 for all {} primes below 200: {}", small.len(), yn(road2_ok));
    let prod29 = mul((3, 2), (3, -2));
    let r29 = roots(&[5, 0, 1], 29);
    println!("29: (3 + 2 sqrt-5)(3 - 2 sqrt-5) = {} + {} sqrt-5; norm 3^2 + 5*2^2 = {}", prod29.0, prod29.1, 9 + 5 * 4);
    println!("square roots of -5 mod 29: {:?}; 13^2 = {} = 5*29 + {}, and {} = -5 mod 29",
             r29, 13 * 13, 13 * 13 - 5 * 29, 13 * 13 - 5 * 29);
    println!("3 + 2*{} = {}, so 3 + 2 sqrt-5 lies in (29, sqrt-5 - {})", r29[0], 3 + 2 * r29[0], r29[0]);
    println!("5: (sqrt-5)^2 = {}, so (5) = (sqrt-5)^2, one prime, e = 2", mul((0, 1), (0, 1)).0);
    let (t, u) = ((2i64, 0i64), (1i64, 1i64));                       // the generators 2 and 1 + sqrt-5
    let sq2 = vec![mul(t, t), mul(t, u), mul(u, u)];                // the square's generators: all products of two
    let even = sq2.iter().all(|&(a, b)| a % 2 == 0 && b % 2 == 0);
    let two = (sq2[1].0 - sq2[2].0 - sq2[0].0, sq2[1].1 - sq2[2].1 - sq2[0].1);
    println!("2: (2, 1 + sqrt-5)^2 holds {:?}, all multiples of 2: {}; (2 + 2 sqrt-5) - (-4 + 2 sqrt-5) - 4 = {} + {} sqrt-5, so it is (2)",
             sq2, yn(even), two.0, two.1);
    println!("3 = a^2 + 5b^2 has a solution: {}; yet x^2 + 5 = (x - 1)(x - 2) mod 3, so (3) = (3, sqrt-5 - 1)(3, sqrt-5 - 2)",
             yn(is_norm(3)));
    let r3 = roots(&[5, 0, 1], 3);
    println!("6 = 2*3 = (1 + sqrt-5)(1 - sqrt-5), norm {}: 1 + sqrt-5 lies in (3, sqrt-5 - {}) as 1 + {} = {}; 1 - sqrt-5 in (3, sqrt-5 - {}) as 1 - {} = {}",
             1 + 5, r3[1], r3[1], 1 + r3[1], r3[0], r3[0], 1 - r3[0]);
    let big = primes_below(10000);
    let agree = big.iter().all(|&p| by_roots(p) == by_euler(p) && by_euler(p) == by_mod20(p));
    println!("roads 1 and 3 agree on all {} primes below 10,000: {}", big.len(), yn(agree));
    let mut table: Vec<Vec<usize>> = vec![];
    for n in [100i64, 1000, 10000] {
        let kinds: Vec<&str> = big.iter().filter(|&&p| p < n).map(|&p| by_euler(p)).collect();
        let c = |k: &str| kinds.iter().filter(|&&q| q == k).count();
        let row = vec![kinds.len(), c("split"), c("inert"), c("ramified")];
        println!("primes below {}: {}; split {}, inert {}, ramified {}; split share of unramified {:.4}",
                 n, row[0], row[1], row[2], row[3], row[1] as f64 / (row[1] + row[2]) as f64);
        table.push(row);
    }
    let ram: Vec<i64> = big.iter().copied().filter(|&p| by_roots(p) == "ramified").collect();
    let dk_primes: Vec<i64> = primes_below(21).into_iter().filter(|q| 20 % q == 0).collect();
    println!("ramified primes below 10,000: {:?}; primes dividing d_K = -20: {:?}", ram, dk_primes);
    let q1000 = primes_below(1000);
    let spl: Vec<i64> = q1000.iter().copied().filter(|&p| by_euler(p) == "split").collect();
    let nonprin: Vec<i64> = spl.iter().copied().filter(|&p| !is_norm(p)).collect();
    println!("split primes below 1000 equal to a^2 + 5b^2: {}; split but not: {}, first {:?}",
             spl.len() - nonprin.len(), nonprin.len(), &nonprin[..6]);
    let rule = spl.iter().all(|&p| is_norm(p) == [1, 9].contains(&(p % 20)));
    println!("a^2 + 5b^2 exactly when p = 1 or 9 mod 20, among split primes below 1000: {}", yn(rule));
    let gauss: Vec<String> = [2i64, 3, 5, 7, 13].iter()
        .map(|&p| format!("{} {}", p, match roots(&[1, 0, 1], p).len() { 2 => "split", 1 => "ramified", _ => "inert" })).collect();
    println!("Gaussian integers, x^2 + 1, d = -4: {}", gauss.join(", "));
    println!("cubic Q(cbrt 2): f(x) = x^3 - 2, d_K = -4*0^3 - 27*2^2 = {}", -27 * 4);
    for p in [2i64, 3, 5, 7, 31] {
        println!("p = {}: roots of x^3 - 2 mod p {:?}; {}", p, roots(&[-2, 0, 0, 1], p), cubic(p));
    }
    let pat: Vec<&str> = q1000.iter().filter(|&&p| !cubic(p).starts_with('r')).map(|&p| cubic(p).split(',').next().unwrap()).collect();
    let c3 = |k: &str| pat.iter().filter(|&&q| q == k).count();
    let counts3 = [c3("split completely"), c3("f = 1"), c3("inert")];
    println!("unramified primes below 1000: {}; split completely {}, f = 1, 2 {}, inert {}",
             pat.len(), counts3[0], counts3[1], counts3[2]);
    println!("shares {:.4}, {:.4}, {:.4}; Chebotarev's 1/6, 1/2, 1/3 = {:.4}, {:.4}, {:.4}",
             counts3[0] as f64 / pat.len() as f64, counts3[1] as f64 / pat.len() as f64, counts3[2] as f64 / pat.len() as f64, 1.0 / 6.0, 0.5, 1.0 / 3.0);
    let rep: Vec<i64> = q1000.iter().copied().filter(|&p| cubic(p).starts_with('r')).collect();
    let d108: Vec<i64> = primes_below(109).into_iter().filter(|q| 108 % q == 0).collect();
    println!("primes below 1000 where x^3 - 2 has a repeated root: {:?}; primes dividing 108: {:?}", rep, d108);
    let w1 = (roots(&[-5, 0, 1], 2), roots(&[-1, -1, 1], 2));
    println!("mistake 1, Z[sqrt5] for Q(sqrt5): x^2 - 5 mod 2 has roots {:?}, a double root, so 2 looks ramified; x^2 - x - 1 has roots {:?}, so 2 is inert; d_K = 5, not 20",
             w1.0, w1.1);
    println!("mistake 2, no element of norm p read as inert: {} split primes below 1000 misread, first {:?}",
             nonprin.len(), &nonprin[..3]);
    let w3: Vec<i64> = q1000.iter().copied()
        .filter(|&p| 20 % p != 0 && (powmod(5, (p - 1) / 2, p) == 1) != (by_euler(p) == "split")).collect();
    println!("mistake 3, testing 5 instead of -5: {} of {} primes below 1000 misread, first {:?}",
             w3.len(), q1000.len() - 2, &w3[..3]);
    let w4: Vec<i64> = [2i64, 3, 5].into_iter().filter(|q| 5 % q == 0).collect();
    println!("mistake 4, ramified primes read off -5 instead of d_K = -20: {:?}, missing 2", w4);
    assert!(road2_ok && agree && ram == dk_primes && ram == vec![2, 5]);          // three roads, one answer
    assert!(r29 == vec![13, 16] && (3 + 2 * r29[0]) % 29 == 0);                      // roots of x^2 + 5 mod 29
    assert!(prod29 == (29, 0) && even && two == (2, 0));        // ring products: (29) and (2, 1 + sqrt-5)^2 = (2)
    assert!(table[1] == vec![168, 81, 85, 2] && table[2] == vec![1229, 614, 613, 2]);
    assert!(rule && nonprin.len() == 45 && !is_norm(3) && r3 == vec![1, 2] && (1 + r3[1]) % 3 == 0 && (1 - r3[0]) % 3 == 0);
    assert!(rep == d108 && rep == vec![2, 3] && counts3 == [24, 86, 56] && w1 == (vec![1], vec![]) && w3.len() == 87);
    println!("ALL CHECKS PASS");
}
