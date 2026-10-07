// Wilson's theorem -- the same check as the Python one, in Rust.  No crates.
// Six dancers, 1 to 6, on a 7-hour clock: each pairs off with the partner that
// undoes it, so the whole product reads 6, one short of a clock, which is -1.
const CLOCK: i64 = 7;

fn product(top: i64, clock: i64) -> i64 {   // 1 x 2 x ... x top, whole clocks taken off
    let mut out = 1;
    for k in 1..=top { out = (out * k) % clock; }
    out
}

fn row(name: &str, value: i64) { println!("{:<48}{:>5}", name, value); }

fn main() {
    let partners: Vec<i64> = (1..CLOCK)
        .map(|a| (1..CLOCK).find(|&b| (a * b) % CLOCK == 1).unwrap()).collect();
    let alone: Vec<i64> = (1..CLOCK).filter(|&a| partners[(a - 1) as usize] == a).collect();
    let pairs: Vec<(i64, i64)> = (1..CLOCK).filter(|&a| a < partners[(a - 1) as usize])
        .map(|a| (a, partners[(a - 1) as usize])).collect();
    let mut plain = 1i64;
    for k in 1..CLOCK { plain = plain * k; }                          // 720, in full
    let mut paired = 1i64;
    for &(a, b) in pairs.iter() { paired = (paired * a * b) % CLOCK; }  // each pair reads 1
    for &a in alone.iter() { paired = (paired * a) % CLOCK; }         // 1 and 6 are left
    row("1 x 2 x 3 x 4 x 5 x 6", plain);
    row(&format!("{} = {} x {} + {}, so the 7-clock reads", plain, plain / CLOCK, CLOCK, plain % CLOCK), plain % CLOCK);
    let who: Vec<String> = partners.iter().map(|b| b.to_string()).collect();
    println!("who undoes who, dancers 1 to 6:  {}", who.join(" "));
    let two: Vec<String> = pairs.iter()
        .map(|&(a, b)| format!("{} x {} = {} reads {}", a, b, a * b, a * b % CLOCK)).collect();
    println!("the two pairs: {}", two.join(", "));
    println!("their own partner: 1 x 1 = 1 and 6 x 6 = {}, both read 1", alone[1] * alone[1]);
    row("the pairing road, 1 x 1 x 1 x 6, reads", paired);
    row(&format!("that reading as a negative: {} - {}", plain % CLOCK, CLOCK), plain % CLOCK - CLOCK);
    println!("composites: an 8-clock (5040) reads {}, a 4-clock (6) reads {}", product(7, 8), product(3, 4));
    assert!(plain == 720 && plain == 102 * CLOCK + 6);
    assert!(partners == vec![1, 4, 5, 2, 3, 6] && alone == vec![1, 6] && pairs == vec![(2, 4), (3, 5)]);
    assert!(paired == 6 && plain % CLOCK == 6 && product(7, 8) == 0 && product(3, 4) == 2);
    println!("ALL CHECKS PASS");
}
