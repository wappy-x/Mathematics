// Distance to default and expected default frequency -- the same check as the Python.
// No crates; the normal CDF, its inverse, the integrator and the random numbers are
// written here.  The firm: assets V = 100 ($m), one zero-coupon debt of D = 80 due in
// T = 1 year, asset volatility 20%, riskless rate 5%, real drift 8%.
use std::f64::consts::PI;

const V: f64 = 100.0;
const D: f64 = 80.0;
const T: f64 = 1.0;
const SIGMA: f64 = 0.20;
const R: f64 = 0.05;
const MU: f64 = 0.08;

fn n_cdf(x: f64) -> f64 {                     // normal CDF from the Taylor series of erf
    let z = x / 2f64.sqrt();
    let (mut term, mut s) = (z, 0.0);
    for n in 0..120 {                         // term = (-1)^n z^(2n+1) / n!
        s += term / (2 * n + 1) as f64;
        term *= -z * z / (n + 1) as f64;
    }
    0.5 + s / PI.sqrt()
}

fn n_inv(p: f64) -> f64 {                     // bisection: N rises, so one root
    let (mut lo, mut hi) = (-10.0, 10.0);
    for _ in 0..200 {
        let mid = 0.5 * (lo + hi);
        if n_cdf(mid) < p { lo = mid } else { hi = mid }
    }
    0.5 * (lo + hi)
}

fn dd(v: f64, drift: f64, t: f64) -> f64 {    // distance to default, in standard deviations
    ((v / D).ln() + (drift - 0.5 * SIGMA * SIGMA) * t) / (SIGMA * t.sqrt())
}

fn pd_simpson(drift: f64, t: f64, n: usize) -> f64 {   // road 2: lognormal density, dollars 0 to D
    let (m, s) = (V.ln() + (drift - 0.5 * SIGMA * SIGMA) * t, SIGMA * t.sqrt());
    let f = |v: f64| (-(v.ln() - m).powi(2) / (2.0 * s * s)).exp() / (v * s * (2.0 * PI).sqrt());
    let (a, h) = (1e-9, (D - 1e-9) / n as f64);
    let mut sum = 0.0;
    for k in 0..=n {
        let w = if k == 0 || k == n { 1.0 } else if k % 2 == 1 { 4.0 } else { 2.0 };
        sum += w * f(a + k as f64 * h);
    }
    h / 3.0 * sum
}

struct Rng(u64);                              // xorshift64* random numbers, same in the Python
impl Rng {
    fn uniform(&mut self) -> f64 {
        self.0 ^= self.0 >> 12; self.0 ^= self.0 << 25; self.0 ^= self.0 >> 27;
        (self.0.wrapping_mul(0x2545F4914F6CDD1D) >> 11) as f64 / 9007199254740992.0 + 1e-18
    }
    fn normals(&mut self) -> (f64, f64) {     // Box-Muller: two uniforms in, two normals out
        let (u1, u2) = (self.uniform(), self.uniform());
        let rad = (-2.0 * u1.ln()).sqrt();
        (rad * (2.0 * PI * u2).cos(), rad * (2.0 * PI * u2 - PI / 2.0).cos())
    }
}

fn pd_euler(rng: &mut Rng, paths: usize, steps: usize) -> f64 {  // road 3: dV = mu V dt + sigma V dW
    let (dt, mut hits) = (T / steps as f64, 0usize);
    for _ in 0..paths / 2 {
        let (mut a, mut b) = (V, V);
        for _ in 0..steps {
            let (z1, z2) = rng.normals();
            a *= 1.0 + MU * dt + SIGMA * dt.sqrt() * z1;
            b *= 1.0 + MU * dt + SIGMA * dt.sqrt() * z2;
        }
        hits += (a < D) as usize + (b < D) as usize;
    }
    hits as f64 / paths as f64
}

fn row(v: &[f64], w: usize, p: usize) -> String {
    v.iter().map(|x| format!("{:>w$.p$}", x, w = w, p = p)).collect::<Vec<_>>().join(" ")
}

fn main() {
    let mut rng = Rng(20260928);
    let dd0 = dd(V, MU, T);
    let (edf, edf_int, edf_mc) = (n_cdf(-dd0), pd_simpson(MU, T, 4000), pd_euler(&mut rng, 40000, 100));
    let se = (edf * (1.0 - edf) / 40000.0).sqrt();
    let d1 = ((V / D).ln() + (R + 0.5 * SIGMA * SIGMA) * T) / (SIGMA * T.sqrt());   // Merton's d1
    let d2 = d1 - SIGMA * T.sqrt();
    let (q, q_int) = (n_cdf(-d2), pd_simpson(R, T, 4000));
    let lam = (MU - R) / SIGMA;
    let q_shift = n_cdf(n_inv(edf) + lam * T.sqrt());   // road 4: from the EDF to the pricing PD
    let e = V * n_cdf(d1) - D * (-R * T).exp() * n_cdf(d2);
    let put = D * (-R * T).exp() * n_cdf(-d2) - V * n_cdf(-d1);
    let spread = -((V - e) / D).ln() / T - R;
    let short = (V - D) / (SIGMA * V);
    let no_half = ((V / D).ln() + MU * T) / (SIGMA * T.sqrt());
    let rows: Vec<(&str, f64)> = vec![
        ("ln(V/D)", (V / D).ln()), ("real log drift mu - sigma^2/2", MU - 0.5 * SIGMA * SIGMA),
        ("one standard deviation, sigma sqrt T", SIGMA * T.sqrt()),
        ("top line, real drift", (V / D).ln() + (MU - 0.5 * SIGMA * SIGMA) * T),
        ("top line, r in place of mu", (V / D).ln() + (R - 0.5 * SIGMA * SIGMA) * T),
        ("DD, distance to default", dd0), ("1 EDF = N(-DD)", edf),
        ("2 EDF, Simpson over dollars", edf_int), ("3 EDF, Euler paths, 40000", edf_mc),
        ("  standard error of road 3", se), ("d2 = d1 - sigma sqrt T, Merton", d2),
        ("pricing PD = N(-d2)", q), ("  pricing PD, Simpson", q_int),
        ("lambda = (mu - r)/sigma", lam), ("DD - d2", dd0 - d2), ("N_inv(EDF)", n_inv(edf)),
        ("4 pricing PD = N(N_inv(EDF) + lambda)", q_shift), ("EDF at mu = 5%", n_cdf(-dd(V, 0.05, T))),
        ("house: equity", e), ("house: risky debt", V - e), ("house: default put", put),
        ("house: spread, bp", 10000.0 * spread), ("shortcut DD (V - D)/(sigma V)", short),
        ("  N(-shortcut)", n_cdf(-short)),
        ("wrong: no -sigma^2/2, DD", no_half), ("wrong: no -sigma^2/2, EDF", n_cdf(-no_half)),
        ("wrong: N(+DD)", n_cdf(dd0)),
        ("wrong: T = 3 with sigma T, EDF", n_cdf(-((V / D).ln() + 0.06 * 3.0) / (SIGMA * 3.0))),
        ("  right: T = 3, EDF", n_cdf(-dd(V, MU, 3.0))),
        ("try: sigma = 30%, EDF", n_cdf(-((V / D).ln() + (MU - 0.045)) / 0.3)),
    ];
    for (name, v) in &rows { println!("{:<40}{:>12.6}", name, v) }

    let drifts = [0.0, 0.02, 0.04, 0.05, 0.06, 0.08, 0.10, 0.12];
    println!("chart, drift %     {}", row(&drifts.iter().map(|m| 100.0 * m).collect::<Vec<_>>(), 6, 0));
    println!("chart, EDF %       {}", row(&drifts.iter().map(|&m| 100.0 * n_cdf(-dd(V, m, T))).collect::<Vec<_>>(), 6, 2));
    println!("chart, pricing PD %{}", row(&drifts.iter().map(|_| 100.0 * q).collect::<Vec<_>>(), 6, 2));
    let assets: Vec<f64> = (0..9).map(|k| 80.0 + 5.0 * k as f64).collect();
    println!("moves, assets $m   {}", row(&assets, 6, 0));
    for t in [1.0, 3.0] {
        println!("moves, DD, T = {:.0}    {}", t, row(&assets.iter().map(|&v| dd(v, MU, t)).collect::<Vec<_>>(), 6, 3));
        println!("moves, EDF %, T = {:.0} {}", t, row(&assets.iter().map(|&v| 100.0 * n_cdf(-dd(v, MU, t))).collect::<Vec<_>>(), 6, 2));
    }

    let ks = [1.0, 2.0, 3.0, 4.0];            // a fat tail with the same variance: Laplace
    let (mut counts, m) = ([0usize; 4], 400000usize);
    for _ in 0..m {
        let (u, w) = (rng.uniform(), rng.uniform());
        let x = (-u.ln() / 2f64.sqrt()) * if w < 0.5 { 1.0 } else { -1.0 };
        for (c, k) in counts.iter_mut().zip(ks.iter()) { *c += (x < -k) as usize }
    }
    for (k, c) in ks.iter().zip(counts.iter()) {
        let fat = 0.5 * (-(2f64.sqrt()) * k).exp();
        println!("tail at DD {:.0}: normal {:>8.4}%  fat formula {:>8.4}%  fat counted {:>8.4}%  ratio {:>5.1}", k,
                 100.0 * n_cdf(-k), 100.0 * fat, 100.0 * *c as f64 / m as f64, fat / n_cdf(-k));
    }

    assert!((edf - edf_int).abs() < 1e-8, "Simpson over dollars must land on N(-DD)");
    assert!((edf_mc - edf).abs() < 4.0 * se, "Euler simulation within four standard errors");
    assert!((q_shift - q).abs() < 1e-9, "shifting the EDF by lambda must give the pricing PD");
    assert!((q_int - q).abs() < 1e-8, "pricing PD by integral over dollars at drift r");
    assert!((n_cdf(-dd(V, 0.05, T)) - q_int).abs() < 1e-8, "EDF at mu = r meets the integrated pricing PD");
    assert!((e - 24.59).abs() < 0.005, "house equity, from the Merton card's numbers");
    assert!((dd0 - 1.415718).abs() < 1e-6 && (edf - 0.078429).abs() < 1e-6, "the card's example: 1.416 and 7.84%");
    assert!((counts[3] as f64 / m as f64 - 0.5 * (-(2f64.sqrt()) * 4.0).exp()).abs() < 4.0 * (0.00175 / m as f64).sqrt(), "counted fat tail");
    println!("ALL CHECKS PASS");
}
