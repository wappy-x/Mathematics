// Dirichlet and Fejer kernels -- the check behind the card.  std only.
// Nine coefficients, k = -4..4: the partial sum S_4 smears with D_4, its running
// average sigma_5 = (S_0 + ... + S_4)/5 smears with F_5.  Same roads as the Python.
use std::f64::consts::PI;

fn d_sum(n: usize, t: f64) -> f64 { 1.0 + 2.0 * (1..=n).map(|k| (k as f64 * t).cos()).sum::<f64>() }
fn d(n: usize, t: f64) -> f64 {
    if t % (2.0 * PI) == 0.0 { (2 * n + 1) as f64 } else { ((n as f64 + 0.5) * t).sin() / (t / 2.0).sin() }
}
fn f_avg(n: usize, t: f64) -> f64 { (0..n).map(|k| d_sum(k, t)).sum::<f64>() / n as f64 } // mean of D_0..D_(n-1)
fn f_taper(n: usize, t: f64) -> f64 {                                                   // tapered
    1.0 + 2.0 * (1..n).map(|k| (1.0 - k as f64 / n as f64) * (k as f64 * t).cos()).sum::<f64>()
}
fn f(n: usize, t: f64) -> f64 {
    if t % (2.0 * PI) == 0.0 { n as f64 } else { ((n as f64 * t / 2.0).sin() / (t / 2.0).sin()).powi(2) / n as f64 }
}
fn gauss(g: &dyn Fn(f64) -> f64, a: f64, b: f64, m: usize) -> f64 { // 3-point Gauss-Legendre per cell
    let (h, r) = ((b - a) / m as f64, 0.6f64.sqrt() / 2.0);
    h * (0..m).map(|j| {
        let c = a + (j as f64 + 0.5) * h;
        5.0 / 18.0 * (g(c - r * h) + g(c + r * h)) + 4.0 / 9.0 * g(c)
    }).sum::<f64>()
}
fn l(n: usize, m: usize) -> f64 { gauss(&|t| d(n, t).abs(), 0.0, PI, (2 * n + 1) * m) / PI }
fn s_sq(n: usize, x: f64) -> f64 {
    4.0 / PI * (1..=n).step_by(2).map(|k| (k as f64 * x).sin() / k as f64).sum::<f64>()
}
fn sig_sq(n: usize, x: f64) -> f64 {
    4.0 / PI * (1..n).step_by(2).map(|k| (1.0 - k as f64 / n as f64) * (k as f64 * x).sin() / k as f64).sum::<f64>()
}
fn sq(x: f64) -> f64 { if x.rem_euclid(2.0 * PI) < PI { 1.0 } else { -1.0 } }
fn two(v: f64) -> String { format!("{:.2}", if v.abs() < 0.005 { 0.0 } else { v }) }

fn main() {
    // ---- the kernels: closed form against the sum of tones ----
    for t in [0.3, 1.0, 2.5] {
        assert!((d(4, t) - d_sum(4, t)).abs() < 1e-12);
        assert!((f(5, t) - f_avg(5, t)).abs() < 1e-12 && (f(5, t) - f_taper(5, t)).abs() < 1e-12);
    }
    let w: Vec<String> = (0..5).map(|k| format!("{:.1}", 1.0 - k as f64 / 5.0)).collect();
    println!("weights on the nine tones, |k| = 0..4: Dirichlet 1 1 1 1 1; Fejer {}", w.join(" "));
    println!("peak at t = 0: D_4 = {:.0}, F_5 = {:.0}", d(4, 0.0), f(5, 0.0));
    println!("first zero: D_4 at 2pi/9 = {:.4} rad, F_5 at 2pi/5 = {:.4} rad", 2.0 * PI / 9.0, 2.0 * PI / 5.0);
    println!("siren, 220 cycles a second: {:.3} ms and {:.3} ms", 1000.0 / (9.0 * 220.0), 1000.0 / (5.0 * 220.0));
    let (mut dmin, mut tmin) = (f64::INFINITY, 0.0);
    for j in 0..50001 {
        let t = 0.8 + j as f64 * 1e-5;
        if d(4, t) < dmin { dmin = d(4, t); tmin = t; }
    }
    println!("lowest value: D_4 = {:.4} at t = {:.4} rad; F_5 = 0 at its zeros", dmin, tmin);
    assert!(-2.1 < dmin && dmin < d(4, PI / 3.0) && d(4, PI / 3.0) < -1.99);
    let mut b = 0.0;
    for m in [360, 720] {
        let a = gauss(&|t| d(4, t), -PI, PI, m) / (2.0 * PI);
        b = gauss(&|t| f(5, t), -PI, PI, m) / (2.0 * PI);
        println!("signed area / 2pi, M = {}: D_4 {:.10}, F_5 {:.10}", m, a, b);
        assert!((a - 1.0).abs() < 1e-12 && (b - 1.0).abs() < 1e-12);
    }

    // ---- total size: L_N = (1/2pi) * area of |D_N|; cells end on the zeros 2 pi j/(2N+1) ----
    for n in [4usize, 16, 64, 256] {
        let (l1, l2) = (l(n, 40), l(n, 80));
        let low = 4.0 / (PI * PI) * (1..=n).map(|k| 1.0 / k as f64).sum::<f64>();
        let up = 1.0 + ((2 * n + 1) as f64).ln();
        println!("L_{}: {:.6} ({} cells), {:.6} ({}); lower {:.4} ratio {:.3}; upper {:.4}",
                 n, l1, 40 * (2 * n + 1), l2, 80 * (2 * n + 1), low, l2 / low, up);
        assert!((l1 - l2).abs() < 1e-6 && low < l2 && l2 < up);
    }
    let l4 = l(4, 80);
    let neg = (l4 - 1.0) / 2.0;
    println!("D_4: positive part {:.5}, negative part {:.5}; F_5: 1 and 0", 1.0 + neg, neg);

    // ---- the worst +-1 V signal for nine terms: f(y) = sign of D_4(y), switching at 2 pi j/9 ----
    let cuts = [0.0, 2.0 * PI / 9.0, 4.0 * PI / 9.0, 6.0 * PI / 9.0, 8.0 * PI / 9.0, PI];
    let fhat = |k: usize| -> f64 {
        let mut s = 0.0;
        for j in 0..5 {
            let (a, bb) = (cuts[j], cuts[j + 1]);
            let sign = if j % 2 == 0 { 1.0 } else { -1.0 };
            s += sign * if k == 0 { bb - a } else { ((k as f64 * bb).sin() - (k as f64 * a).sin()) / k as f64 };
        }
        s / PI
    };
    let worst = fhat(0) + 2.0 * (1..5).map(|k| fhat(k)).sum::<f64>();
    println!("worst signal: S_4 at x = 0 by its coefficients {:.6} V; by L_4 {:.6} V", worst, l4);
    assert!((worst - l4).abs() < 1e-9);

    // ---- the siren: +-1 V square wave, b_k = 4/(pi k) for odd k ----
    let x0 = PI / 4.0;
    println!("siren at x = pi/4: sin x = sin 3x = {:.4}", x0.sin());
    let (mut c1, mut c2) = (0.0, 0.0);
    for m in [3600, 7200] {
        c1 = gauss(&|t| sq(x0 - t) * d(4, t), -PI, PI, m) / (2.0 * PI);
        c2 = gauss(&|t| sq(x0 - t) * f(5, t), -PI, PI, m) / (2.0 * PI);
        println!("at x = pi/4, by convolution, M = {}: S_4 {:.6} V, sigma_5 {:.6} V", m, c1, c2);
    }
    println!("at x = pi/4, by coefficients: S_4 {:.6} V, sigma_5 {:.6} V", s_sq(4, x0), sig_sq(5, x0));
    assert!((c1 - s_sq(4, x0)).abs() < 1e-6 && (c2 - sig_sq(5, x0)).abs() < 1e-6);
    assert!((s_sq(4, x0) - 8.0 * 2f64.sqrt() / (3.0 * PI)).abs() < 1e-12);
    for n in [4usize, 16, 64] {
        let k = (n + 1) / 2;
        let p_s = s_sq(n, PI / (2 * k) as f64);
        let p_f = (1..4000).map(|j| sig_sq(n + 1, PI * j as f64 / 4000.0)).fold(f64::NEG_INFINITY, f64::max);
        println!("square wave, tones up to {}: S peak {:.4} V at x = {:.4}; sigma_{} highest {:.4} V",
                 n, p_s, PI / (2 * k) as f64, n + 1, p_f);
        assert!(p_s > 1.17 && p_f < 1.0);
    }
    assert!((s_sq(64, PI / 64.0) - 1.178980).abs() < 1e-3);

    // ---- far weight: share of each kernel's size beyond |t| = pi/2 ----
    let lim = 4.0 / (PI * PI) * -(2f64.sqrt() - 1.0).ln();
    let mut fd = 0.0;
    for n in [5usize, 50, 500] {
        let ff = gauss(&|t| f(n, t), PI / 2.0, PI, 200 * n) / PI;
        fd = gauss(&|t| d(n, t).abs(), PI / 2.0, PI, 200 * n) / PI;
        println!("beyond pi/2, N = {}: F_N {:.6}, bound 1/N {:.4}, ratio {:.3}; |D_N| {:.4}",
                 n, ff, 1.0 / n as f64, ff * n as f64, fd);
        assert!(ff <= 1.0 / n as f64);
    }
    println!("|D_N| beyond pi/2 tends to (4/pi^2) ln(1/tan(pi/8)) = {:.4}", lim);
    assert!((fd - lim).abs() < 1e-3);

    // ---- what breaks ----
    println!("break, drop 1/2pi: S_4 at pi/4 = {:.4} V", 2.0 * PI * s_sq(4, x0));
    println!("break, drop 1/N in F_5: peak {:.0}, area {:.0}, sigma_5 at pi/4 = {:.4} V",
             5.0 * f(5, 0.0), 5.0 * b, 5.0 * sig_sq(5, x0));

    // ---- chart points, t = 0 .. pi in steps of pi/18 ----
    let ts: Vec<f64> = (0..19).map(|j| PI * j as f64 / 18.0).collect();
    let row = |g: &dyn Fn(f64) -> f64| ts.iter().map(|&t| two(g(t))).collect::<Vec<_>>().join(" ");
    println!("chart t: {}", row(&|t| t));
    println!("chart D_4: {}", row(&|t| d(4, t)));
    println!("chart F_5: {}", row(&|t| f(5, t)));
    println!("ALL CHECKS PASS");
}
