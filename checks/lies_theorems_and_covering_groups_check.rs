// Lie's theorems and covering groups -- the same check as the Python, in Rust.  No crates.
// Matrices are rows of complex numbers, a struct written here; exp is its power series.
use std::f64::consts::PI;

#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
fn c(re: f64, im: f64) -> C { C { re, im } }
fn cmul(a: C, b: C) -> C { c(a.re * b.re - a.im * b.im, a.re * b.im + a.im * b.re) }
type M = Vec<Vec<C>>;

fn mul(a: &M, b: &M) -> M {
    (0..a.len()).map(|i| (0..b[0].len()).map(|j| (0..b.len()).fold(c(0.0, 0.0), |s, k| {
        let p = cmul(a[i][k], b[k][j]); c(s.re + p.re, s.im + p.im) })).collect()).collect()
}
fn add(a: &M, b: &M, s: f64) -> M {
    a.iter().zip(b).map(|(r, q)| r.iter().zip(q).map(|(x, y)| c(x.re + s * y.re, x.im + s * y.im)).collect()).collect()
}
fn scale(a: &M, s: f64) -> M { a.iter().map(|r| r.iter().map(|x| c(s * x.re, s * x.im)).collect()).collect() }
fn eye(n: usize) -> M { (0..n).map(|i| (0..n).map(|j| c(if i == j { 1.0 } else { 0.0 }, 0.0)).collect()).collect() }
fn dag(a: &M) -> M {                          // conjugate transpose, the inverse in SU(2)
    (0..a.len()).map(|i| (0..a.len()).map(|j| c(a[j][i].re, -a[j][i].im)).collect()).collect()
}
fn gap(a: &M, b: &M) -> f64 {                 // Frobenius size of a - b
    let mut s = 0.0;
    for (r, q) in a.iter().zip(b) { for (x, y) in r.iter().zip(q) { s += (x.re - y.re).powi(2) + (x.im - y.im).powi(2) } }
    s.sqrt()
}
fn expm(a: &M) -> M {                         // I + a + a^2/2! + ..., 60 terms
    let (mut out, mut term) = (eye(a.len()), eye(a.len()));
    for k in 1..60 { term = scale(&mul(&term, a), 1.0 / k as f64); out = add(&out, &term, 1.0) }
    out
}
fn br(a: &M, b: &M) -> M { add(&mul(a, b), &mul(b, a), -1.0) }
fn power(a: &M, n: usize) -> M { let mut o = eye(a.len()); for _ in 0..n { o = mul(&o, a) } o }
fn f(v: f64, d: usize) -> String { format!("{:.*}", d, if v.abs() < 0.5 * 10f64.powi(-(d as i32)) { 0.0 } else { v }) }
fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }
fn cx(m: &[[f64; 3]; 3]) -> M { m.iter().map(|r| r.iter().map(|&x| c(x, 0.0)).collect()).collect() }
fn real(m: &M) -> [[f64; 3]; 3] { let mut r = [[0.0; 3]; 3]; for i in 0..3 { for j in 0..3 { r[i][j] = m[i][j].re } } r }

struct G { l: Vec<M>, x: Vec<M> }

fn table(g: &[M]) -> f64 {                    // largest miss in [g1,g2] = g3 and its cyclic turns
    (0..3).map(|k| gap(&br(&g[k], &g[(k + 1) % 3]), &g[(k + 2) % 3])).fold(0.0, f64::max)
}
fn ad(g: &G, u: &M) -> [[f64; 3]; 3] {        // the double cover: X_j-part of u X_k u^-1
    let mut r = [[0.0; 3]; 3];
    for j in 0..3 { for k in 0..3 {
        let p = mul(&g.x[j], &mul(u, &mul(&g.x[k], &dag(u))));
        r[j][k] = -2.0 * (p[0][0].re + p[1][1].re);
    } }
    r
}
fn preimage(g: &G, r: &[[f64; 3]; 3]) -> M {   // one of the two U over a rotation r, via its quaternion
    let t = r[0][0] + r[1][1] + r[2][2];
    let cs = [1.0 + t, 1.0 + 2.0 * r[0][0] - t, 1.0 + 2.0 * r[1][1] - t, 1.0 + 2.0 * r[2][2] - t];
    let mut m = 0;
    for i in 1..4 { if cs[i] > cs[m] { m = i } }
    let s = cs[m].sqrt() / 2.0;
    let p = [r[2][1] - r[1][2], r[0][2] - r[2][0], r[1][0] - r[0][1]];       // pairs with w
    let o = [r[0][1] + r[1][0], r[0][2] + r[2][0], r[1][2] + r[2][1]];       // xy, xz, yz
    let d = 4.0 * s;
    let q = match m {
        0 => [s, p[0] / d, p[1] / d, p[2] / d],
        1 => [p[0] / d, s, o[0] / d, o[1] / d],
        2 => [p[1] / d, o[0] / d, s, o[2] / d],
        _ => [p[2] / d, o[1] / d, o[2] / d, s],
    };
    add(&scale(&eye(2), q[0]), &add(&scale(&g.x[0], 2.0 * q[1]), &add(&scale(&g.x[1], 2.0 * q[2]), &scale(&g.x[2], 2.0 * q[3]), 1.0), 1.0), 1.0)
}
fn lift(g: &G, steps: usize, laps: usize) -> (M, f64, Vec<f64>) {   // follow the tilted loop into SU(2)
    let (mut u, mut worst, mut half) = (eye(2), 0.0f64, Vec::new());
    for s in 1..=steps * laps {
        let t = s as f64 / steps as f64;
        let a = expm(&scale(&g.l[0], (t % 1.0) * 50.0 * PI / 180.0));
        let r = real(&mul(&a, &mul(&expm(&scale(&g.l[2], 2.0 * PI * (t % 1.0))), &dag(&a))));
        let v = preimage(g, &r);
        u = if gap(&v, &u) < gap(&scale(&v, -1.0), &u) { v } else { scale(&v, -1.0) };   // the nearer sign
        worst = worst.max(gap(&cx(&ad(g, &u)), &cx(&r)));
        if s % 30 == 0 && s <= steps { half.push((u[0][0].re + u[1][1].re) / 2.0) }
    }
    (u, worst, half)
}
fn miss(n: usize, slope: f64) -> f64 { let v = n as f64 * slope; (v - v.round()).abs() }

fn main() {
    let z = c(0.0, 0.0);
    let l = vec![cx(&[[0.0, 0.0, 0.0], [0.0, 0.0, -1.0], [0.0, 1.0, 0.0]]), cx(&[[0.0, 0.0, 1.0], [0.0, 0.0, 0.0], [-1.0, 0.0, 0.0]]),
                 cx(&[[0.0, -1.0, 0.0], [1.0, 0.0, 0.0], [0.0, 0.0, 0.0]])];           // so(3): unit roll, pitch, yaw rates
    let x = vec![vec![vec![z, c(0.0, -0.5)], vec![c(0.0, -0.5), z]], vec![vec![z, c(-0.5, 0.0)], vec![c(0.5, 0.0), z]],
                 vec![vec![c(0.0, -0.5), z], vec![z, c(0.0, 0.5)]]];                     // su(2): -i/2 times the Pauli matrices
    let g = G { l, x };
    let (i2, i3, tau) = (eye(2), eye(3), 2.0 * PI);
    let neg = scale(&i2, -1.0);
    println!("so(3) brackets [Lx,Ly] = Lz and cyclic: {}", yn(table(&g.l) < 1e-12));
    println!("su(2) brackets [X1,X2] = X3 and cyclic: {}", yn(table(&g.x) < 1e-12));
    let h = 1e-4;
    let dgap = (0..3).map(|m| gap(&add(&cx(&ad(&g, &expm(&scale(&g.x[m], h)))), &cx(&ad(&g, &expm(&scale(&g.x[m], -h)))), -1.0),
                                  &scale(&g.l[m], 2.0 * h)) / (2.0 * h)).fold(0.0, f64::max);
    println!("derivative of the double cover sends X1, X2, X3 to Lx, Ly, Lz: {}", yn(dgap < 1e-8));
    let (z360, s360, s720) = (expm(&scale(&g.l[2], tau)), expm(&scale(&g.x[2], tau)), expm(&scale(&g.x[2], 2.0 * tau)));
    let closed = [(-PI).cos(), PI.cos()];
    println!("exp(360 deg yaw) in SO(3) is I: {}", yn(gap(&z360, &i3) < 1e-9));
    println!("exp(360 deg yaw) in SU(2), series: diagonal {}, {}", f(s360[0][0].re, 6), f(s360[1][1].re, 6));
    println!("exp(360 deg yaw) in SU(2), closed form e^(-i pi), e^(i pi): {}, {}", f(closed[0], 6), f(closed[1], 6));
    println!("exp(720 deg yaw) in SU(2) is I: {}", yn(gap(&s720, &i2) < 1e-9));
    let (u1, w1, half) = lift(&g, 360, 1);
    let (u2, w2, _) = lift(&g, 360, 2);
    println!("lift of the tilted 360 deg loop, 360 steps: ends at -I: {}", yn(gap(&u1, &neg) < 1e-9));
    println!("lift of the same loop run twice, 720 steps: ends at +I: {}", yn(gap(&u2, &i2) < 1e-9));
    println!("every lifted step lies over its rotation: {}", yn(w1.max(w2) < 1e-9));
    let ang: Vec<usize> = (30..=360).step_by(30).collect();
    let join = |v: Vec<String>| v.join(", ");
    println!("chart, turn angle in deg: 0, {}", join(ang.iter().map(|a| a.to_string()).collect()));
    println!("chart, half trace of the lift in SU(2): 1.000, {}", join(half.iter().map(|&v| f(v, 3)).collect()));
    println!("chart, (trace - 1)/2 of the turn in SO(3): 1.000, {}", join(ang.iter().map(|&a| f((a as f64 * PI / 180.0).cos(), 3)).collect()));
    println!("spin-1/2 guess Phi(exp(theta Lz)) = exp(theta X3): theta 0 gives +I, theta 360 deg gives {}, gap {}, same rotation I",
             if gap(&s360, &neg) < 1e-9 { "-I" } else { "?" }, f(gap(&i2, &s360), 6));
    let (a, b) = (scale(&g.l[1], 0.4), scale(&g.l[2], 1.2));
    let prod: Vec<f64> = [1usize, 10, 100].iter().map(|&n| gap(&power(&mul(&expm(&scale(&a, 1.0 / n as f64)), &expm(&scale(&b, 1.0 / n as f64))), n),
                                                         &expm(&add(&a, &b, 1.0)))).collect();
    println!("Lie product formula, pitch 0.4, yaw 1.2: gap N = 1 {}, N = 10 {}, N = 100 {}", f(prod[0], 6), f(prod[1], 6), f(prod[2], 6));
    let comm: Vec<f64> = [10usize, 100].iter().map(|&n| {
        let (ea, eb) = (expm(&scale(&a, 1.0 / n as f64)), expm(&scale(&b, 1.0 / n as f64)));
        gap(&power(&mul(&mul(&ea, &eb), &mul(&dag(&ea), &dag(&eb))), n * n), &expm(&br(&a, &b)))
    }).collect();
    println!("commutator formula, same rates: gap N = 10 {}, N = 100 {}", f(comm[0], 6), f(comm[1], 6));
    let r2 = 2f64.sqrt();
    let (mut best, mut rec) = (1.0, Vec::new());
    for n in 1..=1000 { if miss(n, r2) < best - 1e-12 { best = miss(n, r2); rec.push(n) } }
    let mut pell = vec![1usize, 2];
    while 2 * pell[pell.len() - 1] + pell[pell.len() - 2] <= 1000 { let k = pell.len(); pell.push(2 * pell[k - 1] + pell[k - 2]) }
    println!("slope sqrt 2 on the motor torus, record returns by search, n <= 1000: {:?}", rec);
    println!("the same list from the Pell rule q -> 2q + q_prev: {}", yn(rec == pell));
    println!("miss at each record, in turns: {}", join(rec.iter().map(|&n| f(miss(n, r2), 6)).collect()));
    println!("miss at each record, in degrees: {}", join(rec.iter().map(|&n| f(360.0 * miss(n, r2), 3)).collect()));
    println!("n times miss at n = 985: {}; 1/(2 sqrt 2) = {}", f(985.0 * miss(985, r2), 6), f(1.0 / (2.0 * r2), 6));
    println!("slope 3/2 closes exactly at n = 2: {}", yn(miss(2, 1.5) == 0.0));
    assert!(table(&g.l) < 1e-12 && table(&g.x) < 1e-12);                 // one bracket table, two algebras
    assert!(dgap < 1e-8);                                                // the double cover's derivative matches them
    assert!(gap(&s360, &neg) < 1e-9 && (closed[0] - s360[0][0].re).abs() < 1e-9 && gap(&z360, &i3) < 1e-9);
    assert!(gap(&u1, &neg) < 1e-9 && gap(&u2, &i2) < 1e-9);               // lifting road, from rotations alone
    assert!(half.iter().zip(&ang).all(|(v, &a)| (v - (a as f64 * PI / 360.0).cos()).abs() < 1e-9));
    assert!(8.0 < prod[1] / prod[2] && prod[1] / prod[2] < 12.0 && 8.0 < comm[0] / comm[1] && comm[0] / comm[1] < 12.0);
    assert!(rec == pell && (985.0 * miss(985, r2) - 1.0 / (2.0 * r2)).abs() < 1e-3);
    println!("ALL CHECKS PASS");
}
