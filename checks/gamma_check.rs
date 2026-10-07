// Gamma -- the check behind the card.  Rust std only, no crates.
// Same rows, same labels as the Python check, by a different road to the
// bell-curve area: N(x) is Simpson's rule on the bell curve, not a series.
use std::f64::consts::PI;

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }
fn n_cdf(x: f64) -> f64 {
    // area from 0 to x, 4000 Simpson panels, plus the left half (0.5)
    if x.abs() > 9.0 { return if x < 0.0 { 0.0 } else { 1.0 }; }
    let n = 4000; let h = x / n as f64;
    let mut s = phi(0.0) + phi(x);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * phi(i as f64 * h); }
    0.5 + s * h / 3.0
}
fn d1(s0: f64, k: f64, r: f64, q: f64, s: f64, t: f64) -> f64 {
    ((s0 / k).ln() + (r - q + 0.5 * s * s) * t) / (s * t.sqrt())
}
fn call(s0: f64, k: f64, r: f64, q: f64, s: f64, t: f64) -> f64 {
    let a = d1(s0, k, r, q, s, t);
    s0 * (-q * t).exp() * n_cdf(a) - k * (-r * t).exp() * n_cdf(a - s * t.sqrt())
}
fn put(s0: f64, k: f64, r: f64, q: f64, s: f64, t: f64) -> f64 {
    let a = d1(s0, k, r, q, s, t);
    k * (-r * t).exp() * n_cdf(s * t.sqrt() - a) - s0 * (-q * t).exp() * n_cdf(-a)
}
fn delta(s0: f64, k: f64, r: f64, q: f64, s: f64, t: f64) -> f64 { (-q * t).exp() * n_cdf(d1(s0, k, r, q, s, t)) }
fn gamma(s0: f64, k: f64, r: f64, q: f64, s: f64, t: f64) -> f64 {
    (-q * t).exp() * phi(d1(s0, k, r, q, s, t)) / (s0 * s * t.sqrt())
}
fn tree_gamma(s0: f64, k: f64, r: f64, q: f64, s: f64, t: f64, n: usize) -> f64 {
    // Road 6: Cox-Ross-Rubinstein tree; gamma from the three nodes two steps in
    let dt = t / n as f64; let u = (s * dt.sqrt()).exp(); let d = 1.0 / u;
    let p = (((r - q) * dt).exp() - d) / (u - d); let disc = (-r * dt).exp();
    let mut v: Vec<f64> = (0..=n).map(|j| (s0 * u.powi(j as i32) * d.powi((n - j) as i32) - k).max(0.0)).collect();
    for step in (3..=n).rev() {
        for j in 0..step { v[j] = disc * (p * v[j + 1] + (1.0 - p) * v[j]); }
    }
    let (up, mid, dn) = (s0 * u * u, s0, s0 * d * d);
    ((v[2] - v[1]) / (up - mid) - (v[1] - v[0]) / (mid - dn)) / (0.5 * (up - dn))
}

fn main() {
    let (s0, k, r, q, s, t) = (100.0_f64, 100.0_f64, 0.05_f64, 0.02_f64, 0.20_f64, 1.0_f64);
    let a = d1(s0, k, r, q, s, t);
    let (g, c, dl) = (gamma(s0, k, r, q, s, t), call(s0, k, r, q, s, t), delta(s0, k, r, q, s, t));
    let h = 0.01;
    let g_price = (call(s0 + h, k, r, q, s, t) - 2.0 * c + call(s0 - h, k, r, q, s, t)) / (h * h);
    let g_delta = (delta(s0 + h, k, r, q, s, t) - delta(s0 - h, k, r, q, s, t)) / (2.0 * h);
    let g_put = (put(s0 + h, k, r, q, s, t) - 2.0 * put(s0, k, r, q, s, t) + put(s0 - h, k, r, q, s, t)) / (h * h);
    let (mu, v) = (s0.ln() + (r - q - 0.5 * s * s) * t, s * t.sqrt());   // Road 5: log-price centre, spread
    let f_k = (-(k.ln() - mu).powi(2) / (2.0 * v * v)).exp() / (k * v * (2.0 * PI).sqrt());
    let g_density = (-r * t).exp() * (k / s0).powi(2) * f_k;
    let g_tree = tree_gamma(s0, k, r, q, s, t, 2000);
    let dt = 1e-4;                                                          // Road 7: the pricing equation
    let theta = -(call(s0, k, r, q, s, t + dt) - call(s0, k, r, q, s, t - dt)) / (2.0 * dt);
    let g_pde = (r * c - theta - (r - q) * s0 * dl) / (0.5 * s * s * s0 * s0);

    let d_up = delta(s0 + 5.0, k, r, q, s, t);
    let (up5, dn5) = (d_up - dl, delta(s0 - 5.0, k, r, q, s, t) - dl);
    let full5 = call(s0 + 5.0, k, r, q, s, t) - c - 5.0 * dl;
    let book = 10000.0;
    let (sh_before, sh_after) = (book * dl, book * d_up);
    let day = s0 * s * (1.0_f64 / 252.0).sqrt();
    let s_star = k * (-(r - q + 1.5 * s * s) * t).exp();
    let (mut best_g, mut best_s) = (0.0, 0.0);
    for i in 0..=8000 {
        let x = 60.0 + i as f64 / 100.0; let gx = gamma(x, k, r, q, s, t);
        if gx > best_g { best_g = gx; best_s = x; }
    }
    let g40 = gamma(s0, k, r, q, 0.40, t);
    let w3 = (-q * 0.25_f64).exp() * phi(((s0 / k).ln() + (r - q + 0.02) * 0.25) / (s * 0.25)) / (s0 * s * 0.25);

    let rows: Vec<(&str, f64)> = vec![
        ("d1", a), ("phi(d1)  bell height", phi(a)), ("e^-qT", (-q * t).exp()),
        ("call", c), ("delta", dl),
        ("1 formula", g), ("2 price bumped twice", g_price), ("3 delta bumped", g_delta),
        ("4 put bumped twice", g_put), ("5 density at the strike", g_density), ("  f(K)", f_k),
        ("6 tree, 2000 steps", g_tree), ("7 from the pricing equation", g_pde), ("  theta by bump", theta),
        ("delta at 105", d_up), ("delta shift +5, actual", up5),
        ("delta shift -5, actual", dn5), ("  gamma * 5", 5.0 * g),
        ("hedged P&L +5, full reprice", full5), ("  half gamma * 25", 0.5 * g * 25.0), ("  gamma * 25, no half", g * 25.0),
        ("book: shares before", sh_before), ("  shares after +5", sh_after), ("  shares to buy", sh_after - sh_before),
        ("  dollars spent at 105", (sh_after - sh_before) * 105.0), ("  book loss, full reprice", book * full5),
        ("daily 1-sd move, dollars", day), ("  shares per daily move", book * g * day),
        ("peak S*, formula", s_star), ("  peak S*, scan by cents", best_s), ("  gamma at the peak", best_g),
        ("gamma, sigma = 0.40", g40), ("  ratio to sigma = 0.20", g40 / g),
        ("wrong: N(d1) for phi(d1)", (-q * t).exp() * n_cdf(a) / (s0 * s * t.sqrt())),
        ("wrong: phi(d2) for phi(d1)", (-q * t).exp() * phi(a - s) / (s0 * s * t.sqrt())),
        ("wrong: S missing downstairs", (-q * t).exp() * phi(a) / (s * t.sqrt())),
        ("wrong: sigma*T, 3 months", w3), ("  right, 3 months", gamma(s0, k, r, q, s, 0.25)),
        ("try: T = 1 week", gamma(s0, k, r, q, s, 1.0 / 52.0)),
    ];
    for (name, x) in &rows { println!("{:<30} {:>14.6}", name, x); }

    println!("\ntime left   gamma@100  gamma@95  shares/$1 at 100");
    for (lab, tt) in [("12 months", 1.0), ("6 months", 0.5), ("3 months", 0.25), ("1 month", 1.0 / 12.0),
                      ("1 week", 1.0 / 52.0), ("1 day", 1.0 / 365.0)] {
        let g100 = gamma(s0, k, r, q, s, tt);
        println!("{:<10} {:>10.4} {:>9.4} {:>10.0}", lab, g100, gamma(95.0, k, r, q, s, tt), book * g100);
    }

    let xs: Vec<f64> = (0..13).map(|i| 70.0 + 5.0 * i as f64).collect();
    let line = |f: &dyn Fn(f64) -> f64, p: usize| xs.iter().map(|&x| format!("{:>6.*}", p, f(x))).collect::<Vec<_>>().join(" ");
    println!("\nchart, Acme price  {}", xs.iter().map(|x| format!("{:>6}", *x as i64)).collect::<Vec<_>>().join(" "));
    for (lab, sg, tt) in [("gamma x100 20% 1y", 0.20, 1.0), ("gamma x100 40% 1y", 0.40, 1.0), ("gamma x100 20% 3m", 0.20, 0.25)] {
        println!("{:<19}{}", lab, line(&|x| 100.0 * gamma(x, k, r, q, sg, tt), 2));
    }
    println!("call, 1y left      {}", line(&|x| call(x, k, r, q, s, t), 2));
    println!("hedge line         {}", line(&|x| c + dl * (x - s0), 2));

    assert!((g - 0.018950578755).abs() < 1e-11, "formula vs the house number");
    assert!((g_price - g).abs() < 1e-7, "price bumped twice");
    let g3: Vec<f64> = [h, 0.0, -h].iter().map(|e| call(s0 + e, k, r, q, s, 0.25)).collect();
    assert!(((g3[0] - 2.0 * g3[1] + g3[2]) / (h * h) - gamma(s0, k, r, q, s, 0.25)).abs() < 1e-7, "3 months, bumped twice");
    assert!((g_put - g).abs() < 1e-7, "put gamma equals call gamma");
    assert!((g_density - g).abs() < 1e-12, "density at the strike, no d1 used");
    assert!((g_tree - g).abs() < 1e-4, "tree within a ten-thousandth");
    assert!((g_pde - g).abs() < 1e-6, "gamma from theta and delta");
    assert!((best_s - s_star).abs() < 0.01, "hump peaks at S*");
    assert!((full5 - 0.5 * g * 25.0).abs() / full5 < 0.05, "half gamma m^2 within 5% at a 5-dollar move");
    assert!(g40 / g > 0.45 && g40 / g < 0.55, "doubling vol about halves gamma at the strike");
    println!("ALL CHECKS PASS");
}
