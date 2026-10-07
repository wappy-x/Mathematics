// Jensen's inequality on a measure space -- the same check as the Python, in
// Rust.  No crates.  Exact fractions are written out by hand on i128.  The
// space: seven days, wind speeds (3, 5, 8, 2, 6, 4, 7) m/s.  Under P each day
// weighs 1/7; under counting measure each weighs 1.
use std::fmt;
use std::ops::{Add, Mul, Sub};

const SPEEDS: [i128; 7] = [3, 5, 8, 2, 6, 4, 7];

#[derive(Clone, Copy, PartialEq)]
struct Q { n: i128, d: i128 }            // n / d with d > 0, in lowest terms
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i128, d: i128) -> Q { let g = gcd(n, d); Q { n: n / g, d: d / g } }
impl Add for Q { type Output = Q; fn add(self, o: Q) -> Q { q(self.n * o.d + o.n * self.d, self.d * o.d) } }
impl Sub for Q { type Output = Q; fn sub(self, o: Q) -> Q { q(self.n * o.d - o.n * self.d, self.d * o.d) } }
impl Mul for Q { type Output = Q; fn mul(self, o: Q) -> Q { q(self.n * o.n, self.d * o.d) } }
impl PartialOrd for Q {                  // compare by cross-multiplying
    fn partial_cmp(&self, o: &Q) -> Option<std::cmp::Ordering> { (self.n * o.d).partial_cmp(&(o.n * self.d)) }
}
impl fmt::Display for Q {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        if self.d == 1 { write!(f, "{}", self.n) } else { write!(f, "{}/{}", self.n, self.d) }
    }
}
impl Q { fn pow(self, k: u32) -> Q { q(self.n.pow(k), self.d.pow(k)) } fn fl(self) -> f64 { self.n as f64 / self.d as f64 } }

fn integral(g: &dyn Fn(i128) -> Q, w: Q) -> Q {  // a simple function: value times weight
    SPEEDS.iter().fold(q(0, 1), |acc, &x| acc + g(x) * w)
}
fn norm(p: u32, w: Q) -> f64 { integral(&|x| q(x, 1).pow(p), w).fl().powf(1.0 / p as f64) }

fn splitmix(state: &mut u64) -> u64 {
    *state = state.wrapping_add(0x9E3779B97F4A7C15);
    let mut z = *state;
    z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    z ^ (z >> 31)
}

fn main() {
    let (p, count) = (q(1, 7), q(1, 1));  // the uniform probability; counting measure
    // ---- road 1: both sides of Jensen, summed exactly ----
    let m = integral(&|x| q(x, 1), p);
    println!("speeds in m/s: {:?}; weight under P {} each, under counting measure {}", SPEEDS, p, count);
    let mean_cube = integral(&|x| q(x * x * x, 1), p);
    let mean_square = integral(&|x| q(x * x, 1), p);
    println!("mean speed E[f] = {}; cube of the mean = {}; mean cube E[f^3] = {}", m, m.pow(3), mean_cube);
    println!("ratio mean cube / cube of mean = {:.4}", mean_cube.fl() / m.pow(3).fl());
    let rho = 1.225;                      // air density, kg per cubic metre
    println!("power per square metre, 0.5 rho v^3 with rho = {}: steady {:.2} W, actual average {:.2} W",
             rho, 0.5 * rho * m.pow(3).fl(), 0.5 * rho * mean_cube.fl());

    // ---- road 2: the supporting line at the mean, never cubing a day's speed ----
    let slope = q(3, 1) * m * m;          // derivative of x^3 at m
    let gaps: Vec<Q> = SPEEDS.iter().map(|&x| (q(x, 1) - m).pow(2) * (q(x, 1) + q(2, 1) * m)).collect();
    println!("tangent at the mean: line(x) = {} + {}(x - {})", m.pow(3), slope, m);
    let shown: Vec<String> = gaps.iter().map(|g| g.to_string()).collect();
    println!("gap cube minus line, day by day: [{}]", shown.join(", "));
    let cubes: Vec<String> = (2i128..=8).map(|x| (x * x * x).to_string()).collect();
    let line: Vec<String> = (2i128..=8).map(|x| (m.pow(3) + slope * (q(x, 1) - m)).to_string()).collect();
    println!("figure, cube at speeds 2 to 8: {}", cubes.join(", "));
    println!("figure, line at speeds 2 to 8: {}", line.join(", "));
    let line_avg = integral(&|x| m.pow(3) + slope * (q(x, 1) - m), p); // the line itself, integrated against P
    let gap_avg = gaps.iter().fold(q(0, 1), |a, &g| a + g * p);
    println!("average of the line = {}; average gap = {}; line + gap = {}", line_avg, gap_avg, line_avg + gap_avg);
    assert!(line_avg + gap_avg == mean_cube);                   // two roads to 185
    assert!(gaps.iter().all(|&g| g >= q(0, 1)) && gap_avg > q(0, 1));
    assert!(line_avg == m.pow(3));                              // P(Omega) = 1: the line averages to its value at m

    // ---- road 3: sampling days from P with SplitMix64, seed 20260929 ----
    const SEED: u64 = 20260929;
    let (n, mut total, mut state) = (70000u64, 0i128, SEED);
    for _ in 0..n { let x = SPEEDS[(splitmix(&mut state) % 7) as usize]; total += x * x * x; }
    let sd = (integral(&|x| q(x.pow(6), 1), p) - mean_cube.pow(2)).fl().sqrt();
    let (mc, se) = (total as f64 / n as f64, sd / (n as f64).sqrt());
    println!("seed {}: sampled mean cube over {} days = {:.4}; standard error {:.4}", SEED, n, mc, se);
    assert!((mc - mean_cube.fl()).abs() < 4.0 * se);

    // ---- the square: Jensen's gap is the variance ----
    let var = integral(&|x| (q(x, 1) - m).pow(2), p);
    println!("E[f^2] = {}; (E[f])^2 = {}; gap {}; variance {}", mean_square, m.pow(2), mean_square - m.pow(2), var);
    assert!(mean_square - m.pow(2) == var);                     // two roads to 4

    // ---- AM-GM: the logarithm is concave ----
    let prod: i128 = SPEEDS.iter().product();
    let gm_log = (SPEEDS.iter().map(|&x| (x as f64).ln()).sum::<f64>() / 7.0).exp();
    let (mut lo, mut hi) = (1.0f64, 8.0f64);                    // bisection on g^7 = product
    for _ in 0..60 {
        let mid = (lo + hi) / 2.0;
        if mid.powi(7) < prod as f64 { lo = mid } else { hi = mid }
    }
    println!("product of speeds {}; geometric mean by logs {:.6}, by bisection {:.6}", prod, gm_log, lo);
    assert!((gm_log - lo).abs() < 1e-9 && gm_log < m.fl());

    // ---- Lyapunov: p-norms under P rise with p ----
    let ps: [u32; 10] = [1, 2, 3, 4, 6, 8, 12, 16, 24, 32];
    let means: Vec<f64> = ps.iter().map(|&k| norm(k, p)).collect();
    let pstr: Vec<String> = ps.iter().map(|k| k.to_string()).collect();
    println!("figure, p: 0 {}", pstr.join(" "));
    let mut fig = vec![format!("{:.2}", gm_log)];
    fig.extend(means.iter().map(|v| format!("{:.2}", v)));
    println!("figure, norm under P: {}", fig.join(", "));
    for (a, b) in [(1u32, 2u32), (1, 3), (2, 4)] {              // exact: (E f^a)^(b/a) <= E f^b
        let lhs = integral(&|x| q(x.pow(a), 1), p).pow(b / a);
        let rhs = integral(&|x| q(x.pow(b), 1), p);
        println!("exact, p = {}, q = {}: (E[f^{}])^{} = {} <= E[f^{}] = {}", a, b, a, b / a, lhs, b, rhs);
        assert!(lhs <= rhs && norm(a, p) <= norm(b, p));
    }
    assert!(means.windows(2).all(|w| w[0] < w[1]) && means[9] < 8.0);

    // ---- what breaks 1: counting measure, total mass 7 ----
    let (s1, s3) = (integral(&|x| q(x, 1), count), integral(&|x| q(x * x * x, 1), count));
    println!("counting measure: integral of f = {}, cubed {}; integral of f^3 = {}", s1, s1.pow(3), s3);
    let counts: Vec<f64> = [1u32, 2, 3].iter().map(|&k| norm(k, count)).collect();
    println!("counting measure norms p = 1, 2, 3: {:.2}, {:.2}, {:.2}", counts[0], counts[1], counts[2]);
    let scaled: Vec<f64> = (0..3).map(|i| counts[i] / 7f64.powf(1.0 / (i + 1) as f64)).collect();
    println!("divided by 7^(1/p): {:.2}, {:.2}, {:.2}", scaled[0], scaled[1], scaled[2]);
    assert!(s1.pow(3) > s3 && counts[0] > counts[1] && counts[1] > counts[2]);
    assert!((scaled[2] - means[2]).abs() < 1e-12);

    // ---- what breaks 2: infinite measure, f(x) = 1/x on [1, N] under lambda ----
    for nn in [10u64, 100, 1000, 10000] {
        let k = 200 * (nn - 1);
        let h = (nn - 1) as f64 / k as f64;
        let (mut i1, mut i2) = (0.0f64, 0.0f64);                 // midpoint rule, both integrals
        for i in 0..k { let t = 1.0 + (i as f64 + 0.5) * h; i1 += 1.0 / t; i2 += 1.0 / (t * t); }
        let (i1, i2, ln_n, tail) = (h * i1, h * i2, (nn as f64).ln(), 1.0 - 1.0 / nn as f64);
        println!("N = {}: integral of f = {:.4} (ln N = {:.4}); integral of f^2 = {:.4} (1 - 1/N = {:.4})",
                 nn, i1, ln_n, i2, tail);
        assert!((i1 - ln_n).abs() < 1e-5 && (i2 - tail).abs() < 1e-5);
    }

    // ---- what breaks 3: a concave function, and equality for a still day ----
    let root_mean = SPEEDS.iter().map(|&x| (x as f64).sqrt()).sum::<f64>() / 7.0;
    println!("square root: E[sqrt f] = {:.4} < sqrt(E[f]) = {:.4}", root_mean, m.fl().sqrt());
    let still = [5i128; 7];
    println!("steady 5 m/s every day: mean cube {}, cube of mean {}", still.iter().map(|x| x * x * x).sum::<i128>() / 7, q(still.iter().sum::<i128>(), 7).pow(3));
    assert!(root_mean < m.fl().sqrt());
    println!("ALL CHECKS PASS");
}
