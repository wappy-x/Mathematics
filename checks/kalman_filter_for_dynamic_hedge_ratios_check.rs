// A moving hedge ratio -- the same check as the Python, in Rust.  No crates.
// The random numbers, the filter, the rolling regression and the tridiagonal
// solver are all written out below.
// Compile: rustc --edition 2021 -O kalman_filter_for_dynamic_hedge_ratios_check.rs
use std::f64::consts::PI;

struct Rng { s: u64 }                        // splitmix64, then Box-Muller for bell-curve draws
impl Rng {
    fn uniform(&mut self) -> f64 {
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
    fn normal(&mut self) -> f64 {
        let u1 = 1.0 - self.uniform();
        let u2 = self.uniform();
        (-2.0 * u1.ln()).sqrt() * (2.0 * PI * u2).cos()
    }
}

// road 1: predict, then update, one day at a time.  Rows are (estimate, P, weight, surprise).
fn kalman(a: &[f64], b: &[f64], m0: f64, p0: f64, q: f64, r: f64) -> Vec<(f64, f64, f64, f64)> {
    let (mut m, mut p) = (m0, p0);
    let mut out = Vec::new();
    for (&av, &bv) in a.iter().zip(b) {
        let pp = p + q;                      // predict: the ratio may have taken a step of variance Q
        let s = bv * bv * pp + r;            // variance of today's price surprise
        let k = pp * bv / s;                 // gain: change in the ratio per dollar of surprise
        let e = av - m * bv;                 // surprise: A's price minus the A price predicted
        m += k * e;
        p = pp * r / s;
        out.push((m, p, k * bv, e));
    }
    out
}

// road 2: one penalised regression over the whole path, tridiagonal normal equations
fn batch(a: &[f64], b: &[f64], m0: f64, p0: f64, q: f64, r: f64) -> f64 {
    let n = a.len();
    let mut diag = vec![1.0 / p0 + 1.0 / q];
    for bv in &b[..n - 1] { diag.push(2.0 / q + bv * bv / r); }
    diag.push(1.0 / q + b[n - 1].powi(2) / r);
    let mut rhs = vec![m0 / p0];
    for (av, bv) in a.iter().zip(b) { rhs.push(av * bv / r); }
    let off = -1.0 / q;
    for i in 1..=n {                         // Thomas algorithm: eliminate downwards,
        let f = off / diag[i - 1];
        diag[i] -= f * off;
        rhs[i] -= f * rhs[i - 1];
    }
    rhs[n] / diag[n]                         // and the last unknown is today's ratio
}

fn rolling(a: &[f64], b: &[f64], w: usize, t: usize) -> f64 {   // through zero, last w days, from day 1
    let first = if t + 1 > w { (t + 1 - w).max(1) } else { 1 };
    let num: f64 = (first..=t).map(|j| a[j] * b[j]).sum();
    let den: f64 = (first..=t).map(|j| b[j] * b[j]).sum();
    num / den
}

fn row(label: &str, vals: Vec<String>) { println!("{:<22}{}", label, vals.join(" ")); }

fn main() {
    // ---- hand example: B at $100 every day, prior 1.30, P0 = Q = 0.0001, R = 1 ----
    let (ha, hb) = ([129.0, 127.0, 126.0, 124.0], [100.0; 4]);
    let hand = kalman(&ha, &hb, 1.30, 1e-4, 1e-4, 1.0);
    let mut fib: Vec<u64> = vec![0, 1];
    for _ in 0..60 { let n = fib.len(); fib.push(fib[n - 1] + fib[n - 2]); }
    println!("hand example: B = $100 every day, prior 1.30, P0 = Q = 0.0001, R = 1");
    for (i, (&av, &(m, p, w, e))) in ha.iter().zip(hand.iter()).enumerate() {
        let d = i + 1;
        let win = &ha[d.saturating_sub(2)..d];
        let r2 = win.iter().sum::<f64>() / (100.0 * win.len() as f64);
        println!("  day {}  A {:6.2}  surprise {:+.4}  weight {:.6} = {}/{}  estimate {:.6}  P {:.8}  2-day {:.4}",
                 d, av, e, w, fib[2 * d + 1], fib[2 * d + 2], m, p, r2);
    }
    let hand_batch = batch(&ha, &hb, 1.30, 1e-4, 1e-4, 1.0);
    let w20 = kalman(&[130.0; 20], &[100.0; 20], 1.30, 1e-4, 1e-4, 1.0)[19].2;
    let golden = (5.0_f64.sqrt() - 1.0) / 2.0;
    println!("  day 4 by batch regression {:.6}", hand_batch);
    println!("  weight on day 20 {:.9};  (sqrt 5 - 1)/2 = {:.9}", w20, golden);

    // ---- the simulated year: B wanders from $100, true ratio slides 1.30 -> 1.10, A = ratio x B + $1 noise ----
    let mut rng = Rng { s: 20260928 };
    let (n, m0, p0, q, r) = (250usize, 1.30, 1e-4, 1e-6, 1.0);
    let beta: Vec<f64> = (0..=n).map(|t| 1.3 - 0.2 * t as f64 / n as f64).collect();
    let mut b = vec![100.0];
    for _ in 0..n { let last = b[b.len() - 1]; b.push(last + rng.normal()); }
    let a: Vec<f64> = (0..=n).map(|t| beta[t] * b[t] + rng.normal()).collect();
    let kf = kalman(&a[1..], &b[1..], m0, p0, q, r);
    let mut est = vec![m0];
    est.extend(kf.iter().map(|x| x.0));
    let road2 = (1..=n).map(|t| (batch(&a[1..t + 1], &b[1..t + 1], m0, p0, q, r) - est[t]).abs()).fold(0.0, f64::max);
    let stat = kalman(&a[1..], &b[1..], m0, p0, 0.0, r)[n - 1].0;
    let sab: f64 = a[1..].iter().zip(&b[1..]).map(|(x, y)| x * y).sum();
    let sbb: f64 = b[1..].iter().map(|y| y * y).sum();
    let closed = (m0 / p0 + sab / r) / (1.0 / p0 + sbb / r);
    let fixed = sab / sbb;
    let roll = |w: usize| -> Vec<f64> { (60..=n).map(|t| rolling(&a, &b, w, t)).collect() };
    let rmse = |path: &[f64]| -> f64 {
        (path.iter().enumerate().map(|(i, p)| (p - beta[60 + i]).powi(2)).sum::<f64>() / (n - 59) as f64).sqrt()
    };
    let roll60 = roll(60);
    println!("simulated year: prior {:.2}, P0 {:.4}, Q {:.6}, R {:.0}; B steps and A noise have sd $1", m0, p0, q, r);
    println!("  seed 20260928: B starts {:.2}, ends {:.2}; A starts {:.2}, ends {:.2}", b[0], b[n], a[0], a[n]);
    println!("  true ratio day 250           {:.6}", beta[n]);
    println!("  Kalman estimate day 250      {:.6}  plus or minus {:.6} (two sd)", est[n], 2.0 * kf[n - 1].1.sqrt());
    println!("  Kalman weight on day 250     {:.6}", kf[n - 1].2);
    println!("  rolling 60-day, day 250      {:.6}", roll60[roll60.len() - 1]);
    println!("  one fixed ratio, whole year  {:.6}", fixed);
    let (k, mean_e) = (kf[n - 1].2, kf.iter().map(|x| x.3).sum::<f64>() / n as f64);
    let drift = 0.2 / n as f64;
    println!("  lag rule, drift {:.4} a day: rolling 60 lags {:.6}; Kalman lags {:.6}", drift, drift * 59.0 / 2.0, drift * (1.0 - k) / k);
    println!("  Kalman surprise, mean over days 1 to 250: {:.4}; shrink factor 1 - weight = {:.6}", mean_e, 1.0 - k);
    println!("  road 2, batch regression vs filter, worst day: {:.2} x 10^-15", road2 * 1e15);
    println!("  Q = 0 filter {:.9};  expanding regression with prior {:.9}", stat, closed);
    println!("accuracy against the true ratio, days 60 to 250 (root mean square error)");
    let mut kf_rmse = Vec::new();
    for (qq, label) in [(0.0, "0"), (1e-7, "0.0000001"), (1e-6, "0.000001"), (1e-5, "0.00001"), (1e-4, "0.0001")] {
        let mut path = vec![m0];
        path.extend(kalman(&a[1..], &b[1..], m0, p0, qq, r).iter().map(|x| x.0));
        kf_rmse.push(rmse(&path[60..]));
        println!("  Kalman, Q = {:<10}      {:.6}", label, kf_rmse[kf_rmse.len() - 1]);
    }
    for w in [20usize, 60, 120] { println!("  rolling {:>3}-day             {:.6}", w, rmse(&roll(w))); }

    // ---- road 3: does the filter's own P match its real error?  2,000 worlds drawn from the model ----
    let (mut mc, mut sq) = (Rng { s: 7 }, 0.0);
    for _ in 0..2000 {
        let mut b_true = m0 + p0.sqrt() * mc.normal();
        let mut as_ = Vec::new();
        for t in 1..=50 {
            b_true += q.sqrt() * mc.normal();
            as_.push(b_true * b[t] + r.sqrt() * mc.normal());
        }
        sq += (kalman(&as_, &b[1..51], m0, p0, q, r)[49].0 - b_true).powi(2);
    }
    println!("road 3: filter's P on day 50 {:.10};  mean squared error over 2,000 simulated worlds {:.10}", kf[49].1, sq / 2000.0);

    let days: Vec<usize> = (60..=n).step_by(10).collect();
    row("chart, day", days.iter().map(|t| format!("{:6}", t)).collect());
    row("chart, true ratio", days.iter().map(|&t| format!("{:6.3}", beta[t])).collect());
    row("chart, Kalman", days.iter().map(|&t| format!("{:6.3}", est[t])).collect());
    row("chart, rolling 60", days.iter().map(|&t| format!("{:6.3}", roll60[t - 60])).collect());
    let sdays: Vec<usize> = (0..=n).step_by(10).collect();
    row("chart, spread day", sdays.iter().map(|t| format!("{:6}", t)).collect());
    row("chart, fixed ratio $", sdays.iter().map(|&t| format!("{:6.2}", a[t] - fixed * b[t])).collect());
    row("chart, Kalman $", sdays.iter().map(|&t| format!("{:6.2}", a[t] - est[t.max(1) - 1] * b[t])).collect());

    for (i, h) in hand.iter().enumerate() {
        assert!((h.2 - fib[2 * i + 3] as f64 / fib[2 * i + 4] as f64).abs() < 1e-12);
    }
    assert!((hand_batch - hand[3].0).abs() < 1e-9 && (w20 - golden).abs() < 1e-12);
    assert!(road2 < 1e-9, "the filter must equal the end point of the whole-path regression");
    assert!((stat - closed).abs() < 1e-12, "with Q = 0 the filter is an expanding regression");
    assert!((sq / 2000.0 / kf[49].1 - 1.0).abs() < 0.10, "the filter's P must match its real squared error");
    assert!(kf_rmse[2] < rmse(&roll60) && kf_rmse[2] < kf_rmse[0]);
    println!("ALL CHECKS PASS");
}
