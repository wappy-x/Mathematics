// Monotone functions and jumps -- the same check as the Python, in Rust, std
// only.  Road 1: the fare formula gives the one-sided limits.  Road 2: a meter
// driven metre by metre, read as highest value below and lowest value above.
// Road 3: the counting bound, jumps of size h or more <= rise / h.
fn f(m: i64) -> i64 { 250 + 120 * ((m + 999) / 1000) }  // fare in cents at m metres
fn d(c: i64) -> String { format!("{}.{:02}", c / 100, c % 100) }
fn g(x: f64) -> f64 { (1..=60).filter(|&n| x >= 1.0 / n as f64).map(|n| 2f64.powi(-n)).sum() }
fn join(v: Vec<String>) -> String { v.join(", ") }
fn main() {
    let mut vals = Vec::new();
    let mut fare = 250;                                   // the meter, metre by metre
    for m in 0..=5000 {
        if m % 1000 == 1 { fare += 120; }                 // a new kilometre starts
        vals.push(fare);
    }
    println!("setup: taxi fare 2.50 + 1.20 per started km on [0, 5]; test staircase g on [0, 1] adds 2^-n at x = 1/n");
    let mut jumps = [0i64; 6];
    for c in 0..6usize {
        let ci = c as i64;
        let lf = if c > 0 { Some(250 + 120 * ci) } else { None };        // road 1: the formula
        let rf = if c < 5 { Some(250 + 120 * (ci + 1)) } else { None };
        let lb = if c > 0 { vals[..1000 * c].iter().max().copied() } else { None };      // road 2: sup below
        let rb = if c < 5 { vals[1000 * c + 1..].iter().min().copied() } else { None };  // road 2: inf above
        assert!((lf, rf) == (lb, rb) && lf.unwrap_or(0) <= f(1000 * ci) && f(1000 * ci) <= rf.unwrap_or(1_000_000_000));
        let j = rf.unwrap_or(f(5000)) - lf.unwrap_or(f(0));
        jumps[c] = j;
        let show = |o: Option<i64>| o.map(d).unwrap_or("-".to_string());
        println!("at {} km: left {}, value {}, right {}, jump {}", c, show(lf), d(f(1000 * ci)), show(rf), d(j));
    }
    println!("near 2 km from the left, 1.9, 1.99, 1.999 km: {} | from the right, 2.1, 2.01, 2.001 km: {}",
             join([1900, 1990, 1999].iter().map(|&m| d(f(m))).collect()), join([2100, 2010, 2001].iter().map(|&m| d(f(m))).collect()));
    let scan: Vec<(usize, i64)> = (1..=5000).filter(|&m| vals[m] > vals[m - 1]).map(|m| (m - 1, vals[m] - vals[m - 1])).collect();
    let total: i64 = scan.iter().map(|s| s.1).sum();
    println!("meter scan: rises at {} km; sizes {}; total {}", join(scan.iter().map(|s| format!("{}", s.0 / 1000)).collect()),
             join(scan.iter().map(|s| d(s.1)).collect()), d(total));
    let rise = f(5000) - f(0);
    let nonzero: Vec<usize> = (0..6).filter(|&c| jumps[c] != 0).map(|c| 1000 * c).collect();
    assert!(scan.iter().map(|s| s.0).collect::<Vec<_>>() == nonzero && total == rise);
    for h in [120i64, 50] {
        let n = jumps.iter().filter(|&&j| j >= h).count();
        println!("rise {}; jumps of at least {}: bound {}, found {}", d(rise), d(h), rise / h, n);
        assert!(n as f64 <= rise as f64 / h as f64);
    }
    let brute: Vec<f64> = (1..=60).map(|n| g(1.0 / n as f64) - g(1.0 / n as f64 - 1e-9)).collect();
    assert!(brute.iter().enumerate().all(|(i, b)| (b - 2f64.powi(-(i as i32 + 1))).abs() < 1e-12));
    println!("g jumps at x = 1, 1/2, 1/3, 1/4 by definition: {} | formula 2^-n: {}",
             join(brute[..4].iter().map(|b| format!("{:.6}", b)).collect()), join((1..5).map(|n| format!("{:.6}", 2f64.powi(-n))).collect()));
    let grise = g(1.0) - g(0.0);
    let hs = [0.1, 0.01, 0.001, 0.000001];
    let found: Vec<usize> = hs.iter().map(|&h| brute.iter().filter(|&&b| b >= h).count()).collect();
    assert!(found.iter().zip(hs).all(|(&n, h)| n as f64 <= grise / h) && found == vec![3, 6, 9, 19]);
    println!("g rise {:.6}; jumps of at least 0.1, 0.01, 0.001, 0.000001: found {}; bounds {}", grise,
             join(found.iter().map(|n| n.to_string()).collect()), join(hs.iter().map(|h| format!("{:.0}", grise / h)).collect()));
    println!("mistakes: jump at 2 km measured from the value {}; kerb jump dropped: {} jumps, {} of {}",
             d(f(2000) - vals[..2000].iter().max().unwrap()), (1..6).filter(|&c| jumps[c] != 0).count(),
             d(jumps[1..].iter().sum()), d(rise));
    let (x, y) = (|km: f64| 60.0 + 56.0 * km, |c: f64| 200.0 - 25.0 * (c - 250.0) / 100.0);
    println!("figure, 56 px per km, 25 px per dollar; step heights y = {}; jump edges x = {}",
             join((1..6).map(|k| format!("{:.0}", y(250.0 + 120.0 * k as f64))).collect()),
             join((0..5).map(|c| format!("{:.0}", x(c as f64))).collect()));
    println!("ALL CHECKS PASS");
}
