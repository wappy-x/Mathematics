// Implied forward and dividend from parity -- the same check as the Python, in Rust.
// Standard library only, no crates.  The bell-curve area is added up slice by slice
// (Simpson), the root finder is a bisection written here, and the random quote errors
// come from a hand-written generator.  Compile: rustc --edition 2021 -O this_file.rs
use std::f64::consts::PI;

const S: f64 = 100.0; const K: f64 = 100.0; const R: f64 = 0.05;
const Q: f64 = 0.02; const SIGMA: f64 = 0.20; const T: f64 = 1.0;

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }   // bell-curve height at x
fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    s * h / 3.0
}
fn n_cdf(x: f64) -> f64 {                                   // bell-curve area left of x
    if x < -12.0 { return 0.0; }
    if x > 12.0 { return 1.0; }
    0.5 + simpson(phi, 0.0, x, 4000)
}
fn d1(s: f64, k: f64, t: f64) -> f64 { ((s / k).ln() + (R - Q + 0.5 * SIGMA * SIGMA) * t) / (SIGMA * t.sqrt()) }
fn call(s: f64, k: f64, t: f64) -> f64 {                    // the call card's formula
    let (a, vt) = (d1(s, k, t), SIGMA * t.sqrt());
    s * (-Q * t).exp() * n_cdf(a) - k * (-R * t).exp() * n_cdf(a - vt)
}
fn put(s: f64, k: f64, t: f64) -> f64 {                     // the put card's formula
    let (a, vt) = (d1(s, k, t), SIGMA * t.sqrt());
    k * (-R * t).exp() * n_cdf(vt - a) - s * (-Q * t).exp() * n_cdf(-a)
}
fn by_integral(k: f64, sign: f64) -> f64 {   // road 4's prices: payoff averaged over the bell curve
    let f = |z: f64| {
        let st = S * ((R - Q - 0.5 * SIGMA * SIGMA) * T + SIGMA * T.sqrt() * z).exp();
        (sign * (st - k)).max(0.0) * phi(z)
    };
    (-R * T).exp() * simpson(f, -10.0, 10.0, 20000)
}
fn fwd(c: f64, p: f64, k: f64, rr: f64, t: f64) -> f64 { k + (c - p) * (rr * t).exp() }  // road 1
fn yld(f: f64, rr: f64, t: f64) -> f64 { rr - (f / S).ln() / t }   // the yield a forward implies
fn bisect_q(gap: f64, rr: f64, t: f64) -> f64 {  // road 2: hunt q in S e^-qT - K e^-rT = C - P
    let (mut lo, mut hi) = (-1.0_f64, 1.0_f64);
    for _ in 0..200 {
        let mid = 0.5 * (lo + hi);
        if S * (-mid * t).exp() - K * (-rr * t).exp() > gap { lo = mid; } else { hi = mid; }
    }
    0.5 * (lo + hi)
}
fn line_fit(ks: &[f64], gaps: &[f64]) -> (f64, f64) {  // road 4: gap = a - D K, then F = a / D
    let n = ks.len() as f64;
    let (mk, mg) = (ks.iter().sum::<f64>() / n, gaps.iter().sum::<f64>() / n);
    let num: f64 = ks.iter().zip(gaps).map(|(x, y)| (x - mk) * (y - mg)).sum();
    let den: f64 = ks.iter().map(|x| (x - mk) * (x - mk)).sum();
    let slope = num / den;
    (-slope, (mg - slope * mk) / (-slope))
}
struct Lcg(u64);
impl Lcg {                   // a 64-bit linear congruential generator: a quote error in +-0.05
    fn noise(&mut self) -> f64 {
        self.0 = self.0.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
        ((self.0 >> 11) as f64 / (1u64 << 53) as f64 - 0.5) * 0.10
    }
}
fn row(name: &str, v: f64) { println!("{:<40}{:>14.6}", name, v); }
fn pct(name: &str, v: f64) { println!("{:<40}{:>13.4}%", name, v * 100.0); }

fn main() {
    let strikes: Vec<f64> = (0..9).map(|i| 80.0 + 5.0 * i as f64).collect();
    let (c, p) = (call(S, K, T), put(S, K, T));
    let f1 = fwd(c, p, K, R, T); let q1 = yld(f1, R, T); let q2 = bisect_q(c - p, R, T);
    let (g90, g110) = (call(S, 90.0, T) - put(S, 90.0, T), call(S, 110.0, T) - put(S, 110.0, T));
    let d3 = (g90 - g110) / (110.0 - 90.0); let r3 = -d3.ln() / T; let f3 = 90.0 + g90 / d3; let q3 = yld(f3, r3, T);
    let gaps4: Vec<f64> = strikes.iter().map(|&k| by_integral(k, 1.0) - by_integral(k, -1.0)).collect();
    let (d4, f4) = line_fit(&strikes, &gaps4); let r4 = -d4.ln() / T; let q4 = yld(f4, r4, T);
    let carry = S * ((R - Q) * T).exp();

    println!("house market: S {:.2}  K {:.2}  r {:.2}%  q {:.2}%  T {:.2} years", S, K, R * 100.0, Q * 100.0, T);
    println!("road 1: one strike, rate given");
    for (name, v) in [("call C", c), ("put P", p), ("C - P", c - p), ("e^rT", (R * T).exp()),
                      ("(C - P) e^rT", (c - p) * (R * T).exp()), ("forward F = K + (C - P) e^rT", f1),
                      ("F / S", f1 / S), ("share grown at the rate, S e^rT", S * (R * T).exp())] { row(name, v); }
    pct("carry r - q = ln(F/S) / T", (f1 / S).ln() / T); pct("yield q = r - ln(F/S) / T", q1);
    pct("road 2: q by bisection on parity", q2);
    println!("road 3: the box, strikes 90 and 110, no rate given");
    for (name, v) in [("C - P at 90", g90), ("C - P at 110", g110), ("discount factor D", d3),
                      ("forward F", f3)] { row(name, v); }
    pct("rate r = -ln D / T", r3); pct("yield q", q3);
    println!("road 4: nine strikes priced by integral, straight-line fit");
    row("discount factor D", d4); row("forward F", f4); pct("rate r", r4); pct("yield q", q4);
    row("check: cash and carry S e^(r-q)T", carry);
    println!("chart, strike    {}", strikes.iter().map(|k| format!("{:>7.0}", k)).collect::<String>());
    println!("chart, C - P     {}", strikes.iter().map(|&k| format!("{:>7.2}", call(S, k, T) - put(S, k, T))).collect::<String>());

    println!("what breaks");
    let fh = fwd(c, p + 0.10, K, R, T); let qh = yld(fh, R, T);
    let fs = fwd(call(99.0, K, T), p, K, R, T); let qs = yld(fs, R, T);
    row("put 0.10 too high: F", fh); pct("put 0.10 too high: q", qh);
    pct("  straight-line guess 0.10 e^rT / (F T)", 0.10 * (R * T).exp() / (f1 * T));
    pct("no carry forward, F = K + C - P: q", yld(K + c - p, R, T));
    pct("sign swapped, r + ln(F/S) / T", R + (f1 / S).ln() / T);
    row("stale call, priced at Acme 99", call(99.0, K, T)); row("stale call: F", fs); pct("stale call: q", qs);
    let w = 1.0 / 52.0;
    let (cw, pw) = (call(S, K, w), put(S, K, w));
    pct("one week, put 0.10 too high: q", yld(fwd(cw, pw + 0.10, K, R, w), R, w));
    println!("bid and ask: call 9.18 / 9.28, put 6.28 / 6.38; crossed put 6.45 / 6.25");
    let (flo, fhi) = (fwd(9.18, 6.38, K, R, T), fwd(9.28, 6.28, K, R, T));
    let (fxlo, fxhi) = (fwd(9.18, 6.25, K, R, T), fwd(9.28, 6.45, K, R, T));
    println!("F band {:.6} to {:.6}, q band {:.4}% to {:.4}%", flo, fhi, yld(fhi, R, T) * 100.0, yld(flo, R, T) * 100.0);
    println!("crossed: F low {:.6} above F high {:.6}", fxlo, fxhi);

    println!("nine strikes, each leg off by up to 0.05 at random");
    let mut g = Lcg(20260919);
    let gaps_n: Vec<f64> = strikes.iter().map(|&k| call(S, k, T) + g.noise() - put(S, k, T) - g.noise()).collect();
    let qs_n: Vec<f64> = strikes.iter().zip(&gaps_n).map(|(k, gp)| yld(k + gp * (R * T).exp(), R, T)).collect();
    let (dn, fn_) = line_fit(&strikes, &gaps_n); let rn = -dn.ln() / T; let qn = yld(fn_, rn, T);
    println!("chart, q by strike %{}", qs_n.iter().map(|v| format!("{:>6.2}", v * 100.0)).collect::<String>());
    let worst = qs_n.iter().fold(0.0_f64, |m, v| m.max((v - Q).abs()));
    let q_avg = qs_n.iter().sum::<f64>() / qs_n.len() as f64;
    pct("worst single-strike error in q", worst); pct("average of the nine, rate given", q_avg);
    row("fit, rate not given: forward F", fn_); pct("fit: rate r", rn); pct("fit: yield q", qn);
    pct("fit: carry r - q", rn - qn);
    let db = (gaps_n[3] - gaps_n[5]) / 10.0;
    println!("box on 95 and 105 only: r {:.4}%", -db.ln() / T * 100.0);
    println!("try: K = 120 alone gives F {:.6}", fwd(call(S, 120.0, T), put(S, 120.0, T), 120.0, R, T));

    assert!((c - 9.227005508154).abs() < 1e-9, "the call against the shelf's house number");
    assert!((p - 6.330080627550).abs() < 1e-9, "the put against the shelf's house number");
    assert!((f1 - carry).abs() < 1e-9, "one-strike forward against cash and carry");
    assert!((q1 - Q).abs() < 1e-9, "the yield comes back out of the two prices");
    assert!((q2 - q1).abs() < 1e-12, "bisection against the logarithm formula");
    assert!((r3 - R).abs() < 1e-9, "the box recovers the rate with no rate given");
    assert!((q3 - Q).abs() < 1e-9, "and the yield from its own rate");
    assert!((q4 - Q).abs() < 1e-6, "integral prices and a line fit: same yield");
    assert!(((qh - q1) - 0.10 * (R * T).exp() / (f1 * T)).abs() < 2e-5, "a put error moves q by e^rT / (F T) a dollar");
    assert!(qs > Q + 0.005, "a stale call drags the implied yield up");
    assert!(flo < f1 && f1 < fhi, "the live bid-ask band brackets the true forward");
    assert!(fxhi < f1 && f1 < fxlo, "a crossed quote turns the band inside out");
    assert!((q_avg - Q).abs() < worst / 3.0, "averaging nine strikes cuts the worst error threefold");
    assert!((fn_ - f1).abs() < 0.05, "the fitted forward survives the noise");
    assert!((-db.ln() / T - R).abs() > 5.0 * (rn - R).abs(), "close strikes magnify the noise in the rate");
    println!("ALL CHECKS PASS");
}
