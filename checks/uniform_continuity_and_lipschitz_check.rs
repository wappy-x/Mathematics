// Uniform continuity and Lipschitz -- the check behind the card.  std only.
// Example: a square tile of side x metres, area x*x, sides from 0 to 2 m,
// area tolerance 0.01 m^2.  Each tolerance is found twice: by a formula, and
// by bisection over sample points, which takes no roots.
const EPS: f64 = 0.01;
const B: f64 = 2.0;

fn bisect<F: Fn(f64) -> bool>(ok: F) -> f64 { // largest d with ok(d) true
    let (mut lo, mut hi) = (0.0, 1.0);
    for _ in 0..60 {
        let mid = (lo + hi) / 2.0;
        if ok(mid) { lo = mid } else { hi = mid }
    }
    lo
}

fn uniform_ok(d: f64) -> bool { // every sampled pair d apart in [0, 2]
    (0..=2000).map(|i| i as f64 * (B - d) / 2000.0)
        .map(|x| (x + d) * (x + d) - x * x).fold(f64::MIN, f64::max) <= EPS
}

fn point_ok(c: f64, d: f64) -> bool { // every sample within d of the side c
    (-100..=100).map(|k| ((c + d * k as f64 / 100.0).powi(2) - c * c).abs())
        .fold(f64::MIN, f64::max) <= EPS
}

fn step(x: f64) -> i32 { if x >= 1.0 { 1 } else { 0 } } // a switch that jumps at side 1

fn main() {
    let k = 2.0 * B; // factoring: x*x - y*y = (x - y)(x + y), x + y <= 4
    let g: Vec<f64> = (0..=2000).map(|i| i as f64 / 1000.0).collect();
    let mut steep = f64::MIN;
    for i in 0..g.len() {
        for j in i + 1..g.len() {
            steep = steep.max((g[j] * g[j] - g[i] * g[i]) / (g[j] - g[i]));
        }
    }
    let lip = EPS / k;
    let (exact, bis) = (B - (B * B - EPS).sqrt(), bisect(uniform_ok));
    let d5 = (0.25 + EPS).sqrt() - 0.5;
    println!("K by factoring on [0,2]: {:.6}; steepest sampled chord: {:.6}", k, steep);
    println!("Lipschitz tolerance, m: {:.8}", lip);
    println!("worst pair 1.9975 and 2, area gap: {:.8}", B * B - (B - lip).powi(2));
    println!("best uniform tolerance, m: formula {:.8}, bisection {:.8}", exact, bis);
    println!("best at side 0.5 alone, m: {:.8}; used at side 2, area gap {:.8}", d5, B * B - (B - d5).powi(2));
    println!("best at side 100 alone, m: {:.8}", (10000.0 + EPS).sqrt() - 100.0);
    for d in [0.1f64, 0.01, 0.0025, 0.001] {
        let x = 1.0 / d;
        let y = x + d / 2.0;
        assert!(((y * y - x * x) - (1.0 + d * d / 4.0)).abs() < 1e-6); // direct gap against the algebra
        println!("whole line, tolerance {}: sides {:.2} and {:.5}, area gap {:.8}", d, x, y, y * y - x * x);
    }
    println!("open end, 1/x at 0.01 and {:.8}: input gap {:.8}, output gap {:.6}",
        1.0 / 101.0, 0.01 - 1.0 / 101.0, 1.0 / (1.0 / 101.0) - 1.0 / 0.01);
    let t = 1.0 / (k + 1.0);
    println!("square root, K = 4 beaten by 0 and {:.2}: ratio {:.6}", t * t, (t * t).sqrt() / (t * t));
    let sq = (0..991).map(|i| (i as f64 / 1000.0 + 0.01).sqrt() - (i as f64 / 1000.0).sqrt()).fold(f64::MIN, f64::max);
    println!("square root, inputs 0.01 apart, largest output gap {:.6}", sq);
    println!("jump at 1: inputs 0.9999 and 1, output gap {}", step(1.0) - step(0.9999));
    let cs = [0.25, 0.5, 1.0, 2.0, 3.0, 4.0, 6.0, 8.0, 10.0];
    let pts: Vec<f64> = cs.iter().map(|&c| bisect(|d| point_ok(c, d))).collect();
    for (c, p) in cs.iter().zip(&pts) {
        assert!((p - ((c * c + EPS).sqrt() - c)).abs() < 1e-9); // bisection against the closed form
    }
    assert!(k - steep >= 0.0 && k - steep < 0.0011); // sampled chords against factoring
    assert!((bis - exact).abs() < 1e-9); // bisection against the formula
    let side: Vec<String> = cs.iter().map(|c| format!("{:.2}", c)).collect();
    let mm: Vec<String> = pts.iter().map(|p| format!("{:.2}", 1000.0 * p)).collect();
    println!("try, sides up to 3 m: K {:.6}, tolerance {:.8}; area tolerance 0.001 on [0,2]: {:.8}", 2.0 * 3.0, EPS / (2.0 * 3.0), 0.001 / k);
    println!("figure, side m: {}", side.join(" "));
    println!("figure, best tolerance mm: {}", mm.join(" "));
    println!("all four checks passed");
}
