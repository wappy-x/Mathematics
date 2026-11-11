// Spin one-half -- the check behind the card.  Rust std only, no crates.
// Silver atoms through Stern-Gerlach magnets.  The chance of "up" along a
// tilted magnet comes three ways: the half-angle formula, the eigenvector of
// a 2x2 matrix found from its quadratic, and the column (1, 0) turned 60 deg by
// the power series of the matrix exponential.  The turning in time comes three
// ways: the closed form, RK4 on Schrodinger's equation, and the same series.
use std::f64::consts::PI;
use std::ops::{Add, Mul};

#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }                       // a complex number, written out
fn c(re: f64, im: f64) -> C { C { re, im } }
impl Add for C { type Output = C; fn add(self, o: C) -> C { c(self.re + o.re, self.im + o.im) } }
impl Mul for C { type Output = C; fn mul(self, o: C) -> C { c(self.re * o.re - self.im * o.im, self.re * o.im + self.im * o.re) } }
impl C { fn conj(self) -> C { c(self.re, -self.im) } fn abs(self) -> f64 { (self.re * self.re + self.im * self.im).sqrt() } }

type M = [[C; 2]; 2];
type V = [C; 2];
const Z: C = C { re: 0.0, im: 0.0 };
const O: C = C { re: 1.0, im: 0.0 };
const I2: M = [[O, Z], [Z, O]];
const SX: M = [[Z, O], [O, Z]];
const SY: M = [[Z, C { re: 0.0, im: -1.0 }], [C { re: 0.0, im: 1.0 }, Z]];
const SZ: M = [[O, Z], [Z, C { re: -1.0, im: 0.0 }]];
fn mul(a: &M, b: &M) -> M { let mut r = [[Z; 2]; 2]; for i in 0..2 { for j in 0..2 { r[i][j] = a[i][0] * b[0][j] + a[i][1] * b[1][j]; } } r }
fn comb(a: C, x: &M, b: C, y: &M) -> M { let mut r = [[Z; 2]; 2]; for i in 0..2 { for j in 0..2 { r[i][j] = a * x[i][j] + b * y[i][j]; } } r }
fn gap(a: &M, b: &M) -> f64 { let mut g = 0.0f64; for i in 0..2 { for j in 0..2 { g = g.max((a[i][j] + c(-1.0, 0.0) * b[i][j]).abs()); } } g }
fn sig(n: [f64; 3]) -> M { comb(O, &comb(c(n[0], 0.0), &SX, c(n[1], 0.0), &SY), c(n[2], 0.0), &SZ) }
fn app(a: &M, v: V) -> V { [a[0][0] * v[0] + a[0][1] * v[1], a[1][0] * v[0] + a[1][1] * v[1]] }
fn prob(u: V, v: V) -> f64 { let s = u[0].conj() * v[0] + u[1].conj() * v[1]; s.abs().powi(2) }
fn axis(deg: f64) -> [f64; 3] { let t = deg * PI / 180.0; [t.sin(), 0.0, t.cos()] }
fn re(x: f64) -> C { c(x, 0.0) }

fn up_vector(m: &M) -> V {      // road 2: eigenvector for the + root of lambda^2 = p^2 + |q|^2
    let (p, q) = (m[0][0].re, m[0][1]);
    let lam = (p * p + q.abs().powi(2)).sqrt();
    if q.abs() < 1e-15 { return if p > 0.0 { [O, Z] } else { [Z, O] }; }
    let v = [q, re(lam - p)]; let s = (v[0].abs().powi(2) + v[1].abs().powi(2)).sqrt();
    [v[0] * re(1.0 / s), v[1] * re(1.0 / s)]
}

struct SplitMix64 { s: u64 }    // a small seeded generator, written out
impl SplitMix64 {
    fn next(&mut self) -> f64 {
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
}

fn u(theta: f64, n: [f64; 3]) -> M { comb(re((theta / 2.0).cos()), &I2, c(0.0, -(theta / 2.0).sin()), &sig(n)) }
fn u_series(theta: f64, n: [f64; 3]) -> M {   // road 3: sum of (-i theta n.s / 2)^k / k!
    let x = comb(c(0.0, -0.5 * theta), &sig(n), Z, &I2);
    let (mut term, mut tot) = (I2, I2);
    for k in 1..40 { term = comb(re(1.0 / k as f64), &mul(&term, &x), Z, &I2); tot = comb(O, &tot, O, &term); }
    tot
}

fn main() {
    let h = 6.62607015e-34; let hbar = h / (2.0 * PI);   // Planck constant, exact in SI, J s
    let mub = 9.2740100657e-24;                          // Bohr magneton, J/T (CODATA 2022)
    let g = 2.00231930436092;                            // electron g factor, size (CODATA 2022)
    let m_ag = 107.8682 * 1.66053906892e-27;             // one silver atom, kg (IUPAC, CODATA)
    let gam_e = 28024.9513861;                           // electron gyromagnetic ratio / 2 pi, MHz/T (CODATA 2022)
    let up_z: V = [O, Z];
    let r2 = 1.0 / 2f64.sqrt(); let up_x: V = [re(r2), re(r2)];
    assert!(gap(&mul(&SX, &SY), &comb(c(0.0, 1.0), &SZ, Z, &I2)) < 1e-15);
    for s in [SX, SY, SZ, sig(axis(60.0))] { assert!(gap(&mul(&s, &s), &I2) < 1e-15); }
    println!("sigma_x sigma_y = i sigma_z, and every n.sigma squares to I: yes");

    let (dbdz, l, v) = (1000.0, 0.035, 500.0);
    let f = 0.5 * g * mub * dbdz; let a = f / m_ag; let tm = l / v;
    let z1 = 0.5 * a * tm * tm;
    println!("moment {:.4} x 10^-24 J/T, atom {:.4} x 10^-25 kg, hbar {:.9} x 10^-34 J s", 0.5 * g * mub * 1e24, m_ag * 1e25, hbar * 1e34);
    println!("force on one atom      {:.4} x 10^-21 N", f * 1e21);
    println!("acceleration           {:.1} m/s^2, time in magnet {:.1} us", a, tm * 1e6);
    println!("each beam moves        {:.4} mm, gap between spots {:.4} mm", z1 * 1e3, 2.0 * z1 * 1e3);
    let (mut zs, mut vs, kk) = (0.0f64, 0.0f64, 1000.0); // road 2 for the drift: step the flight (half kick, drift, half kick)
    for _ in 0..1000 { vs += a * tm / kk / 2.0; zs += vs * tm / kk; vs += a * tm / kk / 2.0; }
    assert!((zs - z1).abs() < 1e-9 * z1);

    let p_formula = (60.0 * PI / 360.0).cos().powi(2);
    let p_eig = prob(up_vector(&sig(axis(60.0))), up_z);
    let p_turn = app(&u_series(PI / 3.0, [0.0, 1.0, 0.0]), up_z)[0].abs().powi(2); // road 3: turn (1, 0) by 60 deg about y
    let (mut rng, n) = (SplitMix64 { s: 2026 }, 100000usize); // not a road: atoms drawn with that chance show a real count's scatter
    let hits = (0..n).filter(|_| rng.next() < p_eig).count();
    println!("P(up) tilt 60 deg      formula {:.6}  eigenvector {:.6}  turned {:.6}  simulated {:.5}", p_formula, p_eig, p_turn, hits as f64 / n as f64);
    println!("of 10000 atoms         {:.0} up, {:.0} down", 10000.0 * p_formula, 10000.0 * (1.0 - p_formula));
    println!("overlap at 60 deg      {:.6}, axis (n_x, n_z) = ({:.6}, {:.6})", p_eig.sqrt(), axis(60.0)[0], axis(60.0)[2]);
    assert!((p_formula - p_eig).abs() < 1e-12);
    assert!((p_formula - p_turn).abs() < 1e-12);
    let nf = n as f64;
    assert!((hits as f64 - nf * p_formula).abs() < 4.0 * (nf * p_formula * (1.0 - p_formula)).sqrt());
    for d in [0.0, 90.0, 120.0, 180.0] {
        println!("P(up) tilt {:3} deg     {:.6}", d as i32, prob(up_vector(&sig(axis(d))), up_z));
    }

    let p1 = prob(up_vector(&sig(axis(90.0))), up_z); let p2 = prob(up_z, up_vector(&sig(axis(90.0))));
    println!("z -> x -> z            10000 -> {:.0} kept -> {:.0} up, {:.0} down", 10000.0 * p1, 10000.0 * p1 * p2, 10000.0 * p1 * (1.0 - p2));
    assert!((p2 - 0.5).abs() < 1e-12);

    let b = 0.5;
    let w = g * mub * b / hbar;
    println!("Larmor rate at {:.3} T {:.4} x 10^9 rad/s; f = w/2pi = {:.4} GHz, period {:.4} ps", b, w / 1e9, w / 2.0 / PI / 1e9, 2.0 * PI / w * 1e12);
    assert!((w / (2.0 * PI * b) / 1e6 - gam_e).abs() < 1e-3); // against CODATA's gamma_e / 2 pi
    println!("turns in the magnet    {:.0};  beam moves in 72 ps  {:.1} nm", w / 2.0 / PI * tm, v * 72e-12 * 1e9);
    let (mut psi, dt, n_steps) = (up_x, 0.008, 9000);
    let hm = comb(c(0.0, -0.5 * w * 1e-12), &SZ, Z, &I2);
    let fv = |y: V| app(&hm, y);
    let step = |p: V, k: V, s: f64| [p[0] + re(s) * k[0], p[1] + re(s) * k[1]];
    let (mut row_cf, mut row_rk, mut row_z) = (Vec::new(), Vec::new(), Vec::new());
    let tilt = up_vector(&sig(axis(60.0)));
    for k in 0..=n_steps {
        if k % 1000 == 0 {
            let t = k as f64 * dt * 1e-12;
            row_cf.push((w * t / 2.0).cos().powi(2)); row_rk.push(prob(up_x, psi));
            assert!(gap(&u(w * t, [0.0, 0.0, 1.0]), &u_series(w * t, [0.0, 0.0, 1.0])) < 1e-12);
            row_z.push(prob(up_z, app(&u(w * t, [0.0, 0.0, 1.0]), tilt)));   // start tilted 60 deg
        }
        let k1 = fv(psi); let k2 = fv(step(psi, k1, dt / 2.0));
        let k3 = fv(step(psi, k2, dt / 2.0)); let k4 = fv(step(psi, k3, dt));
        for i in 0..2 { psi[i] = psi[i] + re(dt / 6.0) * (k1[i] + re(2.0) * k2[i] + re(2.0) * k3[i] + k4[i]); }
    }
    assert!(row_cf.iter().zip(&row_rk).all(|(x, y)| (x - y).abs() < 1e-8));
    assert!(row_z.iter().all(|x| (x - p_formula).abs() < 1e-12));          // z-chance never moves
    let ts: Vec<String> = (0..10).map(|i| format!("{:5}", 8 * i)).collect();
    println!("chart, t (ps)          {}", ts.join(" "));
    println!("chart, phase wt (deg)  {}", (0..10).map(|i| format!("{:5.0}", w * 8e-12 * i as f64 * 180.0 / PI)).collect::<Vec<_>>().join(" "));
    let fmt = |r: &Vec<f64>| r.iter().map(|x| format!("{:5.3}", x)).collect::<Vec<_>>().join(" ");
    println!("chart, P(+x) formula   {}", fmt(&row_cf));
    println!("chart, P(+x) RK4       {}", fmt(&row_rk));
    println!("chart, P(+z) from 60   {}", fmt(&row_z));
    println!("one full turn          U(2 pi) = {:.6} I, U(4 pi) = {:.6} I", u(2.0 * PI, [0.0, 0.0, 1.0])[0][0].re, u(4.0 * PI, [0.0, 0.0, 1.0])[0][0].re);
    assert!(gap(&u_series(2.0 * PI, axis(60.0)), &comb(re(-1.0), &I2, Z, &I2)) < 1e-12);

    let f_true = w / 2.0 / PI;
    println!("wrong: cos^2(60 deg)   {:.6}   (right {:.6})", (60.0 * PI / 180.0).cos().powi(2), p_formula);
    println!("wrong: amplitudes      {:.6} total chance", (PI / 6.0).cos() + (PI / 6.0).sin());
    println!("wrong: g left out      {:.4} GHz   (right {:.4})", mub * b / h / 1e9, f_true / 1e9);
    println!("wrong: z remembered    {:.0} up, 0 down   (right {:.0}, {:.0})", 10000.0 * p1, 10000.0 * p1 * p2, 10000.0 * p1 * (1.0 - p2));
    let fe = g * mub * 50e-6 / h;                        // weak field: electron and nucleus lock into spin 1, rate halves
    println!("Earth 50 uT, electron  {:.4} MHz, silver atom weak field ~{:.4} MHz", fe / 1e6, fe / 2e6);
    println!("ESR at 9.5 GHz needs   {:.4} T;  at 0.339 T  {:.4} GHz", h * 9.5e9 / (g * mub), g * mub * 0.339 / h / 1e9);
    println!("MRI proton at 1.5 T    {:.4} MHz", 42.577478461 * 1.5);
    println!("ALL CHECKS PASS");
}
