// Backpropagation -- the same check as backpropagation_check.py, in Rust.  std only, no crates.
// A 2-3-1 network (2 inputs, 3 tanh hidden units, 1 output) on one synthetic order.
// Three roads to the gradient: backprop (reverse), forward mode, central differences.
// Every multiplication outside act() goes through mul() and is counted.
// Compile: rustc --edition 2021 -O backpropagation_check.rs -o /tmp/backpropagation
use std::cell::Cell;

thread_local! { static COUNT: Cell<u64> = Cell::new(0); }
fn mul(a: f64, b: f64) -> f64 { COUNT.with(|c| c.set(c.get() + 1)); a * b }
fn count() -> u64 { COUNT.with(|c| c.get()) }  fn reset() { COUNT.with(|c| c.set(0)); }

#[derive(Clone, Copy, PartialEq)] enum Kind { Tanh, Relu }
#[derive(Clone, Copy, PartialEq)] enum Slip { None, NoSlope, SlopeAtH }

fn act(z: f64, kind: Kind) -> (f64, f64) {          // squashing function and its slope: not counted
    match kind {
        Kind::Tanh => { let t = z.tanh(); (t, 1.0 - t * t) }
        Kind::Relu => if z > 0.0 { (z, 1.0) } else { (0.0, 0.0) },   // slope at the kink taken as 0
    }
}

// parameter layout: W1 (H rows of n), b1 (H), W2 (H), b2 (1)
fn forward(p: &[f64], x: &[f64], y: f64, n: usize, h: usize, kind: Kind) -> (Vec<f64>, Vec<f64>, f64, f64) {
    let mut z = Vec::new();
    for j in 0..h {
        let mut s = 0.0;
        for i in 0..n { s += mul(p[j * n + i], x[i]); }
        z.push(p[h * n + j] + s);
    }
    let hv: Vec<f64> = z.iter().map(|&zj| act(zj, kind).0).collect();
    let mut s = 0.0;
    for j in 0..h { s += mul(p[h * n + h + j], hv[j]); }
    let yhat = p[p.len() - 1] + s;
    let loss = mul(0.5, mul(yhat - y, yhat - y));
    (z, hv, yhat, loss)
}

fn backward(p: &[f64], x: &[f64], y: f64, n: usize, h: usize, kind: Kind, slip: Slip) -> (Vec<f64>, u64) {
    let (z, hv, yhat, _) = forward(p, x, y, n, h, kind);
    let start = count();
    let d_out = yhat - y;                             // dloss/dyhat for loss = (yhat - y)^2 / 2
    let gw2: Vec<f64> = (0..h).map(|j| mul(d_out, hv[j])).collect();
    let mut d_h = Vec::new();
    for j in 0..h {
        let slope = match slip {
            Slip::None => act(z[j], kind).1,
            Slip::NoSlope => 1.0,                     // mistake: skip the activation's slope
            Slip::SlopeAtH => act(hv[j], kind).1,     // mistake: slope read at h, not z
        };
        d_h.push(mul(mul(p[h * n + h + j], d_out), slope));
    }
    let mut g = Vec::new();
    for j in 0..h { for i in 0..n { g.push(mul(d_h[j], x[i])); } }
    g.extend(d_h); g.extend(gw2); g.push(d_out);
    (g, count() - start)
}

fn forward_mode(p: &[f64], x: &[f64], y: f64, n: usize, h: usize, k: usize) -> f64 {
    let dp: Vec<f64> = (0..p.len()).map(|m| if m == k { 1.0 } else { 0.0 }).collect();
    let (mut yhat, mut dyhat) = (p[p.len() - 1], dp[p.len() - 1]);
    for j in 0..h {
        let (mut z, mut dz) = (0.0, 0.0);
        for i in 0..n { z += mul(p[j * n + i], x[i]); }
        for i in 0..n { dz += mul(dp[j * n + i], x[i]); }
        z = p[h * n + j] + z; dz = dp[h * n + j] + dz;
        let (t, s) = act(z, Kind::Tanh);
        let w = h * n + h + j;
        yhat += mul(p[w], t); dyhat += mul(dp[w], t) + mul(p[w], mul(s, dz));
    }
    mul(yhat - y, dyhat)
}

fn central(p: &[f64], x: &[f64], y: f64, n: usize, h: usize, k: usize, step: f64, kind: Kind) -> f64 {
    let (mut up, mut dn) = (p.to_vec(), p.to_vec()); up[k] += step; dn[k] -= step;
    (forward(&up, x, y, n, h, kind).3 - forward(&dn, x, y, n, h, kind).3) / (2.0 * step)
}

fn commas(v: u64) -> String {
    let s = v.to_string(); let mut out = String::new();
    for (i, ch) in s.chars().enumerate() {
        if i > 0 && (s.len() - i) % 3 == 0 { out.push(','); }
        out.push(ch);
    }
    out
}

fn main() {
    // the order: basket £100 and 5 items in, next month's spend £120 out (units of £100, tens)
    let (x, y, n, h) = ([1.0_f64, 0.5], 1.2_f64, 2usize, 3usize);
    let p = [0.5, -0.4, 0.3, 0.8, -0.6, 0.2, 0.1, -0.2, 0.0, 0.7, -0.5, 0.4, 0.6_f64];
    let names = ["w11", "w12", "w21", "w22", "w31", "w32", "b1", "b2", "b3", "v1", "v2", "v3", "c"];
    let (z, hv, yhat, loss) = forward(&p, &x, y, n, h, Kind::Tanh);
    let g = backward(&p, &x, y, n, h, Kind::Tanh, Slip::None).0;
    let gf: Vec<f64> = (0..13).map(|k| forward_mode(&p, &x, y, n, h, k)).collect();
    let gc: Vec<f64> = (0..13).map(|k| central(&p, &x, y, n, h, k, 1e-5, Kind::Tanh)).collect();
    let mut rows: Vec<(String, f64)> = Vec::new();
    for j in 0..3 { rows.push((format!("z{}", j + 1), z[j])); }
    for j in 0..3 { rows.push((format!("h{} = tanh(z{})", j + 1, j + 1), hv[j])); }
    rows.push(("yhat, in hundreds of pounds".into(), yhat)); rows.push(("yhat, in pounds".into(), 100.0 * yhat));
    rows.push(("loss (yhat - y)^2 / 2".into(), loss));
    rows.push(("delta_out = yhat - y".into(), yhat - y));
    for j in 0..3 { rows.push((format!("delta_h{}", j + 1), g[6 + j])); }
    rows.push(("tanh slope 1 - h1^2".into(), 1.0 - hv[0] * hv[0]));
    for (a, v) in &rows { println!("{:<34} {:>14.6}", a, v); }
    println!("{:<6}{:>16}{:>16}{:>16}", "param", "backprop", "forward mode", "central diff");
    for k in 0..13 { println!("{:<6}{:>16.10}{:>16.10}{:>16.10}", names[k], g[k], gf[k], gc[k]); }
    let worst_c = (0..13).map(|k| (g[k] - gc[k]).abs()).fold(0.0, f64::max);
    let worst_f = (0..13).map(|k| (g[k] - gf[k]).abs()).fold(0.0, f64::max);
    println!("all 13 agree with central diff to 1e-9: {}", if worst_c < 1e-9 { "yes" } else { "NO" });
    println!("all 13 agree with forward mode to 1e-12: {}", if worst_f < 1e-12 { "yes" } else { "NO" });

    // one step downhill, learning rate 0.1
    let eta = 0.1;
    let down: Vec<f64> = (0..13).map(|k| p[k] - eta * g[k]).collect();
    let upw: Vec<f64> = (0..13).map(|k| p[k] + eta * g[k]).collect();
    let loss_down = forward(&down, &x, y, n, h, Kind::Tanh).3;
    let loss_up = forward(&upw, &x, y, n, h, Kind::Tanh).3;
    let predicted = eta * g.iter().map(|v| v * v).sum::<f64>();

    // what breaks
    let no_slope = backward(&p, &x, y, n, h, Kind::Tanh, Slip::NoSlope).0[0];
    let at_h = backward(&p, &x, y, n, h, Kind::Tanh, Slip::SlopeAtH).0[0];
    let mut big = p.to_vec(); big[0] += 0.1;
    let fwd_big = (forward(&big, &x, y, n, h, Kind::Tanh).3 - loss) / 0.1;
    let mut r = p.to_vec();
    r[8] = -(0.0 + r[4] * x[0] + r[5] * x[1]);         // ReLU net: unit 3 sits on its kink
    let r_bp = backward(&r, &x, y, n, h, Kind::Relu, Slip::None).0[4] + 0.0;
    let r_cd = central(&r, &x, y, n, h, 4, 1e-5, Kind::Relu);
    let mut rr = r.clone(); rr[4] += 1e-6;
    let r_right = (forward(&rr, &x, y, n, h, Kind::Relu).3 - forward(&r, &x, y, n, h, Kind::Relu).3) / 1e-6;
    let more = [("step: loss after", loss_down), ("step: actual drop", loss - loss_down),
        ("step: predicted drop eta*|g|^2", predicted), ("wrong sign: loss after", loss_up),
        ("wrong: no tanh slope, dL/dw11", no_slope), ("wrong: slope read at h, dL/dw11", at_h),
        ("wrong: forward diff step 0.1", fwd_big), ("relu kink z3 = 0: backprop dL/dw31", r_bp),
        ("relu kink: central diff", r_cd), ("relu kink: slope from the right", r_right)];
    for (a, v) in &more { println!("{:<34} {:>14.6}", a, v); }

    // cost: multiplies for one full gradient; 12 inputs = an order's 12 numbers
    println!("{:<9}{:>7}{:>9}{:>10}{:>10}{:>10}{:>7}", "network", "params", "forward", "backprop", "fwd mode", "central", "ratio");
    let mut costs = Vec::new();
    for (nn, hh) in [(2usize, 3usize), (12, 4), (12, 16), (12, 64)] {
        let pp: Vec<f64> = (0..nn * hh + 2 * hh + 1).map(|m| 0.01 * (((7 * m) % 11) as f64 - 5.0)).collect();
        let xx: Vec<f64> = (0..nn).map(|i| 0.1 * (i + 1) as f64).collect();
        reset(); forward(&pp, &xx, 1.0, nn, hh, Kind::Tanh); let fc = count();
        let bc = backward(&pp, &xx, 1.0, nn, hh, Kind::Tanh, Slip::None).1;
        reset(); for k in 0..pp.len() { forward_mode(&pp, &xx, 1.0, nn, hh, k); } let fm = count();
        reset(); for k in 0..pp.len() { central(&pp, &xx, 1.0, nn, hh, k, 1e-5, Kind::Tanh); } let cc = count();
        costs.push((nn, hh, pp.len() as u64, fc, bc, cc));
        println!("{:<9}{:>7}{:>9}{:>10}{:>10}{:>10}{:>7.1}", format!("{}-{}-1", nn, hh), pp.len(), fc, fc + bc, fm, cc,
            cc as f64 / (fc + bc) as f64);
    }
    let (_, _, _, f16, b16, c16) = costs[2];
    println!("20,000 orders, 12-16-1, backprop: {} multiplies", commas(20000 * (f16 + b16)));
    println!("20,000 orders, 12-16-1, central:  {} multiplies", commas(20000 * c16));

    assert!((g[0] - (-0.4491751254)).abs() < 1e-9, "the hand-worked gradient for w11");
    assert!(worst_c < 1e-9, "backprop vs central differences, all 13 parameters");
    assert!(worst_f < 1e-12, "backprop vs forward mode, all 13 parameters");
    assert!(((loss - loss_down) - predicted).abs() < 0.2 * predicted, "first-order drop prediction");
    assert!(loss_up > loss && loss > loss_down, "downhill lowers the loss, uphill raises it");
    assert!((r_cd - 0.5 * r_right).abs() < 1e-6, "at the kink, central diff averages the two sides");
    assert!((r_bp - r_cd).abs() > 0.1, "at the kink, backprop and central diff disagree");
    for (nn, hh, pp, fc, bc, cc) in costs {
        assert!(fc == (nn as u64 + 1) * hh as u64 + 2, "counted forward multiplies vs (n + 1)H + 2");
        assert!(fc + bc == 2 * pp, "counted backprop multiplies vs two per parameter");
        assert!(cc == 2 * pp * fc, "counted central-difference multiplies vs 2 x params x forward");
    }
    println!("ALL CHECKS PASS");
}
