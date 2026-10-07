// Cox-Ross-Rubinstein -- the same check as the Python, in Rust.  No crates.
// Nothing here already knows the answer either: the area under the bell curve
// is Simpson's rule written out, and the limit the tree chases is reached
// twice.  Acme: S = 100, K = 100, r = 5%, q = 2%, sigma = 20%, one year, a call.
use std::collections::BTreeMap;
use std::f64::consts::PI;

const S: f64 = 100.0;
const K: f64 = 100.0;
const R: f64 = 0.05;
const Q: f64 = 0.02;
const SIG: f64 = 0.20;
const T: f64 = 1.0;
const HOUSE: f64 = 9.227005508154;      // the shelf's Black-Scholes call price

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }   // height at x

fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;         // area under f from a to b, n panels
    let mut s = f(a) + f(b);
    for i in 1..n {
        s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h);
    }
    s * h / 3.0
}

fn ncdf(x: f64) -> f64 { 0.5 + simpson(phi, 0.0, x, 2000) }   // bell-curve area left of x

fn bs_call() -> f64 {                   // road 3: the continuous formula
    let vt = SIG * T.sqrt();
    let d1 = ((S / K).ln() + (R - Q + 0.5 * SIG * SIG) * T) / vt;
    S * (-Q * T).exp() * ncdf(d1) - K * (-R * T).exp() * ncdf(d1 - vt)
}

fn bs_slices() -> f64 {                 // road 4: average the payoff by brute force
    let f = |z: f64| {
        let st = S * ((R - Q - 0.5 * SIG * SIG) * T + SIG * T.sqrt() * z).exp();
        (st - K).max(0.0) * phi(z)
    };
    (-R * T).exp() * simpson(f, -9.0, 9.0, 36000)
}

fn params(n: usize, root: bool, div: bool) -> [f64; 6] {
    let dt = T / n as f64;              // the CRR step: two sizes and a weight
    let a = if root { SIG * dt.sqrt() } else { SIG * dt };   // one step's log move
    let (u, d) = (a.exp(), (-a).exp());
    let grow = if div { ((R - Q) * dt).exp() } else { (R * dt).exp() };
    [dt, a, u, d, (grow - d) / (u - d), (-R * dt).exp()]
}

fn tree(n: usize, coin: f64, root: bool, div: bool) -> f64 {
    let [_, a, _, _, mut p, disc] = params(n, root, div);     // road 1: backwards
    if coin >= 0.0 { p = coin; }
    let mut v: Vec<f64> = (0..=n)
        .map(|j| (S * ((2.0 * j as f64 - n as f64) * a).exp() - K).max(0.0))
        .collect();
    for step in (1..=n).rev() {
        for j in 0..step { v[j] = disc * (p * v[j + 1] + (1.0 - p) * v[j]); }
    }
    v[0]
}

fn weights(n: usize) -> (f64, f64) {    // road 2: one weighted sum over the ends
    let [_, a, _, _, p, _] = params(n, true, true);
    let mut w = vec![0.0f64; n + 1];
    let mid = (n as f64 * p) as usize;  // start at the fattest end node, weight 1
    w[mid] = 1.0;
    for j in mid..n { w[j + 1] = w[j] * (n - j) as f64 * p / ((j + 1) as f64 * (1.0 - p)); }
    for j in (1..=mid).rev() { w[j - 1] = w[j] * j as f64 * (1.0 - p) / ((n - j + 1) as f64 * p); }
    let (mut total, mut price, mut mean) = (0.0, 0.0, 0.0);
    for j in 0..=n {
        let st = S * ((2.0 * j as f64 - n as f64) * a).exp();
        total += w[j];
        price += w[j] * (st - K).max(0.0);
        mean += w[j] * st;
    }
    ((-R * T).exp() * price / total, mean / total)
}

fn moments(n: usize) -> (f64, f64) {    // what one step's log move actually does
    let [dt, a, _, _, p, _] = params(n, true, true);
    let mean = a * (2.0 * p - 1.0);
    (mean / dt, (a * a - mean * mean) / (SIG * SIG * dt))
}

fn predicted(n: usize) -> (f64, f64) {  // the same two, from the expansion
    let drift = R - Q - 0.5 * SIG * SIG;
    (drift, 1.0 - (drift / SIG).powi(2) * (T / n as f64))
}

fn row(label: &str, value: f64, tail: &str) { println!("{:<46}{:>11.6}{}", label, value, tail); }

fn main() {
    println!("Acme on a tree: S {:.2}  K {:.2}  r 5%  q 2%  sigma 20%  T 1 year, a call", S, K);
    for (label, n) in [("one step ", 1usize), ("two steps", 2)] {
        let [dt, a, u, d, p, disc] = params(n, true, true);
        let ends: Vec<f64> = (0..=n).rev()
            .map(|j| S * ((2.0 * j as f64 - n as f64) * a).exp()).collect();
        println!("{}  dt {:.6}  u {:.6}  d {:.6}  grow {:.6}  p {:.6}  discount {:.6}",
                 label, dt, u, d, ((R - Q) * dt).exp(), p, disc);
        println!("  ends at  {}; the call pays {:.6} at the top",
                 ends.iter().map(|e| format!("{:.6}", e)).collect::<Vec<_>>().join(", "),
                 (ends[0] - K).max(0.0));
    }
    let (limit, slices) = (bs_call(), bs_slices());
    let forward = S * ((R - Q) * T).exp();
    let mean_2000 = weights(2000).1;
    row("tree price, 1 step", tree(1, -1.0, true, true), "");
    row("tree price, 2 steps", tree(2, -1.0, true, true), "");
    row("Black-Scholes limit, by formula", limit, "");
    row("the same limit, by brute-force average", slices, "");
    row("tree average end price, 2000 steps", mean_2000, "");
    row("the forward, S e^(r-q)T", forward, "");
    println!();
    println!("steps  tree price  weighted sum   error vs the limit");
    let (mut gap, mut priced) = (0.0f64, BTreeMap::new());
    for n in [10usize, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21,
              50, 100, 250, 500, 1000, 2000, 2001] {
        let (c, w) = (tree(n, -1.0, true, true), weights(n).0);
        priced.insert(n, c);
        gap = gap.max((c - w).abs());
        println!("{:>5}  {:>10.6}  {:>12.6}   {:>+12.6}", n, c, w, c - limit);
    }
    println!("chart, steps 10 to 21, tree price to the cent");
    println!("  {}   the limit {:.2}", (10..22).map(|n| format!("{:.2}", priced[&n]))
             .collect::<Vec<_>>().join("  "), limit);
    println!();
    let pair = 0.5 * (priced[&2000] + priced[&2001]);
    row("average of the 2000- and 2001-step prices", pair, "");
    row("its error, where 2000 steps alone is off by", pair - limit,
        &format!("   (2000 steps: {:+.6})", priced[&2000] - limit));
    let mut straddle = 0;
    for n in 10..41 {
        if (tree(n, -1.0, true, true) - limit) * (tree(n + 1, -1.0, true, true) - limit) < 0.0 {
            straddle += 1;
        }
    }
    println!("{:<46}{:>11} of 31", "consecutive step counts on opposite sides, 10 to 41", straddle);
    for n in [10usize, 2000] {
        let ((drift, spread), (p_drift, p_spread)) = (moments(n), predicted(n));
        row(&format!("one step log drift / dt, {} steps", n), drift,
            &format!("   predicted {:.6}", p_drift));
        row(&format!("one step spread / (sigma^2 dt), {} steps", n), spread,
            &format!("   predicted {:.6}", p_spread));
    }
    println!();
    row("wrong: dividend left out of p, 2000 steps", tree(2000, -1.0, true, false), "");
    row("wrong: jump sigma*dt, not sigma*sqrt(dt)", tree(2000, -1.0, false, true), "");
    row("wrong: a fair coin, p = 0.5, 2000 steps", tree(2000, 0.5, true, true), "");
    row("wrong: stopping at 10 steps, calling it done", priced[&10], "");
    let thin = 0.02;                          // a share that hardly moves at all
    let bad_p = (((R - Q) * T).exp() - (-thin as f64).exp()) / ((thin as f64).exp() - (-thin as f64).exp());
    row("wrong: sigma 2% on a year-long step, p =", bad_p, "");
    assert!(bad_p > 1.0);                         // too few steps and p stops being a weight
    assert!(gap < 1e-9);                          // recursion vs one weighted sum
    assert!((limit - HOUSE).abs() < 1e-9);        // own formula vs the house price
    assert!((slices - limit).abs() < 1e-7);       // brute-force average vs formula
    assert!((mean_2000 - forward).abs() < 1e-9);  // average end price is the forward
    assert!((priced[&2000] - limit).abs() < 1e-3);         // inside a tenth of a cent
    assert!((priced[&2000] - limit).abs() < (priced[&250] - limit).abs());
    assert!((priced[&250] - limit).abs() < (priced[&10] - limit).abs());
    assert!(straddle == 31);                      // every consecutive pair straddles
    assert!((pair - limit).abs() < 0.05 * (priced[&2000] - limit).abs());
    for n in [10usize, 250, 2000] {           // the drift, then the spread, against Step 3
        assert!((moments(n).0 - predicted(n).0).abs() < 1e-3 * T / n as f64);
        assert!((moments(n).1 - predicted(n).1).abs() < 1e-3 * T / n as f64);
    }
    println!("ALL CHECKS PASS");
}
