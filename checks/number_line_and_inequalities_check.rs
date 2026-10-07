// The number line and inequalities -- the same check as
// number_line_and_inequalities_check.py, in Rust.  No crates.  A thermostat holds
// a room between 18 and 22 degrees: six readings, and -2 outside.
const LOW: i64 = 18;
const HIGH: i64 = 22;
const READINGS: [i64; 6] = [22, 20, 18, 17, 19, 21];

fn row(name: &str, value: String) { println!("{:<34}{}", name, value); }
fn list(v: &[i64]) -> String { v.iter().map(|n| n.to_string()).collect::<Vec<_>>().join(", ") }

fn halfway(a: i64, b: i64, c: i64, d: i64) -> (i64, i64) {   // halfway between a/b and c/d
    let (top, bot) = (a * d + c * b, 2 * b * d);
    let (mut x, mut y) = (top, bot);
    while y != 0 { let t = x % y; x = y; y = t; }             // x ends as the biggest common divisor
    (top / x, bot / x)
}

fn main() {
    let mut sorted = READINGS.to_vec(); sorted.sort();
    let inside = READINGS.iter().filter(|&&t| LOW <= t && t <= HIGH).count();
    let ends_out = READINGS.iter().filter(|&&t| LOW < t && t < HIGH).count();
    let mut night = vec![-2i64]; night.extend(&sorted);
    let flipped: Vec<i64> = sorted.iter().map(|t| -t).collect();
    row("the night, left to right", list(&night));
    row("17 and 18, each doubled", format!("{}, {}", 2 * 17, 2 * 18));
    row("readings inside 18 to 22", inside.to_string());
    row("if the ends were left out", ends_out.to_string());
    row("17 and 19 as shortfalls from 20", format!("{}, {}", 20 - 17, 20 - 19));
    row("the same list, each times -1", list(&flipped));
    for (a, b, c, d) in [(18, 1, 22, 1), (18, 1, 20, 1), (18, 1, 19, 1), (18, 1, 37, 2)] {
        let (t, u) = halfway(a, b, c, d);
        row(&format!("halfway between {}/{} and {}/{}", a, b, c, d),
            format!("{}/{} = {:.2}", t, u, t as f64 / u as f64));
    }
    let mut down = flipped.clone(); down.sort(); down.reverse();
    assert!(inside == 5 && ends_out == 3 && night[0] < 17 && 17 < LOW);
    assert!(flipped == down);
    assert!(halfway(18, 1, 19, 1) == (37, 2) && 18.0 < 37.0 / 2.0 && 37.0 / 2.0 < 19.0);
    println!("ALL CHECKS PASS");
}
