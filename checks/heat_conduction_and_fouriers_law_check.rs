// Fourier's law and a layered wall -- the check behind the card.  std only, no crates.
// A 300 mm filled cavity wall: plaster, aircrete block, mineral wool, brick.
// Road 1: thermal resistances in series, q = (T_in - T_out) / sum of R.
// Road 2: the transient heat equation, stepped in time from a wrong start
//         until it settles; it never uses the series formula.
// Road 3: the same time-stepper on one brick slab, against the exact
//         separation-of-variables series.
use std::f64::consts::PI;

const T_IN: f64 = 20.0; // room air, C
const T_OUT: f64 = 0.0; // outside air, C
const AREA: f64 = 10.0; // wall area, m^2
const RSI: f64 = 0.13; // inside surface film, m^2 K/W (CIBSE Guide A)
const RSE: f64 = 0.04; // outside surface film
const R_AIR_GAP: f64 = 0.18; // unventilated 100 mm air cavity, m^2 K/W (CIBSE Guide A)

#[derive(Clone, Copy)]
struct Layer { name: &'static str, d: f64, k: f64, rho: f64, c: f64 }
const fn lay(name: &'static str, d: f64, k: f64, rho: f64, c: f64) -> Layer { Layer { name, d, k, rho, c } }
// thickness m, k W/(m K), density kg/m^3, c J/(kg K); inside face first
const WALL: [Layer; 4] = [lay("plaster", 0.015, 0.40, 1000.0, 1000.0), lay("aircrete block", 0.085, 0.15, 600.0, 1000.0),
    lay("mineral wool", 0.100, 0.035, 25.0, 1030.0), lay("brick", 0.100, 0.77, 1700.0, 800.0)];

fn flux(layers: &[Layer], t_in: f64, t_out: f64, films: bool) -> (f64, f64) { // road 1, W/m^2
    let r = layers.iter().map(|l| l.d / l.k).sum::<f64>() + if films { RSI + RSE } else { 0.0 };
    ((t_in - t_out) / r, r)
}

fn grid(layers: &[Layer], dx: f64) -> (Vec<f64>, Vec<f64>, Vec<f64>) {
    let (mut ks, mut caps) = (vec![], vec![]);
    for l in layers {
        for _ in 0..(l.d / dx).round() as usize { ks.push(l.k); caps.push(l.rho * l.c * dx); }
    }
    let links = ks.windows(2).map(|w| 1.0 / (dx / (2.0 * w[0]) + dx / (2.0 * w[1]))).collect();
    (ks, caps, links)
}

fn step_wall(mut temps: Vec<f64>, ks: &[f64], caps: &[f64], links: &[f64], dx: f64, t_in: f64, t_out: f64,
             seconds: f64, dt: f64, every: usize, rec: &mut Vec<(f64, f64, f64)>, films: (f64, f64)) -> (Vec<f64>, f64, f64) {
    let g_in = 1.0 / (films.0 + dx / (2.0 * ks[0]));
    let g_out = 1.0 / (films.1 + dx / (2.0 * ks[ks.len() - 1]));
    let n = temps.len();
    for s in 0..(seconds / dt).round() as usize {
        let q: Vec<f64> = links.iter().enumerate().map(|(i, g)| g * (temps[i] - temps[i + 1])).collect();
        let (q_in, q_out) = (g_in * (t_in - temps[0]), g_out * (temps[n - 1] - t_out));
        let mut new = temps.clone();
        for i in 0..n { // heat in minus heat out, over the cell's capacity
            let left = if i == 0 { q_in } else { q[i - 1] };
            let right = if i == n - 1 { q_out } else { q[i] };
            new[i] += dt * (left - right) / caps[i];
        }
        temps = new;
        if every > 0 && (s + 1) % every == 0 {
            let q_in = g_in * (t_in - temps[0]); // the room face sits one film below the room air
            rec.push((q_in, g_out * (temps[n - 1] - t_out), t_in - films.0 * q_in));
        }
    }
    let (a, b) = (g_in * (t_in - temps[0]), g_out * (temps[n - 1] - t_out));
    (temps, a, b)
}

fn slab_fd(n: usize, seconds: f64, dt: f64) -> f64 { // road 3: the same stepper on a brick slab, 20 C, faces held at 0 C
    let h = WALL[3].d / n as f64;
    let (ks, caps, links) = grid(&WALL[3..], h);
    let (temps, _, _) = step_wall(vec![20.0; n], &ks, &caps, &links, h, 0.0, 0.0, seconds, dt, 0, &mut vec![], (0.0, 0.0));
    (temps[n / 2 - 1] + temps[n / 2]) / 2.0
}

fn slab_series(seconds: f64, kap: f64) -> f64 { // sum over odd n
    let d = WALL[3].d;
    (1..400).step_by(2).map(|n| { let nf = n as f64;
        80.0 / (nf * PI) * (nf * PI / 2.0).sin() * (-kap * (nf * PI / d).powi(2) * seconds).exp() }).sum()
}

fn main() {
    let (q, r_tot) = flux(&WALL, T_IN, T_OUT, true);
    println!("{:<34}{:10.4} m^2 K/W", "total resistance R", r_tot);
    println!("{:<34}{:10.4} W/(m^2 K)", "U = 1/R", 1.0 / r_tot);
    println!("{:<34}{:10.4} W/m^2", "1 series formula, q", q);
    println!("{:<34}{:10.2} W", "  through 10 m^2 of wall", q * AREA);
    let mut t = T_IN - q * RSI;
    let mut faces = vec![];
    println!("{:<34}{:10.3} C", "inside surface", t);
    for l in WALL.iter() {
        let drop = q * l.d / l.k;
        println!("  {:<16}R {:7.4}  drop {:7.3} K  share {:5.1} %", l.name, l.d / l.k, drop, 100.0 * drop / (T_IN - T_OUT));
        faces.push(t);
        t -= drop;
    }
    faces.push(t);
    println!("{:<34}{:10.3} C", "outside surface", t);
    let (dx, dt) = (0.005, 5.0);
    let (ks, caps, links) = grid(&WALL, dx);
    let mut none = vec![];
    let (temps, q_in, q_out) = step_wall(vec![10.0; ks.len()], &ks, &caps, &links, dx, T_IN, T_OUT, 72.0 * 3600.0, dt, 0, &mut none, (RSI, RSE));
    println!("{:<34}{:10.4}{:10.4} W/m^2", "2 time-stepped, 72 h, q in, q out", q_in, q_out);
    let fd_wool = temps[19] - q_in * dx / (2.0 * 0.15); // last block cell, half a cell on to the wool
    println!("{:<34}{:10.4}{:10.4} C", "  block-wool face, stepped, formula", fd_wool, faces[2]);
    let diffus: Vec<f64> = WALL.iter().map(|l| l.k / (l.rho * l.c)).collect();
    println!("diffusivity, 1e-7 m^2/s {}", diffus.iter().map(|a| format!("{:7.3}", 1e7 * a)).collect::<Vec<_>>().join(" "));

    let exact = slab_series(1800.0, diffus[3]);
    let (coarse, fine) = (slab_fd(20, 1800.0, 2.0), slab_fd(40, 1800.0, 0.5));
    println!("{:<34}{:10.4} C", "3 brick centre at 30 min, series", exact);
    println!("{:<34}{:10.4}{:10.4} C", "  stepped, 20 and 40 cells", coarse, fine);
    println!("{:<34}{:10.2}", "  error ratio, coarse/fine", (coarse - exact) / (fine - exact));

    let mut rec = vec![(q, q, T_IN - RSI * q)]; // cold snap: outside drops to -10 C; a reading every 10 min
    step_wall(temps, &ks, &caps, &links, dx, T_IN, -10.0, 24.0 * 3600.0, dt, 120, &mut rec, (RSI, RSE));
    let q_new = flux(&WALL, T_IN, -10.0, true).0;
    let mid = (q + q_new) / 2.0; // halfway flux, crossed between two 10-minute readings
    let i = rec.iter().position(|r| r.0 > mid).unwrap();
    let half = (i as f64 - 1.0 + (mid - rec[i - 1].0) / (rec[i].0 - rec[i - 1].0)) / 6.0;
    let two_h: Vec<_> = rec.iter().step_by(12).cloned().collect();
    println!("{:<34}{:10.4} W/m^2", "cold snap: new steady q", q_new);
    println!("{:<34}{:10.2} h", "  q in passes halfway after", half);
    println!("{:<15}{}", "chart, hours", (0..13).map(|i| format!("{:6}", 2 * i)).collect::<String>());
    println!("{:<15}{}", "chart, q in", two_h.iter().map(|r| format!("{:6.2}", r.0)).collect::<String>());
    println!("{:<15}{}", "chart, q out", two_h.iter().map(|r| format!("{:6.2}", r.1)).collect::<String>());
    println!("{:<34}{:10.3} C", "inside surface at 24 h", two_h[12].2);

    let avg_k = WALL.iter().map(|l| l.d * l.k).sum::<f64>() / WALL.iter().map(|l| l.d).sum::<f64>();
    let wrong_avg = flux(&[lay("mean", 0.3, avg_k, 0.0, 0.0)], T_IN, T_OUT, true).0;
    let wrong_films = flux(&WALL, T_IN, T_OUT, false).0;
    let empty = [WALL[0], WALL[1], lay("air gap", 0.1, 0.1 / R_AIR_GAP, 1.2, 1005.0), WALL[3]];
    let q_empty = flux(&empty, T_IN, T_OUT, true).0;
    let q_still = flux(&[WALL[0], WALL[1], lay("still air", 0.1, 0.026, 1.2, 1005.0), WALL[3]], T_IN, T_OUT, true).0;
    println!("{:<34}{:10.4} W/m^2", "wrong: thickness-averaged k", wrong_avg);
    println!("{:<34}{:10.4} W/m^2", "wrong: surface films left out", wrong_films);
    println!("{:<34}{:10.4} W/m^2{:9.2} W", "empty cavity, real R 0.18", q_empty, q_empty * AREA);
    println!("{:<34}{:10.4} W/m^2", "wrong: empty cavity as still air", q_still);
    let try_wool = flux(&[WALL[0], WALL[1], lay("wool", 0.2, 0.035, 25.0, 1030.0), WALL[3]], T_IN, T_OUT, true).0;
    let try_dense = flux(&[WALL[0], lay("dense block", 0.085, 1.13, 2000.0, 1000.0), WALL[2], WALL[3]], T_IN, T_OUT, true).0;
    println!("{:<34}{:10.4} W/m^2", "try: 200 mm of wool", try_wool);
    println!("{:<34}{:10.4} W/m^2", "try: dense block, k 1.13", try_dense);
    let mut xs = vec![0.0];
    for i in 0..4 { xs.push(WALL[..i + 1].iter().map(|l| l.d).sum::<f64>()); }
    println!("figure, x px {} | y px {}", xs.iter().map(|x| format!("{:.1}", 60.0 + 1100.0 * x)).collect::<Vec<_>>().join(" "),
        faces.iter().map(|f| format!("{:.1}", 250.0 - 10.0 * f)).collect::<Vec<_>>().join(" "));

    assert!((q_in - q).abs() < 1e-4 && (q_out - q).abs() < 1e-4, "stepped wall must settle on the series flux");
    assert!((fd_wool - faces[2]).abs() < 1e-3, "interface temperature, stepped against formula");
    assert!((fine - exact).abs() < 0.02, "time-stepper against the separation-of-variables series");
    let ratio = (coarse - exact) / (fine - exact);
    assert!(3.0 < ratio && ratio < 5.0, "halving the cells cuts the error about four times");
    assert!((rec[rec.len() - 1].0 - q_new).abs() < (q - q_new).abs(), "after the cold snap the flux heads to the new steady value");
    assert!(q_still < q && q < q_empty, "still air would beat the wool; the real gap loses far more");
    println!("ALL CHECKS PASS");
}
