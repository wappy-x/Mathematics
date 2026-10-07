// Limit laws and the squeeze -- the same check as the Python, in Rust, std
// only; f64::sin is the one primitive.  h(x) = x^2 sin(1/x) heads for 0 as x
// heads for 0.  Road one: the squeeze bound x^2 picks the window sqrt(eps).
// Road two: a brute scan of h itself on that window, sharing no arithmetic.
use std::f64::consts::PI;

fn h(x: f64) -> f64 {
    x * x * (1.0 / x).sin()
}

fn scan(f: &dyn Fn(f64) -> f64, width: f64) -> Vec<f64> {
    let n = 200000; // every grid point with 0 < |x| < width
    let mut out = Vec::new();
    for k in 1..n {
        let x = width * k as f64 / n as f64;
        out.push(f(x));
        out.push(f(-x));
    }
    out
}

fn list(v: &[f64], places: usize) -> String {
    v.iter().map(|x| format!("{:.*}", places, x)).collect::<Vec<_>>().join(", ")
}

fn main() {
    for x in [0.1, 0.01, 0.001] {
        println!("x = {}: h = {:.8}, bound x^2 = {:.8}", x, h(x), x * x);
    }
    let mut worst = Vec::new();
    for eps in [0.01_f64, 0.001, 0.00001] {
        let delta = eps.sqrt(); // road one: x^2 < eps once |x| < sqrt(eps)
        let w = scan(&h, delta).iter().fold(0.0_f64, |m, v| m.max(v.abs())); // road two
        worst.push((eps, w));
        println!("tolerance {:.6}: window {:.6}, largest |h| found {:.8}", eps, delta, w);
    }
    let sines = scan(&|x: f64| (1.0 / x).sin(), 0.001);
    let top = sines.iter().cloned().fold(f64::MIN, f64::max);
    let bottom = sines.iter().cloned().fold(f64::MAX, f64::min);
    println!("sin(1/x) for 0 < |x| < 0.001 reaches {:.6} and {:.6}", top, bottom);
    let peaks: Vec<f64> = (1..9).map(|n| 1.0 / (PI / 2.0 + n as f64 * PI)).collect();
    let by_sine: Vec<f64> = peaks.iter().map(|&x| h(x)).collect();
    let by_sign: Vec<f64> = (1..9).zip(&peaks).map(|(n, &x)| if n % 2 == 0 { x * x } else { -x * x }).collect();
    let k = |v: &Vec<f64>, s: f64| v.iter().map(|x| s * 1000.0 * x).collect::<Vec<f64>>();
    let squares: Vec<f64> = peaks.iter().map(|x| x * x).collect();
    println!("chart x:                  {}", list(&peaks, 4));
    println!("chart h, thousandths:     {}", list(&k(&by_sine, 1.0), 2));
    println!("chart x^2, thousandths:   {}", list(&k(&squares, 1.0), 2));
    println!("chart -x^2, thousandths:  {}", list(&k(&squares, -1.0), 2));
    let law = (0.0 + 5.0) / (0.0 + 2.0); // limits of the parts: h -> 0, x -> 0
    let direct: Vec<f64> = [0.01, 0.001, 0.000001].iter().map(|&x| (h(x) + 5.0) / (x + 2.0)).collect();
    println!("(h + 5)/(x + 2): laws give {:.6}; direct at 0.01, 0.001, 0.000001: {}", law, list(&direct, 6));
    let gaps: Vec<f64> = direct.iter().map(|v| (v - law).abs()).collect();
    println!("gap from 2.5 at those three points: {}", list(&gaps, 6));
    println!("infinite limit: 1/x^2 at 0.001 is {:.0}; 1/x at 0.001 and -0.001 is {:.0} and {:.0}; at infinity: 1/x at 1000 is {:.6}",
        1.0 / (0.001_f64 * 0.001), 1.0 / 0.001, 1.0 / -0.001, 1.0 / 1000.0);
    println!("mistake, bounds -1 and 1 disagree: sin(1/x) at x = {:.4} and {:.4} is {:.0} and {:.0}",
        peaks[7], peaks[6], (1.0 / peaks[7]).sin(), (1.0 / peaks[6]).sin());
    println!("mistake, 0/0 at x = 0.001: x/x = {:.0}, x^2/x = {:.6}, x/x^2 = {:.0}",
        0.001 / 0.001, 0.001_f64 * 0.001 / 0.001, 0.001 / (0.001_f64 * 0.001));
    assert!(worst.iter().all(|&(e, w)| w < e)); // the squeeze window works
    assert!(top > 0.999 && bottom < -0.999); // the factor never settles
    assert!(by_sine.iter().zip(&by_sign).all(|(a, b)| (a - b).abs() < 1e-12));
    assert!(gaps[0] > gaps[1] && gaps[1] > gaps[2] && gaps[2] < 0.00001); // looking agrees with laws
    println!("ALL CHECKS PASS");
}
