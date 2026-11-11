// Optimality conditions on the banana valley -- the same check as optimality_conditions_check.py.
// Minimise f(x) = sum over i of b(x[i+1] - x[i]^2)^2 + (1 - x[i])^2.  Two variables: the banana.  No crates.
use std::f64::consts::PI;
type Mat = Vec<Vec<f64>>;

fn f(x: &[f64], b: f64) -> f64 {
    (0..x.len() - 1).fold(0.0, |t, i| { let w = x[i + 1] - x[i] * x[i]; t + (b * w * w + (1.0 - x[i]) * (1.0 - x[i])) })
}
fn fb(x: &[f64]) -> f64 { f(x, 100.0) }
fn grad(x: &[f64]) -> Vec<f64> { // the slopes, by hand
    let (b, mut g) = (100.0, vec![0.0; x.len()]);
    for i in 0..x.len() - 1 { let w = x[i + 1] - x[i] * x[i]; g[i] += -4.0 * b * x[i] * w - 2.0 * (1.0 - x[i]); g[i + 1] += 2.0 * b * w; }
    g
}
fn hess(x: &[f64], b: f64) -> Mat { // the second derivatives, by hand
    let (n, mut h) = (x.len(), vec![vec![0.0; x.len()]; x.len()]);
    for i in 0..n - 1 {
        h[i][i] += 12.0 * b * x[i] * x[i] - 4.0 * b * x[i + 1] + 2.0;
        h[i][i + 1] -= 4.0 * b * x[i]; h[i + 1][i] -= 4.0 * b * x[i]; h[i + 1][i + 1] += 2.0 * b;
    }
    h
}
fn eye(n: usize) -> Mat { (0..n).map(|i| (0..n).map(|j| if i == j { 1.0 } else { 0.0 }).collect()).collect() }
fn maxabs(v: &[f64]) -> f64 { v.iter().fold(0.0_f64, |m, a| m.max(a.abs())) }
fn solve(a: &Mat, r: &[f64]) -> Option<Vec<f64>> { // elimination with row swaps; None if singular
    let n = r.len();
    let mut m: Mat = (0..n).map(|i| { let mut row = a[i].clone(); row.push(r[i]); row }).collect();
    for c in 0..n {
        let p = (c..n).fold(c, |p, i| if m[i][c].abs() > m[p][c].abs() { i } else { p });
        if m[p][c] == 0.0 { return None; }
        m.swap(c, p);
        for i in c + 1..n { let mu = m[i][c] / m[c][c]; for k in c..=n { m[i][k] -= mu * m[c][k]; } }
    }
    let mut z = vec![0.0; n];
    for i in (0..n).rev() { z[i] = (m[i][n] - (i + 1..n).fold(0.0, |t, k| t + m[i][k] * z[k])) / m[i][i]; }
    Some(z)
}
fn pivots(h: &Mat) -> (Vec<f64>, Mat) { // elimination without swaps: H = L P L^T
    let (n, mut a, mut l) = (h.len(), h.clone(), eye(h.len()));
    for c in 0..n {
        if a[c][c] == 0.0 { return ((0..n).map(|i| if i <= c { a[i][i] } else { 0.0 }).collect(), l); }
        for i in c + 1..n { l[i][c] = a[i][c] / a[c][c]; for k in c..n { a[i][k] -= l[i][c] * a[c][k]; } }
    }
    ((0..n).map(|i| a[i][i]).collect(), l)
}
fn verdict(piv: &[f64]) -> String { // signs of pivots = signs of eigenvalues
    let neg = piv.iter().filter(|&&p| p < 0.0).count();
    if piv.contains(&0.0) { "no verdict".into() } else if neg == 0 { "strict local minimum".into() }
    else if neg == piv.len() { "strict local maximum".into() } else { format!("saddle ({} negative)", neg) }
}
fn newton(mut x: Vec<f64>) -> Option<Vec<f64>> { // Newton on grad f = 0: finds flat spots of any kind
    for _ in 0..50 {
        if maxabs(&x) > 1e3 { return None; }
        x = step(&x, &solve(&hess(&x, 100.0), &grad(&x))?, -1.0);
    }
    if maxabs(&grad(&x)) < 1e-9 { Some(x) } else { None }
}
fn flat_spots(n: usize) -> (Vec<(Vec<f64>, usize)>, usize) { // Newton from every start in a grid of 5^n points
    let vals = [-1.2, -0.5, 0.0, 0.5, 1.2];
    let (mut found, mut fails): (Vec<(String, Vec<f64>, usize)>, usize) = (vec![], 0);
    for code in 0..5usize.pow(n as u32) {
        let s: Vec<f64> = (0..n).map(|i| vals[code / 5usize.pow((n - 1 - i) as u32) % 5]).collect();
        let Some(z) = newton(s) else { fails += 1; continue };
        match found.iter_mut().find(|e| e.0 == fmt(&z, 6)) { Some(e) => e.2 += 1, None => found.push((fmt(&z, 6), z, 1)) }
    }
    found.sort_by(|a, b| fb(&a.1).partial_cmp(&fb(&b.1)).unwrap());
    (found.into_iter().map(|e| (e.1, e.2)).collect(), fails)
}
fn step(x: &[f64], d: &[f64], t: f64) -> Vec<f64> { x.iter().zip(d).map(|(a, u)| a + t * u).collect() }
fn unit(v: &[f64]) -> Vec<f64> { let s = v.iter().fold(0.0, |t, a| t + a * a).sqrt(); v.iter().map(|a| a / s).collect() }
fn fmt(v: &[f64], p: usize) -> String { format!("({})", v.iter().map(|a| format!("{:.*}", p, a)).collect::<Vec<_>>().join(", ")) }
fn sci(v: f64, p: usize) -> String { // Python's e-format: two-digit exponent with a sign
    let s = format!("{:.*e}", p, v); let (m, e) = s.split_once('e').unwrap(); let e: i32 = e.parse().unwrap();
    format!("{}e{}{:02}", m, if e < 0 { '-' } else { '+' }, e.abs())
}
fn by_differences(x: &[f64]) -> (Vec<f64>, Mat) { // road 2: slopes and bends from f alone
    let (e, h) = (eye(x.len()), 1e-5);
    let g = e.iter().map(|ei| (fb(&step(x, ei, h)) - fb(&step(x, ei, -h))) / (2.0 * h)).collect();
    let hd = e.iter().map(|a| e.iter().map(|c| (fb(&step(&step(x, a, h), c, h)) - fb(&step(&step(x, a, h), c, -h))
        - fb(&step(&step(x, a, -h), c, h)) + fb(&step(&step(x, a, -h), c, -h))) / (4.0 * h * h)).collect()).collect();
    (g, hd)
}
fn worst(a: &Mat, b: &Mat) -> f64 { a.iter().zip(b).flat_map(|(r, s)| r.iter().zip(s).map(|(u, v)| (u - v).abs())).fold(0.0, f64::max) }
fn eig2(h: &Mat) -> (f64, f64, f64, f64) { // eigenvalues of a 2 by 2 table from trace and det
    let (t, d) = (h[0][0] + h[1][1], h[0][0] * h[1][1] - h[0][1] * h[1][0]);
    (t, d, (t + (t * t - 4.0 * d).sqrt()) / 2.0, (t - (t * t - 4.0 * d).sqrt()) / 2.0)
}
fn join(v: impl Iterator<Item = String>, sep: &str) -> String { v.collect::<Vec<_>>().join(sep) }

fn main() {
    // ---- the banana, n = 2 ----
    let (mut x, mut heights) = (vec![-1.2, 1.0], vec![]);
    for _ in 0..7 { x = step(&x, &solve(&hess(&x, 100.0), &grad(&x)).unwrap(), -1.0); heights.push(fb(&x)); }
    println!("start (-1.2, 1): f = {:.6}; newton on grad = 0, f after steps 1-7: {}", fb(&[-1.2, 1.0]), join(heights.iter().map(|v| format!("{:.2}", v)), " "));
    let (xs, h, (gd, hd)) = (x.clone(), hess(&x, 100.0), by_differences(&x));
    println!("flat spot {}: f = {:.6}, gradient {}, by differences {}", fmt(&xs, 6), fb(&xs), fmt(&grad(&xs), 6),
             fmt(&gd.iter().map(|v| v.abs()).collect::<Vec<_>>(), 6));
    println!("hessian by hand {:.3} {:.3} {:.3}; by differences {:.3} {:.3} {:.3}", h[0][0], h[0][1], h[1][1], hd[0][0], hd[0][1], hd[1][1]);
    assert!(worst(&hd, &h) < 0.01 && maxabs(&gd) < 1e-4);
    let (t, d, lmax, lmin) = eig2(&h);
    println!("trace {:.6}, det {:.6}, eigenvalues {:.6} and {:.6}, stretch {:.2}", t, d, lmax, lmin, lmax / lmin);
    let q: Vec<f64> = (0..3600).map(|k| ((k as f64 * PI / 3600.0).cos(), (k as f64 * PI / 3600.0).sin()))
        .map(|(c, s)| h[0][0] * c * c + 2.0 * h[0][1] * c * s + h[1][1] * s * s).collect();
    let (qmax, qmin) = (q.iter().cloned().fold(f64::MIN, f64::max), q.iter().cloned().fold(f64::MAX, f64::min));
    println!("d'Hd over 3600 unit directions: largest {:.4}, smallest {:.4}", qmax, qmin);
    assert!((qmin - lmin).abs() < 1e-3 && (qmax - lmax).abs() < 1e-3);
    let (piv, _) = pivots(&h); println!("pivots {:.6} and {:.6}: {}", piv[0], piv[1], verdict(&piv));
    let (vflat, vsteep) = (unit(&[-h[0][1], h[0][0] - lmin]), unit(&[-h[0][1], h[0][0] - lmax]));
    println!("flat direction {}, steep direction {}", fmt(&vflat, 6), fmt(&vsteep, 6));
    println!("contour f = 0.01, quadratic model: {:.4} along the flat way, {:.4} along the steep way", (0.02 / lmin).sqrt(), (0.02 / lmax).sqrt());
    let r = 0.01; let rise = (0..3600).map(|k| fb(&step(&xs, &[(k as f64 * PI / 1800.0).cos(), (k as f64 * PI / 1800.0).sin()], r)))
        .fold(f64::MAX, f64::min) - fb(&xs);
    println!("circle of radius 0.01: smallest rise {}; model lmin r^2/2 = {}", sci(rise, 4), sci(lmin * r * r / 2.0, 4));
    assert!(0.0 < rise && (rise - lmin * r * r / 2.0).abs() < 0.1 * lmin * r * r / 2.0);
    let mut best = (f64::MAX, 0.0, 0.0);
    for (u, v) in (-200..=200).flat_map(|i| (-200..=200).map(move |j| (i as f64 / 100.0, j as f64 / 100.0))) {
        if fb(&[u, v]) < best.0 { best = (fb(&[u, v]), u, v); } }
    println!("grid over [-2, 2] x [-2, 2], spacing 0.01: lowest f = {:.6} at ({:.2}, {:.2})", best.0, best.1, best.2);
    assert!(best.1 == 1.0 && best.2 == 1.0 && best.0 == fb(&xs));

    // ---- the chained banana, n = 4 ----
    let (pts, fails) = flat_spots(4);
    let dirs: Vec<Vec<f64>> = (0..81usize).map(|c| (0..4).map(|i| (c / 3usize.pow(3 - i as u32) % 3) as f64 - 1.0).collect::<Vec<f64>>())
        .filter(|s| s.iter().any(|&a| a != 0.0)).map(|s| unit(&s)).collect();
    println!("n = 4: Newton from 625 starts finds {} flat spots; {} starts did not settle", pts.len(), fails);
    for (z, count) in &pts {
        let ((piv, _), (gd, hd)) = (pivots(&hess(z, 100.0)), by_differences(z));
        assert!(worst(&hd, &hess(z, 100.0)) < 0.05 && maxabs(&gd) < 1e-4);
        let low = dirs.iter().map(|dd| fb(&step(z, dd, 1e-3))).fold(f64::MAX, f64::min) - fb(z);
        println!("{} f = {:.6} from {:3} starts; pivots {}: {}; 80-direction rise {}", fmt(z, 6), fb(z), count, fmt(&piv, 3), verdict(&piv), sci(low, 3));
    }
    let (sad, hs) = (&pts[pts.len() - 1].0, hess(&pts[pts.len() - 1].0, 100.0)); let (piv, l) = pivots(&hs);
    let k = (0..4).fold(0, |m, i| if piv[i] < piv[m] { i } else { m });
    let mut dv: Vec<f64> = (0..4).map(|i| if i == k { 1.0 } else { 0.0 }).collect();
    for i in (0..k).rev() { dv[i] = -(i + 1..4).fold(0.0, |t, j| t + l[j][i] * dv[j]); } // solve L^T d = e_k
    let dv = unit(&dv); let curv = (0..4).flat_map(|i| (0..4).map(move |j| (i, j))).fold(0.0, |t, (i, j)| t + dv[i] * hs[i][j] * dv[j]);
    let drop = fb(&step(sad, &dv, 0.01)) - fb(sad);
    println!("saddle: diagonal {}; downhill direction {}", fmt(&(0..4).map(|i| hs[i][i]).collect::<Vec<_>>(), 3), fmt(&dv, 6));
    println!("saddle: d'Hd = {:.4}; a step of 0.01 along d changes f by {} (model {})", curv, sci(drop, 4), sci(curv * 0.0001 / 2.0, 4));
    assert!(curv < 0.0 && drop < 0.0 && (0..4).all(|i| hs[i][i] > 0.0));
    assert!(pts[..2].iter().all(|(z, _)| verdict(&pivots(&hess(z, 100.0)).0) == "strict local minimum"));

    // ---- what breaks ----
    for (name, sgn) in [("x^2 + y^4", 1.0), ("x^2 - y^4", -1.0)] {
        let hb = vec![vec![2.0, 0.0], vec![0.0, 0.0]]; // second derivatives 2 and 12y^2 at (0, 0)
        println!("breaks, {}: hessian at 0 is diag(2, 0): {}; f(0, 0.1) = {:.6}", name, verdict(&pivots(&hb).0), sgn * 0.1 * 0.1 * 0.1 * 0.1);
    }
    let p3 = pivots(&vec![vec![2.0, 0.0, 0.0], vec![0.0, -2.0, 0.0], vec![0.0, 0.0, -2.0]]).0;
    println!("breaks, x^2 - y^2 - z^2: det {:.0} and top-left {:.0}, yet pivots {}: {}; f(0, 0.1, 0) = {:.6}",
             p3[0] * p3[1] * p3[2], p3[0], fmt(&p3, 0), verdict(&p3), -0.1 * 0.1);
    assert!(verdict(&p3) != "strict local minimum" && p3[0] * p3[1] * p3[2] > 0.0);
    println!("breaks, local read as global: f = {:.6} at the second pit, {:.6} at (1, 1, 1, 1)", fb(&pts[1].0), fb(&pts[0].0));

    // ---- try changing, and the figure ----
    let h1 = hess(&[1.0, 1.0], 1.0); let (_, _, l1, l2) = eig2(&h1);
    println!("try b = 1: hessian {:.0} {:.0} {:.0}, eigenvalues {:.4} and {:.4}, stretch {:.2}", h1[0][0], h1[0][1], h1[1][1], l1, l2, l1 / l2);
    let pm = pivots(&h.iter().map(|row| row.iter().map(|v| -v).collect()).collect()).0;
    println!("try minus f: pivots {}: {}", fmt(&pm, 6), verdict(&pm));
    let (p3s, _) = flat_spots(3);
    println!("try n = 3: Newton from 125 starts finds {} flat spot(s): {}", p3s.len(), join(p3s.iter().map(|(z, _)| fmt(z, 6)), ", "));
    let spans = [("0.01", 0.01_f64), ("0.25", 0.25), ("1", 1.0), ("4", 4.0), ("24.2", 24.2)].iter()
        .map(|(lab, c)| format!("c = {}: {:.2} to {:.2}", lab, 1.0 - c.sqrt(), 1.0 + c.sqrt()));
    println!("figure, contour f = c runs from x = 1 - sqrt(c) to 1 + sqrt(c): {}", join(spans, "; "));
    println!("ALL CHECKS PASS");
}
