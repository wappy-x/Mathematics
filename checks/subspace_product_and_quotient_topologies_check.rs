// Subspace, product and quotient topologies -- the same check as the Python, in Rust.
// No crates.  Part 1 bends a 100 cm tape into a hoop and a torus (lengths in cm).
// Part 2 checks finite models exhaustively: the tape squeezed to 5 pieces, its ends
// glued into the four-point circle, and the four-point torus.  A set of pieces is a
// bitmask, so every count in part 2 is exact.
use std::collections::BTreeSet;
use std::f64::consts::PI;

const L: f64 = 100.0;
const LT: f64 = 30.0;
const R: f64 = L / (2.0 * PI);
const RT: f64 = LT / (2.0 * PI);

fn f(x: f64) -> String { format!("{:.4}", x) }
fn yn(c: bool) -> &'static str { if c { "yes" } else { "no" } }

fn hoop(t: f64) -> (f64, f64) {             // the wrap map w: tape mark t -> a point of the plane
    let a = 2.0 * PI * t / L;
    (R * a.cos(), R * a.sin())
}
fn chord(s: f64, t: f64) -> f64 {           // straight-line distance in the plane
    let ((x1, y1), (x2, y2)) = (hoop(s), hoop(t));
    (x1 - x2).hypot(y1 - y2)
}
fn round_gap(s: f64, t: f64) -> f64 {       // distance along the glued tape: the shorter way round
    let d = (s - t).abs() % L;
    d.min(L - d)
}
fn tube(s: f64, t: f64) -> [f64; 3] {       // the torus in space: s round the hole, t round the tube
    let (a, b) = (2.0 * PI * s / L, 2.0 * PI * t / LT);
    [(R + RT * b.cos()) * a.cos(), (R + RT * b.cos()) * a.sin(), RT * b.sin()]
}
fn dist(p: &[f64; 3], q: &[f64; 3]) -> f64 {
    ((p[0] - q[0]).powi(2) + (p[1] - q[1]).powi(2) + (p[2] - q[2]).powi(2)).sqrt()
}
// A space is a list of smallest open sets, one per piece; a set of pieces is open
// when it holds the smallest open set of each piece in it.
fn opens_by_rule(u: &[u32]) -> Vec<u32> {
    let n = u.len();
    (0..1u32 << n).filter(|&s| (0..n).all(|x| s >> x & 1 == 0 || u[x] & !s == 0)).collect()
}
fn names(s: u32, label: &[&str]) -> String {
    let v: Vec<&str> = (0..label.len()).filter(|&i| s >> i & 1 == 1).map(|i| label[i]).collect();
    format!("{{{}}}", v.join(", "))
}
fn piece(a: f64) -> u32 {                   // road 2: a circle point at angle a, placed by its coordinates
    let (x, y) = (a.to_radians().cos(), a.to_radians().sin());
    if y > 1e-9 { 1 } else if y < -1e-9 { 3 } else if x > 0.0 { 0 } else { 2 }
}
fn bx(u: u32, v: u32) -> u32 {
    let mut out = 0;
    for x in 0..4 { for y in 0..4 { if u >> x & 1 == 1 && v >> y & 1 == 1 { out |= 1 << (4 * x + y) } } }
    out
}

fn main() {
    println!("hoop {} cm round, radius {} cm; tube {} cm round, radius {} cm", L, f(R), LT, f(RT));
    println!("marks 1 and 99: {} cm apart on the flat tape, {} cm round the hoop, chord {} cm",
             f(98.0), f(round_gap(1.0, 99.0)), f(chord(1.0, 99.0)));
    let pairs: Vec<(f64, f64)> = (0..100).map(|k| (k as f64, ((37 * k + 11) % 100) as f64)).collect();
    let err = pairs.iter().map(|&(s, t)| (chord(s, t) - 2.0 * R * (PI * round_gap(s, t) / L).sin()).abs())
        .fold(0.0, f64::max);
    println!("chord against 2R sin(pi gap / L), checked on {} pairs: worst gap below 1e-9: {}", pairs.len(), yn(err < 1e-9));
    let d_asin = (L / PI) * (1.0 / R).asin();          // road 1: solve 2R sin(pi d / L) = 2
    let (mut lo, mut hi) = (0.0, L / 2.0);             // road 2: halve the interval 60 times
    for _ in 0..60 {
        let mid = (lo + hi) / 2.0;
        if chord(0.0, mid) > 2.0 { hi = mid } else { lo = mid }
    }
    println!("disc of radius 2 cm round the join meets the hoop within {} cm of mark 0 (by asin); by halving {}",
             f(d_asin), f(lo));
    println!("its pre-image on the tape: [0, {}) and ({}, 100]", f(d_asin), f(L - d_asin));
    for h in [1.0, 0.1, 0.01] {
        println!("unglued: mark {} lands {} cm from mark 0's point, {} cm from it along the tape",
                 f(L - h), f(chord(0.0, L - h)), f(L - h));
    }
    let (x0, y0) = hoop(d_asin);
    println!("figure, tape 0 to 100 at 6 px per cm; hoop radius {}; disc radius 2 at ({}, 0); arc ends ({}, {}) and ({}, {})",
             f(R), f(R), f(x0), f(y0), f(x0), f(-y0));
    let ends = [tube(0.0, 0.0), tube(L, 0.0), tube(0.0, LT), tube(L, LT)];
    let same = ends.iter().all(|p| (0..3).all(|i| (p[i] - ends[0][i]).abs() < 1e-9));
    let mut grid = Vec::new();
    for i in 0..20 { for j in 0..6 { grid.push(tube(5.0 * i as f64, 5.0 * j as f64)) } }
    let res = grid.iter().map(|p| ((p[0].hypot(p[1]) - R).powi(2) + p[2] * p[2] - RT * RT).abs()).fold(0.0, f64::max);
    let mut gap = f64::INFINITY;
    for k in 0..grid.len() { for m in 0..k { gap = gap.min(dist(&grid[k], &grid[m])) } }
    println!("torus: the square's 4 corners land on one point: {}", yn(same));
    println!("torus: {} grid points, all on the tube to within 1e-9: {}; closest two {} cm apart",
             grid.len(), yn(res < 1e-9), f(gap));

    let tape_l = ["0", "(0,1/2)", "1/2", "(1/2,1)", "1"];
    let circ = ["east", "top", "west", "bottom"];
    let tape: BTreeSet<u32> = opens_by_rule(&[0b00011, 0b00010, 0b01110, 0b01000, 0b11000]).into_iter().collect();
    let q = [0u32, 1, 2, 3, 0];                        // the glue: mark 0 and mark 1 both go to east
    let pre = |v: u32| -> u32 { (0..5).filter(|&i| v >> q[i] & 1 == 1).map(|i| 1u32 << i).sum() };
    let quot: Vec<u32> = (0..16).filter(|&v| tape.contains(&pre(v))).collect();     // road 1
    let near: Vec<u32> = [0.0, 90.0, 180.0, 270.0].iter()
        .map(|&a| [-1.0, 0.0, 1.0].iter().fold(0, |m, &da| m | 1 << piece(a + da))).collect();
    let plane = opens_by_rule(&near);                  // traces on the circle of small discs in the plane
    let mut cands: Vec<BTreeSet<u32>> = Vec::new();    // road 3: every topology making q continuous
    for m in 0..1u32 << 14 {
        let mut fam: BTreeSet<u32> = [0u32, 15].into_iter().collect();
        for v in 1..15u32 { if m >> (v - 1) & 1 == 1 { fam.insert(v); } }
        let cont = fam.iter().all(|&v| tape.contains(&pre(v)));
        if cont && fam.iter().all(|&a| fam.iter().all(|&b| fam.contains(&(a | b)) && fam.contains(&(a & b)))) {
            cands.push(fam);
        }
    }
    let big = cands.iter().max_by_key(|c| c.len()).unwrap().clone();
    let holds = cands.iter().all(|c| c.is_subset(&big));
    let bigv: Vec<u32> = big.iter().copied().collect();
    let ends_held = tape.iter().filter(|&&s| s & 0b10001 != 0).count();
    println!("tape in 5 pieces: {} open sets; {} of them hold an end mark", tape.len(), ends_held);
    let listed: Vec<String> = quot.iter().map(|&v| names(v, &circ)).collect();
    println!("glued, by the quotient rule: {} open sets: {}", quot.len(), listed.join(" "));
    println!("circle in the plane, by small discs: {} open sets; same family: {}", plane.len(), yn(plane == quot));
    println!("topologies making the glue continuous: {}; largest has {} sets, holds every other: {}; same family: {}",
             cands.len(), big.len(), yn(holds), yn(bigv == quot));
    let bad = 0b00011;                                 // the open set {0, (0,1/2)} of the tape
    println!("image of the open set {} is {}: open? {}", names(bad, &tape_l), names(1 | 2, &circ), yn(quot.contains(&(1 | 2))));

    let boxes: BTreeSet<u32> = quot.iter().flat_map(|&u| quot.iter().map(move |&v| bx(u, v))).collect();
    let mut unions = boxes.clone();                    // road 1: every union of boxes
    let mut todo: Vec<u32> = boxes.iter().copied().collect();
    while let Some(u) = todo.pop() {
        for &b in &boxes { if unions.insert(u | b) { todo.push(u | b) } }
    }
    let small: Vec<u32> = (0..16).map(|k| bx(near[k / 4], near[k % 4])).collect();
    let rule = opens_by_rule(&small);                  // road 2
    let unions_v: Vec<u32> = unions.iter().copied().collect();
    println!("torus of 16 pieces: {} distinct boxes; {} open sets as unions of boxes", boxes.len(), unions.len());
    println!("the same {} open sets by the smallest-open-set rule: {}", rule.len(), yn(unions_v == rule));
    let slices: Vec<bool> = (0..4).map(|y| {             // the subspace circle x {y} inside the torus
        let trace: BTreeSet<u32> = rule.iter()
            .map(|&w| (0..4).filter(|&x| w >> (4 * x + y) & 1 == 1).map(|x| 1u32 << x).sum()).collect();
        trace.into_iter().collect::<Vec<u32>>() == quot
    }).collect();
    println!("each of the 4 slices circle x {{point}} carries the circle's 7 open sets: {}", yn(slices.iter().all(|&b| b)));

    assert!((d_asin - lo).abs() < 1e-9 && err < 1e-9);  // two roads to the arc; chord vs gap
    assert!(plane == quot && bigv == quot && holds);
    assert!(quot.len() == 7 && tape.len() == 13 && !quot.contains(&(1 | 2)));
    assert!(unions_v == rule && slices.iter().all(|&b| b) && same && res < 1e-9 && gap > 0.1);
    println!("ALL CHECKS PASS");
}
