// Bayesian optimisation of three turbine settings -- the check behind the card.  std only, no crates.
// Settings scaled to 0..1: gate opening 0-100 %, blade angle 10-30 degrees, air 0-4 litres a second.
// Roads: (1) Gaussian-process surrogate + expected improvement, 15 trials; (2) every point of the
// 21 x 21 x 21 grid scored on the stand-in rig; (3) EI's formula against a numerical integral, and the
// surrogate's linear solve by Cholesky against plain elimination; (4) random search, 2000 seeded runs.
use std::f64::consts::PI;
type P = [f64; 3];
const PEAK: P = [0.7, 0.35, 0.6]; const SHOULDER: P = [0.3, 0.7, 0.3];
const M: f64 = 85.0; const SF2: f64 = 25.0; const ELL: f64 = 0.2; const NOISE2: f64 = 0.01; // as in Python
const START: [P; 5] = [[0.1, 0.5, 0.9], [0.3, 0.9, 0.3], [0.5, 0.1, 0.5], [0.7, 0.7, 0.1], [0.9, 0.3, 0.7]];
fn d2(p: &P, q: &P) -> f64 { let mut s = 0.0; for i in 0..3 { s += (p[i] - q[i]) * (p[i] - q[i]); } s }
fn rig(x: &P, w2: f64) -> f64 { 80.0 + 13.0 * (-d2(x, &PEAK) / w2).exp() + 8.0 * (-d2(x, &SHOULDER) / 0.18).exp() }
fn kern(p: &P, q: &P, ell: f64) -> f64 { SF2 * (-d2(p, q) / (2.0 * ell * ell)).exp() }
fn phi(z: f64) -> f64 { (-z * z / 2.0).exp() / (2.0 * PI).sqrt() }
fn cdf(z: f64) -> f64 { // normal CDF: series in the middle, continued fraction in the tails
    if z.abs() > 3.0 {
        let mut cf = z.abs();
        for k in (1..=40).rev() { cf = z.abs() + k as f64 / cf; }
        return if z < 0.0 { phi(z) / cf } else { 1.0 - phi(z) / cf };
    }
    let x = z / 2f64.sqrt();
    let (mut term, mut s) = (x, x);
    for n in 0..60 { term = -term * x * x / (n + 1) as f64; s += term / (2 * n + 3) as f64; }
    0.5 + s / PI.sqrt()
}
fn ei(mu: f64, s: f64, best: f64) -> f64 { let z = (mu - best) / s; (mu - best) * cdf(z) + s * phi(z) }
fn lower_solve(l: &[Vec<f64>], b: &[f64]) -> Vec<f64> {
    let mut z: Vec<f64> = Vec::new();
    for i in 0..b.len() { let mut s = 0.0; for k in 0..i { s += l[i][k] * z[k]; } z.push((b[i] - s) / l[i][i]); }
    z
}
struct Post { x: Vec<P>, l: Vec<Vec<f64>>, r: Vec<f64>, ell: f64 }
fn surrogate(x: &[P], y: &[f64], ell: f64) -> Post {
    let n = x.len();
    let mut l = vec![vec![0.0; n]; n];
    for i in 0..n {
        for j in 0..=i {
            let mut s = 0.0; for k in 0..j { s += l[i][k] * l[j][k]; }
            let t = kern(&x[i], &x[j], ell) + if i == j { NOISE2 } else { 0.0 } - s;
            l[i][j] = if i == j { t.sqrt() } else { t / l[j][j] };
        }
    }
    let r = lower_solve(&l, &y.iter().map(|v| v - M).collect::<Vec<_>>());
    Post { x: x.to_vec(), l, r, ell }
}
impl Post {
    fn at(&self, q: &P) -> (f64, f64) {
        let v = lower_solve(&self.l, &self.x.iter().map(|p| kern(q, p, self.ell)).collect::<Vec<_>>());
        let (mut a, mut b) = (0.0, 0.0);
        for i in 0..v.len() { a += v[i] * self.r[i]; b += v[i] * v[i]; }
        (M + a, (SF2 - b).max(1e-12).sqrt())
    }
}
fn grid() -> Vec<P> { (0..9261).map(|i| [(i / 441) as f64 / 20.0, (i / 21 % 21) as f64 / 20.0, (i % 21) as f64 / 20.0]).collect() }
fn maxv(y: &[f64]) -> f64 { y.iter().cloned().fold(f64::MIN, f64::max) }
fn argmax(y: &[f64]) -> usize { let m = maxv(y); y.iter().position(|&v| v == m).unwrap() }
fn bo(rule: &str, ell: f64, trials: usize, w2: f64) -> (Vec<P>, Vec<f64>, Vec<f64>) {
    let g = grid();
    let (mut x, mut log): (Vec<P>, Vec<f64>) = (START.to_vec(), Vec::new());
    let mut y: Vec<f64> = x.iter().map(|p| rig(p, w2)).collect();
    while x.len() < trials {
        let (post, best) = (surrogate(&x, &y, ell), maxv(&y));
        let (mut top, mut arg) = (-1.0, g[0]);
        for p in &g {
            let (mu, s) = post.at(p);
            let score = if rule == "ei" { ei(mu, s, best) } else if rule == "mean" { mu } else { s };
            if score > top { top = score; arg = *p; }
        }
        x.push(arg); y.push(rig(&arg, w2)); log.push(top);
    }
    (x, y, log)
}
fn so_far(y: &[f64]) -> Vec<f64> { (0..y.len()).map(|i| maxv(&y[..=i])).collect() }
fn fmt(x: &P) -> String { format!("({:.2}, {:.2}, {:.2})", x[0], x[1], x[2]) }
fn row(v: &[f64]) -> String { v.iter().map(|a| format!("{:.2}", a)).collect::<Vec<_>>().join(" ") }
fn splitmix(s: &mut u64) -> u64 {
    *s = s.wrapping_add(0x9E3779B97F4A7C15); let mut z = (*s ^ (*s >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB); (z ^ (z >> 31)) >> 11
}
fn main() {
    // a hand-sized case: only trial 5 known, a candidate 0.2 away from it
    let (y5, q) = (rig(&START[4], 0.08), [0.7, 0.3, 0.7]);
    let one = surrogate(&START[4..5], &[y5], ELL);
    let (mu1, s1) = one.at(&q);
    let rho = (-d2(&START[4], &q) / (2.0 * ELL * ELL)).exp();
    let (z1, wt) = ((mu1 - y5) / s1, rho * SF2 / (SF2 + NOISE2));
    println!("one trial: y5 {:.4}, correlation {:.4}, weight {:.4}, mean {:.4}, variance {:.4}, sd {:.4}", y5, rho, wt, mu1, s1 * s1, s1);
    println!("one trial: z {:.4} Phi {:.6} phi {:.6} EI {:.4} x Phi + {:.4} x phi = {:.4} + {:.4} = {:.4}",
        z1, cdf(z1), phi(z1), mu1 - y5, s1, (mu1 - y5) * cdf(z1), s1 * phi(z1), ei(mu1, s1, y5));
    let (mu0, s0) = one.at(&START[4]);
    println!("at trial 5 itself: mean {:.4}, sd {:.4}, EI {:.4}", mu0, s0, ei(mu0, s0, y5));
    assert!((mu1 - (M + wt * (y5 - M))).abs() < 1e-9); // the bivariate-normal rule
    assert!((s1 * s1 - (SF2 - rho * rho * SF2 * SF2 / (SF2 + NOISE2))).abs() < 1e-9);
    let (x, y, log) = bo("ei", ELL, 15, 0.08);
    for i in 0..15 {
        let tag = if i < 5 { "start".to_string() } else { format!("EI {:5.3}", log[i - 5]) };
        println!("trial {:2} {} {:8} -> {:5.2}  best {:5.2}", i + 1, fmt(&x[i]), tag, y[i], maxv(&y[..=i]));
    }
    let best5 = maxv(&y[..5]); let (mu6, s6) = surrogate(&x[..5], &y[..5], ELL).at(&x[5]); let z6 = (mu6 - best5) / s6;
    println!("pick 6: mean {:.4} sd {:.4} z {:.4} Phi {:.6} phi {:.6} EI {:.4} + {:.4} = {:.4}",
        mu6, s6, z6, cdf(z6), phi(z6), (mu6 - best5) * cdf(z6), s6 * phi(z6), ei(mu6, s6, best5));
    // road 3a: EI's formula against Simpson's rule on the improvement integral
    let (n, mut simp) = (4000, 0.0); let h = 10.0 * s6 / n as f64;
    for j in 0..=n {
        let c = if j == 0 || j == n { 1 } else if j % 2 == 1 { 4 } else { 2 };
        simp += (c * j) as f64 * h * phi((best5 + j as f64 * h - mu6) / s6) / s6;
    }
    simp = simp * h / 3.0;
    println!("road 3, EI formula {:.6}  Simpson {:.6}", ei(mu6, s6, best5), simp);
    assert!((ei(mu6, s6, best5) - simp).abs() < 1e-6);
    // road 3b: the same mean by plain Gaussian elimination on the full system
    let mut a: Vec<Vec<f64>> = (0..5).map(|i| {
        let mut r: Vec<f64> = (0..5).map(|j| kern(&x[i], &x[j], ELL) + if i == j { NOISE2 } else { 0.0 }).collect();
        r.push(y[i] - M); r }).collect();
    for c in 0..5 { for r in c + 1..5 { let g = a[r][c] / a[c][c]; for k in 0..6 { a[r][k] = a[r][k] - g * a[c][k]; } } }
    let mut alpha = [0.0; 5];
    for r in (0..5).rev() { let mut s = 0.0; for k in r + 1..5 { s += a[r][k] * alpha[k]; } alpha[r] = (a[r][5] - s) / a[r][r]; }
    let mut sum = 0.0; for i in 0..5 { sum += kern(&x[5], &x[i], ELL) * alpha[i]; } let mu_elim = M + sum;
    println!("road 3, mean at pick 6 by elimination {:.6}", mu_elim);
    assert!((mu_elim - mu6).abs() < 1e-9);
    // road 2: score every grid point on the rig
    let g = grid(); let gv: Vec<f64> = g.iter().map(|p| rig(p, 0.08)).collect(); let gbest = g[argmax(&gv)];
    println!("road 2, all {} grid points: best {} -> {:.2}; BO best {:.2}", g.len(), fmt(&gbest), maxv(&gv), maxv(&y));
    assert!(maxv(&y) >= maxv(&gv) - 1e-9); // BO reached the grid's best point
    assert!(best5 < maxv(&gv) - 5.0); // and the start alone did not
    let (mut tp, mut hs) = (gbest, 0.05); // the rig's true peak: compass search from the grid's best
    while hs > 1e-9 { let mut nb = tp; for i in 0..3 { for s in [1.0, -1.0] { let mut c = tp; c[i] += s * hs; if rig(&c, 0.08) > rig(&nb, 0.08) { nb = c; } } }
        if rig(&nb, 0.08) > rig(&tp, 0.08) { tp = nb; } else { hs /= 2.0; } }
    println!("road 2, between grid points: compass search from the grid's best reaches {:.2} at ({:.3}, {:.3}, {:.3})", rig(&tp, 0.08), tp[0], tp[1], tp[2]);
    assert!(rig(&tp, 0.08) > maxv(&gv) + 0.05); // so the grid search certifies the grid's best, not the box's
    let b = x[argmax(&y)];
    println!("best settings: gate {:.0} %, blade {:.1} degrees, air {:.2} L/s", 100.0 * b[0], 10.0 + 20.0 * b[1], 4.0 * b[2]);
    println!("cost at GBP 20000 a trial: 15 trials {}, every grid point {}", 15 * 20000, g.len() * 20000);
    // road 4: random search, 2000 runs of 15 trials, SplitMix64 from seed 2026
    let (runs, mut state, mut avg, mut hits) = (2000, 2026u64, vec![0.0; 15], 0);
    for _ in 0..runs {
        let mut ys = Vec::new();
        for _ in 0..15 {
            let mut p = [0.0; 3];
            for k in 0..3 { p[k] = splitmix(&mut state) as f64 / 9007199254740992.0; }
            ys.push(rig(&p, 0.08));
        }
        let sf = so_far(&ys);
        for t in 0..15 { avg[t] = avg[t] + sf[t] / runs as f64; }
        if sf[14] >= 93.0 { hits += 1; }
    }
    let mut inside = 0;
    for a in 0..40 { for b in 0..40 { for c in 0..40 {
        let p = [(a as f64 + 0.5) / 40.0, (b as f64 + 0.5) / 40.0, (c as f64 + 0.5) / 40.0];
        if rig(&p, 0.08) >= 93.0 { inside += 1; } } } }
    let (frac, share) = (inside as f64 / 64000.0, hits as f64 / runs as f64); let p15 = 1.0 - (1.0 - frac).powf(15.0);
    println!("random: share of the box at 93 or more {:.5}; runs reaching 93: {:.4}, predicted {:.4}", frac, share, p15);
    assert!((share - p15).abs() < 3.0 * (p15 * (1.0 - p15) / runs as f64).sqrt() + 0.005);
    println!("chart, BO best so far     {}", row(&so_far(&y)));
    println!("chart, random, average    {}", row(&avg));
    let (xm, ym, _) = bo("mean", ELL, 15, 0.08);
    println!("chart, highest mean only  {}; trial 6 at {}", row(&so_far(&ym)), fmt(&xm[5]));
    assert!(maxv(&ym) < maxv(&y) - 5.0); // exploiting alone stalls on the start
    assert!(avg[14] < maxv(&y) - 3.0); // random search trails on average
    let (ys, yr, yn) = (bo("sd", ELL, 15, 0.08).1, bo("ei", 0.05, 15, 0.08).1, bo("ei", ELL, 15, 0.02).1);
    println!("wrong: most uncertain point only   {:.2}", maxv(&ys));
    println!("wrong: length scale 0.05           {:.2}", maxv(&yr));
    let gn: Vec<f64> = g.iter().map(|p| rig(p, 0.02)).collect();
    println!("broken: peak narrower, width 0.1   {:.2}, grid best {:.2}", maxv(&yn), maxv(&gn));
    for ell in [0.1, 0.3] {
        let (xt, yt, _) = bo("ei", ell, 15, 0.08);
        println!("try: length scale {}  best {:.2} at {}, trial {}", ell, maxv(&yt), fmt(&xt[argmax(&yt)]), argmax(&yt) + 1);
    }
    println!("ALL CHECKS PASS");
}
