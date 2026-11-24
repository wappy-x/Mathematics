// Quanto CDS -- the check behind the card.  Standard library only.
// One sovereign, protection paid in dollars or in euros; the euro drops by gam
// at the default instant.  Roads to the two spreads: the closed form, both legs
// added up in dollars (Simpson's rule and a premium-date sum), and a Monte Carlo
// of default dates and exchange-rate paths.  Then the inverse: gam from quotes.
use std::f64::consts::PI;

const R: f64 = 0.40; const LAM: f64 = 0.025; const GAM: f64 = 0.20; // recovery, hazard (dollar world), drop
const RD: f64 = 0.04; const RF: f64 = 0.02; // dollar rate, euro rate
const X0: f64 = 1.10; const SIG: f64 = 0.08; // dollars per euro, FX volatility
const T: f64 = 5.0; const DL: f64 = 0.25; const N: usize = 20; // tenor, quarter, premium dates
const L: f64 = 1.0 - R; const BP: f64 = 1e4;

fn f(x: f64) -> f64 { if x == 0.0 { 1.0 } else { (x.exp() - 1.0) / x } } // the quarter-end delay factor

fn closed(lam: f64, gam: f64, r: f64, dated: bool, acc: bool) -> f64 { // road 1: par spread; gam = 0, r = RD: dollars
    let le = lam * (1.0 - gam); // hazard seen by a holder of the payout currency
    let x = (r + le) * DL;
    let g = if acc { f(x) / (1.0 + le / (r + le) * (f(x) - 1.0)) } else { f(x) }; // accrued premium pulls it back
    L * le * if dated { g } else { 1.0 }
}

fn legs(lam: f64, gam: f64, r: f64) -> (f64, f64, f64, f64) { // road 2: both legs in dollars per $ of notional
    let (m, drift) = (200usize, RD - r + gam * lam); // pre-default drift of the payout currency in dollars
    let w = |t: f64| (-RD * t).exp() * (drift * t).exp() * (-lam * t).exp();
    let (h, mut prot, mut cont, mut accr) = (DL / m as f64, 0.0, 0.0, 0.0);
    for j in 0..N { // Simpson's rule over the default date, a quarter at a time
        for i in 0..=m {
            let k = if i == 0 || i == m { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 };
            let c = k * h / 3.0 * w(j as f64 * DL + i as f64 * h);
            cont += c; // premium paid continuously
            prot += c * L * (1.0 - gam) * lam; // payout at default, after the drop
            accr += c * i as f64 * h * (1.0 - gam) * lam; // premium accrued in the quarter, paid at default
        }
    }
    let ann: f64 = (1..=N).map(|j| DL * w(j as f64 * DL)).sum(); // premiums at quarter ends
    (prot / ann, prot / (ann + accr), prot, cont)
}

struct Rng(u64);
impl Rng {
    fn unif(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15); // splitmix64
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0 + 0.5 / 9007199254740992.0
    }
}

fn ratio(p: &[f64], a: &[f64]) -> (f64, Vec<f64>) { // sum P / sum A, and each path's share of its error
    let (r, ma) = (p.iter().sum::<f64>() / a.iter().sum::<f64>(), a.iter().sum::<f64>() / a.len() as f64);
    (r, p.iter().zip(a).map(|(p, a)| (p - r * a) / ma).collect())
}
fn se(e: &[f64]) -> f64 { e.iter().map(|x| x * x).sum::<f64>().sqrt() / e.len() as f64 }

fn monte_carlo(paths: usize, seed: u64) -> [f64; 7] { // road 3: simulate default and the jump
    let mut g = Rng(seed);
    let mu = RD - RF + GAM * LAM - 0.5 * SIG * SIG; // log-drift of X before default
    let nu = RD - RF - 0.5 * SIG * SIG; // after default: no jump left to pay for
    let (mut pu, mut au, mut pe, mut ae, mut d) = (vec![], vec![], vec![], vec![], vec![]);
    for _ in 0..paths {
        let tau = -g.unif().ln() / LAM;
        let (mut lx, mut o_u, mut o_e, mut b_u, mut b_e) = (0.0f64, 0.0, 0.0, 0.0, 0.0);
        for j in 1..=N {
            let (u1, u2) = (g.unif(), g.unif()); // Box-Muller: two normals
            let (z, z2) = ((-2.0 * u1.ln()).sqrt() * (2.0 * PI * u2).cos(), (-2.0 * u1.ln()).sqrt() * (2.0 * PI * u2).sin());
            let t = j as f64 * DL;
            if tau > t {
                lx += mu * DL + SIG * DL.sqrt() * z;
                b_u += DL * (-RD * t).exp(); b_e += DL * (-RD * t + lx).exp();
            } else if tau > t - DL {
                let hh = tau - (j - 1) as f64 * DL; // walk X to the default date
                lx += mu * hh + SIG * hh.sqrt() * z;
                o_u = L * (-RD * tau).exp();
                o_e = L * (1.0 - GAM) * (-RD * tau + lx).exp(); // the euro drops by gam
                lx += (1.0 - GAM).ln() + nu * (t - tau) + SIG * (t - tau).sqrt() * z2;
            } else {
                lx += nu * DL + SIG * DL.sqrt() * z;
            }
        }
        pu.push(o_u); au.push(b_u); pe.push(o_e); ae.push(b_e);
        d.push((lx + (RF - RD) * T).exp()); // euro deposit in $, discounted, / X0
    }
    let ((s_u, e_u), (s_e, e_e)) = (ratio(&pu, &au), ratio(&pe, &ae));
    let dm = d.iter().sum::<f64>() / paths as f64;
    let e_g: Vec<f64> = e_u.iter().zip(&e_e).map(|(u, e)| s_e / s_u * (e / s_e - u / s_u)).collect(); // the drop
    [s_u, se(&e_u), s_e, se(&e_e), se(&e_g), dm, se(&d.iter().map(|x| x - dm).collect::<Vec<f64>>())]
}

fn solve(fun: &dyn Fn(f64) -> f64, target: f64) -> f64 {
    let (mut lo, mut hi) = (0.0f64, 1.0f64); // bisection for an increasing fun
    while hi - lo > 1e-15 {
        let mid = 0.5 * (lo + hi);
        if fun(mid) < target { lo = mid } else { hi = mid }
    }
    0.5 * (lo + hi)
}

fn main() {
    // ---- the triangle: one name, two currencies ----
    let (s_u, s_e) = (closed(LAM, 0.0, RD, false, false), closed(LAM, GAM, RF, false, false));
    println!("dollar spread, triangle (1-R)*lam: {:.2} bp", s_u * BP);
    println!("euro spread, triangle (1-gam)*(1-R)*lam: {:.2} bp", s_e * BP);
    println!("implied drop from 150 and 120: 1 - 120/150 = {:.4}", 1.0 - 120.0 / 150.0);
    println!("euro-world hazard (1-gam)*lam: {:.4}", LAM * (1.0 - GAM));
    println!("payout on $11m: ${:.2}m; on EUR 10m: EUR {:.2}m = ${:.2}m at {:.2}", L * 11.0, L * 10.0, L * 10.0 * X0 * (1.0 - GAM), X0 * (1.0 - GAM));
    println!("pre-default euro drift rd - rf + gam*lam: {:.4}; jump term -gam*lam: {:.4}", RD - RF + GAM * LAM, -GAM * LAM);
    for (g, r, name) in [(0.0, RD, "dollar"), (GAM, RF, "euro")] { // Simpson against the integrals in closed form
        let k = r + (1.0 - g) * LAM; // payout-currency rate plus the hazard its holder sees
        let (_, _, pr, cn) = legs(LAM, g, r);
        let (pc, cc) = (L * (1.0 - g) * LAM * (1.0 - (-k * T).exp()) / k, (1.0 - (-k * T).exp()) / k);
        println!("{} legs, Simpson vs closed: protection {:.8} vs {:.8}, annuity {:.6} vs {:.6}", name, pr, pc, cn, cc);
        assert!((pr - pc).abs() < 1e-9 && (cn - cc).abs() < 1e-9);
    }
    // ---- quarter-end premiums, without and with the accrued premium at default ----
    let (q_u, q_e) = (closed(LAM, 0.0, RD, true, false), closed(LAM, GAM, RF, true, false));
    let (a_u, a_e) = (closed(LAM, 0.0, RD, true, true), closed(LAM, GAM, RF, true, true));
    let (l_u, l_e) = (legs(LAM, 0.0, RD), legs(LAM, GAM, RF));
    println!("dated closed form: dollar {:.4} bp, euro {:.4} bp, ratio {:.6}", q_u * BP, q_e * BP, q_e / q_u);
    println!("dated legs: dollar {:.4} bp, euro {:.4} bp", l_u.0 * BP, l_e.0 * BP);
    let (xu, xe) = ((RD + LAM) * DL, (RF + LAM * (1.0 - GAM)) * DL);
    println!("delay factors: dollar x {:.5} -> {:.6}, euro x {:.5} -> {:.6}", xu, f(xu), xe, f(xe));
    println!("with accrued premium, closed form: dollar {:.4} bp, euro {:.4} bp, ratio {:.6}", a_u * BP, a_e * BP, a_e / a_u);
    println!("with accrued premium, legs: dollar {:.4} bp, euro {:.4} bp", l_u.1 * BP, l_e.1 * BP);
    println!("delay factors with accrual: dollar {:.6}, euro {:.6}; 1 + r*dl/2: {:.4}, {:.4}",
        a_u / s_u, a_e / s_e, 1.0 + RD * DL / 2.0, 1.0 + RF * DL / 2.0);
    assert!([(l_u.0, q_u), (l_e.0, q_e), (l_u.1, a_u), (l_e.1, a_e)].iter().all(|(a, b)| (a - b).abs() < 1e-9));
    let [m_u, se_u, m_e, se_e, se_g, dep, se_d] = monte_carlo(400_000, 20261123);
    println!("Monte Carlo, 400,000 paths: dollar {:.2} bp (se {:.2}), euro {:.2} bp (se {:.2})",
        m_u * BP, se_u * BP, m_e * BP, se_e * BP);
    println!("Monte Carlo implied drop 1 - sE/sU: {:.4} (se {:.4}); dated model: {:.4}", 1.0 - m_e / m_u, se_g, 1.0 - q_e / q_u);
    println!("Monte Carlo euro deposit in dollars at 5 years, discounted, over X0: {:.4} (se {:.4})", dep, se_d);
    assert!((m_u - q_u).abs() < 4.0 * se_u && (m_e - q_e).abs() < 4.0 * se_e);
    assert!((m_e / m_u - q_e / q_u).abs() < 3.0 * se_g && 3.0 * se_g < (1.0 - m_e / m_u - 0.2).abs()); // model, not shortcut
    assert!((dep - 1.0).abs() < 4.0 * se_d); // the drift a makes the deposit fair
    // ---- the inverse: drop from the two quotes ----
    let (lq, le) = (solve(&|x| closed(x, 0.0, RD, true, false), 0.0150), solve(&|x| closed(x, 0.0, RF, true, false), 0.0120));
    let (la, ea) = (solve(&|x| closed(x, 0.0, RD, true, true), 0.0150), solve(&|x| closed(x, 0.0, RF, true, true), 0.0120));
    let (g0, g1, g2) = (1.0 - 0.0120 / 0.0150, 1.0 - le / lq, 1.0 - ea / la);
    let (r_u, r_e, x_u, x_e) = (legs(lq, 0.0, RD).0, legs(lq, g1, RF).0, legs(la, 0.0, RD).1, legs(la, g2, RF).1);
    println!("inverse: shortcut {:.4}; dated quotes: lam {:.6}, euro-world lam {:.6}, drop {:.4}", g0, lq, le, g1);
    println!("re-priced through the legs: {:.4} bp and {:.4} bp", r_u * BP, r_e * BP);
    println!("inverse with accrued premium: lam {:.6}, euro-world lam {:.6}, drop {:.4}; re-priced {:.4} bp and {:.4} bp",
        la, ea, g2, x_u * BP, x_e * BP);
    assert!([(r_u, 0.0150), (r_e, 0.0120), (x_u, 0.0150), (x_e, 0.0120)].iter().all(|(v, q)| (v - q).abs() < 1e-9));
    println!("Italy, first week of May 2012: 1 - 350/440 = {:.4}", 1.0 - 350.0 / 440.0);
    // ---- what breaks ----
    println!("break: spread same in any currency: euro {:.2} bp, drop 0", s_u * BP);
    println!("break: drop measured as the dollar's rise: 150/120 - 1 = {:.4}", 150.0 / 120.0 - 1.0);
    println!("break: hazard from the euro quote: {:.4} vs {:.4}; 5-year default {:.4} vs {:.4}",
        0.0120 / L, 0.0150 / L, 1.0 - (-5.0 * 0.0120 / L).exp(), 1.0 - (-5.0 * 0.0150 / L).exp());
    println!("break: euro spread converted at 1.10: {:.2} bp, drop {:.4}", 120.0 * X0, 1.0 - 120.0 * X0 / 150.0);
    // ---- try changing ----
    println!("try: gam 0.50 -> euro {:.2} bp", closed(LAM, 0.5, RF, false, false) * BP);
    println!("try: R 0.25 -> dollar {:.2} bp, euro {:.2} bp, drop {:.4}", 0.75 * LAM * BP, 0.75 * LAM * 0.8 * BP, 1.0 - 0.8);
    let r10 = closed(0.10, GAM, RF, true, false) / closed(0.10, 0.0, RD, true, false);
    let a10 = closed(0.10, GAM, RF, true, true) / closed(0.10, 0.0, RD, true, true);
    println!("try: lam 0.10 dated -> dollar {:.2} bp, euro {:.2} bp, shortcut drop {:.4}; with accrual {:.4} (at 0.025: {:.4})",
        closed(0.10, 0.0, RD, true, false) * BP, closed(0.10, GAM, RF, true, false) * BP, 1.0 - r10, 1.0 - a10, 1.0 - a_e / a_u);
    assert!((a10 - a_e / a_u).abs() < 1e-4 && 1e-4 < (r10 - q_e / q_u).abs()); // accrual takes the hazard out
    println!("try: gam -0.10 -> euro {:.2} bp", closed(LAM, -0.1, RF, false, false) * BP);
    // ---- chart: euro spread against the drop ----
    for g in [0.0, 0.1, 0.2, 0.3, 0.4, 0.5] {
        println!("chart, drop {:.1}: triangle {:.2} bp, dated {:.2} bp",
            g, closed(LAM, g, RF, false, false) * BP, closed(LAM, g, RF, true, false) * BP);
    }
    println!("ALL CHECKS PASS");
}
