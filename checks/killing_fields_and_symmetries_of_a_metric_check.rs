// Killing fields -- the same check as the Python, in Rust.  No crates.
// The globe is a sphere of radius 6371 km in the chart (phi, theta): phi is the
// angle down from the North Pole, theta the longitude east, both in radians.
// Each field is tested by the chart formula for L_X g, by moving real points
// in space, and by counting every solution of the Killing equation.
use std::f64::consts::PI;
const R: f64 = 6371.0;
type P = (f64, f64);
const NAMES: [&str; 5] = ["spin about the polar axis z", "spin about the axis x", "spin about the axis y",
                          "slide south", "twist, rate sin(phi)"];

fn embed(p: P) -> [f64; 3] { [R * p.0.sin() * p.1.cos(), R * p.0.sin() * p.1.sin(), R * p.0.cos()] }
fn dot(a: &[f64; 3], b: &[f64; 3]) -> f64 { a[0] * b[0] + a[1] * b[1] + a[2] * b[2] }
fn turn(k: [f64; 3], s: f64, v: [f64; 3]) -> [f64; 3] {         // Rodrigues: turn v by s rad about unit k
    let c = [k[1] * v[2] - k[2] * v[1], k[2] * v[0] - k[0] * v[2], k[0] * v[1] - k[1] * v[0]];
    let d = dot(&k, &v);
    [0, 1, 2].map(|i| v[i] * s.cos() + c[i] * s.sin() + k[i] * d * (1.0 - s.cos()))
}
fn dist(u: [f64; 3], v: [f64; 3]) -> f64 { R * (dot(&u, &v) / (R * R)).clamp(-1.0, 1.0).acos() }
fn field(i: usize, p: P) -> P {                                  // X = (X^phi, X^theta), rad per unit time
    let cot = p.0.cos() / p.0.sin();
    match i { 0 => (0.0, 1.0), 1 => (-p.1.sin(), -cot * p.1.cos()), 2 => (p.1.cos(), -cot * p.1.sin()),
              3 => (1.0, 0.0), _ => (0.0, p.0.sin()) }
}
fn flow(i: usize, p: P, s: f64) -> [f64; 3] {                    // the field's flow, as points in space
    match i { 0 => turn([0.0, 0.0, 1.0], s, embed(p)), 1 => turn([1.0, 0.0, 0.0], s, embed(p)),
              2 => turn([0.0, 1.0, 0.0], s, embed(p)), 3 => embed((p.0 + s, p.1)),
              _ => embed((p.0, p.1 + s * p.0.sin())) }
}
fn grad(i: usize, p: P, k: usize) -> P {                         // d/dphi and d/dtheta of component k
    let h = 1e-5;
    let c = |q: P| { let x = field(i, q); if k == 0 { x.0 } else { x.1 } };
    ((c((p.0 + h, p.1)) - c((p.0 - h, p.1))) / (2.0 * h), (c((p.0, p.1 + h)) - c((p.0, p.1 - h))) / (2.0 * h))
}
fn lie_formula(i: usize, p: P) -> ([f64; 3], f64) {    // (L_X g)_ij / R^2 from the chart formula
    let (f, (pp, _)) = (p.0, field(i, p));
    let ((pf, pt), (qf, qt)) = (grad(i, p, 0), grad(i, p, 1));
    ([2.0 * pf, pp * 2.0 * f.sin() * f.cos() + 2.0 * f.sin().powi(2) * qt, pt + f.sin().powi(2) * qf],
     pp * 2.0 * f.sin() * f.cos())
}
fn lie_flow(i: usize, p: P) -> [f64; 3] {    // the definition: rate of change of squared tiny lengths
    let (h, t) = (1e-4, 1e-4);
    let q = |u: P| {
        let a = (p.0 - h * u.0 / 2.0, p.1 - h * u.1 / 2.0);
        let b = (p.0 + h * u.0 / 2.0, p.1 + h * u.1 / 2.0);
        let d = |s: f64| { let (x, y) = (flow(i, a, s), flow(i, b, s)); (0..3).map(|k| (x[k] - y[k]).powi(2)).sum::<f64>() };
        (d(t) - d(-t)) / (2.0 * t * h * h * R * R)
    };
    let (q11, q22) = (q((1.0, 0.0)), q((0.0, 1.0)));
    [q11, q22, (q((1.0, 1.0)) - q11 - q22) / 2.0]
}
fn count_killing(a: f64, b: f64) -> usize {   // nullity of the Killing equation over 50 trial fields
    let fb = |n: usize, f: f64| -> P { match n { 0 => (1.0, 0.0), 1 => (f.sin(), f.cos()), 2 => (f.cos(), -f.sin()),
        3 => (f.cos() / f.sin(), -1.0 / f.sin().powi(2)), _ => (1.0 / f.sin(), -f.cos() / f.sin().powi(2)) } };
    let tb = |n: usize, t: f64| -> P { let k = [0.0, 1.0, 2.0, 1.0, 2.0][n];
        if n < 3 { ((k * t).cos(), -k * (k * t).sin()) } else { ((k * t).sin(), k * (k * t).cos()) } };
    let mut rows: Vec<Vec<f64>> = Vec::new();
    for i in 0..8 { for j in 0..6 {
        let (f, t) = (0.3 + 2.5 * i as f64 / 7.0, 2.0 * PI * j as f64 / 6.0);
        let (g11, g22) = (a * a * f.cos().powi(2) + b * b * f.sin().powi(2), a * a * f.sin().powi(2));
        let (d11, d22) = (2.0 * (b * b - a * a) * f.sin() * f.cos(), 2.0 * a * a * f.sin() * f.cos());
        let (mut r11, mut r22, mut r12) = (vec![], vec![], vec![]);
        for comp in 0..2 { for fi in 0..5 { for ti in 0..5 {
            let ((u, uf), (v, vt)) = (fb(fi, f), tb(ti, t));
            let (uu, ufv, utv) = (u * v, uf * v, u * vt);
            r11.push(if comp == 0 { uu * d11 + 2.0 * g11 * ufv } else { 0.0 });
            r22.push(if comp == 0 { uu * d22 } else { 2.0 * g22 * utv });
            r12.push(if comp == 0 { g11 * utv } else { g22 * ufv });
        } } }
        rows.push(r11); rows.push(r22); rows.push(r12);
    } }
    let (mut rank, n) = (0, rows[0].len());
    let scale = rows.iter().flatten().fold(0.0f64, |m, x| m.max(x.abs()));
    for c in 0..n {                                              // Gaussian elimination, partial pivoting
        let mut piv = rank;
        for r in rank..rows.len() { if rows[r][c].abs() > rows[piv][c].abs() { piv = r } }
        if rows[piv][c].abs() < 1e-9 * scale { continue }
        rows.swap(rank, piv);
        for r in rank + 1..rows.len() {
            let m = rows[r][c] / rows[rank][c];
            for k in 0..n { rows[r][k] -= m * rows[rank][k] }
        }
        rank += 1;
    }
    n - rank
}
fn fmt(v: &[f64]) -> String {
    let s: Vec<String> = v.iter().map(|&x| format!("{:+.6}", if x.abs() > 5e-7 { x } else { 0.0 })).collect();
    format!("({})", s.join(", "))
}

fn main() {
    let lon: P = ((90.0f64 - 51.5074).to_radians(), (-0.1278f64).to_radians());    // London (phi, theta)
    let nyc: P = ((90.0f64 - 40.7128).to_radians(), (-74.0060f64).to_radians());   // New York (phi, theta)
    let (a_wgs, b_wgs) = (6378.137, 6378.137 * (1.0 - 1.0 / 298.257223563));       // the real Earth, km
    println!("L_X g at New York divided by R^2, components (11, 22, 12):");
    let (mut worst, mut res) = (0.0f64, vec![]);
    for i in 0..5 {
        let (a, naive) = lie_formula(i, nyc);
        let b = lie_flow(i, nyc);
        for k in 0..3 { worst = worst.max((a[k] - b[k]).abs()) }
        res.push((a, naive, dist(flow(i, lon, 0.5), flow(i, nyc, 0.5))));
        println!("  {:<28} formula {}  moving points {}", NAMES[i], fmt(&a), fmt(&b));
    }
    println!("largest gap between the two roads: {:.9}", worst);
    let d0 = dist(embed(lon), embed(nyc));
    println!("London-New York before any flow: {:.2} km; after 0.5 unit of each flow:", d0);
    for i in 0..5 {
        let k = res[i].0.iter().all(|x| x.abs() < 1e-6);
        let bar = "#".repeat((res[i].2 / 250.0).round() as usize);
        println!("  {:<28} |{:<32}{:.2} km   Killing: {}", NAMES[i], bar, res[i].2, if k { "yes" } else { "no" });
    }
    println!("6 sidereal hours of Earth spin (pi/2 rad): {:.2} km", dist(flow(0, lon, PI / 2.0), flow(0, nyc, PI / 2.0)));
    let (px, qx) = field(1, nyc);
    println!("spin about x at New York: X = ({:+.6}, {:+.6}); naive term X^phi d_phi g_22 = {:+.6}, stretch term {:+.6}",
             px, qx, res[1].1, 2.0 * nyc.0.sin() * nyc.0.cos() * nyc.1.sin());
    let (x1, x2) = (field(1, nyc), field(2, nyc));             // bracket [X, Y]^k = X^i d_i Y^k - Y^i d_i X^k
    let br: Vec<f64> = (0..2).map(|k| { let (g2, g1) = (grad(2, nyc, k), grad(1, nyc, k));
        x1.0 * g2.0 + x1.1 * g2.1 - (x2.0 * g1.0 + x2.1 * g1.1) }).collect();
    println!("bracket [spin x, spin y] at New York, in the chart: {} = minus the spin about z", fmt(&br));
    let (n_sphere, n_egg) = (count_killing(1.0, 1.0), count_killing(a_wgs / R, b_wgs / R));
    println!("Killing fields among 50 trial fields: round globe {}, flattened Earth {}; most possible in 2D: {}", n_sphere, n_egg, 2 * 3 / 2);
    let pole = turn([1.0, 0.0, 0.0], PI / 2.0, [0.0, 0.0, b_wgs]);
    println!("flattened Earth, North Pole turned 90 deg about x: {:.3} km from the centre, equator at {:.3} km, off the surface by {:.3} km",
             dot(&pole, &pole).sqrt(), a_wgs, a_wgs - b_wgs);
    let omega = 2.0 * PI / 86164.0905;                          // Earth's spin, rad/s: one turn per sidereal day
    println!("Earth's spin field: one turn per {:.4} s, {:.6} x 10^-5 rad/s; ground speed London {:.1} m/s, New York {:.1} m/s, pole 0.0 m/s",
             86164.0905, omega * 1e5, R * lon.0.sin() * omega * 1000.0, R * nyc.0.sin() * omega * 1000.0);
    let (a, b) = (embed(lon), embed(nyc));                      // Clairaut: the polar spin's conserved number
    let c = (dot(&a, &b) / (R * R)).acos();
    let mut clair: Vec<f64> = vec![];
    for s in [0.0, 0.5, 1.0f64] {
        let r = [0, 1, 2].map(|k| (((1.0 - s) * c).sin() * a[k] + (s * c).sin() * b[k]) / c.sin());
        let t0 = [0, 1, 2].map(|k| -((1.0 - s) * c).cos() * a[k] + (s * c).cos() * b[k]);
        let tn = dot(&t0, &t0).sqrt();
        let tv = t0.map(|x| x / tn);
        let (f, t) = ((r[2] / R).acos(), r[1].atan2(r[0]));
        let (east, north) = ([-t.sin(), t.cos(), 0.0], [-f.cos() * t.cos(), -f.cos() * t.sin(), f.sin()]);
        let head = dot(&tv, &east).atan2(dot(&tv, &north)).rem_euclid(2.0 * PI);
        clair.push(R * f.sin() * head.sin());
        println!("great circle at {:.1} of the way: latitude {:.2} deg, heading {:.2} deg, g(spin z, T) = R sin(phi) sin(heading) = {:.2} km",
                 s, 90.0 - f.to_degrees(), head.to_degrees(), clair[clair.len() - 1]);
    }
    println!("highest latitude on the route, where the heading is due west: {:.2} deg", 90.0 - (-clair[0] / R).asin().to_degrees());
    assert!(worst < 1e-6);                                                      // formula against moving points
    assert!((0..3).all(|i| (res[i].2 - d0).abs() < 1e-6));                      // spins keep the distance
    assert!((res[3].2 - d0).abs() > 100.0 && (res[4].2 - d0).abs() > 100.0);
    assert!(n_sphere == 3 && n_egg == 1);                                       // two counts of the symmetries
    assert!(br[0].abs() < 1e-6 && (br[1] + 1.0).abs() < 1e-6);                  // [X_x, X_y] = -X_z
    let (mx, mn) = clair.iter().fold((f64::MIN, f64::MAX), |(a, b), &x| (a.max(x), b.min(x)));
    assert!(mx - mn < 1e-6);                                                    // conserved along the geodesic
    println!("ALL CHECKS PASS");
}
