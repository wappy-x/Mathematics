// Online convex optimisation and regret -- the check behind the card.  std only, no crates.
// Each morning a tracker overlay commits to a mix w of three sector sleeves (w on the simplex),
// then sees the day's loss f_t(w) = -c_t.w + (mu/2)|w - z|^2, where c_t is each sleeve's return
// minus the sleeves' average and z is the index mix.  Roads: online gradient descent (two step
// rules) and exponentiated gradient, scored against the best fixed mix in hindsight, which is
// found by a projection formula and by enumerating a grid of mixes; the proved bounds; the floor
// on coin-flip days, by a recursion and by binomial sums; online-to-batch over 200 simulated years.
use std::collections::HashMap;

const T: usize = 250; const N3: usize = 3; const MU: f64 = 0.01; const G: f64 = 0.05;
const Z: [f64; 3] = [0.5, 0.3, 0.2]; // index mix
const M: [f64; 3] = [0.0006, 0.0002, -0.0004]; // mean daily return of each sleeve
type V = Vec<f64>;

fn splitmix(s: u64) -> (u64, u64) {
    let s = s.wrapping_add(0x9E3779B97F4A7C15); let mut x = s;
    x = (x ^ (x >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    x = (x ^ (x >> 27)).wrapping_mul(0x94D049BB133111EB);
    (s, x ^ (x >> 31))
}
fn dot(a: &[f64], b: &[f64]) -> f64 { a.iter().zip(b).map(|(x, y)| x * y).sum() }
fn sq(a: &[f64], b: &[f64]) -> f64 { a.iter().zip(b).map(|(x, y)| (x - y).powi(2)).sum() }
fn proj(v: &[f64]) -> V { // nearest point of the simplex: shift every entry by one amount, clip at 0
    let mut u = v.to_vec(); u.sort_by(|a, b| b.partial_cmp(a).unwrap());
    let (mut cs, mut th) = (0.0, 0.0);
    for (i, x) in u.iter().enumerate() { cs += x; if *x > (cs - 1.0) / (i as f64 + 1.0) { th = (cs - 1.0) / (i as f64 + 1.0); } }
    v.iter().map(|x| (x - th).max(0.0)).collect()
}
fn year(mut seed: u64) -> Vec<V> { // 250 days of centred returns: sleeve mean plus uniform noise of +-1.5 %
    let mut c = vec![];
    for _ in 0..T {
        let mut r = vec![];
        for i in 0..N3 { let (s, x) = splitmix(seed); seed = s; r.push(M[i] + 0.015 * (2.0 * (x >> 11) as f64 / 2f64.powi(53) - 1.0)); }
        let rb: f64 = r.iter().sum::<f64>() / N3 as f64; c.push(r.iter().map(|x| x - rb).collect());
    }
    c
}
fn f(c: &[f64], w: &[f64]) -> f64 { -dot(c, w) + MU / 2.0 * sq(w, &Z) }
fn grad(c: &[f64], w: &[f64]) -> V { (0..N3).map(|i| -c[i] + MU * (w[i] - Z[i])).collect() }
fn ogd(c: &[V], step: &dyn Fn(usize) -> f64) -> (f64, Vec<V>) { // commit, see f_t, step, project back
    let (mut w, mut l, mut ws) = (Z.to_vec(), 0.0, vec![]);
    for (t, ct) in c.iter().enumerate() {
        ws.push(w.clone()); l += f(ct, &w); let g = grad(ct, &w);
        w = proj(&(0..N3).map(|i| w[i] - step(t + 1) * g[i]).collect::<V>());
    }
    ws.push(w); (l, ws) // mixes w_1 .. w_(T+1)
}
fn best_fixed(c: &[V]) -> (V, f64, V) { // sum of f_t = (mu t/2)|w - z - S/(mu t)|^2 + const, so project
    let s: V = (0..N3).map(|i| c.iter().map(|ct| ct[i]).sum()).collect();
    let u = proj(&(0..N3).map(|i| Z[i] + s[i] / (MU * c.len() as f64)).collect::<V>());
    let b = c.iter().map(|ct| f(ct, &u)).sum(); (u, b, s)
}
fn j(v: &[f64], p: usize) -> String { v.iter().map(|x| format!("{:.*}", p, x)).collect::<Vec<_>>().join(" ") }

fn main() {
    let d = 2f64.sqrt(); let tf = T as f64;
    let c = year(2024);
    let gm = c.iter().map(|ct| dot(ct, ct).sqrt()).fold(f64::MIN, f64::max) + MU * d;
    println!("gradient bound: max |c_t| + mu sqrt(2) = {:.4} <= G = {}", gm, G);
    let (u, best, s) = best_fixed(&c);
    let n = 600; let mut grid = f64::MAX;
    for i in 0..=n { for k in 0..=(n - i) {
        let w = [i as f64 / n as f64, k as f64 / n as f64, (n - i - k) as f64 / n as f64];
        grid = grid.min(-dot(&s, &w) + MU * tf / 2.0 * sq(&w, &Z));
    } }
    println!("best fixed mix in hindsight: ({:.4}, {:.4}, {:.4}), total loss {:.6}; grid of {} mixes: {:.6}",
             u[0], u[1], u[2], best, (n + 1) * (n + 2) / 2, grid);
    assert!(best <= grid + 1e-12 && grid - best < 1e-6);
    let eta = |t: usize| d / (G * (t as f64).sqrt());
    let (h, w0) = (1e-6, [0.2, 0.3, 0.5]); let gw = grad(&c[0], &w0);
    for i in 0..N3 { // gradient against central differences
        let (mut wp, mut wm) = (w0, w0); wp[i] += h; wm[i] -= h;
        assert!(((f(&c[0], &wp) - f(&c[0], &wm)) / (2.0 * h) - gw[i]).abs() < 1e-9);
    }
    let g1 = grad(&c[0], &Z); let v: V = (0..N3).map(|i| Z[i] - eta(1) * g1[i]).collect(); let w2 = proj(&v);
    println!("day 1: c_1 = ({:+.5}, {:+.5}, {:+.5}), step {:.4}, w_1 - step g_1 = ({:.4}, {:.4}, {:.4}), w_2 = ({:.4}, {:.4}, {:.4})",
             c[0][0], c[0][1], c[0][2], eta(1), v[0], v[1], v[2], w2[0], w2[1], w2[2]);
    let (l, w) = ogd(&c, &eta);
    let mut clip = 0;
    for t in 0..T { // the one-step inequality of Step 1, every day, against the hindsight mix
        let g = grad(&c[t], &w[t]);
        if (0..N3).map(|i| w[t][i] - eta(t + 1) * g[i]).fold(f64::MAX, f64::min) < 0.0 { clip += 1; }
        let (d0, d1) = (sq(&w[t], &u), sq(&w[t + 1], &u));
        assert!((w[t + 1].iter().sum::<f64>() - 1.0).abs() < 1e-12 && w[t + 1].iter().all(|x| *x >= 0.0)); // on the simplex
        let diff: V = (0..N3).map(|i| w[t][i] - u[i]).collect();
        assert!(dot(&g, &diff) <= (d0 - d1) / (2.0 * eta(t + 1)) + eta(t + 1) * dot(&g, &g) / 2.0 + 1e-15);
    }
    let bound = 1.5 * d * G * tf.sqrt();
    println!("OGD, step D/(G sqrt t): loss {:.6}, regret {:.6} ({:.6} a day); bound 1.5 D G sqrt(T) = 1.5 x {:.4} x {} x {:.4} = {:.6} ({:.6} a day)",
             l, l - best, (l - best) / tf, d, G, tf.sqrt(), bound, bound / tf);
    let part2 = G * G / 2.0 * (1..=T).map(|t| eta(t)).sum::<f64>(); let l4 = ogd(&c, &|t| 4.0 * eta(t)).0; // G guessed 4x too small
    println!("bound parts: D^2/(2 alpha_T) = {:.6}, (G^2/2) sum alpha_t = {:.6} <= D G sqrt(T) = {:.6}; steps 4 times too long: regret {:.6}, slope part {:.6}",
             d * d / (2.0 * eta(T)), part2, d * G * tf.sqrt(), l4 - best, 4.0 * part2);
    assert!(part2 <= d * G * tf.sqrt() && d * G * tf.sqrt() < 4.0 * part2 && l4 - best > l - best);
    println!("the projection clipped a sleeve to 0 on {} of {} days; the one-step inequality held on all {}", clip, T, T);
    assert!(0.0 < l - best && l - best <= bound);
    let ts: Vec<usize> = (25..=T).step_by(25).collect();
    let reg: V = ts.iter().map(|&t| ogd(&c[..t], &eta).0 - best_fixed(&c[..t]).1).collect();
    println!("chart, days [{}]", ts.iter().map(|t| t.to_string()).collect::<Vec<_>>().join(", "));
    println!("chart, regret {}", j(&reg, 4));
    println!("chart, bound {}", j(&ts.iter().map(|&t| 1.5 * d * G * (t as f64).sqrt()).collect::<V>(), 4));
    let ls = ogd(&c, &|t| 1.0 / (MU * t as f64)).0; let bsc = G * G / (2.0 * MU) * (1.0 + tf.ln());
    println!("OGD, step 1/(mu t): regret {:.6}; bound G^2/(2 mu) (1 + ln T) = {:.6}; with mu = 0.002 it would be {:.6}", ls - best, bsc, G * G / (2.0 * 0.002) * (1.0 + tf.ln()));
    assert!(0.0 < ls - best && ls - best <= bsc && bsc < bound);
    let e = (2.0 * (N3 as f64).ln() / tf).sqrt() / G; let (mut w, mut le, mut gi) = (vec![1.0 / N3 as f64; N3], 0.0, 0.0);
    for ct in &c { // exponentiated gradient; gi: sum over days of the squared largest slope entry
        le += f(ct, &w); let g = grad(ct, &w); gi += g.iter().fold(0.0f64, |m, x| m.max(x.abs())).powi(2);
        w = (0..N3).map(|i| w[i] * (-e * g[i]).exp()).collect(); let sw: f64 = w.iter().sum(); w = w.iter().map(|a| a / sw).collect();
    }
    let beg = G * (2.0 * tf * (N3 as f64).ln()).sqrt();
    let dd = u.iter().filter(|&&x| x > 0.0).map(|x| x * (N3 as f64 * x).ln()).sum::<f64>() / e + e * gi / 2.0; // the proof's bound
    println!("exponentiated gradient, rate {:.4}: regret {:.6}; bound G sqrt(2 T ln n) = {:.6}; on this year's slopes {:.6}", e, le - best, beg, dd);
    assert!(0.0 < le - best && le - best <= dd && dd <= beg && (w.iter().sum::<f64>() - 1.0).abs() < 1e-12);
    println!("2,000 assets, each gradient entry within {}: OGD bound {:.2}, exponentiated gradient bound {:.2}",
             G, 1.5 * d * G * 2000f64.sqrt() * tf.sqrt(), G * (2.0 * tf * 2000f64.ln()).sqrt());

    // floor: two sleeves, gradient +-(a, -a) on fair coin days; every method expects loss 0
    let a = G / d; let mut pm: HashMap<i64, f64> = HashMap::new(); pm.insert(0, 1.0); let mut fl = vec![];
    for t in 1..=T {
        let mut q: HashMap<i64, f64> = HashMap::new();
        let mut keys: Vec<i64> = pm.keys().cloned().collect(); keys.sort();
        for sk in keys { let p = pm[&sk]; *q.entry(sk + 1).or_insert(0.0) += p / 2.0; *q.entry(sk - 1).or_insert(0.0) += p / 2.0; }
        pm = q;
        if t % 25 == 0 { let mut keys: Vec<i64> = pm.keys().cloned().collect(); keys.sort();
            fl.push(a * keys.iter().map(|k| (*k as f64).abs() * pm[k]).sum::<f64>()); }
    }
    let (mut p, mut ee) = (0.5f64.powi(T as i32), 0.0);
    for k in 0..=T { ee += p * (2.0 * k as f64 - tf).abs(); p = p * (tf - k as f64) / (k as f64 + 1.0); }
    println!("chart, coin-day floor {}", j(&fl, 4));
    println!("coin days: a = {:.6}, E|S_T| = {:.4}, floor a E|S_T| = {:.4}; G sqrt(T/pi) = {:.4}; bound / floor = {:.3}",
             a, ee, a * ee, G * (tf / std::f64::consts::PI).sqrt(), bound / (a * ee));
    assert!((fl[fl.len() - 1] - a * ee).abs() < 1e-12 && a * ee < bound);

    // what breaks: follow the leader, and a step that never shrinks, on alternating days
    let mut alt = vec![vec![-a / 2.0, a / 2.0]];
    for t in 1..T { alt.push(if t % 2 == 1 { vec![a, -a] } else { vec![-a, a] }); }
    let lin = |step: &dyn Fn(usize) -> f64, leader: bool| -> f64 {
        let (mut w, mut l, mut s2) = (vec![0.5, 0.5], 0.0, [0.0f64, 0.0]);
        for (t, ct) in alt.iter().enumerate() {
            if leader { w = if s2[0] == s2[1] { vec![0.5, 0.5] } else if s2[0] > s2[1] { vec![1.0, 0.0] } else { vec![0.0, 1.0] }; }
            l -= dot(ct, &w); s2 = [s2[0] + ct[0], s2[1] + ct[1]];
            w = proj(&[w[0] + step(t + 1) * ct[0], w[1] + step(t + 1) * ct[1]]);
        }
        l + s2[0].max(s2[1])
    };
    let (ftl, fix, og) = (lin(&eta, true), lin(&|_| d / G, false), lin(&eta, false));
    println!("alternating days: follow the leader regret {:.4}, fixed step {:.4} regret {:.4}, OGD regret {:.4}", ftl, d / G, fix, og);
    assert!(ftl > 8.0 && fix > 8.0 && og <= bound);

    // online-to-batch: 200 independent years; F(w) = E f(w) has the true best mix u*
    let mb = M.iter().sum::<f64>() / N3 as f64; let mc: V = M.iter().map(|x| x - mb).collect();
    let us = proj(&(0..N3).map(|i| Z[i] + mc[i] / MU).collect::<V>());
    let ff = |w: &[f64]| -dot(&mc, w) + MU / 2.0 * sq(w, &Z);
    let (mut ex, mut rg, mut last, mut fit, mut seed) = (vec![], vec![], vec![], vec![], 7u64);
    for _ in 0..200 {
        let (s1, s0) = splitmix(seed); seed = s1; let cr = year(s0); let (lr, wr) = ogd(&cr, &eta);
        let wb: V = (0..N3).map(|i| wr[..T].iter().map(|w| w[i]).sum::<f64>() / tf).collect();
        ex.push(ff(&wb) - ff(&us)); rg.push((lr - cr.iter().map(|ct| f(ct, &us)).sum::<f64>()) / tf);
        last.push(ff(&wr[T]) - ff(&us)); fit.push(ff(&best_fixed(&cr).0) - ff(&us));
    }
    let mean = |x: &V| x.iter().sum::<f64>() / x.len() as f64;
    let se = ((mean(&rg.iter().map(|x| x * x).collect()) - mean(&rg).powi(2)) / 200.0).sqrt();
    println!("true best mix u* = ({:.4}, {:.4}, {:.4}); over 200 years, excess daily loss of", us[0], us[1], us[2]);
    println!("  OGD's average mix {:.7}, its last mix {:.7}, refit on the year {:.7}", mean(&ex), mean(&last), mean(&fit));
    println!("  OGD's regret against u* per day {:.7} (standard error {:.7}); bound per day {:.6}", mean(&rg), se, bound / tf);
    assert!(mean(&ex) <= mean(&rg) + 4.0 * se && mean(&ex) < mean(&last));
    println!("ALL CHECKS PASS");
}
