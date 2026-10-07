// Blow-up -- the same check as the Python, in Rust.  No crates.  The square
// scheme y' = 0.01 y^2, y(0) = 10 is answered by three roads: the closed form
// y = 100/(10 - t); Euler's small steps along the slope; and the time for each
// doubling, integrated by Simpson's rule and summed.  None calls another.
const K: f64 = 0.01;
const Y0: f64 = 10.0;

fn closed(t: f64) -> f64 { 1.0 / (1.0 / Y0 - K * t) }    // 1/y0 - 1/y = k t

fn euler(f: &dyn Fn(f64) -> f64, mut y: f64, t_end: f64, h: f64) -> f64 {
    for _ in 0..(t_end / h).round() as usize { y += h * f(y) } // new = old + step x rate
    y
}

fn simpson(g: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 {
    let w = (b - a) / n as f64;                           // area under g, n even
    let s: f64 = (0..=n).map(|i| {
        let c = if i == 0 || i == n { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 };
        g(a + i as f64 * w) * c
    }).sum();
    w / 3.0 * s
}

fn fmt(xs: &[f64], d: usize) -> String {
    xs.iter().map(|x| format!("{:.*}", d, x)).collect::<Vec<_>>().join(" ")
}

fn main() {
    let sq = |y: f64| K * y * y;
    let lin = |y: f64| 0.1 * y;
    let span = |j: i32| (Y0 * 2f64.powi(j), Y0 * 2f64.powi(j + 1));
    let dbl: Vec<f64> = (0..40).map(|j| { let (a, b) = span(j); simpson(&|y| 1.0 / sq(y), a, b, 100) }).collect();
    let dbl_lin: Vec<f64> = (0..40).map(|j| { let (a, b) = span(j); simpson(&|y| 1.0 / lin(y), a, b, 100) }).collect();
    let (mut lo, mut hi) = (0.0f64, 20.0f64);             // bisection: 10 e^(0.1t) = 20
    for _ in 0..100 {
        let mid = (lo + hi) / 2.0;
        if 10.0 * (0.1 * mid).exp() < 20.0 { lo = mid } else { hi = mid }
    }
    let (mut t, mut y, h) = (0.0f64, Y0, 1e-4);           // Euler until a million members
    while y < 1e6 { y += h * sq(y); t += h; }
    let hs = [0.1, 0.05, 0.025];
    let e5: Vec<f64> = hs.iter().map(|&h| euler(&sq, Y0, 5.0, h)).collect();
    let errs: Vec<f64> = e5.iter().map(|v| (v - closed(5.0)).abs()).collect();
    let ts: Vec<f64> = (0..10).map(|i| i as f64).chain(std::iter::once(9.5)).collect();
    let sum: f64 = dbl.iter().sum();
    let sum_lin: f64 = dbl_lin.iter().sum();
    println!("square scheme: y' = 0.01 y^2, y(0) = 10; blow-up time 1/(k y0) = {:.2} months", 1.0 / (K * Y0));
    println!("starting rate: square 0.01 x 10^2 = {:.2}, linear 0.1 x 10 = {:.2} members per month", sq(Y0), lin(Y0));
    println!("t (months):  {}", fmt(&ts, 1));
    println!("square y:    {}", fmt(&ts.iter().map(|&s| closed(s)).collect::<Vec<_>>(), 2));
    println!("linear y:    {}", fmt(&ts.iter().map(|&s| 10.0 * (0.1 * s).exp()).collect::<Vec<_>>(), 2));
    println!("linear at t = 10: {:.2} members; doubling ln 2 / 0.1 = {:.4}, bisection {:.4} months", 10.0 * 1f64.exp(), 2f64.ln() / 0.1, lo);
    println!("square doublings, 10->20, 20->40, ... (Simpson): {} months", fmt(&dbl[..5], 4));
    println!("sum of 40 square doublings = {:.6} months, ending at {:.0} members", sum, Y0 * 2f64.powi(40));
    println!("linear doublings (Simpson): {} ...; 40 of them = {:.2} months", fmt(&dbl_lin[..3], 4), sum_lin);
    println!("Euler, h = 0.0001, passes 1,000,000 members at t = {:.4}; formula: {:.4}", t, 1.0 / (K * Y0) - 1.0 / (K * 1e6));
    println!("Euler at t = 5, h = 0.1, 0.05, 0.025: {}; exact {:.4}", fmt(&e5, 4), closed(5.0));
    println!("errors {}; ratios on halving h: {:.3} {:.3}", fmt(&errs, 4), errs[0] / errs[1], errs[1] / errs[2]);
    println!("life span 1/(k y0) for y0 = 5, 20, 100: {} months", fmt(&[5.0, 20.0, 100.0].map(|v: f64| 1.0 / (K * v)), 2));
    println!("bucket h' = -0.2 sqrt(h), h(0) = 25: h = (5 - 0.1t)^2 is 0 at t = {:.2}, its edge", 25f64.sqrt() / 0.1);
    println!("mistake, exponential at the starting rate 0.1 per month: y(10) = {:.2}, not infinite", 10.0 * 1f64.exp());
    println!("mistake, formula read past blow-up, t = 12: y = {:.2} members", closed(12.0));
    println!("mistake, Euler with h = 0.5 steps through t = 10: y(10) = {:.2}", euler(&sq, Y0, 10.0, 0.5));
    assert!((sum - 1.0 / (K * Y0)).abs() < 1e-6);         // doubling sum meets the formula
    assert!((t - 10.0).abs() < 0.01);                      // Euler's blow-up time meets it too
    assert!(errs[0] / errs[1] > 1.8 && errs[0] / errs[1] < 2.2 && errs[1] / errs[2] > 1.8 && errs[1] / errs[2] < 2.2);
    assert!((lo - dbl_lin[0]).abs() < 1e-6);               // bisection meets Simpson on 6.93
    println!("ALL CHECKS PASS");
}
