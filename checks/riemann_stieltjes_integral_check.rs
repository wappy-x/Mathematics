// Stieltjes integrals -- the same check as the Python, in Rust, std only.
// A book of 1,000 contracts: 400 pay $0, 500 pay amounts spread evenly over
// $0 to $100, and 100 pay the $100 cap.  G(x) is the share paying at most x.
// The average payout is the integral of x against G, reached by four roads.
const A: f64 = -20.0;
const B: f64 = 100.0;

fn g(x: f64) -> f64 {
    // the accumulator: right-continuous, lump 0.4 at zero, lump 0.1 at the cap
    if x < 0.0 { 0.0 } else if x < 100.0 { 0.4 + 0.005 * x } else { 1.0 }
}

fn pay(x: f64) -> f64 { x }

fn fee(x: f64) -> f64 { if x > 0.0 { 1.0 } else { 0.0 } } // $1 if it pays something

fn rs_sum(f: fn(f64) -> f64, n: usize, tag: f64) -> f64 {
    // Stieltjes sum on n equal slices of [A, B], tag 0 = left end, 1 = right end
    let h = (B - A) / n as f64;
    (0..n).map(|k| {
        let (l, r) = (A + k as f64 * h, A + (k + 1) as f64 * h);
        f(A + (k as f64 + tag) * h) * (g(r) - g(l))
    }).sum()
}

fn main() {
    let mut book = vec![0.0f64; 400];
    book.extend((0..500).map(|k| (k as f64 + 0.5) * 0.2));
    book.extend(vec![100.0f64; 100]);
    let paying = book.iter().filter(|&&p| p > 0.0).count();
    let smooth = 0.005 * 100.0f64.powi(2) / 2.0; // road 1: antiderivative of x times G'
    let jumps = 0.4 * pay(0.0) + 0.1 * pay(100.0); // road 1: each lump times its payout
    let split = smooth + jumps;
    let total: f64 = book.iter().sum();
    let by_hand = total / book.len() as f64; // road 3: contract by contract
    let m = 100000;
    let tail: f64 = (0..m).map(|k| 1.0 - g((k as f64 + 0.5) * 100.0 / m as f64)).sum::<f64>() * 100.0 / m as f64;
    let pts = [-20.0, -10.0, -1e-9, 0.0, 20.0, 40.0, 60.0, 80.0, 100.0 - 1e-9, 100.0];
    let row: Vec<String> = pts.iter().map(|&x| format!("{:.2}", g(x))).collect();
    let spread = book.iter().filter(|&&p| p > 0.0 && p < 100.0).count();
    let (zeros, capped) = (book.iter().filter(|&&p| p == 0.0).count(), book.iter().filter(|&&p| p == 100.0).count());
    println!("book: {} at $0, {} spread between, {} at $100", zeros, spread, capped);
    println!("chart, G at -20 -10 0- 0 20 40 60 80 100- 100: {}", row.join(" "));
    println!("lumps: {:.2} at $0, {:.2} at $100; rate between them {:.3} per dollar",
        g(0.0) - g(-1e-9), g(100.0) - g(100.0 - 1e-9), (g(60.0) - g(20.0)) / 40.0);
    println!("total weight G(b) - G(a) = {:.2}; contracts paying something: {}", g(B) - g(A), paying);
    println!("road 1, split: smooth part {:.2} + lumps {:.2} = {:.2}", smooth, jumps, split);
    for n in [12usize, 120, 1200] {
        // road 2: lower and upper sums close on it
        let (lo, hi) = (rs_sum(pay, n, 0.0), rs_sum(pay, n, 1.0));
        let h = (B - A) / n as f64;
        println!("road 2, n = {}: slice width {:.2}, lower {:.3}, upper {:.3}, gap {:.3}", n, h, lo, hi, hi - lo);
        assert!(lo <= split && split <= hi && ((hi - lo) - h * (g(B) - g(A))).abs() < 1e-9);
    }
    println!("road 3, contract by contract: {} contracts, total {:.2}, average {:.2}", book.len(), total, by_hand);
    println!("road 4, area above G from 0 to 100: {:.2}", tail);
    assert!((by_hand - split).abs() < 1e-9); // the list agrees with the formula
    assert!((tail - split).abs() < 1e-6); // the area agrees with the formula
    println!("mistake 1, lumps dropped: {:.2}", smooth);
    let sw = g(100.0 - 1e-9) - g(0.0);
    println!("mistake 2, lumps dropped, divided by smooth weight {:.2}: {:.2}", sw, smooth / sw);
    println!("mistake 3, width instead of weight, integral of x from 0 to 100: {:.2}", 100.0f64.powi(2) / 2.0);
    for n in [125usize, 1250] {
        // 0 falls inside a slice, not on a cut
        let (lo, hi) = (rs_sum(fee, n, 0.0), rs_sum(fee, n, 1.0));
        println!("shared jump, n = {}: left tags {:.4}, right tags {:.4}", n, lo, hi);
        assert!(hi - lo > 0.39); // the tags never agree: no integral
    }
    println!("fee by counting contracts: {:.4} per contract", paying as f64 / book.len() as f64);
    println!("ALL CHECKS PASS");
}
