// Known cash dividends -- the same check as the Python, in Rust, std only.  No
// crates, and nothing that already knows the answer: the bell-curve area is built
// from thin slices under the curve, every average is Simpson's rule written out,
// every tree is a loop.  Acme trades at 100.00 and pays one cash dividend of 2.00
// six months from now; the option is a one-year 100-strike European call.
// Compile: rustc --edition 2021 -O known_cash_dividends_check.rs -o /tmp/kcd
use std::f64::consts::PI;
const S: f64 = 100.0;
const K: f64 = 100.0;
const R: f64 = 0.05;
const SIG: f64 = 0.20;
const T: f64 = 1.0;
const D1: f64 = 2.0;
const TD: f64 = 0.5;
const STEPS: usize = 2000;

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }   // bell-curve height
fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 {   // thin slices under f
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    s * h / 3.0
}
fn ncdf(x: f64) -> f64 {                             // bell-curve area to the left of x
    if x < -12.0 || x > 12.0 { return if x < 0.0 { 0.0 } else { 1.0 }; }
    0.5 + simpson(phi, 0.0, x, 2000)
}
fn parts(steps: usize) -> (f64, f64, f64, f64) {     // a step up, a step down, the odds
    let (u, dt) = ((SIG * (T / steps as f64).sqrt()).exp(), T / steps as f64);
    (dt, u, 1.0 / u, ((R * dt).exp() - 1.0 / u) / (u - 1.0 / u))
}
fn weights(n: usize, p: f64) -> Vec<f64> {           // binomial weights, no factorials
    let mut w = vec![(1.0 - p).powf(n as f64)];
    for j in 0..n { w.push(w[j] * p / (1.0 - p) * (n - j) as f64 / (j + 1) as f64); }
    w
}
fn grid(name: &str, cells: Vec<String>) { println!("{:<30}{}", name, cells.concat()); }

fn bs(s0: f64, k: f64, q: f64, t: f64, call: bool) -> f64 {      // ROAD 1: the formula
    let vt = SIG * t.sqrt();
    let d1 = ((s0 / k).ln() + (R - q + 0.5 * SIG * SIG) * t) / vt;
    if call { s0 * (-q * t).exp() * ncdf(d1) - k * (-R * t).exp() * ncdf(d1 - vt) }
    else { k * (-R * t).exp() * ncdf(vt - d1) - s0 * (-q * t).exp() * ncdf(-d1) }
}
fn by_average(s0: f64, k: f64, t: f64, call: bool) -> f64 {      // ROAD 2: average the payoff
    let (vt, mu) = (SIG * t.sqrt(), (R - 0.5 * SIG * SIG) * t);
    let zk = ((k / s0).ln() - mu) / vt;              // the z where the payoff switches on
    let grow = |z: f64| s0 * (mu + vt * z).exp();
    if call { (-R * t).exp() * simpson(|z| (grow(z) - k) * phi(z), zk, 10.0, 2000) }
    else { (-R * t).exp() * simpson(|z| (k - grow(z)) * phi(z), -10.0, zk, 2000) }
}
fn escrow_tree(s0: f64, steps: usize) -> f64 {       // ROAD 3: recombining tree on s0
    let (dt, u, d, p) = parts(steps);
    let disc = (-R * dt).exp();
    let mut v: Vec<f64> = (0..=steps)
        .map(|j| (s0 * u.powi(j as i32) * d.powi((steps - j) as i32) - K).max(0.0)).collect();
    for layer in (1..=steps).rev() {
        v = (0..layer).map(|j| disc * (p * v[j + 1] + (1.0 - p) * v[j])).collect();
    }
    v[0]
}
fn drop_tree(steps: usize) -> (f64, usize) {         // ROAD 4: cash off every node at TD
    let m = (steps as f64 * TD / T).round() as usize; let n2 = steps - m;
    let (_, u, d, p) = parts(steps);
    let (w1, w2) = (weights(m, p), weights(n2, p));
    let grow: Vec<f64> = (0..=n2).map(|j| u.powi(j as i32) * d.powi((n2 - j) as i32)).collect();
    let mut total = 0.0;
    for j1 in 0..=m {
        let s1 = S * u.powi(j1 as i32) * d.powi((m - j1) as i32) - D1;   // cash leaves here
        let mut inner = 0.0;
        for j2 in 0..=n2 { inner += w2[j2] * (s1 * grow[j2] - K).max(0.0); }
        total += w1[j1] * inner;
    }
    ((-R * T).exp() * total, (m + 1) * (n2 + 1))
}
fn drop_average() -> f64 {                           // ROAD 5: same model, nested averages
    let (vt, mu) = (SIG * (T - TD).sqrt(), (R - 0.5 * SIG * SIG) * (T - TD));
    let inner = |z1: f64| {
        let s1 = S * ((R - 0.5 * SIG * SIG) * TD + SIG * TD.sqrt() * z1).exp() - D1;
        let zk = if s1 > 0.0 { (((K / s1).ln() - mu) / vt).min(10.0) } else { 10.0 };
        simpson(|z2| (s1 * (mu + vt * z2).exp() - K) * phi(z2), zk, 10.0, 400)
    };
    (-R * T).exp() * simpson(|z1| inner(z1) * phi(z1), -10.0, 10.0, 200)
}
fn twins(s0: f64, drop: f64, steps: usize) -> (f64, f64, usize) {   // paths that ought to meet
    let m = (steps as f64 * TD / T).round() as usize; let j = m / 2;
    let (_, u, d, _) = parts(steps);
    ((s0 * u.powi(j as i32) * d.powi((m - j) as i32) - drop) * u,
     (s0 * u.powi(j as i32 + 1) * d.powi((m - j - 1) as i32) - drop) * d, j)
}

fn main() {
    let pvd = D1 * (-R * TD).exp();
    let sx = S - pvd;
    let vt = SIG * T.sqrt();
    let d1 = ((sx / K).ln() + (R + 0.5 * SIG * SIG) * T) / vt;
    let (c_form, p_form) = (bs(sx, K, 0.0, T, true), bs(sx, K, 0.0, T, false));
    let (c_avg, p_avg) = (by_average(sx, K, T, true), by_average(sx, K, T, false));
    let (c_tree, c_drop_avg) = (escrow_tree(sx, STEPS), drop_average());
    let (c_drop_tree, nodes_drop) = drop_tree(STEPS);
    let q_eq = -(sx / S).ln() / T;
    let (c_yield, p_yield) = (bs(S, K, 0.02, T, true), bs(S, K, 0.02, T, false));
    let (up_d, down_d, node) = twins(S, D1, STEPS);
    let (up_e, down_e, _) = twins(sx, 0.0, STEPS);
    println!("Acme S = {:.2}, K = {:.2}, r = 5%, sigma = 20%, T = 1 year\none cash dividend D1 = {:.2} paid at t1 = {:.2} years", S, K, D1, TD);
    let row = |name: &str, v: f64| println!("{:<44}{:>14.6}", name, v);
    row("PV of the dividend   D1 e^-r t1", pvd); row("escrowed spot        S* = S - D0", sx);
    row("d1 on the escrowed spot", d1); row("d2 on the escrowed spot", d1 - vt);
    row("1 escrowed formula, call", c_form); row("2 payoff average on S*, call", c_avg);
    row(&format!("3 escrowed tree, {} steps, call", STEPS), c_tree);
    row("4 escrowed formula, put", p_form); row("5 payoff average on S*, put", p_avg);
    row("  parity  C - P", c_form - p_avg);
    row("  parity  S* - K e^-rT", sx - K * (-R * T).exp());
    row("6 cash-drop model, exploded tree, call", c_drop_tree);
    row("7 cash-drop model, nested averages, call", c_drop_avg);
    row("  cash-drop minus escrowed, call", c_drop_avg - c_form);
    row("equivalent yield, -ln(S*/S)/T, percent", 100.0 * q_eq);
    row("  the yield formula at that q, call", bs(S, K, q_eq, T, true));
    row("house yield q = 2%, call", c_yield); row("house yield q = 2%, put", p_yield);
    row("forward with the cash dividend, S* e^rT", sx * (R * T).exp());
    row("  the same forward from the carry ledger", S * (R * T).exp() - D1 * (R * (T - TD)).exp());
    row("forward with the house yield, S e^(r-q)T", S * ((R - 0.02) * T).exp());
    row("wrong: dividend not discounted, call", bs(S - D1, K, 0.0, T, true));
    row("wrong: escrowed and q = 2% as well, call", bs(sx, K, 0.02, T, true));
    row("wrong: a 2.00 dividend at 18m escrowed",
        bs(sx - D1 * (-R * 1.5).exp(), K, 0.0, T, true));
    row(&format!("dividend layer, up from node {}", node), up_d);
    row(&format!("dividend layer, down from node {}", node + 1), down_d);
    row("  the would-be twins differ by", down_d - up_d);
    row("escrowed layer, the same twins differ by", (down_e - up_e).abs());
    println!("{:<44}{:>14}\n{:<44}{:>14}", "escrowed tree, nodes in the last layer", STEPS + 1, "exploded tree, nodes in the last layer", nodes_drop);
    println!();
    println!("across the ex-dividend date, six months to expiry");
    for (label, quoted, ahead) in [("day before, 2.00 due at once", S, D1),
                                   ("day after, nothing left", S - D1, 0.0),
                                   ("a share that never pays", S, 0.0)] {
        println!("  {:<30} Acme {:6.2}  escrowed {:6.2}  call {:5.2}",
                 label, quoted, quoted - ahead, bs(quoted - ahead, K, 0.0, 0.5, true));
    }
    println!();
    println!("bars: one dividend paid at six months, escrowed call");
    for size in [0.0_f64, 2.0, 5.0, 10.0, 20.0] {
        println!("  dividend {:5.2}   call {:5.2}", size,
                 bs(S - size * (-R * TD).exp(), K, 0.0, T, true));
    }
    println!();
    let share: Vec<f64> = (0..13).map(|m| S * (R * m as f64 / 12.0).exp()
        - if m <= 6 { 0.0 } else { D1 * (R * (m as f64 / 12.0 - TD)).exp() }).collect();
    let strikes: Vec<f64> = (0..9).map(|i| 80.0 + 5.0 * i as f64).collect();
    grid("chart, month", (0..13).map(|m| format!("{:>7}", m)).collect());
    grid("chart, Acme with the dividend", share.iter().map(|v| format!("{:>7.2}", v)).collect());
    grid("chart, the escrowed part",
         (0..13).map(|m| format!("{:>7.2}", sx * (R * m as f64 / 12.0).exp())).collect());
    grid("chart, strike", strikes.iter().map(|k| format!("{:>7.0}", k)).collect());
    grid("chart, no dividend",
         strikes.iter().map(|k| format!("{:>7.2}", bs(S, *k, 0.0, T, true))).collect());
    grid("chart, 2.00 cash dividend",
         strikes.iter().map(|k| format!("{:>7.2}", bs(sx, *k, 0.0, T, true))).collect());
    assert!(((S * (R * T).exp() - D1 * (R * (T - TD)).exp()) - sx * (R * T).exp()).abs() < 1e-9, "carry ledger against the escrowed spot");
    assert!((c_form - c_avg).abs() < 1e-7, "formula against the payoff average, escrowed model");
    assert!((p_form - p_avg).abs() < 1e-7, "put formula against the put's own payoff average");
    assert!((c_form - c_tree).abs() < 0.005, "formula against the recombining tree");
    assert!(((c_form - p_avg) - (sx - K * (-R * T).exp())).abs() < 1e-6, "parity, put from the average");
    assert!((c_drop_avg - c_drop_tree).abs() < 0.005, "two roads to the cash-drop model");
    assert!((c_yield - 9.227005508154).abs() < 1e-9, "the shelf's yield call, from this machinery");
    assert!(c_drop_avg > c_form, "escrowing must price under the cash-drop model");
    assert!((down_d - up_d).abs() > 1e-3, "paying cash at a node must break the meeting");
    assert!((down_e - up_e).abs() < 1e-6, "with no cash paid, the same two paths must meet");
    println!("ALL CHECKS PASS");
}
