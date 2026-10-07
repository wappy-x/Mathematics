// Complex numbers -- the same check as the Python, in Rust.  No crates.
// A complex number is a pair (a, b) of reals, written a + bi.  The drone sits at
// z = 3 + 4i km from its depot; the multiplier is w = 1 + 2i.  Two roads to each
// product: the pair rule, and turn-and-add (w = c + di means c copies of z plus
// d copies of z turned a quarter left), which never calls the pair rule.
#[derive(Clone, Copy)]
struct P { re: f64, im: f64 }
fn p(re: f64, im: f64) -> P { P { re, im } }
fn add(x: P, y: P) -> P { p(x.re + y.re, x.im + y.im) }
fn scale(k: f64, x: P) -> P { p(k * x.re, k * x.im) }
fn mul(x: P, y: P) -> P {             // road one: (a + bi)(c + di) = (ac - bd) + (ad + bc)i
    p(x.re * y.re - x.im * y.im, x.re * y.im + x.im * y.re)
}
fn quarter(x: P) -> P { p(-x.im, x.re) }  // a quarter turn left: the point (a, b) goes to (-b, a)
fn turn_and_add(x: P, y: P) -> P {    // road two: c copies of x, plus d copies of x turned
    add(scale(y.re, x), scale(y.im, quarter(x)))
}
fn length(x: P) -> f64 { (x.re * x.re + x.im * x.im).sqrt() }
fn dot(x: P, y: P) -> f64 { x.re * y.re + x.im * y.im }
fn fmt(x: P) -> String {
    let (re, im) = (x.re + 0.0, x.im + 0.0);
    format!("{:.6} {} {:.6}i", re, if im < 0.0 { "-" } else { "+" }, im.abs())
}
fn near(x: P, y: P) -> bool { (x.re - y.re).abs() < 1e-12 && (x.im - y.im).abs() < 1e-12 }

fn main() {
    let (i, z, w) = (p(0.0, 1.0), p(3.0, 4.0), p(1.0, 2.0));
    let (sc, ox, oy) = (20.0, 200.0, 215.0);
    let pix = |x: P| format!("({:.0}, {:.0})", ox + sc * x.re, oy - sc * x.im);
    let (zw, zw2, iz) = (mul(z, w), turn_and_add(z, w), mul(i, z));
    let mut turns: Vec<String> = Vec::new();
    let mut q = z;
    for _ in 0..4 { q = mul(i, q); turns.push(fmt(q)); }
    let (b, c) = (2.0, 5.0);          // second case: x^2 + 2x + 5 = 0, by the quadratic formula
    let disc = b * b - 4.0 * c;
    let roots: Vec<P> = [1.0, -1.0].iter().map(|s| p(-b / 2.0, s * (-disc).sqrt() / 2.0)).collect();
    let plug: Vec<P> = roots.iter().map(|&r| add(add(mul(r, r), scale(b, r)), p(c, 0.0))).collect();
    let (left, right) = (mul(mul(z, w), i), mul(z, mul(w, i)));
    println!("figure, scale {} px per km, depot {}; z {}; iz {}; w {}; zw {}; arc radius {:.0}",
             sc, pix(p(0.0, 0.0)), pix(z), pix(iz), pix(w), pix(zw), sc * length(z));
    println!("i times i = {}", fmt(mul(i, i)));
    println!("z + w = {}; z - w = {}", fmt(add(z, w)), fmt(add(z, scale(-1.0, w))));
    println!("pair rule parts: ac = {:.6}, bd = {:.6}, ad = {:.6}, bc = {:.6}", z.re * w.re, z.im * w.im, z.re * w.im, z.im * w.re);
    println!("zw by the pair rule = {}", fmt(zw));
    println!("zw by z + 2(iz), turn and add = {}", fmt(zw2));
    println!("wz by the pair rule = {}", fmt(mul(w, z)));
    println!("iz by the pair rule = {}; by the quarter turn = {}", fmt(iz), fmt(quarter(z)));
    println!("|z| = {:.6}; |iz| = {:.6}; z dot iz = {:.6}", length(z), length(iz), dot(z, iz));
    println!("one to four quarter turns of z: {}", turns.join("; "));
    println!("on the real axis: (2 + 0i)(-3 + 0i) = {}", fmt(mul(p(2.0, 0.0), p(-3.0, 0.0))));
    println!("(zw)i = {}; z(wi) = {}", fmt(left), fmt(right));
    println!("x^2 + 2x + 5 = 0: discriminant {:.6}; roots {} and {}", disc, fmt(roots[0]), fmt(roots[1]));
    println!("root squared = {}; 2 times root = {}", fmt(mul(roots[0], roots[0])), fmt(scale(b, roots[0])));
    println!("each root put back in: {} and {}", fmt(plug[0]), fmt(plug[1]));
    println!("mistake 1, multiplying part by part: {}, not {}", fmt(p(z.re * w.re, z.im * w.im)), fmt(zw));
    println!("mistake 2, i squared taken as +1: {}, not {}",
             fmt(p(z.re * w.re + z.im * w.im, z.re * w.im + z.im * w.re)), fmt(zw));
    println!("mistake 3, turned the wrong way, (b, -a): {}, not {}", fmt(p(z.im, -z.re)), fmt(iz));
    assert!(near(zw, zw2));                                                  // two roads, one product
    assert!((length(iz) - length(z)).abs() < 1e-12 && dot(z, iz).abs() < 1e-12); // times i: same length, square corner
    assert!(plug.iter().all(|&v| near(v, p(0.0, 0.0))));                     // the formula's roots solve it
    assert!(near(left, right));                                              // grouping does not matter
    println!("ALL CHECKS PASS");
}
