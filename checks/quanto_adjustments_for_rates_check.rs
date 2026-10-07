// Quanto rates: a yen rate paid in dollars at a fixed conversion.  Rust std only.
// Every number quoted on the card is printed here.  The normal density, the Simpson
// integrator and the bisection root finder are written out below.

const NG: usize = 160;
const LO: f64 = -8.0;
const HI: f64 = 8.0;

fn phi(z: f64) -> f64 { (-0.5 * z * z).exp() / (2.0 * std::f64::consts::PI).sqrt() }

struct Grid { z: Vec<f64>, w: Vec<f64> }

impl Grid {
    fn new() -> Grid {
        let h = (HI - LO) / NG as f64;
        let z: Vec<f64> = (0..=NG).map(|i| LO + i as f64 * h).collect();
        let w = z.iter().enumerate().map(|(i, &x)| {
            let c = if i == 0 || i == NG { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 };
            c * h / 3.0 * phi(x)
        }).collect();
        Grid { z, w }
    }
    fn avg1(&self, f: impl Fn(f64) -> f64) -> f64 {   // E[f(Z)], Z standard normal
        let mut t = 0.0;
        for i in 0..=NG { t += self.w[i] * f(self.z[i]); }
        t
    }
    fn avg2(&self, f: impl Fn(f64, f64) -> f64, rho: f64) -> f64 {   // E[f(Z1, Z2)], correlation rho
        let c = (1.0 - rho * rho).sqrt();
        let mut t = 0.0;
        for i in 0..=NG {
            let z1 = self.z[i];
            let mut inner = 0.0;
            for j in 0..=NG { inner += self.w[j] * f(z1, rho * z1 + c * self.z[j]); }
            t += self.w[i] * inner;
        }
        t
    }
}

fn lognormal(f0: f64, vol: f64, t: f64, z: f64) -> f64 { f0 * (vol * t.sqrt() * z - 0.5 * vol * vol * t).exp() }
fn formula(f: f64, sf: f64, sg: f64, rho: f64, t: f64) -> f64 { f * (-rho * sf * sg * t).exp() }   // road 1
fn m(s: f64) -> f64 { s / (1.0 + s) / (1.0 - (1.0 + s).powf(-10.0)) }   // D_f(T,T+1) / A_T, flat yen curve

fn cms(g: &Grid, s0: f64, ss: f64, t: f64) -> f64 {
    g.avg1(|z| lognormal(s0, ss, t, z) * m(lognormal(s0, ss, t, z))) / g.avg1(|z| m(lognormal(s0, ss, t, z)))
}
fn cms_quanto_2d(g: &Grid, s0: f64, ss: f64, sg: f64, rho: f64, t: f64) -> f64 {   // weight m(S)/G
    let wt = |a: f64, b: f64| m(lognormal(s0, ss, t, a)) * (-sg * t.sqrt() * b).exp();
    g.avg2(|a, b| lognormal(s0, ss, t, a) * wt(a, b), rho) / g.avg2(wt, rho)
}

fn main() {
    let g = Grid::new();
    // ---- contract A: 3-month yen rate fixing at T = 1, paid in dollars at U = 1.25 ----
    let (f, sf, sg, rho, t, u, delta) = (0.03, 0.30, 0.10, 0.40, 1.0, 1.25, 0.25);
    let (chi, nf, dd) = (0.01, 100_000_000.0, 0.98);
    let scale = chi * nf * delta * dd;
    let k1 = formula(f, sf, sg, rho, t);
    // road 2: yen forward measure, each outcome weighted by 1/G
    let h = |_a: f64, b: f64| (-sg * t.sqrt() * b).exp();
    let k2 = g.avg2(|a, b| lognormal(f, sf, t, a) * h(a, b), rho) / g.avg2(h, rho);
    // road 3: dollar measure, G driftless; find the drift that makes a market-FX yen FRA worth zero
    let fra = |mu: f64| g.avg2(|a, b| lognormal(1.0, sg, t, b) * (f * (mu * t + sf * t.sqrt() * a - 0.5 * sf * sf * t).exp() - f), rho);
    let (mut lo, mut hi) = (-0.5, 0.5);
    let mut flo = fra(lo);
    for _ in 0..60 {
        let mid = 0.5 * (lo + hi);
        let fm = fra(mid);
        if flo * fm <= 0.0 { hi = mid; } else { lo = mid; flo = fm; }
    }
    let mu = 0.5 * (lo + hi);
    let k3 = f * (mu * t).exp();
    assert!((k2 - k1).abs() < 1e-12);   // reweighting agrees with the drift
    assert!((k3 - k1).abs() < 1e-12);   // root-found drift agrees too

    // ---- three states by hand ----
    let qf = [0.25, 0.5, 0.25];
    let r = [0.01, 0.03, 0.05];
    let x = [0.008, 0.010, 0.012];
    let w: Vec<f64> = x.iter().map(|v| 1.0 / v).collect();
    let dot = |a: &[f64], b: &[f64]| { let mut s = 0.0; for i in 0..a.len() { s += a[i] * b[i]; } s };
    let wbar = dot(&qf, &w);
    let qd: Vec<f64> = (0..3).map(|i| qf[i] * w[i] / wbar).collect();
    let (f3, k_toy) = (dot(&qf, &r), dot(&qd, &r));
    let rw: Vec<f64> = (0..3).map(|i| r[i] * w[i]).collect();
    let cov = dot(&qf, &rw) - f3 * wbar;
    let dd_toy = 0.01 * 0.96 * wbar;
    assert!((k_toy - 137.0 / 4900.0).abs() < 1e-15);   // dollar probabilities, exact fraction
    assert!((f3 + cov / wbar - k_toy).abs() < 1e-15);  // covariance form, same answer
    assert!((dd_toy - 0.98).abs() < 1e-15);
    let pv_toy = chi * nf * delta * dd_toy * (k_toy - 0.03);
    assert!((pv_toy + 500.0).abs() < 1e-9);

    // ---- contract B: 10-year yen swap rate fixing at T = 1, paid in dollars at T + 1 ----
    let (s0, ss) = (0.03, 0.25);
    let kc_yen = cms(&g, s0, ss, t);
    let kc_2d = cms_quanto_2d(&g, s0, ss, sg, rho, t);
    let kc_shift = cms(&g, s0 * (-rho * ss * sg * t).exp(), ss, t);
    let kc_prod = kc_yen * (-rho * ss * sg * t).exp();
    let kc_rho0 = cms_quanto_2d(&g, s0, ss, sg, 0.0, t);
    assert!((kc_2d - kc_shift).abs() < 1e-12);   // 2-D weight = shifted forward
    assert!((kc_rho0 - kc_yen).abs() < 1e-12);   // no correlation, no quanto part
    assert!((kc_prod - kc_2d).abs() > 1e-7 && (kc_prod - kc_2d).abs() < 1e-5);   // close, not exact

    // ---- sensitivities of contract A's value at strike 3%: analytic against bumped ----
    let value = |f_: f64, sf_: f64, sg_: f64, rho_: f64| scale * (formula(f_, sf_, sg_, rho_, t) - 0.03);
    let e = 1e-6;
    let greeks = [
        ("per 1 bp of yen forward", scale * 1e-4 * (-rho * sf * sg * t).exp(), (value(f + e, sf, sg, rho) - value(f - e, sf, sg, rho)) / 2e-6 * 1e-4),
        ("per 0.01 of correlation", -scale * 0.01 * sf * sg * t * k1, (value(f, sf, sg, rho + e) - value(f, sf, sg, rho - e)) / 2e-6 * 0.01),
        ("per 1 vol point of FX", -scale * 0.01 * rho * sf * t * k1, (value(f, sf, sg + e, rho) - value(f, sf, sg - e, rho)) / 2e-6 * 0.01),
        ("per 1 vol point of rate", -scale * 0.01 * rho * sg * t * k1, (value(f, sf + e, sg, rho) - value(f, sf - e, sg, rho)) / 2e-6 * 0.01),
    ];
    for gk in greeks.iter() { assert!((gk.1 - gk.2).abs() < 1e-5); }

    let bp = |v: f64| 1e4 * v;
    let rows: Vec<(&str, f64)> = vec![
        ("A yen forward F (%)", 100.0 * f), ("A rho*sF*sG*T", rho * sf * sg * t),
        ("A shrink factor e^-(that)", (-rho * sf * sg * t).exp()),
        ("A 1 formula K_q (%)", 100.0 * k1), ("A 2 reweighted by 1/G (%)", 100.0 * k2),
        ("A 3 drift found by root", mu), ("A 3 K_q from that drift (%)", 100.0 * k3),
        ("A adjustment (bp)", bp(k1 - f)), ("A value at 3% strike ($)", scale * (k1 - f)),
        ("A dollars at U per unit rate", chi * nf * delta),
        ("A dollars at U per 1% of rate", chi * nf * delta / 100.0), ("A dollars today per unit rate", scale),
        ("toy weight 1/X, rate 1%", w[0]), ("toy weight 1/X, rate 3%", w[1]), ("toy weight 1/X, rate 5%", w[2]),
        ("toy weight mean E[1/X]", wbar), ("toy D_d(0,U)", dd_toy),
        ("toy dollar prob, rate 1%", qd[0]), ("toy dollar prob, rate 3%", qd[1]), ("toy dollar prob, rate 5%", qd[2]),
        ("toy covariance", cov), ("toy K_q (%)", 100.0 * k_toy), ("toy adjustment (bp)", bp(k_toy - f3)),
        ("toy value at 3% ($)", pv_toy),
        ("B yen CMS rate (%)", 100.0 * kc_yen), ("B yen convexity (bp)", bp(kc_yen - s0)),
        ("B 1 quanto CMS, 2-D (%)", 100.0 * kc_2d), ("B shifted forward (%)", 100.0 * s0 * (-rho * ss * sg * t).exp()),
        ("B 2 shift then CMS (%)", 100.0 * kc_shift),
        ("B 3 product of the two (%)", 100.0 * kc_prod), ("B total adjustment (bp)", bp(kc_2d - s0)),
        ("B quanto part (bp)", bp(kc_2d - kc_yen)), ("B product error (bp)", bp(kc_prod - kc_2d)),
        ("wrong: no quanto (%)", 100.0 * f), ("wrong: sign flipped (%)", 100.0 * f * (rho * sf * sg * t).exp()),
        ("wrong: payment clock U (%)", 100.0 * formula(f, sf, sg, rho, u)),
        ("try: rho = -0.40 (%)", 100.0 * formula(f, sf, sg, -rho, t)), ("try: sG = 0.20 (%)", 100.0 * formula(f, sf, 0.20, rho, t)),
        ("try: B at rho = -0.40 (%)", 100.0 * cms_quanto_2d(&g, s0, ss, sg, -rho, t)),
    ];
    for (name, v) in rows.iter() { println!("{:<30} {:>16.10}", name, v); }
    for gk in greeks.iter() { println!("greek {:<24} {:>12.6} {:>12.6}", gk.0, gk.1, gk.2); }
    let xs = [1.0, 2.0, 3.0, 4.0, 5.0];
    println!("payoff, yen rate (%)      {}", xs.iter().map(|v| format!("{:>10.2}", v)).collect::<String>());
    println!("payoff, dollars at K_q    {}", xs.iter().map(|v| format!("{:>10.2}", chi * nf * delta * (v / 100.0 - k1))).collect::<String>());
    for r_ in [0.4, 0.0, -0.4] {
        let line: String = (1..=10).map(|tt| format!("{:>6.2}", 100.0 * formula(f, sf, sg, r_, tt as f64))).collect();
        println!("chart rho {:+.1}, K_q (%)  {}", r_, line);
    }
    println!("ALL CHECKS PASS");
}
