// Log laws and log scales -- the same check as the Python one, in Rust.  No crates.
// A village of 100, a town of 10,000, a city of 10,000,000, on a 1-10-100 axis.
const VILLAGE: i64 = 100;
const TOWN: i64 = 10000;
const CITY: i64 = 10000000;
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
    let (v, t, c) = (count_of_tens(VILLAGE), count_of_tens(TOWN), count_of_tens(CITY));
    let (product, quotient, square) = (VILLAGE * TOWN, CITY / VILLAGE, TOWN * TOWN); // the plain way
    let half = count_of_tens(product) / v;                       // 6 / 2, the count in hundreds
    let (mid, rem) = ((v + t) / 2, (v + t) % 2); assert!(rem == 0, "halfway is not a whole count");
    println!("village x town     {} x {} = {:<9}count {}", VILLAGE, TOWN, product, count_of_tens(product));
    println!("the counts added instead     {} + {} = {}", v, t, v + t);
    println!("city / village     {} / {} = {:<7}count {}", CITY, VILLAGE, quotient, count_of_tens(quotient));
    println!("the counts subtracted        {} - {} = {}", c, v, c - v);
    println!("town squared       {} x {} = {:<10}count {} = {} + {}", TOWN, TOWN, square, count_of_tens(square), t, t);
    println!("in villages   the product {} / {} = {}, the city {} / {} = {}", count_of_tens(product), v, half, c, v, c as f64 / v as f64);
    println!("halfway from {} to {}    count {}, the {} mark", VILLAGE, TOWN, mid, tens_back(mid));
    println!("the three mistakes come out at {}, {} and {}", VILLAGE + TOWN, (VILLAGE + TOWN) / 2, v * t);
    assert!(product == 1000000 && count_of_tens(product) == v + t && count_of_tens(square) == 2 * t);
    assert!(quotient == 100000 && count_of_tens(quotient) == c - v && square == 100000000);
    assert!(half == 3 && VILLAGE * VILLAGE * VILLAGE == product && tens_back(mid) == 1000);
    println!("ALL CHECKS PASS");
}
