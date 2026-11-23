// BPP card check: the rota product check (one-sided), all coin strings, a seeded simulation,
// and the majority vote that amplifies a two-sided test. std only.
type M = [[i64; 3]; 3];

struct SplitMix64 { s: u64 } // small seeded generator, explained on wing 09's simulation cards
impl SplitMix64 {
    fn next(&mut self) -> u64 {
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    }
    fn unit(&mut self) -> f64 { (self.next() >> 11) as f64 / 9007199254740992.0 }
    fn draw(&mut self, vals: &[i64]) -> Vec<i64> {
        (0..3).map(|_| vals[(self.next() % vals.len() as u64) as usize]).collect()
    }
}

fn mat_mul(x: &M, y: &M) -> M {
    let mut c = [[0; 3]; 3];
    for i in 0..3 { for j in 0..3 { for t in 0..3 { c[i][j] += x[i][t] * y[t][j]; } } }
    c
}
fn mat_vec(x: &M, v: &[i64]) -> Vec<i64> { (0..3).map(|i| (0..3).map(|t| x[i][t] * v[t]).sum()).collect() }
fn passes(a: &M, b: &M, c: &M, x: &[i64]) -> bool { mat_vec(a, &mat_vec(b, x)) == mat_vec(c, x) }
fn lists(values: &[i64]) -> Vec<Vec<i64>> { // every possible random list of length 3
    let mut out: Vec<Vec<i64>> = vec![vec![]];
    for _ in 0..3 {
        out = out.iter().flat_map(|l| values.iter().map(move |&v| { let mut n = l.clone(); n.push(v); n })).collect();
    }
    out
}
fn sci(x: f64) -> String { // same digits in both languages: scale by tens, then 2 decimals
    let (mut m, mut e) = (x, 0);
    while m >= 10.0 { m /= 10.0; e += 1; }
    while m < 1.0 { m *= 10.0; e -= 1; }
    format!("{:.2}e{}", m, e)
}
fn vote_error(p: f64, k: usize) -> f64 { // chance a majority of k runs is wrong, built one run at a time
    let mut dist = vec![1.0f64];
    for _ in 0..k {
        let n = dist.len();
        dist = (0..=n).map(|j| (if j < n { dist[j] * p } else { 0.0 }) + (if j > 0 { dist[j - 1] * (1.0 - p) } else { 0.0 })).collect();
    }
    let mut total = 0.0;
    for v in &dist[(k + 1) / 2..] { total += v; }
    total
}
fn binom_sum(k: usize) -> f64 { // second road: the binomial terms written out, wrong chance 1/3
    let mut total = 0.0;
    for j in (k + 1) / 2..=k {
        let mut c = 1.0f64;
        for i in 0..j { c = c * (k - i) as f64 / (i + 1) as f64; }
        total += c * (1.0f64 / 3.0).powi(j as i32) * (2.0f64 / 3.0).powi((k - j) as i32);
    }
    total
}

fn main() {
    let a: M = [[4, 3, 2], [2, 2, 1], [5, 4, 3]];    // staff on wards W1..W3 per early, late, night shift
    let b: M = [[8, 6, 6], [8, 8, 6], [10, 10, 12]]; // hours of each shift on Mon, Sat, Sun
    let c = mat_mul(&a, &b);                         // staff-hours per ward per day: the true table
    let mut wrong = c; wrong[1][1] = 36;                      // one entry mistyped: W2 Sat
    let mut swap = c; swap[1][0] += 2; swap[1][1] -= 2;       // two errors, row total unchanged
    println!("true table C = AB, staff-hours, columns Mon Sat Sun");
    for w in 0..3 { println!("W{} {} {} {}", w + 1, c[w][0], c[w][1], c[w][2]); }
    for x in [vec![1, 0, 1], vec![0, 1, 1]] {
        let bx = mat_vec(&b, &x);
        let (left, right) = (mat_vec(&a, &bx), mat_vec(&wrong, &x));
        println!("run x={:?}: Bx={:?} A(Bx)={:?} claimed Cx={:?} {}", x, bx, left, right, if left == right { "pass" } else { "caught" });
    }
    let ten: Vec<i64> = (0..10).collect();
    let (l01, l10) = (lists(&[0, 1]), lists(&ten));
    let count = |t: &M, l: &Vec<Vec<i64>>| l.iter().filter(|x| passes(&a, &b, t, x)).count();
    let right_pass = count(&c, &l01);
    let (miss01, miss10) = (count(&wrong, &l01), count(&wrong, &l10));
    let (swap01, swap10) = (count(&swap, &l01), count(&swap, &l10));
    let mut two_runs = 0;
    for x in &l01 { for y in &l01 { if passes(&a, &b, &wrong, x) && passes(&a, &b, &wrong, y) { two_runs += 1; } } }
    let reused = l01.iter().filter(|x| passes(&a, &b, &wrong, x) && passes(&a, &b, &wrong, x)).count();
    println!("all 0/1 lists, true table: passes {} of 8", right_pass);
    println!("all 0/1 lists, one wrong entry: misses {} of 8 = {:.6}", miss01, miss01 as f64 / 8.0);
    println!("all 0-9 lists, one wrong entry: misses {} of 1000 = {:.6}", miss10, miss10 as f64 / 1000.0);
    println!("all 0/1 lists, two errors: misses {} of 8; all 0-9 lists: misses {} of 1000", swap01, swap10);
    println!("fixed list [1, 1, 1], two errors: {}", if passes(&a, &b, &swap, &[1, 1, 1]) { "missed every time" } else { "caught" });
    println!("two runs, all 64 coin strings: misses {} = {:.6}", two_runs, two_runs as f64 / 64.0);
    println!("one list reused for both runs: misses {} of 8 = {:.6}", reused, reused as f64 / 8.0);
    println!("20 fresh 0/1 runs: miss chance at most {}", sci(0.5f64.powi(20)));
    let (mut rng, t) = (SplitMix64 { s: 20261119 }, 100000usize);
    let tf = t as f64;
    let sim01 = (0..t).filter(|_| { let x = rng.draw(&[0, 1]); passes(&a, &b, &wrong, &x) }).count() as f64 / tf;
    let sim10 = (0..t).filter(|_| { let x = rng.draw(&ten); passes(&a, &b, &wrong, &x) }).count() as f64 / tf;
    let sim2 = (0..t).filter(|_| { let x = rng.draw(&[0, 1]); passes(&a, &b, &wrong, &x) && { let y = rng.draw(&[0, 1]); passes(&a, &b, &wrong, &y) } }).count() as f64 / tf;
    println!("simulated {} runs: miss 0/1 {:.5}, 0-9 {:.5}, two 0/1 runs {:.5}", t, sim01, sim10, sim2);
    for m in [100u64, 1000, 10000] {
        println!("side m={}: one check {}, redo {}, 20 checks = {:.2}% of a redo", m, 3 * m * m, m * m * m, (60 * m * m) as f64 / (m * m * m) as f64 * 100.0);
    }
    let (p, eps, delta) = (2.0f64 / 3.0, 1.0f64 / 6.0, 1e-6f64);
    let d = 0.5 * (0.5 / (1.0 - p)).ln() + 0.5 * (0.5 / p).ln();
    println!("two-sided test right with chance 2/3: Chernoff rate D = {:.6}", d);
    println!("runs k, exact vote error, Chernoff bound, Hoeffding bound");
    let mut exact_rows = vec![];
    for k in [1usize, 3, 11, 21, 51, 101, 201] {
        let e = vote_error(p, k);
        exact_rows.push((k, e));
        let kf = k as f64;
        println!("k={}: {} {} {}", k, sci(e), sci((-kf * d).exp()), sci((-2.0 * kf * eps * eps).exp()));
    }
    let k_exact = (1..400).step_by(2).find(|&k| vote_error(p, k) <= delta).unwrap();
    let (k_chern, k_hoef) = (((1.0 / delta).ln() / d).ceil() as usize, ((1.0 / delta).ln() / (2.0 * eps * eps)).ceil() as usize);
    println!("runs for 1 in a million: exact {}, Chernoff {}, Hoeffding {}", k_exact, k_chern, k_hoef);
    let e21 = exact_rows[3].1;
    let votes = (0..t).filter(|_| (0..21).filter(|_| rng.unit() < p).count() < 11).count() as f64 / tf;
    println!("simulated {} votes of 21 runs: wrong {:.5}, exact {:.5}", t, votes, e21);
    for (name, g) in [("1/6", 1.0 / 6.0), ("1/10", 0.1), ("1/100", 0.01), ("2^-20", 2f64.powi(-20)), ("2^-40", 2f64.powi(-40))] {
        let runs = ((1.0 / delta).ln() / (2.0 * g * g)).ceil();
        println!("gap {}: Hoeffding runs for 1 in a million {}", name, if runs < 1e7 { format!("{}", runs as u64) } else { sci(runs) });
    }
    let pp = vote_error(0.5 + 2f64.powi(-20), 101);
    println!("gap 2^-20, majority of 101 runs: wrong {:.6}", pp);
    let chart_k = [1usize, 51, 101, 151, 201, 251, 301];
    println!("chart, runs {}", chart_k.iter().map(|k| k.to_string()).collect::<Vec<_>>().join(" "));
    for (name, q) in [("2/3", 2.0 / 3.0), ("0.6", 0.6), ("0.55", 0.55)] {
        let row: Vec<String> = chart_k.iter().map(|&k| format!("{:.2}", -vote_error(q, k).ln() / 10f64.ln())).collect();
        println!("chart, digits p={} {}", name, row.join(" "));
    }

    assert!(c == [[76, 68, 66], [42, 38, 36], [102, 92, 90]], "table by hand, row by row");
    assert!(right_pass == 8 && miss01 * 2 <= 8 && miss10 * 10 <= 1000, "one-sided: never rejects, misses at most 1/|S|");
    assert!(swap01 * 2 <= 8 && swap10 * 10 <= 1000, "bound holds for an error spread over two entries");
    assert!(two_runs == miss01 * miss01, "fresh lists: two-run misses multiply");
    assert!((sim01 - miss01 as f64 / 8.0).abs() < 4.0 * (0.25 / tf).sqrt() && (sim10 - miss10 as f64 / 1000.0).abs() < 4.0 * (0.09 / tf).sqrt());
    assert!((sim2 - two_runs as f64 / 64.0).abs() < 4.0 * (0.1875 / tf).sqrt(), "simulated pairs against all 64 coin strings");
    for &(k, e) in &exact_rows {
        let direct = binom_sum(k);
        assert!((e - direct).abs() <= 1e-12 * direct, "run-by-run table against the binomial terms");
        let kf = k as f64;
        assert!(e <= (-kf * d).exp() * (1.0 + 1e-12) && (-kf * d).exp() <= (-2.0 * kf * eps * eps).exp(), "truth under both bounds");
    }
    assert!(k_exact <= k_chern && k_chern <= k_hoef);
    assert!((votes - e21).abs() < 4.0 * (e21 * (1.0 - e21) / tf).sqrt());
    assert!(0.49 < pp && pp < 0.5, "a margin of 2^-n, at n = 20, is not amplified by 101 runs");
    println!("ALL CHECKS PASS");
}
