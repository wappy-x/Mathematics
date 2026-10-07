// Taylor's theorem -- the same check as the Python, in Rust, std only.
// Road 1: four Taylor terms for e^0.1 plus the Lagrange remainder, which pins
// e^0.1 inside an interval.  Road 2: e^x found with no series at all, by
// bisection on ln y = x, with ln y built as a Simpson sum of the area under 1/t.

fn ln(y: f64) -> f64 {
    // area under 1/t from 1 to y, Simpson with 2000 panels
    let n = 2000;
    let h = (y - 1.0) / n as f64;
    let mut s = 1.0 + 1.0 / y;
    for k in 1..n {
        let w = if k % 2 == 1 { 4.0 } else { 2.0 };
        s += w / (1.0 + k as f64 * h);
    }
    s * h / 3.0
}

fn exp2(x: f64) -> f64 {
    // road 2: the y whose ln is x
    let (mut lo, mut hi) = (0.01, 10.0);
    for _ in 0..60 {
        let mid = (lo + hi) / 2.0;
        if ln(mid) < x { lo = mid } else { hi = mid }
    }
    (lo + hi) / 2.0
}

fn taylor(x: f64, n: u32) -> f64 {
    // road 1: sum of x^k / k!, k = 0..n
    let (mut term, mut total) = (1.0, 1.0);
    for k in 1..=n {
        term = term * x / k as f64;
        total += term;
    }
    total
}

fn f(t: f64) -> f64 { (t - 0.05).abs() } // a corner inside the interval

fn row(v: &[f64], p: usize) -> String {
    v.iter().map(|x| format!("{:.*}", p, x)).collect::<Vec<_>>().join(", ")
}

fn main() {
    let h: f64 = 0.1;
    let p3 = taylor(h, 3);
    let q = h.powi(4) / 24.0; // the remainder is e^xi times q
    let (low, high) = (p3 + q, p3 / (1.0 - q)); // e^xi >= 1, and e^xi <= e^0.1 solved
    let e01 = exp2(h);
    let xi = ln(24.0 * (e01 - p3) / h.powi(4)); // the point Lagrange promises
    let errs: Vec<f64> = [0.2, 0.1, 0.05].iter().map(|&t| exp2(t) - taylor(t, 3)).collect();
    let (p4, r4) = (taylor(h, 4), h.powi(5) / 120.0 * high); // next term, e^xi at most high
    let xs: Vec<f64> = (0..9).map(|i| -2.0 + 0.5 * i as f64).collect();
    let d2: Vec<f64> = [0.02, 0.08].iter()
        .map(|&t| ((f(t + 0.01) - 2.0 * f(t) + f(t - 0.01)) / 0.0001 * 1000.0).round() / 1000.0 + 0.0).collect();
    println!("four terms 1, 0.1, 0.005, {:.9}: P3(0.1) = {:.9}", h.powi(3) / 6.0, p3);
    println!("remainder = e^xi x {:.9}, so between {:.9} and {:.9}", q, q, high - p3);
    println!("road 1: e^0.1 in [{:.9}, {:.9}], ends round to {:.6}, {:.6}", low, high, low, high);
    println!("road 2, ln by Simpson then bisection: e^0.1 = {:.9}, rounds to {:.6}", e01, e01);
    println!("true remainder {:.9}; Lagrange point xi = {:.6}", e01 - p3, xi);
    println!("five terms: P4(0.1) = {:.9}, remainder under {:.9}", p4, r4);
    println!("degree-3 error at h = 0.2, 0.1, 0.05: {}", row(&errs, 9));
    println!("halving h divides it by {:.2}, then {:.2}", errs[0] / errs[1], errs[1] / errs[2]);
    println!("chart x: {}", row(&xs, 1));
    println!("chart e^x: {}", row(&xs.iter().map(|&t| exp2(t)).collect::<Vec<_>>(), 2));
    println!("chart P1: {}", row(&xs.iter().map(|&t| taylor(t, 1)).collect::<Vec<_>>(), 2));
    println!("chart P3: {}", row(&xs.iter().map(|&t| taylor(t, 3)).collect::<Vec<_>>(), 2));
    let nf: f64 = (0..4).map(|k| h.powi(k)).sum(); // the k! left out
    println!("mistake 1, no factorials: 1 + 0.1 + 0.01 + 0.001 = {:.9}, off by {:.9}", nf, nf - e01);
    println!("mistake 2, e^xi bounded by 1: ceiling {:.9}, below the truth {:.9}", p3 + q, e01);
    println!("mistake 3, four terms, no remainder: {:.6} against {:.6}", p3, e01);
    println!("corner |x - 0.05|: slope at 0 = {:.2}, P1(0.1) = {:.2}, f(0.1) = {:.2}, Lagrange needs f'' = {:.1}; f'' at 0.02, 0.08: {:.1}, {:.1}",
        (f(1e-6) - f(-1e-6)) / 2e-6, f(0.0) - h, f(h), 2.0 * (f(h) - f(0.0) + h) / (h * h), d2[0], d2[1]);
    assert!(low <= e01 && e01 <= high && p4 < e01 && e01 < p4 + r4); // road 1 traps road 2
    assert!(0.0 < xi && xi < h); // the point lies between 0 and 0.1
    assert!(format!("{:.6}", low) == format!("{:.6}", high) && format!("{:.6}", high) == format!("{:.6}", e01));
    assert!((0..2).all(|i| (errs[i] / errs[i + 1] - 16.0).abs() < 1.0));
    println!("ALL CHECKS PASS");
}
