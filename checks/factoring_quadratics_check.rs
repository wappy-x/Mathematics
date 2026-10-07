// Factoring quadratics -- the same check as the Python, in Rust.  No crates.
// A football kicked straight up at 20 m/s stands 20t - 5t^2 metres high after
// t seconds.  A square slab x metres a side, trimmed 5 m one way and 6 m the
// other, leaves x^2 - 11x + 30 square metres.  Each is worked two ways: the
// sum form term by term, and the product form with the brackets multiplied.
fn height_sum(t: f64) -> f64 { 20.0 * t - 5.0 * t * t }   // the football, as a sum
fn height_prod(t: f64) -> f64 { 5.0 * t * (4.0 - t) }     // the same, as a product
fn patio_sum(x: i64) -> i64 { x * x - 11 * x + 30 }       // the slab, as a sum
fn patio_prod(x: i64) -> i64 { (x - 5) * (x - 6) }        // the same, as a product

fn pairs(c: i64) -> Vec<(i64, i64)> {                     // whole-number pairs multiplying to c
    let mut out: Vec<(i64, i64)> = Vec::new();
    let mut d: i64 = 1;
    while d <= c.abs() {
        if c % d == 0 && d * d <= c.abs() { out.push((d, c / d)); }
        d += 1;
    }
    out
}

fn brackets(b: i64, c: i64) -> Option<(i64, i64)> {       // hunt p, q with p + q = b and p * q = c
    for (d, e) in pairs(c) {
        for (p, q) in [(d, e), (-d, -e)] {
            if p + q == b { return Some((p, q)); }
        }
    }
    None
}

fn main() {
    let times: Vec<f64> = (0..9).map(|i| i as f64 / 2.0).collect();   // 0.0, 0.5, ... 4.0 seconds
    let hs: Vec<String> = times.iter().map(|&t| format!("{:.2}", height_sum(t))).collect();
    println!("football height 20t - 5t^2, t = 0.0 to 4.0 in half seconds: {}", hs.join(" "));
    let same = times.iter().filter(|&&t| height_sum(t) == height_prod(t)).count();
    println!("sum and product forms agree at all {} of those times", same);
    println!("20t - 5t^2 = 5t(4 - t), so the factors vanish at t = 0 and t = 4");
    let ps: Vec<String> = pairs(30).iter().map(|(d, e)| format!("{} and {}", d, e)).collect();
    println!("whole-number pairs multiplying to 30: {}", ps.join(", "));
    let (p, q) = brackets(-11, 30).expect("x^2 - 11x + 30 must factor");
    println!("the pair adding to -11 is {} and {}, so x^2 - 11x + 30 = (x - {})(x - {})", p, q, -p, -q);
    println!("the brackets vanish at x = {} and x = {}", -p, -q);
    let agree = (-4..16).filter(|&x| patio_sum(x) == patio_prod(x)).count();
    println!("sum and product forms agree at all {} whole x from -4 to 15", agree);
    println!("patio at x = 11: sum form {}, product form 6 * 5 = {}", patio_sum(11), patio_prod(11));
    println!("pond patio at x = 11: x^2 - 9 gives {}, (x + 3)(x - 3) gives 14 * 8 = {}",
             11 * 11 - 9, (11 + 3) * (11 - 3));
    println!("{}", if brackets(0, 9).is_none() { "x^2 + 9: no whole-number pair, so no brackets" }
                   else { "x^2 + 9 factors, which cannot happen" });
    println!("the four mistakes come out at {}, {}, {} and {}",
             patio_sum(35), (11 - 3) * (11 - 10), (11 + 3) * (11 - 3), 5 * (4 - 2));
    println!("against the right answers {}, {}, {} and {}",
             patio_sum(0), patio_sum(11), 11 * 11 + 9, height_sum(2.0) as i64);
    assert!(brackets(-11, 30) == Some((-5, -6)) && p + q == -11 && p * q == 30);
    assert!(agree == 20 && same == 9);
    assert!(height_sum(0.0) == 0.0 && height_sum(4.0) == 0.0 && height_sum(2.0) == 20.0);
    assert!(brackets(0, 9).is_none() && patio_sum(0) == 30 && patio_sum(5) == 0 && patio_sum(6) == 0);
    println!("ALL CHECKS PASS");
}
