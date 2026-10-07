// Proof by contrapositive -- the same check as the Python one, in Rust.  No
// crates.  The car park sign: "if your ticket is validated, you pay nothing."
// Four drivers, read by the sign, by its flip, and by its converse.  Then the
// twin claim: if a number times itself is odd, the number is odd.
const DRIVERS: [(&str, i64, i64); 4] =
    [("Vic", 1, 0), ("Wes", 1, 6), ("Yaz", 0, 0), ("Zed", 0, 6)];

fn kept(if_part: i64, then_part: i64) -> i64 {   // breaks only when the if part holds and the then part fails
    if if_part == 1 && then_part == 0 { 0 } else { 1 }
}

fn main() {
    println!("{:<5}{:>11}{:>6}{:>10}{:>10}{:>14}",
             "name", "validated", "paid", "the sign", "the flip", "the converse");
    let (mut sign, mut flip, mut converse) = (Vec::new(), Vec::new(), Vec::new());
    for (name, val, paid) in DRIVERS {
        sign.push(kept(val, if paid == 0 { 1 } else { 0 }));        // validated -> pays nothing
        flip.push(kept(if paid > 0 { 1 } else { 0 }, 1 - val));     // paid something -> not validated
        converse.push(kept(if paid == 0 { 1 } else { 0 }, val));    // pays nothing -> validated
        println!("{:<5}{:>11}{:>6}{:>10}{:>10}{:>14}", name, val, paid,
                 sign[sign.len() - 1], flip[flip.len() - 1], converse[converse.len() - 1]);
    }
    println!("the flip disagrees with the sign on rows {}",
             (0..4).filter(|&i| sign[i] != flip[i]).count());
    println!("the converse disagrees with the sign on rows {}",
             (0..4).filter(|&i| sign[i] != converse[i]).count());
    let (n, k) = (6i64, 3i64);
    println!("{} = 2 x {}, so {} x {} = 2 x ({} x {}) = 2 x {} = {}, even",
             n, k, n, n, k, n, k * n, n * n);
    println!("7 x 7 = {}, odd", 7 * 7);
    let odd_ones: Vec<i64> = (1..=20i64).filter(|m| (m * m) % 2 == 1).collect();
    println!("whole numbers 1 to 20 with n x n odd {}, every one of them odd", odd_ones.len());
    assert!(sign == vec![1, 0, 1, 1] && flip == sign && converse == vec![1, 1, 0, 1]);
    assert!(n * n == 2 * (k * n) && (n * n) % 2 == 0 && (7 * 7) % 2 == 1);
    assert!(odd_ones == (1..=19i64).step_by(2).collect::<Vec<i64>>() && odd_ones.len() == 10);
    println!("ALL CHECKS PASS");
}
