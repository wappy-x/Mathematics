// Gambler's ruin -- the same check as the Python, in Rust.  No crates.
// A gambler holds 10 chips, bets 1 chip a round, and stops at 0 or at 20.
// Four roads to the chance h of reaching 20 first and the expected number of
// rounds t: the closed forms; the first-step equations solved by elimination;
// the chance mass pushed forward round by round; and a seeded simulation.
const K: usize = 10;
const L: usize = 20;
const SEED: u64 = 20260929;
const GAMES: usize = 20000;

fn formula(k: usize, n: usize, p: f64) -> (f64, f64) {  // the closed forms from Why it works
    let q = 1.0 - p;
    if p == 0.5 {
        return (k as f64 / n as f64, (k * (n - k)) as f64);
    }
    let r = q / p;
    let h = (1.0 - r.powi(k as i32)) / (1.0 - r.powi(n as i32)) + 0.0;
    (h, (k as f64 - n as f64 * h) / (q - p))
}

fn first_step(n: usize, p: f64, rhs: f64, end: f64) -> Vec<f64> {  // q x[i-1] - x[i] + p x[i+1] = -rhs
    let q = 1.0 - p;                                              // for i = 1..n-1, x[0] = 0, x[n] = end
    let (mut c, mut d) = (vec![0.0; n], vec![0.0; n]);            // forward sweep of Thomas elimination
    for i in 1..n {
        let den = -1.0 - q * c[i - 1];
        c[i] = p / den;
        d[i] = (-rhs - q * d[i - 1]) / den;
    }
    let mut x = vec![0.0; n + 1];
    x[n] = end;
    for i in (1..n).rev() {                                       // back substitution
        x[i] = d[i] - c[i] * x[i + 1];
    }
    x
}

fn mass_flow(k: usize, n: usize, p: f64, rounds: usize) -> (f64, f64, f64) {  // move every scrap of chance
    let mut m = vec![0.0; n + 1];
    m[k] = 1.0;
    let (mut top, mut dur) = (0.0, 0.0);
    for _ in 0..rounds {
        dur += m[1..n].iter().sum::<f64>();                       // P(still playing) adds up to E[rounds]
        let mut new = vec![0.0; n + 1];
        for i in 1..n {
            new[i + 1] += p * m[i];
            new[i - 1] += (1.0 - p) * m[i];
        }
        top += new[n];
        new[0] = 0.0;
        new[n] = 0.0;
        m = new;
    }
    (top, dur, m.iter().sum::<f64>())
}

struct SplitMix64 { s: u64 }                                      // the wing's generator, written out
impl SplitMix64 {
    fn uniform(&mut self) -> f64 {
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
}

fn play(g: &mut SplitMix64, k: usize, n: usize, p: f64, path: &mut Vec<usize>) -> (bool, usize) {
    let (mut x, mut t) = (k, 0);                                  // one game; returns (reached n, rounds)
    while x > 0 && x < n {
        if g.uniform() < p { x += 1 } else { x -= 1 }
        t += 1;
        path.push(x);
    }
    (x == n, t)
}

fn simulate(k: usize, n: usize, p: f64) -> (f64, f64, f64, f64) {
    let mut g = SplitMix64 { s: SEED };
    let (mut wins, mut s1, mut s2) = (0usize, 0.0f64, 0.0f64);
    for _ in 0..GAMES {
        let (won, t) = play(&mut g, k, n, p, &mut Vec::new());
        wins += won as usize;
        s1 += t as f64;
        s2 += (t * t) as f64;
    }
    let gm = GAMES as f64;
    let (h, mt) = (wins as f64 / gm, s1 / gm);
    (h, (h * (1.0 - h) / gm).sqrt(), mt, ((s2 / gm - mt * mt) / (gm - 1.0)).sqrt())
}

fn main() {
    println!("game: start {} chips, stop at 0 or {}, stake 1 chip a round", K, L);
    for p in [0.5, 0.49] {
        let (hf, tf) = formula(K, L, p);
        let (hs, ts) = (first_step(L, p, 0.0, 1.0)[K], first_step(L, p, 1.0, 0.0)[K]);
        let (hm, tm, left) = mass_flow(K, L, p, 3000);
        let (hr, seh, tr, set) = simulate(K, L, p);
        println!("p = {:.2}  formula     h = {:.6}  t = {:.4}", p, hf, tf);
        println!("p = {:.2}  first-step  h = {:.6}  t = {:.4}", p, hs, ts);
        println!("p = {:.2}  mass flow   h = {:.6}  t = {:.4}  unresolved after 3000 rounds {:.1e}", p, hm, tm, left);
        println!("p = {:.2}  simulated   h = {:.4} +- {:.4}  t = {:.2} +- {:.2}  ({} games)", p, hr, seh, tr, set, GAMES);
        println!("p = {:.2}  ruin chance 1 - h = {:.6}", p, 1.0 - hf);
        assert!((hf - hs).abs() < 1e-12);                         // closed form against elimination
        assert!((tf - ts).abs() < 1e-9);
        assert!((hf - hm).abs() <= left + 1e-12);                 // closed form against mass flow
        assert!((tf - tm).abs() < 1e-6);
        assert!((hr - hf).abs() < 4.0 * seh);                     // simulation, within 4 standard errors
        assert!((tr - tf).abs() < 4.0 * set);
    }
    let r = 0.51 / 0.49;
    let mut r10 = 1.0;
    for _ in 0..10 { r10 *= r }
    let h49 = 1.0 / (1.0 + r10);
    println!("worked, p = 0.49: r = {:.6}, r^10 = {:.6}, h = 1/(1 + r^10) = {:.6}", r, r10, h49);
    println!("worked, p = 0.49: 20 h = {:.6}, t = (10 - 20 h)/0.02 = {:.4}", 20.0 * h49, (10.0 - 20.0 * h49) / 0.02);
    assert!((h49 - formula(K, L, 0.49).0).abs() < 1e-12);         // the 1/(1 + r^10) shortcut
    for p in [0.5, 0.49] {
        let row: Vec<String> = (0..=L).step_by(2).map(|k| format!("{:.2}", formula(k, L, p).0)).collect();
        println!("figure, h by start k = 0, 2, ..., 20, p = {:.2}: {}", p, row.join(", "));
    }
    let mut path = vec![K];
    let (_, t_end) = play(&mut SplitMix64 { s: SEED }, K, L, 0.5, &mut path);
    let pts: Vec<String> = (0..=t_end).step_by(4).map(|i| path[i].to_string()).collect();
    println!("figure, first simulated fair game, chips every 4 rounds: {}", pts.join(", "));
    println!("figure, that game ends at round {} on {}; lowest {}, highest before the end {}",
             t_end, path[t_end], path.iter().min().unwrap(), path[..t_end].iter().max().unwrap());
    println!("mistake, fair formula k/L used at p = 0.49: {:.4} against {:.4}", K as f64 / L as f64, formula(K, L, 0.49).0);
    println!("mistake, ratio upside down, p/q for q/p: {:.4}", formula(K, L, 0.51).0);
    let (mut g, mut wins) = (SplitMix64 { s: SEED }, 0usize);
    for _ in 0..GAMES {                                           // bold play: stake all 10 chips at once
        wins += (g.uniform() < 0.49) as usize;
    }
    let hb = wins as f64 / GAMES as f64;
    let se_b = (hb * (1.0 - hb) / GAMES as f64).sqrt();
    println!("mistake, stake all 10 chips in one round at p = 0.49: simulated {:.4} +- {:.4}, exact 0.4900", hb, se_b);
    assert!((hb - 0.49).abs() < 4.0 * se_b);
    for n in [20, 30, 40, 80, 160, 1000] {
        let (hf, tf) = formula(K, n, 0.5);
        println!("top wall moved up, fair, target {}: h = {:.4}, t = {:.0}", n, hf, tf);
    }
    let hf = formula(K, 1000, 0.51).0;
    let mut q10 = 1.0;
    for _ in 0..10 { q10 *= 0.49 / 0.51 }
    println!("top wall moved up, p = 0.51: h at target 1000 = {:.4}; limit 1 - (0.49/0.51)^10 = {:.4}", hf, 1.0 - q10);
    assert!((hf - (1.0 - q10)).abs() < 1e-9);
    for (k, n, p, what) in [(100, 200, 0.49, "100 chips to 200 at 0.49"), (K, L, 18.0 / 38.0, "10 chips to 20 on red, 18/38")] {
        let (hf, tf) = formula(k, n, p);
        println!("scale, {}: h = {:.4}, t = {:.2}", what, hf, tf);
    }
    println!("ALL CHECKS PASS");
}
