// Black-Litterman -- the check behind the card.  Rust std only, no crates.
// Assets in the order shares, bonds, gold.  Reverse optimisation gives the
// returns the market's weights imply; the posterior is then reached three
// ways: the view-space formula, the precision (Bayes) formula, and a Monte
// Carlo draw from the prior, each draw weighted by how well it fits the views.
const VOL: [f64; 3] = [0.20, 0.06, 0.15];
const CORR: [[f64; 3]; 3] = [[1.0, 0.2, 0.1], [0.2, 1.0, 0.0], [0.1, 0.0, 1.0]];
const W_MKT: [f64; 3] = [0.55, 0.30, 0.15]; // the market's weights
const DELTA: f64 = 2.5; // risk aversion
const TAU: f64 = 0.05; // prior scale
const Q: [f64; 2] = [0.02, 0.04]; // the views, as returns above cash

type V = Vec<f64>;
type M = Vec<V>;

fn sig() -> M {
    (0..3).map(|i| (0..3).map(|j| CORR[i][j] * VOL[i] * VOL[j]).collect()).collect()
}

fn matvec(a: &M, x: &[f64]) -> V {
    a.iter().map(|r| (0..x.len()).map(|j| r[j] * x[j]).sum()).collect()
}

fn solve(a: &M, b: &[f64]) -> V {
    // Gaussian elimination, partial pivoting
    let n = b.len();
    let mut m: M = (0..n).map(|i| { let mut r = a[i].clone(); r.push(b[i]); r }).collect();
    for j in 0..n {
        let mut p = j;
        for i in j..n { if m[i][j].abs() > m[p][j].abs() { p = i; } }
        m.swap(j, p);
        for i in 0..n {
            if i != j {
                let f = m[i][j] / m[j][j];
                let row_j = m[j].clone();
                for (u, v) in m[i].iter_mut().zip(row_j.iter()) { *u -= f * v; }
            }
        }
    }
    (0..n).map(|i| m[i][n] / m[i][i]).collect()
}

struct Bl { s: M, pi: V }

impl Bl {
    fn omega_for(&self, p: &[f64], conf: f64) -> f64 {
        let mut pcp = 0.0;
        for i in 0..3 { for j in 0..3 { pcp += p[i] * TAU * self.s[i][j] * p[j]; } }
        pcp * (1.0 - conf) / conf
    }
    fn posterior(&self, rows: &M, q: &[f64], om: &[f64], tau: f64) -> (V, V) {
        // view-space form: a k x k solve
        let k = rows.len();
        let cp: M = (0..3).map(|i| (0..k).map(|a| tau * (0..3).map(|j| self.s[i][j] * rows[a][j]).sum::<f64>()).collect()).collect();
        let s: M = (0..k).map(|a| (0..k).map(|b| (0..3).map(|i| rows[a][i] * cp[i][b]).sum::<f64>() + if a == b { om[a] } else { 0.0 }).collect()).collect();
        let surprise: V = (0..k).map(|a| q[a] - (0..3).map(|i| rows[a][i] * self.pi[i]).sum::<f64>()).collect();
        let z = solve(&s, &surprise);
        ((0..3).map(|i| self.pi[i] + (0..k).map(|a| cp[i][a] * z[a]).sum::<f64>()).collect(), z)
    }
    fn precision_form(&self, p: &M, q: &[f64], om: &[f64]) -> V {
        // Bayes form: a 3 x 3 solve
        let c: M = self.s.iter().map(|r| r.iter().map(|v| TAU * v).collect()).collect();
        let cols: M = (0..3).map(|j| solve(&c, &(0..3).map(|i| if i == j { 1.0 } else { 0.0 }).collect::<V>())).collect();
        let a: M = (0..3).map(|i| (0..3).map(|j| cols[j][i] + (0..2).map(|k| p[k][i] * p[k][j] / om[k]).sum::<f64>()).collect()).collect();
        let b: V = (0..3).map(|i| (0..3).map(|j| cols[j][i] * self.pi[j]).sum::<f64>() + (0..2).map(|k| p[k][i] * q[k] / om[k]).sum::<f64>()).collect();
        solve(&a, &b)
    }
    fn weights(&self, mu: &[f64]) -> V {
        solve(&self.s, &mu.iter().map(|v| v / DELTA).collect::<V>())
    }
}

struct Rng(u64);
impl Rng {
    fn uniform(&mut self) -> f64 {
        // splitmix64, written out
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = (self.0 ^ (self.0 >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        (((z ^ (z >> 31)) >> 11) as f64 + 0.5) / 9007199254740992.0
    }
}

fn monte_carlo(bl: &Bl, p: &M, om: &[f64], n: usize) -> (V, V) {
    // prior draws, weighted by the views
    let mut l = vec![vec![0.0; 3]; 3]; // Cholesky factor of tau * Sigma
    for i in 0..3 {
        for j in 0..=i {
            let r = TAU * bl.s[i][j] - (0..j).map(|k| l[i][k] * l[j][k]).sum::<f64>();
            l[i][j] = if i == j { r.sqrt() } else { r / l[j][j] };
        }
    }
    let mut rng = Rng(20260928);
    let mut draws: Vec<(f64, V)> = Vec::with_capacity(n);
    for _ in 0..n {
        let e: V = (0..3).map(|_| { let u1 = rng.uniform(); let u2 = rng.uniform();
            (-2.0 * u1.ln()).sqrt() * (2.0 * std::f64::consts::PI * u2).cos() }).collect();
        let th: V = (0..3).map(|i| bl.pi[i] + (0..=i).map(|k| l[i][k] * e[k]).sum::<f64>()).collect();
        let g: f64 = (0..2).map(|a| (Q[a] - (0..3).map(|i| p[a][i] * th[i]).sum::<f64>()).powi(2) / om[a]).sum();
        draws.push(((-0.5 * g).exp(), th));
    }
    let sw: f64 = draws.iter().map(|d| d.0).sum();
    let mean: V = (0..3).map(|i| draws.iter().map(|d| d.0 * d.1[i]).sum::<f64>() / sw).collect();
    let se: V = (0..3).map(|i| draws.iter().map(|d| (d.0 * (d.1[i] - mean[i])).powi(2)).sum::<f64>().sqrt() / sw).collect();
    (mean, se)
}

fn pct(xs: &[f64]) -> String {
    xs.iter().map(|x| format!("{:.4}", 100.0 * x)).collect::<Vec<_>>().join("  ")
}

fn pct2(xs: &[f64]) -> String { xs.iter().map(|x| format!("{:.2}", 100.0 * x)).collect::<Vec<_>>().join("  ") }

fn main() {
    let s = sig();
    let pi: V = matvec(&s, &W_MKT).iter().map(|v| DELTA * v).collect(); // reverse optimisation
    let bl = Bl { s: s.clone(), pi: pi.clone() };
    let p: M = vec![vec![0.0, -1.0, 1.0], vec![1.0, 0.0, 0.0]]; // gold minus bonds; shares
    for (name, row) in ["shares", "bonds ", "gold  "].iter().zip(s.iter()) {
        println!("covariance row {} {}", name, pct(row));
    }
    let var_m: f64 = (0..3).map(|i| (0..3).map(|j| W_MKT[i] * s[i][j] * W_MKT[j]).sum::<f64>()).sum();
    println!("market volatility {:.4}  premium {:.4}", 100.0 * var_m.sqrt(), 100.0 * DELTA * var_m);
    println!("implied returns pi        {}", pct(&pi));
    let back = bl.weights(&pi);
    println!("optimiser fed pi returns  {}", pct(&back));
    let om: V = p.iter().map(|r| bl.omega_for(r, 0.5)).collect();
    println!("view variances x 10000    {}", pct(&om.iter().map(|v| 100.0 * v).collect::<V>()));
    println!("prior view values         {}", pct(&matvec(&p, &pi)));
    let (mu, z) = bl.posterior(&p, &Q, &om, TAU);
    let mu_b = bl.precision_form(&p, &Q, &om);
    let (mc, se) = monte_carlo(&bl, &p, &om, 400000);
    println!("posterior, view-space     {}", pct(&mu));
    println!("posterior, precision      {}", pct(&mu_b));
    println!("posterior, Monte Carlo    {}", pct(&mc));
    println!("Monte Carlo std error     {}", pct(&se));
    println!("posterior view values     {}", pct(&matvec(&p, &mu)));
    let w_bl = bl.weights(&mu);
    let lam: V = z.iter().map(|v| TAU / DELTA * v).collect();
    let tilt: V = (0..3).map(|i| W_MKT[i] + (0..2).map(|a| p[a][i] * lam[a]).sum::<f64>()).collect();
    println!("weights, optimiser        {}  cash {:.4}", pct(&w_bl), 100.0 * (1.0 - w_bl.iter().sum::<f64>()));
    println!("weights, market + tilts   {}  lambda {}", pct(&tilt), pct(&lam));
    println!("confidence in view 1: spread, then weights shares bonds gold");
    for c in [0.0, 0.25, 0.5, 0.75, 1.0] {
        let m = if c == 0.0 { bl.posterior(&p[1..].to_vec(), &Q[1..], &om[1..], TAU).0 }
                else { bl.posterior(&p, &Q, &[bl.omega_for(&p[0], c), om[1]], TAU).0 };
        let mut row = vec![m[2] - m[1]];
        row.extend(bl.weights(&m));
        println!("  c = {:3.0} {}", 100.0 * c, pct2(&row));
    }
    let certain = bl.posterior(&p, &Q, &[0.0, om[1]], TAU).0;
    let still = bl.precision_form(&p, &matvec(&p, &pi), &om);
    println!("mistakes, weights shares bonds gold:");
    println!("  tau = 1, views unchanged      {}", pct2(&bl.weights(&bl.posterior(&p, &Q, &om, 1.0).0)));
    let flip: M = vec![vec![0.0, 1.0, -1.0], p[1].clone()];
    println!("  view row flipped (bonds-gold) {}", pct2(&bl.weights(&bl.posterior(&flip, &Q, &om, TAU).0)));
    let gold: M = vec![vec![0.0, 0.0, 1.0], p[1].clone()];
    let om_g = [bl.omega_for(&gold[0], 0.5), om[1]];
    println!("  gold view read as absolute    {}", pct2(&bl.weights(&bl.posterior(&gold, &Q, &om_g, TAU).0)));
    println!("  both views certain (omega 0)  {}", pct2(&bl.weights(&bl.posterior(&p, &Q, &[0.0, 0.0], TAU).0)));
    assert!((0..3).all(|i| (back[i] - W_MKT[i]).abs() < 1e-12));
    assert!((0..3).all(|i| (mu[i] - mu_b[i]).abs() < 1e-12));
    assert!((0..3).all(|i| (mc[i] - mu[i]).abs() < 4.0 * se[i]));
    assert!((0..3).all(|i| (w_bl[i] - tilt[i]).abs() < 1e-12));
    assert!((certain[2] - certain[1] - Q[0]).abs() < 1e-12);
    assert!((0..3).all(|i| (still[i] - pi[i]).abs() < 1e-12));
    let one = bl.posterior(&p[..1].to_vec(), &Q[..1], &[bl.omega_for(&p[0], 0.25)], TAU).0; // one view alone: a quarter of the way
    assert!((one[2] - one[1] - (pi[2] - pi[1] + 0.25 * (Q[0] - pi[2] + pi[1]))).abs() < 1e-12);
    println!("all checks passed");
}
