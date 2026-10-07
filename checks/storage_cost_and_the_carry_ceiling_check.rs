// Storage and the carry ceiling -- the same check as the Python, in Rust.  Std only, no crates.
// Wheat at 6.00 a bushel, a 0.30 warehouse bill paid today, 5% a year, one year.
// Road 1 is the formula.  Road 2 grows the cash-and-carry loan in 200,000 slices of
// simple interest.  Road 3 pays storage in kind, a sliver of grain per slice.  Road 4
// simulates delivery-day wheat prices and repays the loan from a home-made e^x series.
use std::f64::consts::PI;

fn exp_series(x: f64) -> f64 {              // e^x from its Taylor series, no library
    let (mut term, mut total, mut k) = (1.0_f64, 1.0_f64, 0.0_f64);
    while term.abs() > 1e-18 { k += 1.0; term *= x / k; total += term; }
    total
}

fn ceiling(s: f64, u: f64, r: f64, t: f64) -> f64 { (s + u) * (r * t).exp() }   // road 1

fn loan_by_slices(amount: f64, r: f64, t: f64, n: usize) -> f64 {              // road 2
    let (mut bal, dt) = (amount, t / n as f64);
    for _ in 0..n { bal *= 1.0 + r * dt; }
    bal
}

fn forward_in_kind(s: f64, u: f64, r: f64, t: f64, n: usize) -> f64 {           // road 3
    let (mut left, dt) = (1.0_f64, t / n as f64);
    for _ in 0..n { left *= 1.0 - u * dt; }
    let bushels = 1.0 / left;               // buy this many today so one is left at delivery
    loan_by_slices(bushels * s, r, t, n)
}

struct Rng { state: u64 }
impl Rng {
    fn uniform(&mut self) -> f64 {          // 64-bit linear congruential generator
        self.state = self.state.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
        ((self.state >> 11) as f64 + 0.5) / 9007199254740992.0
    }
    fn normal(&mut self) -> f64 {           // Box-Muller
        let a = self.uniform();
        let b = self.uniform();
        (-2.0 * a.ln()).sqrt() * (2.0 * PI * b).cos()
    }
}

fn main() {
    let (s, u_bill, r, t, n) = (6.00_f64, 0.30_f64, 0.05_f64, 1.0_f64, 200000_usize);
    let (f_hi, f_lo, sigma, paths) = (6.80_f64, 6.00_f64, 0.25_f64, 20000);
    let c1 = ceiling(s, u_bill, r, t);
    let c2 = loan_by_slices(s + u_bill, r, t, n);
    let u = ((s + u_bill) / s).ln();        // the storage rate that matches a 0.30 bill
    let c3_formula = s * ((r + u) * t).exp();
    let c3_kind = forward_in_kind(s, u, r, t, n);
    let loan = (s + u_bill) * exp_series(r * t);

    let mut rng = Rng { state: 20260927 };
    let (mut hi_min, mut hi_max) = (f64::INFINITY, f64::NEG_INFINITY);
    let (mut lo_min, mut lo_max) = (f64::INFINITY, f64::NEG_INFINITY);
    for _ in 0..paths {
        let st = s * (-0.5 * sigma * sigma * t + sigma * t.sqrt() * rng.normal()).exp();
        let p_hi = st + (f_hi - st) - loan; // sell the stored grain, settle the short forward
        let p_lo = st - f_lo;               // a grain-less buyer of the 6.00 forward
        hi_min = hi_min.min(p_hi); hi_max = hi_max.max(p_hi);
        lo_min = lo_min.min(p_lo); lo_max = lo_max.max(p_lo);
    }

    let rows: Vec<(&str, f64)> = vec![
        ("interest factor e^rT", (r * t).exp()),
        ("storage bill grown, U e^rT", u_bill * (r * t).exp()),
        ("interest on 6.30, (S+U)(e^rT - 1)", (s + u_bill) * ((r * t).exp() - 1.0)),
        ("1 ceiling (S+U) e^rT", c1),
        ("2 loan run in 200000 slices", c2),
        ("  storage rate u = ln(6.30/6.00)", u),
        ("3 S e^(r+u)T", c3_formula),
        ("  in kind, 200000 slices", c3_kind),
        ("carry profit at 6.80, formula", f_hi - c1),
        ("4 sim: carry profit at 6.80, min", hi_min),
        ("  sim: carry profit at 6.80, max", hi_max),
        ("  sim: long 6.00 forward, min", lo_min),
        ("  sim: long 6.00 forward, max", lo_max),
        ("short sale gain at 6.00, S e^rT - F", s * (r * t).exp() - f_lo),
        ("holder's gain at 6.00, ceiling - F", c1 - f_lo),
        ("wrong: no storage, S e^rT", s * (r * t).exp()),
        ("wrong: bill not financed", s * (r * t).exp() + u_bill),
        ("wrong: u read as 5%", s * ((r + 0.05) * t).exp()),
        ("wrong: simple interest", (s + u_bill) * (1.0 + r * t)),
        ("try: r = 10%", ceiling(s, u_bill, 0.10, t)),
        ("try: storage 0.60", ceiling(s, 0.60, r, t)),
        ("try: 6 months, bill 0.15", ceiling(s, 0.15, r, 0.5)),
        ("try: wheat 4.00, bill 0.30", ceiling(4.00, u_bill, r, t)),
    ];
    for (name, v) in &rows { println!("{:<36} {:>12.6}", name, v); }
    println!();
    let months = [0u32, 3, 6, 9, 12];
    let m_row: Vec<String> = months.iter().map(|m| format!("{:6}", m)).collect();
    let c_row: Vec<String> = months.iter()
        .map(|&m| format!("{:6.2}", ceiling(s, u_bill * m as f64 / 12.0, r, m as f64 / 12.0))).collect();
    let s_row: Vec<String> = months.iter().map(|_| format!("{:6.2}", s)).collect();
    println!("chart, months      {}", m_row.join(" "));
    println!("chart, ceiling     {}", c_row.join(" "));
    println!("chart, spot        {}", s_row.join(" "));

    assert!((c1 - 6.623007907169).abs() < 1e-9, "formula vs the hand value 6.30 x 1.0512711");
    assert!((c2 - c1).abs() < 1e-6, "sliced loan must land on the formula");
    assert!((c3_kind - c3_formula).abs() < 1e-6, "storage in kind must land on S e^(r+u)T");
    assert!((hi_min - (f_hi - c1)).abs() < 1e-9, "carry profit is the same on every path");
    assert!((hi_max - (f_hi - c1)).abs() < 1e-9, "...best path included");
    assert!(lo_min < 0.0 && 0.0 < lo_max, "a forward below the ceiling offers no sure trade");
    println!("ALL CHECKS PASS");
}
