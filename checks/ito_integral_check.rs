// The Ito integral -- the same check as the Python, in Rust.  No crates.
// Price S_t = 100 + 20 W_t dollars, t in years, W a Brownian motion.  A strategy
// holds H_t shares; its gain is 20 times the Ito integral of H against W.
// Three roads: the formulas; exact enumeration of every path of a coin-toss
// walk, in whole numbers; a seeded simulation of Brownian motion (SplitMix64
// and Box-Muller, written out), each average printed with its standard error.
use std::collections::HashMap;
use std::f64::consts::PI;
const SIGMA: f64 = 20.0;
const T: f64 = 1.0;

struct SplitMix64 { s: u64 }

impl SplitMix64 {
    fn next(&mut self) -> u64 {
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    }
    fn uniform(&mut self) -> f64 { ((self.next() >> 11) as f64 + 0.5) * 2f64.powi(-53) }
    fn normal(&mut self) -> f64 {                       // Box-Muller, cosine branch only
        let (u, v) = (self.uniform(), self.uniform());
        (-2.0 * u.ln()).sqrt() * (2.0 * PI * v).cos()
    }
}

fn walk(code: u64, n: usize) -> Vec<i64> {              // coin-toss walk X_0..X_n; bit k is step k
    let mut x = vec![0i64];
    for k in 0..n { let last = x[k]; x.push(last + if code >> k & 1 == 1 { 1 } else { -1 }) }
    x
}

fn mean_se(s: f64, s2: f64, m: f64) -> (f64, f64) {     // sample mean and its standard error
    let a = s / m;
    (a, ((s2 / m - a * a) * m / (m - 1.0) / m).sqrt())
}

fn main() {
    println!("share S_t = 100 + {:.0} W_t dollars, t in years, horizon T = {:.0} year", SIGMA, T);
    // Road 1: the formulas, from the isometry E[I^2] = E[int H^2 dt]
    let var_half = SIGMA * SIGMA * (2.0 * 2.0 * T / 2.0 + 0.5 * T / 2.0);
    let var_wdw = SIGMA * SIGMA * T * T / 2.0;
    let peek = SIGMA * (T / 2.0).sqrt() / (2.0 * PI).sqrt();
    println!("formula, half-year rule: E[int H^2 dt] = 4 x {:.1} + 0.5 x {:.1} = {:.6}; mean gain 0, variance {:.6}, sd ${:.6}", T / 2.0, T / 2.0, var_half / (SIGMA * SIGMA), var_half, var_half.sqrt());
    println!("formula, hold W_t shares: E[int W_t^2 dt] = T^2/2 = {:.6}; mean gain 0, variance {:.6}, sd ${:.6}", T * T / 2.0, var_wdw, var_wdw.sqrt());
    println!("formula, ordinary chain rule mean ${:.6}, right endpoint mean ${:.6}, peeking rule mean ${:.6}", SIGMA * T / 2.0, SIGMA * T, peek);
    // Road 2: every path of a coin-toss walk with steps of size sqrt(dt), dt = T / n
    for n in [2usize, 6, 10, 14] {                      // half-year rule; n/2 odd, never at 0 then
        let (h, mut s1, mut s2, mut up) = (n / 2, 0i64, 0i64, 0i64);
        let mut cond: HashMap<u64, i64> = HashMap::new();
        for code in 0..1u64 << n {
            let x = walk(code, n);
            let later = if x[h] > 0 { x[n] - x[h] } else { 0 };   // second-half gain / (20 sqrt(dt))
            let b = 2 * x[h] + later;
            s1 += b; s2 += b * b; up += (x[h] > 0) as i64;
            *cond.entry(code & ((1 << h) - 1)).or_insert(0) += later;   // the first-half history
        }
        let paths = 1i64 << n;
        assert!(s1 == 0);
        assert!(4 * s2 == 9 * n as i64 * paths);       // isometry: E[I^2] = 2 + 1/4
        assert!(cond.values().all(|&v| v == 0));        // martingale: future gain averages 0
        println!("enumerated, half-year rule, {} steps, {} paths: P(S >= 100 at half-year) {:.6}, mean gain {:.6}, variance {:.6}, {} histories with future mean 0",
                 n, paths, up as f64 / paths as f64, s1 as f64 / paths as f64, SIGMA * SIGMA * s2 as f64 / (n as i64 * paths) as f64, cond.len());
    }
    for n in [4usize, 8, 16] {                          // hold W_t shares
        let mut s2 = 0i64;
        let mut cond: HashMap<(usize, u64), i64> = HashMap::new();
        for code in 0..1u64 << n {
            let x = walk(code, n);
            let g: Vec<i64> = (0..n).map(|k| x[k] * (x[k + 1] - x[k])).collect();   // each trade's gain / dt
            let mut fut = 0i64;
            for m in (0..n).rev() {                     // gain after each history of length m
                fut += g[m];
                *cond.entry((m, code & ((1 << m) - 1))).or_insert(0) += fut;
            }
            let a = fut;
            assert!(2 * a == x[n] * x[n] - n as i64);   // pathwise: left sum = (W_T^2 - T) / 2
            s2 += a * a;
        }
        let paths = 1i64 << n;
        assert!(2 * s2 == paths * n as i64 * (n as i64 - 1));   // isometry: sum of E[X_k^2] = n(n-1)/2
        assert!(cond.values().all(|&v| v == 0));
        println!("enumerated, hold W_t, {} steps: left sum = (W_T^2 - T)/2 on all {} paths, E[I^2] {:.6}, formula (1 - 1/n)/2 = {:.6}, {} histories with future mean 0",
                 n, paths, s2 as f64 / (n as i64 * n as i64 * paths) as f64, (1.0 - 1.0 / n as f64) / 2.0, cond.len());
    }
    // Road 3: seeded simulation of Brownian motion on a grid
    let mut rng = SplitMix64 { s: 20260930 };
    let (m_paths, steps) = (40000usize, 100usize);
    let sd = (T / steps as f64).sqrt();
    let mut acc = [[0.0f64; 3]; 5];
    for _ in 0..m_paths {
        let (mut w, mut left, mut right, mut wh) = (0.0f64, 0.0f64, 0.0f64, 0.0f64);
        for k in 0..steps {
            let dw = sd * rng.normal();
            left += w * dw; right += (w + dw) * dw; w += dw;
            if k == steps / 2 - 1 { wh = w }
        }
        let gains = [2.0 * wh + if wh >= 0.0 { w - wh } else { 0.0 }, left, right, (w - wh).max(0.0), w * w / 2.0];
        for (a, g0) in acc.iter_mut().zip(gains) {
            let g = g0 * SIGMA; a[0] += g; a[1] += g * g; a[2] += (g * g) * (g * g);
        }
    }
    let names = ["half-year rule", "hold W_t, left endpoint (Ito)", "hold W_t, right endpoint",
                 "peeking rule", "ordinary chain rule 10 W_T^2"];
    let exact_mean = [0.0, 0.0, SIGMA * T, peek, SIGMA * T / 2.0];
    println!("simulated, {} paths, {} steps of {:.2} year, seed 20260930", m_paths, steps, T / steps as f64);
    for i in 0..5 {
        let (m, se) = mean_se(acc[i][0], acc[i][1], m_paths as f64);
        assert!((m - exact_mean[i]).abs() < 4.0 * se);
        println!("simulated, {}: mean gain ${:.4} +/- {:.4} (exact {:.4})", names[i], m, se, exact_mean[i]);
    }
    for (i, exact) in [(0usize, var_half), (1, var_wdw * (1.0 - 1.0 / steps as f64))] {
        let (m, se) = mean_se(acc[i][1], acc[i][2], m_paths as f64);
        assert!((m - exact).abs() < 4.0 * se);
        println!("simulated, {}: mean square gain {:.2} +/- {:.2} (exact on this grid {:.2})", names[i], m, se, exact);
    }
    println!("left sum minus (W_T^2 - T)/2, in dollars, 2000 paths per step size");
    for n in [10usize, 100, 1000] {
        let (mut s, mut s2) = (0.0f64, 0.0f64);
        let sdn = (T / n as f64).sqrt();
        for _ in 0..2000 {
            let (mut w, mut left) = (0.0f64, 0.0f64);
            for _ in 0..n { let dw = sdn * rng.normal(); left += w * dw; w += dw }
            let e = SIGMA * (left - (w * w - T) / 2.0); s += e * e; s2 += (e * e) * (e * e);
        }
        let (m, se) = mean_se(s, s2, 2000.0);
        let exact = SIGMA * SIGMA * T * T / (2.0 * n as f64);
        assert!((m - exact).abs() < 4.0 * se);
        println!("steps, {}, rms error ${:.2}, formula 20 T / sqrt(2n) = ${:.2}, mean square {:.4} +/- {:.4}", n, m.sqrt(), exact.sqrt(), m, se);
    }
    let n = 10000usize;                                 // one path, 10000 steps, for variation and the chart
    let sdn = (T / n as f64).sqrt();
    let mut path = vec![0.0f64];
    for k in 0..n { let next = path[k] + sdn * rng.normal(); path.push(next) }
    for m in [10usize, 100, 1000, 10000] {
        let (mut qv, mut tv) = (0.0f64, 0.0f64);
        let j = n / m;
        for k in 0..m { let d = path[(k + 1) * j] - path[k * j]; qv += d * d; tv += d.abs() }
        let mean_tv = (2.0 * m as f64 * T / PI).sqrt();
        assert!((qv - T).abs() < 4.0 * (2.0 / m as f64).sqrt() * T);
        assert!((tv - mean_tv).abs() < 4.0 * (T * (1.0 - 2.0 / PI)).sqrt());
        println!("one path, {} steps: quadratic variation {:.4} (limit {:.4}), total variation {:.4} (mean sqrt(2n/pi) = {:.4})", m, qv, T, tv, mean_tv);
    }
    let (mut ito, mut form, mut naive, mut left) = (vec![0.0f64], vec![0.0f64], vec![0.0f64], 0.0f64);
    for k in 0..n {
        left += path[k] * (path[k + 1] - path[k]);
        if (k + 1) % 500 == 0 {
            let t = (k + 1) as f64 * T / n as f64;
            ito.push(SIGMA * left); form.push(SIGMA * (path[k + 1] * path[k + 1] - t) / 2.0);
            naive.push(SIGMA * path[k + 1] * path[k + 1] / 2.0);
        }
    }
    assert!((ito[20] - form[20]).abs() < 4.0 * SIGMA * T / (2.0 * n as f64).sqrt());
    let show = |v: &Vec<f64>| v.iter().map(|x| format!("{:.2}", x)).collect::<Vec<_>>().join(", ");
    println!("chart, t = 0, 0.05, ..., 1 year; W_T = {:.4}, price at year end ${:.2}", path[n], 100.0 + SIGMA * path[n]);
    println!("chart, Ito sum ($): {}", show(&ito));
    println!("chart, 10 (W_t^2 - t) ($): {}", show(&form));
    println!("chart, ordinary 10 W_t^2 ($): {}", show(&naive));
    println!("ALL CHECKS PASS");
}
