// Risk parity -- the same check as the Python, in Rust.  No crates.
// Three assets: shares (8%, 20%), bonds (4%, 6%), gold (5%, 15%), correlations
// shares-bonds 0.2, shares-gold 0.1, bonds-gold 0.  Equal-risk weights by three
// roads (coordinate steps, Newton's method, a brute-force grid), Euler's sum by
// bumping weights, and risk shares a fourth way, by simulating returns.
type M = Vec<Vec<f64>>;
const VOL: [f64; 3] = [0.20, 0.06, 0.15];
const MU: [f64; 3] = [0.08, 0.04, 0.05];
const RHO: [[f64; 3]; 3] = [[1.0, 0.2, 0.1], [0.2, 1.0, 0.0], [0.1, 0.0, 1.0]];

fn sw(s: &M, w: &[f64]) -> Vec<f64> {
    (0..w.len()).map(|i| (0..w.len()).fold(0.0, |a, j| a + s[i][j] * w[j])).collect()
}
fn dot(a: &[f64], b: &[f64]) -> f64 { a.iter().zip(b).fold(0.0, |t, (x, y)| t + x * y) }
fn vol(s: &M, w: &[f64]) -> f64 { dot(w, &sw(s, w)).sqrt() }
fn euler(s: &M, w: &[f64]) -> (Vec<f64>, Vec<f64>) {   // marginal risk (S w)_i / vol, contribution w_i times it
    let v = vol(s, w);
    let mrc: Vec<f64> = sw(s, w).iter().map(|x| x / v).collect();
    let rc = w.iter().zip(&mrc).map(|(a, b)| a * b).collect();
    (mrc, rc)
}
fn share(s: &M, w: &[f64]) -> Vec<f64> { euler(s, w).1.iter().map(|x| x / vol(s, w)).collect() }
fn norm(y: &[f64]) -> Vec<f64> { let t = y.iter().fold(0.0, |a, b| a + b); y.iter().map(|x| x / t).collect() }
fn ret(w: &[f64]) -> f64 { dot(w, &MU) }
fn row(lab: &str, v: &[f64]) { println!("{:<24}{}", lab, v.iter().map(|x| format!("{:10.6}", x)).collect::<String>()) }
fn erc_steps(s: &M) -> Vec<f64> {                 // road 1: each y_i solves S_ii y^2 + b y - 1 = 0 in turn
    let n = s.len();
    let mut y = vec![1.0; n];
    for _ in 0..300 {
        for i in 0..n {
            let b = (0..n).filter(|&j| j != i).fold(0.0, |a, j| a + s[i][j] * y[j]);
            y[i] = (-b + (b * b + 4.0 * s[i][i]).sqrt()) / (2.0 * s[i][i]);
        }
    }
    norm(&y)
}
fn solve(a: &M, b: &[f64]) -> Vec<f64> {          // Gaussian elimination with row swaps
    let n = b.len();
    let mut m: M = (0..n).map(|i| { let mut r = a[i].clone(); r.push(b[i]); r }).collect();
    for k in 0..n {
        let mut p = k;
        for r in k..n { if m[r][k].abs() > m[p][k].abs() { p = r } }
        m.swap(k, p);
        for r in k + 1..n {
            let f = m[r][k] / m[k][k];
            for c in 0..=n { m[r][c] -= f * m[k][c] }
        }
    }
    let mut x = vec![0.0; n];
    for k in (0..n).rev() {
        x[k] = (m[k][n] - (k + 1..n).fold(0.0, |t, c| t + m[k][c] * x[c])) / m[k][k];
    }
    x
}
fn erc_newton(s: &M) -> Vec<f64> {                // road 2: Newton on S y - 1/y = 0, kept positive
    let n = s.len();
    let mut y = vec![1.0; n];
    for _ in 0..60 {
        let g: Vec<f64> = sw(s, &y).iter().enumerate().map(|(i, a)| a - 1.0 / y[i]).collect();
        let h: M = (0..n).map(|i| (0..n).map(|j| s[i][j] + if i == j { 1.0 / (y[i] * y[i]) } else { 0.0 }).collect()).collect();
        let d = solve(&h, &g);
        let mut t = 1.0;
        while (0..n).any(|i| y[i] - t * d[i] <= 0.0) { t /= 2.0 }
        y = (0..n).map(|i| y[i] - t * d[i]).collect();
    }
    norm(&y)
}
fn erc_grid(s: &M, steps: usize) -> Vec<f64> {    // road 3: every weight in 0.1% steps, smallest spread
    let (mut best, mut bw) = (9.0, vec![]);
    for a in 1..steps {
        for b in 1..steps - a {
            let w = [a as f64 / steps as f64, b as f64 / steps as f64, (steps - a - b) as f64 / steps as f64];
            let rc = euler(s, &w).1;
            let spread = rc.iter().cloned().fold(f64::MIN, f64::max) - rc.iter().cloned().fold(f64::MAX, f64::min);
            if spread < best { best = spread; bw = w.to_vec() }
        }
    }
    bw
}
struct Rng(u64);                                  // splitmix64, the same stream as the Python
impl Rng {
    fn unif(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0 + 1e-18
    }
}
fn main() {
    let s: M = (0..3).map(|i| (0..3).map(|j| RHO[i][j] * VOL[i] * VOL[j]).collect()).collect();
    let (w1, w2, w3) = (erc_steps(&s), erc_newton(&s), erc_grid(&s, 1000));
    let (ew, sixty, iv) = (vec![1.0 / 3.0; 3], vec![0.6, 0.4, 0.0], norm(&VOL.iter().map(|v| 1.0 / v).collect::<Vec<f64>>()));
    let mv = norm(&solve(&s, &[1.0, 1.0, 1.0]));
    println!("equal-risk weights      shares     bonds      gold");
    row("road 1, coordinate steps", &w1); row("road 2, Newton", &w2); row("road 3, grid of 0.1%", &w3);
    let ((mrc, rc), h, s1) = (euler(&s, &w1), 1e-6, vol(&s, &w1));
    let fd: Vec<f64> = (0..3).map(|i| {
        let up: Vec<f64> = (0..3).map(|j| w1[j] + if j == i { h } else { 0.0 }).collect();
        let dn: Vec<f64> = (0..3).map(|j| w1[j] - if j == i { h } else { 0.0 }).collect();
        (vol(&s, &up) - vol(&s, &dn)) / (2.0 * h)
    }).collect();
    println!("covariance S, row by row: {}", s.iter().map(|r| r.iter().map(|a| format!("{:.4}", a)).collect::<Vec<_>>().join(" ")).collect::<Vec<_>>().join(" | "));
    row("covariance times w, S w", &sw(&s, &w1)); row("marginal risk, formula", &mrc);
    row("marginal risk, bumped", &fd); row("risk contribution", &rc);
    println!("{:<24}{}, total {:.6}", "w times S w", sw(&s, &w1).iter().zip(&w1).map(|(a, b)| format!("{:10.6}", b * a)).collect::<String>(), s1 * s1);
    println!("{:<24}{:10.6}", "portfolio volatility", s1); println!("{:<24}{:10.6}", "sum of contributions", dot(&w1, &fd));

    let mut rng = Rng(0x2545F4914F6CDD1D);         // road 4: simulate returns, split the variance
    let mut l = vec![vec![0.0; 3]; 3];            // Cholesky: S = L L^T
    for i in 0..3 {
        for j in 0..=i {
            let t = s[i][j] - (0..j).fold(0.0, |a, k| a + l[i][k] * l[j][k]);
            l[i][j] = if i == j { t.sqrt() } else { t / l[j][j] };
        }
    }
    let (mut acc, mut accp) = (vec![0.0; 3], 0.0);
    for _ in 0..200000 {
        let e: Vec<f64> = (0..3).map(|_| {
            let r = (-2.0 * rng.unif().ln()).sqrt();
            r * (2.0 * std::f64::consts::PI * rng.unif()).cos()
        }).collect();
        let r: Vec<f64> = (0..3).map(|i| (0..3).fold(0.0, |a, k| a + l[i][k] * e[k])).collect();
        let parts: Vec<f64> = (0..3).map(|i| w1[i] * r[i]).collect();
        let p = parts.iter().fold(0.0, |a, b| a + b);
        for i in 0..3 { acc[i] += parts[i] * p }
        accp += p * p;
    }
    let sim: Vec<f64> = acc.iter().map(|a| a / accp).collect();
    row("risk share, formula", &share(&s, &w1)); row("risk share, simulated", &sim);

    println!();
    println!("portfolio              shares   bonds    gold    vol  return  | risk share: shares bonds gold");
    for (lab, w) in [("equal money", &ew), ("60/40 shares/bonds", &sixty), ("inverse volatility", &iv),
                     ("minimum variance", &mv), ("equal risk", &w1)] {
        let a: String = w.iter().map(|x| format!("{:8.2}", 100.0 * x)).collect();
        let b: String = share(&s, w).iter().map(|x| format!("{:7.2}", 100.0 * x)).collect();
        println!("{:<20}{}{:7.2}{:7.2}  |{}", lab, a, 100.0 * vol(&s, w), 100.0 * ret(w), b);
    }
    let rs: Vec<f64> = RHO.iter().map(|r| r.iter().fold(0.0, |a, b| a + b)).collect(); let rst = rs.iter().fold(0.0, |a, b| a + b);
    let j = |v: Vec<String>| v.join(" ");
    println!("inverse volatility, correlation row sums {} of {:.2}: {}", j(rs.iter().map(|a| format!("{:.2}", a)).collect()), rst, j(rs.iter().map(|a| format!("{:.2}", 100.0 * a / rst)).collect()));
    println!("minimum variance, marginal risk each: {}", j(euler(&s, &mv).0.iter().map(|a| format!("{:.6}", a)).collect()));
    let lev = vol(&s, &sixty) / s1;
    println!("return per unit of risk: 60/40 {:.4}, equal risk {:.4}; levered {:.4}x to 60/40's vol: {:.2}% before, {:.2}% after borrowing at 5%",
             ret(&sixty) / vol(&s, &sixty), ret(&w1) / s1, lev, 100.0 * lev * ret(&w1), 100.0 * (lev * ret(&w1) - (lev - 1.0) * 0.05));
    let own: Vec<f64> = (0..3).map(|i| 100.0 * w1[i] * w1[i] * s[i][i] / (s1 * s1)).collect();
    println!("wrong: own-variance shares at equal risk: {}, summing to {:.2}",
             j(own.iter().map(|a| format!("{:.2}", a)).collect()), own.iter().fold(0.0, |a, b| a + b));
    let (c, cn) = (0.2 * 0.2 * 0.06, -0.5 * 0.2 * 0.06);
    let (s2, s2n): (M, M) = (vec![vec![0.04, c], vec![c, 0.0036]], vec![vec![0.04, cn], vec![cn, 0.0036]]);
    let (b2, b2n) = (erc_steps(&s2)[1], erc_steps(&s2n)[1]);
    println!("two assets, correlation 0.2: bonds {:.6}; correlation -0.5: bonds {:.6}; 0.20/(0.20+0.06) = {:.6}", b2, b2n, 0.20 / 0.26);
    println!();
    let (g, bs) = (w1[0] / (w1[0] + w1[2]), [0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9]);
    println!("chart: shares and gold kept {:.0}:{:.0} as in the equal-risk mix; bonds' weight across", 100.0 * g, 100.0 - 100.0 * g);
    println!("bonds' weight, %     {}", bs.iter().map(|b| format!("{:7.0}", 100.0 * b)).collect::<String>());
    for (lab, k) in [("bonds' risk share, %", 1), ("shares' risk share, %", 0)] {
        let v: String = bs.iter().map(|b| format!("{:7.2}", 100.0 * share(&s, &[(1.0 - b) * g, *b, (1.0 - b) * (1.0 - g)])[k])).collect();
        println!("{:<21}{}", lab, v);
    }
    assert!((0..3).all(|i| (w1[i] - w2[i]).abs() < 1e-10), "coordinate steps and Newton disagree");
    assert!((0..3).all(|i| (w1[i] - w3[i]).abs() < 2e-3), "grid lands away from the equal-risk mix");
    assert!((0..3).all(|i| (mrc[i] - fd[i]).abs() < 1e-8), "marginal risk formula disagrees with the bump");
    assert!((dot(&w1, &fd) - s1).abs() < 1e-9, "Euler: bumped contributions must sum to vol");
    assert!(sim.iter().all(|a| (a - 1.0 / 3.0).abs() < 0.01), "simulated risk shares are not a third each");
    assert!((b2n - 0.20 / 0.26).abs() < 1e-10, "two assets: equal risk is inverse volatility");
    assert!(vol(&s, &mv) < s1 && s1 < vol(&s, &ew), "volatility order min-variance < equal-risk < equal-money");
    println!("ALL CHECKS PASS");
}
