// Change of variables, proved -- the same check in Rust, std only.
// Linear case: L = shear after stretch.  Then the polar moment of a disc, radius 2 cm, by
// polar coordinates, by a blind x-y grid, by cutting into pieces, and by two one-coordinate moves.
use std::f64::consts::PI;
type M = [[f64; 2]; 2];
fn mul(a: &M, b: &M) -> M {
    let mut c = [[0.0; 2]; 2];
    for i in 0..2 { for j in 0..2 { c[i][j] = a[i][0] * b[0][j] + a[i][1] * b[1][j]; } }
    c
}
fn det(m: &M) -> f64 { m[0][0] * m[1][1] - m[0][1] * m[1][0] }
fn shoelace(p: &[(f64, f64)]) -> f64 {           // area of a polygon from its corners, in order
    (0..p.len()).map(|k| { let (a, b) = (p[k], p[(k + 1) % p.len()]); a.0 * b.1 - b.0 * a.1 }).sum::<f64>() / 2.0
}
fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64) -> f64 {   // Simpson's rule on 200 strips
    let (n, s) = (200, f(a) + f(b));
    let h = (b - a) / n as f64;
    (s + (1..n).map(|k| if k % 2 == 1 { 4.0 } else { 2.0 } * f(a + k as f64 * h)).sum::<f64>()) * h / 3.0
}
fn grid(f: &dyn Fn(f64, f64) -> f64, inside: &dyn Fn(f64, f64) -> bool, lo: f64, hi: f64, n: usize) -> f64 {
    let (h, mut s) = ((hi - lo) / n as f64, 0.0);  // midpoint cells on a square box, kept if inside
    for i in 0..n { for j in 0..n {
        let (x, y) = (lo + (i as f64 + 0.5) * h, lo + (j as f64 + 0.5) * h);
        if inside(x, y) { s += f(x, y); }
    } }
    s * h * h
}
fn f(x: f64, y: f64) -> f64 { x * x + y * y }    // squared distance from the axis, cm^2
fn pieces(nr: usize, nt: usize) -> f64 {         // sum f(T(centre)) x shoelace area of T(cell)
    let (m, mut s, dr, dt) = (8, 0.0, 2.0 / nr as f64, 2.0 * PI / nt as f64);
    for i in 0..nr { for j in 0..nt {
        let (r0, t0) = (i as f64 * dr, j as f64 * dt);
        let mut e: Vec<(f64, f64)> = (0..m).map(|k| (r0 + dr * k as f64 / m as f64, t0)).collect();
        e.extend((0..m).map(|k| (r0 + dr, t0 + dt * k as f64 / m as f64)));
        e.extend((0..m).map(|k| (r0 + dr - dr * k as f64 / m as f64, t0 + dt)));
        e.extend((0..m).map(|k| (r0, t0 + dt - dt * k as f64 / m as f64)));
        let pts: Vec<(f64, f64)> = e.iter().map(|&(r, t)| (r * t.cos(), r * t.sin())).collect();
        s += (r0 + dr / 2.0).powi(2) * shoelace(&pts);
    } }
    s
}
fn main() {
    let (s, h): (M, M) = ([[2.0, 0.0], [0.0, 3.0]], [[1.0, 1.0 / 3.0], [0.0, 1.0]]);   // stretch; shear
    let l = mul(&h, &s);
    let par: Vec<(f64, f64)> = [(0.0, 0.0), (1.0, 0.0), (1.0, 1.0), (0.0, 1.0)].iter()
        .map(|&(u, v)| (l[0][0] * u + l[0][1] * v, l[1][0] * u + l[1][1] * v)).collect();
    let (pl, swp): (M, Vec<(f64, f64)>) = (mul(&[[0.0, 1.0], [1.0, 0.0]], &l), par.iter().map(|&(a, b)| (b, a)).collect());  // a swap after L: not triangular
    println!("L = shear x stretch: rows ({}, {}), ({}, {}); det stretch {}, det shear {}, det L {:.6}", l[0][0], l[0][1], l[1][0], l[1][1], det(&s), det(&h), det(&l));
    let c: Vec<String> = par.iter().map(|&(a, b)| format!("({}, {})", a, b)).collect();
    println!("image of the unit square: corners {}; area by shoelace {:.6}; after a swap {:.6}, det {}", c.join(" "), shoelace(&par), shoelace(&swp), det(&pl));
    println!("mistake, side lengths multiplied: {:.6}", l[0][0].hypot(l[1][0]) * l[0][1].hypot(l[1][1]));
    let ins = |x: f64, y: f64| {                  // pull the point back by L inverse, test the square
        let (u, v) = ((l[1][1] * x - l[0][1] * y) / det(&l), (l[0][0] * y - l[1][0] * x) / det(&l));
        0.0 <= u && u <= 1.0 && 0.0 <= v && v <= 1.0
    };
    let lin_grid = grid(&f, &ins, -0.001, 3.001, 600);  // box padded 0.001 cm, so no cell centre sits on an edge
    let lin_sq = det(&l).abs() * simpson(&|u| simpson(&|v| f(l[0][0] * u + l[0][1] * v, l[1][0] * u + l[1][1] * v), 0.0, 1.0), 0.0, 1.0);
    println!("polar moment of the plate about its corner: x-y grid {:.6}; square x 6 {:.6}; by hand 6 x 17/3 = 34", lin_grid, lin_sq);
    let polar = simpson(&|_t| simpson(&|r| r.powi(3), 0.0, 2.0), 0.0, 2.0 * PI);
    println!("disc radius 2: polar with factor r {:.6}; by hand 2 pi x 4 = {:.6}", polar, 8.0 * PI);
    let mut g = 0.0;
    for n in [200usize, 800] {
        g = grid(&f, &|x, y| x * x + y * y <= 4.0, -2.0, 2.0, n);
        println!("x-y grid {} a side, blind to r: {:.6}, error {:+.6}", n, g, g - 8.0 * PI);
    }
    let cut = [pieces(10, 40), pieces(40, 160)];
    println!("cut into pieces, no Jacobian used: 10 x 40 cells {:.6}; 40 x 160 cells {:.6}", cut[0], cut[1]);
    let (d, r, t) = (1e-6, 1.5f64, 0.6f64);      // one address; factor polar into two moves
    let x = r * t.cos();
    let m1 = (t.cos() * (r + d) - t.cos() * (r - d)) / (2.0 * d);           // (r, t) -> (x, t)
    let m2 = (x * (t + d).tan() - x * (t - d).tan()) / (2.0 * d);           // (x, t) -> (x, x tan t)
    println!("at r {}, theta {}: move 1 det {:.6}, move 2 det {:.6}, product {:.6} = r", r, t, m1, m2, m1 * m2);
    println!("mistakes: factor r dropped {:.6}; theta run twice round {:.6}; factor 1/r {:.6}", simpson(&|_t| simpson(&|r| r * r, 0.0, 2.0), 0.0, 2.0 * PI), 2.0 * polar, 4.0 * PI);
    assert!((shoelace(&par) - det(&s) * det(&h)).abs() < 1e-12 && (det(&l) - 6.0).abs() < 1e-12 && (shoelace(&swp) - det(&pl)).abs() < 1e-12);
    assert!((lin_grid - 34.0).abs() < 0.05 && (lin_sq - 34.0).abs() < 1e-9);    // plate: blind grid meets the square
    assert!((polar - 8.0 * PI).abs() < 1e-9 && (g - 8.0 * PI).abs() < 0.01);    // disc: polar meets the blind grid
    assert!((cut[1] - 8.0 * PI).abs() < 0.01 && (m1 * m2 - r).abs() < 1e-6);  // pieces close in; moves multiply to r
    println!("ALL CHECKS PASS");
}
