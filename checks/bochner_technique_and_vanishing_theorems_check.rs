// Bochner's theorem -- the check behind the card.  Rust std only, no crates.
// The Bochner formula is checked at London in two charts of the globe, then integrated
// over the whole globe and over a band, and Betti numbers are counted by exact rank.
use std::f64::consts::PI;
type M2 = [[f64; 2]; 2];
type Ch<'a> = &'a dyn Fn([f64; 2]) -> M2;
type Fm<'a> = &'a dyn Fn([f64; 2]) -> [f64; 2];
const R: f64 = 6371.0; // globe radius, km
const A: f64 = 6378.137; const B: f64 = 6356.7523142; // WGS 84 equatorial and polar radii, km
fn sphere(r: f64) -> impl Fn([f64; 2]) -> M2 { move |p| [[r * r, 0.0], [0.0, (r * p[0].sin()).powf(2.0)]] }
fn graph(p: [f64; 2]) -> M2 { // x, y in km on the equator plane, northern half
    let w = R * R - p[0].powf(2.0) - p[1].powf(2.0);
    [[1.0 + p[0].powf(2.0) / w, p[0] * p[1] / w], [p[0] * p[1] / w, 1.0 + p[1].powf(2.0) / w]]
}
fn flat(_p: [f64; 2]) -> M2 { [[1.0, 0.0], [0.0, 1.0]] } // wrap-around map, km
fn wgs(p: [f64; 2]) -> M2 { // parametric latitude beta and longitude
    [[(A * p[0].sin()).powf(2.0) + (B * p[0].cos()).powf(2.0), 0.0], [0.0, (A * p[0].cos()).powf(2.0)]]
}
fn det(g: &M2) -> f64 { g[0][0] * g[1][1] - g[0][1] * g[1][0] }
fn inv(g: &M2) -> M2 { [[g[1][1] / det(g), -g[0][1] / det(g)], [-g[1][0] / det(g), g[0][0] / det(g)]] }
fn dif(f: &dyn Fn([f64; 2]) -> f64, p: [f64; 2], i: usize, h: f64) -> f64 { // central difference
    let (mut a, mut b) = (p, p); a[i] += h; b[i] -= h; (f(a) - f(b)) / (2.0 * h)
}
fn gam(ch: Ch, p: [f64; 2], h: f64) -> [[[f64; 2]; 2]; 2] { // Christoffel symbols G[l][j][k]
    let (gi, mut dg, mut g) = (inv(&ch(p)), [[[0.0; 2]; 2]; 2], [[[0.0; 2]; 2]; 2]);
    for m in 0..2 { for a in 0..2 { for b in 0..2 { dg[m][a][b] = dif(&|q| ch(q)[a][b], p, m, h); } } }
    for l in 0..2 { for j in 0..2 { for k in 0..2 {
        g[l][j][k] = 0.5 * (0..2).fold(0.0, |s, m| s + gi[l][m] * (dg[j][m][k] + dg[k][m][j] - dg[m][j][k]));
    } } }
    g
}
fn ric(ch: Ch, p: [f64; 2], h: f64) -> M2 { // Ric_jk = Rm^i_jik
    let (g, mut dg) = (gam(ch, p, h), [[[[0.0; 2]; 2]; 2]; 2]);
    for i in 0..2 { for l in 0..2 { for j in 0..2 { for k in 0..2 { dg[i][l][j][k] = dif(&|q| gam(ch, q, h)[l][j][k], p, i, h); } } } }
    let rm = |l: usize, k: usize, i: usize, j: usize|
        dg[i][l][j][k] - dg[j][l][i][k] + (0..2).fold(0.0, |s, m| s + (g[l][i][m] * g[m][j][k] - g[l][j][m] * g[m][i][k]));
    let c = |j: usize, k: usize| rm(0, j, 0, k) + rm(1, j, 1, k); [[c(0, 0), c(0, 1)], [c(1, 0), c(1, 1)]]
}
fn nab(ch: Ch, w: Fm, p: [f64; 2], h: f64) -> M2 { // (nabla_i w)_j = d_i w_j - G^k_ij w_k
    let (g, wp, mut n) = (gam(ch, p, h), w(p), [[0.0; 2]; 2]);
    for i in 0..2 { for j in 0..2 { n[i][j] = dif(&|q| w(q)[j], p, i, h) - (g[0][i][j] * wp[0] + g[1][i][j] * wp[1]); } }
    n
}
fn div(ch: Ch, w: Fm, p: [f64; 2], h: f64) -> f64 { // (1/sqrt det g) d_i (sqrt det g g^ij w_j)
    let flux = |q: [f64; 2], i: usize| det(&ch(q)).sqrt() * (inv(&ch(q))[i][0] * w(q)[0] + inv(&ch(q))[i][1] * w(q)[1]);
    (dif(&|q| flux(q, 0), p, 0, h) + dif(&|q| flux(q, 1), p, 1, h)) / det(&ch(p)).sqrt()
}
fn lap(ch: Ch, f: &dyn Fn([f64; 2]) -> f64, p: [f64; 2], h: f64) -> f64 { div(ch, &|q| [dif(f, q, 0, h), dif(f, q, 1, h)], p, h) }
fn sq1(ch: Ch, w: Fm, p: [f64; 2]) -> f64 {
    let (gi, v) = (inv(&ch(p)), w(p));
    (0..4).fold(0.0, |s, ij| s + gi[ij / 2][ij % 2] * v[ij / 2] * v[ij % 2])
}
fn bochner(ch: Ch, w: Fm, p: [f64; 2], h: f64) -> [f64; 6] { // |w|^2, |nabla w|^2, Ric(w,w), half Laplacian, curl, div
    let (gi, n, rc, v) = (inv(&ch(p)), nab(ch, w, p, h), ric(ch, p, h), w(p));
    let (mut n2, mut rw) = (0.0, 0.0);
    for i in 0..2 { for j in 0..2 { for a in 0..2 { for b in 0..2 {
        n2 += gi[i][a] * gi[j][b] * n[i][j] * n[a][b];
        rw += gi[i][a] * gi[j][b] * rc[i][j] * v[a] * v[b];
    } } } }
    [sq1(ch, w, p), n2, rw, 0.5 * lap(ch, &|q| sq1(ch, w, q), p, h), n[0][1] - n[1][0], div(ch, w, p, h)]
}
fn show(label: &str, vs: &[f64]) { // tiny rounding noise prints as 0
    let s: String = vs.iter().map(|v| format!("{:>12.6}", if v.abs() >= 5e-7 { *v } else { 0.0 })).collect();
    println!("{:<46}{}", label, s);
}
fn globe(r: f64, n: usize) -> [f64; 3] { // whole globe, w = d(height), midpoint rule in phi
    let (mut t, sp) = ([0.0; 3], sphere(r));
    for i in 0..n {
        let p = [PI * (i as f64 + 0.5) / n as f64, 0.3]; let wt = 2.0 * PI * r * r * p[0].sin() * PI / n as f64;
        let b = bochner(&sp, &|q| [-r * q[0].sin(), 0.0], p, 1e-4);
        t = [t[0] + wt * lap(&sp, &|q| r * q[0].cos(), p, 1e-4).powf(2.0), t[1] + wt * b[1], t[2] + wt * b[2]];
    }
    t
}
fn band(deg: f64, n: usize) -> [f64; 6] { // R^2 times each side over the band, the edge flux and both sides in closed form
    let (a, sp, mut t) = (deg.to_radians(), sphere(R), [0.0; 3]);
    for i in 0..n {
        let p = [a + (PI - 2.0 * a) * (i as f64 + 0.5) / n as f64, 0.3]; let wt = 2.0 * PI * R * R * p[0].sin() * (PI - 2.0 * a) / n as f64;
        let b = bochner(&sp, &|_q| [0.0, 1.0], p, 1e-4);
        t = [t[0] + wt * b[3], t[1] + wt * b[1], t[2] + wt * b[2]];
    }
    let (f, rc) = (4.0 * PI * a.cos() / a.sin().powf(2.0), 4.0 * PI * (1.0 / (a / 2.0).tan()).ln()); // edge flux; int Ric = 4 pi ln cot(a/2)
    [t[0] * R * R, t[1] * R * R, t[2] * R * R, f, f - rc, rc] // int |nabla w|^2 = 4 pi (cos a / sin^2 a - ln cot(a/2))
}
fn kc(b: f64) -> f64 { // closed form: (1 - e^2 sin^2 lat)^2 / (A^2 (1 - e^2)), lat = geodetic latitude
    let (e2, s2) = (1.0 - B * B / (A * A), (A / B * b.tan()).atan().sin().powf(2.0));
    (1.0 - e2 * s2).powf(2.0) / (A * A * (1.0 - e2))
}
fn rank(m0: &Vec<Vec<i128>>) -> usize { // fraction-free (Bareiss) elimination, exact
    let (mut m, mut r, mut prev) = (m0.clone(), 0usize, 1i128);
    for c in 0..m[0].len() {
        let Some(p) = (r..m.len()).find(|&i| m[i][c] != 0) else { continue };
        m.swap(r, p);
        for i in r + 1..m.len() {
            for j in c + 1..m[0].len() { let num = m[r][c] * m[i][j] - m[i][c] * m[r][j]; assert!(num % prev == 0); m[i][j] = num / prev; }
            m[i][c] = 0;
        }
        prev = m[r][c]; r += 1;
    }
    r
}
fn grid(n: usize, m: usize, wrap: bool) -> Vec<[usize; 3]> { // n by m squares, two triangles each
    let (rows, mut t) = (if wrap { m } else { m + 1 }, vec![]);
    let v = |i: usize, j: usize| i % n + n * (j % rows);
    for i in 0..n { for j in 0..m { t.push([v(i, j), v(i + 1, j), v(i + 1, j + 1)]); t.push([v(i, j), v(i + 1, j + 1), v(i, j + 1)]); } }
    t
}
fn betti(tri: &Vec<[usize; 3]>, n: i128) -> (usize, usize, usize, usize, usize, Vec<i128>) {
    let nv = 1 + tri.iter().map(|t| *t.iter().max().unwrap()).max().unwrap();
    let mut e: Vec<(usize, usize)> = vec![];
    for t in tri { for (a, b) in [(0, 1), (1, 2), (0, 2)] { e.push((t[a].min(t[b]), t[a].max(t[b]))); } }
    e.sort(); e.dedup();
    let d0: Vec<Vec<i128>> = e.iter().map(|&(a, b)| (0..nv).map(|k| (k == b) as i128 - (k == a) as i128).collect()).collect();
    let d1: Vec<Vec<i128>> = tri.iter().map(|t| e.iter().map(|&ed| {
        [((t[0], t[1]), 1), ((t[1], t[2]), 1), ((t[0], t[2]), -1)].iter().map(|&((x, y), sg)|
            sg * ((ed == (x.min(y), x.max(y))) as i128) * if x < y { 1 } else { -1 }).sum()
    }).collect()).collect();
    let ne = e.len(); let l1: Vec<Vec<i128>> = (0..ne).map(|i| (0..ne).map(|j|
        (0..nv).map(|k| d0[i][k] * d0[j][k]).sum::<i128>() + (0..tri.len()).map(|t| d1[t][i] * d1[t][j]).sum::<i128>()).collect()).collect();
    let east: Vec<i128> = e.iter().map(|&(a, b)| ((b as i128 % n) - (a as i128 % n) + 1).rem_euclid(n) - 1).collect();
    let le = (0..ne).map(|i| (0..ne).map(|j| l1[i][j] * east[j]).sum()).collect();
    (nv, ne, tri.len(), ne - rank(&d0) - rank(&d1), ne - rank(&l1), le)
}
fn main() {
    let (ph, th) = ((90.0 - 51.5074f64).to_radians(), (-0.1278f64).to_radians());
    let sa = bochner(&sphere(R), &|_p| [0.0, 1.0], [ph, th], 1e-4);
    let sb = bochner(&graph, &|p| [-p[1] / (p[0].powf(2.0) + p[1].powf(2.0)), p[0] / (p[0].powf(2.0) + p[1].powf(2.0))],
                     [R * ph.sin() * th.cos(), R * ph.sin() * th.sin()], 1.0);
    let (s, c) = (ph.sin(), ph.cos()); let exact = [1.0 / s.powf(2.0), 2.0 * c * c / s.powf(4.0), 1.0 / s.powf(2.0), 1.0 / s.powf(2.0) + 2.0 * c * c / s.powf(4.0)];
    show("London: polar angle (deg), R sin(phi) (km)", &[90.0 - 51.5074, R * s]);
    let sc = |k: usize| R.powf(if k == 0 { 2.0 } else { 4.0 });
    for (k, lab) in ["R^2 |w|^2", "R^4 |nabla w|^2", "R^4 Ric(w, w)", "R^4 half Laplacian |w|^2"].iter().enumerate() {
        show(&format!("{}: sphere, graph, exact", lab), &[sa[k] * sc(k), sb[k] * sc(k), exact[k]]);
    }
    show("R^4 (|nabla w|^2 + Ric): sphere, graph", &[(sa[1] + sa[2]) * R.powf(4.0), (sb[1] + sb[2]) * R.powf(4.0)]);
    show("R^2 curl, R^2 divergence: graph chart", &[sb[4] * R * R, sb[5] * R * R]);
    let hd = nab(&sphere(R), &|q| [-R * q[0].sin(), 0.0], [ph, th], 1e-4)[1][1] / R; // w = df, f = height: sign-sensitive entry
    show("London, w = df: nabla_theta w_theta / R, exact", &[hd, -s * s * c]);
    let (g, g2) = (globe(R, 1200), globe(R, 600));
    show("globe: int (delta w)^2, |nabla w|^2, Ric", &g);
    show("  same with half the steps", &g2);
    show("  closed forms 16 pi/3, 8 pi/3, 8 pi/3", &[16.0 * PI / 3.0, 8.0 * PI / 3.0, 8.0 * PI / 3.0]);
    show("  Moon, r = 1737.4 km", &globe(1737.4, 1200));
    let bands = [band(23.44, 1200), band(10.0, 1200)];
    for (deg, bd) in [23.44, 10.0].iter().zip(bands.iter()) { show(&format!("band from {:5.2} deg: lhs, nabla, Ric, flux", deg), &bd[..4]); show("  closed forms of nabla, Ric", &bd[4..]); }
    let ks: Vec<f64> = (-89..90).map(|d: i32| ric(&wgs, [(d as f64).to_radians(), 0.0], 1e-4)[1][1] / wgs([(d as f64).to_radians(), 0.0])[1][1]).collect();
    let (kmin, kmax) = (ks.iter().cloned().fold(f64::INFINITY, f64::min), ks.iter().cloned().fold(0.0, f64::max));
    show("WGS 84 K x 1e8 (1/km^2): min, max", &[kmin * 1e8, kmax * 1e8]);
    show("  closed form at 89 deg, equator, pole", &[kc(89f64.to_radians()) * 1e8, kc(0.0) * 1e8, B * B / A.powf(4.0) * 1e8]);
    show("flat 40000 x 20000 km map, w = dx: three", &bochner(&flat, &|_p| [1.0, 0.0], [40000.0 * 0.3, 20000.0 * 0.7], 1.0)[..3]);
    let octa: Vec<[usize; 3]> = (1..5).map(|i| [0, i, i % 4 + 1]).chain((1..5).map(|i| [5, i % 4 + 1, i])).collect();
    let (o, t3, cy) = (betti(&octa, 3), betti(&grid(3, 3, true), 3), betti(&grid(3, 1, false), 3));
    for (name, x) in [("octahedron", &o), ("3x3 torus", &t3), ("3x1 band", &cy)] {
        println!("{} V E F {} {} {}: b1 by ranks {}, harmonic 1-cochains {}", name, x.0, x.1, x.2, x.3, x.4);
    }
    let east_ok = t3.5.iter().all(|&v| v == 0); println!("east cochain on the torus has L1 x = 0: {}", if east_ok { "yes" } else { "no" });
    let winds: Vec<String> = [0, 10, 20, 30, 40, 50, 60, 70, 80, 85, 88].iter()
        .map(|&l: &i32| format!("{}:{:.1}", l, 10.0 * R / (R * ((90 - l) as f64).to_radians().sin()))).collect();
    println!("wind m/s at latitude {}", winds.join(" "));
    assert!((0..4).all(|k| (sa[k] * sc(k) - exact[k]).abs() < 1e-5) && (hd + s * s * c).abs() < 1e-6, "sphere chart against exact");
    assert!((0..4).all(|k| ((sb[k] - sa[k]) / sa[k]).abs() < 1e-6), "two charts agree");
    assert!((sb[3] - sb[1] - sb[2]).abs() < 1e-6 * sb[3], "Bochner formula pointwise");
    assert!((g[0] - 16.0 * PI / 3.0).abs() < 1e-4 && (g[1] - 8.0 * PI / 3.0).abs() < 1e-4, "globe integrals against closed forms");
    assert!((g[0] - g[1] - g[2]).abs() < 1e-4, "integrated Weitzenbock identity");
    assert!((g2[0] - g[0]).abs() > 2.0 * (g[0] - 16.0 * PI / 3.0).abs(), "halving the steps cuts the error about fourfold");
    assert!(bands.iter().all(|bd| (bd[0] - bd[3]).abs() < 1e-4 * bd[3] && (bd[0] - bd[1] - bd[2]).abs() < 1e-4 * bd[3] && (bd[1] - bd[4]).abs() < 1e-4 * bd[3] && (bd[2] - bd[5]).abs() < 1e-4 * bd[3]), "band: lhs is the edge flux; each side against its closed form");
    assert!(ks.iter().zip(-89..90).all(|(k, d): (&f64, i32)| (k - kc((d as f64).to_radians())).abs() < 1e-6 * k) && kmin > B * B / A.powf(4.0), "WGS 84 K, closed form, positive");
    assert!((o.3, o.4, t3.3, t3.4, cy.3, cy.4, east_ok) == (0, 0, 2, 2, 1, 1, true), "b1 by two counts; east is harmonic");
    println!("ALL CHECKS PASS");
}
