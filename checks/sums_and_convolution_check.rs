// Adding continuous variables -- the check behind the card.  Rust std only, no crates.
// A commute: bus leg X ~ N(20, 3^2) minutes, train leg Y ~ N(35, 4^2), independent.
// Roads to the total S = X + Y: the closed form N(55, 5^2), the convolution
// integral done numerically, moment generating functions, and a seeded simulation.
use std::f64::consts::PI;

fn npdf(x: f64, m: f64, sd: f64) -> f64 { // the normal density, written out
    let z = (x - m) / sd;
    (-z * z / 2.0).exp() / (sd * (2.0 * PI).sqrt())
}

fn phi(z: f64) -> f64 { // standard normal area left of z, by its Taylor series
    let (mut term, mut total, mut n) = (z, z, 0.0);
    while term.abs() > 1e-17 {
        n += 1.0;
        term *= -z * z / (2.0 * n);
        total += term / (2.0 * n + 1.0);
    }
    0.5 + total / (2.0 * PI).sqrt()
}

fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 { // n strips, n even
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n {
        s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h);
    }
    s * h / 3.0
}

fn bus(x: f64) -> f64 { npdf(x, 20.0, 3.0) }
fn train(y: f64) -> f64 { npdf(y, 35.0, 4.0) }
fn h(s: f64) -> f64 { // the convolution integral: slide the train across the bus
    simpson(&|x| bus(x) * train(s - x), -10.0, 50.0, 600)
}

struct SplitMix(u64);
impl SplitMix {
    fn u01(&mut self) -> f64 { // SplitMix64, top 53 bits as a number in [0, 1)
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
}

fn row(v: &[f64], d: usize) -> String {
    v.iter().map(|x| format!("{:.*}", d, x)).collect::<Vec<_>>().join(" ")
}

fn main() {
    let (h60_form, h60_conv) = (npdf(60.0, 55.0, 5.0), h(60.0));
    let p_form = phi((60.0 - 55.0) / 5.0);
    let p_conv = simpson(&h, 0.0, 60.0, 600); // area under the convolved density, no normal CDF used
    println!("bus N(20, 3^2), train N(35, 4^2), independent; total S = bus + train");
    println!("road 1, closed form N(55, 5^2):  h(60) {:.6}   P(S <= 60) {:.6}", h60_form, p_form);
    println!("road 2, convolution integral:    h(60) {:.6}   P(S <= 60) {:.6}", h60_conv, p_conv);
    let gap = (30..81).map(|s| (h(s as f64) - npdf(s as f64, 55.0, 5.0)).abs()).fold(0.0, f64::max);
    println!("road 2 against road 1 at every whole minute 30..80, largest gap {:.1e}", gap);
    assert!((h60_conv - h60_form).abs() < 1e-9);
    assert!((p_conv - p_form).abs() < 1e-8);
    assert!(gap < 1e-9);

    let t = 0.1; // road 3: moment generating functions, integrated numerically
    let mx = simpson(&|x| (t * x).exp() * bus(x), -10.0, 50.0, 600);
    let my = simpson(&|y| (t * y).exp() * train(y), -10.0, 80.0, 900);
    let ms = simpson(&|s| (t * s).exp() * h(s), 10.0, 110.0, 400);
    let mf = (55.0 * t + 25.0 * t * t / 2.0).exp();
    println!("road 3, MGF at t = 0.1: M_X M_Y {:.4}   M_S from h {:.4}   formula {:.4}", mx * my, ms, mf);
    assert!((mx * my / mf - 1.0).abs() < 1e-9);
    assert!((ms / mf - 1.0).abs() < 1e-9);

    let (mut peak, mut best) = (0.0, -1.0); // where along the slide the product peaks
    for i in 1000..3401 {
        let x = i as f64 / 100.0;
        let v = bus(x) * train(60.0 - x);
        if v > best { best = v; peak = x; }
    }
    let m_s = (16.0 * 20.0 + 9.0 * (60.0 - 35.0)) / 25.0;
    println!("slide at s = 60: product peaks at bus {:.2}, train {:.2}; formula {:.2}", peak, 60.0 - peak, m_s);
    println!("  peak height {:.6}", bus(peak) * train(60.0 - peak));
    assert!((peak - m_s).abs() < 0.006);

    let mut g = SplitMix(20260928);
    let n = 250000; // road 4: simulate n days, two normals per day by Box-Muller
    let (mut ok, mut okd) = (0u32, 0u32);
    let (mut tot, mut sq, mut yd_sq) = (0.0, 0.0, 0.0);
    for _ in 0..n {
        let r = (-2.0 * (1.0 - g.u01()).ln()).sqrt();
        let th = 2.0 * PI * g.u01();
        let (z1, z2) = (r * th.cos(), r * th.sin());
        let s = (20.0 + 3.0 * z1) + (35.0 + 4.0 * z2);
        let yd = 4.0 * (0.5 * z1 + 0.75f64.sqrt() * z2); // same weather: train leg correlated 0.5 with bus
        if s <= 60.0 { ok += 1 }
        if 55.0 + 3.0 * z1 + yd <= 60.0 { okd += 1 }
        tot += s; sq += s * s; yd_sq += yd * yd;
    }
    let nf = n as f64;
    let (pe, pd) = (ok as f64 / nf, okd as f64 / nf);
    let (se, sed) = ((pe * (1.0 - pe) / nf).sqrt(), (pd * (1.0 - pd) / nf).sqrt());
    let mean = tot / nf;
    let var = sq / nf - mean * mean;
    println!("road 4, simulation, seed 20260928, {} days", n);
    println!("  P(S <= 60) {:.6} +- {:.6}   mean {:.4} +- {:.4}   variance {:.4} +- {:.4}",
             pe, se, mean, (var / nf).sqrt(), var, var * (2.0 / nf).sqrt());
    assert!((pe - p_form).abs() < 4.0 * se);
    assert!((mean - 55.0).abs() < 4.0 * (var / nf).sqrt());
    assert!((var - 25.0).abs() < 4.0 * 25.0 * (2.0 / nf).sqrt());

    println!("what breaks");
    let p_sd = phi(5.0 / 7.0);
    println!("  add the spreads, 3 + 4 = 7:       P(S <= 60) {:.6}   true {:.6}", p_sd, p_form);
    let p_dep = phi(5.0 / 37f64.sqrt());
    println!("  same weather, correlation 0.5:    formula for independent {:.6}", p_form);
    println!("    true Phi(5 / sqrt 37) {:.6}   simulated {:.6} +- {:.6}", p_dep, pd, sed);
    let sd_y = (yd_sq / nf).sqrt();
    println!("    train leg alone still spread 4: simulated {:.4} +- {:.4}", sd_y, sd_y / (2.0 * nf).sqrt());
    assert!((pd - p_dep).abs() < 4.0 * sed);
    assert!((pd - p_form).abs() > 20.0 * sed);
    assert!((sd_y - 4.0).abs() < 4.0 * sd_y / (2.0 * nf).sqrt());
    let wait_conv = simpson(&|w| bus(25.0 - w) / 10.0, 0.0, 10.0, 200);
    let wait_form = (phi(5.0 / 3.0) - phi(-5.0 / 3.0)) / 10.0;
    let sdw = (9.0 + 100.0 / 12.0f64).sqrt();
    let tail_conv = simpson(&|w| (1.0 - phi((18.0 - w) / 3.0)) / 10.0, 0.0, 10.0, 200);
    let tail_norm = 1.0 - phi(13.0 / sdw);
    println!("  bus + platform wait uniform 0..10 (mean 25, spread {:.4}):", sdw);
    println!("    density at 25: convolution {:.6}   closed form {:.6}   matched normal {:.6}",
             wait_conv, wait_form, npdf(25.0, 25.0, sdw));
    println!("    P(bus + wait > 38): convolution {:.6}   matched normal {:.6}", tail_conv, tail_norm);
    assert!((wait_conv - wait_form).abs() < 1e-9);
    assert!(tail_norm > 2.0 * tail_conv);

    println!("try changing");
    println!("  bus spread 6 instead of 3: P(S <= 60) {:.6}", phi(5.0 / 52f64.sqrt()));
    println!("  allowance 65 minutes:      P(S <= 65) {:.6}", phi(2.0));
    let ts: Vec<f64> = (0..27).map(|i| 10.0 + 2.5 * i as f64).collect(); // chart 1: minutes 10, 12.5, ..., 75
    println!("chart 1, percent per minute, bus:   {}", row(&ts.iter().map(|&v| 100.0 * bus(v)).collect::<Vec<_>>(), 2));
    println!("chart 1, percent per minute, train: {}", row(&ts.iter().map(|&v| 100.0 * train(v)).collect::<Vec<_>>(), 2));
    println!("chart 1, percent per minute, total: {}", row(&ts.iter().map(|&v| 100.0 * h(v)).collect::<Vec<_>>(), 2));
    let prod: Vec<f64> = (12..33).map(|v| 1000.0 * bus(v as f64) * train(60.0 - v as f64)).collect();
    println!("chart 2, x = 12..32, 1000 bus(x) train(60 - x): {}", row(&prod, 2));
    println!("ALL CHECKS PASS");
}
