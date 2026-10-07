// Three geometries -- the same check as the Python, in Rust.  No crates.
// Escher's fish in the Poincare disc: each fish is 1 unit long, drawn smaller near the rim.
// Every number is reached twice: a closed form, and a road that never uses it
// (thin slices, a many-sided polygon, or a circle solved from three points).
use std::f64::consts::PI;
const DEG: f64 = 180.0 / PI;
const N: usize = 200000;
fn drawn(d: f64) -> f64 { (d.exp() - 1.0) / (d.exp() + 1.0) }   // true distance -> drawn radius
fn by_slices(r: f64) -> f64 {                                    // add 2 x slice / (1 - s^2) over thin slices
    let h = r / N as f64;
    (0..N).map(|i| { let s = (i as f64 + 0.5) * h; 2.0 * h / (1.0 - s * s) }).sum()
}
fn dot(u: &[f64], v: &[f64]) -> f64 { u.iter().zip(v).map(|(a, b)| a * b).sum() }
fn ang(u: &[f64], v: &[f64]) -> f64 { (dot(u, v) / (dot(u, u) * dot(v, v)).sqrt()).clamp(-1.0, 1.0).acos() * DEG }
fn tangent(p: &[f64], q: &[f64]) -> Vec<f64> { let d = dot(p, q); p.iter().zip(q).map(|(a, b)| b - d * a).collect() }
fn dist(p: &[f64], q: &[f64]) -> f64 { p.iter().zip(q).map(|(a, b)| (a - b) * (a - b)).sum::<f64>().sqrt() }
fn disc_ring(rho: f64) -> f64 {                                  // polygon on the drawn circle, pieces rescaled
    let (r, n) = (drawn(rho), 20000);
    let pts: Vec<[f64; 2]> = (0..=n).map(|i| { let t = 2.0 * PI * i as f64 / n as f64; [r * t.cos(), r * t.sin()] }).collect();
    pts.windows(2).map(|w| { let (mx, my) = ((w[0][0] + w[1][0]) / 2.0, (w[0][1] + w[1][1]) / 2.0);
        dist(&w[0], &w[1]) * 2.0 / (1.0 - mx * mx - my * my) }).sum()
}
fn ball_ring(rho: f64) -> f64 {                                  // polygon on a ball of radius 1, straight 3-D chords
    let n = 20000;
    let pts: Vec<[f64; 3]> = (0..=n).map(|i| { let t = 2.0 * PI * i as f64 / n as f64; [rho.sin() * t.cos(), rho.sin() * t.sin(), rho.cos()] }).collect();
    pts.windows(2).map(|w| dist(&w[0], &w[1])).sum()
}
fn f(xs: &[f64], k: usize) -> String { xs.iter().map(|x| format!("{:.*}", k, x)).collect::<Vec<_>>().join(", ") }
fn scr(p: (f64, f64)) -> String { format!("({:.1}, {:.1})", 180.0 + 160.0 * p.0, 180.0 - 160.0 * p.1) }
fn rim(u: f64, v: f64, p: f64) -> Vec<(f64, f64)> {              // where the circle centre (u, v), radius p, crosses the rim
    let (c, m) = (u * u + v * v, (1.0 + u * u + v * v - p * p) / 2.0); let w = (c - m * m).sqrt();
    [-1.0, 1.0].iter().map(|s| ((m * u + s * v * w) / c, (m * v - s * u * w) / c)).collect()
}
fn main() {
    let ends: Vec<f64> = (0..6).map(|k| drawn(k as f64)).collect();
    let lengths: Vec<f64> = ends.windows(2).map(|w| w[1] - w[0]).collect();
    let back: Vec<f64> = ends[1..].iter().map(|&r| by_slices(r)).collect();
    let rs = [1.0f64, 2.0, 3.0];
    let hyp: Vec<f64> = rs.iter().map(|p| 2.0 * PI * (p.exp() - (-p).exp()) / 2.0).collect();
    let hyp_poly: Vec<f64> = rs.iter().map(|&p| disc_ring(p)).collect();
    let ball: Vec<f64> = rs.iter().map(|p| 2.0 * PI * p.sin()).collect();
    let ball_poly: Vec<f64> = rs.iter().map(|&p| ball_ring(p)).collect();
    let (a0, b1, astar) = (0.5f64, 0.5, 2.0);                    // A = (0.5, 0), B = (0, 0.5), A* = (2, 0)
    let cx = (astar * astar - a0 * a0) / (2.0 * (astar - a0));
    let cy = (b1 * b1 - a0 * a0 + 2.0 * a0 * cx) / (2.0 * b1);
    let rad = ((a0 - cx) * (a0 - cx) + cy * cy).sqrt();
    let at_a = ang(&[-1.0, 0.0], &[-cy, cx - a0]);
    let flat = [ang(&[1.0, 0.0], &[0.0, 1.0]), ang(&[-1.0, 0.0], &[-0.5, 0.5]), ang(&[0.0, -1.0], &[0.5, -0.5])];
    let v = [[0.0, 0.0, 1.0], [1.0, 0.0, 0.0], [0.0, 1.0, 0.0]]; // north pole, two equator points
    let octant: Vec<f64> = (0..3).map(|i| ang(&tangent(&v[i], &v[(i + 1) % 3]), &tangent(&v[i], &v[(i + 2) % 3]))).collect();
    let total = 90.0 + 2.0 * at_a;
    let lines: Vec<(f64, f64, f64)> = [0.0f64, 0.5].iter().map(|&u| (u, cy, (u * u + (cy - b1) * (cy - b1)).sqrt())).collect(); // through B, h from road one
    let (fs, os): (f64, f64) = (flat.iter().sum(), octant.iter().sum());
    println!("fish far ends, true 1..5, drawn at: {}", f(&ends[1..], 6));
    println!("fish drawn lengths: {}", f(&lengths, 3));
    println!("fish far ends, true, recovered by thin slices: {}", f(&back, 6));
    println!("ring, true radius 1, 2, 3: flat {} | hyperbolic 2 pi sinh {}", f(&rs.map(|p| 2.0 * PI * p), 2), f(&hyp, 2));
    println!("ring, hyperbolic by disc polygon: {} | ball 2 pi sin {} | ball polygon {}", f(&hyp_poly, 2), f(&ball, 2), f(&ball_poly, 2));
    let sh: Vec<f64> = rs.iter().map(|p| (p.exp() - (-p).exp()) / 2.0).collect();
    println!("by hand: e^1..3 {} | sinh 1..3 {} | sin 3 {:.3}", f(&rs.map(|p| p.exp()), 3), f(&sh, 2), 3.0f64.sin());
    println!("flat triangle O, A, B: {} sum {} | octant on a ball: {} sum {}", f(&flat, 6), f(&[fs], 6), f(&octant, 6), f(&[os], 6));
    println!("disc side AB: circle through A, B, A* centre ({:.6}, {:.6}), radius {:.6}", cx, cy, rad);
    println!("disc angle at A: tangent road {:.6}, atan(3/5) road {:.6}", at_a, 0.6f64.atan() * DEG);
    let sm = 0.05f64;
    println!("disc triangle sum {:.6}, short of 180 by {:.6}; at a = 0.05, {:.6}", total, 180.0 - total, 90.0 + 2.0 * ((1.0 - sm * sm) / (1.0 + sm * sm)).atan() * DEG);
    for &(u, c, p) in &lines {
        println!("line through B, centre ({:.1}, {:.2}): radius {:.6}, rim test {:.6}, lowest y {:.6}", u, c, p, u * u + c * c - p * p, c - p);
    }
    let fx: Vec<f64> = ends[1..].iter().map(|r| 180.0 + 110.0 * r).collect();
    println!("figure 1, disc centre (180, 120), radius 110; fish ends x: {}", f(&fx, 1));
    let ends_s: Vec<String> = lines.iter().flat_map(|&(u, c, p)| rim(u, c, p)).map(scr).collect();
    let arcs: Vec<f64> = [rad].iter().chain(lines.iter().map(|l| &l.2)).map(|r| 160.0 * r).collect();
    println!("figure 2, centre (180, 180), radius 160; A {} B {} arcs radius {} | rim ends {}", scr((a0, 0.0)), scr((0.0, b1)), f(&arcs, 1), ends_s.join(" "));
    println!("mistakes: chord triangle {:.6}; flat ring at 3 is {:.2} not {:.2}; drawn {:.6} is true {:.6}", fs, 2.0 * PI * 3.0, hyp[2], ends[4], by_slices(ends[4]));
    assert!(back.iter().enumerate().all(|(k, b)| (b - (k + 1) as f64).abs() < 1e-6));        // slices undo the closed form
    assert!(hyp.iter().chain(&ball).zip(hyp_poly.iter().chain(&ball_poly)).all(|(a, b)| (a - b).abs() < 1e-3));
    assert!((at_a - 0.6f64.atan() * DEG).abs() < 1e-9 && (os - 270.0).abs() < 1e-9); // two roads to the disc angle; octant
    assert!(lines.iter().all(|&(u, c, p)| c - p > 0.0 && rim(u, c, p).iter().all(|q| (q.0 * (q.0 - u) + q.1 * (q.1 - c)).abs() < 1e-12))); // radii square at rim; miss OA
    println!("ALL CHECKS PASS");
}
