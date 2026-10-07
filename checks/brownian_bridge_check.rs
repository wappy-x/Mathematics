// Brownian bridge -- the same check as brownian_bridge_check.py.  Standard library only, no crates.
// A simulated pollen grain: position W_t in micrometres, t in seconds, Var W_t = t.  Pinned at W_0 = 0 and W_10 = 2.
// Road 1: the bridge formulas.  Road 2: Gaussian conditioning by linear algebra, Cov(W_s, W_t) = min(s, t).
// Road 3: a coin-flip walk pinned at both ends, counted exactly, at three step sizes.
// Road 4: seeded simulations (SplitMix64 and Box-Muller, written out): selection, construction, refinement.
const T: f64 = 10.0; const B: f64 = 2.0;
fn nsum<I: IntoIterator<Item = f64>>(it: I) -> f64 {     // compensated sum, the rule Python's sum() uses
    let (mut s, mut c) = (0.0f64, 0.0f64);
    for x in it { let t = s + x; c += if s.abs() >= x.abs() { (s - t) + x } else { (x - t) + s }; s = t; }
    if c != 0.0 && c.is_finite() { s + c } else { s }
}
fn mean_f(t: f64, a: f64, b: f64, t1: f64, t2: f64) -> f64 { a + (t - t1) / (t2 - t1) * (b - a) }
fn cov_f(s: f64, t: f64, t1: f64, t2: f64) -> f64 { (s.min(t) - t1) * (t2 - s.max(t)) / (t2 - t1) }
fn m0(t: f64) -> f64 { mean_f(t, 0.0, B, 0.0, T) }
fn c0(s: f64, t: f64) -> f64 { cov_f(s, t, 0.0, T) }
fn phi_cdf(x: f64) -> f64 {                               // Simpson's rule on the bell curve from 0 to x
    let (m, h) = (2000, x / 2000.0);
    0.5 + h / 3.0 * nsum((0..=m).map(|i| (if i == 0 || i == m { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 }) * (-(i as f64 * h) * (i as f64 * h) / 2.0).exp())) / (2.0 * std::f64::consts::PI).sqrt()
}
fn solve(a: &Vec<Vec<f64>>, y: &Vec<Vec<f64>>) -> Vec<Vec<f64>> {   // Gauss-Jordan with partial pivoting
    let n = a.len();
    let mut m: Vec<Vec<f64>> = (0..n).map(|i| { let mut r = a[i].clone(); r.extend(y.iter().map(|c| c[i])); r }).collect();
    for c in 0..n {
        let mut p = c;
        for r in c..n { if m[r][c].abs() > m[p][c].abs() { p = r; } } m.swap(c, p);
        for r in 0..n {
            if r != c { let f = m[r][c] / m[c][c]; let pc = m[c].clone(); for (x, yv) in m[r].iter_mut().zip(pc.iter()) { *x = *x - f * yv; } }
        }
    }
    (0..y.len()).map(|j| (0..n).map(|i| m[i][n + j] / m[i][i]).collect()).collect()
}
fn condition(targets: &[f64], given: &[f64]) -> (Vec<Vec<f64>>, Vec<Vec<f64>>) {
    let s22: Vec<Vec<f64>> = given.iter().map(|&a| given.iter().map(|&b| a.min(b)).collect()).collect();
    let s21: Vec<Vec<f64>> = targets.iter().map(|&t| given.iter().map(|&g| t.min(g)).collect()).collect();
    let w = solve(&s22, &s21);
    let c = targets.iter().enumerate().map(|(i, &s)| targets.iter().map(|&t| s.min(t) - nsum(w[i].iter().zip(given).map(|(wv, &g)| wv * g.min(t)))).collect()).collect();
    (w, c)
}
fn walk_bridge(n: usize, lf: &Vec<f64>) -> (f64, f64, f64) {
    let h = (T / n as f64).sqrt(); let m = (B / h).round() as usize; let (k, u) = (4 * n / 10, (n + m) / 2);
    let lo = if u > n - k { u - (n - k) } else { 0 };
    let ps: Vec<(f64, f64)> = (lo..=k.min(u)).map(|up| ((2 * up) as f64 - k as f64,
        (lf[k] - lf[up] - lf[k - up] + lf[n - k] - lf[u - up] - lf[n - k - u + up] - lf[n] + lf[u] + lf[n - u]).exp())).collect();
    let mu = nsum(ps.iter().map(|&(j, p)| p * j * h));
    (nsum(ps.iter().map(|&(_, p)| p)), mu, nsum(ps.iter().map(|&(j, p)| p * ((j * h) * (j * h)))) - mu * mu)
}
struct Rng(u64);
impl Rng {
    fn unif(&mut self) -> f64 {                           // SplitMix64, top 53 bits, never exactly 0 or 1
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        (((z ^ (z >> 31)) >> 11) as f64 + 0.5) / 2f64.powi(53)
    }
    fn normal(&mut self) -> f64 { let r = (-2.0 * self.unif().ln()).sqrt(); r * (2.0 * std::f64::consts::PI * self.unif()).cos() }
}
fn select(r: &mut Rng, drift: f64) -> [f64; 7] {
    let mut acc = vec![];
    for _ in 0..500000 {
        let w4 = 4.0 * drift + 2.0 * r.normal(); let w10 = w4 + 6.0 * drift + 6f64.sqrt() * r.normal();
        if (w10 - B).abs() < 0.1 { acc.push(w4); }
    }
    let k = acc.len() as f64; let mu = nsum(acc.iter().cloned()) / k;
    let var = nsum(acc.iter().map(|x| (x - mu) * (x - mu))) / (k - 1.0);
    let lo = acc.iter().filter(|&&x| x < 0.0).count() as f64 / k;
    [k, mu, (var / k).sqrt(), var, var * (2.0 / (k - 1.0)).sqrt(), lo, (lo * (1.0 - lo) / k).sqrt()]
}
fn refine(r: &mut Rng, path: &Vec<f64>, sd: f64) -> Vec<f64> {
    let mut out = vec![path[0]];
    for i in 0..path.len() - 1 { out.push((path[i] + path[i + 1]) / 2.0 + sd * r.normal()); out.push(path[i + 1]); } out
}
fn qv(p: &Vec<f64>) -> f64 { nsum((0..p.len() - 1).map(|i| (p[i + 1] - p[i]) * (p[i + 1] - p[i]))) }
fn join(v: &[f64], f: impl Fn(f64) -> String) -> String { v.iter().map(|&x| f(x)).collect::<Vec<_>>().join(" ") }

fn main() {
    let sd4 = c0(4.0, 4.0).sqrt();
    println!("pinned W_0 = 0, W_10 = 2, at t = 4: mean (t/T) b {:.6}  var t(T-t)/T {:.6}  sd {:.6}", m0(4.0), c0(4.0, 4.0), sd4);
    let (w, c) = condition(&[4.0, 3.0, 7.0], &[T]);
    println!("road 2, given W_10: weight on W_10 {:.6}, mean {:.6}, var {:.6}", w[0][0], w[0][0] * B, c[0][0]);
    println!("Cov(W_3, W_7 | W_10 = 2): formula s(T-t)/T {:.6}; road 2 {:.6}", c0(3.0, 7.0), c[1][2]);
    let z = -m0(4.0) / sd4;
    println!("P(W_4 < 0 | W_10 = 2) = Phi({:.6}) = {:.6}; wrong var 4: Phi({:.6}) = {:.6}", z, phi_cdf(z), -m0(4.0) / 2.0, phi_cdf(-m0(4.0) / 2.0));
    let (wf, cf) = condition(&[4.5], &(1..11).map(|i| i as f64).collect::<Vec<_>>());
    println!("fill 4.5 s between 1.3 at 4 s and 0.5 at 5 s: mean {:.6} sd {:.6}", mean_f(4.5, 1.3, 0.5, 4.0, 5.0), cov_f(4.5, 4.5, 4.0, 5.0).sqrt());
    let rec = [0.4, -0.2, 0.7, 1.3, 0.5, 1.1, -0.6, 0.2, 0.9, 2.0];   // a record with 1.3 at 4 s and 0.5 at 5 s
    let mf = nsum(wf[0].iter().zip(rec.iter()).map(|(w, v)| w * v));
    println!("road 2, weights on W_1..W_10 {}; mean {:.6} var {:.6}", join(&wf[0], |x| format!("{:.3}", x)), mf, cf[0][0]);
    println!("chance the path touched 2 inside that second, exp(-2 (2-1.3)(2-0.5)/1) = {:.6}", (-2.0f64 * 0.7 * 1.5).exp());
    println!("coin-flip walk pinned at 2, at t = 4    steps n   total chance   mean      var       error");
    let mut lf = vec![0.0f64]; for i in 1..1001 { let l = lf[i - 1] + (i as f64).ln(); lf.push(l); }
    let walk: Vec<(f64, f64, f64)> = [10usize, 90, 1000].iter().map(|&n| walk_bridge(n, &lf)).collect();
    for (n, &(tot, mu, var)) in [10, 90, 1000].iter().zip(walk.iter()) { println!("{:<40}{:>7}{:>12.6}{:>11.6}{:>10.6}{:>10.6}", "", n, tot, mu, var, var - 2.4); }
    println!("selection, 500000 free paths   kept   mean W_4   se       var W_4   se       P(W_4 < 0)  se");
    let mut rng = Rng(20260930);
    let sel: Vec<[f64; 7]> = [0.0, 0.3].iter().map(|&d| select(&mut rng, d)).collect();
    for (d, s) in [0.0, 0.3].iter().zip(sel.iter()) {
        println!("  drift {:.1} per second  {:>11}{}", d, s[0] as usize, s[1..].iter().map(|x| format!("{:>10.6}", x)).collect::<String>());
    }
    let np = 100000usize;
    let (mut s1, mut s2, mut s37) = (vec![0.0f64; 11], vec![0.0f64; 11], 0.0f64);
    for _ in 0..np {
        let mut w = vec![0.0f64];
        for _ in 0..10 { let x = w[w.len() - 1] + rng.normal(); w.push(x); }
        let br: Vec<f64> = (0..11).map(|i| w[i] - i as f64 / T * w[10] + i as f64 / T * B).collect();
        for i in 0..11 { s1[i] += br[i]; s2[i] += br[i] * br[i]; }
        s37 += br[3] * br[7];
    }
    let npf = np as f64; let vs: Vec<f64> = (0..11).map(|i| s2[i] / npf - (s1[i] / npf) * (s1[i] / npf)).collect();
    let c37 = s37 / npf - s1[3] * s1[7] / (npf * npf); let se37 = ((vs[3] * vs[7] + c37 * c37) / npf).sqrt();
    println!("construction, {} paths: Cov(B_3, B_7) {:.6} se {:.6}; mean B_4 {:.6} se {:.6}", np, c37, se37, s1[4] / npf, (vs[4] / npf).sqrt());
    println!(" t   free var t   bridge formula   road 2     simulated   se");
    let road2 = condition(&(1..10).map(|t| t as f64).collect::<Vec<_>>(), &[T]).1;
    for t in 1..10 {
        let tf = t as f64; println!("{:>2}{:>12.6}{:>16.6}{:>11.6}{:>13.6}{:>9.6}", t, tf, c0(tf, tf), road2[t - 1][t - 1], vs[t], vs[t] * (2.0 / npf).sqrt());
    }
    let nr = 20000usize;
    let keys = ["bridge, half", "bridge, quarter", "straight lines, half", "straight lines, quarter", "free var 0.5, half"];
    let mut tot: Vec<Vec<f64>> = vec![vec![]; 5];
    let (mut lag, mut cnt) = (0.0f64, 0.0f64);
    let mut fig = (vec![], vec![]);
    for p in 0..nr {
        let mut w = vec![0.0f64];
        for _ in 0..10 { let x = w[w.len() - 1] + rng.normal(); w.push(x); }
        let half = refine(&mut rng, &w, 0.5); let quarter = refine(&mut rng, &half, 0.125f64.sqrt());
        let wrong = refine(&mut rng, &w, 0.5f64.sqrt());
        let line_h = refine(&mut rng, &w, 0.0); let line_q = refine(&mut rng, &line_h, 0.0);
        for (i, path) in [&half, &quarter, &line_h, &line_q, &wrong].iter().enumerate() { tot[i].push(qv(path)); }
        let d: Vec<f64> = (0..quarter.len() - 1).map(|i| quarter[i + 1] - quarter[i]).collect();
        lag += nsum((0..d.len() - 1).map(|i| d[i] * d[i + 1])); cnt += (d.len() - 1) as f64;
        if p == 0 { fig = (line_h.clone(), half.clone()); }
    }
    println!("refinement, 20000 coarse paths   squared steps summed over 10 s   se       exact");
    let (exact, nrf, mut ms) = ([10.0, 10.0, 5.0, 2.5, 15.0], nr as f64, vec![]);
    for i in 0..5 {
        let m = nsum(tot[i].iter().cloned()) / nrf;
        let s = ((nsum(tot[i].iter().map(|x| x * x)) / nrf - m * m) / nrf).sqrt();
        ms.push((m, s));
        println!("  {:<34}{:>15.6}{:>13.6}{:>9.1}", keys[i], m, s, exact[i]);
    }
    let rho = lag / cnt / 0.25;
    println!("  bridge, quarter: correlation of neighbouring steps {:.6} se {:.6}", rho, 1.0 / cnt.sqrt());
    println!("chart, time    {}", join(&(0..21).map(|i| i as f64 / 2.0).collect::<Vec<_>>(), |x| format!("{:5.1}", x)));
    println!("chart, straight{}", join(&fig.0, |x| format!("{:6.2}", x)));
    println!("chart, filled  {}", join(&fig.1, |x| format!("{:6.2}", x)));
    println!("chart, var free   {}", join(&(0..11).map(|t| t as f64).collect::<Vec<_>>(), |x| format!("{:5.2}", x)));
    println!("chart, var bridge {}", join(&(0..11).map(|t| c0(t as f64, t as f64)).collect::<Vec<_>>(), |x| format!("{:5.2}", x)));
    println!("chart, var sim    {}", join(&vs, |x| format!("{:5.2}", x)));
    println!("try: pin at -3, mean at 4 s {:.6} var {:.6}; midpoint of a 10 s gap sd {:.6}; var rate 4, var at 4 s {:.6}",
        mean_f(4.0, 0.0, -3.0, 0.0, T), c0(4.0, 4.0), c0(5.0, 5.0).sqrt(), 4.0 * c0(4.0, 4.0));

    assert!((1..10).all(|t| (road2[t - 1][t - 1] - c0(t as f64, t as f64)).abs() < 1e-12) && (c[1][2] - c0(3.0, 7.0)).abs() < 1e-12, "road 2 vs formula");
    assert!((wf[0][3] - 0.5).abs() < 1e-12 && (wf[0][4] - 0.5).abs() < 1e-12 && [0, 1, 2, 5, 6, 7, 8, 9].iter().all(|&i| wf[0][i].abs() < 1e-12), "neighbours only");
    assert!((cf[0][0] - cov_f(4.5, 4.5, 4.0, 5.0)).abs() < 1e-12 && (mf - mean_f(4.5, 1.3, 0.5, 4.0, 5.0)).abs() < 1e-12, "fill-in: linear algebra vs bridge between neighbours");
    let errs: Vec<f64> = walk.iter().map(|w| w.2 - c0(4.0, 4.0)).collect();
    assert!(errs[0] > errs[1] && errs[1] > errs[2] && errs[2] > 0.0 && errs[2] < 0.002 && walk.iter().all(|w| (w.1 - m0(4.0)).abs() < 1e-9), "walk bridge converges");
    for s in &sel {
        assert!((s[1] - m0(4.0)).abs() < 4.0 * s[2] && (s[3] - c0(4.0, 4.0)).abs() < 4.0 * s[4] && (s[5] - phi_cdf(z)).abs() < 4.0 * s[6], "selection vs formula");
    }
    assert!((1..10).all(|t| (vs[t] - c0(t as f64, t as f64)).abs() < 4.0 * vs[t] * (2.0 / npf).sqrt()) && (c37 - c0(3.0, 7.0)).abs() < 4.0 * se37, "construction");
    for i in 0..5 { assert!((ms[i].0 - exact[i]).abs() < 4.0 * ms[i].1, "squared steps summed vs exact"); }
    assert!(rho.abs() < 4.0 / cnt.sqrt(), "refined steps uncorrelated");
    println!("ALL CHECKS PASS");
}
