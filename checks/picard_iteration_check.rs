// Picard iteration -- the same check as the Python, in Rust.  No crates.
// Road one feeds polynomial coefficients back in.  Road two feeds a curve
// sampled on a grid back in, adding up trapezoids; it never learns the curves
// are polynomials.  exp and sqrt are primitives; the iteration is ours.
fn coeffs(n: usize, lead: f64) -> Vec<f64> { // y' = y, y(0) = 1: integrate, then add lead
    let mut c = vec![1.0];
    for _ in 0..n {
        let mut next = vec![lead];
        next.extend(c.iter().enumerate().map(|(k, a)| a / (k + 1) as f64));
        c = next;
    }
    c
}

fn value(c: &[f64], t: f64) -> f64 { c.iter().enumerate().map(|(k, a)| a * t.powi(k as i32)).sum() }

fn picard_grid(f: &dyn Fn(f64, f64) -> f64, y0: f64, big_t: f64, sweeps: usize, guess: &dyn Fn(f64) -> f64) -> Vec<f64> {
    let n = 1000;                        // end value of each iterate
    let dt = big_t / n as f64;
    let ts: Vec<f64> = (0..=n).map(|i| i as f64 * dt).collect();
    let mut ys: Vec<f64> = ts.iter().map(|&t| guess(t)).collect();
    let mut ends = vec![ys[n]];
    for _ in 0..sweeps {
        let rate: Vec<f64> = ts.iter().zip(&ys).map(|(&t, &y)| f(t, y)).collect();
        ys = vec![y0];
        for i in 0..n { let last = ys[i]; ys.push(last + dt * (rate[i] + rate[i + 1]) / 2.0) }
        ends.push(ys[n]);
    }
    ends
}

fn euler(h: f64) -> f64 {                // small steps along the slope, to t = 1
    let mut y = 1.0;
    for _ in 0..(1.0 / h).round() as usize { y += h * y }
    y
}

fn fact(n: usize) -> f64 { (1..=n).map(|k| k as f64).product() }

fn row(v: &[f64], d: usize) -> String { v.iter().map(|x| format!("{:.*}", d, x)).collect::<Vec<_>>().join(" ") }

fn main() {
    let e = 1f64.exp();
    let grid = picard_grid(&|_t, y| y, 1.0, 1.0, 5, &|_t| 1.0);
    for n in 0..6 {
        let (v, bound) = (value(&coeffs(n, 1.0), 1.0), 2.0 / fact(n + 1));
        println!("iterate {} at t=1: coefficients {:.6}, grid {:.6}, gap to e {:.6}, bound {:.6}", n, v, grid[n], e - v, bound);
    }
    let ts = [0.0, 0.2, 0.4, 0.6, 0.8, 1.0];
    println!("figure, t (h): {}", row(&ts, 1));
    for n in 1..4 {
        let vals: Vec<f64> = ts.iter().map(|&t| value(&coeffs(n, 1.0), t)).collect();
        println!("figure, iterate {}: {}", n, row(&vals, 2));
    }
    println!("figure, e^t: {}", row(&ts.iter().map(|t| t.exp()).collect::<Vec<_>>(), 2));
    let (e1, e2) = (euler(0.01), euler(0.001));
    println!("euler's rule to t=1: step 0.01 gives {:.6} (gap {:.6}), step 0.001 gives {:.6} (gap {:.6})", e1, e - e1, e2, e - e2);
    let bucket = picard_grid(&|_t, h: f64| -0.2 * h.sqrt(), 25.0, 10.0, 6, &|_t| 25.0);
    let exact = (5.0 - 0.1 * 10.0f64).powi(2);
    println!("bucket at t=10 min, iterates 0-6: {}; exact {:.4}", row(&bucket, 4), exact);
    let root = |_t: f64, y: f64| y.max(0.0).sqrt();
    let zero = picard_grid(&root, 0.0, 2.0, 5, &|_t| 0.0);
    let other = picard_grid(&root, 0.0, 2.0, 1, &|t| t * t / 4.0);
    println!("y' = sqrt(y), y(0) = 0, at t=2: iterates from 0 give {:.4}; t^2/4 fed in returns {:.4}", zero[5], other[1]);
    println!("mistake, y0 not added after integrating: iterate 5 at t=1 is {:.6}", value(&coeffs(5, 0.0), 1.0));
    assert!((grid[5] - value(&coeffs(5, 1.0), 1.0)).abs() < 1e-5);             // two roads, one iterate
    assert!((0..6).all(|n| { let g = e - value(&coeffs(n, 1.0), 1.0); 0.0 < g && g <= 2.0 / fact(n + 1) }));
    assert!((bucket[6] - exact).abs() < 1e-4);                            // the bucket converges
    assert!(9.0 < (e - e1) / (e - e2) && (e - e1) / (e - e2) < 11.0 && (e - e2).abs() < 2e-3);
    println!("ALL CHECKS PASS");
}
