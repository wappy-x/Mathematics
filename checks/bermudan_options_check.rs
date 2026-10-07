// Bermudan put -- the same check as bermudan_options_check.py, in Rust, std only.
// House market: S = K = 100, r = 5%, q = 2%, sigma = 20%, one year.  Four roads:
// gated CRR tree, log-price grid by quadrature, closed form plus insertion
// integral, least-squares Monte Carlo with its own random numbers.
use std::collections::{HashMap, HashSet};
use std::f64::consts::PI;
const S: f64 = 100.0; const K: f64 = 100.0; const R: f64 = 0.05; const Q: f64 = 0.02; const SIG: f64 = 0.20; const T: f64 = 1.0;

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }
fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    s * h / 3.0
}
fn n_cdf(x: f64) -> f64 { 0.5 + simpson(phi, 0.0, x, 200) }            // normal CDF, built here
fn bs_put(s: f64, t: f64) -> f64 {
    let d1 = ((s / K).ln() + (R - Q + 0.5 * SIG * SIG) * t) / (SIG * t.sqrt());
    K * (-R * t).exp() * n_cdf(SIG * t.sqrt() - d1) - s * (-Q * t).exp() * n_cdf(-d1)
}
fn every(n: usize, m: usize) -> Vec<usize> { (1..=m).map(|k| k * n / m).collect() }
fn tree(n: usize, listed: &[usize], greedy: bool) -> (f64, HashMap<usize, f64>) {   // Road 1
    let dt = T / n as f64; let u = (SIG * dt.sqrt()).exp(); let d = 1.0 / u;
    let p = (((R - Q) * dt).exp() - d) / (u - d); let disc = (-R * dt).exp();
    let listed: HashSet<usize> = listed.iter().cloned().collect(); let mut edge = HashMap::new();
    let node = |i: usize, j: usize| S * u.powf(j as f64) * d.powf((i - j) as f64);
    let mut v: Vec<f64> = (0..=n).map(|j| (K - node(n, j)).max(0.0)).collect();
    for i in (0..n).rev() {
        v = (0..=i).map(|j| disc * (p * v[j + 1] + (1.0 - p) * v[j])).collect();
        if listed.contains(&i) {                                          // the gate
            let ex: Vec<f64> = (0..=i).map(|j| K - node(i, j)).collect();
            edge.insert(i, (0..=i).filter(|&j| ex[j] > v[j]).map(|j| node(i, j)).fold(0.0, f64::max));
            v = v.iter().zip(&ex).map(|(&c, &e)| if greedy { if e > 0.0 { e } else { c } } else { c.max(e) }).collect();
        }
    }
    (v[0], edge)
}
fn grid(m: usize) -> f64 {                                                 // Road 2
    let (h, mm) = (0.002_f64, 800usize); let top = 2 * mm;
    let dt = T / m as f64; let s = SIG * dt.sqrt(); let mu = (R - Q - 0.5 * SIG * SIG) * dt;
    let x: Vec<f64> = (0..=top).map(|i| S.ln() + (i as f64 - mm as f64) * h).collect();
    let w: Vec<f64> = (0..=2 * top).map(|k| h * (-R * dt).exp() * phi(((k as f64 - top as f64) * h - mu) / s) / s).collect();
    let c = (9.0 * s / h).ceil() as usize;
    let mut v: Vec<f64> = x.iter().map(|xi| (K - xi.exp()).max(0.0)).collect();
    for k in (0..m).rev() {
        let mut new = vec![0.0; top + 1];
        for i in mm.saturating_sub(k * c)..=(mm + k * c).min(top) {
            let mut acc = 0.0;
            for j in i.saturating_sub(c)..=(i + c).min(top) {
                acc += v[j] * w[j + top - i] * if j == 0 || j == top { 0.5 } else { 1.0 };
            }
            new[i] = if k > 0 { acc.max(K - x[i].exp()) } else { acc };
        }
        v = new;
    }
    v[mm]
}
fn s_half(z: f64) -> f64 { S * ((R - Q - 0.5 * SIG * SIG) * 0.5 + SIG * 0.5_f64.sqrt() * z).exp() }
fn gain(z: f64) -> f64 { K - s_half(z) - bs_put(s_half(z), 0.5) }
struct Rng(u64);                                                           // xorshift64*, written here
impl Rng {
    fn uniform(&mut self) -> f64 {
        self.0 ^= self.0 >> 12; self.0 ^= self.0 << 25; self.0 ^= self.0 >> 27;
        (self.0.wrapping_mul(0x2545F4914F6CDD1D) >> 11) as f64 * 2f64.powi(-53) + 2f64.powi(-54)
    }
    fn paths(&mut self, n: usize) -> Vec<[f64; 4]> {
        let dt = T / 4.0;
        (0..n).map(|_| {
            let (mut s, mut row) = (S, [0.0; 4]);
            for k in 0..4 {
                let z = (-2.0 * self.uniform().ln()).sqrt() * (2.0 * PI * self.uniform()).cos();
                s *= ((R - Q - 0.5 * SIG * SIG) * dt + SIG * dt.sqrt() * z).exp(); row[k] = s;
            }
            row
        }).collect()
    }
}
fn fit(pts: &[(f64, f64)]) -> [f64; 3] {                                    // 3x3 normal equations
    let mut a = [[0.0_f64; 4]; 3];
    for &(x, y) in pts {
        let f = [1.0, x, x * x];
        for i in 0..3 { for j in 0..3 { a[i][j] += f[i] * f[j]; } a[i][3] += f[i] * y; }
    }
    for i in 0..3 { for j in i + 1..3 { let t = a[j][i] / a[i][i]; for c in 0..4 { a[j][c] -= t * a[i][c]; } } }
    let mut beta = [0.0; 3];
    for i in (0..3).rev() { let mut s = a[i][3]; for c in i + 1..3 { s -= a[i][c] * beta[c]; } beta[i] = s / a[i][i]; }
    beta
}
fn take(b: &[f64; 3], s: f64) -> bool { s < K && K - s > b[0] + b[1] * (s / K) + b[2] * (s / K).powf(2.0) }

fn main() {
    let (mut lo, mut hi) = (-6.0_f64, 0.0_f64);                             // Road 3
    for _ in 0..60 { let mid = 0.5 * (lo + hi); if gain(mid) > 0.0 { lo = mid } else { hi = mid } }
    let z_star = lo;
    let insert = (-R * 0.5).exp() * simpson(|z| gain(z) * phi(z), -8.0, z_star, 2000);
    let mut rng = Rng(0x9E3779B97F4A7C15);                                   // Road 4
    let dq = (-R * T / 4.0).exp(); let train = rng.paths(40000);
    let mut cash: Vec<f64> = train.iter().map(|row| (K - row[3]).max(0.0)).collect();
    let mut betas = [[0.0; 3]; 3];
    for k in [2usize, 1, 0] {
        for c in cash.iter_mut() { *c *= dq; }
        let pts: Vec<(f64, f64)> = train.iter().zip(&cash).filter(|(row, _)| row[k] < K).map(|(row, &c)| (row[k] / K, c)).collect();
        betas[k] = fit(&pts);
        for (row, c) in train.iter().zip(cash.iter_mut()) { if take(&betas[k], row[k]) { *c = K - row[k]; } }
    }
    let (mut pay, mut peek) = (Vec::new(), Vec::new());
    for row in rng.paths(100000) {
        let mut got = (-R * T).exp() * (K - row[3]).max(0.0);
        for k in 0..3 { if take(&betas[k], row[k]) { got = (-R * T * (k + 1) as f64 / 4.0).exp() * (K - row[k]); break; } }
        pay.push(got);
        peek.push((0..4).map(|k| (-R * T * (k + 1) as f64 / 4.0).exp() * (K - row[k]).max(0.0)).fold(f64::MIN, f64::max));
    }
    let nn = pay.len() as f64; let lsm = pay.iter().sum::<f64>() / nn;
    let se = ((pay.iter().map(|v| v * v).sum::<f64>() / nn - lsm * lsm) / nn).sqrt();
    let peek_mean = peek.iter().sum::<f64>() / nn;

    let eu = bs_put(S, T);
    let (t1, _) = tree(2000, &every(2000, 1), false); let (t2, e2) = tree(2000, &every(2000, 2), false);
    let (t4, e4) = tree(2000, &every(2000, 4), false); let (t12, _) = tree(2400, &every(2400, 12), false);
    let (t52, _) = tree(2080, &every(2080, 52), false); let (tam, _) = tree(2000, &(0..=2000).collect::<Vec<_>>(), false);
    let greedy = tree(2000, &every(2000, 4), true).0;
    let early = tree(2000, &[500, 2000], false).0; let late = tree(2000, &[1500, 2000], false).0;
    let (g1, g2, g4, g12) = (grid(1), grid(2), grid(4), grid(12));
    let u2 = (SIG * 0.5_f64.sqrt()).exp(); let d2 = 1.0 / u2; let p2 = (((R - Q) * 0.5).exp() - d2) / (u2 - d2);
    let dc = (-R * 0.5).exp(); let hold = dc * (1.0 - p2) * (K - S * d2 * d2);   // the by-hand tree
    let (berm2, euro2) = (dc * (1.0 - p2) * hold.max(K - S * d2), dc * (1.0 - p2) * hold);
    let rows: Vec<(&str, f64)> = vec![("European put, closed form", eu), ("1 date, tree 2000 steps", t1), ("1 date, grid", g1),
        ("2 dates, tree 2000 steps", t2), ("2 dates, grid", g2), ("2 dates, closed form + insertion", eu + insert),
        ("4 dates, tree 2000 steps", t4), ("4 dates, grid", g4), ("4 dates, LSM 40000 fit/100000 run", lsm),
        ("  its standard error", se), ("12 dates, tree 2400 steps", t12), ("12 dates, grid", g12),
        ("52 dates, tree 2080 steps", t52), ("every step, tree 2000 steps", tam),
        ("value of the 6-month date alone", insert), ("6-month critical price", s_half(z_star)),
        ("  tree, highest node exercised", e2[&1000]),
        ("quarterly boundary, 3 months", e4[&500]), ("quarterly boundary, 6 months", e4[&1000]),
        ("quarterly boundary, 9 months", e4[&1500]),
        ("wrong: check at every step", tam), ("wrong: exercise whenever in money", greedy),
        ("wrong: peek at the future (MC)", peek_mean),
        ("timing: dates at 3 months + expiry", early), ("timing: dates at 9 months + expiry", late),
        ("hand: up factor u", u2), ("hand: down factor d", d2), ("hand: up chance p", p2), ("hand: half-year discount", dc),
        ("hand: low price at 6 months", S * d2), ("hand: low price at expiry", S * d2 * d2), ("hand: put pays there", K - S * d2 * d2),
        ("hand: hold at the low 6-month node", hold), ("hand: exercise there", K - S * d2),
        ("hand: Bermudan today", berm2), ("hand: European today", euro2)];
    for (label, v) in &rows { println!("{:<36}{:>12.6}", label, v); }
    let ladder = [t1, t2, t4, t12, t52, tam];
    println!("chart, price by dates  {}", ladder.iter().map(|v| format!("{:.2}", v)).collect::<Vec<_>>().join(" "));
    println!("share of American premium, %  {}", ladder.iter().map(|v| format!("{:.1}", 100.0 * (v - t1) / (tam - t1))).collect::<Vec<_>>().join(" "));

    assert!((g1 - eu).abs() < 1e-4, "grid with one date must return the closed-form European");
    assert!((t1 - eu).abs() < 2e-3, "tree with one date must return the European, to tree accuracy");
    assert!((g2 - (eu + insert)).abs() < 1e-4, "two dates: grid vs closed form plus insertion integral");
    assert!((t4 - g4).abs() < 2e-3, "tree vs grid, quarterly");
    assert!((t12 - g12).abs() < 2e-3, "tree vs grid, monthly");
    assert!(t1 < t2 && t2 < t4 && t4 < t12 && t12 < t52 && t52 < tam, "more dates can never be worth less");
    assert!((lsm - g4).abs() < 3.0 * se, "least squares within three standard errors of the grid");
    assert!(e2[&1000] <= s_half(z_star) && s_half(z_star) < e2[&1000] * (2.0 * SIG * (T / 2000.0).sqrt()).exp(), "tree edge brackets the critical price");
    assert!((berm2 - tree(2, &[1, 2], false).0).abs() < 1e-12, "hand arithmetic vs the general tree, two steps");
    assert!(greedy < t4 && t4 < peek_mean, "a bad rule is worth less, foresight more");
    println!("ALL CHECKS PASS");
}
