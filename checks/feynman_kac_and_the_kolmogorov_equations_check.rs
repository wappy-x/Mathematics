// Feynman-Kac on a bet -- the check behind the card.  Rust std only.
// A price starts at $100 and wanders as Brownian motion, $20 spread per root-year.
// The bet pays (price - $100) after one year.  Two additions, read as PDE pieces:
// the seller fails at hazard k(x) = 0.001 x per year (a potential), and the bet
// dies if the price touches $90 (an edge, paths stopped).  Roads: closed forms
// (Gaussian tilt; images); the coin-flip tree (the equation stepped); a seeded
// coin-flip walk (the path average); residuals by centred differences.
const X0: f64 = 100.0;
const SIG: f64 = 20.0;
const T: f64 = 1.0;
const K: f64 = 100.0;
const B: f64 = 90.0;
const BETA: f64 = 0.001;

fn phi(z: f64) -> f64 { (-z * z / 2.0).exp() / (2.0 * std::f64::consts::PI).sqrt() }

fn ncdf(z: f64) -> f64 { // N(z) = 1/2 + phi(z) * sum z^(2n+1) / (1*3*...*(2n+1))
    let (mut s, mut t, mut n) = (z, z, 0.0);
    while t.abs() > 1e-17 * s.abs() {
        n += 1.0; t *= z * z / (2.0 * n + 1.0); s += t;
    }
    0.5 + phi(z) * s
}

fn call(x: f64, tau: f64) -> f64 { // plain expected payoff: the backward equation's solution
    let d = (x - K) / (SIG * tau.sqrt());
    (x - K) * ncdf(d) + SIG * tau.sqrt() * phi(d)
}

fn hazard_b(x: f64, tau: f64, beta: f64) -> f64 { // potential k(x) = beta x, by the Gaussian tilt
    (-beta * x * tau + beta.powi(2) * SIG.powi(2) * tau.powi(3) / 6.0).exp()
        * call(x - beta * SIG.powi(2) * tau.powi(2) / 2.0, tau)
}
fn hazard(x: f64, tau: f64) -> f64 { hazard_b(x, tau, BETA) }

fn edge(x: f64, tau: f64) -> f64 { call(x, tau) - call(2.0 * B - x, tau) } // images about $90

fn corner(x: f64, tau: f64) -> f64 { (x - B) * tau.powf(-1.5) * (-(x - B).powi(2) / (2.0 * SIG * SIG * tau)).exp() }

fn sci(v: f64) -> String { format!("{:.2e}", v) }

fn tree(n: usize, pot: bool, edg: bool) -> f64 { // u_i(x) = w(x) * (u(x+d) + u(x-d)) / 2
    let h = T / n as f64;
    let d = SIG * h.sqrt();
    let mut v: Vec<f64> = (0..=n).map(|j| (X0 + (2.0 * j as f64 - n as f64) * d - K).max(0.0)).collect();
    for i in (0..n).rev() {
        let mut nv = Vec::with_capacity(i + 1);
        for j in 0..=i {
            let x = X0 + (2.0 * j as f64 - i as f64) * d;
            let w = if edg && x <= B + 1e-9 { 0.0 } else if pot { 1.0 - BETA * x * h } else { 1.0 };
            nv.push(w * 0.5 * (v[j] + v[j + 1]));
        }
        v = nv;
    }
    v[0]
}

struct SplitMix64 { s: u64 }
impl SplitMix64 {
    fn next(&mut self) -> u64 {
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    }
}

fn walk(paths: usize, n: usize, seed: u64) -> ([f64; 4], [f64; 4]) { // the path average
    let mut rng = SplitMix64 { s: seed };
    let h = T / n as f64;
    let (mut sums, mut sq) = ([0.0f64; 4], [0.0f64; 4]);
    for _ in 0..paths {
        let (mut x, mut w, mut alive, mut bits, mut left) = (100i64, 1.0f64, true, 0u64, 0u32);
        for _ in 0..n {
            if left == 0 { bits = rng.next(); left = 64; }
            w *= 1.0 - BETA * x as f64 * h;
            x += if bits & 1 == 1 { 1 } else { -1 };
            bits >>= 1; left -= 1;
            if x <= 90 { alive = false; }
        }
        let pay = (x - 100).max(0) as f64;
        let vals = [pay, w * pay, if alive { pay } else { 0.0 }, if alive { w * pay } else { 0.0 }];
        for k in 0..4 { sums[k] += vals[k]; sq[k] += vals[k] * vals[k]; }
    }
    let p = paths as f64;
    let mean = sums.map(|s| s / p);
    let mut se = [0.0; 4];
    for k in 0..4 { se[k] = ((sq[k] / p - mean[k] * mean[k]) / p).sqrt(); }
    (mean, se)
}

fn resid(f: fn(f64, f64) -> f64, x: f64, tau: f64, dx: f64, beta: f64) -> f64 { // centred
    let ut = (f(x, tau + dx * 1e-3) - f(x, tau - dx * 1e-3)) / (2.0 * dx * 1e-3);
    let uxx = (f(x + dx, tau) - 2.0 * f(x, tau) + f(x - dx, tau)) / (dx * dx);
    ut - 0.5 * SIG * SIG * uxx + beta * x * f(x, tau)
}

fn main() {
    println!("Bet: price $100, spread $20 per root-year, pays (price - $100) after 1 year");
    println!("Hazard k(x) = 0.001 x per year (0.1 per year at $100); knock-out edge at $90");
    let cf = [call(X0, T), hazard(X0, T), edge(X0, T)];
    println!("closed form, plain (backward equation)   ${:.6}", cf[0]);
    println!("closed form, hazard as potential         ${:.6}", cf[1]);
    println!("closed form, knock-out edge by images    ${:.6}", cf[2]);
    let sh = BETA * SIG.powi(2) * T.powi(2) / 2.0;
    let tilt = BETA.powi(2) * SIG.powi(2) * T.powi(3) / 6.0;
    println!("hand: shift ${:.6}, tilt {:.8}, discount exp(-{:.8}) = {:.6}", sh, tilt, BETA * X0 * T - tilt, (-(BETA * X0 * T - tilt)).exp());
    println!("hand: plain at $99.80 ${:.6}; plain at $80 (mirror) ${:.6}", call(X0 - sh, T), call(2.0 * B - X0, T));
    println!("coin-flip tree, step h, plain, hazard, edge, both");
    let ns = [100usize, 400, 1600];
    let mut tr = [[0.0f64; 4]; 3];
    for (a, &n) in ns.iter().enumerate() {
        for (k, &(p, e)) in [(false, false), (true, false), (false, true), (true, true)].iter().enumerate() {
            tr[a][k] = tree(n, p, e);
        }
        let row: Vec<String> = tr[a].iter().map(|v| format!("{:.6}", v)).collect();
        println!("  n={:<5} h={:.6}  {}", n, T / n as f64, row.join("  "));
    }
    let orders: Vec<f64> = (0..4).map(|k| ((tr[0][k] - tr[1][k]) / (tr[1][k] - tr[2][k])).ln() / 4f64.ln()).collect();
    let ord: Vec<String> = orders.iter().map(|p| format!("{:.3}", p)).collect();
    println!("observed order {}", ord.join("  "));
    let both = (4.0 * tr[2][3] - tr[1][3]) / 3.0;
    println!("both pieces, tree extrapolated to h -> 0  ${:.6}", both);
    let (mean, se) = walk(160000, 400, 20261115);
    println!("coin-flip walk, 160000 paths x 400 steps, seed 20261115: estimate (standard error) vs tree n=400");
    for (k, name) in ["plain ", "hazard", "edge  ", "both  "].iter().enumerate() {
        println!("  {} {:.4} ({:.4})  tree {:.4}", name, mean[k], se[k], tr[1][k]);
        assert!((mean[k] - tr[1][k]).abs() < 4.0 * se[k]);
    }
    for k in 0..3 {
        assert!((tr[2][k] - cf[k]).abs() < 0.005 && orders[k] > 0.8 && orders[k] < 1.2);
    }
    let fs: [(&str, fn(f64, f64) -> f64, f64); 3] = [("hazard", hazard, BETA), ("edge  ", edge, 0.0), ("corner", corner, 0.0)];
    for (name, f, b) in fs.iter() {
        let r = [resid(*f, 100.0, T, 0.5, *b), resid(*f, 100.0, T, 0.25, *b)];
        println!("residual of {} at ($100, 1 yr), dx $0.50 and $0.25: {}  {}", name, sci(r[0]), sci(r[1]));
        assert!(r[0] / r[1] > 3.5 && r[0] / r[1] < 4.5); // truncation error, falling as dx^2
    }
    println!("edge value at $90 for 1 yr: {:.6}", edge(B, T));
    println!("what breaks");
    let frozen = cf[0] * (-BETA * X0 * T).exp();
    println!("  hazard frozen at today's 0.1 per year    ${:.6}", frozen);
    println!("  potential sign flipped (+k u)           ${:.6}", hazard_b(X0, T, -BETA));
    println!("  edge as a bouncing wall, not a stop     ${:.6}", call(X0, T) + call(2.0 * B - X0, T));
    println!("  no edge at all                          ${:.6}", cf[0]);
    let v1 = corner(X0, T);
    println!("  corner solution v at ($100, 1 yr) {:.6}; edge price + v ${:.6}", v1, cf[2] + v1);
    println!("  v at $100 with 0.001 yr left {:.6}; v at $90.20 with 0.0001 yr left {:.1}", corner(X0, 1e-3), corner(B + 0.2, 1e-4));
    assert!(frozen > cf[1] + 0.05 && cf[2] < cf[0]);
    println!("far-edge term in the uniqueness proof, R x 2 phi(z)/z with z = (R - 100)/20");
    for r in [150.0f64, 200.0, 250.0] {
        let z = (r - X0) / SIG;
        println!("  R ${:.0}: {}", r, sci(r * 2.0 * phi(z) / z));
    }
    println!("chart: price, plain, hazard, edge (1 year to go)");
    for x in (90..135).step_by(5) {
        let xf = x as f64;
        println!("  {}  {:.2}  {:.2}  {:.2}", x, call(xf, T), hazard(xf, T), edge(xf, T));
    }
    println!("try: hazard slope 0.002 -> ${:.6}; edge at $80 -> ${:.6}", hazard_b(X0, T, 0.002), call(X0, T) - call(60.0, T));
    let kap = 1.11e-4f64;
    println!("copper rod: kappa {} m^2/s, path spread after 10 s {:.2} cm", sci(kap), 100.0 * (2.0 * kap * 10.0).sqrt());
    println!("ALL CHECKS PASS");
}
