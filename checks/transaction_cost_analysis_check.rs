// Transaction cost analysis -- the same check as transaction_cost_analysis_check.py, in Rust.
// Standard library only, no crates.  Same order, same six fills, same five roads,
// same hand-written random generator, same printed rows.
// Compile: rustc --edition 2021 -O transaction_cost_analysis_check.rs -o /tmp/tca_check
use std::f64::consts::PI;

const SIDE: f64 = -1.0; // -1 = sell, +1 = buy
const Q: f64 = 100_000.0;
const P_D: f64 = 100.00; // decision price, Monday's close
const P_A: f64 = 99.96; // arrival price, Tuesday's open
const FILLS: [(f64, f64); 6] = [(10_000.0, 99.93), (15_000.0, 99.92), (20_000.0, 99.89),
                                (20_000.0, 99.86), (20_000.0, 99.85), (15_000.0, 99.86)];
const TAPE: [(f64, f64); 6] = [(200_000.0, 99.97), (120_000.0, 99.96), (100_000.0, 99.93),
                               (90_000.0, 99.90), (110_000.0, 99.90), (280_000.0, 99.91)];
const HOURS: [f64; 6] = [0.5, 1.5, 2.5, 3.5, 4.5, 5.75]; // middle of each bucket
const DAY: f64 = 6.5;

fn average(trades: &[(f64, f64)]) -> f64 {
    let mut cash = 0.0;
    let mut size = 0.0;
    for &(q, p) in trades { cash += q * p; size += q; }
    cash / size
}
fn cost_bp(bench: f64, pbar: f64) -> f64 { 1e4 * SIDE * (pbar - bench) / P_D }

struct Rng(u64);
impl Rng {
    fn uniform(&mut self) -> f64 { // splitmix64, written out; a number in (0, 1]
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0 + 1.0 / 9007199254740992.0
    }
    fn normal(&mut self) -> f64 { // Box-Muller, one draw per pair
        let u1 = self.uniform();
        let u2 = self.uniform();
        (-2.0 * u1.ln()).sqrt() * (2.0 * PI * u2).cos()
    }
}

fn main() {
    // road 1: formula on the average fill price
    let pbar = average(&FILLS);
    let p_v = average(&TAPE);
    let (is, arrival, vwap) = (cost_bp(P_D, pbar), cost_bp(P_A, pbar), cost_bp(p_v, pbar));
    // road 2: cash ledger in whole cents, fill by fill
    let paper = 100_000i64 * (P_D * 100.0).round() as i64;
    let actual: i64 = FILLS.iter().map(|&(q, p)| q as i64 * (p * 100.0).round() as i64).sum();
    let is_ledger = 1e4 * SIDE * (actual - paper) as f64 / paper as f64;
    // road 3: timing leg + impact leg, each from its own prices
    let timing = 1e4 * SIDE * (P_A - P_D) / P_D;
    let mut imp = 0.0;
    for &(q, p) in FILLS.iter() { imp += 1e4 * SIDE * q * (p - P_A); }
    let impact = imp / (Q * P_D);
    let drift = 1e4 * SIDE * (p_v - P_A) / P_D;
    // road 4: VWAP by a running update
    let (mut run_v, mut run_vol) = (0.0f64, 0.0f64);
    for &(v, m) in TAPE.iter() { run_vol += v; run_v += v / run_vol * (m - run_v); }
    // inside the VWAP cost: each hour's fill vs that hour, and the schedule
    let mut os = 0.0;
    for k in 0..6 { os += FILLS[k].0 * TAPE[k].1; }
    let own_sched = os / Q;
    let (slices, schedule) = (cost_bp(own_sched, pbar), 1e4 * SIDE * (own_sched - p_v) / P_D);
    let vol: f64 = TAPE.iter().map(|x| x.0).sum(); // hour by hour, no averages used:
    let (mut slices_hr, mut sched_w) = (0.0, 0.0);
    for k in 0..6 {
        slices_hr += 1e4 * SIDE * FILLS[k].0 * (FILLS[k].1 - TAPE[k].1) / (Q * P_D);
        sched_w += 1e4 * SIDE * (FILLS[k].0 / Q - TAPE[k].0 / vol) * TAPE[k].1 / P_D;
    }
    // what breaks
    let unweighted = cost_bp(P_D, FILLS.iter().map(|x| x.1).sum::<f64>() / 6.0);
    let both: Vec<(f64, f64)> = TAPE.iter().chain(FILLS.iter()).cloned().collect();
    let with_own = cost_bp(average(&both), pbar);
    let only_us = cost_bp(average(&FILLS), pbar) + 0.0;
    let done = &FILLS[..5];
    let unfilled = Q - done.iter().map(|x| x.0).sum::<f64>();
    let p_close = 99.80;
    let filled_only = cost_bp(P_D, average(done));
    let mut opp = 0.0;
    for &(q, p) in done { opp += 1e4 * SIDE * q * (p - P_D); }
    let with_opp = (opp + 1e4 * SIDE * unfilled * (p_close - P_D)) / (Q * P_D);
    let fee_2000 = is + 1e4 * 2000.0 / (Q * P_D);
    let tape_vol: f64 = TAPE.iter().map(|x| x.0).sum();

    let rows: [(&str, f64); 32] = [("decision price", P_D), ("arrival price", P_A),
        ("closing price, partial case", p_close), ("paper proceeds ($)", paper as f64 / 100.0),
        ("cash raised ($)", actual as f64 / 100.0), ("average fill price", pbar), ("market VWAP, others only", p_v),
        ("  VWAP, running update", run_v), ("1 shortfall, formula (bp)", is),
        ("2 shortfall, cents ledger (bp)", is_ledger), ("3 timing leg (bp)", timing),
        ("3 impact leg (bp)", impact), ("  timing + impact (bp)", timing + impact),
        ("arrival cost, formula (bp)", arrival), ("VWAP cost (bp)", vwap),
        ("  arrival -> VWAP drift (bp)", drift), ("  own-schedule market price", own_sched),
        ("  slices vs their hour (bp)", slices), ("  schedule vs volume curve (bp)", schedule),
        ("shortfall ($)", is * Q * P_D / 1e4), ("timing ($)", timing * Q * P_D / 1e4),
        ("impact ($)", impact * Q * P_D / 1e4), ("VWAP cost ($)", vwap * Q * P_D / 1e4),
        ("share of day's volume", Q / (Q + tape_vol)), ("wrong: scored as a buy (bp)", -is),
        ("wrong: unweighted fill average (bp)", unweighted), ("wrong: VWAP with our own fills (bp)", with_own),
        ("wrong: we are the whole tape (bp)", only_us), ("partial: filled shares only (bp)", filled_only),
        ("partial: with missed shares (bp)", with_opp),
        ("partial: missed shares' loss ($)", unfilled * (P_D - p_close)), ("try: $2,000 commission (bp)", fee_2000)];
    for (name, v) in rows.iter() { println!("{:<38}{:>12.4}", name, v); }

    // road 5: how noisy is one order's arrival cost?
    let sigma_day = P_D * 0.20 / 252.0f64.sqrt();
    let impact_c = 0.08;
    let t: Vec<f64> = HOURS.iter().map(|h| h / DAY).collect();
    let w: Vec<f64> = FILLS.iter().map(|x| x.0 / Q).collect();
    let mut dsum = 0.0;
    for j in 0..6 { for k in 0..6 { dsum += w[j] * w[k] * t[j].min(t[k]); } }
    let sd_exact = 1e4 * (sigma_day.powi(2) * dsum).sqrt() / P_D;

    let mut rng = Rng(20260928);
    let n_sim = 20_000usize;
    let edges = [-150.0, -100.0, -50.0, 0.0, 50.0, 100.0, 150.0];
    let mut costs = Vec::with_capacity(n_sim);
    let mut bins = [0usize; 8];
    for _ in 0..n_sim {
        let (mut mid, mut prev, mut pb) = (P_A, 0.0, 0.0);
        for k in 0..6 {
            mid += sigma_day * (t[k] - prev).sqrt() * rng.normal();
            prev = t[k];
            pb += w[k] * (mid - impact_c);
        }
        let c = cost_bp(P_A, pb);
        costs.push(c);
        bins[edges.iter().filter(|&&e| c >= e).count()] += 1;
    }
    let mut total = 0.0;
    for c in &costs { total += *c; }
    let mean = total / n_sim as f64;
    let mut ss = 0.0;
    for c in &costs { ss += (c - mean).powi(2); }
    let sd = (ss / (n_sim - 1) as f64).sqrt();
    let gains = costs.iter().filter(|&&c| c < 0.0).count() as f64 / n_sim as f64;
    println!();
    let sim_rows = [("sim: one day's wander ($)", sigma_day), ("sim: true impact (bp)", 1e4 * impact_c / P_D), ("sim: mean arrival cost (bp)", mean),
        ("sim: standard error of mean (bp)", sd / (n_sim as f64).sqrt()), ("sd, exact (bp)", sd_exact),
        ("sd, simulated (bp)", sd), ("sim: share looking like a gain", gains),
        ("orders to see 8 bp at 2 sd", (2.0 * sd_exact / 8.0).powi(2))];
    for (name, v) in sim_rows.iter() { println!("{:<38}{:>12.4}", name, v); }
    let labels = ["below -150", "-150 to -100", "-100 to -50", "-50 to 0", "0 to 50", "50 to 100",
                  "100 to 150", "150 and up"];
    for (lab, n) in labels.iter().zip(bins.iter()) { println!("histogram {:<14}{:>8}", lab, n); }
    let fmt = |v: Vec<String>| v.join(" ");
    println!("chart, others' hourly price  {}", fmt(TAPE.iter().map(|x| format!("{:.2}", x.1)).collect()));
    println!("chart, our hourly fill       {}", fmt(FILLS.iter().map(|x| format!("{:.2}", x.1)).collect()));

    assert!((is - is_ledger).abs() < 1e-9, "formula road vs cents ledger");
    assert!((timing + impact - is).abs() < 1e-9, "legs built from their own prices must rebuild the shortfall");
    assert!((run_v - p_v).abs() < 1e-9, "running VWAP vs direct VWAP");
    assert!((slices - slices_hr).abs() < 1e-9, "fills vs their hour: average road vs hour-by-hour road");
    assert!((schedule - sched_w).abs() < 1e-9, "schedule: average road vs volume-weight road");
    assert!((slices_hr + sched_w - vwap).abs() < 1e-9, "hour-by-hour split vs the VWAP cost");
    let r9 = |x: f64| (x * 1e9).round() / 1e9;
    assert!([r9(is), r9(timing), r9(impact), r9(vwap)] == [12.0, 4.0, 8.0, 5.0], "the card's 12 = 4 + 8 and 5");
    assert!((mean - 8.0).abs() < 4.0 * sd / (n_sim as f64).sqrt(), "simulated mean vs the 8 bp built in");
    assert!((sd / sd_exact - 1.0).abs() < 0.03, "simulated noise vs exact variance");
    println!("ALL CHECKS PASS");
}
