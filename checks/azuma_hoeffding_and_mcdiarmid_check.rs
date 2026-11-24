// Azuma-Hoeffding and McDiarmid -- the same check as azuma_hoeffding_and_mcdiarmid_check.py, in Rust.  std only.
// Part 1: a gambler bets $1 on a fair coin for 100 rounds; chance of winning $30 or more.
// Part 2: 100 balls thrown into 100 boxes; how far the count of empty boxes strays from its mean.
const N: usize = 100; const T: i64 = 30; const B: usize = 100; const Q: f64 = 0.99; const TB: f64 = 15.0;

fn comb(n: u128, k: u128) -> u128 { (0..k).fold(1u128, |c, i| c * (n - i) / (i + 1)) }
fn heads_at_least(h: usize) -> f64 {
    (h..=N).map(|k| comb(N as u128, k as u128)).sum::<u128>() as f64 / 2f64.powi(N as i32)
}

fn walk(n: usize, level: i64, absorb: bool) -> f64 {
    // exact law of the fair walk, stored at offset n; absorb=true stops it at the level
    let off = n as i64; let mut dist = vec![0.0f64; 2 * n + 1]; dist[n] = 1.0; let mut hit = 0.0;
    for _ in 0..n {
        let mut new = vec![0.0f64; 2 * n + 1];
        for (i, &p) in dist.iter().enumerate() {
            if p == 0.0 { continue; } let x = i as i64 - off;
            for y in [x - 1, x + 1] {
                if absorb && y >= level { hit += 0.5 * p; } else { new[(y + off) as usize] += 0.5 * p; }
            }
        }
        dist = new;
    }
    if absorb { hit } else { dist.iter().enumerate().filter(|(i, _)| *i as i64 - off >= level).map(|(_, p)| p).sum() }
}

fn doubling(n: usize, cap: i64) -> (f64, f64, i64) {
    // double the stake after a loss, up to cap; back to $1 after a win or a loss at cap
    let off: i64 = 64 * n as i64; let size = (2 * off + 1) as usize;
    let mut dist = vec![[0.0f64; 7]; size]; dist[off as usize][0] = 1.0;
    for _ in 0..n {
        let mut new = vec![[0.0f64; 7]; size];
        for i in 0..size {
            for j in 0..7 {
                let p = dist[i][j]; if p == 0.0 { continue; }
                let (x, s) = (i as i64 - off, 1i64 << j);
                new[(x + s + off) as usize][0] += 0.5 * p;
                new[(x - s + off) as usize][if s < cap { j + 1 } else { 0 }] += 0.5 * p;
            }
        }
        dist = new;
    }
    let (mut pr, mut mean, mut low) = (0.0, 0.0, 0i64);
    for i in 0..size {
        let (x, p) = (i as i64 - off, dist[i].iter().sum::<f64>());
        if x >= T { pr += p; } mean += p * x as f64;
        if p > 0.0 { low = low.min(x); }
    }
    (pr, mean, low)
}

fn splitmix(state: &mut u64) -> u64 {
    *state = state.wrapping_add(0x9E3779B97F4A7C15); let z = (*state ^ (*state >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    let z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    z ^ (z >> 31)
}

fn main() {
    let (nf, tf) = (N as f64, T as f64);
    // ---- Part 1: the gambler, steps of width 2 (from -1 to +1)
    let azuma = (-2.0 * tf * tf / (nf * 4.0)).exp();
    let h = (N + T as usize) / 2; let end_exact = heads_at_least(h); // gain 30 means 65 heads or more
    let peak_reflect = end_exact + heads_at_least(h + 1); // reflection: P(S >= 30) + P(S > 30)
    let (end_dp, peak_dp) = (walk(N, T, false), walk(N, T, true));
    let theta = 0.5 * ((1.0 + tf / nf) / (1.0 - tf / nf)).ln(); // atanh(0.3)
    let cosh_bound = (nf * ((theta.exp() + (-theta).exp()) / 2.0).ln() - tf * theta).exp();
    let kolmogorov = nf / (tf * tf); // Doob on the square, two-sided
    let grid: Vec<f64> = (1..=300).map(|i| i as f64 / 100.0).collect();
    let lemma_coin = grid.iter().map(|&t| ((t.exp() + (-t).exp()) / 2.0).ln() - t * t / 2.0).fold(f64::MIN, f64::max);
    let (dbl_p, dbl_mean, dbl_low) = doubling(N, 64); let dbl_azuma = (-2.0 * tf * tf / (nf * 128.0 * 128.0)).exp();
    // ---- Part 2: balls in boxes; z = empty boxes so far
    let bf = B as f64; let mean_formula = bf * Q.powi(B as i32);
    let mut law = vec![0.0f64; B + 1]; law[B] = 1.0;
    for _ in 0..B {
        let mut new = vec![0.0f64; B + 1];
        for z in 0..=B {
            let p = law[z]; if p == 0.0 { continue; }
            new[z] += p * (B - z) as f64 / bf;
            if z > 0 { new[z - 1] += p * z as f64 / bf; }
        }
        law = new;
    }
    let mean_dp: f64 = law.iter().enumerate().map(|(z, p)| z as f64 * p).sum(); let var_dp: f64 = law.iter().enumerate().map(|(z, p)| (z as f64 - mean_dp).powi(2) * p).sum();
    let tail = |t: f64| -> f64 { law.iter().enumerate().filter(|(z, _)| (*z as f64 - mean_dp).abs() >= t).map(|(_, p)| p).sum() };
    let mcd = |t: f64, w2: f64| 2.0 * (-2.0 * t * t / w2).exp(); let exact_tail = tail(TB);
    let mean_dep = (bf - 1.0 + mean_dp) / 2.0; // ball 1 leads: in an even box it draws every other ball in (99 empty); odd: free throws
    let free_far: f64 = law.iter().enumerate().filter(|(z, _)| (*z as f64 - mean_dep).abs() >= TB).map(|(_, p)| p).sum();
    let tail_dep = 0.5 * (if bf - 1.0 - mean_dep >= TB { 1.0 } else { 0.0 }) + 0.5 * free_far;
    // The Doob martingale M_k = E[N | first k balls] = z * Q^(B-k). Check fairness, widths, the lemma.
    let (mut worst_fair, mut worst_width, mut worst_lemma, mut w2_true) = (0.0f64, 0.0f64, -1.0f64, 0.0f64);
    for k in 0..B {
        let w = Q.powi((B - k - 1) as i32); w2_true += w * w;
        for z in (B - k)..=B {
            let zf = z as f64; let m_now = zf * Q.powi((B - k) as i32);
            let (up, down) = (zf * w - m_now, (zf - 1.0) * w - m_now);
            let (pu, pd) = ((bf - zf) / bf, zf / bf); worst_width = worst_width.max(up - down);
            worst_fair = worst_fair.max((pu * up + pd * down).abs());
            for t in grid.iter().step_by(10) {
                let mgf = pu * (t * up).exp() + pd * (t * down).exp();
                worst_lemma = worst_lemma.max(mgf.ln() - t * t * w * w / 8.0);
            }
        }
    }
    let (chebyshev, band95) = (var_dp / (TB * TB), (bf / 2.0 * (2.0f64 / 0.05).ln()).sqrt());
    let (mut st, trials, mut s1, mut s2, mut far) = (20261123u64, 20000usize, 0.0f64, 0.0f64, 0usize);
    for _ in 0..trials {
        let mut hit = [false; B];
        for _ in 0..B { let r = splitmix(&mut st); hit[(r % B as u64) as usize] = true; }
        let e = (B - hit.iter().filter(|&&x| x).count()) as f64;
        s1 += e; s2 += e * e; if (e - mean_formula).abs() >= 6.0 { far += 1; }
    }
    let (tr, f6) = (trials as f64, |x: f64| format!("{:.6}", x));
    let sim_mean = s1 / tr; let sim_se = ((s2 / tr - sim_mean * sim_mean) / tr).sqrt();
    let rows: Vec<(&str, String)> = vec![
        ("gambler: rounds N, target gain t", format!("{} {}", N, T)),
        ("Azuma bound  exp(-2t^2/(N*2^2))", f6(azuma)),
        ("  sum of squared widths, best tilt, exponent", format!("{:.6} {:.6} {:.6}", nf * 4.0, 4.0 * tf / (nf * 4.0), 2.0 * tf * tf / (nf * 4.0))),
        ("exact P(gain >= 30): counting, walk DP", format!("{:.6} {:.6}", end_exact, end_dp)),
        ("exact P(peak >= 30): reflection, absorbed DP", format!("{:.6} {:.6}", peak_reflect, peak_dp)),
        ("tilt atanh(0.3)", f6(theta)),
        ("Doob, exact cosh  cosh^100 e^-30theta", f6(cosh_bound)),
        ("Doob on the square  100/30^2", f6(kolmogorov)),
        ("lemma for the coin, every tilt tested", (if lemma_coin <= 0.0 { "holds" } else { "FAILS" }).to_string()),
        ("doubling to $64: P(gain >= 30), mean gain", format!("{:.6} {:.6}", dbl_p, (dbl_mean * 1e6).round() / 1e6 + 0.0)),
        ("  Azuma at width 128", f6(dbl_azuma)),
        ("balls B, boxes, distance", format!("{} {} {}", B, B, TB)),
        ("E[empty]  100 * 0.99^100", f6(mean_formula)),
        ("E[empty]  exact DP", f6(mean_dp)),
        ("  simulated (20000 throws)", format!("{:.4} +- {:.4}", sim_mean, sim_se)),
        ("Var[empty]  exact DP, and sd", format!("{:.6} {:.6}", var_dp, var_dp.sqrt())),
        ("McDiarmid  2 exp(-2*15^2/100)", f6(mcd(TB, bf))),
        ("exact P(|N - mean| >= 15), per million", format!("{:.3}", 1e6 * exact_tail)),
        ("Chebyshev  Var/15^2", f6(chebyshev)),
        ("Doob martingale fair to 1e-12", (if worst_fair < 1e-12 { "yes" } else { "no" }).to_string()),
        ("  widest step", f6(worst_width)),
        ("  lemma on every step, every tilt", (if worst_lemma <= 1e-12 { "holds" } else { "FAILS" }).to_string()),
        ("  true widths: sum of squares, McDiarmid", format!("{:.6} {:.6}", w2_true, mcd(TB, w2_true))),
        ("95% band  sqrt(50 ln 40)", f6(band95)),
        ("  exact P(|N - mean| >= band), per million", format!("{:.3}", 1e6 * tail(band95))),
        ("P(|N - mean| >= 6): simulated, exact", format!("{:.6} {:.6}", far as f64 / tr, tail(6.0))),
        ("wrong: width 2 per ball", f6(mcd(TB, 4.0 * bf))),
        ("wrong: half-width 1 as width, per million", format!("{:.3}", 1e6 * (-2.0 * tf * tf / nf).exp())),
        ("wrong: widths not squared  exp(-2t^2/200)", f6((-2.0 * tf * tf / (2.0 * nf)).exp())),
        ("try: 400 rounds, gain 30", f6((-2.0 * tf * tf / (4.0 * nf * 4.0)).exp())),
        ("try: 100 rounds, gain 40", f6((-2.0 * 1600.0 / (nf * 4.0)).exp())),
        ("try: 200 balls, mean and McDiarmid at 15", format!("{:.6} {:.6}", bf * Q.powi(200), mcd(TB, 2.0 * bf))),
        ("chromatic, 1000 vertices, t = 50", f6(mcd(50.0, 1000.0))),
        ("ball 1 leads: mean, P(miss >= 15), step c_1", format!("{:.6} {:.9} {:.6}", mean_dep, tail_dep, bf - 1.0 - mean_formula)),
        ("50 pairs: mean and McDiarmid at 15", format!("{:.6} {:.6}", bf * Q.powi(50), mcd(TB, bf / 2.0))),
    ];
    for (name, v) in &rows { println!("{:<44} {}", name, v); }
    println!("\nchart, t   exact %   McDiarmid %   Chebyshev %");
    for t in [3.0f64, 5.0, 7.0, 9.0, 11.0, 13.0, 15.0, 17.0, 19.0] {
        println!("chart, {:>2}  {:8.3}   {:11.3}   {:11.3}", t, 100.0 * tail(t), 100.0 * mcd(t, bf).min(1.0), 100.0 * (var_dp / t / t).min(1.0));
    }

    assert!((end_exact - end_dp).abs() < 1e-12, "counting vs dynamic program");
    assert!((peak_reflect - peak_dp).abs() < 1e-12, "reflection vs absorbed dynamic program");
    assert!(peak_dp < cosh_bound && cosh_bound < azuma && azuma < kolmogorov, "the ladder of bounds");
    assert!(lemma_coin <= 0.0 && worst_lemma <= 1e-12, "Hoeffding's lemma on every step tested");
    assert!((mean_formula - mean_dp).abs() < 1e-9, "mean of empty boxes: formula vs dynamic program");
    assert!((sim_mean - mean_dp).abs() < 4.0 * sim_se, "simulation within 4 standard errors");
    assert!(worst_fair < 1e-12 && worst_width <= 1.0 + 1e-12, "Doob martingale is fair with steps of width <= 1");
    assert!(exact_tail < mcd(TB, w2_true) && mcd(TB, w2_true) < mcd(TB, bf) && mcd(TB, bf) < tail_dep, "McDiarmid holds, true widths sharpen it, dependent inputs break it");
    assert!(dbl_p > azuma && dbl_mean.abs() < 1e-9, "doubling: fair, but big steps break the width-2 bound");
    assert!(dbl_low == -(127 * (N as i64 / 7) + (1i64 << (N % 7)) - 1), "doubling: all losses = 14 busts of $127, then $1 and $2");
    assert!((w2_true - (1.0 - Q.powi(2 * B as i32)) / (1.0 - Q * Q)).abs() < 1e-9, "true widths: a geometric sum of squares");
    assert!((var_dp - (mean_formula + bf * (bf - 1.0) * (1.0 - 2.0 / bf).powi(B as i32) - mean_formula * mean_formula)).abs() < 1e-9, "variance: pairs of boxes");
    println!("ALL CHECKS PASS");
}
