// Gauss, Codazzi and Ricci equations: the check behind the card. Rust std only.
// Curvature of a submanifold = ambient curvature + bending from the second fundamental form II.
// Roads: II from an embedding by finite differences, the metric alone, closed forms, two splits.
use std::f64::consts::PI;

type V = Vec<f64>;
type Emb<'a> = &'a dyn Fn(&[f64]) -> V;
fn sci(x: f64, d: usize) -> String { format!("{:.*e}", d, x) }
fn fx(x: f64, d: usize) -> String {
    let s = format!("{:.*}", d, x);
    if s.starts_with('-') && s[1..].parse::<f64>().unwrap() == 0.0 { s[1..].to_string() } else { s }
}
fn dot(a: &[f64], b: &[f64]) -> f64 { a.iter().zip(b).fold(0.0, |t, (p, q)| t + p * q) }
fn solve(a: &[V], b: &[f64]) -> V { // Gaussian elimination for a small square system
    let n = b.len();
    let mut m: Vec<V> = (0..n).map(|i| { let mut r = a[i].clone(); r.push(b[i]); r }).collect();
    for i in 0..n {
        for k in i + 1..n { let f = m[k][i] / m[i][i]; for j in 0..=n { m[k][j] = m[k][j] - f * m[i][j]; } }
    }
    let mut x = vec![0.0; n];
    for i in (0..n).rev() { x[i] = (m[i][n] - dot(&m[i][i + 1..n], &x[i + 1..])) / m[i][i]; }
    x
}
fn perp(g: &[V], r: &[V], w: &[f64]) -> V { // the part of w at right angles to every tangent arrow
    let b: V = r.iter().map(|ri| dot(w, ri)).collect();
    let c = solve(g, &b);
    (0..w.len()).map(|m| w[m] - dot(&c, &r.iter().map(|ri| ri[m]).collect::<V>())).collect()
}
// metric g_ij, II_ij (normal vectors) and tangent arrows by central differences
fn forms(emb: Emb, x: &[f64], h: f64) -> (Vec<V>, Vec<Vec<V>>, Vec<V>) {
    let n = x.len();
    let at = |s: &[(usize, f64)]| { let mut y = x.to_vec(); for &(k, c) in s { y[k] = x[k] + h * c; } emb(&y) };
    let p0 = at(&[]);
    let r: Vec<V> = (0..n).map(|i| at(&[(i, 1.0)]).iter().zip(at(&[(i, -1.0)])).map(|(a, b)| (a - b) / (2.0 * h)).collect()).collect();
    let g: Vec<V> = (0..n).map(|i| (0..n).map(|j| dot(&r[i], &r[j])).collect()).collect();
    let d2 = |i: usize, j: usize| -> V {
        if i == j {
            let (a, b) = (at(&[(i, 1.0)]), at(&[(i, -1.0)]));
            (0..p0.len()).map(|m| (a[m] - 2.0 * p0[m] + b[m]) / (h * h)).collect()
        } else {
            let q: Vec<V> = [(1.0, 1.0), (1.0, -1.0), (-1.0, 1.0), (-1.0, -1.0)].iter().map(|&(s, t)| at(&[(i, s), (j, t)])).collect();
            (0..p0.len()).map(|m| (q[0][m] - q[1][m] - q[2][m] + q[3][m]) / (4.0 * h * h)).collect()
        }
    };
    let ii = (0..n).map(|i| (0..n).map(|j| perp(&g, &r, &d2(i, j))).collect()).collect();
    (g, ii, r)
}
fn gauss_sec(g: &[V], ii: &[Vec<V>], i: usize, j: usize, amb: f64) -> f64 { // Gauss equation, plane i, j
    let area2 = g[i][i] * g[j][j] - g[i][j] * g[i][j];
    amb + (dot(&ii[i][i], &ii[j][j]) - dot(&ii[i][j], &ii[i][j])) / area2
}
fn norm(a: &[f64]) -> f64 { dot(a, a).sqrt() }
fn frame(emb: Emb, x: &[f64]) -> (V, V) { // orthonormal normal frame by Gram-Schmidt on e1, e3
    let (g, _, r) = forms(emb, x, 1e-5);
    let a = perp(&g, &r, &[1.0, 0.0, 0.0, 0.0]); let a: V = a.iter().map(|t| t / norm(&a)).collect();
    let b = perp(&g, &r, &[0.0, 0.0, 1.0, 0.0]); let d = dot(&b, &a);
    let b: V = b.iter().zip(&a).map(|(t, s)| t - d * s).collect();
    (a.clone(), b.iter().map(|t| t / norm(&b)).collect())
}
fn ricci(emb: Emb, x: &[f64]) -> (f64, f64, f64, Vec<V>, Vec<Vec<V>>) { let h = 1e-3;
    let om = |y: &[f64], i: usize| { // omega_i = <d_i nu1, nu2>, the normal plane's turning rate
        let (mut yp, mut ym) = (y.to_vec(), y.to_vec());
        yp[i] += h; ym[i] -= h;
        let (fp, fm, f0) = (frame(emb, &yp).0, frame(emb, &ym).0, frame(emb, y).1);
        dot(&fp.iter().zip(&fm).map(|(a, b)| (a - b) / (2.0 * h)).collect::<V>(), &f0)
    };
    let sh = |i: usize, s: f64| -> V { (0..2).map(|k| if k == i { x[k] + s * h } else { x[k] }).collect() };
    let rp = (om(&sh(0, 1.0), 1) - om(&sh(0, -1.0), 1) - om(&sh(1, 1.0), 0) + om(&sh(1, -1.0), 0)) / (2.0 * h);
    let (g, ii, _) = forms(emb, x, 1e-3);
    let (n1, n2) = frame(emb, x);
    let am: Vec<Vec<V>> = [&n1, &n2].iter().map(|n| {
        let cols: Vec<V> = (0..2).map(|j| solve(&g, &[dot(&ii[0][j], n), dot(&ii[1][j], n)])).collect();
        (0..2).map(|i| (0..2).map(|j| cols[j][i]).collect()).collect() // column j = A applied to d_j
    }).collect();
    let col = |a: &Vec<V>, j: usize| -> V { (0..2).map(|k| a[k][j]).collect() };
    let c: Vec<V> = (0..2).map(|i| (0..2).map(|j| dot(&am[0][i], &col(&am[1], j)) - dot(&am[1][i], &col(&am[0], j))).collect()).collect();
    let area = (g[0][0] * g[1][1] - g[0][1] * g[0][1]).sqrt(); // per unit area, so it is chart-free
    let cm = dot(&[c[0][0], c[1][0]], &[g[0][1], g[1][1]]) / area;
    (rp / area, cm, gauss_sec(&g, &ii, 0, 1, 0.0), g, ii)
}
const R: f64 = 6371.0; // the globe as a sphere of radius 6371 km
const A: f64 = 6378.137;
fn e2() -> f64 { let fl = 1.0 / 298.257222101; fl * (2.0 - fl) }
fn rho_e(p: f64) -> f64 { A / (1.0 - e2() * p.cos().powi(2)).sqrt() } // east-west radius
fn rho_m(p: f64) -> f64 { A * (1.0 - e2()) / (1.0 - e2() * p.cos().powi(2)).powf(1.5) } // north-south radius
fn eg(p: f64) -> f64 { rho_m(p).powi(2) }
fn gg(p: f64) -> f64 { (rho_e(p) * p.sin()).powi(2) }
fn k_inside(p: f64, h: f64) -> f64 { // Gauss's formula for F = 0 and nothing depending on theta
    let f = |q: f64| (gg(q + h) - gg(q - h)) / (2.0 * h) / (eg(q) * gg(q)).sqrt();
    -(f(p + h) - f(p - h)) / (2.0 * h) / (2.0 * (eg(p) * gg(p)).sqrt())
}
fn codazzi(l: &dyn Fn(f64) -> f64, n: &dyn Fn(f64) -> f64, p: f64) -> f64 { // zero for every real surface
    let h = 1e-4;
    let gp = (gg(p + h) - gg(p - h)) / (2.0 * h);
    (n(p + h) - n(p - h)) / (2.0 * h) - gp / 2.0 * (l(p) / eg(p) + n(p) / gg(p))
}

fn main() {
    let phi = (90.0f64 - 51.5074).to_radians(); // London: polar angle from the North Pole
    let sphere = |x: &[f64]| vec![R * x[0].sin() * x[1].cos(), R * x[0].sin() * x[1].sin(), R * x[0].cos()];
    println!("globe: R = {:.1} km, London phi = {:.4} deg, 1/R = {} per km, target K = 1/R^2 = {} per km^2", R, phi.to_degrees(), sci(1.0 / R, 4), sci(1.0 / (R * R), 4));
    for h in [4e-2, 2e-3, 1e-3] {
        let (g, ii, _) = forms(&sphere, &[phi, 0.3], h);
        let k = gauss_sec(&g, &ii, 0, 1, 0.0);
        println!("  step {}: II/g = {}, {} per km; K = 0 + bending = {}, rel err {}", h, sci(norm(&ii[0][0]) / g[0][0], 4), sci(norm(&ii[1][1]) / g[1][1], 4), sci(k, 4), sci((k * R * R - 1.0).abs(), 1));
        assert!((k * R * R - 1.0).abs() < h * h); // second order: the error falls as the step squared
    }

    // the real globe: the GRS80 ellipsoid at London, where II is no longer a multiple of g
    let e2v = e2();
    let ell = |x: &[f64]| vec![rho_e(x[0]) * x[0].sin() * x[1].cos(), rho_e(x[0]) * x[0].sin() * x[1].sin(), rho_e(x[0]) * (1.0 - e2v) * x[0].cos()];
    let kc = 1.0 / (rho_m(phi) * rho_e(phi));
    println!("GRS80 (a = {:.3} km, 1/f = {:.9}) at London: rho_m = {:.3} km, rho_e = {:.3} km, K = 1/(rho_m rho_e) = {} per km^2", A, 1.0 / (1.0 / 298.257222101), rho_m(phi), rho_e(phi), sci(kc, 4));
    let (g, ii, _) = forms(&ell, &[phi, 0.3], 1e-3);
    let (k1, k2) = (norm(&ii[0][0]) / g[0][0], norm(&ii[1][1]) / g[1][1]);
    let ke = gauss_sec(&g, &ii, 0, 1, 0.0);
    println!("  outside road: kappa_1 = {}, kappa_2 = {} per km, |II_12| = {}, K = {}", sci(k1, 4), sci(k2, 4), fx(norm(&ii[0][1]), 6), sci(ke, 4));
    assert!((k1 * rho_m(phi) - 1.0).abs() < 1e-6 && (ke / kc - 1.0).abs() < 1e-6);
    let errs: V = [2e-3, 1e-3].iter().map(|&h| (k_inside(phi, h) / kc - 1.0).abs()).collect();
    println!("  inside road, metric alone: K = {}; rel err {} then {}", sci(k_inside(phi, 1e-3), 4), sci(errs[0], 1), sci(errs[1], 1));
    assert!(errs[1] < 1e-5 && 3.0 < errs[0] / errs[1] && errs[0] / errs[1] < 5.0);
    println!("  sphere of 6371 km is off by {:.3} percent at London", 100.0 * (1.0 / (R * R) / kc - 1.0));
    let c_ok = codazzi(&rho_m, &|p| gg(p) / rho_e(p), phi); // true II: L = rho_m, N = G / rho_e
    let c_bad = codazzi(&|p| eg(p) / rho_e(p), &|p| gg(p) / rho_m(p), phi);
    println!("  Codazzi residual: true II {} km; radii swapped {:.6} km", fx(c_ok, 6), c_bad);
    assert!(c_ok.abs() < 1e-5 && c_bad.abs() > 1.0);

    // the Clifford torus: flat, inside the round unit 3-sphere, inside 4-space
    let s3 = |x: &[f64]| vec![x[0].cos() * x[1].cos(), x[0].cos() * x[1].sin(), x[0].sin() * x[2].cos(), x[0].sin() * x[2].sin()];
    let (g3, ii3, _) = forms(&s3, &[PI / 4.0, 0.3, 1.1], 1e-4);
    let secs: V = [(0, 1), (0, 2), (1, 2)].iter().map(|&(i, j)| gauss_sec(&g3, &ii3, i, j, 0.0)).collect();
    println!("unit 3-sphere in 4-space (n = 3): sec of the three coordinate planes = {}", secs.iter().map(|s| format!("{:.6}", s)).collect::<Vec<_>>().join(", "));
    assert!(secs.iter().all(|s| (s - 1.0).abs() < 1e-5));
    let s2 = 2.0f64.sqrt();
    let tor = |x: &[f64]| vec![x[0].cos() / s2, x[0].sin() / s2, x[1].cos() / s2, x[1].sin() / s2];
    let pt = [0.3, 1.1]; let p = tor(&pt);
    let (g, ii, _) = forms(&tor, &pt, 1e-4);
    let k4 = gauss_sec(&g, &ii, 0, 1, 0.0);
    let hv: V = (0..4).map(|m| (ii[0][0][m] / g[0][0] + ii[1][1][m] / g[1][1]) / 2.0).collect();
    println!("Clifford torus: E = {:.6}, F = {}, G = {:.6}; area = 4 pi^2 E = {:.4}", g[0][0], fx(g[0][1], 6), g[1][1], 4.0 * PI.powi(2) * g[0][0]);
    println!("  split 1, in flat 4-space (k = 2): <II_11, II_22> = {}, |II(e1,e1)|^2 = {:.6}, K = 0 + {}", fx(dot(&ii[0][0], &ii[1][1]), 6), dot(&ii[0][0], &ii[0][0]) / g[0][0].powi(2), fx(k4, 6));
    println!("    mean curvature vector H = {}, {}, {}, {}; point = {:.6}, {:.6}, {:.6}, {:.6}", fx(hv[0], 6), fx(hv[1], 6), fx(hv[2], 6), fx(hv[3], 6), p[0], p[1], p[2], p[3]);
    assert!(k4.abs() < 1e-6 && (0..4).all(|m| (hv[m] + p[m]).abs() < 1e-6));
    let nu = [pt[0].cos() / s2, pt[0].sin() / s2, -pt[1].cos() / s2, -pt[1].sin() / s2];
    let hp: Vec<V> = (0..2).map(|i| (0..2).map(|j| dot(&ii[i][j], &p) / (g[i][i] * g[j][j]).sqrt()).collect()).collect(); // part along the 3-sphere's normal p
    let hs: Vec<V> = (0..2).map(|i| (0..2).map(|j| dot(&ii[i][j], &nu) / (g[i][i] * g[j][j]).sqrt()).collect()).collect(); // part along nu: II inside the 3-sphere
    let amb = hp[0][0] * hp[1][1] - hp[0][1].powi(2); let ks = amb + hs[0][0] * hs[1][1] - hs[0][1].powi(2); // Gauss for the 3-sphere in 4-space
    println!("  split 2, in the unit 3-sphere (k = 1): II along p = {:.6}, {:.6}, so ambient = ({:.6})({:.6}) = {:.6}", hp[0][0], hp[1][1], hp[0][0], hp[1][1], amb);
    println!("    II along nu = principal curvatures {:.6}, {:.6}, mean {} (minimal); K = {:.6} + ({:.6})({:.6}) = {}", hs[0][0], hs[1][1], fx((hs[0][0] + hs[1][1]) / 2.0, 6), amb, hs[0][0], hs[1][1], fx(ks, 6));
    assert!((hp[0][0] + 1.0).abs() < 1e-6 && (hp[1][1] + 1.0).abs() < 1e-6 && (amb - secs[0]).abs() < 1e-5 && (hs[0][0] + 1.0).abs() < 1e-6 && (hs[1][1] - 1.0).abs() < 1e-6 && (ks - k4).abs() < 1e-6);
    // Ricci equation, flat 4-space: <R_perp(du,dv) nu1, nu2> = <[A1, A2] du, dv>
    let par = |y: &[f64]| vec![y[0], y[1], (y[0].powi(2) - y[1].powi(2)) / 2.0, y[0] * y[1]]; // w = z^2/2
    let cases: [(&str, Emb, [f64; 2]); 2] = [("Clifford torus", &tor, pt), ("w = z^2/2 at z = 0.4 + 0.3i", &par, [0.4, 0.3])];
    let mut last = (0.0, 0.0, 0.0, vec![], vec![]);
    for (name, emb, x) in cases {
        last = ricci(emb, &x);
        println!("Ricci equation, {}: normal curvature = {}, from [A1,A2] = {}; K = {}", name, fx(last.0, 6), fx(last.1, 6), fx(last.2, 6));
        assert!((last.0 - last.1).abs() < 1e-4);
    }
    let (rp, _, k, gp, iip) = last;
    println!("  closed form for w = z^2/2: K = -2/(1+|z|^2)^3 = {:.6}", -2.0 / 1.25f64.powi(3));
    assert!((k + 2.0 / 1.25f64.powi(3)).abs() < 1e-5 && (rp - k).abs() < 1e-4);
    // what breaks
    println!("break: ambient term only: globe K = 0, Clifford torus in the 3-sphere K = {:.6}", amb);
    println!("break: bending term only, Clifford torus in the 3-sphere: K = {:.6}", hs[0][0] * hs[1][1]);
    println!("break: drop |II_12|^2, w = z^2/2 at 0.4 + 0.3i: K = {:.6}", dot(&iip[0][0], &iip[1][1]) / (gp[0][0] * gp[1][1] - gp[0][1].powi(2)));
    println!("break: sphere's II on the ellipsoid's metric: Gauss says {}, metric says {}", sci(1.0 / (R * R), 4), sci(kc, 4));
    println!("try: Moon, R = 1737.4 km: 1/R = {} per km, K = {} per km^2; GRS80: North Pole K = {}, equator K = {}", sci(1.0 / 1737.4, 4), sci(1.0 / 1737.4f64.powi(2), 4), sci(1.0 / rho_m(0.0).powi(2), 4), sci(1.0 / (rho_m(PI / 2.0) * rho_e(PI / 2.0)), 4));
    println!("ALL CHECKS PASS");
}
