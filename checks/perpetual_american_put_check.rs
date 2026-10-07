// Perpetual American put -- the same check as the Python, in Rust.  No crates.
// Every number on the card is printed here.  Nothing imported knows the answer:
// the root finders, the ODE integrator, the tree and the normal CDF are all
// written out below.  House market: S = K = 100, r = 5%, q = 2%, sigma = 20%.
use std::f64::consts::PI;

const S: f64 = 100.0;
const K: f64 = 100.0;
const R: f64 = 0.05;
const Q: f64 = 0.02;
const SIG: f64 = 0.20;

fn roots(r: f64, q: f64, sig: f64) -> (f64, f64) {          // road 1: the quadratic formula
    let (a, b, c) = (0.5 * sig * sig, r - q - 0.5 * sig * sig, -r);
    let disc = (b * b - 4.0 * a * c).sqrt();
    ((-b - disc) / (2.0 * a), (-b + disc) / (2.0 * a))
}

fn perp(s: f64, k: f64, r: f64, q: f64, sig: f64) -> (f64, f64) {   // boundary and value
    let lam = roots(r, q, sig).0;
    let b = k * lam / (lam - 1.0);
    (b, if s <= b { k - s } else { (k - b) * (s / b).powf(lam) })
}

fn golden_max<F: Fn(f64) -> f64>(f: F, mut lo: f64, mut hi: f64) -> f64 {  // road 2: best barrier
    let g = (5.0_f64.sqrt() - 1.0) / 2.0;
    for _ in 0..200 {
        let (m1, m2) = (hi - g * (hi - lo), lo + g * (hi - lo));
        if f(m1) < f(m2) { lo = m1 } else { hi = m2 }
    }
    0.5 * (lo + hi)
}

fn shoot(b: f64, x_end: f64) -> f64 {        // road 3: RK4 on the time-free equation in x = ln s
    let (a, nu) = (0.5 * SIG * SIG, R - Q - 0.5 * SIG * SIG);
    let f = |u: f64, v: f64| (v, (R * u - nu * v) / a);        // u = price, v = s * slope
    let (mut u, mut v) = (K - b, -b);                           // value matching and smooth pasting
    let n = 4000;
    let h = (x_end - b.ln()) / n as f64;
    for _ in 0..n {
        let k1 = f(u, v);
        let k2 = f(u + h / 2.0 * k1.0, v + h / 2.0 * k1.1);
        let k3 = f(u + h / 2.0 * k2.0, v + h / 2.0 * k2.1);
        let k4 = f(u + h * k3.0, v + h * k3.1);
        u += h / 6.0 * (k1.0 + 2.0 * k2.0 + 2.0 * k3.0 + k4.0);
        v += h / 6.0 * (k1.1 + 2.0 * k2.1 + 2.0 * k3.1 + k4.1);
    }
    u
}

fn bisect<F: Fn(f64) -> f64>(f: F, mut lo: f64, mut hi: f64) -> f64 {
    for _ in 0..200 {
        let mid = 0.5 * (lo + hi);
        if (f(lo) > 0.0) == (f(mid) > 0.0) { lo = mid } else { hi = mid }
    }
    0.5 * (lo + hi)
}

fn tree(t: f64, n: usize) -> f64 {           // road 4: Cox-Ross-Rubinstein tree, finite life t
    let dt = t / n as f64;
    let u = (SIG * dt.sqrt()).exp();
    let d = 1.0 / u;
    let p = (((R - Q) * dt).exp() - d) / (u - d);
    let df = (-R * dt).exp();
    let mut v: Vec<f64> = (0..=n).map(|j| (K - S * u.powf(2.0 * j as f64 - n as f64)).max(0.0)).collect();
    for m in (0..n).rev() {
        let mut s = S * u.powf(-(m as f64));
        let mut nv = Vec::with_capacity(m + 1);
        for j in 0..=m {
            let mut c = df * (p * v[j + 1] + (1.0 - p) * v[j]);
            if K - s > c { c = K - s }
            nv.push(c);
            s *= u * u;
        }
        v = nv;
    }
    v[0]
}

fn ncdf(x: f64) -> f64 {                     // bell-curve area left of x, by Simpson's rule
    let n = 2000;
    let h = x / n as f64;
    let ph = |z: f64| (-0.5 * z * z).exp() / (2.0 * PI).sqrt();
    let mut tot = ph(0.0) + ph(x);
    for i in 1..n { tot += if i % 2 == 1 { 4.0 } else { 2.0 } * ph(i as f64 * h) }
    0.5 + tot * h / 3.0
}

fn euro_put(t: f64) -> f64 {
    let d1 = ((S / K).ln() + (R - Q + 0.5 * SIG * SIG) * t) / (SIG * t.sqrt());
    let d2 = d1 - SIG * t.sqrt();
    K * (-R * t).exp() * ncdf(-d2) - S * (-Q * t).exp() * ncdf(-d1)
}

fn main() {
    let (lam, mu) = roots(R, Q, SIG);
    let (bstar, p) = perp(S, K, R, Q, SIG);
    let b_gold = golden_max(|b| (K - b) * (S / b).powf(lam), 1.0, K);
    let b_shoot = bisect(|b| shoot(b, 1e6_f64.ln()), 40.0, 90.0);
    let p_shoot = shoot(b_shoot, S.ln());
    let mats = [1usize, 2, 5, 10, 20, 30, 50, 100];
    let amer: Vec<f64> = mats.iter().map(|&t| tree(t as f64, 1000.max(50 * t))).collect();
    let euro: Vec<f64> = mats.iter().map(|&t| euro_put(t as f64)).collect();
    let h = 0.01;
    let dp = |s: f64| perp(s, K, R, Q, SIG).1;
    let (delta, gamma) = (lam * p / S, lam * (lam - 1.0) * p / (S * S));
    let delta_b = (dp(S + h) - dp(S - h)) / (2.0 * h);
    let gamma_b = (dp(S + h) - 2.0 * p + dp(S - h)) / (h * h);
    let theta = R * p - 0.5 * SIG * SIG * S * S * gamma_b - (R - Q) * S * delta_b;  // zero
    assert!((b_shoot - bstar).abs() < 1e-6 && (b_gold - bstar).abs() < 1e-6);   // two roads to the boundary
    assert!((p_shoot - p).abs() < 1e-6);                                         // the ODE, no power guessed
    assert!(p - amer[5] > 0.0 && p - amer[5] < 0.5 && (amer[7] - p).abs() < 0.01); // tree rises to the formula
    assert!((delta_b - delta).abs() < 1e-6 && theta.abs() < 1e-4);              // slope, and no time decay
    let vega = (perp(S, K, R, Q, SIG + 1e-4).1 - perp(S, K, R, Q, SIG - 1e-4).1) / 2e-4;
    let rho = (perp(S, K, R + 1e-4, Q, SIG).1 - perp(S, K, R - 1e-4, Q, SIG).1) / 2e-4;
    let wrong_q0 = perp(S, K, R, 0.0, SIG);
    let (a2, b1) = (0.5 * SIG * SIG, R - Q - 0.5 * SIG * SIG);
    let rows: Vec<(&str, f64)> = vec![
        ("sigma^2 / 2", a2), ("r - q - sigma^2 / 2", b1),
        ("discriminant b^2 - 4ac", b1 * b1 + 4.0 * a2 * R), ("  its square root", (b1 * b1 + 4.0 * a2 * R).sqrt()),
        ("lambda, the negative root", lam), ("mu, the positive root", mu),
        ("boundary S* = K lambda / (lambda - 1)", bstar), ("payoff at the boundary K - S*", K - bstar),
        ("S / S*", S / bstar), ("(S / S*)^lambda", (S / bstar).powf(lam)),
        ("1 formula, value at S = 100", p), ("2 best barrier, golden section", b_gold),
        ("3 boundary by shooting the ODE", b_shoot), ("3 value by shooting the ODE", p_shoot),
        ("4 tree, 30 years, 1500 steps", amer[5]), ("4 tree, 100 years, 5000 steps", amer[7]),
        ("delta = lambda P / S", delta), ("  delta by bump", delta_b),
        ("gamma = lambda (lambda - 1) P / S^2", gamma), ("  gamma by bump", gamma_b),
        ("theta from the equation, size", theta.abs()), ("vega, per point of sigma", vega / 100.0), ("rho, per point of r", rho / 100.0),
        ("r K - q S*, waiting cost at S*", R * K - Q * bstar),
        ("wrong: positive root, boundary", K * mu / (mu - 1.0)), ("wrong: forgot q, boundary", wrong_q0.0),
        ("wrong: forgot q, value", wrong_q0.1), ("wrong: exercise at 80, value", (K - 80.0) * (S / 80.0).powf(lam)),
        ("wrong: European 30-year put", euro[5]),
        ("try: sigma = 0.30, boundary", perp(S, K, R, Q, 0.30).0), ("try: sigma = 0.30, value", perp(S, K, R, Q, 0.30).1),
        ("try: r = 0.08, boundary", perp(S, K, 0.08, Q, SIG).0), ("try: r = 0.08, value", perp(S, K, 0.08, Q, SIG).1),
        ("try: q = 0, value at 200", perp(200.0, K, R, 0.0, SIG).1),
    ];
    for (name, v) in &rows { println!("{:<38} {:>12.6}", name, v) }
    println!();
    let row = |label: &str, vals: Vec<String>| println!("{}{}", label, vals.join(" "));
    row("maturity (years)  ", mats.iter().map(|t| format!("{:>7}", t)).collect());
    row("American, tree    ", amer.iter().map(|v| format!("{:>7.2}", v)).collect());
    row("European, formula ", euro.iter().map(|v| format!("{:>7.2}", v)).collect());
    let spots: Vec<f64> = (0..13).map(|i| 40.0 + 10.0 * i as f64).collect();
    row("chart, share price", spots.iter().map(|s| format!("{:>7.0}", s)).collect());
    row("chart, perpetual  ", spots.iter().map(|&s| format!("{:>7.2}", dp(s))).collect());
    row("chart, exercise   ", spots.iter().map(|&s| format!("{:>7.2}", (K - s).max(0.0))).collect());

    println!("ALL CHECKS PASS");
}
