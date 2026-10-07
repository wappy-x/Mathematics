// Term structure and forward volatility -- the same check as the Python, in Rust.  Standard
// library only, no crates.  Rust has no erf, so the bell-curve area N(x) is built by adding
// up thin slices under the curve (Simpson); the root finder is bisection and the random
// numbers come from a SplitMix64 generator, all written out below.
use std::f64::consts::PI;
const S: f64 = 100.0; const K: f64 = 100.0; const R: f64 = 0.05; const Q: f64 = 0.02;
const T1: f64 = 0.5; const T2: f64 = 1.0;

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }
fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    s * h / 3.0
}
fn n_cdf(x: f64) -> f64 {
    if x < -12.0 { return 0.0; }
    if x > 12.0 { return 1.0; }
    0.5 + simpson(phi, 0.0, x, 2000)
}
fn call(s: f64, k: f64, t: f64, sig: f64) -> f64 {           // Black-Scholes call, one flat vol
    if sig <= 0.0 { return (s * (-Q * t).exp() - k * (-R * t).exp()).max(0.0); }
    let d1 = ((s / k).ln() + (R - Q + 0.5 * sig * sig) * t) / (sig * t.sqrt());
    s * (-Q * t).exp() * n_cdf(d1) - k * (-R * t).exp() * n_cdf(d1 - sig * t.sqrt())
}
fn bisect<F: Fn(f64) -> f64>(f: F, mut lo: f64, mut hi: f64) -> f64 {   // f(lo) < 0 < f(hi)
    for _ in 0..60 {
        let mid = 0.5 * (lo + hi);
        if f(mid) < 0.0 { lo = mid } else { hi = mid }
    }
    0.5 * (lo + hi)
}
fn fwd_vol(s1: f64, t1: f64, s2: f64, t2: f64) -> Option<f64> {        // road 1: the formula
    let (w1, w2) = (s1 * s1 * t1, s2 * s2 * t2);
    if w2 >= w1 { Some(((w2 - w1) / (t2 - t1)).sqrt()) } else { None }
}
fn two_stage(k: f64, s1: f64, sf: f64) -> f64 {              // road 2: the far call in two stages
    let f = |z: f64| {
        let s_mid = S * ((R - Q - 0.5 * s1 * s1) * T1 + s1 * T1.sqrt() * z).exp();
        call(s_mid, k, T2 - T1, sf) * phi(z)
    };
    (-R * T1).exp() * simpson(f, -10.0, 10.0, 800)
}
fn implied(price: f64, k: f64, t: f64) -> f64 { bisect(|v| call(S, k, t, v) - price, 1e-9, 2.0) }

struct Rng(u64);
impl Rng {
    fn u01(&mut self) -> f64 {                                 // SplitMix64, mapped into (0, 1)
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = (self.0 ^ (self.0 >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        (((z ^ (z >> 31)) >> 11) as f64 + 0.5) / 9007199254740992.0
    }
    fn gauss(&mut self) -> f64 { let u = self.u01(); (-2.0 * u.ln()).sqrt() * (2.0 * PI * self.u01()).cos() }
}
fn var(xs: &[f64]) -> f64 {
    let m = xs.iter().sum::<f64>() / xs.len() as f64;
    xs.iter().map(|x| (x - m) * (x - m)).sum::<f64>() / (xs.len() - 1) as f64
}
fn row(label: &str, v: f64) { println!("{:<46} {:>12.6}", label, v); }

fn main() {
    let (s1, s2) = (0.18_f64, 0.20_f64);
    let (w1, w2) = (s1 * s1 * T1, s2 * s2 * T2);
    let sf = fwd_vol(s1, T1, s2, T2).unwrap();
    let c_far = call(S, K, T2, s2);
    let sf_road2 = bisect(|v| two_stage(K, s1, v) - c_far, 0.0, 1.0);
    println!("house sheet: 18% at half a year, 20% at one year");
    row("total variance w1 = 0.18^2 x 0.5", w1); row("total variance w2 = 0.20^2 x 1", w2);
    row("variance added in between, w2 - w1", w2 - w1);
    row("per year in between, (w2 - w1)/(T2 - T1)", (w2 - w1) / (T2 - T1));
    row("1 forward vol, formula", sf); row("2 forward vol, two-stage price + bisection", sf_road2);
    row("  one-year call at 20%", c_far); row("  half-year call at 18%", call(S, K, T1, s1));
    let mut iv = Vec::new();
    for k in [90.0_f64, 100.0, 110.0] {
        let v = implied(two_stage(k, s1, sf), k, T2);
        row(&format!("3 implied vol of the two-stage price, K {:.0}", k), v);
        iv.push(v);
    }
    let (paths, weeks) = (10000, 26);
    let dt = T1 / weeks as f64;
    let mut rng = Rng(20260919);
    let (mut a_s, mut b_s) = (Vec::new(), Vec::new());
    for _ in 0..paths {
        a_s.push((0..weeks).map(|_| s1 * dt.sqrt() * rng.gauss()).sum::<f64>());
        b_s.push((0..weeks).map(|_| sf * dt.sqrt() * rng.gauss()).sum::<f64>());
    }
    let (v_a, v_b) = (var(&a_s), var(&b_s));
    let ab: Vec<f64> = a_s.iter().zip(&b_s).map(|(a, b)| a + b).collect();
    let v_ab = var(&ab);
    println!("4 simulated log moves, 10000 paths x 52 weeks");
    for (lab, v) in [("variance, first half", v_a), ("variance, second half", v_b),
                     ("variance, whole year", v_ab), ("twice the covariance", v_ab - v_a - v_b)] {
        println!("  {:<44} {:>12.4}", lab, v);
    }
    let (f1, f2, cover) = (S * ((R - Q) * T1).exp(), S * ((R - Q) * T2).exp(), (-Q * (T2 - T1)).exp());
    let k_match = K * f2 / f1;
    row("forward F(T1)", f1); row("forward F(T2)", f2);
    row("matched far strike, K x F(T2)/F(T1)", k_match); row("cover weight e^-q(T2-T1)", cover);
    row("calendar cushion, far call - cover x near", call(S, k_match, T2, s2) - cover * call(S, K, T1, s1));
    row("wrong: vols averaged in a straight line", (s2 * T2 - s1 * T1) / (T2 - T1));
    row("wrong: divided by T2, not T2 - T1", ((w2 - w1) / T2).sqrt());
    row("wrong: squared vols subtracted, no T weights", ((s2 * s2 - s1 * s1) / (T2 - T1)).sqrt());
    let (b1, b2) = (0.21_f64, 0.14_f64);
    let (bw1, bw2) = (b1 * b1 * T1, b2 * b2 * T2);
    println!("broken sheet: 21% at half a year, 14% at one year");
    row("total variance w1 = 0.21^2 x 0.5", bw1); row("total variance w2 = 0.14^2 x 1", bw2);
    row("per year in between, (w2 - w1)/(T2 - T1)", (bw2 - bw1) / (T2 - T1));
    println!("  {:<44} {:>12}", "1 forward vol, formula", if fwd_vol(b1, T1, b2, T2).is_none() { "none" } else { "found" });
    let floor = two_stage(K, b1, 0.0);
    row("2 cheapest two-stage far call, forward vol 0", floor); row("  quoted one-year call at 14%", call(S, K, T2, b2));
    let (near_b, far_b) = (call(S, K, T1, b1), call(S, k_match, T2, b2));
    row("  half-year call at 21%, K 100", near_b); row("  one-year call at 14%, matched strike", far_b);
    row("  cash collected, cover x near - far", cover * near_b - far_b);
    println!("chart: months to expiry, implied vol %, instantaneous vol %");
    let months: Vec<u32> = (1..=12).collect();
    let imp: Vec<String> = months.iter().map(|&m| {
        let t = m as f64 / 12.0;
        format!("{:>6.2}", 100.0 * ((t.min(T1) * s1 * s1 + (t - T1).max(0.0) * sf * sf) / t).sqrt())
    }).collect();
    let inst: Vec<String> = months.iter().map(|&m| format!("{:>6.2}", 100.0 * if m <= 6 { s1 } else { sf })).collect();
    println!("{}", months.iter().map(|m| format!("{:>6}", m)).collect::<Vec<_>>().join(" "));
    println!("{}", imp.join(" ")); println!("{}", inst.join(" "));
    for (lab, t2v) in [("try: 18% flat", 0.18), ("try: 25% at one year", 0.25), ("try: 12.7279% at one year", 0.127279220614)] {
        row(&format!("{}, forward vol", lab), fwd_vol(s1, T1, t2v, T2).unwrap());
    }
    row("falling vols: 25% then 20%, w1", 0.25 * 0.25 * T1); row("  forward vol", fwd_vol(0.25, T1, 0.20, T2).unwrap());
    assert!((sf_road2 - sf).abs() < 1e-8, "two-stage bisection must land on the formula");
    assert!(iv.iter().all(|v| (v - s2).abs() < 1e-7), "a deterministic vol path leaves no smile");
    assert!((v_ab - w2).abs() < 0.002, "simulated whole-year variance vs 0.20^2 x 1");
    assert!((v_b - (w2 - w1)).abs() < 0.0015, "simulated second-half variance vs w2 - w1");
    assert!(floor > call(S, K, T2, b2), "broken sheet: quoted far call under the cheapest reachable");
    assert!(cover * near_b - far_b > 0.0, "broken sheet: the calendar collects cash");
    assert!((50..=300).step_by(5).all(|x| { let x = x as f64; call(x, k_match, T2 - T1, b2) >= cover * (x - K).max(0.0) - 1e-9 }), "at T1 the long far call covers the short near calls");
    println!("ALL CHECKS PASS");
}
