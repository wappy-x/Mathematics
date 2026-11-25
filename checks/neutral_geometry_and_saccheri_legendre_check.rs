// Neutral geometry: Legendre's halving and Saccheri's quadrilateral, in Rust, no
// crates.  Hyperbolic points sit on the surface t^2 - x^2 - y^2 = 1 (the
// hyperboloid), curvature -1.  Same numbers and labels as the Python.
type P = [f64; 3];
fn h(p: &P, q: &P) -> f64 { p[0] * q[0] - p[1] * q[1] - p[2] * q[2] } // the hyperboloid's dot

fn ang(p: &P, q: &P, r: &P) -> f64 {    // angle at p between the lines to q and to r
    let (hq, hr) = (h(p, q), h(p, r));
    let u: P = [q[0] - hq * p[0], q[1] - hq * p[1], q[2] - hq * p[2]];
    let v: P = [r[0] - hr * p[0], r[1] - hr * p[1], r[2] - hr * p[2]];
    (-h(&u, &v) / (h(&u, &u) * h(&v, &v)).sqrt()).acos().to_degrees()
}

fn pt(d: f64, th: f64) -> P { [d.cosh(), d.sinh() * th.cos(), d.sinh() * th.sin()] }

fn main() {
    let (s, mut small, mut n, mut steps) = (181.0_f64, 60.0_f64, 0, vec!["60".to_string()]);
    while small >= s - 180.0 { small /= 2.0; n += 1; steps.push(format!("{}", small)); }
    println!("suppose angles 60, 60, 61 sum to {}: halve the 60 deg angle {} times", s, n);
    println!("smallest angle after each halving: {}", steps.join(" -> "));
    println!("other two then sum to at least {} > 180: impossible", s - small);
    println!("stop at 5 halvings: smallest {}, others {}, no clash", 60.0 / 32.0, s - 60.0 / 32.0);
    assert!(n == (60.0 / (s - 180.0)).log2().floor() as i32 + 1 && small == 60.0 / 2f64.powi(n)); // count and value match logs
    let mut tri = [pt(0.0, 0.0), pt(0.3, 0.0), pt(0.3, std::f64::consts::PI / 3.0)];
    let (mut sums, mut halved) = (vec![], vec![]);
    for _ in 0..7 {                                               // road 2: a real hyperbolic triangle
        let [a, b, c] = tri;
        sums.push(ang(&a, &b, &c) + ang(&b, &c, &a) + ang(&c, &a, &b));
        halved.push(ang(&a, &b, &c));
        let m: P = [b[0] + c[0], b[1] + c[1], b[2] + c[2]];
        let k = h(&m, &m).sqrt();
        let d: P = [m[0] / k, m[1] / k, m[2] / k];                 // the midpoint of BC
        let t = 2.0 * h(&a, &d);
        let e: P = [t * d[0] - a[0], t * d[1] - a[1], t * d[2] - a[2]]; // A's mirror image through D
        tri = if ang(&a, &e, &c) <= ang(&e, &a, &c) { [a, e, c] } else { [e, a, c] };
    }
    let (ch, sh) = (0.3_f64.cosh(), 0.3_f64.sinh());              // hyperbolic law of cosines
    let cos_a = ch * ch - sh * sh / 2.0;
    let law_b = ((cos_a * ch - ch) / ((cos_a * cos_a - 1.0).sqrt() * sh)).acos().to_degrees();
    println!("hyperbolic triangle, sides 0.3 and 0.3 at 60 deg: angles 60, {:.4}, {:.4}", law_b, law_b);
    let hs: Vec<String> = halved.iter().map(|x| format!("{:.4}", x)).collect();
    println!("Legendre steps, the angle being halved: {}", hs.join(", "));
    let lo = sums.iter().cloned().fold(f64::MAX, f64::min);
    let hi = sums.iter().cloned().fold(f64::MIN, f64::max);
    println!("angle sum at all 7 stages: {:.6} to {:.6}, short by {:.6}", lo, hi, 180.0 - sums[0]);
    assert!((sums[0] - (60.0 + 2.0 * law_b)).abs() < 1e-9);       // coordinates agree with the law
    assert!(hi - lo < 1e-6 && sums[0] < 180.0);                   // the sum never moves
    assert!((0..6).all(|i| halved[i + 1] <= halved[i] / 2.0 + 1e-9));
    let (a, b) = (3.0_f64, 4.0_f64);                              // Saccheri: legs 3, base 4
    let (pa, pb) = (pt(b / 2.0, std::f64::consts::PI), pt(b / 2.0, 0.0));
    let pd: P = [a.cosh() * pa[0], a.cosh() * pa[1], a.sinh()];
    let pc: P = [a.cosh() * pb[0], a.cosh() * pb[1], a.sinh()];
    let tops = (ang(&pd, &pa, &pc), ang(&pc, &pb, &pd));
    let formula = (1.0 / (a.sinh() * (b / 2.0).tanh())).atan().to_degrees();
    let top = h(&pd, &pc).acosh();
    println!("Saccheri base {}, legs {}: base corners {:.4}, {:.4}", b, a, ang(&pa, &pb, &pd), ang(&pb, &pc, &pa));
    println!("formula pieces: sinh {} = {:.4}, tanh {} = {:.4}", a, a.sinh(), b / 2.0, (b / 2.0).tanh());
    println!("top corners by coordinates {:.4}, {:.4}; by formula {:.4}", tops.0, tops.1, formula);
    let (u, v) = ([0.0, -a], [b, 0.0]);                           // flat: from the top-left corner
    let flat = ((u[0] * v[0] + u[1] * v[1]) / (a * b)).acos().to_degrees();
    println!("flat top corners {}; top side flat {}, hyperbolic {:.4}", flat, b, top);
    assert!((tops.0 - tops.1).abs() < 1e-9 && (tops.0 - formula).abs() < 1e-9);
    assert!(tops.0 < 90.0 && top > b);                            // neutral: at most 90, top >= base
    let small_top = (1.0 / ((a / 1000.0).sinh() * (b / 2000.0).tanh())).atan().to_degrees();
    println!("same shape shrunk 1000 times: top corners {:.5}", small_top);
    println!("sphere, octant triangle: 90 + 90 + 90 = 270, two angles alone reach 180");
    let f = |q: &P| format!("({:.1}, {:.1})", 170.0 + 150.0 * q[1] / (1.0 + q[0]), 170.0 - 150.0 * q[2] / (1.0 + q[0]));
    println!("figure, disc radius 150 at (170, 170): A {}, B {}, C {}, D {}", f(&pa), f(&pb), f(&pc), f(&pd));
    println!("ALL CHECKS PASS");
}
