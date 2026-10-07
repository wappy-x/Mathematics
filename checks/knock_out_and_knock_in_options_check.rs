// Knock-out and knock-in options -- the same check as the Python, in Rust.  No crates.
// House market: S = K = 100, r = 5%, q = 2%, sigma = 20%, one year; barrier H = 80 below.
// Four roads to the down-and-out call: the reflection formula, a Simpson integral over the
// surviving-path density, a finite-difference grid that knows nothing of mirrors, and a
// 10,000-path daily simulation.  The normal CDF, integrator, solver and random numbers are here.
use std::f64::consts::PI;

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }
fn n_cdf(x: f64) -> f64 {                                          // bell-curve area, by its power series
    if x < -9.0 { return 0.0; }
    if x > 9.0 { return 1.0; }
    let (mut term, mut s, mut k) = (x, x, 0);
    while k < 400 && term.abs() > 1e-17 * s.abs() { k += 1; term *= x * x / (2 * k + 1) as f64; s += term; }
    0.5 + phi(x) * s
}
fn call(s: f64, k: f64, r: f64, q: f64, v: f64, t: f64) -> f64 {
    let d1 = ((s / k).ln() + (r - q + 0.5 * v * v) * t) / (v * t.sqrt());
    let d2 = d1 - v * t.sqrt();
    s * (-q * t).exp() * n_cdf(d1) - k * (-r * t).exp() * n_cdf(d2)
}
fn weight(s: f64, h: f64, r: f64, q: f64, v: f64) -> f64 { (h / s).powf(2.0 * (r - q - 0.5 * v * v) / (v * v)) }
fn d_in(s: f64, k: f64, h: f64, r: f64, q: f64, v: f64, t: f64) -> f64 { weight(s, h, r, q, v) * call(h * h / s, k, r, q, v, t) }
fn d_out(s: f64, k: f64, h: f64, r: f64, q: f64, v: f64, t: f64) -> f64 { call(s, k, r, q, v, t) - d_in(s, k, h, r, q, v, t) }

fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    s * h / 3.0
}

fn by_density(s: f64, k: f64, h: f64, r: f64, q: f64, v: f64, t: f64) -> (f64, f64) {
    // Road 2: average the payoff over where log-price ends, split into untouched and touched paths.
    let (nu, sd, b) = (r - q - 0.5 * v * v, v * t.sqrt(), (h / s).ln());
    let p = |x: f64| phi((x - nu * t) / sd) / sd;
    let pay = |x: f64| s * x.exp() - k;
    let (lo, hi) = ((k / s).ln(), (k / s).ln() + 12.0 * sd);
    let touched = simpson(|x| pay(x) * (2.0 * nu * b / (v * v)).exp() * p(x - 2.0 * b), lo, hi, 20000);
    let alive = simpson(|x| pay(x) * p(x), lo, hi, 20000) - touched;
    ((-r * t).exp() * alive, (-r * t).exp() * touched)
}

fn by_grid(s: f64, k: f64, h: f64, r: f64, q: f64, v: f64, t: f64) -> (f64, f64) {
    // Road 3: the pricing equation on a grid in ln S, value held at 0 on the barrier.  No mirror.
    let (below, m, steps) = (50usize, 400usize, 500usize);
    let dx = (s / h).ln() / below as f64; let dt = t / steps as f64; let nu = r - q - 0.5 * v * v;
    let xs: Vec<f64> = (0..=m).map(|i| h.ln() + i as f64 * dx).collect();
    let mut vv: Vec<f64> = xs.iter().map(|x| (x.exp() - k).max(0.0)).collect();
    let a = 0.5 * v * v / (dx * dx) - 0.5 * nu / dx;
    let c = 0.5 * v * v / (dx * dx) + 0.5 * nu / dx;
    let bb = -v * v / (dx * dx) - r;
    for n in 0..steps {
        let th = if n < 4 { 1.0 } else { 0.5 };                    // four plain steps smooth the kink
        let tau = (n + 1) as f64 * dt;
        let mut rhs: Vec<f64> = (1..m).map(|i| vv[i] + (1.0 - th) * dt * (a * vv[i - 1] + bb * vv[i] + c * vv[i + 1])).collect();
        let top = (xs[m] - q * tau).exp() - k * (-r * tau).exp();
        let last = rhs.len() - 1; rhs[last] += th * dt * c * top;
        let (lo, di, up) = (-th * dt * a, 1.0 - th * dt * bb, -th * dt * c);
        let (mut cp, mut dp) = (vec![0.0; m - 1], vec![0.0; m - 1]);   // Thomas algorithm
        for i in 0..m - 1 {
            let den = di - if i > 0 { lo * cp[i - 1] } else { 0.0 };
            cp[i] = up / den; dp[i] = (rhs[i] - if i > 0 { lo * dp[i - 1] } else { 0.0 }) / den;
        }
        for i in (0..m - 1).rev() { vv[i + 1] = dp[i] - if i < m - 2 { cp[i] * vv[i + 2] } else { 0.0 }; }
        vv[0] = 0.0; vv[m] = top;
    }
    (vv[below], (vv[below + 1] - vv[below - 1]) / (xs[below + 1].exp() - xs[below - 1].exp()))
}

fn by_simulation(s: f64, k: f64, h: f64, r: f64, q: f64, v: f64, t: f64) -> Vec<(f64, f64)> {
    // Road 4: simulate daily closes.  Count a knock-out at a close below H (the daily contract),
    // and separately weight each path by the chance it slipped under H between closes (continuous).
    let (paths, days) = (10000usize, 252usize);
    let mut state: u64 = 20260924;
    let mut unif = || {                                              // splitmix64, written out
        state = state.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = state;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 * 2f64.powi(-53) + 2f64.powi(-54)
    };
    let dt = t / days as f64; let mu = (r - q - 0.5 * v * v) * dt; let sd = v * dt.sqrt(); let hl = (h / s).ln();
    let disc = (-r * t).exp();
    let mut sums = [[0.0f64; 2]; 5];
    for _ in 0..paths {
        let (mut x, mut daily_alive, mut surv, mut z2): (f64, f64, f64, Option<f64>) = (0.0, 1.0, 1.0, None);
        for _ in 0..days {
            let z = match z2.take() {
                Some(zz) => zz,
                None => {
                    let (u1, u2) = (unif(), unif()); let rad = (-2.0 * u1.ln()).sqrt();
                    z2 = Some(rad * (2.0 * PI * u2).sin()); rad * (2.0 * PI * u2).cos()
                }
            };
            let nx = x + mu + sd * z;
            if nx <= hl { daily_alive = 0.0; surv = 0.0; }
            else if surv > 0.0 { surv *= 1.0 - (-2.0 * (x - hl) * (nx - hl) / (v * v * dt)).exp(); }
            x = nx;
        }
        let pay = disc * (s * x.exp() - k).max(0.0);
        for (j, y) in [pay, pay * daily_alive, pay * surv, pay * (daily_alive - surv), pay * (1.0 - surv)].iter().enumerate() {
            sums[j][0] += y; sums[j][1] += y * y;
        }
    }
    let pn = paths as f64;
    sums.iter().map(|[s1, s2]| (s1 / pn, ((s2 / pn - (s1 / pn) * (s1 / pn)) / (pn - 1.0)).sqrt())).collect()
}

fn line(label: &str, vals: &[f64], width: usize, dp: usize) -> String {
    let mut out = String::from(label);
    for x in vals { out.push_str(&format!("{:>w$.p$}", x, w = width, p = dp)); }
    out
}

fn main() {
    let (s, k, h, r, q, v, t) = (100.0f64, 100.0f64, 80.0f64, 0.05f64, 0.02f64, 0.20f64, 1.0f64);
    let nu = r - q - 0.5 * v * v;
    let (c, w, img) = (call(s, k, r, q, v, t), weight(s, h, r, q, v), h * h / s);
    let (dout, din) = (d_out(s, k, h, r, q, v, t), d_in(s, k, h, r, q, v, t));
    let bgk = d_out(s, k, h * (-0.5826 * v * (t / 252.0).sqrt()).exp(), r, q, v, t) - dout;
    let (do_int, di_int) = by_density(s, k, h, r, q, v, t);
    let (do_grid, delta_grid) = by_grid(s, k, h, r, q, v, t);
    let mc = by_simulation(s, k, h, r, q, v, t);
    let fo = |x: f64| d_out(x, k, h, r, q, v, t); let fc = |x: f64| call(x, k, r, q, v, t);
    let rows: Vec<(&str, f64)> = vec![("drift of ln S, nu = r - q - sigma^2/2", nu), ("exponent 2 nu / sigma^2", 2.0 * nu / (v * v)),
        ("reflection weight (H/S)^(2nu/sigma^2)", w), ("image spot H^2/S", img),
        ("vanilla call C(100)", c), ("image call C(64)", call(img, k, r, q, v, t)),
        ("1 down-and-in, formula", din), ("1 down-and-out, formula", dout), ("  in + out", din + dout),
        ("2 down-and-out, density integral", do_int), ("2 down-and-in, density integral", di_int),
        ("3 down-and-out, grid, no mirror", do_grid), ("  grid out + integral in", do_grid + di_int),
        ("4 vanilla, simulation", mc[0].0), ("  its error bar (1 s.e.)", mc[0].1),
        ("4 out, daily closes", mc[1].0), ("  its error bar (1 s.e.)", mc[1].1),
        ("4 in, daily closes = vanilla - out", mc[0].0 - mc[1].0),
        ("4 out, continuous (bridge)", mc[2].0), ("  its error bar (1 s.e.)", mc[2].1),
        ("4 in, continuous (bridge)", mc[4].0), ("  its error bar (1 s.e.)", mc[4].1),
        ("4 daily minus continuous, same paths", mc[3].0), ("  its error bar (1 s.e.)", mc[3].1), ("  shifted-barrier estimate", bgk),
        ("greek: delta out, bump", (fo(s + 0.01) - fo(s - 0.01)) / 0.02), ("greek: delta out, grid", delta_grid),
        ("greek: delta vanilla", (fc(s + 0.01) - fc(s - 0.01)) / 0.02),
        ("greek: gamma out", (fo(s + 0.1) - 2.0 * fo(s) + fo(s - 0.1)) / 0.01),
        ("greek: gamma vanilla", (fc(s + 0.1) - 2.0 * fc(s) + fc(s - 0.1)) / 0.01),
        ("greek: vega out, per vol point", (d_out(s, k, h, r, q, 0.21, t) - d_out(s, k, h, r, q, 0.19, t)) / 2.0),
        ("greek: vega vanilla, per vol point", (call(s, k, r, q, 0.21, t) - call(s, k, r, q, 0.19, t)) / 2.0),
        ("wrong: weight left out", c - call(img, k, r, q, v, t)),
        ("wrong: exponent with +sigma^2/2", c - (h / s).powf(2.0 * (r - q + 0.5 * v * v) / (v * v)) * call(img, k, r, q, v, t)),
        ("wrong: image at H, not H^2/S", c - w * call(h, k, r, q, v, t)),
        ("wrong: only the end price checked", c),
        ("try: H = 90", d_out(s, k, 90.0, r, q, v, t)), ("try: sigma = 0.30, H = 80", d_out(s, k, h, r, q, 0.3, t)),
        ("try: S = 85, out", d_out(85.0, k, h, r, q, v, t)), ("try: S = 85, in", d_in(85.0, k, h, r, q, v, t))];
    for (name, val) in &rows { println!("{:<40} {:>12.6}", name, val); }
    let bars = [60.0, 70.0, 80.0, 90.0, 95.0, 99.0];
    println!("{}", line("bars, barrier H :", &bars, 8, 0));
    println!("{}", line("bars, out price :", &bars.map(|b| d_out(s, k, b, r, q, v, t)), 8, 2));
    let sp: Vec<f64> = (0..11).map(|i| 80.0 + 5.0 * i as f64).collect();
    println!("{}", line("chart, spot     :", &sp, 7, 0));
    println!("{}", line("chart, vanilla  :", &sp.iter().map(|&x| call(x, k, r, q, v, t)).collect::<Vec<_>>(), 7, 2));
    println!("{}", line("chart, out      :", &sp.iter().map(|&x| d_out(x, k, h, r, q, v, t)).collect::<Vec<_>>(), 7, 2));
    println!("{}", line("chart, in       :", &sp.iter().map(|&x| d_in(x, k, h, r, q, v, t)).collect::<Vec<_>>(), 7, 2));
    let se: Vec<f64> = (0..9).map(|i| 60.0 + 10.0 * i as f64).collect();
    println!("{}", line("payoff, S_T     :", &se, 7, 0));
    println!("{}", line("payoff, alive   :", &se.iter().map(|&x| (x - k).max(0.0)).collect::<Vec<_>>(), 7, 0));
    assert!((dout - 9.133306436498).abs() < 1e-9, "formula vs the card's worked number");
    assert!((do_int - dout).abs() < 1e-7, "density integral vs the reflection formula, out");
    assert!((di_int - din).abs() < 1e-7, "density integral vs the reflection formula, in");
    assert!((do_grid - dout).abs() < 2e-3, "grid with no mirror vs the formula");
    assert!((do_grid + di_int - c).abs() < 2e-3, "in-out parity from two independent roads");
    assert!((mc[2].0 - dout).abs() < 3.0 * mc[2].1, "continuous simulated out within 3 error bars of the formula");
    assert!((mc[4].0 - din).abs() < 3.0 * mc[4].1, "continuous simulated in within 3 error bars of the formula");
    assert!((mc[3].0 - bgk).abs() < 2.0 * mc[3].1 && 2.0 * mc[3].1 < mc[3].0, "daily premium: real, and within 2 error bars of the shifted barrier");
    println!("ALL CHECKS PASS");
}
