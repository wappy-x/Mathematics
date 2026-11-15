// Compact and symmetric -- the same check as the Python, in Rust.  No crates.
// The sag operator of a 1 m string, K f(x) = integral of k(x, y) f(y) dy with
// k(x, y) = min(x, y)(1 - max(x, y)), is diagonalised three ways: the Rayleigh
// ratio on polynomials in exact rationals (a small struct), a written-out Jacobi
// eigenvalue solver on an N-point grid, and the grid's closed form.
use std::f64::consts::PI;
const C: f64 = 220.0;        // wave speed, m/s
const TENSION: f64 = 100.0;  // N, illustrative

#[derive(Clone, Copy, PartialEq)]
struct Q { n: i128, d: i128 }  // an exact fraction n/d, d > 0, in lowest terms
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i128, d: i128) -> Q { let g = gcd(n, d).max(1) * d.signum(); Q { n: n / g, d: d / g } }
fn add(a: Q, b: Q) -> Q { q(a.n * b.d + b.n * a.d, a.d * b.d) }
fn mul(a: Q, b: Q) -> Q { q(a.n * b.n, a.d * b.d) }
fn div(a: Q, b: Q) -> Q { q(a.n * b.d, a.d * b.n) }
fn lt(a: Q, b: Q) -> bool { a.n * b.d < b.n * a.d }
fn fl(a: Q) -> f64 { a.n as f64 / a.d as f64 }
fn fr(a: Q) -> String { format!("{}/{}", a.n, a.d) }

fn pmul(a: &[Q], b: &[Q]) -> Vec<Q> {  // polynomials: index = power
    let mut out = vec![q(0, 1); a.len() + b.len() - 1];
    for (i, &x) in a.iter().enumerate() { for (j, &y) in b.iter().enumerate() { out[i + j] = add(out[i + j], mul(x, y)) } }
    out
}
fn integ(a: &[Q]) -> Vec<Q> {
    let mut out = vec![q(0, 1)];
    for (k, &c) in a.iter().enumerate() { out.push(div(c, q(k as i128 + 1, 1))) }
    out
}
fn at1(a: &[Q]) -> Q { a.iter().fold(q(0, 1), |s, &c| add(s, c)) }
fn inner(a: &[Q], b: &[Q]) -> Q { at1(&integ(&pmul(a, b))) }
fn sag(f: &[Q]) -> Vec<Q> {            // K f: solve -u'' = f with u(0) = u(1) = 0
    let p = integ(&integ(f));
    let mut u: Vec<Q> = p.iter().map(|c| q(-c.n, c.d)).collect();
    u[1] = add(u[1], at1(&p));
    u
}
fn ratio(f: &[Q]) -> Q { div(inner(f, &sag(f)), inner(f, f)) }
fn note(mu: f64) -> f64 { C / (2.0 * PI * mu.sqrt()) }
fn kern(x: f64, y: f64) -> f64 { x.min(y) * (1.0 - x.max(y)) }
fn grid(n: usize) -> Vec<Vec<f64>> {   // K_N = h k(x_i, x_j) at x_i = i h, h = 1/(N+1)
    let h = 1.0 / (n as f64 + 1.0);
    (1..=n).map(|i| (1..=n).map(|j| h * kern(i as f64 * h, j as f64 * h)).collect()).collect()
}
fn jacobi(a0: &[Vec<f64>]) -> (Vec<f64>, Vec<Vec<f64>>) {  // cyclic Jacobi rotations
    let n = a0.len();
    let mut a = a0.to_vec();
    let mut v: Vec<Vec<f64>> = (0..n).map(|i| (0..n).map(|j| if i == j { 1.0 } else { 0.0 }).collect()).collect();
    for _ in 0..60 {
        let mut off = 0.0;
        for i in 0..n { for j in i + 1..n { off += a[i][j] * a[i][j] } }
        if off < 1e-30 { break }
        for p in 0..n - 1 {
            for qq in p + 1..n {
                if a[p][qq] == 0.0 { continue }
                let th = (a[qq][qq] - a[p][p]) / (2.0 * a[p][qq]);
                let t = (if th >= 0.0 { 1.0 } else { -1.0 }) / (th.abs() + (th * th + 1.0).sqrt());
                let c = 1.0 / (t * t + 1.0).sqrt(); let s = t * c;
                for m in [&mut a, &mut v] {
                    for k in 0..n { let (x, y) = (m[k][p], m[k][qq]); m[k][p] = c * x - s * y; m[k][qq] = s * x + c * y }
                }
                for k in 0..n { let (x, y) = (a[p][k], a[qq][k]); a[p][k] = c * x - s * y; a[qq][k] = s * x + c * y }
            }
        }
    }
    let mut order: Vec<usize> = (0..n).collect();
    order.sort_by(|&i, &j| a[j][j].partial_cmp(&a[i][i]).unwrap());
    (order.iter().map(|&i| a[i][i]).collect(), order.iter().map(|&i| (0..n).map(|k| v[k][i]).collect()).collect())
}
fn closed(n: usize, j: usize) -> f64 {  // exact eigenvalues of K_N
    let s = (j as f64 * PI / (2.0 * (n as f64 + 1.0))).sin();
    1.0 / (4.0 * ((n + 1) * (n + 1)) as f64 * (s * s))
}
fn join(v: &[f64], dp: usize) -> String { v.iter().map(|x| format!("{:.*}", dp, x)).collect::<Vec<_>>().join(", ") }
fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }

fn main() {
    let mu1 = 1.0 / (PI * PI);
    let one = vec![q(1, 1)];
    let bump = vec![q(0, 1), q(1, 1), q(-1, 1)];
    let (r1, r2, r3) = (ratio(&one), ratio(&bump), ratio(&sag(&bump)));
    println!("string kernel min(x,y)(1-max(x,y)); c = {:.0} m/s; tension {:.0} N", C, TENSION);
    println!("push 1 N at the middle: middle moves {:.3} mm", 1000.0 * kern(0.5, 0.5) / TENSION);
    println!("R(1) = {} = {:.6} -> note {:.2} Hz", fr(r1), fl(r1), note(fl(r1)));
    println!("R(x(1-x)) = {} = {:.6} -> note {:.2} Hz", fr(r2), fl(r2), note(fl(r2)));
    println!("R(K x(1-x)) = {} = {:.8} -> note {:.4} Hz", fr(r3), fl(r3), note(fl(r3)));
    println!("true top eigenvalue 1/pi^2 = {:.8} -> note {:.4} Hz", mu1, note(mu1));
    let sizes = [7usize, 15, 31, 63];
    let (mut errs, mut mats) = (vec![], vec![]);
    for &n in &sizes {
        let (vals, vecs) = jacobi(&grid(n));
        println!("N {:2}: mu1 by Jacobi {:.8}, closed form {:.8}, minus 1/pi^2 {:.8}", n, vals[0], closed(n, 1), vals[0] - mu1);
        assert!((0..n).all(|j| (vals[j] - closed(n, j + 1)).abs() < 1e-12));
        errs.push(vals[0] - mu1);
        mats.push((vals, vecs));
    }
    let shrink: Vec<f64> = (0..3).map(|i| errs[i] / errs[i + 1]).collect();
    println!("error shrinks by {} per doubling of N", join(&shrink, 3));
    let (vals, vecs) = &mats[3];
    let (h, a): (f64, Vec<Vec<f64>>) = (1.0 / 64.0, grid(63));
    println!("N 63, top five: {}", join(&vals[..5], 6));
    let tru: Vec<f64> = (1..6).map(|n| 1.0 / (n as f64 * PI).powi(2)).collect();
    println!("true, 1/(n pi)^2: {}", join(&tru, 6));
    let sgn = if vecs[0].iter().sum::<f64>() > 0.0 { 1.0 } else { -1.0 };
    let gap = (0..63).map(|i| (sgn * vecs[0][i] - (2.0 * h).sqrt() * (PI * (i + 1) as f64 * h).sin()).abs()).fold(0.0, f64::max);
    let (mut orth, mut rebuild): (f64, f64) = (0.0, 0.0);
    for x in 0..63 {
        for y in 0..63 {
            let dot: f64 = (0..63).map(|k| vecs[x][k] * vecs[y][k]).sum();
            orth = orth.max((dot - if x == y { 1.0 } else { 0.0 }).abs());
            let r: f64 = (0..63).map(|m| vals[m] * vecs[m][x] * vecs[m][y]).sum();
            rebuild = rebuild.max((r - a[x][y]).abs());
        }
    }
    println!("top vector against sampled sqrt(2) sin(pi x): within 1e-9: {}", yn(gap < 1e-9));
    println!("Q^T Q = I and Q D Q^T = K_63 within 1e-12: {}", yn(orth.max(rebuild) < 1e-12));
    let (mut w, mut pw): (Vec<f64>, f64) = ((1..64).map(|i| i as f64 * h * (1.0 - i as f64 * h)).collect(), 0.0);
    for _ in 0..200 {
        let kw: Vec<f64> = (0..63).map(|i| (0..63).map(|j| a[i][j] * w[j]).sum()).collect();
        pw = w.iter().zip(&kw).map(|(x, y)| x * y).sum::<f64>() / w.iter().map(|x| x * x).sum::<f64>();
        let nk = kw.iter().map(|x| x * x).sum::<f64>().sqrt();
        w = kw.iter().map(|x| x / nk).collect();
    }
    println!("power iteration, ratio of K_63 w to w: {:.8}", pw);
    let tr: f64 = (0..63).map(|i| a[i][i]).sum();
    let hs: f64 = a.iter().flatten().map(|x| x * x).sum();
    println!("N 63: sum of eigenvalues {:.6}, trace {:.6}; limit 1/6 = {:.6}", vals.iter().sum::<f64>(), tr, 1.0 / 6.0);
    println!("N 63: sum of squares {:.6}, of entries {:.6}; limit 1/90 = {:.6}", vals.iter().map(|m| m * m).sum::<f64>(), hs, 1.0 / 90.0);
    let ck: Vec<usize> = mats.iter().map(|(v, _)| v.iter().filter(|&&m| m > 0.001).count()).collect();
    let cm: Vec<usize> = sizes.iter().map(|&n| (1..=n).filter(|&i| { let x = i as f64 / (n as f64 + 1.0); 0.4 <= x && x <= 0.6 }).count()).collect();
    println!("eigenvalues above 0.001, N 7/15/31/63: {:?}; true {}", ck, (1..99).filter(|&n| mu1 / ((n * n) as f64) > 0.001).count());
    println!("multiplication by x, eigenvalues in [0.4, 0.6], N 7/15/31/63: {:?}", cm);
    let (mut sums, mut s) = (vec![], 0.0);   // uniform load: 1 N/m on the string
    for n in [1.0f64, 3.0, 5.0] {
        s += mu1 / (n * n) * (2.0 * 2f64.sqrt() / (n * PI)) * 2f64.sqrt() * (n * PI / 2.0).sin();
        sums.push(1000.0 * s / TENSION);
    }
    let exact = 1000.0 * fl(add(div(sag(&one)[1], q(2, 1)), div(sag(&one)[2], q(4, 1)))) / TENSION;
    println!("midpoint sag, modes 1 / 1,3 / 1,3,5: {} mm; exact {:.4} mm", join(&sums, 4), exact);
    let vol1 = div(inner(&one, &integ(&one)), inner(&one, &one));   // Volterra: integral 0..x
    let hv = 1.0 / 63.0;
    let vm: Vec<Vec<f64>> = (0..63).map(|i| (0..63).map(|j| if j < i { hv } else if j == i { hv / 2.0 } else { 0.0 }).collect()).collect();
    let (mut vw, mut vn) = (vec![1.0f64; 63], 0.0);
    for _ in 0..300 {
        let y: Vec<f64> = (0..63).map(|i| (0..63).map(|j| vm[i][j] * vw[j]).sum()).collect();
        let z: Vec<f64> = (0..63).map(|j| (0..63).map(|i| vm[i][j] * y[i]).sum()).collect();
        vn = (z.iter().map(|x| x * x).sum::<f64>() / vw.iter().map(|x| x * x).sum::<f64>()).sqrt();
        let nz = z.iter().map(|x| x * x).sum::<f64>().sqrt();
        vw = z.iter().map(|x| x / nz).collect();
    }
    println!("running total V: best ratio {} = {:.6}; norm at N 63 {:.6}, 2/pi = {:.6}; every grid eigenvalue {:.6}",
             fr(vol1), fl(vol1), vn.sqrt(), 2.0 / PI, hv / 2.0);
    let node = vec![q(0, 1), q(1, 1), q(-3, 1), q(2, 1)];   // x(1 - x)(1 - 2x), a node at 1/2
    let (r4, raw) = (ratio(&node), inner(&bump, &sag(&bump)));
    println!("trial with a node at the middle: R = {} = {:.6} -> note {:.2} Hz", fr(r4), fl(r4), note(fl(r4)));
    println!("top of the ratio left undivided: {} = {:.6} -> note {:.2} Hz", fr(raw), fl(raw), note(fl(raw)));
    println!("hand steps: K x(1-x) coefficients, x^0 to x^4: {}", sag(&bump).iter().map(|&c| fr(c)).collect::<Vec<_>>().join(", "));
    println!("hand steps: <f,f> = {}; c/(2 pi) = {:.4}; 17/168 falls short of 1/pi^2 by {:.3} %",
             fr(inner(&bump, &bump)), C / (2.0 * PI), 100.0 * (mu1 - fl(r2)) / mu1);
    println!("chart, n: true 1/(n pi)^2 | N 7 grid");
    for n in 1..8 { println!("chart, {}: {:.4} | {:.4}", n, mu1 / ((n * n) as f64), mats[0].0[n - 1]) }
    assert!(lt(r1, r2) && lt(r2, r3) && fl(r3) < mu1 && r2 == q(17, 168));   // ratios climb to mu1
    assert!(shrink.iter().all(|&x| 3.9 < x && x < 4.1) && gap < 1e-9 && orth.max(rebuild) < 1e-12);
    assert!((pw - closed(63, 1)).abs() < 1e-10 && (vals.iter().sum::<f64>() - tr).abs() < 1e-12);
    assert!((tr - 1.0 / 6.0).abs() < 1e-4 && (hs - 1.0 / 90.0).abs() < 2e-5 && ck[2..] == [10, 10]);
    assert!(cm[3] > cm[0] && (sums[2] - 1.25).abs() < 0.003 && (vn.sqrt() - 2.0 / PI).abs() < 1e-4);
    assert!((fl(r4) - mu1 / 4.0).abs() < 0.001 && vol1 == q(1, 2));
    println!("ALL CHECKS PASS");
}
