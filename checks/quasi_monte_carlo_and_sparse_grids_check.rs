// Quasi-Monte Carlo and sparse grids -- the same check as the Python, in Rust.
// No crates; every point set is built here.  First card 06's basket call, then a
// smooth basket: five assets at $100, each one-year log return spread evenly over
// -30% to +30% (illustrative), wanted the mean of their geometric average.  Roads:
// closed forms; random; van der Corput and Halton; Sobol, plain and shifted; a sparse grid.
use std::collections::BTreeMap;
const C: f64 = 0.06;
const D5: usize = 5; const N: usize = 1024; const BITS: usize = 30;
const PRIMES: [u64; 20] = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71];
fn basket(u: &[f64]) -> f64 { 100.0 * (C * u.iter().fold(0.0, |s, x| s + (2.0 * x - 1.0))).exp() }
struct SplitMix(u64);                       // SplitMix64, written out: random road
impl SplitMix {
    fn next(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = (self.0 ^ (self.0 >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 * 2f64.powi(-53)
    }
}
fn radical_inverse(mut i: u64, p: u64) -> f64 {   // mirror the base-p digits of i
    let (mut x, mut f) = (0.0, 1.0 / p as f64);
    while i > 0 { x += (i % p) as f64 * f; i /= p; f /= p as f64; }
    x
}
fn halton(i: usize, d: usize) -> Vec<f64> { PRIMES[..d].iter().map(|&p| radical_inverse(i as u64, p)).collect() }
fn directions() -> Vec<Vec<u64>> {
    let poly: [(usize, u64, Vec<u64>); 4] = [(1, 0, vec![1]), (2, 1, vec![1, 3]), (3, 1, vec![1, 3, 1]), (3, 2, vec![1, 1, 1])];
    let mut v = vec![(1..=BITS).map(|k| 1u64 << (BITS - k)).collect::<Vec<u64>>()];   // halves
    for (s, a, m0) in poly.iter() {         // dimensions 2-5: Joe-Kuo's numbers
        let (s, mut m) = (*s, m0.clone());
        for k in s..BITS {
            let mut new = m[k - s] ^ (m[k - s] << s);
            for t in 1..s { if (a >> (s - 1 - t)) & 1 == 1 { new ^= m[k - t] << t; } }
            m.push(new);
        }
        v.push((0..BITS).map(|k| m[k] << (BITS - 1 - k)).collect());
    }
    v
}
fn sobol(v: &[Vec<u64>], i: usize) -> Vec<f64> {  // XOR the direction numbers i's bits pick
    v.iter().map(|dir| {
        let (mut x, mut k, mut j) = (0u64, 0, i);
        while j > 0 { if j & 1 == 1 { x ^= dir[k]; } k += 1; j >>= 1; }
        x as f64 / 2f64.powi(BITS as i32)
    }).collect()
}
fn mean(f: &dyn Fn(&[f64]) -> f64, pts: &[Vec<f64>]) -> f64 { pts.iter().fold(0.0, |s, u| s + f(u)) / pts.len() as f64 }
fn rule(l: usize) -> Vec<(f64, f64)> {      // midpoint, then nested trapezoid: 1, 3, 5, 9, 17 points
    if l == 1 { return vec![(0.5, 1.0)]; }
    let n = 1usize << (l - 1);
    (0..=n).map(|j| (j as f64 / n as f64, (if j == 0 || j == n { 0.5 } else { 1.0 }) / n as f64)).collect()
}
fn levels(total: usize, d: usize) -> Vec<Vec<usize>> {  // d levels >= 1 summing to total
    if d == 1 { return vec![vec![total]]; }
    (1..(total + 2 - d)).flat_map(|a| levels(total - a, d - 1).into_iter().map(move |rest| [vec![a], rest].concat())).collect()
}
fn comb(n: usize, k: usize) -> f64 { (0..k).fold(1.0, |c, i| c * (n - i) as f64 / (i + 1) as f64) }
fn smolyak(k: usize, d: usize) -> Vec<(Vec<f64>, f64)> {  // combination form; weights merged
    let mut pts: BTreeMap<Vec<u64>, f64> = BTreeMap::new();
    for s in (d.max(k + 1))..=(k + d) {
        let coef = (if (k + d - s) % 2 == 0 { 1.0 } else { -1.0 }) * comb(d - 1, k + d - s);
        for lv in levels(s, d) {
            let mut grid: Vec<(Vec<f64>, f64)> = vec![(vec![], coef)];
            for &l in &lv {
                let r = rule(l);
                grid = grid.iter().flat_map(|(x, w)| r.iter().map(move |&(p, q)| {
                    let mut y = x.clone(); y.push(p); (y, w * q) })).collect();
            }
            for (x, w) in grid { *pts.entry(x.iter().map(|v| v.to_bits()).collect()).or_insert(0.0) += w; }
        }
    }
    pts.into_iter().map(|(x, w)| (x.iter().map(|&b| f64::from_bits(b)).collect(), w)).collect()
}
fn new_points(l: usize) -> usize { if l == 1 { 1 } else if l == 2 { 2 } else { 1 << (l - 2) } }
fn count_by_formula(k: usize, d: usize) -> usize {   // second road to the sparse-grid size
    (d..=k + d).flat_map(|s| levels(s, d)).map(|lv| lv.iter().map(|&l| new_points(l)).product::<usize>()).sum()
}
fn sgrid(k: usize, f: &dyn Fn(&[f64]) -> f64) -> f64 { smolyak(k, D5).iter().fold(0.0, |s, (x, w)| s + w * f(x)) }
fn dstar(pts: &[f64]) -> f64 {              // exact star discrepancy of a 1-D set
    let (mut x, n) = (pts.to_vec(), pts.len() as f64); x.sort_by(|a, b| a.partial_cmp(b).unwrap());
    x.iter().enumerate().fold(0.0, |m: f64, (i, &v)| m.max(((i + 1) as f64 / n - v).max(v - i as f64 / n)))
}
fn main() {
    let exact = 100.0 * (C.sinh() / C).powi(D5 as i32);   // closed form: five independent factors
    let sigma = 100.0 * (((2.0 * C).sinh() / (2.0 * C)).powi(D5 as i32) - (C.sinh() / C).powi(10)).sqrt();
    let v = directions();
    let (sob, hal): (Vec<Vec<f64>>, Vec<Vec<f64>>) = ((0..N).map(|i| sobol(&v, i)).collect(), (0..N).map(|i| halton(i, D5)).collect());
    let call_x = 8.0 * (0..6).fold(0.0, |s, j| s + (if j % 2 == 0 { 1.0 } else { -1.0 }) * comb(D5, j) * (2.5 - j as f64).max(0.0).powi(6)) / 720.0; // card 06
    let call = |u: &[f64]| 100.0 * (0.8 + 0.4 * u.iter().fold(0.0, |s, x| s + x) / D5 as f64 - 1.0).max(0.0); // card 06's $100 basket call
    let grid10: Vec<Vec<f64>> = (0..100000usize).map(|i| (0..D5 as u32).map(|a| (((i / 10usize.pow(a)) % 10) as f64 + 0.5) / 10.0).collect()).collect();
    let ec = [mean(&call, &sob) - call_x, mean(&call, &hal) - call_x, mean(&call, &grid10) - call_x, sgrid(4, &call) - call_x]; // card 06's grid, 10 per axis
    let se_c = (64.0 * 5.0 / 24.0 - call_x * call_x).sqrt() / (N as f64).sqrt(); // card 06's sigma over root N
    println!("card 06's call: exact {:.6}, random SE {:.6}; Sobol {:+.6}, {:.1} times smaller; Halton {:+.6}; 100000-point grid {:+.6}; 801-point sparse grid {:+.6}",
             call_x, se_c, ec[0], se_c / ec[0].abs(), ec[1], ec[2], ec[3]);
    println!("basket exact mean {:.9}; spread of one draw sigma {:.6}; variance share from single coordinates {:.4}", exact, sigma,
             D5 as f64 * (C.sinh() / C).powi(8) * ((2.0 * C).sinh() / (2.0 * C) - (C.sinh() / C).powi(2)) * 1e4 / (sigma * sigma));
    let mut rnd = SplitMix(2026);                // the random road
    let err_r = mean(&basket, &(0..N).map(|_| (0..D5).map(|_| rnd.next()).collect()).collect::<Vec<Vec<f64>>>()) - exact;
    let (err_h, err_s) = (mean(&basket, &hal) - exact, mean(&basket, &sob) - exact);
    let err_g = sgrid(4, &basket) - exact;
    let h17 = (0..17).fold(0.0, |s, j| s + (if j == 0 || j == 16 { 0.5 } else { 1.0 }) / 16.0 * (C * (2.0 * j as f64 / 16.0 - 1.0)).exp());
    let err_f = 100.0 * h17.powi(D5 as i32) - exact;    // full 17^5 grid, as a product of 1-D sums
    let se = sigma / (N as f64).sqrt();
    println!("N = {}, error of each road:  random standard error {:.6}, this run {:+.6}", N, se, err_r);
    println!("  Halton {:+.6}   Sobol {:+.6}   Sobol beats the standard error {:.1} times", err_h, err_s, se / err_s.abs());
    println!("  random points needed to match Sobol: {:.0}", sigma * sigma / (err_s * err_s));
    println!("  sparse grid level 4, {} points ({} of weight below 0) {:+.6}; full 17-per-side grid, {} points {:+.6}",
             smolyak(4, D5).len(), smolyak(4, D5).iter().filter(|(_, w)| *w < 0.0).count(), err_g, 17usize.pow(D5 as u32), err_f);
    println!("N       random SE   Halton      Sobol       log10 N  log10 |error|: SE, Halton, Sobol");
    let mut rows: Vec<[f64; 4]> = Vec::new();
    for n in [64usize, 256, 1024, 4096, 16384] {
        let row = [n as f64, sigma / (n as f64).sqrt(),
                   mean(&basket, &(0..n).map(|i| halton(i, D5)).collect::<Vec<_>>()) - exact,
                   mean(&basket, &(0..n).map(|i| sobol(&v, i)).collect::<Vec<_>>()) - exact];
        println!("{:<8}{:<12.6}{:<+12.6}{:<+12.6}{:<9.2}{}", n, row[1], row[2], row[3], (n as f64).log10(),
                 row[1..].iter().map(|x| format!("{:.2}", x.abs().log10())).collect::<Vec<_>>().join("  "));
        rows.push(row);
    }
    let order: Vec<f64> = [2, 3].iter().flat_map(|&j| { let r = &rows; (0..4).map(move |i| (r[i][j] / r[i + 1][j]).abs().ln() / 4f64.ln()) }).collect();
    let f2 = |s: &[f64]| s.iter().map(|x| format!("{:.2}", x)).collect::<Vec<_>>().join(" ");
    println!("observed order per quadrupling, Halton: {} | Sobol: {}", f2(&order[..4]), f2(&order[4..]));
    let first8: Vec<String> = (0..8).map(|i| format!("{}", radical_inverse(i, 2))).collect();
    let base3: Vec<String> = (0..4).map(|i| format!("{:.4}", radical_inverse(i, 3))).collect();
    println!("van der Corput, first 8: {} | Halton base 3: {}", first8.join(" "), base3.join(" "));
    let vdc = dstar(&(0..1000).map(|i| radical_inverse(i, 2)).collect::<Vec<_>>());
    let (mut rnd1, ones) = (SplitMix(7), 1000u32.count_ones());
    let d_r = dstar(&(0..1000).map(|_| rnd1.next()).collect::<Vec<_>>());
    println!("N = 1000: van der Corput D* {:.6}, bound {}/N = {:.6}, ratio {:.3}; random D* {:.6}",
             vdc, ones, ones as f64 / 1000.0, vdc * 1000.0 / ones as f64, d_r);
    let worst = (1..=1024u64).map(|n| dstar(&(0..n).map(|i| radical_inverse(i, 2)).collect::<Vec<_>>()) * n as f64 / n.count_ones() as f64).fold(0.0, f64::max);
    println!("worst D* / bound over N = 1 to 1024: {:.3}", worst);
    let roots: Vec<String> = [2.0f64, 3.0, 5.0, 10.0, 20.0].iter().map(|&d| {
        let mut l = 4.0 * d * d;            // fixed point of L = 2d ln L, upper root; L is ln N
        for _ in 0..200 { l = 2.0 * d * l.ln(); }
        format!("  d {}: {:.1}", d, l / 10f64.ln()) }).collect();
    println!("bound shape (ln N)^d / N falls below 1 / sqrt(N) only after log10 N ={}", roots.concat());
    println!("g = product of |4u - 2|, mean 1, N = 1024: d, Halton error, random SE, ratio, single-coordinate share");
    for d in [1usize, 2, 5, 10, 20] {
        let gf = |u: &[f64]| u.iter().fold(1.0, |p, x| p * (4.0 * x - 2.0).abs());
        let g = mean(&gf, &(0..N).map(|i| halton(i, d)).collect::<Vec<_>>());
        let gse = (((4.0f64 / 3.0).powi(d as i32) - 1.0) / N as f64).sqrt();
        println!("  {:<3}{:<+15.6}{:<10.6}{:<10.3}{:.4}", d, g - 1.0, gse, (g - 1.0).abs() / gse, d as f64 / 3.0 / ((4.0f64 / 3.0).powi(d as i32) - 1.0));
    }
    println!("sparse grid level: points in 5 dims (enumerated, by formula), full grid");
    for k in 0..6 {
        println!("  {}  {:>5}{:>6}{:>10}", k, smolyak(k, D5).len(), count_by_formula(k, D5), (if k > 0 { (1usize << k) + 1 } else { 1 }).pow(D5 as u32));
    }
    let (fx, fy) = { let mut fig = SplitMix(11); (fig.next(), fig.next()) };
    let s4: Vec<String> = (0..4).map(|i| { let p = sobol(&v, i); format!("({},{})", p[0], p[1]) }).collect();
    println!("figure, random 0: ({:.4},{:.4}); Sobol 0-3: {} | sparse 2-D level 4: {} of 289", fx, fy, s4.join(" "), smolyak(4, 2).len());
    let t = 2.5 + 1.02f64.ln() / (2.0 * C);  // digital: pays 1 if the average > $102
    let irwin = 1.0 - (0..6).fold(0.0, |s, j| s + (if j % 2 == 0 { 1.0 } else { -1.0 }) * comb(D5, j) * (t - j as f64).max(0.0).powi(5)) / 120.0;
    let digital = |u: &[f64]| if u.iter().fold(0.0, |s, x| s + x) > t { 1.0 } else { 0.0 };
    let (dig, dig_s) = (sgrid(4, &digital), mean(&digital, &sob));
    println!("mistakes: digital exact {:.6}, sparse grid 801 points {:.6}, Sobol {:.6}", irwin, dig, dig_s);
    let mut sh = SplitMix(99);                  // random shifts: move every Sobol point one random step, wrap round
    let rq: Vec<f64> = (0..10).map(|_| { let dl: Vec<f64> = (0..D5).map(|_| sh.next()).collect();
        mean(&basket, &sob.iter().map(|p| p.iter().zip(&dl).map(|(x, y)| (x + y) % 1.0).collect()).collect::<Vec<Vec<f64>>>()) - exact }).collect();
    let m_rq = rq.iter().fold(0.0, |s, x| s + x) / 10.0; let s_rq = (rq.iter().fold(0.0, |s, x| s + (x - m_rq) * (x - m_rq)) / 90.0).sqrt();
    println!("Sobol, 10 random shifts: mean error {:+.6}, standard error {:.6}", m_rq, s_rq);
    assert!((0..D5).all(|j| { let mut c: Vec<usize> = sob.iter().map(|p| (p[j] * N as f64) as usize).collect(); c.sort(); c == (0..N).collect::<Vec<_>>() }));
    assert!(err_s.abs() < se / 4.0 && err_r.abs() < 3.0 * se && err_g.abs() < err_s.abs() / 4.0 && ec[0].abs() < (se_c / 10.0).min(ec[2].abs()));
    assert!(m_rq.abs() < 4.0 * s_rq && s_rq < se / 4.0);                   // shifted Sobol: an honest bar, still narrow
    assert!(order[4..].iter().all(|&o| o > 0.9 && o < 1.1));             // near one over N
    assert!((err_g - err_f).abs() < 0.05 * err_f.abs());                   // 801 points match 1.4 million
    assert!((0..6).all(|k| smolyak(k, D5).len() == count_by_formula(k, D5)));
    assert!(worst <= 1.0 && vdc < d_r / 5.0);                              // D* <= popcount(N) / N
    assert!((dig - irwin).abs() > 0.5 && (dig_s - irwin).abs() < 0.01 && ec[3].abs() > 0.5); // jump, kink: sparse grid fails
    println!("ALL CHECKS PASS");
}
