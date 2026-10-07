// Garman-Kohlhagen Greeks -- the check behind the card.  Rust std only.
// EUR call / USD put.  Prices in USD per EUR of notional.  Three roads to every
// Greek: the closed forms, bumps of the closed-form price, bumps of a Simpson
// integral that never uses d1 or d2.  Then the other currency, via the symmetry.
use std::f64::consts::PI;

type Pricer = fn(f64, f64, f64, f64, f64, f64, bool) -> f64;
const NAMES: [&str; 6] = ["delta", "gamma", "vega", "theta", "rho USD", "rho EUR"];

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }
fn n(x: f64) -> f64 {                                       // bell-curve area, own series
    if x < 0.0 { return 1.0 - n(-x); }
    let (mut term, mut total, mut k) = (x, x, 0.0);
    while term.abs() > 1e-17 * total.abs() { k += 1.0; term *= x * x / (2.0 * k + 1.0); total += term; }
    0.5 + phi(x) * total
}
fn d12(s: f64, k: f64, rd: f64, rf: f64, v: f64, t: f64) -> (f64, f64) {
    let d1 = ((s / k).ln() + (rd - rf + 0.5 * v * v) * t) / (v * t.sqrt());
    (d1, d1 - v * t.sqrt())
}
fn gk(s: f64, k: f64, rd: f64, rf: f64, v: f64, t: f64, call: bool) -> f64 {   // road 1 price
    let (d1, d2) = d12(s, k, rd, rf, v, t);
    if call { s * (-rf * t).exp() * n(d1) - k * (-rd * t).exp() * n(d2) }
    else { k * (-rd * t).exp() * n(-d2) - s * (-rf * t).exp() * n(-d1) }
}
fn gk_int(s: f64, k: f64, rd: f64, rf: f64, v: f64, t: f64, call: bool) -> f64 { // road 3: no d1, no d2
    let (m, sd, steps) = ((rd - rf - 0.5 * v * v) * t, v * t.sqrt(), 4000usize);
    let zs = ((k / s).ln() - m) / sd;                        // where the payoff hits zero
    let (a, b) = if call { (zs, 12.0) } else { (-12.0, zs) };
    let h = (b - a) / steps as f64;
    let mut tot = 0.0;
    for i in 0..=steps {
        let z = a + i as f64 * h;
        let w = if i == 0 || i == steps { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 };
        tot += w * (s * (m + sd * z).exp() - k) * phi(z);
    }
    (if call { 1.0 } else { -1.0 }) * (-rd * t).exp() * tot * h / 3.0
}
fn formulas(s: f64, k: f64, rd: f64, rf: f64, v: f64, t: f64, call: bool) -> [f64; 6] {
    let (d1, d2) = d12(s, k, rd, rf, v, t);
    let (ef, ed, w) = ((-rf * t).exp(), (-rd * t).exp(), if call { 1.0 } else { -1.0 });
    [w * ef * n(w * d1), ef * phi(d1) / (s * v * t.sqrt()), s * ef * phi(d1) * t.sqrt(),
     -s * ef * phi(d1) * v / (2.0 * t.sqrt()) + w * (rf * s * ef * n(w * d1) - rd * k * ed * n(w * d2)),
     w * k * t * ed * n(w * d2), -w * s * t * ef * n(w * d1)]
}
fn bumps(p: Pricer, s: f64, k: f64, rd: f64, rf: f64, v: f64, t: f64, call: bool) -> [f64; 6] {
    let (hs, e) = (1e-4 * s, 1e-4);
    let f = |s: f64, rd: f64, rf: f64, v: f64, t: f64| p(s, k, rd, rf, v, t, call);
    [(f(s + hs, rd, rf, v, t) - f(s - hs, rd, rf, v, t)) / (2.0 * hs),
     (f(s + hs, rd, rf, v, t) - 2.0 * f(s, rd, rf, v, t) + f(s - hs, rd, rf, v, t)) / (hs * hs),
     (f(s, rd, rf, v + e, t) - f(s, rd, rf, v - e, t)) / (2.0 * e),
     -(f(s, rd, rf, v, t + e) - f(s, rd, rf, v, t - e)) / (2.0 * e),
     (f(s, rd + e, rf, v, t) - f(s, rd - e, rf, v, t)) / (2.0 * e),
     (f(s, rd, rf + e, v, t) - f(s, rd, rf - e, v, t)) / (2.0 * e)]
}
fn commas(x: f64, dp: usize) -> String {                    // 1234567.8 -> "1,234,568"
    let raw = format!("{:.*}", dp, x.abs());
    let (int, frac) = match raw.find('.') { Some(i) => (&raw[..i], &raw[i..]), None => (&raw[..], "") };
    let mut out = String::new();
    for (i, c) in int.chars().enumerate() {
        if i > 0 && (int.len() - i) % 3 == 0 { out.push(','); }
        out.push(c);
    }
    format!("{}{}{}", if x < 0.0 && raw.trim_matches(|c| c == '0' || c == '.') != "" { "-" } else { "" }, out, frac)
}

fn main() {
    let (s, k, rd, rf, v, t, not) = (1.10, 1.10, 0.05, 0.03, 0.10, 1.0, 10_000_000.0);
    let (d1, d2) = d12(s, k, rd, rf, v, t);
    let (c, p) = (gk(s, k, rd, rf, v, t, true), gk(s, k, rd, rf, v, t, false));
    let g1 = formulas(s, k, rd, rf, v, t, true);
    let g2 = bumps(gk, s, k, rd, rf, v, t, true);
    let g3 = bumps(gk_int, s, k, rd, rf, v, t, true);
    println!("d1 {:.6}  d2 {:.6}  N(d1) {:.6}  N(d2) {:.6}  phi(d1) {:.6}", d1, d2, n(d1), n(d2), phi(d1));
    println!("e^-rfT {:.6}  e^-rdT {:.6}  forward {:.6}", (-rf * t).exp(), (-rd * t).exp(), s * ((rd - rf) * t).exp());
    println!("call {:.6}  put {:.6}  call by integral {:.6}", c, p, gk_int(s, k, rd, rf, v, t, true));
    println!("{:<9}{:>12}{:>16}{:>17}", "Greek", "1 formula", "2 bump formula", "3 bump integral");
    for i in 0..6 { println!("{:<9}{:>12.6}{:>16.6}{:>17.6}", NAMES[i], g1[i], g2[i], g3[i]); }
    let th_pde = rd * c - (rd - rf) * s * g3[0] - 0.5 * v * v * s * s * g3[1];
    println!("theta decay term {:.6}", -s * (-rf * t).exp() * phi(d1) * v / (2.0 * t.sqrt()));
    println!("theta from the PDE, road-3 delta and gamma {:.6}", th_pde);
    println!("rho USD + rho EUR {:.6}   -T x call {:.6}", g1[4] + g1[5], -t * c);
    println!("desk units on EUR 10m notional");
    println!("  premium                      USD {:>12}", commas(c * not, 0));
    println!("  delta hedge, sell            EUR {:>12}", commas(g1[0] * not, 0));
    println!("  gamma, delta change per 1% spot move {:.6} = EUR {}", g1[1] * s * 0.01, commas(g1[1] * s * 0.01 * not, 0));
    println!("  vega per vol point {:.6} USD per EUR = USD {}", g1[2] / 100.0, commas(g1[2] / 100.0 * not, 0));
    println!("  theta per day {:.8} USD per EUR = USD {}", g1[3] / 365.0, commas(g1[3] / 365.0 * not, 0));
    println!("  rho USD per bp USD {}   rho EUR per bp USD {}", commas(g1[4] * 1e-4 * not, 2), commas(g1[5] * 1e-4 * not, 2));
    // the other currency: a USD put / EUR call for a EUR-based holder, spot 1/S, strike 1/K,
    // domestic rate rf, foreign rate rd, on K USD per EUR of notional
    let (x, kk) = (1.0 / s, 1.0 / k);
    let h1 = formulas(x, kk, rf, rd, v, t, false);
    let h3 = bumps(gk_int, x, kk, rf, rd, v, t, false);
    println!("seen from EUR, per EUR of notional, in EUR   [USD figure / spot]  [EUR-side bumps]");
    println!("  premium       {:.6}   [{:.6}]  [{:.6}]", gk(x, kk, rf, rd, v, t, false) * k, c / s, gk_int(x, kk, rf, rd, v, t, false) * k);
    println!("  vega          {:.6}   [{:.6}]  [{:.6}]", h1[2] * k, g1[2] / s, h3[2] * k);
    println!("  theta         {:.6}   [{:.6}]  [{:.6}]", h1[3] * k, g1[3] / s, h3[3] * k);
    println!("  rho EUR rate  {:.6}   [{:.6}]  [{:.6}]", h1[4] * k, g1[5] / s, h3[4] * k);
    println!("  rho USD rate  {:.6}   [{:.6}]  [{:.6}]", h1[5] * k, g1[4] / s, h3[5] * k);
    let pa = -h1[0] * k / s;                                  // EUR sold per EUR of notional
    println!("  EUR-side hedge, sell EUR per EUR {:.6}   [delta - C/S {:.6}]  = EUR {}", pa, g1[0] - c / s, commas(pa * not, 0));
    println!("what breaks");
    println!("  delta without e^-rfT (N(d1))        {:.6}  EUR {}", n(d1), commas(n(d1) * not, 0));
    println!("  vega per unit read as per point     USD {}", commas(g1[2] * not, 0));
    println!("  both rates up 1bp, only rho USD     USD {}  true USD {}", commas(g1[4] * 1e-4 * not, 2), commas((g2[4] + g2[5]) * 1e-4 * not, 2));
    println!("  gamma with phi(d2)                  {:.6}", (-rf * t).exp() * phi(d2) / (s * v * t.sqrt()));
    println!("  theta without the EUR carry term    {:.6}", g1[3] - rf * s * (-rf * t).exp() * n(d1));
    println!("chart: spot delta across spot");
    let spots: Vec<f64> = (0..11).map(|i| 1.00 + 0.02 * i as f64).collect();
    println!("  spot     {}", spots.iter().map(|x| format!("{:.2}", x)).collect::<Vec<_>>().join(" "));
    for (lab, tt) in [("12 months", 1.0), ("1 month  ", 1.0 / 12.0)] {
        let row: Vec<String> = spots.iter().map(|&sp| format!("{:.2}", formulas(sp, k, rd, rf, v, tt, true)[0])).collect();
        println!("  {} {}", lab, row.join(" "));
    }
    println!("bars: vega per vol point on EUR 10m, USD, 12 months");
    for sp in [1.00, 1.05, 1.10, 1.15, 1.20] {
        println!("  spot {:.2}  USD {:>7}", sp, commas(formulas(sp, k, rd, rf, v, t, true)[2] / 100.0 * not, 0));
    }
    println!("bars: rho per bp on EUR 10m, USD, by maturity, spot and strike 1.10");
    for tt in [0.25, 1.0, 2.0, 5.0] {
        let f = formulas(s, k, rd, rf, v, tt, true);
        println!("  {:>4.2} yr  USD rate {:>8}   EUR rate {:>8}", tt, commas(f[4] * 1e-4 * not, 0), commas(f[5] * 1e-4 * not, 0));
    }

    for (sp, tt) in [(s, t), (1.12, 0.25)] {                 // the house case and a 3-month one
        let (fa, fb) = (formulas(sp, k, rd, rf, v, tt, true), bumps(gk_int, sp, k, rd, rf, v, tt, true));
        for i in 0..6 { assert!((fa[i] - fb[i]).abs() < 1e-5 * fa[i].abs().max(1.0), "{}: formula vs integral road", NAMES[i]); }
    }
    assert!((c - 0.053556).abs() < 5e-7, "house premium from the shelf");
    assert!((th_pde - g1[3]).abs() < 1e-6, "theta: closed form vs PDE built from road 3");
    assert!((h1[2] * k - g3[2] / s).abs() < 1e-6, "vega: EUR-side formula vs USD-side integral bump");
    assert!((pa - (g3[0] - c / s)).abs() < 1e-6, "EUR-side hedge vs delta minus premium");
    for (j, u) in [(2, 2), (3, 3), (4, 5), (5, 4)] {
        assert!((h1[j] * k - g1[u] / s).abs() < 1e-9 && (h3[j] * k - g1[u] / s).abs() < 1e-6, "{}: EUR side vs USD figure / spot", NAMES[j]);
    }
    assert!((gk_int(x, kk, rf, rd, v, t, false) * k - c / s).abs() < 1e-6, "EUR premium: EUR-side integral vs C / S");
    assert!((g2[4] + g2[5] + t * c).abs() < 1e-6, "parallel rate shift = -T x price");
    println!("ALL CHECKS PASS");
}
