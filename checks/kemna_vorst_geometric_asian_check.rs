// Kemna-Vorst on a commodity -- the same check as the Python, in Rust.  std only.
// Normal CDF as a written-out series, Simpson's rule, a brute-force sum over the fixing dates,
// splitmix64 + Box-Muller for the random numbers.
// Compile: rustc --edition 2021 -O kemna_vorst_geometric_asian_check.rs -o /tmp/kvga
use std::f64::consts::PI;

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }
fn n_cdf(x: f64) -> f64 {
    if x < -9.0 { return 0.0; }
    if x > 9.0 { return 1.0; }
    let (mut term, mut total, mut k) = (x, x, 1.0);
    while term.abs() > 1e-17 * total.abs() {
        k += 2.0; term *= x * x / k; total += term;
    }
    0.5 + phi(x) * total
}
fn black76(f: f64, k: f64, r: f64, sig: f64, t: f64, put: bool) -> f64 {
    let d1 = ((f / k).ln() + 0.5 * sig * sig * t) / (sig * t.sqrt());
    let d2 = d1 - sig * t.sqrt();
    if put { return (-r * t).exp() * (k * n_cdf(-d2) - f * n_cdf(-d1)); }
    (-r * t).exp() * (f * n_cdf(d1) - k * n_cdf(d2))
}
// road 1: the two doctored inputs in closed form, for the curve S0 e^(c t)
fn kv_inputs(s0: f64, c: f64, sig: f64, t: f64, n: f64) -> (f64, f64) {
    let tbar = t * (n + 1.0) / (2.0 * n);
    let frac = (n + 1.0) * (2.0 * n + 1.0) / (6.0 * n * n);
    let fg = s0 * (c * tbar).exp() * (-0.5 * sig * sig * (tbar - frac * t)).exp();
    (fg, sig * frac.sqrt())
}
fn kv(s0: f64, k: f64, r: f64, c: f64, sig: f64, t: f64, n: f64, put: bool) -> f64 {
    let (fg, sg) = kv_inputs(s0, c, sig, t, n);
    black76(fg, k, r, sg, t, put)
}
fn kv_cont(s0: f64, k: f64, r: f64, c: f64, sig: f64, t: f64) -> f64 {
    black76(s0 * (0.5 * c * t - sig * sig * t / 12.0).exp(), k, r, sig / 3f64.sqrt(), t, false)
}
fn simpson(m: f64, v: f64, payoff: &dyn Fn(f64) -> f64, r: f64, t: f64) -> f64 {
    let (a, b, panels) = (-10.0, 10.0, 200000);
    let h = (b - a) / panels as f64;
    let f = |z: f64| payoff((m + v.sqrt() * z).exp()) * phi(z);
    let mut tot = f(a) + f(b);
    for i in 1..panels { tot += (if i % 2 == 1 { 4.0 } else { 2.0 }) * f(a + i as f64 * h); }
    (-r * t).exp() * tot * h / 3.0
}
struct Rng(u64);
impl Rng {
    fn uniform(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        (((z ^ (z >> 31)) >> 11) + 1) as f64 * 2f64.powi(-53)
    }
}

fn main() {
    let (s0, k, r, c, sig, t, n) = (100.0f64, 100.0f64, 0.05f64, 0.05f64, 0.20f64, 1.0f64, 52usize);
    let nf = n as f64;
    let fwd = |tt: f64| s0 * (c * tt).exp();
    let (fg, sg) = kv_inputs(s0, c, sig, t, nf);
    let tbar = t * (nf + 1.0) / (2.0 * nf);
    let frac = (nf + 1.0) * (2.0 * nf + 1.0) / (6.0 * nf * nf);
    let d1 = ((fg / k).ln() + 0.5 * sg * sg * t) / (sg * t.sqrt());
    let d2 = d1 - sg * t.sqrt();
    let (cc, pp) = (kv(s0, k, r, c, sig, t, nf, false), kv(s0, k, r, c, sig, t, nf, true));

    // road 2: the law of ln G fixing by fixing, from the curve
    let ts: Vec<f64> = (1..=n).map(|i| t * i as f64 / nf).collect();
    let m2 = ts.iter().map(|&x| fwd(x).ln() - 0.5 * sig * sig * x).sum::<f64>() / nf;
    let mut cov = 0.0;
    for x in &ts { for y in &ts { cov += x.min(*y); } }
    let v2 = sig * sig * cov / (nf * nf);
    let c2 = simpson(m2, v2, &|g: f64| (g - k).max(0.0), r, t);
    let p2 = simpson(m2, v2, &|g: f64| (k - g).max(0.0), r, t);

    // road 3: one Brownian path moves every futures price; read it weekly
    let mut rng = Rng(20260927);
    let (paths, h) = (100000usize, t / nf);
    let mut acc = [0.0f64; 4];
    let mut am_below_gm = 0usize;
    let disc = (-r * t).exp();
    for _ in 0..paths {
        let (mut w, mut sum_log, mut sum_px) = (0.0f64, 0.0f64, 0.0f64);
        let mut i = 0;
        while i < n {
            let rad = (-2.0 * rng.uniform().ln()).sqrt();
            let ang = 2.0 * PI * rng.uniform();
            for (zz, tt) in [(rad * ang.cos(), ts[i]), (rad * ang.sin(), ts[i + 1])] {
                w += h.sqrt() * zz;
                let x = fwd(tt).ln() - 0.5 * sig * sig * tt + sig * w;
                sum_log += x; sum_px += x.exp();
            }
            i += 2;
        }
        let (g, a) = ((sum_log / nf).exp(), sum_px / nf);
        if a < g { am_below_gm += 1; }
        let (pg, pa) = (disc * (g - k).max(0.0), disc * (a - k).max(0.0));
        acc[0] += pg; acc[1] += pg * pg; acc[2] += pa; acc[3] += pa * pa;
    }
    let pf = paths as f64;
    let mean_se = |s1: f64, s2: f64| (s1 / pf, ((s2 / pf - (s1 / pf).powi(2)) / pf).sqrt());
    let (mc_g, mc_a) = (mean_se(acc[0], acc[1]), mean_se(acc[2], acc[3]));

    // Greeks: the whole curve moves with S0; rho holds the curve still
    let bump = |s: f64, rr: f64, sg_: f64| kv(s, k, rr, c, sg_, t, nf, false);
    let delta = (bump(s0 + 0.01, r, sig) - bump(s0 - 0.01, r, sig)) / 0.02;
    let gamma = (bump(s0 + 0.5, r, sig) - 2.0 * cc + bump(s0 - 0.5, r, sig)) / 0.25;
    let vega = (bump(s0, r, sig + 1e-4) - bump(s0, r, sig - 1e-4)) / 2e-4 / 100.0;
    let rho = (bump(s0, r + 1e-4, sig) - bump(s0, r - 1e-4, sig)) / 2e-4 / 100.0;
    let swap = ts.iter().map(|&x| fwd(x)).sum::<f64>() / nf;

    let mut rows: Vec<(String, f64)> = vec![
        ("forward for the last fixing, F(0,T)".into(), fwd(t)), ("centre of the fixings, tbar".into(), tbar),
        ("variance fraction (n+1)(2n+1)/6n^2".into(), frac), ("sigma_G = sigma sqrt(fraction)".into(), sg),
        ("F(0,tbar), geometric mean of forwards".into(), fwd(tbar)), ("haircut e^(-sig^2(tbar-frac T)/2)".into(), fg / fwd(tbar)),
        ("F_G, forward of the average".into(), fg), ("d1".into(), d1), ("d2".into(), d2),
        ("N(d1)".into(), n_cdf(d1)), ("N(d2)".into(), n_cdf(d2)), ("discount e^-rT".into(), disc),
        ("average half e^-rT F_G N(d1)".into(), disc * fg * n_cdf(d1)), ("cash half e^-rT K N(d2)".into(), disc * k * n_cdf(d2)),
        ("1 closed form, 52 weekly fixings".into(), cc), ("2 centre of ln G, summed".into(), m2),
        ("  ln F_G - sigma_G^2 T/2".into(), fg.ln() - 0.5 * sg * sg * t),
        ("2 var ln G, 52x52 min sum".into(), v2), ("  sigma_G^2 T".into(), sg * sg * t), ("2 Simpson over that law".into(), c2),
        ("3 simulation, 100000 paths".into(), mc_g.0), ("  standard error".into(), mc_g.1),
        ("4 put, closed form".into(), pp), ("4 put, Simpson".into(), p2), ("  C - P, Simpson".into(), c2 - p2),
        ("  e^-rT (F_G - K)".into(), disc * (fg - k)),
        ("arithmetic average, same paths".into(), mc_a.0), ("  paths where AM < GM".into(), f64::NAN),
    ];
    for m in [1usize, 2, 4, 12, 52, 252, 1000000] { rows.push((format!("ladder: {} fixings", m), kv(s0, k, r, c, sig, t, m as f64, false))); }
    let tail: Vec<(&str, f64)> = vec![
        ("continuous: sigma/sqrt 3", kv_cont(s0, k, r, c, sig, t)),
        ("curve flat: one futures contract", kv(s0, k, r, 0.0, sig, t, nf, false)),
        ("curve backwardated, c = -5%", kv(s0, k, r, -0.05, sig, t, nf, false)),
        ("delta by bump", delta), ("  e^-rT N(d1) F_G/S0", disc * n_cdf(d1) * fg / s0),
        ("gamma by bump", gamma), ("vega per vol point", vega), ("rho per rate point, curve held", rho),
        ("swap price, mean of the forwards", swap),
        ("wrong: raw sigma, F_G kept", black76(fg, k, r, sig, t, false)),
        ("wrong: swap price as F_G", black76(swap, k, r, sg, t, false)),
        ("try: sigma = 0.40", kv(s0, k, r, c, 0.40, t, nf, false)), ("try: K = 110", kv(s0, 110.0, r, c, sig, t, nf, false)),
        ("try: one month, 21 daily fixings", kv(s0, k, r, c, sig, 1.0 / 12.0, 21.0, false)),
    ];
    for (name, v) in tail { rows.push((name.to_string(), v)); }
    for (name, v) in &rows {
        if v.is_nan() { println!("{:<40} {:>12}", name, am_below_gm); } else { println!("{:<40} {:>12.6}", name, v); }
    }
    let grid: Vec<f64> = (0..9).map(|i| 80.0 + 5.0 * i as f64).collect();
    println!("chart, G at expiry {}", grid.iter().map(|x| format!("{:6.0}", x)).collect::<Vec<_>>().join(" "));
    println!("chart, profit      {}", grid.iter().map(|x| format!("{:6.2}", (x - k).max(0.0) - cc)).collect::<Vec<_>>().join(" "));
    let mut ladder: Vec<f64> = [1.0, 2.0, 4.0, 12.0, 52.0, 252.0].iter().map(|&m| kv(s0, k, r, c, sig, t, m, false)).collect();
    ladder.push(kv_cont(s0, k, r, c, sig, t));
    println!("chart, fixings          1      2      4     12     52    252   cont");
    println!("chart, price       {}", ladder.iter().map(|v| format!("{:6.2}", v)).collect::<Vec<_>>().join(" "));

    assert!((c2 - cc).abs() < 1e-7, "fixing-by-fixing law of ln G must reproduce the closed form");
    assert!((mc_g.0 - cc).abs() < 3.0 * mc_g.1, "simulation within 3 standard errors of the formula");
    assert!(((c2 - p2) - disc * (fg - k)).abs() < 1e-7, "parity: Simpson call and put against the closed F_G");
    assert!((p2 - pp).abs() < 1e-7, "put: Simpson against the closed form");
    let bs1 = ((s0 / k).ln() + (r + 0.5 * sig * sig) * t) / (sig * t.sqrt()); // spot-form Black-Scholes, no yield
    assert!((kv(s0, k, r, c, sig, t, 1.0, false) - (s0 * n_cdf(bs1) - k * disc * n_cdf(bs1 - sig * t.sqrt()))).abs() < 1e-10, "one fixing is the plain call");
    assert!((kv(s0, k, r, c, sig, t, 1e6, false) - kv_cont(s0, k, r, c, sig, t)).abs() < 1e-5, "ladder tends to sigma/sqrt 3");
    assert!((delta - disc * n_cdf(d1) * fg / s0).abs() < 1e-6, "bumped delta vs e^-rT N(d1) F_G/S0");
    println!("ALL CHECKS PASS");
}
