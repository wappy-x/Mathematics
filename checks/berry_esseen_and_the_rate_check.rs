// How big must n be: Berry-Esseen and the skewness correction -- the check.
// Rust std only.  S = number of sixes in n fair-die rolls.  Roads to the law
// of S: convolution in whole numbers, the binomial formula, inversion of the
// fingerprint, and a seeded simulation.  Phi is its own series.
use std::f64::consts::PI;

const C_BE: f64 = 0.4748;
const C_LOW: f64 = 0.409732; // Esseen's floor
const EPS: f64 = 1.0 / 20.0;

#[derive(Clone, Copy)]
struct Cx { re: f64, im: f64 }
impl Cx {
    fn mul(self, o: Cx) -> Cx { Cx { re: self.re * o.re - self.im * o.im, im: self.re * o.im + self.im * o.re } }
    fn sub(self, o: Cx) -> Cx { Cx { re: self.re - o.re, im: self.im - o.im } }
    fn abs(self) -> f64 { self.re.hypot(self.im) }
}
fn cpow(z: Cx, m: usize) -> Cx { let mut w = Cx { re: 1.0, im: 0.0 }; for _ in 0..m { w = w.mul(z); } w }

fn phi_cdf(x: f64) -> f64 { // bell-curve area left of x
    if x.abs() > 8.0 { return if x > 0.0 { 1.0 } else { 0.0 }; }
    let (mut s, mut t, mut k) = (x, x, 0.0);
    while t.abs() > 1e-17 * s.abs() { k += 1.0; t *= x * x / (2.0 * k + 1.0); s += t; }
    0.5 + (-x * x / 2.0).exp() / (2.0 * PI).sqrt() * s
}
fn dens(x: f64) -> f64 { (-x * x / 2.0).exp() / (2.0 * PI).sqrt() } // Phi'(x)
fn law(n: usize, p: f64) -> Vec<f64> {
    let q = 1.0 - p;
    let mut pm = vec![q.powf(n as f64)];
    for k in 1..=n { let last = pm[k - 1]; pm.push(last * (n - k + 1) as f64 / k as f64 * p / q); }
    pm
}
// largest gaps: plain bell (both sides of each jump), half-step, half-step + Edgeworth
fn gaps(n: usize, p: f64, sign: f64, half: f64, skew_scale: f64) -> (f64, f64, f64, Vec<(usize, f64, f64, f64, f64)>) {
    let q = 1.0 - p;
    let (mu, sd) = (n as f64 * p, (n as f64 * p * q).sqrt());
    let g = skew_scale * (1.0 - 2.0 * p) / (p * q).sqrt();
    let (mut f, mut d, mut dh, mut de) = (0.0, 0.0f64, 0.0f64, 0.0f64);
    let mut rows = Vec::new();
    for (k, pk) in law(n, p).into_iter().enumerate() {
        let fl = f; f += pk;
        let z = (k as f64 - mu) / sd; let zh = (k as f64 + half - mu) / sd;
        let edg = phi_cdf(zh) - sign * dens(zh) * g * (zh * zh - 1.0) / (6.0 * (n as f64).sqrt());
        d = d.max((f - phi_cdf(z)).abs()).max((fl - phi_cdf(z)).abs());
        dh = dh.max((f - phi_cdf(zh)).abs()); de = de.max((f - edg).abs());
        rows.push((k, f, phi_cdf(z), phi_cdf(zh), edg));
    }
    (d, dh, de, rows)
}
fn g3(n: usize, p: f64) -> (f64, f64, f64) { let (a, b, c, _) = gaps(n, p, 1.0, 0.5, 1.0); (a, b, c) }
fn ratio(p: f64) -> f64 { (p * (1.0 - p)) * ((1.0 - p).powf(2.0) + p.powf(2.0)) / (p * (1.0 - p)).powf(1.5) }

fn main() {
    let (n, p) = (20usize, 1.0f64 / 6.0);
    let (gam, r) = ((1.0 - 2.0 * p) / (p * (1.0 - p)).sqrt(), ratio(p));
    println!("one roll: variance 5/36 = {:.6}, sigma = {:.6}, rho = 65/648 = {:.6}", 5.0 / 36.0, (5.0f64 / 36.0).sqrt(), 65.0 / 648.0);
    println!("rho/sigma^3 = {:.6}, skewness gamma = {:.6}", r, gam);
    assert!((r - [(1.0, p), (0.0, 1.0 - p)].iter().map(|&(x, w): &(f64, f64)| w * (x - p).abs().powi(3)).sum::<f64>() / (5.0f64 / 36.0).powf(1.5)).abs() < 1e-12, "rho/sigma^3 by definition");

    // ---- road 1 and 2: exact counts of the 6^20 roll sequences ----
    let mut cnt: Vec<u64> = vec![1]; // weights: 5 ways not six, 1 way six
    for _ in 0..n {
        let mut nw = vec![0u64; cnt.len() + 1];
        for k in 0..nw.len() { nw[k] = 5 * if k < cnt.len() { cnt[k] } else { 0 } + if k > 0 { cnt[k - 1] } else { 0 }; }
        cnt = nw;
    }
    let mut binom: Vec<u64> = vec![1];
    for k in 1..=n { let b = binom[k - 1] * (n - k + 1) as u64 / k as u64; binom.push(b); }
    for k in 0..=n { assert!(cnt[k] == binom[k] * 5u64.pow((n - k) as u32), "convolution = binomial"); }
    let six20 = 6f64.powf(n as f64);
    let exact: Vec<f64> = cnt.iter().map(|&c| c as f64 / six20).collect();
    // ---- road 3: inversion of the fingerprint (q + p e^{it})^n at 21 frequencies ----
    let mut err_inv = 0.0f64;
    for k in 0..=n {
        let mut tot = Cx { re: 0.0, im: 0.0 };
        for j in 0..=n {
            let t = 2.0 * PI * j as f64 / (n + 1) as f64;
            let term = cpow(Cx { re: 1.0 - p + p * t.cos(), im: p * t.sin() }, n).mul(Cx { re: (t * k as f64).cos(), im: -(t * k as f64).sin() });
            tot = Cx { re: tot.re + term.re, im: tot.im + term.im };
        }
        err_inv = err_inv.max((tot.re / (n + 1) as f64 - exact[k]).abs());
    }
    let f3: f64 = exact[..4].iter().sum();
    println!("P(S <= 3) exact = {}/6^20 = {:.6}", cnt[..4].iter().sum::<u64>(), f3);
    println!("inversion vs count, largest difference below 1e-12: {}", if err_inv < 1e-12 { "True" } else { "False" });
    assert!(err_inv < 1e-12, "inversion of the fingerprint recovers the law");
    // ---- road 4: simulation, SplitMix64, seed 2026 ----
    let mut state: u64 = 2026;
    let mut nxt = || { state = state.wrapping_add(0x9E3779B97F4A7C15); let mut z = state;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9); z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB); z ^ (z >> 31) };
    let (sims, mut hits) = (100000usize, 0usize);
    for _ in 0..sims {
        let mut sixes = 0; for _ in 0..n { if (nxt() >> 32) % 6 == 5 { sixes += 1; } }
        if sixes <= 3 { hits += 1; }
    }
    let freq = hits as f64 / sims as f64; let se = (f3 * (1.0 - f3) / sims as f64).sqrt();
    println!("simulated P(S <= 3), {} sessions = {:.5}, {:.2} SE off", sims, freq, (freq - f3).abs() / se);
    assert!((freq - f3).abs() < 4.0 * se, "simulation within 4 standard errors");

    // ---- the gaps at n = 20 ----
    let (d, dh, de, rows) = gaps(n, p, 1.0, 0.5, 1.0);
    println!("k  F(k) exact  bell  half-step  +Edgeworth   errors x1000: bell half edge");
    for &(k, f, b, h, e) in rows.iter().take(9) {
        println!("{} {:.4} {:.4} {:.4} {:.4}   {:7.2} {:6.2} {:6.2}", k, f, b, h, e, 1000.0 * (f - b), 1000.0 * (f - h), 1000.0 * (f - e));
    }
    assert!((f3 - rows[3].1).abs() < 1e-12, "float law agrees with the count");
    let be = C_BE * r / (n as f64).sqrt();
    println!("Berry-Esseen bound {} x {:.4} / sqrt(20) = {:.4}", C_BE, r, be);
    println!("largest gap, plain bell = {:.4}, gap / bound = {:.3}", d, d / be);
    println!("largest gap, half-step = {:.4}; half-step + Edgeworth = {:.4}", dh, de);
    println!("Edgeworth gain: {:.2} times smaller", dh / de);
    println!("bars at n = 20, one # per 5 thousandths:");
    for (name, v) in [("Berry-Esseen bound", be), ("plain bell", d), ("half step", dh), ("half step + Edgeworth", de)] {
        println!("  {:<22}{:<42}{:6.1}", name, "#".repeat((200.0 * v).round() as usize), 1000.0 * v);
    }
    let (mu, sd) = (n as f64 * p, (n as f64 * p * (1.0 - p)).sqrt()); let (z3, zh3) = ((3.0 - mu) / sd, (3.5 - mu) / sd);
    println!("total: mean {:.6}, sd {:.6}; k = 3: z = {:.4}, half-step z = {:.4}", mu, sd, z3, zh3);
    println!("  Phi'(z) = {:.6}, Edgeworth term = {:+.6}", dens(zh3), -dens(zh3) * gam * (zh3 * zh3 - 1.0) / (6.0 * (n as f64).sqrt()));
    println!("sharper Shevtsova form 0.33554 x ({:.4} + 0.415) / sqrt(20) = {:.4}", r, 0.33554 * (r + 0.415) / (n as f64).sqrt());
    assert!(d <= be && d > EPS && EPS > dh && dh > de, "bound holds; only the corrections beat 1/20");

    // ---- how big must n be for a gap under 1/20? ----
    println!("Berry-Esseen promises 1/20 from n = {}", ((C_BE * r / EPS).powf(2.0)).ceil());
    let nmax = 400usize;
    let tab: Vec<(f64, f64, f64)> = (0..=nmax).map(|m| if m == 0 { (0.0, 0.0, 0.0) } else { g3(m, p) }).collect();
    for (w, name) in ["plain bell", "half-step", "half-step + Edgeworth"].iter().enumerate() {
        let mut last = 0;
        for m in 1..=nmax { let v = [tab[m].0, tab[m].1, tab[m].2][w]; if v >= EPS { last = m; } }
        println!("actual gap under 1/20 for every n from {} to {}: {}", last + 1, nmax, name);
    }
    println!("n  plain  half-step  +Edgeworth  bound   (x1000)");
    for &m in [5usize, 10, 20, 50, 100, 200, 400].iter() {
        let (a, b, c) = tab[m]; let bm = C_BE * r / (m as f64).sqrt();
        println!("{} {:.1} {:.1} {:.1} {:.1}", m, 1000.0 * a, 1000.0 * b, 1000.0 * c, 1000.0 * bm);
        assert!(a <= bm, "Berry-Esseen holds at every n");
    }
    assert!(tab[400].2 * 400.0 < tab[20].2 * 20.0 && tab[400].1 * 20.0 > tab[20].1, "1/n against 1/sqrt(n)");

    // ---- the fingerprint: why the Edgeworth term is the next order ----
    let (mut e1_20, mut e2_20, mut e1, mut e2) = (0.0, 0.0, 0.0, 0.0);
    for &m in [20usize, 80].iter() {
        let (t, mu, sd) = (1.0f64, m as f64 * p, (m as f64 * p * (1.0 - p)).sqrt());
        let u = t / sd;
        let phiz = cpow(Cx { re: 1.0 - p + p * u.cos(), im: p * u.sin() }, m).mul(Cx { re: (t * mu / sd).cos(), im: -(t * mu / sd).sin() });
        let g0 = (-t * t / 2.0).exp();
        let edg = Cx { re: g0, im: 0.0 }.mul(Cx { re: 1.0, im: -gam * t.powf(3.0) / (6.0 * (m as f64).sqrt()) }); // (it)^3 = -i t^3
        e1 = phiz.sub(Cx { re: g0, im: 0.0 }).abs(); e2 = phiz.sub(edg).abs();
        println!("fingerprint at t = 1, n = {}: gap to bell {:.6}, after Edgeworth {:.6}", m, e1, e2);
        if m == 20 { e1_20 = e1; e2_20 = e2; }
    }
    assert!(1.8 < e1_20 / e1 && e1_20 / e1 < 2.2 && e2_20 / e2 > 3.5, "orders 1/sqrt(n) and 1/n");

    // ---- what breaks ----
    let (dc, dhc, dec) = g3(20, 0.5);
    println!("fair coin: gap {:.4}, bound {:.4}, half-step {:.4}, +Edgeworth {:.4}", dc, C_BE / 20f64.sqrt(), dhc, dec);
    assert!((dhc - dec).abs() < 1e-15 && dc < C_BE / 20f64.sqrt(), "zero skewness, zero gain");
    println!("Edgeworth without the half-step: {:.4}", gaps(n, p, 1.0, 0.0, 1.0).2);
    println!("Edgeworth with the wrong sign: {:.4}", gaps(n, p, -1.0, 0.5, 1.0).2);
    println!("skewness of the total, divided by sqrt(n) again: {:.4}", gaps(n, p, 1.0, 0.5, 1.0 / (n as f64).sqrt()).2);
    println!("bound without sigma^3: {} x {:.4} / sqrt(20) = {:.4}", C_BE, 65.0 / 648.0, C_BE * 65.0 / 648.0 / (n as f64).sqrt());

    // ---- try changing ----
    let (d80, dh80, de80) = g3(80, p);
    println!("try n = 80: bound {:.4}, gaps {:.4} {:.4} {:.4}", C_BE * r / 80f64.sqrt(), d80, dh80, de80);
    let (dd, dhd, ded) = g3(20, 1.0 / 36.0);
    println!("try double sixes, p = 1/36: bound {:.4}, gaps {:.4} {:.4} {:.4}", C_BE * ratio(1.0 / 36.0) / 20f64.sqrt(), dd, dhd, ded);
    println!("try floor constant {}: {:.4}", C_LOW, C_LOW * r / 20f64.sqrt());
    println!("try target 1/100: Berry-Esseen needs n = {}", ((C_BE * r / 0.01).powf(2.0)).ceil());
    println!("ALL CHECKS PASS");
}
