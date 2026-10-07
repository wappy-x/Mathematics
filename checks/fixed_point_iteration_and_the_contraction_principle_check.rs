// Fixed points and the contraction rule -- the same check as the Python, in
// Rust.  No crates; cos, sin and acos are primitives.  The answer to cos x = x
// is reached twice: by pressing cos again and again, and by halving a bracket.
fn first(ok: impl Fn(usize) -> bool) -> usize { (1..=60).find(|&n| ok(n)).unwrap() }

fn main() {
    let mut xs = vec![0.0_f64];                       // road one: press cos 100 times from 0
    for _ in 0..100 { let last = xs[xs.len() - 1]; xs.push(last.cos()) }
    let (mut lo, mut hi) = (0.0_f64, 1.0_f64);         // road two: x - cos x changes sign on [0, 1]
    for _ in 0..60 {
        let mid = (lo + hi) / 2.0;
        if mid - mid.cos() < 0.0 { lo = mid } else { hi = mid }
    }
    let p = (lo + hi) / 2.0;
    let q = 1.0_f64.sin();                            // the mean value theorem's bound for |cos'| on [0, 1]
    let grid: Vec<f64> = (0..=200).map(|k| k as f64 / 200.0).collect();
    let mut chord = 0.0_f64;
    for &a in &grid { for &b in &grid { if b > a { chord = chord.max((a.cos() - b.cos()).abs() / (b - a)) } } }
    let k = q / (1.0 - q);
    let prior = |n: usize| q.powi(n as i32) / (1.0 - q) * (xs[1] - xs[0]).abs();
    let post = |n: usize| k * (xs[n] - xs[n - 1]).abs();
    println!("pressing cos 100 times: {:.10}; halving 60 times: {:.10}", xs[100], p);
    println!("q = sin 1 = {:.6}; widest sampled chord slope {:.6}; q/(1-q) = {:.6}", q, chord, k);
    let cmin = grid.iter().map(|t| t.cos()).fold(f64::INFINITY, f64::min);
    let cmax = grid.iter().map(|t| t.cos()).fold(f64::NEG_INFINITY, f64::max);
    let mut deg = 0.0_f64;                            // the same key in degree mode
    for _ in 0..50 { deg = (deg * std::f64::consts::PI / 180.0).cos() }
    println!("cos sends [0, 1] into [{:.6}, {:.6}]; degree mode settles at {:.10}", cmin, cmax, deg);
    println!("n, x_n, true error, last-step bound, first-step bound");
    for n in [1, 2, 3, 4, 5, 10, 20] {
        println!("{}, {:.6}, {:.6}, {:.6}, {:.6}", n, xs[n], (xs[n] - p).abs(), post(n), prior(n));
    }
    println!("within 0.001 promised by first-step bound at n = {}, by last-step bound at n = {}, true at n = {}",
             first(|n| prior(n) <= 1e-3), first(|n| post(n) <= 1e-3), first(|n| (xs[n] - p).abs() <= 1e-3));
    let h = 1e-5;                                     // the card's own difference quotient for cos' at p
    let slope = ((p + h).cos() - (p - h).cos()) / (2.0 * h);
    let ratio = (xs[31] - p).abs() / (xs[30] - p).abs();
    println!("error ratio at n = 30: {:.6}; |slope of cos at p| by difference quotient: {:.6}", ratio, slope.abs());
    let mut y = vec![0.75_f64];                       // break 1: the same equation as x = arccos x
    for _ in 0..8 { let last = y[y.len() - 1]; y.push(last.acos()) }
    let errs: Vec<String> = y.iter().map(|t| format!("{:.4}", (t - p).abs())).collect();
    println!("arccos from 0.75, errors: {}", errs.join(", "));
    let mut z = 1.0_f64;                              // break 2: halving on (0, 1], which lacks 0
    for _ in 0..20 { z /= 2.0 }
    println!("halving on (0, 1], x_20 = {:.8}, heading for 0, outside the set", z);
    let mut w = 1.0_f64;                              // break 3: x + 1/x on [1, infinity)
    for _ in 0..1000 { w += 1.0 / w }
    let s = |t: f64| t + 1.0 / t;
    println!("x + 1/x: chord slope on [100, 101] = {:.6}; x_1000 from 1 = {:.4}", s(101.0) - s(100.0), w);
    let mut pts = vec![(0.0_f64, 0.0_f64)];
    for j in 0..4 { pts.push((xs[j], xs[j + 1])); pts.push((xs[j + 1], xs[j + 1])) }
    let cob: Vec<String> = pts.iter().map(|(a, b)| format!("{:.1},{:.1}", 60.0 + 200.0 * a, 220.0 - 200.0 * b)).collect();
    println!("figure, cobweb px: {}", cob.join(" "));
    let curve: Vec<String> = (0..=10).map(|i| format!("{},{:.1}", 60 + 20 * i, 220.0 - 200.0 * (i as f64 / 10.0).cos())).collect();
    println!("figure, cos curve px: {}", curve.join(" "));
    println!("figure, fixed point px: {:.1},{:.1}", 60.0 + 200.0 * p, 220.0 - 200.0 * p);
    assert!((xs[100] - p).abs() < 1e-12);                          // two roads, one answer
    assert!((1..=40).all(|n| (xs[n] - p).abs() <= post(n) && post(n) <= prior(n)));
    assert!(chord <= q);                                           // q really bounds every sampled chord
    assert!((ratio - slope.abs()).abs() < 1e-4);                   // errors shrink at the slope at p
    println!("ALL CHECKS PASS");
}
