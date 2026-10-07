// Credibility and reinsurance -- the same check as credibility_and_reinsurance_check.py, in Rust.
// Standard library only, no crates.  Poisson probabilities, Simpson's rule and the
// random numbers are written out below.
fn pois(lam: f64, k: usize) -> Vec<f64> {                  // Poisson probabilities P(0..k), ratio rule
    let mut p = vec![(-lam).exp()];
    for i in 1..=k { let last = p[i - 1]; p.push(last * lam / i as f64); }
    p
}
struct Lcg { s: u64 }                                      // 64-bit linear congruential generator
impl Lcg {
    fn u(&mut self) -> f64 {
        self.s = self.s.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
        (self.s >> 11) as f64 / 9007199254740992.0
    }
    fn poisson(&mut self, lam: f64) -> u32 {               // inversion: walk up the cumulative probabilities
        let u = self.u();
        let (mut k, mut p) = (0u32, (-lam).exp());
        let mut c = p;
        while u > c { k += 1; p *= lam / k as f64; c += p; }
        k
    }
}
fn simpson<F: Fn(f64) -> f64>(f: F, lo: f64, hi: f64, m: usize) -> f64 {
    let h = (hi - lo) / m as f64;
    let mut s = 0.0;
    for i in 0..=m { s += (if i == 0 || i == m { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 }) * f(lo + i as f64 * h); }
    h / 3.0 * s
}
fn zof(n: f64, a: f64, s: f64) -> f64 { n / (n + s / a) }
const SEV: [f64; 2] = [1.0, 4.0];                          // claim sizes in $000, equally likely
fn xl_formula(lam: f64, d: f64) -> f64 { lam * SEV.iter().map(|y| (y - d).max(0.0)).sum::<f64>() / 2.0 }
fn sl_formula(lam: f64, dd: f64) -> f64 {                  // E S - D + sum over totals below D of (D - k) P(S = k)
    let p0 = (-lam).exp();
    let below = [p0, p0 * lam / 2.0, p0 * lam * lam / 8.0];
    lam * 2.5 - dd + (0..3).filter(|&k| (k as f64) < dd).map(|k| (dd - k as f64) * below[k]).sum::<f64>()
}
fn s_law(lam: f64, nmax: usize) -> Vec<f64> {              // exact law of the annual total S
    let pn = pois(lam, nmax);
    let mut law = vec![0.0; 4 * nmax + 1];
    for nn in 0..=nmax {
        let mut c = 1.0;
        for b in 0..=nn {                                  // b of the nn claims are $4,000 ones
            law[nn + 3 * b] += pn[nn] * c / 2f64.powi(nn as i32);
            c = c * (nn - b) as f64 / (b + 1) as f64;
        }
    }
    law
}
fn sl_of(law: &[f64], dd: f64) -> f64 { law.iter().enumerate().map(|(k, p)| (k as f64 - dd).max(0.0) * p).sum() }
fn main() {
    let types = [1.0_f64, 3.0];
    let years = [1.0_f64, 1.0, 2.0];
    let n = 3.0;
    let mu = (types[0] + types[1]) / 2.0;
    let a = types.iter().map(|t| (t - mu).powi(2)).sum::<f64>() / 2.0;
    let s = mu;
    let z = n / (n + s / a);                               // road 1: the formula
    let xbar = years.iter().sum::<f64>() / n;
    let cred = z * xbar + (1.0 - z) * mu;
    // road 2: enumerate the joint law of (type, three yearly counts), counts 0..30
    let kk = 30;
    let p = [pois(types[0], kk), pois(types[1], kk)];
    let (mut ex, mut exx, mut etx) = (0.0, 0.0, 0.0);
    let (mut m_cls, mut m_flt, mut m_crd, mut m_bay) = (0.0, 0.0, 0.0, 0.0);
    for i in 0..=kk { for j in 0..=kk { for k in 0..=kk {
        let w = [0.5 * p[0][i] * p[0][j] * p[0][k], 0.5 * p[1][i] * p[1][j] * p[1][k]];
        let xb = (i + j + k) as f64 / 3.0;
        let post = (w[0] * types[0] + w[1] * types[1]) / (w[0] + w[1]);
        for t in 0..2 {
            let th = types[t];
            ex += w[t] * xb; exx += w[t] * xb * xb; etx += w[t] * th * xb;
            m_cls += w[t] * (th - mu).powi(2); m_flt += w[t] * (th - xb).powi(2);
            m_crd += w[t] * (th - z * xb - (1.0 - z) * mu).powi(2); m_bay += w[t] * (th - post).powi(2);
        }
    }}}
    let z_enum = (etx - mu * ex) / (exx - ex * ex);
    let lik: Vec<f64> = types.iter().map(|t| t.powi(4) * (-3.0 * t).exp()).collect();
    let bayes = (lik[0] * types[0] + lik[1] * types[1]) / (lik[0] + lik[1]);
    // road 3: simulate 100,000 fleets for four years; regress year 4 on the first three
    let mut g = Lcg { s: 20260928 };
    let f = 100000;
    let (mut sx, mut sy, mut sxx, mut sxy) = (0.0, 0.0, 0.0, 0.0);
    for _ in 0..f {
        let th = if g.u() < 0.5 { types[0] } else { types[1] };
        let xb = (0..3).map(|_| g.poisson(th) as f64).sum::<f64>() / 3.0;
        let y = g.poisson(th) as f64;
        sx += xb; sy += y; sxx += xb * xb; sxy += xb * y;
    }
    let ff = f as f64;
    let z_sim = (sxy / ff - sx / ff * sy / ff) / (sxx / ff - (sx / ff).powi(2));
    // normal-normal: prior N(2, 1), years N(theta, 2); posterior mean by Simpson
    let dens = |th: f64| (-(th - mu).powi(2) / (2.0 * a) - years.iter().map(|x| (x - th).powi(2)).sum::<f64>() / (2.0 * s)).exp();
    let nn_post = simpson(|th| th * dens(th), -10.0, 14.0, 4000) / simpson(dens, -10.0, 14.0, 4000);
    // ---- reinsurance at the credibility frequency ----
    let (lam, d, dd) = (cred, 2.0, 3.0);
    let law = s_law(lam, 40);
    let sl_enum = sl_of(&law, dd);
    let surv = |t: usize| law.iter().enumerate().filter(|(k, _)| *k > t).map(|(_, p)| p).sum::<f64>();
    let sl_surv: f64 = (dd as usize..law.len()).map(surv).sum();
    let xl_surv = lam * (d as usize..4).map(|t| SEV.iter().filter(|&&y| y > t as f64).map(|_| 0.5).sum::<f64>()).sum::<f64>();
    let mut g = Lcg { s: 7 };
    let yy = 200000;
    let (mut xs, mut ss) = (0.0, 0.0);
    for _ in 0..yy {
        let cnt = g.poisson(lam);
        let sizes: Vec<f64> = (0..cnt).map(|_| if g.u() < 0.5 { 1.0 } else { 4.0 }).collect();
        xs += sizes.iter().map(|y| (y - d).max(0.0)).sum::<f64>();
        ss += (sizes.iter().sum::<f64>() - dd).max(0.0);
    }
    let yf = yy as f64;
    let zw = n / (n + a / s);
    let rows: Vec<(&str, f64)> = vec![("class mean mu", mu), ("VHM a", a), ("EPV s", s), ("k = s/a", s / a), ("1 Z formula", z),
        ("2 Z from joint law", z_enum), ("3 Z by simulation", z_sim), ("fleet mean xbar", xbar),
        ("credibility forecast", cred), ("normal-normal posterior", nn_post), ("two-type Bayes posterior", bayes),
        ("MSE class mean only", m_cls), ("MSE fleet mean only", m_flt), ("MSE credibility", m_crd),
        ("  formula a(1-Z)", a * (1.0 - z)), ("MSE two-type Bayes", m_bay),
        ("XL d=2 formula", xl_formula(lam, d)), ("XL d=2 survival sum", xl_surv), ("XL d=2 simulation", xs / yf),
        ("SL D=3 formula", sl_formula(lam, dd)), ("SL D=3 exact law", sl_enum), ("SL D=3 survival sum", sl_surv),
        ("SL D=3 simulation", ss / yf), ("P(S=0)", law[0]), ("P(S=1)", law[1]), ("P(S=2)", law[2]), ("E S", lam * 2.5),
        ("layer 1 xs 2 per claim", lam * 0.5),
        ("wrong: Z = n/(n+a/s)", zw), ("  its forecast", zw * xbar + (1.0 - zw) * mu),
        ("wrong: SL as lam*E(Y-D)+", xl_formula(lam, dd)), ("wrong: SL as E S - D", lam * 2.5 - dd),
        ("wrong: XL at class mean 2", xl_formula(mu, d)), ("wrong: SL at class mean 2", sl_formula(mu, dd)),
        ("try: Z with n = 10", zof(10.0, a, s)), ("try: Z with types 1.5, 2.5", zof(3.0, 0.25, s)),
        ("try: SL D=5", sl_of(&law, 5.0))];
    for (name, v) in &rows { println!("{:<28} {:>12.6}", name, v); }
    let join = |v: Vec<String>| v.join(" ");
    println!("chart, years n      {}", join((1..=10).map(|m| format!("{:5}", m)).collect()));
    println!("chart, Z            {}", join((1..=10).map(|m| format!("{:5.2}", zof(m as f64, a, s))).collect()));
    println!("chart, retention    {}", join((0..9).map(|t| format!("{:5}", t)).collect()));
    println!("chart, SL premium   {}", join((0..9).map(|t| format!("{:5.2}", sl_of(&law, t as f64))).collect()));
    println!("chart, XL premium   {}", join((0..9).map(|t| format!("{:5.2}", xl_formula(lam, t as f64))).collect()));

    assert!((z_enum - z).abs() < 1e-9, "joint-law slope must equal the formula's Z");
    assert!((m_crd - a * (1.0 - z)).abs() < 1e-9, "enumerated error must equal a(1 - Z)");
    assert!((z_sim - z).abs() < 0.02, "simulated slope near Z");
    assert!((nn_post - cred).abs() < 1e-9, "normal-normal posterior equals the credibility forecast");
    assert!((sl_enum - sl_formula(lam, dd)).abs() < 1e-12, "stop-loss: exact law vs formula");
    assert!((sl_surv - sl_enum).abs() < 1e-12, "stop-loss: survival sum vs exact law");
    assert!((xl_surv - xl_formula(lam, d)).abs() < 1e-12, "excess of loss: survival sum vs formula");
    assert!((xs / yf - xl_formula(lam, d)).abs() < 0.02, "excess of loss: simulation");
    assert!((ss / yf - sl_enum).abs() < 0.03, "stop-loss: simulation");
    assert!(m_bay < m_crd, "full Bayes beats the best straight line");
    println!("ALL CHECKS PASS");
}
