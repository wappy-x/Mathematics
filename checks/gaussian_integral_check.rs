// The Gaussian integral -- the same check as the Python, in Rust.  No crates;
// exp and sqrt are primitives, never the constant pi.  Road one integrates
// e^(-x^2) by Simpson's rule; road two builds pi from Machin's arctan series
// and takes its root.  A grid over the disk checks the polar step without polar.
fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64) -> f64 {
    let n = 1200;                                  // even: weights 1, 4, 2, 4, ..., 4, 1
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for k in 1..n { s += if k % 2 == 1 { 4.0 } else { 2.0 } * f(a + k as f64 * h) }
    s * h / 3.0
}

fn arctan_inv(x: f64) -> f64 {                     // arctan(1/x) from its own partial sums
    (0..30).map(|k| (-1f64).powi(k) / ((2 * k + 1) as f64 * x.powi(2 * k + 1))).sum()
}

fn disk_by_grid(r: f64, n: usize) -> f64 {         // squares whose centres lie in the disk
    let h = 2.0 * r / n as f64;
    let mut tot = 0.0;
    for i in 0..n {
        let x = -r + (i as f64 + 0.5) * h;
        for j in 0..n {
            let y = -r + (j as f64 + 0.5) * h;
            if x * x + y * y <= r * r { tot += (-x * x - y * y).exp() }
        }
    }
    tot * h * h
}

fn main() {
    let g = |x: f64| (-x * x).exp();
    let pi = 16.0 * arctan_inv(5.0) - 4.0 * arctan_inv(239.0);
    let i_all = simpson(&g, -6.0, 6.0);
    println!("pi by Machin's series: {:.12}", pi);
    println!("road 1, Simpson on [-6, 6], 1200 strips: I = {:.12}", i_all);
    println!("road 2, square root of the series pi:     {:.12}", pi.sqrt());
    let mut squeeze = Vec::new();
    for r in [1.0f64, 2.0, 3.0] {
        let (lo, sq, hi) = (pi * (1.0 - (-r * r).exp()), simpson(&g, -r, r).powi(2), pi * (1.0 - (-2.0 * r * r).exp()));
        squeeze.push((lo, sq, hi));
        println!("squeeze R = {}: I_R = {:.6}; disk {:.6} <= square {:.6} <= disk {:.6}", r, sq.sqrt(), lo, sq, hi);
    }
    for r in [2.0f64, 3.0] {
        println!("tails beyond R = {}: actual {:.6}, bound e^(-R^2)/R {:.6}", r, i_all - simpson(&g, -r, r), (-r * r).exp() / r);
    }
    let grid = disk_by_grid(1.0, 1000);
    println!("disk R = 1 by a 1000 x 1000 grid, no polar: {:.6}; polar formula {:.6}", grid, pi * (1.0 - (-1.0f64).exp()));
    let root2pi = (2.0 * pi).sqrt();
    let bell = |x: f64| (-x * x / 2.0).exp() / root2pi;
    println!("bell: sqrt(2 pi) = {:.6}; peak height 1/sqrt(2 pi) = {:.6}", root2pi, 1.0 / root2pi);
    let area = simpson(&bell, -8.0, 8.0);
    println!("bell area by Simpson on [-8, 8]: {:.9}", area);
    let within: Vec<String> = [1.0, 2.0, 3.0].iter().map(|&k| format!("{:.6}", simpson(&bell, -k, k))).collect();
    println!("bell area within 1, 2, 3 of the centre: {}", within.join(", "));
    let heights: Vec<String> = (-6..7).map(|k| format!("{:.2}", bell(k as f64 / 2.0))).collect();
    println!("chart, bell height at x = -3, -2.5, ..., 3: {}", heights.join(", "));
    println!("figure, centre (180, 120); 60 per unit; square 120 to 240; inner radius 60.00; outer radius {:.2} = 60 x {:.3}", 60.0 * 2f64.sqrt(), 2f64.sqrt());
    println!("mistake, drop r in the polar disk R = 1: {:.6}", 2.0 * pi * simpson(&g, 0.0, 1.0));
    println!("mistake, 1/sqrt(pi) in front of e^(-x^2/2): area {:.6}", simpson(&|x: f64| (-x * x / 2.0).exp(), -8.0, 8.0) / pi.sqrt());
    println!("mistake, a = 0: the strip [-10, 10] holds {:.6}", simpson(&|x: f64| (0.0 * x * x).exp(), -10.0, 10.0));
    assert!((i_all - pi.sqrt()).abs() < 1e-10);                        // two roads to root pi
    assert!(squeeze.iter().all(|&(lo, sq, hi)| lo <= sq && sq <= hi)); // square trapped between disks
    assert!((grid - pi * (1.0 - (-1.0f64).exp())).abs() < 1e-3);        // polar factor r, on a grid
    assert!((area - 1.0).abs() < 1e-10);                               // the bell's area is 1
    println!("ALL CHECKS PASS");
}
