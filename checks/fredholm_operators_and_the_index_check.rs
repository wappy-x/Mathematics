// Fredholm index: the check behind the card.  Rust std only, no crates.
// Every computation is a finite section of an infinite operator; the trend over N
// carries the infinite-dimensional answer.  Ranks are exact (integer elimination).
use std::f64::consts::PI;
type M = Vec<Vec<i128>>;

fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn rank(a: &M) -> usize {          // exact rank of an integer matrix, row by row
    let mut m = a.clone();
    let (rows, cols) = (m.len(), m[0].len());
    let mut rk = 0;
    for c in 0..cols {
        let p = match (rk..rows).find(|&i| m[i][c] != 0) { Some(p) => p, None => continue };
        m.swap(rk, p);
        for i in rk + 1..rows {
            let row: Vec<i128> = (0..cols).map(|j| m[rk][c] * m[i][j] - m[i][c] * m[rk][j]).collect();
            let g = row.iter().fold(0, |g, &v| gcd(g, v));
            m[i] = if g != 0 { row.iter().map(|v| v / g).collect() } else { row };
        }
        rk += 1;
    }
    rk
}
fn shift(r: usize, c: usize, k: usize) -> M {   // delay by k: column j has a 1 in row j + k
    (0..r).map(|i| (0..c).map(|j| (i == j + k) as i128).collect()).collect()
}
fn transpose(a: &M) -> M { (0..a[0].len()).map(|j| a.iter().map(|r| r[j]).collect()).collect() }
fn mul(a: &M, b: &M) -> M {
    (0..a.len()).map(|i| (0..b[0].len()).map(|j| (0..b.len()).map(|t| a[i][t] * b[t][j]).sum()).collect()).collect()
}
fn eye(n: usize) -> M { (0..n).map(|i| (0..n).map(|j| (i == j) as i128).collect()).collect() }
fn index_row(name: &str, a: &M) -> i64 {
    let r = rank(a);
    let (ker, cok) = (a[0].len() - r, a.len() - r);
    println!("{:<34}{}x{}  ker {}  coker {}  index {:+}", name, a.len(), a[0].len(), ker, cok, ker as i64 - cok as i64);
    ker as i64 - cok as i64
}
fn count_below(a: &[f64], b: &[f64], t: f64) -> usize {  // Sturm count for a symmetric tridiagonal matrix
    let (mut q, mut n) = (a[0] - t, (a[0] - t < 0.0) as usize);
    for i in 1..a.len() {
        q = a[i] - t - b[i - 1] * b[i - 1] / (if q != 0.0 { q } else { 1e-300 });
        n += (q < 0.0) as usize;
    }
    n
}
fn section(lam: f64, n: usize) -> Vec<Vec<f64>> {  // (n+1) x n section of S - lam
    (0..n + 1).map(|i| (0..n).map(|j| if i == j { -lam } else if i == j + 1 { 1.0 } else { 0.0 }).collect()).collect()
}
fn smallest_stretch(lam: f64, n: usize) -> f64 {
    let s = section(lam, n);
    let col = |j: usize| -> Vec<f64> { s.iter().map(|r| r[j]).collect() };
    let a: Vec<f64> = (0..n).map(|j| col(j).iter().map(|v| v * v).sum()).collect();
    let b: Vec<f64> = (0..n - 1).map(|j| col(j).iter().zip(col(j + 1).iter()).map(|(u, v)| u * v).sum()).collect();
    let (mut lo, mut hi) = (0.0, (1.0 + lam.abs()).powi(2));
    for _ in 0..80 {
        let mid = (lo + hi) / 2.0;
        if count_below(&a, &b, mid) >= 1 { hi = mid } else { lo = mid }
    }
    ((lo + hi) / 2.0).sqrt()
}
fn grid_count(n: usize, c: f64, t: f64) -> usize {  // eigenvalues < t of diag(x) + (c/n) 1 1^T, by pivots
    let (mut s, mut neg) = (1.0, 0);
    for i in 0..n {
        let d = (i as f64 + 0.5) / n as f64 - t;
        let p = d + s * c / n as f64;
        neg += (p < 0.0) as usize;
        s = s * d / p;
    }
    neg
}
fn top_secular(n: usize, c: f64) -> f64 {
    let (mut lo, mut hi) = ((n as f64 - 0.5) / n as f64 + 1e-15, 1.0 + c.abs() + 1.0);
    for _ in 0..200 {
        let mid = (lo + hi) / 2.0;
        let f = 1.0 - c / n as f64 * (0..n).map(|i| 1.0 / (mid - (i as f64 + 0.5) / n as f64)).sum::<f64>();
        if f > 0.0 { hi = mid } else { lo = mid }
    }
    (lo + hi) / 2.0
}
fn top_count(n: usize, c: f64) -> f64 {
    let (mut lo, mut hi) = (1.0, 3.0);
    for _ in 0..100 {
        let mid = (lo + hi) / 2.0;
        if grid_count(n, c, mid) == n { hi = mid } else { lo = mid }
    }
    (lo + hi) / 2.0
}

fn main() {
    let n = 6;
    println!("Finite sections of the delay line S on an endless clip (exact ranks)");
    let (s, adv) = (shift(n + 1, n, 1), transpose(&shift(n + 1, n, 1)));  // advance = S* = S transposed
    let i_s = index_row("S, delay by one", &s);
    let i_a = index_row("advance S*", &adv);
    let i_s3 = index_row("S^3, delay by three", &shift(n + 3, n, 3));
    let a2 = transpose(&shift(n + 3, n + 1, 2));
    let i_a2 = index_row("advance twice", &a2);
    let p = mul(&a2, &shift(n + 3, n, 3));
    let i_p = index_row("advance twice after S^3", &p);
    assert!(p == s && i_p == i_a2 + i_s3 && i_p == -1 && i_a == 1 && i_s == -1);
    let mut sk = s.clone(); sk[0][0] = 1;          // K x = x1 e1, rank one
    let i_sk = index_row("S + K, K x = x1 e1", &sk);
    let y: Vec<i128> = (0..n + 1).map(|i| [1, -1, 0][i.min(2)]).collect();  // the direction S + K misses
    assert!(i_sk == -1 && (0..n).all(|j| (0..n + 1).map(|i| y[i] * sk[i][j]).sum::<i128>() == 0));
    let h: M = (0..n + 1).map(|i| (0..n).map(|j| 2 * s[i][j] - (i == j) as i128).collect()).collect();
    let i_h = index_row("2(S - 0.5), inside the circle", &h);
    let t: M = (0..n + 1).map(|i| (0..n).map(|j| s[i][j] - 2 * (i == j) as i128).collect()).collect();
    let i_t = index_row("S - 2, outside the circle", &t);
    let i_q = index_row("S cut square", &shift(n, n, 1));
    assert!(i_h == -1 && i_t == -1 && i_q == 0);
    let (sa, e7) = (mul(&s, &adv), eye(n + 1));
    let r2 = rank(&(0..n + 1).map(|i| (0..n + 1).map(|j| sa[i][j] - e7[i][j]).collect()).collect());
    let left_ok = mul(&adv, &s) == eye(n);
    println!("parametrix: advance S = I is {}; S advance - I has rank {} (minus the projection on e1)",
             if left_ok { "True" } else { "False" }, r2);
    assert!(left_ok && r2 == 1);

    println!("Smallest stretch of the section of S - lam (closed range test); closed form agrees");
    let mut last = [0.0f64; 3];
    for &m in &[5usize, 10, 20, 40, 80, 160] {
        for (k, &lam) in [0.5f64, 1.0, 2.0].iter().enumerate() {
            let v = smallest_stretch(lam, m);
            let exact = (1.0 + lam * lam - 2.0 * lam * (PI / (m as f64 + 1.0)).cos()).sqrt();
            assert!((v - exact).abs() < 1e-9);
            last[k] = v;
        }
        println!("N={:<4} lam 0.5: {:.4}  lam 1: {:.4} (x (N+1)/pi = {:.4})  lam 2: {:.4}",
                 m, last[0], last[1], last[1] * (m as f64 + 1.0) / PI, last[2]);
    }
    assert!((last[1] * 161.0 / PI - 1.0).abs() < 1e-4 && last[0] > 0.49 && last[2] > 0.99);
    println!("Missed direction (1, lam, lam^2, ...): energy share in the first 5 entries / at the cut; endless energy at lam 0.5: {:.6}", (0..200).map(|j| 0.25f64.powi(j)).sum::<f64>());
    let mut out = [0.0f64; 4];
    for &m in &[5usize, 10, 20] {
        for (k, &lam) in [0.5f64, 2.0].iter().enumerate() {
            let w: Vec<f64> = (0..m + 1).map(|j| lam.powi(2 * j as i32)).collect();
            let a = section(lam, m);
            let yv: Vec<f64> = (0..m + 1).map(|j| lam.powi(j as i32)).collect();
            assert!((0..m).all(|j| (0..m + 1).map(|i| yv[i] * a[i][j]).sum::<f64>() == 0.0));
            let tot: f64 = w.iter().sum();
            (out[2 * k], out[2 * k + 1]) = (w[..5].iter().sum::<f64>() / tot, w[m] / tot);
        }
        println!("N={:<3} lam 0.5: first 5 {:.6}, at cut {:.6}   lam 2: first 5 {:.6}, at cut {:.6}", m, out[0], out[1], out[2], out[3]);
    }
    assert!(out[0] > 0.999 && out[3] > 0.74);

    println!("Multiplication by x on L2[0, 1] plus K u = c <1, u> 1, midpoint grid of N points");
    let c = 1.0f64; let lam_star = 1.0 / (1.0 - (-1.0 / c).exp());
    println!("closed form, 1 = c ln(lam/(lam - 1)): lam = 1/(1 - {:.6}) = 1/{:.6} = {:.6}", (-1.0 / c).exp(), 1.0 - (-1.0 / c).exp(), lam_star);
    for &m in &[10usize, 100, 1000] {
        let (a, b) = (top_secular(m, c), top_count(m, c));
        assert!((a - b).abs() < 1e-9 && (a - lam_star).abs() < 1.0 / (m * m) as f64);
        println!("N={:<5} top eigenvalue {:.6} (secular) {:.6} (pivots)  error x N^2 {:+.4}", m, a, b, (a - lam_star) * (m * m) as f64);
    }
    for &m in &[100usize, 1000, 10000] {
        let (below, above) = (grid_count(m, c, 0.0), m - grid_count(m, c, 1.0));
        let mid = grid_count(m, c, 0.6) - grid_count(m, c, 0.4);
        println!("N={:<6} below 0: {}   above 1: {}   in [0.4, 0.6]: {}   without K, above 1: {}", m, below, above, mid, m - grid_count(m, 0.0, 1.0));
        assert!(below == 0 && above == 1 && (mid as f64 - 0.2 * m as f64).abs() <= 1.0);
    }
    let (mut lo, mut hi) = (-3.0f64, 0.0f64);     // c = -1: the bound state moves below the band
    for _ in 0..100 {
        let mid = (lo + hi) / 2.0;
        if grid_count(1000, -1.0, mid) >= 1 { hi = mid } else { lo = mid }
    }
    println!("c = -1, N=1000: one eigenvalue below 0, at {:.6}; closed form -1/(e - 1) = {:.6}", lo, -1.0 / (1f64.exp() - 1.0));
    assert!(grid_count(1000, -1.0, 0.0) == 1 && (lo + 1.0 / (1f64.exp() - 1.0)).abs() < 1e-5);
    println!("figure, circle centre 120 120 radius 80; band 270.0 to 390.0; eigenvalue at {:.3}", 270.0 + 120.0 * lam_star);
    println!("ALL CHECKS PASS");
}
