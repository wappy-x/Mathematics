// The quadratic formula -- the same check as the Python, in Rust.  No crates; the
// square root is built here by Newton's method.  A football is kicked straight up
// at 20 m/s, so its height t seconds later is 20t - 5t^2 metres.  Asking when the
// ball is H metres up means solving 5t^2 - 20t + H = 0.
fn root(v: f64) -> f64 {                       // square root, built from scratch
    let mut g = if v > 1.0 { v } else { 1.0 };
    for _ in 0..60 {                           // Newton: average a guess with v/guess
        g = (g + v / g) / 2.0;
    }
    g
}

fn height(t: f64) -> f64 { 20.0 * t - 5.0 * t * t }        // the ball, t seconds on

fn poly(t: f64) -> f64 { 5.0 * t * t - 20.0 * t + 15.0 }   // the 15 m question

fn formula(a: i64, b: i64, c: i64) -> (i64, Vec<f64>) {    // road one: the formula
    let d = b * b - 4 * a * c;
    if d < 0 { return (d, Vec::new()); }
    let (af, bf) = (a as f64, b as f64);
    if d == 0 { return (d, vec![-bf / (2.0 * af)]); }
    let s = root(d as f64);
    (d, vec![(-bf - s) / (2.0 * af), (-bf + s) / (2.0 * af)])
}

fn by_square(a: f64, b: f64, c: f64) -> (f64, f64, Vec<f64>) {  // road two
    let (p, q) = (b / a, c / a);               // divide through: t^2 + p*t + q = 0
    let m = -p / 2.0;                          // the middle, halfway between answers
    let k = m * m - q;                         // (t - m)^2 = k
    (m, k, vec![m - root(k), m + root(k)])
}

fn main() {
    let ts = [0.0, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0];
    println!("the ball's height, 20t - 5t^2 metres");
    let mut secs = String::from("t, seconds      ");
    let mut mets = String::from("height, metres  ");
    for &t in ts.iter() {
        secs.push_str(&format!("{:>7.1}", t));
        mets.push_str(&format!("{:>7.2}", height(t)));
    }
    println!("{}", secs);
    println!("{}", mets);
    let words = ["no answers", "one answer", "two answers"];
    for want in [15i64, 20, 25] {
        let (d, r) = formula(5, -20, want);
        let shown = if r.is_empty() { "never".to_string() } else {
            r.iter().map(|x| format!("{:.2}", x)).collect::<Vec<_>>().join(" and ")
        };
        println!("{} m up:  5t^2 - 20t + {} = 0   b^2 = {}   4ac = {}   D = {:>4}   \
                  t = {:<17} ({})", want, want, 20 * 20, 4 * 5 * want, d, shown, words[r.len()]);
    }
    let r15 = formula(5, -20, 15).1;
    let (mid, k, sq) = by_square(5.0, -20.0, 15.0);
    println!("the 15 m arithmetic:  -b = {},  2a = {},  the root of D = {:.2},  so t = \
              ({} - {:.2}) / {} and ({} + {:.2}) / {}",
             20, 2 * 5, root(100.0), 20, root(100.0), 2 * 5, 20, root(100.0), 2 * 5);
    println!("completing the square:  (t - {:.2})^2 = {:.2}, so t = {:.2} minus {:.2} and \
              {:.2} plus {:.2}, landing on {:.2} and {:.2}",
             mid, k, mid, root(k), mid, root(k), sq[0], sq[1]);
    println!("put each answer back into 5t^2 - 20t + 15:  {:.2} at t = {:.2}, {:.2} at \
              t = {:.2}", poly(r15[0]), r15[0], poly(r15[1]), r15[1]);
    println!("sum and product:  {:.2} + {:.2} = {:.2} = -b/a,  {:.2} x {:.2} = {:.2} = c/a",
             r15[0], r15[1], r15[0] + r15[1], r15[0], r15[1], r15[0] * r15[1]);
    let split = root(400.0) - root(300.0);                    // rooting b^2 and 4ac apart
    let m1 = [(-20.0 - 10.0) / 10.0, (-20.0 + 10.0) / 10.0];  // the minus on -b dropped
    let m2 = [20.0 - 10.0 / 10.0, 20.0 + 10.0 / 10.0];        // only the root over 2a
    let m3 = [(20.0 - split) / 10.0, (20.0 + split) / 10.0];
    println!("the three mistakes come out at:  {:.2} and {:.2}, {:.2} and {:.2}, {:.2} \
              and {:.2}", m1[0], m1[1], m2[0], m2[1], m3[0], m3[1]);
    assert!((r15[0] - 1.0).abs() < 1e-12 && (r15[1] - 3.0).abs() < 1e-12);
    assert!((sq[0] - 1.0).abs() < 1e-12 && (sq[1] - 3.0).abs() < 1e-12 && poly(r15[0]).abs() < 1e-12);
    assert!((r15[0] + r15[1] - 20.0 / 5.0).abs() < 1e-12 && (r15[0] * r15[1] - 15.0 / 5.0).abs() < 1e-12);
    assert_eq!([15i64, 20, 25].map(|h| formula(5, -20, h).0), [100, 0, -100]);
    println!("ALL CHECKS PASS");
}
