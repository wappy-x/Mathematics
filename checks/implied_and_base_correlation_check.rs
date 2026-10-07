// Implied (compound) and base correlation in the large-pool Gaussian copula.
// Pool: default chance P over the life, loss given default G = 1 - 40% recovery.
use std::f64::consts::PI;
const P: f64 = 0.05;
const G: f64 = 0.60;

fn npdf(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }
fn ncdf(x: f64) -> f64 { // own normal CDF: series, then continued fraction
    let u = x.abs();
    let tail = if u < 3.0 {
        let (mut term, mut s, mut k) = (u, u, 1.0);
        while term > 1e-17 * s { term *= u * u / (2.0 * k + 1.0); s += term; k += 1.0; }
        0.5 - npdf(u) * s
    } else {
        let mut cf = u;
        for k in (1..=120).rev() { cf = u + k as f64 / cf; }
        npdf(u) / cf
    };
    if x < 0.0 { tail } else { 1.0 - tail }
}
fn ninv(p: f64) -> f64 { // inverse CDF by bisection
    let (mut lo, mut hi) = (-10.0, 10.0);
    for _ in 0..100 { let m = 0.5 * (lo + hi); if ncdf(m) < p { lo = m } else { hi = m } }
    0.5 * (lo + hi)
}
fn simpson(f: &dyn Fn(f64) -> f64, lo: f64, hi: f64, n: usize) -> f64 {
    let h = (hi - lo) / n as f64;
    let mut s = 0.0;
    for j in 1..n { s += if j % 2 == 1 { 4.0 } else { 2.0 } * f(lo + j as f64 * h); }
    h / 3.0 * (f(lo) + f(hi) + s)
}
fn c0() -> f64 { ninv(P) } // default threshold c
fn zcut(k: f64, rho: f64) -> f64 { (c0() - (1.0 - rho).sqrt() * ninv(k / G)) / rho.sqrt() }
fn f1(k: f64, rho: f64) -> f64 { // road 1: E[min(L, K)] averaged over the market factor
    if k <= 0.0 { return 0.0; }
    if rho <= 0.0 { return (G * P).min(k); }
    if rho >= 1.0 { return P * G.min(k); }
    let z = zcut(k, rho).max(-9.0).min(9.0);
    let c = c0();
    let loss = |x: f64| G * ncdf((c - rho.sqrt() * x) / (1.0 - rho).sqrt()) * npdf(x);
    k * ncdf(z) + simpson(&loss, z, 9.0, 2000)
}
fn f2(k: f64, rho: f64) -> f64 { // road 2: bivariate normal CDF by Plackett's identity
    let (z, r, c) = (zcut(k, rho), rho.sqrt(), c0());
    let dens = |s: f64| (-(c * c - 2.0 * s * c * z + z * z) / (2.0 * (1.0 - s * s))).exp() / (2.0 * PI * (1.0 - s * s).sqrt());
    k * ncdf(z) + G * (P - ncdf(c) * ncdf(z) - simpson(&dens, 0.0, r, 2000))
}
fn m(a: f64, b: f64, rho: f64) -> f64 { (f1(b, rho) - f1(a, rho)) / (b - a) }
fn df(k: f64, rho: f64) -> f64 { -G * npdf(ninv(k / G)) * npdf(zcut(k, rho)) / (2.0 * (rho * (1.0 - rho)).sqrt()) }
fn dm(a: f64, b: f64, rho: f64) -> f64 { (df(b, rho) - if a > 0.0 { df(a, rho) } else { 0.0 }) / (b - a) }
fn peak_rho(a: f64, b: f64) -> Option<f64> { // closed form; None when the tranche has no hump
    let bs = (if a > 0.0 { ninv(a / G) } else { -1e9 }) + ninv(b / G);
    let c = c0();
    if 2.0 * c < bs && bs < 0.0 { Some(1.0 - (bs / (2.0 * c)).powi(2)) } else { None }
}
fn bisect(f: &dyn Fn(f64) -> f64, mut lo: f64, mut hi: f64) -> f64 { // road 1 for every inverse
    let flo = f(lo);
    for _ in 0..60 { let x = 0.5 * (lo + hi); if (f(x) > 0.0) == (flo > 0.0) { lo = x } else { hi = x } }
    0.5 * (lo + hi)
}
fn newton(f: &dyn Fn(f64) -> f64, d: &dyn Fn(f64) -> f64, lo: f64, hi: f64) -> f64 { // road 2, kept in the branch
    let mut x = 0.5 * (lo + hi);
    for _ in 0..40 {
        let y = x - f(x) / d(x);
        x = if lo < y && y < hi { y } else { 0.5 * (x + if y <= lo { lo } else { hi }) };
    }
    x
}
fn compound(a: f64, b: f64, q: f64) -> Vec<(f64, f64)> { // every correlation in (0,1) repricing the quote q
    let top = peak_rho(a, b).unwrap_or(0.999999);
    let mut ends = vec![(1e-9, top)];
    if top < 0.999999 { ends.push((top, 1.0)); }
    let mut out = Vec::new();
    for (lo, hi) in ends {
        let f = |r: f64| m(a, b, r) - q;
        if f(lo) * f(hi) < 0.0 { out.push((bisect(&f, lo, hi), newton(&f, &|r| dm(a, b, r), lo, hi))); }
    }
    out
}
fn golden_max(f: &dyn Fn(f64) -> f64, mut lo: f64, mut hi: f64) -> f64 { // peak found numerically
    let g = (5f64.sqrt() - 1.0) / 2.0;
    for _ in 0..80 {
        let (a, b) = (hi - g * (hi - lo), lo + g * (hi - lo));
        if f(a) < f(b) { lo = a } else { hi = b }
    }
    0.5 * (lo + hi)
}
fn pool100(k: f64, rho: f64) -> f64 { // 100 loans, conditional binomial, same copula
    let c = c0();
    let f = |x: f64| {
        let q = ncdf((c - rho.sqrt() * x) / (1.0 - rho).sqrt());
        let (mut pr, mut tot) = ((1.0 - q).powi(100), 0.0);
        for n in 0..=100 { tot += pr * (n as f64 * G / 100.0).min(k); pr *= (100 - n) as f64 / (n + 1) as f64 * q / (1.0 - q); }
        tot * npdf(x)
    };
    simpson(&f, -9.0, 9.0, 800)
}
fn out(label: &str, v: f64) { println!("{:<40} {:>12.6}", label, v); }
fn row(label: &str, v: &[f64], dec: usize) {
    let s: Vec<String> = v.iter().map(|x| format!("{:6.*}", dec, x)).collect();
    println!("{}{}", label, s.join(" "));
}

fn main() {
    println!("threshold c = N^-1(p)                    {:>12.6}", c0());
    out("road 1 factor integral, 3-7% at 20%", m(0.03, 0.07, 0.2));
    out("road 2 Plackett, 3-7% at 20%", (f2(0.07, 0.2) - f2(0.03, 0.2)) / 0.04);
    out("road 1 equity 0-3% at 20%", f1(0.03, 0.2) / 0.03); out("road 2 equity 0-3% at 20%", f2(0.03, 0.2) / 0.03);
    out("b_A = N^-1(3% / g)", ninv(0.03 / G)); out("b_B = N^-1(7% / g)", ninv(0.07 / G));
    out("100 loans, equity 0-3% at 20%", pool100(0.03, 0.2) / 0.03);
    out("100 loans, 3-7% at 20%", (pool100(0.07, 0.2) - pool100(0.03, 0.2)) / 0.04);
    let fd = (f1(0.07, 0.3 + 1e-5) - f1(0.07, 0.3 - 1e-5)) / 2e-5;
    out("slope dF/drho at 7%, 30%, formula", df(0.07, 0.3)); out("slope dF/drho at 7%, 30%, bumped", fd);
    let rs = peak_rho(0.03, 0.07).unwrap();
    let rg = golden_max(&|r| m(0.03, 0.07, r), 0.01, 0.99);
    out("peak rho*, closed form", rs); out("peak rho*, golden section", rg); out("peak 3-7% loss", m(0.03, 0.07, rs));
    let grid: Vec<f64> = (0..10).map(|i| i as f64 / 10.0).collect();
    row("chart, correlation %  ", &grid.iter().map(|r| 100.0 * r).collect::<Vec<_>>(), 0);
    row("chart, 3-7% loss %    ", &grid.iter().map(|&r| 100.0 * m(0.03, 0.07, r)).collect::<Vec<_>>(), 2);
    row("chart, 0-3% loss %    ", &grid.iter().map(|&r| 100.0 * f1(0.03, r) / 0.03).collect::<Vec<_>>(), 2);
    row("chart, quote lines %  ", &[19.5, 21.0], 2);
    let cases = [("0-3% quote 62.80%", 0.0, 0.03, 0.628), ("3-7% quote = model at 20%", 0.03, 0.07, m(0.03, 0.07, 0.2)),
        ("3-7% quote 19.50%", 0.03, 0.07, 0.195), ("3-7% quote 19.60%", 0.03, 0.07, 0.196), ("3-7% quote 21.00%", 0.03, 0.07, 0.21)];
    let mut roots = Vec::new();
    for (label, a, b, q) in cases {
        let r = compound(a, b, q);
        let s: Vec<String> = r.iter().map(|(x, y)| format!("{:.6}/{:.6}", x, y)).collect();
        println!("{:<27} roots: {}", label, if s.is_empty() { "none".to_string() } else { s.join(", ") });
        roots.push((label, r));
    }
    let naive = bisect(&|r| m(0.03, 0.07, r) - 0.195, 0.0, 1.0);
    out("wrong: one bracket 0..1 for 19.50%", naive); out("  its 3-7% loss", m(0.03, 0.07, naive));
    let ks = [0.0, 0.03, 0.07, 0.10, 0.15];
    let seeds = [0.0, 0.20, 0.25, 0.30, 0.40];
    let mut cum = [0.0; 5];
    for i in 1..5 { cum[i] = f1(ks[i], seeds[i]); }
    for i in 1..5 {
        let (a, b) = (ks[i - 1], ks[i]);
        let q = (cum[i] - cum[i - 1]) / (b - a);
        let fb = |r: f64| f1(b, r) - cum[i];
        let (bb, bn) = (bisect(&fb, 1e-9, 1.0 - 1e-9), newton(&fb, &|r| df(b, r), 1e-6, 1.0 - 1e-6));
        let cr: Vec<String> = compound(a, b, q).iter().map(|(x, _)| format!("{:.4}", x)).collect();
        println!("{:<7} quote {:7.4}%  cum {:.6}  base {:.6}/{:.6}  compound {}",
            format!("{:.0}-{:.0}%", 100.0 * a, 100.0 * b), 100.0 * q, cum[i], bb, bn, cr.join(", "));
        assert!((bb - seeds[i]).abs() < 1e-8, "bisection bootstrap must return the correlation behind each quote");
        assert!((bn - seeds[i]).abs() < 1e-8, "Newton bootstrap must return the correlation behind each quote");
        assert!(0.0 <= cum[i] - cum[i - 1] && cum[i] - cum[i - 1] <= b - a, "cumulative losses must rise, by no more than the width");
    }
    let b5 = 0.20 + (0.05 - 0.03) / (0.07 - 0.03) * (0.25 - 0.20);
    out("base correlation at 5%, interpolated", b5); out("first loss 0-5% at that correlation", f1(0.05, b5));
    out("5-10% by base correlation", (f1(0.10, 0.30) - f1(0.05, b5)) / 0.05);
    out("wrong: 5-10% at flat 20%", m(0.05, 0.10, 0.20));
    out("wrong: 5-10% at flat 30%", m(0.05, 0.10, 0.30));
    out("5-7% by base correlation", (f1(0.07, 0.25) - f1(0.05, b5)) / 0.02);
    for rho in [0.1, 0.2, 0.5, 0.9] {
        assert!((f1(0.07, rho) - f2(0.07, rho)).abs() < 1e-9, "factor integral vs Plackett bivariate normal");
    }
    assert!((fd - df(0.07, 0.3)).abs() < 1e-6, "analytic slope vs bumped slope");
    assert!((rs - rg).abs() < 1e-5, "closed-form peak vs numerical maximum");
    for (label, r) in &roots {
        for (x, y) in r { assert!((x - y).abs() < 1e-8, "bisection vs Newton on each branch: {}", label); }
    }
    assert!(roots[4].1.is_empty(), "no correlation reprices 21%");
    assert!(m(0.03, 0.07, rg) < 0.21, "21% lies above the numerically found hump");
    assert!((roots[1].1[0].0 - 0.2).abs() < 1e-8, "the left root recovers the 20% that made the quote");
    assert!(pool100(0.03, 0.2) < f1(0.03, 0.2), "lumpy losses: 100 loans give the equity less loss (Jensen)");
    assert!((pool100(G, 0.2) - G * P).abs() < 1e-9, "100 loans keep the pool's mean loss g p");
    println!("ALL CHECKS PASS");
}
