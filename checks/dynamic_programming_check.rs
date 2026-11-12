// Dynamic programming -- the same check as the Python, in Rust.  No crates.
// A trader packs a 15 kg rucksack for a fair from 6 items; each goes in whole or not at all.
// K(i, w) = the most value from the first i items with w kg of room.
use std::collections::HashMap;
const NAMES: [&str; 6] = ["books", "soap", "wool", "cheese", "honey", "candles"];
const KG: [usize; 6] = [6, 4, 7, 5, 3, 2];        // weight of item 1..6, kg
const GBP: [u64; 6] = [100, 60, 135, 95, 80, 50]; // what it sells for, pounds
const CAP: usize = 15;

fn table(kg: &[usize], gbp: &[u64], cap: usize) -> (Vec<Vec<u64>>, usize) { // road one: forwards
    let (mut k, mut cells) = (vec![vec![0u64; cap + 1]], 0);
    for i in 1..=kg.len() {
        let mut row = Vec::new();
        for w in 0..=cap {
            let skip = k[i - 1][w];
            let take = if kg[i - 1] <= w { gbp[i - 1] + k[i - 1][w - kg[i - 1]] } else { 0 };
            row.push(skip.max(take)); cells += 1;
        }
        k.push(row);
    }
    (k, cells)
}

struct Rec<'a> { kg: &'a [usize], gbp: &'a [u64], calls: usize, memo: Option<HashMap<(usize, usize), u64>>,
                 seen: HashMap<(usize, usize), usize> }
impl<'a> Rec<'a> {                                // road two: recurse backwards; memo None is naive
    fn k(&mut self, i: usize, w: usize) -> u64 {
        self.calls += 1;
        *self.seen.entry((i, w)).or_insert(0) += 1;
        if let Some(m) = &self.memo { if let Some(&v) = m.get(&(i, w)) { return v; } }
        let mut best = if i == 0 { 0 } else { self.k(i - 1, w) };
        if i > 0 && self.kg[i - 1] <= w { best = best.max(self.gbp[i - 1] + self.k(i - 1, w - self.kg[i - 1])); }
        if let Some(m) = &mut self.memo { m.insert((i, w), best); }
        best
    }
}
fn solve<'a>(kg: &'a [usize], gbp: &'a [u64], cap: usize, memo: bool) -> (u64, Rec<'a>) {
    let mut r = Rec { kg, gbp, calls: 0, memo: if memo { Some(HashMap::new()) } else { None }, seen: HashMap::new() };
    let b = r.k(kg.len(), cap);
    (b, r)
}

fn brute(kg: &[usize], gbp: &[u64], cap: usize) -> (u64, usize) { // road three: every packing
    let (mut best, mut legal) = (0, 0);
    for m in 0..(1usize << kg.len()) {
        let w: usize = (0..kg.len()).filter(|j| m >> j & 1 == 1).map(|j| kg[j]).sum();
        if w <= cap {
            legal += 1;
            best = best.max((0..kg.len()).filter(|j| m >> j & 1 == 1).map(|j| gbp[j]).sum());
        }
    }
    (best, legal)
}

fn greedy(order: &[usize]) -> (u64, Vec<&'static str>) { // mistake: pack in a fixed order while things fit
    let (mut room, mut val, mut took) = (CAP, 0, Vec::new());
    for &j in order {
        if KG[j] <= room { room -= KG[j]; val += GBP[j]; took.push(NAMES[j]); }
    }
    (val, took)
}

fn bad_k(i: usize, w: usize, bad: &mut HashMap<usize, u64>) -> u64 { // wrong: memo keyed on i alone
    if let Some(&v) = bad.get(&i) { return v; }
    let mut best = if i == 0 { 0 } else { bad_k(i - 1, w, bad) };
    if i > 0 && KG[i - 1] <= w { best = best.max(GBP[i - 1] + bad_k(i - 1, w - KG[i - 1], bad)); }
    bad.insert(i, best);
    best
}

fn splitmix(s: u64) -> (u64, u64) {               // SplitMix64, written out, for the synthetic shops
    let s = s.wrapping_add(0x9E3779B97F4A7C15);
    let mut z = s;
    z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    (s, z ^ (z >> 31))
}

fn main() {
    let (k, cells) = table(&KG, &GBP, CAP);
    let items: Vec<String> = (0..6).map(|i| format!("{} {} {} kg {}", i + 1, NAMES[i], KG[i], GBP[i])).collect();
    println!("items: {}", items.join(", "));
    println!("table K(i, w), rows i = 0..6, columns w = 0..15 kg");
    for (i, row) in k.iter().enumerate() {
        println!("  i={}{}", i, row.iter().map(|v| format!("{:4}", v)).collect::<String>());
    }
    let (mut w, mut took) = (CAP, Vec::new());
    for i in (1..=6).rev() {                          // read the packing back
        if k[i][w] != k[i - 1][w] { took.push(i); w -= KG[i - 1]; }
    }
    took.reverse();
    for i in [6usize, 3] {                            // two cells, written out
        let r = CAP - KG[i - 1];
        println!("cell K({},{}) = max(K({},{}), {} + K({},{})) = max({}, {}) = {}", i, CAP, i - 1, CAP,
                 GBP[i - 1], i - 1, r, k[i - 1][CAP], GBP[i - 1] + k[i - 1][r], k[i][CAP]);
    }
    let (pkg, pval): (usize, u64) = (took.iter().map(|&i| KG[i - 1]).sum(), took.iter().map(|&i| GBP[i - 1]).sum());
    let names: Vec<&str> = took.iter().map(|&i| NAMES[i - 1]).collect();
    let vals: Vec<String> = took.iter().map(|&i| GBP[i - 1].to_string()).collect();
    println!("packing: {}, {} kg, {} = {}", names.join(" + "), pkg, vals.join(" + "), pval);
    let (best_naive, naive) = solve(&KG, &GBP, CAP, false);
    let (best_memo, memo) = solve(&KG, &GBP, CAP, true);
    let (best_brute, legal) = brute(&KG, &GBP, CAP);
    println!("small questions: (6 + 1) x ({} + 1) = {}; packings with 20 items: {}", CAP, 7 * (CAP + 1), 1u64 << 20);
    println!("table: {} cells filled, best {}", cells, k[6][CAP]);
    println!("naive recursion: {} calls, best {}", naive.calls, best_naive);
    println!("memoised: {} calls, {} different subproblems, best {}", memo.calls, memo.memo.as_ref().unwrap().len(), best_memo);
    println!("brute force: 64 packings, {} fit, best {}", legal, best_brute);
    let twice = naive.seen.get(&(3, 10)).copied().unwrap_or(0);
    println!("naive repeats: {} different subproblems; K(3,10) asked {} times, value {}", naive.seen.len(), twice, k[3][10]);
    let mut ratio: Vec<usize> = (0..6).collect();
    ratio.sort_by(|&a, &b| (GBP[b] as f64 / KG[b] as f64).partial_cmp(&(GBP[a] as f64 / KG[a] as f64)).unwrap());
    let mut high: Vec<usize> = (0..6).collect();
    high.sort_by(|&a, &b| GBP[b].cmp(&GBP[a]));
    for (label, order) in [("value per kg", &ratio), ("highest value", &high)] {
        let (v, t) = greedy(order);
        println!("wrong: greedy by {}: {} = {}", label, t.join(" + "), v);
    }
    let mut one = vec![0u64; CAP + 1];                // wrong: one row updated left to right
    for j in 0..6 { for w in KG[j]..=CAP { one[w] = one[w].max(GBP[j] + one[w - KG[j]]); } }
    println!("wrong: one row filled left to right, items reused: {}", one[CAP]);
    println!("wrong: memo keyed on i alone: {}", bad_k(6, CAP, &mut HashMap::new()));
    let pw: [usize; 6] = [1, 2, 4, 8, 16, 32];        // no overlap: every packing leaves a different room
    let pv: Vec<u64> = pw.iter().map(|&x| x as u64).collect();
    let (_, pn) = solve(&pw, &pv, 63, false);
    let (_, pm) = solve(&pw, &pv, 63, true);
    println!("no overlap, weights 1,2,4,8,16,32 kg, room 63: naive {} calls, memoised {} calls, {} subproblems",
             pn.calls, pm.calls, pm.memo.as_ref().unwrap().len());
    println!("weights in grams: table {} cells, not {}", 6 * (15000 + 1), cells);
    println!("synthetic, seed 2026, weights 1-10 kg, values 10-99, room 50 kg");
    let mut chart = Vec::new();
    for n in [4usize, 8, 12, 16, 20] {
        let (mut s, mut kg, mut gbp) = (2026u64, Vec::new(), Vec::new());
        for _ in 0..n {
            let (s1, a) = splitmix(s); let (s2, b) = splitmix(s1); s = s2;
            kg.push(1 + (a % 10) as usize); gbp.push(10 + b % 90);
        }
        let (kn, cn) = table(&kg, &gbp, 50);
        let (bn, rn) = solve(&kg, &gbp, 50, false);
        let (bm, rm) = solve(&kg, &gbp, 50, true);
        assert!(kn[n][50] == bn && bn == bm, "three roads disagree on a synthetic shop");
        chart.push((n, rn.calls, cn));
        println!("  n={:2}: naive {:8} calls, memo {:4} subproblems, table {:4} cells, best {}", n, rn.calls, rm.memo.as_ref().unwrap().len(), cn, bn);
    }
    let line = |f: &dyn Fn(&(usize, usize, usize)) -> usize| chart.iter().map(|c| f(c).to_string()).collect::<Vec<_>>().join(" ");
    println!("chart, items {}", line(&|c| c.0));
    println!("chart, naive calls {}", line(&|c| c.1));
    println!("chart, table cells {}", line(&|c| c.2));

    assert!(k[6][CAP] == best_brute && best_brute == 310, "table against all 64 packings");
    assert!(best_naive == best_memo && best_memo == best_brute, "both recursions against brute force");
    assert!(pval == k[6][CAP] && pkg <= CAP);
    assert!(memo.calls < naive.calls && twice == 2, "the overlap the card names");
    assert!(one[CAP] > best_brute, "reusing items must beat the honest best");
    println!("ALL CHECKS PASS");
}
