// Cauchy condensation -- the same check as the Python, in Rust.  No crates;
// ln() is a primitive.  Every sum is added here one term at a time.
fn a1(n: f64) -> f64 { 1.0 / (n * n.ln()) }                   // the card's series, from n = 2
fn a2(n: f64) -> f64 { let l = n.ln(); 1.0 / (n * (l * l)) }  // the same with (ln n)^2
fn sq(n: f64) -> f64 { 1.0 / (n * n) }                         // the p-series with p = 2
fn cond(a: fn(f64) -> f64, k: u32) -> f64 { let t = (1u64 << k) as f64; t * a(t) }
fn csum(a: fn(f64) -> f64, k: u32) -> f64 { (1..=k).map(|j| cond(a, j)).sum() }
fn f3(v: Vec<f64>) -> String { v.iter().map(|x| format!("{:.3}", x)).collect::<Vec<_>>().join(" ") }

fn main() {
    const KMAX: u32 = 20;
    let n_big: u64 = 1 << KMAX;                                // 1048576, about a million terms
    let (mut s1, mut s2) = (0.0f64, 0.0f64);
    let mut at = vec![(0.0, 0.0); KMAX as usize + 1];
    for n in 2..=n_big {                                       // road one: add every term
        s1 += a1(n as f64);
        s2 += a2(n as f64);
        if n & (n - 1) == 0 { at[n.trailing_zeros() as usize] = (s1, s2) }
    }
    for k in 1..=KMAX {                                        // road two: the condensed sandwich
        let (c1, c2) = (csum(a1, k), csum(a2, k));
        let (x1, x2) = at[k as usize];
        assert!(c1 / 2.0 <= x1 && x1 <= c1 && c2 / 2.0 <= x2 && x2 <= c2);
        assert!((cond(a1, k) - 1.0 / (k as f64 * 2f64.ln())).abs() < 1e-12); // harmonic in k
        assert!((cond(a2, k) - 1.0 / (k as f64 * 2f64.ln()).powi(2)).abs() < 1e-12); // squares in k
    }
    let ks: Vec<u32> = (2..=KMAX).step_by(2).collect();
    println!("figure, K (sum runs to 2^K): {}", ks.iter().map(|k| k.to_string()).collect::<Vec<_>>().join(" "));
    println!("figure, half condensed: {}", f3(ks.iter().map(|&k| csum(a1, k) / 2.0).collect()));
    println!("figure, sum of 1/(n ln n): {}", f3(ks.iter().map(|&k| at[k as usize].0).collect()));
    println!("figure, condensed: {}", f3(ks.iter().map(|&k| csum(a1, k)).collect()));
    let nf = n_big as f64;
    let lnln = |x: f64| x.ln().ln();
    let (lo, hi) = (lnln(nf + 1.0) - lnln(2.0), a1(2.0) + lnln(nf) - lnln(2.0));
    assert!(lo <= s1 && s1 <= hi);                             // road three: area under 1/(x ln x)
    println!("1/(n ln n) to N={}: sum {:.6}, integral bounds {:.6} to {:.6}", n_big, s1, lo, hi);
    println!("condensed term at k=20: {:.6}; 1/(20 ln 2) = {:.6}", cond(a1, 20), 1.0 / (20.0 * 2f64.ln()));
    println!("ln ln N: at 2^20 {:.6}, at 10^6 {:.6}; sum to 2^10 {:.6}, gain to 2^20 {:.6}, ln 2 = {:.6}",
             lnln(nf), lnln(1e6), at[10].0, s1 - at[10].0, 2f64.ln());
    let block: f64 = (4..8).map(|n| a1(n as f64)).sum();
    println!("block 4..7: {:.3}, under c_2 = {:.3}", block, cond(a1, 2));
    let c = s1 - lnln(nf);                                     // the sum runs about ln ln N + c
    println!("sum minus ln ln N: {:.6}; estimate: passing 5 takes about 10^{:.0} terms", c, (5.0 - c).exp() / 10f64.ln());
    let z2: f64 = (1..1_000_000u64).map(|k| 1.0 / (k * k) as f64).sum::<f64>() + 1e-6;
    let l2 = 2f64.ln() * 2f64.ln();
    let (low2, up2) = (z2 / l2 / 2.0, z2 / l2);
    let (box_lo, box_hi) = (s2 + 1.0 / (nf + 1.0).ln(), s2 + 1.0 / nf.ln());
    let (lo10, hi10) = (at[10].1 + 1.0 / 1025f64.ln(), at[10].1 + 1.0 / 1024f64.ln()); // the box at 2^10
    assert!(low2 <= lo10 && lo10 <= box_lo && box_hi <= hi10 && hi10 <= up2); // 2^20 box inside it
    println!("1/(n (ln n)^2) to N={}: sum {:.6}, whole sum between {:.6} and {:.6}", n_big, s2, box_lo, box_hi);
    println!("its condensed series 1/(k^2 (ln 2)^2): half {:.6}, whole {:.6}", low2, up2);
    let sqs: f64 = (2..=n_big).map(|n| sq(n as f64)).sum();
    let gq = csum(sq, KMAX);
    assert!(gq / 2.0 <= sqs && sqs <= gq && (gq - (1.0 - 2f64.powi(-20))).abs() < 1e-15);
    println!("p=2: sum of 1/n^2, n=2..2^20, {:.6}; condensed 1/2 + 1/4 + ... to k=20 {:.6}", sqs, gq);
    let m = 1_000_000usize;                                    // primes below a million, by sieve
    let mut sieve = vec![true; m + 1];
    sieve[0] = false;
    sieve[1] = false;
    for i in 2..=1000 {
        if sieve[i] { let mut j = i * i; while j <= m { sieve[j] = false; j += i } }
    }
    let p: Vec<usize> = (0..=m).filter(|&i| sieve[i]).collect();
    assert!((6..=p.len()).all(|n| { let x = n as f64; (p[n - 1] as f64) < x * (x.ln() + x.ln().ln()) }));
    let rp: f64 = p.iter().map(|&q| 1.0 / q as f64).sum();
    println!("primes below 10^6: {}, sum of 1/p {:.6}; largest {}; p_n < n (ln n + ln ln n), n = 6..{}: yes",
             p.len(), rp, p[p.len() - 1], p.len());
    let gap: f64 = (1..=n_big).filter(|n| n & (n - 1) != 0).map(|n| 1.0 / n as f64).sum();
    println!("mistake 1, not decreasing: sum to 2^20 {:.6}, condensed sum 0", gap);
    let drop: f64 = (1..=20u32).map(|k| a1((1u64 << k) as f64)).sum();
    println!("mistake 2, 2^k dropped: sum of a(2^k), k=1..20, {:.6}", drop);
    println!("mistake 3, condensed value as the sum: {:.6} against {:.6}", up2, box_hi);
    println!("ALL CHECKS PASS");
}
