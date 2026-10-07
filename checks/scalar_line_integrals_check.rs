// Line integral of a function -- the same check as the Python, in Rust.  No
// crates; sqrt is a primitive, and every sum below is written out here.
// A wire bent along y = x^2 / 2 from x = 1 to x = 2 m.  Its density is 3x kg/m,
// rising from 3 at the near end to 6 at the far end.  Its mass, two roads.
fn rho(x: f64, _y: f64) -> f64 { 3.0 * x } // density, kg per metre
fn y_of(x: f64) -> f64 { x * x / 2.0 } // the wire's shape
fn sign(t: f64) -> f64 { if t > 0.0 { -1.0 } else { 1.0 } } // out to the far end, then back

fn simpson(g: &dyn Fn(f64) -> f64, a: f64, b: f64) -> f64 { // Simpson's rule, 200 strips
    let n = 200;
    let h = (b - a) / n as f64;
    let mut s = g(a) + g(b);
    for i in 1..n {
        s += if i % 2 == 1 { 4.0 } else { 2.0 } * g(a + i as f64 * h);
    }
    s * h / 3.0
}

type F = dyn Fn(f64) -> f64;
fn line_integral(x: &F, y: &F, dx: &F, dy: &F, a: f64, b: f64) -> f64 { // density times speed
    simpson(&|t| rho(x(t), y(t)) * (dx(t).powi(2) + dy(t).powi(2)).sqrt(), a, b)
}

fn pieces(n: usize) -> f64 { // road two: the definition itself
    let xs: Vec<f64> = (0..=n).map(|i| 1.0 + i as f64 / n as f64).collect();
    xs.windows(2).map(|w| {
        let (p, q) = (w[0], w[1]);
        let chord = ((q - p).powi(2) + (y_of(q) - y_of(p)).powi(2)).sqrt();
        let m = (p + q) / 2.0;
        rho(m, y_of(m)) * chord // density at the middle, times chord
    }).sum()
}

fn main() {
    let exact = 5f64.powf(1.5) - 2f64.powf(1.5); // (1 + x^2)^(3/2) from x = 1 to 2
    let by_x = line_integral(&|t| t, &|t| t * t / 2.0, &|_| 1.0, &|t| t, 1.0, 2.0);
    let by_u = line_integral(&|u: f64| u.sqrt(), &|u| u / 2.0,
                             &|u: f64| 1.0 / (2.0 * u.sqrt()), &|_| 0.5, 1.0, 4.0);
    let back = line_integral(&|s| 3.0 - s, &|s| (3.0 - s).powi(2) / 2.0,
                             &|_| -1.0, &|s| -(3.0 - s), 1.0, 2.0);
    let twice = line_integral(&|t: f64| 2.0 - t.abs(), &|t: f64| (2.0 - t.abs()).powi(2) / 2.0,
                              &sign, &|t: f64| (2.0 - t.abs()) * sign(t), -1.0, 1.0);
    let length = simpson(&|t| (1.0 + t * t).sqrt(), 1.0, 2.0);
    println!("wire y = x^2/2 from x = 1 to 2 m; density 3x: 3.0 kg/m at the near end, 6.0 at the far end");
    println!("closed form 5^1.5 - 2^1.5 = {:.6} - {:.6} = {:.6} kg", 5f64.powf(1.5), 2f64.powf(1.5), exact);
    println!("clock x = t, t from 1 to 2, speed sqrt(1 + t^2): {:.6} kg", by_x);
    println!("clock x = sqrt(u), u from 1 to 4, speed sqrt(1 + u)/(2 sqrt u): {:.6} kg", by_u);
    println!("reversed, x = 3 - s, s from 1 to 2, far end first: {:.6} kg", back);
    for n in [1, 4, 16, 64, 256] {
        println!("pieces {:5}: density x chord {:.6} kg, off by {:+.6}", n, pieces(n), pieces(n) - exact);
    }
    println!("wire length (density 1): {:.6} m; average density {:.4} kg/m", length, exact / length);
    println!("mistake, drop the speed (density x dx): {:.6} kg", simpson(&|t| rho(t, y_of(t)), 1.0, 2.0));
    println!("mistake, signed length when reversed: {:.6} kg",
             simpson(&|t| rho(t, y_of(t)) * (1.0 + t * t).sqrt(), 2.0, 1.0));
    println!("mistake, a clock that runs out and back: {:.6} kg", twice);
    let pt = |x: f64| format!("{:.1},{:.1}", 40.0 + 100.0 * x, 220.0 - 100.0 * y_of(x));
    let curve: Vec<String> = (0..=10).map(|i| pt(1.0 + i as f64 / 10.0)).collect();
    let chords: Vec<String> = (0..=4).map(|i| pt(1.0 + i as f64 / 4.0)).collect();
    println!("figure, 100 units per m, curve: {}", curve.join(" "));
    println!("figure, chord points: {}", chords.join(" "));
    assert!((by_x - exact).abs() < 1e-9); // the formula against the antiderivative
    assert!((by_u - exact).abs() < 1e-9); // a new clock, the same mass
    assert!((back - exact).abs() < 1e-9); // the other direction, the same mass
    assert!((pieces(256) - exact).abs() < 1e-5); // the definition closes in on it
    println!("ALL CHECKS PASS");
}
