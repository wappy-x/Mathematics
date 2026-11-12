// Monte Carlo integration in many dimensions -- the check behind the card.
// No crates.  The volume of a 10-dimensional ball of radius 1, reached four
// ways: the closed form, slicing (a chain of 1-D integrals), a grid of cell
// centres counted exactly, and seeded darts.  Output matches the Python check.
use std::collections::BTreeMap;
use std::f64::consts::PI;
const D: usize = 10; const N: u64 = 100000; const SEED: u64 = 2026;

struct Rng(u64);
impl Rng {
    fn u(&mut self) -> f64 {                  // one uniform number in [0, 1), SplitMix64
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
    fn darts(&mut self, d: usize, n: u64) -> u64 { // how many of n darts in [-1, 1]^d land in the ball
        let mut hits = 0;
        for _ in 0..n {
            let mut r2 = 0.0;
            for _ in 0..d {
                let x = 2.0 * self.u() - 1.0;
                r2 += x * x;
            }
            if r2 <= 1.0 { hits += 1; }
        }
        hits
    }
}

fn exact(d: usize) -> f64 {                   // V_d = pi^(d/2) / (d/2)!, by V_d = V_(d-2) 2 pi / d
    let (mut v, mut k) = if d % 2 == 0 { (1.0, 2) } else { (2.0, 3) };
    while k <= d {
        v *= 2.0 * PI / k as f64;
        k += 2;
    }
    v
}

fn sliced(d: usize, slices: usize) -> f64 {  // V_k = V_(k-1) x integral of cos^k over (-pi/2, pi/2)
    let (mut v, h) = (1.0, PI / slices as f64);
    for k in 1..=d {
        let mut w = 0.0;
        for i in 0..=slices {
            let wt = if i == 0 || i == slices { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 };
            w += wt * (-PI / 2.0 + i as f64 * h).cos().powi(k as i32);
        }
        v *= w * h / 3.0;
    }
    v
}

fn grid_walk(m: i64, d: usize, left: i64, depth: usize) -> u64 { // road A: visit points, prune outside
    if depth == d { return 1; }
    let mut total = 0;
    let mut c = 1 - m;
    while c < m {
        if c * c <= left { total += grid_walk(m, d, left - c * c, depth + 1); }
        c += 2;
    }
    total
}

fn grid_sums(m: i64, d: usize) -> u64 {       // road B: count by the sum of squares, coordinate by coordinate
    let mut ways: BTreeMap<i64, u64> = BTreeMap::new();
    ways.insert(0, 1);
    for _ in 0..d {
        let mut nxt = BTreeMap::new();
        for (&s, &w) in &ways {
            let mut c = 1 - m;
            while c < m {
                if s + c * c <= m * m { *nxt.entry(s + c * c).or_insert(0) += w; }
                c += 2;
            }
        }
        ways = nxt;
    }
    ways.values().sum()
}

fn mid(m: usize) -> f64 {                     // 1-D midpoint rule for e^x / (e - 1) on [0, 1]; true value 1
    let s: f64 = (0..m).map(|j| ((j as f64 + 0.5) / m as f64).exp()).sum();
    s / m as f64 / (1f64.exp() - 1.0)
}

fn main() {
    let mut rng = Rng(SEED);
    let (v, cube) = (exact(D), 2f64.powi(D as i32));
    let p = v / cube;
    let sigma = cube * (p * (1.0 - p)).sqrt();
    let nf = N as f64;
    println!("exact: V_10 = pi^5 / 120 = {:.6}; cube [-1, 1]^10 has volume {:.0}; fraction inside p = {:.8}, about 1 in {:.0}", v, cube, p, 1.0 / p);
    println!("slicing road, Simpson on cos^k with 2000 slices per step: {:.6}", sliced(D, 2000));
    println!("one dart's score: {:.0} inside, 0 outside; sigma = 1024 sqrt(p(1 - p)) = {:.4}", cube, sigma);

    let k = rng.darts(D, N);
    let f = k as f64 / nf;
    let est = cube * f;
    let s = cube * (f * (1.0 - f) * nf / (nf - 1.0)).sqrt();
    let se = s / nf.sqrt();
    println!("darts: {} in [-1, 1]^10, seed {}: {} inside; expected {:.1}", N, SEED, k, nf * p);
    println!("  estimate 1024 x {} / {} = {:.4}; standard error {:.4} (true {:.4}); s {:.4}", k, N, est, se, sigma / nf.sqrt(), s);
    println!("  95% interval {:.4} to {:.4}; miss {:+.4} = {:+.2} standard errors", est - 1.96 * se, est + 1.96 * se, est - v, (est - v) / se);
    println!("  relative standard error {:.4}", sigma / nf.sqrt() / v);

    println!("grid of cell centres, m per axis: points, inside (walk), inside (by sums), estimate, miss");
    let mut grid = [0.0f64; 7];
    for m in 2..=6i64 {
        let walk: i64 = if m <= 5 { grid_walk(m, D, m * m, 0) as i64 } else { -1 };
        let by_sum = grid_sums(m, D);
        let pts = (m as u64).pow(D as u32);
        grid[m as usize] = cube * by_sum as f64 / pts as f64;
        if m <= 5 { assert_eq!(walk as u64, by_sum); } // two counting roads agree
        println!("  m = {}: {:>9} {:>7} {:>7} {:.4} {:+.4}", m, pts, walk, by_sum, grid[m as usize], grid[m as usize] - v);
    }
    let dart_se_3 = sigma / (3f64.powi(D as i32)).sqrt();
    println!("darts at the 3-per-axis budget of {}: standard error {:.4}", 3u64.pow(D as u32), dart_se_3);
    println!("6 per axis: {:.0} times the darts' points, {:.2} times the darts' miss", 6f64.powi(D as i32) / nf, (grid[6] - v).abs() / (est - v).abs());

    println!("error rate exponents: error falls like N^-rate; d, midpoint 2/d, Simpson 4/d, Monte Carlo 1/2");
    for d in 1..=12 {
        println!("  {:>2} {:.2} {:.2} 0.50", d, 2.0 / d as f64, 4.0 / d as f64);
    }
    println!("crossover: midpoint loses past d = {:.0}, Simpson past d = {:.0}; a jump edge gives 1/d = {:.2} in 10-D", 2.0 / 0.5, 4.0 / 0.5, 1.0 / D as f64);
    println!("points per axis for {} grid points in 10-D: {:.4}", N, nf.powf(1.0 / D as f64));
    println!("cost of one more decimal place in 10-D: darts x{}, Simpson x{:.0}, midpoint x{}", 10u64.pow(2), 10f64.powf(2.5), 10u64.pow(5));

    let e: Vec<f64> = [3, 6, 12].iter().map(|&m| (mid(m).powi(D as i32) - 1.0).abs()).collect();
    let rate = (e[0] / e[1]).ln() / 2f64.powi(D as i32).ln();
    println!("smooth test, e^(x1 + ... + x10) / (e - 1)^10 on [0, 1]^10, true integral 1, midpoint grid:");
    println!("  3 per axis ({} points) miss {:.5}; 6 per axis ({}) miss {:.5}; 12 per axis miss {:.6}", 3u64.pow(D as u32), e[0], 6u64.pow(D as u32), e[1], e[2]);
    println!("  1024 times the points cut the miss {:.2} times; measured rate {:.3}, theory 0.200; darts: {:.2} times", e[0] / e[1], rate, 2f64.powi(D as i32).sqrt());

    println!("same N = 1000 darts, 200 runs each: d, sigma / root N, observed root-mean-square miss");
    let mut ratios = Vec::new();
    for &d in &[2usize, 5, 10] {
        let (vd, cd) = (exact(d), 2f64.powi(d as i32));
        let pd = vd / cd;
        let mut sq = 0.0;
        for _ in 0..200 {
            let x = cd * rng.darts(d, 1000) as f64 / 1000.0 - vd;
            sq += x * x;
        }
        let (r, th) = ((sq / 200.0).sqrt(), cd * (pd * (1.0 - pd) / 1000.0).sqrt());
        ratios.push(r / th);
        println!("  {:>2} {:.4} {:.4}  (ratio {:.3}; relative to the volume {:.3})", d, th, r, r / th, th / vd);
    }

    let v20 = exact(20);
    let k20 = rng.darts(20, N);
    let c20 = 2f64.powi(20);
    println!("what breaks, the right answer is {:.4} +/- {:.4}", v, se);
    println!("  20-D ball: true {:.6}, fraction of cube {:.10}; {} darts hit {}, estimate {:.4}", v20, v20 / c20, N, k20, c20 * k20 as f64 / nf);
    println!("  darts for one expected hit in 20-D: {:.0}", c20 / v20);
    println!("  grid of 1,048,576 points (4 per axis): {:.4}, its 1024 inside points all sit at distance {:.4}, the next shell at {:.4} is all outside",
             grid[4], (D as f64).sqrt() / 4.0, ((9 + D - 1) as f64 / 16.0).sqrt());
    println!("  forgetting the cube's volume: {:.6}", f);
    println!("  error bar s / N instead of s / root N: +/- {:.6}, {:.0} times too narrow", s / nf, nf.sqrt());
    println!("try: 400000 darts, standard error {:.4}; 10,000,000 darts {:.4}", sigma / (4.0 * nf).sqrt(), sigma / (100.0 * nf).sqrt());

    assert!((sliced(D, 2000) - v).abs() < 1e-9);          // slicing agrees with the closed form
    assert!((est - v).abs() < 3.0 * sigma / nf.sqrt());    // darts land within 3 standard errors
    assert_eq!(grid_walk(3, D, 9, 0), 1 + 20 + 180);       // 0, 1 or 2 coordinates off-centre fit
    assert!(ratios.iter().all(|r| (r - 1.0).abs() < 0.2)); // sigma / root N in every dimension
    assert!((rate - 0.2).abs() < 0.01);                    // grid error falls like N^(-2/d)
    assert!((grid[3] - v).abs() > 4.0 * dart_se_3);        // the grid misses by more than 4 dart errors
    assert_eq!(k20, 0);
    println!("ALL CHECKS PASS");
}
