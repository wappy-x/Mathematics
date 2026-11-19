// Green, divergence and curl theorems as one statement -- the same check as the Python, in Rust.
// No crates.  One routine integrates any k-form over a parametrised cube, and one routine takes its
// exterior derivative d by central differences.  Stokes says: integral of dw over M equals integral
// of w over the boundary of M.  The valley's four cases change only the degree of w and the shape M.
// Road A: w over the boundary.  Road B: dw over the inside.  Road C: the classical formula (gradient,
// curl, divergence) worked out by hand, integrated directly.  Road D: exact values.
use std::rc::Rc;
type Field = Rc<dyn Fn(&[f64]) -> Vec<f64>>;
const H: f64 = 1e-5;
fn gauss(n: usize) -> Vec<(f64, f64)> {          // Gauss-Legendre nodes and weights on [0, 1]
    let mut out = Vec::new();
    for i in 0..n {
        let mut x = (std::f64::consts::PI * (i as f64 + 0.75) / (n as f64 + 0.5)).cos();
        let mut dp = 0.0;
        for _ in 0..60 {                         // Newton's method on the Legendre polynomial
            let (mut p0, mut p1) = (1.0, x);
            for k in 2..=n { (p0, p1) = (p1, ((2 * k - 1) as f64 * x * p1 - (k - 1) as f64 * p0) / k as f64); }
            dp = n as f64 * (x * p1 - p0) / (x * x - 1.0);
            x = x - p1 / dp;
        }
        out.push(((1.0 - x) / 2.0, 1.0 / ((1.0 - x * x) * dp * dp)));
    }
    out
}
fn quad(nodes: &[(f64, f64)], f: &dyn Fn(&[f64]) -> f64, k: usize) -> f64 {   // over [0, 1]^k
    let n = nodes.len();
    let mut total = 0.0;
    for idx in 0..n.pow(k as u32) {
        let (mut dig, mut rest, mut w) = (vec![0; k], idx, 1.0);
        for j in (0..k).rev() { dig[j] = rest % n; rest /= n; }   // first coordinate slowest
        for j in 0..k { w *= nodes[dig[j]].1; }
        let u: Vec<f64> = dig.iter().map(|&j| nodes[j].0).collect();
        total += w * f(&u);
    }
    total
}
fn combos(n: usize, k: usize) -> Vec<Vec<usize>> {   // increasing k-tuples, in dictionary order
    if k == 0 { return vec![vec![]]; }
    let mut out: Vec<Vec<usize>> = combos(n, k - 1).into_iter()
        .flat_map(|c| { let s = c.last().map_or(0, |l| l + 1); (s..n).map(move |j| [c.clone(), vec![j]].concat()) }).collect();
    out.sort();
    out
}
fn bump(p: &[f64], i: usize, s: f64) -> Vec<f64> { let mut q = p.to_vec(); q[i] += s; q }
fn det(m: &[Vec<f64>]) -> f64 {                   // determinant, expanding along the first row
    if m.is_empty() { return 1.0; }
    let mut total = 0.0;
    for j in 0..m.len() {
        let minor: Vec<Vec<f64>> = m[1..].iter()
            .map(|r| r.iter().enumerate().filter(|(c, _)| *c != j).map(|(_, v)| *v).collect()).collect();
        total += if j % 2 == 0 { 1.0 } else { -1.0 } * m[0][j] * det(&minor);
    }
    total
}
fn d(n: usize, k: usize, f: Field) -> Field {    // exterior derivative: a k-form to a (k+1)-form
    let (lo, hi) = (combos(n, k), combos(n, k + 1));
    Rc::new(move |p: &[f64]| {
        let mut out = Vec::new();
        for big in &hi {                         // coefficient of dx^J: sum of (-1)^m d_j w_(J without j)
            let mut s = 0.0;
            for (m, &j) in big.iter().enumerate() {
                let rest: Vec<usize> = big.iter().enumerate().filter(|(i, _)| *i != m).map(|(_, v)| *v).collect();
                let (r, sign) = (lo.iter().position(|c| *c == rest).unwrap(), if m % 2 == 0 { 1.0 } else { -1.0 });
                s += sign * (f(&bump(p, j, H))[r] - f(&bump(p, j, -H))[r]) / (2.0 * H);
            }
            out.push(s);
        }
        out
    })
}
fn integrate(nodes: &[(f64, f64)], n: usize, k: usize, f: &dyn Fn(&[f64]) -> Vec<f64>,
             c: &dyn Fn(&[f64]) -> Vec<f64>) -> f64 {   // pull w back along c, then add up
    let idx = combos(n, k);
    let pulled = |u: &[f64]| -> f64 {
        let p = c(u);
        let vs: Vec<Vec<f64>> = (0..k).map(|i| {
            let (a, b) = (c(&bump(u, i, H)), c(&bump(u, i, -H)));
            a.iter().zip(b.iter()).map(|(x, y)| (x - y) / (2.0 * H)).collect()
        }).collect();
        let mut total = 0.0;
        for (fi, big) in f(&p).iter().zip(idx.iter()) {   // a k-form eats k arrows
            let m: Vec<Vec<f64>> = vs.iter().map(|v| big.iter().map(|&i| v[i]).collect()).collect();
            total += fi * det(&m);
        }
        total
    };
    quad(nodes, &pulled, k)
}
fn faces(nodes: &[(f64, f64)], n: usize, k: usize, f: &dyn Fn(&[f64]) -> Vec<f64>,
         c: &dyn Fn(&[f64]) -> Vec<f64>) -> Vec<f64> {   // faces of a (k+1)-cube, signed (-1)^(i+1+a), i from 0
    let mut out = Vec::new();
    for i in 0..=k {
        for a in 0..2usize {
            let face = |t: &[f64]| { let mut v = t[..i].to_vec(); v.push(a as f64); v.extend_from_slice(&t[i..]); c(&v) };
            out.push(if (i + 1 + a) % 2 == 0 { 1.0 } else { -1.0 } * integrate(nodes, n, k, f, &face));
        }
    }
    out
}
fn boundary(nodes: &[(f64, f64)], n: usize, k: usize, f: &dyn Fn(&[f64]) -> Vec<f64>,
            c: &dyn Fn(&[f64]) -> Vec<f64>) -> f64 { faces(nodes, n, k, f, c).iter().fold(0.0, |a, b| a + b) }
fn h(x: f64, y: f64) -> f64 { 0.04 * (x - 3.0) * (x - 3.0) + 0.05 * y }   // ground height, km
fn wind(p: &[f64]) -> Vec<f64> { let (x, y, z) = (p[0], p[1], p[2]); vec![-0.1 * y * y + 0.5 * z, 12.0 + 0.2 * x * y + 2.0 * z, 0.05 * x] }
fn rain(p: &[f64]) -> Vec<f64> { let (y, z) = (p[1], p[2]); vec![0.0, 0.1 * y * (2.0 - z), -0.75 * (2.0 - z)] }
fn height(p: &[f64]) -> Vec<f64> { vec![h(p[0], p[1])] }                    // 0-form on the map
fn glider(p: &[f64]) -> Vec<f64> { wind(&[p[0], p[1], 1.0])[..2].to_vec() }  // P dx + Q dy at 1 km
fn flux(p: &[f64]) -> Vec<f64> { let g = rain(p); vec![g[2], -g[1], g[0]] }  // G1 dy^dz + G2 dz^dx + G3 dx^dy
fn path(u: &[f64]) -> Vec<f64> { vec![3.0 - 3.0 * u[0], 4.0 * u[0]] }
fn floor(u: &[f64]) -> Vec<f64> { vec![6.0 * u[0], 4.0 * u[1]] }
fn ground(u: &[f64]) -> Vec<f64> { vec![6.0 * u[0], 4.0 * u[1], h(6.0 * u[0], 4.0 * u[1])] }
fn air(u: &[f64]) -> Vec<f64> { let (x, y) = (6.0 * u[0], 4.0 * u[1]); vec![x, y, h(x, y) + u[2] * (2.0 - h(x, y))] }
fn vortex(p: &[f64]) -> Vec<f64> { let (dx, dy) = (p[0] - 3.0, p[1] - 2.0); vec![-dy / (dx * dx + dy * dy), dx / (dx * dx + dy * dy)] }
fn f6(v: f64) -> String { format!("{:.6}", v).replace("-0.000000", "0.000000") }   // no minus on a zero
fn z6(v: f64) -> String { format!("{:>12}", f6(v)) }
fn row(v: &[f64]) -> String { v.iter().map(|x| f6(*x)).collect::<Vec<_>>().join(", ") }
fn main() {
    let g10 = gauss(10);                         // 10 nodes: exact for polynomials up to degree 19
    let classic = [                              // road C: hand-derived gradient, curl, divergence
        quad(&g10, &|u| { let p = path(u); 0.08 * (p[0] - 3.0) * -3.0 + 0.05 * 4.0 }, 1),
        quad(&g10, &|u| 0.4 * (4.0 * u[1]) * 24.0, 2),
        quad(&g10, &|u| { let p = floor(u); (-2.0 * -(0.08 * (p[0] - 3.0)) + 0.45 * -0.05 + 0.4 * p[1]) * 24.0 }, 2),
        quad(&g10, &|u| { let p = air(u); (0.75 + 0.1 * (2.0 - p[2])) * 24.0 * (2.0 - h(p[0], p[1])) }, 3)];
    let cases: [(&str, usize, usize, Field, fn(&[f64]) -> Vec<f64>, f64); 4] = [
        ("k=0 path, climb in km", 2, 0, Rc::new(height), path, 0.56),
        ("k=1 plane, Green, km^2/h", 2, 1, Rc::new(glider), floor, 19.2),
        ("k=1 space, curl, km^2/h", 3, 1, Rc::new(wind), ground, 18.66),
        ("k=2 space, divergence", 3, 2, Rc::new(flux), air, 35.859904)];
    println!("{:<28}{:>12}{:>12}{:>12}{:>12}", "case", "boundary", "inside", "classical", "exact");
    for ((name, n, k, f, c, exact), cl) in cases.iter().zip(classic.iter()) {
        let edge = boundary(&g10, *n, *k, &**f, c);
        let inside = integrate(&g10, *n, k + 1, &*d(*n, *k, f.clone()), c);
        println!("{:<28}{}{}{}{}", name, z6(edge), z6(inside), z6(*cl), z6(*exact));
        assert!((edge - exact).abs() < 1e-6 && (inside - exact).abs() < 1e-6 && (cl - exact).abs() < 1e-6);
    }
    let p0 = [1.0, 2.0, 0.5];                    // d reads as gradient, curl and divergence here
    let (g, cw, dv) = (d(2, 0, Rc::new(height))(&p0[..2]), d(3, 1, Rc::new(wind))(&p0), d(3, 2, Rc::new(flux))(&p0));
    println!("at (1, 2, 0.5): d(height) = {}", row(&g));
    println!("  d(wind) on dy^dz, dz^dx, dx^dy = {}", row(&[cw[2], -cw[1], cw[0]]));
    println!("  d(rain) on dx^dy^dz = {:.6}", dv[0]);
    assert!((g[0] + 0.16).abs() < 1e-8 && (g[1] - 0.05).abs() < 1e-8 && (dv[0] - 0.9).abs() < 1e-8);
    assert!((cw[2] + 2.0).abs() < 1e-8 && (cw[1] + 0.45).abs() < 1e-8 && (cw[0] - 0.8).abs() < 1e-8);
    assert!((det(&[vec![1.0, 2.0], vec![3.0, 4.0]]) + 2.0).abs() < 1e-12);   // cofactor signs, both off-diagonal entries nonzero
    println!("map area {} km^2; integral of y dy {}; curl north part x rise {}", f6(integrate(&g10, 2, 2, &|_p: &[f64]| vec![1.0], &floor)), f6(quad(&g10, &|u: &[f64]| 16.0 * u[0], 1)), f6(-cw[1] * g[1]));
    let dwind = d(3, 1, Rc::new(wind));
    let curl_slip = move |p: &[f64]| { let v = dwind(p); vec![v[0], -v[1], v[2]] };
    let tilt = quad(&g10, &|u| { let p = floor(u); (-2.0 * -(0.08 * (p[0] - 3.0)) + 0.45 * -0.05) * 24.0 }, 2);
    let (sides, rim, bx) = (faces(&g10, 2, 1, &glider, &floor), faces(&g10, 3, 1, &wind, &ground), faces(&g10, 3, 2, &flux, &air));
    let no_ground = boundary(&g10, 3, 2, &flux, &air) - bx[4];
    let (clockwise, flat) = (-boundary(&g10, 3, 1, &wind, &ground), boundary(&g10, 2, 1, &glider, &floor));
    let slip = integrate(&g10, 3, 2, &curl_slip, &ground);
    let spin10 = boundary(&g10, 2, 1, &vortex, &floor);   // not a polynomial: 10 nodes are not exact here
    let g20 = gauss(20);
    let (spin_edge, spin_inside) = (boundary(&g20, 2, 1, &vortex, &floor), integrate(&g20, 2, 2, &*d(2, 1, Rc::new(vortex)), &floor));
    println!("sides west, east, south, north:");
    println!("  glider at 1 km = {}", row(&sides));
    println!("  rim on the ground = {}", row(&rim));
    println!("  rain, then ground and ceiling = {}", row(&bx));
    println!("curl flux through the ground from the tilt terms: {:.6}", tilt);
    println!("what breaks:");
    for (label, v) in [("rim walked clockwise:", clockwise), ("terrain treated as the flat map:", flat),
            ("dz^dx read as dx^dz:", slip), ("ground left out of the skin:", no_ground), ("whirlwind, boundary, 10 nodes:", spin10),
            ("whirlwind, boundary, 20 nodes:", spin_edge), ("whirlwind, inside, 20 nodes:", spin_inside)] {
        println!("  {:<34}{}", label, z6(v));
    }
    let tau = 2.0 * std::f64::consts::PI;
    assert!((bx[4] - 32.4592).abs() < 1e-6 && (tilt + 0.54).abs() < 1e-6 && (no_ground - 3.400704).abs() < 1e-6);
    assert!((spin_edge - tau).abs() < 1e-8 && spin_inside.abs() < 1e-6 && (spin10 - tau).abs() > 1e-6);
    assert!((slip - 19.74).abs() < 1e-6 && (flat - 19.2).abs() < 1e-6 && (clockwise + 18.66).abs() < 1e-6);
    println!("ALL CHECKS PASS");
}
