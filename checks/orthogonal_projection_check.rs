// Projection -- the same check as the Python, in Rust.  No crates.  A rower pulls
// with force (6, 2) while the boat points along (1, 1).  Road one is the formula.
// Road two never touches it: it fits the parabola through three squared distances
// from the pull to the line and takes that parabola's lowest point.  The plane
// case is done twice too, from two perpendicular pairs inside the same plane.
fn dot(a: &[f64], b: &[f64]) -> f64 { a.iter().zip(b).map(|(x, y)| x * y).sum() }
fn scale(t: f64, a: &[f64]) -> Vec<f64> { a.iter().map(|x| t * x).collect() }
fn sub(a: &[f64], b: &[f64]) -> Vec<f64> { a.iter().zip(b).map(|(x, y)| x - y).collect() }
fn add(a: &[f64], b: &[f64]) -> Vec<f64> { a.iter().zip(b).map(|(x, y)| x + y).collect() }
fn n(x: f64) -> String {
    let s = format!("{:.4}", x);
    s.trim_end_matches('0').trim_end_matches('.').to_string()
}
fn show(a: &[f64]) -> String {
    let parts: Vec<String> = a.iter().map(|x| n(*x)).collect();
    format!("({})", parts.join(", "))
}
fn one(name: &str, value: String) { println!("{:<44}{}", name, value); }
fn project(u: &[f64], v: &[f64]) -> Vec<f64> { scale(dot(u, v) / dot(v, v), v) }   // road one
fn main() {
    let (u, v) = (vec![6.0, 2.0], vec![1.0, 1.0]);   // the pull, and the boat's heading
    let p = project(&u, &v);                         // the shadow
    let e = sub(&u, &p);                             // the leftover
    one("the pull u and the boat's heading v", format!("{} and {}", show(&u), show(&v)));
    one("u . v and v . v", format!("{} and {}", n(dot(&u, &v)), n(dot(&v, &v))));
    one("t = (u . v) / (v . v)", n(dot(&u, &v) / dot(&v, &v)));
    one("the shadow p = t v", show(&p));
    one("the leftover e = u - p", show(&e));
    one("e . v and e . p", format!("{} and {}", n(dot(&e, &v)), n(dot(&e, &p))));
    one("lengths of u, p, e: squared, then actual",
        format!("{}, {}, {} then {}, {}, {}", n(dot(&u, &u)), n(dot(&p, &p)), n(dot(&e, &e)),
                n(dot(&u, &u).sqrt()), n(dot(&p, &p).sqrt()), n(dot(&e, &e).sqrt())));
    // no dot product here: the squared distance from u to the point t v, spelled out
    let dist2 = |t: f64| -> f64 { u.iter().zip(&v).map(|(x, y)| (x - t * y).powi(2)).sum() };
    let grid: Vec<String> = (0..9).map(|t| n(dist2(t as f64))).collect();
    one("squared distance from u to t v, t = 0 to 8", grid.join(", "));
    let c = dist2(0.0);                                     // road two: fit the parabola
    let (a, b) = ((dist2(1.0) + dist2(-1.0)) / 2.0 - c, (dist2(1.0) - dist2(-1.0)) / 2.0);
    let t_low = -b / (2.0 * a);
    one("road two: the parabola a, b, c", format!("{}, {}, {}", n(a), n(b), n(c)));
    one("road two: lowest at t, and the point there",
        format!("{}, {}", n(t_low), show(&scale(t_low, &v))));

    let f = vec![6.0, 2.0, 3.0];                     // the same pull, now lifting a little
    let (w1, w2) = (vec![1.0, 1.0, 0.0], vec![1.0, -1.0, 0.0]);
    let pp = add(&project(&f, &w1), &project(&f, &w2));
    let ee = sub(&f, &pp);
    one(&format!("the plane: pull {}, parts w1, w2", show(&f)),
        format!("{} + {}", show(&project(&f, &w1)), show(&project(&f, &w2))));
    one("the shadow on the plane", show(&pp));
    one("the leftover, then its dots with w1 and w2",
        format!("{}, {} and {}", show(&ee), n(dot(&ee, &w1)), n(dot(&ee, &w2))));
    let alt = add(&project(&f, &[1.0, 0.0, 0.0]), &project(&f, &[0.0, 1.0, 0.0]));  // another pair
    one("road two: same plane, from (1,0,0), (0,1,0)", show(&alt));

    let m1 = scale(dot(&u, &v), &v);                          // forgot to divide at all
    let m2 = scale(dot(&u, &v) / dot(&v, &v).sqrt(), &v);     // divided by the length
    let m3 = project(&v, &u);                                 // projected the wrong way round
    let m4 = sub(&f, &project(&f, &w1));                      // used one direction of two
    one("mistake 1: never divided",
        format!("{}, leftover . v = {}", show(&m1), n(dot(&sub(&u, &m1), &v))));
    let miss: f64 = u.iter().zip(&m2).map(|(x, y)| (x - y).powi(2)).sum();
    one("mistake 2: divided by the length", format!("{}, squared miss {}", show(&m2), n(miss)));
    one("mistake 3: projected the wrong way round", show(&m3));
    one("mistake 4: one direction of the two",
        format!("{}, and m4 . w2 = {}", show(&m4), n(dot(&m4, &w2))));
    assert!(p == vec![4.0, 4.0] && e == vec![2.0, -2.0] && dot(&e, &v) == 0.0 && dot(&e, &p) == 0.0);
    assert!(t_low == 4.0 && scale(t_low, &v) == p && (dist2(t_low) - dot(&e, &e)).abs() < 1e-12);
    assert!(dot(&u, &u) == dot(&p, &p) + dot(&e, &e) && dot(&u, &u) == 40.0);
    assert!(pp == vec![6.0, 2.0, 0.0] && pp == alt && ee == vec![0.0, 0.0, 3.0]
            && dot(&ee, &w1) == 0.0 && dot(&ee, &w2) == 0.0);
    println!("ALL CHECKS PASS");
}
