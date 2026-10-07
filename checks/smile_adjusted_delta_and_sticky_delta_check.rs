// Hedging with the smile -- the check behind the card.  Rust std only.
// House FX market: EURUSD spot 1.10, USD rate 5%, EUR rate 3%, one year; ATM 10%,
// 25-delta risk reversal -1%, 25-delta butterfly +0.25%, pillars on spot delta.
// The smile is the vanna-volga curve.  Sticky delta: the quotes stay put when spot
// moves, so the pillars are rebuilt at the new spot.  Normal CDF from its series,
// strikes and vols by bisection, vanna-volga weights by Gaussian elimination.
const S0: f64 = 1.10; const RD: f64 = 0.05; const RF: f64 = 0.03; const T: f64 = 1.0;
const ATM: f64 = 0.10; const RR: f64 = -0.01; const BF: f64 = 0.0025; const NOTIONAL: f64 = 10_000_000.0;

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * std::f64::consts::PI).sqrt() }
fn n(x: f64) -> f64 {
    if x.abs() > 8.0 { return if x < 0.0 { 0.0 } else { 1.0 }; }
    let (mut term, mut s, mut k) = (x, x, 0.0);
    while term.abs() > 1e-17 { k += 1.0; term *= x * x / (2.0 * k + 1.0); s += term; }
    0.5 + phi(x) * s
}
fn bisect(f: &dyn Fn(f64) -> f64, target: f64, mut lo: f64, mut hi: f64) -> f64 {
    for _ in 0..200 { let mid = 0.5 * (lo + hi); if f(mid) < target { lo = mid } else { hi = mid } }
    0.5 * (lo + hi)
}
fn d1(s: f64, k: f64, v: f64) -> f64 { ((s / k).ln() + (RD - RF + 0.5 * v * v) * T) / (v * T.sqrt()) }
fn call(s: f64, k: f64, v: f64) -> f64 {
    let a = d1(s, k, v); s * (-RF * T).exp() * n(a) - k * (-RD * T).exp() * n(a - v * T.sqrt())
}
fn put(s: f64, k: f64, v: f64) -> f64 { call(s, k, v) - s * (-RF * T).exp() + k * (-RD * T).exp() }
fn delta(s: f64, k: f64, v: f64) -> f64 { (-RF * T).exp() * n(d1(s, k, v)) }
fn vega(s: f64, k: f64, v: f64) -> f64 { s * (-RF * T).exp() * phi(d1(s, k, v)) * T.sqrt() }
fn vanna(s: f64, k: f64, v: f64) -> f64 { let a = d1(s, k, v); -(-RF * T).exp() * phi(a) * (a - v * T.sqrt()) / v }
fn volga(s: f64, k: f64, v: f64) -> f64 { let a = d1(s, k, v); vega(s, k, v) * a * (a - v * T.sqrt()) / v }

fn pillars(s: f64) -> ([f64; 3], [f64; 3]) {
    let f = s * ((RD - RF) * T).exp();
    let vols = [ATM + BF - RR / 2.0, ATM, ATM + BF + RR / 2.0];
    let x = bisect(&n, 0.25 * (RF * T).exp(), -10.0, 10.0);
    let ks = [f * (x * vols[0] * T.sqrt() + 0.5 * vols[0] * vols[0] * T).exp(), f * (0.5 * ATM * ATM * T).exp(),
              f * (-x * vols[2] * T.sqrt() + 0.5 * vols[2] * vols[2] * T).exp()];
    (ks, vols)
}
fn gauss(a: [[f64; 3]; 3], b: [f64; 3]) -> [f64; 3] {
    let mut m = [[0.0; 4]; 3];
    for i in 0..3 { for j in 0..3 { m[i][j] = a[i][j]; } m[i][3] = b[i]; }
    for c in 0..3 {
        let mut p = c;
        for r in c..3 { if m[r][c].abs() > m[p][c].abs() { p = r; } }
        m.swap(c, p);
        for r in c + 1..3 { let f = m[r][c] / m[c][c]; for j in 0..4 { m[r][j] -= f * m[c][j]; } }
    }
    let mut x = [0.0; 3];
    for r in (0..3).rev() {
        let mut s = m[r][3];
        for j in r + 1..3 { s -= m[r][j] * x[j]; }
        x[r] = s / m[r][r];
    }
    x
}
fn vv(s: f64, k: f64) -> f64 {
    let (ks, vols) = pillars(s);
    let gs: [fn(f64, f64, f64) -> f64; 3] = [vega, vanna, volga];
    let mut a = [[0.0; 3]; 3]; let mut b = [0.0; 3];
    for r in 0..3 { for c in 0..3 { a[r][c] = gs[r](s, ks[c], ATM); } b[r] = gs[r](s, k, ATM); }
    let x = gauss(a, b);
    let mut p = call(s, k, ATM);
    for i in 0..3 { p += x[i] * (call(s, ks[i], vols[i]) - call(s, ks[i], ATM)); }
    p
}
fn smile(s: f64, k: f64) -> f64 { let p = vv(s, k); bisect(&|v| call(s, k, v), p, 0.001, 1.0) }
fn first_order_slope(s: f64, k: f64) -> f64 {
    let (ks, vols) = pillars(s);
    let z = k.ln(); let l = [ks[0].ln(), ks[1].ln(), ks[2].ln()];
    let idx = [(0, 1, 2), (1, 0, 2), (2, 0, 1)];
    let mut t = 0.0;
    for (m, &(i, j, q)) in idx.iter().enumerate() { t += vols[m] * (2.0 * z - l[j] - l[q]) / ((l[i] - l[j]) * (l[i] - l[q])); }
    t
}
fn comma(x: f64, dp: usize) -> String {
    let s = format!("{:.*}", dp, x.abs());
    let (int, frac) = match s.find('.') { Some(i) => (&s[..i], &s[i..]), None => (&s[..], "") };
    let mut out = String::new();
    for (i, ch) in int.chars().enumerate() { if i > 0 && (int.len() - i) % 3 == 0 { out.push(','); } out.push(ch); }
    format!("{}{}{}", if x < 0.0 { "-" } else { "" }, out, frac)
}
struct R { k: f64, sk: f64, v0: f64, v1: f64, r1: f64, r2: f64, r3: f64, bs: f64, sa: f64, rep: f64, mv: f64,
           vg: f64, dsd: f64, dss: f64, gterm: f64, vterm: f64, trap: f64, dn: f64, mvd: f64 }
fn study(k: f64, sign: f64) -> R {
    let (h, s1) = (1e-4, S0 * 1.01);
    let (v0, v1) = (smile(S0, k), smile(s1, k));
    let slope = |s: f64| (smile(s + h, k) - smile(s - h, k)) / (2.0 * h);
    let sk = (smile(S0, k + h) - smile(S0, k - h)) / (2.0 * h);
    let r1 = -(k / S0) * sk;
    let (r2, r3) = (slope(S0), -first_order_slope(S0, k) / S0);
    let bs = delta(S0, k, v0) - if sign < 0.0 { (-RF * T).exp() } else { 0.0 };
    let sa = bs + vega(S0, k, v0) * r2;
    let pr = |s: f64| vv(s, k) - if sign > 0.0 { 0.0 } else { s * (-RF * T).exp() - k * (-RD * T).exp() };
    let rep = (pr(S0 + h) - pr(S0 - h)) / (2.0 * h);
    let price: fn(f64, f64, f64) -> f64 = if sign > 0.0 { call } else { put };
    let gam = (-RF * T).exp() * phi(d1(S0, k, v0)) / (S0 * v0 * T.sqrt());
    R { k, sk, v0, v1, r1, r2, r3, bs, sa, rep, mv: s1 - S0, vg: vega(S0, k, v0), dsd: pr(s1) - pr(S0),
        dss: price(s1, k, v0) - price(S0, k, v0), gterm: 0.5 * gam * (s1 - S0).powi(2),
        vterm: vega(s1, k, v0) * (v1 - v0), trap: 0.5 * (r2 + slope(s1)) * (s1 - S0),
        dn: pr(S0 * 0.99) - pr(S0), mvd: -0.01 * S0 }
}

fn main() {
    let (ks, vols) = pillars(S0);
    let (c, p) = (study(ks[2], 1.0), study(ks[0], -1.0));
    let s1 = S0 * 1.01;
    let k1 = bisect(&|k| -delta(s1, k, smile(s1, k)), -0.25, 1.10, 1.40);
    println!("forward {:.6}   pillars {:.6} {:.6} {:.6}", S0 * ((RD - RF) * T).exp(), ks[0], ks[1], ks[2]);
    for (nm, r) in [("call", &c), ("put ", &p)] {
        println!("{} strike                 {:.6}   vol {:.4}%", nm, r.k, r.v0 * 100.0);
        println!("{} BS spot delta          {:+.6}", nm, r.bs);
        println!("{} vega, per 1.00 of vol  {:.6}", nm, r.vg);
        println!("{} dvol/dK, smile slope   {:+.6}", nm, r.sk);
        println!("{} dvol/dS, strike slope  {:+.6}", nm, r.r1);
        println!("{} dvol/dS, rebuilt smile {:+.6}", nm, r.r2);
        println!("{} dvol/dS, first order   {:+.6}", nm, r.r3);
        println!("{} vega x dvol/dS         {:+.6}", nm, r.sa - r.bs);
        println!("{} smile delta, formula   {:+.6}", nm, r.sa);
        println!("{} smile delta, reprice   {:+.6}", nm, r.rep);
        println!("{} vol after 1% move      {:.4}%   sticky strike {:.4}%", nm, r.v1 * 100.0, r.v0 * 100.0);
        println!("{} vol change, points     slope x move {:+.4}   actual {:+.4}", nm, r.r2 * r.mv * 100.0, (r.v1 - r.v0) * 100.0);
        println!("{} value change, USD      sticky delta {}   sticky strike {}", nm, comma(r.dsd * NOTIONAL, 2), comma(r.dss * NOTIONAL, 2));
        println!("{} left after hedge, USD  BS {}   smile {}", nm, comma((r.dsd - r.bs * r.mv) * NOTIONAL, 2), comma((r.dsd - r.sa * r.mv) * NOTIONAL, 2));
        println!("{} half gamma x move^2    {}   vega x vol change {}", nm, comma(r.gterm * NOTIONAL, 2), comma(r.vterm * NOTIONAL, 2));
        println!("{} 1% down, left, USD     BS {}   smile {}", nm, comma((r.dn - r.bs * r.mvd) * NOTIONAL, 2), comma((r.dn - r.sa * r.mvd) * NOTIONAL, 2));
        println!("{} hedge gap, EUR         {}   % of notional {:.2}   x move, USD {}", nm, comma((r.sa - r.bs) * NOTIONAL, 0), (r.sa - r.bs) * 100.0, comma((r.sa - r.bs) * r.mv * NOTIONAL, 2));
    }
    println!("25-delta strike at 1.111    {:.6}   vol {:.4}%   ratio {:.6}", k1, smile(s1, k1) * 100.0, k1 / ks[2]);
    println!("wrong: sign of strike slope {:+.6}", c.bs - c.vg * c.r2);
    println!("wrong: slope in vol points  {:+.6}", c.bs + c.vg * c.r2 * 100.0);
    let grid: Vec<f64> = (0..13).map(|i| 1.00 + 0.025 * i as f64).collect();
    let row = |f: &dyn Fn(f64) -> f64| grid.iter().map(|&k| format!("{:6.2}", f(k))).collect::<Vec<_>>().join(" ");
    println!("chart strike      {}", grid.iter().map(|k| format!("{:6.3}", k)).collect::<Vec<_>>().join(" "));
    println!("chart vol % 1.100 {}", row(&|k| smile(S0, k) * 100.0));
    println!("chart vol % 1.111 {}", row(&|k| smile(s1, k) * 100.0));
    println!("chart correction %{}", row(&|k| vega(S0, k, smile(S0, k)) * (smile(S0 + 1e-4, k) - smile(S0 - 1e-4, k)) / 2e-4 * 100.0));

    assert!((c.bs - 0.25).abs() < 1e-12, "call pillar sits at 25 delta");
    assert!((p.bs + 0.25).abs() < 1e-12, "put pillar sits at -25 delta");
    for r in [&c, &p] {
        assert!((r.r1 - r.r2).abs() < 1e-7, "strike slope and rebuilt smile agree");
        assert!((r.sa - r.rep).abs() < 1e-6, "formula and full reprice agree");
        assert!((r.r3 - r.r2).abs() < 0.1 * r.r2.abs(), "first-order smile within 10% of the exact slope");
        assert!((r.trap / (r.v1 - r.v0) - 1.0).abs() < 0.03, "vol change = average slope x move");
        assert!((r.dss - r.bs * r.mv - r.gterm).abs() < 0.03 * r.gterm, "sticky-strike residual is gamma");
        assert!((r.dsd - r.dss - r.vterm).abs() < 0.03 * r.vterm.abs(), "the smile adds vega x vol change");
    }
    assert!((k1 / ks[2] - 1.01).abs() < 1e-9, "25-delta strike rides with spot");
    assert!((smile(s1, k1) - vols[2]).abs() < 1e-9, "25-delta vol unchanged");
    println!("ALL CHECKS PASS");
}
