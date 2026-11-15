// Eikonal and traffic -- the same check in Rust, std only.
// Sound: arrival time T = min over the speaker towers of distance / c, against a fast-sweeping
// grid that knows no formula, and the residual |grad T| c = 1 by centred differences.
// Traffic: a motorway lane blocked for 6 min.  Rankine-Hugoniot and the backward wave speed
// against Newell's minimum formula for the car count N(x, t), which knows neither.
const C: f64 = 343.0; // speed of sound in air at 20 C, m/s
const TOWERS: [(f64, f64); 2] = [(0.0, 0.0), (100.0, 0.0)]; // speaker towers at the two ends of the straight, m
fn dists(x: f64, y: f64) -> [f64; 2] { TOWERS.map(|(a, b)| ((x - a).powi(2) + (y - b).powi(2)).sqrt()) }
fn t_first(x: f64, y: f64) -> f64 { let d = dists(x, y); d[0].min(d[1]) / C } // the viscosity solution, s
fn t_late(x: f64, y: f64) -> f64 { let d = dists(x, y); d[0].max(d[1]) / C } // also |grad T| = 1/c off the ridge

fn grad_c(f: fn(f64, f64) -> f64, x: f64, y: f64) -> f64 { // |grad f| times c, by centred differences
    let d = 0.01;
    let gx = (f(x + d, y) - f(x - d, y)) / (2.0 * d);
    let gy = (f(x, y + d) - f(x, y - d)) / (2.0 * d);
    (gx * gx + gy * gy).sqrt() * C
}

fn sweep(h: f64) -> (f64, f64) { // road 2: fast sweeping with the upwind update
    let (x0, lx, ly) = (-20.0, 140.0, 60.0);
    let (nx, ny) = ((lx / h).round() as usize + 1, (ly / h).round() as usize + 1);
    let inf: f64 = 1e9;
    let mut g = vec![vec![inf; ny]; nx];
    for (a, b) in TOWERS { g[((a - x0) / h).round() as usize][(b / h).round() as usize] = 0.0; }
    let f = h / C;
    for _ in 0..2 {
        for di in [false, true] {
            for dj in [false, true] {
                for ii in 0..nx {
                    let i = if di { nx - 1 - ii } else { ii };
                    for jj in 0..ny {
                        let j = if dj { ny - 1 - jj } else { jj };
                        let a = (if i > 0 { g[i - 1][j] } else { inf }).min(if i < nx - 1 { g[i + 1][j] } else { inf });
                        let b = (if j > 0 { g[i][j - 1] } else { inf }).min(if j < ny - 1 { g[i][j + 1] } else { inf });
                        let t = if (a - b).abs() >= f { a.min(b) + f } else { (a + b + (2.0 * f * f - (a - b).powi(2)).sqrt()) / 2.0 };
                        if t < g[i][j] { g[i][j] = t; }
                    }
                }
            }
        }
    }
    let mut err: f64 = 0.0;
    for i in 0..nx { for j in 0..ny { err = err.max((g[i][j] - t_first(x0 + i as f64 * h, j as f64 * h)).abs()); } }
    (g[((30.0 - x0) / h).round() as usize][(40.0 / h).round() as usize], err)
}

const VF: f64 = 90.0; // free speed, km/h
const W: f64 = 18.0; // backward wave speed, km/h
const RJ: f64 = 150.0; // jam density, cars/km
const RC: f64 = W * RJ / (VF + W); // critical density
const QC: f64 = VF * RC; // capacity
const RU: f64 = 15.0; // arriving density, cars/km
const QU: f64 = VF * RU; // arriving flow
const TAU: f64 = 0.1; // lane blocked 0.1 h = 6 min
fn q(r: f64) -> f64 { (VF * r).min(W * (RJ - r)) } // Newell's triangular flow rule, cars/h
fn n0(x: f64) -> f64 { -RU * x } // car count at the crash, t = 0
fn newell(x: f64, t: f64) -> f64 { // road 2: Newell's minimum formula, no shock rule inside
    let best = n0(x - VF * t).min(n0(x + W * t) + RJ * W * t);
    let tp = if x <= 0.0 { TAU.min(t + x / W) } else { TAU.min(t - x / VF) }; // latest usable blocked moment
    if tp >= 0.0 { best.min(QC * (t - tp) - RC * x) } else { best }
}
fn rho(x: f64, t: f64) -> f64 { let e = 1e-7; -(newell(x + e, t) - newell(x - e, t)) / (2.0 * e) }
fn bisect(f: &dyn Fn(f64) -> bool, mut lo: f64, mut hi: f64) -> f64 {
    for _ in 0..60 { let m = (lo + hi) / 2.0; if f(m) { hi = m } else { lo = m } }
    (lo + hi) / 2.0
}

fn main() {
    println!("SOUND: towers at (0, 0) m and (100, 0) m, c = 343 m/s; seat at (30, 40) m");
    let d = dists(30.0, 40.0);
    println!("seat: {:.2} m from the near tower, {:.2} m from the far one", d[0], d[1]);
    let (ts, tl8) = (t_first(30.0, 40.0), t_late(30.0, 40.0));
    println!("first arrival T = {:.4} s; later arrival {:.4} s; gap {:.1} ms", ts, tl8, 1000.0 * (tl8 - ts));
    println!("ridge seat (50, 40): {:.2} m from both towers, T = {:.4} s", dists(50.0, 40.0)[0], t_first(50.0, 40.0));
    let (r_seat, r_late, r_ridge) = (grad_c(t_first, 30.0, 40.0), grad_c(t_late, 30.0, 40.0), grad_c(t_first, 50.0, 40.0));
    println!("residual |grad T| c: seat {:.6}, later arrival at seat {:.6}, on the ridge {:.4}", r_seat, r_late, r_ridge);
    let mut errs = vec![];
    for (h, hs) in [(1.0, "1.0"), (0.5, "0.5"), (0.25, "0.25")] {
        let (seat, err) = sweep(h);
        errs.push(err);
        println!("road 2, fast sweeping h = {} m: seat {:.4} s, largest error {:.2} ms", hs, seat, 1000.0 * err);
    }
    println!("error ratios as h halves: {:.2}, {:.2} (order about 1, slowed by log(1/h) at the towers)", errs[0] / errs[1], errs[1] / errs[2]);
    println!("hand timing, gun to finish 100 m: {:.4} s; try, 35 C day, c = 352 m/s: seat {:.4} s", 100.0 / C, 50.0 / 352.0);
    let xs: Vec<f64> = (0..15).map(|k| -20.0 + 10.0 * k as f64).collect();
    let row = |f: fn(f64, f64) -> f64| xs.iter().map(|&x| format!("{:.0}", 1000.0 * f(x, 40.0))).collect::<Vec<_>>().join(", ");
    println!("chart, row 40 m back, first arrival ms: {}", row(t_first));
    println!("chart, row 40 m back, later arrival ms: {}", row(t_late));

    let s = (q(RJ) - q(RU)) / (RJ - RU); // Rankine-Hugoniot speed of the tail, km/h
    let l = -s * TAU; // jam length when the lane reopens, km
    let tend = TAU + l / (W + s);
    let xend = -W * (tend - TAU); // head (at -W) meets tail (at s)
    let dd = RJ * 0.5 * l * tend; // car-hours stopped: the jam's area in (x, t) times RJ
    let caught = (QU - RU * s) * tend; // cars that cross the tail
    let car_delay = |n: f64| { // car n starts at -n/RU km, drives at VF until the tail
        let t1 = n / (RU * (VF - s));
        let t2 = TAU - s * t1 / W;
        (t2 - t1, t2 + (-s * t1) / VF) // stopped time, arrival at the crash site
    };
    println!("TRAFFIC: free {:.0} km/h, wave back {:.0} km/h, jam {:.0} cars/km; capacity {:.0} cars/h at {:.0} cars/km", VF, W, RJ, QC, RC);
    println!("arriving {:.0} cars/h at {:.0} cars/km; lane blocked {:.0} min", QU, RU, 60.0 * TAU);
    println!("tail speed (0 - {:.0})/({:.0} - {:.0}) = {:.1} km/h; jam {:.2} km, {:.0} cars at reopening", QU, RJ, RU, s, l, RJ * l);
    println!("count: {:.0} cars were on that km + {:.0} arrived = {:.0}", RU * l, QU * TAU, RU * l + QU * TAU);
    println!("head at {:.0} km/h meets tail at {:.1} min, {:.2} km; jam outlives the crash by {:.1} min", -W, 60.0 * tend, xend, 60.0 * (tend - TAU));
    println!("cars cross the tail at {:.0} + {:.0} x {:.0} = {:.0} cars/h for {:.1} min", QU, RU, -s, QU - RU * s, 60.0 * tend);
    println!("delay {:.3} car-hours over {:.1} cars = {:.2} min each; first car {:.2} min", dd, caught, 60.0 * dd / caught, 60.0 * car_delay(0.0).0);
    let x6 = bisect(&|x| rho(x, TAU) > 82.5, -3.0, -0.2);
    let x12h = bisect(&|x| rho(x, 0.2) < 87.5, -1.9, -0.5);
    let x12t = bisect(&|x| rho(x, 0.2) > 82.5, -3.0, -1.9);
    println!("road 2, Newell: tail at 6 min {:.4} km; at 12 min tail {:.4} km, head {:.4} km", x6, x12t, x12h);
    println!("road 2, Newell: cars in the jam at 6 min N(-1, 6 min) - N(0, 6 min) = {:.4}", newell(-1.0, TAU) - newell(0.0, TAU));
    let n = 3600;
    let dn = (0..n).map(|k| { let (a, b) = (k as f64 / n as f64, (k + 1) as f64 / n as f64);
        (QU * a - newell(0.0, a) + QU * b - newell(0.0, b)) / 2.0 }).sum::<f64>() / n as f64;
    println!("road 2, Newell: delay = area between free and real counts at the crash site = {:.4} car-hours", dn);
    let t100 = bisect(&|t| newell(0.0, t) >= 100.0, TAU, 0.3);
    let tl = bisect(&|t| newell(0.0, t) >= QU * t - 1e-9, TAU, 0.3);
    let (dl, ar) = car_delay(100.0);
    println!("car 100: formula arrives {:.3} min, stopped {:.3} min; Newell arrives {:.3} min, free {:.3} min", 60.0 * ar, 60.0 * dl, 60.0 * t100, 60.0 * 100.0 / QU);
    println!("last delayed car passes the crash site at {:.3} min, car {:.1}", 60.0 * tl, QU * tl);
    for m in (0..19).step_by(3) {
        let t = m as f64 / 60.0;
        let (tail, head) = (s * t, (-W * (t - TAU)).min(0.0));
        let at = if t <= tend { format!("tail {:5.2} km, head {:5.2} km, jam {:.2} km", tail + 0.0, head + 0.0, head - tail) } else { "jam gone".to_string() };
        println!("story, {:2} min: {}; past the crash N(0, t) = {:5.1}, free {:5.1}", m, at, newell(0.0, t) + 0.0, QU * t);
    }
    println!("mistake 1, jam gone at reopening: {:.3} car-hours, not {:.3}", RJ * 0.5 * l * TAU, dd);
    println!("mistake 2, tail at -{:.0} km/h: jam {:.1} km holding {:.0} cars, but only {:.0} arrived", W, W * TAU, RJ * W * TAU, RU * W * TAU + QU * TAU);
    println!("mistake 3, later arrival at the seat: {:.4} s, not {:.4} s", tl8, ts);
    for (ru, tau) in [(20.0, 0.1), (15.0, 0.2)] {
        let s2 = -VF * ru / (RJ - ru);
        let te = tau * W / (W + s2);
        println!("try, arriving {:.0} cars/km, blocked {:.0} min: jam ends at {:.1} min, {:.2} km, delay {:.3} car-hours", ru, 60.0 * tau, 60.0 * te, -W * (te - tau), RJ * 0.5 * (-s2 * tau) * te);
    }
    println!("figure, tail (0, 0) to ({:.2} km, {:.1} min); head (0, 6.0 min) to the same; free front to (0, {:.1} min)", xend, 60.0 * tend, 60.0 * tl);
    let ks = [0.0, 100.0, 200.0, 300.0];
    let stops: Vec<String> = ks.iter().map(|k| format!("({:.3} km, {:.2} min)", s * k / (RU * (VF - s)) + 0.0, 60.0 * k / (RU * (VF - s)))).collect();
    let leaves: Vec<String> = ks.iter().map(|k| format!("{:.2}", 60.0 * (TAU - s * k / (RU * (VF - s)) / W))).collect();
    println!("figure, cars 0 100 200 300 stop at {} and leave at {} min", stops.join(" "), leaves.join(" "));
    assert!((r_seat - 1.0).abs() < 1e-6 && (r_ridge - 1.0).abs() > 0.3); // T obeys the eikonal, not on the ridge
    assert!(errs[2] < 0.0015 && errs[0] > errs[1] && errs[1] > errs[2]); // the grid settles on min, not max
    assert!((x6 + l).abs() < 1e-9 && (x12t - s * 0.2).abs() < 1e-9 && (x12h + W * 0.1).abs() < 1e-9); // Newell meets RH, -W
    assert!((dn - dd).abs() < 1e-9 && (newell(-1.0, TAU) - newell(0.0, TAU) - RJ * l).abs() < 1e-9); // Newell meets areas
    assert!((t100 - ar).abs() < 1e-9 && (QU * tl - caught).abs() < 1e-6); // arrival times agree
    println!("ALL CHECKS PASS");
}
