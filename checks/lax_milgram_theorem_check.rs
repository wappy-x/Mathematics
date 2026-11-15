// Lax-Milgram on a loaded cable: the check behind the card. std only.
// Sag u (m) of a 1 m cable: tension T (N), spring bed k (N/m^2), load q (N/m), drift b.
// Form a(u,v) = int(T u'v' + b u'v + k u v), load l(v) = int(q v), norm |v|_V = |v'|_L2.
use std::f64::consts::PI;

const T: f64 = 500.0; const K: f64 = 2000.0; const Q: f64 = 40.0; // illustrative cable numbers

fn thomas(sub: f64, dia: f64, sup: f64, rhs: &[f64]) -> Vec<f64> {
    let n = rhs.len();
    let (mut c, mut d) = (vec![0.0; n], vec![0.0; n]);
    (c[0], d[0]) = (sup / dia, rhs[0] / dia);
    for i in 1..n {
        let m = dia - sub * c[i - 1];
        c[i] = sup / m;
        d[i] = (rhs[i] - sub * d[i - 1]) / m;
    }
    let mut x = vec![0.0; n];
    x[n - 1] = d[n - 1];
    for i in (0..n - 1).rev() {
        x[i] = d[i] - c[i] * x[i + 1];
    }
    x
}

fn matrix(n: usize, t: f64, k: f64, b: f64) -> (f64, f64, f64) {
    let h = 1.0 / n as f64;
    (-t / h + k * h / 6.0 - b / 2.0, 2.0 * t / h + 4.0 * k * h / 6.0, -t / h + k * h / 6.0 + b / 2.0)
}

fn apply(row: (f64, f64, f64), x: &[f64]) -> Vec<f64> {
    let n = x.len();
    (0..n)
        .map(|i| {
            let l = if i > 0 { x[i - 1] } else { 0.0 };
            let r = if i < n - 1 { x[i + 1] } else { 0.0 };
            row.0 * l + row.1 * x[i] + row.2 * r
        })
        .collect()
}

fn vnorm(x: &[f64], n: usize) -> f64 {
    let nf = n as f64;
    x.iter().zip(apply((-nf, 2.0 * nf, -nf), x)).map(|(a, b)| a * b).sum::<f64>().sqrt()
}

fn galerkin(n: usize, t: f64, k: f64, b: f64) -> Vec<f64> {
    let (s, d, p) = matrix(n, t, k, b);
    thomas(s, d, p, &vec![Q / n as f64; n - 1])
}

fn ratio(n: usize, j: usize, t: f64, k: f64) -> f64 {
    let h = 1.0 / n as f64;
    let c = (j as f64 * PI / n as f64).cos();
    t + k * h * h * (2.0 + c) / (6.0 * (1.0 - c))
}

fn exact(x: f64, b: f64) -> f64 {
    let disc = (b * b + 4.0 * T * K).sqrt();
    let (r1, r2) = ((b + disc) / (2.0 * T), (b - disc) / (2.0 * T));
    let a = (-Q / K) * (1.0 - r2.exp()) / (r1.exp() - r2.exp());
    let bb = -Q / K - a;
    Q / K + a * (r1 * x).exp() + bb * (r2 * x).exp()
}

fn py(b: bool) -> &'static str { if b { "True" } else { "False" } }

fn join(v: &[f64], p: usize) -> String {
    v.iter().map(|x| format!("{:.*}", p, x)).collect::<Vec<_>>().join(" ")
}

fn main() {
    let mu = (K / T).sqrt();
    let (c, cc) = (T, T + K / (PI * PI));
    let lnorm = Q / 12f64.sqrt();
    let mid = (Q / K) * (1.0 - 1.0 / (mu / 2.0).cosh());
    let un_closed = (Q / K) * mu * (mu.sinh() / (2.0 * mu) - 0.5).sqrt() / (mu / 2.0).cosh();
    let (n, hh) = (2000usize, 1.0 / 2000.0);
    let du = |x: f64| -(Q / K) * mu * (mu * (x - 0.5)).sinh() / (mu / 2.0).cosh();
    let u = |x: f64| (Q / K) * (1.0 - (mu * (x - 0.5)).cosh() / (mu / 2.0).cosh());
    let simp = |f: &dyn Fn(f64) -> f64| {
        hh / 3.0 * (0..=n).map(|i| {
            let w = if i == 0 || i == n { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 };
            w * f(i as f64 * hh)
        }).sum::<f64>()
    };
    let un_simp = simp(&|x| du(x) * du(x)).sqrt();
    let a_uu = simp(&|x| T * du(x) * du(x) + K * u(x) * u(x));
    let l_u = Q * (Q / K) * (1.0 - (2.0 / mu) * (mu / 2.0).tanh());
    println!("form constants: c = {:.3} N, C = {:.3} N, |l| = {:.6}", c, cc, lnorm);
    println!("size of sag |u|_V: closed {:.6}, Simpson {:.6}, Lax-Milgram bound |l|/c {:.6}", un_closed, un_simp, lnorm / c);
    println!("middle sag: exact {:.6} cm, guaranteed below {:.6} cm", 100.0 * mid, 100.0 * 0.5 * lnorm / c);
    println!("energy balance: a(u,u) = {:.9} J, l(u) = {:.9} J, least energy {:.9} J", a_uu, l_u, -0.5 * l_u);
    let (r4, x4) = (matrix(4, T, K, 0.0), galerkin(4, T, K, 0.0));
    println!("N = 4 matrix: diagonal {:.6}, beside it {:.6}, load per node {:.6} N", r4.1, r4.0, Q / 4.0);
    println!("N = 4 nodes (cm): {:.6} {:.6} {:.6}", 100.0 * x4[0], 100.0 * x4[1], 100.0 * x4[2]);
    println!("  N   c_N (N)     C_N (N)    middle sag cm  error cm    energy J");
    let mut errs = vec![];
    for nn in [4usize, 8, 16, 32, 64] {
        let x = galerkin(nn, T, K, 0.0);
        let e = mid - x[nn / 2 - 1];
        errs.push(e.abs());
        let en = -0.5 * x.iter().sum::<f64>() * Q / nn as f64;
        println!("{:3} {:10.4} {:10.4} {:12.6} {:10.6} {:12.9}", nn, ratio(nn, nn - 1, T, K), ratio(nn, 1, T, K), 100.0 * x[nn / 2 - 1], 100.0 * e, en);
    }
    let mut res: f64 = 0.0; // sine modes really are the extremes: residual of A s - ratio K s
    for nn in [4usize, 16] {
        let nf = nn as f64;
        for j in 1..nn {
            let s: Vec<f64> = (1..nn).map(|i| (j as f64 * PI * i as f64 / nf).sin()).collect();
            let a_s = apply(matrix(nn, T, K, 0.0), &s);
            let k_s = apply((-nf, 2.0 * nf, -nf), &s);
            for (p, q) in a_s.iter().zip(k_s.iter()) {
                res = res.max((p - ratio(nn, j, T, K) * q).abs());
            }
        }
    }
    println!("every sine mode, N = 4 and 16: |A s_j - ratio_j K s_j| below 1e-9: {}", py(res < 1e-9));
    let bd = 1000.0; // drift: a stops being symmetric
    let cb = cc + bd / PI;
    let xb = galerkin(64, T, K, bd);
    let (rho, row) = (c / (cb * cb), matrix(64, T, K, bd)); // Step 5's recipe: x <- x - rho K^-1 (A x - F)
    let (f, mut y, e0, mut it) = (vec![Q / 64.0; 63], vec![0.0; 63], vnorm(&xb, 64), 0);
    for k in 1..400 {
        it = k;
        let r: Vec<f64> = apply(row, &y).iter().zip(f.iter()).map(|(p, q)| p - q).collect();
        let z = thomas(-64.0, 128.0, -64.0, &r);
        y = y.iter().zip(z.iter()).map(|(p, q)| p - rho * q).collect();
        let diff: Vec<f64> = y.iter().zip(xb.iter()).map(|(p, q)| p - q).collect();
        if vnorm(&diff, 64) < 1e-10 * e0 { break; }
    }
    let xax = |r: (f64, f64, f64), v: &[f64]| v.iter().zip(apply(r, v)).map(|(p, q)| p * q).sum::<f64>(); // drift's share of x^T A x
    let share = (xax(row, &xb) - xax(matrix(64, T, K, 0.0), &xb)) / xax(matrix(64, T, K, 0.0), &xb);
    println!("drift b = {:.0}: C = {:.3} N, c still {:.3} N, drift's share of x^T A x below 1e-9: {}", bd, cb, c, py(share.abs() < 1e-9));
    println!("drift middle sag (cm): closed {:.6}, N = 64 {:.6}, iteration {:.6}", 100.0 * exact(0.5, bd), 100.0 * xb[31], 100.0 * y[31]);
    println!("drift sag at 0.25 m (cm): closed {:.6}, N = 64 {:.6}", 100.0 * exact(0.25, bd), 100.0 * xb[15]);
    println!("iteration: {} steps to 1e-10, factor per step at most {:.6}", it, (1.0 - (c / cb).powi(2)).sqrt());
    println!("what breaks, N = 4 / 16 / 64:");
    let ns = [4usize, 16, 64];
    let out: Vec<f64> = ns.iter().map(|&nn| ratio(nn, 1, T, -PI * PI * T)).collect();
    let mids: Vec<f64> = ns.iter().map(|&nn| 100.0 * galerkin(nn, T, -PI * PI * T, 0.0)[nn / 2 - 1]).collect();
    println!("  springs push out: c_N {}; middle cm {}", join(&out, 4), join(&mids, 3));
    let z0: Vec<f64> = ns.iter().map(|&nn| ratio(nn, nn - 1, 0.0, K)).collect();
    let zn: Vec<f64> = ns.iter().map(|&nn| vnorm(&galerkin(nn, 0.0, K, 0.0), nn)).collect();
    println!("  no tension: c_N {}; |u_N|_V {}", join(&z0, 4), join(&zn, 4));
    let l2: Vec<f64> = ns.iter().map(|&nn| {
        let (nf, cs) = (nn as f64, ((nn - 1) as f64 * PI / nn as f64).cos());
        T * 6.0 * (1.0 - cs) * nf * nf / (2.0 + cs) + K
    }).collect();
    println!("  L2 norm: bound C_N {}", join(&l2, 1));
    let lg = |v: &[f64]| join(&v.iter().map(|x| x.log10()).collect::<Vec<_>>(), 4);
    let cn: Vec<f64> = ns.iter().map(|&nn| ratio(nn, nn - 1, T, K)).collect();
    println!("chart, log10 N {}; log10 c_N {} / {} / {}", join(&ns.iter().map(|&nn| (nn as f64).log10()).collect::<Vec<_>>(), 3), lg(&cn), lg(&out), lg(&z0));
    let xs: Vec<f64> = (0..9).map(|i| i as f64 / 8.0).collect();
    println!("chart, x (m)  {}", join(&xs, 3));
    println!("chart, exact  {}", join(&xs.iter().map(|&x| 100.0 * u(x)).collect::<Vec<_>>(), 3));
    let nod = [0.0, x4[0], x4[1], x4[2], 0.0];
    let br: Vec<f64> = (0..9).map(|i| 100.0 * if i % 2 == 0 { nod[i / 2] } else { (nod[i / 2] + nod[i / 2 + 1]) / 2.0 }).collect();
    println!("chart, N = 4  {}", join(&br, 3));
    assert!((un_simp - un_closed).abs() < 1e-9 && un_closed <= lnorm / c && mid < 0.5 * lnorm / c, "two roads, under the bounds");
    assert!((a_uu - l_u).abs() < 1e-9, "energy balance a(u,u) = l(u)");
    assert!((simp(&|x| (Q / 2.0 * (1.0 - 2.0 * x)).powi(2)).sqrt() - lnorm).abs() < 1e-9, "|l| = size of the Riesz representer g");
    assert!(errs[4] < 1e-6 && errs[3] / errs[4] > 3.9 && errs[3] / errs[4] < 4.1, "Galerkin middle sag converges at order 2");
    assert!([4usize, 64].iter().all(|&nn| T < ratio(nn, nn - 1, T, K) && ratio(nn, nn - 1, T, K) < ratio(nn, 1, T, K) && ratio(nn, 1, T, K) < cc) && cc - ratio(64, 1, T, K) < 0.1, "c <= c_N <= C_N <= C, gap closing");
    assert!(res < 1e-9, "sine modes are exact extremes");
    assert!(share.abs() < 1e-9, "drift adds nothing to a(v,v) in the solver's own matrix");
    assert!((xb[31] - exact(0.5, bd)).abs() < 1e-6 && (xb[15] - exact(0.25, bd)).abs() < 1e-6, "drift: closed form against solve, middle and 0.25 m");
    assert!((y[31] - xb[31]).abs() < 1e-12 && it < 399, "drift: the iteration reaches the solve before 400 steps");
    assert!(out[2] < 0.01 * out[0] && zn[2] > 3.0 * zn[0], "both failures: c_N heads to 0");
    println!("ALL CHECKS PASS");
}
