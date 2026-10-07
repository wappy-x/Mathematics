// Derangements -- the same check as the Python, in Rust.  No crates.  Six
// colleagues draw names for Secret Santa, and a draw is good when nobody draws
// their own name.  Three roads that share no arithmetic count the good draws:
// listing, the alternating sieve, and the recurrence.  Their share of all draws
// is then set against 1/e, reached twice.
const TOP: usize = 8;

fn factorial(n: usize) -> i64 {        // n! = 1 x 2 x ... x n, with 0! = 1
    let mut out: i64 = 1;
    for i in 2..=n as i64 { out *= i }
    out
}

fn every_draw(n: usize) -> Vec<Vec<usize>> {   // every way to hand out n names, in order
    let mut draws: Vec<Vec<usize>> = vec![vec![]];
    for k in 0..n {
        let mut next: Vec<Vec<usize>> = Vec::new();
        for p in &draws {
            for i in 0..=k { let mut q = p.clone(); q.insert(i, k); next.push(q) }
        }
        draws = next;
    }
    draws
}

fn sieve_terms(n: usize) -> Vec<i64> {  // road two: the alternating sieve, in whole numbers
    (0..=n).map(|k| { let t = factorial(n) / factorial(k); if k % 2 == 0 { t } else { -t } }).collect()
}

fn row(name: &str, values: &[i64]) {
    let mut line = format!("{:<19}", name);
    for v in values { line.push_str(&format!("{:>6}", v)) }
    println!("{}", line);
}

fn main() {
    let listed: Vec<i64> = (0..=TOP).map(|n|                 // road one: deal them all, keep the good ones
        every_draw(n).iter().filter(|p| (0..n).all(|i| p[i] != i)).count() as i64).collect();
    let sieved: Vec<i64> = (0..=TOP).map(|n| sieve_terms(n).iter().sum()).collect();
    let mut recurred: Vec<i64> = vec![1, 0];  // road three: D(n) = (n-1) x (D(n-1) + D(n-2))
    for n in 2..=TOP { recurred.push((n as i64 - 1) * (recurred[n - 1] + recurred[n - 2])) }
    let facts: Vec<i64> = (0..=TOP).map(factorial).collect();
    let share: Vec<f64> = (1..=TOP).map(|n| listed[n] as f64 / facts[n] as f64).collect();
    let mut alt = 0.0;                                       // road one to 1/e
    for k in 0..21 { alt += (if k % 2 == 0 { 1.0 } else { -1.0 }) / factorial(k) as f64 }
    let compounded = (1.0 + 1e-7f64).powf(1e7);              // road two: a dollar, 10^7 times
    let terms = sieve_terms(6);
    let mut flat = format!("{}", terms[0]);
    for t in &terms[1..] { flat.push_str(&format!(" {} {}", if *t < 0 { "-" } else { "+" }, t.abs())) }
    let running: Vec<String> = (0..7).map(|k| terms[..=k].iter().sum::<i64>().to_string()).collect();
    println!("Secret Santa, 6 colleagues: {} draws in all, {} with nobody drawing their own name", facts[6], listed[6]);
    row("n", &(0..=TOP as i64).collect::<Vec<i64>>());
    row("n!, all draws", &facts);
    row("D(n) by listing", &listed);
    row("D(n) by the sieve", &sieved);
    row("D(n) by recurrence", &recurred);
    println!("D(n)/n!, n = 1 to 8: {}", share.iter().map(|s| format!("{:.4}", s)).collect::<Vec<String>>().join(" "));
    println!("sieve at n = 6: {} = {}", flat, sieved[6]);
    println!("pairs at n = 6: C(6,2) = {}, each leaving 4! = {} draws, so the k = 2 term is {}",
             facts[6] / (facts[2] * facts[4]), facts[4], terms[2]);
    println!("sieve running totals at n = 6: {}", running.join(", "));
    println!("recurrence at n = 6: 5 x ({} + {}) = 5 x {} = {}", listed[5], listed[4], listed[5] + listed[4], recurred[6]);
    println!("one-step form at n = 6: 6 x {} + 1 = {}", listed[5], 6 * listed[5] + 1);
    println!("1/e by the alternating sum to 20 terms: {:.6}; by compounding a dollar 10000000 times: {:.6}", alt, 1.0 / compounded);
    println!("720 x (1/e) = {:.3}, nearest whole number {}", facts[6] as f64 * alt, (facts[6] as f64 * alt + 0.5) as i64);
    println!("e by the same compounding: {:.6}; the 7th and 8th terms of the share: {:.6} and {:.6}",
             compounded, 1.0 / facts[7] as f64, 1.0 / facts[8] as f64);
    println!("names put back after each draw, own name barred: 5^6 = {} lists, not {} draws", 5i64.pow(6), listed[6]);
    println!("mistake 1, subtract the six own-name blocks and stop: 720 - 6 x 120 = {}; mistake 2, drop the sieve's last term: {}; mistake 3, recurrence read as 5 x 44 + 9: {}",
             facts[6] - 6 * facts[5], sieved[6] - terms[6], 5 * listed[5] + listed[4]);
    assert!(listed == sieved);                               // listing against the sieve
    assert!(listed == recurred);                             // listing against the recurrence
    assert!(listed[..7] == [1, 0, 1, 2, 9, 44, 265]);        // against the counts worked by hand
    assert!((alt - 1.0 / compounded).abs() < 1e-6);          // two roads to 1/e
    println!("ALL CHECKS PASS");
}
