// Divides -- the same check as divides_check.py, in Rust.  No crates.  The
// 60-minute hour: which lesson lengths split it exactly.  Road one tests every
// length from 1 to 60.  Road two tests only 1 to 7 and takes both ends.
const HOUR: i64 = 60;

fn divides(a: i64, b: i64) -> bool {   // does a go into b with nothing left over?
    if a == 0 { return b == 0; }       // 0 times anything is 0, so 0 reaches nothing else
    b % a == 0
}

fn yes(b: bool) -> &'static str { if b { "True" } else { "False" } }

fn joined(v: &[i64]) -> String {
    v.iter().map(|x| x.to_string()).collect::<Vec<String>>().join(" ")
}

fn main() {
    let brute: Vec<i64> = (1..=HOUR).filter(|&a| divides(a, HOUR)).collect();
    let pairs: Vec<(i64, i64)> = (1..8).filter(|&a| divides(a, HOUR)).map(|a| (a, HOUR / a)).collect();
    let mut from_pairs: Vec<i64> = Vec::new();                   // the check, second road
    for &(a, b) in &pairs { from_pairs.push(a); from_pairs.push(b); }
    from_pairs.sort();
    let shown: Vec<String> = pairs.iter().map(|(a, b)| format!("{} x {}", a, b)).collect();
    let partners: Vec<i64> = brute.iter().map(|&a| HOUR / a).collect();
    println!("the pairs that multiply to 60   {}", shown.join("  "));
    println!("divisors of 60, smallest first  {}", joined(&brute));
    println!("their partners, same order      {}", joined(&partners));
    println!("how many divisors 60 has        {}", brute.len());
    println!("tested 1 up to 7, because 8 x 8 = {} is past {}", 8 * 8, HOUR);
    println!("8 does not divide 60:  60 = 8 x {} + {}", HOUR / 8, HOUR % 8);
    println!("12 divides 60:  {}         60 divides 12:  {}", yes(divides(12, HOUR)), yes(divides(HOUR, 12)));
    println!("1 divides 60:   {}         60 divides 0:   {}", yes(divides(1, HOUR)), yes(divides(HOUR, 0)));
    println!("0 divides 60:   {}        0 divides 0:    {}", yes(divides(0, HOUR)), yes(divides(0, 0)));
    println!("stopping the list at 6 finds only {} of the {}",
             brute.iter().filter(|&&a| a <= 6).count(), brute.len());
    assert!(brute == vec![1, 2, 3, 4, 5, 6, 10, 12, 15, 20, 30, 60]);
    assert!(from_pairs == brute && brute.len() == 12);
    assert!(brute.iter().all(|&a| a * (HOUR / a) == HOUR) && HOUR % 8 == 4 && HOUR / 8 == 7);
    println!("ALL CHECKS PASS");
}
