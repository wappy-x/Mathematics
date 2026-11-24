// Differential-algebraic equations: index 1 (an RC circuit), index 2 and 3 (a prescribed path), index 3 (a pendulum).
const A: [[f64; 2]; 2] = [[5.0 / 12.0, -1.0 / 12.0], [3.0 / 4.0, 1.0 / 4.0]]; // Radau IIA, two stages
const C: [f64; 2] = [1.0 / 3.0, 1.0];
const G: f64 = 9.81;
fn e(x: f64) -> String { format!("{:.3e}", x) }
fn solve(m: Vec<Vec<f64>>, b: Vec<f64>) -> Vec<f64> { // Gaussian elimination with partial pivoting
    let n = b.len();
    let mut m: Vec<Vec<f64>> = m.into_iter().enumerate().map(|(i, mut r)| { r.push(b[i]); r }).collect();
    for k in 0..n {
        let mut p = k;
        for i in k..n { if m[i][k].abs() > m[p][k].abs() { p = i; } }; m.swap(k, p);
        for i in k + 1..n {
            let f = m[i][k] / m[k][k];
            for j in 0..=n { m[i][j] -= f * m[k][j]; }
        }
    }
    let mut x = vec![0.0; n];
    for i in (0..n).rev() {
        let s: f64 = (i + 1..n).map(|j| m[i][j] * x[j]).sum();
        x[i] = (m[i][n] - s) / m[i][i];
    }
    x
}

fn ytrue(t: f64) -> f64 { (1.0 - (-2.0 * t).exp()) / 2.0 }
fn be(n: usize) -> (f64, f64) {
    let h = 1.0 / n as f64;
    let (mut y, mut z) = (0.0, 0.0);
    for _ in 0..n {
        let s = solve(vec![vec![1.0 + h, -h], vec![1.0, 1.0]], vec![y, 1.0]); y = s[0]; z = s[1];
    }
    (y, z)
}

fn bdf2(n: usize) -> f64 {
    let h = 1.0 / n as f64;
    let (mut y0, mut y1) = (0.0, ytrue(h));
    for _ in 0..n - 1 {
        let y2 = solve(vec![vec![1.5 + h, -h], vec![1.0, 1.0]], vec![2.0 * y1 - 0.5 * y0, 1.0])[0];
        y0 = y1; y1 = y2;
    }
    y1
}
fn radau(n: usize) -> f64 {
    let h = 1.0 / n as f64;
    let mut y = 0.0;
    for _ in 0..n {
        let mut m = Vec::new();
        for i in 0..2 {
            let d = |j: usize| if i == j { 1.0 } else { 0.0 };
            m.push(vec![d(0) + h * A[i][0], d(1) + h * A[i][1], -h * A[i][0], -h * A[i][1]]);
        }
        m.push(vec![1.0, 0.0, 1.0, 0.0]); m.push(vec![0.0, 1.0, 0.0, 1.0]);
        y = solve(m, vec![y, y, 1.0, 1.0])[1];
    }
    y
}
fn path2(n: usize, method: &str) -> f64 {
    let h = 1.0 / n as f64;
    let (mut y, mut z) = (0.0, 0.0);
    for k in 0..n {
        let t = k as f64 * h;
        if method == "BE" {
            z = ((t + h).sin() - y) / h;
        } else {
            let m = vec![vec![h * A[0][0], h * A[0][1]], vec![h * A[1][0], h * A[1][1]]];
            z = solve(m, vec![(t + C[0] * h).sin() - y, (t + C[1] * h).sin() - y])[1];
        }
        y = (t + h).sin();
    }
    z - 1.0f64.cos()
}
fn rhs(s: &[f64; 4], gam: f64) -> [f64; 4] {
    let (x1, x2, v1, v2) = (s[0], s[1], s[2], s[3]);
    let r2 = x1 * x1 + x2 * x2;
    let num = v1 * v1 + v2 * v2 - G * x2 + 2.0 * gam * (x1 * v1 + x2 * v2) + gam * gam * (r2 - 1.0) / 2.0;
    let mu = num / r2;
    [v1, v2, -mu * x1, -mu * x2 - G]
}
fn run(h: f64, t_end: f64, gam: f64, proj: bool, every: usize) -> (f64, f64, Vec<f64>) {
    let mut s = [1.0, 0.0, 0.0, 0.0];
    let (mut out, mut worst, mut err) = (Vec::new(), 0.0f64, 0.0);
    let add = |s: &[f64; 4], k: &[f64; 4], c: f64| { let mut r = [0.0; 4]; for i in 0..4 { r[i] = s[i] + c * k[i]; } r };
    for n in 1..=((t_end / h).round() as usize) {
        let k1 = rhs(&s, gam); let k2 = rhs(&add(&s, &k1, h / 2.0), gam);
        let k3 = rhs(&add(&s, &k2, h / 2.0), gam); let k4 = rhs(&add(&s, &k3, h), gam);
        for i in 0..4 { s[i] = s[i] + h / 6.0 * (k1[i] + 2.0 * k2[i] + 2.0 * k3[i] + k4[i]); }
        if proj {
            let r = (s[0] * s[0] + s[1] * s[1]).sqrt(); s[0] /= r; s[1] /= r;
            let d = s[0] * s[2] + s[1] * s[3]; s[2] -= d * s[0]; s[3] -= d * s[1];
        }
        err = (s[0] * s[0] + s[1] * s[1]).sqrt() - 1.0; worst = worst.max(err.abs());
        if every > 0 && n % every == 0 { out.push(err); }
    }
    (err, worst, out)
}

fn main() {
    println!("circuit: y' = -y + z, 0 = y + z - 1, y(0) = 0 (y volts, z milliamps, t seconds)");
    println!("index 1: dg/dz = {:.3}, nonzero; consistent start z(0) = 1 - y(0) = {:.3}", 1.0, 1.0 - 0.0);
    println!("true y(1) = (1 - e^-2)/2 = {:.9}", ytrue(1.0));
    let (yb, zb) = be(10); let yr = radau(10);
    let cf_be = 0.5 * (1.0 - 1.2f64.powi(-10));
    let r = |z: f64| (1.0 + z / 3.0) / (1.0 - 2.0 * z / 3.0 + z * z / 6.0);
    let cf_r = 0.5 * (1.0 - r(-0.2).powi(10));
    let f1 = solve(vec![vec![1.1, -0.1], vec![1.0, 1.0]], vec![0.0, 1.0]);
    println!("h = 0.1: BE first step y = {:.5}, z = {:.5}; factor on y - 0.5 per step 1/1.2 = {:.5}", f1[0], f1[1], 1.0 / 1.2);
    println!("h = 0.1: BE y(1) = {:.5}, z(1) = {:.5}, closed form 0.5(1 - 1.2^-10) = {:.5}", yb, zb, cf_be);
    println!("h = 0.1: Radau IIA y(1) = {:.8}, closed form 0.5(1 - R(-0.2)^10) = {:.8}, R(-0.2) = {:.8}", yr, cf_r, r(-0.2));
    assert!((yb - cf_be).abs() < 1e-14 && (zb - (1.0 - cf_be)).abs() < 1e-14);
    assert!((yr - cf_r).abs() < 1e-14);
    println!("true error in y(1)   N=10        N=20        N=40        N=80     order");
    let ns = [10, 20, 40, 80];
    let methods: [(&str, fn(usize) -> f64, f64); 3] = [("BE", |n| be(n).0, 1.0), ("BDF2", bdf2, 2.0), ("Radau IIA", radau, 3.0)];
    for (name, f, p) in methods {
        let errs: Vec<f64> = ns.iter().map(|&n| f(n) - ytrue(1.0)).collect();
        let q = (errs[2] / errs[3]).abs().log2();
        let cols: Vec<String> = errs.iter().map(|&x| format!("{:>10}", e(x))).collect();
        println!("{:>9}  {}  {:.3}", name, cols.join("  "), q);
        assert!((q - p).abs() < 0.05);
    }
    let mut yd = vec![0.0, 0.9];
    for _ in 0..10 { yd = solve(vec![vec![1.1, -0.1], vec![-0.1, 1.1]], yd); }
    println!("z(0) = 0.9 instead of 1: DAE form by BE y(1) = {:.5}; differentiated form y(1) = {:.5}, y + z = {:.5}", be(10).0, yd[0], yd[0] + yd[1]);
    assert!((yd[0] - 0.9 * cf_be).abs() < 1e-14 && (yd[0] + yd[1] - 0.9).abs() < 1e-14);
    println!("index 2 path, error in z(1)   N=10        N=20        N=40        N=80     order");
    for (name, p) in [("BE", 1.0), ("Radau IIA", 2.0)] {
        let errs: Vec<f64> = ns.iter().map(|&n| path2(n, name)).collect();
        let q = (errs[2] / errs[3]).abs().log2();
        let cols: Vec<String> = errs.iter().map(|&x| format!("{:>10}", e(x))).collect();
        println!("{:>9}{}{}  {:.3}", name, " ".repeat(18), cols.join("  "), q);
        assert!((q - p).abs() < 0.05);
    }
    let (h, mut z1): (f64, f64) = (0.01, 0.0);
    for w0 in [1.0, 0.0] {
        let w1 = (h.sin() - 0.0) / h; z1 = (w1 - w0) / h;
        println!("index 3 path, BE, w(0) = {:.1}: z(0.01) = {:.4}, true {:.4}", w0, z1, -h.sin());
    }
    assert!((z1 - 1.0 / h).abs() < 0.01);
    let s0 = [0.6, -0.8, 1.5, 1.125];
    let lev2 = |mu: f64| s0[2] * s0[2] + s0[3] * s0[3] + s0[0] * (-mu * s0[0]) + s0[1] * (-mu * s0[1] - G);
    println!("pendulum: d/dmu of G = 0, of G' = 0, of G'' = {:.3}: mu appears after 2 differentiations, index 3", lev2(1.0) - lev2(0.0));
    assert!(((lev2(1.0) - lev2(0.0)) + 1.0).abs() < 1e-12);
    println!("length error at 20 s    h = 0.05     h = 0.02     h = 0.01");
    let mut rows: Vec<Vec<f64>> = Vec::new();
    for (name, gam, proj) in [("index-1 form", 0.0, false), ("Baumgarte 5/s", 5.0, false), ("projection, max", 0.0, true)] {
        let row: Vec<f64> = [0.05, 0.02, 0.01].iter().map(|&h| { let o = run(h, 20.0, gam, proj, 0); if proj { o.1 } else { o.0 } }).collect();
        let cols: Vec<String> = row.iter().map(|&x| format!("{:>11}", e(x))).collect();
        println!("{:>15}  {}", name, cols.join("  "));
        rows.push(row);
    }
    let q = (rows[0][1] / rows[0][2]).abs().log2();
    println!("index-1 form drift falls by 2^{:.2} when h halves (RK4 order 4)", q);
    assert!((q - 4.0).abs() < 0.2 && rows[2][1] < 1e-15 && rows[1][1].abs() < 1e-6);
    let naive = run(0.02, 20.0, 0.0, false, 100).2; let bg = run(0.02, 20.0, 5.0, false, 0).1;
    println!("h = 0.02, t = 2..20 s, length error in mm:");
    let v: Vec<String> = naive.iter().map(|&x| format!("{:.3}", -1000.0 * x)).collect();
    println!("  index-1 form: {}", v.join(", "));
    println!("  Baumgarte, largest size over all steps: {} m", e(bg));
    let v: Vec<String> = (1..=10).map(|k| { let f = k as f64 / 10.0; format!("{:.3}", -1000.0 * naive[9] * f * f) }).collect();
    println!("  t^2 guide:    {}", v.join(", "));
    println!("drift ratio 20 s / 10 s: {:.3} (t^2 predicts 4)", naive[9] / naive[4]);
    assert!((naive[9] / naive[4] - 4.0).abs() < 0.1);
    for gam in [150.0, 125.0] {                   // past RK4's linear edge, then inside it
        let (x, e1) = (0.02 * gam, run(0.02, 1.0, gam, false, 0).0);
        println!("Baumgarte {:.0}/s at h = 0.02: h*gam = {:.2}, RK4's linear factor {:.3} (edge at 2.785); length error at 1 s = {}", gam, x, 1.0 - x + x * x / 2.0 - x.powi(3) / 6.0 + x.powi(4) / 24.0, e(e1));
        assert!(e1.abs() > 1.0);
    }
    println!("ALL CHECKS PASS");
}
