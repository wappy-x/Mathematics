// Bounded variation -- the check behind the card.  Rust std only.
// A 12 km trail, its total variation found three ways, its Jordan split,
// a trail with a ladder (a jump), and three oscillating functions near zero.
use std::f64::consts::PI;

const TURNS: [(f64, f64); 5] = [(0.0, 1000.0), (4.0, 1600.0), (6.0, 1300.0), (10.0, 1600.0), (12.0, 1200.0)];

fn trail(x: f64) -> f64 {
    // elevation, straight lines between turning points
    for w in TURNS.windows(2) {
        let ((x0, y0), (x1, y1)) = (w[0], w[1]);
        if x <= x1 {
            return y0 + (y1 - y0) * (x - x0) / (x1 - x0);
        }
    }
    TURNS[4].1
}

fn ladder(x: f64) -> f64 {
    // the same trail with a 50 m ladder at km 8
    trail(x) + if x >= 8.0 { 50.0 } else { 0.0 }
}

fn partition_sum(f: &dyn Fn(f64) -> f64, pts: &[f64], g: &dyn Fn(f64) -> f64) -> f64 {
    pts.windows(2).map(|w| g(f(w[1]) - f(w[0]))).fold(0.0, |a, b| a + b)
}

fn best_on_grid(f: &dyn Fn(f64) -> f64, end: f64, g: &dyn Fn(f64) -> f64) -> f64 {
    // Road 2: the definition, best partition on a 0.25 km grid, by dynamic programming
    let step = 0.25;
    let grid: Vec<f64> = (0..=(end / step) as usize).map(|i| i as f64 * step).collect();
    let mut best = vec![0.0f64; grid.len()];
    for j in 1..grid.len() {
        best[j] = (0..j).map(|i| best[i] + g(f(grid[j]) - f(grid[i]))).fold(f64::MIN, f64::max);
    }
    best[grid.len() - 1]
}

struct SplitMix64(u64);
impl SplitMix64 {
    fn next(&mut self) -> u64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    }
    fn unit(&mut self) -> f64 { (self.next() >> 11) as f64 * 2f64.powi(-53) }
}

fn xk(k: usize) -> f64 { 2.0 / ((2 * k + 1) as f64 * PI) }

fn main() {
    let abs = |d: f64| d.abs();
    let up = |d: f64| d.max(0.0);
    let down = |d: f64| (-d).max(0.0);
    // Road 1: piecewise monotone, so add the rises and falls between turning points.
    let v_turns: f64 = TURNS.windows(2).map(|w| (w[1].1 - w[0].1).abs()).sum();
    let v_grid = best_on_grid(&trail, 12.0, &abs);
    // Road 3: 20,000 random partitions with points anywhere; none may beat the turning-point sum.
    let (mut rng, mut v_rand, mut beaten) = (SplitMix64(2026), 0.0f64, 0);
    for _ in 0..20000 {
        let m = 1 + rng.next() % 30;
        let mut inner: Vec<f64> = (0..m).map(|_| 12.0 * rng.unit()).collect();
        inner.sort_by(|a, b| a.partial_cmp(b).unwrap());
        let mut pts = vec![0.0];
        pts.extend(inner);
        pts.push(12.0);
        let s = partition_sum(&trail, &pts, &abs);
        v_rand = v_rand.max(s);
        if s > v_turns + 1e-9 { beaten += 1; }
    }
    println!("variation, turning points     {:10.2}", v_turns);
    println!("variation, best grid partition{:10.2}", v_grid);
    println!("variation, best of 20000 random{:9.2}   beat it: {}", v_rand, beaten);
    println!("net change f(12) - f(0)       {:10.2}", trail(12.0) - trail(0.0));
    println!("Lipschitz ceiling 200 x 12    {:10.2}", 200.0 * 12.0);
    assert!((v_grid - v_turns).abs() < 1e-9, "definition and turning points disagree");
    assert!(beaten == 0 && v_rand > 0.97 * v_turns, "a random partition beat the sup");

    println!("equal pieces n : sum collected");
    for n in [1usize, 2, 3, 4, 5, 6, 12] {
        let pts: Vec<f64> = (0..=n).map(|i| (12 * i) as f64 / n as f64).collect();
        println!("  n = {:2}        {:10.2}", n, partition_sum(&trail, &pts, &abs));
    }

    println!("km  elevation  climb P  descent N  P - N  P + N");
    for km in 0..=12 {
        let x = km as f64;
        let (p, n, v) = (best_on_grid(&trail, x, &up), best_on_grid(&trail, x, &down), best_on_grid(&trail, x, &abs));
        println!("{:2} {:10.2} {:8.2} {:10.2} {:6.2} {:7.2}", km, trail(x), p, n, p - n, p + n);
        assert!(((p - n) - (trail(x) - trail(0.0))).abs() < 1e-9, "Jordan: P - N is not the net change");
        assert!(((p + n) - v).abs() < 1e-9, "Jordan: P + N is not the variation");
    }

    let v_lad = best_on_grid(&ladder, 12.0, &abs);
    println!("ladder: variation {:.2}, climb {:.2}", v_lad, best_on_grid(&ladder, 12.0, &up));
    assert!((v_lad - (v_turns + 50.0)).abs() < 1e-9, "the ladder should add exactly its height");
    for k in [1, 2, 3, 6] {
        let e = 10f64.powi(-k);
        println!("ladder: f(8 - 1e-{}) = {:9.4}   f(8 + 1e-{}) = {:9.4}", k, ladder(8.0 - e), k, ladder(8.0 + e));
    }

    // Oscillation near zero on [0, 2/pi]: peaks of sin(1/x) at x_k = 2 / ((2k + 1) pi).
    let peaks = |n: usize, with_zero: bool| -> Vec<f64> {
        let mut v = if with_zero { vec![0.0] } else { vec![] };
        v.extend((0..=n).rev().map(xk));
        v
    };
    let wild = |x: f64| if x == 0.0 { 0.0 } else { x * (1.0 / x).sin() };
    let damp = |x: f64| if x == 0.0 { 0.0 } else { x * x * (1.0 / x).sin() };
    println!("peaks n   x sin(1/x)   x^2 sin(1/x)");
    let ns = [1usize, 10, 100, 1000, 10000, 100000];
    let s: Vec<f64> = ns.iter().map(|&n| partition_sum(&wild, &peaks(n, true), &abs)).collect();
    let d: Vec<f64> = ns.iter().map(|&n| partition_sum(&damp, &peaks(n, true), &abs)).collect();
    for i in 0..ns.len() {
        println!("{:7} {:12.4} {:14.4}", ns[i], s[i], d[i]);
    }
    let two = |v: &[f64]| v.iter().map(|x| format!("{:.2}", x)).collect::<Vec<_>>().join(" ");
    println!("chart, x sin(1/x):   {}", two(&s));
    println!("chart, x^2 sin(1/x): {}", two(&d));
    let closed = xk(0) + 2.0 * (1..=1000).map(xk).fold(0.0, |a, b| a + b);
    println!("x sin(1/x), n = 1000 by the formula x_0 + 2 sum x_k  {:.4}", closed);
    let gain = s[5] - s[4];
    println!("x sin(1/x), gain per tenfold n {:.4}   (2/pi) ln 10 = {:.4}", gain, 2.0 / PI * 10f64.ln());
    println!("x^2 sin(1/x): limit 1 - 4/pi^2 = {:.4}   Lipschitz ceiling {:.4}", 1.0 - 4.0 / (PI * PI), (1.0 + 4.0 / PI) * 2.0 / PI);
    assert!((s[3] - closed).abs() < 1e-9, "direct sum and formula disagree");
    assert!((gain - 2.0 / PI * 10f64.ln()).abs() < 1e-3, "growth is not logarithmic");
    assert!((d[5] - (1.0 - 4.0 / (PI * PI))).abs() < 1e-5, "damped sums miss their limit");

    let swing = |x: f64| (1.0 / x).sin();
    for n in [10usize, 100] {
        let got = partition_sum(&swing, &peaks(n, false), &abs); // peaks only: no value at 0
        println!("sin(1/x): {} swings collect {:.2}", n, got);
        assert!((got - 2.0 * n as f64).abs() < 1e-9, "each swing from +1 to -1 should add 2");
    }
    println!("All checks passed.");
}
