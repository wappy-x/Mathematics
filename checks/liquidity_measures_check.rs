//! Liquidity of three stocks: effective spread, Amihud illiquidity, depth, resilience.

struct Rng { x: u64 }                          // splitmix64, the same generator as the Python
impl Rng {
    fn u(&mut self) -> f64 {                   // uniform on [0, 1)
        self.x = self.x.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.x;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
}
const NAMES: [&str; 3] = ["Acme", "Beacon", "Cobble"];
const MID: [i64; 3] = [10000, 4000, 1000];     // quote midpoint, cents
const HALF: [i64; 3] = [1, 2, 1];              // quoted half-spread, cents
const DEPTH: [i64; 3] = [2000, 2500, 5000];    // shares shown at each one-cent bid level
const KAPPA: [f64; 3] = [0.7, 0.25, 0.07];     // refill rate of the missing depth, per minute
const DAYS: [[(f64, f64); 5]; 3] = [           // (return in bp, dollar volume in $ millions)
    [(80.0, 100.0), (-150.0, 120.0), (60.0, 100.0), (-100.0, 100.0), (135.0, 100.0)],
    [(100.0, 25.0), (-160.0, 20.0), (60.0, 20.0), (-50.0, 25.0), (45.0, 15.0)],
    [(120.0, 10.0), (-200.0, 16.0), (70.0, 10.0), (-90.0, 12.0), (110.0, 10.0)],
];
fn tape(i: usize) -> [(f64, f64, f64); 3] {    // (side, shares, price in cents)
    let (m, h) = (MID[i] as f64, HALF[i] as f64);
    [(1.0, 500.0, m + h), (-1.0, 300.0, m - h), (1.0, 200.0, m)]
}
fn effective(i: usize) -> f64 {                // share-weighted 2 s (p - m) / m, in bp
    let m = MID[i] as f64;
    let (mut num, mut den) = (0.0, 0.0);
    for (s, q, p) in tape(i) {
        num += q * 2.0 * s * (p - m) / m * 1e4; den += q;
    }
    num / den
}
fn amihud(i: usize, scale: f64, signed: bool) -> f64 {
    let mut tot = 0.0;
    for &(r, v) in DAYS[i].iter() { tot += (if signed { r } else { r.abs() }) / (v * scale); }
    tot / DAYS[i].len() as f64
}
fn ratio_of_sums(i: usize) -> f64 {
    let (mut sr, mut sv) = (0.0, 0.0);
    for &(r, v) in DAYS[i].iter() { sr += r.abs(); sv += v; }
    sr / sv
}
fn sim(mid: f64, h: f64, keep: f64, seed: u64) -> (f64, f64) {
    let (n, mut g) = (20000usize, Rng { x: seed });
    let (mut m, mut s) = (mid, 1.0f64);
    let (mut direct, mut psum) = (0.0, 0.0);
    let mut prices = Vec::with_capacity(n);
    for _ in 0..n {
        m += h * (2.0 * g.u() - 1.0);          // the fair price wanders
        if g.u() >= keep { s = -s; }           // keep = 0.5 means independent signs
        let p = m + s * h;
        direct += 2.0 * s * (p - m) / m * 1e4; psum += p; prices.push(p);
    }
    let (mut sx, mut sy, mut sxy) = (0.0, 0.0, 0.0);
    for k in 1..n - 1 {
        let (a, b) = (prices[k + 1] - prices[k], prices[k] - prices[k - 1]);
        sx += a; sy += b; sxy += a * b;
    }
    let c = (n - 2) as f64;
    let cov = sxy / c - (sx / c) * (sy / c);
    (direct / n as f64, 2.0 * (-cov).sqrt() / (psum / n as f64) * 1e4)
}
fn walk(i: usize, shares: i64) -> i64 {        // road 1: take the bid levels one by one
    let (mut left, mut k, mut cost) = (shares, 0i64, 0i64);
    while left > 0 {
        let take = DEPTH[i].min(left);
        cost += take * (HALF[i] + k); left -= take; k += 1;
    }
    cost
}
fn closed(i: usize, shares: i64) -> i64 {      // road 2: the arithmetic series
    let (d, h) = (DEPTH[i], HALF[i]); let (n, r) = (shares / d, shares % d);
    d * (n * h + n * (n - 1) / 2) + r * (h + n)
}
fn cost_bp(i: usize, dollars_m: f64, road: fn(usize, i64) -> i64) -> f64 {
    let shares = (dollars_m * 1e6 * 100.0) as i64 / MID[i];
    road(i, shares) as f64 / shares as f64 / MID[i] as f64 * 1e4
}
fn depth_dollars(i: usize) -> f64 {            // dollars bid within 20 bp of the midpoint
    let (mut tot, mut k) = (0i64, 0i64);
    while (HALF[i] + k) * 10000 <= 20 * MID[i] {
        tot += DEPTH[i] * (MID[i] - HALF[i] - k); k += 1;
    }
    tot as f64 / 100.0
}
fn median_refill(kappa: f64, seed: u64) -> f64 {
    let (n, mut g) = (20001usize, Rng { x: seed });
    let mut t: Vec<f64> = (0..n).map(|_| -(1.0 - g.u()).ln() / kappa).collect();
    t.sort_by(|a, b| a.partial_cmp(b).unwrap());
    t[n / 2]
}
fn row(label: &str, vals: &[f64], d: usize) {
    let mut line = format!("{:<40}", label);
    for v in vals { line += &format!("{:>11.*}", d, v); }
    println!("{}", line);
}
fn main() {
    let eff: Vec<f64> = (0..3).map(effective).collect();
    let sims: Vec<(f64, f64)> = (0..3)
        .map(|i| sim(MID[i] as f64 / 100.0, eff[i] / 2e4 * MID[i] as f64 / 100.0, 0.5, 11 + i as u64))
        .collect();
    let split = sim(100.0, eff[0] / 2e4 * 100.0, 0.8, 99);
    let ami: Vec<f64> = (0..3).map(|i| amihud(i, 1.0, false)).collect();
    let hl: Vec<f64> = (0..3).map(|i| 2f64.ln() / KAPPA[i]).collect();
    let hl_mc: Vec<f64> = (0..3).map(|i| median_refill(KAPPA[i], 21 + i as u64)).collect();
    let cost1: Vec<f64> = (0..3).map(|i| cost_bp(i, 1.0, walk)).collect();
    let dep: Vec<f64> = (0..3).map(depth_dollars).collect();
    let all = |f: &dyn Fn(usize) -> f64| -> Vec<f64> { (0..3).map(|i| f(i)).collect() };
    let mut head = format!("{:<40}", "measure");
    for n in NAMES { head += &format!("{:>11}", n); }
    println!("{}", head);
    row("quoted spread, bp", &all(&|i| 2e4 * HALF[i] as f64 / MID[i] as f64), 4);
    for i in [0usize, 2] {
        let v: Vec<f64> = tape(i).iter().map(|&(s, _, p)| 2.0 * s * (p - MID[i] as f64) / MID[i] as f64 * 1e4).collect();
        row(&format!("{} tape, each trade, bp", NAMES[i]), &v, 4);
    }
    row("effective spread, 3-trade tape, bp", &eff, 4);
    row("long tape: effective, direct, bp", &all(&|i| sims[i].0), 4);
    row("long tape: Roll, prices only, bp", &all(&|i| sims[i].1), 4);
    for i in [0usize, 2] {
        let v: Vec<f64> = DAYS[i].iter().map(|&(r, v)| r.abs() / v).collect();
        row(&format!("{} days, |r| / V", NAMES[i]), &v, 4);
    }
    row("Amihud, bp per $1m", &ami, 4);
    row("depth within 20 bp of mid, $", &dep, 2);
    for m in [0.25, 0.5, 1.0, 2.0] {
        row(&format!("sell ${:.2}m, walk the book, bp", m), &all(&|i| cost_bp(i, m, walk)), 2);
    }
    row("sell $1.00m, closed form, bp", &all(&|i| cost_bp(i, 1.0, closed)), 2);
    let sh: Vec<f64> = (0..3).map(|i| (100_000_000 / MID[i]) as f64).collect();
    row("$1m sale: shares; then levels walked", &[sh[0], sh[1], sh[2], sh[0] / DEPTH[0] as f64, sh[1] / DEPTH[1] as f64, sh[2] / DEPTH[2] as f64], 0);
    row("half-life ln2/kappa, minutes", &hl, 4);
    row("half-life, median of 20001 gaps", &hl_mc, 4);
    for t in 0..11 {
        row(&format!("refilled %, minute {}", t), &all(&|i| 100.0 * (1.0 - (-KAPPA[i] * t as f64).exp())), 2);
    }
    row("shares a day, millions", &all(&|i| {
        let mut v = 0.0;
        for d in DAYS[i] { v += d.1; }
        v / 5.0 / (MID[i] as f64 / 100.0) }), 4);
    row("wrong: Amihud as ratio of sums", &all(&ratio_of_sums), 4);
    row("wrong: Amihud with signed returns", &all(&|i| amihud(i, 1.0, true)), 4);
    row("wrong: half-spread reported, bp", &all(&|i| eff[i] / 2.0), 4);
    row("wrong: split orders: true, Roll, ratio", &[split.0, split.1, split.1 / split.0], 4);
    row("Amihud with volumes x10", &all(&|i| amihud(i, 10.0, false)), 4);
    row("house: sell 100,000 Acme: bp, $, levels",
        &[walk(0, 100000) as f64 / 100000.0 / MID[0] as f64 * 1e4,
          walk(0, 100000) as f64 / 100.0, 100000.0 / DEPTH[0] as f64], 2);
    row("Cobble/Acme: eff, Amihud, $1m sell", &[eff[2] / eff[0], ami[2] / ami[0], cost1[2] / cost1[0]], 2);
    row("half-life C/A, sim C/A; depth A/C", &[hl[2] / hl[0], hl_mc[2] / hl_mc[0], dep[0] / dep[2]], 2);
    let (hand_eff, hand_ami) = ([1.6, 8.0, 16.0], [1.0, 4.0, 10.0]);
    for i in 0..3 {
        assert!((eff[i] - hand_eff[i]).abs() < 1e-9, "tape vs the hand table");
        assert!((sims[i].1 / sims[i].0 - 1.0).abs() < 0.05, "Roll within 5% of the direct spread");
        assert!((ami[i] - hand_ami[i]).abs() < 1e-12, "Amihud vs the hand table");
        assert!((amihud(i, 10.0, false) * 10.0 - ami[i]).abs() < 1e-12, "ten times the dollars");
        for s in [2500i64, 6250, 25000, 99999, 200000] {
            assert_eq!(walk(i, s), closed(i, s), "book walk vs series");
        }
        assert!((hl_mc[i] / hl[i] - 1.0).abs() < 0.04, "simulated median refill vs ln2/kappa");
    }
    assert!((split.1 / split.0 - 0.4).abs() < 0.08, "split orders: Roll reads about 0.4 of the truth");
    assert!(eff[0] < eff[1] && eff[1] < eff[2], "spread ranking");
    assert!(ami[0] < ami[1] && ami[1] < ami[2], "Amihud ranking");
    assert!(dep[0] > dep[1] && dep[1] > dep[2], "depth ranking");
    println!("ranking, most liquid first: Acme, Beacon, Cobble on every measure");
    println!("ALL CHECKS PASS");
}
