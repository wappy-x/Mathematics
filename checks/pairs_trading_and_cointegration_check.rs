// Pairs trading and cointegration -- the same check as the Python, std only, no crates.
// Own random numbers (splitmix64 + Box-Muller), least squares, Dickey-Fuller, critical values.
// Compile: rustc --edition 2021 -O pairs_trading_and_cointegration_check.rs -o /tmp/pairs_check
use std::f64::consts::PI;

struct Rng { s: u64 }
impl Rng {
    fn u(&mut self) -> f64 {
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        (((z ^ (z >> 31)) >> 11) as f64 + 0.5) / 9007199254740992.0
    }
    fn z(&mut self) -> f64 { let a = self.u(); (-2.0 * a.ln()).sqrt() * (2.0 * PI * self.u()).cos() }
}

fn mean(v: &[f64]) -> f64 { v.iter().sum::<f64>() / v.len() as f64 }

// fit y = c + b x; return (b, c, R^2)
fn ols(x: &[f64], y: &[f64]) -> (f64, f64, f64) {
    let (mx, my) = (mean(x), mean(y));
    let (mut sxx, mut sxy, mut syy) = (0.0, 0.0, 0.0);
    for i in 0..x.len() {
        sxx += (x[i] - mx) * (x[i] - mx);
        sxy += (x[i] - mx) * (y[i] - my);
        syy += (y[i] - my) * (y[i] - my);
    }
    (sxy / sxx, my - sxy / sxx * mx, sxy * sxy / (sxx * syy))
}

// Dickey-Fuller: regress the change on the lagged level; return (slope rho, its t)
fn df_t(u: &[f64], constant: bool) -> (f64, f64) {
    let lag = &u[..u.len() - 1];
    let d: Vec<f64> = (0..u.len() - 1).map(|i| u[i + 1] - u[i]).collect();
    let (b, c, sxx, k) = if constant {
        let (b, c, _) = ols(lag, &d);
        let m = mean(lag);
        (b, c, lag.iter().map(|a| (a - m) * (a - m)).sum::<f64>(), 2.0)
    } else {
        let sxx: f64 = lag.iter().map(|a| a * a).sum();
        let b = lag.iter().zip(&d).map(|(a, e)| a * e).sum::<f64>() / sxx;
        (b, 0.0, sxx, 1.0)
    };
    let rss: f64 = lag.iter().zip(&d).map(|(a, e)| (e - c - b * a).powi(2)).sum();
    (b, b / (rss / (d.len() as f64 - k) / sxx).sqrt())
}

fn walk(r: &mut Rng, n: usize, start: f64, sd: f64) -> Vec<f64> {
    let mut w = vec![start];
    for _ in 1..n { let next = w[w.len() - 1] + sd * r.z(); w.push(next); }
    w
}

// B wanders; A = 1.3 B + a spread pulled back by phi; C is an unrelated third share
fn year(seed: u64, phi: f64, n: usize) -> (Rng, Vec<f64>, Vec<f64>, Vec<f64>) {
    let mut r = Rng { s: seed };
    let b = walk(&mut r, n, 100.0, 1.0);
    let mut u = vec![0.5 / (1.0 - phi * phi).sqrt() * r.z()];
    for _ in 1..n { let next = phi * u[u.len() - 1] + 0.5 * r.z(); u.push(next); }
    let a: Vec<f64> = (0..n).map(|i| 1.3 * b[i] + u[i]).collect();
    let c = walk(&mut r, n, 100.0, 1.0);
    (r, b, a, c)
}

fn tidy(v: f64) -> f64 { if v.abs() < 1e-9 { 0.0 } else { v } }
fn show(lab: &str, v: f64) { println!("{:<34}{:>12.6}", lab, v); }
fn money(lab: &str, v: f64) { println!("{:<34}{:>12.2}", lab, v); }
fn row(lab: &str, v: &[f64]) {
    let s: Vec<String> = v.iter().map(|x| format!("{:.2}", tidy(*x))).collect();
    println!("{}{}", lab, s.join(" "));
}
fn q5(v: &[f64]) -> f64 { let mut s = v.to_vec(); s.sort_by(|a, b| a.partial_cmp(b).unwrap()); s[v.len() / 20] }
fn resid(x: &[f64], y: &[f64], b: f64, c: f64) -> Vec<f64> { (0..x.len()).map(|i| y[i] - c - b * x[i]).collect() }

fn main() {
    // ---- road 1: the six-date table, retailer B and retailer A, dollars per share ----
    let b = [100.0, 101.0, 99.0, 100.0, 102.0, 101.0];
    let a = [130.0, 132.3, 129.7, 128.0, 132.6, 131.3];
    let (beta, c, _) = ols(&b, &a);
    let (mut num, mut den) = (0.0, 0.0); // road 2: slopes between every two dates, pooled
    for i in 0..6 { for j in i + 1..6 { num += (b[i] - b[j]) * (a[i] - a[j]); den += (b[i] - b[j]).powi(2); } }
    let beta_pw = num / den;
    let (mb, ma) = (mean(&b), mean(&a)); // road 3: golden-section search on the misfit
    let rss = |s: f64| -> f64 { (0..6).map(|i| ((a[i] - ma) - s * (b[i] - mb)).powi(2)).sum() };
    let (mut lo, mut hi, g) = (0.0_f64, 5.0_f64, (5.0_f64.sqrt() - 1.0) / 2.0);
    for _ in 0..80 {
        let (m1, m2) = (hi - g * (hi - lo), lo + g * (hi - lo));
        if rss(m1) < rss(m2) { hi = m2 } else { lo = m1 }
    }
    let beta_gs = (lo + hi) / 2.0;
    let res = resid(&b, &a, beta, c);
    let (rho, t6) = df_t(&res, false);
    show("table: beta, least squares", beta); show("table: beta, pairwise slopes", beta_pw);
    show("table: beta, golden-section search", beta_gs); show("table: intercept c", tidy(c));
    row(&format!("{:<34}", "table: spread A - 1.3 B"), &res);
    show("table: misfit, sum of squares", res.iter().map(|v| v * v).sum());
    show("table: rho", rho); show("table: t = rho / its std error", t6);
    show("wrong: regress B on A, invert", 1.0 / ols(&a, &b).0);

    // ---- the trade: buy 100 A at date 3, short 130 B, close at date 4 ----
    let (na, nb) = (100.0, 130.0);
    let pnl_legs = na * (a[4] - a[3]) - nb * (b[4] - b[3]);
    let pnl_spread = na * (res[4] - res[3]);
    money("trade: long leg at entry", na * a[3]); money("trade: short leg at entry", nb * b[3]);
    money("trade: P&L, leg by leg", pnl_legs); money("trade: P&L, 100 x spread change", pnl_spread);
    money("wrong: 128 B, both prices drift", na * 1.3 * 10.0 - 128.0 * 10.0);

    // ---- road 4: a simulated year of 251 days, pull-back 0.9 a day, and an unrelated third share C ----
    let phi = 0.9;
    let (mut r, bs_p, as_p, cs_p) = year(2030, phi, 251);
    let (bs, cs, r2s) = ols(&bs_p, &as_p);
    let sp = resid(&bs_p, &as_p, bs, cs);
    let (rho_s, t_s) = df_t(&sp, false);
    let (bc, cc, r2c) = ols(&cs_p, &as_p);
    let spc = resid(&cs_p, &as_p, bc, cc);
    let t_c = df_t(&spc, false).1;
    for (lab, v) in [("sim: beta", bs), ("sim: intercept c", cs), ("sim: R^2", r2s), ("sim: rho", rho_s),
                     ("sim: 1 + rho, true 0.9", 1.0 + rho_s), ("sim: half-life, days", 0.5_f64.ln() / (1.0 + rho_s).ln()),
                     ("  half-life if 0.9 exactly", 0.5_f64.ln() / phi.ln()), ("sim: t", t_s),
                     ("unrelated: beta", bc), ("unrelated: R^2", r2c), ("unrelated: t", t_c)] { show(lab, v); }

    // ---- road 5, the referee: 4000 pairs of unrelated walks; what t does fitting alone produce? ----
    let (reps, n) = (4000, 251);
    let (mut teg, mut tdc, mut td0, mut r2n) = (vec![], vec![], vec![], vec![]);
    for _ in 0..reps {
        let (x, y) = (walk(&mut r, n, 100.0, 1.0), walk(&mut r, n, 100.0, 1.0));
        let (bb, c0, q) = ols(&x, &y);
        teg.push(df_t(&resid(&x, &y, bb, c0), false).1);
        tdc.push(df_t(&y, true).1); td0.push(df_t(&y.iter().map(|v| v - y[0]).collect::<Vec<f64>>(), false).1);
        r2n.push(q);
    }
    let (q_eg, q_dc, q_d0) = (q5(&teg), q5(&tdc), q5(&td0));
    let pct = |cut: f64| 100.0 * teg.iter().filter(|t| **t < cut).count() as f64 / reps as f64;
    let mut sr = r2n.clone(); sr.sort_by(|a, b| a.partial_cmp(b).unwrap());
    for (lab, v) in [("5% cut, Engle-Granger (MK -3.36)", q_eg), ("5% cut, 1 series+const (MK -2.87)", q_dc),
                     ("5% cut, 1 series bare (MK -1.94)", q_d0), ("false alarms %, E-G cutoff", pct(q_eg)),
                     ("false alarms %, 1 series+const", pct(q_dc)), ("false alarms %, 1 series bare", pct(q_d0)),
                     ("unrelated pairs: median R^2", sr[reps / 2])] { show(lab, v); }

    // ---- try changing: a slower pull-back, and another year from another seed ----
    for (lab, s, p) in [("try: phi = 0.995", 2030, 0.995), ("try: seed 2026", 2026, 0.9)] {
        let (_, x, y, _) = year(s, p, 251);
        let (bb, c0, _) = ols(&x, &y);
        println!("{:<34}{:>12.6}{:>12.6}", format!("{}: beta, t", lab), bb, df_t(&resid(&x, &y, bb, c0), false).1);
    }

    // ---- chart points, every 10th day ----
    let idx: Vec<usize> = (0..n).step_by(10).collect();
    let days: Vec<String> = idx.iter().map(|i| i.to_string()).collect();
    println!("chart, day   {}", days.join(" "));
    row("chart, A     ", &idx.iter().map(|&i| as_p[i]).collect::<Vec<f64>>());
    row("chart, 1.3B  ", &idx.iter().map(|&i| 1.3 * bs_p[i]).collect::<Vec<f64>>());
    row("chart, sprd  ", &idx.iter().map(|&i| sp[i]).collect::<Vec<f64>>());
    row("chart, unrel ", &idx.iter().map(|&i| spc[i]).collect::<Vec<f64>>());

    assert!((beta - 1.3).abs() < 1e-12 && (beta_pw - 1.3).abs() < 1e-12, "table built as A = 1.3 B + (0,1,1,-2,0,0)");
    assert!((beta_gs - beta_pw).abs() < 1e-6, "search and pairwise slopes agree");
    assert!((rho - (-7.0 / 6.0)).abs() < 1e-12, "hand-worked rho = -7/6");
    assert!((t6 - (-14.0 / 35.0_f64.sqrt())).abs() < 1e-9, "hand-worked t = -14/sqrt(35)");
    assert!((pnl_legs - pnl_spread).abs() < 1e-9, "leg-by-leg P&L equals shares x spread change");
    assert!((bs - 1.3).abs() < 0.03, "fitted ratio near the 1.3 the year was built with");
    assert!(((1.0 + rho_s) - phi).abs() < 0.08, "fitted pull-back near the 0.9 it was built with");
    assert!((q_eg - (-3.36)).abs() < 0.15, "Engle-Granger 5% cutoff vs MacKinnon 2010, two series, T=250");
    assert!((q_dc - (-2.87)).abs() < 0.12, "Dickey-Fuller 5% cutoff with constant vs MacKinnon 2010");
    assert!((q_d0 - (-1.94)).abs() < 0.12, "Dickey-Fuller 5% cutoff, no constant, vs MacKinnon 2010");
    assert!(t_s < q_eg && q_eg < t_c, "the tied pair passes, the unrelated pair does not");
    println!("ALL CHECKS PASS");
}
