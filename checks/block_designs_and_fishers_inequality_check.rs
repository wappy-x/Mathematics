// Block designs and Fisher's inequality -- the same check as the Python, in
// Rust.  No crates.  The design is the Fano plane: 7 blends, 7 tasters, 3
// blends each.  The counts are read off the schedule and from the two formulas;
// the determinant of N N^T is found three ways: by elimination, as (det N)^2
// and from the closed form (r - lambda)^(v - 1) x r k.
const LINES: [[i64; 3]; 7] = [[1, 2, 4], [2, 3, 5], [3, 4, 6], [4, 5, 7], [5, 6, 1], [6, 7, 2], [7, 1, 3]];

fn det(m: &Vec<Vec<i64>>) -> i64 {                // exact whole-number elimination (Bareiss)
    let (mut a, n, mut sign, mut prev) = (m.clone(), m.len(), 1, 1);
    for i in 0..n {
        let p = match (i..n).find(|&r| a[r][i] != 0) { Some(p) => p, None => return 0 };
        if p != i { a.swap(i, p); sign = -sign; }
        for r in i + 1..n {
            for c in i + 1..n { a[r][c] = (a[r][c] * a[i][i] - a[r][i] * a[i][c]) / prev; }
        }
        prev = a[i][i];
    }
    sign * a[n - 1][n - 1]
}

fn gram(n: &Vec<Vec<i64>>) -> Vec<Vec<i64>> {     // N times N transposed
    n.iter().map(|p| n.iter().map(|q| p.iter().zip(q).map(|(x, y)| x * y).sum()).collect()).collect()
}

fn set(mut xs: Vec<i64>) -> Vec<i64> { xs.sort(); xs.dedup(); xs }

fn counts(v: f64, k: f64, lam: f64) -> (f64, f64) {  // the two counts solved for r, then b = v r / k
    let r = lam * (v - 1.0) / (k - 1.0);
    (r, v * r / k)
}

fn main() {
    let (v, b, k) = (7usize, LINES.len(), 3usize);
    let n: Vec<Vec<i64>> = (1..=7).map(|x| LINES.iter().map(|l| l.contains(&x) as i64).collect()).collect();
    let r_seen = set(n.iter().map(|row| row.iter().sum()).collect());      // road one: read the schedule
    let mut pairs = Vec::new();
    for x in 1..=7 { for y in x + 1..=7 {
        pairs.push(LINES.iter().filter(|l| l.contains(&x) && l.contains(&y)).count() as i64);
    } }
    let lam_seen = set(pairs.clone());
    let r = (b * k / v) as i64;                       // road two: b k = v r ...
    let lam = r * (k as i64 - 1) / (v as i64 - 1);    // ... and r(k - 1) = lambda(v - 1)
    let g = gram(&n);
    let closed = (r - lam).pow(v as u32 - 1) * r * k as i64;
    let lines: Vec<String> = LINES.iter().map(|l| format!("({}, {}, {})", l[0], l[1], l[2])).collect();
    println!("blocks: [{}]", lines.join(", "));
    println!("v = {}, b = {}, k = {}; each blend tasted {:?} times; each pair together {:?} times", v, b, k, r_seen, lam_seen);
    println!("b k = {}, v r = {}; r (k - 1) = {}, lambda (v - 1) = {}", b * k, v as i64 * r, r * (k as i64 - 1), lam * (v as i64 - 1));
    println!("pairs per taster {} x {} tasters = {} = all {} pairs", k * (k - 1) / 2, b, b * k * (k - 1) / 2, pairs.len());
    let diag = set((0..v).map(|i| g[i][i]).collect());
    let off = set((0..v).flat_map(|i| (0..v).filter(move |&j| j != i).map(move |j| (i, j))).map(|(i, j)| g[i][j]).collect());
    println!("N N^T row 1: {:?}; diagonal {:?}, off-diagonal {:?}", g[0], diag, off);
    println!("det(N N^T): elimination {}; (det N)^2 = ({})^2 = {}; closed form {}^{} x {} = {}",
             det(&g), det(&n), det(&n).pow(2), r - lam, v - 1, r * k as i64, closed);
    println!("rank N = {} since det N is not 0, so b = {} >= v = {}", v, b, v);
    let mut tested = 0;
    let mut ok = true;
    for rr in 2..9i64 { for ll in 1..rr { for vv in 2..9usize {
        let m: Vec<Vec<i64>> = (0..vv).map(|i| (0..vv).map(|j| if i == j { rr } else { ll }).collect()).collect();
        ok &= det(&m) == (rr - ll).pow(vv as u32 - 1) * (rr + (vv as i64 - 1) * ll);
        tested += 1;
    } } }
    println!("closed form against elimination on {} small (r, lambda, v) cases: {}", tested, if ok { "agree" } else { "DIFFER" });
    let ((r81, _), (r16, b16)) = (counts(8.0, 3.0, 1.0), counts(16.0, 6.0, 1.0));
    println!("mistake 1, (8, 3, 1): r = (8 - 1)/(3 - 1) = {}, not whole; upside down (3 - 1)/(8 - 1) = 1/r = {:.2}", r81, 1.0 / r81);
    println!("mistake 2, (16, 6, 1): r = {}, b = 16 x {} / 6 = {}, whole, but {} < 16", r16, r16, b16, b16);
    let one: Vec<Vec<i64>> = (0..v).map(|_| vec![1]).collect();          // one taster given all 7 blends
    println!("mistake 3, k = v: one block, N N^T = J, det {}, so b = 1 < 7 is no contradiction", det(&gram(&one)));
    assert!(r_seen == vec![r] && lam_seen == vec![lam] && lam == 1
            && counts(v as f64, k as f64, lam_seen[0] as f64) == (r_seen[0] as f64, b as f64));
    assert!(det(&g) == det(&n).pow(2) && det(&g) == closed && closed == 576 && ok);
    assert!((0..v).all(|i| (0..v).all(|j| g[i][j] == (r - lam) * (i == j) as i64 + lam)));
    assert!(det(&gram(&one)) == 0 && r81.fract() != 0.0 && r16.fract() == 0.0 && b16.fract() == 0.0 && b16 < 16.0);
    println!("ALL CHECKS PASS");
}
