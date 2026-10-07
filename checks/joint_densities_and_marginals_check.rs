// Joint densities and marginals -- the same check as the Python, in Rust.  No
// crates.  The surface is a tilted bell for adult height H (cm) and weight
// W (kg): centre 175 cm and 78 kg, spreads 7 cm and 12 kg, tilt rho = 0.5.
// The tail chance P(H > 185, W > 90) is reached three ways: a grid over the
// whole surface, slices with a closed inner area, and 200,000 simulated adults.
use std::f64::consts::PI;

const MH: f64 = 175.0;
const SH: f64 = 7.0;
const MW: f64 = 78.0;
const SW: f64 = 12.0;
const RHO: f64 = 0.5;

fn c() -> f64 { (1.0 - RHO * RHO).sqrt() }        // the tilt's squeeze factor

fn f(h: f64, w: f64) -> f64 {                      // the joint density, per cm per kg
    let (zh, zw) = ((h - MH) / SH, (w - MW) / SW);
    let q = (zh * zh - 2.0 * RHO * zh * zw + zw * zw) / (c() * c());
    (-q / 2.0).exp() / (2.0 * PI * SH * SW * c())
}

fn bell(x: f64, m: f64, s: f64) -> f64 {           // a one-variable normal density
    let z = (x - m) / s;
    (-z * z / 2.0).exp() / (s * (2.0 * PI).sqrt())
}

fn phi(x: f64) -> f64 {                            // standard normal area left of x, by Taylor series
    let (mut term, mut total, mut n) = (x, x, 0.0);
    while term.abs() > 1e-17 * total.abs().max(1.0) {
        n += 1.0;
        term *= -x * x / (2.0 * n);
        total += term / (2.0 * n + 1.0);
    }
    0.5 + total / (2.0 * PI).sqrt()
}

fn simpson(g: &dyn Fn(f64) -> f64, a: f64, b: f64) -> f64 {   // Simpson's rule, 400 panels
    let n = 400;
    let step = (b - a) / n as f64;
    let mut s = g(a) + g(b);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * g(a + i as f64 * step) }
    s * step / 3.0
}

fn grid(g: &dyn Fn(f64, f64) -> f64, h0: f64, h1: f64, w0: f64, w1: f64) -> f64 {
    simpson(&|h| simpson(&|w| g(h, w), w0, w1), h0, h1)     // road 1: the double integral
}

struct SplitMix(u64);
impl SplitMix {
    fn uniform(&mut self) -> f64 {                 // a number strictly between 0 and 1
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^= z >> 31;
        ((z >> 11) as f64 + 0.5) / 9007199254740992.0
    }
}

fn main() {
    let cc = c();
    let (hl, hr, wl, wr) = (MH - 10.0 * SH, MH + 10.0 * SH, MW - 10.0 * SW, MW + 10.0 * SW);
    let total = grid(&f, hl, hr, wl, wr);
    let cov = grid(&|h, w| (h - MH) * (w - MW) * f(h, w), hl, hr, wl, wr);
    let tail_grid = grid(&f, 185.0, hr, 90.0, wr);
    let z90 = (90.0 - MW) / SW;                    // road 2: slices, inner area in closed form
    let tail_slices = simpson(&|h| bell(h, MH, SH) * (1.0 - phi((z90 - RHO * (h - MH) / SH) / cc)), 185.0, hr);
    let heights: Vec<f64> = (0..15).map(|i| 154.0 + 3.0 * i as f64).collect();
    let marg: Vec<f64> = heights.iter().map(|&h| simpson(&|w| f(h, w), wl, wr)).collect();
    let marg_err = heights.iter().zip(&marg).map(|(&h, &m)| (m - bell(h, MH, SH)).abs()).fold(0.0, f64::max);

    let n = 200000usize;
    let mut rng = SplitMix(20260928);
    let r50 = (-2.0 * 0.5f64.ln()).sqrt();
    let (mut n_tail, mut n_mid, mut n_heavy, mut n_ring) = (0usize, 0usize, 0usize, 0usize);
    let mut bins = [0usize; 15];                   // 3-cm bins centred on 154, 157, ..., 196
    for _ in 0..n {                                // road 3: simulated adults, by Box-Muller
        let r = (-2.0 * rng.uniform().ln()).sqrt();
        let a = 2.0 * PI * rng.uniform();
        let (z1, z2) = (r * a.cos(), r * a.sin());
        let (h, w) = (MH + SH * z1, MW + SW * (RHO * z1 + cc * z2));
        if h > 185.0 && w > 90.0 { n_tail += 1 }
        if 170.0 < h && h < 180.0 { n_mid += 1 }
        if w > 90.0 { n_heavy += 1 }
        if z1 * z1 + z2 * z2 < r50 * r50 { n_ring += 1 }
        let k = ((h - 152.5) / 3.0).floor();
        if k >= 0.0 && k < 15.0 { bins[k as usize] += 1 }
    }
    let nf = n as f64;
    let p_sim = n_tail as f64 / nf;
    let se = (p_sim * (1.0 - p_sim) / nf).sqrt();
    let mid_exact = phi(5.0 / 7.0) - phi(-5.0 / 7.0);
    let mid_sim = n_mid as f64 / nf;
    let mid_se = (mid_sim * (1.0 - mid_sim) / nf).sqrt();
    let heavy_sim = n_heavy as f64 / nf;
    let heavy_se = (heavy_sim * (1.0 - heavy_sim) / nf).sqrt();

    let peak = f(MH, MW);
    let (fh, fw) = (bell(MH, MH, SH), bell(MW, MW, SW));
    let box1 = grid(&f, 174.5, 175.5, 77.5, 78.5);
    let box2 = grid(&f, 174.95, 175.05, 77.95, 78.05);
    let (ph, pw) = (1.0 - phi(10.0 / 7.0), 1.0 - phi(1.0));
    let slice_area = simpson(&|h| f(h, 78.0), hl, hr);
    let slice_sd = (simpson(&|h| (h - MH).powi(2) * f(h, 78.0), hl, hr) / slice_area).sqrt();
    let cut_total = grid(&f, hl, hr, wl, 90.0);   // weight integral stopped at 90 kg

    println!("surface: centre {:.0} cm, {:.0} kg; spreads {:.0} cm, {:.0} kg; tilt {}", MH, MW, SH, SW, RHO);
    println!("total volume under the surface, grid:        {:.10}", total);
    println!("covariance from the surface, grid:            {:.6} cm kg (rho x 7 x 12 = {:.1})", cov, RHO * SH * SW);
    println!("peak height f(175, 78):                       {:.6} per cm per kg", peak);
    println!("chance in the 1 cm x 1 kg box at the peak:   {:.6}  (about 1 in {:.0})", box1, 1.0 / box1);
    println!("chance in the 1 mm x 100 g box at the peak:  {:.8}", box2);
    println!("marginal of height at 175, 1/(7 sqrt(2 pi)):  {:.6} per cm", fh);
    println!("marginal of weight at 78, 1/(12 sqrt(2 pi)):  {:.6} per kg", fw);
    println!("product of the two marginals at the peak:    {:.6}  (peak / product = {:.4})", fh * fw, peak / (fh * fw));
    println!("integrated-out marginal = normal bell, 154..196 cm, to 1e-12: {}", if marg_err < 1e-12 { "yes" } else { "no" });
    println!("P(170 < H < 180), from the marginal:          {:.4}", mid_exact);
    println!("P(170 < H < 180), simulated:                  {:.4}  (se {:.4})", mid_sim, mid_se);
    println!("P(H > 185) = 1 - Phi(10/7):                   {:.4}", ph);
    println!("P(W > 90)  = 1 - Phi(1):                      {:.4}", pw);
    println!("P(W > 90), simulated:                         {:.4}  (se {:.4})", heavy_sim, heavy_se);
    println!("road 1, P(H > 185, W > 90), grid:             {:.6}", tail_grid);
    println!("road 2, P(H > 185, W > 90), slices:           {:.6}  (about 1 in {:.0})", tail_slices, 1.0 / tail_slices);
    println!("hand steps: c = {:.4}, sqrt(2 pi) = {:.4}, 2 pi x 7 x 12 x c = {:.2}, z at 185 cm = {:.4}, z at 90 kg = {:.4}, z at 170 and 180 cm = {:.4}, {:.4}",
             cc, (2.0 * PI).sqrt(), 2.0 * PI * SH * SW * cc, 10.0 / 7.0, z90, -5.0 / 7.0, 5.0 / 7.0);
    println!("road 3, P(H > 185, W > 90), simulated:        {:.6}  (se {:.6}, {} of {})", p_sim, se, n_tail, n);
    println!("mistake 1, density read as a chance:          {:.6}, but P(H = 175 and W = 78) = 0", peak);
    println!("mistake 2, marginals multiplied:              {:.6}  vs {:.6}, true / product = {:.2}", ph * pw, tail_slices, tail_slices / (ph * pw));
    println!("mistake 3, slice at 78 kg read as a marginal: area {:.6}, spread {:.4} cm", slice_area, slice_sd);
    println!("weight integral stopped at 90 kg:            height marginal's total {:.4}, Phi(1) = {:.4}", cut_total, phi(1.0));
    println!("simulated share inside the 50% ring:          {:.4}", n_ring as f64 / nf);
    println!("chart, height (cm):     {}", heights.iter().map(|h| format!("{:5}", *h as i64)).collect::<Vec<_>>().join(" "));
    println!("chart, integrated, %/cm:{}", marg.iter().map(|m| format!("{:5.2}", 100.0 * m)).collect::<Vec<_>>().join(" "));
    println!("chart, simulated, %/cm: {}", bins.iter().map(|&b| format!("{:5.2}", 100.0 * b as f64 / (3.0 * nf))).collect::<Vec<_>>().join(" "));
    for p in [0.5f64, 0.9] {                       // rings holding half and nine-tenths of adults
        let r = (-2.0 * (1.0 - p).ln()).sqrt();
        let pts: Vec<String> = (0..24).map(|k| {
            let t = 2.0 * PI * k as f64 / 24.0;
            let (h, w) = (MH + SH * r * t.cos(), MW + SW * r * (RHO * t.cos() + cc * t.sin()));
            format!("{:.1},{:.1}", 40.0 + 6.0 * (h - 150.0), 200.0 - 2.25 * (w - 40.0))
        }).collect();
        println!("figure, ring {:.0}%: {}", 100.0 * p, pts.join(" "));
    }
    println!("figure, tail corner (185 cm, 90 kg): {:.1},{:.1}", 40.0 + 6.0 * 35.0, 200.0 - 2.25 * 50.0);
    assert!((total - 1.0).abs() < 1e-9 && (cov - RHO * SH * SW).abs() < 1e-6);   // grid vs the settings
    assert!(marg_err < 1e-12);                                                   // integrating out gives the bell
    assert!((tail_grid - tail_slices).abs() < 1e-7);                             // road 1 vs road 2
    assert!((p_sim - tail_slices).abs() < 4.0 * se);                             // road 3 vs road 2
    assert!((mid_sim - mid_exact).abs() < 4.0 * mid_se);                         // ignoring W in data = marginal
    assert!((heavy_sim - pw).abs() < 4.0 * heavy_se);                            // ignoring H in data = marginal
    assert!((slice_area - fw).abs() < 1e-9 && (slice_sd - SH * cc).abs() < 1e-6);
    assert!((cut_total - phi(1.0)).abs() < 1e-7);                               // the cut loses exactly P(W > 90)
    println!("ALL CHECKS PASS");
}
