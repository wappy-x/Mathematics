use std::f64::consts::PI;
const TURN: f64 = 2.0 * PI;
#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
impl C {
    fn mul(self, o: C) -> C { C { re: self.re * o.re - self.im * o.im, im: self.re * o.im + self.im * o.re } }
    fn add(self, o: C) -> C { C { re: self.re + o.re, im: self.im + o.im } }
    fn conj(self) -> C { C { re: self.re, im: -self.im } }
}
fn c(re: f64, im: f64) -> C { C { re, im } }
fn p(ph: f64, th: f64) -> [f64; 3] { [ph.sin() * th.cos(), ph.sin() * th.sin(), ph.cos()] } // point on the unit globe: ph down from the North Pole, th east
fn dot(a: [f64; 3], b: [f64; 3]) -> f64 { a[0] * b[0] + a[1] * b[1] + a[2] * b[2] }
fn chern_by_integral(density: &dyn Fn(f64, f64) -> f64, n: usize) -> f64 { // midpoint rule for (1/2pi) times the integral of F
    let (mut s, dph, dth) = (0.0, PI / n as f64, TURN / (2 * n) as f64);
    for i in 0..n { for j in 0..2 * n {
        s += density((i as f64 + 0.5) * dph, (j as f64 + 0.5) * dth) * dph * dth;
    } }
    s / TURN
}
fn chern_by_lattice(state: &dyn Fn(f64, f64) -> Vec<C>, n: usize) -> f64 { // overlaps round each grid square: no connection, no gauge
    let (mut s, dph, dth) = (0.0, PI / n as f64, TURN / (2 * n) as f64);
    for i in 0..n { for j in 0..2 * n {
        let cs: Vec<Vec<C>> = [(i, j), (i + 1, j), (i + 1, j + 1), (i, j + 1)].iter()
            .map(|&(a, b)| state(a as f64 * dph, b as f64 * dth)).collect();
        let mut lp = c(1.0, 0.0);
        for k in 0..4 {
            let mut ov = c(0.0, 0.0);
            for (x, y) in cs[k].iter().zip(cs[(k + 1) % 4].iter()) { ov = ov.add(x.conj().mul(*y)); }
            lp = lp.mul(ov);
        }
        s += lp.im.atan2(lp.re);
    } }
    s / TURN + 0.0
}
fn winding(angle: &dyn Fn(f64) -> f64, m: usize) -> f64 { // whole turns made by an angle carried once round the equator
    let (mut tot, mut prev) = (0.0, angle(0.0));
    for k in 1..=m {
        let cur = angle(TURN * k as f64 / m as f64);
        tot += (cur - prev + PI).rem_euclid(TURN) - PI;
        prev = cur;
    }
    tot / TURN
}
fn spin_half(ph: f64, th: f64) -> Vec<C> { vec![c((ph / 2.0).cos(), 0.0), c(th.cos() * (ph / 2.0).sin(), th.sin() * (ph / 2.0).sin())] }
fn level_frame(ph: f64, th: f64) -> Vec<C> { // (e_phi + i e_theta)/sqrt 2: a level frame as one complex vector
    let ep = [ph.cos() * th.cos(), ph.cos() * th.sin(), -ph.sin()];
    let et = [-th.sin(), th.cos(), 0.0];
    (0..3).map(|k| c(ep[k] / 2f64.sqrt(), et[k] / 2f64.sqrt())).collect()
}
fn stereo_frame(wr: f64, wi: f64) -> [f64; 3] { // d/d(Re w) of the inverse stereographic chart from the South Pole
    let d = 1.0 + wr.hypot(wi).powf(2.0);
    [2.0 / d - 4.0 * wr.powf(2.0) / d.powf(2.0), -4.0 * wr * wi / d.powf(2.0), -4.0 * wr / d.powf(2.0)]
}
fn clutch_tangent(th: f64) -> f64 { // angle from the north-chart frame to the south-chart frame on the equator
    let q = p(PI / 2.0, th);
    let (a, b0) = (stereo_frame(q[0], q[1]), stereo_frame(q[0], -q[1]));
    let b = [b0[0], -b0[1], -b0[2]]; // the south chart is the north chart after (x, y, z) -> (x, -y, -z)
    let cr = [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]];
    dot(cr, q).atan2(dot(a, b))
}
fn b_form(ph: f64, th: f64) -> [f64; 2] { // global 1-form b = z(x dy - y dx) + x(y dz - z dy), times 1/2; parts (b_ph, b_th)
    let [x, y, z] = p(ph, th);
    let vs = [[ph.cos() * th.cos(), ph.cos() * th.sin(), -ph.sin()], [-ph.sin() * th.sin(), ph.sin() * th.cos(), 0.0]];
    vs.map(|v| 0.5 * (z * (x * v[1] - y * v[0]) + x * (y * v[2] - z * v[1])))
}
fn deformed(ph: f64, th: f64) -> f64 { // F density of the monopole connection plus b: F + db
    let (h, bf) = (1e-5, b_form);
    let db = (bf(ph + h, th)[1] - bf(ph - h, th)[1] - bf(ph, th + h)[0] + bf(ph, th - h)[0]) / (2.0 * h);
    0.5 * ph.sin() + db
}
fn perms() -> Vec<[usize; 4]> { // the 24 orderings of 0, 1, 2, 3, in dictionary order
    (0..256).map(|k| [k / 64, k / 16 % 4, k / 4 % 4, k % 4]).filter(|s| (0..4).all(|i| (0..i).all(|j| s[i] != s[j]))).collect()
}
fn sign(s: &[usize; 4]) -> f64 { if (0..4).map(|i| (0..i).filter(|&j| s[j] > s[i]).count()).sum::<usize>() % 2 == 1 { -1.0 } else { 1.0 } }
fn top_form(r: &Vec<Vec<Vec<Vec<f64>>>>, pf: bool) -> f64 { // e1234 coefficient of Pf(Omega) (pf true) or of tr(Omega ^ Omega)
    let mut tot = 0.0;
    for q in perms() { let [a, b, c, d] = q;
        let t = if pf {
            perms().iter().map(|s| sign(s) * r[s[0]][s[1]][a][b] * r[s[2]][s[3]][c][d]).sum::<f64>() / 8.0
        } else {
            (0..16).map(|k| r[k / 4][k % 4][a][b] * r[k % 4][k / 4][c][d]).sum::<f64>()
        };
        tot += sign(&q) * t / 4.0;
    }
    tot + 0.0
}
fn pf4(m: &[[i64; 4]; 4]) -> i64 { m[0][1] * m[2][3] - m[0][2] * m[1][3] + m[0][3] * m[1][2] }

fn main() {
    println!("part 1: the monopole (Hopf) line bundle over the globe");
    let f = |ph: f64, _th: f64| 0.5 * ph.sin();
    let (c20, c40) = (chern_by_integral(&f, 20), chern_by_integral(&f, 40));
    println!("c1 by integrating F/2pi: 20 x 40 grid {:.9}; 40 x 80 grid {:.9}", c20, c40);
    println!("error ratio, coarse over fine: {:.4}", (c20 - 1.0) / (c40 - 1.0));
    let (cap, south) = (0.5 * (1.0 - 40f64.to_radians().cos()), 0.5 * (1.0 + 40f64.to_radians().cos()));
    println!("north gauge round 50N: {:.6} turn; south gauge: {:.6} turn; sum {:.6}", cap, south, cap + south);
    let (c_wind, c_lat) = (winding(&|th| th, 720), chern_by_lattice(&spin_half, 6));
    println!("c1 from the clutching angle at the equator: {:.6}; from spin-half overlaps, 6 x 12 grid: {:.12}", c_wind, c_lat);
    let bx = (30f64.to_radians().cos() - 40f64.to_radians().cos()) * PI / 6.0;
    println!("survey box: area {:.0} km2, rim {:.0} km; camera turn {:.4} deg; spin-half phase {:.4} deg", bx * 6371f64.powf(2.0),
        6371.0 * (PI / 9.0 + PI / 6.0 * (0.5 + 40f64.to_radians().sin())), bx.to_degrees(), (bx / 2.0).to_degrees());
    println!("part 2: the tangent bundle (the camera's level frames)");
    let (e_wind, e_lat) = (winding(&clutch_tangent, 720), chern_by_lattice(&level_frame, 6));
    let e_int = chern_by_integral(&|ph: f64, _th: f64| ph.sin(), 40);
    println!("Euler number from the clutching between stereographic frames: {:.6}; from level-frame overlaps, 6 x 12 grid: {:.12}", e_wind, e_lat);
    println!("Euler number from K dA / 2pi, 40 x 80 grid: {:.9}", e_int);
    println!("part 3: a different connection on the monopole bundle");
    let (mph, mth) = (35f64.to_radians(), (-15f64).to_radians());
    println!("F density at 55N 15W: old {:.6}, new {:.6}", f(mph, mth), deformed(mph, mth));
    let (d20, d40) = (chern_by_integral(&deformed, 20), chern_by_integral(&deformed, 40));
    println!("c1 of the new connection: 20 x 40 grid {:.9}; 40 x 80 grid {:.9}", d20, d40);
    println!("part 4: invariant polynomials");
    let x = [[c(0.0, 0.3), c(0.2, 0.1)], [c(-0.2, 0.1), c(0.0, -0.7)]];
    let g = [[c(0.6, 0.0), c(0.0, 0.8)], [c(0.0, 0.8), c(0.6, 0.0)]]; // unitary, so g^-1 is its conjugate transpose
    let gi = [[g[0][0].conj(), g[1][0].conj()], [g[0][1].conj(), g[1][1].conj()]];
    let mul = |a: [[C; 2]; 2], b: [[C; 2]; 2]| -> [[C; 2]; 2] {
        let e = |i: usize, j: usize| c(0.0, 0.0).add(a[i][0].mul(b[0][j])).add(a[i][1].mul(b[1][j]));
        [[e(0, 0), e(0, 1)], [e(1, 0), e(1, 1)]]
    };
    let y = mul(gi, mul(x, g));
    let mut cs = vec![];
    for (nm, m) in [("F", x), ("g^-1 F g", y)] {
        let det = m[0][0].mul(m[1][1]).re - m[0][1].mul(m[1][0]).re;
        cs.push((-(m[0][0].add(m[1][1])).im / TURN, -det / TURN.powf(2.0)));
        let l = cs[cs.len() - 1];
        println!("{}: c1 part {:.6}, c2 part {:.6}, top-left entry {:.6}i", nm, l.0, l.1, m[0][0].im);
    }
    let w: [[i64; 4]; 4] = [[0, 1, 2, 3], [-1, 0, 4, 5], [-2, -4, 0, 6], [-3, -5, -6, 0]];
    let mut wr = w;
    for i in 0..4 { for j in 0..4 { if (i == 0) != (j == 0) { wr[i][j] = -w[i][j]; } } }
    println!("Pfaffian {}, after a reflection {}; Pfaffian squared {}", pf4(&w), pf4(&wr), pf4(&w).pow(2));
    println!("part 5: the round 4-sphere, radius 1");
    let dl = |a: usize, b: usize| if a == b { 1.0 } else { 0.0 };
    let r: Vec<Vec<Vec<Vec<f64>>>> = (0..4).map(|a| (0..4).map(|b| (0..4).map(|c| (0..4)
        .map(|d| dl(a, c) * dl(b, d) - dl(a, d) * dl(b, c)).collect()).collect()).collect()).collect();
    let (pf_c, tr_c) = (top_form(&r, true), top_form(&r, false));
    let vol = |n: usize| TURN * (1..=3).map(|k| (0..n).map(|i| ((i as f64 + 0.5) * PI / n as f64).sin()
        .powf(k as f64)).sum::<f64>() * PI / n as f64).product::<f64>();
    let (v20, v40) = (vol(20), vol(40));
    let rm2: f64 = (0..256).map(|k| r[k / 64][k / 16 % 4][k / 4 % 4][k % 4].powf(2.0)).sum();
    let ric: Vec<Vec<f64>> = (0..4).map(|a| (0..4).map(|b| (0..4).map(|c| r[c][a][c][b]).sum()).collect()).collect();
    let ric2: f64 = (0..16).map(|k| ric[k / 4][k % 4].powf(2.0)).sum();
    let sc: f64 = (0..4).map(|a| ric[a][a]).sum();
    let (chi_pf, chi_gbc) = (pf_c * v40 / TURN.powf(2.0), (rm2 - 4.0 * ric2 + sc.powf(2.0)) * v40 / (32.0 * PI.powf(2.0)));
    let comb = |n: i64, k: i64| (0..k).fold(1i64, |acc, i| acc * (n - i) / (i + 1));
    let chi_cells: i64 = (0..5).map(|k| (-1i64).pow(k as u32) * comb(6, k + 1)).sum();
    println!("Pfaffian of curvature: {:.6} e1234; trace of Omega^Omega: {:.6} e1234", pf_c, tr_c);
    println!("volume: 20 grid {:.9}; 40 grid {:.9}; exact 8pi^2/3 {:.9}", v20, v40, 8.0 * PI.powf(2.0) / 3.0);
    println!("|Rm|^2 {:.0}, |Ric|^2 {:.0}, S^2 {:.0}; p1 from the trace: {:.6}", rm2, ric2, sc.powf(2.0), -tr_c * v40 / (8.0 * PI.powf(2.0)) + 0.0);
    println!("chi: from the Pfaffian {:.6}; from 4D Gauss-Bonnet-Chern {:.6}; from cells {}", chi_pf, chi_gbc, chi_cells);
    println!("part 6: real line bundles over the circle");
    let mob = [1i32, -1]; // transition signs on the two overlaps of two arcs covering the circle
    for (nm, t) in [("band", [1, 1]), ("Mobius", mob), ("Mobius squared", mob.map(|a| a * a))] {
        let hol = t[0] * t[1];
        println!("{}: section returns {:+}, w1 = {}, curvature 0, two-sided copies {}", nm, hol, (1 - hol) / 2, if hol == 1 { 2 } else { 1 });
    }
    println!("what breaks");
    println!("north gauge alone round 89.9S: {:.6} turn hidden at the pole", 0.5 * (1.0 - 179.9f64.to_radians().cos()));
    println!("F without the 1/2pi: {:.6}; level frames on a 1 x 2 grid: {:.6}", c40 * TURN, chern_by_lattice(&level_frame, 1));
    assert!((c40 - 1.0).abs() < 1e-3 && (c20 - 1.0).abs() > (c40 - 1.0).abs());
    assert!(c_wind.round() == 1.0 && c_lat.round() == 1.0 && (c_lat - 1.0).abs() < 1e-9);
    assert!(e_wind.round() == 2.0 && e_lat.round() == 2.0 && (e_int - 2.0).abs() < 1e-3);
    let [px, py, pz] = p(mph, mth);
    assert!((d40 - 1.0).abs() < 1e-3 && (deformed(mph, mth) - f(mph, mth) * (1.0 + px * px - 2.0 * py * py + pz * pz)).abs() < 1e-6);
    assert!((cs[0].0 - cs[1].0).abs() < 1e-12 && (cs[0].1 - cs[1].1).abs() < 1e-12 && (x[0][0].im - y[0][0].im).abs() > 0.1);
    assert!((pf4(&w).pow(2) as f64) == perms().iter().map(|s| sign(s) * (0..4).map(|i| w[i][s[i]] as f64).product::<f64>()).sum::<f64>());
    assert!((pf_c - 3.0).abs() < 1e-12 && (chi_pf - 2.0).abs() < 1e-3 && (chi_gbc - chi_cells as f64).abs() < 1e-3 && (ric2 - 36.0).abs() < 1e-12 && (sc - 12.0).abs() < 1e-12);
    println!("ALL CHECKS PASS");
}
