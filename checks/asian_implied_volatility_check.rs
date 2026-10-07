// Implied vol from an Asian quote on jet fuel: 52 weekly fixings read the futures curve 100 e^(0.05 t).
// Rust std only.  Nothing imported knows the answer: the bell-curve area, both root finders,
// the random numbers (splitmix64 + Box-Muller) and every simulated path are written out below.
use std::f64::consts::PI;
const K: f64 = 100.0;
const R: f64 = 0.05;
const T: f64 = 1.0;
const NF: usize = 52;
const Q: f64 = 5.854; // the house Asian quote, $ per barrel
const PATHS: usize = 50000; // one set of draws, reused at every trial volatility

fn ncdf(x: f64) -> f64 { // area left of x: Marsaglia's series
    if x < -9.0 { return 0.0; }
    if x > 9.0 { return 1.0; }
    let (mut s, mut t, mut b, mut i) = (x, 0.0, x, 1.0);
    while s != t { i += 2.0; b = b * x * x / i; t = s; s += b; }
    0.5 + s * (-0.5 * x * x - 0.91893853320467274178).exp()
}
fn black(f: f64, v: f64, k: f64, tp: f64) -> f64 { // Black-76 on a lognormal with forward f, log-spread v
    let d1 = ((f / k).ln() + 0.5 * v * v) / v;
    (-R * tp).exp() * (f * ncdf(d1) - k * ncdf(d1 - v))
}
fn fwd(c: f64, t: f64) -> f64 { 100.0 * (c * t).exp() } // futures price for delivery at t
// Turnbull-Wakeman on curve slope c and dates tx: (price, exact vega, M1, fitted log-spread)
fn tw(s: f64, c: f64, tx: &[f64], k: f64) -> (f64, f64, f64, f64) {
    let m = tx.len() as f64;
    let fs: Vec<f64> = tx.iter().map(|&t| fwd(c, t)).collect();
    let m1 = fs.iter().sum::<f64>() / m;
    let (mut m2, mut dm2) = (0.0, 0.0);
    for i in 0..tx.len() {
        for j in 0..tx.len() {
            let mn = tx[i].min(tx[j]);
            let a = fs[i] * fs[j] * (s * s * mn).exp();
            m2 += a; dm2 += a * 2.0 * s * mn;
        }
    }
    m2 /= m * m; dm2 /= m * m;
    let v = (m2 / (m1 * m1)).ln().sqrt();
    let e1 = ((m1 / k).ln() + 0.5 * v * v) / v;
    let tl = tx[tx.len() - 1];
    (black(m1, v, k, tl), (-R * tl).exp() * m1 * (-0.5 * e1 * e1).exp() / (2.0 * PI).sqrt() * dm2 / (2.0 * v * m2), m1, v)
}
fn bisect<F: Fn(f64) -> f64>(f: F, q: f64) -> f64 { // f increasing: keep the half that straddles q
    let (mut lo, mut hi) = (1e-6, 5.0);
    if !(f(lo) < q && q < f(hi)) { return f64::NAN; } // outside the band: no volatility fits
    while hi - lo > 1e-13 {
        let mid = 0.5 * (lo + hi);
        if f(mid) < q { lo = mid; } else { hi = mid; }
    }
    0.5 * (lo + hi)
}
struct Rng(u64);
impl Rng { // splitmix64, the arithmetic-asian-option card's seed
    fn uniform(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 * 2f64.powi(-53) + 2f64.powi(-54)
    }
}
fn kv(s: f64, ts: &[f64]) -> f64 { // geometric twin, exact (Kemna-Vorst on the curve)
    let n = ts.len() as f64;
    let mu = ts.iter().map(|&t| fwd(0.05, t).ln() - 0.5 * s * s * t).sum::<f64>() / n;
    let mut var = 0.0;
    for &a in ts { for &b in ts { var += a.min(b); } }
    var = s * s * var / (n * n);
    black((mu + 0.5 * var).exp(), var.sqrt(), K, T)
}
fn mc(s: f64, ts: &[f64], z: &[f64]) -> (f64, f64) { // controlled simulation, geometric twin as control
    let d = (-R * T).exp();
    let base: Vec<f64> = ts.iter().map(|&t| fwd(0.05, t).ln() - 0.5 * s * s * t).collect();
    let steps: Vec<f64> = (0..NF).map(|i| s * (ts[i] - if i == 0 { 0.0 } else { ts[i - 1] }).sqrt()).collect();
    let (mut sx, mut sxx, mut sy, mut syy, mut sxy) = (0.0, 0.0, 0.0, 0.0, 0.0);
    for p in 0..PATHS {
        let (mut w, mut tot, mut totlog) = (0.0, 0.0, 0.0);
        for i in 0..NF {
            w += steps[i] * z[p * NF + i];
            tot += (base[i] + w).exp(); totlog += base[i] + w;
        }
        let x = d * (tot / NF as f64 - K).max(0.0);
        let y = d * ((totlog / NF as f64).exp() - K).max(0.0);
        sx += x; sxx += x * x; sy += y; syy += y * y; sxy += x * y;
    }
    let pn = PATHS as f64;
    let (mx, my) = (sx / pn, sy / pn);
    let (vy, cxy, vx) = (syy / pn - my * my, sxy / pn - mx * my, sxx / pn - mx * mx);
    let beta = cxy / vy;
    (mx - beta * (my - kv(s, ts)), ((vx - beta * cxy) / pn).sqrt())
}
fn row(label: &str, vals: &[f64]) {
    let mut line = format!("{:<44}", label);
    for v in vals { line += &if v.is_nan() { format!("{:>12}", "nan") } else { format!("{:>12.6}", v) }; }
    println!("{}", line);
}
fn main() {
    let ts: Vec<f64> = (0..NF).map(|i| T * (i + 1) as f64 / NF as f64).collect();
    let mut rng = Rng(20260927);
    let z: Vec<f64> = (0..PATHS * NF).map(|_| { let u1 = rng.uniform(); let u2 = rng.uniform();
        (-2.0 * u1.ln()).sqrt() * (2.0 * PI * u2).cos() }).collect();
    let twp = |s: f64| tw(s, 0.05, &ts, K).0;
    let (tw20, vega20, m1, va20) = tw(0.20, 0.05, &ts, K);
    let (floor, ceil) = ((-R * T).exp() * (m1 - K).max(0.0), (-R * T).exp() * m1);
    let iv_bis = bisect(twp, Q);
    let mut npath = vec![0.30]; // Newton: step by price error over vega
    loop {
        let s = *npath.last().unwrap();
        let (p, vg, _, _) = tw(s, 0.05, &ts, K);
        npath.push(s - (p - Q) / vg);
        if (npath[npath.len() - 1] - s).abs() < 1e-13 { break; }
    }
    let iv_new = *npath.last().unwrap();
    let (mc20, se20) = mc(0.20, &ts, &z);
    // road 3: secant steps on the simulated price
    let (mut a, mut b) = (0.19, 0.21);
    let (mut fa, mut fb, mut evals) = (mc(a, &ts, &z).0 - Q, mc(b, &ts, &z).0 - Q, 2.0);
    while (b - a).abs() > 1e-9 {
        let nb = b - fb * (b - a) / (fb - fa);
        a = b; fa = fb; b = nb;
        fb = mc(b, &ts, &z).0 - Q; evals += 1.0;
    }
    let iv_mc = b;
    let van_m1 = bisect(|v| black(m1, v, K, T), Q); // vanilla formula on the strip's forward
    let van_dec = bisect(|v| black(fwd(0.05, T), v, K, T), Q); // vanilla formula on December futures
    let c_week = (NF as f64 + 1.0) * (2.0 * NF as f64 + 1.0) / (6.0 * (NF * NF) as f64);
    let below = bisect(twp, 2.40);
    row("quote Q; strip forward M1; Dec futures", &[Q, m1, fwd(0.05, T)]);
    row("band: floor e^-rT (M1-K)+, ceiling e^-rT M1", &[floor, ceil]);
    row("TW at 20%; vega/pt; gap to Q; one Newton step", &[tw20, vega20 / 100.0, tw20 - Q, 0.20 - (tw20 - Q) / vega20]);
    row("TW log-spread vA at 20%", &[va20]);
    row("controlled simulation at 20%; error bar", &[mc20, se20]);
    row("1 implied vol, bisection on TW", &[iv_bis]);
    row("2 implied vol, Newton on TW", &[iv_new]);
    row("3 implied vol, secant on simulation", &[iv_mc]);
    row("  simulated prices used", &[evals]);
    row("vanilla formula on M1 reads", &[van_m1]);
    row("  TW log-spread at the TW implied vol", &[tw(iv_bis, 0.05, &ts, K).3]);
    row("vanilla formula on Dec futures reads", &[van_dec]);
    row("sanity: read x sqrt(3); x 1/sqrt(c); c", &[van_m1 * 3f64.sqrt(), van_m1 / c_week.sqrt(), c_week]);
    row("wrong: flat curve at $100, TW implied", &[bisect(|s| tw(s, 0.0, &ts, K).0, Q)]);
    row("wrong: fixings independent, implied", &[bisect(|s| black(m1, s * ts.iter().sum::<f64>().sqrt() / NF as f64, K, T), Q)]);
    row("wrong: quote 2.40, below the floor", &[below]);
    row("Newton from 30%, vol in % after each step", &npath[1..5].iter().map(|s| 100.0 * s).collect::<Vec<f64>>());
    let dec: Vec<f64> = (0..21).map(|i| 11.0 / 12.0 + (i + 1) as f64 / 252.0).collect(); // 21 daily fixings
    let (twd, _, m1d, _) = tw(0.20, 0.05, &dec, K);
    let (van_d, rule_d) = (bisect(|v| black(m1d, v, K, T), twd), 0.20 * (11.0 / 12.0 + 1.0 / 36.0f64).sqrt());
    row("Dec-only average: TW at 20%; M1; Dec vanilla", &[twd, m1d, black(fwd(0.05, T), 0.20, K, T)]);
    row("  vanilla on its M1 reads; x sqrt(3); rule", &[van_d, van_d * 3f64.sqrt(), rule_d]);
    let vols = [0, 5, 10, 15, 20, 25, 30, 35, 40];
    let asian: Vec<f64> = vols.iter().map(|&v| twp((v as f64).max(1e-4) / 100.0)).collect();
    let van: Vec<f64> = vols.iter().map(|&v| black(fwd(0.05, T), (v as f64).max(1e-4) / 100.0, K, T)).collect();
    println!("{:<28}{}", "chart, vol %", vols.iter().map(|v| format!("{:>8}", v)).collect::<String>());
    println!("{:<28}{}", "chart, Asian TW price", asian.iter().map(|p| format!("{:>8.2}", p)).collect::<String>());
    println!("{:<28}{}", "chart, vanilla on Dec price", van.iter().map(|p| format!("{:>8.2}", p)).collect::<String>());
    assert!((iv_bis - iv_new).abs() < 1e-10, "bisection and Newton land on one root");
    assert!((twp(iv_bis) - Q).abs() < 1e-9, "the implied vol reprices the quote");
    assert!((vega20 - (twp(0.200001) - twp(0.199999)) / 2e-6).abs() < 1e-5, "exact vega matches the price's slope");
    assert!((iv_mc - 0.20).abs() < 0.002 && (mc20 - Q).abs() < 3.0 * se20, "the simulation reads back 20%");
    assert!(iv_mc - iv_bis > 0.0 && iv_mc - iv_bis < 0.003, "TW's small overpricing makes its implied vol low");
    assert!((van_m1 - tw(iv_bis, 0.05, &ts, K).3).abs() < 1e-9, "vanilla on M1 reads TW's fitted log-spread");
    assert!((van_m1 * 3f64.sqrt() - iv_mc).abs() < 0.01, "total variance over three: within one vol point");
    let overlap: f64 = ts.iter().map(|&a| ts.iter().map(|&b| a.min(b)).sum::<f64>()).sum();
    assert!((c_week - overlap / ((NF * NF) as f64 * T)).abs() < 1e-12, "c counts the weekly overlap");
    assert!((van_d - rule_d).abs() < 0.001, "the window rule reads the December average");
    assert!(asian.windows(2).all(|w| w[0] < w[1]) && (asian[0] - floor).abs() < 1e-9, "rising from the floor");
    assert!(below.is_nan() && !bisect(twp, floor + 0.01).is_nan(), "no vol below the floor, one just above");
    println!("ALL CHECKS PASS");
}
