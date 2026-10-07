// First and second moments -- the same check as the Python, in Rust; no crates.
// A club of 100 members; each pair are friends with chance p, independently.
// X counts triangles: trios of members who are all friends with each other.
// Roads: the formulas for E[X] and Var(X); every friendship pattern of a
// 6-member club enumerated; a seeded simulation of 10,000 clubs per p.
const N: usize = 100;
const TRIALS: usize = 10000;
const SEED: u64 = 20260929;
const PS: [f64; 8] = [0.0025, 0.005, 0.01, 0.015, 0.02, 0.03, 0.04, 0.05];

fn choose(n: u64, k: u64) -> u64 {                // C(n, k), by the multiplicative rule
    let mut out = 1;
    for i in 0..k { out = out * (n - i) / (i + 1) }
    out
}

fn mean_f(n: u64, p: f64) -> f64 { choose(n, 3) as f64 * p.powf(3.0) } // first moment

fn var_f(n: u64, p: f64) -> f64 {                // own terms, then pairs sharing an edge
    let t = choose(n, 3) as f64;
    t * (p.powf(3.0) - p.powf(6.0)) + t * 3.0 * (n - 3) as f64 * (p.powf(5.0) - p.powf(6.0))
}

fn ratio_f(n: u64, p: f64) -> f64 {              // Var/E^2 rewritten by hand, a second road
    (1.0 - p.powf(3.0)) / mean_f(n, p) + 3.0 * (n - 3) as f64 * (1.0 - p) / (choose(n, 3) as f64 * p)
}

fn splitmix64(s: u64) -> (u64, u64) {            // the generator both languages share
    let s = s.wrapping_add(0x9E3779B97F4A7C15);
    let z = (s ^ (s >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    let z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    (s, z ^ (z >> 31))
}

fn row(label: &str, v: f64) { println!("{:<50} {:>12.6}", label, v) }

fn enum6(tally: &[((u32, u32), u64)], p: f64) -> (f64, f64, f64) { // exact E, Var, P(X = 0)
    let w: Vec<(u32, f64)> = tally.iter()
        .map(|&((e, t), c)| (t, c as f64 * p.powf(e as f64) * (1.0 - p).powf((15 - e) as f64))).collect();
    let m: f64 = w.iter().map(|&(t, v)| v * t as f64).sum();
    let m2: f64 = w.iter().map(|&(t, v)| v * (t * t) as f64).sum();
    (m, m2 - m * m, w.iter().filter(|&&(t, _)| t == 0).map(|&(_, v)| v).sum())
}

fn main() {
    // ---- road 2: every friendship pattern of a 6-member club, 2^15 of them ----
    let mut bit = [[0u32; 6]; 6];
    let mut k = 0;
    for i in 0..6 { for j in i + 1..6 { bit[i][j] = 1 << k; k += 1 } }
    let mut trios6 = Vec::new();
    for a in 0..6 { for b in a + 1..6 { for c in b + 1..6 { trios6.push(bit[a][b] | bit[a][c] | bit[b][c]) } } }
    let mut tally: Vec<((u32, u32), u64)> = Vec::new();  // (friendships, triangles) -> patterns
    for mask in 0u32..1 << 15 {
        let key = (mask.count_ones(), trios6.iter().filter(|&&t| mask & t == t).count() as u32);
        match tally.iter_mut().find(|e| e.0 == key) { Some(e) => e.1 += 1, None => tally.push((key, 1)) }
    }
    let share2 = trios6.iter().map(|s| trios6.iter().filter(|&&t| (s & t).count_ones() == 1).count()).sum::<usize>();
    let n = N as u64;
    println!("club n = {}: pairs {}, trios C(100,3) = {}", N, choose(n, 2), choose(n, 3));
    let mut split = [0u64; 4];                    // trios meeting trio {0,1,2} in 0..3 members
    for a in 0..N { for b in a + 1..N { for c in b + 1..N {
        split[(a < 3) as usize + (b < 3) as usize + (c < 3) as usize] += 1 } } }
    println!("trios sharing 0 / 1 / 2 members with one trio: {} {} {}; 3(n-3) = {}", split[0], split[1], split[2], 3 * (N - 3));
    println!("6 members: trio pairs sharing an edge, counted {}, formula C(6,3)*3*3 = {}", share2, choose(6, 3) * 9);
    for p in [0.2f64, 0.6] {
        let (m, v, z) = enum6(&tally, p);
        println!("6 members, p = {}: E formula {:.6} counted {:.6}; Var formula {:.6} counted {:.6}", p, mean_f(6, p), m, var_f(6, p), v);
        println!("6 members, p = {}: P(X>=1) {:.6} <= Markov {:.6}; P(X=0) {:.6} <= Chebyshev {:.6}",
                 p, 1.0 - z, mean_f(6, p), z, var_f(6, p) / mean_f(6, p).powf(2.0));
    }
    let mut worst6: f64 = 0.0;
    for k in 1..100 {                             // both bounds, 99 values of p, n = 6
        let (m, v, z) = enum6(&tally, k as f64 / 100.0);
        worst6 = worst6.max((1.0 - z) - m).max(z - v / (m * m));
    }

    // ---- the worked numbers, n = 100 ----
    for p in [0.005f64, 0.05] {
        println!("p = {}: p^3 = {:.9}", p, p.powf(3.0));
        row(&format!("p = {}: E[X] = C(100,3) p^3", p), mean_f(n, p));
        row(&format!("p = {}: Paley-Zygmund floor E^2/(E^2 + Var)", p), mean_f(n, p).powf(2.0) / (mean_f(n, p).powf(2.0) + var_f(n, p)));
    }
    let p: f64 = 0.05;
    row("p = 0.05: own part C(100,3)(p^3 - p^6)", choose(n, 3) as f64 * (p.powf(3.0) - p.powf(6.0)));
    row("p = 0.05: shared-edge part 161700*291*(p^5 - p^6)", (choose(n, 3) * 3 * (n - 3)) as f64 * (p.powf(5.0) - p.powf(6.0)));
    row("p = 0.05: Var(X)", var_f(n, p));
    row("p = 0.05: Chebyshev Var/E^2", var_f(n, p) / mean_f(n, p).powf(2.0));
    row("p = 0.05: same, by the simplified ratio", ratio_f(n, p));

    // ---- road 3: 10,000 simulated clubs per p, friendships by geometric skips ----
    let mut pairs = Vec::new();
    for i in 0..N { for j in i + 1..N { pairs.push((i, j)) } }
    let (mut state, mut sims) = (SEED, Vec::new());
    for &p in PS.iter() {
        let lq = (1.0 - p).ln();
        let (mut zero, mut s1, mut s2, mut s3, mut s4) = (0usize, 0u64, 0u64, 0u64, 0u64);
        for _ in 0..TRIALS {
            let (mut adj, mut pos, mut edges) = (vec![0u128; N], -1i64, Vec::new());
            loop {                                // jump straight to the next friendship
                let (s, z) = splitmix64(state);
                state = s;
                pos += 1 + ((((z >> 11) + 1) as f64 * 2f64.powi(-53)).ln() / lq).floor() as i64;
                if pos >= pairs.len() as i64 { break }
                let (i, j) = pairs[pos as usize];
                edges.push((i, j));
                adj[i] |= 1u128 << j;
                adj[j] |= 1u128 << i;
            }
            let x: u64 = edges.iter().map(|&(i, j)| ((adj[i] & adj[j]) >> (j + 1)).count_ones() as u64).sum();
            if x == 0 { zero += 1 }
            s1 += x; s2 += x * x; s3 += x.pow(3); s4 += x.pow(4);
        }
        let tr = TRIALS as f64;
        let (q, m) = (1.0 - zero as f64 / tr, s1 as f64 / tr);
        let v = (s2 as f64 - (s1 * s1) as f64 / tr) / (tr - 1.0);
        let m4 = (s4 as f64 - 4.0 * m * s3 as f64 + 6.0 * m * m * s2 as f64) / tr - 3.0 * m.powf(4.0);
        sims.push((p, q, (q * (1.0 - q) / tr).sqrt(), m, (v / tr).sqrt(), v, ((m4 - v * v).max(0.0) / tr).sqrt()));
    }
    println!("exact,      p  c = np      E[X]     Var(X)  Var/E^2  Markov cap  Chebyshev floor  1-exp(-E)");
    for &p in PS.iter() {
        let (e, v) = (mean_f(n, p), var_f(n, p));
        println!("exact, {:>6} {:>7.4} {:>10.4} {:>10.4} {:>8.4} {:>11.4} {:>16.4} {:>10.4}",
                 p, N as f64 * p, e, v, v / e / e, e.min(1.0), (1.0 - v / e / e).max(0.0), 1.0 - (-e).exp());
    }
    println!("sim,        p  P(X>=1)     s.e.   mean X    s.e.   var X    s.e.");
    for &(p, q, sq, m, sm, v, sv) in &sims {
        println!("sim,   {:>6}  {:>7.4}  {:>7.4} {:>8.4} {:>7.4} {:>7.4} {:>7.4}", p, q, sq, m, sm, v, sv);
    }
    let join = |f: &dyn Fn(usize) -> f64| (0..PS.len()).map(|i| format!("{:.2}", f(i))).collect::<Vec<_>>().join(" ");
    println!("chart, Markov cap:      {}", join(&|i| mean_f(n, PS[i]).min(1.0)));
    println!("chart, simulated:       {}", join(&|i| sims[i].1));
    println!("chart, Chebyshev floor: {}", join(&|i| (1.0 - var_f(n, PS[i]) / mean_f(n, PS[i]).powf(2.0)).max(0.0)));

    // ---- what breaks ----
    row("wrong: Markov read backwards, E[X] at p = 0.02", mean_f(n, 0.02));
    row("wrong:   simulated P(X>=1) at p = 0.02", sims[4].1);
    let indep = choose(n, 3) as f64 * (p.powf(3.0) - p.powf(6.0));
    row("wrong: shared edges ignored, Var at p = 0.05", indep);
    row("wrong:   its 'bound' Var/E^2", indep / mean_f(n, p).powf(2.0));
    let full: Vec<u128> = (0..N).map(|i| (u128::MAX >> (128 - N)) ^ (1u128 << i)).collect(); // all-or-nothing
    let tfull: u64 = pairs.iter().map(|&(i, j)| ((full[i] & full[j]) >> (j + 1)).count_ones() as u64).sum(); // club
    let (ea, e2a) = (0.1 * tfull as f64, 0.1 * (tfull * tfull) as f64);  // chance 0.1 all friends
    row("wrong: all-or-nothing club, E[X]", ea);
    row("wrong:   its P(X = 0)", 1.0 - 0.1 * (tfull > 0) as u8 as f64);   // the empty club, chance 0.9, has none
    row("wrong:   its Chebyshev Var/E^2", (e2a - ea * ea) / (ea * ea));
    row("6 members, 99 values of p: worst bound overshoot", worst6);
    row("house example, n = 1000, p = 0.001: E[X]", mean_f(1000, 0.001));
    let cy = 190.0 - 60.0 * 3f64.sqrt();
    println!("figure, A (60,190) B (180,190) C (120,{:.0}) D (240,{:.0}), sides 120", cy, cy);

    assert!(split == [choose(n - 3, 3), 3 * choose(n - 3, 2), 3 * (n - 3), 1] && share2 as u64 == choose(6, 3) * 9, "shared-member counts");
    for p in [0.2f64, 0.6] {
        let (m, v, _) = enum6(&tally, p);
        assert!((m - mean_f(6, p)).abs() + (v - var_f(6, p)).abs() < 1e-12, "formula vs every pattern");
    }
    assert!(worst6 <= 1e-12, "Markov and Chebyshev hold on every enumerated club");
    assert!(PS.iter().all(|&p| (var_f(n, p) / mean_f(n, p).powf(2.0) - ratio_f(n, p)).abs() < 1e-12), "two algebra roads");
    for &(p, q, sq, m, sm, v, sv) in &sims {
        assert!((m - mean_f(n, p)).abs() < 4.0 * sm && (v - var_f(n, p)).abs() < 4.0 * sv, "simulation vs formulas");
        assert!(q <= mean_f(n, p) + 4.0 * sq && 1.0 - q <= var_f(n, p) / mean_f(n, p).powf(2.0) + 4.0 * sq, "simulation under both bounds");
    }
    assert!(tfull == choose(n, 3), "every trio of the full club counted as a triangle");
    println!("ALL CHECKS PASS");
}
