// Stokes' theorem -- the same check as the Python, in Rust, std only.  A bowl: the lower half of a
// sphere of radius 2 m, rim at height 0.  Wind circles the rim anticlockwise seen from above.
// Road one: circulation round the rim.  Road two: difference-quotient curl, its flux through the bowl.
type V3 = [f64; 3];
type Field = dyn Fn(V3) -> V3;
const R: f64 = 2.0; const W: f64 = 0.5; // bowl radius (m); swirl rate (per second)

fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let w = |j: usize| if j == 0 || j == n { 1.0 } else if j % 2 == 1 { 4.0 } else { 2.0 };
    h / 3.0 * (0..=n).map(|j| w(j) * f(a + j as f64 * h)).sum::<f64>()
}
fn pi() -> f64 { simpson(&|t| 4.0 / (1.0 + t * t), 0.0, 1.0, 200) } // pi, built, not imported
fn swirl(p: V3) -> V3 { [-W * p[1], W * p[0], 0.0] } // 1 m/s at the rim, same at every depth
fn fading(p: V3) -> V3 { swirl(p).map(|c| (1.0 + p[2] / R) * c) } // the same swirl, dying away to the bottom
fn drain(p: V3) -> V3 { let q = p[0] * p[0] + p[1] * p[1]; [-2.0 * p[1] / q, 2.0 * p[0] / q, 0.0] }
fn dot(a: V3, b: V3) -> f64 { a[0] * b[0] + a[1] * b[1] + a[2] * b[2] }
fn cross(a: V3, b: V3) -> V3 { [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]] }
fn curl(f: &Field, p: V3) -> V3 { // d[i][j]: rate of F_i along axis j
    let (h, mut d) = (1e-4, [[0.0; 3]; 3]);
    for j in 0..3 {
        let (mut up, mut dn) = (p, p); up[j] += h; dn[j] -= h;
        let (a, b) = (f(up), f(dn));
        for i in 0..3 { d[i][j] = (a[i] - b[i]) / (2.0 * h) }
    }
    [d[2][1] - d[1][2], d[0][2] - d[2][0], d[1][0] - d[0][1]]
}
fn rate(f: &dyn Fn(f64) -> V3, t: f64) -> V3 { // velocity of a moving point
    let (a, b, h) = (f(t + 1e-5), f(t - 1e-5), 1e-5);
    [(a[0] - b[0]) / (2.0 * h), (a[1] - b[1]) / (2.0 * h), (a[2] - b[2]) / (2.0 * h)]
}
fn rim(f: &Field, turn: f64) -> f64 { // road one: add F . dr round the rim
    let c = |t: f64| [R * t.cos(), turn * R * t.sin(), 0.0];
    simpson(&|t| dot(f(c(t)), rate(&c, t)), 0.0, 2.0 * pi(), 64)
}
fn flux(g: &dyn Fn(V3) -> V3, chart: &dyn Fn(f64, f64) -> V3, u: (f64, f64), v: (f64, f64), n: usize) -> f64 {
    let at = |a: f64, b: f64| dot(g(chart(a, b)), cross(rate(&|s| chart(s, b), a), rate(&|s| chart(a, s), b)));
    simpson(&|a| simpson(&|b| at(a, b), v.0, v.1, n), u.0, u.1, n) // G . (r_u x r_v), added over the chart
}
fn bowl(th: f64, ph: f64) -> V3 { [R * ph.sin() * th.cos(), R * ph.sin() * th.sin(), R * ph.cos()] }
fn lid(r: f64, th: f64) -> V3 { [r * th.cos(), r * th.sin(), 0.0] }
fn bowl_curl(f: &Field, n: usize) -> f64 { flux(&|p| curl(f, p), &bowl, (0.0, 2.0 * pi()), (pi() / 2.0, pi()), n) }
fn lid_curl(f: &Field) -> f64 { flux(&|p| curl(f, p), &lid, (0.0, R), (0.0, 2.0 * pi()), 128) }
fn v3(v: V3) -> String {
    let s: Vec<String> = v.iter().map(|&x| format!("{:.3}", if x.abs() < 5e-10 { x.abs() } else { x })).collect();
    format!("({})", s.join(", "))
}
fn main() {
    let s2 = 2f64.sqrt();
    let hand = 2.0 * pi() * W * R * R;
    println!("pi, built by Simpson on 4/(1+t^2): {:.12}", pi());
    println!("swirl: speed at the rim {:.3} m/s; curl at (2, 0, 0) and (1, 0.5, -1): {} {}", dot(swirl([2.0, 0.0, 0.0]), swirl([2.0, 0.0, 0.0])).sqrt(),
             v3(curl(&swirl, [2.0, 0.0, 0.0])), v3(curl(&swirl, [1.0, 0.5, -1.0])));
    println!("curl of fading at rim, halfway down, bottom: {} {} {}", v3(curl(&fading, [2.0, 0.0, 0.0])),
             v3(curl(&fading, [s2, 0.0, -s2])), v3(curl(&fading, [0.0, 0.0, -2.0])));
    for (name, f) in [("swirl", &swirl as &Field), ("fading", &fading)] {
        println!("{}: rim circulation {:.6}; curl flux, bowl {:.6}; lid {:.6}", name, rim(f, 1.0), bowl_curl(f, 128), lid_curl(f));
    }
    println!("by hand, 2 pi w R^2 = {:.9}", hand);
    for n in [2, 4, 8, 16] {
        let b = bowl_curl(&fading, n);
        println!("fading, bowl with {:2} Simpson strips a side: {:.9}, error {:.9}", n, b, (b - hand).abs());
    }
    let out = flux(&|p| curl(&fading, p), &|ph, th| bowl(th, ph), (pi() / 2.0, pi()), (0.0, 2.0 * pi()), 128);
    let area = flux(&|p| p.map(|c| -c / R), &bowl, (0.0, 2.0 * pi()), (pi() / 2.0, pi()), 128);
    println!("break 1, normal out of the bowl, rim unchanged: {:.3} against {:.3}", out, rim(&fading, 1.0));
    let c = curl(&swirl, [1.0, 1.0, -1.0]);
    let size = dot(c, c).sqrt();
    println!("break 2, curl size times bowl area: {:.3} x {:.3} = {:.3}", size, area, size * area);
    println!("break 3, flux of the wind itself through the bowl: {:.3}", flux(&swirl, &bowl, (0.0, 2.0 * pi()), (pi() / 2.0, pi()), 128).abs());
    println!("break 4, drain wind: rim circulation {:.3}; curl at (1, 0.5, -1) {}", rim(&drain, 1.0), v3(curl(&drain, [1.0, 0.5, -1.0])));
    let tip = |p: V3| { let c = curl(&fading, p); format!("{:.0},{:.0}", 180.0 + 60.0 * p[0] + 50.0 * c[0], 60.0 - 60.0 * p[2] - 50.0 * c[2]) };
    let pts = [[2.0, 0.0, 0.0], [-2.0, 0.0, 0.0], [s2, 0.0, -s2], [-s2, 0.0, -s2], [0.0, 0.0, 0.0]];
    println!("figure, 60 px per m, 50 px per 1/s; curl tips {}", pts.iter().map(|&p| tip(p)).collect::<Vec<_>>().join(" "));
    assert!((rim(&fading, 1.0) - bowl_curl(&fading, 128)).abs() < 1e-6 && (rim(&swirl, 1.0) - bowl_curl(&swirl, 128)).abs() < 1e-6); // two roads
    assert!((bowl_curl(&fading, 128) - hand).abs() < 1e-6); // the hand count on the curved sheet
    assert!((lid_curl(&fading) - rim(&fading, 1.0)).abs() < 1e-6 && rim(&fading, -1.0) < 0.0); // Green's flat case; turn matters
    assert!((rim(&drain, 1.0) - hand).abs() < 1e-6 && curl(&drain, [1.0, 0.5, -1.0])[2].abs() < 1e-6); // the drain breaks it
    println!("ALL CHECKS PASS");
}
