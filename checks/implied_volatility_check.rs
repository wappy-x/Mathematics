// Implied volatility -- the same check as implied_volatility_check.py, in Rust.
// Standard library only, no crates.  Rust has no erf, so the bell-curve area
// N(x) is built by adding thin slices under the curve (Simpson's rule).
// Compile: rustc --edition 2021 -O implied_volatility_check.rs -o /tmp/iv_check
use std::f64::consts::PI;

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }     // bell-curve height at x

fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    s * h / 3.0
}

fn n_cdf(x: f64) -> f64 {                                                // area to the left of x
    if x < -12.0 { return 0.0; }
    if x > 12.0 { return 1.0; }
    0.5 + simpson(&phi, 0.0, x, 4000)
}

fn call(s: f64, k: f64, r: f64, q: f64, v: f64, t: f64) -> f64 {        // road 1: the formula
    let d1 = ((s / k).ln() + (r - q + 0.5 * v * v) * t) / (v * t.sqrt());
    s * (-q * t).exp() * n_cdf(d1) - k * (-r * t).exp() * n_cdf(d1 - v * t.sqrt())
}

fn put(s: f64, k: f64, r: f64, q: f64, v: f64, t: f64) -> f64 {         // the put formula, written separately
    let d1 = ((s / k).ln() + (r - q + 0.5 * v * v) * t) / (v * t.sqrt());
    k * (-r * t).exp() * n_cdf(v * t.sqrt() - d1) - s * (-q * t).exp() * n_cdf(-d1)
}

fn call_by_integral(s: f64, k: f64, r: f64, q: f64, v: f64, t: f64) -> f64 { // road 2: no d1, no d2
    let f = |z: f64| (s * ((r - q - 0.5 * v * v) * t + v * t.sqrt() * z).exp() - k).max(0.0) * phi(z);
    (-r * t).exp() * simpson(&f, -10.0, 10.0, 20000)
}

fn bisect(price: &dyn Fn(f64) -> f64, quote: f64, mut lo: f64, mut hi: f64, steps: usize) -> f64 {
    for _ in 0..steps {
        let mid = 0.5 * (lo + hi);
        if price(mid) < quote { lo = mid; } else { hi = mid; }
    }
    0.5 * (lo + hi)
}

fn implied(quote: f64, floor: f64, ceiling: f64, price: &dyn Fn(f64) -> f64) -> Option<f64> {
    if !(floor < quote && quote < ceiling) { return None; }             // outside the range: no volatility
    Some(bisect(price, quote, 1e-6, 10.0, 60))
}

fn main() {
    let (s, k, r, q, t) = (100.0_f64, 100.0_f64, 0.05_f64, 0.02_f64, 1.0_f64);
    let (a, b) = (s * (-q * t).exp(), k * (-r * t).exp());              // prepaid share, discounted strike
    let (floor_c, ceil_c, floor_p, ceil_p) = ((a - b).max(0.0), a, (b - a).max(0.0), b);
    let (qc, qp) = (9.227005508154_f64, 6.330080627550_f64);
    let c = |v: f64| call(s, k, r, q, v, t);
    let iv1 = implied(qc, floor_c, ceil_c, &c).unwrap();
    let iv2 = bisect(&|v: f64| call_by_integral(s, k, r, q, v, t), qc, 0.05, 1.0, 40);
    let iv3 = implied(qp, floor_p, ceil_p, &|v: f64| put(s, k, r, q, v, t)).unwrap();
    let d1 = ((s / k).ln() + (r - q + 0.5 * iv1 * iv1) * t) / (iv1 * t.sqrt());
    let vega_an = a * phi(d1) * t.sqrt();
    let vega_fd = (c(0.2 + 1e-4) - c(0.2 - 1e-4)) / 2e-4;

    let rows: Vec<(&str, f64)> = vec![
        ("floor, sigma -> 0: max(A - B, 0)", floor_c), ("ceiling, sigma -> oo: A = S e^-qT", ceil_c),
        ("  price at sigma = 0.01", c(0.01)), ("  price at sigma = 20", c(20.0)),
        ("put floor", floor_p), ("put ceiling: B = K e^-rT", ceil_p),
        ("1 implied vol, formula + bisection", iv1), ("2 implied vol, Simpson price", iv2),
        ("3 implied vol of the put quote", iv3),
        ("vega at 0.20, A phi(d1) sqrt(T)", vega_an), ("vega at 0.20, by bump", vega_fd),
        ("dollars per vol point", vega_an / 100.0), ("d1 at 0.20", d1), ("phi(d1)", phi(d1)),
        ("forward F = S e^(r-q)T", s * ((r - q) * t).exp()), ("discount e^-rT", (-r * t).exp()),
        ("free money, call quoted at 2.80", floor_c - 2.80), ("free money, call quoted at 99", 99.0 - ceil_c),
    ];
    for (name, v) in &rows { println!("{:<36} {:>12.6}", name, v); }

    println!("\nquote -> implied vol (call, house inputs)");
    let ladder = [2.80, 2.90, 3.00, 5.00, 9.23, 15.00, 25.00, 50.00, 90.00, 98.00, 99.00_f64];
    let mut ivs = Vec::new();
    for &qt in &ladder {
        let iv = implied(qt, floor_c, ceil_c, &c);
        match iv {
            None => println!("  quote {:6.2}  no implied vol", qt),
            Some(x) => println!("  quote {:6.2}  sigma {:.6}  repriced {:.6}", qt, x, c(x)),
        }
        ivs.push(iv);
    }

    println!("\nchart: call price as sigma climbs (sigma in %)");
    let grid: Vec<i32> = (0..13).map(|i| 25 * i).collect();
    let prices: Vec<f64> = grid.iter().map(|&g| if g == 0 { floor_c } else { c(g as f64 / 100.0) }).collect();
    println!("  sigma % {}", grid.iter().map(|g| format!("{:6}", g)).collect::<Vec<_>>().join(" "));
    println!("  price   {}", prices.iter().map(|p| format!("{:6.2}", p)).collect::<Vec<_>>().join(" "));
    println!("  flat lines: floor {:.2}, ceiling {:.2}, quote {:.2}", floor_c, ceil_c, qc);
    let zoom: Vec<i32> = (0..9).map(|i| 5 * i).collect();
    println!("  sigma % {}", zoom.iter().map(|g| format!("{:6}", g)).collect::<Vec<_>>().join(" "));
    println!("  price   {}", zoom.iter().map(|&g| format!("{:6.2}", if g == 0 { floor_c } else { c(g as f64 / 100.0) }))
        .collect::<Vec<_>>().join(" "));

    println!("\nwhat breaks (house call quote 9.227006 unless stated)");
    let wrong: Vec<(&str, f64)> = vec![
        ("forgot the 2% dividend", implied(qc, (s - b).max(0.0), s, &|v: f64| call(s, k, r, 0.0, v, t)).unwrap()),
        ("rate ln(1.05) = 4.879% for the 5%", implied(qc, floor_c, ceil_c, &|v: f64| call(s, k, 1.05_f64.ln(), q, v, t)).unwrap()),
        ("put quote 6.33 fed to the call", implied(qp, floor_c, ceil_c, &c).unwrap()),
        ("2.80, floor taken as S - K = 0", bisect(&c, 2.80, 1e-6, 10.0, 60)),
        ("99, ceiling taken as S = 100", bisect(&c, 99.0, 1e-6, 10.0, 60)),
    ];
    for (name, v) in &wrong { println!("  {:<42} {:>10.6}", name, v); }

    let fl = (s * (-q / 4.0).exp() - k * (-r / 4.0).exp()).max(0.0);
    println!("\ntry: T = 0.25, quote 4.00 -> {:.6}", implied(4.0, fl, s * (-q / 4.0).exp(), &|v: f64| call(s, k, r, q, v, 0.25)).unwrap());
    println!("try: K = 120, quote 2.711776 -> {:.6}", implied(2.711776, 0.0, a, &|v: f64| call(s, 120.0, r, q, v, t)).unwrap());

    assert!((iv1 - 0.20).abs() < 1e-9, "the quote was made at 20%; bisection must recover it");
    assert!((iv2 - iv1).abs() < 1e-7, "a price built by brute-force averaging must give the same volatility");
    assert!((iv3 - iv1).abs() < 1e-9, "the put quote, inverted on its own formula, must agree (parity)");
    assert!((vega_fd - vega_an).abs() < 1e-6, "bumped slope vs A phi(d1) sqrt(T)");
    assert!((c(0.01) - (a - b)).abs() < 1e-3, "near sigma = 0 the price sits on the floor");
    assert!((c(20.0) - a).abs() < 1e-9, "at huge sigma the price sits under the ceiling");
    assert!(ivs[0].is_none() && ivs[10].is_none(), "quotes outside the range have no volatility");
    assert!(ladder.iter().zip(&ivs).all(|(&qt, iv)| iv.map_or(true, |x| (c(x) - qt).abs() < 1e-9)), "every ladder volatility must reprice to its quote");
    assert!(c(1e-6) > 2.80 && c(10.0) < 99.0 && wrong[3].1 < 1e-5 && wrong[4].1 > 9.99, "no root: the solver stops at a search edge");
    assert!(prices.windows(2).all(|w| w[0] < w[1]), "price must climb with volatility");
    println!("ALL CHECKS PASS");
}
