// Characteristics -- the same check in Rust, std only.  A bunch of cars,
// density rho0(x) = 40 e^(-x^2) cars/km, rides a one-lane road at 50 km/h and
// slows to 30 km/h through a work zone.  Road 1 is the closed form along
// characteristics; road 2 steps the characteristic ODEs by RK4; road 3 puts the
// answer back into the PDE by centred differences and counts the cars.
fn rho0(a: f64) -> f64 { 40.0 * (-a * a).exp() }          // cars/km at t = 0, at label a km
fn v(x: f64) -> f64 { if x <= 2.0 { 50.0 } else if x <= 3.0 { 50.0 - 20.0 * (x - 2.0) } else { 30.0 } }
fn ramp() -> f64 { (5.0f64 / 3.0).ln() / 20.0 }         // hours to cross the ramp, 2 to 3 km

fn clock(x: f64) -> f64 {                                 // hours to drive from 2 km to x km
    if x <= 2.0 { (x - 2.0) / 50.0 } else if x <= 3.0 { (50.0 / v(x)).ln() / 20.0 } else { ramp() + (x - 3.0) / 30.0 }
}
fn unclock(t: f64) -> f64 {                               // the place reached after t hours
    if t <= 0.0 { 2.0 + 50.0 * t } else if t <= ramp() { 2.0 + 2.5 * (1.0 - (-20.0 * t).exp()) } else { 3.0 + 30.0 * (t - ramp()) }
}
fn label(x: f64, t: f64) -> f64 { unclock(clock(x) - t) } // where the car at (x, t) began
fn rho(x: f64, t: f64) -> f64 { let a = label(x, t); rho0(a) * v(a) / v(x) }   // rho * v rides along

fn ride(a: f64, x_end: f64, n: usize) -> (f64, f64) {     // road 2: RK4 in x along the path
    let (mut t, mut r) = (0.0, rho0(a));
    let mut pts = vec![a];
    for b in [2.0, 3.0] { if a < b && b < x_end { pts.push(b) } }
    pts.push(x_end);
    for w in pts.windows(2) {
        let (x0, x1) = (w[0], w[1]);
        let s = if 2.0 <= x0 && x0 < 3.0 { -20.0 } else { 0.0 };   // slope of v on the piece
        let h = (x1 - x0) / n as f64;
        let f = |x: f64, r: f64| (1.0 / v(x), -s * r / v(x));     // dt/dx = 1/v, drho/dx = -v' rho / v
        for i in 0..n {
            let x = x0 + i as f64 * h;
            let k1 = f(x, r); let k2 = f(x + h / 2.0, r + h * k1.1 / 2.0);
            let k3 = f(x + h / 2.0, r + h * k2.1 / 2.0); let k4 = f(x + h, r + h * k3.1);
            t += h * (k1.0 + 2.0 * k2.0 + 2.0 * k3.0 + k4.0) / 6.0;
            r += h * (k1.1 + 2.0 * k2.1 + 2.0 * k3.1 + k4.1) / 6.0;
        }
    }
    (t, r)
}

fn shoot(x: f64, t: f64, n: usize) -> (f64, f64) {        // bisection: the label that arrives on time
    let (mut lo, mut hi, mut m) = (-3.0, x, 0.0);
    for _ in 0..60 {
        m = (lo + hi) / 2.0;
        if ride(m, x, n).0 > t { lo = m } else { hi = m }
    }
    (m, ride(m, x, n).1)
}

fn res(f: &dyn Fn(f64, f64) -> f64, x: f64, t: f64, h: f64) -> f64 {   // rho_t + (v rho)_x
    (f(x, t + h) - f(x, t - h)) / (2.0 * h) + (v(x + h) * f(x + h, t) - v(x - h) * f(x - h, t)) / (2.0 * h)
}
fn c(r: f64) -> f64 { 60.0 - 0.8 * r }                    // quasilinear: speed of a density value
fn qlabel(x: f64, t: f64) -> f64 {                        // bisection on a + c(rho0(a)) t = x
    let (mut lo, mut hi, mut m) = (x - 60.0 * t, x - 28.0 * t, 0.0);
    for _ in 0..60 {
        m = (lo + hi) / 2.0;
        if m + c(rho0(m)) * t < x { lo = m } else { hi = m }
    }
    m
}
fn q(x: f64, t: f64) -> f64 { rho0(qlabel(x, t)) }

fn main() {
    let (xq, tq) = (4.0, 0.1);
    let a = label(xq, tq);
    let ans = rho(xq, tq);
    println!("ramp crossing time ln(5/3)/20 = {:.6} h = {:.4} min", ramp(), 60.0 * ramp());
    println!("work zone, x = {} km, t = {} h: label a = {:.4} km, rho0(a) = {:.4} cars/km", xq, tq, a, rho0(a));
    println!("trace back: {:.6} h in the zone, {:.6} h on the ramp, {:.6} h before it", (xq - 3.0) / 30.0, ramp(), tq - (xq - 3.0) / 30.0 - ramp());
    println!("road 1, closed form rho0(a) * 50/30 = {:.4} cars/km", ans);
    for n in [5, 10] {
        let (m, r) = shoot(xq, tq, n);
        println!("road 2, RK4 {} steps per piece + bisection: label {:.6} km, rho {:.6} cars/km", n, m, r);
    }
    println!("flow carried along: {:.2} cars/h at the start, {:.2} cars/h in the zone", rho0(a) * 50.0, ans * 30.0);
    let wrong = |x: f64, t: f64| rho0(label(x, t));       // mistake: value constant along the path
    let (r1, r2) = (res(&rho, 2.5, 0.05, 0.002), res(&rho, 2.5, 0.05, 0.001));
    println!("road 3, residual on the ramp at 2.5 km, 0.05 h: h = 0.002 {:+.6}, h = 0.001 {:+.6}, ratio {:.2}", r1, r2, r1 / r2);
    let rw = res(&wrong, 2.5, 0.05, 0.001);
    println!("same residual for rho0(label), the zero-R mistake: {:+.2} cars/km/h", rw);
    let cars = |t: f64| 0.002 * (0..9001).map(|i| rho(-6.0 + 0.002 * i as f64, t)).sum::<f64>();
    let sp = std::f64::consts::PI.sqrt();
    println!("cars on the road: 40 sqrt(pi) = {:.4}; summed at t = 0: {:.4}, at t = 0.1 h: {:.4}", 40.0 * sp, cars(0.0), cars(0.1));
    let w0 = 2.0 * 2f64.ln().sqrt();
    let (wl, wr) = (unclock(clock(-w0 / 2.0) + tq), unclock(clock(w0 / 2.0) + tq));
    let xm = unclock(clock(0.0) + tq);                    // the bunch's middle, label 0, at tq
    println!("half-height width: {:.4} km at t = 0, {:.4} km at t = 0.1 h; middle at {:.4} km, peak {:.4} cars/km", w0, wr - wl, xm, rho(xm, tq));
    println!("mistake 1, R dropped: rho0(a) = {:.4} cars/km, not {:.4}", wrong(xq, tq), ans);
    println!("mistake 2, zone ignored, shift at 50 km/h: rho0(4 - 5) = {:.4} cars/km, not {:.4}", rho0(xq - 50.0 * tq), ans);
    let j = |p: f64, qq: f64, dx: f64, dt: f64| p * dt - qq * dx;   // data curve against the characteristic
    println!("J = P t0' - Q x0': start line {:.0}, counter at 0 km {:.0}, probe car {:.0}", j(50.0, 1.0, 1.0, 0.0), j(50.0, 1.0, 0.0, 1.0), j(50.0, 1.0, 50.0, 1.0));
    let g = |t: f64| rho0(-50.0 * t);                     // what the counter at 0 km records
    println!("counter read back, x = 1 km, t = 0.03 h: g(t - x/50) = {:.4}, rho0(x - 50t) = {:.4} cars/km", g(0.03 - 1.0 / 50.0), rho0(1.0 - 50.0 * 0.03));
    let (pa, pb) = (rho0(1.0 - 50.0 * 0.0), 40.0);         // two solutions with the probe's data
    println!("mistake 3, probe reads 40 cars/km: 40 e^(-(x-50t)^2) gives {:.4} at 1 km, 0 h; constant 40 gives {:.4}", pa, pb);
    println!("at 40 cars/km: car speed 60(1 - 40/150) = {:.4} km/h, the density value moves at c = {:.4} km/h", 60.0 * (1.0 - 40.0 / 150.0), c(40.0));
    println!("trap, car speed used for c: after 0.02 h the 40 cars/km value sits at {:.4} km, not {:.4} km, {:.4} km too far ahead",
        c(40.0) * 0.02, 60.0 * (1.0 - 40.0 / 150.0) * 0.02, (60.0 * (1.0 - 40.0 / 150.0) - c(40.0)) * 0.02);
    let qa = qlabel(1.0, 0.02);
    println!("quasilinear, x = 1 km, t = 0.02 h: label {:.4} km, rho {:.4} cars/km, speed c {:.4} km/h", qa, q(1.0, 0.02), c(q(1.0, 0.02)));
    let qr = |h: f64| (q(1.0, 0.02 + h) - q(1.0, 0.02 - h)) / (2.0 * h) + c(q(1.0, 0.02)) * (q(1.0 + h, 0.02) - q(1.0 - h, 0.02)) / (2.0 * h);
    println!("residual rho_t + c(rho) rho_x: h = 0.002 {:+.6}, h = 0.001 {:+.6}", qr(0.002), qr(0.001));
    let l: Vec<f64> = (0..6001).map(|i| -3.0 + i as f64 / 1000.0).collect();
    let cc: Vec<f64> = l.iter().map(|&a| c(rho0(a))).collect();
    let tc = (0..6000).filter(|&i| cc[i] > cc[i + 1]).map(|i| (l[i + 1] - l[i]) / (cc[i] - cc[i + 1])).fold(f64::INFINITY, f64::min);
    let tf = 1.0 / (0.8 * 40.0 * 2f64.sqrt() * (-0.5f64).exp());
    println!("first crossing: {:.6} h by search, 1/(0.8 * 40 sqrt(2) e^(-1/2)) = {:.6} h = {:.4} min", tc, tf, 60.0 * tf);
    let tm = 0.06;                                        // a time after the first crossing, h
    let arrive = |a: f64| a + c(rho0(a)) * tm - 1.8;      // zero where label a reaches 1.8 km
    let hits: Vec<usize> = (0..6000).filter(|&i| arrive(l[i]) * arrive(l[i + 1]) < 0.0).collect();
    let root = |mut lo: f64, mut hi: f64| {               // bisection inside one sign-change bracket
        for _ in 0..60 { let m = (lo + hi) / 2.0; if arrive(lo) * arrive(m) > 0.0 { lo = m } else { hi = m } }
        (lo + hi) / 2.0
    };
    let dens: Vec<String> = hits.iter().map(|&i| format!("{:.2}", rho0(root(l[i], l[i + 1])))).collect();
    println!("mistake 4, at x = 1.8 km, t = {} h: {} labels arrive, densities {}", tm, hits.len(), dens.join(", "));
    for t in [0.0, 0.1] {
        let row: Vec<String> = (0..17).map(|k| format!("{:.2}", rho(-2.0 + k as f64 / 2.0, t))).collect();
        println!("chart, t = {} h: {}", t, row.join(", "));
    }
    let fig: Vec<String> = (-2..3).map(|b| { let b = b as f64;
        format!("{}: {:.4} {:.4} {:.4}", b, 0.0 - clock(b), ramp() - clock(b), unclock(clock(b) + 0.15)) }).collect();
    println!("figure, label a: t entering ramp, t entering zone, x at 0.15 h (h, h, km): {}", fig.join("; "));
    let (m10, r10) = shoot(xq, tq, 10);
    assert!((r10 - ans).abs() < 1e-4 && (m10 - a).abs() < 1e-4);                     // RK4 meets closed form
    assert!(r2.abs() < 1.0 && r1 / r2 > 3.5 && r1 / r2 < 4.5 && rw.abs() > 100.0);   // residual
    assert!((cars(0.1) - 40.0 * sp).abs() < 1e-3 && (wr - wl - 0.6 * w0).abs() < 1e-9);  // cars conserved
    assert!((g(0.03 - 1.0 / 50.0) - rho(1.0, 0.03)).abs() < 1e-9);                   // counter data suffice
    assert!((tc - tf).abs() < 1e-5 && qr(0.001).abs() < 1.0 && hits.len() == 3);    // quasilinear
    println!("ALL CHECKS PASS");
}
