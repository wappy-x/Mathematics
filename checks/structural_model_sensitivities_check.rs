// Structural model sensitivities -- the same check as the Python, in Rust.
// Standard library only, no crates.  N(x) is Simpson's rule on the bell curve's
// height.  Three roads: the card's Greek formulas; bumping the closed-form
// prices; and pricing every claim by integrating its payoff over the asset value
// at maturity, with the default point found by bisection (no d1, no d2).
use std::f64::consts::PI;

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }

fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    s * h / 3.0
}

fn n_cdf(x: f64) -> f64 {
    if x.abs() > 12.0 { return if x > 0.0 { 1.0 } else { 0.0 }; }
    0.5 + simpson(phi, 0.0, x, 2000)
}

// road 1: [E, B, P, Q, spread bp, d1, d2]
fn claims(v: f64, d: f64, s: f64, r: f64, t: f64) -> [f64; 7] {
    let vt = s * t.sqrt();
    let d1 = ((v / d).ln() + (r + 0.5 * s * s) * t) / vt;
    let d2 = d1 - vt;
    let e = v * n_cdf(d1) - d * (-r * t).exp() * n_cdf(d2);
    let b = v - e;
    [e, b, d * (-r * t).exp() - b, n_cdf(-d2), (-(b / d).ln() / t - r) * 1e4, d1, d2]
}

const STEP: [f64; 5] = [1.0, 0.01, 1.0, 1.0, 0.01]; // $1m, 1 vol point, $1m, 1 year, 1 rate point

fn greeks(v: f64, d: f64, s: f64, r: f64, t: f64) -> [[f64; 5]; 5] {
    let c = claims(v, d, s, r, t);
    let (b, d1, d2) = (c[1], c[5], c[6]);
    let (df, rt, y) = ((-r * t).exp(), t.sqrt(), -(b / d).ln() / t);
    let eg = [n_cdf(d1), v * phi(d1) * rt, -df * n_cdf(d2),
              v * phi(d1) * s / (2.0 * rt) + r * d * df * n_cdf(d2), t * d * df * n_cdf(d2)];
    let bg = [1.0 - eg[0], -eg[1], -eg[2], -eg[3], -eg[4]];
    let pg = [eg[0] - 1.0, eg[1], df + eg[2], eg[3] - r * d * df, eg[4] - t * d * df];
    let f = phi(d2);
    let qg = [-f / (v * s * rt), f * d1 / s, f / (d * s * rt),
              f * ((v / d).ln() - (r - 0.5 * s * s) * t) / (2.0 * s * t * rt), -f * rt / s];
    let sg = [-bg[0] / (t * b) * 1e4, -bg[1] / (t * b) * 1e4, -(bg[2] / b - 1.0 / d) / t * 1e4,
              (-bg[3] / (t * b) - y / t) * 1e4, (-bg[4] / (t * b) - 1.0) * 1e4];
    let mut out = [eg, bg, pg, qg, sg];
    for row in out.iter_mut() { for j in 0..5 { row[j] *= STEP[j]; } }
    out
}

fn bumped(v: f64, d: f64, s: f64, r: f64, t: f64) -> [[f64; 5]; 5] {
    let x = [v, d, s, r, t];
    let mut out = [[0.0; 5]; 5];
    for (col, &i) in [0usize, 2, 1, 4, 3].iter().enumerate() { // V, sigma, D, T, r
        let h = 1e-4 * x[i];
        let (mut up, mut dn) = (x, x);
        up[i] += h; dn[i] -= h;
        let cu = claims(up[0], up[1], up[2], up[3], up[4]);
        let cd = claims(dn[0], dn[1], dn[2], dn[3], dn[4]);
        for k in 0..5 { out[k][col] = (cu[k] - cd[k]) / (2.0 * h) * STEP[col]; }
    }
    out
}

// road 3: average the payoffs; returns (E, B, Q) under the given drift
fn by_integral(v: f64, d: f64, s: f64, r: f64, t: f64, drift: f64) -> (f64, f64, f64) {
    let m = drift - 0.5 * s * s;
    let vt = |z: f64| v * (m * t + s * t.sqrt() * z).exp();
    let (mut lo, mut hi) = (-12.0_f64, 12.0_f64);
    for _ in 0..200 {
        let mid = 0.5 * (lo + hi);
        if vt(mid) < d { lo = mid; } else { hi = mid; }
    }
    let (zs, df) = (0.5 * (lo + hi), (-r * t).exp());
    let e = df * simpson(|z| (vt(z) - d) * phi(z), zs, 12.0, 2000);
    let b = df * (simpson(|z| vt(z) * phi(z), -12.0, zs, 2000) + d * simpson(phi, zs, 12.0, 2000));
    (e, b, simpson(phi, -12.0, zs, 2000))
}

fn row(lab: &str, xs: &[f64]) -> String {
    format!("{:<28}{}", lab, xs.iter().map(|v| format!("{:12.6}", v)).collect::<String>())
}

fn line(lab: &str, xs: &[f64], dp: usize) -> String {
    format!("{}{}", lab, xs.iter().map(|v| format!(" {:7.*}", dp, v)).collect::<String>())
}

fn main() {
    let (v, d, s, r, t) = (100.0_f64, 80.0_f64, 0.20_f64, 0.05_f64, 1.0_f64);
    let [e, b, p, q, sp, d1, d2] = claims(v, d, s, r, t);
    let (ei, bi, qi) = by_integral(v, d, s, r, t, r);
    println!("base: V 100, D 80, sigma 0.20, r 0.05, T 1; money in $m");
    println!("{}", row("d1, d2", &[d1, d2]));
    println!("{}", row("N(d1), N(d2)", &[n_cdf(d1), n_cdf(d2)]));
    println!("{}", row("phi(d1), phi(d2)", &[phi(d1), phi(d2)]));
    println!("{}", row("e^-rT, leverage D e^-rT / V", &[(-r * t).exp(), d * (-r * t).exp() / v]));
    println!("{}", row("dE/dT parts: vol, rate", &[v * phi(d1) * s / 2.0, r * d * (-r * t).exp() * n_cdf(d2)]));
    println!("{:<28}{:>12}{:>12}", "claim", "formula", "integral");
    for (lab, a, c) in [("equity E", e, ei), ("debt B", b, bi), ("put P", p, d * (-r * t).exp() - bi),
                        ("default prob Q", q, qi), ("spread s (bp)", sp, (-(bi / d).ln() / t - r) * 1e4)] {
        println!("{}", row(lab, &[a, c]));
    }
    println!("{}", row("E + B by integral", &[ei + bi]));
    println!("{}", row("real-world Q, drift 0.08", &[by_integral(v, d, s, r, t, 0.08).2]));

    let (g, hb) = (greeks(v, d, s, r, t), bumped(v, d, s, r, t));
    println!("{:<16}{:>12}{:>12}{:>12}{:>12}{:>12}", "per step", "$1m of V", "1 vol pt", "$1m of D", "1 year", "1 rate pt");
    let mut worst = 0.0_f64;
    for (k, lab) in ["equity", "debt", "put", "prob Q", "spread bp"].iter().enumerate() {
        for (tag, m) in [("form", &g), ("bump", &hb)] {
            let cells: String = m[k].iter().map(|x| format!("{:12.6}", x)).collect();
            println!("{:<16}{}", format!("{} {}", lab, tag), cells);
        }
        for j in 0..5 { worst = worst.max((g[k][j] - hb[k][j]).abs() / g[k][j].abs().max(1e-9)); }
    }
    println!("{:<28}{:>12}", "formula vs bump, worst gap", if worst < 1e-5 { "below 1e-5" } else { "TOO BIG" });

    let (h, up, dn) = (1e-4, by_integral(v, d, s + 1e-4, r, t, r), by_integral(v, d, s - 1e-4, r, t, r)); // road 3 only
    let (ve, vb) = ((up.0 - dn.0) / (2.0 * h), (up.1 - dn.1) / (2.0 * h));
    println!("{}", row("integral vega E, B, |sum|", &[ve, vb, (ve + vb).abs()]));
    let euler = v * g[0][0] + d * g[0][2];
    println!("{}", row("V dE/dV + D dE/dD", &[euler]));

    println!("{:<16}{:>10}{:>10}{:>10}{:>10}{:>10}", "scenario", "E", "B", "P", "Q %", "s bp");
    let scen = [("base", 100.0, 80.0, 0.2, 0.05, 1.0), ("sigma 0.40", 100.0, 80.0, 0.4, 0.05, 1.0),
                ("V 90", 90.0, 80.0, 0.2, 0.05, 1.0), ("D 88.89", 100.0, 800.0 / 9.0, 0.2, 0.05, 1.0),
                ("T 2", 100.0, 80.0, 0.2, 0.05, 2.0), ("r 0.06", 100.0, 80.0, 0.2, 0.06, 1.0)];
    let mut gap = 0.0_f64;
    for (lab, a, dd, ss, rr, tt) in scen {
        let c = claims(a, dd, ss, rr, tt);
        gap = gap.max((c[0] - by_integral(a, dd, ss, rr, tt, rr).0).abs());
        let cells: String = [c[0], c[1], c[2], 100.0 * c[3], c[4]].iter().map(|x| format!("{:10.2}", x)).collect();
        println!("{:<16}{}", lab, cells);
    }
    println!("{:<28}{:>12}", "scenarios, integral E gap", if gap < 1e-8 { "below 1e-8" } else { "TOO BIG" });

    let sig: Vec<f64> = (0..11).map(|i| 0.10 + 0.05 * i as f64).collect();
    let pick = |k: usize| -> Vec<f64> { sig.iter().map(|&x| claims(v, d, x, r, t)[k]).collect() };
    println!("{}", line("chart sigma", &sig, 2));
    println!("{}", line("chart E    ", &pick(0), 2));
    println!("{}", line("chart B    ", &pick(1), 2));
    println!("{}", line("chart s bp ", &pick(4), 2));
    let mats = [0.25, 0.5, 1.0, 2.0, 3.0, 5.0, 7.0, 10.0];
    println!("{}", line("term T     ", &mats, 2));
    for (lab, a) in [("term V 100 ", 100.0), ("term V 90  ", 90.0)] {
        let xs: Vec<f64> = mats.iter().map(|&tt| claims(a, d, s, r, tt)[4]).collect();
        println!("{}", line(lab, &xs, 2));
    }

    let c40 = claims(v, d, 0.40, r, t);
    println!("{}", row("transfer, sigma 0.20 to 0.40", &[c40[0] - e, c40[1] - b]));
    println!("{}", row("wrong: linear E, sigma 0.40", &[e + g[0][1] * 20.0, c40[0]]));
    println!("{}", row("wrong: linear s, sigma 0.40", &[sp + g[4][1] * 20.0, c40[4]]));
    println!("{}", row("wrong: put delta as Q", &[-g[2][0], q]));
    println!("{}", row("wrong: longer is wider, V 90", &[claims(90.0, d, s, r, 1.0)[4], claims(90.0, d, s, r, 2.0)[4]]));

    assert!((e - ei).abs() < 1e-8, "equity: closed form vs payoff integral");
    assert!((b - bi).abs() < 1e-8, "debt: closed form vs payoff integral");
    assert!((ei + bi - v).abs() < 1e-8, "equity plus debt, priced separately, is the firm");
    assert!(worst < 1e-5, "every Greek formula vs bump-and-revalue");
    assert!((ve - g[0][1] * 100.0).abs() < 1e-5, "equity vega: integral bump vs formula");
    assert!((vb + g[0][1] * 100.0).abs() < 1e-5, "debt vega: integral bump vs minus the formula");
    assert!((euler - e).abs() < 1e-6, "scaling: V dE/dV + D dE/dD must rebuild E");
    assert!((claims(90.0, 80.0, s, r, t)[4] - claims(100.0, 800.0 / 9.0, s, r, t)[4]).abs() < 1e-9, "only leverage matters");
    assert!(gap < 1e-8, "every scenario's equity, closed form vs integral");
    assert!((q - qi).abs() < 1e-10, "default probability: N(-d2) vs the integral of the default region");
    println!("ALL CHECKS PASS");
}
