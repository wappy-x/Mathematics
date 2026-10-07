// Rearranging a formula -- the same check as the Python, in Rust.  No crates.
// F = 1.8C + 32 turns 25 degrees C into 77 degrees F.  Rearranged,
// C = (F - 32) / 1.8 turns 77 back into 25.  Two roads reach that 25: the
// rearranged formula, and a hunt that never rearranges anything at all.
const SLOPE: f64 = 1.8;                          // the two numbers in F = 1.8C + 32
const OFFSET: f64 = 32.0;

fn to_f(c: f64) -> f64 { SLOPE * c + OFFSET }    // the formula as it is written
fn to_c(f: f64) -> f64 { (f - OFFSET) / SLOPE }  // road one: the rearranged formula

fn hunt(f: f64) -> f64 {                         // road two: no rearranging at all
    let (mut lo, mut hi) = (-100.0, 200.0);      // the Celsius number is in here
    for _ in 0..200 {                            // halve the range, 200 times over
        let mid = (lo + hi) / 2.0;
        if to_f(mid) < f { lo = mid; }           // too cold, keep the upper half
        else { hi = mid; }                       // too warm, keep the lower half
    }
    (lo + hi) / 2.0
}

fn fare(m: f64) -> f64 { 3.0 + 2.0 * m }         // the taxi: $3 to start, $2 a mile
fn miles(f: f64) -> f64 { (f - 3.0) / 2.0 }      // the same formula, rearranged

fn grid(name: &str, values: &[String]) {
    let mut line = format!("{:<26}", name);
    for v in values { line.push_str(&format!("{:>7}", v)); }
    println!("{}", line);
}
fn one(name: &str, value: String) { println!("{:<48}{:>10}", name, value); }
fn round2(x: f64) -> f64 { (x * 100.0).round() / 100.0 }

fn main() {
    println!("forward   1.8 x 25 = {:.1}, then {:.1} + 32 = {:.1} degrees F",
             SLOPE * 25.0, SLOPE * 25.0, to_f(25.0));
    println!("backward  77 - 32 = {:.1}, then {:.1} / 1.8 = {:.1} degrees C",
             77.0 - OFFSET, 77.0 - OFFSET, to_c(77.0));
    let cs = [0.0, 5.0, 10.0, 15.0, 20.0, 25.0];
    let fs: Vec<f64> = cs.iter().map(|c| to_f(*c)).collect();
    grid("C, degrees Celsius", &cs.iter().map(|c| format!("{:.0}", c)).collect::<Vec<String>>());
    grid("F, degrees Fahrenheit", &fs.iter().map(|f| format!("{:.0}", f)).collect::<Vec<String>>());
    grid("back to C, rearranged", &fs.iter().map(|f| format!("{:.0}", to_c(*f))).collect::<Vec<String>>());
    one("77 F in Celsius, the rearranged formula", format!("{:.1}", to_c(77.0)));
    one("77 F in Celsius, hunted in the original formula", format!("{:.1}", hunt(77.0)));
    one("5 miles in the taxi costs", format!("${:.2}", fare(5.0)));
    println!("taxi      13.00 - 3 = {:.2}, then {:.2} / 2 = {:.1} miles",
             13.0 - 3.0, 13.0 - 3.0, miles(13.0));
    let wrong_order = 77.0 / SLOPE - OFFSET;     // divided before subtracting
    let no_brackets = 77.0 - OFFSET / SLOPE;     // only the 32 got divided
    let wrong_sign = (77.0 + OFFSET) / SLOPE;    // added instead of subtracted
    println!("the three wrong roads give {:.2}, {:.2} and {:.2} degrees C, not {:.1}",
             wrong_order, no_brackets, wrong_sign, to_c(77.0));
    one("a $13.00 fare with the $3 flagfall forgotten", format!("{:.1} miles", 13.0 / 2.0));
    const PI: f64 = 3.14159265358979;            // written out, no crates
    let radius = (12.0 / PI).sqrt();             // area = PI x radius x radius
    one("a rug of area 12.00 square feet has radius", format!("{:.4} feet", radius));
    let rate = (162.89 / 100.0f64).powf(1.0 / 10.0) - 1.0;  // a tenth power, undone
    one("$100.00 to $162.89 in 10 years is a rate of", format!("{:.2}% a year", rate * 100.0));
    assert!(to_f(25.0) == 77.0 && to_c(77.0) == 25.0 && fs == [32.0, 41.0, 50.0, 59.0, 68.0, 77.0]
            && (hunt(77.0) - 25.0).abs() < 1e-9 && (hunt(212.0) - 100.0).abs() < 1e-9);
    assert!(fare(5.0) == 13.0 && miles(13.0) == 5.0 && 13.0 / 2.0 == 6.5);
    assert!(round2(wrong_order) == 10.78 && round2(no_brackets) == 59.22 && round2(wrong_sign) == 60.56);
    assert!((radius * 10000.0).round() / 10000.0 == 1.9544 && round2(rate * 100.0) == 5.00);
    println!("ALL CHECKS PASS");
}
