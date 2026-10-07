// Representing a martingale -- the same check as the Python, in Rust.  No crates.
// A share starts at $100 and moves $10 up (heads, +1) or down (tails, -1) on each
// of 3 days; fair coin, no interest.  Any payoff V on the 8 paths is shown to be
// M_0 + sum of H_k (S_k - S_(k-1)), each stake H_k fixed the day before.  Roads:
// backward recursion, direct averages over completions, the Walsh expansion of V
// in the coin signs, and a seeded simulation (SplitMix64, written out).
use std::collections::HashMap;
type P = Vec<i32>;
type Map = HashMap<P, f64>;
const DAYS: usize = 3; const S0: f64 = 100.0; const STEP: f64 = 10.0;

struct SplitMix64 { s: u64 }
impl SplitMix64 {
    fn next(&mut self) -> u64 {
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    }
}

fn paths(moves: &[i32], n: usize) -> Vec<P> {      // every sequence of n moves, first move slowest
    let mut out: Vec<P> = vec![vec![]];
    for _ in 0..n { out = out.iter().flat_map(|w| moves.iter().map(move |&m| ext(w, m))).collect(); }
    out
}
fn name(w: &[i32]) -> String {
    if w.is_empty() { "start".to_string() } else { w.iter().map(|&e| if e > 0 { 'H' } else if e < 0 { 'T' } else { '0' }).collect() }
}
fn price(w: &[i32]) -> f64 { S0 + STEP * w.iter().sum::<i32>() as f64 }
fn sign(w: &[i32], s: &[i32]) -> i32 { w.iter().zip(s).map(|(&e, &b)| if b == 1 { e } else { 1 }).product() }
fn ext(w: &[i32], m: i32) -> P { let mut c = w.to_vec(); c.push(m); c }

fn recurse(v: &Map, moves: &[i32], p: f64) -> (Map, Map) {    // road 1: backward
    let (mut m, mut h) = (v.clone(), Map::new());
    for n in (0..DAYS).rev() {
        for w in paths(moves, n) {
            let wt = |mv: i32| if moves.len() == 2 { if mv == 1 { p } else { 1.0 - p } } else { 1.0 / moves.len() as f64 };
            let mw = moves.iter().fold(0.0, |a, &mv| a + wt(mv) * m[&ext(&w, mv)]);
            let hw = moves.iter().fold(0.0, |a, &mv| a + mv as f64 * (m[&ext(&w, mv)] - mw))
                / (STEP * moves.iter().map(|&mv| (mv * mv) as f64).sum::<f64>());
            m.insert(w.clone(), mw); h.insert(w, hw);
        }
    }
    (m, h)
}
fn direct(v: &Map, all: &[P], w: &[i32]) -> f64 {  // road 2: average V over every way to finish
    let ends: Vec<f64> = all.iter().filter(|x| x[..w.len()] == *w).map(|x| v[x]).collect();
    ends.iter().fold(0.0, |a, b| a + b) / ends.len() as f64
}
fn walsh(v: &Map, w2: &[P]) -> (f64, Map) {        // road 3: V = sum over S of c_S x product of signs
    let c: Vec<(P, f64)> = paths(&[0, 1], DAYS).into_iter()
        .map(|s| { let cs = w2.iter().fold(0.0, |a, w| a + v[w] * sign(w, &s) as f64) / w2.len() as f64; (s, cs) }).collect();
    let mut h = Map::new();
    for n in 0..DAYS {
        for w in paths(&[1, -1], n) {
            let t = c.iter().filter(|(s, _)| s[n] == 1 && s[n + 1..].iter().sum::<i32>() == 0)
                .fold(0.0, |a, (s, cs)| a + cs * sign(&w, &s[..n]) as f64);
            h.insert(w, t / STEP);
        }
    }
    (c[0].1, h)
}
fn gains(h: &Map, w: &[i32]) -> Vec<f64> { (0..DAYS).map(|k| h[&w[..k].to_vec()] * STEP * w[k] as f64 + 0.0).collect() }
fn replay(all: &[P], m0: f64, h: &Map) -> Map {
    all.iter().map(|w| (w.clone(), m0 + gains(h, w).iter().fold(0.0, |a, g| a + g))).collect()
}
fn works(v: &Map, w2: &[P]) -> (bool, bool) {
    let (m, h) = recurse(v, &[1, -1], 0.5);
    let ((m0, hw), r) = (walsh(v, w2), replay(w2, m[&vec![]], &h));
    (w2.iter().all(|w| (r[w] - v[w]).abs() < 1e-9),
     (m0 - m[&vec![]]).abs() < 1e-12 && h.iter().all(|(k, x)| (hw[k] - x).abs() < 1e-12))
}

fn main() {
    let (w2, w3) = (paths(&[1, -1], DAYS), paths(&[1, 0, -1], DAYS));
    let call: Map = w2.iter().map(|w| (w.clone(), (price(w) - 100.0).max(0.0))).collect();
    let ((m, h), (m0, hw), root) = (recurse(&call, &[1, -1], 0.5), walsh(&call, &w2), vec![]);
    let list = |v: &Map| w2.iter().map(|w| format!("{} {:.0}", name(w), v[w])).collect::<Vec<_>>().join(", ");
    println!("share ${:.0}, up or down ${:.0} a day for {} days, fair coin, {} paths", S0, STEP, DAYS, w2.len());
    println!("call, strike 100, payoff: {}", list(&call));
    println!("node: price, value M backward | direct average, stake H backward | Walsh");
    for n in 0..DAYS {
        for w in paths(&[1, -1], n) {
            let d = direct(&call, &w2, &w);
            println!("node {}: {:.0}, M {:.6} | {:.6}, H {:.6} | {:.6}", name(&w), price(&w), m[&w], d, h[&w], hw[&w]);
            assert!(m[&w] == d, "backward value vs direct average");
            assert!(h[&w] == hw[&w], "backward stake vs Walsh stake");
        }
    }
    println!("cash at the start = M - H x price = {:.6}; Walsh start value {:.6}", m[&root] - h[&root] * S0, m0);
    let r = replay(&w2, m[&root], &h);
    for w in &w2 {
        let g: Vec<String> = gains(&h, w).iter().map(|x| format!("{:+.2}", x)).collect();
        println!("replay {}: {:.2} {} = {:.2}, payoff {:.2}", name(w), m[&root], g.join(" "), r[w], call[w]);
        assert!(r[w] == call[w], "the strategy must end at the payoff on every path");
    }
    let look: Map = w2.iter().map(|w| (w.clone(), (0..=DAYS).map(|k| price(&w[..k])).fold(f64::MIN, f64::max) - 100.0)).collect();
    let ((lm, lh), (l0, lw), ht, th) = (recurse(&look, &[1, -1], 0.5), walsh(&look, &w2), vec![1, -1], vec![-1, 1]);
    println!("lookback, highest price - 100, payoff: {}", list(&look));
    println!("lookback: price {:.6} (direct {:.6}, Walsh {:.6}); stake after HT {:.6}, after TH {:.6}", lm[&root], direct(&look, &w2, &root), l0, lh[&ht], lh[&th]);
    let lr = replay(&w2, lm[&root], &lh);
    assert!(w2.iter().map(|w| (lr[w] - look[w]).abs()).fold(0.0, f64::max) < 1e-12, "lookback replicated");
    assert!(lw == lh, "lookback stakes: Walsh vs backward");
    let mut ph = lh.clone();
    let avg = (lh[&ht] + lh[&th]) / 2.0;                      // one stake per price, not per history
    ph.insert(ht.clone(), avg); ph.insert(th.clone(), avg);
    let pr = replay(&w2, lm[&root], &ph);
    let e: Vec<String> = w2.iter().map(|w| format!("{} {:+.2}", name(w), pr[w] - look[w] + 0.0)).collect();
    println!("break, lookback with one stake {:.6} at price 100 on day 2, error: {}", avg, e.join(", "));
    let mut miss: Vec<f64> = w2.iter().map(|w| ((pr[w] - look[w]).abs() * 1e9).round() / 1e9).collect();
    miss.sort_by(|x, y| x.partial_cmp(y).unwrap());
    assert!(miss == [vec![0.0; 4], vec![STEP / 4.0; 4]].concat(), "one stake per price misses 4 paths by STEP / 4");
    let mut rng = SplitMix64 { s: 20260929 };
    let zero_one: Vec<(bool, bool)> = (0..256u32).map(|i| works(&w2.iter().enumerate().map(|(j, w)| (w.clone(), ((i >> j) & 1) as f64)).collect(), &w2)).collect();
    let random: Vec<(bool, bool)> = (0..1000).map(|_| works(&w2.iter().map(|w| (w.clone(), (rng.next() % 101) as f64 - 50.0)).collect(), &w2)).collect();
    for (label, res) in [("every 0/1 payoff, 256", &zero_one), ("random payoffs -50..50, 1000", &random)] {
        println!("{}: replicated {}, Walsh agrees {}", label, res.iter().filter(|x| x.0).count(), res.iter().filter(|x| x.1).count());
        assert!(res.iter().all(|x| x.0 && x.1), "every payoff is a strategy, by both roads");
    }
    let (nsim, mut s, mut s2, mut worst) = (100000, 0.0, 0.0, 0.0f64);
    for _ in 0..nsim {
        let w: P = (0..DAYS).map(|_| if rng.next() >> 63 == 1 { 1 } else { -1 }).collect();
        s += call[&w]; s2 += call[&w] * call[&w];
        worst = worst.max((r[&w] - call[&w]).abs());
    }
    let mean = s / nsim as f64;
    let sd = (s2 / nsim as f64 - mean * mean).sqrt();
    let se = sd / (nsim as f64).sqrt();
    println!("simulated {} paths: mean payoff {:.4} +/- {:.4} (exact {:.4})", nsim, mean, se, m[&root]);
    println!("  unhedged seller sd {:.4}; hedged seller worst error {:.4}", sd, worst);
    assert!((mean - m[&root]).abs() < 4.0 * se, "simulated mean within 4 standard errors");
    let (bm, bh) = recurse(&call, &[1, -1], 0.6);
    let cnt = |w: &P, x: i32| w.iter().filter(|&&e| e == x).count() as f64;
    let enumd = w2.iter().fold(0.0, |a, w| a + 0.6f64.powf(cnt(w, 1)) * 0.4f64.powf(cnt(w, -1)) * call[w]);
    let br = replay(&w2, bm[&root], &bh);
    let bl: Vec<f64> = w2.iter().map(|w| br[w] - call[w]).collect();
    let (bmin, bmax) = (bl.iter().cloned().fold(f64::MAX, f64::min), bl.iter().cloned().fold(f64::MIN, f64::max));
    println!("break, averaging with chance 0.6 of an up day: {:.6} (enumerated {:.6})", bm[&root], enumd);
    println!("  its own stakes overshoot by {:.2} to {:.2}; the fair hedge costs {:.2}", bmin, bmax, m[&root]);
    assert!((bm[&root] - enumd).abs() < 1e-12, "recursion vs weighted enumeration at chance 0.6");
    assert!(bmin > 0.1, "averages at 0.6 are no representation against the share");
    let heads = |w: &P| cnt(w, 1);                           // drifts up 0.5 a day
    let hh: Map = (0..DAYS).flat_map(|n| paths(&[1, -1], n)).map(|w| { let d = (heads(&ext(&w, 1)) - heads(&ext(&w, -1))) / (2.0 * STEP); (w, d) }).collect();
    let hr = replay(&w2, 0.0, &hh);
    let left: Vec<f64> = w2.iter().map(|w| heads(w) - hr[w]).collect();
    let (lmin, lmax) = (left.iter().cloned().fold(f64::MAX, f64::min), left.iter().cloned().fold(f64::MIN, f64::max));
    println!("break, count of heads: left over after {} days {:.6} to {:.6} (days / 2 = {:.6})", DAYS, lmin, lmax, DAYS as f64 / 2.0);
    assert!(left.iter().all(|&x| x == DAYS as f64 / 2.0), "the unrepresented part is the drift, 0.5 a day");
    let tcall: Map = w3.iter().map(|w| (w.clone(), (price(w) - 100.0).max(0.0))).collect();
    let (tm, th3) = recurse(&tcall, &[1, 0, -1], 0.5);
    let (tr, td) = (replay(&w3, tm[&root], &th3), direct(&tcall, &w3, &root));
    let err: Vec<f64> = w3.iter().map(|w| tr[w] - tcall[w]).collect();
    let vsd = (w3.iter().fold(0.0, |a, w| a + (tcall[w] - tm[&root]) * (tcall[w] - tm[&root])) / w3.len() as f64).sqrt();
    let esd = (err.iter().fold(0.0, |a, e| a + e * e) / w3.len() as f64).sqrt();
    println!("break, three moves a day: {} paths, {} numbers to choose; price {:.6} (direct {:.6})", w3.len(), 1 + 1 + 3 + 9, tm[&root], td);
    println!("  best hedge misses on {} paths; leftover sd {:.6} against unhedged {:.6}", err.iter().filter(|e| e.abs() > 1e-9).count(), esd, vsd);
    assert!((tm[&root] - td).abs() < 1e-12, "trinomial price by two roads");
    assert!(0.5 < esd && esd < vsd, "hedging helps but cannot finish the job");
    for d in 0..=DAYS as i32 {
        let pts: Vec<String> = (0..=d).map(|j| { let k = (d - 2 * j) as f64;
            format!("({:.0}) -> ({}, {:.0})", S0 + STEP * k, 40 + 95 * d, 124.0 - 2.7 * STEP * k) }).collect();
        println!("figure, day {}, (price) -> (x, y): {}", d, pts.join(", "));
    }
    println!("ALL CHECKS PASS");
}
