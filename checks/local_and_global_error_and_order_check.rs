// Order of a method -- the same check as the Python, in Rust.  No crates.
// The skydiver: v' = 9.8 - 0.2 v, v(0) = 0, exact v = 49 (1 - e^(-0.2 t)).
// Road one steps the rate law in a loop; road two uses each method's closed form.
const G: f64 = 9.8; const K: f64 = 0.2; const T: f64 = 10.0;   // m/s^2, 1/s, s
const TO: f64 = 4.3; const K2: f64 = 0.98;                        // parachute opens at 4.3 s

type Rate = fn(f64, f64) -> f64;
fn exact(t: f64) -> f64 { G / K * (1.0 - (-K * t).exp()) }
fn rate(_t: f64, v: f64) -> f64 { G - K * v }
fn chute(t: f64, v: f64) -> f64 { G - (if t < TO { K } else { K2 }) * v }
fn euler(f: Rate, t: f64, v: f64, h: f64) -> f64 { v + h * f(t, v) }
fn rk4(f: Rate, t: f64, v: f64, h: f64) -> f64 {
    let k1 = f(t, v); let k2 = f(t + h / 2.0, v + h / 2.0 * k1);
    let k3 = f(t + h / 2.0, v + h / 2.0 * k2); let k4 = f(t + h, v + h * k3);
    v + h / 6.0 * (k1 + 2.0 * k2 + 2.0 * k3 + k4)
}
fn run(step: fn(Rate, f64, f64, f64) -> f64, f: Rate, h: f64) -> f64 {   // road one
    let mut v = 0.0;
    for n in 0..(T / h).round() as i32 { v = step(f, n as f64 * h, v, h) }
    v
}
fn closed(factor: f64, h: f64) -> f64 { G / K * (1.0 - factor.powi((T / h).round() as i32)) }  // road two
fn r4(z: f64) -> f64 { 1.0 + z + z * z / 2.0 + z.powi(3) / 6.0 + z.powi(4) / 24.0 }
fn order(e: &[f64]) -> Vec<f64> { (0..e.len() - 1).map(|i| (e[i] / e[i + 1]).log2()).collect() }

fn main() {
    let hs = [2.0, 1.0, 0.5];
    let (vt, m) = (exact(T), K * G);                              // m = size of v'' at t = 0
    println!("skydiver v' = 9.8 - 0.2v from rest; terminal {:.1} m/s; exact v(10) = {:.4} m/s", G / K, vt);
    let mut loc = vec![];
    for h in [1.0, 0.5] {
        loc.push(euler(rate, 0.0, 0.0, h) - exact(h));
        println!("one step h = {:.1}: Euler {:.4}, exact {:.4}, local error {:.4}, Taylor h^2/2 x 1.96 = {:.4}",
                 h, h * G, exact(h), loc[loc.len() - 1], h * h / 2.0 * m);
    }
    println!("local error ratio h = 1 over h = 0.5: {:.2}", loc[0] / loc[1]);
    let (mut ee, mut er, mut pred) = (vec![], vec![], vec![]);
    for h in hs {
        ee.push(run(euler, rate, h) - vt); er.push((run(rk4, rate, h) - vt).abs());
        pred.push(T / 2.0 * m * (-K * T).exp() * h);
        println!("Euler h = {:.1}: v(10) = {:.4}, closed form {:.4}, error {:.4}, predicted {:.4}",
                 h, run(euler, rate, h), closed(1.0 - K * h, h), ee[ee.len() - 1], pred[pred.len() - 1]);
    }
    for (i, h) in hs.iter().enumerate() {
        println!("RK4 h = {:.1}: v(10) = {:.7}, closed form {:.7}, error {:.7}",
                 h, run(rk4, rate, *h), closed(r4(-K * h), *h), er[i]);
    }
    let (po, pr) = (order(&ee), order(&er));
    println!("order estimates, Euler: {:.2}, {:.2}; RK4: {:.2}, {:.2}", po[0], po[1], pr[0], pr[1]);
    println!("error ratios per halving, RK4: {:.1}, {:.1}", er[0] / er[1], er[1] / er[2]);
    println!("general bound (M/2L)(e^(LT) - 1) = {:.2} per unit h", m / (2.0 * K) * ((K * T).exp() - 1.0));
    println!("chart, Euler error / h: {:.2}, {:.2}, {:.2}; prediction / h: {:.2}",
             ee[2] / hs[2], ee[1] / hs[1], ee[0] / hs[0], pred[0] / hs[0]);
    println!("mistake 1, local order 2 read as global: h = 1 guessed {:.4}, actual {:.4}", ee[0] / 4.0, ee[1]);
    let big: Vec<f64> = [10.0, 5.0].iter().map(|&h| (run(euler, rate, h) - vt).abs()).collect();
    println!("mistake 2, h = 10 and 5: errors {:.4}, {:.4}, order estimate {:.2}", big[0], big[1], order(&big)[0]);
    let v2 = G / K2 + (exact(TO) - G / K2) * (-K2 * (T - TO)).exp();
    let ec: Vec<f64> = hs.iter().map(|&h| (run(rk4, chute, h) - v2).abs()).collect();
    let oc = order(&ec);
    println!("mistake 3, parachute at 4.3 s, exact v(10) = {:.4}: RK4 errors {:.4}, {:.4}, {:.4}; estimates {:.2}, {:.2}",
             v2, ec[0], ec[1], ec[2], oc[0], oc[1]);
    for h in hs {                                                                // two roads agree
        assert!((run(euler, rate, h) - closed(1.0 - K * h, h)).abs()
                + (run(rk4, rate, h) - closed(r4(-K * h), h)).abs() < 1e-9 * vt);
    }
    for (h, e) in [1.0, 0.5].iter().zip(&loc) { assert!(h * h / 2.0 * m * (-K * h).exp() < *e && *e < h * h / 2.0 * m) }
    assert!(po.iter().all(|p| 0.9 < *p && *p < 1.1) && pr.iter().all(|p| 3.9 < *p && *p < 4.4));  // orders 1, 4
    assert!(ee.iter().zip(&pred).all(|(e, p)| (e / p - 1.0).abs() < 0.07));
    println!("ALL CHECKS PASS");
}
