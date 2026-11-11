// LQG on the balancing pendulum -- the same check as lqg_and_the_separation_principle_check.py.
// Standard library only, no crates.  Regulator and estimator designed apart, then joined.
// Compile: rustc --edition 2021 -O lqg_and_the_separation_principle_check.rs -o /tmp/lqg_check
type Mat = Vec<Vec<f64>>;
const G0: f64 = 9.81; const L: f64 = 9.81 / 16.0; const H: f64 = 0.01;   // g/l = 16; tick s
const SD: f64 = 1.0 * L; const SV: f64 = 0.005;                 // gust m/s^2, encoder noise rad
const PI: f64 = std::f64::consts::PI;
fn mm(x: &Mat, y: &Mat) -> Mat {
    (0..x.len()).map(|i| (0..y[0].len()).map(|j| (0..y.len()).map(|k| x[i][k] * y[k][j]).sum()).collect()).collect()
}
fn tr(x: &Mat) -> Mat { (0..x[0].len()).map(|j| x.iter().map(|r| r[j]).collect()).collect() }
fn ad(x: &Mat, y: &Mat, s: f64) -> Mat {
    x.iter().zip(y).map(|(p, q)| p.iter().zip(q).map(|(a, b)| a + s * b).collect()).collect()
}
fn eye(n: usize) -> Mat { (0..n).map(|i| (0..n).map(|j| if i == j { 1.0 } else { 0.0 }).collect()).collect() }
fn sc(x: &Mat, s: f64) -> Mat { x.iter().map(|r| r.iter().map(|v| s * v).collect()).collect() }
struct Plant { a: Mat, b: Mat, c: Mat, q: Mat, r: f64 }
fn lqr(p: &Plant) -> (Mat, Mat, f64) {                          // regulator Riccati recursion
    let (mut pm, mut k, mut s) = (p.q.clone(), vec![vec![0.0; 2]], 0.0);
    for _ in 0..5000 {
        s = p.r + mm(&mm(&tr(&p.b), &pm), &p.b)[0][0]; k = sc(&mm(&mm(&tr(&p.b), &pm), &p.a), 1.0 / s);
        pm = ad(&p.q, &mm(&mm(&tr(&p.a), &pm), &ad(&p.a, &mm(&p.b, &k), -1.0)), 1.0);
    }
    (k, pm, s)
}
fn kalman(p: &Plant, sd: f64, sv: f64) -> (Mat, Mat) {          // filter Riccati recursion
    let wn = sc(&mm(&p.b, &tr(&p.b)), sd * sd);
    let (mut s, mut m, mut sf) = (wn.clone(), vec![], vec![]);
    for _ in 0..5000 {
        m = sc(&mm(&s, &tr(&p.c)), 1.0 / (s[0][0] + sv * sv));
        sf = ad(&s, &mm(&m, &mm(&p.c, &s)), -1.0);               // error covariance after correction
        s = ad(&mm(&mm(&p.a, &sf), &tr(&p.a)), &wn, 1.0);
    }
    (m, sf)
}
fn charpoly(f: &Mat) -> Vec<f64> {                              // Faddeev-LeVerrier
    let n = f.len(); let mut mk = eye(n); let mut c = vec![1.0];
    for k in 1..=n {
        let am = mm(f, &mk); let ck = -(0..n).map(|i| am[i][i]).sum::<f64>() / k as f64;
        c.push(ck); mk = ad(&am, &eye(n), ck);
    }
    c
}
fn stable(mut c: Vec<f64>) -> bool {                            // Schur-Cohn-Jury test
    while c.len() > 1 {
        let k = c[c.len() - 1] / c[0];
        if k.abs() >= 1.0 { return false; }
        c = (0..c.len() - 1).map(|i| c[i] - k * c[c.len() - 1 - i]).collect();
    }
    true
}
// state (x, z), z = prediction; plant receives kg * u;  u = -K (z + Mu (y - C z)),  y = C x + v
fn lp(p: &Plant, k: &Mat, m: &Mat, kg: f64, mu: &Mat) -> (Mat, Mat, Vec<f64>, f64) {
    let (a, b, c) = (&p.a, &p.b, &p.c);
    let hx = sc(&mm(k, &mm(mu, c)), -1.0); let hz = sc(&mm(k, &ad(&eye(2), &mm(mu, c), -1.0)), -1.0);
    let hv = -mm(k, mu)[0][0];
    let am = mm(a, m); let amc = mm(&am, c);
    let top = ad(a, &mm(b, &hx), kg); let tz = sc(&mm(b, &hz), kg);
    let bot = ad(&amc, &mm(b, &hx), 1.0); let bz = ad(&ad(a, &amc, -1.0), &mm(b, &hz), 1.0);
    let mut f: Mat = (0..2).map(|i| [top[i].clone(), tz[i].clone()].concat()).collect();
    f.extend((0..2).map(|i| [bot[i].clone(), bz[i].clone()].concat()));
    let g = vec![vec![b[0][0], kg * b[0][0] * hv], vec![b[1][0], kg * b[1][0] * hv],
                 vec![0.0, am[0][0] + b[0][0] * hv], vec![0.0, am[1][0] + b[1][0] * hv]];
    (f, g, [hx[0].clone(), hz[0].clone()].concat(), hv)
}
fn raw(p: &Plant, k: &Mat) -> (Mat, Mat, Vec<f64>, f64) {       // angle straight in, rate by differencing
    let (k1, k2) = (k[0][0], k[0][1] / H);
    let top = ad(&p.a, &sc(&mm(&p.b, &vec![vec![k1 + k2, 0.0]]), -1.0), 1.0);
    let mut f: Mat = (0..2).map(|i| vec![top[i][0], top[i][1], p.b[i][0] * k2]).collect();
    f.push(vec![1.0, 0.0, 0.0]);
    let g = vec![vec![p.b[0][0], -p.b[0][0] * (k1 + k2)], vec![p.b[1][0], -p.b[1][0] * (k1 + k2)], vec![0.0, 1.0]];
    (f, g, vec![-(k1 + k2), 0.0, k2], -(k1 + k2))
}
fn cost(p: &Plant, l: &(Mat, Mat, Vec<f64>, f64), sd: f64, sv: f64) -> (f64, Mat, f64) {
    let (f, g, hh, hv) = l;                                     // steady covariance S = F S F' + G N G'
    let gng = mm(&mm(g, &vec![vec![sd * sd, 0.0], vec![0.0, sv * sv]]), &tr(g));
    let mut s = vec![vec![0.0; f.len()]; f.len()];
    for _ in 0..4000 { s = ad(&mm(&mm(f, &s), &tr(f)), &gng, 1.0); }
    let hm = vec![hh.clone()]; let u2 = mm(&mm(&hm, &s), &tr(&hm))[0][0] + hv * hv * sv * sv;
    (p.q[0][0] * s[0][0] + p.q[1][1] * s[1][1] + p.r * u2, s, u2)
}
fn margin(ok: &dyn Fn(f64) -> bool, mut lo: f64, mut hi: f64) -> f64 {
    for _ in 0..60 { let mid = 0.5 * (lo + hi); if ok(mid) == ok(lo) { lo = mid } else { hi = mid } }
    0.5 * (lo + hi)
}
fn run(f: &Mat) -> f64 {                                        // size after 10 s / size before
    let mut x = vec![0.0; f.len()]; x[0] = 0.01;
    for _ in 0..1000 { x = (0..x.len()).map(|i| (0..x.len()).map(|j| f[i][j] * x[j]).sum()).collect(); }
    x.iter().map(|v| v * v).sum::<f64>().sqrt() / 0.01
}
fn fm(v: &[f64], p: usize) -> String { v.iter().map(|x| format!("{:10.*}", p, x)).collect::<Vec<_>>().join(" ") }
fn main() {
    let (a0, w) = (G0 / L, (G0 / L).sqrt()); let (ch, sh) = ((w * H).cosh(), (w * H).sinh());
    let p = Plant { a: vec![vec![ch, sh / w], vec![w * sh, ch]], b: vec![vec![-(ch - 1.0) / (a0 * L)], vec![-sh / (w * L)]],
                    c: vec![vec![1.0, 0.0]], q: vec![vec![100.0, 0.0], vec![0.0, 0.0]], r: 0.04 };
    let ((k, pm, s), (m, sf)) = (lqr(&p), kalman(&p, SD, SV));
    let lq = lp(&p, &k, &m, 1.0, &m);
    let abk = ad(&p.a, &mm(&p.b, &k), -1.0);
    let (pr, pe, p4) = (charpoly(&abk), charpoly(&mm(&p.a, &ad(&eye(2), &mm(&m, &p.c), -1.0))), charpoly(&lq.0));
    let prod: Vec<f64> = (0..5).map(|kk: usize| (0..3).filter(|&i| kk >= i && kk - i <= 2).map(|i| pr[i] * pe[kk - i]).sum()).collect();
    let j_full = SD * SD * mm(&mm(&tr(&p.b), &pm), &p.b)[0][0];
    let j_sep = j_full + s * mm(&mm(&k, &sf), &tr(&k))[0][0];
    let (j_cov, sc_, u2) = cost(&p, &lq, SD, SV);
    let mut st: u64 = 20251025;                                 // splitmix64, then Box-Muller
    let mut unif = || {
        st = st.wrapping_add(0x9E3779B97F4A7C15); let mut z = st;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9); z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        (((z ^ (z >> 31)) >> 11) as f64 + 0.5) / 2f64.powi(53)
    };
    let (f, g, hh, hv) = &lq; let (mut xi, mut acc) = (vec![0.0; 4], 0.0);
    for _ in 0..200000 {
        let d = SD * (-2.0 * unif().ln()).sqrt() * (2.0 * PI * unif()).cos();
        let v = SV * (-2.0 * unif().ln()).sqrt() * (2.0 * PI * unif()).cos();
        let u = (0..4).map(|j| hh[j] * xi[j]).sum::<f64>() + hv * v;
        acc += p.q[0][0] * xi[0] * xi[0] + p.q[1][1] * xi[1] * xi[1] + p.r * u * u;
        xi = (0..4).map(|i| (0..4).map(|j| f[i][j] * xi[j]).sum::<f64>() + g[i][0] * d + g[i][1] * v).collect();
    }
    let j_sim = acc / 200000.0;
    let (m_ltr, _) = kalman(&p, 100.0, SV);                      // recovery: filter for 100 m/s^2 gusts
    let margins = |mx: &Mat| -> Vec<f64> {
        [0.01, 100.0].iter().map(|&e| margin(&|kg| stable(charpoly(&lp(&p, &k, mx, kg, mx).0)), 1.0, e)).collect()
    };
    let mut gm: Vec<f64> = [0.01, 100.0].iter().map(|&e| margin(&|kg| stable(charpoly(&ad(&p.a, &mm(&p.b, &k), -kg))), 1.0, e)).collect();
    gm.extend(margins(&m)); gm.extend(margins(&m_ltr));
    let grow = [run(&ad(&p.a, &mm(&p.b, &k), -3.0)), run(&lp(&p, &k, &m, 3.0, &m).0), run(&lp(&p, &k, &m, 2.5, &m).0)];
    let zero = vec![vec![0.0], vec![0.0]];
    let wrong = [cost(&p, &lp(&p, &sc(&k, 0.8), &m, 1.0, &m), SD, SV).0, cost(&p, &lp(&p, &sc(&k, 1.2), &m, 1.0, &m), SD, SV).0,
                 cost(&p, &lp(&p, &k, &m, 1.0, &zero), SD, SV).0, cost(&p, &raw(&p, &k), SD, SV).0,
                 cost(&p, &lp(&p, &k, &m_ltr, 1.0, &m_ltr), SD, SV).0];
    let mut tries = vec![];
    for (sd, sv) in [(SD, SV / 10.0), (SD * 10.0, SV)] {
        let (mt, _) = kalman(&p, sd, sv);
        let mut t = vec![1000.0 * cost(&p, &lp(&p, &k, &mt, 1.0, &mt), sd, sv).0]; t.extend(margins(&mt)); tries.push(t);
    }
    let zs = |c: &Vec<f64>| { let re = -c[1] / 2.0; vec![re, (c[2] - re * re).sqrt(), c[2].sqrt()] };
    let rows: Vec<(&str, Vec<f64>)> = vec![
        ("open-loop pole sqrt(g/l), rad/s", vec![w]), ("A row 1, row 2", [p.a[0].clone(), p.a[1].clone()].concat()),
        ("B", tr(&p.b)[0].clone()), ("LQR gain K, per rad and rad/s", k[0].clone()), ("Kalman gain M", tr(&m)[0].clone()),
        ("char poly, regulator A - BK", pr.clone()), ("char poly, estimator A(I - MC)", pe.clone()),
        ("their product", prod.clone()), ("char poly, whole 4-state loop", p4.clone()),
        ("regulator poles re, im, size", zs(&pr)), ("estimator poles re, im, size", zs(&pe)),
        ("cost per tick x1000: see all", vec![1000.0 * j_full]), ("  separation formula", vec![1000.0 * j_sep]),
        ("  loop covariance", vec![1000.0 * j_cov]), ("  simulated, 200000 ticks", vec![1000.0 * j_sim]),
        ("rms angle, estimate error (deg)", vec![sc_[0][0].sqrt() * 180.0 / PI, sf[0][0].sqrt() * 180.0 / PI]),
        ("rms encoder noise deg, motor", vec![SV * 180.0 / PI, u2.sqrt()]),
        ("gain margin LQR low, high", gm[0..2].to_vec()), ("gain margin LQG low, high", gm[2..4].to_vec()),
        ("gain margin LQG recovered", gm[4..6].to_vec()), ("10 s at 3x: LQR, LQG; 2.5x: LQG", grow.to_vec()),
        ("wrong x1000: 0.8K, 1.2K, no corr.", wrong[..3].iter().map(|x| 1000.0 * x).collect()),
        ("wrong x1000: raw, recovery filter", wrong[3..].iter().map(|x| 1000.0 * x).collect()),
        ("try encoder /10: cost, margins", tries[0].clone()), ("try gusts x10: cost, margins", tries[1].clone()),
    ];
    for (name, v) in &rows { println!("{:<34}{}", name, fm(v, 4)); }
    println!("chart t(s)   true LQG   estimate   LQR (deg)");
    let (mut x, mut z, mut xr) = (vec![0.05, 0.0], vec![vec![0.0], vec![0.0]], vec![0.05, 0.0]);
    for kk in 0..121 {
        let xh = ad(&z, &sc(&m, x[0] - z[0][0]), 1.0);          // correct by the reading (noise-free run)
        if kk % 10 == 0 { println!("chart {:5.2} {}", kk as f64 * H, fm(&[x[0] * 180.0 / PI, xh[0][0] * 180.0 / PI, xr[0] * 180.0 / PI], 3)); }
        let u = -mm(&k, &xh)[0][0]; let ur = -(k[0][0] * xr[0] + k[0][1] * xr[1]);
        x = (0..2).map(|i| p.a[i][0] * x[0] + p.a[i][1] * x[1] + p.b[i][0] * u).collect();
        xr = (0..2).map(|i| p.a[i][0] * xr[0] + p.a[i][1] * xr[1] + p.b[i][0] * ur).collect();
        z = ad(&mm(&p.a, &xh), &sc(&p.b, u), 1.0);
    }
    assert!(prod.iter().zip(&p4).map(|(a, b)| (a - b).abs()).fold(0.0, f64::max) < 1e-9, "separation: loop poles");
    assert!((j_sep - j_cov).abs() < 1e-9 * j_cov, "separation cost formula vs loop covariance");
    assert!((j_sim - j_cov).abs() < 0.03 * j_cov, "simulation within 3% of the covariance cost");
    assert!(wrong.iter().all(|&c| c > j_cov), "every departure costs more");
    assert!(grow[0] < 1.0 && grow[1] > 1.0 && grow[2] < 1.0 && 2.5 < gm[3] && gm[3] < 3.0, "running agrees with the test");
    assert!(gm[2] > gm[0] && gm[3] < gm[1] && gm[4] < gm[2], "LQG margins narrower; recovery widens them");
    println!("ALL CHECKS PASS");
}
