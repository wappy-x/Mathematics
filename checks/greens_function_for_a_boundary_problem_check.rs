// Green's function for -y'' = f with zero ends -- the same check as the Python, in Rust.
// A canvas shelf 1 m long; sag y in m; load f = weight per metre / tension.
// Road 1: the tent G(x, s) built from Step 3's corner conditions, summed against the load.
// Road 2: a finite-difference grid solving -y'' = f directly, never using G.
fn build(s: f64, jump: f64) -> (f64, f64) { // A s - B (1 - s) = 0 and -A - B = jump, by Cramer's rule
    let det = s * -1.0 - (-(1.0 - s)) * -1.0;
    ((0.0 * -1.0 - (-(1.0 - s)) * jump) / det, (s * jump - 0.0 * -1.0) / det)
}
fn gj(x: f64, s: f64, jump: f64) -> f64 { // the tent for a unit load at s: A x left of s, B (1 - x) right of it
    let (a, b) = build(s, jump);
    if x <= s { a * x } else { b * (1.0 - x) }
}
fn g(x: f64, s: f64) -> f64 { gj(x, s, -1.0) }
fn green_sum(x: f64, f: &dyn Fn(f64) -> f64, top: f64) -> f64 { // midpoint rule for the sum of G(x, s) f(s) over s from 0 to top
    let (m, h) = (2000, top / 2000.0);
    (0..m).map(|j| { let s = (j as f64 + 0.5) * h; g(x, s) * f(s) }).sum::<f64>() * h
}
fn grid_solve(n: usize, rhs: &[f64]) -> Vec<f64> { // (-y[i-1] + 2 y[i] - y[i+1]) / h^2 = rhs[i], zero ends, Thomas algorithm
    let h = 1.0 / n as f64;
    let (mut cp, mut dp, mut y) = (vec![0.0; n], vec![0.0; n], vec![0.0; n + 1]);
    for i in 1..n {
        let den = 2.0 + cp[i - 1];
        cp[i] = -1.0 / den;
        dp[i] = (rhs[i] * h * h + dp[i - 1]) / den;
    }
    for i in (1..n).rev() { y[i] = dp[i] - cp[i] * y[i + 1]; } y
}
fn bag_grid(n: usize, at: f64, p: f64) -> Vec<f64> { // the bag as load P / h on the one node at `at`
    let k = (at * n as f64).round() as usize;
    grid_solve(n, &(0..=n).map(|i| if i == k { p * n as f64 } else { 0.0 }).collect::<Vec<_>>())
}
fn fmt(v: &[f64]) -> String { v.iter().map(|a| format!("{:.4}", a)).collect::<Vec<_>>().join(" ") }
fn main() {
    let (t, w, q) = (10.0 * 9.81, 5.0 * 9.81, 10.0 * 9.81 / 1.0); // tension = weight of 10 kg; bag 5 kg; books 10 kg/m
    let p = w / t;
    let xs: Vec<f64> = (0..=10).map(|i| i as f64 / 10.0).collect();
    let one = |_s: f64| q / t;
    let (a, b) = build(0.3, -1.0);
    let books_g: Vec<f64> = xs.iter().map(|&x| green_sum(x, &one, 1.0)).collect();
    let books_d = grid_solve(10, &[q / t; 11]);
    let bag_g: Vec<f64> = xs.iter().map(|&x| p * g(x, 0.3)).collect();
    let bag_d = bag_grid(10, 0.3, p);
    let (left, right) = ((bag_d[3] - bag_d[2]) / 0.1, (bag_d[4] - bag_d[3]) / 0.1);
    let recip = bag_grid(10, 0.7, p)[3];
    println!("shelf: tension {:.2} N, bag {:.2} N, P = {:.4}; books {:.2} N/m, f = {:.4} per m", t, w, p, q, q / t);
    println!("construction at s = 0.3: A = {:.4}, B = {:.4}, peak G(0.3, 0.3) = {:.4}", a, b, a * 0.3);
    println!("x                     {}", xs.iter().map(|x| format!("{:.1}", x)).collect::<Vec<_>>().join("    "));
    println!("books, Green sum      {}", fmt(&books_g));
    println!("books, grid h = 0.1   {}", fmt(&books_d));
    println!("bag, 0.5 G(x, 0.3)    {}", fmt(&bag_g));
    println!("bag, grid h = 0.1     {}", fmt(&bag_d));
    println!("peak sag under the bag {:.4} m at x = 0.3; books at the middle {:.4} m", bag_d[3], books_d[5]);
    println!("slopes beside the bag, grid: left {:.4}, right {:.4}, jump {:.4}", left, right, right - left);
    println!("reciprocity, grid: bag at 0.3 sags x = 0.7 by {:.4}; bag at 0.7 sags x = 0.3 by {:.4}", bag_d[7], recip);
    for n in [10usize, 20] {
        let nf = n as f64;
        let eb = grid_solve(n, &vec![1.0; n + 1]).iter().enumerate()
            .map(|(i, v)| (v - (i as f64 / nf) * (1.0 - i as f64 / nf) / 2.0).abs()).fold(0.0, f64::max);
        let ep = bag_grid(n, 0.3, p).iter().enumerate()
            .map(|(i, v)| (v - p * g(i as f64 / nf, 0.3)).abs()).fold(0.0, f64::max);
        println!("grid h = {:.2}: every node within 1e-15 of the kernel, books and bag: {}",
                 1.0 / nf, if eb.max(ep) < 1e-15 { "yes" } else { "no" });
    }
    println!("mistake 1, no slope jump (left piece everywhere): far end at {:.4} m, not 0", p * a * 1.0);
    println!("mistake 2, loads on the left only: books at the middle {:.4} m, not {:.4}",
             green_sum(0.5, &one, 0.5), books_g[5]);
    println!("mistake 3, jump of +1: bag at x = 0.3 gives {:.4} m, the shelf lifted", p * gj(0.3, 0.3, 1.0));
    println!("mistake 4, sliding ends y'(0) = y'(1) = 0: y'(1) - y'(0) = {:.4}, needs 0",
             -(0..10).map(|_| 0.1).sum::<f64>());
    let px = |x: f64, v: f64| format!("({:.0},{:.0})", 40.0 + 280.0 * x, 60.0 + 800.0 * v);
    println!("figure, 280 px/m across, 800 px/m down, depth x {:.2}; bag tent px: {} {} {}",
             800.0 / 280.0, px(0.0, bag_d[0]), px(0.3, bag_d[3]), px(1.0, bag_d[10]));
    println!("figure, books px y at x = 0 to 1: {}",
             books_d.iter().map(|v| format!("{:.0}", 60.0 + 800.0 * v)).collect::<Vec<_>>().join(" "));
    assert!(books_g.iter().zip(&books_d).map(|(u, v)| (u - v).abs()).fold(0.0, f64::max) < 1e-12);
    assert!(bag_g.iter().zip(&bag_d).map(|(u, v)| (u - v).abs()).fold(0.0, f64::max) < 1e-12);
    assert!(((right - left) - (-p)).abs() < 1e-9); // grid kink = derived jump
    assert!((bag_d[7] - recip).abs() < 1e-12); // reciprocity on the grid
    println!("ALL CHECKS PASS");
}
