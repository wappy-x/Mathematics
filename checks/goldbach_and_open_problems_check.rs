// Goldbach and twin primes -- the same check as goldbach_and_open_problems_check.py,
// in Rust.  No crates.  Two roads to the same counts: a sieve of Eratosthenes to
// 200, and trial division.  House numbers 4, 98, 100, 102, and the twins 101 and 103.
fn by_division(n: usize) -> bool {   // road two: hunt for a divisor, up to the square root
    let mut d = 2;
    while d * d <= n && n % d != 0 { d += 1; }
    d * d > n
}
fn pairs(n: usize, is_prime: &dyn Fn(usize) -> bool) -> Vec<(usize, usize)> {
    (2..=n / 2).filter(|&p| is_prime(p) && is_prime(n - p)).map(|p| (p, n - p)).collect()
}
fn main() {
    let mut flag = [true; 201];      // road one: the sieve.  flag[m] means "m is prime"
    flag[0] = false;
    flag[1] = false;
    for p in 2..15 {
        if flag[p] { let mut k = p * p; while k <= 200 { flag[k] = false; k += p; } }
    }
    let by_sieve = |m: usize| flag[m];
    let six = pairs(100, &by_sieve);
    for (p, q) in &six { println!("100 = {} + {}", p, q); }
    let counts: Vec<usize> = [4, 98, 100, 102].iter().map(|&n| pairs(n, &by_sieve).len()).collect();
    let checked: Vec<usize> = [4, 98, 100, 102].iter().map(|&n| pairs(n, &by_division).len()).collect();
    let twins: Vec<(usize, usize)> = (101..199).filter(|&a| flag[a] && flag[a + 2]).map(|a| (a, a + 2)).collect();
    println!("ways to write it as two primes: 4 has {}, 98 has {}, 100 has {}, 102 has {}",
             counts[0], counts[1], counts[2], counts[3]);
    println!("{}", if counts == checked { "the sieve and trial division agree on all four counts" }
                   else { "the two roads disagree" });
    println!("twin primes just above 100: {} and {}", twins[0].0, twins[0].1);
    println!("Goldbach checked to 4,000,000,000,000,000,000 by computer (published, not checked here)");
    println!("the three mistakes come out at {} ordered pairs, {} ways for 11, {} for 2",
             2 * six.len(), pairs(11, &by_sieve).len(), pairs(2, &by_sieve).len());
    assert!(six == vec![(3, 97), (11, 89), (17, 83), (29, 71), (41, 59), (47, 53)]);
    assert!(counts == vec![1, 3, 6, 8] && checked == vec![1, 3, 6, 8] && (2..201).all(|m| flag[m] == by_division(m)));
    assert!(twins[0] == (101, 103) && by_division(101) && by_division(103));
    println!("ALL CHECKS PASS");
}
