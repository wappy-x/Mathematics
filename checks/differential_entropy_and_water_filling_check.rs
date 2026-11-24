// Differential entropy and water-filling -- the check behind the card.  Rust std only, no crates.
// A weather station: its daily temperature reading (spread 2 degrees C) and a radio with three
// frequency slots of noise power 1, 2 and 4 sharing a total signal power of 5. Same output as the Python.
use std::f64::consts::{E, PI};

const SIGMA: f64 = 2.0; // spread of the daily reading, degrees C
const NOISE: [f64; 3] = [1.0, 2.0, 4.0]; // noise power in each frequency slot
const POWER: f64 = 5.0; // total signal power the radio may spend

fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 {
    let hh = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n { s += (if i % 2 == 1 { 4.0 } else { 2.0 }) * f(a + i as f64 * hh); }
    s * hh / 3.0
}
fn gauss(x: f64, s: f64) -> f64 { (-x * x / (2.0 * s * s)).exp() / (2.0 * PI * s * s).sqrt() }
fn h_gauss(s: f64) -> f64 { 0.5 * (2.0 * PI * E * s * s).log2() } // the formula
fn h_simpson(s: f64) -> f64 { simpson(|x| -gauss(x, s) * gauss(x, s).log2(), -12.0 * s, 12.0 * s, 4000) }
fn splitmix64(st: u64) -> (u64, u64) {
    let st = st.wrapping_add(0x9E3779B97F4A7C15);
    let mut z = st;
    z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    (st, z ^ (z >> 31))
}
fn uniform(st: u64) -> (u64, f64) { let (st, z) = splitmix64(st); (st, ((z >> 11) + 1) as f64 / 2f64.powi(53)) }
fn h_rounded(s: f64, step: f64) -> f64 { // entropy in bits of the reading rounded to bins of width step
    let (mut tot, mut k) = (0.0, -((8.0 * s / step) as i64) - 1);
    while (k as f64) * step < 8.0 * s {
        let p = simpson(|x| gauss(x, s), k as f64 * step, (k + 1) as f64 * step, 8);
        if p > 0.0 { tot -= p * p.log2(); }
        k += 1;
    }
    tot
}
fn capacity(powers: &[f64], noise: &[f64]) -> f64 { // bits per use over parallel bell-curve-noise slots
    powers.iter().zip(noise).map(|(p, n)| 0.5 * (1.0 + p / n).log2()).sum()
}
fn water_level(noise: &[f64], total: f64) -> f64 { // bisection: the level nu whose poured power is the total
    let (mut lo, mut hi) = (0.0, total + noise.iter().cloned().fold(0.0, f64::max));
    for _ in 0..200 {
        let mid = (lo + hi) / 2.0;
        if noise.iter().map(|n| (mid - n).max(0.0)).sum::<f64>() < total { lo = mid; } else { hi = mid; }
    }
    (lo + hi) / 2.0
}
fn water_fill(noise: &[f64], total: f64) -> (f64, Vec<f64>) {
    let nu = water_level(noise, total);
    (nu, noise.iter().map(|n| (nu - n).max(0.0)).collect())
}
fn show(out: &mut Vec<String>, name: &str, v: f64) { out.push(format!("{:<44} {:>12.6}", name, v)); }

fn main() {
    let mut out: Vec<String> = Vec::new();
    // ---- differential entropy of the reading ----
    let (h_c, h_s) = (h_gauss(SIGMA), h_simpson(SIGMA));
    let (mut st, mut acc, draws) = (2026u64, 0.0, 200000);
    for _ in 0..draws / 2 { // Box-Muller: two uniforms give two bell-curve draws
        let (s1, u1) = uniform(st); let (s2, u2) = uniform(s1); st = s2;
        let r = (-2.0 * u1.ln()).sqrt();
        for z in [r * (2.0 * PI * u2).cos(), r * (2.0 * PI * u2 - PI / 2.0).cos()] { acc += -gauss(SIGMA * z, SIGMA).log2(); }
    }
    let h_mc = acc / draws as f64;
    show(&mut out, "2 pi e x spread^2", 2.0 * PI * E * SIGMA * SIGMA); show(&mut out, "  log2 of it", (2.0 * PI * E * SIGMA * SIGMA).log2());
    show(&mut out, "h, reading in C, formula", h_c); show(&mut out, "  by Simpson", h_s); show(&mut out, "  by 200000 seeded draws", h_mc);
    show(&mut out, "h, reading in F (spread 3.6)", h_simpson(3.6)); show(&mut out, "  log2 1.8", 1.8f64.log2()); show(&mut out, "  formula h + log2 1.8", h_c + 1.8f64.log2());
    show(&mut out, "h, in tens of degrees (spread 0.2)", h_simpson(0.2)); show(&mut out, "h, uniform on 0 to 0.5", 0.5f64.log2());
    for n in [0, 2, 4] {
        show(&mut out, &format!("rounded to 1/{} C: H by bins", 1 << n), h_rounded(SIGMA, 2f64.powi(-n)));
        show(&mut out, &format!("  h + {}", n), h_c + n as f64);
    }
    let h01 = h_rounded(SIGMA, 0.1);
    show(&mut out, "rounded to 0.1 C: H by bins", h01); show(&mut out, "  h + log2 10", h_c + 10f64.log2());
    // ---- the bell curve has the most, for a fixed variance ----
    let (a, b) = (SIGMA * 3f64.sqrt(), SIGMA / 2f64.sqrt()); // uniform on -a..a and Laplace with scale b: variance 4
    let (h_uni, h_lap) = ((2.0 * a).log2(), (2.0 * E * b).log2());
    let kl_uni = simpson(|x| (1.0 / (2.0 * a)) * ((1.0 / (2.0 * a)) / gauss(x, SIGMA)).log2(), -a, a, 2000);
    let lap = |x: f64| (-x.abs() / b).exp() / (2.0 * b);
    let kl_lap = 2.0 * simpson(|x| lap(x) * (lap(x) / gauss(x, SIGMA)).log2(), 0.0, 30.0 * SIGMA, 20000);
    show(&mut out, "uniform, same variance: h", h_uni); show(&mut out, "  gap to bell, h(bell) - h", h_c - h_uni);
    show(&mut out, "  D(uniform||bell) by Simpson", kl_uni);
    show(&mut out, "Laplace, same variance: h", h_lap); show(&mut out, "  gap to bell, h(bell) - h", h_c - h_lap);
    show(&mut out, "  D(Laplace||bell) by Simpson", kl_lap);
    // ---- water-filling ----
    let (nu, pw) = water_fill(&NOISE, POWER);
    let c_wf = capacity(&pw, &NOISE);
    let (mut best, mut arg, mut splits) = (-1.0, [0.0; 3], 0); // every split in steps of 0.01
    for i in 0..=500 { for j in 0..=(500 - i) {
        let split = [i as f64 / 100.0, j as f64 / 100.0, (500 - i - j) as f64 / 100.0];
        splits += 1; let c = capacity(&split, &NOISE);
        if c > best { best = c; arg = split; }
    } }
    let slopes: Vec<f64> = pw.iter().zip(NOISE.iter()).map(|(p, n)| 1.0 / (2.0 * 2f64.ln() * (p + n))).collect();
    let c_uni = capacity(&[POWER / 3.0; 3], &NOISE);
    let c_one = capacity(&[POWER, 0.0, 0.0], &NOISE);
    let tot_n: f64 = NOISE.iter().sum();
    let c_snr = capacity(&NOISE.map(|n| POWER * n / tot_n), &NOISE);
    let rev = [4.0, 2.0, 1.0];
    let c_stale = capacity(&pw, &rev);
    show(&mut out, "water level nu, by bisection", nu);
    for k in 0..3 { show(&mut out, &format!("  power in slot {} (noise {:.0})", k + 1, NOISE[k]), pw[k]); }
    show(&mut out, "capacity, bits per use", c_wf);
    show(&mut out, "grid search, splits tried", splits as f64); show(&mut out, "grid search best, steps of 0.01", best);
    for k in 0..3 { show(&mut out, &format!("  at power in slot {}", k + 1), arg[k]); }
    out.push(format!("equal split, bits in each slot: {}", NOISE.iter().map(|n| format!("{:.6}", capacity(&[POWER / 3.0], &[*n]))).collect::<Vec<_>>().join(" ")));
    show(&mut out, "wrong: equal split 5/3 each", c_uni); show(&mut out, "  water-filling gain over it, percent", 100.0 * (c_wf / c_uni - 1.0)); show(&mut out, "wrong: all power in slot 1", c_one);
    show(&mut out, "wrong: equal S/N, more to noisy slots", c_snr); show(&mut out, "wrong: stale noise map, truth 4, 2, 1", c_stale);
    show(&mut out, "  water-filled for 4, 2, 1", capacity(&water_fill(&rev, POWER).1, &rev));
    show(&mut out, "try: power 12, level", water_level(&NOISE, 12.0));
    show(&mut out, "  capacity", capacity(&water_fill(&NOISE, 12.0).1, &NOISE));
    show(&mut out, "try: power 1, water-filled", capacity(&water_fill(&NOISE, 1.0).1, &NOISE));
    show(&mut out, "  equal split", capacity(&[1.0 / 3.0; 3], &NOISE));
    let n3 = [1.0, 2.0, 3.0];
    show(&mut out, "try: slot 3 noise 3, level", water_level(&n3, POWER));
    show(&mut out, "  capacity", capacity(&water_fill(&n3, POWER).1, &n3));
    show(&mut out, "try: spread 4 C, h", h_gauss(4.0));
    let chart_wf: Vec<f64> = (0..=10).map(|p| capacity(&water_fill(&NOISE, p as f64).1, &NOISE)).collect();
    let chart_eq: Vec<f64> = (0..=10).map(|p| capacity(&[p as f64 / 3.0; 3], &NOISE)).collect();
    let fmt = |v: &[f64], d: usize| v.iter().map(|x| format!("{:.*}", d, x)).collect::<Vec<_>>().join(" ");
    println!("{}", out.join("\n"));
    println!("chart, water-filled, power 0..10: {}", fmt(&chart_wf, 3));
    println!("chart, equal split,  power 0..10: {}", fmt(&chart_eq, 3));
    println!("slope of each slot at its power: {}", fmt(&slopes, 6));
    println!("figure, y = 200 - 40 v: noise tops {} water {:.1}", fmt(&NOISE.map(|n| 200.0 - 40.0 * n), 1), 200.0 - 40.0 * nu);

    assert!((h_c - h_s).abs() < 1e-9); // formula against the integral
    assert!((h_mc - h_c).abs() < 4.0 * 2f64.sqrt() / (2.0 * 2f64.ln()) / (draws as f64).sqrt()); // within 4 standard errors
    assert!((h_simpson(3.6) - (h_c + 1.8f64.log2())).abs() < 1e-9 && h_simpson(0.2) < 0.0);
    assert!((h01 - (h_c + 10f64.log2())).abs() < 1e-3); // rounded reading: h + log2(1/step)
    assert!(((h_c - h_uni) - kl_uni).abs() < 1e-9 && ((h_c - h_lap) - kl_lap).abs() < 1e-6);
    assert!((nu - 4.0).abs() < 1e-9 && (c_wf - (0.5 * 4f64.log2() + 0.5 * 2f64.log2())).abs() < 1e-9);
    assert!((best - c_wf).abs() < 1e-12 && arg == [3.0, 2.0, 0.0]); // brute force finds the same split
    assert!(c_uni.max(c_one).max(c_snr).max(c_stale) < c_wf);
    assert!((0..=10).all(|p| chart_wf[p] >= chart_eq[p] - 1e-12));
    let lam = 1.0 / (2.0 * 2f64.ln() * nu); // Step 5: every used slot's slope is lam, a dry slot's no more
    let nudge: Vec<f64> = (0..3).map(|i| (capacity(&pw.iter().enumerate().map(|(k, q)| q + if k == i { 1e-6 } else { 0.0 }).collect::<Vec<f64>>(), &NOISE) - c_wf) / 1e-6).collect();
    assert!((0..3).all(|i| (nudge[i] - slopes[i]).abs() < 1e-6 && if pw[i] > 0.0 { (slopes[i] - lam).abs() < 1e-9 } else { slopes[i] <= lam + 1e-12 }));
    println!("ALL CHECKS PASS");
}
