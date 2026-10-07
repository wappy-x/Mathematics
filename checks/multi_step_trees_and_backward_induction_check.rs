// Multi-step binomial tree, priced by backward induction -- the same check as
// multi_step_trees_and_backward_induction_check.py, in Rust.  std only, no
// crates.  Acme: S = 100, K = 100, r = 5%, q = 2%, sigma = 20%, one year cut
// into four quarterly steps.  Five roads to one price: the backward roll with
// the risk-neutral weight; the same roll done by solving for shares and cash,
// with no weight anywhere; a sum over the five end prices with path counts; a
// sum over all sixteen histories; and the hedge carried forward down every one.
const S: f64 = 100.0; const K: f64 = 100.0; const R: f64 = 0.05; const Q: f64 = 0.02;
const SIGMA: f64 = 0.20; const T: f64 = 1.0; const N: usize = 4;
const BS: f64 = 9.227005508154; // the same option, priced by the formula card

fn dt() -> f64 { T / N as f64 }
fn up() -> f64 { (SIGMA * dt().sqrt()).exp() }      // up factor for one step
fn dn() -> f64 { 1.0 / up() }                       // down factor, its reciprocal
fn disc() -> f64 { (-R * dt()).exp() }              // one step of discounting
fn grow() -> f64 { (Q * dt()).exp() }               // dividends reinvested over one step
fn weight() -> f64 { (((R - Q) * dt()).exp() - dn()) / (up() - dn()) }
fn call(x: f64) -> f64 { (x - K).max(0.0) }
fn spot(step: usize, ups: usize) -> f64 { S * up().powf(ups as f64) * dn().powf((step - ups) as f64) }
fn roll<F: Fn(f64) -> f64>(w: f64, pay: F) -> Vec<Vec<f64>> {   // road 1: roll a payoff back
    let mut layers: Vec<Vec<f64>> = vec![(0..=N).map(|k| pay(spot(N, k))).collect()];
    for j in (0..N).rev() {
        let nxt = layers[0].clone();
        layers.insert(0, (0..=j).map(|k| disc() * (w * nxt[k + 1] + (1.0 - w) * nxt[k])).collect());
    }
    layers
}

fn replicate() -> (Vec<Vec<f64>>, Vec<Vec<f64>>, Vec<Vec<f64>>) {   // road 2: shares and cash
    let mut layers: Vec<Vec<f64>> = vec![(0..=N).map(|k| call(spot(N, k))).collect()];
    let (mut shares, mut banks): (Vec<Vec<f64>>, Vec<Vec<f64>>) = (Vec::new(), Vec::new());
    for j in (0..N).rev() {
        let nxt = layers[0].clone();
        let (mut sh, mut ba, mut vals) = (Vec::new(), Vec::new(), Vec::new());
        for k in 0..=j {
            let s0 = spot(j, k);
            let delta = (nxt[k + 1] - nxt[k]) / (grow() * s0 * (up() - dn()));
            let bank = disc() * (up() * nxt[k] - dn() * nxt[k + 1]) / (up() - dn());
            sh.push(delta); ba.push(bank); vals.push(delta * s0 + bank);
        }
        shares.insert(0, sh); banks.insert(0, ba); layers.insert(0, vals);
    }
    (layers, shares, banks)
}

fn choose(n: usize, k: usize) -> i64 {              // path counts, built here
    let mut out: i64 = 1;
    for i in 0..k { out = out * (n - i) as i64 / (i + 1) as i64 }
    out
}
fn tree_price(steps: usize, strike: f64, vol: f64) -> f64 {   // the same machine, other settings
    let h = T / steps as f64;
    let (uu, ds) = ((vol * h.sqrt()).exp(), (-R * h).exp());
    let dd = 1.0 / uu;
    let ww = (((R - Q) * h).exp() - dd) / (uu - dd);
    let mut row: Vec<f64> = (0..=steps)
        .map(|k| (S * uu.powf(k as f64) * dd.powf((steps - k) as f64) - strike).max(0.0))
        .collect();
    for j in (0..steps).rev() {
        row = (0..=j).map(|k| ds * (ww * row[k + 1] + (1.0 - ww) * row[k])).collect();
    }
    row[0]
}

fn first_up(j: usize, k: usize, paths: &[Vec<usize>]) -> f64 {   // $10 if the first quarter was up
    let vals: Vec<f64> = paths.iter().filter(|pp| pp[..j].iter().sum::<usize>() == k)
        .map(|pp| disc().powf((N - j) as f64) * if pp[0] == 1 { 10.0 } else { 0.0 }).collect();
    vals.iter().sum::<f64>() / vals.len() as f64
}

fn show(rows: &[(&str, f64)]) { for (name, v) in rows { println!("{:<45}{:12.6}", name, v) } }
fn join(v: &[f64], w: usize, p: usize) -> String {
    v.iter().map(|x| format!("{:>w$.p$}", x, w = w, p = p)).collect::<Vec<_>>().join(" ")
}
fn main() {
    let paths: Vec<Vec<usize>> = (0..(1usize << N))
        .map(|m| (0..N).map(|i| (m >> i) & 1).collect()).collect();
    let p = weight();
    let lat = roll(p, call);
    let (rep, shares, banks) = replicate();
    let (v_roll, v_rep) = (lat[0][0], rep[0][0]);
    let v_nodes = disc().powf(N as f64) * (0..=N).map(|k| choose(N, k) as f64
        * p.powf(k as f64) * (1.0 - p).powf((N - k) as f64) * call(spot(N, k))).sum::<f64>();
    let (mut v_hist, mut mass) = (0.0, 0.0);
    for path in &paths {                            // road 4: walk each history from today
        let (mut price, mut w) = (S, 1.0);
        for mv in path {
            if *mv == 1 { price *= up(); w *= p } else { price *= dn(); w *= 1.0 - p }
        }
        v_hist += w * call(price); mass += w;
    }
    v_hist *= disc().powf(N as f64);
    let mut worst: f64 = 0.0;                       // road 5: carry the hedge forward
    for path in &paths {
        let (mut k, mut wealth) = (0usize, v_rep);
        for (j, mv) in path.iter().enumerate() {
            let delta = shares[j][k];
            let bank = wealth - delta * spot(j, k);
            k += mv;
            wealth = delta * grow() * spot(j + 1, k) + bank / disc();
        }
        worst = worst.max((wealth - call(spot(N, k))).abs());
    }
    let v_share = roll(p, |x| x)[0][0];
    let v_put = roll(p, |x| (K - x).max(0.0))[0][0];
    let share_now = S * (-Q * T).exp();
    let parity = S * (-Q * T).exp() - K * (-R * T).exp();
    let v_fair = roll(0.5, call)[0][0];                                     // a fair coin instead
    let v_noq = roll(((R * dt()).exp() - dn()) / (up() - dn()), call)[0][0]; // dividend left out
    let v_flat = disc().powf(N as f64)
        * (0..=N).map(|k| call(spot(N, k))).sum::<f64>() / (N + 1) as f64;
    let (node_ud, node_du, node_mix) = (disc().powf((N - 2) as f64) * 10.0, 0.0, first_up(2, 1, &paths));
    let hedge_mix = (first_up(3, 2, &paths) - first_up(3, 1, &paths))
        / (grow() * spot(2, 1) * (up() - dn()));

    println!("Acme {:.2}, strike {:.2}, r {:.0}%, q {:.0}%, sigma {:.0}%, {} steps in {:.0} year",
             S, K, R * 100.0, Q * 100.0, SIGMA * 100.0, N, T);
    println!("step {:.6} yr   up {:.6}   down {:.6}   weight p {:.6}   step discount {:.6}",
             dt(), up(), dn(), p, disc());
    println!();
    println!("node table: step, ups, Acme, option value, hedge in shares, cash in the bank");
    for j in 0..N {
        for k in 0..=j {
            println!("  step {} ups {}   Acme {:7.2}   option {:6.2}   hedge {:7.4}   cash {:8.2}",
                     j, k, spot(j, k), lat[j][k], shares[j][k], banks[j][k]);
        }
    }
    let ends: Vec<f64> = (0..=N).map(|k| spot(N, k)).collect();
    println!("  step 4 Acme   {}", join(&ends, 8, 2));
    println!("  step 4 payoff {}", join(&ends.iter().map(|x| call(*x)).collect::<Vec<f64>>(), 8, 2));
    println!();
    show(&[("road 1  backward roll with the weight p", v_roll), ("road 2  backward replication, no weight", v_rep),
           ("road 3  five end prices with path counts", v_nodes), ("road 4  sixteen histories, one at a time", v_hist),
           ("road 5  hedge carried forward, worst miss", worst), ("        path weights add to", mass)]);
    println!("        path counts across the end prices  {:?}",
             (0..=N).map(|k| choose(N, k)).collect::<Vec<i64>>());
    show(&[("        the share itself rolled back", v_share), ("        S e^-qT", share_now),
           ("        the put on the same tree", v_put), ("        call minus put", v_roll - v_put),
           ("        S e^-qT - K e^-rT", parity), ("        one step across the same year", tree_price(1, K, SIGMA)),
           ("        the same roll at 500 steps", tree_price(500, K, SIGMA)),
           ("        Black-Scholes reference, same option", BS)]);
    println!();
    show(&[("wrong: a fair coin, p = 0.5", v_fair), ("wrong: dividend left out of the weight", v_noq),
           ("wrong: five end prices weighted equally", v_flat)]);
    println!("merge test, $10 if the first quarter was up: after up-down {:.4}, after down-up {:.4}, merged {:.4}",
             node_ud, node_du, node_mix);
    println!("merge test, merged hedge {:.4} shares where both histories need 0.0000", hedge_mix);
    println!();
    println!("chart, step                     0       1       2       3       4");
    let upw: Vec<f64> = vec![lat[0][0], lat[1][1], lat[2][2], lat[3][2], 0.0];
    let dnw: Vec<f64> = vec![lat[0][0], lat[1][0], lat[2][0], lat[3][1], 0.0];
    println!("chart, up-up-down-down     {}", join(&upw, 7, 2));
    println!("chart, down-down-up-up     {}", join(&dnw, 7, 2));
    println!("bars,  hedge up history    {}", join(&[shares[0][0], shares[1][1], shares[2][2], shares[3][3]], 7, 4));
    println!("bars,  hedge down history  {}", join(&[shares[0][0], shares[1][0], shares[2][0], shares[3][0]], 7, 4));
    println!();
    show(&[("try: eight steps instead of four", tree_price(8, K, SIGMA)), ("try: strike 120", tree_price(N, 120.0, SIGMA)),
           ("try: sigma 40%", tree_price(N, K, 0.40))]);

    assert!((v_roll - v_rep).abs() < 1e-12, "the weighted roll and the replication roll must agree");
    assert!((v_nodes - v_roll).abs() < 1e-12, "path counts over end prices must match the roll");
    assert!((v_hist - v_roll).abs() < 1e-12, "sixteen histories must match the roll");
    assert!(worst < 1e-9, "the hedge must land on the payoff down every history");
    assert!((mass - 1.0f64).abs() < 1e-12, "the path weights are a probability");
    assert!((v_share - share_now).abs() < 1e-12, "the share rolled back must be worth S e^-qT today");
    assert!(((v_roll - v_put) - parity).abs() < 1e-12, "call minus put on the tree must be the forward");
    assert!((tree_price(N, K, SIGMA) - v_roll).abs() < 1e-12, "the machine rebuilt from scratch must give the same four-step price");
    assert!((tree_price(500, K, SIGMA) - BS).abs() < 0.01, "500 steps must land within a cent of the Black-Scholes price");
    println!("ALL CHECKS PASS");
}
