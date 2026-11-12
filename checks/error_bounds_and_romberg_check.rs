// Error bounds and Romberg -- the same check as the Python, in Rust.  No crates.
// Wind model (illustrative): v(t) = 8 + 16 sin(pi t / 24) km/h over a 24-hour day,
// logged every 10 minutes (145 readings).  Wind run I = area under v, in km.
// Road 1: the closed form.  Road 2: Romberg's table.  Road 3: the Euler-Maclaurin
// series predicting each trapezoid error from the slopes at the two ends alone.
const PI: f64 = std::f64::consts::PI;
const W: f64 = PI / 24.0;
fn v(t: f64) -> f64 { 8.0 + 16.0 * (W * t).sin() }
fn trap(g: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 { // same rule on any curve
    let h = (b - a) / n as f64;
    h * ((g(a) + g(b)) / 2.0 + (1..n).map(|i| g(a + i as f64 * h)).sum::<f64>())
}
fn romberg(t: &[f64]) -> Vec<Vec<f64>> {                 // t[k] has twice the slices of t[k-1]
    let mut r: Vec<Vec<f64>> = t.iter().map(|&x| vec![x]).collect();
    for k in 1..t.len() {
        for j in 1..=k {
            let x = r[k][j - 1] + (r[k][j - 1] - r[k - 1][j - 1]) / (4f64.powi(j as i32) - 1.0);
            r[k].push(x);
        }
    }
    r
}
fn sci(x: f64, d: usize, plus: bool) -> String {         // Python's e-notation: +8.00e-04
    let s = format!("{:.*e}", d, x.abs());
    let (m, ex) = s.split_once('e').unwrap();
    let ex: i32 = ex.parse().unwrap();
    let sign = if x < 0.0 || (x == 0.0 && x.is_sign_negative()) { "-" } else if plus { "+" } else { "" };
    format!("{}{}e{}{:02}", sign, m, if ex < 0 { '-' } else { '+' }, ex.abs())
}
fn join(xs: impl Iterator<Item = String>, sep: &str) -> String { xs.collect::<Vec<_>>().join(sep) }
fn main() {
    let i_ex = 8.0 * 24.0 + 16.0 * 2.0 / W;               // antiderivative 8t - (16/W) cos(Wt)
    let log: Vec<f64> = (0..145).map(|k| v(10.0 * k as f64 / 60.0)).collect();
    let trap_log = |n: usize| {                           // n slices, every (144/n)-th reading
        let s = 144 / n;
        24.0 / n as f64 * ((log[0] + log[144]) / 2.0 + (1..n).map(|i| log[s * i]).sum::<f64>())
    };
    let e = |x: f64| sci(x - i_ex, 2, true);
    println!("readings in the log: {}; v(0) = {:.6}, v(12) = {:.6}, v(24) = {:.6} km/h", log.len(), log[0], log[72], log[144]);
    println!("exact wind run I = 192 + 768/pi = {:.6} km", i_ex);
    let ns = [3usize, 6, 12, 24, 48];
    let t: Vec<f64> = ns.iter().map(|&n| trap_log(n)).collect();
    let r = romberg(&t);
    println!("Romberg table on the log (stride: use every stride-th reading); entry (error in km):");
    for (k, &n) in ns.iter().enumerate() {
        println!("  n = {:2}, h = {:3.1} h, stride {:2}: {}", n, 24.0 / n as f64, 144 / n, join(r[k].iter().map(|&x| format!("{:.6} ({})", x, e(x))), "; "));
    }
    for j in 0..3 {
        let rat: Vec<f64> = (j + 1..5).map(|k| (r[k - 1][j] - i_ex) / (r[k][j] - i_ex)).collect();
        let th = 4f64.powi(j as i32 + 1);
        println!("column {}: error ratio per halving {}; theory {}", j, join(rat.iter().map(|x| format!("{:.2}", x)), ", "), th);
        assert!((rat[rat.len() - 1] - th).abs() < 0.02 * th);                // h^2, h^4, h^6 observed
    }
    let (t24, r24, t144) = (t[3], r[3][1], trap_log(144));
    println!("headline: T(24) = {:.6}, off {:+.4} km, relative {}", t24, t24 - i_ex, sci((t24 - i_ex) / i_ex, 1, true));
    println!("headline: R(24,1) from 25 readings = {:.6}, off {} km, relative {}", r24, e(r24), sci((r24 - i_ex) / i_ex, 1, true));
    println!("plain T(144), all 145 readings = {:.6}, off {} km, relative {}", t144, e(t144), sci((t144 - i_ex) / i_ex, 1, true));
    let nneed = 24.0 * ((t24 - i_ex) / (r24 - i_ex)).abs().sqrt();
    println!("plain trapezoid slices needed to match R(24,1): about {:.0}", nneed);
    assert!(((t24 - i_ex) / i_ex).abs() < 1e-3 && ((r24 - i_ex) / i_ex).abs() < 1e-6 && 1e-6 < ((t144 - i_ex) / i_ex).abs());
    // Road 3: Euler-Maclaurin, T - I = h^2/12 D1 - h^4/720 D3 + h^6/30240 D5, Dk = f^(k)(24) - f^(k)(0)
    let dk = |k: i32| 16.0 * W.powi(k) * ((W * 24.0 + k as f64 * PI / 2.0).sin() - (k as f64 * PI / 2.0).sin());
    for (&n, &tv) in ns[2..].iter().zip(t[2..].iter()) {
        let h = 24.0 / n as f64;
        let p = [h.powi(2) / 12.0 * dk(1), -h.powi(4) / 720.0 * dk(3), h.powi(6) / 30240.0 * dk(5)];
        let s3 = p[0] + p[1] + p[2];
        println!("Euler-Maclaurin n = {}: one term {:+.10}, three terms {:+.10}, measured {:+.10}", n, p[0], s3, tv - i_ex);
        assert!((s3 - (tv - i_ex)).abs() < 1e-9 * i_ex);                     // road 3 against road 1
    }
    let (k2, k4) = (16.0 * W.powi(2), 16.0 * W.powi(4));                  // largest |v''|, |v''''|, at noon
    let (bt, bs) = (k2 * 24.0 / 12.0, k4 * 24.0 / 180.0);                 // h = 1 hour
    let simp = 1.0 / 3.0 * (log[0] + log[144] + (1..24).map(|i| if i % 2 == 1 { 4.0 } else { 2.0 } * log[6 * i]).sum::<f64>());
    println!("bounds at h = 1 h: trapezoid {:.4} vs true {:.4}, ratio {:.2}", bt, (t24 - i_ex).abs(), bt / (t24 - i_ex).abs());
    println!("bounds at h = 1 h: Simpson {} vs true {}, ratio {:.2}", sci(bs, 2, false), sci((r24 - i_ex).abs(), 2, false), bs / (r24 - i_ex).abs());
    println!("R(24,1) {:.9} vs Simpson on the same 25 readings {:.9}", r24, simp);
    assert!((t24 - i_ex).abs() <= bt && (r24 - i_ex).abs() <= bs && (simp - r24).abs() < 1e-12 * i_ex);
    let (est, est1) = ((t[2] - t24) / 3.0, r24 - r[3][2]);               // T(h) - I and R(24,1) - I, guessed
    println!("free estimate of T(24)'s error, (T(12) - T(24))/3: {:+.6} vs true {:+.6}, ratio {:.5}", est, t24 - i_ex, est / (t24 - i_ex));
    println!("free estimate of R(24,1)'s error, R(24,1) - R(24,2): {} vs true {}, ratio {:.5}", sci(est1, 3, true), sci(r24 - i_ex, 3, true), est1 / (r24 - i_ex));
    assert!((est / (t24 - i_ex) - 1.0).abs() < 2e-3 && (est1 / (r24 - i_ex) - 1.0).abs() < 1e-2);
    println!("diagonal R(n,k) on the model curve, down to rounding (relative error):");
    let tt: Vec<f64> = (0..8).map(|k| trap(&v, 0.0, 24.0, 3 << k)).collect();
    let rr = romberg(&tt);
    println!("  {}", join((0..8).map(|k| format!("n = {}: {}", 3 << k, sci((rr[k][k] - i_ex) / i_ex, 1, true))), ", "));
    assert!((rr[7][7] - i_ex).abs() < 1e-13 * i_ex);
    // What breaks: a speed rising from calm like sqrt(t) after a front at hour 0, over 1 hour
    let sq = romberg(&(1..8).map(|k| trap(&|x: f64| x.sqrt(), 0.0, 1.0, 1 << k)).collect::<Vec<_>>());
    for j in 0..3 {
        let rat = (sq[5][j] - 2.0 / 3.0) / (sq[6][j] - 2.0 / 3.0);
        println!("sqrt(t) on [0, 1], column {}: error at n = 128 {}, ratio per halving {:.2}", j, sci(sq[6][j] - 2.0 / 3.0, 2, true), rat);
        assert!((rat - 2f64.powf(1.5)).abs() < 0.05);                       // stuck near h^1.5
    }
    let per = trap(&|x: f64| 16.0 - 8.0 * (2.0 * W * x).cos(), 0.0, 24.0, 6);
    println!("periodic day 16 - 8 cos(pi t / 12): T(6) = {:.12} vs exact {:.12}", per, 16.0 * 24.0);
    assert!((per - 384.0).abs() < 1e-12 * 384.0);
    let sm: Vec<f64> = [6usize, 12, 24].iter().map(|&n| trap(&|x: f64| 30.0 / (2.0 + (2.0 * W * x).cos()), 0.0, 24.0, n) - 720.0 / 3f64.sqrt()).collect();
    println!("smooth periodic day 30/(2 + cos(pi t / 12)), exact 720/sqrt3 = {:.6}: T(6), T(12), T(24) off {}", 720.0 / 3f64.sqrt(), join(sm.iter().map(|&x| sci(x, 2, true)), ", "));
    assert!(sm[0].abs() > 1e-2 && sm[1].abs() < sm[0].abs() / 1024.0 && sm[2].abs() < sm[1].abs() / 1048576.0);   // not exact; faster than any fixed power
    let wrong = [2.0 * t24 - t[2], (2.25 * t24 - trap_log(16)) / 1.25, (4.0 * t24 - trap_log(16)) / 3.0,
                 r[3][1] + (r[3][1] - r[2][1]) / 3.0, t24 - t[2]];
    println!("mistake, error taken as h not h^2, 2T(24) - T(12): {:.6}, off {:+.4}", wrong[0], wrong[0] - i_ex);
    println!("right, steps 1.5 h and 1 h, (2.25T(24) - T(16))/1.25: {:.6}, off {}", wrong[1], e(wrong[1]));
    println!("mistake, factor 4 on steps 1.5 h and 1 h: {:.6}, off {:+.4}", wrong[2], wrong[2] - i_ex);
    println!("mistake, second column with 3 not 15: {:.6}, off {}", wrong[3], e(wrong[3]));
    println!("mistake, T(24) - T(12) taken as the error: {:+.6}, true {:+.6}", wrong[4], t24 - i_ex);
    println!("chart, model curve, n = 12, 24, 48, 96, 192; log10 h: {}", join((2..7).map(|k| format!("{:.2}", (24.0 / (3 << k) as f64).log10())), ", "));
    for j in 0..3 {
        println!("chart, column {} log10 |relative error|: {}", j, join((2..7).map(|k| format!("{:.2}", ((rr[k][j] - i_ex) / i_ex).abs().log10())), ", "));
    }
    println!("ALL CHECKS PASS");
}
