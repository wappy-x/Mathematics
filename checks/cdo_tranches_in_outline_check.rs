// Tranches in outline -- the check behind the card.  Rust std only, no crates.
// House pool: 100 loans, 5% five-year default chance, recovery 40%, correlation 20%.
// The normal CDF, its inverse, the integrator and the random numbers are written here.
use std::f64::consts::PI;

const P5: f64 = 0.05; const R: f64 = 0.40; const RHO: f64 = 0.20;
const NAMES: usize = 100; const LGD: f64 = 1.0 - R;
const TR: [(&str, f64, f64); 4] = [("equity 0-3%", 0.00, 0.03), ("junior mezz 3-7%", 0.03, 0.07),
    ("senior mezz 7-10%", 0.07, 0.10), ("senior 10-100%", 0.10, 1.00)];

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }
fn n_cdf(x: f64) -> f64 {                     // bell-curve area, by series
    if x < -8.0 { return 0.0; }
    if x > 8.0 { return 1.0; }
    let (mut term, mut total, mut k) = (x, x, 0.0);
    while term.abs() > 1e-17 * total.abs() + 1e-300 {
        k += 1.0;
        term *= x * x / (2.0 * k + 1.0);
        total += term;
    }
    0.5 + phi(x) * total
}
fn n_inv(u: f64) -> f64 {                     // its inverse, by bisection
    let (mut lo, mut hi) = (-9.0, 9.0);
    for _ in 0..80 {
        let mid = 0.5 * (lo + hi);
        if n_cdf(mid) < u { lo = mid; } else { hi = mid; }
    }
    0.5 * (lo + hi)
}
fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    s * h / 3.0
}
fn cut(l: f64, a: f64, d: f64) -> f64 { (l - a).max(0.0).min(d - a) / (d - a) }
fn etl_factor(p: f64, rho: f64, a: f64, d: f64, n: usize, lgd: f64) -> f64 {   // road 1
    let c = n_inv(p);
    simpson(|m| {
        let q = if rho == 0.0 { p } else { n_cdf((c - rho.sqrt() * m) / (1.0 - rho).sqrt()) };
        cut(lgd * q, a, d) * phi(m)
    }, -8.0, 8.0, n)
}
fn etl_losscurve(p: f64, rho: f64, a: f64, d: f64) -> f64 {                     // road 2
    let (c, top) = (n_inv(p), d.min(LGD));
    let surv = |x: f64| {
        if x <= 0.0 { return 1.0; }
        if x >= LGD { return 0.0; }
        1.0 - n_cdf(((1.0 - rho).sqrt() * n_inv(x / LGD) - c) / rho.sqrt())
    };
    if top > a { simpson(surv, a, top, 20000) / (d - a) } else { 0.0 }
}
fn etl_recursion(p: f64, rho: f64, n: usize) -> Vec<f64> {                      // road 3
    let c = n_inv(p);
    let (h, mut out) = (16.0 / n as f64, vec![0.0; TR.len()]);
    for i in 0..=n {
        let m = -8.0 + i as f64 * h;
        let wt = if i == 0 || i == n { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 };
        let w = wt * h / 3.0 * phi(m);
        let q = n_cdf((c - rho.sqrt() * m) / (1.0 - rho).sqrt());
        let mut dist = vec![0.0; NAMES + 1];
        dist[0] = 1.0;
        for j in 0..NAMES {                   // add one name at a time
            for k in (1..=j + 1).rev() { dist[k] = dist[k] * (1.0 - q) + dist[k - 1] * q; }
            dist[0] *= 1.0 - q;
        }
        for (t, &(_, a, d)) in TR.iter().enumerate() {
            let s: f64 = dist.iter().enumerate()
                .map(|(k, dk)| dk * cut(k as f64 * LGD / NAMES as f64, a, d)).sum();
            out[t] += w * s;
        }
    }
    out
}
struct Lcg(u64);                              // road 4: Monte Carlo, own generator
impl Lcg {
    fn unif(&mut self) -> f64 {
        self.0 = self.0.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
        ((self.0 >> 11) as f64 + 0.5) / (1u64 << 53) as f64
    }
}
fn etl_montecarlo(p: f64, rho: f64, runs: usize, g: &mut Lcg) -> Vec<f64> {
    let (c, mut tot) = (n_inv(p), vec![0.0; TR.len()]);
    for _ in 0..runs {
        let q = n_cdf((c - rho.sqrt() * n_inv(g.unif())) / (1.0 - rho).sqrt());
        let hits = (0..NAMES).filter(|_| g.unif() < q).count();
        let l = hits as f64 * LGD / NAMES as f64;
        for (i, &(_, a, d)) in TR.iter().enumerate() { tot[i] += cut(l, a, d); }
    }
    tot.iter().map(|t| t / runs as f64).collect()
}

fn main() {
    println!("pool: {} names, 5y default chance {}, recovery {}, correlation {}", NAMES, P5, R, RHO);
    println!("threshold c = Ninv(0.05) {:.6}   sqrt(rho) {:.6}   sqrt(1-rho) {:.6}", n_inv(P5), RHO.sqrt(), (1.0 - RHO).sqrt());
    println!("pool expected loss (1-R) p               {:.6}", LGD * P5);
    let r1: Vec<f64> = TR.iter().map(|&(_, a, d)| etl_factor(P5, RHO, a, d, 2000, LGD)).collect();
    let r2: Vec<f64> = TR.iter().map(|&(_, a, d)| etl_losscurve(P5, RHO, a, d)).collect();
    let r3 = etl_recursion(P5, RHO, 400);
    let r4 = etl_montecarlo(P5, RHO, 20000, &mut Lcg(20260928));
    println!("expected tranche loss, % of width      factor losscurve  100-name montecarlo");
    for (i, &(nm, _, _)) in TR.iter().enumerate() {
        println!("  {:<19} {:9.4} {:9.4} {:9.4} {:9.4}", nm, 100.0 * r1[i], 100.0 * r2[i], 100.0 * r3[i], 100.0 * r4[i]);
    }
    println!("economy m        z  default chance  pool loss %  equity %  jr mezz %  senior %");
    for m in [-2.0, -1.0, 0.0, 1.0, 2.0] {
        let z = (n_inv(P5) - RHO.sqrt() * m) / (1.0 - RHO).sqrt(); let q = n_cdf(z);
        let cells: String = TR.iter().filter(|t| t.1 != 0.07)
            .map(|&(_, a, d)| format!("{:10.4}", 100.0 * cut(LGD * q, a, d))).collect();
        println!("  {:5.1} {:9.4} {:14.6} {:12.4}{}", m, z, q, 100.0 * LGD * q, cells);
    }
    let pool_back: f64 = TR.iter().enumerate().map(|(i, &(_, a, d))| r1[i] * (d - a)).sum();
    println!("sum of width x tranche loss              {:.6}", pool_back);
    println!("correlation sweep, % of width    equity   jr mezz   sr mezz    senior");
    let mut sweep: Vec<Vec<f64>> = Vec::new();
    for rho in [0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8] {
        let row: Vec<f64> = TR.iter().map(|&(_, a, d)| etl_factor(P5, rho, a, d, 2000, LGD)).collect();
        let cells: Vec<String> = row.iter().map(|v| format!("{:8.2}", 100.0 * v)).collect();
        println!("  rho {:.1}  {}", rho, cells.join("  "));
        sweep.push(row);
    }
    let xs: Vec<String> = (0..13).map(|x| format!("{:6}", x)).collect();
    println!("payoff chart: pool loss %{}", xs.join(" "));
    for &(nm, a, d) in TR.iter() {
        let v: Vec<String> = (0..13).map(|x| format!("{:6.2}", 100.0 * cut(x as f64 / 100.0, a, d))).collect();
        println!("  {:<22}{}", nm, v.join(" "));
    }

    let (lam, r, dt) = (-(1.0 - P5).ln() / 5.0, 0.05, 0.25);
    println!("hazard rate lambda = -ln(0.95)/5          {:.6}", lam);
    println!("tranche legs, quarterly, 5 years       protection  annuity  par spread bp");
    let (mut prot_sum, mut ann_sum, mut legs) = (0.0, 0.0, Vec::new());
    for &(nm, a, d) in TR.iter() {
        let (mut prev, mut prot, mut ann) = (0.0, 0.0, 0.0);
        for i in 1..=20 {
            let t = i as f64 * dt;
            let e = etl_factor(1.0 - (-lam * t).exp(), RHO, a, d, 400, LGD);
            prot += (-r * t).exp() * (e - prev);
            ann += dt * (-r * t).exp() * (1.0 - 0.5 * (prev + e));
            prev = e;
        }
        legs.push((prot, ann));
        prot_sum += prot * (d - a); ann_sum += ann * (d - a);
        println!("  {:<19} {:12.6} {:9.6} {:12.1}", nm, prot, ann, 1e4 * prot / ann);
    }
    let pool_el = |t: f64| LGD * (1.0 - (-lam * t).exp());   // pool's own expected loss, no copula
    let idx_prot: f64 = (1..=20).map(|i| (-r * i as f64 * dt).exp() * (pool_el(i as f64 * dt) - pool_el((i - 1) as f64 * dt))).sum();
    let idx_ann: f64 = (1..=20).map(|i| dt * (-r * i as f64 * dt).exp() * (1.0 - 0.5 * (pool_el((i - 1) as f64 * dt) + pool_el(i as f64 * dt)))).sum();
    println!("pool protection: tranches {:.6}   pool alone {:.6}", prot_sum, idx_prot);
    println!("pool annuity:    tranches {:.6}   pool alone {:.6}", ann_sum, idx_ann);
    println!("equity upfront % with 500 bp running      {:.4}", 100.0 * (legs[0].0 - 0.05 * legs[0].1));

    println!("what breaks, % of width                equity    senior");
    println!("  tranche of the average pool loss    {:9.4} {:9.4}", 100.0 * cut(LGD * P5, 0.0, 0.03), 100.0 * cut(LGD * P5, 0.1, 1.0));
    println!("  forgot recovery, lose 100%          {:9.4} {:9.4}",
        100.0 * etl_factor(P5, RHO, 0.0, 0.03, 2000, 1.0), 100.0 * etl_factor(P5, RHO, 0.1, 1.0, 2000, 1.0));
    println!("  divided by pool, not by width       {:9.4} {:9.4}", 100.0 * r1[0] * 0.03, 100.0 * r1[3] * 0.90);
    println!("  default corr 0.058 for asset 0.20   {:9.4} {:9.4}",
        100.0 * etl_factor(P5, 0.058, 0.0, 0.03, 2000, LGD), 100.0 * etl_factor(P5, 0.058, 0.1, 1.0, 2000, LGD));

    assert!(r1.iter().zip(&r2).all(|(a, b)| (a - b).abs() < 2e-5), "factor road vs loss-curve road");
    assert!((pool_back - LGD * P5).abs() < 1e-6, "tranches add back to the pool loss");
    assert!(r3.iter().zip(&r4).all(|(a, b)| (a - b).abs() < 0.01), "recursion vs Monte Carlo");
    assert!((prot_sum - idx_prot).abs() < 1e-6, "tranche legs add to the pool leg");
    assert!((ann_sum - idx_ann).abs() < 1e-6, "tranche annuities add to the pool annuity");
    assert!((0..8).all(|i| sweep[i + 1][0] < sweep[i][0] && sweep[i + 1][3] > sweep[i][3]),
        "equity falls and senior rises as correlation climbs");
    println!("ALL CHECKS PASS");
}
