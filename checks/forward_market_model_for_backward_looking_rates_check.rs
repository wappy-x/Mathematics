// Forward market model: two compounded overnight forwards, terminal and spot measures -- the same check in Rust.
// std only, no crates.  The normal CDF, the random numbers and every integral are written here.
use std::f64::consts::PI;
const TAU: f64 = 1.0; const T: [f64; 3] = [0.0, 1.0, 2.0];   // two annual accrual periods
const R0: [f64; 2] = [0.04, 0.045]; const S: [f64; 2] = [0.010, 0.009]; const RHO: f64 = 0.9;
const USD: f64 = 1e6; const H: f64 = 0.1; const STEPS: usize = 20;
type M2 = [[f64; 2]; 2];
fn corr(j: usize, k: usize) -> f64 { if j == k { 1.0 } else { RHO } }
fn inside(d: char, u: f64) -> f64 { match d { 'l' => 1.0 - u, 'f' => 1.0, _ => 0.0 } }   // u: share of period gone
fn g(j: usize, t: f64, d: char) -> f64 {   // decay of R_j's volatility; rate j accrues over T[j]..T[j+1]
    if t <= T[j] { 1.0 } else if t >= T[j + 1] { 0.0 } else { inside(d, (t - T[j]) / TAU) }
}
fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64, m: usize) -> f64 {
    let hh = (b - a) / m as f64;
    let mut s = 0.0;
    for i in 1..m { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * hh); }
    hh / 3.0 * (f(a) + f(b) + s)
}
fn vtime(j: usize, d: char) -> f64 { T[j] + TAU * simpson(&|u| inside(d, u).powi(2), 0.0, 1.0, 200) }
fn ncdf(x: f64) -> f64 {   // bell-curve area left of x, by Simpson's rule from 0
    if x == 0.0 { 0.5 } else { 0.5 + simpson(&|u| (-0.5 * u * u).exp() / (2.0 * PI).sqrt(), 0.0, x, 2000) }
}
fn p() -> [f64; 3] { [1.0, 1.0 / 1.04, 1.0 / (1.04 * 1.045)] }   // 1 + tau R_j(0) = P(0,T_j) / P(0,T_(j+1))
fn bachelier(j: usize, v: f64, k: f64) -> f64 {   // caplet on R_j paid at T_(j+1), normal variance s_j^2 v
    let sd = S[j] * v.sqrt();
    if sd == 0.0 { return TAU * p()[j + 1] * (R0[j] - k).max(0.0); }
    let d = (R0[j] - k) / sd;
    TAU * p()[j + 1] * ((R0[j] - k) * ncdf(d) + sd * (-0.5 * d * d).exp() / (2.0 * PI).sqrt())
}
fn cov(t: f64) -> M2 {   // instantaneous covariance of R_j and R_k per year at time t
    let mut c = [[0.0; 2]; 2];
    for j in 0..2 { for k in 0..2 { c[j][k] = corr(j, k) * S[j] * S[k] * g(j, t, 'l') * g(k, t, 'l'); } }
    c
}
// drift of R_j at time t (per year, or over a step if c is a step's covariance)
fn drift(j: usize, t: f64, r: &[f64; 2], rule: char, c: Option<&M2>) -> f64 {
    let a = [TAU / (1.0 + TAU * r[0]), TAU / (1.0 + TAU * r[1])];
    let c = match c { Some(m) => *m, None => cov(t) };
    match rule {
        'T' => -((j + 1)..2).fold(0.0, |s, k| s + c[j][k] * a[k]),
        'S' => (0..=j).fold(0.0, |s, k| s + c[j][k] * a[k]),
        'X' => (0..=j).filter(|&k| !(T[k] <= t && t < T[k + 1])).fold(0.0, |s, k| s + c[j][k] * a[k]),
        _ => 0.0,
    }
}
fn logbond(i: usize, r: &[f64; 2]) -> f64 {   // ln P(t,T_i)/P(t,T_2): every bond rebuilt from the rates (extended after T_i)
    (i..2).fold(0.0, |s, k| s + (1.0 + TAU * r[k]).ln())
}
fn bump(j: usize, t: f64, r: &[f64; 2], rule: char) -> f64 {   // road 2: bump each rate, read ln(new unit / R_j's payment bond)
    let e = 1e-7;
    let num = if rule == 'T' { 2 } else { (0..3).filter(|&i| T[i] <= t).max().unwrap() };   // bank account B(t) = B(T_n) P(t,T_n)
    let lr = |rb: [f64; 2]| logbond(num, &rb) - logbond(j + 1, &rb);
    let up = |k: usize, d: f64| { let mut u = *r; u[k] += d; u };
    (0..2).fold(0.0, |s, k| s + cov(t)[j][k] * (lr(up(k, e)) - lr(up(k, -e))) / (2.0 * e))
}
struct Rng(u64);   // xorshift64* random numbers, Box-Muller normals
impl Rng {
    fn unif(&mut self) -> f64 {
        self.0 ^= self.0 >> 12; self.0 ^= self.0 << 25; self.0 ^= self.0 >> 27;
        (self.0.wrapping_mul(0x2545F4914F6CDD1D) >> 11) as f64 * 2f64.powi(-53) + 2f64.powi(-54)
    }
    fn normals(&mut self) -> [f64; 2] {
        let r = (-2.0 * self.unif().ln()).sqrt(); let t = 2.0 * PI * self.unif();
        [r * t.cos(), r * t.sin()]
    }
}
struct Step { t0: f64, c: M2, l0: f64, l1: f64, l2: f64 }
fn path(rule: char, steps: &[Step], zs: &[[f64; 2]], sg: f64) -> [f64; 4] {
    let mut r = R0;
    let pp = p();
    for (st, z) in steps.iter().zip(zs) {
        let mu = [drift(0, st.t0, &r, rule, Some(&st.c)), drift(1, st.t0, &r, rule, Some(&st.c))];
        r = [r[0] + mu[0] + st.l0 * sg * z[0], r[1] + mu[1] + st.l1 * sg * z[0] + st.l2 * sg * z[1]];
    }
    let gr = [1.0 + TAU * r[0], 1.0 + TAU * r[1]];   // realised growth of $1 rolled overnight, per period
    let (c1, c2) = (TAU * (r[0] - R0[0]).max(0.0), TAU * (r[1] - R0[1]).max(0.0));
    if rule == 'T' || rule == 'N' { [pp[2] * c1 * gr[1], pp[2] * c2, gr[0] * gr[1], (r[1] - R0[1]).powi(2)] }
    else { [c1 / gr[0], c2 / (gr[0] * gr[1]), 1.0 / (gr[0] * gr[1]), 0.0] }
}

fn main() {
    let pp = p();
    let mut steps = Vec::new();
    for n in 0..STEPS {
        let (t0, t1) = (n as f64 * H, (n + 1) as f64 * H);
        let mut c = [[0.0; 2]; 2];
        for j in 0..2 { for k in 0..2 { c[j][k] = corr(j, k) * S[j] * S[k] * simpson(&|t| g(j, t, 'l') * g(k, t, 'l'), t0, t1, 2); } }
        let l0 = c[0][0].sqrt(); let l1 = if l0 != 0.0 { c[1][0] / l0 } else { 0.0 };
        steps.push(Step { t0, c, l0, l1, l2: (c[1][1] - l1 * l1).max(0.0).sqrt() });
    }
    let (rules, m, mut rng) = (['T', 'S', 'N', 'X'], 30000usize, Rng(20261123));
    let (mut tot, mut dif) = ([[[0.0f64; 2]; 4]; 4], [[[0.0f64; 2]; 2]; 4]);
    for _ in 0..m {
        let zs: Vec<[f64; 2]> = (0..STEPS).map(|_| rng.normals()).collect();
        let mut val = [[0.0f64; 4]; 4];
        for (ri, &r) in rules.iter().enumerate() {
            let (a, b) = (path(r, &steps, &zs, 1.0), path(r, &steps, &zs, -1.0));
            for k in 0..4 { val[ri][k] = 0.5 * (a[k] + b[k]); tot[ri][k][0] += val[ri][k]; tot[ri][k][1] += val[ri][k].powi(2); }
            let base = if r == 'T' || r == 'N' { 0 } else { 1 };
            for k in 0..2 { let d = val[ri][k] - val[base][k]; dif[ri][k][0] += d; dif[ri][k][1] += d * d; }
        }
    }
    let mf = m as f64;
    let ms = |q: [f64; 2]| (q[0] / mf, ((q[1] / mf - (q[0] / mf).powi(2)).max(0.0) / mf).sqrt());

    println!("forward market model: compounded forwards on [0,1] and [1,2], annual accrual");
    println!("P(0,1) {:.6}  P(0,2) {:.6}  R_1(0) 4.0%  R_2(0) 4.5%  normal vols 1.0% 0.9%  rho 0.9", pp[1], pp[2]);
    let vt = [vtime(0, 'l'), vtime(1, 'l')];
    println!("variance time, Simpson on g^2: R_1 {:.6}  R_2 {:.6}   rule T_s + tau/3: {:.6} {:.6}", vt[0], vt[1], T[0] + TAU / 3.0, T[1] + TAU / 3.0);
    let cf = [bachelier(0, vt[0], R0[0]), bachelier(1, vt[1], R0[1])];
    println!("caplet sd: R_1 {:.6}%  R_2 {:.6}%  bell height at 0 {:.6}", S[0] * vt[0].sqrt() * 100.0, S[1] * vt[1].sqrt() * 100.0, 1.0 / (2.0 * PI).sqrt());
    println!("closed form, ATM, per $1m: caplet 1 {:.2}  caplet 2 {:.2}", cf[0] * USD, cf[1] * USD);
    for (name, dec) in [("fixed at period start", 'x'), ("flat to payment date", 'f')] {
        let v = [vtime(0, dec), vtime(1, dec)];
        println!("  vol {:<22} variance times {:.4} {:.4}  caplets {:8.2} {:8.2}", name, v[0], v[1], bachelier(0, v[0], R0[0]) * USD, bachelier(1, v[1], R0[1]) * USD);
    }
    println!("try: caplet 2 per $1m at K = 4% {:.2}, at K = 5% {:.2}", bachelier(1, vt[1], 0.04) * USD, bachelier(1, vt[1], 0.05) * USD);
    println!("drift at t = 0, today's curve, bp/yr        formula     bump road");
    for (lab, j, r) in [("R_1 under terminal Q^T2", 0usize, 'T'), ("R_2 under spot (bank account)", 1, 'S'), ("R_1 under spot", 0, 'S')] {
        println!("  {:<34} {:10.4}  {:10.4}", lab, drift(j, 0.0, &R0, r, None) * 1e4, bump(j, 0.0, &R0, r) * 1e4);
    }
    println!("  R_2 spot, accruing rate's term dropped {:.4}", drift(1, 0.0, &R0, 'X', None) * 1e4);
    let (a0, a1) = (TAU / (1.0 + TAU * R0[0]), TAU / (1.0 + TAU * R0[1]));
    println!("  R_2 spot terms: rho s_2 s_1 a_1 {:.4}  s_2^2 a_2 {:.4}", RHO * S[1] * S[0] * a0 * 1e4, S[1].powi(2) * a1 * 1e4);
    let grid: Vec<f64> = (0..9).map(|i| 0.25 * i as f64).collect();
    let row = |f: &dyn Fn(f64) -> String| grid.iter().map(|&t| f(t)).collect::<Vec<_>>().join(" ");
    println!("chart, t        {}", row(&|t| format!("{:6.2}", t)));
    println!("chart, vol R_2  {}", row(&|t| format!("{:6.1}", S[1] * g(1, t, 'l') * 1e4)));
    println!("chart, LIBOR    {}", row(&|t| format!("{:6.1}", S[1] * (if t < T[1] { 1.0 } else { 0.0 }) * 1e4)));
    println!("chart, mu2 spot {}", row(&|t| format!("{:6.3}", drift(1, t, &R0, 'S', None) * 1e4 + 0.0)));
    println!("chart, mu1 term {}", row(&|t| format!("{:6.3}", drift(0, t, &R0, 'T', None) * 1e4 + 0.0)));
    println!("Monte Carlo, {} paths, {} steps of {} years, per $1m      caplet 1        caplet 2", 2 * m, STEPS, H);
    let names = ["terminal Q^T2, drift", "spot, drift", "terminal, no drift", "spot, accruing dropped"];
    for ri in 0..4 {
        let ((m1, e1), (m2, e2)) = (ms(tot[ri][0]), ms(tot[ri][1]));
        println!("  {:<24} {:8.2} se {:4.2}  {:8.2} se {:4.2}", names[ri], m1 * USD, e1 * USD, m2 * USD, e2 * USD);
    }
    for ri in [2usize, 3] {
        let ((d1, f1), (d2, f2)) = (ms(dif[ri][0]), ms(dif[ri][1]));
        println!("  {:<24} minus correct: {:+7.2} se {:.2}  {:+7.2} se {:.2}", names[ri], d1 * USD, f1 * USD, d2 * USD, f2 * USD);
    }
    let (vm, ve) = ms(tot[0][3]);
    println!("simulated variance time of R_2: {:.4}  se {:.4}  (one-third rule {:.4})", vm / S[1].powi(2), ve / S[1].powi(2), T[1] + TAU / 3.0);
    let tg = [1.0 / pp[2], pp[2], 1.0 / pp[2], pp[2]];
    println!("no-arbitrage test: terminal must average 1/P(0,2), spot must average P(0,2)");
    for ri in 0..4 {
        let (mm, e) = ms(tot[ri][2]);
        println!("  {:<24} {:.7} se {:.7}  target {:.7}  off by {:+7.2} se", names[ri], mm, e, tg[ri], (mm - tg[ri]) / e);
    }
    assert!((0..2).all(|j| (vt[j] - (T[j] + TAU / 3.0)).abs() < 1e-12), "one-third rule vs Simpson");
    for j in 0..2 { for &t in &grid { for r in ['T', 'S'] {
        assert!((bump(j, t, &R0, r) - drift(j, t, &R0, r, None)).abs() < 1e-12, "drift formula vs bump road");
    } } }
    for ri in 0..2 {
        for k in 0..2 { let (mm, e) = ms(tot[ri][k]); assert!((mm - cf[k]).abs() < 3.0 * e, "MC caplet vs closed form"); }
        let (mm, e) = ms(tot[ri][2]); assert!((mm - tg[ri]).abs() < 3.0 * e, "numeraire ratio is a fair bet");
    }
    for ri in [2usize, 3] { let (mm, e) = ms(tot[ri][2]); assert!((mm - tg[ri]).abs() > 3.0 * e, "wrong drift must fail the test"); }
    let (d1, f1) = ms(dif[2][0]); assert!(d1.abs() > 3.0 * f1, "dropping the drift must move caplet 1");
    assert!((vm / S[1].powi(2) - 4.0 / 3.0).abs() < 3.0 * ve / S[1].powi(2), "simulated variance time");
    println!("ALL CHECKS PASS");
}
