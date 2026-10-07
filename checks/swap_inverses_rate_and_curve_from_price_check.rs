// Solving a swap backwards -- the same check as swap_inverses_rate_and_curve_from_price_check.py.
// Standard library only, no crates.  The curve is bootstrapped here, the floating leg is
// built payment by payment from forward rates, and bisection is written out.
// Compile: rustc --edition 2021 -O swap_inverses_rate_and_curve_from_price_check.rs
const N: f64 = 10_000_000.0;                      // notional, dollars
const PAR: [f64; 6] = [0.0, 0.0, 0.0440, 0.0455, 0.0462, 0.0465];   // par quotes by year

fn bootstrap() -> [f64; 6] {                      // the rung formula, shortest first
    let mut d = [0.0; 6];
    d[0] = 1.0;
    d[1] = 1.0 / (1.0 + 1.0 * 0.042);             // one-year deposit at 4.20 percent
    for n in 2..=5 {
        let b: f64 = (1..n).map(|i| d[i]).sum();
        d[n] = (1.0 - PAR[n] * b) / (1.0 + PAR[n]);
    }
    d
}

fn legs(d: &[f64; 6], k: f64) -> (f64, f64, Vec<f64>) {   // payment by payment
    let fixed: f64 = (1..=5).map(|i| N * k * d[i]).sum();
    let fwd: Vec<f64> = (1..=5).map(|i| d[i - 1] / d[i] - 1.0).collect();
    let floating: f64 = (1..=5).map(|i| N * fwd[i - 1] * d[i]).sum();
    (fixed, floating, fwd)
}

fn receiver(d: &[f64; 6], k: f64) -> f64 {        // value to whoever receives fixed
    let (fixed, floating, _) = legs(d, k);
    fixed - floating
}

fn bisect<G: Fn(f64) -> f64>(g: G, mut lo: f64, mut hi: f64) -> (f64, u32) {
    let mut steps = 0;                            // g(lo) < 0 < g(hi), g rising
    while hi - lo > 1e-15 && steps < 200 {
        let mid = 0.5 * (lo + hi);
        steps += 1;
        if g(mid) < 0.0 { lo = mid } else { hi = mid }
    }
    (0.5 * (lo + hi), steps)
}

fn main() {
    let d = bootstrap();
    let a: f64 = (1..=5).map(|i| d[i]).sum();     // annuity: one dollar a year, today
    let v = 100_000.0;                            // target value to the fixed receiver
    // ---- case one: value back to a fixed rate ----
    let k1 = (v / N + 1.0 - d[5]) / a;            // road 1: the line, solved by hand
    let (k2, it) = bisect(|k| receiver(&d, k) - v, -1.0, 1.0);    // road 2
    let (k0s, k1s) = (0.01, 0.09);                // road 3: one secant step from anywhere
    let k3 = k0s + (v - receiver(&d, k0s)) * (k1s - k0s) / (receiver(&d, k1s) - receiver(&d, k0s));
    let k0 = (1.0 - d[5]) / a;                    // the same line at value zero: par
    let (_, fl, fwd) = legs(&d, 0.0);
    let s_fwd: f64 = (1..=5).map(|i| fwd[i - 1] * d[i]).sum::<f64>() / a;
    let v_house = -receiver(&d, 0.045);           // house swap: pay 4.50 percent fixed
    let k_house = k0 - v_house / (N * a);
    // ---- case two: a par quote back to one discount factor ----
    let s5 = PAR[5];
    let b5: f64 = (1..=4).map(|i| d[i]).sum();
    let d5_1 = (1.0 - s5 * b5) / (1.0 + s5);      // road 1: the rung
    let par_value = |d5: f64| { let mut dt = d; dt[5] = d5; receiver(&dt, s5) / N };
    let (d5_2, it2) = bisect(par_value, 1e-9, 1.0);   // road 2: search, legs from forwards
    let h = 1e-4;
    let rung = |s: f64| (1.0 - s * b5) / (1.0 + s);
    let slope_fd = (rung(s5 + h) - rung(s5 - h)) / (2.0 * h);
    let slope_an = -(1.0 + b5) / (1.0 + s5).powi(2);
    // ---- what breaks ----
    let w_undisc = s5 + v / (N * 5.0);
    let w_sign = k0 - v / (N * a);
    let w_nofloat = v / (N * a);
    let w_nocoup = 1.0 / (1.0 + s5);
    let w_zero = 1.0 / (1.0 + s5).powi(5);

    let rows: Vec<(&str, f64)> = vec![
        ("D1", d[1]), ("D2", d[2]), ("D3", d[3]), ("D4", d[4]), ("D5", d[5]),
        ("annuity A = D1+...+D5", a), ("N x A, dollars per unit rate", N * a),
        ("floating leg per dollar, 1 - D5", 1.0 - d[5]), ("floating leg, from forwards", fl), ("floating leg, N(1 - D5)", N * (1.0 - d[5])),
        ("par rate, (1 - D5)/A", k0), ("par rate, weighted forwards", s_fwd),
        ("1 fixed rate, the line", k1), ("2 fixed rate, bisection", k2),
        ("  bisection halvings", it as f64), ("3 fixed rate, one secant step", k3),
        ("  value at that rate", receiver(&d, k1)),
        ("  rate shift, V/(N A)", v / (N * a)), ("  value per 1bp of fixed rate", N * a * 1e-4),
        ("  value where fixed rate is 0", -N * (1.0 - d[5])),
        ("house: payer value at 4.50%", v_house), ("house: rate from that value", k_house),
        ("4 D5, the rung", d5_1), ("5 D5, bisection", d5_2), ("  bisection halvings", it2 as f64),
        ("  known part B5 = D1+...+D4", b5), ("  1 - S5 x B5", 1.0 - s5 * b5),
        ("  top edge of quote, 1/B5", 1.0 / b5), ("  bottom edge of quote, -1", -1.0),
        ("  dD5/dS by bump", slope_fd), ("  dD5/dS = -(1+B5)/(1+S)^2", slope_an),
        ("  D5 move for +1bp quote", slope_an * 1e-4),
        ("wrong: annuity read as 5", w_undisc), ("  reprices at", receiver(&d, w_undisc)),
        ("wrong: payer sign", w_sign), ("  reprices at", receiver(&d, w_sign)),
        ("wrong: floating leg dropped", w_nofloat), ("  reprices at", receiver(&d, w_nofloat)),
        ("wrong: D5 without coupons", w_nocoup), ("wrong: par as annual zero", w_zero),
        ("try: 20m notional, rate", k0 + v / (2.0 * N * a)),
        ("try: 5y quote 4.66%, D5", rung(0.0466)),
    ];
    for (name, x) in &rows {
        if name.contains("halvings") { println!("{:<32} {:>18}", name, *x as u32); }
        else { println!("{:<32} {:>18.8}", name, x); }
    }
    println!();
    let ts = [-200e3, -100e3, 0.0, 100e3, 200e3];
    let row = |f: &dyn Fn(f64) -> String, xs: &[f64]| xs.iter().map(|x| f(*x)).collect::<Vec<_>>().join(" ");
    println!("chart, value target        {}", row(&|t| format!("{:>8.0}", t), &ts));
    println!("chart, fixed rate %        {}", row(&|t| format!("{:>8.2}", 100.0 * (k0 + t / (N * a))), &ts));
    let qs = [0.0, 0.04, 0.08, 0.12, 0.16, 0.20, 0.24, 0.28];
    println!("chart, 5y quote %          {}", row(&|s| format!("{:>7.0}", 100.0 * s), &qs));
    println!("chart, $100 due in 5y      {}", row(&|s| format!("{:>7.2}", 100.0 * rung(s)), &qs));

    assert!((k2 - k1).abs() < 1e-12, "bisection on full legs must land on the line");
    assert!((k3 - k1).abs() < 1e-12, "a linear value: one secant step must land exactly");
    assert!((s_fwd - PAR[5]).abs() < 1e-12, "weighted forwards must give back the 5y quote");
    assert!((d5_2 - d5_1).abs() < 1e-12, "bisection on the par swap must land on the rung");
    assert!((d[5] - 0.79621728).abs() < 5e-9, "five-year price from the bootstrapping card");
    assert!((k_house - 0.045).abs() < 1e-12, "the house swap's value must invert to 4.50%");
    assert!((slope_fd - slope_an).abs() < 1e-6, "bumped slope vs the derivative");
    println!("ALL CHECKS PASS");
}
