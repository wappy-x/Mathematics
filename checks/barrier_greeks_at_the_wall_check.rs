// Barrier Greeks at the wall -- the same check as barrier_greeks_at_the_wall_check.py, in Rust.
// Standard library only, no crates.  Rust has no erf, so N(x) is built by adding thin
// slices under the bell curve (Simpson).  Four roads: the formula differentiated by hand,
// bump and revalue, a Crank-Nicolson grid that never sees the formula, static replication.
use std::f64::consts::PI;

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }
fn n_cdf(x: f64) -> f64 {
    if x.abs() > 12.0 { return if x > 0.0 { 1.0 } else { 0.0 }; }
    let (m, h) = (4000, x / 4000.0);
    let mut s = phi(0.0) + phi(x);
    for i in 1..m { s += if i % 2 == 1 { 4.0 } else { 2.0 } * phi(i as f64 * h); }
    0.5 + s * h / 3.0
}
fn d12(s: f64, k: f64, r: f64, q: f64, v: f64, t: f64) -> (f64, f64) {
    let d1 = ((s / k).ln() + (r - q + 0.5 * v * v) * t) / (v * t.sqrt()); (d1, d1 - v * t.sqrt())
}
fn call(s: f64, k: f64, r: f64, q: f64, v: f64, t: f64) -> f64 {
    let (d1, d2) = d12(s, k, r, q, v, t); s * (-q * t).exp() * n_cdf(d1) - k * (-r * t).exp() * n_cdf(d2)
}
fn put(s: f64, k: f64, r: f64, q: f64, v: f64, t: f64) -> f64 {
    let (d1, d2) = d12(s, k, r, q, v, t); k * (-r * t).exp() * n_cdf(-d2) - s * (-q * t).exp() * n_cdf(-d1)
}
fn digital(s: f64, k: f64, r: f64, q: f64, v: f64, t: f64) -> f64 { (-r * t).exp() * n_cdf(d12(s, k, r, q, v, t).1) }
fn vanilla_greeks(s: f64, k: f64, r: f64, q: f64, v: f64, t: f64) -> [f64; 3] {
    let d1 = d12(s, k, r, q, v, t).0; let e = (-q * t).exp();
    [e * n_cdf(d1), e * phi(d1) / (s * v * t.sqrt()), s * e * phi(d1) * t.sqrt()]
}
fn down_out(s: f64, k: f64, b: f64, r: f64, q: f64, v: f64, t: f64) -> f64 {
    if s <= b { return 0.0; }
    let a = 2.0 * (r - q) / (v * v) - 1.0;
    call(s, k, r, q, v, t) - (b / s).powf(a) * call(b * b / s, k, r, q, v, t)
}
fn up_out(s: f64, k: f64, h: f64, r: f64, q: f64, v: f64, t: f64) -> f64 {
    if s >= h { return 0.0; }
    let a = 2.0 * (r - q) / (v * v) - 1.0;
    let w = |x: f64| call(x, k, r, q, v, t) - call(x, h, r, q, v, t) - (h - k) * digital(x, h, r, q, v, t);
    w(s) - (h / s).powf(a) * w(h * h / s)
}
fn down_out_greeks(s: f64, k: f64, b: f64, r: f64, q: f64, v: f64, t: f64) -> [f64; 3] {
    let a = 2.0 * (r - q) / (v * v) - 1.0;
    let (x, p) = (b * b / s, (b / s).powf(a));
    let (dx, ddx, dp, ddp) = (-x / s, 2.0 * x / (s * s), -a * p / s, a * (a + 1.0) * p / (s * s));
    let gv = vanilla_greeks(s, k, r, q, v, t); let gx = vanilla_greeks(x, k, r, q, v, t);
    let cx = call(x, k, r, q, v, t);
    [gv[0] - (dp * cx + p * gx[0] * dx),
     gv[1] - (ddp * cx + 2.0 * dp * gx[0] * dx + p * gx[1] * dx * dx + p * gx[0] * ddx),
     gv[2] - (p * (b / s).ln() * (-4.0 * (r - q) / v.powi(3)) * cx + p * gx[2])]
}
fn bump<F: Fn(f64, f64) -> f64>(f: F, s: f64, v: f64, h: f64) -> [f64; 3] {
    let hs = 0.0001;
    [(f(s + h, v) - f(s - h, v)) / (2.0 * h), (f(s + h, v) - 2.0 * f(s, v) + f(s - h, v)) / (h * h),
     (f(s, v + hs) - f(s, v - hs)) / (2.0 * hs)]
}
struct Grid { lo: f64, ds: f64, v: Vec<f64> }
impl Grid {
    fn at(&self, s: f64) -> [f64; 3] {
        let i = ((s - self.lo) / self.ds).round() as usize; let v = &self.v;
        [v[i], (v[i + 1] - v[i - 1]) / (2.0 * self.ds), (v[i + 1] - 2.0 * v[i] + v[i - 1]) / self.ds.powi(2)]
    }
}
fn grid<P: Fn(f64) -> f64, E: Fn(f64) -> (f64, f64)>(lo: f64, hi: f64, m: usize, n: usize, payoff: P, edge: E,
        r: f64, q: f64, sg: f64, t: f64) -> Grid {
    let ds = (hi - lo) / m as f64;
    let s: Vec<f64> = (0..=m).map(|i| lo + i as f64 * ds).collect();
    let mut v: Vec<f64> = s.iter().map(|&x| payoff(x)).collect();
    let a: Vec<f64> = s.iter().map(|&x| 0.5 * sg * sg * x * x / (ds * ds) - 0.5 * (r - q) * x / ds).collect();
    let c: Vec<f64> = s.iter().map(|&x| 0.5 * sg * sg * x * x / (ds * ds) + 0.5 * (r - q) * x / ds).collect();
    let mut steps = vec![(t / n as f64 / 2.0, 1.0); 4]; steps.extend(vec![(t / n as f64, 0.5); n - 2]);
    let mut tau = 0.0;
    for (dt, th) in steps {
        tau += dt;
        let mut rhs: Vec<f64> = (1..m).map(|i| v[i] + (1.0 - th) * dt * (a[i] * v[i - 1] - (a[i] + c[i] + r) * v[i] + c[i] * v[i + 1])).collect();
        let (lv, hv) = edge(tau);
        rhs[0] += th * dt * a[1] * lv; rhs[m - 2] += th * dt * c[m - 1] * hv;
        let sub: Vec<f64> = (1..m).map(|i| -th * dt * a[i]).collect();
        let sup: Vec<f64> = (1..m).map(|i| -th * dt * c[i]).collect();
        let mut dia: Vec<f64> = (1..m).map(|i| 1.0 + th * dt * (a[i] + c[i] + r)).collect();
        for j in 1..m - 1 { let w = sub[j] / dia[j - 1]; dia[j] -= w * sup[j - 1]; rhs[j] -= w * rhs[j - 1]; }
        let mut x = vec![0.0; m - 1]; x[m - 2] = rhs[m - 2] / dia[m - 2];
        for j in (0..m - 2).rev() { x[j] = (rhs[j] - sup[j] * x[j + 1]) / dia[j]; }
        v = std::iter::once(lv).chain(x).chain(std::iter::once(hv)).collect();
    }
    Grid { lo, ds, v }
}
fn out(label: &str, w: &[f64]) { println!("{:<38}{}", label, w.iter().map(|v| format!("{:>13.6}", v)).collect::<String>()); }

fn main() {
    let (k, b, h, r, q, s, t) = (100.0, 80.0, 120.0, 0.05, 0.02, 0.20, 1.0);
    let dof = |x: f64, sv: f64| down_out(x, k, b, r, q, sv, t);
    let do_grid = |sv: f64| grid(b, 400.0, 800, 500, |x| (x - k).max(0.0),
        |tt| (0.0, 400.0 * (-q * tt).exp() - k * (-r * tt).exp()), r, q, sv, t);
    let (g0, gu, gd) = (do_grid(s), do_grid(s + 0.005), do_grid(s - 0.005));
    out("price at 100: DO, DO grid, vanilla", &[dof(100.0, s), g0.at(100.0)[0], call(100.0, k, r, q, s, t)]);
    out("a, B^2/S, (B/S)^a, C(64), mirror", &[2.0 * (r - q) / (s * s) - 1.0, b * b / 100.0, (b / 100.0f64).powf(0.5), call(b * b / 100.0, k, r, q, s, t),
        (b / 100.0f64).powf(0.5) * call(b * b / 100.0, k, r, q, s, t)]);
    println!("house down-and-out call, B = 80    formula      bump      grid");
    let mut res = Vec::new();
    for sv in [100.0, 90.0, 82.0] {
        let an = down_out_greeks(sv, k, b, r, q, s, t); let bu = bump(dof, sv, s, 0.01);
        let gg = g0.at(sv); let gr = [gg[1], gg[2], (gu.at(sv)[0] - gd.at(sv)[0]) / 0.01];
        for (i, name) in ["delta", "gamma", "vega"].iter().enumerate() {
            if *name != "vega" || sv != 90.0 { out(&format!("{} at {:.0}", name, sv), &[an[i], bu[i], gr[i]]); }
        }
        res.push((an, gr));
    }
    println!("vanilla call, same market             delta        gamma         vega");
    for sv in [100.0, 90.0, 82.0] { out(&format!("vanilla at {:.0}", sv), &vanilla_greeks(sv, k, r, q, s, t)); }
    out("at the wall: delta, gamma, vega", &down_out_greeks(b, k, b, r, q, s, t));
    out("price at 82, at 80.1", &[dof(82.0, s), dof(80.1, s)]);
    out("shares per $ of premium at 82, 80.1", &[res[2].0[0] / dof(82.0, s),
        down_out_greeks(80.1, k, b, r, q, s, t)[0] / dof(80.1, s)]);
    out("wall: C(80), 2 Delta(80), a C(80)/B", &[call(b, k, r, q, s, t), 2.0 * vanilla_greeks(b, k, r, q, s, t)[0], 0.5 * call(b, k, r, q, s, t) / b]);
    println!("reverse knock-out: up-and-out call, H = 120");
    let uo = |x: f64, sv: f64, tt: f64, hh: f64| up_out(x, k, hh, r, q, sv, tt);
    for (tt, lab) in [(1.0, "1 year"), (0.25, "3 months"), (1.0 / 12.0, "1 month"), (1.0 / 52.0, "1 week")] {
        out(&format!("UO delta at 119.9, {}", lab), &[bump(|x, sv| uo(x, sv, tt, h), 119.9, s, 0.01)[0]]);
    }
    let m1 = |x: f64, sv: f64| uo(x, sv, 1.0 / 12.0, h);
    out("UO 1 month: price 100, 115", &[m1(100.0, s), m1(115.0, s)]);
    out("UO 1 month: vega at 100, 115", &[bump(m1, 100.0, s, 0.01)[2], bump(m1, 115.0, s, 0.01)[2]]);
    let ug: Vec<Grid> = [s, s + 0.005, s - 0.005].iter().map(|&sv| grid(0.0, h, 480, 500,
        |x| if x < h { (x - k).max(0.0) } else { 0.0 }, |_| (0.0, 0.0), r, q, sv, 1.0 / 12.0)).collect();
    out("UO grid: price 115, delta 115", &ug[0].at(115.0)[..2]);
    let ugv = |x: f64| (ug[1].at(x)[0] - ug[2].at(x)[0]) / 0.01;
    out("UO grid: vega at 100, 115", &[ugv(100.0), ugv(115.0)]);
    let y1 = |x: f64, sv: f64| uo(x, sv, t, h);
    out("UO 1 year: vega at 80, 100", &[bump(y1, 80.0, s, 0.01)[2], bump(y1, 100.0, s, 0.01)[2]]);
    println!("barrier shift, 1 month: price with H = 120 and 122");
    out("UO price at 100, shifted at 100", &[m1(100.0, s), uo(100.0, s, 1.0 / 12.0, 122.0)]);
    out("shifted option worth at 120", &[uo(120.0, s, 1.0 / 12.0, 122.0)]);
    let sh = bump(|x, sv| uo(x, sv, 1.0 / 12.0, 122.0), 120.0, s, 0.01)[0];
    out("shifted delta at 120, slippage covered", &[sh, -uo(120.0, s, 1.0 / 12.0, 122.0) / sh]);
    println!("static replication when r = q = 0.02: put strike B^2/K = 64, ratio K/B = 1.25");
    let rq = 0.02;
    out("formula, replication at 100", &[down_out(100.0, k, b, rq, rq, s, t),
        call(100.0, k, rq, rq, s, t) - k / b * put(100.0, b * b / k, rq, rq, s, t)]);
    let (cw, pw) = (call(b, k, rq, rq, s, t), k / b * put(b, b * b / k, rq, rq, s, t));
    out("at the wall: call, 1.25 puts", &[cw, pw]);
    println!("what breaks");
    out("vega with a held fixed, at 100", &[vanilla_greeks(100.0, k, r, q, s, t)[2]
        - (b / 100.0f64).powf(0.5) * vanilla_greeks(b * b / 100.0, k, r, q, s, t)[2]]);
    out("bump h = 5 across the wall, at 82", &[bump(dof, 82.0, s, 5.0)[0]]);
    out("try: DO delta at wall, T = 0.25", &[down_out_greeks(b, k, b, r, q, s, 0.25)[0]]);
    let xs = [80.0, 82.0, 85.0, 90.0, 95.0, 100.0, 110.0, 120.0];
    println!("chart, S        {}", xs.iter().map(|x| format!("{:>7.0}", x)).collect::<String>());
    println!("chart, DO x100  {}", xs.iter().map(|&x| format!("{:>7.2}", 100.0 * down_out_greeks(x, k, b, r, q, s, t)[0])).collect::<String>());
    println!("chart, van x100 {}", xs.iter().map(|&x| format!("{:>7.2}", 100.0 * vanilla_greeks(x, k, r, q, s, t)[0])).collect::<String>());

    assert!((dof(100.0, s) - 9.133306).abs() < 1e-6, "house down-and-out price");
    for (an, gr) in &res {
        assert!((an[0] - gr[0]).abs() < 1e-3, "analytic delta vs grid");
        assert!((an[1] - gr[1]).abs() < 1e-4, "analytic gamma vs grid");
        assert!((an[2] - gr[2]).abs() < 0.05, "analytic vega vs grid");
    }
    let wall = down_out_greeks(b, k, b, r, q, s, t);
    let dw = 2.0 * vanilla_greeks(b, k, r, q, s, t)[0] + (2.0 * (r - q) / (s * s) - 1.0) * call(b, k, r, q, s, t) / b;
    assert!((wall[0] - dw).abs() < 1e-9, "wall delta = 2 Delta(B) + a C(B)/B");
    assert!((wall[1] + 2.0 * (r - q) / (s * s) / b * dw).abs() < 1e-9, "wall gamma = -(1 + a)/B times wall delta");
    assert!(res[2].1[1] < 0.0, "grid gamma negative at 82");
    assert!(res[0].1[1] > 0.0, "grid gamma positive at 100");
    assert!((m1(115.0, s) - ug[0].at(115.0)[0]).abs() < 5e-3, "up-and-out formula vs grid");
    assert!(ugv(115.0) < 0.0, "grid vega negative at 115");
    assert!(ugv(100.0) > 0.0, "grid vega positive at 100");
    assert!((cw - pw).abs() < 1e-9, "replication at the wall");
    println!("ALL CHECKS PASS");
}
