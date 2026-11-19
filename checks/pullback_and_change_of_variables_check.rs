// Pullback and change of variables -- the check behind the card.  std only, no crates.
// A rain map on the east-north grid is pulled back to a radar's (range, azimuth) grid.
// Roads: the pullback built by wedging pulled-back 1-forms (finite differences), the
// closed form -r, the signed (shoelace) area of a mapped cell, a two-stage pullback
// through a raster grid, and a plain cell count on the map that uses no pullback at all.
use std::f64::consts::PI;

type Map = dyn Fn(f64, f64) -> (f64, f64);

fn rain(x: f64, y: f64) -> f64 { 20.0 + 10.0 * (x * x + y * y).sqrt() } // mm
fn radar(r: f64, a: f64) -> (f64, f64) { (r * a.sin(), r * a.cos()) } // azimuth clockwise from north
fn raster_to_map(c: f64, k: f64) -> (f64, f64) { (0.25 * c, 3.0 - 0.25 * k) } // rows counted south
fn radar_to_raster(r: f64, a: f64) -> (f64, f64) {
    let (x, y) = radar(r, a);
    (4.0 * x, 4.0 * (3.0 - y))
}
fn rad(d: f64) -> f64 { d.to_radians() }
fn wedge(p: (f64, f64), q: (f64, f64)) -> f64 { p.0 * q.1 - p.1 * q.0 }
fn comp(p: (f64, f64), i: usize) -> f64 { if i == 0 { p.0 } else { p.1 } }

// F*dx (i = 0) or F*dy (i = 1): its du and dv parts, by central differences
fn pull_1form(f: &Map, u: f64, v: f64, i: usize) -> (f64, f64) {
    let h = 1e-5;
    ((comp(f(u + h, v), i) - comp(f(u - h, v), i)) / (2.0 * h),
     (comp(f(u, v + h), i) - comp(f(u, v - h), i)) / (2.0 * h))
}
// F*(dx ^ dy) at (u, v): pull dx and dy back, then wedge them
fn pull(f: &Map, u: f64, v: f64) -> f64 { wedge(pull_1form(f, u, v, 0), pull_1form(f, u, v, 1)) }

fn shoelace(p: &[(f64, f64)]) -> f64 {
    let n = p.len();
    let mut s = 0.0;
    for i in 0..n { s += p[i].0 * p[(i + 1) % n].1 - p[(i + 1) % n].0 * p[i].1; }
    0.5 * s
}

fn simpson2(g: &dyn Fn(f64, f64) -> f64, a0: f64, a1: f64, b0: f64, b1: f64) -> f64 {
    let n = 60;
    let (ha, hb) = ((a1 - a0) / n as f64, (b1 - b0) / n as f64);
    let w = |i: usize| -> i64 { if i == 0 || i == n { 1 } else if i % 2 == 1 { 4 } else { 2 } };
    let mut s = 0.0;
    for i in 0..=n {
        for j in 0..=n { s += (w(i) * w(j)) as f64 * g(a0 + i as f64 * ha, b0 + j as f64 * hb); }
    }
    s * ha * hb / 9.0
}

// road with no pullback: add rain x cell area over map cells in the valley
fn cell_count(h: f64) -> f64 {
    let m = (3.0 / h).round() as usize;
    let mut tot = 0.0;
    for i in 0..m {
        for j in 0..m {
            let (x, y) = ((i as f64 + 0.5) * h, (j as f64 + 0.5) * h);
            if x * x + y * y <= 9.0 && 2.0 * x >= (x * x + y * y).sqrt() { tot += rain(x, y) * h * h; }
        }
    }
    tot
}

fn main() {
    let (r0, a0) = (2.25, rad(65.0)); // centre of the marked radar cell
    let (cx, cy) = radar(r0, a0);
    let f0 = rain(cx, cy);
    let (det_fd, det_cf) = (pull(&radar, r0, a0), -r0);
    let (dr, da) = (1e-4, 1e-4);
    let tiny = [radar(r0, a0), radar(r0 + dr, a0), radar(r0 + dr, a0 + da), radar(r0, a0 + da)];
    let det_sh = shoelace(&tiny) / (dr * da);
    let (px, py) = (pull_1form(&radar, r0, a0, 0), pull_1form(&radar, r0, a0, 1));
    let coef = f0 * det_fd; // radar-grid coefficient of the pulled-back rain form
    let k0 = radar_to_raster(r0, a0);
    let (mx, my) = raster_to_map(k0.0, k0.1);
    let det_g = pull(&raster_to_map, k0.0, k0.1); // raster cell -> map place
    let coef_raster = rain(mx, my) * det_g; // rain form in raster cells
    let det_rr = pull(&radar_to_raster, r0, a0);
    let coef_two = coef_raster * det_rr; // then back to radar cells
    let cell = [radar(2.0, rad(60.0)), radar(2.5, rad(60.0)), radar(2.5, rad(70.0)), radar(2.0, rad(70.0))];
    let cell_rain = rad(10.0) * (10.0 * (2.5f64.powi(2) - 2.0f64.powi(2)) + 10.0 / 3.0 * (2.5f64.powi(3) - 2.0f64.powi(3)));

    let (aa, ab) = (rad(30.0), rad(90.0)); // the valley: bearings 030 to 090, out to 3 km
    let g = |r: f64, a: f64| { let (x, y) = radar(r, a); rain(x, y) * pull(&radar, r, a) };
    let i_pull = simpson2(&g, 0.0, 3.0, aa, ab); // integral of the pullback in the order (r, a)
    let i_closed = -(ab - aa) * (90.0 + 10.0 / 3.0 * 27.0);
    let total = -i_pull; // the radar grid is left-handed: flip once
    let (c1, c2) = (cell_count(0.05), cell_count(0.025));

    let no_d = (ab - aa) * 105.0; // f only, differentials dropped
    let comm = 180.0 * ((2.0 * ab).sin() - (2.0 * aa).sin()) / 2.0; // dr^da treated like da^dr
    let degs = 60.0 * 180.0; // azimuth in degrees
    let twice = -simpson2(&g, 0.0, 3.0, 0.0, 4.0 * PI); // two sweeps of the whole disc
    let disc = 2.0 * PI * 180.0;
    let ccw = |r: f64, t: f64| (r * t.cos(), r * t.sin());
    let north = |c: f64, k: f64| (0.25 * c, 0.25 * k);

    let rows: Vec<(&str, f64)> = vec![
        ("rain at cell centre, mm", f0), ("pulled-back dx: dr part", px.0), ("pulled-back dx: da part", px.1),
        ("pulled-back dy: dr part", py.0), ("pulled-back dy: da part", py.1),
        ("det by wedging pulled-back dx, dy", det_fd), ("det closed form, -r", det_cf),
        ("det from shoelace of a tiny cell", det_sh),
        ("rain form coefficient on radar grid", coef), ("  via raster cells, two stages", coef_two),
        ("  raster-grid coefficient", coef_raster), ("  det radar -> raster", det_rr),
        ("  det raster -> map", det_g), ("  bars: |det| x |det|", det_g.abs() * det_rr.abs()),
        ("marked cell: shoelace of corners", shoelace(&cell)), ("marked cell: exact area, km2", rad(10.0) * 1.125),
        ("marked cell: rain, mm km2", cell_rain),
        ("range part: integral of (20 + 10r) r dr", 90.0 + 10.0 / 3.0 * 27.0), ("integral of pullback, Simpson", i_pull), ("integral of pullback, closed form", i_closed),
        ("valley total, mm km2", total), ("valley total, cubic metres", total * 1000.0),
        ("cell count on map, 0.05 km", c1), ("cell count on map, 0.025 km", c2),
        ("wrong: differentials dropped", no_d), ("wrong: wedge treated as commuting", comm),
        ("wrong: sign not flipped", i_pull), ("wrong: azimuth in degrees", degs),
        ("fails: azimuth swept twice", twice), ("  true rain on the 3 km disc", disc),
        ("try: azimuth anticlockwise from east, det", pull(&ccw, r0, rad(25.0))),
        ("try: raster rows counted north, det", pull(&north, 1.0, 1.0)),
        ("try: valley area, km2", (ab - aa) * 4.5), ("try: uniform 40 mm, mm km2", 40.0 * (ab - aa) * 4.5),
    ];
    for (name, v) in &rows { println!("{:<42}{:>16.6}", name, v); }
    let fig: Vec<String> = cell.iter().map(|p| format!("{:.4} {:.4}", p.0, p.1)).collect();
    println!("figure,{}", fig.join(","));

    assert!((det_fd - det_cf).abs() < 1e-6); // wedging pulled-back 1-forms gives -r
    assert!((det_sh - det_cf).abs() < 1e-3); // so does the signed area of a mapped cell
    assert!((coef_two - coef).abs() < 1e-6); // two-stage pullback agrees with one stage
    assert!((i_pull - i_closed).abs() < 1e-6); // Simpson on the pullback against the closed form
    assert!((c2 - total).abs() < 0.005 * c2); // a cell count with no pullback at all
    assert!(shoelace(&cell) < 0.0); // the radar grid runs clockwise on the map
    assert!(det_rr > 0.0); // two reversals in a row preserve orientation
    assert!((det_g.abs() * det_rr.abs() - det_fd.abs()).abs() < 1e-6); // bars compose too, minus the sign
    assert!((twice - 2.0 * disc).abs() < 1e-6); // two sweeps count every place twice
    assert!((no_d - total).abs() > 50.0); // the dropped differentials are a real error
    println!("ALL CHECKS PASS");
}
