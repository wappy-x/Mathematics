// Instrumental variables and difference-in-differences -- the same check as the
// Python, in Rust.  No crates.  Every number is made up for hand work.  Roads: Wald
// ratio against the compliers' own effect, two-stage least squares and the covariance
// ratio; DiD from four means against a regression with an interaction and per-shop changes.

fn solve(a: &[Vec<f64>], b: &[f64]) -> Vec<f64> { // Gaussian elimination, partial pivoting
    let n = b.len();
    let mut m: Vec<Vec<f64>> = a.iter().enumerate().map(|(i, r)| { let mut r = r.clone(); r.push(b[i]); r }).collect();
    for c in 0..n {
        let p = (c..n).fold(c, |best, r| if m[r][c].abs() > m[best][c].abs() { r } else { best });
        m.swap(c, p);
        let pivot = m[c].clone();
        for r in (0..n).filter(|&r| r != c) {
            let row: Vec<f64> = m[r].iter().zip(&pivot).map(|(x, y)| x - m[r][c] / pivot[c] * y).collect();
            m[r] = row;
        }
    }
    (0..n).map(|i| m[i][n] / m[i][i]).collect()
}

fn gram(x: &[Vec<f64>]) -> Vec<Vec<f64>> { // X^T X
    (0..x[0].len()).map(|i| (0..x[0].len()).map(|j| x.iter().map(|r| r[i] * r[j]).sum()).collect()).collect()
}

fn ols(x: &[Vec<f64>], y: &[f64]) -> Vec<f64> { // least squares by the normal equations
    let xty: Vec<f64> = (0..x[0].len()).map(|i| x.iter().zip(y).map(|(r, v)| r[i] * v).sum()).collect();
    solve(&gram(x), &xty)
}

fn se(x: &[Vec<f64>], resid: &[f64], j: usize) -> f64 { // s * sqrt of entry j of (X^T X)^-1
    let e: Vec<f64> = (0..x[0].len()).map(|i| if i == j { 1.0 } else { 0.0 }).collect();
    let ss: f64 = resid.iter().map(|r| r * r).sum();
    (ss / (x.len() - x[0].len()) as f64 * solve(&gram(x), &e)[j]).sqrt()
}

struct Rng(u64); // SplitMix64, seed stated; bell(): mean 0, spread 1, four uniforms summed
impl Rng {
    fn uniform(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = (self.0 ^ (self.0 >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
    fn bell(&mut self) -> f64 { (self.uniform() + self.uniform() + self.uniform() + self.uniform() - 2.0) * 3.0f64.sqrt() }
}

// the gym voucher, exact: type -> (share, kg lost without the gym, gym's effect in kg)
const TYPES: [(f64, f64, f64); 3] = [(0.20, 1.0, 3.0), (0.30, 0.5, 3.0), (0.50, 0.1, 1.0)]; // always, complier, never
fn joins(t: usize, z: usize) -> bool { t == 0 || (t == 1 && z == 1) }
fn arm(z: usize, letter: f64) -> (f64, f64) { // sign-up share and mean kg lost in one arm
    let d: f64 = (0..3).filter(|&t| joins(t, z)).map(|t| TYPES[t].0).sum();
    let y: f64 = (0..3).map(|t| TYPES[t].0 * (TYPES[t].1 + if joins(t, z) { TYPES[t].2 } else { 0.0 })).sum();
    (d, y + letter * z as f64)
}
fn draw(rng: &mut Rng, c_share: f64) -> (usize, usize) { // a person's type, then the voucher coin
    let u = rng.uniform();
    (if u < 0.2 { 0 } else if u < 0.2 + c_share { 1 } else { 2 }, if rng.uniform() < 0.5 { 1 } else { 0 })
}

fn wald_once(rng: &mut Rng, c_share: f64) -> (f64, f64) {
    let mut s = [[0.0f64; 3]; 2]; // per arm: count, sign-ups, kg lost
    for _ in 0..2000 {
        let (t, z) = draw(rng, c_share);
        let d = if joins(t, z) { 1.0 } else { 0.0 };
        s[z][0] += 1.0; s[z][1] += d; s[z][2] += TYPES[t].1 + TYPES[t].2 * d + 1.5 * rng.bell();
    }
    let (p0, p1) = (s[0][1] / s[0][0], s[1][1] / s[1][0]);
    let f = (p1 - p0).powi(2) / (p0 * (1.0 - p0) / s[0][0] + p1 * (1.0 - p1) / s[1][0]);
    ((s[1][2] / s[1][0] - s[0][2] / s[0][0]) / (p1 - p0), f)
}

fn gap(c: &[Vec<f64>; 2]) -> (f64, f64) { // difference in mean changes, and its SE
    let m: Vec<f64> = c.iter().map(|v| v.iter().sum::<f64>() / 60.0).collect();
    let v: f64 = (0..2).map(|k| c[k].iter().map(|x| (x - m[k]).powi(2)).sum::<f64>() / 59.0 / 60.0).sum();
    (m[1] - m[0], v.sqrt())
}

fn main() {
    let mut rng = Rng(20261123);
    let names = ["always", "complier", "never"];
    println!("types: share, kg lost without -> with the gym: {}", (0..3).map(|t| format!("{} {:.2}, {:.1} -> {:.1}", names[t], TYPES[t].0, TYPES[t].1, TYPES[t].1 + TYPES[t].2)).collect::<Vec<_>>().join("; "));
    let ((d0, y0), (d1, y1)) = (arm(0, 0.0), arm(1, 0.0));
    let (late, ate) = (TYPES[1].2, TYPES.iter().map(|t| t.0 * t.2).sum::<f64>()); // off the table
    println!("no voucher: sign-up {:.2}, mean loss {:.2} kg; voucher: sign-up {:.2}, mean loss {:.2} kg", d0, y0, d1, y1);
    let wald = (y1 - y0) / (d1 - d0);
    println!("Wald = {:.2} / {:.2} = {:.2} kg per sign-up; compliers' own effect {:.2}; average effect over everyone {:.2}", y1 - y0, d1 - d0, wald, late, ate);
    assert!((wald - late).abs() < 1e-12); // the Wald ratio is the compliers' effect
    assert!((ate - late).abs() > 0.5); // which here is not the average effect over everyone
    let (mut mem, mut non) = (Vec::new(), Vec::new());
    for t in 0..3 { for z in 0..2 {
        if joins(t, z) { mem.push((0.5 * TYPES[t].0, TYPES[t].1 + TYPES[t].2)) } else { non.push((0.5 * TYPES[t].0, TYPES[t].1)) }
    } }
    let mean = |g: &[(f64, f64)]| g.iter().map(|(w, v)| w * v).sum::<f64>() / g.iter().map(|(w, _)| w).sum::<f64>();
    let ((_, yl0), (_, yl1)) = (arm(0, 0.15), arm(1, 0.15));
    println!("members {:.4} kg, non-members {:.4} kg; what breaks: voucher effect read as the gym's {:.2}; naive gap {:.2}; letter itself worth 0.15 kg -> Wald {:.2} (bias 0.15 / {:.2} = {:.2}; with a 3-point lift 0.15 / 0.03 = {:.2})",
             mean(&mem), mean(&non), y1 - y0, mean(&mem) - mean(&non), (yl1 - yl0) / (d1 - d0), d1 - d0, 0.15 / (d1 - d0), 0.15 / 0.03);

    // a seeded sample of 4,000 people, with starting weight W as a measured covariate
    let mut rows: Vec<(f64, f64, f64, f64)> = Vec::new();
    for _ in 0..4000 {
        let (t, z) = draw(&mut rng, 0.30);
        let w = 90.0 + 12.0 * rng.bell();
        let d = if joins(t, z) { 1.0 } else { 0.0 };
        rows.push((z as f64, d, w, TYPES[t].1 + TYPES[t].2 * d + 0.1 * (w - 90.0) + 1.5 * rng.bell()));
    }
    let n = rows.len() as f64;
    let (zc, dc, yc): (Vec<f64>, Vec<f64>, Vec<f64>) = (rows.iter().map(|r| r.0).collect(), rows.iter().map(|r| r.1).collect(), rows.iter().map(|r| r.3).collect());
    let avg = |v: &[f64], zz: f64| v.iter().zip(&zc).filter(|(_, b)| **b == zz).map(|(a, _)| a).sum::<f64>() / zc.iter().filter(|b| **b == zz).count() as f64;
    let s_wald = (avg(&yc, 1.0) - avg(&yc, 0.0)) / (avg(&dc, 1.0) - avg(&dc, 0.0));
    let (mz, md, my) = (zc.iter().sum::<f64>() / n, dc.iter().sum::<f64>() / n, yc.iter().sum::<f64>() / n);
    let cov_ratio = zc.iter().zip(&yc).map(|(a, c)| (a - mz) * (c - my)).sum::<f64>() / zc.iter().zip(&dc).map(|(a, b)| (a - mz) * (b - md)).sum::<f64>();
    println!("sample n={}: sign-up {:.4} -> {:.4}, loss {:.4} -> {:.4} kg", n, avg(&dc, 0.0), avg(&dc, 1.0), avg(&yc, 0.0), avg(&yc, 1.0));
    for (label, with_w) in [("no covariate", false), ("with W", true)] {
        let extra = |r: &(f64, f64, f64, f64)| if with_w { vec![r.2 - 90.0] } else { vec![] };
        let x1: Vec<Vec<f64>> = rows.iter().map(|r| { let mut v = vec![1.0, r.0]; v.extend(extra(r)); v }).collect();
        let g1 = ols(&x1, &dc);
        let fit: Vec<f64> = x1.iter().map(|x| x.iter().zip(&g1).map(|(a, b)| a * b).sum()).collect();
        let f_stat = (g1[1] / se(&x1, &dc.iter().zip(&fit).map(|(d, f)| d - f).collect::<Vec<f64>>(), 1)).powi(2);
        let x2: Vec<Vec<f64>> = fit.iter().zip(&rows).map(|(f, r)| { let mut v = vec![1.0, *f]; v.extend(extra(r)); v }).collect();
        let b = ols(&x2, &yc);
        let right: Vec<f64> = rows.iter().map(|r| r.3 - b[0] - b[1] * r.1 - extra(r).iter().zip(&b[2..]).map(|(a, c)| a * c).sum::<f64>()).collect();
        let wrong: Vec<f64> = yc.iter().zip(&x2).map(|(y, x)| y - x.iter().zip(&b).map(|(a, c)| a * c).sum::<f64>()).collect();
        println!("2SLS {}: {:.4} kg (SE {:.4}; second-stage SE taken as is {:.4}); first-stage F {:.1}", label, b[1], se(&x2, &right, 1), se(&x2, &wrong, 1), f_stat);
        assert!((b[1] - 3.0).abs() < 4.0 * se(&x2, &right, 1));
        if !with_w {
            assert!((b[1] - s_wald).abs() < 1e-9 && (cov_ratio - s_wald).abs() < 1e-9);
            println!("  Wald from the four sample means {:.4}; covariance ratio {:.4}", s_wald, cov_ratio);
        }
    }
    println!("least squares of loss on sign-up, sample: {:.4} kg", ols(&dc.iter().map(|d| vec![1.0, *d]).collect::<Vec<_>>(), &yc)[1]);

    // weak instrument: 150 samples of 2,000, voucher lifting sign-up by 30 points or by 3
    let mut spread = [0.0; 2];
    for (i, (label, c_share)) in [("strong, 30 points", 0.30), ("weak, 3 points", 0.03)].iter().enumerate() {
        let runs: Vec<(f64, f64)> = (0..150).map(|_| wald_once(&mut rng, *c_share)).collect();
        let mut est: Vec<f64> = runs.iter().map(|r| r.0).collect();
        est.sort_by(|a, b| a.partial_cmp(b).unwrap());
        let q = |p: f64| est[(p * 149.0 + 0.5) as usize];
        spread[i] = q(0.95) - q(0.05);
        println!("{}: median {:.2}, middle 90% {:.2} to {:.2} kg; samples with F over 10: {} of 150", label, q(0.5), q(0.05), q(0.95), runs.iter().filter(|r| r.1 > 10.0).count());
    }
    assert!(spread[1] > 5.0 * spread[0]);

    // difference-in-differences: jobs per shop, town A gets the rule after year 2
    let (a, bt) = ([21.0f64, 20.0, 21.0], [24.0f64, 23.0, 22.0]); // years 1, 2, 3
    let (did, counterfactual) = ((a[2] - a[1]) - (bt[2] - bt[1]), a[1] + (bt[2] - bt[1]));
    println!("by hand: A {:.1} -> {:.1}, B {:.1} -> {:.1}; DiD {:+.1}; A without the rule {:.1}, effect {:+.1}; placebo years 1-2 {:+.1}", a[1], a[2], bt[1], bt[2], did, counterfactual, a[2] - counterfactual, (a[1] - a[0]) - (bt[1] - bt[0]));
    assert!((did - ols(&[vec![1.0, 1.0, 0.0, 0.0], vec![1.0, 1.0, 1.0, 1.0], vec![1.0, 0.0, 0.0, 0.0], vec![1.0, 0.0, 1.0, 0.0]], &[a[1], a[2], bt[1], bt[2]])[3]).abs() < 1e-9);
    println!("what breaks: before-after in A only {:+.1}; after-only gap {:+.1}; if A would have stayed flat, true effect {:+.1} but DiD still says {:+.1}", a[2] - a[1], a[2] - bt[2], a[2] - a[1], did);
    let j = |v: &[f64; 3]| v.iter().map(|x| format!("{:.1}", x)).collect::<Vec<_>>().join(", ");
    println!("chart, town A: {}; town B: {}; town A without the rule: {:.1}, {:.1}, {:.1}", j(&a), j(&bt), a[0], a[1], counterfactual);
    let mut shops: Vec<(usize, Vec<f64>)> = Vec::new(); // (treated, jobs in years 1, 2, 3)
    for (town, mu) in [(1, a), (0, bt)] { // each shop: its own level, then yearly noise
        for _ in 0..60 { let lv = 3.0 * rng.bell(); shops.push((town, mu.iter().map(|m| m + lv + rng.bell()).collect())) }
    }
    let cell = |tr: usize, yr: usize| shops.iter().filter(|s| s.0 == tr).map(|s| s.1[yr]).sum::<f64>() / 60.0;
    let four = (cell(1, 2) - cell(1, 1)) - (cell(0, 2) - cell(0, 1));
    let (mut x, mut y): (Vec<Vec<f64>>, Vec<f64>) = (Vec::new(), Vec::new());
    for (tr, v) in &shops { for yr in [1, 2] {
        let (t, p) = (*tr as f64, if yr == 2 { 1.0 } else { 0.0 });
        x.push(vec![1.0, t, p, t * p]); y.push(v[yr]);
    } }
    let reg = ols(&x, &y)[3];
    let changes = |s0: usize, s1: usize| [0, 1].map(|tr| shops.iter().filter(|s| s.0 == tr).map(|s| s.1[s1] - s.1[s0]).collect::<Vec<f64>>());
    let ((est, s_e), (plc, s_p)) = (gap(&changes(1, 2)), gap(&changes(0, 1)));
    println!("sample, 60 shops a town: four means {:+.4}; regression interaction {:+.4}; per-shop changes {:+.4} (SE {:.4}); placebo {:+.4} (SE {:.4})", four, reg, est, s_e, plc, s_p);
    assert!((four - reg).abs() < 1e-9 && (four - est).abs() < 1e-9);
    assert!((est - 2.0).abs() < 4.0 * s_e && plc.abs() < 4.0 * s_p);
    println!("ALL CHECKS PASS");
}
