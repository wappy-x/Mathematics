// Scientific notation -- the same check as scientific_notation_check.py, in
// Rust.  No crates.  The distance to the Sun and the width of a red blood
// cell, written out the long way and as a front number times a power of ten.

fn times_ten(front: f64, power: i32) -> f64 {   // 1.5, 8 -> multiply 1.5 by ten, eight times
    let mut value = front;
    for _ in 0..power.abs() {
        value = if power > 0 { value * 10.0 } else { value / 10.0 };
    }
    value
}

fn row(name: &str, value: String) { println!("{:<34}{}", name, value); }

fn main() {
    row("distance to the Sun, km", format!("{:.0}", 150000000.0f64));
    row("1.5 x 10^8 km, multiplied out", format!("{:.0}", times_ten(1.5, 8)));
    row("distance to the Sun, m", format!("{:.0}", 150000000000.0f64));
    row("1.5 x 10^11 m, multiplied out", format!("{:.0}", times_ten(1.5, 11)));
    row("width of a red blood cell, m", format!("{:.6}", 0.000007f64));
    row("7 x 10^-6 m, divided out", format!("{:.6}", times_ten(7.0, -6)));
    let long_way = 150000000000.0f64 / 0.000007;                // one road: plain division
    let (front, power) = (1.5f64 / 7.0 * 10.0, 11 - (-6) - 1);  // the other: fronts, then powers
    row("Sun over cell, plain division", format!("{:.6} x 10^16", long_way / times_ten(1.0, 16)));
    row("Sun over cell, powers subtracted",
        format!("{:.7} x 10^17 = {:.6} x 10^{}", 1.5f64 / 7.0, front, power));
    println!("the dot moves 8 places for the Sun in km and 6 for the cell; km to m adds 3; 11 - (-6) = {}",
             11 - (-6));
    println!("more to read: 6.02 x 10^23 slides the dot 23 places right, 1.5 x 10^-9 slides it 9 places left");
    println!("the mistakes come out at {:.6} m and {:.6} x 10^{}",
             times_ten(7.0, -5), front, 11 + -6 - 1);
    assert!(times_ten(1.5, 8) == 150000000.0);
    assert!((times_ten(7.0, -6) - 0.000007).abs() < 1e-18);
    assert!((long_way - times_ten(front, power)).abs() < 1000000.0);
    println!("ALL CHECKS PASS");
}
