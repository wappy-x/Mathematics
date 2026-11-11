// Semidefinite programs -- the same check as the Python, in Rust.  No crates.
// Eigenvalues come from Jacobi rotations written out below; no linear-algebra library.
use std::f64::consts::PI;
type M = Vec<Vec<f64>>;

fn eig(a0: &M) -> (Vec<f64>, M) {                 // Jacobi: rotate away off-diagonal entries
    let n = a0.len();
    let mut a = a0.clone();
    let mut v: M = (0..n).map(|i| (0..n).map(|j| if i == j { 1.0 } else { 0.0 }).collect()).collect();
    for _ in 0..100 {
        let mut off = 0.0;
        for i in 0..n { for j in 0..n { if i != j { off += a[i][j] * a[i][j]; } } }
        if off < 1e-30 { break; }
        for p in 0..n {
            for q in p + 1..n {
                if a[p][q] == 0.0 { continue; }
                let th = (a[q][q] - a[p][p]) / (2.0 * a[p][q]);
                let t = (if th >= 0.0 { 1.0 } else { -1.0 }) / (th.abs() + (th * th + 1.0).sqrt());
                let c = 1.0 / (t * t + 1.0).sqrt();
                let s = t * c;
                for k in 0..n { let (x, y) = (a[k][p], a[k][q]); a[k][p] = c * x - s * y; a[k][q] = s * x + c * y; }
                for k in 0..n { let (x, y) = (a[p][k], a[q][k]); a[p][k] = c * x - s * y; a[q][k] = s * x + c * y; }
                for k in 0..n { let (x, y) = (v[k][p], v[k][q]); v[k][p] = c * x - s * y; v[k][q] = s * x + c * y; }
            }
        }
    }
    ((0..n).map(|i| a[i][i]).collect(), v)
}

fn psd_part(a: &M) -> M {                         // nearest PSD matrix: clip negative eigenvalues to zero
    let (w, v) = eig(a);
    let n = a.len();
    (0..n).map(|i| (0..n).map(|j| (0..n).map(|k| w[k].max(0.0) * v[i][k] * v[j][k]).sum()).collect()).collect()
}

fn dist(a: &M, b: &M) -> f64 {
    let n = a.len();
    (0..n).flat_map(|i| (0..n).map(move |j| (i, j))).map(|(i, j)| (a[i][j] - b[i][j]).powi(2)).sum::<f64>().sqrt()
}
fn quad(a: &M, w: &[f64]) -> f64 { let n = a.len(); (0..n).flat_map(|i| (0..n).map(move |j| (i, j))).map(|(i, j)| w[i] * a[i][j] * w[j]).sum() }
fn show(label: &str, v: f64) { println!("{:<44} {:.6}", label, if v.abs() < 5e-10 { 0.0 } else { v }); }
fn corr(x: f64, y: f64, z: f64) -> M { vec![vec![1.0, x, y], vec![x, 1.0, z], vec![y, z, 1.0]] }
fn min_eig(a: &M) -> f64 { eig(a).0.into_iter().fold(f64::INFINITY, f64::min) }
fn shift(c: &M, th: &[f64]) -> M { (0..3).map(|i| (0..3).map(|j| c[i][j] + if i == j { th[i] } else { 0.0 }).collect()).collect() }
fn unit_diag(p: &M) -> M { let d: Vec<f64> = (0..3).map(|i| p[i][i].sqrt()).collect(); (0..3).map(|i| (0..3).map(|j| p[i][j] / (d[i] * d[j])).collect()).collect() }

fn repair(c: &M, tol: f64) -> (M, Vec<f64>, usize) {
    let (mut nu, mut k) = (vec![0.0; 3], 0);
    let mut x: M;
    loop {                                        // cap at 1000, so a broken update fails an assert instead of hanging
        x = psd_part(&shift(c, &nu));
        let g: Vec<f64> = (0..3).map(|i| 1.0 - x[i][i]).collect();
        if k >= 1000 || g.iter().fold(0.0f64, |m, v| m.max(v.abs())) < tol { break; }
        for i in 0..3 { nu[i] += g[i]; } k += 1;
    }
    (unit_diag(&x), nu, k)
}

fn higham(c: &M, dykstra: f64) -> (M, usize) {
    let (mut y, mut ds, mut it) = (c.clone(), vec![vec![0.0; 3]; 3], 0);
    while it < 1000 {
        let r: M = (0..3).map(|i| (0..3).map(|j| y[i][j] - ds[i][j]).collect()).collect();
        let p = psd_part(&r);
        ds = (0..3).map(|i| (0..3).map(|j| (p[i][j] - r[i][j]) * dykstra).collect()).collect();
        let ynew: M = (0..3).map(|i| (0..3).map(|j| if i == j { 1.0 } else { p[i][j] }).collect()).collect();
        it += 1;
        let done = dist(&ynew, &y) < 1e-12; y = ynew;
        if done { break; }
    }
    (y, it)
}

fn main() {
    // ---- the broken matrix: UK-Europe 0.9, UK-property 0.2, Europe-property 0.9 ----
    let c = corr(0.9, 0.2, 0.9);
    let mut lam = eig(&c).0; lam.sort_by(|a, b| a.partial_cmp(b).unwrap());
    let mix = [1.0, -1.0, 1.0];
    show("eigenvalue, smallest", lam[0]); show("eigenvalue, middle", lam[1]); show("eigenvalue, largest", lam[2]);
    show("variance of long UK, short Europe, long property", quad(&c, &mix));
    show("  in pounds squared, 100000 each at 20% vol", quad(&c, &mix) * 20000.0f64.powi(2));
    let (x, y) = (0.9f64, 0.2f64);
    let s = [[1.0 - x * x, y - x * x], [y - x * x, 1.0 - x * x]];     // Schur complement, pivot on Europe
    show("Schur complement corner 1 - x^2", s[0][0]); show("Schur complement off-corner y - x^2", s[0][1]);
    show("det of Schur complement", s[0][0] * s[1][1] - s[0][1].powi(2));
    let det3 = 1.0 + 2.0 * x * y * x - 2.0 * x * x - y * y;
    show("det of C by cofactors", det3); show("product of eigenvalues", lam[0] * lam[1] * lam[2]);
    show("least UK-property allowed, 2x^2 - 1", 2.0 * x * x - 1.0);

    // ---- road 1: dual ascent, nu <- nu + (1 - diag((C + Diag nu)+)), from nu = 0 ----
    let (xm, nu, k) = repair(&c, 1e-10);
    let zero = vec![vec![0.0; 3]; 3];
    let primal = 0.5 * dist(&xm, &c).powi(2);
    let dual = 0.5 * dist(&c, &zero).powi(2) + nu.iter().sum::<f64>() - 0.5 * dist(&psd_part(&shift(&c, &nu)), &zero).powi(2);
    println!("road 1 dual ascent: {} steps to max |1 - diag| < 1e-10", k);
    show("  repaired UK-Europe = Europe-property", xm[0][1]); show("  repaired UK-property", xm[0][2]);
    show("  multiplier nu, UK and property", nu[0]); show("  multiplier nu, Europe", nu[1]);
    show("  distance moved, Frobenius", dist(&xm, &c)); show("  smallest eigenvalue after repair", min_eig(&xm));
    show("  primal half-distance^2 minus dual bound", primal - dual);

    // ---- road 2: Higham's alternating projections with Dykstra's correction ----
    let (ym, it) = higham(&c, 1.0);
    println!("road 2 Dykstra projections: {} rounds", it); show("  repaired UK-Europe", ym[0][1]); show("  repaired UK-property", ym[0][2]);

    // ---- road 3: on the boundary y = 2x^2 - 1, minimise 4(x-0.9)^2 + 2(y-0.2)^2: root of 4x^3 - 1.4x - 0.9 ----
    let (mut lo, mut hi) = (0.0f64, 1.0f64);
    for _ in 0..80 {
        let mid = (lo + hi) / 2.0;
        if 4.0 * mid.powi(3) - 1.4 * mid - 0.9 < 0.0 { lo = mid; } else { hi = mid; }
    }
    let _ = hi;
    show("road 3 boundary root x", lo); show("  y = 2x^2 - 1", 2.0 * lo * lo - 1.0);
    show("variance of the same mix, repaired", quad(&xm, &mix));
    show("  its risk in pounds", 20000.0 * quad(&xm, &mix).sqrt());

    // ---- what breaks ----
    let pc = psd_part(&c);
    show("wrong: clip only, diagonal UK", pc[0][0]); show("wrong: clip only, diagonal Europe", pc[1][1]);
    let rc = unit_diag(&pc);
    show("wrong: clip then rescale, UK-Europe", rc[0][1]); show("wrong: clip then rescale, distance", dist(&rc, &c));
    let bad = vec![vec![-1.0, 1.0], vec![1.0, 0.0]];
    show("negative pivot: d - b^2/a", bad[1][1] - bad[0][1] * bad[0][1] / bad[0][0]); show("  yet smallest eigenvalue", min_eig(&bad));
    println!("figure, C ({:.2}, {:.2}); X* ({:.4}, {:.4}); clip-rescale ({:.4}, {:.4})", x, y, xm[0][1], xm[0][2], rc[0][1], rc[0][2]);

    // ---- max-cut on a ring of five assets: edges i -- i+1 ----
    let e: Vec<(usize, usize)> = (0..5).map(|i| (i, (i + 1) % 5)).collect();
    let cuts: Vec<usize> = (0..32u32).map(|m| e.iter().filter(|&&(i, j)| (m >> i & 1) != (m >> j & 1)).count()).collect();
    let best = *cuts.iter().max().unwrap();
    println!("max-cut by listing all 32 sign patterns: {} edges, reached by {} patterns", best, cuts.iter().filter(|&&c| c == best).count());
    let mut v: M = (0..5).map(|i| { let u = [1.0, i as f64, (i * i) as f64]; let n = u.iter().map(|b| b * b).sum::<f64>().sqrt(); u.iter().map(|a| a / n).collect() }).collect();
    let dot = |v: &M, i: usize, j: usize| (0..3).map(|t| v[i][t] * v[j][t]).sum::<f64>();
    let val = |v: &M| e.iter().map(|&(i, j)| (1.0 - dot(v, i, j)) / 2.0).sum::<f64>();
    let (mut mv, mut sweeps) = (1.0f64, 0);
    while mv > 1e-12 && sweeps < 1000 {                // stop when no vector moves more than 1e-12
        mv = 0.0; sweeps += 1;
        for i in 0..5 {
            let s: Vec<f64> = (0..3).map(|t| -(v[(i + 4) % 5][t] + v[(i + 1) % 5][t])).collect();
            let nrm = s.iter().map(|a| a * a).sum::<f64>().sqrt();
            for t in 0..3 { mv = mv.max((s[t] / nrm - v[i][t]).abs()); }
            v[i] = s.iter().map(|a| a / nrm).collect();
        }
    }
    let xc: M = (0..5).map(|i| (0..5).map(|j| dot(&v, i, j)).collect()).collect();
    let yd: Vec<f64> = (0..5).map(|i| (2.0 - xc[i][(i + 4) % 5] - xc[i][(i + 1) % 5]) / 4.0).collect();
    let lq: M = (0..5).map(|i| (0..5).map(|j| (if i == j { yd[i] } else { 0.0 })
        - (if i == j { 0.5 } else if (j + 5 - i) % 5 == 1 || (j + 5 - i) % 5 == 4 { -0.25 } else { 0.0 })).collect()).collect();
    let sdp = val(&v); let ysum: f64 = yd.iter().sum();
    println!("SDP by mixing sweeps: {} sweeps", sweeps); show("  SDP value, upper bound on every cut", sdp);
    show("  neighbour inner product v_i.v_j", xc[0][1]); show("  dual bound, sum of u_i", ysum);
    show("  smallest eigenvalue of Diag(u) - L/4", min_eig(&lq)); show("  closed form 2.5(1 + cos(pi/5))", 2.5 * (1.0 + (PI / 5.0).cos()));
    let expct: f64 = e.iter().map(|&(i, j)| xc[i][j].clamp(-1.0, 1.0).acos() / PI).sum();
    let r = [1.0, 0.5, 0.25];
    let side: Vec<bool> = (0..5).map(|i| (0..3).map(|t| v[i][t] * r[t]).sum::<f64>() > 0.0).collect();
    let alpha = (1..=100000).map(|t| { let a = t as f64 / 1e5 * PI; 2.0 * a / (PI * (1.0 - a.cos())) }).fold(f64::INFINITY, f64::min);
    show("expected cut, random hyperplane", expct);
    println!("cut from hyperplane (1, 0.5, 0.25): {} edges", e.iter().filter(|&&(i, j)| side[i] != side[j]).count());
    show("ratio best cut / SDP bound", best as f64 / sdp); show("guarantee constant alpha", alpha);
    println!("try: stop at 1e-4, steps {}", repair(&c, 1e-4).2);
    let c7 = corr(0.9, 0.7, 0.9); show("try: UK-property 0.7, distance moved", dist(&repair(&c7, 1e-10).0, &c7));
    let (y0, _) = higham(&c, 0.0); show("try: no Dykstra correction, UK-Europe", y0[0][1]); show("try: no Dykstra correction, distance", dist(&y0, &c));

    assert!(lam[0] < 0.0 && (det3 - lam[0] * lam[1] * lam[2]).abs() < 1e-12);            // Schur/cofactor vs eigenvalues
    assert!((xm[0][1] - ym[0][1]).abs() < 1e-7 && (xm[0][2] - ym[0][2]).abs() < 1e-7);   // road 1 vs road 2
    assert!((xm[0][1] - lo).abs() < 1e-7 && (xm[0][2] - (2.0 * lo * lo - 1.0)).abs() < 1e-7); // road 1 vs road 3
    assert!((primal - dual).abs() < 1e-9 && min_eig(&xm) > -1e-12);                        // certificate, both sides
    assert!(dist(&rc, &c) > dist(&xm, &c) + 1e-3);                                         // rescaling is not nearest
    assert!(min_eig(&lq) > -1e-9);                                                         // max-cut SDP certificate
    assert!((sdp - 2.5 * (1.0 + (PI / 5.0).cos())).abs() < 1e-9 && best == 4);           // mixing vs closed form
    println!("ALL CHECKS PASS");
}
