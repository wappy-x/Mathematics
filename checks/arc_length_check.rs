// Arc length -- the same check as the Python, in Rust.  No crates; sqrt and
// ln are primitives, and every sum below is written out here.
// A suspension cable hangs as the parabola y = x^2 / 1000 between towers at
// x = -200 and x = 200 m: span 400 m, sag 40 m.  Its length, three roads.
const S: f64 = 400.0; // span, metres
const D: f64 = 40.0; // sag, metres
const A: f64 = -S / 2.0;
const B: f64 = S / 2.0;

fn f(x: f64) -> f64 { 4.0 * D * x * x / (S * S) } // height above the low point
fn fp(x: f64) -> f64 { 8.0 * D * x / (S * S) } // slope, metres per metre

fn step(x: f64) -> f64 { if x >= 0.0 { D } else { 0.0 } } // a 40 m jump at midspan

fn polygon(n: usize, g: &dyn Fn(f64) -> f64) -> f64 { // road one: n straight chords
    let xs: Vec<f64> = (0..=n).map(|i| A + (B - A) * i as f64 / n as f64).collect();
    (1..=n).map(|i| ((xs[i] - xs[i - 1]).powi(2) + (g(xs[i]) - g(xs[i - 1])).powi(2)).sqrt()).sum()
}

fn simpson(g: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 { // road two
    let h = (b - a) / n as f64;
    let mut s = g(a) + g(b);
    for i in 1..n {
        s += if i % 2 == 1 { 4.0 } else { 2.0 } * g(a + i as f64 * h);
    }
    s * h / 3.0
}

fn main() {
    let k = 8.0 * D / (S * S); // slope per metre of x: 1/500
    let u = k * B; // slope at the tower: 0.4
    let exact = (u * (1.0 + u * u).sqrt() + (u + (1.0 + u * u).sqrt()).ln()) / k; // road three
    let graph = simpson(&|x| (1.0 + fp(x).powi(2)).sqrt(), A, B, 100);
    let param = simpson(&|t| ((S / 2.0).powi(2) + (2.0 * D * t).powi(2)).sqrt(), -1.0, 1.0, 100);

    let r = (1.0 + u * u).sqrt();
    println!("span {:.0} m, sag {:.0} m, cable y = x^2/1000, slope x/500, at the tower {:.1}", S, D, u);
    println!("sqrt(1.16) = {:.6}; 0.4 x it = {:.6}; asinh 0.4 = ln({:.6}) = {:.6}; sum {:.6}",
             r, u * r, u + r, (u + r).ln(), u * r + (u + r).ln());
    println!("closed form, 500 x (0.4 x sqrt(1.16) + asinh 0.4): {:.6} m", exact);
    println!("Simpson on sqrt(1 + f'(x)^2), 100 strips: {:.6} m", graph);
    println!("Simpson on the speed of x = 200t, y = 40t^2, 100 strips: {:.6} m", param);
    let mut lengths: Vec<f64> = Vec::new();
    for n in [1, 2, 4, 8, 16, 32, 64] {
        lengths.push(polygon(n, &f));
        let p = lengths[lengths.len() - 1];
        println!("chords {:4}: polygon {:.2} m, short by {:.4} m", n, p, exact - p);
    }
    println!("mistake 1, integrate |slope| only: {:.3} m", simpson(&|x| fp(x).abs(), A, B, 100));
    println!("mistake 2, drop the square root: {:.3} m", simpson(&|x| 1.0 + fp(x).powi(2), A, B, 100));
    println!("no jumps dropped, a {:.0} m step at midspan: formula (slope 0) {:.2} m, 1024 chords {:.2} m",
             D, S, polygon(1024, &step));
    println!("rule of thumb s + 8d^2/(3s): {:.3} m", S + 8.0 * D * D / (3.0 * S));
    let pts: Vec<String> = [-200.0, -100.0, 0.0, 100.0, 200.0].iter()
        .map(|&x: &f64| format!("({:.1},{:.1})", 180.0 + 0.8 * x, 150.0 - 0.8 * f(x))).collect();
    println!("figure, 0.8 units per m, chord points: {}", pts.join(" "));
    assert!((graph - exact).abs() < 1e-7); // road two against road three
    assert!((param - exact).abs() < 1e-7); // a new clock, the same length
    let mut climb = lengths.clone();
    climb.push(exact);
    assert!(climb.windows(2).all(|w| w[0] < w[1])); // chords climb, stay under
    let gap = exact - polygon(1024, &f);
    assert!(gap > 0.0 && gap < 1e-4); // road one closes the gap, from below
    println!("ALL CHECKS PASS");
}
