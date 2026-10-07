// Backtesting pitfalls -- the same check as the Python, in Rust.  No crates.  Road 1 simulates
// 40 ten-year histories of a 50-slot model market with a home-made random number generator;
// road 2 computes every Sharpe ratio exactly from the model, with a home-made bell-curve area.
use std::f64::consts::PI;

const SF: f64 = 0.015; const SE1: f64 = 0.012; const SE2: f64 = 0.006; const B: f64 = 0.5; const K: usize = 20;
const M: usize = 50; const FAIL: usize = 15; const L: usize = 250; const MU: f64 = -0.005; const C: f64 = 0.0005;
const N: usize = 2520; const W: usize = K + 2; const H: usize = 40; const BP: f64 = 1e4;
const NAMES: [&str; 5] = ["look-ahead", "survivors, no costs", "survivors, costs", "all firms, no costs", "honest"];
const FLAGS: [(usize, bool, bool); 5] = [(1, false, false), (2, false, false), (2, false, true), (2, true, false), (2, true, true)];

fn pdf(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }
fn ncdf(x: f64) -> f64 {                              // bell-curve area left of x, by its power series
    let (mut term, mut total, mut k) = (x, x, 1.0);
    while term.abs() > 1e-17 { term *= x * x / (2.0 * k + 1.0); total += term; k += 1.0; }
    0.5 + pdf(x) * total
}
fn deaths() -> Vec<usize> { (0..FAIL).map(|j| (L as f64 + ((N - L) * (j + 1)) as f64 / FAIL as f64) as usize).collect() }

// model pieces for one stretch of years: (vr, sS, g2, g1, p)
fn regime(se: f64, b: f64) -> (f64, f64, f64, f64, f64) {
    let vz = se * se / (1.0 - b * b);
    let vr = SF * SF + 2.0 * vz * (1.0 - b);
    let ss = (K as f64 * SF * SF + 2.0 * vz * (1.0 - b.powf(K as f64))).sqrt();
    let g2 = -vz * b * (1.0 - b) * (1.0 - b.powf(K as f64));
    let rho = ((K - 1) as f64 * SF * SF + vz * (2.0 * b - b.powf((K + 1) as f64) - b.powf((K - 1) as f64))) / ss.powf(2.0);
    (vr, ss, g2, g2 / b, rho.acos() / PI)
}
fn bet(vr: f64, ss: f64, g: f64, j: f64, mu: f64) -> (f64, f64) {   // one bet: -sign(signal) x return
    let m = j * mu / ss;
    let e = -mu * (2.0 * ncdf(m) - 1.0) - g / ss * 2.0 * pdf(m);
    (e, vr + mu * mu - e * e)
}
fn sharpe_parts(ms: &[f64], vs: &[f64]) -> (f64, f64, f64) {
    let n = ms.len() as f64;
    let mean = ms.iter().fold(0.0, |a, x| a + x) / n;
    let s = (vs.iter().fold(0.0, |a, x| a + x) / n + ms.iter().fold(0.0, |a, x| a + (x - mean).powf(2.0)) / n).sqrt();
    (mean / s * 252f64.sqrt(), mean, s)
}
type Exact = Vec<([(f64, f64, f64); 3], Vec<f64>)>;
fn exact(c: f64, b: f64, se2: f64) -> (Exact, [(f64, f64, f64, f64, f64); 2]) {   // road 2
    let (r, dd, mut out) = ([regime(SE1, b), regime(se2, b)], deaths(), Vec::new());
    for &(lag, dead, cost) in FLAGS.iter() {
        let (mut ms, mut vs) = (Vec::new(), Vec::new());
        for t in 0..N {
            let (vr, ss, g2, g1, p) = r[(t >= N / 2) as usize]; let g = if lag == 1 { g1 } else { g2 };
            let (e0, v0) = bet(vr, ss, g, 0.0, 0.0);
            let (mut tot, mut var) = (e0 * M as f64, v0 * M as f64);
            if dead {
                for &d in &dd {
                    if d - L <= t && t < d {
                        let (ti, lg, ki, di) = (t as i64, lag as i64, K as i64, (d - L) as i64);
                        let j = 0.max(ti - lg - (ti - lg - ki + 1).max(di) + 1);   // declining days inside the signal
                        let (e, v) = bet(vr, ss, g, j as f64, MU); tot += e - e0; var += v - v0;
                    }
                }
            }
            ms.push(tot / M as f64 - if cost && t > 0 { 2.0 * p * c } else { 0.0 }); vs.push(var / M as f64 / M as f64);
        }
        let parts = [sharpe_parts(&ms, &vs), sharpe_parts(&ms[..N / 2], &vs[..N / 2]), sharpe_parts(&ms[N / 2..], &vs[N / 2..])];
        out.push((parts, ms));
    }
    (out, r)
}

struct Rng { x: u64, spare: Option<f64> }            // splitmix64 uniforms, Box-Muller bell-curve draws
impl Rng {
    fn u(&mut self) -> f64 {
        self.x = self.x.wrapping_add(0x9E3779B97F4A7C15); let mut z = self.x;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
    fn n(&mut self) -> f64 {
        if let Some(v) = self.spare.take() { return v; }
        let r = (-2.0 * (1.0 - self.u()).ln()).sqrt(); let a = 2.0 * PI * self.u();
        self.spare = Some(r * a.sin()); r * a.cos()
    }
}
fn path(g: &mut Rng, end: Option<usize>) -> Vec<f64> {   // one firm's log price: fundamental plus mispricing
    let (mut f, mut z) = (0.0, g.n() * SE1 / (1.0 - B * B).sqrt()); let mut p = vec![f + z];
    for i in 1..N + W {
        let t = i as i64 - W as i64;
        let mu = match end { Some(e) if e as i64 - L as i64 <= t && t < e as i64 => MU, _ => 0.0 };
        f += mu + SF * g.n();
        z = B * z + if t < (N / 2) as i64 { SE1 } else { SE2 } * g.n(); p.push(f + z);
    }
    p
}
fn history(seed: u64) -> (Vec<Vec<f64>>, f64) {       // road 1: run the five backtests on one history
    let (mut g, dd) = (Rng { x: seed, spare: None }, deaths());
    let surv: Vec<Vec<f64>> = (0..M).map(|_| path(&mut g, None)).collect();
    let doom: Vec<Vec<f64>> = dd.iter().map(|&d| path(&mut g, Some(d))).collect();
    let (mut out, mut pos_n, mut pos_h, mut turn) = (vec![Vec::new(); 5], vec![0.0; M], vec![0.0; M], 0.0);
    let sign = |a: f64, b: f64| if a > b { -1.0 } else { 1.0 };
    for t in 0..N {
        let (i, mut day, mut tn, mut th) = (t + W, [0.0f64; 3], 0.0, 0.0);
        for s in 0..M {
            let p = &surv[s]; let q = if s < FAIL && t < dd[s] { &doom[s] } else { p };
            let wl = sign(p[i - 1], p[i - 1 - K]);                       // decided at the close it fills at
            let wn = sign(p[i - 2], p[i - 2 - K]);                       // decided a day before the fill
            let wh = sign(q[i - 2], q[i - 2 - K]);
            day[0] += wl * (p[i] - p[i - 1]); day[1] += wn * (p[i] - p[i - 1]); day[2] += wh * (q[i] - q[i - 1]);
            tn += (wn - pos_n[s]).abs(); th += (wh - pos_h[s]).abs(); pos_n[s] = wn; pos_h[s] = wh;
        }
        let m = M as f64; let (cn, ch) = if t > 0 { (C * tn / m, C * th / m) } else { (0.0, 0.0) };
        turn += if t > 0 { tn / m } else { 0.0 };
        for (k, v) in [day[0] / m, day[1] / m, day[1] / m - cn, day[2] / m, day[2] / m - ch].iter().enumerate() { out[k].push(*v); }
    }
    (out, turn / (N - 1) as f64)
}
fn sim_sharpe(x: &[f64]) -> (f64, f64) {
    let n = x.len() as f64; let mean = x.iter().fold(0.0, |a, v| a + v) / n;
    (mean / (x.iter().fold(0.0, |a, v| a + (v - mean).powf(2.0)) / n).sqrt() * 252f64.sqrt(), mean)
}
fn main() {
    let (ex, r) = exact(C, B, SE2);
    let (mut pool, mut h1, mut h2, mut turns, mut one) = (vec![Vec::new(); 5], vec![Vec::new(); 5], vec![Vec::new(); 5], 0.0, Vec::new());
    for h in 0..H {
        let (runs, tv) = history(2026 + h as u64); turns += tv / H as f64;
        if h == 0 { one = runs.iter().map(|x| sim_sharpe(x).0).collect(); }
        for (k, x) in runs.iter().enumerate() { pool[k].extend_from_slice(x); h1[k].extend_from_slice(&x[..N / 2]); h2[k].extend_from_slice(&x[N / 2..]); }
    }
    let sim: Vec<[(f64, f64); 3]> = (0..5).map(|k| [sim_sharpe(&pool[k]), sim_sharpe(&h1[k]), sim_sharpe(&h2[k])]).collect();

    println!("model: {} slots, 10 years, {} failures falling {:.2}% a day for {} days, lookback {} days, cost {:.1} bp", M, FAIL, -MU * 100.0, L, K, C * BP);
    println!("model: fundamental {:.2}% a day, carry-over b {:.2}; {} histories = {} years; sqrt(2/pi) {:.3}, sqrt(252) {:.2}",
             SF * 100.0, B, H, 10 * H, (2.0 / PI).sqrt(), 252f64.sqrt());
    for (lab, &(vr, ss, g2, g1, p), sh) in [("years 1-5 ", &r[0], SE1), ("years 6-10", &r[1], SE2)] {
        let (e, e1) = (bet(vr, ss, g2, 0.0, 0.0).0, bet(vr, ss, g1, 0.0, 0.0).0);
        println!("{}: shock {:.2}%  v_z {:.3} %^2  sigma_S {:.2}%  gamma {:.3} %^2  look-ahead {:.3} %^2  p {:.4}",
                 lab, sh * 100.0, sh * sh / (1.0 - B * B) * BP, ss * 100.0, g2 * BP, g1 * BP, p);
        println!("{}: edge e {:.2} bp  look-ahead {:.2} bp  one bet {:.2}%  s {:.1} bp", lab, e * BP, e1 * BP, vr.sqrt() * 100.0, ((vr - e * e) / M as f64).sqrt() * BP);
    }
    let (turn_exact, fac) = (r[0].4 + r[1].4, 252f64.sqrt() / (ex[4].0[0].2 * BP));   // fac: Sharpe per bp a day
    println!("turnover per day: exact {:.4}, simulated {:.4}; cost per day {:.3} bp = {:.3} Sharpe", turn_exact, turns, turn_exact * C * BP, turn_exact * C * BP * fac);
    let (vr, ss, g2, mf) = (r[0].0, r[0].1, r[0].2, K as f64 * MU / r[0].1);
    println!("failing firm, fully in decline (years 1-5): signal mean {:.1}% = {:.3} spreads, N {:.4}, long {:.4}",
             K as f64 * MU * 100.0, mf, ncdf(mf), 1.0 - ncdf(mf));
    println!("failing firm: drift part {:.2} bp, edge part {:.2} bp, total {:.2} bp",
             -MU * (2.0 * ncdf(mf) - 1.0) * BP, -g2 / ss * 2.0 * pdf(mf) * BP, bet(vr, ss, g2, K as f64, MU).0 * BP);
    let sum = |v: &Vec<f64>| v.iter().fold(0.0, |a, x| a + x);
    let (gain_x, gain_s) = ((sum(&ex[1].1) - sum(&ex[3].1)) / N as f64 * BP, (sim[1][0].1 - sim[3][0].1) * BP);
    println!("survivor gain per day: exact {:.3} bp = {:.3} Sharpe, simulated {:.3} bp", gain_x, gain_x * fac, gain_s);
    println!("Sharpe ratio           exact: 10y  yrs1-5 yrs6-10 | simulated 400y: 10y  yrs1-5 yrs6-10");
    for k in 0..5 {
        let a = &ex[k].0; println!("{:<21} {:9.3} {:7.3} {:7.3} | {:12.3} {:7.3} {:7.3}", NAMES[k], a[0].0, a[1].0, a[2].0, sim[k][0].0, sim[k][1].0, sim[k][2].0);
    }
    for k in [1usize, 4] {
        let (_sr, mean, s) = ex[k].0[0]; println!("{:<21} 10y daily mean {:.3} bp, spread s {:.3} bp, 1 bp a day = {:.3} Sharpe", NAMES[k], mean * BP, s * BP, 252f64.sqrt() / (s * BP));
    }
    println!("one 10-year history:   {}; one decade's standard error: {}", one.iter().map(|v| format!("{:.2}", v)).collect::<Vec<_>>().join("  "),
             [ex[1].0[0].0, ex[4].0[0].0].iter().map(|x| format!("{:.3}", ((1.0 + x * x / 2.0) / 10.0).sqrt())).collect::<Vec<_>>().join(", "));
    let hon = ex[4].0[0].0;
    println!("wrong: 365 days a year {:.3}; wrong: times 252, not its root {:.3}; wrong: years 1-5 only {:.3}",
             hon * (365.0f64 / 252.0).sqrt(), hon * 252f64.sqrt(), ex[4].0[1].0);
    let tries = [("cost 2.5 bp", exact(0.00025, B, SE2)), ("cost 10 bp", exact(0.001, B, SE2)),
                 ("carry-over b 0.8", exact(C, 0.8, SE2)), ("no regime change", exact(C, B, SE1))];
    println!("try, honest 10y: {}", tries.iter().map(|(lab, o)| format!("{} {:.3}", lab, o.0[4].0[0].0)).collect::<Vec<_>>().join("; "));
    println!("chart, {:<20}{}", "year", (0..11).map(|y| format!("{:6}", y)).collect::<Vec<_>>().join(" "));
    for k in [0usize, 1, 4] {                                          // expected return added up, year by year
        let row: Vec<String> = (0..11).map(|y| format!("{:6.2}", ex[k].1[..252 * y].iter().fold(0.0, |a, x| a + x) * 100.0)).collect();
        println!("chart, {:<20}{}", NAMES[k], row.join(" ")); }

    let se = |sr: f64| 3.0 * ((1.0 + sr * sr / 2.0) / (10 * H) as f64).sqrt();   // three standard errors, 400 years
    for k in [0usize, 1, 4] { assert!((sim[k][0].0 - ex[k].0[0].0).abs() < se(ex[k].0[0].0), "{}", NAMES[k]); }
    assert!((turns - turn_exact).abs() < 0.01 * turn_exact, "flip chance from arccos vs counted flips");
    assert!((gain_s - gain_x).abs() < 0.05 * gain_x, "survivor gain, simulated vs exact");
    println!("ALL CHECKS PASS");
}
