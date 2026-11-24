// Holomorphic functional calculus and Riesz projections -- the check behind the card.  std only.
// f(T) = (1/(2 pi i)) x (loop integral of f(z) (zI - T)^-1 dz), computed by the trapezoid rule on a circle.
// Complex numbers are a small struct; inverses, products, exponentials and norms are written out.
use std::f64::consts::PI;

#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
fn c(re: f64, im: f64) -> C { C { re, im } }
fn add(a: C, b: C) -> C { c(a.re + b.re, a.im + b.im) }
fn sub(a: C, b: C) -> C { c(a.re - b.re, a.im - b.im) }
fn cmul(a: C, b: C) -> C { c(a.re * b.re - a.im * b.im, a.re * b.im + a.im * b.re) }
fn cdiv(a: C, b: C) -> C {           // Smith's method, as Python divides complex numbers
    if b.re.abs() >= b.im.abs() {
        let r = b.im / b.re; let d = b.re + b.im * r;
        c((a.re + a.im * r) / d, (a.im - a.re * r) / d)
    } else {
        let r = b.re / b.im; let d = b.re * r + b.im;
        c((a.re * r + a.im) / d, (a.im * r - a.re) / d)
    }
}
fn cabs(a: C) -> f64 { a.re.hypot(a.im) }
fn cexp(z: C) -> C { let e = z.re.exp(); c(e * z.im.cos(), e * z.im.sin()) }
fn one(_z: C) -> C { c(1.0, 0.0) }
fn pole(z: C) -> C { cdiv(c(1.0, 0.0), sub(z, c(2.0, 0.0))) }
type M = Vec<Vec<f64>>;
fn f6(t: f64) -> String { format!("{:.6}", if t.abs() >= 5e-7 { t } else { 0.0 }) }   // never "-0.000000"
fn mat(a: &M) -> String {
    let rows: Vec<String> = a.iter().map(|r| r.iter().map(|&v| f6(v)).collect::<Vec<_>>().join(", ")).collect();
    format!("[[{}]]", rows.join("], ["))
}
fn dot(a: &[f64], b: &[f64]) -> f64 { let mut s = 0.0; for (p, q) in a.iter().zip(b) { s += p * q; } s }
fn col(b: &M, j: usize) -> Vec<f64> { b.iter().map(|r| r[j]).collect() }
fn mul(a: &M, b: &M) -> M { (0..a.len()).map(|i| (0..b[0].len()).map(|j| dot(&a[i], &col(b, j))).collect()).collect() }
fn gap(a: &M, b: &M) -> f64 {
    let mut g: f64 = 0.0;
    for (ra, rb) in a.iter().zip(b) { for (x, y) in ra.iter().zip(rb) { g = g.max((x - y).abs()); } }
    g
}
fn inverse(a: Vec<Vec<C>>) -> Vec<Vec<C>> {   // Gauss-Jordan with partial pivoting
    let n = a.len();
    let mut m: Vec<Vec<C>> = (0..n).map(|i| { let mut r = a[i].clone(); r.extend((0..n).map(|j| c(if i == j { 1.0 } else { 0.0 }, 0.0))); r }).collect();
    for k in 0..n {
        let mut p = k;
        for r in k + 1..n { if cabs(m[r][k]) > cabs(m[p][k]) { p = r; } }
        m.swap(k, p);
        let piv = m[k][k];
        m[k] = m[k].iter().map(|&v| cdiv(v, piv)).collect();
        for r in 0..n {
            if r != k {
                let f = m[r][k];
                let row: Vec<C> = m[r].iter().zip(&m[k]).map(|(&x, &y)| sub(x, cmul(f, y))).collect();
                m[r] = row;
            }
        }
    }
    m.into_iter().map(|r| r[n..].to_vec()).collect()
}
fn calculus(f: fn(C) -> C, a: &M, centre: f64, radius: f64, nodes: usize) -> M {
    let n = a.len();
    let mut s = vec![vec![c(0.0, 0.0); n]; n];
    for k in 0..nodes {
        let t = 2.0 * PI * k as f64 / nodes as f64;
        let w = c(radius * t.cos(), radius * t.sin());
        let z = c(centre + w.re, w.im);  // dz = i w dtheta; the i cancels the i in 1/(2 pi i)
        let r = inverse((0..n).map(|i| (0..n).map(|j| sub(if i == j { z } else { c(0.0, 0.0) }, c(a[i][j], 0.0))).collect()).collect());
        for i in 0..n { for j in 0..n {
            let v = cmul(cmul(f(z), r[i][j]), w);
            s[i][j] = add(s[i][j], c(v.re / nodes as f64, v.im / nodes as f64));
        } }
    }
    s.iter().map(|r| r.iter().map(|v| v.re).collect()).collect()
}
fn opnorm(a: &M) -> f64 {            // largest stretch: power iteration on A^T A
    let mut x = vec![1.0; a[0].len()];
    for _ in 0..200 {
        let y: Vec<f64> = a.iter().map(|r| dot(r, &x)).collect();
        let z: Vec<f64> = (0..x.len()).map(|j| dot(&col(a, j), &y)).collect();
        let s = dot(&z, &z).sqrt();
        x = z.iter().map(|t| t / s).collect();
    }
    let y: Vec<f64> = a.iter().map(|r| dot(r, &x)).collect();
    dot(&y, &y).sqrt()
}
fn main() {
    println!("A = [[1, 1], [0, 2]], spectrum {{1, 2}}; (zI - A)^-1 = [[1/(z-1), 1/((z-1)(z-2))], [0, 1/(z-2)]]");
    let a: M = vec![vec![1.0, 1.0], vec![0.0, 2.0]];
    let p: M = vec![vec![0.0, 1.0 / (2.0 - 1.0)], vec![0.0, 1.0]];   // residues at z = 2, entry by entry
    println!("road 1, residues at 2 by hand: P = {}", mat(&p));
    println!("road 2, trapezoid rule on |z - 2| = 0.5 with M nodes:");
    let mut errs = vec![];
    for m in [4, 8, 16, 32] {
        let pm = calculus(one, &a, 2.0, 0.5, m);
        let (err, pred) = (gap(&pm, &p), 0.5f64.powi(m as i32) / (1.0 - 0.5f64.powi(m as i32)));
        errs.push(format!("{:.3}", err.log10()));
        println!("  M = {:2}: P_M = {}, error {:.12}, r^M/(1 - r^M) = {:.12}, log10 error {:.3}", m, mat(&pm), err, pred, err.log10());
        assert!((err - pred).abs() < 1e-13);
    }
    println!("chart, log10 error against M = 4, 8, 16, 32: {}", errs.join(", "));
    let (p2, ap, pa) = (mul(&p, &p), mul(&a, &p), mul(&p, &a));
    println!("road 3, invariants: P^2 = {} | AP = {} | PA = {}", mat(&p2), mat(&ap), mat(&pa));
    println!("  P (1, 1) = {} | P (1, 0) = {} | trace P = {}", mat(&vec![vec![dot(&p[0], &[1.0, 1.0]), dot(&p[1], &[1.0, 1.0])]]), mat(&vec![vec![p[0][0], p[1][0]]]), f6(p[0][0] + p[1][1]));
    let np = opnorm(&p);
    println!("  ||P|| by power iteration = {} | sqrt 2 = {} | above 1, so P is oblique, not orthogonal", f6(np), f6(2f64.sqrt()));
    assert!(gap(&p2, &p) == 0.0 && gap(&ap, &pa) == 0.0 && (np - 2f64.sqrt()).abs() < 1e-12);
    let q: M = vec![vec![1.0 - p[0][0], -p[0][1]], vec![-p[1][0], 1.0 - p[1][1]]];
    let q1 = calculus(one, &a, 1.0, 0.5, 64);
    println!("I - P = {} | loop |z - 1| = 0.5, 64 nodes: {}", mat(&q), mat(&q1));
    assert!(gap(&q, &q1) < 1e-15);
    println!("e^A, three roads:");
    let e1 = calculus(cexp, &a, 1.5, 2.0, 64);
    let (mut e2, mut term): (M, M) = (vec![vec![1.0, 0.0], vec![0.0, 1.0]], vec![vec![1.0, 0.0], vec![0.0, 1.0]]);
    for k in 1..30 {
        term = mul(&term, &a).iter().map(|r| r.iter().map(|v| v / k as f64).collect()).collect();
        e2 = e2.iter().zip(&term).map(|(r, s)| r.iter().zip(s).map(|(x, y)| x + y).collect()).collect();
    }
    let e3: M = (0..2).map(|i| (0..2).map(|j| 1f64.exp() * q[i][j] + 2f64.exp() * p[i][j]).collect()).collect();
    println!("  loop |z - 1.5| = 2, 64 nodes: {}", mat(&e1));
    println!("  power series, 30 terms:      {}", mat(&e2));
    println!("  e (I - P) + e^2 P:           {}", mat(&e3));
    assert!(gap(&e1, &e3) < 1e-12 && gap(&e2, &e3) < 1e-12);
    let (tr, det) = (e1[0][0] + e1[1][1], e1[0][0] * e1[1][1] - e1[0][1] * e1[1][0]);
    let disc = (tr * tr - 4.0 * det).sqrt();
    let (lo, hi) = ((tr - disc) / 2.0, (tr + disc) / 2.0);
    println!("spectral mapping: z^2 - {} z + {} has roots {}, {} | e, e^2 = {}, {}", f6(tr), f6(det), f6(lo), f6(hi), f6(1f64.exp()), f6(2f64.exp()));
    println!("  det e^A = {} | e^(trace A) = e^3 = {}", f6(det), f6(3f64.exp()));
    assert!((lo - 1f64.exp()).abs() < 1e-9 && (hi - 2f64.exp()).abs() < 1e-9 && (det - 3f64.exp()).abs() < 1e-9);
    println!("what breaks:");
    let jb: M = vec![vec![2.0, 1.0], vec![0.0, 2.0]];
    let ej = calculus(cexp, &jb, 2.0, 1.0, 64);
    println!("  Jordan block [[2, 1], [0, 2]]: loop gives e^J = {} | e^2 on the eigenvalue alone: {}", mat(&ej), mat(&vec![vec![2f64.exp(), 0.0], vec![0.0, 2f64.exp()]]));
    assert!((ej[0][1] - 2f64.exp()).abs() < 1e-12);
    let f = calculus(pole, &a, 1.5, 2.0, 64);
    let fa = mul(&f, &vec![vec![-1.0, 1.0], vec![0.0, 0.0]]);
    println!("  f = 1/(z - 2), a pole on the spectrum: loop gives {} | times (A - 2I): {} not I", mat(&f), mat(&fa));
    assert!(gap(&f, &vec![vec![0.0, 0.0], vec![0.0, 0.0]]) < 1e-12);
    let w = calculus(one, &a, 2.0, 1.5, 64);
    println!("  loop |z - 2| = 1.5 also encloses 1: {} | trace {}", mat(&w), f6(w[0][0] + w[1][1]));
    assert!(gap(&w, &vec![vec![1.0, 0.0], vec![0.0, 1.0]]) < 1e-9);
    let o: M = vec![vec![0.5, 0.5], vec![0.5, 0.5]];
    let cm: M = mul(&a, &o).iter().zip(&mul(&o, &a)).map(|(r, s)| r.iter().zip(s).map(|(x, y)| x - y).collect()).collect();
    println!("  nearest-point projection O onto (1, 1): AO - OA = {} | ||O|| = {}", mat(&cm), f6(opnorm(&o)));
    assert!(gap(&cm, &vec![vec![0.5, -0.5], vec![0.5, -0.5]]) == 0.0 && (opnorm(&o) - 1.0).abs() < 1e-12);
    println!("infinite dimensions: leaning blur on L2[0, 1], k(x, y) = e^(x - y) min(x, y) (1 - max(x, y)), N grid points");
    let (lam1, limit) = (1.0 / (PI * PI), (1f64.exp() - (-1f64).exp()) / 2.0 * (PI * PI) / (1.0 + PI * PI));
    println!("  exact: top eigenvalue 1/pi^2 = {} | ||P|| = sinh(1) pi^2 / (1 + pi^2) = {}", f6(lam1), f6(limit));
    let mut nrm = 0.0;
    for n in [10usize, 20, 40, 80] {
        let xs: Vec<f64> = (0..n).map(|i| (i as f64 + 0.5) / n as f64).collect();
        let k: M = xs.iter().map(|&x| xs.iter().map(|&y| (x - y).exp() * x.min(y) * (1.0 - x.max(y)) / n as f64).collect()).collect();
        let pn = calculus(one, &k, 0.1, 0.04, 48);
        let ones = vec![1.0; n];
        let trp = dot(&(0..n).map(|i| pn[i][i]).collect::<Vec<_>>(), &ones);
        let lamn = dot(&(0..n).map(|i| dot(&k[i], &col(&pn, i))).collect::<Vec<_>>(), &ones) / trp;
        let flat: Vec<f64> = pn.iter().flatten().cloned().collect();
        nrm = dot(&flat, &flat).sqrt();
        let idem = gap(&mul(&pn, &pn), &pn);
        println!("  N = {:2}: trace P_N {} | eigenvalue {}, (eigenvalue - 1/pi^2) x N^2 = {} | ||P_N|| {} | P_N^2 = P_N: {}",
            n, f6(trp), f6(lamn), f6((lamn - lam1) * n as f64 * n as f64), f6(nrm), if idem < 1e-10 { "yes" } else { "no" });
        assert!((trp - 1.0).abs() < 1e-9 && idem < 1e-10 && (lamn - lam1).abs() < 0.1 / (n * n) as f64);
    }
    assert!((nrm - limit).abs() < 1e-5);
    println!("figure, 80 px per unit, 0 at (60, 190): z = 1 at (140, 190), z = 2 at (220, 190), loop |z - 2| = 0.5 radius 40, loop |z - 1.5| = 2 centre (180, 190) radius 160");
    println!("ALL CHECKS PASS");
}
