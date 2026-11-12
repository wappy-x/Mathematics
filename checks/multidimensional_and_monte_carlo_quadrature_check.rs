// Many dimensions: a product grid against random points.  Rust std only.
// Five assets; over a year each grows by a factor 0.8 + 0.4u, u uniform on 0 to 1
// (illustrative).  Wanted: the expected payoff of a $100 basket call,
// 100 * max(average factor - 1, 0), which is an integral over the 5-dimensional cube.

struct SplitMix64 { state: u64 } // the generator, written out, as in wing 09
impl SplitMix64 {
    fn next_u(&mut self) -> f64 {
        self.state = self.state.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.state;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^= z >> 31;
        (z >> 11) as f64 * (2.0f64).powi(-53) // uniform on [0, 1)
    }
}

fn basket(us: &[f64]) -> f64 { // average growth factor, 0.8 to 1.2
    let mut s = 0.0;
    for u in us { s += u; }
    0.8 + 0.4 * s / us.len() as f64
}

fn payoff(us: &[f64]) -> f64 { 100.0 * (basket(us) - 1.0).max(0.0) } // dollars, $100 basket

fn smooth(us: &[f64]) -> f64 { 100.0 * (basket(us) - 1.0).exp() }

fn comb(n: usize, k: usize) -> f64 { (0..k).fold(1.0, |a, i| a * (n - i) as f64 / (i + 1) as f64) }

fn exact(d: usize) -> (f64, f64) { // road 1: the closed form, in floating point
    // E(d/2 - S)+ = sum_k (-1)^k C(d,k) (d/2 - k)+^(d+1) / (d+1)!, and S is symmetric about d/2
    let c = d as f64 / 2.0;
    let mut low = 0.0;
    for k in 0..=d {
        if c > k as f64 {
            let sign = if k % 2 == 0 { 1.0 } else { -1.0 };
            low += sign * comb(d, k) * (c - k as f64).powi(d as i32 + 1);
        }
    }
    let fact: f64 = (1..=d + 1).map(|i| i as f64).product();
    let mean = 40.0 / d as f64 * low / fact;
    let var = (40.0 / d as f64).powi(2) * (d as f64 / 24.0) - mean * mean;
    (mean, var.sqrt())
}

fn grid(d: usize, m: usize, f: fn(&[f64]) -> f64, left: bool) -> f64 { // road 2
    let off = if left { 0.0 } else { 0.5 };
    let xs: Vec<f64> = (0..m).map(|j| (j as f64 + off) / m as f64).collect();
    let mut idx = vec![0usize; d];
    let mut p = vec![0.0; d];
    let mut t = 0.0;
    loop {
        for a in 0..d { p[a] = xs[idx[a]]; }
        t += f(&p);
        let mut a = d; // odometer: the last axis turns fastest
        loop {
            if a == 0 { return t / (m as f64).powi(d as i32); }
            a -= 1;
            idx[a] += 1;
            if idx[a] < m { break; }
            idx[a] = 0;
        }
    }
}

fn monte_carlo(d: usize, n: usize, g: &mut SplitMix64, same: bool) -> (f64, f64) { // road 3
    let (mut t, mut t2) = (0.0, 0.0);
    for _ in 0..n {
        let x = if same {
            let u = g.next_u(); payoff(&vec![u; d]) // wrong: one draw reused for every asset
        } else {
            let us: Vec<f64> = (0..d).map(|_| g.next_u()).collect(); payoff(&us)
        };
        t += x; t2 += x * x;
    }
    let mean = t / n as f64;
    (mean, ((t2 - n as f64 * mean * mean) / (n as f64 - 1.0)).sqrt())
}

fn main() {
    let (i5, sig5) = exact(5);
    println!("exact, d=5      I = {:.6}   sigma = {:.6}", i5, sig5);
    assert!((i5 - 2.081597).abs() < 1e-6 && (sig5 - 3.000048).abs() < 1e-6);
    let t: Vec<f64> = (0..3).map(|k| comb(5, k) * (2.5 - k as f64).powi(6)).collect();
    let low = t[0] - t[1] + t[2];
    println!("hand: {:.6} - {:.6} + {:.6} = {:.6}; /720 = {:.6}; x8 = {:.6}", t[0], t[1], t[2], low, low / 720.0, 8.0 * low / 720.0);
    println!("hand: E[X^2] = 64 x 5/24 = {:.6}; minus I^2 {:.6} = variance {:.6}", 64.0 * 5.0 / 24.0, i5 * i5, 64.0 * 5.0 / 24.0 - i5 * i5);

    println!("grid, d=5:  m   N = m^5   estimate   true error");
    let mut err = [0.0f64; 11];
    for m in 2..=10usize {
        let g = grid(5, m, payoff, false); err[m] = g - i5;
        println!("           {:2} {:9} {:10.6} {:+12.6}", m, m.pow(5), g, err[m]);
    }
    println!("observed order in h (even m):");
    for (a, b) in [(2usize, 4usize), (4, 6), (6, 8), (8, 10)] {
        let p = (err[a] / err[b]).abs().ln() / (b as f64 / a as f64).ln();
        println!("  m {:2} -> {:2}   order {:.4}   per N {:.4}", a, b, p, p / 5.0);
    }
    assert!(((err[8] / err[10]).abs().ln() / (10.0f64 / 8.0).ln() - 2.0).abs() < 0.1); // h^2
    assert!(err[5].abs() > err[4].abs()); // the kink: more points, worse
    assert!(err[10].abs() < 0.01); // grid closes in on road 1

    // the smooth check: f = 100 exp(A - 1) has f_ii <= 100 * 0.08^2 * e^0.2 everywhere
    let j = 100.0 * (-0.2f64).exp() * (((0.08f64).exp() - 1.0) / 0.08).powf(5.0);
    let ej = grid(5, 10, smooth, false) - j;
    let bound = 5.0 * 100.0 * 0.0064 * (0.2f64).exp() * (0.1f64).powf(2.0) / 24.0;
    println!("smooth, m=10: true error {:+.8}  bound {:.8}  ratio {:.4}", ej, bound, bound / -ej);
    assert!(0.0 < -ej && -ej <= bound); // convex f: the midpoint grid reads low

    let mut g = SplitMix64 { state: 2026 };
    let (e5, s5) = monte_carlo(5, 10000, &mut g, false);
    let se = s5 / (10000.0f64).sqrt();
    println!("MC, d=5, N=10000: estimate {:.6}  s {:.6}  SE {:.6}", e5, s5, se);
    println!("  true error {:+.6} = {:+.4} SE;  sigma/sqrt(N) {:.6}", e5 - i5, (e5 - i5) / se, sig5 / 100.0);
    assert!((e5 - i5).abs() < 4.0 * se && (s5 / sig5 - 1.0).abs() < 0.05);

    println!("MC root-mean-square error over 40 runs, d=5:");
    let mut rms = Vec::new();
    for n in [100usize, 1000, 10000] {
        let mut sq = 0.0;
        for _ in 0..40 { let (e, _) = monte_carlo(5, n, &mut g, false); sq += (e - i5) * (e - i5); }
        let r = (sq / 40.0).sqrt();
        let rt = (n as f64).sqrt();
        println!("  N {:6}   rms {:.6}   sigma/sqrt(N) {:.6}   ratio {:.4}", n, r, sig5 / rt, r * rt / sig5);
        assert!((r * rt / sig5 - 1.0).abs() < 0.35);
        rms.push(r);
    }
    println!("  observed order per N, 100 -> 10000: {:.4}", (rms[0] / rms[2]).ln() / (100.0f64).ln());

    let c = err[10].abs() * (100000.0f64).powf(0.4); // grid error about C N^-0.4 (even m)
    println!("crossover estimate, d=5: C {:.4}  MC wins above N = {:.0}", c, (sig5 / c).powf(10.0));
    println!("equal budget, d=5, N=100000: grid error {:+.6}  MC sigma/sqrt(N) {:.6}", err[10], sig5 / (100000.0f64).sqrt());
    assert!(err[10].abs() < sig5 / (100000.0f64).sqrt()); // below the crossover, the grid wins
    println!("cost: d   grid 10 per axis   grid rate 2/d   x to halve grid error   x to halve MC error");
    for d in [1u32, 2, 3, 4, 5, 10, 20] {
        println!("   {:3} {:22} {:9.2} {:14.2} {:12}", d, 10u128.pow(d), 2.0 / d as f64,
                 (2.0f64).powf(d as f64 / 2.0), 4);
    }

    let mut se10 = 0.0;
    for d in [10usize, 20] {
        let (id, sd) = exact(d);
        let (est, s) = monte_carlo(d, 10000, &mut g, false);
        println!("d={}: I {:.6} sigma {:.6}  MC {:.6} SE {:.6} err {:+.6}", d, id, sd, est, s / 100.0, est - id);
        assert!((est - id).abs() < 4.0 * s / 100.0);
        if d == 10 { se10 = s / 100.0; }
    }
    let i10 = exact(10).0;
    let mut last = 0.0;
    for m in [2usize, 3] {
        let gr = grid(10, m, payoff, false);
        println!("grid d=10, m={}: N {:6}  estimate {:.6}  true error {:+.6}", m, m.pow(10), gr, gr - i10);
        last = gr;
    }
    println!("  m=3 grid error / MC SE at d=10: {:.2}", (last - i10).abs() / se10);

    println!("what breaks, d=5:");
    let gl = grid(5, 10, payoff, true);
    println!("  left-corner grid, m=10      {:.6}  error {:+.6}", gl, gl - i5);
    let (bad, sb) = monte_carlo(5, 10000, &mut SplitMix64 { state: 2026 }, true);
    let aim = 100.0 * 0.2 * 0.5 / 2.0; // what that averages: 100 max(0.4u - 0.2, 0) on 0 to 1, a triangle
    println!("  one draw for all 5 assets   {:.6}  error {:+.6}  aims at {:.6}", bad, bad - i5, aim);
    println!("  error bar s/N, not s/sqrt(N) {:.6}  true error is {:.1} of them", s5 / 10000.0, (e5 - i5).abs() / (s5 / 10000.0));
    assert!((bad - aim).abs() < 4.0 * sb / 100.0); // it estimates that 1-D integral, not the basket
    println!("ALL CHECKS PASS");
}
