// Permanent against determinant -- the same check as the Python, in Rust.  No
// crates.  Eight leads face eight follows in a rotating class; lead i has danced
// with follows i, i+1 and i+2 (wrapping).  The permanent counts the ways to pair
// everyone with a practised partner: three roads (every pairing, Ryser's
// inclusion-exclusion, a backtracking search).  The determinant takes two roads
// (every pairing signed, fraction-free elimination).
type M = Vec<Vec<i128>>;
const F: [char; 8] = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];

fn dance(n: usize) -> M {
    (0..n).map(|i| (0..n).map(|j| if (j + n - i) % n <= 2 { 1 } else { 0 }).collect()).collect()
}

fn perms(n: usize) -> Vec<Vec<usize>> {   // every way to give each row its own column
    if n == 0 { return vec![vec![]] }
    let mut out = Vec::new();
    for p in perms(n - 1) {
        for k in 0..n {
            let mut q = p.clone();
            q.insert(k, n - 1);
            out.push(q);
        }
    }
    out
}

fn sign(p: &[usize]) -> i128 {             // +1 if an even count of pairs sit out of order
    let mut inv = 0;
    for i in 0..p.len() { for j in i + 1..p.len() { if p[i] > p[j] { inv += 1 } } }
    if inv % 2 == 1 { -1 } else { 1 }
}

fn by_definition(m: &M) -> (i128, i128, u64, u64, u128) {  // road 1: all n! products
    let (mut per, mut det, mut even, mut odd, mut mults) = (0, 0, 0, 0, 0);
    for p in perms(m.len()) {
        let mut prod = m[0][p[0]];
        for i in 1..m.len() { prod *= m[i][p[i]]; mults += 1 }
        per += prod;
        det += sign(&p) * prod;
        if prod != 0 && sign(&p) == 1 { even += 1 }
        if prod != 0 && sign(&p) == -1 { odd += 1 }
    }
    (per, det, even, odd, mults)
}

fn ryser(m: &M) -> (i128, u128) {          // road 2: sum over column sets, signs alternate
    let n = m.len();
    let (mut total, mut mults) = (0i128, 0u128);
    for s in 1usize..(1 << n) {
        let mut prod = 1i128;
        for i in 0..n {
            prod *= (0..n).filter(|&j| s >> j & 1 == 1).map(|j| m[i][j]).sum::<i128>();
            mults += 1;
        }
        if (n - s.count_ones() as usize) % 2 == 0 { total += prod } else { total -= prod }
    }
    (total, mults)
}

fn search(m: &M, i: usize, used: usize) -> i128 {  // road 3: give lead i a free practised follow
    if i == m.len() { return 1 }
    (0..m.len()).filter(|&j| m[i][j] != 0 && used >> j & 1 == 0).map(|j| search(m, i + 1, used | 1 << j)).sum()
}

fn bareiss(a: &M) -> (i128, u128) {        // the determinant by elimination, whole numbers only
    let (mut m, n) = (a.clone(), a.len());
    let (mut sg, mut prev, mut mults) = (1i128, 1i128, 0u128);
    for k in 0..n - 1 {
        if m[k][k] == 0 {
            match (k + 1..n).find(|&r| m[r][k] != 0) {
                None => return (0, mults),
                Some(r) => { m.swap(k, r); sg = -sg }
            }
        }
        for i in k + 1..n {
            for j in k + 1..n {
                m[i][j] = (m[i][j] * m[k][k] - m[i][k] * m[k][j]) / prev;
                mults += 2;
            }
        }
        prev = m[k][k];
    }
    (sg * m[n - 1][n - 1], mults)
}

fn tilings(rows: usize, cols: usize) -> i128 {  // chessboard road 2: fill cell by cell
    let mut ways = vec![0i128; 1 << cols]; ways[0] = 1;
    for cell in 0..rows * cols {
        let (r, c) = (cell / cols, cell % cols);
        let mut new = vec![0i128; 1 << cols];
        for (m, &w) in ways.iter().enumerate() {
            if w == 0 { continue }
            if m >> c & 1 == 1 { new[m & !(1 << c)] += w; continue }
            if r + 1 < rows { new[m | 1 << c] += w }
            if c + 1 < cols && m >> (c + 1) & 1 == 0 { new[m | 1 << (c + 1)] += w }
        }
        ways = new;
    }
    ways[0]
}
fn fact(n: u128) -> u128 { if n < 2 { 1 } else { n * fact(n - 1) } }
fn cost(n: u128) -> (u128, u128, u128) {
    (fact(n) * (n - 1), ((1u128 << n) - 1) * n, 2 * (1..n).map(|m| m * m).sum::<u128>())
}
fn names(p: &[usize]) -> String { p.iter().map(|&j| F[j]).collect() }

fn main() {
    let (a, small) = (dance(8), dance(4));
    let (p4, d4, e4, o4, _) = by_definition(&small);
    let shown: Vec<String> = perms(4).iter().filter(|p| (0..4).all(|i| small[i][p[i]] != 0))
        .map(|p| format!("{}{}", names(p), if sign(p) > 0 { "+" } else { "-" })).collect();
    println!("4 couples: pairings {}", shown.join(" "));
    println!("4 couples: permanent {}, determinant {}, even {}, odd {}", p4, d4, e4, o4);
    for i in 0..8 {
        let k: Vec<String> = (0..8).filter(|&j| a[i][j] != 0).map(|j| F[j].to_string()).collect();
        println!("lead {} has danced with {}", i + 1, k.join(", "));
    }
    let (per, det, even, odd, m_def) = by_definition(&a);
    let ((ry, m_ry), (bd, m_el)) = (ryser(&a), bareiss(&a));
    println!("8 couples, every pairing: permanent {}, determinant {}, even {}, odd {}", per, det, even, odd);
    println!("8 couples, Ryser: permanent {}; backtracking search: {} pairings", ry, search(&a, 0, 0));
    println!("8 couples, elimination: determinant {}", bd);
    println!("multiplications counted at n = 8: every pairing {}, Ryser {}, elimination {}", m_def, m_ry, m_el);
    println!("same counts by formula: {}, {}, {}", cost(8).0, cost(8).1, cost(8).2);
    for n in [8u128, 16, 32] {
        let c = cost(n);
        println!("n = {}: every pairing {}, Ryser {}, elimination {}", n, c.0, c.1, c.2);
    }
    for (k, name) in ["every pairing", "Ryser", "elimination"].iter().enumerate() {
        let v: Vec<String> = (1..=8u128).map(|t| {
            let c = cost(4 * t);
            let x = [c.0, c.1, c.2][k] as f64;
            format!("{:.2}", x.log10())
        }).collect();
        println!("chart log10 {}: {}", name, v.join(", "));
    }
    let (b, b2): (M, M) = (vec![vec![1, 2], vec![3, 4]], vec![vec![1, 2], vec![0, -2]]);
    println!("2 by 2 [[1, 2], [3, 4]]: permanent {}, determinant {}", by_definition(&b).0, by_definition(&b).1);
    println!("after row 2 minus 3 x row 1: permanent {}, determinant {}", by_definition(&b2).0, by_definition(&b2).1);
    println!("sign trick at n = 2: det [[1, -2], [3, 4]] = {}", by_definition(&vec![vec![1, -2], vec![3, 4]]).1);
    let best = (0..512).map(|s: usize| {
        let sm: M = (0..3).map(|i| (0..3).map(|j| 1 - 2 * ((s >> (3 * i + j) & 1) as i128)).collect()).collect();
        by_definition(&sm).1.abs()
    }).max().unwrap();
    let ones: M = vec![vec![1; 3]; 3];
    println!("sign trick at n = 3: largest |det| over all 512 sign patterns {}, permanent of all ones {}", best, by_definition(&ones).0);
    println!("mistake, |determinant| read as the count: {}, not {}", det.abs(), per);
    let minus = [(0, 0), (1, 2), (3, 4), (5, 6), (7, 7)];  // lead 1 with A, 2 with C, 4 with E, 6 with G, 8 with H
    let s: M = (0..8).map(|i| (0..8).map(|j| if minus.contains(&(i, j)) { -a[i][j] } else { a[i][j] }).collect()).collect();
    println!("dance class, five entries made negative: determinant {}", bareiss(&s).0);
    let sq: Vec<(i64, i64)> = (0..64).map(|t| (t / 8, t % 8)).collect();
    let blk: Vec<(i64, i64)> = sq.iter().copied().filter(|s| (s.0 + s.1) % 2 == 0).collect();
    let wht: Vec<(i64, i64)> = sq.iter().copied().filter(|s| (s.0 + s.1) % 2 == 1).collect();
    let k: M = blk.iter().map(|&(r, c)| wht.iter().map(|&(r2, c2)| {
        if r == r2 && (c - c2).abs() == 1 { 1 }
        else if c == c2 && (r - r2).abs() == 1 { if c % 2 == 0 { 1 } else { -1 } }
        else { 0 }
    }).collect()).collect();
    let kd = bareiss(&k).0;
    println!("chessboard dominoes: signed 32 by 32 determinant {}, cell-by-cell count {}", kd, tilings(8, 8));
    assert!(per == ry && ry == search(&a, 0, 0) && p4 == search(&small, 0, 0)); // three roads
    assert!(det == bd && d4 == bareiss(&small).0);                              // two roads
    assert!(bareiss(&vec![vec![0, 1], vec![1, 0]]).0 == by_definition(&vec![vec![0, 1], vec![1, 0]]).1); // a row swap flips the sign
    assert!(even as i128 + odd as i128 == per && even as i128 - odd as i128 == det);
    assert!((m_def, m_ry, m_el) == cost(8));                                    // counted work
    assert!(best < by_definition(&ones).0);                                     // no pattern at n = 3
    assert!(bareiss(&s).0.abs() == per);                                        // a sign pattern fits
    assert!(kd.abs() == tilings(8, 8));                                         // planar board
    println!("ALL CHECKS PASS");
}
