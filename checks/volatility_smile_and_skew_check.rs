// Volatility smile and skew -- the same check as volatility_smile_and_skew_check.py, in Rust.
// Standard library only, no crates.  A crash-mixture market prices the house strip 80..120;
// each price is run back through Black-Scholes to one volatility per strike.
use std::f64::consts::PI;

const S: f64 = 100.0; const R: f64 = 0.05; const Q: f64 = 0.02; const T: f64 = 1.0;
type Mix = Vec<(f64, f64, f64)>;                         // (weight, forward, vol) per leg

fn n_cdf(x: f64) -> f64 {                                // normal CDF from the erf series
    if x > 9.0 { return 1.0; }
    if x < -9.0 { return 0.0; }
    let y = x.abs() / 2f64.sqrt();
    let (mut term, mut s, mut n) = (y, y, 0.0);
    while term > 1e-17 * s { n += 1.0; term *= 2.0 * y * y / (2.0 * n + 1.0); s += term; }
    let e = 2.0 / PI.sqrt() * (-y * y).exp() * s;
    if x >= 0.0 { 0.5 * (1.0 + e) } else { 0.5 * (1.0 - e) }
}
fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }
fn fwd() -> f64 { S * ((R - Q) * T).exp() }
fn disc() -> f64 { (-R * T).exp() }
fn legs(p: f64, c: f64, sc: f64, sn: f64) -> Mix {
    let f = fwd();
    vec![(p, c * f, sc), (1.0 - p, (f - p * c * f) / (1.0 - p), sn)]
}
fn b76(f: f64, k: f64, s: f64, call: bool) -> f64 {
    let v = s * T.sqrt(); let d1 = ((f / k).ln() + 0.5 * v * v) / v; let d2 = d1 - v;
    if call { disc() * (f * n_cdf(d1) - k * n_cdf(d2)) } else { disc() * (k * n_cdf(-d2) - f * n_cdf(-d1)) }
}
fn mix(k: f64, call: bool, m: &Mix) -> f64 { m.iter().map(|&(w, f, s)| w * b76(f, k, s, call)).sum() }
fn bs(k: f64, s: f64, call: bool, qq: f64) -> f64 { b76(S * ((R - qq) * T).exp(), k, s, call) }
fn iv_bisect(c: f64, k: f64, mut lo: f64, mut hi: f64, qq: f64) -> f64 {
    for _ in 0..200 {
        let mid = 0.5 * (lo + hi);
        if bs(k, mid, true, qq) > c { hi = mid } else { lo = mid }
        if hi - lo < 1e-15 { break; }
    }
    0.5 * (lo + hi)
}
fn iv(c: f64, k: f64) -> f64 { iv_bisect(c, k, 1e-6, 5.0, Q) }
fn iv_newton(p: f64, k: f64) -> f64 {
    let mut s = 0.25;
    for _ in 0..50 {
        let d1 = ((fwd() / k).ln() + 0.5 * s * s * T) / (s * T.sqrt());
        let step = (bs(k, s, false, Q) - p) / (disc() * fwd() * phi(d1) * T.sqrt());
        s -= step;
        if step.abs() < 1e-15 { break; }
    }
    s
}
fn density(x: f64, m: &Mix) -> f64 {
    m.iter().map(|&(w, f, s)| w * phi((x - f.ln() + 0.5 * s * s * T) / (s * T.sqrt())) / (s * T.sqrt())).sum()
}
fn simpson(g: &dyn Fn(f64) -> f64, a: f64, b: f64) -> f64 { // Simpson's rule, written out
    let n = 4000; let h = (b - a) / n as f64;
    let mut s = g(a) + g(b);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * g(a + i as f64 * h); }
    h / 3.0 * s
}
fn call_integral(k: f64, m: &Mix) -> f64 {               // payoff x density, no Black formula
    disc() * simpson(&|x| (x.exp() - k) * density(x, m), k.ln(), fwd().ln() + 3.0)
}
struct Rng(u64);
impl Rng {                                               // splitmix64, top 53 bits -> (0,1)
    fn uniform(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 * 2f64.powi(-53) + 2f64.powi(-54)
    }
}
fn tail(k: f64, m: &Mix) -> f64 {
    m.iter().map(|&(w, f, s)| w * n_cdf(-((f / k).ln() - 0.5 * s * s * T) / (s * T.sqrt()))).sum()
}
fn pct3(v: [f64; 3]) -> String { format!("{:.2} {:.2} {:.2}", 100.0 * v[0], 100.0 * v[1], 100.0 * v[2]) }

fn main() {
    let (f, d) = (fwd(), disc());
    let m = legs(0.12, 0.70, 0.40, 0.15);
    let strip: Vec<f64> = (0..9).map(|i| 80.0 + 5.0 * i as f64).collect();
    let mut rng = Rng(20260919);
    let (paths, mut tot) = (200000, vec![0.0; 9]);
    for _ in 0..paths {
        let (_, fl, s) = if rng.uniform() < m[0].0 { m[0] } else { m[1] };
        let z = (-2.0 * rng.uniform().ln()).sqrt() * (2.0 * PI * rng.uniform()).cos();
        let st = fl * (-0.5 * s * s * T + s * T.sqrt() * z).exp();
        for (j, k) in strip.iter().enumerate() { tot[j] += (st - k).max(0.0); }
    }
    let mc: Vec<f64> = tot.iter().map(|t| d * t / paths as f64).collect();
    println!("forward F = S e^(r-q)T, e^-rT      {:.6} {:.4}", f, d);
    for (lab, &(w, fl, s)) in ["crash", "calm "].iter().zip(m.iter()) {
        println!("{} leg: weight, forward/F, forward, vol  {:.2} {:.4} {:.4} {:.2}", lab, w, fl / f, fl, s);
    }
    println!("weights x forwards                 {:.6}", m.iter().map(|&(w, fl, _)| w * fl).sum::<f64>());
    let mean = call_integral(1e-9, &m) / d;
    assert!((mean - f).abs() < 1e-6, "the density integrates to the market's forward");
    println!("mean of S_T by integral            {:.6}", mean);
    println!("   K       k   call:formula integral  MC    iv call  iv put  crash share of put");
    let mut ivs = vec![];
    for (j, &k) in strip.iter().enumerate() {
        let (c, ci, p) = (mix(k, true, &m), call_integral(k, &m), mix(k, false, &m));
        let (a, b) = (iv(c, k), iv_newton(p, k));
        ivs.push(a);
        assert!((ci - c).abs() < 1e-7, "integral road must land on the weighted formula");
        assert!((mc[j] - c).abs() < 0.1, "Monte Carlo within ten cents");
        assert!((a - b).abs() < 1e-9, "bisection on the call and Newton on the put find one vol");
        let share = m[0].0 * b76(m[0].1, k, m[0].2, false) / p;
        println!("{:5.0} {:+7.4} {:10.4} {:9.4} {:7.2} {:8.2} {:7.2} {:9.1}%", k, (k / f).ln(), c, ci, mc[j], 100.0 * a, 100.0 * b, 100.0 * share);
    }
    let flat = [80.0, 100.0, 120.0].map(|k| iv(bs(k, 0.20, true, Q), k));
    assert!(flat.iter().all(|v| (v - 0.20).abs() < 1e-10), "a flat 20% market must invert to 20% everywhere");
    assert!((0..8).all(|i| ivs[i] > ivs[i + 1]), "the crash market must skew down across the strip");
    println!("flat 20% market inverted at 80/100/120   {}", pct3(flat));
    let iv_k = |kk: f64| { let k = f * kk.exp(); iv(mix(k, true, &m), k) };
    println!("skew, 90 to 110, vol per unit k      {:.4}", (ivs[6] - ivs[2]) / (110.0f64 / 90.0).ln());
    println!("skew at the money, k = -0.01 to 0.01 {:.4}", (iv_k(0.01) - iv_k(-0.01)) / 0.02);
    println!("iv at the forward, k = 0             {:.2}", 100.0 * iv_k(0.0));
    let (pc, pn) = (b76(m[0].1, 80.0, 0.40, false), b76(m[1].1, 80.0, 0.15, false));
    println!("80 put: crash leg, calm leg          {:.4} {:.4}", pc, pn);
    println!("80 put: mixture, flat 20%            {:.4} {:.4}", m[0].0 * pc + m[1].0 * pn, bs(80.0, 0.20, false, Q));
    let (mut lo, mut hi, p80) = (0.0, 0.5, mix(80.0, false, &m));
    for _ in 0..6 {
        let mid = 0.5 * (lo + hi); let v = bs(80.0, mid, false, Q);
        println!("  bisection try {:.6} put {:.4} {}", mid, v, if v > p80 { "too dear" } else { "too cheap" });
        if v > p80 { hi = mid } else { lo = mid }
    }
    let ln: Mix = vec![(1.0, f, 0.20)];
    assert!((simpson(&|x| density(x, &m), -20.0, 60f64.ln()) - tail(60.0, &m)).abs() < 1e-9, "tail formula = area under the density");
    println!("P(S_T < 60): mixture, lognormal 20%  {:.4} {:.4}", tail(60.0, &m), tail(60.0, &ln));
    println!("P(S_T > 130): mixture, lognormal 20% {:.4} {:.4}", 1.0 - tail(130.0, &m), 1.0 - tail(130.0, &ln));
    let mom = |n: f64| -> f64 { m.iter().map(|&(w, fl, s)| w * fl.powf(n) * (0.5 * n * (n - 1.0) * s * s * T).exp()).sum() };
    let sstar = ((mom(2.0) / (f * f)).ln() / T).sqrt();
    for n in [2.0, 3.0] { assert!((simpson(&|x| (n * x).exp() * density(x, &m), -20.0, f.ln() + 4.0) / mom(n) - 1.0).abs() < 1e-9, "moment formula = integral"); }
    assert!(mom(3.0) < f.powi(3) * (3.0 * sstar * sstar * T).exp() - 1000.0, "no lognormal matching the second moment matches the third");
    println!("vol matching E[S_T^2]; E[S_T^3] mixture vs that lognormal  {:.4} {:.1} {:.1}", sstar, mom(3.0), f.powi(3) * (3.0 * sstar * sstar * T).exp());
    let bad_q = [80.0, 100.0, 120.0].map(|k| iv_bisect(mix(k, true, &m), k, 1e-6, 5.0, 0.0));
    println!("wrong: forward with q forgotten     {:.4}", S * (R * T).exp());
    println!("wrong: inverter forgets q, 80/100/120    {}", pct3(bad_q));
    let bad: Mix = vec![(0.12, 0.70 * f, 0.40), (0.88, f, 0.15)];
    println!("wrong: calm leg left at F: call iv, put iv at 100  {:.2} {:.2}", 100.0 * iv(mix(100.0, true, &bad), 100.0), 100.0 * iv_newton(mix(100.0, false, &bad), 100.0));
    println!("wrong: bracket 0.01 to 0.25 at 80        {:.2}", 100.0 * iv_bisect(mix(80.0, true, &m), 80.0, 0.01, 0.25, Q));
    for (lab, mm) in [("no crash leg", legs(0.0, 0.70, 0.40, 0.15)), ("crash to 50%", legs(0.12, 0.50, 0.40, 0.15))] {
        let v = [80.0, 100.0, 120.0].map(|k| iv(mix(k, true, &mm), k));
        println!("try: {}, iv 80/100/120      {}", lab, pct3(v));
    }
    let eq = legs(0.12, 1.0, 0.40, 0.15);
    let e = [-0.2f64, 0.2].map(|kk| { let k = f * kk.exp(); 100.0 * iv(mix(k, true, &eq), k) });
    assert!((e[0] - e[1]).abs() < 1e-7, "equal centres give an even smile in k");
    println!("try: equal centres, iv at k = -0.2, +0.2  {:.4} {:.4}", e[0], e[1]);
    let grid: Vec<f64> = (0..13).map(|i| 40.0 + 10.0 * i as f64).collect();
    let row = |lab: &str, g: &dyn Fn(f64) -> String| println!("{}{}", lab, grid.iter().map(|&x| g(x)).collect::<Vec<_>>().join(" "));
    row("chart, S_T          ", &|x| format!("{:5.0}", x));
    row("chart, mixture      ", &|x| format!("{:5.2}", 100.0 * density(x.ln(), &m) / x));
    row("chart, lognormal 20 ", &|x| format!("{:5.2}", 100.0 * density(x.ln(), &ln) / x));
    println!("ALL CHECKS PASS");
}
