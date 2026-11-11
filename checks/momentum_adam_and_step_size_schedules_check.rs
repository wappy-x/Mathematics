// Momentum, Nesterov and Adam racing down f(x) = (x1^2 + 100 x2^2)/2 from (10, 1).
// Minimum: f >= 0 everywhere and f(0, 0) = 0, so x* = (0, 0) and the distance to it is the error.
type M2 = [[f64; 2]; 2];
type P = [f64; 2];
const MU: f64 = 1.0; const L: f64 = 100.0; const X0: P = [10.0, 1.0]; const TOL: f64 = 1e-4;
const BOWL: M2 = [[MU, 0.0], [0.0, L]];

fn grad(a: &M2, x: &P) -> P { [a[0][0] * x[0] + a[0][1] * x[1], a[1][0] * x[0] + a[1][1] * x[1]] }

// y = x_k + b (x_k - x_{k-1}); heavy ball steps from y with the slope at x_k, Nesterov with the slope at y
fn momentum(m: &M2, a: f64, b: f64, n: usize, nesterov: bool, x0: P) -> Vec<P> {
    let (mut xp, mut x) = (x0, x0);
    let mut path = vec![x];
    for _ in 0..n {
        let y = [x[0] + b * (x[0] - xp[0]), x[1] + b * (x[1] - xp[1])];
        let g = grad(m, if nesterov { &y } else { &x });
        xp = x; x = [y[0] - a * g[0], y[1] - a * g[1]];
        path.push(x);
    }
    path
}

fn adam(a: &M2, step: &dyn Fn(usize) -> f64, n: usize, mut rng: Option<&mut u64>, x0: P) -> Vec<P> {
    let (b1, b2) = (0.9_f64, 0.999_f64);
    let (mut x, mut m, mut v, mut p1, mut p2) = (x0, [0.0; 2], [0.0; 2], 1.0, 1.0);
    let mut path = vec![x];
    for k in 1..=n {
        let g = grad(a, &x);
        p1 *= b1; p2 *= b2;
        for i in 0..2 {
            let gi = g[i] + match rng.as_deref_mut() { Some(s) => 3.0_f64.sqrt() * (2.0 * splitmix(s) - 1.0), None => 0.0 }; // noise of standard deviation 1
            m[i] = b1 * m[i] + (1.0 - b1) * gi;
            v[i] = b2 * v[i] + (1.0 - b2) * gi * gi;
            x[i] -= step(k) * (m[i] / (1.0 - p1)) / ((v[i] / (1.0 - p2)).sqrt() + 1e-8);
        }
        path.push(x);
    }
    path
}

fn dist(p: &P) -> f64 { p[0].hypot(p[1]) }
fn steps(path: &[P]) -> Option<usize> { path.iter().position(|p| dist(p) <= TOL) }
fn show(s: Option<usize>) -> String { s.map_or("None".to_string(), |k| k.to_string()) }

fn splitmix(s: &mut u64) -> f64 {
    *s = s.wrapping_add(0x9E3779B97F4A7C15);
    let mut z = *s;
    z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
}

// Python-style scientific format: 1.00e+01
fn sci(x: f64, prec: usize) -> String {
    let s = format!("{:.*e}", prec, x);
    let (m, e) = s.split_once('e').unwrap();
    let e: i32 = e.parse().unwrap();
    format!("{}e{}{:02}", m, if e < 0 { '-' } else { '+' }, e.abs())
}

// a two-term recurrence whose two roots coincide at rho: e_k = (e0 + (e1/rho - e0) k) rho^k
fn double_root(e0: f64, e1: f64, rho: f64, k: usize) -> f64 {
    if rho == 0.0 { 0.0 } else { (e0 + (e1 / rho - e0) * k as f64) * rho.powf(k as f64) }
}

fn main() {
    let (kap, sk) = (L / MU, (L / MU).sqrt());
    let a_gd = 2.0 / (MU + L);
    let (a_hb, b_hb) = (4.0 / (L.sqrt() + MU.sqrt()).powf(2.0), ((sk - 1.0) / (sk + 1.0)).powf(2.0));
    let (a_ns, b_ns) = (1.0 / L, (sk - 1.0) / (sk + 1.0));
    let n = 800;
    let c03 = |_k: usize| 0.3;
    let (gd, hb) = (momentum(&BOWL, a_gd, 0.0, n, false, X0), momentum(&BOWL, a_hb, b_hb, n, false, X0));
    let (ns, ad) = (momentum(&BOWL, a_ns, b_ns, n, true, X0), adam(&BOWL, &c03, n, None, X0));
    let closed = |kind: &str, k: usize| -> P {
        let mut out = [0.0; 2];
        for (i, (lam, e0)) in [MU, L].iter().zip(X0.iter()).enumerate() {
            if kind == "gd" { out[i] = e0 * (1.0 - a_gd * lam).powf(k as f64); continue; }
            let s = if kind == "hb" { a_hb } else { a_ns } * lam;
            let tr = if kind == "hb" { 1.0 + b_hb - s } else { (1.0 + b_ns) * (1.0 - s) };
            out[i] = double_root(*e0, (1.0 - s) * e0, tr / 2.0, k);
        }
        out
    };
    let cl: Vec<Option<usize>> = ["gd", "hb", "ns"].iter().map(|kd| steps(&(0..=n).map(|k| closed(kd, k)).collect::<Vec<P>>())).collect();
    println!("bowl (x1^2 + {:.0} x2^2)/2 from (10, 1); kappa {:.0}; stop when distance to (0, 0) <= {}", L, kap, TOL);
    println!("plain     alpha {:.4}               rate {:.5}  steps {}, closed form {}", a_gd, (kap - 1.0) / (kap + 1.0), show(steps(&gd)), show(cl[0]));
    println!("heavy     alpha {:.4} beta {:.4}   rate {:.5}  steps {}, closed form {}", a_hb, b_hb, b_hb.sqrt(), show(steps(&hb)), show(cl[1]));
    println!("nesterov  alpha {:.4} beta {:.4}   rate {:.5}  steps {}, closed form {}", a_ns, b_ns, 1.0 - 1.0 / sk, show(steps(&ns)), show(cl[2]));
    println!("adam      alpha 0.3 beta1 0.9 beta2 0.999   steps {}; first step to ({:.4}, {:.4})", show(steps(&ad)), ad[1][0], ad[1][1]);
    let h20 = closed("hb", 20); println!("heavy, step 20: loop ({:.6}, {:.6}), closed form ({:.6}, {:.6})", hb[20][0], hb[20][1], h20[0], h20[1]);
    let cof = |e0: f64, s: f64, tr: f64| format!("({:.4}, {:.4})", tr / 2.0, (1.0 - s) * e0 / (tr / 2.0) - e0); // (double root, coefficient of k)
    println!("double roots and k-coefficients: heavy x1 {}, x2 {}; nesterov x1 {}", cof(10.0, a_hb, 1.0 + b_hb - a_hb), cof(1.0, a_hb * L, 1.0 + b_hb - a_hb * L), cof(10.0, a_ns, (1.0 + b_ns) * (1.0 - a_ns)));
    println!("heavy stability: alpha L = {:.4} < 2(1 + beta) = {:.4}; plain needs alpha L < 2", a_hb * L, 2.0 * (1.0 + b_hb));
    let ks = [0, 1, 2, 5, 10, 25, 50, 100, 200];
    println!("race, distance at k {}", ks.iter().map(|k| format!("{:>9}", k)).collect::<Vec<_>>().join(" "));
    let runs: [(&str, &Vec<P>); 4] = [("plain", &gd), ("heavy ball", &hb), ("nesterov", &ns), ("adam", &ad)];
    for (name, p) in runs.iter() {
        println!("  {:<18}{}", name, ks.iter().map(|&k| format!("{:>9}", sci(dist(&p[k]), 2))).collect::<Vec<_>>().join(" "));
    }
    for (name, p) in runs.iter() {
        println!("chart log10, {:<10} {}", name, (0..=200).step_by(25).map(|k| format!("{:.2}", dist(&p[k]).log10())).collect::<Vec<_>>().join(" "));
    }
    for (name, p) in runs.iter() {
        println!("figure, {:<10} {}", name, p[..11].iter().map(|q| format!("{:.2},{:.2}", q[0], q[1])).collect::<Vec<_>>().join(" "));
    }

    // Step-size schedules: the same Adam with noisy slopes, root-mean-square distance over 20 seeds
    let sched: [(&str, Box<dyn Fn(usize) -> f64>); 4] = [
        ("constant 0.3", Box::new(|_k| 0.3)), ("constant 0.03", Box::new(|_k| 0.03)),
        ("halve every 200", Box::new(|k| 0.3 * 0.5_f64.powf(((k - 1) / 200) as f64))),
        ("cosine 0.3 to 0", Box::new(|k| 0.15 * (1.0 + (std::f64::consts::PI * k as f64 / 1000.0).cos()))),
    ];
    let kn = [100, 200, 400, 600, 800, 1000];
    let mut rms: Vec<Vec<f64>> = Vec::new();
    for (name, sch) in sched.iter() {
        let mut sq = [0.0; 6];
        for seed in 0..20u64 {
            let mut s = seed;
            let p = adam(&BOWL, sch.as_ref(), 1000, Some(&mut s), X0);
            for (j, &k) in kn.iter().enumerate() { sq[j] += dist(&p[k]).powf(2.0) / 20.0; }
        }
        let r: Vec<f64> = sq.iter().map(|s| s.sqrt()).collect();
        println!("noisy adam, {:<16}{}", name, r.iter().map(|x| format!("{:7.4}", x)).collect::<Vec<_>>().join(" "));
        rms.push(r);
    }

    // What breaks, then the Try-changing experiments
    let steep: M2 = [[MU, 0.0], [0.0, 150.0]]; let br: Vec<f64> = [(a_gd, 0.0, false), (a_hb, b_hb, false), (a_ns, b_ns, true)].iter()
        .map(|&(a, b, nv)| dist(momentum(&steep, a, b, 100, nv, X0).last().unwrap())).collect();
    println!("breaks: curvature 150, tuned for 100, distance after 100: plain {}, heavy {}, nesterov {}; adam steps {}",
        sci(br[0], 3), sci(br[1], 3), sci(br[2], 3), show(steps(&adam(&steep, &c03, n, None, X0))));
    println!("breaks: heavy ball's alpha with beta 0, curvature 100, distance after 50: {}", sci(dist(momentum(&BOWL, a_hb, 0.0, 50, false, X0).last().unwrap()), 3));
    // f_k(x) = C x when k leaves remainder 1 on division by 3, else -x; x kept in [-1, 1]
    let reddi = |ams: bool| -> (f64, f64) {
        let (t, c) = (3000usize, 3.0_f64);
        let (mut x, mut v, mut vmax, mut loss) = (0.0_f64, 0.0_f64, 0.0_f64, 0.0_f64);
        for k in 1..=t {
            let g = if k % 3 == 1 { c } else { -1.0 };
            loss += g * x / t as f64;
            v = 0.1 * v + 0.9 * g * g; // beta1 = 0, beta2 = 1/(1 + C^2) = 0.1
            vmax = vmax.max(v);
            x = (x - 0.5 / (k as f64).sqrt() * g / (if ams { vmax } else { v }).sqrt()).min(1.0).max(-1.0);
        }
        (x, loss)
    };
    let ((xa, la), (xm, lm)) = (reddi(false), reddi(true));
    println!("breaks: Reddi example, 3000 rounds: adam ends at x = {:.4}, average loss {:.4}; max-memory variant x = {:.4}, {:.4}; best x = -1, {:.4}", xa, la, xm, lm, -(3.0 - 2.0) / 3.0);
    let rot: M2 = [[50.5, -49.5], [-49.5, 50.5]]; // the same bowl turned 45 degrees
    let r0 = [(X0[0] + X0[1]) / 2.0_f64.sqrt(), (X0[0] - X0[1]) / 2.0_f64.sqrt()]; // the start, turned too
    let rt = [steps(&momentum(&rot, a_gd, 0.0, n, false, r0)), steps(&momentum(&rot, a_hb, b_hb, n, false, r0)),
              steps(&momentum(&rot, a_ns, b_ns, n, true, r0)), steps(&adam(&rot, &c03, 3000, None, r0))];
    println!("try: bowl turned 45 degrees: plain {}, heavy {}, nesterov {}, adam {} steps", show(rt[0]), show(rt[1]), show(rt[2]), show(rt[3]));
    let big: M2 = [[MU, 0.0], [0.0, 1e4]]; let tries = [steps(&adam(&BOWL, &|_k| 0.03, 3000, None, X0)), steps(&adam(&big, &c03, n, None, X0))];
    let (a4, b4) = (4.0 / (100.0_f64 + 1.0).powf(2.0), (99.0_f64 / 101.0).powf(2.0));
    let (hb4, q) = (momentum(&big, a4, b4, 3000, false, X0), 9999.0_f64 / 10001.0);
    let gd4 = (0..1_000_000).find(|&k| (10.0 * q.powf(k as f64)).hypot(q.powf(k as f64)) <= TOL).unwrap();
    println!("try: adam alpha 0.03: {} steps; curvature 10000: adam {}, heavy ball retuned {}, plain retuned (closed form) {}", show(tries[0]), show(tries[1]), show(steps(&hb4)), gd4);

    assert!(steps(&gd) == cl[0] && steps(&hb) == cl[1] && steps(&ns) == cl[2], "loop and closed form disagree");
    assert!((0..2).map(|i| (hb[20][i] - h20[i]).abs()).fold(0.0, f64::max) < 1e-9, "heavy ball off its double root");
    assert!((ad[1][0] - 9.7).abs() < 1e-6 && (ad[1][1] - 0.7).abs() < 1e-6, "Adam's first step is alpha per variable");
    assert!(steps(&hb) < steps(&ns) && steps(&ns) < steps(&ad) && steps(&ad) < steps(&gd), "the race order");
    assert!(rt[0] == steps(&gd) && rt[1] == steps(&hb) && rt[2] == steps(&ns) && rt[3] > steps(&ad), "turning the bowl changes only Adam");
    assert!(xa > 0.99 && xm < -0.99, "Reddi: Adam settles at the worst point, the max-memory variant near the best");
    assert!(rms[2][5] < rms[0][5] / 3.0, "a falling schedule beats the constant step");
    println!("ALL CHECKS PASS");
}
