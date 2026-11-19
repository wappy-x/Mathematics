// Bounded gaps (Zhang, Maynard) -- the same check as bounded_gaps_zhang_maynard_check.py, in Rust.
// No crates.  Road 1: a sieve counts twin pairs, gaps and tuple hits below a million.  Road 2:
// admissible tuples by brute force and by a greedy sieve.  Road 3: the sieve ratio k*J/I in exact
// fractions, against a closed form and the Bessel-zero formula.  Road 4: real GPY weights.
#[derive(Clone, Copy, PartialEq)]
struct Fr(i128, i128);
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn fr(n: i128, d: i128) -> Fr { let g = gcd(n, d) * d.signum(); Fr(n / g, d / g) }
fn add(a: Fr, b: Fr) -> Fr { fr(a.0.checked_mul(b.1).unwrap().checked_add(b.0.checked_mul(a.1).unwrap()).unwrap(), a.1.checked_mul(b.1).unwrap()) }
fn mul(a: Fr, b: Fr) -> Fr { let (g, h) = (gcd(a.0, b.1).max(1), gcd(b.0, a.1).max(1)); fr((a.0 / g).checked_mul(b.0 / h).unwrap(), (a.1 / h).checked_mul(b.1 / g).unwrap()) }
fn lt(a: Fr, b: Fr) -> bool { a.0 * b.1 < b.0 * a.1 } // denominators are positive
fn fa(n: usize) -> i128 { (1..=n as i128).product() }
fn comb(n: usize, k: usize) -> i128 { fa(n) / fa(k) / fa(n - k) }
fn partitions(n: usize, mx: usize) -> Vec<Vec<usize>> {
    if n == 0 { return vec![vec![]]; }
    let mut out = vec![];
    for p in (1..=n.min(mx)).rev() { for mut r in partitions(n - p, p) { r.insert(0, p); out.push(r); } }
    out
}
fn t(k: usize, a: usize, b: usize) -> Fr { // integral over the k-simplex of (1 - P1)^b * P2^a, exactly
    let mut tot = fr(0, 1);
    for lam in partitions(a, a) {
        if lam.len() > k { continue; }
        let mut ways = fr(fa(k) / fa(k - lam.len()) * fa(a), 1);
        let mut seen = vec![];
        for &x in &lam { if !seen.contains(&x) { seen.push(x); ways = mul(ways, fr(1, fa(lam.iter().filter(|&&y| y == x).count()))); } }
        for &x in &lam { ways = mul(ways, fr(fa(2 * x), fa(x))); }
        tot = add(tot, ways);
    }
    mul(tot, fr(fa(b), fa(k + b + 2 * a)))
}
fn ratio(k: usize, basis: &[(usize, usize)], c: &[i128]) -> Fr { // k * J / I for F = sum c * P2^a * (1 - P1)^b
    let (mut i, mut j) = (fr(0, 1), fr(0, 1));
    for (&(a, b), &u) in basis.iter().zip(c) { for (&(a2, b2), &v) in basis.iter().zip(c) {
        i = add(i, mul(fr(u * v, 1), t(k, a + a2, b + b2)));
        for x in 0..=a { for y in 0..=a2 {
            let f = mul(mul(fr(comb(a, x) * comb(a2, y), 1), fr(fa(b) * fa(2 * x), fa(b + 2 * x + 1))), fr(fa(b2) * fa(2 * y), fa(b2 + 2 * y + 1)));
            j = add(j, mul(mul(fr(u * v, 1), f), t(k - 1, a - x + a2 - y, b + 2 * x + b2 + 2 * y + 2)));
        } }
    } }
    mul(fr(k as i128, 1), mul(j, fr(i.1, i.0)))
}
fn closed(k: i128, b: i128) -> Fr { fr(2 * k * (2 * b + 1), (b + 1) * (k + 2 * b + 1)) }
fn fl(x: Fr) -> f64 { x.0 as f64 / x.1 as f64 }
fn bessel(nu: usize, x: f64) -> f64 { // J_nu(x) by Miller's downward recurrence
    let m = 2 * ((x as usize + nu + 40) / 2);
    let (mut jp, mut j, mut norm, mut out) = (0.0f64, 1e-30f64, 0.0f64, 0.0f64);
    for n in (1..=m).rev() {
        let nj = 2.0 * n as f64 / x * j - jp; jp = j; j = nj;
        if n - 1 == nu { out = j; }
        if (n - 1) % 2 == 0 { norm += if n == 1 { j } else { 2.0 * j }; }
        if j.abs() > 1e200 { jp *= 1e-200; j *= 1e-200; norm *= 1e-200; out *= 1e-200; }
    }
    out / norm
}
fn first_zero(nu: usize) -> f64 {
    let mut lo = nu as f64 + 0.1;
    while bessel(nu, lo + 0.1) > 0.0 && lo < nu as f64 + 99.0 { lo += 0.1; }
    let mut hi = lo + 0.1;
    for _ in 0..60 { let mid = (lo + hi) / 2.0; if bessel(nu, mid) > 0.0 { lo = mid } else { hi = mid } }
    lo
}
fn main() {
    const LIM: usize = 1_000_100;
    let mut s = vec![true; LIM + 1]; s[0] = false; s[1] = false;
    let mut i = 2;
    while i * i <= LIM { if s[i] { let mut m = i * i; while m <= LIM { s[m] = false; m += i; } } i += 1; }
    let ps: Vec<usize> = (2..1_000_000).filter(|&p| s[p]).collect();
    let twins = ps.iter().filter(|&&p| p + 2 < 1_000_000 && s[p + 2]).count();
    let (gap, at) = ps.windows(2).map(|w| (w[1] - w[0], w[0])).fold((0, 0), |b, x| if x.0 > b.0 { x } else { b });
    println!("primes below 1,000,000: {}; twin pairs: {}; widest gap: {}, after {}", ps.len(), twins, gap, at);
    println!("{} is prime number {}; average gap near 1,000,000 = log 1,000,000 = {:.4}", at, ps.iter().position(|&p| p == at).unwrap() + 1, 1e6f64.ln());
    let hits = |h: &[usize], need: usize| (1..1_000_000).filter(|&n| h.iter().filter(|&&x| s[n + x]).count() >= need).count();
    println!("n below 1,000,000 with 2+ primes among n, n+2, n+6: {}; all 3: {}", hits(&[0, 2, 6], 2), hits(&[0, 2, 6], 3));
    println!("all 3 of n, n+2, n+4 prime: {}; both n, n+1 prime: {}", hits(&[0, 2, 4], 3), hits(&[0, 1], 2));
    println!("n below 1,000,000 with 2+ primes in n + (0, 2, 6, 8, 12): {}", hits(&[0, 2, 6, 8, 12], 2));
    let admissible = |h: &[usize]| (2..=h.len()).filter(|&p| s[p]).all(|p| { let mut c = vec![false; p]; for &x in h { c[x % p] = true; } c.iter().any(|&y| !y) });
    fn combos(from: usize, to: usize, r: usize, cur: &mut Vec<usize>, f: &mut dyn FnMut(&[usize]) -> bool) -> bool {
        if r == 0 { return f(cur); }
        for x in from..to { cur.push(x); if combos(x + 1, to, r - 1, cur, f) { cur.pop(); return true; } cur.pop(); }
        false
    }
    let narrowest = |k: usize| { let mut w = 1; loop {
        if combos(1, w, k - 2, &mut vec![], &mut |c: &[usize]| { let mut h = vec![0]; h.extend_from_slice(c); h.push(w); admissible(&h) }) { return w; }
        w += 1; } };
    let widths: Vec<usize> = (2..7).map(narrowest).collect();
    println!("narrowest admissible k-tuple, k = 2..6, by brute force: {:?}", widths);
    let greedy = |width: usize, k: usize, shift: usize| {
        let mut v: Vec<usize> = (shift..=shift + width).collect();
        for p in (2..=k).filter(|&q| s[q]) {
            let mut cnt = vec![0; p]; for &x in &v { cnt[x % p] += 1; }
            let mn = *cnt.iter().min().unwrap(); let r = cnt.iter().position(|&c| c == mn).unwrap();
            v.retain(|&x| x % p != r);
        }
        v[..k].iter().map(|&x| x - v[0]).collect::<Vec<usize>>()
    };
    let (t50, t105) = (greedy(246, 50, 1), greedy(600, 105, 21));
    println!("greedy 50-tuple: width {}, admissible {}; first ten {:?}", t50[49], if admissible(&t50) { "True" } else { "False" }, &t50[..10]);
    println!("greedy 105-tuple: width {}, admissible {}", t105[104], if admissible(&t105) { "True" } else { "False" });
    let mut met = [0usize, 2, 4].map(|h| h % 3).to_vec(); met.sort(); met.dedup();
    println!("inadmissible (0, 2, 4): classes mod 3 met: {}", met.len());
    for b in 0..4 { assert!(ratio(5, &[(0, b)], &[1]) == closed(5, b as i128)); }
    println!("GPY weight (1 - P1)^b, k = 5, b = 0..3: {}", (0..4).map(|b| format!("{:.6}", fl(closed(5, b)))).collect::<Vec<_>>().join(", "));
    println!("GPY weight 1 - P1 on k = 3 (used below): {}/{}", closed(3, 1).0, closed(3, 1).1);
    let best1: Vec<(usize, f64)> = [2, 3, 5, 50, 105].iter().map(|&k| (k, 4.0 * (k * (k - 1)) as f64 / first_zero(k - 2).powi(2))).collect();
    println!("first zero of the Bessel function J_3: {:.6}", first_zero(3));
    println!("best one-variable ratio 4k(k-1)/j^2: {}", best1.iter().map(|(k, v)| format!("k={}: {:.6}", k, v)).collect::<Vec<_>>().join(", "));
    let g = ratio(5, &[(0, 0), (0, 1), (0, 2), (0, 3)], &[1, 4, 4, 5]);
    let m5 = ratio(5, &[(0, 0), (0, 1), (0, 2), (0, 3), (1, 0), (1, 1)], &[1, 11, -39, -22, -9, -81]);
    println!("k = 5, one-variable g = 1 + 4u + 4u^2 + 5u^3: {:.6}", fl(g));
    println!("k = 5, Maynard F with P2 terms: {}/{} = {:.6}", m5.0, m5.1, fl(m5));
    let n0: usize = 100_000;
    let sqf: Vec<usize> = (1..317).filter(|d| (2..18).all(|p| d % (p * p) != 0)).collect();
    let mu = |d: usize| if (2..=d).filter(|&p| s[p] && d % p == 0).count() % 2 == 0 { 1.0 } else { -1.0 };
    for r in [18usize, 316] {
        let lam: Vec<(usize, f64)> = sqf.iter().filter(|&&d| d <= r).map(|&d| (d, mu(d) * (r as f64 / d as f64).ln().powi(4))).collect();
        let (mut w, mut p) = (0.0f64, 0.0f64);
        for n in n0..2 * n0 {
            let pn = (n * (n + 2) * (n + 6)) as u128;
            let x: f64 = lam.iter().filter(|(d, _)| pn % *d as u128 == 0).map(|(_, v)| v).sum();
            w += x * x; p += x * x * [n, n + 2, n + 6].iter().filter(|&&m| s[m]).count() as f64;
        }
        let pred = (r as f64).ln() / (n0 as f64).ln() * 1.5;
        println!("R = {}: log R = {:.4}, log N = {:.4}, log R / log N = {:.4}", r, (r as f64).ln(), (n0 as f64).ln(), (r as f64).ln() / (n0 as f64).ln());
        println!("R = {}: weighted primes per n {:.4}; predicted (log R / log N) x 3/2 = {:.4}", r, p / w, pred);
        assert!((p / w - pred).abs() < 0.1);
    }
    let plain = (n0..2 * n0).map(|n| [n, n + 2, n + 6].iter().filter(|&&m| s[m]).count()).sum::<usize>() as f64 / n0 as f64;
    println!("unweighted primes per n in (n, n+2, n+6), n from 100,000 to 199,999: {:.4}", plain);
    println!("record bounds on the smallest gap that recurs forever: 70,000,000 (2013), 600 (2013), 246 (2014)");
    println!("quoted, not computed here: M_105 > 4 (Maynard); 16 on EH (GPY), 12 on EH, 6 on GEH");
    assert!(ps.len() == 78498 && twins == 8169 && (gap, at) == (114, 492113));
    assert!(widths == vec![2, 6, 8, 12, 16] && admissible(&[0, 2, 6, 8, 12]) && !admissible(&[0, 2, 4]));
    assert!(t50[49] == 246 && t50.len() == 50 && admissible(&t50) && t105[104] == 600 && admissible(&t105));
    assert!(hits(&[0, 2, 4], 3) == 1 && hits(&[0, 1], 2) == 1 && 0.25 < plain && plain < 0.26);
    assert!(lt(fr(2, 1), m5) && fl(g) <= best1[2].1 && best1[2].1 < 2.0 && (fl(g) - best1[2].1).abs() < 1e-4);
    assert!(best1[4].1 < 4.0 && [5i128, 50, 105].iter().all(|&k| (0..30).all(|b| lt(closed(k, b), fr(4, 1)))));
    assert!((best1[0].1 - 8.0 / 2.404825557695773f64.powi(2)).abs() < 1e-9);
    println!("ALL CHECKS PASS");
}
