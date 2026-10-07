// Irrational numbers -- the same check as the Python one, in Rust.  No crates.  A floor
// tile 1000 mm on a side: the square on its diagonal is 2000000 square mm, and no whole
// number of millimetres squares to that.  Then two decimals, dug out a place at a time.
fn row(name: &str, value: String) { println!("{:<44}{:>16}", name, value); }

fn joined(v: &[i64], sep: &str) -> String {
    v.iter().map(|d| d.to_string()).collect::<Vec<String>>().join(sep)
}

fn main() {
    let area: i64 = 2 * 1000 * 1000;
    row("tile side, then the square on the diagonal", format!("{}  {}", 1000, area));
    row("1414 x 1414, then 1415 x 1415", format!("{}  {}", 1414 * 1414, 1415 * 1415));
    row("short by, then over by, in sq mm", format!("{}  {}", area - 1414 * 1414, 1415 * 1415 - area));
    row("99 x 99, then 2 x 70 x 70", format!("{}  {}", 99 * 99, 2 * 70 * 70));
    let (mut whole, mut power, mut dug) = (1i64, 1i64, Vec::new());
    for _ in 0..8 {       // biggest whole number whose square, in these units, stays under 2
        whole *= 10; power *= 10;
        while (whole + 1) * (whole + 1) <= 2 * power * power { whole += 1; }
        dug.push(whole % 10);
    }
    row("root 2, dug out one digit at a time", format!("1.{}", joined(&dug, "")));
    let (mut left, mut digits, mut rests) = (5i64, Vec::new(), Vec::new());
    for _ in 0..8 {       // long division: 5 divided by 11, one place at a time
        digits.push(left * 10 / 11);
        left = left * 10 % 11;
        rests.push(left);
    }
    row("five elevenths, by long division", format!("0.{}", joined(&digits, "")));
    row("that decimal shifted two places", format!("45.{}", joined(&digits, "")));
    row("its remainders, step by step", joined(&rests, " "));
    let (mut a, mut b) = (45i64, 99i64);
    while b != 0 { let t = b; b = a % b; a = t; }   // a ends up 9, the biggest common divisor
    row("45/99 from the shift-and-subtract, cut down", format!("{}/{}", 45 / a, 99 / a));
    assert!(1414 * 1414 < area && area < 1415 * 1415 && 99 * 99 - 2 * 70 * 70 == 1);
    assert!(dug == [4, 1, 4, 2, 1, 3, 5, 6] && digits == [4, 5, 4, 5, 4, 5, 4, 5]);
    assert!(45 / a == 5 && 99 / a == 11 && rests[0] == 6 && rests[2] == 6);
    println!("ALL CHECKS PASS");
}
