// Stochastic control and the HJB equation -- the check behind the card.  Rust std only.
// How much of a $200,000 fortune to keep in shares over 5 years.  Four roads to the best fraction:
// the HJB formula, the HJB equation tested by finite differences, discrete Bellman steps that
// shrink, and a seeded Monte Carlo.  The generator, normals and searches are written out here.
use std::f64::consts::PI;

const X0: f64 = 200000.0;
const T: f64 = 5.0;
const R: f64 = 0.03;
const MU: f64 = 0.08;
const SIG: f64 = 0.25;
const GAM: f64 = 2.0;

fn g(p: f64, gam: f64) -> f64 { R + p * (MU - R) - 0.5 * gam * SIG * SIG * p * p }
fn u(x: f64) -> f64 { x.powf(1.0 - GAM) / (1.0 - GAM) }
fn p_star() -> f64 { (MU - R) / (GAM * SIG * SIG) }
fn v(t: f64, x: f64) -> f64 { u(x) * ((1.0 - GAM) * g(p_star(), GAM) * (T - t)).exp() }

// HJB residual by finite differences, divided by |V_t|; ito = false drops the second-derivative term
fn bracket(t: f64, x: f64, p: f64, ito: bool) -> f64 {
    let (e, k) = (1e-4, x * 1e-4);
    let vt = (v(t + e, x) - v(t - e, x)) / (2.0 * e);
    let vx = (v(t, x + k) - v(t, x - k)) / (2.0 * k);
    let vxx = (v(t, x + k) - 2.0 * v(t, x) + v(t, x - k)) / (k * k);
    let b = x * (R + p * (MU - R)) * vx + if ito { 0.5 * x * x * p * p * SIG * SIG * vxx } else { 0.0 };
    (vt + b) / vt.abs()
}

// Bellman's rule on one step of h years, exact two-point shares, bisection on the slope
fn bellman(h: f64) -> (f64, f64) {
    let up = ((MU - 0.5 * SIG * SIG) * h + SIG * h.sqrt()).exp();
    let dn = ((MU - 0.5 * SIG * SIG) * h - SIG * h.sqrt()).exp();
    let b = (R * h).exp();
    let score = |p: f64| 0.5 * (u(b + p * (up - b)) + u(b + p * (dn - b)));
    let slope = |p: f64| 0.5 * ((up - b) * (b + p * (up - b)).powf(-GAM) + (dn - b) * (b + p * (dn - b)).powf(-GAM));
    let (mut lo, mut hi) = (0.0f64, 1.0f64);
    for _ in 0..100 {
        let m = 0.5 * (lo + hi);
        if slope(m) > 0.0 { lo = m; } else { hi = m; }
    }
    let p = 0.5 * (lo + hi);
    let m = score(p) * (1.0 - GAM);
    (p, m.ln() / ((1.0 - GAM) * h))
}

struct Rng { s: u64 }
impl Rng {
    fn unif(&mut self) -> f64 {
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^= z >> 31;
        ((z >> 11) as f64 + 0.5) / 9007199254740992.0
    }
    fn normal(&mut self) -> f64 {
        let (u1, u2) = (self.unif(), self.unif());
        (-2.0 * u1.ln()).sqrt() * (2.0 * PI * u2).cos()
    }
}

fn ce_and_se(ys: &[f64]) -> (f64, f64) {
    let n = ys.len() as f64;
    let m = ys.iter().sum::<f64>() / n;
    let sd = (ys.iter().map(|y| (y - m) * (y - m)).sum::<f64>() / (n - 1.0)).sqrt();
    let ce = m.powf(1.0 / (1.0 - GAM));
    (ce, ce * sd / n.sqrt() / ((1.0 - GAM).abs() * m))
}

fn run_rule(rng: &mut Rng, rule: &dyn Fn(f64) -> f64, n: usize, months: usize, rec: bool) -> (Vec<f64>, Vec<f64>) {
    let hm = 1.0 / 12.0;
    let (mut out, mut path) = (Vec::new(), Vec::new());
    for _ in 0..n {
        let mut x = X0;
        for k in 0..months {
            if rec && k % 6 == 0 { path.push(x); }
            let p = rule(x);
            x *= ((R + p * (MU - R) - 0.5 * p * p * SIG * SIG) * hm + p * SIG * hm.sqrt() * rng.normal()).exp();
        }
        out.push(x.powf(1.0 - GAM));
        if rec { path.push(x); }
    }
    (out, path)
}

fn row(v: &[f64], f: &dyn Fn(f64) -> String) -> String { v.iter().map(|&x| f(x)).collect::<Vec<_>>().join(" ") }

fn main() {
    let ps = p_star();
    let gs = g(ps, GAM);
    let ce_star = X0 * (gs * T).exp();
    println!("setting: fortune {:.0}, {:.0} years, bank {}, shares drift {}, volatility {}, risk aversion {:.0}", X0, T, R, MU, SIG, GAM);
    println!("road 1 formula: excess {:.6}, variance {:.6}, risk aversion x variance {:.6}", MU - R, SIG * SIG, GAM * SIG * SIG);
    println!("road 1 formula: best fraction            {:.6}", ps);
    println!("road 1 formula: dollars in shares now    {:.2}", ps * X0);
    println!("road 1 formula: CE growth per year       {:.6}", gs);
    println!("road 1 formula: CE fortune at 5 years    {:.2}", ce_star);

    let (mut scan_best, mut scan_res) = (0.0, 1.0);
    for &(t, x) in &[(0.0, X0), (2.5, 100000.0)] {
        let mut best = 0usize;
        for i in 0..=2000usize { if bracket(t, x, i as f64 / 1000.0, true) > bracket(t, x, best as f64 / 1000.0, true) { best = i; } }
        let (bp, res) = (best as f64 / 1000.0, bracket(t, x, best as f64 / 1000.0, true));
        println!("road 2 HJB test at t={:.1}, x={:.0}: best fraction {:.4}, residual {:.6}", t, x, bp, res);
        if t == 0.0 { scan_best = bp; scan_res = res; }
    }

    println!("road 3 Bellman steps: step in years, best fraction, its error, CE growth per year");
    let mut steps = Vec::new();
    for &(name, h) in &[("1", 1.0), ("1/2", 0.5), ("1/4", 0.25), ("1/12", 1.0 / 12.0), ("1/52", 1.0 / 52.0), ("1/252", 1.0 / 252.0)] {
        let (p, gh) = bellman(h);
        steps.push((p, gh));
        println!("  {:>6} {:.6} {:+.6} {:.6}", name, p, p - ps, gh);
    }

    let mut rng = Rng { s: 2026 };
    let n = 100000usize;
    let zs: Vec<f64> = (0..n).map(|_| rng.normal()).collect();
    println!("road 4 Monte Carlo, fixed fractions, {} paths, seed 2026: fraction, CE fortune, SE, exact", n);
    let mut mc = Vec::new();
    for &p in &[0.2f64, 0.4, 0.8] {
        let drift = (R + p * (MU - R) - 0.5 * p * p * SIG * SIG) * T;
        let ys: Vec<f64> = zs.iter().map(|z| (X0 * (drift + p * SIG * T.sqrt() * z).exp()).powf(1.0 - GAM)).collect();
        let (ce, se) = ce_and_se(&ys);
        mc.push((ce, se));
        println!("  {:.1} {:10.2} {:7.2} {:10.2}", p, ce, se, X0 * (g(p, GAM) * T).exp());
    }
    println!("road 4 fraction 0.4: simulated minus exact, in standard errors {:.2}", (mc[1].0 - ce_star) / mc[1].1);
    let (ce_fb, se_fb) = ce_and_se(&run_rule(&mut rng, &|x| if x < X0 { 0.6 } else { 0.2 }, 20000, 60, false).0);
    println!("road 4 feedback rule, 0.6 below 200000 and 0.2 above, monthly, 20000 paths: CE {:.2}, SE {:.2}", ce_fb, se_fb);
    println!("road 4 feedback rule: shortfall from the best, in standard errors {:.1}", (ce_star - ce_fb) / se_fb);

    let fr = [0.0, 0.2, 0.4, 0.6, 0.8, 1.0, 1.2];
    println!("hill, fraction in shares:     {}", row(&fr, &|p| format!("{:5.1}", p)));
    println!("hill, CE growth, % per year:  {}", row(&fr, &|p| format!("{:5.2}", 100.0 * g(p, GAM))));
    let q = [0.4, 1.0, 10.0, 100.0];
    println!("wrong: ordinary chain rule, residual at fraction 0.4, 1, 10, 100: {}", row(&q, &|p| format!("{:.4}", bracket(0.0, X0, p, false))));
    println!("right: Ito chain rule,     residual at fraction 0.4, 1, 10, 100: {}", row(&q, &|p| format!("{:.4}", bracket(0.0, X0, p, true))));
    let p_s = (MU - R) / (GAM * SIG);
    println!("wrong: sigma for sigma^2: fraction {:.4}, CE fortune {:.2}", p_s, X0 * (g(p_s, GAM) * T).exp());
    let p_1 = (MU - R) / (1.0 * SIG * SIG);
    println!("wrong: risk aversion 1 for 2: fraction {:.4}, CE fortune {:.2}", p_1, X0 * (g(p_1, GAM) * T).exp());
    println!("all in the bank: CE fortune {:.2}", X0 * (R * T).exp());
    println!("exponential taste, A = 0.00001 per dollar: dollars in shares now {:.2}, at any fortune", (MU - R) * (-R * T).exp() / (0.00001 * SIG * SIG));
    let mut rng7 = Rng { s: 7 };
    let path = run_rule(&mut rng7, &|_x| ps, 1, 60, true).1;
    let yrs: Vec<f64> = (0..11).map(|k| k as f64 / 2.0).collect();
    println!("path, years:              {}", row(&yrs, &|y| format!("{:6.1}", y)));
    println!("path, fortune ($000):     {}", row(&path, &|x| format!("{:6.2}", x / 1000.0)));
    println!("path, in shares ($000):   {}", row(&path, &|x| format!("{:6.2}", ps * x / 1000.0)));

    let last = steps[steps.len() - 1];
    assert!((last.0 - ps).abs() < 1e-3);          // shrinking Bellman steps reach the HJB fraction
    assert!((last.1 - gs).abs() < 1e-4);          // and the HJB growth rate
    assert!((scan_best - ps).abs() < 1e-3);       // the scan finds the HJB maximiser at p_star
    assert!(scan_res.abs() < 1e-5);               // and V makes the HJB equation balance there
    assert!((mc[1].0 - ce_star).abs() < 4.0 * mc[1].1); // simulation agrees with the formula
    assert!(ce_fb + 3.0 * se_fb < ce_star);       // a rule that reacts differently does worse
    println!("all checks passed");
}
