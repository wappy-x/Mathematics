// Minimax: the penalty kick as a 2 by 2 game, then the goal mouth as a line.
// std only. The simplex solver, the fractions and every certificate are written out.
use std::fmt;

#[derive(Clone, Copy, PartialEq, PartialOrd)]
struct Fr(i128, i128); // numerator, denominator > 0, always reduced
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn fr(n: i128, d: i128) -> Fr { let g = gcd(n, d) * d.signum(); Fr(n / g, d / g) }
impl std::ops::Add for Fr { type Output = Fr; fn add(self, o: Fr) -> Fr { fr(self.0 * o.1 + o.0 * self.1, self.1 * o.1) } }
impl std::ops::Sub for Fr { type Output = Fr; fn sub(self, o: Fr) -> Fr { fr(self.0 * o.1 - o.0 * self.1, self.1 * o.1) } }
impl std::ops::Mul for Fr { type Output = Fr; fn mul(self, o: Fr) -> Fr { fr(self.0 * o.0, self.1 * o.1) } }
impl std::ops::Div for Fr { type Output = Fr; fn div(self, o: Fr) -> Fr { fr(self.0 * o.1, self.1 * o.0) } }
impl fmt::Display for Fr { fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result { write!(f, "{}/{}", self.0, self.1) } }
fn lt(x: Fr, y: Fr) -> bool { x.0 * y.1 < y.0 * x.1 }
fn fl(x: Fr) -> f64 { x.0 as f64 / x.1 as f64 }

/// Keeper's LP: maximise sum(z) with A z <= 1, z >= 0 (Bland's rule).
/// Returns value V, the LP's prices u, its solution z, kicker's mix p, keeper's mix q.
fn simplex(a: &Vec<Vec<f64>>) -> (f64, Vec<f64>, Vec<f64>, Vec<f64>, Vec<f64>) {
    let (m, n) = (a.len(), a[0].len());
    let mut t: Vec<Vec<f64>> = (0..m).map(|i| {
        let mut r = a[i].clone();
        r.extend((0..m).map(|k| if k == i { 1.0 } else { 0.0 }));
        r.push(1.0); r }).collect();
    let mut z = vec![-1.0; n]; z.extend(vec![0.0; m + 1]);
    let mut basis: Vec<usize> = (0..m).map(|i| n + i).collect();
    loop {
        let col = match (0..n + m).find(|&j| z[j] < -1e-12) { Some(c) => c, None => break };
        let mut best: Option<(f64, usize, usize)> = None;
        for i in 0..m {
            if t[i][col] > 1e-12 {
                let key = (t[i][n + m] / t[i][col], basis[i], i);
                if best.map_or(true, |b| key.0 < b.0 || (key.0 == b.0 && key.1 < b.1)) { best = Some(key); }
            }
        }
        let r = best.unwrap().2;
        let pv = t[r][col]; t[r] = t[r].iter().map(|v| v / pv).collect();
        let tr = t[r].clone();
        for i in 0..m {
            if i != r && t[i][col] != 0.0 {
                let f = t[i][col];
                t[i] = t[i].iter().zip(&tr).map(|(x, y)| x - f * y).collect();
            }
        }
        let f = z[col]; z = z.iter().zip(&tr).map(|(x, y)| x - f * y).collect();
        basis[r] = col;
    }
    let v = 1.0 / z[n + m];
    let mut zq = vec![0.0; n]; for (i, &b) in basis.iter().enumerate() { if b < n { zq[b] = t[i][n + m]; } }
    let u: Vec<f64> = (0..m).map(|i| z[n + i]).collect();
    let (p, q) = (u.iter().map(|x| x * v).collect(), zq.iter().map(|x| x * v).collect());
    (v, u, zq, p, q)
}
/// Certificate: the kicker's mix guarantees lo, the keeper's mix concedes at most hi.
fn bracket(a: &Vec<Vec<f64>>, p: &[f64], q: &[f64]) -> (f64, f64) {
    let (m, n) = (a.len(), a[0].len());
    let lo = (0..n).map(|j| { let mut s = 0.0; for i in 0..m { s += p[i] * a[i][j]; } s }).fold(f64::INFINITY, f64::min);
    let hi = (0..m).map(|i| { let mut s = 0.0; for j in 0..n { s += a[i][j] * q[j]; } s }).fold(f64::NEG_INFINITY, f64::max);
    (lo, hi)
}
/// Plain choices only: kicker first (max-min) and keeper first (min-max).
fn pure(a: &Vec<Vec<f64>>) -> (f64, f64) {
    let mx = a.iter().map(|r| r.iter().cloned().fold(f64::INFINITY, f64::min)).fold(f64::NEG_INFINITY, f64::max);
    let mn = (0..a[0].len()).map(|j| a.iter().map(|r| r[j]).fold(f64::NEG_INFINITY, f64::max)).fold(f64::INFINITY, f64::min);
    (mx, mn)
}
fn pc(x: f64) -> String { format!("{:.4}%", 100.0 * x) }
fn on(x: f64) -> f64 { 0.95 + 0.18 * x - 0.20 * x * x }           // chance the shot is on target
fn save(x: f64) -> f64 { 37.0 / 95.0 + (23.0 / 93.0 - 37.0 / 95.0) * x } // best save chance at aim x
fn score(x: f64, y: f64, w: f64) -> f64 { on(x) * (1.0 - save(x) * f64::max(0.0, 1.0 - (x - y).abs() / w)) }
fn game(n: usize, w: f64) -> (Vec<f64>, Vec<Vec<f64>>) {
    let g: Vec<f64> = (0..n).map(|k| k as f64 / (n - 1) as f64).collect();
    let a = g.iter().map(|&x| g.iter().map(|&y| score(x, y, w)).collect()).collect();
    (g, a)
}
fn list(v: &[f64], d: usize) -> String { format!("[{}]", v.iter().map(|x| format!("'{:.*}'", d, x)).collect::<Vec<_>>().join(", ")) }

fn main() {
    // ---- road 1: the 2 by 2 table, exact fractions and the closed form ----
    let (a, b, c, d) = (fr(58, 100), fr(95, 100), fr(93, 100), fr(70, 100));
    let (one, den) = (fr(1, 1), b + c - a - d);
    let (p_ex, q_ex, v_ex) = ((c - d) / den, (b - d) / den, (b * c - a * d) / den);
    println!("2x2 closed form: p* = {}  q* = {}  V = {} = {}", p_ex, q_ex, v_ex, pc(fl(v_ex)));
    assert!(a * p_ex + c * (one - p_ex) == v_ex && b * p_ex + d * (one - p_ex) == v_ex);
    assert!(a * q_ex + b * (one - q_ex) == v_ex && c * q_ex + d * (one - q_ex) == v_ex);
    let (ai, bi, ci, di) = (58i128, 95i128, 93i128, 70i128); // whole percentage points, for the hand steps
    println!("hand: {}*{} = {}, {}*{} = {}, {}+{}-{}-{} = {}, V = {}/{}", bi, ci, bi * ci, ai, di, ai * di, bi, ci, ai, di, bi + ci - ai - di, bi * ci - ai * di, bi + ci - ai - di);
    println!("wall: (23*{} + 37*{})/60 = ({} + {})/60 and (23*{} + 37*{})/60 = ({} + {})/60", ai, ci, 23 * ai, 37 * ci, bi, di, 23 * bi, 37 * di);
    assert!(fr(23 * ai + 37 * ci, 6000) == v_ex && fr(23 * bi + 37 * di, 6000) == v_ex && fr(bi * ci - ai * di, 100 * (bi + ci - ai - di)) == v_ex);
    // ---- road 2: brute force over mixing rates in steps of 1/6000 ----
    let (mut lo_s, mut lo_k, mut hi_s, mut hi_k) = (fr(-1, 1), 0, fr(2, 1), 0);
    for k in 0..=6000 {
        let t = fr(k, 6000);
        let l1 = a * t + c * (one - t); let l2 = b * t + d * (one - t);
        let lo = if lt(l1, l2) { l1 } else { l2 };
        if !lt(lo, lo_s) && lo != lo_s { lo_s = lo; lo_k = k; }
        let h1 = a * t + b * (one - t); let h2 = c * t + d * (one - t);
        let hi = if lt(h1, h2) { h2 } else { h1 };
        if lt(hi, hi_s) { hi_s = hi; hi_k = k; }
    }
    println!("scan: kicker-first best {} at p = {:.4} | keeper-first best {} at q = {:.4}",
             pc(fl(lo_s)), lo_k as f64 / 6000.0, pc(fl(hi_s)), hi_k as f64 / 6000.0);
    assert!(lo_s == v_ex && hi_s == v_ex);
    let a2 = vec![vec![0.58, 0.95], vec![0.93, 0.70]];
    println!("pure choices: kicker first {} | keeper first {}", pc(pure(&a2).0), pc(pure(&a2).1));
    assert!(pure(&a2) == (0.70, 0.93));
    // ---- road 3: duality. The keeper's LP; the kicker's mix comes out as its prices ----
    let (v2, u, zq, p2, q2) = simplex(&a2);
    println!("keeper LP: z = {} sum = {:.6} = 1/V", list(&zq, 6), zq.iter().sum::<f64>());
    println!("its prices: pi = {} sum = {:.6} (not a mix)", list(&u, 6), u.iter().sum::<f64>());
    println!("rescaled by V: p = {:.4}, q = {:.4}, V = {}", p2[0], q2[0], pc(v2));
    assert!((p2[0] - fl(p_ex)).abs() < 1e-12 && (q2[0] - fl(q_ex)).abs() < 1e-12 && (v2 - fl(v_ex)).abs() < 1e-12);
    for ql in [0.3, 25.0 / 60.0, 0.5] {
        println!("dual function at keeper Left {:.4}: {}", ql, pc(f64::max(0.58 * ql + 0.95 * (1.0 - ql), 0.93 * ql + 0.70 * (1.0 - ql))));
    }
    // ---- the goal mouth as a line: aim u and dive v in goal widths, 0 = kicker's left post ----
    let w = 0.8;
    let la = 0.22 + on(0.45) * ((37.0 / 95.0 - 23.0 / 93.0) + save(0.0) / w);
    let ld = on(0.45) * save(0.0) / w;
    println!("reach w = {}; Lipschitz bounds: aim {:.4}, dive {:.4} per goal width", w, la, ld);
    let corner = game(2, w).1;
    for i in 0..2 { for j in 0..2 { assert!((corner[i][j] - a2[i][j]).abs() < 1e-12); } }
    println!("N   V_N        bracket for the line's value   pure: kicker first  keeper first");
    let mut vals: Vec<(usize, f64, Vec<f64>, Vec<f64>, Vec<f64>)> = vec![];
    for n in [2usize, 3, 5, 9, 17, 33, 65, 129] {
        let (g, am) = game(n, w);
        let (v, _, _, p, q) = simplex(&am);
        let (lo, hi) = bracket(&am, &p, &q);
        assert!((hi - lo).abs() < 1e-9 && lo - 1e-9 <= v && v <= hi + 1e-9);
        let h = 1.0 / (n - 1) as f64;
        let (pmax, pmin) = pure(&am);
        println!("{:<3} {}  [{}, {}]   {}  {}", n, pc(v), pc(v - ld * h / 2.0), pc(v + la * h / 2.0), pc(pmax), pc(pmin));
        assert!(pmax < v - 0.05 && pmin > v + 0.01); // mixing closes a real gap
        vals.push((n, v, p, q, g));
    }
    let lows: Vec<f64> = vals.iter().map(|e| e.1 - ld / (e.0 - 1) as f64 / 2.0).collect();
    let highs: Vec<f64> = vals.iter().map(|e| e.1 + la / (e.0 - 1) as f64 / 2.0).collect();
    let (mlo, mhi) = (lows.iter().cloned().fold(f64::NEG_INFINITY, f64::max), highs.iter().cloned().fold(f64::INFINITY, f64::min));
    println!("all eight brackets meet in [{}, {}]", pc(mlo), pc(mhi));
    assert!(mlo < mhi);
    let get = |n: usize| vals.iter().find(|e| e.0 == n).unwrap().1;
    assert!((get(129) - get(65)).abs() < 0.0001 && 0.0001 < (get(3) - get(2)).abs());
    for e in vals.iter().filter(|e| [9, 33, 129].contains(&e.0)) {
        let (n, g, p, am) = (e.0, &e.4, &e.2, game(e.0, w).1);
        let (_, _, _, p2, q2) = simplex(&am.iter().map(|r| r.iter().rev().cloned().collect()).collect()); // keeper dives right to left
        let q2: Vec<f64> = q2.into_iter().rev().collect();
        let zone = |m: &Vec<f64>, l: f64, h: f64| -> f64 { let mut s = 0.0; for i in 0..n { if (l <= g[i] && g[i] < h) || (h == 1.0 && g[i] == 1.0) { s += m[i]; } } s };
        let kz = [zone(p, 0.0, 0.1), zone(p, 0.1, 0.5), zone(p, 0.5, 0.9), zone(p, 0.9, 1.0)];
        let (mut m1, mut m2) = (0.0, 0.0); for i in 0..n { m1 += p[i] * g[i]; m2 += p[i] * g[i] * g[i]; }
        println!("N = {}: kicker aims {} | posts {:.4} {:.4} | mean aim {:.4}, mean square {:.4}", n, kz.iter().map(|x| format!("{:.4}", x)).collect::<Vec<_>>().join(" "), p[0], p[n - 1], m1, m2);
        let (d1, d2, (lo2, hi2)) = (zone(&e.3, 0.25, 0.5), zone(&q2, 0.25, 0.5), bracket(&am, &p2, &q2));
        println!("  keeper dives 0.25 to 0.5: {:.4} in one best mix, {:.4} in another", d1, d2);
        assert!((kz.iter().sum::<f64>() - 1.0).abs() < 1e-9 && p.iter().zip(&p2).all(|(a, b)| (a - b).abs() < 1e-9)); // kicker: same mix both ways
        assert!((hi2 - lo2).abs() < 1e-9 && (hi2 - e.1).abs() < 1e-9 && (d1 - d2).abs() > 0.04); // keeper: another best mix
    }
    for wt in [1.0, 0.5] {
        println!("try reach w = {:.1}: V_2 = {}, V_3 = {}, V_65 = {}", wt, pc(simplex(&game(2, wt).1).0), pc(simplex(&game(3, wt).1).0), pc(simplex(&game(65, wt).1).0));
    }
    // ---- compactness fails: name the bigger whole number, the larger name wins 1 ----
    println!("bigger number: chooser of n (minimiser) from 1..N, of m (maximiser) from 1..M");
    for (nn, mm) in [(10, 10), (10, 11), (100, 99), (100, 101)] {
        let bm: Vec<Vec<i32>> = (1..=nn).map(|n| (1..=mm).map(|m| if m > n { 1 } else { 0 }).collect()).collect();
        let up = bm.iter().map(|r| *r.iter().max().unwrap()).min().unwrap();
        let low = (0..mm as usize).map(|j| bm.iter().map(|r| r[j]).min().unwrap()).max().unwrap();
        println!("  N = {}, M = {}: value {}", nn, mm, up);
        assert!(up == low && up == if mm > nn { 1 } else { 0 });
    }
    println!("ALL CHECKS PASS");
}
