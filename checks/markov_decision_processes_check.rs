// Markov decision processes: states, actions, rewards and a transition rule -- the check behind the card.
// A reservoir in 20 levels, three releases, random rain. Roads: Bellman sweeps; exact policy value by
// elimination, with a certificate; every policy of a 6-level reservoir listed; a seeded simulation.
const RAIN: [f64; 5] = [0.1, 0.2, 0.4, 0.2, 0.1]; // chance of 0, 1, 2, 3, 4 bands of inflow in a month
const PAY: [f64; 4] = [0.0, 40.0, 75.0, 90.0]; // revenue, thousand pounds, for 0..3 bands actually released
const PENALTY: f64 = 100.0; const LOW: usize = 2; const G: f64 = 0.95; // penalty if the month ends at level 2 or below
const RUNS: usize = 4000; const S0: usize = 10; // road 4: runs simulated, each from level 10

struct Mdp { n: usize, p: Vec<Vec<Vec<f64>>>, r: Vec<Vec<f64>> } // p[s][a-1][s'], r[s][a-1]

fn model(n: usize, rain: &[f64]) -> Mdp {
    let (mut p, mut r) = (vec![], vec![]);
    for s in 0..n {
        let (mut prow, mut rrow) = (vec![], vec![]);
        for a in 1..=3usize {
            let (mut row, mut rew) = (vec![0.0; n], 0.0);
            for (w, &q) in rain.iter().enumerate() {
                if q == 0.0 { continue; }
                let out = a.min(s + w); // cannot release water that is not there
                let t = (n - 1).min(s + w - out); // anything above the top level spills
                row[t] += q;
                rew += q * (PAY[out] - if t <= LOW { PENALTY } else { 0.0 });
            }
            prow.push(row); rrow.push(rew);
        }
        p.push(prow); r.push(rrow);
    }
    Mdp { n, p, r }
}

fn dot(x: &[f64], v: &[f64]) -> f64 { x.iter().zip(v).fold(0.0, |acc, (a, b)| acc + a * b) }
fn bracket(m: &Mdp, v: &[f64], s: usize, a: usize, g: f64) -> f64 { m.r[s][a - 1] + g * dot(&m.p[s][a - 1], v) }
fn argmax(m: &Mdp, v: &[f64], s: usize, g: f64) -> usize { // the first best action
    (2..=3).fold(1, |best, a| if bracket(m, v, s, a, g) > bracket(m, v, s, best, g) { a } else { best })
}

fn sweeps(m: &Mdp, g: f64, tol: f64, kmax: usize) -> (Vec<f64>, usize) {
    let (mut v, mut k) = (vec![0.0; m.n], 0);
    while k < kmax {
        let w: Vec<f64> = (0..m.n).map(|s| (1..=3).map(|a| bracket(m, &v, s, a, g)).fold(f64::NEG_INFINITY, f64::max)).collect();
        let change = v.iter().zip(&w).map(|(x, y)| (x - y).abs()).fold(0.0, f64::max);
        k += 1; v = w;
        if change < tol { break; }
    }
    (v, k)
}

fn evaluate(m: &Mdp, pol: &[usize], g: f64) -> Vec<f64> { // (I - g P_pi) V = r_pi by elimination
    let n = m.n;
    let mut a: Vec<Vec<f64>> = (0..n).map(|i| {
        let mut row: Vec<f64> = (0..n).map(|j| (if i == j { 1.0 } else { 0.0 }) - g * m.p[i][pol[i] - 1][j]).collect();
        row.push(m.r[i][pol[i] - 1]); row
    }).collect();
    for c in 0..n {
        let mut piv = c;
        for i in c..n { if a[i][c].abs() > a[piv][c].abs() { piv = i; } } a.swap(c, piv);
        for i in c + 1..n {
            let f = a[i][c] / a[c][c];
            for j in c..=n { let x = a[c][j]; a[i][j] -= f * x; }
        }
    }
    let mut v = vec![0.0; n];
    for i in (0..n).rev() {
        let s = (i + 1..n).fold(0.0, |acc, j| acc + a[i][j] * v[j]);
        v[i] = (a[i][n] - s) / a[i][i];
    }
    v
}

fn show(v: &[f64]) -> String { v.iter().map(|x| format!("{:.2}", x)).collect::<Vec<_>>().join(" ") }
fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }
fn code(p: &[usize]) -> String { p.iter().map(|a| a.to_string()).collect() }
fn commas(x: u128) -> String { if x < 1000 { x.to_string() } else { format!("{},{:03}", commas(x / 1000), x % 1000) } }
fn maxdiff(x: &[f64], y: &[f64]) -> f64 { x.iter().zip(y).map(|(a, b)| (a - b).abs()).fold(0.0, f64::max) }

fn splitmix(state: &mut u64) -> u64 { // SplitMix64
    *state = state.wrapping_add(0x9E3779B97F4A7C15);
    let z = (*state ^ (*state >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    let z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    z ^ (z >> 31)
}

const RAINMAP: [usize; 10] = [0, 1, 1, 2, 2, 2, 2, 3, 3, 4]; // a digit 0-9 gives rain with chances 0.1 0.2 0.4 0.2 0.1
fn simulate(pol: &[usize], g: f64, months: usize, seed: u64) -> (f64, f64) { // mean and standard error from S0
    let (n, mut state, mut totals) = (pol.len(), seed, vec![]);
    for _ in 0..RUNS {
        let (mut s, mut disc, mut tot) = (S0, 1.0f64, 0.0f64);
        for _ in 0..months {
            let w = RAINMAP[(splitmix(&mut state) % 10) as usize];
            let out = pol[s].min(s + w); let t = (n - 1).min(s + w - out);
            tot += disc * (PAY[out] - if t <= LOW { PENALTY } else { 0.0 });
            disc *= g; s = t;
        }
        totals.push(tot);
    }
    let mean = totals.iter().fold(0.0, |a, x| a + x) / RUNS as f64;
    let ss = totals.iter().fold(0.0, |a, x| a + (x - mean).powi(2));
    (mean, (ss / (RUNS - 1) as f64 / RUNS as f64).powf(0.5))
}

fn main() {
    let (n, s0) = (20usize, S0);
    let m = model(n, &RAIN);
    let nonzero = m.p.iter().flatten().flatten().filter(|&&x| x > 0.0).count();
    assert!(m.p.iter().flatten().all(|row| (row.iter().sum::<f64>() - 1.0).abs() < 1e-12));
    println!("model: {} levels x 3 releases, table {} entries, {} not zero, rows sum to 1; {} policies", n, n * 3 * n, nonzero, commas(3u128.pow(n as u32)));
    println!("rain 0-4 bands, chances {}; r(2,a) for low, medium, high: {}", show(&RAIN), show(&m.r[2]));
    assert!((m.r[2][2] - (0.1 * -25.0 + 0.2 * -10.0 + 0.4 * -10.0 + 0.2 * -10.0 + 0.1 * 90.0)).abs() < 1e-12);
    let (v, k) = sweeps(&m, G, 1e-6, 10000);
    let pol: Vec<usize> = (0..n).map(|s| argmax(&m, &v, s, G)).collect();
    println!("road 1: {} sweeps from V = 0 until no level changes by 1e-6", k);
    println!("V* levels 0-9:   {}", show(&v[..10]));
    println!("V* levels 10-19: {}", show(&v[10..]));
    println!("best release (1 low, 2 medium, 3 high) by level 0-19: {}", code(&pol));
    let vp = evaluate(&m, &pol, G);
    let mut gain = f64::NEG_INFINITY;
    for s in 0..n { for a in 1..=3 { gain = gain.max(bracket(&m, &vp, s, a, G) - vp[s]); } }
    println!("road 2: exact value of that policy differs from road 1 by under 1e-4: {}", yn(maxdiff(&v, &vp) < 1e-4));
    println!("certificate: no switch of one action gains over 1e-9 anywhere: {}", yn(gain < 1e-9));
    assert!(maxdiff(&v, &vp) < 1e-4 && gain < 1e-9);
    let nxt: Vec<f64> = (1..=3).map(|a| dot(&m.p[s0][a - 1], &vp)).collect();
    let br: Vec<f64> = (1..=3).map(|a| bracket(&m, &vp, s0, a, G)).collect();
    println!("level {}: V*(7..13) = {}", s0, show(&vp[7..14]));
    println!("level {}: r = {}; average next V* = {}", s0, show(&m.r[s0]), show(&nxt));
    println!("level {}: brackets = {}", s0, show(&br));
    assert!((nxt[2] - (0.1 * vp[7] + 0.2 * vp[8] + 0.4 * vp[9] + 0.2 * vp[10] + 0.1 * vp[11])).abs() < 1e-9);
    let (n6, m6) = (6, model(6, &RAIN)); // road 3: a 6-level reservoir, every one of 3^6 policies valued exactly
    let pols6: Vec<Vec<usize>> = (0..729usize).map(|c| (0..n6).map(|i| c / 3usize.pow(i as u32) % 3 + 1).collect()).collect();
    let vals6: Vec<Vec<f64>> = pols6.iter().map(|pl| evaluate(&m6, pl, G)).collect();
    let mut i6 = 0; // the first policy with the largest total
    for i in 1..729 { if vals6[i].iter().fold(0.0, |a, x| a + x) > vals6[i6].iter().fold(0.0, |a, x| a + x) { i6 = i; } }
    let dominates = vals6.iter().all(|w| (0..n6).all(|s| vals6[i6][s] >= w[s] - 1e-9));
    let (v6, _) = sweeps(&m6, G, 1e-10, 10000);
    let pol6: Vec<usize> = (0..n6).map(|s| argmax(&m6, &v6, s, G)).collect();
    println!("road 3: 6 levels, {} policies listed; best {} beats or ties all at every level: {}; Bellman picks {}",
        pols6.len(), code(&pols6[i6]), yn(dominates), code(&pol6));
    assert!(dominates && pols6[i6] == pol6 && maxdiff(&vals6[i6], &v6) < 1e-8);
    let (months, seed) = (300usize, 2026u64); // road 4: simulate the policy with SplitMix64
    let (mean, se) = simulate(&pol, G, months, seed);
    println!("road 4: {} runs of {} months from level {}: mean {:.2}, standard error {:.2}", RUNS, months, s0, mean, se);
    assert!((mean - vp[s0]).abs() < 4.0 * se);
    // what breaks
    let myo: Vec<usize> = (0..n).map(|s| { let mut b = 1; for a in 2..=3 { if m.r[s][a - 1] > m.r[s][b - 1] { b = a; } } b }).collect();
    let mc = model(n, &[0.0, 0.0, 1.0, 0.0, 0.0]);
    let (vc_plan, _) = sweeps(&mc, G, 1e-10, 10000);
    let cert: Vec<usize> = (0..n).map(|s| argmax(&mc, &vc_plan, s, G)).collect();
    let (vm, vc) = (evaluate(&m, &myo, G)[s0], evaluate(&m, &cert, G)[s0]);
    println!("breaks: this month's reward only {}: {:.2}", code(&myo), vm);
    println!("breaks: rain always 2 bands {}: promises {:.2}, delivers {:.2}", code(&cert), vc_plan[s0], vc);
    let g1: Vec<f64> = [100, 200, 400].iter().map(|&k| sweeps(&m, 1.0, 0.0, k).0[s0]).collect();
    println!("breaks: gamma = 1, V(10) after 100, 200, 400 sweeps: {}; rise per sweep {:.2}", show(&g1), (g1[2] - g1[1]) / 200.0);
    assert!(vm < vp[s0] && vc < vp[s0] && vp[s0] < vc_plan[s0] && g1[2] - g1[1] > 0.9 * (g1[1] - g1[0]));
    // counting: d linked reservoirs on one river, each with 20 levels and 3 releases
    println!("reservoirs  states  actions  sweep cost  policy digits");
    for d in [1u32, 2, 3, 10] {
        let (st, ac) = (20u128.pow(d), 3u128.pow(d));
        let digits = ((d as u128 * st) as f64 * 0.47712125471966244) as u128 + 1; // digits of 3^(d * 20^d)
        println!("{} {} {} {} {}", d, commas(st), commas(ac), commas(st * ac * st), commas(digits));
    }
    // the Try-changing box: other discount factors, one year of months, another seed
    for g in [0.8f64, 0.99] {
        let (vg, kg) = sweeps(&m, g, 1e-6, 100000);
        let pg: Vec<usize> = (0..n).map(|s| argmax(&m, &vg, s, g)).collect();
        let (mg, sg) = simulate(&pg, g, months, seed);
        println!("try: gamma {}: {} sweeps, best release {}, V*(10) {:.2}, simulated {:.2} (se {:.2})", g, kg, code(&pg), vg[s0], mg, sg);
    }
    let ((m12, s12), (m7, s7)) = (simulate(&pol, G, 12, seed), simulate(&pol, G, months, 7));
    println!("try: 12 months: simulated mean {:.2} (se {:.2}); seed 7: mean {:.2} (se {:.2})", m12, s12, m7, s7);
    println!("ALL CHECKS PASS");
}
