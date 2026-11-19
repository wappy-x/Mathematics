// de Rham cohomology of the torus -- the same check as the Python, in Rust.
// No crates.  Four roads to one answer, H^1(torus) has dimension 2:
//   road 1: loop integrals of closed 1-forms, Simpson's rule written out
//   road 2: Mayer-Vietoris, ranks of the restriction maps by exact integer elimination
//   road 3: Poincare duality, area integrals of wedge products, plus the Euler count
//   road 4: simplicial Betti numbers of a 3 x 3 grid torus, by exact rank
use std::collections::{BTreeMap, BTreeSet};
use std::f64::consts::PI;
const TAU: f64 = 2.0 * PI;

fn f6(x: f64) -> String { format!("{:.6}", if x.abs() < 5e-7 { 0.0 } else { x }) }

fn simpson(g: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = 0.0;
    for k in 1..n { s += (if k % 2 == 1 { 4.0 } else { 2.0 }) * g(a + k as f64 * h); }
    (g(a) + g(b) + s) * h / 3.0
}

// integral of P du + Q dv along path(t) = (u, v, du/dt, dv/dt)
fn lp(form: &dyn Fn(f64, f64) -> (f64, f64), path: &dyn Fn(f64) -> (f64, f64, f64, f64), t1: f64, n: usize) -> f64 {
    let g = |t: f64| { let (u, v, du, dv) = path(t); let (p, q) = form(u, v); p * du + q * dv };
    simpson(&g, 0.0, t1, n)
}

fn angle(x: f64, y: f64) -> (f64, f64) { let r2 = x * x + y * y; (-y / r2, x / r2) }

fn circle(cx: f64, cy: f64, r: f64) -> impl Fn(f64) -> (f64, f64, f64, f64) {
    move |t| (cx + r * t.cos(), cy + r * t.sin(), -r * t.sin(), r * t.cos())
}

// alpha = d(theta + amp cos(theta) cos(psi)), on the torus
fn encoder(amp: f64) -> impl Fn(f64, f64) -> (f64, f64) {
    move |th: f64, ps: f64| (1.0 - amp * th.sin() * ps.cos(), -amp * th.cos() * ps.sin())
}
fn dth(_: f64, _: f64) -> (f64, f64) { (1.0, 0.0) }
fn dps(_: f64, _: f64) -> (f64, f64) { (0.0, 1.0) }
fn turn_loop(ps0: f64) -> impl Fn(f64) -> (f64, f64, f64, f64) { move |t| (t, ps0, 1.0, 0.0) }
fn bob_loop(th0: f64) -> impl Fn(f64) -> (f64, f64, f64, f64) { move |t| (th0, t, 0.0, 1.0) }
fn ride(k: f64) -> impl Fn(f64) -> (f64, f64, f64, f64) { move |t| (t, k * t, 1.0, k) }

// integral over the torus of f1 ^ f2, midpoint rule
fn pair(f1: &dyn Fn(f64, f64) -> (f64, f64), f2: &dyn Fn(f64, f64) -> (f64, f64)) -> f64 {
    let n = 60;
    let (h, mut s) = (TAU / n as f64, 0.0);
    for i in 0..n {
        for j in 0..n {
            let (u, v) = ((i as f64 + 0.5) * h, (j as f64 + 0.5) * h);
            let ((p1, q1), (p2, q2)) = (f1(u, v), f2(u, v));
            s += p1 * q2 - q1 * p2;
        }
    }
    s * h * h
}

fn gcd(a: i64, b: i64) -> i64 { if b == 0 { a.abs() } else { gcd(b, a % b) } }

// exact rank by fraction-free integer elimination
fn rank(rows: &[Vec<i64>]) -> usize {
    let mut m: Vec<Vec<i64>> = rows.to_vec();
    let mut r = 0;
    let ncol = if m.is_empty() { 0 } else { m[0].len() };
    for c in 0..ncol {
        let p = match (r..m.len()).find(|&i| m[i][c] != 0) { Some(p) => p, None => continue };
        m.swap(r, p);
        for i in r + 1..m.len() {
            if m[i][c] != 0 {
                let (a, b) = (m[r][c], m[i][c]);
                let row: Vec<i64> = m[i].iter().zip(m[r].iter()).map(|(x, y)| a * x - b * y).collect();
                let g = row.iter().fold(0, |g, &x| gcd(g, x));
                m[i] = if g != 0 { row.iter().map(|x| x / g).collect() } else { row };
            }
        }
        r += 1;
    }
    r
}

// maps[k] = (dim H^k(overlap), dim H^k(U) + dim H^k(V), restriction matrix)
fn mv(maps: &[(usize, usize, Vec<Vec<i64>>)]) -> (Vec<usize>, Vec<usize>) {
    let rk: Vec<usize> = maps.iter().map(|(_, _, m)| rank(m)).collect();
    let b = (0..3).map(|k| (if k > 0 { maps[k - 1].0 - rk[k - 1] } else { 0 }) + maps[k].1 - rk[k]).collect();
    (b, rk)
}

// n x n grid of squares, each cut into 2 triangles, edges glued
fn grid(n: i64, twist: bool) -> (usize, usize, usize, usize, usize, Vec<usize>) {
    let v = |i: i64, j: i64| -> usize {
        let i = if twist && j == n { -i } else { i };
        (i.rem_euclid(n) + n * j.rem_euclid(n)) as usize
    };
    let mut tris = BTreeSet::new();
    for i in 0..n {
        for j in 0..n {
            let (a, b, c, d) = (v(i, j), v(i + 1, j), v(i + 1, j + 1), v(i, j + 1));
            for t in [[a, b, c], [a, c, d]] { let mut t = t; t.sort(); tris.insert(t); }
        }
    }
    let mut edges = BTreeSet::new();
    for t in &tris { edges.insert((t[0], t[1])); edges.insert((t[0], t[2])); edges.insert((t[1], t[2])); }
    let ei: BTreeMap<(usize, usize), usize> = edges.iter().enumerate().map(|(k, &e)| (e, k)).collect();
    let nv = (n * n) as usize;
    let d1: Vec<Vec<i64>> = (0..nv).map(|p| edges.iter().map(|e| if e.1 == p { 1 } else if e.0 == p { -1 } else { 0 }).collect()).collect();
    let mut d2 = vec![vec![0i64; tris.len()]; edges.len()];
    for (k, t) in tris.iter().enumerate() {
        d2[ei[&(t[1], t[2])]][k] += 1;
        d2[ei[&(t[0], t[2])]][k] -= 1;
        d2[ei[&(t[0], t[1])]][k] += 1;
    }
    assert!(d2.iter().all(|row| row.iter().filter(|&&x| x != 0).count() == 2)); // every edge on 2 triangles
    let (r1, r2) = (rank(&d1), rank(&d2));
    let (ne, nf) = (edges.len(), tris.len());
    (nv, ne, nf, r1, r2, vec![nv - r1, ne - r1 - r2, nf - r2])
}

fn main() {
    println!("carousel: ride 180 s, 15 s per turn, {} turns; crank 3 bobs per turn, {} bobs", 180 / 15, 3 * 180 / 15);
    let pp = [lp(&angle, &circle(0.0, 0.0, 3.0), TAU, 2400), lp(&angle, &circle(0.0, 0.0, 6.0), TAU, 2400), lp(&angle, &circle(5.0, 0.0, 2.0), TAU, 2400)];
    println!("punctured plane, angle form: circle r 3 m round the pole {}, r 6 m {}, r 2 m centred 5 m out {}", f6(pp[0]), f6(pp[1]), f6(pp[2]));
    assert!((pp[0] - TAU).abs() < 1e-9 && (pp[1] - TAU).abs() < 1e-9 && pp[2].abs() < 1e-9);
    let (al, h) = (encoder(0.05), 1e-5);
    let curl = (al(1.0 + h, 2.0).1 - al(1.0 - h, 2.0).1) / (2.0 * h) - (al(1.0, 2.0 + h).0 - al(1.0, 2.0 - h).0) / (2.0 * h);
    println!("encoder wobble 0.050000 rad = {} degrees; curl of alpha at (1, 2) {}", f6(0.05 * 180.0 / PI), f6(curl));
    let a: Vec<f64> = [0.0, 1.0, 2.0].iter().map(|&p| lp(&al, &turn_loop(p), TAU, 2400)).collect();
    let b: Vec<f64> = [0.0, 1.0, 2.0].iter().map(|&t| lp(&al, &bob_loop(t), TAU, 2400)).collect();
    println!("road 1, turn loop gamma1 at psi = 0, 1, 2: {} {} {}", f6(a[0]), f6(a[1]), f6(a[2]));
    println!("road 1, bob loop gamma2 at theta = 0, 1, 2: {} {} {}", f6(b[0]), f6(b[1]), f6(b[2]));
    let c1 = (a[1] / TAU, b[1] / TAU);
    println!("road 1, class of alpha read by loops: ({}, {})", f6(c1.0), f6(c1.1));
    let (ra, rp) = (lp(&al, &ride(3.0), 12.0 * TAU, 24000), lp(&dps, &ride(3.0), 12.0 * TAU, 24000));
    println!("ride path theta = t, psi = 3t, 12 turns: alpha {} = {} turns; dpsi {} = {} bobs", f6(ra), f6(ra / TAU), f6(rp), f6(rp / TAU));
    assert!(curl.abs() < 1e-6 && (ra - 24.0 * PI).abs() < 1e-8 && (rp - 72.0 * PI).abs() < 1e-8);
    let rr = vec![vec![-1i64, 1], vec![-1, 1]];
    let one = vec![vec![-1i64, 1]];
    let (bt, rk) = mv(&[(2, 2, rr.clone()), (2, 2, rr.clone()), (0, 0, vec![])]);
    println!("road 2, Mayer-Vietoris on two cylinders: ranks {}, {}; torus {} {} {}", rk[0], rk[1], bt[0], bt[1], bt[2]);
    let (bp, _) = mv(&[(2, 2, rr.clone()), (0, 0, vec![]), (0, 0, vec![])]);
    let (bs, _) = mv(&[(1, 2, one.clone()), (1, 0, vec![]), (0, 0, vec![])]);
    println!("road 2, Mayer-Vietoris: punctured plane {} {} {}; sphere {} {} {}", bp[0], bp[1], bp[2], bs[0], bs[1], bs[2]);
    assert!(bp == vec![1, 1, 0] && bs == vec![1, 0, 1]);
    let v4 = pair(&dth, &dps);
    let m = [[pair(&dth, &dth), v4], [pair(&dps, &dth), pair(&dps, &dps)]];
    println!("road 3, <dtheta, dpsi> = {} = 4 pi^2; matrix [[{}, {}], [{}, {}]], det {}", f6(v4), f6(m[0][0]), f6(m[0][1]), f6(m[1][0]), f6(m[1][1]), f6(m[0][0] * m[1][1] - m[0][1] * m[1][0]));
    let c3 = (pair(&al, &dps) / v4, pair(&dth, &al) / v4);
    println!("road 3, class of alpha read by areas: ({}, {})", f6(c3.0), f6(c3.1));
    assert!((v4 - 4.0 * PI * PI).abs() < 1e-9 && (m[1][0] + v4).abs() < 1e-9 && (c3.0 - c1.0).abs() < 1e-9 && (c3.1 - c1.1).abs() < 1e-9);
    let (nv, ne, nf, r1, r2, bg) = grid(3, false);
    let chi = nv as i64 - ne as i64 + nf as i64;
    println!("road 3, duality b2 = b0 = 1; Euler count {} - {} + {} = {}; b1 = 1 + 1 - {} = {}", nv, ne, nf, chi, chi, 2 - chi);
    println!("road 4, grid torus: V {}, E {}, F {}; rank d1 {}, rank d2 {}; Betti {} {} {}", nv, ne, nf, r1, r2, bg[0], bg[1], bg[2]);
    assert!(bg == bt && bt[1] as i64 == 2 - chi); // simplicial = Mayer-Vietoris = duality count
    let (nv, ne, nf, _, _, bk) = grid(3, true);
    println!("break 1, Klein bottle grid: V {}, E {}, F {}; Betti {} {} {}, so b2 is not b0", nv, ne, nf, bk[0], bk[1], bk[2]);
    assert!(bk == vec![1, 1, 0] && bk[2] != bk[0]);
    println!("break 2, punctured plane, not compact: b0 {}, b2 {}", bp[0], bp[2]);
    let nc: Vec<f64> = [0.0, PI / 2.0].iter().map(|&p0| lp(&|_t: f64, p: f64| (p.sin(), 0.0), &turn_loop(p0), TAU, 2400)).collect();
    println!("break 3, sin(psi) dtheta, not closed: turn loop at psi = 0 {}, at psi = pi/2 {}", f6(nc[0]), f6(nc[1]));
    assert!((nc[1] - nc[0] - TAU).abs() < 1e-9);
    let (bw, _) = mv(&[(1, 2, one.clone()), (1, 2, one.clone()), (0, 0, vec![])]);
    println!("break 4, overlap counted as one cylinder: {} {} {}", bw[0], bw[1], bw[2]);
    assert!(bw[1] != bt[1]);
    let (r4, w2) = (lp(&dps, &ride(4.0), 12.0 * TAU, 24000), encoder(0.2));
    println!("try: 4 bobs per turn: dpsi over the ride {} = {} bobs", f6(r4), f6(r4 / TAU));
    let g = 2i64; // the genus, the number of handles
    println!("try: wobble 0.2 rad: class ({}, {}); genus {}: chi {}, b1 = 1 + 1 - ({}) = {}", f6(lp(&w2, &turn_loop(1.0), TAU, 2400) / TAU), f6(lp(&w2, &bob_loop(1.0), TAU, 2400) / TAU), g, 2 - 2 * g, 2 - 2 * g, 2 - (2 - 2 * g));
    println!("figure, square 0 to {} rad both ways; gamma1 at psi = 1; gamma2 at theta = 1; ride segments start at theta = 0.000000, {}, {}", f6(TAU), f6(TAU / 3.0), f6(2.0 * TAU / 3.0));
    println!("ALL CHECKS PASS");
}
