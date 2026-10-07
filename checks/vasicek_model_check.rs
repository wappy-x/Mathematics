// Vasicek model -- the same check as vasicek_model_check.py, in Rust.  No crates.
// Short rate r pulled toward level th at speed a, with volatility s:
//   dr = a (th - r) dt + s dW.   House example: a = 0.3, th = 5%, s = 1%, r0 = 4%.
// The 5-year zero is priced four ways that share no code: the closed form,
// the Gaussian integral of the rate, the bond equation solved as two ODEs by
// Runge-Kutta, and simulated rate paths.  The normal CDF and the random
// numbers are written here.
use std::f64::consts::PI;

const A_: f64 = 0.3;
const TH: f64 = 0.05;
const S_: f64 = 0.01;
const R0: f64 = 0.04;
const T: f64 = 5.0;

fn closed_g(r0: f64, t: f64, a: f64, s: f64) -> f64 {  // road 1: P = exp(lnA - B r0)
    let b = (1.0 - (-a * t).exp()) / a;
    let ln_a = (TH - s * s / (2.0 * a * a)) * (b - t) - s * s * b * b / (4.0 * a);
    (ln_a - b * r0).exp()
}
fn closed(r0: f64, t: f64) -> f64 { closed_g(r0, t, A_, S_) }

fn integral_moments(r0: f64, t: f64) -> (f64, f64) {  // mean and variance of the area under r
    let b = (1.0 - (-A_ * t).exp()) / A_;
    (TH * t + (r0 - TH) * b, S_ * S_ / (A_ * A_) * (t - b - A_ * b * b / 2.0))
}

fn by_moments(r0: f64, t: f64) -> f64 {                // road 2: E[exp(-I)] for a normal I
    let (m, v) = integral_moments(r0, t);
    (-m + v / 2.0).exp()
}

fn by_ode(r0: f64, t: f64, n: usize) -> (f64, f64) {    // road 3: B' = 1 - aB, lnA' = -a th B + s^2 B^2 / 2
    let f = |y: (f64, f64)| (1.0 - A_ * y.0, -A_ * TH * y.0 + S_ * S_ * y.0 * y.0 / 2.0);
    let (mut y, h) = ((0.0f64, 0.0f64), t / n as f64);
    for _ in 0..n {
        let k1 = f(y);
        let k2 = f((y.0 + h / 2.0 * k1.0, y.1 + h / 2.0 * k1.1));
        let k3 = f((y.0 + h / 2.0 * k2.0, y.1 + h / 2.0 * k2.1));
        let k4 = f((y.0 + h * k3.0, y.1 + h * k3.1));
        y = (y.0 + h / 6.0 * (k1.0 + 2.0 * k2.0 + 2.0 * k3.0 + k4.0),
             y.1 + h / 6.0 * (k1.1 + 2.0 * k2.1 + 2.0 * k3.1 + k4.1));
    }
    ((y.1 - y.0 * r0).exp(), y.0)
}

struct Rng(u64);
impl Rng {
    fn uniform(&mut self) -> f64 {                      // splitmix64, written out
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        (((z ^ (z >> 31)) >> 11) + 1) as f64 / 9007199254740992.0
    }
    fn normal(&mut self) -> f64 {                       // Box-Muller, cosine half
        let u1 = self.uniform();
        let u2 = self.uniform();
        (-2.0 * u1.ln()).sqrt() * (2.0 * PI * u2).cos()
    }
}

fn by_paths(rng: &mut Rng, r0: f64, t: f64, pairs: usize, steps: usize) -> (f64, f64) {  // road 4
    let dt = t / steps as f64;
    let (decay, sd) = ((-A_ * dt).exp(), S_ * ((1.0 - (-2.0 * A_ * dt).exp()) / (2.0 * A_)).sqrt());
    let mut vals = Vec::with_capacity(pairs);
    for _ in 0..pairs {
        let (mut rp, mut rm, mut ip, mut im) = (r0, r0, 0.0f64, 0.0f64);
        for _ in 0..steps {
            let z = rng.normal();
            let np = TH + (rp - TH) * decay + sd * z;
            let nm = TH + (rm - TH) * decay - sd * z;
            ip += (rp + np) / 2.0 * dt; im += (rm + nm) / 2.0 * dt; rp = np; rm = nm;
        }
        vals.push(((-ip).exp() + (-im).exp()) / 2.0);
    }
    let mut mean = 0.0; for x in &vals { mean += x; } mean /= pairs as f64;
    let mut ss = 0.0; for x in &vals { ss += (x - mean).powi(2); }
    (mean, (ss / (pairs - 1) as f64 / pairs as f64).sqrt())
}

fn ncdf(x: f64) -> f64 {                                // bell-curve area left of x, Simpson
    let n = 2000;
    let h = x / n as f64;
    let g = |u: f64| (-u * u / 2.0).exp() / (2.0 * PI).sqrt();
    let mut s = 0.0;
    for i in 1..n { s += (if i % 2 == 1 { 4.0 } else { 2.0 }) * g(i as f64 * h); }
    let tot = g(0.0) + g(x) + s;
    0.5 + tot * h / 3.0
}

fn rate_at(t: f64, s: f64) -> (f64, f64) {              // mean and sd of r_t
    (TH + (R0 - TH) * (-A_ * t).exp(), s * ((1.0 - (-2.0 * A_ * t).exp()) / (2.0 * A_)).sqrt())
}

fn yld(r0: f64, t: f64, s: f64) -> f64 {
    if t > 0.0 { 100.0 * (-closed_g(r0, t, A_, s).ln() / t) } else { 100.0 * r0 }
}

fn main() {
    let mut rng = Rng(20260928);
    let p1 = closed(R0, T); let p2 = by_moments(R0, T);
    let (p3, b_ode) = by_ode(R0, T, 1000); let (p4, se) = by_paths(&mut rng, R0, T, 4000, 250);
    let b = (1.0 - (-A_ * T).exp()) / A_;
    let (m, v) = integral_moments(R0, T);
    let h = 1e-4;
    let dur_bump = -(closed(R0 + h, T) - closed(R0 - h, T)) / (2.0 * h) / p1;
    let (mu5, sd5) = rate_at(T, S_); let (mu5b, sd5b) = rate_at(T, 0.02);
    let (neg_1, neg_2) = (ncdf(-mu5 / sd5), ncdf(-mu5b / sd5b));
    let draws = 200000;
    let mut neg_count = 0;
    for _ in 0..draws { if mu5b + sd5b * rng.normal() < 0.0 { neg_count += 1; } }
    let rows: Vec<(&str, f64)> = vec![
        ("e^(-aT)", (-A_ * T).exp()), ("B(5), rate sensitivity in years", b), ("B(5) from the ODE", b_ode),
        ("level part (th - s^2/2a^2)(B - T)", (TH - S_ * S_ / (2.0 * A_ * A_)) * (b - T)),
        ("spread part s^2 B^2 / 4a", S_ * S_ * b * b / (4.0 * A_)),
        ("A(5)", p1.ln() + b * R0), ("-B(5) r0", -b * R0), ("log of price", p1.ln()),
        ("mean of area under r, 0 to 5", m), ("variance of that area", v),
        ("1 closed form P(0,5)", p1), ("2 Gaussian integral", p2), ("3 Runge-Kutta ODE", p3),
        ("4 paths, 4000 antithetic pairs", p4), ("  standard error", se),
        ("5-year yield, percent", yld(R0, T, S_)), ("long yield, percent", 100.0 * (TH - S_ * S_ / (2.0 * A_ * A_))),
        ("5-year yield move per point of r0", b / T), ("bumped rate sensitivity", dur_bump),
        ("expected r at 5y, percent", 100.0 * mu5), ("sd of r at 5y, percent", 100.0 * sd5),
        ("P(r5 < 0), s = 1%, percent", 100.0 * neg_1), ("P(r5 < 0), s = 2%, percent", 100.0 * neg_2),
        ("  simulated, 200000 draws, percent", 100.0 * neg_count as f64 / draws as f64),
        ("3-month zero at r0 = -0.5%", closed(-0.005, 0.25)),
        ("wrong: flat at today's 4%", (-R0 * T).exp()), ("wrong: flat at the 5% level", (-TH * T).exp()),
        ("wrong: expected path, no convexity", (-m).exp()), ("wrong: convexity sign flipped", (-m - v / 2.0).exp()),
        ("wrong: no reversion, a -> 0", (-R0 * T + S_ * S_ * T.powi(3) / 6.0).exp()),
        ("30-year zero", closed(R0, 30.0)), ("  30-year, no convexity", (-integral_moments(R0, 30.0).0).exp()),
        ("try: a = 0.03", closed_g(R0, T, 0.03, S_)), ("try: s = 3%", closed_g(R0, T, A_, 0.03)),
        ("try: r0 = 8%", closed(0.08, T)), ("try: r0 = 0%", closed(0.0, T)),
    ];
    for (name, val) in &rows { println!("{:<36} {:>12.6}", name, val); }
    println!();
    println!("5-year zero by today's rate, percent: price");
    for r in [-1i32, 0, 2, 4, 6, 8] { println!("  r0 = {:>2}%   {:.4}", r, closed(r as f64 / 100.0, T)); }
    println!();
    let mats = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
    let head: String = mats.iter().map(|t| format!("{:>6}", t)).collect();
    println!("yield curve, percent{}", head);
    for r in [2, 4, 8] {
        let row: String = mats.iter().map(|&t| format!("{:6.2}", yld(r as f64 / 100.0, t as f64, S_))).collect();
        println!("  r0 = {}%, s = 1%    {}", r, row);
    }
    let humps = [0, 1, 2, 3, 4, 5, 6, 8, 10, 15, 20];
    let head: String = humps.iter().map(|t| format!("{:>6}", t)).collect();
    println!("hump, maturities   {}", head);
    let row: String = humps.iter().map(|&t| format!("{:6.2}", yld(0.045, t as f64, 0.03))).collect();
    println!("  r0 = 4.5%, s = 3%{}", row);

    assert!((p1 - p2).abs() < 1e-12, "closed form vs Gaussian integral");
    assert!((p1 - p3).abs() < 1e-10, "closed form vs Runge-Kutta on the bond equation");
    assert!((p4 - p1).abs() < 4.0 * se, "simulated paths within four standard errors");
    assert!((dur_bump - b_ode).abs() < 1e-6, "bumped sensitivity vs B from the ODE");
    assert!((neg_count as f64 / draws as f64 - neg_2).abs() < 0.002, "simulated negative-rate share vs normal CDF");
    println!("ALL CHECKS PASS");
}
