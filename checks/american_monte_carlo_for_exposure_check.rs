// American Monte Carlo for exposure -- the same check as the Python, in Rust.  No crates.  The Acme
// call Northwind sold to the bank, then a down-and-out call.  Nothing imported knows an answer: the
// random numbers, normal curve, least-squares fit, Black-Scholes and the barrier grid are written out.
use std::f64::consts::PI;
const S0: f64 = 100.0; const K: f64 = 100.0; const R: f64 = 0.05; const Q: f64 = 0.02;
const SIG: f64 = 0.20; const T: f64 = 1.0; const B: f64 = 90.0; const L: usize = 12;   // barrier $90
const NP: usize = 50000; const G: usize = 1200; const NZ: usize = 200;
fn uniform(s: &mut u64) -> f64 {                  // 64-bit congruential generator, wrapping
    *s = s.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
    ((*s >> 11) as f64) * (1.0 / 9007199254740992.0)
}
fn normal(s: &mut u64) -> f64 {                   // Box-Muller: two uniforms, one bell draw
    let mut u1 = uniform(s); if u1 == 0.0 { u1 = 1e-300 }
    (-2.0 * u1.ln()).sqrt() * (2.0 * PI * uniform(s)).cos()
}
fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }
fn n_cdf(x: f64) -> f64 {                         // 1/2 + phi(x)(x + x^3/3 + x^5/15 + ...)
    if x < -9.0 { return 0.0 } if x > 9.0 { return 1.0 }
    let (mut term, mut total, mut k) = (x, x, 1.0);
    while term.abs() > 1e-17 * total.abs() { k += 2.0; term *= x * x / k; total += term }
    0.5 + phi(x) * total
}
fn fit(xs: &[f64], ys: &[f64], m: usize) -> Vec<f64> {   // least squares, as on the Longstaff-Schwartz
    let mut mom = vec![0.0; 2 * m - 1]; let mut rhs = vec![0.0; 2 * m - 1];  // card: normal equations,
    for (x, y) in xs.iter().zip(ys.iter()) { let mut p = 1.0;             // then pivoted elimination
        for k in 0..2 * m - 1 { mom[k] += p; rhs[k] += p * y; p *= x } }
    let mut mm: Vec<Vec<f64>> = (0..m).map(|i| (0..=m).map(|j| if j < m { mom[i + j] } else { rhs[i] }).collect()).collect();
    for c in 0..m {
        let mut p = c; for k in c + 1..m { if mm[k][c].abs() > mm[p][c].abs() { p = k } } mm.swap(c, p);
        for k in c + 1..m { let f = mm[k][c] / mm[c][c];
            let row: Vec<f64> = (0..=m).map(|j| mm[k][j] - f * mm[c][j]).collect(); mm[k] = row }
    }
    let mut b = vec![0.0; m];
    for i in (0..m).rev() { let mut s = 0.0; for j in i + 1..m { s += mm[i][j] * b[j] } b[i] = (mm[i][m] - s) / mm[i][i] }
    b
}
fn curve(b: &[f64], x: f64) -> f64 { let mut o = 0.0; for c in b.iter().rev() { o = o * x + c } o }   // Horner
fn call(s: f64, tau: f64) -> f64 {                // Black-Scholes value, tau years left
    if tau <= 0.0 { return (s - K).max(0.0) }
    let v = SIG * tau.sqrt(); let d1 = ((s / K).ln() + (R - Q + 0.5 * SIG * SIG) * tau) / v;
    s * (-Q * tau).exp() * n_cdf(d1) - K * (-R * tau).exp() * n_cdf(d1 - v)
}
fn alive(p: &[f64], j: usize) -> bool { (1..=j).all(|i| p[i] > B) }      // barrier checked on month-ends
fn q95(v: &[f64]) -> f64 { let mut w = v.to_vec(); w.sort_by(|a, b| a.partial_cmp(b).unwrap()); w[(95 * w.len() + 99) / 100 - 1] }
fn mean(v: &[f64]) -> f64 { let mut s = 0.0; for x in v { s += x } s / v.len() as f64 }
fn rms(a: &[f64], c: &[f64]) -> f64 { mean(&a.iter().zip(c).map(|(x, y)| (x - y) * (x - y)).collect::<Vec<f64>>()).sqrt() }
struct Grid { lo: f64, hg: f64, vg: Vec<Vec<f64>> }
impl Grid {                                       // the barrier's value marched back on log prices
    fn look(&self, s: f64, tau: f64, v: &[f64]) -> f64 {
        let mut y = (s.ln() - self.lo) / self.hg;           // the first node sits on the barrier:
        if y < -1e-9 { return 0.0 } y = y.max(0.0);            // only a price clearly below is out
        if y >= (G - 1) as f64 { return s * (-Q * tau).exp() - K * (-R * tau).exp() }
        let i = y as usize; let f = y - i as f64; v[i] * (1.0 - f) + v[i + 1] * f
    }
    fn back(&self, bb: f64, v: &[f64], s: f64, tau: f64, mu: f64, vol: f64) -> f64 {
        let za = (((bb / s).ln() - mu) / vol).max(-8.0);
        if za >= 8.0 { return 0.0 }
        let h = (8.0 - za) / NZ as f64; let mut tot = 0.0;
        for i in 0..=NZ {
            let z = za + i as f64 * h; let w = if i == 0 || i == NZ { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 };
            tot += w * phi(z) * self.look(s * (mu + vol * z).exp(), tau, v);
        }
        (-R * (T / L as f64)).exp() * tot * h / 3.0
    }
}
fn grid(bb: f64, mu: f64, vol: f64) -> (Grid, f64) {
    let dt = T / L as f64; let lo = bb.ln(); let hg = ((5.0 * S0).ln() - lo) / (G - 1) as f64;
    let mut g = Grid { lo, hg, vg: vec![vec![0.0; G]; L + 1] };
    g.vg[L] = (0..G).map(|i| ((lo + i as f64 * hg).exp() - K).max(0.0)).collect();
    for j in (1..L).rev() {
        let row: Vec<f64> = (0..G).map(|i| g.back(bb, &g.vg[j + 1], (lo + i as f64 * hg).exp(), T - (j + 1) as f64 * dt, mu, vol)).collect();
        g.vg[j] = row;
    }
    let p = g.back(bb, &g.vg[1], S0, T - dt, mu, vol); (g, p)
}
fn main() {
    let dt = T / L as f64; let mu = (R - Q - 0.5 * SIG * SIG) * dt; let vol = SIG * dt.sqrt();
    let mut seed = 20261123u64;                   // 50,000 paths to fit on, 50,000 fresh ones to use
    let mut path = || { let mut x = S0; let mut row = vec![x];
        for _ in 0..L { x *= (mu + vol * normal(&mut seed)).exp(); row.push(x) } row };
    let train: Vec<Vec<f64>> = (0..NP).map(|_| path()).collect(); let usep: Vec<Vec<f64>> = (0..NP).map(|_| path()).collect();
    let amc = |j: usize, m: usize, barrier: bool, disc: bool, val: Option<&dyn Fn(f64) -> f64>| -> (Vec<f64>, Vec<f64>) {
        // fit on train, revalue use; val: fit the exact values instead, for the best fit
        let tau = T - j as f64 * dt; let pts: Vec<&Vec<f64>> = train.iter().filter(|p| !barrier || alive(p, j)).collect();
        let pay = |p: &Vec<f64>| (p[L] - K).max(0.0) * (if !barrier || alive(p, L) { 1.0 } else { 0.0 });
        let xs: Vec<f64> = pts.iter().map(|p| p[j] / K).collect();
        let ys: Vec<f64> = pts.iter().map(|p| match val { Some(f) => f(p[j]), None => pay(p) * (if disc { (-R * tau).exp() } else { 1.0 }) }).collect();
        let b = fit(&xs, &ys, m);
        let est = usep.iter().map(|p| if !barrier || alive(p, j) { curve(&b, p[j] / K).max(0.0) } else { 0.0 }).collect();
        (b, est)
    };
    let c0 = call(S0, T); let z95 = 1.6448536269514722_f64;   // the 95% normal quantile
    println!("Acme call bought from Northwind: 12 month-ends, fit on 1, x, x^2 with x = S/K");
    println!("{:>5}{:>10}{:>9}{:>8}{:>12}{:>10}{:>9}", "month", "EE closed", "EE exact", "EE AMC", "PFE95 exact", "PFE95 AMC", "RMS miss");
    let mut van: Vec<[f64; 9]> = vec![];
    for j in 1..=L {
        let u = j as f64 * dt; let ex: Vec<f64> = usep.iter().map(|p| call(p[j], T - u)).collect();
        let (b, est) = if j < L { amc(j, 3, false, true, None) } else { (vec![], ex.clone()) };   // at expiry: the payoff
        let ide = if j < L { amc(j, b.len(), false, true, Some(&|s: f64| call(s, T - u))).1 } else { ex.clone() };   // best fit
        let t = [u, c0 * (R * u).exp(), mean(&ex), mean(&est), q95(&ex), q95(&est), rms(&est, &ex), mean(&ide), q95(&ide)];
        println!("{:5}{:10.4}{:9.4}{:8.4}{:12.4}{:10.4}{:9.4}", j, t[1], t[2], t[3], t[4], t[5], t[6]); van.push(t);
    }
    let ex6: Vec<f64> = usep.iter().map(|p| call(p[6], 0.5)).collect();
    let b6 = amc(6, 3, false, true, None).0; let s95 = S0 * (mu * 6.0 + SIG * 0.5_f64.sqrt() * z95).exp();
    let b6i = amc(6, 3, false, true, Some(&|s: f64| call(s, 0.5))).0;   // the best parabola: fitted to exact values
    let pts6: Vec<f64> = train.iter().map(|p| p[6] / K).collect();
    let y6: Vec<f64> = train.iter().map(|p| (p[L] - K).max(0.0) * (-R * 0.5).exp()).collect();
    let fit_mean = mean(&pts6.iter().map(|&x| curve(&b6, x)).collect::<Vec<f64>>());
    for (name, x) in [("call today C0", c0), ("six months: b0", b6[0]), ("  b1", b6[1]), ("  b2", b6[2]),
        ("  fit at S = 100", curve(&b6, 1.0)), ("  Black-Scholes at S = 100", call(100.0, 0.5)),
        ("  Acme at its 95th percentile", s95), ("  fit there", curve(&b6, s95 / K)), ("  Black-Scholes there", call(s95, 0.5)),
        ("  in-sample mean of fit", fit_mean), ("  in-sample mean of Y", mean(&y6)),
        ("  fitting paths' price, Y e^(-r/2)", mean(&y6) * (-R * 0.5).exp()), ("  fresh paths' price", mean(&ex6) * (-R * 0.5).exp())] {
        println!("{:<34}{:10.4}", name, x);
    }
    let gr: Vec<f64> = (0..8).map(|i| 70.0 + 10.0 * i as f64).collect();
    println!("six months, S:      {}", gr.iter().map(|g| format!("{:7.0}", g)).collect::<String>());
    println!("  fitted value:     {}", gr.iter().map(|g| format!("{:7.2}", curve(&b6, g / K))).collect::<String>());
    println!("  Black-Scholes:    {}", gr.iter().map(|g| format!("{:7.2}", call(*g, 0.5))).collect::<String>());
    println!("six months, by basis   EE      PFE95   RMS miss");
    let mut basis = [0.0; 5];
    for (m, name) in [(1usize, "1"), (2, "1, x"), (3, "1, x, x^2"), (4, "1, x, x^2, x^3")] {
        let e = amc(6, m, false, true, None).1; basis[m] = rms(&e, &ex6);
        println!("  {:<18}{:8.4}{:9.4}{:9.4}", name, mean(&e), q95(&e), basis[m]);
    }
    let peek: Vec<f64> = usep.iter().map(|p| (p[L] - K).max(0.0) * (-R * 0.5).exp()).collect();   // own future
    let nod = amc(6, 3, false, false, None).1;
    for (name, x) in [("mistake: own future, PFE95", q95(&peek)), ("mistake: own future, EE", mean(&peek)),
                      ("mistake: no discounting, EE", mean(&nod))] { println!("{:<34}{:10.4}", name, x) }
    println!("nested simulation instead, 1000 inner paths per path per date: {} inner paths", NP * (L - 1) * 1000);
    let (g, bar0) = grid(B, mu, vol); let bar_lo = grid(50.0, mu, vol).1;
    let dpay: Vec<f64> = usep.iter().map(|p| (-R * T).exp() * (p[L] - K).max(0.0) * (if alive(p, L) { 1.0 } else { 0.0 })).collect();
    let bmc = mean(&dpay); let bse = (mean(&dpay.iter().map(|x| (x - bmc) * (x - bmc)).collect::<Vec<f64>>()) / (NP - 1) as f64).sqrt();
    println!("down-and-out call, barrier {:.0} on month-ends: price by grid {:.4}, by paths {:.4} +/- {:.4}", B, bar0, bmc, bse);
    println!("  grid with the barrier moved to $50: {:.4}, Black-Scholes {:.4}", bar_lo, c0);
    println!("{:>5}{:>7}{:>9}{:>8}{:>8}{:>11}{:>10}{:>9}", "month", "alive", "EE grid", "EE AMC", "disc EE", "PFE95 grid", "PFE95 AMC", "RMS miss");
    let mut bar: Vec<[f64; 8]> = vec![];
    for j in 1..=L {
        let u = j as f64 * dt; let al: Vec<bool> = usep.iter().map(|p| alive(p, j)).collect();
        let ex: Vec<f64> = usep.iter().zip(&al).map(|(p, &a)| if a { g.look(p[j], T - u, &g.vg[j]) } else { 0.0 }).collect();
        let est = if j < L { amc(j, 3, true, true, None).1 } else { ex.clone() };
        let ide = if j < L { amc(j, 3, true, true, Some(&|s: f64| g.look(s, T - u, &g.vg[j]))).1 } else { ex.clone() };
        let (mut ss, mut na) = (0.0, 0usize);
        for i in 0..NP { if al[i] { ss += (est[i] - ex[i]) * (est[i] - ex[i]); na += 1 } }
        let t = [na as f64 / NP as f64, mean(&ex), mean(&est), mean(&ex) * (-R * u).exp(), q95(&ex), q95(&est), (ss / na as f64).sqrt(), mean(&ide)];
        println!("{:5}{:7.4}{:9.4}{:8.4}{:8.4}{:11.4}{:10.4}{:9.4}", j, t[0], t[1], t[2], t[3], t[4], t[5], t[6]); bar.push(t);
    }
    for t in &van[..L - 1] {                      // against the best fit: only luck is left
        assert!((t[3] - t[7]).abs() < 0.25, "regression EE near the best parabola's: the payoff's luck averages out");
        assert!((t[2] - t[1]).abs() < 0.20, "exact revaluation EE near the closed form C0 e^(ru)");
        assert!((t[5] - t[8]).abs() < 0.8, "regression PFE near the best parabola's");
    }
    assert!((call(s95, 0.5) - 28.2603).abs() < 1e-3 && (curve(&b6, s95 / K) - curve(&b6i, s95 / K)).abs() < 0.8, "six-month PFE");
    assert!((fit_mean - mean(&y6)).abs() < 1e-9, "a fit with a constant matches the mean");
    assert!(basis[1] > basis[2] && basis[2] > basis[3] && basis[3] > basis[4] && van[5][6] < 1.0, "more terms, smaller miss");
    assert!(q95(&peek) > van[5][4] + 5.0, "a path's own future overstates PFE");
    assert!((bar_lo - c0).abs() < 2e-3, "the grid with no barrier in reach is Black-Scholes");
    assert!((bar0 - bmc).abs() < 3.0 * bse && bar0 < c0 - 0.5, "grid barrier price agrees with the paths");
    for t in &bar[..L - 1] {
        assert!((t[3] - bar0).abs() < 0.25, "discounted barrier EE stays at today's price");
        assert!((t[2] - t[7]).abs() < 0.25, "regression barrier EE near the best fit to the grid's values");
    }
    println!("ALL CHECKS PASS");
}
