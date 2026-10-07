// Vasicek large-pool loss curve and Basel capital -- the check behind the card. Rust std only, no erf,
// so N(x) is a power series in the middle and a continued fraction in the tails. Bisection, Simpson, own RNG.
use std::f64::consts::PI;

fn erf_series(t: f64) -> f64 {
    let (mut term, mut sum, mut n) = (t, t, 0.0);
    while term.abs() > 1e-17 * sum.abs().max(1e-300) {
        n += 1.0;
        term *= -t * t / n;
        sum += term / (2.0 * n + 1.0);
    }
    2.0 / PI.sqrt() * sum
}
fn erfc_cf(t: f64) -> f64 {                       // t > 2.5
    let mut k = t;
    for i in (1..=80).rev() { k = t + (i as f64 / 2.0) / k; }
    (-t * t).exp() / (PI.sqrt() * k)
}
fn norm_cdf(x: f64) -> f64 {
    let t = x / 2f64.sqrt();
    if t.abs() < 2.5 { 0.5 * (1.0 + erf_series(t)) }
    else if t > 0.0 { 1.0 - 0.5 * erfc_cf(t) } else { 0.5 * erfc_cf(-t) }
}
fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }
fn bisect<F: Fn(f64) -> f64>(f: F, mut lo: f64, mut hi: f64) -> f64 {
    for _ in 0..200 {
        let mid = 0.5 * (lo + hi);
        if f(mid) < 0.0 { lo = mid } else { hi = mid }
    }
    0.5 * (lo + hi)
}
fn ninv(u: f64) -> f64 { bisect(|z| norm_cdf(z) - u, -40.0, 40.0) }
fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    s * h / 3.0
}

const PD: f64 = 0.02; const RHO: f64 = 0.20; const LGD: f64 = 0.60; const LOAN: f64 = 100.0; const ALPHA: f64 = 0.999;

fn p_given(m: f64, rho: f64, c: f64) -> f64 { norm_cdf((c - rho.sqrt() * m) / (1.0 - rho).sqrt()) }
fn quantile(u: f64, rho: f64, pd: f64) -> f64 { norm_cdf((ninv(pd) + rho.sqrt() * ninv(u)) / (1.0 - rho).sqrt()) }
fn basel_rho(pd: f64) -> f64 {
    let w = (1.0 - (-50.0 * pd).exp()) / (1.0 - (-50.0f64).exp());
    0.12 * w + 0.24 * (1.0 - w)
}

// exact finite pool: mix binomial counts over the economy; returns (total prob, 99.9% fraction, ES)
fn finite_pool(n: usize, c: f64) -> (f64, f64, f64) {
    let (nodes, lo, hi) = (1600usize, -9.0f64, 9.0f64);
    let mut lc = vec![0.0f64; n + 1];
    for k in 1..=n { lc[k] = lc[k - 1] + ((n - k + 1) as f64).ln() - (k as f64).ln(); }
    let mut dist = vec![0.0f64; n + 1];
    let h = (hi - lo) / nodes as f64;
    for i in 0..=nodes {
        let m = lo + i as f64 * h;
        let wt = if i == 0 || i == nodes { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 };
        let w = wt * h / 3.0 * phi(m);
        let q = p_given(m, RHO, c).max(1e-300).min(1.0 - 1e-16);
        let (lq, l1) = (q.ln(), (1.0 - q).ln());
        for k in 0..=n { dist[k] += w * (lc[k] + k as f64 * lq + (n - k) as f64 * l1).exp(); }
    }
    let (mut cum, mut k) = (0.0, 0usize);
    while cum + dist[k] < ALPHA { cum += dist[k]; k += 1; }
    let mut tail = (cum + dist[k] - ALPHA) * k as f64 / n as f64;
    for j in k + 1..=n { tail += dist[j] * j as f64 / n as f64; }
    (dist.iter().sum(), k as f64 / n as f64, tail / (1.0 - ALPHA))
}

struct Rng(u64);
impl Rng {
    fn uniform(&mut self) -> f64 {
        self.0 = self.0.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
        ((self.0 >> 11) as f64 + 0.5) / 9007199254740992.0
    }
    fn normal_pair(&mut self) -> (f64, f64) {
        let r = (-2.0 * self.uniform().ln()).sqrt();
        let t = 2.0 * PI * self.uniform();
        (r * t.cos(), r * (t - 0.5 * PI).cos())
    }
}

fn main() {
    let (c, z_a) = (ninv(PD), ninv(ALPHA));
    let f_cdf = |x: f64| norm_cdf(((1.0 - RHO).sqrt() * ninv(x) - c) / RHO.sqrt());
    let x1 = quantile(ALPHA, RHO, PD);
    let x2 = bisect(|x| f_cdf(x) - ALPHA, 1e-12, 1.0 - 1e-12);
    let mean_pd = simpson(|m| p_given(m, RHO, c) * phi(m), -10.0, 10.0, 4000);
    let es1 = simpson(|z| p_given(-z, RHO, c) * phi(z), z_a, 12.0, 4000) / (1.0 - ALPHA);
    let es2 = x1 + simpson(|y| 1.0 - f_cdf(y), x1, 1.0 - 1e-12, 4000) / (1.0 - ALPHA);

    // simulate 100 loans, each with its own luck, 100,000 years
    let (years, loans) = (100000usize, 100usize);
    let mut rng = Rng(0x2545F4914F6CDD1D);
    let (a, b) = (RHO.sqrt(), (1.0 - RHO).sqrt());
    let mut fracs: Vec<f64> = Vec::with_capacity(years);
    for _ in 0..years {
        let (m, _) = rng.normal_pair();
        let mut d = 0usize;
        for _ in 0..loans / 2 {
            let (z1, z2) = rng.normal_pair();
            if a * m + b * z1 < c { d += 1; }
            if a * m + b * z2 < c { d += 1; }
        }
        fracs.push(d as f64 / loans as f64);
    }
    fracs.sort_by(|p, q| p.partial_cmp(q).unwrap());
    let tail_n = (years as f64 * (1.0 - ALPHA)).round() as usize;
    let mc_var = fracs[years - tail_n - 1];
    let mc_es = fracs[years - tail_n..].iter().sum::<f64>() / tail_n as f64;
    let mc_mean = fracs.iter().sum::<f64>() / years as f64;

    let el = LOAN * LGD * PD;
    let var_loss = LOAN * LGD * x1;
    let rb = basel_rho(PD);
    let xb = quantile(ALPHA, rb, PD);
    let cap_b = LOAN * LGD * (xb - PD);
    let joint = simpson(|m| p_given(m, RHO, c).powi(2) * phi(m), -10.0, 10.0, 4000);
    let dcorr = (joint - PD * PD) / (PD * (1.0 - PD));

    let mut out: Vec<(String, f64)> = vec![
        ("threshold c = N^-1(PD)".into(), c), ("bad economy N^-1(0.999)".into(), z_a), ("sqrt(rho)".into(), RHO.sqrt()),
        ("sqrt(1 - rho)".into(), (1.0 - RHO).sqrt()),
        ("argument (c + sqrt(rho) z)/sqrt(1-rho)".into(), (c + RHO.sqrt() * z_a) / (1.0 - RHO).sqrt()),
        ("1 closed-form 99.9% fraction".into(), x1), ("2 root of F(x) = 0.999".into(), x2),
        ("  average of p(M), must be PD".into(), mean_pd),
        ("ES 99.9%, over economies".into(), es1), ("ES 99.9%, over loss levels".into(), es2)];
    let mut pools = Vec::new();
    for &n in &[25usize, 100, 1000] {
        let (tot, q_n, es_n) = finite_pool(n, c);
        out.push((format!("3 exact pool of {}: total prob", n), tot));
        out.push((format!("  pool of {}: 99.9% fraction", n), q_n));
        out.push((format!("  pool of {}: ES 99.9%", n), es_n));
        pools.push((q_n, es_n));
    }
    let rest: Vec<(&str, f64)> = vec![
        ("4 simulated 100 loans: mean", mc_mean), ("  simulated: 99.9% fraction", mc_var), ("  simulated: ES 99.9%", mc_es),
        ("expected loss per loan $", el), ("99.9% loss per loan $", var_loss), ("capital = UL per loan $", var_loss - el),
        ("ES loss per loan $", LOAN * LGD * es1), ("fraction above expected", x1 - PD),
        ("Basel weight w", (1.0 - (-50.0 * PD).exp()) / (1.0 - (-50.0f64).exp())), ("Basel correlation", rb), ("Basel 99.9% fraction", xb),
        ("Basel capital per loan $", cap_b), ("risk-weighted assets per loan $", 12.5 * cap_b),
        ("default correlation", dcorr),
        ("wrong: correlation 0, 99.9% fraction", quantile(ALPHA, 0.0, PD)),
        ("wrong: EL left in, capital $", var_loss), ("wrong: forgot LGD, capital $", LOAN * (x1 - PD)),
        ("wrong: N^-1(0.001), capital $", LOAN * LGD * (quantile(1.0 - ALPHA, RHO, PD) - PD)),
        ("wrong: default corr as rho, capital $", LOAN * LGD * (quantile(ALPHA, dcorr, PD) - PD)),
        ("try: rho 0.10 fraction", quantile(ALPHA, 0.10, PD)), ("try: rho 0.30 fraction", quantile(ALPHA, 0.30, PD)),
        ("try: alpha 0.99 fraction", quantile(0.99, RHO, PD))];
    for (k, v) in rest { out.push((k.to_string(), v)); }
    for (name, v) in &out { println!("{:<38} {:>12.6}", name, v); }
    let ts = [2.0, 5.0, 10.0, 20.0, 50.0, 100.0, 200.0, 500.0, 1000.0f64];
    let row = |label: &str, v: Vec<String>| println!("{}{}", label, v.join(" "));
    row("chart, 1 year in   ", ts.iter().map(|t| format!("{:>6}", *t as i64)).collect());
    row("chart, fraction %  ", ts.iter().map(|t| format!("{:6.2}", 100.0 * quantile(1.0 - 1.0 / t, RHO, PD))).collect());
    let pds = [0.001, 0.0025, 0.005, 0.01, 0.02, 0.03, 0.05, 0.10, 0.20f64];
    row("chart, PD %        ", pds.iter().map(|p| format!("{:6.2}", 100.0 * p)).collect());
    row("chart, cap rho 20% ", pds.iter().map(|&p| format!("{:6.2}", LOAN * LGD * (quantile(ALPHA, RHO, p) - p))).collect());
    row("chart, cap Basel   ", pds.iter().map(|&p| format!("{:6.2}", LOAN * LGD * (quantile(ALPHA, basel_rho(p), p) - p))).collect());

    assert!((x1 - x2).abs() < 1e-9, "closed form vs root of the CDF");
    assert!((mean_pd - PD).abs() < 1e-9, "averaging over the economy returns PD");
    assert!((es1 - es2).abs() < 1e-6, "ES over economies vs ES over loss levels");
    assert!((pools[1].0 - mc_var).abs() <= 0.015, "simulated 100-loan quantile within noise of the exact one");
    assert!((pools[1].1 - mc_es).abs() < 0.01, "simulated 100-loan ES within noise of the exact one");
    assert!((pools[2].0 - x1).abs() < 0.005 && 0.005 < (pools[0].0 - x1).abs(), "big pools approach the large-pool curve");
    assert!((mc_mean - PD).abs() < 0.0015, "simulated mean default rate");
    assert!((var_loss - el - LOAN * LGD * (x2 - PD)).abs() < 1e-6 && (rb - 0.1641).abs() < 1e-4 && (bisect(|x| norm_cdf(((1.0 - rb).sqrt() * ninv(x) - c) / rb.sqrt()) - ALPHA, 1e-12, 1.0 - 1e-12) - xb).abs() < 1e-9, "capital by road 2; Basel correlation and quantile by root-finding");
    println!("ALL CHECKS PASS");
}
