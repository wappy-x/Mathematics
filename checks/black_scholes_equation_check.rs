// The Black-Scholes equation -- the same check as the Python, in Rust.  No crates.
// The bell-curve area N(x) is built here by Simpson's rule on the bell curve's own
// height, and road three marches the equation itself back from the payoff wall
// with no pricing formula inside it at all.  Every number quoted on the card is
// printed below.  Compile: rustc --edition 2021 -O black_scholes_equation_check.rs
use std::f64::consts::PI;

const S0: f64 = 100.0; const K: f64 = 100.0; const R: f64 = 0.05; const Q: f64 = 0.02;
const SG: f64 = 0.20; const T: f64 = 1.0; const MU: f64 = 0.10;
const DS: f64 = 1.0e-2; const DT: f64 = 1.0e-6; const DAY: f64 = 1.0 / 252.0;

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }   // bell-curve height

fn ncdf(x: f64) -> f64 {              // area under the bell curve left of x, by Simpson
    if x < -12.0 { return 0.0; }
    if x > 12.0 { return 1.0; }
    let (n, h) = (4000usize, x / 4000.0);
    let mut s = phi(0.0) + phi(x);
    for i in 1..n { s += (if i % 2 == 1 { 4.0 } else { 2.0 }) * phi(h * i as f64); }
    0.5 + s * h / 3.0
}

fn d1d2(s: f64, t: f64) -> (f64, f64) {          // t is the life left, in years
    let (v, m) = (SG * t.sqrt(), (s / K).ln() + (R - Q + 0.5 * SG * SG) * t);
    (m / v, m / v - v)
}

fn call(s: f64, t: f64) -> f64 {
    let (d1, d2) = d1d2(s, t);
    s * (-Q * t).exp() * ncdf(d1) - K * (-R * t).exp() * ncdf(d2)
}

fn put(s: f64, t: f64) -> f64 {
    let (d1, d2) = d1d2(s, t);
    K * (-R * t).exp() * ncdf(-d2) - s * (-Q * t).exp() * ncdf(-d1)
}

// a prepaid share less a loan: a claim with no curvature at all
fn forward(s: f64, t: f64) -> f64 { s * (-Q * t).exp() - K * (-R * t).exp() }

fn greeks(s: f64, t: f64) -> (f64, f64, f64) {   // theta, delta, gamma from the formula
    let (d1, d2) = d1d2(s, t);
    let (dq, dr) = ((-Q * t).exp(), (-R * t).exp());
    let theta = -s * dq * phi(d1) * SG / (2.0 * t.sqrt())
        + Q * s * dq * ncdf(d1) - R * K * dr * ncdf(d2);
    (theta, dq * ncdf(d1), dq * phi(d1) / (s * SG * t.sqrt()))
}

fn slopes(price: fn(f64, f64) -> f64, s: f64, t: f64) -> (f64, f64, f64, f64) {
    let v = price(s, t);              // road two: the three slopes by nudging
    let vt = (price(s, t - DT) - price(s, t + DT)) / (2.0 * DT);   // clock on = life down
    let vs = (price(s + DS, t) - price(s - DS, t)) / (2.0 * DS);
    let vss = (price(s + DS, t) - 2.0 * v + price(s - DS, t)) / (DS * DS);
    (v, vt, vs, vss)
}

fn leftover(price: fn(f64, f64) -> f64, s: f64, t: f64) -> f64 {
    let (v, vt, vs, vss) = slopes(price, s, t);
    vt + (R - Q) * s * vs + 0.5 * SG * SG * s * s * vss - R * v
}

fn grid(is_call: bool) -> f64 {
    // Road three: the equation alone, marched back from the payoff wall on a grid
    // of x = ln(S/K), spaced dx apart.  No d1, no d2, no bell curve anywhere.
    let (m, steps, l) = (600usize, 2000usize, 1.5f64);
    let (dx, dt) = (2.0 * l / m as f64, T / steps as f64);
    let (a, b) = (0.5 * SG * SG, R - Q - 0.5 * SG * SG);
    let mut v: Vec<f64> = (0..=m).map(|i| {
        let sx = K * (-l + i as f64 * dx).exp();
        if is_call { (sx - K).max(0.0) } else { (K - sx).max(0.0) }
    }).collect();
    for s in 0..steps {
        let tl = (s + 1) as f64 * dt;             // life left after this step
        let mut nv = vec![0.0f64; m + 1];
        for i in 1..m {
            nv[i] = v[i] + dt * (a * (v[i + 1] - 2.0 * v[i] + v[i - 1]) / (dx * dx)
                + b * (v[i + 1] - v[i - 1]) / (2.0 * dx) - R * v[i]);
        }
        nv[m] = if is_call { K * (l - Q * tl).exp() - K * (-R * tl).exp() } else { 0.0 };
        nv[0] = if is_call { 0.0 } else { K * (-R * tl).exp() - K * (-l - Q * tl).exp() };
        v = nv;
    }
    v[m / 2]
}

fn hedged_day(ds: f64, c: f64, de: f64) -> f64 {  // road four: revalue one day later
    (call(S0 + ds, T - DAY) - de * (S0 + ds)) - (c - de * S0)
        + (de * S0 - c) * ((R * DAY).exp() - 1.0) - Q * de * S0 * DAY
}

fn show(title: &str, rows: &[(&str, f64)]) {
    println!("{}", title);
    for (name, v) in rows { println!("{:<34}{:>18.12}", name, v); }
}

fn main() {
    let (c, p) = (call(S0, T), put(S0, T));
    let (d1, d2) = d1d2(S0, T);
    let (th, de, ga) = greeks(S0, T);
    let (a, b, cu, d) = (th, (R - Q) * S0 * de, 0.5 * SG * SG * S0 * S0 * ga, R * c);
    let (cash, be) = (c - de * S0, SG * S0 * DAY.sqrt());
    let (v, vt, vs, vss) = slopes(call, S0, T);
    let (gc, gp) = (grid(true), grid(false));
    let still = -0.5 * ga * SG * SG * S0 * S0 * DAY;

    show("Black-Scholes equation, house market: S=K=100 r=5% q=2% sigma=20% T=1",
         &[("call V", c), ("put V", p), ("d1", d1), ("d2", d2)]);
    show("-- road one: the three slopes from the closed formula --",
         &[("theta  dV/dt, dollars a year", th), ("delta  dV/dS", de),
           ("gamma  d(delta)/dS", ga), ("A  theta", a), ("B  (r-q) S delta", b),
           ("C  half sigma^2 S^2 gamma", cu), ("A + B + C", a + b + cu), ("D  r V", d),
           ("call leftover A+B+C-D", a + b + cu - d), ("cash in the mix, V - S delta", cash),
           ("A + C, theta plus gamma", a + cu), ("r(V - S delta) + q S delta", R * cash + Q * S0 * de)]);
    show("-- road two: the same slopes by nudging, no Greek named --",
         &[("call dV/dt by nudging", vt), ("call dV/dS by nudging", vs),
           ("call d2V/dS2 by nudging", vss), ("call leftover by nudging", leftover(call, S0, T)),
           ("put leftover by nudging", leftover(put, S0, T)),
           ("prepaid share less loan, leftover", leftover(forward, S0, T))]);
    show("-- road three: the equation marched back from the payoff wall --",
         &[("call from the grid", gc), ("put from the grid", gp),
           ("worst gap to the formula", (gc - c).abs().max((gp - p).abs()))]);
    show("-- road four: one hedged day, revalued against the forecast --",
         &[("break-even move sigma S sqrt(day)", be), ("still day, hedged P&L", hedged_day(0.0, c, de)),
           ("still day, forecast from gamma", still), ("break-even day, hedged P&L", hedged_day(be, c, de))]);
    show("-- what breaks: each wrong equation's leftover, dollars a year --",
         &[("clock sign flipped", -vt + (R - Q) * S0 * vs + 0.5 * SG * SG * S0 * S0 * vss - R * v),
           ("Ito half dropped", vt + (R - Q) * S0 * vs + SG * SG * S0 * S0 * vss - R * v),
           ("real drift mu = 10% for r - q", vt + MU * S0 * vs + 0.5 * SG * SG * S0 * S0 * vss - R * v),
           ("q dropped from the equation", vt + R * S0 * vs + 0.5 * SG * SG * S0 * S0 * vss - R * v)]);

    let g6: Vec<(f64, (f64, f64, f64))> =
        (0..6).map(|i| 80.0 + 10.0 * i as f64).map(|s| (s, greeks(s, T))).collect();
    let bar = |lab: &str, f: &dyn Fn(f64, (f64, f64, f64)) -> f64| {
        let mut line = format!("{:<14}", lab);
        for &(s, g) in &g6 { line.push_str(&format!("{:>9.2}", f(s, g))); }
        println!("{}", line);
    };
    println!("-- the three terms across the share price, for the chart --");
    let mut line = format!("{:<14}", "share price");
    for &(s, _) in &g6 { line.push_str(&format!("{:>9.0}", s)); }
    println!("{}", line);
    bar("theta", &|_s, g| g.0);
    bar("gamma term", &|s, g| 0.5 * SG * SG * s * s * g.2);
    bar("carry term", &|s, g| (R - Q) * s * g.1);
    bar("r V", &|s, _g| R * call(s, T));
    println!("-- the same budget in cents a day, as expiry comes --");
    println!("{:<14}{:>9}{:>9}{:>9}{:>9}", "months left", "theta", "gamma", "carry", "r V");
    for mo in [12i32, 9, 6, 3, 1] {
        let t = mo as f64 / 12.0;
        let (mth, mde, mga) = greeks(S0, t);
        let cells = [mth, 0.5 * SG * SG * S0 * S0 * mga, (R - Q) * S0 * mde, R * call(S0, t)];
        let mut line = format!("{:<14}", mo);
        for x in cells { line.push_str(&format!("{:>9.2}", 100.0 * x * DAY)); }
        println!("{}", line);
    }

    assert!((vt - th).abs() < 1e-6, "nudged dV/dt against the closed theta");
    assert!((vs - de).abs() < 1e-6, "nudged dV/dS against the closed delta");
    assert!((vss - ga).abs() < 1e-6, "nudged d2V/dS2 against the closed gamma");
    assert!((a + b + cu - d).abs() < 1e-12, "the closed call's slopes satisfy the equation");
    assert!(leftover(put, S0, T).abs() < 1e-6, "the put satisfies it too");
    assert!(leftover(forward, S0, T).abs() < 1e-6, "so does a prepaid share less a loan");
    assert!((gc - 9.227005508154).abs() < 1e-3, "the marched grid lands on the card's call price");
    assert!((gp - 6.330080627550).abs() < 1e-3, "and on the card's put price");
    assert!((hedged_day(0.0, c, de) - still).abs() < 1e-3, "revalued still day against the forecast");
    assert!(hedged_day(be, c, de).abs() < 5e-3, "a break-even move leaves the hedged day flat");
    assert!((a + cu - (R * cash + Q * S0 * de)).abs() < 1e-12, "the trader's reading of the line");
    println!("ALL CHECKS PASS");
}
