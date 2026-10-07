// Linear and time-invariant systems and convolution -- the check behind the card.
// Rust std only.  The car is a black box:
// 1500 dv/dt = 25 (17.25 + u) - 0.6 CdA v^2 - 150, stepped with RK4.
// Road one convolves the measured pulse response with the throttle history;
// road two runs the box itself; road three is the linearised car's closed form.

const M: f64 = 1500.0; // kg
const KF: f64 = 25.0; // N per % throttle
const HALF_RHO: f64 = 0.5 * 1.2; // kg/m^3
const FR: f64 = 150.0; // rolling resistance, N
const V0: f64 = 25.0; // cruise speed, m/s

fn clean(_t: f64) -> f64 { 0.75 } // drag area in clean air, m^2
fn draft(t: f64) -> f64 { if t < 50.0 { 0.75 } else { 0.60 } } // behind a lorry from t = 50 s

struct Car { th0: f64 }

impl Car {
    // throttle deviation u[n] in %, held through second n -> speed deviation y[n] in m/s at t = n s
    fn run(&self, u: &[f64], area: fn(f64) -> f64, mass: f64) -> Vec<f64> {
        let sub = 10;
        let dt = 1.0 / sub as f64;
        let mut v = V0;
        let mut y = vec![0.0];
        for (n, &un) in u.iter().enumerate() {
            let force = KF * (self.th0 + un) - FR;
            let f = |t: f64, v: f64| (force - HALF_RHO * area(t) * v * v) / mass;
            for j in 0..sub {
                let t = n as f64 + j as f64 * dt;
                let k1 = f(t, v);
                let k2 = f(t + dt / 2.0, v + dt / 2.0 * k1);
                let k3 = f(t + dt / 2.0, v + dt / 2.0 * k2);
                let k4 = f(t + dt, v + dt * k3);
                v += dt / 6.0 * (k1 + 2.0 * k2 + 2.0 * k3 + k4);
            }
            y.push(v - V0);
        }
        y
    }
    fn go(&self, u: &[f64]) -> Vec<f64> { self.run(u, clean, M) }
}

fn conv(h: &[f64], u: &[f64]) -> Vec<f64> { // y[n] = sum over k of h[k] u[n - k]
    (0..=u.len()).map(|n| (0..=n).filter(|&k| n - k < u.len()).map(|k| h[k] * u[n - k]).sum()).collect()
}

fn linear(u: &[f64], a: f64, gain: f64) -> Vec<f64> { // the linearised car, solved exactly
    let mut y = vec![0.0];
    for &un in u { let last = *y.last().unwrap(); y.push(a * last + gain * (1.0 - a) * un); }
    y
}

fn block(level: f64, start: usize, length: usize, n: usize) -> Vec<f64> {
    (0..n).map(|i| if start <= i && i < start + length { level } else { 0.0 }).collect()
}
fn plus(p: &[f64], q: &[f64]) -> Vec<f64> { p.iter().zip(q).map(|(a, b)| a + b).collect() }
fn minus(p: &[f64], q: &[f64]) -> Vec<f64> { p.iter().zip(q).map(|(a, b)| a - b).collect() }
fn maxgap(p: &[f64], q: &[f64]) -> f64 { p.iter().zip(q).map(|(a, b)| (a - b).abs()).fold(0.0, f64::max) }
fn row(label: &str, xs: &[f64], scale: f64, step: usize) -> String {
    let cells: Vec<String> = xs.iter().step_by(step).map(|x| format!("{:5.2}", scale * x)).collect();
    format!("{}{}", label, cells.join(" "))
}
fn ticks(label: &str, end: usize, step: usize) -> String {
    let cells: Vec<String> = (0..=end).step_by(step).map(|k| format!("{:5}", k)).collect();
    format!("{}{}", label, cells.join(" "))
}

fn main() {
    let drag = HALF_RHO * 0.75; // drag area 0.75 m^2: 0.45 N per (m/s)^2
    let th0 = (drag * V0 * V0 + FR) / KF; // cruise throttle, %
    let b = 2.0 * drag * V0; // slope of the drag curve at 25 m/s, N s/m
    let (tau, k_gain) = (M / b, KF / b);
    let a = (-1.0 / tau).exp(); // share of a speed bump left after one second
    let car = Car { th0 };
    let n_len = 300;

    let mut pulse = vec![0.0; n_len];
    pulse[0] = 1.0;
    let h = car.go(&pulse); // measured: +1 % for one second
    let mut hcf = vec![0.0];
    for k in 1..=n_len { hcf.push(k_gain * (1.0 - a) * a.powf((k - 1) as f64)); }
    println!("car: mass {:.0} kg, drive {:.0} N per %, air {:.1} kg/m^3, drag area 0.75 m^2 (0.60 m^2 behind the lorry), rolling {:.0} N; drag {:.2} N/(m/s)^2, {:.2} N at {:.0} m/s", M, KF, 2.0 * HALF_RHO, FR, drag, drag * V0 * V0, V0);
    println!("model: cruise throttle {:.2} %, drag slope {:.1} N s/m, tau {:.3} s, K {:.4} (m/s)/%, a {:.6}", th0, b, tau, k_gain, a);

    // ---- the four tests, run on the box ----
    let zero = car.go(&vec![0.0; 120]);
    let (s1, s2) = (car.go(&block(5.0, 0, 10, 20)), car.go(&block(10.0, 0, 10, 20)));
    let (b1, b2) = (car.go(&block(5.0, 10, 10, 30)), car.go(&block(5.0, 0, 10, 30)));
    let both = car.go(&plus(&block(5.0, 0, 10, 30), &block(5.0, 10, 10, 30)));
    let (late, early) = (car.go(&block(10.0, 40, 10, 80)), car.go(&block(10.0, 0, 10, 80)));
    let shift_gap = (0..=40).map(|n| (late[n + 40] - early[n]).abs()).fold(0.0, f64::max);
    let base = car.run(&vec![0.0; 140], draft, M);
    let g0 = minus(&car.run(&block(1.0, 0, 1, 140), draft, M), &base);
    let g1 = minus(&car.run(&block(1.0, 100, 1, 140), draft, M), &base);
    println!("test 1, zero in: largest speed deviation {:.9} m/s", zero.iter().map(|x| x.abs()).fold(0.0, f64::max));
    println!("test 2, scaling at 10 s: 5 % gives {:.4} m/s, 10 % gives {:.4} m/s, ratio {:.4}", s1[10], s2[10], s2[10] / s1[10]);
    println!("test 3, adding at 20 s: together {:.4} m/s, separately {:.4} m/s", both[20], b1[20] + b2[20]);
    println!("test 4, shifting by 40 s, clean air: largest gap {:.9} m/s", shift_gap);
    println!("test 4, shifting by 100 s, lorry from 50 s: 30 s after the pulse {:.2} mm/s early, {:.2} mm/s late", 1000.0 * g0[30], 1000.0 * g1[130]);

    // ---- the pulse response, measured and from the formula ----
    println!("h[1], h[2], h[3] measured: {:.6} {:.6} {:.6} m/s; formula K(1-a)a^(k-1): {:.6} {:.6} {:.6}", h[1], h[2], h[3], hcf[1], hcf[2], hcf[3]);
    let ks1: Vec<usize> = std::iter::once(1).chain((20..=n_len).step_by(20)).collect(); // chart 1 starts at 1 s; h[0] = 0
    println!("chart1, k in s:   {}", ks1.iter().map(|k| format!("{:5}", k)).collect::<Vec<_>>().join(" "));
    println!("chart1, h mm/s:   {}", ks1.iter().map(|&k| format!("{:5.2}", 1000.0 * h[k])).collect::<Vec<_>>().join(" "));
    let herr = (1..=n_len).map(|k| (h[k] - hcf[k]).abs() / hcf[k]).fold(0.0, f64::max);
    println!("pulse response, measured vs formula: largest relative gap {:.3} %", 100.0 * herr);
    println!("running sum of h to 300 s (the step response) {:.4} m/s per %; K = {:.4}", h.iter().sum::<f64>(), k_gain);

    // ---- worked by hand: throttle +10, +10, -5 % for three seconds ----
    let hand = [10.0, 10.0, -5.0];
    println!("hand: products h[1]u[2], h[2]u[1], h[3]u[0] = {:.6} {:.6} {:.6} m/s", h[1] * hand[2], h[2] * hand[1], h[3] * hand[0]);
    println!("hand: y[3] = h[3]*10 + h[2]*10 + h[1]*(-5) = {:.6} m/s; box {:.6}; linear model {:.6}", conv(&h, &hand)[3], car.go(&hand)[3], linear(&hand, a, k_gain)[3]);

    // ---- the overtaking manoeuvre: +10 % for 15 s, -5 % for 15 s, then cruise ----
    let mut u = vec![10.0; 15];
    u.extend(vec![-5.0; 15]);
    u.extend(vec![0.0; 90]);
    let (yc, yb, yl, yh) = (conv(&h, &u), car.go(&u), linear(&u, a, k_gain), conv(&hcf, &u));
    println!("{}", ticks("chart2, t s:     ", 120, 5));
    for (name, ys) in [("convolution", &yc), ("box", &yb), ("linear", &yl)] {
        println!("{}", row(&format!("chart2, {:<12}", format!("{}:", name)), ys, 1.0, 5));
    }
    let gap = maxgap(&yc, &yb);
    let exact = maxgap(&yh, &yl);
    println!("overtaking: largest gap convolution vs box {:.4} m/s; formula-h convolution vs linear model {:.9}", gap, exact);

    // ---- what breaks ----
    let big = vec![40.0; 120];
    let (bl, bb) = (linear(&big, a, k_gain), car.go(&big));
    println!("{}", ticks("chart3, t s:     ", 120, 10));
    println!("{}", row("chart3, linear:  ", &bl, 1.0, 10));
    println!("{}", row("chart3, box:     ", &bb, 1.0, 10));
    let gw = conv(&h, &vec![10.0; 30])[30];
    let bw = car.run(&block(10.0, 100, 30, 130), draft, M)[130] - base[130];
    println!("breaks 1, +40 % for 120 s: linear {:.2} m/s, box {:.2} m/s, gap {:.2} m/s", bl[120], bb[120], bl[120] - bb[120]);
    println!("breaks 2, clean-air h used behind the lorry, +10 % for 30 s: predicted {:.4} m/s, box {:.4} m/s, box in clean air {:.4} m/s", gw, bw, car.go(&vec![10.0; 30])[30]);
    let step = car.go(&vec![1.0; 120]);
    println!("breaks 3, step response used as h: overtaking at 15 s {:.4} m/s, not {:.4}", conv(&step, &u)[15], yc[15]);
    let noflip: f64 = (0..=30).map(|k| h[k] * u[k]).sum();
    println!("breaks 4, no flip at 30 s: {:.4} m/s, not {:.4}", noflip, yc[30]);

    // ---- try changing ----
    for scale in [0.5, 2.0] {
        let us: Vec<f64> = u.iter().map(|x| scale * x).collect();
        println!("try, overtaking x {:.1}: largest gap convolution vs box {:.4} m/s", scale, maxgap(&conv(&h, &us), &car.go(&us)));
    }
    println!("try, car of 2000 kg: speed at 15 s {:.4} m/s", car.run(&u, clean, 2000.0)[15]);

    assert!((s2[10] / s1[10] - 2.0).abs() < 0.01); // scaling nearly holds near cruise
    assert!((both[20] - (b1[20] + b2[20])).abs() < 0.01); // adding nearly holds near cruise
    assert!(shift_gap < 1e-9); // the clean-air car only shifts
    assert!((g1[130] - g0[30]).abs() > 2e-4); // the drafting car changes its answer
    assert!(herr < 0.01); // measured pulse response = linear formula
    assert!(gap < 0.05); // convolution = the box itself, near cruise
    assert!(exact < 1e-9); // convolution = exact linear solution
    assert!(bl[120] - bb[120] > 5.0); // far from cruise, linearity fails
    println!("ALL CHECKS PASS");
}
