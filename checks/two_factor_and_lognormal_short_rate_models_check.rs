// Beyond one factor: Hull-White against G2++, a Black-Derman-Toy tree, and negative rates. std only.
use std::f64::consts::PI;

const KV: f64 = 0.3; const TH: f64 = 0.05; const SV: f64 = 0.01; const R0: f64 = 0.04; // house curve
const A: f64 = 1.0; const B: f64 = 0.08; const SIG: f64 = 0.012; const ETA: f64 = 0.007; const RHO: f64 = -0.2; // G2++

fn load(c: f64, u: f64) -> f64 { (1.0 - (-c * u).exp()) / c }
fn simpson(f: &dyn Fn(f64) -> f64, lo: f64, hi: f64) -> f64 {
    let n = 2000; let h = (hi - lo) / n as f64;
    let s: f64 = (1..n).map(|k| (if k % 2 == 1 { 4.0 } else { 2.0 }) * f(lo + k as f64 * h)).sum();
    (f(lo) + f(hi) + s) * h / 3.0
}
fn p0(t: f64) -> f64 {
    let b = load(KV, t);
    ((TH - SV * SV / (2.0 * KV * KV)) * (b - t) - SV * SV * b * b / (4.0 * KV) - b * R0).exp()
}
fn cov(p: (f64, f64), q: (f64, f64), rho: f64) -> f64 { p.0 * q.0 + p.1 * q.1 + rho * (p.0 * q.1 + p.1 * q.0) }
fn corr(p: (f64, f64), q: (f64, f64), rho: f64) -> f64 { cov(p, q, rho) / (cov(p, p, rho) * cov(q, q, rho)).sqrt() }
fn yload(u: f64, a: f64, b: f64, s: f64, e: f64) -> (f64, f64) { (s * load(a, u) / u, e * load(b, u) / u) }
fn yl(u: f64) -> (f64, f64) { yload(u, A, B, SIG, ETA) }
fn swap(n: usize, x: f64, y: f64) -> f64 {
    let p: Vec<f64> = (1..=n + 1).map(|t| { let t = t as f64; p0(t) * (-load(A, t) * x - load(B, t) * y).exp() }).collect();
    (p[0] - p[n]) / p[1..].iter().sum::<f64>()
}
fn swap_grad(n: usize, c: f64) -> f64 {
    let p: Vec<f64> = (1..=n + 1).map(|t| p0(t as f64)).collect();
    let ann: f64 = p[1..].iter().sum();
    let mut num = (-load(c, 1.0) * p[0] + load(c, 1.0 + n as f64) * p[n]) * ann;
    num += (p[0] - p[n]) * (1..=n).map(|j| load(c, 1.0 + j as f64) * p[j]).sum::<f64>();
    num / ann.powi(2)
}
struct Rng { s: u64 }
impl Rng {
    fn uni(&mut self) -> f64 { self.s ^= self.s << 13; self.s ^= self.s >> 7; self.s ^= self.s << 17; ((self.s >> 11) as f64 + 0.5) / 2f64.powi(53) }
    fn normal(&mut self) -> f64 { let u = self.uni(); let v = self.uni(); (-2.0 * u.ln()).sqrt() * (2.0 * PI * v).cos() }
}
fn show(label: &str, v: f64, d: usize) { println!("{:<40} {:>12.*}", label, d, v); }
fn join(v: &[f64], d: usize, w: usize) -> String { v.iter().map(|x| format!("{:>w$.d$}", x, w = w, d = d)).collect::<Vec<_>>().join(" ") }

fn main() {
    let mats: Vec<f64> = (1..=10).map(|u| u as f64).collect();
    // 1. one factor: a 2-year move fixes every other move
    let dr = 0.0010 / (load(KV, 2.0) / 2.0);
    let hw_move: Vec<f64> = mats.iter().map(|&u| dr * load(KV, u) / u * 1e4).collect();
    // 2. two factors: solve for the shocks that put 2y up 10bp and 10y down 5bp
    let (p2, q2, p10, q10) = (load(A, 2.0) / 2.0, load(B, 2.0) / 2.0, load(A, 10.0) / 10.0, load(B, 10.0) / 10.0);
    let det = p2 * q10 - q2 * p10;
    let x = (0.0010 * q10 - q2 * -0.0005) / det;
    let y = (p2 * -0.0005 - p10 * 0.0010) / det;
    let g2_move: Vec<f64> = mats.iter().map(|&u| (load(A, u) * x + load(B, u) * y) / u * 1e4).collect();
    // 3. correlations of yields and of swap rates
    let c_2_10 = corr(yl(2.0), yl(10.0), RHO);
    let cross = load(A, 2.0) * load(B, 10.0) - load(A, 10.0) * load(B, 2.0);
    let det_cov = cov(yl(2.0), yl(2.0), RHO) * cov(yl(10.0), yl(10.0), RHO) - cov(yl(2.0), yl(10.0), RHO).powi(2);
    let det_id = (SIG * ETA / 20.0).powi(2) * (1.0 - RHO.powi(2)) * cross.powi(2);
    let g = |n: usize| (SIG * swap_grad(n, A), ETA * swap_grad(n, B));
    let swap_corr = corr(g(2), g(9), RHO);
    let h = 1e-6;
    let fd2 = (swap(2, h, 0.0) - swap(2, -h, 0.0)) / (2.0 * h);
    let hw_swap = corr((swap_grad(2, KV), 0.0), (swap_grad(9, KV), 0.0), RHO);
    let mut zs = Rng { s: 20260928 }; let dt: f64 = 1.0 / 252.0;
    let (s2, s9) = (swap(2, 0.0, 0.0), swap(9, 0.0, 0.0));
    let (mut d2, mut d9) = (Vec::new(), Vec::new());
    for _ in 0..100000 { // one trading day of shocks, fully repriced
        let z1 = zs.normal(); let z2 = zs.normal();
        let xx = SIG * dt.sqrt() * z1; let yy = ETA * dt.sqrt() * (RHO * z1 + (1.0 - RHO * RHO).sqrt() * z2);
        d2.push(swap(2, xx, yy) - s2); d9.push(swap(9, xx, yy) - s9);
    }
    let m2 = d2.iter().sum::<f64>() / d2.len() as f64; let m9 = d9.iter().sum::<f64>() / d9.len() as f64;
    let sxy: f64 = d2.iter().zip(&d9).map(|(u, v)| (u - m2) * (v - m9)).sum();
    let mc_corr = sxy / (d2.iter().map(|u| (u - m2).powi(2)).sum::<f64>() * d9.iter().map(|v| (v - m9).powi(2)).sum::<f64>()).sqrt();
    // 4. a Black-Derman-Toy tree, 4 annual steps, 20% log-volatility, fitted to the house curve
    let (sb, nn) = (0.20, 4usize);
    let (mut uu, mut q, mut rates): (Vec<f64>, Vec<f64>, Vec<Vec<f64>>) = (vec![], vec![1.0], vec![]);
    for i in 0..nn {
        let node = |u: f64, j: usize| u * (sb * (2.0 * j as f64 - i as f64)).exp();
        let price = |u: f64| (0..=i).map(|j| q[j] / (1.0 + node(u, j))).sum::<f64>();
        let (mut lo, mut hi) = (1e-6, 1.0);
        for _ in 0..200 { // bisection: price falls as the median rate rises
            let mid = 0.5 * (lo + hi);
            if price(mid) > p0(i as f64 + 1.0) { lo = mid } else { hi = mid }
        }
        uu.push(0.5 * (lo + hi)); let r: Vec<f64> = (0..=i).map(|j| node(uu[i], j)).collect();
        q = (0..=i + 1).map(|j| 0.5 * ((if j > 0 { q[j - 1] / (1.0 + r[j - 1]) } else { 0.0 }) + (if j <= i { q[j] / (1.0 + r[j]) } else { 0.0 }))).collect();
        rates.push(r);
    }
    let backward = |t: usize| -> Vec<Vec<f64>> { // roll a bond paying 1 at year t back through the tree
        let mut v = vec![1.0; t + 1]; let mut layers = vec![vec![]; t];
        for i in (0..t).rev() { v = (0..=i).map(|j| 0.5 * (v[j] + v[j + 1]) / (1.0 + rates[i][j])).collect(); layers[i] = v.clone(); }
        layers
    };
    let bdt_back: Vec<f64> = (1..=nn).map(|t| backward(t)[0][0]).collect();
    let at1: Vec<Vec<f64>> = (0..=4).map(|t| if t >= 2 { backward(t)[1].clone() } else { vec![] }).collect();
    let sw: Vec<Vec<f64>> = [2usize, 3].iter().map(|&n| (0..2).map(|j| (1.0 - at1[1 + n][j]) / (2..2 + n).map(|t| at1[t][j]).sum::<f64>()).collect()).collect();
    // 5. negative rates: Hull-White in a 1% world after 10 years
    let (a1, s1, r1, t1): (f64, f64, f64, f64) = (0.3, 0.01, 0.01, 10.0);
    let sd = (s1 * s1 * (1.0 - (-2.0 * a1 * t1).exp()) / (2.0 * a1)).sqrt();
    let p_neg = 0.5 - simpson(&|z: f64| (-z * z / 2.0).exp() / (2.0 * PI).sqrt(), 0.0, r1 / sd);
    let (mut zs2, mut neg, fade) = (Rng { s: 7 }, 0u32, (-a1).exp());
    for _ in 0..100000 { // ten exact one-year steps of the short rate
        let mut r = r1;
        for _ in 0..10 { r = r1 + (r - r1) * fade + s1 * ((1.0 - fade * fade) / (2.0 * a1)).sqrt() * zs2.normal(); }
        if r < 0.0 { neg += 1 }
    }
    println!("house curve: zero prices P0(T)");
    println!("  {}", [1.0, 2.0, 3.0, 4.0, 10.0].iter().map(|&t| format!("{:.6}", p0(t))).collect::<Vec<_>>().join(" "));
    println!("HW yield loadings B(u)/u, 2y and 10y     {:.6} {:.6}", load(KV, 2.0) / 2.0, load(KV, 10.0) / 10.0);
    println!("G2 loadings 2y fast/slow, 10y fast/slow {:.6} {:.6} {:.6} {:.6}  det {:.6}", p2, q2, p10, q10, det);
    show("HW: short-rate shock for 2y +10bp, bp", dr * 1e4, 4); show("G2++: fast factor shock x, bp", x * 1e4, 4); show("G2++: slow factor shock y, bp", y * 1e4, 4);
    println!("G2++ yield vols 2y, 10y, bp a year       {:.2} {:.2}", 1e4 * cov(yl(2.0), yl(2.0), RHO).sqrt(), 1e4 * cov(yl(10.0), yl(10.0), RHO).sqrt());
    println!("maturity {}", mats.iter().map(|u| format!("{:>6}", *u as i32)).collect::<Vec<_>>().join(" "));
    println!("HW move  {}", join(&hw_move, 2, 6));
    println!("G2 move  {}", join(&g2_move, 2, 6));
    println!("G2 corr% {}", join(&mats.iter().map(|&u| 100.0 * corr(yl(2.0), yl(u), RHO)).collect::<Vec<_>>(), 2, 6));
    show("B_1(2)", load(A, 2.0), 6); show("B_1(2) by Simpson", simpson(&|s: f64| (-A * s).exp(), 0.0, 2.0), 6);
    show("B_0.08(10)", load(B, 10.0), 6); show("B_0.08(10) by Simpson", simpson(&|s: f64| (-B * s).exp(), 0.0, 10.0), 6);
    show("yield corr 2y,10y: G2++", c_2_10, 6); show("yield corr 2y,10y: HW", corr(yload(2.0, KV, KV, SV, 0.0), yload(10.0, KV, KV, SV, 0.0), RHO), 6);
    println!("{:<40} {:>12.4e}", "covariance determinant, direct", det_cov); println!("{:<40} {:>12.4e}", "covariance determinant, identity", det_id);
    show("swap 1y-into-2y par rate", s2, 6); show("swap 1y-into-9y par rate", s9, 6);
    show("dS2/dx analytic", swap_grad(2, A), 6); show("dS2/dx bumped", fd2, 6);
    show("swap corr 1y2y,1y9y: G2++ formula", swap_corr, 6); show("swap corr: G2++ Monte Carlo, 100000 days", mc_corr, 3);
    show("swap corr: HW", hw_swap, 6);
    show("wrong: rho = -1, yield corr", corr(yl(2.0), yl(10.0), -1.0), 6);
    show("wrong: a = b = 0.08, yield corr", corr(yload(2.0, B, B, SIG, ETA), yload(10.0, B, B, SIG, ETA), RHO), 6);
    show("wrong: rho set to 0, yield corr", corr(yl(2.0), yl(10.0), 0.0), 6);
    show("try: rho = +0.5, yield corr", corr(yl(2.0), yl(10.0), 0.5), 6); show("try: rho = -0.8, yield corr", corr(yl(2.0), yl(10.0), -0.8), 6);
    show("try: rho = +0.5, swap corr", corr(g(2), g(9), 0.5), 6); show("try: b = 0.3, yield corr", corr(yload(2.0, A, 0.3, SIG, ETA), yload(10.0, A, 0.3, SIG, ETA), RHO), 6);
    for (i, r) in rates.iter().enumerate() {
        println!("BDT year {} node rates, %  {}", i, join(&r.iter().map(|v| 100.0 * v).collect::<Vec<_>>(), 4, 7));
    }
    println!("BDT zero prices, tree  {}", bdt_back.iter().map(|v| format!("{:.6}", v)).collect::<Vec<_>>().join(" "));
    println!("BDT year-1 swap to 3, down/up, %  {:.4} {:.4}", 100.0 * sw[0][0], 100.0 * sw[0][1]);
    println!("BDT year-1 swap to 4, down/up, %  {:.4} {:.4}", 100.0 * sw[1][0], 100.0 * sw[1][1]);
    show("HW 1% world: P(r < 0 at 10y), formula", p_neg, 4); show("HW 1% world: P(r < 0), Monte Carlo", neg as f64 / 100000.0, 4);

    assert!((g2_move[1] - 10.0).abs() < 1e-9, "the solved shocks put the 2-year up 10bp");
    assert!((g2_move[9] + 5.0).abs() < 1e-9, "and the 10-year down 5bp");
    assert!(hw_move.iter().cloned().fold(f64::INFINITY, f64::min) > 0.0, "one factor cannot move any yield against the 2-year");
    assert!((load(A, 2.0) - simpson(&|s: f64| (-A * s).exp(), 0.0, 2.0)).abs() < 1e-10, "loading: closed form against quadrature");
    assert!((det_cov - det_id).abs() < 1e-22, "covariance determinant against its identity");
    assert!((fd2 - swap_grad(2, A)).abs() < 1e-6, "swap gradient: quotient rule against bump");
    assert!((mc_corr - swap_corr).abs() < 0.003, "swap correlation: formula against simulation");
    assert!((uu[0] - (1.0 / p0(1.0) - 1.0)).abs() < 1e-12, "first BDT rate is the one-year rate");
    assert!((0..nn).all(|t| (bdt_back[t] - p0(t as f64 + 1.0)).abs() < 1e-12), "tree prices every zero back");
    assert!((neg as f64 / 100000.0 - p_neg).abs() < 0.003, "negative-rate chance: formula against simulation");
    println!("ALL CHECKS PASS");
}
