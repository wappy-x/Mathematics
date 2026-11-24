// Edit distance and sequence alignment -- the same check as the Python, in Rust.  No crates.
// D(i, j) = the cheapest way to turn the first i letters of x into the first j letters of y.
use std::sync::atomic::{AtomicUsize, Ordering::Relaxed};
type Sub = fn(u8, u8) -> i64;
fn unit(a: u8, b: u8) -> i64 { if a == b { 0 } else { 1 } }   // Levenshtein: a change costs 1
fn dna(a: u8, b: u8) -> i64 { if a == b { -1 } else { 1 } }   // DNA score +1 / -1, kept as a cost = -score
fn indel(a: u8, b: u8) -> i64 { if a == b { 0 } else { 2 } }  // wrong: a change only as delete + insert
static CELLS: AtomicUsize = AtomicUsize::new(0);
static KEPT: [AtomicUsize; 2] = [AtomicUsize::new(0), AtomicUsize::new(0)]; // table cells held now, and the most at once
fn keep(k: isize) { let now = (KEPT[0].load(Relaxed) as isize + k) as usize; KEPT[0].store(now, Relaxed); KEPT[1].fetch_max(now, Relaxed); }
fn s(v: &[u8]) -> String { String::from_utf8(v.to_vec()).unwrap() } fn rev<T: Clone>(v: &[T]) -> Vec<T> { v.iter().rev().cloned().collect() }

fn last_row(x: &[u8], y: &[u8], sub: Sub, g: i64) -> Vec<i64> { // two rows only: the bottom row
    let mut prev: Vec<i64> = (0..=y.len() as i64).map(|j| j * g).collect(); keep(y.len() as isize + 1);
    for i in 1..=x.len() {
        let mut cur = vec![i as i64 * g; y.len() + 1]; keep(y.len() as isize + 1);
        for j in 1..=y.len() {
            cur[j] = (prev[j - 1] + sub(x[i - 1], y[j - 1])).min(prev[j] + g).min(cur[j - 1] + g);
            CELLS.fetch_add(1, Relaxed);
        }
        prev = cur; keep(-(y.len() as isize) - 1); // the old row is dropped
    }
    prev
}

fn table(x: &[u8], y: &[u8], sub: Sub, g: i64, border: bool) -> Vec<Vec<i64>> { // road one: whole table
    let b = if border { 1 } else { 0 };
    let mut d = vec![vec![0i64; y.len() + 1]; x.len() + 1]; keep(((x.len() + 1) * (y.len() + 1)) as isize);
    for j in 0..=y.len() { d[0][j] = b * j as i64 * g; }
    for i in 1..=x.len() {
        d[i][0] = b * i as i64 * g;
        for j in 1..=y.len() {
            d[i][j] = (d[i - 1][j - 1] + sub(x[i - 1], y[j - 1])).min(d[i - 1][j] + g).min(d[i][j - 1] + g);
            CELLS.fetch_add(1, Relaxed);
        }
    }
    d
}
fn dist(x: &[u8], y: &[u8], sub: Sub, g: i64, border: bool) -> i64 { table(x, y, sub, g, border)[x.len()][y.len()] }

fn trace(d: &[Vec<i64>], x: &[u8], y: &[u8], sub: Sub, g: i64) -> (Vec<u8>, Vec<u8>) { // walk back
    let (mut i, mut j, mut top, mut bot) = (x.len(), y.len(), Vec::new(), Vec::new());
    while i > 0 || j > 0 {
        if i > 0 && j > 0 && d[i][j] == d[i - 1][j - 1] + sub(x[i - 1], y[j - 1]) { top.push(x[i - 1]); bot.push(y[j - 1]); i -= 1; j -= 1; }
        else if i > 0 && d[i][j] == d[i - 1][j] + g { top.push(x[i - 1]); bot.push(b'-'); i -= 1; }
        else { top.push(b'-'); bot.push(y[j - 1]); j -= 1; }
    }
    (rev(&top), rev(&bot))
}

fn score(top: &[u8], bot: &[u8], sub: Sub, g: i64) -> i64 { // the cost of a written alignment
    top.iter().zip(bot).map(|(&a, &b)| if a == b'-' || b == b'-' { g } else { sub(a, b) }).sum()
}

fn go(x: &[u8], y: &[u8], i: usize, j: usize, c: i64, sub: Sub, g: i64, st: &mut (Option<i64>, u64, u64)) {
    if i == x.len() && j == y.len() {
        st.2 += 1;
        match st.0 { Some(b) if c > b => {}, Some(b) if c == b => st.1 += 1, _ => { st.0 = Some(c); st.1 = 1; } }
        return;
    }
    if i < x.len() && j < y.len() { go(x, y, i + 1, j + 1, c + sub(x[i], y[j]), sub, g, st); }
    if i < x.len() { go(x, y, i + 1, j, c + g, sub, g, st); }
    if j < y.len() { go(x, y, i, j + 1, c + g, sub, g, st); }
}
fn brute(x: &[u8], y: &[u8], sub: Sub, g: i64) -> (i64, u64, u64) { // road two: every alignment
    let mut st = (None, 0, 0); go(x, y, 0, 0, 0, sub, g, &mut st);
    (st.0.unwrap(), st.1, st.2)
}

fn plain(x: &[u8], y: &[u8], calls: &mut u64) -> i64 { // the recursion without a table
    *calls += 1;
    if x.is_empty() || y.is_empty() { return (x.len() + y.len()) as i64; }
    let (n, m) = (x.len() - 1, y.len() - 1);
    (plain(&x[..n], &y[..m], calls) + unit(x[n], y[m])).min(plain(&x[..n], y, calls) + 1).min(plain(x, &y[..m], calls) + 1)
}

fn hirsch(x: &[u8], y: &[u8], sub: Sub, g: i64, split_best: bool) -> (Vec<u8>, Vec<u8>) { // road three
    if x.len() <= 1 || y.is_empty() { let al = trace(&table(x, y, sub, g, true), x, y, sub, g); keep(-(((x.len() + 1) * (y.len() + 1)) as isize)); return al; }
    let mid = x.len() / 2;
    let left = last_row(&x[..mid], y, sub, g);
    let right = rev(&last_row(&rev(&x[mid..]), &rev(y), sub, g));
    let j = if split_best { (0..=y.len()).min_by_key(|&k| (left[k] + right[k], k)).unwrap() } else { y.len() / 2 }; drop((left, right)); keep(-2 * (y.len() as isize + 1));
    let (mut a1, mut b1) = hirsch(&x[..mid], &y[..j], sub, g, split_best);
    let (a2, b2) = hirsch(&x[mid..], &y[j..], sub, g, split_best);
    a1.extend(a2); b1.extend(b2); (a1, b1)
}
fn fact(k: u64) -> u64 { if k < 2 { 1 } else { k * fact(k - 1) } }
fn splitmix(s: u64) -> (u64, u64) { // SplitMix64, written out, for the synthetic DNA
    let s = s.wrapping_add(0x9E3779B97F4A7C15);
    let z = (s ^ (s >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    let z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    (s, z ^ (z >> 31))
}

fn main() {
    let (x, y) = (b"kitten".as_slice(), b"sitting".as_slice());
    CELLS.store(0, Relaxed); let d = table(x, y, unit, 1, true);
    println!("table for {} -> {}: rows i = 0..6, columns j = 0..7, {} cells filled", s(x), s(y), CELLS.load(Relaxed));
    for (i, row) in d.iter().enumerate() {
        let lab = if i > 0 { format!(" {}", x[i - 1] as char) } else { "  ".to_string() };
        println!("  {}{}", lab, row.iter().map(|v| format!("{:3}", v)).collect::<String>());
    }
    let (top, bot) = trace(&d, x, y, unit, 1);
    println!("traceback: {} / {}, cost {}", s(&top), s(&bot), score(&top, &bot, unit, 1));
    let edits: Vec<String> = top.iter().zip(&bot).filter(|(a, b)| a != b).map(|(&a, &b)|
        if a == b'-' { format!("insert {}", b as char) } else if b == b'-' { format!("delete {}", a as char) }
        else { format!("{}->{}", a as char, b as char) }).collect();
    println!("edits: {}", edits.join(", "));
    let bk = brute(x, y, unit, 1); let mut calls = 0u64; plain(x, y, &mut calls);
    println!("brute force: {} alignments, best {}, {} of them optimal", bk.2, bk.0, bk.1);
    println!("plain recursion: {} calls for {} different questions", calls, (x.len() + 1) * (y.len() + 1));
    let (g1, g2) = (b"GATTACA".as_slice(), b"GCATGCA".as_slice());
    let (dg, bg) = (table(g1, g2, unit, 1, true), brute(g1, g2, unit, 1));
    let (tg, bgt) = trace(&dg, g1, g2, unit, 1);
    println!("{} -> {}: distance {}, traceback {} / {}; brute force {} alignments, best {}, {} optimal",
             s(g1), s(g2), dg[7][7], s(&tg), s(&bgt), bg.2, bg.0, bg.1);
    for gap in [1i64, 2] {
        let ds = table(g1, g2, dna, gap, true);
        let (t, b) = trace(&ds, g1, g2, dna, gap);
        let bs = brute(g1, g2, dna, gap);
        println!("DNA score, match +1, mismatch -1, gap -{}: best {}, {} / {}; brute force best {}, {} optimal", gap, -ds[7][7], s(&t), s(&b), -bs.0, bs.1);
        assert!(ds[7][7] == bs.0 && bs.0 == score(&t, &b, dna, gap), "scored table against every alignment");
    }
    for (a, b) in [(x, y), (g1, g2)] {
        CELLS.store(0, Relaxed); KEPT[0].store(0, Relaxed); KEPT[1].store(0, Relaxed);
        let (ht, hb) = hirsch(a, b, unit, 1, true);
        println!("Hirschberg {} -> {}: {} / {}, cost {}, {} cells computed, peak {} cells held, 3 rows of {}",
                 s(a), s(b), s(&ht), s(&hb), score(&ht, &hb, unit, 1), CELLS.load(Relaxed), KEPT[1].load(Relaxed), b.len() + 1);
        assert!(KEPT[1].load(Relaxed) <= 3 * (b.len() + 1) && score(&ht, &hb, unit, 1) == dist(a, b, unit, 1, true), "Hirschberg against the full table, in 3 rows");
        let strip = |v: &[u8]| v.iter().filter(|&&c| c != b'-').cloned().collect::<Vec<u8>>();
        assert!(strip(&ht) == a && strip(&hb) == b, "the alignment spells both strings");
    }
    let (l, r) = (last_row(&x[..3], y, unit, 1), rev(&last_row(&rev(&x[3..]), &rev(y), unit, 1)));
    let sums: Vec<i64> = l.iter().zip(&r).map(|(a, b)| a + b).collect();
    println!("first split, kit | ten: forward {:?}, backward {:?}, sums {:?}", l, r, sums);
    let (q, t2) = (b"Beatles".as_slice(), b"The Beatles".as_slice());
    let ham = (0..t2.len()).filter(|&k| k >= q.len() || q[k] != t2[k]).count();
    println!("wrong: letter by letter, {} against {}: {} differences, true distance {}", s(q), s(t2), ham, dist(q, t2, unit, 1, true));
    println!("wrong: no changes, only insert and delete, {} -> {}: {}", s(x), s(y), dist(x, y, indel, 1, true));
    println!("wrong: border filled with zeros, {} -> {}: {}", s(q), s(t2), dist(q, t2, unit, 1, false));
    println!("limit: a swap, teh -> the: {} edits, not 1", dist(b"teh", b"the", unit, 1, true));
    let (wt, wb) = hirsch(q, t2, unit, 1, false);
    println!("wrong: Hirschberg splitting y at its middle, {} -> {}: {} / {}, cost {}", s(q), s(t2), s(&wt), s(&wb), score(&wt, &wb, unit, 1));
    println!("synthetic DNA, seed 2026, both strings of length n, unit costs");
    let (mut chart, mut st) = (Vec::new(), 2026u64);
    for n in [50usize, 100, 200, 400] {
        let (mut u, mut v) = (Vec::new(), Vec::new());
        for _ in 0..n {
            let (s1, r1) = splitmix(st); let (s2, r2) = splitmix(s1); st = s2;
            u.push(b"ACGT"[(r1 % 4) as usize]); v.push(b"ACGT"[(r2 % 4) as usize]);
        }
        CELLS.store(0, Relaxed); KEPT[0].store(0, Relaxed); KEPT[1].store(0, Relaxed); let full = dist(&u, &v, unit, 1, true); let (c_full, k_full) = (CELLS.load(Relaxed), KEPT[1].load(Relaxed));
        CELLS.store(0, Relaxed); KEPT[0].store(0, Relaxed); KEPT[1].store(0, Relaxed); let (ht, hb) = hirsch(&u, &v, unit, 1, true); let (c_h, k_h) = (CELLS.load(Relaxed), KEPT[1].load(Relaxed)); let hs = score(&ht, &hb, unit, 1);
        assert!(hs == full && c_h <= 2 * c_full && k_h <= 3 * (n + 1), "same cost, twice the work, 3 rows");
        chart.push((k_full, k_h));
        println!("  n={:3}: distance {:3}, Hirschberg {:3}; cells computed {:6} vs {:6}; cells kept {:6} vs {}",
                 n, full, hs, c_full, c_h, k_full, k_h);
    }
    println!("chart, n 50 100 200 400");
    println!("chart, cells kept by the full table {}", chart.iter().map(|c| c.0.to_string()).collect::<Vec<_>>().join(" "));
    println!("chart, cells kept by Hirschberg, 3 rows {}", chart.iter().map(|c| c.1.to_string()).collect::<Vec<_>>().join(" "));
    let k = 100001u64;
    println!("two play logs of 100,000 plays, 4 bytes a cell: full table {} cells, {} bytes; 3 rows {} cells, {} bytes; two genomes of 4,600,000: {} cells", k * k, 4 * k * k, 3 * k, 12 * k, 4600000u64 * 4600000);
    assert!(d[6][7] == bk.0 && bk.0 == 3 && dg[7][7] == bg.0 && bg.0 == 3, "table against every alignment");
    assert!(score(&top, &bot, unit, 1) == 3 && hirsch(x, y, unit, 1, true) == (top.clone(), bot.clone()), "traceback cost, and Hirschberg finds the same alignment");
    assert!(calls > bk.2 && bk.2 > 56, "plain recursion repeats questions");
    let paths = |a: u64, b: u64| (0..=a).map(|k| fact(a + b - k) / (fact(k) * fact(a - k) * fact(b - k))).sum::<u64>(); // k diagonal steps
    assert!(bk.2 == paths(6, 7) && bg.2 == paths(7, 7), "alignment count against the path-counting formula");
    println!("ALL CHECKS PASS");
}
