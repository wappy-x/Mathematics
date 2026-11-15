// Equivalent norms -- the check behind the card.  Rust std only.
// A shortbread batch: flour, butter, sugar.  Its weighing error is a list of
// three numbers in grams, sized three ways.  Then a week of electricity prices
// cut into N slots, where the sup and average norms stop agreeing as N grows.
type V = (i64, i64, i64);

const AMT: [f64; 3] = [300.0, 200.0, 100.0]; // recipe amounts, grams
const PRICE: [f64; 3] = [0.09, 0.8, 0.1]; // pence per gram, illustrative
const NAMES: [&str; 3] = ["flour", "butter", "sugar"];

fn arr(x: V) -> [f64; 3] { [x.0 as f64, x.1 as f64, x.2 as f64] }
fn grams(x: V) -> f64 { arr(x).iter().map(|v| v.abs()).sum() } // total grams off
fn pct(x: V) -> f64 { // worst miss, %
    let a = arr(x);
    (0..3).map(|i| 100.0 * a[i].abs() / AMT[i]).fold(f64::MIN, f64::max)
}
fn pence_at(x: V, price: [f64; 3]) -> f64 { // cost of the miss
    let a = arr(x);
    (0..3).map(|i| price[i] * a[i].abs()).sum()
}
fn pence(x: V) -> f64 { pence_at(x, PRICE) }
fn sz(x: V) -> String { format!("({}, {}, {})", x.0.abs(), x.1.abs(), x.2.abs()) }

fn main() {
    // ---- the batch ----
    let e: V = (6, -4, 3);
    println!("batch error ({}, {}, {}) g: grams {:.0} g, percent {:.4} %, pence {:.4} p", e.0, e.1, e.2, grams(e), pct(e), pence(e));
    assert!(grams(e) == 13.0 && (pct(e) - 3.0).abs() < 1e-12);
    assert!((pence(e) - (0.54 + 3.2 + 0.3)).abs() < 1e-12);
    let ea = arr(e);
    for i in 0..3 {
        println!("  {}: {:+} g of {:.0} g = {:.4} %", NAMES[i], ea[i] as i64, AMT[i], 100.0 * ea[i].abs() / AMT[i]);
    }

    // ---- road 1: best constants from the corners of each unit ball ----
    let wa: Vec<f64> = (0..3).map(|i| PRICE[i] * AMT[i] / 100.0).collect();
    let closed = [
        (100.0 / AMT.iter().sum::<f64>(), AMT.iter().map(|a| 100.0 / a).fold(f64::MIN, f64::max)),
        (PRICE.iter().cloned().fold(f64::MAX, f64::min), PRICE.iter().cloned().fold(f64::MIN, f64::max)),
        (wa.iter().cloned().fold(f64::MAX, f64::min), wa.iter().sum::<f64>()),
    ];

    // ---- road 2: walk the whole grams-sphere |x1| + |x2| + |x3| = K ----
    let k: i64 = 60;
    let mut sphere: Vec<V> = Vec::new(); // every whole-gram error of total K, in a fixed order
    for i in -k..=k {
        for j in -(k - i.abs())..=(k - i.abs()) {
            let r = k - i.abs() - j.abs();
            if r > 0 { sphere.push((i, j, r)); sphere.push((i, j, -r)); } else { sphere.push((i, j, 0)); }
        }
    }
    println!("grams-sphere points with K = {}: {} (formula 4K^2 + 2 = {})", k, sphere.len(), 4 * k * k + 2);
    assert!(sphere.len() as i64 == 4 * k * k + 2);
    let keys = ["percent per gram", "pence per gram", "pence per percent"];
    let ratio = |q: usize, x: V| -> f64 {
        match q { 0 => pct(x) / grams(x), 1 => pence(x) / grams(x), _ => pence(x) / pct(x) }
    };
    for q in 0..3 {
        let (mut lo, mut hi, mut alo, mut ahi) = (f64::MAX, f64::MIN, sphere[0], sphere[0]);
        for &x in &sphere {
            let r = ratio(q, x);
            if r < lo { lo = r; alo = x; }
            if r > hi { hi = r; ahi = x; }
        }
        let (c, cc) = closed[q];
        println!("{}: corners c = {:.4}, C = {:.4}; sphere walk min {:.4}, max {:.4}; batch {:.4}", keys[q], c, cc, lo, hi, ratio(q, e));
        assert!((lo - c).abs() < 1e-12 && (hi - cc).abs() < 1e-12 && c <= ratio(q, e) && ratio(q, e) <= cc);
        println!("  sizes of the extreme errors: min at {}, max at {}", sz(alo), sz(ahi));
    }

    // ---- the proof's constants, with grams as the reference norm ----
    let b = [(1, 0, 0), (0, 1, 0), (0, 0, 1)].iter().map(|&u| pct(u)).fold(f64::MIN, f64::max);
    let m = sphere.iter().map(|&x| pct(x)).fold(f64::MAX, f64::min) / k as f64;
    println!("proof, percent against grams: B = max over one gram of each = {:.4}, m = min on sphere = {:.4}", b, m);
    let tot: f64 = AMT.iter().sum();
    let xs: Vec<f64> = AMT.iter().map(|a| a / tot).collect(); // the error in proportion to the recipe
    let j = |v: Vec<String>| v.join(", ");
    println!("  one gram each: {} %; x* = ({}) g, each {} % off", j(AMT.iter().map(|a| format!("{:.4}", 100.0 / a)).collect()),
             j(xs.iter().map(|v| format!("{:.4}", v)).collect()), j((0..3).map(|i| format!("{:.4}", 100.0 * xs[i] / AMT[i])).collect()));
    println!("  batch sandwich: {:.4} <= {:.4} <= {:.4}", m * grams(e), pct(e), b * grams(e));
    let mp = sphere.iter().map(|&x| pence(x)).fold(f64::MAX, f64::min) / k as f64;
    println!("  chain percent <= (B / m_pence) pence: constant {:.4}, best {:.4}", b / mp, 1.0 / closed[2].0);
    assert!(m * grams(e) <= pct(e) && pct(e) <= b * grams(e) && b / mp >= 1.0 / closed[2].0);

    // ---- continuity of the percent norm: |pct(x) - pct(y)| <= B |x - y|_1 ----
    let worst = sphere.iter().map(|&y| (pct(e) - pct(y)).abs() / grams((e.0 - y.0, e.1 - y.1, e.2 - y.2)))
        .fold(f64::MIN, f64::max);
    println!("continuity: worst |pct(e) - pct(y)| / grams(e - y) over the sphere = {:.4} <= B", worst);
    assert!(worst <= b + 1e-12);

    // ---- what breaks: a free ingredient ----
    let free = pence_at((0, 0, 3), [0.09, 0.8, 0.0]);
    println!("sugar priced 0: error (0, 0, 3) costs {:.4} p, yet is {:.4} % off", free, pct((0, 0, 3)));
    assert!(free == 0.0 && pct((0, 0, 3)) > 0.0);

    // ---- what breaks: one net reading of the batch.  Overs and shorts cancel, so it is not a norm ----
    for &x in &[(6i64, -4i64, 3i64), (10, -10, 0), (30, -30, 0)] {
        let a = arr(x);
        let signed: f64 = (0..3).map(|i| PRICE[i] * a[i]).sum();
        println!("net reading ({}, {}, {}): {} g net, {:.4} p net, yet {:.4} % off", x.0, x.1, x.2, x.0 + x.1 + x.2, signed, pct(x));
    }

    // ---- what breaks: fractions only.  |p + q sqrt2| is zero only at (0, 0) when p, q are fractions ----
    for &(p, q) in &[(-7i64, 5i64), (-41, 29), (-239, 169)] {
        let r2 = (p as f64 + q as f64 * 2f64.sqrt()).abs();
        println!("fractions ({}, {}): |p + q sqrt2| = {:.6}, grams {}, ratio {:.7}", p, q, r2, p.abs() + q.abs(), r2 / (p.abs() + q.abs()) as f64);
        assert!((r2 - 1.0 / (p as f64 - q as f64 * 2f64.sqrt()).abs()).abs() < 1e-9); // (p + q sqrt2)(p - q sqrt2) = -1
    }

    // ---- functions: a week cut into N slots, a single-slot price spike ----
    let spike = 920.0; // £/MWh above a flat 80, illustrative
    println!("week of prices, one-slot spike of 920 £/MWh: sup norm vs time-average norm");
    for &n in &[7usize, 168, 1008, 10080, 604800] {
        let mut f = vec![0.0f64; n];
        f[n / 2] = spike;
        let sup = f.iter().map(|v| v.abs()).fold(f64::MIN, f64::max);
        let avg = f.iter().map(|v| v.abs()).sum::<f64>() / n as f64;
        println!("  N {:6}: slot {:.6} h, sup {:.1}, average {:.7}, sup/average {:.1}, log10 average {:.3}",
                 n, 168.0 / n as f64, sup, avg, sup / avg, avg.log10());
        assert!((avg - spike / n as f64).abs() < 1e-9 && (sup / avg - n as f64).abs() < 1e-6);
    }
    let mut pts = Vec::new();
    for &n in &[10usize, 100, 1000, 10000, 100000, 1000000] { // chart points, evenly spaced in log10 N
        let mut f = vec![0.0f64; n];
        f[n / 2] = spike;
        pts.push((f.iter().map(|v| v.abs()).sum::<f64>() / n as f64).log10());
    }
    let ps: Vec<String> = pts.iter().map(|v| format!("{:.3}", v)).collect();
    println!("chart, N = 10^1 to 10^6 slots: log10 sup {:.3}; log10 average {}", spike.log10(), ps.join(", "));
    assert!(pts.windows(2).all(|w| (w[0] - w[1] - 1.0).abs() < 1e-12)); // one unit of log10 per tenfold

    // ---- brute force for N = 7: min average on the sup-sphere is 1/N ----
    let levels = [-1.0, -0.5, 0.0, 0.5, 1.0];
    let (mut best, mut count) = (2.0f64, 0);
    for code in 0..5usize.pow(7) {
        let (mut v, mut c) = (Vec::new(), code);
        for _ in 0..7 { v.push(levels[c % 5]); c /= 5; }
        if v.iter().map(|t: &f64| t.abs()).fold(f64::MIN, f64::max) == 1.0 {
            count += 1;
            best = best.min(v.iter().map(|t| t.abs()).sum::<f64>() / 7.0);
        }
    }
    println!("N = 7 brute force: {} lists tried, {} with sup 1, smallest average {:.6} (1/7 = {:.6})", 5usize.pow(7), count, best, 1.0 / 7.0);
    assert!((best - 1.0 / 7.0).abs() < 1e-12);
    println!("ALL CHECKS PASS");
}
