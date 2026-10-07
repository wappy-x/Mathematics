// Portfolio Greeks and a day's explained P&L -- the same check in Rust, std only, no crates.
// Rust has no erf: N(x) is Simpson's rule on the bell-curve height, not the Python series.
// Compile: rustc --edition 2021 -O portfolio_greeks_and_taylor_pnl_check.rs
use std::f64::consts::PI;

const R: f64 = 0.05;
const Q: f64 = 0.02;
const S0: f64 = 100.0;
const SIG0: f64 = 0.20;

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }

fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    s * h / 3.0
}

fn ncdf(x: f64) -> f64 {
    if x.abs() > 9.0 { return if x < 0.0 { 0.0 } else { 1.0 }; }
    0.5 + simpson(phi, 0.0, x, 2000)
}

fn d1d2(s: f64, k: f64, sg: f64, t: f64) -> (f64, f64) {
    let d1 = ((s / k).ln() + (R - Q + 0.5 * sg * sg) * t) / (sg * t.sqrt());
    (d1, d1 - sg * t.sqrt())
}

fn option(s: f64, k: f64, sg: f64, t: f64, cp: f64) -> f64 {
    let (d1, d2) = d1d2(s, k, sg, t);
    cp * (s * (-Q * t).exp() * ncdf(cp * d1) - k * (-R * t).exp() * ncdf(cp * d2))
}

fn option_integral(s: f64, k: f64, sg: f64, t: f64, cp: f64) -> f64 {
    let (m, v) = ((R - Q - 0.5 * sg * sg) * t, sg * t.sqrt());
    let zk = ((k / s).ln() - m) / v;
    let (lo, hi) = if cp > 0.0 { (zk, 10.0) } else { (-10.0, zk) };
    (-R * t).exp() * simpson(|z| cp * (s * (m + v * z).exp() - k) * phi(z), lo, hi, 4000)
}

fn unit_greeks(k: f64, sg: f64, t: f64, cp: f64, s: f64) -> [f64; 6] {
    if cp == 0.0 {
        let f = s * ((R - Q) * t).exp();
        return [f / s, 0.0, 0.0, -(R - Q) * f, 0.0, 0.0];
    }
    let (d1, d2) = d1d2(s, k, sg, t);
    let (eq, er, rt) = ((-Q * t).exp(), (-R * t).exp(), t.sqrt());
    let vega = s * eq * phi(d1) * rt;
    let theta = -s * eq * phi(d1) * sg / (2.0 * rt) - cp * R * k * er * ncdf(cp * d2) + cp * Q * s * eq * ncdf(cp * d1);
    [cp * eq * ncdf(cp * d1), eq * phi(d1) / (s * sg * rt), vega, theta, -eq * phi(d1) * d2 / sg, vega * d1 * d2 / sg]
}

// label, signed quantity (shares' worth), strike, years left, +1 call / -1 put / 0 future
const BOOK: [(&str, f64, f64, f64, f64); 4] = [
    ("A long call K100 1y", 75000.0, 100.0, 1.0, 1.0), ("B short put K90 3m", -130000.0, 90.0, 0.25, -1.0),
    ("C long call K110 6m", 50000.0, 110.0, 0.5, 1.0), ("D short future 3m", -74200.0, 0.0, 0.25, 0.0)];

fn f0() -> f64 { S0 * ((R - Q) * 0.25).exp() }

fn mark(p: &(&str, f64, f64, f64, f64), s: f64, sg: f64, t: f64, integral: bool) -> f64 {
    let (_, n, k, tt, cp) = *p;
    if cp == 0.0 { return n * (s * ((R - Q) * (tt - t)).exp() - f0()); }
    n * if integral { option_integral(s, k, sg, tt - t, cp) } else { option(s, k, sg, tt - t, cp) }
}

fn book(s: f64, sg: f64, t: f64, integral: bool) -> f64 { BOOK.iter().map(|p| mark(p, s, sg, t, integral)).sum() }

fn book_greeks(s: f64, sg: f64, t: f64) -> [f64; 6] {
    let mut g = [0.0; 6];
    for p in BOOK.iter() { let u = unit_greeks(p.2, sg, p.3 - t, p.4, s); for i in 0..6 { g[i] += p.1 * u[i]; } }
    g
}

fn bumped() -> [f64; 6] {
    let f = |s: f64, v: f64, t: f64| book(s, v, t, false);
    let (hs, hv, ht, hw) = (0.01, 1e-4, 1e-5, 1e-3);  // hw: five-point volga, steadier to round-off
    [(f(S0 + hs, SIG0, 0.0) - f(S0 - hs, SIG0, 0.0)) / (2.0 * hs),
     (f(S0 + hs, SIG0, 0.0) - 2.0 * f(S0, SIG0, 0.0) + f(S0 - hs, SIG0, 0.0)) / (hs * hs),
     (f(S0, SIG0 + hv, 0.0) - f(S0, SIG0 - hv, 0.0)) / (2.0 * hv),
     (f(S0, SIG0, ht) - f(S0, SIG0, -ht)) / (2.0 * ht),
     (f(S0 + hs, SIG0 + hv, 0.0) - f(S0 + hs, SIG0 - hv, 0.0) - f(S0 - hs, SIG0 + hv, 0.0)
        + f(S0 - hs, SIG0 - hv, 0.0)) / (4.0 * hs * hv),
     (-f(S0, SIG0 + 2.0 * hw, 0.0) + 16.0 * f(S0, SIG0 + hw, 0.0) - 30.0 * f(S0, SIG0, 0.0)
        + 16.0 * f(S0, SIG0 - hw, 0.0) - f(S0, SIG0 - 2.0 * hw, 0.0)) / (12.0 * hw * hw)]
}

fn terms(g: &[f64; 6], ds: f64, dv: f64, dt: f64) -> [f64; 6] {
    [g[0] * ds, 0.5 * g[1] * ds * ds, g[2] * dv, g[3] * dt, g[4] * ds * dv, 0.5 * g[5] * dv * dv]
}
fn sum(a: &[f64; 6]) -> f64 { a.iter().sum() }
fn row(lab: &str, v: &[f64]) -> String { format!("{:<20}", lab) + &v.iter().map(|x| format!("{:>12.2}", x)).collect::<String>() }

fn main() {
    let unit: Vec<[f64; 6]> = BOOK.iter().map(|p| unit_greeks(p.2, SIG0, p.3, p.4, S0)).collect();
    let posg: Vec<[f64; 6]> = BOOK.iter().zip(&unit).map(|(p, u)| u.map(|x| p.1 * x + 0.0)).collect();
    let (closed, bump) = (book_greeks(S0, SIG0, 0.0), bumped());
    println!("position             quantity  unit price     delta     gamma      vega     theta     vanna     volga");
    for (p, u) in BOOK.iter().zip(&unit) {
        let price = if p.4 == 0.0 { f0() } else { option(S0, p.2, SIG0, p.3, p.4) };
        println!("{:<20}{:>9}{:>12.6}{}", p.0, p.1, price, u.iter().map(|x| format!("{:>10.6}", x)).collect::<String>());
    }
    println!("position Greeks, quantity x unit");
    for (p, g) in BOOK.iter().zip(&posg) { println!("{}", row(p.0, g)); }
    println!("{}\n{}", row("book, summed", &closed), row("book, by bumping", &bump));
    let d3: f64 = posg[..3].iter().map(|g| g[0]).sum();
    println!("vega per vol point; delta before future {:.2}  {:.2}", closed[2] / 100.0, d3);

    let (ds, dv, dt) = (5.0, 0.01, 1.0 / 365.0);
    let (tc, tb) = (terms(&closed, ds, dv, dt), terms(&bump, ds, dv, dt));
    println!("the day: Acme +5, vol +1 point, one day: term by summed Greeks, by bumped Greeks");
    for (i, nm) in ["delta", "gamma", "vega", "theta", "vanna", "volga"].iter().enumerate() {
        println!("  {:<10}{:>14.2}{:>14.2}", nm, tc[i], tb[i]);
    }
    let (explained, explained_b) = (sum(&tc), sum(&tb));
    let actual = book(S0 + ds, SIG0 + dv, dt, false) - book(S0, SIG0, 0.0, false);
    let actual_i = book(S0 + ds, SIG0 + dv, dt, true) - book(S0, SIG0, 0.0, true);
    println!("explained: summed, bumped               {:.2}  {:.2}", explained, explained_b);
    println!("actual: reprice by formula, by integral {:.2}  {:.2}", actual, actual_i);
    println!("unexplained; explained share of actual  {:.2}  {:.4}", actual - explained, explained / actual);
    println!("by position: unexplained, explained, actual");
    for (p, g) in BOOK.iter().zip(&posg) {
        let (e, a) = (sum(&terms(g, ds, dv, dt)), mark(p, S0 + ds, SIG0 + dv, dt, false) - mark(p, S0, SIG0, 0.0, false));
        println!("  {:<20}{:>12.2}{:>12.2}{:>12.2}", p.0, a - e, e, a);
    }
    let steps = 20;
    let mut walked = 0.0;
    for j in 0..steps {
        let k = j as f64 / steps as f64;
        let n = steps as f64;
        walked += sum(&terms(&book_greeks(S0 + k * ds, SIG0 + k * dv, k * dt), ds / n, dv / n, dt / n));
    }
    let g = |k: f64| book(S0 + k * ds, SIG0 + k * dv, k * dt, false);
    let hk: f64 = 0.05;
    let g3 = (g(2.0 * hk) - 2.0 * g(hk) + 2.0 * g(-hk) - g(-2.0 * hk)) / (2.0 * hk.powi(3));
    let g4 = (g(2.0 * hk) - 4.0 * g(hk) + 6.0 * g(0.0) - 4.0 * g(-hk) + g(-2.0 * hk)) / hk.powi(4);
    let res_half = (g(0.5) - g(0.0)) - sum(&terms(&closed, ds / 2.0, dv / 2.0, dt / 2.0));
    println!("walked in 20 re-Greeked steps           {:.2}", walked);
    println!("third-order, fourth-order pieces        {:.2}  {:.2}", g3 / 6.0, g4 / 24.0);
    println!("unexplained at half the move; ratio     {:.2}  {:.4}", res_half, (actual - explained) / res_half);
    println!("wrong: future's delta taken as 1        {:.2}", explained + BOOK[3].1 * (1.0 - unit[3][0]) * ds);
    println!("wrong: short put entered as long        {:.2}", explained - 2.0 * sum(&terms(&posg[1], ds, dv, dt)));
    println!("wrong: contracts, not shares            {:.2}", explained / 100.0);
    println!("wrong: delta term only                  {:.2}", tc[0]);
    for (lab, a, b) in [("try: Acme -5, vol +1", -5.0, 0.01), ("try: Acme +5, vol 0", 5.0, 0.0), ("try: Acme +2, vol +1", 2.0, 0.01)] {
        let act = book(S0 + a, SIG0 + b, dt, false) - book(S0, SIG0, 0.0, false);
        println!("{:<24}explained {:>10.2}  actual {:>10.2}", lab, sum(&terms(&closed, a, b, dt)), act);
    }
    let moves = [-10.0, -7.5, -5.0, -2.5, 0.0, 2.5, 5.0, 7.5, 10.0];
    let labels = ["-10", "-7.5", "-5", "-2.5", "0", "2.5", "5", "7.5", "10"];
    println!("chart, Acme move ($){}   ($ thousands)", labels.iter().map(|m| format!("{:>7}", m)).collect::<String>());
    let lines: [(&str, Box<dyn Fn(f64) -> f64>); 3] = [
        ("actual", Box::new(|m| book(S0 + m, SIG0 + dv, dt, false) - book(S0, SIG0, 0.0, false))),
        ("explained", Box::new(|m| sum(&terms(&closed, m, dv, dt)))), ("delta only", Box::new(|m| closed[0] * m))];
    for (lab, f) in lines.iter() {
        println!("chart, {:<13}{}", lab, moves.iter().map(|&m| format!("{:>7.2}", f(m) / 1000.0)).collect::<String>());
    }

    for i in 0..6 {
        let scale: f64 = posg.iter().map(|g| g[i].abs()).sum();
        assert!((closed[i] - bump[i]).abs() <= 1e-6 * scale, "summed Greeks != bumped book");
    }
    assert!((explained - explained_b).abs() < 1.0, "explained P&L differs between Greek roads");
    assert!((actual - actual_i).abs() < 0.05, "full reprice differs between price roads");
    assert!((walked - actual_i).abs() < 0.005 * actual_i.abs(), "re-Greeked walk does not reach the actual P&L");
    let ratio = (actual - explained) / res_half;
    assert!(ratio > 6.0 && ratio < 10.0, "leftover does not shrink like the cube");
    assert!((option(S0, 100.0, SIG0, 1.0, 1.0) - 9.227005508154).abs() < 1e-9 && (option(S0, 100.0, SIG0, 1.0, -1.0) - 6.330080627550).abs() < 1e-9, "house prices");
    println!("ALL CHECKS PASS");
}
