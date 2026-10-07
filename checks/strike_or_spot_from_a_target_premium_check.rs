// Strike or spot from a target premium -- the same check as the Python, in Rust.
// No crates.  The bell-curve area is a series written out here, the second
// price is Simpson's rule over the payoff, and both root finders (Newton,
// bisection) are loops written here.
use std::f64::consts::PI;

const S: f64 = 100.0;
const K0: f64 = 100.0;
const R: f64 = 0.05;
const Q: f64 = 0.02;
const SIGMA: f64 = 0.20;
const T: f64 = 1.0;
const QUOTE: f64 = 9.227005508154; // the house call, S = K = 100

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }
fn n(x: f64) -> f64 { // 0.5 + phi(x) * (x + x^3/3 + x^5/15 + ...)
    if x < -8.0 { return 0.0 }
    if x > 8.0 { return 1.0 }
    let (mut term, mut total, mut k) = (x, x, 0.0);
    while term.abs() > 1e-17 * total.abs() + 1e-300 {
        k += 1.0;
        term *= x * x / (2.0 * k + 1.0);
        total += term;
    }
    0.5 + phi(x) * total
}

fn d12(s: f64, k: f64, sg: f64, t: f64, qq: f64) -> (f64, f64) {
    let d1 = ((s / k).ln() + (R - qq + 0.5 * sg * sg) * t) / (sg * t.sqrt());
    (d1, d1 - sg * t.sqrt())
}
fn call_full(s: f64, k: f64, sg: f64, t: f64, qq: f64) -> f64 { // road 1: the closed form
    let (d1, d2) = d12(s, k, sg, t, qq);
    s * (-qq * t).exp() * n(d1) - k * (-R * t).exp() * n(d2)
}
fn call(s: f64, k: f64) -> f64 { call_full(s, k, SIGMA, T, Q) }
fn put(s: f64, k: f64) -> f64 {
    let (d1, d2) = d12(s, k, SIGMA, T, Q);
    k * (-R * T).exp() * n(-d2) - s * (-Q * T).exp() * n(-d1)
}

fn by_integral(s: f64, k: f64, is_call: bool) -> f64 { // road 2: average the payoff over the bell curve
    let (m, v) = ((R - Q - 0.5 * SIGMA * SIGMA) * T, SIGMA * T.sqrt());
    let z0 = ((k / s).ln() - m) / v; // the draw at which the stock ends exactly at k
    let (a, b) = if is_call { (z0, 12.0) } else { (-12.0, z0) };
    let steps = 2000;
    let h = (b - a) / steps as f64;
    let mut tot = 0.0;
    for i in 0..=steps {
        let z = a + i as f64 * h;
        let st = s * (m + v * z).exp();
        let pay = if is_call { st - k } else { k - st };
        let w = if i == 0 || i == steps { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 };
        tot += w * pay.max(0.0) * phi(z);
    }
    (-R * T).exp() * tot * h / 3.0
}

fn bisect(f: &dyn Fn(f64) -> f64, target: f64, mut lo: f64, mut hi: f64, up: bool) -> f64 {
    for _ in 0..80 {
        let mid = 0.5 * (lo + hi);
        if (f(mid) < target) == up { lo = mid } else { hi = mid }
    }
    0.5 * (lo + hi)
}
fn bracket(f: &dyn Fn(f64) -> f64, target: f64, up: bool) -> (f64, f64) {
    let (mut lo, mut hi) = (100.0, 100.0); // double and halve until the target is straddled
    while (f(hi) < target) == up { hi *= 2.0 }
    while (f(lo) < target) != up { lo /= 2.0 }
    (lo, hi)
}
fn newton(f: &dyn Fn(f64) -> f64, slope: &dyn Fn(f64) -> f64, target: f64, mut x: f64) -> Vec<f64> {
    let mut path = vec![x];
    for _ in 0..6 {
        x -= (f(x) - target) / slope(x);
        path.push(x);
    }
    path
}

fn main() {
    let target = 5.0;
    let ceiling = S * (-Q * T).exp(); // a call can never cost more than this
    let slope_k = |k: f64| -(-R * T).exp() * n(d12(S, k, SIGMA, T, Q).1);
    let slope_s = |s: f64| (-Q * T).exp() * n(d12(s, K0, SIGMA, T, Q).0);
    let (lo, hi) = bracket(&|k| call(S, k), target, false);
    let path = newton(&|k| call(S, k), &slope_k, target, 100.0);
    let kc_newton = path[6];
    let kc_integral = bisect(&|k| by_integral(S, k, true), target, lo, hi, false);
    let (lo_p, hi_p) = bracket(&|k| put(S, k), target, true);
    let kp_bisect = bisect(&|k| put(S, k), target, lo_p, hi_p, true);
    let kp_integral = bisect(&|k| by_integral(S, k, false), target, lo_p, hi_p, true);
    let (lo_s, hi_s) = bracket(&|s| call(s, K0), QUOTE, true);
    let s_newton = newton(&|s| call(s, K0), &slope_s, QUOTE, 120.0)[6];
    let s_integral = bisect(&|s| by_integral(s, K0, true), QUOTE, lo_s, hi_s, true);
    let s_for_5 = bisect(&|s| call(s, K0), target, lo_s / 4.0, hi_s, true);
    let h = 1e-4;
    let slope_fd = (call(S, kc_newton + h) - call(S, kc_newton - h)) / (2.0 * h);
    let (d1, d2) = d12(S, kc_newton, SIGMA, T, Q);

    let mut rows: Vec<(String, f64)> = vec![
        ("e^-rT".into(), (-R * T).exp()), ("e^-qT".into(), (-Q * T).exp()), ("ceiling S e^-qT".into(), ceiling),
        ("put spot ceiling K e^-rT".into(), K0 * (-R * T).exp()),
        ("bracket low".into(), lo), ("bracket high".into(), hi), ("newton step 0".into(), path[0]),
        ("  call there".into(), call(S, path[0])), ("  gap to 5.00 there".into(), call(S, path[0]) - target),
        ("  N(d2) there".into(), n(d12(S, path[0], SIGMA, T, Q).1)), ("  slope there".into(), slope_k(path[0])),
        ("newton step 1".into(), path[1]), ("newton step 2".into(), path[2]), ("newton step 3".into(), path[3]),
        ("1 strike, Newton on formula".into(), kc_newton), ("2 strike, bisection on integral".into(), kc_integral),
        ("  ln(S/K) at that strike".into(), (S / kc_newton).ln()), ("  d1 at that strike".into(), d1), ("  d2 at that strike".into(), d2), ("  N(d1)".into(), n(d1)), ("  N(d2)".into(), n(d2)),
        ("  share half".into(), S * (-Q * T).exp() * n(d1)), ("  cash half".into(), kc_newton * (-R * T).exp() * n(d2)),
        ("  call repriced by integral".into(), by_integral(S, kc_newton, true)),
        ("  slope by bump".into(), slope_fd), ("  -e^-rT N(d2)".into(), slope_k(kc_newton)),
        ("put strike, bisection on formula".into(), kp_bisect), ("put strike, bisection on integral".into(), kp_integral),
        ("spot for 9.227, Newton from 120".into(), s_newton), ("spot for 9.227, bisection on integral".into(), s_integral),
        ("spot for 5.00 call, K = 100".into(), s_for_5),
        ("wrong: sigma = 0, K = (S e^-qT - 5) e^rT".into(), (ceiling - target) * (R * T).exp()),
        ("wrong: stop after one Newton step".into(), path[1]),
        ("wrong: forgot the 2% dividend".into(), bisect(&|k| call_full(S, k, SIGMA, T, 0.0), target, lo, 2.0 * hi, false)),
        ("wrong: put solved for the call quote".into(), kp_bisect),
        ("wrong: 99.00 target, solver ends at".into(), bisect(&|k| call(S, k), 99.0, 1e-9, 1000.0, false)),
        ("try: sigma = 0.40".into(), bisect(&|k| call_full(S, k, 0.40, T, Q), target, lo, 2.0 * hi, false)),
        ("try: T = 0.25".into(), bisect(&|k| call_full(S, k, SIGMA, 0.25, Q), target, 1.0, hi, false)),
        ("try: target 1.00".into(), bisect(&|k| call(S, k), 1.0, lo, 4.0 * hi, false)),
        ("try: expiry today, K = S - 5".into(), S - target),
    ];
    for sg in [0.10, 0.30] { // one quote, many (spot, vol) pairs
        let s_pair = bisect(&|s| call_full(s, K0, sg, T, Q), QUOTE, 50.0, 200.0, true);
        rows.push((format!("same 9.227 quote: vol {:.2} needs spot", sg), s_pair));
    }
    for (name, v) in &rows { println!("{:<42} {:>12.6}", name, v) }
    let ks: Vec<f64> = (0..7).map(|i| 80.0 + 10.0 * i as f64).collect();
    let ss: Vec<f64> = (0..5).map(|i| 80.0 + 10.0 * i as f64).collect();
    let line = |v: Vec<f64>, d: usize| v.iter().map(|x| format!("{:7.*}", d, x)).collect::<Vec<_>>().join(" ");
    println!("chart, strike        {}", line(ks.clone(), 0));
    println!("chart, call premium  {}", line(ks.iter().map(|&k| call(S, k)).collect(), 2));
    println!("chart, put premium   {}", line(ks.iter().map(|&k| put(S, k)).collect(), 2));
    println!("chart, spot          {}", line(ss.clone(), 0));
    println!("chart, call at K=100 {}", line(ss.iter().map(|&s| call(s, K0)).collect(), 2));

    assert!((call(S, K0) - QUOTE).abs() < 1e-9, "formula must reproduce the house call");
    assert!((kc_newton - kc_integral).abs() < 1e-6, "two roads to the strike");
    assert!((kp_bisect - kp_integral).abs() < 1e-6, "two roads to the put strike");
    assert!((s_newton - 100.0).abs() < 1e-8 && (s_integral - 100.0).abs() < 1e-6, "9.227 must return S = 100");
    assert!((slope_fd - slope_k(kc_newton)).abs() < 1e-6, "strike slope: bump vs -e^-rT N(d2)");
    assert!(path.windows(2).take(3).all(|w| w[0] < w[1] && w[1] <= kc_newton + 1e-12), "Newton climbs, never overshoots");
    assert!((4..30).all(|i| { let k = 10.0 * i as f64; call(S, k) > call(S, k + 10.0) && put(S, k) < put(S, k + 10.0) }), "call falls, put rises in strike");
    assert!((4..30).all(|i| { let s = 10.0 * i as f64; call(s, K0) < call(s + 10.0, K0) }), "call rises in spot");
    println!("ALL CHECKS PASS");
}
