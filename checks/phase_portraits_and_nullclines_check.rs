// Phase portraits and nullclines -- the same check as the Python, in Rust, no crates.  Gazelles x
// (hundreds), cheetahs y (tens), years: x' = x(1 - y), y' = y(x - 1).  Road one: signs of the
// rates.  Road two: Runge-Kutta 4.  Referee: the conserved V.
fn f(x: f64, y: f64) -> f64 { x * (1.0 - y) }                 // gazelle rate, hundreds per year
fn g(x: f64, y: f64) -> f64 { y * (x - 1.0) }                 // cheetah rate, tens per year
fn crowd(x: f64, y: f64) -> f64 { x * (1.0 - y - 0.2 * x) }   // gazelles that crowd themselves
fn v(x: f64, y: f64) -> f64 { x - x.ln() + y - y.ln() }       // constant along every orbit
fn sg(a: f64) -> &'static str { if a > 0.0 { "+" } else if a < 0.0 { "-" } else { "0" } }
fn reg(x: f64, y: f64) -> String { format!("{}{}", if y > 1.0 { "N" } else { "S" }, if x > 1.0 { "E" } else { "W" }) }
fn p(x: f64, y: f64) -> String { format!("{:.1},{:.1}", 50.0 + 70.0 * x, 205.0 - 70.0 * y) }  // 70 px a unit
fn rk4(x: f64, y: f64, h: f64, ff: fn(f64, f64) -> f64) -> (f64, f64) {
    let k = |a: f64, b: f64| (ff(a, b), g(a, b));             // the two rates at one point
    let (a1, b1) = k(x, y); let (a2, b2) = k(x + h * a1 / 2.0, y + h * b1 / 2.0);
    let (a3, b3) = k(x + h * a2 / 2.0, y + h * b2 / 2.0); let (a4, b4) = k(x + h * a3, y + h * b3);
    (x + h * (a1 + 2.0 * a2 + 2.0 * a3 + a4) / 6.0, y + h * (b1 + 2.0 * b2 + 2.0 * b3 + b4) / 6.0)
}
fn run(h: f64, t: f64, ff: fn(f64, f64) -> f64, mut x: f64, mut y: f64) -> (f64, f64) {
    for _ in 0..(t / h).round() as usize { (x, y) = rk4(x, y, h, ff) }
    (x, y)
}
fn root(mut lo: f64, mut hi: f64, c: f64) -> f64 {           // bisection on u - ln u = c
    for _ in 0..80 {
        let mid = (lo + hi) / 2.0;
        if (mid - mid.ln() > c) == (lo - lo.ln() > c) { lo = mid } else { hi = mid }
    }
    lo
}
fn main() {
    let (mut x, mut y, mut t, mut ok) = (2.0f64, 1.0f64, 0.0f64, true);
    let (mut seen, mut when, mut bx, mut pts) = (vec!["NE".to_string()], vec![], [2.0f64, 2.0, 1.0, 1.0], vec![p(2.0, 1.0)]);
    while seen.len() < 5 {                                    // road two: one full turn from (2, 1)
        let (nx, ny) = rk4(x, y, 0.01, f);
        if reg(nx, ny) == reg(x, y) { ok = ok && format!("{}{}", sg(nx - x), sg(ny - y)) == format!("{}{}", sg(f(x, y)), sg(g(x, y))) }
        else if t > 0.0 {
            let s = if (x > 1.0) != (nx > 1.0) { (1.0 - x) / (nx - x) } else { (1.0 - y) / (ny - y) };
            seen.push(reg(nx, ny)); when.push(t + s * 0.01);
        }
        (x, y, t) = (nx, ny, t + 0.01);
        bx = [bx[0].min(x), bx[1].max(x), bx[2].min(y), bx[3].max(y)];
        if (t * 100.0).round() as i64 % 25 == 0 { pts.push(p(x, y)) }
    }
    let tests = [(2.0, 0.5), (2.0, 2.0), (0.5, 2.0), (0.5, 0.5)];
    let mixed: Vec<(i32, i32)> = [(0, 0), (1, 0), (0, 1), (1, 1)].into_iter().filter(|&(a, b)| (a == 0 || b == 1) && (b == 0 || a == 1)).collect();
    let mut grid = vec![];
    for i in 0..301 { for j in 0..301 { let (a, b) = (i as f64 / 100.0, j as f64 / 100.0); if f(a, b) == 0.0 && g(a, b) == 0.0 { grid.push((a, b)) } } }
    let ms: Vec<String> = mixed.iter().map(|(a, b)| format!("({}, {})", a, b)).collect();
    let gs: Vec<String> = grid.iter().map(|(a, b)| format!("({:.1}, {:.1})", a, b)).collect();
    println!("x' = x(1 - y), y' = y(x - 1); x-nullclines x = 0 and y = 1; y-nullclines y = 0 and x = 1");
    println!("rests at mixed crossings: [{}]; by grid scan of 301 x 301 points: [{}]", ms.join(", "), gs.join(", "));
    println!("same-kind crossing (0, 1): x' = {:.3}, y' = {:.3}; (1, 0): x' = {:.3}, y' = {:.3}", f(0.0, 1.0), g(0.0, 1.0), f(1.0, 0.0), g(1.0, 0.0));
    for (a, b) in tests {
        println!("region {}, test point ({}, {}): x' = {:+.3}, y' = {:+.3}, signs {}{}", reg(a, b), a, b, f(a, b), g(a, b), sg(f(a, b)), sg(g(a, b)));
    }
    println!("start (2, 1) on the x-nullcline: x' = {:.3}, y' = {:.3}, straight up", f(2.0, 1.0), g(2.0, 1.0));
    println!("RK4 h = 0.01, regions in order: {}; every step's signs match its region: {}", seen.join(" "), if ok { "yes" } else { "no" });
    let ws: Vec<String> = when.iter().map(|w| format!("{:.3}", w)).collect();
    println!("crossing times (years): {}; one turn T = {:.3}", ws.join(" "), when[3]);
    println!("extremes by RK4: x {:.4} to {:.4}, y {:.4} to {:.4}; V = {:.4}", bx[0], bx[1], bx[2], bx[3], v(2.0, 1.0));
    let (lo, hi) = (root(0.01, 1.0, v(2.0, 1.0) - 1.0), root(1.0, 10.0, v(2.0, 1.0) - 1.0));
    println!("ln 2 = {:.4}; bisection on u - ln u = {:.4}: low {:.4}, high {:.4}", 2f64.ln(), v(2.0, 1.0) - 1.0, lo, hi);
    let rf = run(0.001, 2.0, f, 2.0, 1.0);                    // a fine run is the yardstick for step-size error
    let e: Vec<f64> = [0.2, 0.1].iter().map(|&h| { let (a, b) = run(h, 2.0, f, 2.0, 1.0); ((a - rf.0).powi(2) + (b - rf.1).powi(2)).sqrt() }).collect();
    println!("error at t = 2 against h = 0.001, in millionths: h = 0.2 {:.3}, h = 0.1 {:.3}, ratio {:.1}", e[0] * 1e6, e[1] * 1e6, e[0] / e[1]);
    let (dx, dy) = run(0.01, 20.0, crowd, 2.0, 0.8);
    let far = ((dx - 1.0).powi(2) + (dy - 0.8).powi(2)).sqrt();
    println!("crowded gazelles x' = x(1 - y - 0.2x): distance to rest (1, 0.8) from 1.000 to {:.3} after 20 years", far);
    println!("figure, loop at 70 px a unit: {}", pts.join(" "));
    let ar: Vec<String> = tests.iter().map(|&(a, b)| { let r = (f(a, b).powi(2) + g(a, b).powi(2)).sqrt();
        format!("{}>{}", p(a, b), p(a + 0.3 * f(a, b) / r, b + 0.3 * g(a, b) / r)) }).collect();   // 0.3-unit arrows
    println!("figure, arrows: {}", ar.join(" "));
    let cs: Vec<(f64, f64)> = (0..15).map(|k| run(0.01, k as f64 / 2.0, f, 2.0, 1.0)).collect();
    println!("chart, gazelles: {}", cs.iter().map(|c| format!("{:.2}", c.0)).collect::<Vec<_>>().join(", "));
    println!("chart, cheetahs: {}", cs.iter().map(|c| format!("{:.2}", c.1)).collect::<Vec<_>>().join(", "));
    assert!(grid == mixed.iter().map(|&(a, b)| (a as f64, b as f64)).collect::<Vec<_>>());   // two roads to the rests
    assert!(seen == ["NE", "NW", "SW", "SE", "NE"] && ok);                                     // the flow follows the sign table
    assert!((bx[0] - lo).abs().max((bx[2] - lo).abs()).max((bx[1] - hi).abs()).max((bx[3] - hi).abs()) < 1e-4);   // on V's level
    assert!(12.0 < e[0] / e[1] && e[0] / e[1] < 20.0 && far < 0.3);                          // order 4; crowding spirals in
    println!("ALL CHECKS PASS");
}
