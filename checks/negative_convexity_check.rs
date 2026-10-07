// Negative convexity -- the same check as negative_convexity_check.py, in Rust.
// Standard library only, no crates.  The house pool: $100 of 30-year mortgages,
// 6% coupon paid monthly, prepaying at 8% a year when the market yield is 6%;
// every point the yield drops adds 2.55 points to the yearly prepayment rate.
const L: f64 = 100.0;
const N: usize = 360;
const I: f64 = 0.06 / 12.0;
const BASE_CPR: f64 = 0.08;
const SLOPE: f64 = 2.55;
const FLOOR: f64 = 0.02;

fn cpr(y: f64, slope: f64) -> f64 { (BASE_CPR + slope * (0.06 - y)).max(FLOOR) }
fn smm(c: f64) -> f64 { 1.0 - (1.0 - c).powf(1.0 / 12.0) }

// Road 1: run the pool month by month.  Re-amortise, pay, prepay, discount.
fn ledger(y: f64, slope: f64) -> (f64, f64) {
    let (s, j) = (smm(cpr(y, slope)), y / 12.0);
    let (mut bal, mut pv, mut wal) = (L, 0.0, 0.0);
    for m in 1..=N {
        let pay = bal * I / (1.0 - (1.0 + I).powi(-((N - m + 1) as i32)));
        let sched = pay - bal * I;
        let extra = s * (bal - sched);
        pv += (pay + extra) / (1.0 + j).powi(m as i32);
        wal += m as f64 / 12.0 * (sched + extra);
        bal -= sched + extra;
    }
    (pv, wal / L)
}

fn balance(m: usize, c: f64) -> f64 {             // opening balance of month m, closed form
    let g = (1.0 + I).powi(N as i32);
    L * (g - (1.0 + I).powi(m as i32 - 1)) / (g - 1.0) * (1.0 - c).powf((m as f64 - 1.0) / 12.0)
}

// Road 2: no ledger.  V = L + (i - j) * F, F = sum of discounted opening balances.
fn closed(y: f64) -> f64 {
    let (c, j) = (cpr(y, SLOPE), y / 12.0);
    let f: f64 = (1..=N).map(|m| balance(m, c) / (1.0 + j).powi(m as i32)).sum();
    L + (I - j) * f
}

// Road 3: no bumps.  D = F/(12L), C = -F'/(6L), F' split into its two causes.
fn exact_at_par() -> (f64, f64, f64) {
    let (c, j) = (cpr(0.06, SLOPE), 0.005_f64);
    let (mut f, mut f_disc, mut f_speed) = (0.0, 0.0, 0.0);
    for m in 1..=N {
        let (b, mf) = (balance(m, c), m as f64);
        f += b / (1.0 + j).powi(m as i32);
        f_disc += -(mf / 12.0) * b / (1.0 + j).powi(m as i32 + 1);
        f_speed += b / (1.0 + j).powi(m as i32) * ((mf - 1.0) / 12.0) * SLOPE / (1.0 - c);
    }
    (f / (12.0 * L), -f_disc / (6.0 * L), -f_speed / (6.0 * L))
}

fn bumped<P: Fn(f64) -> f64>(price: P, y0: f64, d: f64) -> (f64, f64, f64, f64, f64) {
    let (dn, v0, up) = (price(y0 - d), price(y0), price(y0 + d));
    (dn, v0, up, (dn - up) / (2.0 * v0 * d), (dn + up - 2.0 * v0) / (v0 * d * d))
}

fn main() {
    let p1 = |y: f64| ledger(y, SLOPE).0;
    let (dn, v0, up, d1, c1) = bumped(p1, 0.06, 0.01);
    let (_, _, _, d2, c2) = bumped(closed, 0.06, 0.01);
    let (_, _, _, dbp, cbp) = bumped(p1, 0.06, 0.0001);
    let (d3, c_disc, c_speed) = exact_at_par();
    let c3 = c_disc + c_speed;
    let (fdn, _, fup, df, cf) = bumped(|y: f64| ledger(y, 0.0).0, 0.06, 0.01);
    let (d_down, d_up) = ((dn - v0) / (v0 * 0.01), (v0 - up) / (v0 * 0.01));
    let pred_dn = L * (1.0 + d3 * 0.01 + 0.5 * c3 * 0.0001);
    let pred_up = L * (1.0 - d3 * 0.01 + 0.5 * c3 * 0.0001);
    let wrong_units = L * (1.0 - d1 * 0.01 + 0.5 * (c1 / 100.0) * 0.0001);
    let right_units = L * (1.0 - d1 * 0.01 + 0.5 * c1 * 0.0001);
    let c_25 = bumped(p1, 0.06, 0.0025).4;
    let c_300 = bumped(p1, 0.06, 0.03).4;
    let (_, _, _, d_dbl, c_dbl) = bumped(|y: f64| ledger(y, 2.0 * SLOPE).0, 0.06, 0.01);

    let rows: Vec<(&str, f64)> = vec![
        ("month-1 payment per $100", L * I / (1.0 - (1.0 + I).powi(-(N as i32)))),
        ("monthly prepay fraction at 6%", smm(cpr(0.06, SLOPE))),
        ("CPR at 5%", cpr(0.05, SLOPE)), ("CPR at 6%", cpr(0.06, SLOPE)), ("CPR at 7%", cpr(0.07, SLOPE)),
        ("1 ledger  V at 5%", dn), ("1 ledger  V at 6%", v0), ("1 ledger  V at 7%", up),
        ("2 closed  V at 5%", closed(0.05)), ("2 closed  V at 6%", closed(0.06)),
        ("2 closed  V at 7%", closed(0.07)),
        ("gain on a 1-point fall", dn - v0), ("loss on a 1-point rise", v0 - up),
        ("price swing, V- minus V+", dn - up), ("the miss, V- + V+ - 2 V0", dn + up - 2.0 * v0),
        ("1 ledger  D_eff, 100 bp", d1), ("1 ledger  C_eff, 100 bp", c1),
        ("2 closed  D_eff, 100 bp", d2), ("2 closed  C_eff, 100 bp", c2),
        ("  C_eff / 100, as quoted", c1 / 100.0), ("  half of that", c1 / 200.0),
        ("1 ledger  D_eff, 1 bp", dbp), ("1 ledger  C_eff, 1 bp", cbp),
        ("3 exact   D at par", d3), ("3 exact   C at par", c3),
        ("  discounting part of C", c_disc), ("  prepayment part of C", c_speed),
        ("down-side duration", d_down), ("up-side duration", d_up),
        ("average life at 5%, years", ledger(0.05, SLOPE).1), ("average life at 6%, years", ledger(0.06, SLOPE).1),
        ("average life at 7%, years", ledger(0.07, SLOPE).1),
        ("Taylor V at 5%, exact D and C", pred_dn), ("Taylor V at 7%, exact D and C", pred_up),
        ("wrong: speed frozen, V at 5%", fdn), ("wrong: speed frozen, V at 7%", fup),
        ("wrong: speed frozen, D_eff", df), ("wrong: speed frozen, C_eff", cf),
        ("wrong: -1.2 used as years^2, V at 7%", wrong_units),
        ("  right units, V at 7%", right_units),
        ("try: C_eff, 25 bp bumps", c_25), ("try: C_eff, 300 bp bumps", c_300),
        ("try: slope doubled, D_eff", d_dbl), ("try: slope doubled, C_eff", c_dbl),
    ];
    for (name, v) in &rows { println!("{:<38} {:>12.6}", name, v); }

    let ys: Vec<f64> = (0..11).map(|k| 0.03 + 0.005 * k as f64).collect();   // chart: 3% to 8%
    let line = |f: &dyn Fn(f64) -> f64, fmt1: bool| -> String {
        ys.iter().map(|&y| if fmt1 { format!("{:6.1}", f(y)) } else { format!("{:6.2}", f(y)) })
            .collect::<Vec<_>>().join(" ")
    };
    println!("chart, yield %     {}", line(&|y| 100.0 * y, true));
    println!("chart, prepaying   {}", line(&|y| ledger(y, SLOPE).0, false));
    println!("chart, frozen 8%   {}", line(&|y| ledger(y, 0.0).0, false));
    println!("chart, tangent     {}", line(&|y| L * (1.0 - d3 * (y - 0.06)), false));

    assert!((v0 - L).abs() < 1e-9, "ledger at par must equal the par identity's 100");
    assert!((dn - closed(0.05)).abs() < 1e-9 && (up - closed(0.07)).abs() < 1e-9, "roads 1 and 2 disagree");
    assert!((cbp - c3).abs() < 0.01, "1 bp bumped convexity vs exact derivative");
    assert!((dbp - d3).abs() < 1e-5, "1 bp bumped duration vs exact derivative");
    assert!((cf - c_disc).abs() < 1.0, "frozen pool's convexity vs discounting part");
    assert!(c1 < 0.0 && 0.0 < cf && (c1 / 100.0 + 1.2).abs() < 0.05, "house pool must show -1.2 per hundred");
    println!("ALL CHECKS PASS");
}
