// Currency digitals -- the same check as fx_digitals_check.py, in Rust.  Std only, no crates.
// House FX market: EURUSD S = 1.10 dollars per euro, USD rate 5%, EUR rate 3%, vol 10%, one year.
// N(x) by Simpson slices, random numbers by a 64-bit mixer, roots by halving.
use std::f64::consts::PI;

const S: f64 = 1.10; const RD: f64 = 0.05; const RF: f64 = 0.03; const SIG: f64 = 0.10; const T: f64 = 1.0; const K: f64 = 1.10;
const H: f64 = 1e-5;
const VS: [f64; 3] = [0.1075, 0.10, 0.0975];

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }
fn simpson(a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = phi(a) + phi(b);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * phi(a + i as f64 * h); }
    s * h / 3.0
}
fn nc(x: f64) -> f64 { if x < -12.0 { 0.0 } else if x > 12.0 { 1.0 } else { 0.5 + simpson(0.0, x, 2000) } }
fn d12(s: f64, k: f64, dom: f64, fgn: f64, v: f64) -> (f64, f64) {
    let d1 = ((s / k).ln() + (dom - fgn + 0.5 * v * v) * T) / (v * T.sqrt());
    (d1, d1 - v * T.sqrt())
}
fn call(s: f64, k: f64, dom: f64, fgn: f64, v: f64) -> f64 {
    let (d1, d2) = d12(s, k, dom, fgn, v); s * (-fgn * T).exp() * nc(d1) - k * (-dom * T).exp() * nc(d2)
}
fn put(s: f64, k: f64, dom: f64, fgn: f64, v: f64) -> f64 {
    let (d1, d2) = d12(s, k, dom, fgn, v); k * (-dom * T).exp() * nc(-d2) - s * (-fgn * T).exp() * nc(-d1)
}
fn usd_dig(s: f64, k: f64, v: f64) -> f64 { (-RD * T).exp() * nc(d12(s, k, RD, RF, v).1) }
fn eur_dig(s: f64, k: f64, v: f64) -> f64 { (-RF * T).exp() * nc(d12(s, k, RD, RF, v).0) }
fn vega(s: f64, k: f64, v: f64) -> f64 { s * (-RF * T).exp() * phi(d12(s, k, RD, RF, v).0) * T.sqrt() }

struct Rng(u64);
impl Rng {
    fn unif(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 * 2f64.powi(-53) + 2f64.powi(-54)
    }
}
fn lo<F: Fn(f64) -> f64>(mut a: f64, mut b: f64, f: F) -> f64 {
    for _ in 0..200 { let m = 0.5 * (a + b); if f(m) < 0.0 { a = m } else { b = m } }
    0.5 * (a + b)
}
fn smile(x: f64, ks: &[f64; 3]) -> f64 {                           // Castagna-Mercurio, second order
    let (k1, k2, k3) = (ks[0], ks[1], ks[2]);
    let y = [(k2 / x).ln() * (k3 / x).ln() / ((k2 / k1).ln() * (k3 / k1).ln()),
             (x / k1).ln() * (k3 / x).ln() / ((k2 / k1).ln() * (k3 / k2).ln()),
             (x / k1).ln() * (x / k2).ln() / ((k3 / k1).ln() * (k3 / k2).ln())];
    let mut dd1 = 0.0; for i in 0..3 { dd1 += y[i] * VS[i]; } dd1 -= VS[1];
    let mut dd2 = 0.0;
    for i in 0..3 { dd2 += y[i] * d12(S, ks[i], RD, RF, VS[1]).0 * d12(S, ks[i], RD, RF, VS[1]).1 * (VS[i] - VS[1]) * (VS[i] - VS[1]); }
    let (a, b) = d12(S, x, RD, RF, VS[1]); let ab = a * b;
    VS[1] + (-VS[1] + (VS[1] * VS[1] + ab * (2.0 * VS[1] * dd1 + dd2)).sqrt()) / ab
}
fn slope(x: f64, ks: &[f64; 3]) -> f64 { let e = 1e-5; (smile(x + e, ks) - smile(x - e, ks)) / (2.0 * e) }
fn smile_dig(x: f64, ks: &[f64; 3]) -> f64 { let v = smile(x, ks); usd_dig(S, x, v) - vega(S, x, v) * slope(x, ks) }
fn smile_spread(x: f64, ks: &[f64; 3]) -> f64 {
    (call(S, x - H, RD, RF, smile(x - H, ks)) - call(S, x + H, RD, RF, smile(x + H, ks))) / (2.0 * H)
}

fn main() {
    let (d1, d2) = d12(S, K, RD, RF, SIG);
    let (dd, ee) = (usd_dig(S, K, SIG), eur_dig(S, K, SIG));
    let d_spread = (call(S, K - H, RD, RF, SIG) - call(S, K + H, RD, RF, SIG)) / (2.0 * H);
    let p_spread = (put(S, K + H, RD, RF, SIG) - put(S, K - H, RD, RF, SIG)) / (2.0 * H);
    let e_ident = (call(S, K, RD, RF, SIG) + K * dd) / S;
    let (x, k) = (1.0 / S, 1.0 / K);                                  // the inverted quote, euros domestic
    let e_inv_formula = (-RF * T).exp() * nc(-d12(x, k, RF, RD, SIG).1);
    let e_inv_spread = (put(x, k + H, RF, RD, SIG) - put(x, k - H, RF, RD, SIG)) / (2.0 * H);

    let mut rng = Rng(20260927);
    let m = 200000; let (mut hit_d, mut hit_e, mut hit_e2) = (0.0f64, 0.0f64, 0.0f64);
    for _ in 0..m {
        let r = (-2.0 * rng.unif().ln()).sqrt();
        let z = r * (2.0 * PI * rng.unif()).cos();
        let st = S * ((RD - RF - 0.5 * SIG * SIG) * T + SIG * T.sqrt() * z).exp();
        if st > K { hit_d += 1.0; hit_e += st; hit_e2 += st * st; }
    }
    let mf = m as f64;
    let d_mc = (-RD * T).exp() * hit_d / mf; let e_mc = (-RD * T).exp() * hit_e / mf / S;
    let se = (-RD * T).exp() * (hit_d / mf * (1.0 - hit_d / mf) / mf).sqrt();
    let se_e = (-RD * T).exp() / S * ((hit_e2 / mf - (hit_e / mf).powi(2)) / mf).sqrt();

    let f = S * ((RD - RF) * T).exp();
    let dc = lo(-5.0, 5.0, |x| (-RF * T).exp() * nc(x) - 0.25);
    let ks = [f * (dc * 0.1075 + 0.5 * 0.1075 * 0.1075).exp(), f * (0.5f64 * 0.10 * 0.10).exp(), f * (-dc * 0.0975 + 0.5 * 0.0975 * 0.0975).exp()];
    let k3 = ks[2]; let v3 = smile(k3, &ks);
    let flat3 = usd_dig(S, k3, v3); let term3 = -vega(S, k3, v3) * slope(k3, &ks);
    let b = 1e-5;
    let (dlt, dlt_bump) = ((-RD * T).exp() * phi(d2) / (S * SIG * T.sqrt()), (usd_dig(S + b, K, SIG) - usd_dig(S - b, K, SIG)) / (2.0 * b));
    let (vg, vg_bump) = (-(-RD * T).exp() * phi(d2) * d1 / SIG / 100.0, (usd_dig(S, K, SIG + b) - usd_dig(S, K, SIG - b)) / (2.0 * b) / 100.0);

    let mut rows: Vec<(String, f64)> = vec![("d1".into(), d1), ("d2".into(), d2), ("N(d1)".into(), nc(d1)), ("N(d2)".into(), nc(d2)), ("forward F".into(), f),
        ("USD digital 1 formula".into(), dd), ("USD digital 2 call spread".into(), d_spread), ("USD digital 3 Monte Carlo".into(), d_mc),
        ("  Monte Carlo std error".into(), se), ("USD digital put, put spread".into(), p_spread), ("  call + put".into(), dd + p_spread), ("  e^-rdT".into(), (-RD * T).exp()), ("  e^-rfT".into(), (-RF * T).exp()),
        ("EUR digital 1 formula".into(), ee), ("EUR digital 2 (call + K D)/S".into(), e_ident), ("EUR digital 3 Monte Carlo".into(), e_mc),
        ("EUR digital 4 inverted formula".into(), e_inv_formula), ("EUR digital 5 inverted put spread".into(), e_inv_spread),
        ("EUR digital in USD, S x E".into(), S * ee)];
    for w in [0.02, 0.01, 0.001] {
        rows.push((format!("one-sided spread width {}", w), (call(S, K - w, RD, RF, SIG) - call(S, K, RD, RF, SIG)) / w));
    }
    let more: Vec<(&str, f64)> = vec![("USD delta, formula", dlt), ("USD vega per vol pt, formula", vg),
        ("EUR delta, formula", (-RF * T).exp() * phi(d1) / (S * SIG * T.sqrt())),
        ("EUR vega per vol pt, formula", -(-RF * T).exp() * phi(d1) * d2 / SIG / 100.0),
        ("USD vega sign flip spot", K * (-(RD - RF + 0.5 * SIG * SIG) * T).exp()),
        ("EUR vega sign flip spot", K * (-(RD - RF - 0.5 * SIG * SIG) * T).exp()),
        ("pillar 25d put strike", ks[0]), ("pillar ATM strike", ks[1]), ("pillar 25d call strike", k3),
        ("smile vol at 1.10", smile(K, &ks)), ("USD digital 1.10 flat, own vol", usd_dig(S, K, smile(K, &ks))),
        ("  skew term at 1.10", smile_dig(K, &ks) - usd_dig(S, K, smile(K, &ks))), ("USD digital 1.10 smile", smile_dig(K, &ks)),
        ("smile vol at 25d call", v3), ("smile slope per unit strike", slope(k3, &ks)), ("vega at 25d call", vega(S, k3, v3)),
        ("USD digital 25d flat", flat3), ("  skew term -vega x slope", term3), ("USD digital 25d smile", flat3 + term3),
        ("USD digital 25d smile spread", smile_spread(k3, &ks)), ("  skew term / flat price", term3 / flat3),
        ("EUR digital 25d flat", eur_dig(S, k3, v3)), ("EUR digital 25d smile", eur_dig(S, k3, v3) - k3 / S * vega(S, k3, v3) * slope(k3, &ks)),
        ("wrong: USD digital with N(d1)", (-RD * T).exp() * nc(d1)),
        ("wrong: USD digital, rates swapped", (-RF * T).exp() * nc(d12(S, K, RF, RD, SIG).1)),
        ("wrong: skew term added with + sign", flat3 - term3), ("wrong: 25d digital at ATM vol", usd_dig(S, k3, 0.10))];
    for (n, v) in more { rows.push((n.to_string(), v)); }
    for (n, v) in &rows { println!("{:<36} {:>12.6}", n, v); }
    let strikes: Vec<f64> = (0..12).map(|i| 1.02 + 0.02 * i as f64).collect();
    let spots: Vec<f64> = (0..11).map(|i| 1.00 + 0.02 * i as f64).collect();
    let line = |lab: &str, xs: &Vec<f64>, f: &dyn Fn(f64) -> f64, p: usize| {
        println!("{}{}", lab, xs.iter().map(|&x| format!("{:6.*}", p, f(x))).collect::<Vec<_>>().join(" "));
    };
    line("chart K 1.02..1.24, smile vol % ", &strikes, &|x| 100.0 * smile(x, &ks), 2);
    line("chart K, flat digital at own vol ", &strikes, &|x| usd_dig(S, x, smile(x, &ks)), 2);
    line("chart K, digital on the smile    ", &strikes, &|x| smile_dig(x, &ks), 2);
    line("chart S 1.00..1.20, USD digital  ", &spots, &|x| usd_dig(x, K, SIG), 2);
    line("chart S, EUR digital in EUR      ", &spots, &|x| eur_dig(x, K, SIG), 2);

    assert!((dd - 0.532325).abs() < 5e-7 && (ee - 0.581012).abs() < 5e-7, "formula vs the card's worked numbers");
    assert!((d_spread - dd).abs() < 1e-6, "call spread replicates the USD digital");
    assert!((d_mc - dd).abs() < 4.0 * se, "Monte Carlo within four standard errors");
    assert!((dd + p_spread - (-RD * T).exp()).abs() < 1e-6, "digital call + put = a discounted dollar");
    assert!((e_inv_spread - ee).abs() < 1e-6, "inverted-quote put spread = EUR digital");
    assert!((e_ident - ee).abs() < 1e-9, "asset-or-nothing identity");
    assert!((e_inv_formula - ee).abs() < 1e-9 && (e_mc - ee).abs() < 4.0 * se_e, "inverted formula and EUR Monte Carlo");
    assert!((dlt_bump - dlt).abs() < 1e-6 && (vg_bump - vg).abs() < 1e-8, "delta and vega: formula vs bump");
    assert!((smile_spread(k3, &ks) - (flat3 + term3)).abs() < 1e-6, "skew term vs call spread along the smile");
    assert!((v3 - 0.0975).abs() < 1e-12 && (k3 - 1.201425).abs() < 5e-7, "smile passes through its pillar");
    println!("ALL CHECKS PASS");
}
