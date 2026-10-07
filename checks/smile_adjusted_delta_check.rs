// Smile-adjusted delta -- the same check as the Python, in Rust.  Std only, no crates.
// The normal CDF is a series written out here, the random numbers come from a
// splitmix64 generator written out here, and the regression is two sums.
use std::f64::consts::PI;

const S0: f64 = 100.0; const K: f64 = 100.0; const R: f64 = 0.05; const Q: f64 = 0.02; const T: f64 = 1.0;
const SIG0: f64 = 0.20; const BETA: f64 = 0.0004;   // at-the-money vol; skew falls 0.0004 per $ of strike

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }
fn n_cdf(x: f64) -> f64 {                             // 0.5 + phi(x) * (x + x^3/3 + x^5/(3*5) + ...)
    let (mut term, mut total, mut n) = (x, x, 1.0);
    while term.abs() > 1e-17 * total.abs().max(1.0) { n += 2.0; term *= x * x / n; total += term; }
    0.5 + phi(x) * total
}
fn d1(s: f64, sig: f64) -> f64 { ((s / K).ln() + (R - Q + 0.5 * sig * sig) * T) / (sig * T.sqrt()) }
fn call(s: f64, sig: f64) -> f64 {
    let a = d1(s, sig);
    s * (-Q * T).exp() * n_cdf(a) - K * (-R * T).exp() * n_cdf(a - sig * T.sqrt())
}
fn delta(s: f64, sig: f64) -> f64 { (-Q * T).exp() * n_cdf(d1(s, sig)) }
fn vega(s: f64, sig: f64) -> f64 { s * (-Q * T).exp() * phi(d1(s, sig)) * T.sqrt() }
fn gamma(s: f64, sig: f64) -> f64 { (-Q * T).exp() * phi(d1(s, sig)) / (s * sig * T.sqrt()) }
fn vanna(s: f64, sig: f64) -> f64 { -(-Q * T).exp() * phi(d1(s, sig)) * (d1(s, sig) - sig * T.sqrt()) / sig }

fn rule(which: usize, s: f64) -> f64 {                // the vol the K = 100 option is marked at, Acme at s
    match which { 0 => SIG0 - BETA * (K - S0), 1 => SIG0 - BETA * S0 * (K / s - 1.0), _ => SIG0 - BETA * (K + s - 2.0 * S0) }
}
fn row(label: &str, v: f64) { println!("{:<34}{:12.6}", label, v); }
fn row2(label: &str, v: f64) { println!("{:<34}{:12.2}", label, v); }

struct Rng(u64);
impl Rng {
    fn uniform(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0 + 0.5 / 9007199254740992.0
    }
    fn normal_pair(&mut self) -> (f64, f64) {
        let (u1, u2) = (self.uniform(), self.uniform());
        let rad = (-2.0 * u1.ln()).sqrt();
        (rad * (2.0 * PI * u2).cos(), rad * (2.0 * PI * u2 - 0.5 * PI).cos())
    }
}
fn cov(a: &[f64], b: &[f64]) -> f64 {
    let n = a.len() as f64;
    let (ma, mb) = (a.iter().sum::<f64>() / n, b.iter().sum::<f64>() / n);
    a.iter().zip(b).map(|(x, y)| (x - ma) * (y - mb)).sum::<f64>() / n
}

fn main() {
    let names = ["sticky strike", "sticky moneyness", "local-vol rule"];
    let slopes = [0.0, BETA, -BETA];                  // d sigma / dS, by hand
    let (dl, vg, gm, vn) = (delta(S0, SIG0), vega(S0, SIG0), gamma(S0, SIG0), vanna(S0, SIG0));
    row("d1", d1(S0, SIG0));
    row("N(d1)", n_cdf(d1(S0, SIG0)));
    row("phi(d1), bell-curve height", phi(d1(S0, SIG0)));
    row("BS delta e^-qT N(d1)", dl);
    row("vega, per 1.00 of vol", vg);
    row("vega x 0.0004", vg * BETA);
    let mut out = Vec::new();
    for i in 0..3 {                                   // road 1: chain rule.  road 2: bump spot, remark, reprice
        let formula = dl + vg * slopes[i];
        let h = 0.01;
        let bumped = (call(S0 + h, rule(i, S0 + h)) - call(S0 - h, rule(i, S0 - h))) / (2.0 * h);
        out.push((formula, bumped));
        row(&format!("{}, formula", names[i]), formula);
        row(&format!("{}, bump and reprice", names[i]), bumped);
    }

    // strict sticky delta: the vol is a fixed function G of the option's own BS delta
    let ddk = -(-Q * T).exp() * phi(d1(S0, SIG0)) / (K * SIG0 * T.sqrt());   // how delta changes with strike
    let gp = -BETA / ddk;                                                    // skew slope per unit of delta
    let sig_s = gp * gm / (1.0 - gp * vn);
    let solve_vol = |s: f64| { let mut sig = SIG0; for _ in 0..60 { sig = SIG0 + gp * (delta(s, sig) - dl); } sig };
    let strict_bump = (call(S0 + 0.01, solve_vol(S0 + 0.01)) - call(S0 - 0.01, solve_vol(S0 - 0.01))) / 0.02;
    row("gamma", gm);
    row("vanna", vn);
    row("G prime, vol per unit of delta", gp);
    row("1 - G prime x vanna", 1.0 - gp * vn);
    row("strict sticky delta, formula", dl + vg * sig_s);
    row("strict sticky delta, bump", strict_bump);

    // minimum-variance delta: simulate one day of joint spot and vol moves, reprice fully, regress
    let (b, eta, dt, pairs): (f64, f64, f64, usize) = (-BETA, 0.0005, 1.0 / 252.0, 20000);
    let mut rng = Rng(20260919);
    let (mut d_s, mut d_v, mut d_sig) = (Vec::new(), Vec::new(), Vec::new());
    let c0 = call(S0, SIG0);
    for _ in 0..pairs {
        let (z1, z2) = rng.normal_pair();
        for sgn in [1.0, -1.0] {                                             // antithetic pair
            let ds = sgn * S0 * SIG0 * dt.sqrt() * z1;
            let dv = b * ds + sgn * eta * z2;
            d_s.push(ds); d_sig.push(dv); d_v.push(call(S0 + ds, SIG0 + dv) - c0);
        }
    }
    let (v_s, v_sig) = (cov(&d_s, &d_s), cov(&d_sig, &d_sig));
    let h_star = cov(&d_v, &d_s) / v_s;
    let b_hat = cov(&d_sig, &d_s) / v_s;
    let rho = cov(&d_sig, &d_s) / (v_s * v_sig).sqrt();
    let resid_sd = |h: f64| { let e: Vec<f64> = d_v.iter().zip(&d_s).map(|(v, s)| v - h * s).collect(); cov(&e, &e).sqrt() };
    println!("{:<34}{:12}", "simulated days", d_s.len());
    row("daily spot move sd, $", v_s.sqrt());
    row("spot-vol correlation", rho);
    row("vol-on-spot slope, fitted", b_hat);
    row("min-variance delta, regression", h_star);
    row("min-variance delta, BS + vega x b", dl + vg * b_hat);
    let (sd_bs, sd_mv) = (resid_sd(dl), resid_sd(h_star));
    row2("daily P&L sd per 10,000, BS delta", 10000.0 * sd_bs);
    row2("daily P&L sd per 10,000, MV delta", 10000.0 * sd_mv);
    let cut = (sd_bs * sd_bs - sd_mv * sd_mv).sqrt();                        // the part the MV hedge removes
    let cut_pred = vg * b.abs() * v_s.sqrt();                                // vega x |b| x sd of the spot move
    row2("removed sd per 10,000, measured", 10000.0 * cut);
    row2("removed sd per 10,000, vega b sd", 10000.0 * cut_pred);
    let hs: Vec<String> = (0..8).map(|i| format!("{:6.2}", 0.55 + 0.01 * i as f64)).collect();
    println!("chart, hedge ratio   {}", hs.join(" "));
    let sds: Vec<String> = (0..8).map(|i| format!("{:6.2}", 10000.0 * resid_sd(0.55 + 0.01 * i as f64))).collect();
    println!("chart, sd per 10,000 {}", sds.join(" "));
    let spots = [90.0, 95.0, 100.0, 105.0, 110.0];
    println!("smile today, strike   {}", spots.iter().map(|k| format!("{:7.0}", k)).collect::<String>());
    println!("smile today, vol %    {}", spots.iter().map(|&k| format!("{:7.2}", 100.0 * (SIG0 - BETA * (k - S0)))).collect::<String>());
    println!("chart, Acme price     {}", spots.iter().map(|s| format!("{:7.0}", s)).collect::<String>());
    for (i, tag) in ["strike", "moneyness", "local-vol"].iter().enumerate() {
        println!("chart, vol % {:<9}{}", tag, spots.iter().map(|&s| format!("{:7.2}", 100.0 * rule(i, s))).collect::<String>());
    }

    // what breaks, and try changing
    row("wrong: shift of -vega x 0.0004", dl - vg * BETA);
    row("wrong: vega per 1.00 x -0.04", dl + vg * (-0.04));
    row2("shares per 10,000 calls, gap", 10000.0 * vg * BETA);
    row("put: BS delta", dl - (-Q * T).exp());
    row("put: local-vol rule", dl - (-Q * T).exp() - vg * BETA);
    let ((x0, y0), (x1, y1), (x2, y2)) = ((92.15, 0.24), (100.0, 0.20), (119.93, 0.18));   // the house smile
    let house = y0 * (x1 - x2) / ((x0 - x1) * (x0 - x2)) + y1 * (2.0 * x1 - x0 - x2) / ((x1 - x0) * (x1 - x2))
        + y2 * (x1 - x0) / ((x2 - x0) * (x2 - x1));                          // slope at 100 of the parabola
    row("house smile slope at 100, per $", house);
    row("house smile, local-vol rule", dl + vg * house);

    for (i, (formula, bumped)) in out.iter().enumerate() {
        assert!((formula - bumped).abs() < 1e-6, "{}", names[i]);         // chain rule vs full reprice
    }
    assert!(((dl + vg * sig_s) - strict_bump).abs() < 1e-6);                // implicit rule vs solve-and-reprice
    assert!((h_star - (dl + vg * b)).abs() < 1e-3);                         // regression vs chain rule, true b
    assert!((cut / cut_pred - 1.0).abs() < 0.03);                           // risk removed vs vega x b x sd(dS)
    println!("ALL CHECKS PASS");
}
