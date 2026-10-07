// A 0% floor and a 5% cap on year-on-year inflation, five yearly fixings, shifted Black.
// Roads: the formula; the payoff averaged over the bell curve; a coin-flip tree; parity.
// Rust has no erf, so the bell-curve area is built by Simpson slices under the curve.
const M: f64 = 1_000_000.0;
const F: f64 = 0.025;
const A: f64 = 0.03;
const SIG: f64 = 0.20;
const YEARS: [f64; 5] = [1.0, 2.0, 3.0, 4.0, 5.0];
const SI: f64 = 0.01;
const SR: f64 = 0.01;
const RHO: f64 = 0.5;

fn nom() -> f64 { 1.01 * 1.025 - 1.0 }
fn disc(t: f64) -> f64 { (1.0 + nom()).powf(-t) }
fn real_disc(t: f64) -> f64 { 1.01f64.powf(-t) }
fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * std::f64::consts::PI).sqrt() }

fn simpson<G: Fn(f64) -> f64>(f: G, lo: f64, hi: f64, n: usize) -> f64 {
    let h = (hi - lo) / n as f64;
    let mut s = f(lo) + f(hi);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(lo + i as f64 * h); }
    s * h / 3.0
}

fn ncdf(x: f64) -> f64 {
    if x.abs() > 12.0 { return if x > 0.0 { 1.0 } else { 0.0 }; }
    let half = simpson(phi, 0.0, x.abs(), 4000);
    if x >= 0.0 { 0.5 + half } else { 0.5 - half }
}

fn black(g: f64, l: f64, w: f64, put: bool) -> f64 {
    if l <= 0.0 { return if put { 0.0 } else { g - l }; }
    if w <= 0.0 { return if put { (l - g).max(0.0) } else { (g - l).max(0.0) }; }
    let d1 = ((g / l).ln() + 0.5 * w * w) / w;
    let d2 = d1 - w;
    if put { l * ncdf(-d2) - g * ncdf(-d1) } else { g * ncdf(d1) - l * ncdf(d2) }
}

// one option on one fixing: strike k, payment year t, forward f, shift a, vol sig, vol time tv, discount curve
fn let_(k: f64, t: f64, put: bool, f: f64, a: f64, sig: f64, tv: f64, dc: fn(f64) -> f64) -> f64 {
    M * dc(t) * black(f + a, k + a, sig * tv.sqrt(), put)
}
fn book(k: f64, put: bool, f: f64, a: f64, sig: f64) -> f64 {
    YEARS.iter().map(|&t| let_(k, t, put, f, a, sig, t, disc)).sum()
}

fn let_integral(k: f64, t: f64, put: bool) -> f64 {
    let w = SIG * t.sqrt();
    let y = |z: f64| (F + A) * (-0.5 * w * w + w * z).exp() - A;
    let pay = |z: f64| (if put { (k - y(z)).max(0.0) } else { (y(z) - k).max(0.0) }) * phi(z);
    let (mut lo, mut hi) = (-12.0f64, 12.0f64);
    for _ in 0..200 {
        let mid = 0.5 * (lo + hi);
        if y(mid) < k { lo = mid } else { hi = mid }
    }
    M * disc(t) * (simpson(&pay, -12.0, lo, 2000) + simpson(&pay, lo, 12.0, 2000))
}

fn let_tree(k: f64, t: f64, put: bool, n: i32) -> f64 {
    let u = (SIG * (t / n as f64).sqrt()).exp();
    let p = (1.0 - 1.0 / u) / (u - 1.0 / u);
    let (mut lw, mut tot) = (n as f64 * (1.0 - p).ln(), 0.0);
    for j in 0..=n {
        let y = (F + A) * u.powi(2 * j - n) - A;
        tot += lw.exp() * if put { (k - y).max(0.0) } else { (y - k).max(0.0) };
        if j < n { lw += ((n - j) as f64 / (j + 1) as f64).ln() + (p / (1.0 - p)).ln(); }
    }
    M * disc(t) * tot
}

fn fwd_adj(t: f64) -> f64 { (1.0 + F) * (-RHO * SI * SR * (t - 1.0)).exp() - 1.0 }
fn joint_mean(vi: f64, vp: f64, rho: f64, n: usize) -> f64 {
    let c = (1.0 - rho * rho).sqrt();
    let inner = |z1: f64| simpson(|e: f64| (vp * (rho * z1 + c * e) - 0.5 * vp * vp).exp() * phi(e), -9.0, 9.0, n);
    simpson(|z1: f64| (vi * z1 - 0.5 * vi * vi).exp() * phi(z1) * inner(z1), -9.0, 9.0, n)
}

fn main() {
    let fl: Vec<f64> = YEARS.iter().map(|&t| let_(0.0, t, true, F, A, SIG, t, disc)).collect();
    let fl_sum: f64 = fl.iter().sum();
    let fl_int: f64 = YEARS.iter().map(|&t| let_integral(0.0, t, true)).sum();
    let fl_tree: f64 = YEARS.iter().map(|&t| let_tree(0.0, t, true, 2000)).sum();
    let cap5 = book(0.05, false, F, A, SIG);
    let cap5_int: f64 = YEARS.iter().map(|&t| let_integral(0.05, t, false)).sum();
    let cap0_int: f64 = YEARS.iter().map(|&t| let_integral(0.0, t, false)).sum();
    let swap: f64 = YEARS.iter().map(|&t| M * disc(t) * (F - 0.0)).sum();

    let (g, l, w5) = (F + A, A, SIG * 5.0f64.sqrt());
    let d1 = ((g / l).ln() + 0.5 * w5 * w5) / w5;
    let d2 = d1 - w5;
    let (bp, vp) = (1e-4, 0.01);
    let dd1 = |t: f64| ((g / l).ln() + 0.5 * SIG * SIG * t) / (SIG * t.sqrt());
    let delta_an: f64 = YEARS.iter().map(|&t| -M * disc(t) * ncdf(-dd1(t)) * bp).sum();
    let delta_bump = (book(0.0, true, F + bp / 10.0, A, SIG) - book(0.0, true, F - bp / 10.0, A, SIG)) * 5.0;
    let vega_an: f64 = YEARS.iter().map(|&t| M * disc(t) * g * t.sqrt() * phi(dd1(t)) * vp).sum();
    let vega_bump = (book(0.0, true, F, A, SIG + vp / 10.0) - book(0.0, true, F, A, SIG - vp / 10.0)) * 5.0;

    let v19 = SI * 19.0f64.sqrt() * SR * 19.0f64.sqrt();
    let jm = joint_mean(SI * 19.0f64.sqrt(), SR * 19.0f64.sqrt(), RHO, 240);
    let fl_adj: f64 = YEARS.iter().map(|&t| let_(0.0, t, true, fwd_adj(t), A, SIG, t, disc)).sum();
    let start_of_year: f64 = YEARS.iter().map(|&t| let_(0.0, t, true, F, A, SIG, t - 1.0, disc)).sum();
    let strike_only: f64 = YEARS.iter().map(|&t| M * disc(t) * black(F, A, SIG * t.sqrt(), true)).sum();
    let real_dc: f64 = YEARS.iter().map(|&t| let_(0.0, t, true, F, A, SIG, t, real_disc)).sum();

    println!("inputs: forward {:.2} pct, shift {:.2} pct, vol {:.2} pct, notional {:.0}", 100.0 * F, 100.0 * A, 100.0 * SIG, M);
    println!("toy: index vol {:.2} pct, real-rate vol {:.2} pct, rho {:.2}", 100.0 * SI, 100.0 * SR, RHO);
    let mut rows: Vec<(String, f64)> = vec![
        ("nominal rate from Fisher, pct".into(), 100.0 * nom()), ("D(5), dollars per dollar".into(), disc(5.0)),
        ("year 5: G, pct".into(), 100.0 * g), ("year 5: L, pct".into(), 100.0 * l), ("year 5: w".into(), w5),
        ("year 5: d1".into(), d1), ("year 5: d2".into(), d2),
        ("year 5: N(-d2)".into(), ncdf(-d2)), ("year 5: N(-d1)".into(), ncdf(-d1)),
        ("napkin normal vol, G sigma, pct".into(), 100.0 * g * SIG),
    ];
    for (t, v) in YEARS.iter().zip(fl.iter()) { rows.push((format!("1 floorlet year {}, formula, $", t), *v)); }
    let more: Vec<(&str, f64)> = vec![
        ("1 floor 0%, formula, $", fl_sum), ("2 floor 0%, payoff average, $", fl_int),
        ("3 floor 0%, tree 2000 steps, $", fl_tree),
        ("  cap 5%, formula, $", cap5), ("  cap 5%, payoff average, $", cap5_int),
        ("  collar: 0% floor minus 5% cap, $", fl_sum - cap5),
        ("4 cap 0% minus floor 0%, $", cap0_int - fl_sum), ("  swap: sum D(t) (F - 0), $", swap),
        ("delta per 1 bp of F, formula, $", delta_an), ("delta per 1 bp of F, bump, $", delta_bump),
        ("vega per vol point, formula, $", vega_an), ("vega per vol point, bump, $", vega_bump),
        ("plain Black, no shift, floor 0%, $", book(0.0, true, F, 0.0, SIG)),
        ("convexity: year 5 forward, pct", 100.0 * fwd_adj(5.0)),
        ("convexity: year 5 shift, bp", 1e4 * (fwd_adj(5.0) - F)),
        ("convexity: year 20 shift, bp", 1e4 * (fwd_adj(20.0) - F)),
        ("  factor exp(rho vI vP), year 20", (RHO * v19).exp()),
        ("  the same by 2D Simpson", jm),
        ("  floor 0% on adjusted forwards, $", fl_adj),
        ("wrong: vol run to start of year, $", start_of_year),
        ("wrong: strike slid, rate not, $", strike_only),
        ("wrong: 20% vol used at a 1% shift, $", book(0.0, true, F, 0.01, SIG)),
        ("wrong: discounted at the 1% real rate, $", real_dc),
        ("try: sigma = 30%, $", book(0.0, true, F, A, 0.30)),
        ("try: forward 1%, $", book(0.0, true, 0.01, A, SIG)),
        ("try: strike -1%, $", book(-0.01, true, F, A, SIG)),
    ];
    for (n, v) in more { rows.push((n.to_string(), v)); }
    for (name, v) in &rows { println!("{:<42} {:>14.6}", name, v); }
    println!("bars, floorlets by year, $       {}", fl.iter().map(|v| format!("{:>9.2}", v)).collect::<Vec<_>>().join(" "));
    let xs = [-3i32, -2, -1, 0, 1, 2, 3, 4, 5, 6, 7];
    let line = |f: &dyn Fn(i32) -> String| xs.iter().map(|&x| f(x)).collect::<Vec<_>>().join(" ");
    println!("chart, YoY inflation pct          {}", line(&|x| format!("{:>6}", x)));
    println!("chart, floorlet pays $            {}", line(&|x| format!("{:>6.0}", M * (-(x as f64) / 100.0).max(0.0))));
    println!("chart, 5% caplet pays $           {}", line(&|x| format!("{:>6.0}", M * (x as f64 / 100.0 - 0.05).max(0.0))));
    let ks = [-0.02, -0.01, 0.0, 0.01, 0.02, 0.03];
    let kl = |f: &dyn Fn(f64) -> f64, p: usize| ks.iter().map(|&k| format!("{:>9.*}", p, f(k))).collect::<Vec<_>>().join(" ");
    println!("chart, floor strike pct    {}", kl(&|k| 100.0 * k, 0));
    println!("chart, shifted, $          {}", kl(&|k| book(k, true, F, A, SIG), 2));
    println!("chart, plain Black, $      {}", kl(&|k| book(k, true, F, 0.0, SIG), 2));

    assert!((fl_int - fl_sum).abs() < 1e-6, "payoff average must land on the formula");
    assert!((fl_tree - fl_sum).abs() < 1.0, "tree within a dollar");
    assert!((cap5_int - cap5).abs() < 1e-6, "cap by integral vs formula");
    assert!(((cap0_int - fl_sum) - swap).abs() < 1e-6, "cap minus floor at one strike is the swap");
    assert!((delta_an - delta_bump).abs() < 1e-4, "delta by bump");
    assert!((vega_an - vega_bump).abs() < 0.005, "vega by bump");
    assert!((jm - (RHO * v19).exp()).abs() < 1e-10, "convexity factor");
    assert!(((1.0 + F) / jm - 1.0 - fwd_adj(20.0)).abs() < 1e-10, "year-20 forward by 2D Simpson");
    println!("ALL CHECKS PASS");
}
