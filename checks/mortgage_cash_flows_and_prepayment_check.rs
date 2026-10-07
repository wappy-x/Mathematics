// Mortgage pool cash flows under prepayment -- the same check as the Python, in Rust.
// Std only, no crates.  A $1,000,000 pool of identical 30-year loans at 6
// percent, paid monthly.  Three roads to the pool's balance: the month-by-month
// ledger, the closed form (survivors times one loan's schedule), and 20,000
// simulated loans driven by a random-number generator written here.
const L: f64 = 1_000_000.0;
const N: usize = 360;
const I: f64 = 0.06 / 12.0;

type Row = (f64, f64, f64, f64); // interest, scheduled, prepaid, end balance

fn smm(c: f64) -> f64 { 1.0 - ((1.0 - c).ln() / 12.0).exp() } // annual CPR -> monthly s

fn annuity(n: usize) -> f64 { // a_n(i), added up one discount factor at a time
    let (mut v, mut total) = (1.0, 0.0);
    for _ in 0..n { v /= 1.0 + I; total += v; }
    total
}

fn level() -> f64 { L / annuity(N) } // the level payment with no prepayment

fn ledger(cpr: &dyn Fn(usize) -> f64, frozen: bool) -> Vec<Row> { // road 1
    let (a, mut b, mut rows) = (level(), L, Vec::new());
    for m in 1..=N {
        let interest = I * b;
        let pay = (if frozen { a } else { b / annuity(N - m + 1) }).min(b + interest);
        let sched = pay - interest;
        let prepaid = smm(cpr(m)) * (b - sched);
        b = b - sched - prepaid;
        rows.push((interest, sched, prepaid, b));
        if b < 1e-6 { break; }
    }
    rows
}

fn wal(rows: &[Row]) -> f64 { // weighted average life, in years
    rows.iter().enumerate().map(|(m, r)| (m + 1) as f64 / 12.0 * (r.1 + r.2)).sum::<f64>() / L
}

fn value(rows: &[Row], y: f64) -> f64 { // today's value of the cash flows at yearly rate y
    rows.iter().enumerate().map(|(m, r)| (r.0 + r.1 + r.2) / (1.0 + y / 12.0).powf((m + 1) as f64)).sum()
}

fn closed(m: usize, c: f64) -> f64 { // road 2: L (1-s)^m a_{N-m} / a_N
    let v = 1.0 / (1.0 + I);
    L * (1.0 - smm(c)).powf(m as f64) * (1.0 - v.powf((N - m) as f64)) / (1.0 - v.powf(N as f64))
}

fn closed_path(m: usize, cpr: &dyn Fn(usize) -> f64) -> f64 { // road 2, changing speed
    let v = 1.0 / (1.0 + I);
    let surv: f64 = (1..=m).map(|k| 1.0 - smm(cpr(k))).product();
    L * surv * (1.0 - v.powf((N - m) as f64)) / (1.0 - v.powf(N as f64))
}

fn simulate(c: f64, loans: usize, seed: u64) -> (Vec<f64>, f64) { // road 3: whole loans
    let (mut state, mut us) = (seed, Vec::with_capacity(loans));
    for _ in 0..loans { // splitmix64, written out
        state = state.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = (state ^ (state >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        us.push(((z ^ (z >> 31)) >> 11) as f64 / 2f64.powi(53));
    }
    us.sort_by(|a, b| a.partial_cmp(b).unwrap());
    let (a, mut one, mut surv, mut p) = (level(), 1.0, 1.0, loans);
    let (mut alive, mut bal) = (vec![loans], vec![1.0]);
    for _ in 1..=N { // one loan's own schedule, per dollar lent
        one = one * (1.0 + I) - a / L;
        surv *= 1.0 - smm(c); // a loan is still in if its draw is below surv
        while p > 0 && us[p - 1] >= surv { p -= 1; }
        alive.push(p);
        bal.push(f64::max(one, 0.0));
    }
    let bb: Vec<f64> = (0..=N).map(|m| L * alive[m] as f64 / loans as f64 * bal[m]).collect();
    let w = (1..=N).map(|m| m as f64 / 12.0 * (bb[m - 1] - bb[m])).sum::<f64>() / L;
    (bb, w)
}

fn pct(c: f64) -> String { format!("{:.0}%", c * 100.0) }

fn rule(mk: f64) -> f64 { (0.08 + 4.0 * (0.06 - mk)).max(0.02).min(0.30) } // rate-dependent CPR

fn main() {
    let a = level();
    let cs = [0.0, 0.04, 0.08, 0.12, 0.20];
    let runs: Vec<Vec<Row>> = cs.iter().map(|&c| ledger(&move |_| c, false)).collect();
    let (r8, s8) = (&runs[2], smm(0.08));
    let (sim_b, sim_wal) = simulate(0.08, 20000, 2026);

    println!("pool {:.2}, {} months at 0.5% a month; level payment A {:.6}", L, N, a);
    println!("8% CPR -> SMM s {:.12}; (1-s)^12 {:.12}; CPR/12 {:.12}", s8, (1.0 - s8).powf(12.0), 0.08 / 12.0);
    println!("a_N(i) {:.6}; survivors after 10 years (1-s)^120 {:.6}", annuity(N), (1.0 - s8).powf(120.0));
    let (it, sc, pp, b1) = r8[0];
    println!("month 1 at 8% CPR: interest {:.6} scheduled {:.6} prepaid {:.6}", it, sc, pp);
    println!("month 1 at 8% CPR: cash to investors {:.6} balance left {:.6}", it + sc + pp, b1);
    println!("month 2 scheduled payment {:.6}; (1-s) A {:.6}", r8[1].0 + r8[1].1, (1.0 - s8) * a);
    for yr in [10usize, 20] {
        let m = 12 * yr;
        println!("balance year {}, 8% CPR: ledger {:.6} closed {:.6} 20000 loans {:.6}",
                 yr, r8[m - 1].3, closed(m, 0.08), sim_b[m]);
    }
    println!("WAL 8% CPR: ledger {:.6} years; 20000 loans {:.6} years", wal(r8), sim_wal);
    let returned: f64 = r8.iter().map(|r| r.1 + r.2).sum();
    println!("principal returned at 8% CPR: {:.6}", returned);
    let int0: f64 = runs[0].iter().map(|r| r.0).sum();
    println!("interest paid: 0% CPR {:.6}; 8% CPR {:.6}", int0, r8.iter().map(|r| r.0).sum::<f64>());
    for k in [0usize, 2, 3] {
        println!("value at the 6% coupon rate, CPR {}: {:.6}", pct(cs[k]), value(&runs[k], 0.06));
    }
    let bars: Vec<String> = cs.iter().zip(&runs).map(|(c, r)| format!("{} {:.2}", pct(*c), wal(r))).collect();
    println!("WAL by CPR, years: {}", bars.join("  "));
    let psa = ledger(&|m: usize| 0.06 * (m.min(30) as f64) / 30.0, false);
    println!("try: 100% PSA ramp, WAL {:.2} years", wal(&psa));
    println!("rate-dependent CPR: market rate, CPR, WAL, value with rule, value if CPR stayed 8%");
    for mk in [0.05, 0.06, 0.07] {
        let c = rule(mk);
        let rr = ledger(&move |_| c, false);
        println!("  market {}  CPR {:>3}  WAL {:5.2}  {:11.2}  {:11.2}", pct(mk), pct(c), wal(&rr), value(&rr, mk), value(r8, mk));
    }
    let path = |m: usize| rule(if m <= 120 { 0.07 } else { 0.04 }); // market 7%, then 4% from month 121
    let rp = ledger(&path, false);
    println!("rate path 7% then 4%: CPR {} then {}; balance year 10 {:.2} closed {:.2}; year 20 {:.2}; WAL {:.2}",
             pct(path(1)), pct(path(121)), rp[119].3, closed_path(120, &path), rp[239].3, wal(&rp));
    let cpr12 = ledger(&|_| 1.0 - (1.0 - 0.08 / 12.0f64).powf(12.0), false); // mistake 1: s = CPR/12
    let frozen = ledger(&|_| 0.08, true); // mistake 2: payment never shrinks
    let mut b = L; // mistake 3: s on opening balance
    for m in 1..=120 { b = b - (b / annuity(N - m + 1) - I * b) - s8 * b; }
    println!("wrong: s = CPR/12, balance year 10 {:.2}, WAL {:.2}", cpr12[119].3, wal(&cpr12));
    println!("wrong: payment frozen at A, paid off in month {}, WAL {:.2}", frozen.len(), wal(&frozen));
    println!("wrong: s on opening balance, balance year 10 {:.2}", b);
    let ys: Vec<String> = (0..=30).step_by(5).map(|y| format!("{:>10}", y)).collect();
    println!("chart, years                 {}", ys.join(" "));
    for k in [0usize, 2, 3] {
        let mut bs = vec![L];
        for y in (5..=30).step_by(5) { bs.push(runs[k][12 * y - 1].3); }
        let t: Vec<String> = bs.iter().map(|x| format!("{:10.2}", x.abs())).collect();
        println!("chart, balance {:>4} CPR       {}", pct(cs[k]), t.join(" "));
    }
    let years = [1usize, 5, 10, 15, 20, 25, 30];
    let yl: Vec<String> = years.iter().map(|y| format!("{:>10}", y)).collect();
    println!("chart, year of life          {}", yl.join(" "));
    for (k, name) in [(0usize, "interest"), (1, "scheduled"), (2, "prepaid")] {
        let t: Vec<String> = years.iter().map(|&y| {
            let s: f64 = r8[12 * (y - 1)..12 * y].iter().map(|r| [r.0, r.1, r.2][k]).sum();
            format!("{:10.2}", s)
        }).collect();
        println!("chart, {:<10} in year 8%  {}", name, t.join(" "));
    }

    assert!(((1.0 - s8).powf(12.0) - 0.92).abs() < 1e-12, "SMM compounds back to CPR");
    assert!((1..N).all(|m| (r8[m - 1].3 - closed(m, 0.08)).abs() < 1e-6), "ledger = closed form");
    assert!((sim_b[120] - closed(120, 0.08)).abs() < 0.02 * L && (sim_wal - wal(r8)).abs() < 0.25, "loans");
    assert!((returned - L).abs() < 1e-6, "every dollar lent comes back once");
    assert!(runs.iter().all(|r| (value(r, 0.06) - L).abs() < 1e-6), "at the coupon rate, value = par");
    assert!((1..N).all(|m| (rp[m - 1].3 - closed_path(m, &path)).abs() < 1e-6), "changing speed");
    assert!((r8[1].0 + r8[1].1 - (1.0 - s8) * a).abs() < 1e-9, "payment shrinks with the survivors");
    println!("ALL CHECKS PASS");
}
