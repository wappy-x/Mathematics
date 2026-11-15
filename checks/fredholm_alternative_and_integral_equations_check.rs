// Fredholm alternative for the light balance in a long round tunnel, std only.
// Rehearsal: the tunnel as an N-sided prism; form factors by crossed strings; the round tunnel is N -> infinity.
use std::f64::consts::PI;
type Mat = Vec<Vec<f64>>;
const RHO: f64 = 0.8; // paint reflectance
const E0: f64 = 100.0; // lamp output, W/m2
const R: f64 = 2.0; // tunnel radius, m

fn form_factors(n: usize) -> Mat { // F[i][j]: share of light leaving wall i that lands on wall j
    let c: Vec<f64> = (0..=n).map(|k| (k as f64 * PI / n as f64).sin()).collect();
    let mut f = vec![vec![0.0; n]; n];
    for i in 0..n { for j in 0..n {
        let m = (j + n - i) % n;
        if m > 0 { f[i][j] = (2.0 * c[m] - c[m + 1] - c[m - 1]) / (2.0 * c[1]); }
    } }
    f
}
fn eliminate(m0: &Mat) -> (usize, Mat) { // row reduction with partial pivoting; rank and reduced rows
    let mut m = m0.clone();
    let (rows, cols) = (m.len(), m[0].len());
    let mut rank = 0;
    for col in 0..cols {
        if rank == rows { break; }
        let mut p = rank;
        for r in rank..rows { if m[r][col].abs() > m[p][col].abs() { p = r; } }
        if m[p][col].abs() < 1e-9 { continue; }
        m.swap(rank, p);
        for r in 0..rows { if r != rank {
            let f = m[r][col] / m[rank][col];
            let piv = m[rank].clone();
            for (a, b) in m[r].iter_mut().zip(piv.iter()) { *a -= f * b; }
        } }
        rank += 1;
    }
    (rank, m)
}
fn augment(a: &Mat, b: &[f64]) -> Mat {
    a.iter().zip(b).map(|(row, v)| { let mut r = row.clone(); r.push(*v); r }).collect()
}
fn solve(a: &Mat, b: &[f64]) -> Vec<f64> { // a square and invertible
    let (rank, m) = eliminate(&augment(a, b));
    assert!(rank == a.len());
    (0..a.len()).map(|i| m[i][a.len()] / m[i][i]).collect()
}
fn minus(f: &Mat, s: f64) -> Mat { // the matrix I - s F
    let n = f.len();
    (0..n).map(|i| (0..n).map(|j| (if i == j { 1.0 } else { 0.0 }) - s * f[i][j]).collect()).collect()
}
fn transpose(m: &Mat) -> Mat { (0..m[0].len()).map(|j| m.iter().map(|r| r[j]).collect()).collect() }
fn null_vector(m: &Mat) -> Vec<f64> { // one-dimensional null space: fix the first entry at 1
    let n = m.len();
    let mut a: Mat = m[..n - 1].to_vec();
    let mut e = vec![0.0; n]; e[0] = 1.0; a.push(e);
    let mut b = vec![0.0; n]; b[n - 1] = 1.0;
    solve(&a, &b)
}
fn quarter(v: &[f64], k: usize) -> f64 { // average over quarter k: 0 ceiling, 1 and 3 sides, 2 floor
    let q = v.len() / 4;
    v[k * q..(k + 1) * q].iter().sum::<f64>() / q as f64
}
fn lam(n: f64) -> f64 { 1.0 / (1.0 - 4.0 * n * n) } // round kernel |sin((x - y)/2)|/4 on cos(n x)
fn arc_avg(n: f64, a: f64, b: f64) -> f64 { ((n * b).sin() - (n * a).sin()) / (n * (b - a)) }
fn rank_pair(f: &Mat, q: &[f64]) -> (usize, usize) {
    (eliminate(&minus(f, 1.0)).0, eliminate(&augment(&minus(f, 1.0), q)).0)
}

fn main() {
    println!("Round tunnel, radius 2 m; the top quarter of the wall emits 100 W/m2 (illustrative)");
    let f4 = form_factors(4);
    println!("N=4 form factors: next wall {:.6}, opposite wall {:.6}, row sum {:.6}", f4[0][1], f4[0][2], f4[0].iter().sum::<f64>());
    assert!((f4[0][1] - (1.0 - 1.0 / 2f64.sqrt())).abs() < 1e-12 && (f4[0][2] - (2f64.sqrt() - 1.0)).abs() < 1e-12);
    println!("round kernel eigenvalues: n=0 {:.6}, n=1 {:.6}, n=2 {:.6}", lam(0.0), lam(1.0), lam(2.0));
    println!("Painted walls, rho = 0.8: quarter averages of radiosity B, W/m2");
    let ns = [4usize, 8, 16, 32, 64, 128];
    let (mut floors, mut gaps) = (vec![], vec![]);
    for &n in &ns {
        let f = form_factors(n);
        let e: Vec<f64> = (0..n).map(|i| if i < n / 4 { E0 } else { 0.0 }).collect();
        let b = solve(&minus(&f, RHO), &e);
        let ang = |k: usize, m: usize| 2.0 * PI * k as f64 * m as f64 / n as f64;
        let mu: Vec<f64> = (0..n).map(|k| (0..n).map(|m| f[0][m] * ang(k, m).cos()).sum()).collect();
        let ec: Vec<f64> = (0..n).map(|k| (0..n).map(|m| e[m] * ang(k, m).cos()).sum::<f64>() / n as f64).collect();
        let es: Vec<f64> = (0..n).map(|k| (0..n).map(|m| e[m] * ang(k, m).sin()).sum::<f64>() / n as f64).collect();
        let b2: Vec<f64> = (0..n).map(|i| (0..n).map(|k| (ec[k] * ang(k, i).cos() + es[k] * ang(k, i).sin()) / (1.0 - RHO * mu[k])).sum()).collect();
        assert!(b.iter().zip(&b2).all(|(x, y)| (x - y).abs() < 1e-9)); // road 2: the eigenmodes
        assert!(((1.0 - RHO) * b.iter().sum::<f64>() - e.iter().sum::<f64>()).abs() < 1e-9); // absorbed = emitted
        floors.push(quarter(&b, 2));
        println!("N={:<4} floor {:.4} ceiling {:.4} mean {:.4}  mu1 {:.6} mu2 {:.6}", n, quarter(&b, 2), quarter(&b, 0), b.iter().sum::<f64>() / n as f64, mu[1], mu[2]);
    }
    let (mut fl, mut ce) = (E0 * RHO / (1.0 - RHO) / 4.0, E0 + E0 * RHO / (1.0 - RHO) / 4.0);
    for k in 1..4000 {
        let n = k as f64;
        let en = 2.0 * E0 * (n * PI / 4.0).sin() / (n * PI);
        let g = en * RHO * lam(n) / (1.0 - RHO * lam(n));
        fl += g * arc_avg(n, 3.0 * PI / 4.0, 5.0 * PI / 4.0);
        ce += g * arc_avg(n, -PI / 4.0, PI / 4.0);
    }
    println!("round floor {:.4} ceiling {:.4} mean {:.4}  (eigen series)", fl, ce, E0 / 4.0 / (1.0 - RHO));
    let errs: Vec<f64> = floors.iter().map(|x| x - fl).collect();
    assert!((0..5).all(|k| errs[k + 1] / errs[k] > 0.2 && errs[k + 1] / errs[k] < 0.3)); // error falls like 1/N^2
    println!("log10 N: {} | log10 floor error: {}", ns.iter().map(|&n| format!("{:.3}", (n as f64).log10())).collect::<Vec<_>>().join(" "), errs.iter().map(|x| format!("{:.3}", x.log10())).collect::<Vec<_>>().join(" "));
    let (mut b, e) = (vec![0.0; 4], [E0, 0.0, 0.0, 0.0]);
    let gap = E0 / (1.0 + RHO * (2f64.sqrt() - 1.0)); // by hand: ceiling row minus floor row
    for _ in 0..200 { // road 3: bounce by bounce, B <- E + rho F B
        b = (0..4).map(|i| e[i] + RHO * (0..4).map(|j| f4[i][j] * b[j]).sum::<f64>()).collect();
    }
    assert!((b[2] - floors[0]).abs() < 1e-9 && (b[0] - b[2] - gap).abs() < 1e-9);
    println!("N=4 after 200 bounces: floor {:.4}, side {:.4}, ceiling minus floor {:.4} = by hand {:.4}", b[2], b[1], b[0] - b[2], gap);
    println!("White walls, (I - K) J = q with q the net output of each wall, W/m2");
    for &n in &ns {
        let (f, q4) = (form_factors(n), n / 4);
        let a = null_vector(&transpose(&minus(&f, 1.0))); // adjoint null space
        assert!(a.iter().all(|x| (x - 1.0).abs() < 1e-9));
        let q: Vec<f64> = (0..n).map(|i| if i < q4 { E0 } else if 2 * q4 <= i && i < 3 * q4 { -E0 } else { 0.0 }).collect();
        let (r1, r2) = rank_pair(&f, &q);
        assert!(r1 == n - 1 && r2 == n - 1);
        let mut a1: Mat = minus(&f, 1.0)[..n - 1].to_vec();
        a1.push(vec![1.0; n]);
        let mut rhs = q[..n - 1].to_vec(); rhs.push(0.0);
        let j = solve(&a1, &rhs);
        assert!((j[n - 1] - (0..n).map(|k| f[n - 1][k] * j[k]).sum::<f64>() - q[n - 1]).abs() < 1e-9); // the dropped row holds
        gaps.push(quarter(&j, 0) - quarter(&j, 2));
        println!("N={:<4} rank {} of {}, adjoint null vector all 1s, ceiling minus floor {:.4}", n, r1, n, quarter(&j, 0) - quarter(&j, 2));
    }
    let mut cf = 2.0 * E0;
    for k in (1..4000).step_by(2) {
        let n = k as f64;
        let qn = 4.0 * E0 * (n * PI / 4.0).sin() / (n * PI);
        cf += qn * lam(n) / (1.0 - lam(n)) * (arc_avg(n, -PI / 4.0, PI / 4.0) - arc_avg(n, 3.0 * PI / 4.0, 5.0 * PI / 4.0));
    }
    println!("round ceiling minus floor {:.4}  (eigen series, J_n = q_n / (1 - lambda_n) for n >= 1)", cf);
    assert!((0..5).all(|k| (gaps[k + 1] - cf) / (gaps[k] - cf) > 0.2 && (gaps[k + 1] - cf) / (gaps[k] - cf) < 0.3)); // like 1/N^2
    let qbad = [E0, 0.0, -80.0, 0.0];
    let side = 2.0 * R * (PI / 4.0).sin();
    let (r1, r2) = rank_pair(&f4, &qbad);
    assert!((r1, r2) == (3, 4));
    println!("floor absorbs only 80: N=4 wall {:.4} m, mismatch {:.4} W/m, round {:.4} W/m; rank {} vs {}", side, qbad.iter().sum::<f64>() * side, 20.0 * PI * R / 2.0, r1, r2);
    let (mut j, mut means) = (vec![0.0; 4], vec![]);
    for k in 1..=1000 {
        j = (0..4).map(|i| qbad[i] + (0..4).map(|l| f4[i][l] * j[l]).sum::<f64>()).collect();
        if k == 10 || k == 100 || k == 1000 { means.push(j.iter().sum::<f64>() / 4.0); }
    }
    assert!(means.iter().zip([10.0, 100.0, 1000.0]).all(|(m, k)| (m - 5.0 * k).abs() < 1e-6));
    println!("mean J after 10, 100, 1000 bounces: {}", means.iter().map(|m| format!("{:.1}", m)).collect::<Vec<_>>().join(" "));
    let (w, h) = (4.0f64, 3.0f64); // square-cornered corridor: floor, right wall, ceiling, left wall
    let d = w.hypot(h);
    let s = (w + h - d) / 2.0;
    let fc: Mat = vec![vec![0.0, s / w, (2.0 * d - 2.0 * h) / (2.0 * w), s / w], vec![s / h, 0.0, s / h, (2.0 * d - 2.0 * w) / (2.0 * h)],
        vec![(2.0 * d - 2.0 * h) / (2.0 * w), s / w, 0.0, s / w], vec![s / h, (2.0 * d - 2.0 * w) / (2.0 * h), s / h, 0.0]];
    let ac = null_vector(&transpose(&minus(&fc, 1.0)));
    assert!(ac.iter().zip([w, h, w, h]).all(|(x, y)| (x * w - y).abs() < 1e-9));
    let qc = [0.0, -E0, E0, 0.0];
    let rc = rank_pair(&fc, &qc);
    assert!(rc == (3, 4));
    println!("corridor {:.0} m x {:.0} m: rows of F {:.4} {:.4} | {:.4} {:.4}; adjoint null vector {}", w, h, fc[0][1], fc[0][2], fc[1][0], fc[1][3],
        ac.iter().map(|x| format!("{:.4}", x * w)).collect::<Vec<_>>().join(" "));
    let wsum: f64 = ac.iter().zip(qc).map(|(x, y)| x * w * y).sum();
    println!("q = (0, -100, 100, 0): plain sum {:.1}, width-weighted sum {:.1} W/m; rank {} vs {}", qc.iter().sum::<f64>(), wsum, rc.0, rc.1);
    let mut ratio = 0.0;
    for n in [10usize, 100, 1000, 10000] { // multiply by x on [0, 1]: (I - M_x) u = 1 gives u = 1/(1 - x)
        let norm = ((0..n).map(|i| 1.0 / (1.0 - (i as f64 + 0.5) / n as f64).powi(2)).sum::<f64>() / n as f64).sqrt();
        ratio = norm / (n as f64).sqrt();
        println!("multiply by x, N={:<6} norm of u {:.4}, divided by sqrt(N) {:.4}", n, norm, ratio);
    }
    assert!((ratio - PI / 2f64.sqrt()).abs() < 1e-3);
    println!("figure, radius 160 px = 2 m, square vertex {:.3} {:.3}, octagon vertex {:.3} {:.3}", 210.0 + 160.0 * (PI / 4.0).sin(), 210.0 - 160.0 * (PI / 4.0).cos(), 210.0 + 160.0 * 0f64.sin(), 210.0 - 160.0 * 0f64.cos());
    println!("ALL CHECKS PASS");
}
