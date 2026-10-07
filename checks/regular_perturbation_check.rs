// Regular perturbation -- the same check as the Python, in Rust.  No crates.
// A seconds pendulum (small-swing period exactly 2 s) released from rest at
// 10 degrees.  Its period is found three ways: the perturbation series in
// eps = a^2, Gauss's arithmetic-geometric mean, and RK4 stepping of the swing.
use std::f64::consts::PI;

const G: f64 = 9.80665;              // standard gravity, m/s^2 (NIST conventional value)
const DAY: f64 = 86400.0;            // seconds in a day
const D: f64 = PI / 180.0;           // radians per degree

fn series(a: f64, n: usize) -> f64 {  // T/T0 from the series, keeping n corrections
    let e = a * a;
    [1.0, 1.0 + e / 16.0, 1.0 + e / 16.0 + 11.0 * e * e / 3072.0][n]
}

fn agm(mut x: f64, mut y: f64) -> f64 {  // Gauss's arithmetic-geometric mean, written out
    for _ in 0..30 {
        let (nx, ny) = (0.5 * (x + y), (x * y).sqrt());
        x = nx;
        y = ny;
    }
    x
}

fn exact(a: f64) -> f64 { 1.0 / agm(1.0, (0.5 * a).cos()) }  // T/T0 = 1 / AGM(1, cos(a/2))

fn step(th: f64, w: f64, h: f64) -> (f64, f64) {  // one RK4 step of th' = w, w' = -sin th
    let (k1t, k1w) = (w, -th.sin());
    let (k2t, k2w) = (w + 0.5 * h * k1w, -(th + 0.5 * h * k1t).sin());
    let (k3t, k3w) = (w + 0.5 * h * k2w, -(th + 0.5 * h * k2t).sin());
    let (k4t, k4w) = (w + h * k3w, -(th + h * k3t).sin());
    (th + h * (k1t + 2.0 * k2t + 2.0 * k3t + k4t) / 6.0,
     w + h * (k1w + 2.0 * k2w + 2.0 * k3w + k4w) / 6.0)
}

fn rk4_ratio(a: f64, h: f64) -> f64 {  // time from rest at a to the bottom, times 4, over 2 pi
    let (mut th, mut w, mut n) = (a, 0.0, 0.0);
    loop {
        let (th2, w2) = step(th, w, h);
        if th2 <= 0.0 { break }
        th = th2;
        w = w2;
        n += 1.0;
    }
    let (mut lo, mut hi) = (0.0, h);   // bisect the last step to land on the bottom
    for _ in 0..60 {
        let mid = 0.5 * (lo + hi);
        if step(th, w, mid).0 > 0.0 { lo = mid } else { hi = mid }
    }
    4.0 * (n * h + lo) / (2.0 * PI)
}

fn strained(a: f64, t: f64) -> f64 {  // two-term solution, frequency expanded too
    let e = a * a;
    let tau = (1.0 - e / 16.0 + e * e / 3072.0) * t;
    a * (tau.cos() + e * (tau.cos() - (3.0 * tau).cos()) / 192.0)
}

fn naive(a: f64, t: f64) -> f64 {     // two-term solution, frequency held at 1
    let e = a * a;
    a * (t.cos() + e * ((t.cos() - (3.0 * t).cos()) / 192.0 + t * t.sin() / 16.0))
}

fn row(v: &[f64], f: impl Fn(f64) -> String) -> String {
    v.iter().map(|&x| f(x)).collect::<Vec<_>>().join(" ")
}

fn main() {
    let l = G / (PI * PI);             // rod length giving a 2 s small-swing period, m
    let t0 = 2.0 * PI * (l / G).sqrt();
    let a = 10.0 * D;
    let e = a * a;
    let s: Vec<f64> = (0..3).map(|n| series(a, n)).collect();
    let (x, r) = (exact(a), rk4_ratio(a, 0.001));
    println!("pendulum: l = {:.6} m, g = {:.5} m/s^2, T0 = {:.9} s, time unit sqrt(l/g) = {:.6} s", l, G, t0, (l / G).sqrt());
    println!("amplitude a = 10 deg = {:.6} rad; eps = a^2 = {:.6}", a, e);
    println!("first correction eps/16 = {:.9}; second 11 eps^2/3072 = {:.9}", e / 16.0, 11.0 * e * e / 3072.0);
    for (label, v) in [("0 corrections", s[0]), ("1 correction", s[1]), ("2 corrections", s[2]),
                       ("exact, by AGM", x), ("exact, by RK4", r)] {
        println!("period, {:<15} {:.9} s", label, v * t0);
    }
    for n in 0..3 {
        let err = (x - s[n]) / x;
        println!("error, keeping {}       {:11.4} ppm   clock off by {:9.4} s/day", n, err * 1e6, DAY * err);
    }
    for d in [9.0, 10.0, 11.0] {
        println!("clock at {:4.1} deg loses {:7.2} s/day vs the small-swing 2 s", d, DAY * (1.0 - 1.0 / exact(d * D)));
    }
    println!("near 10 deg the loss changes by {:.2} s/day per degree", DAY * (1.0 / exact(9.0 * D) - 1.0 / exact(11.0 * D)) / 2.0);
    println!("shrink: amplitude deg   eps        error 1 corr ppm   error 2 corr ppb");
    let mut errs = Vec::new();
    for d in [20.0, 10.0, 5.0, 2.5] {
        let b = d * D;
        let xb = exact(b);
        errs.push((xb - series(b, 2)) / xb);
        println!("shrink: {:12.1}   {:.6}   {:16.4}   {:16.4}", d, b * b, (xb - series(b, 1)) / xb * 1e6, errs[errs.len() - 1] * 1e9);
    }
    let ratio = errs[1] / errs[2];
    println!("halving the amplitude cuts the 2-correction error by {:.2} (eps^3 predicts 64)", ratio);
    let r1 = |b: f64| (exact(b) - 1.0) / (b * b);                         // left over after 1, per eps
    let r2 = |b: f64| (exact(b) - 1.0 - b * b / 16.0) / (b * b * b * b);  // after 1 + eps/16, per eps^2
    let c1 = (4.0 * r1(0.5 * D) - r1(1.0 * D)) / 3.0;                     // Richardson: cancel the next term
    let c2 = (4.0 * r2(2.0 * D) - r2(4.0 * D)) / 3.0;
    println!("coefficient of eps, read off the AGM:   {:.10}   derived 1/16    = {:.10}", c1, 1.0 / 16.0);
    println!("coefficient of eps^2, read off the AGM: {:.10}   derived 11/3072 = {:.10}", c2, 11.0 / 3072.0);

    let nn = 4000;                     // one exact period, sampled for the third harmonic
    let p = 2.0 * PI * x;
    let (mut th, mut w, mut b3) = (a, 0.0, 0.0);
    for k in 0..nn {
        b3 += th * (3.0 * 2.0 * PI * k as f64 / nn as f64).cos();
        (th, w) = step(th, w, p / nn as f64);
    }
    b3 = 2.0 * b3 / nn as f64 / a;
    println!("third harmonic, share of the swing: RK4 {:.7}   derived -eps/192 = {:.7}", b3, -e / 192.0);

    let m = 2000;                      // 100 swings: both expansions against RK4
    let (mut th, mut w, mut worst) = (a, 0.0, 0.0f64);
    let mut chart: Vec<[f64; 4]> = Vec::new();
    chart.push([a, a, a, a]);
    for n in 1..=100 {
        let mut t = 0.0;
        for k in 0..m {
            (th, w) = step(th, w, p / m as f64);
            t = ((n - 1) * m + k + 1) as f64 * (p / m as f64);
            worst = worst.max((th - strained(a, t)).abs());
        }
        chart.push([th, a * t.cos(), naive(a, t), strained(a, t)]);
    }
    for n in [1, 10, 100] {
        let v: Vec<f64> = chart[n].iter().map(|c| c / D).collect();
        println!("after {:3} swings: RK4 {:7.4} deg  small-angle {:8.4}  naive {:8.4}  strained {:7.4}", n, v[0], v[1], v[2], v[3]);
    }
    println!("worst gap, strained expansion vs RK4, 100 swings ({:.2} s): {:.6} deg", 100.0 * p * (l / G).sqrt(), worst / D);
    let ns: Vec<usize> = (0..11).map(|i| 10 * i).collect();
    println!("chart, swing number   {}", ns.iter().map(|n| format!("{:6}", n)).collect::<Vec<_>>().join(" "));
    for (j, lab) in ["RK4 deg        ", "small-angle deg", "naive deg      ", "strained deg   "].iter().enumerate() {
        println!("chart, {} {}", lab, ns.iter().map(|&n| format!("{:6.2}", chart[n][j] / D)).collect::<Vec<_>>().join(" "));
    }

    println!("beyond: amplitude deg   eps      exact s   2 corrections s   error %");
    for d in [30.0, 60.0, 90.0, 120.0, 150.0, 170.0] {
        let b = d * D;
        let (xb, sb) = (exact(b), series(b, 2));
        println!("beyond: {:12.0}   {:6.3}   {:7.4}   {:15.4}   {:7.2}", d, b * b, xb * t0, sb * t0, (xb - sb) / xb * 100.0);
    }
    let amps: Vec<f64> = (0..11).map(|i| 15.0 * i as f64).collect();
    println!("chart, amplitude deg     {}", row(&amps, |d| format!("{:6.0}", d)));
    println!("chart, exact period s    {}", row(&amps, |d| format!("{:6.2}", exact(d * D) * t0)));
    println!("chart, 2 corrections s   {}", row(&amps, |d| format!("{:6.2}", series(d * D, 2) * t0)));

    let ed = 10.0 * 10.0;              // mistakes, all at the 10 degree swing
    println!("wrong: eps in degrees, 100      period {:.4} s", t0 * (1.0 + ed / 16.0 + 11.0 * ed * ed / 3072.0));
    println!("wrong: eps = a, not a^2         period {:.6} s", t0 * (1.0 + a / 16.0 + 11.0 * a * a / 3072.0));
    println!("wrong: frequency read as period period {:.6} s", t0 * (1.0 - e / 16.0 + e * e / 3072.0));

    assert!((r - x).abs() < 1e-10, "RK4 period must match the AGM period");
    assert!((c1 - 1.0 / 16.0).abs() < 1e-9, "first coefficient read off the AGM must be 1/16");
    assert!((c2 - 11.0 / 3072.0).abs() < 1e-8, "second coefficient read off the AGM must be 11/3072");
    assert!(60.0 < ratio && ratio < 70.0, "two-correction error must fall about 64-fold per halving");
    assert!((b3 + e / 192.0).abs() < 2e-6, "RK4 third harmonic must match the first correction");
    assert!(worst < 1e-5 * D, "strained expansion must stay on the RK4 swing for 100 swings");
    assert!(chart[100][2] - a > 4.0 * D, "naive expansion must drift by over 4 degrees by swing 100");
    println!("ALL CHECKS PASS");
}
