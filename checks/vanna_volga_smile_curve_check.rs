// The vanna-volga smile -- the same check as vanna_volga_smile_curve_check.py, in Rust.
// Standard library only, no crates.  Rust has no erf, so N(x) is built by adding thin
// slices under the bell curve (Simpson); roots are found by halving.
use std::f64::consts::PI;

const S: f64 = 1.10;
const RD: f64 = 0.05;
const RF: f64 = 0.03;

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }
fn n_cdf(x: f64) -> f64 {
    if x < -12.0 { return 0.0; }
    if x > 12.0 { return 1.0; }
    let n = 2000; let h = x / n as f64;
    let mut s = phi(0.0) + phi(x);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * phi(i as f64 * h); }
    0.5 + s * h / 3.0
}
fn halve<F: Fn(f64) -> f64>(f: F, mut lo: f64, mut hi: f64) -> f64 {
    for _ in 0..200 { let mid = 0.5 * (lo + hi); if f(mid) < 0.0 { lo = mid; } else { hi = mid; } }
    0.5 * (lo + hi)
}
#[derive(Clone, Copy)]
struct Mkt { f: f64, t: f64, ks: [f64; 3], vs: [f64; 3] }
fn market(t: f64, atm: f64, rr: f64, bf: f64) -> Mkt {
    let f = S * ((RD - RF) * t).exp();
    let vs = [atm + bf - rr / 2.0, atm, atm + bf + rr / 2.0];
    let a = halve(|d| (-RF * t).exp() * n_cdf(d) - 0.25, -8.0, 8.0);   // spot delta 0.25 -> call's d1
    let ks = [f * (a * vs[0] * t.sqrt() + vs[0] * vs[0] * t / 2.0).exp(), f * (vs[1] * vs[1] * t / 2.0).exp(),
              f * (-a * vs[2] * t.sqrt() + vs[2] * vs[2] * t / 2.0).exp()];
    Mkt { f, t, ks, vs }
}
fn d12(m: &Mkt, k: f64, v: f64) -> (f64, f64) {
    let d1 = ((m.f / k).ln() + 0.5 * v * v * m.t) / (v * m.t.sqrt()); (d1, d1 - v * m.t.sqrt())
}
fn call(m: &Mkt, k: f64, v: f64) -> f64 {
    let (d1, d2) = d12(m, k, v); S * (-RF * m.t).exp() * n_cdf(d1) - k * (-RD * m.t).exp() * n_cdf(d2)
}
fn vega(m: &Mkt, k: f64, v: f64) -> f64 { S * (-RF * m.t).exp() * phi(d12(m, k, v).0) * m.t.sqrt() }
fn vanna(m: &Mkt, k: f64, v: f64) -> f64 { let (d1, d2) = d12(m, k, v); -(-RF * m.t).exp() * phi(d1) * d2 / v }
fn volga(m: &Mkt, k: f64, v: f64) -> f64 { let (d1, d2) = d12(m, k, v); vega(m, k, v) * d1 * d2 / v }
fn ys(m: &Mkt, x: f64) -> [f64; 3] {
    let [k1, k2, k3] = m.ks;
    [(k2 / x).ln() * (k3 / x).ln() / ((k2 / k1).ln() * (k3 / k1).ln()),
     (x / k1).ln() * (k3 / x).ln() / ((k2 / k1).ln() * (k3 / k2).ln()),
     (x / k1).ln() * (x / k2).ln() / ((k3 / k1).ln() * (k3 / k2).ln())]
}
fn first(m: &Mkt, x: f64) -> f64 { let y = ys(m, x); y[0] * m.vs[0] + y[1] * m.vs[1] + y[2] * m.vs[2] }
fn dd(m: &Mkt, k: f64, v: f64) -> f64 { let (a, b) = d12(m, k, v); a * b }
fn d2_term(m: &Mkt, x: f64) -> f64 {
    let (y, s2) = (ys(m, x), m.vs[1]);
    [0usize, 2].iter().map(|&i| y[i] * dd(m, m.ks[i], s2) * (m.vs[i] - s2).powi(2)).sum()
}
// Road 1: Castagna-Mercurio second order -> (vol, or None past the end; the discriminant)
fn second(m: &Mkt, x: f64, keep_d2: bool) -> (Option<f64>, f64) {
    let s2 = m.vs[1];
    let d1 = first(m, x) - s2;
    let d2 = if keep_d2 { d2_term(m, x) } else { 0.0 };
    let ab = dd(m, x, s2);
    if ab.abs() < 1e-9 { return (Some(s2 + d1 + d2 / (2.0 * s2)), 1.0); }   // the 0/0 point: the limit
    let disc = s2 * s2 + ab * (2.0 * s2 * d1 + d2);
    (if disc >= 0.0 { Some(s2 + (-s2 + disc.sqrt()) / ab) } else { None }, disc)
}
fn sv(m: &Mkt, x: f64) -> f64 { second(m, x, true).0.unwrap() }
fn det3(a: &[[f64; 3]; 3]) -> f64 {
    a[0][0] * (a[1][1] * a[2][2] - a[1][2] * a[2][1]) - a[0][1] * (a[1][0] * a[2][2] - a[1][2] * a[2][0])
        + a[0][2] * (a[1][0] * a[2][1] - a[1][1] * a[2][0])
}
// Road 2: the full vanna-volga price, weights from a 3x3 solve (Cramer's rule)
fn vv_price(m: &Mkt, x: f64) -> (f64, [f64; 3]) {
    let s2 = m.vs[1];
    let gs: [fn(&Mkt, f64, f64) -> f64; 3] = [vega, vanna, volga];
    let mut a = [[0.0; 3]; 3]; let mut b = [0.0; 3];
    for r in 0..3 { for c in 0..3 { a[r][c] = gs[r](m, m.ks[c], s2); } b[r] = gs[r](m, x, s2); }
    let mut w = [0.0; 3];
    for c in 0..3 { let mut ac = a; for r in 0..3 { ac[r][c] = b[r]; } w[c] = det3(&ac) / det3(&a); }
    let p = call(m, x, s2) + (0..3).map(|i| w[i] * (call(m, m.ks[i], m.vs[i]) - call(m, m.ks[i], s2))).sum::<f64>();
    (p, w)
}
fn implied(m: &Mkt, x: f64, p: f64) -> f64 { halve(|v| call(m, x, v) - p, 1e-4, 1.0) }
fn density(m: &Mkt, x: f64) -> f64 {           // e^{rd T} d2C/dK2 along the curve
    let h = 1e-3; let c = |k: f64| call(m, k, sv(m, k));
    (RD * m.t).exp() * (c(x - h) - 2.0 * c(x) + c(x + h)) / (h * h)
}
fn row(name: &str, v: &[f64]) {
    let mut s = format!("{:<38}", name);
    for u in v { s.push_str(&format!(" {:>12.6}", u)); }
    println!("{}", s);
}
fn line(name: &str, v: &[f64]) {
    let mut s = format!("{:<27}", name);
    for u in v { s.push_str(&format!("{:6.2}", u)); }
    println!("{}", s);
}

fn main() {
    let h = market(1.0, 0.10, -0.01, 0.0025);
    let (ks, vs, s2) = (h.ks, h.vs, h.vs[1]);
    row("forward F", &[h.f]);
    for (i, lab) in ["25d put", "ATM", "25d call"].iter().enumerate() {
        row(&format!("pillar {}: strike, vol read back", lab), &[ks[i], sv(&h, ks[i])]);
    }
    let x = 1.15; let y = ys(&h, x);
    row("ln(K2/K1), ln(K3/K2), ln(K3/K1)", &[(ks[1] / ks[0]).ln(), (ks[2] / ks[1]).ln(), (ks[2] / ks[0]).ln()]);
    row("K=1.15  ln(K/K1), ln(K/K2), ln(K/K3)", &[(x / ks[0]).ln(), (x / ks[1]).ln(), (x / ks[2]).ln()]);
    for i in 0..3 { row(&format!("K=1.15  weight y{}", i + 1), &[y[i]]); }
    row("K=1.15  first order  sum y_i sigma_i", &[first(&h, x)]);
    row("K=1.15  D1", &[first(&h, x) - s2]);
    row("d1 d2 at K1 and at K3, ATM vol", &[dd(&h, ks[0], s2), dd(&h, ks[2], s2)]);
    row("K=1.15  D2, in millionths", &[1e6 * d2_term(&h, x)]);
    row("K=1.15  d1 d2 at the ATM vol", &[dd(&h, x, s2)]);
    let disc = second(&h, x, true).1;
    row("K=1.15  discriminant, its square root", &[disc, disc.sqrt()]);
    row("K=1.15  1 second order", &[sv(&h, x)]);
    let (p115, w) = vv_price(&h, x);
    row("K=1.15  2 full VV price", &[p115]); row("K=1.15  2 full VV, implied vol", &[implied(&h, x, p115)]);
    let cm: Vec<f64> = (0..3).map(|i| vega(&h, x, s2) / vega(&h, ks[i], s2) * y[i]).collect();
    for i in 0..3 {
        row(&format!("K=1.15  weight x{}: 3x3 solve", i + 1), &[w[i]]);
        row(&format!("K=1.15  weight x{}: nu(K)/nu(K{}) y{}", i + 1, i + 1, i + 1), &[cm[i]]);
    }
    let x = 1.40; let p140 = vv_price(&h, x).0;
    row("K=1.40  first order", &[first(&h, x)]); row("K=1.40  1 second order", &[sv(&h, x)]);
    row("K=1.40  2 full VV, implied vol", &[implied(&h, x, p140)]);
    row("K=1.40  call on the VV curve", &[call(&h, x, sv(&h, x))]); row("K=1.40  call, flat 9.75% past K3", &[call(&h, x, vs[2])]);
    let kmin = halve(|k| sv(&h, k + 1e-6) - sv(&h, k - 1e-6), 1.13, 1.35);
    row("curve's lowest point, strike", &[kmin]); row("curve's lowest point, vol", &[sv(&h, kmin)]);
    row("K=0.80  first order", &[first(&h, 0.80)]); row("K=0.80  second order", &[sv(&h, 0.80)]);
    let wrong = Mkt { ks: market(1.0, 0.10, 0.0, 0.0).ks, ..h };
    row("wrong: pillars all at 10%, K=1.15", &[sv(&wrong, 1.15)]);
    row("wrong: drop D2, K=1.40", &[second(&h, 1.40, false).0.unwrap()]);
    let dmin = (0..81).map(|i| density(&h, 0.80 + 0.01 * i as f64)).fold(f64::INFINITY, f64::min);
    row("house density, lowest on 0.80..1.60", &[dmin]);
    let st = market(1.0, 0.10, -0.03, 0.0025);                    // a steep skew: risk reversal -3%
    let kb = halve(|k| -second(&st, k, true).1, 1.21, 1.40);
    row("steep skew: vols K1, K3; strike K3", &[st.vs[0], st.vs[2], st.ks[2]]); row("steep skew: vol at K=1.25", &[sv(&st, 1.25)]);
    row("steep skew: density at K=1.25", &[density(&st, 1.25)]);
    row("steep skew: vol at end - 0.002", &[sv(&st, kb - 0.002)]); row("steep skew: density at end - 0.002", &[density(&st, kb - 0.002)]);
    row("steep skew: curve ends at strike", &[kb]);
    let m6 = market(0.5, 0.12, -0.01, 0.01);                     // a 6-month market: ATM 12%, RR -1%, BF +1%
    let tv = |m: &Mkt, k: f64| sv(m, m.f * k.exp()).powi(2) * m.t * 100.0;
    for k in [0.0, 0.3] {
        row(&format!("total var x100, k={:.1}: 1y", k), &[tv(&h, k)]);
        row(&format!("total var x100, k={:.1}: 6m", k), &[tv(&m6, k)]);
    }
    let grid: Vec<f64> = (0..11).map(|i| 0.95 + 0.05 * i as f64).collect();
    line("chart, strike", &grid);
    line("chart, VV curve %", &grid.iter().map(|&k| 100.0 * sv(&h, k)).collect::<Vec<_>>());
    line("chart, first order %", &grid.iter().map(|&k| 100.0 * first(&h, k)).collect::<Vec<_>>());
    line("chart, flat past pillars %", &grid.iter().map(|&k| 100.0 * if k < ks[0] { vs[0] } else if k > ks[2] { vs[2] } else { sv(&h, k) }).collect::<Vec<_>>());
    let kg: Vec<f64> = (0..8).map(|i| -0.3 + 0.1 * i as f64).collect();
    line("chart, k", &kg);
    line("chart, 1y total var x100", &kg.iter().map(|&k| tv(&h, k)).collect::<Vec<_>>());
    line("chart, 6m total var x100", &kg.iter().map(|&k| tv(&m6, k)).collect::<Vec<_>>());

    assert!(ks.iter().zip([1.052466, 1.127847, 1.201425]).all(|(k, k0)| (k - k0).abs() < 5e-7), "house pillar strikes");
    assert!((0..3).all(|i| (sv(&h, ks[i]) - vs[i]).abs() < 1e-12), "the curve passes through its three quotes");
    assert!((sv(&h, 1.15) - implied(&h, 1.15, p115)).abs() < 1e-6, "road 1 (closed form) meets road 2 (full VV price)");
    assert!((0..3).all(|i| (w[i] - cm[i]).abs() < 1e-9), "3x3 weights equal the closed-form weights");
    assert!(sv(&h, 1.15) > 0.0975 && sv(&h, 1.15) < 0.10, "1.15 lands between the ATM and 25d call vols");
    assert!(sv(&h, 1.40) > vs[1] && call(&h, 1.40, sv(&h, 1.40)) > 1.5 * call(&h, 1.40, vs[2]), "the wing turns up");
    assert!(dmin > 0.0, "the house curve passes the butterfly test");
    assert!(density(&st, kb - 0.002) < 0.0 && second(&st, kb + 0.001, true).0.is_none(), "steep skew: negative density, then no vol");
    assert!(tv(&m6, 0.0) < tv(&h, 0.0), "at the money the 6m total variance sits below the 1y");
    assert!(tv(&m6, 0.3) > tv(&h, 0.3), "in the wing it crosses above: calendar arbitrage");
    println!("ALL CHECKS PASS");
}
