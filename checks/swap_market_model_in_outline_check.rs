// Swap market model in outline -- the same check as swap_market_model_in_outline_check.py.
// Standard library only, no crates.  Two annual forwards, L1 (year 1 to 2) and L2 (year 2
// to 3), each lognormal on its own independent shock: a forward market model.  The
// two-coupon swap rate built from them is shown not to be lognormal, three ways.
use std::f64::consts::PI;

const L1: f64 = 0.03; const L2: f64 = 0.04; const S1: f64 = 0.20; const S2: f64 = 0.10;
const T: f64 = 1.0; const NOTIONAL: f64 = 10_000_000.0;

fn phi(z: f64) -> f64 { (-0.5 * z * z).exp() / (2.0 * PI).sqrt() }
fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    s * h / 3.0
}
fn n_cdf(x: f64) -> f64 {
    if x.abs() > 8.0 { return if x < 0.0 { 0.0 } else { 1.0 }; }
    0.5 + simpson(phi, 0.0, x, 200)
}
fn black(f: f64, k: f64, vol: f64, t: f64) -> f64 {        // undiscounted Black call
    if k <= 0.0 { return f - k; }
    let sd = vol * t.sqrt();
    let d1 = ((f / k).ln() + 0.5 * sd * sd) / sd;
    f * n_cdf(d1) - k * n_cdf(d1 - sd)
}
fn bonds(l1: f64, l2: f64) -> [f64; 3] {                   // P(T1), P(T2), P(T3) per T1 bond
    let p2 = 1.0 / (1.0 + l1);
    [1.0, p2, p2 / (1.0 + l2)]
}
fn swap_from_bonds(l1: f64, l2: f64) -> f64 {
    let p = bonds(l1, l2);
    (p[0] - p[2]) / (p[1] + p[2])
}
fn swap_formula(l1: f64, l2: f64) -> f64 { (l1 + l2 + l1 * l2) / (2.0 + l2) }
fn gamma(l1: f64, l2: f64) -> (f64, f64) {
    let d = l1 + l2 + l1 * l2;
    (S1 * l1 * (1.0 + l2) / d, S2 * l2 * (l1 + 2.0) / ((2.0 + l2) * d))
}
fn gamma_bump(l1: f64, l2: f64) -> (f64, f64) {
    let h: f64 = 1e-5;
    let g1 = (swap_from_bonds(l1 * h.exp(), l2) / swap_from_bonds(l1 * (-h).exp(), l2)).ln() / (2.0 * h);
    let g2 = (swap_from_bonds(l1, l2 * h.exp()) / swap_from_bonds(l1, l2 * (-h).exp())).ln() / (2.0 * h);
    (S1 * g1, S2 * g2)
}
fn size(g: (f64, f64)) -> f64 { (g.0 * g.0 + g.1 * g.1).sqrt() }
fn payer_integral(k: f64, s1: f64, s2: f64, t: f64) -> f64 {   // road A: one integral
    let f = |z: f64| {
        let y = L2 * (s2 * t.sqrt() * z - 0.5 * s2 * s2 * t).exp();
        let xs = (k * (2.0 + y) - y) / (1.0 + y);
        (1.0 + y) * black(L1, xs, s1, t) * phi(z)
    };
    simpson(f, -8.0, 8.0, 400)
}
struct Rng(u64);
impl Rng {                                                   // xorshift64
    fn uniform(&mut self) -> f64 {
        self.0 ^= self.0 << 13; self.0 ^= self.0 >> 7; self.0 ^= self.0 << 17;
        ((self.0 >> 11) as f64 + 0.5) / (2.0f64).powi(53)
    }
}
fn payer_mc(strikes: &[f64], paths: usize) -> (Vec<f64>, Vec<f64>, f64) {   // road B
    let m = strikes.len();
    let (mut sums, mut sq, mut ann) = (vec![0.0; m], vec![0.0; m], 0.0);
    let mut rng = Rng(88172645463325252);
    for _ in 0..paths {
        let (u1, u2) = (rng.uniform(), rng.uniform());
        let r = (-2.0 * u1.ln()).sqrt();
        let (z1, z2) = (r * (2.0 * PI * u2).cos(), r * (2.0 * PI * u2 - PI / 2.0).cos());
        let mut v = vec![0.0; m];
        for sign in [1.0, -1.0] {
            let x = L1 * (sign * S1 * T.sqrt() * z1 - 0.5 * S1 * S1 * T).exp();
            let y = L2 * (sign * S2 * T.sqrt() * z2 - 0.5 * S2 * S2 * T).exp();
            let s = swap_formula(x, y);
            ann += 0.5 * (2.0 + y) * s;
            for i in 0..m { v[i] += 0.5 * (2.0 + y) * (s - strikes[i]).max(0.0); }
        }
        for i in 0..m { sums[i] += v[i]; sq[i] += v[i] * v[i]; }
    }
    let n = paths as f64;
    let means: Vec<f64> = sums.iter().map(|a| a / n).collect();
    let ses = sq.iter().zip(&means).map(|(q, mu)| ((q / n - mu * mu) / n).sqrt()).collect();
    (means, ses, ann / n)
}
fn implied(s0: f64, target: f64, k: f64, t: f64) -> f64 {  // Black vol by halving
    let (mut lo, mut hi) = (1e-4, 1.0);
    for _ in 0..100 {
        let mid = 0.5 * (lo + hi);
        if black(s0, k, mid, t) < target { lo = mid; } else { hi = mid; }
    }
    0.5 * (lo + hi)
}

fn main() {
    let d1 = 1.0 / 1.025;
    let (s0, s0b) = (swap_formula(L1, L2), swap_from_bonds(L1, L2));
    let p = bonds(L1, L2);
    let (a0, p3) = (d1 * (p[1] + p[2]), d1 * p[2]);
    let (g, gb, g6, g6b) = (gamma(L1, L2), gamma_bump(L1, L2), gamma(0.06, L2), gamma_bump(0.06, L2));
    let money = |e: f64| NOTIONAL * p3 * e;
    println!("{:<34}{:>14.6}", "swap rate from bonds", s0b);
    println!("{:<34}{:>14.6}", "swap rate from the algebra", s0);
    println!("{:<34}{:>10.6}{:>10.6}{:>10.6}", "bonds P(T1) P(T2) P(T3) today", d1 * p[0], d1 * p[1], d1 * p[2]);
    println!("{:<34}{:>14.6}", "annuity today A(0)", a0);
    println!("{:<34}{:>14.6}{:>10.6}", "average weights P(T2)/A, P(T3)/A", d1 * p[1] / a0, p3 / a0);
    for (lab, a, b) in [("gamma1 at L1 = 3%", g.0, gb.0), ("gamma2 at L1 = 3%", g.1, gb.1),
                        ("gamma1 at L1 = 6%", g6.0, g6b.0), ("gamma2 at L1 = 6%", g6.1, g6b.1)] {
        println!("{:<24}formula{:>11.6}  nudge{:>11.6}", lab, a, b);
    }
    println!("{:<34}{:>14.6}", "swap vol size at L1 = 3%", size(g));
    println!("{:<34}{:>14.6}", "swap vol size at L1 = 6%", size(g6));
    println!("{:<34}{:>14.6}{:>10.6}", "weights dlnS/dlnL1, dlnS/dlnL2", g.0 / S1, g.1 / S2);
    let one = |l: f64| { let b = bonds(l, L2); (b[0] - b[1]) / b[1] };
    let g_one = S1 * (one(L1 * 1e-5f64.exp()) / one(L1 * (-1e-5f64).exp())).ln() / 2e-5;
    println!("{:<34}{:>14.6}", "one coupon: swap vol by nudging", g_one);
    println!("chart, swap vol (%) as L1 runs 1..8%, L2 = 4%:");
    let fm: Vec<String> = (1..9).map(|i| format!("{:.2}", 100.0 * size(gamma(i as f64 / 100.0, L2)))).collect();
    println!("  forward model {}", fm.join(" "));
    println!("  swap model    {}", vec![format!("{:.2}", 100.0 * size(g)); 8].join(" "));

    let strikes = [0.025, 0.03, 0.035, 0.04, 0.045, 0.05, s0];
    let exact: Vec<f64> = strikes.iter().map(|&k| payer_integral(k, S1, S2, T)).collect();
    let (mc, se, ann) = payer_mc(&strikes, 1_000_000);
    println!("{:<34}{:>14.6}", "annuity measure: E[S] by draws", ann / (2.0 + L2));
    println!("strike %   integral $    draws $  std error $  implied Black vol %");
    let mut vols = vec![];
    for i in 0..strikes.len() {
        let v = implied(s0, exact[i] / (2.0 + L2), strikes[i], T);
        vols.push(v);
        println!("{:8.4}{:>13.2}{:>11.2}{:>11.2}{:>18.4}", 100.0 * strikes[i], money(exact[i]), money(mc[i]), money(se[i]), 100.0 * v);
    }
    let atm = vols[6];
    let iv: Vec<String> = vols[..6].iter().map(|v| format!("{:.2}", 100.0 * v)).collect();
    println!("chart, implied vol (%) strikes 2.5..5.0: {}", iv.join(" "));
    let flat = |k: f64, v: f64| money(black(s0, k, v, T) * (2.0 + L2));
    println!("{:<34}{:>14.6}{:>14.2}", "frozen sensitivities: vol, ATM $", size(g), flat(s0, size(g)));
    let (w1, w2) = (d1 * p[1] / a0, p3 / a0);                 // Rebonato: freeze the weights
    let reb = size((S1 * w1 * L1 / s0, S2 * w2 * L2 / s0));
    println!("{:<34}{:>14.6}{:>14.2}", "frozen weights (Rebonato): vol, $", reb, flat(s0, reb));
    println!("{:<34}{:>14.2}", "wrong: flat ATM vol, 5% strike $", flat(0.05, atm));
    println!("{:<34}{:>14.2}", "wrong: flat ATM vol, 4.5% strike $", flat(0.045, atm));
    println!("{:<34}{:>14.6}{:>14.2}", "wrong: vols added, not combined", g.0 + g.1, flat(s0, g.0 + g.1));
    let xs = (0.01 * (2.0 + L2) - L2) / (1.0 + L2);
    let p1 = 0.01 * (2.0 + L2) + 1.0;                        // swap model state back to bonds
    println!("{:<34}{:>14.6}{:>12.6}", "swap model, S = 1%, L2 = 4%: L1", xs, p1 / (1.0 + L2) - 1.0);
    let tv: Vec<f64> = [0.025, 0.05].iter().map(|&k| implied(s0, payer_integral(k, S1, 0.20, T) / (2.0 + L2), k, T)).collect();
    let t5: Vec<f64> = [0.025, 0.05].iter().map(|&k| implied(s0, payer_integral(k, S1, S2, 5.0) / (2.0 + L2), k, 5.0)).collect();
    println!("{:<34}{:>14.4}{:>10.4}", "try: sigma2 = 20%, vol at 2.5%, 5%", 100.0 * tv[0], 100.0 * tv[1]);
    println!("{:<34}{:>14.4}{:>10.4}", "try: expiry 5 years, vol 2.5%, 5%", 100.0 * t5[0], 100.0 * t5[1]);

    assert!((s0 - s0b).abs() < 1e-14, "bond road and algebra road must agree");
    let gaps = [g.0 - gb.0, g.1 - gb.1, g6.0 - g6b.0, g6.1 - g6b.1];
    assert!(gaps.iter().all(|d| d.abs() < 1e-8), "closed-form vol vs nudging");
    assert!((0..strikes.len()).all(|i| (exact[i] - mc[i]).abs() < 4.0 * se[i]), "integral vs draws");
    assert!((ann / (2.0 + L2) - s0).abs() < 3e-5, "swap rate is driftless in annuity units");
    assert!(vols[0] < atm - 0.002 && vols[5] > atm + 0.002, "a lognormal swap rate has no skew");
    assert!((g_one - S1).abs() < 1e-8, "one coupon: the swap rate is the forward, same vol");
    assert!((swap_from_bonds(xs, L2) - 0.01).abs() < 1e-14, "recovered L1 reprices the 1% swap through bonds");
    assert!((p1 / (1.0 + L2) - 1.0 - xs).abs() < 1e-14, "L1 from the formula and from rebuilt bonds agree");
    assert!(size(g6) > size(g) + 0.02, "the swap rate's vol moves with L1, so no fixed gamma fits both");
    assert!((reb - atm).abs().min((size(g) - atm).abs()) > 2e-5, "frozen approximations are not exact");
    println!("ALL CHECKS PASS");
}
