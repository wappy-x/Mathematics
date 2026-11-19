// Lie group: a group that is also a smooth manifold -- the same check as the
// Python, in Rust.  No crates.  A drone's orientation is a 3 x 3 rotation matrix
// R, axes north, east, down.  The set of all of them, SO(3), is shown to be a
// group and a smooth 3-dimensional manifold.  The dimension comes by three roads:
// road 1 counts free entries, 9 minus the rank of the constraint's derivative;
// roads 2 and 3 count the independent directions of two different charts.
use std::f64::consts::PI;
type M = Vec<Vec<f64>>;
const D: f64 = PI / 180.0;

fn mul(a: &M, b: &M) -> M {
    (0..a.len()).map(|i| (0..b[0].len()).map(|j| (0..b.len()).map(|k| a[i][k] * b[k][j]).sum()).collect()).collect()
}
fn tp(a: &M) -> M { (0..a[0].len()).map(|j| (0..a.len()).map(|i| a[i][j]).collect()).collect() }
fn eye(n: usize) -> M { (0..n).map(|i| (0..n).map(|j| if i == j { 1.0 } else { 0.0 }).collect()).collect() }
fn rx(a: f64) -> M { vec![vec![1.0, 0.0, 0.0], vec![0.0, a.cos(), -a.sin()], vec![0.0, a.sin(), a.cos()]] }
fn ry(a: f64) -> M { vec![vec![a.cos(), 0.0, a.sin()], vec![0.0, 1.0, 0.0], vec![-a.sin(), 0.0, a.cos()]] }
fn rz(a: f64) -> M { vec![vec![a.cos(), -a.sin(), 0.0], vec![a.sin(), a.cos(), 0.0], vec![0.0, 0.0, 1.0]] }
fn euler(x: &[f64]) -> M { mul(&rz(x[0]), &mul(&ry(x[1]), &rx(x[2]))) }   // chart A: yaw, pitch, roll
fn rodrigues(v: &[f64]) -> M {                                           // chart B: axis times angle
    let t = v.iter().map(|c| c * c).sum::<f64>().sqrt();
    if t == 0.0 { return eye(3); }
    let (x, y, z) = (v[0] / t, v[1] / t, v[2] / t);
    let k = vec![vec![0.0, -z, y], vec![z, 0.0, -x], vec![-y, x, 0.0]];
    let k2 = mul(&k, &k);
    (0..3).map(|i| (0..3).map(|j| (if i == j { 1.0 } else { 0.0 }) + t.sin() * k[i][j] + (1.0 - t.cos()) * k2[i][j]).collect()).collect()
}
fn axis_angle(r: &M) -> Vec<f64> {                // the inverse of chart B, valid for angles below 180 degrees
    let t = ((r[0][0] + r[1][1] + r[2][2] - 1.0) / 2.0).acos();
    let s = 2.0 * t.sin();
    vec![t * (r[2][1] - r[1][2]) / s, t * (r[0][2] - r[2][0]) / s, t * (r[1][0] - r[0][1]) / s]
}
fn det3(a: &M) -> f64 {
    a[0][0] * (a[1][1] * a[2][2] - a[1][2] * a[2][1]) - a[0][1] * (a[1][0] * a[2][2] - a[1][2] * a[2][0])
        + a[0][2] * (a[1][0] * a[2][1] - a[1][1] * a[2][0])
}
fn residual(r: &M) -> f64 {                       // size of R^T R - I, zero exactly on O(n)
    let (p, n) = (mul(&tp(r), r), r.len());
    let mut s = 0.0;
    for i in 0..n { for j in 0..n { let d = p[i][j] - if i == j { 1.0 } else { 0.0 }; s += d * d; } }
    s.sqrt()
}
fn rank(rows: &M) -> usize {                      // Gaussian elimination with partial pivoting
    let (mut m, mut r) = (rows.clone(), 0);
    for c in 0..m[0].len() {
        if r == m.len() { continue; }
        let mut p = r;
        for i in r..m.len() { if m[i][c].abs() > m[p][c].abs() { p = i; } }
        if m[p][c].abs() < 1e-7 { continue; }
        m.swap(r, p);
        for i in r + 1..m.len() {
            let f = m[i][c] / m[r][c];
            let top = m[r].clone();
            for (a, b) in m[i].iter_mut().zip(top.iter()) { *a -= f * b; }
        }
        r += 1;
    }
    r
}
fn constraint_rows(r: &M) -> M {                  // derivative of H -> H^T R + R^T H, one row per entry i <= j
    let n = r.len();
    let mut out = Vec::new();
    for i in 0..n { for j in i..n {
        let mut row = Vec::new();
        for a in 0..n { for b in 0..n {
            row.push(if b == i { r[a][j] } else { 0.0 } + if b == j { r[a][i] } else { 0.0 });
        } }
        out.push(row);
    } }
    out
}
fn chart_columns(chart: fn(&[f64]) -> M, x: &[f64]) -> M {   // central differences, one column per coordinate
    let h = 1e-6;
    (0..3).map(|k| {
        let (mut up, mut dn) = (x.to_vec(), x.to_vec());
        up[k] += h; dn[k] -= h;
        let (a, b) = (chart(&up), chart(&dn));
        (0..9).map(|q| (a[q / 3][q % 3] - b[q / 3][q % 3]) / (2.0 * h)).collect()
    }).collect()
}
fn dot(a: &[f64], b: &[f64]) -> f64 { a.iter().zip(b).map(|(x, y)| x * y).sum() }
fn volume(cols: &M) -> f64 {                      // square root of the Gram determinant
    let g: M = cols.iter().map(|c1| cols.iter().map(|c2| dot(c1, c2)).collect()).collect();
    det3(&g).max(0.0).sqrt()
}
fn f4(x: f64) -> String { format!("{:.4}", if x.abs() < 5e-5 { 0.0 } else { x }) }
fn yn(claim: bool) -> &'static str { if claim { "yes" } else { "no" } }
fn rotation_n(n: usize) -> M {                    // an n-dimensional turn: plane turns in planes (0,1), (1,2), ...
    let mut r = eye(n);
    for k in 0..n - 1 {
        let (mut g, a) = (eye(n), 0.3 + 0.2 * k as f64);
        g[k][k] = a.cos(); g[k][k + 1] = -a.sin(); g[k + 1][k] = a.sin(); g[k + 1][k + 1] = a.cos();
        r = mul(&r, &g);
    }
    r
}
struct SplitMix(u64);                             // SplitMix64, seed 2026, for random orientations
impl SplitMix {
    fn uniform(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
}

fn main() {
    let drone = [30.0 * D, 10.0 * D, 5.0 * D];   // yaw 30, pitch 10 nose up, roll 5 right wing down
    let r0 = euler(&drone);
    for (i, name) in ["north", "east ", "down "].iter().enumerate() {
        println!("R0 row {}: {}", name, (0..3).map(|j| f4(r0[i][j])).collect::<Vec<_>>().join(" "));
    }
    let sq: Vec<f64> = (0..3).map(|i| r0[i][0] * r0[i][0]).collect();
    println!("R0 column 1 squared: {} = {}; column 1 . column 2 = {}", sq.iter().map(|&x| f4(x)).collect::<Vec<_>>().join(" + "),
             f4(sq.iter().sum()), f4((0..3).map(|i| r0[i][0] * r0[i][1]).sum()));
    println!("R0: R^T R - I below 1e-12: {}; det {}", yn(residual(&r0) < 1e-12), f4(det3(&r0)));
    let cam = mul(&r0, &ry(-30.0 * D));           // gimbal tilts the camera 30 degrees down from the nose
    println!("camera = R0 G: R^T R - I below 1e-12: {}; det {}", yn(residual(&cam) < 1e-12), f4(det3(&cam)));
    println!("camera axis below horizon {} deg, heading {} deg", f4(cam[2][0].asin() / D), f4(cam[1][0].atan2(cam[0][0]) / D));
    println!("inverse is the transpose: R0 R0^T - I below 1e-12: {}", yn(residual(&tp(&r0)) < 1e-12));
    let rank1 = rank(&constraint_rows(&r0));
    let road1 = 9 - rank1;
    let v0 = axis_angle(&r0);
    let (ca, cb) = (chart_columns(euler, &drone), chart_columns(rodrigues, &v0));
    println!("road 1: 9 entries - rank {} of the constraint = {}", rank1, road1);
    println!("road 2: rank of chart A (yaw, pitch, roll) at the drone = {}", rank(&ca));
    println!("road 3: rank of chart B (axis-angle) at the drone = {}", rank(&cb));
    println!("chart B point: angle {} deg, rebuilt R0 error below 1e-12: {}",
             f4(dot(&v0, &v0).sqrt() / D), yn(residual(&mul(&tp(&r0), &rodrigues(&v0))) < 1e-12));
    let mut tang: f64 = 0.0;
    for row in constraint_rows(&r0) { for col in ca.iter().chain(cb.iter()) { tang = tang.max(dot(&row, col).abs()); } }
    println!("chart directions obey the constraint's derivative, worst miss below 1e-8: {}", yn(tang < 1e-8));
    let mut rng = SplitMix(2026);
    let mut full = 0;
    for _ in 0..1000 {
        let x = [(2.0 * rng.uniform() - 1.0) * PI, (rng.uniform() - 0.5) * PI, (2.0 * rng.uniform() - 1.0) * PI];
        if rank(&constraint_rows(&euler(&x))) == 6 { full += 1; }
    }
    println!("1000 random orientations with constraint rank 6: {}", full);
    let so: Vec<usize> = [2, 3, 4].iter().map(|&n| n * n - rank(&constraint_rows(&rotation_n(n)))).collect();
    let formula: Vec<usize> = [2usize, 3, 4].iter().map(|&n| n * (n - 1) / 2).collect();
    println!("SO(n) by road 1, n = 2, 3, 4: {:?}; by n(n-1)/2: {:?}", so, formula);
    println!("n = 3: GL {}, O {}, SO {}, U {}, SU {}", 3 * 3, 3 * 2 / 2, 3 * 2 / 2, 3 * 3, 3 * 3 - 1);
    let pitches: Vec<f64> = (0..7).map(|k| 15.0 * k as f64).collect();
    let vols: Vec<f64> = pitches.iter().map(|p| volume(&chart_columns(euler, &[30.0 * D, p * D, 5.0 * D]))).collect();
    println!("chart A volume at level flight {}; 2 sqrt 2 = {}", f4(vols[0]), f4(2.0 * 2f64.sqrt()));
    println!("chart A volume / level, pitch 0..90 by 15: {}", vols.iter().map(|v| f4(v / vols[0])).collect::<Vec<_>>().join(" "));
    println!("cos(pitch), pitch 0..90 by 15:            {}", pitches.iter().map(|p| f4((p * D).cos())).collect::<Vec<_>>().join(" "));
    let lock = [30.0 * D, 90.0 * D, 5.0 * D];
    let (lock_a, lock_b) = (rank(&chart_columns(euler, &lock)), rank(&chart_columns(rodrigues, &axis_angle(&euler(&lock)))));
    println!("mistake 1, all 9 equations of R^T R = I counted: 9 - 9 = {}", 9 - 9);
    println!("mistake 2, pitch 90: chart A rank {}, chart B rank {}", lock_a, lock_b);
    let mirror = vec![vec![1.0, 0.0, 0.0], vec![0.0, 1.0, 0.0], vec![0.0, 0.0, -1.0]];
    println!("mistake 3, mirror diag(1, 1, -1): R^T R - I = {}, det {}", f4(residual(&mirror)), f4(det3(&mirror)));
    let (n0, s0) = (rz(0.0), rz(180.0 * D));
    let avg: M = (0..3).map(|i| (0..3).map(|j| (n0[i][j] + s0[i][j]) / 2.0).collect()).collect();
    println!("mistake 4, north and south headings averaged: det {}, R^T R - I = {}", f4(det3(&avg)), f4(residual(&avg)));
    assert!(road1 == 3 && rank(&ca) == 3 && rank(&cb) == 3);             // three roads, one dimension
    assert!(tang < 1e-8 && full == 1000);                                // charts move along the constraint surface
    assert!(so == formula);                                              // the rank count against the formula
    assert!(vols.iter().zip(&pitches).all(|(v, p)| (v / vols[0] - (p * D).cos()).abs() < 1e-6));
    assert!((vols[0] - 2.0 * 2f64.sqrt()).abs() < 1e-6);                 // finite differences against the closed form
    assert!(lock_a == 2 && det3(&avg).abs() < 1e-12);
    assert!([&r0, &cam, &rotation_n(2), &rotation_n(3), &rotation_n(4)].iter().all(|m| residual(m) < 1e-12));  // all are turns
    assert!((det3(&r0) - 1.0).abs() < 1e-12 && (det3(&cam) - 1.0).abs() < 1e-12);  // det +1, not mirrors
    let [yaw, pitch, roll] = drone;              // R0's nose column and down row against their closed forms
    assert!([r0[0][0] - yaw.cos() * pitch.cos(), r0[1][0] - yaw.sin() * pitch.cos(), r0[2][0] + pitch.sin(), r0[2][1] - pitch.cos() * roll.sin(), r0[2][2] - pitch.cos() * roll.cos()].iter().all(|e| e.abs() < 1e-12));
    println!("ALL CHECKS PASS");
}
