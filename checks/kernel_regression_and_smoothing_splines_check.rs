// Kernel regression and smoothing splines -- the same check as the Python, in Rust, std only.
// Twelve coffee waits, one every 20 minutes from 7:00 to 10:40.  Time x is in hours after 7:00.
// Nadaraya-Watson and local-linear fits with bell weights, bandwidth 30 minutes; a cubic
// smoothing spline by Reinsch's equations, checked against a fine-grid penalised fit; and the
// smoothing level chosen by leave-one-out cross-validation, by refitting and by the hat shortcut.

const Y: [f64; 12] = [1.5, 3.2, 4.4, 6.5, 7.2, 8.1, 6.8, 6.6, 4.7, 4.4, 2.9, 2.7];
const H: f64 = 0.5;

fn xs() -> Vec<f64> { (0..12).map(|i| i as f64 / 3.0).collect() }
fn clock(x: f64) -> String { let m = (x * 60.0).round() as i64; format!("{}:{:02}", 7 + m / 60, m % 60) }
fn bell(x0: f64, xs: &[f64], h: f64) -> Vec<f64> { xs.iter().map(|x| (-((x - x0) / h).powi(2) / 2.0).exp()).collect() }
fn dot(a: &[f64], b: &[f64]) -> f64 { a.iter().zip(b).map(|(p, q)| p * q).sum() }
fn join(v: &[f64], d: usize) -> String { v.iter().map(|x| format!("{:.*}", d, x)).collect::<Vec<_>>().join(" ") }

fn nw(x0: f64, xs: &[f64], ys: &[f64], h: f64) -> f64 {
    let w = bell(x0, xs, h);
    dot(&w, ys) / w.iter().sum::<f64>()
}

fn loclin(x0: f64, xs: &[f64], ys: &[f64], h: f64) -> (f64, Vec<f64>) { // weighted least-squares line, read at x0
    let w = bell(x0, xs, h);
    let s0: f64 = w.iter().sum();
    let s1: f64 = w.iter().zip(xs).map(|(a, x)| a * (x - x0)).sum();
    let s2: f64 = w.iter().zip(xs).map(|(a, x)| a * (x - x0).powi(2)).sum();
    let l: Vec<f64> = w.iter().zip(xs).map(|(a, x)| a * (s2 - (x - x0) * s1) / (s0 * s2 - s1 * s1)).collect();
    (dot(&l, ys), l)
}

fn solve(a: &[Vec<f64>], b: &[f64]) -> Vec<f64> { // Gaussian elimination with partial pivoting
    let n = b.len();
    let mut m: Vec<Vec<f64>> = a.iter().zip(b).map(|(r, v)| { let mut r = r.clone(); r.push(*v); r }).collect();
    for c in 0..n {
        let p = (c..n).max_by(|&i, &j| m[i][c].abs().partial_cmp(&m[j][c].abs()).unwrap()).unwrap();
        m.swap(c, p);
        for r in c + 1..n {
            let f = m[r][c] / m[c][c];
            if f != 0.0 { for k in c..=n { let d = m[c][k]; m[r][k] -= f * d; } }
        }
    }
    let mut z = vec![0.0; n];
    for r in (0..n).rev() {
        let s: f64 = (r + 1..n).map(|k| m[r][k] * z[k]).sum();
        z[r] = (m[r][n] - s) / m[r][r];
    }
    z
}

fn spline(xs: &[f64], ys: &[f64], lam: f64) -> (Vec<f64>, f64) { // Reinsch: (R + lam Q'Q) gamma = Q'y, g = y - lam Q gamma
    let n = xs.len();
    let h: Vec<f64> = (0..n - 1).map(|i| xs[i + 1] - xs[i]).collect();
    let mut q = vec![vec![0.0; n - 2]; n];
    let mut r = vec![vec![0.0; n - 2]; n - 2];
    for j in 0..n - 2 {
        q[j][j] = 1.0 / h[j]; q[j + 1][j] = -1.0 / h[j] - 1.0 / h[j + 1]; q[j + 2][j] = 1.0 / h[j + 1];
        r[j][j] = (h[j] + h[j + 1]) / 3.0;
        if j < n - 3 { r[j][j + 1] = h[j + 1] / 6.0; r[j + 1][j] = h[j + 1] / 6.0; }
    }
    let a: Vec<Vec<f64>> = (0..n - 2).map(|p| (0..n - 2).map(|s| r[p][s] + lam * (0..n).map(|i| q[i][p] * q[i][s]).sum::<f64>()).collect()).collect();
    let rhs: Vec<f64> = (0..n - 2).map(|p| (0..n).map(|i| q[i][p] * ys[i]).sum()).collect();
    let gam = solve(&a, &rhs);
    let g: Vec<f64> = (0..n).map(|i| ys[i] - lam * dot(&q[i], &gam)).collect();
    let pen: f64 = (0..n - 2).map(|p| (0..n - 2).map(|s| gam[p] * r[p][s] * gam[s]).sum::<f64>()).sum();
    (g, pen)
}

fn grid_fit(lam: f64, per: usize) -> Vec<f64> { // road 2: values on a 1-minute grid, second differences
    let (m, d) = (11 * per + 1, 1.0 / (3.0 * per as f64));
    let mut a = vec![vec![0.0; m]; m];
    let mut b = vec![0.0; m];
    for i in 0..12 { a[i * per][i * per] += 1.0; b[i * per] += Y[i]; }
    for k in 1..m - 1 {
        let c = [(k - 1, 1.0), (k, -2.0), (k + 1, 1.0)];
        for &(p, u) in &c { for &(s, v) in &c { a[p][s] += lam * u * v / d.powi(3); } }
    }
    let g = solve(&a, &b);
    (0..12).map(|i| g[i * per]).collect()
}

fn unit(i: usize) -> Vec<f64> { (0..12).map(|j| if j == i { 1.0 } else { 0.0 }).collect() }
fn drop(v: &[f64], i: usize) -> Vec<f64> { v.iter().enumerate().filter(|&(j, _)| j != i).map(|(_, x)| *x).collect() }

fn spline_at(xs: &[f64], g: &[f64], x0: f64) -> f64 { // natural cubic spline through (xs, g), evaluated at x0
    let n = xs.len();
    let h: Vec<f64> = (0..n - 1).map(|i| xs[i + 1] - xs[i]).collect();
    let mut a = vec![vec![0.0; n]; n];
    let mut b = vec![0.0; n];
    a[0][0] = 1.0; a[n - 1][n - 1] = 1.0;
    for i in 1..n - 1 {
        a[i][i - 1] = h[i - 1] / 6.0; a[i][i] = (h[i - 1] + h[i]) / 3.0; a[i][i + 1] = h[i] / 6.0;
        b[i] = (g[i + 1] - g[i]) / h[i] - (g[i] - g[i - 1]) / h[i - 1];
    }
    let s = solve(&a, &b);
    if x0 < xs[0] { return g[0] + ((g[1] - g[0]) / h[0] - h[0] * s[1] / 6.0) * (x0 - xs[0]); } // straight past the ends
    if x0 > xs[n - 1] { return g[n - 1] + ((g[n - 1] - g[n - 2]) / h[n - 2] + h[n - 2] * s[n - 2] / 6.0) * (x0 - xs[n - 1]); }
    let i = (0..n - 1).filter(|&j| xs[j] <= x0).max().unwrap();
    let (a, t) = (xs[i + 1] - x0, x0 - xs[i]);
    (s[i] * a.powi(3) + s[i + 1] * t.powi(3)) / (6.0 * h[i]) + (g[i] / h[i] - s[i] * h[i] / 6.0) * a + (g[i + 1] / h[i] - s[i + 1] * h[i] / 6.0) * t
}

fn loo(x: &[f64], lam: f64) -> (f64, f64) { // leave-one-out: real refits, and the hat shortcut
    let (g, _) = spline(x, &Y, lam);
    let (mut refit, mut shortcut) = (0.0, 0.0);
    for i in 0..12 {
        let (xi, yi) = (drop(x, i), drop(&Y, i));
        let (gi, _) = spline(&xi, &yi, lam);
        refit += (Y[i] - spline_at(&xi, &gi, x[i])).powi(2);
        let sii = spline(x, &unit(i), lam).0[i];
        shortcut += ((Y[i] - g[i]) / (1.0 - sii)).powi(2);
    }
    (refit / 12.0, shortcut / 12.0)
}

fn main() {
    let (x, y) = (xs(), Y.to_vec());
    println!("waits, time  {}", x.iter().map(|v| format!("{:>5}", clock(*v))).collect::<Vec<_>>().join(" "));
    println!("waits, min   {}", y.iter().map(|v| format!("{:5.1}", v)).collect::<Vec<_>>().join(" "));
    let w9 = bell(2.0, &x, H);
    println!("9:00 weights {}", join(&w9, 4));
    println!("9:00 w*wait  {}", join(&w9.iter().zip(&y).map(|(a, b)| a * b).collect::<Vec<_>>(), 4));
    println!("9:00 NW: sum(w*wait) {:.4} / sum(w) {:.4} = {:.4}", dot(&w9, &y), w9.iter().sum::<f64>(), nw(2.0, &x, &y, H));
    let (nw7, (ll7, l7)) = (nw(0.0, &x, &y, H), loclin(0.0, &x, &y, H));
    let w7 = bell(0.0, &x, H);
    println!("7:00 NW: sum(w*wait) {:.4} / sum(w) {:.4} = {:.4}", dot(&w7, &y), w7.iter().sum::<f64>(), nw7);
    let hand = |c: f64| -> Vec<f64> { (0..12).map(|i| (-2.0 * (i as f64 - c).powi(2) / 9.0).exp()).collect() }; // by hand: visits 20|i - c| min away weigh e^(-2(i-c)^2/9)
    assert!([(6.0, nw(2.0, &x, &y, H)), (0.0, nw7)].iter().all(|&(c, v)| (dot(&hand(c), &y) / hand(c).iter().sum::<f64>() - v).abs() < 1e-12), "NW from hand-built weights");
    println!("7:00 weighted mean time of its weights {:.2} min; local-linear {:.4}; observed {}", dot(&w7, &x) / w7.iter().sum::<f64>() * 60.0, ll7, Y[0]);
    println!("7:00 local-linear weights {}", join(&l7[..5], 4));
    let line: Vec<f64> = x.iter().map(|v| 1.5 + 5.0 * v).collect(); // a wait rising 5 minutes per hour
    println!("on a straight line 1.5 + 5x: NW at 7:00 {:.4}, local-linear {:.4}, NW at 9:00 {:.4}, NW at 10:40 {:.4} (true {:.4})",
        nw(0.0, &x, &line, H), loclin(0.0, &x, &line, H).0, nw(2.0, &x, &line, H), nw(x[11], &x, &line, H), line[11]);
    assert!((l7.iter().sum::<f64>() - 1.0).abs() < 1e-12 && dot(&l7, &x).abs() < 1e-12, "local-linear weights reproduce lines");
    assert!((loclin(0.0, &x, &line, H).0 - 1.5).abs() < 1e-12, "local-linear has no edge bias on a line");
    assert!(nw(0.0, &x, &line, H) > 1.5 + 0.5, "the plain average is pulled inward at the edge");

    let cv: Vec<(f64, f64, f64)> = (-16..5).map(|k| { let lam = 10f64.powf(k as f64 / 4.0); let (a, b) = loo(&x, lam); (lam, a, b) }).collect();
    for &(_, a, b) in &cv { assert!((a - b).abs() < 1e-9, "the hat shortcut equals real refits"); }
    let best = *cv.iter().min_by(|p, q| p.1.partial_cmp(&q.1).unwrap()).unwrap();
    println!("lambda  {}", cv[8..].iter().map(|r| format!("{:7.4}", r.0)).collect::<Vec<_>>().join(" "));
    println!("LOO-CV  {}", cv[8..].iter().map(|r| format!("{:7.4}", r.1)).collect::<Vec<_>>().join(" "));
    let lam = best.0;
    let (g, pen) = spline(&x, &y, lam);
    let gg = grid_fit(lam, 20);
    let dfof = |l: f64| -> f64 { (0..12).map(|i| spline(&x, &unit(i), l).0[i]).sum() }; let df = dfof(lam);
    let sse = |v: &[f64]| -> f64 { y.iter().zip(v).map(|(a, b)| (a - b).powi(2)).sum() };
    let rss = sse(&g);
    println!("chosen lambda {:.4}: LOO-CV refits {:.4}, hat shortcut {:.4}; effective df {:.2}", lam, best.1, best.2, df);
    println!("spline fit, Reinsch  {}", join(&g, 2));
    println!("spline fit, grid     {}", join(&gg, 2));
    let gap = g.iter().zip(&gg).map(|(a, b)| (a - b).abs()).fold(0.0, f64::max);
    println!("max gap Reinsch vs grid {:.4}; RSS {:.4} + lambda x penalty {:.4} = {:.4}", gap, rss, lam * pen, rss + lam * pen);
    assert!(gap < 2e-3, "two roads to the spline agree");
    let obj = |v: &[f64]| sse(v) + lam * spline(&x, v, 0.0).1;
    for i in 0..12 { // road 3: nudging any fitted value raises the objective
        for e in [0.01, -0.01] {
            let v: Vec<f64> = g.iter().enumerate().map(|(j, u)| if j == i { u + e } else { *u }).collect();
            assert!(obj(&v) > obj(&g), "Reinsch fit is the minimiser");
        }
    }
    println!("chart, NW           {}", join(&x.iter().map(|v| nw(*v, &x, &y, H)).collect::<Vec<_>>(), 2));
    println!("chart, local-linear {}", join(&x.iter().map(|v| loclin(*v, &x, &y, H).0).collect::<Vec<_>>(), 2));
    let (g0, ginf) = (spline(&x, &y, 1e-6).0, spline(&x, &y, 1e6).0);
    let (mx, my) = (x.iter().sum::<f64>() / 12.0, y.iter().sum::<f64>() / 12.0);
    let b1 = x.iter().zip(&y).map(|(a, b)| (a - mx) * (b - my)).sum::<f64>() / x.iter().map(|a| (a - mx).powi(2)).sum::<f64>();
    assert!((ginf[6] - (my + b1 * (x[6] - mx))).abs() < 1e-3, "a huge lambda leaves the least-squares line");
    println!("lambda 0.000001: RSS {:.4}, LOO-CV {:.4}, df {:.2}", sse(&g0), loo(&x, 1e-6).0, dfof(1e-6));
    println!("lambda 1000000: 9:00 value {:.4}, least-squares line at 9:00 {:.4}, LOO-CV {:.4}, df {:.2}", ginf[6], my + b1 * (x[6] - mx), loo(&x, 1e6).0, dfof(1e6));
    println!("bandwidth 30 read as hours: NW at 7:00 {:.4}, mean of all waits {:.4}", nw(0.0, &x, &y, 30.0), my);
    println!("ALL CHECKS PASS");
}
