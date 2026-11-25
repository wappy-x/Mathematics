// Hilbert's sixth problem -- the check behind the card.  Rust std only.
// Roads: the mean free path from the formula and from a hard-sphere gas run by
// Newton's laws (written out); the root 2 from Maxwell pairs drawn at random.
use std::f64::consts::PI;
const K: f64 = 1.380649e-23; const T: f64 = 293.15; const P: f64 = 101325.0; const U: f64 = 1.66053906660e-27; // SI, exact or CODATA
const D: f64 = 3.64e-10; const ROOM: f64 = 4.0; // sphere diameter (illustrative), room size
const NP: usize = 64; const BOX: f64 = 18.85; const REPS: u64 = 48;
const GRID: [f64; 11] = [0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0]; // in mean free times

fn mfp(n: f64, d: f64) -> f64 { 1.0 / (2f64.sqrt() * PI * d * d * n) } // Boltzmann's mean free path
fn sci(x: f64, p: usize) -> String {     // Python-style e-notation: 2.5035e+25
    let s = format!("{:.*e}", p, x);
    let (m, e) = s.split_once('e').unwrap();
    let e: i32 = e.parse().unwrap();
    format!("{}e{}{:02}", m, if e < 0 { '-' } else { '+' }, e.abs())
}
fn splitmix(s: &mut u64) -> u64 {
    *s = s.wrapping_add(0x9E3779B97F4A7C15);
    let mut z = (*s ^ (*s >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    (z ^ (z >> 31)) >> 11
}
fn norm(w: &[f64; 3]) -> f64 { (w[0] * w[0] + w[1] * w[1] + w[2] * w[2]).sqrt() }

fn predict(i: usize, x: &[[f64; 3]], v: &[[f64; 3]], now: f64) -> (f64, i64) {
    let (mut best, mut who) = (f64::INFINITY, -1i64);
    for a in 0..3 {
        if v[i][a] == 0.0 { continue; }
        let t = ((if v[i][a] > 0.0 { BOX } else { 0.0 }) - x[i][a]) / v[i][a];
        if t < best { best = t; who = -1 - a as i64; }
    }
    for j in 0..NP {
        if j == i { continue; }
        let dr = [x[i][0] - x[j][0], x[i][1] - x[j][1], x[i][2] - x[j][2]];
        let dv = [v[i][0] - v[j][0], v[i][1] - v[j][1], v[i][2] - v[j][2]];
        let b = dr[0] * dv[0] + dr[1] * dv[1] + dr[2] * dv[2];
        if b >= 0.0 { continue; }
        let vv = dv[0] * dv[0] + dv[1] * dv[1] + dv[2] * dv[2];
        let disc = b * b - vv * (dr[0] * dr[0] + dr[1] * dr[1] + dr[2] * dr[2] - 1.0);
        if disc < 0.0 { continue; }
        let t = ((-b - disc.sqrt()) / vv).max(0.0);
        if t < best { best = t; who = j as i64; }
    }
    (now + best, who)
}

// path inside the core, one diameter from every wall (dt = 0: is the point inside?)
fn inside(p: &[f64; 3], w: &[f64; 3], dt: f64) -> f64 {
    let (mut t0, mut t1) = (0.0f64, dt);
    for a in 0..3 {
        if w[a] == 0.0 { if !(1.0 <= p[a] && p[a] <= BOX - 1.0) { return 0.0; } continue; }
        let (ta, tb) = ((1.0 - p[a]) / w[a], (BOX - 1.0 - p[a]) / w[a]);
        t0 = t0.max(ta.min(tb)); t1 = t1.min(ta.max(tb));
    }
    if dt == 0.0 { return if t0 <= t1 { 1.0 } else { 0.0 }; }
    (t1 - t0).max(0.0) * norm(w)
}

fn gas(seed: u64, tau: f64, speed_sum: &mut [f64], paths: &mut u64, length: &mut f64) -> f64 {
    let mut s = seed;
    let (mut x, mut v): (Vec<[f64; 3]>, Vec<[f64; 3]>) = (vec![], vec![]);
    while x.len() < NP {
        let mut p = [0.0; 3];
        for a in 0..3 { p[a] = BOX * splitmix(&mut s) as f64 / 2f64.powi(53); }
        if x.iter().all(|q| (p[0] - q[0]) * (p[0] - q[0]) + (p[1] - q[1]) * (p[1] - q[1])
            + (p[2] - q[2]) * (p[2] - q[2]) > 1.0) { x.push(p); }
    }
    while v.len() < NP {
        let mut w = [0.0; 3];
        for a in 0..3 { w[a] = 2.0 * splitmix(&mut s) as f64 / 2f64.powi(53) - 1.0; }
        let r2 = w[0] * w[0] + w[1] * w[1] + w[2] * w[2];
        if 0.01 < r2 && r2 < 1.0 { let r = r2.sqrt(); v.push([w[0] / r, w[1] / r, w[2] / r]); }
    }
    let mut ev: Vec<(f64, i64)> = (0..NP).map(|i| predict(i, &x, &v, 0.0)).collect();
    let (mut now, mut g, end) = (0.0f64, 0usize, GRID[10] * tau);
    loop {
        let mut i = 0; for k in 1..NP { if ev[k].0 < ev[i].0 { i = k; } }
        let te = ev[i].0.min(end);
        while g < GRID.len() && GRID[g] * tau <= te { speed_sum[g] += v.iter().fold(0.0, |acc, w| acc + norm(w)); g += 1; }
        let dt = te - now;
        if now >= 2.0 * tau { for k in 0..NP { *length += inside(&x[k], &v[k], dt); } }
        for k in 0..NP { for a in 0..3 { x[k][a] += v[k][a] * dt; } }
        now = te;
        if te >= end { return v.iter().fold(0.0, |acc, w| acc + (w[0] * w[0] + w[1] * w[1] + w[2] * w[2])); } // energy, x2
        let jj = ev[i].1;
        let moved: Vec<usize> = if jj < 0 {
            let a = (-1 - jj) as usize; v[i][a] = -v[i][a]; vec![i]
        } else {
            let j = jj as usize;
            let dr = [x[i][0] - x[j][0], x[i][1] - x[j][1], x[i][2] - x[j][2]];
            let dv = [v[i][0] - v[j][0], v[i][1] - v[j][1], v[i][2] - v[j][2]];
            let f = (dr[0] * dv[0] + dr[1] * dv[1] + dr[2] * dv[2]) / (dr[0] * dr[0] + dr[1] * dr[1] + dr[2] * dr[2]);
            for a in 0..3 { v[i][a] -= f * dr[a]; v[j][a] += f * dr[a]; }
            if now >= 2.0 * tau { *paths += (inside(&x[i], &v[i], 0.0) + inside(&x[j], &v[j], 0.0)) as u64; }
            vec![i, j]
        };
        for &k in &moved { ev[k] = predict(k, &x, &v, now); }
        for k in 0..NP {
            if !moved.contains(&k) && ev[k].1 >= 0 && moved.contains(&(ev[k].1 as usize)) {
                ev[k] = predict(k, &x, &v, now);
            }
        }
    }
}

fn main() {
    let n = P / (K * T);
    let (lam, vbar) = (mfp(n, D), (8.0 * K * T / (PI * (28.97 * U))).sqrt());
    let (tau, phi) = (lam / vbar, n * PI * D * D * D / 6.0);
    println!("air at 20 C, 1 atm; hard spheres of diameter 0.364 nm");
    println!("n from p/(kT)                {} per m^3", sci(n, 4));
    println!("mean free path               {:.2} nm  (target area {} m^2)", lam * 1e9, sci(PI * D * D, 3));
    println!("mean speed                   {:.1} m/s", vbar);
    println!("mean free time               {:.1} ps", tau * 1e12);
    println!("collisions per second each   {}  (= mean free times in 1 s)", sci(1.0 / tau, 3));
    println!("volume fraction of spheres   {}", sci(phi, 3));
    println!("Knudsen number, 4 m room     {}", sci(lam / ROOM, 3));
    println!("periodic 4 m box: eps = d/L  {}  rate N eps^2 = {}  (log|log eps|)^(1/2) = {:.3}",
             sci(D / ROOM, 2), sci(n * ROOM * D * D, 3), (-(D / ROOM).ln()).ln().sqrt());
    assert!((lam * 1e9 - 68.0).abs() < 1.0);  // quoted: about 68 nm
    println!("Boltzmann-Grad limit in 1 m^3: shrink d, keep N d^2 fixed");
    for k in 0..4 {
        let (d, nk) = (D / 2f64.powi(k), n * 4f64.powi(k));
        println!("  d = {:.4} nm  N = {}  N d^2 = {} m^2  path = {:.2} nm  fraction = {}",
                 d * 1e9, sci(nk, 3), sci(nk * d * d, 4), mfp(nk, d) * 1e9, sci(nk * PI * d * d * d / 6.0, 3));
    }
    println!("what breaks");
    println!("  drop sqrt 2                 {:.2} nm", lam * 2f64.sqrt() * 1e9);
    println!("  radius for diameter         {:.2} nm", mfp(n, D / 2.0) * 1e9);
    println!("  keep N d^3 fixed, d/8       {:.2} nm", mfp(n * 512.0, D / 8.0) * 1e9);
    // ---- Maxwell pairs: normal components by Box-Muller from SplitMix64 ----
    let (mut s, mut rel, mut spd, pairs) = (7u64, 0.0f64, 0.0f64, 100000);
    for _ in 0..pairs {
        let mut z = [0.0f64; 6];
        for k in 0..3 {
            let (a, b) = (splitmix(&mut s), splitmix(&mut s));
            let (r, th) = ((-2.0 * ((a + 1) as f64 / 2f64.powi(53)).ln()).sqrt(), 2.0 * PI * b as f64 / 2f64.powi(53));
            z[2 * k] = r * th.cos(); z[2 * k + 1] = r * th.sin();
        }
        rel += norm(&[z[0] - z[3], z[1] - z[4], z[2] - z[5]]); spd += norm(&[z[0], z[1], z[2]]);
    }
    println!("Maxwell pairs, {} drawn: mean |v - v1| / mean |v| = {:.4}  (sqrt 2 = {:.4})", pairs, rel / spd, 2f64.sqrt());
    assert!((rel / spd - 2f64.sqrt()).abs() < 0.01);
    // ---- Newton's laws for hard spheres: an event-driven gas in a box ----
    let vol = BOX * BOX * BOX;
    let pack = NP as f64 * PI / 6.0 / vol;                 // share of the box the spheres fill
    let lam_b = mfp((NP - 1) as f64 / vol, 1.0);           // Boltzmann's mean free path, in diameters
    let vmax = (8.0 / (3.0 * PI)).sqrt();                  // Maxwell mean speed when every start speed is 1
    let tau_b = lam_b / vmax;
    let (mut speed_sum, mut paths, mut length) = (vec![0.0; GRID.len()], 0u64, 0.0f64);
    let energy: Vec<f64> = (0..REPS).map(|r| gas(1000 + r, tau_b, &mut speed_sum, &mut paths, &mut length)).collect();
    let mean_speed: Vec<f64> = speed_sum.iter().map(|s| s / (NP as f64 * REPS as f64)).collect();
    let lam_sim = length / paths as f64;
    println!("hard-sphere gas: {} boxes of {} = {} spheres, packing {:.4}", REPS, NP, REPS * NP as u64, pack);
    let (emin, emax) = energy.iter().fold((f64::INFINITY, 0.0f64), |(a, b), &e| (a.min(e), b.max(e)));
    println!("sum of v^2 in each box       {} at the start, {:.9} to {:.9} at the end", NP, emin, emax);
    println!("Boltzmann mean free path     {:.2} diameters", lam_b);
    println!("Newton, measured             {:.2} diameters from {} free paths", lam_sim, paths);
    println!("ratio Boltzmann/measured     {:.4}  (own-volume factor {:.4})", lam_b / lam_sim,
             (1.0 - pack / 2.0) / ((1.0 - pack) * (1.0 - pack) * (1.0 - pack)));
    println!("ratio without sqrt 2         {:.4}  (path {:.2})", lam_b * 2f64.sqrt() / lam_sim, lam_b * 2f64.sqrt());
    println!("Maxwell mean speed           {:.4}", vmax);
    for g in 0..GRID.len() { println!("t = {:4.1} mean free times  mean speed {:.4}", GRID[g], mean_speed[g]); }
    assert!((lam_b / lam_sim - 1.0).abs() < 0.04);    // Boltzmann's formula against the Newton gas
    assert!((mean_speed[10] - vmax).abs() < 0.02);    // Maxwell's mean speed against the Newton gas
    assert!(energy.iter().all(|e| (e - NP as f64).abs() < 1e-9)); // collisions keep the energy
    println!("ALL CHECKS PASS");
}
