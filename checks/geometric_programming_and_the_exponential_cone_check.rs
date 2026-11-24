// Geometric programs and the exponential cone -- the same check as the Python, in Rust.  No crates.
// Box: largest volume h*w*d (dm, so litres) with wall 2h(w + d) <= 200 dm^2 and floor w*d <= 100 dm^2.
// In logs u = (log h, log w, log d) it is convex.  Road 1: log-barrier Newton in logs.  Road 2: the
// multipliers and the AM-GM ceiling.  Road 3: a grid of boxes.  Then log-concave tests, the
// exponential cone, and a growth-optimal (Kelly) mix of five assets, solved and certified the same way.
type Eval = (f64, Vec<f64>, Vec<Vec<f64>>);
const NAMES: [&str; 5] = ["UK", "US", "EM", "gilts", "corp"];
const P: [f64; 4] = [0.30, 0.40, 0.20, 0.10]; // boom, steady, slump, crash
const R: [[f64; 5]; 4] = [[1.20, 1.24, 1.36, 1.02, 1.05], [1.08, 1.09, 1.14, 1.05, 1.07],
    [0.94, 0.99, 0.85, 1.07, 1.06], [0.72, 0.75, 0.61, 1.15, 0.97]]; // wealth multiplier a year

fn add<I: IntoIterator<Item = f64>>(xs: I) -> f64 { let mut s = 0.0; for v in xs { s += v; } s }
fn dot(x: &[f64], y: &[f64]) -> f64 { add(x.iter().zip(y).map(|(a, b)| a * b)) }

fn solve(m: &[Vec<f64>], b: &[f64]) -> Vec<f64> { // Gaussian elimination, partial pivoting
    let n = b.len();
    let mut r: Vec<Vec<f64>> = (0..n).map(|i| { let mut row = m[i].clone(); row.push(b[i]); row }).collect();
    for c in 0..n {
        let mut p = c;
        for k in c..n { if r[k][c].abs() > r[p][c].abs() { p = k; } }
        r.swap(c, p);
        for k in c + 1..n {
            let f = r[k][c] / r[c][c];
            for j in 0..=n { r[k][j] -= f * r[c][j]; }
        }
    }
    let mut x = vec![0.0; n];
    for i in (0..n).rev() {
        x[i] = (r[i][n] - add((i + 1..n).map(|j| r[i][j] * x[j]))) / r[i][i];
    }
    x
}

fn barrier(f: &dyn Fn(&[f64], f64) -> Eval, x0: Vec<f64>, m: f64) -> (Vec<f64>, usize, f64) {
    let (mut x, mut t, mut steps) = (x0, 1.0, 0); // minimise t*cost + barrier, t = 1, 10, 100, ...
    loop {
        for _ in 0..100 {
            let (v, g, h) = f(&x, t);
            let dx = solve(&h, &g.iter().map(|a| -a).collect::<Vec<_>>());
            let dec = -dot(&g, &dx); // Newton decrement squared
            if dec / 2.0 < 1e-12 { break; }
            let mut s = 1.0;
            let step = |s: f64| x.iter().zip(&dx).map(|(a, b)| a + s * b).collect::<Vec<f64>>();
            while f(&step(s), t).0 > v - 0.25 * s * dec && s > 1e-12 { s *= 0.5; }
            x = step(s);
            steps += 1;
        }
        if m / t < 1e-10 { return (x, steps, m / t); } // m barrier terms: gap at most m / t
        t *= 10.0;
    }
}

fn box_f(wall: f64, floor: f64) -> impl Fn(&[f64], f64) -> Eval {
    move |u: &[f64], t: f64| {
        let (x, y, z) = (u[0], u[1], u[2]);
        let (e1, e2) = ((x + y).exp(), (x + z).exp());
        let (c1, c2) = ((e1 + e2).ln() - (wall / 2.0).ln(), y + z - floor.ln());
        if c1 >= 0.0 || c2 >= 0.0 { return (f64::INFINITY, vec![], vec![]); }
        let ab = e1 * e2 / ((e1 + e2) * (e1 + e2)); // Hessian of log-sum-exp: ab times (0, 1, -1)(0, 1, -1)'
        let (g1, g2, d1) = ([1.0, e1 / (e1 + e2), e2 / (e1 + e2)], [0.0, 1.0, 1.0], [0.0, 1.0, -1.0]);
        let g: Vec<f64> = (0..3).map(|i| -t + g1[i] / -c1 + g2[i] / -c2).collect();
        let h: Vec<Vec<f64>> = (0..3).map(|i| (0..3).map(|j| ab * d1[i] * d1[j] / -c1
            + g1[i] * g1[j] / (c1 * c1) + g2[i] * g2[j] / (c2 * c2)).collect()).collect();
        (-t * (x + y + z) - (-c1).ln() - (-c2).ln(), g, h)
    }
}

fn vol(u: &[f64]) -> f64 { (u[0] + u[1] + u[2]).exp() } // volume in litres from the logs
fn phi(x: f64) -> f64 { (-x * x / 2.0).exp() / (2.0 * std::f64::consts::PI).sqrt() } // normal density
fn big_phi(x: f64) -> f64 { // Simpson's rule from -12 to x, 2000 panels
    let (n, lo) = (2000, -12.0);
    let hs = (x - lo) / n as f64;
    hs / 3.0 * add((0..=n).map(|k| (if k == 0 || k == n { 1.0 } else if k % 2 == 1 { 4.0 } else { 2.0 }) * phi(lo + k as f64 * hs)))
}
fn growth(wt: &[f64]) -> f64 { add((0..4).map(|s| P[s] * dot(&R[s], wt).ln())) } // mean log of wealth
fn pct(wt: &[f64]) -> String { (0..5).map(|i| format!("{} {:.2}", NAMES[i], 100.0 * wt[i])).collect::<Vec<_>>().join("  ") }
fn full(x: &[f64]) -> Vec<f64> { let mut w = x.to_vec(); w.push(1.0 - add(x.iter().copied())); w }

fn kelly_f(x: &[f64], t: f64) -> Eval { // cost -t * growth - sum log w_i, w5 = 1 - sum
    let wt = full(x);
    if wt.iter().any(|&v| v <= 0.0) { return (f64::INFINITY, vec![], vec![]); }
    let w: Vec<f64> = R.iter().map(|r| dot(r, &wt)).collect();
    let gw: Vec<f64> = (0..5).map(|i| -t * add((0..4).map(|s| P[s] * R[s][i] / w[s])) - 1.0 / wt[i]).collect();
    let hw: Vec<Vec<f64>> = (0..5).map(|i| (0..5).map(|j| t * add((0..4).map(|s| P[s] * R[s][i] * R[s][j] / (w[s] * w[s])))
        + if i == j { 1.0 / (wt[i] * wt[i]) } else { 0.0 }).collect()).collect();
    let g: Vec<f64> = (0..4).map(|i| gw[i] - gw[4]).collect();
    let h: Vec<Vec<f64>> = (0..4).map(|i| (0..4).map(|j| hw[i][j] - hw[i][4] - hw[4][j] + hw[4][4]).collect()).collect();
    (-t * growth(&wt) - add(wt.iter().map(|v| v.ln())), g, h)
}

fn main() {
    let yn = |b: bool| if b { "yes" } else { "no" };
    let (u, steps, gap) = barrier(&box_f(200.0, 100.0), vec![0.0; 3], 2.0);
    let (h, w, d) = (u[0].exp(), u[1].exp(), u[2].exp());
    println!("road 1 barrier in logs: h {:.6}  w {:.6}  d {:.6} dm  volume {:.4} L  Newton steps {}  gap bound {:.0e}", h, w, d, vol(&u), steps, gap);
    let a = h * w / (h * w + h * d);
    let (lam1, lam2) = (1.0, 1.0 - a); // stationarity rows x and y; row z is the residual
    println!("road 2 wall-term weights {:.4} {:.4}  multipliers wall {:.4} floor {:.4}  z-row residual below 1e-6: {}", a, 1.0 - a, lam1, lam2, yn((lam1 * (1.0 - a) + lam2 - 1.0).abs() < 1e-6));
    let ceiling = 200.0 / 4.0 * 100.0f64.sqrt();
    println!("road 2 AM-GM ceiling (wall / 4) x sqrt(floor) = {:.4} L  wall used {:.4}  floor used {:.4}", ceiling, 2.0 * h * (w + d), w * d);
    let (mut best, mut nfl) = ((0.0, 0, 0), 0); // w = i/10, d = j/10; h fills the wall
    for i in 1..=200 { for j in 1..=200 { if i * j <= 10000 {
        let (wi, dj) = (i as f64 / 10.0, j as f64 / 10.0);
        let v = 100.0 / (wi + dj) * wi * dj; nfl += 1;
        if v > best.0 { best = (v, i, j); }
    } } }
    let (bw, bd) = (best.1 as f64 / 10.0, best.2 as f64 / 10.0);
    println!("road 3 grid of 40000 floors in 0.1 dm steps, {} within the floor limit: best w {:.1} d {:.1} h {:.4}  volume {:.4} L", nfl, bw, bd, 100.0 / (bw + bd), best.0);
    let vw = vol(&barrier(&box_f(202.0, 100.0), vec![0.0; 3], 2.0).0);
    let vf = vol(&barrier(&box_f(200.0, 101.0), vec![0.0; 3], 2.0).0);
    println!("sensitivity: wall 202 -> {:.4} L (+{:.4}%)  floor 101 -> {:.4} L (+{:.4}%)", vw, 100.0 * (vw / 500.0 - 1.0), vf, 100.0 * (vf / 500.0 - 1.0));
    let (ba, bb) = ([2.0, 2.0, 25.0], [10.0, 10.0, 5.0]); // (w, d, h): both use the full 200 dm^2 of wall
    let mut walls = vec![];
    for (name, bx) in [("plain mix", (0..3).map(|i| (ba[i] + bb[i]) / 2.0).collect::<Vec<f64>>()),
                       ("log mix", (0..3).map(|i| f64::sqrt(ba[i] * bb[i])).collect())] {
        walls.push(2.0 * bx[2] * (bx[0] + bx[1]));
        println!("{}: {:.4} x {:.4} x {:.4}  wall {:.4} dm^2  floor {:.4}  volume {:.4} L", name, bx[0], bx[1], bx[2], walls[walls.len() - 1], bx[0] * bx[1], bx[0] * bx[1] * bx[2]);
    }
    println!("figure, A (2, 25) B (10, 5) plain mix (6, 15) log mix ({:.4}, {:.4}); logs A ({:.4}, {:.4}) B ({:.4}, {:.4}) mix ({:.4}, {:.4})",
        20f64.sqrt(), 125f64.sqrt(), 2f64.ln(), 25f64.ln(), 10f64.ln(), 5f64.ln(), 20f64.ln() / 2.0, 125f64.ln() / 2.0);
    for s in [20.0, 40.0] { println!("wrong: floor limit dropped, side {:.0} dm: volume {:.4} L", s, 50.0 * s); } // h = 50/s
    println!("wrong: assume a cube: side {:.4} dm  volume {:.4} L", 50f64.sqrt(), 50f64.sqrt().powf(3.0));
    let tests: [(&str, Box<dyn Fn(f64) -> f64>); 4] = [("normal density", Box::new(phi)), ("normal CDF", Box::new(big_phi)),
        ("skew normal 2 phi Phi", Box::new(|x| 2.0 * phi(x) * big_phi(x))), ("two-bump mixture", Box::new(|x| (phi(x - 3.0) + phi(x + 3.0)) / 2.0))];
    let mid: Vec<f64> = tests.iter().map(|(_, f)| f(0.0).ln() - (f(-3.0).ln() + f(3.0).ln()) / 2.0).collect();
    for (k, (name, _)) in tests.iter().enumerate() { // midpoint test of log f between -3 and 3
        println!("log-concave test {}: log f(0) - mean(log f(-3), log f(3)) = {:.4}", name, mid[k]);
    }
    let te = -0.3 * 0.3f64.ln();
    println!("exp cone, entropy: x 0.3  r = -x log x = {:.6}  x e^(r/x) = {:.6} (<= 1 means in the cone)", te, 0.3 * (te / 0.3).exp());
    println!("exp cone, wall: v = {:.4} {:.4}  sum {:.6} (<= 1)", h * w / 100.0, h * d / 100.0, (h * w + h * d) / 100.0);
    let means: Vec<String> = (0..5).map(|i| format!("{} {:.2}", NAMES[i], 100.0 * (add((0..4).map(|s| P[s] * R[s][i])) - 1.0))).collect();
    println!("kelly mean return %  {}", means.join("  "));
    let (x, ksteps, kgap) = barrier(&kelly_f, vec![0.2; 4], 5.0);
    let wk = full(&x);
    let (gk_val, wv): (f64, Vec<f64>) = (growth(&wk), R.iter().map(|r| dot(r, &wk)).collect());
    println!("road 1 barrier weights %  {}  Newton steps {}  gap bound {:.0e}", pct(&wk), ksteps, kgap);
    println!("road 1 growth {:.6} a year in logs, median wealth x{:.6}", gk_val, gk_val.exp());
    let y: Vec<f64> = (0..4).map(|s| P[s] / wv[s]).collect(); // road 2: state prices, the dual point
    let gk: Vec<f64> = (0..5).map(|i| dot(&y, &R.iter().map(|r| r[i]).collect::<Vec<_>>())).collect();
    let dual = add((0..4).map(|s| P[s] * (P[s] / y[s]).ln()));
    println!("road 2 state prices y_s = p_s / W_s:  {}", y.iter().map(|v| format!("{:.6}", v)).collect::<Vec<_>>().join("  "));
    println!("road 2 price of each asset, sum y_s R_si (<= 1):  {}", (0..5).map(|i| format!("{} {:.6}", NAMES[i], gk[i])).collect::<Vec<_>>().join("  "));
    println!("road 2 dual ceiling sum p_s log(p_s / y_s) = {:.6}  gap to road 1 below 1e-9: {}", dual, yn((dual - gk_val).abs() < 1e-9));
    let mut grid = (-1.0, vec![]); // road 3: every mix in 2% steps
    for i in 0..51 { for j in 0..51 - i { for k in 0..51 - i - j { for l in 0..51 - i - j - k {
        let m: Vec<f64> = [i, j, k, l, 50 - i - j - k - l].iter().map(|&v| v as f64 / 50.0).collect();
        let gm = growth(&m);
        if gm > grid.0 { grid = (gm, m); }
    } } } }
    println!("road 3 grid in 2% steps (316251 mixes): best {}  growth {:.6}", pct(&grid.1), grid.0);
    println!("cone points (log W, 1, W) by scenario: {}", wv.iter().map(|v| format!("({:.4}, 1, {:.4})", v.ln(), v)).collect::<Vec<_>>().join("  "));
    let em = [0.0, 0.0, 1.0, 0.0, 0.0];
    println!("wrong: all in EM, the largest mean: growth {:.6}  crash wealth x{:.2}", growth(&em), R[3][2]);
    println!("wrong: equal weights: growth {:.6}", growth(&[0.2; 5]));
    let gmax = gk.iter().cloned().fold(f64::MIN, f64::max);
    assert!((vol(&u) - ceiling).abs() < 1e-6 && (lam1 * (1.0 - a) + lam2 - 1.0).abs() < 1e-6, "barrier meets the AM-GM ceiling and the KKT rows");
    assert!(best.0 <= ceiling + 1e-9 && (best.0 - vol(&u)).abs() < 1e-6, "no grid box beats the ceiling");
    assert!((vw / vol(&u) - 1.01).abs() < 1e-6 && (vf / vol(&u) - 1.01f64.sqrt()).abs() < 1e-6, "multipliers are the elasticities");
    assert!(gmax < 1.0 + 1e-9 && (dual - gk_val).abs() < 1e-9, "state prices: feasible dual meets the growth");
    assert!(grid.0 <= dual + 1e-12 && gk_val - grid.0 < 1e-3 && growth(&em) < gk_val, "nothing on the grid grows faster");
    assert!(mid[..3].iter().all(|&v| v > 0.0) && mid[3] < 0.0 && (mid[0] - 4.5).abs() < 1e-12
        && (mid[1] - (0.5f64.ln() - (1.3498980316301e-3f64.ln() + (1.0 - 1.3498980316301e-3f64).ln()) / 2.0)).abs() < 1e-9, "log-concave tests; Phi(-3) = 0.0013498980316301");
    println!("ALL CHECKS PASS");
}
