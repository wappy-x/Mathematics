// Weierstrass and the minimax fit -- the check behind the card.  std only, no crates.
// Target (illustrative spec): exp on [0, 1] with absolute error at most a millionth, 1e-06.
// Roads: Remez (levelled error, then max error), Chebyshev interpolation boxed in by the
// de la Vallee Poussin bound, the Chebyshev a-priori bound, Taylor, and Bernstein polynomials.
use std::f64::consts::PI;
const TOL: f64 = 1e-06;

fn sci(v: f64, p: usize) -> String { // Python-style e-notation: 4.028484e-08
    let s = format!("{:.*e}", p, v);
    let (m, e) = s.split_once('e').unwrap();
    let (sg, d) = if let Some(d) = e.strip_prefix('-') { ('-', d) } else { ('+', e) };
    format!("{}e{}{:0>2}", m, sg, d)
}
fn solve(a: &[Vec<f64>], b: &[f64]) -> Vec<f64> { // Gaussian elimination with partial pivoting
    let n = b.len();
    let mut m: Vec<Vec<f64>> = (0..n).map(|i| { let mut r = a[i].clone(); r.push(b[i]); r }).collect();
    for c in 0..n {
        let mut p = c;
        for r in c + 1..n { if m[r][c].abs() > m[p][c].abs() { p = r; } }
        m.swap(c, p);
        for r in c + 1..n {
            let f = m[r][c] / m[c][c];
            for k in c..=n { m[r][k] -= f * m[c][k]; }
        }
    }
    let mut x = vec![0.0; n];
    for r in (0..n).rev() {
        let mut s = m[r][n];
        for k in r + 1..n { s -= m[r][k] * x[k]; }
        x[r] = s / m[r][r];
    }
    x
}
fn pows(t: f64, n: usize) -> Vec<f64> { (0..=n).map(|k| (0..k).fold(1.0, |a, _| a * t)).collect() }
fn horner(c: &[f64], t: f64) -> f64 { c.iter().rev().fold(0.0, |s, &a| s * t + a) }
fn golden(g: &dyn Fn(f64) -> f64, mut a: f64, mut b: f64) -> (f64, f64) { // maximise g on [a, b]
    let r = (5.0f64.sqrt() - 1.0) / 2.0;
    for _ in 0..90 {
        let (c, d) = (b - r * (b - a), a + r * (b - a));
        if g(c) > g(d) { b = d; } else { a = c; }
    }
    let m = (a + b) / 2.0;
    (m, g(m))
}
fn extrema(e: &dyn Fn(f64) -> f64) -> Vec<(f64, f64)> { // one peak of |e| per run of one sign
    let nn = 2000usize;
    let ts: Vec<f64> = (0..=nn).map(|j| -1.0 + 2.0 * j as f64 / nn as f64).collect();
    let es: Vec<f64> = ts.iter().map(|&t| e(t)).collect();
    let mut runs: Vec<usize> = vec![];
    for j in 0..=nn {
        if let Some(&l) = runs.last() {
            if (es[j] > 0.0) == (es[l] > 0.0) { if es[j].abs() > es[l].abs() { *runs.last_mut().unwrap() = j; } continue; }
        }
        runs.push(j);
    }
    runs.iter().map(|&j| {
        if j == 0 || j == nn { return (ts[j], es[j]); }
        let s = if es[j] > 0.0 { 1.0 } else { -1.0 };
        let (t, v) = golden(&|u| s * e(u), ts[j - 1], ts[j + 1]);
        (t, s * v)
    }).collect()
}
fn fmap(a: f64, b: f64) -> impl Fn(f64) -> f64 { move |t| (a + (b - a) * (t + 1.0) / 2.0).exp() }
fn remez(n: usize, a: f64, b: f64, show: bool) -> (Vec<f64>, f64, f64, Vec<(f64, f64)>) {
    let (f, mut gap) = (fmap(a, b), f64::INFINITY);
    let mut rf: Vec<f64> = (0..n + 2).map(|i| -(i as f64 * PI / (n + 1) as f64).cos()).collect();
    for it in 1..16 {
        let am: Vec<Vec<f64>> = rf.iter().enumerate().map(|(i, &t)| { let mut r = pows(t, n); r.push(if i % 2 == 0 { 1.0 } else { -1.0 }); r }).collect();
        let sol = solve(&am, &rf.iter().map(|&t| f(t)).collect::<Vec<_>>());
        let (c, lev) = (sol[..n + 1].to_vec(), sol[n + 1].abs());
        let ext = extrema(&|t| f(t) - horner(&c, t));
        let top = ext.iter().fold(0.0f64, |m, &(_, v)| m.max(v.abs()));
        assert!(ext.len() == n + 2, "error must have n + 2 alternating peaks");
        if show { println!("remez degree {}, round {}: level {}, max error {}, gap {}", n, it, sci(lev, 6), sci(top, 6), sci(top - lev, 1)); }
        if top - lev <= 1e-6 * top + 4e-15 && top - lev > gap / 4.0 { return (c, lev, top, ext); } // gap stopped falling
        gap = top - lev; rf = ext.iter().map(|&(t, _)| t).collect();
    }
    panic!("Remez did not settle");
}
fn bern(f: &dyn Fn(f64) -> f64, n: usize, x: f64) -> f64 { // B_n f(x), weights grown from the middle
    if x <= 0.0 || x >= 1.0 { return f(x); }
    let (r, m) = (x / (1.0 - x), (n as f64 * x) as usize);
    let (mut s, mut tot) = (1.0, f(m as f64 / n as f64));
    let (mut w, mut k) = (1.0, m);
    while k < n && w > 1e-18 { w *= (n - k) as f64 / (k + 1) as f64 * r; k += 1; s += w; tot += w * f(k as f64 / n as f64); }
    let (mut w, mut k) = (1.0, m);
    while k > 0 && w > 1e-18 { w *= k as f64 / (n - k + 1) as f64 / r; k -= 1; s += w; tot += w * f(k as f64 / n as f64); }
    tot / s
}
fn bern_err(n: usize) -> (f64, f64) { // largest |B_n exp - exp| on [0, 1]
    let g = |x: f64| (bern(&|y: f64| y.exp(), n, x) - x.exp()).abs();
    let mut j: usize = 0;
    for i in 1..=200 { if g(i as f64 / 200.0) > g(j as f64 / 200.0) { j = i; } }
    golden(&g, j.saturating_sub(1) as f64 / 200.0, (j + 1).min(200) as f64 / 200.0)
}
fn fact(k: usize) -> f64 { (1..=k).fold(1.0, |a, i| a * i as f64) }
fn join<T>(v: impl Iterator<Item = T>, f: impl Fn(T) -> String) -> String { v.map(f).collect::<Vec<_>>().join(" ") }

fn main() {
    let e1 = 1.0f64.exp();
    println!("target: exp on [0, 1], absolute error at most {}", sci(TOL, 0));
    let tay: Vec<f64> = [6usize, 8, 9].iter().map(|&d| e1 - (0..=d).map(|k| 1.0 / fact(k)).sum::<f64>()).collect();
    println!("taylor at 0, error at x = 1: degree 6 {}, degree 8 {}, degree 9 {}", sci(tay[0], 4), sci(tay[1], 4), sci(tay[2], 4));
    let (c6, e6, top6, ext6) = remez(6, 0.0, 1.0, true);
    let e5 = remez(5, 0.0, 1.0, false).1;
    println!("minimax error: degree 5 {}, degree 6 {}", sci(e5, 6), sci(e6, 6));
    println!("degree 6 peaks at x: {}", join(ext6.iter(), |&(t, _)| format!("{:.4}", (t + 1.0) / 2.0)));
    println!("signs: {}", join(ext6.iter(), |&(_, v)| (if v > 0.0 { "+" } else { "-" }).to_string()));
    let f01 = fmap(0.0, 1.0);
    let nodes: Vec<f64> = (0..7).map(|i| ((2 * i + 1) as f64 * PI / 14.0).cos()).collect();
    let ci = solve(&nodes.iter().map(|&t| pows(t, 6)).collect::<Vec<_>>(), &nodes.iter().map(|&t| f01(t)).collect::<Vec<_>>());
    let ext = extrema(&|t| f01(t) - horner(&ci, t));
    let lo = ext.iter().fold(f64::INFINITY, |m, &(_, v)| m.min(v.abs()));
    let hi = ext.iter().fold(0.0f64, |m, &(_, v)| m.max(v.abs()));
    let u6 = e1 * 2.0 / 4.0f64.powi(7) / fact(7);
    println!("chebyshev interpolant, degree 6: {} peaks, smallest {}, largest {}, ratio {:.4}", ext.len(), sci(lo, 6), sci(hi, 6), hi / lo);
    println!("so the best error lies in [{}, {}]; a-priori bound e*2/(4^7*7!) = {}, bound/true {:.3}", sci(lo, 6), sci(hi, 6), sci(u6, 6), u6 / e6);
    let mut cx = vec![0.0; 7];
    let mut pw = vec![1.0]; // rewrite p(t) with t = 2x - 1 as coefficients of x
    for &ck in &c6 {
        for (j, &v) in pw.iter().enumerate() { cx[j] += ck * v; }
        let mut nw = vec![0.0; pw.len() + 1];
        for (j, &v) in pw.iter().enumerate() { nw[j] -= v; nw[j + 1] += 2.0 * v; }
        pw = nw;
    }
    println!("chip coefficients, x^0..x^6: {}", join(cx.iter(), |v| format!("{:.10}", v)));
    let xmax = (0..=4000).fold(0.0f64, |m, i| m.max(((i as f64 / 4000.0).exp() - horner(&cx, i as f64 / 4000.0)).abs()));
    println!("chip form, max error on 4001 points {}; cost 6 multiplies + 6 adds", sci(xmax, 6));
    println!("outside the interval: at x = 2 the error is {}", sci(2.0f64.exp() - horner(&cx, 2.0), 4));
    let cc = (5.0f64.sqrt() - 2.0) * ((5.0f64.sqrt() - 1.0) / 2.0).exp() / 2.0;
    println!("bernstein n, at x, max error, n*error, bound e/(8n), bound/true");
    let ns = [10usize, 30, 100, 300, 1000, 3000, 10000, 30000, 100000];
    let bt: Vec<(f64, f64)> = ns.iter().map(|&n| bern_err(n)).collect();
    for (i, &n) in ns.iter().enumerate() {
        if i % 2 == 1 { continue; }
        let (x, v) = bt[i];
        println!("  {:>6} {:.4} {} {:.6} {} {:.3}", n, x, sci(v, 6), n as f64 * v, sci(e1 / 8.0 / n as f64, 6), e1 / 8.0 / n as f64 / v);
    }
    println!("limit of n*error: (sqrt5 - 2) e^0.618034 / 2 = {:.6}, at x = {:.6}", cc, (5.0f64.sqrt() - 1.0) / 2.0);
    let (nest, nbd) = ((cc / TOL).ceil() as usize, (e1 / 8.0 / TOL).ceil() as usize);
    let (x_est, v_est) = bern_err(nest);
    println!("degree for a millionth: estimate {}, guaranteed {}; largest error at {}: {} at x = {:.4}", nest, nbd, nest, sci(v_est, 6), x_est);
    let b2 = bern(&|x: f64| x * x, 10, 0.3);
    println!("identity: B_10(x^2) at 0.3 = {:.12}, x^2 + x(1-x)/n = {:.12}", b2, 0.09 + 0.3 * 0.7 / 10.0);
    let step = |x: f64| if x >= 0.5 { 1.0 } else { 0.0 };
    println!("step function, worst error (just left of 0.5), then error at 0.5: {}", join([10usize, 100, 1000, 10000].iter(), |&n| format!("n={} {:.4} {:.4}", n, bern(&step, n, 0.5), 1.0 - bern(&step, n, 0.5))));
    for d in [7usize, 8] { println!("try: degree {} minimax error {}", d, sci(remez(d, 0.0, 1.0, false).1, 4)); }
    println!("try: on [0, 2], degree 6 {}, degree 8 {}", sci(remez(6, 0.0, 2.0, false).1, 4), sci(remez(8, 0.0, 2.0, false).1, 4));
    let xs: Vec<f64> = (0..21).map(|i| i as f64 / 20.0).collect();
    println!("chart, minimax error x 1e8: {}", join(xs.iter(), |&x| format!("{:.2}", 1e8 * (x.exp() - horner(&c6, 2.0 * x - 1.0)))));
    println!("chart, chebyshev error x 1e8: {}", join(xs.iter(), |&x| format!("{:.2}", 1e8 * (x.exp() - horner(&ci, 2.0 * x - 1.0)))));
    println!("chart, log10 n: {}", join(ns.iter(), |&n| format!("{:.2}", (n as f64).log10())));
    println!("chart, log10 bernstein error: {}", join(bt.iter(), |&(_, v)| format!("{:.2}", v.log10())));
    println!("chart, log10 bound e/(8n): {}", join(ns.iter(), |&n| format!("{:.2}", (e1 / 8.0 / n as f64).log10())));

    assert!(lo <= e6 && e6 <= hi && e6 <= u6, "Remez must land inside the Chebyshev box and under the a-priori bound");
    assert!((top6 - e6).abs() <= 1e-6 * top6 && (xmax - e6).abs() < 1e-12, "levelled error = true max error, both forms");
    assert!(e5 > TOL && TOL > e6 && tay[1] > TOL && TOL > tay[2], "degree 6 is the least minimax degree, 9 the least Taylor degree");
    assert!((b2 - (0.09 + 0.3 * 0.7 / 10.0)).abs() < 1e-15, "Bernstein's second-moment identity");
    assert!(ns.iter().zip(&bt).all(|(&n, &(_, v))| v <= e1 / 8.0 / n as f64) && (100000.0 * bt[8].1 - cc).abs() < 1e-3, "bound and Voronovskaya");
    assert!(v_est < TOL && TOL < e1 / 8.0 / nest as f64, "the estimated degree reaches a millionth; the bound alone cannot promise it");
    println!("ALL CHECKS PASS");
}
