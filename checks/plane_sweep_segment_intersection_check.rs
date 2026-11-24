// Plane sweep -- the same check as the Python, in Rust.  No crates.  A vertical line sweeps
// left to right over straight copper tracks.  Tracks are kept in up-down order and only next-door
// tracks are tested for a crossing.  Road two tests every pair (brute force); the answers must agree.
use std::cmp::Reverse;
use std::collections::{BinaryHeap, BTreeMap, BTreeSet};
type Seg = ((i64, i64), (i64, i64));
type Ev = Reverse<(u64, u8, u64, usize, usize)>;  // (x, kind 0 start / 1 crossing / 2 end, y, a, b)
type Found = BTreeMap<(usize, usize), (f64, f64)>;
fn orient(a: (i64, i64), b: (i64, i64), c: (i64, i64)) -> i64 { (b.0 - a.0) * (c.1 - a.1) - (b.1 - a.1) * (c.0 - a.0) }
fn meet(s: Seg, t: Seg) -> Option<(f64, f64)> {   // crossing point of two segments, or None
    let ((p, q), (r, u)) = (s, t); let (d1, d2) = (orient(r, u, p), orient(r, u, q));
    if d1 * d2 >= 0 || orient(p, q, r) * orient(p, q, u) >= 0 { return None }   // no straddle, no crossing
    let f = d1 as f64 / (d1 - d2) as f64;          // fraction of the way from p to q
    Some((p.0 as f64 + f * (q.0 - p.0) as f64, p.1 as f64 + f * (q.1 - p.1) as f64))
}
fn y_at(s: Seg, x: f64) -> f64 { s.0.1 as f64 + (x - s.0.0 as f64) * (s.1.1 - s.0.1) as f64 / (s.1.0 - s.0.0) as f64 }
fn g(v: f64) -> String { format!("{:.6}", v).trim_end_matches('0').trim_end_matches('.').to_string() }
fn test(k: usize, s: &[Seg], order: &[usize], tested: &mut BTreeSet<(usize, usize)>, found: &mut Found, ev: &mut BinaryHeap<Ev>) {
    if k + 1 >= order.len() { return }            // the next-door pair at positions k, k + 1
    let pair = (order[k].min(order[k + 1]), order[k].max(order[k + 1]));
    if let (true, Some(c)) = (tested.insert(pair), meet(s[pair.0], s[pair.1])) {
        found.insert(pair, c); ev.push(Reverse((c.0.to_bits(), 1, c.1.to_bits(), pair.0, pair.1)));
    }
}
fn sweep(s: &[Seg], swap: bool, mut log: Option<&mut Vec<String>>) -> (Found, BTreeSet<(usize, usize)>) {
    let mut ev: BinaryHeap<Ev> = s.iter().enumerate().flat_map(|(i, &(p, q))| [(p, 0), (q, 2)].map(|(e, kind)|
        Reverse(((e.0 as f64).to_bits(), kind, (e.1 as f64).to_bits(), i, i)))).collect();
    let (mut order, mut tested, mut found): (Vec<usize>, _, Found) = (vec![], BTreeSet::new(), BTreeMap::new());
    macro_rules! t { ($k:expr) => { test($k, s, &order, &mut tested, &mut found, &mut ev) } }
    while let Some(Reverse((xb, kind, yb, a, b))) = ev.pop() {
        let (x, y) = (f64::from_bits(xb), f64::from_bits(yb));
        if kind == 0 {                             // a track starts: slot it in by height
            let k = order.iter().filter(|&&j| y_at(s[j], x) < y).count();
            order.insert(k, a); if k > 0 { t!(k - 1) } t!(k);
        } else if kind == 2 {                      // a track ends: its two neighbours become next-door
            let k = order.iter().position(|&j| j == a).unwrap();
            order.remove(k); if k > 0 { t!(k - 1) }
        } else if swap {                           // a crossing: the two tracks swap places
            let k = order.iter().position(|&j| j == a || j == b).unwrap();
            order.swap(k, k + 1); if k > 0 { t!(k - 1) } t!(k + 1);
        }
        if let (Some(l), true) = (log.as_deref_mut(), ev.peek().map_or(true, |e| (e.0).0 != xb)) {
            let names: Vec<String> = order.iter().rev().map(|&j| format!("S{} at {:.2}", j + 1, y_at(s[j], x))).collect();
            l.push(format!("x = {}: top to bottom {}", g(x), if names.is_empty() { "(none left)".to_string() } else { names.join(", ") }));
        }
    }
    (found, tested)
}
fn brute(s: &[Seg]) -> Found {                     // road two: test every pair
    let mut out = BTreeMap::new(); for i in 0..s.len() { for j in i + 1..s.len() { if let Some(c) = meet(s[i], s[j]) { out.insert((i, j), c); } } }
    out
}
fn names<'a>(pairs: impl Iterator<Item = &'a (usize, usize)>) -> String { pairs.map(|(i, j)| format!("S{}-S{}", i + 1, j + 1)).collect::<Vec<_>>().join(", ") }
fn main() {
    let tracks: Vec<Seg> = vec![((0, 0), (6, 4)), ((0, 4), (6, 0)), ((1, 3), (5, 3)), ((5, 0), (6, 1))];
    let mut log = vec![]; let (found, tested) = sweep(&tracks, true, Some(&mut log));
    println!("{}", log.join("\n"));
    let mut pts: Vec<_> = found.iter().collect(); pts.sort_by(|a, b| a.1.partial_cmp(b.1).unwrap());
    for ((i, j), (x, y)) in &pts { println!("S{} crosses S{} at ({:.2}, {:.2})", i + 1, j + 1, x, y) }
    let every: BTreeSet<(usize, usize)> = (0..4).flat_map(|i| (i + 1..4).map(move |j| (i, j))).collect();
    println!("pairs tested {} of {}: {}; never tested: {}", tested.len(), every.len(), names(tested.iter()), names(every.difference(&tested)));
    let mut r: Vec<i64> = vec![2026];                 // a fixed pseudo-random sequence for a 1000-track board
    while r.len() < 4001 { let v = (r[r.len() - 1] * 1103515245 + 12345) % (1 << 31); r.push(v) }
    let board: Vec<Seg> = (1..4001).step_by(4).map(|i| ((r[i] % 100000, 3000 + r[i + 1] % 100000),
        (r[i] % 100000 + 1 + r[i + 2] % 3000, r[i + 1] % 100000 + r[i + 3] % 6001))).collect();
    let (bf, (bs, bt), n) = (brute(&board), sweep(&board, true, None), board.len());
    let (k, pairs, lg) = (bs.len(), n * (n - 1) / 2, (n as f64).log2());
    println!("board: {} tracks, {} crossings by sweep, {} by all pairs; events 2n + k = {}", n, k, bf.len(), 2 * n + k);
    println!("board: sweep tested {} pairs; all pairs is {}; (n + k) log2 n = {:.0}", bt.len(), pairs, (n + k) as f64 * lg);
    let ((ns, _), (nb, _)) = (sweep(&tracks, false, None), sweep(&board, false, None));
    println!("mistake 1, no swap at a crossing: finds {} of 4, misses {}; board {} of {}", ns.len(), names(found.keys().filter(|p| !ns.contains_key(p))), nb.len(), k);
    println!("mistake 2, all {} cross each other (k = {}): (n + k) log2 n = {:.0}, more than {}", n, pairs, (n + pairs) as f64 * lg, pairs);
    let fig: Vec<String> = pts.iter().map(|(_, (x, y))| format!("({}, {})", g(60.0 + 60.0 * x), g(280.0 - 60.0 * y))).collect();
    println!("figure, sweep line x = 4 at {}; crossings {}", g(60.0 + 60.0 * 4.0), fig.join(" "));
    assert!(found == brute(&tracks) && found.len() == 4 && tested.len() == 5);       // two roads, one answer
    assert!(bs == bf && bt.len() < pairs / 50);    // the board: same crossings, far fewer tests
    assert!(found.iter().all(|(&(i, j), &(x, y))| (y - y_at(tracks[i], x)).abs() + (y - y_at(tracks[j], x)).abs() < 1e-12));
    assert!(ns.len() < 4 && nb.len() < k);         // dropping the swap loses crossings
    println!("ALL CHECKS PASS");
}
