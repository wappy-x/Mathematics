// Laplace's equation on a 1 m square plate: top edge 100 C, other three 0 C.
// Road one relaxes a grid until each point is the average of its neighbours;
// road two is the rectangle card's sine series; the centre's third road is symmetry.
use std::f64::consts::PI;
const N: usize = 40;
const F: f64 = 100.0; // heat source, C per m^2

fn relax(n: usize, top: f64, src: f64, start: f64) -> Vec<Vec<f64>> {
    let (h, w) = (1.0 / n as f64, 2.0 / (1.0 + (PI / n as f64).sin())); // w: over-relaxation
    let mut u = vec![vec![start; n + 1]; n + 1]; // u[i][j] is u at x = i h, y = j h
    for i in 0..=n { u[i][0] = 0.0; u[0][i] = 0.0; u[n][i] = 0.0; u[i][n] = top; }
    loop {
        let mut big: f64 = 0.0;
        for i in 1..n { for j in 1..n {
            let new = (u[i + 1][j] + u[i - 1][j] + u[i][j + 1] + u[i][j - 1] + h * h * src) / 4.0;
            big = big.max((new - u[i][j]).abs());
            u[i][j] += w * (new - u[i][j]);
        } }
        if big < 1e-12 { return u; }
    }
}
fn plate(x: f64, y: f64) -> f64 { // sum over odd n of 400/(n pi) sin(n pi x) sinh(n pi y)/sinh(n pi)
    (1..800).step_by(2).map(|n| { let a = n as f64 * PI;
        400.0 / a * (a * x).sin() * ((a * (y - 1.0)).exp() - (-a * (y + 1.0)).exp()) / (1.0 - (-2.0 * a).exp())
    }).sum()
}
fn heated(x: f64, y: f64) -> f64 { // edges 0 C, source F: a parabola minus a harmonic correction
    let c: f64 = (1..200).step_by(2).map(|n| { let a = n as f64 * PI;
        4.0 / a.powi(3) * (a * x).sin() * ((a * (y - 1.0)).exp() + (-a * y).exp()) / (1.0 + (-a).exp())
    }).sum();
    F * (x * (1.0 - x) / 2.0 - c)
}
fn ring(g: fn(f64, f64) -> f64, x: f64, y: f64, r: f64) -> f64 { // average round a circle, 256 points
    let m = 256;
    (0..m).map(|k| { let t = 2.0 * PI * k as f64 / m as f64; g(x + r * t.cos(), y + r * t.sin()) }).sum::<f64>() / m as f64
}
fn f2(v: &[f64]) -> String { v.iter().map(|t| format!("{:.2}", t)).collect::<Vec<_>>().join(", ") }

fn main() {
    let (a, b) = (relax(N, 100.0, 0.0, 0.0), relax(N, 100.0, 0.0, 100.0)); // two first guesses
    let inner: Vec<f64> = (1..N).flat_map(|i| (1..N).map(move |j| (i, j))).map(|(i, j)| a[i][j]).collect();
    let (mx, mn) = (inner.iter().cloned().fold(f64::MIN, f64::max), inner.iter().cloned().fold(f64::MAX, f64::min));
    let line_s: Vec<f64> = (0..11).map(|k| if k < 10 { plate(0.5, k as f64 / 10.0) } else { 100.0 }).collect();
    let line_g: Vec<f64> = (0..11).map(|k| a[N / 2][4 * k]).collect();
    let (p20, p40, pex) = (relax(20, 0.0, F, 0.0)[10][10], relax(40, 0.0, F, 0.0)[20][20], heated(0.5, 0.5));
    let (m1, m2, m3) = (ring(plate, 0.5, 0.5, 0.25), ring(plate, 0.5, 0.75, 0.2), ring(heated, 0.5, 0.5, 0.25));
    let gap = a.iter().zip(&b).flat_map(|(ra, rb)| ra.iter().zip(rb).map(|(x, y)| (x - y).abs())).fold(0.0, f64::max);
    println!("plate centre: symmetry 25, series {:.6}, grid h=1/40 {:.6}", plate(0.5, 0.5), a[20][20]);
    println!("one-point grids h=1/2: plate (100+0+0+0)/4 = {:.2}, heated 0 + (1/4)(100)/4 = {:.2}",
             relax(2, 100.0, 0.0, 0.0)[1][1], relax(2, 0.0, F, 0.0)[1][1]);
    println!("centre line x=0.5, y=0,0.1..1, series: {}", f2(&line_s));
    println!("centre line x=0.5, y=0,0.1..1, grid:   {}", f2(&line_g));
    println!("interior grid max {:.4} at (0.5, 0.975), min {:.4} at (0.025, 0.025); edges 0 and 100", mx, mn);
    println!("uniqueness: first guesses 0 and 100 settle within 1e-9 of each other: {}", if gap < 1e-9 { "yes" } else { "no" });
    println!("mean value at (0.5, 0.5), r=0.25: ring {:.6}, point {:.6}", m1, plate(0.5, 0.5));
    println!("mean value at (0.5, 0.75), r=0.2: ring {:.6}, point {:.6}", m2, plate(0.5, 0.75));
    println!("Poisson, edges 0, source {:.0}: centre series {:.4}, grid h=1/20 {:.4}, h=1/40 {:.4}", F, pex, p20, p40);
    println!("Poisson grid error: h=1/20 {:.5}, h=1/40 {:.5}, ratio {:.2}", pex - p20, pex - p40, (pex - p20) / (pex - p40));
    println!("Poisson ring r=0.25: {:.4}; centre minus F r^2/4 = {:.4}", m3, pex - F * 0.25f64.powi(2) / 4.0);
    println!("breaks 1, a source: centre {:.4} C, above every edge (all 0 C)", pex);
    println!("breaks 2, half-plane y>0 with edge 0: u=y has neighbour average {:.1} = u at (0.5, 2); u=0 fits too", (2.0 + 2.0 + 2.1 + 1.9) / 4.0);
    println!("breaks 3, edge average at (0.5, 0.75): 25.00, true {:.2}", plate(0.5, 0.75));
    println!("figure, 160 per metre; plate (100,50)-(260,210); centre (180,130), ring r=0.25 -> radius 40; point (0.5,0.75) -> (180,90)");
    assert!((plate(0.5, 0.5) - 25.0).abs() < 1e-9); // series against symmetry
    assert!(line_s.iter().zip(&line_g).map(|(s, g)| (s - g).abs()).fold(0.0, f64::max) < 0.05 && mx < 100.0);
    assert!((m1 - 25.0).abs() < 1e-9 && (m2 - plate(0.5, 0.75)).abs() < 1e-9); // mean value, two circles
    let ratio = (pex - p20) / (pex - p40);
    assert!(3.8 < ratio && ratio < 4.2 && (m3 - (pex - F * 0.25f64.powi(2) / 4.0)).abs() < 1e-9);
    println!("ALL CHECKS PASS");
}
