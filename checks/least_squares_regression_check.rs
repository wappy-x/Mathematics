// Least squares regression -- the same check as least_squares_regression_check.py, in Rust.
// Std only, no crates.  Six house sales, three roads to the line (centred sums, raw-sum
// normal equations by Cramer's rule, blind golden-section search), then 2,000 simulated
// markets of 50 sales from the same SplitMix64 stream as the Python.
// Compile: rustc --edition 2021 -O least_squares_regression_check.rs -o /tmp/lsq_check
const AREA: [f64; 6] = [60.0, 70.0, 90.0, 110.0, 130.0, 140.0];
const PRICE: [f64; 6] = [165000.0, 205000.0, 229000.0, 267000.0, 327000.0, 337000.0];

// road 1: slope = S_xy / S_xx, line through the mean point
fn centred(xs: &[f64], ys: &[f64]) -> (f64, f64, f64, f64, f64, f64, f64) {
    let n = xs.len() as f64;
    let xb = xs.iter().sum::<f64>() / n;
    let yb = ys.iter().sum::<f64>() / n;
    let (mut sxx, mut sxy, mut syy) = (0.0, 0.0, 0.0);
    for x in xs { sxx += (x - xb) * (x - xb); }
    for (x, y) in xs.iter().zip(ys) { sxy += (x - xb) * (y - yb); }
    for y in ys { syy += (y - yb) * (y - yb); }
    let b = sxy / sxx;
    (xb, yb, sxx, sxy, syy, yb - b * xb, b)
}

// road 2: n a + (sum x) b = sum y ; (sum x) a + (sum x^2) b = sum xy, solved by Cramer's rule
fn raw(xs: &[f64], ys: &[f64]) -> (f64, f64, f64) {
    let n = xs.len() as f64;
    let sx: f64 = xs.iter().sum();
    let sy: f64 = ys.iter().sum();
    let (mut sxx, mut sxy) = (0.0, 0.0);
    for x in xs { sxx += x * x; }
    for (x, y) in xs.iter().zip(ys) { sxy += x * y; }
    let det = n * sxx - sx * sx;
    ((sy * sxx - sx * sxy) / det, (n * sxy - sx * sy) / det, sxy / sxx)
}

fn sse(a: f64, b: f64, xs: &[f64], ys: &[f64]) -> f64 {
    let mut s = 0.0;
    for (x, y) in xs.iter().zip(ys) { s += (y - a - b * x) * (y - a - b * x); }
    s
}

// shrink a bracket around the bottom of a one-dip curve
fn golden<F: Fn(f64) -> f64>(f: F, mut lo: f64, mut hi: f64) -> f64 {
    let g = (5.0_f64.sqrt() - 1.0) / 2.0;
    let (mut c, mut d) = (hi - g * (hi - lo), lo + g * (hi - lo));
    let (mut fc, mut fd) = (f(c), f(d));
    for _ in 0..90 {
        if fc < fd { hi = d; d = c; fd = fc; c = hi - g * (hi - lo); fc = f(c); }
        else { lo = c; c = d; fc = fd; d = lo + g * (hi - lo); fd = f(d); }
    }
    (lo + hi) / 2.0
}

// road 3: no formula, only "try a line, score its misses"
fn search(xs: &[f64], ys: &[f64]) -> (f64, f64) {
    let best_a = |b: f64| golden(|a| sse(a, b, xs, ys), -1e6, 1e6);
    let b = golden(|b| sse(best_a(b), b, xs, ys), -1e4, 1e4);
    (best_a(b), b)
}

struct SplitMix(u64);
impl SplitMix {
    fn next(&mut self) -> u64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    }
    fn normal(&mut self) -> f64 { // Box-Muller
        let u1 = ((self.next() >> 11) as f64 + 0.5) / 2f64.powi(53);
        let u2 = ((self.next() >> 11) as f64 + 0.5) / 2f64.powi(53);
        (-2.0 * u1.ln()).sqrt() * (2.0 * std::f64::consts::PI * u2).cos()
    }
}

fn main() {
    let (xb, yb, sxx, sxy, syy, a1, b1) = centred(&AREA, &PRICE);
    let (a2, b2, b_origin) = raw(&AREA, &PRICE);
    let (a3, b3) = search(&AREA, &PRICE);
    let fit: Vec<f64> = AREA.iter().map(|x| a1 + b1 * x).collect();
    let res: Vec<f64> = PRICE.iter().zip(&fit).map(|(y, f)| y - f).collect();
    let sse1 = sse(a1, b1, &AREA, &PRICE);
    let r = sxy / (sxx * syy).sqrt();
    let explained: f64 = fit.iter().map(|f| (f - yb) * (f - yb)).sum();
    let se_b = (sse1 / (AREA.len() as f64 - 2.0)).sqrt() / sxx.sqrt();

    println!("sale  area  price     d_x   d_y(k)  product(k)  fitted    residual");
    for i in 0..6 {
        let (x, y) = (AREA[i], PRICE[i]);
        println!("{:>4} {:5.0} {:8.0} {:6.0} {:7.0} {:10.0} {:9.0} {:9.0}", i + 1, x, y, x - xb,
                 (y - yb) / 1000.0, (x - xb) * (y - yb) / 1000.0, fit[i], res[i]);
    }
    let n = AREA.len() as f64;
    let rows: Vec<(&str, f64)> = vec![
        ("mean area (m2)", xb), ("mean price ($)", yb), ("S_xx (m2^2)", sxx),
        ("S_xy ($ m2)", sxy), ("S_yy ($^2)", syy),
        ("Cov(area, price), divide by n", sxy / n), ("Var(area), divide by n", sxx / n),
        ("1 slope, centred sums", b1), ("  intercept", a1),
        ("2 slope, raw normal equations", b2), ("  intercept", a2),
        ("3 slope, golden search", b3), ("  intercept", a3),
        ("SSE at the fit ($^2)", sse1), ("SSE at the searched line", sse(a3, b3, &AREA, &PRICE)),
        ("sum of residuals", res.iter().sum()),
        ("sum of residual x area", res.iter().zip(&AREA).map(|(e, x)| e * x).sum()),
        ("explained, S_xy^2 / S_xx ($^2)", sxy * sxy / sxx),
        ("R^2 = 1 - SSE/S_yy", 1.0 - sse1 / syy), ("R^2 = explained/S_yy", explained / syy),
        ("r, correlation", r), ("r^2", r * r), ("standard error of slope", se_b),
        ("wrong: area on price, inverted", syy / sxy), ("wrong: no intercept", b_origin),
        ("wrong: two end houses only", (PRICE[5] - PRICE[0]) / (AREA[5] - AREA[0])),
        ("wrong: flat line, residual sum", PRICE.iter().map(|y| y - yb).sum()), ("  flat line SSE", syy),
    ];
    for (name, v) in &rows { println!("{:<32} {:>18.4}", name, v); }

    // ---- try changing ----
    let ft2: Vec<f64> = AREA.iter().map(|x| x * 10.7639).collect();
    let (_, _, _, _, syy_f, a_f, b_f) = centred(&ft2, &PRICE);
    let mut big = PRICE.to_vec(); big[5] = 437000.0;
    let (_, _, _, _, _, a_m, b_m) = centred(&AREA, &big);
    let up: Vec<f64> = PRICE.iter().map(|y| y + 20000.0).collect();
    let (_, _, _, _, _, a_u, b_u) = centred(&AREA, &up);
    println!("try: square feet, slope {:.2}  R^2 {:.5}", b_f, 1.0 - sse(a_f, b_f, &ft2, &PRICE) / syy_f);
    println!("try: last house $437,000, slope {:.2}  intercept {:.2}", b_m, a_m);
    println!("try: every price +$20,000, slope {:.2}  intercept {:.2}", b_u, a_u);

    // ---- the figure: x px = 40 + 3 (area - 50), y px = 220 - (price - 150,000) / 1,000 ----
    let px = |x: f64| 40.0 + 3.0 * (x - 50.0);
    let py = |y: f64| 220.0 - (y - 150000.0) / 1000.0;
    let pts: Vec<String> = AREA.iter().zip(&PRICE).map(|(x, y)| format!("({:.0},{:.0})", px(*x), py(*y))).collect();
    println!("figure, points {}", pts.join(" "));
    let ends: Vec<String> = [55.0, 145.0].iter().map(|x| format!("({:.0},{:.1})", px(*x), py(a1 + b1 * x))).collect();
    let fy: Vec<String> = fit.iter().map(|f| format!("{:.0}", py(*f))).collect();
    println!("figure, line   {} fitted {} mean ({:.0},{:.0})", ends.join(" "), fy.join(" "), px(xb), py(yb));

    // ---- 2,000 simulated markets, 50 sales each: true line 45,000 + 2,100 area, noise sd 25,000 ----
    let mut rng = SplitMix(2026092801);
    let areas: Vec<f64> = (0..50).map(|_| 50.0 + (rng.next() % 101) as f64).collect();
    let (mut slopes, mut bins, mut sx50) = (Vec::new(), [0u32; 8], 0.0);
    for m in 0..2000 {
        let prices: Vec<f64> = areas.iter().map(|x| 45000.0 + 2100.0 * x + 25000.0 * rng.normal()).collect();
        let (_, _, sx, _, sy50, a50, b50) = centred(&areas, &prices);
        sx50 = sx;
        if m == 0 {
            let s50 = sse(a50, b50, &areas, &prices);
            println!("market 1: slope {:.2}  intercept {:.2}  R^2 {:.4}  se {:.2}", b50, a50,
                     1.0 - s50 / sy50, (s50 / 48.0).sqrt() / sx.sqrt());
        }
        slopes.push(b50);
        bins[(((b50 - 1700.0) / 100.0).floor().max(0.0) as usize).min(7)] += 1;
    }
    let mean_b = slopes.iter().sum::<f64>() / 2000.0;
    let sd_b = (slopes.iter().map(|s| (s - mean_b) * (s - mean_b)).sum::<f64>() / 1999.0).sqrt();
    let theory = 25000.0 / sx50.sqrt();
    println!("2000 markets: mean slope {:.2}  se of mean {:.2}  spread {:.2}  theory {:.2}",
             mean_b, sd_b / 2000f64.sqrt(), sd_b, theory);
    let b: Vec<String> = bins.iter().map(|c| c.to_string()).collect();
    println!("figure, slope bins 1700..2500 by 100: {}", b.join(" "));

    assert!((b1 - 2100.0).abs() < 1e-9 && (a1 - 45000.0).abs() < 1e-6, "centred road vs the hand table");
    assert!((b2 - b1).abs() < 1e-6 && (a2 - a1).abs() < 1e-4, "raw normal equations vs centred sums");
    assert!((b3 - b1).abs() < 1e-3 && (a3 - a1).abs() < 0.1, "blind search lands on the formula's line");
    assert!(((1.0 - sse1 / syy) - r * r).abs() < 1e-12, "R^2 from misses equals squared correlation");
    assert!((mean_b - 2100.0).abs() < 4.0 * sd_b / 2000f64.sqrt(), "simulated slopes centre on the true 2,100");
    assert!((sd_b / theory - 1.0).abs() < 0.1, "simulated spread matches sigma / sqrt(S_xx)");
    println!("ALL CHECKS PASS");
}
