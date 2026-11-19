// Smooth manifold -- the same check as the Python, in Rust.  No crates.
// The Earth is a sphere of radius 6371 km.  Six map sheets each look straight
// down on one half of it (orthographic projection): a sheet keeps two of the
// point's coordinates (X, Y, Z) and drops the third.  The card's claim is that
// every change of sheet is smooth.  Road 1: derivative matrices by formula.
// Road 2: difference quotients at two step sizes.  A rate measured on the
// ground is then computed in two sheets, which must agree.
const R: f64 = 6371.0;
type Sheet = (&'static str, usize, f64);
type M2 = [[f64; 2]; 2];
const SHEETS: [Sheet; 6] = [("North", 2, 1.0), ("South", 2, -1.0), ("Greenwich", 0, 1.0),
    ("Date line", 0, -1.0), ("East", 1, 1.0), ("West", 1, -1.0)];

fn point(lat: f64, lon: f64) -> [f64; 3] {          // degrees to (X, Y, Z) in km
    let (a, b) = (lat.to_radians(), lon.to_radians());
    [R * a.cos() * b.cos(), R * a.cos() * b.sin(), R * a.sin()]
}
fn on_sheet(p: &[f64; 3], s: Sheet) -> bool { s.2 * p[s.1] > 0.0 } // open half: rim left out
fn chart(p: &[f64; 3], s: Sheet) -> [f64; 2] {
    let k: Vec<f64> = (0..3).filter(|&i| i != s.1).map(|i| p[i]).collect();
    [k[0], k[1]]
}
fn lift(u: [f64; 2], s: Sheet) -> [f64; 3] {       // inverse chart: put back the dropped coordinate
    let mut p = vec![u[0], u[1]];
    p.insert(s.1, s.2 * (R * R - u[0].powf(2.0) - u[1].powf(2.0)).sqrt());
    [p[0], p[1], p[2]]
}
fn change(u: [f64; 2], s: Sheet, t: Sheet) -> [f64; 2] { chart(&lift(u, s), t) }

fn jac_formula(u: [f64; 2], s: Sheet, t: Sheet) -> M2 {   // road 1: row = output, column = input
    let (p, k) = (lift(u, s), s.1);
    let ins: Vec<usize> = (0..3).filter(|&i| i != k).collect();
    let outs: Vec<usize> = (0..3).filter(|&o| o != t.1).collect();
    let mut j = [[0.0; 2]; 2];
    for (r, &o) in outs.iter().enumerate() {
        for (c, &i) in ins.iter().enumerate() {
            j[r][c] = if o == k { -p[i] / p[k] } else if o == i { 1.0 } else { 0.0 };
        }
    }
    j
}
fn jac_steps(u: [f64; 2], s: Sheet, t: Sheet, h: f64) -> M2 {  // road 2: central differences
    let mut j = [[0.0; 2]; 2];
    for c in 0..2 {
        let (mut up, mut dn) = (u, u);
        up[c] += h;
        dn[c] -= h;
        let (a, b) = (change(up, s, t), change(dn, s, t));
        for r in 0..2 { j[r][c] = (a[r] - b[r]) / (2.0 * h) }
    }
    j
}
fn gap(a: &M2, b: &M2) -> f64 {
    let mut g: f64 = 0.0;
    for i in 0..2 { for j in 0..2 { g = g.max((a[i][j] - b[i][j]).abs()) } }
    g
}
fn det(j: &M2) -> f64 { j[0][0] * j[1][1] - j[0][1] * j[1][0] }
fn mul(a: &M2, b: &M2) -> M2 {
    let mut m = [[0.0; 2]; 2];
    for i in 0..2 { for j in 0..2 { m[i][j] = 0.0 + a[i][0] * b[0][j] + a[i][1] * b[1][j] } }
    m
}
fn yn(c: bool) -> &'static str { if c { "yes" } else { "no" } }

fn rate(s: Sheet, h: f64, lat: f64, lon: f64, p: &[f64; 3]) -> ([f64; 2], f64) {
    let a = chart(&point(lat + (h / R).to_degrees(), lon), s);   // walk north from London
    let b = chart(&point(lat - (h / R).to_degrees(), lon), s);
    let vel = [(a[0] - b[0]) / (2.0 * h), (a[1] - b[1]) / (2.0 * h)];
    let c = chart(p, s);
    let q = lift(c, s);                                          // gradient of Z, chain rule
    let grad = if s.1 == 2 { [-c[0] / q[2], -c[1] / q[2]] } else { [0.0, 1.0] };
    (vel, grad[0] * vel[0] + grad[1] * vel[1])
}

fn main() {
    let mut grid = Vec::new();
    for la in (-90..=90).step_by(5) { for lo in (-180..180).step_by(5) { grid.push(point(la as f64, lo as f64)) } }
    let counts: Vec<usize> = grid.iter().map(|p| SHEETS.iter().filter(|&&s| on_sheet(p, s)).count()).collect();
    let mut pairs = Vec::new();
    for i in 0..6 { for j in i + 1..6 {
        let (s, t) = (SHEETS[i], SHEETS[j]);
        if grid.iter().any(|p| on_sheet(p, s) && on_sheet(p, t)) { pairs.push((s, t)) }
    } }
    let (mut worst, mut smallest): (f64, f64) = (0.0, 1e9);
    for &(s, t) in &pairs {
        for (a, b) in [(s, t), (t, s)] {
            let mut p = [R * 3.0 / 7.0, R * 2.0 / 7.0, R * 6.0 / 7.0];
            p[a.1] *= a.2;
            p[b.1] *= b.2;
            let u = chart(&p, a);
            worst = worst.max(gap(&jac_formula(u, a, b), &jac_steps(u, a, b, 0.01)));
            smallest = smallest.min(det(&jac_formula(u, a, b)).abs());
        }
    }
    let (fewest, most) = (*counts.iter().min().unwrap(), *counts.iter().max().unwrap());
    println!("grid points {}; sheets per point: fewest {}, most {}", grid.len(), fewest, most);
    println!("pairs of sheets that overlap: {} of 15; transitions checked both ways: {}", pairs.len(), 2 * pairs.len());
    println!("formula and difference quotients agree to 1e-6 on all {}: {}", 2 * pairs.len(), yn(worst < 1e-6));
    println!("smallest |det J| among them: {:.4}", smallest);

    let (n, g) = (SHEETS[0], SHEETS[2]);
    let (lat, lon) = (51.5074, -0.1278);
    let p = point(lat, lon);
    let (u, v) = (chart(&p, n), chart(&p, g));
    let (j, k) = (jac_formula(u, n, g), jac_formula(v, g, n));
    println!("London {:.4} N, {:.4} W: (X, Y, Z) = ({:.1}, {:.1}, {:.1}) km", lat, -lon, p[0], p[1], p[2]);
    println!("North sheet ({:.1}, {:.1}); Greenwich sheet ({:.1}, {:.1})", u[0], u[1], v[0], v[1]);
    let w = change(u, n, g);
    println!("North to Greenwich by the transition: ({:.1}, {:.1})", w[0], w[1]);
    println!("J at London: [[{:.4}, {:.4}], [{:.4}, {:.4}]]; det J = X/Z = {:.4}", j[0][0], j[0][1], j[1][0], j[1][1], det(&j));
    for h in [1.0, 0.1] {
        println!("step {:.1} km: difference quotients miss J by {:.10}", h, gap(&j, &jac_steps(u, n, g, h)));
    }
    let ij = mul(&k, &j);
    let one = (ij[0][0] - 1.0).abs() < 1e-12 && ij[0][1].abs() < 1e-12 && ij[1][0].abs() < 1e-12 && (ij[1][1] - 1.0).abs() < 1e-12;
    println!("J back times J forward is the identity to 1e-12: {}", yn(one));
    let a = point(5.6037, -0.1870);
    println!("Accra {:.4} N, near the North sheet's rim: slope -X/Z = {:.2}", 5.6037, -a[0] / a[2]);
    let e = point(0.01, 0.0);
    println!("0.01 deg north of the equator: slope -X/Z = {:.2}; on the equator Z = 0", -e[0] / e[2]);
    let exact = lat.to_radians().cos();
    for s in [n, g] {
        for h in [1.0, 0.1] {
            let (vel, r) = rate(s, h, lat, lon, &p);
            println!("{} sheet, step {:.1} km: velocity ({:.4}, {:.4}), sheet speed {:.4}, dZ/ds {:.6}, off by {:.10}",
                     s.0, h, vel[0], vel[1], vel[0].hypot(vel[1]), r, (r - exact).abs());
        }
    }
    println!("exact dZ/ds = cos(latitude) = {:.6}; ground speed 1", exact);

    let rho = u[0].hypot(u[1]);                              // the stereographic north map
    let st = R * rho / (R + (R * R - rho * rho).sqrt());
    let back = 2.0 * R * R * st / (R * R + st * st);
    println!("North sheet {:.1} km out -> stereographic {:.1} km -> back {:.1} km", rho, st, back);
    for h in [0.001f64, 0.000001] {                          // charts t and t^3 on the line
        println!("line, step {:.6}: slope of t^3 at 0 = {:.12}, of cube root = {:.1}", h, h.powf(3.0) / h, h.powf(1.0 / 3.0) / h);
    }
    let (cx, cy, sc) = (190.0, 210.0, 160.0 / R);
    println!("figure, London ({:.2}, {:.2}), Accra ({:.2}, {:.2})", cx + sc * p[0], cy - sc * p[2], cx + sc * a[0], cy - sc * a[2]);

    let (v1, r1) = rate(n, 0.1, lat, lon, &p);
    let (v2, r2) = rate(g, 0.1, lat, lon, &p);
    assert!(fewest == 1 && most == 3 && pairs.len() == 12);              // an atlas, 12 overlaps
    assert!(worst < 1e-6 && smallest > 0.1);                             // road 1 against road 2
    assert!((w[0] - v[0]).abs() < 1e-9 && (w[1] - v[1]).abs() < 1e-9);   // transition lands right
    assert!(one);                                                        // J back undoes J
    assert!((r1 - exact).abs() < 1e-6 && (r2 - exact).abs() < 1e-6);     // one rate, two sheets
    assert!((v1[0].hypot(v1[1]) - v2[0].hypot(v2[1])).abs() > 0.1);      // components differ
    assert!((back - rho).abs() < 1e-6 && (st - 2224.4).abs() < 0.05);    // matches the topology card
    println!("ALL CHECKS PASS");
}
