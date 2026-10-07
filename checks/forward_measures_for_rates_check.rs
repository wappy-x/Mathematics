// Forward measures for rates -- the same check as forward_measures_for_rates_check.py.
// Standard library only, no crates.  Rust has no erf, so the bell-curve area is
// built by adding thin slices under the curve (Simpson), not by the Python series.
// Caplet 7 of the shelf's 2-year cap: fixed at 1.75 years, paid at 2.00, strike 5%,
// lognormal volatility 30%, $10,000,000.  Roads: Black under the pay-date bond,
// Simpson quadrature, Monte Carlo under the fix-date bond with the forward's drift.
use std::f64::consts::PI;

const TAU: f64 = 0.25; const K: f64 = 0.05; const SIG: f64 = 0.30;
const T1: f64 = 1.75; const T2: f64 = 2.0; const NOTL: f64 = 1e7;

fn phi(z: f64) -> f64 { (-z * z / 2.0).exp() / (2.0 * PI).sqrt() }

fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    s * h / 3.0
}

fn ncdf(x: f64) -> f64 {
    if x.abs() > 8.0 { return if x < 0.0 { 0.0 } else { 1.0 }; }
    0.5 + simpson(phi, 0.0, x, 4000)
}

fn black(f: f64, k: f64, sig: f64, t: f64) -> f64 {
    let v = sig * t.sqrt();
    let d1 = ((f / k).ln() + v * v / 2.0) / v;
    f * ncdf(d1) - k * ncdf(d1 - v)
}

fn quad<G: Fn(f64) -> f64>(f0: f64, g: G) -> f64 {    // E[g(F(T1))], F driftless lognormal
    let v = SIG * T1.sqrt();
    simpson(|z| g(f0 * (v * z - v * v / 2.0).exp()) * phi(z), -10.0, 10.0, 40000)
}

struct Lcg(u64);
impl Lcg {
    fn unif(&mut self) -> f64 {
        self.0 = self.0.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
        ((self.0 >> 11) as f64 + 0.5) / 9007199254740992.0
    }
    fn gauss(&mut self) -> f64 {
        let u1 = self.unif();
        (-2.0 * u1.ln()).sqrt() * (2.0 * PI * self.unif()).cos()
    }
}

fn main() {
    let fwd: Vec<f64> = (0..8).map(|i| 0.044 + 0.0005 * i as f64).collect();
    let mut d = vec![1.0_f64];
    for f in &fwd { let last = *d.last().unwrap(); d.push(last / (1.0 + TAU * f)); }
    let (f0, p1, p2) = (fwd[7], d[7], d[8]);

    let strikes: Vec<f64> = (0..9).map(|j| 0.03 + 0.005 * j as f64).collect();
    let (pairs, steps) = (100000usize, 35usize);
    let dt = T1 / steps as f64;
    let mut rng = Lcg(88172645463325252);
    let mut pay1 = [0.0_f64; 9];
    let (mut s_d, mut s_dd, mut s1, mut s11) = (0.0_f64, 0.0_f64, 0.0_f64, 0.0_f64);
    let (mut sh, mut shh, mut sf, mut sff, mut sn, mut snn) = (0.0_f64, 0.0, 0.0, 0.0, 0.0, 0.0);
    for _ in 0..pairs {
        let zs: Vec<f64> = (0..steps).map(|_| rng.gauss()).collect();
        for sign in [1.0_f64, -1.0] {
            let (mut x, mut y) = (f0.ln(), f0.ln());   // x: fix-date unit (drift), y: pay-date unit
            for z in &zs {
                let f = x.exp();
                x += (SIG * SIG * TAU * f / (1.0 + TAU * f) - SIG * SIG / 2.0) * dt + SIG * dt.sqrt() * sign * z;
                y += -SIG * SIG / 2.0 * dt + SIG * dt.sqrt() * sign * z;
            }
            let (fx, fy) = (x.exp(), y.exp());
            for j in 0..9 { pay1[j] += p1 * TAU * (fx - strikes[j]).max(0.0) / (1.0 + TAU * fx); }
            let c1 = p1 * TAU * (fx - K).max(0.0) / (1.0 + TAU * fx);
            s1 += c1; s11 += c1 * c1;
            let dd = c1 - p2 * TAU * (fy - K).max(0.0);
            s_d += dd; s_dd += dd * dd;
            let h = fx - fy; sh += h; shh += h * h;
            let g = fx / (1.0 + TAU * fx) - fy / (1.0 + TAU * f0); sf += g; sff += g * g;
            let e = p1 * TAU * (fy - K).max(0.0) / (1.0 + TAU * fy) - c1;
            sn += e; snn += e * e;
        }
    }
    let m = (2 * pairs) as f64;
    let se = |s: f64, ss: f64| ((ss / m - (s / m).powi(2)) / m).sqrt();

    let c_black = TAU * p2 * black(f0, K, SIG, T1) * NOTL;
    let c_quad = TAU * p2 * quad(f0, |f| (f - K).max(0.0)) * NOTL;
    let (c_mc1, se1) = (s1 / m * NOTL, se(s1, s11) * NOTL);
    let (diff, se_d) = (s_d / m * NOTL, se(s_d, s_dd) * NOTL);
    let mean_fix = (f0 + TAU * f0 * f0 * (SIG * SIG * T1).exp()) / (1.0 + TAU * f0);
    let no_drift = p1 * TAU * quad(f0, |f| (f - K).max(0.0) / (1.0 + TAU * f)) * NOTL;
    let v = SIG * T1.sqrt();
    let d1 = ((f0 / K).ln() + v * v / 2.0) / v;
    let out: Vec<(&str, f64, usize)> = vec![
        ("fix-date bond P(0,1.75)", p1, 6), ("pay-date bond P(0,2.00)", p2, 6),
        ("forward F(0), percent", 100.0 * f0, 4), ("sigma sqrt(T1)", v, 6),
        ("d1", d1, 6), ("d2", d1 - v, 6), ("N(d1)", ncdf(d1), 6), ("N(d2)", ncdf(d1 - v), 6),
        ("F N(d1) - K N(d2), percent", 100.0 * black(f0, K, SIG, T1), 6),
        ("1 Black, pay-date unit $", c_black, 2), ("2 Simpson quadrature $", c_quad, 2),
        ("3 MC, fix-date unit + drift $", c_mc1, 2), ("  standard error $", se1, 2),
        ("  road 3 minus pay-date road, MC $", diff, 2), ("  its standard error $", se_d, 2),
        ("mean F(1.75) under fix-date unit %", 100.0 * mean_fix, 4),
        ("  its lift over F(0), bp, exact", 1e4 * (mean_fix - f0), 4),
        ("  its lift over F(0), bp, MC paired", 1e4 * sh / m, 4),
        ("  standard error, bp", 1e4 * se(sh, shh), 4),
        ("fair bet F/(1+tau F) gap, bp, MC", 1e4 * sf / m, 4),
        ("  standard error, bp", 1e4 * se(sf, sff), 4),
        ("wrong: discount from fix date $", TAU * p1 * black(f0, K, SIG, T1) * NOTL, 2),
        ("wrong: no accrual fraction $", p2 * black(f0, K, SIG, T1) * NOTL, 2),
        ("wrong: volatility to pay date $", TAU * p2 * black(f0, K, SIG, T2) * NOTL, 2),
        ("wrong: fix-date unit, no drift $", no_drift, 2),
        ("  its error, quadrature $", no_drift - c_black, 2),
        ("  its error, MC paired $", sn / m * NOTL, 2),
    ];
    for (name, val, dp) in &out { println!("{:<38}{:>16.*}", name, *dp, val); }
    let row = |xs: Vec<f64>| xs.iter().map(|x| format!("{:8.0}", x)).collect::<Vec<_>>().join(" ");
    let strike_row: Vec<String> = strikes.iter().map(|k| format!("{:8.2}", 100.0 * k)).collect();
    println!("chart, strike %      {}", strike_row.join(" "));
    println!("chart, Black $       {}", row(strikes.iter().map(|&k| TAU * p2 * black(f0, k, SIG, T1) * NOTL).collect()));
    println!("chart, MC fix-date $ {}", row(pay1.iter().map(|p| p / m * NOTL).collect()));

    assert!((c_quad - c_black).abs() < 1e-4, "quadrature road vs Black's formula");
    assert!((c_black - 14793.71).abs() < 0.005, "caplet 7 as priced on the caps shelf");
    assert!((c_mc1 - c_black).abs() < 4.0 * se1, "fix-date-unit simulation vs Black");
    assert!(diff.abs() < 4.0 * se_d, "paired: fix-date road vs pay-date road, path by path");
    assert!((sh / m - (mean_fix - f0)).abs() < 4.0 * se(sh, shh), "forward drifts under the fix-date unit");
    assert!((sf / m).abs() < 4.0 * se(sf, sff), "F/(1+tau F) is the fair bet there instead");
    assert!((sn / m * NOTL - (no_drift - c_black)).abs() < 4.0 * se(sn, snn) * NOTL, "the no-drift error, two roads");
    println!("ALL CHECKS PASS");
}
