// Optimal stopping as a dynamic program -- the same check as the Python, in Rust.  std only, no crates.
// One block of stored water (10 million m3) and a forward price x for it, GBP thousand, on the grid
// 60, 70, ..., 140.  Each month the price moves 10 up or 10 down, pulled toward 100; at the ends of the
// grid the blocked move becomes "stay".  Storing costs C a month.  Months k = 0 (1 June) .. N = 6
// (1 December), when the block must be sold.  Maximise the average sale price minus storage costs.
// Roads: (1) backward induction; (2) the rule run forward over every price path; (3) every stop set for
// October and November listed and scored; (4) a simulation with SplitMix64, seed 20261111.
const MONTHS: [&str; 7] = ["Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
const N: usize = 6; const C: f64 = 1.0; const PULL: f64 = 0.02; const START: usize = 2;
type Row = [f64; 9]; type Stop = Vec<[bool; 9]>;
fn x(i: usize) -> f64 { 60.0 + 10.0 * i as f64 }
fn moves(i: usize, pull: f64) -> [(usize, f64); 2] { // (next index, chance): down, up
    let (up, dn) = (0.5 - pull * (i as f64 - 4.0), 0.5 + pull * (i as f64 - 4.0));
    if i == 0 { [(0, dn), (1, up)] } else if i == 8 { [(7, dn), (8, up)] } else { [(i - 1, dn), (i + 1, up)] }
}
fn wait_value(v1: &Row, i: usize, c: f64, pull: f64) -> f64 {
    let mut s = 0.0; for (j, q) in moves(i, pull) { s += q * v1[j]; }
    s - c
}
fn solve(c: f64, pull: f64, n: usize) -> (Vec<Row>, Vec<Row>, Stop) {
    let mut v = vec![[0.0; 9]; n + 1];
    let (mut w, mut stop) = (vec![[0.0; 9]; n], vec![[false; 9]; n]);
    for i in 0..9 { v[n][i] = x(i); }                  // 1 December: sell at whatever the price is
    for k in (0..n).rev() {
        for i in 0..9 {
            w[k][i] = wait_value(&v[k + 1], i, c, pull);
            stop[k][i] = x(i) >= w[k][i];
            v[k][i] = x(i).max(w[k][i]);
        }
    }
    (v, w, stop)
}
fn run_forward(stop: &Stop, i0: usize, c: f64, n: usize) -> (f64, Vec<f64>) { // road 2
    let (mut mass, mut value, mut sold) = ([0.0f64; 9], 0.0, vec![]);
    mass[i0] = 1.0;
    for k in 0..=n {
        let (mut here, mut gain) = (0.0, 0.0);
        for i in 0..9 {
            if k == n || stop[k][i] { here += mass[i]; gain += mass[i] * (x(i) - c * k as f64); }
        }
        value += gain; sold.push(here);
        let mut nxt = [0.0; 9];
        for i in 0..9 {
            if k < n && !stop[k][i] { for (j, q) in moves(i, PULL) { nxt[j] += q * mass[i]; } }
        }
        mass = nxt;
    }
    (value, sold)
}
fn splitmix(s: u64) -> (u64, u64) {
    let s = s.wrapping_add(0x9E3779B97F4A7C15);
    let mut z = (s ^ (s >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    (s, (z ^ (z >> 31)) >> 11)
}
fn prophet(k: usize, i: usize, best: f64) -> f64 { // sees the whole price path, then picks the best month
    let g = best.max(x(i) - C * k as f64);
    if k == N { return g; }
    let mut s = 0.0; for (j, q) in moves(i, PULL) { s += q * prophet(k + 1, j, g); }
    s
}
fn join(v: &[f64], p: usize, w: usize) -> String {
    v.iter().map(|a| format!("{:w$.p$}", a, w = w, p = p)).collect::<Vec<_>>().join(" ")
}
fn bars(stop: &Stop) -> Vec<usize> {
    stop.iter().map(|s| (0..9).filter(|&i| s[i]).map(|i| 60 + 10 * i).min().unwrap()).collect()
}
fn main() {
    let (v, w, stop) = solve(C, PULL, N);
    let bar = bars(&stop);
    println!("price x            {}", (0..9).map(|i| format!("{:7}", 60 + 10 * i)).collect::<Vec<_>>().join(" "));
    println!("chance of a rise   {}", join(&(0..9).map(|i| moves(i, PULL)[1].1).collect::<Vec<_>>(), 2, 7));
    println!("month  bar | value V_k(x), GBP k");
    for k in 0..N {
        assert!((0..9).all(|i| stop[k][i] == (60 + 10 * i >= bar[k])));   // the stop set is one threshold
        println!("{}  {:5} | {}", MONTHS[k], bar[k], join(&v[k], 2, 7));
    }
    println!("Dec   sell | {}", join(&v[N], 2, 7));
    println!("Nov wait values  {}", join(&w[5], 2, 6));
    println!("Jun wait values  {}", join(&w[0], 2, 6));
    println!("Jun gap W_0(x)-x {}", join(&(0..9).map(|i| w[0][i] - x(i)).collect::<Vec<_>>(), 2, 6));
    for i in [2usize, 3, 4] { println!("wait value at x={}, Jun..Nov  {}", 60 + 10 * i, join(&(0..N).map(|k| w[k][i]).collect::<Vec<_>>(), 2, 6)); }
    assert!((w[5][2] - (0.46 * 70.0 + 0.54 * 90.0 - 1.0)).abs() < 1e-9 && (w[5][3] - (0.48 * 80.0 + 0.52 * 100.0 - 1.0)).abs() < 1e-9);
    let best = v[0][START];
    let (fwd, sold) = run_forward(&stop, START, C, N);
    println!("road 1, backward induction, V_0(80)       {:8.3}", best);
    println!("road 2, rule run forward over the prices  {:8.3}", fwd);
    assert!((best - fwd).abs() < 1e-9);
    println!("chance of selling in {}", (0..=N).map(|k| format!("{} {:.3}", MONTHS[k], sold[k])).collect::<Vec<_>>().join(" "));
    let mut held = 0.0; for k in 0..=N { held += k as f64 * sold[k]; }
    println!("average months held {:.3}, average sale price {:.3}", held, best + C * held);
    let mut top = [-1e9f64; 9];                         // road 3: every stop set for Oct and Nov
    for a in 0..512usize {
        for b in 0..512usize {
            let mut v5 = [0.0; 9];
            for i in 0..9 { v5[i] = if b >> i & 1 == 1 { x(i) } else { wait_value(&v[N], i, C, PULL) }; }
            for i in 0..9 {
                let v4 = if a >> i & 1 == 1 { x(i) } else { wait_value(&v5, i, C, PULL) };
                if v4 > top[i] { top[i] = v4; }
            }
        }
    }
    println!("road 3, best of 262144 Oct-Nov rules: {}", top.iter().map(|t| format!("{:.2}", t)).collect::<Vec<_>>().join(" "));
    assert!((0..9).all(|i| (top[i] - v[4][i]).abs() < 1e-9));
    let (mut seed, mut total, mut total2, r) = (20261111u64, 0.0f64, 0.0f64, 200000usize);
    for _ in 0..r {                                     // road 4: simulate sellers who follow the rule
        let (mut i, mut k) = (START, 0usize);
        while k < N && !stop[k][i] {
            let (s, bits) = splitmix(seed); seed = s;
            let m = moves(i, PULL);
            i = if (bits as f64) / 2f64.powi(53) < m[1].1 { m[1].0 } else { m[0].0 };
            k += 1;
        }
        let g = x(i) - C * k as f64;
        total += g; total2 += g * g;
    }
    let mean = total / r as f64;
    let se = ((total2 / r as f64 - mean * mean) / (r as f64 - 1.0)).sqrt();
    println!("road 4, {} simulated sellers   {:8.3}  (standard error {:.3})", r, mean, se);
    assert!((mean - best).abs() < 4.0 * se);
    let story = [80usize, 70, 80, 90, 80, 90];
    let mut k = 0;
    while k < N && story[k] < bar[k] { k += 1; }
    println!("story: prices {}; sold in {} at {}, net {:.0}",
             story.iter().map(|s| s.to_string()).collect::<Vec<_>>().join(" "), MONTHS[k], story[k], story[k] as f64 - C * k as f64);
    println!("rule's sale in Aug at 80? {} | in Oct at 80? {}", if stop[2][2] { "True" } else { "False" }, if stop[4][2] { "True" } else { "False" });
    let never: Stop = vec![[false; 9]; N];
    let hold = run_forward(&never, START, C, N).0;
    let mut myopic: Stop = vec![[false; 9]; N];
    let xs: Row = std::array::from_fn(|i| x(i));
    for k in 0..N { for i in 0..9 { myopic[k][i] = x(i) >= wait_value(&xs, i, C, PULL); } }
    let (mut fixed, mut fixed_t) = (-1e9, 0usize);
    for t in 0..9 {
        let rule: Stop = vec![std::array::from_fn(|i| i >= t); N];
        let f = run_forward(&rule, START, C, N).0;
        if f > fixed { fixed = f; fixed_t = 60 + 10 * t; }
    }
    let mut pi = [1.0f64; 9];                           // the long-run spread of prices, from balance up = down
    for i in 0..8 { pi[i + 1] = pi[i] * moves(i, PULL)[1].1 / moves(i + 1, PULL)[0].1; }
    let mut z = 0.0; for p in pi { z += p; }
    for p in pi.iter_mut() { *p /= z; }
    let mut vi = vec![];                                // wrong model: each month a fresh price from that spread
    let mut s = 0.0; for i in 0..9 { s += pi[i] * x(i); }
    vi.push(s - C);
    for _ in 0..N - 1 {
        let (last, mut s) = (vi[vi.len() - 1], 0.0); for i in 0..9 { s += pi[i] * x(i).max(last); }
        vi.push(s - C);
    }
    let mut indep: Stop = vec![[false; 9]; N];
    for k in 0..N { for i in 0..9 { indep[k][i] = x(i) >= vi[N - 1 - k]; } }
    let rows = [("wrong: sell on 1 June".to_string(), x(START)),
                ("wrong: hold to 1 December".to_string(), hold),
                ("wrong: look one month ahead only".to_string(), run_forward(&myopic, START, C, N).0),
                (format!("wrong: best fixed bar ({})", fixed_t), fixed),
                ("wrong: fresh price each month, delivered".to_string(), run_forward(&indep, START, C, N).0),
                ("wrong: prophet who sees the whole path".to_string(), prophet(0, START, -1e9))];
    for (name, val) in rows.iter() { println!("{:<42}{:8.3}", name, val); }
    assert!(rows[..5].iter().all(|(_, val)| *val < best - 0.02) && rows[5].1 > best + 0.5);
    let rev: Vec<f64> = vi.iter().rev().cloned().collect();
    println!("fresh-price model's bars {}", rev.iter().map(|t| format!("{:.2}", t)).collect::<Vec<_>>().join(" "));
    for (name, c, pull, n) in [("try: no storage cost", 0.0, PULL, N), ("try: no pull to 100", C, 0.0, N),
                               ("try: a 12-month season", C, PULL, 12), ("try: cost 3 a month", 3.0, PULL, N)] {
        let (vt, _, st) = solve(c, pull, n);
        println!("{:<24}V_0(80) {:7.3}  bars {}", name, vt[0][START],
                 bars(&st).iter().map(|b| b.to_string()).collect::<Vec<_>>().join(" "));
    }
    println!("chart, V_0(x) and V_5(x): {} | {}", v[0].iter().map(|t| format!("{:.2}", t)).collect::<Vec<_>>().join(" "),
             v[5].iter().map(|t| format!("{:.2}", t)).collect::<Vec<_>>().join(" "));
    println!("ALL CHECKS PASS");
}
