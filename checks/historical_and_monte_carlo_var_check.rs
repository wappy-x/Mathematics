// Historical and Monte Carlo VaR -- the same check as historical_and_monte_carlo_var_check.py.
// Standard library only, no crates.  Own random numbers (splitmix64), own normal CDF, own inverse.
// Compile: rustc --edition 2021 -O historical_and_monte_carlo_var_check.rs -o /tmp/hmc_var_check
use std::f64::consts::PI;

struct Rng { s: u64 }
impl Rng {                                      // splitmix64: the same stream as the Python
    fn u64(&mut self) -> u64 {
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = (self.s ^ (self.s >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    }
    fn unif(&mut self) -> f64 { ((self.u64() >> 11) as f64 + 0.5) / 9007199254740992.0 }
    fn below(&mut self, n: usize) -> usize { (self.u64() % n as u64) as usize }
    fn normal(&mut self) -> f64 {
        let u1 = self.unif(); let u2 = self.unif();
        (-2.0 * u1.ln()).sqrt() * (2.0 * PI * u2).cos()
    }
    fn pair(&mut self, rho: f64, nu: usize) -> (f64, f64) {   // nu > 0 fattens the tails
        let z1 = self.normal(); let z2 = rho * z1 + (1.0 - rho * rho).sqrt() * self.normal();
        if nu == 0 { return (z1, z2); }
        let mut w = 0.0; for _ in 0..nu { let n = self.normal(); w += n * n; }
        let f = ((nu as f64 - 2.0) / w).sqrt();
        (z1 * f, z2 * f)
    }
}
fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }
fn big_phi(x: f64) -> f64 {                     // bell-curve area left of x, by its power series
    if x.abs() > 8.0 { return if x < 0.0 { 0.0 } else { 1.0 }; }
    let (mut term, mut total, mut n) = (x, x, 1.0);
    while term.abs() > 1e-17 * total.abs() { n += 2.0; term *= x * x / n; total += term; }
    0.5 + phi(x) * total
}
fn phi_inv(p: f64) -> f64 {
    let (mut lo, mut hi) = (-10.0, 10.0);
    for _ in 0..200 { let mid = 0.5 * (lo + hi); if big_phi(mid) < p { lo = mid } else { hi = mid } }
    0.5 * (lo + hi)
}
const S0: f64 = 100.0; const K: f64 = 100.0; const R: f64 = 0.05; const Q: f64 = 0.02;
const VOL: f64 = 0.20; const T: f64 = 1.0;
const SHARES: f64 = 100000.0; const OPT_SHARES: f64 = 100000.0; const BOND: f64 = 5e6; const DUR: f64 = 7.0;
fn call(s: f64) -> f64 {
    let d1 = ((s / K).ln() + (R - Q + 0.5 * VOL * VOL) * T) / (VOL * T.sqrt());
    s * (-Q * T).exp() * big_phi(d1) - K * (-R * T).exp() * big_phi(d1 - VOL * T.sqrt())
}
fn parts(x: f64, y: f64, c0: f64) -> [f64; 3] {  // full revaluation of today's book
    let s = S0 * x.exp();
    [SHARES * (s - S0), OPT_SHARES * (call(s) - c0), -BOND * DUR * y]
}
fn loss(x: f64, y: f64, c0: f64) -> f64 { let p = parts(x, y, c0); -(p[0] + p[1] + p[2]) }
fn sorted(v: &[f64]) -> Vec<f64> { let mut s = v.to_vec(); s.sort_by(|a, b| a.total_cmp(b)); s }
fn var(v: &[f64]) -> f64 { sorted(v)[(99 * v.len() + 99) / 100 - 1] }  // ceil(0.99 N)-th smallest
fn sd_of(v: &[f64]) -> f64 {
    let m = v.iter().sum::<f64>() / v.len() as f64;
    (v.iter().map(|x| (x - m) * (x - m)).sum::<f64>() / (v.len() as f64 - 1.0)).sqrt()
}

fn main() {
    let c0 = call(S0);
    let mut rec = Rng { s: 558 };
    let days: Vec<(f64, f64)> = (0..500).map(|_| { let (a, b) = rec.pair(0.3, 6); (0.0118 * a, 0.0006 * b) }).collect();
    let l: Vec<f64> = days.iter().map(|&(x, y)| loss(x, y, c0)).collect();
    let ls = sorted(&l);
    let h_var = var(&l);
    let count_road = l.iter().cloned().filter(|&v| l.iter().filter(|&&w| w <= v).count() >= 495).fold(f64::INFINITY, f64::min);
    let day = l.iter().position(|&v| v == h_var).unwrap();
    let mut pm = vec![0.0; 501]; pm[500] = 0.99f64.powf(500.0);
    for k in (1..=500).rev() { pm[k - 1] = pm[k] * k as f64 / (501 - k) as f64 * 0.01 / 0.99; }
    let cover: f64 = pm[489..499].iter().sum();
    let cover_direct: f64 = (489..499).map(|k: usize| ((1..=k).map(|j| ((501 - j) as f64 / j as f64).ln()).sum::<f64>() + k as f64 * 0.99f64.ln() + (500 - k) as f64 * 0.01f64.ln()).exp()).sum();

    let sxx = days.iter().map(|d| d.0 * d.0).sum::<f64>() / 500.0;
    let syy = days.iter().map(|d| d.1 * d.1).sum::<f64>() / 500.0;
    let sxy = days.iter().map(|d| d.0 * d.1).sum::<f64>() / 500.0;
    let d1 = (R - Q + 0.5 * VOL * VOL) / VOL;
    let ex = S0 * (SHARES + OPT_SHARES * (-Q * T).exp() * big_phi(d1)); let ey = -BOND * DUR;
    let (pu, pd) = (parts(1e-6, 0.0, c0), parts(-1e-6, 0.0, c0));
    let bump = ((pu[0] + pu[1] + pu[2]) - (pd[0] + pd[1] + pd[2])) / 2e-6;
    let (yu, yd) = (parts(0.0, 1e-6, c0), parts(0.0, -1e-6, c0));
    let bump_y = ((yu[0] + yu[1] + yu[2]) - (yd[0] + yd[1] + yd[2])) / 2e-6;
    let z = phi_inv(0.99);
    let sd = (ex * ex * sxx + 2.0 * ex * ey * sxy + ey * ey * syy).sqrt();
    let sd_series = (days.iter().map(|&(x, y)| (ex * x + ey * y) * (ex * x + ey * y)).sum::<f64>() / 500.0).sqrt();
    let p_var = z * sd;
    let simpson = 0.5 + (0..401).map(|i| (if i == 0 || i == 400 { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 }) * phi(i as f64 / 400.0)).sum::<f64>() / 1200.0;

    let kurt = l.iter().map(|v| v * v * v * v).sum::<f64>() / 500.0 / (l.iter().map(|v| v * v).sum::<f64>() / 500.0).powi(2) - 3.0;
    let nu = (4.0 + 6.0 / kurt).round() as usize;
    let (sa, sb) = (sxx.sqrt(), syy.sqrt()); let rho = sxy / (sa * sb);
    let draws = |seed: u64, n: usize, nu: usize| -> Vec<(f64, f64)> { let mut g = Rng { s: seed }; (0..n).map(|_| g.pair(rho, nu)).collect() };
    let mc = |seed: u64, n: usize, nu: usize| -> Vec<f64> { draws(seed, n, nu).iter().map(|&(a, b)| loss(sa * a, sb * b, c0)).collect() };
    let m = mc(1, 10000, nu); let m_var = var(&m);
    let f_hat = m.iter().filter(|&&v| (v - m_var).abs() < 20000.0).count() as f64 / (40000.0 * 10000.0);
    let se_formula = (0.99f64 * 0.01 / 10000.0).sqrt() / f_hat;
    let reruns: Vec<f64> = (0..20).map(|k| var(&mc(100 + k, 10000, nu))).collect();
    let mean_rr = reruns.iter().sum::<f64>() / 20.0;
    let normal_full = var(&mc(8, 10000, 0));
    let normal_delta = var(&draws(8, 10000, 0).iter().map(|&(a, b)| -(ex * sa * a + ey * sb * b)).collect::<Vec<_>>());
    let se_normal = (0.99f64 * 0.01 / 10000.0).sqrt() * sd / phi(z);
    let mut g = Rng { s: 9 }; let boot = var(&(0..10000).map(|_| l[g.below(500)]).collect::<Vec<_>>());
    let mut g = Rng { s: 11 };
    let truth = var(&(0..200000).map(|_| { let (a, b) = g.pair(0.3, 6); loss(0.0118 * a, 0.0006 * b, c0) }).collect::<Vec<_>>());

    let delta_hist = var(&days.iter().map(|&(x, y)| -(ex * x + ey * y)).collect::<Vec<_>>());
    let eq: Vec<f64> = days.iter().map(|&(x, _)| { let p = parts(x, 0.0, c0); p[0] + p[1] }).collect();
    let split = var(&eq.iter().flat_map(|a| days.iter().map(move |&(_, y)| -(a - BOND * DUR * y))).collect::<Vec<_>>());  // every pairing
    let small: Vec<f64> = (0..20).map(|k| var(&mc(200 + k, 1000, nu))).collect();

    let dp = parts(days[day].0, days[day].1, c0);
    let rows: Vec<(&str, f64)> = vec![("house call price", c0), ("N(1) by series", big_phi(1.0)), ("N(1) by Simpson", simpson),
        ("z = N^-1(0.99)", z), ("record: Acme vol, annual", (sxx * 252.0).sqrt()),
        ("record: yield vol, bp per day", syy.sqrt() * 1e4), ("record: correlation", rho),
        ("1 historical VaR, rank 495 of 500", h_var), ("  same, by counting", count_road),
        ("  that day's number", (day + 1) as f64), ("  its Acme move, percent", 100.0 * (days[day].0.exp() - 1.0)),
        ("  its yield change, bp", 1e4 * days[day].1), ("  shares P&L", dp[0]),
        ("  calls P&L", dp[1]), ("  bond P&L", dp[2]),
        ("  95% band low, rank 489", ls[488]), ("  95% band high, rank 499", ls[498]),
        ("  band coverage", cover),
        ("2 delta, analytic", ex), ("  delta, by bump", bump), ("  call delta e^-qT N(d1)", (-Q * T).exp() * big_phi(d1)),
        ("  delta to the yield", ey), ("  P&L sd, covariance", sd),
        ("  P&L sd, series", sd_series), ("  parametric VaR", p_var),
        ("record: excess kurtosis", kurt), ("MC tail weight nu", nu as f64),
        ("3 Monte Carlo VaR, 10,000", m_var), ("  SE by formula", se_formula),
        ("  20 reruns: mean", mean_rr), ("  20 reruns: SE", sd_of(&reruns)),
        ("  20 reruns: lowest", reruns.iter().cloned().fold(f64::INFINITY, f64::min)),
        ("  20 reruns: highest", reruns.iter().cloned().fold(f64::NEG_INFINITY, f64::max)),
        ("  normal law, full revaluation", normal_full), ("  normal law, delta P&L", normal_delta),
        ("  normal law SE", se_normal), ("  resample whole days", boot),
        ("  truth: the record's own law", truth),
        ("wrong: 5th-worst day", ls[495]), ("wrong: delta, not full revaluation", delta_hist),
        ("wrong: moves paired apart", split), ("wrong: 1,000 scenarios, SE", sd_of(&small))];
    for (name, v) in &rows { println!("{:<36} {:>18.*}", name, if v.abs() >= 1000.0 { 2 } else { 6 }, v); }
    println!("tail, losses from $k   200    300    400    500    600");
    let edges: Vec<f64> = (0..6).map(|i| 200000.0 + 100000.0 * i as f64).collect();
    let mut a = String::from("tail, days in record "); let mut b = String::from("tail, normal expects ");
    for w in edges.windows(2) {
        a.push_str(&format!("{:>7}", l.iter().filter(|&&v| w[0] <= v && v < w[1]).count()));
        b.push_str(&format!("{:>7.2}", 500.0 * (big_phi(w[1] / sd) - big_phi(w[0] / sd))));
    }
    println!("{}\n{}", a, b);

    assert!(count_road == h_var, "sorting and counting must pick the same day");
    assert!((cover - cover_direct).abs() < 1e-9, "binomial band: recursion vs direct formula");
    assert!((big_phi(1.0) - simpson).abs() < 1e-12, "series vs Simpson for the bell-curve area");
    assert!((c0 - 9.227005508154).abs() < 1e-9, "the house call price");
    assert!((bump - ex).abs() < 1e-7 * ex, "delta by bump vs analytic");
    assert!((bump_y - ey).abs() < 1e-7 * ey.abs(), "yield delta by bump vs duration");
    assert!((sd - sd_series).abs() < 1e-6 * sd, "covariance formula vs the P&L series");
    assert!((m_var - mean_rr).abs() < 3.0 * sd_of(&reruns), "MC answer sits inside its reruns");
    let ratio = se_formula / sd_of(&reruns);
    assert!(ratio > 0.5 && ratio < 2.0, "error bar: formula vs reruns");
    assert!((normal_delta - p_var).abs() < 3.0 * se_normal, "normal MC lands on the parametric answer");
    assert!(ls[489..499].contains(&boot), "resampling days returns one of the record's own days");
    assert!(ls[488] <= truth && truth <= ls[498], "the order-statistic band holds the truth");
    assert!(split > h_var, "pairing days apart removes the bond's cushion");
    println!("ALL CHECKS PASS");
}
