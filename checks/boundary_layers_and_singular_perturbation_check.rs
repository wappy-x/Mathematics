// Boundary layers and singular perturbation -- the same check as the Python,
// in Rust, std only.  Part 1 solves the model layer  eps*y'' + y' + y = 0,
// y(0) = 0,  y(1) = 1  three ways: exact roots, finite differences, and the
// matched inner-outer composite.  Part 2 takes the same steps on a drone wing:
// Blasius's inner equation solved by shooting two ways, then the
// skin-friction drag by two independent roads.
const E: f64 = std::f64::consts::E;
const N: usize = 4000;

fn exact(x: f64, eps: f64) -> f64 {          // road 1: roots of eps r^2 + r + 1 = 0
    let d = (1.0 - 4.0 * eps).sqrt();
    let (r1, r2) = ((-1.0 + d) / (2.0 * eps), (-1.0 - d) / (2.0 * eps));
    ((r1 * x).exp() - (r2 * x).exp()) / (r1.exp() - r2.exp())
}

fn finite_diff(eps: f64, n: usize) -> Vec<f64> { // road 2: central differences, Thomas sweep
    let h = 1.0 / n as f64;
    let (a, b, c) = (eps / (h * h) - 0.5 / h, 1.0 - 2.0 * eps / (h * h), eps / (h * h) + 0.5 / h);
    let mut cp = vec![0.0; n];               // y(0) = 0 and zero right side: y_i = -cp_i y_(i+1)
    for i in 1..n { cp[i] = c / (b - a * cp[i - 1]) }
    let mut y = vec![0.0; n + 1];
    y[n] = 1.0;
    for i in (1..n).rev() { y[i] = -cp[i] * y[i + 1] }
    y
}

fn outer(x: f64) -> f64 { (1.0 - x).exp() }                       // eps dropped, keeps y(1) = 1
fn inner(x: f64, eps: f64) -> f64 { E * (1.0 - (-x / eps).exp()) } // X = x/eps, keeps y(0) = 0
fn composite(x: f64, eps: f64) -> f64 { outer(x) + inner(x, eps) - E } // minus the shared value e

fn worst(eps: f64, f: &dyn Fn(f64, usize) -> f64) -> f64 { // largest gap from the exact answer
    (0..=N).map(|i| { let x = i as f64 / N as f64; (f(x, i) - exact(x, eps)).abs() }).fold(0.0, f64::max)
}

fn rhs(v: [f64; 3]) -> [f64; 3] { [v[1], v[2], -0.5 * v[0] * v[2]] }

// f''' = -f f''/2, f(0) = f'(0) = 0, f''(0) = s; RK4.  Path rows: (eta, f, f', integral of f'(1 - f'))
fn blasius(s: f64, eta_max: f64, h: f64) -> ([f64; 3], Vec<[f64; 4]>) {
    let mut v = [0.0, 0.0, s];
    let mut path: Vec<[f64; 4]> = Vec::new();
    path.push([0.0; 4]);
    for k in 0..(eta_max / h).round() as usize {
        let k1 = rhs(v);
        let k2 = rhs([0, 1, 2].map(|j| v[j] + 0.5 * h * k1[j]));
        let k3 = rhs([0, 1, 2].map(|j| v[j] + 0.5 * h * k2[j]));
        let k4 = rhs([0, 1, 2].map(|j| v[j] + h * k3[j]));
        let w = [0, 1, 2].map(|j| v[j] + h / 6.0 * (k1[j] + 2.0 * k2[j] + 2.0 * k3[j] + k4[j]));
        let mom = path[path.len() - 1][3] + 0.5 * h * (v[1] * (1.0 - v[1]) + w[1] * (1.0 - w[1]));
        v = w;
        path.push([(k + 1) as f64 * h, v[0], v[1], mom]);
    }
    (v, path)
}

fn row(lab: &str, vals: &[f64], w: usize) -> String {
    format!("{} {}", lab, vals.iter().map(|v| format!("{:w$.2}", v, w = w)).collect::<Vec<_>>().join(" "))
}

fn main() {
    let eps = 0.05;
    let y_fd = finite_diff(eps, N);
    println!("part 1: model layer, eps = 0.05");
    println!("{:>6} {:>9} {:>9} {:>9} {:>9} {:>9}", "x", "exact", "fin-diff", "outer", "inner", "composite");
    for x in [0.0, 0.01, 0.02, 0.05, 0.1, 0.2, 0.5, 1.0] {
        println!("{:6.2} {:9.4} {:9.4} {:9.4} {:9.4} {:9.4}", x, exact(x, eps),
                 y_fd[(x * N as f64).round() as usize], outer(x), inner(x, eps), composite(x, eps));
    }
    let fd_gap = worst(eps, &|_, i| y_fd[i]);
    println!("worst gap, finite differences vs exact   {:.8}", fd_gap);
    println!("eps     worst gap, composite vs exact   gap / eps   overlap gap at x = sqrt(eps)");
    let eps_list = [0.2, 0.1, 0.05, 0.02, 0.01, 0.001];
    let mut gaps = [0.0; 6];
    for (k, &ep) in eps_list.iter().enumerate() {
        gaps[k] = worst(ep, &|x, _| composite(x, ep));
        let s = ep.sqrt();
        println!("{:<7.3} {:28.4} {:11.3} {:16.4}", ep, gaps[k], gaps[k] / ep, (outer(s) - inner(s, ep)).abs());
    }
    println!("e x eps at eps = 0.01: {:.4}", E * 0.01);
    println!("mistake, outer only, value at the wall x = 0:   {:.4}  (truth 0)", outer(0.0));
    println!("mistake, inner + outer, no subtraction, x = 1:  {:.4}  (truth 1)", outer(1.0) + inner(1.0, eps));
    let xs: Vec<f64> = (0..11).map(|k| 0.05 * k as f64).collect();
    println!("{}", row("chart, x     ", &xs, 5));
    println!("{}", row("chart, outer  ", &xs.iter().map(|&x| outer(x)).collect::<Vec<_>>(), 5));
    println!("{}", row("chart, inner  ", &xs.iter().map(|&x| inner(x, eps)).collect::<Vec<_>>(), 5));
    println!("{}", row("chart, compos.", &xs.iter().map(|&x| composite(x, eps)).collect::<Vec<_>>(), 5));

    // ---- part 2: the drone wing, chord 0.20 m at 15 m/s in air at 20 C ----
    let (r, m, t, p, mu) = (8.314462618, 0.0289644, 293.15, 101325.0, 1.82e-5);
    let rho: f64 = p * m / (r * t);          // ideal gas
    let (nu, u, c) = (mu / rho, 15.0, 0.20);
    let re: f64 = u * c / nu;
    let (mut lo, mut hi) = (0.1, 1.0);       // road A: bisect on f''(0) until f'(10) = 1
    for _ in 0..60 {
        let mid = 0.5 * (lo + hi);
        if blasius(mid, 10.0, 0.01).0[1] < 1.0 { lo = mid } else { hi = mid }
    }
    let s_shoot: f64 = 0.5 * (lo + hi);
    let lam: f64 = blasius(1.0, 8.0, 0.005).0[1]; // road B: one run with f''(0) = 1, then rescale
    let s_scale = lam.powf(-1.5);
    let (_, path) = blasius(s_shoot, 10.0, 0.01);
    let i99 = path.iter().position(|q| q[2] >= 0.99).unwrap();
    let (a0, a1) = (path[i99 - 1], path[i99]);
    let eta99 = a0[0] + (0.99 - a0[2]) * (a1[0] - a0[0]) / (a1[2] - a0[2]);
    let last = path[path.len() - 1];
    let (disp, theta) = (last[0] - last[1], last[3]);
    let u_over_u = |eta: f64| {             // f'(eta) read off the stored run
        let i = ((eta / 0.01) as usize).min(path.len() - 2);
        let tt = (eta - path[i][0]) / 0.01;
        path[i][2] + tt * (path[i + 1][2] - path[i][2])
    };
    let delta = c / re.sqrt();               // the layer's thickness scale at the trailing edge
    let d_wall = 2.0 * mu * u * s_shoot * (u * c / nu).sqrt(); // road 1: wall shear along the chord
    let d_mom = rho * u * u * theta * delta;                  // road 2: momentum the layer has lost
    println!("part 2: drone wing, chord 0.20 m, 15 m/s, air at 20 C");
    println!("rho {:.4} kg/m^3   nu {:.4} mm^2/s   Re {:.0}   1/Re {:.3} per million", rho, nu * 1e6, re, 1e6 / re);
    println!("mu {:.2}e-5 Pa s; Sutherland's law, as on card 04, gives {:+.1} %",
             mu * 1e5, 100.0 * (1.458e-6 * t.powf(1.5) / (t + 110.4) - mu) / mu);
    println!("laminar on a smooth plate in a quiet stream up to Re about 500000; this wing {:.0}, {}", re,
             if re < 5e5 { "inside" } else { "OUTSIDE" });
    println!("f''(0) by bisection shooting {:.6}   by rescaling one run {:.6}", s_shoot, s_scale);
    println!("eta at 99% of U {:.4}   eta - f far out {:.4}   momentum integral {:.6}", eta99, disp, theta);
    println!("thickness scale c/sqrt(Re) {:.4} mm   99% thickness {:.3} mm", delta * 1e3, eta99 * delta * 1e3);
    println!("displacement thickness {:.3} mm   wrong scale c/Re {:.3} um", disp * delta * 1e3, c / re * 1e6);
    println!("average skin-friction coefficient 4 f''(0)/sqrt(Re) {:.6}   4 f''(0) {:.3}", 4.0 * s_shoot / re.sqrt(), 4.0 * s_shoot);
    println!("drag per metre of span, one side, by wall shear {:.5} N/m   by momentum lost {:.5} N/m", d_wall, d_mom);
    println!("drag per metre of span, both sides {:.4} N/m   inviscid outer flow alone 0.0000 N/m", 2.0 * d_wall);
    let re2: f64 = 60.0 * 1.5 / nu;          // outside the range: light-aircraft wing, laminar formula misused
    println!("outside range: chord 1.5 m at 60 m/s, Re {:.0}; laminar 4 f''(0)/sqrt(Re) {:.6} vs turbulent fit 0.074 Re^-0.2 {:.6}",
             re2, 4.0 * s_shoot / re2.sqrt(), 0.074 * re2.powf(-0.2));
    let heights: Vec<f64> = (0..13).map(|k| 0.25 * k as f64).collect();
    println!("{}", row("chart, height above skin (mm) ", &heights, 4));
    println!("{}", row("chart, u/U Blasius inner      ", &heights.iter().map(|&y| u_over_u(y / (delta * 1e3))).collect::<Vec<_>>(), 4));
    println!("{}", row("chart, u/U outer (inviscid)   ", &heights.iter().map(|_| 1.0).collect::<Vec<_>>(), 4));

    assert!(fd_gap < 1e-4, "finite differences must land on the exact roots");
    assert!(gaps[4] < gaps[1] / 4.0, "composite error shrinks with eps");
    assert!((gaps[5] / 0.001 - E).abs() < 0.1, "first outer correction eps (1 - x) e^(1 - x) predicts e eps");
    assert!((s_shoot - s_scale).abs() < 1e-6 && (s_shoot - 0.332057).abs() < 1e-5, "two shooting roads, and Howarth's value");
    assert!((d_wall - d_mom).abs() < 1e-4 * d_wall, "wall shear and momentum deficit must give one drag");
    assert!((eta99 - 4.91).abs() < 0.01, "99% thickness at eta near 4.91");
    println!("ALL CHECKS PASS");
}
