// Caratheodory's criterion -- the same check as the Python, in Rust.  No crates.
// Lengths are whole numbers of tenth-millimetres (1 m = 10000), so every sum is
// exact.  E = [0.5, 1.2]; R = 100 rust spots at 0.03, ..., 3.00; T = [0.2, 0.8] and
// [1.0, 2.0].  Four roads, then the toy fence of four panels.
use std::collections::BTreeSet;
type Iv = (i64, i64, bool, bool);            // a..b in tenth-mm; are the ends included?

fn length(pieces: &[Iv]) -> i64 {            // merge overlaps, add the lengths
    let mut v = pieces.to_vec();
    v.sort_by_key(|p| (p.0, p.1));
    let (mut total, mut reach) = (0, i64::MIN);
    for &(a, b, _, _) in &v {
        if a > reach { total += b - a; reach = b } else if b > reach { total += b - reach; reach = b }
    }
    total
}

fn meet(pieces: &[Iv], e: Iv) -> Vec<Iv> {   // the part of the pieces inside e
    let mut out = vec![];
    for &(a, b, lc, rc) in pieces {
        let (lo, l2) = if a > e.0 { (a, lc) } else { (e.0, e.2 && (lc || a < e.0)) };
        let (hi, r2) = if b < e.1 { (b, rc) } else { (e.1, e.3 && (rc || b > e.1)) };
        if lo < hi { out.push((lo, hi, l2, r2)) }
    }
    out
}

fn minus(pieces: &[Iv], e: Iv) -> Vec<Iv> { // the part outside e: cut left and right
    let mut out = meet(pieces, (-10000, e.0, true, !e.2));
    out.extend(meet(pieces, (e.1, 100000, !e.3, true)));
    out
}

fn cells(pieces: &[Iv], w: i64) -> i64 {     // grid cells of width w meeting the pieces
    let mut got = BTreeSet::new();
    for &(a, b, _, rc) in pieces {
        let hi = if b % w == 0 && !rc { b / w - 1 } else { b / w };
        for c in a / w..=hi { got.insert(c); }
    }
    got.len() as i64
}

fn m(v: i64) -> String { format!("{}.{:04}", v / 10000, v % 10000) }

fn inside(s: i64, set: &[Iv]) -> bool { set.iter().any(|p| p.0 <= s && s <= p.1) }

fn cut_out(set: &[Iv], pts: &[i64]) -> Vec<Iv> {
    let mut rest = set.to_vec();
    for &s in pts { rest = minus(&rest, (s, s, true, true)) }
    rest
}

struct Rng(u64);                             // SplitMix64, written out
impl Rng {
    fn next(&mut self, k: u64) -> i64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) % k) as i64
    }
}

const BOARDS: [u32; 3] = [1, 6, 12];         // boards over {a}, {b, c}, {c, d}; each costs 1
fn covered(k: u32) -> u32 {                  // the panels under the boards chosen by k
    (0..BOARDS.len()).filter(|i| k >> i & 1 == 1).fold(0, |u, i| u | BOARDS[i])
}
fn bill(a: u32) -> u32 {                     // cheapest set of boards covering a
    (0..1u32 << BOARDS.len()).filter(|&k| a & !covered(k) == 0).map(|k| k.count_ones()).min().unwrap()
}

fn main() {
    let e: Iv = (5000, 12000, true, true);
    let t: Vec<Iv> = vec![(2000, 8000, true, true), (10000, 20000, true, true)];
    let spots: Vec<i64> = (1..=100).map(|k| 300 * k).collect();
    let in_t: Vec<i64> = spots.iter().copied().filter(|&s| inside(s, &t)).collect();
    let (te, tne) = (length(&meet(&t, e)), length(&minus(&t, e)));
    let tr = length(&in_t.iter().map(|&s| (s, s, true, true)).collect::<Vec<Iv>>());
    let tnr = length(&cut_out(&t, &in_t));
    println!("fence [0, 3] m; E = [0.5, 1.2], size {}; rust spots R = 0.03, 0.06, ..., 3.00 (100 points)", m(length(&[e])));
    println!("test set T = [0.2, 0.8] and [1.0, 2.0]");
    let parts = |ps: &[Iv]| ps.iter().map(|&p| m(length(&[p]))).collect::<Vec<_>>().join(" + ");
    println!("road 1, exact lengths, an upper bound for outer measure: T = {} = {}", parts(&t), m(length(&t)));
    println!("  E splits T: inside {} = {}, outside {} = {}; total {}", parts(&meet(&t, e)), m(te),
             parts(&minus(&t, e)), m(tne), m(te + tne));
    let per: Vec<String> = t.iter().map(|p| spots.iter().filter(|&&s| p.0 <= s && s <= p.1).count().to_string()).collect();
    println!("  R splits T: inside {} ({} = {} spots), outside {}; total {}", m(tr), per.join(" + "), in_t.len(), m(tnr), m(tr + tnr));
    let (gap, hull): (Iv, Iv) = ((8000, 10000, false, false), (2000, 20000, true, true));  // T and the gap make [0.2, 2.0]
    let lows = [(length(&[hull]), length(&[gap])), (length(&[e]), length(&[gap])), (length(&[hull]), length(&[e]))];
    let low_txt: Vec<String> = ["T", "inside", "outside"].iter().zip(lows.iter())
        .map(|(w, &(a, b))| format!("{} >= {} - {} = {}", w, m(a), m(b), m(a - b))).collect();
    println!("  lower bounds by subadditivity, gaps (0.8, 1.0) and E: {}", low_txt.join(", "));
    println!("road 2, grid cells meeting each set, times cell width:");
    println!("  cells per metre | T | T and E | T minus E | sum | T and R | all of R");
    let (mut coarse, mut last) = ([0i64; 3], [0i64; 3]);
    for n in [10i64, 100, 1000, 10000] {
        let w = 10000 / n;
        let row = [cells(&t, w) * w, cells(&meet(&t, e), w) * w, cells(&minus(&t, e), w) * w];
        let pts = |p: &[i64]| p.iter().map(|s| s / w).collect::<BTreeSet<i64>>().len() as i64 * w;
        println!("  {:>5} | {} | {} | {} | {} | {} | {}", n, m(row[0]), m(row[1]), m(row[2]),
                 m(row[1] + row[2]), m(pts(&in_t)), m(pts(&spots)));
        if n == 10 { coarse = row }
        last = row;
    }
    let eps = 100;
    let cover: Vec<Iv> = t.iter().map(|p| (p.0 - eps / 4, p.1 + eps / 4, false, false)).collect();
    let (ci, co) = (length(&meet(&cover, e)), length(&minus(&cover, e)));
    println!("road 3, one cover of T, total {} = outer(T) + {}, cut at 0.5 and 1.2:", m(length(&cover)), m(eps));
    println!("  pieces inside E {} + pieces outside E {} = {}", m(ci), m(co), m(ci + co));
    let seed = 2026;
    let mut rng = Rng(seed);
    let (mut bad_e, mut bad_r) = (0, 0);
    for _ in 0..1000 {
        let v: Vec<i64> = (0..4).map(|_| rng.next(30001)).collect();
        let s: Vec<Iv> = vec![(v[0].min(v[1]), v[0].max(v[1]), true, true), (v[2].min(v[3]), v[2].max(v[3]), true, true)];
        if length(&meet(&s, e)) + length(&minus(&s, e)) != length(&s) { bad_e += 1 }
        let s_r: Vec<i64> = spots.iter().copied().filter(|&p| inside(p, &s)).collect();
        if length(&cut_out(&s, &s_r)) != length(&s) { bad_r += 1 }
    }
    println!("road 4, 1000 random two-piece test sets (SplitMix64, seed {}): E fails {}, R fails {}", seed, bad_e, bad_r);
    let names = ["-", "a", "b", "ab", "c", "ac", "bc", "abc", "d", "ad", "bd", "abd", "cd", "acd", "bcd", "abcd"];
    let ok: Vec<u32> = (0..16).filter(|&a| (0..16).all(|x| bill(x) == bill(x & a) + bill(x & !a & 15))).collect();
    println!("toy fence, panels a b c d; boards over a, over b c, over c d; each board costs 1");
    let bills: Vec<String> = (0..16).map(|a| format!("{}:{}", names[a as usize], bill(a))).collect();
    println!("  cheapest bill: {}", bills.join(" "));
    let nm = |v: &[u32]| v.iter().map(|&a| names[a as usize]).collect::<Vec<_>>().join(", ");
    println!("  sets passing all 16 tests: {}", nm(&ok));
    let mut blocks: Vec<u32> = vec![];          // road two: glue panels that share a board
    for bd in BOARDS {
        let glued = blocks.iter().filter(|&&b| b & bd != 0).fold(bd, |u, b| u | b);
        blocks.retain(|&b| b & bd == 0);
        blocks.push(glued);
    }
    let mut unions: Vec<u32> = (0..1u32 << blocks.len())
        .map(|k| (0..blocks.len()).filter(|i| k >> i & 1 == 1).fold(0, |u, i| u | blocks[i])).collect();
    unions.sort();
    println!("  glued blocks {}; their unions: {}", nm(&blocks), nm(&unions));
    let closed = ok.iter().all(|&a| ok.iter().all(|&b| ok.contains(&(15 & !a)) && ok.contains(&(a | b)) && ok.contains(&(a & b))));
    println!("  closed under complement, union, overlap: {}", if closed { "yes" } else { "no" });
    println!("  additive on them: {} + {} = {}", bill(1), bill(14), bill(15));
    println!("what breaks: b passes the whole-fence test, {} + {} = {}, but fails T = bc: {} + {} vs {}",
             bill(2), bill(13), bill(15), bill(2), bill(4), bill(6));
    println!("  outer measure off the passing sets: bill(b) + bill(c) = {}, bill(bc) = {}", bill(2) + bill(4), bill(6));
    let fx = |ps: &[Iv]| ps.iter().map(|p| format!("{} to {}", 30 + p.0 / 100, 30 + p.1 / 100))
        .collect::<Vec<_>>().join(" and ");        // figure x-coordinates: 30 + 100 per metre
    println!("figure, x = 30 + 100 * metres: fence {}; E {}; T {}; T and E {}; T minus E {}; spots every 3",
             fx(&[(0, 30000, true, true)]), fx(&[e]), fx(&t), fx(&meet(&t, e)), fx(&minus(&t, e)));
    assert!(te + tne == length(&t) && length(&t) == 16000 && tr + tnr == length(&t));
    assert!(lows.iter().map(|&(a, b)| a - b).collect::<Vec<i64>>() == vec![length(&t), te, tne]);  // the squeeze
    assert!(coarse == [18000, 7000, 12000]);    // the coarse row quoted in What breaks
    assert!([length(&t), te, tne].iter().zip(last).all(|(x, g)| 0 <= g - x && g - x <= 2)); // one cell per piece
    assert!(bad_e == 0 && bad_r == 0 && ci + co == length(&cover));
    assert!(ok == unions && closed && bill(1) + bill(14) == bill(15));
    assert!(bill(2) + bill(13) == bill(15) && bill(2) + bill(4) > bill(6));
    println!("ALL CHECKS PASS");
}
