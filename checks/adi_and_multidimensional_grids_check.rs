// ADI and multidimensional grids -- the same check as the Python, in Rust.  No crates.
// A 1 m square steel plate (diffusivity 1.2e-5 m^2/s, illustrative) starts at 0 C; its top edge
// is held at 100 C, the other three edges at 0 C.  Road one: the exact series, settled and in time.
// Road two: the five-point system assembled and solved by banded elimination, flops counted.
// Road three: Peaceman-Rachford ADI, a row sweep then a column sweep, each a tridiagonal solve.
use std::f64::consts::PI;
const ALPHA: f64 = 1.2e-5; const HOUR: f64 = 3600.0;
type Grid = Vec<Vec<f64>>;
fn ratio(n: f64, y: f64) -> f64 { // sinh(n pi y)/sinh(n pi), written so it never overflows
    (n * PI * (y - 1.0)).exp() * (1.0 - (-2.0 * n * PI * y).exp()) / (1.0 - (-2.0 * n * PI).exp())
}
fn settled(x: f64, y: f64) -> f64 { // the separated series for the settled plate
    (1..400).step_by(2).map(|n| { let n = n as f64; 400.0 / (n * PI) * (n * PI * x).sin() * ratio(n, y) }).fold(0.0, |a, t| a + t)
}
fn exact(x: f64, y: f64, t: f64) -> f64 { // settled minus every double-sine mode, each fading at its own rate
    let mut gap = 0.0;
    for m in (1..41i64).step_by(2) {
        for n in 1..41i64 {
            let sign = if n % 2 == 1 { 1 } else { -1 };
            let (mf, nf, q) = (m as f64, n as f64, (m * m + n * n) as f64);
            gap += (800 * n * sign) as f64 / (PI * PI * mf * q) * (mf * PI * x).sin() * (nf * PI * y).sin()
                * (-ALPHA * PI * PI * q * t).exp();
        }
    }
    settled(x, y) - gap
}
fn cold_grid(n: usize, top: f64) -> Grid { // u[j][i] at x = i/N, y = j/N; edges hold their values
    let mut u = vec![vec![0.0; n + 1]; n + 1]; for i in 1..n { u[n][i] = top; } u
}
fn thomas(lo: f64, di: f64, up: f64, d: &[f64]) -> Vec<f64> { // one sweep down, one back
    let n = d.len();
    let (mut p, mut q) = (vec![up / di], vec![d[0] / di]);
    for k in 1..n {
        let den = di - lo * p[k - 1];
        p.push(up / den); q.push((d[k] - lo * q[k - 1]) / den);
    }
    let mut x = q.clone(); for k in (0..n - 1).rev() { x[k] = q[k] - p[k] * x[k + 1]; } x
}
fn adi_step(u: &Grid, n: usize, r: f64, half: bool) -> Grid { // rows implicit in x, then columns in y
    let s = if half { r / 2.0 } else { r };
    let mut v = u.clone();
    for j in 1..n {
        let mut d: Vec<f64> = (1..n).map(|i| u[j][i] + s * (u[j + 1][i] - 2.0 * u[j][i] + u[j - 1][i])).collect();
        d[0] += s * u[j][0]; d[n - 2] += s * u[j][n]; // the row's two edge values go right
        for (i, x) in thomas(-s, 1.0 + 2.0 * s, -s, &d).into_iter().enumerate() { v[j][i + 1] = x; }
    }
    let mut w = v.clone();
    for i in 1..n {
        let mut d: Vec<f64> = (1..n).map(|j| v[j][i] + s * (v[j][i + 1] - 2.0 * v[j][i] + v[j][i - 1])).collect();
        d[0] += s * v[0][i]; d[n - 2] += s * v[n][i]; // the column's two edge values go right
        for (j, x) in thomas(-s, 1.0 + 2.0 * s, -s, &d).into_iter().enumerate() { w[j + 1][i] = x; }
    }
    w
}
fn explicit_step(u: &Grid, n: usize, r: f64, _half: bool) -> Grid {
    let mut w = u.clone();
    for j in 1..n { for i in 1..n {
        w[j][i] = u[j][i] + r * (u[j][i + 1] + u[j][i - 1] + u[j + 1][i] + u[j - 1][i] - 4.0 * u[j][i]);
    } }
    w
}
fn run(step: fn(&Grid, usize, f64, bool) -> Grid, n: usize, dt: f64, t: f64, half: bool) -> Grid {
    let (mut u, h) = (cold_grid(n, 100.0), 1.0 / n as f64);
    let r = ALPHA * dt / (h * h); for _ in 0..(t / dt).round() as usize { u = step(&u, n, r, half); }
    u
}
// the five-point system on the (N-1)^2 inside points, numbered row by row, solved inside its band
fn solve_grid(n: usize, edges: bool) -> (Vec<f64>, u64, u64) {
    let (m, b) = ((n - 1) * (n - 1), n - 1);
    let (mut a, mut rhs) = (vec![vec![0.0; 2 * b + 1]; m], vec![0.0; m]);
    let e = cold_grid(n, if edges { 100.0 } else { 0.0 });
    for j in 1..n { for i in 1..n {
        let k = (j - 1) * b + (i - 1); a[k][b] = 4.0;
        for (ii, jj) in [(i - 1, j), (i + 1, j), (i, j - 1), (i, j + 1)] {
            if ii > 0 && ii < n && jj > 0 && jj < n { a[k][b + (jj - 1) * b + (ii - 1) - k] = -1.0; }
            else { rhs[k] += e[jj][ii]; } // an edge value is known: it moves right
        }
    } }
    let (mut fac, mut sol) = (0u64, 0u64);
    for k in 0..m {
        let end = (k + b + 1).min(m);
        for i in k + 1..end {
            let l = a[i][b + k - i] / a[k][b]; fac += 1;
            for j in k + 1..end { a[i][b + j - i] -= l * a[k][b + j - k]; }
            fac += 2 * (end - k - 1) as u64;
            rhs[i] -= l * rhs[k]; sol += 2;
        }
    }
    let mut x = vec![0.0; m];
    for i in (0..m).rev() {
        let mut s = rhs[i];
        for j in i + 1..(i + b + 1).min(m) { s -= a[i][b + j - i] * x[j]; sol += 2; }
        x[i] = s / a[i][b]; sol += 1;
    }
    (x, fac, sol)
}
fn at(x: &[f64], n: usize, i: usize, j: usize) -> f64 { x[(j - 1) * (n - 1) + (i - 1)] }
fn sci(x: f64, d: usize) -> String { // Python's e-notation: mantissa, e, sign, two-digit exponent
    let s = format!("{:.*e}", d, x);
    let (mant, ex) = s.split_once('e').unwrap();
    let ex: i32 = ex.parse().unwrap(); format!("{}e{}{:02}", mant, if ex < 0 { '-' } else { '+' }, ex.abs())
}
fn main() {
    // by hand: the 3-cell grid, 4 inside points; settled values, then one ADI step of an hour
    let g3 = solve_grid(3, true).0;
    let r3 = ALPHA * HOUR * 9.0; let s3 = r3 / 2.0;
    let top_star = 100.0 * s3 / (1.0 + s3); let col_rhs = top_star * (1.0 - s3) + 100.0 * s3;
    let u3 = adi_step(&cold_grid(3, 100.0), 3, r3, true);
    println!("3-cell grid settled: top points {:.4}, bottom points {:.4} C", at(&g3, 3, 1, 2), at(&g3, 3, 1, 1));
    println!("3-cell ADI step of 1 h: r = {:.4}, r/2 = {:.4}; row sweep: right side {:.4}, diagonal {:.4}, U* = {:.4} at both top points", r3, s3, 100.0 * s3, 1.0 + r3, top_star);
    println!("  column sweep: right side top {:.4}, pivot {:.4}; top {:.4}, bottom {:.4}; exact (1/3, 2/3) at 1 h {:.4} C, off by {:.4}", col_rhs, 1.0 + r3 - s3 * s3 / (1.0 + r3),
        u3[2][1], u3[1][1], exact(1.0 / 3.0, 2.0 / 3.0, HOUR), u3[2][1] - exact(1.0 / 3.0, 2.0 / 3.0, HOUR));
    // settled plate: assembled five-point system against the series, at P = (0.5, 0.8)
    let (p, mut errs) = (settled(0.5, 0.8), vec![]);
    for n in [10usize, 20, 40] {
        let (x, fac, sol) = solve_grid(n, true);
        errs.push((at(&x, n, n / 2, 4 * n / 5) - p).abs());
        println!("five-point N = {}: {} unknowns, band {}; P = {:.4} C, centre {:.4} C; flops factor {} solve {}",
            n, (n - 1) * (n - 1), n - 1, at(&x, n, n / 2, 4 * n / 5), at(&x, n, n / 2, n / 2), fac, sol);
    }
    println!("series P = {:.4} C; errors {:.5} {:.5} {:.5}; ratios {:.2} {:.2}", p, errs[0], errs[1], errs[2], errs[0] / errs[1], errs[1] / errs[2]);
    for n in [39u64, 999] { // n = N - 1 points a line; m = n^2 unknowns; band w = n
        let adi = 2 * n * (13 * n - 2);
        println!("flops per step, N = {}: ADI 2n(13n - 2) = {}; banded estimates: solve 4mw = {}, factor once 2mw^2 = {}; solve/ADI {:.1}",
            n + 1, adi, 4 * n * n * n, 2 * n * n * n * n, (4 * n * n * n) as f64 / adi as f64);
    }
    let zero = at(&solve_grid(20, false).0, 20, 10, 16);
    // the plate warming: ADI at N = 40 against the exact series at the centre after one hour
    let (ex1, rf) = (exact(0.5, 0.5, HOUR), run(adi_step, 40, 30.0, HOUR, true)[20][20]);
    let dts = [3600.0, 1200.0, 600.0, 300.0, 150.0];
    let adi1: Vec<f64> = dts.iter().map(|&dt| run(adi_step, 40, dt, HOUR, true)[20][20]).collect();
    println!("centre at 1 h: exact {:.4} C; ADI N = 40, dt = 30 s {:.4} C, so the space error is {:.4}", ex1, rf, rf - ex1);
    for (dt, v) in dts.iter().zip(&adi1) {
        println!("  ADI dt = {:4} s, r = {:6.2}: {:.4} C; time error {:8.4}, error against exact {:8.4}", *dt as i64, ALPHA * dt * 1600.0, v, v - rf, v - ex1);
    }
    let te: Vec<f64> = adi1[1..].iter().map(|v| v - rf).collect();
    println!("time-error ratios as dt halves: {:.2} {:.2} {:.2}", te[0] / te[1], te[1] / te[2], te[2] / te[3]);
    let exp12 = run(explicit_step, 40, 12.0, HOUR, true)[20][20];
    let blow = run(explicit_step, 40, 15.0, HOUR, true).iter().flatten().fold(0.0f64, |a, v| a.max(v.abs()));
    let full = run(adi_step, 40, 60.0, HOUR, false)[20][20];
    println!("explicit limit r <= 1/4: dt <= {:.4} s; dt = 12 s (r = 0.2304): {:.4} C after 300 steps; dt = 15 s (r = 0.288): largest |U| {}",
        0.25 * 0.025 * 0.025 / ALPHA, exp12, sci(blow, 3));
    println!("mistake, full r in each sweep: {:.4} C at 1 h; exact at 2 h {:.4} C", full, exact(0.5, 0.5, 2.0 * HOUR));
    println!("mistake, edge values left out of b: P reads {:.4} C", zero);
    // the chart: centre, hour by hour, ADI dt = 600 s against the exact series; then 24 h against direct
    let (mut u, mut hours, mut adiv) = (cold_grid(40, 100.0), vec![], vec![]);
    for step in 1..145 {
        u = adi_step(&u, 40, ALPHA * 600.0 * 1600.0, true);
        if step % 6 == 0 && step <= 48 { hours.push(exact(0.5, 0.5, step as f64 * 600.0)); adiv.push(u[20][20]); }
    }
    let g40 = solve_grid(40, true).0;
    let mut gap24 = 0.0f64;
    for j in 1..40 { for i in 1..40 { gap24 = gap24.max((u[j][i] - at(&g40, 40, i, j)).abs()); } }
    let row = |v: &[f64]| v.iter().map(|x| format!("{:7.4}", x)).collect::<Vec<_>>().join(" ");
    println!("chart, hours         {}", (1..9).map(|h| format!("{:7}", h)).collect::<Vec<_>>().join(" "));
    println!("chart, exact centre  {}", row(&hours));
    println!("chart, ADI dt = 600  {}", row(&adiv));
    println!("ADI at 24 h against the direct settled solve, N = 40: largest gap {} C", sci(gap24, 2));
    let pt = |i: i32, j: i32| format!("{},{}", 80 + 40 * i, 230 - 40 * j); // the figure: N = 5, 200 units per metre
    println!("figure, plate {} to {}; stencil {} arms {} {} {} {}; row {} to {}; column {} to {}",
        pt(0, 5), pt(5, 0), pt(1, 4), pt(0, 4), pt(2, 4), pt(1, 5), pt(1, 3), pt(1, 1), pt(4, 1), pt(4, 1), pt(4, 4));
    let worst = adiv.iter().zip(&hours).fold(0.0f64, |a, (x, e)| a.max((x - e).abs()));
    assert!((at(&g3, 3, 1, 2) - 37.5).abs() < 1e-12 && (at(&g3, 3, 1, 1) - 12.5).abs() < 1e-12); // 3a - b = 100, 3b - a = 0
    assert!((0..2).all(|k| errs[k] / errs[k + 1] > 3.5 && errs[k] / errs[k + 1] < 4.5) && errs[2] < 0.03); // error as h^2
    assert!((at(&g40, 40, 20, 20) - 25.0).abs() < 1e-9); // turning the plate: centre is 25
    assert!((rf - ex1).abs() < 0.03 && [1, 2].iter().all(|&k| te[k] / te[k + 1] > 3.5 && te[k] / te[k + 1] < 4.5)); // order 2 in time
    assert!((exp12 - ex1).abs() < 0.03 && blow > 1e6 && zero.abs() < 1e-12); // explicit: fine at r < 1/4, not above
    assert!(gap24 < 1e-6 && worst < 0.03); // ADI settles on the direct solve
    println!("ALL CHECKS PASS");
}
