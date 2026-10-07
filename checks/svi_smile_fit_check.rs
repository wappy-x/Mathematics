// SVI smile fit -- the check behind the card.  Rust std only.  Card 1's crash market quotes
// seven one-year strikes; SVI is fitted by two roads, then tested for butterfly arbitrage and Lee's bound.
use std::f64::consts::PI;
const S: f64 = 100.0; const R: f64 = 0.05; const Q: f64 = 0.02; const T: f64 = 1.0;
type P = [f64; 5];

fn n_cdf(x: f64) -> f64 { // normal CDF from its own series, as on card 1
    if x.abs() > 9.0 { return if x > 0.0 { 1.0 } else { 0.0 }; }
    let y = x.abs() / 2f64.sqrt(); let (mut term, mut s, mut n) = (y, y, 0.0);
    while term > 1e-17 * s { n += 1.0; term *= 2.0 * y * y / (2.0 * n + 1.0); s += term; }
    let e = 2.0 / PI.sqrt() * (-y * y).exp() * s;
    if x >= 0.0 { 0.5 * (1.0 + e) } else { 0.5 * (1.0 - e) }
}
fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }
fn fwd() -> f64 { S * ((R - Q) * T).exp() }
fn disc() -> f64 { (-R * T).exp() }
fn mixl() -> [(f64, f64, f64); 2] { let f = fwd(); [(0.12, 0.70 * f, 0.40), (0.88, (f - 0.12 * 0.70 * f) / 0.88, 0.15)] }
fn b76(f: f64, k: f64, v: f64) -> f64 { // call on forward f, total standard deviation v
    let d1 = ((f / k).ln() + 0.5 * v * v) / v;
    disc() * (f * n_cdf(d1) - k * n_cdf(d1 - v))
}
fn mix(k: f64) -> f64 { mixl().iter().map(|&(p, f, s)| p * b76(f, k, s * T.sqrt())).sum() }
fn iv(c: f64, k: f64) -> f64 { // bisection: the vol whose Black-Scholes call costs c
    let (mut lo, mut hi) = (1e-6, 3.0);
    for _ in 0..200 { let mid = 0.5 * (lo + hi); if b76(fwd(), k, mid * T.sqrt()) > c { hi = mid } else { lo = mid } }
    0.5 * (lo + hi)
}
fn svi(p: &P, k: f64) -> f64 { let [a, b, rho, m, s] = *p; a + b * (rho * (k - m) + ((k - m).powi(2) + s * s).sqrt()) }
fn sse(p: &P, ks: &[f64], ws: &[f64]) -> f64 { ks.iter().zip(ws).map(|(&k, &w)| (svi(p, k) - w).powi(2)).sum() }
fn solve(a: &Vec<Vec<f64>>, y: &[f64]) -> Vec<f64> { // Gaussian elimination with partial pivoting
    let n = y.len(); let mut m: Vec<Vec<f64>> = (0..n).map(|i| { let mut r = a[i].clone(); r.push(y[i]); r }).collect();
    for c in 0..n {
        let piv = (c..n).max_by(|&i, &j| m[i][c].abs().partial_cmp(&m[j][c].abs()).unwrap()).unwrap(); m.swap(c, piv);
        for i in c + 1..n { let f = m[i][c] / m[c][c]; for j in c..=n { m[i][j] -= f * m[c][j]; } }
    }
    let mut x = vec![0.0; n];
    for i in (0..n).rev() { x[i] = (m[i][n] - (i + 1..n).map(|j| m[i][j] * x[j]).sum::<f64>()) / m[i][i]; }
    x
}
fn dot(u: &[f64], v: &[f64]) -> f64 { u.iter().zip(v).map(|(a, b)| a * b).sum() }
fn lstsq(cols: &[Vec<f64>], y: &[f64]) -> Vec<f64> { // normal equations: (X'X) beta = X'y
    let a: Vec<Vec<f64>> = cols.iter().map(|ci| cols.iter().map(|cj| dot(ci, cj)).collect()).collect();
    let rhs: Vec<f64> = cols.iter().map(|ci| dot(ci, y)).collect();
    solve(&a, &rhs)
}
fn g(p: &P, k: f64) -> f64 { // Gatheral's g: the implied density is g times a positive factor
    let [_, b, rho, m, s] = *p; let w = svi(p, k); let rt = ((k - m).powi(2) + s * s).sqrt();
    let (w1, w2) = (b * (rho + (k - m) / rt), b * s * s / rt.powi(3));
    (1.0 - k * w1 / (2.0 * w)).powi(2) - w1 * w1 / 4.0 * (1.0 / w + 0.25) + w2 / 2.0
}
fn dens_g(p: &P, kk: f64) -> f64 { // road A: density of S_T at K from g, no option prices
    let k = (kk / fwd()).ln(); let w = svi(p, k);
    g(p, k) * phi(-k / w.sqrt() - w.sqrt() / 2.0) / (w.sqrt() * kk)
}
fn dens_fd(p: &P, kk: f64) -> f64 { // road B: e^rT times the second difference of call prices
    let h = 0.01; let c = |x: f64| b76(fwd(), x, svi(p, (x / fwd()).ln()).sqrt());
    (c(kk + h) - 2.0 * c(kk) + c(kk - h)) / (h * h) / disc()
}
fn gmin(p: &P) -> (f64, f64) {
    (0..3001).map(|i| { let k = -1.5 + 0.001 * i as f64; (g(p, k), k) }).fold((f64::MAX, 0.0), |b, x| if x.0 < b.0 { x } else { b })
}
fn line(v: &[f64], w: usize, d: usize) -> String { v.iter().map(|x| format!("{:w$.d$}", x, w = w, d = d)).collect::<Vec<_>>().join(" ") }

fn main() {
    let (f, d) = (fwd(), disc());
    let fit = [80.0, 90.0, 95.0, 100.0, 105.0, 110.0, 120.0];
    let ks: Vec<f64> = fit.iter().map(|k| (k / f).ln()).collect();
    let vols: Vec<f64> = fit.iter().map(|&k| iv(mix(k), k)).collect();
    let ws: Vec<f64> = vols.iter().map(|v| v * v * T).collect(); // total variance = vol squared times time
    // road 1: for fixed (m, s) SVI is linear in (a, b*rho, b); search (m, s) on a shrinking grid
    let inner = |m: f64, s: f64| -> P {
        let cols = vec![vec![1.0; 7], ks.iter().map(|k| k - m).collect(), ks.iter().map(|k| ((k - m).powi(2) + s * s).sqrt()).collect()];
        let x = lstsq(&cols, &ws); [x[0], x[2], x[1] / x[2], m, s]
    };
    let (mut p1, mut cm, mut cs, mut hm, mut hs) = ([0.0; 5], 0.0, 0.3, 0.5, 0.29); let mut first = true;
    for _ in 0..60 {
        for i in -5..=5 { for j in -5..=5 {
            let p = inner(cm + hm * i as f64 / 5.0, cs + hs * j as f64 / 5.0);
            if first || sse(&p, &ks, &ws) < sse(&p1, &ks, &ws) { p1 = p; first = false; }
        } }
        cm = p1[3]; cs = p1[4]; hm *= 0.6; hs *= 0.6;
    }
    // road 2: Levenberg-Marquardt on all five at once; b = e^u1, rho = tanh(u2), s = e^u4 keep them legal
    let p5 = |u: &[f64]| -> P { [u[0], u[1].exp(), u[2].tanh(), u[3], u[4].exp()] };
    let res = |u: &[f64]| -> Vec<f64> { ks.iter().zip(&ws).map(|(&k, &w)| svi(&p5(u), k) - w).collect() };
    let (mut u, mut lam) = (vec![0.03, 0.1f64.ln(), 0.0, 0.0, 0.1f64.ln()], 1e-3);
    while lam < 1e12 {
        let r = res(&u);
        let jac: Vec<Vec<f64>> = (0..5).map(|j| { let mut uu = u.clone(); uu[j] += 1e-7; res(&uu).iter().zip(&r).map(|(x, y)| (x - y) / 1e-7).collect() }).collect();
        let a: Vec<Vec<f64>> = (0..5).map(|i| (0..5).map(|j| dot(&jac[i], &jac[j]) * (1.0 + if i == j { lam } else { 0.0 })).collect()).collect();
        let step = solve(&a, &(0..5).map(|i| -dot(&jac[i], &r)).collect::<Vec<_>>());
        let un: Vec<f64> = u.iter().zip(&step).map(|(x, s)| x + s).collect();
        if dot(&res(&un), &res(&un)) < dot(&r, &r) { u = un; lam *= 0.3; } else { lam *= 10.0; }
    }
    let p2 = p5(&u);
    let [a, b, rho, m, s] = p1;
    println!("forward F, discount e^-rT        {:.6} {:.6}", f, d);
    println!("crash market, crash then calm: weight, forward/F, vol  {}", mixl().iter().map(|&(p, fl, vl)| format!("{:.2} {:.4} {:.2}", p, fl / f, vl)).collect::<Vec<_>>().join("  "));
    println!("strike      k    market vol   total var w");
    for i in 0..7 { println!("{:6.0} {:+8.4} {:10.4} {:12.6}", fit[i], ks[i], 100.0 * vols[i], ws[i]); }
    for (lab, p) in [("road 1, grid + linear", p1), ("road 2, Levenberg-Marquardt", p2)] {
        println!("{:<28} a b rho m s  {}  sse {:.3e}", lab, p.iter().map(|x| format!("{:+.6}", x)).collect::<Vec<_>>().join(" "), sse(&p, &ks, &ws));
    }
    println!("strike  market   SVI    miss (vol points)");
    let mut miss = vec![];
    for i in 0..7 {
        let sv = 100.0 * (svi(&p1, ks[i]) / T).sqrt(); miss.push(sv - 100.0 * vols[i]);
        println!("{:6.0} {:8.4} {:8.4} {:+9.4}", fit[i], 100.0 * vols[i], sv, miss[i]);
    }
    let hold: Vec<(f64, f64, f64)> = [85.0, 115.0].iter().map(|&k| (k, 100.0 * iv(mix(k), k), 100.0 * (svi(&p1, (k / f).ln()) / T).sqrt())).collect();
    for &(k, mv, sv) in &hold { println!("held out {:.0}: market, SVI, miss  {:.4} {:.4} {:+.4}", k, mv, sv, sv - mv); }
    let k90 = (90.0 / f).ln(); let rt = ((k90 - m).powi(2) + s * s).sqrt(); // the worked number at the 90 strike
    println!("at 90: k, k-m, root, bracket, w, vol  {:.6} {:.6} {:.6} {:.6} {:.6} {:.4}", k90, k90 - m, rt, rho * (k90 - m) + rt, svi(&p1, k90), 100.0 * (svi(&p1, k90) / T).sqrt());
    let root1 = (1.0 - rho * rho).sqrt();
    println!("bottom: sqrt(1-rho^2), k*, w_min = a+b s sqrt(1-rho^2), vol  {:.6} {:.6} {:.6} {:.4}", root1, m - rho * s / root1, a + b * s * root1, 100.0 * ((a + b * s * root1) / T).sqrt());
    println!("at the forward k = 0: w, vol     {:.6} {:.4}", svi(&p1, 0.0), 100.0 * (svi(&p1, 0.0) / T).sqrt());
    println!("1-rho, 1+rho; wing slopes b(1-rho), b(1+rho)   {:.6} {:.6}; {:.6} {:.6}   Lee's ceiling 2", 1.0 - rho, 1.0 + rho, b * (1.0 - rho), b * (1.0 + rho));
    let (sl, sr) = ((svi(&p1, -12.0) - svi(&p1, -10.0)) / 2.0, (svi(&p1, 12.0) - svi(&p1, 10.0)) / 2.0);
    println!("slopes measured, k -12..-10, 10..12  {:.6} {:.6}", sl, sr);
    let gm = gmin(&p1);
    println!("min g on k in [-1.5, 1.5], at k   {:.6} {:+.3}", gm.0, gm.1);
    for kk in [80.0, 100.0, 120.0] { println!("density at {:.0}, per $1: from g, from prices  {:.6} {:.6}", kk, dens_g(&p1, kk), dens_fd(&p1, kk)); }
    let h = 14.0 / 6000.0; // Simpson on k in [-10, 4]
    let simp = |n: i32| h / 3.0 * (0..6001).map(|i| { let k = -10.0 + i as f64 * h; let wt = if i == 0 || i == 6000 { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 };
        wt * (f * k.exp()).powi(n + 1) * dens_g(&p1, f * k.exp()) }).sum::<f64>();
    println!("density total, mean (Simpson)    {:.6} {:.6}", simp(0), simp(1));
    let v: P = [-0.0410, 0.1331, 0.3060, 0.3586, 0.4153]; // Vogt's example, quoted by Gatheral and Jacquier
    println!("Vogt parameters a b rho m s       {}", v.iter().map(|x| format!("{:+.4}", x)).collect::<Vec<_>>().join(" "));
    let vm = gmin(&v); let kv = f * vm.1.exp();
    println!("Vogt: floor, min g, at k, K       {:.6} {:.6} {:+.3} {:.2}", v[0] + v[1] * v[4] * (1.0 - v[2] * v[2]).sqrt(), vm.0, vm.1, kv);
    println!("Vogt density at K, per $1 000 000: from g, from prices  {:.4} {:.4}", 1e6 * dens_g(&v, kv), 1e6 * dens_fd(&v, kv));
    let qx = lstsq(&[vec![1.0; 7], ks.clone(), ks.iter().map(|k| k * k).collect()], &ws); let wq = |k: f64| qx[0] + qx[1] * k + qx[2] * k * k;
    println!("wrong: parabola in k, w/|k| at k = -3, +3   {:.4} {:.4}  SVI {:.4} {:.4}", wq(-3.0) / 3.0, wq(3.0) / 3.0, svi(&p1, -3.0) / 3.0, svi(&p1, 3.0) / 3.0);
    let k40 = (40.0 / f).ln();
    println!("wrong: parabola vol at 40, SVI vol, market vol  {:.2} {:.2} {:.2}", 100.0 * wq(k40).sqrt(), 100.0 * svi(&p1, k40).sqrt(), 100.0 * iv(mix(40.0), 40.0));
    println!("wrong: k from spot, vol at 100, right vol  {:.4} {:.4}", 100.0 * svi(&p1, (100.0 / S).ln()).sqrt(), 100.0 * svi(&p1, (100.0 / f).ln()).sqrt());
    for (lab, p) in [("rho = 0", [a, b, 0.0, m, s]), ("b doubled", [a, 2.0 * b, rho, m, s]), ("s = 0.01", [a, b, rho, m, 0.01]), ("a + 0.01", [a + 0.01, b, rho, m, s])] {
        println!("try: {:<10} vol at 80/100/120  {}", lab, [80.0, 100.0, 120.0].iter().map(|&k| format!("{:.2}", 100.0 * svi(&p, (k / f).ln()).sqrt())).collect::<Vec<_>>().join(" "));
    }
    let grid: Vec<f64> = (0..9).map(|i| 80.0 + 5.0 * i as f64).collect();
    let kg: Vec<f64> = (0..9).map(|i| -1.0 + 0.25 * i as f64).collect();
    let sg: Vec<f64> = (0..13).map(|i| 40.0 + 10.0 * i as f64).collect();
    let mixd = |x: f64| -> f64 { mixl().iter().map(|&(p, fl, vl)| p * phi(((x / fl).ln() + 0.5 * vl * vl * T) / (vl * T.sqrt())) / (vl * T.sqrt() * x)).sum() };
    println!("chart, strike        {}", line(&grid, 6, 0));
    println!("chart, market vol    {}", line(&grid.iter().map(|&k| 100.0 * iv(mix(k), k)).collect::<Vec<_>>(), 6, 2));
    println!("chart, SVI vol       {}", line(&grid.iter().map(|&k| 100.0 * svi(&p1, (k / f).ln()).sqrt()).collect::<Vec<_>>(), 6, 2));
    println!("chart, k             {}", line(&kg, 6, 2));
    println!("chart, 100 w, SVI    {}", line(&kg.iter().map(|&k| 100.0 * svi(&p1, k)).collect::<Vec<_>>(), 6, 2));
    println!("chart, 100 w, s = 0  {}", line(&kg.iter().map(|&k| 100.0 * svi(&[a, b, rho, m, 0.0], k)).collect::<Vec<_>>(), 6, 2));
    println!("chart, S_T           {}", line(&sg, 5, 0));
    println!("chart, SVI density   {}", line(&sg.iter().map(|&x| 100.0 * dens_g(&p1, x)).collect::<Vec<_>>(), 5, 2));
    println!("chart, market dens.  {}", line(&sg.iter().map(|&x| 100.0 * mixd(x)).collect::<Vec<_>>(), 5, 2));
    assert!(p1.iter().zip(&p2).all(|(x, y)| (x - y).abs() < 1e-6), "two fitting roads land on one parameter set");
    assert!(miss.iter().all(|x| x.abs() < 0.1) && hold.iter().all(|&(_, mv, sv)| (sv - mv).abs() < 0.1), "within a tenth of a vol point");
    assert!([80.0, 100.0, 120.0].iter().all(|&k| (dens_g(&p1, k) - dens_fd(&p1, k)).abs() < 1e-5), "g road = price road");
    assert!((simp(0) - 1.0).abs() < 1e-4 && (simp(1) - f).abs() < 1e-2, "density sums to one and averages to the forward");
    assert!((sl - b * (1.0 - rho)).abs() < 1e-3 && (sr - b * (1.0 + rho)).abs() < 1e-3, "measured wing slopes match b(1 -/+ rho)");
    let hc = 1900.0 / 6000.0; let cint = d * hc / 3.0 * (0..6001).map(|i| { let wt = if i == 0 || i == 6000 { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 }; wt * i as f64 * hc * mixd(100.0 + i as f64 * hc) }).sum::<f64>();
    assert!((cint - mix(100.0)).abs() < 1e-6, "call price by integrating the payoff against the market density");
    assert!(gm.0 > 0.0 && vm.0 < 0.0 && dens_fd(&v, kv) < 0.0, "fit passes butterfly; Vogt fails it on both roads");
    println!("ALL CHECKS PASS");
}
