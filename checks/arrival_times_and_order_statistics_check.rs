// Arrival times given the count -- the same check as arrival_times_and_order_statistics_check.py.
// Standard library only, no crates.  Calls reach a switchboard at 4 an hour; exactly 4 came in one hour.
// Road 1: the formula, 4 uniform draws sorted.  Road 2: Poisson counts with independent increments,
// integrated by Simpson's rule.  Road 3: the hour cut into m slots, counted exactly.
// Road 4: two seeded SplitMix64 simulations: exponential gaps, and a Poisson count scattered uniformly.
const LAM: f64 = 4.0;
const T: f64 = 1.0;
const N: usize = 4;
const H: usize = 200000;

fn fact(n: usize) -> f64 { (1..=n).fold(1.0, |a, i| a * i as f64) }
fn comb(n: usize, k: usize) -> u128 {
    if k > n { return 0; }
    let mut c = 1u128;
    for i in 0..k { c = c * (n - i) as u128 / (i + 1) as u128; }
    c
}
fn pois(mu: f64, j: usize) -> f64 { (-mu).exp() * mu.powf(j as f64) / fact(j) }
fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64) -> f64 {
    let m = 600;
    let h = (b - a) / m as f64;
    h / 3.0 * (0..=m).fold(0.0, |s, i| s + (if i == 0 || i == m { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 }) * f(a + i as f64 * h))
}
fn surv_inc(k: usize, s: f64) -> f64 {           // road 2: P(T_k > s | N(1) = 4)
    (0..k).fold(0.0, |a, j| a + pois(LAM * s, j) * pois(LAM * (T - s), N - j)) / pois(LAM * T, N)
}
fn window_inc(j: usize, a: f64, lam: f64) -> f64 { pois(lam * a, j) * pois(lam * (T - a), N - j) / pois(lam * T, N) }
fn dens(k: usize, s: f64, n: usize) -> f64 {     // road 1: density of T_k given n calls, per hour
    fact(n) / (fact(k - 1) * fact(n - k)) * (s / T).powf((k - 1) as f64) * (1.0 - s / T).powf((n - k) as f64) / T
}
struct Rng(u64);
impl Rng {
    fn unif(&mut self) -> f64 {                   // SplitMix64, top 53 bits, never exactly 0 or 1
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        (((z ^ (z >> 31)) >> 11) as f64 + 0.5) / 2f64.powi(53)
    }
}
fn hour_by_gaps(r: &mut Rng) -> (Vec<f64>, bool) {
    let mut ts = vec![];
    let mut s = -r.unif().ln() / LAM;
    while s <= T { ts.push(s); s -= r.unif().ln() / LAM; }
    (ts, false)
}
fn hour_by_scatter(r: &mut Rng) -> (Vec<f64>, bool) {
    let (u, mut n, mut p) = (r.unif(), 0usize, (-LAM * T).exp());
    let mut c = p;
    while u > c { n += 1; p *= LAM * T / n as f64; c += p; }
    let raw: Vec<f64> = (0..n).map(|_| T * r.unif()).collect();
    let mut sorted = raw.clone();
    sorted.sort_by(|a, b| a.partial_cmp(b).unwrap());
    let ordered = raw == sorted;
    (sorted, ordered)
}
fn se(p: f64, n: usize) -> f64 { (p * (1.0 - p) / n as f64).sqrt() }
fn join<T, F: Fn(T) -> String>(it: impl Iterator<Item = T>, f: F) -> String { it.map(f).collect::<Vec<_>>().join(" ") }

fn main() {
    println!("{:<58}{:>10.6}", "density of (T_1..T_4) given 4 calls, 4!/1^4, per hour^4", fact(N) / T.powf(N as f64));
    println!("{:<58}{:>10.6}", "chance of exactly 4 calls in the hour, e^-4 4^4 / 4!", pois(LAM * T, N));
    println!("mean time of call k given 4 calls, minutes   k   k 60/5     from counts");
    let mean_inc: Vec<f64> = (1..=N).map(|k| 60.0 * simpson(|s| surv_inc(k, s), 0.0, T)).collect();
    for k in 1..=N { println!("{:<45}{}{:>11.6}{:>14.6}", "", k, 60.0 * k as f64 / (N + 1) as f64, mean_inc[k - 1]); }
    println!("calls in the first half-hour, given 4       j   C(4,j)/16  counts, rate 4  counts, rate 10");
    for j in 0..=N {
        println!("{:<45}{}{:>11.6}{:>14.6}{:>15.6}", "", j, comb(N, j) as f64 / 16.0, window_inc(j, 0.5, 4.0), window_inc(j, 0.5, 10.0));
    }
    let quarters = pois(LAM / 4.0, 1).powf(4.0) / pois(LAM, N);
    println!("one call in each quarter-hour: 4! (1/4)^4 = {:.6}; from counts {:.6}", fact(N) / 256.0, quarters);
    println!("first quarter-hour empty, given 4: (3/4)^4 = {:.6}; read as one uniform draw {:.6}", 0.75f64.powf(4.0), 0.75);
    println!("slots m   mean first call, min   error      P(2 of 4 in first half)   error");
    let mut slots = vec![];
    for m in [60usize, 600, 6000] {
        let num: u128 = (1..=m).map(|j| j as u128 * comb(m - j, N - 1)).sum();
        let e1 = (60 * num) as f64 / comb(m, N) as f64 / m as f64;
        let h2 = (comb(m / 2, 2) * comb(m / 2, 2)) as f64 / comb(m, N) as f64;
        slots.push(e1 - 12.0);
        println!("{:>7}{:>18.6}{:>13.6}{:>20.6}{:>16.6}", m, e1, e1 - 12.0, h2, h2 - 0.375);
    }

    let mut rng = Rng(20260929);
    let mut stats = vec![];
    for name in ["gaps", "scatter"] {
        let (mut four, mut empty15, mut half2, mut inorder, mut two_first, mut gap20) = (0usize, 0usize, 0usize, 0usize, 0usize, 0usize);
        let (mut s1, mut s2, mut fig) = (vec![0.0f64; N], vec![0.0f64; N], vec![]);
        for _ in 0..H {
            let (ts, ordered) = if name == "gaps" { hour_by_gaps(&mut rng) } else { hour_by_scatter(&mut rng) };
            let firsthalf = ts.iter().filter(|&&t| t <= 0.5).count();
            four += (ts.len() == N) as usize; empty15 += (ts.is_empty() || ts[0] > 0.25) as usize; half2 += (firsthalf == 2) as usize;
            if ts.len() == N {
                inorder += ordered as usize; two_first += (firsthalf == 2) as usize; gap20 += (ts[2] - ts[1] > 1.0 / 3.0) as usize;
                for k in 0..N { s1[k] += 60.0 * ts[k]; s2[k] += (60.0 * ts[k]).powf(2.0); }
                if fig.len() < 5 { fig.push(ts.clone()); }
            }
        }
        stats.push((four, empty15, half2, inorder, two_first, gap20, s1, s2, fig));
    }
    println!("simulation, {} hours each   P(N(1) = 4)    se        P(none by 15 min)  se        P(N(1/2) = 2)  se", H);
    for (i, name) in ["gaps", "scatter"].iter().enumerate() {
        let (f, e, h) = (stats[i].0 as f64 / H as f64, stats[i].1 as f64 / H as f64, stats[i].2 as f64 / H as f64);
        println!("  {:<27}{:>9.6}{:>10.6}{:>15.6}{:>10.6}{:>15.6}{:>10.6}", name, f, se(f, H), e, se(e, H), h, se(h, H));
    }
    println!("  {:<27}{:>9.6}{:>10}{:>15.6}{:>10}{:>15.6}", "formula", pois(LAM, N), "", (-LAM / 4.0).exp(), "", pois(LAM / 2.0, 2));
    let (four, two_first, gap20) = (stats[0].0, stats[0].4, stats[0].5);
    let means: Vec<f64> = stats[0].6.iter().map(|s| s / four as f64).collect();
    let ses: Vec<f64> = stats[0].7.iter().zip(&means).map(|(q, mu)| ((q / four as f64 - mu.powf(2.0)) / four as f64).sqrt()).collect();
    println!("gaps, hours with 4 calls: {}; mean T_1..T_4, minutes {}", four, join(means.iter(), |m| format!("{:.3}", m)));
    println!("  standard errors                                  {}", join(ses.iter(), |x| format!("{:.3}", x)));
    let (p2, pg) = (two_first as f64 / four as f64, gap20 as f64 / four as f64);
    println!("gaps, given 4: P(2 in first half) {:.6} se {:.6}; P(gap 2 to 3 > 20 min) {:.6} se {:.6}", p2, se(p2, four), pg, se(pg, four));
    let (four_b, inorder) = (stats[1].0, stats[1].3);
    let po = inorder as f64 / four_b as f64;
    println!("scatter, given 4: draws already in time order {:.6} se {:.6}; 1/4! = {:.6}", po, se(po, four_b), 1.0 / 24.0);
    let big_l = |s: f64| if s <= 0.5 { 2.0 * s } else { 1.0 + 6.0 * (s - 0.5) };   // rising rate: 2 an hour, then 6
    let rise_counts = pois(1.0, 2) * pois(3.0, 2) / pois(4.0, 4);
    let rise_e1 = 60.0 * simpson(|s| pois(big_l(s), 0) * pois(4.0 - big_l(s), 4) / pois(4.0, 4), 0.0, T);
    let rise_closed = 60.0 * (0.4 * (1.0 - 0.75f64.powf(5.0)) + 0.75f64.powf(5.0) / 7.5);
    println!("rising rate, given 4: P(2 in first half) from counts {:.6}; binomial, p = 1/4 {:.6}", rise_counts, 6.0 / 16.0 * 9.0 / 16.0);
    println!("rising rate, given 4: mean first call, minutes: Simpson {:.6}; closed form {:.6}", rise_e1, rise_closed);
    let grid: Vec<f64> = (0..13).map(|i| 5.0 * i as f64).collect();
    println!("chart, minute          {}", join(grid.iter(), |g| format!("{:>5}", *g as i64)));
    for k in [1usize, 4] {
        println!("chart, T_{} %/min       {}", k, join(grid.iter(), |g| format!("{:5.2}", 100.0 * dens(k, g / 60.0, N) / 60.0)));
    }
    println!("chart, one call %/min   {}", join(grid.iter(), |g| format!("{:5.2}", 100.0 * dens(1, g / 60.0, 1) / 60.0)));
    println!("chart, first half j %   {}", join(0..=N, |j| format!("{:5.2}", 100.0 * comb(N, j) as f64 / 16.0)));
    for (i, ts) in stats[0].8.iter().enumerate() {   // the first five simulated hours with exactly 4 calls; svg x = 60 + 4.5 m
        println!("figure, hour {}, minutes {};  x {}", i + 1, join(ts.iter(), |t| format!("{:5.2}", 60.0 * t)), join(ts.iter(), |t| format!("{:5.1}", 60.0 + 270.0 * t)));
    }
    println!("try: 8 calls, mean first call {:.6} min; first quarter empty {:.6}; gap 2 to 3 > 20 min, 4 calls {:.6}",
             60.0 / 9.0, 0.75f64.powf(8.0), (2.0f64 / 3.0).powf(4.0));

    assert!((1..=N).all(|k| (mean_inc[k - 1] - 60.0 * k as f64 / (N + 1) as f64).abs() < 1e-6), "means: counts vs sorted uniforms");
    assert!((0..=N).all(|j| [4.0, 10.0].iter().all(|&l| (window_inc(j, 0.5, l) - comb(N, j) as f64 / 16.0).abs() < 1e-12)), "binomial");
    assert!((quarters - fact(N) / 256.0).abs() < 1e-12, "one call per quarter: counts vs n! times the volume");
    assert!(slots[0] > slots[1] && slots[1] > slots[2] && slots[2] > 0.0 && slots[2].abs() < 0.003, "slot error shrinks");
    assert!((means[0] - 12.0).abs() < 4.0 * ses[0] && (means[3] - 48.0).abs() < 4.0 * ses[3], "gap recipe: mean first and last call");
    assert!((p2 - 0.375).abs() < 4.0 * se(0.375, four) && (pg - (2.0f64 / 3.0).powf(4.0)).abs() < 4.0 * se(pg, four), "gap recipe, given 4");
    for s in &stats {
        assert!((s.0 as f64 / H as f64 - pois(LAM, N)).abs() < 4.0 * se(pois(LAM, N), H), "P(N = 4), simulated vs formula");
        assert!((s.1 as f64 / H as f64 - (-LAM / 4.0).exp()).abs() < 4.0 * se((-LAM / 4.0).exp(), H), "no call in 15 minutes vs e^-1");
        assert!((s.2 as f64 / H as f64 - pois(LAM / 2.0, 2)).abs() < 4.0 * se(pois(LAM / 2.0, 2), H), "2 calls in the first half-hour");
    }
    assert!((po - 1.0 / 24.0).abs() < 4.0 * se(1.0 / 24.0, four_b), "unsorted draws already in order 1 time in 4!");
    assert!((rise_counts - 54.0 / 256.0).abs() < 1e-12 && (rise_e1 - rise_closed).abs() < 1e-6, "rising rate, two roads");
    println!("ALL CHECKS PASS");
}
