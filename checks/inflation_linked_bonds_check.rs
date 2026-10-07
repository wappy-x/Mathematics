// Inflation-linked bond -- the check behind the card.  Rust std only, no crates.
// The 10-year linker: 1% real coupon, dated 15 Jul 2026, settles 31 Jul 2026 at a 1.02% real yield.
// Index levels are invented for teaching; the rules are the US Treasury's (31 CFR 356, Appendix B).
fn ref_cpi(m0: i64, m1: i64, day: i64, days: i64) -> i64 {
    // CPI levels in thousandths.  Road 1: the interpolation formula.  Road 2: walk one day at a time.
    let formula = m0 * days + (day - 1) * (m1 - m0);
    let mut walk = m0 * days;
    for _ in 1..day {
        walk += m1 - m0;
    }
    assert_eq!(walk, formula);
    let six = formula * 1000 / days; // truncate to six decimals
    (six + 5) / 10 // round to five: result in units of 0.00001
}
fn index_ratio(reference: i64, base: i64) -> i64 {
    let six = reference * 1_000_000 / base;
    (six + 5) / 10
}
fn days_from_civil(y: i64, m: i64, d: i64) -> i64 {
    // day count since 1 Mar 0000, month by month -- a second road to the calendar
    let (y, m) = if m <= 2 { (y - 1, m + 12) } else { (y, m) };
    365 * y + y / 4 - y / 100 + y / 400 + (153 * (m - 3) + 2) / 5 + d
}
fn price_closed(c: f64, i: f64, n: i32, r: f64, s: f64) -> (f64, f64) {
    let v = 1.0 / (1.0 + i / 2.0);
    let an = if i != 0.0 { (1.0 - v.powi(n)) / (i / 2.0) } else { n as f64 };
    let whole = (c / 2.0 + (c / 2.0) * an + 100.0 * v.powi(n)) / (1.0 + (r / s) * (i / 2.0));
    let accrued = (s - r) / s * (c / 2.0);
    (whole - accrued, accrued)
}
fn cash(c: f64, k: i32, n: i32) -> f64 {
    c / 2.0 + if k == n { 100.0 } else { 0.0 }
}
fn dirty_by_sum(c: f64, i: f64, n: i32, r: f64, s: f64) -> f64 {
    let stub = 1.0 + (r / s) * (i / 2.0);
    (0..=n).map(|k| cash(c, k, n) / (stub * (1.0 + i / 2.0).powi(k))).sum()
}
fn ddirty_dy(c: f64, i: f64, n: i32, r: f64, s: f64) -> f64 {
    let stub = 1.0 + (r / s) * (i / 2.0);
    let mut total = 0.0;
    for k in 0..=n {
        let rate = (r / s) / 2.0 / stub + k as f64 / 2.0 / (1.0 + i / 2.0);
        total -= cash(c, k, n) * rate / (stub * (1.0 + i / 2.0).powi(k));
    }
    total
}
fn yield_bisect(target: f64, c: f64, n: i32, r: f64, s: f64) -> f64 {
    let (mut lo, mut hi) = (-0.5, 0.5);
    for _ in 0..200 {
        let mid = (lo + hi) / 2.0;
        if price_closed(c, mid, n, r, s).0 > target { lo = mid } else { hi = mid }
    }
    (lo + hi) / 2.0
}
fn yield_newton(target: f64, c: f64, n: i32, r: f64, s: f64) -> f64 {
    let mut y = 0.05;
    for _ in 0..50 {
        let acc = price_closed(c, y, n, r, s).1;
        y -= (dirty_by_sum(c, y, n, r, s) - acc - target) / ddirty_dy(c, y, n, r, s);
    }
    y
}
fn row(label: &str, v: f64, d: usize) {
    println!("{:<44} {:.*}", label, d, v);
}
fn main() {
    // ---- road 0: Treasury's own published examples, reproduced to six decimals ----
    let t_ref = ref_cpi(154400, 154900, 15, 30);
    let t_ratio = index_ratio(ref_cpi(154400, 154900, 16, 30), t_ref);
    let t_p1 = price_closed(3.875, 0.03898, 19, 181.0, 181.0).0;
    let (t_p2, t_a2) = price_closed(3.625, 0.0365, 18, 92.0, 184.0);
    let r6 = |x: f64| (x * 1e6).round() / 1e6;
    let t_sa2 = r6(r6(t_p2) * 1.01074) + r6(t_a2 * 1.01074);
    assert_eq!((t_ref, t_ratio), (15463333, 100011));
    assert!((t_p1 - 99.811030).abs() < 5e-7 && (t_p2 - 99.797017).abs() < 5e-7);
    assert!((t_sa2 - 101.784820).abs() < 2e-6);

    // ---- the 10-year linker ----
    let base = ref_cpi(320000, 320930, 15, 31);
    let settle = ref_cpi(320000, 320930, 31, 31);
    let jan = ref_cpi(324000, 324310, 15, 31);
    let (i_s, i_jan) = (index_ratio(settle, base) as f64 / 1e5, index_ratio(jan, base) as f64 / 1e5);
    assert_eq!((base, settle, jan, index_ratio(settle, base), index_ratio(jan, base)), (32042000, 32090000, 32414000, 100150, 101161));
    let s = (days_from_civil(2027, 1, 15) - days_from_civil(2026, 7, 15)) as f64;
    let r = (days_from_civil(2027, 1, 15) - days_from_civil(2026, 7, 31)) as f64;
    let n = 19;
    let (c, y, face) = (1.0, 0.0102, 10.0);
    let (clean, accrued) = price_closed(c, y, n, r, s);
    let dirty = dirty_by_sum(c, y, n, r, s);
    let invoice = face * i_s * dirty;
    assert!((clean + accrued - dirty).abs() < 1e-11);

    // ---- the inverse: quoted real price in, real yield out, two root finders ----
    let y_b = yield_bisect(clean, c, n, r, s);
    let y_n = yield_newton(clean, c, n, r, s);
    assert!((y_b - y).abs() < 1e-12 && (y_n - y).abs() < 1e-12);

    // ---- road 3: nominal cashflows, inflation at the breakeven, nominal yield by Fisher ----
    let nominal_road = |pi: f64| -> (f64, f64, f64) {
        let g = (1.0 + pi).sqrt();
        let zn = (1.0 + y / 2.0) * g;
        let stub = (1.0 + (r / s) * (y / 2.0)) * g.powf(r / s);
        let pv: f64 = (0..=n)
            .map(|k| cash(c, k, n) * i_s * g.powf(r / s + k as f64) / (stub * zn.powi(k)))
            .sum();
        (face * pv, 2.0 * (zn - 1.0), i_s * g.powf(r / s + n as f64))
    };
    let (nom_pv, nom_yield, final_ratio) = nominal_road(0.025);
    let nom_pv_hi = nominal_road(0.035).0;
    assert!((nom_pv - invoice).abs() < 1e-9 && (nom_pv_hi - invoice).abs() < 1e-9);

    // ---- sensitivities, by calculus and by bumping ----
    let dv01 = -face * i_s * ddirty_dy(c, y, n, r, s) * 1e-4;
    let dv01_bump = face * i_s * (dirty_by_sum(c, y - 1e-4, n, r, s) - dirty_by_sum(c, y + 1e-4, n, r, s)) / 2.0;
    assert!((dv01 - dv01_bump).abs() < 1e-6);

    // ---- what breaks ----
    let no_ratio = face * dirty;
    let jan_ratio = face * i_jan * dirty;
    let real_at_nominal = face * i_s * dirty_by_sum(c, nom_yield, n, r, s);
    let g = 1.025f64.sqrt();
    let nominal_at_real: f64 = face * i_s * (0..=n)
        .map(|k| cash(c, k, n) * g.powf(r / s + k as f64) / ((1.0 + (r / s) * (y / 2.0)) * (1.0 + y / 2.0).powi(k)))
        .sum::<f64>();
    let street: f64 = face * i_s * (0..=n).map(|k| cash(c, k, n) / (1.0 + y / 2.0).powf(r / s + k as f64)).sum::<f64>();

    row("treasury 1996 ref CPI, 15 Apr", t_ref as f64 / 1e5, 5);
    row("treasury 1996 index ratio, 16 Apr", t_ratio as f64 / 1e5, 5);
    row("treasury 1999 real price", t_p1, 6);
    row("treasury 1998 real price", t_p2, 6);
    row("treasury 1998 settlement amount", t_sa2, 6);
    row("ref CPI 15 Jul 2026 (base)", base as f64 / 1e5, 5);
    row("ref CPI 31 Jul 2026 (settlement)", settle as f64 / 1e5, 5);
    row("ref CPI 15 Jan 2027 (first coupon)", jan as f64 / 1e5, 5);
    row("index ratio 31 Jul 2026", i_s, 5);
    row("index ratio 15 Jan 2027", i_jan, 5);
    println!("{:<44} {} {} {}", "days in period s, days to coupon r, n", s, r, n);
    row("real coupon per half-year, per $1,000", face * c / 2.0, 2);
    row("first coupon paid, per $1,000", face * c / 2.0 * i_jan, 5);
    row("1 real clean price per 100, closed form", clean, 6);
    row("  real accrued per 100", accrued, 6);
    row("2 real dirty per 100, cashflow by cashflow", dirty, 6);
    row("invoice per $1,000 = 10 x ratio x dirty", invoice, 4);
    row("  nominal clean per $1,000", face * i_s * clean, 4);
    row("  nominal accrued per $1,000", face * i_s * accrued, 4);
    row("yield from price, bisection (%)", 100.0 * y_b, 10);
    row("yield from price, Newton (%)", 100.0 * y_n, 10);
    row("3 nominal road: PV at 2.5% breakeven", nom_pv, 4);
    row("  nominal yield by Fisher (%)", 100.0 * nom_yield, 4);
    row("  same, breakeven 3.5%", nom_pv_hi, 4);
    row("  projected final index ratio", final_ratio, 5);
    row("  projected final principal", 1000.0 * final_ratio, 2);
    row("real DV01 per $1,000, calculus", dv01, 4);
    row("real DV01 per $1,000, bump", dv01_bump, 4);
    row("real modified duration (years)", dv01 / invoice * 1e4, 4);
    row("invoice change per 0.01 of index ratio", face * dirty * 0.01, 4);
    row("wrong: no index ratio", no_ratio, 4);
    row("wrong: coupon-date ratio 1.01161", jan_ratio, 4);
    row("wrong: real cashflows at nominal yield", real_at_nominal, 4);
    row("wrong: nominal cashflows at real yield", nominal_at_real, 4);
    row("convention: compound stub instead of simple", street, 4);
    row("floor: principal if final ratio 0.95", 1000.0 * 0.95f64.max(1.0), 2);
    row("  without the floor", 1000.0 * 0.95, 2);
    println!("payoff: principal at final ratio 0.90 to 1.40, step 0.05");
    let pay: Vec<String> = (0..11).map(|k| format!("{:.2}", 1000.0 * (0.90 + 0.05 * k as f64).max(1.0))).collect();
    println!("{}", pay.join(" "));
    println!("price curve: real clean per 100 at yield -1.0% to 3.0%, step 0.5%");
    let curve: Vec<String> = (0..9).map(|k| format!("{:.2}", price_closed(c, -0.01 + 0.005 * k as f64, n, r, s).0)).collect();
    println!("{}", curve.join(" "));
}
