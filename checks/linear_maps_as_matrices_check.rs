// Linear maps as matrices -- the same check as the Python, in Rust.  No crates.
// A game sprite sits on the unit square.  Two moves: a shear that leans it, and
// a quarter turn.  Each is tested for linearity, turned into a matrix from the
// images of the two axis arrows, run by rule and by matrix, then composed.
type V = (i64, i64);
type M = [[i64; 2]; 2];

fn shear(v: V) -> V { (v.0 + v.1, v.1) }        // lean the top to the right
fn turn(v: V) -> V { (-v.1, v.0) }              // quarter turn, anticlockwise
fn slide(v: V) -> V { (v.0 + 1, v.1) }          // NOT linear: it moves (0, 0)

const E1: V = (1, 0);                           // the two axis arrows
const E2: V = (0, 1);
const C: V = (1, 1);                            // the corner followed

fn matrix_of(f: fn(V) -> V) -> M {              // columns are the images of the axes
    let (a, b) = (f(E1), f(E2));
    [[a.0, b.0], [a.1, b.1]]
}
fn apply(m: M, v: V) -> V {                     // matrix times vector: mix the columns
    (m[0][0] * v.0 + m[0][1] * v.1, m[1][0] * v.0 + m[1][1] * v.1)
}
fn times(m: M, n: M) -> M {                     // m after n: push each column of n through m
    let (c1, c2) = (apply(m, (n[0][0], n[1][0])), apply(m, (n[0][1], n[1][1])));
    [[c1.0, c2.0], [c1.1, c2.1]]
}
fn add(a: V, b: V) -> V { (a.0 + b.0, a.1 + b.1) }
fn scale(k: i64, a: V) -> V { (k * a.0, k * a.1) }
fn s(v: V) -> String { format!("({}, {})", v.0, v.1) }
fn mm(m: M) -> String {
    format!("[[{}, {}], [{}, {}]]", m[0][0], m[0][1], m[1][0], m[1][1])
}
fn row<F: Fn(V) -> V>(label: &str, f: F, square: &[V]) -> String {
    let parts: Vec<String> = square.iter().map(|&v| s(f(v))).collect();
    format!("{}{}", label, parts.join("  "))
}

fn main() {
    let square: Vec<V> = vec![(0, 0), (1, 0), (1, 1), (0, 1)];   // the sprite's four corners
    let (sm, rm) = (matrix_of(shear), matrix_of(turn));
    println!("shear: e1 -> {}, e2 -> {}, so the matrix is {}", s(shear(E1)), s(shear(E2)), mm(sm));
    println!("turn:  e1 -> {}, e2 -> {}, so the matrix is {}", s(turn(E1)), s(turn(E2)), mm(rm));
    println!("{}", row("the sprite's corners             ", |v| v, &square));
    println!("{}", row("after the shear, by the rule     ", shear, &square));
    println!("{}", row("after the shear, by its matrix   ", |v| apply(sm, v), &square));
    println!("{}", row("after the turn, by the rule      ", turn, &square));
    println!("{}", row("after the turn, by its matrix    ", |v| apply(rm, v), &square));

    let (ts, st) = (times(sm, rm), times(rm, sm));
    println!("turn first, then shear: one matrix {}", mm(ts));
    println!("  two steps, corner {}: turn -> {}, then shear -> {}", s(C), s(turn(C)), s(shear(turn(C))));
    println!("  that one matrix, corner {}: {}", s(C), s(apply(ts, C)));
    println!("shear first, then turn: one matrix {}", mm(st));
    println!("  two steps, corner {}: shear -> {}, then turn -> {}", s(C), s(shear(C)), s(turn(shear(C))));
    println!("  that one matrix, corner {}: {}", s(C), s(apply(st, C)));

    let (u, v, k) = ((1, 0), (0, 1), 3);
    println!("linearity of the shear, with u = {}, v = {}, c = {}", s(u), s(v), k);
    println!("  T(u + v) = {} and T(u) + T(v) = {}", s(shear(add(u, v))), s(add(shear(u), shear(v))));
    println!("  T(cu) = {} and cT(u) = {}", s(shear(scale(k, u))), s(scale(k, shear(u))));
    println!("slide right by 1 fails: D(u + v) = {} but D(u) + D(v) = {}",
             s(slide(add(u, v))), s(add(slide(u), slide(v))));

    let rows_not_cols: M = [[1, 0], [1, 1]];
    let no_minus: M = [[0, 1], [1, 0]];
    println!("mistakes on corner {}: wrong order {}, rows not columns {}, turn with no minus {}",
             s(C), s(apply(st, C)), s(apply(rows_not_cols, C)), s(apply(no_minus, C)));

    assert!(sm == [[1, 1], [0, 1]] && rm == [[0, -1], [1, 0]]);
    assert!(square.iter().all(|&w| apply(sm, w) == shear(w) && apply(rm, w) == turn(w)));
    assert!(ts == [[1, -1], [1, 0]] && st == [[0, -1], [1, 1]]);
    assert!(apply(ts, C) == shear(turn(C)) && apply(ts, C) == (0, 1)
            && apply(st, C) == turn(shear(C)) && apply(st, C) == (-1, 2));
    println!("ALL CHECKS PASS");
}
