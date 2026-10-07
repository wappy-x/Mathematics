// Stopping without a bound -- the same check as the Python, in Rust.  No
// crates.  A gambler starts with a = 10 dollars, stakes 1 dollar a round, and
// stops at 0 (ruin) or at the goal b = 30.  Ruin odds are reached four ways:
// the martingale in one line, first-step equations solved as a linear system,
// the exact law of the stopped fortune pushed forward round by round, and a
// seeded simulation.  Then two games where optional stopping fails.
const A: usize = 10;
const B: usize = 30;

struct SplitMix64 { s: u64 }                  // the wing's generator, written out
impl SplitMix64 {
    fn unit(&mut self) -> f64 {               // a uniform draw in [0, 1)
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 * 2f64.powi(-53)
    }
}

fn first_step(p: f64, rhs: &dyn Fn(usize) -> f64) -> f64 {
    // solve -q h(x-1) + h(x) - p h(x+1) = rhs(x), 0 < x < B, h(0) = h(B) = 0
    let (q, n) = (1.0 - p, B - 1);
    let (mut c, mut d) = (vec![0.0; n], vec![0.0; n]);
    for i in 0..n {
        let (cp, dp) = if i > 0 { (c[i - 1], d[i - 1]) } else { (0.0, 0.0) };
        let piv = 1.0 - (-q) * cp;
        c[i] = -p / piv;
        d[i] = (rhs(i + 1) + q * dp) / piv;
    }
    let mut h = vec![0.0; B + 1];
    for i in (0..n).rev() { h[i + 1] = d[i] - c[i] * h[i + 2]; }
    h[A]
}

fn sum(v: &[f64]) -> f64 { v.iter().fold(0.0, |s, x| s + x) }
fn mean_of(law: &[f64], from: usize) -> f64 {
    (from..law.len()).fold(0.0, |s, x| s + x as f64 * law[x])
}

// exact law of the stopped fortune, round by round; rows are
// (ruined, reached goal, still playing, mean fortune, E[min(tau, n)])
fn push_law(p: f64, rounds: usize, marks: &[usize]) -> Vec<(usize, [f64; 5])> {
    let (mut law, mut alive_sum, mut rows) = (vec![0.0; B + 1], 0.0, Vec::new());
    law[A] = 1.0;
    for n in 0..=rounds {
        if marks.contains(&n) {
            rows.push((n, [law[0], law[B], sum(&law[1..B]), mean_of(&law, 0), alive_sum]));
        }
        alive_sum += sum(&law[1..B]);             // adds P(tau > n)
        let mut new = vec![0.0; B + 1];
        (new[0], new[B]) = (law[0], law[B]);
        for x in 1..B {
            new[x + 1] += p * law[x];
            new[x - 1] += (1.0 - p) * law[x];
        }
        law = new;
    }
    rows
}

fn simulate(p: f64, games: usize, seed: u64) -> (f64, f64, f64, f64) {
    let (mut g, mut wins, mut steps, mut steps2) = (SplitMix64 { s: seed }, 0u64, 0u64, 0u64);
    for _ in 0..games {
        let (mut x, mut t) = (A as i64, 0u64);
        while x > 0 && x < B as i64 {
            x += if g.unit() < p { 1 } else { -1 };
            t += 1;
        }
        if x == B as i64 { wins += 1; }
        steps += t;
        steps2 += t * t;
    }
    let gm = games as f64;
    let (w, m) = (wins as f64 / gm, steps as f64 / gm);
    (w, (w * (1.0 - w) / gm).sqrt(), m, ((steps2 as f64 / gm - m * m) / gm).sqrt())
}

fn main() {
    println!("fair game: start a = {}, goal b = {}, stake $1 a round, win chance 0.5", A, B);
    let w_mart = A as f64 / B as f64;
    let w_fs = first_step(0.5, &|x| if x == B - 1 { 0.5 } else { 0.0 });
    let d_fs = first_step(0.5, &|_| 1.0);
    let marks = [0, 100, 200, 300, 400, 500, 600, 700, 800, 900, 1000, 20000];
    let law = push_law(0.5, 20000, &marks);
    let last = law[law.len() - 1].1;
    println!("road 1, martingale in one line: P(reach 30) = a/b = {:.6}, P(ruin) = {:.6}", w_mart, 1.0 - w_mart);
    println!("road 2, first-step equations:   P(reach 30) = {:.6}, P(ruin) = {:.6}", w_fs, 1.0 - w_fs);
    println!("road 3, law pushed 20000 rounds: P(reach 30) = {:.6}, P(ruin) = {:.6}", last[1], last[0]);
    let (ws, wse, ds, dse) = simulate(0.5, 10000, 2026);
    println!("road 4, 10000 games, seed 2026:  P(reach 30) = {:.4} (se {:.4})", ws, wse);
    println!("chart, by round n: n, P(ruined by n), P(reached 30 by n), P(still playing), E[X at min(tau, n)]");
    for (n, r) in &law[..law.len() - 1] {
        println!("  {:5}  {:.2}  {:.2}  {:.4}  {:.6}", n, r[0], r[1], r[2], r[3]);
    }
    println!("bounded test: |X at min(tau, n)| never exceeds {}, so its tail above K = {} is 0 for every n", B, B);
    println!("duration, E[tau] in rounds: a(b - a) = {}, first-step = {:.3}, law = {:.3}, simulated = {:.1} (se {:.1})",
             A * (B - A), d_fs, last[4], ds, dse);
    println!("duration by X^2 - n: X^2 <= b^2 = {}, E[X_tau^2] = b^2 P(reach 30) = {:.3}, E[tau] = that - a^2 = {:.3}",
             B * B, (B * B) as f64 * w_mart, (B * B) as f64 * w_mart - (A * A) as f64);
    let p: f64 = 18.0 / 38.0;                    // roulette: $1 on red wins 18 times in 38
    let r = (1.0 - p) / p;
    let w_rm = (r.powf(A as f64) - 1.0) / (r.powf(B as f64) - 1.0);
    let w_rf = first_step(p, &|x| if x == B - 1 { p } else { 0.0 });
    let d_rf = first_step(p, &|_| 1.0);
    let d_rm = (A as f64 - B as f64 * w_rm) / ((1.0 - p) - p);
    let (rs, rse, rds, rdse) = simulate(p, 10000, 38);
    println!("roulette, p = 18/38 = {:.6}, martingale (q/p)^X with q/p = {:.6}", p, r);
    println!("  by hand: (q/p)^10 = {:.6}, (q/p)^30 = {:.6}, q - p = {:.6}, a - b P(reach 30) = {:.6}",
             r.powf(A as f64), r.powf(B as f64), 1.0 - 2.0 * p, A as f64 - B as f64 * w_rm);
    println!("  P(reach 30): martingale = {:.6}, first-step = {:.6}, simulated = {:.4} (se {:.4})", w_rm, w_rf, rs, rse);
    println!("  E[tau]: martingale X + n(q - p) = {:.3}, first-step = {:.3}, simulated = {:.1} (se {:.1})", d_rm, d_rf, rds, rdse);
    println!("doubling, every coin word enumerated: n, E[G_n], E|G_n - 1|, tail of |G_n| above K = 100");
    let mut dbl = Vec::new();
    for n in [1usize, 4, 7, 10] {
        let (mut mean, mut err, mut tail) = (0.0, 0.0, 0.0);
        let den = (1u64 << n) as f64;
        for word in 0..(1u64 << n) {              // bit j set = toss j+1 is a head
            let (mut stake, mut gain) = (1i64, 0i64);
            for j in 0..n {
                if gain == 1 { break; }           // already won, stopped
                if (word >> j) & 1 == 1 { gain += stake; } else { gain -= stake; stake *= 2; }
            }
            mean += gain as f64 / den;
            err += (gain - 1).abs() as f64 / den;
            if gain.abs() > 100 { tail += gain.abs() as f64 / den; }
        }
        dbl.push((mean, err, tail));
        println!("  {:2}  {:.6}  {:.6}  {:.6}", n, mean, err, tail);
    }
    let e_tau = (0..60).fold(0.0, |s, n| s + 2f64.powi(-n));
    println!("doubling: stopped gain G_tau = 1 on every run, E[tau] = {:.6} tosses, yet E[G_n] = 0 at every cap", e_tau);
    println!("no goal, stop only at 0: n, P(ruined by n) pushed (chart), by reflection, E[X at min(tau, n)], tail above 30");
    let nmax = 2000usize;
    let mut law1 = vec![0.0; A + 2002];
    law1[A] = 1.0;
    let mut one = (0.0, 0.0, 0.0);
    for n in 0..=nmax {
        if n % 250 == 0 {
            let (k_lo, k_hi) = ((n as f64 - A as f64) / 2.0, (n as f64 + A as f64) / 2.0);
            let mut refl = 0.0;                   // reflection: P(tau > n) = P(-a < S_n <= a)
            for k in 0..=n {
                if !(k_lo < k as f64 && k as f64 <= k_hi) { continue; }
                let lc = (1..=k).fold(0.0, |s, i| s + (((n - k + i) as f64) / (i as f64)).ln());
                refl += (lc - n as f64 * 2f64.ln()).exp();
            }
            one = (law1[0], 1.0 - refl, mean_of(&law1, 0));
            println!("  {:5}  {:.2}  {:.6}  {:.6}  {:.2}", n, one.0, one.1, one.2, mean_of(&law1, B + 1));
        }
        let mut new = vec![0.0; law1.len()];
        new[0] = law1[0];
        for x in 1..=(A + n) {
            new[x + 1] += 0.5 * law1[x];
            new[x - 1] += 0.5 * law1[x];
        }
        law1 = new;
    }
    println!("mistake 1, doubling: optional stopping claims E[G_tau] = 0; it is 1");
    println!("no goal as the limit of goal b: P(ruin) = 1 - a/b = {:.2} at b = 100, {:.3} at b = 1000",
             1.0 - A as f64 / 100.0, 1.0 - A as f64 / 1000.0);
    println!("mistake 2, no goal: optional stopping claims E[X_tau] = {}; X_tau = 0 on every run, since ruin is certain", A);
    println!("mistake 3, fair formula a/b on roulette: {:.6} against the true {:.6}", w_mart, w_rm);
    assert!((w_fs - w_mart).abs() < 1e-12 && (last[1] - w_mart).abs() < 1e-12);   // three roads agree
    assert!((ws - w_mart).abs() < 4.0 * wse && (rs - w_rm).abs() < 4.0 * rse);     // simulation within 4 se
    assert!((d_fs - (A * (B - A)) as f64).abs() < 1e-9 && (last[4] - d_fs).abs() < 1e-6 && (ds - d_fs).abs() < 4.0 * dse);
    assert!((w_rf - w_rm).abs() < 1e-12 && (d_rf - d_rm).abs() < 1e-9 && (rds - d_rm).abs() < 4.0 * rdse);
    assert!((one.0 - one.1).abs() < 1e-9 && one.0 > 0.8 && (one.2 - A as f64).abs() < 1e-9);
    assert!(dbl.iter().all(|d| d.0.abs() < 1e-12 && (d.1 - 1.0).abs() < 1e-12));
    println!("ALL CHECKS PASS");
}
