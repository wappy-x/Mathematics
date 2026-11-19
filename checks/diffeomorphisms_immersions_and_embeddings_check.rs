// Diffeomorphism, immersion, submersion -- the same check as the Python, in Rust.
// No crates.  Four maps from the house example are classified by the rank of
// their differential.  Each rank is found by two roads: the Jacobian written out
// in the latitude-longitude chart, and a chart-free road that pushes two tangent
// directions through the map in 3D space by central differences.
use std::f64::consts::PI;

const R: f64 = 6371.0; // the globe's radius in km (a sphere: a model)
type M = Vec<Vec<f64>>;

fn rank(a: &M, tol: f64) -> usize { // Gaussian elimination, tolerance relative to the largest entry
    let mut a = a.clone();
    let mut r = 0;
    let big = a.iter().flatten().fold(0.0_f64, |m, x| m.max(x.abs()));
    let big = if big == 0.0 { 1.0 } else { big };
    for c in 0..a[0].len() {
        let rows: Vec<usize> = (r..a.len()).filter(|&i| a[i][c].abs() > tol * big).collect();
        if rows.is_empty() { continue; }
        let mut p = rows[0];
        for &i in &rows { if a[i][c].abs() > a[p][c].abs() { p = i; } }
        a.swap(r, p);
        for i in r + 1..a.len() {
            let f = a[i][c] / a[r][c];
            let top = a[r].clone();
            for (x, y) in a[i].iter_mut().zip(top.iter()) { *x -= f * y; }
        }
        r += 1;
    }
    r
}
fn rk(a: &M) -> usize { rank(a, 1e-7) }
fn add(a: &[f64], b: &[f64], s: f64) -> Vec<f64> { a.iter().zip(b).map(|(x, y)| x + s * y).collect() }
fn norm(a: &[f64]) -> f64 { a.iter().map(|x| x * x).sum::<f64>().sqrt() }
fn cross(a: &[f64], b: &[f64]) -> Vec<f64> {
    vec![a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]]
}
fn ball(lat: f64, lon: f64) -> Vec<f64> { // degrees north and east to a point on the globe, km
    let (f, t) = ((90.0 - lat).to_radians(), lon.to_radians()); // phi measured down from the North Pole
    vec![R * f.sin() * t.cos(), R * f.sin() * t.sin(), R * f.cos()]
}
fn tangent_pair(q: &[f64]) -> Vec<Vec<f64>> { // two unit directions along the globe at q, no chart used
    let u: Vec<f64> = q.iter().map(|x| x / norm(q)).collect();
    let mut a = vec![0.0; 3];
    let mut i = 0;
    for j in 1..3 { if u[j].abs() < u[i].abs() { i = j; } }
    a[i] = 1.0;
    let e1 = cross(&a, &u);
    let e1: Vec<f64> = e1.iter().map(|x| x / norm(&e1)).collect();
    let e2 = cross(&u, &e1);
    vec![e1, e2]
}
fn push(f: &dyn Fn(&[f64]) -> Vec<f64>, q: &[f64], dirs: &M, h: f64) -> M { // columns dF(v), as a matrix
    let cols: M = dirs.iter().map(|v| {
        let (a, b) = (f(&add(q, v, h)), f(&add(q, v, -h)));
        a.iter().zip(&b).map(|(x, y)| (x - y) / (2.0 * h)).collect()
    }).collect();
    (0..cols[0].len()).map(|i| cols.iter().map(|c| c[i]).collect()).collect()
}
fn mercator(q: &[f64]) -> Vec<f64> { // X = R theta, Y = R ln cot(phi/2), from a 3D point
    let s = q[2] / norm(q);
    vec![R * q[1].atan2(q[0]), R * 0.5 * ((1.0 + s) / (1.0 - s)).ln()]
}
fn photo(q: &[f64]) -> Vec<f64> { vec![q[0], q[1]] } // the globe seen from far above the North Pole
fn j_mercator(f: f64) -> M { vec![vec![0.0, R], vec![-R / f.sin(), 0.0]] } // columns: d/dphi, d/dtheta
fn j_photo(f: f64, t: f64) -> M {
    vec![vec![R * f.cos() * t.cos(), -R * f.sin() * t.sin()], vec![R * f.cos() * t.sin(), R * f.sin() * t.cos()]]
}
fn roll(c: f64) -> impl Fn(&[f64]) -> Vec<f64> {
    let rho = c / (2.0 * PI);
    move |q: &[f64]| vec![rho * (q[0] / rho).sin(), rho * (1.0 - (q[0] / rho).cos()), q[1]]
}
fn closest(width: f64) -> f64 { // brute force: nearest meeting of far-apart points
    let (f, step, apart) = (roll(0.80), 0.005, 0.40);
    let us: Vec<f64> = (0..=((width / step).round() as usize)).map(|i| i as f64 * step).collect();
    let mut best = f64::INFINITY;
    for &u in &us { for &w in &us {
        if w - u >= apart - 1e-12 { best = best.min(norm(&add(&f(&[u, 0.0]), &f(&[w, 0.0]), -1.0))); }
    } }
    best
}

fn main() {
    // 1. Mercator at Heathrow: a diffeomorphism from the globe minus its poles onto a strip.
    let (lat, lon) = (51.47_f64, -0.4543_f64);
    let (f, _t) = ((90.0 - lat).to_radians(), lon.to_radians());
    let l = ball(lat, lon);
    let xy = mercator(&l);
    let (x, y) = (xy[0], xy[1]);
    let jm = push(&mercator, &l, &tangent_pair(&l), 1e-3);
    let st: Vec<f64> = (0..2).map(|k| norm(&[jm[0][k], jm[1][k]])).collect();
    println!("Heathrow {:.4} N {:.4} W on Mercator: X = {:.3} km, Y = {:.3} km", lat, -lon, x, y);
    println!("Mercator rank at Heathrow: chart {}, chart-free {}; chart det = {:.1} km^2 per rad^2",
             rk(&j_mercator(f)), rk(&jm), R * R / f.sin());
    println!("Mercator stretch at Heathrow, two chart-free directions: {:.6}, {:.6}; 1/cos(latitude) = {:.6}",
             st[0], st[1], 1.0 / lat.to_radians().cos());
    let back = (90.0 - (2.0 * (-y / R).exp().atan()).to_degrees(), (x / R).to_degrees()); // road one
    let (mut g, mut k) = (40.0_f64.to_radians(), 2.0_f64.to_radians()); // road two: Newton from 50 N, 2 E
    let mut n = 0;
    for step in 1..30 {
        n = step;
        let j = j_mercator(g);
        let d = [R * k - x, R * 0.5 * ((1.0 + g.cos()) / (1.0 - g.cos())).ln() - y];
        g -= d[1] / j[1][0];
        k -= d[0] / j[0][1]; // inverse of an anti-diagonal matrix
        if d[0].abs() + d[1].abs() < 1e-9 { break; }
    }
    println!("undo by formula: {:.6} N {:.6} W; by Newton ({} steps): {:.6} N {:.6} W",
             back.0, -back.1, n, 90.0 - g.to_degrees(), -k.to_degrees());
    println!("Mercator strip width 2 pi R = {:.2} km; Y at 85 N = {:.1} km", 2.0 * PI * R, mercator(&ball(85.0, 0.0))[1]);
    // 2. The photo from above the North Pole: rank 2 at Heathrow, rank 1 on the equator.
    let rp: Vec<(usize, usize)> = [(lat, lon), (0.0, 0.0), (90.0, 0.0)].iter().map(|&(a, b)| {
        let p = ball(a, b);
        (rk(&j_photo((90.0 - a).to_radians(), b.to_radians())), rk(&push(&photo, &p, &tangent_pair(&p), 1e-3)))
    }).collect();
    println!("photo rank (chart, chart-free): Heathrow ({}, {}), equator ({}, {}), North Pole ({}, {})",
             rp[0].0, rp[0].1, rp[1].0, rp[1].1, rp[2].0, rp[2].1);
    println!("photo chart det R^2 sin(phi) cos(phi): Heathrow {:.1}, equator {:.1}, North Pole {:.1} km^2 per rad^2",
             R * R * f.sin() * f.cos(), (R * R * (PI / 2.0).sin() * (PI / 2.0).cos()).abs(), R * R * 0.0_f64.sin() * 0.0_f64.cos());
    let (p10n, p10s) = (photo(&ball(10.0, 0.0)), photo(&ball(-10.0, 0.0)));
    println!("photo of 10 N 0 E: ({:.2}, {:.2}) km; of 10 S 0 E: ({:.2}, {:.2}) km", p10n[0], p10n[1], p10s[0], p10s[1].abs());
    // 3. The overlay: a 1.00 m clear sheet curled into a roll 0.80 m round.
    let c = roll(0.80);
    let jc = push(&c, &[0.10, 0.35], &vec![vec![1.0, 0.0], vec![0.0, 1.0]], 1e-5);
    let w = 0.10 / (0.8 / (2.0 * PI));
    let jca: M = vec![vec![w.cos(), 0.0], vec![w.sin(), 0.0], vec![0.0, 1.0]];
    let (a, b) = (c(&[0.10, 0.35]), c(&[0.90, 0.35]));
    let col = |m: &M, j: usize| -> Vec<f64> { m.iter().map(|r| r[j]).collect() };
    println!("roll rank at u = 0.10 m: formula {}, differences {}; column lengths {:.6}, {:.6}",
             rk(&jca), rk(&jc), norm(&col(&jc, 0)), norm(&col(&jc, 1)));
    println!("u = 0.10 m lands at ({:.6}, {:.6}, {:.2}); u = 0.90 m at ({:.6}, {:.6}, {:.2})", a[0], a[1], a[2], b[0], b[1], b[2]);
    let rho = 0.80 / (2.0 * PI);
    let gap = 2.0 * rho * (0.05 / (2.0 * rho)).sin(); // chord across the 0.05 m left uncovered
    let (c100, c75) = (closest(1.00), closest(0.75));
    println!("closest approach of points 0.40 m apart on the sheet: 1.00 m sheet {:.6} m, 0.75 m sheet {:.6} m; chord formula {:.6} m",
             c100, c75, gap);
    println!("roll radius 0.80 m / 2 pi = {:.6} m; a 1.00 m sheet overlaps itself by {:.2} m", rho, 1.00 - 0.80);
    // 4. The drop from an aircraft 11 km above Heathrow to the ground point below it.
    let u: Vec<f64> = l.iter().map(|v| v / R).collect();
    let q: Vec<f64> = u.iter().map(|v| (R + 11.0) * v).collect();
    let gmap = |p: &[f64]| -> Vec<f64> { p.iter().map(|v| R * v / norm(p)).collect() };
    let eye: M = vec![vec![1.0, 0.0, 0.0], vec![0.0, 1.0, 0.0], vec![0.0, 0.0, 1.0]];
    let jg = push(&gmap, &q, &eye, 1e-3);
    let jga: M = (0..3).map(|i| (0..3).map(|j| R / norm(&q) * (eye[i][j] - u[i] * u[j])).collect()).collect();
    let apply = |m: &M, v: &[f64]| -> Vec<f64> { m.iter().map(|r| r.iter().zip(v).map(|(p, s)| p * s).sum()).collect() };
    let up = apply(&jg, &u);
    let side = tangent_pair(&q)[0].clone();
    println!("drop rank: formula {}, differences {}; nullity {}", rk(&jga), rk(&jg), 3 - rk(&jg));
    println!("an 11 km climb moves the ground point {:.6} km; a 1 km sideways step moves it {:.6} km = R/(R + 11)",
             11.0 * norm(&up), norm(&apply(&jg, &side)));
    assert!(rk(&j_mercator(f)) == 2 && rk(&jm) == 2 && (st[0] - 1.0 / lat.to_radians().cos()).abs() < 1e-6);
    assert!((back.0 - lat).abs() < 1e-9 && (90.0 - g.to_degrees() - lat).abs() < 1e-9 && (k.to_degrees() - lon).abs() < 1e-9);
    assert!(rp == vec![(2, 2), (1, 1), (1, 2)] && (p10n[0] - p10s[0]).abs() < 1e-9);
    assert!(rk(&jc) == 2 && rk(&jca) == 2 && norm(&add(&a, &b, -1.0)) < 1e-12);
    assert!(c100 < 1e-9 && (c75 - gap).abs() < 1e-9);
    assert!(rk(&jg) == 2 && rk(&jga) == 2 && 11.0 * norm(&up) < 1e-6 && (norm(&jg[0]) - norm(&jga[0])).abs() < 1e-6);
    assert!((j_mercator(f)[0][1] / (R * f.sin()) - st[0]).abs() < 1e-6 && (-j_mercator(f)[1][0] / R - st[1]).abs() < 1e-6);
    println!("ALL CHECKS PASS");
}
