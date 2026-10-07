// Market models: ten forwards under the terminal measure -- the same check in Rust, std only.
// The normal CDF, the random numbers and every sum are written here.  No crates.
use std::f64::consts::PI;
const N: usize = 10; const DL: f64 = 0.5; const T0: f64 = 1.0;   // ten half-year forwards, first reset 1y
type Curve = [f64; N];
fn vol(i: usize) -> [f64; 2] { [0.20 - 0.005 * i as f64, 0.08 + 0.003 * i as f64] }
fn dot(x: [f64; 2], y: [f64; 2]) -> f64 { x[0] * y[0] + x[1] * y[1] }
// rule: 'T' terminal bond, 'F' first bond, 'N' none, 'S' sign flipped, 'I' own term included
fn drift(l: &Curve, rule: char) -> Curve {
    let mut mu = [0.0; N];
    if rule == 'N' { return mu; }
    let (mut s0, mut s1) = (0.0, 0.0);
    let order: Vec<usize> = if rule == 'F' { (0..N).collect() } else { (0..N).rev().collect() };
    for i in order {
        let ai = DL * l[i] / (1.0 + DL * l[i]);
        let v = vol(i);
        if rule == 'F' || rule == 'I' { s0 += ai * v[0]; s1 += ai * v[1]; }
        let sg = if rule == 'F' || rule == 'S' { 1.0 } else { -1.0 };
        mu[i] = sg * (v[0] * s0 + v[1] * s1) + 0.0;
        if rule == 'T' || rule == 'S' { s0 += ai * v[0]; s1 += ai * v[1]; }
    }
    mu
}
// log-Euler predictor, then a trapezoid corrector on the drift; the same kick both times
fn step(l: &Curve, rule: char, h: f64, z: [f64; 2], pc: bool) -> Curve {
    let mut kick = [0.0; N]; for i in 0..N { kick[i] = h.sqrt() * dot(vol(i), z) - 0.5 * dot(vol(i), vol(i)) * h; }
    let m0 = drift(l, rule);
    let (mut lp, mut out) = ([0.0; N], [0.0; N]);
    for i in 0..N { lp[i] = l[i] * (m0[i] * h + kick[i]).exp(); }
    if !pc { return lp; }
    let m1 = drift(&lp, rule);
    for i in 0..N { out[i] = l[i] * (0.5 * (m0[i] + m1[i]) * h + kick[i]).exp(); }
    out
}
// road 2 for the drift: bump each factor, read the loading of the log bond ratio
fn bump_drift(l: &Curve, i: usize) -> f64 {
    let eps = 1e-6;
    let log_d = |k: usize, e: f64| -> f64 { ((i + 1)..N).fold(0.0, |s, j| s + (1.0 + DL * l[j] * (e * vol(j)[k]).exp()).ln()) };
    let load = [(log_d(0, eps) - log_d(0, -eps)) / (2.0 * eps), (log_d(1, eps) - log_d(1, -eps)) / (2.0 * eps)];
    -dot(vol(i), load) + 0.0
}
fn ncdf(x: f64) -> f64 {   // bell-curve area left of x, by Simpson's rule from 0
    let (m, mut s) = (2000, 0.0);
    let f = |u: f64| (-0.5 * u * u).exp() / (2.0 * PI).sqrt();
    let hh = x / m as f64;
    for k in 1..m { s += if k % 2 == 1 { 4.0 } else { 2.0 } * f(k as f64 * hh); }
    0.5 + hh / 3.0 * (f(0.0) + f(x) + s)
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
// caplet on L_0, swaption, bond ratio: each in numeraire units at T0
fn at_reset(l: &Curve, rule: char, s0: f64) -> [f64; 3] {
    let (mut w, mut acc) = ([0.0; N], 1.0);
    if rule == 'F' { for i in 0..N { acc /= 1.0 + DL * l[i]; w[i] = acc; } }
    else { for i in (0..N).rev() { w[i] = acc; acc *= 1.0 + DL * l[i]; } }
    let cap = DL * (l[0] - 0.03).max(0.0) * w[0];
    let sw = (0..N).fold(0.0, |s, i| s + DL * (l[i] - s0) * w[i]);
    [cap, sw.max(0.0), acc]
}

fn main() {
    let mut l0 = [0.0; N]; for i in 0..N { l0[i] = 0.030 + 0.001 * i as f64; }
    let mut p = vec![(-0.03 * T0).exp()];
    for i in 0..N { let last = p[i]; p.push(last / (1.0 + DL * l0[i])); }
    let ann: f64 = p[1..].iter().fold(0.0, |a, b| a + b); let s0 = (p[0] - p[N]) / (DL * ann);
    let (rules, m, steps, mut rng) = (['T', 'F', 'N', 'S', 'I'], 12000usize, 4usize, Rng(20260928));
    let (mut tot, mut dif) = ([[[0.0f64; 2]; 3]; 5], [[0.0f64; 2]; 5]);
    for _ in 0..m {
        let zs: Vec<[f64; 2]> = (0..steps).map(|_| rng.normals()).collect();
        let mut val = [[0.0f64; 3]; 5];
        for (ri, &r) in rules.iter().enumerate() {
            let mut acc = [0.0; 3];
            for sg in [1.0, -1.0] {
                let mut l = l0;
                for z in &zs { l = step(&l, r, T0 / steps as f64, [sg * z[0], sg * z[1]], true); }
                let v = at_reset(&l, r, s0);
                for k in 0..3 { acc[k] += 0.5 * v[k]; }
            }
            let num = if r == 'F' { p[0] } else { p[N] };
            val[ri] = [acc[0] * num, acc[1] * num, acc[2]];
            for k in 0..3 { tot[ri][k][0] += val[ri][k]; tot[ri][k][1] += val[ri][k] * val[ri][k]; }
            let d = val[ri][1] - val[0][1]; dif[ri][0] += d; dif[ri][1] += d * d;
        }
    }
    let mf = m as f64;
    let ms = |s: [f64; 2]| (s[0] / mf, ((s[1] / mf - (s[0] / mf).powi(2)).max(0.0) / mf).sqrt());
    println!("market model: ten half-year forwards, first reset T0 = 1 year");
    println!("P(0,T0) {:.6}  P(0,T10) {:.6}  swap rate S0 {:.6}%  annuity {:.6}", p[0], p[N], s0 * 100.0, DL * ann);
    println!("  i  L_i(0) %   drift terminal %/yr   bump road %/yr   drift first bond %/yr");
    let (mu_t, mu_f) = (drift(&l0, 'T'), drift(&l0, 'F'));
    let bump: Vec<f64> = (0..N).map(|i| bump_drift(&l0, i)).collect();
    for i in 0..N { println!("{:>3} {:9.3} {:21.4} {:16.4} {:23.4}", i, l0[i] * 100.0, mu_t[i] * 100.0, bump[i] * 100.0, mu_f[i] * 100.0); }
    for (r, mu) in [("terminal", mu_t), ("first bond", mu_f)] {
        let vals: Vec<String> = (0..N).map(|i| format!("{:5.2}", mu[i] * l0[i] * 1e4)).collect();
        println!("chart, {:<25}{}", format!("{} drift bp/yr", r), vals.join(" "));
    }
    let terms: Vec<String> = (1..N).map(|j| format!("{:.4}", DL * l0[j] / (1.0 + DL * l0[j]) * dot(vol(0), vol(j)) * 100.0)).collect();
    println!("drift of L_0, terms a_j sigma_0.sigma_j, %/yr: {}", terms.join(" "));
    let (hp, hc) = (step(&l0, 'T', 0.25, [0.2, -0.4], false), step(&l0, 'T', 0.25, [0.2, -0.4], true));
    println!("hand step, h = 0.25, z = (0.2, -0.4): sigma_0.dW {:.6}  half variance x h {:.6}", dot(vol(0), [0.1, -0.2]), 0.5 * dot(vol(0), vol(0)) * 0.25);
    println!("  L_0 drift at start {:.6}%/yr, on the predicted curve {:.6}%/yr", mu_t[0] * 100.0, drift(&hp, 'T')[0] * 100.0);
    println!("  log move of L_0: predicted {:.8}, corrected {:.8}", (hp[0] / l0[0]).ln(), (hc[0] / l0[0]).ln());
    println!("  L_0 predicted {:.9}%  corrected {:.9}%;  L_9 both {:.9}%", hp[0] * 100.0, hc[0] * 100.0, hc[9] * 100.0);
    let (mut dbl, mut hlf) = (l0, l0); for i in 0..N { dbl[i] *= 2.0; hlf[i] /= 2.0; }
    println!("try: L_0 drift %/yr, rates doubled {:.4}, rates halved {:.4}; no-shock step L_0 {:.6}%",
             drift(&dbl, 'T')[0] * 100.0, drift(&hlf, 'T')[0] * 100.0, step(&l0, 'T', 0.25, [0.0, 0.0], true)[0] * 100.0);
    let vbar = dot(vol(0), vol(0)).sqrt();
    let d1 = ((l0[0] / 0.03).ln() + 0.5 * vbar.powi(2) * T0) / (vbar * T0.sqrt());
    let black = DL * p[1] * (l0[0] * ncdf(d1) - 0.03 * ncdf(d1 - vbar * T0.sqrt()));
    println!("caplet on L_0, K = 3%, per $1m: Black-76 {:.2}  (vol {:.4}%, d1 {:.6})", black * 1e6, vbar * 100.0, d1);
    for (ri, name) in [(0usize, "terminal bond"), (1, "first bond")] {
        let (mm, se) = ms(tot[ri][0]);
        println!("  Monte Carlo, {:<13} {:9.2}  se {:.2}", name, mm * 1e6, se * 1e6);
    }
    println!("payer swaption 1y into 5y, K = S0, per $1m, {} paths, {} predictor-corrector steps:", 2 * m, steps);
    let names = ["terminal bond, drift", "first bond, drift", "terminal, no drift", "terminal, sign flipped", "terminal, own term in"];
    for ri in 0..5 {
        let ((mm, se), (dm, dse)) = (ms(tot[ri][1]), ms(dif[ri]));
        println!("  {:<23} {:10.2}  se {:6.2}   minus terminal {:8.2}  se {:5.2}", names[ri], mm * 1e6, se * 1e6, dm * 1e6, dse * 1e6);
    }
    let target = p[0] / p[N];
    println!("bond ratio P(T0,T0)/P(T0,T10), must average today's {:.6}:", target);
    for ri in [0usize, 2, 3, 4] {
        let (mm, se) = ms(tot[ri][2]);
        println!("  {:<23} {:.6}  se {:.6}  off by {:+7.2} se", names[ri], mm, se, (mm - target) / se);
    }
    let (mm, se) = ms(tot[1][2]);
    println!("  first bond: P(T0,T10) {:.6}  se {:.6}  must average {:.6}", mm, se, 1.0 / target);

    println!("same kicks, 2000 paths: error in L_0(1) against 64 steps, hundredths of a basis point");
    let (paths, ks, mut err) = (2000usize, [1usize, 2, 4, 8], [[[0.0f64; 2]; 2]; 4]);   // err[k][pc][average, size]
    for _ in 0..paths {
        let zf: Vec<[f64; 2]> = (0..64).map(|_| rng.normals()).collect();
        let mut lr = l0; for z in &zf { lr = step(&lr, 'T', T0 / 64.0, *z, true); }
        for (ki, &k) in ks.iter().enumerate() {
            let g = 64 / k;
            let zk: Vec<[f64; 2]> = (0..k).map(|s| {
                let mut c = [0.0; 2];
                for z in &zf[s * g..(s + 1) * g] { c[0] += z[0]; c[1] += z[1]; }
                [c[0] / (g as f64).sqrt(), c[1] / (g as f64).sqrt()]
            }).collect();
            for (pi, pc) in [false, true].iter().enumerate() {
                let mut lc = l0; for z in &zk { lc = step(&lc, 'T', T0 / k as f64, *z, *pc); }
                err[ki][pi][0] += (lc[0] - lr[0]) * 1e6 / paths as f64;
                err[ki][pi][1] += (lc[0] - lr[0]).abs() * 1e6 / paths as f64;
            }
        }
    }
    for (ki, k) in ks.iter().enumerate() {
        println!("  {} steps  average: Euler {:7.4}  corrector {:7.4}   size: Euler {:7.4}  corrector {:7.4}",
                 k, err[ki][0][0], err[ki][1][0], err[ki][0][1], err[ki][1][1]);
    }
    assert!((0..N).all(|i| (mu_t[i] - bump[i]).abs() < 1e-10), "drift formula vs bumped bond ratio");
    assert!((hc[0] - 0.029897065778).abs() < 1e-11, "hand step vs the audited value");
    for ri in 0..2 { let (mm, se) = ms(tot[ri][0]); assert!((mm - black).abs() < 3.0 * se, "caplet MC vs Black-76"); }
    let (dm, dse) = ms(dif[1]); assert!(dm.abs() < 3.0 * dse, "two measures, one swaption price");
    let (dm, dse) = ms(dif[2]); assert!(dm.abs() > 3.0 * dse, "dropping the drift must move the price");
    let (mm, se) = ms(tot[0][2]); assert!((mm - target).abs() < 3.0 * se, "bond ratio is a fair bet");
    assert!((0..4).all(|ki| err[ki][1][0].abs() < err[ki][0][0].abs() / 4.0), "corrector bias");
    println!("ALL CHECKS PASS");
}
