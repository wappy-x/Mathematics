// Rigid motions in space and screws -- the same check as the Python, in Rust, std only.
// The drone's move: turn 90 degrees about the vertical through (0, 0, 0), then shift (1, 0, 2).
// Road one: axis and screw by formula.  Two: grid search for the least move.  Three: four mirrors.
type V = [f64; 3];  type M = [[f64; 3]; 3];
fn dot(a: V, b: V) -> f64 { a[0] * b[0] + a[1] * b[1] + a[2] * b[2] }
fn add(a: V, b: V, k: f64) -> V { [a[0] + k * b[0], a[1] + k * b[1], a[2] + k * b[2]] }
fn cross(a: V, b: V) -> V { [a[1]*b[2] - a[2]*b[1], a[2]*b[0] - a[0]*b[2], a[0]*b[1] - a[1]*b[0]] }
fn mv(r: &M, t: V, x: V) -> V { add([dot(r[0], x), dot(r[1], x), dot(r[2], x)], t, 1.0) }
fn unit(v: V) -> V { let n = dot(v, v).sqrt(); [v[0] / n, v[1] / n, v[2] / n] }
fn gap(a: V, b: V) -> f64 { let d = add(a, b, -1.0); dot(d, d).sqrt() }
fn f(v: V, n: usize) -> String {
    let s: Vec<String> = v.iter().map(|&x| format!("{:.*}", n, if x.abs() >= 5e-7 { x } else { 0.0 })).collect();
    format!("({})", s.join(", "))
}
fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }
fn trace(r: &M) -> f64 { r[0][0] + r[1][1] + r[2][2] }
fn screw(r: &M, t: V) -> (V, f64, f64, V, V) {   // road one: axis u, angle, slide s, axis point c
    let w = [r[2][1] - r[1][2], r[0][2] - r[2][0], r[1][0] - r[0][1]];   // = 2 sin(angle) u
    let u = unit(w);
    let th = (dot(w, w).sqrt() / 2.0).atan2((trace(r) - 1.0) / 2.0);
    let s = dot(t, u);
    let tp = add(t, u, -s);                      // the sideways part of the shift
    let k = cross(u, tp);
    let c = [0, 1, 2].map(|i| (tp[i] + k[i] / (th / 2.0).tan()) / 2.0);
    (u, th, s, tp, c)
}
fn axis_two(r: &M) -> (V, f64, f64) {             // second road: cross two rows of R - I, turn a side arrow
    let m: M = [0, 1, 2].map(|i| [0, 1, 2].map(|j| r[i][j] - if i == j { 1.0 } else { 0.0 }));
    let u = unit([cross(m[0], m[1]), cross(m[1], m[2]), cross(m[2], m[0])].into_iter().max_by(|a, b| dot(*a, *a).total_cmp(&dot(*b, *b))).unwrap());
    let v = cross(u, if u[0].abs() > 0.9 { [0.0, 1.0, 0.0] } else { [1.0, 0.0, 0.0] });
    let rv = mv(r, [0.0; 3], v);
    (u, dot(u, cross(v, rv)).atan2(dot(v, rv)), dot(m[0], cross(m[1], m[2])))
}
fn rebuilt(u: V, th: f64, s: f64, c: V, x: V) -> V {   // turn about the line through c, then slide s along u
    let v = add(x, c, -1.0);
    let k = cross(u, v);
    let r = add([0, 1, 2].map(|i| v[i] * th.cos() + k[i] * th.sin()), u, dot(u, v) * (1.0 - th.cos()));
    add(add(c, r, 1.0), u, s)
}
fn mirror(n: V, k: f64, x: V) -> V { add(x, n, -2.0 * (dot(n, x) - k) / dot(n, n)) }   // plane n.x = k
fn main() {
    let r: M = [[0.0, -1.0, 0.0], [1.0, 0.0, 0.0], [0.0, 0.0, 1.0]];
    let rc: M = [[0.0, 0.0, 1.0], [1.0, 0.0, 0.0], [0.0, 1.0, 0.0]];
    let (t, p): (V, V) = ([1.0, 0.0, 2.0], [2.0, 3.0, 5.0]);
    let mut tests: Vec<V> = vec![p, [0.0; 3], [10.0, 0.0, 0.0], [10.0, 4.8, 3.6], [0.0, 4.8, 3.6]];   // drone, panel corners
    for (name, q) in [("drone turn", &r), ("camera mount x->y->z->x", &rc)] {
        let (u, th, s, tp, c) = screw(q, t);
        let (u2, th2, d) = axis_two(q);
        let err = tests.iter().map(|&x| gap(rebuilt(u, th, s, c, x), mv(q, t, x))).fold(0.0, f64::max);
        println!("{}: det(R - I) = {:.6}, trace {:.0}", name, d, trace(q));
        println!("  axis {} from the lopsided entries, {} from rows of R - I", f(u, 6), f(u2, 6));
        println!("  angle {:.6} from the trace, {:.6} by turning a side arrow", th.to_degrees(), th2.to_degrees());
        println!("  slide {:.6}, sideways shift {}, axis point {}, screw rebuilt matches: {}", s, f(tp, 6), f(c, 6), yn(err < 1e-9));
        assert!(d.abs() < 1e-12 && gap(u, u2) < 1e-12 && (th - th2).abs() < 1e-12 && err < 1e-9);
    }
    let (u, th, s, _tp, c) = screw(&r, t);
    let mut best = (f64::INFINITY, 0, 0);            // road two
    for i in -300..=300 { for j in -300..=300 {
        let x = [i as f64 / 100.0, j as f64 / 100.0, 0.0];  let g = gap(mv(&r, t, x), x);
        if g < best.0 { best = (g, i, j) }
    } }
    println!("drone {} -> {}, moved {:.6} m; grid search: least move {:.6} at ({:.2}, {:.2})", f(p, 0), f(mv(&r, t, p), 0), gap(p, mv(&r, t, p)), best.0, best.1 as f64 / 100.0, best.2 as f64 / 100.0);
    let four: Vec<V> = tests.iter().map(|&x| mv(&r, t, x)).collect();
    for (n, k) in [([0.0, 0.0, 1.0], 0.0), ([0.0, 0.0, 1.0], 1.0), ([0.0, 1.0, 0.0], 0.5), ([-1.0, 1.0, 0.0], 0.0)] {
        tests = tests.iter().map(|&x| mirror(n, k, x)).collect();   // road three
    }
    let worst = tests.iter().zip(&four).map(|(&a, &b)| gap(a, b)).fold(0.0, f64::max);
    println!("four mirrors z = 0, z = 1, y = 0.5, y = x send the drone to {}, all five points match: {}", f(tests[0], 0), yn(worst < 1e-12));
    let w = rebuilt(u, th, s, [0.0; 3], p);
    println!("mistake, axis through (0, 0, 0): drone -> {}, {:.6} m from the truth", f(w, 0), gap(w, mv(&r, t, p)));
    println!("mistake, whole shift as the slide: {:.6} m, not {:.6} m", dot(t, t).sqrt(), s);
    println!("mistake, shift before the turn: axis point {}", f(screw(&r, mv(&r, [0.0; 3], t)).4, 1));
    let pp = |v: V| format!("({:.2}, {:.2})", 200.0 + 50.0 * v[0], 220.0 - 50.0 * v[1]);
    let rad = 50.0 * gap([p[0], p[1], 0.0], [c[0], c[1], 0.0]);
    println!("figure, 1 m = 50 units, axis {} start {} end {} radius {:.2}", pp(c), pp(p), pp(mv(&r, t, p)), rad);
    assert!((best.0 - s.abs()).abs() < 1e-12 && gap([best.1 as f64 / 100.0, best.2 as f64 / 100.0, 0.0], [c[0], c[1], 0.0]) < 1e-9);
    assert!(gap(c, [0.5, 0.5, 0.0]) < 1e-12 && (s - 2.0).abs() < 1e-12);   // the hand solution
    assert!(worst < 1e-12);                                                // road three
    println!("ALL CHECKS PASS");
}
