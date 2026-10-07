// Circles, on a bicycle wheel 70 cm across.  No crates, and std's own pi is not
// used.  Road one finds pi from polygons inside and outside the rim.  Road two
// measures the rim and the disc on a grid, with Pythagoras alone.  Lengths are
// in cm, areas in square cm.
const D: f64 = 70.0;
const R: f64 = D / 2.0;

fn pi_bounds(doublings: u32) -> (u64, f64, f64) { // radius 1; perimeter over the width, 2
    let (mut n, mut s) = (6u64, 1.0f64);           // hexagon inside: each side equals the radius
    for _ in 0..doublings {                        // double the sides, by Pythagoras
        n *= 2;
        s = s / (2.0 + (4.0 - s * s).sqrt()).sqrt();
    }
    let t = s / (1.0 - s * s / 4.0).sqrt();        // side of the matching polygon outside
    (n, n as f64 * s / 2.0, n as f64 * t / 2.0)
}

fn walk(r: f64, hops: u32) -> f64 {                // an eighth of the rim in straight hops, x 8
    let (end, mut total, mut x0, mut y0) = (r / 2f64.sqrt(), 0.0, 0.0, r);
    for k in 1..=hops {
        let x = end * k as f64 / hops as f64;
        let y = (r * r - x * x).sqrt();            // the rim point above x, by Pythagoras
        total += ((x - x0).powi(2) + (y - y0).powi(2)).sqrt();
        x0 = x;
        y0 = y;
    }
    8.0 * total
}

fn squares(r: f64, per_cm: i64) -> (f64, f64) {   // grid squares wholly inside, and touching, x 4
    let (m, mut inside, mut touch) = ((r * per_cm as f64).round() as i64, 0i64, 0i64);
    for i in 0..m {
        for j in 0..m {
            if (i + 1).pow(2) + (j + 1).pow(2) <= m * m { inside += 1 }
            if i * i + j * j < m * m { touch += 1 }
        }
    }
    let cell = (per_cm * per_cm) as f64;
    (4.0 * inside as f64 / cell, 4.0 * touch as f64 / cell)
}

fn main() {
    let ((n6, lo6, hi6), (n96, lo96, hi96), (nf, pi, hi)) = (pi_bounds(0), pi_bounds(4), pi_bounds(20));
    let (c, a, rim) = (pi * D, pi * R * R, walk(R, 10000));
    let ((c_lo, c_hi), (m_lo, m_hi)) = (squares(R, 1), squares(R, 10));
    let gaps: Vec<String> = (0..5).map(|k| { let (_, l, h) = pi_bounds(k); format!("{:.6}", h - l) }).collect();
    let ends: Vec<String> = [28.0, 21.0, 14.0, 7.0].iter().map(|p| format!("{:.2}", 44.0 + 1.4 * 2.0 * pi * p)).collect();
    println!("wheel: diameter {:.0} cm, radius {:.0} cm", D, R);
    println!("pi from {} sides: between {:.6} and {:.6}", n6, lo6, hi6);
    println!("pi from {} sides: between {:.6} and {:.6}; Archimedes wrote {:.6} and {:.6}",
             n96, lo96, hi96, 3.0 + 10.0 / 71.0, 3.0 + 1.0 / 7.0);
    println!("gap, outside minus inside, 6 to 96 sides: {}", gaps.join(", "));
    println!("pi from {} sides: between {:.10} and {:.10}", nf, pi, hi);
    println!("distance per turn, pi x {:.0}: {:.6} cm; turns per km: {:.2}", D, c, 100000.0 / c);
    println!("distance per turn, 10000 hops round an eighth of the rim, x 8: {:.6} cm", rim);
    println!("disc, pi x {:.0} x {:.0}: {:.6}; unrolled, half of {:.6} x {:.0}: {:.6}", R, R, a, c, R, c * R / 2.0);
    println!("disc, centimetre squares: between {:.0} and {:.0}", c_lo, c_hi);
    println!("disc, millimetre squares: between {:.2} and {:.2}", m_lo, m_hi);
    println!("disc / radius^2 from the squares: between {:.6} and {:.6}", m_lo / R / R, m_hi / R / R);
    println!("second case, wheel {:.0} cm: {:.6} cm per turn, disc {:.6}", 2.0 * D, pi * 2.0 * D, pi * D * D);
    println!("measuring wheel, 100 cm per turn: diameter {:.6} cm", 100.0 / pi);
    println!("mistake, radius in pi x d: {:.6} cm per turn", pi * R);
    println!("mistake, pi as 3: {:.6} cm per turn; a real km reads {:.6} km", 3.0 * D, 3.0 * D / c);
    println!("mistake, diameter in pi r^2: {:.6}; whole rim x radius: {:.6}", pi * D * D, c * R);
    println!("figure 1, 1 cm = 1.1: centres (50, 71.5) and ({:.2}, 71.5), radius {:.1}", 50.0 + 1.1 * c, 1.1 * R);
    println!("figure 2, 1 cm = 1.4: disc radius {:.0}, rings {:.0} cm wide; base ends at ({:.2}, 215); strips end at x {}",
             1.4 * R, R / 5.0, 44.0 + 1.4 * c, ends.join(", "));
    assert!(3.0 + 10.0 / 71.0 < lo96 && lo96 < pi && pi < hi && hi < hi96 && hi96 < 3.0 + 1.0 / 7.0);
    assert!((rim - c).abs() < 1e-6);                  // rim: grid walk against pi x 70
    assert!(c_lo < m_lo && m_lo < a && a < m_hi && m_hi < c_hi); // disc: mm squares inside cm, around pi r^2
    assert!(m_lo < rim * R / 2.0 && rim * R / 2.0 < m_hi); // half rim x radius, no pi at all
    println!("ALL CHECKS PASS");
}
