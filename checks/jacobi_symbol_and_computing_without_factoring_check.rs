// The Jacobi symbol -- the same check as the Python twin, in Rust.  No crates.
// (1001/9907) by reciprocity alone, in six rounds and with no factoring; then three more
// roads to the same -1; then Euler's criterion as the Solovay-Strassen test, against the
// Fermat and Miller-Rabin tests, on every base of every odd composite below 2,000.
fn gcd(a: u128, b: u128) -> u128 { if b == 0 { a } else { gcd(b, a % b) } }
fn mulmod(a: u128, b: u128, n: u128) -> u128 { a.checked_mul(b).expect("overflow") % n }
fn modpow(mut b: u128, mut e: u128, n: u128) -> u128 {       // square and multiply on the n clock
    let mut r = 1; b %= n;
    while e > 0 {
        if e & 1 == 1 { r = mulmod(r, b, n); }
        b = mulmod(b, b, n); e >>= 1;
    }
    r
}
fn py(b: bool) -> &'static str { if b { "True" } else { "False" } }
fn jacobi_full(a: u128, n: u128, log: &mut Vec<String>, two_rule: bool, flip_rule: bool) -> (i32, u32) {
    let (mut a, mut n, mut s, mut r) = (a % n, n, 1i32, 0u32);   // road one: reciprocity only
    while a != 0 {
        r += 1; let mut k = 0; let start = (a, n);
        while a % 2 == 0 {                 // pull out the twos: (2/n) = -1 when n is 3 or 5 mod 8
            a /= 2; k += 1;
            if two_rule && (n % 8 == 3 || n % 8 == 5) { s = -s; }
        }
        let two = if n % 8 == 3 || n % 8 == 5 { -1 } else { 1 };
        if a == 1 {
            log.push(format!("round {}: ({}/{})  twos out: {}, each (2/{}) = {:+}  top is 1, so the sign is the answer: {:+}", r, start.0, start.1, k, n, two, s));
            return (s, r);
        }
        let flip = if a % 4 == 3 && n % 4 == 3 { -1 } else { 1 };
        if flip_rule { s *= flip; }        // reciprocity: flip, and change sign if both are 3 mod 4
        let (na, nn) = (n % a, a); a = na; n = nn;
        let tw = if k > 0 { format!(", (2/{}) = {:+}", start.1, two) } else { String::new() };
        log.push(format!("round {}: ({}/{})  twos out: {}{}  flip: ({}/{}), sign {:+}  reduce: ({}/{})  sign so far {:+}", r, start.0, start.1, k, tw, start.1, n, flip, a, n, s));
    }
    (if n == 1 { s } else { 0 }, r)
}
fn jacobi(a: u128, n: u128) -> (i32, u32) { jacobi_full(a, n, &mut Vec::new(), true, true) }
fn is_prime(n: u128) -> bool { n > 1 && (2..).take_while(|d| d * d <= n).all(|d| n % d != 0) }
fn euler(a: u128, p: u128) -> i32 {        // a^((p-1)/2) on the p clock, read as -1, 0 or +1
    let v = modpow(a, (p - 1) / 2, p);
    if v == p - 1 { -1 } else { v as i32 }
}
fn jacobi_def(a: u128, n: u128) -> i32 {   // road three: the definition, factor n and multiply Legendre symbols
    let (mut s, mut m, mut p) = (1, n, 3);
    while m > 1 {
        while m % p == 0 { s *= euler(a, p); m /= p; }
        p += 2;
    }
    s
}
fn census(n: u128) -> (u32, u32, u32, u32, bool) {   // coprime bases; Fermat, Euler and strong liars
    let (mut d, mut s) = (n - 1, 0);
    while d % 2 == 0 { d /= 2; s += 1; }
    let (mut co, mut f, mut eu, mut st, mut subset) = (0, 0, 0, 0, true);
    for a in 1..n {
        if gcd(a, n) != 1 { continue; }
        co += 1; if modpow(a, n - 1, n) == 1 { f += 1; }
        let j = jacobi(a, n).0;
        let e_ok = modpow(a, (n - 1) / 2, n) == if j == -1 { n - 1 } else { j as u128 };
        let mut x = modpow(a, d, n); let mut s_ok = x == 1 || x == n - 1;
        for _ in 1..s { x = mulmod(x, x, n); s_ok = s_ok || x == n - 1; }
        if e_ok { eu += 1; } if s_ok { st += 1; } subset = subset && (e_ok || !s_ok);
    }
    (co, f, eu, st, subset)
}
fn main() {
    let mut log = Vec::new();
    let (jv, rounds) = jacobi_full(1001, 9907, &mut log, true, true);
    for line in &log { println!("{}", line); }
    println!("(1001/9907) = {:+} after {} rounds; 9907 prime by trial division: {}", jv, rounds, py(is_prime(9907)));
    let e = modpow(1001, 4953, 9907);
    println!("road two, Euler's criterion: 1001^4953 on the 9907 clock = {}, which is 9907 - 1, so {:+}", e, euler(1001, 9907));
    println!("road three, factor 1001 = 7 x 11 x 13 = {}: (7/9907) = {:+}, (11/9907) = {:+}, (13/9907) = {:+}, product {:+}", 7 * 11 * 13, euler(7, 9907), euler(11, 9907), euler(13, 9907), jacobi_def(1001, 9907));
    let sq = (0..9907u128).filter(|x| x * x % 9907 == 1001).count();
    let mut res: Vec<u128> = (1..9907u128).map(|x| x * x % 9907).collect(); res.sort(); res.dedup();
    println!("road four, brute force: x with x^2 = 1001 on the 9907 clock: {} of 9907 tried; residues mod 9907: {}", sq, res.len());
    let (mut pairs, mut bad) = (0, 0);
    for n in (3..1000u128).step_by(2) {
        for a in 0..n { pairs += 1; if jacobi(a, n).0 != jacobi_def(a, n) { bad += 1; } }
    }
    println!("reciprocity algorithm against the definition, odd n below 1,000, every a below n: {} pairs, {} disagree", pairs, bad);
    let mut recip = 0;
    for m in (3..300u128).step_by(2) { for n in (3..300u128).step_by(2) {
        let sign = if ((m - 1) / 2 * ((n - 1) / 2)) % 2 == 0 { 1 } else { -1 };
        if gcd(m, n) == 1 && jacobi_def(m, n) * jacobi_def(n, m) != sign { recip += 1; }
    } }
    println!("reciprocity for every coprime odd m, n below 300, from the definition: {} failures", recip);
    let (p, a) = ((1u128 << 61) - 1, 1_000_000_000_000_000_009u128);
    let (jp, rp) = jacobi(a, p);
    println!("a 19-digit case: ({}/{}) = {:+} in {} rounds; Euler's criterion gives {:+}", a, p, jp, rp, euler(a, p));
    let mut sq15: Vec<u128> = (0..15u128).map(|x| x * x % 15).collect(); sq15.sort(); sq15.dedup();
    println!("(2/15) = {:+}, yet the squares mod 15 are {:?}: 2 is not one; (2/3) = {:+}, (2/5) = {:+}", jacobi(2, 15).0, sq15, euler(2, 3), euler(2, 5));
    for n in [221u128, 561, 1105, 1729] {
        let (co, f, eu, st, _) = census(n);
        println!("{}: coprime bases {}, Fermat liars {}, Euler liars {}, strong liars {}", n, co, f, eu, st);
    }
    for a in [2u128, 5, 13] {
        let (x, j) = (modpow(a, 280, 561), jacobi(a, 561).0);
        let v = if x == (if j == -1 { 560 } else { j as u128 }) { "liar, says prime" } else { "witness, proves composite" };
        println!("561, base {:>2}: a^280 = {:>3}, (a/561) = {:+} -> {}; Fermat's a^560 = {}", a, x, j, v, modpow(a, 560, 561));
    }
    let (mut worst, mut arg, mut comps, mut sub_ok, mut half_ok) = (0u32, Vec::new(), 0, true, true);
    for n in (9..2000u128).step_by(2) {
        if is_prime(n) { continue; }
        let (co, _f, eu, _st, sub) = census(n); comps += 1;
        sub_ok = sub_ok && sub; half_ok = half_ok && 2 * eu <= co; let pm = eu * 1000 / co;
        if pm > worst { worst = pm; arg = vec![n]; } else if pm == worst { arg.push(n); }
    }
    println!("odd composites below 2,000: {}; none has Euler liars above half its coprime bases: {}; most, per thousand: {}, at {:?}", comps, py(half_ok), worst, arg);
    println!("every strong liar of every one of them is an Euler liar: {}", py(sub_ok));
    println!("20 rounds: Solovay-Strassen leaves at most 1 in {}, Miller-Rabin at most 1 in {}", 1u128 << 20, 1u128 << 40);
    let no2 = jacobi_full(1001, 9907, &mut Vec::new(), false, true).0;
    let noflip = jacobi_full(3, 7, &mut Vec::new(), true, false).0;
    println!("what breaks: drop the 2 rule, (1001/9907) = {:+}; drop the reciprocity sign, (3/7) = {:+} against {:+}", no2, noflip, euler(3, 7));
    assert!(jv == -1 && rounds == 6 && e == 9906 && jacobi_def(1001, 9907) == -1 && sq == 0);
    assert!(bad == 0 && recip == 0 && jp == euler(a, p) && jacobi(2, 15).0 == 1 && !sq15.contains(&2));
    let (c561, c1729) = (census(561), census(1729));
    assert!((c561.1, c561.2, c561.3) == (320, 80, 10) && c1729.2 * 2 == c1729.0 && worst == 500 && half_ok && sub_ok);
    assert!(modpow(13, 280, 561) == 1 && jacobi(13, 561).0 == -1 && modpow(5, 280, 561) == 67);
    assert!(no2 == 1 && noflip == 1 && euler(3, 7) == -1);
    println!("ALL CHECKS PASS");
}
