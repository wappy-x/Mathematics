// Counting divisors -- the same check as counting_divisors_check.py, in Rust.
// No crates.  A box of 96 tiles: 96 = 2 x 2 x 2 x 2 x 2 x 3.  The count is read
// off that prime factorisation, then checked by trying every number up to 96.
fn primes_of(mut n: i64) -> Vec<i64> {          // 96 -> [2, 2, 2, 2, 2, 3]
    let (mut out, mut d) = (Vec::new(), 2);
    while d * d <= n {
        while n % d == 0 { out.push(d); n /= d; }
        d += 1;
    }
    if n > 1 { out.push(n); } out
}
fn by_formula(n: i64) -> i64 {                  // one more than each prime's count, multiplied
    let (ps, mut total) = (primes_of(n), 1);
    for (i, p) in ps.iter().enumerate() {
        if i == 0 || *p != ps[i - 1] { total *= ps.iter().filter(|q| *q == p).count() as i64 + 1; }
    }
    total
}
fn by_hand(n: i64) -> Vec<i64> { (1..=n).filter(|d| n % d == 0).collect() }   // the slow road
fn list(v: Vec<i64>) -> String { v.iter().map(|d| d.to_string()).collect::<Vec<_>>().join(", ") }
fn row(name: &str, value: i64) { println!("{:<44}{:>4}", name, value); }
fn main() {
    println!("96 = {}", list(primes_of(96)).replace(", ", " x "));
    row("(5 + 1) x (1 + 1)", by_formula(96));
    row("divisors of 96, the slow way", by_hand(96).len() as i64);
    println!("divisors of 96: {}", list(by_hand(96)));
    println!("the grid, no 3:  {}", list(by_hand(96).into_iter().filter(|d| d % 3 != 0).collect()));
    println!("the grid, one 3: {}", list(by_hand(96).into_iter().filter(|d| d % 3 == 0).collect()));
    row("rectangle shapes, 12 / 2", by_formula(96) / 2);
    row("360 = 2 x 2 x 2 x 3 x 3 x 5, (3 + 1) x (2 + 1) x (1 + 1)", by_formula(360));
    row("divisors of 360, the slow way", by_hand(360).len() as i64);
    row("sum of the divisors of 96, 63 x 4", by_hand(96).iter().sum::<i64>());
    println!("the three mistakes come out at {}, {} and {}", 5, (5 + 1) + (1 + 1), by_formula(96) - 2);
    assert!(by_formula(96) == 12 && by_hand(96).len() == 12 && *by_hand(96).last().unwrap() == 96);
    let mut grid: Vec<i64> = by_hand(96).into_iter().filter(|d| d % 3 != 0)
        .chain(by_hand(96).into_iter().filter(|d| d % 3 == 0)).collect();
    grid.sort(); assert!(grid == by_hand(96));
    assert!(by_formula(360) == 24 && by_hand(360).len() == 24 && by_hand(96).iter().sum::<i64>() == 63 * 4);
    println!("ALL CHECKS PASS");
}
