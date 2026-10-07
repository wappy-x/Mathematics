// Seasonal gas curve -- the same check as seasonality_and_the_gas_curve_check.py, in Rust.
// Standard library only, no crates.  The strip is fitted to a level times a yearly
// cosine shape by two roads; the storage bound is found by a formula and by pricing
// the trade's cash flows and searching.
use std::f64::consts::PI;

const MONTHS: [&str; 12] = ["Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec", "Jan", "Feb", "Mar"];
const STRIP: [f64; 12] = [2.70, 2.55, 2.50, 2.50, 2.55, 2.62, 2.75, 3.05, 3.35, 3.50, 3.40, 3.05];
const R: f64 = 0.05;
const C: f64 = 0.60;
const FS: f64 = 2.50;
const FW: f64 = 3.50;
const TS: f64 = 3.0 / 12.0;
const TW: f64 = 9.0 / 12.0;

// Gaussian elimination with partial pivoting on an augmented 3 x 4 system.
fn solve(mut m: [[f64; 4]; 3]) -> [f64; 3] {
    for k in 0..3 {
        let mut p = k;
        for i in k..3 { if m[i][k].abs() > m[p][k].abs() { p = i; } }
        m.swap(k, p);
        for i in (k + 1)..3 {
            let f = m[i][k] / m[k][k];
            for j in 0..4 { m[i][j] -= f * m[k][j]; }
        }
    }
    let mut x = [0.0; 3];
    for i in (0..3).rev() {
        let mut s = m[i][3];
        for j in (i + 1)..3 { s -= m[i][j] * x[j]; }
        x[i] = s / m[i][i];
    }
    x
}

// Value today of: pay fs at ts for gas, deliver it at tw for fw, pay the storage cost at tw.
fn trade_pv(fs: f64, fw: f64, cost: f64, ts: f64, tw: f64) -> f64 {
    -fs * (-R * ts).exp() + (fw - cost) * (-R * tw).exp()
}

fn row(label: &str, v: f64) { println!("{:<30} {:10.4}", label, v); }

fn main() {
    let tau = TW - TS;
    let y: Vec<f64> = STRIP.iter().map(|f| f.ln()).collect();
    let th: Vec<f64> = (0..12).map(|m| 2.0 * PI * m as f64 / 12.0).collect();

    // Road 1 to the shape: orthogonal sums (a discrete Fourier sum).
    let a1 = y.iter().sum::<f64>() / 12.0;
    let aa1 = 2.0 / 12.0 * (0..12).map(|m| y[m] * th[m].cos()).sum::<f64>();
    let bb1 = 2.0 / 12.0 * (0..12).map(|m| y[m] * th[m].sin()).sum::<f64>();

    // Road 2: least squares by the normal equations.
    let mut aug = [[0.0; 4]; 3];
    for m in 0..12 {
        let x = [1.0, th[m].cos(), th[m].sin()];
        for i in 0..3 {
            for j in 0..3 { aug[i][j] += x[i] * x[j]; }
            aug[i][3] += x[i] * y[m];
        }
    }
    let [a2, aa2, bb2] = solve(aug);

    let l = a1.exp();
    let beta = (aa1 * aa1 + bb1 * bb1).sqrt();
    let t0 = (bb1.atan2(aa1) / (2.0 * PI)).rem_euclid(1.0);
    let fit: Vec<f64> = (0..12).map(|m| l * (beta * (2.0 * PI * (m as f64 / 12.0 - t0)).cos()).exp()).collect();

    // The storage bound.  Road 1: the formula.
    let cap1 = C + FS * ((R * tau).exp() - 1.0);
    // Road 2: bisection for the January price at which the trade is worth zero today.
    let (mut lo, mut hi) = (FS, FS + 5.0);
    for _ in 0..200 {
        let mid = 0.5 * (lo + hi);
        if trade_pv(FS, mid, C, TS, TW) < 0.0 { lo = mid; } else { hi = mid; }
    }
    let cap2 = 0.5 * (lo + hi) - FS;

    let profit_jan = FW - FS * (R * tau).exp() - C;
    let profit_pv = trade_pv(FS, FW, C, TS, TW);
    let fw_low = FS + 0.30;
    let loss_low = fw_low - FS * (R * tau).exp() - C;
    let phantom = FS * (R * tau).exp() + C - fw_low;

    // Road 3: every storage cycle on the strip, the season's space leased for a flat 0.60.
    let mut best = (f64::MIN, 0usize, 0usize);
    for i in 0..12 {
        for j in (i + 1)..12 {
            let v = trade_pv(STRIP[i], STRIP[j], C, i as f64 / 12.0, j as f64 / 12.0);
            if v > best.0 { best = (v, i, j); }
        }
    }

    let fitted_spread = fit[9] - fit[3];
    let level_up = 1.2 * FW - 1.2 * FS - (C + 1.2 * FS * ((R * tau).exp() - 1.0));

    println!("{:<30} {:10.6} {:10.6} {:10.6}", "fit road 1  a, A, B", a1, aa1, bb1);
    println!("{:<30} {:10.6} {:10.6} {:10.6}", "fit road 2  a, A, B", a2, aa2, bb2);
    row("level L = e^a", l);
    row("amplitude beta", beta);
    println!("{:<30} {:10.4}  = month {:.2}", "peak t0, years from 1 Apr", t0, 12.0 * t0);
    row("winter/summer shape ratio", (2.0 * beta).exp());
    println!("month   strip    fit   miss");
    for m in 0..12 {
        println!("{:<5} {:7.2} {:6.2} {:+6.2}", MONTHS[m], STRIP[m], fit[m], STRIP[m] - fit[m]);
    }
    let miss = (0..12).map(|m| (STRIP[m] - fit[m]).abs()).fold(0.0, f64::max);
    row("largest miss", miss);
    row("fitted Jul -> Jan spread", fitted_spread);
    println!("{:<30} {:10.4} {:10.4}", "quoted spreads, high and low", FW - FS, fw_low - FS);
    row("growth e^(r tau), July -> Jan", (R * tau).exp());
    row("July 2.50 grown to January", FS * (R * tau).exp());
    row("interest on July gas", FS * ((R * tau).exp() - 1.0));
    row("cap road 1  formula", cap1);
    row("cap road 2  cash flows+search", cap2);
    row("January break-even price", FS + cap1);
    row("spread 1.00: profit in Jan", profit_jan);
    row("spread 1.00: value today", profit_pv);
    println!("{:<30} {:10.0}", "  x 1,000,000 MMBtu, in Jan", profit_jan * 1e6);
    row("spread 0.30: storage trade", loss_low);
    println!("{:<30} {} -> {}  {:.4}", "best cycle on the strip", MONTHS[best.1], MONTHS[best.2], best.0);
    row("wrong: no interest, cap", C);
    row("wrong: storage fee only, cap", 0.50 + FS * ((R * tau).exp() - 1.0));
    row("wrong: reverse trade on 0.30", phantom);
    println!("{:<30} {:10.4} {:10.4}", "try: level x 1.2, spread, cap", 1.2 * (FW - FS), C + 1.2 * FS * ((R * tau).exp() - 1.0));
    row("try: level x 1.2, profit Jan", level_up);
    row("try: r = 10%, cap", C + FS * ((0.10 * tau).exp() - 1.0));
    row("try: c = 1.10, spread 1.00 P&L", FW - FS * (R * tau).exp() - 1.10);
    let grid: Vec<f64> = (0..9).map(|k| 2.8 + 0.1 * k as f64).collect();
    let fmt = |f: &dyn Fn(f64) -> f64| grid.iter().map(|w| format!("{:5.2}", f(*w))).collect::<Vec<_>>().join(" ");
    println!("chart, Jan price  {}", fmt(&|w| w));
    println!("chart, trade P&L  {}", fmt(&|w| w - FS - cap1));
    println!("chart, take-it    {}", fmt(&|w| (w - FS - cap1).max(0.0)));

    let fit_gap = [(a1, a2), (aa1, aa2), (bb1, bb2)].iter().map(|(u, v)| (u - v).abs()).fold(0.0, f64::max);
    assert!(fit_gap < 1e-12, "two fits agree");
    assert!((cap1 - cap2).abs() < 1e-9, "formula cap equals the searched break-even");
    assert!((profit_pv * (R * TW).exp() - profit_jan).abs() < 1e-12, "today's value grows to the January profit");
    assert!((best.1, best.2) == (3, 9), "the best cycle on the strip is the summer-to-winter one");
    let form_gap = (0..12).map(|m| ((a1 + aa1 * th[m].cos() + bb1 * th[m].sin()).exp() - fit[m]).abs()).fold(0.0, f64::max);
    assert!(form_gap < 1e-12, "legs form equals level-and-peak form");
    assert!(fw_low - FS < cap2 && cap2 < FW - FS, "0.30 sits under the searched cap, 1.00 over it");
    println!("ALL CHECKS PASS");
}
