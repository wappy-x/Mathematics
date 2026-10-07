// Logistic growth -- the same check as the Python, in Rust.  No crates.  A
// rumour in a 1,000-pupil school: P' = 0.8 P (1 - P/1000), P pupils who have
// heard it, t in days, 10 pupils on day 0.  Road one is the closed form; road
// two steps along the slope; road three is the area under 1/rate, the
// separated equation integrated with no partial fractions.
const R: f64 = 0.8;
const K: f64 = 1000.0;
const P0: f64 = 10.0;

fn rate(p: f64) -> f64 { R * p * (1.0 - p / K) }            // the right-hand side

fn closed(p0: f64, t: f64) -> f64 { K / (1.0 + (K / p0 - 1.0) * (-R * t).exp()) }

fn euler(p0: f64, t: f64, h: f64) -> f64 {                   // small steps along the slope
    let mut p = p0;
    for _ in 0..(t / h).round() as i64 { p += h * rate(p) }
    p
}

fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 {   // area under f
    let h = (b - a) / n as f64;
    let inner: f64 = (1..n).map(|i| (if i % 2 == 1 { 4.0 } else { 2.0 }) * f(a + i as f64 * h)).sum();
    (f(a) + f(b) + inner) * h / 3.0
}

fn slope(p: f64) -> f64 { let d = 1e-4; (rate(p + d) - rate(p - d)) / (2.0 * d) }   // f' by differences

fn row(xs: &[f64], prec: usize) -> String {
    xs.iter().map(|x| format!("{:.*}", prec, x)).collect::<Vec<_>>().join(" ")
}

fn main() {
    let a = K / P0 - 1.0;
    let t_half = a.ln() / R;
    let area = simpson(&|p| 1.0 / rate(p), P0, K / 2.0, 20000);
    let (mut p, mut n) = (P0, 0);
    while p < K / 2.0 { p += 0.001 * rate(p); n += 1 }        // step until half the school
    let err: Vec<f64> = [0.1, 0.05, 0.025].iter().map(|&h| euler(P0, 6.0, h) - closed(P0, 6.0)).collect();
    let mut coarse = vec![P0];
    for _ in 0..6 { let q = *coarse.last().unwrap(); coarse.push(q + 3.0 * rate(q)) }
    let c10: Vec<f64> = (0..13).map(|t| closed(P0, t as f64)).collect();
    let c1500: Vec<f64> = (0..13).map(|t| closed(1500.0, t as f64)).collect();
    let a_wrong = (K / 1500.0 - 1.0).abs();
    println!("rate law P' = 0.8 P (1 - P/1000), pupils and days; A = K/P0 - 1 = {:.0}", a);
    println!("rests: rate at 0 = {:.2}, at 1000 = {:.2}; slope there {:+.6} and {:+.6} per day", rate(0.0), rate(K), slope(0.0), slope(K));
    println!("phase line signs: rate at 10 = {:.2}, at 500 = {:.2} (up, the fastest), at 1250 = {:.2} (down)", rate(10.0), rate(500.0), rate(1250.0));
    println!("half the school, closed form ln(99)/0.8 = {:.6}/0.8: {:.6} days", a.ln(), t_half);
    println!("half the school, area under 1/rate from 10 to 500: {:.6} days", area);
    println!("half the school, Euler h = 0.001: {:.3} days", n as f64 * 0.001);
    println!("chart, from 10, days 0 to 12: {}", row(&c10, 0));
    println!("chart, from 1500, days 0 to 12: {}", row(&c1500, 0));
    println!("day 6 from 10: 99 e^(-4.8) = {:.4}; closed {:.2}, Euler h = 0.001 {:.2}", a * (-4.8f64).exp(), closed(P0, 6.0), euler(P0, 6.0, 0.001));
    println!("day 2 from 1500: A = {:.4}, 1 + A = {:.4}; closed {:.2}, Euler h = 0.001 {:.2}", K / 1500.0 - 1.0, K / 1500.0, closed(1500.0, 2.0), euler(1500.0, 2.0, 0.001));
    println!("Euler error at day 6, h = 0.1, 0.05, 0.025: {}", row(&err, 4));
    println!("never everyone: 999 pupils at day {:.2}; day 20 gives {:.3}", (a * 999.0).ln() / R, closed(P0, 20.0));
    println!("mistake 1, no crowding factor: 10 e^(0.8 t) at day 5.74 = {:.2}, at day 7 = {:.2}", P0 * (R * t_half).exp(), P0 * (R * 7.0).exp());
    println!("mistake 2, sign of A dropped from 1500: A = {:.4}, P(0) = {:.2}", a_wrong, K / (1.0 + a_wrong));
    println!("mistake 3, Euler h = 3 days from 10: {}", row(&coarse, 2));
    let x = |q: f64| 40.0 + 0.24 * q;                         // 0.24 per pupil
    let y = |q: f64| 110.0 - 0.4 * rate(q);                   // 0.4 per pupil/day
    println!("figure, axis y = 110; rests at x = {:.1} and {:.1}; top at ({:.1}, {:.1})", x(0.0), x(K), x(500.0), y(500.0));
    let pts: Vec<String> = (0..11).map(|i| { let q = 125.0 * i as f64; format!("{:.1},{:.1}", x(q), y(q)) }).collect();
    println!("figure, rate curve: {}", pts.join(" "));
    assert!((area - 99f64.ln() / 0.8).abs() < 1e-6);                        // separation, two ways
    assert!((n as f64 * 0.001 - t_half).abs() < 0.01 && err[0] / err[1] > 1.9 && err[0] / err[1] < 2.1);
    assert!((slope(0.0) - R).abs() < 1e-6 && (slope(K) + R).abs() < 1e-6);  // 0 repels, K attracts
    let e1500 = euler(1500.0, 2.0, 0.001);
    assert!(e1500 > 1000.0 && e1500 < 1500.0 && (e1500 - closed(1500.0, 2.0)).abs() < 0.5);
    println!("ALL CHECKS PASS");
}
