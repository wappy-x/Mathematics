// Theta pays for gamma -- the same check as theta_pays_for_gamma_hedged_pnl_check.py, in Rust.
// Standard library only, no crates.  The bell-curve area is the same power series written
// out; the random numbers are splitmix64 and Box-Muller; the root finder is bisection.
// Compile: rustc --edition 2021 -O theta_pays_for_gamma_hedged_pnl_check.rs -o /tmp/tpg_check
use std::f64::consts::PI;

const K: f64 = 100.0; const R: f64 = 0.05; const Q: f64 = 0.02;
const SIG: f64 = 0.20; const T: f64 = 1.0; const S0: f64 = 100.0;

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }
fn n_cdf(x: f64) -> f64 {
    if x.abs() > 9.0 { return if x < 0.0 { 0.0 } else { 1.0 }; }
    let (mut term, mut total, mut k) = (x, x, 1.0);
    while term.abs() > 1e-18 * total.abs() { term *= x * x / (2.0 * k + 1.0); total += term; k += 1.0; }
    0.5 + phi(x) * total
}
fn d1(s: f64, v: f64, t: f64) -> f64 { ((s / K).ln() + (R - Q + 0.5 * v * v) * t) / (v * t.sqrt()) }
fn call(s: f64, v: f64, t: f64) -> f64 {
    let a = d1(s, v, t);
    s * (-Q * t).exp() * n_cdf(a) - K * (-R * t).exp() * n_cdf(a - v * t.sqrt())
}
fn dg(s: f64, t: f64) -> (f64, f64) {
    let a = d1(s, SIG, t);
    ((-Q * t).exp() * n_cdf(a), (-Q * t).exp() * phi(a) / (s * SIG * t.sqrt()))
}
fn theta(s: f64, v: f64, t: f64) -> f64 {
    let a = d1(s, v, t); let b = a - v * t.sqrt();
    -s * (-Q * t).exp() * phi(a) * v / (2.0 * t.sqrt()) - R * K * (-R * t).exp() * n_cdf(b) + Q * s * (-Q * t).exp() * n_cdf(a)
}

struct Normals { x: u64, spare: Option<f64> }
impl Normals {
    fn u(&mut self) -> f64 {
        self.x = self.x.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = (self.x ^ (self.x >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        (((z ^ (z >> 31)) >> 11) as f64 + 0.5) / 9007199254740992.0
    }
    fn next(&mut self) -> f64 {
        if let Some(z) = self.spare.take() { return z; }
        let (a, b) = (self.u(), self.u()); let rr = (-2.0 * a.ln()).sqrt();
        self.spare = Some(rr * (2.0 * PI * b).sin());
        rr * (2.0 * PI * b).cos()
    }
}

// Seller of the call at 20%, delta-hedged n times; the world moves at sw with drift mu.
fn hedge(n: usize, sw: f64, mu: f64, v0: f64, d0: f64, g0: f64) -> (Vec<f64>, Vec<f64>, Vec<(usize, f64, f64, f64)>) {
    let d_t = T / n as f64; let mut g = Normals { x: 2026, spare: None };
    let (mut out, mut pred, mut story) = (Vec::new(), Vec::new(), Vec::new());
    for p in 0..2000 {
        let (mut s, mut dl, mut gm, mut cash, mut gs) = (S0, d0, g0, v0 - d0 * S0, 0.0);
        for i in 0..n {
            let sn = s * ((mu - 0.5 * sw * sw) * d_t + sw * d_t.sqrt() * g.next()).exp();
            cash = cash * (R * d_t).exp() + Q * dl * s * d_t;
            gs += 0.5 * gm * (SIG * SIG * s * s * d_t - (sn - s) * (sn - s)) * (R * (T - (i + 1) as f64 * d_t)).exp();
            s = sn; let left = T - (i + 1) as f64 * d_t;
            if i < n - 1 { let (dn, gn) = dg(s, left); gm = gn; cash -= (dn - dl) * s; dl = dn; }
            if p == 0 && (i + 1) % (n / 4) == 0 {
                let owed = if left > 1e-12 { call(s, SIG, left) } else { (s - K).max(0.0) };
                story.push((i + 1, s, cash + dl * s - owed, gs));
            }
        }
        out.push(cash + dl * s - (s - K).max(0.0)); pred.push(gs);
    }
    (out, pred, story)
}
fn stats(xs: &[f64]) -> (f64, f64, f64) {
    let n = xs.len() as f64; let m = xs.iter().sum::<f64>() / n;
    let sd = (xs.iter().map(|x| (x - m) * (x - m)).sum::<f64>() / (n - 1.0)).sqrt();
    (m, sd, sd / n.sqrt())
}

fn main() {
    // ---- road 1: the identity, with delta and gamma found by bumping the price ----
    let (v, th) = (call(S0, SIG, T), theta(S0, SIG, T));
    let (d, g) = dg(S0, T);
    let h = 0.01;
    let db = (call(S0 + h, SIG, T) - call(S0 - h, SIG, T)) / (2.0 * h);
    let gb = (call(S0 + h, SIG, T) - 2.0 * v + call(S0 - h, SIG, T)) / (h * h);
    let thb = (call(S0, SIG, T - 1e-4) - call(S0, SIG, T + 1e-4)) / 2e-4;
    let (rent, carry, fund) = (0.5 * SIG * SIG * S0 * S0 * gb, (R - Q) * S0 * db, R * v);
    let th_id = fund - carry - rent;
    // ---- road 2: one trading day, revalued in full, for the seller of the call ----
    let dt = 1.0 / 252.0;
    let day_pnl = |ds: f64| -(call(S0 + ds, SIG, T - dt) - v) + d * ds + (v - d * S0) * ((R * dt).exp() - 1.0) + Q * d * S0 * dt;
    let bisect = |mut a: f64, mut b: f64| {
        for _ in 0..200 { let m = 0.5 * (a + b); if (day_pnl(a) > 0.0) == (day_pnl(m) > 0.0) { a = m } else { b = m } }
        0.5 * (a + b)
    };
    let (up, dn, be) = (bisect(0.0, 5.0), bisect(-5.0, 0.0), SIG * S0 * dt.sqrt());
    let rows: Vec<(&str, f64)> = vec![("call price V", v), ("delta, formula", d), ("delta, bumped", db), ("gamma, formula", g),
        ("gamma, bumped", gb), ("theta per year, formula", th), ("theta per year, bumped clock", thb),
        ("rent  1/2 sig^2 S^2 gamma", rent), ("carry (r-q) S delta", carry), ("funding r V", fund),
        ("theta from the identity", th_id), ("rent per trading day", rent * dt),
        ("theta per trading day", th * dt), ("theta per calendar day", th / 365.0),
        ("carry less funding per trading day", (carry - fund) * dt),
        ("break-even move sig S root(dt)", be), ("break-even, weekly hedge", SIG * S0 * (5.0 * dt).sqrt()),
        ("break-even up, bisection", up),
        ("break-even down, bisection", dn), ("  average size", 0.5 * (up - dn)),
        ("wrong: drop the 1/2, theta", fund - carry - 2.0 * rent),
        ("wrong: sigma not sigma^2, theta", fund - carry - rent / SIG),
        ("wrong: theta = -rent alone", -rent), ("wrong: sig S dt, break-even", SIG * S0 * dt),
        ("wrong: unfinanced break-even", (-2.0 * th * dt / g).sqrt())];
    for (name, x) in &rows { println!("{:<34} {:>12.6}", name, x); }
    let moves: Vec<f64> = (0..13).map(|i| -3.0 + 0.5 * i as f64).collect();
    println!("chart, move ($)   {}", moves.iter().map(|m| format!("{:6.1}", m)).collect::<Vec<_>>().join(" "));
    println!("chart, cents      {}", moves.iter().map(|m| format!("{:6.2}", 100.0 * day_pnl(*m))).collect::<Vec<_>>().join(" "));

    // ---- road 3: hedge 2,000 simulated years, rebalancing n times ----
    let (a, ap, story) = hedge(252, 0.20, R - Q, v, d, g);
    println!("story: day, Acme, seller's P&L marked, gamma-weighted sum");
    for (day, s, mark, gs) in &story { println!("  day {:>3}   Acme {:7.2}   P&L {:+8.4}   sum {:+8.4}", day, s, mark, gs); }
    println!("rebalances   mean      sd   sd*root(n)");
    let mut sds = [0.0; 3];
    for (j, n) in [21usize, 63, 252].iter().enumerate() {
        let xs = if *n == 252 { a.clone() } else { hedge(*n, 0.20, R - Q, v, d, g).0 };
        let (m, sd, _) = stats(&xs); sds[j] = sd;
        println!("  n = {:>3}  {:+.4}  {:.4}  {:.4}", n, m, sd, sd * (*n as f64).sqrt());
    }
    let (ma, sda, sea) = stats(&a);
    let diff = stats(&a.iter().zip(&ap).map(|(x, y)| x - y).collect::<Vec<_>>());
    let mut srt = a.clone(); srt.sort_by(|x, y| x.partial_cmp(y).unwrap());
    println!("daily, 20% world: std error {:.4}; 5th pct {:+.4}; 95th pct {:+.4}", sea, srt[99], srt[1899]);
    println!("daily, 20% world: gamma-sum mean {:+.4}; sd of (P&L - sum) {:.4}", stats(&ap).0, diff.1);
    let (cw, cp, _) = hedge(252, 0.30, R - Q, v, d, g);
    let (mc, sdc, sec) = stats(&cw); let gap = call(S0, 0.30, T) - v;
    println!("daily, 30% world: mean {:+.4}  sd {:.4}  std error {:.4}  gamma-sum mean {:+.4}", mc, sdc, sec, stats(&cp).0);
    let best = cw.iter().cloned().fold(f64::MIN, f64::max);
    println!("daily, 30% world: paths that made money {}; best path {:+.4}", cw.iter().filter(|x| **x > 0.0).count(), best);
    let vega = S0 * (-Q * T).exp() * phi(d1(S0, SIG, T)) * T.sqrt();
    println!("price gap C(30%) - C(20%) {:.4}; carried to expiry {:.4}; vega x 0.10 {:.4}", gap, gap * (R * T).exp(), 0.10 * vega);
    let md = stats(&hedge(252, 0.20, 0.15, v, d, g).0);
    println!("daily, 20% world, drift 15%: mean {:+.4}  sd {:.4}", md.0, md.1);
    let edges: Vec<f64> = (0..22).map(|i| -9.0 + 0.5 * i as f64).collect();
    let hist = |xs: &[f64]| -> Vec<usize> {
        edges.iter().map(|lo| xs.iter().filter(|x| { let c = x.max(-8.999).min(1.999); *lo <= c && c < lo + 0.5 }).count()).collect()
    };
    println!("hist, bin start {}", edges.iter().map(|e| format!("{:5.1}", e)).collect::<Vec<_>>().join(" "));
    println!("hist, 20% world {}", hist(&a).iter().map(|c| format!("{:5}", c)).collect::<Vec<_>>().join(" "));
    println!("hist, 30% world {}", hist(&cw).iter().map(|c| format!("{:5}", c)).collect::<Vec<_>>().join(" "));

    assert!((th - (-5.089319)).abs() < 5e-7, "theta vs the house number from the theta card");
    assert!((th_id - th).abs() < 1e-5, "identity with bumped Greeks vs the closed-form theta");
    assert!((thb - th).abs() < 1e-6, "bumped clock vs the closed-form theta");
    assert!((0.5 * (up - dn) - be).abs() < 0.002, "full-revaluation break-even vs sig S root(dt)");
    assert!(ma.abs() < 3.0 * sea, "matched world: hedge centred on zero");
    assert!((sds[0] / sds[2] / 12f64.sqrt() - 1.0).abs() < 0.1, "spread falls like one over root n");
    assert!((mc + gap * (R * T).exp()).abs() < 4.0 * sec, "30% world: loss is the price gap carried forward");
    assert!(diff.1 < 0.25 * sda, "the gamma-weighted sum tracks each path");
    println!("ALL CHECKS PASS");
}
