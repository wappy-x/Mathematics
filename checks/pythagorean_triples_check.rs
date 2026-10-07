// Pythagorean triples -- the same check as pythagorean_triples_check.py, in Rust.
// No crates.  The builder's 3-4-5 rope, then the recipe: two whole numbers,
// bigger first, giving bigger x bigger - smaller x smaller and 2 x bigger x small.
fn triple(big: i64, small: i64) -> (i64, i64, i64) {   // the recipe, as on the card
    let (p, q) = (big * big - small * small, 2 * big * small);
    (p.min(q), p.max(q), big * big + small * small)
}
fn missing_leg(leg: i64, long_side: i64) -> i64 {      // count up until it fits
    let mut other = 1;
    while leg * leg + other * other < long_side * long_side { other += 1; }
    if leg * leg + other * other == long_side * long_side { other } else { 0 }
}
fn row(name: &str, value: &str) { println!("{:<44}{:>24}", name, value); }
fn main() {
    row("the rope: 3 x 3 + 4 x 4", &format!("{} + {} = {} = 5 x 5", 3 * 3, 4 * 4, 3 * 3 + 4 * 4));
    for (big, small) in [(3i64, 2i64), (4, 1), (2, 1)] {
        let (a, b, c) = triple(big, small);
        row(&format!("seeds {} and {}: leg, leg, long side", big, small), &format!("{} {} {}", a, b, c));
    }
    for (a, b, c) in [triple(3, 2), triple(4, 1)] {
        row(&format!("{} x {} + {} x {}", a, a, b, b),
            &format!("{} + {} = {} = {} x {}", a * a, b * b, a * a + b * b, c, c));
    }
    let (a, b, c) = triple(3, 2);
    row(&format!("({} + {}) x ({} - {}) = {} x {}", c, a, c, a, c + a, c - a),
        &format!("{} = {} x {}", (c + a) * (c - a), b, b));
    row("missing legs by counting up: 5,13 and 8,17",
        &format!("{} and {}", missing_leg(5, 13), missing_leg(8, 17)));
    let s = triple(3, 1);
    let share = (1i64..11).filter(|k| [s.0, s.1, s.2].iter().all(|v| v % k == 0)).max().unwrap();
    row("seeds 3 and 1, both odd", &format!("{} {} {}, shared factor {}", s.0, s.1, s.2, share));
    row("adding the sides, not the squares", &(3 + 4).to_string());
    row("smaller seed first, 2 and 3", &triple(2, 3).0.to_string());
    assert!(triple(3, 2) == (5, 12, 13) && triple(4, 1) == (8, 15, 17) && triple(2, 1) == (3, 4, 5));
    assert!(missing_leg(5, 13) == 12 && missing_leg(8, 17) == 15 && 25 + 144 == 169);
    assert!(triple(3, 1) == (6, 8, 10) && share == 2 && (13 + 5) * (13 - 5) == 144);
    println!("ALL CHECKS PASS");
}
