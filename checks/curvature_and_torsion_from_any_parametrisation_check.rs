// Curvature and torsion at any speed -- the check behind the card.  std only.
// A ski run bends right round a hill while dropping: a helix of radius a = 40 m that
// drops c = 9 m per radian.  Skier A passes the apex at 10.25 m/s, speeding up.
// Roads: closed form by arc length; the any-speed formulas on three different
// parametrisations; central differences on 20 Hz positions at two step sizes.
type V = [f64; 3];
type G = (f64, f64);

fn sub(p: V, q: V) -> V { [p[0] - q[0], p[1] - q[1], p[2] - q[2]] }
fn scale(k: f64, p: V) -> V { [k * p[0], k * p[1], k * p[2]] }
fn dot(p: V, q: V) -> f64 { p[0] * q[0] + p[1] * q[1] + p[2] * q[2] }
fn cross(p: V, q: V) -> V { [p[1] * q[2] - p[2] * q[1], p[2] * q[0] - p[0] * q[2], p[0] * q[1] - p[1] * q[0]] }
fn norm(p: V) -> f64 { dot(p, p).sqrt() }
fn vecd(p: V, d: usize) -> String {
    let s: Vec<String> = p.iter().map(|&a| format!("{:.*}", d, if a.abs() < 0.5 * 10f64.powi(-(d as i32)) { 0.0 } else { a })).collect();
    format!("({})", s.join(", "))
}
fn vec(p: V) -> String { vecd(p, 4) }

fn pos(g: G, th: f64) -> V { [g.0 * th.cos(), -g.0 * th.sin(), -g.1 * th] }

// chain rule: r(t) = r(theta(t)); d1, d2, d3 are theta's first three time derivatives
fn derivs(g: G, s: (f64, f64, f64, f64)) -> (V, V, V) {
    let (th, d1, d2, d3) = s;
    let (r, c) = g;
    let r1 = [-r * th.sin(), -r * th.cos(), -c];
    let r2 = [-r * th.cos(), r * th.sin(), 0.0];
    let r3 = [r * th.sin(), r * th.cos(), 0.0];
    let v = scale(d1, r1);
    let mut acc = [0.0; 3];
    let mut jerk = [0.0; 3];
    for i in 0..3 {
        acc[i] = d2 * r1[i] + d1 * d1 * r2[i];
        jerk[i] = d3 * r1[i] + 3.0 * d1 * d2 * r2[i] + d1.powi(3) * r3[i];
    }
    (v, acc, jerk)
}

fn kappa_tau(d: (V, V, V)) -> (f64, f64) {
    let w = cross(d.0, d.1);
    (norm(w) / norm(d.0).powi(3), dot(w, d.2) / dot(w, w))
}

// angle turned, and its time derivatives
fn skier(g: G, v0: f64, a: f64, t: f64) -> (f64, f64, f64, f64) {
    let l = g.0.hypot(g.1); // metres of track per radian of turn
    ((v0 * t + a * t * t / 2.0) / l, (v0 + a * t) / l, a / l, 0.0)
}

fn closed(g: G) -> (f64, f64) { let q = g.0 * g.0 + g.1 * g.1; (g.0 / q, g.1 / q) }

const GB: G = (40.0, 9.0);
const V0: f64 = 10.25;
const A0: f64 = 0.82;

// road 4: positions only, 20 Hz samples, n = -40..40, with SplitMix64 jitter in [-noise, noise]
fn track(noise: f64) -> Vec<V> {
    let mut s: u64 = 2026;
    let mut out = Vec::new();
    for n in -40i32..41 {
        let p = pos(GB, skier(GB, V0, A0, n as f64 * 0.05).0);
        let mut q = p;
        for i in 0..3 {
            s = s.wrapping_add(0x9E3779B97F4A7C15);
            let mut z = (s ^ (s >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
            z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
            let u = ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0;
            q[i] = p[i] + noise * (2.0 * u - 1.0);
        }
        out.push(q);
    }
    out
}

fn by_steps(pts: &Vec<V>, m: i32) -> (V, V, V) {
    let at = |n: i32| pts[(n + 40) as usize];
    let h = 0.05 * m as f64;
    let (p2, p1, p0, n1, n2) = (at(2 * m), at(m), at(0), at(-m), at(-2 * m));
    let v = scale(1.0 / (2.0 * h), sub(p1, n1));
    let mut acc = [0.0; 3];
    let mut jerk = [0.0; 3];
    for i in 0..3 {
        acc[i] = (p1[i] - 2.0 * p0[i] + n1[i]) * (1.0 / (h * h));
        jerk[i] = (p2[i] - 2.0 * p1[i] + 2.0 * n1[i] - n2[i]) * (1.0 / (2.0 * h.powi(3)));
    }
    (v, acc, jerk)
}

fn main() {
    let (k0, t0) = closed(GB);
    println!("bend: a = 40 m, drop c = 9 m per radian, a^2 + c^2 = {:.0}, L = {:.0} m per radian", GB.0 * GB.0 + GB.1 * GB.1, GB.0.hypot(GB.1));
    println!("road 1, closed form: kappa = {:.10} 1/m, tau = {:.10} 1/m, radius {:.3} m, tau/kappa = {:.3}", k0, t0, 1.0 / k0, t0 / k0);

    let s0 = skier(GB, V0, A0, 0.0);
    println!("grade {:.1}%, skier A at the apex: thetadot = {:.2} rad/s, thetaddot = {:.2} rad/s^2, position {}", 100.0 * GB.1 / GB.0, s0.1, s0.2, vec(pos(GB, s0.0)));
    println!("thetadot^2 = {:.4}, 3 thetadot thetaddot = {:.3}, thetadot^3 = {:.6}", s0.1 * s0.1, 3.0 * s0.1 * s0.2, s0.1.powi(3));
    let (a1, a2, a3) = derivs(GB, (0.0, 1.0, 0.0, 0.0));
    println!("angle clock at the apex: r_th, r_thth, r_ththth = {}, {}, {}", vec(a1), vec(a2), vec(a3));
    let (v, acc, jerk) = derivs(GB, s0);
    let w = cross(v, acc);
    println!("skier A at t = 0 s: rdot = {}, rddot = {}, rdddot = {}", vec(v), vec(acc), vec(jerk));
    println!("rdot x rddot = {}, |rdot x rddot| = {:.4}, |rdot|^3 = {:.6}", vec(w), norm(w), norm(v).powi(3));
    println!("det = (rdot x rddot).rdddot = {:.6}, |rdot x rddot|^2 = {:.6}", dot(w, jerk), dot(w, w));
    let (k, t) = kappa_tau((v, acc, jerk));
    println!("road 2, any-speed formulas: kappa = {:.10} 1/m, tau = {:.10} 1/m", k, t);
    assert!((k - k0).abs() < 1e-12 && (t - t0).abs() < 1e-12);
    let k_wrong = norm(acc) / norm(v).powi(2);
    let t_wrong = dot(w, jerk) / norm(w);
    let sw = |p: V| -> V { [p[1], p[0], p[2]] }; // north, east, up
    let swap = (sw(v), sw(acc), sw(jerk));

    println!("road 3, same track, three clocks: label, time s, speed m/s, kappa, tau");
    let clocks: [(&str, f64, f64, &[f64]); 3] =
        [("A", V0, A0, &[-4.0, 4.0, 8.0]), ("B steady", 5.125, 0.0, &[0.0, 6.0]), ("angle", 41.0, 0.0, &[0.5])];
    for (label, v0, a, ts) in clocks.iter() {
        for &tt in ts.iter() {
            let s = skier(GB, *v0, *a, tt);
            let (k, t) = kappa_tau(derivs(GB, s));
            println!("  {}, t = {:.1}, speed {:.3}, kappa {:.10}, tau {:.10}", label, tt, s.1 * 41.0, k, t);
            assert!((k - k0).abs() < 1e-12 && (t - t0).abs() < 1e-12);
        }
    }

    let clean = track(0.0);
    for n in [-4i32, -2, 0, 2, 4] {
        println!("road 4, fix at t = {:.1} s: {} m", n as f64 * 0.05, vecd(clean[(n + 40) as usize], 8));
    }
    let mut errs: Vec<[f64; 3]> = Vec::new();
    for m in [2, 1] {
        let d = by_steps(&clean, m);
        let (k, t) = kappa_tau(d);
        errs.push([k - k0, t - t0, norm(sub(d.2, jerk))]); // jerk: skier A's, by the chain rule
        let wd = cross(d.0, d.1);
        println!("road 4, h = {:.2} s: rdot = {}, rddot = {}, rdddot = {}", 0.05 * m as f64, vec(d.0), vec(d.1), vec(d.2));
        println!("  rdot x rddot = {}, length {:.4}, |rdot|^3 = {:.4}, det {:.6}, length^2 {:.6}", vec(wd), norm(wd), norm(d.0).powi(3), dot(wd, d.2), dot(wd, wd));
        println!("  kappa {:.10} (error {:.10}), tau {:.10} (error {:.10}), jerk off by {:.6}", k, k - k0, t, t - t0, errs[errs.len() - 1][2]);
    }
    let (rk, rt, rj) = (errs[0][0] / errs[1][0], errs[0][1] / errs[1][1], errs[0][2] / errs[1][2]);
    println!("halving h divides the errors by {:.3}, {:.3} and {:.3}", rk, rt, rj);
    assert!(rk > 3.5 && rk < 4.5 && rt > 3.5 && rt < 4.5 && errs[1][1].abs() < 1e-5);
    assert!(rj > 3.5 && rj < 4.5 && errs[1][2] < 1e-3); // the jerk from positions meets the chain-rule jerk

    println!("what breaks:");
    println!("  |rddot|/|rdot|^2 = {:.6} ({:+.1}%), |rddot| = {:.5} m/s^2", k_wrong, 100.0 * (k_wrong / k0 - 1.0), k_wrong * 10.25f64.powi(2));
    println!("  det over |rdot x rddot|, not squared = {:.6} ({:.2} times)", t_wrong, t_wrong / t0);
    assert!(k_wrong / k0 - 1.0 > 0.01 && t_wrong / t0 > 10.0);
    let (k, t) = kappa_tau(swap);
    println!("  axes swapped to north, east, up: kappa {:.6}, tau {:.6}", k, t);
    assert!((k - k0).abs() < 1e-12 && (t + t0).abs() < 1e-12);
    let (v, acc, _) = derivs(GB, skier(GB, 0.0, A0, 0.0));
    println!("  skier stopped at t = 0: |rdot x rddot| = {:.4}, |rdot|^3 = {:.4}, 0/0",
             norm(cross(v, acc)), norm(v).powi(3));
    println!("chart, 1 cm GPS jitter at 20 Hz: h in s, kappa, tau");
    let noisy = track(0.01);
    for m in [1, 2, 4, 8, 16] {
        let (k, t) = kappa_tau(by_steps(&noisy, m));
        println!("  h = {:.2}: kappa {:.6}, tau {:.6}", 0.05 * m as f64, k, t);
        if m == 1 { assert!((t - t0).abs() > 0.5 * t0); }
    }
    println!("try changing:");
    let tries: [(&str, G, f64); 3] = [("flat bend, c = 0", (40.0, 0.0), A0), ("steep spiral, c = 40", (40.0, 40.0), A0),
                                       ("skier braking, -0.82 m/s^2", GB, -A0)];
    for (label, g, a) in tries.iter() {
        let (k, t) = kappa_tau(derivs(*g, skier(*g, V0, *a, 2.0)));
        println!("  {}: kappa {:.6}, tau {:.6}", label, k, t);
        assert!((k - closed(*g).0).abs() < 1e-12 && (t - closed(*g).1).abs() < 1e-12);
    }
    println!("ALL CHECKS PASS");
}
