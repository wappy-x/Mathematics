// Multistep methods: the same check as the Python, in Rust.  No crates.
// A satellite on an orbit 400 km up at perigee and 1,600 km up at apogee, stepped by
// AB4, by AB4 + AM4 as predictor-corrector (PECE) and by RK4.  Weights come from exact
// fractions, written out below as a small struct.
use std::f64::consts::PI;

#[derive(Clone, Copy, PartialEq, Debug)]
struct Fr { n: i64, d: i64 }
fn gcd(a: i64, b: i64) -> i64 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn fr(n: i64, d: i64) -> Fr { let g = gcd(n, d) * d.signum(); Fr { n: n / g, d: d / g } }
impl std::ops::Add for Fr { type Output = Fr; fn add(self, o: Fr) -> Fr { fr(self.n * o.d + o.n * self.d, self.d * o.d) } }
impl std::ops::Sub for Fr { type Output = Fr; fn sub(self, o: Fr) -> Fr { fr(self.n * o.d - o.n * self.d, self.d * o.d) } }
impl std::ops::Mul for Fr { type Output = Fr; fn mul(self, o: Fr) -> Fr { fr(self.n * o.n, self.d * o.d) } }
impl std::ops::Div for Fr { type Output = Fr; fn div(self, o: Fr) -> Fr { fr(self.n * o.d, self.d * o.n) } }
impl Fr {
    fn f(self) -> f64 { self.n as f64 / self.d as f64 }
    fn s(self) -> String { if self.d == 1 { format!("{}", self.n) } else { format!("{}/{}", self.n, self.d) } }
    fn pow(self, k: usize) -> Fr { (0..k).fold(fr(1, 1), |a, _| a * self) }
}
fn e(x: f64) -> String { format!("{:.2e}", x) }
fn basis(nodes: &[i64], j: usize) -> Vec<Fr> {      // Lagrange basis l_j(s), low to high
    let mut c = vec![fr(1, 1)];
    for (m, &cm) in nodes.iter().enumerate() {
        if m == j { continue; }
        let d = fr(nodes[j] - cm, 1);
        c = (0..=c.len()).map(|k| {
            let a = if k > 0 { c[k - 1] / d } else { fr(0, 1) };
            if k < c.len() { a - c[k] * fr(cm, 1) / d } else { a } }).collect();
    }
    c
}
fn adams(nodes: &[i64]) -> Vec<Fr> {                 // area under l_j for s from 0 to 1
    (0..nodes.len()).map(|j| basis(nodes, j).iter().enumerate().fold(fr(0, 1), |s, (k, &a)| s + a / fr(k as i64 + 1, 1))).collect()
}
fn bdf(nodes: &[i64]) -> Vec<Fr> {                   // slope of l_j at s = 1
    (0..nodes.len()).map(|j| basis(nodes, j).iter().enumerate().skip(1).fold(fr(0, 1), |s, (k, &a)| s + fr(k as i64, 1) * a)).collect()
}
fn errconst(w: &[Fr], nodes: &[i64], p: usize) -> Fr {
    let fact = (2..=p as i64).product::<i64>();
    w.iter().zip(nodes).fold(fr(1, (p as i64 + 1) * fact), |s, (&b, &c)| s - b * fr(c, 1).pow(p) / fr(fact, 1))
}
fn roots2(a: f64, b: f64, c: f64) -> (f64, f64) { let d = (b * b - 4.0 * a * c).sqrt(); ((-b - d) / (2.0 * a), (-b + d) / (2.0 * a)) }

const MU: f64 = 398600.4418; const RP: f64 = 6778.0; const RA: f64 = 7978.0;
type S = [f64; 4];
fn f(u: &S, nev: &mut usize) -> S {
    *nev += 1; let r = (u[0] * u[0] + u[1] * u[1]).sqrt(); let k = -MU / (r * r * r);
    [u[2], u[3], k * u[0], k * u[1]]
}
fn lin(u: &S, h: f64, ws: &[f64], fs: &[S]) -> S {
    let mut o = [0.0; 4];
    for i in 0..4 { o[i] = u[i] + h * ws.iter().zip(fs).fold(0.0, |s, (w, g)| s + w * g[i]); }
    o
}
fn rk4(u: &S, h: f64, nev: &mut usize) -> S {
    let k1 = f(u, nev); let k2 = f(&lin(u, h / 2.0, &[1.0], &[k1]), nev);
    let k3 = f(&lin(u, h / 2.0, &[1.0], &[k2]), nev); let k4 = f(&lin(u, h, &[1.0], &[k3]), nev);
    lin(u, h / 6.0, &[1.0, 2.0, 2.0, 1.0], &[k1, k2, k3, k4])
}
fn euler(u: &S, h: f64, nev: &mut usize) -> S { let g = f(u, nev); lin(u, h, &[1.0], &[g]) }
fn miss(u: &S, c: &S) -> f64 { ((u[0] - c[0]) * (u[0] - c[0]) + (u[1] - c[1]) * (u[1] - c[1])).sqrt() }

struct Orbit { t: f64, u0: S, am: Vec<f64>, goal: S }      // goal: where the run should end
impl Orbit {
    fn run(&self, n: usize, how: &str, start: fn(&S, f64, &mut usize) -> S, wab: &[f64], upto: Option<usize>) -> (f64, usize) {
        let mut nev = 0; let h = self.t / n as f64; let mut u = self.u0;
        if how == "rk4" { for _ in 0..n { u = rk4(&u, h, &mut nev); } return (miss(&u, &self.goal), nev); }
        let k = if how == "bad" { 2 } else { wab.len() };
        let mut us = vec![u];
        for _ in 0..k - 1 { let nx = start(us.last().unwrap(), h, &mut nev); us.push(nx); }
        let mut fs: Vec<S> = us.iter().map(|w| f(w, &mut nev)).collect(); fs.reverse();
        let mut ys: Vec<S> = us.iter().rev().cloned().collect(); u = *us.last().unwrap();
        for _ in k - 1..upto.unwrap_or(n) {
            let mut p = [0.0; 4];
            if how == "bad" {                    // y+ = -4 y_n + 5 y_(n-1) + h (4 f_n + 2 f_(n-1))
                for i in 0..4 { p[i] = -4.0 * ys[0][i] + 5.0 * ys[1][i] + h * (4.0 * fs[0][i] + 2.0 * fs[1][i]); }
            } else {
                p = lin(&u, h, wab, &fs);
                if how == "pece" { let fp = f(&p, &mut nev); p = lin(&u, h, &self.am, &[fp, fs[0], fs[1], fs[2]]); }
            }
            fs.pop(); fs.insert(0, f(&p, &mut nev)); ys = vec![p, ys[0]]; u = p;
        }
        (miss(&u, &self.goal), nev)
    }
}

fn main() {
    let (abn, amn): ([i64; 4], [i64; 4]) = ([0, -1, -2, -3], [1, 0, -1, -2]);
    let (ab, am, b2, ab6) = (adams(&abn), adams(&amn), bdf(&[1, 0, -1]), adams(&[0, -1, -2, -3, -4, -5]));
    let x = |w: &Vec<Fr>, m: i64| format!("[{}]", w.iter().map(|&v| (v * fr(m, 1)).s()).collect::<Vec<_>>().join(", "));
    println!("AB4 weights x24: {}  AM4 weights x24: {}", x(&ab, 24), x(&am, 24));
    println!("BDF2 coefficients of y_(n+1), y_n, y_(n-1): {}", b2.iter().map(|v| v.s()).collect::<Vec<_>>().join(", "));
    assert_eq!(ab, vec![fr(55, 24), fr(-59, 24), fr(37, 24), fr(-9, 24)]);
    assert_eq!(am, vec![fr(9, 24), fr(19, 24), fr(-5, 24), fr(1, 24)]);
    for (nodes, w) in [(&abn, &ab), (&amn, &am)] {   // road 2: exact for t^0 .. t^3
        for k in 0..4 { assert_eq!(w.iter().zip(nodes.iter()).fold(fr(0, 1), |s, (&b, &c)| s + b * fr(c, 1).pow(k)), fr(1, k as i64 + 1)); }
    }
    let (cab, cam) = (errconst(&ab, &abn, 4), errconst(&am, &amn, 4));
    println!("error constants: AB4 {}, AM4 {}, size ratio {:.2}; Milne factor {}", cab.s(), cam.s(), (cab / (fr(0, 1) - cam)).f(), (fr(0, 1) - cam / (cab - cam)).s());
    assert_eq!((cab, cam), (fr(251, 720), fr(-19, 720)));
    let (rb, ru) = (roots2(1.5, -2.0, 0.5), roots2(1.0, 4.0, -5.0));
    println!("roots of rho: Adams z^4 - z^3: 0, 0, 0, 1; BDF2: {:.4}, {:.4}; unstable 2-step: {:.4}, {:.4}", rb.0, rb.1, ru.0, ru.1);
    assert!((rb.0 - 1.0 / 3.0).abs() < 1e-15);
    assert!((ru.0 + 5.0).abs() < 1e-15);

    let a = (RP + RA) / 2.0; let v = (MU * (2.0 / RP - 1.0 / a)).sqrt(); let t = 2.0 * PI * (a * a * a / MU).sqrt();
    println!("orbit: perigee speed {:.4} km/s, period {:.1} s = {:.2} min", v, t, t / 60.0);
    let fl = |w: &Vec<Fr>| w.iter().map(|q| q.f()).collect::<Vec<f64>>();
    let (abf, ab6f) = (fl(&ab), fl(&ab6));
    let o = Orbit { t, u0: [RP, 0.0, 0.0, v], am: fl(&am), goal: [RP, 0.0, 0.0, v] };
    println!(" steps   h (s)   AB4 miss km  evals  PECE miss km  evals   RK4 miss km  evals");
    let ns = [100usize, 200, 400, 800, 1600];
    let res: Vec<Vec<(f64, usize)>> = ns.iter().map(|&n| ["ab4", "pece", "rk4"].iter().map(|m| o.run(n, m, rk4, &abf, None)).collect()).collect();
    for (i, &n) in ns.iter().enumerate() {
        let cells: Vec<String> = res[i].iter().map(|(a, k)| format!("{:>11} {:6}", e(*a), k)).collect();
        println!("{:6} {:7.2}  {}", n, t / n as f64, cells.join("  "));
    }
    for (j, m) in ["AB4", "PECE", "RK4"].iter().enumerate() {
        let od: Vec<f64> = (0..4).map(|i| (res[i][j].0 / res[i + 1][j].0).log2()).collect();
        println!("observed order {:4}: {}   (theory 4)", m, od.iter().map(|q| format!("{:.2}", q)).collect::<Vec<_>>().join(", "));
        assert!((od[3] - 4.0).abs() < 0.25);
    }
    let (abm, pcm) = (res[2][0].0, res[2][1].0);
    println!("400 steps: AB4 misses by {:.1} m, PECE by {:.2} m, ratio {:.1}", abm * 1000.0, pcm * 1000.0, abm / pcm);
    assert!(abm / pcm > 10.0 && abm / pcm < 20.0);
    println!("order 4 predicts AB4 at 800 steps: {:.1} m / 16 = {:.2} m; measured {:.2} m", abm * 1000.0, abm * 1000.0 / 16.0, res[3][0].0 * 1000.0);
    let a6 = o.run(400, "ab6", rk4, &ab6f, None);
    println!("AB6 weights x1440: {}; 400 steps: miss {} km, {} evals", x(&ab6, 1440), e(a6.0), a6.1);
    assert!(a6.0 < abm / 100.0);
    println!("chart, log10 h: {}", ns.iter().rev().map(|&n| format!("{:.2}", (t / n as f64).log10())).collect::<Vec<_>>().join(" "));
    for (j, m) in ["AB4", "PECE", "RK4"].iter().enumerate() {
        println!("chart, log10 miss {}: {}", m, (0..5).rev().map(|i| format!("{:.2}", res[i][j].0.log10())).collect::<Vec<_>>().join(" "));
    }
    let fnn = [3200usize, 6400, 12800, 25600, 51200, 102400];   // finer steps, down to where rounding stops the fall
    let fine: Vec<Vec<f64>> = fnn.iter().map(|&n| { let r: Vec<f64> = ["ab4", "pece", "rk4"].iter().map(|m| o.run(n, m, rk4, &abf, None).0).collect();
        println!("finer, {:6} steps: AB4 {}, PECE {}, RK4 {} km", n, e(r[0]), e(r[1]), e(r[2])); r }).collect();
    assert!((0..3).all(|j| { let lo = fine.iter().map(|r| r[j]).fold(f64::MAX, f64::min); 1e-11 < lo && lo < fine[5][j] / 2.0 })); // rounding stops the fall

    // the picture: AB4's cubic through four stored slopes, with a step stretched to T/8
    let hh = t / 8.0; let mut pts = vec![o.u0]; let mut nev = 0;
    for _ in 0..16 { let mut u = *pts.last().unwrap(); for _ in 0..200 { u = rk4(&u, hh / 800.0, &mut nev); } pts.push(u); }
    let ap = ((pts[16][0] + RA) * (pts[16][0] + RA) + pts[16][1] * pts[16][1]).sqrt();
    println!("reference at half a period: {} km from apogee (Kepler: it is at apogee)", e(ap));
    assert!(ap < 1e-6);
    let vx: Vec<f64> = pts.iter().map(|p| p[2]).collect();
    let st = [vx[12], vx[8], vx[4], vx[0]];
    let cub: Vec<f64> = (0..17).map(|q| (0..4).fold(0.0, |s, j| s + basis(&abn, j).iter().enumerate()
        .fold(fr(0, 1), |a, (k, &c)| a + c * fr(q - 12, 4).pow(k)).f() * st[j])).collect();
    let row = |v: &Vec<f64>| v.iter().map(|z| format!("{:.2}", z)).collect::<Vec<_>>().join(" ");
    println!("chart, minutes: {}", (0..17).map(|q| format!("{:.1}", q as f64 * hh / 240.0)).collect::<Vec<_>>().join(" "));
    println!("chart, true vx km/s: {}", row(&vx));
    println!("chart, cubic km/s:   {}", row(&cub));
    let inc = hh * ab.iter().zip(st.iter()).fold(0.0, |s, (b, z)| s + b.f() * z);
    println!("stretched step: AB4 moves x by {:.1} km, the reference by {:.1} km", inc, pts[16][0] - pts[12][0]);
    for q in [0, 4, 8, 12] { assert!((cub[q] - vx[q]).abs() < 1e-9); }
    assert!((cub[16] - vx[16]).abs() > 1.0);

    // what breaks
    let mut r10 = o.u0;                      // reference at T/10: RK4 with 1,600 small steps
    for _ in 0..1600 { r10 = rk4(&r10, t / 16000.0, &mut nev); }
    let ob = Orbit { t, u0: o.u0, am: o.am.clone(), goal: r10 };
    for (n, at) in [(100usize, 10usize), (200, 20), (400, 40), (800, 80)] {
        println!("unstable 2-step, h = {:.2} s: miss after {:.1} s = {} km", t / n as f64, t * at as f64 / n as f64, e(ob.run(n, "bad", rk4, &abf, Some(at)).0));
    }
    assert!(ob.run(200, "bad", rk4, &abf, Some(20)).0 > 100.0 * ob.run(100, "bad", rk4, &abf, Some(10)).0);
    let eu: Vec<f64> = [400usize, 800].iter().map(|&n| o.run(n, "ab4", euler, &abf, None).0).collect();
    println!("AB4 started by Euler: 400 steps {} km, 800 steps {} km, order {:.2}", e(eu[0]), e(eu[1]), (eu[0] / eu[1]).log2());
    assert!(((eu[0] / eu[1]).log2() - 2.0).abs() < 0.3);
    println!("ALL CHECKS PASS");
}
