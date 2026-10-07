// Vanna-volga pricing -- the same check as vanna_volga_pricing_check.py, in Rust.  std only.
// House FX market: EURUSD spot 1.10, USD rate 5%, EUR rate 3%, one year; ATM 10%,
// 25-delta risk reversal -1%, 25-delta butterfly +0.25%.  Target: EUR call at 1.15.
// Different roads from the Python: the normal CDF adds thin slices under the curve,
// the weights come from Cramer's rule, the prices of risk from Gaussian elimination.
use std::f64::consts::PI;
const S: f64 = 1.10; const RD: f64 = 0.05; const RF: f64 = 0.03; const T: f64 = 1.0;
const ATM: f64 = 0.10; const RR: f64 = -0.01; const BF: f64 = 0.0025; const KT: f64 = 1.15;
type M3 = [[f64; 3]; 3];

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }
fn simpson<G: Fn(f64) -> f64>(f: G, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    s * h / 3.0
}
fn ncdf(x: f64) -> f64 { if x.abs() > 8.0 { if x < 0.0 { 0.0 } else { 1.0 } } else { 0.5 + simpson(phi, 0.0, x, 2000) } }
fn bisect<G: Fn(f64) -> f64>(f: G, target: f64, mut lo: f64, mut hi: f64) -> f64 {
    for _ in 0..200 { let m = 0.5 * (lo + hi); if f(m) < target { lo = m } else { hi = m } }
    0.5 * (lo + hi)
}
fn fwd() -> f64 { S * ((RD - RF) * T).exp() }
fn d12(k: f64, v: f64, s: f64) -> (f64, f64) {
    let d1 = ((s / k).ln() + (RD - RF + 0.5 * v * v) * T) / (v * T.sqrt()); (d1, d1 - v * T.sqrt())
}
fn call_s(k: f64, v: f64, s: f64) -> f64 { let (d1, d2) = d12(k, v, s); s * (-RF * T).exp() * ncdf(d1) - k * (-RD * T).exp() * ncdf(d2) }
fn call(k: f64, v: f64) -> f64 { call_s(k, v, S) }
fn vega(k: f64, v: f64) -> f64 { let (d1, _) = d12(k, v, S); S * (-RF * T).exp() * phi(d1) * T.sqrt() }
fn vanna(k: f64, v: f64) -> f64 { let (d1, d2) = d12(k, v, S); -(-RF * T).exp() * phi(d1) * d2 / v }
fn volga(k: f64, v: f64) -> f64 { let (d1, d2) = d12(k, v, S); vega(k, v) * d1 * d2 / v }
fn greeks(k: f64) -> [f64; 3] { [vega(k, ATM), vanna(k, ATM), volga(k, ATM)] }
fn pillars(atm: f64, rr: f64, bf: f64) -> ([f64; 3], [f64; 3]) {
    let v = [atm + bf - rr / 2.0, atm, atm + bf + rr / 2.0];
    let d1 = bisect(ncdf, 0.25 * (RF * T).exp(), -10.0, 10.0);
    let f = fwd();
    ([f * (d1 * v[0] * T.sqrt() + 0.5 * v[0] * v[0] * T).exp(), f * (0.5 * atm * atm * T).exp(),
      f * (-d1 * v[2] * T.sqrt() + 0.5 * v[2] * v[2] * T).exp()], v)
}
fn det3(m: &M3) -> f64 {
    m[0][0] * (m[1][1] * m[2][2] - m[1][2] * m[2][1]) - m[0][1] * (m[1][0] * m[2][2] - m[1][2] * m[2][0])
        + m[0][2] * (m[1][0] * m[2][1] - m[1][1] * m[2][0])
}
fn cramer(a: &M3, b: &[f64; 3]) -> [f64; 3] {
    let mut x = [0.0; 3];
    for c in 0..3 { let mut m = *a; for r in 0..3 { m[r][c] = b[r]; } x[c] = det3(&m) / det3(a); }
    x
}
fn gauss(a: &M3, b: &[f64; 3]) -> [f64; 3] {
    let mut m = [[0.0; 4]; 3];
    for i in 0..3 { for j in 0..3 { m[i][j] = a[i][j]; } m[i][3] = b[i]; }
    for c in 0..3 {
        let p = (c..3).max_by(|&i, &j| m[i][c].abs().partial_cmp(&m[j][c].abs()).unwrap()).unwrap();
        m.swap(c, p);
        for r in c + 1..3 { let f = m[r][c] / m[c][c]; for j in 0..4 { m[r][j] -= f * m[c][j]; } }
    }
    let mut x = [0.0; 3];
    for r in (0..3).rev() { let mut s = m[r][3]; for j in r + 1..3 { s -= m[r][j] * x[j]; } x[r] = s / m[r][r]; }
    x
}
fn vv(k: f64, ks: &[f64; 3], vols: &[f64; 3], at_mkt: bool) -> (f64, [f64; 3], [f64; 3], M3) {
    let mut a = [[0.0; 3]; 3];
    for i in 0..3 { let v = if at_mkt { vols[i] } else { ATM };
        a[0][i] = vega(ks[i], v); a[1][i] = vanna(ks[i], v); a[2][i] = volga(ks[i], v); }
    let x = cramer(&a, &greeks(k));
    let gaps = [0, 1, 2].map(|i| call(ks[i], vols[i]) - call(ks[i], ATM));
    (call(k, ATM) + (0..3).map(|i| x[i] * gaps[i]).sum::<f64>(), x, gaps, a)
}
fn lagrange(k: f64, ks: &[f64; 3]) -> [f64; 3] {
    let (z, l) = (k.ln(), ks.map(|q| q.ln()));
    [(0, 1, 2), (1, 0, 2), (2, 0, 1)].map(|(i, j, m)| (z - l[j]) * (z - l[m]) / ((l[i] - l[j]) * (l[i] - l[m])))
}
fn first_order(k: f64, ks: &[f64; 3], v: &[f64; 3]) -> f64 { let w = lagrange(k, ks); (0..3).map(|i| w[i] * v[i]).sum() }
fn iv(p: f64, k: f64) -> f64 { bisect(|v| call(k, v), p, 0.001, 1.0) }
fn pp(v: f64) -> String { format!("{:.2}", v * 1e4) }
fn usd(v: f64) -> String {
    let s = format!("{:.2}", v); let (int, dec) = s.split_at(s.len() - 3);
    let mut out = String::new();
    for (i, ch) in int.chars().enumerate() { if i > 0 && (int.len() - i) % 3 == 0 { out.push(','); } out.push(ch); }
    out + dec
}
fn row<G: Fn(f64) -> String>(v: &[f64], f: G) -> String { v.iter().map(|&q| f(q)).collect::<Vec<_>>().join(" ") }

fn main() {
    let (ks, vols) = pillars(ATM, RR, BF);
    let (price, x, gaps, a) = vv(KT, &ks, &vols, false);
    let (flat, g) = (call(KT, ATM), greeks(KT));
    let lw = lagrange(KT, &ks);
    let x_cf = [0, 1, 2].map(|i| vega(KT, ATM) / vega(ks[i], ATM) * lw[i]);
    let mut at = [[0.0; 3]; 3];
    for r in 0..3 { for c in 0..3 { at[c][r] = a[r][c]; } }
    let y = gauss(&at, &gaps);
    let charges = [0, 1, 2].map(|i| g[i] * y[i]);
    let z0 = ((KT / S).ln() - (RD - RF - 0.5 * ATM * ATM) * T) / (ATM * T.sqrt());
    let flat_int = (-RD * T).exp() * simpson(|z| (S * ((RD - RF - 0.5 * ATM * ATM) * T + ATM * T.sqrt() * z).exp() - KT) * phi(z), z0, 10.0, 4000);
    let h = 1e-4;
    let bump = [(call(KT, ATM + h) - call(KT, ATM - h)) / (2.0 * h),
        (call_s(KT, ATM + h, S + h) - call_s(KT, ATM - h, S + h) - call_s(KT, ATM + h, S - h) + call_s(KT, ATM - h, S - h)) / (4.0 * h * h),
        (call(KT, ATM + h) - 2.0 * flat + call(KT, ATM - h)) / (h * h)];
    let (iv_vv, iv_1) = (iv(price, KT), first_order(KT, &ks, &vols));
    let back = ks.map(|k| vv(k, &ks, &vols, false).0);
    let (ks_f, vols_f) = pillars(ATM, -RR, BF);

    println!("forward F {:.6}   det A {:.6}", fwd(), det3(&a));
    for (i, nm) in ["25d put ", "ATM     ", "25d call"].iter().enumerate() {
        println!("pillar {} {}  K {:.6}  vol {:.2}%  mkt {}  flat {}  gap {}", i + 1, nm, ks[i], vols[i] * 100.0,
                 pp(call(ks[i], vols[i])), pp(call(ks[i], ATM)), pp(gaps[i]));
    }
    for (r, nm) in ["vega ", "vanna", "volga"].iter().enumerate() {
        println!("A {} {}   target {:10.6}  bumped {:10.6}", nm, row(&a[r], |v| format!("{:10.6}", v)), g[r], bump[r]);
    }
    println!("weights, Gaussian elimination {}", row(&x, |v| format!("{:.6}", v)));
    println!("weights, closed form          {}", row(&x_cf, |v| format!("{:.6}", v)));
    println!("x_i times gap (pips)          {}", row(&[0, 1, 2].map(|i| x[i] * gaps[i]), pp));
    println!("price of one unit, y_j        {}", row(&y, |v| format!("{:.8}", v)));
    println!("charge g_j y_j (pips)         {}", row(&charges, pp));
    println!("flat price at 10%   {} pips   by Simpson {} pips", pp(flat), pp(flat_int));
    println!("overlay, weights    {} pips   by prices of risk {} pips", pp(price - flat), pp(charges.iter().sum()));
    println!("vanna-volga price   {} pips  = USD {} on EUR 10 million (flat USD {})", pp(price), usd(price * 1e7), usd(flat * 1e7));
    println!("implied vol of it   {:.4}%   first-order smile {:.4}%   gap {:.4} bp", iv_vv * 100.0, iv_1 * 100.0, (iv_vv - iv_1) * 1e4);
    println!("pillars back, pips            {}", row(&back, pp));
    println!("wrong: smile vol + overlay     {}", pp(call(KT, iv_1) + price - flat));
    println!("wrong: ATM vega hedge only     {}", pp(flat + vega(KT, ATM) / vega(ks[1], ATM) * gaps[1]));
    println!("wrong: Greeks at pillar vols   {}   pillar 1 back {}", pp(vv(KT, &ks, &vols, true).0), pp(vv(ks[0], &ks, &vols, true).0));
    println!("wrong: risk reversal flipped   {}", pp(vv(KT, &ks_f, &vols_f, false).0));
    println!("try: K = 1.20                  {} overlay", pp(vv(1.20, &ks, &vols, false).0 - call(1.20, ATM)));
    println!("try: K = 1.50                  {} overlay on flat {}", pp(vv(1.50, &ks, &vols, false).0 - call(1.50, ATM)), pp(call(1.50, ATM)));
    let (k0, v0) = pillars(ATM, RR, 0.0);
    println!("try: butterfly 0               {} overlay", pp(vv(KT, &k0, &v0, false).0 - flat));
    let (k1, v1) = pillars(ATM, 0.0, BF);
    println!("try: risk reversal 0           {} overlay", pp(vv(KT, &k1, &v1, false).0 - flat));
    let grid: Vec<f64> = (0..13).map(|i| 1.00 + 0.025 * i as f64).collect();
    println!("chart strike {}", row(&grid, |k| format!("{:6.3}", k)));
    println!("chart overlay pips {}", row(&grid, |k| pp(vv(k, &ks, &vols, false).0 - call(k, ATM))));
    println!("chart vv vol % {}", row(&grid, |k| format!("{:.2}", iv(vv(k, &ks, &vols, false).0, k) * 100.0)));
    println!("chart 1st-order % {}", row(&grid, |k| format!("{:.2}", first_order(k, &ks, &vols) * 100.0)));

    let house = [1.052466, 1.127847, 1.201425];
    assert!((0..3).all(|i| (ks[i] - house[i]).abs() < 5e-7), "pillar strikes must match the house market");
    assert!((0..3).all(|i| (x[i] - x_cf[i]).abs() < 1e-10), "elimination and closed-form weights agree");
    assert!((0..3).all(|i| (back[i] - call(ks[i], vols[i])).abs() < 1e-12), "pillars priced back exactly");
    assert!(((price - flat) - charges.iter().sum::<f64>()).abs() < 1e-12, "weights road and prices-of-risk road agree");
    assert!((flat_int - flat).abs() < 1e-9, "Simpson flat price equals the formula");
    assert!((0..3).all(|i| (bump[i] - g[i]).abs() < 1e-5 * g[i].abs().max(1.0)), "bumped Greeks equal closed forms");
    assert!((iv_vv - iv_1).abs() < 1e-4, "implied vol within one basis point of the first-order smile");
    println!("ALL CHECKS PASS");
}
