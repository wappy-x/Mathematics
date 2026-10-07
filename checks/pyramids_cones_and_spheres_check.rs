// Pyramids, cones and spheres -- the same check as the Python, in Rust.  No
// crates.  The hopper under the tank is a cone, rim radius 1 m, depth 0.75 m;
// the ball is 2 m across.  Road one: the formulas.  Road two: thin slabs, a
// many-sided pyramid and thin bands, from slice areas and Pythagoras alone.
use std::f64::consts::PI;

const R: f64 = 1.0; // rim radius, m
const H: f64 = 0.75; // hopper depth, m
const TANK: f64 = 3.0; // tank height, m

fn slabs(area_at: &dyn Fn(f64) -> f64, height: f64, n: usize) -> (f64, f64) {
    let ends: Vec<f64> = (0..=n).map(|j| area_at(height * j as f64 / n as f64)).collect();
    let inside: f64 = (0..n).map(|j| ends[j].min(ends[j + 1])).sum::<f64>() * height / n as f64;
    (inside, (0..n).map(|j| ends[j].max(ends[j + 1])).sum::<f64>() * height / n as f64)
}

fn polygon_steel(doublings: u32) -> (u64, f64) { // a pyramid on a 6 x 2^k-sided rim polygon
    let (mut n, mut e) = (6u64, R); // a hexagon's side equals its radius
    for _ in 0..doublings { // halve every side's angle: Pythagoras twice
        n *= 2;
        e = (2.0 * R * R - R * (4.0 * R * R - e * e).sqrt()).sqrt();
    }
    (n, n as f64 * e * (H * H + R * R - e * e / 4.0).sqrt() / 2.0) // edge x face height / 2
}

fn bands(n: usize) -> f64 { // the ball's outline cut into n chords, spun round
    let z: Vec<f64> = (0..=n).map(|j| -R + 2.0 * R * j as f64 / n as f64).collect();
    let r: Vec<f64> = z.iter().map(|v| (R * R - v * v).max(0.0).sqrt()).collect();
    (0..n).map(|j| PI * (r[j] + r[j + 1]) * ((z[j + 1] - z[j]).powi(2) + (r[j + 1] - r[j]).powi(2)).sqrt()).sum()
}

fn main() {
    let l = (R * R + H * H).sqrt(); // the slant, by Pythagoras
    let (cone_v, cone_s) = (PI * R * R * H / 3.0, PI * R * l);
    let (ball_v, ball_s) = (4.0 * PI * R.powi(3) / 3.0, 4.0 * PI * R * R);
    let cone_at = |z: f64| PI * (R * z / H).powi(2); // slice z above the tip
    let hemi_at = |z: f64| PI * (R * R - z * z); // slice z above the ball's middle
    let cone_slabs: Vec<(f64, f64)> = [10, 100, 1000].iter().map(|&n| slabs(&cone_at, H, n)).collect();
    let (ball_lo, ball_hi) = slabs(&hemi_at, R, 1000);
    println!("hopper: rim radius {:.0} m, depth {} m, slant {:.6} m; volume {:.6} m^3 = {:.2} litres", R, H, l, cone_v, cone_v * 1000.0);
    println!("rim area {:.6} m^2; hopper = {:.6} m of tank; tank {:.6} m^3, tank and hopper {:.6} m^3",
             PI * R * R, cone_v / (PI * R * R), PI * R * R * TANK, PI * R * R * TANK + cone_v);
    for (n, (lo, hi)) in [10, 100, 1000].iter().zip(cone_slabs.iter()) {
        println!("hopper by {} slabs: inside {:.6}, outside {:.6}", n, lo, hi);
    }
    let (lo, hi) = slabs(&|z: f64| z * z, 1.0, 100);
    println!("1 m cube, one of three pyramids: 1/3 = {:.6}; 100 slabs {:.6} to {:.6}", 1.0 / 3.0, lo, hi);
    println!("stretched to 0.75 m tall {:.6}; base widened to pi m^2 {:.6}; square side {:.6} m", 0.75 / 3.0, PI * 0.75 / 3.0, PI.sqrt());
    println!("hopper steel, pi x r x slant: {:.6} m^2; unrolled sector {:.2} degrees, {:.2} of a {:.2} m disc: {:.6} m^2",
             cone_s, 360.0 * R / l, R / l, l, R / l * PI * l * l);
    let steel: Vec<String> = [4, 10].iter().map(|&k| { let (n, s) = polygon_steel(k); format!("{} sides {:.6}", n, s) }).collect();
    println!("pyramid steel on a rim polygon: {}", steel.join("; "));
    println!("ball 2 m across: volume {:.6} m^3, skin {:.6} m^2; 1000 slabs {:.6} to {:.6}", ball_v, ball_s, 2.0 * ball_lo, 2.0 * ball_hi);
    println!("ball skin by 10, 100, 1000 bands: {:.6}, {:.6}, {:.6}", bands(10), bands(100), bands(1000));
    println!("cylinder 2 m tall round the ball: {:.6} m^3, wall {:.6} m^2, ball / cylinder {:.6}",
             2.0 * PI * R.powi(3), 2.0 * PI * R * (2.0 * R), ball_v / (2.0 * PI * R.powi(3)));
    println!("slice 0.6 m above the middle: ball radius {:.6}, area {:.6}; cylinder minus cone {:.6}; hemisphere {:.6}",
             (R * R - 0.36).sqrt(), hemi_at(0.6), PI * R * R - PI * 0.6_f64.powi(2), PI * R.powi(3) - PI * R.powi(3) / 3.0);
    println!("mistakes: no third {:.6}; slant as depth {:.6}; lid counted {:.6}", PI * R * R * H, PI * R * R * l / 3.0, cone_s + PI * R * R);
    println!("mistakes: third on a 1 m bowl {:.6}; 4 m ball as double {:.6}, truth {:.6}, {:.6} times the 2 m ball",
             PI * R.powi(3) / 3.0, 2.0 * ball_v, 4.0 * PI * 8.0 / 3.0, 4.0 * PI * 8.0 / 3.0 / ball_v);
    println!("figure, hopper at 1 m = 50: tank (130, 20) to ({:.0}, {:.0}), tip ({:.0}, {:.2}), wall {:.2} long",
             130.0 + 100.0 * R, 20.0 + 50.0 * TANK, 130.0 + 50.0 * R, 20.0 + 50.0 * TANK + 50.0 * H, 50.0 * l);
    let (dx, dy) = (60.0 * 0.75_f64.sqrt(), 60.0 * 0.5); // cube figure: depth drawn half size, 30 degrees up
    println!("figure, cube at 1 m = 120, depth half size at 30 degrees: front (100, 200) to (220, 80), back shift ({:.2}, {:.2}), P ({:.2}, {:.2}), Q (100, 200)",
             dx, -dy, 220.0 + dx, 80.0 - dy);
    assert!(cone_slabs.iter().all(|&(lo, hi)| lo < cone_v && cone_v < hi)); // slabs pinch a third of B x h
    assert!((polygon_steel(10).1 - cone_s).abs() < 1e-5); // many-sided pyramid against pi r l
    assert!(2.0 * ball_lo < ball_v && ball_v < 2.0 * ball_hi); // slabs pinch 4/3 pi r^3
    assert!(0.0 < ball_s - bands(1000) && ball_s - bands(1000) < 1e-4); // bands fall just short of 4 pi r^2
    println!("ALL CHECKS PASS");
}
