// Carr-Madan spanning and the log contract -- the same check as the Python, in Rust.
// No crates.  The normal CDF is a series written out below, the integrals are
// Simpson's rule written out, nothing used knows an answer.
use std::f64::consts::PI;

const S0: f64 = 100.0; const R: f64 = 0.05; const Q: f64 = 0.02; const SIG: f64 = 0.20; const T: f64 = 1.0;
fn fwd() -> f64 { S0 * ((R - Q) * T).exp() }       // forward price
fn disc() -> f64 { (-R * T).exp() }                // discount factor

fn n_cdf(x: f64) -> f64 {                          // bell-curve area left of x
    if x > 8.5 { return 1.0; }
    if x < -8.5 { return 0.0; }
    let y = x.abs() / 2f64.sqrt(); let (mut term, mut total, mut n) = (y, y, 0.0);
    while term > 1e-17 * total {                   // erf(y) = 2/sqrt(pi) e^(-y^2) sum 2^n y^(2n+1)/(2n+1)!!
        n += 1.0; term *= 2.0 * y * y / (2.0 * n + 1.0); total += term;
    }
    let e = 2.0 / PI.sqrt() * (-y * y).exp() * total;
    if x >= 0.0 { 0.5 * (1.0 + e) } else { 0.5 * (1.0 - e) }
}
fn call(k: f64) -> f64 {
    let v = SIG * T.sqrt(); let d1 = ((S0 / k).ln() + (R - Q + 0.5 * SIG * SIG) * T) / v;
    S0 * (-Q * T).exp() * n_cdf(d1) - k * disc() * n_cdf(d1 - v)
}
fn put(k: f64) -> f64 { call(k) - S0 * (-Q * T).exp() + k * disc() }   // put-call parity
fn otm(k: f64) -> f64 { if k < fwd() { put(k) } else { call(k) } }     // put below F, call above

fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64; let mut s = f(a) + f(b);
    for i in 1..n { s += (if i % 2 == 1 { 4.0 } else { 2.0 }) * f(a + i as f64 * h); }
    s * h / 3.0
}

// the two payoffs: g, its slope g1, its curvature g2
#[derive(Clone, Copy)] enum P { Log, Sqr }
fn g(p: P, x: f64) -> f64 { match p { P::Log => 100.0 * (x / 100.0).ln(), P::Sqr => (x - 100.0).powi(2) } }
fn g1(p: P, x: f64) -> f64 { match p { P::Log => 100.0 / x, P::Sqr => 2.0 * (x - 100.0) } }
fn g2(p: P, x: f64) -> f64 { match p { P::Log => -100.0 / (x * x), P::Sqr => 2.0 } }

fn road1(p: P) -> f64 {                            // closed form from the lognormal's moments
    let (f, d) = (fwd(), disc());
    match p { P::Log => 100.0 * d * (R - Q - 0.5 * SIG * SIG) * T,
              P::Sqr => d * (f * f * (SIG * SIG * T).exp() - 200.0 * f + 10000.0) }
}
fn road2(p: P, s: f64, sg: f64) -> f64 {           // average the payoff over the bell curve, no options
    let m = (R - Q - 0.5 * sg * sg) * T;
    disc() * simpson(&|z: f64| g(p, s * (m + sg * T.sqrt() * z).exp()) * (-0.5 * z * z).exp() / (2.0 * PI).sqrt(), -10.0, 10.0, 4000)
}
fn road3(p: P) -> f64 {                            // bond + forward + continuum strip, in log-strike
    let w = 12.0 * SIG * T.sqrt(); let lf = fwd().ln();
    let f = |x: f64| g2(p, x.exp()) * otm(x.exp()) * x.exp();
    disc() * g(p, fwd()) + simpson(&f, lf - w, lf, 3000) + simpson(&f, lf, lf + w, 3000)
}
fn strip(p: P, lo: f64, hi: f64, dk: f64) -> f64 { // the discrete book: bond + one OTM option per strike
    let n = ((hi - lo) / dk).round() as usize; let mut tot = disc() * g(p, fwd());
    for i in 0..=n { let k = lo + i as f64 * dk; tot += g2(p, k) * dk * otm(k); }
    tot
}
fn rebuilt(p: P, st: f64) -> f64 {                 // payoff of bond + forward + continuum at one S_T
    let f = fwd(); let (a, b) = (f.min(st), f.max(st));
    let inner = |k: f64| if st > f { g2(p, k) * (b - k) } else { g2(p, k) * (k - a) };
    g(p, f) + g1(p, f) * (st - f) + simpson(&inner, a, b, 2000)
}
fn join(v: &[f64], d: usize) -> String { v.iter().map(|x| format!("{:.*}", d, x)).collect::<Vec<_>>().join(", ") }

fn main() {
    let (f, d) = (fwd(), disc());
    println!("house: S 100, r 0.05, q 0.02, sigma 0.20, T 1; forward F = {:.6}, discount D = {:.6}", f, d);
    println!("listed: 90-put {:.6}, 120-call {:.6}; call at F {:.6} = put at F {:.6}", put(90.0), call(120.0), call(f), put(f));
    println!("log strip holdings (short): 90-put {:.6}, 120-call {:.6}; square strip (long): {:.0} each", 100.0 * 30.0 / 8100.0, 100.0 * 30.0 / 14400.0, 60.0);
    let (r1, r2, r3) = (road1(P::Log), road2(P::Log, S0, SIG), road3(P::Log));
    println!("log contract, road 1 closed form      {:.6}", r1);
    println!("log contract, road 2 bell-curve mean  {:.6}", r2);
    println!("log contract, road 3 continuum strip  {:.6} = bond {:.6} - options {:.6}", r3, d * g(P::Log, f), d * g(P::Log, f) - r3);
    println!("variance the strip prices: 2 x options / (100 D T) = {:.6}", 2.0 * (d * g(P::Log, f) - r3) / (100.0 * d * T));
    let (hp, hc) = (100.0 * 30.0 / 8100.0 * put(90.0), 100.0 * 30.0 / 14400.0 * call(120.0));
    println!("two-strike log book: options {:.6} + {:.6} = {:.6}; price {:.6}", hp, hc, hp + hc, d * g(P::Log, f) - hp - hc);
    println!("two-strike square book: 60 x (put + call) = {:.6}; price {:.6}", 60.0 * (put(90.0) + call(120.0)), d * g(P::Sqr, f) + 60.0 * (put(90.0) + call(120.0)));
    let (s1, s2, s3) = (road1(P::Sqr), road2(P::Sqr, S0, SIG), road3(P::Sqr));
    println!("square contract, roads 1, 2, 3        {:.6}, {:.6}, {:.6}; bond {:.6}", s1, s2, s3, d * g(P::Sqr, f));
    println!("strip                  strikes   log price        gap   square price       gap");
    let books = [("90 & 120 only", 90.0, 120.0, 30.0), ("80 to 120 by 10", 80.0, 120.0, 10.0), ("50 to 200 by 5", 50.0, 200.0, 5.0),
                 ("20 to 400 by 1", 20.0, 400.0, 1.0), ("10 to 600 by 0.25", 10.0, 600.0, 0.25)];
    for (lab, lo, hi, dk) in books {
        let (a, b) = (strip(P::Log, lo, hi, dk), strip(P::Sqr, lo, hi, dk));
        println!("{:<22} {:>7} {:>11.6} {:>+10.6} {:>14.4} {:>+9.4}", lab, ((hi - lo) / dk).round() as usize + 1, a, a - r1, b, b - s1);
    }
    let fine = strip(P::Log, 10.0, 600.0, 0.25);
    println!("pathwise, log payoff: S_T, exact, tangent (bond+forward), options pay, rebuilt");
    let mut worst: f64 = 0.0;
    for st in [70.0, 90.0, 110.0, 140.0] {
        let (ex, tan, rb) = (g(P::Log, st), g(P::Log, f) + g1(P::Log, f) * (st - f), rebuilt(P::Log, st));
        worst = worst.max((rb - ex).abs()).max((rebuilt(P::Sqr, st) - g(P::Sqr, st)).abs());
        println!("  S_T {:6.2}: exact {:9.6}, tangent {:9.6}, options {:9.6}, rebuilt {:9.6}", st, ex, tan, rb - tan, rb);
    }
    println!("  two-listed book at S_T 110: {:.6} (both options expire worthless)", g(P::Log, f) + g1(P::Log, f) * (110.0 - f));
    println!("pathwise, both payoffs rebuilt to within 1e-9 at every S_T: {}", if worst < 1e-9 { "yes" } else { "no" });
    println!("chart: S_T, log payoff, tangent, two-strike book");
    let xs: Vec<f64> = (6..=15).map(|i| i as f64 * 10.0).collect();
    let book = |x: f64| g(P::Log, f) + g1(P::Log, f) * (x - f) - 100.0 * 30.0 / 8100.0 * (90.0 - x).max(0.0) - 100.0 * 30.0 / 14400.0 * (x - 120.0).max(0.0);
    println!("  x {}", join(&xs, 0));
    println!("  log {}", join(&xs.iter().map(|&x| g(P::Log, x)).collect::<Vec<_>>(), 2));
    println!("  tangent {}", join(&xs.iter().map(|&x| g(P::Log, f) + g1(P::Log, f) * (x - f)).collect::<Vec<_>>(), 2));
    println!("  book {}", join(&xs.iter().map(|&x| book(x)).collect::<Vec<_>>(), 2));
    let h = 0.01;
    let dgam = |s: f64| s * s * (road2(P::Log, s + h, SIG) - 2.0 * road2(P::Log, s, SIG) + road2(P::Log, s - h, SIG)) / (h * h);
    let cg = |s: f64| s * s * (-Q * T).exp() * (-0.5 * (((s / 100.0).ln() + (R - Q + 0.5 * SIG * SIG) * T) / SIG).powi(2)).exp() / (2.0 * PI).sqrt() / (s * SIG);
    println!("log delta at S 100: closed {:.6}, bumped {:.6}", d, (road2(P::Log, 100.0 + h, SIG) - road2(P::Log, 100.0 - h, SIG)) / (2.0 * h));
    println!("log vega per vol point: closed {:.6}, bumped {:.6}", -100.0 * d * SIG * T / 100.0, (road2(P::Log, 100.0, SIG + 1e-4) - road2(P::Log, 100.0, SIG - 1e-4)) / 2e-4 / 100.0);
    let gs: Vec<f64> = [80.0, 100.0, 125.0].iter().map(|&s| dgam(s)).collect();
    println!("log dollar gamma S^2 x gamma: closed {:.4}; bumped at S 80, 100, 125: {}", -100.0 * d, join(&gs, 4));
    let ss: Vec<f64> = (6..=16).map(|i| i as f64 * 10.0).collect();
    println!("  chart S {}", join(&ss, 0));
    println!("  log |S^2 gamma| {}", join(&ss.iter().map(|_| 100.0 * d).collect::<Vec<_>>(), 2));
    println!("  100-call S^2 gamma {}", join(&ss.iter().map(|&s| cg(s)).collect::<Vec<_>>(), 2));
    let (bond, opts) = (d * g(P::Log, f), d * g(P::Log, f) - fine);
    let flat: f64 = (0..2361).map(|i| 100.0 * 0.25 / (f * f) * otm(10.0 + i as f64 * 0.25)).sum();
    let itm: f64 = (0..2361).map(|i| { let k = 10.0 + i as f64 * 0.25; 100.0 * 0.25 / (k * k) * call(k) }).sum();
    let wrong = [("strip held long", bond + opts), ("one weight 1/F^2 for all", bond - flat),
                 ("calls below F, not puts", bond - itm), ("bond piece dropped", -opts)];
    for (lab, v) in wrong { println!("mistake, {:<24} {:10.6} (right {:.6})", lab, v, r1); }
    assert!((r1 - r2).abs() < 1e-8 && (s1 - s2).abs() < 1e-6, "closed form vs bell-curve average");
    assert!((r3 - r1).abs() < 1e-6 && (s3 - s1).abs() < 1e-4, "continuum strip vs closed form");
    assert!((fine - r1).abs() < 1e-4 && (strip(P::Log, 90.0, 120.0, 30.0) - r1).abs() > 0.3, "fine strip closes the gap, two strikes do not");
    assert!(worst < 1e-9, "spanning identity holds pathwise");
    assert!(gs.iter().all(|g| (g + 100.0 * d).abs() < 1e-3), "dollar gamma is flat at -100 D");
    println!("ALL CHECKS PASS");
}
