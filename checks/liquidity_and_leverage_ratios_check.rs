// Liquidity and leverage ratios -- the same check as liquidity_and_leverage_ratios_check.py, in Rust.
// Standard library only, no crates.  One bank, money in millions of dollars.
// Compile: rustc --edition 2021 -O liquidity_and_leverage_ratios_check.rs -o /tmp/liq_check
use std::collections::BTreeMap;

type Book = BTreeMap<&'static str, f64>;
const UNDRAWN: f64 = 200.0; const LOAN_DUE: f64 = 40.0; const RWA: f64 = 500.0;   // credit lines, loans due

fn book(items: &[(&'static str, f64)]) -> Book { items.iter().cloned().collect() }
fn assets() -> Book {
    book(&[("cash", 80.0), ("gov", 170.0), ("l2a", 50.0), ("l2b", 20.0), ("mortgage", 600.0),
           ("corp_short", 100.0), ("corp_long", 300.0), ("trading", 100.0), ("other", 30.0)])
}
fn funding() -> Book {
    book(&[("stable", 500.0), ("less_stable", 300.0), ("corporate", 200.0), ("interbank", 100.0),
           ("bonds", 200.0), ("other", 90.0), ("equity", 60.0)])
}
fn runoff(k: &str) -> f64 {
    match k { "stable" => 0.05, "less_stable" => 0.10, "corporate" => 0.40, "interbank" => 1.0, _ => 0.0 }
}
fn spread(k: &str) -> usize { match k { "corporate" => 10, "interbank" => 5, _ => 30 } }
fn asf_f(k: &str) -> f64 {
    match k { "stable" => 0.95, "less_stable" => 0.90, "corporate" => 0.50, "bonds" | "equity" => 1.0, _ => 0.0 }
}
fn rsf_f(k: &str) -> f64 {
    match k {
        "cash" => 0.0, "gov" => 0.05, "l2a" => 0.15, "l2b" | "corp_short" => 0.50, "mortgage" => 0.65,
        "corp_long" | "trading" => 0.85, _ => 1.0,
    }
}
fn g(b: &Book, k: &str) -> f64 { *b.get(k).unwrap_or(&0.0) }
fn total(b: &Book) -> f64 { b.values().sum() }

fn hqla(l1: f64, l2a: f64, l2b: f64) -> f64 {           // road 1: the Basel cap formula
    let adj15 = (l2b - 15.0 / 85.0 * (l1 + l2a)).max(l2b - 15.0 / 60.0 * l1).max(0.0);
    let adj40 = (l2a + l2b - adj15 - 2.0 / 3.0 * l1).max(0.0);
    l1 + l2a + l2b - adj15 - adj40
}
fn hqla_search(l1: f64, l2a: f64, l2b: f64, h: f64) -> f64 {   // road 2: largest legal count, by search
    let mut best = 0.0_f64;
    for i in 0..=((l2a / h).round() as usize) {
        for j in 0..=((l2b / h).round() as usize) {
            let (a, b) = (i as f64 * h, j as f64 * h);
            let tot = l1 + a + b;
            if a + b <= 0.40 * tot + 1e-12 && b <= 0.15 * tot + 1e-12 { best = best.max(tot); }
        }
    }
    best
}
// returns (HQLA, outflows, inflows, LCR, NSFR, leverage)
fn ratios(a: &Book, f: &Book) -> (f64, f64, f64, f64, f64, f64) {
    let h = hqla(g(a, "cash") + g(a, "gov"), 0.85 * g(a, "l2a"), 0.50 * g(a, "l2b"));
    let out: f64 = f.iter().map(|(k, v)| runoff(k) * v).sum::<f64>() + 0.10 * UNDRAWN;
    let inflow = 0.50 * LOAN_DUE;
    let lcr = h / (out - inflow.min(0.75 * out));
    let (asf, rsf) = (f.iter().map(|(k, v)| asf_f(k) * v).sum::<f64>(),
                      a.iter().map(|(k, v)| rsf_f(k) * v).sum::<f64>() + 0.05 * UNDRAWN);
    (h, out, inflow, lcr, asf / rsf, g(f, "equity") / (total(a) + 0.40 * UNDRAWN))
}
fn stress_path(h: f64, mult: f64) -> Vec<f64> {         // road 2 for the LCR: day by day
    let f = funding();
    let mut stock = vec![h];
    for d in 1..=30usize {
        let mut out: f64 = ["stable", "less_stable", "corporate", "interbank"].iter()
            .filter(|k| d <= spread(k)).map(|k| mult * runoff(k) * g(&f, k) / spread(k) as f64).sum();
        if d <= 20 { out += mult * 0.10 * UNDRAWN / 20.0; }
        stock.push(stock[d - 1] - out + if d == 30 { 0.50 * LOAN_DUE } else { 0.0 });   // loans repay day 30
    }
    stock
}
fn bisect<F: Fn(f64) -> f64>(f: F, mut lo: f64, mut hi: f64) -> f64 {
    for _ in 0..200 {
        let mid = 0.5 * (lo + hi);
        if (f(lo) > 0.0) == (f(mid) > 0.0) { lo = mid; } else { hi = mid; }
    }
    0.5 * (lo + hi)
}
fn scen(da: &[(&'static str, f64)], df: &[(&'static str, f64)]) -> (f64, f64, f64, f64, f64, f64) {
    let (mut a, mut f) = (assets(), funding());
    for (k, v) in da { *a.entry(k).or_insert(0.0) += v; }
    for (k, v) in df { *f.entry(k).or_insert(0.0) += v; }
    ratios(&a, &f)
}
fn row(label: &str, vals: &[f64], dp: usize) {
    let s: String = vals.iter().map(|v| format!("{:9.*}", dp, v)).collect();
    println!("{:<42}{}", label, s);
}

fn main() {
    let (a, f) = (assets(), funding());
    let (h, out, inflow, lcr, nsfr, lev) = ratios(&a, &f);
    let path = stress_path(h, 1.0);
    let lcr_sim = h / (h - path[30]);
    let lam_closed = (h + inflow) / out;
    let lam_bisect = bisect(|m| stress_path(h, m)[30], 0.5, 3.0);
    let lam_day = h / (["stable", "less_stable", "corporate", "interbank"].iter().map(|k| runoff(k) * g(&f, k) * spread(k).min(29) as f64 / spread(k) as f64).sum::<f64>() + 0.10 * UNDRAWN);
    let lam_day_b = bisect(|m| stress_path(h, m).iter().cloned().fold(f64::MAX, f64::min), 0.5, 3.0);   // every day
    let hard = stress_path(h, 1.5);
    let dry_day = hard.iter().position(|s| *s < 0.0).unwrap();
    let tot = total(&f);                                  // road 2 for the NSFR: whole balance sheet
    let unstable: f64 = f.iter().map(|(k, v)| (1.0 - asf_f(k)) * v).sum();
    let free: f64 = a.iter().map(|(k, v)| (1.0 - rsf_f(k)) * v).sum();
    let nsfr2 = (tot - unstable) / (tot - free + 0.05 * UNDRAWN);
    let asf: f64 = f.iter().map(|(k, v)| asf_f(k) * v).sum();
    let rsf: f64 = a.iter().map(|(k, v)| rsf_f(k) * v).sum::<f64>() + 0.05 * UNDRAWN;
    let exp_assets = total(&a) + 0.40 * UNDRAWN;
    let exp_funding = tot + 0.40 * UNDRAWN;               // road 2 for the exposure: the funding side
    let t1 = g(&f, "equity");
    let x_closed = (t1 - 0.03 * exp_assets) / 0.97;
    let x_bisect = bisect(|x| (t1 - x) / (exp_assets - x) - 0.03, 0.0, t1);
    let s_a = scen(&[], &[("bonds", -200.0), ("interbank", 200.0)]);
    let s_b = scen(&[("mortgage", 400.0)], &[("interbank_90", 400.0)]);
    let s_c = scen(&[("gov", 500.0)], &[("bonds", 500.0)]);

    let (l1, l2a, l2b) = (g(&a, "cash") + g(&a, "gov"), 0.85 * g(&a, "l2a"), 0.50 * g(&a, "l2b"));
    row("HQLA: level 1, level 2A, level 2B", &[l1, l2a, l2b], 2);
    row("HQLA, cap formula / cap search", &[h, hqla_search(l1, l2a, l2b, 0.05)], 2);
    let a15 = (60.0_f64 - 15.0 / 85.0 * 200.0).max(60.0 - 15.0 / 60.0 * 100.0).max(0.0);
    row("caps bite (100, 100, 60): cuts", &[a15, (160.0_f64 - a15 - 200.0 / 3.0).max(0.0)], 2);
    row("caps bite (100, 100, 60): formula", &[hqla(100.0, 100.0, 60.0), hqla_search(100.0, 100.0, 60.0, 0.05)], 2);
    for (k, name) in [("interbank", "interbank"), ("corporate", "corporate"), ("less_stable", "less stable retail"), ("stable", "stable retail")] {
        row(&format!("  30-day outflow, {}", name), &[runoff(k) * g(&f, k)], 2);
    }
    row("  30-day outflow, credit lines", &[0.10 * UNDRAWN], 2);
    row("outflows, inflows, net", &[out, inflow, out - inflow.min(0.75 * out)], 2);
    row("LCR % formula / day-by-day", &[100.0 * lcr, 100.0 * lcr_sim], 2);
    println!("stress day      {}", (0..=30).step_by(5).map(|d| format!("{:9}", d)).collect::<String>());
    println!("stock, 1.0x run {}", (0..=30).step_by(5).map(|d| format!("{:9.2}", path[d])).collect::<String>());
    println!("stock, 1.5x run {}", (0..=30).step_by(5).map(|d| format!("{:9.2}", hard[d])).collect::<String>());
    let (lo_day, lo) = path.iter().enumerate().fold((0, f64::MAX), |b, (d, s)| if *s < b.1 { (d, *s) } else { b });
    println!("{:<42}{:9.2}{:9}", "lowest stock, day", lo, lo_day);
    row("largest run: day 30 x2, every day x2", &[lam_closed, lam_bisect, lam_day, lam_day_b], 4);
    println!("{:<42}{:9.2}{:9.2}{:9}", "1.5x run: stock day 29, 30; dry day", hard[29], hard[30], dry_day);
    row("ASF: long-term, stable, less, corporate", &[g(&f, "equity") + g(&f, "bonds"), 0.95 * g(&f, "stable"),
        0.90 * g(&f, "less_stable"), 0.50 * g(&f, "corporate")], 2);
    row("RSF: liquid, mortgage, corp, rest, lines", &[0.05 * g(&a, "gov") + 0.15 * g(&a, "l2a") + 0.5 * g(&a, "l2b"),
        0.65 * g(&a, "mortgage"), 0.5 * g(&a, "corp_short") + 0.85 * g(&a, "corp_long"),
        0.85 * g(&a, "trading") + g(&a, "other"), 0.05 * UNDRAWN], 2);
    row("ASF, RSF", &[asf, rsf], 2);
    row("NSFR % by factors / by identity", &[100.0 * nsfr, 100.0 * nsfr2], 2);
    row("exposure: on balance sheet, credit lines", &[total(&a), 0.40 * UNDRAWN], 2);
    row("exposure: asset side / funding side", &[exp_assets, exp_funding], 2);
    row("leverage %, CET1 % on RWA 500", &[100.0 * lev, 100.0 * t1 / RWA], 2);
    row("assets per dollar of Tier 1", &[exp_assets / t1], 2);
    row("loss that breaches 3%, closed / bisect", &[x_closed, x_bisect], 2);
    println!("scenario: LCR %, NSFR %, leverage %");
    for (name, s) in [("A, 1-week money", s_a), ("B, 90-day mortgages", s_b), ("C, bonds for bonds", s_c)] {
        row(&format!("  {}", name), &[100.0 * s.3, 100.0 * s.4, 100.0 * s.5], 2);
    }
    row("wrong: no haircuts on level 2", &[100.0 * (l1 + g(&a, "l2a") + g(&a, "l2b")) / (out - inflow)], 2);
    row("wrong: loan inflows at 100%", &[100.0 * h / (out - LOAN_DUE)], 2);
    row("wrong: credit lines left out of lev.", &[100.0 * t1 / total(&a)], 2);
    row("wrong: 90-day money as 50% ASF (B)", &[100.0 * scen(&[("mortgage", 400.0)], &[("corporate", 400.0)]).4], 2);
    let t_a = scen(&[], &[("less_stable", -100.0), ("stable", 100.0)]);
    let t_b = scen(&[("trading", -100.0), ("gov", 100.0)], &[]);
    let t_c = scen(&[("other", -15.0)], &[("equity", -15.0)]);
    row("try: 100 made stable, LCR NSFR %", &[100.0 * t_a.3, 100.0 * t_a.4], 2);
    row("try: trading into gov, LCR NSFR lev %", &[100.0 * t_b.3, 100.0 * t_b.4, 100.0 * t_b.5], 2);
    row("try: 15 lost, leverage %", &[100.0 * t_c.5], 2);

    assert!((total(&a) - tot).abs() < 1e-9, "balance sheet must balance");
    assert!((lcr - lcr_sim).abs() < 1e-9, "LCR formula vs the day-by-day stress");
    assert!((lam_closed - lam_bisect).abs() < 1e-9, "largest run passing day 30: closed form vs bisection");
    assert!((lam_day - lam_day_b).abs() < 1e-9 && lam_day < lam_closed, "every-day survival: closed vs bisection");
    assert!((hqla(100.0, 100.0, 60.0) - hqla_search(100.0, 100.0, 60.0, 0.05)).abs() < 0.06, "cap formula vs search");
    assert!((nsfr - nsfr2).abs() < 1e-12, "NSFR: factor sums vs the balance-sheet identity");
    assert!((x_closed - x_bisect).abs() < 1e-9, "breach loss: closed form vs bisection");
    for (s, i) in [(s_a, 3), (s_b, 4), (s_c, 5)] { assert!([s.3 < 1.0, s.4 < 1.0, s.5 < 0.03] == [i == 3, i == 4, i == 5], "each change fails only its own rule"); }
    println!("ALL CHECKS PASS");
}
