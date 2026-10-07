// Linear against exponential -- the same check as the Python, in Rust.  No
// crates.  Two ponds, each starting at one lily pad.  In the first the gardener
// adds one pad a day.  In the second the pads double.  Covered is a million.
const COVER: i64 = 1000000;

fn grid(name: &str, values: &[i64]) {
    let mut line = format!("{:<16}", name);
    for v in values { line.push_str(&format!("{:>6}", v)); }
    println!("{}", line);
}

fn one(name: &str, value: i64) { println!("{:<44}{:>10}", name, value); }

fn main() {
    let (mut plus, mut times) = (vec![1i64], vec![1i64]);
    for _ in 0..20 {                         // one road: step a day at a time
        plus.push(plus[plus.len() - 1] + 1);
        times.push(times[times.len() - 1] * 2);
    }
    let days: Vec<i64> = (0..11).collect();
    grid("day", &days);
    grid("one pad a day", &plus[..11]);
    grid("doubling", &times[..11]);
    one("day 19, doubling pond", times[19]);
    one("day 20, doubling pond", times[20]);
    one("day 20, one-pad pond", plus[20]);
    one("day 20, the gap", times[20] - plus[20]);
    one("days for the one-pad pond to reach 1000000", COVER - 1);
    one("that, in whole years", (COVER - 1) / 365);
    println!("the two mistakes come out at {} and {}", 1 + 2 * 20, 2 * 20);

    assert!(plus[20] == 21 && times[20] == 1048576 && times[20] - plus[20] == 1048555);
    assert!(times[20] == times[10] * times[10]);   // a second road: 1024 x 1024
    assert!(times[19] * 2 == times[20] && times[19] < COVER && COVER <= times[20]);
    assert!(COVER - 1 == 999999 && (COVER - 1) / 365 == 2739);  // headline numbers
    assert!(1 + 2 * 20 == 41 && 2 * 20 == 40);   // the two mistakes, as printed
    println!("ALL CHECKS PASS");
}
