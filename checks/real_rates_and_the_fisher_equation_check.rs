// Real rates and the Fisher equation -- the same check as the Python, in Rust.
// Standard library only, no crates.  The real rate is reached four ways:
// dividing growth factors, counting baskets, a bisection root finder that
// never divides, and log rates.
// Compile: rustc --edition 2021 -O real_rates_and_the_fisher_equation_check.rs

const I: f64 = 0.045; // nominal rate, one year
const PI: f64 = 0.025; // inflation, one year
const DEPOSIT: f64 = 1000.0; // dollars deposited
const BASKET: f64 = 100.0; // a basket's price today

fn real(i: f64, p: f64) -> f64 { (1.0 + i) / (1.0 + p) - 1.0 } // road 1: exact Fisher

fn by_baskets(i: f64, p: f64) -> (f64, f64, f64) { // road 2: count what the money buys
    let before = DEPOSIT / BASKET;
    let after = DEPOSIT * (1.0 + i) / (BASKET * (1.0 + p));
    (before, after, after / before - 1.0)
}

fn by_bisection(i: f64, p: f64) -> f64 { // road 3: (1 + r)(1 + p) = 1 + i, no division
    let (mut lo, mut hi) = (-0.99_f64, 1.0_f64);
    for _ in 0..200 {
        let mid = 0.5 * (lo + hi);
        if (1.0 + mid) * (1.0 + p) - (1.0 + i) > 0.0 { hi = mid; } else { lo = mid; }
    }
    0.5 * (lo + hi)
}

fn by_logs(i: f64, p: f64) -> (f64, f64, f64, f64) { // road 4: continuous rates subtract
    let (ic, pc) = ((1.0 + i).ln(), (1.0 + p).ln());
    (ic, pc, ic - pc, (ic - pc).exp() - 1.0)
}

fn main() {
    let r = real(I, PI);
    let (b0, b1, r_b) = by_baskets(I, PI);
    let r_bis = by_bisection(I, PI);
    let (ic, pc, rc, r_log) = by_logs(I, PI);
    let approx = I - PI;
    let gap_formula = (I - PI) * PI / (1.0 + PI); // the approximation's error, independently

    let rows: Vec<(&str, f64)> = vec![
        ("baskets bought today", b0), ("basket price in a year", BASKET * (1.0 + PI)),
        ("dollars in a year", DEPOSIT * (1.0 + I)), ("baskets bought in a year", b1),
        ("1 exact (1+i)/(1+pi) - 1", r), ("2 baskets after/before - 1", r_b),
        ("3 bisection, no division", r_bis),
        ("4a continuous nominal ln(1+i)", ic), ("4b continuous inflation ln(1+pi)", pc),
        ("4c continuous real, the difference", rc), ("4  back to yearly, e^diff - 1", r_log),
        ("approximation i - pi", approx), ("approximation minus exact", approx - r),
        ("  (i - pi) pi / (1 + pi)", gap_formula),
    ];
    for (name, v) in &rows { println!("{:<38} {:>13.9}", name, v); }

    // ---- ten years: the deposit in dollars and in today's dollars ----
    println!();
    println!("year   dollars  today's-dollars  approx-2%");
    let (mut grow, mut prices, mut money, mut approx_path) = (1.0_f64, 1.0_f64, DEPOSIT, DEPOSIT);
    for year in 0..11 {
        if year > 0 {
            money *= 1.0 + I; prices *= 1.0 + PI; approx_path *= 1.0 + approx; grow *= 1.0 + r;
        }
        if year % 2 == 0 {
            println!("{:>4} {:>9.2} {:>16.2} {:>10.2}", year, money, money / prices, approx_path);
        }
    }
    let baskets10 = money / (BASKET * prices);
    println!("{:<38} {:>13.6}", "baskets after ten years", baskets10);
    println!("{:<38} {:>13.6}", "price index after ten years", prices);

    // ---- the same 2-point gap as inflation rises: exact against approximate ----
    println!();
    println!("inflation%  nominal%  exact-real%  approx-real%");
    for p in [0.0_f64, 0.025, 0.05, 0.10, 0.20, 0.50, 1.00] {
        println!("{:>10.1} {:>9.1} {:>12.2} {:>13.2}", 100.0 * p, 100.0 * (p + 0.02),
                 100.0 * real(p + 0.02, p), 100.0 * 0.02);
    }

    // ---- nominal locked at 4.5 percent; the inflation that actually arrived ----
    println!();
    println!("realised inflation%  realised real%");
    for p in [0.0_f64, 0.01, 0.02, 0.025, 0.03, 0.04, 0.05] {
        println!("{:>19.1} {:>15.2}", 100.0 * p, 100.0 * real(I, p));
    }

    // ---- what breaks, taxes, the shelf's bond, try changing ----
    println!();
    let t = 0.30;
    let extra: Vec<(&str, f64)> = vec![
        ("wrong: multiply, (1+i)(1+pi) - 1", (1.0 + I) * (1.0 + PI) - 1.0),
        ("wrong: approx, 110% nominal 100% infl", 1.10 - 1.00),
        ("  exact, 110% nominal 100% inflation", real(1.10, 1.00)),
        ("wrong: approx compounded, baskets", DEPOSIT * (1.0 + approx).powi(10) / BASKET),
        ("tax 30%: nominal after tax", I * (1.0 - t)),
        ("tax 30%: real after tax", real(I * (1.0 - t), PI)),
        ("wrong: tax charged on the real rate", r * (1.0 - t)),
        ("shelf bond: real 1%, breakeven 2.5%", 1.01 * 1.025 - 1.0),
        ("try: inflation 4.5%", real(I, 0.045)),
        ("try: inflation 10%", real(I, 0.10)),
        ("try: nominal 10%", real(0.10, PI)),
    ];
    for (name, v) in &extra { println!("{:<38} {:>13.9}", name, v); }

    assert!((r_bis - r).abs() < 1e-12, "bisection (no division) must land on the ratio");
    assert!((r_log - r).abs() < 1e-12, "log road must land on the ratio");
    assert!((r_b - r).abs() < 1e-12, "basket count must land on the ratio");
    assert!(((approx - r) - gap_formula).abs() < 1e-15, "approximation error is (i - pi) pi / (1 + pi)");
    assert!((baskets10 - 10.0 * grow).abs() < 1e-9, "ten years of baskets vs real growth compounded");
    assert!((r - 2.0 / 102.5).abs() < 1e-15, "hand value: 2 dollars gained on a 102.50 basket");
    assert!(((approx - r) - r * PI).abs() < 1e-15, "the dropped term is exactly r times pi");
    assert!((real(1.01 * 1.025 - 1.0, 0.025) - 0.01).abs() < 1e-15, "shelf bond: back to 1 percent real");
    assert!((real(1.10, 1.00) - (1.10 - 1.00) / 2.0).abs() < 1e-15, "100% inflation: exact is half the shortcut");
    println!("ALL CHECKS PASS");
}
