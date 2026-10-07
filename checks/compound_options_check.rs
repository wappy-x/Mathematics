// Compound options -- the same check as compound_options_check.py, in Rust.
// Standard library only, no crates.  The bell-curve area is a series, the
// two-dimensional bell curve is Simpson's rule, the critical share price is
// Newton's method checked by bisection, and the tree is a loop.
use std::f64::consts::PI;

const S: f64 = 100.0; const K2: f64 = 100.0; const T2: f64 = 1.0; const K1: f64 = 8.0;
const T1: f64 = 0.5; const R: f64 = 0.05; const Q: f64 = 0.02; const SIG: f64 = 0.20;

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }

fn n_cdf(x: f64) -> f64 {                                   // bell-curve area left of x, by series
    if x.abs() > 10.0 { return if x > 0.0 { 1.0 } else { 0.0 }; }
    let (mut term, mut total, mut k) = (x, x, 1.0_f64);
    while term.abs() > 1e-17 * total.abs() {
        term *= x * x / (2.0 * k + 1.0); total += term; k += 1.0;
    }
    0.5 + phi(x) * total
}

fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    s * h / 3.0
}

fn m2(a: f64, b: f64, rho: f64) -> f64 {    // chance X <= a and Y <= b, correlation rho
    if a < -10.0 { return 0.0; }
    let w = (1.0 - rho * rho).sqrt();
    simpson(|z| phi(z) * n_cdf((b - rho * z) / w), -10.0, a, 2000)
}

fn bs(s: f64, t: f64, eta: f64, sg: f64) -> f64 {   // call (eta = 1) or put (eta = -1), strike K2
    let v = sg * t.sqrt(); let d1 = ((s / K2).ln() + (R - Q + 0.5 * sg * sg) * t) / v;
    eta * (s * (-Q * t).exp() * n_cdf(eta * d1) - K2 * (-R * t).exp() * n_cdf(eta * (d1 - v)))
}

fn newton(eta: f64, k1: f64, tau: f64, sg: f64, trail: &mut Vec<(f64, f64)>) -> f64 {
    let mut x = K2;
    for _ in 0..50 {
        let d1 = ((x / K2).ln() + (R - Q + 0.5 * sg * sg) * tau) / (sg * tau.sqrt());
        let f = bs(x, tau, eta, sg) - k1; let slope = eta * (-Q * tau).exp() * n_cdf(eta * d1);
        trail.push((x, f));
        let step = f / slope; x -= step;
        if step.abs() < 1e-10 { return x; }
    }
    panic!("Newton did not settle");
}

fn bisect(eta: f64, k1: f64, tau: f64) -> f64 {
    let (mut lo, mut hi) = (1.0_f64, 300.0_f64);
    for _ in 0..80 {
        let mid = 0.5 * (lo + hi);
        if eta * (bs(mid, tau, eta, SIG) - k1) > 0.0 { hi = mid; } else { lo = mid; }
    }
    0.5 * (lo + hi)
}

struct P { s: f64, k1: f64, t1: f64, sg: f64, x: Option<f64>, rho: Option<f64>, k1_disc: Option<f64> }
fn base() -> P { P { s: S, k1: K1, t1: T1, sg: SIG, x: None, rho: None, k1_disc: None } }

fn geske(eps: f64, eta: f64, p: &P) -> f64 {
    if p.k1 == 0.0 { return if eps == 1.0 { bs(p.s, T2, eta, p.sg) } else { 0.0 }; }
    let x = p.x.unwrap_or_else(|| newton(eta, p.k1, T2 - p.t1, p.sg, &mut Vec::new()));
    let rho = p.rho.unwrap_or((p.t1 / T2).sqrt());
    let a2 = ((p.s / x).ln() + (R - Q - 0.5 * p.sg * p.sg) * p.t1) / (p.sg * p.t1.sqrt());
    let a1 = a2 + p.sg * p.t1.sqrt();
    let b2 = ((p.s / K2).ln() + (R - Q - 0.5 * p.sg * p.sg) * T2) / (p.sg * T2.sqrt());
    let b1 = b2 + p.sg * T2.sqrt();
    let j = eps * eta;
    let (a, b, f) = (p.s * (-Q * T2).exp(), K2 * (-R * T2).exp(), p.k1 * (-R * p.k1_disc.unwrap_or(p.t1)).exp());
    eps * (eta * (a * m2(j * a1, eta * b1, j * eta * rho) - b * m2(j * a2, eta * b2, j * eta * rho)) - f * n_cdf(j * a2))
}

fn by_integral(eps: f64, eta: f64, x: f64) -> f64 {     // road 2: average the first-date payoff
    let (v, nu) = (SIG * T1.sqrt(), (R - Q - 0.5 * SIG * SIG) * T1);
    let cut = ((x / S).ln() - nu) / v;
    let (lo, hi) = if eps * eta == 1.0 { (cut, 10.0) } else { (-10.0, cut) };
    let f = |z: f64| (eps * (bs(S * (nu + v * z).exp(), T2 - T1, eta, SIG) - K1)).max(0.0) * phi(z);
    (-R * T1).exp() * simpson(f, lo, hi, 4000)
}

fn by_tree(eta: f64, n: usize) -> (f64, f64) {          // road 3: one tree, both dates, no critical price
    let dt = T2 / n as f64; let up = SIG * dt.sqrt();
    let p = (((R - Q) * dt).exp() - (-up).exp()) / (up.exp() - (-up).exp());
    let disc = (-R * dt).exp(); let m = (n as f64 * T1 / T2).round() as usize;
    let back = |a: &Vec<f64>, i: usize| -> Vec<f64> { (0..=i).map(|j| disc * (p * a[j + 1] + (1.0 - p) * a[j])).collect() };
    let mut u: Vec<f64> = (0..=n).map(|j| (eta * (S * ((2.0 * j as f64 - n as f64) * up).exp() - K2)).max(0.0)).collect();
    for i in (m..n).rev() { u = back(&u, i); }
    let mut c: Vec<f64> = u.iter().map(|x| (x - K1).max(0.0)).collect();
    let mut pt: Vec<f64> = u.iter().map(|x| (K1 - x).max(0.0)).collect();
    for i in (0..m).rev() { c = back(&c, i); pt = back(&pt, i); }
    (c[0], pt[0])
}

fn main() {
    let mut trail = Vec::new();
    let xc = newton(1.0, K1, T2 - T1, SIG, &mut trail); let xb = bisect(1.0, K1, T2 - T1);
    let xp = newton(-1.0, K1, T2 - T1, SIG, &mut Vec::new()); let xpb = bisect(-1.0, K1, T2 - T1);
    let (v1, rho) = (SIG * T1.sqrt(), (T1 / T2).sqrt());
    let a2 = ((S / xc).ln() + (R - Q - 0.5 * SIG * SIG) * T1) / v1; let a1 = a2 + v1;
    let b2 = ((S / K2).ln() + (R - Q - 0.5 * SIG * SIG) * T2) / (SIG * T2.sqrt()); let b1 = b2 + SIG * T2.sqrt();
    let bp = base();
    let (cc, pc, cp, pp) = (geske(1.0, 1.0, &bp), geske(-1.0, 1.0, &bp), geske(1.0, -1.0, &bp), geske(-1.0, -1.0, &bp));
    let (cc_i, pc_i) = (by_integral(1.0, 1.0, xc), by_integral(-1.0, 1.0, xc));
    let (cp_i, pp_i) = (by_integral(1.0, -1.0, xp), by_integral(-1.0, -1.0, xp));
    let (cc_t, pc_t) = by_tree(1.0, 2000); let (cp_t, pp_t) = by_tree(-1.0, 2000);
    let (c0, fee) = (bs(S, T2, 1.0, SIG), K1 * (-R * T1).exp());
    let (at_s, h) = (|s: f64| geske(1.0, 1.0, &P { s, ..base() }), 0.01);
    let delta_bump = (at_s(S + h) - at_s(S - h)) / (2.0 * h);
    let gamma = (at_s(S + 1.0) - 2.0 * cc + at_s(S - 1.0)) / 1.0;
    let vega = (geske(1.0, 1.0, &P { sg: SIG + 0.01, ..base() }) - geske(1.0, 1.0, &P { sg: SIG - 0.01, ..base() })) / 2.0;
    let c_delta = (bs(S + h, T2, 1.0, SIG) - bs(S - h, T2, 1.0, SIG)) / (2.0 * h);
    let c_gamma = bs(S + 1.0, T2, 1.0, SIG) - 2.0 * c0 + bs(S - 1.0, T2, 1.0, SIG);
    let c_vega = (bs(S, T2, 1.0, SIG + 0.01) - bs(S, T2, 1.0, SIG - 0.01)) / 2.0;
    let m00 = m2(0.0, 0.0, rho); let m00_exact = 0.25 + rho.asin() / (2.0 * PI);
    let delta_f = (-Q * T2).exp() * m2(a1, b1, rho);

    let rows: Vec<(&str, f64)> = vec![
        ("underlying call today, 1 year", c0),
        ("critical price x*, Newton", xc), ("critical price x*, bisection", xb),
        ("call at 6 months when Acme = x*", bs(xc, T2 - T1, 1.0, SIG)),
        ("a1", a1), ("a2", a2), ("b1", b1), ("b2", b2),
        ("N(a2)  chance the $8 is paid", n_cdf(a2)), ("M(a2, b2; rho)  both exercised", m2(a2, b2, rho)),
        ("M(a1, b1; rho)  share-counted", m2(a1, b1, rho)),
        ("share leg  S e^-qT2 M(a1,b1)", S * (-Q * T2).exp() * m2(a1, b1, rho)),
        ("strike leg K2 e^-rT2 M(a2,b2)", K2 * (-R * T2).exp() * m2(a2, b2, rho)),
        ("fee leg    K1 e^-rT1 N(a2)", fee * n_cdf(a2)),
        ("1 call on call, Geske formula", cc), ("2 call on call, Simpson integral", cc_i),
        ("3 call on call, tree 2000 steps", cc_t),
        ("put on call, formula", pc), ("put on call, integral", pc_i), ("put on call, tree", pc_t),
        ("  CoC - PoC", cc - pc), ("  C0 - K1 e^-rT1", c0 - fee),
        ("critical price on the put, Newton", xp),
        ("call on put, formula", cp), ("call on put, integral", cp_i), ("call on put, tree", cp_t),
        ("put on put, formula", pp), ("put on put, integral", pp_i), ("put on put, tree", pp_t),
        ("check M(0,0;rho)", m00), ("  1/4 + asin(rho)/(2 pi)", m00_exact),
        ("delta CoC, e^-qT2 M(a1,b1)", delta_f), ("delta CoC, bump", delta_bump),
        ("gamma CoC, bump", gamma), ("vega CoC per vol point", vega), ("gearing CoC  S delta / V", S * delta_bump / cc),
        ("delta call, bump", c_delta), ("gamma call, bump", c_gamma), ("vega call per vol point", c_vega),
        ("gearing call  S delta / C", S * c_delta / c0),
        ("wrong: always pay the $8", c0 - fee), ("wrong: rho = T1/T2", geske(1.0, 1.0, &P { rho: Some(T1 / T2), ..base() })),
        ("wrong: $8 discounted from T2", geske(1.0, 1.0, &P { k1_disc: Some(T2), ..base() })),
        ("wrong: exercise when Acme > 100", geske(1.0, 1.0, &P { x: Some(K2), ..base() })),
        ("try: sigma = 0.30", geske(1.0, 1.0, &P { sg: 0.30, ..base() })), ("try: T1 = 0.25", geske(1.0, 1.0, &P { t1: 0.25, ..base() })),
    ];
    for (name, val) in &rows { println!("{:<40} {:>12.6}", name, val); }
    println!("hand: sigma sqrt(T1) {:.6}; drift T1 {:.6}; ln(S/x*) {:.6}; rho {:.6}\nhand: e^-qT2 {:.6}; e^-rT2 {:.6}; e^-rT1 {:.6}; K1 e^-rT1 {:.6}",
        v1, (R - Q - 0.5 * SIG * SIG) * T1, (S / xc).ln(), rho, (-Q * T2).exp(), (-R * T2).exp(), (-R * T1).exp(), fee);
    let steps: Vec<String> = trail.iter().map(|(x, f)| format!("{:.4} ({:+.4})", x, f)).collect();
    println!("newton steps: {}", steps.join("; "));
    let xs: Vec<f64> = (0..10).map(|i| 80.0 + 5.0 * i as f64).collect();
    let row = |label: &str, v: Vec<String>| println!("{}{}", label, v.join(" "));
    row("chart, Acme at 6 months ", xs.iter().map(|x| format!("{:6.0}", x)).collect());
    row("chart, call at 6 months ", xs.iter().map(|x| format!("{:6.2}", bs(*x, T2 - T1, 1.0, SIG))).collect());
    row("chart, CoC payoff       ", xs.iter().map(|x| format!("{:6.2}", (bs(*x, T2 - T1, 1.0, SIG) - K1).max(0.0))).collect());
    let ks: Vec<f64> = (0..9).map(|i| 2.0 * i as f64).collect();
    row("chart, fee K1           ", ks.iter().map(|k| format!("{:6.0}", k)).collect());
    row("chart, CoC price        ", ks.iter().map(|k| format!("{:6.2}", geske(1.0, 1.0, &P { k1: *k, ..base() }))).collect());

    assert!((xc - xb).abs() < 1e-6, "Newton and bisection find one critical price, call underlying");
    assert!((xp - xpb).abs() < 1e-6, "Newton and bisection find one critical price, put underlying");
    assert!((m00 - m00_exact).abs() < 1e-10, "bivariate routine vs closed form");
    for (f, i) in [(cc, cc_i), (pc, pc_i), (cp, cp_i), (pp, pp_i)] { assert!((f - i).abs() < 1e-6, "formula vs integral"); }
    for (f, t) in [(cc, cc_t), (pc, pc_t), (cp, cp_t), (pp, pp_t)] { assert!((f - t).abs() < 0.01, "formula vs tree"); }
    assert!(((cc - pc) - (c0 - fee)).abs() < 1e-9, "compound parity with the tree-free call");
    assert!((delta_f - delta_bump).abs() < 1e-6, "delta formula vs bump");
    assert!((c0 - 9.227005508154).abs() < 1e-9, "the house call");
    println!("ALL CHECKS PASS");
}
