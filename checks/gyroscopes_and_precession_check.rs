// Gyroscopes and precession -- the check behind the card.  std only, no crates.
// A bicycle wheel hangs from a string tied to its axle and spins once a second.
// Roads to the precession rate: the formula tau/L; a full rigid-body simulation (RK4);
// the axle turned by many small sideways kicks.  Then a release from rest, where the
// formula holds only on average and only once the spin is fast.
use std::f64::consts::PI;

const G: f64 = 9.80665;          // standard gravity, m/s^2 (NIST CODATA g_n, exact)
const M: f64 = 2.0;              // wheel mass, kg
const R: f64 = 0.30;             // rim radius, m
const D: f64 = 0.10;             // string-to-hub distance, m
const I3: f64 = M * R * R;       // spin inertia, all mass at the rim (a hoop), kg m^2
const I1: f64 = M * R * R / 2.0 + M * D * D; // inertia about a diameter, moved out to the string
type S = [f64; 6];               // axle direction a (3), then angular momentum H about the string (3)

fn dot(a: &[f64], b: &[f64]) -> f64 { a.iter().zip(b).fold(0.0, |t, (x, y)| t + x * y) }
fn cross(a: &[f64], b: &[f64]) -> [f64; 3] {
    [a[1]*b[2] - a[2]*b[1], a[2]*b[0] - a[0]*b[2], a[0]*b[1] - a[1]*b[0]]
}
fn rates(s: &S) -> S {
    let (a, h) = (&s[..3], &s[3..]);
    let along = dot(h, a);       // spin part of H; the rest turns the axle, with inertia I1
    let w: Vec<f64> = (0..3).map(|i| along / I3 * a[i] + (h[i] - along * a[i]) / I1).collect();
    let da = cross(&w, a);
    let tq = cross(&[D * a[0], D * a[1], D * a[2]], &[0.0, 0.0, -M * G]);
    [da[0], da[1], da[2], tq[0], tq[1], tq[2]]
}
fn step(s: &S, k: &S, c: f64) -> S { let mut o = *s; for i in 0..6 { o[i] = s[i] + c * k[i]; } o }
// RK4 from a level axle pointing east; a sample every 0.04 s, and the lowest the axle went
fn run(h0: [f64; 3], t_end: f64) -> (Vec<S>, f64) {
    let dt = 1e-4;
    let mut s: S = [1.0, 0.0, 0.0, h0[0], h0[1], h0[2]];
    let (mut path, mut low) = (Vec::new(), 0.0f64);
    for n in 0..((t_end / dt).round() as usize + 1) {
        if n % 400 == 0 { path.push(s); }
        low = low.min(s[2]);
        let k1 = rates(&s); let k2 = rates(&step(&s, &k1, dt / 2.0));
        let k3 = rates(&step(&s, &k2, dt / 2.0)); let k4 = rates(&step(&s, &k3, dt));
        for i in 0..6 { s[i] = s[i] + dt / 6.0 * (k1[i] + 2.0 * k2[i] + 2.0 * k3[i] + k4[i]); }
    }
    (path, -low.asin().to_degrees())
}
fn energy(s: &S) -> f64 {
    let along = dot(&s[3..], &s[..3]);
    along * along / (2.0 * I3) + (dot(&s[3..], &s[3..]) - along * along) / (2.0 * I1) + M * G * D * s[2]
}
fn tilt(s: &S) -> f64 { s[2].asin().to_degrees() }   // axle angle above level, degrees
fn turned(path: &[S]) -> f64 {                       // angle swept round the string, unwrapped, rad
    let (mut tot, mut prev) = (0.0, 0.0);
    for s in path {
        let ang = s[1].atan2(s[0]); let d = ang - prev;
        tot += d - 2.0 * PI * (d / (2.0 * PI)).round(); prev = ang;
    }
    tot
}

fn main() {
    let w = 2.0 * PI * 1.0;                          // once a second, in rad/s
    let (l, tau) = (I3 * w, M * G * D);
    let om = tau / l;                                // road 1
    let (steady, _) = run([l, 0.0, I1 * om], 2.0);   // launched already turning at om
    let om_sim = turned(&steady) / 2.0;              // road 2
    let (mut lv, n) = ([l, 0.0, 0.0], 10000);        // road 3: kicks of tau*dt, side-on to L
    for _ in 0..n {
        let m = dot(&lv, &lv).sqrt();
        let side = cross(&[0.0, 0.0, 1.0], &[lv[0] / m, lv[1] / m, lv[2] / m]);
        for i in 0..3 { lv[i] = lv[i] + tau * 0.5 / n as f64 * side[i]; }
    }
    let om_kick = lv[1].atan2(lv[0]) / 0.5;          // angle turned in 0.5 s, per second
    println!("wheel {:.1} kg, rim radius {:.2} m, string to hub {:.2} m, g {} m/s^2", M, R, D, G);
    println!("weight m g                       {:9.4} N", M * G);
    println!("spin inertia I3 = m R^2          {:9.4} kg m^2", I3);
    println!("tilt inertia I1, about the string{:9.4} kg m^2", I1);
    println!("spin, once a second              {:9.4} rad/s", w);
    println!("angular momentum L = I3 w        {:9.4} kg m^2/s", l);
    println!("gravity torque tau = m g d       {:9.4} N m", tau);
    println!("road 1  formula tau / L          {:9.4} rad/s", om);
    println!("road 2  rigid-body simulation    {:9.4} rad/s", om_sim);
    println!("road 3  10000 kicks in 0.5 s     {:9.4} rad/s", om_kick);
    println!("precession period 2 pi / Omega   {:9.4} s", 2.0 * PI / om);
    println!("hub speed round the string       {:9.4} m/s", om * D);
    println!("string lean, m d Omega^2 vs m g  {:9.4} degrees", (om * om * D).atan2(G).to_degrees());
    let level = steady.iter().map(|s| tilt(s).abs()).fold(0.0, f64::max) < 1e-6;
    println!("axle level to 1e-6 deg for 2 s   {:>9}", if level { "yes" } else { "no" });

    // ---- the stubborn wheel: hands 0.30 m apart turn the axle a quarter turn in 0.5 s ----
    let (wt, h) = ((PI / 2.0) / 0.5, 1e-6);
    let lvec = |t: f64| [I3 * w * (wt * t).cos(), I3 * w * (wt * t).sin(), M * R * R / 2.0 * wt]; // turn about a diameter
    let (p, q) = (lvec(h), lvec(-h));
    let need: Vec<f64> = (0..3).map(|i| (p[i] - q[i]) / (2.0 * h)).collect();
    let need_mag = dot(&need, &need).sqrt();
    println!("turn rate, quarter turn in 0.5 s {:9.4} rad/s", wt);
    println!("torque needed, L times turn rate {:9.4} N m", l * wt);
    println!("  same, by differencing L(t)     {:9.4} N m", need_mag);
    println!("  force at each hand, 0.30 m     {:9.4} N", l * wt / 0.30);
    println!("  the same at 5 rev/s            {:9.4} N", 5.0 * l * wt / 0.30);

    // ---- release from rest, axle level: the formula only on average, only at fast spin ----
    let ts: Vec<String> = (0..31).map(|k| format!("{:5.2}", 0.04 * k as f64)).collect();
    println!("time s      {}", ts.join(" "));
    let mut out = Vec::new();
    for rps in [1, 4] {
        let ls = I3 * 2.0 * PI * rps as f64;
        let (p, dip) = run([ls, 0.0, 0.0], 3.0);
        let row: Vec<String> = p[..31].iter().map(|s| format!("{:5.1}", tilt(s))).collect();
        println!("tilt {} rev/s  {}", rps, row.join(" "));
        out.push((rps, p, dip, ls));
    }
    for (rps, p, dip, ls) in &out {
        println!("{} rev/s: deepest dip {:6.2} deg, estimate 2 tau I1/L^2 {:6.2} deg; mean turn {:.4} rad/s vs tau/L {:.4}, {:+.1}%",
                 rps, dip, (2.0 * tau * I1 / (ls * ls)).to_degrees(), turned(p) / 3.0, tau / ls,
                 100.0 * (turned(p) / 3.0 * ls / tau - 1.0));
    }
    let e0 = energy(&out[0].1[0]);
    let drift = out[0].1.iter().map(|s| (energy(s) - e0).abs()).fold(0.0, f64::max);

    // ---- what breaks ----
    println!("wrong: spin 1 rev/s as w = 1     {:9.4} rad/s", tau / (I3 * 1.0));
    println!("wrong: disc inertia m R^2 / 2    {:9.4} rad/s", tau / (I3 / 2.0 * w));
    println!("wrong: rim radius as lever arm   {:9.4} rad/s", M * G * R / l);
    println!("wrong: period as 1 / Omega       {:9.4} s", 1.0 / om);
    let (x, top) = (110.0 + 400.0 * D, 470.0 + 400.0 * D);
    println!("figure, 400 units per m: side pivot (110,150) hub ({:.0},150) rim ({:.0},{:.0}) to ({:.0},{:.0}); top pivot (470,150) hub ({:.0},150) path radius {:.0}",
             x, x, 150.0 - 400.0 * R, x, 150.0 + 400.0 * R, top, 400.0 * D);

    let (p1, l1) = (&out[0].1, out[0].3);
    let (p4, dip4, l4) = (&out[1].1, out[1].2, out[1].3);
    assert!((om_sim - om).abs() < 1e-6 * om && level);           // simulation against the formula
    assert!((om_kick - om).abs() < 1e-3 * om);                   // kicks against the formula
    assert!((need_mag - l * wt).abs() < 1e-6);                   // torque by differencing against L times rate
    assert!((turned(p4) / 3.0 - tau / l4).abs() < 0.02 * tau / l4); // fast spin: formula holds on average
    let est4 = (2.0 * tau * I1 / (l4 * l4)).to_degrees();
    assert!((dip4 - est4).abs() < 0.05 * est4);
    assert!((turned(p1) / 3.0 - tau / l1).abs() > 0.05 * tau / l1); // slow spin: off by more than 5%
    assert!(drift < 1e-9);                                       // energy kept by the simulation
    println!("ALL CHECKS PASS");
}
