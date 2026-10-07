// Inverting by partial fractions -- the same check as the Python, in Rust.  No
// crates.  Case 1: the car released from 1 cm, Y = (s + 2)/(s^2 + 2s + 5).
// Case 2: a steady push, Y = 5/(s(s^2 + 2s + 5)).  Road one completes the
// square and reads the table.  Road two splits over the complex roots by
// cover-up.  Road three transforms road one's answer forward.
use std::f64::consts::PI;
const P: f64 = 2.0; const Q: f64 = 5.0;              // the denominator s^2 + P s + Q
type C = (f64, f64);                                 // a complex number, (real, imaginary)

fn mul(x: C, y: C) -> C { (x.0 * y.0 - x.1 * y.1, x.0 * y.1 + x.1 * y.0) }
fn div(x: C, y: C) -> C { let d = y.0 * y.0 + y.1 * y.1; ((x.0 * y.0 + x.1 * y.1) / d, (x.1 * y.0 - x.0 * y.1) / d) }

fn square(al: f64, be: f64) -> (f64, f64, f64, f64) { // road one: (al s + be) over the square
    let a = P / 2.0; let w = (Q - a * a).sqrt();     // (s + a)^2 + w^2
    (a, w, al, (be - al * a) / w)                    // e^(-at)(C cos wt + D sin wt)
}

fn cover_up(num: &dyn Fn(C) -> C, poles: &[C]) -> Vec<(C, C)> { // road two: residue at each pole
    poles.iter().map(|&p| {
        let d = poles.iter().filter(|&&q| q != p).fold((1.0, 0.0), |acc, &q| mul(acc, (p.0 - q.0, p.1 - q.1)));
        (p, div(num(p), d))
    }).collect()
}

fn at(terms: &[(C, C)], t: f64) -> f64 {              // sum of r e^(pt): its real part
    terms.iter().map(|&(p, r)| mul(r, ((p.1 * t).cos(), (p.1 * t).sin())).0 * (p.0 * t).exp()).sum()
}

fn simpson(f: &dyn Fn(f64) -> f64, s: f64) -> f64 { // road three: integral of e^(-st) f(t)
    let (n, h) = (4000usize, 40.0 / 4000.0);
    h / 3.0 * (0..=n).map(|k| {
        let wt = if k == 0 || k == n { 1.0 } else if k % 2 == 1 { 4.0 } else { 2.0 };
        wt * (-s * k as f64 * h).exp() * f(k as f64 * h)
    }).sum::<f64>()
}

fn main() {
    let disc = P * P - 4.0 * Q;                      // quadratic formula, complex square root
    let root: C = if disc < 0.0 { (-P / 2.0, (-disc).sqrt() / 2.0) } else { ((-P + disc.sqrt()) / 2.0, 0.0) };
    let poles = [root, (root.0, -root.1)];
    let grid: Vec<f64> = (0..=400).map(|k| k as f64 * 0.01).collect();
    let (a, w, c, d) = square(1.0, 2.0);
    println!("discriminant P^2 - 4Q = {}: no real roots; completed square (s + {})^2 + {}", disc, a, w * w);
    let y1 = move |t: f64| (-a * t).exp() * (c * (w * t).cos() + d * (w * t).sin());
    let terms1 = cover_up(&|s: C| (s.0 + 2.0, s.1), &poles);
    let r1 = terms1[0].1;
    println!("case 1, completed square: shift a = {}, w = {}, cos coefficient {:.6}, sin coefficient {:.6}", a, w, c, d);
    println!("case 1, cover-up at {}{:+}i: residue {:.6} {:+.6}i, so cos {:.6}, sin {:.6}",
             root.0, root.1, r1.0, r1.1, 2.0 * r1.0, -2.0 * r1.1);
    let gap1 = grid.iter().map(|&t| (y1(t) - at(&terms1, t)).abs()).fold(0.0, f64::max);
    let low = grid[50..301].iter().copied().fold(0.5, |b, t| if y1(t) < y1(b) { t } else { b });
    println!("case 1, forward transform at s = 2: {:.6} against Y(2) = 4/13 = {:.6}", simpson(&y1, 2.0), 4.0 / 13.0);
    println!("case 1 in the car: y(0) = {:.6} cm, y(0.5) = {:.6} cm, lowest {:.6} cm at t = {:.2} s", y1(0.0), y1(0.5), y1(low), low);
    let big_a = 5.0 / Q;                             // cover-up at the real pole s = 0
    let (a2, w2, c2, d2) = square(-big_a, -big_a * P); // leftover (5 - A D(s))/s = -A s - A P
    let y2 = move |t: f64| big_a + (-a2 * t).exp() * (c2 * (w2 * t).cos() + d2 * (w2 * t).sin());
    let terms2 = cover_up(&|_s: C| (5.0, 0.0), &[(0.0, 0.0), poles[0], poles[1]]);
    let gap2 = grid.iter().map(|&t| (y2(t) - at(&terms2, t)).abs()).fold(0.0, f64::max);
    println!("case 2, cover-up at s = 0: A = {:.6}; leftover ({:.6} s {:+.6})/(s^2 + 2s + 5)", big_a, -big_a, -big_a * P);
    println!("case 2, so y = {} - e^(-t)(cos 2t + {:.1} sin 2t); forward transform at s = 2: {:.6} against 5/26 = {:.6}",
             big_a, d2 / c2, simpson(&y2, 2.0), 5.0 / 26.0);
    let word = |g: f64| if g < 1e-12 { "below" } else { "ABOVE" };
    println!("roads one and two, largest gap on 0 to 4 s: case 1 {} 1e-12, case 2 {} 1e-12", word(gap1), word(gap2));
    println!("mistake 1, e^(+t) for (s + 1): y(0.5) = {:.6}, not {:.6}", 0.5f64.exp() * (1f64.cos() + 0.5 * 1f64.sin()), y1(0.5));
    println!("mistake 2, s + 2 left whole over the square: y(0.5) = {:.6}", (-0.5f64).exp() * 1f64.cos());
    println!("mistake 3, sin entry without dividing by w: y(0.5) = {:.6}", (-0.5f64).exp() * (1f64.cos() + 1f64.sin()));
    let ts: Vec<f64> = (0..16).map(|k| k as f64 * 0.25).collect();
    let row = |f: &dyn Fn(f64) -> f64| ts.iter().map(|&t| format!("{:5.2}", f(t))).collect::<Vec<_>>().join(" ");
    println!("figure, t     {}", row(&|t| t));
    println!("figure, cos   {}", row(&|t: f64| (-t).exp() * (2.0 * t).cos()));
    println!("figure, sin   {}", row(&|t: f64| 0.5 * (-t).exp() * (2.0 * t).sin()));
    println!("figure, y     {}", row(&y1));
    assert!(gap1 < 1e-12 && gap2 < 1e-12);                           // square + table = cover-up
    assert!((simpson(&y1, 2.0) - 4.0 / 13.0).abs() < 1e-7);          // the answer transforms back
    assert!((simpson(&y2, 2.0) - 5.0 / 26.0).abs() < 1e-7);
    assert!((low - PI / 2.0).abs() < 0.01 && (y1(low) + (-PI / 2.0).exp()).abs() < 1e-4); // the shelf-3 dip
    println!("ALL CHECKS PASS");
}
