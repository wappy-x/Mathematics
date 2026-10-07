// Merton's model -- the same check as the Python, in Rust.  Standard library
// only, no crates.  Rust has no erf, so the bell-curve area N(x) is built by
// adding thin slices under the curve (Simpson), a different road from the
// Python series.  Tree, Monte Carlo generator and bisection are written here.
use std::f64::consts::PI;

fn phi(z: f64) -> f64 { (-0.5 * z * z).exp() / (2.0 * PI).sqrt() }

fn simpson<G: Fn(f64) -> f64>(f: G, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    s * h / 3.0
}

fn n_cdf(x: f64) -> f64 {                    // bell-curve area left of x
    if x < -12.0 { return 0.0; }
    if x > 12.0 { return 1.0; }
    0.5 + simpson(phi, 0.0, x, 4000)
}

// road 1: the call and put formulas -> (d1, d2, safe bond, equity, put)
fn merton(v: f64, f: f64, r: f64, sig: f64, t: f64) -> (f64, f64, f64, f64, f64) {
    let w = sig * t.sqrt();
    let d2 = ((v / f).ln() + (r - 0.5 * sig * sig) * t) / w;
    let d1 = d2 + w;
    let safe = f * (-r * t).exp();
    let e = v * n_cdf(d1) - safe * n_cdf(d2);
    let p = safe * n_cdf(-d2) - v * n_cdf(-d1);
    (d1, d2, safe, e, p)
}

fn spread_bp(v: f64, f: f64, r: f64, sig: f64, t: f64) -> f64 {
    let e = merton(v, f, r, sig, t).3;
    (-((v - e) / f).ln() / t - r) * 1e4
}

fn bisect<G: Fn(f64) -> f64>(g: G, mut lo: f64, mut hi: f64) -> f64 {
    for _ in 0..200 {
        let mid = 0.5 * (lo + hi);
        if (g(lo) < 0.0) == (g(mid) < 0.0) { lo = mid } else { hi = mid }
    }
    0.5 * (lo + hi)
}

fn tree<G: Fn(f64) -> f64>(v0: f64, r: f64, sig: f64, t: f64, payoff: G, disc: bool) -> f64 {
    let n = 2000usize;
    let dt = t / n as f64;
    let (u, d) = ((sig * dt.sqrt()).exp(), (-sig * dt.sqrt()).exp());
    let p = ((r * dt).exp() - d) / (u - d);
    let k = if disc { (-r * dt).exp() } else { 1.0 };
    let mut v: Vec<f64> = (0..=n).map(|j| payoff(v0 * u.powi(j as i32) * d.powi((n - j) as i32))).collect();
    for m in (1..=n).rev() { v = (0..m).map(|j| k * (p * v[j + 1] + (1.0 - p) * v[j])).collect(); }
    v[0]
}

struct SplitMix(u64);                        // hand-written random numbers
impl SplitMix {
    fn uniform(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut x = self.0;
        x = (x ^ (x >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        x = (x ^ (x >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((x ^ (x >> 31)) >> 11) as f64 * 2f64.powi(-53)
    }
}

fn main() {
    let (v, f, t, sig, r, mu) = (100.0_f64, 80.0_f64, 1.0_f64, 0.20_f64, 0.05_f64, 0.08_f64);
    let (d1, d2, safe, e, p) = merton(v, f, r, sig, t);
    let (b, b_put, pd) = (v - e, safe - p, n_cdf(-d2));
    let y = -(b / f).ln() / t;
    let y_bis = bisect(|x| f * (-x * t).exp() - b, -1.0, 1.0);

    // road 2: average the maturity payoffs over the bell curve; no d1, d2 or N
    let vt = |z: f64| v * ((r - 0.5 * sig * sig) * t + sig * t.sqrt() * z).exp();
    let zs = bisect(|z| vt(z) - f, -10.0, 10.0);
    let disc = (-r * t).exp();
    let e_int = disc * simpson(|z| (vt(z) - f) * phi(z), zs, 10.0, 4000);
    let b_int = disc * (simpson(|z| vt(z) * phi(z), -10.0, zs, 4000) + simpson(|z| f * phi(z), zs, 10.0, 4000));
    let p_int = disc * simpson(|z| (f - vt(z)) * phi(z), -10.0, zs, 4000);
    let pd_int = simpson(phi, -10.0, zs, 4000);
    let rec_int = simpson(|z| vt(z) * phi(z), -10.0, zs, 4000) / pd_int;

    // road 3: a 2000-step coin-flip tree on the assets
    let e_tree = tree(v, r, sig, t, |a| (a - f).max(0.0), true);
    let pd_tree = tree(v, r, sig, t, |a| if a < f { 1.0 } else { 0.0 }, false);

    // road 4: Monte Carlo, 200,000 draws from the same splitmix64 generator
    let (mut rng, m) = (SplitMix(20260928), 200000usize);
    let (mut se, mut sq, mut nd) = (0.0_f64, 0.0_f64, 0usize);
    for _ in 0..m {
        let z = (-2.0 * (1.0 - rng.uniform()).ln()).sqrt() * (2.0 * PI * rng.uniform()).cos();
        let pay = (vt(z) - f).max(0.0);
        se += pay; sq += pay * pay;
        if vt(z) < f { nd += 1; }
    }
    let mf = m as f64;
    let (e_mc, pd_mc) = (disc * se / mf, nd as f64 / mf);
    let e_se = disc * ((sq / mf - (se / mf).powi(2)) / mf).sqrt();
    let pd_se = (pd_mc * (1.0 - pd_mc) / mf).sqrt();

    let rec = v * (r * t).exp() * n_cdf(-d1) / n_cdf(-d2);
    let wrong_e = v * n_cdf(d1) - f * n_cdf(d2);
    let w_mu = ((v / f).ln() + (mu - 0.5 * sig * sig) * t) / (sig * t.sqrt());
    let rows: Vec<(&str, f64)> = vec![
        ("ln(V/F)", (v / f).ln()), ("d1", d1), ("d2", d2), ("N(d1)", n_cdf(d1)), ("N(d2)", n_cdf(d2)), ("discount e^-rT", (-r * t).exp()), ("safe bond F e^-rT", safe),
        ("share leg V N(d1)", v * n_cdf(d1)), ("cash leg F e^-rT N(d2)", safe * n_cdf(d2)), ("recovery leg V N(-d1)", v * n_cdf(-d1)),
        ("1 equity, formula", e), ("2 equity, Simpson integral", e_int),
        ("3 equity, tree 2000 steps", e_tree), ("4 equity, Monte Carlo", e_mc), ("  its standard error", e_se),
        ("debt, V - E", b), ("debt, safe bond - put", b_put),
        ("debt, integral of min(V_T, F)", b_int), ("bond / riskless bond", b / safe),
        ("put, formula", p), ("put, integral", p_int),
        ("default prob, N(-d2)", pd), ("default prob, integral", pd_int),
        ("default prob, tree", pd_tree), ("default prob, Monte Carlo", pd_mc), ("  its standard error", pd_se),
        ("yield, -ln(B/F)/T", y), ("yield, bisection", y_bis), ("spread, bp", (y - r) * 1e4),
        ("mean assets given default, formula", rec), ("mean assets given default, integral", rec_int),
        ("recovery rate, share of F", rec / f), ("loss given default, share of F", 1.0 - rec / f),
        ("shortfall given default, F - mean", f - rec),
        ("put = e^-rT x PD x (F - mean assets)", disc * pd * (f - rec)),
        ("rough spread PD x LGD, bp", pd * (1.0 - rec / f) * 1e4),
        ("wrong: no discount, equity", wrong_e), ("wrong: no discount, debt", v - wrong_e),
        ("wrong: safe x (1 - PD), debt", safe * (1.0 - pd)),
        ("wrong: simple yield, spread bp", ((f / b - 1.0) / t - r) * 1e4),
        ("real-world default prob, 8% drift", n_cdf(-w_mu)),
        ("try: sigma 0.40, equity", merton(v, f, r, 0.40, t).3), ("try: sigma 0.40, spread bp", spread_bp(v, f, r, 0.40, t)),
        ("try: F 90, spread bp", spread_bp(v, 90.0, r, sig, t)), ("try: V 80, spread bp", spread_bp(80.0, f, r, sig, t)),
        ("try: T 5, spread bp", spread_bp(v, f, r, sig, 5.0)), ("try: T 5, default prob", n_cdf(-merton(v, f, r, sig, 5.0).1)),
    ];
    for (name, x) in &rows { println!("{:<38} {:>14.6}", name, x); }
    let join = |xs: Vec<String>| xs.join(" ");
    let grid: Vec<f64> = (0..9).map(|i| 20.0 * i as f64).collect();
    println!("chart, assets at maturity {}", join(grid.iter().map(|a| format!("{:6.0}", a)).collect()));
    println!("chart, equity at maturity {}", join(grid.iter().map(|a| format!("{:6.0}", (a - f).max(0.0))).collect()));
    println!("chart, debt at maturity   {}", join(grid.iter().map(|a| format!("{:6.0}", a.min(f))).collect()));
    println!("bars, $m: equity, debt, put, safe {}", join([e, b, p, safe].iter().map(|x| format!("{:.2}", x)).collect()));
    let today: Vec<f64> = (0..9).map(|i| 60.0 + 10.0 * i as f64).collect();
    println!("chart, assets today       {}", join(today.iter().map(|a| format!("{:6.0}", a)).collect()));
    println!("chart, equity today       {}", join(today.iter().map(|a| format!("{:6.2}", merton(*a, f, r, sig, t).3)).collect()));
    println!("chart, debt today         {}", join(today.iter().map(|a| format!("{:6.2}", a - merton(*a, f, r, sig, t).3)).collect()));

    assert!((e_int - e).abs() < 1e-7 && (b_int - b).abs() < 1e-7, "integral road vs the call formula");
    assert!((p_int - p).abs() < 1e-7 && (b_put - b).abs() < 1e-9, "put formula vs integral; two debt routes");
    assert!((e_tree - e).abs() < 0.01 && (pd_tree - pd).abs() < 0.005, "tree road");
    assert!((e_mc - e).abs() < 4.0 * e_se && (pd_mc - pd).abs() < 4.0 * pd_se, "Monte Carlo within 4 standard errors");
    assert!((pd_int - pd).abs() < 1e-8 && (rec_int - rec).abs() < 1e-6, "default prob and recovery, two roads");
    assert!((y_bis - y).abs() < 1e-12 && ((y - r) * 1e4 - 90.713).abs() < 0.001, "yield two ways; the reference 90.713 bp");
    println!("ALL CHECKS PASS");
}
