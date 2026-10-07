// Triple product and volume -- the check behind the card.  Standard library only.
// A crate knocked out of square, measured in decimetres, so 1 dm^3 = 1 litre.  Its
// capacity is found three ways: cross then dot, a 3 by 3 determinant, and a count of
// small cubes.  Then sets of four corners are tested for lying in one plane, two ways.
type V3 = [f64; 3];
const A: V3 = [20.0, 0.0, 0.0];
const B: V3 = [5.0, 15.0, 0.0];
const C: V3 = [4.0, 3.0, 12.0];

fn add(u: V3, v: V3) -> V3 { [u[0] + v[0], u[1] + v[1], u[2] + v[2]] }
fn sub(u: V3, v: V3) -> V3 { [u[0] - v[0], u[1] - v[1], u[2] - v[2]] }
fn dot(u: V3, v: V3) -> f64 { u[0] * v[0] + u[1] * v[1] + u[2] * v[2] }
fn cross(u: V3, v: V3) -> V3 { [u[1] * v[2] - u[2] * v[1], u[2] * v[0] - u[0] * v[2], u[0] * v[1] - u[1] * v[0]] }
fn triple(u: V3, v: V3, w: V3) -> f64 { dot(cross(u, v), w) } // road 1: floor arrow, then height
fn det(m: &Vec<Vec<f64>>) -> f64 {                               // road 2: cofactor expansion, top row
    if m.len() == 1 { return m[0][0]; }
    (0..m.len()).map(|j| {
        let minor: Vec<Vec<f64>> = m[1..].iter().map(|r| [&r[..j], &r[j + 1..]].concat()).collect();
        if j % 2 == 0 { m[0][j] * det(&minor) } else { -m[0][j] * det(&minor) }
    }).sum()
}
fn inside(p: V3) -> bool {                                       // road 3: undo c, then b, then read a
    let t = p[2] / C[2]; let s = (p[1] - t * C[1]) / B[1]; let r = (p[0] - t * C[0] - s * B[0]) / A[0];
    (0.0..=1.0).contains(&r) && (0.0..=1.0).contains(&s) && (0.0..=1.0).contains(&t)
}
fn show(v: V3) -> String { format!("({:.1}, {:.1}, {:.1})", v[0], v[1], v[2]) }
fn length(v: V3) -> f64 { dot(v, v).sqrt() }
fn step(p: V3, q: V3, r: V3, s: V3) -> (f64, f64) {             // plane road: reach S along two edges; what is left
    let (u, v, d) = (sub(q, p), sub(r, p), sub(s, p)); let k = u[0] * v[1] - u[1] * v[0];
    let (a, b) = ((d[0] * v[1] - d[1] * v[0]) / k, (u[0] * d[1] - u[1] * d[0]) / k);
    (k, d[2] - (a * u[2] + b * v[2]))                            // floor shadow of the base, height left over
}

fn main() {
    let v = triple(A, B, C);
    let d = det(&vec![A.to_vec(), B.to_vec(), C.to_vec()]);
    let h = 0.25;                                                // cube edge in dm; the box spans 29 x 18 x 12
    let mut n = 0u64;
    for i in 0..116 { for j in 0..72 { for k in 0..48 {
        if inside([(i as f64 + 0.5) * h, (j as f64 + 0.5) * h, (k as f64 + 0.5) * h]) { n += 1; }
    } } }
    let (o, p, q, r) = ([0.0; 3], C, add(C, A), add(C, B));       // corner at the floor, three lid corners
    let cases = [("flat lid", p, q, r, add(q, B)), ("sagging lid", p, q, r, [29.0, 18.0, 11.5]),
                 ("bent front", o, A, C, [24.0, 2.5, 12.0])];
    let floor = length(cross(A, B));
    println!("edges in dm: a {}, b {}, c {}", show(A), show(B), show(C));
    println!("floor arrow a x b = {}, floor area {:.1} dm^2", show(cross(A, B)), floor);
    println!("road 1, (a x b) . c = {:.1} litres", v);
    println!("road 2, determinant with rows a, b, c = {:.1} litres", d);
    println!("road 3, {} cubes of 1/64 litre inside = {:.2} litres", n, n as f64 * h * h * h);
    println!("a . (b x c) = {:.1}; (b x a) . c = {:.1}", dot(A, cross(B, C)), triple(B, A, C));
    println!("height straight up: {:.1} / {:.1} = {:.1} dm", v, floor, v / floor);
    println!("mistake 1, edge lengths multiplied: {:.0} x {:.6} x {:.0} = {:.2}",
             length(A), length(B), length(C), length(A) * length(B) * length(C));
    println!("mistake 2, floor area x slanted edge: {:.1}", floor * length(C));
    for (name, p, q, r, s) in cases {
        let (t, (k, z)) = (triple(sub(q, p), sub(r, p), sub(s, p)), step(p, q, r, s));
        println!("{} S {}: triple {:.1}; shadow {:.1} x leftover {:.2} = {:.1}; gap {:.3} dm",
                 name, show(s), t, k, z, k * z, t / length(cross(sub(q, p), sub(r, p))));
    }
    println!("mistake 3, corner positions Q, R, S of the flat lid as edges: {:.1}", triple(q, r, cases[0].4));
    let g: [V3; 3] = [[1.0, 2.0, 3.0], [2.0, -1.0, 1.0], [0.0, 3.0, 1.0]]; // a second box, every top-row term live
    let dg = det(&g.iter().map(|x| x.to_vec()).collect());
    println!("second box, rows {} {} {}: triple {:.1}, determinant {:.1}", show(g[0]), show(g[1]), show(g[2]),
             triple(g[0], g[1], g[2]), dg);
    println!("try changing: c (0, 0, 12) {:.1}; c (4, 3, 6) {:.1}; corner at 11.0: triple {:.1}, gap {:.2} dm",
             triple(A, B, [0.0, 0.0, 12.0]), triple(A, B, [4.0, 3.0, 6.0]), triple(A, B, [25.0, 15.0, -1.0]),
             triple(A, B, [25.0, 15.0, -1.0]) / 300.0);
    let pts = [[0.0, 0.0, 0.0], A, B, C, add(A, B), add(A, C), add(B, C), add(add(A, B), C), [4.0, 3.0, 0.0]];
    let f: Vec<String> = pts.iter().map(|p| format!("{:.2},{:.2}",
        60.0 + 7.0 * (p[0] + p[1] * 3f64.sqrt() / 4.0), 205.0 - 7.0 * (p[2] + p[1] / 4.0))).collect();
    println!("figure, {}", f.join(" "));
    assert!(d == v && dg == triple(g[0], g[1], g[2]));            // two expansions, one number
    assert!((n as f64 * h * h * h - v).abs() < 0.01 * v);        // the cube count lands within 1%
    assert!(triple(B, A, C) == -v);                              // swapping two edges flips the sign
    assert!(cases.iter().all(|&(_, p, q, r, s)| {                // box volume = shadow x leftover height
        let (k, z) = step(p, q, r, s); (triple(sub(q, p), sub(r, p), sub(s, p)) - k * z).abs() < 1e-9 }));
    println!("ALL CHECKS PASS");
}
