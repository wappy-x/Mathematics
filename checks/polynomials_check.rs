// Polynomials -- the same check as the Python, in Rust.  No crates.  A football
// kicked straight up at 20 m/s is 20t - 5t^2 metres up after t seconds.  A
// coefficient list runs from the plain number upward: the ball is [0, 20, -5],
// a second ball thrown off a 3 m wall is [3, 12, -5].
const BALL: [i64; 3] = [0, 20, -5];
const WALL: [i64; 3] = [3, 12, -5];
fn plain(c: &[i64], t: f64) -> f64 {      // one road: work out each power, then add
    let mut total = 0.0_f64;
    for (i, &a) in c.iter().enumerate() {
        let mut power = 1.0_f64;
        for _ in 0..i { power *= t; }
        total += a as f64 * power;
    }
    total
}
fn nested(c: &[i64], t: f64) -> f64 {     // second road: multiply and add, no powers
    let mut total = 0.0_f64;
    for &a in c.iter().rev() { total = total * t + a as f64; }
    total
}
fn add(c: &[i64], d: &[i64]) -> Vec<i64> {   // line the lists up, add what sits together
    (0..c.len().max(d.len()))
        .map(|i| c.get(i).copied().unwrap_or(0) + d.get(i).copied().unwrap_or(0)).collect()
}
fn mul(c: &[i64], d: &[i64]) -> Vec<i64> {   // every term of one times every term of the other
    let mut out = vec![0i64; c.len() + d.len() - 1];
    for (i, &a) in c.iter().enumerate() {
        for (j, &b) in d.iter().enumerate() { out[i + j] += a * b; }
    }
    out
}
fn degree(c: &[i64]) -> usize {
    c.iter().enumerate().filter(|(_, &a)| a != 0).map(|(i, _)| i).max().unwrap()
}
fn row(name: &str, vals: Vec<String>) {
    let mut line = format!("{:<15}", name);
    for v in &vals { line.push_str(&format!("{:>7}", v)); }
    println!("{}", line);
}
fn list(vals: Vec<String>) -> String { vals.join(", ") }
fn main() {
    let ts: Vec<f64> = (0..13).map(|i| i as f64 / 2.0).collect();   // 0, 0.5 ... 6.0 seconds
    row("t, seconds", ts.iter().map(|&t| format!("{:.1}", t)).collect());
    row("height, m", ts.iter().map(|&t| format!("{:.2}", plain(&BALL, t))).collect());
    println!("degree {}; coefficients {} for t^2, {} for t, {} plain",
             degree(&BALL), BALL[2], BALL[1], BALL[0]);
    println!("height at t = 1, 2, 3, 4: {} metres",
             list([1.0, 2.0, 3.0, 4.0].iter().map(|&t| format!("{:.2}", plain(&BALL, t))).collect()));
    println!("the piece 20t: {}; the piece 5t^2: {}",
             list([1.0, 2.0, 3.0, 4.0].iter().map(|&t| format!("{:.2}", 20.0 * t)).collect()),
             list([1.0, 2.0, 3.0, 4.0].iter().map(|&t| format!("{:.2}", 5.0 * t * t)).collect()));
    println!("the roots, where the height is zero: t = 0 and t = 4");
    let far = ts.iter().map(|&t| (plain(&BALL, t) - nested(&BALL, t)).abs()).fold(0.0_f64, f64::max);
    println!("the nested route gives the same heights; biggest difference {:.8}", far);
    println!("far end at t = 10: 20t is {:.2}, 5t^2 is {:.2}, height {:.2}",
             20.0 * 10.0, 5.0 * 100.0, plain(&BALL, 10.0));
    let e = mul(&[0, 5], &[4, -1]);
    println!("5t times (4 - t): plain {}, t coefficient {}, t^2 coefficient {}; \
              degrees add, 1 + 1 = {}", e[0], e[1], e[2], degree(&e));
    println!("second ball: plain {}, t coefficient {}, t^2 coefficient {}, degree {}",
             WALL[0], WALL[1], WALL[2], degree(&WALL));
    let neg: Vec<i64> = BALL.iter().map(|&a| -a).collect();
    let d = add(&WALL, &neg);
    println!("the gap between them: plain {}, t coefficient {}, t^2 coefficient {}, degree {}",
             d[0], d[1], d[2], degree(&d));
    let level = 3.0 / 8.0;
    println!("the balls are level at t = {:.3} s, both at {:.6} m", level, plain(&BALL, level));
    println!("h(2 + s) = 20 - 5s^2, so at s = 0, 1, 2 the heights are {}",
             list([0.0, 1.0, 2.0].iter().map(|&s| format!("{:.2}", plain(&BALL, 2.0 + s))).collect()));
    println!("three mistakes at t = 3: {:.2}, {:.2} and {:.2} instead of {:.2}",
             20.0 * 3.0 - (5.0 * 3.0) * (5.0 * 3.0), 20.0 - 3.0 * 3.0,
             20.0 * (2.0 + 1.0) - 5.0 * (4.0 + 1.0 * 1.0), plain(&BALL, 3.0));
    let four: Vec<f64> = [1.0, 2.0, 3.0, 4.0].iter().map(|&t| plain(&BALL, t)).collect();
    assert!(four == vec![15.0, 20.0, 15.0, 0.0]);
    assert!(far == 0.0 && degree(&BALL) == 2 && degree(&d) == 1 && e == BALL.to_vec());
    assert!(d == vec![3, -8, 0] && mul(&[0, 5], &[4, -1]) == mul(&[4, -1], &[0, 5]));
    assert!([0.0, 1.0, 2.0].iter().all(|&s| plain(&BALL, 2.0 + s) == 20.0 - 5.0 * s * s));
    println!("ALL CHECKS PASS");
}
