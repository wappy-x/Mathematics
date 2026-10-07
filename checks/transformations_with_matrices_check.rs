// Moving shapes with matrices -- the same check as the Python, in Rust, std
// only.  A 4 cm by 2 cm logo, lower-left corner A at (3, 1) cm, turns 30
// degrees anticlockwise about A.  Road one: 3 x 3 matrices acting on (x, y, 1).
// Road two: each corner's distance and angle from A, angle plus 30, and back.
type M = [[f64; 3]; 3];

fn mul(m: &M, n: &M) -> M {
    let mut o = [[0.0; 3]; 3];
    for i in 0..3 { for j in 0..3 { for k in 0..3 { o[i][j] += m[i][k] * n[k][j]; } } }
    o
}
fn apply(m: &M, v: [f64; 3]) -> [f64; 3] {
    let mut o = [0.0; 3];
    for i in 0..3 { for k in 0..3 { o[i] += m[i][k] * v[k]; } }
    o
}
fn shift(a: f64, b: f64) -> M { [[1.0, 0.0, a], [0.0, 1.0, b], [0.0, 0.0, 1.0]] }
fn turn(t: f64) -> M { [[t.cos(), -t.sin(), 0.0], [t.sin(), t.cos(), 0.0], [0.0, 0.0, 1.0]] }
fn about_a(m: &M) -> M { mul(&shift(3.0, 1.0), &mul(m, &shift(-3.0, -1.0))) }
fn area(p: &[[f64; 2]]) -> f64 {          // shoelace: signed area, positive anticlockwise
    let n = p.len();
    (0..n).map(|i| p[i][0] * p[(i + 1) % n][1] - p[(i + 1) % n][0] * p[i][1]).sum::<f64>() / 2.0
}
fn mv(m: &M, pts: &[[f64; 2]]) -> Vec<[f64; 2]> {
    pts.iter().map(|&[x, y]| { let o = apply(m, [x, y, 1.0]); [o[0], o[1]] }).collect()
}
fn pt(v: [f64; 2]) -> String { format!("({:.6}, {:.6})", v[0], v[1]) }
fn d(u: [f64; 2], v: [f64; 2]) -> f64 { (u[0] - v[0]).hypot(u[1] - v[1]) }

fn main() {
    let (p, q, names) = (3.0_f64, 1.0_f64, ["A", "B", "C", "D"]);
    let logo = [[3.0, 1.0], [7.0, 1.0], [7.0, 3.0], [3.0, 3.0]];
    let r30 = 30.0_f64.to_radians();
    let h = about_a(&turn(r30));
    let road1 = mv(&h, &logo);
    let road2: Vec<[f64; 2]> = logo.iter().map(|&[x, y]| {  // polar about A: same distance, angle + 30
        let (r, ang) = ((x - p).hypot(y - q), (y - q).atan2(x - p) + r30);
        [p + r * ang.cos(), q + r * ang.sin()]
    }).collect();
    println!("cos 30 = {:.6}, sin 30 = {:.6}", r30.cos(), r30.sin());
    for i in 0..2 { println!("H row {}: {:.6} {:.6} {:.6}", i + 1, h[i][0], h[i][1], h[i][2]); }
    for i in 0..4 {
        println!("{} ({}, {}) -> {} by matrix, {} by angle", names[i], logo[i][0], logo[i][1], pt(road1[i]), pt(road2[i]));
    }
    let offs: Vec<String> = (1..4).map(|i| format!("{} {}", names[i], pt([road1[i][0] - p, road1[i][1] - q]))).collect();
    println!("offsets from A after the turn: {}", offs.join(" "));
    println!("after the turn: sides {:.6} and {:.6} cm, area {:.6} cm^2", d(road1[0], road1[1]), d(road1[0], road1[3]), area(&road1));
    let up = apply(&h, [0.0, 1.0, 0.0]);
    println!("direction (0, 1, 0) -> ({:.6}, {:.6}, {:.0}): the shift never touches it", up[0], up[1], up[2].abs());
    let big = mv(&about_a(&[[1.5, 0.0, 0.0], [0.0, 1.5, 0.0], [0.0, 0.0, 1.0]]), &logo);
    let mir = mv(&about_a(&[[-1.0, 0.0, 0.0], [0.0, 1.0, 0.0], [0.0, 0.0, 1.0]]), &logo);
    println!("scale 1.5 about A: C -> {}, area {:.6} cm^2", pt(big[2]), area(&big));
    println!("mirror in the line x = 3: B -> {}, signed area {:.6} cm^2", pt(mir[1]), area(&mir));
    println!("mistake, turn about (0, 0): A -> {}", pt(mv(&turn(r30), &logo)[0]));
    let wrong = mul(&shift(-3.0, -1.0), &mul(&turn(r30), &shift(3.0, 1.0)));
    println!("mistake, shifts in the wrong order: A -> {}", pt(mv(&wrong, &logo)[0]));
    println!("mistake, 30 read as radians: B -> {}", pt(mv(&about_a(&turn(30.0)), &logo)[1]));
    println!("mistake, sine signs swapped: B -> {}", pt(mv(&about_a(&turn(-r30)), &logo)[1]));
    let fig: Vec<String> = (0..4).map(|i| format!("{}' ({:.2}, {:.2})", names[i], 30.0 + 36.0 * road1[i][0], 220.0 - 36.0 * road1[i][1])).collect();
    println!("figure, 1 cm = 36 units, {}", fig.join(" "));
    let gap = (0..4).map(|i| (road1[i][0] - road2[i][0]).abs().max((road1[i][1] - road2[i][1]).abs())).fold(0.0, f64::max);
    assert!(gap < 1e-12);
    assert!((road1[0][0] - p).abs() < 1e-12 && (road1[0][1] - q).abs() < 1e-12); // the pivot stays
    assert!((d(road1[0], road1[1]) - 4.0).abs() < 1e-12 && (area(&road1) - 4.0 * 2.0).abs() < 1e-12);
    assert!((area(&big) - (4.0 * 1.5) * (2.0 * 1.5)).abs() < 1e-12 && (area(&mir) + 8.0).abs() < 1e-12);
    println!("ALL CHECKS PASS");
}
