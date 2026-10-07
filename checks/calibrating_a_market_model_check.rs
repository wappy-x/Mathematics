// Calibrating a market model. Roads: Levenberg-Marquardt, Nelder-Mead, Simpson, a Monte Carlo of the model.
use std::f64::consts::PI;
const D: f64 = 0.12; // fixed d; forward i runs from year i to year i + 1
const CAP: [f64; 10] = [0.2210, 0.2296, 0.2149, 0.2129, 0.1963, 0.1925, 0.1893, 0.1779, 0.1694, 0.1720];
const SWP: [(usize, usize, f64); 10] = [(1, 2, 0.2219), (1, 5, 0.1836), (1, 10, 0.1434), (2, 3, 0.2035), (2, 8, 0.1523),
    (3, 3, 0.1915), (3, 7, 0.1524), (5, 5, 0.1555), (6, 4, 0.1615), (8, 3, 0.1579)];
const MADE: [f64; 4] = [0.08, 0.12, 0.60, 0.10]; // the knobs the screen was manufactured from
type Th = [f64; 4]; type Ks = [f64; 11]; type Mat = Vec<Vec<f64>>;
fn t(i: usize) -> f64 { i as f64 }
fn l(i: usize) -> f64 { 0.030 + 0.002 * i as f64 } // today's one-year forward rates, 3.0% to 5.0%
fn p(i: usize) -> f64 { let mut x = 1.0; for j in 0..i { x = x / (1.0 + l(j)); } x } // discount factor P(0, T_i)
fn g(i: usize, s: f64, th: &Th) -> f64 { (th[0] + th[1] * (t(i) - s)) * (-th[2] * (t(i) - s)).exp() + D }
fn cross(i: usize, j: usize, e: f64, th: &Th, d: f64) -> f64 { // closed form: integral of g_i g_j from 0 to e
    let (a, b, c) = (th[0], th[1], th[2]);
    let mom = |k: f64| { let m0 = -(-k * e).exp_m1() / k; let m1 = (m0 - e * (-k * e).exp()) / k; [m0, m1, (2.0 * m1 - e * e * (-k * e).exp()) / k] };
    let (m, n) = (mom(2.0 * c), mom(c));
    let (ai, aj, ei, ej) = (a + b * (t(i) - e), a + b * (t(j) - e), (-c * (t(i) - e)).exp(), (-c * (t(j) - e)).exp());
    ei * ej * (ai * aj * m[0] + b * (ai + aj) * m[1] + b * b * m[2]) + d * (ei * (ai * n[0] + b * n[1]) + ej * (aj * n[0] + b * n[1])) + d * d * e
}
fn simpson<F: Fn(f64) -> f64>(f: F, lo: f64, hi: f64) -> f64 { // second integrator, no closed form used
    let n = 2000usize; let h = (hi - lo) / n as f64;
    h / 3.0 * (0..=n).map(|m| (if m == 0 || m == n { 1.0 } else if m % 2 == 1 { 4.0 } else { 2.0 }) * f(lo + m as f64 * h)).sum::<f64>()
}
fn mults(th: &Th, d: f64, cap: &[f64]) -> Ks { let mut k = [0.0; 11]; for i in 1..11 { k[i] = cap[i - 1] * (t(i) / cross(i, i, t(i), th, d)).sqrt(); } k }
fn cov(i: usize, j: usize, e: f64, th: &Th, k: &Ks, d: f64) -> f64 { (-th[3] * (t(i) - t(j)).abs()).exp() * k[i] * k[j] * cross(i, j, e, th, d) }
fn swap(q: usize, n: usize) -> (f64, f64) { let a: f64 = (q..q + n).map(|i| p(i + 1)).sum(); (a, (q..q + n).map(|i| p(i + 1) * l(i)).sum::<f64>() / a) }
fn reb(q: usize, n: usize, th: &Th, k: &Ks, d: f64) -> f64 { // Rebonato's frozen-weight Black vol of the swaption
    let (a, s) = swap(q, n); let x: Vec<f64> = (q..q + n).map(|i| p(i + 1) / a * l(i)).collect();
    let v: f64 = (0..n).flat_map(|u| (0..n).map(move |w| (u, w))).map(|(u, w)| x[u] * x[w] * cov(q + u, q + w, t(q), th, k, d)).sum();
    (v / (t(q) * s * s)).sqrt()
}
fn resid(th: &Th) -> Vec<f64> { let k = mults(th, D, &CAP); SWP.iter().map(|&(q, n, u)| 100.0 * (reb(q, n, th, &k, D) - u)).collect() }
fn loss(th: &Th) -> f64 {
    if 0.05 < th[2] && th[2] < 5.0 && 0.0 <= th[3] && th[3] < 3.0 && th[0] > -D { 0.5 * resid(th).iter().map(|e| e * e).sum::<f64>() } else { f64::INFINITY }
}
fn chol(c: &Mat) -> Mat { // lower-triangular r with r r' = c
    let n = c.len(); let mut r = vec![vec![0.0; n]; n];
    for a in 0..n { for b in 0..=a { let x = c[a][b] - (0..b).map(|m| r[a][m] * r[b][m]).sum::<f64>(); r[a][b] = if a == b { x.sqrt() } else { x / r[b][b] }; } }
    r
}
fn lm(mut th: Th) -> (Th, f64, usize) { // road one: Levenberg-Marquardt, slopes by bumping
    let (mut f, mut steps, mut lam) = (loss(&th), 0usize, 1e-3);
    while steps < 100 {
        let e = resid(&th);
        let j: Mat = (0..4).map(|r| { let mut tp = th; tp[r] += 1e-7; resid(&tp).iter().zip(&e).map(|(x, y)| (x - y) / 1e-7).collect() }).collect();
        let a: Mat = (0..4).map(|r| (0..4).map(|s| (0..10).map(|m| j[r][m] * j[s][m]).sum()).collect()).collect();
        let grad: Vec<f64> = (0..4).map(|r| -(0..10).map(|m| j[r][m] * e[m]).sum::<f64>()).collect();
        let (mut tn, mut fnew) = (th, f64::INFINITY);
        while lam < 1e12 { // damped step by Cholesky; a refused step triples the damping
            let rr = chol(&(0..4).map(|r| (0..4).map(|s| a[r][s] * if r == s { 1.0 + lam } else { 1.0 }).collect()).collect());
            let (mut y, mut d) = ([0.0; 4], [0.0; 4]);
            for u in 0..4 { y[u] = (grad[u] - (0..u).map(|m| rr[u][m] * y[m]).sum::<f64>()) / rr[u][u]; }
            for u in (0..4).rev() { d[u] = (y[u] - (u + 1..4).map(|m| rr[m][u] * d[m]).sum::<f64>()) / rr[u][u]; }
            for q in 0..4 { tn[q] = th[q] + d[q]; } fnew = loss(&tn);
            if fnew < f { break; } lam *= 3.0;
        }
        if fnew >= f { break; }
        let gain = f - fnew; steps += 1; lam /= 3.0; th = tn; f = fnew;
        if gain < 1e-13 * (1.0 + f) { break; }
    }
    (th, f, steps)
}
fn nelder(th: Th) -> (Th, f64, usize) { // road two: Nelder-Mead, no slopes at all
    let mut pts: Vec<Th> = vec![th]; for r in 0..4 { let mut x = th; x[r] += 0.05; pts.push(x); }
    let (mut fs, mut evals, lo) = (pts.iter().map(loss).collect::<Vec<f64>>(), 5usize, |f: &Vec<f64>| f.iter().cloned().fold(f64::INFINITY, f64::min));
    while fs.iter().cloned().fold(f64::NEG_INFINITY, f64::max) - lo(&fs) > 1e-13 * (1.0 + lo(&fs)) && evals < 20000 {
        let mut o: Vec<usize> = (0..5).collect(); o.sort_by(|&x, &y| fs[x].partial_cmp(&fs[y]).unwrap());
        pts = o.iter().map(|&m| pts[m]).collect(); fs = o.iter().map(|&m| fs[m]).collect();
        let tr = |s: f64, pts: &Vec<Th>| { let mut x = [0.0; 4]; for q in 0..4 { x[q] = (pts[0][q] + pts[1][q] + pts[2][q] + pts[3][q]) / 4.0 * (1.0 - s) + s * pts[4][q]; } x };
        let xr = tr(-1.0, &pts); let fr = loss(&xr); evals += 1;
        if fr < fs[0] {
            let xe = tr(-2.0, &pts); let fe = loss(&xe); evals += 1;
            if fe < fr { pts[4] = xe; fs[4] = fe; } else { pts[4] = xr; fs[4] = fr; }
        } else if fr < fs[3] { pts[4] = xr; fs[4] = fr; } else {
            let xc = tr(if fr >= fs[4] { 0.5 } else { -0.5 }, &pts); let fc = loss(&xc); evals += 1;
            if fc < fr.min(fs[4]) { pts[4] = xc; fs[4] = fc; } else { // shrink every corner halfway to the best one
                for m in 1..5 { for q in 0..4 { pts[m][q] = 0.5 * (pts[0][q] + pts[m][q]); } fs[m] = loss(&pts[m]); }
                evals += 4;
            }
        }
    }
    let m = (0..5).min_by(|&x, &y| fs[x].partial_cmp(&fs[y]).unwrap()).unwrap(); (pts[m], fs[m], evals)
}
struct Rng(u64);
impl Rng { fn unif(&mut self) -> f64 { // splitmix64, top 53 bits, never exactly 0
    self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15); let mut z = self.0;
    z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9); z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    ((z ^ (z >> 31)) >> 11) as f64 * 2f64.powi(-53) + 2f64.powi(-54) } }
fn ncdf(x: f64) -> f64 { // bell-curve area left of x, by its power series
    let y = x / 2f64.sqrt(); let (mut s, mut term, mut n) = (0.0, y, 0.0);
    while term.abs() > 1e-17 * (2.0 * n + 1.0) { s += term / (2.0 * n + 1.0); n += 1.0; term *= -y * y / n; }
    0.5 + s / PI.sqrt()
}
fn mc(th: &Th, k: &Ks, pairs: usize) -> [f64; 4] { // road four: forwards 5..10 to year 5, year-11 bond as unit
    let (steps, mut rng, s0) = (20usize, Rng(20260928), swap(5, 5).1); let h = 5.0 / steps as f64;
    let cm: Vec<Mat> = (0..steps).map(|s| (5..11).map(|i| (5..11).map(|j| cov(i, j, (s + 1) as f64 * h, th, k, D) - cov(i, j, s as f64 * h, th, k, D)).collect()).collect()).collect();
    let rm: Vec<Mat> = cm.iter().map(chol).collect(); let mut out: Vec<[f64; 3]> = Vec::new();
    for _ in 0..pairs {
        let (mut z, mut pay) = (Vec::new(), [0.0; 3]);
        for _ in 0..steps * 3 { let r = (-2.0 * rng.unif().ln()).sqrt(); let a = 2.0 * PI * rng.unif(); z.push(r * a.cos()); z.push(r * a.sin()); }
        for sign in [1.0, -1.0] { // antithetic pair: the same draws, sign flipped
            let mut x: Vec<f64> = (5..11).map(|i| l(i).ln()).collect();
            for s in 0..steps { // log step: terminal-measure drift, exact covariance
                let (lv, c): (Vec<f64>, &Mat) = (x.iter().map(|v| v.exp()).collect(), &cm[s]);
                x = (0..6).map(|a| x[a] - (a + 1..6).map(|b| lv[b] / (1.0 + lv[b]) * c[a][b]).sum::<f64>() - 0.5 * c[a][a]
                    + sign * (0..=a).map(|b| rm[s][a][b] * z[6 * s + b]).sum::<f64>()).collect();
            }
            let mut grow = [1.0; 7]; // grow[m] = P(5, T_5+m) / P(5, T_11)
            for m in (0..6).rev() { grow[m] = grow[m + 1] * (1.0 + x[m].exp()); }
            let ann: f64 = grow[1..6].iter().sum(); let sw = (grow[0] - grow[5]) / ann;
            pay = [pay[0] + 0.5 * (x[0].exp() - l(5)).max(0.0) * grow[1], pay[1] + 0.5 * ann * (sw - s0).max(0.0), pay[2] + 0.5 * ann * (sw - s0)];
        }
        out.push(pay);
    }
    let np = pairs as f64; let mean: Vec<f64> = (0..3).map(|q| out.iter().map(|o| o[q]).sum::<f64>() / np).collect();
    let cv = |q: usize, r: usize| out.iter().map(|o| (o[q] - mean[q]) * (o[r] - mean[r])).sum::<f64>() / (np - 1.0);
    let beta = cv(1, 2) / cv(2, 2); // control: the forward swap itself, worth exactly 0 today
    [p(11) * mean[0], p(11) * (cv(0, 0) / np).sqrt(), p(11) * (mean[1] - beta * mean[2]), p(11) * ((cv(1, 1) - beta * cv(1, 2)) / np).sqrt()]
}
fn implied(ratio: f64, e: f64) -> f64 { // ATM Black vol by bisection: 2N(u sqrt(e) / 2) - 1 = ratio
    let (mut lo, mut hi) = (1e-6, 2.0); for _ in 0..100 { let mid = 0.5 * (lo + hi); if 2.0 * ncdf(0.5 * mid * e.sqrt()) - 1.0 < ratio { lo = mid } else { hi = mid } }
    0.5 * (lo + hi)
}
fn main() {
    let (th1, f1, n1) = lm([0.20, 0.05, 1.50, 0.40]); let (th2, f2, n2) = nelder([0.02, 0.30, 0.30, 0.02]); let k = mults(&th1, D, &CAP);
    let jn = |v: &[f64], dp: usize| v.iter().map(|x| format!("{:.*}", dp, x)).collect::<Vec<_>>().join(" ");
    println!("caplet quotes 1y..10y        {}\ncaplet multipliers k_1..k_10  {}", jn(&CAP.map(|x| 100.0 * x), 2), jn(&k[1..], 4));
    println!("road 1 Levenberg-Marquardt a b c beta {}  loss {:.6}  steps {}", jn(&th1, 6), f1, n1);
    println!("road 2 Nelder-Mead         a b c beta {}  loss {:.6}  evals {}", jn(&th2, 6), f2, n2);
    println!("manufacturing knobs 0.08 0.12 0.60 0.10: loss {:.6}  1y x 10y {:.2}", loss(&MADE), 100.0 * reb(1, 10, &MADE, &mults(&MADE, D, &CAP), D));
    for &(q, n, u) in SWP.iter() { let v = reb(q, n, &th1, &k, D); println!("swaption {:>2}y x {:>2}y  quote {:6.2}  fit {:6.2}  miss {:+.2}", q, n, 100.0 * u, 100.0 * v, 100.0 * (v - u)); }
    let capmiss = (1..11).map(|i| (k[i] * (simpson(|s| g(i, s, &th1).powi(2), 0.0, t(i)) / t(i)).sqrt() - CAP[i - 1]).abs()).fold(0.0, f64::max);
    let (one, ci, cs) = (reb(5, 1, &th1, &k, D), cross(3, 7, 3.0, &th1, D), simpson(|s| g(3, s, &th1) * g(7, s, &th1), 0.0, 3.0));
    let big = [1.5 * th1[0], 1.5 * th1[1], th1[2], th1[3]]; let kb = mults(&big, 1.5 * D, &CAP);
    let shift = SWP.iter().map(|&(q, n, _)| (reb(q, n, &big, &kb, 1.5 * D) - reb(q, n, &th1, &k, D)).abs()).fold(0.0, f64::max);
    println!("caplets repriced through Simpson: largest miss {:.10} points   5y x 1y by Rebonato {:.6}, caplet quote {:.6}", 100.0 * capmiss, 100.0 * one, 100.0 * CAP[4]);
    println!("cross integral, forwards 3 and 7, to year 3: closed form {:.8}  Simpson {:.8}   abcd all times 1.5: largest change {:.10}", ci, cs, 100.0 * shift);
    let ((a5, s5), r55) = (swap(5, 5), reb(5, 5, &th1, &k, D)); let [cmc, cse, smc, sse] = mc(&th1, &k, 20000);
    let (cbl, sbl) = (p(6) * l(5) * (2.0 * ncdf(0.5 * CAP[4] * 5f64.sqrt()) - 1.0), a5 * s5 * (2.0 * ncdf(0.5 * r55 * 5f64.sqrt()) - 1.0));
    let umc = implied(smc / (a5 * s5), 5.0); let use_ = implied((smc + sse) / (a5 * s5), 5.0) - umc;
    println!("MC 5y caplet, per 1 notional  {:.6} +/- {:.6}   Black at the quote {:.6}", cmc, cse, cbl);
    println!("MC 5y x 5y swaption           {:.6} +/- {:.6}   Rebonato price {:.6}", smc, sse, sbl);
    println!("MC implied vol {:.2} +/- {:.2}   Rebonato {:.2}   gap {:+.2} points", 100.0 * umc, 100.0 * use_, 100.0 * r55, 100.0 * (r55 - umc));
    let ((a, s), i) = (swap(1, 2), [cross(1, 1, 1.0, &th1, D), cross(1, 2, 1.0, &th1, D), cross(2, 2, 1.0, &th1, D)]);
    let (x1, x2) = (p(2) / a * l(1) * k[1], p(3) / a * l(2) * k[2]); let tm = [x1 * x1 * i[0], 2.0 * x1 * x2 * (-th1[3]).exp() * i[1], x2 * x2 * i[2]];
    println!("hand 1y x 2y: P(0,2) {:.6}  P(0,3) {:.6}  annuity {:.6}  w1 {:.6}  w2 {:.6}  S {:.6}%", p(2), p(3), a, p(2) / a, p(3) / a, 100.0 * s);
    println!("hand: k1 {:.6}  k2 {:.6}  I11 {:.6}  I12 {:.6}  I22 {:.6}  rho12 {:.6}", k[1], k[2], i[0], i[1], i[2], (-th1[3]).exp());
    println!("hand: terms x 1e6 {:.6} {:.6} {:.6}  sum {:.6}  S^2 x 1e6 {:.6}", 1e6 * tm[0], 1e6 * tm[1], 1e6 * tm[2], 1e6 * (tm[0] + tm[1] + tm[2]), 1e6 * s * s);
    let (kbar, (a1, s1)) = (k[1..].iter().sum::<f64>() / 10.0, swap(1, 10));
    let cmiss = (1..11).map(|i| (kbar * (cross(i, i, t(i), &th1, D) / t(i)).sqrt() - CAP[i - 1]).abs()).fold(0.0, f64::max);
    println!("break: one common multiplier {:.4}, largest caplet miss {:.2} points", kbar, 100.0 * cmiss);
    let mut flat = [0.0; 11]; flat[1..].copy_from_slice(&CAP);
    println!("break: 1y x 10y with beta = 0 (one factor) {:.2}   with flat caplet vols {:.2}", 100.0 * reb(1, 10, &[th1[0], th1[1], th1[2], 0.0], &k, D), 100.0 * reb(1, 10, &[0.0, 0.0, 1.0, th1[3]], &flat, 1.0));
    println!("break: 1y x 10y as weighted average of caplet vols {:.2}", 100.0 * (0..10).map(|m| p(m + 2) * l(m + 1) * CAP[m]).sum::<f64>() / (a1 * s1));
    let mut bump = CAP; bump[4] += 0.01;
    println!("try: beta = 0.30, 1y x 10y {:.2}   5y caplet +1 point, 5y x 5y {:.2}", 100.0 * reb(1, 10, &[th1[0], th1[1], th1[2], 0.30], &k, D), 100.0 * reb(5, 5, &th1, &mults(&th1, D, &bump), D));
    for (name, th) in [("fitted", th1), ("made  ", MADE)] { let kk = mults(&th, D, &CAP); println!("chart, 10y forward {}   {}", name, jn(&(0..11).map(|s| 100.0 * kk[10] * g(10, s as f64, &th)).collect::<Vec<_>>(), 2)); }
    assert!(th1.iter().zip(&th2).map(|(x, y)| (x - y).abs()).fold(0.0, f64::max) < 1e-5, "two optimisers, one minimum");
    assert!(capmiss < 1e-10, "every caplet repriced exactly, checked with an integral the fit never used");
    assert!((ci - cs).abs() < 1e-10, "closed-form cross integral against Simpson");
    assert!((one - CAP[4]).abs() < 1e-12, "a one-period swaption must collapse to its caplet");
    assert!((cmc - cbl).abs() < 3.0 * cse, "simulated caplet within three standard errors of Black");
    assert!((r55 - umc).abs() < 0.0025, "Rebonato within a quarter of a vol point of the simulated model");
    assert!(shift < 1e-12, "overall scale of abcd is invisible once the caplets set the multipliers");
    println!("ALL CHECKS PASS");
}
