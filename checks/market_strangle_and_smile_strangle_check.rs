// The broker butterfly -- the same check as market_strangle_and_smile_strangle_check.py, in Rust.
// Standard library only, no crates.  N(x) is Simpson's rule written out; roots come from
// bisection (road 1) and the secant method (road 2).
use std::f64::consts::PI;

const S: f64 = 1.10; const RD: f64 = 0.05; const RF: f64 = 0.03; const T: f64 = 1.0;
const ATM: f64 = 0.10; const RR: f64 = -0.01; const BFM: f64 = 0.0025;
fn fwd() -> f64 { S * ((RD - RF) * T).exp() }
fn dd() -> f64 { (-RD * T).exp() }  fn df() -> f64 { (-RF * T).exp() }

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }     // bell-curve height
fn simpson<G: Fn(f64) -> f64>(f: G, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    s * h / 3.0
}
fn n_cdf(x: f64) -> f64 {                                                // bell-curve area left of x
    if x < -12.0 { 0.0 } else if x > 12.0 { 1.0 } else { 0.5 + simpson(phi, 0.0, x, 2000) }
}
fn bisect<G: Fn(f64) -> f64>(g: G, mut lo: f64, mut hi: f64) -> f64 {   // g(lo), g(hi) of opposite sign
    let mut glo = g(lo);
    for _ in 0..100 {
        let mid = 0.5 * (lo + hi); let gm = g(mid);
        if (gm > 0.0) == (glo > 0.0) { lo = mid; glo = gm; } else { hi = mid; }
    }
    0.5 * (lo + hi)
}
fn secant<G: Fn(f64) -> f64>(g: G, mut a: f64, mut b: f64) -> f64 {
    let (mut ga, mut gb) = (g(a), g(b));
    for _ in 0..30 {
        if gb == ga { break; }
        let nb = b - gb * (b - a) / (gb - ga); a = b; ga = gb; b = nb; gb = g(b);
        if (b - a).abs() < 1e-13 { break; }
    }
    b
}
fn d1(k: f64, sig: f64) -> f64 { ((S / k).ln() + (RD - RF + 0.5 * sig * sig) * T) / (sig * T.sqrt()) }
fn gk(k: f64, sig: f64, w: f64) -> f64 {                                 // w = +1 EUR call, -1 EUR put
    let a = d1(k, sig);
    w * (S * df() * n_cdf(w * a) - k * dd() * n_cdf(w * (a - sig * T.sqrt())))
}
fn delta(k: f64, sig: f64, w: f64) -> f64 { w * df() * n_cdf(w * d1(k, sig)) }
fn vega(k: f64, sig: f64) -> f64 { S * df() * phi(d1(k, sig)) * T.sqrt() }
fn by_integral(k: f64, sig: f64, w: f64) -> f64 {                        // road 2: average the payoff
    let f = |z: f64| {
        let st = S * ((RD - RF - 0.5 * sig * sig) * T + sig * T.sqrt() * z).exp();
        (w * (st - k)).max(0.0) * phi(z)
    };
    dd() * simpson(f, -10.0, 10.0, 40000)
}
type Kf = fn(f64, f64) -> f64;
fn k25(sig: f64, w: f64) -> f64 {
    let d25 = bisect(|x| n_cdf(x) - 0.25 / df(), -10.0, 10.0);         // e^{-rf T} N(d25) = 0.25
    fwd() * (-w * d25 * sig * T.sqrt() + 0.5 * sig * sig * T).exp()
}
fn k25_search(sig: f64, w: f64) -> f64 { bisect(|k| delta(k, sig, w) - 0.25 * w, 0.5, 2.0) }
struct Smile { xs: [f64; 3], ys: [f64; 3] }                              // quadratic in ln(K/F) through 3 pillars
impl Smile {
    fn new(atm: f64, rr: f64, b: f64, kf: Kf) -> Smile {
        let (sc, sp) = (atm + b + 0.5 * rr, atm + b - 0.5 * rr);
        Smile { xs: [(kf(sp, -1.0) / fwd()).ln(), 0.5 * atm * atm * T, (kf(sc, 1.0) / fwd()).ln()], ys: [sp, atm, sc] }
    }
    fn vol(&self, k: f64) -> f64 {
        let x = (k / fwd()).ln();
        let mut v = 0.0;
        for i in 0..3 {
            let mut l = 1.0;
            for j in 0..3 { if j != i { l *= (x - self.xs[j]) / (self.xs[i] - self.xs[j]); } }
            v += l * self.ys[i];
        }
        v
    }
}
fn market(atm: f64, bfm: f64, kf: Kf, price: Kf3) -> (f64, f64, f64) {     // the broker's strangle: one vol
    let sm = atm + bfm;
    let (kc, kp) = (kf(sm, 1.0), kf(sm, -1.0));
    (kc, kp, price(kc, sm, 1.0) + price(kp, sm, -1.0))
}
type Kf3 = fn(f64, f64, f64) -> f64;
fn gap_with(atm: f64, rr: f64, bfm: f64, b: f64, kf: Kf, price: Kf3) -> f64 {  // smile strangle minus market
    let (kc, kp, v) = market(atm, bfm, kf, price);
    let sm = Smile::new(atm, rr, b, kf);
    price(kc, sm.vol(kc), 1.0) + price(kp, sm.vol(kp), -1.0) - v
}
fn gap(atm: f64, rr: f64, bfm: f64, b: f64) -> f64 { gap_with(atm, rr, bfm, b, k25, gk) }
fn solve(atm: f64, rr: f64, bfm: f64) -> f64 { bisect(|b| gap(atm, rr, bfm, b), bfm - 0.01, bfm + 0.02) }

fn main() {
    let f = fwd();
    let sm = ATM + BFM;
    let (kmc, kmp, v) = market(ATM, BFM, k25, gk);
    let (kmc2, kmp2, v2) = (k25_search(sm, 1.0), k25_search(sm, -1.0), market(ATM, BFM, k25_search, by_integral).2);
    let g_naive = gap(ATM, RR, BFM, BFM);
    let b1 = solve(ATM, RR, BFM);                                         // road 1: formula + bisection
    let b2 = secant(|b| gap_with(ATM, RR, BFM, b, k25_search, by_integral), BFM, BFM + 0.001);   // road 2
    let slope = (gap(ATM, RR, BFM, BFM + 1e-5) - gap(ATM, RR, BFM, BFM - 1e-5)) / 2e-5;
    let b3 = BFM - g_naive / slope;                                       // road 3: one vega step
    let sml = Smile::new(ATM, RR, b1, k25);
    let (kc_s, kp_s) = (f * sml.xs[2].exp(), f * sml.xs[0].exp());
    let kc_fp = bisect(|k| delta(k, sml.vol(k), 1.0) - 0.25, kmc - 0.05, kmc + 0.05);   // 25 delta read off the smile
    let kp_fp = bisect(|k| delta(k, sml.vol(k), -1.0) + 0.25, kmp - 0.05, kmp + 0.05);
    let ka = bisect(|k| delta(k, sml.vol(k), 1.0) + delta(k, sml.vol(k), -1.0), kmp, kmc);   // delta-neutral straddle on the smile
    let nv = Smile::new(ATM, RR, BFM, k25);
    let (npk, nck) = (f * nv.xs[0].exp(), f * nv.xs[2].exp());
    let rows: Vec<(&str, f64)> = vec![
        ("forward F", f), ("market vol ATM+BF  %", 100.0 * sm),
        ("K market call, closed form", kmc), ("K market call, delta search", kmc2),
        ("K market put, closed form", kmp), ("K market put, delta search", kmp2),
        ("market call at 10.25", gk(kmc, sm, 1.0)), ("market put at 10.25", gk(kmp, sm, -1.0)),
        ("market strangle V, formula", v), ("market strangle V, integral", v2),
        ("delta: market strangle", delta(kmc, sm, 1.0) + delta(kmp, sm, -1.0)),
        ("vega/pt: market call", vega(kmc, sm) / 100.0), ("vega/pt: market put", vega(kmp, sm) / 100.0),
        ("naive smile vol at K call %", 100.0 * nv.vol(kmc)), ("naive smile vol at K put  %", 100.0 * nv.vol(kmp)),
        ("naive avg vol at market K %", 50.0 * (nv.vol(kmc) + nv.vol(kmp))),
        ("naive smile strangle", v + g_naive), ("naive gap, pips", 1e4 * g_naive), ("naive gap on EUR 10m, USD", 1e7 * g_naive),
        ("smile BF, bisection  %", 100.0 * b1), ("smile BF, secant+integral %", 100.0 * b2), ("smile BF, one vega step %", 100.0 * b3),
        ("smile BF - market BF, bp", 1e4 * (b1 - BFM)), ("d gap / d b, pips per bp", slope * 1e-4 * 1e4),
        ("smile vol 25d call  %", 100.0 * sml.vol(kc_s)), ("smile vol 25d put   %", 100.0 * sml.vol(kp_s)),
        ("K 25d call on smile", kc_s), ("K 25d call, smile delta search", kc_fp),
        ("K 25d put on smile", kp_s), ("K 25d put, smile delta search", kp_fp),
        ("smile vol at K market call %", 100.0 * sml.vol(kmc)), ("smile vol at K market put  %", 100.0 * sml.vol(kmp)),
        ("rebuilt RR  %", 100.0 * (sml.vol(kc_fp) - sml.vol(kp_fp))), ("rebuilt ATM %", 100.0 * sml.vol(ka)),
        ("naive pillar K put", npk), ("naive pillar K call", nck),
        ("wrong: V on naive pillar K", gk(nck, sm, 1.0) + gk(npk, sm, -1.0)),
        ("wrong: V strikes found at ATM", gk(k25(ATM, 1.0), sm, 1.0) + gk(k25(ATM, -1.0), sm, -1.0)),
        ("try: RR +1.00, gap bp", 1e4 * (solve(ATM, -RR, BFM) - BFM)), ("try: BF 0.50, gap bp", 1e4 * (solve(ATM, RR, 0.005) - 0.005)),
        ("try: ATM 15.00, gap bp", 1e4 * (solve(0.15, RR, BFM) - BFM)),
    ];
    for (name, x) in &rows { println!("{:<32} {:>14.6}", name, x); }
    let rrs = [0.0, -0.005, -0.01, -0.02, -0.03, -0.04, -0.05, -0.06];
    let gaps: Vec<f64> = rrs.iter().map(|&r| 1e4 * (solve(ATM, r, BFM) - BFM)).collect();
    let join = |v: &[f64], d: usize, m: f64| v.iter().map(|x| format!("{:.*}", d, m * x)).collect::<Vec<_>>().join(" ");
    println!("chart, RR %            {}", join(&rrs, 1, 100.0));
    println!("chart, BF gap, bp      {}", join(&gaps, 2, 1.0));
    let bs: Vec<f64> = (0..9).map(|i| -0.0025 + 0.00125 * i as f64).collect();
    let gs: Vec<f64> = bs.iter().map(|&b| gap(ATM, RR, BFM, b)).collect();
    println!("chart, smile BF %      {}", join(&bs, 3, 100.0));
    println!("chart, gap, pips       {}", join(&gs, 2, 1e4));
    let xs: Vec<f64> = (0..13).map(|i| 1.0 + 0.025 * i as f64).collect();
    let pay: Vec<f64> = xs.iter().map(|&x| (x - kmc).max(0.0) + (kmp - x).max(0.0)).collect();
    println!("chart, EURUSD expiry   {}", join(&xs, 3, 1.0));
    println!("chart, strangle, pips  {}", join(&pay, 2, 1e4));
    // no root: RR -12%.  The naive smile goes negative; every positive smile overprices the strangle.
    let rrx = -0.12;
    let nx = Smile::new(ATM, rrx, BFM, k25);
    let lowest_naive = nx.vol(kmc).min(nx.vol(kmp));
    let mut ok: Vec<f64> = Vec::new();
    for i in 0..1201 {
        let b = -0.03 + 0.0001 * i as f64;
        let s2 = Smile::new(ATM, rrx, b, k25);
        if ATM + b - 0.5 * rrx.abs() > 0.0 && s2.xs[0] < s2.xs[1] && s2.xs[1] < s2.xs[2] && s2.vol(kmc).min(s2.vol(kmp)) > 0.0 {
            ok.push(gap(ATM, rrx, BFM, b));
        }
    }
    let min_ok = ok.iter().cloned().fold(f64::INFINITY, f64::min);
    println!("{:<32} {:>14.6}", "RR -12: naive smile, low vol %", 100.0 * lowest_naive);
    println!("{:<32} {:>14}", "RR -12: positive smiles tried", ok.len());
    println!("{:<32} {:>14.6}", "RR -12: smallest gap, pips", 1e4 * min_ok);

    assert!((kmc - kmc2).abs() < 1e-9 && (kmp - kmp2).abs() < 1e-9 && (v - v2).abs() < 1e-8, "market strangle: formula vs search + integral");
    assert!((b1 - b2).abs() < 1e-8, "bisection on formula prices vs secant on brute-force prices");
    assert!((b3 / b1 - 1.0).abs() < 1e-3, "one vega step lands within 0.1 percent of the root");
    assert!((solve(ATM, 0.0, BFM) - BFM).abs() < 1e-10, "no tilt: smile BF equals market BF");
    assert!((sml.vol(kc_fp) - sml.vol(kp_fp) - RR).abs() < 1e-9 && (sml.vol(ka) - ATM).abs() < 1e-12, "smile still honours ATM and RR");
    assert!(gaps.windows(2).all(|w| w[0] < w[1]), "the gap grows with the size of the tilt");
    assert!(gs.windows(2).all(|w| w[0] < w[1]) && gs[4] < 0.0 && 0.0 < gs[5], "g rises on the scan, one sign change");
    assert!(lowest_naive < 0.0 && min_ok > 0.0, "RR -12%: no positive smile reprices the strangle");
    println!("ALL CHECKS PASS");
}
