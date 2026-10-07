// Implied volatility by Newton and bisection -- the same check as the Python, in Rust.
// Standard library only, no crates.  The normal CDF is the same series written out;
// the root finders are plain loops.  Compile: rustc --edition 2021 -O <this file>
use std::f64::consts::PI;

const S: f64 = 100.0; const R: f64 = 0.05; const Q: f64 = 0.02;   // Acme spot, cash rate, dividend yield
const WEEK: f64 = 1.0 / 52.0;

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }

fn n_cdf(x: f64) -> f64 {                          // 0.5 + phi(x) (x + x^3/3 + x^5/15 + ...)
    if x < -10.0 { return 0.0; }
    if x > 10.0 { return 1.0; }
    let (mut term, mut total, mut k) = (x, x, 1.0);
    while term.abs() > 1e-17 * total.abs() {
        term *= x * x / (2.0 * k + 1.0); total += term; k += 1.0;
    }
    0.5 + total * phi(x)
}

fn d1(k: f64, t: f64, s: f64) -> f64 { ((S / k).ln() + (R - Q + 0.5 * s * s) * t) / (s * t.sqrt()) }
fn call(k: f64, t: f64, s: f64) -> f64 {
    let a = d1(k, t, s); S * (-Q * t).exp() * n_cdf(a) - k * (-R * t).exp() * n_cdf(a - s * t.sqrt()) }
fn put(k: f64, t: f64, s: f64) -> f64 {
    let a = d1(k, t, s); k * (-R * t).exp() * n_cdf(s * t.sqrt() - a) - S * (-Q * t).exp() * n_cdf(-a) }
fn vega(k: f64, t: f64, s: f64) -> f64 { S * (-Q * t).exp() * phi(d1(k, t, s)) * t.sqrt() }
fn s_peak(k: f64, t: f64) -> f64 { (2.0 * ((S * ((R - Q) * t).exp()) / k).ln().abs() / t).sqrt() }

type Pricer = fn(f64, f64, f64) -> f64;

// road 1: the slope, unguarded.  The trace keeps (trip, sigma, residual, vega).
fn newton(price: Pricer, k: f64, t: f64, p: f64, mut x: f64, trace: &mut Vec<(usize, f64, f64, f64)>) -> (f64, usize) {
    for trip in 1..100 {
        let (f, v) = (price(k, t, x) - p, vega(k, t, x));
        trace.push((trip, x, f, v));
        if f.abs() < 1e-12 { return (x, trip); }
        if v == 0.0 { return (f64::INFINITY, trip); }
        x -= f / v;
        if !(x > 0.0 && x < 1e3) { return (x, trip); }   // left the world of volatilities
    }
    (x, 100)
}

// road 2: no slope, only signs
fn bisect(price: Pricer, k: f64, t: f64, p: f64) -> (f64, usize) {
    let (mut lo, mut hi, mut halvings) = (0.01, 5.0, 0usize);
    while hi - lo > 1e-12 {
        let m = 0.5 * (lo + hi);
        halvings += 1;
        if price(k, t, m) > p { hi = m; } else { lo = m; }
    }
    (0.5 * (lo + hi), halvings)
}

// Newton inside a bracket, bisection as the net
fn guarded(price: Pricer, k: f64, t: f64, p: f64, mut x: f64) -> (f64, usize, usize) {
    let (mut lo, mut hi, mut falls, mut trips) = (0.01, 5.0, 0usize, 0usize);
    for trip in 1..200 {
        trips = trip;
        let f = price(k, t, x) - p;
        if f.abs() < 1e-12 || hi - lo < 1e-14 { break; }
        if f > 0.0 { hi = x; } else { lo = x; }
        let v = vega(k, t, x);
        let mut nxt = if v > 0.0 { x - f / v } else { lo };
        if !(lo < nxt && nxt < hi) { nxt = 0.5 * (lo + hi); falls += 1; }
        x = nxt;
    }
    (x, trips, falls)
}

fn strike_for_delta(t: f64, target: f64) -> f64 {  // the strike whose call delta is target, at 0.20
    let (mut lo, mut hi) = (50.0, 200.0);
    while hi - lo > 1e-12 {
        let m = 0.5 * (lo + hi);
        if (-Q * t).exp() * n_cdf(d1(m, t, 0.20)) > target { lo = m; } else { hi = m; }
    }
    0.5 * (lo + hi)
}

fn row(label: &str, v: f64) { println!("{:<46}{:>22.12}", label, v); }
fn row_int(label: &str, v: usize) { println!("{:<46}{:>22}", label, v); }

fn main() {
    let mut none = Vec::new();
    // ---- the house quote, read backwards ----
    let (c, p) = (call(100.0, 1.0, 0.20), put(100.0, 1.0, 0.20));
    row("house call at 0.20", c);
    row("house put at 0.20", p);
    row("call floor, S e^-qT - K e^-rT", S * (-Q).exp() - 100.0 * (-R).exp());
    row("call ceiling, S e^-qT", S * (-Q).exp());
    let (v0, h) = (vega(100.0, 1.0, 0.20), 1e-5);
    let v_bump = (call(100.0, 1.0, 0.20 + h) - call(100.0, 1.0, 0.20 - h)) / (2.0 * h);
    row("vega at 0.20, per 1.00 of vol", v0);
    row("vega by bumping the price", v_bump);
    row("sigma_c, where vega peaks", s_peak(100.0, 1.0));
    let mut trace = Vec::new();
    let (x_n, _) = newton(call, 100.0, 1.0, c, 0.50, &mut trace);
    for (trip, x, f, v) in &trace {
        println!("newton from 0.50, trip {}: sigma {:.12}  residual {:+.12}  vega {:.6}", trip, x, f, v);
    }
    row_int("newton from sigma_c, trips", newton(call, 100.0, 1.0, c, s_peak(100.0, 1.0), &mut none).1);
    let (x_b, halv_b) = bisect(call, 100.0, 1.0, c);
    row("bisection on 0.01 to 5.00, answer", x_b);
    row_int("bisection on 0.01 to 5.00, halvings", halv_b);
    let x_p = newton(put, 100.0, 1.0, p, 0.50, &mut none).0;
    row("put 6.330080627550 by Newton from 0.50", x_p);

    // ---- the same solver on one-week options ----
    let cases = [("1y atm", 100.0, 1.0), ("1w atm", 100.0, WEEK),
                 ("1w 20d", strike_for_delta(WEEK, 0.20), WEEK), ("1w 5d", strike_for_delta(WEEK, 0.05), WEEK)];
    println!("case    strike      sigma_c   newton from 0.05 ends at  trips  from sigma_c  guarded, falls  bisection");
    let mut results = Vec::new();
    for (name, k, t) in cases {
        let pr = call(k, t, 0.20);
        let (x_lo, t_lo) = newton(call, k, t, pr, 0.05, &mut none);
        let (x_c, t_c) = newton(call, k, t, pr, s_peak(k, t), &mut none);
        let (x_g, t_g, f_g) = guarded(call, k, t, pr, 0.05);
        let x_bi = bisect(call, k, t, pr).0;
        results.push((x_lo, x_c, x_g, x_bi));
        println!("{:<7}{:>11.6}{:>9.4}{:>27.6}{:>7}{:>14}{:>9}{:>7}{:>11.6}", name, k, s_peak(k, t), x_lo, t_lo, t_c, t_g, f_g, x_bi);
    }
    for (name, k, t) in &cases[2..] {                // where the low start goes
        let mut tr = Vec::new();
        newton(call, *k, *t, call(*k, *t, 0.20), 0.05, &mut tr);
        for (trip, x, f, v) in &tr {
            println!("{} from 0.05, trip {}: sigma {:.6}  residual {:+.6}  vega {:.12}", name, trip, x, f, v);
        }
    }

    // ---- a 0.05 bid-ask width, read as a volatility width ----
    println!("case    mid price   vega per vol point   width / vega, points   ask vol - bid vol, points");
    let mut widths = Vec::new();
    for (name, k, t) in cases {
        let pr = call(k, t, 0.20);
        let lin = 0.05 / vega(k, t, 0.20) * 100.0;
        let exact = (bisect(call, k, t, pr + 0.025).0 - bisect(call, k, t, pr - 0.025).0) * 100.0;
        widths.push((lin, exact));
        println!("{:<7}{:>10.6}{:>21.6}{:>23.4}{:>28.4}", name, pr, vega(k, t, 0.20) / 100.0, lin, exact);
    }

    // ---- what breaks, and the chart ----
    row("bisection on a 2.80 quote, below the floor", bisect(call, 100.0, 1.0, 2.80).0);
    row("0.05 / vega per 1.00, misread as points", 0.05 / v0);
    let strikes: Vec<f64> = (0..9).map(|i| 90.0 + 2.5 * i as f64).collect();
    let head: Vec<String> = strikes.iter().map(|k| format!("{:6.1}", k)).collect();
    println!("chart, strike              {}", head.join(" "));
    for (label, t) in [("chart, cents per point, 1y ", 1.0), ("chart, cents per point, 1w ", WEEK)] {
        let vals: Vec<String> = strikes.iter().map(|k| format!("{:6.2}", vega(*k, t, 0.20))).collect();
        println!("{} {}", label, vals.join(" "));
    }

    let k5 = cases[3].1;
    let mut slide = Vec::new();
    newton(call, k5, WEEK, call(k5, WEEK, 0.20), s_peak(k5, WEEK), &mut slide);
    assert!((c - 9.227005508154).abs() < 1e-9, "the pilot's call");
    assert!((p - 6.330080627550).abs() < 1e-9, "the pilot's put");
    assert!((v_bump - v0).abs() < 1e-6, "slope two ways");
    assert!((x_n - 0.20).abs() < 1e-12, "Newton recovers 0.20");
    assert!((x_b - 0.20).abs() < 1e-11, "bisection recovers 0.20");
    assert!((x_p - 0.20).abs() < 1e-12, "the put gives the same vol");
    assert!(results.iter().all(|r| [r.1, r.2, r.3].iter().all(|x| (x - 0.20).abs() < 1e-10)), "every safe road lands");
    assert!([2, 3].iter().all(|&i| !(results[i].0 > 0.0 && results[i].0 < 1e3)), "low start dies on 20d and 5d");
    assert!(cases.iter().all(|&(_, k, t)| vega(k, t, s_peak(k, t)) > vega(k, t, s_peak(k, t) * 0.99)
        && vega(k, t, s_peak(k, t)) > vega(k, t, s_peak(k, t) * 1.01)), "sigma_c is where vega peaks");
    assert!(slide.windows(2).all(|w| w[0].1 >= w[1].1 - 1e-15), "from sigma_c: never overshoots");
    assert!((widths[0].0 - widths[0].1).abs() < 0.001, "linear width holds at the money");
    assert!(widths[3].1 > 3.0, "several points on the 5d");
    println!("ALL CHECKS PASS");
}
