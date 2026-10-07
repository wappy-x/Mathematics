// Basis and dimension -- the same check as the Python, in Rust.  No crates.  A
// rowing crew on a river; positions in km east and km north of the boathouse.
// Two bases of the same plane: east-north (1, 0) and (0, 1), and the river
// basis (1, 1) downstream and (-1, 1) across.  The buoy sits at (5, 3).
const E1: (i64, i64) = (1, 0);           // the standard basis: one east, one north
const E2: (i64, i64) = (0, 1);
const B1: (i64, i64) = (1, 1);           // downstream along the river
const B2: (i64, i64) = (-1, 1);          // across it
const SPARE: (i64, i64) = (1, 0);        // a spare third vector: spans, but not a basis

fn combo(cs: &[f64], vs: &[(i64, i64)]) -> (f64, f64) {   // so much of each, added up
    let (mut e, mut n) = (0.0, 0.0);
    for (c, v) in cs.iter().zip(vs.iter()) { e += c * v.0 as f64; n += c * v.1 as f64; }
    (e, n)
}

fn cross(u: (i64, i64), v: (i64, i64)) -> i64 { u.0 * v.1 - v.0 * u.1 }  // zero when dependent

fn eliminate(t: (i64, i64)) -> (f64, f64) {        // road one: x - y = east, x + y = north
    let x = (t.0 + t.1) as f64 / 2.0;
    (x, t.1 as f64 - x)
}

fn rule(t: (i64, i64), b1: (i64, i64), b2: (i64, i64)) -> (f64, f64) {   // road two: cross-numbers
    let d = cross(b1, b2) as f64;
    (cross(t, b2) as f64 / d, cross(b1, t) as f64 / d)
}

fn tup(v: (f64, f64)) -> String { format!("({:.0}, {:.0})", v.0, v.1) }
fn trip(c: &[f64]) -> String { format!("({:.0}, {:.0}, {:.0})", c[0], c[1], c[2]) }
fn show(name: &str, value: String) { println!("{:<48}{:>12}", name, value); }

fn main() {
    show("cross-number, river basis then east-north basis",
         format!("{} and {}", cross(B1, B2), cross(E1, E2)));
    for t in [(5_i64, 3_i64), (0, 6)] {
        let (ex, ey) = eliminate(t);
        let (rx, ry) = rule(t, B1, B2);
        let tf = (t.0 as f64, t.1 as f64);
        show(&format!("point {}: east-north coordinates", tup(tf)),
             tup(combo(&[tf.0, tf.1], &[E1, E2])));
        show(&format!("point {}: river coordinates, by elimination", tup(tf)), tup((ex, ey)));
        show(&format!("point {}: river coordinates, by cross-number", tup(tf)), tup((rx, ry)));
        show(&format!("point {}: rebuilt from the river basis", tup(tf)),
             tup(combo(&[ex, ey], &[B1, B2])));
    }
    let wrong_read = combo(&[5.0, 3.0], &[B1, B2]);     // east-north numbers used as river ones
    let wrong_order = combo(&[-1.0, 4.0], &[B1, B2]);   // the coordinates the wrong way round
    show("wrong: (5, 3) read as river coordinates", tup(wrong_read));
    show("wrong: the river coordinates in the other order", tup(wrong_order));
    show("wrong: cross-number of (1, 1) and (2, 2)", format!("{}", cross((1, 1), (2, 2))));
    let (first, second) = ([4.0, -1.0, 0.0], [3.0, 0.0, 2.0]);
    show("with a spare third vector, one answer", trip(&first));
    show("with a spare third vector, another answer", trip(&second));
    show("both of those rebuild the buoy",
         format!("{} {}", tup(combo(&first, &[B1, B2, SPARE])),
                 tup(combo(&second, &[B1, B2, SPARE]))));
    let river: Vec<(f64, f64)> = (0..6).map(|s| combo(&[s as f64, 0.0], &[B1, B2])).collect();
    let mut route: Vec<(f64, f64)> = (0..5).map(|s| combo(&[s as f64, 0.0], &[B1, B2])).collect();
    route.push(combo(&[4.0, -1.0], &[B1, B2]));
    let row = |name: &str, vals: Vec<f64>| {
        let cells: Vec<String> = vals.iter().map(|v| format!("{:>2}", *v as i64)).collect();
        println!("{:<48}{}", name, cells.join(" "));
    };
    row("chart, km east", river.iter().map(|p| p.0).collect());
    row("chart, the river, km north", river.iter().map(|p| p.1).collect());
    row("chart, the crew's route, km north", route.iter().map(|p| p.1).collect());
    show("vectors in each basis, so the dimension",
         format!("{} and {}", [B1, B2].len(), [E1, E2].len()));
    assert!(eliminate((5, 3)) == (4.0, -1.0) && rule((5, 3), B1, B2) == (4.0, -1.0)
            && combo(&[4.0, -1.0], &[B1, B2]) == (5.0, 3.0));
    assert!(eliminate((0, 6)) == (3.0, 3.0) && rule((0, 6), B1, B2) == (3.0, 3.0)
            && combo(&[3.0, 3.0], &[B1, B2]) == (0.0, 6.0));
    assert!(cross(B1, B2) == 2 && cross(E1, E2) == 1 && cross((1, 1), (2, 2)) == 0);
    assert!(wrong_read == (2.0, 8.0) && wrong_order == (-5.0, 3.0) && first != second
            && combo(&first, &[B1, B2, SPARE]) == (5.0, 3.0)
            && combo(&second, &[B1, B2, SPARE]) == (5.0, 3.0));
    println!("ALL CHECKS PASS");
}
