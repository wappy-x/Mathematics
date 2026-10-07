// Reading a currency quote -- the same check as currency_quotes_and_cross_rates_check.py, in Rust.
// Standard library only, no crates.  A pair "AB" at price q: 1 unit of A (the base) costs q of B.
// Road 1: the cross-rate formulas by hand.  Road 2: a ledger that walks real amounts through
// each trade.  Road 3: every possible loop through the three currencies, tried one by one.
use std::collections::HashMap;

type Book = HashMap<String, f64>;

fn book(pairs: &[(&str, f64)]) -> Book {
    pairs.iter().map(|(k, v)| (k.to_string(), *v)).collect()
}

// Sell `amount` of frm for to, using whichever way round the pair is quoted.
fn convert(amount: f64, frm: &str, to: &str, b: &Book) -> f64 {
    if let Some(q) = b.get(&format!("{}{}", frm, to)) { return amount * q; } // selling the base
    if let Some(q) = b.get(&format!("{}{}", to, frm)) { return amount / q; } // buying the base
    panic!("no quote for {}{}", frm, to);
}

fn main() {
    let (eurusd, usdjpy, gbpusd, broker) = (1.1000_f64, 150.00_f64, 1.2500_f64, 165.50_f64);
    let bk = book(&[("EURUSD", eurusd), ("USDJPY", usdjpy), ("GBPUSD", gbpusd), ("EURJPY", broker)]);
    let fair = book(&[("EURUSD", eurusd), ("USDJPY", usdjpy), ("GBPUSD", gbpusd)]);

    // ---- Road 1: formulas ----
    let usdeur = 1.0 / eurusd;
    let eurjpy = eurusd * usdjpy;          // USD cancels
    let eurgbp = eurusd / gbpusd;          // USD on the money side of both: divide
    let edge = broker / eurjpy - 1.0;
    let pips = (broker - eurjpy) / 0.01;   // a yen-pair pip is 0.01
    // ---- Road 2: ledger ----
    let eurjpy_l = convert(convert(1.0, "EUR", "USD", &fair), "USD", "JPY", &fair);
    let eurgbp_l = convert(convert(1.0, "EUR", "USD", &fair), "USD", "GBP", &fair);
    let usdeur_l = convert(1.0, "USD", "EUR", &fair);
    let jpy0 = 16_500_000.0_f64;
    let usd1 = convert(jpy0, "JPY", "USD", &bk);
    let eur2 = convert(usd1, "USD", "EUR", &bk);
    let jpy3 = convert(eur2, "EUR", "JPY", &bk);
    let profit_l = jpy3 / jpy0 - 1.0;
    let pip_pnl = 50.0 * 0.01 * eur2;
    // ---- Road 3: every loop, in the same order as Python's permutations ----
    let cur = ["EUR", "USD", "JPY"];
    let mut loops: Vec<(String, f64)> = Vec::new();
    for i in 0..3 { for j in 0..3 { for k in 0..3 {
        if i == j || j == k || i == k { continue; }
        let (a, b, c) = (cur[i], cur[j], cur[k]);
        let end = convert(convert(convert(1.0, a, b, &bk), b, c, &bk), c, a, &bk);
        loops.push((format!("{}>{}>{}>{}", a, b, c, a), end - 1.0));
    }}}
    let mut best = loops[0].clone();
    let mut worst = loops[0].clone();
    for l in &loops {
        if l.1 > best.1 { best = l.clone(); }
        if l.1 < worst.1 { worst = l.clone(); }
    }

    // ---- bid and ask ----
    let (eb, ea, jb, ja) = (1.0999_f64, 1.1001_f64, 149.99_f64, 150.01_f64);
    let (x_bid, x_ask) = (eb * jb, ea * ja);
    let (inv_bid, inv_ask) = (1.0 / ea, 1.0 / eb);
    let inv_bid_l = convert(1.0, "USD", "EUR", &book(&[("EURUSD", ea)]));       // euros got for 1 USD sold
    let inv_ask_l = 1.0 / convert(1.0, "EUR", "USD", &book(&[("EURUSD", eb)])); // euros paid per USD bought
    let sold = convert(convert(1.0, "EUR", "USD", &book(&[("EURUSD", eb)])), "USD", "JPY", &book(&[("USDJPY", jb)]));
    let bought = convert(convert(1.0, "JPY", "USD", &book(&[("USDJPY", ja)])), "USD", "EUR", &book(&[("EURUSD", ea)]));
    let profit_sp = broker / x_ask - 1.0;

    // ---- what breaks ----
    let w_mult = eurusd * gbpusd;
    let w_div = eurusd / usdjpy;
    let (w_ib, w_ia) = (1.0 / eb, 1.0 / ea);
    let w_pips = (broker - eurjpy) / 0.0001;
    let up_eur = 1.12 / 1.10 - 1.0;
    let dn_usd = (1.0 / 1.12) / (1.0 / 1.10) - 1.0;

    let rows: Vec<(&str, f64)> = vec![
        ("EURUSD, USD per EUR", eurusd), ("USDJPY, JPY per USD", usdjpy), ("GBPUSD, USD per GBP", gbpusd),
        ("USDEUR = 1/EURUSD", usdeur), ("  ledger: 1 USD -> EUR", usdeur_l),
        ("EURJPY = EURUSD x USDJPY", eurjpy), ("  ledger: 1 EUR -> USD -> JPY", eurjpy_l),
        ("EURGBP = EURUSD / GBPUSD", eurgbp), ("  ledger: 1 EUR -> USD -> GBP", eurgbp_l),
        ("broker EURJPY", broker), ("broker rich by, yen", broker - eurjpy), ("broker rich by, pips of 0.01", pips), ("broker rich by, %", 100.0 * edge),
        ("loop: start JPY", jpy0), ("  -> USD", usd1), ("  -> EUR", eur2), ("  -> JPY", jpy3),
        ("  kept, JPY", jpy3 - jpy0), ("  kept, %", 100.0 * profit_l), ("  50 pips on the euros, JPY", pip_pnl),
        ("spread: EURUSD bid", eb), ("spread: EURUSD ask", ea), ("spread: USDJPY bid", jb), ("spread: USDJPY ask", ja),
        ("spread: EURJPY bid = bid x bid", x_bid), ("  ledger: sell 1 EUR", sold),
        ("spread: EURJPY ask = ask x ask", x_ask), ("  ledger: buy 1 EUR costs", 1.0 / bought),
        ("spread: USDEUR bid = 1/ask", inv_bid), ("spread: USDEUR ask = 1/bid", inv_ask),
        ("spread: loop kept, %", 100.0 * profit_sp),
        ("wrong: EURGBP multiplied", w_mult), ("wrong: EURJPY divided", w_div),
        ("wrong: USDEUR bid not swapped", w_ib), ("wrong: USDEUR ask not swapped", w_ia),
        ("wrong: yen pips at 0.0001", w_pips), ("wrong: loop run backwards, %", 100.0 * worst.1),
        ("EURUSD 1.10 -> 1.12: euro, %", 100.0 * up_eur), ("  same move: dollar, %", 100.0 * dn_usd),
        ("try: USDJPY 140 -> EURJPY", eurusd * 140.0), ("try: GBPUSD 1.35 -> EURGBP", eurusd / 1.35),
        ("try: broker 164.50 -> kept, %", 100.0 * (eurjpy / 164.50 - 1.0)),
    ];
    for (name, v) in &rows { println!("{:<34} {:>18.6}", name, v); }
    println!();
    println!("every loop, starting with 1 unit       kept, %");
    for (name, p) in &loops { println!("  {:<32} {:>+10.4}", name, 100.0 * p); }
    println!("  best: {}", best.0);
    let qs: Vec<f64> = (0..9).map(|i| 164.00 + 0.25 * i as f64).collect();
    let line = |f: &dyn Fn(f64) -> f64| qs.iter().map(|q| format!("{:7.2}", f(*q))).collect::<Vec<_>>().join(" ");
    println!("chart, broker EURJPY  {}", line(&|q| q));
    println!("chart, kept % no sprd {}", line(&|q| 100.0 * (q / eurjpy - 1.0).max(eurjpy / q - 1.0)));
    println!("chart, kept % spread  {}", line(&|q| 100.0 * (q / x_ask - 1.0).max(x_bid / q - 1.0).max(0.0)));

    assert!((eurjpy - eurjpy_l).abs() < 1e-9, "cross: formula vs ledger");
    assert!((eurgbp - eurgbp_l).abs() < 1e-12, "divide: formula vs ledger");
    assert!((usdeur - usdeur_l).abs() < 1e-12, "invert: formula vs ledger");
    assert!((profit_l - edge).abs() < 1e-12, "ledger loop keeps what the formula says");
    assert!((best.1 - edge).abs() < 1e-12, "search: best loop keeps the formula's edge");
    assert!(loops.iter().filter(|l| l.1 > 0.0).count() == 3, "search: one direction wins, from any start");
    assert!((worst.1 - (1.0 / (1.0 + edge) - 1.0)).abs() < 1e-12, "backwards loop loses 1/(1+e) - 1");
    assert!((pip_pnl - (jpy3 - jpy0)).abs() < 1e-6, "pips x pip size x euros = ledger profit");
    assert!((sold - x_bid).abs() < 1e-9, "cross bid: formula vs ledger");
    assert!((1.0 / bought - x_ask).abs() < 1e-9, "cross ask: formula vs ledger");
    assert!((inv_bid - inv_bid_l).abs() < 1e-12, "inverted bid: formula vs ledger");
    assert!((inv_ask - inv_ask_l).abs() < 1e-12, "inverted ask: formula vs ledger");
    assert!(inv_bid_l < inv_ask_l, "inverted quote keeps bid below ask");
    assert!(((jpy3 - jpy0) - 50_000.0).abs() < 1e-6, "the card's loop keeps 50,000 yen");
    assert!(!(165.00 > x_ask || 166.00 < x_bid), "two-sided broker 165.00/166.00: no loop pays");
    println!("ALL CHECKS PASS");
}
