// Characteristic functions and inversion -- the same check in Rust, std only.
// Integrals are Simpson's rule written out; random draws come from SplitMix64
// (seed 2026) and Box-Muller, the same generator as the Python check.
// Compile: rustc --edition 2021 -O characteristic_functions_and_inversion_check.rs
use std::f64::consts::PI;

const SD: f64 = 2.0; // the scale's error: normal, mean 0 g, sd 2 g
const NDRAW: usize = 200000;

fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n {
        s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h);
    }
    s * h / 3.0
}

fn dens(x: f64, mu: f64, sd: f64) -> f64 { // the bell in grams
    let z = (x - mu) / sd;
    (-0.5 * z * z).exp() / (sd * (2.0 * PI).sqrt())
}

fn phi(t: f64, sd: f64) -> f64 { (-0.5 * sd * sd * t * t).exp() } // road 1: a bell in t

// f(x) = (1/2pi) integral of e^{-itx} phi(t) dt, real part, over [-T, T]
fn invert<A: Fn(f64) -> f64, B: Fn(f64) -> f64>(x: f64, re: A, im: B, sign: f64, big_t: f64) -> f64 {
    simpson(|t| re(t) * (t * x).cos() + sign * im(t) * (t * x).sin(), -big_t, big_t, 4000) / (2.0 * PI)
}

fn die_phi(t: f64, shift: i32) -> (f64, f64) { // a fair die: (1/6) sum of e^{itj}
    let (mut c, mut s) = (0.0, 0.0);
    for j in 1..7 { c += (t * (j + shift) as f64).cos(); s += (t * (j + shift) as f64).sin(); }
    (c / 6.0, s / 6.0)
}

struct Rng(u64);
impl Rng {
    fn uniform(&mut self) -> f64 { // SplitMix64, a number in (0, 1]
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^= z >> 31;
        ((z >> 11) + 1) as f64 / 9007199254740992.0
    }
    fn normal(&mut self) -> f64 { // Box-Muller, cosine half
        let u1 = self.uniform();
        let u2 = self.uniform();
        (-2.0 * u1.ln()).sqrt() * (2.0 * PI * u2).cos()
    }
}

fn join(v: &[f64], d: usize) -> String {
    v.iter().map(|x| format!("{:.*}", d, x)).collect::<Vec<_>>().join(" ")
}

fn main() {
    let mut rng = Rng(2026);
    let mut acc = [[0.0f64; 2]; 4];
    for _ in 0..NDRAW {
        let x1 = SD * rng.normal();
        let x2 = SD * rng.normal();
        let vals = [(0.5 * x1).cos(), if -2.0 < x1 && x1 < 2.0 { 1.0 } else { 0.0 },
                    (0.5 * (x1 + x2)).cos(), (0.5 * (x1 + x1)).cos()];
        for k in 0..4 { acc[k][0] += vals[k]; acc[k][1] += vals[k] * vals[k]; }
    }
    let n = NDRAW as f64;
    let mean_se = |k: usize| {
        let m = acc[k][0] / n;
        (m, ((acc[k][1] - n * m * m) / (n - 1.0) / n).sqrt())
    };
    let ((sim, se), (sim_in, se_in), (sim_2, se_2), (sim_d, se_d)) = (mean_se(0), mean_se(1), mean_se(2), mean_se(3));

    let p = |t: f64| phi(t, SD);
    let re05 = simpson(|x| (0.5 * x).cos() * dens(x, 0.0, SD), -40.0, 40.0, 4000);
    let im05 = simpson(|x| (0.5 * x).sin() * dens(x, 0.0, SD), -40.0, 40.0, 4000);
    let re1 = simpson(|x| (1.0 * x).cos() * dens(x, 0.0, SD), -40.0, 40.0, 4000);
    let mut terms = Vec::new();
    let mut fact = 1.0;
    for k in 0..8 {
        let m = simpson(|z| z.powf((2 * k) as f64) * dens(z, 0.0, 1.0), -12.0, 12.0, 4000);
        let sign = if k % 2 == 0 { 1.0 } else { -1.0 };
        terms.push(sign * m / fact);
        fact *= ((2 * k + 1) * (2 * k + 2)) as f64;
    }
    let series: f64 = terms.iter().sum();
    let zero = |_t: f64| 0.0;
    let f_inv: Vec<f64> = [0.0, 2.0, 4.0].iter().map(|&x| invert(x, p, zero, 1.0, 10.0)).collect();
    let levy_g = |t: f64| if t == 0.0 { 4.0 * p(t) } else { ((2.0 * t).sin() - (-2.0 * t).sin()) / t * p(t) };
    let levy = simpson(levy_g, -10.0, 10.0, 4000) / (2.0 * PI);
    let area = simpson(|x| dens(x, 0.0, SD), -2.0, 2.0, 4000);
    let (b_re, b_im) = (|t: f64| t.cos() * p(t), |t: f64| t.sin() * p(t)); // scale reading 1 g heavy
    let (right, wrong) = (invert(1.0, b_re, b_im, 1.0, 10.0), invert(1.0, b_re, b_im, -1.0, 10.0));
    let (dre, dim) = (|t: f64| die_phi(t, 0).0, |t: f64| die_phi(t, 0).1);
    let die_p: Vec<f64> = (1..8).map(|k| invert(k as f64, dre, dim, 1.0, PI)).collect();
    let ts = [10.0, 20.0, 40.0];
    let die_bad: Vec<f64> = ts.iter().map(|&bt| invert(3.0, dre, dim, 1.0, bt)).collect();
    let die_bad_exact: Vec<f64> = ts.iter().map(|&bt| {
        bt / (6.0 * PI) + [-2.0, -1.0, 1.0, 2.0, 3.0].iter().map(|&m: &f64| (bt * m).sin() / (6.0 * PI * m)).sum::<f64>()
    }).collect();
    let gap = |t: f64| {
        let (a, b) = (die_phi(t, 0), die_phi(t, 4));
        ((a.0 - b.0).powf(2.0) + (a.1 - b.1).powf(2.0)).sqrt()
    };
    let probe_gap = (0..5).map(|k| gap(k as f64 * PI / 2.0)).fold(f64::MIN, f64::max);
    let sd_die = (35.0f64 / 12.0).sqrt();
    let s = 1.0 / (sd_die * 1000.0f64.sqrt());
    let clt = ((1..7).map(|j| (s * (j as f64 - 3.5)).cos()).sum::<f64>() / 6.0).powf(1000.0);

    let rows: Vec<(&str, f64)> = vec![
        ("phi(0.5) formula exp(-2 t^2)", p(0.5)), ("phi(0.5) Simpson, real part", re05),
        ("phi(0.5) Simpson, |imaginary part|", im05.abs()), ("phi(0.5) simulated, 200000 draws", sim),
        ("  standard error", se), ("phi(1) formula", p(1.0)), ("phi(1) Simpson", re1),
        ("f(0) by inversion", f_inv[0]), ("f(0) density formula", dens(0.0, 0.0, SD)),
        ("f(2) by inversion", f_inv[1]), ("f(2) density formula", dens(2.0, 0.0, SD)),
        ("f(4) by inversion", f_inv[2]), ("f(4) density formula", dens(4.0, 0.0, SD)),
        ("P(-2<X<2) Levy inversion", levy), ("P(-2<X<2) Simpson on density", area),
        ("P(-2<X<2) simulated", sim_in), ("  standard error", se_in),
        ("series for exp(-1/2), 8 terms", series), ("exp(-1/2)", (-0.5f64).exp()),
        ("two weighings X1+X2: phi(0.5)^2", p(0.5).powf(2.0)), ("  simulated", sim_2), ("  standard error", se_2),
        ("one weighing doubled 2X: phi(1)", p(1.0)), ("  simulated", sim_d), ("  standard error", se_d),
        ("biased scale, f(1), right sign", right), ("wrong: sign flipped, f(1)", wrong),
        ("wrong: no 1/(2 pi), f(0)", 2.0 * PI * f_inv[0]),
        ("die vs die+4, max gap at t = k pi/2", probe_gap), ("die vs die+4, gap at t = 1", gap(1.0)),
        ("1000 rolls standardized, phi(1)", clt), ("spread of the average, sd/sqrt(1000)", sd_die / 1000.0f64.sqrt()),
    ];
    for (name, v) in &rows { println!("{:<38}{:>12.6}", name, v); }
    println!("series terms k=0..7    {}", join(&terms, 6));
    println!("die P(X=k) by inversion, k=1..7  {}", join(&die_p.iter().map(|v| v.abs()).collect::<Vec<_>>(), 6));
    println!("wrong: die as a density, T=10,20,40  {}", join(&die_bad, 4));
    println!("  closed form                        {}", join(&die_bad_exact, 4));
    let chart: Vec<f64> = (-6..7).map(|x| 100.0 * dens(x as f64, 0.0, SD)).collect();
    println!("chart, density %/g, x=-6..6   {}", join(&chart, 2));
    for sd in [1.0f64, 2.0] {
        let v: Vec<f64> = (0..13).map(|i| phi(-1.5 + 0.25 * i as f64, sd)).collect();
        println!("chart, phi sd={:.0}, t=-1.5..1.5  {}", sd, join(&v, 2));
    }
    let dv: Vec<f64> = (0..17).map(|k| { let c = die_phi(k as f64 * PI / 8.0, 0); (c.0 * c.0 + c.1 * c.1).sqrt() }).collect();
    println!("chart, die |phi|, t=k pi/8  {}", join(&dv, 2));

    assert!((re05 - p(0.5)).abs() < 1e-9, "integral road lands on the bell formula");
    assert!((sim - p(0.5)).abs() < 4.0 * se, "simulated average of cos(tX) within 4 standard errors");
    assert!((f_inv[0] - dens(0.0, 0.0, SD)).abs() < 1e-9, "inversion returns the density at the peak");
    assert!((f_inv[2] - dens(4.0, 0.0, SD)).abs() < 1e-9, "inversion returns the density in the tail");
    assert!((levy - area).abs() < 1e-8, "Levy's interval formula against the integrated density");
    assert!((sim_in - levy).abs() < 4.0 * se_in, "Levy's interval formula against the simulated count");
    assert!((series - (-0.5f64).exp()).abs() < 1e-5, "series from integrated moments");
    assert!((die_p[2] - 1.0 / 6.0).abs() < 1e-9, "die face 3 recovered from its characteristic function");
    assert!(die_p[6].abs() < 1e-9, "no face 7 recovered");
    assert!(die_bad.iter().zip(&die_bad_exact).all(|(a, b)| (a - b).abs() < 1e-6), "die failure matches its closed form");
    assert!((sim_2 - p(0.5).powf(2.0)).abs() < 4.0 * se_2, "independent weighings: transforms multiply");
    assert!((sim_d - p(0.5).powf(2.0)).abs() > 10.0 * se_d, "a copied weighing breaks the product rule");
    assert!((clt - (-0.5f64).exp()).abs() < 1e-3, "1000 rolls: the bell in t appears");
    assert!((sim_d - p(1.0)).abs() < 4.0 * se_d, "a copied weighing follows phi at the doubled rate");
    assert!((right - dens(1.0, 1.0, SD)).abs() < 1e-9 && (wrong - dens(1.0, -1.0, SD)).abs() < 1e-9, "right sign finds the bias, wrong sign mirrors it");
    assert!(probe_gap < 1e-12 && gap(1.0) > 0.05, "die and die+4 agree at k pi/2 but not at t = 1");
    println!("ALL CHECKS PASS");
}
