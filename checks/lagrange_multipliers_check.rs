// Lagrange multipliers -- the same check as the Python, in Rust.  No crates.
// Fence a rectangle, x by y metres, with P metres of fence: a*x + b*y = P.
// Four sides: a = b = 2.  Beside a river (no fence on one long side): a = 1, b = 2.
// Road one solves the Lagrange equations y = lam*a, x = lam*b, a*x + b*y = P.
// Road two walks along the fence and searches for the biggest area.
fn det(m: &[[f64; 3]; 3]) -> f64 {
    m[0][0] * (m[1][1] * m[2][2] - m[1][2] * m[2][1])
        - m[0][1] * (m[1][0] * m[2][2] - m[1][2] * m[2][0])
        + m[0][2] * (m[1][0] * m[2][1] - m[1][1] * m[2][0])
}

fn lagrange(a: f64, b: f64, p: f64) -> [f64; 3] {  // Cramer's rule on the 3 x 3 system
    let m = [[0.0, 1.0, -a], [1.0, 0.0, -b], [a, b, 0.0]];
    let rhs = [0.0, 0.0, p];
    let d = det(&m);
    let mut out = [0.0; 3];
    for j in 0..3 {
        let mut c = m;
        for i in 0..3 { c[i][j] = rhs[i] }
        out[j] = det(&c) / d;
    }
    out
}

fn search(a: f64, b: f64, p: f64) -> (f64, f64) {  // golden-section search along the fence
    let area = |x: f64| x * (p - a * x) / b;
    let (mut lo, mut hi, r) = (0.0, p / a, (5f64.sqrt() - 1.0) / 2.0);
    for _ in 0..200 {
        let (u, v) = (hi - r * (hi - lo), lo + r * (hi - lo));
        if area(u) < area(v) { lo = u } else { hi = v }
    }
    let x = (lo + hi) / 2.0;
    (x, area(x))
}

fn price(a: f64, b: f64, p: f64) -> f64 {          // slope of the best area as the fence grows
    let h = 1e-3;
    (search(a, b, p + h).1 - search(a, b, p - h).1) / (2.0 * h)
}

fn main() {
    for (name, a, b) in [("four sides", 2.0, 2.0), ("river", 1.0, 2.0)] {
        let [x, y, lam] = lagrange(a, b, 40.0);
        let (sx, sa) = search(a, b, 40.0);
        let pr = price(a, b, 40.0);
        let a41 = search(a, b, 41.0).1;
        println!("{}: Lagrange x = {:.6}, y = {:.6}, lambda = {:.6}, area = {:.6}", name, x, y, lam, x * y);
        println!("{}: search along the fence x = {:.6}, area = {:.6}; price slope = {:.6}", name, sx, sa, pr);
        println!("{}: 41 m of fence gives area {:.4}, gain {:.4}", name, a41, a41 - sa);
        assert!((sx - x).abs() < 1e-6 && (sa - x * y).abs() < 1e-6);  // two roads, one best point
        assert!((pr - lam).abs() < 1e-6);                              // the multiplier is the price
    }
    let row: Vec<String> = (0..=20).step_by(2).map(|x: i64| (x * (20 - x)).to_string()).collect();
    println!("area along the four-side fence, x = 0, 2, ..., 20: {}", row.join(" "));
    let pts: Vec<f64> = (0..141).map(|k| k as f64 / 7.0).collect();   // 0 to 20 m in steps of 1/7
    assert!(pts.iter().all(|&x| ((100.0 - x * (20.0 - x)) - (x - 10.0).powi(2)).abs() < 1e-12));
    println!("square identity 100 - x(20 - x) = (x - 10)^2 holds at {} points on the fence", pts.len());
    for (x, y) in [(10, 10), (15, 5)] {
        println!("at ({}, {}): grad A = ({}, {}), grad g = (2, 2), area {}, rate as x grows along the fence = {}", x, y, y, x, x * y, y - x);
    }
    let (x0, y0) = (0, 0);                            // grad A = (y, x) = (0, 0) has one solution
    println!("mistake 1, grad A = 0 with no fence: ({}, {}), area {}", x0, y0, x0 * y0);
    let (x2, y2) = (2 * 6, 2 * 6);                    // y = 2*lam, x = 2*lam with lam = 6, fence ignored
    println!("mistake 2, no fence equation: lambda = 6 gives {} by {}, fence {}, area {}", x2, y2, 2 * x2 + 2 * y2, x2 * y2);
    let s = 2 * (2 * 10 + 2 * 10 - 40);
    println!("mistake 3, fence squared: its gradient at (10, 10) = ({}, {}), grad A = (10, 10)", s * 2, s * 2);
    println!("mistake 4, river priced at 5: predicts gain 5, true gain {:.4}", search(1.0, 2.0, 41.0).1 - 200.0);
    let px = |x: i64, y: i64| format!("({}, {})", 40 + 9 * x, 215 - 9 * y);
    println!("figure, 9 px per m, origin (40, 215): fence ends {} {} touch {} crossings {} {}",
             px(0, 20), px(20, 0), px(10, 10), px(5, 15), px(15, 5));
    println!("ALL CHECKS PASS");
}
