// Continuity and homeomorphism -- the same check as the Python file, in Rust, std only.
// Three maps: the wrap w(t) = (cos t, sin t) from [0, 2pi) onto the circle; the
// radial maps s (circle to square, pasted from two pieces) and r (square to
// circle); and the stretch h(x) = x / (1 - |x|) from (-1, 1) onto the line.
use std::collections::BTreeSet;
use std::f64::consts::PI;

// Exact fractions: numerator, denominator > 0, in lowest terms.
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
struct Q(i128, i128);
impl Ord for Q { fn cmp(&self, o: &Q) -> std::cmp::Ordering { (self.0 * o.1).cmp(&(o.0 * self.1)) } }
impl PartialOrd for Q { fn partial_cmp(&self, o: &Q) -> Option<std::cmp::Ordering> { Some(self.cmp(o)) } }
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i128, d: i128) -> Q { let g = gcd(n, d) * d.signum(); Q(n / g, d / g) }
fn add(a: Q, b: Q) -> Q { q(a.0 * b.1 + b.0 * a.1, a.1 * b.1) }
fn sub(a: Q, b: Q) -> Q { q(a.0 * b.1 - b.0 * a.1, a.1 * b.1) }
fn mul(a: Q, b: Q) -> Q { q(a.0 * b.0, a.1 * b.1) }
fn div(a: Q, b: Q) -> Q { q(a.0 * b.1, a.1 * b.0) }
fn qabs(a: Q) -> Q { Q(a.0.abs(), a.1) }
fn neg(a: Q) -> Q { Q(-a.0, a.1) }
fn show(a: Q) -> String { if a.1 == 1 { format!("{}", a.0) } else { format!("{}/{}", a.0, a.1) } }
fn fmt(p: (Q, Q)) -> String { format!("({}, {})", show(p.0), show(p.1)) }
fn isqrt(n: i128) -> i128 { let mut a = (n as f64).sqrt() as i128; while a * a > n { a -= 1; } while (a + 1) * (a + 1) <= n { a += 1; } a }
fn fsqrt(x: Q) -> Q { let (a, b) = (isqrt(x.0), isqrt(x.1)); assert!(a * a == x.0 && b * b == x.1); q(a, b) }
const ONE: Q = Q(1, 1);
// s is pasted: p/|x| where |x| >= |y|, p/|y| where |y| >= |x|.
fn s(p: (Q, Q)) -> (Q, Q) { let m = if qabs(p.0) >= qabs(p.1) { qabs(p.0) } else { qabs(p.1) }; (div(p.0, m), div(p.1, m)) }
fn r(p: (Q, Q)) -> (Q, Q) { let n = fsqrt(add(mul(p.0, p.0), mul(p.1, p.1))); (div(p.0, n), div(p.1, n)) }
fn sf(p: (f64, f64)) -> (f64, f64) { let m = if p.0.abs() >= p.1.abs() { p.0.abs() } else { p.1.abs() }; (p.0 / m, p.1 / m) }
fn rf(p: (f64, f64)) -> (f64, f64) { let n = (p.0 * p.0 + p.1 * p.1).sqrt(); (p.0 / n, p.1 / n) }
fn h(x: Q) -> Q { if x.0 >= 0 { div(x, sub(ONE, x)) } else { div(x, add(ONE, x)) } }
fn hinv(y: Q) -> Q { div(y, add(ONE, qabs(y))) }
fn yes(b: bool) -> &'static str { if b { "yes" } else { "NO" } }
fn pieces(adj: &Vec<Vec<usize>>, gone: usize) -> usize {
    let mut seen = vec![false; adj.len()];
    let mut count = 0;
    for v in 0..adj.len() {
        if v == gone || seen[v] { continue; }
        count += 1; seen[v] = true; let mut stack = vec![v];
        while let Some(u) = stack.pop() {
            for &w in &adj[u] { if w != gone && !seen[w] { seen[w] = true; stack.push(w); } }
        }
    }
    count
}

fn main() {
    // 1. The wrap.  Pre-image of the open arc of angles (-30, 30) degrees, two roads.
    let n = 7200;
    let ts: Vec<f64> = (0..n).map(|k| 2.0 * PI * (k as f64 + 0.5) / n as f64).collect();
    let scan: Vec<f64> = ts.iter().cloned().filter(|t| t.sin().atan2(t.cos()).abs() < PI / 6.0).collect();
    let formula: Vec<f64> = ts.iter().cloned().filter(|&t| t < PI / 6.0 || t > 11.0 * PI / 6.0).collect();
    println!("pre-image of the arc (-30, 30) degrees under w: [0, {:.6}) and ({:.6}, {:.6})", PI / 6.0, 11.0 * PI / 6.0, 2.0 * PI);
    println!("  scan of {} points of [0, 2pi): {} inside, formula agrees: {}", n, scan.len(), yes(scan == formula));
    let mut tears = vec![];
    for k in [10.0f64, 100.0, 1000.0] {
        let p = ((-1.0 / k).cos(), (-1.0 / k).sin());
        let gap = ((p.0 - 1.0).powi(2) + p.1.powi(2)).sqrt();
        let wi = p.1.atan2(p.0).rem_euclid(2.0 * PI);
        tears.push((wi, k));
        println!("angle -1/{}: {:.6} from (1, 0), w-inverse {:.6} against 0 at (1, 0)", k, gap, wi);
    }

    // 2. Circle and square.
    let mut pts = BTreeSet::new();
    for b in 1..13i128 {
        for a in 0..=b {
            let t = q(a, b); let tt = mul(t, t);
            let (x, y) = (div(sub(ONE, tt), add(ONE, tt)), div(mul(q(2, 1), t), add(ONE, tt)));
            for (u, v) in [(x, y), (y, x)] { for p in [(u, v), (neg(u), v), (u, neg(v)), (neg(u), neg(v))] { pts.insert(p); } }
        }
    }
    let on_circle = pts.iter().all(|&(x, y)| add(mul(x, x), mul(y, y)) == ONE);
    let on_square = pts.iter().all(|&p| { let t = s(p); std::cmp::max(qabs(t.0), qabs(t.1)) == ONE });
    let back = pts.iter().all(|&p| r(s(p)) == p);
    for p in [(q(4, 5), q(3, 5)), (q(3, 5), q(4, 5))] {
        println!("s{} = {}, r{} = {}", fmt(p), fmt(s(p)), fmt(s(p)), fmt(r(s(p))));
    }
    println!("{} rational points of the circle: all land on the square {}, r(s(p)) = p exactly {}", pts.len(), yes(on_square), yes(back));
    let circ: Vec<(f64, f64)> = (0..3600).map(|k| { let a = 2.0 * PI * k as f64 / 3600.0; (a.cos(), a.sin()) }).collect();
    let d = |a: (f64, f64), b: (f64, f64)| (a.0 - b.0).abs().max((a.1 - b.1).abs());
    let err1 = circ.iter().map(|&p| d(rf(sf(p)), p)).fold(0.0, f64::max);
    let sq: Vec<(f64, f64)> = circ.iter().map(|&p| sf(p)).collect();
    let err2 = sq.iter().map(|&p| d(sf(rf(p)), p)).fold(0.0, f64::max);
    let step = (0..3600).map(|k| d(sq[k], sq[(k + 3599) % 3600])).fold(0.0, f64::max);
    println!("3600 points 0.1 degree apart: r(s(p)) = p and s(r(q)) = q to 1e-12: {}", yes(err1.max(err2) < 1e-12));
    println!("  neighbours {:.6} apart land at most {:.6} apart", 2.0 * (PI / 3600.0).sin(), step);
    let seam = [1.0, 3.0, 5.0, 7.0].iter().map(|a: &f64| { let t = a * PI / 4.0; (t.cos().abs() - t.sin().abs()).abs() }).fold(0.0, f64::max);
    println!("overlap |x| = |y|: the two pieces of s agree to 1e-12 at all 4 points: {}", yes(seam < 1e-12));
    let bad = (q(20, 29), q(21, 29));
    println!("wrong: p/|x| on the whole circle sends {} to {}, off the square", fmt(bad), fmt((div(bad.0, bad.0), div(bad.1, bad.0))));

    // 3. The stretch h: (-1, 1) onto the line, pasted from x/(1 - x) and x/(1 + x).
    let mut xs = BTreeSet::new();
    for b in 1..41i128 { for a in (-b + 1)..b { xs.insert(q(a, b)); } }
    println!("h(1/2) = {}, h(9/10) = {}, h(99/100) = {}, h-inverse(99) = {}", show(h(q(1, 2))), show(h(q(9, 10))), show(h(q(99, 100))), show(hinv(q(99, 1))));
    let round_h = xs.iter().all(|&x| hinv(h(x)) == x) && (-500..501i128).all(|y| h(hinv(q(y, 1))) == q(y, 1));
    println!("{} fractions in (-1, 1) and 1001 whole numbers: round trips exact {}", xs.len(), yes(round_h));

    // 4. Pieces left after removing one point, on graph models (an illustration).
    let m = 12;
    let cyc: Vec<Vec<usize>> = (0..m).map(|i| vec![(i + m - 1) % m, (i + 1) % m]).collect();
    let path: Vec<Vec<usize>> = (0..m).map(|i| { let mut v = vec![]; if i > 0 { v.push(i - 1); } if i + 1 < m { v.push(i + 1); } v }).collect();
    let tor: Vec<Vec<usize>> = (0..36).map(|k| { let (i, j) = (k / 6, k % 6);
        vec![((i + 1) % 6) * 6 + j, ((i + 5) % 6) * 6 + j, i * 6 + (j + 1) % 6, i * 6 + (j + 5) % 6] }).collect();
    let mut cuts = vec![];
    for (name, g) in [("circle", &cyc), ("interval", &path), ("torus", &tor)] {
        let mut c: Vec<usize> = (0..g.len()).map(|v| pieces(g, v)).collect();
        c.sort();
        let kinds: BTreeSet<usize> = c.iter().cloned().collect();
        let parts: Vec<String> = kinds.iter().map(|k| format!("{} times {}", c.iter().filter(|x| *x == k).count(), k)).collect();
        println!("{} model, {} points: remove one, pieces {}", name, c.len(), parts.join(", "));
        cuts.push(c);
    }

    // 5. Gluing that fails: 0 on [0, 1) and 1 on [1, 2]; the right piece is closed, the left is not.
    let step_f = |x: Q| if x < ONE { 0 } else { 1 };
    let jumps = (1..1001i128).map(|k| step_f(sub(ONE, q(1, k)))).max().unwrap();
    let grid: Vec<Q> = (0..2001i128).map(|i| q(i, 1000)).collect();
    let pre_step: Vec<Q> = grid.iter().cloned().filter(|&x| { let v = q(step_f(x), 1); q(1, 2) < v && v < q(3, 2) }).collect();
    println!("wrong: 0 on [0, 1), 1 on [1, 2]: f(1) = {}, f(1 - 1/k) = {} for k = 1..1000", step_f(ONE), jumps);
    println!("  pre-image of (1/2, 3/2): {} of {} grid points, from {} to {}: [1, 2], not open",
             pre_step.len(), grid.len(), show(pre_step[0]), show(*pre_step.last().unwrap()));
    let (lpiece, rpiece) = (|x: i64| x, |x: i64| x + 1);
    println!("wrong: x on [0, 1], x + 1 on [1, 2]: at 1 the pieces give {} and {}", lpiece(1), rpiece(1));
    let px = |p: (Q, Q)| format!("({}, {})", 210.0 + 150.0 * p.0 .0 as f64 / p.0 .1 as f64, 210.0 - 150.0 * p.1 .0 as f64 / p.1 .1 as f64);
    let mut fig = vec![];
    for p in [(q(4, 5), q(3, 5)), (q(3, 5), q(4, 5))] { for t in [p, s(p)] { fig.push(format!("{} at {}", fmt(t), px(t))); } }
    println!("figure, 150 units a step, centre (210, 210): {}", fig.join(", "));

    // 6. The mug's cup, 8 cm across and 9 cm deep, flattened onto a disc: a cup point is (radius, depth) in cm.
    let four = q(4, 1);
    let wall = |d: Q| sub(four, mul(q(2, 9), d));              // inside wall at depth d -> radius on the disc
    let floor = |rho: Q| div(rho, q(2, 1));                     // floor at radius rho -> radius on the disc
    let flat = |p: (Q, Q)| if p.0 == four { wall(p.1) } else { floor(p.0) };
    let unflat = |x: Q| if x >= q(2, 1) { (four, mul(sub(four, x), q(9, 2))) } else { (mul(q(2, 1), x), q(9, 1)) };
    let mut cup = BTreeSet::new();
    for k in 0..91i128 { cup.insert((four, q(k, 10))); }
    for k in 0..41i128 { cup.insert((q(k, 10), q(9, 1))); }
    let disc: Vec<Q> = (0..401i128).map(|k| q(k, 100)).collect();
    let cup_back = cup.iter().all(|&p| unflat(flat(p)) == p) && disc.iter().all(|&x| flat(unflat(x)) == x);
    println!("mug: cup 8 cm across, 9 cm deep; on the disc, wall depth d goes to radius 4 - (2/9) d, floor radius to half");
    println!("  wall depth 9/2 goes to radius {}, wall foot to {}, floor edge to {}", show(wall(q(9, 2))), show(wall(q(9, 1))), show(floor(four)));
    println!("  {} points of wall and floor, {} radii of the disc: round trips exact {}", cup.len(), disc.len(), yes(cup_back));

    assert!(scan == formula && scan.len() == n / 6);
    assert!(tears.iter().all(|&(t, k)| (t - (2.0 * PI - 1.0 / k)).abs() < 1e-12 && t > 6.0));
    assert!(on_circle && on_square && back && pts.len() == 252);
    assert!(err1 < 1e-12 && err2 < 1e-12 && seam < 1e-12 && step < 2.01 * 2.0 * (PI / 3600.0).sin());
    assert!(round_h && h(q(99, 100)) == q(99, 1) && hinv(q(99, 1)) == q(99, 100));
    assert!(cuts[0] == vec![1; 12] && cuts[1] == [vec![1, 1], vec![2; 10]].concat());
    assert!(cuts[2] == vec![1; 36] && jumps == 0);
    assert!(pre_step[0] == ONE && *pre_step.last().unwrap() == q(2, 1) && pre_step.len() == 1001);
    assert!(cup_back && wall(q(9, 1)) == floor(four) && cup.len() == 131);   // pieces agree at the seam
    println!("ALL CHECKS PASS");
}
