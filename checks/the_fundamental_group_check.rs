// The fundamental group -- the same check as the Python, in Rust.  No crates.
// A lamp post stands at (0, 0) on a pavement of 1 m slabs, and the owner
// stands at X0 = (2, 0).  A walk is the list of slab corners the dog visits,
// 1 m apart, from X0 back to X0: a loop.  Joining is one, then the other.
type P = (i64, i64);
const X0: P = (2, 0);

fn walk(moves: &str) -> Vec<P> {                  // "N2 W4" -> the corners visited
    let mut pts = vec![X0];
    for m in moves.split_whitespace() {
        let (dx, dy) = match &m[..1] { "N" => (0, 1), "S" => (0, -1), "E" => (1, 0), _ => (-1, 0) };
        for _ in 0..m[1..].parse::<i64>().unwrap() {
            let l = pts[pts.len() - 1];
            pts.push((l.0 + dx, l.1 + dy));
        }
    }
    pts
}
fn join(a: &[P], b: &[P]) -> Vec<P> { let mut v = a.to_vec(); v.extend_from_slice(&b[1..]); v }
fn rev(a: &[P]) -> Vec<P> { a.iter().rev().copied().collect() }
fn wind_ray(p: &[P]) -> i64 {                     // road 1: signed crossings of the ray east
    let mut n = 0;
    for w in p.windows(2) {
        let ((x0, y0), (x1, y1)) = (w[0], w[1]);
        let c = x0 * y1 - x1 * y0;                // c > 0: the post is on the walker's left
        if y0 <= 0 && 0 < y1 && c > 0 { n += 1 }
        if y1 <= 0 && 0 < y0 && c < 0 { n -= 1 }
    }
    n
}
fn quad(x: i64, y: i64) -> i64 { if x > 0 && y >= 0 { 0 } else if y > 0 { 1 } else if x < 0 { 2 } else { 3 } }
fn wind_quad(p: &[P]) -> i64 {                    // road 2: count quarter turns, no ray at all
    let mut total = 0;
    for w in p.windows(2) {
        let d = (quad(w[1].0, w[1].1) - quad(w[0].0, w[0].1)).rem_euclid(4);
        assert!(d != 2, "one step swept half the compass");
        total += [0, 1, 0, -1][d as usize];
    }
    assert!(total % 4 == 0);
    total / 4
}
fn laps(p: &[P]) -> i64 {                         // the same crossings, sign ignored
    p.windows(2).filter(|w| { let ((x0, y0), (x1, y1)) = (w[0], w[1]);
        (y0 <= 0 && 0 < y1 && x0 * y1 > x1 * y0) || (y1 <= 0 && 0 < y0 && x0 * y1 < x1 * y0) }).count() as i64
}
fn cancel(p: &[P]) -> (Vec<P>, i64) {             // pull in every there-and-back spur
    let (mut st, mut k): (Vec<P>, i64) = (Vec::new(), 0);
    for &v in p {
        if st.len() >= 2 && st[st.len() - 2] == v { st.pop(); k += 1 } else { st.push(v) }
    }
    (st, k)
}
fn gcd(a: i64, b: i64) -> i64 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
#[derive(Clone, Copy, PartialEq)]
struct Q(i64, i64);                               // an exact fraction n/d, d > 0
fn q(n: i64, d: i64) -> Q { let g = gcd(n, d).max(1); Q(n / g, d / g) }
fn show(a: Q) -> String { if a.1 == 1 { format!("{}", a.0) } else { format!("{}/{}", a.0, a.1) } }
fn pt(v: (Q, Q)) -> String { format!("({}, {})", show(v.0), show(v.1)) }
type T = Box<dyn Fn(Q) -> (Q, Q)>;
fn timed(p: Vec<P>) -> T {                        // the walk as a function of time s in [0, 1]
    Box::new(move |s: Q| {
        let len = (p.len() - 1) as i64;
        let (i, r) = ((s.0 * len).div_euclid(s.1), (s.0 * len).rem_euclid(s.1));
        let (a, b) = (p[i as usize], p[((i + 1) as usize).min(p.len() - 1)]);
        (q(a.0 * s.1 + r * (b.0 - a.0), s.1), q(a.1 * s.1 + r * (b.1 - a.1), s.1))
    })
}
fn dot(f: T, g: T) -> T {                         // the card's product: f at double speed, then g
    Box::new(move |s: Q| if 2 * s.0 <= s.1 { f(q(2 * s.0, s.1)) } else { g(q(2 * s.0 - s.1, s.1)) })
}
fn sq(v: P) -> P { (v.0 * v.0 - v.1 * v.1, 2 * v.0 * v.1) }   // doubles every bearing
fn mirror(v: P) -> P { (v.0, -v.1) }                          // swaps north and south
fn carry(f: fn(P) -> P, p: &[P]) -> Vec<P> { p.iter().map(|&v| f(v)).collect() }
fn yn(c: bool) -> &'static str { if c { "yes" } else { "no" } }
fn s2(v: P) -> String { format!("({}, {})", v.0, v.1) }

fn main() {
    let a = walk("N2 W4 S4 E4 N2");               // once round the post, anticlockwise
    let b = rev(&a);                              // once round, clockwise
    let c = walk("E1 N1 W1 S1");                  // round a bin beside the owner
    let d = walk("E1 N3 W6 S6 E6 N3 W1");         // a wider lap round the post
    let loops: Vec<(&str, Vec<P>)> = vec![("stand", vec![X0]), ("a", a.clone()), ("a-bar", b.clone()), ("bin", c.clone()), ("wide", d.clone())];
    for (name, p) in &loops {
        println!("loop {:<6} {:>2} m   winding by the ray {:>2}, by quarter turns {:>2}", name, p.len() - 1, wind_ray(p), wind_quad(p));
    }
    println!("figure,post (0, 0); owner {}; a turns at {} {} {} {}; wide turns at {} {} {} {}; bin {} {} {}",
             s2(X0), s2(a[2]), s2(a[6]), s2(a[10]), s2(a[14]), s2(d[4]), s2(d[10]), s2(d[16]), s2(d[22]), s2(c[1]), s2(c[2]), s2(c[3]));
    let mut pairs: Vec<(Vec<P>, Vec<P>)> = Vec::new();
    for (_, x) in &loops { for (_, y) in &loops { pairs.push((x.clone(), y.clone())) } }
    let adds = pairs.iter().all(|(x, y)| { let j = join(x, y); wind_ray(&j) == wind_ray(x) + wind_ray(y) && wind_ray(&j) == wind_quad(&j) });
    println!("windings add when two loops are joined: {}, checked on {} pairs", yn(adds), pairs.len());
    println!("joined   length  winding  spurs pulled in  left after pulling");
    let aaa = join(&a, &join(&a, &a));
    for (name, p) in [("a.a", join(&a, &a)), ("a.a-bar", join(&a, &b)), ("a-bar.a", join(&b, &a)), ("a.bin", join(&a, &c)), ("a.a.a", aaa)] {
        let (red, k) = cancel(&p);
        println!("{:<8} {:>4} m {:>8} {:>16} {:>14} m", name, p.len() - 1, wind_ray(&p), k, red.len() - 1);
    }
    let left = dot(dot(timed(a.clone()), timed(a.clone())), timed(a.clone()));
    let right = dot(timed(a.clone()), dot(timed(a.clone()), timed(a.clone())));
    let stand_a = dot(timed(vec![X0]), timed(a.clone()));
    let quarter = q(1, 4);
    println!("(a.a).a gives the three laps times 1/4, 1/4, 1/2; a.(a.a) gives 1/2, 1/4, 1/4");
    println!("at time 1/4: (a.a).a is at {}, a.(a.a) at {}", pt(left(quarter)), pt(right(quarter)));
    println!("at time 1/4: stand.a is at {}, a alone at {}", pt(stand_a(quarter)), pt(timed(a.clone())(quarter)));
    // the straight squeeze at t = k/4, every corner scaled by 4: winding ignores the scale
    let squeeze = |k: i64| -> Vec<P> { a.iter().map(|&(x, y)| ((4 - k) * x + 2 * k, (4 - k) * y)).collect() };
    let on_post = squeeze(2).contains(&(0, 0));
    println!("squeeze a straight toward the owner: winding {} at t = 1/4, {} at t = 3/4; a corner on the post at t = 1/2: {}",
             wind_ray(&squeeze(1)), wind_ray(&squeeze(3)), yn(on_post));
    println!("a.a-bar: unsigned laps {}, signed winding {}", laps(&join(&a, &b)), wind_ray(&join(&a, &b)));
    println!("basepoint after each map: mirror {}, squaring {}", s2(mirror(X0)), s2(sq(X0)));
    println!("squaring a.a gives winding {}; squaring each a, then joining, gives {}",
             wind_quad(&carry(sq, &join(&a, &a))), wind_quad(&join(&carry(sq, &a), &carry(sq, &a))));
    println!("loop      n   mirror  squaring  squaring after mirror");
    for (name, p) in &loops {
        println!("{:<6} {:>4} {:>8} {:>9} {:>22}", name, wind_quad(p), wind_quad(&carry(mirror, p)),
                 wind_quad(&carry(sq, p)), wind_quad(&carry(sq, &carry(mirror, p))));
    }
    assert!(loops.iter().map(|(_, p)| wind_ray(p)).collect::<Vec<i64>>() == vec![0, 1, -1, 0, 1]);
    assert!(loops.iter().all(|(_, p)| wind_ray(p) == wind_quad(p)) && adds);
    assert!(laps(&join(&a, &b)) == 2 && cancel(&join(&a, &b)) == (vec![X0], 16) && cancel(&join(&a, &a)).1 == 0);
    assert!(left(quarter) == (q(2, 1), q(0, 1)) && right(quarter) == (q(-2, 1), q(0, 1)));
    assert!(wind_ray(&squeeze(1)) == 1 && wind_ray(&squeeze(3)) == 0 && on_post);
    assert!(wind_quad(&carry(sq, &join(&a, &a))) == 2 * wind_ray(&join(&a, &a)) && 2 * wind_ray(&join(&a, &a)) == 4); // squaring a.a: 2 x 2
    assert!(loops.iter().all(|(_, p)| wind_quad(&carry(sq, p)) == 2 * wind_ray(p) && wind_quad(&carry(mirror, p)) == -wind_ray(p)
            && wind_quad(&carry(sq, &carry(mirror, p))) == -2 * wind_ray(p)));
    println!("ALL CHECKS PASS");
}
