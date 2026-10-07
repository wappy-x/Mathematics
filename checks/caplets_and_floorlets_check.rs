// Caplets and floorlets -- the same check as caplets_and_floorlets_check.py, in Rust.
// Standard library only, no crates.  Rust has no erf, so the bell-curve area N(x) is
// built another way: add up thin slices under the curve (Simpson's rule).
use std::f64::consts::PI;

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }

fn simpson<G: Fn(f64) -> f64>(f: G, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    s * h / 3.0
}

fn ncdf(x: f64) -> f64 {                                 // area left of x: one half plus the slice 0..x
    if x.abs() > 8.0 { return if x < 0.0 { 0.0 } else { 1.0 }; }
    0.5 + simpson(phi, 0.0, x, 4000)
}

fn black(f: f64, k: f64, sig: f64, t: f64, cp: f64) -> f64 {   // Black-76 per unit of rate
    let v = sig * t.sqrt();
    let d1 = ((f / k).ln() + 0.5 * v * v) / v;
    cp * (f * ncdf(cp * d1) - k * ncdf(cp * (d1 - v)))
}

fn average<G: Fn(f64) -> f64>(f: f64, sig: f64, t: f64, g: G, kink: f64) -> f64 {  // E[g(L)], L lognormal
    let h = |z: f64| g(f * (-0.5 * sig * sig * t + sig * t.sqrt() * z).exp()) * phi(z);
    simpson(&h, -10.0, kink, 4000) + simpson(&h, kink, 10.0, 4000)
}

struct Rng(u64);
impl Rng {
    fn uniform(&mut self) -> f64 {
        self.0 ^= self.0 << 13; self.0 ^= self.0 >> 7; self.0 ^= self.0 << 17;
        ((self.0 >> 11) as f64 + 0.5) / 9007199254740992.0
    }
}

fn main() {
    let (m, tau, k, sig, r, t1, t2) = (10_000_000.0_f64, 0.25_f64, 0.05_f64, 0.30_f64, 0.05_f64, 2.5_f64, 2.75_f64);
    let d = |t: f64| (-r * t).exp();
    let (d1f, d2f) = (d(t1), d(t2));
    let f = (d1f / d2f - 1.0) / tau;                     // the forward rate, read from two bond prices
    let v = sig * t1.sqrt();
    let d1 = ((f / k).ln() + 0.5 * v * v) / v;
    let d2 = d1 - v;
    let cpl = m * tau * d2f * black(f, k, sig, t1, 1.0);
    let flr = m * tau * d2f * black(f, k, sig, t1, -1.0);
    let kz = ((k / f).ln() + 0.5 * v * v) / v;
    let mut rows: Vec<(&str, f64, usize)> = vec![
        ("D(T1) reset 2.5y", d1f, 6), ("D(T2) payment 2.75y", d2f, 6), ("forward rate F", f, 8),
        ("sigma sqrt(T1)", v, 6), ("d1", d1, 6), ("d2", d2, 6), ("N(d1)", ncdf(d1), 6), ("N(d2)", ncdf(d2), 6),
        ("F N(d1)", f * ncdf(d1), 8), ("K N(d2)", k * ncdf(d2), 8), ("Black value, rate units", f * ncdf(d1) - k * ncdf(d2), 8),
        ("M tau D(T2)", m * tau * d2f, 2), ("1 CAPLET, formula", cpl, 2), ("  per cent of notional", 100.0 * cpl / m, 4),
        ("  breakeven fixing, per cent", 100.0 * (k + cpl / (m * tau * d2f)), 4), ("FLOORLET, formula", flr, 2)];

    let cpl_int = m * tau * d2f * average(f, sig, t1, |l| (l - k).max(0.0), kz);
    let flr_int = m * tau * d2f * average(f, sig, t1, |l| (k - l).max(0.0), kz);
    let mean_l = average(f, sig, t1, |l| l, kz);
    rows.extend([("2 CAPLET, Simpson integral", cpl_int, 2), ("  FLOORLET, Simpson integral", flr_int, 2),
                 ("  average fixing (must be F)", mean_l, 8)]);

    let mut rng = Rng(88172645463325252);
    let (n_mc, mut s1, mut s2) = (200_000usize, 0.0_f64, 0.0_f64);
    for _ in 0..n_mc {
        let u1 = rng.uniform(); let u2 = rng.uniform();
        let z = (-2.0 * u1.ln()).sqrt() * (2.0 * PI * u2).cos();
        let p = m * tau * d2f * (f * (-0.5 * v * v + v * z).exp() - k).max(0.0);
        s1 += p; s2 += p * p;
    }
    let mc = s1 / n_mc as f64;
    let se = ((s2 / n_mc as f64 - mc * mc) / n_mc as f64).sqrt();
    rows.extend([("3 CAPLET, Monte Carlo 200k", mc, 2), ("  standard error", se, 2)]);

    let x = |l: f64| 1.0 / (1.0 + tau * l);              // price at T1 of $1 paid at T2
    let w = |l: f64| (d2f / d1f) / x(l);                  // payment-date odds -> reset-date odds
    let kb = 1.0 / (1.0 + tau * k);
    let w_mean = average(f, sig, t1, w, kz);
    let bond_put = m * (1.0 + tau * k) * d1f * average(f, sig, t1, |l| w(l) * (kb - x(l)).max(0.0), kz);
    rows.extend([("4 bond strike 1/(1+tau K)", kb, 8), ("  average reweighting (must be 1)", w_mean, 10),
                 ("  CAPLET as bond puts, reset-date odds", bond_put, 2)]);

    let fra = m * tau * d2f * (f - k);
    rows.extend([("caplet - floorlet (floorlet by integral)", cpl - flr_int, 4), ("M tau D(T2) (F - K)", fra, 4)]);

    let (lu, ld) = (0.08_f64, 0.03_f64);
    let pu = (d2f - d1f * x(ld)) / (x(lu) - x(ld));
    let pd = d1f - pu;                                    // state prices at T1
    let bank = (pu * lu + pd * ld) / d1f;
    let fwd = (pu * x(lu) * lu + pd * x(ld) * ld) / d2f;
    let true2 = m * tau * (pu * x(lu) * (lu - k).max(0.0) + pd * x(ld) * (ld - k).max(0.0));
    let wrong2 = m * tau * d2f * (pu * (lu - k).max(0.0) + pd * (ld - k).max(0.0)) / d1f;
    rows.extend([("toy: state price, rate 8%", pu, 6), ("toy: state price, rate 3%", pd, 6),
                 ("toy: average rate, reset-bond odds", bank, 8), ("toy: average rate, payment-bond odds", fwd, 8),
                 ("toy: caplet, state prices", true2, 2), ("toy: caplet, wrong odds", wrong2, 2)]);

    let dlt = m * tau * d2f * ncdf(d1) * 1e-4;
    let vga = m * tau * d2f * f * phi(d1) * t1.sqrt() * 0.01;
    let b = 1e-6;
    let dlt_b = m * tau * d2f * (black(f + b, k, sig, t1, 1.0) - black(f - b, k, sig, t1, 1.0)) / (2.0 * b) * 1e-4;
    let vga_b = m * tau * d2f * (black(f, k, sig + b, t1, 1.0) - black(f, k, sig - b, t1, 1.0)) / (2.0 * b) * 0.01;
    rows.extend([("delta per 1bp of F, formula", dlt, 4), ("delta per 1bp of F, bump", dlt_b, 4),
                 ("floorlet delta per 1bp", -m * tau * d2f * ncdf(-d1) * 1e-4, 4),
                 ("vega per vol point, formula", vga, 4), ("vega per vol point, bump", vga_b, 4)]);

    let c = |f_: f64, k_: f64, s_: f64, t_: f64, dd: f64, a: f64| m * a * dd * black(f_, k_, s_, t_, 1.0);
    let fq = |rr: f64, a: f64, bb: f64| ((rr * (bb - a)).exp() - 1.0) / (bb - a);
    rows.extend([("wrong: discount to reset date", c(f, k, sig, t1, d1f, tau), 2),
                 ("wrong: vol clock to payment date", c(f, k, sig, t2, d2f, tau), 2),
                 ("wrong: curve's 5% read as F", c(0.05, k, sig, t1, d2f, tau), 2),
                 ("wrong: no accrual tau", c(f, k, sig, t1, d2f, 1.0), 2),
                 ("wrong: N(d2) on both sides", m * tau * d2f * (f - k) * ncdf(d2), 2),
                 ("try: sigma = 0.20", c(f, k, 0.20, t1, d2f, tau), 2), ("try: K = 5.5%", c(f, 0.055, sig, t1, d2f, tau), 2),
                 ("try: fixes 1y, pays 1.25y", c(f, k, sig, 1.0, d(1.25), tau), 2),
                 ("try: curve at 4%", c(fq(0.04, t1, t2), k, sig, t1, (-0.04 * t2).exp(), tau), 2)]);
    let mut dq = vec![1.0_f64];
    for i in 0..8 { let last = dq[dq.len() - 1]; dq.push(last / (1.0 + 0.25 * (0.044 + 0.0005 * i as f64))); }
    rows.push(("shelf: caplet 7 of the 2-year cap", c(0.0475, k, sig, 1.75, dq[8], tau), 2));
    for (name, val, dp) in &rows { println!("{:<42}{:>16.*}", name, *dp, val); }

    let fix: Vec<f64> = (0..9).map(|i| 3.0 + 0.5 * i as f64).collect();
    let join = |g: &dyn Fn(f64) -> String| fix.iter().map(|&x| g(x)).collect::<Vec<_>>().join(" ");
    println!("chart, fixing %  {}", join(&|x| format!("{:.1}", x)));
    println!("chart, payoff    {}", join(&|x| format!("{:.0}", m * tau * (x / 100.0 - k).max(0.0))));
    println!("chart, profit    {}", join(&|x| format!("{:.0}", m * tau * (x / 100.0 - k).max(0.0) - cpl / d2f)));

    assert!((cpl_int - cpl).abs() < 1e-4, "Simpson road must land on the formula");
    assert!((mc - cpl).abs() < 3.0 * se, "Monte Carlo within three standard errors");
    assert!((bond_put - cpl).abs() < 1e-4, "bond-put road under reset-date odds must agree");
    assert!(((cpl - flr_int) - fra).abs() < 1e-4, "caplet - floorlet must equal the FRA");
    assert!((fwd - f).abs() < 1e-12, "payment-date odds make the forward a fair bet");
    assert!((dlt_b - dlt).abs() < 1e-4, "delta by bump matches N(d1)");
    assert!((vga_b - vga).abs() < 1e-4, "vega by bump matches the formula");
    assert!((mean_l - f).abs() < 1e-12, "under payment-date odds the fixing averages to F");
    assert!((w_mean - 1.0).abs() < 1e-12, "the reweighting averages to 1");
    println!("ALL CHECKS PASS");
}
