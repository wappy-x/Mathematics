// Breakeven inflation -- the same check as breakeven_inflation_check.py, in Rust.
// Standard library only, no crates.  Three roads to the breakeven: the closed
// form, bisection on two zero-coupon payoffs, Newton's method on a coupon linker.
// Compile: rustc --edition 2021 -O breakeven_inflation_check.rs -o /tmp/breakeven_check

const T: i32 = 10;
const N: f64 = 0.03525; // nominal yield, annual effective
const R: f64 = 0.01; // real yield, annual effective
const C: f64 = 0.01; // the linker's real coupon
const K: f64 = 0.026; // inflation swap fixed rate
const FACE: f64 = 1000.0; // dollars invested

fn pw(x: f64, t: i32) -> f64 {
    x.powf(t as f64)
}

fn closed_form(n: f64, r: f64) -> f64 {
    (1.0 + n) / (1.0 + r) - 1.0
}

fn bisect(f: &dyn Fn(f64) -> f64, mut lo: f64, mut hi: f64) -> f64 {
    assert!(f(lo) < 0.0 && 0.0 < f(hi), "bracket must straddle the root");
    for _ in 0..200 {
        let mid = (lo + hi) / 2.0;
        if f(mid) < 0.0 { lo = mid } else { hi = mid }
    }
    (lo + hi) / 2.0
}

fn zero_gap(pi: f64, t: i32) -> f64 {
    FACE * pw(1.0 + R, t) * pw(1.0 + pi, t) - FACE * pw(1.0 + N, t)
}

fn real_price(c: f64, y: f64, t: i32) -> f64 {
    let coupons: f64 = (1..=t).map(|s| c / pw(1.0 + y, s)).sum();
    coupons + 1.0 / pw(1.0 + y, t)
}

fn linker_pv(pi: f64, c: f64, n: f64, t: i32) -> f64 {
    let coupons: f64 = (1..=t).map(|s| c * pw(1.0 + pi, s) / pw(1.0 + n, s)).sum();
    coupons + pw(1.0 + pi, t) / pw(1.0 + n, t)
}

fn newton(f: &dyn Fn(f64) -> f64, mut x: f64) -> f64 {
    let h = 1e-7;
    for _ in 0..50 {
        x -= f(x) / ((f(x + h) - f(x - h)) / (2.0 * h));
    }
    x
}

fn main() {
    let pi1 = closed_form(N, R);
    let pi2 = bisect(&|p| zero_gap(p, T), -0.5, 1.0);
    let p_c = real_price(C, R, T);
    let pi3 = newton(&|p| linker_pv(p, C, N, T) - p_c, 0.0);
    let p_lo = real_price(0.00125, R, T);
    let pi4 = newton(&|p| linker_pv(p, 0.00125, N, T) - p_lo, 0.0);

    let j = pw(1.0 + pi1, T);
    let nominal_end = FACE * pw(1.0 + N, T);
    let linker_real_end = FACE * pw(1.0 + R, T);
    let spread = N - R;
    let cont = (1.0 + N).ln() - (1.0 + R).ln();

    let basis = K - pi1;
    let synth_real = (1.0 + N) / (1.0 + K) - 1.0;
    let locked = FACE * pw((1.0 + R) * (1.0 + K), T);
    let receiver_at_tie = FACE * (pw(1.0 + pi1, T) - pw(1.0 + K, T));

    let inverted = (1.0 + R) / (1.0 + N) - 1.0;
    let simple_ann = (j - 1.0) / T as f64;
    let y_sa = 2.0 * ((1.0 + N).powf(0.5) - 1.0);
    let mixed = (1.0 + y_sa) / (1.0 + R) - 1.0;

    let n_low = 0.005;
    let pi_low = closed_form(n_low, R);
    let floor_min = FACE * pw(1.0 + R, T);
    let nominal_low = FACE * pw(1.0 + n_low, T);

    let rows: Vec<(&str, f64)> = vec![
        ("1 closed form, pct", 100.0 * pi1), ("2 bisection, zero bonds, pct", 100.0 * pi2),
        ("3 Newton, 1% coupon linker, pct", 100.0 * pi3), ("  linker price per 1000", 1000.0 * p_c),
        ("4 Newton, 0.125% coupon linker, pct", 100.0 * pi4), ("  linker price per 1000", 1000.0 * p_lo),
        ("growth ratio (1+n)/(1+r)", (1.0 + N) / (1.0 + R)),
        ("index ratio at the tie J*", j),
        ("nominal zero at year 10, $", nominal_end), ("linker zero, real units, $", linker_real_end),
        ("linker zero at the tie, $", linker_real_end * j),
        ("linker if inflation 2%, $", linker_real_end * pw(1.02, T)),
        ("linker if inflation 3%, $", linker_real_end * pw(1.03, T)),
        ("shortcut spread n - r, pct", 100.0 * spread), ("shortcut error, bp", 10000.0 * (spread - pi1)),
        ("  r times breakeven, bp", 10000.0 * R * pi1),
        ("continuous-rate breakeven, pct", 100.0 * cont),
        ("swap fixed rate, pct", 100.0 * K), ("swap minus breakeven, bp", 10000.0 * basis),
        ("synthetic real yield, pct", 100.0 * synth_real),
        ("linker + pay-CPI swap at year 10, $", locked), ("  gain over nominal zero, $", locked - nominal_end),
        ("CPI receiver at the tie path, $", receiver_at_tie),
        ("wrong: inverted ratio, pct", 100.0 * inverted),
        ("wrong: simple annualising, pct", 100.0 * simple_ann),
        ("  nominal yield quoted semiannual, pct", 100.0 * y_sa),
        ("wrong: semiannual over annual, pct", 100.0 * mixed),
        ("boundary: n = 0.5%, breakeven pct", 100.0 * pi_low), ("  index ratio at that tie", pw(1.0 + pi_low, T)),
        ("  floored linker at least, $", floor_min), ("  nominal zero, $", nominal_low),
        ("try: real yield 2%, pct", 100.0 * closed_form(N, 0.02)),
        ("try: nominal yield 5%, pct", 100.0 * closed_form(0.05, R)),
        ("try: 30 years, bisection, pct", 100.0 * bisect(&|p| zero_gap(p, 30), -0.5, 1.0)),
        ("try: swap 2.5%, synthetic real, pct", 100.0 * ((1.0 + N) / 1.025 - 1.0)),
    ];
    for (name, v) in &rows {
        println!("{:<38} {:>12.6}", name, v);
    }

    let grid: Vec<f64> = (0..11).map(|i| 0.005 * i as f64).collect();
    let row = |f: &dyn Fn(f64) -> String| grid.iter().map(|&p| f(p)).collect::<String>();
    println!("{:<22}{}", "chart, inflation pct", row(&|p| format!("{:>9.1}", 100.0 * p)));
    println!("{:<22}{}", "chart, linker $", row(&|p| format!("{:>9.2}", linker_real_end * pw(1.0 + p, T))));
    println!("{:<22}{}", "chart, nominal $", row(&|_| format!("{:>9.2}", nominal_end)));

    // linker + pay-CPI swap is fixed whatever the index does: test on random index ratios
    let (mut seed, mut worst) = (20260928u64, 0.0f64);
    for _ in 0..1000 {
        seed = seed.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
        let jx = 0.5 + 1.5 * (seed >> 11) as f64 / 2f64.powi(53);
        let linker_leg = FACE * pw(1.0 + R, T) * jx;
        let swap_leg = FACE * pw(1.0 + R, T) * (pw(1.0 + K, T) - jx);
        worst = worst.max((linker_leg + swap_leg - locked).abs());
    }

    assert!((pi2 - pi1).abs() < 1e-12, "bisection on zero payoffs must land on the closed form");
    assert!((pi3 - pi1).abs() < 1e-10, "Newton on the coupon linker must land on the closed form");
    assert!((pi4 - pi1).abs() < 1e-10, "the coupon must not move the breakeven");
    assert!(((spread - pi1) - R * pi1).abs() < 1e-15, "shortcut error must equal r times breakeven");
    assert!(zero_gap(0.02, T) < 0.0 && 0.0 < zero_gap(0.03, T), "linker loses below, wins above");
    assert!(worst < 1e-9, "linker + pay-CPI swap must be fixed on every index path");
    assert!(floor_min > nominal_low, "with n < r the floored linker beats the nominal bond: no tie");
    println!("ALL CHECKS PASS");
}
