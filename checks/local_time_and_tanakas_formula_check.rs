// Local time and Tanaka's formula -- the same check as local_time_and_tanakas_formula_check.py,
// in Rust.  Std only, no crates.  Same roads, same seed, same printed lines.
const SEED: u64 = 20261123; const PATHS: usize = 5000; const FINE: usize = 4096;
const GRIDS: [usize; 4] = [16, 64, 256, 1024]; const EPS: f64 = 0.05;
const S0: f64 = 100.0; const K: f64 = 100.0; const SIG: f64 = 20.0; // price, strike, $ per root-year

struct SplitMix64 { s: u64 }
impl SplitMix64 {
    fn uniform(&mut self) -> f64 {
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
    fn normal_pair(&mut self) -> (f64, f64) {
        let (u1, u2) = (self.uniform(), self.uniform());
        let r = (-2.0 * (1.0 - u1).ln()).sqrt();
        let a = 2.0 * std::f64::consts::PI * u2;
        (r * a.cos(), r * a.sin())
    }
}

fn sgn(x: f64) -> f64 { if x > 0.0 { 1.0 } else if x < 0.0 { -1.0 } else { 0.0 } }
fn isgn(x: i64) -> i64 { if x > 0 { 1 } else if x < 0 { -1 } else { 0 } }

fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n { s += (if i % 2 == 1 { 4.0 } else { 2.0 }) * f(a + i as f64 * h); }
    s * h / 3.0
}

fn phi(z: f64) -> f64 { (-0.5 * z * z).exp() / (2.0 * std::f64::consts::PI).sqrt() }

fn walk(steps: &[i64]) -> (Vec<i64>, Vec<i64>, Vec<i64>) {
    let (mut s, mut beta, mut vis) = (vec![0i64], vec![0i64], vec![0i64]);
    for &x in steps {
        let last = *s.last().unwrap();
        beta.push(beta.last().unwrap() + isgn(last) * x);
        vis.push(vis.last().unwrap() + (last == 0) as i64);
        s.push(last + x);
    }
    (s, beta, vis)
}

fn comb(n: u64, k: u64) -> u64 {
    let mut c = 1u64; for i in 0..k { c = c * (n - i) / (i + 1); } c
}

fn mse(xs: &[f64]) -> (f64, f64) {
    let n = xs.len() as f64;
    let mut m = 0.0; for &x in xs { m += x / n; }
    let mut v = 0.0; for &x in xs { v += (x - m) * (x - m) / (n - 1.0); }
    (m, (v / n).sqrt())
}

fn row(label: &str, v: &[i64]) {
    let cells: String = v.iter().map(|x| format!("{:4}", x)).collect();
    println!("{}{}", label, cells);
}

fn main() {
    // 1. the hand path
    let steps = [1, -1, -1, 1, 1, 1, -1, -1, -1, -1];
    let (s, beta, vis) = walk(&steps);
    let ks: Vec<i64> = (0..11).collect();
    row("walk, k        ", &ks);
    row("walk, S_k      ", &s);
    row("walk, |S_k|    ", &s.iter().map(|x| x.abs()).collect::<Vec<_>>());
    row("walk, hedge    ", &beta);
    row("walk, visits   ", &vis);
    println!("hand path: |S_10| = {} = hedge sum {} + visits {}", s[10].abs(), beta[10], vis[10]);
    assert!(s[10].abs() == beta[10] + vis[10]);
    assert!(vis[10] == s[..10].iter().filter(|&&x| x == 0).count() as i64 && vis[10] == 4);

    // 2. all 1024 ten-step paths
    let (mut tot_abs, mut tot_vis, mut bad) = (0i64, 0i64, 0i64);
    for m in 0..1024u32 {
        let st: Vec<i64> = (0..10).map(|i| if (m >> i) & 1 == 1 { 1 } else { -1 }).collect();
        let (p, b, v) = walk(&st);
        tot_abs += p[10].abs(); tot_vis += v[10]; bad += (p[10].abs() != b[10] + v[10]) as i64;
    }
    let binom_abs = (0..11u64).map(|j| ((2 * j as i64 - 10).abs() as u64) * comb(10, j)).sum::<u64>() as f64 / 1024.0;
    let mut binom_vis = 0.0;
    for k in (0..10u64).step_by(2) { binom_vis += comb(k, k / 2) as f64 / 2f64.powi(k as i32); }
    println!("all 1024 paths: identity fails on {}; mean |S_10| {:.4}, mean visits {:.4}",
             bad, tot_abs as f64 / 1024.0, tot_vis as f64 / 1024.0);
    println!("binomials: E|S_10| {:.4}; sum of P(S_k = 0), k < 10, {:.4}", binom_abs, binom_vis);
    assert!(bad == 0 && (tot_vis as f64 / 1024.0 - binom_abs).abs() < 1e-12 && (binom_vis - binom_abs).abs() < 1e-12);

    // 3. scaling: visits / sqrt(n) -> E|B_1|
    let xphi = |x: f64| x * phi(x);
    let target = 2.0 * simpson(&xphi, 0.0, 12.0, 4000);
    let r2pi = (2.0 / std::f64::consts::PI).sqrt();
    println!("E|B_1| by Simpson {:.6}; sqrt(2/pi) {:.6}", target, r2pi);
    let (mut p0, mut acc) = (1.0f64, 0.0f64);
    let mut last: Vec<(usize, f64, f64)> = Vec::new();
    for k in (0..=10000usize).step_by(2) {
        if k > 0 { p0 *= (k - 1) as f64 / k as f64; }
        if [10, 100, 1000, 10000].contains(&k) {
            let r = (k as f64).sqrt();
            last.push((k, acc / r, k as f64 * p0 / r));
        }
        acc += p0;
    }
    for &(n, a, b) in &last { println!("n {:5}: mean visits / sqrt(n) {:.6}; E|S_n| / sqrt(n) {:.6}", n, a, b); }
    assert!((target - r2pi).abs() < 1e-9 && (last[3].1 - target).abs() < 1e-4);
    assert!(last.iter().all(|&(_, a, b)| (a - b).abs() < 1e-12));

    // 4. Brownian paths and the stop-loss hedge, price P = 100 + 20 B, strike 100
    let mut rng = SplitMix64 { s: SEED };
    let dt = 1.0 / FINE as f64;
    let (mut l_tan, mut l_occ, mut over) = (Vec::new(), Vec::new(), 0usize);
    let mut slip: Vec<Vec<f64>> = vec![Vec::new(); 4];
    let mut gap = [0.0f64; 4];
    for _ in 0..PATHS {
        let mut b = vec![0.0f64];
        for _ in 0..FINE / 2 {
            let (z1, z2) = rng.normal_pair();
            let x = b[b.len() - 1] + z1 * dt.sqrt(); b.push(x);
            let y = b[b.len() - 1] + z2 * dt.sqrt(); b.push(y);
        }
        let (mut hedge, mut near) = (0.0f64, 0usize);
        for k in 0..FINE { hedge += sgn(b[k]) * (b[k + 1] - b[k]); near += (b[k].abs() < EPS) as usize; }
        let lt = b[FINE].abs() - hedge;
        l_tan.push(lt); l_occ.push(near as f64 * dt / (2.0 * EPS));
        if lt > 0.5 { over += 1; }
        let pay = (S0 + SIG * b[FINE] - K).max(0.0);
        for (gi, &g) in GRIDS.iter().enumerate() {
            let st = FINE / g;
            let (mut gain, mut j) = (0.0, 0);
            while j < FINE {
                if S0 + SIG * b[j] > K { gain += SIG * (b[j + st] - b[j]); }
                j += st;
            }
            slip[gi].push(pay - gain);
            gap[gi] += (pay - gain - SIG * lt / 2.0).abs() / PATHS as f64;
        }
    }
    let (mt, st_) = mse(&l_tan);
    let (mo, so) = mse(&l_occ);
    let mut pd = 0.0;
    for (a, b) in l_tan.iter().zip(l_occ.iter()) { pd += (a - b).abs() / PATHS as f64; }
    let law = 2.0 * (0.5 - simpson(&phi, 0.0, 0.5, 2000));
    let fr = over as f64 / PATHS as f64;
    let fse = (fr * (1.0 - fr) / PATHS as f64).sqrt();
    let occ = simpson(&|a: f64| 2.0 * phi(a) + 2.0 * a * simpson(&phi, 0.0, a, 200) - a.abs(), -EPS, EPS, 200) / (2.0 * EPS); // mean of E|B_1 - a| - |a|
    println!("Brownian, {} paths of {} steps, seed {}:", PATHS, FINE, SEED);
    println!("  Tanaka leftover |B_1| - sum sgn(B) dB: mean {:.4} (se {:.4})", mt, st_);
    println!("  time within {} of 0, over 2 eps: mean {:.4} (se {:.4}), exact {:.4} at this eps; path gap {:.4}", EPS, mo, so, occ, pd);
    println!("  share with L_1 > 0.5: {:.4} (se {:.4}); reflection law 2 P(B_1 > 0.5) {:.4}", fr, fse, law);
    let call = SIG * simpson(&xphi, 0.0, 12.0, 4000);
    println!("call, P = {} + {} B, strike {}, one year: value {:.4} = half of {} x {:.4}", S0, SIG, K, call, SIG, target);
    for (gi, &g) in GRIDS.iter().enumerate() {
        let (m, e) = mse(&slip[gi]);
        println!("  stop-loss hedge checked {:4} times: mean slippage {:.4} (se {:.4}); path gap to {} L {:.4}",
                 g, m, e, SIG / 2.0, gap[gi]);
        assert!((m - call).abs() < 4.0 * e);
    }
    assert!((mt - target).abs() < 4.0 * st_ && (mo - occ).abs() < 4.0 * so && (fr - law).abs() < 4.0 * fse);
    assert!(gap[0] > gap[1] && gap[1] > gap[2] && gap[2] > gap[3]);
    println!("what breaks:");
    println!("  ordinary Ito on |x| (no curvature off 0): E|B_1| would be 0; it is {:.4}", target);
    println!("  time near 0 divided by eps, not 2 eps: {:.4}; it is {:.4}", 2.0 * mo, mo);
    println!("  slippage as all of {} L, not half: {:.4}; it is {:.4}", SIG, 2.0 * call, call);
    println!("  check {} times to kill slippage: still {:.4}, not 0", GRIDS[3], mse(&slip[3]).0);
    println!("ALL CHECKS PASS");
}
