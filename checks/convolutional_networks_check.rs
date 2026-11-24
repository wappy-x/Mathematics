// Convolutional networks -- the same check as the Python, in Rust.  No crates.
// A synthetic 28 x 28 digit "7" (ink 1, paper 0, drawn by the rule below) goes
// through 8 filters of 3 x 3, each bias -1, then ReLU = max(0, value).  Roads:
// size and parameter formulas against counting; a sliding loop against the
// same layer written as a 784 x 5408 matrix; shift proofs against comparing
// every number.
type Maps = Vec<Vec<Vec<i64>>>;
const N: usize = 28; const K: usize = 3; const F: usize = 8; const B: i64 = -1;
const NAMES: [&str; 8] = ["ink below", "ink below-right", "ink right", "ink above-right",
                          "ink above", "ink above-left", "ink left", "ink below-left"];
const DIRS: [(i64, i64); 8] = [(1, 0), (1, 1), (0, 1), (-1, 1), (-1, 0), (-1, -1), (0, -1), (1, -1)];

fn filters() -> Vec<Vec<Vec<i64>>> {
    DIRS.iter().map(|&(a, b)| (-1..=1).map(|di| (-1..=1).map(|dj| (di * a + dj * b).signum()).collect()).collect()).collect()
}

fn yn(c: bool) -> &'static str { if c { "yes" } else { "no" } }

fn digit(dr: i64, dc: i64) -> Vec<Vec<i64>> {      // the 7: a top bar and a slanting stroke
    let mut x = vec![vec![0i64; N]; N];
    let mut ink: Vec<(i64, i64)> = Vec::new();
    for r in [6, 7] { for c in 7..21 { ink.push((r, c)) } }
    for r in 8..23 { for d in [0, 1] { ink.push((r, 19 - (r - 8) / 2 + d)) } }
    for (r, c) in ink {
        let (rr, cc) = (r + dr, c + dc);
        if (0..N as i64).contains(&rr) && (0..N as i64).contains(&cc) { x[rr as usize][cc as usize] = 1 }
    }
    x
}

fn conv(x0: &Vec<Vec<i64>>, w: &Maps, s: usize, flip: bool, pad: usize) -> Maps {  // road one
    let n = x0.len() + 2 * pad;
    let mut x = vec![vec![0i64; n]; n];
    for i in 0..x0.len() { for j in 0..x0.len() { x[i + pad][j + pad] = x0[i][j] } }
    let m = (n - K) / s + 1;
    (0..F).map(|f| (0..m).map(|i| (0..m).map(|j| {
        let mut t = B;
        for a in 0..K { for b in 0..K {
            let wt = if flip { w[f][K - 1 - a][K - 1 - b] } else { w[f][a][b] };
            t += wt * x[i * s + a][j * s + b];
        } }
        t.max(0)
    }).collect()).collect()).collect()
}

fn shift(y: &Maps, dr: i64, dc: i64) -> Maps {      // move every map, filling with zeros
    let m = y[0].len() as i64;
    y.iter().map(|g| (0..m).map(|i| (0..m).map(|j| {
        let (a, b) = (i - dr, j - dc);
        if a >= 0 && a < m && b >= 0 && b < m { g[a as usize][b as usize] } else { 0 }
    }).collect()).collect()).collect()
}

fn pool(y: &Maps) -> Maps {                         // max over 2 x 2 blocks, stride 2
    let m = y[0].len() / 2;
    y.iter().map(|g| (0..m).map(|i| (0..m).map(|j|
        g[2 * i][2 * j].max(g[2 * i][2 * j + 1]).max(g[2 * i + 1][2 * j]).max(g[2 * i + 1][2 * j + 1])
    ).collect()).collect()).collect()
}

fn diff(y: &Maps, z: &Maps) -> usize {             // how many numbers disagree
    y.iter().flatten().flatten().zip(z.iter().flatten().flatten()).filter(|(u, v)| u != v).count()
}

fn kept(y: &Maps, z: &Maps) -> (usize, usize) {   // active values of y that z keeps in place
    let (mut k, mut n) = (0, 0);
    for f in 0..y.len() { for i in 0..y[0].len() { for j in 0..y[0].len() {
        if y[f][i][j] != 0 { n += 1; if y[f][i][j] == z[f][i][j] { k += 1 } }
    } } }
    (k, n)
}

fn size(n: usize, k: usize, p: usize, s: usize) -> usize { (n + 2 * p - k) / s + 1 }   // the formula

fn fits(n: usize, k: usize, p: usize, s: usize) -> usize {   // count window starts that fit
    (0..n + 2 * p).filter(|i| i % s == 0 && i + k <= n + 2 * p).count()
}

fn sums(z: &Maps) -> Vec<i64> { z.iter().map(|g| g.iter().flatten().sum()).collect() }
fn active(g: &Vec<Vec<i64>>) -> usize { g.iter().flatten().filter(|&&v| v > 0).count() }
fn main() {
    let (w, x, m) = (filters(), digit(0, 0), size(N, K, 0, 1));
    let y = conv(&x, &w, 1, false, 0);
    let mut links: Vec<(usize, usize, (usize, usize, usize))> = Vec::new();   // road two:
    for f in 0..F { for i in 0..m { for j in 0..m { for a in 0..K { for b in 0..K {  // the layer
        links.push((f * m * m + i * m + j, (i + a) * N + j + b, (f, a, b)));         // as a matrix
    } } } } }
    let mut acc = vec![B; F * m * m];
    let flat: Vec<i64> = x.iter().flatten().copied().collect();
    for &(o, p, (f, a, b)) in &links { acc[o] += w[f][a][b] * flat[p] }   // scatter
    let y2: Maps = (0..F).map(|f| (0..m).map(|i| (0..m).map(|j| acc[f * m * m + i * m + j].max(0))
        .collect()).collect()).collect();
    let mut slot_list: Vec<(usize, usize, usize)> = Vec::new();
    for l in &links { if !slot_list.contains(&l.2) { slot_list.push(l.2) } }
    let (slots, dense, ink) = (slot_list.len(), N * N * F * m * m, flat.iter().sum::<i64>());
    println!("image {} x {}, ink pixels {}; {} filters of {} x {}, bias -1 each", N, N, ink, F, K, K);
    for f in 0..F { println!("filter {} {:<15} {:?}", f + 1, NAMES[f], w[f]) }
    println!("output side, formula (28 + 2*0 - 3)//1 + 1 = {}; window starts counted: {}", m, fits(N, K, 0, 1));
    println!("output numbers {} x {} x {} = {}", m, m, F, F * m * m);
    println!("parameters, formula {} x ({} + 1) = {}; slots counted in the matrix {} + biases {}", F, K * K, F * (K * K + 1), slots, F);
    println!("dense layer to the same output: {} x {} = {} weights, {} with biases", N * N, F * m * m, dense, dense + F * m * m);
    println!("matrix entries the layer can set: {} of {} ({:.2} %)", links.len(), dense, 100.0 * links.len() as f64 / dense as f64);
    println!("dense weights per conv parameter, whole part: {}", dense / (F * (K * K + 1)));
    println!("sliding loop and matrix agree on all {} outputs: {}", F * m * m, yn(y == y2));
    let pt: Vec<Vec<i64>> = (0..K).map(|a| x[5 + a][9..12].to_vec()).collect();
    let hand: i64 = (0..K).map(|a| (0..K).map(|b| w[0][a][b] * pt[a][b]).sum::<i64>()).sum();
    println!("by hand, filter 1 at row 5, col 9: patch {:?} -> {} - 1 -> {}", pt, hand, y[0][5][9]);
    println!("figure, ink pixels {}; window rows 5-7, cols 9-11; filter 1 active cells {}", ink, active(&y[0]));
    let act: Vec<usize> = y.iter().map(active).collect();
    println!("active (non-zero) values per map {:?}, total {}", act, act.iter().sum::<usize>());
    let mut equi = true;
    for (dr, dc) in [(0, 1), (1, 0), (3, -2)] {
        let ys = conv(&digit(dr, dc), &w, 1, false, 0);
        let d = diff(&ys, &shift(&y, dr, dc));
        equi = equi && d == 0;
        println!("shift ({}, {}): conv(shift x) vs shift(conv x) disagree at {} of {}; unshifted maps disagree at {}",
                 dr, dc, d, F * m * m, diff(&ys, &y));
    }
    let y1 = conv(&digit(0, 1), &w, 1, false, 0);
    println!("after shift (0, 1), filter 1 at row 5, col 10: {}", y1[0][5][10]);
    let (pp, p2) = (pool(&y), pool(&conv(&digit(0, 2), &w, 1, false, 0)));
    println!("max pool 2 x 2: {} x {} x {} = {} numbers", pp[0].len(), pp[0].len(), F, F * pp[0].len() * pp[0].len());
    let mut pb = vec![vec![vec![0i64; m / 2]; m / 2]; F];   // pooling, road two: every cell of the matrix
    for f in 0..F { for r in 0..m { for c in 0..m { pb[f][r / 2][c / 2] = pb[f][r / 2][c / 2].max(y2[f][r][c]) } } }   // road raises its block's max
    let same = |u: &Maps, v: &Maps| u.iter().flatten().flatten().zip(v.iter().flatten().flatten()).filter(|(a, b)| **a > 0 && a == b).count();
    let (mut tot, mut rc) = ([0usize; 6], [0usize; 2]);
    for d in [(0, 1), (0, -1), (1, 0), (-1, 0)] {
        let z = conv(&digit(d.0, d.1), &w, 1, false, 0);
        let ((a, b), (c, e)) = (kept(&y, &z), kept(&pp, &pool(&z)));
        rc[0] += same(&y, &z); rc[1] += same(&pb, &pool(&z));
        let g = sums(&y).iter().zip(sums(&z).iter()).filter(|(u, v)| u == v).count();
        for (t, v) in tot.iter_mut().zip([a, b, c, e, g, F]) { *t += v }
        println!("shift {:?}: raw values kept {} of {}; pooled kept {} of {}; map sums kept {} of {}", d, a, b, c, e, g, F);
    }
    let pc = |u: usize, v: usize| format!("{:.0}", 100.0 * u as f64 / v as f64);
    println!("over the four 1-pixel shifts: raw {} of {} ({} %), pooled {} of {} ({} %), map sums {} of {} ({} %)",
             tot[0], tot[1], pc(tot[0], tot[1]), tot[2], tot[3], pc(tot[2], tot[3]), tot[4], tot[5], pc(tot[4], tot[5]));
    let (pd, s32) = (diff(&p2, &shift(&pp, 0, 1)), sums(&conv(&digit(3, -2), &w, 1, false, 0)));
    println!("pooled, 2-pixel shift vs pooled map moved 1 cell: disagree at {}", pd);
    println!("map sums {:?}; after shift (3, -2) {:?}", sums(&y), s32);
    let (s2, s2s, m2) = (conv(&x, &w, 2, false, 0), conv(&digit(0, 1), &w, 2, false, 0), size(N, K, 0, 2));
    let sub: Maps = (0..F).map(|f| (0..m2).map(|i| (0..m2).map(|j| y[f][2 * i][2 * j]).collect()).collect()).collect();
    println!("stride 2: side (28 - 3)//2 + 1 = {}, counted {}; equals every 2nd stride-1 value: {}", m2, fits(N, K, 0, 2), yn(s2 == sub));
    let best = diff(&s2s, &shift(&s2, 0, 0)).min(diff(&s2s, &shift(&s2, 0, 1)));   // not still, not moved 1 cell
    println!("stride 2, 1-pixel shift: no shifted copy, disagree at {} of {}; 2-pixel shift vs moved 1 cell: {}",
             best, F * m2 * m2, diff(&conv(&digit(0, 2), &w, 2, false, 0), &shift(&s2, 0, 1)));
    let cases = [(28, 3, 0, 1), (28, 3, 1, 1), (28, 5, 0, 1), (28, 3, 0, 2), (26, 2, 0, 2), (224, 7, 3, 2)];
    let parts: Vec<String> = cases.iter().map(|&(n, k, p, s)| format!("{:?} -> {}, {}", (n, k, p, s), size(n, k, p, s), fits(n, k, p, s))).collect();
    println!("side n k p s -> formula, counted: {}", parts.join("; "));
    println!("mistake, bias forgotten: {} x {} = {} parameters, not {}", F, K * K, F * K * K, F * (K * K + 1));
    println!("mistake, side as n - k: {}, not {}; numbers {}, not {}", N - K, m, F * (N - K) * (N - K), F * m * m);
    let (yp, ye) = (conv(&x, &w, 1, false, 1), conv(&digit(0, 8), &w, 1, false, 1));
    let (edge, yf) = (diff(&ye, &shift(&yp, 0, 8)), conv(&x, &w, 1, true, 0));
    println!("breaks, padding 1 (side {}), shift (0, 8) pushes ink past the edge: disagree at {}", yp[0].len(), edge);
    println!("mistake, flipping the filter (textbook convolution): filter 1 map equals filter 5 map: {}", yn(yf[0] == y[4]));
    assert!(m == fits(N, K, 0, 1) && cases.iter().all(|&(n, k, p, s)| size(n, k, p, s) == fits(n, k, p, s)));
    assert!(slots + F == F * (K * K + 1));                      // slots counted vs formula
    assert!(y == y2);                                           // gather against scatter
    assert!(hand - 1 == y[0][5][9] && y[0][5][9] == 2);         // by hand vs the layer
    assert!(equi);                                              // shift in, shift out
    assert!(pd == 0);                                           // pooled map moves 1 cell
    assert!(sums(&y) == s32);                                   // map sums do not move
    assert!(pb == pp);                                          // pooling: gather vs scatter
    assert!(tot[..4] == [rc[0], 4 * act.iter().sum::<usize>(), rc[1], 4 * pb.iter().map(active).sum::<usize>()]);   // recount
    assert!(tot[2] * tot[1] > tot[0] * tot[3]);                 // pooling keeps a larger share
    assert!(s2 == sub);                                         // stride = subsampling
    assert!(best > 0);                                          // stride breaks 1-pixel shifts
    assert!(edge > 0);                                          // padding breaks at the edge
    println!("ALL CHECKS PASS");
}
