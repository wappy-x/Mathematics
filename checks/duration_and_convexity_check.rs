// Duration and convexity -- the same check as the Python, in Rust.  No crates.
// The bond: 1,000 face, 6% annual coupon, five years, priced at a 5% yield.
// Four roads reach the same numbers: present-value weighted sums; central
// differences on the price function itself; whole-number arithmetic with a
// single division at the end; and a certified bound on what the second-order
// estimate leaves out.
const FACE: f64 = 1000.0;
const COUPON: f64 = 60.0;
const YEARS: u32 = 5;
const Y: f64 = 0.05;
const UP: f64 = 0.01;

fn flows(coupon: f64, years: u32) -> Vec<(u32, f64)> {
    (1..=years).map(|t| (t, coupon + if t == years { FACE } else { 0.0 })).collect()
}

fn price(y: f64, fl: &[(u32, f64)]) -> f64 {
    let mut s = 0.0;
    for &(t, c) in fl { s += c / (1.0 + y).powf(t as f64) }
    s
}

fn macaulay(y: f64, fl: &[(u32, f64)]) -> f64 {   // road 1: the present-value weighted average time
    let mut s = 0.0;
    for &(t, c) in fl { s += (t as f64) * c / (1.0 + y).powf(t as f64) }
    s / price(y, fl)
}

fn convexity(y: f64, fl: &[(u32, f64)]) -> f64 {  // road 1: weighted t(t+1), two extra discounts
    let mut s = 0.0;
    for &(t, c) in fl { s += (t as f64) * ((t + 1) as f64) * c / (1.0 + y).powf((t + 2) as f64) }
    s / price(y, fl)
}

fn third_size(y: f64, fl: &[(u32, f64)]) -> f64 { // the largest the third derivative gets on a move
    let mut s = 0.0;
    for &(t, c) in fl {
        s += (t as f64) * ((t + 1) as f64) * ((t + 2) as f64) * c / (1.0 + y).powf((t + 3) as f64)
    }
    s
}

fn slope(y: f64, fl: &[(u32, f64)]) -> f64 {      // road 2: dP/dy by nudging the yield both ways
    let h = 1e-5;
    (price(y + h, fl) - price(y - h, fl)) / (2.0 * h)
}

fn bend(y: f64, fl: &[(u32, f64)]) -> f64 {       // road 2: d2P/dy2 by nudging the yield both ways
    let h = 1e-4;
    (price(y + h, fl) - 2.0 * price(y, fl) + price(y - h, fl)) / (h * h)
}

fn exact_price(a: i128, b: i128, fl: &[(u32, f64)]) -> f64 {  // road 3: (1+y) = a/b, whole numbers
    let mut num: i128 = 0;
    for &(t, c) in fl { num += (c as i128) * b.pow(t) * a.pow(YEARS - t) }
    num as f64 / a.pow(YEARS) as f64
}

fn pair(label: &str, vals: [f64; 2]) {
    let mut line = format!("{:<38}", label);
    for v in vals { line.push_str(&format!("{:>15.6}", v)) }
    println!("{}", line);
}

fn row(prefix: &str, cells: Vec<String>) { println!("{}{}", prefix, cells.join(" ")) }

fn main() {
    let fl = flows(COUPON, YEARS);
    let p = price(Y, &fl);
    let dmac = macaulay(Y, &fl);
    let dmod = dmac / (1.0 + Y);
    let cvx = convexity(Y, &fl);

    println!("the house bond: 1000 face, 6% annual coupon, 5 years, priced at a 5% yield");
    println!("{:>4}{:>10}{:>16}{:>16}{:>14}",
             "year", "cash", "present value", "share of price", "year x share");
    for &(t, c) in &fl {
        let pv = c / (1.0 + Y).powf(t as f64);
        println!("{:>4}{:>10.2}{:>16.6}{:>16.6}{:>14.6}", t, c, pv, pv / p, (t as f64) * pv / p);
    }
    println!("{:>14}{:>16.6}{:>16.6}{:>14.6}", "totals", p, 1.0, dmac);
    println!();
    println!("{:<40}{:>14.6}", "price P", p);
    println!("{:<40}{:>14.6}", "  by whole-number arithmetic", exact_price(21, 20, &fl));
    println!("{:<40}{:>14.6}", "Macaulay duration, years", dmac);
    println!("{:<40}{:>14.6}", "modified duration, per 1.00 of yield", dmod);
    println!("{:<40}{:>14.6}", "  -(1/P) dP/dy by nudging", -slope(Y, &fl) / p);
    println!("{:<40}{:>14.6}", "convexity, years squared", cvx);
    println!("{:<40}{:>14.6}", "  (1/P) d2P/dy2 by nudging", bend(Y, &fl) / p);
    println!("{:<40}{:>14.6}", "DV01, dollars per basis point", dmod * p * 1e-4);

    let mut shocks: Vec<(f64, f64, f64, f64, f64)> = Vec::new();
    for (h, a, b) in [(UP, 53i128, 50i128), (-UP, 26i128, 25i128)] {
        let exact = exact_price(a, b, &fl);
        let lin = p * (1.0 - dmod * h);
        let quad = lin + p * 0.5 * cvx * h * h;
        let bound = third_size(Y.min(Y + h), &fl) * h.abs().powf(3.0) / 6.0;
        shocks.push((h, exact, lin, quad, bound));
    }
    let (s0, s1) = (shocks[0], shocks[1]);
    println!();
    println!("{:<38}{:>15}{:>15}", "a 1-point move from the 5% yield", "rise to 6%", "fall to 4%");
    pair("  exact new price, whole numbers", [s0.1, s1.1]);
    pair("  duration-only estimate", [s0.2, s1.2]);
    pair("  duration + convexity estimate", [s0.3, s1.3]);
    pair("  duration-only error, dollars", [s0.1 - s0.2, s1.1 - s1.2]);
    pair("  duration + convexity error, dollars", [s0.1 - s0.3, s1.1 - s1.3]);
    pair("  certified error bound, dollars", [s0.4, s1.4]);
    pair("  actual move, percent of price", [100.0 * (s0.1 - p) / p, 100.0 * (s1.1 - p) / p]);
    pair("  duration-only said, percent", [-100.0 * dmod * s0.0, -100.0 * dmod * s1.0]);
    pair("  convexity correction, percent",
         [50.0 * cvx * s0.0 * s0.0, 50.0 * cvx * s1.0 * s1.0]);

    println!();
    println!("what breaks, on the 1-point rise (right answer 1000.000000)");
    println!("{:<40}{:>14.6}", "  Macaulay used in place of modified", p * (1.0 - dmac * UP));
    println!("{:<40}{:>14.6}", "  convexity term without the half", s0.2 + p * cvx * UP * UP);
    println!("{:<40}{:>14.6}", "  convexity term subtracted", s0.2 - p * 0.5 * cvx * UP * UP);
    println!("{:<40}{:>14.6}", "  100 basis points typed as 1.0", p * (1.0 - dmod * 1.0));

    println!();
    let zc = flows(0.0, YEARS);
    let ten = flows(COUPON, 10);
    let big = 3.0 * UP;
    println!("{:<40}{:>14.6}", "try: 5-year zero, Macaulay duration", macaulay(Y, &zc));
    println!("{:<40}{:>14.6}", "try: 5-year zero, convexity", convexity(Y, &zc));
    println!("{:<40}{:>14.6}", "try: 10-year bond, modified duration", macaulay(Y, &ten) / (1.0 + Y));
    println!("{:<40}{:>14.6}", "try: 3-point rise, with convexity error",
             price(Y + big, &fl) - p * (1.0 - dmod * big + 0.5 * cvx * big * big));

    println!();
    let chart_y: Vec<f64> = (0..9).map(|i| 0.03 + 0.005 * i as f64).collect();
    row("chart, yield percent      ", chart_y.iter().map(|y| format!("{:7.2}", 100.0 * y)).collect());
    row("chart, actual price       ", chart_y.iter().map(|&y| format!("{:7.2}", price(y, &fl))).collect());
    row("chart, duration-only line ",
        chart_y.iter().map(|&y| format!("{:7.2}", p * (1.0 - dmod * (y - Y)))).collect());
    let moves = [0.001, 0.005, 0.01, 0.02, 0.03];
    row("bars, move in basis points", moves.iter().map(|h| format!("{:7.0}", 10000.0 * h)).collect());
    row("bars, duration-only error ",
        moves.iter().map(|&h| format!("{:7.2}", price(Y + h, &fl) - p * (1.0 - dmod * h))).collect());
    let ages = [5u32, 4, 3, 2, 1];
    row("chart, years remaining    ", ages.iter().map(|n| format!("{:7}", n)).collect());
    row("chart, modified duration  ",
        ages.iter().map(|&n| format!("{:7.2}", macaulay(Y, &flows(COUPON, n)) / (1.0 + Y))).collect());
    let drift = [0.03, 0.04, 0.05, 0.06, 0.07];
    row("drift, yield percent      ", drift.iter().map(|y| format!("{:7.2}", 100.0 * y)).collect());
    row("drift, modified duration  ",
        drift.iter().map(|&y| format!("{:7.2}", macaulay(y, &fl) / (1.0 + y))).collect());

    assert!((-slope(Y, &fl) / p - dmod).abs() < 1e-6, "nudged slope must land on Macaulay/(1+y)");
    assert!((bend(Y, &fl) / p - cvx).abs() < 1e-4, "nudged bend must land on the weighted t(t+1) sum");
    assert!((exact_price(21, 20, &fl) - p).abs() < 1e-9, "whole numbers must land on the float price");
    assert!((macaulay(Y, &zc) - YEARS as f64).abs() < 1e-12, "a zero's average payment time is its maturity");
    for &(_h, exact, lin, quad, bound) in &shocks {
        assert!((exact - quad).abs() <= bound, "the second-order error must respect its bound");
        assert!((exact - quad).abs() < (exact - lin).abs(), "convexity must shrink the error");
        assert!(exact > lin, "the curve must sit above its tangent on both sides");
    }
    println!("ALL CHECKS PASS");
}
