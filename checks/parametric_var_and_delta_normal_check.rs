// Parametric (delta-normal) VaR -- the check behind the card, in Rust, std only.
// The book: 10,000,000 of shares, a 5,000,000 bond, 1,000 Acme call contracts
// on 100 shares each.  One day, 99%.  Same roads and labels as the Python.
use std::f64::consts::PI;

fn n_cdf(x: f64) -> f64 { // normal CDF: Simpson on the bell curve
    let (n, a) = (2000, x.abs());
    let h = a / n as f64;
    let f = |t: f64| (-0.5 * t * t).exp() / (2.0 * PI).sqrt();
    let mut s = f(0.0) + f(a);
    for i in 1..n { s += (if i % 2 == 1 { 4.0 } else { 2.0 }) * f(i as f64 * h); }
    let half = s * h / 3.0;
    if x >= 0.0 { 0.5 + half } else { 0.5 - half }
}

fn inv_n(p: f64) -> f64 { // bisection: the z with N(z) = p
    let (mut lo, mut hi) = (-10.0, 10.0);
    for _ in 0..100 {
        let mid = 0.5 * (lo + hi);
        if n_cdf(mid) < p { lo = mid } else { hi = mid }
    }
    0.5 * (lo + hi)
}

type M = [[f64; 3]; 3];

fn cov(rh: &M, vol: &[f64; 3]) -> M {
    let mut c = [[0.0; 3]; 3];
    for i in 0..3 { for j in 0..3 { c[i][j] = rh[i][j] * vol[i] * vol[j]; } }
    c
}

fn var_quad(w: &[f64; 3], c: &M, z: f64) -> f64 { // road 1: z * sqrt(w' C w)
    let mut v = 0.0;
    for i in 0..3 { for j in 0..3 { v += w[i] * c[i][j] * w[j]; } }
    z * v.sqrt()
}

struct Rng(u64);
impl Rng {
    fn u01(&mut self) -> f64 { // splitmix64 -> uniform in (0,1)
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut x = self.0;
        x = (x ^ (x >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        x = (x ^ (x >> 27)).wrapping_mul(0x94D049BB133111EB);
        x ^= x >> 31;
        ((x >> 11) as f64 + 0.5) / 9007199254740992.0
    }
}

fn main() {
    // ---- mapping: each position becomes dollars per unit move of a risk factor ----
    let (s, k, r, q, sig, t) = (100.0f64, 100.0f64, 0.05, 0.02, 0.20f64, 1.0f64);
    let d1 = ((s / k).ln() + (r - q + 0.5 * sig * sig) * t) / (sig * t.sqrt());
    let delta = (-q * t).exp() * n_cdf(d1);
    let bs_call = |s0: f64| { // Black-Scholes call at spot s0
        let d = ((s0 / k).ln() + (r - q + 0.5 * sig * sig) * t) / (sig * t.sqrt());
        s0 * (-q * t).exp() * n_cdf(d) - k * (-r * t).exp() * n_cdf(d - sig * t.sqrt()) };
    let (call, delta_fd) = (bs_call(s), (bs_call(s + 0.01) - bs_call(s - 0.01)) / 0.02);
    let pv01 = 5_000_000.0 * 5.0 * 0.0001;
    let w = [10_000_000.0, 1000.0 * 100.0 * s * delta, -pv01];
    let vol = [0.0135, sig / 252f64.sqrt(), 6.0];
    let rho: M = [[1.0, 0.5, 0.2], [0.5, 1.0, 0.1], [0.2, 0.1, 1.0]];
    let (z99, z95) = (inv_n(0.99), inv_n(0.95));
    let c = cov(&rho, &vol);
    let v1 = var_quad(&w, &c, z99);

    // ---- road 2: Cholesky, C = L L', so the P&L is a sum of independent moves ----
    let mut l = [[0.0f64; 3]; 3];
    for i in 0..3 {
        for j in 0..=i {
            let mut x = c[i][j];
            for kk in 0..j { x -= l[i][kk] * l[j][kk]; }
            l[i][j] = if i == j { x.sqrt() } else { x / l[j][j] };
        }
    }
    let mut b = [0.0f64; 3];
    for kk in 0..3 { for i in 0..3 { b[kk] += w[i] * l[i][kk]; } }
    let v2 = z99 * b.iter().map(|x| x * x).sum::<f64>().sqrt();

    // ---- road 3: dollar volatilities and correlations, the hand table ----
    let sd: Vec<f64> = (0..3).map(|i| w[i] * vol[i]).collect();
    let mut terms = Vec::new();
    for i in 0..3 { for j in i..3 { terms.push((i, j, rho[i][j] * sd[i] * sd[j] * if i == j { 1.0 } else { 2.0 })); } }
    let v3 = z99 * terms.iter().map(|x| x.2).sum::<f64>().sqrt();

    // ---- road 4: simulate 100,000 days, own random numbers, read the 1% tail ----
    let mut rng = Rng(20260928);
    let n = 100_000usize;
    let mut pnl = Vec::with_capacity(n);
    for _ in 0..n {
        let mut g: Vec<f64> = Vec::new();
        while g.len() < 3 {
            let rad = (-2.0 * rng.u01().ln()).sqrt();
            let ang = 2.0 * PI * rng.u01();
            g.extend([rad * ang.cos(), rad * (ang - 0.5 * PI).cos()]);
        }
        pnl.push((0..3).map(|i| w[i] * (0..3).map(|kk| l[i][kk] * g[kk]).sum::<f64>()).sum::<f64>());
    }
    pnl.sort_by(|a, b| a.partial_cmp(b).unwrap());
    let v4 = -pnl[n / 100 - 1];

    // ---- decomposition: component = position x marginal; marginal by bumping ----
    let sp = v1 / z99;
    let (mut comp, mut bump, mut alone) = ([0.0f64; 3], [0.0f64; 3], [0.0f64; 3]);
    for i in 0..3 {
        let ce: f64 = (0..3).map(|j| c[i][j] * w[j]).sum();
        comp[i] = z99 * w[i] * ce / sp;
        let (mut up, mut dn) = (w, w);
        up[i] *= 1.0001; dn[i] *= 0.9999;
        bump[i] = (var_quad(&up, &c, z99) - var_quad(&dn, &c, z99)) / 0.0002;
        alone[i] = z99 * sd[i].abs();
    }

    // ---- what breaks ----
    let w_sum: f64 = alone.iter().sum();
    let w_zero = z99 * sd.iter().map(|x| x * x).sum::<f64>().sqrt();
    let w_prem = var_quad(&[w[0], 1000.0 * 100.0 * call, w[2]], &c, z99);
    let w_annual = var_quad(&w, &c.map(|row| row.map(|x| x * 252.0)), z99);
    let w_95 = z95 * sp;

    let names = ["shares", "calls (Acme)", "bond (yield)"];
    let mut rows: Vec<(String, f64)> = vec![
        ("d1".into(), d1), ("call price".into(), call), ("call delta".into(), delta),
        ("calls' market value".into(), 1000.0 * 100.0 * call), ("delta, in Acme shares".into(), 1000.0 * 100.0 * delta),
        ("bond PV01 $/bp".into(), pv01), ("Acme daily vol".into(), vol[1]),
        ("z at 99%".into(), z99), ("z at 95%".into(), z95),
        ("exposure shares $/1.00".into(), w[0]), ("exposure calls $/1.00".into(), w[1]), ("exposure bond $/bp".into(), w[2]),
    ];
    for i in 0..3 { rows.push((format!("dollar vol {}", names[i]), sd[i])); }
    for (i, j, x) in &terms { rows.push((format!("term {}{}", i + 1, j + 1), *x)); }
    for (a, x) in [("portfolio sigma", sp), ("1 VaR, quadratic form", v1), ("2 VaR, Cholesky", v2),
                   ("3 VaR, dollar-vol table", v3), ("4 VaR, 100,000 simulated days", v4)] { rows.push((a.into(), x)); }
    for i in 0..3 { rows.push((format!("component {}", names[i]), comp[i])); }
    for i in 0..3 { rows.push((format!("  by bumping {}", names[i]), bump[i])); }
    for i in 0..3 { rows.push((format!("  percent of VaR {}", names[i]), 100.0 * comp[i] / v1)); }
    for i in 0..3 { rows.push((format!("standalone {}", names[i]), alone[i])); }
    for (a, x) in [("wrong: add standalone VaRs", w_sum), ("wrong: correlations set to 0", w_zero),
                   ("wrong: calls at premium", w_prem), ("wrong: annual vols", w_annual), ("wrong: 95% z, called 99%", w_95),
                   ("try: 10-day, root-10 rule", v1 * 10f64.sqrt()),
                   ("try: bond doubled", var_quad(&[w[0], w[1], 2.0 * w[2]], &c, z99)),
                   ("try: calls sold, not bought", var_quad(&[w[0], -w[1], w[2]], &c, z99))] { rows.push((a.into(), x)); }
    for (name, v) in &rows {
        let p = if v.abs() < 100.0 { 6 } else { 2 };
        println!("{:<34}{:>16.*}", name, p, v);
    }
    for i in 0..3 {
        let cells: Vec<String> = (0..3).map(|j| format!("{:>14.9}", c[i][j])).collect();
        println!("covariance row {}  {}", i + 1, cells.join(" "));
    }
    let xs = [-0.5, -0.25, 0.0, 0.25, 0.5, 0.75];
    let head: Vec<String> = xs.iter().map(|x| format!("{:>7.2}", x)).collect();
    println!("chart, rho shares-Acme  {}", head.join(" "));
    let pts: Vec<String> = xs.iter().map(|&x| {
        let mut rh = rho;
        rh[0][1] = x; rh[1][0] = x;
        format!("{:>7.2}", var_quad(&w, &cov(&rh, &vol), z99) / 1000.0)
    }).collect();
    println!("chart, VaR in $000      {}", pts.join(" "));

    assert!((n_cdf(d1) - 0.598706325683).abs() < 1e-9, "own normal CDF vs the pilot's N(0.25)");
    assert!((call - 9.227005508154).abs() < 1e-9, "call price vs the house market");
    assert!((delta_fd - delta).abs() < 1e-6, "delta vs bumping the call's price");
    assert!((v2 - v1).abs() < 1e-6 * v1, "Cholesky road must equal the quadratic form");
    assert!((v3 - v1).abs() < 1e-6 * v1, "hand table road must equal the quadratic form");
    assert!((v4 - v1).abs() < 0.02 * v1, "simulated 1% tail within 2% of the formula");
    assert!((0..3).all(|i| (comp[i] - bump[i]).abs() < 1e-3 * v1), "components vs bumped marginals");
    assert!((bump.iter().sum::<f64>() - v1).abs() < 1e-4 * v1, "bumped pieces add back to the total (Euler)");
    println!("ALL CHECKS PASS");
}
