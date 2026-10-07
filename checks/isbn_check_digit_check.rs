// ISBN-10 -- the same check as the Python twin, in Rust.  No crates.  ISBN
// 0-306-40615-2: ten digits, weights 10 down to 1, total a multiple of 11.
const DIGITS: [i64; 10] = [0, 3, 0, 6, 4, 0, 6, 1, 5, 2];
const WEIGHTS: [i64; 10] = [10, 9, 8, 7, 6, 5, 4, 3, 2, 1];

fn total(ds: [i64; 10]) -> i64 {          // each digit times its weight, added up
    (0..10).map(|i| ds[i] * WEIGHTS[i]).sum()
}

fn main() {
    let t = total(DIGITS);
    let parts: Vec<String> = (0..10).map(|i| format!("{} x {}", WEIGHTS[i], DIGITS[i])).collect();
    println!("{} = {}", parts.join(" + "), t);
    println!("{} = {} x 11, so ISBN 0-306-40615-2 checks out", t, t / 11);
    let (mut runs, mut acc): (Vec<i64>, i64) = (Vec::new(), 0);   // second road: running totals
    for i in 0..10 { acc += DIGITS[i]; runs.push(acc); }
    let runsum: i64 = runs.iter().sum();
    let shown: Vec<String> = runs.iter().map(|r| r.to_string()).collect();
    println!("running totals: {}, and those add to {}", shown.join(", "), runsum);
    let mut first_nine = DIGITS;          // the first nine alone, weights 10 down to 2
    first_nine[9] = 0;
    let nine = total(first_nine);
    let check = (11 - nine % 11) % 11;
    println!("first nine digits: {} = {} x 11 + {}, so the check digit is 11 - {} = {}",
             nine, nine / 11, nine % 11, nine % 11, check);
    let mut swapped = DIGITS;
    swapped.swap(7, 8);
    let s = total(swapped);
    println!("swap the 1 and the 5: 0-306-40651-2 gives {} = {} x 11 + {}, rejected", s, s / 11, s % 11);
    println!("the swap moved the total by (3 - 2) x (5 - 1) = {}", s - t);
    println!("weight gaps run 1 to {} and digit gaps at most 10, and 11 divides neither", WEIGHTS[0] - WEIGHTS[9]);
    println!("on a clock of 10 a weight gap of 2 and a digit gap of 5 move it by {}, which leaves {}", 2 * 5, 2 * 5 % 10);
    println!("the three mistakes come out at {}, {} and {}", DIGITS.iter().sum::<i64>(), t % 10, nine % 11);
    assert!(t == 132 && t == runsum && t % 11 == 0);
    assert!(check == DIGITS[9] && check == 2 && nine == 130);
    assert!(s == 136 && s - t == (3 - 2) * (5 - 1) && s % 11 == 4);
    println!("ALL CHECKS PASS");
}
