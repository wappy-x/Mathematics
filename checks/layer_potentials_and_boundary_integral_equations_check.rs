// Layer potentials -- the check behind the card.  Rust std only, no crates.
// A 5 cm steel bar lies across a stream of water at 1 m/s.  Lengths are scaled
// by its radius a = 2.5 cm, so its rim is the unit circle.  Roads: (1) the
// closed form from the constant circle kernel, (2) a Nystrom solve of the
// boundary equation, (3) the potential summed by quadrature against a known
// harmonic function, (4) the jumps read off near the rim from both sides.
use std::f64::consts::PI;
const TAU: f64 = 2.0 * PI; const A_M: f64 = 0.025; const U: f64 = 1.0; // 2 pi; bar radius in m; stream in m/s
type P = (f64, f64);
type Node = (f64, P, P, f64, f64); // t, point, outward unit normal, speed, curvature

fn fx(v: f64) -> f64 { if v.abs() < 5e-7 { 0.0 } else { v } }
fn show(label: &str, vals: &[f64]) {
    println!("{},{}", label, vals.iter().map(|v| format!(" {:.6}", fx(*v))).collect::<Vec<_>>().join(","));
}
fn sci(v: f64) -> String { // Python's "%.1e"
    let s = format!("{:.1e}", v); let (m, e) = s.split_once('e').unwrap(); let e: i32 = e.parse().unwrap();
    format!("{}e{}{:02}", m, if e < 0 { '-' } else { '+' }, e.abs())
}
fn circle(t: f64) -> (P, P, f64, f64) { ((t.cos(), t.sin()), (t.cos(), t.sin()), 1.0, 1.0) }
fn big(t: f64) -> (P, P, f64, f64) { ((2.0 * t.cos(), 2.0 * t.sin()), (t.cos(), t.sin()), 2.0, 0.5) }
fn oval(t: f64) -> (P, P, f64, f64) {
    let b = 0.6;
    let j = (t.sin().powi(2) + (b * t.cos()).powi(2)).sqrt();
    ((t.cos(), b * t.sin()), (b * t.cos() / j, t.sin() / j), j, b / j.powi(3))
}
fn dk(x: P, y: P, ny: P) -> f64 {
    let (dx, dy) = (x.0 - y.0, x.1 - y.1);
    (dx * ny.0 + dy * ny.1) / (dx * dx + dy * dy) / TAU
}
fn sk(x: P, y: P) -> f64 { -((x.0 - y.0).hypot(x.1 - y.1)).ln() / TAU }
fn nodes(c: fn(f64) -> (P, P, f64, f64), n: usize) -> Vec<Node> {
    (0..n).map(|j| { let t = TAU * j as f64 / n as f64; let (p, q, s, k) = c(t); (t, p, q, s, k) }).collect()
}
fn dlayer(c: fn(f64) -> (P, P, f64, f64), n: usize, mu: &dyn Fn(f64) -> f64, x: P) -> f64 {
    nodes(c, n).iter().map(|&(t, y, ny, j, _)| dk(x, y, ny) * mu(t) * j * TAU / n as f64).sum()
}
fn slayer(c: fn(f64) -> (P, P, f64, f64), n: usize, sig: &dyn Fn(f64) -> f64, x: P) -> f64 {
    nodes(c, n).iter().map(|&(t, y, _, j, _)| sk(x, y) * sig(t) * j * TAU / n as f64).sum()
}
fn nystrom(c: fn(f64) -> (P, P, f64, f64), n: usize, half: f64, adjoint: bool) -> (Vec<Vec<f64>>, Vec<Node>) {
    let nd = nodes(c, n);
    let mut a = vec![vec![0.0; n]; n];
    for (i, &(_, xi, ni, _, _)) in nd.iter().enumerate() {
        for (j, &(_, yj, nj, jj, kj)) in nd.iter().enumerate() {
            let kern = if i == j { -kj / (2.0 * TAU) } else if adjoint { dk(yj, xi, ni) } else { dk(xi, yj, nj) };
            a[i][j] = kern * jj * TAU / n as f64 + if i == j { half } else { 0.0 };
        }
    }
    (a, nd)
}
fn solve(a: &[Vec<f64>], b: &[f64]) -> Vec<f64> {
    let n = b.len();
    let mut m: Vec<Vec<f64>> = a.iter().enumerate().map(|(i, r)| { let mut v = r.clone(); v.push(b[i]); v }).collect();
    for c in 0..n {
        let p = (c..n).fold(c, |p, r| if m[r][c].abs() > m[p][c].abs() { r } else { p });
        m.swap(c, p);
        for r in c + 1..n {
            let f = m[r][c] / m[c][c];
            for k in c..=n { m[r][k] -= f * m[c][k]; }
        }
    }
    let mut x = vec![0.0; n];
    for r in (0..n).rev() {
        x[r] = (m[r][n] - (r + 1..n).map(|k| m[r][k] * x[k]).sum::<f64>()) / m[r][r];
    }
    x
}
fn at(r: f64, th: f64) -> P { (r * th.cos(), r * th.sin()) }

fn main() {
    println!("kernel on the circle: double layer, adjoint, -1/(4 pi)");
    let ((x0, n0, _, _), (y0, m0, _, _)) = (circle(0.3), circle(2.1));
    show("kernel,theta=0.3,phi=2.1", &[dk(x0, y0, m0), dk(y0, x0, n0), -1.0 / (2.0 * TAU)]);
    assert!((dk(x0, y0, m0) + 1.0 / (2.0 * TAU)).abs() < 1e-12);

    println!("interior Dirichlet: rim temperature cos(theta) K");
    let (a, nd) = nystrom(circle, 16, -0.5, false);
    let mu = solve(&a, &nd.iter().map(|n| n.0.cos()).collect::<Vec<_>>());
    show("Nystrom N=16: mu at theta=0, 90, 180 deg", &[mu[0], mu[4], mu[8]]);
    assert!(mu.iter().zip(&nd).all(|(m, n)| (m + 2.0 * n.0.cos()).abs() < 1e-12));
    let mu_f = |t: f64| -2.0 * t.cos();
    for (r, deg) in [(0.5, 0), (0.9, 60), (0.3, 135)] {
        let th = (deg as f64).to_radians();
        let u = dlayer(circle, 4000, &mu_f, at(r, th));
        show(&format!("u at r={:.1}, {} deg: layer, r cos(theta)", r, deg), &[u, r * th.cos()]);
        assert!((u - r * th.cos()).abs() < 1e-9);
    }

    println!("jump of the double layer along theta=0 (N=40000)");
    for r in [0.9, 0.99, 0.999, 1.001, 1.01, 1.1] {
        show(&format!("D mu at r={:.3}", r), &[dlayer(circle, 40000, &mu_f, at(r, 0.0))]);
    }
    let onrim: f64 = (0..4000).map(|j| -1.0 / (2.0 * TAU) * mu_f(TAU * j as f64 / 4000.0) * TAU / 4000.0).sum();
    show("on the rim: K mu, then K mu - mu/2 and K mu + mu/2", &[onrim, onrim + 1.0, onrim - 1.0]);
    assert!((dlayer(circle, 40000, &mu_f, at(1.001, 0.0)) - dlayer(circle, 40000, &mu_f, at(0.999, 0.0)) + 2.0).abs() < 3e-3);

    println!("chart: D mu along theta=0, distance in cm");
    let rs: Vec<f64> = (0..15).map(|i| 0.1 + 0.2 * i as f64).collect(); // equal steps of 0.5 cm, none on the rim
    let cm: Vec<String> = rs.iter().map(|r| format!(" {:.2}", 2.5 * r)).collect();
    println!("chart,cm,{}", cm.join(","));
    let kv: Vec<String> = rs.iter().map(|&r| format!(" {:.2}", fx(dlayer(circle, 4000, &mu_f, at(r, 0.0))))).collect();
    println!("chart,K,{}", kv.join(","));

    println!("single layer, sigma = 2 cos(theta): inside r cos, outside cos/r");
    let sg_f = |t: f64| 2.0 * t.cos();
    let s2 = slayer(circle, 4000, &sg_f, at(2.0, 0.0));
    show("S sigma at r=0.5 and r=2, theta=0", &[slayer(circle, 4000, &sg_f, at(0.5, 0.0)), s2]);
    assert!((s2 - 0.5).abs() < 1e-9);
    let h = 1e-4;
    let din = (slayer(circle, 40000, &sg_f, at(0.999 + h, 0.0)) - slayer(circle, 40000, &sg_f, at(0.999 - h, 0.0))) / (2.0 * h);
    let dout = (slayer(circle, 40000, &sg_f, at(1.001 + h, 0.0)) - slayer(circle, 40000, &sg_f, at(1.001 - h, 0.0))) / (2.0 * h);
    show("slope at r=0.999 and r=1.001, jump", &[din, dout, din - dout]);
    assert!((din - dout - 2.0).abs() < 3e-3);

    println!("flow past the bar: exterior Neumann, d u/dn = -cos(theta)");
    let (a, nd) = nystrom(circle, 16, -0.5, true);
    let sg = solve(&a, &nd.iter().map(|n| -n.0.cos()).collect::<Vec<_>>());
    show("Nystrom N=16: sigma at theta=0, 90 deg", &[sg[0], sg[4]]);
    assert!(sg.iter().zip(&nd).all(|(s, n)| (s - 2.0 * n.0.cos()).abs() < 1e-12));
    let speed = |r: f64, th: f64| -> f64 {
        let phi = |rr: f64, tt: f64| U * A_M * (rr * tt.cos() + slayer(circle, 4000, &sg_f, at(rr, tt)));
        let vr = (phi(r + h, th) - phi(r - h, th)) / (2.0 * h * A_M);
        let vt = (phi(r, th + h) - phi(r, th - h)) / (2.0 * h * r * A_M);
        vr.hypot(vt)
    };
    show("speed m/s at 5 cm from centre, top and front", &[speed(2.0, PI / 2.0), speed(2.0, PI)]);
    assert!((speed(2.0, PI / 2.0) - U * (1.0 + 0.25)).abs() < 1e-6);
    show("surface speed m/s at the top, 2U; Reynolds number 2aU/nu", &[2.0 * U, 2.0 * A_M * U / 1e-6]);

    println!("interior Neumann: (I/2 + K') sigma = h, Fredholm alternative");
    let (a, nd) = nystrom(circle, 16, 0.5, true);
    let rowmax = a.iter().map(|r| r.iter().sum::<f64>().abs()).fold(0.0, f64::max);
    show("row sum of the matrix (kills constants)", &[rowmax]);
    let tc: f64 = nd.iter().map(|n| n.0.cos() * TAU / 16.0).sum();
    show("test integral of h=1 and h=cos", &[TAU, tc]);
    for c in [0.0, 0.7] {
        assert!((0..16).all(|i| ((0..16).map(|j| a[i][j] * (2.0 * nd[j].0.cos() + c)).sum::<f64>() - nd[i].0.cos()).abs() < 1e-12));
    }
    show("sigma = 2cos + 0.7 also solves h=cos; u at r=0.5", &[slayer(circle, 4000, &|t: f64| sg_f(t) + 0.7, at(0.5, 0.0))]);

    println!("what breaks");
    show("jump sign flipped: mu = +2cos, u at r=0.5", &[dlayer(circle, 4000, &|t: f64| 2.0 * t.cos(), at(0.5, 0.0))]);
    show("jump dropped: rim value K mu with mu=-2cos", &[onrim]);
    let (one, minus) = (|_t: f64| 1.0, |_t: f64| -1.0);
    show("double layer of 1: inside, outside r=2", &[dlayer(circle, 4000, &one, at(0.5, 0.0)), dlayer(circle, 4000, &one, at(2.0, 0.0))]);
    let (a, _) = nystrom(circle, 16, -0.5, true);
    let leak = solve(&a, &[1.0; 16]);
    let u10 = slayer(circle, 4000, &minus, at(10.0, 0.0));
    show("leaky bar h=1: sigma, u at r=2 and r=10, ln r", &[leak[0], slayer(circle, 4000, &minus, at(2.0, 0.0)), u10, 10f64.ln()]);
    assert!((u10 - 10f64.ln()).abs() < 1e-9);
    show("first kind, S of 1 inside radius 1 and radius 2", &[slayer(circle, 4000, &one, at(0.5, 0.0)), slayer(big, 4000, &one, at(0.5, 0.0)), -2.0 * 2f64.ln()]);
    assert!((slayer(big, 4000, &one, at(0.5, 0.0)) + 2.0 * 2f64.ln()).abs() < 1e-9); // needs the weight J = 2

    println!("flattened pipe (oval 2.5 x 1.5 cm): rim data x^2 - y^2, u at (0.5, 0.2)");
    let mut u = 0.0;
    for n in [8, 16, 32, 64] {
        let (a, nd) = nystrom(oval, n, -0.5, false);
        let m = solve(&a, &nd.iter().map(|q| q.1 .0 * q.1 .0 - q.1 .1 * q.1 .1).collect::<Vec<_>>());
        u = nd.iter().enumerate().map(|(j, q)| dk((0.5, 0.2), q.1, q.2) * m[j] * q.3 * TAU / n as f64).sum();
        if n < 64 { println!("oval, N={}, u={:.6}, error={}", n, u, sci((u - 0.21).abs())); }
    }
    assert!((u - 0.21).abs() < 1e-10);
    let (a, nd) = nystrom(oval, 64, -0.5, true); // exterior Neumann with K': u = x / (x^2 + y^2) outside
    let sg = solve(&a, &nd.iter().map(|q| { let (x, y, n) = (q.1 .0, q.1 .1, q.2); ((y * y - x * x) * n.0 - 2.0 * x * y * n.1) / (x * x + y * y).powi(2) }).collect::<Vec<_>>());
    let ue: f64 = nd.iter().enumerate().map(|(j, q)| sk((1.5, 0.5), q.1) * sg[j] * q.3 * TAU / 64.0).sum();
    show("oval, exterior Neumann N=64: S sigma at (1.5, 0.5), x/(x^2+y^2)", &[ue, 1.5 / (1.5f64.powi(2) + 0.5f64.powi(2))]);
    assert!((ue - 0.6).abs() < 1e-9);
    println!("ALL CHECKS PASS");
}
