// Connected and path-connected -- the same check as the Python, in Rust.  No
// crates.  Part 1 cuts the circle and the line into finitely many pieces (open
// arcs and cut points) and splits what is left into components two independent
// ways; every subset is tested, so those counts are proved for the finite
// models.  Part 2 halves [0, 1] onto the seam of a split that fails.  Part 3
// measures the topologist's sine curve; it illustrates the proofs on the card.
// A set of points is a bit mask: point p is bit p.
use std::f64::consts::PI;

fn minimal(p: u32, m: u32) -> u32 {               // smallest open set round point p
    if p % 2 == 0 { 1 << p } else { (1 << ((p + m - 1) % m)) | (1 << p) | (1 << ((p + 1) % m)) }
}
fn is_open(s: u32, y: u32, m: u32) -> bool {      // open in the subspace y
    (0..m).filter(|&p| s >> p & 1 == 1).all(|p| minimal(p, m) & y & !s == 0)
}
fn subsets(y: u32) -> Vec<u32> { (0..1u32 << 9).filter(|&s| s & !y == 0).collect() }
fn connected(y: u32, m: u32) -> bool {            // no split into two non-empty open pieces
    !subsets(y).iter().any(|&s| s != 0 && s != y && is_open(s, y, m) && is_open(y & !s, y, m))
}
fn sorted_pieces(mut v: Vec<u32>) -> Vec<u32> {
    v.sort_by_key(|&c| c.trailing_zeros());
    v.dedup();
    v
}
fn pieces_by_splits(y: u32, m: u32) -> Vec<u32> { // road 1: union of every connected set round p
    let good: Vec<u32> = subsets(y).into_iter().filter(|&s| s != 0 && connected(s, m)).collect();
    sorted_pieces((0..m).filter(|&p| y >> p & 1 == 1)
        .map(|p| good.iter().filter(|&&s| s >> p & 1 == 1).fold(0, |a, &s| a | s)).collect())
}
fn find(boss: &Vec<u32>, mut p: u32) -> u32 {
    while boss[p as usize] != p { p = boss[p as usize]; }
    p
}
fn pieces_by_joins(y: u32, m: u32) -> Vec<u32> {  // road 2: join each point to its smallest open set
    let mut boss: Vec<u32> = (0..m).collect();
    for p in (0..m).filter(|&p| y >> p & 1 == 1) {
        for q in (0..m).filter(|&q| (minimal(p, m) & y) >> q & 1 == 1) {
            let (rq, rp) = (find(&boss, q), find(&boss, p));
            boss[rq as usize] = rp;
        }
    }
    sorted_pieces((0..m).filter(|&p| y >> p & 1 == 1)
        .map(|p| (0..m).filter(|&q| y >> q & 1 == 1 && find(&boss, q) == find(&boss, p)).fold(0, |a, q| a | 1 << q))
        .collect())
}
fn sizes(v: &Vec<u32>) -> Vec<u32> { v.iter().map(|c| c.count_ones()).collect() }
fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }

fn main() {
    println!("Part 1: the circle and the line cut into open arcs (even) and cut points (odd)");
    let n = 4u32;
    let (circle, line) = (2 * n, 2 * n + 1);      // the line's two end pieces are open rays
    let whole = (1u32 << circle) - 1;
    let clopen = subsets(whole).iter().filter(|&&s| is_open(s, whole, circle) && is_open(whole & !s, whole, circle)).count();
    println!("circle of {} points: open-and-closed subsets {} of {}: connected {}", circle, clopen, 1 << circle, yn(clopen == 2));
    let mut counts = vec![];
    for k in 0..=n {
        let y = whole & !(0..k).fold(0, |a, j| a | 1 << (2 * j + 1));
        let (a, b) = (pieces_by_splits(y, circle), pieces_by_joins(y, circle));
        assert!(a == b);                                                 // two roads agree
        counts.push(a.len());
        println!("circle minus {} cut points: pieces {}, sizes {:?}", k, a.len(), sizes(&a));
    }
    let mut line_counts = vec![];
    for k in 0..3u32 {
        let y = ((1u32 << line) - 1) & !(0..k).fold(0, |a, j| a | 1 << (2 * j + 1));
        let (a, b) = (pieces_by_splits(y, line), pieces_by_joins(y, line));
        assert!(a == b);
        line_counts.push(a.len());
        println!("line minus {} cut points: pieces {}, sizes {:?}", k, a.len(), sizes(&a));
    }
    println!("one cut point out: circle pieces {}, line pieces {}: not homeomorphic", counts[1], line_counts[1]);
    assert!(clopen == 2 && counts == vec![1, 1, 2, 3, 4] && line_counts == vec![1, 2, 3]);

    println!("Part 2: try to split [0, 1] at U = {{t : 2t^2 < 1}}, V = {{t : 2t^2 >= 1}}");
    let (mut a, mut i): (i128, u32) = (0, 0);     // the bracket is a/2^i to (a+1)/2^i
    while i < 30 {
        let mid = 2 * a + 1;
        a = if 2 * mid * mid < 4i128.pow(i + 1) { mid } else { 2 * a };
        i += 1;
        if i == 10 || i == 20 || i == 30 {
            let t = 10i128.pow(12);
            println!("after {} halvings: {}/2^{} to {}/2^{} = 0.{:012} to 0.{:012}",
                     i, a, i, a + 1, i, a * t / (1i128 << i), (a + 1) * t / (1i128 << i));
        }
    }
    assert!(2 * a * a < 4i128.pow(i) && 4i128.pow(i) <= 2 * (a + 1) * (a + 1));   // seam inside
    let seam = 0.5f64.sqrt();
    let p2 = (1i128 << i) as f64;
    assert!((a as f64) / p2 < seam && seam < ((a + 1) as f64) / p2);   // bracket meets root
    println!("the seam: 1/root 2 = {:.12}; in V, and every window round it meets U", seam);
    let none = (1..=1000i64).all(|q| (0..=q).all(|p| 2 * p * p != q * q));
    println!("no fraction p/q in [0, 1] with q up to 1000 sits on the seam: {}", yn(none));
    println!("so the fractions in [0, 1] do split: U and V are both open there");
    assert!(none);

    println!("Part 3: the topologist's sine curve, y = sin(1/x) for 0 < x <= 1, plus x = 0");
    println!("start of the graph: (1, {:.9})", 1.0f64.sin());
    for d in [0.1f64, 0.01, 0.001] {
        let (mut kp, mut km) = (0.0f64, 0.0f64);
        while 1.0 / (PI / 2.0 + 2.0 * PI * kp) >= d { kp += 1.0; }
        while 1.0 / (3.0 * PI / 2.0 + 2.0 * PI * km) >= d { km += 1.0; }
        let (xp, xm) = (1.0 / (PI / 2.0 + 2.0 * PI * kp), 1.0 / (3.0 * PI / 2.0 + 2.0 * PI * km));
        let (yp, ym) = ((1.0 / xp).sin(), (1.0 / xm).sin());
        println!("x below {}: peak k = {} at x = {:.9}, y = {:.9}; trough k = {} at x = {:.9}, y = {:.9}", d, kp, xp, yp, km, xm, ym);
        let us: Vec<f64> = (0..10001).map(|j| 1.0 / d + j as f64 / (d * 10000.0)).collect();
        let hi = us.iter().map(|u| u.sin()).fold(f64::MIN, f64::max);
        let lo = us.iter().map(|u| u.sin()).fold(f64::MAX, f64::min);
        let damp = us.iter().map(|u| (u.sin() / u).abs()).fold(0.0, f64::max);
        println!("  scan of 10001 points, x from {} to {}: highest y {:.6}, lowest y {:.6}; damped x sin(1/x) at most {:.6}",
                 d / 2.0, d, hi, lo, damp);
        let step = 1.0 / (d * 10000.0);                                 // scan step in 1/x
        let (mut u_hi, mut u_lo) = (us[0], us[0]);                      // where the scan peaks
        for &u in &us { if u.sin() > u_hi.sin() { u_hi = u } if u.sin() < u_lo.sin() { u_lo = u } }
        let (k_hi, k_lo) = (((u_hi - PI / 2.0) / (2.0 * PI)).round(), ((u_lo - 3.0 * PI / 2.0) / (2.0 * PI)).round());
        let (gap_hi, gap_lo) = ((u_hi - PI / 2.0 - 2.0 * PI * k_hi).abs(), (u_lo - 3.0 * PI / 2.0 - 2.0 * PI * k_lo).abs());
        println!("  scan's highest point x = {:.9}: formula peak k = {}; lowest x = {:.9}: formula trough k = {}; each within one scan step: {}",
                 1.0 / u_hi, k_hi, 1.0 / u_lo, k_lo, yn(gap_hi.max(gap_lo) <= step));
        assert!(xp < d && xm < d && yp > 0.999999 && ym < -0.999999);  // formula road
        assert!(hi > 0.998 && lo < -0.998 && damp <= d);                // scan road
        assert!(gap_hi <= step && gap_lo <= step);                      // the two roads meet
    }
    for k in [1.0f64, 10.0, 100.0, 1000.0] {
        let xk = 1.0 / (PI / 6.0 + 2.0 * PI * k);
        println!("towards (0, 0.5): k = {}, x = {:.9}, y = {:.9}, distance {:.9}", k, xk, (1.0 / xk).sin(), xk);
        assert!(((1.0 / xk).sin() - 0.5).abs() < 1e-9);
    }
    println!("components of the curve: 1; path components: 2 (the graph, and the segment)");
    println!("figure, scale 400 per unit of x, 110 per unit of y; graph from (1, 0.841470985) drawn to x = 0.0125; segment (0, -1) to (0, 1); peaks x = {:.9}, {:.9}; trough x = {:.9}",
             2.0 / PI, 2.0 / (5.0 * PI), 2.0 / (3.0 * PI));
    println!("ALL CHECKS PASS");
}
