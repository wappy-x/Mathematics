// Finite planes and orthogonal Latin squares -- the same check as the Python, in Rust.  No crates.  Lines are
// bit masks over numbered points.  Order 3 squares, the order 3 plane built two ways, Fano, and mates up to order 6.
use std::collections::HashSet;
type Sq = Vec<Vec<usize>>;
fn square(m: usize, n: usize) -> Sq { (0..n).map(|i| (0..n).map(|j| (i + m * j) % n).collect()).collect() }
fn latin(l: &Sq) -> bool { let n = l.len();
    (0..n).all(|i| (0..n).map(|j| l[i][j]).collect::<HashSet<_>>().len() == n && (0..n).map(|j| l[j][i]).collect::<HashSet<_>>().len() == n) }
fn pairs(a: &Sq, b: &Sq) -> usize { let n = a.len(); (0..n * n).map(|c| (a[c / n][c % n], b[c / n][c % n])).collect::<HashSet<_>>().len() }
fn yn(claim: bool) -> &'static str { if claim { "yes" } else { "no" } }
fn plane_ok(pts: &[usize], lines: &[u64]) -> bool {          // two points share one line, two lines share one point
    pts.iter().enumerate().all(|(k, &a)| pts[k + 1..].iter().all(|&b| lines.iter().filter(|&&l| l >> a & 1 == 1 && l >> b & 1 == 1).count() == 1))
        && (0..lines.len()).all(|x| (x + 1..lines.len()).all(|y| (lines[x] & lines[y]).count_ones() == 1)) }
fn from_squares(sqs: &[Sq], n: usize) -> Vec<u64> {          // road one: cell i*n+j, point at infinity n*n+class
    let key = |c: usize, i: usize, j: usize| if c == 0 { i } else if c == 1 { j } else { sqs[c - 2][i][j] };
    let mut lines: Vec<u64> = (0..n + 1).flat_map(|c| (0..n).map(move |s| (c, s))).map(|(c, s)| (0..n * n)
        .filter(|&p| key(c, p / n, p % n) == s).fold(1u64 << (n * n + c), |m, p| m | 1 << p)).collect();
    lines.push((n * n..n * n + n + 1).fold(0, |m, p| m | 1 << p)); lines }
fn gf_plane(q: usize) -> (usize, Vec<u64>) {                 // road two: triples over GF(q) for prime q, first nonzero entry 1
    let pts: Vec<[usize; 3]> = (0..q * q * q).map(|x| [x / (q * q), x / q % q, x % q])
        .filter(|t| t.iter().any(|&v| v > 0) && *t.iter().find(|&&v| v > 0).unwrap() == 1).collect();
    let on = |p: &[usize; 3], l: &[usize; 3]| (0..3).map(|k| p[k] * l[k]).sum::<usize>() % q == 0;
    (pts.len(), pts.iter().map(|l| (0..pts.len()).filter(|&k| on(&pts[k], l)).fold(0, |m, k| m | 1 << k)).collect()) }
fn transversals(l: &Sq, i: usize, cols: u64, syms: u64, first: usize, mask: u64, out: &mut Vec<(usize, u64)>) {
    let n = l.len(); if i == n { out.push((first, mask)); return }
    for j in 0..n { if cols >> j & 1 == 0 && syms >> l[i][j] & 1 == 0 {
        transversals(l, i + 1, cols | 1 << j, syms | 1 << l[i][j], if i == 0 { j } else { first }, mask | 1 << (i * n + j), out) } } }
fn tile(t: &[(usize, u64)], k: usize, n: usize, used: u64) -> bool {
    k == n || t.iter().any(|&(f, m)| f == k && m & used == 0 && tile(t, k + 1, n, used | m)) }
fn has_mate(l: &Sq) -> bool { let mut t = Vec::new(); transversals(l, 0, 0, 0, 0, 0, &mut t); tile(&t, 0, l.len(), 0) }
fn fill(l: &mut Sq, c: usize, count: &mut [usize; 2]) {      // every Latin square with first row and column 0..n-1
    let n = l.len(); if c == n * n { count[0] += 1; if has_mate(l) { count[1] += 1 } return }
    let (i, j) = (c / n, c % n); if i == 0 || j == 0 { return fill(l, c + 1, count) }
    for s in 0..n { if (0..n).all(|k| l[i][k] != s && l[k][j] != s) { l[i][j] = s; fill(l, c + 1, count); l[i][j] = n } } }
fn main() {
    let (l1, l2) = (square(1, 3), square(2, 3)); println!("L1 = i + j mod 3: {:?}   L2 = i + 2j mod 3: {:?}", l1, l2);
    println!("both Latin: {}; ordered pairs seen when laid on top: {} of 9", yn(latin(&l1) && latin(&l2)), pairs(&l1, &l2));
    let rows: Vec<String> = (0..3).map(|i| (0..3).map(|j| format!("{}{}", l1[i][j], l2[i][j])).collect::<Vec<_>>().join(" ")).collect();
    println!("laid on top, row by row: {}", rows.join(" | "));
    let sq3: Vec<Sq> = (0..19683usize).map(|g| (0..3).map(|i| (0..3).map(|j| g / 3usize.pow(8 - 3 * i - j as u32) % 3).collect()).collect())
        .filter(|l| latin(l)).collect();
    let mo = |c: &[usize]| c.iter().enumerate().all(|(x, &a)| c[x + 1..].iter().all(|&b| pairs(&sq3[a], &sq3[b]) == 9));
    let k3 = sq3.len(); let best = if (0..k3.pow(3)).any(|x| { let c = [x / k3 / k3, x / k3 % k3, x % k3]; c[0] < c[1] && c[1] < c[2] && mo(&c) }) { 3 }
        else if (0..k3 * k3).any(|x| x / k3 < x % k3 && mo(&[x / k3, x % k3])) { 2 } else { 1 };
    println!("Latin squares of order 3: {}; largest mutually orthogonal set: {} = 3 - 1", k3, best);
    let la = from_squares(&[l1.clone(), l2.clone()], 3); let (nb, lb) = gf_plane(3); let pa: Vec<usize> = (0..13).collect();
    let ns = [2usize, 3, 4, 5, 7]; println!("n = ({}): points n^2 + n + 1 = {:?}, points per line n + 1 = {:?}", ns.map(|n| n.to_string()).join(", "),
             ns.map(|n| n * n + n + 1), ns.map(|n| n + 1));
    for (name, np, ls) in [("from the two squares", 13, &la), ("from triples over GF(3)", nb, &lb)] {
        let sz: Vec<u32> = ls.iter().map(|l| l.count_ones()).collect();
        println!("plane {}: {} points, {} lines, points per line {} to {}, a plane: {}", name, np, ls.len(), sz.iter().min().unwrap(),
                 sz.iter().max().unwrap(), yn(plane_ok(&(0..np).collect::<Vec<_>>(), ls))) }
    let inf: u64 = 0b1111 << 9; let aff3: Vec<u64> = la.iter().filter(|&&l| l & !inf != 0).map(|l| l & !inf).collect();
    let classes: HashSet<u64> = la.iter().filter(|&&l| l & !inf != 0).map(|l| l & inf).collect();
    println!("minus its line at infinity: {} points, {} lines of {}, in {} parallel classes",
             aff3.iter().fold(0, |m, l| m | l).count_ones(), aff3.len(), aff3[0].count_ones(), classes.len());
    let fano: Vec<u64> = [[1, 2, 4], [2, 3, 5], [3, 4, 6], [4, 5, 7], [5, 6, 1], [6, 7, 2], [7, 1, 3]].iter().map(|l| l.iter().fold(0, |m, p| m | 1 << p)).collect();
    let (_, g2) = gf_plane(2); let mut fs = fano.clone(); fs.sort();
    let same = (0..823543usize).any(|x| { let p: Vec<usize> = (0..7).map(|k| 1 + x / 7usize.pow(k) % 7).collect();
        if p.iter().fold(0u64, |m, &v| m | 1 << v) != 0b11111110 { return false }
        let mut img: Vec<u64> = g2.iter().map(|&l| (0..7).filter(|&k| l >> k & 1 == 1).fold(0, |m, k| m | 1 << p[k as usize])).collect();
        img.sort(); img == fs });
    println!("Fano plane: {} points, {} lines of 3, a plane: {}; the GF(2) plane, relabelled: {}", fano.iter().fold(0, |m, l| m | l).count_ones(), fano.len(),
             yn(plane_ok(&(1..8).collect::<Vec<_>>(), &fano)), yn(same));
    let aff: Vec<u64> = fano.iter().filter(|&&l| l != fano[0]).map(|l| l & !fano[0]).collect();
    println!("Fano minus the line 1 2 4: {} points, {} lines of {}", aff.iter().fold(0, |m, l| m | l).count_ones(), aff.len(), aff[0].count_ones());
    let mut mates = [[0usize; 2]; 7];
    for n in 2..7 { let mut l: Sq = (0..n).map(|i| (0..n).map(|j| if j == 0 { i } else if i == 0 { j } else { n }).collect()).collect();
        fill(&mut l, 0, &mut mates[n]); println!("order {}: reduced Latin squares {}, with an orthogonal mate {}", n, mates[n][0], mates[n][1]) }
    println!("mistake 1, the 4-hour clock for GF(4): i + 2j mod 4 row 0 = {:?}, Latin: {}", square(2, 4)[0], yn(latin(&square(2, 4))));
    let twice: Sq = l1.iter().map(|r| r.iter().map(|x| 2 * x % 3).collect()).collect();
    println!("mistake 2, second square 2(i + j) mod 3: ordered pairs {} of 9", pairs(&l1, &twice));
    println!("mistake 3, i + j and i + 5j mod 6: ordered pairs {} of 36", pairs(&square(1, 6), &square(5, 6)));
    assert!(pairs(&l1, &l2) == 9 && best == 2 && k3 == 12);
    assert!(plane_ok(&pa, &la) && plane_ok(&(0..nb).collect::<Vec<_>>(), &lb) && nb == 3 * 3 + 3 + 1);
    assert!(same && mates[6][1] == 0 && mates[5][1] > 0 && mates[2][1] == 0);
    println!("ALL CHECKS PASS");
}
