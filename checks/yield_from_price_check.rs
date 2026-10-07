// Yield from price -- the same check as the Python, in Rust.  No crates.  The
// house bond: face 1000, a 6% coupon paid once a year, five years to run,
// quoted at 1043.294767.  The yield is found two ways that share no
// arithmetic: halving a bracket and following tangents.  The quote itself is
// a whole-number fraction, the exact price at 21/20, so the target is not an
// artefact of the floating-point code.  A quarry stream is then solved too.
const FACE: f64 = 1000.0;
const CRATE_: f64 = 0.06;
const YEARS: usize = 5;

/// the price at a yield: every payment discounted, then added
fn pv(flows: &[(usize, f64)], y: f64) -> f64 {
    let mut s = 0.0;
    for &(t, cf) in flows { s += cf / (1.0 + y).powf(t as f64); }
    s
}

/// dP/dy: dollars of price per unit of yield
fn slope(flows: &[(usize, f64)], y: f64) -> f64 {
    let mut s = 0.0;
    for &(t, cf) in flows { s += t as f64 * cf / (1.0 + y).powf(t as f64 + 1.0); }
    -s
}

/// decimal digits of the answer that have settled
fn digits(err: f64) -> i32 {
    let (mut d, mut e) = (0, err.abs());
    while e < 1.0 && d < 17 { e *= 10.0; d += 1; }
    d - 1
}

/// Halve a bracket whose ends price on opposite sides of the target.
fn bisect(flows: &[(usize, f64)], target: f64, lo0: f64, hi0: f64, steps: usize)
          -> Vec<(usize, f64, f64, f64)> {
    let (mut lo, mut hi) = (lo0, hi0);
    let flo = pv(flows, lo) - target;
    let mut trace = Vec::new();
    for k in 0..steps {
        let mid = 0.5 * (lo + hi);
        if (pv(flows, mid) - target) * flo > 0.0 { lo = mid } else { hi = mid }
        trace.push((k + 1, lo, hi, 0.5 * (lo + hi)));
    }
    trace
}

/// Follow the tangent to where it crosses the quoted price.
fn newton(flows: &[(usize, f64)], target: f64, y0: f64, steps: usize) -> Vec<(usize, f64, f64)> {
    let (mut trace, mut y) = (Vec::new(), y0);
    for k in 0..steps {
        let resid = pv(flows, y) - target;
        y -= resid / slope(flows, y);
        trace.push((k + 1, y, resid));
        if y <= -1.0 { break }
    }
    trace
}

/// whole-number square root, written out here
fn isqrt(n: i128) -> i128 {
    let mut x = n;
    while x * x > n { x = (x + n / x) / 2 }
    x
}

fn row(label: &str, value: f64) { println!("{:<48}{:>14.6}", label, value); }

fn strip(label: &str, values: &[f64]) {
    let mut line = format!("{:<38}", label);
    for v in values { line.push_str(&format!("{:>10.2}", v)); }
    println!("{}", line);
}

fn main() {
    let bond: Vec<(usize, f64)> = (1..=YEARS)
        .map(|t| (t, FACE * CRATE_ + if t == YEARS { FACE } else { 0.0 })).collect();
    let quarry: Vec<(usize, f64)> = vec![(0, -1000.0), (1, 3000.0), (2, -2000.0)];
    let mut num: i128 = 0;                            // exact price at y = 1/20,
    for &(t, cf) in &bond {                           // as a whole-number fraction
        num += cf.round() as i128 * 20i128.pow(t as u32) * 21i128.pow((YEARS - t) as u32);
    }
    let den: i128 = 21i128.pow(YEARS as u32);
    let quote = num as f64 / den as f64;

    println!("the house bond: face {:.2}, coupon {:.2}% once a year, {} payments, quoted at {:.6}",
             FACE, CRATE_ * 100.0, YEARS, quote);
    println!("the quote as a whole-number fraction: {} / {}", num, den);
    println!("the same fraction by long division:   {}.{:012}",
             num / den, (num * 10i128.pow(12) / den) % 10i128.pow(12));
    let ys = [0.03, 0.04, 0.05, 0.06, 0.07, 0.08, 0.09];
    let curve: Vec<f64> = ys.iter().map(|&y| pv(&bond, y)).collect();
    strip("price at yields 3% to 9%", &curve);
    strip("the quote, flat, at those yields", &[quote; 7]);
    println!("bracket: the price at 0% is {:.6} and at 100% is {:.6}, so the quote is caught between",
             pv(&bond, 0.0), pv(&bond, 1.0));
    println!("road 1  halving the bracket [0%, 100%]");
    let tr = bisect(&bond, quote, 0.0, 1.0, 40);
    for &(k, lo, hi, mid) in &tr {
        if k <= 6 || k == 10 || k == 20 || k == 40 {
            println!("  step {:>2}  bracket [{:.6}, {:.6}]  midpoint {:.6}  price {:>11.6}",
                     k, lo, hi, mid, pv(&bond, mid));
        }
    }
    println!("road 2  tangent steps from the 6% coupon rate");
    let nt = newton(&bond, quote, CRATE_, 6);
    for &(k, y, resid) in nt.iter().take(4) {
        println!("  step {:>2}  price residual before the step {:>12.6}  yield after it {:.7}%",
                 k, resid, y * 100.0);
    }
    let (y_bis, y_new) = (tr[tr.len() - 1].3, nt[3].1);
    row("road 1  yield after 40 halvings, percent", y_bis * 100.0);
    row("road 2  yield after 4 tangent steps, percent", y_new * 100.0);
    row("the exact 1/20 the quote was built at, percent", 100.0 / 20.0);
    row("roads 1 and 2 apart by, percent", (y_bis - y_new).abs() * 100.0);
    let mut head = format!("{:<38}", "digits of the yield settled after step");
    let (mut bh, mut th) = (format!("{:<38}", "  by halving"), format!("{:<38}", "  by tangents"));
    for k in 0..6 {
        head.push_str(&format!("{:>10}", k + 1));
        bh.push_str(&format!("{:>10}", digits(tr[k].3 - 0.05)));
        th.push_str(&format!("{:>10}", digits(nt[k].1 - 0.05)));
    }
    println!("{}\n{}\n{}", head, bh, th);
    let m = -slope(&bond, 0.06);        // the slowest the price falls anywhere in 4% to 6%
    let stop10 = tr[9].3;
    row("price fall per unit of yield at 5%, dollars", -slope(&bond, 0.05));
    row("price fall for one basis point, dollars", -slope(&bond, 0.05) * 0.0001);
    row("slowest price fall anywhere in 4% to 6%", m);
    row("yield a 1 cent price error can hide, percent", 0.01 / m * 100.0);
    row("mistake: coupon over price, the current yield, %", FACE * CRATE_ / quote * 100.0);
    row("mistake: the 6% coupon read as the yield, %", CRATE_ * 100.0);
    row("mistake: halving stopped after 10 steps, %", stop10 * 100.0);
    row("  that guess is out by, percent", (stop10 - 0.05).abs() * 100.0);
    row("  with this much price still missing, dollars", (pv(&bond, stop10) - quote).abs());
    row("  and that residual allows a yield error of, %", (pv(&bond, stop10) - quote).abs() / m * 100.0);
    println!("the quarry: 1000 paid out today, 3000 back in a year, 2000 of clean-up at the end");
    let qys = [0.0, 0.25, 0.5, 0.75, 1.0, 1.25, 1.5];
    strip("its value at yields 0% to 150%", &qys.iter().map(|&y| pv(&quarry, y)).collect::<Vec<f64>>());
    strip("the zero line it must cross", &[0.0; 7]);
    let qr = bisect(&quarry, 0.0, 0.5, 3.0, 60)[59].3;
    row("quarry yield by halving [50%, 300%], percent", qr * 100.0);
    row("quarry value at a yield of 0%, dollars", pv(&quarry, 0.0));
    let mut roots: Vec<f64> = Vec::new();
    for cost in [1000i128, 1125, 1200] {
        let disc = 3000 * 3000 - 4 * cost * 2000;   // the whole-number test for how many yields exist
        if disc < 0 {
            println!("  bought for {}: the root sign holds {}, so no yield exists at all", cost, disc);
        } else {
            let mut zs = vec![3000 - isqrt(disc), 3000 + isqrt(disc)];
            zs.dedup();
            let rs: Vec<f64> = zs.iter().map(|&z| z as f64 / (2 * cost) as f64 - 1.0).collect();
            if cost == 1000 { roots = rs.clone() }
            let shown: Vec<String> = rs.iter().map(|y| format!("{:.6}%", y * 100.0)).collect();
            println!("  bought for {}: the root sign holds {}, giving {}: {}", cost, disc,
                     if rs.len() == 1 { "one yield" } else { "two yields" }, shown.join(" and "));
        }
    }
    println!("  a tangent step from a yield of 30% lands at {:.4}%, outside every price",
             newton(&quarry, 0.0, 0.30, 1)[0].1 * 100.0);
    assert!((y_bis - y_new).abs() < 1e-9, "halving and tangents must land on the same yield");
    assert!((pv(&bond, y_new) - quote).abs() < 1e-9, "the found yield must reprice the whole-number quote");
    assert!((y_bis - 0.05).abs() < 1e-11, "the search must find the 1/20 built into the quote");
    assert!((stop10 - 0.05).abs() <= (pv(&bond, stop10) - quote).abs() / m, "the price-residual bound holds");
    assert!((0..curve.len() - 1).all(|i| curve[i] > curve[i + 1]), "one price per yield, no ties");
    assert!((qr - roots[1]).abs() < 1e-9 && pv(&quarry, roots[0]) == 0.0, "both quarry yields, two ways");
    println!("ALL CHECKS PASS");
}
