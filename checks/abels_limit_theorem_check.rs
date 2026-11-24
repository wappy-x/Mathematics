// Abel's limit theorem -- the same check as the Python, in Rust, std only.
// Road one sums each power series term by term just inside the edge, x < 1.
// Road two shares no arithmetic with it: Simpson areas under 1/(1+t) and
// 1/(1+t^2), which are ln(1+x) and arctan x.  Road three is the averaging
// identity f(x) - s = (1 - x) times the sum of (s_n - s) x^n.  Abel's lemma,
// the summation-by-parts bound, is tested at 101 inputs from 0 to 1.
fn series(coef: fn(i64) -> f64, x: f64) -> f64 { // coef(0) + coef(1) x + ... until x^n < 1e-16
    let (mut total, mut n, mut p) = (0.0, 0, 1.0);
    while p > 1e-16 { total += coef(n) * p; n += 1; p *= x; }
    total
}
fn simpson(g: fn(f64) -> f64, b: f64) -> f64 { // area under g from 0 to b, parabola strips
    let m = 4000;
    let h = b / m as f64;
    let inner = (1..m).fold(0.0, |a, k| a + (if k % 2 == 1 { 4.0 } else { 2.0 }) * g(k as f64 * h));
    h / 3.0 * (g(0.0) + g(b) + inner)
}
fn partial(coef: fn(i64) -> f64, big_n: i64) -> Vec<f64> { // edge partial sums s_0, ..., s_N at x = 1
    let mut s = 0.0;
    (0..=big_n).map(|n| { s += coef(n); s }).collect()
}
fn sgn(k: i64) -> f64 { if k % 2 == 0 { 1.0 } else { -1.0 } } // (-1)^k
fn ln_c(n: i64) -> f64 { if n == 0 { 0.0 } else { sgn(n + 1) / n as f64 } } // x - x^2/2 + ...
fn at_c(n: i64) -> f64 { if n % 2 == 0 { 0.0 } else { sgn(n / 2) / n as f64 } } // x - x^3/3 + ...
fn geo_c(n: i64) -> f64 { sgn(n) } // 1 - x + x^2 - ...
fn eu_c(n: i64) -> f64 { sgn(n) * (n as f64 + 1.0) } // 1 - 2x + 3x^2 - ...
fn row(v: &[f64], d: usize) -> String {
    v.iter().map(|t| format!("{:.*}", d, t)).collect::<Vec<_>>().join(", ")
}
fn main() {
    let xs = [0.9, 0.99, 0.999];
    let (gl, ga): (fn(f64) -> f64, fn(f64) -> f64) = (|t| 1.0 / (1.0 + t), |t| 1.0 / (1.0 + t * t));
    let (ln2, pi4) = (simpson(gl, 1.0), simpson(ga, 1.0));
    for (name, c, g, s, last) in [("ln(1+x)", ln_c as fn(i64) -> f64, gl, ln2, 1000), ("arctan x", at_c, ga, pi4, 1999)] {
        let inside: Vec<f64> = xs.iter().map(|&x| series(c, x)).collect();
        let areas: Vec<f64> = xs.iter().map(|&x| simpson(g, x)).collect();
        let edge = *partial(c, last).last().unwrap();
        let gaps: Vec<f64> = inside.iter().map(|v| s - v).collect();
        println!("{} series at x = 0.9, 0.99, 0.999: {}; areas {}", name, row(&inside, 6), row(&areas, 6));
        println!("  edge value {:.6}; gaps {}; 1000 edge terms {:.6}", s, row(&gaps, 6), edge);
        assert!(inside.iter().zip(&areas).all(|(v, a)| (v - a).abs() < 1e-9)); // road one = road two
        assert!(gaps[2] < gaps[1] && gaps[1] < gaps[0] && gaps[2] < 0.001);
        assert!((edge - s).abs() < 1.0 / (last + 2) as f64); // alternating-series bound
    }
    let (big_n, big_m) = (10, 60);
    let grid: Vec<f64> = (0..=100).map(|k| k as f64 / 100.0).collect();
    let cap = (big_n + 1..=big_m).map(|m| (big_n + 1..=m).map(ln_c).sum::<f64>().abs()).fold(0.0, f64::max);
    let tails: Vec<f64> = grid.iter()
        .map(|&x| (big_n + 1..=big_m).map(|n| ln_c(n) * x.powi(n as i32)).sum::<f64>().abs()).collect();
    let ok = tails.iter().zip(&grid).all(|(t, x)| *t <= cap * x.powi(big_n as i32 + 1) + 1e-15);
    println!("Abel's lemma, terms 11 to 60 of ln(1+x), 101 inputs: worst tail {:.6}; cap {:.6} x^11 never beaten: {}",
        tails.iter().cloned().fold(0.0, f64::max), cap, if ok { "yes" } else { "no" });
    assert!(ok);
    let (f9, sn) = (series(ln_c, 0.9), partial(ln_c, 400));
    let avg = (1.0 - 0.9) * sn.iter().enumerate().map(|(n, v)| (v - ln2) * 0.9_f64.powi(n as i32)).sum::<f64>();
    println!("average road at x = 0.9: f(x) - s = {:.6}; (1 - x) sum (s_n - s) x^n = {:.6}", f9 - ln2, avg);
    assert!(((f9 - ln2) - avg).abs() < 1e-9);
    let g3: Vec<f64> = xs.iter().map(|&x| series(geo_c, x)).collect();
    let closed: Vec<f64> = xs.iter().map(|x| 1.0 / (1.0 + x)).collect();
    let gs = partial(geo_c, 1000);
    let mut vals = gs.clone();
    vals.sort_by(|a, b| a.partial_cmp(b).unwrap());
    vals.dedup();
    println!("1 - x + x^2 - ... at 0.9, 0.99, 0.999: {}; 1/(1+x): {}", row(&g3, 6), row(&closed, 6));
    println!("  edge partial sums of 1 - 1 + 1 - ...: {}, ...; values taken: {:?}", row(&gs[..6], 0), vals);
    assert!(g3.iter().zip(&closed).all(|(v, w)| (v - w).abs() < 1e-9) && vals == vec![0.0, 1.0]);
    println!("mistake, 1 - 2x + 3x^2 - ... at 0.999: {:.6}, 1/(1+x)^2 = {:.6}; edge sums {}",
        series(eu_c, 0.999), 1.0 / 1.999_f64.powi(2), row(&partial(eu_c, 5), 0));
    println!("mistake, past the edge: term 1000 of the ln series at x = 1.01 is {:.2}", ln_c(1000) * 1.01_f64.powi(1000));
    let cx = [0.5, 0.6, 0.7, 0.8, 0.9, 0.95, 0.99, 0.999];
    println!("chart, x: {}", row(&cx, 3));
    for (name, c) in [("ln(1+x)", ln_c as fn(i64) -> f64), ("arctan x", at_c), ("1/(1+x)", geo_c)] {
        let v: Vec<f64> = cx.iter().map(|&x| series(c, x)).collect();
        println!("chart, {} by its series: {}", name, row(&v, 2));
    }
    println!("ALL CHECKS PASS");
}
