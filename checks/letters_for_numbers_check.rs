// Letters for numbers -- the same check as the Python, in Rust.  No crates.  A
// taxi charges $3 to start plus $2 a mile, so the fare in dollars is 3 + 2m,
// where m is the number of miles.  Every number quoted on the card is printed
// here, and the fare is reached by two roads that share no arithmetic.
const START: i64 = 3;
const PER_MILE: i64 = 2;

fn fare(m: i64) -> i64 {                       // road one: the recipe in one line
    START + PER_MILE * m
}

fn fare_a_mile_at_a_time(m: i64) -> i64 {      // road two: add $2, m times over
    let mut total = START;
    for _ in 0..m {
        total = total + PER_MILE;
    }
    total
}

fn two_taxis_collected(m: i64) -> i64 {        // two fares, collected: 6 + 4m
    6 + 4 * m
}

fn two_taxis_bracketed(m: i64) -> i64 {        // two fares, bracketed: 2(3 + 2m)
    2 * (START + PER_MILE * m)
}

fn grid(name: &str, values: &[i64]) {
    let mut line = format!("{:<24}", name);
    for v in values {
        line.push_str(&format!("{:>6}", v));
    }
    println!("{}", line);
}

fn main() {
    let miles: [i64; 6] = [0, 2, 4, 6, 8, 10];
    let charge: Vec<i64> = miles.iter().map(|&m| PER_MILE * m).collect();
    let one: Vec<i64> = miles.iter().map(|&m| fare(m)).collect();
    let two_collected: Vec<i64> = miles.iter().map(|&m| two_taxis_collected(m)).collect();
    let two_bracketed: Vec<i64> = miles.iter().map(|&m| two_taxis_bracketed(m)).collect();
    grid("miles m", &miles);
    grid("mileage charge, 2m", &charge);
    grid("one taxi, 3 + 2m", &one);
    grid("two taxis, 6 + 4m", &two_collected);
    grid("two taxis, 2(3 + 2m)", &two_bracketed);
    println!("fare at m = 6 and at m = 10: {} and {}", fare(6), fare(10));
    let mut parts = vec![START.to_string()];
    for _ in 0..6 {
        parts.push(PER_MILE.to_string());
    }
    println!("a mile at a time, m = 6: {} = {}", parts.join(" + "), fare_a_mile_at_a_time(6));
    println!(
        "two fares at m = 6: {} + {} = {}, collected {}, bracketed {}",
        fare(6), fare(6), fare(6) + fare(6), two_taxis_collected(6), two_taxis_bracketed(6)
    );
    let hits: Vec<i64> = (0..=20).filter(|&m| fare(m) == 15).collect();
    println!(
        "whole miles from 0 to 20 with a fare of 15: {}, namely m = {}",
        hits.len(), hits[0]
    );
    let wrong = [5 * 6, START + PER_MILE + 6, 6 + PER_MILE * 6, START + 4 * 6];
    println!(
        "the four mistakes at m = 6 come out at {}, {}, {} and {}",
        wrong[0], wrong[1], wrong[2], wrong[3]
    );
    assert!(fare(0) == 3 && fare(6) == 15 && fare(10) == 23);
    assert!((0..=20).all(|m| fare_a_mile_at_a_time(m) == fare(m)));
    assert!((0..=20).all(|m| two_taxis_collected(m) == two_taxis_bracketed(m)
        && two_taxis_bracketed(m) == fare(m) + fare(m)));
    assert!(hits == vec![6] && wrong == [30, 11, 18, 27]);
    println!("ALL CHECKS PASS");
}
