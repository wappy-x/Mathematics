// Policy gradients and actor-critic -- the same check as the Python, in Rust.  No crates.
// Part 1: one state, two actions, softmax at (0, 0); action 1 pays 1, action 2 pays 0.
// Part 2: the 20-level reservoir of the MDP card (release 1, 2 or 3 bands; GBP thousands; maximise; 0.95).
const N: usize = 20; const G: f64 = 0.95; const S0: usize = 10;
const RAIN: [f64; 5] = [0.1, 0.2, 0.4, 0.2, 0.1]; const PAY: [f64; 4] = [0.0, 40.0, 75.0, 90.0];
const RMAP: [usize; 10] = [0, 1, 1, 2, 2, 2, 2, 3, 3, 4];   // a digit 0-9 gives rain with those chances
struct SplitMix64 { x: u64 }                       // the card's random numbers, seeded
impl SplitMix64 {
    fn next(&mut self) -> u64 {
        self.x = self.x.wrapping_add(0x9E3779B97F4A7C15); let z = (self.x ^ (self.x >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        let z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB); z ^ (z >> 31)
    }
    fn unif(&mut self) -> f64 { (self.next() >> 11) as f64 / 9007199254740992.0 }
}
fn add<I: Iterator<Item = f64>>(xs: I) -> f64 { xs.fold(0.0, |t, x| t + x) }   // plain left-to-right sum
fn soft(h: &[f64]) -> Vec<f64> {                  // softmax: scores into chances
    let m = h.iter().fold(f64::NEG_INFINITY, |m, &x| if x > m { x } else { m });
    let e: Vec<f64> = h.iter().map(|x| (x - m).exp()).collect(); let z = add(e.iter().cloned()); e.iter().map(|x| x / z).collect()
}
fn pick(pi: &[f64], u: f64) -> usize {            // draw an action from chances pi
    let (mut a, mut c) = (0, pi[0]); while u >= c && a < pi.len() - 1 { a += 1; c += pi[a]; } a
}
fn f4(xs: &[f64]) -> String { xs.iter().map(|x| format!("{:.4}", x)).collect::<Vec<_>>().join(",") }
fn sci(x: f64, p: usize) -> String {              // Python's e-format: two-digit exponent
    let s = format!("{:.*e}", p, x); let (m, e) = s.split_once('e').unwrap(); let e: i32 = e.parse().unwrap();
    format!("{}e{}{:02}", m, if e < 0 { "-" } else { "+" }, e.abs())
}
fn gl(pi: &[f64], a: usize) -> Vec<f64> { (0..2).map(|b| (if b == a { 1.0 } else { 0.0 }) - pi[b]).collect() }
fn pg(th: &[f64]) -> Vec<f64> { let pi = soft(th); (0..2).map(|i| add((0..2).map(|a| pi[a] * (1.0 - a as f64) * gl(&pi, a)[i]))).collect() }
fn step(s: usize, a: usize, w: usize) -> (f64, usize) {   // release a + 1 bands, rain w: money, next level
    let out = (a + 1).min(s + w); let t = (N - 1).min(s + w - out); (PAY[out] - if t <= 2 { 100.0 } else { 0.0 }, t)
}
fn solve(a: &[Vec<f64>], b: &[f64]) -> Vec<f64> {  // Gaussian elimination, partial pivoting
    let n = b.len(); let mut m: Vec<Vec<f64>> = (0..n).map(|i| { let mut r = a[i].clone(); r.push(b[i]); r }).collect();
    for c in 0..n {
        let p = (c..n).fold(c, |p, i| if m[i][c].abs() > m[p][c].abs() { i } else { p }); m.swap(c, p);
        for i in c + 1..n { let f = m[i][c] / m[c][c]; for j in c..n + 1 { m[i][j] -= f * m[c][j]; } }
    }
    let mut x = vec![0.0; n];
    for i in (0..n).rev() { x[i] = (m[i][n] - add((i + 1..n).map(|j| m[i][j] * x[j]))) / m[i][i]; }
    x
}
struct Mdp { p: Vec<Vec<Vec<f64>>>, r: Vec<Vec<f64>> }
impl Mdp {
    fn pof(&self, pis: &[Vec<f64>]) -> Vec<Vec<f64>> { (0..N).map(|s| (0..N).map(|j| add((0..3).map(|a| pis[s][a] * self.p[s][a][j]))).collect()).collect() }
    fn value(&self, pis: &[Vec<f64>]) -> Vec<f64> {   // exact value of a (random) rule: (I - g P) V = r
        let pp = self.pof(pis);
        let a: Vec<Vec<f64>> = (0..N).map(|i| (0..N).map(|j| (if i == j { 1.0 } else { 0.0 }) - G * pp[i][j]).collect()).collect();
        solve(&a, &(0..N).map(|s| add((0..3).map(|a| pis[s][a] * self.r[s][a]))).collect::<Vec<_>>())
    }
    fn qv(&self, v: &[f64], s: usize, a: usize) -> f64 { self.r[s][a] + G * add((0..N).map(|j| self.p[s][a][j] * v[j])) }
}
fn argmax(xs: &[f64]) -> usize { (0..xs.len()).fold(0, |b, i| if xs[i] > xs[b] { i } else { b }) }
fn rulestr(rl: &[usize]) -> String { rl.iter().map(|a| (a + 1).to_string()).collect() }
// one-step actor-critic, softmax actor; returns (month, V(10), levels right, rule) at the marks, and the chances
fn ac(m: &Mdp, best: &[usize], months: usize, at: f64, seed: u64, line: bool, marks: &[usize]) -> (Vec<(usize, f64, usize, String)>, Vec<Vec<f64>>) {
    let (mut rng, mut th, mut w, mut s, mut hist) = (SplitMix64 { x: seed }, vec![vec![0.0f64; 3]; N], vec![0.0f64; if line { 2 } else { N }], 0usize, vec![]);
    for t in 0..=months {
        if marks.contains(&t) || t == months {
            let pis: Vec<Vec<f64>> = th.iter().map(|h| soft(h)).collect(); let rl: Vec<usize> = pis.iter().map(|p| argmax(p)).collect();
            hist.push((t, m.value(&pis)[S0], (0..N).filter(|&i| rl[i] == best[i]).count(), rulestr(&rl)));
            if t == months { return (hist, pis); }
        }
        if t % 50 == 0 { s = (rng.next() % N as u64) as usize; }   // a fresh 50-month run from a random level
        let pi = soft(&th[s]); let a = pick(&pi, rng.unif());
        let (r, s2) = step(s, a, RMAP[(rng.next() % 10) as usize]);
        let v = |w: &[f64], x: usize| if line { w[0] + w[1] * (x as f64 - 10.0) / 10.0 } else { w[x] };
        let dl = r + G * v(&w, s2) - v(&w, s);     // TD error: the critic's surprise
        if line { w[0] += 0.01 * dl; w[1] += 0.01 * (s as f64 - 10.0) / 10.0 * dl; } else { w[s] += 0.05 * dl; }
        for b in 0..3 { th[s][b] += at * dl * ((if b == a { 1.0 } else { 0.0 }) - pi[b]); }
        s = s2;
    }
    unreachable!()
}
fn main() {
    // ---- part 1: the two-action example ----
    let (pi0, grad) = (soft(&[0.0, 0.0]), pg(&[0.0, 0.0]));
    let fd = [(soft(&[1e-5, 0.0])[0] - soft(&[-1e-5, 0.0])[0]) / 2e-5, (soft(&[0.0, 1e-5])[0] - soft(&[0.0, -1e-5])[0]) / 2e-5];
    println!("bandit: chances {}; theorem gradient {}; central difference {}", f4(&pi0), f4(&grad), f4(&fd));
    for &(sh, b) in [(0usize, 0.0f64), (0, 0.5), (10, 0.0)].iter() {   // one-play estimates: pay 1 and 0, or 11 and 10
        let est: Vec<Vec<f64>> = (0..2).map(|a| gl(&pi0, a).iter().map(|g| (1.0 - a as f64 + sh as f64 - b) * g + 0.0).collect()).collect();
        let var = add((0..2).map(|a| pi0[a] * (est[a][0] - grad[0]).powi(2)));
        let mut rng = SplitMix64 { x: 11 }; let xs: Vec<f64> = (0..10000).map(|_| est[pick(&pi0, rng.unif())][0]).collect();
        let m = add(xs.iter().cloned()) / 10000.0; let v = add(xs.iter().map(|x| (x - m).powi(2))) / 9999.0;
        println!("pay {},{} baseline {:?}: action 1 gives {}, action 2 gives {}; variance {:.4}; 10000 draws: mean {:.4}, variance {:.4}",
                 1 + sh, sh, b, f4(&est[0]), f4(&est[1]), var, m, v);
        assert!((m - grad[0]).abs() < 4.0 * (var / 10000.0).sqrt() + 1e-12 && (v - var).abs() < 0.02 * var + 1e-12);
    }
    let mut th = vec![0.0f64, 0.0];                // exact gradient ascent, step 0.05, 20 steps
    for _ in 0..20 { let g = pg(&th); th = (0..2).map(|i| th[i] + 0.05 * g[i]).collect(); }
    let asc = soft(&th)[0]; println!("exact gradient ascent, 20 steps of 0.05: chance of action 1 {:.4}", asc);
    for &(sh, base) in [(0usize, false), (0, true), (10, false), (10, true)].iter() {   // REINFORCE, 2000 runs
        let (mut rng, mut fin) = (SplitMix64 { x: 12 }, vec![]);
        for _ in 0..2000 {
            let mut th = vec![0.0f64, 0.0];
            for _ in 0..20 {
                let pi = soft(&th); let a = pick(&pi, rng.unif()); let g = gl(&pi, a);
                let b = if base { pi[0] + sh as f64 } else { 0.0 };   // baseline: the average payment now
                th = (0..2).map(|i| th[i] + 0.05 * (1.0 - a as f64 + sh as f64 - b) * g[i]).collect();
            }
            fin.push(soft(&th)[0]);
        }
        let m = add(fin.iter().cloned()) / 2000.0; let sd = (add(fin.iter().map(|x| (x - m).powi(2))) / 1999.0).sqrt();
        println!("REINFORCE pay {},{} baseline {}: chance of action 1 mean {:.4}, spread {:.4}, runs below 0.5: {}",
                 1 + sh, sh, if base { "True" } else { "False" }, m, sd, fin.iter().filter(|&&x| x < 0.5).count());
        assert!(if sh > 0 && !base { sd > 0.2 } else { (m - asc).abs() < 0.01 });
    }
    // ---- part 2: the reservoir ----
    let mut md = Mdp { p: vec![vec![vec![0.0; N]; 3]; N], r: vec![vec![0.0; 3]; N] };
    for s in 0..N { for a in 0..3 { for w in 0..5 { let (r, t) = step(s, a, w); md.p[s][a][t] += RAIN[w]; md.r[s][a] += RAIN[w] * r; } } }
    let (mut v, mut k, mut ch) = (vec![0.0f64; N], 0, 1.0f64);
    while ch >= 1e-9 {                             // value iteration from V = 0
        let w: Vec<f64> = (0..N).map(|s| (0..3).map(|a| md.qv(&v, s, a)).fold(f64::NEG_INFINITY, f64::max)).collect();
        k += 1; ch = (0..N).fold(0.0, |c, s| f64::max(c, (v[s] - w[s]).abs())); v = w;
    }
    let best: Vec<usize> = (0..N).map(|s| argmax(&(0..3).map(|a| md.qv(&v, s, a)).collect::<Vec<_>>())).collect();
    let vb = md.value(&(0..N).map(|s| (0..3).map(|a| if a == best[s] { 1.0 } else { 0.0 }).collect()).collect::<Vec<_>>());
    let rule = rulestr(&best);
    let cert = (0..N).flat_map(|s| (0..3).map(move |a| (s, a))).fold(f64::NEG_INFINITY, |c, (s, a)| f64::max(c, md.qv(&vb, s, a) - vb[s]));
    let gaps: Vec<String> = (0..N).map(|s| { let mut q: Vec<f64> = (0..3).map(|a| md.qv(&vb, s, a)).collect();
        q.sort_by(|x, y| x.partial_cmp(y).unwrap()); format!("{:.2}", q[2] - q[1]) }).collect();
    println!("value iteration: {} sweeps; rule {}; V*(10) {:.2}; best one-switch gain {}", k, rule, vb[S0], sci(cert, 1));
    println!("gap to second-best release, levels 0-19: {}", gaps.join(","));
    assert!(rule == "11111222223333333333" && cert < 1e-9 && (vb[S0] - v[S0]).abs() < 1e-6);
    let u = vec![vec![1.0 / 3.0; 3]; N]; let (vu, pu) = (md.value(&u), md.pof(&u));   // policy gradient theorem at theta = 0
    let at: Vec<Vec<f64>> = (0..N).map(|i| (0..N).map(|j| (if i == j { 1.0 } else { 0.0 }) - G * pu[j][i]).collect()).collect();
    let d = solve(&at, &(0..N).map(|i| if i == S0 { 1.0 } else { 0.0 }).collect::<Vec<_>>());
    let thm: Vec<Vec<f64>> = (0..N).map(|s| (0..3).map(|a| d[s] * u[s][a] * (md.qv(&vu, s, a) - vu[s])).collect()).collect();
    let jth = |s: usize, a: usize, h: f64| md.value(&(0..N).map(|i| soft(&(0..3).map(|b| if (i, b) == (s, a) { h } else { 0.0 }).collect::<Vec<_>>())).collect::<Vec<_>>())[S0];
    let mut gap = 0.0f64;
    for s in 0..N { for a in 0..3 { gap = gap.max(((jth(s, a, 1e-4) - jth(s, a, -1e-4)) / 2e-4 - thm[s][a]).abs()); } }
    println!("uniform rule: J = V(10) {:.4}; d(10) {:.4}; Q(10,.) {}", vu[S0], d[S0], f4(&(0..3).map(|a| md.qv(&vu, S0, a)).collect::<Vec<_>>()));
    println!("theorem gradient at level 10: {}; largest gap to central differences over 60: {}", f4(&thm[S0]), sci(gap, 1));
    assert!(gap < 1e-4);
    let mut dp = vec![1.0 / N as f64; N];          // semi-gradient TD, straight-line critic, best rule
    for _ in 0..3000 { dp = (0..N).map(|j| add((0..N).map(|s| dp[s] * md.p[s][best[s]][j]))).collect(); }
    let x: Vec<[f64; 2]> = (0..N).map(|s| [1.0, (s as f64 - 10.0) / 10.0]).collect();
    let nx: Vec<Vec<f64>> = (0..N).map(|s| (0..2).map(|j| add((0..N).map(|t| md.p[s][best[s]][t] * x[t][j]))).collect()).collect();
    let mat = |f: &dyn Fn(usize, usize, usize) -> f64| (0..2).map(|i| (0..2).map(|j| add((0..N).map(|s| f(s, i, j)))).collect()).collect::<Vec<Vec<f64>>>();
    let wtd = solve(&mat(&|s, i, j| dp[s] * x[s][i] * (x[s][j] - G * nx[s][j])), &(0..2).map(|i| add((0..N).map(|s| dp[s] * md.r[s][best[s]] * x[s][i]))).collect::<Vec<_>>());
    let wls = solve(&mat(&|s, i, j| dp[s] * x[s][i] * x[s][j]), &(0..2).map(|i| add((0..N).map(|s| dp[s] * x[s][i] * vb[s]))).collect::<Vec<_>>());
    let rms = |w: &[f64]| add((0..N).map(|s| dp[s] * (w[0] + w[1] * x[s][1] - vb[s]).powi(2))).sqrt();
    let (mut rng, mut s, mut w) = (SplitMix64 { x: 5 }, S0, [0.0f64, 0.0]);
    for t in 0..1000000usize {
        let (r, s2) = step(s, best[s], RMAP[(rng.next() % 10) as usize]); let al = 0.05 / (1.0 + t as f64 / 100000.0);
        let dl = r + G * (w[0] + w[1] * x[s2][1]) - (w[0] + w[1] * x[s][1]); w = [w[0] + al * dl, w[1] + al * dl * x[s][1]]; s = s2;
    }
    println!("TD line: exact fixed point {:.2} + {:.2} x; 1,000,000 months of TD {:.2} + {:.2} x", wtd[0], wtd[1], w[0], w[1]);
    let (lv, bound) = ([0usize, 5, 10, 15, 19], rms(&wls) / (1.0 - G * G).sqrt());
    println!("TD line at levels 0,5,10,15,19: {}; true {}", lv.iter().map(|&s| format!("{:.2}", wtd[0] + wtd[1] * x[s][1])).collect::<Vec<_>>().join(","),
             lv.iter().map(|&s| format!("{:.2}", vb[s])).collect::<Vec<_>>().join(","));
    println!("weighted error: TD line {:.2}, best line {:.2}, bound {:.2}", rms(&wtd), rms(&wls), bound);
    assert!((w[0] - wtd[0]).abs() < 0.01 * wtd[0] && (w[1] - wtd[1]).abs() < 0.1 * wtd[1] && rms(&wtd) <= bound);
    let (mut wo, mut wn) = (1.0f64, 1.0f64);       // deadly triad: values w and 2w, step 0.1
    for _ in 0..50 { wo += 0.1 * (G * 2.0 * wo - wo); wn += 0.1 * (G * 2.0 * wn - wn); wn += 0.1 * (0.0 - 2.0 * wn) * 2.0; }
    println!("triad: after 50 updates off-policy w = {:.2}; on-policy w = {}", wo, sci(wn, 2));
    let (hist, pis) = ac(&md, &best, 5000000, 0.0001, 1, false, &[0, 50000, 100000, 200000, 500000, 1000000, 2000000]);
    for (t, v10, ok, rl) in hist.iter() { println!("actor-critic month {}: V(10) {:.2}, levels right {}/20, rule {}", t, v10, ok, rl); }
    let top = pis.iter().map(|p| p.iter().fold(f64::NEG_INFINITY, |m, &x| m.max(x))).fold(f64::INFINITY, f64::min);
    println!("actor-critic: smallest top chance {:.4}; level 9 chances {}", top, f4(&pis[9]));
    let s2 = ac(&md, &best, 5000000, 0.0001, 2, false, &[200000, 1000000, 2000000]).0; let h2 = s2[3].clone();
    let hb = ac(&md, &best, 1000000, 0.003, 1, false, &[]).0.pop().unwrap();
    let hl = ac(&md, &best, 5000000, 0.0001, 1, true, &[]).0.pop().unwrap();
    println!("seed 2: levels right at 200k, 1M, 2M months {}, {}, {}; at 5M rule {}, V(10) {:.2}; step 0.003, 1,000,000 months: rule {}, V(10) {:.2}", s2[0].2, s2[1].2, s2[2].2, h2.3, h2.1, hb.3, hb.1);
    println!("straight-line critic: rule {}, levels right {}/20, V(10) {:.2}", hl.3, hl.2, hl.1);
    let last = &hist[hist.len() - 1];
    assert!(last.3 == rule && vb[S0] - last.1 < 1.0 && h2.3 == rule);
    assert!(hb.3 != rule && hl.3 != rule && wo > 50.0 && wn < 1e-6);
    println!("ALL CHECKS PASS");
}
