// Least squares two ways: normal equations against Householder QR, on a quadratic fit
// to 20 kart lap times (illustrative data, in seconds). Standard library only.
// Roads: exact integer arithmetic (Cramer's rule), Householder QR, normal equations
// with Cholesky; kappa of A and of A^T A by one-sided Jacobi on each separately.
const TIMES: [f64; 20] = [61.318, 61.418, 61.327, 61.293, 61.278, 61.133, 61.071, 61.026,
    61.065, 60.965, 60.982, 61.006, 61.020, 61.123, 61.212, 61.180, 61.218, 61.388, 61.188, 61.217];
const LAP0: i64 = 301; const M: usize = 20; // first lap of the stint, laps
const U: f64 = 1.0 / 9007199254740992.0; const S62: f64 = 4611686018427387904.0; // unit roundoff 2^-53; 2^62

fn fe(x: f64, p: usize) -> String { // Python-style e-notation: 1.23e-08
    let s = format!("{:.*e}", p, x);
    let (m, e) = s.split_once('e').unwrap(); let n: i32 = e.parse().unwrap();
    format!("{}e{}{:02}", m, if n < 0 { '-' } else { '+' }, n.abs())
}
fn dot(p: &[f64], q: &[f64]) -> f64 { // plain loop: same rounding in Python and Rust
    let mut t = 0.0;
    for (a, b) in p.iter().zip(q) { t += a * b; } t
}
fn columns(a: i64) -> Vec<Vec<f64>> { // A as three columns: 1, lap, lap^2
    let laps: Vec<f64> = (0..M).map(|i| (a + i as i64) as f64).collect();
    vec![vec![1.0; M], laps.clone(), laps.iter().map(|v| v * v).collect()]
}
fn det3(g: &[[i128; 3]; 3]) -> i128 {
    g[0][0] * (g[1][1] * g[2][2] - g[1][2] * g[2][1]) - g[0][1] * (g[1][0] * g[2][2]
        - g[1][2] * g[2][0]) + g[0][2] * (g[1][0] * g[2][1] - g[1][1] * g[2][0])
}
fn exact(a: i64, times: &[f64]) -> Vec<f64> { // road 1: exact rationals in integers
    let t: Vec<i128> = (0..M).map(|i| (a + i as i64) as i128).collect(); // laps as numbered: new integers
    let yi: Vec<i128> = times.iter().map(|v| (v * 140737488355328.0) as i128).collect(); // x 2^47
    let (mut g, mut h) = ([[0i128; 3]; 3], [0i128; 3]);
    for j in 0..3 {
        for k in 0..3 { g[j][k] = t.iter().map(|v| v.pow((j + k) as u32)).sum(); }
        h[j] = t.iter().zip(&yi).map(|(v, y)| v.pow(j as u32) * y).sum();
    }
    let (d, mut n) = (det3(&g), [0i128; 3]);
    for j in 0..3 {
        let mut gj = g;
        for i in 0..3 { gj[i][j] = h[i]; } n[j] = det3(&gj);
    }
    n.iter().map(|v| *v as f64 / ((d << 47) as f64)).collect()
}
fn back(r: &[[f64; 3]; 3], z: &[f64]) -> Vec<f64> { // solve R x = z from the bottom up
    let mut x = vec![0.0; 3]; for i in (0..3).rev() {
        let mut e = z[i];
        for k in i + 1..3 { e -= r[i][k] * x[k]; } x[i] = e / r[i][i];
    }
    x
}
fn normal(c: &[Vec<f64>], y: &[f64]) -> Vec<f64> { // road 2: A^T A x = A^T b by Cholesky
    let (mut g, mut r) = ([[0.0; 3]; 3], [[0.0; 3]; 3]);
    for j in 0..3 { for k in 0..3 { g[j][k] = dot(&c[j], &c[k]); } }
    for j in 0..3 {
        let mut d = g[j][j];
        for k in 0..j { d -= r[k][j] * r[k][j]; } r[j][j] = d.sqrt();
        for i in j + 1..3 {
            let mut e = g[j][i];
            for k in 0..j { e -= r[k][j] * r[k][i]; } r[j][i] = e / r[j][j];
        }
    }
    let mut z = vec![0.0; 3]; for i in 0..3 { // forward solve R^T z = A^T b
        let mut e = dot(&c[i], y);
        for k in 0..i { e -= r[k][i] * z[k]; } z[i] = e / r[i][i];
    }
    back(&r, &z)
}
fn householder(c: &[Vec<f64>], y: &[f64]) -> Vec<f64> { // road 3: reflect A into a triangle
    let mut w: Vec<Vec<f64>> = c.to_vec();
    w.push(y.to_vec()); // b rides along as a fourth column
    let mut r = [[0.0; 3]; 3];
    for j in 0..3 {
        let nrm = dot(&w[j][j..], &w[j][j..]).sqrt();
        let alpha = if w[j][j] > 0.0 { -nrm } else { nrm };
        let mut v = w[j][j..].to_vec(); v[0] -= alpha;
        let vv = dot(&v, &v);
        for col in w.iter_mut().skip(j) {
            let f = 2.0 * dot(&v, &col[j..]) / vv;
            for i in j..M { col[i] -= f * v[i - j]; }
        }
        for k in j..3 { r[j][k] = w[k][j]; }
    }
    back(&r, &w[3][..3])
}
fn gram_schmidt(c: &[Vec<f64>], y: &[f64]) -> Vec<f64> { // classical, for "what breaks"
    let (mut q, mut r): (Vec<Vec<f64>>, _) = (Vec::new(), [[0.0; 3]; 3]);
    for j in 0..3 {
        let mut v = c[j].clone(); for k in 0..j {
            r[k][j] = dot(&q[k], &c[j]);
            for i in 0..M { v[i] -= r[k][j] * q[k][i]; }
        }
        r[j][j] = dot(&v, &v).sqrt();
        q.push(v.iter().map(|w| w / r[j][j]).collect());
    }
    let z: Vec<f64> = q.iter().map(|qk| dot(qk, y)).collect();
    back(&r, &z)
}
fn sing(cols: &[Vec<f64>]) -> f64 { // one-sided Jacobi: rotate columns until perpendicular
    let mut v = cols.to_vec();
    for _sweep in 0..40 {
        let mut worst: f64 = 0.0;
        for p in 0..3 {
            for q in p + 1..3 {
                let (al, be, ga) = (dot(&v[p], &v[p]), dot(&v[q], &v[q]), dot(&v[p], &v[q]));
                if ga == 0.0 { continue; }
                worst = worst.max(ga.abs() / (al * be).sqrt());
                let ze = (be - al) / (2.0 * ga);
                let t = (if ze >= 0.0 { 1.0 } else { -1.0 }) / (ze.abs() + (1.0 + ze * ze).sqrt());
                let cs = 1.0 / (1.0 + t * t).sqrt(); let sn = cs * t;
                for i in 0..v[p].len() {
                    let (x1, x2) = (v[p][i], v[q][i]);
                    (v[p][i], v[q][i]) = (cs * x1 - sn * x2, sn * x1 + cs * x2);
                }
            }
        }
        if worst < 1e-15 { break; }
    }
    let mut s: Vec<f64> = v.iter().map(|w| dot(w, w).sqrt()).collect(); s.sort_by(f64::total_cmp);
    s[2] / s[0] // largest stretch over smallest: kappa
}
fn scaled(c: &[Vec<f64>]) -> Vec<Vec<f64>> { // each column scaled to length 1
    c.iter().map(|col| { let n = dot(col, col).sqrt(); col.iter().map(|v| v / n).collect() }).collect()
}
fn rel2(xh: &[f64], x: &[f64]) -> f64 { (xh[2] - x[2]).abs() / x[2].abs() } // error in x2
fn rss(c: &[Vec<f64>], x: &[f64]) -> f64 { // residual sum of squares, exact: misses in whole units of 2^-62
    let sx: Vec<i128> = x.iter().map(|v| (v * S62) as i128).collect(); assert!(x.iter().all(|v| (v * S62).fract() == 0.0));
    let q: i128 = (0..M).map(|i| (TIMES[i] * S62) as i128 - sx[0] - sx[1] * c[1][i] as i128 - sx[2] * c[2][i] as i128).map(|r| r * r).sum();
    q as f64 / S62 / S62
}
fn main() {
    let c = columns(LAP0);
    let (xe, xq) = (exact(LAP0, &TIMES), householder(&c, &TIMES));
    let (xn, xg) = (normal(&c, &TIMES), gram_schmidt(&c, &TIMES));
    for (name, x) in [("exact", &xe), ("QR", &xq), ("normal eqns", &xn)] {
        println!("{:<12} x0 {}  x1 {}  x2 {}", name, fe(x[0], 12), fe(x[1], 12), fe(x[2], 12));
    }
    let cs = scaled(&c); let k = sing(&cs);
    let gs: Vec<Vec<f64>> = (0..3).map(|j| (0..3).map(|i| dot(&cs[j], &cs[i])).collect()).collect();
    let kg = sing(&gs); // kappa of A^T A
    let fit: Vec<f64> = (0..M).map(|i| xe[0] + xe[1] * c[1][i] + xe[2] * c[2][i]).collect();
    let tan = rss(&c, &xe).sqrt() / dot(&fit, &fit).sqrt();
    let (eq, en, eg) = (rel2(&xq, &xe), rel2(&xn, &xe), rel2(&xg, &xe));
    println!("kappa(A) {:.1}  kappa(A^T A) {:.1}  kappa(A)^2 {:.1}", k, kg, k * k);
    println!("tan theta {}   u {}", fe(tan, 3), fe(U, 3));
    let (eqs, ens) = ((k + k * k * tan) * U, k * k * U);
    println!("x2 error, QR          {}   estimate (k + k^2 tan)u {}   ratio {:.3}", fe(eq, 2), fe(eqs, 2), eq / eqs);
    println!("x2 error, normal eqns {}   estimate k^2 u {}   ratio {:.3}", fe(en, 2), fe(ens, 2), en / ens);
    println!("normal eqns / QR error {:.0}, about {:.2} digits", en / eq, (en / eq).log10());
    println!("x2 error, classical Gram-Schmidt {}", fe(eg, 2));
    println!("rss, summed exactly: exact fit {:.15}  QR {:.15}  normal {:.15}", rss(&c, &xe), rss(&c, &xq), rss(&c, &xn));
    println!("fastest lap {:.4}, wear 2*x2 {:.4} ms per lap per lap", -xe[1] / (2.0 * xe[2]), 2000.0 * xe[2]);
    let mut bumped = TIMES; bumped[0] = 61.319;
    println!("lap {} timed 1 ms slower: x2 moves {}", LAP0, fe(rel2(&exact(LAP0, &bumped), &xe), 2));
    for m in [20i64, 1000000] { println!("flops m={}: normal {}, Householder {}", m, m * 9 + 9, 18 * m - 18); }
    println!("sweep first lap, centre/half-width, kappa, k^2 u, normal, QR, log10 normal, log10 QR");
    let mut sweep = Vec::new();
    for a in [-9i64, 1, 21, 101, 301] {
        let (ca, x) = (columns(a), exact(a, &TIMES));
        let (kk, e1, e2) = (sing(&scaled(&ca)), rel2(&normal(&ca, &TIMES), &x), rel2(&householder(&ca, &TIMES), &x));
        println!("sweep {:>5} {:>8.2} {:>9.1} {} {} {} {:6.2} {:6.2}", a, (a as f64 + 9.5) / 9.5, kk,
            fe(kk * kk * U, 2), fe(e1, 2), fe(e2, 2), e1.log10(), e2.log10());
        sweep.push((kk, e1, e2));
    }
    assert!((xe[2] - 0.0036196172248804).abs() < 1e-15); // exact x2, pinned to 14 digits
    assert!([-9i64, 1, 21, 101].iter().all(|a| (exact(*a, &TIMES)[2] - xe[2]).abs() < 1e-15)); // same x2, new integers
    assert!(eq < 1e-11 && (0.1..1.0).contains(&(en / ens)) && en / eq > 1e3); // NE near k^2 u; QR 4 digits ahead
    assert!((kg / (k * k) - 1.0).abs() < 1e-6); // kappa(A^T A) = kappa(A)^2
    assert!(sweep[0].1 < 1e-12 && sweep[4].1 > 1e3 * sweep[0].1); // centring rescues it
    assert!((rss(&c, &xn) - rss(&c, &xe)).abs() < 1e-15); // residual hides the loss
    assert!((-xq[1] / (2.0 * xq[2]) + xe[1] / (2.0 * xe[2])).abs() < 1e-9);
    println!("ALL CHECKS PASS");
}
