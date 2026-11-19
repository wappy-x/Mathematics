// The L-function of y^2 = x^3 - 2 -- the same check as the Python, in Rust.  No
// crates.  Every a_p comes from counting points mod p.  Road 1: the local
// factor predicts the counts over F_p, F_p^2, F_p^3, checked by enumeration.
// Road 2: the Euler product against the series sum of a_n / n^s.  Road 3: the
// symmetry a modular form must have picks the conductor 1728 out of 54 tries.
use std::collections::HashMap;
const B: i64 = -2;
const X: usize = 10000;

#[derive(Clone, Copy, PartialEq, Debug)]
struct Q { n: i128, d: i128 }                       // a fraction in lowest terms
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i128, d: i128) -> Q { let g = gcd(n, d) * d.signum(); Q { n: n / g, d: d / g } }
fn qmul(a: Q, b: Q) -> Q { q(a.n.checked_mul(b.n).unwrap(), a.d.checked_mul(b.d).unwrap()) }
fn show(a: Q) -> String { if a.d == 1 { format!("{}", a.n) } else { format!("{}/{}", a.n, a.d) } }

fn count_mod_p(p: i64) -> i64 {                     // points over F_p, with O
    let mut squares = vec![0i64; p as usize];
    for y in 0..p { squares[(y * y % p) as usize] += 1 }
    1 + (0..p).map(|x| squares[(x * x * x + B).rem_euclid(p) as usize]).sum::<i64>()
}

fn digits(idx: i64, p: i64, k: usize) -> Vec<i64> {   // first coordinate most significant
    (0..k).map(|i| idx / p.pow((k - 1 - i) as u32) % p).collect()
}

fn count_over_field(p: i64, k: usize) -> i64 {      // points over F_(p^k), enumerated
    let size = p.pow(k as u32);
    let mut rule = vec![0i64; k];                   // x^k = rule[0] + rule[1] x + ...
    if k > 1 {                                      // degree 2 or 3: irreducible = no root
        rule = (0..size).map(|i| digits(i, p, k)).find(|r| (0..p).all(|z| {
            let lhs = z.pow(k as u32) - (0..k).map(|i| r[i] * z.pow(i as u32)).sum::<i64>();
            lhs.rem_euclid(p) != 0 })).unwrap();
    }
    let mul = |u: &Vec<i64>, v: &Vec<i64>| -> Vec<i64> {
        let mut w = vec![0i64; 2 * k - 1];
        for i in 0..k { for j in 0..k { w[i + j] += u[i] * v[j] } }
        for d in (k..2 * k - 1).rev() { for i in 0..k { w[d - k + i] += w[d] * rule[i] } }  // x^d by the rule
        w[..k].iter().map(|c| c.rem_euclid(p)).collect()
    };
    let elems: Vec<Vec<i64>> = (0..size).map(|i| digits(i, p, k)).collect();
    let mut squares: HashMap<Vec<i64>, i64> = HashMap::new();
    for y in &elems { *squares.entry(mul(y, y)).or_insert(0) += 1 }
    1 + elems.iter().map(|x| {
        let mut c = mul(&mul(x, x), x);
        c[0] = (c[0] + B).rem_euclid(p);
        *squares.get(&c).unwrap_or(&0)
    }).sum::<i64>()
}

fn predicted(p: i64, c: i64, d: i64, k: usize) -> i64 {   // p^k + 1 - (alpha^k + beta^k)
    let mut s = vec![2, c];                          // power sums of the roots of 1 - cT + dT^2
    for _ in 0..k - 1 { let n = s.len(); s.push(c * s[n - 1] - d * s[n - 2]) }
    p.pow(k as u32) + 1 - s[k]
}

fn poly(c: i64, d: i128) -> String {
    let mag = if c.abs() != 1 { c.abs().to_string() } else { String::new() };
    let mid = if c != 0 { format!(" {} {}T", if c > 0 { "-" } else { "+" }, mag) } else { String::new() };
    format!("1{}{}", mid, if d != 0 { format!(" + {}T^2", d) } else { String::new() })
}

fn list(v: &[f64], dp: usize) -> String { v.iter().map(|x| format!("{:.*}", dp, x)).collect::<Vec<_>>().join(", ") }

fn ratios(coef: &[i64], n: f64) -> Vec<f64> {      // F(1/(N y)) / (N y^2 F(y)) at two y's
    let f = |y: f64| (1..4000).map(|m| coef[m] as f64 * (-2.0 * std::f64::consts::PI * m as f64 * y).exp()).sum::<f64>();
    [1.1f64, 1.3].iter().map(|&t| f(n.sqrt() / (n * t)) / (t * t * f(t / n.sqrt()))).collect()
}

fn scan(coef: &[i64]) -> Vec<i64> {                 // every 2^i 3^j, i <= 8, j <= 5
    (0..9u32).flat_map(|i| (0..6u32).map(move |j| 2i64.pow(i) * 3i64.pow(j)))
        .filter(|&n| ratios(coef, n as f64).iter().all(|r| (r.abs() - 1.0).abs() < 1e-9)).collect()
}

fn main() {
    let mut sieve: Vec<bool> = (0..X).map(|i| i > 1).collect();
    for i in 2..100 { if sieve[i] { let mut m = i * i; while m < X { sieve[m] = false; m += i } } }
    let ps: Vec<i64> = (0..X).filter(|&i| sieve[i]).map(|i| i as i64).collect();
    let disc = -16 * 27 * B * B;
    let bad: Vec<i64> = ps.iter().copied().filter(|&p| p < 50 && disc % p == 0).collect();
    let mut a: HashMap<i64, i64> = HashMap::new();
    for &p in &ps { a.insert(p, if bad.contains(&p) { 0 } else { p + 1 - count_mod_p(p) }); }
    let v: Vec<u32> = bad.iter().map(|&p| (0..20u32).filter(|&j| disc % p.pow(j) == 0).max().unwrap()).collect();
    println!("curve y^2 = x^3 - 2; discriminant -16(4a^3 + 27b^2) = {} = -2^{} * 3^{}; bad primes {:?}; house point (3, 5) on it: {}",
             disc, v[0], v[1], bad, if 5 * 5 == 27 + B { "yes" } else { "no" });
    let mut at2: Vec<Q> = vec![];
    for p in [2i64, 3, 5, 7] {
        let sing: Vec<(i64, i64)> = (0..p).flat_map(|x| (0..p).map(move |y| (x, y)))
            .filter(|&(x, y)| (y * y - x.pow(3) - B).rem_euclid(p) == 0 && 2 * y % p == 0 && 3 * x * x % p == 0).collect();
        let (c, d) = if sing.is_empty() { (p + 1 - count_mod_p(p), p) } else { (0, 0) };
        let kind = if sing.is_empty() { "smooth".to_string() } else {
            format!("singular at {:?}, {}", sing[0], if 3 * sing[0].0 % p == 0 { "a cusp" } else { "a node" }) };
        let lf = if c != 0 || d != 0 { format!("1/({})", poly(c, d as i128)) } else { "1".to_string() };
        println!("p = {}: {} points over F_{}; {}; a_{} = {}; local factor {}", p, count_mod_p(p), p, kind, p, c, lf);
        let got: Vec<i64> = (1..4).map(|k| count_over_field(p, k)).collect();
        let want: Vec<i64> = (1..4).map(|k| predicted(p, c, d, k)).collect();
        let s: Vec<i128> = (1..4).map(|k| (p.pow(k as u32) + 1 - got[k - 1]) as i128).collect();
        let (e1, e2) = (s[0], q(s[0] * s[0] - s[1], 2));      // Newton's identities: counts -> factor
        let e3 = q(e2.n * s[0] - e1 * s[1] * e2.d + s[2] * e2.d, 3 * e2.d);
        println!("   counted over F_{p}, F_{p}^2, F_{p}^3: {:?}; from the factor: {:?}; rebuilt from counts: {}, T^3 coefficient {}",
                 got, want, poly(e1 as i64, e2.n), show(e3));
        assert!(got == want && e1 == c as i128 && e2 == q(d as i128, 1) && e3 == q(0, 1));
        let p4 = (p as i128).pow(4);
        at2.push(q(p4, p4 - (c * p * p) as i128 + d as i128));   // T = 1/p^2
    }
    let (three, four) = (qmul(qmul(at2[0], at2[1]), at2[2]), qmul(qmul(qmul(at2[0], at2[1]), at2[2]), at2[3]));
    println!("factors at s = 2 for p = 2, 3, 5, 7: {}", at2.iter().map(|&v| show(v)).collect::<Vec<_>>().join(", "));
    println!("first three multiply to {} = {:.6}; first four to {} = {:.6}", show(three),
             three.n as f64 / three.d as f64, show(four), four.n as f64 / four.d as f64);
    let mut an: Vec<i64> = (0..X).map(|i| (i == 1) as i64).collect();   // a_n, multiplicative
    for n in 2..X as i64 {
        let p = *ps.iter().find(|&&q| n % q == 0).unwrap();
        let (mut m, mut k) = (n, 0);
        while m % p == 0 { m /= p; k += 1 }
        let (mut prev, mut cur) = (1i64, a[&p]);     // a_(p^k) = a_p a_(p^(k-1)) - p a_(p^(k-2))
        for _ in 0..k - 1 { let nx = a[&p] * cur - (if bad.contains(&p) { 0 } else { p }) * prev; prev = cur; cur = nx }
        an[n as usize] = an[m as usize] * cur;
    }
    println!("a_1 to a_25: {:?}", &an[1..26]);
    let worst = ps.iter().map(|&p| a[&p].abs() as f64 / (2.0 * (p as f64).sqrt())).fold(0.0, f64::max);
    let hasse = ps.iter().all(|&p| a[&p] * a[&p] <= 4 * p);
    println!("Hasse a_p^2 <= 4p for all {} primes below {}: {}; largest |a_p|/(2 sqrt p) = {:.6}",
             ps.len(), X, if hasse { "yes" } else { "no" }, worst);
    let cp: Vec<i64> = ps.iter().copied().filter(|&p| p <= 61).collect();
    println!("chart primes {:?}", cp);
    println!("chart a_p {:?}", cp.iter().map(|p| a[p]).collect::<Vec<_>>());
    println!("chart 2 sqrt p [{}]", list(&cp.iter().map(|&p| 2.0 * (p as f64).sqrt()).collect::<Vec<_>>(), 2));
    for s in [2i64, 3] {
        let (mut prods, mut sums) = (vec![], vec![]);
        for cut in [100i64, 1000, 10000] {
            let mut pr = 1.0f64;
            for &p in ps.iter().filter(|&&q| q < cut && !bad.contains(&q)) {
                let pf = p as f64;
                pr /= 1.0 - a[&p] as f64 * pf.powf(-s as f64) + pf.powf((1 - 2 * s) as f64);
            }
            prods.push(pr);
            sums.push((1..cut).map(|n| an[n as usize] as f64 * (n as f64).powf(-s as f64)).sum::<f64>());
        }
        println!("s = {}: product over p < 100, 1000, 10000: {}", s, list(&prods, 9));
        println!("s = {}: series over n < 100, 1000, 10000:  {}", s, list(&sums, 9));
        assert!((prods[2] - sums[2]).abs() < if s == 2 { 1e-4 } else { 1e-8 });
    }
    for (sigma, label) in [(1.25f64, "1.25"), (2.0, "2")] {
        let part: Vec<f64> = [100i64, 1000, 10000].iter().map(|&cut| ps.iter().filter(|&&p| p < cut)
            .map(|&p| a[&p].abs() as f64 * (p as f64).powf(-sigma)).sum::<f64>()).collect();
        println!("sum of |a_p| p^-sigma, sigma = {}, p < 100, 1000, 10000: {}", label, list(&part, 4));
    }
    let (passed, w) = (scan(&an), ratios(&an, 1728.0));
    println!("conductor scan, N = 2^i 3^j with i <= 8, j <= 5 (54 tries): symmetry holds only at {:?}; sign w = {:.9}, {:.9}",
             passed, w[0], w[1]);
    assert!(passed == vec![1728] && (w[0] + 1.0).abs() < 1e-9);
    assert!(hasse && a[&7] == 1 && a[&13] == -5);
    let mut wrong = an.clone();                      // mistake 3: 1 + pT^2 at 2 and 3
    for n in 2..X as i64 {
        for &p in &bad {
            let k = (0..20u32).find(|&j| n % p.pow(j + 1) != 0).unwrap();
            if k > 0 { wrong[n as usize] = if k % 2 == 1 { 0 } else { wrong[(n / p.pow(k)) as usize] * (-p).pow(k / 2) }; break }
        }
    }
    let wrong_at2: Vec<String> = bad.iter().map(|&p| { let p4 = (p as i128).pow(4); show(q(p4, p4 + p as i128)) }).collect();
    println!("mistake 1, factor 1 + pT^2 at a bad prime: F_p^2 counts {} at p = 2 (true {}) and {} at p = 3 (true {}); s = 2 factors {}, not {}",
             predicted(2, 0, 2, 2), count_over_field(2, 2), predicted(3, 0, 3, 2), count_over_field(3, 2), wrong_at2.join(" and "), show(at2[0]));
    println!("mistake 2, dropping pT^2 at p = 5: F_25 count {} (true {}); s = 2 factor {}, not {}",
             predicted(5, 0, 0, 2), count_over_field(5, 2), show(q(25, 25 - a[&5] as i128)), show(at2[2]));
    println!("mistake 3, those bad factors in the scan: ratio at N = 1728 is {:.6}, not -1; scan passes {:?}",
             ratios(&wrong, 1728.0)[0], scan(&wrong));
    println!("ALL CHECKS PASS");
}
