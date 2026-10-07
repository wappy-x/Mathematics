// Cross product and oriented area -- the same check as the Python, in Rust.  No crates.
// A 10 m by 6 m solar panel: bottom edge u, sloping edge v, in metres east, north, up.
// Road 1 is the component formula.  Road 2 never forms a cross product: base times
// height for the area, the panel's tilt for the normal.
type V = [f64; 3];

fn cross(u: V, v: V) -> V {
    [u[1] * v[2] - u[2] * v[1], u[2] * v[0] - u[0] * v[2], u[0] * v[1] - u[1] * v[0]]
}

fn dot(u: V, v: V) -> f64 { u[0] * v[0] + u[1] * v[1] + u[2] * v[2] }

fn f(x: f64) -> String {                    // two decimals, and never "-0.00"
    format!("{:.2}", if x.abs() > 5e-10 { x } else { 0.0 })
}

fn vec(a: V) -> String { format!("({}, {}, {})", f(a[0]), f(a[1]), f(a[2])) }

fn det3(a: V, b: V, c: V) -> f64 {          // rows a, b, c; cofactors along the top row
    a[0] * (b[1] * c[2] - b[2] * c[1]) - a[1] * (b[0] * c[2] - b[2] * c[0])
        + a[2] * (b[0] * c[1] - b[1] * c[0])
}

fn main() {
    let cases: [(&str, V, V); 2] = [
        ("case 1, bottom edge due east", [10.0, 0.0, 0.0], [0.0, 4.8, 3.6]),
        ("case 2, the same panel turned", [8.0, 6.0, 0.0], [-2.88, 3.84, 3.6]),
    ];
    for (label, u, v) in cases {
        let w = cross(u, v);                // road 1
        let area = dot(w, w).sqrt();
        let n = w.map(|x| x / area);
        let k = dot(u, v) / dot(u, u);      // road 2: drop v's part along u, keep the height
        let h: V = [v[0] - k * u[0], v[1] - k * u[1], v[2] - k * u[2]];
        let (base, height) = (dot(u, u).sqrt(), dot(h, h).sqrt());
        let (run, rise) = ((h[0] * h[0] + h[1] * h[1]).sqrt(), h[2]); // u is level
        let tilt_n: V = [-h[0] / run * rise / height, -h[1] / run * rise / height, run / height];
        let d = det3(u, v, w);
        println!("{}: u = {}, v = {}", label, vec(u), vec(v));
        println!("  road 1, components: w = u x v = {}, length {} m^2", vec(w), f(area));
        println!("  road 2, base times height: {} m x {} m = {} m^2", f(base), f(height), f(base * height));
        println!("  unit normal by components {}; by the tilt {}", vec(n), vec(tilt_n));
        println!("  w.u = {}, w.v = {}; det of rows u, v, w = {}", f(dot(w, u)), f(dot(w, v)), f(d));
        assert!((area - base * height).abs() < 1e-9);                     // area, two roads
        assert!((0..3).all(|i| (n[i] - tilt_n[i]).abs() < 1e-12));        // normal, two roads
        assert!(dot(w, u).abs() < 1e-9 && dot(w, v).abs() < 1e-9);         // perpendicular
        assert!(d > 0.0 && (d - (w[0] * w[0] + w[1] * w[1] + w[2] * w[2])).abs() < 1e-9);
    }
    let (u, v) = (cases[0].1, cases[0].2);
    let w = cross(u, v);
    let bad: V = [u[1] * v[2] - u[2] * v[1], u[0] * v[2] - u[2] * v[0], u[0] * v[1] - u[1] * v[0]];
    let a = dot(w, w).sqrt();
    println!("tilt from level {:.2} degrees; sin of the edge angle = {}",
             v[2].atan2(v[1]).to_degrees(), f(a / (dot(u, u) * dot(v, v)).sqrt()));
    println!("shadows: ground {}, east-west wall {}, north-south wall {}; squares add to {}",
             f(w[2]), f(w[1]), f(w[0]), f(dot(w, w)));
    println!("order swapped: v x u = {}, length {} m^2, facing down", vec(cross(v, u)), f(a));
    println!("mistake, middle sign unflipped: {}; dot with v = {}, not 0", vec(bad), f(dot(bad, v)));
    println!("mistake, dot product read as area: u.v = {}, not {}", f(dot(u, v)), f(a));
    println!("mistake, triangle half-panel left unhalved: {} instead of {} m^2", f(a), f(a / 2.0));
    println!("figure, 1 m = 40 units: foot (100, 200), top ({:.0}, {:.0}), normal ({:.0}, {:.0}) to ({:.0}, {:.0})",
             100.0 + 40.0 * v[1], 200.0 - 40.0 * v[2], 100.0 + 20.0 * v[1], 200.0 - 20.0 * v[2],
             100.0 + 20.0 * v[1] + 80.0 * w[1] / a, 200.0 - 20.0 * v[2] - 80.0 * w[2] / a);
    println!("ALL CHECKS PASS");
}
