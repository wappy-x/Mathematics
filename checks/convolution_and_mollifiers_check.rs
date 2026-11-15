// Convolution and mollifiers: smooth a jagged GPS track with a shrinking bump.
const Y: [f64; 11] = [0.0, 2.0, -1.0, 3.0, 1.0, 4.0, 0.0, 2.0, -2.0, 1.0, 0.0]; // offsets (m), one fix per second

fn bump(u: f64) -> f64 {
    // exp(-1/(1-u^2)) inside (-1, 1), zero outside
    if u.abs() < 1.0 { (-1.0 / (1.0 - u * u)).exp() } else { 0.0 }
}

fn gauss(g: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 {
    // n panels of 3-point Gauss-Legendre; never touches a or b
    let r = 0.6f64.sqrt();
    let h = (b - a) / n as f64;
    let mut s = 0.0;
    for i in 0..n {
        let c = a + (i as f64 + 0.5) * h;
        s += 5.0 * g(c - 0.5 * h * r) + 8.0 * g(c) + 5.0 * g(c + 0.5 * h * r);
    }
    s * h / 18.0
}

fn joined(t: f64) -> f64 {
    // fixes joined by straight lines, zero outside 0..10 s
    if t <= 0.0 || t >= 10.0 { return 0.0; }
    let k = t as usize;
    Y[k] + (Y[k + 1] - Y[k]) * (t - k as f64)
}

fn held(t: f64) -> f64 {
    // each fix held for one second, zero outside 0..10 s
    if (0.0..10.0).contains(&t) { Y[t as usize] } else { 0.0 }
}

fn smooth(f: &dyn Fn(f64) -> f64, x: f64, eps: f64, kern: &dyn Fn(f64) -> f64, n: usize, lo: f64, hi: f64) -> f64 {
    // (kern_eps * f)(x), split where f breaks
    let mut cuts = vec![lo * eps];
    let mut inner: Vec<f64> = (-1..13).map(|k| x - k as f64).filter(|&s| lo * eps < s && s < hi * eps).collect();
    inner.sort_by(|a, b| a.partial_cmp(b).unwrap());
    cuts.extend(inner);
    cuts.push(hi * eps);
    let g = |s: f64| kern(s / eps) / eps * f(x - s);
    cuts.windows(2).filter(|w| w[1] > w[0]).map(|w| gauss(&g, w[0], w[1], n)).sum()
}

fn integrate(h: &dyn Fn(f64) -> f64, lo: f64, hi: f64, eps: f64) -> f64 {
    // integral of h over [lo, hi], split at k and k +- eps
    let mut pts = vec![lo, hi];
    for k in -1..12 {
        for p in [k as f64 - eps, k as f64, k as f64 + eps] {
            if lo < p && p < hi { pts.push(p); }
        }
    }
    pts.sort_by(|a, b| a.partial_cmp(b).unwrap());
    pts.dedup();
    pts.windows(2).map(|w| gauss(h, w[0], w[1], 100)).sum()
}

fn tidy(v: f64) -> f64 { if v.abs() >= 0.005 { v } else { 0.0 } } // print 0.00, never -0.00

fn main() {
    let z = gauss(&bump, -1.0, 1.0, 2000); // the bump's area
    let eta = move |u: f64| bump(u) / z; // unit-area bump
    let deta = move |u: f64| if u.abs() < 1.0 { eta(u) * (-2.0 * u / (1.0 - u * u).powi(2)) } else { 0.0 };
    let m1 = gauss(&|u: f64| u.abs() * eta(u), -1.0, 1.0, 2000); // mean distance |u| under the bump
    let sm = |f: &dyn Fn(f64) -> f64, x: f64, eps: f64| smooth(f, x, eps, &eta, 100, -1.0, 1.0);

    println!("bump area Z                     {:.12}", z);
    println!("m1, mean |u| under the bump     {:.12}", m1);
    println!("eta(0), the bump's peak         {:.12}", eta(0.0));

    // Rehearsal on the list of 11 fixes: weights eta(k/eps) on whole seconds, rescaled to add to 1.
    println!("list, raw hill at 0 and 1 s, eps 2: {:.6} {:.6}; sum {:.6}", bump(0.0), bump(0.5), bump(0.0) + 2.0 * bump(0.5));
    for eps in [2.0, 0.5] {
        let w0: Vec<f64> = [-1.0, 0.0, 1.0].iter().map(|k: &f64| eta(k / eps)).collect();
        let tot: f64 = w0.iter().sum();
        let w: Vec<f64> = w0.iter().map(|v| v / tot).collect();
        let mut pad = vec![0.0];
        pad.extend_from_slice(&Y);
        pad.push(0.0);
        let s: Vec<f64> = (0..11).map(|i| w[0] * pad[i] + w[1] * pad[i + 1] + w[2] * pad[i + 2]).collect();
        let total: f64 = s.iter().sum();
        println!("list, eps {:.1} s: weights {:.6} {:.6}; fix at 5 s {:.6}; total {:.6}", eps, w[0], w[1], s[5], total);
    }

    // Road 1 against road 2: worst gap on the joined track, scanned against eps*m1*7/2.
    println!("eps (s)   sup gap joined  formula   L1 gap held  formula   sup gap held");
    for eps in [0.5, 0.25, 0.125, 0.0625] {
        let grid: Vec<f64> = (0..1201).map(|j| (j as f64 - 100.0) / 100.0).collect();
        let sup_j = grid.iter().map(|&x| (sm(&joined, x, eps) - joined(x)).abs()).fold(0.0, f64::max);
        let l1_h = integrate(&|x: f64| (sm(&held, x, eps) - held(x)).abs(), -1.0, 11.0, eps);
        let sup_h = grid.iter().map(|&x| (sm(&held, x, eps) - held(x)).abs()).fold(0.0, f64::max);
        let (f_sup, f_l1) = (3.5 * eps * m1, 28.0 * eps * m1);
        println!("{:<9.4} {:.6}        {:.6}  {:.6}     {:.6}  {:.6}", eps, sup_j, f_sup, l1_h, f_l1, sup_h);
        assert!((sup_j - f_sup).abs() < 1e-6, "scanned worst gap = eps * m1 * 7/2");
        assert!((l1_h - f_l1).abs() < 1e-6, "integrated gap = eps * m1 * 28");
        assert!((sup_h - 2.0).abs() < 1e-9, "half the 4 m jump survives in the sup norm");
    }

    // Smoothness: slope of the smoothed track at the 5 s corner (3 m/s in, -4 m/s out).
    let eps = 0.25;
    let slope_q = smooth(&joined, 5.0, eps, &|u: f64| deta(u) / eps, 100, -1.0, 1.0);
    let slope_fd = (sm(&joined, 5.0 + 1e-4, eps) - sm(&joined, 5.0 - 1e-4, eps)) / 2e-4;
    println!("slope at 5 s, eps 0.25: eta' * f {:.6}; finite difference {:.6}", slope_q, slope_fd);
    assert!((slope_q + 0.5).abs() < 1e-6 && (slope_fd + 0.5).abs() < 1e-6);

    // No shift: area and centre of the track are kept; a trailing bump moves the centre by eps.
    for eps in [0.5, 1.0] {
        let a0 = integrate(&joined, -2.0, 12.0, eps);
        let c0 = integrate(&|t: f64| t * joined(t), -2.0, 12.0, eps) / a0;
        let a1 = integrate(&|t: f64| sm(&joined, t, eps), -2.0, 12.0, eps);
        let c1 = integrate(&|t: f64| t * sm(&joined, t, eps), -2.0, 12.0, eps) / a1;
        let trail = |u: f64| eta(u - 1.0);
        let c2 = integrate(&|t: f64| t * smooth(&joined, t, eps, &trail, 100, 0.0, 2.0), -2.0, 12.0, eps) / a1;
        println!("eps {:.1}: area {:.6} -> {:.6}; centre {:.6} s -> {:.6} s; trailing bump {:.6} s", eps, a0, a1, c0, c1, c2);
        assert!((a0 - Y.iter().sum::<f64>()).abs() < 1e-9, "area of the joined track = sum of the fixes");
        assert!((a1 - a0).abs() < 1e-7 && (c1 - c0).abs() < 1e-7);
        assert!((c2 - c0 - eps).abs() < 1e-6);
    }

    // Never larger: the L2 size of the smoothed track against the track's own (Young, p = 2).
    let n2 = (0..10).map(|k| (Y[k] * Y[k] + Y[k] * Y[k + 1] + Y[k + 1] * Y[k + 1]) / 3.0).sum::<f64>().sqrt();
    for eps in [0.5, 1.0] {
        let s2 = integrate(&|t: f64| sm(&joined, t, eps).powi(2), -2.0, 12.0, eps).sqrt();
        println!("L2 size: track {:.6}, smoothed eps {:.1}: {:.6}", n2, eps, s2);
        assert!(s2 <= n2);
    }

    // Wrong mass: the raw bump (area Z) shrinks the track and never recovers it.
    let raw = smooth(&joined, 5.0, 0.0625, &bump, 100, -1.0, 1.0);
    println!("raw bump at 5 s, eps 0.0625: {:.6} (track 4.000000); gap {:.6}", raw, 4.0 - raw);
    assert!((raw - z * (4.0 - 3.5 * 0.0625 * m1)).abs() < 1e-6);

    // The infinite-dimensional catch: a wiggle sin(xi t), xi = 20/eps, is all but erased at every eps.
    let hat20 = gauss(&|u: f64| eta(u) * (20.0 * u).cos(), -1.0, 1.0, 4000);
    for eps in [0.5, 0.0625] {
        let (xi, x) = (20.0 / eps, 0.3);
        let ratio = smooth(&|t: f64| (xi * t).sin(), x, eps, &eta, 4000, -1.0, 1.0) / (xi * x).sin();
        println!("wiggle, eps {:.4}: kept fraction {:.6}; eta-hat(20) {:.6}; gap {:.6}", eps, ratio, hat20, 1.0 - hat20);
        assert!((ratio - hat20).abs() < 1e-7);
    }

    // The switch and the tap: H * eta_eps rises over 2 eps; its slope at 0 is eta_eps(0).
    let ramp_half = gauss(&eta, -1.0, 0.5, 2000);
    println!("switch smoothed, at t = eps/2: {:.6}; at t = 0: {:.6}", ramp_half, gauss(&eta, -1.0, 0.0, 2000));

    // Chart points: the joined track and two smoothings, every half second.
    let ts: Vec<f64> = (0..21).map(|j| 0.5 * j as f64).collect();
    let line = |v: Vec<f64>| v.iter().map(|x| format!("{:.2}", tidy(*x))).collect::<Vec<_>>().join(" ");
    println!("chart, track    {}", line(ts.iter().map(|&t| joined(t)).collect()));
    for eps in [1.0, 0.25] {
        println!("chart, eps {:.2} {}", eps, line(ts.iter().map(|&t| sm(&joined, t, eps)).collect()));
    }
    println!("ALL CHECKS PASS");
}
