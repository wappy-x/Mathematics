// Mean value and maximum principle -- the same check as the Python, in Rust.
// No crates.  The soap film u = x^2 - y^2 on the wire frame |z| = 1.  Road one:
// closed forms.  Road two: averages round circles, Cauchy's loop sum with a small
// (re, im) pair, and a grid film grown by neighbour averaging.
use std::f64::consts::PI;

fn u(x: f64, y: f64) -> f64 { x * x - y * y }
fn pushed(x: f64, y: f64) -> f64 { u(x, y) + 1.5 * (1.0 - x * x - y * y) }   // same frame, pushed from below
fn lnmod(x: f64, y: f64) -> f64 { 0.5 * (x * x + y * y).ln() }             // ln|z|, harmonic except at 0
fn pt(r: f64, k: usize, n: usize) -> (f64, f64) { let t = 2.0 * PI * k as f64 / n as f64; (r * t.cos(), r * t.sin()) }
fn lap(g: &dyn Fn(f64, f64) -> f64) -> f64 { let h = 0.1; (g(h, 0.0) + g(-h, 0.0) + g(0.0, h) + g(0.0, -h) - 4.0 * g(0.0, 0.0)) / (h * h) }   // net bending at 0
fn fx(v: f64) -> String { format!("{:.6}", if v.abs() < 5e-7 { 0.0 } else { v }) }
fn mul(p: (f64, f64), q: (f64, f64)) -> (f64, f64) { (p.0 * q.0 - p.1 * q.1, p.0 * q.1 + p.1 * q.0) }
fn div(p: (f64, f64), q: (f64, f64)) -> (f64, f64) { let d = q.0 * q.0 + q.1 * q.1; ((p.0 * q.0 + p.1 * q.1) / d, (p.1 * q.0 - p.0 * q.1) / d) }

fn avg(g: &dyn Fn(f64, f64) -> f64, cx: f64, cy: f64, r: f64) -> f64 {   // plain average, 64 equal steps
    (0..64).map(|k| { let (x, y) = pt(r, k, 64); g(cx + x, cy + y) }).sum::<f64>() / 64.0
}

fn cauchy(a: (f64, f64), n: usize) -> (f64, f64) {   // (1/2 pi i) x loop sum of z^2/(z - a) dz round |z| = 1
    let mut s = (0.0, 0.0);
    for k in 0..n {
        let z = pt(1.0, k, n);
        let t = mul(div(mul(z, z), (z.0 - a.0, z.1 - a.1)), mul((0.0, 2.0 * PI / n as f64), z));
        s = (s.0 + t.0, s.1 + t.1);
    }
    div(s, (0.0, 2.0 * PI))
}

fn ring(r: f64) -> (f64, f64) {                      // highest and lowest film height on |z| = r
    (0..360).map(|k| { let (x, y) = pt(r, k, 360); u(x, y) }).fold((f64::MIN, f64::MAX), |m, h| (m.0.max(h), m.1.min(h)))
}

const N: i32 = 10;
fn ix(i: i32, j: i32) -> usize { ((i + N + 1) * (2 * N + 3) + (j + N + 1)) as usize }
fn inside() -> Vec<(i32, i32)> { (-N..=N).flat_map(|i| (-N..=N).map(move |j| (i, j))).filter(|&(i, j)| i * i + j * j < N * N).collect() }

fn relax(start: f64) -> (Vec<f64>, Vec<f64>) {       // grid film, step 1/N: each inside node -> 4 neighbours' average
    let ins = inside();
    let mut g = vec![0.0; ((2 * N + 3) * (2 * N + 3)) as usize];
    for i in -N - 1..=N + 1 { for j in -N - 1..=N + 1 { g[ix(i, j)] = u(i as f64 / N as f64, j as f64 / N as f64) } }
    for &(i, j) in &ins { g[ix(i, j)] = start }
    for _ in 0..3000 {
        for &(i, j) in &ins { g[ix(i, j)] = (g[ix(i + 1, j)] + g[ix(i - 1, j)] + g[ix(i, j + 1)] + g[ix(i, j - 1)]) / 4.0 }
    }
    let frame = ins.iter().flat_map(|&(i, j)| [(i + 1, j), (i - 1, j), (i, j + 1), (i, j - 1)])
        .filter(|q| !ins.contains(q)).map(|(i, j)| g[ix(i, j)]).collect();
    (g, frame)
}

fn main() {
    let a = (0.3, 0.4);
    println!("figure, 1 unit = the 10 cm frame radius, heights in mm; 80 units per 1: centre (180, 120), frame radius 80, a = 0.3 + 0.4i at (204, 88), circle round a radius 32");
    let rs: Vec<String> = [0.25, 0.5, 1.0].iter().map(|&r| fx(avg(&u, 0.0, 0.0, r))).collect();
    println!("round 0, radii 0.25, 0.5, 1: averages {}; u(0) = {}", rs.join(", "), fx(u(0.0, 0.0)));
    println!("a = 0.3 + 0.4i: u(a) = {}; average on radius 0.4 = {}", fx(u(0.3, 0.4)), fx(avg(&u, 0.3, 0.4, 0.4)));
    let (c, sq) = (cauchy(a, 64), mul(a, a));
    println!("Cauchy loop sum of z^2/(z - a), 64 points = {} + {}i; a^2 = {} + {}i", fx(c.0), fx(c.1), fx(sq.0), fx(sq.1));
    for r in [0.0, 0.25, 0.5, 0.75, 1.0] {
        let (hi, lo) = ring(r);
        println!("circle r = {}: highest {}, lowest {}; r^2 = {}", r, fx(hi), fx(lo), fx(r * r));
    }
    let ((g0, frame), g5, ins) = (relax(0.0), relax(5.0).0, inside());
    let top = ins.iter().map(|&(i, j)| g0[ix(i, j)]).fold(f64::MIN, f64::max);
    let (flo, fhi) = frame.iter().fold((f64::MAX, f64::MIN), |m, &h| (m.0.min(h), m.1.max(h)));
    println!("grid film, step 0.1: centre {}, at 0.5 {}, highest inside node {}, frame nodes {} to {}", fx(g0[ix(0, 0)]), fx(g0[ix(5, 0)]), fx(top), fx(flo), fx(fhi));
    let gap = ins.iter().map(|&(i, j)| (g0[ix(i, j)] - g5[ix(i, j)]).abs()).fold(0.0, f64::max);
    println!("grid films from starts 0 and 5: largest gap {}", fx(gap));
    println!("Laplacian at 0 by differences: film {}, pushed sheet {}", fx(lap(&u)), fx(lap(&pushed)));
    println!("mistake 1, sheet pushed from below: centre {}, frame highest {}, rim average {}", fx(pushed(0.0, 0.0)), fx(ring(1.0).0), fx(avg(&pushed, 0.0, 0.0, 1.0)));
    println!("mistake 2, half-plane x > 0, films 0 and x, both 0 on the edge x = 0: at z = 1 they give {} and {}", fx(0.0), fx(1.0));
    println!("mistake 3, ln|z| round 0.5, radius 1, the hole at 0 inside: average {}, not ln 0.5 = {}", fx(avg(&lnmod, 0.5, 0.0, 1.0)), fx(0.5f64.ln()));
    assert!([(0.0, 0.0, 1.0), (0.3, 0.4, 0.4), (0.5, 0.0, 0.3)].iter().all(|&(x, y, r)| (avg(&u, x, y, r) - u(x, y)).abs() < 1e-12));
    assert!((c.0 - sq.0).hypot(c.1 - sq.1) < 1e-12);                 // Cauchy road: F(a) = a^2
    assert!([0.25, 0.5, 0.75, 1.0].iter().all(|&r| (ring(r).0 - r * r).abs() < 1e-12 && (ring(r).1 + r * r).abs() < 1e-12));
    assert!(gap < 1e-9 && ins.iter().all(|&(i, j)| (g0[ix(i, j)] - u(i as f64 / 10.0, j as f64 / 10.0)).abs() < 1e-9));   // one film only
    println!("ALL CHECKS PASS");
}
