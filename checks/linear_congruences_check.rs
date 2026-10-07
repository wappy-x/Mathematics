// Solving 6x = 4 (mod 10) -- the same check as the Python twin, in Rust.  No
// crates.  A 10-position dial, 6 places per click.  Road one: try all ten step
// counts.  Road two: the gcd rule -- shrink the clock, undo the step, unfold.
const A: i64 = 6;
const B: i64 = 4;
const N: i64 = 10;

fn plain_gcd(a: i64, b: i64) -> i64 {            // list the divisors; no algorithm assumed
    (1..=a.min(b)).filter(|d| a % d == 0 && b % d == 0).max().unwrap()
}

fn brute(a: i64, b: i64, n: i64) -> Vec<i64> {   // road one: every step count on the dial
    (0..n).filter(|x| (a * x) % n == b % n).collect()
}

fn show(v: &[i64]) -> String {                   // "[4, 9]", the way Python prints a list
    format!("[{}]", v.iter().map(|x| x.to_string()).collect::<Vec<String>>().join(", "))
}

fn main() {
    let g = plain_gcd(A, N);
    let orbit: Vec<String> = (0..N).map(|x| ((A * x) % N).to_string()).collect();
    println!("where the dial sits after 0..{} clicks: {}", N - 1, orbit.join(" "));
    println!("{:<34}{:>4}", format!("gcd({}, {})", A, N), g);
    println!("{:<34}{:>8}", "answers by trying every click", show(&brute(A, B, N)));
    let (a2, b2, n2) = (A / g, B / g, N / g);    // road two: shrink the whole line by 2
    let inv = (0..n2).find(|t| (a2 * t) % n2 == 1).unwrap();
    let first = (inv * b2) % n2;
    let found: Vec<i64> = (0..g).map(|k| first + n2 * k).collect();
    println!("shrunk to {}x = {} (mod {}); undo the {} with {}; x = {} (mod {})", a2, b2, n2, a2, inv, first, n2);
    println!("{:<34}{:>8}", format!("unfolded, in steps of {}", n2), show(&found));
    println!("{}", found.iter().map(|x| format!("{} x {} = {} = {} x {} + {}", A, x, A * x, A * x / N, N, A * x % N)).collect::<Vec<String>>().join(";  "));
    println!("as whole numbers: {}", found.iter().map(|x| format!("{} x {} + {} x {} = {}", A, x, N, (B - A * x) / N, B)).collect::<Vec<String>>().join(", "));
    println!("aiming at 3: {} answers; shrinking {} and {} but not the {}: {}", brute(A, 3, N).len(), A, B, N, show(&brute(a2, b2, N)));
    assert!(g == 2 && found == brute(A, B, N) && found == vec![4, 9] && found.len() as i64 == g);
    assert!((A * 4) % N == B && A * 4 + N * -2 == B && A * 9 + N * -5 == B);
    assert!(brute(A, 3, N).is_empty() && brute(a2, b2, N) == vec![4] && N / g == 5);
    println!("ALL CHECKS PASS");
}
