// Ratios and rates -- the same check as ratios_and_rates_check.py, in Rust.  No
// crates.  Paint mixed 3 parts blue to 2 parts white, scaled up to a 15 litre
// tin.  A car covering 120 km in 1.5 hours.  Blue paint, 3 litres for $2.25.
fn row(name: &str, value: String) { println!("{:<34}{:>11}", name, value); }

fn main() {
    let (blue_parts, white_parts, tin) = (3i64, 2i64, 15i64);
    let parts = blue_parts + white_parts;
    let per_part = tin / parts;                   // what one part is worth, in litres
    let (blue, white) = (blue_parts * per_part, white_parts * per_part);
    row("parts in the mix, 3 blue + 2 white", parts.to_string());
    row("litres in one part, 15 / 5", per_part.to_string());
    row("blue litres and white litres", format!("{} and {}", blue, white));
    row("blue + white, back to the tin", (blue + white).to_string());

    let (km, hours) = (120.0f64, 1.5f64);
    let speed = km / hours;                       // a rate: kilometres per one hour
    row("car speed, 120 km / 1.5 hours", format!("{:.0}", speed));
    row("distance check, speed x 1.5 hours", format!("{:.0}", speed * hours));
    row("km by 0.5 hours and by 1 hour", format!("{:.0} and {:.0}", speed * 0.5, speed));

    let (price, litres) = (2.25f64, 3.0f64);
    let unit = price / litres;                    // the same move: dollars per litre
    row("unit price, $2.25 / 3 litres", format!("{:.2}", unit));
    row("twelve litres, 12 x unit price", format!("{:.2}", 12.0 * unit));
    row("twelve litres, 4 x $2.25", format!("{:.2}", (12.0 / litres) * price));
    println!("the three mistakes: {} litres, {:.4} hours per km, ${:.2}",
             (tin / blue_parts) * parts, hours / km, 12.0 * price);

    assert!(parts == 5 && per_part == 3 && blue == 9 && white == 6 && blue + white == 15);
    assert!(speed == 80.0 && speed * hours == 120.0 && speed * 0.5 == 40.0);
    assert!(unit == 0.75 && 12.0 * unit == 9.0 && (12.0 / litres) * price == 9.0);
    println!("ALL CHECKS PASS");
}
