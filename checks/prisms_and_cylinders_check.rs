// Prisms and cylinders -- the same check as the Python, in Rust.  No crates.
// The tank is a cylinder 2 m across (radius 1 m) and 3 m tall.  Road one: base
// area times height.  Two more roads never touch pi: count cubes of water, and
// squeeze the tank between prisms on many-sided bases built by Pythagoras alone.
use std::f64::consts::PI;

const R: f64 = 1.0; // radius, in metres
const H: f64 = 3.0; // height, in metres

fn cubes(n: i64) -> (i64, i64) { // cubes of edge 1/n m: wholly inside, touching
    let m = (R * n as f64).round() as i64;
    let (mut inside, mut touching) = (0, 0);
    for i in -m..m { // one layer, cell corners i..i+1, j..j+1
        for j in -m..m {
            let far = (i * i).max((i + 1) * (i + 1)) + (j * j).max((j + 1) * (j + 1));
            let near = (i * i).min((i + 1) * (i + 1)) + (j * j).min((j + 1) * (j + 1));
            if far <= m * m { inside += 1 } // farthest corner inside the circle
            if near < m * m { touching += 1 } // nearest corner inside the circle
        }
    }
    let layers = (H * n as f64).round() as i64;
    (inside * layers, touching * layers) // one layer, times the layers
}

fn main() {
    let (base, rim) = (PI * R * R, 2.0 * PI * R); // circle area and circumference
    let (vol, side) = (base * H, rim * H); // base x height; perimeter x height
    let l = vol * 1000.0; // 1000 litre cubes to the cubic metre
    println!("tank: {:.0} m across, radius {:.0} m, {:.0} m tall", 2.0 * R, R, H);
    println!("base area {:.6} m^2; volume {:.6} m^3, x 1000 = {:.2} litres", base, vol, l);
    println!("each cm of depth: {:.4} litres, x {:.0} cm = {:.2}; each 1 m slice: {:.2}",
             base * 10.0, H * 100.0, l, base * 1000.0);
    println!("circumference {:.6} m; side {:.6}, with floor {:.6}, closed {:.6} m^2",
             rim, side, side + base, side + 2.0 * base);
    let (d, k, z) = (2.0 * R, (20.0 * R).round() as i64, (10.0 * H).round() as i64); // the box; litre cubes
    println!("square box {:.0} x {:.0} x {:.0} m: {} x {} = {} litre cubes a layer, x {} layers = {} litres",
             d, d, H, k, k, k * k, z, k * k * z);
    println!("box skin: perimeter {:.0} m x {:.0} m = {:.0} m^2 of walls, + 2 x {:.0} m^2 of ends = {:.0} m^2; tank / box = {:.6}",
             4.0 * d, H, 4.0 * d * H, d * d, 4.0 * d * H + 2.0 * d * d, vol / (d * d * H));
    let ((lo1, hi1), (lo2, hi2)) = (cubes(10), cubes(100));
    println!("litre cubes (10 cm): {} wholly inside, {} touching the tank", lo1, hi1);
    println!("millilitre cubes (1 cm): {} to {}, so {:.2} to {:.2} litres",
             lo2, hi2, lo2 as f64 / 1000.0, hi2 as f64 / 1000.0);
    let (mut rows, mut s, mut n): (Vec<(f64, f64, f64, f64, f64)>, f64, f64) = (vec![], 2f64.sqrt() * R, 4.0);
    while n <= 4096.0 { // a square inside the circle, then double the sides
        let a = (R * R - s * s / 4.0).sqrt(); // centre to the middle of a side
        rows.push((n, n * s * a / 2.0 * H * 1000.0, n * s * R * R / (2.0 * a) * H * 1000.0,
                   n * s * H, n * s * R / a * H)); // inside and outside prisms
        s = (R * s * s / (2.0 * (R + a))).sqrt(); // the new side, by Pythagoras
        n *= 2.0;
    }
    for &(n, vin, vout, sin, sout) in &rows {
        if [4.0, 16.0, 256.0, 4096.0].contains(&n) {
            println!("prisms, {} sides: {:.2} to {:.2} litres; side {:.6} to {:.6} m^2", n, vin, vout, sin, sout);
        }
    }
    println!("mistake, diameter as radius: {:.2} litres", PI * (2.0 * R).powi(2) * H * 1000.0);
    println!("mistake, circumference as base area: {:.2} litres", rim * H * 1000.0);
    println!("mistake, 100 litres to the cubic metre: {:.2} litres", vol * 100.0);
    println!("mistake, paint for the side only: {:.2} of {:.2} m^2", side, side + 2.0 * base);
    println!("figure, tank at 1 m = 55: walls x {:.0} and {:.0}, rim y 32, slices y {:.0} and {:.0}, floor y {:.0}, ends {:.2} deep",
             125.0 - 55.0 * R, 125.0 + 55.0 * R, 32.0 + 55.0, 32.0 + 110.0, 32.0 + 55.0 * H, 55.0 * R / 4.0);
    println!("figure, net at 1 m = 30: side 30 to {:.2} by 75 to {:.0} ({:.2} m by {:.0} m, {:.2} m^2); ends centred x {:.2}, y {:.0} and {:.0}, radius {:.0} ({:.2} m^2 each)",
             30.0 + 30.0 * rim, 75.0 + 30.0 * H, rim, H, side, 30.0 + 15.0 * rim, 75.0 - 30.0 * R, 75.0 + 30.0 * H + 30.0 * R, 30.0 * R, base);
    let (lo1, hi1, lo2, hi2) = (lo1 as f64, hi1 as f64, lo2 as f64, hi2 as f64);
    assert!(lo1 < l && l < hi1 && lo2 / 1000.0 < l && l < hi2 / 1000.0 && (hi2 - lo2) / 1000.0 < (hi1 - lo1) / 5.0);
    assert!(rows.iter().all(|r| r.1 < l && l < r.2) && rows[rows.len() - 1].2 - rows[rows.len() - 1].1 < 1e-6 * l);
    assert!(rows.iter().all(|r| r.3 < side && side < r.4) && rows[rows.len() - 1].4 - rows[rows.len() - 1].3 < 1e-6 * side);
    println!("ALL CHECKS PASS");
}
