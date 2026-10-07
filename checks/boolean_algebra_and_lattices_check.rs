// Boolean algebra -- the same check as the Python, in Rust.  No crates.  A porch
// light is on when (motion AND dark) OR override.  Road one evaluates that rule row by
// row; road two closes ideal switches and hunts for a live path.  The eight subsets of
// {a, b, c} are then ordered by inclusion, and meet and join are found twice: by
// searching the order, and by set algebra on three-bit masks.
fn rule(m: u32, d: u32, o: u32) -> bool { (m == 1 && d == 1) || o == 1 }
fn off_rule(m: u32, d: u32, o: u32) -> bool { (m == 0 || d == 0) && o == 0 }
fn sub(a: u32, b: u32) -> bool { a & b == a }        // a is a subset of b
fn name(k: u32) -> String { (0..3).filter(|i| k >> i & 1 == 1).map(|i| (b'a' + i as u8) as char).collect() }

fn switches(m: u32, d: u32, o: u32) -> bool {        // road two: parallel pairs in series
    let wires = [(0usize, 1usize, m), (0, 1, o), (1, 2, d), (1, 2, o)];
    let mut live = [true, false, false];             // 0 the live rail, 2 the lamp
    for _ in 0..wires.len() {                        // spread current along closed wires
        for &(a, b, closed) in wires.iter() { if closed == 1 && live[a] { live[b] = true; } }
    }
    live[2]
}

fn extreme(cands: &[u32], upper: bool) -> u32 {   // the one all the others sit below, or above
    let hits: Vec<u32> = cands.iter().cloned()
        .filter(|&s| cands.iter().all(|&t| if upper { sub(t, s) } else { sub(s, t) })).collect();
    if hits.len() == 1 { hits[0] } else { 99 }
}

fn main() {
    let mut rows: Vec<(u32, u32, u32)> = Vec::new();
    for m in 0..2 { for d in 0..2 { for o in 0..2 { rows.push((m, d, o)); } } }
    let show = |k: u32| -> String { (0..rows.len()).filter(|i| k >> i & 1 == 1)
        .map(|i| format!("{}{}{}", rows[i].0, rows[i].1, rows[i].2)).collect::<Vec<String>>().join(", ") };
    let bits = |f: &[bool]| -> u32 { let mut b = 0; for i in 0..f.len() { if f[i] { b |= 1 << i; } } b };
    let on: Vec<bool> = rows.iter().map(|&(m, d, o)| rule(m, d, o)).collect();
    let net: Vec<bool> = rows.iter().map(|&(m, d, o)| switches(m, d, o)).collect();
    let off: Vec<bool> = rows.iter().map(|&(m, d, o)| off_rule(m, d, o)).collect();
    for i in 0..rows.len() { println!("MDO={}{}{}: rule={} switches={} off={}", rows[i].0,
        rows[i].1, rows[i].2, on[i] as u8, net[i] as u8, off[i] as u8); }
    let (n_on, n_off) = (on.iter().filter(|&&v| v).count(), off.iter().filter(|&&v| v).count());
    println!("light on in {} of the {} rows, off in {}", n_on, rows.len(), n_off);
    let cols: Vec<Vec<bool>> = (0..3).map(|k| rows.iter().map(|&(m, d, o)| [m, d, o][k] == 1).collect()).collect();
    let (mm, md, mo) = (bits(&cols[0]), bits(&cols[1]), bits(&cols[2]));
    let (on_set, off_set) = ((mm & md) | mo, ((255 ^ mm) | (255 ^ md)) & (255 ^ mo));
    println!("on rows from set algebra: {}; off rows from its complement: {}", show(on_set), show(off_set));
    let subsets: Vec<u32> = (0..8).collect();
    let lows = |a: u32, b: u32| -> Vec<u32> { subsets.iter().cloned().filter(|&s| sub(s, a) && sub(s, b)).collect() };
    let ups = |a: u32, b: u32| -> Vec<u32> { subsets.iter().cloned().filter(|&s| sub(a, s) && sub(b, s)).collect() };
    let (mut meets_ok, mut joins_ok, mut all_pairs) = (true, true, 0);
    for &a in &subsets { for &b in &subsets {
        all_pairs += 1;
        if extreme(&lows(a, b), true) != (a & b) { meets_ok = false; }
        if extreme(&ups(a, b), false) != (a | b) { joins_ok = false; }
    } }
    let mut edges = 0;
    for &a in &subsets { for &b in &subsets { if a != b && sub(a, b) && (b ^ a).count_ones() == 1 { edges += 1; } } }
    let (mut comp, mut incomp, mut pairs) = (0, 0, 0);
    for i in 0..8 { for j in (i + 1)..8 {
        pairs += 1;
        if sub(subsets[i], subsets[j]) || sub(subsets[j], subsets[i]) { comp += 1 } else { incomp += 1 }
    } }
    println!("subset cube of {{a, b, c}}: {} vertices, {} upward edges; meet and join agree on all {} pairs",
             subsets.len(), edges, all_pairs);
    println!("order: {} of the {} pairs are comparable, {} are not", comp, pairs, incomp);
    let (a, b) = (3u32, 6u32);                       // {a, b} and {b, c}
    println!("A=ab, B=bc: meet by search={}, by intersection={}; join by search={}, by union={}",
             name(extreme(&lows(a, b), true)), name(a & b), name(extreme(&ups(a, b), false)), name(a | b));
    println!("complement in U=abc: of A=ab it is {}, of the empty set it is {}", name(7 ^ a), name(7 ^ 0));
    let xor_bad: Vec<bool> = rows.iter().enumerate().map(|(i, &(m, d, o))| (((m & d) ^ o) == 1) != on[i]).collect();
    let neg_bad: Vec<bool> = rows.iter().enumerate().map(|(i, &(m, d, o))| ((m == 0 && d == 0) && o == 0) != off[i]).collect();
    let half_bad: Vec<bool> = rows.iter().enumerate().map(|(i, &(m, d, o))| ((m == 1 || o == 1) && d == 1) != on[i]).collect();
    let cnt = |f: &[bool]| f.iter().filter(|&&x| x).count();
    println!("exclusive-or instead of OR: fails {} of 8 rows, at MDO={}", cnt(&xor_bad), show(bits(&xor_bad)));
    println!("NOT(M AND D) as (NOT M) AND (NOT D): fails {} of 8 rows, at MDO={}", cnt(&neg_bad), show(bits(&neg_bad)));
    println!("override dropped from the second bracket: fails {} of 8 rows, at MDO={}", cnt(&half_bad), show(bits(&half_bad)));
    assert!(net == on && off == on.iter().map(|&v| !v).collect::<Vec<bool>>());
    assert!(on_set == bits(&on) && off_set == 255 ^ on_set);
    assert!(meets_ok && joins_ok && edges == 3 * 2i32.pow(2));
    assert!(comp == 3i32.pow(3) - 2i32.pow(3) && incomp == (4i32.pow(3) - 2 * 3i32.pow(3) + 2i32.pow(3)) / 2 && [cnt(&xor_bad), cnt(&neg_bad), cnt(&half_bad)] == [1, 2, 2]);
    println!("ALL CHECKS PASS");
}
