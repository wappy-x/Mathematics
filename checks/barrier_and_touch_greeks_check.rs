// Greeks at the wall: EURUSD reverse knock-out (call 1.10, dies at 1.20) and one-touch at 1.20.
// Std only. Three roads: closed-form Greeks, bump-and-revalue of the closed-form price, and a
// Crank-Nicolson grid that never sees the formula. The normal CDF is a series written here.
use std::f64::consts::PI;
const RD: f64 = 0.05; const RF: f64 = 0.03; const K: f64 = 1.10; const H: f64 = 1.20; const SIG: f64 = 0.10;
const MONTH: f64 = 1.0 / 12.0; const WEEK: f64 = 1.0 / 52.0; const DAY: f64 = 1.0 / 365.0;
const LO: f64 = 0.90; const DS: f64 = 0.0005; const STEPS: usize = 400;
#[derive(Clone, Copy, PartialEq)] enum P { Ko, Ot }

fn n_cdf(x: f64) -> f64 {                  // area under the bell curve left of x, by its Taylor series
    if x.abs() > 9.0 { return if x < 0.0 { 0.0 } else { 1.0 }; }
    let (mut t, mut s, mut n) = (x, x, 0.0);
    while t.abs() > 1e-17 * s.abs() { n += 1.0; t *= x * x / (2.0 * n + 1.0); s += t; }
    0.5 + s * (-0.5 * x * x).exp() / (2.0 * PI).sqrt()
}
fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }
fn vanilla(x: f64, k: f64, s: f64, t: f64) -> ([f64; 4], [f64; 4]) {   // call and cash digital at strike k
    let v = s * t.sqrt(); let d1 = ((x / k).ln() + (RD - RF + 0.5 * s * s) * t) / v; let d2 = d1 - v;
    let (a, b) = ((-RF * t).exp(), (-RD * t).exp());
    ([x * a * n_cdf(d1) - k * b * n_cdf(d2), a * n_cdf(d1), a * phi(d1) / (x * v), x * a * phi(d1) * t.sqrt()],
     [b * n_cdf(d2), b * phi(d2) / (x * v), -b * phi(d2) * d1 / (x * x * v * v), -b * phi(d2) * d1 / s])
}
fn below(p: P, x: f64, s: f64, t: f64, hb: f64) -> [f64; 4] {   // plain price of the payoff cut at the wall
    let ck = vanilla(x, K, s, t).0; let (ch, dh) = vanilla(x, hb, s, t);
    let mut g = [0.0; 4];
    for j in 0..4 {
        g[j] = if p == P::Ko { ck[j] - ch[j] - (hb - K) * dh[j] }
               else { (if j == 0 { (-RD * t).exp() } else { 0.0 }) - dh[j] };   // no-touch piece
    }
    g
}
fn closed(p: P, sp: f64, s: f64, t: f64, hb: f64, drop: bool) -> [f64; 4] {   // mirror: V = G(S) - w G(m)
    let lam = (RD - RF - 0.5 * s * s) / (s * s); let w = (hb / sp).powf(2.0 * lam); let m = hb * hb / sp;
    let (g, gm) = (below(p, sp, s, t, hb), below(p, m, s, t, hb));
    let v = g[0] - w * gm[0];
    let d = g[1] + (if drop { 0.0 } else { 2.0 * lam * w * gm[0] / sp }) + w * m * gm[1] / sp;
    let ga = g[2] - 2.0 * lam * (2.0 * lam + 1.0) * w * gm[0] / sp.powi(2) - (4.0 * lam + 2.0) * w * m * gm[1] / sp.powi(2)
        - w * m * m * gm[2] / sp.powi(2);
    let ve = g[3] + w * 4.0 * (hb / sp).ln() * (RD - RF) / s.powi(3) * gm[0] - w * gm[3];
    if p == P::Ot { [(-RD * t).exp() - v, -d, -ga, -ve] } else { [v, d, ga, ve] }
}
fn price(p: P, sp: f64, s: f64, t: f64, hb: f64) -> f64 {
    if sp >= hb { return if p == P::Ko { 0.0 } else { (-RD * t).exp() }; }
    closed(p, sp, s, t, hb, false)[0]
}
fn five(p: P, sp: f64, s: f64, t: f64) -> [f64; 6] {   // road 1: closed form; vanna, volga = vol-slopes
    let e = 1e-4;
    let (c, u, d) = (closed(p, sp, s, t, H, false), closed(p, sp, s + e, t, H, false), closed(p, sp, s - e, t, H, false));
    [c[0], c[1], c[2], c[3], (u[1] - d[1]) / (2.0 * e), (u[3] - d[3]) / (2.0 * e)]
}
fn bump(p: P, sp: f64, s: f64, t: f64) -> [f64; 6] {   // road 2: bump and revalue the price only
    let (h, e) = (1e-4, 1e-4);
    let q = |x: f64, y: f64| price(p, x, y, t, H); let v = q(sp, s);
    [v, (q(sp + h, s) - q(sp - h, s)) / (2.0 * h), (q(sp + h, s) - 2.0 * v + q(sp - h, s)) / (h * h),
     (q(sp, s + e) - q(sp, s - e)) / (2.0 * e),
     (q(sp + h, s + e) - q(sp + h, s - e) - q(sp - h, s + e) + q(sp - h, s - e)) / (4.0 * h * e),
     (q(sp, s + e) - 2.0 * v + q(sp, s - e)) / (e * e)]
}
fn grid(p: P, s: f64, t: f64) -> Vec<f64> {   // road 3: Crank-Nicolson on price LO..H, wall on a node
    let n = ((H - LO) / DS).round() as usize;
    let x: Vec<f64> = (0..=n).map(|i| LO + i as f64 * DS).collect();
    let mut v: Vec<f64> = x.iter().map(|&y| if p == P::Ko { (y - K).max(0.0) } else { 0.0 }).collect();
    v[n] = if p == P::Ko { 0.0 } else { 1.0 }; let dt = t / STEPS as f64;
    let a: Vec<f64> = x.iter().map(|&y| 0.5 * s * s * y * y / (DS * DS) - 0.5 * (RD - RF) * y / DS).collect();
    let c: Vec<f64> = x.iter().map(|&y| 0.5 * s * s * y * y / (DS * DS) + 0.5 * (RD - RF) * y / DS).collect();
    let b: Vec<f64> = x.iter().map(|&y| -s * s * y * y / (DS * DS) - RD).collect();
    for k in 0..STEPS {
        let th = if k < 4 { 1.0 } else { 0.5 };   // four fully implicit steps first
        let top = if p == P::Ko { 0.0 } else { (-RD * (k + 1) as f64 * dt).exp() };
        let mut r: Vec<f64> = (1..n).map(|i| v[i] + (1.0 - th) * dt * (a[i] * v[i - 1] + b[i] * v[i] + c[i] * v[i + 1])).collect();
        r[n - 2] += th * dt * c[n - 1] * top;
        let (mut cp, mut dp) = (vec![0.0; n - 1], vec![0.0; n - 1]);
        for j in 0..n - 1 {
            let i = j + 1; let (aa, cc) = (-th * dt * a[i], -th * dt * c[i]);
            let den = 1.0 - th * dt * b[i] - if j > 0 { aa * cp[j - 1] } else { 0.0 };
            cp[j] = cc / den; dp[j] = (r[j] - if j > 0 { aa * dp[j - 1] } else { 0.0 }) / den;
        }
        v[n - 1] = dp[n - 2];
        for j in (0..n - 2).rev() { v[j + 1] = dp[j] - cp[j] * v[j + 2]; }
        v[n] = top;
    }
    v
}
fn from_grid(g0: &[f64], gu: &[f64], gd: &[f64], sp: f64, e: f64) -> [f64; 6] {
    let i = ((sp - LO) / DS).round() as usize;
    let dl = |v: &[f64]| (v[i + 1] - v[i - 1]) / (2.0 * DS);
    [g0[i], dl(g0), (g0[i + 1] - 2.0 * g0[i] + g0[i - 1]) / (DS * DS), (gu[i] - gd[i]) / (2.0 * e),
     (dl(gu) - dl(gd)) / (2.0 * e), (gu[i] - 2.0 * g0[i] + gd[i]) / (e * e)]
}
fn root<F: Fn(f64) -> f64>(f: F, mut a: f64, mut b: f64) -> f64 {   // bisection
    let mut fa = f(a);
    for _ in 0..80 {
        let m = 0.5 * (a + b); let fm = f(m);
        if (fm > 0.0) == (fa > 0.0) { a = m; fa = fm; } else { b = m; }
    }
    0.5 * (a + b)
}
fn touch(sp: f64, s: f64, t: f64) -> f64 {   // one-touch as discounted touch chance: independent formula
    let (b, nu, v) = ((H / sp).ln(), RD - RF - 0.5 * s * s, s * t.sqrt());
    (-RD * t).exp() * (n_cdf((nu * t - b) / v) + (H / sp).powf(2.0 * nu / s / s) * n_cdf((-b - nu * t) / v))
}
fn desk(p: P, g: &[f64]) -> Vec<f64> {   // desk units
    let u = if p == P::Ko { [1e4, 1.0, 0.01, 100.0, 0.01, 1.0] } else { [100.0, 1.0, 0.01, 1.0, 0.01, 0.01] };
    g.iter().zip(u.iter()).map(|(x, y)| x * y).collect()
}
fn main() {
    let cl = |p: P, sp: f64, t: f64| closed(p, sp, SIG, t, H, false);
    println!("house cross-checks, one year, spot 1.10");
    println!("  reverse knock-out, pips               {:10.2}", price(P::Ko, 1.10, SIG, 1.0, H) * 1e4);
    println!("  one-touch, mirror of digital          {:10.6}", price(P::Ot, 1.10, SIG, 1.0, H));
    println!("  one-touch, discounted touch chance    {:10.6}", touch(1.10, SIG, 1.0));
    let e = 0.001;
    let gk = [grid(P::Ko, SIG, MONTH), grid(P::Ko, SIG + e, MONTH), grid(P::Ko, SIG - e, MONTH)];
    let go = [grid(P::Ot, SIG, MONTH), grid(P::Ot, SIG + e, MONTH), grid(P::Ot, SIG - e, MONTH)];
    let names = ["price", "delta", "gamma", "vega", "vanna", "volga"];
    println!("one month left; units: KO pips, OT % of payout; gamma per cent, vega/vanna/volga per vol point");
    println!("                     closed form    bump    grid");
    for (p, sp, lab) in [(P::Ko, 1.10, "ko"), (P::Ko, 1.19, "ko"), (P::Ot, 1.19, "ot")] {
        let g = if p == P::Ko { &gk } else { &go };
        let rows = [desk(p, &five(p, sp, SIG, MONTH)), desk(p, &bump(p, sp, SIG, MONTH)), desk(p, &from_grid(&g[0], &g[1], &g[2], sp, e))];
        for j in 0..6 {
            println!("  {} {:.2} {:<6}  {:12.4} {:9.4} {:9.4}", lab, sp, names[j], rows[0][j], rows[1][j], rows[2][j]);
            assert!((rows[1][j] - rows[0][j]).abs() < 1e-4 * (1.0 + rows[0][j].abs()));   // bump agrees with closed form
            assert!((rows[2][j] - rows[0][j]).abs() < 1e-3 * (1.0 + rows[0][j].abs()));   // grid agrees with closed form
        }
    }
    assert!((price(P::Ot, 1.10, SIG, 1.0, H) - touch(1.10, SIG, 1.0)).abs() < 1e-12);   // two one-touch formulas agree
    let (lam, sp) = ((RD - RF - 0.5 * SIG * SIG) / (SIG * SIG), 1.19); let (w, m) = ((H / sp).powf(2.0 * lam), H * H / sp);
    let (g, gm) = (below(P::Ko, sp, SIG, MONTH, H), below(P::Ko, m, SIG, MONTH, H));   // the hand table
    println!("worked, KO 1.19, month: lam {:.4}  w {:.6}  m {:.6}  G(S) {:.6}  G(m) {:.6}  price {:.6}", lam, w, m, g[0], gm[0], g[0] - w * gm[0]);
    println!("  delta terms: G'(S) {:.6}  2 lam w G(m)/S {:.6}  w m G'(m)/S {:.6}", g[1], 2.0 * lam * w * gm[0] / sp, w * m * gm[1] / sp);
    println!("sweep, one month: closed form   KO pips  delta  gamma   vega |  OT %   delta   vega");
    for sp in [1.10, 1.11, 1.12, 1.13, 1.14, 1.15, 1.16, 1.17, 1.18, 1.19, 1.195, 1.199] {
        let (k, o) = (desk(P::Ko, &cl(P::Ko, sp, MONTH)), desk(P::Ot, &cl(P::Ot, sp, MONTH)));
        println!("  spot {:<6.3}  {:20.2} {:6.2} {:6.2} {:6.2} | {:5.2} {:7.2} {:6.2}", sp, k[0], k[1], k[2], k[3], o[0], o[1], o[3]);
    }
    let f = |j: usize, tg: f64| move |sp: f64| closed(P::Ko, sp, SIG, MONTH, H, false)[j] - tg;
    println!("  KO delta 0 at {:.4}, delta -1 at {:.4}, vega 0 at {:.4}, gamma 0 at {:.4}",
             root(f(1, 0.0), 1.12, 1.18), root(f(1, -1.0), 1.16, 1.19), root(f(3, 0.0), 1.10, 1.13), root(f(2, 0.0), 1.10, 1.13));
    let vz: Vec<String> = [WEEK, DAY].iter().map(|&t| format!("{:.4}", root(|sp| cl(P::Ko, sp, t)[3], 1.10, 1.1999))).collect();
    println!("  OT gamma 0 at {:.4}; KO vega 0 at, week / day: {}", root(|sp| cl(P::Ot, sp, MONTH)[2], 1.19, 1.199), vz.join(" / "));
    println!("T left    KO delta 1.199  at wall  wall-delta rule  KO gamma 1.199  OT delta 1.199");
    for (lab, t) in [("month", MONTH), ("week", WEEK), ("day", DAY)] {
        let rule = 1.0 - (H - K) * (2.0 / PI).sqrt() / (H * SIG * t.sqrt());   // wall-delta rule, near expiry
        println!("  {:<6} {:16.4} {:8.4} {:17.4} {:15.4} {:15.4}", lab, cl(P::Ko, 1.199, t)[1], cl(P::Ko, H, t)[1], rule,
                 cl(P::Ko, 1.199, t)[2] * 0.01, cl(P::Ot, 1.199, t)[1]);
        assert!((cl(P::Ko, H, t)[1] - rule).abs() < 0.05 * rule.abs());   // blow-up law holds
    }
    println!("barrier shift, one month   wall 1.2010   wall 1.2020   wall 1.2050  (KO reserve, pips)");
    for sp in [1.10, 1.19] {
        let cols: String = [0.001, 0.002, 0.005].iter()
            .map(|&d| format!("{:14.2}", (price(P::Ko, sp, SIG, MONTH, H + d) - price(P::Ko, sp, SIG, MONTH, H)) * 1e4)).collect();
        println!("  spot {:.2}          {}", sp, cols);
    }
    let (res, cost) = (price(P::Ko, H, SIG, MONTH, H + 0.001), -cl(P::Ko, H, MONTH)[1] * 0.001);
    println!("  at spot 1.20, wall 1.2010: KO worth {:.2} pips; |delta at wall| x 10 pips = {:.2}", res * 1e4, cost * 1e4);
    assert!((res - cost).abs() < 0.1 * cost);   // shift pays for the unwind
    let ot: Vec<String> = [1.10, 1.19].iter()
        .map(|&sp| format!("{:.2}", (price(P::Ot, sp, SIG, MONTH, H - 0.001) - price(P::Ot, sp, SIG, MONTH, H)) * 100.0)).collect();
    println!("  OT sold: wall pulled to 1.1990, reserve % at 1.10 / 1.19: {}", ot.join(" / "));
    let vd = vanilla(1.19, K, SIG, MONTH).0[1];
    let (up, mid, dn) = (price(P::Ko, 1.205, SIG, MONTH, H), price(P::Ko, 1.195, SIG, MONTH, H), price(P::Ko, 1.185, SIG, MONTH, H));
    println!("what breaks at 1.19: vanilla delta {:.4}; weight slope dropped {:.4}", vd, closed(P::Ko, 1.19, SIG, MONTH, H, true)[1]);
    println!("  at 1.195, one-cent bump across the wall: delta {:.4}, gamma per cent {:.4}", (up - dn) / 0.02, (up - 2.0 * mid + dn) / 1e-4 * 0.01);
    println!("ALL CHECKS PASS");
}
