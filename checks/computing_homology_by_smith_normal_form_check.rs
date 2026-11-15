// Smith normal form -- the same check as the Python, in Rust.  No crates.  The
// Klein bottle's boundary matrices are reduced over the integers with row and
// column moves that can be undone, and the diagonal is read as hole counts plus
// torsion.  Roads: a 3-edge cell model by hand and a 9-corner triangulation;
// gcds of minors; ranks over Q, Z mod 2 and Z mod 3 by separate elimination.
type M = Vec<Vec<i64>>;
type H = Vec<(usize, Vec<i64>)>;

fn gcd(mut a: i64, mut b: i64) -> i64 {
    while b != 0 { (a, b) = (b, a % b) }
    a.abs()
}
fn smith(m: &M) -> Vec<i64> {                      // the diagonal d_1 | d_2 | ... (nonzero part)
    let (mut a, mut diag, mut t) = (m.clone(), Vec::new(), 0);
    let (nr, nc) = (a.len(), a[0].len());
    loop {
        let mut best: Option<(i64, usize, usize)> = None;
        for i in t..nr { for j in t..nc {
            if a[i][j] != 0 && best.map_or(true, |b| (a[i][j].abs(), i, j) < b) { best = Some((a[i][j].abs(), i, j)) }
        } }
        let Some((_, i, j)) = best else { return diag };   // smallest nonzero entry becomes the pivot
        a.swap(t, i);
        for row in a.iter_mut() { row.swap(t, j) }
        if a[t][t] < 0 { a[t] = a[t].iter().map(|x| x.checked_neg().unwrap()).collect() }
        let p = a[t][t];
        for i in t + 1..nr {                       // row moves: divide with remainder
            let q = a[i][t].div_euclid(p);
            for j in 0..nc { a[i][j] = a[i][j].checked_sub(q.checked_mul(a[t][j]).unwrap()).unwrap() }
        }
        for j in t + 1..nc {                       // column moves: the same along the row
            let q = a[t][j].div_euclid(p);
            for i in 0..nr { a[i][j] = a[i][j].checked_sub(q.checked_mul(a[i][t]).unwrap()).unwrap() }
        }
        if (t + 1..nr).any(|i| a[i][t] != 0) || (t + 1..nc).any(|j| a[t][j] != 0) { continue }
        if let Some(b) = (t + 1..nr).find(|&i| (t + 1..nc).any(|j| a[i][j] % p != 0)) {
            for j in 0..nc { a[t][j] = a[t][j].checked_add(a[b][j]).unwrap() }  // p must divide the rest: add that row, go again
            continue;
        }
        diag.push(p);
        t += 1;
    }
}
fn homology(d1: &M, d2: &M, n: [usize; 3]) -> H {  // (rank, torsion) for H0, H1, H2
    let (s1, s2) = (smith(d1), smith(d2));
    let tor = |s: &Vec<i64>| s.iter().copied().filter(|&d| d > 1).collect::<Vec<i64>>();
    vec![(n[0] - s1.len(), tor(&s1)), (n[1] - s1.len() - s2.len(), tor(&s2)), (n[2] - s2.len(), vec![])]
}
fn show(h: &H) -> String {
    h.iter().enumerate().map(|(k, (r, t))| format!("H{}: rank {}, torsion {:?}", k, r, t)).collect::<Vec<_>>().join("; ")
}
fn rank_q(m: &M) -> usize {                        // fraction-free elimination: exact rank over Q
    let (mut a, mut r, mut prev) = (m.iter().map(|row| row.iter().map(|&x| x as i128).collect::<Vec<i128>>()).collect::<Vec<_>>(), 0, 1i128);
    for c in 0..a[0].len() {
        let Some(piv) = (r..a.len()).find(|&i| a[i][c] != 0) else { continue };
        a.swap(r, piv);
        for i in r + 1..a.len() {
            for j in c + 1..a[0].len() {
                let num = a[i][j] * a[r][c] - a[i][c] * a[r][j];
                assert!(num % prev == 0);
                a[i][j] = num / prev;
            }
            a[i][c] = 0;
        }
        (prev, r) = (a[r][c], r + 1);
    }
    r
}
fn rank_p(m: &M, p: i64) -> usize {                // rank over Z mod p, p prime
    let (mut a, mut r) = (m.iter().map(|row| row.iter().map(|x| x.rem_euclid(p)).collect::<Vec<i64>>()).collect::<Vec<_>>(), 0);
    for c in 0..a[0].len() {
        let Some(piv) = (r..a.len()).find(|&i| a[i][c] != 0) else { continue };
        a.swap(r, piv);
        let mut inv = 1;
        for _ in 0..p - 2 { inv = inv * a[r][c] % p }
        for i in 0..a.len() {
            if i != r && a[i][c] != 0 {
                let f = a[i][c] * inv % p;
                for j in 0..a[0].len() { a[i][j] = (a[i][j] - f * a[r][j]).rem_euclid(p) }
            }
        }
        r += 1;
    }
    r
}
fn betti_field(d1: &M, d2: &M, rank: &dyn Fn(&M) -> usize) -> Vec<usize> {
    let (r1, r2) = (rank(d1), rank(d2));           // Betti numbers over a field, from two ranks
    vec![9 - r1, 27 - r1 - r2, 18 - r2]
}
fn grid(flip: bool) -> (Vec<[usize; 3]>, Vec<[usize; 2]>, M, M) {  // 3 x 3 squares, each cut by one diagonal
    let v = |i: usize, j: usize| { let j = j % 3; if i == 3 { if flip { (3 - j) % 3 } else { j } } else { 3 * i + j } };
    let mut tris: Vec<[usize; 3]> = Vec::new();
    for i in 0..3 { for j in 0..3 {
        for mut t in [[v(i, j), v(i + 1, j), v(i + 1, j + 1)], [v(i, j), v(i, j + 1), v(i + 1, j + 1)]] {
            t.sort();
            if !tris.contains(&t) { tris.push(t) }
        }
    } }
    tris.sort();
    assert!(tris.len() == 18);                     // no two triangles share their corners
    let mut edges: Vec<[usize; 2]> = Vec::new();
    for &[x, y, z] in &tris { for e in [[x, y], [x, z], [y, z]] { if !edges.contains(&e) { edges.push(e) } } }
    edges.sort();
    let d1 = (0..9).map(|k| edges.iter().map(|&[x, y]| (k == y) as i64 - (k == x) as i64).collect()).collect();
    let d2 = edges.iter().map(|&e| tris.iter().map(|&[x, y, z]|
        (e == [y, z]) as i64 - (e == [x, z]) as i64 + (e == [x, y]) as i64).collect()).collect();
    (tris, edges, d1, d2)
}
fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }
fn main() {
    let (cell, none): (M, M) = (vec![vec![1, 1], vec![1, -1], vec![-1, -1]], vec![vec![0, 0, 0]]);  // rows a, b, c; columns U, L
    println!("figure, corners P0 (60,360) P1 (360,360) P2 (360,60) P3 (60,60); diagonal c (60,360) to (360,60)");
    println!("cell Klein bottle: 1 corner, 3 edges a b c, 2 triangles U L; d2 = {:?}", cell);
    let s1: M = vec![cell[0].clone(), (0..2).map(|j| cell[1][j] - cell[0][j]).collect(), (0..2).map(|j| cell[2][j] + cell[0][j]).collect()];
    let s2: M = s1.iter().map(|r| vec![r[0], r[1] - r[0]]).collect();
    let s3: M = vec![s2[0].clone(), s2[1].iter().map(|x| -x).collect(), s2[2].clone()];
    println!("step 1, clear column U: row b - row a, row c + row a -> {:?}", s1);
    println!("step 2, clear row a: column L - column U -> {:?}", s2);
    println!("step 3, row b times -1 -> {:?}", s3);
    let mins: Vec<i64> = (0..3).flat_map(|i| (i + 1..3).map(move |j| (i, j)))
        .map(|(i, j)| cell[i][0] * cell[j][1] - cell[i][1] * cell[j][0]).collect();
    let (g1, g2) = (cell.iter().flatten().fold(0, |g, &x| gcd(g, x)), mins.iter().fold(0, |g, &x| gcd(g, x)));
    println!("Smith diagonal, cell Klein: {:?}; of [[2, 0], [0, 3]]: {:?}; of [[4, 6]]: {:?}", smith(&cell), smith(&vec![vec![2, 0], vec![0, 3]]), smith(&vec![vec![4, 6]]));
    println!("gcd road: entries {}, 2x2 minors {:?} -> {}, so d_2 = {}", g1, mins, g2, g2 / g1);
    println!("boundary of U - L, in a b c: {:?}; of U + L: {:?}", cell.iter().map(|r| r[0] - r[1]).collect::<Vec<i64>>(), cell.iter().map(|r| r[0] + r[1]).collect::<Vec<i64>>());
    let cell_h = homology(&none, &cell, [1, 3, 2]);
    println!("cell Klein: {}", show(&cell_h));
    let mut results: Vec<(M, M, H)> = Vec::new();
    for (name, flip) in [("Klein", true), ("torus", false)] {
        let (tris, edges, d1, d2) = grid(flip);
        let on_two = edges.iter().all(|e| tris.iter().filter(|t| t.contains(&e[0]) && t.contains(&e[1])).count() == 2);
        let zero = (0..9).all(|k| (0..18).all(|t| (0..27).map(|e| d1[k][e] * d2[e][t]).sum::<i64>() == 0));
        let (sd1, sd2, h) = (smith(&d1), smith(&d2), homology(&d1, &d2, [9, edges.len(), tris.len()]));
        let ones = |s: &Vec<i64>| s.iter().filter(|&&d| d == 1).count();
        let big = |s: &Vec<i64>| s.iter().copied().filter(|&d| d > 1).collect::<Vec<i64>>();
        println!("grid {}: {} corners, {} edges, {} triangles; each edge on 2 triangles: {}; d1 d2 = 0: {}",
                 name, 9, edges.len(), tris.len(), yn(on_two), yn(zero));
        println!("grid {}: Smith d1 has {} ones, others {:?}; Smith d2 has {} ones, others {:?}",
                 name, ones(&sd1), big(&sd1), ones(&sd2), big(&sd2));
        println!("grid {}: {}", name, show(&h));
        results.push((d1, d2, h));
    }
    let (d1, d2, kh) = &results[0];
    let bq = betti_field(d1, d2, &rank_q);
    println!("Euler characteristic: 9 - 27 + 18 = {}; Betti over Q {} - {} + {} = {}",
             9 - 27 + 18, bq[0], bq[1], bq[2], bq[0] as i64 - bq[1] as i64 + bq[2] as i64);
    println!("Klein over Q, fraction-free elimination: {:?}", bq);
    let mut rule2 = Vec::new();
    for p in [2i64, 3] {
        let direct = betti_field(d1, d2, &|m: &M| rank_p(m, p));
        let t: Vec<usize> = kh.iter().map(|(_, tor)| tor.iter().filter(|&&d| d % p == 0).count()).collect();
        let rule: Vec<usize> = (0..3).map(|k| kh[k].0 + t[k] + if k > 0 { t[k - 1] } else { 0 }).collect();
        println!("Klein over Z mod {}: elimination {:?}, counting rule from Smith {:?}", p, direct, rule);
        assert!(direct == rule);
        if p == 2 { rule2 = rule }
    }
    let (tq, t2) = (betti_field(&results[1].0, &results[1].1, &rank_q), betti_field(&results[1].0, &results[1].1, &|m: &M| rank_p(m, 2)));
    println!("torus over Q {:?}, over Z mod 2 {:?}", tq, t2);
    let unsigned: M = cell.iter().map(|r| r.iter().map(|x| x.abs()).collect()).collect();
    println!("mistake 1, signs dropped: d2 = {:?}, Smith {:?} -> {}", unsigned, smith(&unsigned), show(&homology(&none, &unsigned, [1, 3, 2])));
    println!("mistake 2, ranks over Q only: H1 rank {}, torsion seen: none", bq[1]);
    println!("mistake 3, mod 2 count read as free loops: {} loops, the torus's count", rule2[1]);
    println!("mistake 4, rank of d1 forgotten: 27 - {} = {} loops", rank_q(d2), 27 - rank_q(d2));
    assert!(smith(&cell) == vec![1, 2] && g2 / g1 == 2 && s3 == vec![vec![1, 0], vec![0, 2], vec![0, 0]]);
    assert!(smith(&vec![vec![2, 0], vec![0, 3]]) == vec![1, 2 * 3] && smith(&vec![vec![4, 6]]) == vec![gcd(4, 6)]);
    let want: H = vec![(1, vec![]), (1, vec![2]), (0, vec![])];
    assert!(cell_h == want && *kh == want);                  // cell model meets triangulation
    assert!(*bq == [kh[0].0, kh[1].0, kh[2].0] && bq == vec![1, 1, 0]);  // Q ranks meet Smith ranks
    assert!(results[1].2 == vec![(1, vec![]), (2, vec![]), (1, vec![])] && tq == t2 && tq == vec![1, 2, 1]);
    println!("ALL CHECKS PASS");
}
