// Tomorrow's volatility: EWMA, GARCH and realised measures -- the same check as
// the Python, in Rust.  No crates.  Every number quoted on the card is printed.
// Variances print in percent-squared: a 1% daily return, squared, is 1.00.
// The random numbers are a 64-bit xorshift and Box-Muller, written out here.
use std::f64::consts::PI;

const R: [f64; 8] = [0.01, -0.02, 0.015, -0.005, 0.03, -0.025, 0.01, -0.015]; // daily log returns
const A: [f64; 8] = [0.003, 0.004, 0.002, 0.003, 0.01, 0.008, 0.004, 0.005]; // intraday swings
const LAM: f64 = 0.94;
const OMEGA: f64 = 0.00001;
const ALPHA: f64 = 0.10;
const BETA: f64 = 0.85;
const SEED: f64 = 0.0002;
const P: f64 = 1e4; // decimal -> percent-squared

struct Rng(u64);
impl Rng {
    fn unif(&mut self) -> f64 {
        let mut x = self.0;
        x ^= x << 13; x ^= x >> 7; x ^= x << 17;
        self.0 = x;
        ((x >> 11) as f64 + 0.5) / 9007199254740992.0
    }
    fn normal(&mut self) -> f64 { // one standard bell-curve draw
        let (u1, u2) = (self.unif(), self.unif());
        (-2.0 * u1.ln()).sqrt() * (2.0 * PI * u2).cos()
    }
}

fn pieces(r: f64, a: f64) -> [f64; 4] { [r / 4.0 + a, r / 4.0 - a, r / 4.0 + a / 2.0, r / 4.0 - a / 2.0] }

fn main() {
    let mut rng = Rng(0x9E3779B97F4A7C15);
    // ---- road 1: the three rules, one close at a time ----
    let (mut e, mut g, mut p, mut rv) = (vec![SEED], vec![SEED], vec![SEED], Vec::new());
    for i in 0..8 {
        let r = R[i];
        rv.push(pieces(r, A[i]).iter().fold(0.0, |s, x| s + x * x));
        e.push(LAM * e[i] + (1.0 - LAM) * r * r);
        g.push(OMEGA + ALPHA * r * r + BETA * g[i]);
        p.push(rv[i]);
    }
    println!("rules: lambda {:.2}; omega {:.4}, alpha {:.2}, beta {:.2}; seed {:.4}", LAM, P * OMEGA, ALPHA, BETA, P * SEED);
    println!("day  return%   realised   EWMA  GARCH  lag-RV   (variances in percent-squared)");
    for i in 0..8 {
        println!("{:>3} {:>+8.2} {:>10.4} {:>6.4} {:>6.4} {:>7.4}", i + 1, 100.0 * R[i], P * rv[i], P * e[i], P * g[i], P * p[i]);
    }
    println!("day 9 forecasts: EWMA {:.4}  GARCH {:.4}  lag-RV {:.4}", P * e[8], P * g[8], P * p[8]);
    println!("day 9 as daily vol: EWMA {:.4}%  GARCH {:.4}%; on a $100 share ${:.2} and ${:.2}",
             100.0 * e[8].sqrt(), 100.0 * g[8].sqrt(), 100.0 * e[8].sqrt(), 100.0 * g[8].sqrt());
    for (lab, xs) in [("realised", &rv), ("EWMA", &e), ("GARCH", &g)] {
        let row: Vec<String> = xs[..8].iter().map(|x| format!("{:.2}", P * x)).collect();
        println!("chart {:<8} days 1-8: {}", lab, row.join(" "));
    }
    // ---- road 2: the same forecasts as one weighted sum, no recursion ----
    let n = 8.0;
    let mut e_sum = LAM.powf(n) * SEED;
    let mut g_sum = OMEGA * (1.0 - BETA.powf(n)) / (1.0 - BETA) + BETA.powf(n) * SEED;
    for j in 0..8 {
        e_sum += (1.0 - LAM) * LAM.powf(7.0 - j as f64) * R[j] * R[j];
        g_sum += ALPHA * BETA.powf(7.0 - j as f64) * R[j] * R[j];
    }
    let rv_id: Vec<f64> = (0..8).map(|i| R[i] * R[i] / 4.0 + 2.5 * A[i] * A[i]).collect();
    println!("unrolled sums, day 9: EWMA {:.4}  GARCH {:.4}", P * e_sum, P * g_sum);
    println!("weight on newest square: EWMA {:.2}  GARCH {:.2}; on seed after 8 days: EWMA {:.4}  GARCH {:.4}",
             1.0 - LAM, ALPHA, LAM.powf(n), BETA.powf(n));
    // ---- scoring days 2..8 against realised variance ----
    let names = ["EWMA", "GARCH", "lag-RV"];
    let fc = [&e, &g, &p];
    let (mut mse, mut qlk, mut usual) = ([0.0f64; 3], [0.0f64; 3], [0.0f64; 3]);
    for k in 0..3 {
        for i in 1..8 {
            let (f, t) = (fc[k][i], rv[i]);
            mse[k] += (P * f - P * t).powi(2);
            qlk[k] += t / f - (t / f).ln() - 1.0;
            usual[k] += (P * f).ln() + t / f;
        }
        mse[k] /= 7.0; qlk[k] /= 7.0; usual[k] /= 7.0;
        println!("score {:<6} MSE {:.4}   QLIKE {:.4}   log f + RV/f {:.4}", names[k], mse[k], qlk[k], usual[k]);
    }
    println!("QLIKE gap GARCH - EWMA {:.6}; same gap in log f + RV/f {:.6}", qlk[1] - qlk[0], usual[1] - usual[0]);
    println!("QLIKE for one day, forecast half of RV {:.4}; forecast double RV {:.4}", 2.0 - 2f64.ln() - 1.0, 0.5 - 0.5f64.ln() - 1.0);
    // ---- several days ahead: closed form, iterated, simulated ----
    let (rho, anchor) = (ALPHA + BETA, OMEGA / (1.0 - ALPHA - BETA));
    let closed: Vec<f64> = (1..21).map(|k| anchor + rho.powf(k as f64 - 1.0) * (g[8] - anchor)).collect();
    let mut it = vec![g[8]];
    for k in 0..19 { it.push(OMEGA + rho * it[k]); }
    let (paths, mut sim) = (20000, [0.0f64; 20]);
    for _ in 0..paths {
        let mut h = g[8];
        for k in 0..20 {
            sim[k] += h / paths as f64;
            let z = rng.normal();
            h = OMEGA + ALPHA * h * z * z + BETA * h;
        }
    }
    println!("GARCH anchor {:.4} (daily vol {:.4}%, a year {:.2}%); half-life {:.2} days",
             P * anchor, 100.0 * anchor.sqrt(), 100.0 * (252.0 * anchor).sqrt(), 0.5f64.ln() / rho.ln());
    for k in [1usize, 2, 5, 10, 20] {
        println!("k={:>2} days ahead: closed {:.4}  iterated {:.4}  simulated {:.4}  EWMA {:.4}",
                 k, P * closed[k - 1], P * it[k - 1], P * sim[k - 1], P * e[8]);
    }
    let (ten_g, ten_e) = (closed[..10].iter().fold(0.0, |s, x| s + x), 10.0 * e[8]);
    println!("10-day variance: GARCH sum {:.4}  EWMA {:.4}  10 x GARCH tomorrow {:.4}", P * ten_g, P * ten_e, 10.0 * P * g[8]);
    let row: Vec<String> = closed.iter().map(|c| format!("{:.2}", P * c)).collect();
    println!("chart GARCH k=1..20: {}", row.join(" "));
    println!("chart EWMA k=1..20: flat at {:.2}", P * e[8]);
    // ---- why score against realised variance: its noise, by simulation ----
    let (h0, days) = (SEED, 40000);
    let mut stats: Vec<(usize, f64, f64)> = Vec::new();
    for m in [1usize, 4, 16] {
        let (mut s1, mut s2) = (0.0, 0.0);
        for _ in 0..days {
            let mut v = 0.0;
            for _ in 0..m { v += ((h0 / m as f64).sqrt() * rng.normal()).powi(2); }
            s1 += P * v; s2 += (P * v).powi(2);
        }
        let (mean, var) = (s1 / days as f64, s2 / days as f64 - (s1 / days as f64).powi(2));
        stats.push((m, mean, var));
        println!("proxy, {:>2} pieces a day: mean {:.4}  variance {:.4}  theory 2h^2/m {:.4}",
                 m, mean, var, 2.0 * (P * h0).powi(2) / m as f64);
    }
    // ---- a longer race: 2,500 days simulated from the GARCH rule itself ----
    let (mut h, mut fe, mut fp, mut sc) = (anchor, anchor, anchor, [[0.0f64; 4]; 3]);
    for day in 0..2750 {
        let xs: Vec<f64> = (0..4).map(|_| (h / 4.0).sqrt() * rng.normal()).collect();
        let r = xs.iter().fold(0.0, |s, x| s + x);
        let v = xs.iter().fold(0.0, |s, x| s + x * x);
        if day >= 250 { // first 250 days only warm the rules up
            for (k, f) in [fe, h, fp].iter().enumerate() { // GARCH's forecast is the true h here
                for (j, tgt) in [v, h].iter().enumerate() {
                    sc[k][j] += (P * f - P * tgt).powi(2) / 2500.0;
                    sc[k][2 + j] += ((P * f).ln() + tgt / f) / 2500.0;
                }
            }
        }
        fe = LAM * fe + (1.0 - LAM) * r * r;
        fp = v;
        h = OMEGA + ALPHA * r * r + BETA * h;
    }
    println!("race, 2,500 days    MSE vs RV   MSE vs h   log f+RV/f   log f+h/f");
    for k in 0..3 {
        println!("race {:<6} {:>17.4} {:>10.4} {:>12.4} {:>11.4}", names[k], sc[k][0], sc[k][1], sc[k][2], sc[k][3]);
    }
    // ---- what breaks ----
    let (mut flip, mut g90) = (vec![SEED], SEED);
    for i in 0..8 {
        flip.push((1.0 - LAM) * flip[i] + LAM * R[i] * R[i]);
        g90 = OMEGA + ALPHA * R[i] * R[i] + 0.90 * g90;
    }
    let igarch = g90 + 19.0 * OMEGA; // alpha + beta = 1: no pull, drift up by omega a day
    let peek = (1..8).fold(0.0, |s, i| s + (P * p[i + 1] - P * rv[i]).powi(2)) / 7.0;
    println!("wrong: lambda and 1-lambda swapped, day 9 {:.4}; day 6 {:.4}", P * flip[8], P * flip[5]);
    println!("wrong: beta 0.90 (alpha+beta=1), day 9 {:.4}, 20 days ahead {:.4}, still rising", P * g90, P * igarch);
    println!("wrong: forecast scored against its own day, MSE {:.4}", peek);
    println!("wrong: 365-day year, annual vol from day 9 GARCH {:.2}% not {:.2}%",
             100.0 * (365.0 * g[8]).sqrt(), 100.0 * (252.0 * g[8]).sqrt());

    assert!((0..8).all(|i| (rv[i] - rv_id[i]).abs() < 1e-15), "realised sum vs its identity");
    assert!((e[8] - e_sum).abs() < 1e-15, "EWMA recursion vs unrolled sum");
    assert!((g[8] - g_sum).abs() < 1e-15, "GARCH recursion vs unrolled sum");
    assert!((P * it[19] - P * closed[19]).abs() < 1e-9, "iterated vs closed-form term structure");
    assert!((sim[9] / closed[9] - 1.0).abs() < 0.01, "simulated vs closed-form 10-day forecast");
    assert!(((qlk[1] - qlk[0]) - (usual[1] - usual[0])).abs() < 1e-12, "QLIKE ranking vs usual score");
    assert!((0..3).all(|k| ((1..8).fold(0.0, |s, i| s + (P * fc[k][i]).powi(2) - 2.0 * P * fc[k][i] * P * rv[i] + (P * rv[i]).powi(2)) / 7.0 - mse[k]).abs() < 1e-9), "MSE vs expanded square");
    let rank = |j: usize| { let mut o = vec![0usize, 1, 2]; o.sort_by(|a, b| sc[*a][j].partial_cmp(&sc[*b][j]).unwrap()); o };
    assert!(rank(0) == rank(1), "RV ranks as h does");
    assert!(stats.iter().all(|&(m, _, var)| (var / (2.0 * (P * h0).powi(2) / m as f64) - 1.0).abs() < 0.05), "proxy noise vs 2h^2/m");
    println!("ALL CHECKS PASS");
}
