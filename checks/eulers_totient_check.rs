// Euler's totient -- the same check as the Python twin, in Rust.  No crates.  The musical clock:
// 12 semitones to an octave.  Road one walks each jump size round the N notes; road two reads
// phi(N) off the primes.  Same labels, same numbers.
const N: i64 = 12;
fn gcd(a: i64, b: i64) -> i64 { if b == 0 { a } else { gcd(b, a % b) } }
fn walk(jump: i64, n: i64) -> Vec<i64> {        // the notes one jump size actually visits
    let (mut seen, mut k) = (Vec::new(), 0i64);
    while !seen.contains(&k) { seen.push(k); k = (k + jump) % n; }
    seen
}
fn primes_of(n: i64) -> Vec<i64> { (2..=n).filter(|&p| n % p == 0 && (2..p).all(|q| p % q != 0)).collect() }
fn by_counting(n: i64) -> i64 { (1..=n).filter(|&k| gcd(k, n) == 1).count() as i64 }   // the definition
fn cull(n: i64, ps: &[i64]) -> i64 {            // start at n; for each p on the list, throw away one in every p
    let mut out = n;
    for &p in ps { out = out / p * (p - 1); }
    out
}
fn by_primes(n: i64) -> i64 { cull(n, &primes_of(n)) }      // one bracket per distinct prime -- the formula
fn show(v: &[i64]) -> String {                  // "[1, 5, 7, 11]", the way Python prints a list
    format!("[{}]", v.iter().map(|x| x.to_string()).collect::<Vec<String>>().join(", "))
}
fn main() {
    let tours: Vec<i64> = (1..=N).filter(|&j| walk(j, N).len() as i64 == N).collect();
    let coprime: Vec<i64> = (1..=N).filter(|&k| gcd(k, N) == 1).collect();
    let same = (1..=60i64).filter(|&n| by_counting(n) == by_primes(n)).count();
    let brackets = primes_of(N).iter().map(|p| format!("(1 - 1/{})", p)).collect::<Vec<String>>().join(" x ");
    let (per_copy, stop_early) = (cull(N, &[2, 2, 3]), cull(N, &[2]));   // the same culling, run wrong
    println!("jump by 7 from C: {}, back to 0", walk(7, N).iter().map(|k| k.to_string()).collect::<Vec<String>>().join(" "));
    println!("notes visited, jumps 1 to {}: {}", N, (1..=N).map(|j| walk(j, N).len().to_string()).collect::<Vec<String>>().join(" "));
    println!("{:<41}{:>14}", format!("jumps that tour all {} notes", N), show(&tours));
    println!("{:<41}{:>14}", format!("numbers 1 to {} sharing no factor with {}", N, N), show(&coprime));
    println!("phi({}) by counting the survivors: {};  by the primes, {} x {}: {}", N, by_counting(N), N, brackets, by_primes(N));
    println!("by coprime parts: phi(4) x phi(3) = {} x {} = {};  a prime clock: phi(7) = 7 - 1 = {}", by_primes(4), by_primes(3), by_primes(4) * by_primes(3), by_primes(7));
    println!("the two roads agree for {} of the 60 clock sizes from 1 to 60", same);
    println!("the three mistakes come out at {}, {} and {}", N - 1, per_copy, stop_early);
    assert!(coprime == vec![1, 5, 7, 11] && tours == coprime && by_counting(N) == 4);
    assert!(by_primes(N) == 4 && by_primes(4) * by_primes(3) == 4 && by_primes(7) == 6);
    assert!(same == 60 && by_counting(1) == 1 && (N - 1, per_copy, stop_early) == (11, 2, 6));
    println!("ALL CHECKS PASS");
}
