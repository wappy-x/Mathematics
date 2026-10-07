// Continuity -- the same check as the Python, in Rust, std only.  Two roads
// each time: a simulated meter against the fare formula, and a brute-force
// search for the widest safe window against the recipe the proofs give.
fn s(d: f64) -> f64 { 3.0 + 2.0 * d.ceil() }          // stepped fare, by formula
fn m(d: f64) -> f64 { 3.0 + 2.0 * d }                  // metered fare
fn meter(d: f64) -> f64 {                              // stepped fare, by driving
    let mut fare = 3.0;                                // $3 at the kerb, then metre by metre
    for k in 1..=((d * 1000.0).round() as i64) {
        if k % 1000 == 1 { fare += 2.0; }              // a new kilometre starts
    }
    fare
}
fn widest(f: &dyn Fn(f64) -> f64, a: f64, tol: f64) -> f64 {
    let ok = |w: f64| (1..=200).all(|k| [-1.0, 1.0].iter().all(|sg: &f64|
        (f(a + sg * w * k as f64 / 200.0) - f(a)).abs() < tol));
    let (mut lo, mut hi) = (0.0, 1.0);
    for _ in 0..60 {                                   // bisection on the width
        let mid = (lo + hi) / 2.0;
        if ok(mid) { lo = mid } else { hi = mid }
    }
    lo
}
fn join(v: Vec<String>) -> String { v.join(", ") }
fn main() {
    let ds = [0.0, 0.4, 1.0, 1.001, 2.0, 2.5, 3.2];
    println!("setup: $3 at the kerb, $2 per km (started, or metered); cab 0.5 km a minute; waiting 0.25 a minute; surge 1 + 0.05 t");
    for (name, f) in [("formula", s as fn(f64) -> f64), ("driving", meter)] {
        println!("stepped fare by {} at 0, 0.4, 1, 1.001, 2, 2.5, 3.2 km: {}", name,
                 join(ds.iter().map(|&d| format!("{}", f(d))).collect()));
    }
    for a in [1.0, 2.0] {
        println!("at {} km: from the left {:.2}, value {:.2}, from the right {:.2}, jump {:.2}",
                 a, s(a - 1e-9), s(a), s(a + 1e-9), s(a + 1e-9) - s(a - 1e-9));
    }
    println!("stepped fare at 1.1, 1.01, 1.001 km: {}", join([0.1, 0.01, 0.001].iter().map(|h| format!("{}", s(1.0 + h))).collect()));
    let blank = |d: f64| if d == 2.0 { 0.0 } else { m(d) };  // a meter that blanks at 2 km
    println!("blanking meter at 2 km: from the left {:.2}, value {:.2}, from the right {:.2}",
             blank(2.0 - 1e-9), blank(2.0), blank(2.0 + 1e-9));
    println!("metered price per km at 0.1, 0.01, 0.001 km: {}", join([0.1, 0.01, 0.001].iter().map(|h| format!("{:.2}", m(*h) / h)).collect()));
    let (w_m, w_s) = (widest(&m, 2.0, 0.01), widest(&s, 1.0, 1.0));
    println!("metered fare at 2 km, within $0.01: recipe {:.6} km, widest {:.6} km", 0.01 / 2.0, w_m);
    println!("stepped fare at 1 km, within $1: some window works: {}; fare at 1.000000001 km is {}",
             if w_s > 1e-12 { "yes" } else { "no" }, s(1.000000001));
    let fare_t = |t: f64| m(0.5 * t);                  // the cab covers 0.5 km a minute
    let total = |t: f64| fare_t(t) + 0.25 * t;         // plus 25 cents a minute waiting
    let surge = |t: f64| 1.0 + 0.05 * t;               // a multiplier rising 5% a minute
    let prod = |t: f64| fare_t(t) * surge(t);
    let eta = 0.01 / (fare_t(4.0) + surge(4.0) + 1.0); // the product proof's recipe
    let q = |c: f64| (-1.15 + (1.15f64.powi(2) - 0.2 * (3.0 - c)).sqrt()) / 0.1;  // 0.05t^2 + 1.15t + 3 = c
    let w_q = (q(8.41) - 4.0).min(4.0 - q(8.39));      // the exact widest window
    let rows: [(&str, &dyn Fn(f64) -> f64, f64); 3] = [("composition 3 + t", &fare_t, 0.01 / 2.0 / 0.5),
        ("sum 3 + 1.25 t", &total, 0.005f64.min(0.005 / 0.25)), ("product (3 + t)(1 + 0.05 t)", &prod, eta.min(eta / 0.05))];
    println!("sum recipe: fare within $0.005 needs {:.6} min, waiting within $0.005 needs {:.6} min", 0.005, 0.005 / 0.25);
    println!("product recipe: 0.01 / ({:.2} + {:.2} + 1) = {:.6} min; whole tolerance to each part instead: {:.6} min",
             fare_t(4.0), surge(4.0), eta, 0.01f64.min(0.01 / 0.05));
    let wide: Vec<f64> = rows.iter().map(|r| widest(r.1, 4.0, 0.01)).collect();
    for (r, w) in rows.iter().zip(&wide) {
        println!("{} at 4 min = {:.2}; recipe {:.6} min, widest {:.6} min", r.0, (r.1)(4.0), r.2, w);
    }
    println!("product widest window by the quadratic formula: {:.6} min", w_q);
    println!("stepped fare over time at 4 min: {}, a moment later {}", s(0.5 * 4.0), s(0.5 * 4.000001));
    let (x, y) = (|d: f64| 40.0 + 80.0 * d, |f: f64| 210.0 - 16.0 * f);
    println!("figure, 80 px per km, 16 px per dollar; step tops at y = {}; meter line ({:.0}, {:.0}) to ({:.0}, {:.0})",
             join([1.0, 2.0, 3.0, 4.0].iter().map(|&k| format!("{:.0}", y(s(k)))).collect()), x(0.0), y(m(0.0)), x(3.5), y(m(3.5)));
    assert!(ds.iter().all(|&d| meter(d) == s(d)));                        // driving = formula
    assert!((w_m - 0.01 / 2.0).abs() < 1e-9 && w_s < 1e-12);              // continuous vs jump
    assert!(rows.iter().zip(&wide).all(|(r, w)| r.2 <= w + 1e-12));      // recipes are safe
    assert!((wide[2] - w_q).abs() < 1e-9);                                // two roads agree
    println!("ALL CHECKS PASS");
}
