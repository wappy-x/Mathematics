// The Riemann problem -- the same check as rarefaction_and_the_riemann_problem_check.py,
// in Rust.  Standard library only, no crates.  A one-lane road (illustrative
// numbers): top speed 25 m/s, jam 150 cars/km, flow q = V rho (1 - rho/RJ).  The
// light at x = 0 turns green at t = 0.  Roads: the fan formula; a Rusanov grid at
// three steps; a car's path by RK4; centred-difference residuals; exact fractions.
// Compile: rustc --edition 2021 -O rarefaction_and_the_riemann_problem_check.rs

const V: f64 = 25.0; // top speed, m/s
const RJ: f64 = 0.15; // jam density, cars/m
fn q(r: f64) -> f64 { V * r * (1.0 - r / RJ) } // flow, cars/s
fn wave(r: f64) -> f64 { V * (1.0 - 2.0 * r / RJ) } // wave speed u = q'(rho), m/s
fn car(r: f64) -> f64 { V * (1.0 - r / RJ) } // car speed, m/s
fn rho_of(u: f64) -> f64 { RJ * (1.0 - u / V) / 2.0 }

fn riemann(ul: f64, ur: f64, x: f64, t: f64) -> f64 { // Burgers u_t + (u^2/2)_x = 0
    if ul > ur { return if x < (ul + ur) / 2.0 * t { ul } else { ur }; } // shock
    if x <= ul * t { return ul; } // fan: u = x/t between the edges
    if x >= ur * t { return ur; }
    x / t
}
fn rho(x: f64, t: f64) -> f64 { rho_of(riemann(wave(RJ), wave(0.0), x, t)) }

const X0: f64 = 100.0; // the car starts 100 m behind the light
fn path(t: f64) -> f64 { if t > X0 / V { V * t - 2.0 * (V * X0 * t).sqrt() } else { -X0 } }
fn vel(x: f64, t: f64) -> f64 { car(rho(x, t)) }
fn rk4(s: f64, n: usize) -> f64 { // RK4 from the moment the fan reaches the car
    let (mut x, mut t) = (-X0, X0 / V);
    if s <= t { return x; }
    let h = (s - t) / n as f64;
    for _ in 0..n {
        let k1 = vel(x, t); let k2 = vel(x + h / 2.0 * k1, t + h / 2.0);
        let k3 = vel(x + h / 2.0 * k2, t + h / 2.0); let k4 = vel(x + h * k3, t + h);
        x += h / 6.0 * (k1 + 2.0 * k2 + 2.0 * k3 + k4); t += h;
    }
    x
}

// exact fractions, numerator and denominator
#[derive(Clone, Copy, PartialEq, Debug)]
struct Fr(i64, i64);
fn gcd(a: i64, b: i64) -> i64 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn fr(n: i64, d: i64) -> Fr { let g = gcd(n, d).max(1) * d.signum(); Fr(n / g, d / g) }
impl Fr {
    fn add(self, o: Fr) -> Fr { fr(self.0 * o.1 + o.0 * self.1, self.1 * o.1) }
    fn sub(self, o: Fr) -> Fr { fr(self.0 * o.1 - o.0 * self.1, self.1 * o.1) }
    fn mul(self, o: Fr) -> Fr { fr(self.0 * o.0, self.1 * o.1) }
    fn div(self, o: Fr) -> Fr { fr(self.0 * o.1, self.1 * o.0) }
    fn f(self) -> f64 { self.0 as f64 / self.1 as f64 }
}
fn qk(r: i64) -> Fr { fr(90 * r, 1).mul(fr(1, 1).sub(fr(r, 150))) } // km/h, cars/km
fn wk(r: i64) -> Fr { fr(90, 1).mul(fr(1, 1).sub(fr(2 * r, 150))) }

fn grid(hx: f64) -> (f64, f64, f64) { // Rusanov flux, no Riemann solution inside
    let nx = (4000.0 / hx) as usize;
    let mut r: Vec<f64> = (0..nx).map(|i| if -2000.0 + (i as f64 + 0.5) * hx < 0.0 { RJ } else { 0.0 }).collect();
    let dt = 0.5 * hx / V;
    let steps = (60.0 / dt).round() as usize;
    let mut thru = 0.0;
    for _ in 0..steps {
        let mut e = vec![r[0]]; e.extend_from_slice(&r); e.push(r[nx - 1]);
        let fl: Vec<f64> = (0..nx + 1).map(|i| (q(e[i]) + q(e[i + 1])) / 2.0
            - wave(e[i]).abs().max(wave(e[i + 1]).abs()) / 2.0 * (e[i + 1] - e[i])).collect();
        thru += fl[nx / 2] * dt;
        r = (0..nx).map(|i| r[i] - dt / hx * (fl[i + 1] - fl[i])).collect();
    }
    let err: f64 = (0..nx).map(|i| (r[i] - rho(-2000.0 + (i as f64 + 0.5) * hx, 60.0)).abs() * hx).sum();
    (err, thru, r.iter().sum::<f64>() * hx)
}

fn main() {
    let (ul, ur) = (wave(RJ), wave(0.0));
    println!("wave speeds: queue {:.1} km/h, empty road {:.1} km/h", ul * 3.6, ur * 3.6);
    println!("fan edges at 10 s: {:.0} m and {:.0} m", ul * 10.0, ur * 10.0);
    let r0 = rho(0.0, 30.0);
    println!("at the light: density {:.1} cars/km, car speed {:.1} km/h, flow {:.1} cars/h", r0 * 1000.0, car(r0) * 3.6, q(r0) * 3600.0);
    let through = q(r0) * 60.0;
    let w = V * 60.0 / 6000.0; // count the cars past the light, cell by cell
    let past: f64 = (0..6000).map(|k| rho((k as f64 + 0.5) * w, 60.0) * w).sum();
    println!("cars through in 60 s: flow x time {:.4}, counted on the road {:.4}", through, past);
    assert!((r0 - RJ / 2.0).abs() < 1e-12 && (through - past).abs() < 1e-6 && (through - V * RJ / 4.0 * 60.0).abs() < 1e-9);

    println!("car 100 m back:  t s   closed x m   RK4 x m   speed km/h");
    for s in [4.0, 9.0, 16.0, 25.0, 36.0].iter() {
        let (xc, xr) = (path(*s), rk4(*s, 4000));
        println!("              {:5.0}   {:9.3}  {:8.3}   {:8.2}", s, xc, if xr.abs() > 5e-4 { xr } else { 0.0 }, car(rho(xc, *s)) * 3.6);
        assert!((xc - xr).abs() < 1e-3);
    }
    let tc = 4.0 * X0 / V;
    println!("it crosses the light at {:.1} s; cars ahead of it: {:.1}; flow x time {:.1}", tc, X0 * RJ, q(r0) * tc);
    assert!(path(tc).abs() < 1e-9 && (q(r0) * tc - X0 * RJ).abs() < 1e-9);

    print!("residual u_t + u u_x at -100 m, 20 s, in mm/s^2:");
    let mut res = vec![];
    for (d, name) in [(1.0, "1.0"), (0.5, "0.5"), (0.25, "0.25")] {
        let f = |xx: f64, tt: f64| riemann(ul, ur, xx, tt);
        let ut = (f(-100.0, 20.0 + d) - f(-100.0, 20.0 - d)) / (2.0 * d);
        let ux = (f(-100.0 + d, 20.0) - f(-100.0 - d, 20.0)) / (2.0 * d);
        res.push(ut + f(-100.0, 20.0) * ux);
        print!("  step {} -> {:.4}", name, res[res.len() - 1] * 1000.0);
    }
    println!();
    assert!((res[0] / res[1] - 4.0).abs() < 0.01 && (res[1] / res[2] - 4.0).abs() < 0.01);

    let (mut errs, mut thrus) = (vec![], vec![]);
    for hx in [20.0, 10.0, 5.0] {
        let (err, thru, tot) = grid(hx);
        errs.push(err); thrus.push(thru);
        println!("grid h = {:4.1} m: misplaced cars {:.4}, through the light {:.4}, total cars {:.4}", hx, err, thru, tot);
        assert!((tot - 2000.0 * RJ).abs() < 1e-9);
    }
    println!("error ratio per halving: {:.3} and {:.3}; observed order {:.2} and {:.2}", errs[0] / errs[1], errs[1] / errs[2],
        (errs[0] / errs[1]).log2(), (errs[1] / errs[2]).log2());
    assert!(errs[2] < errs[1] && errs[1] < errs[0] && errs[1] / errs[2] > 1.4);
    let gap = |v: f64| (v - past).abs();
    assert!(gap(thrus[2]) < gap(thrus[1]) && gap(thrus[1]) < gap(thrus[0]));

    // the other branch: red light, 30 cars/km meets the queue -> a shock
    let s_rh = qk(150).sub(qk(30)).div(fr(150 - 30, 1));
    let s_b = wk(30).add(wk(150)).div(fr(2, 1));
    println!("red light: wave speeds {:.1} and {:.1} km/h; shock {:.1} km/h (cars), {:.1} km/h (Burgers)", wk(30).f(), wk(150).f(), s_rh.f(), s_b.f());
    assert!(s_rh == s_b && s_b == fr(-18, 1));
    let (rl, rr) = (0.03, RJ); // the same shock from the float solver
    let cnt: f64 = (0..8000).map(|k| rho_of(riemann(wave(rl), wave(rr), -2000.0 + (k as f64 + 0.5) * 0.5, 60.0)) * 0.5).sum();
    let inflow = 2000.0 * (rl + rr) + q(rl) * 60.0; // cars at t = 0 plus cars driven in
    println!("red light, 60 s: shock at {:.0} m; cars on 4 km counted {:.4}, by inflow {:.4}", (wave(rl) + wave(rr)) / 2.0 * 60.0, cnt, inflow);
    assert!((cnt - inflow).abs() < 1e-6);

    // what breaks
    let jump = qk(150).sub(qk(0)).div(fr(150, 1));
    println!("breaks: green-light jump kept: speed {:.1} km/h, flow at light {:.0} cars/h (right: {:.0})", jump.f(), qk(150).f(), q(r0) * 3600.0);
    let cs = fr(90, 1).mul(fr(1, 1).sub(fr(30, 150))).add(fr(0, 1)).div(fr(2, 1));
    println!("breaks: shock at the average car speed: {:.1} km/h (right: {:.1})", cs.f(), s_rh.f());
    let (a, b) = (wk(30).div(fr(18, 5)), wk(150).div(fr(18, 5))); // m/s
    let wrong = fr(2, 3).mul(a.mul(a).add(a.mul(b)).add(b.mul(b))).div(a.add(b));
    println!("breaks: conserve u^2/2 instead of cars: {:.1} m/s = {:.1} km/h (right: {:.1})", wrong.f(), wrong.mul(fr(18, 5)).f(), s_rh.f());
    let over = a.sub(b).mul(fr(10, 1));
    println!("breaks: fan drawn for the red light: {:.0} m of road given two densities at 10 s", over.f());
    assert!(jump == fr(0, 1) && cs == fr(36, 1));
    assert!(wrong == fr(-95, 3) && over == fr(400, 1));

    for tt in [20.0, 40.0, 60.0] {
        let pts: Vec<String> = (0..7).map(|k| format!("{:.1}", rho(-1500.0 + 500.0 * k as f64, tt) * 1000.0)).collect();
        println!("chart, t = {:.0} s: {}", tt, pts.join(" "));
    }
    let fig: Vec<String> = [4.0, 9.0, 16.0, 25.0, 40.0].iter().map(|s| format!("({:.1}, {:.0})", path(*s), s)).collect();
    println!("figure, fan edges at 40 s: {:.0} m, {:.0} m; car path (x m, t s): {}", ul * 40.0, ur * 40.0, fig.join(", "));
    println!("ALL CHECKS PASS");
}
