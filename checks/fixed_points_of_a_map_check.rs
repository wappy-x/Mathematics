// Fixed points of a map -- the same check as the Python, in Rust.  No crates.
// The map is the logistic rule g(x) = r x (1 - x): x is this summer's population
// as a fraction of what the habitat holds.  Every fixed point and slope is found
// twice: by formula, and by pressing the map, Newton's method or measurement.
fn g(r: f64, x: f64) -> f64 { r * x * (1.0 - x) }

fn press(r: f64, mut x: f64, n: usize) -> f64 {        // apply the map n times
    for _ in 0..n { x = g(r, x) }
    x
}

fn slope(f: &dyn Fn(f64) -> f64, x: f64) -> f64 { let h = 1e-6; (f(x + h) - f(x - h)) / (2.0 * h) }

fn newton_fixed(r: f64, mut x: f64) -> (f64, usize) { // Newton's method on G(x) = g(x) - x
    for k in 1..50 {
        let step = (g(r, x) - x) / (r * (1.0 - 2.0 * x) - 1.0);
        x -= step;
        if step.abs() < 1e-15 { return (x, k) }
    }
    (x, 50)
}

fn euler(h: f64, n: usize) -> f64 {                   // Euler steps of x' = x(1 - x), step h
    let mut x = 0.2;
    for _ in 0..n { x += h * x * (1.0 - x) }
    x
}

fn ratio(r: f64) -> f64 { (g(r, 1.0 - 1.0 / r + 1e-6) - (1.0 - 1.0 / r)) / 1e-6 }  // gap after / gap before

fn join(v: &[f64], d: usize) -> String { v.iter().map(|x| format!("{:.*}", d, x)).collect::<Vec<_>>().join(", ") }

fn gaps(r: f64, n: usize) -> String {
    let xs = 1.0 - 1.0 / r;
    join(&(0..=n).map(|k| (press(r, xs + 0.02, k) - xs) * 100.0).collect::<Vec<_>>(), 2)
}

fn main() {
    let (fx28, it28) = (1.0 - 1.0 / 2.8, press(2.8, 0.2, 200));
    let (m28, m32) = (slope(&|x| g(2.8, x), fx28), slope(&|x| g(3.2, x), 0.6875));
    let win: Vec<f64> = (0..=1000).map(|i| fx28 - 0.02 + 0.04 * i as f64 / 1000.0).collect();
    let l = win.iter().map(|&x| (2.8 * (1.0 - 2.0 * x)).abs()).fold(0.0, f64::max);
    let into = win.iter().map(|&x| (g(2.8, x) - fx28).abs()).fold(0.0, f64::max);
    let (nw32, k32) = newton_fixed(3.2, 0.9);
    let (p, q) = (press(3.2, 0.2, 1000), press(3.2, 0.2, 1001));
    let (a, b) = (p.min(q), p.max(q));
    let (e, f) = (euler(2.2, 1000), euler(2.2, 1001));
    let cyc = [e.min(f), e.max(f)];
    let mut cob = vec![0.2];
    let mut nx = vec![1.0];
    for _ in 0..6 { let v = g(2.8, *cob.last().unwrap()); cob.push(v) }
    for _ in 0..4 { let v = *nx.last().unwrap(); nx.push(v / 2.0 + 1.0 / v) }
    cob.push(fx28);
    let px: Vec<f64> = cob.iter().map(|v| 50.0 + 200.0 * v).collect();
    let errs: Vec<f64> = nx[1..4].iter().map(|v| (v - 2f64.sqrt()).abs()).collect();
    println!("r = 2.8: fixed points 0 (slope r = 2.8) and 1 - 1/r = {:.12}", fx28);
    println!("r = 2.8: 200 presses of the map from x0 = 0.2 land on {:.12}", it28);
    println!("r = 2.8: slope 2 - r = {:.6}; measured by central difference {:.6}; gap ratio {:.6}", 2.0 - 2.8, m28, ratio(2.8));
    println!("r = 2.8: window x* +/- 0.02: largest |slope| {:.6} (formula 0.8 + 2r(0.02) = {:.6}); largest |g(x) - x*| {:.6}", l, 0.8 + 5.6 * 0.02, into);
    println!("r = 3.2: fixed point 1 - 1/r = {:.12}; Newton on g(x) - x from 0.9, {} steps: {:.12}", 1.0 - 1.0 / 3.2, k32, nw32);
    println!("r = 3.2: slope 2 - r = {:.6}; measured by central difference {:.6}; gap ratio {:.6}", 2.0 - 3.2, m32, ratio(3.2));
    println!("r = 3.2: presses 1000 and 1001 from 0.2 alternate {:.6} and {:.6}, not 0.687500", a, b);
    println!("r = 3.0: slope -1; gap after 1000 presses from 0.2 {:.6}, after 4000 {:.6}",
             (press(3.0, 0.2, 1000) - 2.0 / 3.0).abs(), (press(3.0, 0.2, 4000) - 2.0 / 3.0).abs());
    println!("chart, gap in hundredths, r = 2.8: {}", gaps(2.8, 12));
    println!("chart, gap in hundredths, r = 3.2: {}", gaps(3.2, 12));
    println!("figure, cobweb x0..x6 and x* at r = 2.8: {} | px 50 + 200x: {}", join(&cob, 4), join(&px, 1));
    let curve: Vec<f64> = (0..=10).map(|i| 220.0 - 200.0 * g(2.8, i as f64 / 10.0)).collect();
    println!("figure, curve y = g(x) at x = 0, 0.1, ..., 1, px 220 - 200y: {}", join(&curve, 1));
    println!("Newton for x^2 = 2 from 1: {}", join(&nx[1..], 12));
    println!("Newton map x/2 + 1/x: slope at sqrt 2 measured {:.6}; errors {}", slope(&|t| t / 2.0 + 1.0 / t, 2f64.sqrt()).abs(), join(&errs, 9));
    println!("Newton for (x - 1)^2 = 0: map (x + 1)/2, slope measured {:.6}", slope(&|t| t - (t - 1.0) / 2.0, 1.0));
    println!("Euler steps of x' = x(1 - x): h = 1.8 lands on {:.6}; h = 2.2 alternates {:.6}, {:.6}", euler(1.8, 200), cyc[0], cyc[1]);
    println!("mistake, slope read at x0 = 0.2 instead of x*: 2.8(1 - 0.4) = {:.6}", 2.8 * (1.0 - 0.4));
    assert!((it28 - fx28).abs() < 1e-12 && (nw32 - 0.6875).abs() < 1e-12);    // iteration and Newton find the formula's points
    assert!((ratio(2.8) - (2.0 - 2.8)).abs() < 1e-4 && (m32 - (2.0 - 3.2)).abs() < 1e-6); // measured slopes match 2 - r
    assert!(l < 1.0 && (l - 0.912).abs() < 1e-9 && into < 0.02 && (b - 0.6875).abs() > 0.1); // window contracts at 2.8; 3.2 lets go
    assert!((cyc[0] - a * 3.2 / 2.2).abs() + (cyc[1] - b * 3.2 / 2.2).abs() < 1e-9 && (euler(1.8, 200) - 1.0).abs() < 1e-9);
    println!("ALL CHECKS PASS");
}
