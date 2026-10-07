// Solving backwards -- the same check as the Python, in Rust.  Std only, no crates, and
// nothing borrowed that already knows an answer: the bell-curve area N(x) is built from
// thin slices (Simpson's rule), and bisection, Newton and Brent are written out here.  One
// step means one trip through the pricer.  Case one takes the Acme call quote
// 9.227005508154 back to 0.20 three ways; case two runs the same three on a bond yield.
use std::f64::consts::PI;

const S: f64 = 100.0; const K: f64 = 100.0; const R: f64 = 0.05;     // the house market
const Q: f64 = 0.02; const T: f64 = 1.0;
const CF: [f64; 5] = [4.0, 4.0, 4.0, 4.0, 104.0];    // 4% annual coupon, 100 face, 5 years

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }   // bell-curve height
fn n_cdf(x: f64) -> f64 {                            // bell-curve area to the left of x
    if x < 0.0 { return 1.0 - n_cdf(-x); }
    if x > 8.0 { return 1.0; }
    let (mut s, h) = (phi(0.0) + phi(x), x / 1000.0); // Simpson's rule, written out
    for i in 1..1000 { s += (if i % 2 == 1 { 4.0 } else { 2.0 }) * phi(i as f64 * h); }
    0.5 + s * h / 3.0
}
fn d1_of(sig: f64, k: f64) -> f64 { ((S / k).ln() + (R - Q + 0.5 * sig * sig) * T) / (sig * T.sqrt()) }
fn price(sig: f64, k: f64) -> f64 {                  // the call price at volatility sig
    let d1 = d1_of(sig, k);
    S * (-Q * T).exp() * n_cdf(d1) - k * (-R * T).exp() * n_cdf(d1 - sig * T.sqrt())
}
fn vega(sig: f64, k: f64) -> f64 { S * (-Q * T).exp() * phi(d1_of(sig, k)) * T.sqrt() }  // dC/dsig

fn bisect<F: Fn(f64) -> f64>(f: &F, lo: f64, hi: f64, tol: f64) -> (f64, usize) {
    let (mut lo, mut hi) = (lo, hi);                 // halve the bracket, no slope needed
    let (mut flo, mut n) = (f(lo), 1usize);
    while hi - lo > tol {
        let mid = 0.5 * (lo + hi); let fm = f(mid); n += 1;
        if (fm > 0.0) == (flo > 0.0) { lo = mid; flo = fm; } else { hi = mid; }
    }
    (0.5 * (lo + hi), n)
}
type Rows = Vec<(usize, f64, f64, f64)>;
fn newton<F: Fn(f64) -> f64, G: Fn(f64) -> f64>(f: &F, fp: &G, x0: f64, tol: f64, cap: usize)
        -> (f64, Rows, String) {                     // slide down the tangent line
    let (mut x, mut rows): (f64, Rows) = (x0, Vec::new());
    for n in 1..=cap {
        let (fx, sl) = (f(x), fp(x)); rows.push((n, x, fx, sl));
        if fx.abs() < tol { return (x, rows, format!("converged after {} steps", n)); }
        if sl == 0.0 { return (x, rows, "the slope vanished".to_string()); }
        x -= fx / sl;
        if x <= 0.0 { return (x, rows, format!("left the region after {} steps", n)); }
    }
    (x, rows, "hit the step cap".to_string())
}
fn brent<F: Fn(f64) -> f64>(f: &F, lo: f64, hi: f64, tol: f64) -> (f64, usize, usize, String) {
    let (mut a, mut b) = (lo, hi);                   // a fast step with a midpoint net
    let (mut fa, mut fb) = (f(a), f(b)); let (mut n, mut mid) = (2usize, 0usize);
    if (fa > 0.0) == (fb > 0.0) { return (b, n, mid, "no sign change".to_string()); }
    if fa.abs() < fb.abs() { (a, b, fa, fb) = (b, a, fb, fa); }
    let (mut c, mut fc, mut d, mut wide) = (a, fa, a, true);
    while (b - a).abs() > tol && fb != 0.0 {
        let mut s = if fa != fc && fb != fc {        // inverse quadratic, three points
            a * fb * fc / ((fa - fb) * (fa - fc)) + b * fa * fc / ((fb - fa) * (fb - fc))
                + c * fa * fb / ((fc - fa) * (fc - fb))
        } else { b - fb * (b - a) / (fb - fa) };     // secant, two points
        let edge = (3.0 * a + b) / 4.0;
        let stalled = (s - b).abs() >= 0.5 * (if wide { (b - c).abs() } else { (c - d).abs() });
        if !(edge.min(b) < s && s < edge.max(b)) || stalled {
            s = 0.5 * (a + b); wide = true; mid += 1;
        } else { wide = false; }
        let fs = f(s); n += 1; (d, c, fc) = (c, b, fb);
        if (fa > 0.0) != (fs > 0.0) { b = s; fb = fs; } else { a = s; fa = fs; }
        if fa.abs() < fb.abs() { (a, b, fa, fb) = (b, a, fb, fa); }
    }
    (b, n, mid, format!("converged after {} steps", n))
}

fn dfac(y: f64, k: usize) -> f64 {                   // discount factor, one divide per year
    let mut v = 1.0;
    for _ in 0..k { v /= 1.0 + y; }
    v
}
fn bond(y: f64) -> f64 {                             // road one: payment by payment
    let mut s = 0.0;
    for (i, c) in CF.iter().enumerate() { s += c * dfac(y, i + 1); }
    s
}
fn bond_annuity(y: f64) -> f64 { 4.0 * (1.0 - dfac(y, 5)) / y + 100.0 * dfac(y, 5) }  // annuity form
fn bond_slope(y: f64) -> f64 {
    let mut s = 0.0;
    for (i, c) in CF.iter().enumerate() { s += (i + 1) as f64 * c * dfac(y, i + 2); }
    -s
}
fn row(name: &str, v: f64) { println!("{:<48}{:>18.12}", name, v); }
fn txt(name: &str, v: &str) { println!("{:<48}{:>18}", name, v); }

fn main() {
    let quote = price(0.20, K);
    let f = |x: f64| price(x, K) - quote;
    let mut vfloor = f64::INFINITY;
    for i in 0..3001 { let v = vega(0.10 + 0.0001 * i as f64, K); if v < vfloor { vfloor = v; } }
    row("the quote: Acme call at sigma = 0.20", quote);
    row("the shelf's delta, e^-qT N(d1)", (-Q * T).exp() * n_cdf(d1_of(0.20, K)));
    row("vega at sigma = 0.20, dollars per 1.00 of vol", vega(0.20, K));
    row("  the same slope by bumping sigma", (price(0.2001, K) - price(0.1999, K)) / 0.0002);
    row("  smallest vega on [0.10, 0.40]", vfloor);
    row("price floor, sigma -> 0: S e^-qT - K e^-rT", S * (-Q * T).exp() - K * (-R * T).exp());
    row("  price at sigma = 0.01", price(0.01, K));
    row("  vega at sigma = 0.01", vega(0.01, K));
    row("price ceiling, sigma -> infinity: S e^-qT", S * (-Q * T).exp());
    let sigs: Vec<f64> = (1..9).map(|i| 0.05 * i as f64).collect();
    let mut l1 = format!("{:<32}", "chart, volatility in percent");
    let mut l2 = format!("{:<32}", "chart, Acme call price ($)");
    let mut l3 = format!("{:<32}", "chart, the quote ($)");
    for x in &sigs { l1 += &format!("{:>7.0}", 100.0 * x); l3 += &format!("{:>7.2}", quote);
                     l2 += &format!("{:>7.2}", price(*x, K)); }
    println!("{}\n{}\n{}", l1, l2, l3);
    println!("newton from sigma = 1.00:  step, sigma, residual ($), vega ($)");
    let (sig_n, nrows, nstatus) = newton(&f, &|x| vega(x, K), 1.00, 1e-12, 30);
    for (n, x, fx, sl) in &nrows { println!("  {:>2}{:>18.12}{:>18.12}{:>18.12}", n, x, fx, sl); }
    txt("  newton", &nstatus);
    let (sig_b, steps_b) = bisect(&f, 0.01, 1.00, 1e-12);
    row("bisection on [0.01, 1.00], root", sig_b);
    txt("  steps", &format!("{}", steps_b));
    let (sig_r, steps_r, mids, _) = brent(&f, 0.01, 1.00, 1e-12);
    row("brent on [0.01, 1.00], root", sig_r);
    txt("  steps", &format!("{}", steps_r));
    row("gap between the newton and bisection roots", (sig_n - sig_b).abs());
    row("residual at the newton root, dollars", f(sig_n).abs());
    row("  that residual divided by the smallest vega", f(sig_n).abs() / vfloor);
    row("  one cent of residual, in volatility", 0.01 / vfloor);
    println!("steps to pin sigma to 12 decimals, one block = one step");
    for (label, count) in [("bisection", steps_b), ("brent", steps_r), ("newton", nrows.len())] {
        println!("  {:<11}{:<42}{:>3}", label, "\u{2588}".repeat(count), count);
    }
    let sig_round = brent(&|x| price(x, K) - 9.23, 0.01, 1.00, 1e-12).0;
    row("quote rounded to 9.23: sigma", sig_round);
    row("  volatility points away from 20.000", 100.0 * (sig_round - 0.20).abs());
    row("wing K = 200: price at sigma = 0.20", price(0.20, 200.0));
    row("  vega there", vega(0.20, 200.0));
    let target = price(0.20, 200.0) + 0.01;
    let wing = brent(&|x| price(x, 200.0) - target, 0.01, 1.00, 1e-12);
    row("  sigma from a quote one cent higher", wing.0);
    row("  volatility points away from 20.000", 100.0 * (wing.0 - 0.20).abs());
    txt("midpoint fallbacks: at the money, then on the wing", &format!("{} and {}", mids, wing.2));
    let wrows = newton(&f, &|x| vega(x, K), 0.01, 1e-12, 30).1;
    row("no bracket, newton from 0.01: sigma after 1 step", wrows[1].1);
    row("  vega there", wrows[1].3);
    txt("  next step proposes minus a sigma of order 10^",
        &format!("{}", (wrows[1].1 - wrows[1].2 / wrows[1].3).abs().log10() as i64));
    row("bisection on [0.01, 0.10], both ends low", bisect(&f, 0.01, 0.10, 1e-12).0);
    txt("quote 2.50, below the floor: brent reports", &brent(&|x| price(x, K) - 2.50, 0.01, 1.00, 1e-12).3);
    println!("bond: 4% annual coupon, 100 face, 5 years, quoted 96.00");
    let g = |y: f64| bond(y) - 96.00;
    let y_b = bisect(&g, 0.001, 0.50, 1e-14).0;
    let y_n = newton(&g, &bond_slope, 0.10, 1e-12, 30).0;
    let y_r = brent(&g, 0.001, 0.50, 1e-14).0;
    row("  yield by bisection", y_b);
    row("  yield by newton", y_n);
    row("  yield by brent", y_r);
    row("  price at that yield, payment by payment", bond(y_n));
    row("  the same price by the annuity formula", bond_annuity(y_n));
    assert!((quote - 9.227005508154).abs() < 1e-9, "the pricer must reproduce the shelf's quote");
    assert!(((-Q * T).exp() * n_cdf(d1_of(0.20, K)) - 0.586851).abs() < 1e-6, "delta vs the shelf's number");
    assert!((vega(0.20, K) - (price(0.2001, K) - price(0.1999, K)) / 0.0002).abs() < 1e-6, "vega vs a bump");
    assert!((sig_b - 0.20).abs() < 1e-11 && (sig_r - 0.20).abs() < 1e-11, "bisection and brent find 0.20");
    assert!((sig_n - 0.20).abs() < 1e-14 && (sig_n - sig_b).abs() < 1e-11, "newton agrees with bisection");
    assert!((sig_n - 0.20).abs() <= f(sig_n).abs() / vfloor + 1e-16, "the residual bound holds");
    assert!((nrows[3].1 - 0.20).abs() <= nrows[3].2.abs() / vfloor, "and it bites at step 4");
    assert!((0..7).all(|i| price(sigs[i], K) < price(sigs[i + 1], K)), "the price climbs with vol");
    assert!(vfloor > 36.0 && (price(0.01, K) - (S * (-Q * T).exp() - K * (-R * T).exp())).abs() < 1e-3);
    assert!((y_n - y_b).abs() < 1e-12 && (y_r - y_b).abs() < 1e-12, "three solvers, one yield");
    assert!((bond(y_n) - bond_annuity(y_n)).abs() < 1e-9, "two roads to the bond price");
    assert!((wing.0 - 0.20).abs() > 100.0 * (sig_round - 0.20).abs(), "a flat slope hurts far more");
    println!("ALL CHECKS PASS");
}
