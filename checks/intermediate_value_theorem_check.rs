// Intermediate value theorem -- the same check as the Python, in Rust.  No crates.
// f(x) = x*x - 2 on [1, 2]: f(1) < 0 < f(2), so a root exists.  Road 1 halves
// the bracket in exact whole numbers (x = k / 2^n); road 2 scans a grid; road 3
// averages x and 2/x again and again.  Then three functions that break the theorem.
fn f(x: f64) -> f64 { x * x - 2.0 }

fn bisect(g: &dyn Fn(f64) -> f64, mut lo: f64, mut hi: f64, steps: u32) -> (f64, f64) {
    for _ in 0..steps {                  // keep the half whose ends still straddle 0
        let m = (lo + hi) / 2.0;
        if g(m) < 0.0 { lo = m } else { hi = m }
    }
    (lo, hi)
}

fn jump(x: f64) -> f64 { if x < 1.5 { -1.0 } else { 1.0 } }
fn h(x: f64) -> f64 { x * x * x - x }

fn main() {
    println!("f(1) = {:.2}, f(2) = {:.2}: the signs differ", f(1.0), f(2.0));
    let chart: Vec<String> = (0..11).map(|i| format!("{:.2}", f((10 + i) as f64 / 10.0))).collect();
    println!("chart, f(x) at x = 1.0, 1.1, ..., 2.0: {}", chart.join(" "));
    let (mut lo, mut hi, mut den, mut bad): (i64, i64, i64, i64) = (1, 2, 1, 0);
    for n in 1..=12 {                    // the bracket is [lo/den, hi/den], exactly
        lo *= 2; hi *= 2; den *= 2;
        let m = lo + 1;                  // the midpoint, in the finer units
        if m * m == 2 * den * den { bad += 1 }
        if m * m < 2 * den * den { lo = m } else { hi = m }
        if n <= 4 {
            let (x, d) = (m as f64, den as f64);
            println!("halving {}: m = {:.8}, f(m) = {:.8}, keep [{:.8}, {:.8}]",
                     n, x / d, f(x / d), lo as f64 / d, hi as f64 / d);
        }
    }
    let d = den as f64;
    println!("road 1, halving 12: [{}/{}, {}/{}] = [{:.12}, {:.12}]", lo, den, hi, den, lo as f64 / d, hi as f64 / d);
    println!("midpoint {:.13}, root within 1/{} = {:.13}", (lo + hi) as f64 / (2.0 * d), 2 * den, 1.0 / (2.0 * d));
    let mut k = den;                     // road 2: walk the grid k/4096 up from 1
    while (k + 1) * (k + 1) < 2 * den * den { k += 1 }
    println!("road 2, grid scan: largest k with k*k < 2*{}*{} is {}", den, den, k);
    let b50 = bisect(&f, 1.0, 2.0, 50).0;
    let (mut x, mut heron) = (1.5_f64, Vec::new());
    for _ in 0..4 {                      // road 3: average x and 2/x, from 1.5
        x = (x + 2.0 / x) / 2.0;
        heron.push(x);
    }
    println!("50 halvings in floats: {:.15}", b50);
    let nw: Vec<String> = heron.iter().map(|v| format!("{:.15}", v)).collect();
    println!("road 3, averaging from 1.5: {}", nw.join(" "));
    let worst = (0..1001).map(|i| 0.00025 * (i - 500) as f64 / 500.0)
        .map(|dx| (f(b50 + dx) - f(b50)).abs()).fold(0.0_f64, f64::max);
    println!("tolerance game at the root: inputs within 0.00025 move f by at most {:.6} < 0.001", worst);
    println!("midpoints squaring to exactly 2 in 12 halvings: {}", bad);
    let jh = bisect(&jump, 1.0, 2.0, 40).1;
    println!("jump: ends {:.0}, {:.0}; bisection closes on {:.10}, where it is {:.0}", jump(1.0), jump(2.0), jh, jump(jh));
    let roots: Vec<f64> = (-8..9).map(|i| i as f64 / 4.0).filter(|&x| h(x) == 0.0).collect();
    println!("x^3 - x on [-2, 2]: ends {:.0}, {:.0}; grid roots {:?}; first midpoint {:.1}", h(-2.0), h(2.0), roots, (-2.0 + 2.0) / 2.0);
    let rises = (0..10).all(|i| f((11 + i) as f64 / 10.0) > f((10 + i) as f64 / 10.0));
    println!("f rises at every step of the grid: {}", if rises { "yes" } else { "no" });
    assert!((lo, hi) == (k, k + 1));                    // halving meets the grid scan
    assert!((b50 - heron[3]).abs() < 1e-15);           // halving meets averaging
    assert!(roots == vec![-1.0, 0.0, 1.0]);             // the factors x, x - 1, x + 1
    assert!(worst <= 4.0 * 0.00025);                    // |f(x) - f(c)| <= 4|x - c|
    println!("ALL CHECKS PASS");
}
