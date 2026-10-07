// Reflection principle for Brownian motion -- the same check as reflection_principle_and_running_maximum_check.py.
// Standard library only, no crates.  A pollen grain's position W_t along one axis, in um, variance t after t s.
// Road 1: the formula 2(1 - Phi(3/sqrt 10)), Phi by Simpson's rule.  Road 2: exact coin-flip walks, no mirror.
// Road 3: seeded Gaussian paths (SplitMix64 + Box-Muller, written out) on grids of 1, 0.1 and 0.01 seconds.
use std::f64::consts::PI;

const A: f64 = 3.0;
const T: f64 = 10.0;
fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }
fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    s * h / 3.0
}
fn big_phi(x: f64) -> f64 {
    if x > 12.0 { return 1.0; }
    if x < -12.0 { return 0.0; }
    0.5 + simpson(phi, 0.0, x, 2000)
}
fn touch(a: f64, t: f64) -> f64 { 2.0 * (1.0 - big_phi(a / t.sqrt())) }
fn drift_touch(a: f64, t: f64, mu: f64) -> f64 {
    1.0 - big_phi((a - mu * t) / t.sqrt()) + (2.0 * mu * a).exp() * big_phi((-a - mu * t) / t.sqrt())
}
fn either_side(a: f64, t: f64) -> f64 {
    let stay = (-8i32..9).map(|k| (if k % 2 == 0 { 1.0 } else { -1.0 })
        * (big_phi((2 * k + 1) as f64 * a / t.sqrt()) - big_phi((2 * k - 1) as f64 * a / t.sqrt())))
        .fold(0.0, |s, v| s + v);
    1.0 - stay
}
fn walk(n: usize, j: i64, p: f64, two_sided: bool) -> f64 {
    let lo = if two_sided { -j + 1 } else { -(j + (12.0 * (n as f64).sqrt()) as i64 + 2) };
    let len = (j - lo) as usize;
    let mut w = vec![0.0f64; len];
    w[(-lo) as usize] = 1.0;
    let mut hit = 0.0;
    for _ in 0..n {
        hit += p * w[len - 1] + if two_sided { (1.0 - p) * w[0] } else { 0.0 };
        w = (0..len).map(|i| (if i > 0 { p * w[i - 1] } else { 0.0 })
            + (if i + 1 < len { (1.0 - p) * w[i + 1] } else { 0.0 })).collect();
    }
    hit
}
struct Rng(u64);
impl Rng {
    fn u01(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        (((z ^ (z >> 31)) >> 11) as f64 + 0.5) / 9007199254740992.0
    }
}
fn row(name: &str, v: f64) { println!("{:<44}{:>11.6}", name, v); }
fn join<I: Iterator<Item = String>>(it: I) -> String { it.collect::<Vec<_>>().join(" ") }

fn main() {
    let (paths, steps) = (10000usize, 1000usize);
    let grids = [1usize, 10, 100];
    let mut rng = Rng(20260930);
    let (mut grid_hits, mut max_sum, mut max_sq, mut joint) = ([0usize; 3], 0.0f64, 0.0f64, 0usize);
    let (mut first_sec, mut first_fine) = ([0usize; 11], [0usize; 11]);
    for _ in 0..paths {
        let (mut x, mut k, mut fine_t, mut sec_t) = (0.0f64, 0usize, 0usize, 0usize);
        let mut tops = [0.0f64; 3];
        while k < steps {
            let r = (-2.0 * rng.u01().ln()).sqrt();
            let th = 2.0 * PI * rng.u01();
            for z in [r * th.cos(), r * th.sin()] {
                x += 0.1 * z; k += 1;
                for (gi, g) in grids.iter().enumerate() { if k % g == 0 && x > tops[gi] { tops[gi] = x; } }
                if fine_t == 0 && x >= A { fine_t = (k + 99) / 100; }
                if sec_t == 0 && k % 100 == 0 && x >= A { sec_t = k / 100; }
            }
        }
        for gi in 0..3 { if tops[gi] >= A { grid_hits[gi] += 1; } }
        max_sum += tops[0]; max_sq += tops[0] * tops[0];
        if tops[0] >= A && x <= 1.0 { joint += 1; }
        if fine_t > 0 { first_fine[fine_t] += 1; }
        if sec_t > 0 { first_sec[sec_t] += 1; }
    }
    let est = |c: usize| { let p = c as f64 / paths as f64; (p, (p * (1.0 - p) / paths as f64).sqrt()) };
    let beta = 1.4603545088 / (2.0 * PI).sqrt();

    let p1 = touch(A, T);
    row("sqrt(t), typical spread at 10 s", T.sqrt());
    row("a / sqrt(t)", A / T.sqrt());
    row("Phi(a / sqrt(t)), Simpson", big_phi(A / T.sqrt()));
    row("1 formula 2(1 - Phi)", p1);
    row("  ends at or above 3, P(W_10 >= 3)", 1.0 - big_phi(A / T.sqrt()));
    println!("2 coin walk, exact      steps n     P(reach)      error");
    let mut errs = Vec::new();
    for j in [3i64, 6, 12, 24, 48, 96] {
        let n = (10 * j * j / 9) as usize;
        let v = walk(n, j, 0.5, false);
        errs.push((v - p1).abs());
        println!("{:<24}{:>7}   {:>10.6}   {:>+9.6}", "", n, v, v - p1);
    }
    row("BETA = -zeta(1/2) / sqrt(2 pi)", beta);
    println!("3 simulation, 10000 paths   grid      P(reach)   std err   grid-corrected formula");
    let mut sims = Vec::new();
    for (gi, dt) in [(2usize, 1.0f64), (1, 0.1), (0, 0.01)] {
        let (p, se) = est(grid_hits[gi]);
        let c = touch(A + beta * dt.sqrt(), T);
        sims.push((p, se, c));
        println!("{:<28}{:>4.2} s   {:>9.4}   {:>7.4}   {:>9.4}", "", dt, p, se, c);
    }
    let (pj, sej) = est(joint);
    row("joint: reach 3, end <= 1; P(W_10 >= 5)", 1.0 - big_phi(5.0 / T.sqrt()));
    row("  grid-corrected, 0.01 s", 1.0 - big_phi((2.0 * (A + beta * 0.1) - 1.0) / T.sqrt()));
    println!("{:<44}{:>11.4}{:>8.4}", "  simulated, 0.01 s grid, std err", pj, sej);
    let mean_f = (2.0 * T / PI).sqrt();
    let mean_i = simpson(|m| if m > 0.0 { touch(m, T) } else { 1.0 }, 0.0, 40.0, 400);
    row("mean of M_10: sqrt(2t/pi)", mean_f);
    row("  integral of P(M_10 >= m) dm", mean_i);
    let m_bar = max_sum / paths as f64;
    let m_se = ((max_sq / paths as f64 - m_bar * m_bar) / paths as f64).sqrt();
    println!("{:<44}{:>11.4}{:>8.4}", "  simulated 0.01 s + BETA sqrt(dt), std err", m_bar + beta * 0.1, m_se);
    let (mut lo, mut hi) = (0.0f64, 10.0f64);
    for _ in 0..60 {
        let mid = (lo + hi) / 2.0;
        if touch(mid, T) > 0.5 { lo = mid; } else { hi = mid; }
    }
    row("median of M_10, bisection", lo);
    row("  median / sqrt(t)", lo / T.sqrt());
    let two_dp = walk(10240, 96, 0.5, true);
    let drift_dp = walk(10240, 96, 0.5 * (1.0 + 0.2 * 3.0 / 96.0), false);
    row("wrong: double for either side", 2.0 * p1);
    row("  right, mirrors in both walls", either_side(A, T));
    row("  right, coin walk n = 10240", two_dp);
    row("wrong: mirror with drift 0.2 / s", touch(A - 0.2 * T, T));
    row("  right, drift formula", drift_touch(A, T, 0.2));
    row("  right, coin walk n = 10240", drift_dp);
    row("wrong: formula at level -3, below the start", touch(-A, T));
    row("try: level 6", touch(6.0, T));
    row("try: 40 seconds", touch(A, 40.0));
    row("try: 1000 seconds", touch(A, 1000.0));
    println!("chart, level m          {}", join((0..9).map(|m| format!("{:>6}", m))));
    println!("chart, P(M_10 >= m) %   {}", join((0..9).map(|m| format!("{:6.2}", 100.0 * if m > 0 { touch(m as f64, T) } else { 1.0 }))));
    println!("chart, coin walk 2560 % {}", join((0..9).map(|m| format!("{:6.2}", 100.0 * if m > 0 { walk(2560, 16 * m, 0.5, false) } else { 1.0 }))));
    println!("chart, P(W_10 >= m) %   {}", join((0..9).map(|m| format!("{:6.2}", 100.0 * (1.0 - big_phi(m as f64 / T.sqrt()))))));
    println!("chart, second t         {}", join((1..11).map(|t| format!("{:>6}", t))));
    println!("chart, P(tau_3 <= t) %  {}", join((1..11).map(|t| format!("{:6.2}", 100.0 * touch(A, t as f64)))));
    let cum = |v: &[usize; 11], t: usize| 100.0 * v[..=t].iter().sum::<usize>() as f64 / paths as f64;
    println!("chart, sim 0.01 s grid %{}", join((1..11).map(|t| format!("{:6.2}", cum(&first_fine, t)))));
    println!("chart, sim every sec %  {}", join((1..11).map(|t| format!("{:6.2}", cum(&first_sec, t)))));
    let path = [0.0f64, 0.6, 0.2, 1.1, 1.6, 1.2, 2.0, 2.4, 3.0, 2.5, 2.8, 2.1, 1.5, 1.9, 1.2, 0.7, 1.3, 0.9, 0.4, 1.1, 1.0];
    let hit = path.iter().position(|&v| v == A).unwrap();      // hand-drawn, 0.5 s grid, first at 3 at t = 4 s
    let mir = |i: usize, v: f64| if i <= hit { v } else { 2.0 * A - v };
    println!("figure, path            {}", join(path.iter().map(|v| format!("{:.1}", v))));
    println!("figure, mirrored        {}", join(path.iter().enumerate().map(|(i, &v)| format!("{:.1}", mir(i, v)))));
    println!("figure, x px            {}", join((0..path.len()).map(|i| format!("{}", 40 + 15 * i))));
    println!("figure, y px path       {}", join(path.iter().map(|v| format!("{:.1}", 185.0 - 25.0 * v))));
    println!("figure, y px mirrored   {}", join(path.iter().enumerate().map(|(i, &v)| format!("{:.1}", 185.0 - 25.0 * mir(i, v)))));

    let tail = &errs[1..];
    assert!((walk(10240, 96, 0.5, false) - p1).abs() < 0.005 && tail.windows(2).all(|w| w[0] >= w[1]), "coin walks close in on the formula");
    assert!(sims.iter().all(|&(p, se, c)| (p - c).abs() < 4.0 * se), "each grid within 4 std errs of the grid-corrected formula");
    assert!((pj - (1.0 - big_phi((2.0 * (A + beta * 0.1) - 1.0) / T.sqrt()))).abs() < 4.0 * sej, "joint law: simulation vs grid-corrected mirror");
    assert!((mean_i - mean_f).abs() < 1e-6 && (m_bar + beta * 0.1 - mean_f).abs() < 4.0 * m_se, "mean of the maximum, three ways");
    assert!((two_dp - either_side(A, T)).abs() < 0.005, "two walls: image series vs coin walk");
    assert!((drift_dp - drift_touch(A, T, 0.2)).abs() < 0.005, "drift: formula vs coin walk");
    assert!((lo - 0.6744897502 * T.sqrt()).abs() < 1e-6, "median of M_10 = median of |W_10|");
    println!("ALL CHECKS PASS");
}
