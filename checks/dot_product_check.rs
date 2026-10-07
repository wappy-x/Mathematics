// The dot product -- the same check as the Python, in Rust.  No crates.  A weekly
// shop: quantities (2, 3, 1) at prices (3, 2, 4); a cyclist's leg (3, 4); the
// direction (4, -3) at right angles to it; (6, 8), the same way twice as long.
// Two roads to the bill, Pythagoras on the tips, Cauchy-Schwarz on twelve arrows.
const SHOP_Q: [i64; 3] = [2, 3, 1];
const SHOP_P: [i64; 3] = [3, 2, 4];
const LEG: [i64; 2] = [3, 4];
const PERP: [i64; 2] = [4, -3];
const TWICE: [i64; 2] = [6, 8];
const ROUND: [[i64; 2]; 12] = [[5, 0], [4, 3], [3, 4], [0, 5], [-3, 4], [-4, 3],
                               [-5, 0], [-4, -3], [-3, -4], [0, -5], [3, -4], [4, -3]];

fn dot(a: &[i64], b: &[i64]) -> i64 {   // road one: multiply matching entries, add
    let mut total = 0;
    for k in 0..a.len() { total += a[k] * b[k]; }
    total
}

fn squares(w: &[i64]) -> i64 {          // one list's own squares, nothing paired
    let mut total = 0;
    for &t in w { total += t * t; }
    total
}

fn dot_from_lengths(a: &[i64], b: &[i64]) -> f64 {   // road two: squared lengths only
    let both: Vec<i64> = (0..a.len()).map(|k| a[k] + b[k]).collect();
    (squares(&both) - squares(a) - squares(b)) as f64 / 2.0
}

fn length(w: &[i64]) -> f64 { (squares(w) as f64).sqrt() }

fn show(w: &[i64]) -> String {
    let parts: Vec<String> = w.iter().map(|t| t.to_string()).collect();
    format!("({})", parts.join(", "))
}

fn one(name: &str, value: String) { println!("{:<46}{:>6}", name, value); }

fn main() {
    for (a, b) in [(&SHOP_Q[..], &SHOP_P[..]), (&LEG[..], &LEG[..]),
                   (&LEG[..], &PERP[..]), (&LEG[..], &TWICE[..])] {
        let parts: Vec<String> = (0..a.len())
            .map(|k| format!("{} x {} = {}", a[k], b[k], a[k] * b[k])).collect();
        println!("line by line, {} . {}: {}", show(a), show(b), parts.join(", "));
    }
    one("(2, 3, 1) . (3, 2, 4), the bill in dollars", format!("{}", dot(&SHOP_Q, &SHOP_P)));
    one("the same bill, from squared lengths only",
        format!("{:.0}", dot_from_lengths(&SHOP_Q, &SHOP_P)));
    one("(3, 4) . (3, 4)", format!("{}", dot(&LEG, &LEG)));
    one("the leg's length, the square root of 25", format!("{:.1}", length(&LEG)));
    one("(3, 4) . (4, -3)", format!("{}", dot(&LEG, &PERP)));
    one("(3, 4) . (6, 8)", format!("{}", dot(&LEG, &TWICE)));
    one("the alignment score, 50 / (5 x 10)",
        format!("{:.2}", dot(&LEG, &TWICE) as f64 / (length(&LEG) * length(&TWICE))));
    let gap: Vec<i64> = (0..LEG.len()).map(|k| LEG[k] - PERP[k]).collect();
    println!("the tips of (3, 4) and (4, -3) are {} apart, squared length {} = {} + {}",
             show(&gap), squares(&gap), squares(&LEG), squares(&PERP));
    let add_them: i64 = (0..SHOP_Q.len()).map(|k| SHOP_Q[k] + SHOP_P[k]).sum();
    let all_pairs: i64 = SHOP_Q.iter().sum::<i64>() * SHOP_P.iter().sum::<i64>();
    let back: Vec<i64> = SHOP_P.iter().rev().cloned().collect();
    let back_to_front = dot(&SHOP_Q, &back);
    println!("the four mistakes come out at {}, {}, {} and {}",
             add_them, all_pairs, back_to_front, squares(&LEG));
    let scores: Vec<f64> = ROUND.iter()
        .map(|d| dot(&LEG, d) as f64 / (length(&LEG) * length(d))).collect();
    println!("alignment scores with (3, 4), for twelve directions each of length 5:");
    let mut names = String::from("  ");
    for d in ROUND.iter() { names.push_str(&format!("{:>8}", show(d).replace(", ", ","))); }
    println!("{}", names);
    let mut row = String::from("  ");
    for s in scores.iter() { row.push_str(&format!("{:>8.2}", s)); }
    println!("{}", row);
    assert!(dot(&SHOP_Q, &SHOP_P) == 16 && dot_from_lengths(&SHOP_Q, &SHOP_P) == 16.0);
    assert!(add_them == 15 && all_pairs == 54 && back_to_front == 17);
    assert!(squares(&LEG) == 25 && dot(&LEG, &PERP) == 0 && squares(&gap) == squares(&LEG) + squares(&PERP));
    assert!(scores[2] == 1.0 && scores[8] == -1.0
            && scores.iter().all(|&s| (-1.0..=1.0).contains(&s)));
    assert!(ROUND.iter().all(|d| dot(&LEG, d).pow(2) <= squares(&LEG) * squares(d)));   // Cauchy-Schwarz
    println!("ALL CHECKS PASS");
}
