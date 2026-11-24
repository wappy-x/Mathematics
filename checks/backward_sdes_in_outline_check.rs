// Backward SDEs in outline -- the same check as the Python, std only.
// A one-year call on a share at 100, strike 100, volatility 0.20, real drift 0.08.
// Cash lent earns r = 2%; cash borrowed costs R = 6%.  Roads to the hedger's price:
// the Black-Scholes closed form; a Simpson average under Q (the change of measure);
// seeded draws under the real-world P, reweighted by the density; replication backward
// on a tree; the semilinear PDE (nonlinear Feynman-Kac) solved backward on a grid.
use std::f64::consts::PI;

const S0: f64 = 100.0;
const K: f64 = 100.0;
const K2: f64 = 110.0;
const SIG: f64 = 0.20;
const T: f64 = 1.0;
const MU: f64 = 0.08;
const LEND: f64 = 0.02;
const BORROW: f64 = 0.06;
const N: usize = 50;

fn ncdf(x: f64) -> f64 { // Marsaglia: 1/2 + phi(x)(x + x^3/3 + x^5/15 + ...)
    let (mut s, mut t, mut k) = (x, x, 1.0);
    while t.abs() > 1e-17 {
        t *= x * x / (2.0 * k + 1.0);
        s += t;
        k += 1.0;
    }
    0.5 + s * (-0.5 * x * x).exp() / (2.0 * PI).sqrt()
}

fn bs(rate: f64, k: f64) -> f64 { // Black-Scholes call, one year, at one rate
    let d1 = ((S0 / k).ln() + (rate + 0.5 * SIG * SIG) * T) / (SIG * T.sqrt());
    S0 * ncdf(d1) - k * (-rate * T).exp() * ncdf(d1 - SIG * T.sqrt())
}

fn pay(kind: usize, s: f64) -> f64 { // 0 call, 1 short call, 2 call spread 100/110, 3 short 110 call
    let (c1, c2) = ((s - K).max(0.0), (s - K2).max(0.0));
    [c1, -c1, c1 - c2, -c2][kind]
}

fn tree(kind: usize, n: usize, lend: f64, borrow: f64) -> (f64, usize, usize) { // replicate backward on the tree
    let h = T / n as f64;
    let a = SIG * h.sqrt();
    let mut y: Vec<f64> = (0..=n).map(|j| pay(kind, S0 * (a * (2.0 * j as f64 - n as f64)).exp())).collect();
    let (mut lends, mut borrows) = (0, 0);
    for m in (0..n).rev() {
        for j in 0..=m {
            let s = S0 * (a * (2.0 * j as f64 - m as f64)).exp();
            let (su, sd) = (s * a.exp(), s * (-a).exp());
            let delta = (y[j + 1] - y[j]) / (su - sd); // shares held: the hedge
            let cash = y[j + 1] - delta * su; // cash at the next date, same in both states
            if cash > 0.0 { lends += 1; }
            if cash < 0.0 { borrows += 1; } // nodes with no cash count as neither
            y[j] = delta * s + cash * (-(if cash >= 0.0 { lend } else { borrow }) * h).exp();
        }
    }
    (y[0], lends, borrows)
}

fn pde(kind: usize, lend: f64, borrow: f64) -> f64 { // u_t + s^2 sig^2 u_ss/2 + rho(s u_s - u) = 0
    let (m, dx, steps) = (200usize, 0.01, 1000usize);
    let dt = T / steps as f64;
    let mut v: Vec<f64> = (0..=2 * m).map(|i| pay(kind, S0 * ((i as f64 - m as f64) * dx).exp())).collect();
    for _ in 0..steps {
        let mut w = v.clone();
        for i in 1..2 * m {
            let ux = (v[i + 1] - v[i - 1]) / (2.0 * dx);
            let uxx = (v[i + 1] - 2.0 * v[i] + v[i - 1]) / (dx * dx);
            let rho = if v[i] - ux >= 0.0 { lend } else { borrow }; // cash = u - s u_s; its sign picks the rate
            w[i] = v[i] + dt * (0.5 * SIG * SIG * uxx + (rho - 0.5 * SIG * SIG) * ux - rho * v[i]);
        }
        w[0] = w[1] - (w[2] - w[1]) * (-dx).exp(); // straight line in s at both ends
        w[2 * m] = w[2 * m - 1] + (w[2 * m - 1] - w[2 * m - 2]) * dx.exp();
        v = w;
    }
    v[m]
}

struct Rng { state: u64, spare: Option<f64> }

impl Rng {
    fn uniform(&mut self) -> f64 { // SplitMix64 -> a number in (0, 1]
        self.state = self.state.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.state;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        (((z ^ (z >> 31)) >> 11) + 1) as f64 / 9007199254740992.0
    }
    fn normal(&mut self) -> f64 { // Box-Muller, both values of each pair used
        if let Some(z) = self.spare.take() { return z; }
        let r = (-2.0 * self.uniform().ln()).sqrt();
        let a = 2.0 * PI * self.uniform();
        self.spare = Some(r * a.sin());
        r * a.cos()
    }
}

fn f(x: f64) -> String { format!("{:.4}", x) }

fn main() {
    let theta = (MU - LEND) / SIG; // market price of risk
    let (bs_r, bs_big, bs_mid) = (bs(LEND, K), bs(BORROW, K), bs(0.5 * (LEND + BORROW), K));
    let d1 = ((S0 / K).ln() + (MU + 0.5 * SIG * SIG) * T) / SIG;
    let real = ((MU - LEND) * T).exp() * S0 * ncdf(d1) - K * (-LEND * T).exp() * ncdf(d1 - SIG);
    println!("closed form: call at r {} at R {} at 4% {} | no change of measure {}", f(bs_r), f(bs_big), f(bs_mid), f(real));
    let mut simpson = 0.0; // Simpson over the bell curve, under Q
    for i in 0..=4000usize {
        let z = -8.0 + 16.0 * i as f64 / 4000.0;
        let g = (S0 * ((LEND - 0.5 * SIG * SIG) * T + SIG * z).exp() - K).max(0.0) * (-0.5 * z * z).exp();
        let wt = if i == 0 || i == 4000 { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 };
        simpson += g * wt;
    }
    simpson = simpson * (16.0 / 4000.0) / 3.0;
    simpson *= (-LEND * T).exp() / (2.0 * PI).sqrt();
    println!("linear BSDE, Y_0 = E^Q[e^(-rT) xi] by Simpson: {}", f(simpson));
    let mut rng = Rng { state: 20261123, spare: None };
    let n = 200000usize;
    let (mut s1, mut s2, mut p1) = (0.0, 0.0, 0.0);
    for _ in 0..n {
        let w = rng.normal(); // W_T under P, T = 1
        let x = (-LEND * T).exp() * (S0 * ((MU - 0.5 * SIG * SIG) * T + SIG * w).exp() - K).max(0.0);
        let y = x * (-theta * w - 0.5 * theta * theta * T).exp(); // reweight by the density dQ/dP
        s1 += y;
        s2 += y * y;
        p1 += x;
    }
    let nf = n as f64;
    let (mc, se) = (s1 / nf, ((s2 / nf - (s1 / nf).powi(2)) / nf).sqrt());
    println!("draws under P, theta {} reweighted: {} +- {} | not reweighted: {}", f(theta), f(mc), f(se), f(p1 / nf));
    let h = T / N as f64;
    let (u, dd) = ((SIG * h.sqrt()).exp(), (-SIG * h.sqrt()).exp());
    let s = S0 * u; // hand step: node at step 49, price 100u
    let (su, sd) = (s * u, s * dd);
    let (pu, pd) = ((su - K).max(0.0), (sd - K).max(0.0));
    let delta = (pu - pd) / (su - sd);
    let cash = pu - delta * su;
    println!("hand step: u {} s {} su {} sd {} payoffs {} {}", f(u), f(s), f(su), f(sd), f(pu), f(pd));
    println!("  delta {} cash {} borrow today {} Y {} | at r {}", f(delta), f(cash), f(cash * (-BORROW * h).exp()),
        f(delta * s + cash * (-BORROW * h).exp()), f(delta * s + cash * (-LEND * h).exp()));
    let q = ((BORROW * h).exp() - dd) / (u - dd);
    println!("  same Y as a reweighted average: q {} Y {}", f(q), f((-BORROW * h).exp() * q * pu));
    let (t_lin, _, _) = tree(0, N, LEND, LEND);
    let (t_sell, lends, borrows) = tree(0, N, LEND, BORROW);
    let (t_buy, blends, bborrows) = tree(1, N, LEND, BORROW);
    println!("tree 50 steps: linear at r {} | seller two rates {} lending nodes {} borrowing {}", f(t_lin), f(t_sell), lends, borrows);
    println!("  buyer two rates (hedges the short call) {} lending nodes {} borrowing {}", f(-t_buy), blends, bborrows);
    println!("  seller minus buyer {} | linear at 4% {}", f(t_sell + t_buy), f(tree(0, N, 0.04, 0.04).0));
    let big: Vec<f64> = [0usize, 2, 3].iter().map(|&k| tree(k, 1000, LEND, BORROW).0).collect();
    let grid = [pde(0, LEND, BORROW), pde(0, LEND, LEND), pde(2, LEND, BORROW)];
    println!("tree 1000 steps, two rates: call {} spread {}", f(big[0]), f(big[1]));
    println!("PDE grid: call two rates {} call linear at r {} spread two rates {}", f(grid[0]), f(grid[1]), f(grid[2]));
    let (sp_r, sp_big) = (bs(LEND, K) - bs(LEND, K2), bs(BORROW, K) - bs(BORROW, K2));
    println!("spread linear at r {} at R {} | parts priced apart {}", f(sp_r), f(sp_big), f(big[0] + big[2]));
    let rates: Vec<f64> = (0..9).map(|i| 0.02 + 0.01 * i as f64).collect();
    let row = |v: Vec<String>| v.join(" ");
    println!("chart, borrow %      {}", row(rates.iter().map(|x| format!("{:.0}", 100.0 * x)).collect()));
    println!("chart, tree seller   {}", row(rates.iter().map(|&x| format!("{:.2}", tree(0, N, LEND, x).0)).collect()));
    println!("chart, closed form R {}", row(rates.iter().map(|&x| format!("{:.2}", bs(x, K))).collect()));
    assert!((bs_r - 8.916).abs() < 5e-4 && (simpson - bs_r).abs() < 1e-4); // change of measure = closed form
    assert!((mc - bs_r).abs() < 4.0 * se && (p1 / nf - real).abs() < 0.2); // density reweighting finds Q's price
    assert!((t_lin - bs_r).abs() < 0.05 && (big[0] - bs_big).abs() < 0.005); // tree converges to both closed forms
    assert!(lends == 0 && bborrows == 0 && (-t_buy - t_lin).abs() < 1e-9); // seller always borrows, buyer always lends
    assert!((grid[0] - bs_big).abs() < 0.01 && (grid[1] - bs_r).abs() < 0.01); // nonlinear Feynman-Kac: PDE = BSDE
    assert!((grid[2] - big[1]).abs() < 0.01 && big[1] > sp_r.max(sp_big) + 0.01); // comparison: above both linear prices
    assert!(t_sell > t_lin + 2.0 && big[0] + big[2] > big[1] + 0.01); // nonlinear: the parts do not add
    println!("ALL CHECKS PASS");
}
