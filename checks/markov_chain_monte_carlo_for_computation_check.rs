// MCMC as a tool: fit wet-day chance p, Weibull shape k and scale c (mm) to 200 synthetic rainfall days.
// Roads: 1 the exact Beta posterior for p; 2 a 2-D grid for (k, c), no randomness;
// 3 seeded Metropolis chains (SplitMix64, Box-Muller), tuned, run four at a time, error bars by batch means.
// Std only, no crates.  Same generator, same order of draws, same output as the Python check.
use std::f64::consts::PI;

struct Rng { s: u64 }
impl Rng {
    fn u(&mut self) -> f64 {
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
    fn n(&mut self) -> f64 {
        let u1 = self.u(); let u2 = self.u();
        (-2.0 * (1.0 - u1).ln()).sqrt() * (2.0 * PI * u2).cos()
    }
}
type P3 = [f64; 3];
struct Data { wet: Vec<f64>, nw: f64, nd: f64, sl: f64 }

fn tot<I: IntoIterator<Item = f64>>(v: I) -> f64 { let mut s = 0.0; for x in v { s += x; } s }
fn out(k: &str, v: &[f64], d: usize) {
    let mut line = format!("{:<40}", k); for x in v { line.push_str(&format!(" {:.*}", d, x)); } println!("{}", line);
}
fn logf(dt: &Data, p: f64, k: f64, c: f64) -> f64 {              // log posterior up to a constant, flat prior on a box
    if !(0.0 < p && p < 1.0 && 0.0 < k && k < 5.0 && 0.0 < c && c < 100.0) { return -1e300; }
    dt.nw * p.ln() + (dt.nd - dt.nw) * (1.0 - p).ln() + dt.nw * k.ln() - dt.nw * k * c.ln() + (k - 1.0) * dt.sl
        - tot(dt.wet.iter().map(|x| (x / c).powf(k)))
}
fn over25(t: &P3) -> f64 { t[0] * (-(25.0 / t[2]).powf(t[1])).exp() }   // chance a day brings more than 25 mm
fn chain(dt: &Data, seed: u64, start: P3, step: &P3, n: usize) -> (Vec<P3>, f64) {
    let mut r = Rng { s: seed }; let mut th = start; let mut lf = logf(dt, th[0], th[1], th[2]);
    let mut xs = Vec::with_capacity(n); let mut acc = 0usize;
    for _ in 0..n {
        let mut prop = [0.0; 3];
        for i in 0..3 { prop[i] = th[i] + step[i] * r.n(); }
        let lp = logf(dt, prop[0], prop[1], prop[2]);
        if (1.0 - r.u()).ln() < lp - lf { th = prop; lf = lp; acc += 1; }
        xs.push(th);
    }
    (xs, acc as f64 / n as f64)
}
fn sd(v: &[f64]) -> f64 {
    let m = tot(v.iter().copied()) / v.len() as f64;
    (tot(v.iter().map(|x| (x - m) * (x - m))) / (v.len() - 1) as f64).sqrt()
}
fn bm(cs: &[Vec<f64>]) -> (f64, f64, f64) {        // batch means over several chains: mean, Monte Carlo SE, ESS
    let per = 25; let mut bs = Vec::new();
    for c in cs {
        let lb = c.len() / per;
        for q in 0..per { bs.push(tot(c[q * lb..(q + 1) * lb].iter().copied()) / lb as f64); }
    }
    let allv: Vec<f64> = cs.iter().flatten().copied().collect();
    let m = tot(allv.iter().copied()) / allv.len() as f64; let se = sd(&bs) / (bs.len() as f64).sqrt();
    let r = sd(&allv) / se;
    (m, se, r * r)
}
fn rhat(cs: &[Vec<f64>]) -> f64 {                  // Gelman-Rubin: spread between chains against spread within
    let m = cs.len() as f64; let n = cs[0].len() as f64;
    let mus: Vec<f64> = cs.iter().map(|c| tot(c.iter().copied()) / n).collect();
    let g = tot(mus.iter().copied()) / m;
    let b = n * tot(mus.iter().map(|x| (x - g) * (x - g))) / (m - 1.0);
    let wv = tot(cs.iter().map(|c| sd(c) * sd(c))) / m;
    (((n - 1.0) / n * wv + b / n) / wv).sqrt()
}
fn col(xs: &[P3], j: usize, a: usize, b: usize) -> Vec<f64> { xs[a..b].iter().map(|x| x[j]).collect() }

fn main() {
    // ---- the data: 200 days, wet with chance 0.35, wet amounts Weibull(shape 0.75, scale 6 mm), to 0.1 mm ----
    let mut r = Rng { s: 2026 }; let mut days = Vec::new();
    for _ in 0..200 {
        if r.u() < 0.35 {
            let a = (10.0 * 6.0 * (-(1.0 - r.u()).ln()).powf(1.0 / 0.75) + 0.5).floor() / 10.0;
            days.push(if a < 0.1 { 0.1 } else { a });
        } else { days.push(0.0); }
    }
    let wet: Vec<f64> = days.iter().copied().filter(|x| *x > 0.0).collect();
    let dt = Data { nw: wet.len() as f64, nd: days.len() as f64, sl: tot(wet.iter().map(|x| x.ln())), wet };
    let big = dt.wet.iter().copied().fold(0.0, f64::max);
    println!("{:<40} {} {} {:.1}", "data: days, wet days, total mm", days.len(), dt.wet.len(), tot(dt.wet.iter().copied()));
    out("data: mean and largest wet-day mm", &[tot(dt.wet.iter().copied()) / dt.nw, big], 1);
    // ---- road 1: p alone has an exact Beta posterior ----
    let (a1, b1) = (dt.nw + 1.0, dt.nd - dt.nw + 1.0);
    let pm = a1 / (a1 + b1); let psd = (a1 * b1 / ((a1 + b1) * (a1 + b1) * (a1 + b1 + 1.0))).sqrt();
    out("exact p: mean, sd", &[pm, psd], 4);
    // ---- road 2: (k, c) on a 161 x 361 grid, k 0.40 to 1.20, c 2 to 20 mm ----
    let gkv: Vec<f64> = (0..161).map(|i| 0.40 + 0.005 * i as f64).collect();
    let gcv: Vec<f64> = (0..361).map(|j| 2.0 + 0.05 * j as f64).collect();
    let l: Vec<Vec<f64>> = gkv.iter().map(|&k| gcv.iter().map(|&c| logf(&dt, pm, k, c)).collect()).collect();
    let top = l.iter().flatten().copied().fold(f64::NEG_INFINITY, f64::max);
    let g: Vec<Vec<f64>> = l.iter().map(|row| row.iter().map(|v| (v - top).exp()).collect()).collect();
    let t = tot(g.iter().map(|row| tot(row.iter().copied())));
    let ge = |h: &dyn Fn(f64, f64) -> f64| -> f64 {
        let mut s = 0.0;
        for i in 0..161 { for j in 0..361 { s += g[i][j] * h(gkv[i], gcv[j]); } }
        s / t
    };
    let gk = ge(&|k, _| k); let gc = ge(&|_, c| c);
    let gks = ge(&|k, _| (k - gk) * (k - gk)).sqrt(); let gcs = ge(&|_, c| (c - gc) * (c - gc)).sqrt();
    let grho = ge(&|k, c| (k - gk) * (c - gc)) / (gks * gcs);
    let g25 = pm * ge(&|k, c| (-(25.0 / c).powf(k)).exp());       // p is independent of (k, c), so the average splits
    out("grid k: mean, sd", &[gk, gks], 4); out("grid c: mean, sd", &[gc, gcs], 4); out("grid corr(k, c)", &[grho], 4);
    out("grid P(day > 25 mm)", &[g25], 5);
    // ---- road 3: random-walk Metropolis ----
    let mut step: P3 = [0.1, 0.1, 0.1]; let mut th: P3 = [0.5, 1.0, 5.0];   // tuning: a guess, then 2.38/sqrt(3) x pilot sd
    for rnd in 1..4u64 {
        let (xs, acc) = chain(&dt, 100 + rnd, th, &step, 2000);
        out(&format!("tune round {}: steps p k c, accept", rnd), &[step[0], step[1], step[2], acc], 4);
        th = xs[1999];
        for i in 0..3 { step[i] = 2.38 / 3f64.sqrt() * sd(&col(&xs, i, 1000, 2000)); }
    }
    out("tuned steps p k c", &step, 4);
    let f = 2.38 / 3f64.sqrt();
    out("rule 2.38/sqrt(3); times exact sd p k c", &[f, f * psd, f * gks, f * gcs], 4);
    let (start, s): (P3, P3) = ([pm, gk, gc], step);
    let cases: [(&str, P3); 5] = [("one step 0.1 for all", [0.1; 3]), ("one step 1.0 for all", [1.0; 3]),
        ("tuned x 0.1", [s[0] * 0.1, s[1] * 0.1, s[2] * 0.1]), ("tuned", s), ("tuned x 10", [s[0] * 10.0, s[1] * 10.0, s[2] * 10.0])];
    let mut tests = Vec::new();
    for (name, st) in cases.iter() {
        let (xs, acc) = chain(&dt, 7, start, st, 10000); let ess = bm(&[col(&xs, 2, 0, 10000)]).2; tests.push((acc, ess));
        println!("{:<40} {:.4} {:.0}", format!("{}: accept, ESS of c", name), acc, ess);
    }
    let starts: [P3; 4] = [[0.10, 0.30, 2.0], [0.80, 2.00, 20.0], [0.50, 1.20, 3.0], [0.20, 0.50, 15.0]];
    let mut runs = Vec::new();
    for (i, s0) in starts.iter().enumerate() {
        let (xs, acc) = chain(&dt, 11 + i as u64, *s0, &step, 12000); runs.push(xs);
        out(&format!("chain {} from p k c, accept", i + 1), &[s0[0], s0[1], s0[2], acc], 4);
    }
    let early: Vec<Vec<Vec<f64>>> = (0..3).map(|j| runs.iter().map(|xs| col(xs, j, 0, 100)).collect()).collect();
    let kept: Vec<Vec<Vec<f64>>> = (0..3).map(|j| runs.iter().map(|xs| col(xs, j, 2000, 12000)).collect()).collect();
    let re: Vec<f64> = early.iter().map(|e| rhat(e)).collect(); let rk: Vec<f64> = kept.iter().map(|e| rhat(e)).collect();
    out("R-hat p k c, first 100 steps", &re, 4);
    out("R-hat p k c, 10,000 kept after 2,000", &rk, 4);
    let same: Vec<Vec<P3>> = (0..4).map(|i| chain(&dt, 31 + i, [0.35, 0.75, 20.0], &step, 100).0).collect();
    let samec: Vec<Vec<f64>> = same.iter().map(|xs| col(xs, 2, 0, 100)).collect();
    out("4 chains all from c=20: R-hat c, mean c", &[rhat(&samec), tot(samec.iter().flatten().copied()) / 400.0], 4);
    let mut rep = Vec::new();
    for (j, name) in ["p", "k", "c"].iter().enumerate() {
        let allv: Vec<f64> = kept[j].iter().flatten().copied().collect(); let (m, se, ess) = bm(&kept[j]);
        rep.push((m, sd(&allv), se));
        out(&format!("report {}: mean, sd, MCSE, naive SE", name), &[m, sd(&allv), se, sd(&allv) / 40000f64.sqrt()], 4);
        out(&format!("  ESS of {} out of 40,000; N/ESS", name), &[ess, 40000.0 / ess], 1);
    }
    let q: Vec<Vec<f64>> = runs.iter().map(|xs| xs[2000..].iter().map(over25).collect()).collect();
    let (m25, se25, _) = bm(&q); let qall: Vec<f64> = q.iter().flatten().copied().collect();
    out("report P(>25 mm): mean, sd, MCSE", &[m25, sd(&qall), se25], 5);
    out("  as about 1 day in", &[1.0 / m25], 1);
    out("plug-in P(>25 mm) at the means", &[over25(&[rep[0].0, rep[1].0, rep[2].0])], 5);
    let ts: Vec<usize> = (0..=300).step_by(20).collect();
    println!("{:<19}{}", "chart, step", ts.iter().map(|t| format!("{:6}", t)).collect::<String>());
    for i in 0..2 {
        println!("{:<19}{}", format!("chart, c from {:.1}", starts[i][2]), ts.iter().map(|&t| format!("{:6.2}", runs[i][t][2])).collect::<String>());
    }
    assert!((rep[0].0 - pm).abs() < 4.0 * rep[0].2, "chains' p against the exact Beta mean");
    assert!((rep[1].0 - gk).abs() < 4.0 * rep[1].2, "chains' k against the grid");
    assert!((rep[2].0 - gc).abs() < 4.0 * rep[2].2, "chains' c against the grid");
    assert!((m25 - g25).abs() < 4.0 * se25, "P(day > 25 mm) against the grid");
    assert!((rep[0].1 / psd - 1.0).abs() < 0.05, "posterior sd of p against the Beta formula");
    assert!((rep[2].1 / gcs - 1.0).abs() < 0.05, "posterior sd of c against the grid");
    assert!(re.iter().copied().fold(0.0, f64::max) > 1.1, "R-hat flags the scattered starts");
    assert!(rk.iter().copied().fold(0.0, f64::max) < 1.01, "R-hat clears after burn-in");
    assert!(0.15 < tests[3].0 && tests[3].0 < 0.5, "tuned acceptance in the workable band");
    assert!(tests[3].1 > 10.0 * tests[0].1, "per-parameter steps beat one shared step");
    assert!((gk - 0.75).abs() < 3.0 * gks, "grid posterior covers the generator's shape k = 0.75");
    assert!((gc - 6.0).abs() < 3.0 * gcs, "grid posterior covers the generator's scale c = 6 mm");
    println!("ALL CHECKS PASS");
}
