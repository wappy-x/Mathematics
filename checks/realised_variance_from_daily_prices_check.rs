// Realised variance from daily prices -- the same check as realised_variance_from_daily_prices_check.py.
// Standard library only, no crates.  Same splitmix64 + Box-Muller draws, so the same Acme month.
// Compile: rustc --edition 2021 -O realised_variance_from_daily_prices_check.rs -o /tmp/rv_check
use std::f64::consts::PI;

struct Rng { x: u64, spare: Option<f64> }
impl Rng {
    fn u(&mut self) -> f64 {
        self.x = self.x.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.x;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        (((z ^ (z >> 31)) >> 11) as f64 + 0.5) / 9007199254740992.0
    }
    fn z(&mut self) -> f64 {
        if let Some(v) = self.spare.take() { return v; }
        let r = (-2.0 * self.u().ln()).sqrt();
        let t = 2.0 * PI * self.u();
        self.spare = Some(r * t.sin());
        r * t.cos()
    }
}

const SIG: f64 = 0.20; const MU: f64 = 0.03; const H: f64 = 0.001; const DAYS: usize = 21; const M: usize = 390;
const T: f64 = DAYS as f64 / 252.0;
type Ohlc = (f64, f64, f64, f64);

fn month(g: &mut Rng) -> (Vec<f64>, Vec<Ohlc>) {       // log prices every 5 minutes, daily open/high/low/close
    let dt = 1.0 / (252 * M) as f64;
    let (a, b) = ((MU - 0.5 * SIG * SIG) * dt, SIG * dt.sqrt());
    let mut x = 100.0_f64.ln();
    let (mut prints, mut ohlc) = (vec![x], Vec::new());
    for _ in 0..DAYS {
        let (o, mut hi, mut lo) = (x, x, x);
        for j in 0..M {
            x += a + b * g.z(); hi = hi.max(x); lo = lo.min(x);
            if (j + 1) % 5 == 0 { prints.push(x); }
        }
        ohlc.push((o, hi, lo, x));
    }
    (prints, ohlc)
}

fn rv(p: &[f64], k: usize) -> f64 {                    // annualised: squared log returns every k prints, x 252/N
    let mut s = 0.0;
    let mut i = k;
    while i < p.len() { s += (p[i] - p[i - k]).powi(2); i += k; }
    252.0 / DAYS as f64 * s
}
fn parkinson(oh: &[Ohlc]) -> f64 {
    let l4 = 4.0 * 2.0_f64.ln();
    252.0 / DAYS as f64 * oh.iter().fold(0.0, |s, &(_, h, l, _)| s + (h - l).powi(2) / l4)
}
fn garman_klass(oh: &[Ohlc]) -> f64 {
    let w = 2.0 * 2.0_f64.ln() - 1.0;
    252.0 / DAYS as f64 * oh.iter().fold(0.0, |s, &(o, h, l, c)| s + 0.5 * (h - l).powi(2) - w * (c - o).powi(2))
}
fn noise_formula(n: usize, h: f64) -> f64 { SIG * SIG + 2.0 * n as f64 * h * h / T }
fn bounce(g: &mut Rng, p: &[f64]) -> Vec<f64> { p.iter().map(|x| x + if g.u() < 0.5 { H } else { -H }).collect() }

fn main() {
    let mut g = Rng { x: 135, spare: None };
    let (clean, ohlc) = month(&mut g);
    let traded = bounce(&mut g, &clean);                 // each print at the bid or the ask
    let closes: Vec<f64> = traded.iter().step_by(78).cloned().collect();
    let rets: Vec<f64> = (1..=DAYS).map(|i| closes[i] - closes[i - 1]).collect();
    let ssq: f64 = rets.iter().map(|r| r * r).sum();
    let nd = DAYS as f64;
    let var_cc = 252.0 / nd * ssq;
    println!("chart, closes {}", closes.iter().map(|c| format!("{:.2}", c.exp())).collect::<Vec<_>>().join(" "));
    for i in 0..3 {
        println!("day {}  close {:8.4}  log return {:+.6}  squared {:.8}", i + 1, closes[i + 1].exp(), rets[i], rets[i] * rets[i]);
    }
    println!("sum of 21 squared log returns    {:.6}", ssq);
    println!("x 252/21 = realised variance      {:.6}", var_cc);
    println!("realised vol, closes              {:.2}%", 100.0 * var_cc.sqrt());
    let mean = rets.iter().sum::<f64>() / nd;
    let dm: f64 = rets.iter().map(|r| (r - mean).powi(2)).sum();
    println!("textbook: mean removed, N-1       {:.2}%", 100.0 * (252.0 / (nd - 1.0) * dm).sqrt());
    println!("wrong: x 365 not 252              {:.2}%", 100.0 * (365.0 / nd * ssq).sqrt());
    let simple: f64 = rets.iter().map(|r| (r.exp() - 1.0).powi(2)).sum();
    println!("wrong: simple returns             {:.2}%", 100.0 * (252.0 / nd * simple).sqrt());
    println!("wrong: variance read as vol       {:.2}%", 100.0 * var_cc);
    println!("true quadratic variation 21 days  {:.6}", SIG * SIG * T);
    println!("5-min, true prices                {:.2}%   n = {}", 100.0 * rv(&clean, 1).sqrt(), clean.len() - 1);
    println!("5-min, as traded                  {:.2}%   formula {:.2}%", 100.0 * rv(&traded, 1).sqrt(), 100.0 * noise_formula(1638, H).sqrt());
    println!("bounce adds 2 n h^2 / T           {:.6}   total {:.6}", 2.0 * 1638.0 * H * H / T, noise_formula(1638, H));
    println!("constants  4 ln 2 = {:.4}   2 ln 2 - 1 = {:.4}", 4.0 * 2.0_f64.ln(), 2.0 * 2.0_f64.ln() - 1.0);
    println!("one month: Parkinson              {:.2}%", 100.0 * parkinson(&ohlc).sqrt());
    println!("one month: Garman-Klass           {:.2}%", 100.0 * garman_klass(&ohlc).sqrt());

    // ---- many months: how much each estimator wobbles around the truth ----
    let p = 400usize;
    let ks = [1usize, 2, 3, 6, 13, 26, 39, 78];
    let mut est: Vec<Vec<f64>> = vec![Vec::new(), Vec::new(), Vec::new()];
    let (mut sig_t, mut sig_c) = (vec![0.0; ks.len()], vec![0.0; ks.len()]);
    for _ in 0..p {
        let (cl, oh) = month(&mut g);
        let tr = bounce(&mut g, &cl);
        for (j, &k) in ks.iter().enumerate() { sig_t[j] += rv(&tr, k) / p as f64; sig_c[j] += rv(&cl, k) / p as f64; }
        est[0].push(252.0 / nd * oh.iter().fold(0.0, |s, &(o, _, _, c)| s + (c - o).powi(2)));
        est[1].push(parkinson(&oh)); est[2].push(garman_klass(&oh));
    }
    let names = ["close-to-close", "Parkinson", "Garman-Klass"];
    let stats: Vec<(f64, f64)> = est.iter().map(|xs| {
        let m = xs.iter().sum::<f64>() / p as f64;
        (m, (xs.iter().map(|x| (x - m).powi(2)).sum::<f64>() / (p - 1) as f64).sqrt())
    }).collect();
    let cv_c = stats[0].1 / stats[0].0;                 // spread/mean of close-to-close
    println!("{} months       average    spread/mean   efficiency", p);
    for (name, &(m, sd)) in names.iter().zip(stats.iter()) {
        println!("{:<15} {:7.2}%   {:11.4}   {:10.2}", name, 100.0 * m.sqrt(), sd / m, (cv_c * m / sd).powi(2));
    }
    println!("signature, 400-month average  minutes  as traded  formula  true prices");
    for (j, &k) in ks.iter().enumerate() {
        println!("signature  {:7}  {:9.2}  {:7.2}  {:11.2}", 5 * k, 100.0 * sig_t[j].sqrt(), 100.0 * noise_formula(1638 / k, H).sqrt(), 100.0 * sig_c[j].sqrt());
    }
    println!("theory, close-to-close spread/mean sqrt(2/21) = {:.4}", (2.0 / nd).sqrt());
    println!("try: half-spread 5 cents, 5-min   {:.2}%", 100.0 * noise_formula(1638, 0.0005).sqrt());
    println!("try: 1-minute prints, 10 cents    {:.2}%", 100.0 * noise_formula(8190, H).sqrt());
    println!("try: 252 days, spread/mean        {:.4}", (2.0 / 252.0_f64).sqrt());

    let (mc, sdc) = stats[0];
    assert!((mc - SIG * SIG).abs() < 3.0 * sdc / (p as f64).sqrt() + 1e-4, "close-to-close is unbiased for sigma^2");
    assert!((sdc / mc - (2.0 / nd).sqrt()).abs() < 0.15 * (2.0 / nd).sqrt(), "its wobble matches sqrt(2/N)");
    assert!((sig_t[0].sqrt() - noise_formula(1638, H).sqrt()).abs() < 0.003, "noise bias: simulation vs formula");
    assert!((rv(&clean, 1).sqrt() - SIG).abs() < 0.01, "5-min true prices recover 20%");
    for &(m, sd) in &stats[1..] {
        assert!((cv_c * m / sd).powi(2) > 3.0, "ranges beat closes");
        assert!(0.85 * SIG * SIG < m && m < SIG * SIG, "minute ranges read a little low");
    }
    println!("ALL CHECKS PASS");
}
