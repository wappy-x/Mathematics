// Novikov's condition -- the check behind the card.  Rust std only.
// Three tilts theta_t for Girsanov, time in years, W_t a Brownian motion under P:
//   A  constant 0.15: the share drifting 8% a year, priced at 5%, volatility 20%
//   B  theta_t = c W_t, c = 1 per year: the tilt grows with the wander
//   C  theta_t = -Z_t: the tilt grows with the weight itself, so dZ = Z^2 dW
// Roads: closed forms; exact Gaussian determinants and an exact lattice walk on
// shrinking grids; seeded simulation (SplitMix64 + Box-Muller) with standard errors.
use std::f64::consts::PI;

fn erf(x: f64) -> f64 { // Taylor series, accurate for |x| <= 3
    let (mut term, mut total, mut n) = (x, x, 0.0);
    while term.abs() > 1e-17 {
        n += 1.0;
        term *= -x * x / n;
        total += term / (2.0 * n + 1.0);
    }
    2.0 / PI.sqrt() * total
}

struct Rng { s: u64, spare: Option<f64> } // SplitMix64 uniforms, Box-Muller normals
impl Rng {
    fn u(&mut self) -> f64 {
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = (self.s ^ (self.s >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 * 2f64.powi(-53)
    }
    fn normal(&mut self) -> f64 {
        if let Some(g) = self.spare.take() { return g; }
        let r = (-2.0 * (1.0 - self.u()).ln()).sqrt();
        let a = 2.0 * PI * self.u();
        self.spare = Some(r * a.sin());
        r * a.cos()
    }
}

fn mean_se(xs: &[f64]) -> (f64, f64) {
    let (mut s1, mut s2) = (0.0, 0.0);
    for &x in xs { s1 += x; s2 += x * x; }
    let n = xs.len() as f64;
    let m = s1 / n;
    (m, ((s2 / n - m * m) / n).sqrt())
}

// E[exp(-a W_T^2 - b dt sum_{k=1..n} W_{k dt}^2)], dt = T/n, exactly: det(Tn + 2b dt^2 I + 2a dt e_n e_n)^(-1/2).
fn gauss(n: usize, t: f64, a: f64, b: f64) -> Option<f64> {
    let (dt, mut d0, mut d1) = (t / n as f64, 1.0, 1.0);
    for k in 1..=n {
        let dk = (if k < n { 2.0 } else { 1.0 + 2.0 * a * dt }) + 2.0 * b * dt * dt;
        let next = dk * d1 - if k > 1 { d0 } else { 0.0 };
        d0 = d1;
        d1 = next;
        if d1 <= 0.0 { return None; }
    }
    Some(1.0 / d1.sqrt())
}

fn fmt(v: Option<f64>) -> String { match v { None => "infinite".to_string(), Some(x) => format!("{:.6}", x) } }
fn row(xs: &[f64]) -> String { xs.iter().map(|v| format!("{:6.2}", v)).collect::<Vec<_>>().join(" ") }

fn main() {
    // ---- A: constant tilt, the shelf's share ----
    let (mu, r, sig, t) = (0.08, 0.05, 0.20, 1.0);
    let th: f64 = (mu - r) / sig;
    let mut rng = Rng { s: 20260930, spare: None };
    let zs: Vec<f64> = (0..100000).map(|_| { let g = rng.normal(); (-th * f64::sqrt(t) * g - 0.5 * th * th * t).exp() }).collect();
    let (ma, sa) = mean_se(&zs);
    println!("A theta {:.2}   theta^2 {:.4}   half theta^2 T {:.5}", th, th * th, 0.5 * th * th * t);
    println!("A Novikov E[exp(half int theta^2)] {:.6}   Q drift {:.2}", (0.5 * th * th * t).exp(), mu - sig * th);
    println!("A simulated E[Z_1], 100000 draws  {:.4}  se {:.4}", ma, sa);

    // ---- B: theta_t = c W_t ----
    let c: f64 = 1.0;
    let nov_b = |t: f64| -> Option<f64> { if c * t < PI / 2.0 { Some(1.0 / (c * t).cos().sqrt()) } else { None } };
    let ez_b = |t: f64| (0.5 * c * t).exp() / ((c * t).cosh() + (c * t).sinh()).sqrt(); // Cameron-Martin, a = c/2, b = c^2/2
    println!("B Novikov horizon pi/(2c) {:.6} years   cos(1) {:.6}", PI / (2.0 * c), 1f64.cos());
    println!("B grid n    Novikov T=1    error       E[Z_2] grid   error      Novikov T=2");
    for n in [25usize, 100, 400, 1600] {
        let nv = gauss(n, 1.0, 0.0, -0.5 * c * c).unwrap();
        let ez = c.exp() * gauss(n, 2.0, 0.5 * c, 0.5 * c * c).unwrap();
        println!("B {:6} {:12.6} {:+11.7} {:12.6} {:+11.7}   {}", n, nv, nv - nov_b(1.0).unwrap(), ez, ez - 1.0, fmt(gauss(n, 2.0, 0.0, -0.5 * c * c)));
    }
    println!("B formula Novikov T=1 {:.6}   T=1.5 {}   T=1.6 {}   T=2 {}", nov_b(1.0).unwrap(), fmt(nov_b(1.5)), fmt(nov_b(1.6)), fmt(nov_b(2.0)));
    let tstar = (1..=400).map(|k| k as f64 / 100.0).find(|&x| gauss(1600, x, 0.0, -0.5 * c * c).is_none()).unwrap();
    println!("B grid n 1600, T in steps of 0.01: Novikov first infinite at T = {:.2}   formula pi/(2c) {:.6}", tstar, PI / (2.0 * c));
    let (steps, t2) = (200usize, 2.0);
    let dt = t2 / steps as f64;
    let mut zs = Vec::new();
    for _ in 0..20000 {
        let (mut w, mut s) = (0.0, 0.0);
        for _ in 0..steps {
            w += dt.sqrt() * rng.normal();
            s += dt * w * w;
        }
        zs.push((0.5 * c * t2 - 0.5 * c * w * w - 0.5 * c * c * s).exp());
    }
    let (mb, sb) = mean_se(&zs);
    let grid_b = c.exp() * gauss(steps, t2, 0.5 * c, 0.5 * c * c).unwrap();
    println!("B simulated E[Z_2], 200 steps, 20000 paths {:.4}  se {:.4}   same grid exact {:.6}", mb, sb, grid_b);
    let tb = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5];
    println!("chart, B T          {}", row(&tb));
    println!("chart, B Novikov    {}", row(&tb.iter().map(|&x| nov_b(x).unwrap()).collect::<Vec<_>>()));
    println!("chart, B E[Z_T]     {}", row(&tb.iter().map(|&x| ez_b(x)).collect::<Vec<_>>()));

    // ---- C: dZ = Z^2 dW, the weight that feeds its own tilt ----
    let r0: f64 = 1.0; // start of R = 1/Z, so Z_0 = 1/R0; weights are Z/Z_0
    let surv_c = |t: f64| erf(r0 / (2.0 * t).sqrt()); // chance a Brownian motion from R0 stays above 0 to T
    let lattice = |h: f64, t: f64| -> f64 { // walk of +-h every h^2 years from R0, absorbed at 0
        let (k0, n) = ((r0 / h).round() as usize, (t / (h * h)).round() as usize);
        let mut p = vec![0.0; k0 + n + 2];
        p[k0] = 1.0;
        for _ in 0..n {
            let mut q = vec![0.0; p.len()];
            for j in 1..p.len() - 1 { q[j] = 0.5 * (p[j - 1] + p[j + 1]); }
            q[0] = 0.0;
            p = q;
        }
        let mut tot = 0.0;
        for v in &p[1..] { tot += v; }
        tot
    };
    println!("C deterministic part dy = y^3 dt from 1 blows up at t = {:.2} years", 0.5);
    let s1 = surv_c(1.0);
    println!("C formula E[Z_1] = 2 Phi(R0) - 1 = {:.6}   Phi(1) {:.6}   leak {:.6}", s1, 0.5 * (1.0 + erf(1.0 / 2f64.sqrt())), 1.0 - s1);
    let mut lat = Vec::new();
    for h in [0.1, 0.05, 0.025] {
        lat.push(lattice(h, 1.0));
        let l = *lat.last().unwrap();
        println!("C lattice h {:5.3}  survival {:.6}  error {:+.6}", h, l, l - s1);
    }
    let mut zs = Vec::new();
    for _ in 0..200000 { // Z_1/Z_0 = R0/|(R0,0,0) + 3-d Brownian motion at time 1|
        let (g1, g2, g3) = (rng.normal(), rng.normal(), rng.normal());
        zs.push(r0 / ((r0 + g1) * (r0 + g1) + g2 * g2 + g3 * g3).sqrt());
    }
    let (mc, sc) = mean_se(&zs);
    println!("C simulated E[Z_1] under P, 200000 paths {:.4}  se {:.4}", mc, sc);
    for cap in [10usize, 100, 1000] {
        let lost = 1.0 - erf((r0 - 1.0 / cap as f64) / 2f64.sqrt());
        println!("C cap {:5}: mass on capped paths {:.6}, their chance {:.6}", cap, lost, lost / (cap as f64 * r0));
    }
    let tc = [0.25, 0.5, 1.0, 2.0, 4.0, 8.0];
    println!("chart, C T          {}", row(&tc));
    println!("chart, C E[Z_T]     {}", row(&tc.iter().map(|&x| surv_c(x)).collect::<Vec<_>>()));
    println!("chart, A E[Z_T]     {}", row(&tc.iter().map(|&x| (-0.5 * th * th * x).exp() * (0.5 * th * th * x).exp()).collect::<Vec<_>>()));

    assert!((ma - 1.0).abs() < 4.0 * sa, "A: constant tilt, weights average 1");
    assert!((gauss(1600, 1.0, 0.0, -0.5 * c * c).unwrap() - nov_b(1.0).unwrap()).abs() < 1e-3, "B: grid determinant vs 1/sqrt(cos cT)");
    assert!(gauss(1600, 2.0, 0.0, -0.5 * c * c).is_none() == nov_b(2.0).is_none(), "B: both roads agree on Novikov at T = 2");
    assert!((tstar - PI / (2.0 * c)).abs() < 0.01, "B: the grid road blows up within a step of pi/(2c)");
    assert!((c.exp() * gauss(1600, 2.0, 0.5 * c, 0.5 * c * c).unwrap() - 1.0).abs() < 1e-3, "B: E[Z_2] = 1 though Novikov fails");
    assert!((mb - grid_b).abs() < 4.0 * sb, "B: simulation vs same-grid exact");
    assert!((lat[2] - s1).abs() < 0.01 && (lat[2] - s1).abs() < (lat[0] - s1).abs(), "C: lattice -> formula");
    assert!((mc - s1).abs() < 4.0 * sc, "C: P-side simulation vs Q-side reflection formula");
    assert!(1.0 - mc > 20.0 * sc, "C: the leak is real");
    println!("ALL CHECKS PASS");
}
