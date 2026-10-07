// Laplace on a rectangle -- the same check as the Python, in Rust.  No crates.  A 1 m square
// plate, top edge at 100 C, the rest at 0 C: u = sum over odd n of (400/(n pi)) sin(n pi x)
// sinh(n pi y)/sinh(n pi).  Road one: that series.  Road two: a grid of neighbour means, no sines.
// Road three: four turned copies add to 100 C.  Second case: edges 100, 60, 20, 0 C (T, R, B, L).
use std::f64::consts::PI;

fn ratio(n: f64, y: f64, s: f64) -> f64 { // sinh(n pi y)/sinh(n pi) without overflow; s = +1 gives the cosh mistake
    (n * PI * (y - 1.0)).exp() * (1.0 + s * (-2.0 * n * PI * y).exp()) / (1.0 + s * (-2.0 * n * PI).exp())
}
fn series(x: f64, y: f64, terms: usize, s: f64) -> f64 { // one hot edge at 100 C; terms counts odd n
    let terms = if terms > 0 { terms } else if y >= 1.0 { 100000 } else { (40.0 / (PI * (1.0 - y))) as usize + 2 };
    (0..terms).map(|k| { let n = (2 * k + 1) as f64; 400.0 / (n * PI) * (n * PI * x).sin() * ratio(n, y, s) }).sum()
}
fn top(x: f64, y: f64) -> f64 { series(x, y, 0, -1.0) }
fn plate(x: f64, y: f64, t: f64, r: f64, b: f64, l: f64) -> f64 {
    (t * top(x, y) + r * top(y, x) + b * top(x, 1.0 - y) + l * top(y, 1.0 - x)) / 100.0
}
fn simpson(f: &dyn Fn(f64) -> f64, m: usize) -> f64 { // integral of f from 0 to 1, m even
    (0..=m).map(|i| (if i == 0 || i == m { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 }) * f(i as f64 / m as f64)).sum::<f64>() / (3 * m) as f64
}
fn grid(n: usize, t: f64, r: f64, b: f64, l: f64) -> Vec<Vec<f64>> { // u[j][i] at x = i/n, y = j/n
    let mut u = vec![vec![0.0f64; n + 1]; n + 1];
    for k in 1..n { u[n][k] = t; u[k][n] = r; u[0][k] = b; u[k][0] = l; }
    let (w, mut change) = (2.0 / (1.0 + (PI / n as f64).sin()), 1.0f64); // over-relaxation only speeds the sweeps up
    while change > 1e-11 {
        change = 0.0;
        for j in 1..n {
            for i in 1..n {
                let d = (u[j][i - 1] + u[j][i + 1] + u[j - 1][i] + u[j + 1][i]) / 4.0 - u[j][i];
                change = change.max(d.abs());
                u[j][i] += w * d;
            }
        }
    }
    u
}
fn isotherm(x: f64, c: f64) -> f64 { // the height y where the one-edge plate reads c C, by bisection
    let (mut lo, mut hi) = (0.0f64, 1.0f64);
    for _ in 0..50 { let mid = (lo + hi) / 2.0; if top(x, mid) > c { hi = mid } else { lo = mid } }
    lo
}
fn join(v: &[f64], d: usize) -> String { v.iter().map(|x| format!("{:.*}", d, x)).collect::<Vec<_>>().join(" ") }

fn main() {
    let odd = [1.0f64, 3.0, 5.0, 7.0];
    let bf: Vec<f64> = odd.iter().map(|&n| 400.0 / (n * PI)).collect();
    let bs: Vec<f64> = odd.iter().map(|&n| simpson(&|x| 200.0 * (n * PI * x).sin(), 2000)).collect();
    let terms: Vec<f64> = odd.iter().map(|&n| 400.0 / (n * PI) * (n * PI / 2.0).sin() * ratio(n, 0.5, -1.0)).collect();
    let (centre, turned) = (top(0.5, 0.5), [top(0.3, 0.8), top(0.8, 0.3), top(0.3, 0.2), top(0.8, 0.7)]);
    let (ns, exact) = ([20usize, 40, 80], top(0.5, 0.75));
    let grids: Vec<Vec<Vec<f64>>> = ns.iter().map(|&n| grid(n, 100.0, 0.0, 0.0, 0.0)).collect();
    let g75: Vec<f64> = ns.iter().zip(&grids).map(|(&n, g)| g[3 * n / 4][n / 2]).collect();
    let errs: Vec<f64> = g75.iter().map(|g| (g - exact).abs()).collect();
    let (case2, grid2) = (plate(0.25, 0.75, 100.0, 60.0, 20.0, 0.0), grid(80, 100.0, 60.0, 20.0, 0.0)[60][20]);
    println!("sine coefficients, n = 1 3 5 7: formula {}  Simpson {}", join(&bf, 4), join(&bs, 4));
    println!("centre (0.5, 0.5), n = 1 3 5 7: sinh ratios {}  terms {}  full series {:.4} C", join(&odd.map(|n| ratio(n, 0.5, -1.0)), 6), join(&terms, 4), centre);
    println!("hot edge (0.5, 1), first 1 2 3 odd modes: {}  full {:.2} C", join(&[1, 2, 3].map(|k| series(0.5, 1.0, k, -1.0)), 2), top(0.5, 1.0));
    println!("four turned copies at (0.3, 0.8), top right bottom left: {}  sum {:.4} C", join(&turned, 4), turned.iter().sum::<f64>());
    println!("grid (0.5, 0.75), N = 20 40 80: {}  series {:.4} C", join(&g75, 4), exact);
    println!("grid error: {}  ratios {}", join(&errs, 5), join(&[errs[0] / errs[1], errs[1] / errs[2]], 2));
    println!("grid centre, N = 20 40 80: {}", join(&ns.iter().zip(&grids).map(|(&n, g)| g[n / 2][n / 2]).collect::<Vec<_>>(), 4));
    let ys: Vec<f64> = (0..11).map(|j| j as f64 / 10.0).collect();
    println!("figure, y (m):          {}", join(&ys, 1));
    println!("figure, series x = 0.5: {}", join(&ys.iter().map(|&y| top(0.5, y)).collect::<Vec<_>>(), 2));
    println!("figure, grid N = 20:    {}", join(&(0..11).map(|j| grids[0][2 * j][10]).collect::<Vec<_>>(), 2));
    for c in [25.0, 50.0, 75.0] {
        let pts: Vec<String> = (1..10).map(|i| format!("{},{:.1}", 60 + 20 * i, 220.0 - 200.0 * isotherm(i as f64 / 10.0, c))).collect();
        println!("figure, {} C isotherm, svg: {}", c, pts.join(" "));
    }
    println!("second case, edges 100 60 20 0 C: centre {:.4} C; (0.25, 0.75) series {:.4}, grid N = 80 {:.4}", plate(0.5, 0.5, 100.0, 60.0, 20.0, 0.0), case2, grid2);
    println!("mistake, cosh for sinh: centre {:.2} C, bottom edge middle {:.2} C, not 0", series(0.5, 0.5, 50, 1.0), series(0.5, 0.0, 50, 1.0));
    let raw: Vec<f64> = [1.0f64, 3.0, 5.0].iter().map(|&n| 400.0 / (n * PI) * (n * PI / 2.0).sin() * ((n * PI / 2.0).exp() - (-n * PI / 2.0).exp()) / 2.0).collect();
    println!("mistake, no division by sinh(n pi): centre partial sums {}", join(&[raw[0], raw[0] + raw[1], raw[0] + raw[1] + raw[2]], 1));
    println!("mistake, quarter rule off-centre: 25 C claimed at (0.5, 0.75), series gives {:.2} C", exact);
    assert!(bf.iter().zip(&bs).all(|(p, q)| (p - q).abs() < 1e-6)); // closed-form coefficients against an integral
    assert!((centre - 25.0).abs() < 1e-9 && (grids[2][40][40] - 25.0).abs() < 1e-6); // series and grid meet the symmetry count
    assert!((turned.iter().sum::<f64>() - 100.0).abs() < 1e-9); // four turned copies make a 100 C plate
    assert!(errs[2] < 0.01 && (0..2).all(|i| errs[i] / errs[i + 1] > 3.5 && errs[i] / errs[i + 1] < 4.5) && (case2 - grid2).abs() < 0.01);
    println!("ALL CHECKS PASS");
}
