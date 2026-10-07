// Asset-or-nothing digital -- the same check as asset_or_nothing_digital_check.py, in Rust.
// Standard library only, no crates.  Rust has no erf, so the bell-curve area N(x)
// is built a different way from the Python: thin slices under the curve (Simpson).
use std::f64::consts::PI;

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }

fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    s * h / 3.0
}

fn n_cdf(x: f64) -> f64 {                                          // area left of x
    if x.abs() > 9.0 { return if x < 0.0 { 0.0 } else { 1.0 }; }
    0.5 + simpson(phi, 0.0, x, 4000)
}

fn d1d2(s: f64, k: f64, r: f64, q: f64, sig: f64, t: f64) -> (f64, f64) {
    let vt = sig * t.sqrt();
    let d1 = ((s / k).ln() + (r - q + 0.5 * sig * sig) * t) / vt;
    (d1, d1 - vt)
}

fn aon(s: f64, k: f64, r: f64, q: f64, sig: f64, t: f64, put: bool) -> f64 {   // road 1: the formula
    let (d1, _) = d1d2(s, k, r, q, sig, t);
    s * (-q * t).exp() * n_cdf(if put { -d1 } else { d1 })
}

fn con(s: f64, k: f64, r: f64, q: f64, sig: f64, t: f64, put: bool) -> f64 {   // cash digital, one dollar
    let (_, d2) = d1d2(s, k, r, q, sig, t);
    (-r * t).exp() * n_cdf(if put { -d2 } else { d2 })
}

fn call(s: f64, k: f64, r: f64, q: f64, sig: f64, t: f64) -> f64 {
    let (d1, d2) = d1d2(s, k, r, q, sig, t);
    s * (-q * t).exp() * n_cdf(d1) - k * (-r * t).exp() * n_cdf(d2)
}

fn main() {
    let (s, k, r, q, sig, t) = (100.0_f64, 100.0_f64, 0.05_f64, 0.02_f64, 0.20_f64, 1.0_f64);
    let (mu, vt) = ((r - q - 0.5 * sig * sig) * t, sig * t.sqrt());
    let st = |z: f64| s * (mu + vt * z).exp();                    // Acme at expiry, z wiggle-units out
    let zk = ((k / s).ln() - mu) / vt;                            // above K exactly when z > zk
    let (d1, d2) = d1d2(s, k, r, q, sig, t);
    let (a, ap) = (aon(s, k, r, q, sig, t, false), aon(s, k, r, q, sig, t, true));
    let (b, bp) = (con(s, k, r, q, sig, t, false), con(s, k, r, q, sig, t, true));
    let disc = (-r * t).exp();
    // road 2: average the payoff over the bell curve, no d1 anywhere
    let above = simpson(|z| st(z) * phi(z), zk, 10.0, 20000);
    let a_int = disc * above;
    let ap_int = disc * simpson(|z| st(z) * phi(z), -10.0, zk, 20000);
    let c_int = disc * simpson(|z| (st(z) - k) * phi(z), zk, 10.0, 20000);
    let p_int = disc * simpson(|z| (k - st(z)) * phi(z), -10.0, zk, 20000);
    let p_cash = simpson(phi, zk, 10.0, 20000);
    let f_int = simpson(|z| st(z) * phi(z), -10.0, 10.0, 20000);
    let p_shr = above / f_int;
    let cond = above / p_cash;
    // road 3: the call minus K times its slope in the strike
    let h = 0.01;
    let a_slope = call(s, k, r, q, sig, t) - k * (call(s, k + h, r, q, sig, t) - call(s, k - h, r, q, sig, t)) / (2.0 * h);
    // road 4: simulation, xorshift random numbers, Box-Muller draws, antithetic pairs
    let mut state: u64 = 88172645463325252;
    let mut rnd = || {
        state ^= state >> 12; state ^= state << 25; state ^= state >> 27;
        (state.wrapping_mul(0x2545F4914F6CDD1D) >> 11) as f64 / 2f64.powi(53)
    };
    let n = 200000;
    let (mut tot, mut tot2) = (0.0_f64, 0.0_f64);
    for _ in 0..n {
        let (u1, u2) = (1.0 - rnd(), rnd());
        let z = (-2.0 * u1.ln()).sqrt() * (2.0 * PI * u2).cos();
        let mut pay = 0.0;
        for w in [z, -z] { if st(w) > k { pay += st(w); } }
        let x = 0.5 * pay * disc;
        tot += x; tot2 += x * x;
    }
    let a_mc = tot / n as f64;
    let se = ((tot2 / n as f64 - a_mc * a_mc) / n as f64).sqrt();
    // Greeks: formula, and by nudging the price
    let delta = (-q * t).exp() * (n_cdf(d1) + phi(d1) / vt);
    let vega = -s * (-q * t).exp() * phi(d1) * d2 / sig;
    let delta_b = (aon(s + h, k, r, q, sig, t, false) - aon(s - h, k, r, q, sig, t, false)) / (2.0 * h);
    let vega_b = (aon(s, k, r, q, sig + 1e-4, t, false) - aon(s, k, r, q, sig - 1e-4, t, false)) / 2e-4;
    let eq = (-q * t).exp();

    let rows: Vec<(&str, f64)> = vec![("d1", d1), ("d2", d2), ("e^-qT", eq), ("e^-rT", disc),
        ("N(d1)  chance counted in shares", n_cdf(d1)), ("N(d2)  chance counted in cash", n_cdf(d2)),
        ("1 asset call, formula", a), ("2 asset call, Simpson", a_int), ("3 asset call, C - K dC/dK", a_slope),
        ("4 asset call, simulation", a_mc), ("  simulation standard error", se),
        ("asset put, formula", ap), ("asset put, Simpson", ap_int), ("asset call + asset put", a + ap),
        ("  S e^-qT, prepaid share", s * eq),
        ("cash call, one dollar", b), ("cash put, one dollar", bp), ("cash call + cash put", b + bp),
        ("call = asset - 100 x cash", a - k * b), ("call by Simpson", c_int),
        ("put = 100 x cash put - asset put", k * bp - ap), ("put by Simpson", p_int),
        ("plain chance above, Simpson", p_cash), ("share-weighted chance, Simpson", p_shr),
        ("forward F by Simpson", f_int), ("  S e^(r-q)T", s * ((r - q) * t).exp()),
        ("average share given above", cond), ("  N(d1) / N(d2)", n_cdf(d1) / n_cdf(d2)), ("  average above / F", cond / f_int),
        ("delta, formula", delta), ("delta, nudged", delta_b), ("  share part, e^-qT N(d1)", eq * n_cdf(d1)),
        ("asset put delta", eq - delta),
        ("vega per 1.00 of vol, formula", vega), ("vega, nudged", vega_b), ("  vega per vol point (0.01)", vega / 100.0),
        ("wrong: N(d2) in the asset digital", s * eq * n_cdf(d2)),
        ("wrong: no e^-qT", s * n_cdf(d1)), ("wrong: today's S x cash digital", s * b),
        ("wrong: e^-rT in place of e^-qT", s * disc * n_cdf(d1)), ("wrong: asset - cash, no K", a - b),
        ("try: sigma = 0.40", aon(s, k, r, q, 0.40, t, false)), ("try: sigma = 0.10", aon(s, k, r, q, 0.10, t, false)),
        ("try: K = 120", aon(s, 120.0, r, q, sig, t, false)), ("try: q = 0", aon(s, k, r, 0.0, sig, t, false))];
    for (name, v) in &rows { println!("{:<36} {:>14.6}", name, v); }

    println!();
    let xs: Vec<f64> = (0..11).map(|i| 80.0 + 5.0 * i as f64).collect();
    let line = |label: &str, vals: Vec<String>| println!("{:<24}{}", label, vals.concat());
    line("chart, Acme at expiry", xs.iter().map(|x| format!("{:7.0}", x)).collect());
    line("chart, asset payoff", xs.iter().map(|&x| format!("{:7.2}", if x > k { x } else { 0.0 })).collect());
    line("chart, 100 cash payoff", xs.iter().map(|&x| format!("{:7.2}", if x > k { k } else { 0.0 })).collect());
    line("chart, call payoff", xs.iter().map(|&x| format!("{:7.2}", (x - k).max(0.0))).collect());
    let zb = |x: f64| ((x / s).ln() - mu) / vt;                     // price band edge -> wiggle units
    let edges: Vec<f64> = (0..11).map(|i| 60.0 + 10.0 * i as f64).collect();
    let plain: Vec<f64> = edges.windows(2).map(|e| 100.0 * simpson(phi, zb(e[0]), zb(e[1]), 2000)).collect();
    let share: Vec<f64> = edges.windows(2)
        .map(|e| 100.0 * simpson(|z| st(z) * phi(z), zb(e[0]), zb(e[1]), 2000) / f_int).collect();
    line("band centre ($)", edges[..10].iter().map(|a| format!("{:7.0}", a + 5.0)).collect());
    line("band, plain chance %", plain.iter().map(|v| format!("{:7.2}", v)).collect());
    line("band, share-weighted %", share.iter().map(|v| format!("{:7.2}", v)).collect());

    assert!((a_int - a).abs() < 1e-8, "Simpson road must land on the formula");
    assert!((a_slope - a).abs() < 1e-5, "call minus K times slope must land on the formula");
    assert!((a_mc - a).abs() < 4.0 * se, "simulation within four standard errors");
    assert!(((a - k * b) - 9.227005508154).abs() < 1e-9, "asset minus 100 cash must be the house call");
    assert!(((k * bp - ap) - 6.330080627550).abs() < 1e-9, "100 cash puts minus asset put must be the house put");
    assert!(((a_int + ap_int) - s * eq).abs() < 1e-8, "the two asset digitals by Simpson must make the prepaid share");
    assert!((p_shr - n_cdf(d1)).abs() < 1e-9, "share-weighted chance by Simpson vs N(d1)");
    assert!((p_cash - n_cdf(d2)).abs() < 1e-9, "plain chance by Simpson vs N(d2)");
    assert!((c_int - 9.227005508154).abs() < 1e-8, "call by Simpson must be the house call");
    assert!((cond / f_int - n_cdf(d1) / n_cdf(d2)).abs() < 1e-8, "average above / F must equal N(d1) / N(d2)");
    assert!((delta_b - delta).abs() < 1e-5, "nudged delta vs formula");
    assert!((vega_b - vega).abs() < 1e-4, "nudged vega vs formula");
    println!("ALL CHECKS PASS");
}
