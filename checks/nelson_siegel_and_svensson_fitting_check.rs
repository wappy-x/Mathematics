// Nelson-Siegel and Svensson fitted to twelve bond prices -- the same check in Rust, std only.
// Gaussian elimination, Gauss-Newton, Nelder-Mead, Simpson's rule and bisection are written out.
const BONDS: [(u32, f64); 12] = [(1, 2.00), (2, 2.50), (3, 3.00), (4, 3.25), (5, 3.50), (7, 3.75),
    (10, 4.00), (12, 4.00), (15, 4.25), (20, 4.25), (25, 4.50), (30, 4.50)];
const TRUE: [f64; 6] = [0.035, -0.025, 0.040, 0.025, 2.0, 7.0];

fn l(x: f64) -> f64 { (1.0 - (-x).exp()) / x }                 // slope loading of the zero rate
fn h(x: f64) -> f64 { l(x) - (-x).exp() }                        // hump loading of the zero rate
fn tau1(p: &[f64]) -> f64 { if p.len() == 6 { p[4] } else { p[3] } }
fn zero(t: f64, p: &[f64]) -> f64 {
    let z = p[0] + p[1] * l(t / tau1(p)) + p[2] * h(t / tau1(p));
    if p.len() == 6 { z + p[3] * h(t / p[5]) } else { z }
}
fn fwd(t: f64, p: &[f64]) -> f64 {
    let a = t / tau1(p);
    let f = p[0] + p[1] * (-a).exp() + p[2] * a * (-a).exp();
    if p.len() == 6 { f + p[3] * (t / p[5]) * (-t / p[5]).exp() } else { f }
}
fn flows(n: u32, c: f64) -> Vec<(f64, f64)> { (1..=n).map(|k| (k as f64, c + if k == n { 100.0 } else { 0.0 })).collect() }
fn price_with(n: u32, c: f64, p: &[f64], rate: fn(f64, &[f64]) -> f64) -> f64 {
    flows(n, c).iter().map(|&(t, cf)| cf * (-t * rate(t, p)).exp()).sum()
}
fn price(n: u32, c: f64, p: &[f64]) -> f64 { price_with(n, c, p, zero) }
fn sse(p: &[f64], mkt: &[f64]) -> f64 { BONDS.iter().zip(mkt).map(|(&(n, c), m)| (price(n, c, p) - m).powi(2)).sum() }

fn solve(a: Vec<Vec<f64>>, b: Vec<f64>) -> Vec<f64> {          // Gaussian elimination with pivoting
    let n = b.len();
    let mut m: Vec<Vec<f64>> = a.into_iter().zip(b).map(|(mut r, v)| { r.push(v); r }).collect();
    for k in 0..n {
        let piv = (k..n).max_by(|&i, &j| m[i][k].abs().total_cmp(&m[j][k].abs())).unwrap(); m.swap(k, piv);
        for i in k + 1..n {
            let f = m[i][k] / m[k][k];
            for j in k..=n { m[i][j] -= f * m[k][j]; }
        }
    }
    let mut x = vec![0.0; n];
    for i in (0..n).rev() { x[i] = (m[i][n] - (i + 1..n).map(|j| m[i][j] * x[j]).sum::<f64>()) / m[i][i]; }
    x
}
fn gram(rows: &[Vec<f64>], y: &[f64]) -> (Vec<Vec<f64>>, Vec<f64>) {
    (rows.iter().map(|u| rows.iter().map(|v| u.iter().zip(v).map(|(a, b)| a * b).sum()).collect()).collect(),
     rows.iter().map(|u| u.iter().zip(y).map(|(a, b)| a * b).sum()).collect())
}
fn gn(p0: &[f64], free: &[usize], mkt: &[f64]) -> Vec<f64> {    // road 1: Gauss-Newton on the free parameters
    let mut p = p0.to_vec();
    for _ in 0..40 {
        let jac: Vec<Vec<f64>> = free.iter().map(|&j| {
            let (mut up, mut dn) = (p.clone(), p.clone()); up[j] += 1e-6; dn[j] -= 1e-6;
            BONDS.iter().map(|&(n, c)| (price(n, c, &up) - price(n, c, &dn)) / 2e-6).collect()
        }).collect();
        let r: Vec<f64> = BONDS.iter().zip(mkt).map(|(&(n, c), m)| m - price(n, c, &p)).collect();
        let (a, b) = gram(&jac, &r); let step = solve(a, b);
        let moved = |hh: f64| { let mut q = p.clone(); for (&j, s) in free.iter().zip(&step) { q[j] += hh * s; } q };
        let (old, mut hh) = (sse(&p, mkt), 1.0);
        while sse(&moved(hh), mkt) > old && hh > 1e-6 { hh /= 2.0; }
        p = moved(hh);
        if step.iter().fold(0.0_f64, |a, s| a.max(s.abs())) < 1e-12 { break; }
    }
    p
}
fn ns_fit(mkt: &[f64]) -> Vec<f64> {                            // grid on tau with the betas solved, then all four
    let start = (1..=40).map(|i| gn(&[0.04, 0.0, 0.0, 0.25 * i as f64], &[0, 1, 2], mkt))
        .min_by(|a, b| sse(a, mkt).total_cmp(&sse(b, mkt))).unwrap();
    gn(&start, &[0, 1, 2, 3], mkt)
}
fn nelder_mead(f: &dyn Fn(&[f64]) -> f64, x0: &[f64], steps0: &[f64]) -> Vec<f64> {   // road 2: no derivatives
    let n = x0.len();
    let (mut best, mut steps) = (x0.to_vec(), steps0.to_vec());
    for _ in 0..12 {
        let mut s: Vec<(f64, Vec<f64>)> = (0..=n).map(|i| {
            let mut v = best.clone(); if i > 0 { v[i - 1] += steps[i - 1]; } (f(&v), v)
        }).collect();
        s.sort_by(|a, b| a.0.total_cmp(&b.0));
        for _ in 0..800 {
            let c: Vec<f64> = (0..n).map(|j| s[..n].iter().map(|z| z.1[j]).sum::<f64>() / n as f64).collect();
            let pt = |k: f64, w: &[f64]| -> Vec<f64> { (0..n).map(|j| c[j] + k * (w[j] - c[j])).collect() };
            let worst = s[n].1.clone();
            let r = pt(-1.0, &worst); let fr = f(&r);
            if fr < s[0].0 {
                let e = pt(-2.0, &worst); let fe = f(&e); s[n] = if fe < fr { (fe, e) } else { (fr, r) };
            } else if fr < s[n - 1].0 { s[n] = (fr, r); } else {
                let k = pt(0.5, &worst); let fk = f(&k);
                if fk < s[n].0 { s[n] = (fk, k); } else {
                    let b0 = s[0].1.clone();
                    for z in s.iter_mut().skip(1) {
                        let w: Vec<f64> = (0..n).map(|j| b0[j] + 0.5 * (z.1[j] - b0[j])).collect();
                        *z = (f(&w), w);
                    }
                }
            }
            s.sort_by(|a, b| a.0.total_cmp(&b.0));
        }
        best = s[0].1.clone(); for st in steps.iter_mut() { *st *= 0.3; }
    }
    best
}
fn simpson(g: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 {
    let hh = (b - a) / n as f64;
    (g(a) + g(b) + (1..n).map(|i| if i % 2 == 1 { 4.0 } else { 2.0 } * g(a + i as f64 * hh)).sum::<f64>()) * hh / 3.0
}
fn ytm(n: u32, c: f64, m: f64) -> f64 {                          // bisection: one flat rate that reprices the bond
    let (mut lo, mut hi) = (-0.05_f64, 0.20_f64);
    for _ in 0..200 { let mid = (lo + hi) / 2.0;
        if flows(n, c).iter().map(|&(t, cf)| cf * (-t * mid).exp()).sum::<f64>() > m { lo = mid } else { hi = mid } }
    (lo + hi) / 2.0
}
fn fmt(p: &[f64]) -> String {
    let (k, j) = (p.len() / 2 + 1, |v: Vec<String>| v.join(" "));
    format!("{} | {}", j(p[..k].iter().map(|x| format!("{:.4}", 100.0 * x)).collect()), j(p[k..].iter().map(|x| format!("{:.4}", x)).collect()))
}
fn main() {
    let mkt: Vec<f64> = BONDS.iter().map(|&(n, c)| (price(n, c, &TRUE) * 100.0).round() / 100.0).collect();
    let ns1 = ns_fit(&mkt);
    let mut best = (f64::INFINITY, vec![]);
    for i in 1..=10 { for j in 4..=30 { if j > i + 1 {
        let q = gn(&[0.04, 0.0, 0.0, 0.0, 0.5 * i as f64, 0.5 * j as f64], &[0, 1, 2, 3], &mkt);
        let v = sse(&q, &mkt); if v < best.0 { best = (v, q); }
    } } }
    let sv1 = gn(&best.1, &[0, 1, 2, 3, 4, 5], &mkt);
    let safe = |p: &[f64]| if p[3..].iter().skip(if p.len() == 6 { 1 } else { 0 }).all(|&t| t > 0.05) { sse(p, &mkt) } else { 1e9 };
    let ns2 = nelder_mead(&safe, &[0.04, -0.02, 0.0, 1.0], &[0.01, 0.01, 0.01, 0.5]);
    let sv2 = nelder_mead(&safe, &[0.04, -0.02, 0.0, 0.0, 1.0, 5.0], &[0.01, 0.01, 0.01, 0.01, 0.5, 2.0]);
    println!("fit             betas (% a year)                    | taus (years)");
    for (lab, p) in [("NS road 1", &ns1), ("NS road 2", &ns2), ("SV road 1", &sv1), ("SV road 2", &sv2), ("SV truth", &TRUE.to_vec())] {
        println!("{:<15} {}", lab, fmt(p));
    }
    let rms = |p: &[f64]| (sse(p, &mkt) / 12.0).sqrt();
    println!("score: NS {:.6}  SV {:.6}  (dollars squared); rms miss NS {:.3}c SV {:.3}c", sse(&ns1, &mkt), sse(&sv1, &mkt), 100.0 * rms(&ns1), 100.0 * rms(&sv1));
    println!("bond  coupon  market  NS miss, cents  SV miss, cents  yield %  NS zero %  SV zero %");
    for (&(n, c), &m) in BONDS.iter().zip(&mkt) {
        println!("{:>4} {:7.2} {:8.2} {:+15.2} {:+15.2} {:8.2} {:10.2} {:10.2}", n, c, m, 100.0 * (price(n, c, &ns1) - m),
            100.0 * (price(n, c, &sv1) - m), 100.0 * ytm(n, c, m), 100.0 * zero(n as f64, &ns1), 100.0 * zero(n as f64, &sv1));
    }
    let (b0, b1, t1) = (ns1[0], ns1[1], ns1[3]);
    println!("read NS: long level b0 {:.4}%, zero at 10000y {:.4}%; short end b0+b1 {:.4}%, zero at 0.001y {:.4}%",
        100.0 * b0, 100.0 * zero(10000.0, &ns1), 100.0 * (b0 + b1), 100.0 * zero(0.001, &ns1));
    let xp = (1..=500000).map(|i| i as f64 * 1e-5).fold((0.0, f64::MIN), |a, x| if h(x) > a.1 { (x, h(x)) } else { a }).0;
    println!("read NS: slope long minus short = -b1 = {:.4}%; zero-rate hump peaks at x = {:.4}, t = {:.4}y", -100.0 * b1, xp, xp * t1);
    println!("read SV: long level b0 {:.4}%, short end b0+b1 {:.4}%; truth {:.4}% and {:.4}%", 100.0 * sv1[0], 100.0 * (sv1[0] + sv1[1]), 100.0 * TRUE[0], 100.0 * (TRUE[0] + TRUE[1]));
    let row = |g: &dyn Fn(f64) -> String| BONDS.iter().map(|&(n, _)| g(n as f64)).collect::<Vec<_>>().join(" ");
    println!("loadings at NS tau, years: {}", row(&|n| format!("{}", n)));
    println!("  slope L {}", row(&|n| format!("{:.2}", l(n / t1))));
    println!("  hump  H {}", row(&|n| format!("{:.2}", h(n / t1))));
    let ci = simpson(&|s| fwd(s, &sv1), 0.0, 10.0, 2000) / 10.0;
    println!("SV 10y zero: closed form {:.8}%  integral of forward / 10 {:.8}%", 100.0 * zero(10.0, &sv1), 100.0 * ci);
    let parts: Vec<String> = flows(3, 3.0).iter().map(|&(t, _)| format!("t={} L={:.4} H={:.4} R={:.4}% D={:.6}", t, l(t / t1), h(t / t1), 100.0 * zero(t, &ns1), (-t * zero(t, &ns1)).exp())).collect();
    println!("3y bond by hand: {}  price {:.4}", parts.join("  "), price(3, 3.0, &ns1));
    let yl: Vec<f64> = BONDS.iter().zip(&mkt).map(|(&(n, c), &m)| ytm(n, c, m)).collect();
    let cols: Vec<Vec<f64>> = vec![vec![1.0; 12], BONDS.iter().map(|&(n, _)| l(n as f64 / t1)).collect(), BONDS.iter().map(|&(n, _)| h(n as f64 / t1)).collect()];
    let (a, b) = gram(&cols, &yl);
    let mut lin = solve(a, b); lin.push(t1);
    let worst = BONDS.iter().zip(&mkt).map(|(&(n, c), m)| (price(n, c, &lin) - m).abs()).fold(0.0_f64, f64::max);
    println!("wrong: yields fitted as zero rates (same tau): betas {:.4} {:.4} {:.4}; worst price miss {:.4}", 100.0 * lin[0], 100.0 * lin[1], 100.0 * lin[2], worst);
    println!("wrong: forward used as zero rate, 30y bond: {:.4} vs NS {:.4}", price_with(30, 4.5, &ns1, fwd), price(30, 4.5, &ns1));
    let dl = gn(&[0.04, 0.0, 0.0, 1.0 / (12.0 * 0.0609)], &[0, 1, 2], &mkt);
    println!("wrong: tau fixed at 1.3684y: betas {:.4} {:.4} {:.4} score {:.6}", 100.0 * dl[0], 100.0 * dl[1], 100.0 * dl[2], sse(&dl, &mkt));
    let m2: Vec<f64> = BONDS.iter().map(|&(n, c)| (price(n, c, &[0.035, -0.025, 0.040, 2.0]) * 100.0).round() / 100.0).collect();
    let t2 = ns_fit(&m2);
    println!("try: prices from a four-parameter curve: NS fit {}; score {:.6}", fmt(&t2), sse(&t2, &m2));
    let m3: Vec<f64> = BONDS.iter().map(|&(n, c)| price(n, c, &TRUE)).collect();
    println!("try: prices not rounded: SV fit {}", fmt(&gn(&sv1, &[0, 1, 2, 3, 4, 5], &m3)));
    let m4: Vec<f64> = BONDS.iter().zip(&mkt).map(|(&(n, _), &m)| m + if n == 10 { 0.10 } else { 0.0 }).collect();
    println!("try: 10y bond 10 cents dearer: NS fit {}", fmt(&gn(&ns1, &[0, 1, 2, 3], &m4)));
    assert!(ns1.iter().zip(&ns2).all(|(a, b)| (a - b).abs() < 1e-6), "NS: road 1 and road 2 must land on the same fit");
    assert!(sv1.iter().zip(&sv2).all(|(a, b)| (a - b).abs() < 1e-5), "SV: road 1 and road 2 must land on the same fit");
    assert!(sse(&sv1, &mkt) <= sse(&ns1, &mkt), "Svensson contains Nelson-Siegel, so it cannot fit worse");
    assert!((zero(10.0, &sv1) - ci).abs() < 1e-10, "zero rate must equal the average of the forward");
    assert!(sv1[..4].iter().zip(&TRUE[..4]).all(|(a, b)| (a - b).abs() < 2e-4), "SV betas must recover the curve the prices came from");
    println!("ALL CHECKS PASS");
}
