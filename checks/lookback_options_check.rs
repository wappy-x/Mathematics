// Floating-strike lookback call -- the same check as lookback_options_check.py, in Rust.  Std only.
// Four roads: the closed form, the minimum's law integrated level by level, a simulation that
// draws the exact continuous minimum, and a daily-watched simulation on paired paths.
use std::f64::consts::PI;

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }
fn n_cdf(x: f64) -> f64 {                                        // Marsaglia's series
    if x < -8.0 { return 0.0; }
    if x > 8.0 { return 1.0; }
    let (mut s, mut t) = (x, x);
    for k in 1..200 { t *= x * x / (2 * k + 1) as f64; s += t; }
    0.5 + phi(x) * s
}
fn vanilla(s: f64, k: f64, r: f64, q: f64, sig: f64, t: f64) -> f64 {
    let d1 = ((s / k).ln() + (r - q + 0.5 * sig * sig) * t) / (sig * t.sqrt());
    s * (-q * t).exp() * n_cdf(d1) - k * (-r * t).exp() * n_cdf(d1 - sig * t.sqrt())
}
fn lookback_call(s: f64, m: f64, r: f64, q: f64, sig: f64, tt: f64, keep_ebt: bool) -> f64 {   // Road 1
    let m = m.min(s); let b = r - q; let t = sig * tt.sqrt();
    let a1 = ((s / m).ln() + (b + 0.5 * sig * sig) * tt) / t; let a2 = a1 - t; let a3 = a1 - 2.0 * b * tt / t;
    let van = s * (-q * tt).exp() * n_cdf(a1) - m * (-r * tt).exp() * n_cdf(a2);
    if b == 0.0 { return van + s * (-r * tt).exp() * t * (phi(a1) - a1 * n_cdf(-a1)); }
    let ebt = if keep_ebt { (b * tt).exp() } else { 1.0 };
    van + s * (-r * tt).exp() * sig * sig / (2.0 * b) * ((s / m).powf(-2.0 * b / (sig * sig)) * n_cdf(-a3) - ebt * n_cdf(-a1))
}
fn lookback_put(s: f64, mx: f64, r: f64, q: f64, sig: f64, tt: f64) -> f64 {
    let b = r - q; let t = sig * tt.sqrt();
    let a1 = ((s / mx).ln() + (b + 0.5 * sig * sig) * tt) / t; let a2 = a1 - t; let a3 = a1 - 2.0 * b * tt / t;
    let van = mx * (-r * tt).exp() * n_cdf(-a2) - s * (-q * tt).exp() * n_cdf(-a1);
    van + s * (-r * tt).exp() * sig * sig / (2.0 * b) * (-(s / mx).powf(-2.0 * b / (sig * sig)) * n_cdf(a3) + (b * tt).exp() * n_cdf(a1))
}
fn expected_min(s: f64, m: f64, r: f64, q: f64, sig: f64, tt: f64) -> f64 {   // Road 2
    let (nu, t, n) = (r - q - 0.5 * sig * sig, sig * tt.sqrt(), 4000usize);
    let qh = |h: f64| -> f64 {
        if h <= 0.0 { return 1.0; }
        let u = (s / h).ln();
        n_cdf((u + nu * tt) / t) - (h / s).powf(2.0 * nu / (sig * sig)) * n_cdf((nu * tt - u) / t)
    };
    let (w, mut tot) = (m / n as f64, 0.0);
    for i in 0..=n { tot += (if i == 0 || i == n { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 }) * qh(i as f64 * w); }
    w / 3.0 * tot
}
fn by_integral(s: f64, m: f64, r: f64, q: f64, sig: f64, tt: f64) -> f64 {
    s * (-q * tt).exp() - (-r * tt).exp() * expected_min(s, m, r, q, sig, tt)
}
struct Rng(u64);
impl Rng {
    fn u01(&mut self) -> f64 {                                   // splitmix64, written out
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = (self.0 ^ (self.0 >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 * 2f64.powi(-53) + 2f64.powi(-54)
    }
    fn gauss(&mut self) -> f64 { let u = self.u01(); (-2.0 * u.ln()).sqrt() * (2.0 * PI * self.u01()).cos() }
    fn low(&mut self, x0: f64, x1: f64, v: f64) -> f64 { 0.5 * (x0 + x1 - ((x1 - x0).powi(2) - 2.0 * v * self.u01().ln()).sqrt()) }
    fn high(&mut self, x0: f64, x1: f64, v: f64) -> f64 { 0.5 * (x0 + x1 + ((x1 - x0).powi(2) - 2.0 * v * self.u01().ln()).sqrt()) }
}
fn mean_se(xs: &[f64]) -> (f64, f64) {
    let (mut mu, mut ss) = (0.0, 0.0);
    for x in xs { mu += x; }
    mu /= xs.len() as f64;
    for x in xs { ss += (x - mu).powi(2); }
    (mu, (ss / (xs.len() - 1) as f64 / xs.len() as f64).sqrt())
}

fn main() {
    let (s, k, r, q, sig, tt) = (100.0_f64, 100.0_f64, 0.05_f64, 0.02_f64, 0.20_f64, 1.0_f64);
    let (d, nu) = ((-r * tt).exp(), r - q - 0.5 * sig * sig);
    let c = lookback_call(s, s, r, q, sig, tt, true); let v = vanilla(s, k, r, q, sig, tt);
    let emin = expected_min(s, s, r, q, sig, tt); let c2 = s * (-q * tt).exp() - d * emin;
    let p = lookback_put(s, s, r, q, sig, tt); let gap_fwd = s * (-q * tt).exp() - s * d;
    let cfix = p + gap_fwd;
    let (lam, bar) = ((r - q + 0.5 * sig * sig) / (sig * sig), 80.0_f64);
    let y = (bar * bar / (s * k)).ln() / (sig * tt.sqrt()) + lam * sig * tt.sqrt();
    let di = s * (-q * tt).exp() * (bar / s).powf(2.0 * lam) * n_cdf(y) - k * d * (bar / s).powf(2.0 * lam - 2.0) * n_cdf(y - sig * tt.sqrt());

    let mut rng = Rng(20260924);
    let (mut fl, mut pu, mut fx) = (Vec::new(), Vec::new(), Vec::new());       // Road 3
    for _ in 0..200000 {
        let x = nu * tt + sig * tt.sqrt() * rng.gauss(); let st = s * x.exp();
        fl.push(d * (st - s * rng.low(0.0, x, sig * sig * tt).min(0.0).exp()));
        let hi = s * rng.high(0.0, x, sig * sig * tt).max(0.0).exp();
        pu.push(d * (hi - st)); fx.push(d * (hi - k).max(0.0));
    }
    let ((c3, se3), (p3, sep), (f3, sef)) = (mean_se(&fl), mean_se(&pu), mean_se(&fx));
    let (mut daily, mut cont, mut gap) = (Vec::new(), Vec::new(), Vec::new());   // Road 4
    let dt = tt / 252.0;
    for _ in 0..20000 {
        let (mut x, mut lo_d, mut lo_c) = (0.0_f64, 0.0_f64, 0.0_f64);
        for _ in 0..252 {
            let x1 = x + nu * dt + sig * dt.sqrt() * rng.gauss();
            lo_c = lo_c.min(rng.low(x, x1, sig * sig * dt)); x = x1; lo_d = lo_d.min(x);
        }
        daily.push(d * (s * x.exp() - s * lo_d.exp())); cont.push(d * (s * x.exp() - s * lo_c.exp()));
        gap.push(cont[cont.len() - 1] - daily[daily.len() - 1]);
    }
    let ((c4, se4), (c4c, _), (g4, seg)) = (mean_se(&daily), mean_se(&cont), mean_se(&gap));
    let bgk = s * (-q * tt).exp() - d * emin * (0.5826 * sig * dt.sqrt()).exp();

    let h = 1e-4;
    let pr = |sp: f64, r2: f64, q2: f64, s2: f64, t2: f64| lookback_call(sp, s, r2, q2, s2, t2, true);
    let rows: Vec<(&str, f64)> = vec![("vanilla call, strike 100", v), ("1 lookback call, closed form", c), ("  extra over the vanilla", c - v),
        ("2 lookback call, integral of P(min > h)", c2), ("  expected minimum E[m_T]", emin),
        ("3 lookback call, exact-minimum simulation", c3), ("  standard error", se3),
        ("4 lookback call, watched daily", c4), ("  standard error", se4), ("  same paths, watched continuously", c4c),
        ("  continuous minus daily, paired", g4), ("  standard error", seg), ("  daily, formula minus paired gap", c - g4),
        ("  daily, Broadie-Glasserman-Kou shift", bgk), ("prepaid share S e^-qT", s * (-q * tt).exp()), ("  S e^-qT - K e^-rT", gap_fwd),
        ("floating lookback put, formula", p), ("  simulation", p3), ("  standard error", sep),
        ("fixed-strike lookback call, parity", cfix), ("  simulation", f3), ("  standard error", sef), ("fixed-strike lookback put, parity", c - gap_fwd),
        ("down-and-in call, barrier 80", di), ("down-and-out call, barrier 80", v - di),
        ("seasoned, minimum 90: formula", lookback_call(s, 90.0, r, q, sig, tt, true)), ("  integral", by_integral(s, 90.0, r, q, sig, tt)),
        ("  vanilla struck at 90", vanilla(s, 90.0, r, q, sig, tt)),
        ("greek delta, bump", (pr(s + h, r, q, sig, tt) - lookback_call(s - h, s - h, r, q, sig, tt, true)) / (2.0 * h)), ("  C / S", c / s),
        ("greek vega per vol point", (pr(s, r, q, sig + 0.01, tt) - pr(s, r, q, sig - 0.01, tt)) / 2.0),
        ("greek rho per rate point", (pr(s, r + 0.01, q, sig, tt) - pr(s, r - 0.01, q, sig, tt)) / 2.0),
        ("greek theta, one day", pr(s, r, q, sig, tt - 1.0 / 365.0) - c),
        ("wrong: dividend ignored, q = 0", pr(s, r, 0.0, sig, tt)), ("wrong: e^bT dropped", lookback_call(s, s, r, q, sig, tt, false)),
        ("try: T = 0.25", pr(s, r, q, sig, 0.25)), ("try: r = q = 5%, formula", pr(s, r, 0.05, sig, tt)),
        ("  integral", by_integral(s, s, r, 0.05, sig, tt))];
    for (name, val) in &rows { println!("{:<42} {:>12.6}", name, val); }
    let a1 = (r - q + 0.5 * sig * sig) * tt / (sig * tt.sqrt()); let (a2, a3) = (a1 - sig * tt.sqrt(), a1 - 2.0 * (r - q) * tt.sqrt() / sig);
    println!("pieces: a1, a2, a3               {:9.6} {:9.6} {:9.6}", a1, a2, a3);
    println!("pieces: N(a1), N(a2), N(-a1), N(-a3)  {:.6} {:.6} {:.6} {:.6}", n_cdf(a1), n_cdf(a2), n_cdf(-a1), n_cdf(-a3));
    let eb = ((r - q) * tt).exp();
    println!("pieces: e^bT, bracket, S e^-rT sig^2/2b  {:.6} {:.6} {:.6}", eb, n_cdf(-a3) - eb * n_cdf(-a1), s * d * sig * sig / (2.0 * (r - q)));
    let sigs: Vec<f64> = (1..9).map(|i| 0.05 * i as f64).collect();
    let line = |f: &dyn Fn(f64) -> f64, p2: usize| sigs.iter().map(|&x| format!("{:6.*}", p2, f(x))).collect::<Vec<_>>().join(" ");
    println!("chart, sigma            {}", line(&|x| x, 2));
    println!("chart, {:<17}{}", "fixed-strike", line(&|x| lookback_put(s, s, r, q, x, tt) + gap_fwd, 2));
    println!("chart, {:<17}{}", "floating", line(&|x| pr(s, r, q, x, tt), 2));
    println!("chart, {:<17}{}", "vanilla", line(&|x| vanilla(s, k, r, q, x, tt), 2));
    let path = [100i64, 96, 91, 88, 93, 97, 94, 99, 104, 101, 107, 110, 108];
    let lows: Vec<i64> = (0..path.len()).map(|i| *path[..=i].iter().min().unwrap()).collect();
    let fmt = |xs: &[i64]| xs.iter().map(|p| format!("{:4}", p)).collect::<Vec<_>>().join(" ");
    println!("path, month-end price  {}", fmt(&path));
    println!("path, lowest so far    {}", fmt(&lows));
    println!("path pays: lookback {}, vanilla {}, fixed-strike {}", path[12] - lows[12], (path[12] - 100).max(0), (path.iter().max().unwrap() - 100).max(0));

    assert!((c - 15.975910).abs() < 5e-7, "closed form vs the shelf's house number");
    let (c90, i90) = (lookback_call(s, 90.0, r, q, sig, tt, true), by_integral(s, 90.0, r, q, sig, tt));
    assert!((c - c2).abs() < 1e-6 && (c90 - i90).abs() < 1e-6, "closed form vs the level-by-level integral, fresh and seasoned");
    assert!((c3 - c).abs() < 3.0 * se3, "exact-minimum simulation within three standard errors");
    assert!(g4 > 5.0 * seg, "daily watching must price clearly below continuous watching");
    assert!((v - di - 9.133306).abs() < 5e-7, "down-and-out vs the shelf's house number");
    assert!((f3 - cfix).abs() < 3.0 * sef && (p3 - p).abs() < 3.0 * sep, "fixed-strike and put vs simulation");
    assert!(((pr(s + h, r, q, sig, tt) - pr(s, r, q, sig, tt)) / h - c / s).abs() < 1e-5, "delta at issue is C/S");
    assert!((pr(s, r, 0.05, sig, tt) - by_integral(s, s, r, 0.05, sig, tt)).abs() < 1e-6, "zero-carry branch vs the integral");
    println!("ALL CHECKS PASS");
}
