// Substitution -- the same check as the Python, in Rust.  No crates; exp and ln
// are primitives.  The area under x e^(x^2) is found by two roads: the
// antiderivative e^u / 2 at the moved limits, with e^u built from its own
// series, and midpoint sums in x and in u, refined until the error closes.

fn exp_series(t: f64) -> f64 {              // e^t = 1 + t + t^2/2! + ..., 60 terms
    let (mut term, mut total) = (1.0, 1.0);
    for k in 1..60 {
        term *= t / k as f64;
        total += term;
    }
    total
}

fn mid(f: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 {   // midpoint sum
    let w = (b - a) / n as f64;
    w * (0..n).map(|k| f(a + (k as f64 + 0.5) * w)).sum::<f64>()
}

fn f_x(x: f64) -> f64 { x * (x * x).exp() }        // the integrand, written in x
fn f_u(u: f64) -> f64 { u.exp() / 2.0 }            // the same integrand, written in u = x^2
fn big_f(u: f64) -> f64 { exp_series(u) / 2.0 }    // an antiderivative in u

fn join(v: &[f64], places: usize) -> String {
    v.iter().map(|x| format!("{:.*}", places, x)).collect::<Vec<_>>().join(" ")
}

fn main() {
    let exact = big_f(1.0) - big_f(0.0);
    println!("road 1, e^u/2 from u = 0 to u = 1: {:.6}  (e = {:.6})", exact, exp_series(1.0));
    let mut errors = Vec::new();
    for n in [10usize, 100, 1000] {
        let s = mid(&f_x, 0.0, 1.0, n);
        errors.push(s - exact);
        println!("road 2, midpoint sum in x, n = {:4}: {:.6}  error {:.9}", n, s, s - exact);
    }
    let u_sum = mid(&f_u, 0.0, 1.0, 1000);
    println!("road 2, midpoint sum in u, n = 1000: {:.6}", u_sum);
    let (x0, h) = (0.7f64, 1e-5);
    let dq = (big_f((x0 + h).powi(2)) - big_f((x0 - h).powi(2))) / (2.0 * h);
    println!("chain rule at x = 0.7: slope of e^(x^2)/2 {:.6}, integrand {:.6}", dq, f_x(x0));
    for (a, b) in [(1i32, 2i32), (1, 0), (-1, 1), (-1, 2)] {
        let (af, bf) = (a as f64, b as f64);
        let s = (mid(&f_x, af, bf, 30000) * 1e9).round() / 1e9 + 0.0;
        println!("x from {} to {}: u from {} to {}; e^u/2 gives {:.6}; x sum {:.6}",
                 a, b, a * a, b * b, big_f(bf * bf) - big_f(af * af), s);
    }
    println!("mistake, x limits 1 and 2 kept on u: {:.6}, not {:.6}", big_f(2.0) - big_f(1.0), big_f(4.0) - big_f(1.0));
    println!("mistake, the 1/2 dropped: {:.6}, not {:.6}", 2.0 * exact, exact);
    let g = |x: f64| 2.0 * x / (x * x - 1.0);      // u = x^2 - 1 passes through 0, where 1/u fails
    println!("mistake, 2x/(x^2 - 1) on 0 to 2: formula ln 3 = {:.6}; area 0 to 0.99 = {:.6} (sum {:.6}); 0 to 0.9999 = {:.6} (sum {:.6})",
             3f64.ln(), 0.0199f64.ln(), mid(&g, 0.0, 0.99, 200000), 0.00019999f64.ln(), mid(&g, 0.0, 0.9999, 200000));
    let pts: Vec<f64> = (0..6).map(|i| i as f64 / 5.0).collect();
    println!("chart, x e^(x^2) at x = 0, 0.2, ..., 1: {}", join(&pts.iter().map(|&p| f_x(p)).collect::<Vec<_>>(), 2));
    println!("chart, e^u/2 at u = 0, 0.2, ..., 1: {}", join(&pts.iter().map(|&p| f_u(p)).collect::<Vec<_>>(), 2));
    let t: Vec<f64> = (0..5).map(|i| i as f64 / 4.0).collect();
    let ts = |f: &dyn Fn(f64) -> f64, p: usize| join(&t.iter().map(|&v| f(v)).collect::<Vec<_>>(), p);
    println!("figure, x ticks {} at px {}", ts(&|v| v, 4), ts(&|v| 30.0 + 300.0 * v, 2));
    println!("figure, u marks {} at px {}", ts(&|v| v * v, 4), ts(&|v| 30.0 + 300.0 * v * v, 2));
    println!("figure, u strip widths {} = 2 x centre x 0.25, centres {}",
             join(&t.windows(2).map(|w| w[1] * w[1] - w[0] * w[0]).collect::<Vec<_>>(), 4),
             join(&t[..4].iter().map(|&a| a + 0.125).collect::<Vec<_>>(), 4));
    assert!((mid(&f_x, 0.0, 1.0, 1000) - exact).abs() < 1e-6);   // x-road meets the moved-limit antiderivative
    assert!((u_sum - exact).abs() < 1e-6);                        // u-road meets it too
    assert!((dq - f_x(x0)).abs() < 1e-6);                         // the chain rule, by difference quotient
    assert!((mid(&f_x, -1.0, 2.0, 30000) - (big_f(4.0) - big_f(1.0))).abs() < 1e-5 && errors[2].abs() < errors[1].abs() / 50.0);
    println!("ALL CHECKS PASS");
}
