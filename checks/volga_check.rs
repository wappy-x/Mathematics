// Volga -- the same check as volga_check.py, in Rust.  Standard library only.
// Rust has no erf, so N(x) is built by adding thin slices under the bell
// curve (Simpson).  The root finder is bisection, written out.
// Compile: rustc --edition 2021 -O volga_check.rs -o /tmp/volga_check
use std::collections::HashMap;
use std::f64::consts::PI;

const S: f64 = 100.0;
const R: f64 = 0.05;
const Q: f64 = 0.02;
const T: f64 = 1.0;
const SIG: f64 = 0.20;

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }   // bell-curve height at x

fn simpson<G: Fn(f64) -> f64>(f: G, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    s * h / 3.0
}

fn n_cdf(x: f64) -> f64 {                                              // area left of x
    if x < -12.0 { return 0.0; }
    if x > 12.0 { return 1.0; }
    0.5 + simpson(phi, 0.0, x, 4000)
}

fn d1d2(k: f64, s: f64) -> (f64, f64) {
    let d1 = ((S / k).ln() + (R - Q + 0.5 * s * s) * T) / (s * T.sqrt());
    (d1, d1 - s * T.sqrt())
}

fn call(k: f64, s: f64) -> f64 {
    let (d1, d2) = d1d2(k, s);
    S * (-Q * T).exp() * n_cdf(d1) - k * (-R * T).exp() * n_cdf(d2)
}

fn vega(k: f64, s: f64) -> f64 { S * (-Q * T).exp() * phi(d1d2(k, s).0) * T.sqrt() }

fn volga(k: f64, s: f64) -> f64 {                                      // road 1: closed form
    let (d1, d2) = d1d2(k, s);
    vega(k, s) * d1 * d2 / s
}

fn volga_bump(k: f64, s: f64) -> f64 {                                 // road 2: nudge sigma, watch vega
    let h = 1e-5;
    (vega(k, s + h) - vega(k, s - h)) / (2.0 * h)
}

fn bisect<G: Fn(f64) -> f64>(f: G, mut lo: f64, mut hi: f64) -> f64 {
    let mut flo = f(lo);
    for _ in 0..200 {
        let mid = 0.5 * (lo + hi);
        let fm = f(mid);
        if (fm > 0.0) == (flo > 0.0) { lo = mid; flo = fm; } else { hi = mid; }
    }
    0.5 * (lo + hi)
}

fn price_by_integral(k: f64, s: f64, put: bool) -> f64 {              // no d1, no d2, no N
    let (a, b) = ((R - Q - 0.5 * s * s) * T, s * T.sqrt());
    let st = |z: f64| S * (a + b * z).exp();
    let zk = bisect(|z| st(z) - k, -10.0, 10.0);                     // where the payoff switches on
    let v = if put { simpson(|z| (k - st(z)) * phi(z), -10.0, zk, 4000) }
            else { simpson(|z| (st(z) - k) * phi(z), zk, 10.0, 4000) };
    (-R * T).exp() * v
}

fn volga_second_diff(k: f64, s: f64, put: bool) -> f64 {              // road 3: curvature of the price
    let h = 1e-3;
    let p = |j: f64| price_by_integral(k, s + j * h, put);
    let (pm2, pm1, p0, pp1, pp2) = (p(-2.0), p(-1.0), p(0.0), p(1.0), p(2.0));
    let d_h = (pp1 - 2.0 * p0 + pm1) / (h * h);
    let d_2h = (pp2 - 2.0 * p0 + pm2) / (4.0 * h * h);
    (4.0 * d_h - d_2h) / 3.0                                           // Richardson: cancel the h^2 error
}

fn main() {
    let f = S * ((R - Q) * T).exp();
    let k = 100.0;
    let (d1, d2) = d1d2(k, SIG);
    let (v1, v2, v3) = (volga(k, SIG), volga_bump(k, SIG), volga_second_diff(k, SIG, false));
    let v3put = volga_second_diff(k, SIG, true);
    let (m, half_var) = ((f / k).ln(), 0.5 * SIG * SIG * T);
    let z_lo = bisect(|x| volga_bump(x, SIG), 90.0, f);
    let z_hi = bisect(|x| volga_bump(x, SIG), f, 120.0);
    let rows: Vec<(&str, f64)> = vec![
        ("d1", d1), ("d2", d2), ("d1 d2", d1 * d2), ("e^(-qT)", (-Q * T).exp()), ("phi(d1)", phi(d1)),
        ("vega", vega(k, SIG)), ("vega / sigma", vega(k, SIG) / SIG),
        ("1 volga, vega d1 d2 / sigma", v1), ("2 volga, bump of vega", v2),
        ("3 volga, 2nd difference of price", v3), ("  put, 2nd difference of price", v3put),
        ("volga per vol point squared", v1 / 1e4),
        ("vega at 21%, formula", vega(k, 0.21)), ("vega at 21%, vega + 0.01 volga", vega(k, SIG) + 0.01 * v1),
        ("ln(F/K)", m), ("half the variance, sigma^2 T / 2", half_var),
        ("forward F", f), ("vega at K = F", vega(f, SIG)), ("volga at K = F", volga(f, SIG)), ("  -vega sigma T / 4 at K = F", -vega(f, SIG) * SIG * T / 4.0),
        ("zero strike low, bisection", z_lo), ("  F e^(-sigma^2 T / 2)", f * (-half_var).exp()),
        ("zero strike high, bisection", z_hi), ("  F e^(+sigma^2 T / 2)", f * half_var.exp()),
        ("wrong: sign slip in dd1/dsigma", -vega(k, SIG) * d1 * d2 / SIG),
        ("wrong: d1^2 for d1 d2", vega(k, SIG) * d1 * d1 / SIG),
        ("wrong: vega at 21% as vega + volga", vega(k, SIG) + v1),
        ("try: sigma = 40%", volga(k, 0.40)), ("try: K = 130", volga(130.0, SIG)),
        ("try: K = 80", volga(80.0, SIG)),
    ];
    for (name, v) in &rows { println!("{:<36} {:>12.6}", name, v); }

    // ---- volatility itself moves: 15% or 25%, even odds, instead of a sure 20% ----
    println!();
    println!("strike   price@20%  avg(15%,25%)  gain(c)  half volga dsig^2 (c)");
    let mut mix: HashMap<u64, (f64, f64)> = HashMap::new();
    for kk in [80.0, 90.0, 100.0, f, 110.0, 120.0, 130.0, 140.0] {
        let avg = 0.5 * (call(kk, 0.15) + call(kk, 0.25));
        let g = (avg - call(kk, SIG), 0.5 * volga(kk, SIG) * 0.05f64.powi(2));
        mix.insert(kk.to_bits(), g);
        println!("{:7.2} {:10.4} {:12.4} {:9.2} {:12.2}", kk, call(kk, SIG), avg, 100.0 * g.0, 100.0 * g.1);
    }
    let wide = 0.5 * (call(130.0, 0.10) + call(130.0, 0.30)) - call(130.0, SIG);
    println!("try: K = 130, 10% or 30%: gain(c) {:.2}  half volga dsig^2 (c) {:.2}", 100.0 * wide, 100.0 * 0.5 * volga(130.0, SIG) * 0.01);

    // ---- chart: volga across strikes ----
    let ks: Vec<f64> = (0..15).map(|i| 70.0 + 5.0 * i as f64).collect();
    println!("chart, strike {}", ks.iter().map(|x| format!("{:.0}", x)).collect::<Vec<_>>().join(" "));
    println!("chart, volga  {}", ks.iter().map(|x| format!("{:.2}", volga(*x, SIG))).collect::<Vec<_>>().join(" "));

    let (w, a) = (mix[&130.0f64.to_bits()], mix[&f.to_bits()]);
    assert!((v1 - 2.368822).abs() < 5e-7, "closed form vs the shelf's house number");
    assert!((v2 - v1).abs() < 1e-6, "bump of vega must land on vega d1 d2 / sigma");
    assert!((v3 - v1).abs() < 1e-6, "call price curvature, from the integral");
    assert!((v3put - v1).abs() < 1e-6, "put price curvature equals the call's");
    assert!((z_lo - f * (-half_var).exp()).abs() < 1e-6, "low zero where d2 = 0");
    assert!((z_hi - f * half_var.exp()).abs() < 1e-6, "high zero where d1 = 0");
    assert!((w.0 - w.1).abs() < 0.005, "wing gain matches half volga times dsigma^2");
    assert!(w.0 > 0.0 && 0.0 > a.0, "wing gains from vol of vol, forward strike loses");
    println!("ALL CHECKS PASS");
}
