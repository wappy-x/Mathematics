// Swapping limits -- the same check as the Python, in Rust.  No crates.
// sin and ln are primitives; every integral, slope and sum below is built
// here, and each answer is reached by two roads that share no arithmetic.
fn spike(n: f64, x: f64) -> f64 { // tent on [0, 1/n], peak 2n at x = 1/(2n)
    (2.0 * n - (4.0 * n * n * x - 2.0 * n).abs()).max(0.0)
}

fn midpoint(f: impl Fn(f64) -> f64, a: f64, b: f64, m: usize) -> f64 { // m rectangles, read at the middle
    let h = (b - a) / m as f64;
    h * (0..m).map(|i| f(a + (i as f64 + 0.5) * h)).sum::<f64>()
}

fn simpson(f: impl Fn(f64) -> f64, a: f64, b: f64, m: usize) -> f64 { // weights 1 4 2 4 ... 4 1
    let h = (b - a) / m as f64;
    let w = |i: usize| if i == 0 || i == m { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 };
    h / 3.0 * (0..=m).map(|i| w(i) * f(a + i as f64 * h)).sum::<f64>()
}

fn s(x: f64) -> f64 { x / (2.0 - x) } // the sum of (x/2)^k for k = 1, 2, 3, ...

fn main() {
    for n in [1.0, 2.0, 4.0] {
        let r: Vec<String> = (0..9).map(|i| format!("{:.2}", spike(n, i as f64 / 8.0))).collect();
        println!("chart n={}: {}", n, r.join(" "));
    }
    for n in [1.0, 10.0, 50.0, 1000.0] {
        let tri = 0.5 * (1.0 / n) * (2.0 * n);                      // road one: half base times height
        let rect = midpoint(|x| spike(n, x), 0.0, 1.0, 100000);     // road two: 100,000 rectangles
        assert!((tri - rect).abs() < 1e-9);
        println!("spike n={}: worst gap {}, area by triangle {:.6}, by rectangles {:.6}, height at x=0.01 {:.6}",
            n, 2.0 * n, tri, rect, spike(n, 0.01));
    }
    println!("integral of the limit (0 everywhere): {:.6}", midpoint(|_| 0.0, 0.0, 1.0, 1000));
    let exact = 2.0 * 2f64.ln() - 1.0;                              // from the antiderivative -x - 2 ln(2 - x)
    let simp = simpson(s, 0.0, 1.0, 1000);
    println!("integral of S on [0, 1]: antiderivative {:.9}, Simpson {:.9}", exact, simp);
    for big_n in [5, 10, 20] {
        let partial = |x: f64| (1..=big_n).map(|k| (x / 2.0).powi(k)).sum::<f64>();
        let worst = (0..=1000).map(|i| (s(i as f64 / 1000.0) - partial(i as f64 / 1000.0)).abs()).fold(0.0, f64::max);
        let tbt: f64 = (1..=big_n).map(|k| 1.0 / ((k + 1) as f64 * 2f64.powi(k))).sum(); // term by term
        assert!(0.0 < simp - tbt && simp - tbt <= (1.0 - 0.0) * worst); // miss <= (b - a) * worst gap
        println!("N={}: worst gap {:.9}, integrals of terms {:.9}, miss {:.9}", big_n, worst, tbt, exact - tbt);
    }
    let h = 1e-6;
    for n in [1.0, 10.0, 100.0] {
        let worst = (0..=70000).map(|i| (n * i as f64 / 10000.0).sin().abs() / n).fold(0.0, f64::max);
        let slope0 = ((n * h).sin() - (-n * h).sin()) / (2.0 * n * h); // difference quotient at 0
        assert!((slope0 - 1.0).abs() < 1e-6 && (worst * n - 1.0).abs() < 1e-3); // gap 1/n, slope stuck at 1
        println!("wave n={}: worst gap {:.6}, slope at 0 {:.6}; limit 0, its slope 0", n, worst, slope0);
    }
    let x: f64 = 0.5;
    let tbt: f64 = (1..80).map(|k| k as f64 * x.powi(k - 1) / 2f64.powi(k)).sum(); // slopes of the terms
    let dq = (s(x + h) - s(x - h)) / (2.0 * h);                     // slope of the sum, measured
    assert!((tbt - dq).abs() < 1e-7);
    println!("slope of S at {}: term by term {:.6}, difference quotient {:.6}, formula 2/(2-x)^2 {:.6}",
        x, tbt, dq, 2.0 / (2.0 - x).powi(2));
    let caps: f64 = (1..61).map(|k| k as f64 / 2f64.powi(k)).sum();
    println!("caps on the slope terms, k/2^k added to k=60: {:.6}", caps);
    for n in [10.0, 1000.0] {
        println!("block n={} on [0, {}]: worst gap {:.6}, area {:.6}", n, n, 1.0 / n, midpoint(|_| 1.0 / n, 0.0, n, 1000));
    }
    println!("ALL CHECKS PASS");
}
