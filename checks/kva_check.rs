// KVA on the Acme call bought from Northwind: capital cost over the trade's life.
// Standard library only, no crates. The bell-curve area, its inverse, the
// integrator and the random numbers are all written here.
use std::f64::consts::PI;

const S0: f64 = 100.0; const K: f64 = 100.0; const R_: f64 = 0.05; const Q: f64 = 0.02;
const SIG: f64 = 0.20; const T: f64 = 1.0;
const LAM: f64 = 0.02; const REC: f64 = 0.40;               // Northwind's hazard and recovery
const H: f64 = 0.10; const ALPHA: f64 = 1.4; const RATIO: f64 = 0.08; const RW: f64 = 1.00;

fn n_cdf(x: f64) -> f64 {                                  // positive-term erf series
    if x > 12.0 { return 1.0; }
    if x < -12.0 { return 0.0; }
    let z = x.abs() / 2f64.sqrt();
    let (mut term, mut total, mut n) = (z, z, 0.0);
    while term > 1e-17 * total {
        n += 1.0;
        term *= 2.0 * z * z / (2.0 * n + 1.0);
        total += term;
    }
    let half = (-z * z).exp() * total / PI.sqrt();         // erf(z) / 2
    if x >= 0.0 { 0.5 + half } else { 0.5 - half }
}

fn n_inv(u: f64) -> f64 {                                  // bisection root finder on N
    let (mut lo, mut hi) = (-12.0, 12.0);
    for _ in 0..200 {
        let mid = 0.5 * (lo + hi);
        if n_cdf(mid) < u { lo = mid; } else { hi = mid; }
    }
    0.5 * (lo + hi)
}

fn call(s: f64, tau: f64) -> f64 {
    if tau <= 0.0 { return (s - K).max(0.0); }
    let v = SIG * tau.sqrt();
    let d1 = ((s / K).ln() + (R_ - Q + 0.5 * SIG * SIG) * tau) / v;
    s * (-Q * tau).exp() * n_cdf(d1) - K * (-R_ * tau).exp() * n_cdf(d1 - v)
}

fn addon(s: f64, tau: f64) -> f64 {                        // SA-CCR add-on, bought equity call
    let m = tau.max(10.0 / 250.0);                         // maturity factor, floored at 10 days
    let d = if tau <= 0.0 { if s > K { 40.0 } else { -40.0 } }   // delta at expiry: 1 or 0
            else { ((s / K).ln() + 0.72 * tau) / (1.2 * tau.sqrt()) };   // time to expiry, vol 120%
    0.32 * n_cdf(d) * s * m.min(1.0).sqrt()
}

fn s_at(t: f64, z: f64) -> f64 { S0 * ((R_ - Q - 0.5 * SIG * SIG) * t + SIG * t.sqrt() * z).exp() }

fn avg(f: fn(f64, f64) -> f64, t: f64, n: usize) -> f64 { // Simpson over the bell curve
    if t == 0.0 { return f(S0, T); }
    let (a, w) = (-8.0, 16.0 / n as f64);
    let mut tot = 0.0;
    for i in 0..=n {
        let z = a + i as f64 * w;
        let wt = if i == 0 || i == n { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 };
        tot += wt * f(s_at(t, z), T - t) * (-0.5 * z * z).exp();
    }
    tot * w / 3.0 / (2.0 * PI).sqrt()
}

struct Rng(u64);
impl Rng {                                                 // splitmix64, same stream as Python
    fn u(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut x = self.0;
        x = (x ^ (x >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        x = (x ^ (x >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((x ^ (x >> 31)) >> 11) as f64 * 2f64.powi(-53) + 2f64.powi(-54)
    }
}

fn main() {
    let c = RATIO * RW * ALPHA;                            // capital per $1 of exposure
    let c0 = call(S0, T);
    let cva = (1.0 - REC) * c0 * (1.0 - (-LAM * T).exp());
    let life = (1.0 - (-LAM * T).exp()) / LAM;
    let kva_closed = H * c * c0 * life;                    // road 1

    let (mut kva_wk, mut kva_wk_rh, mut kva_sa) = (0.0, 0.0, 0.0);   // road 2
    for i in 0..52 {
        let (t, dt) = ((i as f64 + 0.5) / 52.0, 1.0 / 52.0);
        let ee = avg(call, t, 200);
        let ea = avg(addon, t, 200);
        let w = H * (-(R_ + LAM) * t).exp() * dt;
        kva_wk += w * c * ee;
        kva_wk_rh += w * c * ee * (-H * t).exp();
        kva_sa += w * c * (ee + ea);
    }

    let mut rng = Rng(20260928);                           // road 3
    let m = 100000usize;
    let (mut s1, mut s2, mut sa1, mut sa2) = (0.0, 0.0, 0.0, 0.0);
    for _ in 0..m {
        let t = rng.u() * T;
        let z = (-2.0 * rng.u().ln()).sqrt() * (2.0 * PI * rng.u()).cos();
        let s = s_at(t, z);
        let base = H * (-(R_ + LAM) * t).exp() * T * c;
        let (x, y) = (base * call(s, T - t), base * (call(s, T - t) + addon(s, T - t)));
        s1 += x; s2 += x * x; sa1 += y; sa2 += y * y;
    }
    let mf = m as f64;
    let (kva_mc, kva_mc_sa) = (s1 / mf, sa1 / mf);
    let se = ((s2 / mf - kva_mc * kva_mc) / mf).sqrt();
    let se_sa = ((sa2 / mf - kva_mc_sa * kva_mc_sa) / mf).sqrt();

    let (pd, lgd) = (0.02f64, 0.60);                       // Basel IRB, M = 1
    let wgt = (1.0 - (-50.0 * pd).exp()) / (1.0 - (-50.0f64).exp());
    let rho = 0.12 * wgt + 0.24 * (1.0 - wgt);
    let x999 = n_cdf((n_inv(pd) + rho.sqrt() * n_inv(0.999)) / (1.0 - rho).sqrt());
    let k_irb = lgd * (x999 - pd);
    let kva_irb = H * ALPHA * k_irb * c0 * life;

    let rows: Vec<(&str, f64)> = vec![
        ("clean call C0", c0), ("CVA, Northwind 2%, R 40%", cva),
        ("capital per $ of exposure c", c), ("EAD today 1.4 x C0", ALPHA * c0),
        ("capital today 0.112 x C0", c * c0), ("survival integral", life),
        ("1 KVA closed form", kva_closed), ("2 KVA 52 weekly buckets", kva_wk),
        ("3 KVA Monte Carlo", kva_mc), ("  MC standard error", se),
        ("KVA / CVA", kva_closed / cva), ("running rate, CVA (1-R) lam", (1.0 - REC) * LAM),
        ("running rate, KVA h c", H * c), ("Northwind 1-year default", 1.0 - (-LAM).exp()),
        ("IRB correlation", rho), ("IRB 99.9% default rate", x999),
        ("IRB capital per $ of EAD", k_irb), ("IRB risk weight", 12.5 * k_irb),
        ("rule: simple 8% x 100%", kva_closed), ("rule: IRB", kva_irb),
        ("rule: SA-CCR, weekly", kva_sa), ("rule: SA-CCR, Monte Carlo", kva_mc_sa),
        ("  MC standard error", se_sa), ("SA-CCR add-on today", addon(S0, T)),
        ("SA-CCR EAD today", ALPHA * (c0 + addon(S0, T))),
        ("hurdle 8%", 0.08 / H * kva_closed), ("hurdle 12%", 0.12 / H * kva_closed),
        ("charge h - r = 5%", (H - R_) / H * kva_closed),
        ("discount at r + h, weekly", kva_wk_rh),
        ("discount at r + h, closed", H * c * c0 * (1.0 - (-(LAM + H)).exp()) / (LAM + H)),
        ("capital frozen at today's", H * c * c0 * (1.0 - (-(R_ + LAM)).exp()) / (R_ + LAM)),
        ("wrong: no survival", H * c * c0 * T), ("wrong: no alpha", H * RATIO * c0 * life),
        ("wrong: no discount", H * c * c0 * (((R_ - LAM) * T).exp() - 1.0) / (R_ - LAM)),
        ("wrong: hurdle on EAD itself", H * ALPHA * c0 * life), ("KVA + CVA", kva_closed + cva),
        ("try: hurdle 15%", 0.15 / H * kva_closed), ("try: risk weight 20%", 0.20 * kva_closed),
        ("try: hazard 10%, KVA", H * c * c0 * (1.0 - (-0.1f64).exp()) / 0.1),
        ("try: hazard 10%, CVA", (1.0 - REC) * c0 * (1.0 - (-0.1f64).exp())),
    ];
    for (name, v) in &rows { println!("{:<30} {:>12.6}", name, v); }
    println!("chart, expected capital by month (t dollars)");
    for mo in [0, 3, 6, 9, 12] {
        let t = mo as f64 / 12.0;
        let (e, a) = (avg(call, t, 2000), avg(addon, t, 2000));
        println!("  month {:>2}  simple {:6.2}  SA-CCR {:6.2}", mo, c * e, c * (e + a));
    }

    assert!((kva_wk - kva_closed).abs() < 1e-7, "weekly Simpson sum vs closed form");
    assert!((kva_mc - kva_closed).abs() < 4.0 * se, "Monte Carlo vs closed form");
    assert!((kva_mc_sa - kva_sa).abs() < 4.0 * se_sa, "SA-CCR: Monte Carlo vs weekly sum");
    assert!((avg(call, T, 2000) - c0 * (R_ * T).exp()).abs() < 1e-4, "payoff at expiry vs C0 grown at r");
    assert!((k_irb - 0.1022).abs() < 5e-5, "IRB capital vs the Vasicek card's 10.22 per 100");
    println!("ALL CHECKS PASS");
}
