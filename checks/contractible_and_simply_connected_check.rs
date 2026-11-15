// Contractible and simply connected -- the check behind the card.  Rust std only.
// A round lawn, radius 10 m, centred on a lamp post whose base has radius 1 m.
// Disc: the lawn with no post.  Annulus: 1 <= |x| <= 10.  Punctured plane: |x| > 0.
// A walker's loop is a polygon with whole-metre corners.  Roads to its winding number:
// signed crossings of the ray east from the post (exact), and the total turn of the
// sight line from the post (atan2).  Homotopies are checked stage by stage: N cases.
use std::f64::consts::PI;

fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
#[derive(Clone, Copy, PartialEq)]
struct Q { n: i128, d: i128 } // an exact fraction n/d, d > 0, in lowest terms
fn q(n: i128, d: i128) -> Q { let g = gcd(n, d).max(1); let s = if d < 0 { -1 } else { 1 }; Q { n: s * n / g, d: s * d / g } }
fn lt(a: Q, b: Q) -> bool { a.n * b.d < b.n * a.d }
fn qs(a: Q) -> String { if a.d == 1 { format!("{}", a.n) } else { format!("{}/{}", a.n, a.d) } }
fn qf(a: Q) -> f64 { a.n as f64 / a.d as f64 }

type P = (i128, i128); // corners in whole units; each caller says what a unit is
const SQ: [P; 4] = [(4, -4), (4, 4), (-4, 4), (-4, -4)]; // 8 m square round the post, anticlockwise

fn edges(p: &[P]) -> Vec<(P, P)> { (0..p.len()).map(|i| (p[i], p[(i + 1) % p.len()])).collect() }

fn crossings(p: &[P]) -> (i64, i64) { // road 1: signed crossings of the ray east from (0, 0)
    let (mut up, mut down) = (0, 0);
    for ((ax, ay), (bx, by)) in edges(p) {
        // x-intercept ax - ay (bx - ax) / (by - ay) > 0, cleared of its denominator
        if (ay <= 0) != (by <= 0) && (ax * (by - ay) - ay * (bx - ax)) * (by - ay) > 0 {
            if by > ay { up += 1 } else { down += 1 }
        }
    }
    (up, down)
}

fn turns(p: &[(f64, f64)]) -> f64 { // road 2: total turn of the sight line, in whole turns
    let mut t = 0.0;
    for i in 0..p.len() {
        let ((ax, ay), (bx, by)) = (p[i], p[(i + 1) % p.len()]);
        t += (ax * by - ay * bx).atan2(ax * bx + ay * by);
    }
    let w = t / (2.0 * PI);
    if w.abs() < 1e-9 { 0.0 } else { w } // print 0, never -0
}
fn fl(p: &[P]) -> Vec<(f64, f64)> { p.iter().map(|&(x, y)| (x as f64, y as f64)).collect() }

fn near2(p: &[P]) -> Q { // exact squared distance from the post's centre to the nearest point
    let mut best: Option<Q> = None;
    for ((ax, ay), (bx, by)) in edges(p) {
        let (dx, dy) = (bx - ax, by - ay);
        let l = dx * dx + dy * dy;
        let u = if l == 0 { q(0, 1) } else { let r = q(-(ax * dx + ay * dy), l);
            if lt(r, q(0, 1)) { q(0, 1) } else if lt(q(1, 1), r) { q(1, 1) } else { r } };
        let (x, y) = (ax * u.d + u.n * dx, ay * u.d + u.n * dy);
        let d = q(x * x + y * y, u.d * u.d);
        best = Some(match best { None => d, Some(b) => if lt(d, b) { d } else { b } });
    }
    best.unwrap()
}
fn far2(p: &[P]) -> i128 { p.iter().map(|&(x, y)| x * x + y * y).max().unwrap() }

fn main() {
    let rev: Vec<P> = SQ.iter().rev().cloned().collect();
    let mut back: Vec<P> = SQ.to_vec(); back.push((4, -4)); back.extend_from_slice(&rev[..3]);
    let twice: Vec<P> = SQ.iter().chain(SQ.iter()).cloned().collect();
    let loops: Vec<(&str, Vec<P>)> = vec![("once round, anticlockwise", SQ.to_vec()), ("once round, clockwise", rev.clone()),
        ("round, then back the other way", back), ("twice round", twice),
        ("beside the post, not round it", vec![(3, -2), (7, -2), (7, 2), (3, 2)])];
    let mut wind = vec![];
    for (name, p) in &loops {
        let (u, d) = crossings(p); let w = turns(&fl(p)); wind.push((u - d, w.round() as i64));
        println!("{:<31}: ray crossings up {} down {}, signed {}; turns {:.6}; nearest {:.6} m",
                 name, u, d, u - d, w, qf(near2(p)).sqrt());
    }

    println!("shrink H(x, t) = (1 - t) x on the once-round square, stage by stage:");
    let mut stages = vec![]; // corners in eighths of a metre, so (1 - t) x stays whole
    for k in 0..=8i128 {
        let t = q(k, 8);
        let p: Vec<P> = SQ.iter().map(|&(x, y)| (x * (8 - k), y * (8 - k))).collect();
        let n2r = near2(&p); let n2 = q(n2r.n, n2r.d * 64);
        let inb = !lt(n2, q(1, 1));
        let where_ = if inb { "disc and annulus" } else { "disc only: inside the base" };
        let sig = if n2.n > 0 { let (u, d) = crossings(&p); Some(u - d) } else { None };
        let sigs = match sig { Some(s) => format!("{}", s), None => "none: a point on the post".to_string() };
        stages.push((t, n2, sig, far2(&p)));
        println!("  t = {:<4} half-side {:.1} m, nearest {:.6} m, farthest {:.6} m, winding {}; {}",
                 qs(t), SQ[1].0 as f64 * (8 - k) as f64 / 8.0, qf(n2).sqrt(), (far2(&p) as f64 / 64.0).sqrt(), sigs, where_);
    }
    let t_hit = stages.iter().filter(|s| !lt(q(1, 1), s.1)).map(|s| s.0).next().unwrap();
    let formula = q(3, 4); // 1 - 1/4
    println!("straight shrink touches the 1 m base at t = {} (formula 1 - 1/4 = {})", qs(t_hit), qs(formula));

    let rim: (i128, i128) = (6, 8); // a point on the disc's edge, 10 m out
    println!("disc contraction of the rim point (6, 8): t = 1/2 gives ({}, {}), t = 1 gives (0, 0)",
             qs(q(rim.0, 2)), qs(q(rim.1, 2)));

    let retract = |x: f64, y: f64, t: f64| { let r = (x * x + y * y).sqrt(); (x / ((1.0 - t) + t * r), y / ((1.0 - t) + t * r)) };
    let parts: Vec<String> = [0.0, 0.5, 1.0].iter().map(|&t| { let (a, b) = retract(3.0, 4.0, t); format!("({:.6}, {:.6})", a, b) }).collect();
    println!("retract the punctured plane, (3, 4) at t = 0, 1/2, 1: {}", parts.join(" -> "));
    let mut side: Vec<(f64, f64)> = (0..16).map(|j| (4.0 - j as f64 / 2.0, 4.0)).collect();
    side.extend((0..16).map(|j| (-4.0, 4.0 - j as f64 / 2.0)));
    let mut samples = side.clone(); samples.extend(side.iter().map(|&(x, y)| (-x, -y)));
    let circ: Vec<(f64, f64)> = samples.iter().map(|&(x, y)| retract(x, y, 1.0)).collect();
    let mut r_min = f64::INFINITY;
    for s in 0..11 { for &(a, b) in &samples { let (x, y) = retract(a, b, s as f64 / 10.0); r_min = r_min.min((x * x + y * y).sqrt()); } }
    let tc = turns(&circ);
    println!("retracted square, 64 sample points: turns {:.6}; nearest to the hole over 11 stages {:.6} m", tc, r_min);

    // in space, remove only one point: lift the loop of radius 4 m over it
    let d2: Vec<Q> = (0..=100i128).map(|k| q(16 * ((100 - k) * (100 - k) + k * k), 10000)).collect();
    let mut kb = 0; for k in 0..d2.len() { if lt(d2[k], d2[kb]) { kb = k } }
    let (best, t_best) = (d2[kb], q(kb as i128, 100));
    println!("space minus a point: lift H(s, t) = ((1 - t) 4 cos 2 pi s, (1 - t) 4 sin 2 pi s, 4t); nearest {:.6} m at t = {} (101 stages), formula 2 sqrt 2 = {:.6}",
             qf(best).sqrt(), qs(t_best), 2.0 * 2f64.sqrt());

    println!("figure, panel centres (120, 130) (350, 130) (580, 130); 10 units a metre; disc and lawn radius 100; base radius 10; squares half-side 40, 20, 10");

    assert!(wind.iter().map(|w| w.0).collect::<Vec<_>>() == vec![1, -1, 0, 2, 0], "signed crossings");
    assert!(wind.iter().all(|w| w.0 == w.1), "two roads to the winding number");
    assert!(near2(&loops[4].1) == q(9, 1), "beside the post: nearest 3 m, at (3, 0)");
    assert!(stages.iter().filter(|s| !lt(s.1, q(1, 1))).all(|s| s.2 == Some(1)), "winding stays 1 while the loop avoids the base");
    assert!(t_hit == formula && stages[6].1 == q(1, 1), "the shrink meets the base exactly at t = 3/4");
    assert!(stages.iter().all(|s| s.3 <= 100 * 64), "every stage stays in the 10 m disc");
    assert!(tc.round() == 1.0 && (r_min - 1.0).abs() < 1e-12, "retraction keeps the winding and avoids the hole");
    assert!(best == q(8, 1) && t_best == q(1, 2), "lift: nearest squared distance 8 m2 at t = 1/2");
    println!("ALL CHECKS PASS");
}
