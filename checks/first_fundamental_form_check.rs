// First fundamental form -- the check behind the card.  std only, no crates.
// Roof: the saddle middle of a stadium roof, z = 30 + (u^2 - v^2)/120 metres.
// Walk: straight on the plan from the centre (0, 0) to the corner P = (30, 20).
type V3 = [f64; 3];
type Chart = fn(f64, f64) -> V3;

fn plan(u: f64, v: f64) -> V3 { [u, v, 30.0 + (u * u - v * v) / 120.0] }
fn rule(p: f64, q: f64) -> V3 { [p + q, p - q, 30.0 + p * q / 30.0] }
fn polar(rho: f64, th: f64) -> V3 { plan(rho * th.cos(), rho * th.sin()) }

fn dot(a: V3, b: V3) -> f64 { a[0] * b[0] + a[1] * b[1] + a[2] * b[2] }
fn sub(a: V3, b: V3) -> V3 { [a[0] - b[0], a[1] - b[1], a[2] - b[2]] }

fn efg(chart: Chart, a: f64, b: f64) -> (f64, f64, f64) {
    // E, F, G from the patch alone: tangent arrows by central differences, then dots
    let h = 1e-5;
    let (pu, mu, pv, mv) = (chart(a + h, b), chart(a - h, b), chart(a, b + h), chart(a, b - h));
    let ru = [(pu[0] - mu[0]) / (2.0 * h), (pu[1] - mu[1]) / (2.0 * h), (pu[2] - mu[2]) / (2.0 * h)];
    let rv = [(pv[0] - mv[0]) / (2.0 * h), (pv[1] - mv[1]) / (2.0 * h), (pv[2] - mv[2]) / (2.0 * h)];
    (dot(ru, ru), dot(ru, rv), dot(rv, rv))
}

fn form(e: (f64, f64, f64), x: (f64, f64), y: (f64, f64)) -> f64 {
    e.0 * x.0 * y.0 + e.1 * (x.0 * y.1 + x.1 * y.0) + e.2 * x.1 * y.1
}

fn length(chart: Chart, end: (f64, f64), vel: (f64, f64), fterm: f64) -> f64 {
    // Simpson's rule on ds/dt = sqrt(E u'^2 + 2F u'v' + G v'^2), t from 0 to 1
    let n = 200;
    let speed = |t: f64| {
        let (e, f, g) = efg(chart, end.0 * t, end.1 * t);
        (e * vel.0 * vel.0 + fterm * f * vel.0 * vel.1 + g * vel.1 * vel.1).sqrt()
    };
    let h = 1.0 / n as f64;
    let mut s = speed(0.0) + speed(1.0);
    for k in 1..n { s += (if k % 2 == 1 { 4.0 } else { 2.0 }) * speed(k as f64 * h); }
    s * h / 3.0
}

fn chords(n: usize) -> f64 {
    // road 3: a tape laid along n straight pieces in space
    let pts: Vec<V3> = (0..=n).map(|k| plan(30.0 * k as f64 / n as f64, 20.0 * k as f64 / n as f64)).collect();
    pts.windows(2).map(|w| { let d = sub(w[1], w[0]); dot(d, d).sqrt() }).sum()
}

fn angle(e: (f64, f64, f64), x: (f64, f64), y: (f64, f64)) -> f64 {
    (form(e, x, y) / (form(e, x, x) * form(e, y, y)).sqrt()).acos().to_degrees()
}

fn tape_angle(h: f64) -> f64 {
    // road 3 for the angle: three tape lengths and the law of cosines
    let (p, a3, b3) = (plan(30.0, 20.0), plan(30.0 + h, 20.0), plan(30.0, 20.0 + h));
    let len = |x: V3, y: V3| { let d = sub(x, y); dot(d, d).sqrt() };
    let (a, b, c) = (len(a3, p), len(b3, p), len(a3, b3));
    ((a * a + b * b - c * c) / (2.0 * a * b)).acos().to_degrees()
}

fn main() {
    let e1 = efg(plan, 30.0, 20.0);
    let e2 = efg(rule, 25.0, 5.0);
    let (a, b) = (10.0 * 13f64.sqrt(), 25.0 / 3.0); // ds/dt = sqrt(a^2 + b^2 t^2) on this walk
    let closed = 0.5 * ((a * a + b * b).sqrt() + a * a / b * (b / a).asinh());
    let l1 = length(plan, (30.0, 20.0), (30.0, 20.0), 2.0);
    let l2 = length(rule, (25.0, 5.0), (25.0, 5.0), 2.0);
    let flat = (30.0f64 * 30.0 + 20.0 * 20.0).sqrt();
    let no_f = length(plan, (30.0, 20.0), (30.0, 20.0), 0.0);
    let one_f = length(plan, (30.0, 20.0), (30.0, 20.0), 1.0);
    let mixed = length(plan, (25.0, 5.0), (25.0, 5.0), 2.0);
    let th1 = angle(e1, (1.0, 0.0), (0.0, 1.0));
    let th2 = angle(e2, (0.5, 0.5), (0.5, -0.5));
    let ep = efg(polar, 0.0, 0.7);
    let three = |e: (f64, f64, f64)| format!("{:.6} {:.6} {:.6}", e.0, e.1, e.2);
    let rows: Vec<(&str, String)> = vec![
        ("E, F, G at P, plan chart", three(e1)),
        ("hand formula 1+u^2/3600, -uv/3600, 1+v^2/3600", three((1.0 + 900.0 / 3600.0, -600.0 / 3600.0, 1.0 + 400.0 / 3600.0))),
        ("E, F, G at P, seam chart", three(e2)),
        ("  by J^T I J: E+2F+G, E-G, E-2F+G", three((e1.0 + 2.0 * e1.1 + e1.2, e1.0 - e1.2, e1.0 - 2.0 * e1.1 + e1.2))),
        ("EG - F^2 at P", format!("{:.6}", e1.0 * e1.2 - e1.1 * e1.1)),
        ("roof height at P, m", format!("{:.6}", plan(30.0, 20.0)[2])),
        ("sqrt(E), sqrt(G), sqrt(EG) at P", three((e1.0.sqrt(), e1.2.sqrt(), (e1.0 * e1.2).sqrt()))),
        ("t^2 terms: 900/4, -1200/6, 400/9", three((900.0 / 4.0, -1200.0 / 6.0, 400.0 / 9.0))),
        ("speed at t = 0, 0.5, 1, m per unit t", three((a, (a * a + b * b / 4.0).sqrt(), (a * a + b * b).sqrt()))),
        ("Simpson by hand, 2 slices, m", format!("{:.6}", (a + 4.0 * (a * a + b * b / 4.0).sqrt() + (a * a + b * b).sqrt()) / 6.0)),
        ("plan distance O to P, m", format!("{:.6}", flat)),
        ("1 length, plan chart, Simpson", format!("{:.6}", l1)),
        ("2 length, seam chart, Simpson", format!("{:.6}", l2)),
        ("3 length, closed form", format!("{:.6}", closed)),
        ("4 tape in 10 straight pieces", format!("{:.6}", chords(10))),
        ("  tape in 100 straight pieces", format!("{:.6}", chords(100))),
        ("roof minus plan, m", format!("{:.6}", closed - flat)),
        ("speed^2 at t = 1, (m per unit t)^2", format!("{:.6}", form(e1, (30.0, 20.0), (30.0, 20.0)))),
        ("1 angle at P, plan chart, deg", format!("{:.6}", th1)),
        ("2 angle at P, seam chart, deg", format!("{:.6}", th2)),
        ("  same angle in radians", format!("{:.6}", th1.to_radians())),
        ("  cos of the angle, F/sqrt(EG)", format!("{:.6}", e1.1 / (e1.0 * e1.2).sqrt())),
        ("3 tape triangle, 1 m legs, deg", format!("{:.6}", tape_angle(1.0))),
        ("  tape triangle, 0.1 m legs, deg", format!("{:.6}", tape_angle(0.1))),
        ("wrong: plan angle, deg", format!("{:.6}", 90.0)),
        ("wrong: drop F, length", format!("{:.6}", no_f)),
        ("wrong: F once, not 2F, length", format!("{:.6}", one_f)),
        ("wrong: plan E,F,G with seam speeds", format!("{:.6}", mixed)),
        ("breaks: polar chart at centre, E F G", three(ep)),
        ("  EG - F^2 there", format!("{:.6}", ep.0 * ep.2 - ep.1 * ep.1)),
        ("try: walk along seam to (30, 30), m", format!("{:.6}", length(plan, (30.0, 30.0), (30.0, 30.0), 2.0))),
        ("  plan distance to (30, 30), m", format!("{:.6}", 1800f64.sqrt())),
        ("try: walk to (30, -20), m", format!("{:.6}", length(plan, (30.0, -20.0), (30.0, -20.0), 2.0))),
        ("try: angle at centre, deg", format!("{:.6}", angle(efg(plan, 0.0, 0.0), (1.0, 0.0), (0.0, 1.0)))),
        ("try: seams crossing at P, deg", format!("{:.6}", angle(e1, (1.0, 1.0), (1.0, -1.0)))),
    ];
    for (name, v) in &rows { println!("{:<46} {}", name, v); }
    let xs: Vec<String> = (0..=10).map(|k| format!("{:.1}", flat * k as f64 / 10.0)).collect();
    let ys: Vec<String> = (0..=10)
        .map(|k| { let t = k as f64 / 10.0; format!("{:.4}", (a * a + b * b * t * t).sqrt() / a) }).collect();
    println!("figure, plan metres {}", xs.join(" "));
    println!("figure, roof m per plan m {}", ys.join(" "));

    assert!((l1 - closed).abs() < 1e-7, "first-form integral must match the closed form");
    assert!((l2 - closed).abs() < 1e-7, "the seam chart must give the same length");
    let (c10, c100) = (chords(10), chords(100));
    assert!(0.0 < closed - c10 && closed - c10 < 0.001 && (closed - c10) / (closed - c100) > 50.0, "tape error falls 100-fold");
    assert!((e1.0 - 2.0 * e1.1 + e1.2 - e2.2).abs() + (e1.0 - e1.2 - e2.1).abs() < 1e-6, "chart change rule J^T I J");
    assert!((th1 - th2).abs() < 1e-6, "the angle must not depend on the chart");
    let (g1, g2) = ((tape_angle(0.1) - th1).abs(), (tape_angle(1.0) - th1).abs());
    assert!(g1 < g2 && g2 < 0.5, "tape angle closes in");
    assert!((e1.1 / (e1.0 * e1.2).sqrt() + 1.0 / 50f64.sqrt()).abs() < 1e-9, "cos = -1/sqrt(50) by hand");
    assert!((ep.0 * ep.2 - ep.1 * ep.1).abs() < 1e-9, "polar chart is not regular at the centre");
    println!("ALL CHECKS PASS");
}
