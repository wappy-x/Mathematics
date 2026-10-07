// Growth, decay and cooling -- the same check as the Python, in Rust.  No
// crates.  y' = k y is answered by two roads: the closed form y0 e^(kt), and
// Euler's small steps along the slope, which never call exp.  Times and rates
// are found twice: by a logarithm, and by bisection, which halves a bracket
// around the answer and never calls log.
fn closed(y0: f64, k: f64, t: f64) -> f64 { y0 * (k * t).exp() } // the theorem

fn euler(y0: f64, k: f64, t_end: f64, h: f64) -> f64 {  // new = old + step x rate
    let mut y = y0;
    for _ in 0..(t_end / h).round() as usize { y += h * k * y }
    y
}

fn bisect(f: &dyn Fn(f64) -> f64, mut lo: f64, mut hi: f64) -> f64 {
    for _ in 0..100 {                                     // f changes sign in the bracket
        let mid = (lo + hi) / 2.0;
        if f(lo) * f(mid) > 0.0 { lo = mid } else { hi = mid }
    }
    (lo + hi) / 2.0
}

fn coffee(t: f64) -> f64 { 20.0 + closed(60.0, -0.1, t) } // the gap T - 20 decays

fn fmt(xs: &[f64], d: usize) -> String {
    xs.iter().map(|x| format!("{:.*}", d, x)).collect::<Vec<_>>().join(" ")
}

fn main() {
    let ln2 = 2f64.ln();
    let bal = closed(5000.0, 0.04, 10.0);
    let hs = [1.0, 0.5, 0.25];
    let steps: Vec<f64> = hs.iter().map(|&h| euler(5000.0, 0.04, 10.0, h)).collect();
    let errs: Vec<f64> = steps.iter().map(|y| (y - bal).abs()).collect();
    let k14 = -ln2 / 5730.0;
    let k14_b = bisect(&|k| closed(1.0, k, 5730.0) - 0.5, -0.01, 0.0);
    let (t50, t50_b) = (10.0 * ln2, bisect(&|t| coffee(t) - 50.0, 0.0, 30.0));
    let slope = (coffee(5.001) - coffee(4.999)) / 0.002;
    let ts: Vec<f64> = (0..7).map(|i| 5.0 * i as f64).collect();
    let temps: Vec<f64> = ts.iter().map(|&t| coffee(t)).collect();
    let fine = euler(5000.0, 0.04, 10.0, 0.001);
    println!("balance: 5000 at 4% continuous for 10 years = {:.2} dollars", bal);
    println!("Euler, h = 1, 0.5, 0.25 years: {}", fmt(&steps, 2));
    println!("Euler, h = 0.001 years: {:.2}; errors at h = 1, 0.5, 0.25: {}", fine, fmt(&errs, 2));
    println!("error ratios on halving h: {:.3} {:.3}", errs[0] / errs[1], errs[1] / errs[2]);
    println!("ln 2 = {:.4}; doubling time ln 2 / 0.04 = {:.2} years; e^0.4 = {:.6}", ln2, ln2 / 0.04, 0.4f64.exp());
    println!("carbon-14 k: -ln 2 / 5730 = {:.9}; bisection on e^(5730k) = 1/2 gives {:.9} per year", k14, k14_b);
    println!("bone with 30% of its carbon-14 left: ln 0.3 = {:.4}, / k = {:.0} years", 0.3f64.ln(), 0.3f64.ln() / k14);
    println!("coffee t (min): {}", fmt(&ts, 0));
    println!("coffee T (C):   {}", fmt(&temps, 2));
    println!("coffee reaches 50 C: 10 ln 2 = {:.4} min; bisection = {:.4} min", t50, t50_b);
    let gap = coffee(5.0) - 20.0;
    println!("k read back from the gap T(5) - 20 = {:.2}: ln(gap / 60) / 5 = {:.4} per min", gap, (gap / 60.0).ln() / 5.0);
    println!("rate at t = 5: finite difference {:.4}; law -0.1(T - 20) = {:.4} C/min", slope, -0.1 * (coffee(5.0) - 20.0));
    println!("mistake, cool toward 0 C: 80 e^(-0.1t) hits 50 at {:.2} min", (80.0f64 / 50.0).ln() / 0.1);
    println!("mistake, k from raw temperatures: ln(T(5) / 80) / 5 = {:.4} per min", (coffee(5.0) / 80.0).ln() / 5.0);
    println!("mistake, k = -1/5730 (ln 2 dropped): bone age {:.0} years", 0.3f64.ln() * -5730.0);
    println!("hypothesis dropped, 4% then 2% after year 5: {:.2}, not {:.2}", closed(closed(5000.0, 0.04, 5.0), 0.02, 5.0), bal);
    assert!((fine - bal).abs() < 0.1);                                    // road two meets road one
    assert!(errs[0] / errs[1] > 1.9 && errs[0] / errs[1] < 2.1 && errs[1] / errs[2] > 1.9 && errs[1] / errs[2] < 2.1);
    assert!((t50_b - t50).abs() < 1e-9 && (k14_b - k14).abs() < 1e-8);     // logs against bisection
    assert!((slope + 0.1 * (coffee(5.0) - 20.0)).abs() < 1e-6);           // the answer obeys the law
    println!("ALL CHECKS PASS");
}
