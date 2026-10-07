// t-tests -- the same check as the Python, in Rust.  No crates.  30 patients' systolic blood pressure (mmHg)
// before and after 8 weeks on a drug.  Road 1: t areas by Simpson over an angle.  Road 2: the closed-form t
// area.  Road 3: exact sign-flip, shuffle and sign tests by counting, no t law.  Then sample size and simulations.
use std::f64::consts::PI;

const BEFORE: [i64; 30] = [152, 151, 165, 156, 163, 150, 150, 151, 128, 166, 131, 139, 161, 153, 163,
    174, 176, 170, 149, 179, 141, 151, 165, 149, 150, 147, 170, 120, 169, 166];
const AFTER: [i64; 30] = [145, 149, 151, 159, 181, 137, 155, 145, 119, 156, 123, 123, 144, 160, 157,
    172, 172, 168, 131, 164, 140, 153, 150, 138, 135, 146, 167, 114, 158, 163];
const CLAIM: f64 = 10.0; const NOISE: f64 = 8.0; const SIM: usize = 4000; const SEED: u64 = 20260928;

fn mean(xs: &[f64]) -> f64 { xs.iter().fold(0.0, |a, x| a + x) / xs.len() as f64 }
fn sd(xs: &[f64]) -> f64 { let m = mean(xs); (xs.iter().fold(0.0, |a, x| a + (x - m).powi(2)) / (xs.len() - 1) as f64).sqrt() }

fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64) -> f64 {   // integral of f, 600 steps
    let m = 600;
    let h = (b - a) / m as f64;
    let mut acc = 0.0;
    for i in 1..m { acc += (if i % 2 == 1 { 4.0 } else { 2.0 }) * f(a + i as f64 * h) }
    (f(a) + f(b) + acc) * h / 3.0
}

fn t_area_angle(x: f64, v: f64) -> f64 {         // road 1: any v > 0, u = root(v) tan(th)
    let g = |th: f64| th.cos().powf(v - 1.0);
    0.5 + 0.5 * simpson(g, 0.0, (x / v.sqrt()).atan()) / simpson(g, 0.0, PI / 2.0)
}

fn t_area_closed(x: f64, v: usize) -> f64 {      // road 2: whole-number v, closed form
    let th = (x / (v as f64).sqrt()).atan();
    let (c2, mut term, mut total) = (th.cos().powi(2), 1.0, 1.0);
    if v % 2 == 0 {
        for j in 1..v / 2 {
            term *= c2 * (2 * j - 1) as f64 / (2 * j) as f64;
            total += term;
        }
        return 0.5 + th.sin() * total / 2.0;
    }
    for j in 1..(v - 1) / 2 {
        term *= c2 * (2 * j) as f64 / (2 * j + 1) as f64;
        total += term;
    }
    0.5 + (th + if v > 1 { th.sin() * th.cos() * total } else { 0.0 }) / PI
}
fn p_ang(t: f64, v: f64) -> f64 { 2.0 * (1.0 - t_area_angle(t.abs(), v)) }
fn p_cl(t: f64, v: usize) -> f64 { 2.0 * (1.0 - t_area_closed(t.abs(), v)) }
fn cutoff<F: Fn(f64) -> f64>(area: F, p: f64) -> f64 {   // bisection: area(x) = p
    let (mut lo, mut hi) = (0.0, 10.0);
    for _ in 0..60 { let mid = (lo + hi) / 2.0; if area(mid) < p { lo = mid } else { hi = mid } }
    (lo + hi) / 2.0
}
fn phi(x: f64) -> f64 { 0.5 + simpson(|u: f64| (-u * u / 2.0).exp(), 0.0, x) / (2.0 * PI).sqrt() }   // the bell's area left of x
fn power(m: usize, gap: f64, s: f64) -> f64 {    // exact paired-t power at 5%: the bell's chance averaged over chi-square
    let (k, ts, c) = ((m - 1) as f64, cutoff(|x| t_area_closed(x, m - 1), 0.975), gap * (m as f64).sqrt() / s); let dens = |v: f64| v.powf(k / 2.0 - 1.0) * (-v / 2.0).exp();
    simpson(|v| dens(v) * (phi(c - ts * (v / k).sqrt()) + phi(-c - ts * (v / k).sqrt())), 0.0, 6.0 * k) / simpson(dens, 0.0, 6.0 * k)
}
fn welch(a: &[f64], b: &[f64]) -> (f64, f64) {   // t and Welch's degrees of freedom
    let (va, vb) = (sd(a).powi(2) / a.len() as f64, sd(b).powi(2) / b.len() as f64);
    ((mean(a) - mean(b)) / (va + vb).sqrt(),
     (va + vb).powi(2) / (va.powi(2) / (a.len() - 1) as f64 + vb.powi(2) / (b.len() - 1) as f64))
}
fn pooled(a: &[f64], b: &[f64]) -> (f64, usize) {
    let (na, nb) = (a.len(), b.len());
    let sp2 = ((na - 1) as f64 * sd(a).powi(2) + (nb - 1) as f64 * sd(b).powi(2)) / (na + nb - 2) as f64;
    ((mean(a) - mean(b)) / (sp2 * (1.0 / na as f64 + 1.0 / nb as f64)).sqrt(), na + nb - 2)
}

struct Rng(u64);
impl Rng {
    fn splitmix(&mut self) -> u64 {              // SplitMix64, seed 20260928
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut x = self.0;
        x = (x ^ (x >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        x = (x ^ (x >> 27)).wrapping_mul(0x94D049BB133111EB);
        x ^ (x >> 31)
    }
    fn unif(&mut self) -> f64 { ((self.splitmix() >> 11) as f64 + 0.5) / 9007199254740992.0 }
    fn normal(&mut self) -> f64 { let r = (-2.0 * self.unif().ln()).sqrt(); r * (2.0 * PI * self.unif()).cos() }
    fn normals(&mut self, k: usize, mu: f64, s: f64) -> Vec<f64> { (0..k).map(|_| mu + s * self.normal()).collect() }
}

fn main() {
    let n = BEFORE.len();
    let (bf, af): (Vec<f64>, Vec<f64>) = (BEFORE.iter().map(|&x| x as f64).collect(), AFTER.iter().map(|&x| x as f64).collect());
    let di: Vec<i64> = BEFORE.iter().zip(AFTER.iter()).map(|(b, a)| b - a).collect();   // drop, mmHg
    let d: Vec<f64> = di.iter().map(|&x| x as f64).collect();
    let (dbar, sdd) = (mean(&d), sd(&d));
    let se = sdd / (n as f64).sqrt();
    let (t0, t10) = (dbar / se, (dbar - CLAIM) / se);
    let tstar = cutoff(|x| t_area_closed(x, n - 1), 0.975);
    println!("drops: {:?}", di);
    println!("n {}, mean drop {:.4}, s {:.4}, standard error {:.4} mmHg", n, dbar, sdd, se);
    println!("before: mean {:.4} s {:.4}; after: mean {:.4} s {:.4}", mean(&bf), sd(&bf), mean(&af), sd(&af));
    println!("paired t vs 0: t {:.4}, df {}, p road 1 {:.6}, road 2 {:.6}, one-sided {:.6}", t0, n - 1, p_ang(t0, (n - 1) as f64), p_cl(t0, n - 1), p_cl(t0, n - 1) / 2.0);
    println!("one-sample t vs claim {:.0}: t {:.4}, p road 1 {:.6}, road 2 {:.6}", CLAIM, t10, p_ang(t10, (n - 1) as f64), p_cl(t10, n - 1));
    println!("t cutoff 0.975, df {}: {:.6}; 95% interval for mean drop [{:.4}, {:.4}]", n - 1, tstar, dbar - tstar * se, dbar + tstar * se);
    let ((tw, vw), (tp, vp)) = (welch(&bf, &af), pooled(&bf, &af));
    println!("mistake, before vs after as independent: se {:.4}, Welch t {:.4} df {:.4} p {:.6}; pooled t {:.4} p {:.6}", dbar / tw, tw, vw, p_ang(tw, vw), tp, p_cl(tp, vp));
    let r = bf.iter().zip(af.iter()).fold(0.0, |acc, (b, a)| acc + (b - mean(&bf)) * (a - mean(&af))) / ((n - 1) as f64 * sd(&bf) * sd(&af));
    let ident = sd(&bf).powi(2) + sd(&af).powi(2) - 2.0 * r * sd(&bf) * sd(&af);
    println!("  correlation before-after {:.4}; s^2(before)+s^2(after)-2 r s s = {:.4} = s_d^2 {:.4}", r, ident, sdd.powi(2));
    let (wom, men) = (&d[..15], &d[15..]);
    let ((tw2, vw2), (tp2, vp2)) = (welch(men, wom), pooled(men, wom));
    println!("two-sample, men vs women: means {:.4} {:.4}, s {:.4} {:.4}, se {:.4}", mean(men), mean(wom), sd(men), sd(wom), (mean(men) - mean(wom)) / tw2);
    println!("  Welch t {:.4} df {:.4} p road 1 {:.6}; pooled t {:.4} df {} p {:.6}", tw2, vw2, p_ang(tw2, vw2), tp2, vp2, p_cl(tp2, vp2));
    let bins: Vec<usize> = (-20..25).step_by(5).map(|lo| di.iter().filter(|&&x| lo <= x && x < lo + 5).count()).collect();
    println!("histogram of drops, bins of 5 from -20 to 25: {:?}", bins);
    let (k, m0) = (di.iter().filter(|&&x| x > 0).count() as u128, di.iter().filter(|&&x| x != 0).count() as u128);
    let (mut comb, mut tail) = (1u128, 0u128);   // exact sign test by counting
    for j in 0..=k.min(m0 - k) {
        tail += comb;
        comb = comb * (m0 - j) / (j + 1);
    }
    println!("sign test: {} of {} dropped, exact two-sided p {:.6}", k, m0, (2.0 * tail as f64 / 2f64.powi(m0 as i32)).min(1.0));
    let mut sub = vec![vec![0u64; 601]; n + 1];  // road 3: count every subset of the drops by its size k and sum s - 300
    sub[0][300] = 1;
    for &x in &di { for k in (0..n).rev() { for s in 0..601 { let c = sub[k][s]; if c > 0 { sub[k + 1][(s as i64 + x) as usize] += c } } } }
    let (tt, c15) = (di.iter().sum::<i64>() as f64, (1..=15u64).fold(1u64, |c, j| c * (15 + j) / j));   // C(30, 15)
    let flip = |mu: f64| (0..=n).map(|k| (0..601).filter(|&s| (2.0 * (s as f64 - 300.0 - mu * k as f64) - (tt - mu * n as f64)).abs() >= (tt - mu * n as f64).abs() - 1e-9).map(|s| sub[k][s]).sum::<u64>()).sum::<u64>() as f64 / 2f64.powi(n as i32);
    let pe = [flip(0.0), flip(CLAIM), (0..601).filter(|&s| (2.0 * (s as f64 - 300.0) - tt).abs() >= (2.0 * di[15..].iter().sum::<i64>() as f64 - tt).abs()).map(|s| sub[15][s]).sum::<u64>() as f64 / c15 as f64];
    println!("exact randomisation p, all {} sign patterns: vs 0 {:.6}, vs {:.0} {:.6}; all {} splits, men vs women {:.6}", 1u64 << n, pe[0], CLAIM, pe[1], c15, pe[2]);
    let z = [cutoff(phi, 0.975), cutoff(phi, 0.80)];
    println!("sample size, power 0.80 at a 6 mmHg drop, s {:.4}: z {:.6} + {:.6} = {:.4}, normal rule n {:.1}; exact t power n 16 {:.4}, n 17 {:.4}", sdd, z[0], z[1], z[0] + z[1], ((z[0] + z[1]) * sdd / 6.0).powi(2), power(16, 6.0, sdd), power(17, 6.0, sdd));

    let mut rng = Rng(SEED);
    let mut rates = Vec::new();                  // share of SIM simulated trials with p < 0.05
    for case in 0..7 {
        let mut hits = 0;
        for _ in 0..SIM {
            let p = if case < 3 {
                let b = rng.normals(n, 152.0, 13.0);
                let drop = if case == 0 { 0.0 } else { 6.0 };
                let a: Vec<f64> = b.iter().map(|x| x - drop - NOISE * rng.normal()).collect();
                let dd: Vec<f64> = b.iter().zip(a.iter()).map(|(x, y)| x - y).collect();
                if case < 2 { p_cl(mean(&dd) / (sd(&dd) / (n as f64).sqrt()), n - 1) } else { let (t, v) = welch(&b, &a); p_ang(t, v) }
            } else if case < 5 {
                let (a, b) = (rng.normals(5, 150.0, 24.0), rng.normals(25, 150.0, 8.0));
                if case == 3 { let (t, v) = pooled(&a, &b); p_cl(t, v) } else { let (t, v) = welch(&a, &b); p_ang(t, v) }
            } else {
                let dd = rng.normals(11 + case, 6.0, sdd);   // case 5: 16 patients, case 6: 17
                p_cl(mean(&dd) / (sd(&dd) / (dd.len() as f64).sqrt()), dd.len() - 1)
            };
            if p < 0.05 { hits += 1 }
        }
        rates.push(hits as f64 / SIM as f64);
    }
    let names = ["paired, no real drop", "paired, drop 6", "unpaired, drop 6", "pooled, n 5 vs 25, s 24 vs 8, no difference", "Welch, same setting", "paired, n 16, drop 6, spread as in the trial", "paired, n 17, drop 6, spread as in the trial"];
    println!("simulation, {} trials each, share with p < 0.05:", SIM);
    for (nm, p) in names.iter().zip(rates.iter()) {
        println!("  {:45} {:.4} +/- {:.4}", nm, p, (p * (1.0 - p) / SIM as f64).sqrt());
    }
    let fig: Vec<String> = bf.iter().zip(af.iter()).map(|(b, a)| format!("{:.1} {:.1}", 40.0 + 2.5 * (b - 110.0), 210.0 - 2.5 * (a - 110.0))).collect();
    for i in (0..n).step_by(10) { println!("figure, points {}", fig[i..i + 10].join(", ")) }

    assert!((p_ang(t0, (n - 1) as f64) - p_cl(t0, n - 1)).abs() < 1e-9);        // two roads, odd df
    assert!((p_ang(tp2, vp2 as f64) - p_cl(tp2, vp2)).abs() < 1e-9);            // two roads, even df
    assert!((sdd.powi(2) - ident).abs() < 1e-9);
    assert!((tp2 - tw2).abs() < 1e-12);                                      // equal sizes: same ratio
    assert!((14.0..=vp2 as f64).contains(&vw2));                              // nu between 14 and 28
    assert_eq!(sub.iter().map(|r| r.iter().sum::<u64>()).sum::<u64>(), 1u64 << n);   // every sign pattern counted once
    assert_eq!(2 * (0..601).map(|s| (s as i64 - 300) * sub[15][s] as i64).sum::<i64>(), c15 as i64 * tt as i64);   // each drop is in half the splits
    assert!((pe[1] - p_cl(t10, n - 1)).abs() < 0.15 * p_cl(t10, n - 1));   // exact flips and t within 15%
    assert!((pe[2] - p_ang(tw2, vw2)).abs() < 0.05);              // shuffle and Welch: different tests, near p
    assert!((rates[0] - 0.05).abs() < 4.0 * (0.05f64 * 0.95 / SIM as f64).sqrt());   // paired t keeps its 5 percent
    assert!(rates[3] - 0.05 > 4.0 * (0.05f64 * 0.95 / SIM as f64).sqrt());           // pooled t breaks with unequal spreads
    assert!((rates[4] - 0.05).abs() < 4.0 * (0.05f64 * 0.95 / SIM as f64).sqrt());   // Welch repairs it
    assert!((power(n, 6.0, NOISE) - rates[1]).abs() < 4.0 * (rates[1] * (1.0 - rates[1]) / SIM as f64).sqrt());   // exact power vs simulated
    for i in 0..2 { assert!((power(16 + i, 6.0, sdd) - rates[5 + i]).abs() < 4.0 * (rates[5 + i] * (1.0 - rates[5 + i]) / SIM as f64).sqrt()); }   // small n too
    assert!(power(16, 6.0, sdd) < 0.80 && 0.80 < power(17, 6.0, sdd));    // 17 patients, not 16, reach 80 percent
    println!("ALL CHECKS PASS");
}
