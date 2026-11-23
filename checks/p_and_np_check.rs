// P and NP -- the check behind the card, in Rust with std only.  The same
// 4 by 4 sudoku (side k = 4, 16 cells of 3 bits, n = 48 bits; 0 = blank) and the same
// three roads: blind search over every filling, a backtracking solver, and
// the list of all valid grids built from row orderings.
const K: usize = 4;
const PUZZLE: [usize; 16] = [1, 0, 3, 0, 0, 4, 1, 0, 2, 0, 0, 3, 0, 3, 0, 1];
const BROKEN: [usize; 16] = [1, 0, 3, 0, 0, 4, 1, 0, 2, 0, 0, 3, 0, 3, 0, 2]; // last given 1 -> 2
type Grid = [usize; 16];

fn groups() -> (Vec<Vec<usize>>, Vec<Vec<usize>>) {
    let rows: Vec<Vec<usize>> = (0..4).map(|r| (0..4).map(|c| r * 4 + c).collect()).collect();
    let mut all = rows.clone();
    for c in 0..4 { all.push((0..4).map(|r| r * 4 + c).collect()); }
    for br in [0, 2] { for bc in [0, 2] {
        all.push((0..4).map(|t| (br + t / 2) * 4 + bc + t % 2).collect());
    } }
    (rows, all)
}

/// V(x, c): true when grid c fills puzzle x legally, with the cell reads spent.
fn verify(x: &Grid, c: &Grid, gs: &[Vec<usize>], use_givens: bool) -> (bool, u64) {
    let (mut ok, mut reads) = (true, 0u64);
    for i in 0..16 {
        reads += 1;
        if use_givens && x[i] != 0 && c[i] != x[i] { ok = false; }
    }
    for g in gs {
        let mut seen = [false; K + 1];
        for &i in g {
            reads += 1;
            let v = c[i];
            if v < 1 || v > K || seen[v] { ok = false; } else { seen[v] = true; }
        }
    }
    (ok, reads)
}

/// Deterministic run of the guessing machine: try every filling of the blanks.
fn blind_search(x: &Grid, gs: &[Vec<usize>]) -> (Vec<Grid>, u64, u64, usize) {
    let blanks: Vec<usize> = (0..16).filter(|&i| x[i] == 0).collect();
    let (mut found, mut tried, mut reads) = (Vec::new(), 0u64, 0u64);
    for code0 in 0..K.pow(blanks.len() as u32) {
        let (mut c, mut code) = (*x, code0);
        for &b in &blanks { c[b] = code % K + 1; code /= K; }
        let (ok, r) = verify(x, &c, gs, true);
        tried += 1; reads += r;
        if ok { found.push(c); }
    }
    (found, tried, reads, blanks.len())
}

/// A second road: fill blanks in order, never placing a clashing digit.
fn go(g: &mut Grid, i: usize, nodes: &mut u64, gs: &[Vec<usize>]) -> bool {
    if i == 16 { return true; }
    if g[i] != 0 { return go(g, i + 1, nodes, gs); }
    for v in 1..=K {
        *nodes += 1;
        let fits = gs.iter().filter(|grp| grp.contains(&i)).all(|grp| grp.iter().all(|&j| g[j] != v));
        if fits {
            g[i] = v;
            if go(g, i + 1, nodes, gs) { return true; }
            g[i] = 0;
        }
    }
    false
}
fn backtrack(x: &Grid, gs: &[Vec<usize>]) -> (Option<Grid>, u64) {
    let (mut g, mut nodes) = (*x, 0u64);
    let ok = go(&mut g, 0, &mut nodes, gs);
    (if ok { Some(g) } else { None }, nodes)
}

fn orderings(items: &[usize]) -> Vec<Vec<usize>> {
    if items.len() <= 1 { return vec![items.to_vec()]; }
    let mut out = Vec::new();
    for i in 0..items.len() {
        let mut rest = items.to_vec();
        let head = rest.remove(i);
        for mut r in orderings(&rest) { r.insert(0, head); out.push(r); }
    }
    out
}

/// A third road: every grid whose rows are orderings of 1..4, kept if valid.
fn all_valid_grids(gs: &[Vec<usize>]) -> Vec<Grid> {
    let rows = orderings(&[1, 2, 3, 4]);
    let mut grids = Vec::new();
    for a in &rows { for b in &rows { for c in &rows { for d in &rows {
        let mut g = [0usize; 16];
        for t in 0..4 { g[t] = a[t]; g[4 + t] = b[t]; g[8 + t] = c[t]; g[12 + t] = d[t]; }
        if verify(&[0; 16], &g, gs, true).0 { grids.push(g); }
    } } } }
    grids
}

fn show(g: &Grid) -> String {
    (0..4).map(|r| g[r * 4..r * 4 + 4].iter().map(|&v| if v == 0 { ".".to_string() } else { v.to_string() }).collect::<String>())
        .collect::<Vec<_>>().join(" / ")
}
fn agrees(x: &Grid, g: &Grid) -> bool { (0..16).all(|i| x[i] == 0 || x[i] == g[i]) }

fn main() {
    let (rows, gs) = groups();
    let bits = |v: usize| format!("{:b}", v).len(); // bits per cell, as on Time and space classes
    println!("puzzle {} | givens {} | n = {} bits: 16 cells x {} bits", show(&PUZZLE), PUZZLE.iter().filter(|&&v| v != 0).count(), 16 * bits(K), bits(K));
    let (found, tried, reads, b) = blind_search(&PUZZLE, &gs);
    let (sol, nodes) = backtrack(&PUZZLE, &gs);
    let sol = sol.expect("puzzle has a completion");
    let valid = all_valid_grids(&gs);
    let matches: Vec<Grid> = valid.iter().filter(|g| agrees(&PUZZLE, g)).cloned().collect();
    println!("blanks {} | fillings tried {} | completions found {}", b, tried, found.len());
    println!("solution {}", show(&found[0]));
    println!("verifier reads per grid {}", verify(&PUZZLE, &found[0], &gs, true).1);
    println!("blind search total reads {}", reads);
    println!("guessing machine: branches {} | guesses + reads per branch {}", K.pow(b as u32), b + 64);
    println!("backtracking placements tried {}", nodes);
    println!("valid 4 by 4 grids {} | agreeing with the givens {}", valid.len(), matches.len());
    let gives: Vec<usize> = [PUZZLE, BROKEN].iter().map(|x| valid.iter().filter(|g| verify(x, g, &gs, true).0).count()).collect(); // the givens pass at work
    println!("verifier over all {} grids: accepts {} for the puzzle, {} for the no-instance", valid.len(), gives[0], gives[1]);
    let mut swapped = sol; swapped.swap(1, 2);
    println!("verifier on solution {} | with two cells swapped {}",
        verify(&PUZZLE, &sol, &gs, true).0 as u8, verify(&PUZZLE, &swapped, &gs, true).0 as u8);
    assert!(found.len() == 1 && sol == found[0]); // road 1 = road 2
    assert!(matches == vec![sol]); // road 3 agrees
    assert_eq!(valid.len(), 288); // known count of 4 by 4 grids
    assert!(verify(&PUZZLE, &sol, &gs, true).0 && !verify(&PUZZLE, &swapped, &gs, true).0);
    assert_eq!(reads, tried * 4 * (K * K) as u64); // 4k^2 reads per grid
    // What breaks
    let (rows_only, _, _, _) = blind_search(&PUZZLE, &rows);
    let loose = valid.iter().filter(|g| verify(&PUZZLE, g, &gs, false).0).count();
    let (bfound, btried, _, _) = blind_search(&BROKEN, &gs);
    let (bsol, bnodes) = backtrack(&BROKEN, &gs);
    let bmatch = valid.iter().filter(|g| agrees(&BROKEN, g)).count();
    let row_choices: usize = rows.iter().map(|r| (1..=r.iter().filter(|&&i| PUZZLE[i] == 0).count()).product::<usize>()).product();
    println!("broken: rows-only verifier accepts {} | row choices multiplied {}", rows_only.len(), row_choices);
    println!("broken: verifier ignoring givens accepts {}", loose);
    println!("no-instance {} | completions {} | backtracking placements {}", show(&BROKEN), bfound.len(), bnodes);
    println!("no-instance: listing every failed filling takes {} digits, the puzzle has 16", btried * 16);
    assert!(rows_only.len() == row_choices && loose == 288);
    assert!(bfound.is_empty() && bsol.is_none() && bmatch == 0);
    assert!(gives == vec![matches.len(), bmatch]); // the givens pass, against the agree filter
    // Scale: verifier reads 4k^2 against blind fillings of an empty grid, k^(k^2)
    for k in [4usize, 9, 16, 25] {
        let lg = (k * k) as f64 * (k as f64).log10();
        println!("scale k={} cells={} n={} groups={} verifier reads={} log10 reads={:.2} log10 blind fillings={:.2}",
            k, k * k, k * k * bits(k), 3 * k, 4 * k * k, ((4 * k * k) as f64).log10(), lg);
    }
    let lg17 = 64.0 * 9f64.log10();
    let mant = 10f64.powf(lg17 - lg17.floor());
    println!("9 by 9 with 17 givens: 64 blanks, 9^64 = {:.2} x 10^{}", mant, lg17.floor());
    // exact 9^64 in decimal digits (least significant first), against the log road
    let mut digits = vec![1u32];
    for _ in 0..64 {
        let mut carry = 0;
        for d in digits.iter_mut() { let t = *d * 9 + carry; *d = t % 10; carry = t / 10; }
        while carry > 0 { digits.push(carry % 10); carry /= 10; }
    }
    let n = digits.len();
    let lead = digits[n - 1] * 1000 + digits[n - 2] * 100 + digits[n - 3] * 10 + digits[n - 4];
    assert!(n == lg17.floor() as usize + 1 && format!("{:.2}", lead as f64 / 1000.0) == format!("{:.2}", mant));
    println!("ALL CHECKS PASS");
}
