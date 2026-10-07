// CVA -- the same check as cva_check.py, in Rust.  Standard library only, no crates.
// The Acme call (S = K = 100, r = 5%, q = 2%, sigma = 20%, T = 1) bought from
// Northwind (hazard 2% a year, recovery 40%).  The normal CDF is a series, the
// integrals are Simpson's rule, the random numbers are splitmix64 plus Box-Muller.
use std::f64::consts::PI;

const S: f64 = 100.0;
const K: f64 = 100.0;
const RATE: f64 = 0.05;
const Q_DIV: f64 = 0.02;
const SIG: f64 = 0.20;
const T: f64 = 1.0;
const LAM: f64 = 0.02;
const REC: f64 = 0.40;
const LGD: f64 = 1.0 - REC;

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }  // bell-curve height
fn n_cdf(x: f64) -> f64 {                                         // 1/2 + phi(x)(x + x^3/3 + x^5/15 + ...)
    if x < -9.0 { return 0.0; }
    if x > 9.0 { return 1.0; }
    let (mut term, mut total, mut k) = (x, x, 1.0);
    while term.abs() > 1e-17 * total.abs() { k += 2.0; term *= x * x / k; total += term; }
    0.5 + phi(x) * total
}

fn bs(s: f64, left: f64, put: bool) -> f64 {                      // Acme option with `left` years to run
    if left <= 1e-12 { return if put { (K - s).max(0.0) } else { (s - K).max(0.0) }; }
    let v = SIG * left.sqrt();
    let d1 = ((s / K).ln() + (RATE - Q_DIV + 0.5 * SIG * SIG) * left) / v;
    if put { return K * (-RATE * left).exp() * n_cdf(v - d1) - s * (-Q_DIV * left).exp() * n_cdf(-d1); }
    s * (-Q_DIV * left).exp() * n_cdf(d1) - K * (-RATE * left).exp() * n_cdf(d1 - v)
}

fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 {   // area under f, n even
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    s * h / 3.0
}

fn dee(t: f64, sign: f64) -> f64 {   // discounted expected exposure, integrated over Acme's price at t
    let (drift, vol) = ((RATE - Q_DIV - 0.5 * SIG * SIG) * t, SIG * t.sqrt());
    let lo = if t < T { -8.0 } else { ((K / S).ln() - drift) / vol };   // at expiry, start at the kink
    let f = |z: f64| (sign * bs(S * (drift + vol * z).exp(), T - t, false)).max(0.0) * phi(z);
    (-RATE * t).exp() * simpson(f, lo, 8.0, 2000)
}

fn surv(t: f64, lam: f64) -> f64 { (-lam * t).exp() }              // survival to t

fn bucketed(n: usize) -> (f64, Vec<f64>) {                         // road 2: sum over n buckets
    let parts: Vec<f64> = (0..n).map(|i| {
        let (a, b, m) = (i as f64 * T / n as f64, (i + 1) as f64 * T / n as f64, (i as f64 + 0.5) * T / n as f64);
        LGD * dee(m, 1.0) * (surv(a, LAM) - surv(b, LAM))
    }).collect();
    (parts.iter().sum(), parts)
}

struct Rng(u64);
impl Rng {
    fn uniform(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 * (1.0 / 9007199254740992.0) + 0.5 / 9007199254740992.0
    }
}

fn main() {
    let (c0, p0) = (bs(S, T, false), bs(S, T, true));
    let pd = 1.0 - surv(T, LAM);
    let cva_closed = LGD * c0 * pd;                                // road 1: loss x price x default chance
    let (cva_52, weekly) = bucketed(52);
    let (cva_1, _) = bucketed(1);

    let mut rng = Rng(20260928);                                   // road 3: simulate the default date
    let m = 400000;
    let (mut acc, mut acc2) = (0.0, 0.0);
    for _ in 0..m {
        let (u1, u2, u3) = (rng.uniform(), rng.uniform(), rng.uniform());
        let tau = -(1.0 - u1 * pd).ln() / LAM;                    // a default date, given one before T
        let z = (-2.0 * u2.ln()).sqrt() * (2.0 * PI * u3).cos();
        let s_tau = S * ((RATE - Q_DIV - 0.5 * SIG * SIG) * tau + SIG * tau.sqrt() * z).exp();
        let x = LGD * pd * (-RATE * tau).exp() * bs(s_tau, T - tau, false);
        acc += x; acc2 += x * x;
    }
    let cva_mc = acc / m as f64;
    let se_mc = ((acc2 / m as f64 - cva_mc * cva_mc) / m as f64).sqrt();

    let s_run = LGD * LAM;                                         // road 4: a CDS on the exposure
    let annuity_e = simpson(|t| dee(t, 1.0) * surv(t, LAM), 0.0, T, 8);
    let cva_cds = s_run * annuity_e;
    let risky = c0 - cva_closed;
    let risky_disc = c0 * (-LGD * LAM * T).exp();                  // approximate road: risky discounting
    let dee_end = dee(T, 1.0);

    let rows: Vec<(&str, f64)> = vec![
        ("clean call C0", c0), ("clean put P0", p0), ("loss given default 1-R", LGD),
        ("default chance to T, 1-e^-lam T", pd),
        ("1 closed form (1-R) C0 PD", cva_closed), ("2 bucketed sum, 52 weeks", cva_52),
        ("  one bucket only", cva_1), ("3 simulated default dates", cva_mc), ("  standard error", se_mc),
        ("4 CDS view: spread x annuity", cva_cds),
        ("  running spread (1-R) lam", s_run), ("  exposure annuity int DEE Q dt", annuity_e),
        ("risky call C0 - CVA", risky), ("risky discounting C0 e^-(1-R)lam T", risky_disc),
        ("DEE at expiry, by integration", dee_end),
        ("wrong: R in place of 1-R", REC * c0 * pd),
        ("wrong: exposure not discounted", LGD * c0 * LAM * (((RATE - LAM) * T).exp() - 1.0) / (RATE - LAM)),
        ("wrong: risky discount and CVA", risky_disc - cva_closed),
        ("wrong: CVA charged on a call sold", cva_closed), ("  right: sold call DEE at 6 months", dee(0.5, -1.0)),
        ("try: hazard 5%", LGD * c0 * (1.0 - surv(T, 0.05))), ("try: recovery 0", c0 * pd),
        ("try: long put", LGD * p0 * pd), ("try: 5-year call", LGD * bs(S, 5.0, false) * (1.0 - surv(5.0, LAM))),
    ];
    for (name, v) in &rows { println!("{:<36}{:12.6}", name, v); }
    println!();
    let ts = [0.0, 0.25, 0.5, 0.75, 1.0];
    let join = |v: Vec<String>| v.join(" ");
    println!("chart, years      {}", join(ts.iter().map(|t| format!("{:6.2}", t)).collect()));
    println!("chart, EE         {}", join(ts.iter().map(|t| format!("{:6.2}", (RATE * t).exp() * dee(*t, 1.0))).collect()));
    println!("chart, DEE        {}", join(ts.iter().map(|t| format!("{:6.2}", dee(*t, 1.0))).collect()));
    let hz: Vec<f64> = (0..11).map(|i| i as f64 / 100.0).collect();
    println!("chart, hazard %   {}", join(hz.iter().map(|h| format!("{:6.0}", 100.0 * h)).collect()));
    println!("chart, CVA cents  {}", join(hz.iter().map(|h| format!("{:6.2}", 100.0 * LGD * c0 * (1.0 - surv(T, *h)))).collect()));
    println!("chart, lam T cents{}", join(hz.iter().map(|h| format!("{:6.2}", 100.0 * LGD * c0 * h * T)).collect()));
    println!("bars, CVA cents by quarter {}", join((0..4).map(|j| format!("{:.2}", 100.0 * weekly[13 * j..13 * j + 13].iter().sum::<f64>())).collect()));

    assert!((c0 - 9.227005508154).abs() < 1e-9, "own normal CDF reproduces the house call");
    assert!((p0 - 6.330080627550).abs() < 1e-9, "and the house put");
    assert!((dee_end - c0).abs() < 1e-6, "payoff averaged at expiry, discounted, is today's price");
    assert!((cva_52 - cva_closed).abs() < 5e-6, "52-week sum with integrated exposure agrees to four decimals");
    assert!((cva_mc - cva_closed).abs() < 4.0 * se_mc, "simulation within four standard errors");
    assert!((cva_cds - cva_closed).abs() < 1e-6, "CDS view: spread times exposure annuity");
    println!("ALL CHECKS PASS");
}
