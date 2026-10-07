// Double no-touch and double knock-out call -- the same check as the Python file, in Rust.  Std only.
// Roads: (1) image series, (2) sine-wave series, (3) Crank-Nicolson grid, (4) bridge-corrected simulation.
use std::f64::consts::PI;
const S: f64 = 1.10; const RD: f64 = 0.05; const RF: f64 = 0.03; const SIG: f64 = 0.10;
const T: f64 = 1.0; const L: f64 = 1.05; const U: f64 = 1.20; const K: f64 = 1.10;
fn n_cdf(x: f64) -> f64 {                              // bell-curve area left of x (Marsaglia's series)
    if x < -8.0 { return 0.0; } else if x > 8.0 { return 1.0; }
    let (mut term, mut tot, mut k) = (x, x, 0.0);
    while term.abs() > 1e-17 * tot.abs() { k += 1.0; term *= x * x / (2.0 * k + 1.0); tot += term; }
    0.5 + tot * (-0.5 * x * x).exp() / (2.0 * PI).sqrt()
}
#[derive(Clone, Copy)] struct Mkt { s: f64, t: f64, l: f64, u: f64, sig: f64 }
const M0: Mkt = Mkt { s: S, t: T, l: L, u: U, sig: SIG };
// road 1: discounted (cash leg, asset leg) for survival inside (l, u) and log(S_T/S) in (lo, hi)
fn images(m: Mkt, lo: f64, hi: f64, jmax: usize) -> (f64, f64) {
    let (sig, t) = (m.sig, m.t); let nu = RD - RF - 0.5 * sig * sig; let s2 = sig * sig * t;
    let (a, b) = ((m.l / m.s).ln(), (m.u / m.s).ln()); let w = b - a;
    let mut out = [0.0f64; 2];
    for j in 0..=jmax {
        let jf = j as f64;
        let imgs: Vec<(f64, f64)> = if j == 0 { vec![(0.0, 1.0)] }
            else if j % 2 == 1 { vec![(2.0 * b + (jf - 1.0) * w, -1.0), (2.0 * a - (jf - 1.0) * w, -1.0)] }
            else { vec![(jf * w, 1.0), (-jf * w, 1.0)] };
        for &(c, sg) in &imgs {
            for e in 0..2 {                                   // e = 1 weights each outcome by S_T / S
                let al = nu / (sig * sig) + e as f64; let mm = c + al * s2;
                out[e] += sg * (al * c + 0.5 * al * al * s2).exp()
                    * (n_cdf((hi - mm) / s2.sqrt()) - n_cdf((lo - mm) / s2.sqrt()));
            }
        }
    }
    let f = (-RD * t - nu * nu * t / (2.0 * sig * sig)).exp();
    (f * out[0], f * m.s * out[1])
}
fn dnt_j(m: Mkt, jmax: usize) -> f64 {
    if m.s <= m.l || m.s >= m.u { return 0.0; }
    images(m, (m.l / m.s).ln(), (m.u / m.s).ln(), jmax).0
}
fn dko_j(m: Mkt, jmax: usize) -> f64 {
    if m.s <= m.l || m.s >= m.u { return 0.0; }
    let (cash, asset) = images(m, (K.max(m.l) / m.s).ln(), (m.u / m.s).ln(), jmax); asset - K * cash
}
fn dnt(m: Mkt) -> f64 { dnt_j(m, 8) }  fn dko(m: Mkt) -> f64 { dko_j(m, 8) }
fn dnt_sine(modes: usize) -> f64 {                     // road 2: heat-equation modes that vanish at both walls
    let nu = RD - RF - 0.5 * SIG * SIG; let be = nu / (SIG * SIG);
    let (a, w, mut tot) = ((L / S).ln(), (U / L).ln(), 0.0);
    for k in 1..=modes {
        let (m, sgn) = (k as f64 * PI / w, if k % 2 == 1 { -1.0 } else { 1.0 });
        tot += (2.0 / w) * (-m * a).sin() * (-0.5 * m * m * SIG * SIG * T).exp() * m * (1.0 - sgn * (be * w).exp()) / (be * be + m * m);
    }
    (-RD * T - nu * nu * T / (2.0 * SIG * SIG) + be * a).exp() * tot
}
fn grid<F: Fn(f64) -> f64>(payoff: F) -> f64 {        // road 3: Crank-Nicolson 400 x 400, zero at both walls
    let (j, steps) = (400usize, 400usize);
    let (a, b, nu) = ((L / S).ln(), (U / S).ln(), RD - RF - 0.5 * SIG * SIG);
    let (h, dt) = ((b - a) / j as f64, T / steps as f64);
    let mut v: Vec<f64> = (0..=j).map(|i| if i == 0 || i == j { 0.0 } else { payoff(S * (a + i as f64 * h).exp()) }).collect();
    let (lo, di, up) = (0.5 * SIG * SIG / (h * h) - nu / (2.0 * h), -SIG * SIG / (h * h) - RD, 0.5 * SIG * SIG / (h * h) + nu / (2.0 * h));
    for n in 0..(steps + 2) {
        let (th, k) = if n < 4 { (1.0, dt / 2.0) } else { (0.5, dt) };   // 4 implicit half steps (Rannacher)
        let rhs: Vec<f64> = (1..j).map(|i| v[i] + (1.0 - th) * k * (lo * v[i - 1] + di * v[i] + up * v[i + 1])).collect();
        let (aa, bb, cc) = (-th * k * lo, 1.0 - th * k * di, -th * k * up);
        let (mut cp, mut dp) = (vec![0.0; j - 1], vec![0.0; j - 1]);
        for i in 0..(j - 1) {
            let (cprev, dprev) = if i > 0 { (cp[i - 1], dp[i - 1]) } else { (0.0, 0.0) };
            let den = bb - aa * cprev;
            cp[i] = cc / den; dp[i] = (rhs[i] - aa * dprev) / den;
        }
        for i in (0..(j - 1)).rev() { v[i + 1] = dp[i] - if i < j - 2 { cp[i] * v[i + 2] } else { 0.0 }; }
    }
    let i = (-a / h) as usize; let t = -a / h - i as f64;          // quadratic interpolation at today's spot
    v[i] * (t - 1.0) * (t - 2.0) / 2.0 - v[i + 1] * t * (t - 2.0) + v[i + 2] * t * (t - 1.0) / 2.0
}
fn simulate(paths: usize, steps: usize, seed: u64) -> [f64; 5] {   // road 4: weekly steps, bridge survival between
    let (nu, dt) = (RD - RF - 0.5 * SIG * SIG, T / steps as f64);
    let (a, b, v) = ((L / S).ln(), (U / S).ln(), SIG * SIG * dt);
    let (mut st, mut tot) = (seed, [0.0f64; 5]);      // sums: bridge weight, its square, call, call^2, nodes-only
    let next = |st: &mut u64| -> f64 {
        *st = st.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
        ((*st >> 11) as f64 + 0.5) / 9007199254740992.0
    };
    for _ in 0..paths {
        let (mut x, mut wt, mut raw) = (0.0f64, 1.0f64, 1.0f64);
        for _ in 0..steps {
            let (u1, u2) = (next(&mut st), next(&mut st));
            let y = x + nu * dt + v.sqrt() * (-2.0 * u1.ln()).sqrt() * (2.0 * PI * u2).cos();
            if y <= a || y >= b { wt = 0.0; raw = 0.0; break; }
            wt *= (1.0 - (-2.0 * (b - x) * (b - y) / v).exp() - (-2.0 * (x - a) * (y - a) / v).exp()).max(0.0);
            x = y;
        }
        let c = wt * (S * x.exp() - K).max(0.0);
        for (j, val) in [wt, wt * wt, c, c * c, raw].iter().enumerate() { tot[j] += val; }
    }
    let d = (-RD * T).exp(); let m: Vec<f64> = tot.iter().map(|t| t / paths as f64).collect();
    [d * m[0], d * ((m[1] - m[0] * m[0]) / paths as f64).sqrt(), d * m[2], d * ((m[3] - m[2] * m[2]) / paths as f64).sqrt(), d * m[4]]
}

fn reflect_nt(s: f64, hh: f64) -> f64 {               // single-wall no-touch by reflection, the sibling card's formula
    let (nu, sd, h) = (RD - RF - 0.5 * SIG * SIG, SIG * T.sqrt(), (hh / s).ln());
    let sgn = if hh > s { 1.0 } else { -1.0 };
    (-RD * T).exp() * (n_cdf(sgn * (h - nu * T) / sd) - (2.0 * nu * h / (SIG * SIG)).exp() * n_cdf(sgn * (-h - nu * T) / sd))
}
fn bs_call(s: f64) -> f64 {
    let sd = SIG * T.sqrt(); let d1 = ((s / K).ln() + (RD - RF + 0.5 * SIG * SIG) * T) / sd;
    s * (-RF * T).exp() * n_cdf(d1) - K * (-RD * T).exp() * n_cdf(d1 - sd)
}
fn reflect_doc(s: f64) -> f64 {                      // down-and-out call, one wall, by reflection (K above L)
    bs_call(s) - (L / s).powf(2.0 * (RD - RF - 0.5 * SIG * SIG) / (SIG * SIG)) * bs_call(L * L / s) }
fn main() {
    let (d, v_dnt, v_dko) = ((-RD * T).exp(), dnt(M0), dko(M0));
    let (nu, s, a, b) = (RD - RF - 0.5 * SIG * SIG, SIG * T.sqrt(), (L / S).ln(), (U / S).ln());
    println!("inputs: a {:.6}  b {:.6}  width {:.6}  2w {:.6}  nu {:.6}  sigma*sqrt(T) {:.6}  D {:.6}", a, b, b - a, 2.0 * (b - a), nu, s, d);
    for c in [0.0, 2.0 * b, 2.0 * a] {                   // the three nearest images, by hand: D x tilt x bracket
        let (tilt, br) = ((nu * c / (SIG * SIG)).exp(), n_cdf((b - c - nu * T) / s) - n_cdf((a - c - nu * T) / s));
        println!("image at {:+.6}: tilt {:.6}  bracket N({:+.6}) - N({:+.6}) = {:.6}  D x tilt x bracket {:.6}", c, tilt,
            (c - a + nu * T) / s, (c - b + nu * T) / s, br, d * tilt * br);
    }
    println!("image series, partial sums     reflections  double no-touch  knock-out call");
    for j in 0..5 { println!("  images with up to {} reflections {:>9} {:16.6} {:15.6}", j, j, dnt_j(M0, j), dko_j(M0, j)); }
    println!("sine series, modes 1 2 3       {:.10} {:.10} {:.10}", dnt_sine(1), dnt_sine(2), dnt_sine(3));
    let mc = simulate(400000, 52, 2026);
    let (g_dnt, g_dko) = (grid(|_s| 1.0), grid(|s| (s - K).max(0.0)));
    let rng_dig = images(Mkt { l: 1e-9, u: 1e9, ..M0 }, (L / S).ln(), (U / S).ln(), 0).0;
    let (nt_up, nt_dn) = (reflect_nt(S, U), reflect_nt(S, L));
    let rows: Vec<(&str, f64)> = vec![
        ("1 image series, 8 reflections  DNT", v_dnt), ("1 image series, 8 reflections  DKO", v_dko),
        ("2 sine series, 3 modes         DNT", dnt_sine(3)),
        ("3 Crank-Nicolson 400 x 400     DNT", g_dnt), ("3 Crank-Nicolson 400 x 400     DKO", g_dko),
        ("4 simulation 400k paths        DNT", mc[0]), ("  its standard error           DNT", mc[1]),
        ("4 simulation 400k paths        DKO", mc[2]), ("  its standard error           DKO", mc[3]),
        ("check: upper wall at 100, DKO", dko(Mkt { u: 100.0, ..M0 })), ("  one-wall reflection, DOC", reflect_doc(S)),
        ("check: upper wall at 100, DNT", dnt(Mkt { u: 100.0, ..M0 })), ("  one-wall no-touch at 1.05", nt_dn),
        ("check: lower wall at 0.01, DNT", dnt(Mkt { l: 0.01, ..M0 })), ("  one-wall no-touch at 1.20", nt_up),
        ("  one-touch at 1.20", d - nt_up), ("vanilla EUR call, K = 1.10", bs_call(S)),
        ("double knock-in = vanilla - DKO", bs_call(S) - v_dko), ("double one-touch = D - DNT", d - v_dnt),
        ("range bet: ends in 1.05-1.20", rng_dig), ("DNT payout / premium", 1.0 / v_dnt),
        ("wrong: NT(1.20) x NT(1.05) / D", nt_up * nt_dn / d), ("wrong: NT(1.20) + NT(1.05) - D", nt_up + nt_dn - d),
        ("wrong: simulation, no bridge", mc[4]),
        ("try: walls 1.00 / 1.25", dnt(Mkt { l: 1.00, u: 1.25, ..M0 })), ("try: six months", dnt(Mkt { t: 0.5, ..M0 })),
        ("try: vol 8%", dnt(Mkt { sig: 0.08, ..M0 })), ("try: DKO, vol 8%", dko(Mkt { sig: 0.08, ..M0 })),
    ];
    for (name, v) in &rows { println!("{:<36} {:>12.6}", name, v); }
    let h = 0.01;                                     // Greeks by bumping road 1: spot by 0.01, vol by one point, one day
    for (nm, f) in [("DNT", dnt as fn(Mkt) -> f64), ("DKO", dko as fn(Mkt) -> f64)] {
        let at = |s: f64, t: f64, sg: f64| f(Mkt { s, t, sig: sg, ..M0 });
        println!("greeks {}: delta/0.01 {:+.6}  gamma/0.01 {:+.6}  vega/1pt {:+.6}  theta/day {:+.6}", nm,
            (at(S + h, T, SIG) - at(S - h, T, SIG)) / 2.0, at(S + h, T, SIG) - 2.0 * at(S, T, SIG) + at(S - h, T, SIG),
            (at(S, T, SIG + 0.01) - at(S, T, SIG - 0.01)) / 2.0, at(S, T - 1.0 / 365.0, SIG) - at(S, T, SIG));
    }
    let spots: Vec<f64> = (0..16).map(|i| 1.05 + 0.01 * i as f64).collect();
    let line = |lab: &str, f: &dyn Fn(f64) -> f64, p: usize| {
        let body: Vec<String> = spots.iter().map(|&x| format!("{:6.*}", p, f(x))).collect();
        println!("{}{}", lab, body.join(" "));
    };
    line("chart, spot       ", &|x| x, 2);
    line("chart, DNT 12m    ", &|x| dnt(Mkt { s: x, ..M0 }), 4);
    line("chart, DNT 3m     ", &|x| dnt(Mkt { s: x, t: 0.25, ..M0 }), 2);
    line("chart, DKO payoff ", &|x| if L < x && x < U - 1e-9 { (x - K).max(0.0) } else { 0.0 }, 4);

    assert!((v_dnt - dnt_sine(3)).abs() < 1e-10, "two different series must give one price");
    assert!((v_dnt - g_dnt).abs() < 1e-4, "grid within a pip of the series, DNT");
    assert!((v_dko - g_dko).abs() < 1e-4, "grid within a pip of the series, DKO");
    assert!((v_dko - mc[2]).abs() < 3.0 * mc[3], "simulation within three standard errors, DKO");
    assert!((v_dnt - mc[0]).abs() < 3.0 * mc[1], "simulation within three standard errors, DNT");
    assert!((dko(Mkt { u: 100.0, ..M0 }) - 0.041661).abs() < 5e-7, "far upper wall: the one-wall house knock-out");
    assert!((dnt(Mkt { u: 100.0, ..M0 }) - nt_dn).abs() < 1e-9, "far upper wall: the one-wall no-touch at 1.05");
    assert!((d - dnt(Mkt { l: 0.01, ..M0 }) - 0.4142).abs() < 5e-5, "far lower wall: the house one-touch at 1.20");
    assert!(v_dnt < nt_up.min(nt_dn).min(rng_dig), "two walls must cost less than any one of them");
    println!("ALL CHECKS PASS");
}
