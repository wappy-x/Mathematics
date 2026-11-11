// Stability of a state-space model, the check behind the card.  std only.  Cart and pendulum upright,
// pole 0.613125 m so g/l = 9.81 / 0.613125 = 16 per s^2; x = (cart p m, speed v m/s, tilt th rad, rate w rad/s), u = cart
// acceleration m/s^2.  Roads: polynomial roots vs simulated growth; Lyapunov P by solve, hand formula and
// integral; sampled loop by trace and determinant vs powers; positive definite by minors vs Cholesky.
type M = Vec<Vec<f64>>;
fn mm(x: &M, y: &M) -> M { (0..x.len()).map(|i| (0..y[0].len()).map(|j| (0..y.len()).map(|k| x[i][k] * y[k][j]).sum()).collect()).collect() }
fn tr(x: &M) -> M { (0..x[0].len()).map(|j| (0..x.len()).map(|i| x[i][j]).collect()).collect() }
fn eye(n: usize) -> M { (0..n).map(|i| (0..n).map(|j| if i == j { 1.0 } else { 0.0 }).collect()).collect() }
fn add(x: &M, y: &M, c: f64) -> M { x.iter().zip(y).map(|(r, s)| r.iter().zip(s).map(|(a, b)| a + c * b).collect()).collect() }
fn m(rows: &[&[f64]]) -> M { rows.iter().map(|r| r.to_vec()).collect() }
fn f(x: f64, d: usize) -> String { let s = format!("{:.*}", d, x); if s.trim_start_matches('-').chars().all(|c| c == '0' || c == '.') { s.trim_start_matches('-').to_string() } else { s } }
fn fl(xs: &[f64], d: usize) -> String { xs.iter().map(|&x| f(x, d)).collect::<Vec<_>>().join(" ") }
fn tf(b: bool) -> &'static str { if b { "True" } else { "False" } }
fn expm(x: &M, t: f64) -> M {                         // e^(Xt): shrink t by halving, Taylor, square back up
    let mx = x.iter().flatten().fold(0.0f64, |a, b| a.max(b.abs()));
    let mut s = 0; while mx * t.abs() / 2f64.powi(s) > 0.1 { s += 1; }
    let y: M = x.iter().map(|r| r.iter().map(|a| a * t / 2f64.powi(s)).collect()).collect();
    let (mut e, mut tt) = (eye(x.len()), eye(x.len()));
    for k in 1..16 { tt = mm(&tt, &y).iter().map(|r| r.iter().map(|a| a / k as f64).collect()).collect(); e = add(&e, &tt, 1.0); }
    for _ in 0..s { e = mm(&e, &e); }
    e
}
fn solve(a: &M, y: &[f64]) -> (Option<Vec<f64>>, f64) {   // Gaussian elimination with row swaps; (x, det)
    let n = a.len(); let mut a: M = a.iter().zip(y).map(|(r, b)| { let mut r = r.clone(); r.push(*b); r }).collect(); let mut det = 1.0;
    for c in 0..n {
        let p = (c..n).fold(c, |p, i| if a[i][c].abs() > a[p][c].abs() { i } else { p });
        if a[p][c].abs() < 1e-12 { return (None, 0.0); }
        if p != c { a.swap(c, p); det = -det; }
        det *= a[c][c];
        for i in c + 1..n { let q = a[i][c] / a[c][c]; for j in 0..=n { a[i][j] -= q * a[c][j]; } }
    }
    let mut x = vec![0.0; n];
    for i in (0..n).rev() { x[i] = (a[i][n] - (i + 1..n).map(|j| a[i][j] * x[j]).sum::<f64>()) / a[i][i]; }
    (Some(x), det)
}
fn lyap(a: &M, q: &M, disc: bool) -> (Option<M>, f64) {  // A'P + PA = -Q, or sampled A'PA - P = -Q
    let n = a.len(); let ix: Vec<(usize, usize)> = (0..n * n).map(|t| (t / n, t % n)).collect();
    let d = |b: bool| if b { 1.0 } else { 0.0 };
    let mat: M = ix.iter().map(|&(i, j)| ix.iter().map(|&(k, l)| if disc { a[k][i] * a[l][j] - d(i == k && j == l) }
        else { a[k][i] * d(l == j) + d(i == k) * a[l][j] }).collect()).collect();
    let (x, det) = solve(&mat, &ix.iter().map(|&(i, j)| -q[i][j]).collect::<Vec<_>>());
    (x.map(|x| (0..n).map(|i| x[i * n..(i + 1) * n].to_vec()).collect()), det)
}
fn lyap_int(a: &M, t: f64, n: usize) -> M {            // Simpson's rule on e^(A't) I e^(At) over 0..T
    let h = t / n as f64; let e1 = expm(a, h); let mut e = eye(a.len()); let mut s = vec![vec![0.0; a.len()]; a.len()];
    for k in 0..=n { let w = if k == 0 || k == n { 1.0 } else if k % 2 == 1 { 4.0 } else { 2.0 }; s = add(&s, &mm(&tr(&e), &e), w * h / 3.0); e = mm(&e, &e1); }
    s
}
fn charpoly(a: &M) -> Vec<f64> {                       // Faddeev-LeVerrier: det(sI - A), highest power first
    let n = a.len(); let mut c = vec![1.0]; let mut mk = vec![vec![0.0; n]; n];
    for k in 1..=n { mk = add(&mm(a, &mk), &eye(n), *c.last().unwrap()); let am = mm(a, &mk); c.push(-(0..n).map(|i| am[i][i]).sum::<f64>() / k as f64); }
    c
}
#[derive(Clone, Copy)] struct C(f64, f64);
fn cm(a: C, b: C) -> C { C(a.0 * b.0 - a.1 * b.1, a.0 * b.1 + a.1 * b.0) }
fn cd(a: C, b: C) -> C { let d = b.0 * b.0 + b.1 * b.1; C((a.0 * b.0 + a.1 * b.1) / d, (a.1 * b.0 - a.0 * b.1) / d) }
fn roots(c: &[f64]) -> Vec<C> {                        // Durand-Kerner: all roots at once, complex
    let n = c.len() - 1; let mut z: Vec<C> = Vec::new(); let mut p = C(1.0, 0.0);
    for _ in 0..n { z.push(p); p = cm(p, C(0.4, 0.9)); }
    for _ in 0..3000 { for i in 0..n {
        let num = c.iter().fold(C(0.0, 0.0), |acc, &a| { let t = cm(acc, z[i]); C(t.0 + a, t.1) });
        let den = (0..n).filter(|&j| j != i).fold(C(1.0, 0.0), |acc, j| cm(acc, C(z[i].0 - z[j].0, z[i].1 - z[j].1)));
        let q = cd(num, den); z[i] = C(z[i].0 - q.0, z[i].1 - q.1);
    } }
    z.sort_by(|a, b| b.0.partial_cmp(&a.0).unwrap()); z
}
fn re(z: &[C]) -> Vec<f64> { z.iter().map(|w| w.0).collect() }
fn minors(p: &M) -> Vec<f64> { (1..=p.len()).map(|k| solve(&p[..k].iter().map(|r| r[..k].to_vec()).collect(), &vec![0.0; k]).1).collect() }
fn cholesky_ok(p: &M) -> bool {                        // P = L L' exists with positive pivots iff P > 0
    let n = p.len(); let mut l = vec![vec![0.0; n]; n];
    for i in 0..n { for j in 0..=i {
        let s = p[i][j] - (0..j).map(|k| l[i][k] * l[j][k]).sum::<f64>();
        if i == j && s <= 0.0 { return false; }
        l[i][j] = if i == j { s.sqrt() } else { s / l[j][j] };
    } }
    true
}
fn mdig(h: f64) -> M {                                 // held input: one e^() of the plant with its input column
    let g = expm(&m(&[&[0.0, 1.0, 0.0], &[16.0, 0.0, -1.0], &[0.0, 0.0, 0.0]]), h);
    (0..2).map(|i| (0..2).map(|j| g[i][j] + g[i][2] * [24.0, 6.0][j]).collect()).collect()
}
fn rho(a: &M) -> (f64, f64, f64) {                     // spectral radius of a 2x2 from trace and determinant
    let (t, d) = (a[0][0] + a[1][1], a[0][0] * a[1][1] - a[0][1] * a[1][0]); let disc = t * t - 4.0 * d;
    let r = if disc >= 0.0 { ((t + disc.sqrt()) / 2.0).abs().max(((t - disc.sqrt()) / 2.0).abs()) } else { d.sqrt() };
    (r, t, d)
}
fn rho_pow(a: &M, k: usize) -> f64 {                   // the same number from steps: growth of |M^j x| over j = k..2k
    let (mut x, mut s) = ([1.0f64, 1.0], 0.0);
    for j in 0..2 * k {
        let y = [a[0][0] * x[0] + a[0][1] * x[1], a[1][0] * x[0] + a[1][1] * x[1]]; let n = (y[0] * y[0] + y[1] * y[1]).sqrt();
        if j >= k { s += n.ln(); } x = [y[0] / n, y[1] / n];
    }
    2.718281828459045f64.powf(s / k as f64)
}
fn gap(a: &M, b: &M) -> f64 { a.iter().flatten().zip(b.iter().flatten()).fold(0.0, |g, (x, y)| g.max((x - y).abs())) }
fn main() {
    let a = m(&[&[0.0, 1.0, 0.0, 0.0], &[0.0; 4], &[0.0, 0.0, 0.0, 1.0], &[0.0, 0.0, 16.0, 0.0]]); let c = charpoly(&a); let lam = roots(&c);
    println!("open loop: det(sI - A) coefficients {} | eigenvalues {}", fl(&c, 1), fl(&re(&lam), 4));
    let th = |t: f64| expm(&a, t)[2][2];               // tilt in mrad, released at 1 mrad from rest
    println!("tilt from 1 mrad: at 1 s {} mrad; growth ln(th(3)/th(2)) = {} per s; doubling {} s; cart nudged to 0.1 m/s is at {} m after 10 s",
        f(th(1.0), 2), f((th(3.0) / th(2.0)).ln(), 4), f(2f64.ln() / 4.0, 4), f(0.1 * expm(&a, 10.0)[0][1], 4));
    let h = 0.01; let zd = roots(&charpoly(&expm(&a, h)));
    println!("sampled every 0.01 s: eigenvalues of e^(Ah) {} | e^(4h) = {}", fl(&re(&zd), 6), f(2.718281828459045f64.powf(4.0 * h), 6));
    let ac = m(&[&[0.0, 1.0], &[-8.0, -6.0]]); let (t2, d2) = (ac[0][0] + ac[1][1], ac[0][0] * ac[1][1] - ac[0][1] * ac[1][0]);
    println!("angle loop: trace {} det {} eigenvalues {} {}; feedback u = {} th + {} w", f(t2, 1), f(d2, 1), f((t2 + (t2 * t2 - 4.0 * d2).sqrt()) / 2.0, 1),
        f((t2 - (t2 * t2 - 4.0 * d2).sqrt()) / 2.0, 1), f(24.0 * 0.613125, 3), f(6.0 * 0.613125, 3));
    let p = lyap(&ac, &eye(2), false).0.unwrap(); let pi = lyap_int(&ac, 20.0, 4000); let (cc, dd) = (8.0, 6.0);  // hand: the three entry equations
    let hand = [cc * (1.0 + 1.0 / cc) / (2.0 * dd) + dd / (2.0 * cc), 1.0 / (2.0 * cc), (1.0 + 1.0 / cc) / (2.0 * dd)];
    println!("P11 P12 P22: solve {} | hand {} | integral {}", fl(&[p[0][0], p[0][1], p[1][1]], 6), fl(&hand, 6), fl(&[pi[0][0], pi[0][1], pi[1][1]], 6));
    println!("P leading minors {} | Cholesky {}", fl(&minors(&p), 7), tf(cholesky_ok(&p)));
    let v = |s: [f64; 2]| p[0][0] * s[0] * s[0] + 2.0 * p[0][1] * s[0] * s[1] + p[1][1] * s[1] * s[1];
    let x0 = [0.1, 0.0]; let lmax = (p[0][0] + p[1][1] + ((p[0][0] - p[1][1]).powi(2) + 4.0 * p[0][1] * p[0][1]).sqrt()) / 2.0;
    let vd: f64 = 2.0 * (0..2).map(|i| (0..2).map(|j| x0[i] * p[i][j] * (0..2).map(|k| ac[j][k] * x0[k]).sum::<f64>()).sum::<f64>()).sum::<f64>();
    println!("from th = 0.1 rad: V = {}, V' = 2 x'PAx = {}; largest eigenvalue of P {}, so V falls at least as e^(-{} t)", f(v(x0), 6), f(vd, 6), f(lmax, 4), f(1.0 / lmax, 4));
    let traj = |t: f64| { let e = expm(&ac, t); [e[0][0] * x0[0] + e[0][1] * x0[1], e[1][0] * x0[0] + e[1][1] * x0[1]] };
    let ks: Vec<f64> = (0..7).map(|k| 0.5 * k as f64).collect(); let ts: Vec<f64> = (0..11).map(|k| 0.1 * k as f64).collect();
    println!("chart, t s:        {}", fl(&ks, 1));
    println!("chart, V x 1000:   {}", fl(&ks.iter().map(|&t| 1000.0 * v(traj(t))).collect::<Vec<_>>(), 3));
    println!("chart, bound x1000 {}", fl(&ks.iter().map(|&t| 1000.0 * v(x0) * 2.718281828459045f64.powf(-t / lmax)).collect::<Vec<_>>(), 3));
    println!("chart, tilt mrad open   {}", fl(&ts.iter().map(|&t| th(t)).collect::<Vec<_>>(), 2));
    println!("chart, tilt mrad closed {}", fl(&ts.iter().map(|&t| 10.0 * traj(t)[0]).collect::<Vec<_>>(), 2));
    for (hh, lab) in [(0.01, "0.01"), (0.2, "0.2"), (0.5, "0.5")] {
        let (r, t, d) = rho(&mdig(hh));
        println!("digital angle loop, h = {} s: M {}; trace {} det {}; Jury |det| < 1 and |trace| < 1 + det: {}; radius {}, by powers {}",
            lab, fl(&mdig(hh).concat(), 4), f(t, 4), f(d, 4), tf(d.abs() < 1.0 && t.abs() < 1.0 + d), f(r, 4), f(rho_pow(&mdig(hh), 2000), 4));
    }
    let (mut lo, mut hi) = (0.2, 0.5);
    for _ in 0..60 { let mid = (lo + hi) / 2.0; if rho(&mdig(mid)).0 < 1.0 { lo = mid; } else { hi = mid; } }
    println!("slowest safe sampling: h = {} s, {} samples per s", f(lo, 4), f(1.0 / lo, 2));
    let m1 = mdig(0.01); let pd = lyap(&m1, &eye(2), true).0.unwrap(); let (mut s, mut mk) = (eye(2), eye(2));
    for _ in 0..3000 { mk = mm(&mk, &m1); s = add(&s, &mm(&tr(&mk), &mk), 1.0); }
    println!("sampled P x h, solve {} | by the series {}", fl(&[0.01 * pd[0][0], 0.01 * pd[0][1], 0.01 * pd[1][1]], 4), fl(&[0.01 * s[0][0], 0.01 * s[0][1], 0.01 * s[1][1]], 4));
    let fnl = |s: [f64; 2]| [s[1], 16.0 * s[0].sin() - (24.0 * s[0] + 6.0 * s[1]) * s[0].cos()];
    let falls = |th0: f64| {                           // RK4 on the curved pendulum for 5 s: V always falling? top tilt
        let (mut s, h) = ([th0, 0.0], 0.001); let (mut vv, mut ok, mut top) = (v(s), true, th0);
        for _ in 0..5000 {
            let k1 = fnl(s); let k2 = fnl([s[0] + h / 2.0 * k1[0], s[1] + h / 2.0 * k1[1]]); let k3 = fnl([s[0] + h / 2.0 * k2[0], s[1] + h / 2.0 * k2[1]]);
            let k4 = fnl([s[0] + h * k3[0], s[1] + h * k3[1]]); s = [0, 1].map(|i| s[i] + h / 6.0 * (k1[i] + 2.0 * k2[i] + 2.0 * k3[i] + k4[i]));
            ok = ok && v(s) < vv; vv = v(s); top = top.max(s[0].abs());
        }
        (ok, top, s[0])
    };
    for (th0, lab) in [(0.3, "0.3"), (0.9, "0.9"), (1.0, "1.0")] { let r = falls(th0); println!("curved pendulum from {} rad: V falls at every step {}; largest tilt {}, tilt at 5 s {} rad", lab, tf(r.0), f(r.1, 4), f(r.2, 4)); }
    let k = [-1.5, -3.125, -52.5 * 0.613125, -13.125 * 0.613125]; let bv = [0.0, 1.0, 0.0, -1.0 / 0.613125];
    let acl: M = (0..4).map(|i| (0..4).map(|j| a[i][j] - bv[i] * k[j]).collect()).collect();
    let cl = charpoly(&acl); let p4 = lyap(&acl, &eye(4), false).0.unwrap(); let p4i = lyap_int(&acl, 40.0, 8000);
    println!("full loop: coefficients {} | eigenvalues {}", fl(&cl, 4), fl(&re(&roots(&cl)), 4));
    println!("full loop P minors {} | Cholesky {} | solve vs integral, largest gap {}", fl(&minors(&p4), 3), tf(cholesky_ok(&p4)), f(gap(&p4, &p4i), 7));
    let (po, dopen) = lyap(&m(&[&[0.0, 1.0], &[16.0, 0.0]]), &eye(2), false); let flip = m(&[&[0.0, 1.0], &[-8.0, 6.0]]); let pf = lyap(&flip, &eye(2), false).0.unwrap();
    println!("wrong: Lyapunov on the open angle loop: solution {}, system determinant {}", if po.is_none() { "None" } else { "found" }, f(dopen, 4));
    println!("wrong: rate gain sign flipped, eigenvalues {} P {}", fl(&re(&roots(&charpoly(&flip))), 1), fl(&[pf[0][0], pf[0][1], pf[1][1]], 6));
    println!("wrong: half-plane test on the sampled loop's {}: real part > 0; try: pole 0.24525 m: eigenvalue {}, doubling {} s",
        f(rho(&m1).0, 4), f((9.81f64 / 0.24525).sqrt(), 4), f(2f64.ln() / (9.81f64 / 0.24525).sqrt(), 4));
    let pq = lyap(&ac, &m(&[&[10.0, 0.0], &[0.0, 1.0]]), false).0.unwrap();
    println!("try: Q = diag(10, 1): P {} minors {}", fl(&[pq[0][0], pq[0][1], pq[1][1]], 6), fl(&minors(&pq), 6));
    assert!(lam.iter().zip([4.0, 0.0, 0.0, -4.0]).all(|(z, e)| (z.0 - e).abs() < 1e-6));       // roots of s^4 - 16 s^2
    assert!(((th(3.0) / th(2.0)).ln() - lam[0].0).abs() < 1e-6);                                 // simulated growth = top eigenvalue
    assert!((zd.iter().map(|z| (z.0 * z.0 + z.1 * z.1).sqrt()).fold(0.0, f64::max) - 2.718281828459045f64.powf(4.0 * h)).abs() < 1e-9);
    assert!([p[0][0], p[0][1], p[1][1]].iter().zip(hand).all(|(a, b)| (a - b).abs() < 1e-12)); // solve = hand formula
    assert!(gap(&p, &pi) < 1e-8);                                                                // solve = integral
    assert!(gap(&p4, &p4i) < 1e-6 && cholesky_ok(&p4));
    assert!([0.01, 0.2, 0.5].iter().all(|&x| (rho(&mdig(x)).0 - rho_pow(&mdig(x), 2000)).abs() < 1e-6)); // trace-det = powers
    let (_, t9, d9) = rho(&mdig(lo)); assert!((1.0 + t9 + d9).abs() < 1e-9); assert!(gap(&pd, &s) < 1e-6);   // Jury edge; solve = series
    let (ch, sh) = (2f64.cosh(), 2f64.sinh());        // closed form at h = 0.5: e^(Ah) by cosh and sinh, push by integrating
    let cf = m(&[&[ch - (ch - 1.0) / 16.0 * 24.0, sh / 4.0 - (ch - 1.0) / 16.0 * 6.0], &[4.0 * sh - sh / 4.0 * 24.0, ch - sh / 4.0 * 6.0]]);
    assert!(gap(&mdig(0.5), &cf) < 1e-9);
    assert!(po.is_none() && !cholesky_ok(&pf));                                                  // no certificate when unstable
    assert!(falls(0.9).0 && !falls(1.0).0);                                                      // the linear certificate is local
    println!("ALL CHECKS PASS");
}
