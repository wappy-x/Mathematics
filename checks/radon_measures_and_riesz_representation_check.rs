// Radon measures and the Riesz representation theorem -- the same check as the Python.
// No crates. The rule is Lambda(f) = f(0) + (integral of f over [0, 1]).
// The code treats Lambda as a black box: it builds the measure mu from Lambda alone,
// with bumps that fit inside open sets and tents that sit over compact sets, then checks
// that integrating against mu gives Lambda back, by a layer-cake road and a Stieltjes road.
const N: usize = 120000; // Simpson pieces on [0, 1]
const D: f64 = 1e-4; // ramp width of bumps and tents

fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n {
        s += (if i % 2 == 1 { 4.0 } else { 2.0 }) * f(a + i as f64 * h);
    }
    s * h / 3.0
}

fn lam(f: &dyn Fn(f64) -> f64) -> f64 { f(0.0) + simpson(f, 0.0, 1.0, N) }

fn lam_signed(f: &dyn Fn(f64) -> f64) -> f64 { f(0.0) - simpson(f, 0.0, 1.0, N) }

fn clamp(v: f64) -> f64 { v.min(1.0).max(0.0) }

// 0 outside (p + d, q - d), 1 on [p + 2d, q - 2d]
fn bump(p: f64, q: f64, d: f64) -> impl Fn(f64) -> f64 {
    move |x: f64| clamp((x - p - d).min(q - d - x) / d)
}

// 1 on [p, q], falling to 0 at distance d outside it
fn tent(p: f64, q: f64, d: f64) -> impl Fn(f64) -> f64 {
    move |x: f64| clamp(1.0 - (p - x).max(x - q).max(0.0) / d)
}

// the answer to test: point mass at 0 plus length on [0, 1]
fn mu_formula(p: f64, q: f64, closed: bool) -> f64 {
    let holds_0 = if closed { p <= 0.0 && 0.0 <= q } else { p < 0.0 && 0.0 < q };
    (if holds_0 { 1.0 } else { 0.0 }) + (q.min(1.0) - p.max(0.0)).max(0.0)
}

fn f(x: f64) -> f64 { (1.0 - x * x).max(0.0) } // (1 - x^2) on [-1, 1], 0 outside

fn row(label: &str, vals: &[f64], dp: usize) {
    let parts: Vec<String> = vals.iter().map(|v| format!("{:.*}", dp, v)).collect();
    println!("{}{}", label, parts.join(" "));
}

// 1 at 0, -1 on [e, 1], 0 outside (-e, 1 + e), straight between
fn norm_test(e: f64) -> impl Fn(f64) -> f64 {
    move |x: f64| {
        if x < 0.0 { clamp(1.0 + x / e) }
        else if x <= e { 1.0 - 2.0 * x / e }
        else if x <= 1.0 { -1.0 }
        else { (-1.0 + (x - 1.0) / e).min(0.0) }
    }
}

fn main() {
    println!("rule: Lambda(f) = f(0) + integral of f over [0, 1]; ramps of width d = 0.0001");
    let xs: Vec<f64> = (0..17).map(|i| -0.5 + 0.125 * i as f64).collect();
    row("chart x: ", &xs, 3);
    let t4 = tent(0.0, 1.0, 0.25);
    let b8 = bump(0.0, 1.0, 0.125);
    row("chart tent, 1 on [0, 1], ramps 0.25: ", &xs.iter().map(|&x| t4(x)).collect::<Vec<_>>(), 2);
    row("chart bump, 0 outside (0.125, 0.875): ", &xs.iter().map(|&x| b8(x)).collect::<Vec<_>>(), 2);
    let tents: Vec<f64> = [1.0, 10.0, 100.0].iter().map(|&k: &f64| lam(&tent(0.0, 1.0, 1.0 / k))).collect();
    let ks = [4.0, 8.0, 100.0, 1000.0];
    let bumps: Vec<f64> = ks.iter().map(|&k: &f64| lam(&bump(0.0, 1.0, 1.0 / k))).collect();
    let spikes: Vec<f64> = [4.0, 100.0].iter().map(|&k: &f64| lam(&tent(0.0, 0.0, 1.0 / k))).collect();
    row("tents over [0, 1], k = 1, 10, 100: Lambda = ", &tents, 6);
    row("bumps inside (0, 1), k = 4, 8, 100, 1000: Lambda = ", &bumps, 6);
    row("spikes over {0}, k = 4, 100: Lambda = ", &spikes, 6);
    let sets = [("[0, 1]", 0.0, 1.0, true), ("(0, 1)", 0.0, 1.0, false), ("{0}", 0.0, 0.0, true),
                ("(-1, 0)", -1.0, 0.0, false), ("(-1, 0.5)", -1.0, 0.5, false), ("[-2, 2]", -2.0, 2.0, true)];
    for &(name, p, q, closed) in sets.iter() {
        let built = if closed { lam(&tent(p, q, D)) } else { lam(&bump(p, q, D)) };
        let exact = mu_formula(p, q, closed);
        println!("mu{} built from Lambda: {:.3}; point mass plus length: {:.3}", name, built, exact);
        assert!((built - exact).abs() < 1e-3); // Lambda's measure is delta_0 + length
    }
    let fx: Vec<f64> = (0..9).map(|i| -0.5 + 0.25 * i as f64).collect();
    row("F(x) = mu((-inf, x]) at x = -0.5, -0.25, ..., 1.5: ",
        &fx.iter().map(|&x| lam(&tent(-2.0, x, D))).collect::<Vec<_>>(), 3);
    let exact = 1.0 + 2.0 / 3.0;
    let road1 = lam(&f);
    let m = 200; // layer cake: mu({f > t}) by bumps
    let road2 = (0..m).map(|j| {
        let a = (1.0 - (j as f64 + 0.5) / m as f64).sqrt();
        lam(&bump(-a, a, D))
    }).sum::<f64>() / m as f64;
    let n = 300; // Stieltjes sums on (-1.5, 1.5]
    let grid: Vec<f64> = (0..=n).map(|i| -1.5 + 3.0 * i as f64 / n as f64).collect();
    let fg: Vec<f64> = grid.iter().map(|&x| lam(&tent(-2.0, x, D))).collect();
    let road3: f64 = (0..n).map(|i| f((grid[i] + grid[i + 1]) / 2.0) * (fg[i + 1] - fg[i])).sum();
    println!("test function (1 - x^2) on [-1, 1]: exact 1 + 2/3 = {:.6}", exact);
    println!("road 1, Lambda(f) directly: {:.6}", road1);
    println!("road 2, layer cake, {} levels of mu(f > t) built from bumps: {:.6}", m, road2);
    println!("road 3, Stieltjes sum of f against F, {} pieces: {:.7}", n, road3);
    let bound = lam(&tent(-1.0, 1.0, 1.0));
    println!("bound on [-1, 1]: |Lambda(f)| <= Lambda(phi) x max|f| = {:.3} x 1; Lambda(f) = {:.3}", bound, road1);
    println!("signed rule: Lambda_s(f) = f(0) - integral of f over [0, 1]");
    let sb: Vec<f64> = [4.0, 8.0, 100.0].iter().map(|&k: &f64| lam_signed(&bump(0.0, 1.0, 1.0 / k))).collect();
    row("bumps inside (0, 1), k = 4, 8, 100: Lambda_s = ", &sb, 3);
    let sup = sb.iter().fold(0.0_f64, |a, &b| a.max(b));
    println!("sup over 0 <= g <= 1 inside (0, 1), g = 0 included: {:.3}; signed mass of (0, 1): -1.000", sup);
    let es = [0.1, 0.01];
    let nt: Vec<f64> = es.iter().map(|&e| lam_signed(&norm_test(e))).collect();
    row("norm test, |g| <= 1, e = 0.1, 0.01: Lambda_s(g) = ", &nt, 4);
    let mass = lam_signed(&tent(-2.0, 2.0, 1.0));
    println!("signed mass of R: {:.3}; total variation |mu|(R) = 1 + 1 = 2", mass);
    let uk = [10.0, 100.0, 1000.0];
    let ups: Vec<f64> = uk.iter().map(|&k: &f64| lam_signed(&tent(0.0, 0.0, 1.0 / k))).collect();
    row("positive part at the tent over [0, 1], spikes k = 10, 100, 1000: ", &ups, 4);
    let lebesgue: Vec<f64> = [10.0, 100.0].iter()
        .map(|&r: &f64| simpson(&tent(-r, r, 1.0), -r - 1.0, r + 1.0, 4 * (r as usize + 1))).collect();
    row("length rule on plateaus of height 1 over [-R, R], R = 10, 100: ", &lebesgue, 1);
    println!("mistakes:");
    println!("  mu((0, 1)) from outside, by tents over [0, 1]: {:.3} (true 1.000)", tents[2]);
    println!("  length only, integral of f over [0, 1]: {:.3} (true {:.3})", simpson(&f, 0.0, 1.0, N), exact);
    println!("  norm of Lambda_s read as |mu(R)|: {:.3} (true 2.000)", mass.abs());
    println!("  sup over bumps for Lambda_s on (0, 1): {:.3} (true -1.000)", sup);
    assert!((road1 - exact).abs() < 1e-12); // Simpson is exact on a quadratic
    assert!((road2 - exact).abs() < 1e-3 && (road3 - exact).abs() < 1e-3); // three roads agree
    assert!(bumps.iter().zip(ks.iter()).all(|(b, k)| (b - (1.0 - 3.0 / k)).abs() < 1e-9));
    assert!(nt.iter().zip(es.iter()).all(|(v, e)| (v - (2.0 - e)).abs() < 1e-9));
    assert!(ups.iter().zip(uk.iter()).all(|(v, k)| (v - (1.0 - 1.0 / (2.0 * k))).abs() < 1e-9));
    assert!((lebesgue[1] - 201.0).abs() < 1e-9 && mass.abs() < 1e-9);
    println!("ALL CHECKS PASS");
}
