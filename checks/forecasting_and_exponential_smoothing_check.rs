// Forecasting with exponential smoothing -- the check behind the card.  Rust std only.
// Monthly airline passengers, thousands, 1949-1960 (Box-Jenkins series G); Holt-Winters on the logs, fitted to 1949-1959.
// Interval width three ways: a loop over the error weights, their closed form, 20,000 simulated years (SplitMix64 below).
const P: [u32; 144] = [
    112, 118, 132, 129, 121, 135, 148, 148, 136, 119, 104, 118, 115, 126, 141, 135, 125, 149, 170, 170, 158, 133, 114, 140,
    145, 150, 178, 163, 172, 178, 199, 199, 184, 162, 146, 166, 171, 180, 193, 181, 183, 218, 230, 242, 209, 191, 172, 194,
    196, 196, 236, 235, 229, 243, 264, 272, 237, 211, 180, 201, 204, 188, 235, 227, 234, 264, 302, 293, 259, 229, 203, 229,
    242, 233, 267, 269, 270, 315, 364, 347, 312, 274, 237, 278, 284, 277, 317, 313, 318, 374, 413, 405, 355, 306, 271, 306,
    315, 301, 356, 348, 355, 422, 465, 467, 404, 347, 305, 336, 340, 318, 362, 348, 363, 435, 491, 505, 404, 359, 310, 337,
    360, 342, 406, 396, 420, 472, 548, 559, 463, 407, 362, 405, 417, 391, 419, 461, 472, 535, 622, 606, 508, 461, 390, 432];
const M: usize = 12; // months in one season
const Z: f64 = 1.96; // the 95% normal quantile
const MON: [&str; 12] = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];

// Holt-Winters over y; returns final level, trend, seasons and the one-step squared errors
fn run(y: &[f64], a: f64, b: f64, g: f64, seasons: bool) -> (f64, f64, Vec<f64>, f64) {
    let mut lev = y[..M].iter().fold(0.0, |s, v| s + v) / M as f64;
    let mut tr = (y[M..2 * M].iter().fold(0.0, |s, v| s + v) - y[..M].iter().fold(0.0, |s, v| s + v)) / (M * M) as f64;
    let mut sea: Vec<f64> = y[..M].iter().map(|v| if seasons { v - lev } else { 0.0 }).collect();
    let mut sse = 0.0;
    for t in M..y.len() {
        let s = sea[t % M];
        let e = y[t] - lev - tr - s;
        sse += e * e;
        sea[t % M] = g * (y[t] - lev - tr) + (1.0 - g) * s;
        let new = a * (y[t] - s) + (1.0 - a) * (lev + tr);
        tr = b * (new - lev) + (1.0 - b) * tr;
        lev = new;
    }
    (lev, tr, sea, sse)
}

// coarse grid in tenths, then hundredths around the best point
fn fit(y: &[f64]) -> (f64, f64, f64) {
    let mut best = (1e9, 0i64, 0i64, 0i64);
    let try_it = |i: i64, j: i64, k: i64, d: f64, w: i64, best: &mut (f64, i64, i64, i64)| {
        let e = run(y, i as f64 / d, j as f64 / d, k as f64 / d, true).3;
        if e < best.0 { *best = (e, i * w, j * w, k * w); }
    };
    for i in 1..10 { for j in 0..10 { for k in 0..10 { try_it(i, j, k, 10.0, 10, &mut best); } } }
    let (_, i0, j0, k0) = best;
    for i in (i0 - 9).max(1)..(i0 + 10).min(100) {
        for j in (j0 - 9).max(0)..(j0 + 10).min(100) {
            for k in (k0 - 9).max(0)..(k0 + 10).min(100) { try_it(i, j, k, 100.0, 1, &mut best); }
        }
    }
    (best.1 as f64 / 100.0, best.2 as f64 / 100.0, best.3 as f64 / 100.0)
}

struct Rng(u64); // SplitMix64, seed 0x2026092905
impl Rng {
    fn u01(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut x = self.0;
        x = (x ^ (x >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        x = (x ^ (x >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((x ^ (x >> 31)) >> 11) as f64 / 9007199254740992.0 + 1.1102230246251565e-16
    }
    fn normal(&mut self) -> f64 {
        let r = (-2.0 * self.u01().ln()).sqrt();
        r * (2.0 * std::f64::consts::PI * self.u01()).cos()
    }
}

fn main() {
    let yall: Vec<f64> = P.iter().map(|&p| (p as f64).ln()).collect();
    let (fitd, act) = (&yall[..132], &P[132..]);
    let (a, b, g) = fit(fitd);
    let (lev, tr, sea, sse) = run(fitd, a, b, g, true);
    let n = fitd.len() - M;
    let sig = (sse / n as f64).sqrt();
    println!("fit     alpha {:.2}  beta {:.2}  gamma {:.2}  one-step errors {}  sigma {:.6}  se {:.6}", a, b, g, n, sig, sig / ((2 * n) as f64).sqrt());
    println!("state   Dec 1959: level {:.6}  trend {:.6}  s_Jan {:.6}  s_Jul {:.6}  s_Dec {:.6}", lev, tr, sea[0], sea[6], sea[11]);
    let mut l2 = fitd[..M].iter().fold(0.0, |s, v| s + v) / M as f64;
    let mut t2 = (fitd[M..2 * M].iter().fold(0.0, |s, v| s + v) - fitd[..M].iter().fold(0.0, |s, v| s + v)) / (M * M) as f64;
    let mut s2: Vec<f64> = fitd[..M].iter().map(|v| v - l2).collect();
    for t in M..132 { let e = fitd[t] - l2 - t2 - s2[t % M]; l2 = l2 + t2 + a * e; t2 += a * b * e; s2[t % M] += g * e; } // Step 3's form
    println!("ec      error-correction form, Dec 1959: level {:.6}  trend {:.6}  s_Jul {:.6}", l2, t2, s2[6]);

    let c: Vec<f64> = (0..M).map(|j| if j == 0 { 1.0 } else { a * (1.0 + j as f64 * b) }).collect(); // weight of a shock j months back
    let v_loop: Vec<f64> = (1..=M).map(|h| (0..h).fold(0.0, |s, j| s + c[j] * c[j])).collect();
    let v_closed: Vec<f64> = (1..=M).map(|h| { let hf = h as f64;
        1.0 + (hf - 1.0) * (a * a + a * a * b * hf + a * a * b * b * hf * (2.0 * hf - 1.0) / 6.0) }).collect();
    let f: Vec<f64> = (1..=M).map(|h| lev + h as f64 * tr + sea[(h - 1) % M]).collect();

    let mut rng = Rng(0x2026092905);
    let nn = 20000usize;
    let mut err = vec![vec![0.0f64; nn]; M];
    let mut tot: Vec<f64> = Vec::with_capacity(nn);
    for p in 0..nn { // run the same smoothing equations forward on simulated months
        let (mut l, mut t, mut s_, mut total) = (lev, tr, sea.clone(), 0.0);
        for h in 0..M {
            let s = s_[h];
            let yv = l + t + s + sig * rng.normal();
            err[h][p] = yv - f[h];
            total += yv.exp();
            s_[h] = g * (yv - l - t) + (1.0 - g) * s;
            let new = a * (yv - s) + (1.0 - a) * (l + t);
            t = b * (new - l) + (1.0 - b) * t;
            l = new;
        }
        tot.push(total);
    }

    println!(" h month  forecast   lower   upper  actual  in | sd loop  sd closed  sd sim  cover sim  cover flat");
    let (mut inside, mut cov12, mut flat12, mut mean12) = (0, 0.0, 0.0, 0.0);
    let mut sd_sim = Vec::new();
    for h in 0..M {
        let w = Z * sig * v_loop[h].sqrt();
        let (lo, hi) = ((f[h] - w).exp(), (f[h] + w).exp());
        let ok = lo <= act[h] as f64 && act[h] as f64 <= hi;
        if ok { inside += 1; }
        let mean = err[h].iter().fold(0.0, |s, e| s + e) / nn as f64;
        sd_sim.push((err[h].iter().fold(0.0, |s, e| s + (e - mean) * (e - mean)) / (nn - 1) as f64).sqrt());
        let cover = err[h].iter().filter(|e| e.abs() <= w).count() as f64 / nn as f64;
        let flat = err[h].iter().filter(|e| e.abs() <= Z * sig).count() as f64 / nn as f64;
        println!("{:2} {}  {:9.2} {:7.2} {:7.2} {:7}  {}| {:.5}  {:.5}    {:.5}  {:.4}    {:.4}", h + 1, MON[h], f[h].exp(), lo, hi, act[h],
            if ok { "yes" } else { "NO " }, sig * v_loop[h].sqrt(), sig * v_closed[h].sqrt(), sd_sim[h], cover, flat);
        if h == M - 1 { cov12 = cover; flat12 = flat; mean12 = mean; }
    }

    tot.sort_by(|x, y| x.partial_cmp(y).unwrap());
    let ff: Vec<f64> = f.iter().map(|x| x.exp()).collect();
    let sum_f = ff.iter().fold(0.0, |s, v| s + v);
    let mut var_tot = 0.0;
    for h in 0..M { for k in 0..M {
        let inner = (0..=h.min(k)).fold(0.0, |s, i| s + c[h - i] * c[k - i]);
        var_tot += ff[h] * ff[k] * sig * sig * inner;
    } }
    let act_sum: u32 = act.iter().sum();
    println!("total   1960 forecast {:.1}  simulated 95% band {:.1} to {:.1}  linearised {:.1} to {:.1}  actual {}", sum_f,
        tot[(0.025 * nn as f64) as usize], tot[(0.975 * nn as f64) as usize], sum_f - Z * var_tot.sqrt(), sum_f + Z * var_tot.sqrt(), act_sum);
    println!("hand    Jan log forecast {:.6}  half-width {:.6}   Jul log forecast {:.6}  v_7 {:.5}  half-width {:.6}",
        f[0], Z * sig, f[6], v_loop[6], Z * sig * v_loop[6].sqrt());
    println!("check   1960 months inside the 95% band: {} of 12   h=12 mean simulated log error {:.5}", inside, mean12);

    let mut ses_l = fitd[0]; // simple smoothing, level only: recursion against explicit weights
    for t in 1..132 { ses_l = a * fitd[t] + (1.0 - a) * ses_l; }
    let ses_w = (0..131).fold(0.0, |s, k| s + a * (1.0 - a).powf(k as f64) * fitd[131 - k]) + (1.0 - a).powf(131.0) * fitd[0];
    println!("ses     recursion {:.10}  weighted sum {:.10}", ses_l, ses_w);
    let wts: Vec<String> = (0..6).map(|k| format!("j={} {:.4}", k, a * (1.0 - a).powf(k as f64))).collect();
    println!("weights {}", wts.join("  "));

    let rawy: Vec<f64> = P[..132].iter().map(|&p| p as f64).collect(); // additive seasons on the raw counts
    let (ar, br, gr) = fit(&rawy);
    let (lr, trr, sr, _) = run(&rawy, ar, br, gr, true);
    let raw: Vec<f64> = (0..M).map(|h| lr + (h + 1) as f64 * trr + sr[h]).collect();
    let mape = |fc: &[f64]| 100.0 * (0..M).fold(0.0, |s, h| s + (fc[h] - act[h] as f64).abs() / act[h] as f64) / M as f64;
    println!("try     log-scale error {:.2}%   raw-count fit ({:.2}, {:.2}, {:.2}) error {:.2}%   July raw {:.2}", mape(&ff), ar, br, gr, mape(&raw), raw[6]);
    let naive: u32 = P[120..132].iter().sum();
    println!("breaks  same month last year: 1960 total {}  short by {}   Holt-Winters over by {:.1}", naive, act_sum - naive, sum_f - act_sum as f64);
    let k80 = (0..M).filter(|&h| ((act[h] as f64).ln() - f[h]).abs() <= 1.2816 * sig * v_loop[h].sqrt()).count();
    let (a8, b8, g8) = fit(&yall[..120]); // the same method one year earlier: fit to 1949-1958, forecast 1959
    let (l8, t8, s8, e8) = run(&yall[..120], a8, b8, g8, true);
    let v8 = |h: usize| 1.0 + (1..h).fold(0.0, |s, j| s + a8 * (1.0 + j as f64 * b8) * a8 * (1.0 + j as f64 * b8));
    let in59 = (0..M).filter(|&h| (yall[120 + h] - l8 - (h + 1) as f64 * t8 - s8[h]).abs() <= Z * (e8 / 108.0).sqrt() * v8(h + 1).sqrt()).count();
    println!("try     80% band holds {} of 12   alpha 0.9 sigma {:.6}   fit to 1958 ({:.2}, {:.2}, {:.2}): 1959 inside {} of 12",
        k80, (run(fitd, 0.9, b, g, true).3 / n as f64).sqrt(), a8, b8, g8, in59);
    let (l0, t0, _, _) = run(fitd, a, b, 0.0, false);
    println!("breaks  unwidened band at h=12 covers {:.4}   July with no season {:.2}", flat12, (l0 + 7.0 * t0).exp());

    assert!((0..M).all(|h| (v_loop[h] - v_closed[h]).abs() < 1e-12)); // two formulas, one width
    assert!((0..M).all(|h| (sd_sim[h] / (sig * v_loop[h].sqrt()) - 1.0).abs() < 4.0 / ((2 * nn) as f64).sqrt())); // simulation vs formula
    assert!((cov12 - 0.95).abs() < 4.0 * (0.95 * 0.05 / nn as f64).sqrt()); // the band covers 95%
    assert!(mean12.abs() < 4.0 * sd_sim[M - 1] / (nn as f64).sqrt()); // simulated paths centre on f
    assert!((0..M).fold((l2 - lev).abs().max((t2 - tr).abs()), |m, i| m.max((s2[i] - sea[i]).abs())) < 1e-12); // two update forms agree
    assert!((ses_l - ses_w).abs() < 1e-9); // recursion = fading weights
    println!("all checks passed");
}
