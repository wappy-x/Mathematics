// Convex functions -- the same check as the Python, in Rust.  No crates.  One
// seedling measured at weeks 0-3; fit height = a + b*week by least squares.
// S(a, b), the squared error, is convex: two roads reach one fit.
const X: [f64; 4] = [0.0, 1.0, 2.0, 3.0]; const Y: [f64; 4] = [1.0, 3.0, 4.0, 6.0];

fn s_err(a: f64, b: f64, xs: &[f64; 4]) -> f64 {        // squared error of the line a + b*x
    xs.iter().zip(Y.iter()).map(|(x, y)| (y - a - b * x).powi(2)).sum()
}
fn s(p: &[f64]) -> f64 { s_err(p[0], p[1], &X) }
fn wf(p: &[f64]) -> f64 { let x = p[0]; x.powi(4) - 4.0 * x * x + x }   // a wavy error curve

fn descend(f: fn(&[f64]) -> f64, start: &[f64], rate: f64, steps: usize) -> Vec<f64> {
    let (mut p, h) = (start.to_vec(), 1e-4);            // gradient descent, central differences
    for _ in 0..steps {
        let g: Vec<f64> = (0..p.len()).map(|i| {
            let (mut up, mut dn) = (p.clone(), p.clone()); up[i] += h; dn[i] -= h;
            (f(&up) - f(&dn)) / (2.0 * h)
        }).collect();
        for i in 0..p.len() { p[i] -= rate * g[i] }
    }
    p
}
fn sci(x: f64) -> String {                              // 5.0e-01, as Python writes it
    let t = format!("{:.1e}", x); let (m, e) = t.split_once('e').unwrap(); let k: i32 = e.parse().unwrap();
    format!("{}e{}{:02}", m, if k < 0 { '-' } else { '+' }, k.abs())
}
fn list(v: &[f64], d: usize) -> String { v.iter().map(|x| format!("{:.*}", d, x)).collect::<Vec<_>>().join(", ") }

fn main() {
    let n = 4.0;
    let (sx, sy, sxx): (f64, f64, f64) = (X.iter().sum(), Y.iter().sum(), X.iter().map(|x| x * x).sum());
    let sxy: f64 = X.iter().zip(Y.iter()).map(|(x, y)| x * y).sum();
    let b = (n * sxy - sx * sy) / (n * sxx - sx * sx);  // road 1: the normal equations, solved
    let a = (sy - b * sx) / n;
    let h = [[2.0 * n, 2.0 * sx], [2.0 * sx, 2.0 * sxx]];   // Hessian of S, from its formula
    let e = 0.01;                                       // Hessian again, by second differences
    let sa = |da: f64, db: f64| s(&[a + da, b + db]);
    let h01 = (sa(e, e) - sa(e, -e) - sa(-e, e) + sa(-e, -e)) / (4.0 * e * e);
    let hd = [[(sa(e, 0.0) - 2.0 * sa(0.0, 0.0) + sa(-e, 0.0)) / (e * e), h01],
              [h01, (sa(0.0, e) - 2.0 * sa(0.0, 0.0) + sa(0.0, -e)) / (e * e)]];
    let (det, tr) = (h[0][0] * h[1][1] - h[0][1] * h[0][1], h[0][0] + h[1][1]);
    let root = (tr * tr - 4.0 * det).sqrt();
    let quad = |d: [f64; 2]| (0..2).map(|i| (0..2).map(|j| d[i] * h[i][j] * d[j]).sum::<f64>()).sum::<f64>();
    let ends: Vec<Vec<f64>> = [[10.0, -10.0], [-10.0, 10.0]].iter().map(|st| descend(s, st, 0.05, 400)).collect();
    let errs: Vec<String> = [25, 50, 100, 200].iter().map(|&k| descend(s, &[10.0, -10.0], 0.05, k))
        .map(|p| sci((p[0] - a).abs().max((p[1] - b).abs()))).collect();
    let bs: Vec<f64> = (0..7).map(|k| 0.5 * k as f64).collect();
    let (pts, wts) = ([[0.0, 2.0], [2.0, 1.0], [3.0, 0.0]], [0.5, 0.3, 0.2]);   // Jensen: three fits
    let m: Vec<f64> = (0..2).map(|i| (0..3).map(|k| wts[k] * pts[k][i]).sum()).collect();
    let jgap = (0..3).map(|k| wts[k] * s(&pts[k])).sum::<f64>() - s(&m);
    let jgap2: f64 = (0..3).map(|k| wts[k] * quad([pts[k][0] - m[0], pts[k][1] - m[1]]) / 2.0).sum();
    let (cgap, cgap2) = ((s(&[0.0, 2.0]) + s(&[2.0, 1.0])) / 2.0 - s(&[1.0, 1.5]), quad([2.0, -1.0]) / 8.0);
    let (wl, wr) = (descend(wf, &[-2.0], 0.01, 2000)[0], descend(wf, &[2.0], 0.01, 2000)[0]);
    let x2 = [2.0; 4];                                  // all four measurements in week 2
    let det2 = (2.0 * 4.0) * (2.0 * x2.iter().map(|x| x * x).sum::<f64>()) - (2.0 * x2.iter().sum::<f64>()).powi(2);
    println!("weeks [0, 1, 2, 3], heights [1, 3, 4, 6] cm");
    println!("sums: x {}, x^2 {}, y {}, xy {}; residuals {}", sx, sxx, sy, sxy, list(&X.iter().zip(Y.iter()).map(|(x, y)| y - a - b * x).collect::<Vec<_>>(), 1));
    println!("road 1, normal equations: a = {:.3} cm, b = {:.3} cm/week, S = {:.3}", a, b, s(&[a, b]));
    for (st, p) in ["(10, -10)", "(-10, 10)"].iter().zip(ends.iter()) { println!("road 2, descent from {}: a = {:.6}, b = {:.6}", st, p[0], p[1]) }
    println!("descent error after 25, 50, 100, 200 steps: {}", errs.join(", "));
    println!("Hessian by formula: [[{}, {}], [{}, {}]]; by second differences: [[{:.4}, {:.4}], [{:.4}, {:.4}]]",
             h[0][0], h[0][1], h[1][0], h[1][1], hd[0][0], hd[0][1], hd[1][0], hd[1][1]);
    println!("determinant {}, trace {}, stretch factors {:.2} and {:.2}", det, tr, (tr + root) / 2.0, (tr - root) / 2.0);
    println!("chart b: {}", list(&bs, 1));
    println!("chart S(1.1, b): {}", list(&bs.iter().map(|&x| s(&[1.1, x])).collect::<Vec<_>>(), 2));
    let (c0, c3) = (s(&[1.1, 0.0]), s(&[1.1, 3.0]));
    println!("chart chord: {}", list(&bs.iter().map(|&x| c0 + (c3 - c0) * x / 3.0).collect::<Vec<_>>(), 2));
    println!("chord: S(0, 2) = {:.2}, S(2, 1) = {:.2}, S(1, 1.5) = {:.2}; gap {:.2}, by d'Hd/8 {:.2}",
             s(&[0.0, 2.0]), s(&[2.0, 1.0]), s(&[1.0, 1.5]), cgap, cgap2);
    println!("Jensen: S at (0, 2), (2, 1), (3, 0): {}; mix ({:.2}, {:.2}), S at mix {:.2}, mix of S {:.2}; gap {:.2}, by Hessian {:.2}",
             list(&pts.iter().map(|p| s(p)).collect::<Vec<_>>(), 2), m[0], m[1], s(&m), s(&m) + jgap, jgap, jgap2);
    println!("mistake 1, wavy curve: w''(0) = {:.2}; descent from 2 stops at x = {:.4}, w = {:.4}; from -2 at x = {:.4}, w = {:.4}",
             (wf(&[e]) - 2.0 * wf(&[0.0]) + wf(&[-e])) / (e * e), wr, wf(&[wr]), wl, wf(&[wl]));
    println!("mistake 2, all weeks 2: determinant {}; S(3.5, 0) = {:.2}, S(1.5, 1) = {:.2}", det2, s_err(3.5, 0.0, &x2), s_err(1.5, 1.0, &x2));
    assert!(ends.iter().all(|p| (p[0] - a).abs() < 1e-6 && (p[1] - b).abs() < 1e-6));    // two roads, one fit
    assert!((0..2).all(|i| (0..2).all(|j| (hd[i][j] - h[i][j]).abs() < 1e-6)));          // Hessian two ways
    assert!((jgap - jgap2).abs() < 1e-9 && (cgap - cgap2).abs() < 1e-9 && jgap > 0.0);  // Jensen gap two ways
    assert!(wf(&[wl]) < wf(&[wr]) - 1.0 && (s_err(3.5, 0.0, &x2) - s_err(1.5, 1.0, &x2)).abs() < 1e-12);
    println!("ALL CHECKS PASS");
}
