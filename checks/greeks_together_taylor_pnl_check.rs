// The Greeks together -- the same check as greeks_together_taylor_pnl_check.py, in Rust.
// Standard library only, no crates.  Rust has no erf, so the bell-curve area N(x)
// is built by adding thin slices under the curve (Simpson's rule).
// Compile: rustc --edition 2021 -O greeks_together_taylor_pnl_check.rs
use std::f64::consts::PI;

const K: f64 = 100.0;
const Q: f64 = 0.02;

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
    0.5 + simpson(phi, 0.0, x, 4000)
}

fn call(s: f64, sg: f64, t: f64, r: f64) -> f64 {
    let d1 = ((s / K).ln() + (r - Q + 0.5 * sg * sg) * t) / (sg * t.sqrt());
    s * (-Q * t).exp() * n_cdf(d1) - K * (-r * t).exp() * n_cdf(d1 - sg * t.sqrt())
}

fn call_integral(s: f64, sg: f64, t: f64, r: f64) -> f64 {
    let f = |z: f64| (s * ((r - Q - 0.5 * sg * sg) * t + sg * t.sqrt() * z).exp() - K).max(0.0) * phi(z);
    (-r * t).exp() * simpson(f, -10.0, 10.0, 20000)
}

const NAMES: [&str; 8] = ["delta", "gamma", "vega", "theta", "rho", "vanna", "volga", "charm"];

// Greeks as an array in NAMES order; the card's formula term by term
fn terms(g: &[f64; 8], ds: f64, dv: f64, dt: f64, dr: f64) -> Vec<(&'static str, f64)> {
    vec![("delta x dS", g[0] * ds), ("1/2 gamma x dS^2", 0.5 * g[1] * ds * ds),
         ("vega x dsigma", g[2] * dv), ("theta x dt", g[3] * dt), ("rho x dr", g[4] * dr),
         ("vanna x dS x dsigma", g[5] * ds * dv), ("1/2 volga x dsigma^2", 0.5 * g[6] * dv * dv)]
}
fn total(t: &[(&str, f64)]) -> f64 { t.iter().map(|x| x.1).sum() }
fn p(lab: &str, vals: &[f64]) {
    let mut line = format!("{:<38}", lab);
    for v in vals { line.push_str(&format!(" {:>11.6}", v)); }
    println!("{}", line);
}

fn main() {
    let (s, sg, tt, r) = (100.0_f64, 0.20_f64, 1.0_f64, 0.05_f64);
    let rt = tt.sqrt();
    let d1 = ((s / K).ln() + (r - Q + 0.5 * sg * sg) * tt) / (sg * rt);
    let d2 = d1 - sg * rt;
    let (eq, er) = ((-Q * tt).exp(), (-r * tt).exp());
    let g: [f64; 8] = [
        eq * n_cdf(d1), eq * phi(d1) / (s * sg * rt), s * eq * phi(d1) * rt,
        -s * eq * phi(d1) * sg / (2.0 * rt) - r * K * er * n_cdf(d2) + Q * s * eq * n_cdf(d1),
        K * tt * er * n_cdf(d2), -eq * phi(d1) * d2 / sg, s * eq * phi(d1) * rt * d1 * d2 / sg,
        Q * eq * n_cdf(d1) - eq * phi(d1) * (2.0 * (r - Q) * tt - d2 * sg * rt) / (2.0 * tt * sg * rt),
    ];
    // price with spot x, vol v, calendar time elapsed t, rate rr
    let v = |x: f64, vv: f64, t: f64, rr: f64| call(x, vv, tt - t, rr);
    let (hs, hv, ht, hr) = (0.01, 1e-3, 1e-4, 1e-4);
    let b: [f64; 8] = [
        (v(s + hs, sg, 0.0, r) - v(s - hs, sg, 0.0, r)) / (2.0 * hs),
        (v(s + hs, sg, 0.0, r) - 2.0 * v(s, sg, 0.0, r) + v(s - hs, sg, 0.0, r)) / (hs * hs),
        (v(s, sg + hv, 0.0, r) - v(s, sg - hv, 0.0, r)) / (2.0 * hv),
        (v(s, sg, ht, r) - v(s, sg, -ht, r)) / (2.0 * ht),
        (v(s, sg, 0.0, r + hr) - v(s, sg, 0.0, r - hr)) / (2.0 * hr),
        (v(s + hs, sg + hv, 0.0, r) - v(s + hs, sg - hv, 0.0, r) - v(s - hs, sg + hv, 0.0, r)
            + v(s - hs, sg - hv, 0.0, r)) / (4.0 * hs * hv),
        (v(s, sg + hv, 0.0, r) - 2.0 * v(s, sg, 0.0, r) + v(s, sg - hv, 0.0, r)) / (hv * hv),
        (v(s + hs, sg, ht, r) - v(s - hs, sg, ht, r) - v(s + hs, sg, -ht, r) + v(s - hs, sg, -ht, r))
            / (4.0 * hs * ht),
    ];

    let (ds, dv, dt) = (5.0, 0.01, 1.0 / 365.0);
    let v0 = v(s, sg, 0.0, r);
    let exact = v(s + ds, sg + dv, dt, r) - v0;
    let exact_int = call_integral(s + ds, sg + dv, tt - dt, r) - call_integral(s, sg, tt, r);
    let tm = terms(&g, ds, dv, dt, 0.0);
    let (est, est_b) = (total(&tm), total(&terms(&b, ds, dv, dt, 0.0)));
    let dgv = tm[0].1 + tm[1].1 + tm[2].1;
    p("price today: formula, integral", &[v0, call_integral(s, sg, tt, r)]);
    println!("greek: closed form, by bump");
    for i in 0..8 { p(&format!("  {}", NAMES[i]), &[g[i], b[i]]); }
    println!("move: spot +5, vol +1 point, one day, term by term");
    for (l, x) in &tm { p(l, &[*x]); }
    p("charm x dS x dt (dropped)", &[g[7] * ds * dt]);
    p("estimate: closed-form, bumped Greeks", &[est, est_b]);
    p("exact reprice: formula, integral", &[exact, exact_int]);
    p("error, exact - estimate", &[exact - est]);
    println!("terms kept: estimate, estimate - exact");
    for (l, x) in [("delta only", tm[0].1), ("delta-gamma", tm[0].1 + tm[1].1), ("delta-gamma-vega", dgv),
                   ("plus theta", dgv + tm[3].1), ("all seven", est)] { p(&format!("  {}", l), &[x, x - exact]); }
    p("delta term share of estimate", &[tm[0].1 / est]);
    p("typical day's move, sigma S sqrt(dt)", &[sg * s * dt.sqrt()]);
    p("wrong: no 1/2 on gamma", &[est + tm[1].1]); p("wrong: vol point as 1", &[est - tm[2].1 + g[2]]);
    p("wrong: theta x 1 (day as 1)", &[est - tm[3].1 + g[3]]); p("wrong: no vanna", &[est - tm[5].1]);
    let wr = 0.0025;
    p("try: rates +0.25%: rho, est, exact", &[g[4] * wr, est + g[4] * wr, v(s + ds, sg + dv, dt, r + wr) - v0]);

    // cube law: scale the whole move (dS, dsigma) = k x (5, 0.01), no time passing
    let gk = |k: f64| v(s + 5.0 * k, sg + 0.01 * k, 0.0, r);
    let h3 = 0.05;
    let g3 = (gk(2.0 * h3) - 2.0 * gk(h3) + 2.0 * gk(-h3) - gk(-2.0 * h3)) / (2.0 * h3 * h3 * h3);
    p("third-order coefficient g3/6", &[g3 / 6.0]);
    println!("   k  spot  vol pts     exact  estimate     error  error/k^3");
    let ks = [0.5_f64, 1.0, 2.0, 4.0];
    let mut errs = [0.0_f64; 4];
    for (i, k) in ks.iter().enumerate() {
        let e = gk(*k) - v0;
        let a = total(&terms(&g, 5.0 * k, 0.01 * k, 0.0, 0.0));
        errs[i] = e - a;
        println!("{:4.1} {:+5.1} {:+8.1} {:9.4} {:9.4} {:9.5} {:10.6}", k, 5.0 * k, k, e, a, e - a, (e - a) / k.powi(3));
    }
    for i in 0..3 { p(&format!("error ratio, move x2 from k = {:.1}", ks[i]), &[errs[i + 1] / errs[i]]); }
    p("error ratio, move x4 from k = 1.0", &[errs[3] / errs[1]]);
    let xs: Vec<f64> = (0..9).map(|i| -20.0 + 5.0 * i as f64).collect();
    println!("chart, spot move ($)      {}", xs.iter().map(|x| format!("{:6.0}", x)).collect::<Vec<_>>().join(" "));
    let mut rows: [Vec<f64>; 3] = [vec![], vec![], vec![]];
    for x in &xs {
        rows[0].push(v(s + x, sg + 0.01, dt, r) - v0);
        let t = terms(&g, *x, 0.01, dt, 0.0);
        rows[1].push(t[0].1);
        rows[2].push(total(&t));
    }
    for (lab, vals) in ["chart, exact", "chart, delta only", "chart, full estimate"].iter().zip(rows.iter()) {
        println!("{:<26}{}", lab, vals.iter().map(|x| format!("{:6.2}", x)).collect::<Vec<_>>().join(" "));
    }
    p("at +20: full - exact, delta - exact", &[rows[2][8] - rows[0][8], rows[1][8] - rows[0][8]]);

    assert!((v0 - 9.227005508154).abs() < 1e-9, "own normal CDF reproduces the house call");
    for i in 0..8 { assert!((g[i] - b[i]).abs() < 1e-4 * g[i].abs().max(1.0), "closed-form Greeks vs bumps"); }
    assert!((exact - exact_int).abs() < 1e-6, "formula reprice vs integral reprice");
    assert!((est - exact).abs() < 0.02 * exact.abs(), "second-order estimate within 2% of the reprice");
    assert!((errs[0] / 0.125 - g3 / 6.0).abs() < 0.05 * (g3 / 6.0).abs(), "error at small moves follows g3/6 k^3");
    assert!(errs[1] / errs[0] > 7.0 && errs[1] / errs[0] < 9.0, "halving the move cuts the error about eightfold");
    println!("ALL CHECKS PASS");
}
