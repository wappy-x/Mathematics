// Carry and roll-down -- the same check as the Python, in Rust.  No crates.
// A five-year zero-coupon bond, face 100, bought today and sold in one year on
// a curve that has not moved.  Roads to the answer: (1) the closed forms for
// carry and roll, (2) repricing the bond, (3) adding up the instantaneous
// forward rate along the path the bond travels, (4) bisection on the sale
// price for the breakeven, (5) the forward curve read off discount factors.
const Y: [f64; 6] = [0.0, 0.030, 0.033, 0.0365, 0.0405, 0.045]; // zero yields, continuous
const N: f64 = 100.0;
const T: f64 = 5.0;
const H: f64 = 1.0;

fn y(t: f64) -> f64 {                // yield at any maturity from 1 to 5: straight line between pillars
    let lo = (t.floor() as usize).clamp(1, 4);
    let w = t - lo as f64;
    (1.0 - w) * Y[lo] + w * Y[lo + 1]
}

fn d(t: f64) -> f64 { (-t * y(t)).exp() }   // discount factor: today's value of 1 due in t years

fn fwd_inst(t: f64) -> f64 {         // instantaneous forward rate: the slope of t * y(t)
    let e = 1e-6;
    ((t + e) * y(t + e) - (t - e) * y(t - e)) / (2.0 * e)
}

fn slices(f: &dyn Fn(f64) -> f64, a: f64, b: f64) -> f64 {   // n thin slices, at midpoints
    let n = 4000;
    let w = (b - a) / n as f64;
    (0..n).map(|i| f(a + (i as f64 + 0.5) * w)).sum::<f64>() * w
}

fn bisect(g: &dyn Fn(f64) -> f64, mut lo: f64, mut hi: f64) -> f64 {   // halve until done
    for _ in 0..200 {
        let mid = 0.5 * (lo + hi);
        if (g(lo) > 0.0) == (g(mid) > 0.0) { lo = mid } else { hi = mid }
    }
    0.5 * (lo + hi)
}

fn zero_price(years_left: f64, yld: f64) -> f64 { N * (-years_left * yld).exp() }
fn pct(x: f64) -> String { format!("{:.4}%", 100.0 * x) }
fn bp(x: f64) -> String { format!("{:.2} bp", 10000.0 * x) }
fn try_curve(y5: f64, y4: f64, y1: f64) -> String {   // the closed forms again, for Try changing
    let (c, r) = (H * y5, (T - H) * (y5 - y4));
    format!("carry {}, roll {}, breakeven vs cash {}", pct(c), pct(r), bp((c + r - H * y1) / (T - H)))
}

fn main() {
    let r1 = Y[1];                                           // one-year rate: cash for the year
    // ---- road 1: the closed forms;  road 2: reprice the bond ----
    let (carry, roll) = (H * Y[5], (T - H) * (Y[5] - Y[4]));
    let (p0, flat, stat) = (zero_price(T, Y[5]), zero_price(T - H, Y[5]), zero_price(T - H, Y[4]));
    let total_reprice = (stat / p0).ln();
    // ---- road 3: the bond slides from 5 years to 4 and earns the forward rate on the way ----
    let total_path = slices(&fwd_inst, T - H, T);
    let excess = carry + roll - H * r1;
    // ---- breakevens: road 4 bisection on the price, road 5 the forward yield ----
    let be_zero_formula = (carry + roll) / (T - H);
    let be_zero_bisect = bisect(&|x| zero_price(T - H, Y[4] + x) - p0, -0.1, 0.1);
    let be_cash_formula = excess / (T - H);
    let be_cash_bisect = bisect(&|x| zero_price(T - H, Y[4] + x) - p0 * (H * r1).exp(), -0.1, 0.1);
    let fwd_4y = (d(1.0) / d(5.0)).ln() / (T - H);           // the 4-year yield, one year ahead
    let rows: Vec<(&str, String)> = vec![
        ("5-year yield today", pct(Y[5])), ("4-year yield today", pct(Y[4])),
        ("roll-down in yield, 5y minus 4y", bp(Y[5] - Y[4])), ("one-year rate (cash)", pct(r1)),
        ("price today, 100 e^-5y5", format!("{:.6}", p0)), ("sale price at the old 5y yield", format!("{:.6}", flat)),
        ("sale price at the 4y yield", format!("{:.6}", stat)),
        ("carry in dollars", format!("{:.6}", flat - p0)), ("roll in dollars", format!("{:.6}", stat - flat)),
        ("total in dollars", format!("{:.6}", stat - p0)),
        ("1 carry, h y(5)", pct(carry)), ("1 roll, (T-h)(y5 - y4)", pct(roll)),
        ("1 carry + roll", pct(carry + roll)), ("2 log(sale / price today)", pct(total_reprice)),
        ("3 forward rate added up, 4y to 5y", pct(total_path)),
        ("simple return, e^total - 1", pct((carry + roll).exp() - 1.0)),
        ("net carry, h (y5 - r1)", pct(H * (Y[5] - r1))), ("excess over cash", pct(excess)),
        ("breakeven vs zero, formula", bp(be_zero_formula)), ("breakeven vs zero, bisection", bp(be_zero_bisect)),
        ("breakeven vs cash, formula", bp(be_cash_formula)), ("breakeven vs cash, bisection", bp(be_cash_bisect)),
        ("forward 4y yield in one year", pct(fwd_4y)), ("forward minus today's 4y", bp(fwd_4y - Y[4])),
        ("wrong: 45 bp read as the return", pct(Y[5] - Y[4])),
        ("wrong: roll times 5 years", pct(T * (Y[5] - Y[4]))),
        ("wrong: breakeven over 5 years", bp(excess / T)),
        ("wrong: breakeven from roll alone", bp(roll / (T - H))),
    ];
    for (name, v) in &rows { println!("{:<36} {:>14}", name, v) }
    println!("try: 4y yield 4.80%      {}", try_curve(0.045, 0.048, 0.030));
    println!("try: cash rate 4.50%     {}", try_curve(0.045, 0.0405, 0.045));
    println!("try: flat curve at 4.50% {}", try_curve(0.045, 0.045, 0.045));

    println!("\nbond, % a year   carry   roll  total   path excess  breakeven");
    for m in [2.0_f64, 3.0, 4.0, 5.0] {                      // every bond on the curve, held one year
        let (c, r) = (H * y(m), (m - H) * (y(m) - y(m - H)));
        let p = slices(&fwd_inst, m - H, m);
        println!("{}-year zero     {:6.2} {:6.2} {:6.2} {:6.2} {:6.2} {:7.2} bp", m, 100.0 * c, 100.0 * r,
                 100.0 * (c + r), 100.0 * p, 100.0 * (c + r - r1), 10000.0 * (c + r - r1) / (m - H));
    }
    let us = [1.0_f64, 2.0, 3.0, 4.0];
    println!("chart, years left at sale {}", us.iter().map(|u| format!("{:9}", u)).collect::<String>());
    println!("chart, today's curve bp   {}", us.iter().map(|&u| format!("{:9.2}", 10000.0 * y(u))).collect::<String>());
    println!("chart, breakeven curve bp {}", us.iter()
        .map(|&u| format!("{:9.2}", 10000.0 * (d(1.0) / d(1.0 + u)).ln() / u)).collect::<String>());
    let shifts: Vec<f64> = (0..11).map(|i| -0.005 + 0.0025 * i as f64).collect();
    println!("chart, 4y yield move bp   {}", shifts.iter().map(|s| format!("{:7.0}", 10000.0 * s)).collect::<String>());
    println!("chart, log return %       {}", shifts.iter()
        .map(|&s| format!("{:7.2}", 100.0 * (zero_price(4.0, Y[4] + s) / p0).ln())).collect::<String>());

    // ---- a 4.5% annual-coupon five-year bond on the same curve ----
    let cf: Vec<f64> = (0..6).map(|t| if t == 0 { 0.0 } else { 4.5 + if t == 5 { N } else { 0.0 } }).collect();
    let pc: f64 = (1..6).map(|t| cf[t] * d(t as f64)).sum();
    let q = bisect(&|z| (1..6).map(|t| cf[t] * (-z * t as f64).exp()).sum::<f64>() - pc, -0.5, 0.5);
    let w_flat = cf[1] + (2..6).map(|t| cf[t] * (-q * (t as f64 - 1.0)).exp()).sum::<f64>();
    let w_stat = cf[1] + (2..6).map(|t| cf[t] * d(t as f64 - 1.0)).sum::<f64>();
    let fwd = |u: f64| ((1.0 + u) * y(1.0 + u) - y(1.0)) / u;                   // breakeven curve
    let w_fwd = cf[1] + (2..6).map(|t| { let u = t as f64 - 1.0; cf[t] * (-u * fwd(u)).exp() }).sum::<f64>();
    let be_c = bisect(&|x| cf[1] + (2..6).map(|t| { let u = t as f64 - 1.0; cf[t] * d(u) * (-u * x).exp() })
        .sum::<f64>() - pc * (H * r1).exp(), -0.1, 0.1);
    println!("\ncoupon bond price today {:.6}, its own yield {}", pc, pct(q));
    println!("coupon bond carry {}, roll {}, total {}", pct((w_flat - pc) / pc), pct((w_stat - w_flat) / pc),
             pct((w_stat - pc) / pc));
    println!("coupon bond on the breakeven curve: growth {:.10}, cash e^r1 {:.10}", w_fwd / pc, (H * r1).exp());
    println!("coupon bond breakeven, parallel move {}", bp(be_c));

    assert!((total_path - (carry + roll)).abs() < 1e-9, "forward rate added up must equal carry + roll");
    assert!((total_reprice - (carry + roll)).abs() < 1e-12, "repricing must equal the closed form");
    assert!((be_cash_bisect - (fwd_4y - Y[4])).abs() < 1e-12, "breakeven by bisection = forward minus spot");
    assert!((be_zero_bisect - be_zero_formula).abs() < 1e-12, "zero-return breakeven, two roads");
    assert!((w_fwd / pc - (H * r1).exp()).abs() < 1e-12, "on the forward curve every bond earns cash");
    assert!((be_cash_bisect - 0.00825).abs() < 1e-12, "breakeven vs cash: 82.5 bp, the audited reference");
    assert!((be_zero_bisect - 0.01575).abs() < 1e-12, "breakeven vs zero: 157.5 bp, the audited reference");
    println!("ALL CHECKS PASS");
}
