// Finite differences and telescoping sums -- the same check as the Python, in
// Rust.  No crates.  A supermarket stacks tins in rows of 1, 2, 3, ...: the
// running totals are 1, 3, 6, 10, 15.  Every count is reached twice, once by
// adding term by term and once by a closed form or a telescope collapsed to
// its two ends.
const ROWS: i64 = 10;
const TERMS: i64 = 99;

fn diffs(seq: &[i64]) -> Vec<i64> {                 // one pass of jumps: a(n+1) - a(n)
    (1..seq.len()).map(|i| seq[i] - seq[i - 1]).collect()
}

fn choose(n: i64, k: i64) -> i64 {                  // n choose k, multiplied out
    let mut out = 1;
    for i in 0..k { out = out * (n - i) / (i + 1) }
    out
}

fn gcd(mut a: i64, mut b: i64) -> i64 {
    while b != 0 { (a, b) = (b, a % b) }
    a
}

fn add_fraction(n1: i64, d1: i64, n2: i64, d2: i64) -> (i64, i64) {   // exact, reduced
    let (n, d) = (n1 * d2 + n2 * d1, d1 * d2);
    let g = gcd(n, d);
    (n / g, d / g)
}

fn row(name: &str, values: &[String]) { println!("{:<46}{}", name, values.join(" ")) }

fn strs(values: &[i64]) -> Vec<String> { values.iter().map(|v| v.to_string()).collect() }

fn main() {
    let (mut totals, mut running) = (Vec::new(), 0);  // road one: add the rows one at a time
    for n in 1..=ROWS { running += n; totals.push(running) }
    let (first, second) = (diffs(&totals), diffs(&diffs(&totals)));
    let closed: Vec<i64> = (1..=ROWS).map(|n| n * (n + 1) / 2).collect();          // road two
    let newton: Vec<i64> = (1..=ROWS).map(|n| 1 + 2 * choose(n - 1, 1) + choose(n - 1, 2)).collect();
    let (mut exact, mut wrong) = ((0i64, 1i64), 0.0f64);   // road one to the fraction sum
    for k in 1..=TERMS {
        exact = add_fraction(exact.0, exact.1, 1, k * (k + 1));
        wrong += 1.0 / k as f64 + 1.0 / (k + 1) as f64;    // the same split, with a plus
    }
    let tele = (TERMS, TERMS + 1);                 // road two: 1 - 1/100, collapsed to two ends
    let mut fib = vec![1i64, 1];
    while fib.len() < 11 { fib.push(fib[fib.len() - 1] + fib[fib.len() - 2]) }
    let added: i64 = fib[..9].iter().sum();
    let jumps: i64 = first.iter().sum();
    row("tins in rows 1 to 10", &strs(&(1..=ROWS).collect::<Vec<i64>>()));
    row("running totals, added row by row", &strs(&totals));
    row("first differences", &strs(&first));
    row("second differences", &strs(&second));
    row("the same totals from n(n+1)/2", &strs(&closed));
    row("the same totals from Newton's formula", &strs(&newton));
    println!("Newton at n = 5: 1 + 2*C(4,1) + C(4,2) = 1 + {} + {} = {}", 2 * choose(4, 1), choose(4, 2), newton[4]);
    println!("ten rows: {} tins by adding, {} from n(n+1)/2", totals[9], closed[9]);
    println!("the jumps add to the trip: 2+3+...+{} = {} = {} - {}", ROWS, jumps, totals[9], totals[0]);
    row("the first three terms as differences",
        &(1..4).map(|k| format!("1/{}-1/{}", k, k + 1)).collect::<Vec<String>>());
    println!("1/(k(k+1)) added exactly to k = {}: {}/{} = {:.2}",
             TERMS, exact.0, exact.1, exact.0 as f64 / exact.1 as f64);
    println!("the same sum, telescoped: 1 - 1/{} = {}/{} = {:.2}",
             TERMS + 1, tele.0, tele.1, tele.0 as f64 / tele.1 as f64);
    row("Fibonacci F(1) to F(11), the hallway count", &strs(&fib));
    println!("F(1)+...+F(9) added: {}; telescoped F(11) - F(2) = {} - {} = {}",
             added, fib[10], fib[1], fib[10] - fib[1]);
    println!("mistake 1, second difference 1 read as the rule n^2: 5 rows -> {}, not {}", 5 * 5, closed[4]);
    println!("mistake 2, the collapse stopped at a(n): {}, not {}", ROWS * (ROWS - 1) / 2, totals[9]);
    println!("mistake 3, the split written with a plus: {:.2}, not {:.2}",
             wrong, exact.0 as f64 / exact.1 as f64);
    assert!(first == (2..=ROWS).collect::<Vec<i64>>() && second == vec![1; (ROWS - 2) as usize]);
    assert!(totals == closed && closed == newton);
    assert!(jumps == totals[9] - totals[0] && exact == tele);
    assert!(added == fib[10] - fib[1] && fib[10] == 89);
    println!("ALL CHECKS PASS");
}
