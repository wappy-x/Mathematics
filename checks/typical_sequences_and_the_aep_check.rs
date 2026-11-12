// Typical sequences -- the same check as the Python, in Rust.  No crates.  A
// weather station sends one reading a day: sunny (chance 1/2), cloudy (1/4),
// rain (1/8) or snow (1/8), days independent.  A record is N = 1,000 readings.
// Surprise of one reading: s = -log2 p, so 1, 2, 3, 3 bits.
// Typical set: the records whose surprise per day is within EPS of H.
use std::collections::BTreeMap;
const P: [f64; 4] = [0.5, 0.25, 0.125, 0.125];
const S: [i64; 4] = [1, 2, 3, 3];
const N: usize = 1000;
const EPS: f64 = 0.05;

fn typical(l: usize, n: usize) -> bool {   // |L/n - 1.75| <= 0.05, in whole numbers
    (20 * l as i64 - 35 * n as i64).abs() <= n as i64
}
fn lse(xs: &[f64]) -> f64 {                 // log2 of a sum of 2^x, without overflow
    let m = xs.iter().cloned().fold(f64::NEG_INFINITY, f64::max);
    m + xs.iter().fold(0.0, |a, x| a + 2f64.powf(x - m)).log2()
}
fn smallest(dist: &[f64], share: f64) -> f64 {   // most likely records first, the last level in part
    let (mut acc, mut l, mut logs) = (0.0, 0usize, Vec::new());
    while acc + dist[l] < share {
        if dist[l] > 0.0 { acc += dist[l]; logs.push(dist[l].log2() + l as f64); }
        l += 1;
    }
    logs.push((share - acc).log2() + l as f64);      // (share - acc) x 2^L records of level L
    lse(&logs)
}
fn splitmix(state: &mut u64) -> u64 {
    *state = state.wrapping_add(0x9E3779B97F4A7C15);
    let mut z = (*state ^ (*state >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    z ^ (z >> 31)
}
fn f4(xs: &[f64]) -> String { xs.iter().map(|x| format!("{:.3}", x)).collect::<Vec<_>>().join(", ") }

fn main() {
    let h = P.iter().zip(S.iter()).fold(0.0, |a, (p, s)| a + p * *s as f64);
    let h2 = P.iter().fold(0.0, |a, p| a + -p * p.log2());
    let ms = P.iter().zip(S.iter()).fold(0.0, |a, (p, s)| a + p * *s as f64 * *s as f64);
    let var = ms - h * h;                                   // variance of one surprise
    // Road 1: the law of a record's total surprise, built one day at a time.
    let mut dist = vec![1.0f64];
    let mut by_n: BTreeMap<usize, (f64, f64, f64, Vec<f64>)> = BTreeMap::new();
    for n in 1..=N {
        let mut new = vec![0.0f64; dist.len() + 3];
        for (l, &v) in dist.iter().enumerate() {
            new[l + 1] += v / 2.0; new[l + 2] += v / 4.0; new[l + 3] += v / 4.0;
        }
        dist = new;
        if n % 100 == 0 || n == 8 {
            let in_a: Vec<usize> = (0..dist.len()).filter(|&l| typical(l, n)).collect();
            let pa = in_a.iter().fold(0.0, |a, &l| a + dist[l]);
            let la = lse(&in_a.iter().map(|&l| dist[l].log2() + l as f64).collect::<Vec<_>>());
            by_n.insert(n, (pa, la, smallest(&dist, 0.95), dist.clone()));
        }
    }
    let (pa, log_a, log95) = (by_n[&N].0, by_n[&N].1, by_n[&N].2);
    let ml = dist.iter().enumerate().fold(0.0, |a, (l, v)| a + l as f64 * v);   // mean and
    let vl = dist.iter().enumerate().fold(0.0, |a, (l, v)| a + (l * l) as f64 * v) - ml * ml;  // variance
    // Road 2: count records by type: a sunny, b cloudy, c wet (rain or snow) days.
    let mut lf = vec![0.0f64];
    for k in 1..=N { let last = lf[k - 1]; lf.push(last + (k as f64).log2()); }
    let (mut terms, mut pa2) = (Vec::new(), 0.0f64);
    for b in 0..=N {
        for c in 0..=(N - b) {
            let l = N + b + 2 * c;
            if typical(l, N) {
                let lc = lf[N] - lf[N - b - c] - lf[b] - lf[c] + c as f64;
                terms.push(lc); pa2 += 2f64.powf(lc - l as f64);
            }
        }
    }
    let log_a2 = lse(&terms);
    // Road 3: every record of 8 days, all 65,536 of them, listed and tested.
    let (mut cnt8, mut p8) = (0u64, 0.0f64);
    for code0 in 0..4usize.pow(8) {
        let (mut code, mut l, mut pr) = (code0, 0i64, 1.0f64);
        for _ in 0..8 { l += S[code % 4]; pr *= P[code % 4]; code /= 4; }
        if typical(l as usize, 8) { cnt8 += 1; p8 += pr; }
    }
    let (pa8, log_a8) = (by_n[&8].0, by_n[&8].1);
    // Road 4: simulate 2,000 records of 1,000 days with SplitMix64, seed 2026.
    let cost: [usize; 8] = [1, 1, 1, 1, 2, 2, 3, 3];   // top 3 bits
    let (runs, mut hits, mut tot, mut state) = (2000usize, 0usize, 0usize, 2026u64);
    for _ in 0..runs {
        let mut l = 0;
        for _ in 0..N { l += cost[(splitmix(&mut state) >> 61) as usize]; }
        if typical(l, N) { hits += 1; }
        tot += l;
    }
    let (sim, se) = (hits as f64 / runs as f64, (pa * (1.0 - pa) / runs as f64).sqrt());
    // The converse: the most likely records, up to 2^(N(H - 2 EPS)) of them.
    let room = N as f64 * (h - 2.0 * EPS);
    let (mut logs, mut held): (Vec<f64>, f64) = (Vec::new(), 0.0);
    for l in 0..dist.len() {
        if dist[l] > 0.0 {
            let x = dist[l].log2() + l as f64;
            let mut trial = logs.clone(); trial.push(x);
            if lse(&trial) > room {             // fill up from this total's records
                held += 2f64.powf(room - l as f64) - 2f64.powf(lse(&logs) - l as f64); break;
            }
            logs.push(x); held += dist[l];
        }
    }
    let promise = 2f64.powf(-(N as f64) * EPS) + 1.0 - pa;
    let cheb = 1.0 - var / (N as f64 * EPS * EPS);
    let nf = N as f64;
    let lab = log_a as usize + 1;               // whole bits to number every typical record
    let code = (1 + lab) as f64 * pa + (1 + 2 * N) as f64 * (1.0 - pa);   // flag, then label or raw
    let sunny = N * S[0] as usize;                // total surprise of the all-sunny record
    let stuck = (0..4).filter(|&k| typical(N * S[k] as usize, N)).fold(0.0, |a, k| a + P[k]);  // day 1 repeated

    println!("surprises {:?} bits; entropy H = {:.4} = {:.4} bits a day; mean square {:.4}, variance {:.4}",
             S, h, h2, ms, var);
    println!("records of {} days: 4^{} = 2^{}; typical window {:.2} to {:.2} bits a day, chance 2^-{:.0} to 2^-{:.0}",
             N, N, 2 * N, h - EPS, h + EPS, nf * (h + EPS), nf * (h - EPS));
    println!("centre record, 500 sunny 250 cloudy 125 rain 125 snow: {} bits", 500 * 1 + 250 * 2 + 250 * 3);
    println!("chance a record is typical, road 1 (day by day): {:.4}", pa);
    println!("chance a record is typical, road 2 (by type):    {:.4}", pa2);
    println!("chance a record is typical, road 4 (2,000 runs): {:.4}, standard error {:.4}", sim, se);
    println!("mean surprise per day over the 2,000 runs: {:.4}", tot as f64 / (runs * N) as f64);
    println!("Chebyshev: miss at most {:.4}/({} x {}^2) = {:.4}, floor {:.4}", var, N, EPS, 1.0 - cheb, cheb);
    println!("log2 of the typical set's size, road 1: {:.2}; road 2: {:.2}", log_a, log_a2);
    println!("bounds: {:.2} <= log2 size <= {:.2}", pa.log2() + nf * (h - EPS), nf * (h + EPS));
    println!("typical share of all records: 2^{:.1}", log_a - 2.0 * nf);
    println!("8 days: {} listed, {} typical (total {} bits), chance {:.4}; road 1: 2^{:.4} = {:.1}, chance {:.4}",
             4usize.pow(8), cnt8, 7 * 8 / 4, p8, log_a8, 2f64.powf(log_a8), pa8);
    println!("code: 1 flag bit + {}-bit label, else 1 + {} raw bits: {:.1} bits on average, {:.4} a day",
             lab, 2 * N, code, code / nf);
    println!("smallest set holding 95%: log2 size {:.2}, {:.4} bits a day", log95, log95 / nf);
    println!("most likely 2^{:.0} records hold {:.6}; promise at most 2^-{:.0} + {:.4} = {:.4}",
             room, held, nf * EPS, 1.0 - pa, promise);
    println!("mistake, all-sunny record: chance 2^-{}, {:.2} bits a day, typical: {}", sunny, sunny as f64 / nf,
             if typical(sunny, N) { "yes" } else { "no" });
    println!("mistake, stuck station: {:.2}, {:.2} or {:.2} bits a day, typical chance {:.4}",
             S[0] as f64, S[1] as f64, S[2] as f64, stuck);
    println!("mistake, natural log: {:.4} a day, 2^{:.0}; 2^{:.0} read as the count: short by 2^{:.1}",
             h * 0.6931471805599453, nf * h * 0.6931471805599453, nf * h, log_a - nf * h);
    println!("chance by surprise per day, bins centred 1.50, 1.55, ..., 2.00:");
    for n in [100usize, 1000] {
        let dd = &by_n[&n].3;
        let row: Vec<f64> = (30..41usize).map(|k| (0..dd.len())
            .filter(|&l| (2 * k - 1) * n <= 40 * l && 40 * l < (2 * k + 1) * n)
            .fold(0.0, |a, l| a + dd[l])).collect();
        println!("n = {}: {}", n, f4(&row));
    }
    println!("n, chance typical, Chebyshev floor, bits a day: typical set, smallest 95% set");
    for n in (100..=N).step_by(100) {
        let t = &by_n[&n];
        let fl = f64::max(0.0, 1.0 - var / (n as f64 * EPS * EPS));
        println!("{}, {:.4}, {:.4}, {:.4}, {:.4}", n, t.0, fl, t.1 / n as f64, t.2 / n as f64);
    }

    assert!(S.iter().zip(P.iter()).all(|(s, p)| *s as f64 == -p.log2()) && (h - h2).abs() < 1e-12);
    assert!((ml / nf - h).abs() < 1e-9 && (vl / nf - var).abs() < 1e-9);   // mean and variance add up
    assert!((pa - pa2).abs() < 1e-9 && (log_a - log_a2).abs() < 1e-6);   // road 1 meets road 2
    assert!(cnt8 == 2f64.powf(log_a8).round() as u64 && (p8 - pa8).abs() < 1e-12);
    assert!((sim - pa).abs() < 4.0 * se);                                 // road 4, the simulation
    assert!(cheb <= pa && pa.log2() + nf * (h - EPS) <= log_a && log_a <= nf * (h + EPS));
    assert!(held <= promise && log95 < log_a);                            // the converse
    assert!(!typical(sunny, N) && stuck == 0.0);                          // broken hypotheses: not typical
    println!("ALL CHECKS PASS");
}
