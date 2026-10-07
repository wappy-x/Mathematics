// Deflated Sharpe ratio and CSCV overfitting check. Rust std only: the normal CDF,
// its inverse, the integrals and the random numbers are all written here.
use std::f64::consts::PI;

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }
fn ncdf(x: f64) -> f64 { // N(x): bell-curve area left of x
    if x < -9.0 { return 0.0; }
    if x > 9.0 { return 1.0; }
    let (mut term, mut total, mut k) = (x, x, 1.0);  // x + x^3/3 + x^5/15 + ...
    while term.abs() > 1e-17 * total.abs() {
        term *= x * x / (2.0 * k + 1.0); total += term; k += 1.0;
    }
    0.5 + phi(x) * total
}
fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64) -> f64 {
    let (n, mut s) = (4000, f(a) + f(b));
    let h = (b - a) / n as f64;
    for i in 1..n { s += (if i % 2 == 1 { 4.0 } else { 2.0 }) * f(a + i as f64 * h); }
    s * h / 3.0
}
fn ninv(p: f64) -> f64 { // N^-1(p) by bisection
    let (mut lo, mut hi) = (-9.0, 9.0);
    for _ in 0..80 { let mid = (lo + hi) / 2.0; if ncdf(mid) < p { lo = mid; } else { hi = mid; } }
    (lo + hi) / 2.0
}
const G: f64 = 0.5772156649015329; // Euler's constant
fn emax_density(m: f64) -> f64 { simpson(&|z| z * m * phi(z) * ncdf(z).powf(m - 1.0), -12.0, 12.0) }
fn emax_tail(m: f64) -> f64 { simpson(&|z| 1.0 - ncdf(z).powf(m), 0.0, 12.0) - simpson(&|z| ncdf(z).powf(m), -12.0, 0.0) }
fn emax_approx(m: f64) -> f64 { (1.0 - G) * ninv(1.0 - 1.0 / m) + G * ninv(1.0 - 1.0 / (m * 1f64.exp())) }
// returns (SR0 annual, DSR); per_period = false is the clock-mixing mistake
fn dsr(sr_ann: f64, ppy: f64, t: f64, m: f64, skew: f64, kurt: f64, per_period: bool) -> (f64, f64) {
    let sr = if per_period { sr_ann / ppy.sqrt() } else { sr_ann };
    let s0 = if m > 1.0 { emax_approx(m) / (t - 1.0).sqrt() } else { 0.0 };
    let den = (1.0 - skew * sr + (kurt - 1.0) / 4.0 * sr * sr).sqrt();
    (s0 * ppy.sqrt(), ncdf((sr - s0) * (t - 1.0).sqrt() / den))
}
fn row(name: &str, v: f64) { println!("{:<34}{:>12.6}", name, v); }
fn row4(name: &str, v: f64) { println!("{:<34}{:>12.4}", name, v); }

struct Lcg(u64);
impl Lcg {
    fn unif(&mut self) -> f64 {
        self.0 = self.0.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
        ((self.0 >> 11) as f64 + 0.5) / 9007199254740992.0
    }
    fn pair(&mut self) -> (f64, f64) { // two normals by Box-Muller
        let (u1, u2) = (self.unif(), self.unif());
        let r = (-2.0 * u1.ln()).sqrt();
        (r * (2.0 * PI * u2).cos(), r * (2.0 * PI * u2).sin())
    }
}
const PPY: f64 = 252.0;
fn sharpe(s: f64, q: f64, n: f64) -> f64 { s / n / ((q - s * s / n) / (n - 1.0)).sqrt() * PPY.sqrt() }

// st[j][b] = (sum, sumsq); returns (splits where the in-sample winner lands below the middle, splits)
fn cscv(st: &Vec<Vec<(f64, f64)>>, blocks: usize, l: usize) -> (usize, usize) {
    let splits: Vec<usize> = (0..1usize << blocks).filter(|c| c.count_ones() as usize == blocks / 2).collect();
    let score = |c: usize, j: usize, want: usize| {
        let (mut s, mut q) = (0.0, 0.0);
        for b in 0..blocks { if (c >> b & 1) == want { s += st[j][b].0; q += st[j][b].1; } }
        sharpe(s, q, (l * blocks / 2) as f64)
    };
    let mut below = 0;
    for &c in &splits {
        let best = (1..st.len()).fold(0, |b, j| if score(c, j, 1) > score(c, b, 1) { j } else { b });
        let oos: Vec<f64> = (0..st.len()).map(|j| score(c, j, 0)).collect();
        let rank = 1 + oos.iter().filter(|&&o| o < oos[best]).count(); // rank 1 = worst out of sample
        if rank <= st.len() / 2 { below += 1; }
    }
    (below, splits.len())
}

fn main() {
    // ---- the example: best of 100 random strategies, 3 years of daily returns, Sharpe 1.4 ----
    let (m, t, sr) = (100.0, 756.0, 1.4);
    let sd_ann = (PPY / (t - 1.0)).sqrt(); // spread of a no-skill annual Sharpe
    let (e_exact, e_tail, e_apx) = (emax_density(m), emax_tail(m), emax_approx(m));
    let (s0_ann, d) = dsr(sr, PPY, t, m, 0.0, 3.0, true);
    let psr0 = dsr(sr, PPY, t, 1.0, 0.0, 3.0, true).1;
    let (p_one, p_max) = (1.0 - psr0, 1.0 - ncdf(sr / sd_ann).powf(m));
    let (sr_d, s0_d) = (sr / PPY.sqrt(), e_apx / (t - 1.0).sqrt()); // the hand chain, per day
    let den = (1.0 + 2.0 / 4.0 * sr_d * sr_d).sqrt();
    let simp = 0.5 + simpson(&phi, 0.0, 1.5);
    println!("{:<34}{:>12.8}{:>12.8}", "N(1.5): series, Simpson", ncdf(1.5), simp);
    row("observed best annual Sharpe", sr); row("winner's Sharpe per day", sr_d);
    row("no-skill Sharpe spread per day", 1.0 / (t - 1.0).sqrt()); row("no-skill annual Sharpe spread", sd_ann);
    row("E[max of 100 z], density integral", e_exact); row("E[max of 100 z], tail integral", e_tail);
    row("N^-1(1 - 1/100)", ninv(1.0 - 1.0 / m)); row("N^-1(1 - 1/(100e))", ninv(1.0 - 1.0 / (m * 1f64.exp())));
    row("E[max of 100 z], two-quantile", e_apx); row("expected best annual Sharpe, exact", e_exact * sd_ann);
    row("SR0 per day", s0_d); row("SR0 annual (deflation bar)", s0_ann);
    row("gap per day", sr_d - s0_d); row("sqrt(T - 1)", (t - 1.0).sqrt()); row("denominator", den);
    row("z", (sr_d - s0_d) * (t - 1.0).sqrt() / den); row("DSR", d);
    row("PSR against zero (naive)", psr0); row("one-test p-value", p_one);
    row("Bonferroni 100 x p", 100.0 * p_one); row("P(best of 100 >= 1.4 | no skill)", p_max);
    println!("chart: M, expected best annual Sharpe");
    for k in [1, 2, 5, 10, 20, 50, 100, 200, 500, 1000] {
        println!("  M={:<5}{:>10.2}", k, (emax_density(k as f64) * sd_ann).max(0.0)); // clamp round-off: E[max] >= 0
    }
    // ---- the same 1.4 on ten years of monthly returns (independent reference run) ----
    let (s0_m, d_m) = dsr(sr, 12.0, 120.0, m, 0.0, 3.0, true);
    row("monthly 10y: SR0 annual", s0_m); row("monthly 10y: DSR", d_m);
    // ---- what breaks, and try changing ----
    row("wrong: count 10 trials, not 100", dsr(sr, PPY, t, 10.0, 0.0, 3.0, true).1);
    row("wrong: annual Sharpe, daily clock", dsr(sr, PPY, t, m, 0.0, 3.0, false).1);
    row("try: M = 1000, DSR", dsr(sr, PPY, t, 1000.0, 0.0, 3.0, true).1);
    row("try: 10 years daily, DSR", dsr(sr, PPY, 2520.0, m, 0.0, 3.0, true).1);
    row("try: monthly, skew -1 kurt 6, DSR", dsr(sr, 12.0, 120.0, m, -1.0, 6.0, true).1);

    // ---- road 3: simulate the search itself, and run CSCV on every matrix ----
    let (reps, blocks, tt, mm) = (500, 6, 756usize, 100usize);
    let (l, mut rng) = (tt / blocks, Lcg(20260928));
    let (mut tot_max, mut hits, mut below_n, mut below_s, mut count) = (0.0, 0, 0, 0, 0);
    for _ in 0..reps {
        let (mut noise, mut skill) = (Vec::new(), Vec::new());
        for j in 0..mm {
            let mu = 2.0 * j as f64 / (mm - 1) as f64 / PPY.sqrt(); // skill family: true annual Sharpe 0 to 2
            let mut z = Vec::with_capacity(tt);
            for _ in 0..tt / 2 { let (a, b) = rng.pair(); z.push(a); z.push(b); }
            let st: Vec<(f64, f64)> = (0..blocks).map(|b| {
                let x = &z[b * l..(b + 1) * l];
                (x.iter().fold(0.0, |a, v| a + v), x.iter().fold(0.0, |a, v| a + v * v))
            }).collect();
            skill.push(st.iter().map(|&(s, q)| (s + mu * l as f64, q + 2.0 * mu * s + mu * mu * l as f64)).collect());
            noise.push(st);
        }
        let mut best = f64::NEG_INFINITY;
        for st in &noise {
            let (s, q) = st.iter().fold((0.0, 0.0), |a, b| (a.0 + b.0, a.1 + b.1));
            best = best.max(sharpe(s, q, tt as f64));
        }
        tot_max += best; hits += (best >= sr) as usize;
        let (bn, c) = cscv(&noise, blocks, l); below_n += bn; count = c;
        below_s += cscv(&skill, blocks, l).0;
    }
    let (mc_max, mc_hit) = (tot_max / reps as f64, hits as f64 / reps as f64);
    let (pbo_n, pbo_s) = (below_n as f64 / (reps * count) as f64, below_s as f64 / (reps * count) as f64);
    row4("simulated mean best Sharpe", mc_max); row4("simulated P(best >= 1.4)", mc_hit);
    println!("{:<34}{:>12}", "CSCV splits per matrix", count);
    row4("PBO, 100 random strategies", pbo_n); row4("PBO, family with real skill", pbo_s);

    // ---- CSCV by hand: four rules, four blocks, mean P&L per block (reference case) ----
    let cols = [[8, 8, -2, -2], [2, 2, 2, 2], [-2, -2, 8, 8], [1, 1, 1, 1]];
    let mut ranks = Vec::new();
    for c in [3usize, 12, 5, 9, 6, 10] { // in-sample halves {1,2},{3,4},{1,3},{1,4},{2,3},{2,4}
        let half = |w: usize| -> Vec<i32> { cols.iter().map(|col| (0..4).filter(|b| c >> b & 1 == w).map(|b| col[b]).sum::<i32>() / 2).collect() };
        let (isc, osc) = (half(1), half(0));
        let mut pick = 0;
        for j in 1..4 { if isc[j] > isc[pick] { pick = j; } } // ties go to the earlier rule
        ranks.push(1 + (0..4).filter(|&j| osc[j] < osc[pick] || (osc[j] == osc[pick] && j > pick)).count());
        let lab: String = (0..4).filter(|b| c >> b & 1 == 1).map(|b| char::from(b'1' + b as u8)).collect();
        let join = |v: &Vec<i32>| v.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(" ");
        println!("  IS {}: means {} -> {} | OOS means {} | rank {}", lab, join(&isc), &"ABCD"[pick..pick + 1], join(&osc), ranks[ranks.len() - 1]);
    }
    println!("hand CSCV: PBO {}/{}", ranks.iter().filter(|&&r| r <= 2).count(), ranks.len());

    assert!((ncdf(1.5) - simp).abs() < 1e-12); // series vs integral
    assert!((e_exact - e_tail).abs() < 1e-8); // two different integrals
    assert!((e_apx - e_exact).abs() < 0.03); // the paper's shortcut is close
    assert!((mc_max - e_exact * sd_ann).abs() < 0.08); // simulation vs integral
    assert!((mc_hit - p_max).abs() < 0.15); // simulation vs max law
    assert!((pbo_n - 0.5).abs() < 0.05); // symmetry says 1/2 for noise
    assert!(pbo_s < 0.35); // real skill travels
    assert!((d_m - 0.964526).abs() < 1e-5); // independent earlier run
    assert_eq!(ranks, vec![1, 1, 4, 4, 4, 4]); // the hand enumeration
    println!("all checks passed");
}
