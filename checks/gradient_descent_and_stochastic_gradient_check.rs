// Gradient descent and stochastic gradient -- the check behind the card.  Rust std
// only.  Synthetic shop: 20,000 orders, 12 numbers each, made by the rule below
// from SplitMix64 seed 2026.  Fit 12 weights and a bias by squared error.
const N: usize = 20000; const D: usize = 12; const P: usize = 13;
type Mat = Vec<Vec<f64>>;
struct Rng(u64);
impl Rng {
    fn rnd(&mut self) -> f64 { // SplitMix64, a uniform number in [0, 1)
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 * 2f64.powi(-53)
    }
}
struct Fit { yy: f64, r0: f64 }
fn mul(m: &Mat, v: &[f64]) -> Vec<f64> {
    m.iter().map(|row| { let mut s = 0.0; for k in 0..P { s += row[k] * v[k]; } s }).collect()
}
fn risk(f: &Fit, w: &[f64], m: &Mat, cc: &[f64]) -> f64 { // mean squared error, pounds squared
    let mw = mul(m, w);
    let mut s = f.yy;
    for j in 0..P { s += 0.5 * w[j] * mw[j] - cc[j] * w[j]; }
    s
}
fn grad(w: &[f64], m: &Mat, cc: &[f64]) -> Vec<f64> { mul(m, w).iter().zip(cc).map(|(g, c)| g - c).collect() }
fn excess(f: &Fit, w: &[f64], m: &Mat, cc: &[f64]) -> f64 { risk(f, w, m, cc) - f.r0 }
fn eig(m: &Mat, shift: f64) -> f64 { // power iteration on M - shift I
    let mut v: Vec<f64> = (0..P).map(|j| 1.0 + 0.01 * j as f64).collect();
    for _ in 0..100000 {
        let u: Vec<f64> = mul(m, &v).iter().zip(&v).map(|(a, b)| a - shift * b).collect();
        let top = u.iter().fold(0.0f64, |t, a| t.max(a.abs()));
        v = u.iter().map(|a| a / top).collect();
    }
    let u: Vec<f64> = mul(m, &v).iter().zip(&v).map(|(a, b)| a - shift * b).collect();
    let (mut num, mut den) = (0.0, 0.0);
    for (a, b) in u.iter().zip(&v) { num += a * b; den += b * b; }
    num / den
}
fn below(m: &Mat, mu: f64) -> usize { // road 3b: curvatures below mu = negative pivots of M - mu I
    let mut g: Mat = (0..P).map(|i| (0..P).map(|j| m[i][j] - if i == j { mu } else { 0.0 }).collect()).collect();
    let mut neg = 0;
    for j in 0..P {
        if g[j][j] < 0.0 { neg += 1; }
        for r in j + 1..P { let f = g[r][j] / g[j][j]; for k in j..P { g[r][k] -= f * g[j][k]; } }
    }
    neg
}
fn descend(f: &Fit, eta: f64, beta: f64, steps: usize, m: &Mat, cc: &[f64], sign: f64) -> (Vec<f64>, Vec<f64>) {
    let (mut w, mut v) = (vec![0.0; P], vec![0.0; P]); let mut trace = vec![excess(f, &w, m, cc)];
    for _ in 0..steps {
        let g = grad(&w, m, cc);
        v = (0..P).map(|j| beta * v[j] - sign * eta * g[j]).collect();
        w = (0..P).map(|j| w[j] + v[j]).collect();
        trace.push(excess(f, &w, m, cc));
    }
    (w, trace)
}
fn sci(x: f64) -> String { // Python's 1.234e+05 style
    let s = format!("{:.3e}", x); let (m, e) = s.split_once('e').unwrap(); let e: i32 = e.parse().unwrap();
    format!("{}e{}{:02}", m, if e < 0 { '-' } else { '+' }, e.abs())
}
fn main() {
    let (true_w, true_b) = ([3.0, -2.0, 1.5, 0.0, 4.0, -1.0, 2.0, 0.5, -3.0, 1.0, 2.5, -0.5], 40.0);
    let mut rng = Rng(2026);
    let (mut xs, mut ys): (Mat, Vec<f64>) = (vec![], vec![]);
    for _ in 0..N { // each order: a shared size z plus its own wobble
        let z = 2.0 * rng.rnd() - 1.0;
        let mut x: Vec<f64> = (0..D).map(|_| z + 0.3 * (2.0 * rng.rnd() - 1.0)).collect();
        let mut y = true_b;
        for j in 0..D { y += true_w[j] * x[j]; }
        x.push(1.0);
        xs.push(x);
        ys.push(y + 10.0 * (rng.rnd() + rng.rnd() + rng.rnd() - 1.5)); // noise, sd 5 pounds
    }
    let nf = N as f64;
    let (mut a, mut c, mut yy) = (vec![vec![0.0; P]; P], vec![0.0; P], 0.0);
    for (x, &y) in xs.iter().zip(&ys) { // summed products, added once: H = A, grad = A w - c
        yy += y * y / nf;
        for j in 0..P {
            c[j] += 2.0 * x[j] * y / nf;
            for k in 0..P { a[j][k] += 2.0 * x[j] * x[k] / nf; }
        }
    }
    let mut g: Mat = a.iter().zip(&c).map(|(r, &cj)| { let mut r = r.clone(); r.push(cj); r }).collect();
    for j in 0..P { // road 1: exact bottom, by elimination
        for r in j + 1..P {
            let f = g[r][j] / g[j][j];
            for k in j..P + 1 { g[r][k] -= f * g[j][k]; }
        }
    }
    let mut best = vec![0.0; P];
    for j in (0..P).rev() {
        let mut s = g[j][P];
        for k in j + 1..P { s -= g[j][k] * best[k]; }
        best[j] = s / g[j][j];
    }
    let mut fit = Fit { yy, r0: 0.0 }; fit.r0 = risk(&fit, &best, &a, &c);
    let r0 = fit.r0;
    let worst = |w: &[f64]| (0..P).fold(0.0f64, |t, j| t.max((w[j] - best[j]).abs()));
    println!("orders {}, numbers per order {}, mean order value {:.4} pounds", N, D, c[P - 1] / 2.0);
    println!("best weights {}; bias {:.2}", best[..D].iter().map(|v| format!("{:.2}", v)).collect::<Vec<_>>().join(" "), best[D]);
    println!("lowest risk {:.4} pounds squared, typical miss {:.2} pounds", r0, r0.sqrt());
    let mut rowg = vec![0.0; P]; // road 2: the gradient at zero, order by order
    for (x, &y) in xs.iter().zip(&ys) { for j in 0..P { rowg[j] += 2.0 * (0.0 - y) * x[j] / nf; } }
    let (h, unit) = (1e-3, |j: usize, s: f64| -> Vec<f64> { (0..P).map(|k| if k == j { s } else { 0.0 }).collect() });
    let rowrisk = |w: &[f64]| xs.iter().zip(&ys).map(|(x, y)| (x.iter().zip(w).map(|(a, b)| a * b).sum::<f64>() - y).powi(2)).sum::<f64>() / nf;
    let fd: Vec<f64> = (0..P).map(|j| (rowrisk(&unit(j, h)) - rowrisk(&unit(j, -h))) / (2.0 * h)).collect();
    let g0 = grad(&vec![0.0; P], &a, &c);
    println!("gradient at zero: bias {:.4}, weight 1 {:.4}; row sum {:.4}, {:.4}; difference quotient {:.4}, {:.4}", g0[D], g0[0], rowg[D], rowg[0], fd[D], fd[0]);
    println!("first plain step, size 0.2: bias {:.4}, weight 1 {:.4}", -0.2 * g0[D], -0.2 * g0[0]);
    let lmax = eig(&a, 0.0); let lmin = lmax + eig(&a, lmax);
    println!("steepest curvature {:.4}, gentlest {:.5}, ratio {:.1}; step limit 2/steepest {:.4}", lmax, lmin, lmax / lmin, 2.0 / lmax);
    let cnt: Vec<usize> = [lmin - 1e-4, lmin + 1e-4, 0.07, lmax - 1e-4, lmax + 1e-4].iter().map(|&m| below(&a, m)).collect();
    println!("curvatures counted below gentlest -/+ 0.0001: {}, {}; below 0.07: {}; below steepest -/+ 0.0001: {}, {}", cnt[0], cnt[1], cnt[2], cnt[3], cnt[4]);
    let run = |eta: f64, beta: f64, steps: usize| descend(&fit, eta, beta, steps, &a, &c, 1.0);
    let sizes = [("0.05", 0.05), ("0.1", 0.1), ("0.2", 0.2), ("0.24", 0.24), ("0.25", 0.25)];
    println!("step size, excess risk after 50 passes: {}", sizes.iter().map(|(s, e)| format!("{} -> {:.4}", s, run(*e, 0.0, 50).1[50])).collect::<Vec<_>>().join(", "));
    let ((wg, tg), (wm, tm)) = (run(0.2, 0.0, 50), run(0.2, 0.8, 50));
    let slow = (1.0 - 0.2 * lmin).powf(2.0);
    println!("plain, late shrink per pass {:.4}; predicted (1 - 0.2 x gentlest)^2 = {:.4}; passes to cut slow error tenfold {:.0}", tg[50] / tg[49], slow, 10f64.ln() / -(1.0 - 0.2 * lmin).ln());
    println!("slow factor per pass {:.5}, slow error left after 50 passes {:.3}", 1.0 - 0.2 * lmin, (1.0 - 0.2 * lmin).powf(50.0));
    println!("multiply-adds per pass {}; mini-batch steps per pass {}, in 50 passes {}", 2 * N * P, N / 100, 50 * N / 100);
    let sgd = |eta: f64, bsz: usize, passes: usize, seed: u64| { // mini-batches, reshuffled every pass
        let (mut rng, mut w, mut idx) = (Rng(seed), vec![0.0; P], (0..N).collect::<Vec<usize>>());
        let mut trace = vec![excess(&fit, &w, &a, &c)];
        for _ in 0..passes {
            for i in (1..N).rev() { let j = (rng.rnd() * (i + 1) as f64) as usize; idx.swap(i, j); }
            for s in (0..N).step_by(bsz) {
                let mut gr = vec![0.0; P];
                for &i in &idx[s..s + bsz] {
                    let (x, mut e) = (&xs[i], -ys[i]);
                    for j in 0..P { e += w[j] * x[j]; }
                    for j in 0..P { gr[j] += 2.0 * e * x[j] / bsz as f64; }
                }
                for j in 0..P { w[j] -= eta * gr[j]; }
            }
            trace.push(excess(&fit, &w, &a, &c));
        }
        (w, trace)
    };
    let ((ws, ts), (_wq, tq)) = (sgd(0.05, 100, 50, 7), sgd(0.0125, 100, 50, 7));
    let mut floor = [0.0, 0.0]; for (k, t) in [&ts, &tq].iter().enumerate() { for p in 31..51 { floor[k] += t[p] / 20.0; } }
    println!("mini-batch jitter floor, mean excess over passes 31-50: step 0.05 -> {:.4}, step 0.0125 -> {:.4}, ratio {:.2}", floor[0], floor[1], floor[0] / floor[1]);
    for (name, t) in [("plain, step 0.2   ", &tg), ("momentum 0.8      ", &tm), ("mini-batch of 100 ", &ts)] {
        println!("{} {}", name, [0, 1, 2, 5, 10, 20, 30, 40, 50].iter().map(|&p| format!("{:9.4}", t[p])).collect::<Vec<_>>().join(" "));
    }
    println!("typical miss after 50 plain passes {:.3} pounds, at the bottom {:.3}", (r0 + tg[50]).sqrt(), r0.sqrt());
    for (name, w, t) in [("plain", &wg, &tg), ("momentum", &wm, &tm), ("mini-batch", &ws, &ts)] {
        println!("after 50 passes, {}: excess {:.4}, worst weight off by {:.3} pounds", name, t[50], worst(w));
    }
    let chart = |t: &Vec<f64>| (0..51).step_by(5).map(|p| format!("{:.2}", t[p].ln() / 10f64.ln())).collect::<Vec<_>>().join(" ");
    println!("chart, log10 excess: {} | {} | {}", chart(&tg), chart(&tm), chart(&ts));
    let (mut np, mut cp) = (a.clone(), c.clone()); // what breaks: number 1 recorded 100 times too large
    for k in 0..P { np[0][k] *= 100.0; np[k][0] *= 100.0; } cp[0] *= 100.0;
    let lp = eig(&np, 0.0);
    println!("breaks: step 0.25 -> {:.1}; sum not mean, one step -> {}; uphill -> {}", run(0.25, 0.0, 50).1[50],
             sci(run(0.2 * nf, 0.0, 1).1[1]), sci(descend(&fit, 0.2, 0.0, 50, &a, &c, -1.0).1[50]));
    println!("breaks: number 1 x100: steepest {:.2}, {:.0} times; step 0.2, 3 passes -> {}; safe step {:.6} -> {:.4}", lp, lp / lmax, sci(descend(&fit, 0.2, 0.0, 3, &np, &cp, 1.0).1[3]),
             1.9 / lp, descend(&fit, 1.9 / lp, 0.0, 50, &np, &cp, 1.0).1[50]);
    let gap = (0..P).fold(0.0f64, |t, j| t.max((g0[j] - rowg[j]).abs() + (g0[j] - fd[j]).abs()));
    assert!(gap < 1e-6); // three gradients agree
    assert!(grad(&best, &a, &c).iter().all(|v| v.abs() < 1e-9) && (best[D] - true_b).abs() < 0.2); // flat bottom
    assert!(0.995 < (tg[50] / tg[49]) / slow && (tg[50] / tg[49]) / slow < 1.005); // rate meets prediction
    assert!(cnt[..2] == [0, 1] && cnt[3..] == [P - 1, P]); // curvatures, second road
    assert!(run(0.24, 0.0, 50).1[50] < 10.0 && 10.0 < run(0.25, 0.0, 50).1[50] && 0.24 < 2.0 / lmax && 2.0 / lmax < 0.25); // cliff at 2/steepest
    assert!(tm[50] < tg[50] / 10.0 && floor[0] < tg[50] / 2.0 && worst(&ws) < worst(&wg) / 5.0); // the two win
    assert!(2.0 < floor[0] / floor[1] && floor[0] / floor[1] < 16.0); // quarter step, smaller jitter
    println!("ALL CHECKS PASS");
}
