// Dual spaces and Lp duality -- the same check as dual_spaces_and_lp_duality_check.py.
// Standard library only, no crates. A cafe's day of hourly sales, scored by a
// weighted rule; a rule's norm is found by the dual-norm formula and, separately,
// by brute force over the unit ball's corners or the extremal list.
// Compile: rustc --edition 2021 -O dual_spaces_and_lp_duality_check.rs -o /tmp/dual_check
const INF: f64 = f64::INFINITY;
const X: [f64; 8] = [120.0, 340.0, 260.0, 410.0, 380.0, 150.0, 90.0, 250.0]; // pounds, 9:00 to 17:00
const W: [f64; 8] = [1.5, 1.0, 1.0, 0.5, 0.5, 1.0, 1.5, 1.0]; // head office's weight per hour

fn size(v: &[f64], p: f64) -> f64 {
    if p == INF {
        return v.iter().fold(0.0, |m, a| f64::max(m, a.abs()));
    }
    v.iter().map(|a| a.abs().powf(p)).sum::<f64>().powf(1.0 / p)
}
fn rule(w: &[f64], v: &[f64]) -> f64 {
    w.iter().zip(v).map(|(a, b)| a * b).sum()
}
fn conj(p: f64) -> f64 {
    if p == 1.0 { INF } else if p == INF { 1.0 } else { p / (p - 1.0) }
}
fn name(p: f64) -> String {
    if p == INF { "inf".to_string() } else { format!("{}", p) }
}
fn signs(n: usize) -> Vec<Vec<f64>> {
    (0..1usize << n).map(|k| (0..n).map(|i| if (k >> i) & 1 == 1 { 1.0 } else { -1.0 }).collect()).collect()
}
fn apply(a: &[Vec<f64>], v: &[f64]) -> Vec<f64> {
    a.iter().map(|row| rule(row, v)).collect()
}
fn join(v: &[f64]) -> String {
    v.iter().map(|a| format!("{}", a)).collect::<Vec<_>>().join(" ")
}
struct SplitMix(u64); // SplitMix64, seed 20261115, uniform on [-1, 1)
impl SplitMix {
    fn unif(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^= z >> 31;
        (z >> 11) as f64 / 9007199254740992.0 * 2.0 - 1.0
    }
}

fn main() {
    let mut rng = SplitMix(20261115);
    let score = rule(&W, &X);
    println!("day: score {:.2}  total {:.2}  busiest {:.2}  root-sum-square {:.6}", score, size(&X, 1.0), size(&X, INF), size(&X, 2.0));
    println!("hourly score w_n x_n {}", join(&W.iter().zip(&X).map(|(a, b)| a * b).collect::<Vec<_>>()));
    println!("size rule p | rule norm ||w||_q | brute force | Holder ceiling ||w||_q ||x||_p");
    let mut norms = vec![];
    for p in [1.0, 2.0, 3.0, INF] {
        let q = conj(p);
        let formula = size(&W, q);
        let brute = if p == 1.0 {
            (0..8).map(|i| rule(&W, &(0..8).map(|j| if j == i { 1.0 } else { 0.0 }).collect::<Vec<_>>()).abs()).fold(0.0, f64::max)
        } else if p == INF {
            signs(8).iter().map(|s| rule(&W, s)).fold(f64::MIN, f64::max)
        } else {
            let ext: Vec<f64> = W.iter().map(|a| a.abs().powf(q - 1.0)).collect();
            let mut best = 0.0f64;
            for _ in 0..20000 {
                let v: Vec<f64> = (0..8).map(|_| rng.unif()).collect();
                best = best.max(rule(&W, &v).abs() / size(&v, p));
            }
            println!("  p={}: best of 20000 random lists {:.6}, never above {:.6}", name(p), best, formula);
            assert!(best <= formula + 1e-12 && best > 0.9 * formula);
            rule(&W, &ext) / size(&ext, p)
        };
        assert!((brute - formula).abs() < 1e-9 && score <= formula * size(&X, p) + 1e-9);
        norms.push(formula);
        println!("p={:>3} q={:>3} | {:.6} | {:.6} | {:.2}", name(p), name(q), formula, brute, formula * size(&X, p));
    }
    assert!((norms[1] - 3.0).abs() < 1e-12 && (norms[0] - 1.5).abs() < 1e-12 && (norms[3] - 8.0).abs() < 1e-12);

    // transpose: S = running totals; psi reads the running total at noon and at close
    let s: Vec<Vec<f64>> = (0..8).map(|i| (0..8).map(|j| if j <= i { 1.0 } else { 0.0 }).collect()).collect();
    let st: Vec<Vec<f64>> = (0..8).map(|i| (0..8).map(|j| s[j][i]).collect()).collect();
    let psi = [0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0];
    let (sx, pulled) = (apply(&s, &X), apply(&st, &psi));
    println!("running totals Sx {}", join(&sx));
    println!("pulled-back weights S^t psi {}", join(&pulled));
    println!("psi(Sx) {}  (S^t psi)(x) {}", rule(&psi, &sx), rule(&pulled, &X));
    assert!(rule(&psi, &sx) == 2720.0 && rule(&pulled, &X) == 2720.0);
    let norm_s = (0..8).map(|j| size(&(0..8).map(|i| s[i][j]).collect::<Vec<_>>(), 1.0)).fold(0.0, f64::max);
    let norm_st = signs(8).iter().map(|v| size(&apply(&st, v), INF)).fold(0.0, f64::max);
    println!("||S|| on l1 by columns {}  ||S^t|| on sup by 256 corners {}", norm_s, norm_st);
    assert!(norm_s == 8.0 && norm_st == 8.0);

    // annihilator: reshuffles (total 0) are killed exactly by multiples of the total
    let r = [0.0, 0.0, 0.0, -50.0, 0.0, 0.0, 50.0, 0.0]; // move 50 pounds from 12:00 to 15:00
    let d: Vec<Vec<f64>> = (0..8).map(|i| (0..8).map(|j| if i == j { 1.0 } else { 0.0 } - 1.0 / 8.0).collect()).collect(); // D^t = D
    let ones8 = [1.0; 8];
    println!("reshuffle: head office rule {}  total-takings rule {}", rule(&W, &r), rule(&ones8, &r));
    println!("D^t on the all-ones rule, largest entry {:.6}", size(&apply(&d, &ones8), INF));
    assert!(rule(&W, &r) == 50.0 && rule(&ones8, &r) == 0.0 && size(&apply(&d, &W), INF) > 0.4);
    assert!(size(&apply(&d, &ones8), INF) < 1e-12); // ker D^t = (ran D)^perp holds the total

    // infinite dimensions: weights 1/n on an endless list of hours, cut to N
    let gamma = 0.5772156649015329;
    let pi = std::f64::consts::PI;
    println!("weights 1/n; pi/sqrt6 = {:.6}", pi / 6f64.sqrt());
    println!("N | l2 rule norm | gap to pi/sqrt6 | sup-size rule norm H_N | ln N + gamma | l2 tail of 1/n");
    for k in 1..5 {
        let n = 10usize.pow(k);
        let nf = n as f64;
        let s1: f64 = (1..=n).map(|m| 1.0 / m as f64).sum();
        let s2: f64 = (1..=n).map(|m| 1.0 / (m * m) as f64).sum();
        let gap = pi / 6f64.sqrt() - s2.sqrt();
        let tail = (pi.powf(2.0) / 6.0 - s2).sqrt();
        println!("{:>5} | {:.6} | {:.6} | {:.6} | {:.6} | {:.6}", n, s2.sqrt(), gap, s1, nf.ln() + gamma, tail);
        assert!(0.0 < gap && gap < 0.5 / nf && (s1 - nf.ln() - gamma - 1.0 / (2.0 * nf)).abs() < 1.0 / (nf * nf));
        assert!((tail * nf.sqrt() - 1.0).abs() < 1.0 / nf);
    }
    let lim = |v: &[f64]| v[v.len() - 1]; // the limit reading, on lists that are constant after hour N
    let n = 1000;
    let weights: Vec<f64> = (0..n).map(|i| lim(&(0..=n).map(|j| if j == i { 1.0 } else { 0.0 }).collect::<Vec<_>>())).collect();
    let ones = vec![1.0; n + 1];
    let cut_gap = size(&ones.iter().enumerate().map(|(i, a)| a - if i < n { 1.0 } else { 0.0 }).collect::<Vec<_>>(), INF);
    println!("limit rule: weights lim(e_n) all {}, weighted sum on all-ones {}, limit {}; sup gap from all-ones to its cut {}",
        weights.iter().fold(0.0, |m: f64, a| m.max(*a)), rule(&weights, &ones), lim(&ones), cut_gap);
    assert!(rule(&weights, &ones) == 0.0 && lim(&ones) == 1.0 && cut_gap == 1.0);

    // C[0, 8]: the noon reading f(3) against any weight function, here the step g = w
    let g = |t: f64| W[std::cmp::min(t as usize, 7)];
    let mut alpha = vec![0.0f64]; // alpha(t) = integral of g from 0 to t, on a grid of 800
    for k in 0..800 {
        let last = alpha[alpha.len() - 1];
        alpha.push(last + g((k as f64 + 0.5) / 100.0) / 100.0);
    }
    let alpha_tv: f64 = (0..800).map(|k| (alpha[k + 1] - alpha[k]).abs()).sum();
    println!("weight rule on C: value on f = 1 is {}, total variation of alpha {:.6}", rule(&W, &ones8), alpha_tv);
    assert!((alpha_tv - norms[3]).abs() < 1e-9);
    for n in [10, 100, 1000] {
        let (h, m) = (1.0 / n as f64, 2000);
        let tent = |t: f64| f64::max(0.0, 1.0 - (t - 3.0).abs() / h);
        let integral = (0..m).map(|i| {
            let t = 3.0 - h + (i as f64 + 0.5) * 2.0 * h / m as f64;
            g(t) * tent(t)
        }).sum::<f64>() * 2.0 * h / m as f64;
        println!("tent half-width 1/{}: noon reading {}, weight rule {:.6}", n, tent(3.0), integral);
        assert!((integral - 0.75 * h).abs() < 1e-9);
    }
    // what breaks
    println!("wrong: same exponent p on the weights, busiest-hour ceiling {:.2} < score {:.2}", size(&W, INF) * size(&X, INF), score);
    println!("wrong: pull back with S, not S^t: {} instead of 2720", rule(&apply(&s, &psi), &X));
    let mut w2 = W;
    w2[6] = 3.0;
    println!("try: weight 3 at 15:00: score {}, rule norm on total takings {}", rule(&w2, &X), size(&w2, INF));
    let psi2 = [0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 1.0];
    println!("try: read the running total at 14:00 and close: weights {}, score {}", join(&apply(&st, &psi2)), rule(&psi2, &apply(&s, &X)));
    let s3: f64 = (1..=10000usize).map(|m| 1.0 / (m * m) as f64).sum();
    println!("try: weights 1/n^2, sup-size rule norm at N = 10000 {:.6}, limit pi^2/6 {:.6}", s3, pi.powf(2.0) / 6.0);
    println!("ALL CHECKS PASS");
}
