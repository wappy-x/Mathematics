// Monotone operators and splitting -- the check behind the card.  std only.
// Roads: the Moreau envelope of |x| by its prox, by the Huber formula and by a grid search;
// Douglas-Rachford against the closed-form answer and its KKT multipliers;
// Chambolle-Pock against a duality gap and an enumeration of every jump pattern.
fn f(v: f64) -> String { format!("{:.6}", if v.abs() < 5e-7 { 0.0 } else { v }) }
fn l(vs: &[f64]) -> String { format!("({})", vs.iter().map(|&v| f(v)).collect::<Vec<_>>().join(", ")) }
fn nm(v: &[f64]) -> f64 { v.iter().map(|a| a * a).sum::<f64>().sqrt() } fn sub(a: &[f64], b: &[f64]) -> Vec<f64> { a.iter().zip(b).map(|(p, q)| p - q).collect() }
fn prox(x: f64) -> f64 { (x.abs() - 1.0).max(0.0).copysign(x) }
fn env(x: f64) -> f64 { prox(x).abs() + 0.5 * (x - prox(x)).powi(2) } fn huber(x: f64) -> f64 { if x.abs() <= 1.0 { x * x / 2.0 } else { x.abs() - 0.5 } }
fn p_simplex(v: &[f64]) -> Vec<f64> {
    let mut s = v.to_vec();
    s.sort_by(|a, b| b.partial_cmp(a).unwrap());
    let (mut c, mut t) = (0.0, 0.0);
    for i in 0..s.len() {
        c += s[i]; t = (c - 1.0) / (i as f64 + 1.0);
        if i == s.len() - 1 || s[i + 1] <= t { break; }
    }
    v.iter().map(|a| (a - t).max(0.0)).collect()
}
const U: [f64; 3] = [0.5, 0.6, -0.1]; const H: [f64; 3] = [0.6, 0.4, 0.0];
fn p_ball(v: &[f64], r: f64) -> Vec<f64> {
    let d = sub(v, &U); let n = nm(&d); if n <= r { v.to_vec() } else { U.iter().zip(&d).map(|(b, x)| b + r * x / n).collect() }
}
fn p_f(v: &[f64]) -> Vec<f64> { p_simplex(&v.iter().zip(&H).map(|(a, b)| (a + b) / 2.0).collect::<Vec<_>>()) }
type Hist = Vec<(Vec<f64>, Vec<f64>, Vec<f64>)>;
fn dr(r: f64, steps: usize, zstar: Option<&[f64]>) -> (usize, Vec<f64>, Hist) {
    let (mut z, mut hist): (Vec<f64>, Hist) = (H.to_vec(), vec![]);
    for k in 0..steps {
        let x = p_f(&z);
        let y = p_ball(&sub(&x.iter().map(|a| 2.0 * a).collect::<Vec<_>>(), &z), r);
        let zn: Vec<f64> = (0..3).map(|i| z[i] + y[i] - x[i]).collect();
        hist.push((x, y, zn.clone()));
        if let Some(zs) = zstar { // firm nonexpansiveness: Fejer decrease, residual bound
            assert!(nm(&sub(&zn, zs)).powi(2) <= nm(&sub(&z, zs)).powi(2) - nm(&sub(&zn, &z)).powi(2) + 1e-15);
            assert!(nm(&sub(&zn, &z)) <= nm(&sub(&H, zs)) / ((k + 1) as f64).sqrt() + 1e-15);
        }
        if nm(&sub(&zn, &z)) < 1e-12 { return (k + 1, zn, hist); }
        z = zn;
    }
    (steps, z, hist)
}
const Y: [f64; 8] = [2.0, 4.0, 3.0, 10.0, 12.0, 9.0, 11.0, 3.0]; const LAM: f64 = 3.0; const M: usize = 8;
fn dx(x: &[f64]) -> Vec<f64> { (0..M - 1).map(|i| x[i + 1] - x[i]).collect() }
fn dt(p: &[f64]) -> Vec<f64> {
    (0..M).map(|k| (if k > 0 { p[k - 1] } else { 0.0 }) - (if k < M - 1 { p[k] } else { 0.0 })).collect()
}
fn pr(x: &[f64]) -> f64 {
    0.5 * x.iter().zip(&Y).map(|(a, b)| (a - b).powi(2)).sum::<f64>() + LAM * dx(x).iter().map(|d| d.abs()).sum::<f64>()
}
fn qd(p: &[f64]) -> f64 {
    0.5 * Y.iter().map(|a| a * a).sum::<f64>() - 0.5 * Y.iter().zip(dt(p)).map(|(a, b)| (a - b).powi(2)).sum::<f64>()
}
fn cp(tau: f64, sig: f64, steps: usize) -> (usize, Vec<f64>, Vec<f64>) {
    let (mut x, mut xb, mut p) = (vec![0.0; M], vec![0.0; M], vec![0.0; M - 1]);
    for k in 0..steps {
        p = p.iter().zip(dx(&xb)).map(|(a, b)| (a + sig * b).min(LAM).max(-LAM)).collect();
        let d = dt(&p);
        let xn: Vec<f64> = (0..M).map(|i| (x[i] - tau * d[i] + tau * Y[i]) / (1.0 + tau)).collect();
        xb = (0..M).map(|i| 2.0 * xn[i] - x[i]).collect();
        if (0..M).map(|i| (xn[i] - x[i]).abs()).fold(0.0, f64::max) < 1e-12 { return (k + 1, xn, p); }
        x = xn;
    }
    (steps, x, p)
}
fn main() {
    println!("monotone operators and splitting");
    // 1. the prox of |x| is soft thresholding; its Moreau envelope is the Huber function
    let xs: Vec<f64> = (-6..7).map(|i| i as f64 / 2.0).collect();
    for &x in &xs {
        let g = (-5000..5001).map(|i| { let t = i as f64 / 1000.0; t.abs() + 0.5 * (x - t).powi(2) }).fold(f64::INFINITY, f64::min);
        assert!((env(x) - huber(x)).abs() < 1e-12 && (env(x) - g).abs() < 1e-6);
    }
    println!("chart_abs, {}", xs.iter().map(|&x| f(x.abs())).collect::<Vec<_>>().join(", "));
    println!("chart_env, {}", xs.iter().map(|&x| f(env(x))).collect::<Vec<_>>().join(", "));
    for x in [3.0, 0.4] {
        let cd = (env(x + 1e-5) - env(x - 1e-5)) / 2e-5;
        let clip = x.min(1.0).max(-1.0);
        assert!((cd - (x - prox(x))).abs() < 1e-6 && (prox(x) + clip - x).abs() < 1e-15);
        println!("x = {}: prox {}, envelope {}, gradient x - prox {}, central difference {}, clip {}",
                 f(x), f(prox(x)), f(env(x)), f(x - prox(x)), f(cd), f(clip));
    }
    let pts: Vec<f64> = (-40..41).map(|i| i as f64 / 10.0).collect();
    let mut slack = f64::INFINITY;
    for &a in &pts { for &b in &pts { slack = slack.min((a - b) * (prox(a) - prox(b)) - (prox(a) - prox(b)).powi(2)); } }
    assert!(slack >= 0.0);
    println!("firm nonexpansiveness, worst slack over 6561 pairs: {}", f(slack));
    let (mut pp, mut fw) = (vec![3.0], vec![0.4]);
    for _ in 0..3 { let (a, b) = (*pp.last().unwrap(), *fw.last().unwrap()); pp.push(prox(a)); fw.push(b - 1f64.copysign(b)); }
    assert!(pp[3] == 0.0 && (fw[3] + 0.6).abs() < 1e-12);
    println!("proximal point from 3: {} | subgradient step 1 from 0.4: {}", l(&pp), l(&fw));
    // 2. Douglas-Rachford: simplex (budget, long only) and a ball round the model weights
    let h2 = dr(0.15, 2, None).2;
    for k in 0..2 { println!("DR step {}: x {}, y {}, z {}", k, l(&h2[k].0), l(&h2[k].1), l(&h2[k].2)); }
    let (n, zs, hist) = dr(0.15, 5000, None);
    dr(0.15, 5000, Some(&zs));
    let w = p_f(&zs);
    let e = 0.06f64.sqrt() / 4.0; let exact = [0.45 + e, 0.55 - e, 0.0];
    assert!(nm(&sub(&w, &exact)) < 1e-9);
    // KKT: h - w = mu (w - u) + nu (1,1,1) - eta e3, with mu, eta >= 0
    let mu = ((H[0] - w[0]) - (H[1] - w[1])) / ((w[0] - U[0]) - (w[1] - U[1]));
    let nu = H[0] - w[0] - mu * (w[0] - U[0]);
    let eta = mu * (w[2] - U[2]) + nu - (H[2] - w[2]);
    assert!(mu > 0.0 && eta > 0.0 && (nm(&sub(&w, &U)) - 0.15).abs() < 1e-9 && (w.iter().sum::<f64>() - 1.0).abs() < 1e-12);
    println!("DR converged in {} steps: w {} closed form {}", n, l(&w), l(&exact));
    println!("KKT multipliers: ball {} budget {} Japan >= 0 {}", f(mu), f(nu), f(eta));
    println!("distance to model {} tracking error % {} trade {}", f(nm(&sub(&w, &U))), f(20.0 * nm(&sub(&w, &U))), f(w[0] - H[0]));
    println!("Fejer decrease and residual bound held at all {} steps", n);
    let q2 = |v: &[f64]| l(&[(v[1] - v[0]) / 2f64.sqrt(), (2.0 * v[2] - v[0] - v[1]) / 6f64.sqrt()]);
    println!("figure, plane coordinates: u {} h {} w {}", q2(&U), q2(&H), q2(&w));
    println!("figure, z path: {}", [0, 1, 2, 4, 8, 16, 32].iter().map(|&k| q2(&hist[k].2)).collect::<Vec<_>>().join(" "));
    println!("what breaks: read off z: {}, sum {}", l(&zs), f(zs.iter().sum()));
    let (n10, _, hist10) = dr(0.10, 400, None);
    let (drift, x10) = (nm(&sub(&hist10[399].2, &hist10[398].2)), &hist10[399].0);
    assert!(n10 == 400 && drift > 0.02 && nm(&sub(x10, &U)) > 0.12);
    println!("what breaks: radius 0.10, z still moving {} per step after 400; x {} is {} from the model",
             f(drift), l(x10), f(nm(&sub(x10, &U))));
    // 3. Chambolle-Pock: total-variation smoothing of eight days of trading spreads (bp)
    let mut v = vec![0.0; M]; v[0] = 1.0;
    for _ in 0..2000 { v = dt(&dx(&v)); let s = nm(&v); v = v.iter().map(|a| a / s).collect(); }
    let norm2 = nm(&dt(&dx(&v)));
    let cf = 2.0 + 2.0 * (std::f64::consts::PI / M as f64).cos();
    assert!((norm2 - cf).abs() < 1e-9);
    println!("||D||^2 by power iteration {} closed form {} tau sigma ||D||^2 {}", f(norm2), f(cf), f(0.45 * 0.45 * norm2));
    let (k, x, p) = cp(0.45, 0.45, 100000);
    let gap = pr(&x) - qd(&p);
    assert!(gap >= 0.0 && gap < 1e-6 && p.iter().all(|a| a.abs() <= LAM));
    println!("CP converged in {} steps: x {}", k, l(&x));
    println!("primal {} dual {} gap {} prices p {}", f(pr(&x)), f(qd(&p)), f(gap), l(&p));
    let mut found: Vec<Vec<f64>> = vec![];
    for code in 0..3usize.pow(7) {
        let s: Vec<i32> = (0..M - 1).map(|i| ((code / 3usize.pow((M - 2 - i) as u32)) % 3) as i32 - 1).collect();
        let (mut xs, mut a) = (vec![0.0; M], 0);
        while a < M {
            let mut b = a;
            while b < M - 1 && s[b] == 0 { b += 1; }
            let sb = if b < M - 1 { s[b] as f64 } else { 0.0 };
            let sa = if a > 0 { s[a - 1] as f64 } else { 0.0 };
            let val = (Y[a..=b].iter().sum::<f64>() + LAM * sb - LAM * sa) / (b - a + 1) as f64;
            for i in a..=b { xs[i] = val; }
            a = b + 1;
        }
        let mut ok = dx(&xs).iter().zip(&s).all(|(&d, &t)| if t == 1 { d > 1e-12 } else if t == -1 { d < -1e-12 } else { d.abs() < 1e-12 });
        let mut run = 0.0;
        for i in 0..M - 1 {
            run += xs[i] - Y[i];
            ok = ok && if s[i] != 0 { (run - LAM * s[i] as f64).abs() < 1e-9 } else { run.abs() <= LAM + 1e-9 };
        }
        if ok { found.push(xs); }
    }
    assert!(found.len() == 1 && (0..M).all(|i| (found[0][i] - x[i]).abs() < 1e-9));
    println!("enumeration: 2187 jump patterns, 1 passes: {}", l(&found[0]));
    let (hu, z1) = (nm(&sub(&H, &U)), dr(0.15, 2, None).2[0].2.clone());
    println!("hand: |h - u| {}, scale {}, (z1 + h)/2 {}; TV fit {}, total jump {}", f(hu), f(0.15 / hu), l(&(0..3).map(|i| (z1[i] + H[i]) / 2.0).collect::<Vec<_>>()),
             f(0.5 * x.iter().zip(&Y).map(|(a, b)| (a - b).powi(2)).sum::<f64>()), f(dx(&x).iter().map(|d| d.abs()).sum()));
    let (a1, b1) = ([1.0, 0.0, 2.0, 5.0, 3.0, 1.0, 0.0, 4.0], [0.5, -1.0, 2.0, 0.0, 1.0, -2.0, 0.0]);
    let (a2, b2) = ([2.0, 1.0, 1.0, 3.0, 3.0, 3.0, 2.0, 0.0], [0.0, 1.0, -1.0, 2.0, -2.0, 0.0, 0.5]);
    let op = |xx: &[f64], pq: &[f64]| (sub(xx, &sub(&Y, &dt(pq))), dx(xx).iter().map(|d| -d).collect::<Vec<f64>>());
    let ((g1, h1), (g2, h2)) = (op(&a1, &b1), op(&a2, &b2));
    let inner: f64 = sub(&g1, &g2).iter().zip(sub(&a1, &a2)).map(|(c, d)| c * d).sum::<f64>()
        + sub(&h1, &h2).iter().zip(sub(&b1, &b2)).map(|(c, d)| c * d).sum::<f64>();
    assert!((inner - nm(&sub(&a1, &a2)).powi(2)).abs() < 1e-12);
    println!("saddle operator: <Ma - Mb, a - b> = {} = ||x_a - x_b||^2 = {}", f(inner), f(nm(&sub(&a1, &a2)).powi(2)));
    let ((k1, x1, _), x9, x8) = (cp(1.0, 1.0, 3000), cp(1.0, 1.0, 2999).1, cp(1.0, 1.0, 2998).1);
    assert!(pr(&x1) - pr(&x) > 1.0 && pr(&x9) - pr(&x1) > 1.0 && (pr(&x8) - pr(&x1)).abs() < 1e-9); // stuck in a two-step cycle
    println!("what breaks: tau = sigma = 1 (tau sigma ||D||^2 = {}): after {} steps {} above the minimum, after {} steps {}",
             f(norm2), k1, f(pr(&x1) - pr(&x)), k1 - 1, f(pr(&x9) - pr(&x)));
    let ((k6, x6, p6), w20) = (cp(0.6, 0.6, 100000), p_f(&dr(0.20, 5000, None).1));
    println!("try: CP at tau = sigma = 0.6 (tau sigma ||D||^2 = {}): {} steps, gap {}; DR at radius 0.20: w {}", f(0.36 * norm2), k6, f(pr(&x6) - qd(&p6)), l(&w20));
    println!("ALL CHECKS PASS");
}
