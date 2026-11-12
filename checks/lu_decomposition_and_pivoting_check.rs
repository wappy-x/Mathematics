// LU with partial pivoting on a small water network, solved for six demand patterns.
// std only. Prints the same lines as the Python check.
// Unknowns: heads h1, h2 (m) at junctions J1, J2; flows q1, q2, q3 (L/s) in pipes
// pipe 1 (reservoir to J1), pipe 2 (J1 to J2), pipe 3 (reservoir to J2). Rows: J1, J2, pipes 1 to 3.
const H: f64 = 60.0;
const R1: f64 = 0.1;
const R2: f64 = 0.3;
const R3: f64 = 0.4;
const ROWS: [&str; 5] = ["J1", "J2", "pipe 1", "pipe 2", "pipe 3"];
type M = Vec<Vec<f64>>;

fn sci(x: f64) -> String { format!("{:.2e}", x) }
fn comma(k: u64) -> String {
    let s = k.to_string(); let mut out = String::new();
    for (i, c) in s.chars().enumerate() { if i > 0 && (s.len() - i) % 3 == 0 { out.push(','); } out.push(c); }
    out
}
fn network(leak: f64) -> M {
    vec![vec![-leak, 0.0, 1.0, -1.0, 0.0], vec![0.0, -leak, 0.0, 1.0, 1.0],
         vec![1.0, 0.0, R1, 0.0, 0.0], vec![-1.0, 1.0, 0.0, R2, 0.0], vec![0.0, 1.0, 0.0, 0.0, R3]]
}
fn rhs(d1: f64, d2: f64) -> Vec<f64> { vec![d1, d2, H, 0.0, H] }

// returns packed L and U (None on a zero pivot), row order, growth or failing step, flops, swaps
fn lu(a: &M, pivot: bool) -> (Option<M>, Vec<usize>, f64, u64, u32) {
    let n = a.len(); let mut w = a.clone(); let mut perm: Vec<usize> = (0..n).collect();
    let amax = a.iter().flatten().fold(0.0f64, |m, v| m.max(v.abs()));
    let (mut big, mut flops, mut swaps) = (amax, 0u64, 0u32);
    for k in 0..n {
        if pivot {
            let mut m = k;
            for i in k + 1..n { if w[i][k].abs() > w[m][k].abs() { m = i; } }
            if m != k { w.swap(k, m); perm.swap(k, m); swaps += 1; }
        }
        if w[k][k] == 0.0 { return (None, perm, (k + 1) as f64, flops, swaps); }
        for i in k + 1..n {
            w[i][k] /= w[k][k]; flops += 1;
            for j in k + 1..n {
                w[i][j] -= w[i][k] * w[k][j]; flops += 2;
                big = big.max(w[i][j].abs());
            }
        }
    }
    (Some(w), perm, big / amax, flops, swaps)
}
fn solve(lu: &M, perm: &[usize], b: &[f64]) -> (Vec<f64>, u64) {
    let n = b.len(); let mut flops = 0; let mut y: Vec<f64> = perm.iter().map(|&p| b[p]).collect();
    for i in 0..n { for j in 0..i { y[i] -= lu[i][j] * y[j]; flops += 2; } }
    for i in (0..n).rev() {
        for j in i + 1..n { y[i] -= lu[i][j] * y[j]; flops += 2; }
        y[i] /= lu[i][i]; flops += 1;
    }
    (y, flops)
}
fn nodal(leak: f64, d1: f64, d2: f64) -> Vec<f64> {
    let (c1, c2, c3) = (1.0 / R1, 1.0 / R2, 1.0 / R3);
    let (a, b, c, d) = (c1 + c2 + leak, -c2, -c2, c2 + c3 + leak);
    let (e, f) = (c1 * H - d1, c3 * H - d2);
    let h1 = (e * d - b * f) / (a * d - b * c); let h2 = (a * f - c * e) / (a * d - b * c);
    vec![h1, h2, (H - h1) / R1, (h1 - h2) / R2, (H - h2) / R3]
}
fn looped(d1: f64, d2: f64) -> Vec<f64> {
    let q2 = (R3 * d2 - R1 * d1) / (R1 + R2 + R3); let (q1, q3) = (d1 + q2, d2 - q2);
    vec![H - R1 * q1, H - R3 * q3, q1, q2, q3]
}
fn det(m: &M) -> f64 {
    if m.len() == 1 { return m[0][0]; }
    let mut s = 0.0;
    for j in 0..m.len() {
        if m[0][j] == 0.0 { continue; }
        let minor: M = m[1..].iter().map(|r| r.iter().enumerate().filter(|(c, _)| *c != j).map(|(_, v)| *v).collect()).collect();
        s += if j % 2 == 0 { 1.0 } else { -1.0 } * m[0][j] * det(&minor);
    }
    s
}
fn matvec(a: &M, x: &[f64]) -> Vec<f64> { a.iter().map(|r| r.iter().zip(x).fold(0.0, |s, (a, v)| s + a * v)).collect() }
fn inf(v: &[f64]) -> f64 { v.iter().fold(0.0f64, |m, t| m.max(t.abs())) }
fn err(x: &[f64], y: &[f64]) -> f64 { x.iter().zip(y).fold(0.0f64, |m, (a, b)| m.max((a - b).abs())) }
fn norm_a(a: &M) -> f64 { inf(&a.iter().map(|r| r.iter().fold(0.0, |s, v| s + v.abs())).collect::<Vec<_>>()) }
fn resid(a: &M, b: &[f64], x: &[f64]) -> Vec<f64> { b.iter().zip(matvec(a, x)).map(|(bi, ai)| bi - ai).collect() }

fn trial(leak: f64, pivot: bool) -> (Vec<f64>, f64, f64, f64) {
    let a = network(leak); let b = rhs(20.0, 30.0); let (w, perm, g, _, _) = lu(&a, pivot);
    let x = solve(&w.unwrap(), &perm, &b).0;
    let eta = inf(&resid(&a, &b, &x)) / (norm_a(&a) * inf(&x));
    let e = err(&x, &nodal(leak, 20.0, 30.0));
    (x, e, g, eta)
}

fn wilkinson(nw: usize) -> (u32, f64, f64) { // 1 on the diagonal, -1 below it, 1 down the last column
    let wk: M = (0..nw).map(|i| (0..nw).map(|j| if i == j || j == nw - 1 { 1.0 } else if i > j { -1.0 } else { 0.0 }).collect()).collect();
    let xt: Vec<f64> = (0..nw).map(|i| ((7 * i) % 11) as f64 / 10.0 - 0.5).collect();
    let (lw, pw, gw, _, sw) = lu(&wk, true);
    (sw, gw, err(&solve(&lw.unwrap(), &pw, &matvec(&wk, &xt)).0, &xt))
}

fn main() {
    let a = network(0.0); let n = a.len();
    let (w, perm, growth, f_lu, swaps) = lu(&a, true); let w = w.unwrap();
    println!("row order after pivoting   {}   swaps {}", perm.iter().map(|&p| ROWS[p]).collect::<Vec<_>>().join(", "), swaps);
    for i in 0..n {
        let l: String = (0..n).map(|j| format!("{:6.2}", if j < i { w[i][j] } else if j == i { 1.0 } else { 0.0 } + 0.0)).collect();
        let u: String = (0..n).map(|j| format!("{:6.2}", if j >= i { w[i][j] } else { 0.0 } + 0.0)).collect();
        println!("L{} {}    U{} {}", i + 1, l, i + 1, u);
    }
    let mut du = 1.0; for k in 0..n { du *= w[k][k]; }
    let sign = if swaps % 2 == 0 { 1.0 } else { -1.0 };
    println!("det A = (-1)^{} x product of pivots = {:.4}   cofactor {:.4}   growth {:.2}", swaps, sign * du, det(&a), growth);
    assert!((sign * du - det(&a)).abs() < 1e-12, "PA = LU determinant against cofactor expansion");
    for i in 0..n { for j in 0..n {
        let s: f64 = (0..n).fold(0.0, |s, k| s + (if k < i { w[i][k] } else if k == i { 1.0 } else { 0.0 }) * (if k <= j { w[k][j] } else { 0.0 }));
        assert!((a[perm[i]][j] - s).abs() < 1e-15, "L times U must rebuild PA");
    } }
    assert!(lu(&vec![vec![1.0, 2.0], vec![-3.0, 4.0]], true).1 == vec![1, 0], "pivot by size: the -3 below the 1 is chosen");

    println!("{:<11}{:>5}{:>5}{:>8}{:>8}{:>7}{:>7}{:>7}   vs nodal   vs loop", "pattern", "d1", "d2", "h1 m", "h2 m", "q1", "q2", "q3");
    let pats = [("night", 8.0, 12.0), ("morning", 20.0, 30.0), ("midday", 12.0, 18.0),
                ("evening", 24.0, 36.0), ("weekend", 16.0, 20.0), ("fire at J2", 12.0, 50.0)];
    let mut f_solve = 0;
    for &(name, d1, d2) in pats.iter() {
        let (x, f) = solve(&w, &perm, &rhs(d1, d2)); f_solve = f;
        let (e2, e3) = (err(&x, &nodal(0.0, d1, d2)), err(&x, &looped(d1, d2)));
        println!("{:<11}{:5.0}{:5.0}{:8.2}{:8.2}{:7.2}{:7.2}{:7.2}   {}  {}", name, d1, d2, x[0], x[1], x[2], x[3], x[4], sci(e2), sci(e3));
        assert!(e2 < 1e-12 && e3 < 1e-12, "LU against the nodal and loop roads");
        assert!(inf(&resid(&a, &rhs(d1, d2), &x)) < 1e-12, "residual");
    }
    let xm = solve(&w, &perm, &rhs(20.0, 30.0)).0;
    println!("morning y = Ux: {}", (0..n).map(|i| format!("{:.2}", (i..n).fold(0.0, |s, j| s + w[i][j] * xm[j]))).collect::<Vec<_>>().join(" "));
    let (e_, f_, s_) = (|n: u64| (4 * n * n * n + 9 * n * n - 7 * n) / 6, |n: u64| (4 * n * n * n - 3 * n * n - n) / 6, |n: u64| 2 * n * n - n);
    assert!(f_lu == f_(5) && f_solve == s_(5), "counted flops against the formulas");
    println!("flops n = 5: factor {} (formula {}), each solve {} (formula {}); six patterns: reuse {}, refactor {}", f_lu, f_(5), f_solve, s_(5), f_(5) + 6 * s_(5), 6 * e_(5));
    let nn = 500u64; let inv = f_(nn) + nn * s_(nn);
    println!("flops n = 500: factor {}, each solve {}; six patterns: reuse {}, refactor {}, ratio {:.2}", comma(f_(nn)), comma(s_(nn)), comma(f_(nn) + 6 * s_(nn)), comma(6 * e_(nn)), (6 * e_(nn)) as f64 / (f_(nn) + 6 * s_(nn)) as f64);
    println!("flops n = 500: inverse first {}, {:.2} times the factorisation; one more pattern costs {:.2}% of it", comma(inv), inv as f64 / f_(nn) as f64, s_(nn) as f64 / f_(nn) as f64 * 100.0);

    let ainv: M = (0..n).map(|j| solve(&w, &perm, &(0..n).map(|i| if i == j { 1.0 } else { 0.0 }).collect::<Vec<_>>()).0).collect();
    let kappa = norm_a(&a) * (0..n).map(|i| (0..n).fold(0.0, |s, j| s + ainv[j][i].abs())).fold(0.0f64, f64::max);
    println!("kappa_inf(A) = {:.2}", kappa);
    let step = lu(&a, false).2;
    println!("no pivoting, no leak: zero pivot at step {}", step);
    for piv in [false, true] {
        let (x, e, g, eta) = trial(1e-14, piv);
        println!("leak 1e-14, pivoting {}: q1 {:.6}  vs nodal {}  growth {}  backward error {}", if piv { "on " } else { "off" }, x[2], sci(e), sci(g), sci(eta));
        assert!((e < 1e-12) == piv, "pivoting fixes it");
        if !piv {
            println!("  relative error {} <= kappa x backward error {}, ratio {:.1}", sci(e / inf(&x)), sci(kappa * eta), kappa * eta / (e / inf(&x)));
            assert!(e / inf(&x) <= kappa * eta, "forward error bounded by kappa times backward error");
        }
    }
    let gam = 3.0 * n as f64 * 2f64.powi(-53) / (1.0 - 3.0 * n as f64 * 2f64.powi(-53)); let (eta_on, g_off) = (trial(1e-14, true).3, trial(1e-14, false).2);
    println!("bound gamma_15 x n^2 x g: pivoting on {}, {:.0} times the backward error; off {}", sci(gam * (n * n) as f64), gam * (n * n) as f64 / eta_on, sci(gam * (n * n) as f64 * g_off));
    assert!(eta_on <= gam * (n * n) as f64, "backward error within the theorem's bound");
    let x_nop = solve(&w, &(0..n).collect::<Vec<_>>(), &rhs(20.0, 30.0)).0;
    println!("wrong: b not reordered: h1 {:.2}  h2 {:.2}  q1 {:.2}  q2 {:.2}  q3 {:.2}", x_nop[0], x_nop[1], x_nop[2], x_nop[3], x_nop[4]);

    let ks: Vec<i32> = (1..16).collect();
    let row = |piv: bool| -> Vec<f64> { ks.iter().map(|&k| trial(1.0 / 10f64.powi(k), piv).1.max(1e-16).log10()).collect() };
    let (off, on) = (row(false), row(true));
    println!("chart, -log10 leak     {}", ks.iter().map(|k| format!("{:5}", k)).collect::<Vec<_>>().join(" "));
    println!("chart, log10 gap, off  {}", off.iter().map(|v| format!("{:5.1}", v)).collect::<Vec<_>>().join(" "));
    println!("chart, log10 gap, on   {}", on.iter().map(|v| format!("{:5.1}", v)).collect::<Vec<_>>().join(" "));
    assert!(off[14] > -1.0 && on.iter().cloned().fold(f64::MIN, f64::max) < -12.0, "unpivoted error grows as the leak shrinks; pivoted does not");

    let (sw, gw, ew) = wilkinson(60);
    println!("Wilkinson n = 60: swaps {}, growth {} = 2^59 {}, error {:.2}", sw, sci(gw), sci(2f64.powi(59)), ew);
    assert!(gw == 2f64.powi(59) && ew > 0.1, "growth 2^(n-1) defeats partial pivoting");
    println!("try: leak 1e-8, pivoting off: error {}; Wilkinson n = 40: growth {}, error {}", sci(trial(1e-8, false).1), sci(wilkinson(40).1), sci(wilkinson(40).2));
    println!("try: n = 2,000: factor {}, each solve {}, solves per factorisation {}", comma(f_(2000)), comma(s_(2000)), comma(f_(2000) / s_(2000)));
    println!("ALL CHECKS PASS");
}
