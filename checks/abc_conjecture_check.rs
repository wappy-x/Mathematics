// The abc conjecture, status card: the quality of a triple, the record 2 + 3^10*109 = 23^5,
// and what the epsilon and the constant mean.  Rust std only, no crates.  abc is open, so every
// count is evidence.  Roads: radical by sieve against trial division; hits by a pruned search
// against brute force; the record's quality by logarithms against exact integer powers.
fn gcd(a: u64, b: u64) -> u64 { if b == 0 { a } else { gcd(b, a % b) } }
fn rad_trial(mut n: u128) -> u128 { // product of the distinct primes dividing n
    let (mut r, mut p) = (1u128, 2u128);
    while p * p <= n {
        if n % p == 0 { r *= p; while n % p == 0 { n /= p; } }
        p += 1;
    }
    if n > 1 { r * n } else { r }
}
fn rad_sieve(n: usize) -> Vec<u64> {
    let mut rad = vec![1u64; n + 1];
    for p in 2..=n {
        if rad[p] == 1 { let mut m = p; while m <= n { rad[m] *= p as u64; m += p; } } // p is prime
    }
    rad
}
fn q(a: u128, b: u128, c: u128) -> f64 { (c as f64).ln() / (rad_trial(a * b * c) as f64).ln() }
fn commas(n: u64) -> String {
    let (s, mut out) = (n.to_string(), String::new());
    for (i, ch) in s.chars().enumerate() {
        if i > 0 && (s.len() - i) % 3 == 0 { out.push(','); }
        out.push(ch);
    }
    out
}
// a small bignum: little-endian base 2^32 limbs, enough for base^e and a comparison
fn big_pow(base: u64, e: u32) -> Vec<u32> {
    let mut x = vec![1u32];
    for _ in 0..e {
        let mut carry = 0u64;
        for limb in x.iter_mut() { let t = *limb as u64 * base + carry; *limb = t as u32; carry = t >> 32; }
        while carry > 0 { x.push(carry as u32); carry >>= 32; }
    }
    x
}
fn big_lt(a: &[u32], b: &[u32]) -> bool {
    if a.len() != b.len() { return a.len() < b.len(); }
    for i in (0..a.len()).rev() { if a[i] != b[i] { return a[i] < b[i]; } }
    false
}
fn tf(b: bool) -> &'static str { if b { "True" } else { "False" } }
fn main() {
    // ---- the record triple ----
    let (a, b, c) = (2u128, 3u128.pow(10) * 109, 23u128.pow(5));
    let r = rad_trial(a * b * c);
    println!("record: 2 + 3^10*109 = 23^5:  {} + {} = {}", a, commas(b as u64), commas(c as u64));
    println!("rad = 2*3*109*23 = {}   log c = {:.4}   log rad = {:.4}   quality = {:.4}",
             commas(r as u64), (c as f64).ln(), (r as f64).ln(), q(a, b, c));
    assert!(a + b == c && gcd(a as u64, b as u64) == 1 && r == 2 * 3 * 109 * 23); // trial division against the factorisation
    let cp = big_pow(c as u64, 10000);
    assert!(big_lt(&big_pow(r as u64, 16299), &cp) && big_lt(&cp, &big_pow(r as u64, 16300))); // exact bracket
    assert!(1.6299 < q(a, b, c) && q(a, b, c) < 1.6300); // the logarithm road lands inside the exact bracket
    println!("exact powers: rad^16299 < c^10000 < rad^16300, so 1.6299 < quality < 1.6300");
    println!("c / rad = {:.4}", c as f64 / r as f64);
    println!("small example: 1 + 8 = 9  rad = {}  quality = {:.4}", rad_trial(72), q(1, 8, 9));

    // ---- every hit with c below 100,000, by a pruned search ----
    let n = 100_000usize;
    let rad = rad_sieve(n);
    assert!((1..3001).all(|m| rad[m] as u128 == rad_trial(m as u128)));
    let mut order: Vec<usize> = (1..=n).collect();
    order.sort_by_key(|&x| rad[x]);
    let mut hits: Vec<(u64, u64, u64)> = Vec::new();
    for cc in 3..n {
        let bound = cc as u64 / rad[cc]; // rad(a) * rad(b) must stay below c / rad(c)
        for &aa in &order {
            if rad[aa] > bound { break; }
            if aa >= cc { continue; }
            let bb = cc - aa;
            if aa < bb && gcd(aa as u64, bb as u64) == 1 && rad[aa] * rad[bb] * rad[cc] < cc as u64 {
                hits.push((aa as u64, bb as u64, cc as u64));
            }
        }
    }
    let mut brute = Vec::new();
    for y in 3u64..2000 { for x in 1..(y + 1) / 2 {
        if gcd(x, y) == 1 && rad_trial((x * (y - x) * y) as u128) < y as u128 { brute.push((x, y - x, y)); }
    } }
    let mut small: Vec<_> = hits.iter().cloned().filter(|h| h.2 < 2000).collect();
    small.sort(); brute.sort();
    assert!(small == brute); // two roads, same list
    println!("\nhits (rad(abc) < c) with c below 2,000: pruned {}, brute force {}", small.len(), brute.len());
    let rr = |x: u64| rad[x as usize];
    let mut quals: Vec<(f64, u64, u64, u64)> = hits.iter()
        .map(|&(x, y, z)| ((z as f64).ln() / ((rr(x) * rr(y) * rr(z)) as f64).ln(), x, y, z)).collect();
    quals.sort_by(|p, s| s.partial_cmp(p).unwrap());
    println!("quality ladder, c below 100,000 (the record lies beyond); one # per 7 hits, rounded up:");
    for t in [1.0, 1.1, 1.2, 1.3, 1.4, 1.5, 1.6] {
        let k = quals.iter().filter(|v| v.0 > t).count();
        println!("  quality > {:.1}  {:<60}  {:>3}", t, "#".repeat((k + 6) / 7), k);
    }
    println!("top three, c below 100,000:");
    for &(v, x, y, z) in &quals[..3] {
        println!("  {} + {} = {}   rad = {}   quality = {:.4}", commas(x), commas(y), commas(z), commas(rr(x) * rr(y) * rr(z)), v);
    }
    assert!((quals[0].1, quals[0].2, quals[0].3) == (1, 4374, 4375) && quals.len() == 418);

    // ---- what the constant K must be, for each epsilon, on what is known ----
    println!("\nsmallest K with c < K rad^(1+eps) on the hits below 100,000 plus the record");
    let mut pool: Vec<(u64, u64, u64, u64)> = hits.iter().map(|&(x, y, z)| (x, y, z, rr(x) * rr(y) * rr(z))).collect();
    pool.push((a as u64, b as u64, c as u64, r as u64));
    for eps in [0.0f64, 0.2, 0.4, 0.6, 0.7] {
        let mut best = (f64::MIN, 0, 0, 0);
        for &(x, y, z, w) in &pool {
            let k = z as f64 / (w as f64).powf(1.0 + eps);
            if k > best.0 { best = (k, x, y, z); }
        }
        println!("  eps = {:.1}:  K at least {:10.4}   set by {} + {} = {}", eps, best.0, commas(best.1), commas(best.2), commas(best.3));
        if eps == 0.7 { assert!(best.0 < 1.0); } else { assert!(best.0 > 1.0); } // no triple here reaches 1.7
    }

    // ---- what abc would buy: a Fermat solution x^n + y^n = z^n has quality above n/3 ----
    println!("\nFermat: rad(x^n y^n z^n) <= xyz < z^3, so quality > log z^n / log z^3 = n/3");
    for k in [4.0f64, 5.0, 6.0] {
        println!("  n = {}: quality above {:.4}   beats the record: {}", k, k / 3.0, tf(k / 3.0 > q(a, b, c)));
    }

    // ---- proved against conjectured, on the record (logarithms of c) ----
    let lr = (r as f64).ln();
    println!("\nsize of log c on the record:");
    println!("  actual log c                         {:12.4}", (c as f64).ln());
    println!("  abc, eps = 0.7: (1 + eps) log rad    {:12.4}   plus log K", 1.7 * lr);
    println!("  proved shape rad^(1/3) (log rad)^3   {:12.4}   times an unstated K", (r as f64).powf(1.0 / 3.0) * lr.powi(3));

    // ---- what breaks ----
    println!("\nwhat breaks");
    println!("no constant, eps = 0.2: 6^1.2 = {:.4} < 9, so c < rad^1.2 fails at 1 + 8 = 9", 6f64.powf(1.2));
    assert!(6u64.pow(6) < 9u64.pow(5)); // exact: 6^1.2 < 9
    let fam: Vec<(u128, u128)> = (1..6u32).map(|k| (3u128.pow(1 << k), rad_trial(3u128.pow(1 << k) - 1) * 3)).collect();
    let s: Vec<String> = fam.iter().map(|&(z, w)| format!("{:.4}", z as f64 / w as f64)).collect();
    println!("eps = 0, family 1 + (3^(2^k) - 1) = 3^(2^k):  c/rad = {}", s.join(", "));
    assert!(fam.windows(2).all(|p| p[0].0 * p[1].1 < p[1].0 * p[0].1)); // exact: c/rad grows
    println!("product, not radical: log c / log(abc) = {:.4}", (c as f64).ln() / ((a * b * c) as f64).ln());
    println!("common factor: 512 + 512 = 1024  quality = {:.4}", 1024f64.ln() / (rad_trial(512 * 512 * 1024) as f64).ln());
    assert!(rad_trial(512 * 512 * 1024) == 2);

    println!("\ntry changing");
    println!("hits with c below 10,000: {}", hits.iter().filter(|h| h.2 < 10_000).count());
    println!("eps = 0.65: K at least {:.4}", c as f64 / (r as f64).powf(1.65));
    println!("3 + 125 = 128: quality = {:.4}", q(3, 125, 128));
    println!("Fermat n = 7: quality above {:.4}", 7.0 / 3.0);
    println!("ALL CHECKS PASS");
}
