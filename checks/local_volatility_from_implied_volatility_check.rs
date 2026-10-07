// Local volatility in implied-vol terms -- the same check as the Python, in Rust.  No crates.
// The surface: the one-year SVI curve v(k) of svi-smile-fit, each log-moneyness k keeping its
// implied vol at every expiry, so total variance is w(k, T) = T v(k).  Road 1 is the implied-vol
// formula, (dw/dT) / g.  Road 2 is Dupire's formula on call prices by finite differences: it never
// sees g or an SVI slope.  Road 3 rebuilds short-dated implied vols as harmonic means of local vols.
use std::f64::consts::PI;

type P5 = [f64; 5];
const P: P5 = [0.016719, 0.126769, -0.912282, -0.118207, 0.248954]; // a, b, rho, m, s
const S0: f64 = 100.0;
const R: f64 = 0.05;
const Q: f64 = 0.02;
const DAY: f64 = 1.0 / 365.0;
const WEEK: f64 = 1.0 / 52.0;

fn n_cdf(x: f64) -> f64 { // normal CDF from its own series
    if x.abs() > 9.0 { return if x > 0.0 { 1.0 } else { 0.0 }; }
    let y = x.abs() / 2f64.sqrt();
    let (mut term, mut s, mut n) = (y, y, 0.0);
    while term > 1e-17 * s { n += 1.0; term *= 2.0 * y * y / (2.0 * n + 1.0); s += term; }
    let e = 2.0 / PI.sqrt() * (-y * y).exp() * s;
    if x >= 0.0 { 0.5 * (1.0 + e) } else { 0.5 * (1.0 - e) }
}
fn fwd(t: f64) -> f64 { S0 * ((R - Q) * t).exp() }
fn svi(k: f64, p: &P5) -> (f64, f64, f64) { // one-year total variance v, its slope v' and its bend v''
    let [a, b, rho, m, s] = *p;
    let rt = ((k - m).powi(2) + s * s).sqrt();
    (a + b * (rho * (k - m) + rt), b * (rho + (k - m) / rt), b * s * s / rt.powi(3))
}
fn g_terms(k: f64, t: f64, p: &P5) -> (f64, f64, f64) { // the three terms of g, for w = T v
    let (v0, v1, v2) = svi(k, p);
    let (w, w1, w2) = (t * v0, t * v1, t * v2);
    ((1.0 - k * w1 / (2.0 * w)).powi(2), w1 * w1 / 4.0 * (1.0 / w + 0.25), w2 / 2.0)
}
fn g(k: f64, t: f64, p: &P5) -> f64 { let (t1, t2, t3) = g_terms(k, t, p); t1 - t2 + t3 }
fn loc(k: f64, t: f64, p: &P5) -> f64 { (svi(k, p).0 / g(k, t, p)).sqrt() } // road 1
fn imp(k: f64, p: &P5) -> f64 { svi(k, p).0.sqrt() } // implied vol, the same at every T
fn call(kk: f64, t: f64, vol: &dyn Fn(f64, f64) -> f64) -> f64 { // Black-Scholes call
    let (f, sd) = (fwd(t), vol(kk, t) * t.sqrt());
    let d1 = ((f / kk).ln() + 0.5 * sd * sd) / sd;
    (-R * t).exp() * (f * n_cdf(d1) - kk * n_cdf(d1 - sd))
}
fn dupire(kk: f64, t: f64, vol: &dyn Fn(f64, f64) -> f64) -> f64 { // road 2: Dupire on call prices
    let (hk, ht) = (0.05, 1e-4);
    let c = |x: f64, s: f64| call(x, s, vol);
    let c0 = c(kk, t);
    let ct = (c(kk, t + ht) - c(kk, t - ht)) / (2.0 * ht);
    let ck = (c(kk + hk, t) - c(kk - hk, t)) / (2.0 * hk);
    let ckk = (c(kk + hk, t) - 2.0 * c0 + c(kk - hk, t)) / (hk * hk);
    ((ct + (R - Q) * kk * ck + Q * c0) / (0.5 * kk * kk * ckk)).sqrt()
}
fn svi_vol(kk: f64, t: f64) -> f64 { imp((kk / fwd(t)).ln(), &P) }
fn skew(f: &dyn Fn(f64) -> f64) -> f64 { let h = 1e-4; (f(h) - f(-h)) / (2.0 * h) } // slope at k = 0
fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    h / 3.0 * (0..=n).map(|i| (if i == 0 || i == n { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 }) * f(a + i as f64 * h)).sum::<f64>()
}
fn row(label: &str, xs: &[f64], prec: usize) {
    let mut line = format!("{:<42}", label);
    for x in xs { line.push_str(&format!("{:>12.*}", prec, x)); }
    println!("{}", line);
}
fn join(xs: &[f64], f: &dyn Fn(f64) -> String) -> String { xs.iter().map(|&x| f(x)).collect::<Vec<_>>().join(" ") }

fn main() {
    let (f1, kks) = (fwd(1.0), [92.0, 120.0]);
    let ks: Vec<f64> = kks.iter().map(|kk| (kk / f1).ln()).collect();
    let [a, b, rho, m, s] = P;
    let sv: Vec<(f64, f64, f64)> = ks.iter().map(|&k| svi(k, &P)).collect();
    let gt: Vec<(f64, f64, f64)> = ks.iter().map(|&k| g_terms(k, 1.0, &P)).collect();
    let col = |f: &dyn Fn(usize) -> f64| -> Vec<f64> { (0..2).map(|i| f(i)).collect() };
    println!("forward at one year, F = 100 e^0.03       {:.6}", f1);
    println!("SVI a, b, rho, m, s (svi-smile-fit)       {}", join(&P, &|x| format!("{:+.6}", x)));
    println!("{:<42}{:>12}{:>12}", "one year, T = 1", "K = 92", "K = 120");
    row("log-moneyness k = ln(K/F)", &ks, 6);
    row("k - m", &col(&|i| ks[i] - m), 6);
    row("rounded distance sqrt((k-m)^2 + s^2)", &col(&|i| ((ks[i] - m).powi(2) + s * s).sqrt()), 6);
    row("total variance w", &col(&|i| sv[i].0), 6);
    row("implied vol, %", &col(&|i| 100.0 * imp(ks[i], &P)), 4);
    row("slope w' in k", &col(&|i| sv[i].1), 6);
    row("bend w'' in k", &col(&|i| sv[i].2), 6);
    row("time slope dw/dT at fixed k", &col(&|i| sv[i].0), 6);
    row("g, first term (1 - k w'/2w)^2", &col(&|i| gt[i].0), 6);
    row("g, second term w'^2/4 (1/w + 1/4)", &col(&|i| gt[i].1), 6);
    row("g, third term w''/2", &col(&|i| gt[i].2), 6);
    row("g", &col(&|i| g(ks[i], 1.0, &P)), 6);
    row("local variance (dw/dT) / g", &col(&|i| sv[i].0 / g(ks[i], 1.0, &P)), 6);
    let l1 = col(&|i| loc(ks[i], 1.0, &P));
    let l2 = col(&|i| dupire(kks[i], 1.0, &svi_vol));
    row("road 1 local vol, implied-vol formula, %", &col(&|i| 100.0 * l1[i]), 4);
    row("road 2 local vol, Dupire on prices, %", &col(&|i| 100.0 * l2[i]), 4);
    let flat = col(&|i| dupire(kks[i], 1.0, &|_x, _t| 0.2));
    row("flat 20% surface through road 2, %", &col(&|i| 100.0 * flat[i]), 4);
    let pilot = call(100.0, 1.0, &|_x, _t| 0.2);
    println!("{:<42}{:>16.12}", "house call, flat 20%, K = 100", pilot);
    row("wrong: dw/dT at fixed strike, %", &col(&|i| 100.0 * ((sv[i].0 - (R - Q) * sv[i].1) / g(ks[i], 1.0, &P)).sqrt()), 4);
    row("wrong: k measured from spot, %", &col(&|i| 100.0 * loc((kks[i] / S0).ln(), 1.0, &P)), 4);
    row("wrong: short-dated formula at 1 year, %", &col(&|i| 100.0 * imp(ks[i], &P) / (1.0 - ks[i] * sv[i].1 / (2.0 * sv[i].0))), 4);
    let (s0, sk0) = (imp(0.0, &P), svi(0.0, &P).1 / (2.0 * imp(0.0, &P))); // implied skew = v'(0) / (2 sigma)
    println!("at the forward k = 0: implied vol %, implied skew     {:.4} {:.6}", 100.0 * s0, sk0);
    println!("limit as T -> 0: twice the implied skew               {:.6}", 2.0 * sk0);
    println!("expiry            T  local vol at k = 0, %    local skew  local / implied");
    let mut ratio = Vec::new();
    for (lab, t) in [("1 year", 1.0), ("6 months", 0.5), ("3 months", 0.25), ("1 month", 1.0 / 12.0), ("1 week", WEEK), ("1 day", DAY)] {
        let ls = skew(&|k| loc(k, t, &P));
        ratio.push(ls / sk0);
        println!("{:<10}{:9.6}{:16.4}{:18.6}{:12.2}", lab, t, 100.0 * loc(0.0, t, &P), ls, ls / sk0);
    }
    let kd = col(&|i| (kks[i] / fwd(DAY)).ln());
    let hm = col(&|i| 1.0 / simpson(&|u| 1.0 / loc(u * kd[i], DAY, &P), 0.0, 1.0, 200));
    row("one day: implied vol, %", &col(&|i| 100.0 * imp(kd[i], &P)), 4);
    row("one day: harmonic mean of local vols, %", &col(&|i| 100.0 * hm[i]), 4);
    let mut gmin = f64::INFINITY;
    for i in 0..301 { for t in [1.0, 0.5, 0.25, 1.0 / 12.0, WEEK, DAY] { gmin = gmin.min(g(0.01 * i as f64 - 1.5, t, &P)); } }
    println!("smallest g, k from -1.5 to 1.5, six expiries   {:.6}", gmin);
    let g34: Vec<f64> = [3.0, 4.0].iter().map(|&t| (0..301).map(|i| g(0.01 * i as f64 - 1.5, t, &P)).fold(f64::INFINITY, f64::min)).collect();
    println!("smallest g, same k, at 3 and 4 years           {:.6} {:.6}", g34[0], g34[1]);
    row("one year, K = 60 and 40: implied vol, %", &[60.0, 40.0].map(|kk: f64| 100.0 * imp((kk / f1).ln(), &P)), 2);
    row("one year, K = 60 and 40: local vol, %", &[60.0, 40.0].map(|kk: f64| 100.0 * loc((kk / f1).ln(), 1.0, &P)), 2);
    let grid: Vec<f64> = (0..9).map(|i| 80.0 + 5.0 * i as f64).collect();
    let kg: Vec<f64> = (0..9).map(|i| 0.025 * (i as f64 - 4.0)).collect();
    println!("chart, strike           {}", join(&grid, &|kk| format!("{:6.0}", kk)));
    println!("chart, implied, 1 year  {}", join(&grid, &|kk| format!("{:6.2}", 100.0 * imp((kk / f1).ln(), &P))));
    println!("chart, local, 1 year    {}", join(&grid, &|kk| format!("{:6.2}", 100.0 * loc((kk / f1).ln(), 1.0, &P))));
    println!("chart, k                {}", join(&kg, &|k| format!("{:6.3}", k)));
    println!("chart, implied, 1 week  {}", join(&kg, &|k| format!("{:6.2}", 100.0 * imp(k, &P))));
    println!("chart, local, 1 week    {}", join(&kg, &|k| format!("{:6.2}", 100.0 * loc(k, WEEK, &P))));
    println!("chart, twice-skew line  {}", join(&kg, &|k| format!("{:6.2}", 100.0 * (s0 + 2.0 * sk0 * k))));
    let (pb, pr): (P5, P5) = ([a, 0.0, rho, m, s], [a, b, 0.0, m, s]);
    println!("try: b = 0, local vol at 92 and 120, %          {:.2} {:.2}", 100.0 * loc(ks[0], 1.0, &pb), 100.0 * loc(ks[1], 1.0, &pb));
    let sr = svi(0.0, &pr).1 / (2.0 * imp(0.0, &pr));
    println!("try: rho = 0, local / implied skew, 1 year, 1 day   {:.2} {:.2}", skew(&|k| loc(k, 1.0, &pr)) / sr, skew(&|k| loc(k, DAY, &pr)) / sr);
    assert!(l1.iter().zip(&l2).all(|(x, y)| (x - y).abs() < 1e-5), "road 1 (dw/dT over g) must match road 2 (Dupire on prices)");
    assert!(flat.iter().all(|x| (x - 0.2).abs() < 1e-5), "a flat 20% surface must give 20% local vol");
    assert!((ratio[5] - 2.0).abs() < 0.01, "short-dated local skew is twice the implied skew");
    assert!(ratio[0] < 1.5, "at one year the factor is well short of 2");
    assert!((0..2).all(|i| (hm[i] - imp(kd[i], &P)).abs() < 1e-4), "short-dated implied = harmonic mean of local");
    assert!(gmin > 0.0, "g positive everywhere: a local vol exists at every point of the grid");
    assert!(g34[1] < 0.0, "stretched to four years this surface fails the butterfly test");
    assert!((pilot - 9.227005508154).abs() < 1e-9, "the pricer returns the pilot's house call");
    println!("ALL CHECKS PASS");
}
