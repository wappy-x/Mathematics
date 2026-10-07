// Conditional densities -- the same check as conditional_densities_check.py, in Rust.
// Standard library only, no crates.  Height H (cm) and weight W (kg) follow the
// tilted bell: centres 175 cm and 78 kg, spreads 7 cm and 12 kg, correlation 0.5.
// Three roads to the weight law at 180 cm: slice and divide (Simpson), complete
// the square, and a band of simulated adults (SplitMix64, rejection sampling).
use std::f64::consts::PI;

const MH: f64 = 175.0;
const SH: f64 = 7.0;
const MW: f64 = 78.0;
const SW: f64 = 12.0;
const RHO: f64 = 0.5;
const WLO: f64 = MW - 8.0 * SW;
const WHI: f64 = MW + 8.0 * SW;
const HLO: f64 = MH - 8.0 * SH;
const HHI: f64 = MH + 8.0 * SH;

fn joint(h: f64, w: f64, rho: f64) -> f64 {           // the tilted bell, per cm per kg
    let (a, b) = ((h - MH) / SH, (w - MW) / SW);
    let q = (a * a - 2.0 * rho * a * b + b * b) / (1.0 - rho * rho);
    (-q / 2.0).exp() / (2.0 * PI * SH * SW * (1.0 - rho * rho).sqrt())
}

fn simpson<F: Fn(f64) -> f64>(g: F, lo: f64, hi: f64, n: usize) -> f64 {
    let step = (hi - lo) / n as f64;
    let mut acc = 0.0;
    for i in 1..n {
        acc += (if i % 2 == 1 { 4.0 } else { 2.0 }) * g(lo + i as f64 * step);
    }
    (g(lo) + g(hi) + acc) * step / 3.0
}

fn slice_area(h: f64, rho: f64) -> f64 { simpson(|w| joint(h, w, rho), WLO, WHI, 800) }
fn cond(w: f64, h: f64) -> f64 { joint(h, w, RHO) / slice_area(h, RHO) }
fn cond_mean(h: f64, rho: f64) -> f64 {
    simpson(|w| w * joint(h, w, rho), WLO, WHI, 800) / slice_area(h, rho)
}
fn cond_sd(h: f64, rho: f64) -> f64 {
    let m = cond_mean(h, rho);
    (simpson(|w| (w - m).powi(2) * joint(h, w, rho), WLO, WHI, 800) / slice_area(h, rho)).sqrt()
}
fn cond_tail(t: f64, h: f64) -> f64 { simpson(|w| joint(h, w, RHO), t, WHI, 800) / slice_area(h, RHO) }

fn phi_cdf(z: f64) -> f64 {                            // standard normal area left of z, by series
    let (mut term, mut total) = (z, z);
    for n in 1..200 {
        term *= -z * z / (2.0 * n as f64);
        total += term / (2.0 * n as f64 + 1.0);
    }
    0.5 + total / (2.0 * PI).sqrt()
}

struct SplitMix(u64);
impl SplitMix {
    fn uniform(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        (((z ^ (z >> 31)) >> 11) as f64 + 0.5) / 9007199254740992.0
    }
}

fn mean_se(n: f64, s: f64, s2: f64) -> (f64, f64) {
    let m = s / n;
    (m, ((s2 / n - m * m) / n).sqrt())
}

fn main() {
    let (h0, t90) = (180.0, 90.0);
    println!("road 1: slice the joint density at 180 cm, divide by the slice's area");
    let area = slice_area(h0, RHO);
    let (m1, s1, p1) = (cond_mean(h0, RHO), cond_sd(h0, RHO), cond_tail(t90, h0));
    println!("slice area f_H(180)            {:.6} per cm", area);
    println!("conditional mean, sd            {:.4} kg  {:.4} kg", m1, s1);
    println!("P(W > 90 | H = 180)             {:.4}", p1);
    println!("road 2: complete the square at a = 5/7 (180 cm is 5/7 of a spread up)");
    let a0 = (h0 - MH) / SH;
    let (m2, s2) = (MW + SW * RHO * a0, SW * (1.0 - RHO * RHO).sqrt());
    let area2 = (-a0 * a0 / 2.0).exp() / ((2.0 * PI).sqrt() * SH);
    let p2 = 1.0 - phi_cdf((t90 - m2) / s2);
    println!("slice area exp(-a^2/2)/(7 sqrt(2 pi)) {:.6} per cm", area2);
    println!("centre 78 + 12(0.5)(5/7), spread 12 sqrt(0.75) {:.4} kg  {:.4} kg", m2, s2);
    println!("P(W > 90 | H = 180) = 1 - Phi(z)  {:.4}  (z = {:.4})", p2, (t90 - m2) / s2);
    println!("all adults: P(W > 90) = 1 - Phi(1)  {:.4}", 1.0 - phi_cdf((t90 - MW) / SW));

    println!("road 3: rejection sampling from the joint density, then keep a band");
    let n = 3_000_000;
    let mut rng = SplitMix(20260928);
    let (mut acc, mut sw, mut sw2) = (0.0, 0.0, 0.0);
    let mut band = [0.0f64; 4];                       // |H - 180| < 1: count, sum w, sum w^2, w > 90
    let mut rev = [0.0f64; 3];                        // |W - 90| < 1.2: count, sum h, sum h^2
    let mut odd = [0.0f64; 3];                        // |(H - 180)/W| < 0.01: count, sum w, sum w^2
    for _ in 0..n {
        let a = -4.5 + 9.0 * rng.uniform();
        let b = -4.5 + 9.0 * rng.uniform();
        let q = (a * a - 2.0 * RHO * a * b + b * b) / (1.0 - RHO * RHO);
        if rng.uniform() >= (-q / 2.0).exp() { continue; }
        let (h, w) = (MH + SH * a, MW + SW * b);
        acc += 1.0; sw += w; sw2 += w * w;
        if (h - h0).abs() < 1.0 {
            band[0] += 1.0; band[1] += w; band[2] += w * w;
            if w > t90 { band[3] += 1.0; }
        }
        if (w - t90).abs() < 1.2 { rev[0] += 1.0; rev[1] += h; rev[2] += h * h; }
        if ((h - h0) / w).abs() < 0.01 { odd[0] += 1.0; odd[1] += w; odd[2] += w * w; }
    }
    let (m3, se3) = mean_se(band[0], band[1], band[2]);
    let p3 = band[3] / band[0];
    let ((mall, seall), (m5, se5)) = (mean_se(acc, sw, sw2), mean_se(rev[0], rev[1], rev[2]));
    println!("accepted {} of {}; mean weight {:.3} kg, se {:.3}", acc as u64, n, mall, seall);
    println!("band 179-181 cm: {} adults, mean {:.3} kg, se {:.3}", band[0] as u64, m3, se3);
    println!("band 179-181 cm: share over 90 kg {:.4}, se {:.4}", p3, (p3 * (1.0 - p3) / band[0]).sqrt());

    println!("regression toward the mean: E[W | H = h] by slicing, and the sd line");
    for h in [161.0, 168.0, 175.0, 180.0, 182.0, 189.0] {
        println!("h = {:.0}: slice mean {:.3} kg; line 78+(6/7)(h-175) {:.3}; sd line {:.3}",
                 h, cond_mean(h, RHO), MW + 6.0 / 7.0 * (h - MH), MW + 12.0 / 7.0 * (h - MH));
    }
    let rev_int = simpson(|h| h * joint(h, t90, RHO), HLO, HHI, 800) / simpson(|h| joint(h, t90, RHO), HLO, HHI, 800);
    println!("reverse: E[H | W = 90] by slicing {:.3} cm; band 88.8-91.2 kg {:.3} cm, se {:.3}, n {}", rev_int, m5, se5, rev[0] as u64);
    let tower = simpson(|h| cond_mean(h, RHO) * slice_area(h, RHO), HLO, HHI, 200);
    let back90 = simpson(|h| cond(t90, h) * slice_area(h, RHO), HLO, HHI, 200);
    println!("average of slice means, weighted by f_H: {:.4} kg (overall 78)", tower);
    println!("f_W(90) rebuilt from slices {:.6}; bell exp(-1/2)/(12 sqrt(2 pi)) {:.6}", back90, (-0.5f64).exp() / (12.0 * (2.0 * PI).sqrt()));

    println!("what breaks");
    println!("slice not divided: P(W > 90) read as {:.4}", simpson(|w| joint(h0, w, RHO), t90, WHI, 800));
    println!("sd line at 180 cm: {:.3} kg; line inverted at 90 kg: {:.1} cm", MW + 12.0 / 7.0 * (h0 - MH), MH + (t90 - MW) * 7.0 / 6.0);
    let odd_int = simpson(|w| w * w * joint(h0, w, RHO), WLO, WHI, 800) / simpson(|w| w * joint(h0, w, RHO), WLO, WHI, 800);
    let (m4, se4) = mean_se(odd[0], odd[1], odd[2]);
    println!("band in (H-180)/W: mean {:.3} kg by integral; simulated {:.3}, se {:.3}, n {}", odd_int, m4, se4, odd[0] as u64);
    println!("try changing");
    println!("rho = 0: mean {:.3}, sd {:.3}; rho = 0.9: mean {:.3}, sd {:.3}",
             cond_mean(h0, 0.0), cond_sd(h0, 0.0), cond_mean(h0, 0.9), cond_sd(h0, 0.9));

    let ws: Vec<f64> = (0..17).map(|k| 40.0 + 5.0 * k as f64).collect();
    let row = |v: Vec<String>| v.join(" ");
    println!("chart, weight kg          {}", row(ws.iter().map(|w| format!("{:5.0}", w)).collect()));
    println!("chart, at 180 cm, %/kg    {}", row(ws.iter().map(|&w| format!("{:5.2}", 100.0 * cond(w, h0))).collect()));
    println!("chart, all adults, %/kg   {}", row(ws.iter().map(|&w| format!("{:5.2}", 100.0 * simpson(|h| joint(h, w, RHO), HLO, HHI, 800))).collect()));
    let x = |h: f64| 40.0 + 6.0 * (h - 150.0);           // screen x: 150-200 cm -> 40-340
    let y = |w: f64| 210.0 - 2.0 * (w - 30.0);           // screen y: 30-120 kg -> 210-30
    let ell: Vec<String> = (0..24).map(|k| {
        let t = 2.0 * PI * k as f64 / 24.0;
        let (c, s) = (2.0 * t.cos(), 2.0 * t.sin());
        format!("{:.1},{:.1}", x(MH + SH * c), y(MW + SW * (RHO * c + (1.0 - RHO * RHO).sqrt() * s)))
    }).collect();
    println!("figure, scale 6 per cm across, 2 per kg up");
    println!("figure, 2-sd contour {}", row(ell));
    let l1 = |h: f64| MW + 6.0 / 7.0 * (h - MH);
    let l2 = |h: f64| MW + 12.0 / 7.0 * (h - MH);
    println!("figure, mean line {:.0},{:.1} {:.0},{:.1}; sd line {:.0},{:.1} {:.0},{:.1}; slice x {:.0}; dot y {:.1}",
             x(150.0), y(l1(150.0)), x(200.0), y(l1(200.0)), x(154.0), y(l2(154.0)), x(196.0), y(l2(196.0)), x(h0), y(m1));

    assert!((m1 - m2).abs() < 1e-6, "slice mean vs completing the square");
    assert!((s1 - s2).abs() < 1e-6, "slice spread vs completing the square");
    assert!((area - area2).abs() < 1e-9, "slice area vs the height bell");
    assert!((p1 - p2).abs() < 1e-6, "tail by integration vs by the Phi series");
    assert!((m3 - m1).abs() < 4.0 * se3, "simulated band mean within 4 se");
    assert!((tower - MW).abs() < 1e-6, "averaging slice means gives back 78");
    assert!((back90 - (-0.5f64).exp() / (12.0 * (2.0 * PI).sqrt())).abs() < 1e-9, "slices rebuild f_W(90)");
    assert!([161.0, 189.0].iter().all(|&h| (cond_mean(h, RHO) - MW - 6.0 / 7.0 * (h - MH)).abs() < 1e-6), "line of averages");
    assert!((m5 - rev_int).abs() < 4.0 * se5, "reverse band within 4 se");
    assert!((p3 - p1).abs() < 4.0 * (p1 * (1.0 - p1) / band[0]).sqrt(), "band share over 90 kg within 4 se");
    assert!((m4 - odd_int).abs() < 4.0 * se4, "the other band: simulation vs integral");
    assert!(odd_int - m1 > 1.0, "the other band really moves the answer");
    println!("ALL CHECKS PASS");
}
