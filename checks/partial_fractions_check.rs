// Partial fractions -- the same check as the Python, in Rust.  std only;
// ln is the one primitive used, and arctan is built from its own series.
// Road one: split the fraction, integrate each piece to a log (or an arctan).
// Road two: a Simpson sum of the original, unsplit curve, refined until it closes.

fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64; // n even; weights 1, 4, 2, 4, ..., 4, 1
    let mut inner = 0.0;
    for k in 1..n {
        inner += (if k % 2 == 1 { 4.0 } else { 2.0 }) * f(a + k as f64 * h);
    }
    (f(a) + f(b) + inner) * h / 3.0
}

fn arctan(y: f64) -> f64 { // the series y - y^3/3 + y^5/5 - ..., for small y
    (0..30).map(|k: i32| (-1.0_f64).powi(k) * y.powi(2 * k + 1) / (2 * k + 1) as f64).sum()
}

fn main() {
    let f = |x: f64| 1.0 / (x * x - 1.0);
    let (a, b) = (1.0 / (1.0 + 1.0), 1.0 / (-1.0 - 1.0)); // cover-up at x = 1 and x = -1
    let (am, bm) = ((0.0 + 1.0) / 2.0, (0.0 - 1.0) / 2.0); // matching: A + B = 0, A - B = 1
    println!("cover-up: A = {:.6}, B = {:.6}; matching coefficients: A = {:.6}, B = {:.6}", a, b, am, bm);
    let gap = [-3.0, -0.5, 0.5, 2.0, 2.5, 3.0, 10.0_f64].iter()
        .map(|&x| (f(x) - (a / (x - 1.0) + b / (x + 1.0))).abs()).fold(0.0, f64::max);
    println!("1/(x^2 - 1) against the two pieces at seven points, largest gap below 1e-12: {}", if gap < 1e-12 { "yes" } else { "no" });
    let big_f = |x: f64| a * (x - 1.0).abs().ln() + b * (x + 1.0).abs().ln();
    let two_logs = big_f(3.0) - big_f(2.0);
    println!("two logs on 2..3: F(3) - F(2) = {:.6}; half of ln(3/2) = {:.6}", two_logs, 0.5 * 1.5_f64.ln());
    for n in [4usize, 8, 16] {
        let s = simpson(&f, 2.0, 3.0, n);
        println!("Simpson, {:2} strips: {:.10}, error {:.10}", n, s, s - two_logs);
    }
    for x in [2.0, 2.25, 2.5, 2.75, 3.0_f64] {
        println!("chart, x = {:.2}: curve {:.2}, A/(x - 1) {:.2}, B/(x + 1) {:.2}", x, f(x), a / (x - 1.0), b / (x + 1.0));
    }
    let div = (9.0 - 4.0) / 2.0 + 0.5 * (8.0_f64 / 3.0).ln(); // x^3/(x^2 - 1) = x + x/(x^2 - 1)
    println!("divide first, x^3/(x^2 - 1): {:.6} + {:.6} = {:.6}; Simpson {:.6}", (9.0 - 4.0) / 2.0, div - (9.0 - 4.0) / 2.0, div, simpson(&|x: f64| x.powi(3) / (x * x - 1.0), 2.0, 3.0, 64));
    let g = |x: f64| 0.25 * (-1.0 / (x - 1.0) - (x - 1.0).ln() - 1.0 / (x + 1.0) + (x + 1.0).ln());
    let rep = g(3.0) - g(2.0); // pieces -1/4, 1/4 on the logs; 1/4, 1/4 on the squares
    let sq = |x: f64| f(x) * f(x);
    println!("repeated, 1/(x^2 - 1)^2: {:.6}; Simpson {:.6}", rep, simpson(&sq, 2.0, 3.0, 64));
    let quad = 0.5 * two_logs - 0.5 * arctan(1.0 / 7.0); // arctan 3 - arctan 2 = arctan(1/7)
    let q4 = |x: f64| 1.0 / (x.powi(4) - 1.0);
    println!("quadratic, 1/(x^4 - 1): {:.6}; Simpson {:.6}; arctan(1/7) {:.6}", quad, simpson(&q4, 2.0, 3.0, 64), arctan(1.0 / 7.0));
    println!("mistake, the half forgotten: {:.6}, not {:.6}", 1.5_f64.ln(), two_logs);
    println!("mistake, no division, pieces 1/2 and 1/2: {:.6}, not {:.6}", 0.5 * (8.0_f64 / 3.0).ln(), div);
    println!("mistake, repeated factor given logs only: {:.6}, not {:.6}", 0.25 * (-2.0_f64.ln() + 4.0_f64.ln() - 3.0_f64.ln()), rep);
    println!("mistake, F(2) - F(0) across the wall at 1: {:.6}; 0 to 0.9999 alone {:.6}, to 0.999999 {:.6}",
             big_f(2.0) - big_f(0.0), big_f(0.9999) - big_f(0.0), big_f(0.999999) - big_f(0.0));
    assert!(gap < 1e-12); // the pieces rebuild the curve
    assert!((two_logs - simpson(&f, 2.0, 3.0, 256)).abs() < 1e-10); // logs against strips
    assert!((rep - simpson(&sq, 2.0, 3.0, 256)).abs() < 1e-9);
    assert!((quad - simpson(&q4, 2.0, 3.0, 256)).abs() < 1e-9);
    println!("ALL CHECKS PASS");
}
