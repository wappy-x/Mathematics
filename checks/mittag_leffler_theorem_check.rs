// Mittag-Leffler's theorem: the same check as the Python, in Rust.  No crates.
// A row of charged wires sits at every whole number n; the wire at n adds
// 1/(z - n) to the field at z.  The sum diverges until each term has its value
// at 0 subtracted; then it is pi cot(pi z), and its derivative gives pi^2/6.
use std::f64::consts::PI;
const N: i64 = 100000;                           // wires counted on each side
fn f6(x: f64) -> String { format!("{:.6}", (x * 1e6).round() / 1e6 + 0.0) }   // never -0.000000
fn cot_series(z: f64) -> f64 {                   // road one: 1/z + sum of 2z/(z^2 - k^2), plus its tail
    1.0 / z + (1..=N).map(|k| { let k = k as f64; 2.0 * z / (z * z - k * k) }).sum::<f64>() - 2.0 * z / (N as f64 + 0.5)
}
fn sq_series(z: f64) -> f64 {                    // sum over all k of 1/(z - k)^2, plus its tail
    (-N..=N).map(|k| 1.0 / ((z - k as f64) * (z - k as f64))).sum::<f64>() + 2.0 / (N as f64 + 0.5)
}
fn pcot(z: f64) -> f64 { PI * (PI * z).cos() / (PI * z).sin() }               // road two: the closed form
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a } else { gcd(b, a % b) } }
fn sum_to(m: i64, f: &dyn Fn(f64) -> f64) -> f64 { (-m..=2 * m).map(|k| f(k as f64)).sum() }
fn main() {
    let (mut a, mut b) = (0i128, 1i128);         // road three: exact fractions, 1/(k^2 - 1/4) = 4/(4k^2 - 1)
    for k in 1..=1000i128 {
        let d = 4 * k * k - 1;
        a = a * d + 4 * b; b *= d;
        let g = gcd(a, b); a /= g; b /= g;
    }
    println!("z = 0.5, midway: series {}; pi cot(pi z) {}", f6(cot_series(0.5)), f6(pcot(0.5)));
    let pairs: Vec<String> = [1.0, 2.0, 3.0].iter().map(|&k: &f64| f6(1.0 / (0.25 - k * k))).collect();
    println!("pairs n = 1, 2, 3 at z = 0.5, 1/(1/4 - n^2): {}", pairs.join(", "));
    println!("sum of 1/(n^2 - 1/4) to n = 1000, exact: {}/{} = 2 - 1/1000.5 = {}", a, b, f6(a as f64 / b as f64));
    assert!(a * 2001 == 4000 * b && cot_series(0.5).abs() < 1e-9);
    for z in [0.25, 0.1] {
        println!("z = {}: series {}; pi cot(pi z) {}", z, f6(cot_series(z)), f6(pcot(z)));
        assert!((cot_series(z) - pcot(z)).abs() < 1e-9);
    }
    let y = 2.0;                                 // straight above the wire at 0: z = 2i
    let above = 1.0 / y + (1..=N).map(|k| { let k = k as f64; 2.0 * y / (y * y + k * k) }).sum::<f64>() + 2.0 * y / (N as f64 + 0.5);
    let e = (2.0 * PI * y).exp();
    let coth = PI * (e + 1.0) / (e - 1.0);
    println!("z = 2i: field -i x {}; pi coth(2 pi) = {}; a flat sheet gives pi = {}", f6(above), f6(coth), f6(PI));
    assert!((above - coth).abs() < 1e-9);
    let s2 = sq_series(0.25);
    let sq = PI / (PI / 4.0).sin();
    println!("z = 0.25: sum of 1/(z - n)^2 {}; pi^2/sin^2(pi z) {}", f6(s2), f6(sq * sq));
    println!("one step along the row: cot series at 1.25 minus at 0.25 = {}", f6(cot_series(1.25) - cot_series(0.25)));
    assert!((s2 - 2.0 * PI * PI).abs() < 1e-9 && (cot_series(1.25) - cot_series(0.25)).abs() < 1e-6);
    let basel = (1..=N).map(|k| 1.0 / (k as f64 * k as f64)).sum::<f64>() + 1.0 / (N as f64 + 0.5);
    let s = PI / (PI * 1e-3).sin();
    let near0 = s * s - 1e6;
    println!("pi^2/sin^2(pi z) - 1/z^2 at z = 0.001: {}; pi^2/3 = {}", f6(near0), f6(PI * PI / 3.0));
    println!("sum of 1/n^2: {}; half of pi^2/3 = pi^2/6 = {}", f6(basel), f6(PI * PI / 6.0));
    assert!((near0 - PI * PI / 3.0).abs() < 1e-4 && (basel - PI * PI / 6.0).abs() < 1e-12);
    let ms = [1, 2, 5, 10, 20, 50, 100, 200, 500, 1000];   // chart: wires n = -M ... 2M, lopsided
    let raw: Vec<f64> = ms.iter().map(|&m| sum_to(m, &|k| 1.0 / (0.25 - k))).collect();
    let fix: Vec<f64> = ms.iter().map(|&m| 4.0 + sum_to(m, &|k| if k == 0.0 { 0.0 } else { 1.0 / (0.25 - k) + 1.0 / k })).collect();
    let show = |v: &Vec<f64>| v.iter().map(|x| format!("{:.2}", x)).collect::<Vec<_>>().join(", ");
    println!("chart, raw sum at z = 0.25, n = -M ... 2M: {}", show(&raw));
    println!("chart, corrected sum, same wires: {}", show(&fix));
    assert!((raw[9] - (PI - 2f64.ln())).abs() < 1e-3 && (fix[9] - PI).abs() < 1e-3);
    let one: f64 = (0..=1000).map(|k| 1.0 / (0.25 - k as f64)).sum();
    println!("mistake, raw sum over n = 0 ... 1000 only: {}; raw limit for n = -M ... 2M: {}, near pi - ln 2 = {}",
             f6(one), f6(raw[9]), f6(PI - 2f64.ln()));
    println!("mistake, pi^2/3 read as the sum of 1/n^2: {}, not {}", f6(PI * PI / 3.0), f6(PI * PI / 6.0));
    let d0 = |kk: i64| (1..=kk).map(|k| { let r = (k as f64).sqrt(); 0.5 / (r * (0.5 - r)) }).sum::<f64>();
    let d1 = |kk: i64| (1..=kk).map(|k| 0.25 / (k as f64 * (0.5 - (k as f64).sqrt()))).sum::<f64>();
    let ks = [1000, 10000, 100000];
    let j = |f: &dyn Fn(i64) -> f64| ks.iter().map(|&k| f6(f(k))).collect::<Vec<_>>().join(", ");
    println!("poles at sqrt(k), z = 0.5, K = 1000, 10000, 100000: degree-0 fix {}; degree-1 fix {}", j(&d0), j(&d1));
    assert!(((d0(ks[1]) - d0(ks[2])) - 0.5 * 10f64.ln()).abs() < 0.01 && (d1(ks[1]) - d1(ks[2])).abs() < 0.005);
    println!("ALL CHECKS PASS");
}
