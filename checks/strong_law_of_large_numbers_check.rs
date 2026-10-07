// Strong law of large numbers -- the check behind the card.  Rust std only.
// A fair die, mean 3.5, tolerance 0.1.  Roads: exact integer fractions for the
// moments and closed forms beside them; the fourth moment of the sum by formula
// and by counting all 6^n sequences; exact tail probabilities by convolution
// against the two bounds and against simulation (SplitMix64, seed 20260929); the
// +-n sequence by partial sums against the integral test.  Limits need proofs.
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn show(n: i128, d: i128) -> String {
    let g = gcd(n, d);
    if d / g == 1 { format!("{}", n / g) } else { format!("{}/{}", n / g, d / g) }
}
const M2: f64 = 35.0 / 12.0;
const M4: f64 = 707.0 / 48.0;
fn cheb(n: u64) -> f64 { 100.0 * M2 / n as f64 } // E[Y^2] / (n eps^2)
fn fourth(n: u64) -> f64 { // E[S_n^4] / (n^4 eps^4)
    let x = n as f64;
    10000.0 * (x * M4 + 3.0 * x * (x - 1.0) * M2 * M2) / (x * x * (x * x))
}
struct SplitMix(u64);
impl SplitMix {
    fn roll(&mut self) -> i64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) % 6 + 1) as i64
    }
}

fn main() {
    // doubled centred faces 2f - 7 = -5, -3, ..., 5; Y = (2f - 7)/2
    let s2: i128 = (1..=6).map(|f: i128| (2 * f - 7).pow(2)).sum(); // 4 * 6 * E[Y^2]
    let s4: i128 = (1..=6).map(|f: i128| (2 * f - 7).pow(4)).sum(); // 16 * 6 * E[Y^4]
    let (m2n, m2d, m4n, m4d) = (s2, 4 * 6, s4, 16 * 6);
    let (c_n, c_d) = ((m4n * m2d * m2d + 3 * m2n * m2n * m4d) * 10000, m4d * m2d * m2d);
    println!("centred die: E[Y^2] = {} = {:.6}, E[Y^4] = {} = {:.6}", show(m2n, m2d), m2n as f64 / m2d as f64,
        show(m4n, m4d), m4n as f64 / m4d as f64);
    println!("closed forms (k^2-1)/12 = {}, (k^2-1)(3k^2-7)/240 = {}", show(35, 12), show(35 * 101, 240));
    println!("E[Y^4] + 3 E[Y^2]^2 = {:.2}; C = that / 0.1^4 = {}", c_n as f64 / c_d as f64 / 10000.0, show(c_n, c_d));
    let moments_ok = m2n * 12 == 35 * m2d && m4n * 240 == 3535 * m4d && c_n == 402500 * c_d;

    println!("E[(S_n - 3.5n)^4]: formula n m4 + 3n(n-1) m2^2, and a count over all 6^n sequences");
    let mut counts: Vec<i128> = vec![1]; // counts[s] = number of sequences with sum s
    let mut fourth_ok = true;
    for n in 1..=8i128 {
        let mut new = vec![0i128; counts.len() + 6];
        for (s, &c) in counts.iter().enumerate() { for f in 1..=6 { new[s + f] += c; } }
        counts = new;
        let counted: i128 = counts.iter().enumerate().map(|(s, &c)| c * (2 * s as i128 - 7 * n).pow(4)).sum();
        let den = 16 * 6i128.pow(n as u32);
        let formula = 2121 * n + 3675 * n * (n - 1); // over 144
        fourth_ok &= counted * 144 == formula * den;
        if [1, 2, 3, 4, 8].contains(&n) {
            println!("n={}: formula {:.6}, count {:.6}", n, formula as f64 / 144.0, counted as f64 / den as f64);
        }
    }

    println!("P(|average - 3.5| > 0.1): Chebyshev 35/12/(n 0.01), fourth-moment bound, C/n^2, exact");
    let c = 402500.0f64;
    let mut dist = vec![1.0f64]; // dist[s - n] = P(S_n = s)
    let mut exact: Vec<(u64, f64)> = Vec::new();
    for n in 1..=1000u64 {
        let old = dist;
        dist = (0..old.len() + 5).map(|j| {
            let mut acc = 0.0;
            for f in 0..6 { if j >= f && j - f < old.len() { acc += old[j - f]; } }
            acc / 6.0
        }).collect();
        if [10, 100, 200, 500, 1000].contains(&n) {
            let mut p = 0.0;
            for (j, &q) in dist.iter().enumerate() {
                if 5 * (2 * (j as i64 + n as i64) - 7 * n as i64).abs() > n as i64 { p += q; }
            }
            exact.push((n, p));
            println!("n={:4}: {:9.4} {:11.4} {:11.4} {:.4}", n, cheb(n), fourth(n), c / (n * n) as f64, p);
        }
    }
    println!("n=10000: {:9.4} {:11.4} {:11.4} (no exact)", cheb(10000), fourth(10000), c / (10000 * 10000) as f64);
    let edge: f64 = dist.iter().enumerate() // dist is n = 1000
        .filter(|&(j, _)| 5 * (2 * (j as i64 + 1000) - 7000).abs() >= 1000).map(|(_, &q)| q).sum();
    println!("n=1000, the edge totals 3400 and 3600 counted too: P(|average - 3.5| >= 0.1) = {:.4}", edge);
    let tl: Vec<String> = [402501u64, 402502, 40250002].iter().map(|&n| format!("{:.6} at N={}", c / (n - 1) as f64, n)).collect();
    println!("Borel-Cantelli tail: sum over n >= N of C/n^2 <= C/(N-1) = {}", tl.join("; "));
    let (mut sc, mut sf) = (0.0f64, 0.0f64);
    for n in 1000..=1000000u64 {
        sc += cheb(n);
        sf += fourth(n);
        if [10000, 100000, 1000000].contains(&n) {
            println!("sum of bounds for n = 1000..{}: Chebyshev {:.2}, fourth-moment {:.2}", n, sc, sf);
        }
    }

    let check = [10usize, 20, 50, 100, 200, 500, 1000, 2000, 5000, 10000];
    let grid = [100usize, 200, 500, 1000, 2000, 5000];
    let (runs, len) = (200usize, 10000usize);
    let (mut out_at, mut again) = (vec![0usize; 6], vec![0usize; 6]);
    let mut rng = SplitMix(20260929);
    let mut first_avg = 0.0;
    for r in 0..runs {
        let (mut s, mut last, mut s200) = (0i64, 0usize, 0i64);
        let mut avgs = Vec::new();
        for n in 1..=len {
            s += rng.roll();
            if 5 * (2 * s - 7 * n as i64).abs() > n as i64 {
                last = n;
                if let Some(i) = grid.iter().position(|&g| g == n) { out_at[i] += 1; }
            }
            if check.contains(&n) { avgs.push(s as f64 / n as f64); }
            if n == 200 { s200 = s; }
        }
        for (i, &g) in grid.iter().enumerate() { if last >= g { again[i] += 1; } }
        if r == 0 {
            let a: Vec<String> = check.iter().zip(&avgs).map(|(n, v)| format!("{}: {:.4}", n, v)).collect();
            println!("run 1, running average: {}", a.join(", "));
            println!("run 1: last n <= 10000 outside the band 3.40 to 3.60 is n = {}", last);
            println!("run 1: rolls 201 to 10000 average (S_10000 - S_200) / 9800 = {:.4}", (s - s200) as f64 / (len - 200) as f64);
            let f: Vec<String> = avgs.iter().map(|v| format!("{:.2}", v)).collect();
            println!("figure, run 1 averages to 2 decimals: {}", f.join(", "));
            first_avg = avgs[9];
        }
    }
    println!("{} runs of {}: n, runs outside the band at n, runs outside at some m in [n, 10000]", runs, len);
    for i in 0..6 { println!("n={:4}: {:3} {:3}", grid[i], out_at[i], again[i]); }

    println!("+-n sequence: Z_n = +n or -n, each with chance 1/(2 n ln n), else 0 (n >= 3)");
    let (mut v, mut h, mut bracket_ok) = (0.0f64, 0.0f64, true);
    for n in 3..=1000000u64 {
        let x = n as f64;
        v += x / x.ln();
        h += 1.0 / (x * x.ln());
        if [10, 100, 1000, 10000, 100000, 1000000].contains(&n) {
            let lo = (x + 1.0).ln().ln() - 3f64.ln().ln();
            let hi = x.ln().ln() - 3f64.ln().ln() + 1.0 / (3.0 * 3f64.ln());
            bracket_ok &= lo <= h && h <= hi;
            println!("n={:7}: Var(S_n/n) {:.6}, 2 ln n Var {:.4}, sum P(|Z_k| = k) {:.4} in [{:.4}, {:.4}]",
                n, v / (n * n) as f64, 2.0 * x.ln() * v / (n * n) as f64, h, lo, hi);
        }
    }
    let far = (1..=6i64).filter(|f| 5 * (2 * f - 7).abs() > 1).count() as i128; // average = first face
    println!("copied die (every roll equals the first): P(|average - 3.5| > 0.1) = {} at every n", show(far, 6));

    assert!(moments_ok); // moments: listing vs closed form
    assert!(fourth_ok); // fourth moment: count vs formula
    assert!(exact.iter().all(|&(n, p)| p <= 1.0f64.min(cheb(n)).min(fourth(n)))); // bounds hold on exact values
    let p1000 = exact[4].1;
    let se = (p1000 * (1.0 - p1000) / runs as f64).sqrt();
    assert!((out_at[3] as f64 / runs as f64 - p1000).abs() < 4.0 * se); // simulation vs convolution
    assert!((first_avg - 3.5).abs() < 4.0 * (M2 / len as f64).sqrt()); // one run's average vs mean
    assert!(bracket_ok); // divergent sum vs integral test
}
