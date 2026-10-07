// Stationary distributions -- the check behind the card.  std only.
// A town's days are sunny, cloudy or rainy; tomorrow depends only on today.
// Three roads to the long-run share of each kind of day: the balance equations
// solved exactly; mean return times from first-step equations (share = 1/return
// time); and 100000 simulated days, with a standard error from blocks of days.
use std::fmt;
use std::ops::{Add, Div, Mul, Sub};

#[derive(Clone, Copy, PartialEq, Debug)]
struct Q(i128, i128); // exact fraction, numerator / denominator, kept in lowest terms
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i128, d: i128) -> Q { let g = gcd(n, d) * d.signum(); Q(n / g, d / g) }
impl Add for Q { type Output = Q; fn add(self, o: Q) -> Q { q(self.0 * o.1 + o.0 * self.1, self.1 * o.1) } }
impl Sub for Q { type Output = Q; fn sub(self, o: Q) -> Q { q(self.0 * o.1 - o.0 * self.1, self.1 * o.1) } }
impl Mul for Q { type Output = Q; fn mul(self, o: Q) -> Q { q(self.0 * o.0, self.1 * o.1) } }
impl Div for Q { type Output = Q; fn div(self, o: Q) -> Q { q(self.0 * o.1, self.1 * o.0) } }
impl fmt::Display for Q {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        if self.1 == 1 { write!(f, "{}", self.0) } else { write!(f, "{}/{}", self.0, self.1) }
    }
}
fn fl(x: Q) -> f64 { x.0 as f64 / x.1 as f64 }
type M = Vec<Vec<Q>>;
const NAMES: [&str; 3] = ["sunny", "cloudy", "rainy"];
const TENTHS: [[i128; 3]; 3] = [[6, 3, 1], [4, 4, 2], [4, 3, 3]]; // row = today, column = tomorrow

fn solve(a: &M, b: &[Q]) -> Vec<Q> { // exact Gaussian elimination
    let n = a.len();
    let mut m: M = (0..n).map(|i| { let mut r = a[i].clone(); r.push(b[i]); r }).collect();
    for c in 0..n {
        let piv = (c..n).find(|&r| m[r][c].0 != 0).unwrap();
        m.swap(c, piv);
        for r in 0..n {
            if r != c && m[r][c].0 != 0 {
                let f = m[r][c] / m[c][c];
                for k in 0..=n { m[r][k] = m[r][k] - f * m[c][k]; }
            }
        }
    }
    (0..n).map(|i| m[i][n] / m[i][i]).collect()
}
fn eye(i: usize, j: usize) -> Q { if i == j { q(1, 1) } else { q(0, 1) } }
fn balance(p: &M, left: bool) -> Vec<Q> { // pi P = pi (left) or P x = x (right), sum 1
    let n = p.len();
    let mut a: M = (0..n).map(|j| (0..n).map(|i| (if left { p[i][j] } else { p[j][i] }) - eye(i, j)).collect()).collect();
    a[n - 1] = vec![q(1, 1); n]; // one balance equation is spare: swap in the total
    let mut b = vec![q(0, 1); n];
    b[n - 1] = q(1, 1);
    solve(&a, &b)
}
fn mean_return(p: &M, j: usize) -> Q { // first-step equations for days until j
    let others: Vec<usize> = (0..p.len()).filter(|&i| i != j).collect();
    let a: M = others.iter().map(|&x| others.iter().map(|&y| eye(x, y) - p[x][y]).collect()).collect();
    let h = solve(&a, &vec![q(1, 1); others.len()]);
    others.iter().zip(h.iter()).fold(q(1, 1), |s, (&k, &hk)| s + p[j][k] * hk)
}
fn vecmat(v: &[Q], p: &M) -> Vec<Q> {
    (0..p[0].len()).map(|j| (0..v.len()).fold(q(0, 1), |s, i| s + v[i] * p[i][j])).collect()
}
struct SplitMix64(u64);
impl SplitMix64 {
    fn uniform(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
}
fn step(g: &mut SplitMix64, today: usize) -> usize {
    let (u, mut acc) = (g.uniform(), 0);
    for j in 0..3 {
        acc += TENTHS[today][j];
        if u < acc as f64 / 10.0 { return j; }
    }
    2
}
fn join<T: fmt::Display>(v: &[T]) -> String { v.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(", ") }
fn f2(v: &[f64]) -> String { v.iter().map(|x| format!("{:.2}", x)).collect::<Vec<_>>().join(", ") }

fn main() {
    let p: M = TENTHS.iter().map(|r| r.iter().map(|&x| q(x, 10)).collect()).collect();
    let (days, blocks, seed) = (100000usize, 100usize, 20260929u64);
    let pi = balance(&p, true);
    println!("table P, rows today sunny, cloudy, rainy: {}", p.iter().map(|r| r.iter().map(|&x| format!("{:.1}", fl(x))).collect::<Vec<_>>().join(", ")).collect::<Vec<_>>().join("; "));
    println!("road 1, balance equations: {}", (0..3).map(|i| format!("{} {}", NAMES[i], pi[i])).collect::<Vec<_>>().join(", "));
    let m: Vec<Q> = (0..3).map(|j| mean_return(&p, j)).collect();
    println!("road 2, mean days between visits: {}", (0..3).map(|j| format!("{} {}", NAMES[j], m[j])).collect::<Vec<_>>().join(", "));
    println!("road 2, one over those: {}", (0..3).map(|j| format!("{} {}", NAMES[j], q(1, 1) / m[j])).collect::<Vec<_>>().join(", "));
    assert!((0..3).all(|j| q(1, 1) / m[j] == pi[j])); // two exact roads agree
    assert_eq!(vecmat(&pi, &p), pi); // includes the balance equation that was swapped out
    println!("hand, sunny: pi_S = pi_C + pi_R and sum 1 give pi_S = {}", pi[0]);
    let pr = (p[0][2] * pi[0] + p[1][2] * (q(1, 1) - pi[0])) / (q(1, 1) - p[2][2] + p[1][2]); // rainy balance, pi_C = 1/2 - pi_R
    assert_eq!(pr, pi[2]); // the hand route lands on road 1
    println!("hand, rainy: 0.7 pi_R = 0.1 (1/2) + 0.2 (1/2 - pi_R), so 0.9 pi_R = 0.15, pi_R = {}", pr);
    println!("hand, spare cloudy equation: {:.4} + {:.4} + {:.4} = {}", fl(pi[0] * p[0][1]), fl(pi[1] * p[1][1]), fl(pi[2] * p[2][1]), vecmat(&pi, &p)[1]);
    println!("rainy days in a 365-day year: {:.2}", fl(q(365, 1) * pi[2]));
    println!("excursion from rain, expected days of each kind, pi times m_R: {}", join(&pi.iter().map(|&x| x * m[2]).collect::<Vec<_>>()));
    println!("detailed balance fails: pi_S p_SR = {:.4}, pi_R p_RS = {:.4}", fl(pi[0] * p[0][2]), fl(pi[2] * p[2][0]));
    println!("flow, out of rainy per day: {}; into rainy: {}", pi[2] * (q(1, 1) - p[2][2]), pi[0] * p[0][2] + pi[1] * p[1][2]);

    let (mut g, mut today, mut counts, mut blk, mut cur) = (SplitMix64(seed), 0usize, [0usize; 3], Vec::new(), [0usize; 3]);
    let marks = [10usize, 30, 100, 300, 1000, 3000, 10000, 30000, 100000];
    let mut running = Vec::new();
    for d in 1..=days { // day 0 is sunny; count days 1 .. days
        today = step(&mut g, today);
        counts[today] += 1;
        cur[today] += 1;
        if d % (days / blocks) == 0 { blk.push(cur); cur = [0; 3]; }
        if marks.contains(&d) { running.push(100.0 * counts[2] as f64 / d as f64); }
    }
    println!("figure, rainy days per 100, running, days {}: {}; exact {:.2}", join(&marks), f2(&running), 100.0 * fl(pi[2]));
    let frac: Vec<f64> = counts.iter().map(|&c| c as f64 / days as f64).collect();
    let bs = (days / blocks) as f64;
    let ses: Vec<f64> = (0..3).map(|i| (blk.iter().map(|b| (b[i] as f64 / bs - frac[i]).powi(2)).sum::<f64>() / (blocks - 1) as f64 / blocks as f64).sqrt()).collect();
    let se = ses[2];
    let naive = (frac[2] * (1.0 - frac[2]) / days as f64).sqrt();
    println!("road 3, simulated shares of 100000 days: {}", (0..3).map(|i| format!("{} {:.4} +- {:.4}", NAMES[i], frac[i], ses[i])).collect::<Vec<_>>().join(", "));
    println!("road 3, rainy share {:.4} +- {:.4} (100 blocks of 1000 days); naive iid s.e. {:.4}", frac[2], se, naive);
    println!("road 3, rainy days {}, days per rainy day, simulated: {:.2} +- {:.2}; exact mean return {}", counts[2], days as f64 / counts[2] as f64, se / frac[2].powi(2), m[2]);
    assert!((0..3).all(|i| (frac[i] - fl(pi[i])).abs() < 4.0 * ses[i])); // simulation against the exact shares

    let pf: Vec<Vec<f64>> = p.iter().map(|r| r.iter().map(|&x| fl(x)).collect()).collect();
    let (mut v, mut fc) = (vec![1.0f64, 0.0, 0.0], vec![0.0f64; 61]);
    for n in 1..=60 {
        v = (0..3).map(|j| (0..3).map(|i| v[i] * pf[i][j]).sum()).collect();
        fc[n] = v[2];
    }
    println!("forecast, chance of rain n days after a sunny day, n = 1, 2, 3, 5, 10: {}", [1, 2, 3, 5, 10].iter().map(|&n| format!("{:.4}", fc[n])).collect::<Vec<_>>().join(", "));
    assert!((fc[60] - fl(pi[2])).abs() < 1e-12); // this chain's forecasts settle (next card: why)

    println!("mistake, column convention P x = x: rainy {} (uniform, since rows sum to 1)", balance(&p, false)[2]);
    println!("mistake, average of the rain column: {}", (p[0][2] + p[1][2] + p[2][2]) / q(3, 1));
    println!("mistake, rain after rain read as the share: {}", p[2][2]);
    let (o, z) = (q(1, 1), q(0, 1));
    let rota: M = vec![vec![z, o, z], vec![z, z, o], vec![o, z, z]];
    let rp = balance(&rota, true);
    println!("rota sunny -> cloudy -> rainy -> sunny: stationary {}", join(&rp));
    let (mut v, mut st, mut seen, mut fcr, mut frr) = (vec![o, z, z], 0usize, 0usize, Vec::new(), Vec::new());
    for n in 1..=12 {
        v = vecmat(&v, &rota);
        st = (st + 1) % 3;
        if st == 2 { seen += 1; }
        fcr.push(100.0 * fl(v[2]));
        frr.push(100.0 * seen as f64 / n as f64);
    }
    println!("figure, rota, chance of rain on day n (per 100), n = 1..12: {}", f2(&fcr));
    println!("figure, rota, rainy days per 100 up to day n, n = 1..12: {}", f2(&frr));
    assert!(fcr[9] == 0.0 && fcr[10] == 100.0); // day 10 dry for sure, day 11 wet for sure: no settling
    assert!((frr[11] - 100.0 * fl(rp[2])).abs() < 1e-9); // yet the share of rainy days is the stationary 1/3
    let h = q(1, 2);
    let split: M = vec![vec![h, h, z], vec![h, h, z], vec![z, z, o]];
    let (a, b) = (vec![h, h, z], vec![z, z, o]);
    assert!(vecmat(&a, &split) == a && vecmat(&b, &split) == b);
    println!("split climate (rain stays, dry stays dry): stationary (1/2, 1/2, 0) and (0, 0, 1); rainy share 0 or 1");
    let s6 = q(1, 6); // classifying-states' board: start S, ring A, B, C, jail J
    let board: M = vec![vec![o - s6, s6, z, z, z], vec![z, z, h, z, h], vec![z, h, z, h, z], vec![z, z, h, z, h], vec![z, s6, z, z, o - s6]];
    let bp = balance(&board, true);
    println!("one closed class plus a transient start (classifying-states' board, S A B C J): stationary {}", join(&bp));
    assert!(bp[0] == z); // the transient start gets share 0
    assert_eq!(vecmat(&bp, &board), bp); // includes the balance equation that was swapped out
    let tr: M = [[6, 3, 1], [4, 4, 2], [2, 3, 5]].iter().map(|r| r.iter().map(|&x| q(x, 10)).collect()).collect();
    println!("try, rain stays with 0.5 (rainy row 0.2, 0.3, 0.5): {}; rain returns every {} days", join(&balance(&tr, true)), mean_return(&tr, 2));
    let r: Vec<f64> = pi.iter().map(|&x| 40.0 * (fl(x) / 0.5).sqrt()).collect();
    println!("figure, circle radius 40 sqrt(share / 0.5): {}; centres (80, 160), (280, 160), (180, 62)", (0..3).map(|i| format!("{} {:.2}", NAMES[i], r[i])).collect::<Vec<_>>().join(", "));
    println!("ALL CHECKS PASS");
}
