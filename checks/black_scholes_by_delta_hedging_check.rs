// Black-Scholes by hedging -- the same check as the Python, in Rust.  No crates,
// std only.  Nothing here already knows the answer: the bell-curve area N(x) is
// built from its own series, the slope and the bend are taken from prices alone,
// and the grid road reaches the price from the equation and the payoff, never
// from the closed formula.  Acme is the house market: S = K = 100, r = 5%,
// q = 2%, sigma = 20%, one year.
// Compile: rustc --edition 2021 -O black_scholes_by_delta_hedging_check.rs
use std::f64::consts::PI;
const S0: f64 = 100.0;
const K: f64 = 100.0;
const R: f64 = 0.05;
const Q: f64 = 0.02;
const SIG: f64 = 0.20;
const T: f64 = 1.0;
const H: f64 = 0.20; const KT: f64 = 0.001;   // price step, time step, for differences

fn erf_series(x: f64) -> f64 {           // the error function as its own series
    let (mut term, mut total, mut n) = (x, 0.0_f64, 0.0_f64);
    while term.abs() > 1e-19 * (total.abs() + 1.0) && n < 300.0 {
        total += term / (2.0 * n + 1.0);
        n += 1.0;
        term *= -x * x / n;
    }
    2.0 / PI.sqrt() * total
}
fn nn(x: f64) -> f64 { 0.5 * (1.0 + erf_series(x / 2.0_f64.sqrt())) }  // area left of x
fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }     // height at x
fn d12(s: f64, tau: f64) -> (f64, f64) {
    let v = SIG * tau.sqrt();
    (((s / K).ln() + (R - Q + 0.5 * SIG * SIG) * tau) / v, v)
}
fn call(s: f64, tau: f64) -> f64 {
    let (d1, v) = d12(s, tau);
    s * (-Q * tau).exp() * nn(d1) - K * (-R * tau).exp() * nn(d1 - v)
}
fn put(s: f64, tau: f64) -> f64 {
    let (d1, v) = d12(s, tau);
    K * (-R * tau).exp() * nn(v - d1) - s * (-Q * tau).exp() * nn(-d1)
}
fn forward(s: f64, tau: f64) -> f64 {    // one funded share minus the funded strike
    s * (-Q * tau).exp() - K * (-R * tau).exp()
}
fn call_greeks(s: f64, tau: f64) -> (f64, f64, f64) {   // each from its own formula
    let (d1, v) = d12(s, tau);
    let (dq, dr) = ((-Q * tau).exp(), (-R * tau).exp());
    let theta = -s*dq*phi(d1)*SIG/(2.0*tau.sqrt()) + Q*s*dq*nn(d1) - R*K*dr*nn(d1 - v);
    (theta, dq * nn(d1), dq * phi(d1) / (s * SIG * tau.sqrt()))
}
fn put_greeks(s: f64, tau: f64) -> (f64, f64, f64) {
    let (d1, v) = d12(s, tau);
    let (dq, dr) = ((-Q * tau).exp(), (-R * tau).exp());
    let theta = -s*dq*phi(d1)*SIG/(2.0*tau.sqrt()) - Q*s*dq*nn(-d1) + R*K*dr*nn(v - d1);
    (theta, dq * (nn(d1) - 1.0), dq * phi(d1) / (s * SIG * tau.sqrt()))
}
fn forward_greeks(s: f64, tau: f64) -> (f64, f64, f64) {   // no bend: a straight line
    (Q * s * (-Q * tau).exp() - R * K * (-R * tau).exp(), (-Q * tau).exp(), 0.0)
}
fn left(s: f64, g: (f64, f64, f64)) -> f64 {               // clock + carry + bend
    g.0 + (R - Q) * s * g.1 + 0.5 * SIG * SIG * s * s * g.2
}
fn stencil<F: Fn(f64, f64) -> f64>(f: &F, s: f64, tau: f64, h: f64, k: f64)
        -> (f64, f64, f64, f64) {        // value, clock, slope, bend, from prices alone
    let v = f(s, tau);
    (v, (f(s, tau - k) - f(s, tau + k)) / (2.0 * k),
     (f(s + h, tau) - f(s - h, tau)) / (2.0 * h),
     (f(s + h, tau) - 2.0 * v + f(s - h, tau)) / (h * h))
}
fn refined<F: Fn(f64, f64) -> f64>(f: &F, s: f64, tau: f64, h: f64, k: f64)
        -> (f64, f64, f64) {             // two step sizes, leading step error cancelled
    let (_, t1, s1, b1) = stencil(f, s, tau, h, k);
    let (_, t2, s2, b2) = stencil(f, s, tau, 2.0 * h, 2.0 * k);
    ((4.0*t1 - t2)/3.0, (4.0*s1 - s2)/3.0, (4.0*b1 - b2)/3.0)
}
fn grid(m: usize, smax: f64, steps: usize) -> f64 {   // march the equation back
    let (ds, dt) = (smax / m as f64, T / steps as f64);
    let mut v: Vec<f64> = (0..=m).map(|i| (i as f64 * ds - K).max(0.0)).collect();
    for n in 1..=steps {
        let mut new = vec![0.0_f64; m + 1];
        for i in 1..m {
            let s = i as f64 * ds;
            new[i] = v[i] + dt * (0.5*SIG*SIG*s*s*(v[i-1] - 2.0*v[i] + v[i+1])/(ds*ds)
                                  + (R - Q)*s*(v[i+1] - v[i-1])/(2.0*ds) - R*v[i]);
        }
        new[m] = forward(smax, n as f64 * dt);
        v = new;
    }
    v[(S0 / ds).round() as usize]
}
fn yn(claim: bool) -> &'static str { if claim { "yes" } else { "no" } }

fn main() {
    let (d1, v1) = d12(S0, T);
    let (c, p, f) = (call(S0, T), put(S0, T), forward(S0, T));
    let (theta, delta, gamma) = call_greeks(S0, T);
    let (carry, bend) = ((R - Q) * S0 * delta, 0.5 * SIG * SIG * S0 * S0 * gamma);
    let res_c = left(S0, call_greeks(S0, T)) - R * c;
    let res_p = left(S0, put_greeks(S0, T)) - R * p;
    let res_f = left(S0, forward_greeks(S0, T)) - R * f;
    let cf = call;
    let (_, pt, ps, pb) = stencil(&cf, S0, T, H, KT);
    let (vt, vs, vb) = refined(&cf, S0, T, H, KT);
    let res_plain = pt + (R - Q)*S0*ps + 0.5*SIG*SIG*S0*S0*pb - R*c;
    let res_fine = vt + (R - Q)*S0*vs + 0.5*SIG*SIG*S0*S0*vb - R*c;
    let (g1, g2) = (grid(300, 300.0, 3601), grid(600, 300.0, 14401));
    let wrong_clock = -theta + carry + bend - R*c;        // clock read backwards
    let drop_half = theta + carry + 2.0*bend - R*c;       // Ito's one half thrown away
    let real_drift = theta + 0.10*S0*delta + bend - R*c;  // a 10% opinion for r - q
    let no_q = theta + R*S0*delta + bend - R*c;           // dividend dropped

    let rows: Vec<(&str, f64)> = vec![
        ("d1", d1), ("d2", d1 - v1), ("N(d1)", nn(d1)), ("N(d2)", nn(d1 - v1)),
        ("call C", c), ("put P", p), ("prepaid forward", f),
        ("Delta, shares of Acme per option", delta), ("Gamma, bend of the price", gamma),
        ("clock  Theta", theta), ("cash in the hedge, C - S Delta", c - delta * S0),
        ("carry  (r - q) S Delta", carry), ("bend   1/2 sig^2 S^2 Gamma", bend),
        ("clock + carry + bend", left(S0, (theta, delta, gamma))), ("r C", R * c),
        ("wrong: clock read backwards", wrong_clock),
        ("wrong: Ito's one half dropped", drop_half),
        ("wrong: real drift 0.10 for r - q", real_drift),
        ("wrong: dividend dropped", no_q)];
    for (name, v) in &rows { println!("{:<42}{:>18.12}", name, v); }
    println!("{:<42}{:>18.6}{:>12.6}", "price from the equation on a grid", g1, g2);
    println!("{:<42}{:>18.6}{:>12.6}", "  gap to the closed call", g1 - c, g2 - c);
    println!("residual under 1e-10 with the closed Greeks: call {}, put {}, prepaid forward {}",
             yn(res_c.abs() < 1e-10), yn(res_p.abs() < 1e-10), yn(res_f.abs() < 1e-10));
    println!("{:<42}{:>18.9}{:>14.9}{:>14.9}",
             "clock, slope, bend from prices alone", vt, vs, vb);
    println!("residual from prices alone under 1e-4: {}; two step sizes combined, under 1e-8: {}",
             yn(res_plain.abs() < 1e-4), yn(res_fine.abs() < 1e-8));
    println!();
    let spots: Vec<f64> = (0..11).map(|i| 90.0 + 2.0 * i as f64).collect();
    let mut a = format!("{:<30}", "hedge picture, Acme price");
    let mut b = format!("{:<30}", "hedge picture, the call C");
    let mut d = format!("{:<30}", "hedge picture, the hedge line");
    for s in &spots {
        a.push_str(&format!("{:>7.2}", s));
        b.push_str(&format!("{:>7.2}", call(*s, T)));
        d.push_str(&format!("{:>7.2}", c + delta * (s - S0)));
    }
    println!("{}\n{}\n{}", a, b, d);
    println!();
    println!("across Acme's price, 12 months to go, dollars per year");
    println!("{:>11}{:>10}{:>10}{:>10}{:>10}", "Acme", "clock", "carry", "bend", "r C");
    for s in [80.0_f64, 90.0, 100.0, 110.0, 120.0] {
        let (th, de, ga) = call_greeks(s, T);
        println!("{:>11.2}{:>10.2}{:>10.2}{:>10.2}{:>10.2}", s, th, (R - Q) * s * de,
                 0.5 * SIG * SIG * s * s * ga, R * call(s, T));
    }
    println!();
    println!("as the clock runs down, Acme at 100, dollars per year");
    println!("{:>11}{:>10}{:>10}{:>10}{:>10}", "months left", "clock", "carry", "bend", "r C");
    for m in [12_i32, 9, 6, 3, 1] {
        let tau = m as f64 / 12.0;
        let (th, de, ga) = call_greeks(S0, tau);
        println!("{:>11}{:>10.2}{:>10.2}{:>10.2}{:>10.2}", m, th, (R - Q) * S0 * de,
                 0.5 * SIG * SIG * S0 * S0 * ga, R * call(S0, tau));
    }

    assert!(res_c.abs() < 1e-10 && res_p.abs() < 1e-10, "closed call and put: left side must equal r V");
    assert!(res_f.abs() < 1e-10, "the prepaid forward obeys it with no bend at all");
    assert!((vt - theta).abs() < 1e-9 && (vs - delta).abs() < 1e-8, "prices alone reproduce clock and slope");
    assert!((vb - gamma).abs() < 1e-10, "prices alone reproduce the bend");
    assert!(res_fine.abs() < 1e-8, "prices alone satisfy the equation");
    assert!((g2 - c).abs() < 0.001 && (g1 - c).abs() < 0.005, "the grid road lands on the formula");
    assert!((g1 - c).abs() > 3.5 * (g2 - c).abs(), "halving the price step quarters the gap");
    assert!(wrong_clock > 10.0 && drop_half > 3.0, "a backwards clock and a lost half cost dollars");
    assert!(real_drift > 4.0 && no_q > 1.0, "an opinion and a missing dividend cost dollars");
    println!("ALL CHECKS PASS");
}
