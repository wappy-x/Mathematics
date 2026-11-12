// Linear interpolation and extrapolation -- the check behind the card.  std only, no crates.
// Illustrative tide: height H = 2.5 + 1.8 cos(w (t - 6 - 0.1 x)) metres above chart datum, t hours
// after midnight, x km up the estuary from the harbour-mouth gauge, w = 2 pi / 12.42 radians an hour.
// Road 1: the exact curve.  Road 2: the line through two readings, built two ways.  Road 3: the error
// against the bound M h^2 / 8, the point xi of the error formula, and the observed order as h shrinks.
// Then bilinear interpolation three ways, extrapolation past 10 am, and an eight-quote yield curve.
const PI: f64 = 3.141592653589793;
const W: f64 = 2.0 * PI / 12.42;

fn cos(z0: f64) -> f64 {
    // written out with + - * / only, so Python and Rust agree to the bit; f64::cos is only a cross-check
    let mut z = z0;
    while z > PI { z -= 2.0 * PI; }
    while z < -PI { z += 2.0 * PI; }
    z = z.abs();
    let mut sign = 1.0;
    if z > PI / 2.0 { z = PI - z; sign = -1.0; }
    let (mut term, mut total) = (1.0f64, 1.0f64);
    for k in 1..20 {
        term = -term * z * z / (((2 * k - 1) * (2 * k)) as f64);
        total += term;
    }
    sign * total
}
fn h(t: f64, x: f64) -> f64 { 2.5 + 1.8 * cos(W * (t - 6.0 - 0.1 * x)) }
fn h2(t: f64) -> f64 { -1.8 * W * W * cos(W * (t - 6.0)) } // d2H/dt2 at the mouth; d2H/dx2 is 0.01 times it
fn m(t1: f64, t2: f64, x1: f64, x2: f64) -> f64 {
    // largest |d2H/dt2| over the box: |cos| peaks at an end of the phase range, or at 0 or pi
    let (p, q) = (W * (t1 - 6.0 - 0.1 * x2), W * (t2 - 6.0 - 0.1 * x1));
    let c = if (p <= PI && PI <= q) || (p <= 0.0 && 0.0 <= q) { 1.0 } else { cos(p).abs().max(cos(q).abs()) };
    1.8 * W * W * c
}
fn line(t: f64, a: f64, b: f64, ha: f64, hb: f64) -> f64 { let s = (t - a) / (b - a); (1.0 - s) * ha + s * hb }
fn slope_form(t: f64, a: f64, b: f64, ha: f64, hb: f64) -> f64 { ha + (t - a) * ((hb - ha) / (b - a)) }
fn d2(f: &dyn Fn(f64) -> f64, u: f64) -> f64 { let d = 1e-3; (f(u + d) - 2.0 * f(u) + f(u - d)) / (d * d) } // H'' by another road
fn grid_max(lo: f64, hi: f64) -> f64 { (0..=400).map(|i| d2(&|u| h(u, 0.0), lo + (hi - lo) * i as f64 / 400.0).abs()).fold(0.0, f64::max) }
fn e(x: f64, d: usize) -> String {
    // Python-style e-notation: 1.14e-02
    let s = format!("{:.*e}", d, x);
    let (mant, ex) = s.split_once('e').unwrap();
    let n: i32 = ex.parse().unwrap();
    format!("{}e{}{:02}", mant, if n < 0 { '-' } else { '+' }, n.abs())
}
fn commas(x: f64) -> String {
    let s = format!("{:.0}", x);
    let mut out = String::new();
    for (i, ch) in s.chars().enumerate() {
        if i > 0 && (s.len() - i) % 3 == 0 { out.push(','); }
        out.push(ch);
    }
    out
}
fn join(v: &[f64], f: &dyn Fn(f64) -> String) -> String { v.iter().map(|&x| f(x)).collect::<Vec<_>>().join(", ") }

fn main() {
    assert!((-700..=700).all(|i| (cos(0.01 * i as f64) - (0.01 * i as f64).cos()).abs() < 1e-14));
    let (a, b, t) = (9.0, 10.0, 9.0 + 1.0 / 3.0);
    let (ha, hb) = (h(a, 0.0), h(b, 0.0));
    println!("readings: 9 am {:.4} m, 10 am {:.4} m; slope {:.4} m per hour; w = {:.6}", ha, hb, (hb - ha) / (b - a), W);
    let (l, l2, tr) = (line(t, a, b, ha, hb), slope_form(t, a, b, ha, hb), h(t, 0.0));
    let (err, mab) = (tr - l, m(a, b, 0.0, 0.0));
    let (bt, bh) = (mab / 2.0 * (t - a) * (b - t), mab * ((b - a) * (b - a)) / 8.0);
    println!("9:20 am: line {:.4} m (slope form {:.4}), true {:.4} m, true error H - L {:.4} m", l, l2, tr, err);
    println!("ceiling M on [9, 10] {:.4} m/h^2; bound M/2 (t-a)(b-t) {:.4}, M h^2/8 {:.4}; bound over |error| {:.2}", mab, bt, bh, bt / err.abs());
    assert!((l - l2).abs() < 1e-15 && err.abs() <= bt && bt <= bh && (tr - 2.2925).abs() < 1e-4);
    assert!([a, 9.5, b].iter().all(|&u| (h2(u) - d2(&|v| h(v, 0.0), u)).abs() < 1e-5) && (mab - grid_max(a, b)).abs() < 1e-5);
    let c = 2.0 * err / ((t - a) * (t - b));
    let (mut lo, mut hi) = (a, b);
    for _ in 0..60 {
        let mid = (lo + hi) / 2.0;
        if h2(mid) < c { lo = mid; } else { hi = mid; }
    }
    println!("error formula: 2 e / ((t-a)(t-b)) = {:.6} = H''(xi) at xi = {:.4} h, inside [9, 10]; H'' runs {:.4} to {:.4}", c, lo, h2(a), h2(b));
    assert!(h2(a) < c && c < h2(b) && a < lo && lo < b);
    println!("at 9:30: true error {:.5} m; estimate -H''(9.5)/8 = {:.5} m", h(9.5, 0.0) - line(9.5, a, b, ha, hb), -h2(9.5) / 8.0);
    assert!((-h2(9.5) / 8.0 / (h(9.5, 0.0) - line(9.5, a, b, ha, hb)) - 1.0).abs() < 0.01);
    let mut errs = Vec::new();
    for k in 0..13 {
        let w = 0.25f64.powi(k);
        errs.push(h(9.5, 0.0) - line(9.5, 9.5 - w / 2.0, 9.5 + w / 2.0, h(9.5 - w / 2.0, 0.0), h(9.5 + w / 2.0, 0.0)));
    }
    let orders: Vec<f64> = (0..8).map(|k| (errs[k] / errs[k + 1]).abs().ln() / 4f64.ln()).collect();
    println!("order: true error at 9:30 for h = 4^-k, k = 0..12: {}", join(&errs[..7], &|x| e(x, 2)));
    println!("       {}; observed order k=0..7 {}", join(&errs[7..], &|x| e(x, 2)), join(&orders, &|o| format!("{:.2}", o)));
    let hs: Vec<f64> = (0..9).map(|k| 0.25f64.powi(k)).collect();
    println!("chart, log10 h: {}; log10 |error|: {}", join(&hs, &|w| format!("{:.2}", w.log10())), join(&errs[..9], &|x| format!("{:.2}", x.abs().log10())));
    assert!(orders.iter().all(|o| (o - 2.0).abs() < 0.01) && errs[12].abs() < 1e-14);

    println!("extrapolating the 9-10 am line: t, line, true, true error, factor (t-9)(t-10), bound M[9,t]/2 x factor, ratio");
    for tt in [10.5, 11.0, 12.0, 13.0] {
        let (lt, ttv) = (line(tt, a, b, ha, hb), h(tt, 0.0));
        let bd = m(a, tt, 0.0, 0.0) / 2.0 * (tt - a) * (tt - b);
        println!("  {:5.2} h: {:7.4} m, {:.4} m, {:.4} m, {:5.2}, {:.4} m, {:.2}", tt, lt, ttv, ttv - lt, (tt - a) * (tt - b), bd, bd / (ttv - lt).abs());
        assert!((ttv - lt).abs() <= bd && (m(a, tt, 0.0, 0.0) - grid_max(a, tt)).abs() < 1e-5);
    }
    assert!(line(13.0, a, b, ha, hb) < 0.0 && 0.0 < h(13.0, 0.0) && (h(13.0, 0.0) - line(13.0, a, b, ha, hb)).abs() > 100.0 * err.abs());
    let w13 = (1.0 - (13.0 - a) / (b - a), (13.0 - a) / (b - a)); // the line's two weights at 1 pm
    println!("weights at 13 h: {:.2} and {:.2}; reading errors d move the line by up to {:.2} d", w13.0, w13.1, w13.0.abs() + w13.1.abs());
    assert!((line(13.0, a, b, ha + 1e-3, hb - 1e-3) - line(13.0, a, b, ha, hb) + (w13.0.abs() + w13.1.abs()) * 1e-3).abs() < 1e-12);
    let grid: Vec<f64> = (0..17).map(|i| 6.0 + 0.5 * i as f64).collect();
    println!("chart, true tide 6 am to 2 pm by half hours: {}", join(&grid, &|g| format!("{:.2}", h(g, 0.0))));
    println!("chart, the 9-10 am line extended: {}", join(&grid, &|g| format!("{:.2}", line(g, a, b, ha, hb))));

    let (x0, x1, x) = (0.0, 6.0, 2.0);
    let cc = [[h(a, x0), h(a, x1)], [h(b, x0), h(b, x1)]];
    let (s, r) = ((t - a) / (b - a), (x - x0) / (x1 - x0));
    let b1 = line(x, x0, x1, line(t, a, b, cc[0][0], cc[1][0]), line(t, a, b, cc[0][1], cc[1][1]));
    let b2 = line(t, a, b, line(x, x0, x1, cc[0][0], cc[0][1]), line(x, x0, x1, cc[1][0], cc[1][1]));
    let b3 = (1.0 - s) * (1.0 - r) * cc[0][0] + (1.0 - s) * r * cc[0][1] + s * (1.0 - r) * cc[1][0] + s * r * cc[1][1];
    let (t2, mt) = (h(t, x), m(a, b, x0, x1));
    let mx = 0.01 * mt; // distance enters the phase times 0.1, so its bend is 0.01 times
    let bound2 = mt / 2.0 * (t - a) * (b - t) + mx / 2.0 * (x - x0) * (x1 - x);
    let bound8 = (mt * ((b - a) * (b - a)) + mx * ((x1 - x0) * (x1 - x0))) / 8.0; // the formula's whole-box form
    println!("corners: mouth {:.4}, {:.4}; quay {:.4}, {:.4} m at 9 and 10 am; s = r = 1/3", cc[0][0], cc[1][0], cc[0][1], cc[1][1]);
    println!("bilinear at 9:20, 2 km: time first {:.4}, distance first {:.4}, four weights {:.4}; true {:.4}; true error {:.4} m", b1, b2, b3, t2, t2 - b3);
    println!("ceilings: |H_tt| {:.4}, |H_xx| {:.6}; bound {:.4} m, box form {:.4} m; bound over |error| {:.2}", mt, mx, bound2, bound8, bound2 / (t2 - b3).abs());
    assert!((b1 - b2).abs() < 1e-14 && (b1 - b3).abs() < 1e-14 && (t2 - b3).abs() <= bound2 && bound2 <= bound8);
    let bx: Vec<(f64, f64)> = (0..=50).flat_map(|i| (0..=50).map(move |j| (a + i as f64 / 50.0, x0 + (x1 - x0) * j as f64 / 50.0))).collect();
    let mt_grid = bx.iter().map(|&(p, q)| d2(&|u| h(u, q), p).abs()).fold(0.0, f64::max);
    let mx_grid = bx.iter().map(|&(p, q)| d2(&|v| h(p, v), q).abs()).fold(0.0, f64::max);
    assert!((mt - mt_grid).abs() < 1e-5 && (mx - mx_grid).abs() < 1e-7);
    println!("cost: weights form 3 + 4 = 7 flops a reading; slope form 3, once the slope (3 flops) is stored; bilinear 3 readings, 21 flops");

    println!("mistake, nearest reading (9 am): {:.4} m, error {:.4}", ha, tr - ha);
    println!("mistake, 20 minutes as s = 0.20: {:.4} m, error {:.4}", line(9.2, a, b, ha, hb), tr - line(9.2, a, b, ha, hb));
    println!("mistake, weights swapped: {:.4} m, error {:.4}", s * ha + (1.0 - s) * hb, tr - (s * ha + (1.0 - s) * hb));
    let avg4 = (cc[0][0] + cc[0][1] + cc[1][0] + cc[1][1]) / 4.0;
    println!("mistake, plain average of four corners: {:.4} m, error {:.4}", avg4, t2 - avg4);

    let mats = [1.0, 2.0, 3.0, 5.0, 7.0, 10.0, 20.0, 30.0];
    let ylds = [4.10, 3.95, 3.90, 3.95, 4.05, 4.20, 4.60, 4.40];
    let curve = |mm: f64, flat_end: bool| -> f64 {
        if mm >= 30.0 && flat_end { return ylds[7]; }
        let j = if mm < 30.0 { (0..7).filter(|&i| mats[i] <= mm).max().unwrap() } else { 6 };
        line(mm, mats[j], mats[j + 1], ylds[j], ylds[j + 1])
    };
    assert!(mats.iter().zip(ylds.iter()).all(|(&mm, &y)| [true, false].iter().all(|&f| (curve(mm, f) - y).abs() < 1e-12)));
    let pv = |y: f64, n: usize| -> f64 { let mut d = 1.0; for _ in 0..n { d = d / (1.0 + y / 100.0); } 1e6 * d };
    let (y50a, y50b) = (curve(50.0, false), curve(50.0, true));
    println!("yield curve: 4 years {:.3}%, 15 years {:.3}%; both rules hit all 8 quotes", curve(4.0, false), curve(15.0, false));
    println!("50 years: line through 20 and 30 extended {:.3}%, flat after 30 {:.3}%", y50a, y50b);
    println!("$1,000,000 due in 50 years: worth ${} or ${} today; gap ${}", commas(pv(y50a, 50)), commas(pv(y50b, 50)), commas(pv(y50a, 50) - pv(y50b, 50)));
    assert!((y50a - 4.0).abs() < 1e-12 && (pv(4.0, 50) - 1e6 / 1.04f64.powi(50)).abs() < 1e-6 && pv(y50a, 50) > pv(y50b, 50));
    println!("ALL CHECKS PASS");
}
