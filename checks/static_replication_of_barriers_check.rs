// Static barrier hedges -- the same check as static_replication_of_barriers_check.py, in Rust.
// Standard library only, no crates.  Rust has no erf, so N(x) is built from its power
// series, N(x) = 1/2 + phi(x) (x + x^3/3 + x^5/15 + ...), whose terms all share one sign.
// Roads: the closed form; the Derman-Ergener-Kani calendar strip; the mirror claim by
// Simpson's rule against the lognormal density; the mirror claim as a fan of puts.
use std::f64::consts::PI;

const S0: f64 = 100.0; const K: f64 = 100.0; const B: f64 = 80.0; const S: f64 = 0.20; const T: f64 = 1.0;

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }
fn n_cdf(x: f64) -> f64 {
    if x.abs() > 9.0 { return if x > 0.0 { 1.0 } else { 0.0 }; }
    let (mut term, mut sum, mut k) = (x, x, 1.0);
    while term.abs() > 1e-17 * sum.abs().max(1e-300) { term *= x * x / (2.0 * k + 1.0); sum += term; k += 1.0; }
    0.5 + phi(x) * sum
}
fn bs(s: f64, k: f64, r: f64, q: f64, t: f64, cp: f64) -> f64 {
    if t <= 0.0 { return (cp * (s - k)).max(0.0); }
    let d1 = ((s / k).ln() + (r - q + 0.5 * S * S) * t) / (S * t.sqrt()); let d2 = d1 - S * t.sqrt();
    cp * (s * (-q * t).exp() * n_cdf(cp * d1) - k * (-r * t).exp() * n_cdf(cp * d2))
}
fn expo(r: f64, q: f64) -> f64 { 2.0 * (r - q) / (S * S) - 1.0 }
fn closed(s: f64, r: f64, q: f64) -> f64 { bs(s, K, r, q, T, 1.0) - (B / s).powf(expo(r, q)) * bs(B * B / s, K, r, q, T, 1.0) }
fn naive(s: f64, t: f64, r: f64, q: f64) -> f64 { bs(s, K, r, q, T - t, 1.0) - K / B * bs(s, B * B / K, r, q, T - t, -1.0) }

struct Strip { w: Vec<f64>, tj: Vec<f64>, tau: Vec<f64>, need: Vec<f64>, strike: f64 }
fn dek(n: usize, r: f64, q: f64, strike: f64) -> Strip {
    let tj: Vec<f64> = (0..n).map(|j| T * (j + 1) as f64 / n as f64).collect();
    let tau: Vec<f64> = (0..n).map(|j| T * j as f64 / n as f64).collect();
    let (mut w, mut need) = (vec![0.0; n], vec![0.0; n]);
    for j in (0..n).rev() {
        let t = tau[j];
        let mut v = bs(B, K, r, q, T - t, 1.0);
        for k in j + 1..n { v += w[k] * bs(B, strike, r, q, tj[k] - t, -1.0); }
        need[j] = v; w[j] = -v / bs(B, strike, r, q, tj[j] - t, -1.0);
    }
    Strip { w, tj, tau, need, strike }
}
fn strip(s: f64, t: f64, p: &Strip, r: f64, q: f64) -> f64 {
    let mut v = bs(s, K, r, q, T - t, 1.0);
    for (wk, tk) in p.w.iter().zip(&p.tj) { if *tk > t { v += wk * bs(s, p.strike, r, q, tk - t, -1.0); } }
    v
}
fn g(x: f64, r: f64, q: f64) -> f64 { (B / x).powf(expo(r, q)) * (B * B / x - K).max(0.0) }
fn claim(s: f64, t: f64, r: f64, q: f64) -> f64 {
    let m = 4000; let tau = T - t; let mu = s.ln() + (r - q - 0.5 * S * S) * tau; let sd = S * tau.sqrt();
    let (lo, hi) = (mu - 10.0 * sd, (B * B / K).ln()); let h = (hi - lo) / m as f64; let mut tot = 0.0;
    for i in 0..=m {
        let z = lo + i as f64 * h;
        let c = if i == 0 || i == m { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 };
        tot += c * g(z.exp(), r, q) * (-(z - mu).powi(2) / (2.0 * sd * sd)).exp() / (sd * (2.0 * PI).sqrt());
    }
    (-r * tau).exp() * tot * h / 3.0
}
fn fan(h: f64, r: f64, q: f64) -> (Vec<f64>, Vec<f64>) {
    let top = B * B / K; let ks: Vec<f64> = (0..(top / h) as usize).map(|i| top - i as f64 * h).collect();
    let sl: Vec<f64> = (0..ks.len() - 1).map(|i| (g(ks[i + 1], r, q) - g(ks[i], r, q)) / (ks[i + 1] - ks[i])).collect();
    let mut w = vec![-sl[0]]; for i in 1..sl.len() { w.push(sl[i - 1] - sl[i]); }
    (ks, w)
}
fn z(v: f64) -> f64 { if v.abs() < 1e-9 { 0.0 } else { v } }
fn out(label: &str, v: &[f64]) { println!("{:<40}{}", label, v.iter().map(|x| format!("{:>12.6}", z(*x))).collect::<String>()); }

fn main() {
    let (r, q) = (0.05, 0.02);
    let (c0, v0) = (bs(S0, K, r, q, T, 1.0), closed(S0, r, q));
    out("call C(100), down-and-out closed form", &[c0, v0]);
    out("a, mirror strike B^2/K, ratio K/B", &[expo(r, q), B * B / K, K / B]);
    out("call alone: worth on the wall at t=0", &[bs(B, K, r, q, T, 1.0)]);
    out("1.25 puts at 64: price, wall at t=0", &[naive(S0, 0.0, r, q), naive(B, 0.0, r, q)]);
    println!("DEK strip, 4 dates, solved backwards from the last");
    let p4 = dek(4, r, q, B);
    out("put at 80 on the wall, 0.25 .. 1 yr left", &p4.tj.iter().map(|&x| bs(B, B, r, q, x, -1.0)).collect::<Vec<f64>>());
    for j in (0..4).rev() {
        out(&format!("match t={:.2}: call, to cancel, weight", p4.tau[j]), &[bs(B, K, r, q, T - p4.tau[j], 1.0), p4.need[j], p4.w[j]]);
    }
    let pv: Vec<f64> = p4.tj.iter().map(|&tk| bs(S0, B, r, q, tk, -1.0)).collect();
    out("puts at 80, Acme at 100: 0.25 .. 1 yr", &pv);
    let s4 = strip(S0, 0.0, &p4, r, q);
    out("puts' cost, strip price, its error", &[-p4.w.iter().zip(&pv).map(|(a, b)| a * b).sum::<f64>(), s4, s4 - v0]);
    println!("dates   strip price   error (cents)");
    let mut errs = Vec::new();
    for n in [1, 2, 4, 12, 52, 252] {
        let p = strip(S0, 0.0, &dek(n, r, q, B), r, q); errs.push(p - v0);
        println!("{:>5}{:>14.6}{:>14.4}", n, p, 100.0 * (p - v0));
    }
    let ts: Vec<f64> = (0..20).map(|i| i as f64 / 20.0).collect();
    println!("chart, t        {}", ts.iter().map(|t| format!("{:>7.2}", t)).collect::<String>());
    println!("chart, strip    {}", ts.iter().map(|&t| format!("{:>7.3}", z(strip(B, t, &p4, r, q)))).collect::<String>());
    println!("chart, 1.25 put {}", ts.iter().map(|&t| format!("{:>7.3}", naive(B, t, r, q))).collect::<String>());
    let fine: Vec<f64> = (0..400).map(|i| i as f64 / 400.0).collect();
    let worst = |p: &Strip| fine.iter().map(|&t| strip(B, t, p, r, q)).fold(f64::INFINITY, f64::min);
    out("worst wall value: 4 dates, 52 dates", &[worst(&p4), worst(&dek(52, r, q, B))]);
    println!("mirror claim: payoff (B/x)^a (B^2/x - K)+ below 64");
    let m0 = claim(S0, 0.0, r, q);
    let c64 = bs(B * B / S0, K, r, q, T, 1.0);
    out("(B/S)^a, C(64), product, Simpson claim", &[(B / S0).powf(0.5), c64, (B / S0).powf(0.5) * c64, m0]);
    out("hedge price C - claim", &[c0 - m0]);
    let wall: Vec<f64> = [0.0, 0.5, 0.9].iter().map(|&t| bs(B, K, r, q, T - t, 1.0) - claim(B, t, r, q)).collect();
    out("wall at t=0, 0.5, 0.9: call - claim", &wall);
    println!("fan of puts below 64   puts   weight at 64   hedge price");
    let mut fans = Vec::new();
    for h in [16.0, 8.0, 4.0, 2.0, 1.0] {
        let (ks, wf) = fan(h, r, q);
        let price = c0 - ks.iter().zip(&wf).map(|(k, wk)| wk * bs(S0, *k, r, q, T, -1.0)).sum::<f64>();
        println!("spacing {:>4.0}{:>15}{:>15.6}{:>14.6}", h, wf.len(), wf[0], price);
        fans.push(price);
    }
    println!("r = q = 2%: the symmetry hedge is exact");
    let (_, wq) = fan(4.0, 0.02, 0.02); let pq52 = dek(52, 0.02, 0.02, B);
    let wq_other = wq[1..].iter().fold(0.0f64, |m, x| m.max(x.abs()));
    out("closed form, 1.25 puts at 64", &[closed(S0, 0.02, 0.02), naive(S0, 0.0, 0.02, 0.02)]);
    out("fan weight at 64, largest other weight", &[wq[0], wq_other]);
    let sq52 = strip(S0, 0.0, &pq52, 0.02, 0.02);
    out("DEK strip, 52 dates", &[sq52]);
    println!("what breaks");
    out("4 puts struck at 100 instead of 80", &[strip(S0, 0.0, &dek(4, r, q, K), r, q)]);
    let p12 = dek(12, r, q, B);
    out("try: 12 monthly dates, worst wall value", &[strip(S0, 0.0, &p12, r, q), worst(&p12)]);

    assert!((v0 - 9.133306).abs() < 1e-6, "house down-and-out price");
    assert!((c0 - m0 - v0).abs() < 1e-8, "Simpson mirror claim matches the closed form");
    assert!(wall.iter().all(|d| d.abs() < 1e-8), "call minus claim is zero on the wall");
    assert!((0..5).all(|i| errs[i + 1].abs() < errs[i].abs()), "strip error shrinks with dates");
    assert!(errs[5].abs() < 1e-4, "252-date strip within a hundredth of a cent");
    assert!((fans[4] - v0).abs() < 2e-4 && (fans[0] - v0).abs() > (fans[4] - v0).abs(), "fan converges");
    assert!((wq[0] - 1.25).abs() < 1e-9 && wq_other < 1e-9, "r = q fan is 1.25 puts");
    assert!((naive(S0, 0.0, 0.02, 0.02) - closed(S0, 0.02, 0.02)).abs() < 1e-9, "r = q: 1.25 puts at 64 is exact");
    assert!([0.0, 0.5, 0.9].iter().all(|&t| naive(B, t, 0.02, 0.02).abs() < 1e-9), "r = q: zero on the wall");
    assert!((sq52 - closed(S0, 0.02, 0.02)).abs() < 1e-3, "r = q strip");
    assert!(naive(B, 0.0, r, q).abs() > 0.1, "symmetry hedge fails on the wall when r != q");
    println!("ALL CHECKS PASS");
}
