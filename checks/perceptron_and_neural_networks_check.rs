// The perceptron and its stack -- the same check as the Python, in Rust.  std only, no crates.
// The orders are synthetic: eight made up by hand, and 1,000 drawn by SplitMix64 (seed 2026).
// Compile: rustc --edition 2021 -O perceptron_and_neural_networks_check.rs -o /tmp/perceptron_check

type Order = (String, f64, f64, f64);                    // name, x1, x2, label (+1 fraud, -1 normal)

fn splitmix64(state: u64) -> (u64, f64) {                // returns (new state, uniform in [0, 1))
    let s = state.wrapping_add(0x9E3779B97F4A7C15);
    let mut z = s;
    z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    (s, ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0)
}

struct Run { w1: f64, w2: f64, b: f64, updates: usize, per_pass: Vec<usize> }

// The perceptron rule: on a mistake, w <- w + eta*y*x and b <- b + eta*y.
fn train(data: &[Order], eta: f64, max_passes: usize, strict: bool, use_bias: bool,
         log: &mut Vec<(usize, usize, String, f64, f64, f64, f64)>) -> Run {
    let (mut w1, mut w2, mut b) = (0.0f64, 0.0f64, 0.0f64);
    let (mut updates, mut per_pass) = (0usize, Vec::new());
    for p in 0..max_passes {
        let mut mistakes = 0;
        for (name, x1, x2, y) in data {
            let s = w1 * x1 + w2 * x2 + b;
            let wrong = if strict { y * s < 0.0 } else { y * s <= 0.0 };
            if wrong {
                w1 += eta * y * x1; w2 += eta * y * x2;
                if use_bias { b += eta * y; }
                mistakes += 1; updates += 1;
                log.push((updates, p + 1, name.clone(), s, w1, w2, b));
            }
        }
        per_pass.push(mistakes);
        if mistakes == 0 { break; }
    }
    Run { w1, w2, b, updates, per_pass }
}
fn tr(data: &[Order], eta: f64, max_passes: usize, strict: bool, use_bias: bool) -> Run {
    train(data, eta, max_passes, strict, use_bias, &mut Vec::new())
}

fn correct(data: &[Order], w1: f64, w2: f64, b: f64) -> usize {      // fraud if the score is above 0
    data.iter().filter(|(_, x1, x2, y)| (if w1 * x1 + w2 * x2 + b > 0.0 { 1.0 } else { -1.0 }) == *y).count()
}

fn bound(data: &[Order], u: (f64, f64, f64)) -> (f64, f64, f64) {   // the stopping bound: updates <= (R / gamma)^2
    let n = (u.0 * u.0 + u.1 * u.1 + u.2 * u.2).sqrt();
    let r = data.iter().map(|(_, x1, x2, _)| (x1 * x1 + x2 * x2 + 1.0).sqrt()).fold(f64::MIN, f64::max);
    let g = data.iter().map(|(_, x1, x2, y)| y * (u.0 * x1 + u.1 * x2 + u.2) / n).fold(f64::MAX, f64::min);
    (r, g, (r / g).powi(2))
}

fn step(s: f64) -> f64 { if s > 0.0 { 1.0 } else { 0.0 } }
fn lam(s: f64) -> f64 { 1.0 / (1.0 + (-s).exp()) }                 // the logistic squashing function
fn matvec(w: &[[f64; 2]], x: &[f64; 2]) -> Vec<f64> {
    w.iter().map(|row| row[0] * x[0] + row[1] * x[1]).collect()
}
const W1: [[f64; 2]; 2] = [[1.0, 1.0], [1.0, 1.0]];
const B1: [f64; 2] = [-0.5, -1.5];
const W2: [f64; 2] = [1.0, -1.0];
const B2: f64 = -0.5;
fn net(x: [f64; 2], f: fn(f64) -> f64, k: f64) -> (Vec<f64>, f64) {
    let h: Vec<f64> = matvec(&W1, &x).iter().zip(B1.iter()).map(|(s, c)| f(k * (s + c))).collect();
    let o = f(k * (W2[0] * h[0] + W2[1] * h[1] + B2));
    (h, o)
}

fn main() {
    // ---- eight orders: value in pounds, distance billing-to-delivery in km ----
    let raw = [("A", 100.0, 100.0, -1.0), ("B", 800.0, 600.0, 1.0), ("C", 700.0, 100.0, -1.0),
               ("D", 200.0, 600.0, -1.0), ("E", 500.0, 500.0, 1.0), ("F", 600.0, 400.0, 1.0),
               ("G", 400.0, 200.0, -1.0), ("H", 300.0, 400.0, -1.0)];
    let ord: Vec<Order> = raw.iter().map(|&(n, v, d, y)| (n.to_string(), (v - 400.0) / 100.0, (d - 300.0) / 100.0, y)).collect();
    let mut log = Vec::new();
    let m = train(&ord, 1.0, 1000, false, true, &mut log);
    for (u, p, name, s, a1, a2, a3) in &log {
        println!("update {}  pass {}  order {}  score {:+.0}  ->  w = ({:.0}, {:.0})  b = {:.0}", u, p, name, s, a1, a2, a3);
    }
    println!("mistakes per pass {:?}; updates {}; right {} of 8", m.per_pass, m.updates, correct(&ord, m.w1, m.w2, m.b));
    let sc: Vec<String> = ord.iter().map(|(n, x1, x2, _)| format!("{} {:+.0}", n, m.w1 * x1 + m.w2 * x2 + m.b)).collect();
    println!("settled scores {}", sc.join(" "));
    println!("order A's score just after update 1: {:+}", 3 * -3 + 2 * -2 - 1);
    let (r8, g8, b8) = bound(&ord, (m.w1, m.w2, m.b));
    println!("8 orders: R = {:.4}  gamma = {:.4}  bound (R/gamma)^2 = {:.1}", r8, g8, b8);
    let r2 = ord.iter().map(|(_, x1, x2, _)| (x1 * x1 + x2 * x2).sqrt()).fold(f64::MIN, f64::max);
    let g2 = ord.iter().map(|(_, x1, x2, y)| y * (m.w1 * x1 + m.w2 * x2 + m.b)).fold(f64::MAX, f64::min) / (m.w1 * m.w1 + m.w2 * m.w2).sqrt();
    println!("8 orders, plane only (no constant 1): farthest {:.4}  gap {:.4}", r2, g2);

    // ---- 1,000 synthetic orders, labelled by the rule 0.6 x1 + 0.8 x2 > 1.4, gap 0.25 kept clear ----
    let (mut st, mut big): (u64, Vec<Order>) = (2026, Vec::new());
    while big.len() < 1000 {
        let (s1, a) = splitmix64(st); let (s2, c) = splitmix64(s1); st = s2;
        let (x1, x2) = (-5.0 + 10.0 * a, -4.0 + 8.0 * c);
        let mm = 0.6 * x1 + 0.8 * x2 - 1.4;
        if mm.abs() >= 0.25 { big.push(("o".to_string(), x1, x2, if mm > 0.0 { 1.0 } else { -1.0 })); }
    }
    let bg = tr(&big, 1.0, 1000, false, true);
    let (rb, gb, bb) = bound(&big, (0.6, 0.8, -1.4));
    println!("1000 orders: fraud {}  updates {}  passes {}  right {}  R = {:.4}  gamma = {:.4}  bound = {:.1}",
             big.iter().filter(|o| o.3 == 1.0).count(), bg.updates, bg.per_pass.len(),
             correct(&big, bg.w1, bg.w2, bg.b), rb, gb, bb);

    // ---- XOR: card abroad? device abroad? fraud when exactly one is ----
    let xor: Vec<Order> = [("UK card, UK device", 0.0, 0.0, -1.0), ("UK card, device abroad", 0.0, 1.0, 1.0),
        ("card abroad, UK device", 1.0, 0.0, 1.0), ("card abroad, device abroad", 1.0, 1.0, -1.0)]
        .iter().map(|&(n, a, c, y)| (n.to_string(), a, c, y)).collect();
    let mut xl = Vec::new();
    let xr = train(&xor, 1.0, 1000, false, true, &mut xl);
    println!("XOR one perceptron: passes {}  updates {}  mistakes in each of the first 5 passes {:?}  weights after every pass ({:.0}, {:.0}, {:.0})",
             xr.per_pass.len(), xr.updates, &xr.per_pass[..5], xr.w1, xr.w2, xr.b);
    let xs: Vec<String> = xl[..4].iter().map(|e| format!("({:.0}, {:.0}, {:.0})", e.4, e.5, e.6)).collect();
    println!("XOR pass 1, weights after each update: {}", xs.join("  "));
    let grid: Vec<f64> = (-8..=8).map(|i| i as f64 / 2.0).collect();   // every line with w1, w2, b in -4 .. 4
    let (mut best_x, mut best_8) = (0, 0);
    for &p in &grid { for &q in &grid { for &r in &grid {
        best_x = best_x.max(correct(&xor, p, q, r)); best_8 = best_8.max(correct(&ord, p, q, r));
    }}}
    println!("brute force over {} lines: best on XOR {} of 4, best on the 8 orders {} of 8", grid.len().pow(3), best_x, best_8);

    // ---- two layers: h = step(W1 x + b1), out = step(W2 h + b2) ----
    let mut xor_ok = 0;
    for (name, x1, x2, _) in &xor {
        let (h, o) = net([*x1, *x2], step, 1.0);
        let (_, ol) = net([*x1, *x2], lam, 10.0);
        let (_, o1) = net([*x1, *x2], lam, 1.0);
        if o == (if x1 != x2 { 1.0 } else { 0.0 }) { xor_ok += 1; }
        println!("{:<27} h1 {:.0}  h2 {:.0}  out {:.0}  logistic x10 {:.4}  logistic x1 {:.4}", name, h[0], h[1], o, ol, o1);
    }
    let c1 = matvec(&[W2], &[W1[0][0], W1[1][0]])[0];
    let c2 = matvec(&[W2], &[W1[0][1], W1[1][1]])[0];
    let c0 = W2[0] * B1[0] + W2[1] * B1[1] + B2;
    let lin_right = xor.iter().filter(|(_, x1, x2, y)| (if c1 * x1 + c2 * x2 + c0 > 0.0 { 1.0 } else { -1.0 }) == *y).count();
    println!("no squashing: W2 W1 = ({:.0}, {:.0}), bias {:.1}, every score {:.1}, right {} of 4", c1, c2, c0, c0, lin_right);
    println!("shop network, 12 inputs, 8 hidden, 1 out: parameters {}", 8 * 12 + 8 + 8 + 1);

    // ---- what breaks ----
    let nb = tr(&ord, 1.0, 100, false, false);
    let sr = tr(&ord, 1.0, 1000, true, true);
    let rawu: Vec<Order> = raw.iter().map(|&(n, v, d, y)| (n.to_string(), v / 100.0, d / 100.0, y)).collect();
    let rw = tr(&rawu, 1.0, 1000, false, true);
    let (_, _, br) = bound(&rawu, (1.0, 1.0, -9.0));
    println!("wrong: no bias: mistakes in pass 100 {}, right {} of 8", nb.per_pass[nb.per_pass.len() - 1], correct(&ord, nb.w1, nb.w2, nb.b));
    println!("wrong: score 0 counted right: updates {}, w = ({:.0}, {:.0}) b = {:.0}, right {} of 8", sr.updates, sr.w1, sr.w2, sr.b, correct(&ord, sr.w1, sr.w2, sr.b));
    println!("wrong: raw units, not centred: updates {}  passes {}  bound {:.0}", rw.updates, rw.per_pass.len(), br);

    // ---- try changing ----
    let th = tr(&ord, 0.5, 1000, false, true);
    let rev: Vec<Order> = ord.iter().rev().cloned().collect();
    let rv = tr(&rev, 1.0, 1000, false, true);
    let mut more = ord.clone(); more.push(("I".to_string(), -2.0, -2.0, 1.0));
    let bad = tr(&more, 1.0, 200, false, true);
    println!("try: eta 0.5 -> updates {}, w = ({:.1}, {:.1}) b = {:.1}", th.updates, th.w1, th.w2, th.b);
    println!("try: reversed order -> updates {}, w = ({:.0}, {:.0}) b = {:.0}", rv.updates, rv.w1, rv.w2, rv.b);
    println!("try: add fraud at £200, 100 km -> mistakes in pass 200: {}", bad.per_pass[bad.per_pass.len() - 1]);
    let pts: Vec<String> = raw.iter().map(|&(n, v, d, _)| format!("{}({:.0},{:.1})", n, 50.0 + 0.28 * v, 205.0 - 0.225 * d)).collect();
    println!("figure, {} line ({:.0},{:.1})-({:.0},{:.1})", pts.join(" "), 50.0 + 0.28 * 100.0, 205.0 - 0.225 * 800.0,
             50.0 + 0.28 * 900.0, 205.0 - 0.225 * 0.0);

    assert!((m.updates, m.w1, m.w2, m.b) == (6, 2.0, 2.0, -4.0), "hand trace: 6 updates ending at w = (2, 2), b = -4");
    assert!(correct(&ord, m.w1, m.w2, m.b) == 8 && correct(&big, bg.w1, bg.w2, bg.b) == 1000, "settled lines get every order right");
    assert!((b8 - 26.0 * 24.0 / 4.0).abs() < 1e-9, "bound by hand: R^2 = 26, gamma = 2 / sqrt(24)");
    assert!((m.updates as f64) <= b8 && (bg.updates as f64) <= bb, "the stopping promise: updates never exceed (R / gamma)^2");
    assert!(best_x == 3 && best_8 == 8, "no line gets XOR fully right; some line gets the 8 orders right");
    assert!(xr.per_pass[xr.per_pass.len() - 1] == 4 && xr.per_pass.len() == 1000, "one perceptron never settles on XOR");
    assert!(xor_ok == 4 && lin_right == 2, "two layers do XOR; without squashing they collapse");
    assert!(nb.per_pass[nb.per_pass.len() - 1] > 0 && rw.updates > m.updates, "dropping the bias or the centring costs");
    println!("ALL CHECKS PASS");
}
