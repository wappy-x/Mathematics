// Forward and backward error, the same check as the Python, in Rust.  No crates.
// A mine: pay $100 now, earn $230 in a year, pay a $132.24 cleanup bill a year later.
// NPV(x) = -100 x^2 + 230 x - c, where x = 1 + the yearly rate.  The IRR is a root.
fn sci(v: f64, k: usize) -> String { format!("{:.*e}", k, v) }   // 6.055e-4
fn isqrt(n: i128) -> i128 {                      // whole-number square root, by halving
    let (mut lo, mut hi) = (0i128, n + 1);
    while hi - lo > 1 {
        let mid = (lo + hi) / 2;
        if mid * mid <= n { lo = mid } else { hi = mid }
    }
    lo
}
const C: i128 = 13224;                           // the cleanup bill in cents: $132.24
fn npv100(n: i128, d: i128) -> i128 {            // 100 d^2 NPV(n/d): exact, in whole numbers
    -10000 * n * n + 23000 * n * d - C * d * d
}
fn exact(x: f64) -> i128 {                       // a double in [1, 2) is n52 / 2^52 exactly
    ((x.to_bits() & ((1u64 << 52) - 1)) | (1u64 << 52)) as i128
}

fn main() {
    // road 1: the true roots, exactly, from the quadratic formula
    let dd = 52900 - 4 * C;                      // 230^2 - 4 * 100 * c
    let s = isqrt(dd);
    assert!(s * s == dd);
    println!("true IRRs, quadratic formula: x = {:.4} and {:.4}, rates {:.2}% and {:.2}%",
             (230 - s) as f64 / 200.0, (230 + s) as f64 / 200.0, (30 - s) as f64 / 2.0, (30 + s) as f64 / 2.0);
    println!("NPV at the peak, rate 15%: {:+.4} cents", npv100(23, 20) as f64 / 400.0);
    // road 2: bisection on [1.15, 1.25] in exact fractions m/d, stopping when |NPV| < half a cent
    println!("cash flows -100, +230, -{:.2} dollars; bisection on x in [1.15, 1.25], stop when |NPV| < 0.5 cents",
             C as f64 / 100.0);
    let (mut a, mut b, mut d, mut k) = (23i128, 25i128, 20i128, 0);
    let (m, n) = loop {
        a *= 2; b *= 2; d *= 2;                  // same bracket, finer denominator
        let m = (a + b) / 2;
        k += 1;
        let n = npv100(m, d);
        println!("bisection {}: x = {:.6}, rate {:.4}%, NPV {:+.4} cents", k, m as f64 / d as f64,
                 (100 * (m - d)) as f64 / d as f64, n as f64 / d as f64 / d as f64);
        if 2 * n.abs() < d * d { break (m, n) }  // the stop test: |NPV| under half a cent
        if n > 0 { a = m } else { b = m }        // NPV > 0 means the root lies above m
    };
    let xs = (230 + s) as f64 / 200.0;
    let fe = (200 * m - (230 + s) * d).abs() as f64 / (200 * d) as f64;   // forward error
    let be = n.abs() as f64 / (100 * d * d) as f64;                      // backward error, dollars
    println!("computed rate {:.2}% against true {:.2}%: forward error {:.6} in x, {:.4} points",
             (100 * (m - d)) as f64 / d as f64, (30 + s) as f64 / 2.0, fe, 100.0 * fe);
    let rr = fe / ((30 + s) as f64 / 200.0);     // relative error of the rate itself
    println!("rate relative error {}, about {:.2} correct digits; x about {:.2}", sci(rr, 3), -rr.log10(), -(fe / xs).log10());
    println!("backward error: NPV {:.10} dollars, so the bill changes to {:.10}",
             be, (C * d * d + n) as f64 / (100 * d * d) as f64);
    let d2 = dd * d * d - 4 * n;                 // road 3: solve the changed problem afresh
    let s2 = isqrt(d2);
    assert!(s2 * s2 == d2 && 230 * d + s2 == 200 * m);
    println!("quadratic formula on the changed bill: x = {:.6}, exactly the computed root",
             (230 * d + s2) as f64 / (200 * d) as f64);
    let kap = 1.0 / s as f64;                    // 1 / |slope at the root|; the slope is -s
    let h = 1e-6;                                // road 4: nudge the bill, re-solve, measure
    let xr = |c: f64| (230.0 + (52900.0 - 400.0 * c).sqrt()) / 200.0;
    let kfd = (xr(C as f64 / 100.0) - xr(C as f64 / 100.0 + h)) / h;
    println!("slope at the root {:.1}, absolute condition number kappa_abs = 1/|slope| = {:.4}; nudged bill gives {:.6}",
             -s as f64, kap, kfd);
    let est = kap * be;
    println!("rule of thumb: kappa_abs x backward = {}; true forward {}; ratio {:.4}", sci(est, 3), sci(fe, 3), fe / est);
    let smin = ((200 * m - 230 * d).abs() as f64 / d as f64).min(s as f64);  // smallest slope between
    println!("guaranteed bound backward/smallest slope = {:.10}/{:.4} = {}, ratio to true {:.4}", be, smin, sci(be / smin, 3), be / smin / fe);
    assert!((kfd - kap).abs() < 1e-4 && 0.9 < fe / est && fe / est < 1.1 && fe <= be / smin);
    assert!(((200 * m - (230 + s) * d) * (200 * m - (230 - s) * d)).abs() == 4 * n.abs());
    let (rb, rf, kr) = (be / (C as f64 / 100.0), fe / xs, kap * (C as f64 / 100.0) / xs);
    println!("relative: backward {}, forward {}, kappa_rel {:.2}, estimate {}", sci(rb, 3), sci(rf, 3), kr, sci(kr * rb, 3));
    // road 5: Newton in doubles, to the floor set by rounding
    let c = C as f64 / 100.0;
    let f = |x: f64| (-100.0 * x + 230.0) * x - c;
    let df = |x: f64| -200.0 * x + 230.0;
    let p52 = 1i128 << 52;
    let err = |x: f64| (200 * exact(x) - (230 + s) * p52) as f64 / (200 * p52) as f64;  // true error
    let (mut x, mut k) = (1.2f64, 0);
    loop {
        println!("Newton {}: x = {:.16}, computed NPV {}, error {}", k, x, sci(f(x), 2), sci(err(x), 2));
        if f(x) == 0.0 || k == 9 { break }
        x -= f(x) / df(x);
        k += 1;
    }
    let tr = npv100(exact(x), p52) as f64 / (100 * p52 * p52) as f64;   // true residual of that double
    let ex = err(x).abs();
    let noise = 2f64.powi(-53) * (100.0 * x * x + 230.0 * x + c);
    println!("floor: rounding noise in NPV about {} dollars; kappa_abs x noise = {} bound", sci(noise, 2), sci(kap * noise, 2));
    println!("computed NPV 0, true NPV {}; true error {}, {} steps of 2^-52, bound/true {:.2}", sci(tr, 2), sci(ex, 2),
             (ex / 2f64.powi(-52)).round(), kap * noise / ex);
    assert!(0.0 < ex && ex <= kap * noise && (ex - kap * tr.abs()).abs() < 1e-6 * ex);
    // what breaks
    println!("break 1, read relative backward error as accuracy: claims {}, truth {}, {:.1} times worse",
             sci(rb, 3), sci(rf, 3), rf / rb);
    let e2 = be.sqrt() / 10.0;                   // bill $132.25: NPV = -(10x - 11.5)^2, slope 0 at the root
    let x2 = (230.0 + (52900.0 - 4.0 * 13225.0 + 400.0 * be).sqrt()) / 200.0;
    assert!((x2 - 1.15 - e2).abs() < 1e-12 && e2 > 2.0 * be);
    println!("break 2, bill $132.25, slope 0 at x = 1.15, kappa_abs = 1/0: backward error {} gives error {}",
             sci(be, 3), sci(e2, 3));
    println!("break 3, computed NPV 0 taken as exact: x = {:.16} still {} off", x, sci(ex, 2));
    let pts: Vec<f64> = (0..13).map(|j| npv100(4540 + 10 * j, 4000) as f64 / 16e6).collect();
    let ps: Vec<String> = pts.iter().map(|v| format!("{:.4}", v)).collect();
    println!("chart, NPV in cents at rates 13.50% to 16.50% in steps of 0.25: {}", ps.join(" "));
    assert!((pts[0] + 1.25).abs() < 1e-12 && (pts[6] - 1.0).abs() < 1e-12);
    println!("ALL CHECKS PASS");
}
