// Fatou's lemma -- the same check as the Python, in Rust.  No crates.
// A spotlight on a 1 m stage: frame n lights the strip [1 - 1/n, 1) at
// brightness n watts per metre, so every frame carries 1 W, yet every seat
// goes dark for good.  Road one counts lit grid cells in whole numbers; road
// two is the formula.  Then the running infimum under house lights that fade
// up, by a closed-form series and by brute force over frames; the smallest
// roof, whose area is a harmonic sum; the flicker under a roof of 2; and the
// shadow that breaks the sign rule.
const M: i64 = 10_000; // grid cells, 0.1 mm each
const J: i64 = 1000; // strips [1 - 1/j, 1 - 1/(j + 1)), j = 1..J, then a leftover sliver

fn lit(n: i64, p: i64, q: i64) -> bool {
    // is the seat at p/q m lit in frame n?  p/q >= 1 - 1/n
    p * n >= q * (n - 1)
}

fn light(n: i64, cells: i64, sign: f64) -> f64 {
    // watts on the first `cells` grid cells in frame n
    let hit = (0..cells).filter(|&i| lit(n, 2 * i + 1, 2 * M)).count() as f64;
    sign * n as f64 * hit / M as f64
}

fn house(n: i64) -> f64 {
    // house lights fading up, W/m, the same at every seat
    0.5 * (1.0 - 1.0 / n as f64)
}

fn by_series(k: i64) -> f64 {
    // g_k = house(k) left of 1 - 1/k, house(j + 1) on strip j >= k
    let head: f64 = (1..=k).map(|m| 1.0 / (m * m) as f64).sum();
    let tail = std::f64::consts::PI.powi(2) / 6.0 - head;
    0.5 * (1.0 - 1.0 / k as f64).powi(2) + 0.5 * tail
}

fn by_brute(k: i64) -> (f64, f64) {
    let mut s = 0.0;
    for j in 1..=J {
        // every frame from k up to a few past the strip's last lit one
        let low = (k..k.max(j) + 6)
            .map(|n| house(n) + if lit(n, j - 1, j) { n as f64 } else { 0.0 })
            .fold(f64::INFINITY, f64::min);
        s += low / (j * (j + 1)) as f64;
    }
    (s + house(k) / (J + 1) as f64, s + 0.5 / (J + 1) as f64)
}

fn main() {
    println!("frame n lights [1 - 1/n, 1) at brightness n W/m");
    for n in [1i64, 2, 4, 10, 100, 1000] {
        let (total, part) = (light(n, M, 1.0), light(n, 9 * M / 10, 1.0));
        println!("frame {:>4}: strip from {:.4} m, total {:.4} W, on [0, 0.9] m {:.4} W", n, 1.0 - 1.0 / n as f64, total, part);
        assert!((total - 1.0).abs() < 1e-12); // grid count against n x (1/n)
        assert!((part - (1.0 - 0.1 * n as f64).max(0.0)).abs() < 1e-12); // against the overlap formula
    }
    for (p, q) in [(1i64, 2i64), (9, 10), (99, 100), (999, 1000)] {
        let last = (1..=100_000).filter(|&n| lit(n, p, q)).max().unwrap(); // brute force over 100000 frames
        println!("seat {:.4} m: lit in frames 1 to {}, brightness climbs to {} W/m, then dark from frame {} on", p as f64 / q as f64, last, last, last + 1);
        assert!(last == q / (q - p)); // against n <= 1/(1 - x)
        assert!((1..=last).all(|n| lit(n, p, q))); // lit in every frame up to the last
    }
    let dark = light(2 * M + 1, M, 1.0); // every grid seat (at most 0.99995 m) is dark for good from frame 2M + 1 on
    println!("spotlight: integral of lim inf = {:.4} W, lim inf of the integrals = {:.4} W, lost {:.4} W", dark, light(1000, M, 1.0), light(1000, M, 1.0) - dark);

    // the proof on the stage: f_n = house(n) + spotlight; g_k = inf over n >= k of f_n
    println!("k, integral of g_k by series, by brute force (bracket), inf of integrals from frame k on");
    let (mut prev, mut rows) = (0.0f64, Vec::new());
    for k in 1..=8i64 {
        let (a, (lo, hi)) = (by_series(k), by_brute(k));
        let rhs = (k..k + 4).map(|n| house(n) + 1.0).fold(f64::INFINITY, f64::min); // integral of f_n is house(n) + 1 W
        println!("k = {}: {:.4}, {:.4} to {:.4}, {:.4}", k, a, lo, hi, rhs);
        assert!(lo - 1e-12 <= a && a <= hi + 1e-12); // two roads to the integral of g_k
        assert!(prev <= a && a <= rhs); // g_k rises, and sits below every later integral
        prev = a;
        rows.push(a);
    }
    for k in [100i64, 10_000] {
        println!("k = {}: integral of g_k {:.4}", k, by_series(k));
    }
    let tail3: f64 = (4..=2_000_000i64).map(|m| 1.0 / (m as f64 * m as f64)).sum(); // summed directly, not from pi^2/6
    println!("k = 3 by hand: floor {:.4} W/m on [0, {:.4}) m, area {:.4}; sum of 1/m^2 from m = 4 is {:.4}, half of it {:.4}",
             house(3), 1.0 - 1.0 / 3.0, house(3) * (1.0 - 1.0 / 3.0), tail3, 0.5 * tail3);
    assert!((house(3) * (1.0 - 1.0 / 3.0) + 0.5 * tail3 - by_series(3)).abs() < 1e-6);
    println!("with house lights, read at k = 1000000: integral of lim inf = {:.4} W, lim inf of the integrals = {:.4} W", by_series(1_000_000), 1.0 + house(1_000_000));
    let fmt = |v: Vec<f64>| v.iter().map(|a| format!("{:.2}", a)).collect::<Vec<_>>().join(", ");
    println!("chart, integral of g_k to 2 places: {}", fmt(rows));
    println!("chart, inf of integrals to 2 places: {}", fmt((1..=8).map(|k| 1.0 + house(k)).collect()));

    // the smallest roof over every frame: sup_n f_n = j on strip j
    for jr in [10i64, 100, 1000, 1_000_000] {
        let formula: f64 = (1..=jr).map(|j| 1.0 / (j + 1) as f64).sum();
        if jr <= 1000 {
            let brute: f64 = (1..=jr)
                .map(|j| (1..j + 6).filter(|&n| lit(n, j - 1, j)).max().unwrap() as f64 / (j * (j + 1)) as f64)
                .sum();
            assert!((brute - formula).abs() < 1e-9);
        }
        assert!(formula >= ((jr + 2) as f64 / 2.0).ln());
        println!("roof over [0, {:.6}) m: area {:.4} W", 1.0 - 1.0 / (jr + 1) as f64, formula);
    }

    // flicker: odd frames 2 W/m on [0, 0.5), even frames 2 W/m on [0.5, 1); roof G = 2
    let odd: Vec<i64> = (0..M).map(|i| if i < M / 2 { 2 } else { 0 }).collect();
    let even: Vec<i64> = odd.iter().map(|v| 2 - v).collect();
    let area = |row: &[i64]| row.iter().sum::<i64>() as f64 / M as f64;
    let low: Vec<i64> = odd.iter().zip(&even).map(|(a, b)| *a.min(b)).collect();
    let high: Vec<i64> = odd.iter().zip(&even).map(|(a, b)| *a.max(b)).collect();
    let chain = [area(&low), area(&odd).min(area(&even)), area(&odd).max(area(&even)), area(&high)];
    let shown: Vec<String> = chain.iter().map(|v| format!("{:.4}", v)).collect();
    println!("flicker: {}, roof area {:.4}", shown.join(" <= "), area(&vec![2; M as usize]));
    assert!(chain == [0.0, 1.0, 1.0, 2.0]);

    // what breaks
    println!("breaks, reverse Fatou with no roof: lim sup of integrals {:.4} > integral of lim sup {:.4}", light(1000, M, 1.0), dark);
    let shadow = light(1000, M, -1.0);
    println!("breaks, shadow of depth n: integral of lim inf {:.4} > lim inf of integrals {:.4}", dark, shadow);
    assert!(dark > shadow);
    println!("breaks, equality claimed: {:.4} W predicted for the limit, {:.4} W there", light(1000, M, 1.0), dark);
    let fig: Vec<String> = [1i64, 2, 4].iter()
        .map(|&n| format!("frame {}: {:.1} to {:.1}, top {:.1}", n, 40.0 + 280.0 * (1.0 - 1.0 / n as f64), 40.0 + 280.0 * 1.0, 200.0 - 40.0 * n as f64))
        .collect();
    println!("figure, x = 40 + 280 x, y = 200 - 40 brightness; {}", fig.join("; "));
    println!("ALL CHECKS PASS");
}
