// Spline end conditions and a monotone scheme -- the check behind the card.  std only.
// Every scheme is a Hermite cubic on each gap; the schemes differ only in the slopes s_i at the knots.
const T: [f64; 8] = [1.0, 2.0, 3.0, 4.0, 5.0, 7.0, 10.0, 15.0]; // maturities, years
const Y: [f64; 8] = [3.50, 3.50, 3.55, 4.25, 4.50, 4.55, 4.60, 4.60]; // forward rates, % a year (illustrative)

fn e(x: f64, p: usize) -> String { // Python's %.<p>e
    let s = format!("{:.*e}", p, x); let (m, ex) = s.split_once('e').unwrap(); let k: i32 = ex.parse().unwrap();
    format!("{}e{}{:02}", m, if k < 0 { '-' } else { '+' }, k.abs())
}
fn join(v: &[f64], f: &dyn Fn(f64) -> String, sep: &str) -> String { v.iter().map(|&x| f(x)).collect::<Vec<_>>().join(sep) }
fn solve(mut a: Vec<Vec<f64>>, mut b: Vec<f64>) -> Vec<f64> { // Gaussian elimination with partial pivoting
    let n = b.len();
    for k in 0..n {
        let mut p = k; for i in k + 1..n { if a[i][k].abs() > a[p][k].abs() { p = i; } } // first largest pivot
        a.swap(k, p); b.swap(k, p);
        for i in k + 1..n { let m = a[i][k] / a[k][k]; for j in k..n { a[i][j] -= m * a[k][j]; } b[i] -= m * b[k]; }
    }
    let mut x = vec![0.0; n];
    for i in (0..n).rev() { let mut acc = b[i]; for j in i + 1..n { acc -= a[i][j] * x[j]; } x[i] = acc / a[i][i]; }
    x
}
fn gaps(t: &[f64], y: &[f64]) -> (Vec<f64>, Vec<f64>, usize) {
    let h: Vec<f64> = (0..t.len() - 1).map(|i| t[i + 1] - t[i]).collect();
    let d = (0..h.len()).map(|i| (y[i + 1] - y[i]) / h[i]).collect();
    let n = h.len(); (h, d, n)
}
fn road1(t: &[f64], y: &[f64], end: &str, a0: f64, b0: f64) -> Vec<f64> { // unknowns: the slopes
    let (h, d, n) = gaps(t, y);
    let (mut a, mut r) = (vec![vec![0.0; n + 1]; n + 1], vec![0.0; n + 1]);
    for i in 1..n {
        a[i][i - 1] = h[i]; a[i][i] = 2.0 * (h[i - 1] + h[i]); a[i][i + 1] = h[i - 1];
        r[i] = 3.0 * (h[i] * d[i - 1] + h[i - 1] * d[i]);
    }
    for (e, f, g, k, j) in [(0, 1, 2, 0, 1), (n, n - 1, n - 2, n - 1, n - 2)] {
        if end == "natural" { a[e][e] = 2.0; a[e][f] = 1.0; r[e] = 3.0 * d[k]; }
        else if end == "clamped" { a[e][e] = 1.0; r[e] = if e == 0 { a0 } else { b0 }; }
        else { // not-a-knot: S''' equal on the two end gaps
            let (q, u) = (1.0 / (h[k] * h[k]), 1.0 / (h[j] * h[j]));
            a[e][e] = q; a[e][f] = q - u; a[e][g] = -u; r[e] = 2.0 * d[k] * q - 2.0 * d[j] * u;
        }
    }
    solve(a, r)
}
fn road2(t: &[f64], y: &[f64], end: &str) -> Vec<f64> { // unknowns: second derivatives M
    let (h, d, n) = gaps(t, y);
    let (mut a, mut r) = (vec![vec![0.0; n + 1]; n + 1], vec![0.0; n + 1]);
    for i in 1..n {
        a[i][i - 1] = h[i - 1]; a[i][i] = 2.0 * (h[i - 1] + h[i]); a[i][i + 1] = h[i]; r[i] = 6.0 * (d[i] - d[i - 1]);
    }
    if end == "natural" { a[0][0] = 1.0; a[n][n] = 1.0; }
    else if end == "clamped" {
        a[0][0] = 2.0 * h[0]; a[0][1] = h[0]; r[0] = 6.0 * (d[0] - 0.0);
        a[n][n - 1] = h[n - 1]; a[n][n] = 2.0 * h[n - 1]; r[n] = 6.0 * (0.0 - d[n - 1]);
    } else {
        a[0][0] = h[1]; a[0][1] = -(h[0] + h[1]); a[0][2] = h[0];
        a[n][n - 2] = h[n - 1]; a[n][n - 1] = -(h[n - 2] + h[n - 1]); a[n][n] = h[n - 2];
    }
    let m = solve(a, r);
    let mut s: Vec<f64> = (0..n).map(|i| d[i] - h[i] * (2.0 * m[i] + m[i + 1]) / 6.0).collect();
    s.push(d[n - 1] + h[n - 1] * (m[n - 1] + 2.0 * m[n]) / 6.0); s
}
fn monotone(t: &[f64], y: &[f64], limit: bool) -> Vec<f64> { // weighted harmonic mean, or plain averages
    let (h, d, n) = gaps(t, y);
    let mut s = vec![0.0; n + 1];
    for i in 1..n {
        if !limit { s[i] = (d[i - 1] + d[i]) / 2.0; }
        else if d[i - 1] * d[i] > 0.0 {
            let (w1, w2) = (2.0 * h[i] + h[i - 1], h[i] + 2.0 * h[i - 1]);
            s[i] = (w1 + w2) / (w1 / d[i - 1] + w2 / d[i]);
        }
    }
    for (e, k, j) in [(0, 0, 1), (n, n - 1, n - 2)] {
        let mut v = ((2.0 * h[k] + h[j]) * d[k] - h[k] * d[j]) / (h[k] + h[j]);
        if v * d[k] <= 0.0 { v = 0.0; } else if d[k] * d[j] <= 0.0 && v.abs() > (3.0 * d[k]).abs() { v = 3.0 * d[k]; }
        s[e] = if limit { v } else { d[k] };
    }
    s
}
fn sv(t: &[f64], y: &[f64], s: &[f64], x: f64, der: u8) -> f64 { // the Hermite cubic, or its second derivative
    let mut i = 0;
    while i < t.len() - 2 && x > t[i + 1] { i += 1; }
    let h = t[i + 1] - t[i]; let p = (x - t[i]) / h; let p2 = p * p; let p3 = p2 * p;
    if der == 0 { return y[i] * (2.0*p3 - 3.0*p2 + 1.0) + h * s[i] * (p3 - 2.0*p2 + p) + y[i+1] * (3.0*p2 - 2.0*p3) + h * s[i+1] * (p3 - p2); }
    (y[i] * (12.0*p - 6.0) + h * s[i] * (6.0*p - 4.0) + y[i+1] * (6.0 - 12.0*p) + h * s[i+1] * (6.0*p - 2.0)) / (h * h)
}
fn low_by_roots(t: &[f64], y: &[f64], s: &[f64], i: usize) -> f64 { // roots of the quadratic S'
    let h = t[i + 1] - t[i]; let dl = (y[i + 1] - y[i]) / h;
    let (qa, qb, qc) = (3.0 * s[i] + 3.0 * s[i + 1] - 6.0 * dl, 6.0 * dl - 4.0 * s[i] - 2.0 * s[i + 1], s[i]);
    let mut ps = if qa == 0.0 && qb != 0.0 { vec![-qc / qb] } else { vec![] };
    if qa != 0.0 && qb * qb - 4.0 * qa * qc >= 0.0 {
        let r = (qb * qb - 4.0 * qa * qc).sqrt(); ps = vec![(-qb - r) / (2.0 * qa), (-qb + r) / (2.0 * qa)];
    }
    let mut lo = y[i].min(y[i + 1]);
    for p in ps { if 0.0 < p && p < 1.0 { lo = lo.min(sv(t, y, s, t[i] + h * p, 0)); } }
    lo
}
fn f(x: f64) -> f64 { 4.60 - 1.10 * (-(x - 1.0) / 4.0).exp() }
fn fp(x: f64) -> f64 { 0.275 * (-(x - 1.0) / 4.0).exp() }
fn cub(x: f64) -> f64 { 3.0 + 0.3 * x - 0.03 * x * x + 0.001 * x * x * x }
fn cubp(x: f64) -> f64 { 0.3 - 0.06 * x + 0.003 * x * x }
fn err(t: &[f64], g: fn(f64) -> f64, s: &[f64]) -> f64 {
    let y: Vec<f64> = t.iter().map(|&v| g(v)).collect(); let mut m: f64 = 0.0;
    for i in 0..t.len() - 1 { for k in 1..10 { let x = t[i] + (t[i + 1] - t[i]) * k as f64 / 10.0; m = m.max((sv(t, &y, s, x, 0) - g(x)).abs()); } }
    m
}
fn schemes(t: &[f64], g: fn(f64) -> f64, gp: fn(f64) -> f64) -> Vec<(&'static str, Vec<f64>)> {
    let y: Vec<f64> = t.iter().map(|&v| g(v)).collect(); let l = t.len() - 1;
    vec![("natural", road1(t, &y, "natural", 0.0, 0.0)), ("clamped", road1(t, &y, "clamped", gp(t[0]), gp(t[l]))),
         ("not-a-knot", road1(t, &y, "not-a-knot", 0.0, 0.0)), ("monotone", monotone(t, &y, true)), ("flat ends", road1(t, &y, "clamped", 0.0, 0.0))]
}

fn main() {
    let ends = ["natural", "clamped", "not-a-knot"]; let d1 = Y[2] - Y[1];
    let mut sl: Vec<(&str, Vec<f64>)> = ends.iter().map(|&k| (k, road1(&T, &Y, k, 0.0, 0.0))).collect();
    sl.push(("monotone", monotone(&T, &Y, true)));
    println!("quotes: {} | gap slopes: {}", (0..8).map(|i| format!("{}y {:.2}", T[i], Y[i])).collect::<Vec<_>>().join(" "), join(&gaps(&T, &Y).1, &|v| format!("{:.4}", v), " "));
    for (k, s) in &sl { println!("{:<10} slopes {}", k, join(s, &|v| format!("{:+.4}", v), " ")); }
    let mut gap: f64 = 0.0;
    for (i, k) in ends.iter().enumerate() { for (u, v) in sl[i].1.iter().zip(road2(&T, &Y, k)) { gap = gap.max((u - v).abs()); } }
    println!("road 2 (second derivatives) against road 1 (slopes), largest slope difference: {}", e(gap, 1)); assert!(gap < 1e-12);
    for (k, s) in &sl {
        let g = (0..4001).map(|k2| sv(&T, &Y, s, 2.0 + k2 as f64 / 4000.0, 0)).fold(f64::INFINITY, f64::min);
        let r = low_by_roots(&T, &Y, s, 1);
        println!("{:<10} lowest on 2y-3y: {:.4}% by roots, {:.4}% on a grid, {:+.2} bp against 3.50", k, r, g, (r - Y[1]) * 100.0);
        assert!((g - r).abs() < 1e-6 && if *k != "monotone" { r < Y[1] - 0.03 } else { r >= Y[1] - 1e-12 });
    }
    for i in [0, 3] { let (k, s) = (&sl[i].0, &sl[i].1);
        println!("{:<10} 2y-3y: delta {:.4}, s(2y) {:+.4}, s(3y) {:+.4}, alpha {:+.4}, beta {:+.4}, S(2.35) {:.4}", k, d1, s[1], s[2], s[1] / d1, s[2] / d1, sv(&T, &Y, s, 2.35, 0)); }
    let v: Vec<Vec<f64>> = sl.iter().map(|(_, s)| (0..14001).map(|j| sv(&T, &Y, s, 1.0 + j as f64 / 1000.0, 0)).collect()).collect();
    let over: Vec<f64> = v.iter().map(|w| w.iter().fold(f64::NEG_INFINITY, |a, &b| a.max(b)) - Y[7]).collect();
    println!("highest point above the 4.60 top quote, bp: {}", (0..4).map(|i| format!("{} {:+.2}", sl[i].0, over[i] * 100.0)).collect::<Vec<_>>().join(" "));
    assert!(over[3] <= 1e-12 && over[2] > 0.01 && v[3].windows(2).fold(f64::INFINITY, |m, w| m.min(w[1] - w[0])) > -1e-12);
    for i in [0, 2, 3] { println!("chart, {}: {}", sl[i].0, (0..17).map(|j| format!("{:.4}", sv(&T, &Y, &sl[i].1, 1.0 + 0.125 * j as f64, 0))).collect::<Vec<_>>().join(", ")); }
    let mut bump = Y; bump[3] += 0.01;
    for k in ["natural", "monotone"] {
        let fit = |y: &[f64]| if k == "natural" { road1(&T, y, "natural", 0.0, 0.0) } else { monotone(&T, y, true) };
        let ch: Vec<f64> = [1.5, 12.5].iter().map(|&x| (sv(&T, &bump, &fit(&bump), x, 0) - sv(&T, &Y, &fit(&Y), x, 0)) * 100.0).collect();
        println!("{:<10} 4y quote +1 bp moves 1.5y by {:+.4} bp, 12.5y by {:+.4} bp", k, ch[0], ch[1]);
        assert!(if k == "monotone" { ch[0] == 0.0 && ch[1] == 0.0 } else { ch[0].abs().min(ch[1].abs()) > 1e-3 });
    }
    let jump = |s: &[f64]| sv(&T[3..], &Y[3..], &s[3..], 4.0, 2) - sv(&T[..4], &Y[..4], &s[..4], 4.0, 2);
    let (jm, jn) = (jump(&sl[3].1), jump(&sl[0].1));
    println!("jump in S'' at 4y, % a year per year squared: monotone {:+.4}, natural spline {}", jm, e(jn.abs(), 1)); assert!(jm.abs() > 0.1 && jn.abs() < 1e-12);
    println!("flops at n = 7: natural spline rows 9n - 4 = {}, Thomas sweep 8n + 1 = {}, total {}; monotone at most 13n + 10 = {}", 9 * 7 - 4, 8 * 7 + 1, 17 * 7 - 3, 13 * 7 + 10);
    // Errors against a known smooth forward curve f(t) = 4.60 - 1.10 exp(-(t - 1)/4), 1y to 15y
    println!("n    h       natural    clamped    not-a-knot monotone   flat ends  clamped bound");
    let ns = [7usize, 14, 28, 56, 112]; let mut tab: Vec<Vec<f64>> = vec![]; let mut bound = 0.0;
    for &n in &ns {
        let t: Vec<f64> = (0..=n).map(|i| 1.0 + 14.0 * i as f64 / n as f64).collect();
        let row: Vec<f64> = schemes(&t, f, fp).iter().map(|(_, s)| err(&t, f, s)).collect();
        bound = 5.0 / 384.0 * (14.0 / n as f64).powf(4.0) * 1.10 / 256.0;
        println!("{:<4} {:<7.4} {} {}", n, 14.0 / n as f64, join(&row, &|v| e(v, 3) + " ", " "), e(bound, 3));
        assert!(row[1] <= bound); tab.push(row);
    }
    println!("bound / true error, clamped, n = 112: {:.2}", bound / tab[4][1]);
    let names = ["natural", "clamped", "not-a-knot", "monotone", "flat ends"];
    let order: Vec<f64> = (0..5).map(|k| (tab[3][k] / tab[4][k]).log2()).collect();
    println!("observed order, n 56 to 112: {}", (0..5).map(|k| format!("{} {:.2}", names[k], order[k])).collect::<Vec<_>>().join(" "));
    for k in [0, 2, 3] { println!("chart, log10 error, {}: {}", names[k], (0..5).map(|r| format!("{:.2}", tab[r][k].log10())).collect::<Vec<_>>().join(", ")); }
    assert!((order[0] - 2.0).abs() < 0.2 && (order[1] - 4.0).abs() < 0.2 && (order[2] - 4.0).abs() < 0.2);
    assert!((order[3] - 3.0).abs() < 0.3 && (order[4] - 1.0).abs() < 0.2);
    let cs = schemes(&T, cub, cubp); let ce: Vec<f64> = (0..3).map(|k| err(&T, cub, &cs[k].1)).collect();
    println!("a cubic through the 8 maturities, largest error: {}", (0..3).map(|k| format!("{} {}", names[k], e(ce[k], 1))).collect::<Vec<_>>().join(" "));
    assert!(ce[1] < 1e-12 && ce[2] < 1e-12 && ce[0] > 1e-3);
    let avg = monotone(&T, &Y, false); let la = low_by_roots(&T, &Y, &avg, 1);
    println!("plain average slopes: s(3y) {:+.4}, beta {:.2}, lowest on 2y-3y {:.4}%, {:+.2} bp", avg[2], avg[2] / d1, la, (la - Y[1]) * 100.0);
    assert!(la < Y[1] - 0.001);
    assert!((sl[3].1[4] - 0.05).abs() < 1e-12); // by hand at 5y, gaps 1 and 2: 9/(5/0.25 + 4/0.025)
    println!("ALL CHECKS PASS");
}
