// Roots and the factor theorem -- the same check as the Python, in Rust.  No crates.
// The tank: three edges adding to 6 m, pairwise products 11 m^2, volume 6 m^3.
// Its cubic is x^3 - 6x^2 + 11x - 6, written highest power first.
fn value(p: &[i64], x: i64) -> i64 {              // p at x, by nested multiplication
    let mut out = 0;
    for c in p { out = out * x + c; }
    out
}
fn value_f(p: &[i64], x: f64) -> f64 {            // the same at a fractional x, for the chart
    let mut out = 0.0;
    for c in p { out = out * x + *c as f64; }
    out
}
fn peel(p: &[i64], r: i64) -> (Vec<i64>, i64) {   // divide p by x - r: quotient, remainder
    let mut out = vec![p[0]];
    for c in &p[1..] {
        let last = out[out.len() - 1];
        out.push(last * r + c);
    }
    let rem = out.pop().unwrap();
    (out, rem)
}
fn multiply(p: &[i64], q: &[i64]) -> Vec<i64> {   // road two: multiply two polynomials out
    let mut out = vec![0; p.len() + q.len() - 1];
    for (i, a) in p.iter().enumerate() {
        for (j, b) in q.iter().enumerate() { out[i + j] += a * b; }
    }
    out
}
fn whole_roots(p: &[i64]) -> Vec<i64> {           // every whole number from -20 to 20 giving 0
    (-20..=20).filter(|&x| value(p, x) == 0).collect()
}
fn show(p: &[i64]) -> String {                    // a list of numbers, as one line
    p.iter().map(|c| c.to_string()).collect::<Vec<String>>().join(" ")
}
fn main() {
    let tank: Vec<i64> = vec![1, -6, 11, -6];
    let repeat: Vec<i64> = vec![1, -6, 9, -4];
    let vol12: Vec<i64> = vec![1, -6, 11, -12];
    println!("tank cubic, highest power first: {}", show(&tank));
    let first_five: Vec<i64> = (0..5).map(|x| value(&tank, x)).collect();
    println!("p at 0, 1, 2, 3, 4: {}", show(&first_five));
    let mut left = tank.clone();
    for r in [1, 2, 3] {
        let (q, rem) = peel(&left, r);
        println!("peel x - {}: quotient {}, remainder {}", r, show(&q), rem);
        assert!(rem == 0 && value(&tank, r) == 0);
        left = q;
    }
    let rebuilt = multiply(&multiply(&[1, -1], &[1, -2]), &[1, -3]);
    println!("rebuilt (x - 1)(x - 2)(x - 3): {}", show(&rebuilt));
    let (a, b, c) = (1, 2, 3);
    println!("edges: sum {}, pairwise products {}, volume {}",
             a + b + c, a * b + a * c + b * c, a * b * c);
    let cands: Vec<i64> = (-6..=6).filter(|&d| d != 0 && 6 % d == 0).collect();
    println!("whole-number candidates, the divisors of 6: {}", show(&cands));
    let at: Vec<i64> = cands.iter().map(|&d| value(&tank, d)).collect();
    println!("p at those candidates: {}", show(&at));
    println!("whole roots of the tank cubic in -20..20: {}  (3 of them, degree 3)", show(&whole_roots(&tank)));
    println!("volume 12 instead, x^3 - 6x^2 + 11x - 12: {}  (1 root, degree 3)", show(&whole_roots(&vol12)));
    println!("repeated root, x^3 - 6x^2 + 9x - 4: {}  (2 distinct, degree 3)", show(&whole_roots(&repeat)));
    println!("p at -1, the sign slip: {}", value(&tank, -1));
    println!("p at 4, a number that does not divide 6: {}", value(&tank, 4));
    let xs: Vec<f64> = (0..13).map(|i| 0.5 + 0.25 * i as f64).collect();
    let sx: Vec<String> = xs.iter().map(|x| format!("{:.2}", x)).collect();
    let sp: Vec<String> = xs.iter().map(|&x| format!("{:.2}", value_f(&tank, x))).collect();
    println!("chart x: {}", sx.join(" "));
    println!("chart p: {}", sp.join(" "));
    assert!(rebuilt == tank && multiply(&[1, -1], &[1, -2]) == vec![1, -3, 2]);
    assert!(whole_roots(&tank) == vec![1, 2, 3] && whole_roots(&repeat) == vec![1, 4] && whole_roots(&vol12) == vec![4]);
    assert!(value(&tank, -1) == -24 && value(&tank, 4) == 6 && left == vec![1]);
    println!("ALL CHECKS PASS");
}
