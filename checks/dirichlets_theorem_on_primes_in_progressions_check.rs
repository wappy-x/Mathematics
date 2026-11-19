// Dirichlet's theorem for primes 3 mod 4 -- the same check as the Python, in Rust.  No crates.
// Road 1 counts primes with a sieve, and again by trial division.  Road 2 computes the two
// L-functions mod 4 from their series over all whole numbers, using no primes, and tests the
// identity that ties them to the primes 3 mod 4.  Road 3 is the Euler product of L(1, chi4).
const X: usize = 1_000_000;

fn sieve(m: usize) -> Vec<bool> {                // Eratosthenes: flag[n] is true when n is prime
    let mut flag = vec![true; m + 1];
    flag[0] = false; flag[1] = false;
    let mut p = 2;
    while p * p <= m {
        if flag[p] { let mut q = p * p; while q <= m { flag[q] = false; q += p } }
        p += 1;
    }
    flag
}
fn is_prime(n: usize) -> bool {                  // trial division, the second road to primality
    if n < 2 { return false }
    let mut d = 2;
    while d * d <= n { if n % d == 0 { return false } d += 1 }
    true
}
fn factor(mut n: usize) -> Vec<usize> {          // prime factors by trial division
    let (mut out, mut d) = (Vec::new(), 2);
    while d * d <= n { while n % d == 0 { out.push(d); n /= d } d += 1 }
    if n > 1 { out.push(n) }
    out
}
fn alt(term: &dyn Fn(usize, f64) -> f64, s: f64) -> f64 {   // alternating series: partial sums,
    let (n, m) = (2000, 20);                                 // then average neighbours m times
    let (mut sums, mut tot) = (Vec::new(), 0.0);
    for k in 0..n {
        let sign = if k % 2 == 0 { 1.0 } else { -1.0 };
        tot += sign * term(k, s); sums.push(tot);
    }
    let mut w: Vec<f64> = sums[n - m - 1..].to_vec();
    for _ in 0..m { w = (0..w.len() - 1).map(|i| (w[i] + w[i + 1]) / 2.0).collect() }
    w[0]
}
fn l4(s: f64) -> f64 { alt(&|k, s| ((2 * k + 1) as f64).powf(-s), s) }   // 1 - 1/3^s + 1/5^s - ...
fn l0(s: f64) -> f64 {                           // sum over odd n = (1 - 2^-s) zeta(s),
    let eta = alt(&|k, s| ((k + 1) as f64).powf(-s), s);     // with zeta from the eta series
    (1.0 - 2f64.powf(-s)) * eta / (1.0 - 2f64.powf(1.0 - s))
}
fn f6(v: f64) -> String { format!("{:.6}", v) }
fn list(v: &[f64]) -> String { format!("[{}]", v.iter().map(|x| format!("{:.2}", x)).collect::<Vec<_>>().join(", ")) }

fn main() {
    let flag = sieve(X);
    let primes: Vec<usize> = (2..=X).filter(|&n| flag[n]).collect();
    let three: Vec<usize> = primes.iter().copied().filter(|p| p % 4 == 3).collect();
    println!("first primes 3 mod 4: {:?}", &three[..10]);
    let (e, f) = (4 * 3 * 7 * 11 - 1, 4 * 5 * 13 * 17 - 1);
    let (fe, ff) = (factor(e), factor(f));
    println!("Euclid's trick: 4 x 3 x 7 x 11 - 1 = {} = {:?}; new prime 3 mod 4: {}", e, fe, fe[fe.len() - 1]);
    println!("same trick for 1 mod 4: 4 x 5 x 13 x 17 - 1 = {} = {:?}; each is 3 mod 4: {}", f, ff,
             if ff.iter().all(|p| p % 4 == 3) { "yes" } else { "no" });
    let (mut cnt, mut tot) = ([0usize; 4], [0.0f64; 4]);
    let mut rows: Vec<(usize, usize, usize, f64, f64)> = Vec::new();
    let mut marks: Vec<usize> = (1..7).map(|k| 10usize.pow(k)).collect();
    let mut lead: Option<(usize, usize, usize)> = None;
    let mut walk = primes.clone(); walk.push(X + 1);  // X + 1 only closes the last row
    for &p in &walk {
        while !marks.is_empty() && p > marks[0] { rows.push((marks.remove(0), cnt[1], cnt[3], tot[1], tot[3])) }
        if p % 2 == 1 && p <= X {
            cnt[p % 4] += 1; tot[p % 4] += 1.0 / p as f64;
            if lead.is_none() && cnt[1] > cnt[3] { lead = Some((p, cnt[1], cnt[3])) }
        }
    }
    println!("x | primes 1 mod 4 | primes 3 mod 4 | share 3 mod 4 | sum 1/p, 1 mod 4 | sum 1/p, 3 mod 4 | difference = sum chi4(p)/p | (1/2) log log x");
    for &(x, a, b, t1, t3) in &rows {
        println!("10^{} | {} | {} | {:.4} | {} | {} | {} | {}", x.to_string().len() - 1, a, b, b as f64 / (a + b) as f64,
                 f6(t1), f6(t3), f6(t1 - t3), f6(0.5 * (x as f64).ln().ln()));
    }
    println!("chart, sum 1/p over p 3 mod 4: {}", list(&rows.iter().map(|r| r.4).collect::<Vec<_>>()));
    println!("chart, sum 1/p over p 1 mod 4: {}", list(&rows.iter().map(|r| r.3).collect::<Vec<_>>()));
    println!("chart, sum chi4(p)/p: {}", list(&rows.iter().map(|r| r.3 - r.4).collect::<Vec<_>>()));
    let trial = (3..10_000).step_by(4).filter(|&n| is_prime(n)).count();
    println!("primes 3 mod 4 below 10^4: sieve {}, trial division {}", rows[3].2, trial);
    let lead = lead.unwrap();
    println!("first prime where 1 mod 4 leads: {} (counts {} to {})", lead.0, lead.1, lead.2);
    let digits: Vec<String> = [1, 3, 7, 9].iter().map(|&d| {
        let v = primes.iter().filter(|&&p| p % 10 == d).count();
        format!("{}: {} ({:.4})", d, v, v as f64 / (primes.len() - 2) as f64) }).collect();
    println!("primes below 10^6: {}; by last digit (2 and 5 aside): {}", primes.len(), digits.join(", "));
    let mut euler = 1.0f64;
    for &p in &primes { if p % 2 == 1 { euler /= 1.0 - (if p % 4 == 1 { 1.0 } else { -1.0 }) / p as f64 } }
    println!("L(1, chi4): series {:.12}; Euler product to 10^6 {:.12}; pi/4 cross-check {:.12}; floor 1 - 1/3 = {}",
             l4(1.0), euler, std::f64::consts::PI / 4.0, f6(2.0 / 3.0));
    println!("s | L(s, chi0) | L(s, chi4) | (1/2) log(L0/L4) | (1/2) log(L0 L4) | log(1/(s-1)) | 3 mod 4 share");
    let mut table: Vec<(f64, f64, f64, f64, f64, f64)> = Vec::new();
    for label in ["2", "1.1", "1.01", "1.001"] {
        let s: f64 = label.parse().unwrap(); let (a, b) = (l0(s), l4(s));
        let (g3, g1, big) = (0.5 * (a / b).ln(), 0.5 * (a * b).ln(), (1.0 / (s - 1.0)).ln());
        table.push((s, a, b, g3, g1, big));
        let share = if big == 0.0 { "-".to_string() } else { format!("{:.4}", g3 / big) };
        println!("{} | {} | {} | {} | {} | {} | {}", label, f6(a), f6(b), f6(g3), f6(g1), f6(big), share);
    }
    let side: f64 = three.iter().map(|&p| (p as f64).powf(-2.0).atanh()).sum();
    println!("s = 2: (1/2) log(L0/L4) = {:.9}; sum of artanh(p^-2) over p 3 mod 4 to 10^6 = {:.9}; gap {:.9}",
             table[0].3, side, table[0].3 - side);
    let fake = 0.5 * (table[3].1.ln() + ((1.001 - 1.0) * table[3].2).ln());
    println!("mistake 1, class 2 mod 4 (shares 2 with the step): {} prime; class 0 mod 4: {} primes",
             primes.iter().filter(|&&p| p % 4 == 2).count(), primes.iter().filter(|&&p| p % 4 == 0).count());
    println!("mistake 2, sharing over all 4 classes: 78498 / 4 = {:.1}, true count {}", primes.len() as f64 / 4.0, rows[5].2);
    println!("mistake 3, equal share read as equal counts: 3 mod 4 leads by {} at 10^6", rows[5].2 - rows[5].1);
    println!("mistake 4, a zero at s = 1: (1/2) log(L0 x (s-1) L4) at s = 1.001 is {}, no longer growing", f6(fake));
    assert!(trial == rows[3].2);                                     // sieve against trial division
    assert!((euler - l4(1.0)).abs() < 1e-3 && (l4(1.0) - std::f64::consts::PI / 4.0).abs() < 1e-10);
    assert!((table[0].3 - side).abs() < 2e-6);                       // primes against whole-number series
    assert!(table.iter().all(|r| r.2 >= 2.0 / 3.0) && table.windows(2).all(|w| w[0].3 <= w[1].3));
    assert!(rows.iter().all(|r| (r.3 - r.4).abs() < 0.5) && lead.0 == 26861);   // bounded; Leech 1957
    assert!(fe == vec![13, 71] && fe[fe.len() - 1] % 4 == 3 && primes.len() == 78498);   // pi(10^6) table
    println!("ALL CHECKS PASS");
}
