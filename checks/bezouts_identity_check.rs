// Bezout's identity -- the same check as the Python twin, in Rust.  No crates.
// Two jugs, 21 and 15 litres.  Road one: Euclid's chain, walked backwards, to
// write 3 as a mix of 21 and 15.  Road two: try every small mix and look.
const A: i64 = 21;
const B: i64 = 15;

fn listing_gcd(a: i64, b: i64) -> i64 {   // independent of Euclid: list the divisors
    (1..=a.min(b)).filter(|d| a % d == 0 && b % d == 0).max().unwrap()
}

fn main() {
    let (mut a, mut b) = (A, B);
    let mut chain: Vec<(i64, i64, i64, i64)> = Vec::new();
    while b != 0 { let t = a % b; chain.push((a, a / b, b, t)); a = b; b = t; }
    let g = a;
    println!("{:<38}{:>4}", "gcd(21, 15) by Euclid", g);
    for &(u, q, v, r) in &chain { println!("{} = {} x {} + {}", u, q, v, r); }
    let n = chain.len();
    let (mut p, mut s) = (1, -chain[n - 2].1);   // the last useful line: 3 = 15 - 2 x 6
    for &(_, q, _, _) in chain[..n - 2].iter().rev() { let (np, ns) = (s, p - s * q); p = np; s = ns; }
    println!("Bezout: 21 x {} + 15 x {} = {} + {} = {}", p, s, A * p, B * s, A * p + B * s);
    let (p2, s2) = (p + B / g, s - A / g);       // slide along by one whole step
    println!("one step along (21 x {} = 15 x {} = {}): 21 x {} + 15 x {} = {} + {} = {}", B / g, A / g, A * (B / g), p2, s2, A * p2, B * s2, A * p2 + B * s2);
    let mut mixes: Vec<i64> = Vec::new();
    for i in -9..=9 { for j in -9..=9 { mixes.push(A * i + B * j); } }
    let best = *mixes.iter().filter(|&&m| m > 0).min().unwrap();
    let hits = mixes.iter().filter(|&&m| m == 1 || m == 2).count();
    println!("{:<38}{:>4}", "smallest mix above zero, by search", best);
    println!("{:<38}{:>4}", "mixes that land on 1 or 2 litres", hits);
    println!("the three mistakes come out at {}, {} and {}", A * 2 + B * 3, B - 2 * A, A * 3 - B * 2);
    assert!(g == 3 && g == listing_gcd(A, B));
    assert!(p == -2 && s == 3 && A * p + B * s == g && A * p2 + B * s2 == g);
    assert!(best == g && !mixes.contains(&1) && !mixes.contains(&2));
    println!("ALL CHECKS PASS");
}
