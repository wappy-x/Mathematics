// Whose risk is it: component VaR by Euler's rule -- the same check in Rust.
// Standard library only, no crates.  The normal CDF is Simpson's rule on the
// bell curve, the 99% point is found by bisection, the random numbers come
// from a 64-bit generator written out here.
use std::f64::consts::PI;

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }
fn n_cdf(x: f64) -> f64 {
    let n = 2000;
    let h = x / n as f64;
    let mut inner = 0.0;
    for i in 1..n { inner += if i % 2 == 1 { 4.0 } else { 2.0 } * phi(i as f64 * h); }
    0.5 + (phi(0.0) + phi(x) + inner) * h / 3.0
}
fn z_of(p: f64) -> f64 {
    let (mut lo, mut hi) = (0.0, 10.0);
    for _ in 0..100 {
        let mid = 0.5 * (lo + hi);
        if n_cdf(mid) < p { lo = mid } else { hi = mid }
    }
    0.5 * (lo + hi)
}
fn sd(p: &[f64; 3], cov: &[[f64; 3]; 3]) -> f64 {
    let mut v = 0.0;
    for i in 0..3 { for j in 0..3 { v += p[i] * cov[i][j] * p[j]; } }
    v.sqrt()
}
fn t(v: f64) -> String { format!("{:10.2}", v / 1000.0) }

fn main() {
    let delta = (-0.02f64).exp() * n_cdf(0.25);
    let x = [10_000_000.0, 5_000_000.0, 1000.0 * 100.0 * delta * 100.0];
    let vol = [0.0135, 5.0 * 0.0006, 0.20 / 252f64.sqrt()]; // bonds: 5-year duration x 6 bp
    let rho = [[1.0, -0.2, 0.5], [-0.2, 1.0, -0.1], [0.5, -0.1, 1.0]]; // bond price: yield corrs flip sign
    let mk = |r: &[[f64; 3]; 3]| -> [[f64; 3]; 3] {
        let mut c = [[0.0; 3]; 3];
        for i in 0..3 { for j in 0..3 { c[i][j] = r[i][j] * vol[i] * vol[j]; } }
        c
    };
    let cov = mk(&rho);
    let names = ["shares", "bonds", "calls"];
    let z = z_of(0.99);
    let k = phi(z) / 0.01;
    let var = |p: &[f64; 3]| z * sd(p, &cov);

    // Road 1: the gradient formula
    let s = sd(&x, &cov); let v_tot = var(&x); let es = k * s;
    let sx: [f64; 3] = std::array::from_fn(|i| (0..3).map(|j| cov[i][j] * x[j]).sum());
    let marg: [f64; 3] = std::array::from_fn(|i| z * sx[i] / s);
    let comp: [f64; 3] = std::array::from_fn(|i| x[i] * marg[i]);
    let comp_es: [f64; 3] = std::array::from_fn(|i| k * x[i] * sx[i] / s);
    // Road 2: nudge each position
    let fd: [f64; 3] = std::array::from_fn(|i| {
        let h = 1e-4 * x[i];
        let (mut up, mut dn) = (x, x);
        up[i] += h; dn[i] -= h;
        x[i] * (var(&up) - var(&dn)) / (2.0 * h)
    });
    // Road 3: simulate 400,000 days
    let mut l = [[1.0, 0.0, 0.0], [0.0; 3], [0.0; 3]];
    l[1][0] = rho[1][0]; l[1][1] = (1.0 - l[1][0] * l[1][0]).sqrt();
    l[2][0] = rho[2][0]; l[2][1] = (rho[2][1] - l[2][0] * l[1][0]) / l[1][1];
    l[2][2] = (1.0 - l[2][0] * l[2][0] - l[2][1] * l[2][1]).sqrt();
    let mut state: u64 = 20260928;
    let mut unif = || {
        state = state.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
        ((state >> 11) as f64 + 0.5) / 9007199254740992.0
    };
    let m = 400_000usize;
    let mut days: Vec<(f64, [f64; 3])> = Vec::with_capacity(m);
    for _ in 0..m {
        let (a, b) = ((-2.0 * unif().ln()).sqrt(), 2.0 * PI * unif());
        let (c, g) = ((-2.0 * unif().ln()).sqrt(), 2.0 * PI * unif());
        let e = [a * b.cos(), a * b.sin(), c * g.cos()];
        let w: [f64; 3] = std::array::from_fn(|i| { let mut acc = 0.0; for j in 0..3 { acc += l[i][j] * e[j]; } acc });
        let loss: [f64; 3] = std::array::from_fn(|i| -x[i] * vol[i] * w[i]);
        days.push((loss[0] + loss[1] + loss[2], loss));
    }
    days.sort_by(|p, q| q.0.partial_cmp(&p.0).unwrap());
    let tail = m / 100;
    let mc_var = days[tail].0;
    let mc_es: [f64; 3] = std::array::from_fn(|i| days[..tail].iter().map(|d| d.1[i]).sum::<f64>() / tail as f64);
    let band = &days[tail - 400..tail + 400];
    let mc_vc: [f64; 3] = std::array::from_fn(|i| band.iter().map(|d| d.1[i]).sum::<f64>() / band.len() as f64);
    let mc_sd = (days.iter().map(|d| d.0 * d.0).sum::<f64>() / m as f64).sqrt();

    println!("z(99%) {:.6}   ES multiplier {:.6}   call delta {:.6}", z, k, delta);
    println!("exposure $k      {}{}{}", t(x[0]), t(x[1]), t(x[2]));
    println!("Sigma x, dollars   {}", sx.iter().map(|v| format!("{:10.2}", v)).collect::<String>());
    println!("x_i (Sigma x)_i $k^2{}  sum {:.2}", (0..3).map(|i| format!("{:12.2}", x[i] * sx[i] / 1e6)).collect::<String>(),
             (0..3).map(|i| x[i] * sx[i]).sum::<f64>() / 1e6);
    println!("one-day sd $k {}   sd by simulation {}", t(s), t(mc_sd));
    println!("VaR 99% $k    {}   VaR by simulation {}", t(v_tot), t(mc_var));
    println!("ES 99% $k     {}   ES by simulation {}", t(es), t(mc_es.iter().sum()));
    println!("{:<8}{:>10}{:>10}{:>10}{:>10}{:>10}{:>10}{:>10}", "line", "marg c/$", "comp VaR", "by nudge", "by sim", "share %", "comp ES", "ES sim");
    for i in 0..3 {
        println!("{:<8}{:10.4}{}{}{}{:10.2}{}{}", names[i], 100.0 * marg[i], t(comp[i]), t(fd[i]), t(mc_vc[i]),
                 100.0 * comp[i] / v_tot, t(comp_es[i]), t(mc_es[i]));
    }
    let sum = |a: &[f64; 3]| a[0] + a[1] + a[2];
    println!("{:<8}{:>10}{}{}{}{:10.2}{}{}", "sum", "", t(sum(&comp)), t(sum(&fd)), t(sum(&mc_vc)),
             100.0 * sum(&comp) / v_tot, t(sum(&comp_es)), t(sum(&mc_es)));
    println!("Euler by scaling: VaR(2x) / VaR(x) = {:.6}", var(&[2.0 * x[0], 2.0 * x[1], 2.0 * x[2]]) / v_tot);
    for i in 0..3 {
        let mut p = x; p[i] = 0.0;
        println!("sell all {:<7} VaR {}  change {}  minus component {}", names[i], t(var(&p)), t(var(&p) - v_tot), t(-comp[i]));
    }
    let mut p = x; p[0] += 100_000.0;
    println!("buy $100k shares: change {:10.2}   marginal x 100k {:10.2}", var(&p) - v_tot, marg[0] * 100_000.0);
    let alone: [f64; 3] = std::array::from_fn(|i| z * x[i].abs() * vol[i]);
    println!("standalone VaR $k {}{}{}  sum {}", t(alone[0]), t(alone[1]), t(alone[2]), t(sum(&alone)));
    println!("wrong: shares % of standalone sum {:6.2}", 100.0 * alone[0] / sum(&alone));
    let own: [f64; 3] = std::array::from_fn(|i| x[i] * x[i] * cov[i][i]);
    println!("wrong: shares % of own-variance sum {:6.2}", 100.0 * own[0] / sum(&own));
    let rem: f64 = (0..3).map(|i| { let mut p = x; p[i] = 0.0; v_tot - var(&p) }).sum();
    println!("wrong: remove-one changes summed $k {}", t(rem));
    let cs: Vec<i64> = (0..9).map(|n| 250 * n).collect();
    let curve: Vec<f64> = cs.iter().map(|&c| var(&[x[0], x[1], c as f64 * 100.0 * delta * 100.0])).collect();
    let tang: Vec<f64> = cs.iter().map(|&c| v_tot + marg[2] * (c - 1000) as f64 * 100.0 * delta * 100.0).collect();
    let row = |v: &Vec<f64>| v.iter().map(|y| format!("{:7.2}", y / 1000.0)).collect::<Vec<_>>().join(" ");
    println!("chart contracts {}", cs.iter().map(|c| format!("{:7}", c)).collect::<Vec<_>>().join(" "));
    println!("chart VaR $k    {}", row(&curve));
    println!("chart tangent $k{}", row(&tang));
    for (label, r) in [("try: shares-Acme corr 0", 0.0), ("try: shares-Acme corr 0.9", 0.9)] {
        let mut rr = rho; rr[0][2] = r; rr[2][0] = r;
        let cv = mk(&rr);
        let sv = sd(&x, &cv);
        let sh = x[0] * (0..3).map(|j| cv[0][j] * x[j]).sum::<f64>() / (sv * sv);
        println!("{:<27} VaR {}  shares % {:6.2}", label, t(z * sv), 100.0 * sh);
    }

    assert!((sum(&fd) - v_tot).abs() < 1e-6 * v_tot);
    assert!((0..3).all(|i| (fd[i] - comp[i]).abs() < 1e-6 * v_tot));
    assert!((mc_var - v_tot).abs() < 0.02 * v_tot);
    assert!((0..9).all(|n| { let (i, j) = (n / 3, n % 3);
        (days.iter().map(|d| d.1[i] * d.1[j]).sum::<f64>() / (m as f64 * x[i] * vol[i] * x[j] * vol[j]) - rho[i][j]).abs() < 0.01 }));
    assert!((0..3).all(|i| (mc_es[i] - comp_es[i]).abs() < 0.02 * es));
    assert!((0..3).all(|i| (mc_vc[i] - comp[i]).abs() < 0.03 * v_tot));
    assert!(0.69 < comp[0] / v_tot && comp[0] / v_tot < 0.70);
    assert!(v_tot - var(&[x[0], x[1], 0.0]) < comp[2]);
    println!("ALL CHECKS PASS");
}
