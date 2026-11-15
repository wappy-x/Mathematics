// Spectrum and resolvent -- the same check as the Python, in Rust.  No crates.
// The delay line S moves a signal one sample later: S(x0, x1, ...) = (0, x0, x1, ...).
// Code holds only truncations, the first N samples.  Inverses, norms and least
// squares are written out here; nothing used already knows the answer.
fn f6(t: f64) -> String { format!("{:.6}", t) }
fn size(x: &[f64]) -> f64 { x.iter().fold(0.0, |s, t| s + t * t).sqrt() }
fn join(x: &[f64], d: usize) -> String { x.iter().map(|t| format!("{:.*}", d, t)).collect::<Vec<_>>().join(" ") }
fn yn(c: bool) -> &'static str { if c { "yes" } else { "no" } }

fn minus_shift(lam: f64, x: &[f64]) -> Vec<f64> {   // (lam I - S) x; the delayed copy spills one sample
    (0..=x.len()).map(|n| lam * (if n < x.len() { x[n] } else { 0.0 }) - (if n > 0 { x[n - 1] } else { 0.0 })).collect()
}

fn echo(lam: f64, y: &[f64], steps: usize) -> Vec<f64> {   // x_n = (y_n + x_{n-1}) / lam
    let mut x = Vec::new();
    let mut prev = 0.0;
    for n in 0..steps {
        prev = ((if n < y.len() { y[n] } else { 0.0 }) + prev) / lam;
        x.push(prev);
    }
    x
}

fn trunc_inverse(lam: f64, n: usize) -> Vec<Vec<f64>> {   // (lam I - S_N)^-1 by forward substitution
    let mut x = vec![vec![0.0; n]; n];
    for k in 0..n {
        for j in 0..n {
            x[j][k] = ((if j == k { 1.0 } else { 0.0 }) + (if j > 0 { x[j - 1][k] } else { 0.0 })) / lam;
        }
    }
    x
}

fn matmul(a: &[Vec<f64>], b: &[Vec<f64>]) -> Vec<Vec<f64>> {
    (0..a.len()).map(|i| (0..b[0].len()).map(|j| (0..b.len()).fold(0.0, |s, t| s + a[i][t] * b[t][j])).collect()).collect()
}

fn opnorm(a: &[Vec<f64>]) -> f64 {   // largest stretch of A: power iteration on A^T A
    let n = a.len();
    let apply = |x: &[f64]| -> Vec<f64> { (0..n).map(|i| (0..n).fold(0.0, |s, j| s + a[i][j] * x[j])).collect() };
    let mut x = vec![1.0; n];
    for _ in 0..300 {
        let y = apply(&x);
        let z: Vec<f64> = (0..n).map(|j| (0..n).fold(0.0, |s, i| s + a[i][j] * y[i])).collect();
        let s = size(&z);
        x = z.iter().map(|t| t / s).collect();
    }
    size(&apply(&x))
}

fn distance_to_range(lam: f64, m: usize) -> f64 {   // least squares by tridiagonal normal equations
    let (d, o) = (lam * lam + 1.0, -lam);
    let mut b = vec![0.0; m];
    b[0] = lam;
    let (mut c, mut r) = (vec![0.0; m], vec![0.0; m]);
    c[0] = o / d;
    r[0] = b[0] / d;
    for i in 1..m {
        let mm = d - o * c[i - 1];
        c[i] = o / mm;
        r[i] = (b[i] - o * r[i - 1]) / mm;
    }
    let mut x = vec![0.0; m];
    x[m - 1] = r[m - 1];
    for i in (0..m - 1).rev() { x[i] = r[i] - c[i] * x[i + 1]; }
    let mut res = minus_shift(lam, &x);
    res[0] -= 1.0;
    size(&res)
}

fn ones_ratio(lam: f64, m: usize) -> f64 { size(&minus_shift(lam, &vec![1.0; m])) / (m as f64).sqrt() }
fn echo_ratio(lam: f64, m: usize) -> f64 { size(&echo(lam, &vec![1.0; m], m + 400)) / (m as f64).sqrt() }

fn main() {
    println!("delay line S on l2: one-sided signals of finite energy; code holds the first N samples");
    println!("-- outside the disc: a feedback echo with gain 1/lam");
    let r2 = echo(2.0, &[1.0], 60);
    println!("lam = 2.00, R(2) e0 first five samples: {} | size {} | sqrt(1/3) {}", join(&r2[..5], 5), f6(size(&r2)), f6((1.0f64 / 3.0).sqrt()));
    for lam in [2.0, 1.25] {
        let bound = 1.0 / (lam - 1.0);
        let tests: Vec<f64> = [10, 100, 1000].iter().map(|&m| echo_ratio(lam, m)).collect();
        println!("lam = {:.2}: Neumann bound 1/(|lam| - 1) = {}; ones-block test M = 10, 100, 1000: {}", lam, f6(bound), join(&tests, 6));
        assert!(tests.iter().all(|&t| t <= bound + 1e-12) && bound - tests[2] < 0.02 * bound);
    }
    let n = 6;
    let (ra, rb) = (trunc_inverse(2.0, n), trunc_inverse(1.25, n));
    let p = matmul(&ra, &rb);
    let (mut gap, mut closed) = (0.0f64, 0.0f64);
    for i in 0..n {
        for j in 0..n {
            gap = gap.max((ra[i][j] - rb[i][j] - (1.25 - 2.0) * p[i][j]).abs());
            let f = if i >= j { 2.0f64.powi(-((i - j + 1) as i32)) } else { 0.0 };
            closed = closed.max((ra[i][j] - f).abs());
        }
    }
    println!("resolvent identity, N = 6: R(2) - R(1.25) at (0,0) = {}; (1.25 - 2) R(2) R(1.25) = {}; gap below 1e-14: {}",
             f6(ra[0][0] - rb[0][0]), f6(-0.75 * p[0][0]), yn(gap < 1e-14));
    println!("forward substitution against the formula lam^-(j-k+1): gap below 1e-15: {}", yn(closed < 1e-15));
    assert!(gap < 1e-14 && closed < 1e-15);
    println!("-- no eigenvalues");
    let mut x0 = vec![0.0; 8];
    x0[7] = 1.0;
    println!("truncated S_8 sends e7 to {}, so 0 is its eigenvalue; the true S sends e7 to size {}",
             f6(size(&minus_shift(0.0, &x0)[..8])), f6(size(&minus_shift(0.0, &x0))));
    assert!(size(&minus_shift(0.0, &x0)[..8]) == 0.0 && size(&minus_shift(0.0, &x0)) == 1.0);
    println!("-- inside the disc, lam = 0.5: residual spectrum");
    println!("echo of e0 at lam = 0.5: {} ... doubling, infinite energy", join(&echo(0.5, &[1.0], 5), 0));
    let v: Vec<f64> = (0..60).map(|k| 0.5f64.powi(k)).collect();
    let w = minus_shift(0.5, &[3.0, -1.0, 4.0, 1.0, -5.0]);
    let ip = v.iter().zip(w.iter()).fold(0.0, |s, (a, b)| s + a * b);
    println!("obstruction v = (1, 0.5, 0.25, ...): <v, (0.5 I - S) x> for x = (3, -1, 4, 1, -5) = {}", f6(ip));
    let adj = (0..59).fold(0.0f64, |s, k| s.max((v[k + 1] - 0.5 * v[k]).abs()));
    println!("left shift S* v - 0.5 v, largest entry = {}; ||v||^2 = {}", f6(adj), f6(size(&v).powi(2)));
    let dists: Vec<f64> = [3, 24, 99].iter().map(|&m| distance_to_range(0.5, m)).collect();
    println!("distance from e0 to the range, least squares M = 3, 24, 99: {} | closed form sqrt(1 - lam^2) = {}", join(&dists, 6), f6(0.75f64.sqrt()));
    assert!((dists[2] - 0.75f64.sqrt()).abs() < 1e-12 && ip.abs() < 1e-15 && adj < 1e-15 && (size(&v).powi(2) - 4.0 / 3.0).abs() < 1e-12);
    let low: Vec<f64> = [2, 200, 20000].iter().map(|&m| ones_ratio(0.5, m)).collect();
    println!("bounded below: ||(0.5 I - S) x|| / ||x|| on ones blocks M = 2, 200, 20000: {} | never below 1 - |lam| = 0.5", join(&low, 6));
    assert!(low.iter().all(|&t| t >= 0.5));
    println!("-- on the circle, lam = 1: continuous spectrum");
    println!("echo of e0 at lam = 1: {} ... never decays, infinite energy", join(&echo(1.0, &[1.0], 5), 0));
    let ms = [3usize, 24, 99];
    let d1: Vec<f64> = ms.iter().map(|&m| distance_to_range(1.0, m)).collect();
    let inv: Vec<f64> = ms.iter().map(|&m| 1.0 / ((m + 1) as f64).sqrt()).collect();
    println!("distance from e0 to the range, least squares M = 3, 24, 99: {} | 1/sqrt(M + 1) = {}", join(&d1, 6), join(&inv, 6));
    assert!(d1.iter().zip(inv.iter()).all(|(d, e)| (d - e).abs() < 1e-12));
    let c1: Vec<f64> = [2, 200, 20000].iter().map(|&m| ones_ratio(1.0, m)).collect();
    println!("||(I - S) x|| / ||x|| on ones blocks M = 2, 200, 20000: {} | sqrt(2/M) -> {}", join(&c1, 6), f6((2.0f64 / 20000.0).sqrt()));
    assert!((c1[2] - 0.01).abs() < 1e-12);
    println!("-- the truncation's honesty: ||(lam I - S_N)^-1|| by power iteration");
    let ns = [5usize, 10, 20, 40];
    let mut table: Vec<Vec<f64>> = Vec::new();
    for lam in [0.5, 1.0, 1.25, 2.0] {
        let row: Vec<f64> = ns.iter().map(|&k| opnorm(&trunc_inverse(lam, k))).collect();
        let big = row.iter().map(|&t| if t < 1e9 { format!("{:.4}", t) } else { format!("{:.6e}", t).replace('e', "e+") }).collect::<Vec<_>>();
        println!("lam = {:.2}, N = 5, 10, 20, 40: {}", lam, big.join(" "));
        println!("   log10: {}", join(&row.iter().map(|t| t.log10()).collect::<Vec<_>>(), 3));
        table.push(row);
    }
    let sine: Vec<f64> = ns.iter().map(|&k| 1.0 / (2.0 * (std::f64::consts::PI / (4 * k + 2) as f64).sin())).collect();
    println!("lam = 1 closed form 1/(2 sin(pi/(4N + 2))): {}", join(&sine, 4));
    assert!(table[1].iter().zip(sine.iter()).all(|(a, b)| (a - b).abs() < 1e-9 * b));
    assert!(table[0].iter().zip(ns.iter()).all(|(t, &k)| (t / (4.0 / 3.0 * 2.0f64.powi(k as i32)) - 1.0).abs() < 0.01));
    assert!(table[3].windows(2).all(|p| p[0] < p[1] && p[1] <= 1.0));
    println!("-- spectral radius r = lim ||T^n||^(1/n)");
    let sig = vec![1.0, -2.0, 0.5];
    let mut grown = sig.clone();
    for _ in 0..5 { grown.insert(0, 0.0); }
    println!("S is an isometry: ||S^5 x|| / ||x|| = {}, so ||S^n||^(1/n) = 1 and r(S) = 1", f6(size(&grown) / size(&sig)));
    let mut last = vec![1.0; 8];
    for _ in 0..8 { last = minus_shift(0.0, &last)[..8].to_vec(); }
    println!("truncated S_8: eight delays push every sample off the end, ||S_8^8 x|| = {}, so r(S_8) = 0", f6(size(&last)));
    assert!((size(&grown) / size(&sig) - 1.0).abs() < 1e-15 && size(&last) == 0.0);
    println!("-- what breaks");
    let tail = size(&echo(0.5, &[1.0], 10));
    println!("Neumann series at lam = 0.5, ten terms on e0: size {:.1}, and growing", tail);
    let dets: Vec<f64> = (-300..=300).map(|t| (t as f64 / 100.0).powi(2) + 1.0).collect();
    let dmin = dets.iter().cloned().fold(f64::INFINITY, f64::min);
    println!("quarter turn [[0, -1], [1, 0]]: smallest det(lam I - A) = lam^2 + 1 over real lam in [-3, 3] is {}; roots i and -i", f6(dmin));
    assert!(dmin == 1.0);
    assert!((tail - (4.0 * (4.0f64.powi(10) - 1.0) / 3.0).sqrt()).abs() < 1e-9);
    println!("figure, unit 80 px, centre and lam = 0 at (180, 160); lam = 0.5 at (220, 160), 1 at (260, 160), 1.25 at (280, 160), 2 at (340, 160); safe disc round 2, radius 1/||R(2)|| = 80 px");
    println!("ALL CHECKS PASS");
}
