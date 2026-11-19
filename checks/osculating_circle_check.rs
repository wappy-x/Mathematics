// Osculating circle on a bus corner: radius and centre by formula, by a second chart and by three-point circles.
type P = (f64, f64);
const A: f64 = 20.0; // m from the crossing point O to where the turn starts and ends
const BUS: f64 = 12.0; // m: the tightest radius the bus's centre line can follow (assumed)
const SIDE: f64 = 1.75; // m: half the bus's 2.5 m width plus a 0.5 m margin

fn pos(t: f64) -> P { (A * t * t, A * (1.0 - t).powi(2)) }
fn vel(t: f64) -> P { (2.0 * A * t, -2.0 * A * (1.0 - t)) }
fn acc(_t: f64) -> P { (2.0 * A, 2.0 * A) }

// signed: positive turning left
fn curvature(dx: f64, dy: f64, ax: f64, ay: f64) -> f64 {
    (dx * ay - dy * ax) / (dx * dx + dy * dy).sqrt().powi(3)
}

// unit tangent turned a quarter turn left
fn normal(t: f64) -> P {
    let (dx, dy) = vel(t);
    let s = (dx * dx + dy * dy).sqrt();
    (-dy / s, dx / s)
}

// curvature, then the centre 1/k along the unit normal
fn by_formula(t: f64) -> (f64, P) {
    let ((dx, dy), (ax, ay)) = (vel(t), acc(t));
    let k = curvature(dx, dy, ax, ay);
    let ((x, y), (nx, ny)) = (pos(t), normal(t));
    (k, (x + nx / k, y + ny / k))
}

// second chart: the same corner as the graph y = (sqrt(A) - sqrt(x))^2
fn by_graph(x: f64) -> (f64, P) {
    let y = (A.sqrt() - x.sqrt()).powi(2);
    let (d1, d2) = (1.0 - (A / x).sqrt(), 0.5 * A.sqrt() * x.powf(-1.5));
    let q = 1.0 + d1 * d1;
    (d2 / q.powf(1.5), (x - d1 * q / d2, y + q / d2))
}

// circle through three nearby points of the path
fn three_point(t: f64, h: f64) -> (f64, P) {
    let ((x0, y0), (x1, y1), (x2, y2)) = (pos(t - h), pos(t), pos(t + h));
    let (bx, by, cx, cy) = (x0 - x1, y0 - y1, x2 - x1, y2 - y1);
    let d = 2.0 * (bx * cy - by * cx);
    let (b2, c2) = (bx * bx + by * by, cx * cx + cy * cy);
    let (ux, uy) = ((cy * b2 - by * c2) / d, (bx * c2 - cx * b2) / d);
    ((ux * ux + uy * uy).sqrt(), (x1 + ux, y1 + uy))
}

fn dist(a: P, b: P) -> f64 { ((a.0 - b.0).powi(2) + (a.1 - b.1).powi(2)).sqrt() }
fn p(label: &str, v: &str) { println!("{:<44}{}", label, v); }
fn xy(c: P) -> String { format!("({:.2}, {:.2})", c.0, c.1) }

fn main() {
    for (t, name) in [(0.0, "entry t=0.0"), (0.25, "quarter t=0.25"), (0.5, "apex t=0.5")] {
        let (k, c) = by_formula(t);
        p(&format!("{}: point", name), &xy(pos(t)));
        p("  curvature k (1/m), radius 1/k (m)", &format!("{:.6}  {:.6}", k, 1.0 / k));
        p("  centre", &xy(c));
        if t > 0.0 {
            let (kg, cg) = by_graph(pos(t).0);
            p("  graph chart: k, centre", &format!("{:.6}  {}", kg, xy(cg)));
            assert!((kg - k).abs() < 1e-12 && dist(cg, c) < 1e-9);
            for (h, hs) in [(0.01, "0.01"), (0.001, "0.001")] {
                let (r3, c3) = three_point(t, h);
                p(&format!("  three-point circle, step {}", hs), &format!("{:.6}  ({:.6}, {:.6})", r3, c3.0, c3.1));
                assert!((r3 - 1.0 / k).abs() < 100.0 * h * h && dist(c3, c) < 100.0 * h * h);
            }
        }
    }

    let ((dx, dy), (ax, ay), (nx, ny)) = (vel(0.5), acc(0.5), normal(0.5));
    p("apex by hand: velocity, acceleration", &format!("{}  {}", xy((dx, dy)), xy((ax, ay))));
    let sp = (dx * dx + dy * dy).sqrt();
    p("  cross, speed, speed^3, N", &format!("{:.2}  {:.2}  {:.2}  ({:.4}, {:.4})", dx * ay - dy * ax, sp, sp.powi(3), nx, ny));
    p("  graph at x = 5: y', y''", &format!("{:.6}  {:.6}", 1.0 - (A / 5.0).sqrt(), 0.5 * A.sqrt() * 5f64.powf(-1.5)));
    let (kq, cq) = by_formula(0.25);
    let (ka, ca) = by_formula(0.5);
    assert!((1.0 / ka - A / 2f64.sqrt()).abs() < 1e-12 && dist(ca, (15.0, 15.0)) < 1e-12 && dist(cq, (20.0, 17.5)) < 1e-12);
    assert!((1.0 / by_formula(0.0).0 - 2.0 * A).abs() < 1e-12);

    let steps = [0.04, 0.02, 0.01];
    println!("gap from path to circle at steps 0.04 0.02 0.01 (micrometres); halving ratios");
    let lens: Vec<String> = steps.iter().map(|&st| format!("{:.2}", dist(pos(0.25 + st), pos(0.25)))).collect();
    p("  step lengths along the road, quarter (m)", &lens.join(" "));
    let nq = normal(0.25);
    let tangent12 = (pos(0.25).0 + BUS * nq.0, pos(0.25).1 + BUS * nq.1);
    let cases = [("osculating circle at quarter", 0.25, cq, 1.0 / kq, 8.0),
                 ("12 m tangent circle at quarter", 0.25, tangent12, BUS, 4.0),
                 ("osculating circle at apex", 0.5, ca, 1.0 / ka, 16.0)];
    for (label, t, c, r, order) in cases {
        let g: Vec<f64> = steps.iter().map(|&st| dist(pos(t + st), c) - r).collect();
        let gs: Vec<String> = g.iter().map(|v| format!("{:.2}", 1e6 * v)).collect();
        p(&format!("  {}", label), &format!("{}   {:.2} {:.2}", gs.join(" "), g[0] / g[1], g[1] / g[2]));
        assert!((g[1] / g[2] - order).abs() < 0.1 * order);
    }

    let kerb = 1.0 / ka - SIDE;
    let near = (0..=2000).map(|i| (dist(pos(i as f64 / 2000.0), ca) - kerb).abs()).fold(f64::INFINITY, f64::min);
    let v = 15.0 / 3.6;
    p("bus: kerb arc radius round the apex centre", &format!("{:.2} m", kerb));
    p("bus: closest path to kerb arc, 2001 samples", &format!("{:.4} m", near));
    p("bus: shortest turn-in distance for 12 m", &format!("{:.2} m", BUS * 2f64.sqrt()));
    p("bus at 15 km/h: v^2 k at entry, apex", &format!("{:.3}  {:.3} m/s^2", v * v * by_formula(0.0).0, v * v * ka));
    assert!((near - SIDE).abs() < 1e-9 && 1.0 / ka >= BUS);

    let ((dx, dy), (ax, ay)) = (vel(0.25), acc(0.25));
    let am = (ax * ax + ay * ay).sqrt();
    let wrong_r = (dx * dx + dy * dy) / am;
    let wrong_c = (pos(0.25).0 + ax / am / kq, pos(0.25).1 + ay / am / kq);
    p("wrong: speed^2 / |acceleration|, quarter", &format!("{:.2} m (right {:.2})", wrong_r, 1.0 / kq));
    p("wrong: centre on the other side, apex", &xy((2.0 * pos(0.5).0 - ca.0, 2.0 * pos(0.5).1 - ca.1)));
    p("wrong: centre along acceleration, quarter", &format!("{}, {:.2} m off", xy(wrong_c), dist(wrong_c, cq)));
    p("wrong: 1/|y''| on the graph, apex", &format!("{:.2} m (right {:.2})", 1.0 / (0.5 * A.sqrt() * 5f64.powf(-1.5)), 1.0 / ka));
    for (t, ts) in [(0.1, "0.1"), (0.01, "0.01")] {
        p(&format!("cusp (t^2, t^3): radius at t={}", ts), &format!("{:.6} m", 1.0 / curvature(2.0 * t, 3.0 * t * t, 2.0, 6.0 * t)));
    }
    assert!((wrong_r - 1.0 / kq).abs() > 1.0 && dist(wrong_c, cq) > 1.0);
    p("try: A = 15, apex radius (m)", &format!("{:.2}", 1.0 / curvature(15.0, -15.0, 30.0, 30.0)));
    p("try: centres at t=0.1, t=0.4", &format!("{}  {}", xy(by_formula(0.1).1), xy(by_formula(0.4).1)));
    let g19: Vec<f64> = [0.02, 0.01].iter().map(|&st| dist(pos(0.25 + st), (pos(0.25).0 + 19.0 * nq.0, pos(0.25).1 + 19.0 * nq.1)) - 19.0).collect();
    p("try: 19 m tangent circle, halving ratio", &format!("{:.2}", g19[0] / g19[1]));
    p("try: 30 km/h, v^2 k at apex", &format!("{:.3} m/s^2", (30.0f64 / 3.6).powi(2) * ka));
    p("figure, path (0,20) via O (0,0) to (20,0)", &format!("centre {} r {:.2}; kerb r {:.2}", xy(ca), 1.0 / ka, kerb));
    println!("ALL CHECKS PASS");
}
