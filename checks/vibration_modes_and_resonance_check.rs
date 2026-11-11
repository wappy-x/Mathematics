// Vibration modes and resonance -- the same check as the Python, in Rust.  No crates.
// A two-span steel footbridge, its sideways sway lumped into two masses on three springs:
//   M x'' + C x' + K x = F sin(W t),  modes from K v = lam M v,  f = sqrt(lam) / (2 pi).
// Roads to the modes: the quadratic det(K - lam M) = 0; inverse iteration; a free-swing RK4 run.
// Roads to the sway: modal superposition; a direct complex solve; an RK4 run of the crowd.
use std::f64::consts::PI;

const M1: f64 = 60000.0; const M2: f64 = 40000.0; const KS: f64 = 2.0e6; // kg, kg, N/m per spring
const ZETA: f64 = 0.01;                                                  // damping ratio of each mode
const WALKERS: f64 = 100.0; const PUSH: f64 = 25.0; const F_WALK: f64 = 1.0; // people, N each, Hz
const M: [f64; 2] = [M1, M2];
const K: [[f64; 2]; 2] = [[2.0 * KS, -KS], [-KS, 2.0 * KS]];

#[derive(Clone, Copy)]
struct Cx { re: f64, im: f64 }                                         // a complex number, written out
impl Cx {
    fn n(re: f64, im: f64) -> Cx { Cx { re, im } }
    fn mul(self, o: Cx) -> Cx { Cx::n(self.re * o.re - self.im * o.im, self.re * o.im + self.im * o.re) }
    fn sub(self, o: Cx) -> Cx { Cx::n(self.re - o.re, self.im - o.im) }
    fn add(self, o: Cx) -> Cx { Cx::n(self.re + o.re, self.im + o.im) }
    fn div(self, o: Cx) -> Cx { let d = o.re * o.re + o.im * o.im;
        Cx::n((self.re * o.re + self.im * o.im) / d, (self.im * o.re - self.re * o.im) / d) }
    fn abs(self) -> f64 { self.re.hypot(self.im) }
}

fn solve(a: [[Cx; 2]; 2], b: [Cx; 2]) -> [Cx; 2] {                     // 2x2 solve by Cramer's rule
    let d = a[0][0].mul(a[1][1]).sub(a[0][1].mul(a[1][0]));
    [b[0].mul(a[1][1]).sub(a[0][1].mul(b[1])).div(d), a[0][0].mul(b[1]).sub(b[0].mul(a[1][0])).div(d)]
}
fn solve_r(a: [[f64; 2]; 2], b: [f64; 2]) -> [f64; 2] {
    let r = |x: f64| Cx::n(x, 0.0);
    let s = solve([[r(a[0][0]), r(a[0][1])], [r(a[1][0]), r(a[1][1])]], [r(b[0]), r(b[1])]);
    [s[0].re, s[1].re]
}
fn dotm(u: [f64; 2], v: [f64; 2]) -> f64 { M[0] * u[0] * v[0] + M[1] * u[1] * v[1] }
fn dotk(u: [f64; 2], v: [f64; 2]) -> f64 { let mut s = 0.0; for i in 0..2 { for j in 0..2 { s += u[i] * K[i][j] * v[j] } } s }

fn rk4(c: [[f64; 2]; 2], force: &dyn Fn(f64) -> [f64; 2], x0: [f64; 4], dt: f64, n: usize) -> Vec<[f64; 2]> {
    let acc = |t: f64, s: [f64; 4]| -> [f64; 4] {
        let f = force(t);
        let mut a = [s[2], s[3], 0.0, 0.0];
        for i in 0..2 { a[2 + i] = (f[i] - (0..2).map(|j| c[i][j] * s[2 + j] + K[i][j] * s[j]).sum::<f64>()) / M[i] }
        a
    };
    let st = |s: [f64; 4], k: [f64; 4], h: f64| -> [f64; 4] { let mut o = s; for i in 0..4 { o[i] += h * k[i] } o };
    let (mut s, mut out) = (x0, vec![[x0[0], x0[1]]]);
    for i in 0..n {
        let t = i as f64 * dt;
        let k1 = acc(t, s); let k2 = acc(t + dt / 2.0, st(s, k1, dt / 2.0));
        let k3 = acc(t + dt / 2.0, st(s, k2, dt / 2.0)); let k4 = acc(t + dt, st(s, k3, dt));
        for j in 0..4 { s[j] += dt / 6.0 * (k1[j] + 2.0 * k2[j] + 2.0 * k3[j] + k4[j]) }
        out.push([s[0], s[1]]);
    }
    out
}

fn main() {
    let f = [PUSH * WALKERS * 0.6, PUSH * WALKERS * 0.4];
    let wf = 2.0 * PI * F_WALK;
    // ---- modes, road A: det(K - lam M) = 0 is a quadratic in lam ----
    let (a, b, c) = (M1 * M2, -(M1 * K[1][1] + M2 * K[0][0]), K[0][0] * K[1][1] - K[0][1] * K[0][1]);
    let dq = (b * b - 4.0 * a * c).sqrt();
    let lam = [(-b - dq) / (2.0 * a), (-b + dq) / (2.0 * a)];
    let w = [lam[0].sqrt(), lam[1].sqrt()];
    let v = [[1.0, (K[0][0] - lam[0] * M1) / KS], [1.0, (K[0][0] - lam[1] * M1) / KS]];
    let mr = [dotm(v[0], v[0]), dotm(v[1], v[1])];
    let kr = [dotk(v[0], v[0]), dotk(v[1], v[1])];
    let pr = [v[0][0] * f[0] + v[0][1] * f[1], v[1][0] * f[0] + v[1][1] * f[1]];
    println!("inputs: m1 = {:.0} kg, m2 = {:.0} kg, k = {:.0} N/m each, zeta = {}", M1, M2, KS, ZETA);
    println!("quadratic, in units of 1e9: {:.1} lam^2 - {:.1} lam + {:.1} = 0", a / 1e9, -b / 1e9, c / 1e9);
    for r in 0..2 {
        println!("mode {}: lam = {:.4} 1/s^2, w = {:.4} rad/s, f = {:.4} Hz, shape (1, {:.4})", r + 1, lam[r], w[r], w[r] / (2.0 * PI), v[r][1]);
        println!("mode {}: modal mass {:.0} kg, modal stiffness {:.0} N/m, modal force {:.1} N", r + 1, mr[r], kr[r], pr[r]);
    }
    println!("orthogonality: |v1 . M v2| = {:.6} kg, |v1 . K v2| = {:.6} N/m; {:.4} x {:.4} = {:.4} = m1/m2",
             dotm(v[0], v[1]).abs(), dotk(v[0], v[1]).abs(), v[0][1], -v[1][1], -v[0][1] * v[1][1]);
    // ---- modes, road B: inverse iteration, mode 2 kept M-orthogonal to mode 1 ----
    let mut it: Vec<[f64; 2]> = vec![];
    for r in 0..2 {
        let mut x = [1.0, 0.3];
        for _ in 0..60 {
            x = solve_r(K, [M[0] * x[0], M[1] * x[1]]);
            if r == 1 { let s = dotm(it[0], x) / dotm(it[0], it[0]); x = [x[0] - s * it[0][0], x[1] - s * it[0][1]] }
            x = [x[0] / x[0], x[1] / x[0]];
        }
        it.push(x);
        println!("inverse iteration mode {}: shape (1, {:.4}), Rayleigh quotient {:.4} 1/s^2", r + 1, x[1], dotk(x, x) / dotm(x, x));
    }
    // ---- modes, road C: release the deck in mode 1's shape and time the swing ----
    let fr = rk4([[0.0; 2]; 2], &|_t| [0.0, 0.0], [0.01, 0.01 * v[0][1], 0.0, 0.0], 1e-3, 20000);
    let up: Vec<f64> = (1..fr.len()).filter(|&i| fr[i - 1][0] > 0.0 && 0.0 >= fr[i][0]).map(|i| i as f64 * 1e-3).collect();
    let t_p = (up[up.len() - 1] - up[0]) / (up.len() - 1) as f64;
    let mx = |i: usize, s: &[[f64; 2]]| s.iter().map(|p| p[i]).fold(f64::MIN, f64::max);
    let mn = |i: usize, s: &[[f64; 2]]| s.iter().map(|p| p[i]).fold(f64::MAX, f64::min);
    println!("free swing in mode 1: period {:.4} s = {:.4} Hz, span 2 / span 1 peaks {:.4}", t_p, 1.0 / t_p, mx(1, &fr) / mx(0, &fr));
    // ---- damping: Rayleigh C = al M + be K gives zeta in both modes ----
    let (al, be) = (2.0 * ZETA * w[0] * w[1] / (w[0] + w[1]), 2.0 * ZETA / (w[0] + w[1]));
    let mut cm = [[0.0; 2]; 2];
    for i in 0..2 { for j in 0..2 { cm[i][j] = al * if i == j { M[i] } else { 0.0 } + be * K[i][j] } }
    let zr: Vec<f64> = (0..2).map(|r| { let u = v[r]; let mut s = 0.0;
        for i in 0..2 { for j in 0..2 { s += u[i] * cm[i][j] * u[j] } } s / (2.0 * mr[r] * w[r]) }).collect();
    println!("Rayleigh damping: alpha {:.5} 1/s, beta {:.6} s; modal zeta {:.4}, {:.4}", al, be, zr[0], zr[1]);
    let modal = |om: f64, z: f64, ff: [f64; 2]| -> ([f64; 2], [Cx; 2]) {      // sway amplitudes (m), modal sum
        let q: Vec<Cx> = (0..2).map(|r| Cx::n((v[r][0] * ff[0] + v[r][1] * ff[1]) / kr[r], 0.0)
            .div(Cx::n(1.0 - (om / w[r]).powi(2), 2.0 * z * om / w[r]))).collect();
        let x = |i: usize| q[0].mul(Cx::n(v[0][i], 0.0)).add(q[1].mul(Cx::n(v[1][i], 0.0))).abs();
        ([x(0), x(1)], [q[0], q[1]])
    };
    let direct = |om: f64| -> [f64; 2] {                                  // (K - om^2 M + j om C) X = F
        let mut a = [[Cx::n(0.0, 0.0); 2]; 2];
        for i in 0..2 { for j in 0..2 { a[i][j] = Cx::n(K[i][j] - om * om * if i == j { M[i] } else { 0.0 }, om * cm[i][j]) } }
        let s = solve(a, [Cx::n(f[0], 0.0), Cx::n(f[1], 0.0)]);
        [s[0].abs(), s[1].abs()]
    };
    let (x, q) = modal(wf, ZETA, f);
    let xd = direct(wf);
    println!("crowd in step: {} walkers x {:.0} N at {:.2} Hz ({:.4} rad/s), F = ({:.0}, {:.0}) N", WALKERS, PUSH, F_WALK, wf, f[0], f[1]);
    println!("spread evenly on spans of 60 m and 40 m: {:.0} and {:.0} walkers; resonance gain 1/(2 zeta) = {:.2}",
             WALKERS * 0.6, WALKERS * 0.4, 1.0 / (2.0 * ZETA));
    for r in 0..2 {
        let hr = 1.0 / Cx::n(1.0 - (wf / w[r]).powi(2), 2.0 * ZETA * wf / w[r]).abs();
        println!("mode {} at {:.2} Hz: f/f_r {:.5}, gain {:.2}, static {:.4} mm, modal sway {:.2} mm",
                 r + 1, F_WALK, wf / w[r], hr, pr[r] / kr[r] * 1000.0, q[r].abs() * 1000.0);
    }
    println!("sway at {:.2} Hz, modal: span 1 {:.2} mm, span 2 {:.2} mm; accel span 1 {:.3} m/s^2",
             F_WALK, x[0] * 1000.0, x[1] * 1000.0, x[0] * wf * wf);
    println!("sway at {:.2} Hz, direct: span 1 {:.2} mm, span 2 {:.2} mm", F_WALK, xd[0] * 1000.0, xd[1] * 1000.0);
    let cr = rk4(cm, &|t| [f[0] * (wf * t).sin(), f[1] * (wf * t).sin()], [0.0; 4], 1e-3, 160000);
    let tail = &cr[150000..];
    let xs = [0.5 * (mx(0, tail) - mn(0, tail)), 0.5 * (mx(1, tail) - mn(1, tail))];
    println!("sway at {:.2} Hz, RK4 after 150 s: span 1 {:.2} mm, span 2 {:.2} mm", F_WALK, xs[0] * 1000.0, xs[1] * 1000.0);
    let ts: Vec<usize> = (0..65).step_by(5).collect();
    let env: Vec<String> = ts.iter().map(|&t| { let lo = if t >= 1 { 1000 * t - 1000 } else { 0 };
        format!("{:5.2}", cr[lo..1000 * t + 1].iter().map(|p| p[0].abs()).fold(0.0, f64::max) * 1000.0) }).collect();
    println!("chart, build-up t (s) {}", ts.iter().map(|t| format!("{:5}", t)).collect::<Vec<_>>().join(" "));
    println!("chart, span 1 env mm  {}", env.join(" "));
    println!("time constant 1/(zeta w1) {:.2} s", 1.0 / (ZETA * w[0]));
    let fs: Vec<f64> = (0..21).map(|i| 0.5 + 0.1 * i as f64).collect();
    let sw: Vec<[f64; 2]> = fs.iter().map(|&fq| modal(2.0 * PI * fq, ZETA, f).0).collect();
    println!("chart, f (Hz)    {}", fs.iter().map(|x| format!("{:5.1}", x)).collect::<Vec<_>>().join(" "));
    for i in 0..2 { println!("chart, span {} mm {}", i + 1, sw.iter().map(|s| format!("{:5.2}", s[i] * 1000.0)).collect::<Vec<_>>().join(" ")) }
    let pk = [modal(w[0], ZETA, f).0, modal(w[1], ZETA, f).0];
    println!("peaks: at f1 span 1 {:.2} mm, span 2 {:.2} mm; at f2 span 1 {:.2} mm, span 2 {:.2} mm",
             pk[0][0] * 1000.0, pk[0][1] * 1000.0, pk[1][0] * 1000.0, pk[1][1] * 1000.0);
    println!("dampers, zeta 0.10: span 1 at f1 {:.2} mm, at {:.2} Hz {:.2} mm",
             modal(w[0], 0.10, f).0[0] * 1000.0, F_WALK, modal(wf, 0.10, f).0[0] * 1000.0);
    // ---- what breaks ----
    let x0 = modal(wf, 0.0, f).0;
    println!("no damping at {:.2} Hz: span 1 {:.2} mm; at f1 the formula divides by zero", F_WALK, x0[0] * 1000.0);
    let lm = [KS / 50000.0, 3.0 * KS / 50000.0];                           // equal 50 t masses
    let xe = (0..2).map(|r| Cx::n([2500.0, 500.0][r] / ([2.0, 6.0][r] * KS), 0.0).div(Cx::n(1.0 - wf * wf / lm[r], 2.0 * ZETA * wf / lm[r].sqrt()))).fold(Cx::n(0.0, 0.0), |a, b| a.add(b)).abs();
    println!("equal masses 50000 kg: f = {:.4}, {:.4} Hz; span 1 sway {:.2} mm", lm[0].sqrt() / (2.0 * PI), lm[1].sqrt() / (2.0 * PI), xe * 1000.0);
    let xst = solve_r(K, f);
    println!("static push: span 1 {:.4} mm, span 2 {:.4} mm", xst[0] * 1000.0, xst[1] * 1000.0);
    let xr = modal(wf, ZETA, [f[0] / WALKERS.sqrt(), f[1] / WALKERS.sqrt()]).0;
    println!("out of step, 25 sqrt(N) = {:.0} N: span 1 {:.2} mm", PUSH * WALKERS.sqrt(), xr[0] * 1000.0);
    let x2k = modal(wf, ZETA, [f[0] * 2000.0 / WALKERS, f[1] * 2000.0 / WALKERS]).0;
    println!("2000 walkers in step: linear model says span 1 {:.0} mm", x2k[0] * 1000.0);
    println!("figure, mode 1 (160.0, 60.0) (360.0, {:.1}); mode 2 (160.0, 230.0) (360.0, {:.1})", 110.0 - 50.0 * v[0][1], 280.0 - 50.0 * v[1][1]);

    assert!((0..2).all(|r| (it[r][1] - v[r][1]).abs() < 1e-9));          // inverse iteration vs quadratic
    assert!((1.0 / t_p - w[0] / (2.0 * PI)).abs() < 1e-4);                 // free swing vs quadratic
    assert!(dotm(v[0], v[1]).abs() < 1e-6 * M1);                           // modes are M-orthogonal
    assert!(zr.iter().all(|z| (z - ZETA).abs() < 1e-12));                  // Rayleigh C gives zeta per mode
    assert!((0..2).all(|i| (x[i] - xd[i]).abs() < 1e-9));                  // modal sum vs direct solve
    assert!((0..2).all(|i| (xs[i] - x[i]).abs() < 1e-3 * x[0]));           // RK4 vs modal sum
    assert!(fs.iter().all(|&fq| (modal(2.0 * PI * fq, ZETA, f).0[0] - direct(2.0 * PI * fq)[0]).abs() < 1e-9));
    println!("ALL CHECKS PASS");
}
