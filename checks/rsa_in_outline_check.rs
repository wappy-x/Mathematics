// RSA in outline -- the same check as the Python twin, in Rust.  No crates.  Two secret
// primes, 61 and 53, make the public clock size 3233.  The message 65 locks with the
// public exponent 17 and unlocks with the private one, 2753.
const P: u64 = 61;
const Q: u64 = 53;
const E: u64 = 17;
const MSG: u64 = 65;
fn power(mut base: u64, mut times: u64, clock: u64) -> u64 {   // square and multiply
    let mut out = 1;
    while times != 0 {
        if times & 1 == 1 { out = out * base % clock; }
        base = base * base % clock;
        times >>= 1;
    }
    out
}
fn row(name: &str, value: u64) { println!("{:<42}{:>6}", name, value); }
fn main() {
    let (n, phi) = (P * Q, (P - 1) * (Q - 1));
    let count = (1..=n).filter(|k| k % P != 0 && k % Q != 0).count() as u64;  // one at a time
    let d = (1..phi).find(|k| E * k % phi == 1).unwrap();      // by search, not by Euclid
    let mut slow = 1;
    for _ in 0..E { slow = slow * MSG % n; }                   // the plain way: 1 times 65, 17 times
    let c = power(MSG, E, n);
    row("clock size, 61 x 53", n);
    row("how many share no factor, 60 x 52", phi);
    row("private exponent, 17 undone on 3120", d);
    println!("17 x {} = {} = {} x {} + {}", d, E * d, E * d / phi, phi, E * d % phi);
    row("lock: 65 to the 17th, 3233s off", c);
    row("unlock: 2790 to the 2753rd, 3233s off", power(c, d, n));
    row("65 to the 3120th, 3233s off", power(MSG, phi, n));
    row("65 to the 46801st, 3233s off", power(MSG, E * d, n));
    let bad = (1..n).find(|k| E * k % n == 1).unwrap();        // a d built on 3233, not 3120
    println!("unlocked with 17: {}; with a d built on {}: {}; {} comes back as {}", power(c, E, n), n,
             power(c, bad, n), MSG + n, power(power(MSG + n, E, n), d, n));
    assert!(n == 3233 && phi == count && count == 3120 && n - P - Q + 1 == phi);
    assert!(d == 2753 && E * d == 15 * phi + 1 && c == slow && slow == 2790);
    assert!(power(c, d, n) == MSG && power(MSG, phi, n) == 1);
    println!("ALL CHECKS PASS");
}
