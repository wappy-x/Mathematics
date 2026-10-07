// Line integrals of a field -- the same check as the Python, in Rust.  No
// crates; sqrt is a primitive, and every sum is written out here.  Wind pushes
// a cart with force F(x, y) = (y/10, -1) newtons at the point x m east and
// y m north of corner A.  The cart goes from A to B by four routes.
type P = (f64, f64);
type Piece = (Box<dyn Fn(f64) -> P>, Box<dyn Fn(f64) -> P>); // position, velocity

fn f(p: P) -> P { (p.1 / 10.0, -1.0) }
fn dot(u: P, v: P) -> f64 { u.0 * v.0 + u.1 * v.1 }
fn line(p: P, q: P) -> Piece { // a straight piece from p to q, clock t from 0 to 1
    (Box::new(move |t| (p.0 + (q.0 - p.0) * t, p.1 + (q.1 - p.1) * t)), Box::new(move |_| (q.0 - p.0, q.1 - p.1)))
}
fn curve() -> Piece { (Box::new(|t| (40.0 * t, 30.0 * t * t)), Box::new(|t| (40.0, 60.0 * t))) }
fn simpson(g: &dyn Fn(f64) -> f64) -> f64 { // road one: integral of F(r(t)).r'(t) dt
    let n = 100;
    let h = 1.0 / n as f64;
    let mut s = g(0.0) + g(1.0);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * g(i as f64 * h) }
    s * h / 3.0
}
fn formula(route: &[Piece]) -> f64 { route.iter().map(|(r, v)| simpson(&|t| dot(f(r(t)), v(t)))).sum() }
fn chords(route: &[Piece], n: usize) -> f64 { // road two, the definition: mid-piece force . each chord
    let mut total = 0.0;
    for (r, _) in route {
        for i in 0..n {
            let (p, q) = (r(i as f64 / n as f64), r((i + 1) as f64 / n as f64));
            total += dot(f(r((i as f64 + 0.5) / n as f64)), (q.0 - p.0, q.1 - p.1));
        }
    }
    total
}

fn main() {
    let (a, b, nw, se) = ((0.0, 0.0), (40.0, 30.0), (0.0, 30.0), (40.0, 0.0));
    let routes: Vec<(&str, Vec<Piece>, f64)> = vec![
        ("straight", vec![line(a, b)], 120.0 / 2.0 - 30.0),
        ("curve", vec![curve()], 120.0 / 3.0 - 60.0 / 2.0),
        ("east, then north", vec![line(a, se), line(se, b)], 0.0 - 30.0),
        ("north, then east", vec![line(a, nw), line(nw, b)], -30.0 + 3.0 * 40.0)];
    println!("wind force (y/10, -1) N at (x, y) m; cart from A (0, 0) to B (40, 30)");
    println!("by hand: straight length {:.0} m, direction ({:.1}, {:.1}); north leg {:.0} J; east leg at y = 30: {:.0} N x 40 m = {:.0} J",
             (40.0f64.powi(2) + 30.0f64.powi(2)).sqrt(), 40.0 / 50.0, 30.0 / 50.0, -1.0 * 30.0, f((0.0, 30.0)).0, f((0.0, 30.0)).0 * 40.0);
    for (name, route, hand) in &routes {
        println!("{}: formula {:.6} J, by hand {:.6} J, 1024 chords {:.6} J", name, formula(route), hand, chords(route, 1024));
    }
    for n in [4, 16, 32, 64] {
        let c = chords(&[curve()], n);
        println!("curve, {:2} chords: {:.6} J, short by {:.6} J", n, c, 10.0 - c);
    }
    let pace = formula(&[(Box::new(|s: f64| (40.0 * s * s, 30.0 * s * s)), Box::new(|s: f64| (80.0 * s, 60.0 * s)))]);
    let back = formula(&[line(b, a)]);
    let lp = formula(&routes[3].1) + formula(&[line(b, se), line(se, a)]);
    println!("straight, slow start (40s^2, 30s^2): {:.6} J; straight, B to A: {:.6} J", pace, back);
    println!("loop, north-then-east out, hedge route back: {:.6} J; 0.1 N/m x 40 m x 30 m = {:.6}", lp, 0.1 * 40.0 * 30.0);
    let rb = line(b, a).0;
    println!("mistake 1, B to A with the A-to-B velocity: {:.3} J, not -30", simpson(&|t| dot(f(rb(t)), (40.0, 30.0))));
    println!("mistake 2, speed factor dropped: {:.3} J, not 30", simpson(&|t| dot(f((40.0 * t, 30.0 * t)), (0.8, 0.6))));
    println!("mistake 3, strength |F| times length: {:.3} N m, not 30 J", simpson(&|t| 50.0 * ((3.0 * t).powi(2) + 1.0).sqrt()));
    println!("mistake 4, same ends so same work: straight 30 J copied to north-then-east, truly {:.0} J", routes[3].2);
    let (sx, sy) = (|x: f64| 50.0 + 6.0 * x, |y: f64| 210.0 - 6.0 * y);
    let pts: Vec<String> = (0..9).map(|t| t as f64 / 8.0)
        .map(|t| format!("({:.1},{:.1})", sx(40.0 * t), sy(30.0 * t * t))).collect();
    println!("figure, 6 units per m, curve: {}", pts.join(" "));
    let arr: Vec<String> = [(6.0, 12.0), (6.0, 24.0), (16.0, 26.0), (26.0, 26.0), (34.0, 4.0), (34.0, 12.0)].iter()
        .map(|&(x, y): &(f64, f64)| format!("({:.0},{:.0})->({:.1},{:.0})", sx(x), sy(y), sx(x + y / 10.0), sy(y - 1.0))).collect();
    println!("figure, arrows 6 units per N, tail->head: {}", arr.join(" "));
    for (_, route, hand) in &routes {
        assert!((formula(route) - hand).abs() < 1e-9); // road one against the hand
        assert!((chords(route, 1024) - hand).abs() < 1e-4); // road two, the definition
    }
    assert!((pace - 30.0).abs() < 1e-9 && (back + 30.0).abs() < 1e-9 && (chords(&[line(b, a)], 1024) + 30.0).abs() < 1e-9); // new clock: same; reversed: negated, both roads
    assert!((lp - 0.1 * 40.0 * 30.0).abs() < 1e-9); // the loop against wind gain x area
    println!("ALL CHECKS PASS");
}
