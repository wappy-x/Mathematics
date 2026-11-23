// Counting solutions and #P -- the same check as the Python, in Rust.  No crates.  A floor
// 4 squares by 6 takes 1 x 2 dominoes; deciding needs one tiling, counting needs all.
const ROWS: usize = 4;
const COLS: usize = 6;
type Domino = (usize, usize, usize, usize);

fn go(i: usize, rows: usize, cols: usize, full: &mut Vec<Vec<bool>>, seen: &mut [u64; 2]) {
    seen[1] += 1;
    let mut i = i;
    while i < rows * cols && full[i % rows][i / rows] { i += 1 }   // read down each column
    if i == rows * cols { seen[0] += 1; return }
    let (r, c) = (i % rows, i / rows);
    for (dr, dc) in [(1, 0), (0, 1)] {                              // upright, then flat
        if r + dr < rows && c + dc < cols && !full[r + dr][c + dc] {
            full[r][c] = true; full[r + dr][c + dc] = true;
            go(i + 1, rows, cols, full, seen);
            full[r][c] = false; full[r + dr][c + dc] = false;
        }
    }
}

fn search(rows: usize, cols: usize) -> (u64, u64) {    // road one: list every tiling
    let (mut full, mut seen) = (vec![vec![false; cols]; rows], [0u64; 2]);
    go(0, rows, cols, &mut full, &mut seen);
    (seen[0], seen[1])
}

fn moves(mask: usize, r: usize, nxt: usize, rows: usize, out: &mut Vec<usize>) {
    if r == rows { out.push(nxt) }
    else if mask >> r & 1 == 1 { moves(mask, r + 1, nxt, rows, out) }
    else {
        moves(mask, r + 1, nxt | 1 << r, rows, out);              // flat: pokes into the next column
        if r + 1 < rows && mask >> (r + 1) & 1 == 0 { moves(mask, r + 2, nxt, rows, out) } // upright
    }
}

fn transfer(rows: usize, cols: usize) -> (u64, u64) {  // road two: 2^rows column states
    let mut v: Vec<u64> = (0..1usize << rows).map(|m| (m == 0) as u64).collect();
    for _ in 0..cols {
        let mut w = vec![0u64; 1 << rows];
        for mask in 0..(1 << rows) {
            let mut out = Vec::new();
            moves(mask, 0, 0, rows, &mut out);
            for nxt in out { w[nxt] += v[mask] }
        }
        v = w;
    }
    (v[0], v.iter().sum())
}

fn det(mut a: Vec<Vec<i128>>) -> i128 {                // exact, fraction-free (Bareiss)
    let n = a.len();
    let (mut sign, mut prev) = (1i128, 1i128);
    for k in 0..n - 1 {
        if a[k][k] == 0 {
            let Some(s) = (k + 1..n).find(|&i| a[i][k] != 0) else { return 0 };
            a.swap(k, s);
            sign = -sign;
        }
        for i in k + 1..n { for j in k + 1..n { a[i][j] = (a[i][j] * a[k][k] - a[i][k] * a[k][j]) / prev } }
        prev = a[k][k];
    }
    sign * a[n - 1][n - 1]
}

fn squares(rows: usize, cols: usize, colour: usize) -> Vec<(usize, usize)> {
    (0..cols).flat_map(|c| (0..rows).map(move |r| (r, c))).filter(|&(r, c)| (r + c) % 2 == colour).collect()
}

fn kasteleyn(rows: usize, cols: usize, signed: bool) -> i128 {   // road three
    let (dark, light) = (squares(rows, cols, 0), squares(rows, cols, 1));
    let mut k = vec![vec![0i128; light.len()]; dark.len()];
    for (i, &(r, c)) in dark.iter().enumerate() {
        for (j, &(s, d)) in light.iter().enumerate() {
            if r.abs_diff(s) + c.abs_diff(d) == 1 {
                k[i][j] = if signed && r != s && c % 2 == 1 { -1 } else { 1 };
            }
        }
    }
    det(k).abs()
}

fn product(rows: usize, cols: usize) -> f64 {          // road four: the closed product
    let pi = std::f64::consts::PI;
    let mut p = 1.0f64;
    for j in 1..=rows / 2 { for k in 1..=cols / 2 {
        p *= 4.0 * (pi * j as f64 / (rows + 1) as f64).cos().powi(2) + 4.0 * (pi * k as f64 / (cols + 1) as f64).cos().powi(2);
    } }
    p
}

fn augment(u: (usize, usize), rows: usize, cols: usize, used: &mut Vec<bool>,
           partner: &mut Vec<Option<(usize, usize)>>, looks: &mut u64) -> bool {
    let (r, c) = (u.0 as i64, u.1 as i64);
    for (a, b) in [(r + 1, c), (r - 1, c), (r, c + 1), (r, c - 1)] {
        if a < 0 || b < 0 || a >= rows as i64 || b >= cols as i64 { continue }
        *looks += 1;
        let v = a as usize * cols + b as usize;          // partner[light square] = its dark square
        if !used[v] {
            used[v] = true;
            if partner[v].map_or(true, |w| augment(w, rows, cols, used, partner, looks)) {
                partner[v] = Some(u);
                return true;
            }
        }
    }
    false
}

fn matching(rows: usize, cols: usize) -> (usize, u64) { // deciding, by augmenting paths
    let (mut looks, mut partner) = (0u64, vec![None; rows * cols]);
    let paired = squares(rows, cols, 0).iter().filter(|&&u| augment(u, rows, cols, &mut vec![false; rows * cols], &mut partner, &mut looks)).count();
    (paired, looks)
}

fn verify(rows: usize, cols: usize, t: &[Domino]) -> bool {     // the checker V
    let mut cells: Vec<(usize, usize)> = t.iter().map(|d| (d.0, d.1)).collect();
    cells.extend(t.iter().map(|d| (d.2, d.3)));
    let (n, mut uniq) = (cells.len(), cells.clone());
    uniq.sort();
    uniq.dedup();
    t.iter().all(|d| d.0.abs_diff(d.2) + d.1.abs_diff(d.3) == 1) && uniq.len() == n
        && n == rows * cols && cells.iter().all(|&(r, c)| r < rows && c < cols)
}

fn adder(a1: u8, a0: u8, b1: u8, b0: u8) -> u8 {       // the two-bit adder from the circuits card, gate by gate
    let xor = |x: u8, y: u8| (x | y) & (1 - (x & y));    // AND, OR and NOT only: (x OR y) AND NOT (x AND y)
    let (t, c0) = (xor(a1, b1), a0 & b0);                // t = a1 XOR b1; c0 = the carry out of bit 0
    4 * ((a1 & b1) | (t & c0)) + 2 * xor(t, c0) + xor(a0, b0)
}
fn yn(claim: bool) -> &'static str { if claim { "yes" } else { "no" } }

fn main() {
    let ((found, tried), (closed, poked)) = (search(ROWS, COLS), transfer(ROWS, COLS));
    let (signed, unsigned) = (kasteleyn(ROWS, COLS, true), kasteleyn(ROWS, COLS, false));
    let (prod, (paired, looks), strip) = (product(ROWS, COLS), matching(ROWS, COLS), transfer(2, COLS).0);
    let flat: Vec<Domino> = (0..4).flat_map(|r| [0, 2, 4].map(|c| (r, c, r, c + 1))).collect();
    let brick: Vec<Domino> = [0, 2, 4].iter().flat_map(|&c|
        [(0, c, 0, c + 1), (1, c, 2, c), (1, c + 1, 2, c + 1), (3, c, 3, c + 1)]).collect();
    let moved: Vec<Domino> = [(1, 0, 1, 1)].into_iter().chain(brick[1..].iter().copied()).collect();
    let by_gates: Vec<usize> = (0..7u8).map(|s| (0..16u8).filter(|x| adder(x >> 3 & 1, x >> 2 & 1, x >> 1 & 1, x & 1) == s).count()).collect();
    let by_sums: Vec<usize> = (0..7).map(|s| (0..4).flat_map(|a| (0..4).map(move |b| a + b)).filter(|&t| t == s).count()).collect();
    println!("floor {} by {}: {} squares, {} dominoes", ROWS, COLS, ROWS * COLS, ROWS * COLS / 2);
    println!("decide: augmenting paths pair {} of {} dark squares after {} looks", paired, ROWS * COLS / 2, looks);
    println!("count, road 1, every tiling listed: {} tilings, {} squares tried", found, tried);
    println!("count, road 2, column states stepped: {}", closed);
    println!("count, road 3, signed determinant: {}", signed);
    println!("count, road 4, product of cosines: {:.6}", prod);
    println!("growth 4 by m: m, tilings, squares tried by listing, looks to decide");
    for m in [2, 4, 6, 8, 10] { println!("  {}, {}, {}, {}", m, transfer(4, m).0, search(4, m).1, matching(4, m).1) }
    println!("square floors: side, tilings by column states, by signed determinant");
    for s in [2, 4, 6, 8] { println!("  {}, {}, {}", s, transfer(s, s).0, kasteleyn(s, s, true)) }
    println!("checker V accepts all-flat: {}; brick: {}; brick less one domino: {}; one moved: {}",
             yn(verify(4, 6, &flat)), yn(verify(4, 6, &brick)), yn(verify(4, 6, &brick[1..])), yn(verify(4, 6, &moved)));
    for (name, t) in [("all-flat", &flat), ("brick", &brick)] {
        let parts: Vec<String> = t.iter().map(|d| format!("{} {} {} {}", d.0, d.1, d.2, d.3)).collect();
        println!("figure, {}: {}", name, parts.join("; "));
    }
    println!("two-bit adder, inputs giving sum 3: {} by the gates, {} by a + b = 3", by_gates[3], by_sums[3]);
    println!("mistake 1, each domino flat or upright freely: 2^12 = {}", 1u64 << 12);
    println!("mistake 2, two 2 by 6 strips: {} x {} = {}, missing {}", strip, strip, strip * strip, closed - strip * strip);
    println!("mistake 3, determinant with no signs: {}", unsigned);
    println!("mistake 4, dominoes left poking out of the far wall: {}", poked);
    assert!(found == closed && closed as i128 == signed && signed == 281);  // three exact roads
    assert!((prod - found as f64).abs() < 1e-6);                            // the closed product
    assert!(paired == ROWS * COLS / 2 && by_gates == by_sums && by_gates[3] == 4); // a tiling; the adder
    assert!(transfer(8, 8).0 as i128 == kasteleyn(8, 8, true) && kasteleyn(8, 8, true) == 12988816);
    assert!(verify(4, 6, &flat) && verify(4, 6, &brick) && !verify(4, 6, &brick[1..]) && !verify(4, 6, &moved));
    println!("ALL CHECKS PASS");
}
