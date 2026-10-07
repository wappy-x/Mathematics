// The fundamental theorems of asset pricing -- the same check as the Python, in
// Rust.  Standard library only, no crates, and nothing borrowed that already
// knows an answer: the bell curve, the integrator, the root finder, the trees
// and the one-period markets are written out here.  House market: Acme at
// S = 100, K = 100, r = 5%, dividend yield q = 2%, sigma = 20%, T = 1 year, and
// a real-world price drift m = 8%.  Compile: rustc --edition 2021 -O
use std::f64::consts::PI;

const S: f64 = 100.0; const K: f64 = 100.0; const R: f64 = 0.05;
const QD: f64 = 0.02; const SIG: f64 = 0.20; const T: f64 = 1.0; const M: f64 = 0.08;
const LO: f64 = 80.0; const MID: f64 = 100.0; const HI: f64 = 125.0;
const CLAIM: [f64; 3] = [0.0, 10.0, 0.0];        // pays 10 only if Acme ends at 100
const ENDS: [f64; 3] = [LO, MID, HI];            // the small market's three ends

fn disc() -> f64 { (-R * T).exp() }              // the discount factor e^-rT
fn fwd() -> f64 { S * ((R - QD) * T).exp() }     // the forward price
fn bell(z: f64) -> f64 { (-0.5 * z * z).exp() / (2.0 * PI).sqrt() }   // bell curve
fn biggest(v: &[f64]) -> f64 { v.iter().fold(f64::NEG_INFINITY, |a, &b| a.max(b)) }
fn smallest(v: &[f64]) -> f64 { v.iter().fold(f64::INFINITY, |a, &b| a.min(b)) }

fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;                  // area under f, by thin slices
    let mut s = f(a) + f(b);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    s * h / 3.0
}

fn ratio(th: f64, z: f64) -> f64 { (-th * T.sqrt() * z - 0.5 * th * th * T).exp() }   // dQ/dP

fn average<F: Fn(f64) -> f64>(drift: f64, pay: F, th: Option<f64>, vol: f64, n: usize) -> f64 {
    simpson(|z| {                                // payoff x weight x bell curve
        let price = S * ((drift - 0.5 * vol * vol) * T + vol * T.sqrt() * z).exp();
        pay(price) * (match th { None => 1.0, Some(t) => ratio(t, z) }) * bell(z)
    }, -10.0, 10.0, n)
}

fn bisect<F: Fn(f64) -> f64>(f: F, mut lo: f64, mut hi: f64, steps: usize) -> f64 {
    let mut flo = f(lo);                         // the root, by halving the bracket
    for _ in 0..steps {
        let mid = 0.5 * (lo + hi);
        if flo * f(mid) <= 0.0 { hi = mid } else { lo = mid; flo = f(mid) }
    }
    0.5 * (lo + hi)
}

fn tree_pricing(n: usize, drift: f64) -> f64 {   // road 3: backward, pricing chances
    let dt = T / n as f64; let u = (SIG * dt.sqrt()).exp(); let d = 1.0 / u;
    let p = ((drift * dt).exp() - d) / (u - d); let dis = (-R * dt).exp();
    let mut v: Vec<f64> = (0..=n)
        .map(|j| (S * u.powi(j as i32) * d.powi((n - j) as i32) - K).max(0.0)).collect();
    for s in (1..=n).rev() { v = (0..s).map(|j| dis * (p * v[j + 1] + (1.0 - p) * v[j])).collect(); }
    v[0]
}

fn tree_reweighted(n: usize, real: f64, pricing: f64) -> f64 {
    let dt = T / n as f64;                       // road 4: real paths, reweighted
    let u = (SIG * dt.sqrt()).exp(); let d = 1.0 / u;
    let p = ((real * dt).exp() - d) / (u - d);       // the real-world up chance
    let pq = ((pricing * dt).exp() - d) / (u - d);   // the pricing up chance
    let mut logc = n as f64 * (1.0 - p).ln();    // log chance of n downs, under P
    let mut total = 0.0;
    for j in 0..=n {                             // step the path count along, then reweight
        if j > 0 { logc += (((n - j + 1) as f64) / j as f64 * p / (1.0 - p)).ln(); }
        let loglr = j as f64 * (pq / p).ln() + (n - j) as f64 * ((1.0 - pq) / (1.0 - p)).ln();
        total += (logc + loglr).exp() * (S * u.powi(j as i32) * d.powi((n - j) as i32) - K).max(0.0);
    }
    (-R * T).exp() * total
}

fn weights(p2: f64) -> [f64; 3] {                // three-state weights, middle p2
    let p3 = (fwd() - LO - (MID - LO) * p2) / (HI - LO);
    [1.0 - p2 - p3, p2, p3]
}

fn worth(w: &[f64; 3], c: &[f64; 3]) -> f64 {    // a claim's price under weights w
    disc() * (0..3).map(|j| w[j] * c[j]).sum::<f64>()
}

fn cost(a: f64, b: f64) -> f64 { a * S * (-QD * T).exp() + b * disc() }   // a, b at T

fn edge(claim: &[f64; 3], sg: f64) -> f64 {      // +1: cheapest copy above the
    let mut best: Option<f64> = None;            // claim; -1: dearest copy below it
    for i in -400..=400 {                        // search the share holding directly
        let a = i as f64 / 100.0;
        let b = biggest(&(0..3).map(|j| sg * (claim[j] - a * ENDS[j])).collect::<Vec<f64>>());
        let v = sg * cost(a, sg * b);
        if best.is_none() || v < best.unwrap() { best = Some(v) }
    }
    sg * best.unwrap()
}

fn row(name: &str, vals: &[f64]) {
    let mut line = format!("{:<40}", name);
    for v in vals { line.push_str(&format!("{:>14.6}", v)); }
    println!("{}", line);
}

fn pct(drift: f64, c: f64) -> f64 {              // chance of landing in a $10 band
    let z = |x: f64| ((x / S).ln() - (drift - 0.5 * SIG * SIG) * T) / (SIG * T.sqrt());
    100.0 * simpson(bell, z(c - 5.0), z(c + 5.0), 400)
}

fn main() {
    let call = |x: f64| (x - K).max(0.0); let spot = |x: f64| x;
    let theta = (M + QD - R) / SIG;              // the price of risk
    let shift = bisect(|th| average(M, spot, Some(th), SIG, 2000) - fwd(), 0.0, 1.0, 80);
    let c_q = disc() * average(R - QD, call, None, SIG, 20000);
    let c_p = disc() * average(M, call, Some(theta), SIG, 20000);
    let tree_q = tree_pricing(2000, R - QD); let tree_p = tree_reweighted(2000, M, R - QD);
    let wrong_real = disc() * average(M, call, None, SIG, 20000);
    let wrong_disc = (-(M + QD) * T).exp() * average(R - QD, call, None, SIG, 20000);
    let wrong_noq = disc() * average(R, call, None, SIG, 20000);
    let vol15 = disc() * average(R - QD, call, None, 0.15, 20000);
    let vol25 = disc() * average(R - QD, call, None, 0.25, 20000);
    let pi_up = (fwd() - LO) / (HI - LO);        // two states, 80 or 125: unique
    let tick_w = disc() * 10.0 * pi_up; let a2 = 10.0 / (HI - LO);
    let tick_c = cost(a2, -a2 * LO);             // the same claim, built from shares
    let p2max = (HI - fwd()) / (HI - MID);       // three states: the family's edge
    let band: Vec<f64> = [0.2, 0.5, 0.8, p2max].iter().map(|&p| worth(&weights(p), &CLAIM)).collect();
    let (hi_edge, lo_edge) = (edge(&CLAIM, 1.0), edge(&CLAIM, -1.0));
    let zero = weights(0.0);                     // the middle state weighted nothing
    let shares: Vec<f64> = [0.2, 0.5, 0.8].iter().map(|&p| worth(&weights(p), &ENDS)).collect();
    row("real-world price drift m", &[M]); row("pricing drift r - q", &[R - QD]);
    row("price of risk theta = (m + q - r)/sigma", &[theta]);
    row("  theta again, by solving for the shift", &[shift]); row("forward F = S e^(r-q)T", &[fwd()]);
    row("E^P[S_T], the real drift", &[average(M, spot, None, SIG, 20000)]);
    row("E^Q[S_T], the pricing drift", &[average(R - QD, spot, None, SIG, 20000)]);
    row("  E^P[S_T x dQ/dP], reweighted", &[average(M, spot, Some(theta), SIG, 20000)]);
    row("dQ/dP at z = +1 and z = -1", &[ratio(theta, 1.0), ratio(theta, -1.0)]);
    row("1 call by Q-average", &[c_q]); row("2 call by P-average x dQ/dP", &[c_p]);
    row("3 call by tree, 2000 steps, Q-chances", &[tree_q]);
    row("4 call by tree, P-paths reweighted", &[tree_p]);
    row("wrong: real odds, bank discount", &[wrong_real]);
    row("wrong: Q-average discounted at m + q", &[wrong_disc]);
    row("wrong: pricing drift r, dividend gone", &[wrong_noq]);
    row("call if sigma were 0.15 or 0.25", &[vol15, vol25]); println!();
    row("two states 80/125: weights", &[1.0 - pi_up, pi_up]);
    row("  claim pays 10 at 125: weights, copy", &[tick_w, tick_c]);
    row("  that copy: shares at T, cash at T", &[a2, -a2 * LO]); println!();
    row("three states: weights at middle 0.20", &weights(0.2));
    row("  at middle 0.50", &weights(0.5)); row("  at middle 0.80", &weights(0.8));
    row("  at the family's edge", &weights(p2max));
    row("nudge (5,-9,4) on the share and the claim", &[(0..3).map(|j| [5.0, -9.0, 4.0][j] * ENDS[j]).sum::<f64>(), (0..3).map(|j| [5.0, -9.0, 4.0][j] * CLAIM[j]).sum::<f64>()]);
    row("claim (0,10,0) at middle 0.20/0.50/0.80", &band[..3]);
    row("  at the edge, and cheapest copy above", &[band[3], hi_edge]); row("  dearest copy below: hold nothing", &[lo_edge]);
    row("one share at T, under those three", &shares);
    row("zero on the middle state: weights", &zero);
    row("  that claim's price, and its payout", &[worth(&zero, &CLAIM), biggest(&CLAIM)]); println!();
    let mids: Vec<f64> = (0..8).map(|i| 70.0 + 10.0 * i as f64).collect();
    let mut bars = format!("{:<34}", "bars, claim price ($)");
    for v in &band { bars.push_str(&format!("{:>8.2}", v)); } println!("{}", bars);
    let mut head = format!("{:<34}", "chart, band centre ($)");
    for c in &mids { head.push_str(&format!("{:>8.0}", c)); }
    println!("{}", head);
    for (lab, dr) in [("chart, chance under P (%)", M), ("chart, chance under Q (%)", R - QD)] {
        let mut line = format!("{:<34}", lab);
        for c in &mids { line.push_str(&format!("{:>8.2}", pct(dr, *c))); }
        println!("{}", line);
    }
    assert!((c_q - 9.227005508154).abs() < 1e-9, "Q-average vs the shelf's call price");
    assert!((c_p - c_q).abs() < 1e-7, "reweighted real-world average, same price");
    assert!((shift - theta).abs() < 1e-6, "the solved drift shift is the price of risk");
    assert!((tree_q - c_q).abs() < 0.005 && (tree_p - tree_q).abs() < 1e-8, "both trees");
    assert!((tick_w - tick_c).abs() < 1e-9, "unique weights: average equals the copy");
    assert!((hi_edge - band[3]).abs() < 1e-9 && lo_edge.abs() < 1e-12, "the two edges");
    assert!(wrong_real > c_q && c_q > wrong_disc, "real odds dear, over-discounting cheap");
    assert!(smallest(&zero) == 0.0 && smallest(&weights(0.2)) > 0.0, "the edge is no measure");
    assert!([0.05, 0.2, 0.5, 0.8, 0.87].iter().all(|&p| smallest(&weights(p)) > 0.0 && (worth(&weights(p), &ENDS) - S * (-QD * T).exp()).abs() < 1e-12), "every family member reprices the share");
    println!("ALL CHECKS PASS");
}
