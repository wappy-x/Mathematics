use std::f64::consts::PI;
const S: f64 = 100.0; const R: f64 = 0.05; const Q: f64 = 0.02; const SIG: f64 = 0.20; const T: f64 = 1.0;

fn n_cdf(x: f64) -> f64 {
    // normal CDF from the erf series that converges everywhere
    let z = x.abs() / 2f64.sqrt();
    let e = if z > 9.0 { 1.0 } else {
        let (mut term, mut total, mut n) = (z, z, 0.0);
        while term > 1e-17 * total {
            n += 1.0;
            term *= 2.0 * z * z / (2.0 * n + 1.0);
            total += term;
        }
        2.0 / PI.sqrt() * (-z * z).exp() * total
    };
    if x >= 0.0 { 0.5 * (1.0 + e) } else { 0.5 * (1.0 - e) }
}

fn bs(k: f64, s: f64, v: f64) -> (f64, f64) {
    let sd = v * T.sqrt();
    let d1 = ((s / k).ln() + (R - Q + 0.5 * v * v) * T) / sd;
    let d2 = d1 - sd;
    (s * (-Q * T).exp() * n_cdf(d1) - k * (-R * T).exp() * n_cdf(d2),
     k * (-R * T).exp() * n_cdf(-d2) - s * (-Q * T).exp() * n_cdf(-d1))
}

fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut inner = 0.0;
    for i in 1..n { inner += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    h / 3.0 * (f(a) + f(b) + inner)
}

fn strip_pv(volf: &dyn Fn(f64) -> f64, s: f64, cut: f64) -> f64 {
    // puts below the cut, calls above, each weighted 1/K^2; integrated in log-strike
    let g = |k: f64| {
        let kk = cut * k.exp();
        let (c, p) = bs(kk, s, volf(kk));
        (if k < 0.0 { p } else { c }) / kk
    };
    simpson(&g, -3.0, 0.0, 2000) + simpson(&g, 0.0, 3.0, 2000)
}

fn kvar(volf: &dyn Fn(f64) -> f64, s: f64, cut: f64) -> f64 {
    2.0 * (R * T).exp() / T * strip_pv(volf, s, cut)
}

struct Rng(u64);
impl Rng {
    fn u01(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        (((z ^ (z >> 31)) >> 11) as f64 + 0.5) / 2f64.powi(53)
    }
}

fn simulate(rng: &mut Rng, paths: usize, volday: &dyn Fn(usize) -> f64) -> (Vec<f64>, Vec<f64>) {
    let dt = T / 252.0;
    let (mut rvs, mut pls) = (Vec::new(), Vec::new());
    for _ in 0..paths {
        let (mut rv, mut pl) = (0.0, 0.0);
        for i in 0..252 {
            let v = volday(i);
            let (u1, u2) = (rng.u01(), rng.u01());
            let y = -0.5 * v * v * dt + v * dt.sqrt() * (-2.0 * u1.ln()).sqrt() * (2.0 * PI * u2).cos();
            let x = y + (R - Q) * dt; // the share's daily log move; y is the forward's
            rv += x * x / T;
            pl += 2.0 / T * ((y.exp() - 1.0) - y); // futures gain minus the log contract's share of the day
        }
        rvs.push(rv); pls.push(pl);
    }
    (rvs, pls)
}

fn mean_se(a: &[f64]) -> (f64, f64) {
    let n = a.len() as f64;
    let m = a.iter().sum::<f64>() / n;
    (m, (a.iter().map(|x| (x - m).powi(2)).sum::<f64>() / (n - 1.0) / n).sqrt())
}

fn dollar_gamma(pv: &dyn Fn(f64) -> f64, s: f64) -> f64 {
    s * s * (pv(s + 0.1) - 2.0 * pv(s) + pv(s - 0.1)) / (0.1 * 0.1)
}

fn main() {
    let f = S * ((R - Q) * T).exp();
    let flat = |v: f64| move |_k: f64| v;
    // road 1: the option strip on the flat 20% surface
    let k1 = kvar(&flat(SIG), S, f);
    // road 2: the log contract priced with no options, (2/T) E[-ln(S_T/F)] against the bell curve
    let dens = |z: f64| (-0.5 * z * z).exp() / (2.0 * PI).sqrt();
    let k2 = 2.0 / T * simpson(&|z: f64| -((-0.5 * SIG * SIG) * T + SIG * T.sqrt() * z) * dens(z), -10.0, 10.0, 2000);
    // road 3: simulated daily paths, hedged log contract against realised variance
    let mut rng = Rng(0x2545F4914F6CDD1D);
    let (rv, pl) = simulate(&mut rng, 4000, &|_i| SIG);
    let (rv_m, rv_se) = mean_se(&rv);
    let (pl_m, pl_se) = mean_se(&pl);
    let gap = rv.iter().zip(&pl).map(|(a, b)| (a - b).abs()).fold(0.0, f64::max);
    let (rv2, pl2) = simulate(&mut rng, 1000, &|i| if i < 126 { 0.10 } else { 0.30 });
    let (rv2_m, rv2_se) = mean_se(&rv2);
    let k_regime = kvar(&flat((0.5 * 0.01 + 0.5 * 0.09f64).sqrt()), S, f);
    let gap2 = rv2.iter().zip(&pl2).map(|(a, b)| (a - b).abs()).fold(0.0, f64::max);
    // worked by hand: a two-strike strip, $30 of strike each
    let (c120, p90) = (bs(120.0, S, SIG).0, bs(90.0, S, SIG).1);
    let two = 2.0 * (R * T).exp() / T * (30.0 / 8100.0 * p90 + 30.0 / 14400.0 * c120);
    let five = 2.0 * (R * T).exp() / T * (0..31).map(|i| 50.0 + 5.0 * i as f64)
        .map(|k| { let (c, p) = bs(k, S, SIG); 5.0 / (k * k) * if k < f { p } else { c } }).sum::<f64>();
    // what breaks
    let skew = move |k: f64| f64::max(0.05, SIG - 0.10 * (k - f) / f);
    let skew2 = move |k: f64| f64::max(0.05, SIG - 0.20 * (k - f) / f);
    let k_skew = kvar(&skew, S, f);
    let cut_spot = kvar(&flat(SIG), S, S);
    let no_ert = 2.0 / T * strip_pv(&flat(SIG), S, f);
    // notionals: $100,000 per vol point, struck at 20 vol points
    let (nvega, kvol) = (100000.0, 20.0);
    let nvar = nvega / (2.0 * kvol);
    let disc = (-R * T).exp();
    let vega = disc * nvar * 1e4 * (kvar(&flat(0.21), S, f) - kvar(&flat(0.19), S, f)) / 2.0;
    let fwd = |s: f64| s * ((R - Q) * T).exp();
    let delta = disc * nvar * 1e4 * (kvar(&flat(SIG), 101.0, fwd(101.0)) - kvar(&flat(SIG), 99.0, fwd(99.0))) / 2.0;
    let spots = [60.0, 80.0, 100.0, 120.0, 140.0];
    let g_strip: Vec<f64> = spots.iter().map(|&s| dollar_gamma(&|x| 2.0 / T * strip_pv(&flat(SIG), x, f), s)).collect();
    let g_call: Vec<f64> = spots.iter().map(|&s| dollar_gamma(&|x| bs(100.0, x, SIG).0, s)).collect();
    let scale = g_strip[2] / g_call[2];

    let rows: Vec<(&str, f64)> = vec![("forward F", f), ("1 option strip, fair variance", k1), ("  as a vol, percent", 100.0 * k1.sqrt()),
        ("2 log contract, no options", k2),
        ("3 hedged log P&L, mean of 4000", pl_m), ("  standard error", pl_se),
        ("  realised variance, mean", rv_m), ("  standard error", rv_se), ("  worst path, |P&L - realised|", gap),
        ("  10% then 30%: realised mean", rv2_m), ("  standard error", rv2_se), ("  strip at that average variance", k_regime),
        ("  10% then 30%: worst |P&L - realised|", gap2),
        ("put 90", p90), ("call 120", c120), ("weight 30/90^2", 30.0 / 8100.0), ("weight 30/120^2", 30.0 / 14400.0),
        ("  put 90 x weight", 30.0 / 8100.0 * p90), ("  call 120 x weight", 30.0 / 14400.0 * c120),
        ("  sum of the two", 30.0 / 8100.0 * p90 + 30.0 / 14400.0 * c120), ("2 e^rT / T", 2.0 * (R * T).exp() / T), ("two-strike strip", two), ("strikes 50 to 200 every $5", five),
        ("wrong: no e^rT", no_ert), ("wrong: cut at spot 100", cut_spot),
        ("skewed surface: strip", k_skew), ("  ATM vol squared", SIG * SIG), ("  rule 0.04 (1 + 3 T b^2)", 0.04 * 1.03),
        ("variance notional per var point", nvar), ("vega by bumping the strip", vega), ("  e^-rT times vega notional", disc * nvega),
        ("delta by bumping spot", if delta.abs() > 5e-7 { delta } else { 0.0 }), ("try: sigma = 30%", kvar(&flat(0.30), S, f)),
        ("try: skew slope 0.20", kvar(&skew2, S, f)),
        ("  strip dollar gamma, formula 2e^-rT/T", 2.0 * disc / T)];
    for (name, v) in &rows { println!("{:<40} {:>14.6}", name, v); }
    let vols = [10.0, 15.0, 20.0, 25.0, 30.0];
    let line = |xs: Vec<f64>| xs.iter().map(|v| format!("{:>9.2}", v)).collect::<String>();
    println!("dollar gamma at spot   {}", spots.iter().map(|s| format!("{:>9.0}", s)).collect::<String>());
    println!("  strip                {}", line(g_strip.clone()));
    println!("  calls struck 100     {}", line(g_call.iter().map(|g| scale * g).collect()));
    println!("payoff, realised vol   {}", vols.iter().map(|v| format!("{:>9.0}", v)).collect::<String>());
    println!("  variance swap, $000  {}", line(vols.iter().map(|v| nvar * (v * v - kvol * kvol) / 1000.0).collect()));
    println!("  vega-linear, $000    {}", line(vols.iter().map(|v| nvega * (v - kvol) / 1000.0).collect()));
    println!("  at 20.5: var, vega   {:>12.2}{:>12.2}", nvar * (20.5f64.powi(2) - kvol * kvol), nvega * (20.5 - kvol));

    assert!((k1 - SIG * SIG).abs() < 1e-9, "strip must return the flat surface's variance");
    assert!((k1 - k2).abs() < 1e-9, "strip and log contract are one payoff");
    assert!((pl_m - k1).abs() < 4.0 * pl_se, "hedged log contract earns the strip on average");
    assert!((rv_m - k1).abs() < 4.0 * rv_se + 1e-5, "realised variance averages to the strip");
    assert!(gap < 0.002, "hedge tracks realised variance path by path");
    assert!(gap2 < 0.002, "and still does when the volatility changes mid-year");
    assert!((rv2_m - k_regime).abs() < 4.0 * rv2_se + 1e-5, "strip still reads the average variance");
    assert!((vega - disc * nvega).abs() < 0.01, "vega notional is the dollar vega, discounted");
    assert!(delta.abs() < 1e-3, "on a flat surface the fair strike ignores spot");
    let (gmax, gmin) = (g_strip.iter().cloned().fold(f64::MIN, f64::max), g_strip.iter().cloned().fold(f64::MAX, f64::min));
    assert!(gmax - gmin < 1e-4, "the strip's dollar gamma is flat across spot");
    assert!((g_strip[2] - 2.0 * disc / T).abs() < 1e-4, "and equals 2 e^-rT / T");
    println!("ALL CHECKS PASS");
}
