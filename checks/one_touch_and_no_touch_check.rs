// One-touch and no-touch -- the same check as one_touch_and_no_touch_check.py, in Rust.
// Standard library only, no crates.  Roads: reflection formulas, Simpson integrals
// of the first-passage and surviving-path densities, and a simulation.
use std::f64::consts::PI;

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }
fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    s * h / 3.0
}
fn n_cdf(x: f64) -> f64 {
    if x < -12.0 { return 0.0; }
    if x > 12.0 { return 1.0; }
    0.5 + simpson(phi, 0.0, x, 2000)
}
fn drift(r: f64, q: f64, sig: f64) -> f64 { r - q - 0.5 * sig * sig }
fn touch_prob_nu(s: f64, h: f64, sig: f64, t: f64, v: f64) -> f64 {     // road 1: reflection formula
    let b = (h / s).ln();
    if b <= 0.0 { return 1.0; }
    let st = sig * t.sqrt();
    n_cdf((v * t - b) / st) + (2.0 * v * b / sig.powf(2.0)).exp() * n_cdf((-b - v * t) / st)
}
fn touch_prob(s: f64, h: f64, q: f64, r: f64, sig: f64, t: f64) -> f64 { touch_prob_nu(s, h, sig, t, drift(r, q, sig)) }
fn one_touch_expiry(s: f64, h: f64, q: f64, r: f64, sig: f64, t: f64) -> f64 { (-r * t).exp() * touch_prob(s, h, q, r, sig, t) }
fn no_touch(s: f64, h: f64, q: f64, r: f64, sig: f64, t: f64) -> f64 {
    let (b, v, st) = ((h / s).ln(), drift(r, q, sig), sig * t.sqrt());
    if b <= 0.0 { return 0.0; }
    (-r * t).exp() * (n_cdf((b - v * t) / st) - (2.0 * v * b / sig.powf(2.0)).exp() * n_cdf((-b - v * t) / st))
}
fn one_touch_hit(s: f64, h: f64, q: f64, r: f64, sig: f64, t: f64) -> f64 {
    let (b, v) = ((h / s).ln(), drift(r, q, sig));
    if b <= 0.0 { return 1.0; }
    let vt = (v * v + 2.0 * r * sig * sig).sqrt();                        // the steeper drift
    (b * (v - vt) / sig.powf(2.0)).exp() * touch_prob_nu(s, h, sig, t, vt)
}

fn main() {
    let (s, h, r, q, sig, t) = (100.0_f64, 120.0_f64, 0.05_f64, 0.02_f64, 0.20_f64, 1.0_f64);
    let (b, nu, d) = ((h / s).ln(), drift(r, q, sig), (-r * t).exp());
    let w = (2.0 * nu * b / sig.powf(2.0)).exp();
    let fpt = |tt: f64| if tt <= 0.0 { 0.0 } else {
        b / (sig * (2.0 * PI * tt.powf(3.0)).sqrt()) * (-(b - nu * tt).powf(2.0) / (2.0 * sig * sig * tt)).exp() };
    let (q1, q2) = (touch_prob(s, h, q, r, sig, t), simpson(&fpt, 0.0, t, 20000));
    let (hit1, hit2) = (one_touch_hit(s, h, q, r, sig, t), simpson(|tt| (-r * tt).exp() * fpt(tt), 0.0, t, 20000));
    let st = sig * t.sqrt();
    let alive = |x: f64| (phi((x - nu * t) / st) - w * phi((x - 2.0 * b - nu * t) / st)) / st;
    let (nt1, nt2) = (no_touch(s, h, q, r, sig, t), d * simpson(alive, b - 12.0 * st, b, 20000));

    let mut state: u64 = 20260924;                                          // road 3: simulation
    let mut unif = || {
        state = state.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
        ((state >> 11) as f64 + 0.5) / 9007199254740992.0
    };
    let (paths, steps) = (20000usize, 250usize);
    let dt = t / steps as f64;
    let (mut hits, mut pv, mut pv2) = (0usize, 0.0_f64, 0.0_f64);
    for _ in 0..paths {
        let mut x = 0.0_f64;
        for k in 0..steps {
            let z = (-2.0 * unif().ln()).sqrt() * (2.0 * PI * unif()).cos();
            let y = x + nu * dt + sig * dt.sqrt() * z;
            let u = unif();                                                 // bridge: touched between steps?
            if y >= b || u < (-2.0 * (b - x) * (b - y) / (sig * sig * dt)).exp() {
                hits += 1; let g = (-r * (k as f64 + 0.5) * dt).exp(); pv += g; pv2 += g * g;
                break;
            }
            x = y;
        }
    }
    let (q3, hit3) = (hits as f64 / paths as f64, pv / paths as f64);
    let se_q = (q3 * (1.0 - q3) / paths as f64).sqrt();
    let se_h = ((pv2 / paths as f64 - hit3.powf(2.0)) / paths as f64).sqrt();

    let vt = (nu * nu + 2.0 * r * sig * sig).sqrt();
    let up = n_cdf((nu * t - b) / st);
    let rows: Vec<(&str, f64)> = vec![
        ("log distance b = ln(H/S)", b), ("log drift nu = r - q - sigma^2/2", nu),
        ("reflection weight (H/S)^(2 nu/sigma^2)", w), ("mirror start H^2/S", h * h / s), ("discount D(T) = e^-rT", d),
        ("z-score, end beyond 120", (nu * t - b) / st), ("z-score, mirror term", (-b - nu * t) / st),
        ("paths ending beyond 120", up), ("touched, ending below (mirror term)", w * n_cdf((-b - nu * t) / st)),
        ("touch prob, 1 reflection formula", q1), ("touch prob, 2 first-passage integral", q2),
        ("touch prob, 3 simulation", q3), ("  simulation standard error", se_q),
        ("one-touch at expiry, D(T) x Q", d * q1), ("no-touch, 1 formula", nt1), ("no-touch, 2 surviving-path integral", nt2),
        ("one-touch + no-touch", d * q1 + nt2), ("one-touch at hit, 1 formula", hit1),
        ("one-touch at hit, 2 discounted density", hit2), ("one-touch at hit, 3 simulation", hit3),
        ("  simulation standard error", se_h), ("steeper drift sqrt(nu^2 + 2 r sigma^2)", vt),
        ("at-hit weight e^(b(nu - nut)/sigma^2)", (b * (nu - vt) / sig.powf(2.0)).exp()), ("touch prob with the steeper drift", touch_prob_nu(s, h, sig, t, vt)),
        ("wrong: no mirror term, D(T) x P(end>=120)", d * up),
        ("wrong: mirror weight set to 1", d * (up + n_cdf((-b - nu * t) / st))),
        ("wrong: drift r - q, no -sigma^2/2", d * touch_prob_nu(s, h, sig, t, r - q)),
        ("rule of thumb: 2 x digital at 120", 2.0 * d * up),
        ("try: sigma = 0.30", one_touch_expiry(s, h, q, r, 0.30, t)), ("try: H = 110", one_touch_expiry(s, 110.0, q, r, sig, t)),
        ("try: T = 2", one_touch_expiry(s, h, q, r, sig, 2.0)), ("try: r=0.04, q=0.02 (nu=0), touch prob", touch_prob(s, h, q, 0.04, sig, t)),
        ("try: nu=0, 2 x P(end>=120)", 2.0 * n_cdf(-b / st)),
    ];
    println!("house market, S=100 H=120 r=0.05 q=0.02 sigma=0.20 T=1, $1 paid");
    for (lab, v) in &rows { println!("{:<42} {:>10.6}", lab, v); }
    println!("greeks by nudging            one-touch(exp)    no-touch");
    type P = fn(f64, f64, f64, f64, f64, f64) -> f64;
    let greeks: [(&str, Box<dyn Fn(P) -> f64>); 4] = [
        ("delta, per $1 of S", Box::new(move |g: P| (g(s + 0.01, h, q, r, sig, t) - g(s - 0.01, h, q, r, sig, t)) / 0.02)),
        ("gamma, per $1 of S", Box::new(move |g: P| (g(s + 0.5, h, q, r, sig, t) - 2.0 * g(s, h, q, r, sig, t) + g(s - 0.5, h, q, r, sig, t)) / 0.25)),
        ("vega, per 1 vol point", Box::new(move |g: P| (g(s, h, q, r, sig + 0.0001, t) - g(s, h, q, r, sig - 0.0001, t)) / 0.02)),
        ("theta, per day", Box::new(move |g: P| g(s, h, q, r, sig, t - 1.0 / 365.0) - g(s, h, q, r, sig, t))),
    ];
    for (lab, f) in &greeks { println!("{:<28} {:>14.6} {:>11.6}", lab, f(one_touch_expiry), f(no_touch)); }
    let spots: Vec<f64> = (0..9).map(|i| 80.0 + 5.0 * i as f64).collect();
    println!("chart, Acme price       {}", spots.iter().map(|x| format!("{:5.0}", x)).collect::<Vec<_>>().join(" "));
    for (lab, tt) in [("chart, 12 months left", 1.0), ("chart, 6 months left", 0.5), ("chart, 1 month left", 1.0 / 12.0)] {
        let v: Vec<String> = spots.iter().map(|&x| format!("{:5.2}", one_touch_expiry(x, h, q, r, sig, tt))).collect();
        println!("{:<24}{}", lab, v.join(" "));
    }
    let highs = [100, 105, 110, 115, 119, 120, 125, 130];
    let line = |f: &dyn Fn(i32) -> i32| highs.iter().map(|&x| format!("{:5}", f(x))).collect::<Vec<_>>().join(" ");
    println!("payoff, year's high     {}", line(&|x| x));
    println!("payoff, one-touch       {}", line(&|x| if x >= 120 { 1 } else { 0 }));
    println!("payoff, no-touch        {}", line(&|x| if x >= 120 { 0 } else { 1 }));

    assert!((q1 - 0.378622).abs() < 5e-7, "formula vs the spec's touch probability");
    assert!((nt1 - nt2).abs() < 1e-7, "no-touch formula vs surviving-path integral");
    assert!((q1 - q2).abs() < 1e-7, "reflection formula vs integrated first-passage density");
    assert!((hit1 - hit2).abs() < 1e-7, "at-hit formula vs discounted density integral");
    assert!((d * q1 + nt2 - d).abs() < 1e-7, "one-touch plus independently integrated no-touch is a sure dollar");
    assert!((q3 - q1).abs() < 4.0 * se_q, "simulated touch probability within four standard errors");
    assert!((hit3 - hit1).abs() < 4.0 * se_h, "simulated at-hit price within four standard errors");
    println!("ALL CHECKS PASS");
}
