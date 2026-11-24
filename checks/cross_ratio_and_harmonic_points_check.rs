// Cross-ratio and harmonic points -- the same check as the Python, in Rust, std
// only.  A level pinhole camera, 1 m above the track, focal length 1, sees a
// sleeper Z m ahead 1/Z focal lengths below the horizon.
const GROUND: [f64; 4] = [4.0, 5.0, 6.0, 7.0];               // sleepers, metres ahead

fn cr(a: f64, b: f64, c: f64, d: f64) -> f64 { (c - a) * (d - b) / ((c - b) * (d - a)) }
fn cr4(v: &[f64]) -> f64 { cr(v[0], v[1], v[2], v[3]) }
fn solve(a: f64, b: f64, c: f64, k: f64) -> Option<f64> {   // the x with cr(a, b, c, x) = k
    let den = (c - a) - k * (c - b);
    if den.abs() < 1e-12 { None } else { Some(((c - a) * b - k * (c - b) * a) / den) }
}
fn tipped(z: f64) -> f64 { ((1.0 / z).atan() - 10f64.to_radians()).tan() } // tipped 10 degrees down
fn cross(u: [f64; 3], v: [f64; 3]) -> [f64; 3] {
    [u[1] * v[2] - u[2] * v[1], u[2] * v[0] - u[0] * v[2], u[0] * v[1] - u[1] * v[0]]
}
fn dot(u: [f64; 3], v: [f64; 3]) -> f64 { u[0] * v[0] + u[1] * v[1] + u[2] * v[2] }
fn fit(pairs: &[(f64, f64)]) -> Vec<f64> {   // road 2: the map z = (p y + q)/(r y + s) through three pairs
    let rows: Vec<[f64; 4]> = pairs.iter().map(|&(y, z)| [y, 1.0, -z * y, -z]).collect();
    (0..4).map(|j| {
        let m: Vec<[f64; 3]> = rows.iter().map(|r| {
            let k: Vec<f64> = (0..4).filter(|&i| i != j).map(|i| r[i]).collect();
            [k[0], k[1], k[2]]
        }).collect();
        (if j % 2 == 0 { 1.0 } else { -1.0 }) * dot(m[0], cross(m[1], m[2]))
    }).collect()
}
fn num(x: f64) -> String {
    let s = format!("{:.6}", x);
    let s = s.trim_end_matches('0').trim_end_matches('.');
    if s == "-0" { "0".to_string() } else { s.to_string() }
}
fn nums(v: &[f64]) -> String { v.iter().map(|&x| num(x)).collect::<Vec<_>>().join(", ") }
fn pt(v: [f64; 3]) -> String { format!("({}, {})", num(v[0] / v[2]), num(v[1] / v[2])) }

fn main() {
    let photo: Vec<f64> = GROUND.iter().map(|z| 1.0 / z).collect();
    let tilt: Vec<f64> = GROUND.iter().map(|&z| tipped(z)).collect();
    let t = 10f64.to_radians().tan();                          // t: the tipped camera's map (Step 1)
    let k = cr4(&photo);
    let (top, bot) = ((photo[2] - photo[0]) * (photo[3] - photo[1]), (photo[2] - photo[1]) * (photo[3] - photo[0]));
    println!("ground: sleepers at {} m; cross-ratio (6-4)(7-5)/((6-5)(7-4)) = {}", nums(&GROUND), num(cr4(&GROUND)));
    println!("level photo: heights {} focal lengths below the horizon", nums(&photo));
    println!("level photo: top ({})({}) = {} = 1/{}, bottom ({})({}) = {} = 1/{}, cross-ratio {}", num(photo[2] - photo[0]), num(photo[3] - photo[1]),
             num(top), num(1.0 / top), num(photo[2] - photo[1]), num(photo[3] - photo[0]), num(bot), num(1.0 / bot), num(k));
    println!("photo tipped 10 degrees down: heights {} from centre; cross-ratio {}", nums(&tilt), num(cr4(&tilt)));
    println!("tipped map: t = tan 10 degrees = {}, (p, q, r, s) = ({}), ps - qr = {}", num(t), nums(&[-t, 1.0, 1.0, t]), num(-t * t - 1.0));
    for (z, y) in GROUND.iter().zip(&photo) {
        println!("bar, sleeper {} m  {:<25}  {}", num(*z), "#".repeat((100.0 * y).round() as usize), num(*y));
    }
    let (r1, r3, rt) = (solve(4.0, 5.0, 6.0, k).unwrap(), 1.0 / photo[3], solve(4.0, 5.0, 6.0, cr4(&tilt)).unwrap());
    let m = fit(&[(photo[0], 4.0), (photo[1], 5.0), (photo[2], 6.0)]);
    let m: Vec<f64> = m.iter().map(|x| x / m[1]).collect();
    let r2 = (m[0] * photo[3] + m[1]) / (m[2] * photo[3] + m[3]);
    println!("road 1, photo cross-ratio solved with sleepers 4, 5, 6: fourth sleeper at {} m", num(r1));
    println!("road 2, map through three photo-ground pairs: (p, q, r, s) = ({}); sends {} to {} m", nums(&m), num(photo[3]), num(r2));
    println!("road 3, the camera's own ray, 1 m drop over Z m: {} m; the tipped photo by cross-ratio: {} m", num(r3), num(rt));
    let (g, h) = (solve(4.0, 6.0, 5.0, -1.0), solve(0.25, 1.0 / 6.0, 0.2, -1.0).unwrap());
    println!("harmonic, ground: conjugate of 5 against 4 and 6: {}", g.map_or("at infinity".to_string(), num));
    println!("harmonic, photo: conjugate of 0.2 against 0.25 and 0.166667: {}; harmonic mean 2(0.25)(0.166667)/{} = {}",
             num(h), num(photo[0] + photo[2]), num(2.0 * photo[0] * photo[2] / (photo[0] + photo[2])));
    let (a, b, c, p) = ([0.0, 0.25, 1.0], [0.0, 1.0 / 6.0, 1.0], [0.0, 0.2, 1.0], [1.0, 0.1, 1.0]); // a, b, c on u = 0
    let q = [(p[0] + c[0]) / 2.0, (p[1] + c[1]) / 2.0, 1.0];                    // q halfway along pc
    let (r, s) = (cross(cross(a, q), cross(p, b)), cross(cross(b, q), cross(p, a)));
    let d = cross(cross(r, s), cross(a, b));
    println!("figure, A {}, B {}, C {}, P {}, Q {}, R {}, S {}; line RS meets the centre line at D {}",
             pt(a), pt(b), pt(c), pt(p), pt(q), pt(r), pt(s), pt(d));
    let prop = 4.0 + (photo[0] - photo[3]) / (photo[0] - photo[1]);
    println!("mistake, simple ratio AC/BC: ground {}, photo {}; gap {} read as 1 m makes gap {} read as {} m, fourth sleeper at {} m",
             num((6.0 - 4.0) / (6.0 - 5.0)), num((photo[2] - photo[0]) / (photo[2] - photo[1])),
             num(photo[0] - photo[1]), num(photo[0] - photo[3]), num(prop - 4.0), num(prop));
    let wrong = cr(4.0, 6.0, 5.0, 7.0);
    println!("mistake, order A, C, B, D: cross-ratio {}; solved, fourth sleeper at {} m", num(wrong), num(solve(4.0, 5.0, 6.0, wrong).unwrap()));
    println!("mistake, photo midpoint of 4 and 6: height {}, read as {} m", num((photo[0] + photo[2]) / 2.0), num(2.0 / (photo[0] + photo[2])));
    assert!(GROUND.iter().zip(&tilt).all(|(z, y)| ((1.0 - t * z) / (z + t) - y).abs() < 1e-12)); // Step 1's map = the camera
    assert!((cr4(&GROUND) - k).abs() < 1e-12 && (cr4(&tilt) - k).abs() < 1e-12);       // invariance, two cameras
    assert!((r1 - r3).abs() < 1e-9 && (r2 - r3).abs() < 1e-9 && (rt - r3).abs() < 1e-9); // three roads to 7 m
    assert!(g.is_none() && (d[1] / d[2] - h).abs() < 1e-12 && (d[0] / d[2]).abs() < 1e-12); // construction = formula
    assert!((cr(0.25, 1.0 / 6.0, 0.2, d[1] / d[2]) + 1.0).abs() < 1e-12 && (prop - r3).abs() > 0.5);
    println!("ALL CHECKS PASS");
}
