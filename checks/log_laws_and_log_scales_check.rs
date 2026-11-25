// Log laws and log scales -- the same check as the Python one, in Rust.  No crates.
// A village of 100, a town of 10,000, a city of 10,000,000, on a 1-10-100 axis.
const VILLAGE: i64 = 100;
const TOWN: i64 = 10000;
const CITY: i64 = 10000000;
const REGION: i64 = 100;      // towns in a region
const COUNTRY: i64 = 10000;   // towns in a large country
fn count_of_tens(x: i64) -> i64 {          // divide by ten until 1, counting the steps
    let (mut x, mut steps) = (x, 0i64);
    while x > 1 {
        assert!(x % 10 == 0, "not a whole power of ten"); x /= 10; steps += 1;
    }
    steps
}
fn tens_back(steps: i64) -> i64 {          // the road back: that many tens multiplied
    let mut out = 1i64;
    for _ in 0..steps { out *= 10; }
    out
}
fn main() {
    for (name, size) in [("village", VILLAGE), ("town", TOWN), ("city", CITY)] {
        println!("{:<9}{:>9}   its count {}", name, size, count_of_tens(size));
    }
    let (v, t, c, r) = (count_of_tens(VILLAGE), count_of_tens(TOWN), count_of_tens(CITY), count_of_tens(REGION));
    let (product, quotient, square) = (REGION * TOWN, CITY / VILLAGE, COUNTRY * TOWN); // the plain way
    let half = count_of_tens(product) / v;                       // 6 / 2, the count in steps of 100
    let (mid, rem) = ((v + t) / 2, (v + t) % 2); assert!(rem == 0, "halfway is not a whole count");
    println!("100 towns          {} x {} = {:<9}count {}", REGION, TOWN, product, count_of_tens(product));
    println!("the counts added instead     {} + {} = {}", r, t, r + t);
    println!("city / village     {} / {} = {:<7}count {}", CITY, VILLAGE, quotient, count_of_tens(quotient));
    println!("the counts subtracted        {} - {} = {}", c, v, c - v);
    println!("10000 towns        {} x {} = {:<10}count {} = {} + {}", COUNTRY, TOWN, square, count_of_tens(square), t, t);
    println!("in steps of 100   the product {} / {} = {}, the city {} / {} = {}", count_of_tens(product), v, half, c, v, c as f64 / v as f64);
    println!("halfway from {} to {}    count {}, the {} mark", VILLAGE, TOWN, mid, tens_back(mid));
    println!("the three mistakes come out at {}, {} and {}", REGION + TOWN, (VILLAGE + TOWN) / 2, r * t);
    assert!(product == 1000000 && count_of_tens(product) == r + t && count_of_tens(square) == 2 * t);
    assert!(quotient == 100000 && count_of_tens(quotient) == c - v && square == 100000000);
    assert!(half == 3 && VILLAGE * VILLAGE * VILLAGE == product && tens_back(mid) == 1000);
    println!("ALL CHECKS PASS");
}
