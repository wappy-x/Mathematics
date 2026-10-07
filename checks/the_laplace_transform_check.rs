// The Laplace transform -- the same check as the Python, in Rust.  No crates.
// Road one: the table, F(s) read off a formula.  Road two: the defining
// integral of e^(-st) f(t), summed by Simpson's rule written out here and
// cut off where the weight has faded to e^(-40).
use std::f64::consts::PI;
const S: f64 = 0.05; // discount rate per year
const B: f64 = 2.0 * PI; // one seasonal cycle a year

fn simpson(g: &dyn Fn(f64) -> f64, t_end: f64, n: usize) -> f64 {
    let h = t_end / n as f64;
    let mut total = g(0.0) + g(t_end);
    for k in 1..n {
        total += if k % 2 == 1 { 4.0 } else { 2.0 } * g(k as f64 * h);
    }
    total * h / 3.0
}
fn laplace(f: &dyn Fn(f64) -> f64, s: f64, a: f64) -> f64 {
    simpson(&|t: f64| f(t) * (-s * t).exp(), 40.0 / (s - a), 200000)
}
fn pv_to(f: &dyn Fn(f64) -> f64, s: f64, t_end: f64) -> f64 {
    if t_end == 0.0 { 0.0 } else { simpson(&|t: f64| f(t) * (-s * t).exp(), t_end, 2000) }
}
fn sci(v: f64) -> String {
    let e = v.abs().log10().floor() as i32;
    format!("{:.4}e+{:02}", v / 10f64.powi(e), e)
}

fn main() {
    let rows: [(&str, fn(f64) -> f64, f64, f64); 5] = [
        ("1", |_t| 1.0, 1.0 / S, 0.0),
        ("t", |t| t, 1.0 / (S * S), 0.0),
        ("e^(0.03t)", |t| (0.03 * t).exp(), 1.0 / (S - 0.03), 0.03),
        ("cos(2 pi t)", |t| (B * t).cos(), S / (S * S + B * B), 0.0),
        ("sin(2 pi t)", |t| (B * t).sin(), B / (S * S + B * B), 0.0),
    ];
    println!("s = {} per year: table F(s) against the integral, summed", S);
    let mut worst: f64 = 0.0;
    for (name, f, table, a) in rows.iter() {
        let num = laplace(f, S, *a);
        worst = worst.max((num - table).abs() / table);
        println!("{:12} table {:.8}   integral {:.8}", name, table, num);
    }
    let (level, growing) = (1000.0 * rows[0].2, 1000.0 * rows[2].2);
    println!("level 1000/s = {:.2} dollars; growing 1000 e^(0.03t): {:.2} dollars", level, growing);
    let mix_t = 1000.0 / S + 400.0 * rows[3].2;
    let mix_n = laplace(&|t: f64| 1000.0 + 400.0 * (B * t).cos(), S, 0.0);
    println!("linearity, 1000 + 400 cos(2 pi t): table {:.4}   integral {:.4}", mix_t, mix_n);
    let d_exp = laplace(&|t: f64| 0.03 * (0.03 * t).exp(), S, 0.03);
    let d_cos = laplace(&|t: f64| -B * (B * t).sin(), S, 0.0);
    println!("rate rule, e^(0.03t): L[f'] = {:.8}   s F - f(0) = {:.8}", d_exp, S * rows[2].2 - 1.0);
    println!("rate rule, cos(2 pi t): L[f'] = {:.8}   s F - f(0) = {:.8}", d_cos, S * rows[3].2 - 1.0);
    let grow = |t: f64| 1000.0 * (0.03 * t).exp();
    let level_f = |_t: f64| 1000.0;
    let series: [(&str, &dyn Fn(f64) -> f64, f64); 3] =
        [("level at 5%", &level_f, S), ("growing at 5%", &grow, S), ("growing at 3%", &grow, 0.03)];
    for (label, f, s) in series.iter() {
        let pts: Vec<String> = (0..11).map(|k| format!("{:.0}", pv_to(*f, *s, 10.0 * k as f64))).collect();
        println!("chart, {}: {}", label, pts.join(" "));
    }
    let stall = [pv_to(&grow, 0.03, 100.0), pv_to(&grow, 0.03, 200.0)];
    println!("mistake 1, growing stream at s = 0.03: {:.0} by year 100, {:.0} by year 200", stall[0], stall[1]);
    println!("mistake 2, sign slip 1000/(s + 0.03) = {:.2}, not {:.2}", 1000.0 / (S + 0.03), growing);
    println!("mistake 3, sine for cosine: 400 x {:.6} = {:.4}, not {:.4}", rows[4].2, 400.0 * rows[4].2, 400.0 * rows[3].2);
    let sq: Vec<String> = [2.0, 4.0, 6.0].iter()
        .map(|&te| sci(simpson(&|t: f64| (t * t - S * t).exp(), te, 200000))).collect();
    println!("mistake 4, e^(t^2) at s = 0.05, integral to T = 2, 4, 6: {}", sq.join("  "));
    assert!(worst < 1e-7); // table = integral, five signals
    assert!((mix_n - mix_t).abs() < 1e-6); // linearity: the sum transforms as the sum
    assert!((d_exp - (S * rows[2].2 - 1.0)).abs().max((d_cos - (S * rows[3].2 - 1.0)).abs()) < 1e-7);
    assert!(stall[1] - stall[0] > 99000.0); // no limit when s does not beat the growth
    println!("ALL CHECKS PASS");
}
