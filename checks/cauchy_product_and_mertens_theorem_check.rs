// Cauchy product and Mertens' theorem -- the same check as the Python, in Rust.
// No crates.  The product of two series adds the grid of products a_k * b_m
// along its diagonals k + m = n.  Road one convolves the term lists; road two
// uses closed forms, and an independent ln 2 from Simpson's rule.

fn cauchy(a: &[f64], b: &[f64]) -> Vec<f64> {  // c_n = a_0 b_n + a_1 b_(n-1) + ... + a_n b_0
    (0..a.len()).map(|n| {
        let mut s = 0.0;
        for k in 0..=n { s += a[k] * b[n - k] }
        s
    }).collect()
}
fn running(terms: &[f64]) -> Vec<f64> {         // partial sums: entry N totals terms 0..N
    let mut s = 0.0;
    terms.iter().map(|t| { s += t; s }).collect()
}
fn simpson(f: impl Fn(f64) -> f64, a: f64, b: f64, panels: usize) -> f64 {
    let h = (b - a) / panels as f64;            // parabolas through each pair of strips
    let mut s = f(a) + f(b);
    for i in 1..panels { s += (if i % 2 == 1 { 4.0 } else { 2.0 }) * f(a + i as f64 * h) }
    s * h / 3.0
}
fn row(xs: &[f64], digits: usize) -> String {
    xs.iter().map(|x| format!("{:.*}", digits, x)).collect::<Vec<_>>().join(" ")
}
fn sign(n: usize) -> f64 { if n % 2 == 0 { 1.0 } else { -1.0 } }

fn main() {
    let geo: Vec<f64> = (0..2001).map(|n| 0.5f64.powi(n)).collect();   // 1 + 1/2 + 1/4 + ..., sum 2
    let c = cauchy(&geo[..60], &geo[..60]);
    let (cc, a) = (running(&c), running(&geo[..60]));
    println!("halving: c_n for n=0..5: {}", row(&c[..6], 4));
    println!("halving: C_10={:.6}  4-13/1024={:.6}  A_10*B_10={:.6}", cc[10], 4.0 - 13.0 / 1024.0, a[10] * a[10]);
    println!("halving: C_59={:.6}  A*B={:.6}", cc[59], a[59] * a[59]);
    assert!((0..60).all(|n| (c[n] - (n + 1) as f64 / 2f64.powi(n as i32)).abs() < 1e-15)); // count the diagonal
    assert!((0..60).all(|n| (cc[n] - (4.0 - (n + 3) as f64 / 2f64.powi(n as i32))).abs() < 1e-12));
    let same = running(&geo[..60].iter().map(|x| x * x).collect::<Vec<_>>())[59];
    println!("mistake, positions matched a_n*b_n: {:.6}, not 4", same);
    let l = simpson(|t| 1.0 / (1.0 + t), 0.0, 1.0, 2000);
    let alt: Vec<f64> = (0..2001).map(|n| sign(n) / (n + 1) as f64).collect(); // 1 - 1/2 + 1/3 - ..., sum ln 2
    let m = cauchy(&geo, &alt);
    let mm = running(&m);
    println!("ln 2 by Simpson={:.9}  2 ln 2={:.9}", l, 2.0 * l);
    println!("mertens: C_N at N=10, 100, 1000, 2000: {}", row(&[mm[10], mm[100], mm[1000], mm[2000]], 6));
    assert!(((mm[1999] + mm[2000]) / 2.0 - 2.0 * l).abs() < 1e-6); // neighbours straddle 2 ln 2
    let sizes = running(&m.iter().map(|x| x.abs()).collect::<Vec<_>>());
    println!("mertens: (n+1)|c_n| at n=1000: {:.6}; sum |c_n| to 100, 1000: {:.6} {:.6}", 1001.0 * m[1000].abs(), sizes[100], sizes[1000]);
    let sq: Vec<f64> = (0..1000001).map(|n| sign(n) / ((n + 1) as f64).powf(0.5)).collect(); // 1 - 1/sqrt 2 + ...
    let p = running(&sq);
    let s = (p[999999] + p[1000000]) / 2.0;      // average two neighbouring totals
    let d = cauchy(&sq[..200], &sq[..200]);
    let dd = running(&d);
    println!("conditional: S={:.6}  S^2={:.6}", s, s * s);
    println!("conditional: |c_n| for n=0..5: {}", row(&d[..6].iter().map(|x| x.abs()).collect::<Vec<_>>(), 4));
    assert!((0..200).all(|n| d[n].abs() >= 2.0 * (n + 1) as f64 / (n + 2) as f64)); // never below 1
    println!("conditional: |c_n| >= 2(n+1)/(n+2) >= 1 for every n < 200; C_98={:.6}  C_99={:.6}", dd[98], dd[99]);
    for (name, line) in [("halving", &cc), ("mertens", &mm), ("conditional", &dd)] {
        println!("chart {} C_N, N=0..12: {}", name, row(&line[..13], 2));
    }
    let v: f64 = 1.0 / 1.05;                      // one year's discount at 5%
    let due: Vec<f64> = (0..1500).map(|n| v.powi(n)).collect();   // 1 now and every year after
    let mut late = due.clone();                   // 1 at the end of every year
    late[0] = 0.0;
    let rising = cauchy(&due, &late);             // n paid at the end of year n
    let total = *running(&rising).last().unwrap();
    println!("bond at 5%: due={:.6}  level={:.6}  rising={:.6}", running(&due)[1499], running(&late)[1499], total);
    assert!((total - 21.0 * 20.0).abs() < 1e-6 && (rising[7] - 7.0 * v.powi(7)).abs() < 1e-12);
    println!("ALL CHECKS PASS");
}
