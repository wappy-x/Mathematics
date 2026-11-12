// Tail bounds and repeated trials: the check behind the card. std only, no crates.
// Roads to each answer: a closed-form bound; an exact count (all 8 random lists, or
// a binomial sum term by term); a seeded SplitMix64 simulation of the real runs.
const MISS: f64 = 0.5; // one-sided check: chance one run misses a wrong product
const P_RIGHT: f64 = 0.75; // two-sided test: chance one run gives the right answer
const DELTA: f64 = 1e-6; // failure chance allowed
const USES: f64 = 10_000_000.0; // requests a day at the web service
const EPS: f64 = 0.01; // error allowance on an estimated share
const SEED: u64 = 2026;
const TRIALS: usize = 100_000;
type M3 = [[i64; 3]; 3];
const A: M3 = [[2, 1, 0], [1, 3, 1], [0, 1, 2]];
const B: M3 = [[1, 2, 1], [0, 1, 3], [2, 0, 1]];

fn splitmix(s: &mut u64) -> u64 {
    *s = s.wrapping_add(0x9E3779B97F4A7C15);
    let mut z = (*s ^ (*s >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    z ^ (z >> 31)
}
fn sci(x: f64) -> String {
    let mut e = x.log10().floor();
    let mut m = x / 10f64.powf(e);
    if m >= 9.995 { m /= 10.0; e += 1.0; }
    format!("{:.2}e{}", m, e as i64)
}
fn grp(n: u64) -> String { // thousands separators, like Python's {:,}
    let s = n.to_string();
    s.chars().enumerate().map(|(i, c)| if i > 0 && (s.len() - i) % 3 == 0 { format!(",{}", c) } else { c.to_string() }).collect()
}
fn mul(x: &M3, y: &M3) -> M3 {
    let mut r = [[0; 3]; 3];
    for i in 0..3 { for j in 0..3 { for t in 0..3 { r[i][j] += x[i][t] * y[t][j]; } } }
    r
}
fn mv(x: &M3, v: &[i64; 3]) -> [i64; 3] {
    let mut r = [0; 3];
    for i in 0..3 { for t in 0..3 { r[i] += x[i][t] * v[t]; } }
    r
}
fn bits(z: u64) -> [i64; 3] { [(z & 1) as i64, ((z >> 1) & 1) as i64, ((z >> 2) & 1) as i64] }
fn catches(c: &M3, x: &[i64; 3]) -> bool { mv(&A, &mv(&B, x)) != mv(c, x) } // Freivalds' check, one run

fn tail(k: usize, q: f64) -> f64 { // exact chance that a majority of k runs (k odd) are wrong
    let mut pmf = 1.0;
    for _ in 0..k { pmf *= 1.0 - q; }
    let mut total = 0.0;
    for w in 0..=k {
        if 2 * w > k { total += pmf; }
        pmf *= (k - w) as f64 / (w + 1) as f64 * q / (1.0 - q);
    }
    total
}
fn tail_dp(k: usize, q: f64) -> f64 { // second road: the law of the wrong count, built up one run at a time
    let mut d = vec![1.0];
    for _ in 0..k { d = (0..=d.len()).map(|w| (if w < d.len() { d[w] * (1.0 - q) } else { 0.0 }) + (if w > 0 { d[w - 1] * q } else { 0.0 })).collect(); }
    d[(k + 1) / 2..].iter().sum()
}
fn kl(a: f64, b: f64) -> f64 { a * (a / b).ln() + (1.0 - a) * ((1.0 - a) / (1.0 - b)).ln() }
fn runs_formula(n_uses: f64, delta: f64, rate: f64) -> usize { ((n_uses / delta).ln() / rate).ceil() as usize }
fn runs_exact(q: f64, target: f64) -> usize {
    let mut k = 1;
    while tail(k, q) > target { k += 2; }
    k
}
fn runs_one_sided(miss: f64, target: f64) -> usize { // brute force: run by run
    let (mut k, mut left) = (0, 1.0);
    while left > target { k += 1; left *= miss; }
    k
}

fn main() {
    // ---- one-sided: the check itself, every random list, and the cost ----
    let good = mul(&A, &B);
    let mut bad = good;
    bad[1][2] += 1; // one entry off by one
    let caught = (0..8u64).filter(|&v| catches(&bad, &bits(v))).count();
    let false_alarm = (0..8u64).filter(|&v| catches(&good, &bits(v))).count();
    println!("wrong product caught by {} of 8 lists; right product flagged by {} of 8", caught, false_alarm);
    let size: u64 = 1000;
    let rate1 = (1.0 / MISS).ln();
    for k in [1, 2, 10, 20, 44] {
        println!("one-sided, {:2} runs: miss chance {}, about 1 in {}", k, sci(MISS.powi(k)), grp(MISS.powi(-k).round() as u64));
    }
    let (k1, kday) = (runs_formula(1.0, DELTA, rate1), runs_formula(USES, DELTA, rate1));
    let (l1, ln_day) = ((1.0 / DELTA).ln(), (USES / DELTA).ln());
    println!("one-sided runs for 1 in a million: per request {:.2} / {:.4} = {:.2} -> {}, whole day {:.2} / {:.4} = {:.2} -> {}, {} more", l1, rate1, l1 / rate1, k1, ln_day, rate1, ln_day / rate1, kday, kday - k1);
    println!("cost on {}x{}: one check {}, redo {}; {} checks {:.1}% of a redo, {} checks {:.1}%", size, size, grp(3 * size * size), grp(size * size * size), k1, 100.0 * 3.0 * k1 as f64 / size as f64, kday, 100.0 * 3.0 * kday as f64 / size as f64);
    println!("one-sided runs at miss chance 0.25 per run: {}", runs_formula(1.0, DELTA, 4f64.ln()));

    // ---- seeded simulation of the real check: fresh list each run, then one list reused ----
    let (mut s, mut fresh, mut reused) = (SEED, 0usize, 0usize);
    for _ in 0..TRIALS {
        let mut hit = false;
        for _ in 0..4 { let z = splitmix(&mut s); hit = hit || catches(&bad, &bits(z)); }
        if !hit { fresh += 1; }
        let z = splitmix(&mut s);
        if !catches(&bad, &bits(z)) { reused += 1; } // same list, 4 times: one answer
    }
    let tr = TRIALS as f64;
    println!("simulated, 4 runs, fresh lists: miss {:.4} (exact {:.4})", fresh as f64 / tr, MISS.powi(4));
    println!("simulated, 4 runs, one list reused: miss {:.4}", reused as f64 / tr);

    // ---- two-sided: majority vote, exact against every bound ----
    let (q, gap) = (1.0 - P_RIGHT, P_RIGHT - 0.5);
    let d = kl(0.5, q);
    let cheb = |k: f64| f64::min(1.0, P_RIGHT * q / (k * gap * gap)); // Chebyshev: variance k p q over distance (k eps)^2
    println!("two-sided, right {} per run: Chernoff rate D = {:.4}, Hoeffding rate 2 eps^2 = {:.4}", P_RIGHT, d, 2.0 * gap * gap);
    println!("Markov on the count of wrong votes: {:.2} at every number of runs", q / 0.5);
    println!(" runs   exact      Chernoff   Hoeffding  Chebyshev");
    for k in [1usize, 9, 21, 41, 81, 121] {
        let kf = k as f64;
        let (ex, ch, ho) = (tail(k, q), (-kf * d).exp(), (-2.0 * kf * gap * gap).exp());
        let cb = cheb(kf);
        println!("{:5}   {:9}  {:9}  {:9}  {}", k, sci(ex), sci(ch), sci(ho), sci(cb));
        assert!(ex <= ch && ch <= ho && ex <= cb && (tail_dp(k, q) / ex - 1.0).abs() < 1e-9); // every bound bounds; two roads agree
    }
    let (kc, kh, ke) = (runs_formula(1.0, DELTA, d), runs_formula(1.0, DELTA, 2.0 * gap * gap), runs_exact(q, DELTA));
    let kcheb = (P_RIGHT * q / (gap * gap * DELTA)).ceil() as u64;
    println!("runs for 1 in a million: Chebyshev {}, Hoeffding {}, Chernoff {}, exact {}", grp(kcheb), kh, kc, ke);
    println!("exact at {} runs {}, at {} runs {}, at {} runs {}", ke - 2, sci(tail(ke - 2, q)), ke, sci(tail(ke, q)), kc, sci(tail(kc, q)));
    println!("Chernoff quotients {:.2} and {:.2}; whole day: Chernoff {}, exact {}", l1 / d, ln_day / d, runs_formula(USES, DELTA, d), runs_exact(q, DELTA / USES));
    let d3 = kl(0.5, 1.0 / 3.0);
    println!("at right 2/3 per run: Chernoff {}, exact {}", runs_formula(1.0, DELTA, d3), runs_exact(1.0 / 3.0, DELTA));

    let (mut s, mut wrong) = (SEED, 0usize);
    for _ in 0..TRIALS {
        let mut bad_votes = 0;
        for _ in 0..9 { if splitmix(&mut s) >> 62 == 0 { bad_votes += 1; } } // wrong with chance 1/4
        if bad_votes >= 5 { wrong += 1; }
    }
    println!("simulated majority of 9: wrong {:.4} (exact {:.4})", wrong as f64 / tr, tail(9, q));

    // ---- many uses: the union bound ----
    let d20 = MISS.powi(20);
    let p_any = -(USES * (-d20).ln_1p()).exp_m1(); // 1 - (1 - d20)^USES, exactly
    println!("20 runs, {} requests: union bound {:.2}, chance of at least one miss {:.5}", grp(USES as u64), USES * d20, p_any);
    println!("{} runs, {} requests: union bound {}", kday, grp(USES as u64), sci(USES * MISS.powi(kday as i32)));

    // ---- the same recipe for an estimate ----
    let n_est = ((2.0 / DELTA).ln() / (2.0 * EPS * EPS)).ceil();
    println!("samples to know a share within {} except 1 in a million: {}; at eps 0.001: {}", EPS, grp(n_est as u64), grp(((2.0 / DELTA).ln() / 2e-6).ceil() as u64));

    // ---- what breaks ----
    println!("what breaks: any-alarm rule on the two-sided test, 20 runs: false alarm {:.4}", 1.0 - P_RIGHT.powi(20));
    println!("what breaks: no margin, right 0.5 per run, majority of 101: wrong {:.4}", tail(101, 0.5));

    // ---- chart: digits of safety, -log10 of the failure chance ----
    let ks = [1usize, 21, 41, 61, 81, 101, 121];
    let row = |f: &dyn Fn(f64) -> f64| ks.iter().map(|&k| format!("{:.2}", f(k as f64))).collect::<Vec<_>>().join(",");
    println!("figure,runs,{}", ks.iter().map(|k| k.to_string()).collect::<Vec<_>>().join(","));
    println!("figure,one-sided,{}", row(&|k| k * (1.0 / MISS).log10()));
    println!("figure,majority exact,{}", row(&|k| -tail(k as usize, q).log10()));
    println!("figure,majority Chernoff,{}", row(&|k| k * d / 10f64.ln()));
    println!("figure,majority Chebyshev,{}", row(&|k| (1.0 / cheb(k)).log10()));

    assert!(caught == 4 && false_alarm == 0 && 1.0 - caught as f64 / 8.0 == MISS); // exhaustive = stated rate
    assert!(k1 == runs_one_sided(MISS, DELTA) && kday == runs_one_sided(MISS, DELTA / USES));
    let m4 = MISS.powi(4);
    assert!((fresh as f64 / tr - m4).abs() < 4.0 * (m4 * (1.0 - m4) / tr).sqrt());
    assert!((reused as f64 / tr - MISS).abs() < 4.0 * (0.25 / tr).sqrt());
    let t9 = tail(9, q);
    assert!((wrong as f64 / tr - t9).abs() < 4.0 * (t9 * (1.0 - t9) / tr).sqrt());
    assert!(tail(kc, q) <= DELTA && tail_dp(ke, q) <= DELTA && DELTA < tail_dp(ke - 2, q) && ke < kc && kc < kh);
    assert!(kcheb == (3.0 / DELTA).round() as u64 && ks[1..].iter().all(|&k| (cheb(k as f64) - 3.0 / k as f64).abs() < 1e-12)); // Chebyshev is 3/k
    assert!((p_any - (1.0 - (-USES * d20).exp())).abs() < 1e-9 && USES * MISS.powi(kday as i32) <= DELTA); // against the Poisson form
    assert!(2.0 * (-2.0 * n_est * EPS * EPS).exp() <= DELTA && DELTA < 2.0 * (-2.0 * (n_est - 1.0) * EPS * EPS).exp());
    assert!((tail(101, 0.5) - 0.5).abs() < 1e-12); // symmetry: a fair vote
    println!("ALL CHECKS PASS");
}
