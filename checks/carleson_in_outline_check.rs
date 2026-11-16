// Carleson's theorem in outline -- the same check as carleson_in_outline_check.py, in Rust.
// Standard library only, no crates. Same signals, same seed, same printed lines.
// Compile: rustc --edition 2021 -O carleson_in_outline_check.rs -o /tmp/carleson_check
use std::f64::consts::PI;

const KMAX: usize = 1024;
const POINTS: usize = 2000;
const SEED: u64 = 2026;
const EPS: f64 = 0.2;

fn splitmix(state: &mut u64) -> u64 {
    *state = state.wrapping_add(0x9E3779B97F4A7C15);
    let mut z = *state;
    z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    z ^ (z >> 31)
}

fn harmonic_direct(n: u64) -> f64 { (1..=n).rev().map(|j| 1.0 / j as f64).sum() }

fn harmonic_asym(log_n: f64, n: f64, gamma: f64) -> f64 {
    log_n + gamma + 1.0 / (2.0 * n) - 1.0 / (12.0 * n * n)
}

fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64, m: usize) -> f64 {
    let h = (b - a) / m as f64;
    let inner: f64 = (1..m).map(|i| if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h)).sum();
    (f(a) + f(b) + inner) * h / 3.0
}

fn bad_point_sums(p: u64, q: u64) -> Vec<f64> { // x = 2 pi p/q; term k has phase 2^(k-1) p mod q
    let (mut s, mut out, mut r) = (0.0, Vec::new(), p % q);
    for k in 1..=KMAX {
        s += (2.0 * PI * r as f64 / q as f64).cos() / k as f64;
        out.push(s);
        r = 2 * r % q;
    }
    out
}

fn inv_sq_sum(a: usize, b: usize) -> f64 {
    (a..=b).map(|k| 1.0 / (k as f64 * k as f64)).sum()
}

fn row(label: &str, v: &[f64]) -> String {
    label.to_string() + &v.iter().map(|x| format!("{:8.4}", x)).collect::<String>()
}

fn main() {
    let ng = 100000u64;
    let n = ng as f64;
    let gamma = harmonic_direct(ng) - n.ln() - 1.0 / (2.0 * n) + 1.0 / (12.0 * n * n) - 1.0 / (120.0 * n.powi(4));
    let si_pi = simpson(&|u: f64| if u == 0.0 { 1.0 } else { u.sin() / u }, 0.0, PI, 1000);

    // ---- the octave stack: energy, and the two bad points
    let energy = 0.5 * inv_sq_sum(1, 200000) + 0.5 / 200000.0;
    println!("octave stack energy, mean square volts^2: series {:.6}  exact pi^2/12 {:.6}", energy, PI * PI / 12.0);
    println!("octave stack rms volts: {:.4}", (PI * PI / 12.0).sqrt());
    let tail_rms = (0.5 * inv_sq_sum(KMAX + 1, 2000000)).sqrt();
    println!("rms of the part beyond octave {}: {:.4} V", KMAX, tail_rms);
    assert!((energy - PI * PI / 12.0).abs() < 1e-9);
    let chart_k = [1usize, 2, 4, 8, 16, 32, 64, 128, 256, 512, 1024];
    let (at0, at23) = (bad_point_sums(0, 1), bad_point_sums(1, 3));
    for &k in &chart_k {
        let kf = k as f64;
        assert!((at0[k - 1] - harmonic_asym(kf.ln(), kf, gamma)).abs() < 1.0 / (60.0 * kf.powi(4)) + 1e-9);
        assert!((at23[k - 1] + 0.5 * harmonic_direct(k as u64)).abs() < 1e-9);
    }
    println!("chart, octaves K        {}", chart_k.iter().map(|k| format!("{:>8}", k)).collect::<String>());
    let pick = |v: &Vec<f64>| chart_k.iter().map(|&k| v[k - 1]).collect::<Vec<f64>>();
    println!("{}", row("chart, at t = 0         ", &pick(&at0)));
    println!("{}", row("chart, at t = 1/660 s   ", &pick(&at23)));

    // ---- random instants: binary digits are fair coin flips (SplitMix64, seed 2026)
    let mut state = SEED;
    let osc_k0 = [4usize, 16, 64, 256];
    let (mut still, mut dsq, mut dsq2) = ([0usize; 4], 0.0f64, 0.0f64);
    let mut first_point: Vec<f64> = Vec::new();
    let mask53: u64 = (1u64 << 53) - 1;
    for pt in 0..POINTS {
        let words: Vec<u64> = (0..17).map(|_| splitmix(&mut state)).collect();
        let bits: Vec<u64> = (0..17 * 64).map(|i| (words[i / 64] >> (63 - i % 64)) & 1).collect();
        let mut win: u64 = (0..53).fold(0, |w, i| (w << 1) | bits[i]);
        let (mut s, mut sums) = (0.0f64, Vec::with_capacity(KMAX));
        for k in 1..=KMAX {
            s += (2.0 * PI * win as f64 / 9007199254740992.0).cos() / k as f64;
            sums.push(s);
            win = ((win << 1) & mask53) | bits[k + 52];
        }
        let last = sums[KMAX - 1];
        for (i, &k0) in osc_k0.iter().enumerate() {
            if (k0..=KMAX).map(|k| (sums[k - 1] - last).abs()).fold(0.0, f64::max) > EPS { still[i] += 1; }
        }
        let d = last - sums[15];
        dsq += d * d;
        dsq2 += d.powi(4);
        if pt == 0 { first_point = sums; }
    }
    println!("{}", row("chart, a random instant ", &pick(&first_point)));
    let mean_sq = dsq / POINTS as f64;
    let se = ((dsq2 / POINTS as f64 - mean_sq * mean_sq) / POINTS as f64).sqrt();
    let exact_sq = 0.5 * inv_sq_sum(17, KMAX);
    println!("energy between octaves 16 and {}: simulated {:.5}  exact {:.5}  std error {:.5}", KMAX, mean_sq, exact_sq, se);
    assert!((mean_sq - exact_sq).abs() < 4.0 * se);
    let fr: Vec<f64> = still.iter().map(|&c| c as f64 / POINTS as f64).collect();
    for i in 0..4 {
        println!("bars, after octave {:>3}: {:>4} of {} instants still move by more than {} V  ({:.4})", osc_k0[i], still[i], POINTS, EPS, fr[i]);
    }
    assert!(fr[0] > fr[1] && fr[1] > fr[2] && fr[2] > fr[3] && fr[0] > 0.5 && fr[3] < 0.02);

    // ---- Step 1: convergence in energy gives a fast subsequence, not the whole sequence
    let tail = |k: usize| 0.5 * (PI * PI / 6.0 - inv_sq_sum(1, k));
    let along_squares: f64 = (1..=32).map(|j| tail(j * j)).sum();
    let along_all: f64 = (1..=KMAX).map(|k| tail(k)).sum();
    println!("sum of tail energies, K = 1, 4, 9, ..., 1024: {:.4};  every K up to 1024: {:.4}", along_squares, along_all);
    assert!(along_squares < 1.0 && along_all > 3.0);

    // ---- Fejer's continuous signal: bounded, yet its partial sums at x = 0 grow without bound
    let bound = 2.0 * si_pi * PI * PI / 6.0;
    println!("Si(pi) = {:.6};  bound on |f|: 2 Si(pi) pi^2/6 = {:.4}", si_pi, bound);
    let peak = (0..200).map(|i| PI * (i as f64 + 0.5) / 4000.0)
        .map(|x| (1..=256).map(|j| (j as f64 * x).sin() / j as f64).sum::<f64>().abs()).fold(0.0, f64::max);
    println!("largest |sum of sin(jx)/j, j <= 256| on the grid: {:.4}", peak);
    assert!(peak > 1.84 && peak < si_pi);
    let mut coef: Vec<(usize, f64)> = Vec::new(); // direct road: blocks 1 and 2 as cosine coefficients
    for &(k, nb) in &[(1usize, 2usize), (2, 256)] {
        for j in 1..=nb {
            let c = 1.0 / (j as f64 * (k * k) as f64);
            coef.extend([(2 * nb - j, c), (2 * nb + j, -c)]);
        }
    }
    let direct: Vec<f64> = [4usize, 512].iter().map(|&nn| coef.iter().filter(|p| p.0 <= nn).map(|p| p.1).sum()).collect();
    assert!((direct[0] - harmonic_direct(2)).abs() < 1e-12 && (direct[1] - harmonic_direct(256) / 4.0).abs() < 1e-12);
    assert!((harmonic_direct(256) - harmonic_asym(256f64.ln(), 256.0, gamma)).abs() < 1e-6);
    let f_at_0: f64 = coef.iter().map(|p| p.1).sum();
    let prod: f64 = [(1usize, 2usize), (2, 256)].iter()
        .map(|&(k, nb)| 2.0 * (2.0 * nb as f64).sin() * (1..=nb).map(|j| (j as f64).sin() / j as f64).sum::<f64>() / (k * k) as f64).sum();
    assert!((coef.iter().map(|p| p.1 * (p.0 as f64).cos()).sum::<f64>() - prod).abs() < 1e-12); // cosine form = product form, x = 1
    println!("f at x = 0, blocks 1 and 2: {:.4}", f_at_0.abs());
    let mut fej = Vec::new();
    for k in 1..10u32 {
        let e = k * k * k;
        let h = if e <= 20 { harmonic_direct(1u64 << e) } else { harmonic_asym(e as f64 * 2f64.ln(), 2f64.powi(e as i32), gamma) };
        fej.push(h / (k * k) as f64);
    }
    println!("bars, Fejer block k      {}", (1..10).map(|k| format!("{:>8}", k)).collect::<String>());
    println!("{}", row("bars, partial sum at 0   ", &fej));
    assert!((fej[1] - direct[1]).abs() < 1e-12 && fej[8] > bound && bound > fej[7]);

    // ---- the siren square wave: converges at every non-switch instant, never uniformly
    let nn = 1001usize;
    let mut top = f64::MIN;
    for i in 1..600 {
        let x = 3.0 * PI / (nn as f64 + 1.0) * i as f64 / 600.0;
        let v: f64 = (1..=nn).step_by(2).map(|k| (k as f64 * x).sin() / k as f64).sum::<f64>() * 4.0 / PI;
        top = top.max(v);
    }
    println!("siren, N = {}: largest partial sum {:.4} V, overshoot {:.4} V;  limit (2/pi) Si(pi) = {:.4} V", nn, top, top - 1.0, 2.0 / PI * si_pi);
    assert!((top - 2.0 / PI * si_pi).abs() < 1e-3);
    println!("ALL CHECKS PASS");
}
