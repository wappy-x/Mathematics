// Equidistribution and Weyl's criterion -- the same check as the Python, in Rust.  No crates.
// {x} = x - floor(x) is the fractional part; e(x) = cos 2 pi x + i sin 2 pi x.
// Roads: exact bin counts by integer square roots against floating-point {n root2};
// Weyl sums added term by term against the geometric-series closed form and its bound;
// leading digits read off the integers against the fractional parts of logs.
use std::f64::consts::PI;

fn frac(x: f64) -> f64 { x - x.floor() }
fn dist(x: f64) -> f64 { frac(x).min(1.0 - frac(x)) }          // ||x||, distance to the nearest integer
fn isqrt(n: u128) -> u128 {
    let mut x = (n as f64).sqrt() as u128;
    while x.checked_mul(x).unwrap() > n { x -= 1 }
    while (x + 1).checked_mul(x + 1).unwrap() <= n { x += 1 }
    x
}
fn digits(n: u128, k: u32) -> u128 {                           // floor(10^k {n root2}), exact
    let t = 10u128.pow(k);
    isqrt(2 * n * n * t * t) - t * isqrt(2 * n * n)
}
fn weyl(xs: &[f64], h: f64) -> f64 {                           // |(1/N) sum of e(h x_n)|, term by term
    let (mut re, mut im) = (0.0f64, 0.0f64);
    for &x in xs {
        let t = 2.0 * PI * frac(h * x);
        re += t.cos(); im += t.sin();
    }
    (re * re + im * im).sqrt() / xs.len() as f64
}
fn closed(n: f64, h: f64, a: f64) -> f64 {                     // |sin(pi N h a)| / (N |sin(pi h a)|)
    (PI * frac(n * h * a)).sin().abs() / (n * (PI * frac(h * a)).sin().abs())
}
fn r2s(m: usize, r2: f64) -> Vec<f64> { (1..=m).map(|n| n as f64 * r2).collect() }
fn join(v: Vec<String>, sep: &str) -> String { v.join(sep) }
fn leading(n: u64) -> char { n.to_string().chars().next().unwrap() }

fn main() {
    let r2 = 2.0f64.sqrt();
    println!("n, n root2, {{n root2}}: {}", join((1..6).map(|n| { let x = n as f64 * r2;
        format!("{}, {:.6}, {:.6}", n, x, frac(x)) }).collect(), "; "));
    println!("road 1 = exact integer count, road 2 = floating point; points in [0, 0.1):");
    for &nn in &[10u128, 100, 1000, 10000, 100000] {
        let c1 = (1..=nn).filter(|&n| digits(n, 1) == 0).count() as i64;
        let c2 = (1..=nn).filter(|&n| frac(n as f64 * r2) < 0.1).count() as i64;
        assert_eq!(c1, c2);
        let fair = (nn / 10) as i64;
        println!("  N = {:>6}: count {:>5}, fair share {:>5}, difference {:>2}, ratio {:.4}", nn, c1, fair, c1 - fair, c1 as f64 / (nn as f64 / 10.0));
    }

    let nn = 1000usize;
    let (mut b2, mut b7) = (vec![0i64; 10], vec![0i64; 10]);
    for n in 1..=nn as u128 {
        b2[digits(n, 1) as usize] += 1;
        b7[(10 * (99 * n % 70) / 70) as usize] += 1;         // 99/70: {99n/70} = (99n mod 70)/70
    }
    assert!(b2.iter().all(|c| (c - 100).abs() < 10));
    for (b, &c) in b2.iter().enumerate() {
        let hi = if b == 9 { "1.0".to_string() } else { format!("0.{}", b + 1) };
        println!("root2 [0.{}, {})  {:<28} {}", b, hi, "#".repeat((c / 4) as usize), c);
    }
    println!("99/70 bins, N = 1000: [{}]", join(b7.iter().map(|c| c.to_string()).collect(), ", "));
    let gap2 = (1..=1000u128).filter(|&n| { let d = digits(n, 3); 1 <= d && d <= 13 }).count() as i64;
    let gap7 = (1..=1000u128).filter(|&n| { let r = 1000 * (99 * n % 70); 70 <= r && r < 980 }).count();
    assert!(gap7 == 0 && (gap2 - 13).abs() <= 6);
    println!("points in [0.001, 0.014) for N = 1000: root2 {}, 99/70 {}, fair share 13", gap2, gap7);

    for &m in &[10usize, 100, 1000, 10000] {                   // worst miscount over all [0, t)
        let mut xs: Vec<f64> = (1..=m).map(|n| frac(n as f64 * r2)).collect();
        xs.sort_by(|a, b| a.partial_cmp(b).unwrap());
        let mf = m as f64;
        let d = xs.iter().enumerate().map(|(i, &x)| (i as f64 + 1.0 - mf * x).max(mf * x - i as f64)).fold(f64::MIN, f64::max);
        let u: Vec<u128> = (1..=m as u128).map(|n| digits(n, 12)).collect();   // exact floor(10^12 {n root2})
        let mut su = u.clone(); su.sort();
        let d2 = u.iter().map(|&v| { let x = mf * v as f64 / 1e12;
            (su.partition_point(|&s| s <= v) as f64 - x).max(x - su.partition_point(|&s| s < v) as f64) }).fold(f64::MIN, f64::max);
        assert!((d - d2).abs() < 1e-6);                        // road 2: exact points, ranks by bisection
        println!("  worst miscount over all [0, t), N = {:>5}: {:.4} points, share of N {:.6}", m, d, d / mf);
    }

    println!("Weyl averages for root2: term by term | closed form | bound 1/(2 N ||h root2||)");
    for &h in &[1.0f64, 2.0, 70.0] {
        println!("  h = {:>2}, ||h root2|| = {:.6}", h as i64, dist(h * r2));
        for &m in &[100usize, 1000, 10000] {
            let w = weyl(&r2s(m, r2), h);
            let (c, bd) = (closed(m as f64, h, r2), 1.0 / (2.0 * m as f64 * dist(h * r2)));
            assert!((w - c).abs() < 1e-9 && w <= bd);
            println!("    N = {:>5}: {:.6} | {:.6} | {:.6}", m, w, c, bd);
        }
    }
    let (mut re, mut im, mut big, mut at) = (0.0f64, 0.0f64, 0.0f64, 0usize);
    for n in 1..=10000usize {
        let t = 2.0 * PI * frac(n as f64 * r2); re += t.cos(); im += t.sin();
        let s = (re * re + im * im).sqrt();
        if s > big { big = s; at = n; }
    }
    assert!(big <= 1.0 / (2.0 * dist(r2)));
    println!("largest |S_N(1)| for N up to 10000: {:.6} at N = {}; bound for every N {:.6}", big, at, 1.0 / (2.0 * dist(r2)));
    println!("by hand: sin(pi ||root2||) = {:.6}, 1/that = {:.6}", (PI * dist(r2)).sin(), 1.0 / (PI * dist(r2)).sin());
    let near = |h: i128| { let m = (h as f64 * r2).round() as i128; (2 * h * h - m * m).abs() };
    let pell: Vec<String> = (1..=1000i128).filter(|&h| near(h) == 1).map(|h| h.to_string()).collect();
    assert!((1..=1000i128).all(|h| near(h) >= 1));
    let worst = (1..=1000).map(|h| dist(h as f64 * r2) * (2.0 * r2 * h as f64 + 1.0)).fold(f64::MAX, f64::min);
    assert!(worst > 1.0);
    println!("|2h^2 - m^2| >= 1 for h up to 1000; it equals 1 at h = [{}]; min ||h root2||(2 root2 h + 1) = {:.6}", join(pell, ", "), worst);

    let rat: Vec<f64> = (1..=nn as u64).map(|n| (99 * n % 70) as f64 / 70.0).collect();
    let w70 = weyl(&rat, 70.0);
    let top = (1..70).map(|h| weyl(&rat, h as f64)).fold(f64::MIN, f64::max);
    assert!((w70 - 1.0).abs() < 1e-9 && top < 0.02);
    println!("99/70 = {:.6}, root2 = {:.6}, gap {:.6}", 99.0 / 70.0, r2, 99.0 / 70.0 - r2);
    println!("99/70, N = 1000: Weyl average at h = 70 is {:.6}; largest over h = 1..69 is {:.6}", w70, top);
    println!("chart, h = 70, N = 20..400 step 20 (bound = smaller of 1 and 1/(2 N ||70 root2||)):");
    let ms: Vec<usize> = (1..=20).map(|k| 20 * k).collect();
    println!("  root2  {}", join(ms.iter().map(|&m| format!("{:.3}", closed(m as f64, 70.0, r2))).collect(), ", "));
    println!("  99/70  {}", join(ms.iter().map(|&m| format!("{:.3}", weyl(&rat[..m], 70.0))).collect(), ", "));
    println!("  bound  {}", join(ms.iter().map(|&m| format!("{:.3}", 1f64.min(1.0 / (2.0 * m as f64 * dist(70.0 * r2))))).collect(), ", "));

    let (l2, lim) = (2f64.log10(), 1.0 / (1.0 + (2.0 * PI / 10f64.ln()).powi(2)).sqrt());
    for &m in &[999u64, 1999] {
        let ex = (1..=m).filter(|&n| leading(n) == '1').count();
        let fl = (1..=m).filter(|&n| frac((n as f64).log10()) < l2).count();
        assert_eq!(ex, fl);
        println!("log10 n, N = {:>5}: leading digit 1 share {:.6} (equidistributed would give {:.6})", m, ex as f64 / m as f64, l2);
    }
    for &m in &[1000usize, 10000, 100000] {
        let w = weyl(&(1..=m).map(|n| (n as f64).log10()).collect::<Vec<f64>>(), 1.0);
        assert!((w - lim).abs() < 0.005);
        println!("log10 n, N = {:>6}: Weyl average at h = 1 is {:.6}; limit 1/sqrt(1 + (2 pi/ln 10)^2) = {:.6}", m, w, lim);
    }

    let mut big2: Vec<u32> = vec![1];                          // 2^n exactly, base 10^9 limbs, low first
    let (mut e1, mut e9) = (0, 0);
    for _ in 1..=nn {
        let mut carry = 0u64;
        for limb in big2.iter_mut() { let v = *limb as u64 * 2 + carry; *limb = (v % 1_000_000_000) as u32; carry = v / 1_000_000_000; }
        if carry > 0 { big2.push(carry as u32) }
        match leading(*big2.last().unwrap() as u64) { '1' => e1 += 1, '9' => e9 += 1, _ => {} }
    }
    let f1 = (1..=nn).filter(|&n| frac(n as f64 * l2) < l2).count();
    let f9 = (1..=nn).filter(|&n| frac(n as f64 * l2) >= 9f64.log10()).count();
    assert!(e1 == f1 && e9 == f9 && (f1 as f64 - nn as f64 * l2).abs() < 3.0);
    println!("2^n, n = 1..1000, leading digit 1: {}, predicted {:.2}; leading 9: {}, predicted {:.2}", f1, nn as f64 * l2, f9, nn as f64 * (10.0f64 / 9.0).log10());
    println!("ALL CHECKS PASS");
}
