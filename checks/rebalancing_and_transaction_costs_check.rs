// Rebalancing and transaction costs -- the same check as the Python, in Rust.
// Standard library only, no crates.  A 60-40 fund has drifted to 65-35.
// Roads: the exact sale by formula and by bisection; the one-shot band by
// formula and by grid search; the lifelong band by the cube-root rule and by
// simulating ten-year daily paths with a random generator written here.
const W: f64 = 100000.0;
const S: f64 = 65000.0;
const C: f64 = 0.001;
const TW: f64 = 0.60; // target weight
const GAM: f64 = 2.5;
const SIG: f64 = 0.20;
const R: f64 = 0.03;
const DAYS: usize = 252;
const YEARS: usize = 10;
const PATHS: usize = 500;

fn sale_formula(z: f64) -> f64 { (S - z * W) / (1.0 - C * z) }

fn sale_bisect(z: f64) -> f64 {
    // road 2: search for the sale, no formula
    let (mut lo, mut hi) = (0.0_f64, S);
    for _ in 0..200 {
        let q = 0.5 * (lo + hi);
        if (S - q) / (W - C * q) > z { lo = q } else { hi = q }
    }
    0.5 * (lo + hi)
}

fn clamp(x: f64, h: f64) -> f64 { (TW + h).min((TW - h).max(x)) }
fn lam() -> f64 { GAM * SIG * SIG }
fn j(z: f64, x: f64, kap: f64) -> f64 { 0.5 * kap * (z - TW).powi(2) + C * (z - x).abs() }
fn s_w() -> f64 { TW * (1.0 - TW) * SIG }
fn h_cube(cc: f64) -> f64 { (3.0 * cc * s_w() * s_w() / (2.0 * lam())).powf(1.0 / 3.0) }
fn big_l(h: f64) -> f64 { 0.5 * lam() * h * h / 3.0 + C * s_w() * s_w() / (2.0 * h) }

struct Rng(u64); // splitmix64, written out
impl Rng {
    fn u01(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
}

fn path(rng: &mut Rng, mu: f64) -> Vec<f64> {
    // one ten-year path of daily share growth factors
    let dt = 1.0 / DAYS as f64;
    (0..DAYS * YEARS).map(|_| {
        let a = rng.u01();
        let b = rng.u01();
        let z = (-2.0 * (1.0 - a).ln()).sqrt() * (2.0 * std::f64::consts::PI * b).cos();
        ((mu - 0.5 * SIG * SIG) * dt + SIG * dt.sqrt() * z).exp()
    }).collect()
}

fn run(rule: &str, arg: f64, gs: &[f64], tot: &mut [f64; 4]) {
    // tot: turnover, cost, loss, squared deviation
    let dt = 1.0 / DAYS as f64;
    let gb = (R * dt).exp();
    let mut x = TW;
    for (t, &g) in gs.iter().enumerate() {
        tot[2] += 0.5 * lam() * (x - TW).powi(2) * dt;
        tot[3] += (x - TW).powi(2) * dt;
        x = x * g / (x * g + (1.0 - x) * gb);
        let mut z = x;
        if rule == "calendar" && (t + 1) % (arg as usize) == 0 { z = TW }
        else if rule == "threshold" && (x - TW).abs() > arg { z = TW }
        else if rule == "band" { z = clamp(x, arg) }
        tot[0] += (z - x).abs();
        tot[1] += C * (z - x).abs();
        x = z;
    }
}

fn main() {
    let mu = R + GAM * SIG * SIG * TW; // excess return making 60% Merton's fraction
    let x0 = S / W;
    let (s, h) = (s_w(), h_cube(C));
    let rules: [(&str, &str, f64); 6] = [("never rebalance", "never", 0.0), ("calendar, yearly", "calendar", 252.0),
        ("calendar, quarterly", "calendar", 63.0), ("calendar, monthly", "calendar", 21.0),
        ("threshold 5 pts, to target", "threshold", 0.05), ("band +-3.26 pts, to edge", "band", h)];
    let sweep = [0.01, 0.02, 0.03, 0.04, 0.05, 0.06, 0.08];
    let mut acc_r = [[0.0_f64; 4]; 6];
    let mut acc_s = [[0.0_f64; 4]; 7];
    let mut rng = Rng(20260928);
    for _ in 0..PATHS {
        let gs = path(&mut rng, mu);
        for (i, (_, rule, arg)) in rules.iter().enumerate() { run(rule, *arg, &gs, &mut acc_r[i]) }
        for (i, hh) in sweep.iter().enumerate() { run("band", *hh, &gs, &mut acc_s[i]) }
    }
    let yrs = (PATHS * YEARS) as f64;
    let (qf, qb) = (sale_formula(TW), sale_bisect(TW));
    let (qe, qeb) = (sale_formula(TW + h), sale_bisect(TW + h));
    let k1 = lam() * 1.0; // one-shot model: the gap is held for one year
    let mut zs = 0.4;
    for i in 40000..=80000 {
        let z = i as f64 / 100000.0;
        if j(z, x0, k1) < j(zs, x0, k1) { zs = z }
    }
    println!("fund {:.2}  shares {:.2}  bonds {:.2}  target {:.2}  drifted {:.2}", W, S, W - S, TW, x0);
    println!("cost per dollar traded {:.4}  gamma {:.2}  sigma {:.2}  r {:.2}  mu {:.2}", C, GAM, SIG, R, mu);
    println!("gamma sigma^2 {:.4}  Merton fraction (mu-r)/(gamma sigma^2) {:.4}", lam(), (mu - R) / lam());
    println!("paths {}  years {}  days per year {}", PATHS, YEARS, DAYS);
    println!("loss rate at 65%, per $100,000 per year {:9.2}", W * 0.5 * lam() * (x0 - TW).powi(2));
    println!("sell to 60%: formula {:10.2}  bisection {:10.2}  fee {:6.2}", qf, qb, C * qf);
    println!("one-shot kappa {:.4}  half-width c/kappa {:.4}  clamp {:.5}  grid {:.5}", k1, C / k1, clamp(x0, C / k1), zs);
    for (lab, z) in [("wait", x0), ("to target", TW), ("to edge 61%", clamp(x0, C / k1))] {
        println!("  one-shot loss, {:<12} per $100,000 {:8.2}", lab, W * j(z, x0, k1));
    }
    println!("weight's spread s = w(1-w)sigma {:.4}  w^2(1-w)^2 {:.4}  h^3 {:.7}", s, (TW * (1.0 - TW)).powi(2), h.powi(3));
    let mut hl = 0.001; // road 2 to h: brute-force minimum
    for i in 100..=20000 {
        let hh = i as f64 / 100000.0;
        if big_l(hh) < big_l(hl) { hl = hh }
    }
    println!("lifelong half-width h {:.5}  brute-force minimum of L {:.5}", h, hl);
    println!("band {:.2}% to {:.2}%", 100.0 * (TW - h), 100.0 * (TW + h));
    println!("sell to edge {:.2}%: formula {:9.2}  bisection {:9.2}  fee {:5.2}", 100.0 * (TW + h), qe, qeb, C * qe);
    println!("formula at h: turnover {:.4}  mean sq dev {:.6}  $/yr {:.2}", s * s / (2.0 * h), h * h / 3.0, W * big_l(h));
    let bh = acc_r[5];
    println!("simulated at h: turnover {:.4}  mean sq dev {:.6}  $/yr {:.2}", bh[0] / yrs, bh[3] / yrs, W * (bh[1] + bh[2]) / yrs);
    println!("simulated / formula: turnover {:.3}  mean sq dev {:.3}", bh[0] / yrs / (s * s / (2.0 * h)), bh[3] / yrs / (h * h / 3.0));
    println!("what breaks, $ per year per $100,000 (formula L):");
    for (lab, hh) in [("one-shot width c/kappa", C / k1), ("sigma in place of s", (3.0 * C / (2.0 * GAM)).powf(1.0 / 3.0)),
                      ("cost counted twice", h_cube(2.0 * C))] {
        println!("  {:<24} h {:.4}  {:6.2}   right {:.2}", lab, hh, W * big_l(hh), W * big_l(h));
    }
    println!("rules over 10 years, daily prices, per $100,000 per year:");
    println!("  {:<28}{:>9}{:>8}{:>8}{:>8}", "rule", "turnover", "cost", "drift", "total");
    for (i, (name, _, _)) in rules.iter().enumerate() {
        let a = acc_r[i];
        println!("  {:<28}{:9.4}{:8.2}{:8.2}{:8.2}", name, a[0] / yrs, W * (a[1] / yrs), W * (a[2] / yrs),
                 W * (a[1] / yrs + a[2] / yrs));
    }
    println!("band sweep, simulated, per $100,000 per year:");
    for (i, hh) in sweep.iter().enumerate() {
        let a = acc_s[i];
        println!("  h {:4.1} pts  cost {:6.2}  drift {:6.2}  total {:6.2}  formula {:6.2}", 100.0 * hh,
                 W * (a[1] / yrs), W * (a[2] / yrs), W * (a[1] / yrs + a[2] / yrs), W * big_l(*hh));
    }
    let h_of = |cc: f64, g: f64, p: f64| (1.5 * cc * (p * (1.0 - p)).powi(2) / g).powf(1.0 / 3.0);
    for (lab, cc, g, p) in [("c = 0.0001", 0.0001, GAM, TW), ("c = 0.01", 0.01, GAM, TW),
                            ("gamma = 5", C, 5.0, TW), ("target 0.50", C, GAM, 0.5)] {
        let v = h_of(cc, g, p);
        println!("try: {:<12} h {:.4}  band {:.2}% to {:.2}%", lab, v, 100.0 * (p - v), 100.0 * (p + v));
    }
    println!("ten times the cost widens the band by {:.3}", h_of(0.01, GAM, TW) / h);
    let pol: Vec<f64> = (0..11).map(|i| 0.50 + 0.02 * i as f64).collect();
    let row = |f: &dyn Fn(f64) -> String| pol.iter().map(|&x| f(x)).collect::<Vec<_>>().join(" ");
    println!("chart, weight before {}", row(&|x| format!("{:5.0}", 100.0 * x)));
    println!("chart, band to edge  {}", row(&|x| format!("{:5.2}", 100.0 * clamp(x, h))));
    println!("chart, threshold     {}", row(&|x| format!("{:5.2}", 100.0 * if (x - TW).abs() > 0.05 + 1e-12 { TW } else { x })));
    let mut best = sweep[0];
    let mut best_tot = f64::INFINITY;
    for (i, hh) in sweep.iter().enumerate() {
        let t = acc_s[i][1] / yrs + acc_s[i][2] / yrs;
        if t < best_tot { best_tot = t; best = *hh }
    }
    let tots: Vec<f64> = acc_r.iter().map(|a| a[1] / yrs + a[2] / yrs).collect();
    assert!((qf - qb).abs() < 1e-6 && (qe - qeb).abs() < 1e-6, "exact sale: formula vs bisection");
    assert!((hl - h).abs() < 2e-5, "cube-root rule vs brute-force minimum of L");
    assert!((zs - clamp(x0, C / k1)).abs() < 2e-5, "one-shot band: clamp vs grid search");
    assert!((bh[0] / yrs / (s * s / (2.0 * h)) - 1.0).abs() < 0.15, "turnover: walls vs simulation");
    assert!((bh[3] / yrs / (h * h / 3.0) - 1.0).abs() < 0.20, "time spread evenly: h^2/3 vs simulation");
    assert!((best - h).abs() <= 0.011, "simulated best width near the cube-root rule");
    assert!(tots[..5].iter().all(|&t| tots[5] < t), "band beats every other rule");
    println!("ALL CHECKS PASS");
}
