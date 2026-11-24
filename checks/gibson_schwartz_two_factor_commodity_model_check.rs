// Gibson-Schwartz: Brent 85, a convenience yield 6% pulled to 3% at speed 1.5 -- the card's check.
// No crates.  The same roads as the Python, the same random numbers, the same printed lines.
use std::f64::consts::PI;
const R: f64 = 0.05;
#[derive(Clone, Copy)]
struct Par { s: f64, y: f64, k: f64, al: f64, ss: f64, sy: f64, rho: f64 }
const P: Par = Par { s: 85.0, y: 0.06, k: 1.5, al: 0.03, ss: 0.30, sy: 0.25, rho: 0.8 };
fn bf(t: f64, k: f64) -> f64 { (1.0 - (-k * t).exp()) / k }   // years of today's yield gap still felt by T
fn terms(t: f64, p: Par) -> ([f64; 4], f64, f64, f64) {       // road 1: the closed form, piece by piece
    let b = bf(t, p.k); let i1 = (t - b) / p.k;                // i1: integral of B(u) du from 0 to T
    let i2 = (t - 2.0 * b + (1.0 - (-2.0 * p.k * t).exp()) / (2.0 * p.k)) / p.k.powi(2);
    ([(R - p.al) * t, -(p.y - p.al) * b, -p.rho * p.ss * p.sy * i1, 0.5 * p.sy * p.sy * i2], b, i1, i2)
}
fn fut(t: f64, p: Par) -> f64 { p.s * terms(t, p).0.iter().sum::<f64>().exp() }
fn fut_ode(t: f64, p: Par) -> f64 {
    // road 2: moments of log spot X and yield y, stepped by Runge-Kutta; F = exp(mean X + var X / 2)
    let f = |s: [f64; 5]| [R - s[1] - p.ss * p.ss / 2.0, p.k * (p.al - s[1]), p.ss * p.ss - 2.0 * s[3],
                            p.rho * p.ss * p.sy - p.k * s[3] - s[4], p.sy * p.sy - 2.0 * p.k * s[4]];
    let add = |s: [f64; 5], d: [f64; 5], h: f64| { let mut o = s; for i in 0..5 { o[i] += h * d[i]; } o };
    let (n, mut s) = (2000, [p.s.ln(), p.y, 0.0, 0.0, 0.0]); let h = t / n as f64;
    for _ in 0..n {
        let k1 = f(s); let k2 = f(add(s, k1, h / 2.0)); let k3 = f(add(s, k2, h / 2.0)); let k4 = f(add(s, k3, h));
        for i in 0..5 { s[i] += h / 6.0 * (k1[i] + 2.0 * k2[i] + 2.0 * k3[i] + k4[i]); }
    }
    (s[0] + s[2] / 2.0).exp()
}
struct Lcg(u64);                                                // road 3: our own random numbers
impl Lcg {
    fn uniform(&mut self) -> f64 {                              // 64-bit LCG, top 53 bits
        self.0 = self.0.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407); ((self.0 >> 11) as f64 + 0.5) / 9007199254740992.0 }
    fn normals(&mut self) -> (f64, f64) {                       // two independent normals, then correlate
        let r = (-2.0 * self.uniform().ln()).sqrt(); let t = 2.0 * PI * self.uniform();
        (r * t.cos(), P.rho * r * t.cos() + (1.0 - P.rho * P.rho).sqrt() * r * t.sin())
    }
}
fn simulate(rng: &mut Lcg, times: &[f64], pairs: usize, dt: f64) -> Vec<(f64, f64)> {
    let (marks, mut sums): (Vec<usize>, _) = (times.iter().map(|t| (t / dt).round() as usize).collect(), vec![(0.0_f64, 0.0_f64); times.len()]);
    let (ss, sy, k, al) = (P.ss, P.sy, P.k, P.al);
    for _ in 0..pairs {
        let (mut xa, mut xb, mut ya, mut yb) = (P.s.ln(), P.s.ln(), P.y, P.y);
        for step in 1..=*marks.iter().max().unwrap() {
            let (z1, z2) = rng.normals();
            (xa, ya) = (xa + (R - ya - ss * ss / 2.0) * dt + ss * dt.sqrt() * z1, ya + k * (al - ya) * dt + sy * dt.sqrt() * z2);
            (xb, yb) = (xb + (R - yb - ss * ss / 2.0) * dt - ss * dt.sqrt() * z1, yb + k * (al - yb) * dt - sy * dt.sqrt() * z2);
            if let Some(i) = marks.iter().position(|&m| m == step) { let v = (xa.exp() + xb.exp()) / 2.0; sums[i].0 += v; sums[i].1 += v * v; }
        }
    }
    let n = pairs as f64; sums.iter().map(|&(a, b)| (a / n, ((b / n - (a / n).powi(2)) / n).sqrt())).collect()
}
fn vol_corr(ta: f64, tb: f64, p: Par) -> (f64, f64, f64) {      // formula: d ln F = ss dz1 - sy B dz2
    let cov = |a: f64, b: f64| p.ss * p.ss - p.rho * p.ss * p.sy * (a + b) + p.sy * p.sy * a * b;
    let (a, b) = (bf(ta, p.k), bf(tb, p.k));
    (cov(a, a).sqrt(), cov(b, b).sqrt(), cov(a, b) / (cov(a, a) * cov(b, b)).sqrt())
}
fn bumps(t: f64) -> (f64, f64) {                                // second road: slopes of ln F from the ODE road
    let e = 1e-4_f64; let ds = (fut_ode(t, Par { s: P.s * e.exp(), ..P }).ln() - fut_ode(t, Par { s: P.s * (-e).exp(), ..P }).ln()) / (2.0 * e);
    (ds, (fut_ode(t, Par { y: P.y + e, ..P }).ln() - fut_ode(t, Par { y: P.y - e, ..P }).ln()) / (2.0 * e))
}
fn cv(p1: f64, q1: f64, p2: f64, q2: f64) -> f64 { P.ss * P.ss * p1 * p2 + P.sy * P.sy * q1 * q2 + P.rho * P.ss * P.sy * (p1 * q2 + q1 * p2) }
fn row(v: &[f64], d: usize) -> String { v.iter().map(|x| format!("{:6.*}", d, x)).collect::<Vec<_>>().join(" ") }
fn main() {
    let (times, mut rng) = ([0.25, 0.5, 1.0, 2.0, 3.0, 5.0], Lcg(20261123));
    let sim = simulate(&mut rng, &times, 5000, 0.01);
    println!("inputs: spot 85, yield today 6%, level 3%, kappa 1.5, vols 30% and 25%, rho 0.8, r 5%");
    for t in [0.25, 1.0, 3.0] {
        let ([c, g, q, v], b, i1, i2) = terms(t, P);
        println!("by hand T = {}: B {:.4}  carry {:+.4}  yield gap {:+.4}  I1 {:.4}  rho term {:+.4}  I2 {:.4}  yield-var term {:+.4}  sum {:+.4}  F {:.4}",
                 t, b, c, g, i1, q, i2, v, c + g + q + v, fut(t, P));
    }
    println!("   T   closed form   ODE road   simulation  (s.e.)");
    for (i, &t) in times.iter().enumerate() { println!("{:4.2}  {:11.4}  {:9.4}  {:11.4}  ({:.4})", t, fut(t, P), fut_ode(t, P), sim[i].0, sim[i].1); }
    println!("   T   futures vol   by bumps   correlation with 3-month   by bumps");
    let mut rows = Vec::new();
    for &t in &times {
        let (_, vb, cr) = vol_corr(0.25, t, P);
        let ((sa, ya), (sb, yb)) = (bumps(0.25), bumps(t));
        let (bv, bc) = (cv(sb, yb, sb, yb).sqrt(), cv(sa, ya, sb, yb) / (cv(sa, ya, sa, ya) * cv(sb, yb, sb, yb)).sqrt());
        rows.push((vb, bv, cr, bc)); println!("{:4.2}  {:10.2}%  {:8.2}%  {:24.4}  {:9.4}", t, 100.0 * vb, 100.0 * bv, cr, bc);
    }
    println!("long-run futures vol sqrt(ss^2 - 2 rho ss sy / k + sy^2 / k^2)  {:.2}%", 100.0 * vol_corr(0.25, 60.0, P).1);
    let (n, dt) = (100000usize, 1.0 / 252.0);                   // third road: daily moves, sample correlation
    let (f25, f2, mut xs) = (fut(0.25, P), fut(2.0, P), Vec::with_capacity(n));
    for _ in 0..n {
        let (z1, z2) = rng.normals();
        let s1 = P.s * ((R - P.y - P.ss * P.ss / 2.0) * dt + P.ss * dt.sqrt() * z1).exp();
        let y1 = P.y + P.k * (P.al - P.y) * dt + P.sy * dt.sqrt() * z2;
        let q = Par { s: s1, y: y1, ..P }; xs.push(((fut(0.25 - dt, q) / f25).ln(), (fut(2.0 - dt, q) / f2).ln()));
    }
    let nf = n as f64;
    let (ma, mb) = (xs.iter().map(|p| p.0).sum::<f64>() / nf, xs.iter().map(|p| p.1).sum::<f64>() / nf);
    let sab = xs.iter().map(|p| (p.0 - ma) * (p.1 - mb)).sum::<f64>();
    let c_mc = sab / (xs.iter().map(|p| (p.0 - ma).powi(2)).sum::<f64>() * xs.iter().map(|p| (p.1 - mb).powi(2)).sum::<f64>()).sqrt();
    let c_th = vol_corr(0.25, 2.0, P).2; let se = (1.0 - c_th * c_th) / nf.sqrt();
    println!("3-month vs 2-year correlation: formula {:.4}  simulated daily moves {:.4}  (s.e. {:.4})", c_th, c_mc, se);
    println!("share of 2-year risk a 3-month hedge cannot remove, sqrt(1 - corr^2)  {:.1}%", 100.0 * (1.0 - c_th * c_th).sqrt());
    let one = fut(1.0, Par { s: 80.0, y: R - 0.045 + (80.0_f64 / 75.0).ln(), k: 1.0, al: R - 0.045, ss: 0.3, sy: 0.3, rho: 1.0 });
    println!("one-factor case (rho 1, sy = kappa ss), crude 80 toward 75, 1-year {:.4}; earlier card 78.3108", one);
    println!("3-month vs 2-year correlation, rho 1 and sy = kappa ss: {:.4};  sy = 0: {:.4}",
             vol_corr(0.25, 2.0, Par { k: 1.0, sy: 0.3, rho: 1.0, ..P }).2, vol_corr(0.25, 2.0, Par { sy: 0.0, ..P }).2);
    let jump = P.rho * P.sy / P.ss * 1.1_f64.ln();               // yield move that typically comes with a 10% spot rise
    let kicks = [("spot alone", Par { s: P.s * 1.1, ..P }), ("yield alone", Par { y: P.y + jump, ..P }), ("both", Par { s: P.s * 1.1, y: P.y + jump, ..P })];
    let mv = |t: f64, q: Par| 100.0 * (fut(t, q) / fut(t, P) - 1.0);   // percent change in the future after a kick
    println!("spot +10% with the typical yield move {:+.2} points; change in each future, kick by kick", 100.0 * jump);
    for t in [0.25, 1.0, 3.0] { println!("  T = {:4.2}  today {:.2}  {}", t, fut(t, P), kicks.iter().map(|&(l, q)| format!("{} {:+.2}%", l, mv(t, q))).collect::<Vec<_>>().join("  ")); }
    let grid: Vec<f64> = (0..11).map(|i| 0.5 * i as f64).collect(); println!("chart {:11} {}", "T", row(&grid, 1));
    for (l, q) in [("today", P), kicks[0], kicks[2]] { println!("chart {:11} {}", l, row(&grid.iter().map(|&t| fut(t, q)).collect::<Vec<_>>(), 2)); }
    for (l, q) in kicks { println!("move  {:11} {}", l, row(&grid.iter().map(|&t| mv(t, q)).collect::<Vec<_>>(), 2)); }
    let (st, sf) = ([0.25, 0.5, 1.0, 1.5, 2.0, 3.0, 4.0, 5.0], [84.78, 84.50, 84.09, 83.70, 83.42, 82.88, 82.33, 81.86]);
    let model = |t: f64, k: f64, y: f64, al: f64, rho: f64| fut(t, Par { k, y, al, rho, ..P }).ln();
    let sse = |k: f64, y: f64, al: f64, rho: f64| st.iter().zip(sf.iter()).map(|(&t, &f): (&f64, &f64)| (f.ln() - model(t, k, y, al, rho)).powi(2)).sum::<f64>();
    let best = |k: f64, rho: f64| {                             // for fixed kappa, ln F is a straight line in (y, al)
        let (mut p, mut q, mut u, mut g, mut h) = (0.0, 0.0, 0.0, 0.0, 0.0);
        for (&t, &f) in st.iter().zip(sf.iter()) {
            let (a, b, c) = (-bf(t, k), bf(t, k) - t, f.ln() - model(t, k, 0.0, 0.0, rho));
            p += a * a; q += a * b; u += b * b; g += a * c; h += b * c;
        }
        ((u * g - q * h) / (p * u - q * q), (p * h - q * g) / (p * u - q * q))
    };
    let (mut lo, mut hi, gr) = (0.2_f64, 6.0_f64, (5f64.sqrt() - 1.0) / 2.0);   // fit road 1: golden section
    for _ in 0..200 {
        let (c, d) = (hi - gr * (hi - lo), lo + gr * (hi - lo)); let (bc, bd) = (best(c, P.rho), best(d, P.rho)); if sse(c, bc.0, bc.1, P.rho) < sse(d, bd.0, bd.1, P.rho) { hi = d } else { lo = c }
    }
    let k1 = (lo + hi) / 2.0; let (y1, a1) = best(k1, P.rho);
    let (mut x, e) = ([1.0_f64, 0.03, 0.03], 1e-6);             // fit road 2: Gauss-Newton on all three at once
    for _ in 0..100 {
        let mut m = [[0.0_f64; 4]; 3];
        for (&t, &f) in st.iter().zip(sf.iter()) {
            let (r, mut jr) = (f.ln() - model(t, x[0], x[1], x[2], P.rho), [0.0; 3]);
            for j in 0..3 { let (mut up, mut dn) = (x, x); up[j] += e; dn[j] -= e;
                jr[j] = (model(t, up[0], up[1], up[2], P.rho) - model(t, dn[0], dn[1], dn[2], P.rho)) / (2.0 * e); }
            for a in 0..3 { for b in 0..3 { m[a][b] += jr[a] * jr[b]; } m[a][3] += jr[a] * r; }
        }
        for (a, b) in [(0, 1), (0, 2), (1, 2)] {                // Gaussian elimination on the 3 x 3 normal equations
            let f = m[b][a] / m[a][a]; for c in 0..4 { m[b][c] -= f * m[a][c]; }
        }
        let mut dx = [0.0; 3]; for a in [2, 1, 0] { dx[a] = (m[a][3] - (a + 1..3).map(|b| m[a][b] * dx[b]).sum::<f64>()) / m[a][a]; }
        let mut step = 1.0;                                     // halve the step until the error falls
        while step > 1e-9 && (x[0] + step * dx[0] <= 0.0 || sse(x[0] + step * dx[0], x[1] + step * dx[1], x[2] + step * dx[2], P.rho) > sse(x[0], x[1], x[2], P.rho)) { step /= 2.0; }
        for i in 0..3 { x[i] += step * dx[i]; }
    }
    println!("fit, golden section: kappa {:.4}  yield today {:.3}%  level {:.3}%  rms log error {:.6}", k1, 100.0 * y1, 100.0 * a1, (sse(k1, y1, a1, P.rho) / 8.0).sqrt());
    println!("fit, Gauss-Newton:   kappa {:.4}  yield today {:.3}%  level {:.3}%  rms log error {:.6}", x[0], 100.0 * x[1], 100.0 * x[2], (sse(x[0], x[1], x[2], P.rho) / 8.0).sqrt());
    let held: Vec<f64> = [1.0, 1.5, 3.0].iter().map(|&k| { let (y, a) = best(k, P.rho); sse(k, y, a, P.rho) }).collect();
    println!("fit, rms log error with kappa held at 1.0 / 1.5 / 3.0: {}  ({} times the best)", held.iter().map(|h| format!("{:.6}", (h / 8.0).sqrt())).collect::<Vec<_>>().join(" / "),
             held.iter().map(|h| format!("{:.2}", (h / sse(k1, y1, a1, P.rho)).sqrt())).collect::<Vec<_>>().join(" / "));
    let (y0, a0) = best(k1, 0.0);                               // the same strip and speed, fitted as if rho were 0
    println!("fit with rho 0, kappa {:.4}: yield today {:.3}%  level {:.3}%  rms log error {:.6};  level shift {:.2} points, rho ss sy / kappa {:.2}",
             k1, 100.0 * y0, 100.0 * a0, (sse(k1, y0, a0, 0.0) / 8.0).sqrt(), 100.0 * (a0 - a1), 100.0 * P.rho * P.ss * P.sy / k1);
    println!("strip quotes  {}", row(&sf, 2));
    println!("fitted curve  {}", row(&st.iter().map(|&t| fut(t, Par { k: k1, y: y1, al: a1, ..P })).collect::<Vec<_>>(), 2));
    println!("wrong: drop both variance terms, 3-year      {:10.4}", P.s * (terms(3.0, P).0[0] + terms(3.0, P).0[1]).exp());
    println!("wrong: drop the correlation term, 3-year     {:10.4}", fut(3.0, Par { rho: 0.0, ..P }));
    println!("wrong: carry with yield fixed at 6%, 3-year  {:10.4}", P.s * ((R - P.y) * 3.0).exp());
    println!("wrong: carry with yield fixed at 3%, 3-year  {:10.4}", P.s * ((R - P.al) * 3.0).exp());
    println!("try: rho = 0, 3-month vs 2-year correlation      {:.4}", vol_corr(0.25, 2.0, Par { rho: 0.0, ..P }).2);
    println!("try: kappa = 0.5, 3-month vs 2-year correlation  {:.4}", vol_corr(0.25, 2.0, Par { k: 0.5, ..P }).2);
    println!("try: kappa = 0.5, 3-year future                  {:.4}", fut(3.0, Par { k: 0.5, ..P }));
    println!("try: yield today 3%, 1-year future               {:.4}", fut(1.0, Par { y: 0.03, ..P }));
    for (i, &t) in times.iter().enumerate() {
        assert!((fut(t, P) - fut_ode(t, P)).abs() < 1e-6, "closed form vs Runge-Kutta moments");
        assert!((sim[i].0 - fut(t, P)).abs() < 4.0 * sim[i].1, "simulation within four standard errors");
    }
    for &(vb, bv, cr, bc) in &rows { assert!((vb - bv).abs() < 1e-6 && (cr - bc).abs() < 1e-6, "futures vol and correlation vs bumps"); }
    assert!((c_mc - c_th).abs() < 4.0 * se, "correlation vs simulated daily moves");
    assert!((one - 78.3108).abs() < 1e-4, "one-factor special case reproduces the earlier card");
    assert!((k1 - x[0]).abs() < 1e-4, "two fits agree on kappa");
    assert!((y1 - P.y).abs() < 0.002 && (a1 - P.al).abs() < 0.002 && (k1 - P.k).abs() < 0.25, "fit recovers the settings the strip was built from");
    assert!((a0 - a1 - P.rho * P.ss * P.sy / k1).abs() < 1e-9 && (sse(k1, y0, a0, 0.0) - sse(k1, y1, a1, P.rho)).abs() < 1e-15, "rho 0: the level absorbs rho ss sy / kappa");
    println!("ALL CHECKS PASS");
}
