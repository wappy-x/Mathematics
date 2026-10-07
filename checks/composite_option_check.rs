// Composite option -- the same check as composite_option_check.py, in Rust.
// Standard library only, no crates.  The normal CDF is Simpson slices under the
// bell curve; the two-asset averages are Simpson grids over two bell curves.
use std::f64::consts::PI;

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }

fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    s * h / 3.0
}

fn ncdf(x: f64) -> f64 {
    if x < -12.0 { return 0.0; }
    if x > 12.0 { return 1.0; }
    0.5 + simpson(phi, 0.0, x, 2000)
}

fn bs_call(s: f64, k: f64, r: f64, q: f64, v: f64, t: f64) -> (f64, f64, f64) {
    let d1 = ((s / k).ln() + (r - q + 0.5 * v * v) * t) / (v * t.sqrt());
    let d2 = d1 - v * t.sqrt();
    (s * (-q * t).exp() * ncdf(d1) - k * (-r * t).exp() * ncdf(d2), d1, d2)
}

const S: f64 = 100.0; const KE: f64 = 100.0; const X0: f64 = 1.10;
const RD: f64 = 0.05; const RF: f64 = 0.03; const Q: f64 = 0.01;
const SS: f64 = 0.20; const SX: f64 = 0.10; const RHO: f64 = 0.30; const T: f64 = 1.0;
const K: f64 = KE * X0;

fn comp_vol(rho: f64) -> f64 { (SS * SS + SX * SX + 2.0 * rho * SS * SX).sqrt() }
fn composite(rho: f64, s: f64, x: f64, s1: f64) -> (f64, f64, f64) {         // road 1: the formula
    let v = (s1 * s1 + SX * SX + 2.0 * rho * s1 * SX).sqrt();
    bs_call(s * x, K, RD, Q, v, T)
}
fn c_at(rho: f64) -> f64 { composite(rho, S, X0, SS).0 }
fn quanto(rho: f64) -> f64 { X0 * bs_call(S, KE, RD, RD - (RF - Q - rho * SS * SX), SS, T).0 }

fn avg2<F: Fn(f64, f64) -> [f64; 6]>(f: F, m: f64) -> [f64; 6] {   // roads 2 and 3: Simpson grid
    let (n, l) = (600usize, 8.0_f64);
    let h = 2.0 * l / n as f64;
    let w: Vec<f64> = (0..=n).map(|i| (if i == 0 || i == n { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 }) * h / 3.0).collect();
    let c = (1.0 - RHO * RHO).sqrt();
    let mut tot = [0.0_f64; 6];
    for i in 0..=n {
        let a = -l + i as f64 * h + m;
        for j in 0..=n {
            let b = -l + j as f64 * h;
            let vals = f(a, RHO * a + c * b);
            let ww = w[i] * phi(a) * w[j] * phi(b);
            for k in 0..6 { tot[k] += ww * vals[k]; }
        }
    }
    tot
}

fn usd_world(zs: f64, zx: f64) -> [f64; 6] {
    let st = S * ((RF - Q - RHO * SS * SX - 0.5 * SS * SS) * T + SS * T.sqrt() * zs).exp();
    let xt = X0 * ((RD - RF - 0.5 * SX * SX) * T + SX * T.sqrt() * zx).exp();
    let v = st * xt;
    let lg = (v / (S * X0)).ln();
    [(v - K).max(0.0), (K - v).max(0.0), X0 * (st - KE).max(0.0), xt * (st - KE).max(0.0), lg, lg * lg]
}
fn eur_world(zs: f64, zx: f64) -> [f64; 6] {
    let st = S * ((RF - Q - 0.5 * SS * SS) * T + SS * T.sqrt() * zs).exp();
    let inv_xt = ((RF - RD - 0.5 * SX * SX) * T - SX * T.sqrt() * zx).exp() / X0;
    [(st - K * inv_xt).max(0.0), 0.0, 0.0, 0.0, 0.0, 0.0]
}

fn main() {
    let plain = X0 * bs_call(S, KE, RF, Q, SS, T).0;
    let m = ((KE / S).ln() - (RF - Q - RHO * SS * SX - 0.5 * SS * SS) * T) / (SS * T.sqrt());
    let u = avg2(usd_world, m);
    let e = avg2(eur_world, 0.0);
    let (c, d1, d2) = composite(RHO, S, X0, SS);
    let disc = (-RD * T).exp();
    let (c_usd, p_usd, q_int, plain_int) = (disc * u[0], disc * u[1], disc * u[2], disc * u[3]);
    let c_eur = X0 * (-RF * T).exp() * e[0];
    let vol_int = ((u[5] - u[4] * u[4]) / T).sqrt();
    let h = 1e-4;
    let ds = (composite(RHO, S + h, X0, SS).0 - composite(RHO, S - h, X0, SS).0) / (2.0 * h);
    let dx = (composite(RHO, S, X0 + h, SS).0 - composite(RHO, S, X0 - h, SS).0) / (2.0 * h);
    let dr = (c_at(RHO + h) - c_at(RHO - h)) / (2.0 * h);
    let dss = (composite(RHO, S, X0, SS + h).0 - composite(RHO, S, X0, SS - h).0) / (2.0 * h);
    let eq = (-Q * T).exp();
    let vega = S * X0 * eq * phi(d1) * T.sqrt();
    let rows: Vec<(&str, f64)> = vec![
        ("cross term 2 rho sS sX", 2.0 * RHO * SS * SX), ("composite variance", comp_vol(RHO).powi(2)),
        ("composite vol", comp_vol(RHO)), ("  vol from the log-moments integral", vol_int),
        ("d1", d1), ("d2", d2), ("N(d1)", ncdf(d1)), ("N(d2)", ncdf(d2)),
        ("share side V e^-qT N(d1)", S * X0 * eq * ncdf(d1)),
        ("cash side K e^-rdT N(d2)", K * disc * ncdf(d2)),
        ("1 composite call, formula", c), ("2 dollar-world integral", c_usd),
        ("3 euro-world integral", c_eur), ("4 put by integral", p_usd),
        ("  C - P", c - p_usd), ("  S X e^-qT - K e^-rdT", S * X0 * eq - K * disc),
        ("quanto drift rf - q - rho sS sX", RF - Q - RHO * SS * SX), ("quanto call, formula", quanto(RHO)), ("  quanto by integral", q_int),
        ("plain euro call x 1.10, formula", plain), ("  plain by integral", plain_int),
        ("delta, shares e^-qT N(d1)", eq * ncdf(d1)), ("  bump S, per EUR", ds),
        ("  X e^-qT N(d1)", X0 * eq * ncdf(d1)), ("  bump X, per 1.00 of rate", dx),
        ("  S e^-qT N(d1)", S * eq * ncdf(d1)), ("vega per unit composite vol", vega),
        ("dC/drho, bump", dr), ("  vega x sS sX / vol", vega * SS * SX / comp_vol(RHO)),
        ("dC/dsigma_S, bump", dss), ("  vega x (sS + rho sX) / vol", vega * (SS + RHO * SX) / comp_vol(RHO)),
        ("breakeven dollar value", K + c),
        ("wrong: vol sqrt(sS^2 + sX^2)", c_at(0.0)),
        ("wrong: vol sS alone", bs_call(S * X0, K, RD, Q, SS, T).0),
        ("wrong: vol sS + sX", c_at(1.0)),
        ("wrong: grows at the euro rate rf - q", bs_call(S * X0, K, RD, Q + RD - RF, comp_vol(RHO), T).0),
    ];
    for (name, v) in &rows { println!("{:<36} {:>12.6}", name, v); }
    println!("scenario  share  USD per EUR  dollar value  quanto  composite  plain");
    for (sh, x) in [(120.0_f64, 1.30_f64), (120.0, 0.90), (95.0, 1.30), (110.0, 1.10)] {
        println!("scenario {:6.0} {:12.2} {:13.2} {:8.2} {:10.2} {:6.2}", sh, x, sh * x,
                 X0 * (sh - KE).max(0.0), (sh * x - K).max(0.0), x * (sh - KE).max(0.0));
    }
    let rhos: Vec<f64> = (0..9).map(|i| -1.0 + 0.25 * i as f64).collect();
    let line = |f: &dyn Fn(f64) -> String| rhos.iter().map(|r| f(*r)).collect::<Vec<_>>().join(" ");
    println!("chart, rho      {}", line(&|r| format!("{:6.2}", r)));
    println!("chart, composite{}", line(&|r| format!("{:6.2}", c_at(r))));
    println!("chart, quanto   {}", line(&|r| format!("{:6.2}", quanto(r))));
    println!("chart, plain    {}", line(&|_| format!("{:6.2}", plain)));
    println!("chart, comp vol {}", line(&|r| format!("{:6.3}", comp_vol(r))));
    let vs: Vec<f64> = (0..7).map(|i| 90.0 + 10.0 * i as f64).collect();
    println!("payoff, value   {}", vs.iter().map(|v| format!("{:6.0}", v)).collect::<Vec<_>>().join(" "));
    println!("payoff, profit  {}", vs.iter().map(|v| format!("{:6.2}", (v - K).max(0.0) - c)).collect::<Vec<_>>().join(" "));

    assert!((c_usd - c).abs() < 1e-5, "dollar-world integral must land on the formula");
    assert!((c_eur - c).abs() < 1e-5, "euro-world integral, no drift adjustment, must agree");
    assert!(((c - p_usd) - (S * X0 * eq - K * disc)).abs() < 1e-5, "parity");
    assert!((vol_int - comp_vol(RHO)).abs() < 1e-6, "spread of log(S X) is the composite vol");
    assert!((q_int - 9.151629).abs() < 1e-5, "quanto integral matches the sibling card's price");
    assert!((plain_int - plain).abs() < 1e-5, "plain call converted at expiry: integral vs formula");
    assert!((dr - vega * SS * SX / comp_vol(RHO)).abs() < 1e-4, "correlation sensitivity");
    println!("ALL CHECKS PASS");
}
