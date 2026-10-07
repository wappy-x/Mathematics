// Error propagation and sensitivity -- the same check in Rust, std only, no crates.
// Cd = 2F / (rho v^2 A) for a cyclist in a full-size wind tunnel.  Road 1: hand
// partial derivatives.  Road 2: central differences.  Road 3: the exponent rule.
// Road 4: a Monte Carlo of 200,000 rigs, SplitMix64 and Box-Muller written out.
// Compile: rustc --edition 2021 -O error_propagation_and_sensitivity_check.rs -o /tmp/<dir>/chk
use std::f64::consts::PI;

const X: [f64; 4] = [24.0, 12.0, 0.400, 1.204]; // F in N, v in m/s, A in m^2, rho in kg/m^3
const U: [f64; 4] = [0.24, 0.18, 0.008, 0.006]; // standard uncertainties, same units
const NAMES: [&str; 4] = ["F", "v", "A", "rho"];
const UNITS: [&str; 4] = ["N", "m/s", "m^2", "kg/m^3"]; // partials are per this unit
const EXPO: [i32; 4] = [1, -2, -1, -1]; // Cd = 2 F^1 v^-2 A^-1 rho^-1

fn cd(x: &[f64; 4]) -> f64 { 2.0 * x[0] / (x[3] * x[1] * x[1] * x[2]) }

struct SplitMix64 { s: u64 }
impl SplitMix64 {
    fn next(&mut self) -> u64 {
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    }
    fn unif(&mut self) -> f64 { ((self.next() >> 11) + 1) as f64 / 9007199254740992.0 } // in (0, 1]
    fn normal(&mut self) -> f64 { // Box-Muller, cosine half
        let r = (-2.0 * self.unif().ln()).sqrt();
        r * (2.0 * PI * self.unif()).cos()
    }
}

fn monte_carlo(u: &[f64; 4], n: usize, seed: u64) -> (f64, f64) {
    let mut g = SplitMix64 { s: seed };
    let (mut s1, mut s2) = (0.0, 0.0);
    for _ in 0..n {
        let mut x = [0.0; 4];
        for i in 0..4 { x[i] = X[i] + u[i] * g.normal(); }
        let y = cd(&x);
        s1 += y; s2 += y * y;
    }
    let mean = s1 / n as f64;
    (mean, ((s2 - n as f64 * mean * mean) / (n as f64 - 1.0)).sqrt())
}

fn rel_with(r: &[f64; 4]) -> f64 {
    100.0 * (0..4).map(|i| (EXPO[i] as f64 * r[i]).powi(2)).sum::<f64>().sqrt()
}

fn main() {
    let c0 = cd(&X);
    // road 1: partial derivatives worked by hand
    let d1 = [2.0 / (X[3] * X[1].powi(2) * X[2]), -4.0 * X[0] / (X[3] * X[1].powi(3) * X[2]),
              -2.0 * X[0] / (X[3] * X[1].powi(2) * X[2].powi(2)), -2.0 * X[0] / (X[3].powi(2) * X[1].powi(2) * X[2])];
    // road 2: central differences, step one millionth of each input
    let mut d2 = [0.0; 4];
    for i in 0..4 {
        let h = X[i] * 1e-6;
        let (mut up, mut dn) = (X, X);
        up[i] += h; dn[i] -= h;
        d2[i] = (cd(&up) - cd(&dn)) / (2.0 * h);
    }
    let terms: Vec<f64> = (0..4).map(|i| d1[i].abs() * U[i]).collect();
    let u_quad = terms.iter().map(|t| t * t).sum::<f64>().sqrt();
    let u_num = (0..4).map(|i| (d2[i] * U[i]).powi(2)).sum::<f64>().sqrt();
    let rel = [U[0] / X[0], U[1] / X[1], U[2] / X[2], U[3] / X[3]];
    let u_rel = (0..4).map(|i| (EXPO[i] as f64 * rel[i]).powi(2)).sum::<f64>().sqrt(); // road 3
    let share: Vec<f64> = terms.iter().map(|t| 100.0 * t * t / u_quad.powi(2)).collect();
    // second-order mean: Cd + 1/2 sum of (second partial) u^2; second partials by hand
    let d2nd = [0.0, 6.0 * c0 / X[1].powi(2), 2.0 * c0 / X[2].powi(2), 2.0 * c0 / X[3].powi(2)];
    let mean2 = c0 + 0.5 * (0..4).map(|i| d2nd[i] * U[i].powi(2)).sum::<f64>();
    let n = 200000usize;
    let (mc_mean, mc_sd) = monte_carlo(&U, n, 20260930);

    println!("Cd = 2F/(rho v^2 A)                 {:10.6}", c0);
    println!("by hand: 2F = {:.3} N, rho v^2 A = {:.4} N", 2.0 * X[0], X[3] * X[1].powi(2) * X[2]);
    println!("input   value      u        u/value   partial dCd/dx  by differences  exponent  unit of x");
    for i in 0..4 {
        println!("{:<6}{:8.3}{:9.4}{:9.2} %{:15.6}{:16.6}{:8}  {}", NAMES[i], X[i], U[i], 100.0 * rel[i], d1[i], d2[i], EXPO[i], UNITS[i]);
    }
    println!("budget  term |dCd/dx| u   rel term   squared, %^2   share of variance");
    for i in 0..4 {
        let r = 100.0 * EXPO[i].abs() as f64 * rel[i];
        println!("{:<6}{:12.6}{:11.2} %{:14.4}{:12.2} %", NAMES[i], terms[i], r, r * r, share[i]);
    }
    println!("sum of squared rel terms, %^2       {:10.4}", (0..4).map(|i| (100.0 * EXPO[i] as f64 * rel[i]).powi(2)).sum::<f64>());
    println!("u(Cd) road 1, hand partials         {:10.6}", u_quad);
    println!("u(Cd) road 2, central differences   {:10.6}", u_num);
    println!("u(Cd) road 3, exponent rule         {:10.6}   = {:.3} % of Cd", u_rel * c0, 100.0 * u_rel);
    println!("95% band, Cd +- 2u                  {:10.6} to {:.6}", c0 - 2.0 * u_quad, c0 + 2.0 * u_quad);
    println!("road 4, Monte Carlo {} rigs, seed 20260930", n);
    println!("  sd of Cd                          {:10.6}   standard error {:.6}", mc_sd, mc_sd / (2.0 * n as f64).sqrt());
    println!("  mean of Cd                        {:10.6}   standard error {:.6}", mc_mean, mc_sd / (n as f64).sqrt());
    println!("  second-order mean                 {:10.6}", mean2);

    // what breaks, and what to buy
    let lin_sum: f64 = terms.iter().sum();
    let no_square = c0 * (0..4).map(|i| (rel[i] * if i == 1 { 1.0 } else { EXPO[i].abs() as f64 }).powi(2)).sum::<f64>().sqrt();
    let corner = cd(&[X[0] + U[0], X[1] - U[1], X[2] - U[2], X[3] - U[3]]) - c0;
    println!("wrong: add terms, no quadrature     {:10.6}   = {:.3} %", lin_sum, 100.0 * lin_sum / c0);
    println!("wrong: speed exponent 1, not 2      {:10.6}   = {:.3} %", no_square, 100.0 * no_square / c0);
    println!("wrong: worst corner, all inputs     {:10.6}", corner);
    println!("buy: load cell 0.1 %                {:10.3} %", rel_with(&[0.001, rel[1], rel[2], rel[3]]));
    println!("buy: speed 0.5 %                    {:10.3} %", rel_with(&[rel[0], 0.005, rel[2], rel[3]]));
    println!("buy: area 1.0 %                     {:10.3} %", rel_with(&[rel[0], rel[1], 0.010, rel[3]]));
    // far from small: the same sweep up to a hand-held anemometer, speed uncertainty 15 %
    let steps = [0.0, 2.5, 5.0, 7.5, 10.0, 12.5, 15.0];
    let (mut fo, mut sim) = (Vec::new(), Vec::new());
    let mut far_mean = 0.0;
    for p in steps {
        fo.push(rel_with(&[rel[0], p / 100.0, rel[2], rel[3]]));
        let (m, s) = monte_carlo(&[U[0], p / 100.0 * X[1], U[2], U[3]], n, 20260930);
        far_mean = m;
        sim.push(100.0 * s / c0);
    }
    let far_mean2 = c0 + 0.5 * (d2nd[1] * (0.15 * X[1]).powi(2) + d2nd[2] * U[2].powi(2) + d2nd[3] * U[3].powi(2));
    println!("far: u(v) = 15 %, first order       {:10.3} %", fo[6]);
    println!("far: Monte Carlo sd                 {:10.3} %   mean {:.6}", sim[6], far_mean);
    println!("far: second-order mean              {:10.6}", far_mean2);
    let row = |v: &[f64], prec: usize| v.iter().map(|x| format!("{:6.*}", prec, x)).collect::<Vec<_>>().join(" ");
    println!("chart, u(v) %       {}", row(&steps, 1));
    println!("chart, first order %{}", row(&fo, 2));
    println!("chart, simulated %  {}", row(&sim, 2));
    println!("chart, shares %     {}", row(&share, 2));

    for i in 0..4 { assert!((d1[i] - d2[i]).abs() < 1e-6 * d1[i].abs(), "hand partial vs central difference"); }
    assert!((u_quad - u_rel * c0).abs() < 1e-12, "hand partials vs exponent rule");
    assert!((u_num - u_quad).abs() < 1e-8, "central differences vs hand partials");
    assert!((mc_sd - u_quad).abs() < 0.01 * u_quad, "simulated spread vs first-order u, within 1 %");
    assert!((mc_mean - mean2).abs() < 4.0 * mc_sd / (n as f64).sqrt(), "simulated mean vs second-order mean");
    let top = (0..4).fold(0, |b, i| if share[i] > share[b] { i } else { b });
    assert!(top == 1, "speed dominates the budget");
    assert!(sim[6] > 1.05 * fo[6], "first order fails far out");
    println!("ALL CHECKS PASS");
}
