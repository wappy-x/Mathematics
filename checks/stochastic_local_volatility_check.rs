// Stochastic-local volatility -- the same check as stochastic_local_volatility_check.py, in Rust.
// Standard library only, no crates.  Same generator, polar method, normal-CDF series and summing
// order as the Python, so the two outputs agree digit for digit.
use std::f64::consts::PI;
const S0: f64 = 100.0; const R: f64 = 0.05; const Q: f64 = 0.02; const T: f64 = 1.0; const SIG: f64 = 0.20;
const V0: f64 = 0.04; const TH: f64 = 0.04; const KA: f64 = 2.0; const XI: f64 = 0.3; const RHO: f64 = -0.7;
const NP: usize = 50000; const NS: usize = 40; const T1: f64 = 0.5;
const DT: f64 = T / NS as f64; const TAU: f64 = T - T1;
type Pair = (f64, f64);
fn unif(x: &mut u64) -> f64 {                                        // uniform on (-1, 1], 64-bit LCG
    *x = x.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
    ((*x >> 11) + 1) as f64 * (1.0 / 4503599627370496.0) - 1.0
}
fn normals(x: &mut u64) -> Pair {                                    // polar method: two normals
    loop { let (a, b) = (unif(x), unif(x)); let s = a * a + b * b;
           if s > 0.0 && s < 1.0 { let f = (-2.0 * s.ln() / s).sqrt(); return (a * f, b * f); } }
}
fn ncdf(x: f64) -> f64 {                                             // bell-curve area left of x
    if x.abs() > 9.0 { return if x < 0.0 { 0.0 } else { 1.0 }; }
    let (mut s, mut t, mut i) = (x, x, 1.0);
    loop { i += 2.0; t *= x * x / i; if s + t == s { return 0.5 + s * (-0.5 * x * x).exp() / (2.0 * PI).sqrt(); } s += t; }
}
fn bs(s: f64, k: f64, tau: f64, vol: f64, call: bool) -> f64 {       // Black-Scholes; put by parity
    let sd = vol * tau.sqrt(); let d1 = ((s / k).ln() + (R - Q) * tau) / sd + 0.5 * sd;
    let c = s * (-Q * tau).exp() * ncdf(d1) - k * (-R * tau).exp() * ncdf(d1 - sd);
    if call { c } else { c - s * (-Q * tau).exp() + k * (-R * tau).exp() }
}
fn ivol(price: f64, s: f64, k: f64, tau: f64, call: bool) -> f64 {  // bisection
    let (mut lo, mut hi) = (0.01, 1.0);
    for _ in 0..50 { let mid = 0.5 * (lo + hi); if bs(s, k, tau, mid, call) > price { hi = mid } else { lo = mid } }
    0.5 * (lo + hi)
}
fn hat(s: f64) -> (usize, f64) { let x = (s.max(40.0).min(199.999999) - 40.0) / 10.0; (x as usize, x - (x as usize) as f64) }
fn interp(lev: &[f64], s: f64) -> f64 { let (j, a) = hat(s); (1.0 - a) * lev[j] + a * lev[j + 1] }
fn node_avg(ss: &[f64], ys: &[f64]) -> (Vec<Option<f64>>, Vec<f64>) {
    let (mut num, mut den) = (vec![0.0; 17], vec![0.0; 17]);
    for (s, y) in ss.iter().zip(ys) {
        let (j, a) = hat(*s); num[j] += (1.0 - a) * y; den[j] += 1.0 - a; num[j + 1] += a * y; den[j + 1] += a;
    }
    ((0..17).map(|j| if den[j] >= 100.0 { Some(num[j] / den[j]) } else { None }).collect(), den)
}
fn l2v(lev: &[f64], ss: &[f64], vp: &[f64]) -> Vec<f64> {
    ss.iter().zip(vp).map(|(s, v)| { let l = interp(lev, *s); l * l * v }).collect()
}
fn leverage(ss: &[f64], vp: &[f64], passes: usize) -> (Vec<f64>, [f64; 4]) {
    let (ev, den) = node_avg(ss, vp);
    let ok: Vec<usize> = (0..17).filter(|&j| ev[j].is_some()).collect();
    let cl = |j: usize| j.max(ok[0]).min(ok[ok.len() - 1]);
    let mut lev: Vec<f64> = (0..17).map(|j| SIG / ev[cl(j)].unwrap().sqrt()).collect();
    let first = lev[5];
    for _ in 0..passes {                                             // rescale: average L^2 v -> SIG^2
        let m = node_avg(ss, &l2v(&lev, ss, vp)).0;
        let raw: Vec<f64> = (0..17).map(|j| m[j].map_or(0.0, |x| lev[j] * SIG / x.sqrt())).collect();
        lev = (0..17).map(|j| raw[cl(j)]).collect();
    }
    let info = [den[5], ev[5].unwrap_or(0.0), first, lev[5]]; (lev, info)
}
fn calibrate(seed: u64, passes: usize, cr: f64) -> (Vec<Vec<f64>>, [f64; 4]) {
    let (mut g, mut ss, mut vs, mut table, mut node90) = (seed, vec![S0; NP], vec![V0; NP], Vec::new(), [0.0; 4]);
    for k in 0..NS {
        let vp: Vec<f64> = vs.iter().map(|v| v.max(0.0)).collect();
        let (lev, info) = leverage(&ss, &vp, passes); if k == 20 { node90 = info; }
        for i in 0..NP {
            let (zv, zp) = normals(&mut g); let l = interp(&lev, ss[i]); let sv = (vp[i] * DT).sqrt();
            ss[i] *= ((R - Q - 0.5 * l * l * vp[i]) * DT + l * sv * (RHO * zv + cr * zp)).exp();
            vs[i] += KA * (TH - vp[i]) * DT + XI * sv * zv;
        }
        table.push(lev);
    }
    (table, node90)
}
fn stats(xs: &[f64]) -> Pair {                                       // mean and standard error
    let n = xs.len() as f64; let (mut m, mut s2) = (0.0, 0.0);
    for x in xs { m += x / n; } for x in xs { s2 += (x - m) * (x - m); }
    (m, (s2 / (n - 1.0) / n).sqrt())
}
fn row(label: &str, xs: &[f64], p: usize) {
    println!("{:<30}{}", label, xs.iter().map(|x| format!("{:6.*}", p, x)).collect::<Vec<_>>().join(" "));
}
fn main() {
    let (cr, d) = ((1.0 - RHO * RHO).sqrt(), (-R * T).exp());
    let ((lf_t, node90), ln_t) = (calibrate(1, 2, cr), calibrate(1, 0, cr).0);
    let (mut g, mut s, mut vs, mut ii, mut vv) = (2u64, vec![vec![S0; NP]; 5], vec![V0; NP], vec![0.0; NP], vec![0.0; NP]);
    let (mut s1, mut i1, mut v1, mut cond_slv, mut cond_h) = (vec![], vec![], vec![], vec![], vec![]);
    for k in 0..NS {                     // fresh paths: 0 SLV, 1 no rescaling, 2 L from Heston's cloud, 3 Heston, 4 LV
        let vp: Vec<f64> = vs.iter().map(|v| v.max(0.0)).collect();
        if k == NS / 2 { s1 = s.clone(); i1 = ii.clone(); v1 = vv.clone(); }
        if k == 30 { cond_slv = node_avg(&s[0], &l2v(&lf_t[k], &s[0], &vp)).0; cond_h = node_avg(&s[3], &vp).0; }
        let lw = leverage(&s[3], &vp, 2).0;
        for i in 0..NP {
            let (zv, zp) = normals(&mut g); let w = vp[i]; let sv = (w * DT).sqrt(); let zs = RHO * zv + cr * zp;
            for (m, lev) in [(0, &lf_t[k]), (1, &ln_t[k]), (2, &lw)] {
                let l = interp(lev, s[m][i]); s[m][i] *= ((R - Q - 0.5 * l * l * w) * DT + l * sv * zs).exp();
            }
            s[3][i] *= ((R - Q - 0.5 * w) * DT + sv * zs).exp();
            s[4][i] *= ((R - Q - 0.5 * SIG * SIG) * DT + SIG * DT.sqrt() * zs).exp();
            ii[i] += sv * zv; vv[i] += w * DT; vs[i] += KA * (TH - w) * DT + XI * sv * zv;
        }
    }
    let (c_t, p_t) = (bs(S0, 100.0, T, SIG, true), bs(S0, 100.0, T, SIG, false));
    let fs = S0 * (-Q * T1).exp() * bs(1.0, 1.0, TAU, SIG, true);
    let sd = SIG * TAU.sqrt(); let d1 = (R - Q) * TAU / sd + 0.5 * sd;
    println!("house targets: call {:.6}  put {:.6}  forward-start {:.6}", c_t, p_t, fs);
    println!("forward-start by hand: d1 {:.6}  d2 {:.6}  N(d1) {:.6}  N(d2) {:.6}", d1, d1 - sd, ncdf(d1), ncdf(d1 - sd));
    println!("  half-year call {:.6}  e^-q t1 {:.6}", bs(S0, 100.0, TAU, SIG, true), (-Q * T1).exp());
    println!("node $90, t 0.50: weight {:.1}  E[v|S] {:.6}  sqrt {:.6}  L first {:.4}  L final {:.4}",
             node90[0], node90[1], node90[1].sqrt(), node90[2], node90[3]);
    println!("  L final x 30% vol {:.4}   L final x 10% vol {:.4}", node90[3] * 0.3, node90[3] * 0.1);
    let grid: Vec<f64> = (7..14).map(|j| 10.0 * j as f64).collect();
    row("leverage L(S, t), S =", &grid, 0);
    for k in [10usize, 20, 30] { row(&format!("  t = {:.2}  rescaled", k as f64 * DT), &lf_t[k][3..10], 2); }
    row("  t = 0.75  node values only", &ln_t[30][3..10], 2);
    row("fresh paths, t = 0.75, vol %", &grid, 0);
    row("  Heston  sqrt E[v | S]", &(3..10).map(|j| 100.0 * cond_h[j].unwrap().sqrt()).collect::<Vec<_>>(), 2);
    row("  SLV  sqrt E[L^2 v | S]", &(3..10).map(|j| 100.0 * cond_slv[j].unwrap().sqrt()).collect::<Vec<_>>(), 2);
    println!("one year     target  SLV by paths      SLV - LV same paths   vol %: SLV  Heston");
    let mut rows: Vec<(f64, Vec<Pair>, f64, Vec<f64>)> = Vec::new();
    for (kk, call) in [(80.0, false), (90.0, false), (100.0, false), (100.0, true), (110.0, true), (120.0, true)] {
        let f = |x: f64| if call { (x - kk).max(0.0) } else { (kk - x).max(0.0) };
        let (tgt, plain) = (bs(S0, kk, T, SIG, call), stats(&s[0].iter().map(|x| d * f(*x)).collect::<Vec<_>>()));
        let rw: Vec<Pair> = (0..4).map(|m| stats(&(0..NP).map(|i| d * (f(s[m][i]) - f(s[4][i]))).collect::<Vec<_>>())).collect();
        let iv: Vec<f64> = (0..4).map(|m| 100.0 * ivol(tgt + rw[m].0, S0, kk, T, call)).collect();
        println!("{} {:5.0}  {:7.4}  {:7.4} ± {:.4}   {:+.4} ± {:.4}   {:10.2} {:7.2}", if call { "call" } else { "put " },
                 kk, tgt, plain.0, plain.1, rw[0].0, rw[0].1, iv[0], iv[3]);
        rows.push((kk, rw, tgt, iv));
    }
    let (mut mix_c, mut mix_f) = (vec![], vec![]);                  // Heston, second road: condition on the variance path
    for i in 0..NP {
        let (i2, v2) = (ii[i] - i1[i], vv[i] - v1[i]);
        mix_c.push(bs(S0 * (RHO * ii[i] - 0.5 * RHO * RHO * vv[i]).exp(), 120.0, T, cr * (vv[i] / T).sqrt(), true));
        mix_f.push(S0 * (-Q * T1 + RHO * i1[i] - 0.5 * RHO * RHO * v1[i]).exp()
                   * bs((RHO * i2 - 0.5 * RHO * RHO * v2).exp(), 1.0, TAU, cr * (v2 / TAU).sqrt(), true));
    }
    let (hc, mc, mf) = (stats(&s[3].iter().map(|x| d * (x - 120.0).max(0.0)).collect::<Vec<_>>()), stats(&mix_c), stats(&mix_f));
    let fsp: Vec<Pair> = [3, 4].iter().map(|&m| stats(&(0..NP).map(|i| d * (s[m][i] - s1[m][i]).max(0.0)).collect::<Vec<_>>())).collect();
    println!("Heston call 120       paths {:.4} ± {:.4}   mixing formula {:.4} ± {:.4}", hc.0, hc.1, mc.0, mc.1);
    println!("Heston forward-start  paths {:.4} ± {:.4}   mixing formula {:.4} ± {:.4}", fsp[0].0, fsp[0].1, mf.0, mf.1);
    println!("local-vol forward-start  paths {:.4} ± {:.4}", fsp[1].0, fsp[1].1);
    println!("forward start  LV exact    SLV, same paths     Heston, same paths   fwd vol %: LV   SLV  Heston");
    let mut fwd11 = vec![];
    for kk in [0.8, 0.9, 1.0, 1.1, 1.2] {
        let ex = S0 * (-Q * T1).exp() * bs(1.0, kk, TAU, SIG, true);
        let fw: Vec<Pair> = [0, 3].iter().map(|&m| stats(&(0..NP)
            .map(|i| d * ((s[m][i] - kk * s1[m][i]).max(0.0) - (s[4][i] - kk * s1[4][i]).max(0.0))).collect::<Vec<_>>())).collect();
        let iv: Vec<f64> = [0.0, fw[0].0, fw[1].0].iter()
            .map(|x| 100.0 * ivol((ex + x) / (S0 * (-Q * T1).exp()), 1.0, kk, TAU, true)).collect();
        println!("  k = {:.1}    {:8.4}   {:8.4} ± {:.4}   {:8.4} ± {:.4}   {:8.2} {:6.2} {:6.2}",
                 kk, ex, ex + fw[0].0, fw[0].1, ex + fw[1].0, fw[1].1, iv[0], iv[1], iv[2]);
        if kk == 1.1 { fwd11 = fw; }
    }
    let (a, b) = (&rows[3], &rows[5]);
    println!("what breaks, priced against LV on the same paths   call 100 (vol %)          call 120 (vol %)");
    for (m, name) in [(3, "pure Heston, L = 1"), (2, "L fitted to pure-Heston paths"), (1, "node values, no rescaling")] {
        println!("  {:<34} {:.4} ± {:.4} ({:.2})   {:.4} ± {:.4} ({:.2})",
                 name, a.2 + a.1[m].0, a.1[m].1, a.3[m], b.2 + b.1[m].0, b.1[m].1, b.3[m]);
    }
    assert!((c_t - 9.227005508154).abs() < 1e-9, "own normal CDF vs the house call");
    assert!((fs - 6.244873136513).abs() < 1e-9, "forward-start closed form vs the house anchor");
    for r in &rows { assert!(r.1[0].0.abs() < 3.0 * r.1[0].1, "SLV must reprice K = {} within 3 s.e.", r.0); }
    assert!(b.1[3].0.abs() > 10.0 * b.1[3].1, "without leverage Heston misses");
    assert!(a.1[2].0.abs() > 3.0 * a.1[2].1, "leverage from the wrong cloud misses");
    assert!((hc.0 - mc.0).abs() < 3.0 * hc.1, "Heston call: paths vs mixing formula");
    assert!((fsp[0].0 - mf.0).abs() < 3.0 * fsp[0].1, "Heston forward-start: paths vs mixing formula");
    assert!((fsp[1].0 - fs).abs() < 3.0 * fsp[1].1, "local-vol forward-start: paths vs closed form");
    assert!(fwd11[1].0 + 3.0 * fwd11[1].1 < fwd11[0].0 && fwd11[0].0 < -3.0 * fwd11[0].1, "SLV between LV and Heston");
    assert!((4..9).all(|j| (cond_slv[j].unwrap().sqrt() - SIG).abs() < 0.005), "fresh paths: E[L^2 v | S] = SIG^2");
    println!("ALL CHECKS PASS");
}
