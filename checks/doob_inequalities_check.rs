// Doob's inequalities -- the same check as doob_inequalities_check.py, in Rust.  std only.
// A gambler starts with $10, bets $1 a round on a fair coin, and must stop when broke.
// The chance her fortune ever exceeds $30 (touches $31) within 100 rounds, by four roads.
const X0: usize = 10; const LAM: usize = 31; const N: usize = 100;
const TOP: usize = X0 + N; // the highest fortune reachable in N rounds

fn joint_law(n: usize) -> Vec<Vec<f64>> {
    // exact law of (fortune x after n rounds, peak m so far), stopped at 0
    let mut law = vec![vec![0.0f64; TOP + 1]; TOP + 1]; law[X0][X0] = 1.0;
    for _ in 0..n {
        let mut new = vec![vec![0.0f64; TOP + 1]; TOP + 1];
        for x in 0..=TOP {
            for m in x..=TOP {
                let pr = law[x][m];
                if pr == 0.0 { continue; }
                if x == 0 { new[0][m] += pr; continue; }
                new[x - 1][m] += 0.5 * pr; new[x + 1][m.max(x + 1)] += 0.5 * pr;
            }
        }
        law = new;
    }
    law
}

fn hit_by(n: usize) -> f64 {
    // chance of touching LAM by round n; the walk dies at 0 and at LAM
    let mut v = vec![0.0f64; LAM + 1]; v[X0] = 1.0; let mut hit = 0.0;
    for _ in 0..n {
        let mut w = vec![0.0f64; LAM + 1];
        for x in 1..LAM { w[x - 1] += 0.5 * v[x]; w[x + 1] += 0.5 * v[x]; }
        hit += w[LAM]; w[LAM] = 0.0; w[0] = 0.0; v = w;
    }
    hit
}

fn rounds_played(n: usize) -> f64 {
    // mean number of rounds actually bet: sum over rounds of P(still solvent)
    let mut v = vec![0.0f64; TOP + 2]; v[X0] = 1.0; let mut total = 0.0;
    for _ in 0..n {
        total += v[1..].iter().sum::<f64>();
        let mut w = vec![0.0f64; TOP + 2]; w[0] = v[0];
        for x in 1..=TOP { w[x - 1] += 0.5 * v[x]; w[x + 1] += 0.5 * v[x]; }
        v = w;
    }
    total
}

fn binom(k: i64, r: i64) -> i128 {
    let mut c: u128 = 1;
    for i in 0..r { c = c * (k - i) as u128 / (i + 1) as u128; }
    c as i128
}

fn hit_by_images(n: usize) -> f64 {
    // count paths 10 -> 30 inside (0, 31), then one step up
    let (l, a) = (LAM as i64, X0 as i64);
    let mut total = 0.0f64;
    for s in 1..=n as i64 {
        let (k, mut c) = (s - 1, 0i128);
        for j in -3..4i64 {
            for (d, sign) in [(l - 1 - a + 2 * j * l, 1i128), (l - 1 + a + 2 * j * l, -1i128)] {
                if d.abs() <= k && (k + d) % 2 == 0 { c += sign * binom(k, (k + d) / 2); }
            }
        }
        total += c as f64 / 2f64.powi(s as i32);
    }
    total
}

fn splitmix(state: &mut u64) -> u64 {
    // SplitMix64: one 64-bit word per call, 64 coin tosses
    *state = state.wrapping_add(0x9E3779B97F4A7C15);
    let mut z = *state;
    z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    z ^ (z >> 31)
}

fn simulate(paths: usize, seed: u64) -> (f64, f64, f64, f64, f64, f64) {
    let (mut st, mut hits, mut s) = (seed, 0usize, [0.0f64; 4]);
    for _ in 0..paths {
        let (w1, w2) = (splitmix(&mut st), splitmix(&mut st));
        let (mut x, mut m) = (X0 as i64, X0 as i64);
        for i in 0..N {
            if x == 0 { break; }
            let bit = if i < 64 { (w1 >> i) & 1 } else { (w2 >> (i - 64)) & 1 };
            x += if bit == 1 { 1 } else { -1 };
            if x > m { m = x; }
        }
        if m >= LAM as i64 { hits += 1; }
        s[0] += (m * m) as f64; s[1] += (m * m * m * m) as f64; s[2] += (x * x) as f64; s[3] += (x * x * x * x) as f64;
    }
    let pf = paths as f64; let (p, pk, en) = (hits as f64 / pf, s[0] / pf, s[2] / pf);
    (p, (p * (1.0 - p) / pf).sqrt(), pk, ((s[1] / pf - pk * pk) / pf).sqrt(),
     en, ((s[3] / pf - en * en) / pf).sqrt())
}

fn main() {
    let law = joint_law(N);
    let avg = |f: &dyn Fn(f64, f64) -> f64| -> f64 {
        let mut t = 0.0;
        for x in 0..=TOP { for m in x..=TOP { t += f(x as f64, m as f64) * law[x][m]; } }
        t
    };
    let (lam, x0, nf) = (LAM as f64, X0 as f64, N as f64); let b = |c: bool| if c { 1.0 } else { 0.0 };
    let p_joint = avg(&|_x, m| b(m >= lam));
    let (end_hit, end_miss) = (avg(&|x, m| x * b(m >= lam)), avg(&|x, m| x * b(m < lam)));
    let (end_mean, end_sq, peak_sq) = (avg(&|x, _m| x), avg(&|x, _m| x * x), avg(&|_x, m| m * m));
    let mut layer = 0.0; for k in 1..=TOP { let kf = k as f64; layer += (2.0 * kf - 1.0) * avg(&|_x, m| b(m >= kf)); }
    let (wins_sq, wins_pos) = (avg(&|x, _m| (x - x0) * (x - x0)), avg(&|x, _m| (x - x0).max(0.0)));
    let end_above = avg(&|x, _m| b(x >= lam));
    let (p_dp, p_img, played) = (hit_by(N), hit_by_images(N), rounds_played(N));
    let (doob, kolm, a) = (end_mean / lam, wins_sq / ((lam - x0) * (lam - x0)), (lam - x0) / nf);
    let theta = 0.5 * ((1.0 + a) / (1.0 - a)).ln(); // tanh(theta) = 21/100 minimises the bound
    let chern = |t: f64| (nf * ((t.exp() + (-t).exp()) / 2.0).ln() - (lam - x0) * t).exp();
    let (mut lo, mut hi) = (0.0f64, 2.0f64);
    for _ in 0..200 { // golden-section search for the best exponent, a second road to theta
        let (g1, g2) = (hi - 0.618034 * (hi - lo), lo + 0.618034 * (hi - lo));
        if chern(g1) < chern(g2) { hi = g2; } else { lo = g1; }
    }
    let (p_sim, se_p, pk_sim, se_pk, en_sim, se_en) = simulate(100000, 20260929);
    let rows: Vec<(&str, String)> = vec![
        ("start X0, level lambda, rounds N", format!("{} {} {}", X0, LAM, N)),
        ("E[X_N] (fair game keeps the mean)", format!("{:.6}", end_mean)),
        ("Doob bound  E[X_N]/lambda", format!("{:.6}", doob)),
        ("  Doob bound as 1 in", format!("{:.1}", 1.0 / doob)),
        ("exact p, peak DP", format!("{:.6}", p_joint)),
        ("exact p, two-barrier DP", format!("{:.6}", p_dp)),
        ("exact p, counting by images", format!("{:.6}", p_img)),
        ("  exact p as 1 in", format!("{:.1}", 1.0 / p_img)),
        ("simulated p (100000 paths)", format!("{:.6} +- {:.6}", p_sim, se_p)),
        ("E[X_N ; peak >= 31]", format!("{:.6}", end_hit)),
        ("  31 * p", format!("{:.6}", lam * p_joint)),
        ("E[X_N ; peak < 31]  (the slack)", format!("{:.6}", end_miss)),
        ("E[X_N^2]", format!("{:.6}", end_sq)),
        ("  simulated E[X_N^2]", format!("{:.4} +- {:.4}", en_sim, se_en)),
        ("E[peak^2]", format!("{:.6}", peak_sq)),
        ("  sum (2k-1) P(peak >= k)", format!("{:.6}", layer)),
        ("  simulated E[peak^2]", format!("{:.4} +- {:.4}", pk_sim, se_pk)),
        ("L2 bound  4 E[X_N^2]", format!("{:.6}", 4.0 * end_sq)),
        ("ratio E[peak^2] / E[X_N^2]", format!("{:.6}", peak_sq / end_sq)),
        ("bound on squares  E[(X_N-10)^2]/21^2", format!("{:.6}", kolm)),
        ("  E[(X_N-10)^2]", format!("{:.6}", wins_sq)),
        ("  mean rounds played", format!("{:.6}", played)),
        ("  unstopped walk  100/21^2", format!("{:.6}", nf / ((lam - x0) * (lam - x0)))),
        ("theta = atanh(21/100)", format!("{:.6}", theta)),
        ("  theta by golden-section search", format!("{:.6}", (lo + hi) / 2.0)),
        ("exponential bound  cosh^100 e^-21theta", format!("{:.6}", chern(theta))),
        ("wrong: net winnings, E[M_N]/21", format!("{:.6}", ((end_mean - x0) / (lam - x0)).abs())),
        ("  right: E[M_N^+]/21", format!("{:.6}", wins_pos / (lam - x0))),
        ("wrong: endpoint P(X_N >= 31)", format!("{:.6}", end_above)),
    ];
    for (name, v) in &rows { println!("{:<40} {}", name, v); }
    println!("\nchart, rounds   exact p %   Doob bound %");
    for n in [25usize, 50, 100, 200, 400, 800, 1600, 3200] {
        println!("chart, {:>6}   {:9.2}   {:12.2}", n, 100.0 * hit_by(n), 100.0 * doob);
    }

    assert!((end_mean - x0).abs() < 1e-9, "the stopped fair game keeps its mean");
    assert!((p_joint - p_img).abs() < 1e-12, "peak DP vs path counting by images");
    assert!((p_dp - p_img).abs() < 1e-12, "two-barrier DP vs path counting by images");
    assert!((p_sim - p_img).abs() < 4.0 * se_p, "simulation within 4 standard errors");
    assert!(p_img < chern(theta) && chern(theta) < kolm && kolm < doob, "the ladder of bounds");
    assert!((end_hit - lam * p_img).abs() < 1e-12, "on the peak event the fortune ends at 31 on average");
    assert!((layer - peak_sq).abs() < 1e-9, "layer-cake identity: two ways to average the squared peak");
    assert!(peak_sq <= 4.0 * end_sq, "Doob's L2 inequality on the exact law");
    assert!((wins_sq - played).abs() < 1e-9, "squared winnings minus rounds played is a martingale");
    assert!((theta - (lo + hi) / 2.0).abs() < 1e-6, "calculus optimum vs searched optimum");
    println!("ALL CHECKS PASS");
}
