// Term by term -- the check behind the card.  std gives pi, sin and cos only.
// Coefficients are integrated by a midpoint rule written here; every series is
// summed here; each answer is met by a second road that shares no arithmetic.
use std::f64::consts::PI;

fn midpoint<F: Fn(f64) -> f64>(g: F, a: f64, b: f64) -> f64 {
    let m = 200000;                          // m slices, each read at its middle
    let h = (b - a) / m as f64;
    h * (0..m).map(|k| g(a + (k as f64 + 0.5) * h)).sum::<f64>()
}
fn saw(x: f64) -> f64 { x }                  // the sawtooth on -pi < x < pi
fn sign(n: u32) -> f64 { if n % 2 == 0 { 1.0 } else { -1.0 } } // (-1)^n
fn b(n: u32) -> f64 { -2.0 * sign(n) / n as f64 } // its sine coefficients, closed form
fn tri_a(n: u32) -> f64 { if n % 2 == 1 { -4.0 / (PI * (n * n) as f64) } else { 0.0 } }
fn sq(n: u32) -> f64 { if n % 2 == 1 { 4.0 / (PI * n as f64) } else { 0.0 } } // sgn x

fn main() {
    // Road 1 against road 2: coefficients by formula and by integration.
    for n in 1..=3u32 {
        let num = midpoint(|x| saw(x) * (n as f64 * x).sin(), -PI, PI) / PI;
        assert!((num - b(n)).abs() < 1e-8);
        println!("sawtooth b_{}: formula {:.6}, integrated {:.6}", n, b(n), num);
    }
    // The slope f' = 1 has cosine coefficients 0 for n >= 1, yet n b_n is not 0.
    let j = saw(PI) - saw(-PI);              // how far the sawtooth falls when it wraps
    for n in 1..=3u32 {
        let num = midpoint(|x| (n as f64 * x).cos(), -PI, PI) / PI;
        let jump = 2.0 * sign(n) * j / (2.0 * PI); // the jump's share, in cosine form
        let nb = n as f64 * b(n);
        assert!((num - (nb + jump)).abs() < 1e-8);
        println!("n={}: n b_n {:.6}, jump term {:.6}, true coefficient of f' {:.6}", n, nb, jump, num.abs());
    }

    // The failure: differentiate x = sum b_n sin(nx) term by term, read at pi/2.
    let x = PI / 2.0;
    let true_slope = (saw(x + 1e-6) - saw(x - 1e-6)) / 2e-6;
    let mut d = 0.0;
    let mut partial = Vec::new();
    for n in 1..=1000u32 {
        d += n as f64 * b(n) * (n as f64 * x).cos();
        partial.push(d);
    }
    let w = 2.0 * PI * 220.0;                // radians of phase per second at 220 cycles a second
    println!("slope of the sawtooth at pi/2, difference quotient: {:.6} V per radian = {:.1} V/s", true_slope, true_slope * w);
    println!("term by term claims 0 or 2 V per radian = 0 or {:.1} V/s", 2.0 * w);
    let row: Vec<String> = partial[..12].iter().map(|v| format!("{:.4}", v.abs())).collect();
    println!("sawtooth, term-by-term slope at pi/2, N=1..12: {}", row.join(" "));
    let closest = partial[100..].iter().map(|v| (v - true_slope).abs()).fold(f64::INFINITY, f64::min);
    assert!(closest > 0.99);                 // never within 0.99 of 1
    let fejer = partial.iter().sum::<f64>() / partial.len() as f64;
    println!("average of the first 1000 partial sums: {:.6}", fejer);
    assert!((fejer - true_slope).abs() < 1e-9);
    let top = (1000..=1010u32).map(|n| (n as f64 * b(n) * (n as f64).cos()).abs()).fold(0.0, f64::max);
    println!("largest term size for n=1000..1010 at x=1: {:.6} (terms never shrink)", top);
    assert!(top > 1.0);

    // The legal case: the triangle |x|, the integral of the square wave.
    for n in [1u32, 2, 3] {
        let num = midpoint(|t| t.abs() * (n as f64 * t).cos(), -PI, PI) / PI;
        assert!((num - tri_a(n)).abs() < 1e-8);
        println!("triangle a_{}: formula {:.6}, integrated {:.6}", n, tri_a(n), if num.abs() > 1e-9 { num } else { 0.0 });
    }
    let mut s = 0.0;
    let mut rows = vec![0.0; 1002];
    for n in 1..=1001u32 {
        s += -(n as f64) * tri_a(n) * (n as f64 * x).sin(); // derivative of a_n cos(nx) is -n a_n sin(nx)
        rows[n as usize] = s;
    }
    let row: Vec<String> = (1..=12).map(|n| format!("{:.4}", rows[n])).collect();
    println!("triangle, term-by-term slope at pi/2, N=1..12: {}", row.join(" "));
    for big_n in [11usize, 101, 1001] {
        let err = (rows[big_n] - 1.0).abs();
        let bound = 4.0 / (PI * (big_n + 2) as f64); // alternating: next term caps the miss
        assert!(err <= bound);
        println!("N={}: sum {:.6}, miss {:.6}, bound from the next term {:.6}", big_n, rows[big_n], err, bound);
    }

    // Integration: integrate x = sum b_n sin(nx) from 0 to pi/2 term by term.
    let exact = x * x / 2.0;
    let quad = midpoint(saw, 0.0, x);
    println!("integral of the sawtooth from 0 to pi/2: x^2/2 = {:.6}, midpoint rule {:.6}", exact, quad);
    assert!((exact - quad).abs() < 1e-9);
    let mut integ = 0.0;
    for n in 1..=1000u32 {
        integ += b(n) * (1.0 - (n as f64 * x).cos()) / n as f64; // integral of sin(ny) from 0 to x
        if [1, 2, 3, 10, 100, 1000].contains(&n) {
            let (miss, bound) = ((integ - exact).abs(), 4.0 / n as f64);
            assert!(miss <= bound);
            println!("N={}: integrated terms {:.6}, miss {:.6}, tail bound 4/N {:.6}", n, integ, miss, bound);
        }
    }
    let no_const = integ - (1..=200000u32).map(|n| b(n) / n as f64).sum::<f64>(); // no constant
    println!("forget the constant pi^2/6 = {:.6}: {:.4}", PI * PI / 6.0, no_const);
    assert!((no_const - (exact - PI * PI / 6.0)).abs() < 1e-4);

    // An on-off version of the siren: g = (1 + sgn x)/2, 0 V or 1 V, mean 1/2; integrate to pi/2.
    let osc: f64 = (1..=200000u32).map(|n| 0.5 * sq(n) * (1.0 - (n as f64 * x).cos()) / n as f64).sum();
    println!("on-off wave, integral to pi/2: true {:.4}, terms only {:.4}, with the mean term {:.4}",
             midpoint(|_t| 1.0, 0.0, x), osc, 0.5 * x + osc);
    assert!((0.5 * x + osc - x).abs() < 1e-5);      // g = 1 V on (0, pi/2): integral pi/2
    let bounce: Vec<f64> = [1u32, 3, 5, 7].iter()
        .map(|&big_n| 4.0 / PI * (1..=big_n).step_by(2).map(|k| (k as f64 * PI / 4.0).cos()).sum::<f64>())
        .collect();
    let row: Vec<String> = bounce.iter().map(|v| format!("{:.4}", if v.abs() > 1e-9 { *v } else { 0.0 })).collect();
    println!("square wave, term-by-term slope at pi/4, N=1,3,5,7: {}", row.join(" "));
    assert!(bounce[0].abs() > 0.9 && bounce[2].abs() > 0.9); // the square wave is flat there: slope 0
    println!("ALL CHECKS PASS");
}
