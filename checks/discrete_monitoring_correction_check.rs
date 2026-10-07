// Daily monitoring of a barrier: the Broadie-Glasserman-Kou shift, checked three ways.
// Std only, no crates.  Rust has no erf, so N(x) adds up thin slices under the bell curve
// (Simpson).  Same random numbers as the Python check: a 64-bit LCG and Box-Muller.
use std::f64::consts::PI;

const S: f64 = 100.0; const K: f64 = 100.0; const R: f64 = 0.05; const Q: f64 = 0.02;
const SIGMA: f64 = 0.20; const T: f64 = 1.0; const H: f64 = 80.0; const DAYS: usize = 252;

fn n_cdf(x: f64) -> f64 {
    let n = 2000; let h = x / n as f64;
    let phi = |u: f64| (-0.5 * u * u).exp() / (2.0 * PI).sqrt();
    let mut s = phi(0.0) + phi(x);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * phi(i as f64 * h); }
    0.5 + s * h / 3.0
}

fn call(s: f64, k: f64) -> f64 {
    let v = SIGMA * T.sqrt();
    let d1 = ((s / k).ln() + (R - Q + 0.5 * SIGMA * SIGMA) * T) / v;
    s * (-Q * T).exp() * n_cdf(d1) - k * (-R * T).exp() * n_cdf(d1 - v)
}

fn lam() -> f64 { (R - Q - 0.5 * SIGMA * SIGMA) / (SIGMA * SIGMA) }
fn doc(h: f64) -> f64 { call(S, K) - (h / S).powf(2.0 * lam()) * call(h * h / S, K) }

fn beta_from_zeta(terms: usize) -> (f64, f64) {
    let mut sums = Vec::new(); let mut total = 0.0;
    for n in 1..=terms {
        let sign = if n % 2 == 1 { 1.0 } else { -1.0 };
        total += sign / (n as f64).sqrt(); sums.push(total);
    }
    while sums.len() > 1 { sums = sums.windows(2).map(|w| 0.5 * (w[0] + w[1])).collect(); }
    let zeta = sums[0] / (1.0 - 2f64.sqrt());
    (zeta, -zeta / (2.0 * PI).sqrt())
}

fn beta_from_integral(x_max: f64, n: usize) -> f64 {   // the same constant as an integral (Siegmund)
    let f = |x: f64| if x == 0.0 { -0.25 } else { (-2.0 * (-x * x / 2.0).exp_m1() / (x * x)).ln() / (x * x) };
    let h = x_max / n as f64;
    let mut body = f(0.0) + f(x_max);
    for i in 1..n { body += if i % 2 == 1 { 4.0 } else { 2.0 } * f(i as f64 * h); }
    -(body * h / 3.0 + (2f64.ln() - 2.0 * x_max.ln() - 2.0) / x_max) / PI
}

fn bridge_dip(a_close: f64, b_close: f64, dt: f64) -> f64 {   // chance of a dip to H between closes
    (-2.0 * (a_close / H).ln() * (b_close / H).ln() / (SIGMA * SIGMA * dt)).exp()
}

fn shifted(h: f64, span: f64, beta: f64) -> f64 { h * (-beta * SIGMA * span.sqrt()).exp() }

fn tree(h: f64, n: usize, every: usize, layer: bool) -> f64 {
    let dt = T / n as f64; let nu = R - Q - 0.5 * SIGMA * SIGMA; let lnh = (h / S).ln();
    let j = (lnh / (SIGMA * (3.0 * dt).sqrt())).round();
    let dx = if layer { lnh / j } else { lnh / (j + 0.5) };
    let a = (SIGMA * SIGMA * dt + nu * nu * dt * dt) / (dx * dx);
    let (pu, pd, pm) = (0.5 * (a + nu * dt / dx), 0.5 * (a - nu * dt / dx), 1.0 - a);
    let disc = (-R * dt).exp();
    let mut v: Vec<f64> = (0..=2 * n).map(|k| (S * ((k as f64 - n as f64) * dx).exp() - K).max(0.0)).collect();
    for step in (0..n).rev() {
        v = (0..v.len() - 2).map(|k| disc * (pd * v[k] + pm * v[k + 1] + pu * v[k + 2])).collect();
        if step > 0 && step % every == 0 {
            let top = j as i64 + step as i64 + 1;
            for k in 0..(top.max(0) as usize).min(v.len()) { v[k] = 0.0; }
        }
    }
    v[0]
}

fn simulate(m: usize, pairs: usize, seed: u64) -> (f64, f64, f64, f64, f64) {
    let mut x = seed; let dt = T / m as f64;
    let drift = (R - Q - 0.5 * SIGMA * SIGMA) * dt; let vol = SIGMA * dt.sqrt();
    let lnh = (H / S).ln(); let disc = (-R * T).exp();
    let (mut sy, mut sy2, mut sr, mut sr2, mut touched) = (0.0, 0.0, 0.0, 0.0, 0usize);
    let next = |x: &mut u64| {
        *x = x.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
        ((*x >> 11) as f64 + 0.5) / 2f64.powi(53)
    };
    for _ in 0..pairs {
        let (mut a, mut b, mut mina, mut minb) = (0.0f64, 0.0f64, 0.0f64, 0.0f64);
        for _ in 0..m / 2 {
            let u1 = next(&mut x); let u2 = next(&mut x);
            let (rad, th) = ((-2.0 * u1.ln()).sqrt(), 2.0 * PI * u2);
            for z in [rad * th.cos(), rad * th.sin()] {
                a += drift + vol * z; b += drift - vol * z;
                if a < mina { mina = a; }
                if b < minb { minb = b; }
            }
        }
        let (mut y, mut rr) = (0.0, 0.0);
        for (end, low) in [(a, mina), (b, minb)] {
            let pay = disc * (S * end.exp() - K).max(0.0);
            if low <= lnh { touched += 1; y -= 0.5 * pay; } else { rr += 0.5 * pay; }
        }
        sy += y; sy2 += y * y; sr += rr; sr2 += rr * rr;
    }
    let p = pairs as f64; let (my, mr) = (sy / p, sr / p);
    (call(S, K) + my, ((sy2 / p - my * my) / p).sqrt(), mr, ((sr2 / p - mr * mr) / p).sqrt(),
     touched as f64 / (2.0 * p))
}

fn touch_prob(h: f64) -> f64 {
    let (nu, b, v) = (R - Q - 0.5 * SIGMA * SIGMA, (h / S).ln(), SIGMA * T.sqrt());
    n_cdf((b - nu * T) / v) + (2.0 * nu * b / (SIGMA * SIGMA)).exp() * n_cdf((b + nu * T) / v)
}

fn main() {
    let day = T / DAYS as f64; let bb = 0.5826;
    let (zeta, beta) = beta_from_zeta(40);
    let beta_int = beta_from_integral(40.0, 4000);
    let cont = doc(H); let hd = shifted(H, day, bb); let bgk = doc(hd);
    let steps = 3276;
    let tree_daily = tree(H, steps, steps / DAYS, false);
    let tree_cont = tree(H, steps, 1, true);
    let (mc, mc_se, raw, raw_se, touch_daily) = simulate(DAYS, 100000, 20260924);
    let lm = 2.0 * lam();
    let mut rows: Vec<(String, f64)> = vec![
        ("zeta(1/2), by hand".into(), zeta), ("beta = -zeta(1/2)/sqrt(2 pi)".into(), beta),
        ("beta, by Siegmund's integral".into(), beta_int),
        ("dip chance, closes 81 then 81".into(), bridge_dip(81.0, 81.0, day)),
        ("dip chance, closes 82 then 82".into(), bridge_dip(82.0, 82.0, day)),
        ("one day's wiggle sigma sqrt(dt)".into(), SIGMA * day.sqrt()), ("shift beta sigma sqrt(dt)".into(), bb * SIGMA * day.sqrt()),
        ("shifted barrier, daily".into(), hd), ("2 lambda".into(), lm), ("(H*/S)^(2 lambda)".into(), (hd / S).powf(lm)), ("H*^2/S".into(), hd * hd / S),
        ("image call C(H*^2/S)".into(), call(hd * hd / S, K)), ("vanilla call".into(), call(S, K)),
        ("1 continuous formula, H = 80".into(), cont), ("2 BGK shifted formula, daily".into(), bgk),
        ("3 tree, checked daily".into(), tree_daily), ("4 simulation, daily, 200,000 paths".into(), mc), ("  std error".into(), mc_se),
        ("  raw average, no control".into(), raw), ("  std error, no control".into(), raw_se),
        ("5 tree, checked every step".into(), tree_cont), ("daily minus continuous".into(), bgk - cont),
        ("BGK minus daily tree".into(), bgk - tree_daily), ("down-and-in, daily".into(), call(S, K) - bgk), ("down-and-in, continuous".into(), call(S, K) - cont),
        ("touch chance, continuous at 80".into(), touch_prob(H)), ("touch rate, daily simulation".into(), touch_daily),
        ("touch chance, continuous at H*".into(), touch_prob(hd)),
    ];
    let (mut extra_bgk, mut extra_tree) = (Vec::new(), Vec::new());   // chart: cents above continuous
    for (months, label) in [(12usize, "monthly"), (52, "weekly")] {
        let hm = shifted(H, T / months as f64, bb);
        let (b_m, t_m) = (doc(hm), tree(H, steps, steps / months, false));
        rows.push((format!("shifted barrier, {}", label), hm));
        rows.push((format!("BGK, {}", label), b_m));
        rows.push((format!("tree, checked {}", label), t_m));
        extra_bgk.push(100.0 * (b_m - cont)); extra_tree.push(100.0 * (t_m - cont));
    }
    extra_bgk.extend([100.0 * (bgk - cont), 0.0]);
    extra_tree.extend([100.0 * (tree_daily - cont), 100.0 * (tree_cont - cont)]);
    let wrong_sign = doc(H * (bb * SIGMA * day.sqrt()).exp());
    let wrong_t = doc(shifted(H, T, bb));
    let node_daily = tree(H, steps, steps / DAYS, true);
    rows.push(("wrong: no shift".into(), cont));
    rows.push(("wrong: shift toward the spot".into(), wrong_sign));
    rows.push(("wrong: sigma sqrt(T), not sigma sqrt(dt)".into(), wrong_t));
    rows.push(("wrong: daily tree, barrier on a layer".into(), node_daily));
    rows.push(("try: beta = 1".into(), doc(shifted(H, day, 1.0))));
    rows.push(("try: H = 95, continuous".into(), doc(95.0)));
    rows.push(("try: H = 95, BGK daily".into(), doc(shifted(95.0, day, bb))));
    rows.push(("try: H = 95, tree daily".into(), tree(95.0, steps, steps / DAYS, false)));
    for (name, val) in &rows { println!("{:<42} {:>12.6}", name, val); }
    println!("chart, checks a year        12      52     252   every");
    let line = |v: &Vec<f64>| v.iter().map(|x| format!("{:8.2}", x)).collect::<String>();
    println!("chart, BGK cents  {}", line(&extra_bgk));
    println!("chart, tree cents {}", line(&extra_tree));

    assert!((call(S, K) - 9.227005508154).abs() < 1e-9, "house call must match the pilot");
    assert!((cont - 9.133306).abs() < 5e-7, "continuous down-and-out must match the barrier-formulas card");
    assert!((beta - 0.5826).abs() < 5e-5, "hand-built zeta must give the published constant");
    assert!((beta - beta_int).abs() < 1e-6, "zeta road and integral road to beta must agree");
    assert!((tree_cont - cont).abs() < 0.002, "a tree checked every step must land on the continuous formula");
    assert!((bgk - tree_daily).abs() < 0.001, "shifted formula vs a daily-checked tree");
    assert!((mc - bgk).abs() < 3.0 * mc_se, "shifted formula vs the daily simulation");
    assert!(mc - cont > 3.0 * mc_se, "daily checking must be worth measurably more than continuous");
    assert!((touch_daily - touch_prob(hd)).abs() < 0.003, "daily touch rate vs continuous touch at the shifted barrier");
    println!("ALL CHECKS PASS");
}
