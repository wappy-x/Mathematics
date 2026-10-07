// Similar triangles and scale -- the check behind the card.  std only.
// A metre stick and a flagpole stand on level ground in the same sun.
// The pole's height is found twice: by scaling the stick (road one) and by
// hunting the height that makes the sun's angle match (road two).  Areas are
// found by the formula and by counting 1 cm squares.  A river is crossed too.

fn cos_at_tip(height: f64, shadow: f64) -> f64 {
    // dot product of the two sides at the shadow tip, over their lengths
    shadow / (shadow * shadow + height * height).sqrt()
}

fn count_cm2(hc: i64, sc: i64) -> i64 {
    // squares of 1 cm whose centre lies under the ray
    let mut n = 0;
    for i in 0..sc {
        for j in 0..hc {
            if (2 * j + 1) * sc + (2 * i + 1) * hc < 2 * hc * sc {
                n += 1;
            }
        }
    }
    n
}

fn main() {
    let (h, s, big_s) = (1.0_f64, 0.8_f64, 9.6_f64); // stick height, stick shadow, pole shadow (m)
    let k = big_s / s; // road one: the scale factor
    let h1 = h * k;

    let (mut lo, mut hi) = (0.0_f64, 1000.0_f64); // road two: bisection on the pole height
    for _ in 0..200 {
        let mid = (lo + hi) / 2.0;
        if cos_at_tip(mid, big_s) > cos_at_tip(h, s) { lo = mid; } else { hi = mid; }
    }
    let h2 = (lo + hi) / 2.0;
    assert!((h1 - h2).abs() < 1e-9);

    let (a_stick, a_pole) = (h * s / 2.0, h1 * big_s / 2.0);
    let (c_stick, c_pole) = (count_cm2(100, 80) as f64, count_cm2(1200, 960) as f64);
    assert!((c_pole / 1e4 - a_pole).abs() / a_pole < 0.005);
    assert!((c_pole / c_stick - k * k).abs() / (k * k) < 0.01);

    let (near, on, back) = (30.0_f64, 10.0_f64, 6.0_f64); // river: Q 30 m along, R 10 m on, S 6 m back
    let w1 = back * near / on; // road one: scale the small triangle
    let (x1, y1, x2, y2) = (on + near, -back, near, 0.0_f64); // road two: line S to Q meets x = 0
    let w2 = y1 + (0.0 - x1) * (y2 - y1) / (x2 - x1);
    assert!((w1 - w2).abs() < 1e-9);

    println!("flagpole: stick {:.1} m casts {:.1} m, pole casts {:.1} m", h, s, big_s);
    println!("scale factor k = {:.0}", k);
    println!("road 1, scale the stick: pole height {:.6} m", h1);
    println!("road 2, match the sun's angle by bisection: pole height {:.6} m", h2);
    let (sun, top) = (h.atan2(s).to_degrees(), s.atan2(h).to_degrees());
    println!("angles: sun {:.1} at both tips, top {:.1}, with the right angle {:.1}", sun, top, sun + top + 90.0);
    println!("areas by formula: stick {:.6} m^2, pole {:.6} m^2", a_stick, a_pole);
    println!("areas by counting 1 cm squares: stick {:.4} m^2, pole {:.4} m^2", c_stick / 1e4, c_pole / 1e4);
    println!("area ratio: formula {:.4}, counted {:.4}, k^2 = {:.0}", a_pole / a_stick, c_pole / c_stick, k * k);
    println!("river: factor {:.0}, road 1, scale the 6 m walk: width {:.6} m", near / on, w1);
    println!("river: road 2, intersect the sight line: width {:.6} m", w2);
    println!("mistake, ratio upside down: {:.6} m", s * big_s / h);
    println!("mistake, area scaled by k: {:.6} m^2", a_stick * k);
    println!("mistake, stick shadow read later at 1.2 m: {:.6} m", h * big_s / 1.2);
    let (g, m) = (220.0_f64, 16.0_f64); // figures: ground line and units per metre
    println!("figure, flag (1 m = 16): pole (40.0,{:.1})-(40.0,{:.1}), tip ({:.1},{:.1}), stick top (260.0,{:.1}), tip ({:.1},{:.1})",
             g, g - h1 * m, 40.0 + big_s * m, g, g - h * m, 260.0 + s * m, g);
    println!("figure, river (1 m = 6): P (50,150), T (50,{:.0}), Q ({:.0},150), R ({:.0},150), S ({:.0},{:.0})",
             150.0 - w1 * 6.0, 50.0 + near * 6.0, 50.0 + (near + on) * 6.0, 50.0 + (near + on) * 6.0, 150.0 + back * 6.0);
    println!("ALL CHECKS PASS");
}
