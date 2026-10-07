// The layer-cake formula -- the same check as the Python, in Rust.  No crates.
// A dart lands uniformly on a 1 m by 1 m board; M = max(x, y) is its larger
// coordinate, with tail P(M > t) = 1 - t^2.  Exact fractions are pairs of i128
// kept in lowest terms by hand; the float roads repeat the Python's steps.
type Q = (i128, i128);

fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i128, d: i128) -> Q { let g = gcd(n, d) * d.signum(); (n / g, d / g) }
fn add(a: Q, b: Q) -> Q { q(a.0 * b.1 + b.0 * a.1, a.1 * b.1) }
fn sub(a: Q, b: Q) -> Q { add(a, (-b.0, b.1)) }
fn mul(a: Q, b: Q) -> Q { q(a.0 * b.0, a.1 * b.1) }
fn div(a: Q, b: Q) -> Q { q(a.0 * b.1, a.1 * b.0) }
fn pw(a: Q, k: u32) -> Q { q(a.0.pow(k), a.1.pow(k)) }
fn show(a: Q) -> String { if a.1 == 1 { format!("{}", a.0) } else { format!("{}/{}", a.0, a.1) } }
fn fl(a: Q) -> f64 { a.0 as f64 / a.1 as f64 }

fn integral(p: &[Q], a: Q, b: Q) -> Q {             // exact integral over [a, b], lowest power first
    p.iter().enumerate().fold((0, 1), |s, (m, &c)| {
        let k = m as u32 + 1;
        add(s, div(mul(c, sub(pw(b, k), pw(a, k))), (k as i128, 1)))
    })
}
fn pmul(p: &[Q], r: &[Q]) -> Vec<Q> {               // multiply two polynomials
    let mut out = vec![(0, 1); p.len() + r.len() - 1];
    for (i, &a) in p.iter().enumerate() {
        for (j, &b) in r.iter().enumerate() { out[i + j] = add(out[i + j], mul(a, b)); }
    }
    out
}
fn mono(c: i128, k: usize) -> Vec<Q> { let mut v = vec![(0, 1); k]; v.push((c, 1)); v }

struct Rng(u64);                                    // SplitMix64
impl Rng {
    fn uniform(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = (self.0 ^ (self.0 >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
}
fn midpoint(f: &dyn Fn(f64) -> f64, a: f64, b: f64, steps: usize) -> f64 {
    let h = (b - a) / steps as f64;
    h * (0..steps).fold(0.0, |s, k| s + f(a + (k as f64 + 0.5) * h))
}
fn join(v: &[f64], d: usize) -> String { v.iter().map(|x| format!("{:.*}", d, x)).collect::<Vec<_>>().join(", ") }

fn main() {
    let (zero, one, half) = ((0, 1), (1, 1), (1, 2));
    let tail: Vec<Q> = vec![(1, 1), (0, 1), (-1, 1)];  // P(M > t) = 1 - t^2 on [0, 1]
    // road 1, the tail: E[M^p] = integral of p t^(p-1) P(M > t) dt
    let tail_road: Vec<Q> = (1..4).map(|p| integral(&pmul(&mono(p as i128, p - 1), &tail), zero, one)).collect();
    // road 2, the board: where y < x the max is x, the strip under it has length x, twice
    let board_road: Vec<Q> = (1..4).map(|p| mul((2, 1), integral(&pmul(&mono(1, p), &[(0, 1), (1, 1)]), zero, one))).collect();
    println!("moment | tail integral | on the board | decimal");
    for p in 0..3 {
        println!("E[M^{}] | {} | {} | {:.4}", p + 1, show(tail_road[p]), show(board_road[p]), fl(tail_road[p]));
    }
    let var = sub(tail_road[1], mul(tail_road[0], tail_road[0]));
    println!("variance E[M^2] - E[M]^2 = {} - {} = {} = {:.4} m^2, sd {:.4} m", show(tail_road[1]), show(mul(tail_road[0], tail_road[0])),
             show(var), fl(var), fl(var).sqrt());
    let tail_k = integral(&tail, half, one);
    let board_k = mul((2, 1), integral(&pmul(&[(-1, 2), (1, 1)], &[(0, 1), (1, 1)]), half, one));
    println!("shifted, E[(M - 0.5)^+]: tail from 0.5 = {}, on the board = {} = {:.4}", show(tail_k), show(board_k), fl(tail_k));
    let markov = mul(half, tail.iter().enumerate().fold(zero, |s, (m, &c)| add(s, mul(c, pw(half, m as u32)))));  // rectangle t P(M > t)
    println!("markov, rectangle 0.5 x P(M > 0.5) = {} = {:.4} <= E[M] = {:.4}", show(markov), fl(markov), fl(tail_road[0]));

    println!("grid n | direct average | layer-cake sum | (n+1)(4n-1)/(6n^2) | excess over 2/3 | bound 1/(2n)");
    let mut grid: Vec<(i128, Q, Q, Q)> = Vec::new();
    for n in [2i128, 4, 10, 100] {                  // the dart's coordinates rounded up to multiples of 1/n
        let pts: Vec<(i128, i128)> = (1..=n).flat_map(|i| (1..=n).map(move |j| (i, j))).collect();
        let direct = div(pts.iter().fold(zero, |s, &(i, j)| add(s, (i.max(j), n))), (n * n, 1));
        let layer = div((0..n).fold(zero, |s, k| {
            add(s, (pts.iter().filter(|&&(i, j)| i.max(j) > k).count() as i128, n * n))
        }), (n, 1));
        let closed = q((n + 1) * (4 * n - 1), 6 * n * n);
        grid.push((n, direct, layer, closed));
        println!("n = {:3} | {} | {} | {} | {:.6} | {:.6}", n, show(direct), show(layer), show(closed),
                 fl(sub(direct, (2, 3))), 1.0 / (2.0 * n as f64));
    }
    let pts4: Vec<(i128, i128)> = (1..=4).flat_map(|i| (1..=4).map(move |j| (i, j))).collect();
    let sq_direct = div(pts4.iter().fold(zero, |s, &(i, j)| add(s, (i.max(j).pow(2), 16))), (16, 1));
    let sq_layer = (0..4).fold(zero, |s, k| {
        add(s, mul((pts4.iter().filter(|&&(i, j)| i.max(j) > k).count() as i128, 16), (2 * k + 1, 16)))
    });
    let count = |test: &dyn Fn(i128) -> bool| pts4.iter().filter(|&&(i, j)| test(i.max(j))).count().to_string();
    println!("grid n = 4, points with max 1/4, 2/4, 3/4, 1: {}; points with max > 0, 1/4, 2/4, 3/4: {}",
             (1..5).map(|k| count(&|m| m == k)).collect::<Vec<_>>().join(", "), (0..4).map(|k| count(&|m| m > k)).collect::<Vec<_>>().join(", "));
    println!("grid n = 4, E[M^2]: direct {}, layer-cake with weight 2t {}", show(sq_direct), show(sq_layer));

    let ts: Vec<f64> = (0..11).map(|k| k as f64 / 10.0).collect();
    println!("chart, t = {}", join(&ts, 1));
    println!("chart, tail 1 - t^2 = {}", join(&ts.iter().map(|t| 1.0 - t * t).collect::<Vec<_>>(), 2));
    println!("chart, weighted 2t(1 - t^2) = {}", join(&ts.iter().map(|t| 2.0 * t * (1.0 - t * t)).collect::<Vec<_>>(), 2));

    let (mut rng, n_darts) = (Rng(2026), 100000);   // SplitMix64, seed 2026, two draws per dart
    let mut s = [0.0f64; 6];                        // sums of M, M^2, [M > 0.5], (M - 0.5)^+, x - y, (x - y)^+
    for _ in 0..n_darts {
        let x = rng.uniform();
        let y = rng.uniform();
        let m = x.max(y);
        let vals = [m, m * m, if m > 0.5 { 1.0 } else { 0.0 }, (m - 0.5).max(0.0), x - y, (x - y).max(0.0)];
        for i in 0..6 { s[i] += vals[i]; }
    }
    let sim: Vec<f64> = s.iter().map(|v| v / n_darts as f64).collect();
    let se: Vec<f64> = [1.0 / 18.0, 1.0 / 12.0, 3.0 / 16.0, 1.0 / 18.0].iter().map(|v| (v / n_darts as f64).sqrt()).collect();
    println!("simulation, {} darts: E[M] {:.4}, E[M^2] {:.4}, P(M > 0.5) {:.4}, E[(M - 0.5)^+] {:.4}; standard errors {:.4}, {:.4}, {:.4}",
             n_darts, sim[0], sim[1], sim[2], sim[3], se[0], se[1], se[2]);
    println!("simulation, signed D = x - y: E[D] {:.4}, E[D^+] {:.4}, standard error {:.4}", sim[4], sim[5], se[3]);

    let d_tail: Vec<Q> = vec![half, (-1, 1), half]; // P(D > t) = (1 - t)^2 / 2, and P(D < -t) is the same
    let (pos, neg) = (integral(&d_tail, zero, one), integral(&d_tail, zero, one));
    println!("break, signed D = x - y: positive tail alone {}, true E[D] = {} (positive tail {} minus negative tail {})",
             show(pos), show(sub(pos, neg)), show(pos), show(neg));
    println!("break, E[M^2] without the weight 2t: integral of the tail {}, integral of t times the tail {}; true {}",
             show(integral(&tail, zero, one)), show(integral(&pmul(&mono(1, 1), &tail), zero, one)), show(tail_road[1]));
    println!("break, integrating P(M <= t) instead of the tail: {}, not {}", show(integral(&mono(1, 2), zero, one)), show(tail_road[0]));

    println!("heavy tail Y = 1/x, cut at T | tail integral to T | E[min(Y, T)] on the board | 1 + ln T");
    let mut heavy: Vec<(f64, f64, f64)> = Vec::new();
    for big_t in [10.0f64, 100.0, 1000.0] {
        let by_tail = midpoint(&|t: f64| (1.0f64).min(1.0 / t), 0.0, big_t, 200000);
        let on_board = midpoint(&|u: f64| (1.0 / u).min(big_t), 0.0, 1.0, 200000);
        heavy.push((by_tail, on_board, 1.0 + big_t.ln()));
        println!("T = {:6.0} | {:.4} | {:.4} | {:.4}", big_t, by_tail, on_board, 1.0 + big_t.ln());
    }
    println!("figure, x = 40 + 160 u, y = 180 - 160 v; board (40, 20) to (200, 180); inner square to ({:.0}, {:.0}), area {:.2}; \
              shaded L area {:.2}; dart (0.3, 0.8) at ({:.0}, {:.0}), max 0.8",
             40.0 + 160.0 * 0.5, 180.0 - 160.0 * 0.5, 0.5 * 0.5, 1.0 - 0.5 * 0.5, 40.0 + 160.0 * 0.3, 180.0 - 160.0 * 0.8);

    assert!(tail_road == board_road);                               // tail road against the board, three moments
    assert!(tail_road[0] == (2, 3) && tail_road[1] == (1, 2));
    assert!(tail_k == board_k && board_k == (5, 24));               // shifted tail against a direct payoff
    assert!(grid.iter().all(|&(_, d, l, c)| d == l && l == c));     // exact finite layer cake, three ways
    assert!(grid.iter().all(|&(n, d, _, _)| { let e = sub(d, (2, 3)); e.0 > 0 && e.0 * 2 * n <= e.1 }));
    assert!(sq_direct == sq_layer && sq_layer == (85, 128));
    assert!((sim[0] - 2.0 / 3.0).abs() < 4.0 * se[0] && (sim[1] - 0.5).abs() < 4.0 * se[1]);
    assert!((sim[2] - 0.75).abs() < 4.0 * se[2] && (sim[3] - 5.0 / 24.0).abs() < 0.002);
    assert!((fl(markov) - 0.5 * sim[2]).abs() < 2.0 * se[2]);      // Markov rectangle against 0.5 x simulated P(M > 0.5)
    assert!((sim[5] - fl(pos)).abs() < 4.0 * se[3] && (sim[4] - fl(sub(pos, neg))).abs() < 4.0 * (1.0 / (6.0 * n_darts as f64)).sqrt());
    assert!(heavy.iter().all(|&(a, b, c)| (a - b).abs() < 1e-4 && (a - c).abs() < 1e-4));
    println!("ALL CHECKS PASS");
}
