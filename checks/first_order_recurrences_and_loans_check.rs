// First-order recurrences and loans -- the same check as the Python, in Rust.
// No crates.  A $20,000 car loan at 0.5% a month over 48 months, with balance
// B(n) = 1.005 B(n-1) - P, reached twice: by stepping, and by the closed form.
const B0: f64 = 20000.0;
const RATE: f64 = 0.005;
const N: usize = 48;
const R: f64 = 1.0 + RATE;                  // the monthly growth factor

fn power(x: f64, k: usize) -> f64 {         // x multiplied in k times
    let mut out = 1.0;
    for _ in 0..k { out = out * x }
    out
}

fn step(start: f64, pay: f64, months: usize) -> Vec<f64> {   // road one: a month at a time
    let mut path = vec![start];
    for _ in 0..months { path.push(path[path.len() - 1] * R - pay) }
    path
}

fn closed(start: f64, pay: f64, n: usize) -> f64 {     // road two: shift to the fixed point
    let anchor = -pay / (1.0 - R);          // c / (1 - r), here with c = -pay
    power(R, n) * (start - anchor) + anchor
}

fn level_payment(rate: f64, n: usize) -> f64 {         // the closed-form level repayment
    let g = power(1.0 + rate, n);
    B0 * rate * g / (g - 1.0)
}

fn bisect_payment(n: usize) -> f64 {        // road three: bisection on the stepping
    let (mut lo, mut hi) = (0.0, 2000.0);
    for _ in 0..200 {
        let mid = (lo + hi) / 2.0;
        if step(B0, mid, n)[n] > 0.0 { lo = mid } else { hi = mid }
    }
    (lo + hi) / 2.0
}

fn cash(v: f64) -> String {                 // a residue under half a cent reads 0.00
    format!("{:.2}", if v.abs() < 0.005 { 0.0 } else { v })
}

fn row(name: &str, cells: Vec<String>) -> String {
    let mut line = String::from(name);
    for c in cells { line.push_str(&format!("{:>9}", c)) }
    line
}

fn main() {
    let (p, guess) = (level_payment(RATE, N), bisect_payment(N));
    let (path, anchor) = (step(B0, p, N), p / RATE);
    let marks: Vec<usize> = (0..=N).step_by(6).collect();
    let mut save = vec![0.0];
    for _ in 0..N { save.push(save[save.len() - 1] * R + p) }   // the same rule, payment added
    let split: Vec<f64> = [1, 12, 24, 36, 48].iter().map(|&m: &usize| path[m - 1] * RATE).collect();
    println!("loan {} at {:.1}% a month over {} months; growth factor {}; {} multiplies give {:.6}", cash(B0), RATE * 100.0, N, R, N, power(R, N));
    println!("level payment: closed form {:.4}, bisection on the stepping {:.4}", p, guess);
    println!("the anchor, payment / rate: {} -- the balance this payment holds still", cash(anchor));
    println!("{}", row("month        ", marks.iter().map(|m| m.to_string()).collect()));
    println!("{}", row("balance      ", marks.iter().map(|&m| cash(path[m])).collect()));
    println!("{}", row("closed form  ", marks.iter().map(|&m| cash(closed(B0, p, m))).collect()));
    println!("{}", row("straight line", marks.iter().map(|&m| cash(B0 * (1.0 - m as f64 / N as f64))).collect()));
    println!("month 1: interest {}, principal {}, balance {}", cash(split[0]), cash(p - split[0]), cash(path[1]));
    println!("month 2: interest {}, principal {}, balance {}", cash(path[1] * RATE), cash(p - path[1] * RATE), cash(path[2]));
    let join = |g: &dyn Fn(f64) -> f64| split.iter().map(|&i| cash(g(i))).collect::<Vec<String>>().join(", ");
    println!("interest  inside the payment at months 1, 12, 24, 36, 48: {}", join(&|i| i));
    println!("principal inside the payment at months 1, 12, 24, 36, 48: {}", join(&|i| p - i));
    println!("paid in all {}; interest {}; last balance {}", cash(N as f64 * p), cash(N as f64 * p - B0), cash(path[N]));
    println!("the same payment saved reaches {}; the loan left unpaid grows to {}", cash(save[N]), cash(B0 * power(R, N)));
    println!("mistake 1, {} a month and no interest: {} still owing", cash(B0 / N as f64), cash(step(B0, B0 / N as f64, N)[N]));
    println!("mistake 2, 6% a year read as 6% a month: payment {}", cash(level_payment(0.06, N)));
    println!("mistake 3, payment rounded down to 469.00: {} still owing", cash(step(B0, 469.0, N)[N]));
    let worst = (0..=N).map(|m| (path[m] - closed(B0, p, m)).abs()).fold(0.0f64, f64::max);
    assert!(worst < 1e-9);                                      // stepping vs closed form
    assert!((guess - p).abs() < 1e-6 && path[N].abs() < 1e-6);   // root hunt vs formula
    assert!((save[N] - B0 * power(R, N)).abs() < 1e-6);          // saved vs principal grown
    assert!((p * 100.0).round() as i64 == 46970 && (anchor * 100.0).round() as i64 == 9394012);
    println!("ALL CHECKS PASS");
}
