// Total return swap on Acme -- the same check as equity_swaps_and_total_return_swaps_check.py.
// Standard library only, no crates.  Road 1: the closed forms (fair spread f - b, and the mark).
// Road 2: the dealer's hedge ledger, cash item by item, on 2,000 random paths, plus bisection on
// that ledger for the spread.  Road 3: the dealer's hedge book at the reset, against the mark.
const N_SH: f64 = 10_000.0; // shares
const S0: f64 = 100.0; // Acme's price at the start: notional 1,000,000
const A: f64 = 0.25; // quarter as a year fraction
const L: f64 = 0.05; // SOFR, simple, flat
const F: f64 = 0.004; // dealer's funding spread over SOFR
const B: f64 = 0.01; // borrow fee
const D: f64 = 0.50; // Acme's dividend per share, paid on each reset date
const S_FAIR: f64 = F - B; // road 1: the fair spread

// Road 2: the dealer's quarter, one cash item at a time; returns its net cash at the end.
fn hedge_quarter(sa: f64, sb: f64, div: f64, lq: f64, s: f64) -> f64 {
    let loan = N_SH * sa; // borrow at SOFR + f to buy n shares at the reset
    let mut cash = N_SH * sb + N_SH * div; // sell the shares at the next reset; dividends received
    cash += N_SH * sa * A * B; // fee for lending the shares out over the quarter
    cash -= loan * (1.0 + A * (lq + F)); // repay the loan with interest
    cash -= N_SH * (sb - sa) + N_SH * div; // pay the receiver: price return plus dividends
    cash += loan * A * (lq + s); // collect the funding leg: SOFR + s on the reset notional
    cash
}

// Road 1: value to the receiver, tau years before the next reset.
fn mark(st: f64, tau: f64, n_prev: f64, s: f64, cash_now: f64) -> f64 {
    let owed = n_prev * (1.0 + A * (L + s)); // the funding leg plus the reset notional
    (N_SH * st * (1.0 + tau * (L + S_FAIR)) + cash_now - owed) / (1.0 + L * tau)
}

struct Rng(u64);
impl Rng {
    fn next(&mut self) -> f64 { // xorshift64, the same generator as the Python check
        self.0 ^= self.0 << 13;
        self.0 ^= self.0 >> 7;
        self.0 ^= self.0 << 17;
        (self.0 >> 11) as f64 / 9007199254740992.0
    }
}

fn random_path(rng: &mut Rng) -> Vec<(f64, f64, f64, f64)> {
    let (mut s, mut out) = (S0, Vec::new());
    for _ in 0..4 {
        let mut z = 0.0;
        for _ in 0..12 { z += rng.next(); } // roughly a bell-curve draw
        let s1 = s * (0.10 * (z - 6.0)).exp(); // 20% a year volatility, one quarter
        let div = rng.next();
        let lq = 0.03 + 0.04 * rng.next(); // dividend 0 to 1, SOFR fixing 3% to 7%
        out.push((s, s1, div, lq));
        s = s1;
    }
    out
}

fn ledger(p: &[(f64, f64, f64, f64)], s: f64) -> f64 {
    p.iter().map(|q| hedge_quarter(q.0, q.1, q.2, q.3, s)).sum()
}

fn commas(v: f64) -> String { // 1234567.891 -> 1,234,567.89
    let t = format!("{:.2}", v.abs());
    let (int, frac) = t.split_at(t.len() - 3);
    let mut g = String::new();
    for (i, c) in int.chars().enumerate() {
        if i > 0 && (int.len() - i) % 3 == 0 { g.push(','); }
        g.push(c);
    }
    format!("{}{}{}", if v < 0.0 && t != "0.00" { "-" } else { "" }, g, frac)
}

fn main() {
    let mut rng = Rng(88172645463325252);
    let (mut worst_fair, mut worst_leak) = (0.0_f64, 0.0_f64);
    let mut first: Vec<(f64, f64, f64, f64)> = Vec::new();
    for k in 0..2000 {
        let p = random_path(&mut rng);
        if k == 0 { first = p.clone(); }
        worst_fair = worst_fair.max(ledger(&p, S_FAIR).abs());
        let leak = ledger(&p, S_FAIR + 0.001);
        let predicted: f64 = p.iter().map(|q| N_SH * q.0 * A * 0.001).sum();
        worst_leak = worst_leak.max((leak - predicted).abs());
    }
    let (mut lo, mut hi) = (-0.05_f64, 0.05_f64); // bisection on the ledger of the first path
    for _ in 0..100 {
        let mid = 0.5 * (lo + hi);
        if ledger(&first, mid) < 0.0 { lo = mid; } else { hi = mid; }
    }
    let s_bisect = 0.5 * (lo + hi);

    let (n1, s3) = (N_SH * S0, 105.0_f64); // the 3-month reset: Acme at 105, dividend just paid
    let v3 = mark(s3, 0.0, n1, S_FAIR, N_SH * D);
    let book = N_SH * s3 + N_SH * D + n1 * A * B - n1 * (1.0 + A * (L + F)); // road 3
    let (tau4, v4) = (2.0 / 12.0, mark(107.0, 2.0 / 12.0, N_SH * s3, S_FAIR, 0.0)); // month 4
    let mut worst4 = 0.0_f64; // a new dealer hedges from 107; its book at the reset, item by item
    for _ in 0..100 {
        let s6 = 107.0 * (0.1 * (rng.next() - 0.5)).exp();
        let div = rng.next();
        let mut book4 = N_SH * s6 + N_SH * div + N_SH * 107.0 * tau4 * B - N_SH * 107.0 * (1.0 + tau4 * (L + F));
        book4 += -(N_SH * (s6 - s3) + N_SH * div) + N_SH * s3 * A * (L + S_FAIR);
        worst4 = worst4.max((book4 + v4 * (1.0 + L * tau4)).abs());
    }
    let f_house = S0 * ((L + (0.0 - B) - 0.02) * 1.0).exp(); // f = 0: financing at SOFR - 1%
    let f_noborrow = S0 * ((L - 0.02) * 1.0).exp();
    let carried = N_SH * 107.0 * (1.0 + 2.0 / 12.0 * (L + S_FAIR));
    let owed4 = N_SH * s3 * (1.0 + A * (L + S_FAIR));
    let rows: Vec<(&str, f64)> = vec![
        ("fair spread f - b, %", 100.0 * S_FAIR), ("fair spread by bisection on the ledger, %", 100.0 * s_bisect),
        ("worst |dealer P&L| at fair spread, 2000 paths", worst_fair),
        ("worst |leak - predicted| at fair + 0.10%", worst_leak),
        ("3m: price return", N_SH * (s3 - S0)), ("3m: dividends", N_SH * D),
        ("3m: funding leg SOFR + s", n1 * A * (L + S_FAIR)),
        ("3m: mark before the exchange", v3), ("3m: dealer's hedge book", book),
        ("3m hedge: fee for lending the shares", n1 * A * B), ("3m hedge: loan repaid", n1 * (1.0 + A * (L + F))),
        ("3m: mark after the exchange", mark(s3, A, N_SH * s3, S_FAIR, 0.0)),
        ("4m: Acme 107 carried to the reset", carried),
        ("4m: owed at the reset", owed4),
        ("4m: gap at the reset", carried - owed4),
        ("4m: SOFR growth to the reset", 1.0 + L * 2.0 / 12.0),
        ("4m: mark, the gap discounted", v4), ("4m: worst |takeover hedge - mark|", worst4),
        ("wrong: spread = dealer funding only", mark(s3, 0.0, n1, F, N_SH * D)),
        ("wrong: dividends left out", mark(s3, 0.0, n1, S_FAIR, 0.0)),
        ("wrong: funding leg forgotten", N_SH * (s3 - S0) + N_SH * D),
        ("house: 1y forward financed at SOFR - 1%", f_house), ("house: 1y forward, no borrow fee", f_noborrow),
        ("try: borrow fee 0.25%, fair spread %", 100.0 * (F - 0.0025)),
        ("try: borrow fee 5%, fair spread %", 100.0 * (F - 0.05)),
        ("try: dealer funds at SOFR, fair spread %", 100.0 * (0.0 - B)),
        ("try: Acme at 95 at 3m, mark", mark(95.0, 0.0, n1, S_FAIR, N_SH * D)),
    ];
    for (name, v) in &rows { println!("{:<46} {:>14.4}", name, v); }

    println!();
    println!("month  Acme  quarter-start notional  mark to the receiver  cash paid at reset");
    let path = [100.0, 102.0, 101.0, 105.0, 107.0, 104.0, 106.0, 103.0, 101.0, 98.0, 100.0, 103.0, 104.0_f64];
    let (mut nq, mut total, mut marks) = (N_SH * S0, 0.0_f64, Vec::new());
    for m in 0..13usize {
        let reset = m > 0 && m % 3 == 0;
        let (st, tau) = (path[m], if reset { 0.0 } else { (3 - m % 3) as f64 / 12.0 });
        let v = mark(st, tau, nq, S_FAIR, if reset { N_SH * D } else { 0.0 });
        marks.push(v);
        let paid = if reset { v } else { 0.0 };
        total += paid;
        println!("{:>5} {:5.0} {:>23} {:>21} {:>19}", m, st, commas(nq), commas(v), commas(paid));
        if reset { nq = N_SH * st; }
    }
    println!("cash to the receiver over the year {}", commas(total));
    let ch: Vec<String> = marks.iter().map(|v| format!("{:.1}", v / 1000.0)).collect();
    println!("chart, mark in thousands {}", ch.join(" "));

    assert!((s_bisect - S_FAIR).abs() < 1e-12, "bisection on the hedge ledger lands on f - b");
    assert!(worst_fair < 1e-6, "the hedge at the fair spread is flat on every path");
    assert!(worst_leak < 1e-6, "an off-market spread leaks exactly n S a (s - s*) a quarter");
    assert!((v3 - book).abs() < 1e-6, "the mark at the reset equals the dealer's hedge book");
    assert!(worst4 < 1e-6, "between resets: the takeover hedge pays the mark, path by path");
    assert!((v3 - 44_000.0).abs() < 1e-6, "the card's worked number");
    assert!((f_house - 102.0201).abs() < 1e-4, "the shelf's house forward");
    println!("ALL CHECKS PASS");
}
