// Surface area from the first fundamental form -- the check behind the card.
// std only, no crates.  A stadium roof: a half dome over the east end and a
// saddle over the middle.  Area = double integral of sqrt(EG - F^2), done by
// Simpson's rule written out, in two charts per panel; then a flat-triangle mesh
// that never forms E, F or G; then the dome's closed form.
use std::f64::consts::PI;
type V = [f64; 3];

fn dot(a: V, b: V) -> f64 { a[0] * b[0] + a[1] * b[1] + a[2] * b[2] }
fn cross(a: V, b: V) -> V { [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]] }
fn efg(ru: V, rv: V) -> (f64, f64, f64) { (dot(ru, ru), dot(ru, rv), dot(rv, rv)) }
fn stretch(ru: V, rv: V) -> f64 {
    // sqrt(EG - F^2): m^2 of roof per unit of chart
    let (e, f, g) = efg(ru, rv);
    (e * g - f * f).sqrt()
}

fn simpson2<C: Fn(f64, f64) -> (V, V)>(chart: C, a: f64, b: f64, c: f64, d: f64, n: usize) -> f64 {
    let (hu, hv) = ((b - a) / n as f64, (d - c) / n as f64);
    let w = |i: usize| -> f64 { if i == 0 || i == n { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 } };
    let mut s = 0.0;
    for i in 0..=n {
        for j in 0..=n {
            let (ru, rv) = chart(a + i as f64 * hu, c + j as f64 * hv);
            s += w(i) * w(j) * stretch(ru, rv);
        }
    }
    s * hu * hv / 9.0
}

const R: f64 = 60.0; // dome: sphere radius (m)
const H: f64 = 12.0; // rise of the cap (m)
const SR: f64 = 60.0; // saddle radius a: z = 30 + (x^2 - y^2)/(2a)
const LX: f64 = 30.0;
const LY: f64 = 36.0;

fn sphere(p: f64, t: f64) -> (V, V) {
    // chart 1: polar angle p, longitude t
    ([R * p.cos() * t.cos(), R * p.cos() * t.sin(), -R * p.sin()], [-R * p.sin() * t.sin(), R * p.sin() * t.cos(), 0.0])
}
fn plan_polar(rho: f64, t: f64) -> (V, V) {
    // chart 2: distance rho and angle t on the plan
    let s = (R * R - rho * rho).sqrt();
    ([t.cos(), t.sin(), -rho / s], [-rho * t.sin(), rho * t.cos(), 0.0])
}
fn saddle(x: f64, y: f64) -> (V, V) { ([1.0, 0.0, x / SR], [0.0, 1.0, -y / SR]) }
fn cubic(s: f64, t: f64) -> (V, V) {
    // chart 2: x = 15(s + s^3), y = 18(t + t^3)
    let (x, y) = (LX * (s + s * s * s) / 2.0, LY * (t + t * t * t) / 2.0);
    let (xs, yt) = (LX * (1.0 + 3.0 * s * s) / 2.0, LY * (1.0 + 3.0 * t * t) / 2.0);
    ([xs, 0.0, xs * x / SR], [0.0, yt, -yt * y / SR])
}
fn folded(s: f64, y: f64) -> (V, V) {
    // a chart that doubles back: x = 30(2s^2 - 1)
    let (x, xs) = (LX * (2.0 * s * s - 1.0), 4.0 * LX * s);
    ([xs, 0.0, xs * x / SR], [0.0, 1.0, -y / SR])
}
fn roof(x: f64, y: f64) -> V { [x, y, 30.0 + (x * x - y * y) / (2.0 * SR)] }
fn sub(b: V, a: V) -> V { [b[0] - a[0], b[1] - a[1], b[2] - a[2]] }

fn mesh(n: usize) -> f64 {
    // flat triangles pinned to the saddle: no E, F, G
    let (hx, hy) = (2.0 * LX / n as f64, 2.0 * LY / n as f64);
    let mut total = 0.0;
    for i in 0..n {
        for j in 0..n {
            let (x, y) = (-LX + i as f64 * hx, -LY + j as f64 * hy);
            let (p, q, r, s) = (roof(x, y), roof(x + hx, y), roof(x + hx, y + hy), roof(x, y + hy));
            for (a, b, c) in [(p, q, r), (p, r, s)] {
                let n3 = cross(sub(b, a), sub(c, a));
                total += dot(n3, n3).sqrt() / 2.0;
            }
        }
    }
    total
}

fn main() {
    let b = (2.0 * R * H - H * H).sqrt(); // radius of the dome's footprint: 36 m
    let phi0 = ((R - H) / R).acos(); // polar angle at the dome's rim
    let sheet = 0.0006 * 8960.0; // kg per m^2 of 0.6 mm copper sheet
    println!("dome, footprint radius m {:.6}", b);
    println!("dome, rim polar angle rad {:.6} deg {:.6} cos {:.6}", phi0, phi0.to_degrees(), phi0.cos());
    let d_closed = PI * R * H; // half of Archimedes' 2 pi R h
    let d1 = simpson2(sphere, 0.0, phi0, -PI / 2.0, PI / 2.0, 100);
    let d2 = simpson2(plan_polar, 0.0, b, -PI / 2.0, PI / 2.0, 100);
    println!("dome area, closed form pi R h {:.6}", d_closed);
    println!("dome area, chart 1 (sphere)   {:.6}", d1);
    println!("dome area, chart 2 (plan)     {:.6}", d2);
    let d_plan = PI * b * b / 2.0;
    println!("dome plan area {:.6} ratio {:.6}", d_plan, d_closed / d_plan);
    assert!((d1 - d_closed).abs() < 1e-6);
    assert!((d2 - d_closed).abs() < 1e-3);

    let (ru, rv) = saddle(30.0, 36.0);
    let (e, f, g) = efg(ru, rv);
    println!("saddle corner (30, 36): E {:.6} F {:.6} G {:.6}", e, f, g);
    println!("saddle corner: EG {:.6} F^2 {:.6} EG-F^2 {:.6} stretch {:.6}", e * g, f * f, e * g - f * f, stretch(ru, rv));
    let nn = cross(ru, rv);
    println!("saddle corner: |r_x x r_y| {:.6}", dot(nn, nn).sqrt());
    assert!((dot(nn, nn).sqrt() - stretch(ru, rv)).abs() < 1e-12);
    let (cu, cv) = cubic(1.0, 1.0); // same corner in chart 2
    let (e2, f2, g2) = efg(cu, cv);
    println!("same corner, chart 2: E {:.6} F {:.6} G {:.6} stretch {:.6}", e2, f2, g2, stretch(cu, cv));
    println!("chart 2 stretch / chart 1 stretch {:.6} Jacobian x_s y_t {:.6}", stretch(cu, cv) / stretch(ru, rv), 60.0 * 72.0);
    let s1 = simpson2(saddle, -LX, LX, -LY, LY, 200);
    let s2 = simpson2(cubic, -1.0, 1.0, -1.0, 1.0, 200);
    println!("saddle area, chart 1 (plan x, y) {:.6}", s1);
    println!("saddle area, chart 2 (cubic s, t) {:.6}", s2);
    assert!((s1 - s2).abs() < 1e-4);
    let (m1, m2) = (mesh(30), mesh(60));
    println!("saddle area, mesh 30 x 30 {:.6} error {:.6}", m1, m1 - s1);
    println!("saddle area, mesh 60 x 60 {:.6} error {:.6} ratio {:.6}", m2, m2 - s1, (m1 - s1) / (m2 - s1));
    assert!((m2 - s1).abs() < (m1 - s1).abs() / 3.5);
    let s_plan = 2.0 * LX * 2.0 * LY;
    println!("saddle plan area {:.6} ratio {:.6}", s_plan, s1 / s_plan);

    let total = d_closed + s1;
    println!("copper, m^2 {:.6} kg at 5.376 kg/m^2 {:.6}", total, total * sheet);
    println!("plan m^2 {:.6} short by {:.6}", d_plan + s_plan, total - d_plan - s_plan);
    let no_f = simpson2(|x, y| { let (e, _, g) = efg(saddle(x, y).0, saddle(x, y).1); ([e.sqrt(), 0.0, 0.0], [0.0, g.sqrt(), 0.0]) }, -LX, LX, -LY, LY, 200);
    let no_sin = R * R * phi0 * PI; // G taken as R^2: the sin(p)^2 forgotten
    let (a60, b60) = ([0.5, 0.0, 0.0], [0.25, 0.5 * 3f64.sqrt() / 2.0, 0.0]); // diamond shingle, 0.5 m sides at 60 deg
    let (e, f, g) = efg(a60, b60);
    println!("diamond shingle: E {:.6} F {:.6} G {:.6} area {:.6} sqrt(EG) {:.6} ratio {:.6}", e, f, g, stretch(a60, b60), (e * g).sqrt(), (e * g).sqrt() / stretch(a60, b60));
    assert!((stretch(a60, b60) - 0.25 * (PI / 3.0).sin()).abs() < 1e-12);
    let fold = simpson2(folded, -1.0, 1.0, -LY, LY, 200);
    println!("breaks: plan area for saddle {:.6}", s_plan);
    println!("breaks: drop F^2, sqrt(EG) {:.6} excess {:.6}", no_f, no_f - s1);
    println!("breaks: dome with G = R^2 {:.6} times {:.6}", no_sin, no_sin / d_closed);
    println!("breaks: folded chart {:.6} times {:.6}", fold, fold / s1);
    assert!(no_f > s1 + 1.0);
    assert!((fold / s1 - 2.0).abs() < 1e-6);

    println!("try: saddle a = 90 {:.6}", simpson2(|x, y| ([1.0, 0.0, x / 90.0], [0.0, 1.0, -y / 90.0]), -LX, LX, -LY, LY, 200));
    println!("try: dome rise 18 m {:.6} footprint radius {:.6}", PI * R * 18.0, (2.0 * R * 18.0 - 18.0 * 18.0).sqrt());
    println!("try: Simpson n = 4 {:.6}", simpson2(saddle, -LX, LX, -LY, LY, 4));
    println!("try: mesh 6 x 6 {:.6}", mesh(6));
    println!("figure, saddle plan x {:.6} {:.6} y {:.6} {:.6} dome centre x {:.6} radius {:.6}", -LX, LX, -LY, LY, LX, b);
    println!("ALL CHECKS PASS");
}
