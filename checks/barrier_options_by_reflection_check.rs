// Knock-out and knock-in by reflection -- the same check as barrier_options_by_reflection_check.py.
// Standard library only, no crates.  House FX market: EURUSD 1.10, USD 5%, EUR 3%, vol 10%, one year,
// EUR call struck at 1.10, knocked out if EURUSD ever trades at 1.05 or lower.
// Compile: rustc --edition 2021 -O barrier_options_by_reflection_check.rs -o /tmp/<dir>/chk
use std::f64::consts::PI;

const S: f64 = 1.10; const K: f64 = 1.10; const H: f64 = 1.05;
const RD: f64 = 0.05; const RF: f64 = 0.03; const SIG: f64 = 0.10; const T: f64 = 1.0;
const PIP: f64 = 1e-4; const BETA: f64 = 0.5826;              // BETA = -zeta(1/2)/sqrt(2 pi), rounded

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }
fn n_cdf(x: f64) -> f64 {                                      // bell-curve area left of x, by its series
    if x < -9.0 { return 0.0; }
    if x > 9.0 { return 1.0; }
    let (mut term, mut total, mut k) = (x, x, 0.0);
    while term.abs() > 1e-17 * total.abs() { k += 1.0; term *= x * x / (2.0 * k + 1.0); total += term; }
    0.5 + phi(x) * total
}
fn call(s: f64, k: f64, sig: f64, t: f64, rd: f64, rf: f64) -> f64 {   // Garman-Kohlhagen EUR call
    let v = sig * t.sqrt();
    let d1 = ((s / k).ln() + (rd - rf + 0.5 * sig * sig) * t) / v;
    s * (-rf * t).exp() * n_cdf(d1) - k * (-rd * t).exp() * n_cdf(d1 - v)
}
fn lam(sig: f64, rd: f64, rf: f64) -> f64 { (rd - rf - 0.5 * sig * sig) / (sig * sig) }
fn dao(s: f64, k: f64, h: f64, sig: f64, t: f64, rd: f64, rf: f64) -> f64 {   // Road 1
    if s <= h { return 0.0; }
    call(s, k, sig, t, rd, rf) - (h / s).powf(2.0 * lam(sig, rd, rf)) * call(h * h / s, k, sig, t, rd, rf)
}
fn dai_rr(s: f64, k: f64, h: f64, sig: f64) -> f64 {           // Road 3: knock-in, the other lambda
    let l = (RD - RF + 0.5 * sig * sig) / (sig * sig);
    let v = sig * T.sqrt();
    let y = (h * h / (s * k)).ln() / v + l * v;
    s * (-RF * T).exp() * (h / s).powf(2.0 * l) * n_cdf(y) - k * (-RD * T).exp() * (h / s).powf(2.0 * l - 2.0) * n_cdf(y - v)
}
fn c0(s: f64) -> f64 { call(s, K, SIG, T, RD, RF) }
fn o0(s: f64, h: f64) -> f64 { dao(s, K, h, SIG, T, RD, RF) }

fn two_humps(n: usize) -> f64 {                                // Road 2: reflected density, no N, no d1
    let (nu, v2, b) = (RD - RF - 0.5 * SIG * SIG, SIG * SIG * T, (H / S).ln());
    let f = |y: f64| {
        let dens = ((-(y - nu * T).powi(2) / (2.0 * v2)).exp() - (2.0 * nu * b / (SIG * SIG)).exp()
            * (-(y - 2.0 * b - nu * T).powi(2) / (2.0 * v2)).exp()) / (2.0 * PI * v2).sqrt();
        (S * y.exp() - K) * dens
    };
    let (lo, hi) = ((K / S).ln(), nu * T + 12.0 * SIG * T.sqrt());
    let h = (hi - lo) / n as f64;
    let mut tot = f(lo) + f(hi);
    for i in 1..n { tot += if i % 2 == 1 { 4.0 } else { 2.0 } * f(lo + i as f64 * h); }
    (-RD * T).exp() * tot * h / 3.0
}

fn lattice(n: usize) -> f64 {                                  // Road 4: the n-date contract on a log grid
    let (per, m) = (40usize, 800usize);
    let (dx, dt) = ((S / H).ln() / per as f64, T / n as f64);
    let (s, mu) = (SIG * dt.sqrt(), (RD - RF - 0.5 * SIG * SIG) * dt);
    let w: Vec<f64> = (0..=m).map(|i| if i == 0 || i == m { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 } * dx / 3.0).collect();
    let wd = (9.0 * s / dx) as i64 + 2;
    let ker: Vec<f64> = (-wd..=wd).map(|d| phi((d as f64 * dx - mu) / s) / s).collect();
    let mut v: Vec<f64> = (0..=m).map(|i| (H * (i as f64 * dx).exp() - K).max(0.0)).collect();
    let (disc, wu) = ((-RD * dt).exp(), wd as usize);
    for _ in 0..n {
        let mut u = vec![0.0; m + 1 + 2 * wu];
        for i in 0..=m { u[i + wu] = w[i] * v[i]; }
        v = (0..=m).map(|i| disc * ker.iter().zip(&u[i..i + 2 * wu + 1]).map(|(a, b)| a * b).sum::<f64>()).collect();
    }
    v[per]
}

fn mc(npairs: usize, n: usize, seed: u64) -> ([(f64, f64); 3], f64) {   // Road 5: simulated daily paths
    let (mut st, dt) = (seed, T / n as f64);
    let (mu, s, c) = ((RD - RF - 0.5 * SIG * SIG) * dt, SIG * dt.sqrt(), 2.0 / (SIG * SIG * dt));
    let (disc, mut acc, mut knocked) = ((-RD * T).exp(), [0.0f64; 6], 0usize);
    let mut u = || {
        st = st.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
        ((st >> 11) as f64 + 0.5) / 9007199254740992.0
    };
    for _ in 0..npairs {
        let mut zs: Vec<f64> = Vec::with_capacity(n + 1);
        while zs.len() < n {                                   // Box-Muller
            let r = (-2.0 * u().ln()).sqrt();
            let a = 2.0 * PI * u();
            zs.push(r * a.cos()); zs.push(r * a.sin());
        }
        let mut est = [[0.0f64; 3]; 2];
        for (e, sg) in [s, -s].iter().enumerate() {            // each path and its mirror-image twin
            let (mut y, mut surv, mut alive) = ((S / H).ln(), 1.0f64, true);
            for z in &zs {
                let yn = y + mu + sg * z;
                if yn <= 0.0 { alive = false; surv = 0.0; break; }
                surv *= 1.0 - (-c * y * yn).exp(); y = yn;
            }
            let pay = if alive { disc * (H * y.exp() - K).max(0.0) } else { 0.0 };
            est[e] = [pay * surv, pay, pay - pay * surv];
            if !alive { knocked += 1; }
        }
        for j in 0..3 { let a = 0.5 * (est[0][j] + est[1][j]); acc[j] += a; acc[j + 3] += a * a; }
    }
    let np = npairs as f64;
    let mut res = [(0.0, 0.0); 3];
    for j in 0..3 { let m = acc[j] / np; res[j] = (m, ((acc[j + 3] / np - m * m) / np).sqrt()); }
    (res, knocked as f64 / (2.0 * np))
}

fn main() {
    let (van, out, mirror, wgt) = (c0(S), o0(S, H), c0(H * H / S), (H / S).powf(2.0 * lam(SIG, RD, RF)));
    let (humps, inn) = (two_humps(2000), dai_rr(S, K, H, SIG));
    let (a, nu) = ((S / H).ln(), RD - RF - 0.5 * SIG * SIG);
    let touch = n_cdf((-a - nu * T) / (SIG * T.sqrt())) + wgt * n_cdf((-a + nu * T) / (SIG * T.sqrt()));
    let dates = [12usize, 52, 252];
    let lat: Vec<f64> = dates.iter().map(|&n| lattice(n)).collect();
    let walls: Vec<f64> = dates.iter().map(|&n| H * (-BETA * SIG * (T / n as f64).sqrt()).exp()).collect();
    let bgk: Vec<f64> = walls.iter().map(|&w| o0(S, w)).collect();
    let bgk_up = o0(S, H * (BETA * SIG * (T / 252.0).sqrt()).exp());
    let (sims, knocked) = mc(100000, 252, 20260927);
    let [(mc_c, se_c), (mc_d, se_d), (gap, se_g)] = sims;
    let mc_daily = out + gap;
    let greek = |f: &dyn Fn(f64, f64) -> f64| ((f(S + 1e-4, SIG) - f(S - 1e-4, SIG)) / 2e-4,
                                                (f(S, SIG + 0.005) - f(S, SIG - 0.005)) / PIP);
    let g_v = greek(&|s, sg| call(s, K, sg, T, RD, RF));
    let g_o = greek(&|s, sg| dao(s, K, H, sg, T, RD, RF));
    let g_i = greek(&|s, sg| dai_rr(s, K, H, sg));

    let rows: Vec<(&str, Vec<f64>)> = vec![
        ("nu, drift of log EURUSD", vec![nu]), ("lambda", vec![lam(SIG, RD, RF)]), ("weight (H/S)^(2 lambda)", vec![wgt]), ("mirror spot H^2/S", vec![H * H / S]),
        ("1 vanilla C(S)", vec![van]), ("  mirror call C(H^2/S)", vec![mirror]), ("  weighted mirror", vec![wgt * mirror]),
        ("1 down-and-out, formula", vec![out]), ("2 down-and-out, two humps", vec![humps]),
        ("3 down-and-in, other lambda", vec![inn]), ("  in + out", vec![inn + out]),
        ("  touch chance, continuous", vec![touch]), ("  BGK beta, rounded", vec![BETA]),
        ("4 lattice, 12 / 52 / 252 dates", lat.clone()), ("  BGK wall, 12 / 52 / 252", walls.clone()),
        ("  BGK price, 12 / 52 / 252", bgk.clone()),
        ("5 MC continuous, std error", vec![mc_c, se_c]), ("  MC daily raw, std error", vec![mc_d, se_d]),
        ("  paired gap, std error", vec![gap, se_g]), ("  MC daily = formula + gap", vec![mc_daily]),
        ("  knocked out at a close", vec![knocked]),
        ("pips: daily - continuous", vec![(lat[2] - out) / PIP]), ("pips: BGK - lattice, 252", vec![(bgk[2] - lat[2]) / PIP]),
        ("pips: BGK - MC daily", vec![(bgk[2] - mc_daily) / PIP]), ("pips: BGK - lattice, 12", vec![(bgk[0] - lat[0]) / PIP]),
        ("wrong: barrier ignored", vec![van]), ("wrong: weight dropped", vec![van - mirror]),
        ("wrong: lambda with +sigma^2/2", vec![van - (H / S).powf(2.0 * lam(SIG, RD, RF) + 2.0) * mirror]),
        ("wrong: mirror at H, not H^2/S", vec![van - wgt * c0(H)]), ("wrong: EUR rate left out", vec![dao(S, K, H, SIG, T, RD, 0.0)]),
        ("wrong: wall shifted up, 252", vec![bgk_up]),
        ("delta: vanilla / out / in", vec![g_v.0, g_o.0, g_i.0]),
        ("vega pips/pt: vanilla / out / in", vec![g_v.1, g_o.1, g_i.1]),
        ("try: H = 1.08, out / in", vec![o0(S, 1.08), dai_rr(S, K, 1.08, SIG)]), ("try: H = 1.00, out", vec![o0(S, 1.00)]),
        ("try: sigma 0.15, vanilla / out", vec![call(S, K, 0.15, T, RD, RF), dao(S, K, H, 0.15, T, RD, RF)]),
        ("try: T = 3, vanilla / out", vec![call(S, K, SIG, 3.0, RD, RF), dao(S, K, H, SIG, 3.0, RD, RF)]),
    ];
    for (name, vals) in &rows {
        let cells: String = vals.iter().map(|v| format!("{:>12.6}", v)).collect();
        println!("{:<33}{}", name, cells);
    }
    println!();
    let xs: Vec<f64> = (0..16).map(|i| 1.05 + 0.01 * i as f64).collect();
    let charts: [(&str, &dyn Fn(f64) -> f64); 5] = [
        ("chart, EURUSD", &|x| x), ("chart, vanilla pips", &|x| c0(x) / PIP),
        ("chart, knock-out pips", &|x| o0(x, H) / PIP), ("chart, knock-in pips", &|x| dai_rr(x, K, H, SIG) / PIP),
        ("chart, payoff untouched", &|x| (x - K).max(0.0) / PIP)];
    for (name, f) in charts.iter() {
        let cells: String = xs.iter().map(|&x| format!("{:>8.2}", f(x))).collect();
        println!("{:<24}{}", name, cells);
    }

    assert!((out - 0.041661).abs() < 5e-7, "formula vs the shelf's house number");
    assert!((humps - out).abs() < 1e-10, "reflected-density integral lands on the formula");
    assert!((inn + out - van).abs() < 1e-12, "in-out parity with a knock-in written in the other lambda");
    assert!((mc_c - out).abs() < 3.0 * se_c, "bridge-weighted simulation finds the continuous price");
    assert!((mc_daily - lat[2]).abs() < 3.0 * se_g, "simulated daily price agrees with the lattice");
    assert!((bgk[2] - lat[2]).abs() < PIP, "BGK shift within a pip of the exact daily price");
    assert!(lat[0] > lat[1] && lat[1] > lat[2] && lat[2] > out, "fewer looks, fewer knock-outs, dearer option");
    assert!((bgk_up - lat[2]).abs() > (out - lat[2]).abs(), "shifting the wall the wrong way is worse than no shift");
    println!("ALL CHECKS PASS");
}
