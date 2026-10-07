// Barriers on a smile -- the same check in Rust, std only, no crates.
// Compile: rustc --edition 2021 -O barriers_with_the_smile_check.rs -o /tmp/bws_check
// House EURUSD reverse knock-out: EUR call, strike 1.10, knocked out at 1.20.
// Roads: reflection formula, finite-difference PDE, Monte Carlo on the same draws.
use std::f64::consts::PI;
const RD: f64 = 0.05; const RF: f64 = 0.03; const K: f64 = 1.10; const H: f64 = 1.20;
const ATM: f64 = 0.10; const PIP: f64 = 1e-4; const SMILE: [f64; 3] = [0.1075, 0.10, 0.0975];
type P = (f64, f64, f64); // pillar: strike, vol, +1 call / -1 put

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }
fn n_cdf(x: f64) -> f64 { // bell-curve area: series for the integral
    if x.abs() > 9.0 { return if x > 0.0 { 1.0 } else { 0.0 }; }
    let (mut s, mut t, mut n) = (x, x, 1.0);
    while t.abs() > 1e-17 * s.abs() { t *= x * x / (2.0 * n + 1.0); s += t; n += 1.0; }
    0.5 + phi(x) * s
}
fn n_inv(p: f64) -> f64 { // bisection root finder
    let (mut lo, mut hi) = (-9.0, 9.0);
    for _ in 0..80 { let m = 0.5 * (lo + hi); if n_cdf(m) < p { lo = m } else { hi = m } }
    0.5 * (lo + hi)
}
fn gk(s: f64, k: f64, t: f64, v: f64, w: f64) -> f64 { // Garman-Kohlhagen call or put
    let d1 = ((s / k).ln() + (RD - RF + 0.5 * v * v) * t) / (v * t.sqrt()); let d2 = d1 - v * t.sqrt();
    w * (s * (-RF * t).exp() * n_cdf(w * d1) - k * (-RD * t).exp() * n_cdf(w * d2))
}
fn dig(s: f64, k: f64, t: f64, v: f64) -> f64 { (-RD * t).exp() * n_cdf(((s / k).ln() + (RD - RF - 0.5 * v * v) * t) / (v * t.sqrt())) }
fn uoc(s: f64, t: f64, v: f64, h: f64) -> f64 { // road 1: reflection formula
    let g = |x: f64| gk(x, K, t, v, 1.0) - gk(x, h, t, v, 1.0) - (h - K) * dig(x, h, t, v);
    g(s) - (h / s).powf(2.0 * (RD - RF) / (v * v) - 1.0) * g(h * h / s)
}
fn surv(s: f64, t: f64, v: f64, h: f64) -> f64 { // chance the wall is never touched
    let (mu, a) = (RD - RF - 0.5 * v * v, (h / s).ln());
    n_cdf((a - mu * t) / (v * t.sqrt())) - (2.0 * mu * a / (v * v)).exp() * n_cdf((-a - mu * t) / (v * t.sqrt()))
}
fn pillars(s: f64, t: f64, vo: [f64; 3]) -> [P; 3] { // strikes of 25-put, ATM, 25-call (spot delta)
    let (vp, va, vc) = (vo[0], vo[1], vo[2]); let d = n_inv(0.25 * (RF * t).exp()); let m = (RD - RF) * t;
    [(s * (d * vp * t.sqrt() + m + 0.5 * vp * vp * t).exp(), vp, -1.0), (s * (m + 0.5 * va * va * t).exp(), va, 1.0),
     (s * (-d * vc * t.sqrt() + m + 0.5 * vc * vc * t).exp(), vc, 1.0)]
}
fn vvv(f: &dyn Fn(f64, f64) -> f64, s: f64, v: f64) -> [f64; 3] { // vega, vanna, volga by central bumps
    let e = 1e-4;
    [(f(s, v + e) - f(s, v - e)) / (2.0 * e), (f(s + e, v + e) - f(s + e, v - e) - f(s - e, v + e)
        + f(s - e, v - e)) / (4.0 * e * e), (f(s, v + e) - 2.0 * f(s, v) + f(s, v - e)) / (e * e)]
}
fn det(m: &[[f64; 3]; 3]) -> f64 {
    m[0][0] * (m[1][1] * m[2][2] - m[1][2] * m[2][1]) - m[0][1] * (m[1][0] * m[2][2]
        - m[1][2] * m[2][0]) + m[0][2] * (m[1][0] * m[2][1] - m[1][1] * m[2][0])
}
fn solve3(a: &[[f64; 3]; 3], b: &[f64; 3]) -> [f64; 3] { // Cramer's rule
    let mut x = [0.0; 3];
    for c in 0..3 { let mut m = *a; for i in 0..3 { m[i][c] = b[i]; } x[c] = det(&m) / det(a); }
    x
}
fn overlay(f: &dyn Fn(f64, f64) -> f64, s: f64, t: f64, pil: &[P; 3]) -> ([f64; 3], f64) { // hedge weights, hedge cost
    let mut a = [[0.0; 3]; 3];
    for (j, &(k, _, w)) in pil.iter().enumerate() { let c = vvv(&|x, v| gk(x, k, t, v, w), s, ATM); for i in 0..3 { a[i][j] = c[i]; } }
    let x = solve3(&a, &vvv(f, s, ATM));
    (x, pil.iter().enumerate().fold(0.0, |acc, (j, &(k, v, w))| acc + x[j] * (gk(s, k, t, v, w) - gk(s, k, t, ATM, w))))
}
fn pde(s: f64, t: f64, lv: &dyn Fn(f64) -> f64, pay: &dyn Fn(f64) -> f64, h: f64) -> f64 { // road 2 (h = 0: no wall)
    let (nx, nt) = (300usize, 150usize);
    let l = 0.8 * t.sqrt() + 0.05; let x0 = -l; let x1 = if h > 0.0 { (h / s).ln() } else { l };
    let dx = (x1 - x0) / nx as f64; let dt = t / nt as f64;
    let xs: Vec<f64> = (0..=nx).map(|i| x0 + i as f64 * dx).collect();
    let mut v: Vec<f64> = xs.iter().map(|x| pay(s * x.exp())).collect();
    if h > 0.0 { v[nx] = 0.0; }
    let s2: Vec<f64> = xs.iter().map(|&x| lv(x).powi(2)).collect();
    let lo: Vec<f64> = s2.iter().map(|q| 0.5 * q / dx / dx - 0.5 * (RD - RF - 0.5 * q) / dx).collect();
    let up: Vec<f64> = s2.iter().map(|q| 0.5 * q / dx / dx + 0.5 * (RD - RF - 0.5 * q) / dx).collect();
    let di: Vec<f64> = s2.iter().map(|q| -q / dx / dx - RD).collect();
    for n in 0..nt {
        let th = if n < 2 { 1.0 } else { 0.5 }; let e = (1.0 - th) * dt; let bl = v[0] * (-RD * dt).exp();
        let bh = if h > 0.0 { 0.0 } else { v[nx] * (-RD * dt).exp() };
        let (mut cp, mut dp) = (vec![0.0; nx + 1], vec![0.0; nx + 1]); dp[0] = bl;
        for i in 1..nx {
            let r = v[i] + e * (lo[i] * v[i - 1] + di[i] * v[i] + up[i] * v[i + 1]);
            let (a, b, c) = (-th * dt * lo[i], 1.0 - th * dt * di[i], -th * dt * up[i]);
            let m = b - a * cp[i - 1]; cp[i] = c / m; dp[i] = (r - a * dp[i - 1]) / m;
        }
        v[nx] = bh;
        for i in (1..nx).rev() { v[i] = dp[i] - cp[i] * v[i + 1]; }
        v[0] = bl;
    }
    let i = (-x0 / dx) as usize; let w = -xs[i] / dx;
    v[i] * (1.0 - w) + v[i + 1] * w
}
fn lvf(p: [f64; 3]) -> impl Fn(f64) -> f64 { move |x| (p[0] + p[1] * x + p[2] * x * x).max(0.02).min(0.6) }
fn calib(s: f64, t: f64, pil: &[P; 3]) -> ([f64; 3], f64) { // fit a + b x + c x^2 so the PDE hits all three quotes
    let tgt: Vec<(f64, f64)> = pil.iter().map(|&(k, v, w)| (gk(s, k, t, v, w), vvv(&|x, u| gk(x, k, t, u, w), s, v)[0])).collect();
    let res = |p: [f64; 3]| -> [f64; 3] {
        let mut r = [0.0; 3];
        for (j, &(k, _, w)) in pil.iter().enumerate() { r[j] = (pde(s, t, &lvf(p), &|x| (w * (x - k)).max(0.0), 0.0) - tgt[j].0) / tgt[j].1; }
        r };
    let mut p = [ATM, 0.0, 0.0]; let mut r = res(p); let mut jac = [[0.0; 3]; 3];
    for j in 0..3 { let mut q = p; q[j] += 1e-3; let rq = res(q); for i in 0..3 { jac[i][j] = (rq[i] - r[i]) / 1e-3; } }
    for _ in 0..5 { let d = solve3(&jac, &[-r[0], -r[1], -r[2]]); for i in 0..3 { p[i] += d[i]; } r = res(p); } // chord Newton
    (p, r.iter().fold(0.0, |m: f64, u| m.max(u.abs())))
}
struct Rng(u64); // splitmix64 uniforms in (0, 1]
impl Rng { fn u(&mut self) -> f64 {
    self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15); let mut z = self.0;
    z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9); z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    (((z ^ (z >> 31)) >> 11) + 1) as f64 / 9007199254740992.0 } }
fn mc(s: f64, t: f64, lv: &dyn Fn(f64) -> f64, pay: &dyn Fn(f64) -> f64, n: usize, steps: usize, h: f64) -> (f64, f64) { // road 3
    let mut g = Rng(7); let dt = t / steps as f64; let b = (h / s).ln(); let (mut s1, mut s2) = (0.0, 0.0);
    for _ in 0..n {
        let (mut xa, mut xb, mut wa, mut wb) = (0.0, 0.0, 1.0, 1.0);
        for _ in 0..steps {
            let u1 = g.u(); let z = (-2.0 * u1.ln()).sqrt() * (2.0 * PI * g.u()).cos();
            let step = |x: f64, v: f64| { let y = x + (RD - RF - 0.5 * v * v) * dt + v * dt.sqrt() * z; // Euler step, bridge survival
                (y, if y >= b { 0.0 } else { 1.0 - (-2.0 * (b - x) * (b - y) / (v * v * dt)).exp() }) };
            let (ya, ka) = step(xa, ATM); let (yb, kb) = step(xb, lv(xb));
            xa = ya; xb = yb; wa *= ka; wb *= kb;
        }
        let d = wb * pay(s * xb.exp()) - wa * pay(s * xa.exp()); s1 += d; s2 += d * d;
    }
    let m = s1 / n as f64; ((-RD * t).exp() * m, (-RD * t).exp() * ((s2 / n as f64 - m * m) / n as f64).sqrt())
}
fn call(s: f64) -> f64 { (s - K).max(0.0) }
fn case(s: f64, t: f64, tag: &str, n: usize, steps: usize) -> [f64; 7] {
    let pil = pillars(s, t, SMILE); let flat = uoc(s, t, ATM, H); let ps = surv(s, t, ATM, H); let f = |x: f64, v: f64| uoc(x, t, v, H);
    let (x, ov) = overlay(&f, s, t, &pil); let (p, _) = calib(s, t, &pil); let lv = lvf(p);
    let pf = pde(s, t, &|_| ATM, &call, H); let d = pde(s, t, &lv, &call, H) - pf; let (dm, se) = mc(s, t, &lv, &call, n, steps, H);
    let rows: Vec<(&str, Vec<f64>)> = vec![("pillar strikes 25P ATM 25C", pil.iter().map(|q| q.0).collect()), ("barrier vega vanna volga", vvv(&f, s, ATM).to_vec()),
        ("hedge weights x", x.to_vec()), ("local vol a b c", p.to_vec()), ("flat: formula, PDE, pips", vec![flat / PIP, pf / PIP]),
        ("pillar cost mkt - flat, pips", pil.iter().map(|&(k, v, w)| (gk(s, k, t, v, w) - gk(s, k, t, ATM, w)) / PIP).collect()),
        ("survival chance, touch chance", vec![ps, 1.0 - ps]), ("overlay: full, x survival, pips", vec![ov / PIP, ps * ov / PIP]),
        ("VV: unweighted, x survival, pips", vec![(flat + ov) / PIP, (flat + ps * ov) / PIP]), ("local vol: flat + PDE gap, pips", vec![(flat + d) / PIP]),
        ("smile gap: PDE, MC, s.e., pips", vec![d / PIP, dm / PIP, se / PIP]), ("VV minus local vol: full, x surv", vec![(ov - d) / PIP, (ps * ov - d) / PIP])];
    println!("{}", tag);
    for (lab, vals) in &rows { println!("  {:<32}{}", lab, vals.iter().map(|v| format!("{:>12.6}", v)).collect::<String>()); }
    [flat, ps, ov, d, pf, dm, se]
}
fn main() {
    let [flat, ps, ov, d, pf, dm, se] = case(1.10, 1.0, "house reverse knock-out, 1 year, spot 1.10", 20000, 200);
    let w = 7.0 / 365.0;
    let [wf, wps, wov, wd, wpf, wdm, wse] = case(1.19, w, "same contract, 1 week left, spot 1.19", 20000, 200);
    println!("1 week left: spot, flat, VV x survival - flat, local vol - flat (pips)");
    for i in 0..10 {
        let s = 1.15 + 0.005 * i as f64; let pl = pillars(s, w, SMILE);
        let (_, o) = overlay(&|q, v| uoc(q, w, v, H), s, w, &pl); let (ps_, _) = calib(s, w, &pl);
        let g = pde(s, w, &lvf(ps_), &call, H) - pde(s, w, &|_| ATM, &call, H);
        println!("  {:.3} {:9.2} {:9.2} {:9.2}", s, uoc(s, w, ATM, H) / PIP, surv(s, w, ATM, H) * o / PIP, g / PIP);
    }
    let pts: Vec<String> = [1.05, 1.10, 1.15, 1.19, 1.20, 1.25].iter().map(|&s: &f64| format!("{:.3}:{:.3}", s, if s < H { call(s) } else { 0.0 })).collect();
    println!("payoff at expiry if 1.20 never traded: {}", pts.join(" "));
    let pil = pillars(1.10, 1.0, SMILE); let (p0, fit) = calib(1.10, 1.0, &pil); let lv = lvf(p0);
    let nt_pde = pde(1.10, 1.0, &|_| ATM, &|_| 1.0, H) * RD.exp(); // survival chance by PDE
    let (k3, v3, _) = pil[2]; let (_, o3) = overlay(&|s, v| gk(s, k3, 1.0, v, 1.0), 1.10, 1.0, &pil);
    let (kp, vp, _) = pil[0]; let (pm, pse) = mc(1.10, 1.0, &lv, &|s| (kp - s).max(0.0), 20000, 200, 1e9);
    let mut extra: Vec<(String, f64)> = vec![("wrong: weight by touch chance".into(), (flat + (1.0 - ps) * ov) / PIP),
        ("wrong: flat at 25C vol 9.75%".into(), uoc(1.10, 1.0, 0.0975, H) / PIP), ("wrong: flat at 25P vol 10.75%".into(), uoc(1.10, 1.0, 0.1075, H) / PIP)];
    for (lab, vo) in [("try: risk reversal mirrored", [0.0975, 0.10, 0.1075]), ("try: butterfly zero", [0.105, 0.10, 0.095])] {
        let (_, o) = overlay(&|s, v| uoc(s, 1.0, v, H), 1.10, 1.0, &pillars(1.10, 1.0, vo)); extra.push((format!("{}, VVxS", lab), (flat + ps * o) / PIP));
    }
    let (_, o) = overlay(&|s, v| uoc(s, 1.0, v, 1.25), 1.10, 1.0, &pil); let (f25, s25) = (uoc(1.10, 1.0, ATM, 1.25), surv(1.10, 1.0, ATM, 1.25));
    let lv25 = f25 + pde(1.10, 1.0, &lv, &call, 1.25) - pde(1.10, 1.0, &|_| ATM, &call, 1.25);
    let mkt = gk(1.10, kp, 1.0, vp, -1.0) - gk(1.10, kp, 1.0, ATM, -1.0);
    for (lab, v) in [("try: wall 1.25, flat", f25 / PIP), ("try: wall 1.25, VV x survival", (f25 + s25 * o) / PIP), ("try: wall 1.25, local vol PDE", lv25 / PIP),
        ("check: survival by PDE", nt_pde), ("check: 25C via overlay", gk(1.10, k3, 1.0, ATM, 1.0) + o3), ("  market 25C at 9.75%", gk(1.10, k3, 1.0, v3, 1.0)),
        ("check: 25P smile-flat MC, s.e., pips", pm / PIP), ("  s.e.", pse / PIP), ("  market - flat, pips", mkt / PIP)] { extra.push((lab.into(), v)); }
    for (lab, v) in &extra { println!("{:<38}{:>12.6}", lab, v); }
    assert!((pf - flat).abs() < 0.5 * PIP && (wpf - wf).abs() < 0.5 * PIP, "PDE road vs reflection formula");
    assert!((dm - d).abs() < 3.0 * se && (wdm - wd).abs() < 3.0 * wse, "Monte Carlo smile gap vs PDE smile gap");
    assert!((nt_pde - ps).abs() < 1e-3, "survival chance: closed form vs PDE");
    assert!((gk(1.10, k3, 1.0, ATM, 1.0) + o3 - gk(1.10, k3, 1.0, v3, 1.0)).abs() < 1e-9, "overlay reprices its own pillar");
    assert!((pm - mkt).abs() < 3.0 * pse, "local vol MC reprices the 25P quote");
    assert!(fit < 1e-6, "local vol reprices all three quotes on the grid"); assert!(wd < 0.0 && 0.0 < wps * wov, "a week out the recipe and the model disagree in sign");
    println!("ALL CHECKS PASS");
}
