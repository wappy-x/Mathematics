// Persistence in practice: sliding windows on daily returns, before and after a simulated crash.
// std only. Returns are whole basis points (1 bp = 0.01%); squared distances are integers.
// Bars are Vietoris-Rips bars over Z mod 2, in ball radius r (an edge joins windows within 2r), in percent.
use std::collections::{BTreeSet, HashMap};
type Set = BTreeSet<usize>;

struct Rng(u64); // SplitMix64, the same numbers as the Python check
impl Rng {
    fn next(&mut self) -> u64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = (self.0 ^ (self.0 >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    }
    fn gauss(&mut self, sd: i64) -> i64 {
        let tot: i64 = (0..12).map(|_| (self.next() >> 40) as i64).sum::<i64>() - 6 * (1 << 24);
        (sd * tot * 2 + (1 << 24)).div_euclid(1 << 25)
    }
    fn shuffle<T>(&mut self, v: &mut [T]) {
        for i in (1..v.len()).rev() { let j = (self.next() % (i as u64 + 1)) as usize; v.swap(i, j); }
    }
}

fn simulate(seed: u64) -> (Rng, Vec<i64>, Vec<i64>) {
    let mut g = Rng(seed);
    let before: Vec<i64> = (0..42).map(|_| g.gauss(100)).collect();
    let (mut a, mut b, mut after) = (0i64, 0i64, vec![]);
    for _ in 0..72 { let x = a - (95 * b).div_euclid(100) + g.gauss(60); b = a; a = x; after.push(a); }
    (g, before, after[30..].to_vec())
}

fn windows(x: &[i64], m: usize) -> Vec<Vec<i64>> { (0..=x.len() - m).map(|i| x[i..i + m].to_vec()).collect() }
fn d2(p: &[i64], q: &[i64]) -> i64 { p.iter().zip(q).map(|(u, v)| (u - v) * (u - v)).sum() }
fn rad(w: i64) -> f64 { (w as f64).sqrt() / 200.0 }
fn xor(a: &mut Set, b: &Set) { for &e in b { if !a.remove(&e) { a.insert(e); } } }

type Bars = (Vec<i64>, Vec<(i64, i64)>, Vec<Vec<i64>>);
fn bars(p: &[Vec<i64>]) -> Bars {
    let n = p.len(); let d: Vec<Vec<i64>> = p.iter().map(|a| p.iter().map(|b| d2(a, b)).collect()).collect();
    let enc = d.iter().map(|r| *r.iter().max().unwrap()).min().unwrap();
    let mut e = vec![];
    for i in 0..n { for j in i + 1..n { e.push((d[i][j], i, j)); } }
    e.sort();
    let idx: HashMap<(usize, usize), usize> = e.iter().enumerate().map(|(k, &(_, i, j))| ((i, j), k)).collect();
    let mut par: Vec<usize> = (0..n).collect();
    fn find(par: &[usize], mut a: usize) -> usize { while par[a] != a { a = par[a]; } a }
    let mut h0 = vec![];
    for &(w, i, j) in &e {
        let (a, b) = (find(&par, i), find(&par, j)); if a != b { par[a] = b; h0.push(w); }
    }
    let mut t = vec![];
    for i in 0..n { for j in i + 1..n { for k in j + 1..n {
        let w = d[i][j].max(d[i][k]).max(d[j][k]); if w <= enc { t.push((w, i, j, k)); }
    } } }
    t.sort();
    let (mut low, mut h1): (HashMap<usize, Set>, Vec<(i64, i64)>) = (HashMap::new(), vec![]);
    for &(w, i, j, k) in &t {
        let mut col: Set = [idx[&(i, j)], idx[&(i, k)], idx[&(j, k)]].into_iter().collect();
        while let Some(&p) = col.last() { if let Some(c) = low.get(&p) { xor(&mut col, c); } else { break; } }
        if let Some(&p) = col.last() { if e[p].0 < w { h1.push((e[p].0, w)); } low.insert(p, col); }
    }
    (h0, h1, d)
}

fn longest(h1: &[(i64, i64)]) -> f64 { h1.iter().map(|&(b, d)| rad(d) - rad(b)).fold(0.0, f64::max) }

fn betti_at(d: &[Vec<i64>], w: i64) -> (usize, usize) {
    let (n, mut ed) = (d.len(), vec![]);
    for i in 0..n { for j in i + 1..n { if d[i][j] <= w { ed.push((i, j)); } } }
    let ei: HashMap<(usize, usize), usize> = ed.iter().enumerate().map(|(k, &e)| (e, k)).collect();
    let mut tr: Vec<Set> = vec![];
    for &(i, j) in &ed { for k in j + 1..n {
        if let (Some(&a), Some(&b)) = (ei.get(&(i, k)), ei.get(&(j, k))) { tr.push([ei[&(i, j)], a, b].into_iter().collect()); }
    } }
    let rank = |cols: Vec<Set>| {
        let (mut piv, mut r): (HashMap<usize, Set>, usize) = (HashMap::new(), 0);
        for mut c in cols {
            while let Some(&p) = c.first() { if let Some(q) = piv.get(&p) { xor(&mut c, q); } else { break; } }
            if let Some(&p) = c.first() { piv.insert(p, c); r += 1; }
        }
        r
    };
    let (r1, r2) = (rank(ed.iter().map(|&(i, j)| [i, j].into_iter().collect()).collect()), rank(tr));
    (n - r1, ed.len() - r1 - r2)
}

fn test(g: &mut Rng, x: &[i64], m: usize, n: usize) -> (f64, f64, f64) {
    let l = longest(&bars(&windows(x, m)).1);
    let null: Vec<f64> = (0..n).map(|_| { let mut y = x.to_vec(); g.shuffle(&mut y); longest(&bars(&windows(&y, m)).1) }).collect();
    let band = null.iter().cloned().fold(f64::MIN, f64::max);
    (l, band, (1 + null.iter().filter(|&&v| v >= l).count()) as f64 / (n + 1) as f64)
}

fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }
fn join(v: &[i64]) -> String { v.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(" ") }

fn main() {
    let hexa = windows(&[200, 100, -100, -200, -100, 100, 200, 100], 3);
    let hb = bars(&hexa).1;
    let hw: Vec<String> = hexa.iter().map(|p| format!("({})", p.iter().map(|v| (v / 100).to_string()).collect::<Vec<_>>().join(","))).collect();
    println!("hexagon windows (%): {}", hw.join(" "));
    let sq: BTreeSet<i64> = hexa[1..6].iter().map(|q| d2(&hexa[0], q) / 10000).collect();
    println!("hexagon squared distances (%^2): {:?}", sq.into_iter().collect::<Vec<_>>());
    println!("hexagon loop bar: [{:.4}, {:.4}), {} loop", rad(hb[0].0), rad(hb[0].1), hb.len());
    assert!(hb.len() == 1 && (rad(hb[0].0) - 6f64.sqrt() / 2.0).abs() < 1e-12 && (rad(hb[0].1) - 18f64.sqrt() / 2.0).abs() < 1e-12);
    let (mut g, before, after) = simulate(2000);
    println!("before (bp): {}\ncrash day (bp): -900\nafter (bp): {}", join(&before), join(&after));
    println!("planted cycle after the fall: x_t = x_(t-1) - 0.95 x_(t-2) + noise, period {:.2} days", 2.0 * std::f64::consts::PI / (0.5 / 0.95f64.sqrt()).acos());
    let vol: Vec<f64> = [&before, &after].iter().map(|x| (x.iter().map(|v| v * v).sum::<i64>() as f64 / x.len() as f64).sqrt() / 100.0).collect();
    println!("realised daily vol (%): before {:.2}, after {:.2}, ratio {:.2}", vol[0], vol[1], vol[1] / vol[0]);
    println!("annualised vol (%): before {:.1}, after {:.1}", 252f64.sqrt() * vol[0], 252f64.sqrt() * vol[1]);
    let mut res = vec![];
    for (name, x) in [("before", &before), ("after", &after)] {
        let (h0, mut h1, d) = bars(&windows(x, 3));
        let (tot, l) = (h0.iter().map(|&w| rad(w)).sum::<f64>(), longest(&h1));
        h1.sort_by(|p, q| (rad(p.0) - rad(p.1)).partial_cmp(&(rad(q.0) - rad(q.1))).unwrap());
        let top: Vec<String> = h1[..3].iter().map(|&(b, d)| format!("[{:.2}, {:.2})", rad(b), rad(d))).collect();
        println!("{} m=3: {} H0 deaths, total {:.2}; {} H1 bars, longest three: {}", name, h0.len(), tot, h1.len(), top.join(", "));
        let mid = (h1[0].0 + h1[0].1).div_euclid(2);
        let alive = (h0.iter().filter(|&&w| w > mid).count() + 1, h1.iter().filter(|&&(b, d)| b <= mid && mid < d).count());
        let fresh = betti_at(&d, mid); res.push((tot, l));
        println!("  at r = {:.4}: bars alive (H0, H1) = {:?}; fresh ranks give {:?}", rad(mid), alive, fresh);
        assert_eq!(alive, fresh);
    }
    println!("ratio after/before: H0 total {:.2}, longest H1 bar {:.2}", res[1].0 / res[0].0, res[1].1 / res[0].1);
    let (k, alpha) = (4, 0.05f64);
    println!("tests k = {}, threshold alpha/k = {}; chance of a false alarm uncorrected: {:.4} if independent, at most {:.2} in any case", k, alpha / k as f64, 1.0 - (1.0 - alpha).powi(k), k as f64 * alpha);
    let mut band = HashMap::new();
    for (name, x) in [("before", &before), ("after", &after)] {
        for m in [3, 4] {
            let (l, b, p) = test(&mut g, x, m, 99); band.insert((name, m), b);
            println!("{} m={}: longest {:.2}, band (max of 99 shuffles) {:.2}, p = {:.2}, feature: {}", name, m, l, b, p, yn(p <= alpha / k as f64));
            assert_eq!(p <= alpha / k as f64, name == "after");
            assert!(name == "before" || (p == 0.01 && b < l)); // after: no shuffle reached L, so p = (1 + 0) / (99 + 1)
        }
    }
    let (l0, ba) = (res[1].1, band[&("after", 3)]);
    let jit: Vec<i64> = after.iter().map(|v| v + (g.next() % 21) as i64 - 10).collect();
    let lj = longest(&bars(&windows(&jit, 3)).1);
    println!("noise: jitter 10 bp moves the longest bar {:.2} -> {:.2}, bound {:.4}, above band: {}", l0, lj, 2.0 * 3f64.sqrt() * 0.1, yn(lj > ba));
    assert!((lj - l0).abs() <= 2.0 * 3f64.sqrt() * 0.1 + 1e-12);
    let w = windows(&after, 3);
    let mut sub = vec![];
    for _ in 0..20 {
        let mut ix: Vec<usize> = (0..w.len()).collect(); g.shuffle(&mut ix);
        let mut keep = ix[..32].to_vec(); keep.sort();
        sub.push(longest(&bars(&keep.iter().map(|&i| w[i].clone()).collect::<Vec<_>>()).1));
    }
    let (lo, hi) = (sub.iter().cloned().fold(f64::MAX, f64::min), sub.iter().cloned().fold(f64::MIN, f64::max));
    println!("resample: 20 draws of 32 of 40 windows: longest bar {:.2} to {:.2}, above band in {}/20", lo, hi, sub.iter().filter(|&&v| v > ba).count());
    let mut found = [0, 0];
    for seed in 2001..2011 {
        let (mut g2, b2, a2) = simulate(seed);
        if test(&mut g2, &b2, 3, 19).2 <= 0.05 { found[0] += 1; }
        if test(&mut g2, &a2, 3, 19).2 <= 0.05 { found[1] += 1; }
    }
    println!("10 fresh seeds, 19 shuffles each, at 0.05: calm stretches flagged {}/10, rebound stretches found {}/10", found[0], found[1]);
    let dbl: Vec<i64> = before.iter().map(|v| 2 * v).collect();
    let (ld, _, pd) = test(&mut Rng(7), &dbl, 3, 99);
    let (lb, _, pb) = test(&mut Rng(7), &before, 3, 99);
    println!("breaks: calm returns doubled: longest bar {:.2} vs {:.2}, p = {:.2} vs {:.2}", ld, lb, pd, pb);
    assert!((ld - 2.0 * lb).abs() < 1e-12 && pd == pb);
    println!("breaks: diameter instead of radius: longest bar after reads {:.2}", 2.0 * l0);
    println!("ALL CHECKS PASS");
}
