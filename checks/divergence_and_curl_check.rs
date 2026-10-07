// Divergence and curl -- the same check as the Python, in Rust.  No crates;
// atan2 and pi are primitives, and every sum is written out here.
// Wind (P, Q, R) in m/s at the point x m east, y m north and z m up of a mast.
use std::f64::consts::PI;
type Field<'a> = &'a dyn Fn(f64, f64, f64) -> [f64; 3];

fn w(x: f64, y: f64, _z: f64) -> [f64; 3] { [3.0 + 0.0003 * (x * x - y * y) + x.powi(3) / 400000.0, 0.0006 * x * y, 0.0] }
fn g(_x: f64, _y: f64, z: f64) -> [f64; 3] { [3.0 + z / 10.0, 0.0, 0.0] } // second case: a breeze growing with height
fn rates(x: f64, y: f64) -> [(&'static str, f64); 4] { // road one: the partial derivatives, by hand
    [("dP/dx", 0.0006 * x + 3.0 * x * x / 400000.0), ("dQ/dy", 0.0006 * x), ("dQ/dx", 0.0006 * y), ("dP/dy", 0.0 - 0.0006 * y)]
}
fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64) -> f64 {
    let n = 10;
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for k in 1..n { s += if k % 2 == 1 { 4.0 } else { 2.0 } * f(a + k as f64 * h) }
    h / 3.0 * s
}
fn bx(f: Field, c: [f64; 3], li: f64, lj: f64, i: usize, j: usize) -> (f64, f64) { // road two, no derivatives
    let at = |u: f64, v: f64| { let mut p = c; p[i] += u; p[j] += v; f(p[0], p[1], p[2]) };
    let (a, b) = (li / 2.0, lj / 2.0);
    let circ = simpson(&|u| at(u, -b)[i] - at(u, b)[i], -a, a) + simpson(&|v| at(a, v)[j] - at(-a, v)[j], -b, b);
    let out = simpson(&|u| at(u, b)[j] - at(u, -b)[j], -a, a) + simpson(&|v| at(a, v)[i] - at(-a, v)[i], -b, b);
    (circ, out)
}
fn turn(f: Field, c: [f64; 3], d: (f64, f64)) -> f64 { // a straw of length l along d, carried for dt
    let (dt, l) = (0.01, 1e-4);
    let (root, tip) = (f(c[0], c[1], c[2]), f(c[0] + l * d.0, c[1] + l * d.1, c[2]));
    let v = (l * d.0 + (tip[0] - root[0]) * dt, l * d.1 + (tip[1] - root[1]) * dt);
    (v.1.atan2(v.0) - d.1.atan2(d.0)) / dt
}

fn main() {
    let (s, e) = ([40.0, 0.0, 0.0], [0.0, 50.0, 0.0]);
    println!("wind P = 3 + 0.0003(x^2 - y^2) + x^3/400000, Q = 0.0006xy, R = 0 m/s; S = (40, 0), E = (0, 50) m");
    let mut res = Vec::new();
    for (name, c) in [("S", s), ("E", e)] {
        let r = rates(c[0], c[1]);
        let (div, curl) = (r[0].1 + r[1].1, r[2].1 - r[3].1);
        let wc = w(c[0], c[1], c[2]);
        let parts: Vec<String> = r.iter().map(|(k, v)| format!("{} {:.3}", k, v)).collect();
        println!("{}: wind ({:.3}, {:.3}); {}", name, wc[0], wc[1], parts.join(", "));
        println!("{}: div {:.6} per s, curl {:.6} per s", name, div, curl);
        res.push((div, curl, r));
    }
    let (ds, (ce, re)) = (res[0].0, (res[1].1, res[1].2));
    for l in [40.0_f64, 20.0, 10.0, 5.0] {
        let (os, cel) = (bx(&w, s, l, l, 0, 1).1 / l.powi(2), bx(&w, e, l, l, 0, 1).0 / l.powi(2));
        println!("side {:2} m: S outflow/area {:.9}, gap {:.9}; E circulation/area {:.9}", l, os, os - ds, cel);
        assert!((os - (ds + l * l / 1600000.0)).abs() < 1e-12); // road two against road one plus the size term
        assert!((cel - ce).abs() < 1e-12); // circulation per area against the hand curl
    }
    let (east, north) = (turn(&w, e, (1.0, 0.0)), turn(&w, e, (0.0, 1.0)));
    println!("E: straws turn east {:.6}, north {:.6} rad/s; average {:.6}; curl/2 {:.6}; one turn in {:.1} s",
             east, north, (east + north) / 2.0, ce / 2.0, 2.0 * PI / (ce / 2.0));
    assert!(((east + north) / 2.0 - ce / 2.0).abs() < 1e-6); // the straws spin at half the curl
    let (cg, og) = bx(&g, [0.0, 0.0, 10.0], 2.0, 2.0, 2, 0); // plane z then x: anticlockwise seen from the north
    let cl = bx(&|_x: f64, y: f64, _z: f64| [y / 10.0, -1.0, 0.0], [20.0, 15.0, 0.0], 40.0, 30.0, 0, 1).0;
    println!("breeze 3 + z/10: curl by hand (0, {:.1}, 0); z-x square circulation/area {:.6}, outflow {:.6}; roll {:.2} rad/s",
             1.0 / 10.0, cg / 4.0, og, cg / 8.0);
    println!("line-integrals wind (y/10, -1) N: curl by hand {:.1} N/m; 40 m x 30 m anticlockwise {:.3} J", 0.0 - 1.0 / 10.0, cl);
    assert!((cg / 4.0 - 1.0 / 10.0).abs() < 1e-12 && (cl - (0.0 - 1.0 / 10.0) * 40.0 * 30.0).abs() < 1e-9);
    println!("mistake 1, curl read as spin: {:.2} rad/s, one turn in {:.1} s, truly {:.1} s", ce, 2.0 * PI / ce, 2.0 * PI / (ce / 2.0));
    println!("mistake 2, cross rates added at E: {:.3} per s, not {:.3}", re[2].1 + re[3].1, ce);
    println!("mistake 3, order swapped at E: {:.3} per s, clockwise, not anticlockwise", re[3].1 - re[2].1);
    for (name, c, cx) in [("S", s, 90.0), ("E", e, 270.0)] {
        let w0 = w(c[0], c[1], c[2]);
        let pts: Vec<String> = [(10.0, 0.0), (10.0, 10.0), (0.0, 10.0), (-10.0, 10.0), (-10.0, 0.0), (-10.0, -10.0), (0.0, -10.0), (10.0, -10.0)]
            .iter().map(|&(hx, hy): &(f64, f64)| {
                let wv = w(c[0] + hx, c[1] + hy, 0.0);
                format!("({},{})->({:.0},{:.0})", cx + 5.0 * hx, 120.0 - 5.0 * hy,
                        cx + 5.0 * hx + 80.0 * (wv[0] - w0[0]), 120.0 - 5.0 * hy - 80.0 * (wv[1] - w0[1]))
            }).collect();
        println!("figure, {}, 5 units per m, 80 per m/s: {}", name, pts.join(" "));
    }
    println!("ALL CHECKS PASS");
}
