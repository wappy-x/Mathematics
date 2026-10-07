// Iteration and cobweb plots -- the same check as the Python, in Rust.  No
// crates.  Road one feeds each rule its own output, step by step.  Road two
// reaches each end point without that loop: exact fractions and bisection for
// the square root, algebra for the fish stock's resting level, a slope for the spiral.
fn orbit(g: &dyn Fn(f64) -> f64, x0: f64, n: usize) -> Vec<f64> {
    let mut xs = vec![x0];                 // x0, g(x0), g(g(x0)), ... n steps in all
    for _ in 0..n { let last = xs[xs.len() - 1]; xs.push(g(last)) }
    xs
}

fn bisect(f: &dyn Fn(f64) -> f64, mut lo: f64, mut hi: f64) -> f64 {
    for _ in 0..60 {                       // a root of f between lo and hi, 60 halvings
        let mid = (lo + hi) / 2.0;
        if f(lo) * f(mid) > 0.0 { lo = mid } else { hi = mid }
    }
    (lo + hi) / 2.0
}

fn show(xs: &[f64], d: usize) -> String {
    xs.iter().map(|x| format!("{:.*}", d, x)).collect::<Vec<_>>().join(", ")
}

fn sci(x: f64) -> String {                 // 8.58e-02, as Python prints it
    let s = format!("{:.2e}", x);
    let (m, e) = s.split_once('e').unwrap();
    let e: i32 = e.parse().unwrap();
    format!("{}e{}{:02}", m, if e < 0 { "-" } else { "+" }, e.abs())
}

fn fish(r: f64) -> impl Fn(f64) -> f64 { move |x| r * x * (1.0 - x) }

fn main() {
    let sq = |x: f64| (x + 2.0 / x) / 2.0;                     // the square-root rule
    let b = orbit(&sq, 1.0, 4);
    let (mut p, mut q, mut fracs): (u64, u64, Vec<String>) = (1, 1, vec![]);
    for _ in 0..4 {                        // exact: p/q -> (p*p + 2q*q)/(2pq)
        (p, q) = (p * p + 2 * q * q, 2 * p * q);
        fracs.push(format!("{}/{}", p, q));
    }
    let root = bisect(&|x: f64| x * x - 2.0, 1.0, 2.0);
    let err: Vec<f64> = b.iter().map(|x| x - root).collect();
    let g = fish(2.8);
    let f = orbit(&g, 0.2, 200);
    let star = 1.0 - 1.0 / 2.8;                                // g(x) = x, solved by hand
    let ratio = (f[81] - star) / (f[80] - star);
    let slope = (g(star + 1e-6) - g(star - 1e-6)) / 2e-6;
    let c = orbit(&fish(3.2), 0.2, 203);
    let w = orbit(&fish(3.9), 0.2, 1999);
    let mut seen: Vec<i64> = w[1000..].iter().map(|x| (x * 10000.0) as i64).collect();
    seen.sort();
    seen.dedup();
    let signs: String = f[..9].iter().map(|&x| if x > star { '+' } else { '-' }).collect();
    let bx: Vec<f64> = b[..4].iter().map(|x| 60.0 + 200.0 * (x - 0.8)).collect();
    let fx: Vec<f64> = f[..9].iter().map(|x| 60.0 + 180.0 * x).collect();
    println!("square-root rule from 1 m, x0..x4: {}", show(&b, 10));
    println!("the same orbit as exact fractions: {}", fracs.join(", "));
    println!("sqrt(2) by bisection, no use of the rule: {:.10}", root);
    println!("error after steps 1 to 4: {}", err[1..].iter().map(|&e| sci(e)).collect::<Vec<_>>().join(", "));
    println!("error after step 3 predicted by (error after step 2)^2 / (2 x2): {}", sci(err[2] * err[2] / (2.0 * b[2])));
    println!("logistic r = 2.8 from 0.2, x0..x8: {}", show(&f[..9], 6));
    println!("x200 = {:.6}; resting level by algebra, 1 - 1/r = {:.6}", f[200], star);
    println!("side of the resting level at steps 0..8: {}", signs);
    println!("error ratio at step 80: {:.6}; slope of the curve at the resting level: {:.6}", ratio, slope);
    println!("logistic r = 3.2, x200..x203: {}", show(&c[200..], 6));
    println!("logistic r = 3.9, x50..x55: {}", show(&w[50..56], 6));
    println!("r = 3.9, distinct values to 4 decimals among x1000..x1999: {}", seen.len());
    println!("mistake 1, solving g(x) = 0 at r = 2.8: {:.6} and {:.6}", bisect(&g, -0.5, 0.5).abs(), bisect(&g, 0.5, 1.5));
    println!("mistake 2, the rule 2/x from 1, x0..x4: {}", show(&orbit(&|x: f64| 2.0 / x, 1.0, 4), 1));
    println!("mistake 3, g(0.2) squared = {:.6}; g(g(0.2)) = {:.6}", g(0.2) * g(0.2), g(g(0.2)));
    println!("mistake 4, square-root rule from -1, x4 = {:.10}", orbit(&sq, -1.0, 4)[4]);
    println!("figure, square-root cobweb x0..x3 at x px: {}", show(&bx, 1));
    println!("figure, logistic cobweb x0..x8 at x px: {}", show(&fx, 1));
    assert!((b[4] - root).abs() < 1e-11);                      // iteration against bisection
    assert!((b[4] - p as f64 / q as f64).abs() < 1e-15);       // iteration against exact fractions
    assert!((f[200] - star).abs() < 1e-12);                    // iteration against algebra
    assert!((ratio - slope).abs() < 1e-5);                     // spiral rate against the slope
    println!("ALL CHECKS PASS");
}
