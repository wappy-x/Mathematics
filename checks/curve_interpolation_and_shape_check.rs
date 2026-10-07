// Curve interpolation and shape -- the same check as the Python, in Rust.  No crates: the quadrature rule,
// the three-by-three solve and the tau sweep are written out.  Six pillars, three rules, compared.
struct Curve { t: [f64; 7], d: [f64; 7], l: [f64; 7], h: [f64; 6], seg: [f64; 6], pf: [f64; 7] }

fn build(t: [f64; 7], z: [f64; 6]) -> Curve {                 // pillars, their logs, and the gaps
    let (mut d, mut l, mut h) = ([1.0f64; 7], [0.0f64; 7], [0.0f64; 6]);
    let (mut seg, mut pf) = ([0.0f64; 6], [0.0f64; 7]);
    for i in 1..7 { d[i] = (-z[i - 1] * t[i]).exp(); l[i] = d[i].ln(); }
    for i in 0..6 { h[i] = t[i + 1] - t[i]; seg[i] = (l[i] - l[i + 1]) / h[i]; }
    for i in 1..6 { pf[i] = (h[i] * seg[i - 1] + h[i - 1] * seg[i]) / (h[i - 1] + h[i]); }   // rule 2, step one
    pf[0] = seg[0] - 0.5 * (pf[1] - seg[0]);
    pf[6] = seg[5] - 0.5 * (pf[5] - seg[5]);
    Curve { t, d, l, h, seg, pf }
}
fn gauss<F: Fn(f64) -> f64>(f: &F, a: f64, b: f64, n: usize) -> f64 {   // two sample points per strip
    let h = (b - a) / n as f64; let c = h / (2.0 * 3.0_f64.sqrt());     // exact for any cubic on a strip
    h / 2.0 * (0..n).map(|i| { let m = a + (i as f64 + 0.5) * h; f(m - c) + f(m + c) }).sum::<f64>()
}
fn integral<F: Fn(f64) -> f64>(f: &F, a: f64, b: f64, breaks: &[f64], n: usize) -> f64 {
    let mut p: Vec<f64> = breaks.iter().copied().filter(|&x| x > a && x < b).collect();
    p.sort_by(|x, y| x.partial_cmp(y).unwrap()); p.insert(0, a); p.push(b);   // cut at the breaks
    (0..p.len() - 1).map(|k| gauss(f, p[k], p[k + 1], n)).sum()
}
fn gap(c: &Curve, t: f64) -> usize { (0..6).find(|&i| t < c.t[i + 1]).unwrap_or(5) }  // a pillar starts a gap
fn f_loglin(c: &Curve, t: f64) -> f64 { c.seg[gap(c, t)] }    // rule 1's forward: one flat step per gap
fn d_loglin(c: &Curve, t: f64) -> f64 {                       // rule 1: a line between the log discounts
    let i = gap(c, t); let w = (t - c.t[i]) / c.h[i]; ((1.0 - w) * c.l[i] + w * c.l[i + 1]).exp()
}
fn shape(c: &Curve, i: usize) -> (f64, f64, u8, f64) {        // Hagan-West: which region, where it turns
    let (g0, g1) = (c.pf[i] - c.seg[i], c.pf[i + 1] - c.seg[i]);   // the ends, from the segment forward
    if g0 == 0.0 || g1 == 0.0 || (g0 < 0.0 && -0.5 * g0 <= g1 && g1 <= -2.0 * g0)
        || (g0 > 0.0 && -0.5 * g0 >= g1 && g1 >= -2.0 * g0) { return (g0, g1, 1, 1.0); }  // parabola behaves
    if (g0 < 0.0 && g1 > -2.0 * g0) || (g0 > 0.0 && g1 < -2.0 * g0) {
        return (g0, g1, 2, (g1 + 2.0 * g0) / (g1 - g0));      // flat, then a curve
    }
    if (g0 > 0.0 && 0.0 > g1 && g1 > -0.5 * g0) || (g0 < 0.0 && 0.0 < g1 && g1 < -0.5 * g0) {
        return (g0, g1, 3, 3.0 * g1 / (g1 - g0));             // a curve, then flat
    }
    (g0, g1, 4, g1 / (g0 + g1))                               // both ends the same side: a dip between
}
fn f_mc(c: &Curve, t: f64) -> f64 {                           // rule 2: the monotone convex forward
    let i = gap(c, t); let x = (t - c.t[i]) / c.h[i];
    let (g0, g1, region, eta) = shape(c, i);
    let g = if region == 1 {
        g0 * (1.0 - 4.0 * x + 3.0 * x * x) + g1 * (3.0 * x * x - 2.0 * x)
    } else if region == 2 {
        if x <= eta { g0 } else { g0 + (g1 - g0) * ((x - eta) / (1.0 - eta)).powi(2) }
    } else if region == 3 {
        if x < eta { g1 + (g0 - g1) * ((eta - x) / eta).powi(2) } else { g1 }
    } else {
        let a = -g0 * g1 / (g0 + g1);
        if x < eta { a + (g0 - a) * ((eta - x) / eta).powi(2) } else { a + (g1 - a) * ((x - eta) / (1.0 - eta)).powi(2) }
    };
    c.seg[i] + g
}
fn basis(t: f64, tau: f64) -> [f64; 3] {                      // rule 3: the three Nelson-Siegel shapes
    let e = (-t / tau).exp(); let slope = (1.0 - e) / (t / tau); [1.0, slope, slope - e]
}
fn solve3(a: [[f64; 3]; 3], v: [f64; 3]) -> [f64; 3] {        // Gaussian elimination, largest pivot first
    let mut m = [[0.0f64; 4]; 3];
    for r in 0..3 { for k in 0..3 { m[r][k] = a[r][k]; } m[r][3] = v[r]; }
    for c in 0..3 {
        let mut p = c;
        for r in c + 1..3 { if m[r][c].abs() > m[p][c].abs() { p = r; } }
        m.swap(c, p);
        for r in 0..3 { if r != c {
            let factor = m[r][c] / m[c][c];
            for k in 0..4 { m[r][k] -= factor * m[c][k]; }
        } }
    }
    [m[0][3] / m[0][0], m[1][3] / m[1][1], m[2][3] / m[2][2]]
}
fn fit(ts: &[f64], zs: &[f64], tau: f64) -> [f64; 3] {        // least squares on the six quotes, tau fixed
    let rows: Vec<[f64; 3]> = ts.iter().map(|&t| basis(t, tau)).collect();
    let (mut a, mut v) = ([[0.0f64; 3]; 3], [0.0f64; 3]);
    for x in 0..3 { v[x] = rows.iter().zip(zs.iter()).map(|(r, z)| r[x] * z).sum();
        for y in 0..3 { a[x][y] = rows.iter().map(|r| r[x] * r[y]).sum(); } }
    solve3(a, v)
}
fn line(beta: [f64; 3], r: [f64; 3]) -> f64 { beta[0] * r[0] + beta[1] * r[1] + beta[2] * r[2] }
fn sse(ts: &[f64], zs: &[f64], tau: f64, beta: [f64; 3]) -> f64 {   // total squared miss on the quotes
    ts.iter().zip(zs.iter()).map(|(&t, &z)| (line(beta, basis(t, tau)) - z).powi(2)).sum()
}
fn main() {
    let t = [0.0, 0.25, 1.0, 2.0, 5.0, 10.0, 30.0];           // today, then the six quoted dates, in years
    let z = [0.0430, 0.0400, 0.0380, 0.0390, 0.0420, 0.0450]; // the bootstrap's zero rates, a year each
    let c = build(t, z);
    let (ts, zs) = (&c.t[1..], &z[..]);
    let mut breaks: Vec<f64> = c.t.to_vec();                  // pillars plus every turning point
    for i in 0..6 { breaks.push(c.t[i] + shape(&c, i).3 * c.h[i]); }
    let fmc = |x: f64| f_mc(&c, x);
    let d_mc = |x: f64| (-integral(&fmc, 0.0, x, &breaks, 1)).exp();
    let (mut tau, mut best) = (0.10f64, f64::INFINITY);
    for k in 10..=1500 {                                      // hunt for tau, a hundredth of a year apart
        let cand = k as f64 * 0.01; let s = sse(ts, zs, cand, fit(ts, zs, cand));
        if s < best { best = s; tau = cand; } }
    let beta = fit(ts, zs, tau);
    let z_ns = |x: f64| line(beta, basis(x, tau));
    let f_ns = |x: f64| beta[0] + (beta[1] + beta[2] * x / tau) * (-x / tau).exp();
    let d_ns = |x: f64| (-z_ns(x) * x).exp();
    let d_lind = |x: f64| { let i = gap(&c, x); let w = (x - c.t[i]) / c.h[i];   // mistake: a line
        (1.0 - w) * c.d[i] + w * c.d[i + 1] };                                   // between the discounts
    let f_lind = |x: f64| { let i = gap(&c, x); (c.d[i] - c.d[i + 1]) / c.h[i] / d_lind(x) };
    let zf = [z[0], z[0], z[1], z[2], z[3], z[4], z[5]];      // mistake: a line between the zero rates
    let z_linz = |x: f64| { let i = gap(&c, x); let w = (x - c.t[i]) / c.h[i];
        (1.0 - w) * zf[i] + w * zf[i + 1] };
    let f_linz = |x: f64| { let i = gap(&c, x); z_linz(x) + x * (zf[i + 1] - zf[i]) / c.h[i] };
    let (pay, eps) = (10000000.0f64, 1e-9f64);
    println!("six pillars from one morning: years, zero rate %, discount factor, log discount");
    for i in 1..7 { println!("{:8.2}{:9.4}{:12.6}{:12.6}", c.t[i], 100.0 * z[i - 1], c.d[i], c.l[i]); }
    println!("across each gap: the segment forward %, then the shape monotone convex gives it");
    for i in 0..6 {
        let (g0, g1, region, eta) = shape(&c, i);
        println!("{:6.2} to{:6.2}{:9.4}   region {}   ends{:+8.4}{:+8.4}   turn at{:7.4}",
                 c.t[i], c.t[i + 1], 100.0 * c.seg[i], region, 100.0 * g0, 100.0 * g1, eta);
    }
    let pillars: Vec<String> = c.pf.iter().map(|p| format!("{:.4}", 100.0 * p)).collect();
    println!("monotone convex, forward at each pillar %: {}", pillars.join(" "));
    println!("three forward curves, % a year: years, log-linear, monotone convex, Nelson-Siegel");
    for k in 0..10 {
        let x = 0.5 + k as f64;
        println!("{:8.2}{:8.2}{:8.2}{:8.2}", x, 100.0 * f_loglin(&c, x), 100.0 * fmc(x), 100.0 * f_ns(x));
    }
    let three = [f_loglin(&c, 2.5), fmc(2.5), f_ns(2.5)];
    let (hi, lo) = (three.iter().cloned().fold(f64::MIN, f64::max), three.iter().cloned().fold(f64::MAX, f64::min));
    println!("forward at 2.50 years %: log-linear {:.4}, monotone convex {:.4}, Nelson-Siegel {:.4}; \
              widest gap {:.2} basis points", 100.0 * three[0], 100.0 * three[1], 100.0 * three[2], 10000.0 * (hi - lo));
    println!("forward at 3.00 years %: log-linear {:.4}, monotone convex {:.4}, Nelson-Siegel {:.4}",
             100.0 * f_loglin(&c, 3.0), 100.0 * fmc(3.0), 100.0 * f_ns(3.0));
    println!("monotone convex, average forward from 2 to 3 years %: {:.4}",
             100.0 * integral(&fmc, 2.0, 3.0, &breaks, 1));
    println!("Nelson-Siegel fit: tau {:.2} years, beta0 {:.4}, beta1 {:.4}, beta2 {:.4}, all % a year",
             tau, 100.0 * beta[0], 100.0 * beta[1], 100.0 * beta[2]);
    let misses: Vec<String> = (1..7).map(|i| format!("{:+.2}", 10000.0 * (z_ns(c.t[i]) - z[i - 1]))).collect();
    println!("Nelson-Siegel minus the quote at each pillar, basis points: {}", misses.join(" "));
    let worst = |rule: &dyn Fn(f64) -> f64| (1..7).map(|i| (rule(c.t[i]) / c.d[i]).ln().abs() / c.t[i])
        .fold(0.0f64, f64::max) * 10000.0;
    println!("largest quote missed, basis points: log-linear {:.4}, monotone convex {:.4}, Nelson-Siegel {:.4}",
             worst(&|x| d_loglin(&c, x)), worst(&d_mc), worst(&d_ns));
    println!("{:.2} due in 1 year: the quotes say {:.2}, Nelson-Siegel says {:.2}, a gap of {:.2}",
             pay, pay * c.d[2], pay * d_ns(1.0), pay * (d_ns(1.0) - c.d[2]));
    println!("the 3-year discount factor, {:.2} due in 3 years, and the gap to the log-linear value", pay);
    for (name, d) in [("log-linear", d_loglin(&c, 3.0)), ("monotone convex", d_mc(3.0)),
                      ("Nelson-Siegel", d_ns(3.0)), ("line between discounts", d_lind(3.0)),
                      ("line between zero rates", (-z_linz(3.0) * 3.0).exp())] {
        println!("  {:<24}{:12.6}{:16.2}{:+12.2}", name, d, pay * d, pay * (d - d_loglin(&c, 3.0)));
    }
    println!("forward across the 10-year pillar, % a year: log-linear {:.4} to {:.4}, monotone convex \
              {:.4} to {:.4}, line between zero rates {:.4} to {:.4}",
             100.0 * f_loglin(&c, 10.0 - eps), 100.0 * f_loglin(&c, 10.0 + eps), 100.0 * fmc(10.0 - eps),
             100.0 * fmc(10.0 + eps), 100.0 * f_linz(10.0 - eps), 100.0 * f_linz(10.0 + eps));
    println!("inside the 2-to-5-year gap the line between discounts slides the forward from {:.4} to {:.4} \
              % a year, on no instruction from the quotes", 100.0 * f_lind(2.0), 100.0 * f_lind(5.0 - eps));
    for i in 1..6 { let mid = c.seg[i - 1] + (c.seg[i] - c.seg[i - 1]) * c.h[i - 1] / (c.h[i - 1] + c.h[i]);
        assert!((c.pf[i] - mid).abs() < 1e-15); }             // the pillar forwards, off the step midpoints
    // both exact rules hand every quote back
    for i in 1..7 { assert!((d_loglin(&c, c.t[i]) - c.d[i]).abs() < 1e-12 && (d_mc(c.t[i]) - c.d[i]).abs() < 1e-12); }
    let floglin = |x: f64| f_loglin(&c, x);
    assert!((d_loglin(&c, 3.0) - (-integral(&floglin, 0.0, 3.0, &c.t, 1)).exp()).abs() < 1e-12);
    // area under the forward equals the quoted gap
    for i in 0..6 { assert!((integral(&fmc, c.t[i], c.t[i + 1], &breaks, 1) - c.h[i] * c.seg[i]).abs() < 1e-14); }
    assert!((z_ns(5.0) * 5.0 - integral(&f_ns, 0.0, 5.0, &[], 2000)).abs() < 1e-11);
    for j in 0..3 { for step in [1e-5, -1e-5] {               // the fitted levels sit at a genuine low point
        let mut moved = beta; moved[j] += step;
        assert!(sse(ts, zs, tau, moved) > sse(ts, zs, tau, beta));
    } }
    assert!((1..6).map(|i| (fmc(c.t[i] + eps) - fmc(c.t[i] - eps)).abs()).fold(0.0f64, f64::max) < 1e-9);
    assert!((f_loglin(&c, 10.0 + eps) - f_loglin(&c, 10.0 - eps)).abs() > 0.001);
    println!("ALL CHECKS PASS");
}
