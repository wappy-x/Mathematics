// Cheeger's inequality and spectral geometry -- the same check as the Python, in
// Rust.  No crates.  Flat torus 2 pi by 2 pi, unit sphere, and a dumbbell: two
// unit spheres joined by a tube 1 m long and 0.1 m round.  Eigenvalues are
// counted against Weyl's law, then the first note is set against Cheeger's h.
use std::f64::consts::PI;

fn isqrt(n: i64) -> i64 { let mut r = 0; while (r + 1) * (r + 1) <= n { r += 1 } r }   // largest r with r*r <= n

fn torus_brute(lam: i64) -> i64 {                // road one: every (m, n) pair
    let mut c = 0;
    for m in -20..=20i64 { for n in -20..=20i64 { if m * m + n * n <= lam { c += 1 } } }
    c
}

fn torus_rows(lam: i64) -> i64 {                 // road two: one row of m at a time
    (-isqrt(lam)..=isqrt(lam)).map(|m| 2 * isqrt(lam - m * m) + 1).sum()
}

const P: i64 = 1000000007;                       // a prime; rank mod P bounds rank over Q
fn modpow(mut b: i64, mut e: i64) -> i64 {
    let mut r = 1;
    b %= P;
    while e > 0 { if e & 1 == 1 { r = r * b % P } b = b * b % P; e >>= 1 }
    r
}

fn mons(d: i64) -> Vec<(i64, i64, i64)> {
    let mut v = Vec::new();
    for a in 0..=d { for b in 0..=d - a { v.push((a, b, d - a - b)) } }
    v
}

fn harmonic_dim(k: i64) -> i64 {                 // kernel of the flat Laplacian, degree k -> k-2
    let cols = mons(k);
    let rows = if k >= 2 { mons(k - 2) } else { Vec::new() };
    let mut a = vec![vec![0i64; cols.len()]; rows.len()];
    for (j, &(x, y, z)) in cols.iter().enumerate() {
        for &(e, t) in &[(x, (x - 2, y, z)), (y, (x, y - 2, z)), (z, (x, y, z - 2))] {
            if e >= 2 {
                let i = rows.iter().position(|&m| m == t).unwrap();
                a[i][j] += e * (e - 1);
            }
        }
    }
    let fact = |n: i64| (1..=n).product::<i64>();
    let rk = |d: i64| -> Vec<i64> { mons(d).iter().map(|&(x, y, z)| if (x | y | z) % 2 == 1 { 0 } else { fact(d / 2) / (fact(x / 2) * fact(y / 2) * fact(z / 2)) }).collect() };
    assert!(k % 2 == 1 || k < 2 || a.iter().map(|row| row.iter().zip(rk(k)).map(|(u, v)| u * v).sum::<i64>()).eq(rk(k - 2).into_iter().map(|v| k * (k + 1) * v))); // radial road: Lap r^k = k(k+1) r^(k-2)
    let (mut rank, mut r) = (0usize, 0usize);
    for col in 0..cols.len() {                   // Gaussian elimination modulo P
        let piv = (r..rows.len()).find(|&i| a[i][col] % P != 0);
        let piv = match piv { Some(p) => p, None => continue };
        a.swap(r, piv);
        let inv = modpow(a[r][col], P - 2);
        for i in 0..rows.len() {
            if i != r && a[i][col] % P != 0 {
                let f = a[i][col] * inv % P;
                let pr = a[r].clone();
                for c in 0..cols.len() { a[i][c] = (a[i][c] - f * pr[c]).rem_euclid(P) }
            }
        }
        r += 1;
        rank += 1;
    }
    assert!(rank == rows.len());                 // full rank mod P forces full rank over Q
    (cols.len() - rank) as i64
}

fn lap_ratio(k: i32) -> f64 {                    // card 08's chart formula, by differences
    let (ph, th, d) = (1.0f64, 0.3f64, 1e-4f64);
    let y = |p: f64, t: f64| p.sin().powi(k) * (k as f64 * t).cos();
    let y0 = y(ph, th);
    let dph = ((ph + d / 2.0).sin() * (y(ph + d, th) - y0) - (ph - d / 2.0).sin() * (y0 - y(ph - d, th))) / (d * d * ph.sin());
    let dth = (y(ph, th + d) - 2.0 * y0 + y(ph, th - d)) / (d * d * ph.sin().powi(2));
    (dph + dth) / y0
}

const C: f64 = 0.1;                              // neck circumference, m
fn r0() -> f64 { C / (2.0 * PI) }                // neck radius
fn sj() -> f64 { PI - r0().asin() }              // bell length along the metal
const NECK: f64 = 1.0;                           // tube length
fn sphere_r(s: f64) -> f64 { s.sin() }
fn bell_r(s: f64) -> f64 {                       // dumbbell profile: bell, tube, bell
    if s <= sj() { s.sin() } else if s <= sj() + NECK { r0() } else { (2.0 * sj() + NECK - s).sin() }
}

fn lam1_mesh(prof: fn(f64) -> f64, length: f64, n: usize) -> f64 {   // Sturm-count bisection
    let h = length / n as f64;
    let mass: Vec<f64> = (0..n).map(|i| 2.0 * PI * prof((i as f64 + 0.5) * h) * h).collect();
    let cond: Vec<f64> = (0..n - 1).map(|i| 2.0 * PI * prof((i as f64 + 1.0) * h) / h).collect();
    let diag: Vec<f64> = (0..n).map(|i| ((if i > 0 { cond[i - 1] } else { 0.0 }) + (if i < n - 1 { cond[i] } else { 0.0 })) / mass[i]).collect();
    let off2: Vec<f64> = (0..n - 1).map(|i| cond[i] * cond[i] / (mass[i] * mass[i + 1])).collect();
    let below = |x: f64| -> usize {              // eigenvalues under x, by Sylvester's law
        let (mut q, mut cnt) = (diag[0] - x, 0);
        for i in 0..n {
            if i > 0 { q = diag[i] - x - off2[i - 1] / (if q != 0.0 { q } else { 1e-300 }) }
            if q < 0.0 { cnt += 1 }
        }
        cnt
    };
    let (mut lo, mut hi) = (0.0f64, 10.0f64);
    for _ in 0..60 {
        let mid = (lo + hi) / 2.0;
        if below(mid) >= 2 { hi = mid } else { lo = mid }
    }
    (lo + hi) / 2.0
}

fn list1(v: &[f64]) -> String { v.iter().map(|x| format!("{:.1}", x)).collect::<Vec<_>>().join(", ") }

fn main() {
    let (nt, wt) = (torus_brute(100), PI * 100.0);
    println!("torus 2pi x 2pi: eigenvalues m^2 + n^2 <= 100: brute {}, by rows {}; Weyl pi x 100 = {:.1}", nt, torus_rows(100), wt);
    let chart: Vec<i64> = (1..=10).map(|i| torus_brute(10 * i)).collect();
    println!("chart, torus count at lambda = 10..100: {:?}", chart);
    let wl: Vec<f64> = (1..=10).map(|i| PI * (10 * i) as f64).collect();
    println!("chart, Weyl pi x lambda: [{}]", list1(&wl));
    let mult: Vec<i64> = (0..11).map(harmonic_dim).collect();
    println!("sphere multiplicity by exact rank, k = 0..10: {:?}", mult);
    let fd: Vec<String> = [1, 2, 3].iter().map(|&k| format!("{:.6}", -lap_ratio(k))).collect();
    println!("sphere eigenvalue k(k+1), chart formula by differences, k = 1, 2, 3: {}", fd.join(", "));
    let (ns, ws): (i64, f64) = (mult.iter().sum(), PI * 4.0 * PI * 110.0 / (4.0 * PI * PI));
    println!("sphere: eigenvalues <= 110 with multiplicity {}, (K + 1)^2 = {}; Weyl = {:.1}", ns, 11 * 11, ws);
    println!("globe, radius 6371 km: lambda1 = 2/6371^2 = {:.4} x 1e-8 per km2", 2e8 / (6371.0f64 * 6371.0));
    for &n in &[200usize, 400] {
        let l = lam1_mesh(sphere_r, PI, n);
        println!("sphere lambda1 on a {}-cell mesh: {:.6}, error {:.6}", n, l, l - 2.0);
    }
    println!("sphere caps, alpha deg: area, rim, rim/area");
    for &a in &[30i32, 60, 90] {
        let t = (a as f64).to_radians();
        println!("  {:2}: {:.6}  {:.6}  {:.6}", a, 2.0 * PI * (1.0 - t.cos()), 2.0 * PI * t.sin(), t.sin() / (1.0 - t.cos()));
    }
    let hs = (1..=1000).map(|i| { let t = i as f64 * PI / 2000.0; t.sin() / (1.0 - t.cos()) }).fold(f64::INFINITY, f64::min);
    println!("sphere: h = {:.6}; Cheeger h^2/4 = {:.6} <= lambda1 = 2 <= Buser 10 h^2 = {:.6}", hs, hs * hs / 4.0, 10.0 * hs * hs);
    let (ht, hd) = (4.0 * PI / (2.0 * PI * PI), 2.0 * (PI / (2.0 * PI * PI)).sqrt());
    println!("torus half-cuts: two circles {:.6}, one disc {:.6}; h^2/4 = {:.6} <= 1 <= 10 h^2 = {:.6}", ht, hd, ht * ht / 4.0, 10.0 * ht * ht);
    let dq = (PI / 2.0) / 20000.0;
    let (mut iu2, mut igu, mut igw, mut coa) = (0.0f64, 0.0f64, 0.0f64, 0.0f64);
    for i in 0..20000 {
        let p = (i as f64 + 0.5) * (PI / 2.0) / 20000.0;
        iu2 += p.cos().powi(2) * 2.0 * PI * p.sin();
        igu += p.sin().powi(2) * 2.0 * PI * p.sin();
        igw += 2.0 * p.cos() * p.sin() * 2.0 * PI * p.sin();
        coa += 2.0 * PI * (1.0 - (i as f64 + 0.5) / 20000.0).sqrt();
    }
    let (iu2, igu, igw, coa) = (iu2 * dq, igu * dq, igw * dq, coa / 20000.0);
    println!("proof on the hemisphere: int u^2 {:.6} (2pi/3 {:.6}), int |grad u|^2 {:.6}, ratio {:.6}", iu2, 2.0 * PI / 3.0, igu, igu / iu2);
    println!("  int |grad w| {:.6}, coarea int length dt {:.6}, 2 sqrt(..) {:.6}", igw, coa, 2.0 * (iu2 * igu).sqrt());
    let ab = 2.0 * PI * (1.0 + r0().asin().cos());
    let lt = 2.0 * sj() + NECK;
    let hn = C / ab;
    let ray = (4.0 * C / NECK) / (2.0 * ab + C * NECK / 3.0);
    let lds: Vec<f64> = [2000usize, 4000].iter().map(|&n| lam1_mesh(bell_r, lt, n)).collect();
    println!("dumbbell: bell area {:.6}, neck cut h <= {:.6}, test-function bound {:.6}, C/(2pi) = {:.6}", ab, hn, ray, C / (2.0 * PI));
    println!("dumbbell lambda1 on 2000 and 4000 cells: {:.6}, {:.6}", lds[0], lds[1]);
    println!("  Cheeger: h <= 2 sqrt(lambda1) = {:.6}; no-curvature Buser 10 h^2 <= {:.6} < lambda1", 2.0 * lds[1].sqrt(), 10.0 * hn * hn);
    println!("mistake 1, sphere eigenvalues without multiplicity: {} against Weyl {:.1}", mult.len(), ws);
    let quad = (0..11i64).map(|m| (0..11i64).filter(|n| m * m + n * n <= 100).count()).sum::<usize>();
    println!("mistake 2, torus with m, n >= 0 only: {} against {:.1}", quad, wt);
    let c30 = (PI / 6.0).sin() / (1.0 - (PI / 6.0).cos());
    println!("mistake 3, any cut's ratio as h: 30-degree cap {:.6} gives lambda1 >= {:.6}, but lambda1 = 2", c30, c30 * c30 / 4.0);
    assert!(nt == torus_rows(100) && nt == 317 && ((nt as f64) - wt).abs() < 2.0 * wt.sqrt());
    assert!(mult == (0..11).map(|k| 2 * k + 1).collect::<Vec<i64>>() && ns == 121);
    assert!([1, 2, 3].iter().all(|&k| (-lap_ratio(k) - (k * (k + 1)) as f64).abs() < 1e-5));
    assert!((lam1_mesh(sphere_r, PI, 400) - 2.0).abs() < 1e-4 && (hs - 1.0).abs() < 1e-9);
    assert!((igu / iu2 - 2.0).abs() < 1e-6 && (igw - coa).abs() < 1e-4 && hs * iu2 <= igw && igw <= 2.0 * (iu2 * igu).sqrt());
    assert!(lds[1] <= ray + 1e-6 && (lds[1] - lds[0]).abs() < 1e-4 && 10.0 * hn * hn < lds[1]);
    println!("ALL CHECKS PASS");
}
