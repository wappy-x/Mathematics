// Bivariate normal and conditioning -- the same check as the Python, in Rust.  No crates.
// Adult height H (cm) and weight W (kg): centres 175 and 75, spreads 7 and 12,
// correlation 0.5.  The law of weight among adults 189 cm tall is reached three
// ways: the formula, a slice of the joint density integrated by Simpson's rule,
// and a seeded simulation.  Nothing used holds the answer.
use std::f64::consts::PI;

const MH: f64 = 175.0; const SH: f64 = 7.0; const MW: f64 = 75.0; const SW: f64 = 12.0;
const RHO: f64 = 0.5;
const H0: f64 = 189.0; const W0: f64 = 90.0; // the question: over 90 kg, at 189 cm tall

fn phi(z: f64) -> f64 { (-z * z / 2.0).exp() / (2.0 * PI).sqrt() } // standard normal density

fn cdf(z: f64) -> f64 { // standard normal area, Taylor series term by term
    let (mut term, mut total) = (z, z);
    for n in 1..200 {
        let n = n as f64;
        term *= -z * z / (2.0 * n);
        total += term / (2.0 * n + 1.0);
    }
    0.5 + total / (2.0 * PI).sqrt()
}

fn simpson(g: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 { // Simpson's rule, n even
    let h = (b - a) / n as f64;
    let mut s = 0.0;
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * g(a + i as f64 * h); }
    (g(a) + g(b) + s) * h / 3.0
}

fn joint(h: f64, w: f64) -> f64 { // the bivariate normal density, per cm per kg
    let (x, y) = ((h - MH) / SH, (w - MW) / SW);
    let q = (x * x - 2.0 * RHO * x * y + y * y) / (1.0 - RHO * RHO);
    (-q / 2.0).exp() / (2.0 * PI * SH * SW * (1.0 - RHO * RHO).sqrt())
}

fn cond(h: f64, rho: f64) -> (f64, f64, f64) { // road 1: the formula -> (mean, spread, P(W > W0))
    let (m, s) = (MW + rho * SW * (h - MH) / SH, SW * (1.0 - rho * rho).sqrt());
    (m, s, 1.0 - cdf((W0 - m) / s))
}

struct SplitMix(u64); // road 3: SplitMix64, seed 20260928
impl SplitMix {
    fn next(&mut self) -> u64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    }
    fn uniform(&mut self) -> f64 { ((self.next() >> 11) as f64 + 0.5) / 2f64.powi(53) } // in (0, 1)
    fn normal_pair(&mut self) -> (f64, f64) { // Marsaglia's polar method
        loop {
            let (u, v) = (2.0 * self.uniform() - 1.0, 2.0 * self.uniform() - 1.0);
            let s = u * u + v * v;
            if s > 0.0 && s < 1.0 { let k = (-2.0 * s.ln() / s).sqrt(); return (u * k, v * k); }
        }
    }
}

fn main() {
    let (m1, s1, p1) = cond(H0, RHO);
    println!("model: height {:.1} cm sd {:.1}; weight {:.1} kg sd {:.1}; rho {:.2}", MH, SH, MW, SW, RHO);
    println!("covariance rho*sH*sW = {:.3} cm kg; height z at {:.0} cm = {:.3}", RHO * SH * SW, H0, (H0 - MH) / SH);
    println!("slope rho*sW/sH = {:.6} kg per cm; reverse slope rho*sH/sW = {:.6} cm per kg", RHO * SW / SH, RHO * SH / SW);
    println!("  inverting the first slope instead: {:.6} cm per kg; mean height at 99 kg {:.1} cm", SH / (RHO * SW), MH + RHO * SH * (99.0 - MW) / SW);
    println!("rho^2 = {:.4}; spread shrink sqrt(1 - rho^2) = {:.6}; variances sH^2 {:.0}, sW^2 {:.0} = line {:.0} + leftover {:.0}",
        RHO * RHO, (1.0 - RHO * RHO).sqrt(), SH * SH, SW * SW, RHO * RHO * SW * SW, (1.0 - RHO * RHO) * SW * SW);
    let (lo, hi) = (MW - 12.0 * SW, MW + 12.0 * SW); // road 2: slice the joint density at 189 cm
    let g = |w: f64| joint(H0, w);
    let fx = simpson(&g, lo, hi, 4000);
    let m2 = simpson(&|w| w * g(w), lo, hi, 4000) / fx;
    let s2 = (simpson(&|w| (w - m2).powi(2) * g(w), lo, hi, 4000) / fx).sqrt();
    let p2 = simpson(&g, W0, hi, 4000) / fx;
    println!("at {:.0} cm   formula: mean {:.6} kg, sd {:.6} kg, P(W > 90) {:.6}, z of 90 kg {:.4}", H0, m1, s1, p1, (W0 - m1) / s1);
    println!("at {:.0} cm   slice:   mean {:.6} kg, sd {:.6} kg, P(W > 90) {:.6}", H0, m2, s2, p2);
    println!("height density at {:.0} cm: slice area {:.8}, phi(2)/7 {:.8}", H0, fx, phi((H0 - MH) / SH) / SH);
    println!("P(W > 90) ignoring height: z {:.4}, P {:.6}", (W0 - MW) / SW, 1.0 - cdf((W0 - MW) / SW));
    // flip pair: normal weight, correlation 0.5, not jointly normal
    let flip_corr = |c: f64| 4.0 * simpson(&|z| z * z * phi(z), 0.0, c, 400) - 1.0;
    let (mut a, mut b) = (0.0_f64, 5.0_f64); // bisection for the cutoff
    for _ in 0..60 {
        let c = (a + b) / 2.0;
        if flip_corr(c) < RHO { a = c; } else { b = c; }
    }
    let cut = (a + b) / 2.0;
    let flip_w = |z: f64| MW + SW * if z.abs() < cut { z } else { -z };
    println!("flip pair: cutoff c = {:.6}, correlation by integral {:.6}", cut, flip_corr(cut));
    println!("  weight at 189 cm: {:.1} kg, P(W > 90) = 1; at 192.5 cm: {:.1} kg vs line {:.1}", flip_w(2.0), flip_w(2.5), cond(192.5, RHO).0);
    let n = 400000usize; // road 3: simulation
    let nf = n as f64;
    let mut rng = SplitMix(20260928);
    let (mut sh, mut sw, mut shh, mut sww, mut shw, mut sf, mut sff, mut shf) = (0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
    let (mut nwin, mut swin, mut swin2, mut nover, mut both, mut inside) = (0usize, 0.0, 0.0, 0usize, 0usize, 0usize);
    for _ in 0..n {
        let (z1, z2) = rng.normal_pair();
        let (h, w) = (MH + SH * z1, MW + SW * (RHO * z1 + (1.0 - RHO * RHO).sqrt() * z2));
        let f = flip_w(z1);
        sh += h; sw += w; shh += h * h; sww += w * w; shw += h * w;
        sf += f; sff += f * f; shf += h * f;
        let (x, y) = ((h - MH) / SH, (w - MW) / SW);
        if x > 0.0 && y > 0.0 { both += 1; }
        if (x * x - 2.0 * RHO * x * y + y * y) / (1.0 - RHO * RHO) <= 4.0 { inside += 1; }
        if (188.0..=190.0).contains(&h) {
            nwin += 1; swin += w; swin2 += w * w;
            if w > W0 { nover += 1; }
        }
    }
    let (vh, vw, vf) = (shh / nf - (sh / nf).powi(2), sww / nf - (sw / nf).powi(2), sff / nf - (sf / nf).powi(2));
    let corr = (shw / nf - sh * sw / nf / nf) / (vh * vw).sqrt();
    let corr_f = (shf / nf - sh * sf / nf / nf) / (vh * vf).sqrt();
    let nw = nwin as f64;
    let mw_win = swin / nw;
    let sd_win = (swin2 / nw - mw_win * mw_win).sqrt();
    let (se_m, p_win) = (sd_win / nw.sqrt(), nover as f64 / nw);
    let se_p = (p_win * (1.0 - p_win) / nw).sqrt();
    let (p_both, p_in) = (both as f64 / nf, inside as f64 / nf);
    let (se_both, se_in) = ((p_both * (1.0 - p_both) / nf).sqrt(), (p_in * (1.0 - p_in) / nf).sqrt());
    println!("simulation, {} adults, seed 20260928:", n);
    println!("  correlation {:.4} (se about {:.4}); slope {:.4} kg per cm", corr, (1.0 - RHO * RHO) / nf.sqrt(), corr * (vw / vh).sqrt());
    println!("  heights 188-190 cm: {} adults, mean weight {:.3} (se {:.3}), sd {:.3}", nwin, mw_win, se_m, sd_win);
    println!("  share over 90 kg there: {:.4} (se {:.4})", p_win, se_p);
    println!("  flip pair: correlation {:.4}, weight sd {:.3}", corr_f, vf.sqrt());
    let p_or = 0.25 + RHO.asin() / (2.0 * PI);
    let p_or2 = simpson(&|z| phi(z) * cdf(RHO * z / (1.0 - RHO * RHO).sqrt()), 0.0, 12.0, 4000);
    println!("both above average: arcsin rule {:.6}, integral {:.6}, simulation {:.4} (se {:.4})", p_or, p_or2, p_both, se_both);
    println!("inside the Q = 4 ellipse: 1 - e^-2 = {:.6}, simulation {:.4} (se {:.4})", 1.0 - (-2.0f64).exp(), p_in, se_in);
    let (wm, full) = (MW + RHO * SH * (H0 - MH) / SW, MW + SW * (H0 - MH) / SH); // upside-down slope; slope sW/sH
    println!("wrong: slope upside down: mean {:.4}, P(W > 90) {:.6}", wm, 1.0 - cdf((W0 - wm) / s1));
    println!("wrong: spread not shrunk: P(W > 90) {:.6}", 1.0 - cdf((W0 - m1) / SW));
    println!("wrong: full step, no regression: mean {:.1}, P(W > 90) {:.6}", full, 1.0 - cdf((W0 - full) / s1));
    for r in [0.9, 0.0, -0.5] {
        let (m, s, p) = cond(H0, r);
        println!("try: rho {:+.1} at 189 cm: mean {:.3}, sd {:.3}, P(W > 90) {:.6}", r, m, s, p);
    }
    let (m, s, p) = cond(161.0, RHO);
    println!("try: rho +0.5 at 161 cm: mean {:.3}, sd {:.3}, P(W > 90) {:.6}", m, s, p);
    let ws: Vec<f64> = (0..13).map(|i| 45.0 + 5.0 * i as f64).collect();
    let row = |f: &dyn Fn(f64) -> f64, d: usize| ws.iter().map(|&w| format!("{:5.*}", d, f(w))).collect::<Vec<_>>().join(" ");
    println!("chart, weight kg        {}", row(&|w| w, 0));
    println!("chart, at 189 cm %/kg   {}", row(&|w| 100.0 * phi((w - m1) / s1) / s1, 2));
    println!("chart, all adults %/kg  {}", row(&|w| 100.0 * phi((w - MW) / SW) / SW, 2));
    let px = |h: f64| 40.0 + (h - 154.0) * 300.0 / 42.0; // cm, kg -> pixels
    let py = |w: f64| 220.0 - (w - 39.0) * 192.0 / 72.0;
    let pts: Vec<String> = (0..36).map(|k| {
        let t = 2.0 * PI * k as f64 / 36.0;
        let (zx, zy) = (2.0 * t.cos(), 2.0 * (RHO * t.cos() + (1.0 - RHO * RHO).sqrt() * t.sin()));
        format!("{:.1},{:.1}", px(MH + SH * zx), py(MW + SW * zy))
    }).collect();
    println!("figure, ellipse Q = 4: {}", pts.join(" "));
    let hw = |w: f64| MH + RHO * SH * (w - MW) / SW;
    println!("figure, W on H line: {:.1},{:.1} {:.1},{:.1}; H on W line: {:.1},{:.1} {:.1},{:.1}",
        px(154.0), py(cond(154.0, RHO).0), px(196.0), py(cond(196.0, RHO).0), px(hw(39.0)), py(39.0), px(hw(111.0)), py(111.0));
    println!("figure, point (189, 87): {:.1},{:.1}; ticks x {:.1} {:.1} {:.1}; y {:.1} {:.1} {:.1}",
        px(H0), py(m1), px(161.0), px(175.0), px(189.0), py(51.0), py(75.0), py(99.0));
    let ends: Vec<String> = [(2.0, 1.0), (-2.0, -1.0), (1.0, 2.0), (-1.0, -2.0)].iter()
        .map(|&(a, b): &(f64, f64)| format!("({:.0}, {:.0})", MH + SH * a, MW + SW * b)).collect();
    println!("figure, scale {:.2} px per cm, {:.2} px per kg; ellipse ends (cm, kg): {}", px(155.0) - px(154.0), py(39.0) - py(40.0), ends.join(" "));
    assert!((m2 - m1).abs() < 1e-9, "slice mean vs the formula's straight line");
    assert!((s2 - s1).abs() < 1e-9, "slice spread vs sW sqrt(1 - rho^2)");
    assert!((p2 - p1).abs() < 1e-9, "slice tail area vs the Phi series");
    assert!((fx - phi((H0 - MH) / SH) / SH).abs() < 1e-12, "slice area vs height's own density");
    assert!((mw_win - m1).abs() < 4.0 * se_m, "simulated mean weight at 188-190 cm vs formula");
    assert!((p_win - p1).abs() < 4.0 * se_p, "simulated share over 90 kg vs formula");
    assert!((p_or - p_or2).abs() < 1e-9, "arcsin rule vs integral");
    assert!((p_both - p_or).abs() < 4.0 * se_both, "arcsin rule vs simulation");
    assert!((p_in - (1.0 - (-2.0f64).exp())).abs() < 4.0 * se_in, "ellipse share vs 1 - e^-2");
    assert!((corr_f - RHO).abs() < 4.0 * (1.0 - RHO * RHO) / nf.sqrt(), "flip pair: simulated correlation vs the integral's 0.5");
    println!("ALL CHECKS PASS");
}
