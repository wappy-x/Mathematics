// Conservation law rho_t + q(rho)_x = 0 -- the same check in Rust, std only.  Cars bunch
// behind a red light on a one-lane road.  Greenshields flux q = VM rho (1 - rho/RM).  Roads:
// the breaking-time formula against a search over characteristics; Rankine-Hugoniot against
// counting cars; both against a cell-transmission grid that knows no formula.
const VM: f64 = 90.0; // top speed, km/h
const RM: f64 = 150.0; // jam density, cars/km
fn q(r: f64) -> f64 { VM * r * (1.0 - r / RM) } // flow, cars/h
fn c(r: f64) -> f64 { VM * (1.0 - 2.0 * r / RM) } // characteristic (wave) speed q'(rho), km/h
fn v(r: f64) -> f64 { VM * (1.0 - r / RM) } // car speed, km/h
fn rho0(x: f64) -> f64 { // t = 0: 30 cars/km, braking zone, queue to the light
    if x <= -0.7 { 30.0 } else if x <= -0.3 { 30.0 + 300.0 * (x + 0.7) } else { 150.0 }
}
fn smooth0(x: f64) -> f64 { 90.0 + 60.0 * (1.0 - 2.0 / (1.0 + (2.0 * (x + 0.5) / 0.2).exp())) } // 90 + 60 tanh
const TB: f64 = 1.0 / (2.0 * VM / RM * 300.0); // breaking time: -1/(q'' * steepest slope), h
fn xs() -> f64 { -0.5 + c(90.0) * TB } // where: the ramp's centre line, km
fn s() -> f64 { (q(150.0) - q(30.0)) / (150.0 - 30.0) } // Rankine-Hugoniot shock speed, km/h

fn exact(x: f64, t: f64) -> f64 { // the entropy solution, x <= 0 km, t in h
    if t < TB {
        let (a, b) = (-0.7 + c(30.0) * t, -0.3 + c(150.0) * t);
        return if x <= a { 30.0 } else if x >= b { 150.0 } else { 30.0 + 120.0 * (x - a) / (b - a) };
    }
    if x < xs() + s() * (t - TB) { 30.0 } else { 150.0 }
}

fn by_characteristics(x: f64, t: f64) -> f64 { // road 2 before breaking: solve x0 + c(rho0(x0)) t = x
    let (mut lo, mut hi) = (-3.0, 0.0);
    for _ in 0..60 {
        let m = (lo + hi) / 2.0;
        if m + c(rho0(m)) * t < x { lo = m } else { hi = m }
    }
    rho0((lo + hi) / 2.0)
}

fn search(prof: fn(f64) -> f64) -> f64 { // earliest crossing of neighbouring characteristics
    let n = 20000;
    let xs: Vec<f64> = (0..=n).map(|i| -1.5 + 1.5 * i as f64 / n as f64).collect();
    let cs: Vec<f64> = xs.iter().map(|&x| c(prof(x))).collect();
    (0..n).filter(|&i| cs[i + 1] < cs[i]).map(|i| (xs[i] - xs[i + 1]) / (cs[i + 1] - cs[i]))
        .fold(f64::INFINITY, f64::min)
}

fn grid(h: f64, t: f64) -> Vec<f64> { // road 3: cell transmission (Godunov) on [-2, 0] km
    let n = (2.0 / h).round() as usize;
    let mut r: Vec<f64> = (0..n).map(|i| rho0(-2.0 + (i as f64 + 0.5) * h)).collect();
    let qm = q(RM / 2.0);
    let dem = |a: f64| if a < RM / 2.0 { q(a) } else { qm };
    let sup = |a: f64| if a < RM / 2.0 { qm } else { q(a) };
    let steps = (t / (0.9 * h / VM)) as usize + 1; // each step inside the CFL limit
    let k = t / steps as f64;
    for _ in 0..steps { // inflow at 30 cars/km on the left, red light on the right
        let mut fl = vec![dem(30.0).min(sup(r[0]))];
        for i in 0..n - 1 { fl.push(dem(r[i]).min(sup(r[i + 1]))) }
        fl.push(0.0);
        r = (0..n).map(|i| r[i] - k / h * (fl[i + 1] - fl[i])).collect();
    }
    r
}

fn tail(r: &[f64], h: f64) -> f64 { // where the grid's density crosses 90 cars/km
    let i = (0..r.len()).find(|&i| r[i] >= 90.0).unwrap();
    let xa = -2.0 + (i as f64 - 0.5) * h;
    xa + (90.0 - r[i - 1]) / (r[i] - r[i - 1]) * h
}

fn gcd(a: i64, b: i64) -> i64 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn frac(n: i64, d: i64) -> String { // exact rational, printed like Python's Fraction
    let g = gcd(n, d); let (n, d) = if d / g < 0 { (-n / g, -d / g) } else { (n / g, d / g) };
    if d == 1 { format!("{}", n) } else { format!("{}/{}", n, d) }
}

fn main() {
    let (xs_, s_) = (xs(), s());
    println!("start: 30 cars/km to -0.7 km, rising 300 cars/km per km over 400 m to 150 at -0.3 km, queue to the light at 0 km");
    println!("top speed {:.0} km/h, jam {:.0} cars/km = one car per {:.1} m; top flow q(75) = {:.0} cars/h", VM, RM, 1000.0 / RM, q(75.0));
    println!("flux q(rho) = {:.0} rho (1 - rho/{:.0}): q(30) = {:.0} cars/h at {:.0} km/h; q(150) = {:.0}", VM, RM, q(30.0), v(30.0), q(150.0));
    println!("wave speeds q'(30) = {:+.0} km/h, q'(90) = {:+.0} km/h, q'(150) = {:+.0} km/h", c(30.0), c(90.0), c(150.0));
    println!("breaking time by formula: 1/(1.2 x 300) = {:.6} h = {:.1} s, at x = {:.3} km", TB, TB * 3600.0, xs_);
    let (lin, smo) = (search(rho0), search(smooth0));
    println!("road 2, search over 20001 characteristics: braking ramp {:.4} s, smooth tanh zone {:.4} s", lin * 3600.0, smo * 3600.0);
    println!("slope inside the ramp at 5 s: 300/(1 - 5/10) = {:.0} cars/km per km", 300.0 / (1.0 - 5.0 / (TB * 3600.0)));
    let qf = |r: i64| (90 * r * (150 - r), 150); // exact flow, cars/h, as numerator and denominator
    let (fs_n, fs_d) = (qf(150).0 * qf(30).1 - qf(30).0 * qf(150).1, qf(150).1 * qf(30).1 * (150 - 30));
    println!("Rankine-Hugoniot: s = (0 - 2160)/(150 - 30) = {} km/h exactly = {:.1} m/s", frac(fs_n, fs_d), s_ / 3.6);
    println!("same by the Greenshields shortcut 90 (1 - 180/150) = {:.0} km/h", VM * (1.0 - 180.0 / RM));
    let t60 = 1.0 / 60.0;
    let x60 = xs_ + s_ * (t60 - TB);
    println!("queue tail at 60 s: -0.55 + (-18)(50/3600) = {:.4} km; queue {:.0} m holding {:.0} cars", x60, -x60 * 1000.0, -x60 * 150.0);
    let cars0 = 1.3 * 30.0 + 0.4 * 90.0 + 0.3 * 150.0;
    let inflow = q(30.0) * t60;
    let xc = (cars0 + inflow - 30.0 * 2.0) / (30.0 - 150.0);
    println!("road 2, count cars on [-2, 0] km: {:.0} at start + {:.0} in = {:.0}; tail where 30(X + 2) + 150(-X) = 156: X = {:.4} km", cars0, inflow, cars0 + inflow, xc);
    let mut errs = vec![];
    let mut r60 = vec![];
    for h in [0.01, 0.005, 0.0025] {
        let r5 = grid(h, 5.0 / 3600.0);
        r60 = grid(h, t60);
        errs.push((0..r5.len()).map(|i| (r5[i] - exact(-2.0 + (i as f64 + 0.5) * h, 5.0 / 3600.0)).abs()).sum::<f64>() * h);
        println!("road 3, cell grid h = {} m: tail at 60 s {:.4} km, cars {:.4}; at 5 s {:.4} cars out of place",
            h * 1000.0, tail(&r60, h), r60.iter().sum::<f64>() * h, errs[errs.len() - 1]);
    }
    println!("error ratios as h halves: {:.2}, {:.2} (order 1)", errs[0] / errs[1], errs[1] / errs[2]);
    let mid: Vec<f64> = (0..10).map(|i| -0.95 + 0.1 * i as f64).collect();
    let gap = mid.iter().map(|&x| (by_characteristics(x, 5.0 / 3600.0) - exact(x, 5.0 / 3600.0)).abs()).fold(0.0, f64::max);
    println!("profile at 5 s by tracing characteristics back, largest gap from formula: {:.6} cars/km", gap);
    for t in [0, 5, 60] {
        let row: Vec<String> = mid.iter().map(|&x| format!("{:.0}", exact(x, t as f64 / 3600.0))).collect();
        println!("chart, t = {} s: {}", t, row.join(", "));
    }
    let tw = 1.0 / (VM / RM * 300.0);
    println!("mistake 1, characteristics at car speed v: breaks at {:.1} s, not {:.1} s", tw * 3600.0, TB * 3600.0);
    let xw = xs_ - s_ * (t60 - TB);
    let cw = 30.0 * (xw + 2.0) + 150.0 * (-xw);
    println!("mistake 2, sign flipped, +18 km/h: tail at {:.4} km, cars counted {:.0}, not 156", xw, cw);
    let jmp = |f: fn(i64) -> (i64, i64)| { let (r, l) = (f(0), f(1)); (r.0 * l.1 - l.0 * r.1, r.1 * l.1) }; // Burgers 1-to-0 jump [f], exact
    let ratio = |a: (i64, i64), b: (i64, i64)| frac(a.0 * b.1, a.1 * b.0); // [flux] / [conserved quantity]
    let (b1, b2) = (ratio(jmp(|u| (u * u, 2)), jmp(|u| (u, 1))), ratio(jmp(|u| (u * u * u, 3)), jmp(|u| (u * u, 2))));
    println!("mistake 3, Burgers 1-to-0 jump: conserving u gives {}, conserving u^2/2 gives {}", b1, b2);
    println!("try, arriving at 60 cars/km: s = {:.0} km/h; braking zone 800 m: breaks at {:.1} s", (q(150.0) - q(60.0)) / 90.0, 1.0 / (1.2 * 150.0) * 3600.0);
    println!("figure, shock from ({:.3} km, {:.1} s) to ({:.3} km, 30.0 s)", xs_, TB * 3600.0, xs_ + s_ * (30.0 / 3600.0 - TB));
    let up: Vec<String> = [-1.0, -0.9, -0.8, -0.7].iter().map(|x0: &f64| format!("{:.1}", (-0.5 - x0) / ((c(30.0) - s_) / 3600.0))).collect();
    let dn: Vec<String> = [-0.3, -0.2, -0.1, 0.0].iter().map(|x0: &f64| format!("{:.1}", (x0 + 0.5) / ((s_ - c(150.0)) / 3600.0))).collect();
    println!("figure, lines from -1.0 -0.9 -0.8 -0.7 km hit the shock at {} s; from -0.3 -0.2 -0.1 0.0 km at {} s", up.join(" "), dn.join(" "));
    assert!((lin - TB).abs() < 1e-9 && (smo - TB).abs() < 1e-4 * TB); // search meets breaking formula
    assert!(frac(fs_n, fs_d) == "-18" && (xc - x60).abs() < 1e-12); // RH meets the car count
    assert!((tail(&r60, 0.0025) - x60).abs() < 1e-4 && (r60.iter().sum::<f64>() * 0.0025 - 156.0).abs() < 1e-6); // grid meets RH, count
    assert!(errs[2] < 0.1 && errs[1] / errs[2] > 1.8 && errs[1] / errs[2] < 2.2); // grid meets the profile at order 1
    assert!(gap < 1e-9); // characteristics meet formula
    assert!(b1 == "1/2" && b2 == "2/3"); // Burgers: the jump depends on what is conserved
    println!("ALL CHECKS PASS");
}
