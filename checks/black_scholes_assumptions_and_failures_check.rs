// The Black-Scholes assumptions -- the same check as the Python, in Rust.  No crates, std
// only, and nothing that already knows an answer: the bell-curve area is the same series,
// the daily moves come from the same generator, the American put is the same tree.  Acme
// is the house market: S = K = 100, r = 5%, q = 2%, sigma = 20%, one year; one call is
// sold at the model premium and hedged 252 times, on 200 records, in three worlds.
use std::f64::consts::PI;
const S0: f64 = 100.0; const STRIKE: f64 = 100.0; const RATE: f64 = 0.05;
const Q: f64 = 0.02; const SIG: f64 = 0.20; const T: f64 = 1.0; const N: usize = 252;
const MU: f64 = 0.08; const COST: f64 = 0.001; const H: f64 = 1.0 / 252.0;   // drift, 10bp, a day
const RECS: usize = 200;                          // records of 252 daily moves
const KINDS: [&str; 3] = ["matched", "gap", "switch"];
fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }   // bell-curve height
fn ncdf(x: f64) -> f64 {                          // the area to the LEFT of x
    let a = x.abs();
    if a > 8.0 { return if x > 0.0 { 1.0 } else { 0.0 }; }  // the tail here is under 1e-15
    let (mut term, mut tot, mut k) = (a, a, 1.0);           // a series, all terms positive
    while term > 1e-19 * tot { term *= a * a / (2.0 * k + 1.0); tot += term; k += 1.0; }
    let p = 0.5 + phi(a) * tot;
    if x > 0.0 { p } else { 1.0 - p }
}
fn bs(s: f64, k: f64, r: f64, q: f64, sg: f64, t: f64) -> (f64, f64) {
    if t <= 0.0 { return ((s - k).max(0.0), if s > k { 1.0 } else { 0.0 }); }
    let (a, drag) = (sg * t.sqrt(), (-q * t).exp());        // value, and its share count
    let d1 = ((s / k).ln() + (r - q + 0.5 * sg * sg) * t) / a;
    (s * drag * ncdf(d1) - k * (-r * t).exp() * ncdf(d1 - a), drag * ncdf(d1))
}
fn mark(t: f64, s: f64) -> (f64, f64) { bs(s, STRIKE, RATE, Q, SIG, T - t) }  // always 20%
fn normals(seed: u64, m: usize) -> Vec<f64> {     // own generator, then Box-Muller
    let (mut out, mut st) = (Vec::new(), seed);
    while out.len() < m {
        let mut u = [0.0f64; 2];
        for slot in u.iter_mut() {
            st = (1664525 * st + 1013904223) % 4294967296;
            *slot = (st as f64 + 0.5) / 4294967296.0;
        }
        let (rad, ang) = ((-2.0 * u[0].ln()).sqrt(), 2.0 * PI * u[1]);
        out.push(rad * ang.cos()); out.push(rad * ang.sin());
    }
    out.truncate(m); out
}
struct Run { s: f64, wealth: f64, pay: f64, left: f64, carried: f64, bill: f64,
             jump: [f64; 4], month: Vec<f64> }
fn account(kind: &str, z: &[f64]) -> Run {
    // Hedge the sold call once a day, then settle it: what is left over?
    let (grow, paid) = ((RATE * H).exp(), (Q * H).exp() - 1.0);
    let (mut s, mut jump, mut month) = (S0, [0.0; 4], vec![0.0]);
    let (mut v, mut d) = mark(0.0, s);
    let (mut wealth, mut carried, mut bill, mut cash) = (v, 0.0, COST * d.abs() * s, v - d * s);
    for (i, zi) in z.iter().enumerate() {
        let vol = if kind == "switch" && i >= N / 2 { 0.30 } else { SIG };   // realised vol
        let (t, bank) = ((i + 1) as f64 * H, (RATE * (i + 1) as f64 * H).exp());
        let mut nxt = s * ((MU - 0.5 * vol * vol) * H + vol * H.sqrt() * zi).exp();
        let income = d * s * paid;                                 // the day's dividend
        let (mut vn, mut dn) = mark(t, nxt);
        carried = grow * carried + d * (nxt - s) + income
            + (grow - 1.0) * (v - d * s) - (vn - v);               // road 2: the defects
        wealth = d * nxt + cash * grow + income;                   // road 1: the account
        if kind == "gap" && i + 1 == N / 2 {                       // a 10% overnight gap
            let (after, j) = (0.9 * nxt, -0.1 * nxt);
            let (va, da) = mark(t, after);
            jump = [j, (d - dn) * j, va - vn - dn * j, d * j - (va - vn)];
            wealth += d * j; carried += jump[3];
            nxt = after; vn = va; dn = da;
        }
        bill += COST * (dn - d).abs() * nxt / bank;                // the trading bill
        s = nxt; v = vn; d = dn;
        cash = wealth - d * s;
        if (i + 1) % 21 == 0 { month.push(wealth - v); }
    }
    let pay = (s - STRIKE).max(0.0);              // the call is settled at expiry
    Run { s, wealth, pay, left: wealth - pay, carried, bill, jump, month }
}
fn tree_put(steps: usize, american: bool) -> f64 {   // a CRR tree: an independent road
    let (dt, u) = (T / steps as f64, (SIG * (T / steps as f64).sqrt()).exp());
    let (p, disc) = ((((RATE - Q) * dt).exp() - 1.0 / u) / (u - 1.0 / u), (-RATE * dt).exp());
    let mut v: Vec<f64> = (0..=steps).map(|j| (STRIKE - S0 * u.powi(2 * j as i32 - steps as i32)).max(0.0)).collect();
    for st in (1..=steps).rev() {
        v = (0..st).map(|j| disc * (p * v[j + 1] + (1.0 - p) * v[j])).collect();
        if american {
            v = (0..st).map(|j| v[j].max(STRIKE - S0 * u.powi(2 * j as i32 - st as i32 + 1))).collect();
        }
    }
    v[0]
}
fn stats(x: &[f64]) -> (f64, f64, f64, f64) {     // mean, spread, worst, best
    let m = x.iter().sum::<f64>() / x.len() as f64;
    let sq = x.iter().map(|a| (a - m) * (a - m)).sum::<f64>() / (x.len() - 1) as f64;
    (m, sq.sqrt(), x.iter().copied().fold(f64::INFINITY, f64::min), x.iter().copied().fold(f64::NEG_INFINITY, f64::max))
}
fn main() {
    let (c0, d0) = bs(S0, STRIKE, RATE, Q, SIG, T);
    let p0 = c0 - S0 * (-Q * T).exp() + STRIKE * (-RATE * T).exp();    // the put, by parity
    let d1 = ((S0 / STRIKE).ln() + (RATE - Q + 0.5 * SIG * SIG) * T) / (SIG * T.sqrt());
    let gamma = (-Q * T).exp() * phi(d1) / (S0 * SIG * T.sqrt());
    let vega = S0 * (-Q * T).exp() * phi(d1);
    let stream = normals(20260919, N * RECS);
    let runs: Vec<Vec<Run>> = KINDS.iter()
        .map(|k| (0..RECS).map(|i| account(k, &stream[N * i..N * (i + 1)])).collect()).collect();
    let res: Vec<(f64, f64, f64, f64)> = (0..3)
        .map(|c| stats(&runs[c].iter().map(|a| a.left).collect::<Vec<f64>>())).collect();
    let traced = (0..RECS).find(|&i| (runs[0][i].s - STRIKE).abs() <= 5.0).unwrap();
    let be = (PI / (4.0 * N as f64)).sqrt() * vega * SIG;      // Boyle-Emanuel, closed form
    let bill = stats(&runs[0].iter().map(|a| a.bill).collect::<Vec<f64>>());
    let lel = SIG * (1.0 + (2.0 / PI).sqrt() * 2.0 * COST / (SIG * H.sqrt())).sqrt();
    let leland = bs(S0, STRIKE, RATE, Q, lel, T).0 - c0;
    let rms = (0.5 * SIG * SIG + 0.5 * 0.09f64).sqrt();   // the switch world's whole year
    let rms_c = bs(S0, STRIKE, RATE, Q, rms, T).0;
    let stale = stats(&runs[1].iter().map(|a| a.jump[1]).collect::<Vec<f64>>());
    let bend = stats(&runs[1].iter().map(|a| a.jump[2]).collect::<Vec<f64>>());
    let sd_day = (0.9f64.ln() - (MU - 0.5 * SIG * SIG) * H) / (SIG * H.sqrt());
    let p_day = phi(sd_day) / -sd_day * (1.0 - 1.0 / (sd_day * sd_day) + 3.0 / sd_day.powi(4));
    let borrow = bs(S0, STRIKE, 0.07, Q, SIG, T).0;
    let lend = bs(S0, STRIKE, 0.03, Q, SIG, T).0;
    let (eu, am) = (tree_put(1200, false), tree_put(1200, true));
    println!("Acme house market: S = K = 100, r = 5%, q = 2%, sigma = 20%, T = 1 year; {} \
daily hedges, {} records, real drift 8% a year", N, RECS);
    println!("  call C {:.6}  put by parity P {:.6}  delta {:.6}  gamma {:.6}  vega {:.6}", c0, p0, d0, gamma, vega);
    println!("leftover after settling, over {} records:", RECS);
    for c in 0..3 {
        println!("  {:<8} mean {:>10.6}  spread {:>9.6}  worst {:>10.6}  best {:>10.6}",
                 KINDS[c], res[c].0, res[c].1, res[c].2, res[c].3);
    }
    println!("record {} is the first to finish within $5 of the strike:", traced);
    for c in 0..3 {
        let a = &runs[c][traced];
        println!("  {:<8} stock {:>10.6}  account {:>10.6}  call pays {:>9.6}  leftover \
{:>10.6}  carried defects {:>10.6}",
                 KINDS[c], a.s, a.wealth, a.pay, a.left, a.carried);
    }
    let j = runs[1][traced].jump;
    println!("  its gap: stock moved {:.6}, stale-delta term {:.6}, bend's bill {:.6}, together {:.6}", j[0], j[1], j[2], j[3]);
    println!("what one broken assumption costs, on the same option:");
    println!("  1 vol switched to 30%: the whole year's volatility {:.6}, the right premium {:.6}, dearer than 9.227006 by {:.6}",
             rms, rms_c, rms_c - c0);
    println!("  2 the 10% gap: bend's bill, mean {:.6}, largest {:.6}; stale-delta term, mean {:.6}",
             bend.0, bend.3, stale.0);
    println!("  3 daily, not continuous: Boyle-Emanuel spread {:.6}; at 10bp a trade the \
bill is {:.6}, less the opening purchase {:.6}, against Leland's {:.6}",
             be, bill.0, bill.0 - COST * d0 * S0, leland);
    println!("  4 two rates: borrowing at 7% {:.6}, lending at 3% {:.6}, band {:.6} wide", borrow, lend, borrow - lend);
    println!("  5 lognormal moves: a 10% down day is {:.6} standard deviations, chance 10^{:.3}, one such day per 10^{:.3} years",
             -sd_day, p_day.log10(), -(p_day * N as f64).log10());
    println!("  6 European exercise: the put on a 1200-step tree {:.6}, the American {:.6}, early exercise worth {:.6}",
             eu, am, am - eu);
    println!("bars, dollars on a $9.23 option: vol switch {:.2}, gap {:.2}, daily not \
continuous {:.2}, trading at 10bp {:.2}, funding band {:.2}, early exercise {:.2}",
             -res[2].0, -res[1].0, be, bill.0, borrow - lend, am - eu);
    let mut line = format!("{:<26}", "chart, months gone");
    for i in 0..13 { line.push_str(&format!("{:>7}", i)); }
    println!("{}", line);
    for c in 0..3 {
        let mut line = format!("{:<26}", format!("chart, {}", KINDS[c]));
        for v in &runs[c][traced].month { line.push_str(&format!("{:>7.2}", v)); }
        println!("{}", line);
    }
    assert!((c0 - 9.227005508154).abs() < 1e-9, "the call against the house number");
    assert!((d0 - 0.5 * (mark(0.0, 101.0).0 - mark(0.0, 99.0).0)).abs() < 1e-3, "delta by a bump");
    assert!((eu - p0).abs() < 0.01, "the tree must reproduce the put, 6.330081");
    assert!(am > eu + 0.05, "early exercise must be worth something");
    assert!(runs.iter().flatten().all(|a| (a.left - a.carried).abs() < 1e-7), "account vs defects");
    assert!(bend.2 > 0.0, "a gap costs the hedger whichever way it goes");
    assert!(runs[1].iter().all(|a| (a.jump[3] - a.jump[1] + a.jump[2]).abs() < 1e-9), "each gap splits");
    assert!((res[0].1 / be - 1.0).abs() < 0.15, "the spread against Boyle-Emanuel");
    assert!(res[0].0.abs() < 4.0 * res[0].1 / (RECS as f64).sqrt(), "daily is unbiased");
    assert!((-res[2].0 / (rms_c - c0) - 1.0).abs() < 0.10, "the loss against the price gap");
    assert!(((bill.0 - COST * d0 * S0) / leland - 1.0).abs() < 0.15, "the bill against Leland");
    println!("ALL CHECKS PASS");
}
