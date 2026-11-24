// Numerical range and spectral gap -- the same check as the Python, in Rust.  No crates.
// Complex numbers are a small struct.  Eigenvalues, norms, exponentials and the heat
// flow are written out here; nothing in std already knows an answer.
use std::f64::consts::PI;

#[derive(Clone, Copy)] struct C { re: f64, im: f64 }
fn c(re: f64, im: f64) -> C { C { re, im } }
fn cm(a: C, b: C) -> C { c(a.re * b.re - a.im * b.im, a.re * b.im + a.im * b.re) }
fn ca(a: C, b: C) -> C { c(a.re + b.re, a.im + b.im) }
fn size(z: C) -> f64 { (z.re * z.re + z.im * z.im).sqrt() }
type M2 = [[C; 2]; 2];
fn cx(a: [[f64; 2]; 2]) -> M2 { [[c(a[0][0], 0.0), c(a[0][1], 0.0)], [c(a[1][0], 0.0), c(a[1][1], 0.0)]] }
fn f6(t: f64) -> String { format!("{:.6}", t) }
fn ip(x: [C; 2], y: [C; 2]) -> C {                    // <x, y>, conjugating the first slot
    (0..2).fold(c(0.0, 0.0), |s, k| ca(s, cm(c(x[k].re, -x[k].im), y[k])))
}
fn mul(t: &M2, x: [C; 2]) -> [C; 2] {                 // T x for a complex 2 x 2 matrix
    [ca(cm(t[0][0], x[0]), cm(t[0][1], x[1])), ca(cm(t[1][0], x[0]), cm(t[1][1], x[1]))]
}
fn avg(t: &M2, x: [C; 2]) -> C {                      // the average <x, Tx> / <x, x>
    let (q, n) = (ip(x, mul(t, x)), ip(x, x).re);
    c(q.re / n, q.im / n)
}
fn unit(al: f64, ph: f64) -> [C; 2] { [c(al.cos(), 0.0), c(al.sin() * ph.cos(), al.sin() * ph.sin())] }
fn sample(t: &M2) -> Vec<C> {                         // averages over a grid of 361 x 360 unit vectors
    (0..361).flat_map(|k| (0..360).map(move |m| avg(t, unit(k as f64 * PI / 720.0, m as f64 * PI / 180.0)))).collect()
}
fn top(t: &M2, th: f64) -> f64 {                      // top eigenvalue of the Hermitian part of e^(i th) T
    let e = c(th.cos(), th.sin());
    let m = [[cm(e, t[0][0]), cm(e, t[0][1])], [cm(e, t[1][0]), cm(e, t[1][1])]];
    let (a, d) = (m[0][0].re, m[1][1].re);
    let (br, bi) = ((m[0][1].re + m[1][0].re) / 2.0, (m[0][1].im - m[1][0].im) / 2.0);
    (a + d) / 2.0 + (((a - d) / 2.0).powi(2) + br * br + bi * bi).sqrt()
}
fn norm(a: [[f64; 2]; 2]) -> f64 {                    // largest stretch of a real 2 x 2: power iteration on A^T A
    let mut v = [1.0, 0.3];
    for _ in 0..400 {
        let w = [a[0][0] * v[0] + a[0][1] * v[1], a[1][0] * v[0] + a[1][1] * v[1]];
        v = [a[0][0] * w[0] + a[1][0] * w[1], a[0][1] * w[0] + a[1][1] * w[1]];
        let s = (v[0] * v[0] + v[1] * v[1]).sqrt(); v = [v[0] / s, v[1] / s];
    }
    let w = [a[0][0] * v[0] + a[0][1] * v[1], a[1][0] * v[0] + a[1][1] * v[1]];
    (w[0] * w[0] + w[1] * w[1]).sqrt()
}
fn lap(u: &[f64]) -> Vec<f64> {                       // grid heat operator on M cells, insulated ends
    let m = u.len();
    (0..m).map(|j| (m * m) as f64 * ((if j > 0 { u[j - 1] } else { u[0] }) - 2.0 * u[j]
        + (if j < m - 1 { u[j + 1] } else { u[m - 1] }))).collect()
}
fn sum(v: &[f64]) -> f64 { v.iter().fold(0.0, |s, t| s + t) }
fn spread(u: &[f64]) -> f64 {                         // distance from the average, sqrt(h * sum of squares)
    let m = sum(u) / u.len() as f64;
    (u.iter().fold(0.0, |s, t| s + (t - m).powi(2)) / u.len() as f64).sqrt()
}
const A: [[f64; 2]; 2] = [[-1.0, 6.0], [0.0, -2.0]];
fn exp_a(t: f64) -> [[f64; 2]; 2] { [[(-t).exp(), 6.0 * ((-t).exp() - (-2.0 * t).exp())], [0.0, (-2.0 * t).exp()]] }
fn taylor(t: f64) -> [[f64; 2]; 2] {                  // sum of (tA)^k / k!, 60 terms
    let (mut s, mut p) = ([[1.0, 0.0], [0.0, 1.0]], [[1.0, 0.0], [0.0, 1.0]]);
    for k in 1..60 {
        let mut q = [[0.0; 2]; 2];
        for i in 0..2 { for j in 0..2 { q[i][j] = (0.0 + p[i][0] * A[0][j] + p[i][1] * A[1][j]) * t / k as f64 } }
        p = q;
        for i in 0..2 { for j in 0..2 { s[i][j] += p[i][j] } }
    }
    s
}

fn main() {
    let (n, b, q) = ([[0.0, 1.0], [0.0, 0.0]], [[1.0, 2.0], [0.0, -1.0]], [[0.0, -1.0], [1.0, 0.0]]);
    let (nc, bc) = (cx(n), cx(b));
    let w_n = sample(&nc).iter().map(|&z| size(z)).fold(f64::MIN, f64::max);
    let n_n = norm(n);
    let sup: Vec<f64> = (0..360).map(|k| top(&nc, k as f64 * PI / 180.0)).collect();
    let (smin, smax) = (sup.iter().cloned().fold(f64::MAX, f64::min), sup.iter().cloned().fold(f64::MIN, f64::max));
    let hit = avg(&nc, unit((2.0 * size(c(0.3, 0.2))).asin() / 2.0, 0.2f64.atan2(0.3)));
    let res = norm([[1.0, 1.0], [0.0, 1.0]]);
    let gold = (1.0 + 5f64.sqrt()) / 2.0;
    println!("N: trace 0 and determinant 0, so l^2 = 0: spectrum {{0}}, spectral radius 0");
    println!("N: largest |<x, Nx>| over 129960 unit vectors: w(N) = {}", f6(w_n));
    println!("N: top of Re(e^(i th) N) over 360 angles: min {}, max {}", f6(smin), f6(smax));
    println!("N: ||N|| = {}; w <= ||N|| <= 2w: {} <= {} <= {}", f6(n_n), f6(w_n), f6(n_n), f6(2.0 * w_n));
    println!("N: the point 0.3 + 0.2i as an average: {} + {}i", f6(hit.re), f6(hit.im));
    println!("N: ||(I - N)^-1|| = {} (golden ratio {}) <= 1/dist(1, W) = {}", f6(res), f6(gold), f6(1.0 / (1.0 - w_n)));
    let ell = (0..8).map(|k| { let th = k as f64 * PI / 4.0;
        (top(&bc, th) - (2.0 * th.cos().powi(2) + th.sin().powi(2)).sqrt()).abs() }).fold(f64::MIN, f64::max);
    let pts = sample(&bc);
    let inside = pts.iter().all(|p| p.re * p.re / 2.0 + p.im * p.im <= 1.0 + 1e-12);
    let (w_b, n_b) = (pts.iter().map(|&z| size(z)).fold(f64::MIN, f64::max), norm(b));
    println!("B: foci 1 and -1, semi-axes {} and {}; largest gap, support against ellipse: {}", f6(2f64.sqrt()), f6(1.0), f6(ell));
    println!("B: all 129960 averages inside the ellipse: {}; w(B) = {}", if inside { "yes" } else { "no" }, f6(w_b));
    println!("B: ||B|| = {} (1 + sqrt 2 = {}); w <= ||B|| <= 2w: {} <= {} <= {}",
             f6(n_b), f6(1.0 + 2f64.sqrt()), f6(w_b), f6(n_b), f6(2.0 * w_b));
    let (x, y) = ([c(1.0, 0.0), c(0.0, 0.0)], [c(0.5f64.sqrt(), 0.0), c(0.0, 0.5f64.sqrt())]);
    let (a, bb) = (avg(&bc, x), avg(&bc, y));        // Step 3's path: T' = (B - aI)/(b - a) runs from 0 to 1
    let e = c(bb.re - a.re, bb.im - a.im);
    let d = c(e.re / (e.re * e.re + e.im * e.im), -e.im / (e.re * e.re + e.im * e.im));
    let mut tp = bc;
    for i in 0..2 { for j in 0..2 { tp[i][j] = cm(if i == j { ca(bc[i][j], c(-a.re, -a.im)) } else { bc[i][j] }, d) } }
    let h = ip(y, mul(&tp, x));
    let g = ca(ip(x, mul(&tp, y)), c(-h.re, h.im));       // 2i <x, (Im T') y>
    let ph = g.im.atan2(g.re);
    let xr = [cm(c(ph.cos(), ph.sin()), x[0]), cm(c(ph.cos(), ph.sin()), x[1])];
    let path = |t: f64| [ca(cm(c(1.0 - t, 0.0), xr[0]), cm(c(t, 0.0), y[0])), ca(cm(c(1.0 - t, 0.0), xr[1]), cm(c(t, 0.0), y[1]))];
    let (mut lo, mut hi) = (0.0, 1.0);
    for _ in 0..60 { let mid = (lo + hi) / 2.0; if avg(&tp, path(mid)).re < 0.5 { lo = mid } else { hi = mid } }
    let mp = avg(&bc, path(lo));
    println!("B: <e1, Be1> = {}, <y, By> = {}i; the path reaches {} + {}i", f6(a.re), f6(bb.im), f6(mp.re), f6(mp.im));
    println!("heat, grid of M cells: gap by power iteration, closed form 4M^2 sin^2(pi/2M), pi^2 - gap, times M^2");
    let mut gaps = Vec::new();
    for m in [4usize, 8, 16, 32, 64] {
        let cc = 4.0 * m as f64 * m as f64;
        let mut v: Vec<f64> = (0..m).map(|j| (j as f64 + 1.0).powi(3)).collect();
        for _ in 0..20000 {                           // power iteration on A + cI, constants projected out
            let mu = sum(&v) / m as f64; v = v.iter().map(|t| t - mu).collect();
            let av = lap(&v); v = av.iter().zip(&v).map(|(p, q)| p + cc * q).collect();
            let s = v.iter().fold(0.0, |s, t| s + t * t).sqrt(); v = v.iter().map(|t| t / s).collect();
        }
        let mu = sum(&v) / m as f64; v = v.iter().map(|t| t - mu).collect();
        let g = -lap(&v).iter().zip(&v).fold(0.0, |s, (p, q)| s + p * q) / v.iter().fold(0.0, |s, t| s + t * t);
        let cf = (4 * m * m) as f64 * (PI / (2.0 * m as f64)).sin().powi(2);
        gaps.push((g, cf, (PI.powi(2) - cf) * m as f64 * m as f64));
        println!("  M = {:2}: {}  {}  {}  {}", m, f6(g), f6(cf), f6(PI.powi(2) - cf), f6((PI.powi(2) - cf) * m as f64 * m as f64));
    }
    println!("  limit pi^2 = {}; the error times M^2 tends to pi^4/12 = {}", f6(PI * PI), f6(PI.powi(4) / 12.0));
    let (mm, dt) = (50usize, 1e-4);
    let mut u: Vec<f64> = (0..mm).map(|j| if j < mm / 2 { 1.0 } else { 0.0 }).collect();
    let (mut rows, mut chart) = (Vec::new(), Vec::new());
    for k in 0..3001usize {
        if k % 500 == 0 { chart.push((spread(&u), 0.5 * ((-PI) * PI * k as f64 * dt).exp())) }
        if k % 100 == 0 && [1, 5, 10, 20, 30].contains(&(k / 100)) { rows.push((k as f64 * dt, spread(&u))) }
        let au = lap(&u); u = u.iter().zip(&au).map(|(p, q)| p + dt * q).collect();
    }
    let g50 = (4 * mm * mm) as f64 * (PI / (2.0 * mm as f64)).sin().powi(2);
    println!("hot left half, cold right half: t, grid M = 50, cosine series, bound 0.5 e^(-pi^2 t)");
    for &(t, gr) in &rows {
        let se = (1..400).step_by(2).fold(0.0, |s, k: i64| s + 2.0 / ((k * k) as f64 * PI * PI) * ((-2 * k * k) as f64 * PI * PI * t).exp()).sqrt();
        println!("  {:.2}  {}  {}  {}", t, f6(gr), f6(se), f6(0.5 * ((-PI) * PI * t).exp()));
        assert!((gr - se).abs() < 2e-3 && se <= 0.5 * ((-PI) * PI * t).exp() && gr <= 0.5 * (-g50 * t).exp() + 1e-12);
    }
    let fmt = |v: Vec<f64>| v.iter().map(|p| format!("{:.4}", p)).collect::<Vec<_>>().join(", ");
    println!("chart, t = 0, 0.05, ..., 0.3, grid: {}", fmt(chart.iter().map(|p| p.0).collect()));
    println!("chart, bound: {}", fmt(chart.iter().map(|p| p.1).collect()));
    let unit_s = 1.0 / 1.1e-4;
    println!("1 m bar, kappa 1.1e-4 m^2/s: time unit {:.1} s; settles by e in {:.1} s, to 1% in {:.1} s",
             unit_s, unit_s / PI.powi(2), unit_s * 100f64.ln() / PI.powi(2));
    let om = (-3.0 + 37f64.sqrt()) / 2.0;
    let om_s = sample(&cx(A)).iter().map(|p| p.re).fold(f64::MIN, f64::max);
    let tay = (0..4).map(|q| (exp_a(0.3)[q / 2][q % 2] - taylor(0.3)[q / 2][q % 2]).abs()).fold(f64::MIN, f64::max);
    let scan: Vec<(f64, f64)> = (0..301).map(|k| (norm(exp_a(k as f64 / 100.0)), k as f64 / 100.0)).collect();
    let pk = scan.iter().cloned().fold((f64::MIN, 0.0), |s, p| if p.0 > s.0 { p } else { s });
    println!("A = [[-1, 6], [0, -2]]: eigenvalues -1, -2; top of Re W: {} closed form, {} sampled", f6(om), f6(om_s));
    println!("A: ||e^(0.3A)|| = {}; spectrum predicts {}; bound e^(0.3 w) = {}", f6(norm(exp_a(0.3))), f6((-0.3f64).exp()), f6((0.3 * om).exp()));
    println!("A: largest ||e^(tA)|| = {} at t = {:.2}; Taylor against closed form {}", f6(pk.0), pk.1, f6(tay));
    let real = (0..1441).map(|k| avg(&cx(q), unit(k as f64 * PI / 720.0, 0.0)).re.abs()).fold(f64::MIN, f64::max);
    let w_q = sample(&cx(q)).iter().map(|&z| size(z)).fold(f64::MIN, f64::max);
    println!("quarter turn Q: trace 0, determinant 1, eigenvalues i and -i; real vectors give at most {}; complex w(Q) = {}", f6(real), f6(w_q));
    println!("figure, left: centre (160, 150), 120 px per unit, W(N) radius {:.1}, norm circle {:.1}; right: centre (470, 150), 100 px per unit, rx {:.1}, ry {:.1}, foci x {:.1} and {:.1}, midpoint ({:.1}, {:.1})",
             120.0 * w_n, 120.0 * n_n, 100.0 * 2f64.sqrt(), 100.0 * 1.0, 470.0 - 100.0 * 1.0, 470.0 + 100.0 * 1.0, 470.0 + 100.0 * mp.re, 150.0 - 100.0 * mp.im);
    assert!((w_n - smax).abs() < 1e-9 && (smin - 0.5).abs() < 1e-9);       // sampling against support
    assert!((n_n - 1.0).abs() < 1e-9 && (n_b - (1.0 + 2f64.sqrt())).abs() < 1e-9); // power iteration, closed form
    assert!((res - gold).abs() < 1e-9 && res <= 1.0 / (1.0 - w_n));          // resolvent bound
    assert!(inside && ell < 1e-12 && (w_b - 2f64.sqrt()).abs() < 1e-9 && w_b <= n_b && n_b <= 2.0 * w_b);
    assert!((mp.re - 0.5).abs() < 1e-9 && (mp.im - 0.5).abs() < 1e-9);      // convexity path
    assert!(gaps.iter().all(|g| (g.0 - g.1).abs() < 1e-6) && (gaps[4].2 - PI.powi(4) / 12.0).abs() < 1e-2);
    assert!((om - om_s).abs() < 1e-4 && tay < 1e-12 && pk.0 > 1.0 && scan.iter().all(|p| p.0 <= (p.1 * om).exp() + 1e-12));
    assert!(real < 1e-15 && (w_q - 1.0).abs() < 1e-9);
    println!("ALL CHECKS PASS");
}
