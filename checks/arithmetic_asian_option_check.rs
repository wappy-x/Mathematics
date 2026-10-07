// The arithmetic Asian on jet fuel: 52 weekly fixings read the futures curve 100 e^(0.05 t).
// Rust std only, no crates.  Nothing imported knows the answer: the bell-curve area, the random
// numbers (splitmix64 + Box-Muller) and every path are written out below.
use std::f64::consts::PI;

const K: f64 = 100.0; const R: f64 = 0.05; const SIG: f64 = 0.20; const T: f64 = 1.0; const NF: usize = 52;
fn ncdf(x: f64) -> f64 {                    // area left of x: Marsaglia's series
    if x < -9.0 { return 0.0; }
    if x > 9.0 { return 1.0; }
    let (mut s, mut t, mut b, mut i) = (x, 0.0, x, 1.0);
    while s != t {
        i += 2.0; b = b * x * x / i; t = s; s += b;
    }
    0.5 + s * (-0.5 * x * x - 0.91893853320467274178).exp()
}
fn black(f: f64, v: f64, k: f64, tp: f64) -> f64 {   // Black-76: call on a lognormal, forward f, log-spread v
    let d1 = ((f / k).ln() + 0.5 * v * v) / v;
    (-R * tp).exp() * (f * ncdf(d1) - k * ncdf(d1 - v))
}
#[derive(Clone, Copy)]
struct Curve { c: f64, lvl: f64 }           // futures price for delivery at t: lvl e^(c t)
impl Curve { fn at(&self, t: f64) -> f64 { self.lvl * (self.c * t).exp() } }
fn dates(m: usize, tx: f64, t0: f64) -> Vec<f64> {
    (0..m).map(|i| t0 + (tx - t0) * (i + 1) as f64 / m as f64).collect()
}
fn tw(fw: Curve, ts: &[f64], s: f64, k: f64) -> (f64, f64, f64, f64) {   // Turnbull-Wakeman
    let m = ts.len() as f64;
    let fs: Vec<f64> = ts.iter().map(|&t| fw.at(t)).collect();
    let m1 = fs.iter().fold(0.0, |a, &f| a + f) / m;
    let mut m2 = 0.0;
    for i in 0..ts.len() {
        for j in 0..ts.len() { m2 += fs[i] * fs[j] * (s * s * ts[i].min(ts[j])).exp(); }
    }
    m2 /= m * m;
    let va = (m2 / (m1 * m1)).ln().sqrt();
    (black(m1, va, k, ts[ts.len() - 1]), m1, m2, va)
}
fn kv(fw: Curve, ts: &[f64], s: f64, k: f64) -> (f64, f64) {   // geometric twin, exact, summed date by date
    let m = ts.len() as f64;
    let mu = ts.iter().fold(0.0, |a, &t| a + (fw.at(t).ln() - 0.5 * s * s * t)) / m;
    let mut sm = 0.0;
    for &a in ts { for &b in ts { sm += a.min(b); } }
    let var = s * s * sm / (m * m);
    (black((mu + 0.5 * var).exp(), var.sqrt(), k, ts[ts.len() - 1]), (mu + 0.5 * var).exp())
}
struct Rng(u64);
impl Rng {
    fn uniform(&mut self) -> f64 {          // splitmix64: 64-bit integer mixing
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = (self.0 ^ (self.0 >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 * 2f64.powi(-53) + 2f64.powi(-54)
    }
    fn normal(&mut self) -> f64 {           // Box-Muller, one draw per pair of uniforms
        let a = (-2.0 * self.uniform().ln()).sqrt();
        a * (2.0 * PI * self.uniform()).cos()
    }
}
// fixing i = F(0,t_i) e^(s W(t_i) - s^2 t_i / 2); returns plain, bar, controlled, bar, rho,
// geometric simulated and bar, mean of A and bar, mean of A^2 and bar
fn mc(rng: &mut Rng, fw: Curve, ts: &[f64], s: f64, k: f64, paths: usize) -> [f64; 11] {
    let (m, d) = (ts.len() as f64, (-R * ts[ts.len() - 1]).exp());
    let base: Vec<f64> = ts.iter().map(|&t| fw.at(t).ln() - 0.5 * s * s * t).collect();
    let steps: Vec<f64> = (0..ts.len()).map(|i| s * (ts[i] - if i == 0 { 0.0 } else { ts[i - 1] }).sqrt()).collect();
    let mut a = [0.0f64; 8];
    for _ in 0..paths {
        let (mut w, mut tot, mut totlog) = (0.0, 0.0, 0.0);
        for (b0, st) in base.iter().zip(steps.iter()) {
            w += st * rng.normal();
            tot += (b0 + w).exp(); totlog += b0 + w;
        }
        let av = tot / m;
        let (x, y) = (d * (av - k).max(0.0), d * ((totlog / m).exp() - k).max(0.0));   // arithmetic, geometric
        for (j, v) in [x, x * x, y, y * y, x * y, av, av * av, av * av * av * av].iter().enumerate() { a[j] += v; }
    }
    let p = paths as f64;
    let (mx, my, ma, ma2) = (a[0] / p, a[2] / p, a[5] / p, a[6] / p);
    let (vx, vy, cxy) = (a[1] / p - mx * mx, a[3] / p - my * my, a[4] / p - mx * my);
    let beta = cxy / vy;                    // slope of X on Y; the twin's miss is subtracted
    [mx, (vx / p).sqrt(), mx - beta * (my - kv(fw, ts, s, k).0), ((vx - beta * cxy) / p).sqrt(),
     cxy / (vx * vy).sqrt(), my, (vy / p).sqrt(), ma, ((ma2 - ma * ma) / p).sqrt(), ma2, ((a[7] / p - ma2 * ma2) / p).sqrt()]
}
fn row(label: &str, vals: &[f64], w: usize, dp: usize) {
    let s: String = vals.iter().map(|v| format!("{:>w$.dp$}", v, w = w, dp = dp)).collect();
    println!("{:<42}{}", label, s);
}
fn greeks(tsx: &[f64]) -> [f64; 3] {        // bump the whole curve by 1%, the volatility by 0.01 point
    let fw = Curve { c: 0.05, lvl: 100.0 };
    let p = |h: f64| tw(Curve { c: 0.05, lvl: 100.0 * (1.0 + h) }, tsx, SIG, K).0;
    let (up, mid, dn) = (p(0.01), p(0.0), p(-0.01));
    let (vu, vd) = (tw(fw, tsx, SIG + 1e-4, K).0, tw(fw, tsx, SIG - 1e-4, K).0);
    [(up - dn) / 2.0, (up - 2.0 * mid + dn) / 1.0, (vu - vd) / 2e-4 / 100.0]
}
fn main() {
    let mut rng = Rng(20260927);
    let fw = Curve { c: 0.05, lvl: 100.0 };
    let ts = dates(NF, T, 0.0);
    let plain = black(fw.at(T), SIG * T.sqrt(), K, T);
    let d1 = ((100.0 / K).ln() + (R + 0.5 * SIG * SIG) * T) / (SIG * T.sqrt());   // spot form, no yield
    let spot_form = 100.0 * ncdf(d1) - K * (-R * T).exp() * ncdf(d1 - SIG * T.sqrt());
    let (tw0, m1, m2, va) = tw(fw, &ts, SIG, K);
    let (kv0, fg) = kv(fw, &ts, SIG, K);
    let e1 = ((m1 / K).ln() + 0.5 * va * va) / va;
    let [mx, se, ctrl, se_c, rho, gsim, se_g, ma, se_a, ma2, se_a2] = mc(&mut rng, fw, &ts, SIG, K, 50000);
    let ceiling = kv0 + (-R * T).exp() * (m1 - fg);   // A - G >= (A-K)+ - (G-K)+ >= 0 on every path
    let eq = tw(Curve { c: 0.03, lvl: 100.0 }, &ts, SIG, K).0;
    let rows: Vec<(&str, Vec<f64>)> = vec![("curve F(0,t) at first and last fixing", vec![fw.at(ts[0]), fw.at(T)]),
        ("plain call, Black-76 on F(0,T)", vec![plain]), ("plain call, spot form, no yield", vec![spot_form]),
        ("M1, mean of the average, exact", vec![m1]), ("  simulated, and its error bar", vec![ma, se_a]),
        ("M2, mean square of the average, exact", vec![m2]), ("  simulated, and its error bar", vec![ma2, se_a2]),
        ("M2 / M1^2", vec![m2 / (m1 * m1)]), ("log-spread of the average vA", vec![va]),
        ("log-spread of one fixing, sigma*sqrt(T)", vec![SIG * T.sqrt()]), ("cut-offs e1, e2", vec![e1, e1 - va]),
        ("N(e1), N(e2)", vec![ncdf(e1), ncdf(e1 - va)]), ("discount e^-rT", vec![(-R * T).exp()]),
        ("geometric twin, Kemna-Vorst", vec![kv0]), ("  simulated, and its error bar", vec![gsim, se_g]),
        ("geometric forward F_G", vec![fg]), ("1 plain simulation, and its error bar", vec![mx, se]),
        ("2 controlled simulation, and its bar", vec![ctrl, se_c]), ("  correlation rho", vec![rho]),
        ("  error bar shrinks by", vec![se / se_c]), ("  plain paths needed for that bar, times", vec![(se / se_c).powi(2)]),
        ("3 Turnbull-Wakeman", vec![tw0]), ("  minus road 2", vec![tw0 - ctrl]), ("4 floor (the twin) and ceiling", vec![kv0, ceiling]),
        ("Asian / plain call", vec![ctrl / plain]), ("dial: lower spread only", vec![black(fw.at(T), va, K, T)]),
        ("dial: lower forward only", vec![black(m1, SIG * T.sqrt(), K, T)]),
        ("wrong: fixings as independent draws", vec![black(m1, SIG * (T / NF as f64).sqrt(), K, T)]),
        ("equity slope r-q = 3%, Turnbull-Wakeman", vec![eq])];
    for (label, vals) in rows.iter() { row(label, vals, 12, 6); }
    row("greeks, Asian (delta gamma vega/pt)", &greeks(&ts), 10, 4);
    row("greeks, plain call", &greeks(&[T]), 10, 4);

    println!("{:<42}", "scenario: TW, controlled MC, bar, TW - MC");
    let (mut errs, mut bar60) = (vec![tw0 - ctrl], 0.0);
    let five = dates(NF, 5.0, 0.0);
    let sc: [(&str, Curve, &[f64], f64); 7] = [("  curve flat at 100", Curve { c: 0.0, lvl: 100.0 }, &ts, SIG), ("  curve falling 5% (backwardation)", Curve { c: -0.05, lvl: 100.0 }, &ts, SIG),
        ("  vol 30%", fw, &ts, 0.3), ("  vol 40%", fw, &ts, 0.4), ("  vol 50%", fw, &ts, 0.5),
        ("  vol 60%", fw, &ts, 0.6), ("  five years, 52 fixings", fw, &five, SIG)];
    for &(label, f, tx, s) in sc.iter() {
        let (res, t0) = (mc(&mut rng, f, tx, s, K, 20000), tw(f, tx, s, K).0);
        errs.push(t0 - res[2]);
        row(label, &[t0, res[2], res[3], t0 - res[2]], 10, 4);
        if label == "  vol 60%" { bar60 = res[3]; }
    }
    let (half, kstar) = (dates(26, 0.5, 0.0), 2.0 * K - 80.0);   // 26 fixings banked at $80; 26 left
    let (res, th) = (mc(&mut rng, fw, &half, SIG, kstar, 20000), tw(fw, &half, SIG, kstar).0);
    row("  half done, $80 banked (half of K*=120)", &[0.5 * th, 0.5 * res[2], 0.5 * res[3], 0.5 * (th - res[2])], 10, 4);
    row("  half done: TW / MC", &[th / res[2]], 12, 6);
    let strip: Vec<Vec<f64>> = (0..12).map(|mth| (0..21).map(|i| mth as f64 / 12.0 + (i + 1) as f64 / 252.0).collect()).collect();
    let (mut st, mut fl, mut ce) = (0.0, 0.0, 0.0);
    for tm in strip.iter() {                // 21 daily fixings a month
        let (g, t1) = (kv(fw, tm, SIG, K), tw(fw, tm, SIG, K));
        st += t1.0; fl += g.0;
        ce += g.0 + (-R * tm[tm.len() - 1]).exp() * (t1.1 - g.1);
    }
    row("monthly strip: TW, floor, ceiling", &[st / 12.0, fl / 12.0, ce / 12.0], 12, 6);
    let cents: Vec<f64> = [errs[0], errs[3], errs[4], errs[5], errs[6]].iter().map(|e| 100.0 * e).collect();
    row("chart, TW - MC in cents, vol 20% to 60%", &cents, 7, 2);
    let avgs: Vec<i32> = (0..9).map(|i| 80 + 5 * i).collect();
    println!("{:<42}{}", "chart, average at expiry", avgs.iter().map(|a| format!("{:>7}", a)).collect::<String>());
    let prof: Vec<f64> = avgs.iter().map(|&a| (a as f64 - K).max(0.0) - ctrl).collect();
    row("chart, profit after premium", &prof, 7, 2);

    assert!((tw(fw, &[T], SIG, K).0 - spot_form).abs() < 1e-9 && (spot_form - 10.450583572185565).abs() < 1e-9, "one fixing: the plain call");
    assert!((gsim - kv0).abs() < 3.0 * se_g, "the paths reproduce the exact geometric price");
    assert!((ma - m1).abs() < 3.0 * se_a && (ma2 - m2).abs() < 3.0 * se_a2, "the paths reproduce both exact moments");
    assert!(kv0 < ctrl && ctrl < ceiling, "controlled price inside the AM-GM floor and ceiling");
    assert!((ctrl - mx).abs() < 3.0 * se, "the control moves the price by less than three plain bars");
    assert!(se / se_c > 10.0, "the control shrinks the error bar at least tenfold");
    assert!((tw0 - ctrl).abs() < 0.03, "moment matching within three cents at 20% vol");
    assert!(errs[6] > 10.0 * bar60 && errs[6] > 5.0 * (tw0 - ctrl), "at 60% vol the approximation has drifted");
    assert!(th < res[2] - 3.0 * res[3], "half banked, far out of the money: the quick price is too cheap");
    println!("ALL CHECKS PASS");
}
