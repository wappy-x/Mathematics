// Change of basis -- the same check as the Python, in Rust.  No crates.  A game
// map is drawn on a diagonal grid whose axes are b1 = (1, 1) and b2 = (-1, 1), and
// P carries those two axes as its columns.  The treasure at (5, 3) is given its
// diagonal address, and the shear [[1, 1], [0, 1]] is rewritten on that grid.  Two
// methods all the way: the 2 by 2 inverse formula, and elimination, which builds no
// inverse at all.
type M = [[f64; 2]; 2];
type V = [f64; 2];
fn det(a: M) -> f64 { a[0][0] * a[1][1] - a[0][1] * a[1][0] }
fn tr(a: M) -> f64 { a[0][0] + a[1][1] }
fn mul(a: M, b: M) -> M {                        // 2 by 2 times 2 by 2
    let mut o: M = [[0.0; 2]; 2];
    for i in 0..2 { for j in 0..2 { o[i][j] = a[i][0] * b[0][j] + a[i][1] * b[1][j]; } }
    o
}
fn act(a: M, v: V) -> V {                        // 2 by 2 times a column
    [a[0][0] * v[0] + a[0][1] * v[1], a[1][0] * v[0] + a[1][1] * v[1]]
}
fn inv(a: M) -> M {                              // method one: the 2 by 2 inverse
    let d = det(a);
    [[a[1][1] / d, -a[0][1] / d], [-a[1][0] / d, a[0][0] / d]]
}
fn solve(a: M, v: V) -> V {                      // method two: elimination, no inverse
    let f = a[1][0] / a[0][0];                   // clear the lower-left entry
    let y = (v[1] - f * v[0]) / (a[1][1] - f * a[0][1]);
    [(v[0] - a[0][1] * y) / a[0][0], y]
}
fn mat(a: M) -> String { format!("[[{}, {}], [{}, {}]]", a[0][0], a[0][1], a[1][0], a[1][1]) }
fn col(v: V) -> String { format!("({}, {})", v[0], v[1]) }
fn row(label: &str, value: String) { println!("{:<44}{}", label, value); }
fn main() {
    let (b1, b2): (V, V) = ([1.0, 1.0], [-1.0, 1.0]);   // the diagonal grid's axes
    let p: M = [[b1[0], b2[0]], [b1[1], b2[1]]];        // new axes down the columns
    let pi = inv(p);
    let a: M = [[1.0, 1.0], [0.0, 1.0]];                // the shear, standard grid
    let ad = mul(pi, mul(a, p));                        // the shear, diagonal grid
    let s0 = solve(p, act(a, [p[0][0], p[1][0]]));      // sheared axes, new coords
    let s1 = solve(p, act(a, [p[0][1], p[1][1]]));
    let ad2: M = [[s0[0], s1[0]], [s0[1], s1[1]]];
    let (v, w): (V, V) = ([5.0, 3.0], [2.0, 6.0]);      // the treasure, and a second
    let (c, cw) = (act(pi, v), act(pi, w));             // their diagonal addresses
    let rebuilt: V = [c[0] * b1[0] + c[1] * b2[0], c[0] * b1[1] + c[1] * b2[1]];
    let prow: M = [[b1[0], b1[1]], [b2[0], b2[1]]];     // the new axes as rows
    let papi = mul(p, mul(a, pi));                      // the sandwich, backwards
    let wrongs = [act(p, v), act(inv(prow), v), act(papi, c)];

    row("P, the new axes down its columns", format!("{}   det {}", mat(p), det(p)));
    row("P inverse, by the 2 by 2 formula", mat(pi));
    row("P times (1, 0), must be the first new axis", col(act(p, [1.0, 0.0])));
    row("treasure: standard, then diagonal address", format!("{}  ->  {}", col(v), col(c)));
    row("the same diagonal address, by elimination", col(solve(p, v)));
    row("rebuilt as 4 b1 - 1 b2", col(rebuilt));
    row("A, the shear on the standard grid", format!("{}   trace {}   area {}", mat(a), tr(a), det(a)));
    row("A P, the shear sent through the new axes", mat(mul(a, p)));
    row("P^-1 A P, the shear on the diagonal grid", format!("{}   trace {}   area {}", mat(ad), tr(ad), det(ad)));
    row("the same matrix, by elimination", mat(ad2));
    row("road 1: shear, then convert", format!("A v = {}  ->  {}", col(act(a, v)), col(act(pi, act(a, v)))));
    row("road 2: convert, then shear", col(act(ad, c)));
    row("second treasure: standard, then diagonal", format!("{}  ->  {}", col(w), col(cw)));
    row("second treasure, road 1", format!("A w = {}  ->  {}", col(act(a, w)), col(act(pi, act(a, w)))));
    row("second treasure, road 2", col(act(ad, cw)));
    row("wrong: P v instead of P^-1 v", col(wrongs[0]));
    row("wrong: the new axes written as rows", col(wrongs[1]));
    row("wrong: P A P^-1 sends (4, -1) to", col(wrongs[2]));
    assert!(c == [4.0, -1.0] && solve(p, v) == c && rebuilt == v);
    assert!(ad == [[1.5, 0.5], [-0.5, 0.5]] && ad2 == ad && det(ad) == det(a) && tr(ad) == tr(a));
    assert!(act(pi, act(a, v)) == [5.5, -2.5] && act(ad, c) == [5.5, -2.5]
        && act(pi, act(a, w)) == [7.0, -1.0] && act(ad, cw) == [7.0, -1.0]);
    assert!(wrongs == [[2.0, 8.0], [1.0, 4.0], [1.5, -3.5]]);
    println!("ALL CHECKS PASS");
}
