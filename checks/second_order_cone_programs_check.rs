// Second-order cone programs -- the same check as the Python, in Rust.  No crates.
// A fund holds five assets against a benchmark.  It chooses weights w to make the
// expected return largest, fully invested and long-only, with tracking error
// ||A (w - wb)|| at most DELTA = 2% a year: one second-order cone constraint.
// Road 1 is a log-barrier Newton method, road 2 the KKT closed form, road 3 a dual
// certificate whose bound meets the return.  Then the mistakes, and the chart.
const N: usize = 5;
const DELTA: f64 = 0.02;
const NAMES: [&str; 5] = ["UK", "US", "EM", "gilts", "corp"];
const MU: [f64; 5] = [0.060, 0.070, 0.085, 0.040, 0.048];   // expected return a year
const WB: [f64; 5] = [0.25, 0.30, 0.10, 0.20, 0.15];        // benchmark weights

fn add(xs: impl Iterator<Item = f64>) -> f64 {               // plain left-to-right sum
    let mut s = 0.0;
    for v in xs { s += v }
    s
}
fn dot(x: &[f64], y: &[f64]) -> f64 { add(x.iter().zip(y).map(|(a, b)| a * b)) }
fn mat_vec(m: &[Vec<f64>], x: &[f64]) -> Vec<f64> { m.iter().map(|r| dot(r, x)).collect() }
fn sub(x: &[f64], y: &[f64]) -> Vec<f64> { x.iter().zip(y).map(|(a, b)| a - b).collect() }
fn min(x: &[f64]) -> f64 { x.iter().fold(f64::INFINITY, |a, &b| a.min(b)) }
fn full(x: &[f64]) -> Vec<f64> { let mut w = x.to_vec(); w.push(1.0 - add(x.iter().copied())); w }

fn solve(m: &[Vec<f64>], b: &[f64]) -> Vec<f64> {           // Gaussian elimination, partial pivoting
    let n = b.len();
    let mut r: Vec<Vec<f64>> = (0..n).map(|i| { let mut row = m[i].clone(); row.push(b[i]); row }).collect();
    for c in 0..n {
        let mut p = c;
        for k in c + 1..n { if r[k][c].abs() > r[p][c].abs() { p = k } }
        r.swap(c, p);
        for k in c + 1..n {
            let f = r[k][c] / r[c][c];
            let pivot = r[c].clone();
            r[k] = r[k].iter().zip(&pivot).map(|(a, b)| a - f * b).collect();
        }
    }
    let mut x = vec![0.0; n];
    for i in (0..n).rev() {
        x[i] = (r[i][n] - add((i + 1..n).map(|j| r[i][j] * x[j]))) / r[i][i];
    }
    x
}

struct P { a: Vec<Vec<f64>>, sig: Vec<Vec<f64>> }

impl P {
    fn te2(&self, w: &[f64]) -> f64 { let v = mat_vec(&self.a, &sub(w, &WB)); dot(&v, &v) }
    fn te(&self, w: &[f64]) -> f64 { self.te2(w).sqrt() }
    fn phi(&self, x: &[f64], t: f64, delta: f64) -> f64 {     // barrier cost; x = first four weights
        let w = full(x);
        let slack = delta * delta - self.te2(&w);
        if min(&w) <= 0.0 || slack <= 0.0 { return f64::INFINITY }
        -t * dot(&MU, &w) - add(w.iter().map(|v| v.ln())) - slack.ln()
    }
    fn barrier(&self, delta: f64) -> (Vec<f64>, usize, f64) { // road 1: long-only, from the benchmark
        let (mut x, mut t, mut steps) = (WB[..4].to_vec(), 1.0_f64, 0usize);
        loop {
            for _ in 0..100 {                                // Newton steps at this t, capped
                let w = full(&x);
                let sd = mat_vec(&self.sig, &sub(&w, &WB));
                let sl = delta * delta - self.te2(&w);
                let gw: Vec<f64> = (0..N).map(|i| -t * MU[i] - 1.0 / w[i] + 2.0 * sd[i] / sl).collect();
                let hw: Vec<Vec<f64>> = (0..N).map(|i| (0..N).map(|j|
                    (if i == j { 1.0 / (w[i] * w[i]) } else { 0.0 }) + 2.0 * self.sig[i][j] / sl
                    + 4.0 * sd[i] * sd[j] / (sl * sl)).collect()).collect();
                let g: Vec<f64> = (0..4).map(|i| gw[i] - gw[4]).collect();
                let h: Vec<Vec<f64>> = (0..4).map(|i| (0..4).map(|j|
                    hw[i][j] - hw[i][4] - hw[4][j] + hw[4][4]).collect()).collect();
                let dx = solve(&h, &g.iter().map(|v| -v).collect::<Vec<f64>>());
                if -dot(&g, &dx) / 2.0 < 1e-9 { break }
                let (mut s, f0) = (1.0_f64, self.phi(&x, t, delta));
                let step = |s: f64| -> Vec<f64> { x.iter().zip(&dx).map(|(a, b)| a + s * b).collect() };
                while self.phi(&step(s), t, delta) > f0 + 0.25 * s * dot(&g, &dx) && s > 1e-12 { s *= 0.5 }
                x = step(s);
                steps += 1;
            }
            if 6.0 / t < 1e-10 { return (full(&x), steps, 6.0 / t) }
            t *= 10.0;
        }
    }
    fn closed_form(&self, delta: f64) -> (Vec<f64>, f64, f64) { // road 2: KKT, floor ignored
        let (a, o) = (solve(&self.sig, &MU), solve(&self.sig, &[1.0; N]));
        let nu = add(a.iter().copied()) / add(o.iter().copied());
        let g: Vec<f64> = a.iter().zip(&o).map(|(p, q)| p - nu * q).collect();
        let ir = dot(&g, &mat_vec(&self.sig, &g)).sqrt();
        (WB.iter().zip(&g).map(|(b, gi)| b + delta * gi / ir).collect(), nu, ir)
    }
}

fn pct(w: &[f64]) -> String {
    NAMES.iter().zip(w).map(|(n, v)| format!("{} {:.2}", n, 100.0 * v)).collect::<Vec<_>>().join("  ")
}

fn main() {
    let mut a = vec![vec![0.14, 0.15, 0.18, -0.01, 0.04], vec![0.00, 0.00, 0.02, 0.06, 0.05]];
    for (i, s) in [0.06, 0.05, 0.10, 0.02, 0.03].iter().enumerate() {
        a.push((0..N).map(|j| if j == i { *s } else { 0.0 }).collect());
    }
    let sig: Vec<Vec<f64>> = (0..N).map(|i| (0..N).map(|j| add(a.iter().map(|r| r[i] * r[j]))).collect()).collect();
    let p = P { a: a.clone(), sig };
    let wb_ret = dot(&MU, &WB);
    let (w1, steps, gap) = p.barrier(DELTA);
    let (w2, nu, ir) = p.closed_form(DELTA);
    let d2 = sub(&w2, &WB);
    let u: Vec<f64> = mat_vec(&a, &d2).iter().map(|v| ir / DELTA * v).collect();   // road 3, lambda = 0
    let z = dot(&u, &u).sqrt();
    let resid = (0..N).map(|i| (add((0..a.len()).map(|k| a[k][i] * u[k])) + nu - MU[i]).abs()).fold(0.0, f64::max);
    let bound = nu + DELTA * z + dot(&u, &mat_vec(&a, &WB));
    let yn = |c: bool| if c { "yes" } else { "no" };
    println!("risk model rows {}, so the cone has dimension {}", a.len(), a.len() + 1);
    println!("benchmark return             {:.4}%", 100.0 * wb_ret);
    println!("road 1 barrier weights %     {}", pct(&w1));
    println!("road 1 return {:.4}%  tracking error {:.4}%  Newton steps {}  gap bound {:.0e}",
             100.0 * dot(&MU, &w1), 100.0 * p.te(&w1), steps, gap);
    println!("road 2 closed-form weights % {}", pct(&w2));
    println!("road 2 nu {:.6}  best ratio sqrt(g'Sg) {:.6}  return {:.4}%", nu, ir, 100.0 * dot(&MU, &w2));
    println!("road 2 excess = delta x ratio {:.4}%  direction g = {}", 100.0 * DELTA * ir,
             d2.iter().map(|v| format!("{:.6}", v * ir / DELTA)).collect::<Vec<_>>().join(" "));
    println!("road 3 dual z = |u| {:.6}  u = {}", z, u.iter().map(|v| format!("{:.6}", v)).collect::<Vec<_>>().join(" "));
    println!("road 3 stationarity residual below 1e-12: {}", yn(resid < 1e-12));
    println!("road 3 dual bound {:.4}%  gap to the return below 1e-12: {}", 100.0 * bound,
             yn((bound - dot(&MU, &w2)).abs() < 1e-12));
    println!("tracking error by 7-row length {:.4}%, by sqrt of variance {:.4}%",
             100.0 * p.te(&w2), 100.0 * dot(&d2, &mat_vec(&p.sig, &d2)).sqrt());
    println!("turnover from benchmark, sum |w - wb| {:.2}%", 100.0 * add(d2.iter().map(|v| v.abs())));
    let (wv, _, _) = p.barrier(DELTA.sqrt());                 // mistake: variance capped at 0.02
    println!("wrong: variance cap 0.02    weights % {}", pct(&wv));
    println!("wrong: variance cap 0.02    excess {:.4}%  real tracking error {:.4}%",
             100.0 * (dot(&MU, &wv) - wb_ret), 100.0 * p.te(&wv));
    let m: Vec<f64> = MU.iter().map(|v| v - add(MU.iter().copied()) / N as f64).collect();
    let wl: Vec<f64> = WB.iter().zip(&m).map(|(b, v)| b + DELTA * v / dot(&m, &m).sqrt()).collect();
    println!("wrong: |w - wb| <= 2%       excess {:.4}%  real tracking error {:.4}%",
             100.0 * (dot(&MU, &wl) - wb_ret), 100.0 * p.te(&wl));
    println!("wrong: |w - wb| scaled up to 2% tracking error: excess {:.4}%",
             100.0 * (dot(&MU, &wl) - wb_ret) * DELTA / p.te(&wl));
    let (w5, _, _) = p.closed_form(0.05);
    println!("wrong: closed form at 5%    weights % {}", pct(&w5));
    for x2 in [10.0_f64, 100.0, 1000.0] {                     // min x1 with x1 * x2 >= 1: never reached
        let x1 = 1.0 / x2;
        println!("hyperbola x2 {:6.0}  x1 {:.4}  |(x1 - x2, 2)| {:.4}  x1 + x2 {:.4}",
                 x2, x1, ((x1 - x2) * (x1 - x2) + 4.0).sqrt(), x1 + x2);
    }
    println!("hyperbola dual point (0.5, 0.5, 0): on the rim, |(0.5, 0)| = 0.5, dual value 0");
    let deltas: Vec<f64> = (1..9).map(|k| 0.01 * k as f64).collect();
    let long_only: Vec<f64> = deltas.iter().map(|&d| 100.0 * (dot(&MU, &p.barrier(d).0) - wb_ret)).collect();
    let row = |v: Vec<String>| v.join(" ");
    println!("chart, limit %   {}", row(deltas.iter().map(|d| format!("{:5.1}", 100.0 * d)).collect()));
    println!("chart, long-only {}", row(long_only.iter().map(|v| format!("{:5.3}", v)).collect()));
    println!("chart, shorting  {}", row(deltas.iter().map(|d| format!("{:5.3}", 100.0 * d * ir)).collect()));
    assert!((dot(&MU, &w1) - dot(&MU, &w2)).abs() < 1e-8, "barrier method meets the closed form");
    assert!(w1.iter().zip(&w2).all(|(a, b)| (a - b).abs() < 1e-6) && min(&w2) > 0.0, "same weights");
    assert!(resid < 1e-12 && (bound - dot(&MU, &w2)).abs() < 1e-12, "dual certificate meets the return");
    assert!((p.te(&w2) - DELTA).abs() < 1e-12 && (z - ir).abs() < 1e-12, "cone tight, |u| is the ratio");
    assert!(p.te(&wv) > 3.0 * DELTA && p.te(&wl) < DELTA / 2.0 && min(&w5) < 0.0, "each mistake breaks a limit");
    assert!(long_only[7] < 100.0 * 0.08 * ir - 1e-4 && (long_only[0] - ir).abs() < 1e-6, "chart bends");
    println!("ALL CHECKS PASS");
}
