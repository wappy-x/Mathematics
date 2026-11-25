// Weak waves on a 65 cm guitar string plucked 4 mm at 16 cm from the bridge.
// Roads: d'Alembert with mirror images; Galerkin sine sums with N = 10, 40, 160 modes;
// energy by closed form, by mode sums and by quadrature; the L2 gap by quadrature and
// by the tail series; the weak form's residual by centred differences in time.
use std::f64::consts::PI;

const L: f64 = 0.65; const F1: f64 = 329.63; // string length, m; open high E string, Hz
const A: f64 = 0.16; const H: f64 = 0.004; const T1: f64 = 1e-3; // pluck point, m; height, m; time watched, s
const KAPPA: f64 = 1.110e-4; // copper's diffusivity, m^2/s, for the heat contrast
const NS: [usize; 3] = [10, 40, 160];
const KMAX: usize = 100000;

fn nsum<I: Iterator<Item = f64>>(it: I) -> f64 { // compensated sum, as Python's sum() does it
    let (mut s, mut c) = (0.0f64, 0.0f64);
    for x in it {
        let t = s + x;
        c += if s.abs() >= x.abs() { (s - t) + x } else { (x - t) + s }; s = t;
    }
    s + c
}
fn f(x: f64) -> f64 { if x <= A { H * x / A } else { H * (L - x) / (L - A) } }
fn df(x: f64) -> f64 { if x < A { H / A } else { -H / (L - A) } }
fn wrap(s: f64) -> f64 { (s + L).rem_euclid(2.0 * L) - L } // odd mirror images about both ends
fn big_f(s: f64) -> f64 { let s = wrap(s); if s >= 0.0 { f(s) } else { -f(-s) } }
fn big_df(s: f64) -> f64 { df(wrap(s).abs()) }
fn kk(k: usize) -> f64 { k as f64 * PI / L }
fn b_closed(k: usize) -> f64 { 2.0 * H * L * L * (kk(k) * A).sin() / ((k * k) as f64 * PI * PI * A * (L - A)) }
fn simpson(g: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 { // ends nudged inward
    let (h, e) = ((b - a) / n as f64, (b - a) * 1e-12);
    h / 3.0 * nsum((0..=n).map(|i| {
        let w = if i == 0 || i == n { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 };
        w * g((a + i as f64 * h).max(a + e).min(b - e))
    }))
}

struct S { c: f64, rho: f64, ten: f64, b: Vec<f64> }
impl S {
    fn om(&self, k: usize) -> f64 { self.c * kk(k) }
    fn u(&self, x: f64, t: f64) -> f64 { (big_f(x - self.c * t) + big_f(x + self.c * t)) / 2.0 }
    fn ux(&self, x: f64, t: f64) -> f64 { (big_df(x - self.c * t) + big_df(x + self.c * t)) / 2.0 }
    fn ut(&self, x: f64, t: f64) -> f64 { self.c * (big_df(x + self.c * t) - big_df(x - self.c * t)) / 2.0 }
    fn kinks(&self, t: f64, lo: f64, hi: f64) -> Vec<f64> { // x -/+ c t = +/- A + 2 L m
        let mut p = vec![lo, hi];
        for s in [A, -A] {
            for m in -3..4 {
                for x in [s + self.c * t + 2.0 * L * m as f64, s - self.c * t + 2.0 * L * m as f64] {
                    if lo < x && x < hi { p.push(x); }
                }
            }
        }
        p.sort_by(|a, b| a.partial_cmp(b).unwrap()); p.dedup(); p
    }
    fn pieces(&self, g: &dyn Fn(f64) -> f64, t: f64, n: usize, lo: f64, hi: f64) -> f64 {
        let p = self.kinks(t, lo, hi);
        nsum((0..p.len() - 1).map(|i| simpson(g, p[i], p[i + 1], n)))
    }
    fn mode_e(&self, k: usize) -> f64 { self.ten * L / 4.0 * kk(k).powf(2.0) * self.b[k].powf(2.0) }
    fn galerkin(&self, x: f64, t: f64, n: usize) -> (f64, f64, f64) { // u_N, slope, speed
        let (mut s, mut sx, mut st) = (0.0, 0.0, 0.0);
        for k in 1..=n {
            let (ck, sk) = ((self.om(k) * t).cos(), (self.om(k) * t).sin());
            s += self.b[k] * ck * (kk(k) * x).sin();
            sx += self.b[k] * ck * kk(k) * (kk(k) * x).cos();
            st -= self.b[k] * self.om(k) * sk * (kk(k) * x).sin();
        }
        (s, sx, st)
    }
    fn trap_energy(&self, n: usize, t: f64) -> f64 { // trapezoid rule: exact for these sine products
        let m = 1000;
        let mut tot = 0.0;
        for i in 0..=m {
            let (_, sx, st) = self.galerkin(i as f64 * L / m as f64, t, n);
            let w = if i == 0 || i == m { 0.5 } else { 1.0 };
            tot += w * (self.rho / 2.0 * st * st + self.ten / 2.0 * sx * sx);
        }
        tot * L / m as f64
    }
}
fn join(v: &[f64], d: usize) -> String { v.iter().map(|x| format!("{:.*}", d, x)).collect::<Vec<_>>().join(", ") }

fn main() {
    let c = 2.0 * L * F1;
    let rho = 7850.0 * PI * 0.000127f64.powf(2.0);
    let mut b = vec![0.0];
    b.extend((1..=KMAX).map(b_closed));
    let (st, ten) = (S { c, rho, ten: rho * c * c, b }, rho * c * c);
    println!("string: c = {:.3} m/s, rho = {:.4} g/m, tension = {:.2} N", c, rho * 1e3, ten);
    let e0 = ten / 2.0 * H * H * (1.0 / A + 1.0 / (L - A));
    println!("pluck: slopes {:.6} and {:.6}; energy (T/2) H^2 (1/a + 1/(L - a)) = {:.6} mJ", H / A, -H / (L - A), e0 * 1e3);
    let proj = |k: usize| {
        let g = |x: f64| f(x) * (kk(k) * x).sin();
        (simpson(&g, 0.0, A, 2000), simpson(&g, A, L, 2000))
    };
    for k in 1..=3 {
        let (p1, p2) = proj(k); println!("b_{}: closed form {:.9} mm, Simpson projection {:.9} mm", k, st.b[k] * 1e3, 2.0 / L * (p1 + p2) * 1e3);
    }
    let kn = st.kinks(T1, 0.0, L);
    println!("corners at 1 ms: {}", kn[1..kn.len() - 1].iter().map(|x| format!("{:.2} cm", x * 100.0)).collect::<Vec<_>>().join(", "));
    println!(" N | energy kept mJ | at 0 ms by quadrature | at 0.5 ms | at 1 ms | missing mJ");
    let (mut en, mut cons) = (vec![], vec![]);
    for &n in NS.iter() {
        let e = nsum((1..=n).map(|k| st.mode_e(k)));
        let q: Vec<f64> = [0.0, T1 / 2.0, T1].iter().map(|&t| st.trap_energy(n, t)).collect();
        cons.push(q.iter().map(|x| (x - e).abs()).fold(0.0, f64::max) / e);
        en.push(e);
        println!("{:3} | {:.10} | {:.10} | {:.10} | {:.10} | {:.6}", n, e * 1e3, q[0] * 1e3, q[1] * 1e3, q[2] * 1e3, (e0 - e) * 1e3);
    }
    let eall = nsum((1..=KMAX).map(|k| st.mode_e(k)));
    let tail = ten * L / 4.0 * (PI / L).powf(2.0) * (2.0 * H * L * L / (PI * PI * A * (L - A))).powf(2.0) / 100000.0;
    println!("modes 1 to 100000 carry {:.6} mJ; the rest at most {:.4} uJ", eall * 1e3, tail * 1e6);
    let fo: Vec<f64> = NS.iter().map(|&n| st.mode_e(n + 1) * 1e6).collect();
    println!("first omitted energy terms, modes 11, 41, 161: {} uJ", join(&fo, 4));
    println!(" N | RMS gap at 1 ms, quadrature um | by tail series um | difference energy at 1 ms mJ");
    let (mut gqv, mut gtv, mut dev) = (vec![], vec![], vec![]);
    for &n in NS.iter() {
        let gq = st.pieces(&|x: f64| (st.galerkin(x, T1, n).0 - st.u(x, T1)).powf(2.0), T1, 2000, 0.0, L);
        let gt = L / 2.0 * nsum((n + 1..=KMAX).map(|k| st.b[k].powf(2.0) * (st.om(k) * T1).cos().powf(2.0)));
        let de = st.pieces(&|x: f64| {
            let g = st.galerkin(x, T1, n);
            rho / 2.0 * (g.2 - st.ut(x, T1)).powf(2.0) + ten / 2.0 * (g.1 - st.ux(x, T1)).powf(2.0)
        }, T1, 2000, 0.0, L);
        gqv.push((gq / L).sqrt()); gtv.push((gt / L).sqrt()); dev.push(de);
        println!("{:3} | {:.6} | {:.6} | {:.6}", n, (gq / L).sqrt() * 1e6, (gt / L).sqrt() * 1e6, de * 1e3);
    }
    let ord: Vec<f64> = (0..2).map(|i| (gqv[i] / gqv[i + 1]).ln() / 4f64.ln()).collect();
    let ore: Vec<f64> = (0..2).map(|i| (dev[i] / dev[i + 1]).ln() / 4f64.ln() / 2.0).collect();
    println!("observed order in N: L2 gap {:.3}, {:.3}; energy-norm gap {:.3}, {:.3}", ord[0], ord[1], ore[0], ore[1]);
    let v = |x: f64| (PI * (x - 0.20) / 0.20).sin().powf(2.0); // test shape on 20 cm to 40 cm
    let vx = |x: f64| PI / 0.20 * (2.0 * PI * (x - 0.20) / 0.20).sin();
    let mom = |t: f64| st.pieces(&|x: f64| st.u(x, t) * v(x), t, 400, 0.20, 0.40);
    let stiff = c * c * st.pieces(&|x: f64| st.ux(x, T1) * vx(x), T1, 400, 0.20, 0.40);
    let mut res = vec![];
    for d in [2e-5, 1e-5] {
        let acc = (mom(T1 + d) - 2.0 * mom(T1) + mom(T1 - d)) / (d * d);
        res.push((acc + stiff).abs() / stiff.abs());
        println!("weak form at 1 ms, step {:.2} ms: (u, v)'' = {:.4} m^2/s^2, -c^2 (u_x, v_x) = {:.4} m^2/s^2, residual {:.4}%",
                 d * 1e3, acc, -stiff, res[res.len() - 1] * 100.0);
    }
    let (xf, tf) = (0.50, 0.5e-3);
    let vel: Vec<f64> = NS.iter().map(|&n| st.galerkin(xf, tf, n).2).collect();
    println!("finite speed: corner reaches 50 cm at {:.4} ms; at 0.5 ms d'Alembert u = {:.6} mm, u_t = {:.6} m/s",
             (xf - A) / c * 1e3, st.u(xf, tf) * 1e3, st.ut(xf, tf));
    println!("  Galerkin u_t there, N = 10, 40, 160: {} m/s", join(&vel, 6));
    let bend = |n: usize, w: &dyn Fn(usize) -> f64| L / 2.0 * nsum((1..=n).map(|k| kk(k).powf(4.0) * st.b[k].powf(2.0) * w(k)));
    let bw0: Vec<f64> = NS.iter().map(|&n| L / 2.0 * nsum((1..=n).map(|k| kk(k).powf(4.0) * st.b[k].powf(2.0)))).collect();
    let bw1: Vec<f64> = NS.iter().map(|&n| bend(n, &|k| (st.om(k) * T1).cos().powf(2.0))).collect();
    let bh: Vec<f64> = NS.iter().map(|&n| bend(n, &|k| (-2.0 * KAPPA * kk(k).powf(2.0) * 1.0).exp())).collect();
    println!("bending integral of u_N_xx^2, 1/m, N = 10, 40, 160: wave at 0 ms {}; wave at 1 ms {}; heat in copper after 1 s {}",
             join(&bw0, 6), join(&bw1, 6), join(&bh, 6));
    let sh = 0.5 * ten * L / 2.0;
    let je: Vec<f64> = NS.iter().map(|&n| nsum((1..=n).map(|k|
        sh * kk(k).powf(2.0) * (2.0 * H / (k as f64 * PI) * (1.0 - (kk(k) * A).cos())).powf(2.0)))).collect();
    println!("wrong: a 4 mm plateau from the bridge to 16 cm (not in H1_0), energy of N = 10, 40, 160: {} J", join(&je, 4));
    println!("wrong: expect order 2, gap at N = 160 would be {:.6} um, not {:.6} um", gqv[0] * 1e6 / 256.0, gqv[2] * 1e6);
    let xs: Vec<f64> = (0..14).map(|i| 0.05 * i as f64).collect();
    println!("chart, cm: {}", join(&xs.iter().map(|x| x * 100.0).collect::<Vec<_>>(), 0));
    println!("chart, d'Alembert at 1 ms, mm: {}", join(&xs.iter().map(|&x| st.u(x, T1) * 1e3).collect::<Vec<_>>(), 3));
    println!("chart, Galerkin N = 10 at 1 ms, mm: {}", join(&xs.iter().map(|&x| st.galerkin(x, T1, 10).0 * 1e3).collect::<Vec<_>>(), 3));
    assert!((1..=3).all(|k| { let (p1, p2) = proj(k); (b_closed(k) - 2.0 / L * p1 - 2.0 / L * p2).abs() < 1e-9 * H }), "projection");
    assert!(cons.iter().cloned().fold(0.0, f64::max) < 1e-12, "each Galerkin sum must keep its energy to rounding");
    assert!(0.0 < e0 - eall && e0 - eall < tail, "modes must carry the pluck's energy");
    assert!(gqv.iter().zip(&gtv).all(|(q, t)| (q - t).abs() < 1e-4 * t), "L2 gap: quadrature against tail series");
    assert!(dev.iter().zip(&en).all(|(d, e)| (d - (e0 - e)).abs() < 1e-4 * (e0 - e)), "difference keeps its starting energy");
    assert!(ord.iter().all(|&o| 1.4 < o && o < 1.6) && ore.iter().all(|&o| 0.4 < o && o < 0.6), "observed orders 1.5 and 0.5");
    assert!(res[1] < 1e-3 && 3.5 < res[0] / res[1] && res[0] / res[1] < 4.5, "weak-form residual must fall as step^2");
    assert!(st.ut(xf, tf).abs() < 1e-15 && vel[2].abs() < vel[0].abs(), "the limit is still before the corner arrives");
    assert!(bw0[2] > 3.0 * bw0[1] && 3.0 * bw0[1] > 9.0 * bw0[0] && bh[2] < 1.01 * bh[1], "the wave never smooths; heat does");
    assert!(je[2] > 3.0 * je[1] && 3.0 * je[1] > 9.0 * je[0], "a jump has no finite energy");
    println!("ALL CHECKS PASS");
}
