// Reflexive spaces -- the check behind the card.  std only, no crates.
// A schedule x lists the MWh a battery moves each hour (+ sells, - buys); a
// price list y (pounds/MWh, illustrative) values it by the revenue sum y_k x_k.
// Every list here is cut to N hours: a truncation is finite-dimensional, so it
// is always reflexive.  The infinite claims rest on the proofs; the code shows
// the trends over N that never close.  Schedules in section 1 are kept in
// hundredths of a MWh, so the rehearsal is exact integer arithmetic.
use std::f64::consts::PI;

fn rev(y: &[i64], x: &[i64]) -> i64 { y.iter().zip(x).map(|(a, b)| a * b).sum() }
fn revf(y: &[f64], x: &[i64]) -> f64 { y.iter().zip(x).map(|(a, b)| a * (*b as f64)).sum() }
fn bump(n: usize, big_n: usize) -> Vec<i64> { (1..=big_n).map(|k| if k == n { 1 } else { 0 }).collect() }
fn hund(v: i64) -> String {
    let s = if v < 0 { "-" } else { "" };
    format!("{}{}.{:02}", s, v.abs() / 100, v.abs() % 100)
}
fn join<T: ToString>(v: &[T]) -> String { v.iter().map(|a| a.to_string()).collect::<Vec<_>>().join(", ") }
fn join4(v: &[f64]) -> String { v.iter().map(|a| format!("{:.4}", a)).collect::<Vec<_>>().join(", ") }
fn norm(v: (f64, f64), p: f64) -> f64 {
    if p == 0.0 { v.0.abs().max(v.1.abs()) } else { (v.0.abs().powf(p) + v.1.abs().powf(p)).powf(1.0 / p) }
}
fn dent(p: f64, m: usize) -> f64 {
    let pts: Vec<(f64, f64)> = (0..m).map(|i| {
        let t = 2.0 * PI * i as f64 / m as f64;
        let r = norm((t.cos(), t.sin()), p);
        (t.cos() / r, t.sin() / r)
    }).collect();
    let mut best = 1.0f64;
    for u in &pts {
        for v in &pts {
            if norm((u.0 - v.0, u.1 - v.1), p) >= 1.0 - 1e-9 {
                best = best.min(1.0 - norm(((u.0 + v.0) / 2.0, (u.1 + v.1) / 2.0), p));
            }
        }
    }
    best.max(0.0)
}

fn main() {
    // 1. Six-hour rehearsal: ||Jx|| = sup |revenue| over |y_k| <= 100, against 100 ||x||_1
    let x: [i64; 6] = [-30, -20, 0, 10, 25, 15];
    let day: [i64; 6] = [40, 35, 45, 70, 90, 60];
    let corners: Vec<i64> = (0..64u32).map(|mask| {
        let y: Vec<i64> = (0..6).map(|i| if mask >> i & 1 == 1 { 100 } else { -100 }).collect();
        rev(&y, &x)
    }).collect();
    let best = *corners.iter().max().unwrap();
    let norm1: i64 = x.iter().map(|v| v.abs()).sum();
    println!("rehearsal, 6 hours: x = {} MWh", x.iter().map(|&v| hund(v)).collect::<Vec<_>>().join(", "));
    println!("  ||x||_1 = {} MWh; revenue at prices {}: {}", hund(norm1), join(&day), hund(rev(&day, &x)));
    println!("  best |revenue| over 64 corner lists, |y_k| <= 100: {}; 100 ||x||_1 = {}", hund(best), hund(100 * norm1));

    // 2. Bumps in l1: three price lists read the bump at hour n
    println!("l1 bumps e_n read by: flat 50 | 50 at hour 18 only | sup and 2-norm of the flat list");
    let mut flat_norm2 = vec![];
    for &n in &[168usize, 336, 672, 1344] {
        let flat = vec![50i64; n];
        let h18: Vec<i64> = (1..=n).map(|k| if k == 18 { 50 } else { 0 }).collect();
        let e = bump(n, n);
        let s2 = (flat.iter().map(|v| (v * v) as f64).sum::<f64>()).sqrt();
        flat_norm2.push(s2);
        println!("  N={:4} bump at hour {:4}: {} | {} | {}, {:.2} (50 sqrt N = {:.2})",
                 n, n, rev(&flat, &e), rev(&h18, &e), flat.iter().max().unwrap(), s2, 50.0 * (n as f64).sqrt());
    }
    let days: Vec<usize> = (1..=7).map(|k| 18 + 24 * (k - 1)).collect();
    let mut alt = vec![50i64; 168];
    for (k, &n) in days.iter().enumerate() { alt[n - 1] = if k % 2 == 0 { 60 } else { 40 }; }
    let h18w: Vec<i64> = (1..=168).map(|k| if k == 18 { 50 } else { 0 }).collect();
    let read_alt: Vec<i64> = days.iter().map(|&n| rev(&alt, &bump(n, 168))).collect();
    let read_h18: Vec<i64> = days.iter().map(|&n| rev(&h18w, &bump(n, 168))).collect();
    let read_flat: Vec<i64> = days.iter().map(|&n| rev(&vec![50i64; 168], &bump(n, 168))).collect();
    println!("  18:00 bumps, hours {}", join(&days));
    println!("  flat list reads {}", join(&read_flat));
    println!("  alternating list reads {} ; hour-18 list reads {}", join(&read_alt), join(&read_h18));
    let settle: Vec<f64> = [18usize, 168, 1344].iter().map(|&n| {
        let y: Vec<f64> = (1..=n).map(|k| 50.0 + 30.0 / k as f64).collect();
        revf(&y, &bump(n, n))
    }).collect();
    println!("  settling list 50 + 30/k reads the bump at hours 18, 168, 1344 as {} -> long-run price 50", join4(&settle));
    let gaps: Vec<i64> = read_alt.windows(2).map(|w| (w[0] - w[1]).abs()).collect();
    let mut dist = vec![];
    for &m in &days { for &n in &days { if m != n {
        let d: i64 = bump(m, 168).iter().zip(bump(n, 168)).map(|(a, b)| (a - b).abs()).sum();
        if !dist.contains(&d) { dist.push(d); }
    } } }
    let mut gset = gaps.clone(); gset.sort(); gset.dedup();
    println!("  gaps between neighbours: [{}]; ||e_m - e_n||_1 for m != n: [{}]", join(&gset), join(&dist));

    // 3. The same bumps in l2: an allowed price list must be square-summable, so it dies away
    let ysq = |k: usize| 50.0 / k as f64;
    let tail: Vec<f64> = [168usize, 1344].iter().map(|&n| (1..=n).map(|k| ysq(k).powi(2)).sum::<f64>().sqrt()).collect();
    let lim2 = 50.0 * PI / 6f64.sqrt();
    println!("l2: price list 50/k has 2-norm {:.4} (N=168), {:.4} (N=1344), limit 50 pi/sqrt 6 = {:.4}", tail[0], tail[1], lim2);
    let reads2: Vec<f64> = [18usize, 168, 1344].iter().map(|&n| {
        let y: Vec<f64> = (1..=n).map(ysq).collect();
        revf(&y, &bump(n, n))
    }).collect();
    println!("  it reads the bump at hours 18, 168, 1344 as {} -> 0; ||e_n||_2 = 1", join4(&reads2));

    // 4. The promise in l2: x_n = sin(n) e_1 + e_(n+1), bounded by sqrt 2.  Bisection keeps the
    //    half of [-1, 1] holding more later terms and takes the next term there.
    let s: Vec<f64> = (1..=100000).map(|n| (n as f64).sin()).collect();
    let bisect = |kk: usize| {
        let (mut lo, mut hi, mut last) = (-1.0f64, 1.0f64, 0usize);
        let (mut picks, mut boxes) = (vec![], vec![]);
        for _ in 0..kk {
            let mid = (lo + hi) / 2.0;
            let low = (last + 1..=100000).filter(|&n| lo <= s[n - 1] && s[n - 1] < mid).count();
            let upp = (last + 1..=100000).filter(|&n| mid <= s[n - 1] && s[n - 1] <= hi).count();
            if low >= upp { hi = mid } else { lo = mid }
            last = (last + 1..=100000).find(|&n| lo <= s[n - 1] && s[n - 1] <= hi).unwrap();
            picks.push(last);
            boxes.push((lo, hi));
        }
        (picks, boxes)
    };
    let (picks, boxes) = bisect(8);
    let (lo, hi) = boxes[7];
    let c = (lo + hi) / 2.0;
    let sp: Vec<f64> = picks.iter().map(|&n| s[n - 1]).collect();
    println!("bisection picks n_k = {}", join(&picks));
    println!("  sin(n_k) = {}", join4(&sp));
    println!("  last interval [{:.6}, {:.6}], width {:.6}; weak limit about {:.4} e_1", lo, hi, hi - lo, c);
    let count = s.iter().filter(|&&v| lo <= v && v <= hi).count();
    let law = (hi.asin() - lo.asin()) / PI;        // share of sin(n) in [lo, hi] as n runs on
    println!("  terms n <= 100000 inside it: {}, share {:.4}; arcsine law {:.4}", count, count as f64 / 100000.0, law);
    println!("  ||x_(n_8)||_2 = {:.4}; ||limit||_2 about {:.4}", (1.0 + sp[7] * sp[7]).sqrt(), c.abs());

    // 5. Uniform convexity in the plane: delta_p(1) = least dent 1 - ||(u+v)/2||_p over unit
    //    u, v at distance >= 1, by a 720-angle grid; Clarkson's formula 1 - (1 - 2^-p)^(1/p)
    let d: Vec<f64> = [1.0, 2.0, 4.0, 0.0].iter().map(|&p| dent(p, 720)).collect();
    let clark = |p: i32| 1.0 - (1.0 - 2f64.powi(-p)).powf(1.0 / p as f64);
    println!("dent delta_p(1): p=1 {:.4}, p=2 {:.4} (Clarkson {:.4}), p=4 {:.4} (Clarkson {:.4}), p=inf {:.4}",
             d[0], d[1], clark(2), d[2], clark(4), d[3]);
    let mid = norm((0.5, 0.5), 1.0);
    println!("  l1 flat face: e_1, e_2 at distance 2, midpoint 1-norm {:.4}; in 2-norm {:.4}", mid, norm((0.5, 0.5), 2.0));

    let (p12, b12) = bisect(12);
    println!("try: 12 halvings pick n_12 = {}, interval [{:.6}, {:.6}]", p12[11], b12[11].0, b12[11].1);
    println!("try: dent p=1.5 {:.4}; p=3 {:.4} (Clarkson {:.4})", dent(1.5, 720), dent(3.0, 720), clark(3));
    let root: Vec<f64> = [168usize, 1344].iter().map(|&n| (1..=n).map(|k| 2500.0 / k as f64).sum::<f64>().sqrt()).collect();
    println!("try: price list 50/sqrt k has 2-norm {:.2} (N=168), {:.2} (N=1344), still growing", root[0], root[1]);

    assert!(best == 100 * norm1 && 100 * norm1 == 10000);          // ||Jx|| = ||x|| two roads
    assert_eq!(rev(&day, &x), 1950);
    assert!(read_alt == vec![60, 40, 60, 40, 60, 40, 60] && read_h18 == vec![50, 0, 0, 0, 0, 0, 0]);
    assert!(gaps == vec![20; 6] && dist == vec![2]);
    for (s2, n) in flat_norm2.iter().zip([168.0f64, 336.0, 672.0, 1344.0]) { assert!((s2 - 50.0 * n.sqrt()).abs() < 1e-9); }
    assert!(tail[0] < tail[1] && tail[1] < lim2 && lim2 - tail[1] < 0.03);
    assert!(picks.iter().zip(&boxes).all(|(&n, &(a, b))| a <= s[n - 1] && s[n - 1] <= b));
    assert!(picks.windows(2).all(|w| w[0] < w[1]));
    assert!(boxes.windows(2).all(|w| w[1].0 >= w[0].0 && w[1].1 <= w[0].1 && w[1].1 - w[1].0 == (w[0].1 - w[0].0) / 2.0));
    assert!(p12[..8] == picks[..] && (b12[11].1 - b12[11].0 - 2.0 / 4096.0).abs() < 1e-12);
    assert!(((hi - lo) - 2.0 / 256.0).abs() < 1e-12 && read_flat == vec![50; 7]);
    assert!(count > 1000 && (count as f64 / 100000.0 - law).abs() < 2e-3);   // plenty left: the run can go on
    for (v, n) in settle.iter().zip([18.0f64, 168.0, 1344.0]) { assert!((v - (50.0 + 30.0 / n)).abs() < 1e-12); }
    assert!((d[1] - clark(2)).abs() < 2e-3 && (d[2] - clark(4)).abs() < 2e-3);
    assert!(d[0] < 1e-9 && d[3] < 1e-9 && mid == 1.0);
    println!("ALL CHECKS PASS");
}
