// The number families -- the same check as number_families_check.py, in Rust.
// No crates.  A carpenter's job: 3 planks counted, a plank cut 15 cm short,
// a 100 cm off-cut sawn in three, and a 30 cm square tile whose diagonal
// lands between two marks on the tape and stays there.
fn row(name: &str, value: &str) { println!("{:<40}{:>14}", name, value); }

fn main() {
    let (planks, want, got, offcut, side) = (3i64, 240i64, 225i64, 100i64, 30i64);
    let short = got - want;                       // 225 - 240, off the bottom of counting
    let (whole, rest) = (offcut / 3, offcut % 3); // 100 cm is three 33s and 1 cm over
    let dsq = side * side + side * side;          // the diagonal, multiplied by itself
    let (mut lo, mut hi) = (side as f64, (2 * side) as f64);  // longer than a side, shorter than two
    for _ in 0..60 {                              // road 1: squeeze it between two marks
        let mid = (lo + hi) / 2.0;
        if mid * mid < dsq as f64 { lo = mid; } else { hi = mid; }
    }
    let mut guess = side as f64;
    for _ in 0..20 { guess = (guess + dsq as f64 / guess) / 2.0; }  // road 2: guess, average, repeat
    row("planks on the job", &planks.to_string());
    row("plank cut short, 225 - 240", &short.to_string());
    row("check, 240 + (-15) back to the cut", &(want + short).to_string());
    row("off-cut of 100 cm sawn in three", &format!("{} + {}/3 cm", whole, rest));
    row("check, three of those back together", &(whole * 3 + rest).to_string());
    row("tile diagonal, times itself, 900 + 900", &dsq.to_string());
    row("tile diagonal, squeezed, in cm", &format!("{:.9}", lo));
    row("tile diagonal, second road, in cm", &format!("{:.9}", guess));
    row("rounding that third down to 33 loses", &(whole * 3).to_string());
    row("tape mark below, 42.42 x 42.42", &format!("{:.4}", 4242.0 * 4242.0 / 10000.0));
    row("tape mark above, 42.43 x 42.43", &format!("{:.4}", 4243.0 * 4243.0 / 10000.0));
    assert!(short == -15 && want + short == got);
    assert!(whole == 33 && rest == 1 && whole * 3 + rest == offcut && whole * 3 == 99);
    assert!(dsq == 1800 && lo * lo < dsq as f64 && (dsq as f64) < hi * hi && (lo - guess).abs() < 1e-9);
    println!("ALL CHECKS PASS");
}
