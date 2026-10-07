// Gronwall's inequality -- the same check as the Python, in Rust.  No crates.
// Two rumours in a 1,000-pupil school, P' = 0.8 P (1 - P/1000), started at 10
// and 11 pupils, t in days; two cups of coffee, T' = -0.1 (T - 20), poured at
// 80 C and 81 C, t in minutes.  Road one: the closed-form solutions.  Road two:
// Euler's small steps along the slope, which never call exp.  The bound is
// gap(0) * e^(L t).
const R: f64 = 0.8;
const K: f64 = 1000.0;
const L: f64 = 0.8;

fn rumour(p: f64) -> f64 { R * p * (1.0 - p / K) }
fn coffee(t: f64) -> f64 { -0.1 * (t - 20.0) }
fn closed_rumour(p0: f64, t: f64) -> f64 { K / (1.0 + (K / p0 - 1.0) * (-R * t).exp()) }
fn closed_coffee(t0: f64, t: f64) -> f64 { 20.0 + (t0 - 20.0) * (-0.1 * t).exp() }

fn euler(f: &dyn Fn(f64) -> f64, y0: f64, t: f64, h: f64) -> f64 {   // step along the slope
    let mut y = y0;
    for _ in 0..(t / h).round() as i64 { y += h * f(y) }
    y
}

fn gaps(f: &dyn Fn(f64) -> f64, a: f64, b: f64, times: &[f64], h: f64) -> Vec<f64> {
    times.iter().map(|&t| euler(f, b, t, h) - euler(f, a, t, h)).collect()
}

fn row(xs: &[f64], prec: usize) -> String {
    xs.iter().map(|x| format!("{:.*}", prec, x)).collect::<Vec<_>>().join(" ")
}

fn main() {
    let days: Vec<f64> = (0..11).map(|t| t as f64).collect();
    let closed: Vec<f64> = days.iter().map(|&t| closed_rumour(11.0, t) - closed_rumour(10.0, t)).collect();
    let stepped = gaps(&rumour, 10.0, 11.0, &days, 0.001);
    let bound: Vec<f64> = days.iter().map(|&t| (L * t).exp()).collect();
    let slopes: Vec<f64> = (0..201).map(|i| { let p = 5.0 * i as f64; (rumour(p + 1e-4) - rumour(p - 1e-4)).abs() / 2e-4 }).collect();
    let lmax = slopes.iter().cloned().fold(0.0, f64::max);
    let err: Vec<f64> = [0.02, 0.01, 0.005].iter().map(|&h| gaps(&rumour, 10.0, 11.0, &[6.0], h)[0] - closed[6]).collect();
    let cup = [0.0, 10.0, 30.0, 60.0];
    let cup_closed: Vec<f64> = cup.iter().map(|&t| closed_coffee(81.0, t) - closed_coffee(80.0, t)).collect();
    let cup_step = gaps(&coffee, 80.0, 81.0, &cup, 0.001);
    let crude: Vec<f64> = cup.iter().map(|&t| (0.1 * t).exp()).collect();
    let wide = |i: usize| closed_rumour(11.0, i as f64 / 100.0) - closed_rumour(10.0, i as f64 / 100.0);
    let top = (0..1101).fold(0, |b, i| if wide(i) > wide(b) { i } else { b });
    println!("rumours from 10 and 11 pupils, P' = 0.8 P (1 - P/1000), days 0 to 10");
    println!("largest slope |f'(P)| on 0..1000 by differences: L = {:.6} per day", lmax);
    println!("gap, closed form:  {}", row(&closed, 2));
    println!("gap, Euler h=0.001: {}", row(&stepped, 2));
    println!("bound e^(0.8 t):   {}", row(&bound, 2));
    println!("bound passes 1000 pupils at day ln(1000)/0.8 = {:.2}", K.ln() / L);
    println!("widest gap: {:.2} pupils at day {:.2}", wide(top), top as f64 / 100.0);
    println!("Euler gap error at day 6, h = 0.02, 0.01, 0.005: {}", row(&err, 4));
    println!("coffee from 80 and 81 C, minutes 0, 10, 30, 60");
    println!("gap, closed e^(-0.1 t): {}", row(&cup_closed, 4));
    println!("gap, Euler h=0.001:     {}", row(&cup_step, 4));
    println!("crude bound e^(0.1 t):  {}", row(&crude, 4));
    let (z, t) = (1.01_f64, 0.98_f64);                          // y' = y^2: L = 2 read at the start
    println!("y' = y^2 from 1 and 1.01 at t = 0.98: gap {:.2}, start-slope bound {:.4}", 1.0 / (1.0 / z - t) - 1.0 / (1.0 - t), 0.01 * (2.0 * t).exp());
    let back = |q: f64| 0.2 * q.sqrt();                       // the bucket run backwards from empty
    let g2 = |s: f64| (0.1 * s).powi(2);                       // its second solution besides g = 0
    let fd: Vec<f64> = [10.0, 30.0, 50.0].iter().map(|&s| (g2(s + 1e-3) - g2(s - 1e-3)) / 2e-3).collect();
    println!("bucket reversed, g' = 0.2 sqrt(g), g(0) = 0: g = 0 or (0.1 s)^2 = {:.2} at s = 50", g2(50.0));
    println!("slope of (0.1 s)^2 at s = 30: differences {:.4}, law 0.2 sqrt(g) = {:.4}; Euler from 0 stays at {:.2}", fd[1], back(g2(30.0)), euler(&back, 0.0, 50.0, 0.01));
    assert!((lmax - L).abs() < 1e-6);                                               // L found by scanning
    assert!((0..11).all(|i| (closed[i] - stepped[i]).abs() < 0.05 && stepped[i] <= bound[i]));   // two roads; the theorem
    assert!((0..4).all(|i| (cup_closed[i] - cup_step[i]).abs() < 1e-4 && cup_closed[i] <= 1.0));   // coffee within 1 C
    assert!([10.0, 30.0, 50.0].iter().zip(&fd).all(|(&s, &d)| (d - back(g2(s))).abs() < 1e-6) && err[0] / err[1] > 1.9 && err[0] / err[1] < 2.1);   // second solution; order one
    println!("ALL CHECKS PASS");
}
