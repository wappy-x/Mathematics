// Flux limiters: TVD schemes on a square slug of pollutant -- the check behind the card.
// std only.  Road 1: the exact answer (after one lap round the loop the slug is back where it
// began).  Road 2: total variation measured every step, against Harten's coefficients C computed
// from the limiter.  Road 3: a second scheme, MUSCL slopes with an SSP Runge-Kutta step.
// Road 4: errors at four grid sizes.
use std::f64::consts::PI;

const C: f64 = 2.0; const H: f64 = 0.25; const NU: f64 = 0.5; const N: usize = 40;
const TVD: [&str; 3] = ["minmod", "van Leer", "superbee"];

fn lim(s: &str, r: f64) -> f64 {
    match s {
        "upwind" => 0.0,
        "Lax-Wendroff" => 1.0,
        "minmod" => 0.0f64.max(1.0f64.min(r)),
        "van Leer" => (r + r.abs()) / (1.0 + r.abs()),
        "superbee" => 0.0f64.max((2.0 * r).min(1.0)).max(r.min(2.0)),
        _ => if r > 0.0 { 1.0 } else { 0.0 }, // "phi = 1 for r > 0"
    }
}
fn jumps(u: &[f64]) -> Vec<f64> { (0..u.len()).map(|j| u[(j + 1) % u.len()] - u[j]).collect() }
fn tv(u: &[f64]) -> f64 { jumps(u).iter().map(|d| d.abs()).sum() }
fn prev(j: usize, n: usize) -> usize { (j + n - 1) % n }

fn step(u: &[f64], s: &str, nu: f64, cs: Option<&mut [f64; 3]>) -> Vec<f64> {
    let n = u.len();
    let d = jumps(u);
    let g: Vec<f64> = (0..n).map(|j| if d[j] != 0.0 { lim(s, d[prev(j, n)] / d[j]) * d[j] } else { 0.0 }).collect();
    let new: Vec<f64> = (0..n).map(|j| { let p = prev(j, n);
        u[j] - nu * ((u[j] + (1.0 - nu) / 2.0 * g[j]) - (u[p] + (1.0 - nu) / 2.0 * g[p])) }).collect();
    if let Some(cs) = cs { // incremental form u_j - C_(j-1/2) d_(j-1/2), built separately
        for j in 0..n { let p = prev(j, n);
            if d[p] != 0.0 {
                let c = nu * (1.0 + (1.0 - nu) / 2.0 * (g[j] - g[p]) / d[p]);
                cs[0] = cs[0].min(c); cs[1] = cs[1].max(c);
                cs[2] = cs[2].max((u[j] - c * d[p] - new[j]).abs());
            }
        }
    }
    new
}
fn mm(a: f64, b: f64) -> f64 { if a * b <= 0.0 { 0.0 } else if a.abs() < b.abs() { a } else { b } }
fn muscl(u: &[f64], nu: f64) -> Vec<f64> { // forward Euler on minmod-limited slopes, one step
    let n = u.len();
    let d = jumps(u);
    let e: Vec<f64> = (0..n).map(|j| u[j] + 0.5 * mm(d[prev(j, n)], d[j])).collect();
    (0..n).map(|j| u[j] - nu * (e[j] - e[prev(j, n)])).collect()
}
fn ssprk2(u: &[f64]) -> Vec<f64> { let w = muscl(&muscl(u, NU), NU); u.iter().zip(&w).map(|(a, b)| 0.5 * a + 0.5 * b).collect() }

fn lap(u0: &[f64], f: &dyn Fn(&[f64]) -> Vec<f64>, n: usize) -> (Vec<f64>, f64, bool) {
    let (mut u, mut top, mut mono) = (u0.to_vec(), tv(u0), true);
    for _ in 0..n { let v = f(&u); mono = mono && tv(&v) <= tv(&u) + 1e-12; top = top.max(tv(&v)); u = v; }
    (u, top, mono)
}
fn mx(u: &[f64]) -> f64 { u.iter().cloned().fold(f64::MIN, f64::max) }
fn mn(u: &[f64]) -> f64 { u.iter().cloned().fold(f64::MAX, f64::min) }
fn l1(u: &[f64], v: &[f64], h: f64) -> f64 { h * u.iter().zip(v).map(|(a, b)| (a - b).abs()).sum::<f64>() }
fn px(r: f64, p: f64) -> String { format!("({:.0}, {:.1})", 40.0 + 100.0 * r, 200.0 - 80.0 * p) }

fn main() {
    let dt = NU * H / C;
    let slug: Vec<f64> = (0..N).map(|j| if (10..20).contains(&j) { 1.0 } else { 0.0 }).collect();
    let steps = (N as f64 / NU).round() as usize;
    println!("river {:.1} km/h, cell h = {:.2} km, Courant number nu = {:.2}, step {:.4} h, {} cells on a 10 km loop (Flow problems' 0.1 h step gave nu = {:.2})",
             C, H, NU, dt, N, C * 0.1 / H);
    println!("one lap = {} steps = {:.2} h; slug 1 mg/L in the 10 cells at 2.50 to 4.75 km; total variation TV = {:.4}", steps, steps as f64 * dt, tv(&slug));
    let v: Vec<f64> = TVD.iter().map(|s| lim(s, 0.5)).collect();
    println!("phi(0.5): minmod {:.4}, van Leer {:.4}, superbee {:.4}", v[0], v[1], v[2]);
    assert!((v[0] - 0.5).abs() < 1e-15 && (v[1] - 2.0 / 3.0).abs() < 1e-15 && (v[2] - 1.0).abs() < 1e-15);
    let rs: Vec<f64> = (-200..1001).map(|k| k as f64 / 100.0).collect();
    for s in ["Lax-Wendroff", "minmod", "van Leer", "superbee"] {
        let out: Vec<f64> = rs.iter().cloned().filter(|&r| !(0.0 <= lim(s, r) && lim(s, r) <= 0.0f64.max((2.0 * r).min(2.0)))).collect();
        let inside = rs.iter().all(|&r| (0.0 <= lim(s, r) && lim(s, r) <= (2.0 * r).min(2.0) + 1e-15) || (r <= 0.0 && lim(s, r) == 0.0));
        let msg = if out.is_empty() { "yes".to_string() } else { format!("no, outside for r <= {:.2}", out[out.len() - 1]) };
        println!("  {:<12} inside Sweby's TVD region for r = -2..10: {}", s, msg);
        assert!(inside == TVD.contains(&s));
    }
    println!("first step by hand, cells at 2.25 | 2.50 | 4.75 | 5.00 km:");
    for s in ["Lax-Wendroff", "minmod"] {
        let u1 = step(&slug, s, NU, None);
        println!("  {:<12} {:.4} | {:.4} | {:.4} | {:.4}; TV {:.4}", s, u1[9], u1[10], u1[19], u1[20], tv(&u1));
    }
    let lw1 = step(&slug, "Lax-Wendroff", NU, None);
    assert!((lw1[19] - (1.0 + NU / 2.0 - NU * NU / 2.0)).abs() < 1e-15 && (tv(&lw1) - 2.5).abs() < 1e-12);
    let m1 = step(&slug, "minmod", NU, None);
    let r20 = (m1[20] - m1[19]) / (m1[21] - m1[20]);
    let m2 = step(&m1, "minmod", NU, None)[20];
    println!("second minmod step at 5.00 km: r = {:.4}, phi = {:.4}, value {:.4}", r20, lim("minmod", r20), m2);
    assert!((m2 - 0.8125).abs() < 1e-15); // by hand: 0.5 + 0.25 + 0.0625
    let s1 = ssprk2(&slug);
    println!("MUSCL + SSP-RK2, step 1, cells at 5.00 | 5.25 km: {:.4} | {:.4}", s1[20], s1[21]);
    assert!((s1[20] - 7.0 / 16.0).abs() < 1e-15 && (s1[21] - 1.0 / 16.0).abs() < 1e-15); // by hand: 0.875 / 2, 0.125 / 2

    println!("one lap | largest TV on the way | TV at end | highest | lowest | L1 error mg/L km | mass");
    let mut ends: Vec<(&str, Vec<f64>)> = vec![];
    for s in ["upwind", "Lax-Wendroff", "minmod", "van Leer", "superbee", "MUSCL + SSP-RK2"] {
        let f: Box<dyn Fn(&[f64]) -> Vec<f64>> = if s.starts_with('M') { Box::new(ssprk2) } else { Box::new(move |u: &[f64]| step(u, s, NU, None)) };
        let (u, top, mono) = lap(&slug, &*f, steps);
        let mass = H * u.iter().sum::<f64>();
        println!("  {:<15} {:.4} | {:.4} | {:.4} | {:.4} | {:.4} | {:.4}", s, top, tv(&u), mx(&u), mn(&u), l1(&u, &slug, H), mass);
        assert!((mass - 2.5).abs() < 1e-12);
        if s != "Lax-Wendroff" { assert!(mono && top <= 2.0 + 1e-12 && -1e-12 <= mn(&u) && mx(&u) <= 1.0 + 1e-12); }
        ends.push((s, u));
    }
    let end = |name: &str| ends.iter().find(|e| e.0 == name).unwrap().1.clone();
    assert!(tv(&end("Lax-Wendroff")) > 3.0 && mx(&end("Lax-Wendroff")) > 1.15);
    assert!(l1(&end("minmod"), &slug, H) < 0.6 * l1(&end("upwind"), &slug, H));

    for s in ["minmod", "van Leer", "superbee", "Lax-Wendroff"] {
        let mut cs = [9.0, -9.0, 0.0];
        let mut u = slug.clone();
        for _ in 0..steps { u = step(&u, s, NU, Some(&mut cs)); }
        println!("Harten's C over the lap, {:<12}: {:.4} to {:.4}; incremental form matches to {:.1e}", s, cs[0], cs[1], cs[2]);
        assert!(cs[2] < 1e-14);
        assert!((NU * NU - 1e-12 <= cs[0] && cs[1] <= NU * (2.0 - NU) + 1e-12) == TVD.contains(&s));
    }
    println!("bound for any limiter in the region: nu^2 = {:.4} to nu(2 - nu) = {:.4}", NU * NU, NU * (2.0 - NU));

    println!("what breaks:");
    for (s, nu) in [("phi = 1 for r > 0", NU), ("minmod", 1.2)] {
        let (u, top, mono) = lap(&slug, &|w: &[f64]| step(w, s, nu, None), (N as f64 / nu).round() as usize);
        println!("  {} at nu = {:.1}: largest TV {:.4}, highest {:.4}, lowest {:.4}", s, nu, top, mx(&u), mn(&u));
        assert!(top > 2.2 && !mono);
    }

    println!("smooth wave 0.5 + 0.5 sin(2 pi x / 10 km), one lap: L1 error | max error at N = 40, 80, 160, 320");
    let mut ords: Vec<(f64, f64)> = vec![];
    for s in ["upwind", "Lax-Wendroff", "minmod", "van Leer", "superbee"] {
        let (mut e1, mut e8, mut top) = (vec![], vec![], vec![]);
        for n in [40usize, 80, 160, 320] {
            let h = 10.0 / n as f64;
            let u0: Vec<f64> = (0..n).map(|j| 0.5 + 0.5 * (2.0 * PI * j as f64 * h / 10.0).sin()).collect();
            let mut u = u0.clone();
            for _ in 0..2 * n { u = step(&u, s, NU, None); }
            e1.push(l1(&u, &u0, h));
            e8.push(u.iter().zip(&u0).map(|(a, b)| (a - b).abs()).fold(0.0, f64::max));
            top.push(mx(&u));
        }
        let (p1, p8) = ((e1[2] / e1[3]).log2(), (e8[2] / e8[3]).log2());
        ords.push((p1, p8));
        let cells: Vec<String> = (0..4).map(|i| format!("{:.6}|{:.6}", e1[i], e8[i])).collect();
        println!("  {:<12} {}; orders {:.2} | {:.2}; crest at N = 40: {:.4}", s, cells.join("  "), p1, p8, top[0]);
    }
    assert!((ords[0].0 - 1.0).abs() < 0.1 && (ords[1].0 - 2.0).abs() < 0.05 && (ords[1].1 - 2.0).abs() < 0.05);
    assert!(ords[2].0 > 1.8 && ords[2].1 < 1.5 && ords[3].1 < 1.5);

    let xs: Vec<usize> = (2..25).collect();
    println!("chart, km {}", xs.iter().map(|&j| format!("{:.2}", j as f64 * H)).collect::<Vec<_>>().join(", "));
    for (s, u) in [("exact", slug.clone()), ("Lax-Wendroff", end("Lax-Wendroff")), ("minmod", end("minmod"))] {
        println!("  {}: {}", s, xs.iter().map(|&j| format!("{:.2}", u[j])).collect::<Vec<_>>().join(", "));
    }
    println!("figure, Sweby diagram, x = 40 + 100 r, y = 200 - 80 phi: r = 0.5 minmod {}, van Leer {}, superbee {}; r = 3 van Leer {}, superbee {}",
        px(0.5, v[0]), px(0.5, v[1]), px(0.5, v[2]), px(3.0, lim("van Leer", 3.0)), px(3.0, lim("superbee", 3.0)));
    println!("ALL CHECKS PASS");
}
