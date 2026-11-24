// Gas storage and swing contracts -- the check behind the card.  std only, no crates.
// The 25-05 Henry Hub strip (USD/MMBtu, Apr..Mar).  A store holds 100 units (1 unit =
// 10,000 MMBtu), moves at most 25 a month, and starts and ends empty.  The month's price
// reverts (speed 3 a year, volatility 60%) on a trinomial tree fitted to the strip.
const MON: [&str; 12] = ["Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec", "Jan", "Feb", "Mar"];
const F: [f64; 12] = [2.70, 2.55, 2.50, 2.50, 2.55, 2.62, 2.75, 3.05, 3.35, 3.50, 3.40, 3.05];
const R: f64 = 0.05; const C: f64 = 0.02; const CAP: i32 = 100; const LIM: i32 = 25;
const KAP: f64 = 3.0; const SIG: f64 = 0.60; const SUB: usize = 8; const K: f64 = 3.00; const NR: i32 = 4;
type Mat = Vec<Vec<f64>>; type Pol = Vec<Vec<Vec<i32>>>;
fn cash(a: i32, p: f64) -> f64 { (-a) as f64 * p - C * a.abs() as f64 } // buy a units, pay the cost
fn disc() -> Vec<f64> { (0..12).map(|m| (-R * m as f64 / 12.0).exp()).collect() }

fn intrinsic(curve: &[f64], m0: usize, i0: i32, lim: i32) -> (f64, i32) { // road 1: backwards
    let d = disc();
    let mut v: Vec<f64> = (0..5).map(|l| if l == 0 { 0.0 } else { -1e18 }).collect();
    let mut w = vec![(0.0, 0); 5];
    for m in (m0..12).rev() {
        for l in 0..5 {
            let mut b = (f64::NEG_INFINITY, 0);
            for a in (-lim..=lim).step_by(25).filter(|a| (0..=CAP).contains(&(25 * l as i32 + a))) {
                let x = cash(a, curve[m]) * d[m] / d[m0] + v[((25 * l as i32 + a) / 25) as usize];
                if x > b.0 || (x == b.0 && a > b.1) { b = (x, a); }
            }
            w[l] = b;
        }
        for l in 0..5 { v[l] = w[l].0; }
    }
    w[(i0 / 25) as usize]
}

fn tree(kap: f64, sig: f64) -> (Mat, Mat, Mat, usize, f64) {
    let dt = 1.0 / 12.0 / SUB as f64; let mm = (-kap * dt).exp() - 1.0;
    let dy = (3.0 * sig * sig * (1.0 - (-2.0 * kap * dt).exp()) / (2.0 * kap)).sqrt();
    let jm = (0.184 / -mm).ceil() as i64; let n = (2 * jm + 1) as usize;
    let mut p = vec![vec![0.0; n]; n];
    for j in -jm..=jm {
        let (q, m) = ((j * j) as f64 * mm * mm, j as f64 * mm);
        let br = if j == jm {
            [(j, 7.0/6.0 + (q + 3.0*m)/2.0), (j-1, -1.0/3.0 - q - 2.0*m), (j-2, 1.0/6.0 + (q + m)/2.0)]
        } else if j == -jm {
            [(j+2, 1.0/6.0 + (q - m)/2.0), (j+1, -1.0/3.0 - q + 2.0*m), (j, 7.0/6.0 + (q - 3.0*m)/2.0)]
        } else { [(j+1, 1.0/6.0 + (q + m)/2.0), (j, 2.0/3.0 - q), (j-1, 1.0/6.0 + (q - m)/2.0)] };
        for (k, pr) in br { p[(j + jm) as usize][(k + jm) as usize] += pr; }
    }
    let mut t = p.clone();
    for _ in 0..SUB - 1 { t = (0..n).map(|i| (0..n).map(|j| (0..n).fold(0.0, |s, k| s + t[i][k] * p[k][j])).collect()).collect(); }
    let mut qm: Mat = vec![(0..n).map(|i| if i == jm as usize { 1.0 } else { 0.0 }).collect()];
    for m in 0..11 { let row = (0..n).map(|k| (0..n).fold(0.0, |s, i| s + qm[m][i] * t[i][k])).collect(); qm.push(row); }
    let mut s: Mat = vec![(0..n).map(|i| ((i as i64 - jm) as f64 * dy).exp()).collect(); 12];
    for m in 0..12 { let sh = F[m] / (0..n).fold(0.0, |a, i| a + qm[m][i] * s[m][i]); for i in 0..n { s[m][i] *= sh; } }
    (t, qm, s, jm as usize, dy)
}

// backwards over (month, node, state); states are 0, step, 2 step, ...; ties keep the larger state
fn dp(t: &Mat, s: &Mat, ns: usize, step: i32, moves: &dyn Fn(i32, f64) -> Vec<(i32, f64)>, end: &dyn Fn(i32) -> f64) -> (Mat, Pol) {
    let n = t.len(); let g = (-R / 12.0).exp();
    let mut v: Mat = (0..ns).map(|x| vec![end(x as i32 * step); n]).collect();
    let mut pol = vec![vec![vec![0; ns]; n]; 12];
    for m in (0..12).rev() {
        let c: Mat = (0..ns).map(|x| (0..n).map(|i| if m < 11 { g * (0..n).fold(0.0, |a, k| a + t[i][k] * v[x][k]) } else { end(x as i32 * step) }).collect()).collect();
        for x in 0..ns {
            for i in 0..n {
                let mut b = (f64::NEG_INFINITY, -1);
                for (s2, cf) in moves(x as i32 * step, s[m][i]) {
                    let y = cf + c[(s2 / step) as usize][i];
                    if y > b.0 || (y == b.0 && s2 > b.1) { b = (y, s2); }
                }
                v[x][i] = b.0; pol[m][i][x] = b.1;
            }
        }
    }
    (v, pol)
}
fn st(i: i32, p: f64) -> Vec<(i32, f64)> { [-25, 0, 25].iter().filter(|&&a| (0..=CAP).contains(&(i + a))).map(|&a| (i + a, cash(a, p))).collect() }
fn sw(n: i32, p: f64) -> Vec<(i32, f64)> { let mut v = vec![(n, 0.0)]; if n > 0 { v.push((n - 1, (p - K).max(0.0))); } v }
fn emp(i: i32) -> f64 { if i == 0 { 0.0 } else { -1e18 } } // the store must end empty
fn storage(kap: f64, sig: f64) -> f64 { let (t, _, s, jm, _) = tree(kap, sig); dp(&t, &s, 5, 25, &st, &emp).0[0][jm] }
fn ncdf(x: f64) -> f64 { // bell-curve area, Simpson's rule
    let h = x / 2000.0; let mut s = 1.0 + (-x * x / 2.0).exp();
    for k in 1..2000 { let z = k as f64 * h; s += (if k % 2 == 1 { 4.0 } else { 2.0 }) * (-z * z / 2.0).exp(); }
    0.5 + s * h / 3.0 / (2.0 * std::f64::consts::PI).sqrt()
}

fn main() {
    let d = disc(); let iv = intrinsic(&F, 0, 0, LIM).0;
    let (mut best, mut plan) = (-1e18, [0i32; 12]);          // road 2: try all 3^12 schedules
    for code in 0..531441u32 {
        let (mut s, mut x) = ([0i32; 12], code); for m in (0..12).rev() { s[m] = (x % 3) as i32 * 25 - 25; x /= 3; }
        let (mut lev, mut ok, mut val) = (0, true, 0.0);
        for m in 0..12 { lev += s[m]; ok &= (0..=CAP).contains(&lev); val += cash(s[m], F[m]) * d[m]; }
        if ok && lev == 0 && val > best { best = val; plan = s; }
    }
    let (t, q, s, jm, dy) = tree(KAP, SIG); let n = t.len();
    let (stor, spol) = dp(&t, &s, 5, 25, &st, &emp);
    let (swv, wpol) = dp(&t, &s, 13, 1, &sw, &|_| 0.0);
    let mut gg = vec![vec![vec![0.0; n]; 12]; 12];            // gg[m][t][i]: forward for t at node i, month m
    for tt in 0..12 {
        let mut v = s[tt].clone();
        for m in (0..=tt).rev() { gg[m][tt] = v.clone(); v = (0..n).map(|i| (0..n).fold(0.0, |a, k| a + t[i][k] * v[k])).collect(); }
    }
    let (mut dist, mut ri, mut rp): (Vec<((usize, i32), f64)>, f64, Pol) = (vec![((jm, 0), 1.0)], 0.0, vec![vec![vec![0; 5]; n]; 12]); // rolling intrinsic
    for m in 0..12 {
        let mut nd: Vec<((usize, i32), f64)> = Vec::new();
        for &((i, lv), p) in &dist {
            let curve: Vec<f64> = (0..12).map(|tt| if tt < m { 0.0 } else { gg[m][tt][i] }).collect();
            let a = intrinsic(&curve, m, lv, LIM).1; rp[m][i][(lv / 25) as usize] = a;
            ri += p * d[m] * cash(a, s[m][i]);
            for k in 0..(if m < 11 { n } else { 0 }) {
                let key = (k, lv + a); let add = p * t[i][k];
                match nd.iter_mut().find(|e| e.0 == key) { Some(e) => e.1 += add, None => nd.push((key, 0.0 + add)) }
            }
        }
        dist = nd;
    }
    let (mut eur, mut b76) = (vec![], vec![]); for m in 0..12 {
        eur.push(d[m] * (0..n).fold(0.0, |a, i| a + q[m][i] * (s[m][i] - K).max(0.0)));
        let v = SIG * SIG * (1.0 - (-2.0 * KAP * m as f64 / 12.0).exp()) / (2.0 * KAP); let sd = v.sqrt();
        let dd = if sd > 0.0 { ((F[m] / K).ln() + v / 2.0) / sd } else { 0.0 };
        b76.push(if sd > 0.0 { d[m] * (F[m] * ncdf(dd) - K * ncdf(dd - sd)) } else { d[m] * (F[m] - K).max(0.0) });
    }
    let mut srt = eur.clone(); srt.sort_by(|a, b| a.partial_cmp(b).unwrap()); let top4 = srt[12 - NR as usize..].iter().fold(0.0, |a, x| a + x);
    let (np, mut acc, mut state) = (20000, [0.0f64; 8], 20261123u64); // road 3: walk the tree's own paths
    for _ in 0..np {
        let (mut i, mut lv, mut nn, mut lj, mut w1, mut w2, mut w3) = (jm, 0i32, NR, 0i32, 0.0, 0.0, 0.0);
        for m in 0..12 {
            let (i2, n2, a) = (spol[m][i][(lv / 25) as usize], wpol[m][i][nn as usize], rp[m][i][(lj / 25) as usize]); w1 += d[m] * cash(i2 - lv, s[m][i]);
            w2 += d[m] * (s[m][i] - K).max(0.0) * (nn - n2) as f64; w3 += d[m] * cash(a, s[m][i]); lv = i2; nn = n2; lj += a;
            state = state.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
            let (mut u, mut k) = ((state >> 11) as f64 / 9007199254740992.0, 0);
            while k < n - 1 && u > t[i][k] { u -= t[i][k]; k += 1; }
            i = k;
        }
        let add = [w1, w1 * w1, w2, w2 * w2, w3, w3 * w3, w1 - w3, (w1 - w3) * (w1 - w3)]; for k in 0..8 { acc[k] += add[k]; } assert!(lv == 0 && lj == 0, "store ends empty");
    }
    let npf = np as f64; let mc: Vec<f64> = (0..4).map(|k| acc[2 * k] / npf).collect(); // storage, swing, rolling, storage minus rolling
    let sem: Vec<f64> = (0..4).map(|k| ((acc[2 * k + 1] / npf - mc[k] * mc[k]) / npf).sqrt()).collect(); let st0 = stor[0][jm];
    println!("store {} units of 10,000 MMBtu, {} a month, cost {:.2}, r {:.2}, kappa {:.1}, sigma {:.2}\ntree: {} steps a month, {} nodes, \
              log-price step {:.4}; swing strike {:.2}, {} rights", CAP, LIM, C, R, KAP, SIG, SUB, n, dy, K, NR);
    println!("month  forward  plan  level  discount  cash today");
    let mut lev = 0; for m in 0..12 { lev += plan[m]; println!("{:<6} {:7.2} {:+5} {:6} {:9.6} {:11.4}", MON[m], F[m], plan[m], lev, d[m], cash(plan[m], F[m]) * d[m]); }
    println!("intrinsic, backwards over inventory  {:9.4}\nintrinsic, all 3^12 schedules        {:9.4}", iv, best);
    println!("rolling intrinsic, exact on the tree {:9.4}\n  simulated, 20,000 paths            {:9.4}  s.e. {:.4}", ri, mc[2], sem[2]);
    println!("storage on the tree, backwards       {:9.4}\n  simulated, 20,000 paths            {:9.4}  s.e. {:.4}\n  full minus rolling, exact {:.4}, same paths {:.4}  s.e. {:.4}", st0, mc[0], sem[0], st0 - ri, mc[3], sem[3]);
    println!("extrinsic: rolling, full tree        {:9.4} {:9.4}", ri - iv, st0 - iv);
    let gap = (0..12).map(|tt| (gg[0][tt][jm] - F[tt]).abs()).fold(0.0, f64::max); // each month's prices rolled back to 1 April
    println!("tree rolled back = strip, every month{:>9}", if gap < 1e-12 { "yes" } else { "no" });
    println!("month  European tree  Black-76"); for m in 0..12 { println!("{:<6} {:13.4} {:9.4}", MON[m], eur[m], b76[m]); }
    let (se, sb) = (eur.iter().fold(0.0, |a, x| a + x), b76.iter().fold(0.0, |a, x| a + x));
    println!("strip of 12 Europeans, tree, B76     {:9.4} {:9.4}", se, sb);
    println!("swing, 12 rights on the tree         {:9.4}\nswing, 1 right = one American        {:9.4}", swv[12][jm], swv[1][jm]);
    println!("swing, 4 rights                      {:9.4}", swv[NR as usize][jm]);
    println!("  simulated, 20,000 paths            {:9.4}  s.e. {:.4}", mc[1], sem[1]);
    println!("4 American options                   {:9.4}\nbest 4 Europeans, fixed months       {:9.4}", NR as f64 * swv[1][jm], top4);
    println!("dollars: intrinsic {:.0}, tree {:.0}, swing {:.0}, 4 Americans {:.0}", iv * 1e4, st0 * 1e4, swv[NR as usize][jm] * 1e4, NR as f64 * swv[1][jm] * 1e4);
    println!("lowest price that uses a right, by rights left 1 2 3 4");
    for m in [8, 9, 10, 11] {
        let row: Vec<String> = (1..=4).map(|r| format!("{:5.2}", (0..n).filter(|&i| wpol[m][i][r] < r as i32).map(|i| s[m][i]).fold(f64::INFINITY, f64::min))).collect();
        println!("  {}  {}", MON[m], row.join(" "));
    }
    println!("wrong: no 25-a-month limit           {:9.4}\ntry: 50 a month, intrinsic           {:9.4}", intrinsic(&F, 0, 0, 100).0, intrinsic(&F, 0, 0, 50).0);
    println!("try: sigma 30%, storage              {:9.4}\ntry: kappa 1, storage                {:9.4}", storage(KAP, 0.30), storage(1.0, SIG));
    assert!((iv - best).abs() < 1e-9 && plan == [0, 25, 25, 25, 25, 0, 0, -25, -25, -25, -25, 0], "two intrinsic roads");
    assert!(gap < 1e-12, "tree reprices the strip"); let hand = [1usize, 2, 3, 4, 7, 8, 9, 10].iter().fold(0.0, |a, &m| a + d[m] * 25.0 * if m > 6 { F[m] - C } else { -(F[m] + C) });
    assert!((iv - hand).abs() < 1e-9, "intrinsic = hand sum");
    assert!((0..12).all(|m| (eur[m] - b76[m]).abs() < 0.003), "tree Europeans match Black-76"); assert!((swv[12][jm] - se).abs() < 1e-9, "12 rights = the strip of Europeans");
    assert!(iv < ri && ri < st0, "intrinsic < rolling intrinsic < full tree"); assert!(top4 < swv[NR as usize][jm] && swv[NR as usize][jm] < NR as f64 * swv[1][jm], "swing between bounds");
    assert!((mc[0] - st0).abs() < 3.0 * sem[0] && (mc[1] - swv[NR as usize][jm]).abs() < 3.0 * sem[1], "simulation agrees");
    assert!((mc[2] - ri).abs() < 3.0 * sem[2] && (mc[3] - (st0 - ri)).abs() < 3.0 * sem[3], "rolling intrinsic agrees with its paths");
    println!("ALL CHECKS PASS");
}
