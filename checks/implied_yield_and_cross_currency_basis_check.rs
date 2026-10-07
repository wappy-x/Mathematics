// Implied yield and cross-currency basis -- the same check as the Python, in Rust.  std only.
// EURUSD quoted in dollars per euro.  Rates continuously compounded, as decimals; time in years.
// Road 1: the closed form rf = rd - ln(F/S)/T.
// Road 2: bisection on the parity formula itself, using exp only: no logarithm in it.
// Road 3: the cash ledger of borrowing dollars through the FX market, read off as a rate.
// Compile: rustc --edition 2021 -O implied_yield_and_cross_currency_basis_check.rs -o /tmp/<dir>/chk

const S: f64 = 1.10;
const RD: f64 = 0.05;
const RF_DEP: f64 = 0.03;
const PIP: f64 = 0.0001;

fn implied_rf(s: f64, f: f64, rd: f64, t: f64) -> f64 { rd - (f / s).ln() / t }   // road 1
fn implied_rd(s: f64, f: f64, rf: f64, t: f64) -> f64 { rf + (f / s).ln() / t }

fn bisect_rf(s: f64, f: f64, rd: f64, t: f64) -> f64 {
    // road 2: the forward s e^{(rd - rf)t} falls as rf rises, so halve the bracket 200 times.
    let (mut lo, mut hi) = (-1.0_f64, 1.0_f64);
    for _ in 0..200 {
        let mid = 0.5 * (lo + hi);
        if s * ((rd - mid) * t).exp() > f { lo = mid; } else { hi = mid; }
    }
    0.5 * (lo + hi)
}

fn ledger(s: f64, f: f64, rf: f64, t: f64) -> (f64, f64) {
    // road 3: borrow one euro at the deposit rate, sell it at spot, buy the repayment forward.
    (s, (rf * t).exp() * f)
}

fn show(label: &str, v: f64) { println!("{:<40}{:>14.6}", label, v); }
fn show2(label: &str, v: f64) { println!("{:<40}{:>14.2}", label, v); }

fn main() {
    let (f_house, f_house3m) = (S + 222.21 * PIP, S + 55.14 * PIP);
    let r_house = implied_rf(S, f_house, RD, 1.0);
    let r_house3m = implied_rf(S, f_house3m, RD, 0.25);
    show("house F, 1 year (+222.21 pips)", f_house);
    show("  ln(F / S)", (f_house / S).ln());
    show("  implied euro rate, %", 100.0 * r_house);
    show("house F, 3 months (+55.14 pips)", f_house3m);
    show("  implied euro rate, %", 100.0 * r_house3m);

    let mut cases: Vec<(f64, f64, f64, f64, f64, f64)> = Vec::new();
    for pips in [195.0_f64, 249.0] {
        let f = S + pips * PIP;
        let (r1, r2) = (implied_rf(S, f, RD, 1.0), bisect_rf(S, f, RD, 1.0));
        let (usd_now, usd_owed) = ledger(S, f, RF_DEP, 1.0);
        let synth = (usd_owed / usd_now).ln();
        let basis = r1 - RF_DEP;
        cases.push((f, r1, r2, synth, basis, usd_owed));
        println!();
        show(&format!("market +{:.0} pips: F", pips), f);
        show("  F / S", f / S);
        show("  ln(F / S)", (f / S).ln());
        show("  1 closed form, implied euro %", 100.0 * r1);
        show("  2 bisection, implied euro %", 100.0 * r2);
        show2("  basis = implied - deposit, bp", 1e4 * basis);
        show("  3 ledger: dollars owed per euro", usd_owed);
        show("    synthetic dollar rate, %", 100.0 * synth);
        show2("    basis = 5% - synthetic, bp", 1e4 * (RD - synth));
        show("  implied dollar rate at 3% euro, %", 100.0 * implied_rd(S, f, RF_DEP, 1.0));
    }

    let (f249, usd_owed249) = (cases[1].0, cases[1].5);
    let repay = S * RD.exp();
    println!();
    show("euros owed at T per euro borrowed at 3%", RF_DEP.exp());
    show("+249: lend dollars via swap, receive", usd_owed249);
    show("  repay the dollar loan", repay);
    show("  profit per euro", usd_owed249 - repay);
    show2("  profit on EUR 10m", 1e7 * (usd_owed249 - repay));

    println!();
    show("wrong: sign flipped, rd + ln(F/S), %", 100.0 * (RD + (f249 / S).ln()));
    show("wrong: 3M house, T dropped, %", 100.0 * (RD - (f_house3m / S).ln()));
    show("wrong: points/spot, no log, %", 100.0 * (RD - (f249 - S) / S));
    show2("wrong: basis as deposit - implied, bp", 1e4 * (RF_DEP - cases[1].1));

    println!();
    show("try: +700 pips, implied euro %", 100.0 * implied_rf(S, S + 700.0 * PIP, RD, 1.0));
    show("try: F = S, implied euro %", 100.0 * implied_rf(S, S, RD, 1.0));
    show("try: +249 over 2 years, implied %", 100.0 * implied_rf(S, f249, RD, 2.0));

    println!();
    for (name, t) in [("1 week", 7.0 / 365.0), ("1 month", 1.0 / 12.0), ("3 months", 0.25), ("1 year", 1.0)] {
        let ft = S * ((RD - RF_DEP) * t).exp();
        let mv = implied_rf(S, ft, RD, t) - implied_rf(S, ft + PIP, RD, t);
        show2(&format!("bar, bp per pip, {}", name), 1e4 * mv);
    }

    println!();
    let grid = [150.0_f64, 175.0, 195.0, 222.21, 249.0, 275.0, 300.0];
    let pts: Vec<String> = grid.iter().map(|p| format!("{:7.2}", p)).collect();
    let rts: Vec<String> = grid.iter().map(|p| format!("{:7.2}", 100.0 * implied_rf(S, S + p * PIP, RD, 1.0))).collect();
    println!("chart, points  {}", pts.join(" "));
    println!("chart, euro %  {}", rts.join(" "));

    let fwd: Vec<f64> = (0..201).map(|i| S * (RD - (-0.05 + 0.001 * i as f64)).exp()).collect();
    assert!(fwd.windows(2).all(|w| w[0] > w[1]), "forward must fall as the euro rate rises");
    assert!((r_house - RF_DEP).abs() < 5e-6, "house points give back 3% to the quote's precision");
    assert!((r_house3m - bisect_rf(S, f_house3m, RD, 0.25)).abs() < 1e-12, "3-month closed form and bisection agree");
    for &(f, r1, r2, synth, basis, _) in &cases {
        assert!((r1 - r2).abs() < 1e-12, "closed form and bisection agree");
        assert!(((RD - synth) - basis).abs() < 1e-12, "ledger basis equals implied minus deposit");
        assert!((S * (RD - r2).exp() - f).abs() < 1e-12, "bisection's rate rebuilds the quoted forward");
    }
    assert!(cases[0].4 > 0.0 && 0.0 > cases[1].4, "fewer points than fair: basis up; more: down");
    println!("ALL CHECKS PASS");
}
