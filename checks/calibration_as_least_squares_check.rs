// Calibration as least squares -- the same check as calibration_as_least_squares_check.py,
// in Rust.  Standard library only, no crates.  Rust has no erf, so the bell-curve area is
// built the honest way: thin slices added up under the curve (Simpson).  The
// Levenberg-Marquardt loop and the derivative-free grid road are written out here too.
use std::f64::consts::PI;
const S: f64 = 100.0;  const R: f64 = 0.05;  const T: f64 = 1.0;   // spot, bank rate, one year
const KS: [f64; 5] = [80.0, 90.0, 100.0, 110.0, 120.0];   // the five quoted strikes
const SMILE: [f64; 5] = [0.22, 0.21, 0.20, 0.19, 0.185];  // vol the market charges
const START: [f64; 2] = [0.30, 0.05];
const BOX: [[f64; 2]; 2] = [[0.05, 0.60], [-0.05, 0.12]];
const FAR: [f64; 2] = [0.70, 0.10];               // a deliberately bad starting guess
fn dens(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }   // bell-curve height
fn ncdf(x: f64) -> f64 {                          // bell-curve area left of x, by Simpson
    if x < -12.0 { return 0.0; }
    if x > 12.0 { return 1.0; }
    let (n, h) = (4096usize, x / 4096.0);
    let mut s = dens(0.0) + dens(x);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * dens(i as f64 * h); }
    0.5 + s * h / 3.0
}
fn call(k: f64, sig: f64, q: f64) -> f64 {        // Black-Scholes call at one strike
    let v = sig * T.sqrt();
    let d1 = ((S / k).ln() + (R - q + 0.5 * sig * sig) * T) / v;
    S * (-q * T).exp() * ncdf(d1) - k * (-R * T).exp() * ncdf(d1 - v)
}
fn slopes(k: f64, sig: f64, q: f64) -> (f64, f64) {   // dC/dsigma (vega) and dC/dq
    let v = sig * T.sqrt();
    let d1 = ((S / k).ln() + (R - q + 0.5 * sig * sig) * T) / v;
    (S * (-q * T).exp() * dens(d1) * T.sqrt(), -S * T * (-q * T).exp() * ncdf(d1))
}
fn loss(ks: &[f64], x: [f64; 2], y: &[f64], s: &[f64]) -> f64 {   // half the scaled squares
    0.5 * (0..ks.len()).map(|i| { let z = (call(ks[i], x[0], x[1]) - y[i]) / s[i]; z * z }).sum::<f64>()
}
fn normal(ks: &[f64], x: [f64; 2], y: &[f64], s: &[f64]) -> ([f64; 3], [f64; 2]) {
    let (mut a, mut g) = ([0.0; 3], [0.0; 2]);    // J'J (three entries) and the gradient J'e
    for i in 0..ks.len() {
        let miss = (call(ks[i], x[0], x[1]) - y[i]) / s[i];
        let (j0, j1) = slopes(ks[i], x[0], x[1]);
        let (j0, j1) = (j0 / s[i], j1 / s[i]);
        a[0] += j0 * j0; a[1] += j0 * j1; a[2] += j1 * j1;
        g[0] += j0 * miss; g[1] += j1 * miss;
    }
    (a, g)
}
fn step(a: [f64; 3], g: [f64; 2], lam: f64, scaled: bool) -> (Option<[f64; 2]>, f64) {
    let b0 = a[0] + lam * if scaled { a[0] } else { 1.0 };   // (J'J + damping) d = -J'e
    let b2 = a[2] + lam * if scaled { a[2] } else { 1.0 };
    let det = b0 * b2 - a[1] * a[1];
    if det <= 0.0 { return (None, det); }
    (Some([(-b2 * g[0] + a[1] * g[1]) / det, (a[1] * g[0] - b0 * g[1]) / det]), det)
}
fn fit(ks: &[f64], y: &[f64], s: &[f64], start: [f64; 2]) -> ([f64; 2], f64, usize, &'static str) {
    let (mut x, mut f, mut taken, mut lam) = (start, loss(ks, start, y, s), 0usize, 1e-3);
    for _ in 0..200 {                             // road one: Levenberg-Marquardt
        let (a, g) = normal(ks, x, y, s);
        let mut moved = false;
        for _ in 0..60 {
            if let (Some(d), _) = step(a, g, lam, true) { if x[0] + d[0] > 0.0 {
                let trial = [x[0] + d[0], x[1] + d[1]];
                let ft = loss(ks, trial, y, s);
                if ft < f {
                    let gain = f - ft;
                    (x, f, taken) = (trial, ft, taken + 1);
                    lam = (lam / 3.0).max(1e-14); // step taken: trust the slope more
                    if gain <= 1e-8 * (1.0 + f) { return (x, f, taken, "loss settled"); }
                    moved = true; break;
                }
            }}
            lam *= 3.0;                           // step refused: trust the slope less
        }
        if !moved { return (x, f, taken, "no better step"); }
    }
    (x, f, taken, "step cap")
}
fn shrink(ks: &[f64], y: &[f64], s: &[f64], bx: [[f64; 2]; 2]) -> ([f64; 2], f64) {
    let n = 6usize;                               // road two: shrink a grid, no derivatives
    let (mut lo, mut hi, mut lo2, mut hi2) = (bx[0][0], bx[0][1], bx[1][0], bx[1][1]);
    let mut best = [0.5 * (lo + hi), 0.5 * (lo2 + hi2)];
    for _ in 0..30 {
        let mut bf = f64::INFINITY;
        for i in 0..=n { for j in 0..=n {
            let p = [lo + (hi - lo) * i as f64 / n as f64, lo2 + (hi2 - lo2) * j as f64 / n as f64];
            let fp = loss(ks, p, y, s);
            if fp < bf { (bf, best) = (fp, p); }
        }}
        let (w, w2) = ((hi - lo) / n as f64, (hi2 - lo2) / n as f64);
        (lo, hi) = ((best[0] - w).max(1e-4), best[0] + w);
        (lo2, hi2) = (best[1] - w2, best[1] + w2);
    }
    (best, loss(ks, best, y, s))
}
fn q_repricing(sig: f64, target: f64) -> f64 {    // bisection: the price falls as q rises
    let (mut lo, mut hi) = (-0.40, 0.40);
    for _ in 0..100 {
        let mid = 0.5 * (lo + hi);  if call(100.0, sig, mid) > target { lo = mid } else { hi = mid }
    }
    0.5 * (lo + hi)
}
fn wide(name: &str, values: &[f64], dp: usize) {
    let mut line = format!("{:<30}", name);
    for v in values { line.push_str(&format!("{:>10.*}", dp, v)); }
    println!("{}", line);
}
fn report(name: &str, x: [f64; 2], f: f64, extra: &str) {
    println!("{:<30}sigma {:.6}   q {:.6}   loss {:.8}{}", name, x[0], x[1], f, extra);
}
fn main() {
    let qa: Vec<f64> = KS.iter().map(|&k| call(k, 0.20, 0.02)).collect();      // set A
    let qb: Vec<f64> = (0..5).map(|i| call(KS[i], SMILE[i], 0.02)).collect();  // set B
    let (vega, ones): (Vec<f64>, Vec<f64>) = (KS.iter().map(|&k| slopes(k, 0.20, 0.02).0).collect(), vec![1.0; 5]);
    println!("five one-year Acme calls: spot {:.2}, bank rate {:.2}%, strikes 80 to 120; every fit starts at sigma {:.2}, q {:.2}", S, R * 100.0, START[0], START[1]);
    wide("strike", &KS, 0);
    wide("set A quote, one vol", &qa, 6);
    wide("set B quote, market smile", &qb, 6);
    wide("set B vol, strike by strike", &SMILE, 6);
    wide("vega scale, $ per 1.00 vol", &vega, 6);
    let mut found: Vec<([f64; 2], [f64; 2])> = Vec::new();
    for (label, y, s) in [("A, dollar scales", &qa, &ones), ("B, dollar scales", &qb, &ones), ("B, vega scales", &qb, &vega)] {
        let (x, f, n, stop) = fit(&KS, y, s, START);                 // road one
        let (g, fg) = shrink(&KS, y, s, BOX);                        // road two
        report(&format!("fit {}", label), x, f, &format!("   steps {}   stop: {}", n, stop));
        report(&format!("fit {}, grid", label), g, fg, "");
        found.push((x, g));
    }
    let (xa, xb, xv, gb, gv) = (found[0].0, found[1].0, found[2].0, found[1].1, found[2].1);
    let miss_b: Vec<f64> = (0..5).map(|i| call(KS[i], xb[0], xb[1]) - qb[i]).collect();
    let miss_v: Vec<f64> = (0..5).map(|i| call(KS[i], xv[0], xv[1]) - qb[i]).collect();
    wide("dollar fit misses, dollars", &miss_b, 6);
    wide("dollar fit misses, vol pts", &(0..5).map(|i| 100.0 * miss_b[i] / vega[i]).collect::<Vec<f64>>(), 6);
    wide("vega fit misses, vol pts", &(0..5).map(|i| 100.0 * miss_v[i] / vega[i]).collect::<Vec<f64>>(), 6);
    let g0 = normal(&KS, START, &qb, &ones).1;
    let bump: Vec<f64> = (0..2).map(|k| {         // the same gradient, by bumping the loss
        let (mut p, mut m) = (START, START);
        p[k] += 1e-5; m[k] -= 1e-5;
        (loss(&KS, p, &qb, &ones) - loss(&KS, m, &qb, &ones)) / 2e-5 }).collect();
    println!("gradient at the start, from the Jacobian {:+.4} {:+.4}, by bumping the loss {:+.4} {:+.4}", g0[0], g0[1], bump[0], bump[1]);
    let (ab, a1) = (normal(&KS, xb, &qb, &ones).0, normal(&[100.0], [0.20, 0.02], &[qa[2]], &[1.0]).0);
    let dq = -S * T * (-0.02 * T).exp();          // a zero-strike ticket has no vega at all
    let tick = [0.0, 0.0, 5.0 * dq * dq];         // so J'J for five of them is this
    println!("det(J'J): five strikes {:.3}, one strike {:.6}, five zero-strike tickets {:.6}", ab[0] * ab[2] - ab[1] * ab[1], a1[0] * a1[2] - a1[1] * a1[1], tick[0] * tick[2]);
    let ((lev, dlev), dmar) = (step(tick, [0.0, 1.0], 0.01, false), step(tick, [0.0, 1.0], 0.01, true).1);
    println!("tickets, damped step: Levenberg moves sigma by {:.6}, determinant {:.6}; Marquardt's determinant is {:.6}, so it has no step to take", lev.unwrap()[0], dlev, dmar);
    let valley: Vec<[f64; 2]> = [0.18, 0.19, 0.20, 0.21, 0.22].iter().map(|&sg| [sg, q_repricing(sg, qa[2])]).collect();
    wide("valley, sigma", &valley.iter().map(|v| v[0]).collect::<Vec<f64>>(), 6);
    wide("valley, q repricing quote 3", &valley.iter().map(|v| v[1]).collect::<Vec<f64>>(), 6);
    let ((x1, f1, n1, _), (x2, f2, n2, _)) = (fit(&[100.0], &[qa[2]], &[1.0], [0.16, 0.00]), fit(&[100.0], &[qa[2]], &[1.0], [0.26, 0.05]));
    report("one quote from sigma 0.16", x1, f1, &format!("   steps {}", n1));
    report("one quote from sigma 0.26", x2, f2, &format!("   steps {}", n2));
    let (pin, fpin) = shrink(&KS, &qb, &ones, [[0.05, 0.60], [0.0, 0.0]]);
    report("mistake, q pinned at zero", pin, fpin, "");
    let gn = { let (af, gf) = normal(&KS, FAR, &qb, &ones); step(af, gf, 0.0, true).0.unwrap() };
    let (xf, ff, nf, _) = fit(&KS, &qb, &ones, FAR);
    println!("from sigma {:.2}, q {:.2}: one undamped step gives sigma {:.6}, a volatility below zero; damped, sigma {:.6} and loss {:.8} in {} steps", FAR[0], FAR[1], FAR[0] + gn[0], xf[0], ff, nf);
    for (label, vals) in [("chart, market vol percent", SMILE.iter().map(|v| 100.0 * v).collect::<Vec<f64>>()),
                          ("chart, fitted flat vol", vec![100.0 * xv[0]; 5]), ("chart, vega scale dollars", vega.clone()),
                          ("chart, valley sigma percent", valley.iter().map(|v| 100.0 * v[0]).collect()),
                          ("chart, valley q percent", valley.iter().map(|v| 100.0 * v[1]).collect()), ("chart, dividend used", vec![2.0; 5])] {
        wide(label, &vals, 2);
    }
    assert!((qa[2] - 9.227005508154).abs() < 1e-9);        // quote 3 is the house call price
    assert!((xa[0] - 0.20).abs() < 1e-9 && (xa[1] - 0.02).abs() < 1e-9);   // set A recovered
    assert!((xb[0] - gb[0]).abs() < 1e-7 && (xb[1] - gb[1]).abs() < 1e-7); // two roads, one fit
    assert!((xv[0] - gv[0]).abs() < 1e-7 && (xv[1] - gv[1]).abs() < 1e-7);
    assert!((0..2).all(|k| (g0[k] - bump[k]).abs() < 1e-4));   // Jacobian vs bumped loss
    assert!(valley.iter().all(|v| (call(100.0, v[0], v[1]) - qa[2]).abs() < 1e-10));
    assert!(loss(&KS, xv, &qb, &vega) < loss(&KS, xb, &qb, &vega));   // weights move the answer
    assert!((xf[0] - xb[0]).abs() < 1e-7 && FAR[0] + gn[0] < 0.0);    // damping saves a bad start
    println!("ALL CHECKS PASS");
}
