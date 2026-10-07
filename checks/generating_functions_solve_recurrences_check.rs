// Solving a recurrence with a generating function -- the same check as the Python,
// in Rust.  No crates.  A bar of n beats is filled with one-beat and two-beat
// notes and counted three ways: by listing every pattern, by dividing the series
// x by 1 - x - x^2, and by the two geometric pieces that fraction splits into.
// The whole-number case 2^n + 3^n out of (2 - 5x) / (1 - 5x + 6x^2) follows.
fn rhythms(n: usize) -> Vec<String> {              // road one: list every pattern
    if n == 0 { return vec![String::new()] }
    let mut out = Vec::new();
    for s in 1..=2usize { if s <= n { for w in rhythms(n - s) { out.push(format!("{}{}", s, w)) } } }
    out
}
fn times(p: &[i64], q: &[i64]) -> Vec<i64> {       // multiply two polynomials
    (0..p.len() + q.len() - 1).map(|k| (0..p.len())
        .filter(|&i| k >= i && k - i < q.len()).map(|i| p[i] * q[k - i]).sum()).collect()
}
fn series(num: &[i64], den: &[i64], n: usize) -> Vec<i64> {   // road two: num / den
    let mut out: Vec<i64> = Vec::new();
    for j in 0..=n {
        let mut c = if j < num.len() { num[j] } else { 0 };
        for k in 1..=std::cmp::min(j, den.len() - 1) { c -= den[k] * out[j - k] }
        out.push(c)
    }
    out
}
fn solve2(p1: f64, q1: f64, r1: f64, p2: f64, q2: f64, r2: f64) -> (f64, f64) {
    let d = p1 * q2 - p2 * q1;                     // two equations, two unknowns
    ((r1 * q2 - r2 * q1) / d, (p1 * r2 - p2 * r1) / d)
}
fn sqrt(x: f64) -> f64 {                           // Newton's method, no crates
    let mut g = x;
    for _ in 0..60 { g = (g + x / g) / 2.0 }
    g
}
fn pw(x: f64, k: u32) -> f64 {                     // powers by repeated multiplying
    if k == 0 { 1.0 } else { x * pw(x, k - 1) }
}
fn row(name: &str, xs: &[i64]) {
    let parts: Vec<String> = xs.iter().map(|v| v.to_string()).collect();
    println!("{:<40}{}", name, parts.join(" "))
}
fn main() {
    let s5 = sqrt(5.0);
    let (phi, psi) = ((1.0 + s5) / 2.0, (1.0 - s5) / 2.0);
    let fib = series(&[0, 1], &[1, -1, -1], 13);   // x / (1 - x - x^2)
    let list: Vec<i64> = (0..13).map(|n| rhythms(n).len() as i64).collect();
    let (a, b) = solve2(1.0, 1.0, 0.0, -psi, -phi, 1.0);   // A + B = 0, -A psi - B phi = 1
    let binet = |n: u32| a * pw(phi, n) + b * pw(psi, n);  // road three
    let (num2, den2) = ([2i64, -5], [1i64, -5, 6]);
    let rates: Vec<i64> = (1..10).filter(|r| r * r + den2[1] * r + den2[2] == 0).collect();
    let (c, d) = solve2(1.0, 1.0, num2[0] as f64, -(rates[1] as f64), -(rates[0] as f64), num2[1] as f64);
    let second = series(&num2, &den2, 8);
    let closed: Vec<i64> = (0..9u32)
        .map(|n| c.round() as i64 * rates[0].pow(n) + d.round() as i64 * rates[1].pow(n)).collect();
    let rounded: Vec<i64> = (0..14).map(|n| binet(n).round() as i64).collect();
    println!("sqrt(5) = {:.10}, phi = {:.10}, psi = {:.10}", s5, phi, psi);
    row("bars of n beats, patterns listed:", &list);
    row("the same, coefficients of x/(1-x-x^2):", &fib);
    println!("a 4-beat bar, every pattern: {}", rhythms(4).join(" "));
    println!("a 12-beat bar: {} patterns listed, coefficient of x^13 = {}", list[12], fib[13]);
    println!("phi + psi = {:.10}, phi x psi = {:.10}, so (1 - phi x)(1 - psi x) = 1 - x - x^2", phi + psi, phi * psi);
    println!("the split: A = {:.10}, B = {:.10}; 1/sqrt(5) = {:.10}", a, b, 1.0 / s5);
    println!("phi^13/sqrt(5) = {:.10}, psi^13/sqrt(5) = {:.10}, F(13) = {:.10}",
             pw(phi, 13) / s5, pw(psi, 13) / s5, binet(13));
    row("F(0)..F(13) from the split, rounded:", &rounded);
    row("coefficients of (2-5x)/(1-5x+6x^2):", &second);
    println!("growth rates by search: {:?}, and (1 - {}x)(1 - {}x) = {:?}",
             rates, rates[0], rates[1], times(&[1, -rates[0]], &[1, -rates[1]]));
    row(&format!("the same list from {} x 2^n + {} x 3^n:", c.round() as i64, d.round() as i64), &closed);
    println!("mistake 1, numerator 1 not x: coefficient of x^12 = {}, not {}",
             series(&[1], &[1, -1, -1], 13)[12], fib[12]);
    println!("mistake 2, denominator signs copied across: a(4) = {}, not {}",
             series(&num2, &[1, -5, -6], 8)[4], second[4]);
    println!("mistake 3, split fitted to the constant only: a(4) = {}, not {}", 2 * rates[0].pow(4), second[4]);
    assert!(list == fib[1..].to_vec());                     // listing against the divided series
    assert!(rounded == fib);                                // the geometric pieces against it
    assert!(second == closed);                              // rates and weights against it
    assert!((a - 1.0 / s5).abs() < 1e-12 && (b + 1.0 / s5).abs() < 1e-12);
    assert!(times(&[1, -rates[0]], &[1, -rates[1]]) == den2.to_vec());  // the factoring, multiplied out
    println!("ALL CHECKS PASS");
}
