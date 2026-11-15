// Function spaces C and Lp -- the check behind the card.  Rust std only.
// One day of traffic on a 100 km/h road, as the shortfall below 100 km/h.
// Tuesday: a jam, 60 km/h short from 07:00 to 10:00.  Thursday: a crash,
// 90 km/h short from 15:00 to 15:06.  Sizes use the day as a probability
// (each hour weighs 1/24), so every size is in km/h.  Code holds a truncation:
// a grid of 23,040 cells (3.75 s each) and at most 64 daily harmonics.
use std::f64::consts::PI;

const CELLS: usize = 24 * 960; // cell width 1/960 h
const DT: f64 = 24.0 / CELLS as f64;

fn jam(t: f64) -> f64 { if (7.0..10.0).contains(&t) { 60.0 } else { 0.0 } }
fn crash(t: f64) -> f64 { if (15.0..15.1).contains(&t) { 90.0 } else { 0.0 } }
// the jam with onset and clearing over w hours
fn ramp(w: f64, t: f64) -> f64 { 60.0 * 0.0f64.max(1.0f64.min(((t - 7.0) / w).min((10.0 - t) / w))) }

fn total(v: &[f64]) -> f64 { let mut s = 0.0; for x in v { s += x; } s }
// the p-norm, day weighted as a probability
fn avg_p(v: &[f64], p: f64) -> f64 {
    let a: Vec<f64> = v.iter().map(|x| x.abs().powf(p)).collect();
    (total(&a) / v.len() as f64).powf(1.0 / p)
}
fn worst(f: &dyn Fn(f64) -> f64, node: &[f64]) -> f64 { node.iter().map(|&t| f(t).abs()).fold(0.0, f64::max) }
fn sizes(f: &dyn Fn(f64) -> f64, mid: &[f64], node: &[f64]) -> (f64, f64, f64) {
    let m: Vec<f64> = mid.iter().map(|&t| f(t)).collect();
    (avg_p(&m, 1.0), avg_p(&m, 2.0), worst(f, node))
}

const W: f64 = 2.0 * PI / 24.0; // one cycle per day
// Fourier coefficients of the ramped jam (w = 0: jam)
fn coeffs(w: f64, kmax: usize) -> (f64, Vec<(f64, f64)>) {
    let a0 = 60.0 * (3.0 - w) / 24.0;
    let (lo, hi) = (7.0 + w / 2.0, 10.0 - w / 2.0);
    let mut out = vec![];
    for k in 1..=kmax {
        let kf = k as f64;
        let s = if w == 0.0 { 1.0 } else { (kf * W * w / 2.0).sin() / (kf * W * w / 2.0) };
        out.push((60.0 * ((kf * W * hi).sin() - (kf * W * lo).sin()) / (PI * kf) * s,
                  60.0 * ((kf * W * lo).cos() - (kf * W * hi).cos()) / (PI * kf) * s));
    }
    (a0, out)
}

fn fourier_errors(f: &dyn Fn(f64) -> f64, w: f64, energy: f64, ks: &[usize], mid: &[f64], node: &[f64])
    -> Vec<(usize, f64, f64, f64, f64)> {
    let (a0, ab) = coeffs(w, *ks.last().unwrap());
    let (mut sm, mut sn) = (vec![a0; CELLS], vec![a0; CELLS + 1]);
    let (mut rows, mut done, mut par) = (vec![], 0, energy - a0 * a0);
    for &kk in ks {
        for k in done + 1..=kk {
            let (a, b) = ab[k - 1];
            par -= (a * a + b * b) / 2.0; // Parseval: what the first K harmonics carry
            let kf = k as f64;
            for (i, &t) in mid.iter().enumerate() { sm[i] += a * (kf * W * t).cos() + b * (kf * W * t).sin(); }
            for (i, &t) in node.iter().enumerate() { sn[i] += a * (kf * W * t).cos() + b * (kf * W * t).sin(); }
        }
        done = kk;
        let e: Vec<f64> = mid.iter().zip(&sm).map(|(&t, s)| f(t) - s).collect();
        let sup = node.iter().zip(&sn).map(|(&t, s)| (f(t) - s).abs()).fold(0.0, f64::max);
        rows.push((kk, avg_p(&e, 1.0), avg_p(&e, 2.0), par.sqrt(), sup));
    }
    rows
}

fn main() {
    let mid: Vec<f64> = (0..CELLS).map(|i| (i as f64 + 0.5) * DT).collect(); // for averages
    let node: Vec<f64> = (0..=CELLS).map(|i| i as f64 * DT).collect(); // for the worst moment

    println!("bars, the two days under three sizes, km/h");
    let (jt, ct) = (sizes(&jam, &mid, &node), sizes(&crash, &mid, &node));
    for (name, s) in [("jam", jt), ("crash", ct)] {
        println!("{}: average {:.4}  RMS {:.4}  worst {:.4}", name, s.0, s.1, s.2);
    }
    assert!((jt.0 - 60.0 * 3.0 / 24.0).abs() < 1e-9 && (ct.0 - 90.0 * 0.1 / 24.0).abs() < 1e-9);
    assert!((jt.1 - (3600.0f64 * 3.0 / 24.0).sqrt()).abs() < 1e-9 && (ct.1 - (8100.0f64 * 0.1 / 24.0).sqrt()).abs() < 1e-9);
    println!("average ratio jam/crash {:.4}, worst ratio crash/jam {:.4}", jt.0 / ct.0, ct.2 / jt.2);
    println!("totals without the 1/24: jam {:.4} km, crash {:.4} km", 24.0 * jt.0, 24.0 * ct.0);

    println!("rehearsal: N bins, largest ratio worst/average is N (one-bin spike)");
    for n in [24usize, 96, 288, 1440] {
        let mut spike = vec![0.0; n];
        spike[0] = 90.0;
        let r = 90.0 / avg_p(&spike, 1.0);
        println!("N {}: worst/average {:.1}", n, r);
        assert!((r - n as f64).abs() < 1e-9);
    }
    println!("crash seen through bin averages");
    let m: Vec<f64> = mid.iter().map(|&t| crash(t)).collect();
    let mut last = 0.0;
    for n in [24usize, 96, 288] {
        let per = CELLS / n;
        let bins: Vec<f64> = (0..n).map(|i| total(&m[i * per..(i + 1) * per]) / per as f64).collect();
        last = bins.iter().cloned().fold(0.0, f64::max);
        println!("N {}: worst bin {:.4}  average {:.4}", n, last, avg_p(&bins, 1.0));
        assert!((avg_p(&bins, 1.0) - ct.0).abs() < 1e-9); // averaging keeps the average
    }
    assert!((last - 90.0).abs() < 1e-9);

    println!("ramps f_w: distances, by geometry and by the grid");
    for w in [1.0, 0.5, 0.25, 0.125, 0.0625] {
        let d1: Vec<f64> = mid.iter().map(|&t| ramp(w, t) - jam(t)).collect();
        let d2: Vec<f64> = mid.iter().map(|&t| ramp(w, t) - ramp(w / 2.0, t)).collect();
        let (to_jam, step) = (avg_p(&d1, 1.0), avg_p(&d2, 1.0));
        let sup_step = worst(&|t| ramp(w, t) - ramp(w / 2.0, t), &node);
        let sup_jam = worst(&|t| ramp(w, t) - jam(t), &node);
        println!("w {:.4} h: avg to jam {:.6}  avg to next {:.6}  worst to next {:.4}  worst to jam {:.4}",
                 w, to_jam, step, sup_step, sup_jam);
        assert!((to_jam - 2.5 * w).abs() < 1e-9 && (step - 1.25 * w).abs() < 1e-9);
        assert!((sup_step - 30.0).abs() < 1e-9 && (sup_jam - 60.0).abs() < 1e-9);
    }

    let ks = [4usize, 8, 16, 32, 64];
    println!("daily harmonics S_K: average, RMS (grid), RMS (Parseval), worst");
    let jr = fourier_errors(&jam, 0.0, 450.0, &ks, &mid, &node);
    let rr = fourier_errors(&|t| ramp(0.5, t), 0.5, 3600.0 * (3.0 - 4.0 * 0.5 / 3.0) / 24.0, &ks, &mid, &node);
    for (tag, rows) in [("jam", &jr), ("ramp 0.5", &rr)] {
        for &(k, l1, l2, l2p, sup) in rows.iter() {
            println!("{} K {}: {:.4}  {:.4}  {:.4}  {:.4}", tag, k, l1, l2, l2p, sup);
            assert!((l2 - l2p).abs() < 1e-3); // grid against Parseval
        }
    }
    for r in &jr { assert!(r.4 > 29.5); } // a jump keeps every continuous curve 30 away
    for r in &rr { assert!(r.4 <= 5760.0 / (PI * PI * r.0 as f64)); } // M-test bound for the ramped jam
    assert!(jr[4].1 < jr[0].1 / 4.0 && rr[4].4 < rr[0].4 / 8.0);
    println!("M-test bound at K 64: {:.4}", 5760.0 / (PI * PI * 64.0));
    println!("ALL CHECKS PASS");
}
