// The spectral theorem -- the same check as the Python, in Rust.  No crates.  The symmetric
// table [[2, 1], [1, 2]], two stocks that move together, is split into perpendicular axes by
// two roads: the characteristic quadratic, and repeated multiply-and-shrink.
type V = [f64; 2];
type M = [[f64; 2]; 2];
fn dot(u: V, v: V) -> f64 { u[0] * v[0] + u[1] * v[1] }
fn mv(a: M, v: V) -> V { [dot(a[0], v), dot(a[1], v)] }
fn tp(a: M) -> M { [[a[0][0], a[1][0]], [a[0][1], a[1][1]]] }
fn mul(a: M, b: M) -> M { let t = tp(b); a.map(|r| [dot(r, t[0]), dot(r, t[1])]) }
fn unit(v: V) -> V { let n = dot(v, v).sqrt(); [v[0] / n, v[1] / n] }
fn stretch(a: M, v: V) -> f64 { dot(v, mv(a, v)) / dot(v, v) }
fn f(v: V) -> String {
    let c = |x: f64| if x.abs() < 1e-12 { 0.0 } else { x };
    format!("({:.6}, {:.6})", c(v[0]), c(v[1]))
}
fn near(u: &[f64], v: &[f64]) -> bool { u.iter().zip(v).all(|(x, y)| (x - y).abs() < 1e-9) }
fn flat(m: M) -> [f64; 4] { [m[0][0], m[0][1], m[1][0], m[1][1]] }
fn roots(a: M) -> V {                                  // road one: the quadratic
    let t = a[0][0] + a[1][1];
    let g = ((a[0][0] - a[1][1]) * (a[0][0] - a[1][1]) + 4.0 * a[0][1] * a[1][0]).sqrt();
    [(t + g) / 2.0, (t - g) / 2.0]
}
fn main() {
    let a: M = [[2.0, 1.0], [1.0, 2.0]];
    let (trace, det) = (a[0][0] + a[1][1], a[0][0] * a[1][1] - a[0][1] * a[1][0]);
    let road_one = roots(a);
    let mut q1: V = [1.0, 0.25];                       // road two: multiply, shrink
    for _ in 0..40 { q1 = unit(mv(a, q1)); }
    let q2: V = [q1[1], -q1[0]];                       // a quarter turn from q1
    let (big, small) = (stretch(a, q1), stretch(a, q2));
    let (q, d) = (tp([q1, q2]), [[big, 0.0], [0.0, small]]);
    let (gram, rebuilt) = (mul(tp(q), q), mul(mul(q, d), tp(q)));
    let (x, rawq): (V, M) = ([4.0, 2.0], [[1.0, 1.0], [1.0, -1.0]]);
    let coords = mv(tp(q), x);
    let scaled = mv(d, coords);
    let bad_unit = mul(mul(tp(rawq), d), rawq);
    let bad_swap = mul(mul(q, [[small, 0.0], [0.0, big]]), tp(q));
    let slopes = [-3.0, -2.0, -1.0, -0.5, 0.0, 0.5, 1.0, 2.0, 3.0];
    let curve: Vec<f64> = slopes.iter().map(|&s| stretch(a, [1.0, s])).collect();
    let mut sweep: Vec<f64> = Vec::new();
    for k in -1000..=1000 {
        let s = k as f64 / 1000.0;
        sweep.push(stretch(a, [1.0, s]));
        sweep.push(stretch(a, [s, 1.0]));
    }
    let fm: M = [[0.8, 0.3], [0.2, 0.7]];              // second case: not symmetric
    let fleet = roots(fm);
    let (hi, lo) = (sweep.iter().cloned().fold(f64::MIN, f64::max),
                    sweep.iter().cloned().fold(f64::MAX, f64::min));
    println!("A rows {} and {}: symmetric, trace {:.6}, determinant {:.6}",
             f(a[0]), f(a[1]), trace, det);
    println!("road one, roots of L*L - 4L + 3 = 0: {:.6} and {:.6}", road_one[0], road_one[1]);
    println!("road two, 40 rounds of multiply-and-shrink from (1, 0.25): q1 = {}", f(q1));
    println!("a quarter turn from it: q2 = {}, and q1 . q2 = {:.6}", f(q2), dot(q1, q2));
    println!("A q1 = {} = {:.6} q1; A q2 = {} = {:.6} q2",
             f(mv(a, q1)), big, f(mv(a, q2)), small);
    println!("Q^T Q rows: {} and {}", f(gram[0]), f(gram[1]));
    println!("Q D Q^T rows: {} and {}", f(rebuilt[0]), f(rebuilt[1]));
    println!("mix (4, 2): coordinates {}, then stretched {}", f(coords), f(scaled));
    println!("A x straight, and through the axes: {} and {}", f(mv(a, x)), f(mv(q, scaled)));
    println!("stretch along (1, s) for s = -3, -2, -1, -0.5, 0, 0.5, 1, 2, 3:\n  {}",
             curve.iter().map(|c| format!("{:.6}", c)).collect::<Vec<String>>().join(" "));
    println!("largest and smallest stretch over {} directions: {:.6} and {:.6}",
             sweep.len(), hi, lo);
    println!("mistake, raw axes as Q: rows {} and {}", f(bad_unit[0]), f(bad_unit[1]));
    println!("mistake, 3 and 1 swapped in D alone: rows {} and {}", f(bad_swap[0]), f(bad_swap[1]));
    println!("not symmetric, F rows {} and {}: stretch factors {:.6} and {:.6}",
             f(fm[0]), f(fm[1]), fleet[0], fleet[1]);
    println!("F(3, 2) = {}, F(1, -1) = {}, and (3, 2) . (1, -1) = {:.6}",
             f(mv(fm, [3.0, 2.0])), f(mv(fm, [1.0, -1.0])), dot([3.0, 2.0], [1.0, -1.0]));
    assert!((big - 3.0).abs() < 1e-12 && (small - 1.0).abs() < 1e-12
            && near(&road_one, &[big, small]));
    assert!(near(&flat(gram), &[1.0, 0.0, 0.0, 1.0]) && near(&flat(rebuilt), &flat(a)));
    assert!(near(&mv(a, x), &[10.0, 8.0]) && near(&mv(q, scaled), &mv(a, x))
            && near(&[hi, lo], &[3.0, 1.0]));
    assert!(near(&flat(bad_unit), &[4.0, 2.0, 2.0, 4.0]) && near(&fleet, &[1.0, 0.5])
            && near(&flat(bad_swap), &[2.0, -1.0, -1.0, 2.0]));
    println!("ALL CHECKS PASS");
}
