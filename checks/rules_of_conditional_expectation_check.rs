// The rules of conditional expectation -- the same check as the Python, in
// Rust.  No crates; exact fractions written out by hand on i128.  The space:
// 48 equally likely points = 12 months x (dry, wet) x gauge error (-3, +1) mm.
// Rainfall X is the month's mean times 3/5 in a dry year, 7/5 in a wet one.
use std::fmt;
use std::ops::{Add, Mul, Sub};

const MEAN: [i128; 12] = [25, 30, 35, 50, 60, 70, 100, 90, 80, 50, 40, 30];
const U: [i128; 4] = [4, 3, 1, 2];        // umbrellas sold per mm, by season
const NAMES: [&str; 4] = ["winter", "spring", "summer", "autumn"];

#[derive(Clone, Copy, PartialEq, Debug)]
struct Q { n: i128, d: i128 }             // n / d, d > 0, lowest terms
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i128, d: i128) -> Q { let g = gcd(n, d).max(1) * d.signum(); Q { n: n / g, d: d / g } }
impl Add for Q { type Output = Q; fn add(self, o: Q) -> Q { q(self.n * o.d + o.n * self.d, self.d * o.d) } }
impl Sub for Q { type Output = Q; fn sub(self, o: Q) -> Q { q(self.n * o.d - o.n * self.d, self.d * o.d) } }
impl Mul for Q { type Output = Q; fn mul(self, o: Q) -> Q { q(self.n * o.n, self.d * o.d) } }
impl PartialOrd for Q {
    fn partial_cmp(&self, o: &Q) -> Option<std::cmp::Ordering> { (self.n * o.d).partial_cmp(&(o.n * self.d)) }
}
impl fmt::Display for Q {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        if self.d == 1 { write!(f, "{}", self.n) } else { write!(f, "{}/{}", self.n, self.d) }
    }
}
impl Q { fn fl(self) -> f64 { self.n as f64 / self.d as f64 } }
fn z(n: i128) -> Q { q(n, 1) }

// a point is 4 * month + 2 * wet + error index, the Python's order
fn x(p: usize) -> Q { q(MEAN[p / 4] * if (p / 2) % 2 == 1 { 7 } else { 3 }, 5) }
fn nerr(p: usize) -> Q { z(if p % 2 == 1 { 1 } else { -3 }) }
fn month(p: usize) -> usize { p / 4 }
fn season(p: usize) -> usize { p / 12 }
fn bimonth(p: usize) -> usize { p / 8 }
fn all(_p: usize) -> usize { 0 }

fn cond(f: &dyn Fn(usize) -> Q, lab: fn(usize) -> usize) -> Vec<Q> {   // road 1: atom averages
    let k = (0..48).map(lab).max().unwrap() + 1;
    let (mut tot, mut mass) = (vec![z(0); k], vec![z(0); k]);
    for p in 0..48 { tot[lab(p)] = tot[lab(p)] + f(p) * q(1, 48); mass[lab(p)] = mass[lab(p)] + q(1, 48); }
    (0..k).map(|a| tot[a] * q(mass[a].d, mass[a].n)).collect()
}
fn defining_identity(cand: &dyn Fn(usize) -> Q, f: &dyn Fn(usize) -> Q, lab: fn(usize) -> usize) -> bool {
    let k = (0..48).map(lab).max().unwrap() + 1;          // road 2: every A in G
    (0..1usize << k).all(|bits| {
        let pts: Vec<usize> = (0..48).filter(|&p| bits >> lab(p) & 1 == 1).collect();
        pts.iter().fold(z(0), |s, &p| s + cand(p) * q(1, 48)) == pts.iter().fold(z(0), |s, &p| s + f(p) * q(1, 48))
    })
}
fn show(v: &[Q]) -> String { v.iter().map(|a| a.to_string()).collect::<Vec<_>>().join(", ") }
fn dec(v: &[Q]) -> String { v.iter().map(|a| format!("{:.2}", a.fl())).collect::<Vec<_>>().join(", ") }
fn splitmix(state: &mut u64) -> u64 {
    *state = state.wrapping_add(0x9E3779B97F4A7C15);
    let mut z = *state;
    z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    z ^ (z >> 31)
}

fn main() {
    println!("space: 48 points, each 1/48; E[X] = {} mm", cond(&x, all)[0]);
    let dw: Vec<String> = (0..12).map(|m| format!("{}/{}", x(4 * m), x(4 * m + 2))).collect();
    println!("X dry/wet by month: {}", dw.join(", "));
    let (by_month, by_season) = (cond(&x, month), cond(&x, season));
    println!("E[X | month]: {}", show(&by_month));
    println!("E[X | season], direct: {}", show(&by_season));
    let tower = cond(&|p| by_month[month(p)], season);
    println!("E[E[X | month] | season]: {}; its mean {}", show(&tower), cond(&|p| tower[season(p)], all)[0]);
    assert!(tower == by_season);
    assert!(defining_identity(&|p| by_month[month(p)], &x, month));      // 4096 events
    assert!(defining_identity(&|p| by_month[month(p)], &x, season));     // tower, 16 events
    println!("defining identity: E[X | month] on all 4096 events of sigma(month); tower on all 16 of sigma(season)");

    // ---- taking out what is known: umbrella sales U(season) times rainfall ----
    let sales = |p: usize| z(U[season(p)]) * x(p);
    let pulled: Vec<Q> = (0..4).map(|s| z(U[s]) * by_season[s]).collect();
    println!("E[U X | season]: {}; U E[X | season]: {}", show(&cond(&sales, season)), show(&pulled));
    assert!(cond(&sales, season) == pulled);
    assert!(defining_identity(&|p| pulled[season(p)], &sales, season));
    println!("E[U X] = {:.1}; wrong E[U] E[X] = {:.1}", cond(&sales, all)[0].fl(), (q(U.iter().sum(), 4) * z(55)).fl());

    // ---- linearity and the independent gauge error: reading R = X + N ----
    let en = cond(&nerr, all)[0];
    println!("E[N | month]: {}; E[N] = {}", show(&cond(&nerr, month)), en);
    let dropped: Vec<Q> = (0..4).map(|s| by_season[s] + en).collect();
    assert!(cond(&|p| x(p) + nerr(p), season) == dropped);
    assert!(defining_identity(&|_p| en, &nerr, month));
    println!("E[X + N | season]: {}", show(&dropped));

    // ---- conditional Jensen: flood payout (X - 50)+, and the square ----
    let flood = |v: Q| if v > z(50) { v - z(50) } else { z(0) };
    let pay = cond(&|p| flood(x(p)), season);
    let at_mean: Vec<Q> = by_season.iter().map(|&v| flood(v)).collect();
    println!("E[(X - 50)+ | season]: {}; (E[X | season] - 50)+: {}", show(&pay), show(&at_mean));
    assert!((0..4).all(|s| pay[s] >= at_mean[s]) && pay[1] > at_mean[1]);
    let sq = cond(&|p| x(p) * x(p), season);
    let cvar = cond(&|p| (x(p) - by_season[season(p)]) * (x(p) - by_season[season(p)]), season);
    let gap: Vec<Q> = (0..4).map(|s| sq[s] - by_season[s] * by_season[s]).collect();
    println!("E[X^2 | season] - E[X | season]^2: {}", dec(&gap));
    assert!(gap == cvar);                                                 // gap = spread

    // ---- what breaks ----
    let bi = cond(&x, bimonth);
    println!("E[X | bimonth]: {}", show(&bi));
    let cross = cond(&|p| bi[bimonth(p)], season);
    println!("not nested, E[E[X | bimonth] | season]: {}", show(&cross));
    assert!(cross != by_season);
    let v = |p: usize| z(if (p / 2) % 2 == 1 { 3 } else { 1 });           // umbrellas per mm, by weather
    let twice: Vec<Q> = by_season.iter().map(|&m| z(2) * m).collect();
    println!("V by weather: E[V X | season]: {}; E[V | season] E[X | season]: {}", show(&cond(&|p| v(p) * x(p), season)), show(&twice));
    assert!(cond(&|p| v(p) * x(p), season) != twice);
    let n2 = |p: usize| nerr(p) - z(if season(p) == 2 { 4 } else { 0 });   // summer evaporation loss
    println!("seasonal error: E[N2 | season]: {}; E[N2] = {}", show(&cond(&n2, season)), cond(&n2, all)[0]);
    assert!(cond(&n2, season) != vec![cond(&n2, all)[0]; 4]);

    // ---- conditional monotone convergence: a gauge that overflows at c mm ----
    let caps: [i128; 7] = [20, 40, 60, 80, 100, 120, 140];
    println!("figure, capacity c (mm): {}", caps.iter().map(|c| c.to_string()).collect::<Vec<_>>().join(", "));
    let rows: Vec<Vec<Q>> = caps.iter().map(|&c| cond(&|p| if x(p) < z(c) { x(p) } else { z(c) }, season)).collect();
    for s in 0..4 {
        let col: Vec<Q> = rows.iter().map(|r| r[s]).collect();
        println!("figure, E[min(X, c) | {}]: {}", NAMES[s], dec(&col));
        assert!(col.windows(2).all(|w| w[0] <= w[1]) && col[6] == by_season[s]);
    }

    // ---- conditional dominated convergence: the burst X_n = n on [0, 1/n) ----
    // Omega = [0, 1) under length; G = {early half [0, 1/2), late half}.
    let k = 1usize << 14;                                                // midpoint rule on the early half
    let mids: Vec<f64> = (0..k).map(|i| (i as f64 + 0.5) / (2 * k) as f64).collect();
    for n in [2i128, 4, 8, 16, 32, 64] {
        let len = if q(1, n) < q(1, 2) { q(1, n) } else { q(1, 2) };
        let early = z(n) * len * z(2);
        let late = z(n) * (if q(1, n) > q(1, 2) { q(1, n) - q(1, 2) } else { z(0) }) * z(2);
        let capped = z(n.min(4)) * len * z(2);
        let r_early = mids.iter().filter(|&&t| t < 1.0 / n as f64).map(|_| n as f64).sum::<f64>() / k as f64;
        let r_cap = mids.iter().filter(|&&t| t < 1.0 / n as f64).map(|_| n.min(4) as f64).sum::<f64>() / k as f64;
        println!("n = {}: E[X_n | early] = {} (midpoint {:.4}); E[X_n | late] = {}; E[min(X_n, 4) | early] = {} (midpoint {:.4})",
                 n, early, r_early, late, capped, r_cap);
        assert!((r_early - early.fl()).abs() < 1e-12 && (r_cap - capped.fl()).abs() < 1e-12);
    }

    // ---- road 3: sampling, SplitMix64, seed 20260929 ----
    let mut state = 20260929u64;
    let (mut tot, mut tot2, mut cnt) = ([0.0f64; 4], [0.0f64; 4], [0usize; 4]);
    println!("sampling: 48000 draws, SplitMix64 seed 20260929");
    for _ in 0..48000 {
        let p = (splitmix(&mut state) % 48) as usize;
        let r = sales(p).fl();
        tot[season(p)] += r; tot2[season(p)] += r * r; cnt[season(p)] += 1;
    }
    for s in 0..4 {
        let m = tot[s] / cnt[s] as f64;
        let se = ((tot2[s] / cnt[s] as f64 - m * m) / cnt[s] as f64).sqrt();
        println!("sampled E[U X | {}] over {} draws = {:.2}, standard error {:.2}", NAMES[s], cnt[s], m, se);
        assert!((m - pulled[s].fl()).abs() < 4.0 * se);
    }
    println!("ALL CHECKS PASS");
}
