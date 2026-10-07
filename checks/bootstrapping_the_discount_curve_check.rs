// Bootstrapping the discount curve -- the same check as the Python, in Rust.  No crates.
// Six quotes from one morning, two deposits and four par swaps, become six discount
// factors by three independent roads; the finished curve is then made to reprice every
// quote it was built from, out of the cash flows the contracts actually pay.  A curve is
// six numbers: slot 0 is the 0.5-year pillar and slot j the j-year pillar.
const DEPOSITS: [(f64, f64); 2] = [(0.5, 0.0400), (1.0, 0.0420)];   // (years, simple rate)
const SWAPS: [(usize, f64); 4] = [(2, 0.0440), (3, 0.0455), (4, 0.0462), (5, 0.0465)];
const DATES: [f64; 6] = [0.5, 1.0, 2.0, 3.0, 4.0, 5.0];             // the six pillar dates
const PAIRS: [(f64, f64); 6] = [(0.0, 0.5), (0.5, 1.0), (1.0, 2.0), (2.0, 3.0), (3.0, 4.0), (4.0, 5.0)];
const LOAN: f64 = 10_000_000.0;                                     // a round notional

fn money(x: f64) -> String {                  // Python's {:,.2f}: thousands, two decimals
    let s = format!("{:.2}", x);
    let (int, dec) = s.split_once('.').unwrap();
    let mut out = String::new();
    for (i, c) in int.chars().enumerate() {
        if i > 0 && (int.len() - i) % 3 == 0 { out.push(',') } out.push(c);
    }
    format!("{}.{}", out, dec)
}
fn g(x: f64) -> String {                      // Python's {:g} on these numbers: 0.5, 1, 2
    if x.fract() == 0.0 { format!("{}", x as i64) } else { format!("{}", x) }
}
fn slot(t: f64) -> usize { DATES.iter().position(|&x| x == t).unwrap() }
fn zero(d: &[f64; 6], t: f64) -> f64 { -d[slot(t)].ln() / t }       // continuous zero rate
fn fwd(d: &[f64; 6], a: f64, b: f64) -> f64 {
    (if a > 0.0 { (d[slot(a)] / d[slot(b)]).ln() } else { -d[slot(b)].ln() }) / (b - a)
}
fn loan(d: &[f64; 6], s: f64, n: usize) -> f64 {
    LOAN * ((1..n + 1).map(|j| s * d[j]).sum::<f64>() + d[n])
}
fn deposits_only() -> [f64; 6] {
    let mut d = [0.0_f64; 6];
    for (i, &(t, r)) in DEPOSITS.iter().enumerate() { d[i] = 1.0 / (1.0 + t * r) }
    d
}

fn ladder(swaps: &[(usize, f64); 4]) -> [f64; 6] {     // road 1: one maturity at a time
    let mut d = deposits_only();
    for &(n, s) in swaps {
        let b: f64 = (1..n).map(|j| d[j]).sum();       // the earlier coupons, funded
        d[n] = (1.0 - s * b) / (1.0 + s);
    }
    d
}

fn by_elimination() -> [f64; 6] {             // road 2: all six equations at once
    let mut rows: Vec<[f64; 7]> = Vec::new();
    for &(n, s) in SWAPS.iter().rev() {       // longest first: pivoting must do real work
        let mut row = [0.0_f64; 7];
        for j in 1..n + 1 { row[j] = s + if j == n { 1.0 } else { 0.0 } }
        row[6] = 1.0; rows.push(row);
    }
    for (i, &(t, r)) in DEPOSITS.iter().enumerate().rev() {
        let mut row = [0.0_f64; 7];
        row[i] = 1.0 + t * r;
        row[6] = 1.0; rows.push(row);
    }
    let n = rows.len();
    for c in 0..n {                           // Gaussian elimination, partial pivoting
        let mut p = c;
        for i in c..n { if rows[i][c].abs() > rows[p][c].abs() { p = i } }
        rows.swap(c, p);
        for i in c + 1..n {
            let f = rows[i][c] / rows[c][c];
            for j in c..n + 1 { rows[i][j] -= f * rows[c][j] }
        }
    }
    let mut x = [0.0_f64; 6];
    for i in (0..n).rev() {
        let mut acc = rows[i][n];
        for j in i + 1..n { acc -= rows[i][j] * x[j] }
        x[i] = acc / rows[i][i];
    }
    x
}

fn legs(d: &[f64; 6], n: usize, s: f64) -> (f64, f64) {   // what the swap actually pays
    let (mut floating, mut fixed, mut prev) = (0.0_f64, 0.0_f64, 1.0_f64);
    for j in 1..n + 1 {
        floating += (prev / d[j] - 1.0) * d[j];  // this year's forward rate, times this year
        fixed += s * d[j];
        prev = d[j];
    }
    (floating, fixed)
}

fn by_bisection() -> [f64; 6] {               // road 3: hunt each pillar numerically
    let mut d = deposits_only();
    for &(n, s) in SWAPS.iter() {
        let (mut lo, mut hi) = (1e-9_f64, 1.0_f64);
        for _ in 0..200 {
            let mid = 0.5 * (lo + hi);
            d[n] = mid;
            if legs(&d, n, s).0 - legs(&d, n, s).1 > 0.0 { lo = mid } else { hi = mid }
        }
        d[n] = 0.5 * (lo + hi);
    }
    d
}

fn main() {
    let (d, e, z) = (ladder(&SWAPS), by_elimination(), by_bisection());
    let gap_e = (0..6).map(|i| (d[i] - e[i]).abs()).fold(0.0_f64, f64::max);
    let gap_z = (0..6).map(|i| (d[i] - z[i]).abs()).fold(0.0_f64, f64::max);
    println!("Six quotes on one morning; accruals 0.5 and 1.0 exactly, one year per swap coupon");
    println!("{:<13}{:>8}{:>6}{:>11}{:>13}{:>13}{:>13}", "quote", "rate %", "T", "B_n", "1 - S_n B_n", "1 + a_n S_n", "D(T)");
    for (i, &(t, r)) in DEPOSITS.iter().enumerate() {
        println!("{:<13}{:>8.4}{:>6.1}{:>11.6}{:>13.6}{:>13.6}{:>13.8}", format!("deposit {}y", g(t)), 100.0 * r, t, 0.0, 1.0, 1.0 + t * r, d[i]);
    }
    for &(n, s) in SWAPS.iter() {
        let b: f64 = (1..n).map(|j| d[j]).sum();
        println!("{:<13}{:>8.4}{:>6.1}{:>11.6}{:>13.6}{:>13.6}{:>13.8}", format!("par swap {}y", n), 100.0 * s, n as f64, b, 1.0 - s * b, 1.0 + s, d[n]);
    }
    println!("\n{:>5}{:>13}{:>15}{:>13}{:>16}", "T", "D(T)", "$100 due then", "zero rate %", "forward rate %");
    for &(a, b) in PAIRS.iter() {
        println!("{:>5.1}{:>13.8}{:>15.2}{:>13.4}{:>16.4}", b, d[slot(b)], 100.0 * d[slot(b)], 100.0 * zero(&d, b), 100.0 * fwd(&d, a, b));
    }
    println!("\nroad 2, elimination on the 6 by 6 system, rows fed longest first: largest gap {:.12}", gap_e);
    println!("road 3, bisection against the legs the swaps actually pay: largest gap {:.12}", gap_z);
    let worst_dep = DEPOSITS.iter().map(|&(t, r)| ((1.0 + t * r) * d[slot(t)] - 1.0).abs()).fold(0.0_f64, f64::max);
    let worst_par = SWAPS.iter().map(|&(n, s)| (legs(&d, n, s).0 / (1..n + 1).map(|j| d[j]).sum::<f64>() - s).abs()).fold(0.0_f64, f64::max);
    let worst_val = SWAPS.iter().map(|&(n, s)| (LOAN * (legs(&d, n, s).0 - legs(&d, n, s).1)).abs()).fold(0.0_f64, f64::max);
    println!("road 4, reprice: deposits come back to within {:.12} of a dollar per dollar lent, par rates to within {:.12},", worst_dep, worst_par);
    println!("         and every input swap values at zero: the worst is ${:.6} on $10,000,000", worst_val);
    let b5: f64 = (1..5).map(|j| d[j]).sum();
    println!("\nthe 5-year rung: B_5 = {:.6}, so a positive D(5) needs a 5-year quote between {:.2}% and {:.2}%", b5, -100.0, 100.0 / b5);
    println!("at {:.2}% the rung returns D(5) = {:.2}; at {:.2}% it reads 0 x D(5) = {:.6}, which no number solves", 100.0 / b5, 0.0, -100.0, 1.0 + b5);
    let names = ["par rate read as a zero rate", "earlier coupons forgotten", "simple interest for n years"];
    let wrong: Vec<[f64; 6]> = (0..3).map(|rule| {
        let mut c = d;                        // the deposits stay right on every wrong curve
        for &(n, s) in SWAPS.iter() {
            c[n] = match rule { 0 => 1.0 / (1.0 + s).powf(n as f64), 1 => 1.0 / (1.0 + s), _ => 1.0 / (1.0 + n as f64 * s) };
        }
        c
    }).collect();
    println!("\n{:<34}{:>13}{:>48}{:>13}", "the 5-year pillar, built this way", "D(5)", "a $10,000,000 5-year loan at 4.6500% prices at", "off by");
    println!("{:<34}{:>13.8}{:>48}{:>13}", "bootstrapped, the right answer", d[5], money(loan(&d, 0.0465, 5)), money(loan(&d, 0.0465, 5) - LOAN));
    for (name, c) in names.iter().zip(wrong.iter()) {
        println!("{:<34}{:>13.8}{:>48}{:>13}", name, c[5], money(loan(c, 0.0465, 5)), money(loan(c, 0.0465, 5) - LOAN));
    }
    let mut quotes = SWAPS;
    for q in quotes.iter_mut() { if q.0 == 3 { q.1 += 0.0001 } }
    let bumped = ladder(&quotes);
    println!("\nthe 3-year quote ticks up one basis point; every other quote on the screen holds still");
    println!("  pillar zero rates move, in basis points: {}", DATES.iter()
        .map(|&t| format!("{}y {:+.4}", g(t), 10000.0 * (zero(&bumped, t) - zero(&d, t)))).collect::<Vec<String>>().join(", "));
    println!("  forward rates move, in basis points:     {}", PAIRS[3..].iter()
        .map(|&(a, b)| format!("{}y-{}y {:+.4}", g(a), g(b), 10000.0 * (fwd(&bumped, a, b) - fwd(&d, a, b)))).collect::<Vec<String>>().join(", "));
    let alt4 = d[3];                          // a flat guess where the 4-year quote should be
    let alt5 = (1.0 - 0.0465 * (d[1] + d[2] + d[3] + alt4)) / 1.0465;
    println!("\ndrop the 4-year quote and the 5-year swap holds two unknowns: D(4) = {:.8} with D(5) = {:.8} reprices it", d[4], d[5]);
    println!("and so does D(4) = {:.8} with D(5) = {:.8}", alt4, alt5);
    println!("the 4y-5y forward rate is {:.4}% on the first pair, {:.4}% on the second", 100.0 * fwd(&d, 4.0, 5.0), 100.0 * (alt4 / alt5).ln());
    let cells = |vals: Vec<f64>, dp: usize| vals.iter()
        .map(|v| if dp == 1 { format!("{:>8.1}", v) } else { format!("{:>8.2}", v) }).collect::<Vec<String>>().join("");
    println!("\n{:<26}{}", "chart, T", cells(DATES.to_vec(), 1));
    println!("{:<26}{}", "chart, $100 due at T", cells(DATES.iter().map(|&t| 100.0 * d[slot(t)]).collect(), 2));
    assert!(gap_e < 1e-12, "the ladder and the 6 by 6 solve must land on the same six numbers");
    assert!(gap_z < 1e-9, "the ladder and the numerical hunt must land on the same six numbers");
    assert!(worst_par < 1e-12, "the curve must hand back every par rate it was built from");
    assert!(worst_val < 1e-6, "every input swap must value at zero on its own curve");
    assert!((0..5).all(|i| d[slot(DATES[i])] > d[slot(DATES[i + 1])]), "discount factors must fall with time");
    assert!(PAIRS[1..].iter().all(|&(a, b)| fwd(&d, a, b) > zero(&d, b)), "forwards sit above zeros on a rising curve");
    assert!((loan(&wrong[0], 0.0465, 5) - LOAN).abs() > 1000.0, "the mistake costs real money");
    println!("ALL CHECKS PASS");
}
