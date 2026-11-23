// Regret -- the same check as the Python, in Rust.  No crates.  Four routes to
// work, twenty mornings, delays in minutes.  The weighted-majority rule
// (randomised form: pick a route with chance in proportion to its weight,
// shrink each weight by e^(-eta x loss)) is run and its regret is compared with
// the bound ln N / eta + eta T / 8 and with rules that fail.
const ROUTES: [&str; 4] = ["bus", "train", "bike", "car"];
const CAP: f64 = 20.0; // a loss is delay / 20 minutes
const DELAY: [[u32; 20]; 4] = [
    [6, 8, 5, 9, 7, 6, 10, 5, 8, 7, 6, 9, 5, 7, 8, 6, 7, 9, 6, 8],
    [1, 2, 0, 1, 2, 18, 20, 16, 19, 17, 2, 1, 0, 2, 1, 1, 2, 0, 1, 2],
    [4, 4, 5, 4, 12, 4, 5, 4, 4, 13, 4, 5, 4, 4, 14, 4, 5, 4, 4, 4],
    [9, 11, 8, 12, 10, 9, 13, 10, 11, 9, 10, 12, 8, 9, 11, 10, 9, 12, 10, 11]];
const N: usize = 4;
const T: usize = 20;

fn splitmix(state: &mut u64) -> f64 { // SplitMix64: a uniform in [0, 1)
    *state = state.wrapping_add(0x9E3779B97F4A7C15);
    let mut z = *state;
    z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
}

fn first_min(v: &[f64]) -> usize { let mut j = 0; for i in 0..v.len() { if v[i] < v[j] { j = i } } j }
fn first_max(v: &[f64]) -> usize { let mut j = 0; for i in 0..v.len() { if v[i] > v[j] { j = i } } j }
fn dot(a: &[f64], b: &[f64]) -> f64 { a.iter().zip(b).map(|(x, y)| x * y).sum() }

// road one: each weight read off the running total, w_i = e^(-eta L_i);
// leader = true follows the route with the smallest total (eta -> infinity)
fn play(eta: f64, rounds: usize, n: usize, nature: &dyn Fn(usize, &[f64]) -> Vec<f64>, leader: bool)
        -> (Vec<Vec<f64>>, f64, Vec<f64>, Vec<f64>) {
    let (mut tot, mut alg, mut probs, mut regret) = (vec![0.0; n], 0.0, Vec::new(), Vec::new());
    for t in 0..rounds {
        let p: Vec<f64> = if leader {
            let j = first_min(&tot);
            (0..n).map(|i| if i == j { 1.0 } else { 0.0 }).collect()
        } else {
            let low = tot.iter().cloned().fold(f64::INFINITY, f64::min);
            let w: Vec<f64> = tot.iter().map(|x| (-eta * (x - low)).exp()).collect();
            let s: f64 = w.iter().sum();
            w.iter().map(|x| x / s).collect()
        };
        let loss = nature(t, &p);
        alg += dot(&p, &loss);
        for i in 0..n { tot[i] += loss[i] }
        probs.push(p);
        regret.push(alg - tot.iter().cloned().fold(f64::INFINITY, f64::min));
    }
    (probs, alg, tot, regret)
}

fn commute(t: usize, _p: &[f64]) -> Vec<f64> { (0..N).map(|i| DELAY[i][t] as f64 / CAP).collect() }
fn alternating(t: usize, _p: &[f64]) -> Vec<f64> { // two routes: half a loss, then 1 and 0 in turn
    if t == 0 { vec![0.5, 0.0] } else if t % 2 == 1 { vec![0.0, 1.0] } else { vec![1.0, 0.0] }
}
fn spiteful(_t: usize, p: &[f64]) -> Vec<f64> { // the hold-up lands on the likeliest route
    let j = first_max(p);
    (0..p.len()).map(|i| if i == j { 1.0 } else { 0.0 }).collect()
}

fn iterate(eta: f64) -> (f64, Vec<f64>) { // road two: multiply each weight in, morning by morning
    let (mut w, mut alg) = (vec![1.0; N], 0.0);
    for t in 0..T {
        let s: f64 = w.iter().sum();
        alg += (0..N).map(|i| w[i] * DELAY[i][t] as f64 / CAP).sum::<f64>() / s;
        for i in 0..N { w[i] *= (-eta * DELAY[i][t] as f64 / CAP).exp() }
    }
    (alg, w)
}

fn bound(eta: f64, t: usize, n: usize) -> f64 { (n as f64).ln() / eta + eta * t as f64 / 8.0 }
fn join(v: &[f64]) -> String { v.iter().map(|x| format!("{:.4}", x)).collect::<Vec<_>>().join(" ") }

fn main() {
    let ln_n = (N as f64).ln();
    let eta = (8.0 * ln_n / T as f64).sqrt();
    let (probs, alg, tot, regret) = play(eta, T, N, &commute, false);
    let (alg2, w_end) = iterate(eta);
    let best = first_min(&tot);
    let totals: Vec<String> = (0..N).map(|i| format!("{} {}", ROUTES[i], DELAY[i].iter().sum::<u32>())).collect();
    println!("route totals, minutes: {}", totals.join(", "));
    println!("best single route in hindsight: {}, {:.0} minutes", ROUTES[best], tot[best] * CAP);
    println!("train's bad week, mornings 6 to 10: {} minutes; train, morning 6: loss {:.4}",
             DELAY[1][5..10].iter().sum::<u32>(), DELAY[1][5] as f64 / CAP);
    println!("L* = {:.4} losses, rule {:.4} losses, ln {} = {:.4}", tot[best], alg, N, ln_n);
    println!("eta = sqrt(8 ln {} / {}) = {:.4}", N, T, eta);
    for t in [0usize, 1, 19] {
        let d: f64 = (0..N).map(|i| probs[t][i] * DELAY[i][t] as f64).sum();
        println!("morning {}: chances {}, expected delay {:.4} min", t + 1, join(&probs[t]), d);
    }
    let w1: Vec<f64> = (0..N).map(|i| (-eta * DELAY[i][0] as f64 / CAP).exp()).collect();
    println!("weights after morning 1: {}, sum {:.4}", join(&w1), w1.iter().sum::<f64>());
    println!("weighted majority, expected total: {:.2} minutes (road two, multiplied in: {:.2})", alg * CAP, alg2 * CAP);
    println!("regret R_T = {:.2} - {:.0} = {:.2} minutes", alg * CAP, tot[best] * CAP, regret[T - 1] * CAP);
    let b = bound(eta, T, N);
    println!("bound ln {}/eta + eta T/8 = {:.4} losses = {:.2} minutes", N, b, b * CAP);
    println!("bound per morning: {:.2} minutes; regret per morning {:.2}", b * CAP / T as f64, regret[T - 1] * CAP / T as f64);
    let phi = (w_end.iter().sum::<f64>() / N as f64).ln();
    let (floor, ceil) = (-eta * tot[best] - ln_n, -eta * alg + eta * eta * T as f64 / 8.0);
    println!("potential ln(W/N) = {:.4}, floor -eta L* - ln N = {:.4}, ceiling -eta rule + eta^2 T/8 = {:.4}", phi, floor, ceil);
    let (mut state, runs, mut sums, mut squares) = (2026u64, 10000, 0.0f64, 0.0f64);
    for _ in 0..runs { // road three: really toss the coin, 10,000 months
        let mut month = 0.0;
        for t in 0..T {
            let u = splitmix(&mut state);
            let (mut i, mut acc) = (0, probs[t][0]);
            while u >= acc && i < N - 1 { i += 1; acc += probs[t][i] }
            month += DELAY[i][t] as f64;
        }
        sums += month;
        squares += month * month;
    }
    let mean = sums / runs as f64;
    let sd = (squares / runs as f64 - mean * mean).sqrt();
    let se = sd / (runs as f64).sqrt();
    println!("simulated months: {}, mean total {:.2} minutes, one month's spread {:.2}, standard error {:.2}", runs, mean, sd, se);
    let daily_best: u32 = (0..T).map(|t| (0..N).map(|i| DELAY[i][t]).min().unwrap()).sum();
    println!("mistake, best route each morning instead: {} minutes, gap {:.2}", daily_best, alg * CAP - daily_best as f64);
    println!("eta = 0.01 on the month: regret {:.2} minutes", play(0.01, T, N, &commute, false).3[T - 1] * CAP);
    println!("eta = 20 on alternating mornings: regret {:.4}", play(20.0, T, 2, &alternating, false).3[T - 1]);
    let (_, fa, ft, fr) = play(0.0, T, 2, &alternating, true);
    let eta2 = (8.0 * 2f64.ln() / T as f64).sqrt();
    let hr = play(eta2, T, 2, &alternating, false).3[T - 1];
    println!("alternating mornings: leader loses {:.1}, best route {:.1}, regret {:.1} = {:.0} minutes; weighted majority regret {:.4}",
             fa, ft[first_min(&ft)], fr[T - 1], fr[T - 1] * CAP, hr);
    let sr = play(0.0, T, N, &spiteful, true).3;
    let hs = play(eta, T, N, &spiteful, false).3[T - 1];
    let lose = T as f64 * (1.0 - 1.0 / N as f64);
    println!("spiteful mornings: leader regret {:.1} of {} = {:.0} minutes (T(1 - 1/N) = {:.1}); weighted majority regret {:.4}",
             sr[T - 1], T, sr[T - 1] * CAP, lose, hs);
    let t2 = 240;
    let eta3 = (8.0 * ln_n / t2 as f64).sqrt();
    let (lr, hr2) = (play(0.0, t2, N, &spiteful, true).3, play(eta3, t2, N, &spiteful, false).3);
    for t in (30..=t2).step_by(30) {
        println!("chart, t = {}: leader {:.1}, weighted majority {:.2}, bound {:.2}", t, lr[t - 1], hr2[t - 1], bound(eta3, t, N));
    }
    let mut row: Vec<f64> = vec![1.0]; // Pascal's triangle, row 20
    for _ in 0..T {
        let mut next = vec![1.0];
        for k in 0..row.len() - 1 { next.push(row[k] + row[k + 1]) }
        next.push(1.0);
        row = next;
    }
    let two_t = 2f64.powi(T as i32);
    let floor_sum: f64 = row.iter().enumerate().map(|(k, c)| c * (k as f64 - T as f64 / 2.0).abs()).sum::<f64>() / two_t;
    let mut choose = 1.0; // C(20, 10) as a running product
    for k in 0..T / 2 { choose = choose * (T - k) as f64 / (k + 1) as f64 }
    let floor_closed = T as f64 / 2.0 * choose / two_t;
    let b2 = (T as f64 * 2f64.ln() / 2.0).sqrt();
    println!("fair-coin mornings, two routes: every rule's expected regret {:.4} (closed form {:.4}, about sqrt(T/2pi) = {:.4}); bound {:.4}",
             floor_sum, floor_closed, (T as f64 / (2.0 * std::f64::consts::PI)).sqrt(), b2);
    println!("in minutes: floor {:.2}, bound {:.2}", floor_sum * CAP, b2 * CAP);
    assert!((alg - alg2).abs() < 1e-9); // two roads to the weights
    assert!((mean - alg * CAP).abs() < 4.0 * se); // the coin, really tossed
    assert!(regret.iter().enumerate().all(|(t, r)| *r <= bound(eta, t + 1, N))); // the theorem, every prefix
    assert!(play(eta2, T, 2, &alternating, false).3.iter().enumerate().all(|(t, r)| *r <= bound(eta2, t + 1, 2))); // and on the hostile runs
    assert!(hr2.iter().enumerate().all(|(t, r)| *r <= bound(eta3, t + 1, N)));
    assert!(floor <= phi && phi <= ceil);
    assert!((fr[T - 1] - T as f64 / 2.0).abs() < 1e-9 && (sr[T - 1] - lose).abs() < 1e-9);
    assert!((floor_sum - floor_closed).abs() < 1e-12 && floor_sum <= b2);
    println!("ALL CHECKS PASS");
}
