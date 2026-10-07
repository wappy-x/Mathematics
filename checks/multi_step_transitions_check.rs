// n-step transitions -- the check behind the card.  std only.
// The weather chain of the markov-chains card, one step = one day, today sunny.
// Five roads to the law 7 days out: matrix powers; every path summed;
// Chapman-Kolmogorov splits; eigenvalues; a seeded simulation.  Exact values are
// whole numbers over 10^n, because every entry of P is a whole number of tenths.
type M = Vec<Vec<i128>>;
const NAMES: [&str; 3] = ["sunny", "cloudy", "rainy"];
const DAYS: usize = 7;
const WEEKS: u64 = 100000;
const SEED: u64 = 20260929;

fn mul(a: &M, b: &M) -> M { // exact matrix product
    (0..a.len()).map(|i| (0..b[0].len()).map(|j| (0..b.len()).map(|k| a[i][k] * b[k][j]).sum()).collect()).collect()
}
fn frac(num: i128, den: i128, places: u32) -> String { // num / den rounded half up, fixed decimals
    let s = if num < 0 { "-" } else { "" };
    let p = 10_i128.pow(places);
    let v = (num.abs() * p * 2 + den) / (2 * den);
    format!("{}{}.{:0w$}", s, v / p, v % p, w = places as usize)
}
fn t(n: usize) -> i128 { 10_i128.pow(n as u32) }
fn law(row: &[i128], n: usize) -> String { row.iter().map(|&x| frac(x, t(n), 7)).collect::<Vec<_>>().join(" ") }
fn cross<T: Copy + std::ops::Mul<Output = T> + std::ops::Sub<Output = T>>(a: &[T], b: &[T]) -> Vec<T> {
    vec![a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]]
}
fn ident() -> M { (0..3).map(|i| (0..3).map(|j| (i == j) as i128).collect()).collect() }

struct SplitMix(u64);
impl SplitMix {
    fn digit(&mut self) -> i128 { // a digit 0..9 from the top 32 bits
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^= z >> 31;
        (((z >> 32) * 10) >> 32) as i128
    }
}

fn main() {
    let p10: M = vec![vec![6, 3, 1], vec![3, 4, 3], vec![2, 4, 4]]; // P in tenths
    let wet10: M = vec![vec![4, 4, 2], vec![2, 4, 4], vec![1, 3, 6]]; // a wetter season, for What breaks
    println!("chain: sunny, cloudy, rainy; one step = one day; today sunny");
    let rows: Vec<String> = (0..3).map(|i| format!("{} {}", NAMES[i],
        p10[i].iter().map(|&x| frac(x, 10, 1)).collect::<Vec<_>>().join(" "))).collect();
    println!("P rows: {}", rows.join(" | "));

    // Road 1: powers P^n = P P^(n-1), and the law pushed forward, mu_n = mu_(n-1) P
    let (mut powers, mut mu, mut fc): (Vec<M>, M, M) = (vec![ident()], vec![vec![1, 0, 0]], vec![vec![5, 3, 2]]);
    for _ in 0..DAYS {
        let (next, row) = (mul(&p10, &powers[powers.len() - 1]), mul(&vec![mu[mu.len() - 1].clone()], &p10));
        powers.push(next);
        mu.push(row[0].clone());
        fc.push(mul(&vec![fc[fc.len() - 1].clone()], &p10)[0].clone()); // fc: an uncertain start, the forecast of markov-chains
    }
    println!("road 1, law by day (sunny cloudy rainy), exact:");
    for n in 0..=DAYS {
        assert!(mu[n] == powers[n][0] && mu[n].iter().sum::<i128>() == t(n));
        println!("  day {}: {}", n, law(&mu[n], n));
    }
    let pn = powers[DAYS].clone();
    println!("  P^{} row cloudy: {}; row rainy: {}", DAYS, law(&pn[1], DAYS), law(&pn[2], DAYS));
    let avg: Vec<i128> = (0..3).map(|j| (0..3).map(|i| fc[0][i] * pn[i][j]).sum()).collect(); // start law times P^7: rows averaged
    assert!(fc[DAYS] == avg && avg.iter().sum::<i128>() == t(DAYS + 1));
    let terms: Vec<String> = (0..3).map(|i| format!("{} x {}", frac(fc[0][i], 10, 1), frac(pn[i][2], t(DAYS), 7))).collect();
    println!("  forecast start, day {}: {}; rainy = {} = {}", DAYS, law(&fc[DAYS], DAYS + 1), terms.join(" + "), frac(avg[2], t(DAYS + 1), 7));

    // Road 2: every path from sunny, weighted by the product along it
    let (mut ends, mut count) = (vec![0_i128; 3], 0);
    for code in 0..3_usize.pow(DAYS as u32) {
        let (mut x, mut w, mut c) = (0_usize, 1_i128, code);
        for _ in 0..DAYS {
            let y = c % 3;
            (c, w, x) = (c / 3, w * p10[x][y], y);
        }
        (ends[x], count) = (ends[x] + w, count + 1);
    }
    assert_eq!(ends, pn[0]);
    println!("road 2, {} paths summed: {}", count, law(&ends, DAYS));

    // Road 3: Chapman-Kolmogorov, P^m P^(n-m) for every split
    let ok = (0..=DAYS).filter(|&m| mul(&powers[m], &powers[DAYS - m]) == pn).count();
    assert_eq!(ok, DAYS + 1);
    let col: Vec<i128> = (0..3).map(|k| powers[DAYS - 3][k][2]).collect();
    println!("road 3, splits P^m P^({}-m) equal to P^{}: {} of {}", DAYS, DAYS, ok, DAYS + 1);
    let dot: i128 = (0..3).map(|k| powers[3][0][k] * col[k]).sum();
    println!("  split at day 3: P^3 sunny row {} . P^{} rainy column {} = {}", law(&powers[3][0], 3),
             DAYS - 3, law(&col, DAYS - 3), frac(dot, t(DAYS), 7));

    // Road 4: eigenvalues.  pi = (24, 22, 15)/61 exactly; the other two from a quadratic
    let pi61: [i128; 3] = [24, 22, 15];
    assert!((0..3).all(|j| (0..3).map(|i| pi61[i] * p10[i][j]).sum::<i128>() == 10 * pi61[j]));
    let c12 = cross(&p10[1], &p10[2]);
    let det10: i128 = (0..3).map(|j| p10[0][j] * c12[j]).sum();
    let (s, d) = ((p10[0][0] + p10[1][1] + p10[2][2] - 10) as f64 / 10.0, det10 as f64 / 1000.0); // x^2 - s x + d = 0
    let lams = [1.0, (s + (s * s - 4.0 * d).sqrt()) / 2.0, (s - (s * s - 4.0 * d).sqrt()) / 2.0];
    let mut comps: Vec<Vec<f64>> = Vec::new();
    for &lam in lams.iter() { // left row v and right column r of P - lam I
        let m: Vec<Vec<f64>> = (0..3)
            .map(|i| (0..3).map(|j| p10[i][j] as f64 / 10.0 - lam * ((i == j) as i32 as f64)).collect()).collect();
        let v = cross(&[m[0][0], m[1][0], m[2][0]], &[m[0][1], m[1][1], m[2][1]]);
        let r = cross(&m[0], &m[1]);
        let c = r[0] / (0..3).map(|i| v[i] * r[i]).sum::<f64>(); // share of today's law on v
        comps.push(v.iter().map(|x| c * x).collect());
    }
    assert!((0..3).all(|j| (comps[0][j] - pi61[j] as f64 / 61.0).abs() < 1e-12));
    let mut pw = [1.0_f64; 3];
    for n in 0..=DAYS {
        for j in 0..3 {
            let f: f64 = (0..3).map(|k| comps[k][j] * pw[k]).sum();
            assert!((f - mu[n][j] as f64 / t(n) as f64).abs() < 1e-12);
        }
        pw = [pw[0] * lams[0], pw[1] * lams[1], pw[2] * lams[2]];
    }
    let lr: Vec<String> = pi61.iter().map(|&x| frac(x, 61, 7)).collect();
    println!("road 4, eigenvalues 1 and the roots of x^2 - {:.1} x + {:.2}: {:.7}, {:.7}; long run (24 22 15)/61 = {}",
             s, d, lams[1], lams[2], lr.join(" "));
    println!("  rainy_n = {:.7} + ({:.7}) x {:.7}^n + ({:.7}) x {:.7}^n, days 0 to {} within 1e-12",
             comps[0][2], comps[1][2], lams[1], comps[2][2], lams[2], DAYS);
    let gap: Vec<i128> = [DAYS - 1, DAYS].iter().map(|&n| 15 * t(n) - 61 * mu[n][2]).collect();
    println!("  rainy gap to long run, day {}: {}, day {}: {}, ratio {:.4}", DAYS - 1, frac(gap[0], 61 * t(DAYS - 1), 7),
             DAYS, frac(gap[1], 61 * t(DAYS), 7), gap[1] as f64 / (10 * gap[0]) as f64);

    // Road 5: simulate WEEKS weeks with SplitMix64, a digit 0..9 picks tomorrow
    let (mut rng, mut hits) = (SplitMix(SEED), [0_u64; 3]);
    for _ in 0..WEEKS {
        let mut x = 0;
        for _ in 0..DAYS {
            let (mut d, mut y) = (rng.digit(), 0);
            while d >= p10[x][y] { (d, y) = (d - p10[x][y], y + 1); }
            x = y;
        }
        hits[x] += 1;
    }
    for j in 0..3 {
        let p = hits[j] as f64 / WEEKS as f64;
        let se = (p * (1.0 - p) / WEEKS as f64).sqrt();
        assert!((p - pn[0][j] as f64 / t(DAYS) as f64).abs() < 4.0 * se);
        println!("road 5, {} simulated weeks, seed {}, {} on day {}: {:.4} +/- {:.4}", WEEKS, SEED, NAMES[j], DAYS, p, se);
    }

    // Charts: the law by day, rounded to 2 places
    for j in 0..3 {
        let pts: Vec<String> = (0..=DAYS).map(|n| frac(mu[n][j], t(n), 2)).collect();
        println!("chart, {}: {}", NAMES[j], pts.join(", "));
    }

    // What breaks
    let col_s: Vec<i128> = (0..3).map(|i| pn[i][0]).collect();
    println!("break, P^{} times the start as a column: {}, sum {}", DAYS, law(&col_s, DAYS),
             frac(col_s.iter().sum(), t(DAYS), 7));
    let wr: Vec<String> = wet10.iter().map(|r| r.iter().map(|&x| frac(x, 10, 1)).collect::<Vec<_>>().join(" ")).collect();
    println!("break, wet table rows: {}", wr.join(" | "));
    let mut wet = ident();
    for _ in 0..DAYS - 3 { wet = mul(&wet, &wet10); }
    let (ordered, backwards) = (mul(&vec![mu[3].clone()], &wet)[0].clone(), mul(&vec![wet[0].clone()], &powers[3])[0].clone());
    assert!(ordered != backwards && ordered != pn[0]);
    println!("break, 3 days of P then {} of the wet table, rainy: {}; P^{} alone {}; wet days first {}", DAYS - 3,
             frac(ordered[2], t(DAYS), 7), DAYS, frac(pn[0][2], t(DAYS), 7), frac(backwards[2], t(DAYS), 7));
    let pat = ['S', 'S', 'R', 'R']; // two-day spells S S R R S S ..., random start
    let pairs: Vec<(char, char)> = (0..4).map(|f| (pat[f], pat[(f + 1) % 4])).collect();
    let fit = |a: char| {
        pairs.iter().filter(|p| **p == (a, 'S')).count() as f64 / pairs.iter().filter(|p| p.0 == a).count() as f64
    };
    let fit2 = fit('S') * fit('S') + (1.0 - fit('S')) * fit('R');
    let true2 = (0..4).filter(|&f| pat[f] == 'S' && pat[(f + 2) % 4] == 'S').count() as f64
        / pat.iter().filter(|&&c| c == 'S').count() as f64;
    assert!(fit2 != true2);
    println!("break, spells of two days: fitted P^2 sunny->sunny {:.4}, true {:.4}", fit2, true2);
}
