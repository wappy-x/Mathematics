// Densities and CDFs -- the same check as the Python, in Rust.  No crates.
// A share's daily return, in percent, is modelled by a bell-shaped density
// centred at 0 with spread 1.2.  The chance of a fall of more than 2 percent
// is reached three ways: strips under the density, the CDF's own power
// series, and seeded random draws.  Every number on the card is printed.
use std::f64::consts::PI;

const SIGMA: f64 = 1.2;
const CUT: f64 = -2.0;
const DAYS: f64 = 252.0;

fn f(x: f64) -> f64 {                          // the density: chance per percentage point
    (-x * x / (2.0 * SIGMA * SIGMA)).exp() / (SIGMA * (2.0 * PI).sqrt())
}

fn simpson(g: fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 {   // n even strips
    let h = (b - a) / n as f64;
    let mut s = g(a) + g(b);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * g(a + i as f64 * h); }
    s * h / 3.0
}

fn cdf(x: f64) -> f64 {                        // the CDF by its power series, no integrator
    let z = x / SIGMA;
    let (mut term, mut total, mut n) = (z, 0.0, 0.0);
    while term.abs() > 1e-17 {                 // term n is (-1)^n z^(2n+1) / (2^n n! (2n+1))
        total += term / (2.0 * n + 1.0);
        n += 1.0;
        term *= -z * z / (2.0 * n);
    }
    0.5 + total / (2.0 * PI).sqrt()
}

struct SplitMix(u64);                          // SplitMix64, seed stated, same in Python
impl SplitMix {
    fn uniform(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^= z >> 31;
        ((z >> 11) as f64 + 0.5) / 2f64.powi(53)   // strictly between 0 and 1
    }
}

fn row(label: &str, value: f64, digits: usize) {
    println!("{:<52} {:.*}", label, digits, value);
}

fn main() {
    let road1 = simpson(f, -12.0, CUT, 20000);
    let road2 = cdf(CUT);
    let mut rng = SplitMix(20260928);
    let draws = 400000u64;
    let (mut below, mut in_bin) = (0u64, 0u64);
    for _ in 0..draws / 2 {                    // Box-Muller: two uniforms make two bell draws
        let r = (-2.0 * rng.uniform().ln()).sqrt();
        let t = 2.0 * PI * rng.uniform();
        for x in [SIGMA * r * t.cos(), SIGMA * r * (t - PI / 2.0).cos()] {
            if x < CUT { below += 1 }
            if (-2.25..-1.75).contains(&x) { in_bin += 1 }
        }
    }
    let nd = draws as f64;
    let p3 = below as f64 / nd;
    let se3 = (p3 * (1.0 - p3) / nd).sqrt();
    let hb = in_bin as f64 / nd / 0.5;
    let binx = (cdf(-1.75) - cdf(-2.25)) / 0.5;
    let pb = in_bin as f64 / nd;
    let seb = (pb * (1.0 - pb) / nd).sqrt() / 0.5;
    let slope = (cdf(-1.999) - cdf(-2.001)) / 0.002;
    let total = simpson(f, -12.0, 12.0, 20000);

    println!("daily return: bell-shaped density, centre 0%, spread {}%", SIGMA);
    row("z = -2 / 1.2, the cut in units of spread", CUT / SIGMA, 6);
    row("road 1, 20000 strips under f from -12% to -2%", road1, 6);
    row("road 2, F(-2) by power series at z = -2/1.2", road2, 6);
    row("road 3, share of 400000 seeded draws below -2%", p3, 6);
    row("  its standard error", se3, 6);
    println!("  draws below -2%: {} of {}", below, draws);
    row("fall of more than 2% on 252 days, expected count", DAYS * road2, 2);
    row("one day in N, N = 1 / F(-2)", 1.0 / road2, 1);
    row("f(-2), density height at -2%, per point", f(CUT), 6);
    row("slope of F at -2%, (F(-1.999) - F(-2.001)) / 0.002", slope, 6);
    row("draws in -2.25% to -1.75%, per point of width", hb, 6);
    row("  its standard error", seb, 6);
    row("  exact, (F(-1.75) - F(-2.25)) / 0.5", binx, 6);
    row("f(0), density height at the centre, per point", f(0.0), 6);
    row("F(0), chance of a return at or below 0%", cdf(0.0), 6);
    row("total area under f, -12% to 12%", total, 6);
    row("F(1) - F(-1), a day between -1% and +1%", cdf(1.0) - cdf(-1.0), 6);
    for w in [0.1, 0.01, 0.001] {
        row(&format!("chance within a strip of width {} at -2%", w), cdf(CUT + w / 2.0) - cdf(CUT - w / 2.0), 6);
    }
    row("wrong: height f(-2) read as the chance", f(CUT), 6);
    row("wrong: returns as decimals, height at centre", f(0.0) * 100.0, 3);
    row("wrong: either way, below -2% or above +2%", cdf(CUT) + 1.0 - cdf(-CUT), 6);
    row("wrong: F(-2) plus f(-2) for the point itself", cdf(CUT) + f(CUT), 6);
    println!("by hand: strips 0.5 wide from -5% to -2%, centre, height, area");
    let mut hand = 0.0;
    for c in [-2.25, -2.75, -3.25, -3.75, -4.25, -4.75] {
        hand += 0.5 * f(c);
        println!("  {:6.2}  {:.4}  {:.4}", c, f(c), 0.5 * f(c));
    }
    row("  sum of the six strip areas", hand, 4);
    row("  area left of -5%, left out by hand", cdf(-5.0), 6);
    row("  gap, road 2 minus the hand sum", road2 - hand, 4);
    row("try: spread 1.5% instead of 1.2%, chance below -2%", cdf(CUT * SIGMA / 1.5), 6);
    row("try: cut at -3% instead of -2%, chance below it", cdf(-3.0), 6);
    let xs: Vec<f64> = (0..17).map(|i| -4.0 + 0.5 * i as f64).collect();
    let xl: Vec<String> = xs.iter().map(|x| format!("{:.1}", x)).collect();
    let fl: Vec<String> = xs.iter().map(|&x| format!("{:.2}", cdf(x))).collect();
    println!("chart, x   {}", xl.join(" "));
    println!("chart, F   {}", fl.join(" "));
    let px = |x: f64| 180.0 + 30.0 * x;        // figure: 30 px per point, baseline at y = 200
    let py = |x: f64| 200.0 - 500.0 * f(x);
    let pts: Vec<f64> = (0..21).map(|i| -5.0 + 0.5 * i as f64).collect();
    for k in 0..3 {
        let s: Vec<String> = pts[7 * k..7 * k + 7].iter().map(|&x| format!("{:.0},{:.1}", px(x), py(x))).collect();
        println!("figure, {}", s.join(" "));
    }
    println!("figure, tail from x = {:.0} to {:.0}, baseline y = 200", px(-5.0), px(CUT));

    assert!((road1 - road2).abs() < 1e-9);                // strips against series
    assert!((p3 - road2).abs() < 4.0 * se3);              // draws against series
    assert!((slope - f(CUT)).abs() < 1e-6);               // CDF's slope is the density
    assert!((hb - binx).abs() < 4.0 * seb);               // bin share per width vs CDF
    assert!((total - 1.0).abs() < 1e-9);
    println!("ALL CHECKS PASS");
}
