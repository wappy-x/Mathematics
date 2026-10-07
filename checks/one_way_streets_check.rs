// One-way streets -- the same check as the Python twin, in Rust.  No crates.
// Two easy jobs: 1,009 x 1,013 on paper, and 11 raised to the 613 on a clock
// of 1,009.  Then both jobs backwards, counting what the way back costs.
const A: i64 = 1009;
const B: i64 = 1013;
const BASE: i64 = 11;
const SECRET: i64 = 613;
const CLOCK: i64 = 1009;
fn row(name: &str, value: i64) { println!("{:<40}{:>9}", name, value); }
fn main() {
    let n = A * B;
    row("1,009 x 1,013, the easy way", n);
    row("digit by digit, that is 4 x 4", 4 * 4);
    let primes: Vec<i64> = (2..1011).filter(|&i| (2..i).all(|d| i % d != 0)).collect();  // up to the square root of n
    let tries = primes.iter().position(|&p| n % p == 0).unwrap();                        // trial division, the slow road back
    row("primes tried before 1,009 turns up", tries as i64);
    row("the check, going back: 1022117 / 1009", n / primes[tries]);
    let (mut fast, mut steps) = (1i64, 0i64);
    let top = 63 - (SECRET as u64).leading_zeros() as i64;
    for i in (0..=top).rev() {                      // square and multiply; the first squaring, of 1, is free
        fast = fast * fast % CLOCK; steps += 1;
        if (SECRET >> i) & 1 == 1 { fast = fast * BASE % CLOCK; steps += 1; }
    }
    let (mut slow, mut back) = (1i64, 0i64);
    while slow != fast { slow = slow * BASE % CLOCK; back += 1; }   // walking, one multiply at a time
    row("11 to the 613 on a clock of 1,009", fast);
    row("squarings and multiplies that took", steps);
    row("walking one multiply at a time, steps", back);
    let inv = (0..CLOCK).find(|k| BASE * k % CLOCK == 1).unwrap();
    let stop100 = primes.iter().filter(|&&p| p < 100 && n % p == 0).count();   // trial division stopped at 100
    println!("the three mistakes come out at {}, {} and {}", stop100, 4 * 4, fast * inv % CLOCK);
    assert!(n == 1022117 && primes[tries] == A && n / primes[tries] == B);
    assert!(tries == 168 && primes[..tries].iter().all(|p| n % p != 0) && inv == 367 && stop100 == 0);
    assert!(fast == 956 && slow == fast && back == SECRET && fast * inv % CLOCK == 729);
    println!("ALL CHECKS PASS");
}
