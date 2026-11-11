// Kirchhoff's laws and equivalent circuits -- the same check as the Python, in Rust.  No crates.
// A 12 V battery, three resistors and a 6-ohm lamp.  Every number quoted on the card is printed here.
// Roads to the lamp: node voltages by elimination, loop currents by elimination, relaxation,
// and the Thevenin/Norton pair, found by open/short tests, by a test current and by hand rules.
use std::collections::{BTreeMap, BTreeSet};

const VS: f64 = 12.0; const R1: f64 = 2.0; const R2: f64 = 6.0; const R3: f64 = 1.5; const RL: f64 = 6.0;
const GND: usize = 0; const TOP: usize = 1; const A: usize = 2; const B: usize = 3;

fn solve(m: &[Vec<f64>], s: &[f64]) -> Vec<f64> {          // Gaussian elimination, partial pivoting
    let n = s.len();
    let mut m: Vec<Vec<f64>> = m.iter().zip(s).map(|(row, &si)| { let mut r = row.clone(); r.push(si); r }).collect();
    for k in 0..n {
        let p = (k..n).fold(k, |best, i| if m[i][k].abs() > m[best][k].abs() { i } else { best });
        m.swap(k, p);
        for i in k + 1..n {
            let f = m[i][k] / m[k][k];
            let rk = m[k].clone();
            for (a, b) in m[i].iter_mut().zip(rk.iter()) { *a -= f * b; }
        }
    }
    let mut x = vec![0.0; n];
    for i in (0..n).rev() {
        let tail: f64 = (i + 1..n).map(|j| m[i][j] * x[j]).sum();
        x[i] = (m[i][n] - tail) / m[i][i];
    }
    x
}

type Parts = Vec<(usize, usize, f64)>;

// parts: (node, node, ohms).  fixed: node -> volts.  inject: node -> amps pushed in from outside.
fn nodal(parts: &Parts, fixed: &BTreeMap<usize, f64>, inject: &BTreeMap<usize, f64>)
    -> (BTreeMap<usize, f64>, Vec<Vec<f64>>, Vec<f64>) {
    let all: BTreeSet<usize> = parts.iter().flat_map(|&(a, b, _)| [a, b]).collect();
    let free: Vec<usize> = all.into_iter().filter(|n| !fixed.contains_key(n)).collect();
    let ix: BTreeMap<usize, usize> = free.iter().enumerate().map(|(i, &n)| (n, i)).collect();
    let mut g = vec![vec![0.0; free.len()]; free.len()];
    let mut s: Vec<f64> = free.iter().map(|n| *inject.get(n).unwrap_or(&0.0)).collect();
    for &(a, b, r) in parts {                               // KCL at each free node, Ohm's law for each part
        let c = 1.0 / r;
        for (here, there) in [(a, b), (b, a)] {
            if let Some(&h) = ix.get(&here) {
                g[h][h] += c;
                match ix.get(&there) { Some(&t) => g[h][t] -= c, None => s[h] += c * fixed[&there] }
            }
        }
    }
    let x = solve(&g, &s);
    let mut v = fixed.clone();
    for (n, val) in free.iter().zip(x) { v.insert(*n, val); }
    (v, g, s)
}

fn circuit(vs: f64, r1: f64, r2: f64, r3: f64, rl: f64) -> (Parts, BTreeMap<usize, f64>) {
    let mut parts = vec![(TOP, A, r1), (A, B, r3)];
    if r2 != 0.0 { parts.push((A, GND, r2)); }
    if rl != 0.0 { parts.push((B, GND, rl)); }
    (parts, BTreeMap::from([(GND, 0.0), (TOP, vs)]))
}

fn lamp_amps(vs: f64, r2: f64) -> f64 {
    let (p, f) = circuit(vs, R1, r2, R3, RL);
    nodal(&p, &f, &BTreeMap::new()).0[&B] / RL
}

fn show(name: &str, v: f64) { println!("{:<44} {:>11.6}", name, v); }

fn main() {
    let none = BTreeMap::new();
    // ---- road 1: node voltages, G v = s, solved by elimination ----
    let (p, f) = circuit(VS, R1, R2, R3, RL);
    let (v, g, s) = nodal(&p, &f, &none);
    let cs: String = [R1, R2, R3, RL].iter().map(|r| format!("{:6.1}", 6.0 / r)).collect();
    println!("conductances x 6: R1, R2, R3, lamp      {}", cs);
    for (name, row, rhs) in [("row A", &g[0], s[0]), ("row B", &g[1], s[1])] {
        println!("nodal matrix x 6, {}            {:8.3} {:8.3} | {:7.3}", name, 6.0 * row[0], 6.0 * row[1], 6.0 * rhs);
    }
    let m = 6.0 * g[1][0] / (6.0 * g[0][0]);
    println!("after row B - ({:.1}) x row A               {:8.3} {:8.3} | {:7.3}",
             m, 0.0, 6.0 * g[1][1] - m * 6.0 * g[0][1], 6.0 * s[1] - m * 6.0 * s[0]);
    let (va, vb) = (v[&A], v[&B]);
    show("1 node voltages: V_A", va); show("1 node voltages: V_B", vb);
    let (i1, i2, i3, il) = ((VS - va) / R1, va / R2, (va - vb) / R3, vb / RL);
    show("current through R1 (the battery)", i1); show("current through R2", i2);
    show("current through R3", i3); show("current through the lamp", il);
    show("KCL at A: out through R2 and R3", i2 + i3);

    // ---- road 2: loop currents J1 (left loop), J2 (right loop), KVL in each ----
    let lp = [vec![R1 + R2, -R2], vec![-R2, R2 + R3 + RL]];
    for (name, row, rhs) in [("row 1", &lp[0], VS), ("row 2", &lp[1], 0.0)] {
        println!("loop matrix, {}                 {:8.3} {:8.3} | {:7.3}", name, row[0], row[1], rhs);
    }
    let j = solve(&lp, &[VS, 0.0]);
    show("2 loop currents: J1", j[0]); show("2 loop currents: J2 (the lamp)", j[1]);
    show("KVL, left loop: drops on R1 and R2", j[0] * R1 + (j[0] - j[1]) * R2);
    show("KVL, right loop: drop on R2", (j[0] - j[1]) * R2); show("KVL, right loop: drops on R3 and lamp", j[1] * (R3 + RL));

    // ---- road 3: relaxation -- each node becomes the conductance-weighted average of its neighbours ----
    let (g1, g2, g3, gl) = (1.0 / R1, 1.0 / R2, 1.0 / R3, 1.0 / RL);
    let mut rb = 0.0_f64;
    for _ in 0..200 {
        let ra = (g1 * VS + g3 * rb) / (g1 + g2 + g3);
        rb = (g3 * ra) / (g3 + gl);
    }
    show("3 relaxation, 200 sweeps: V_B", rb);

    // ---- power: what the battery gives equals what the parts burn ----
    let p_batt = VS * i1;
    let p_parts = i1 * i1 * R1 + i2 * i2 * R2 + i3 * i3 * R3 + il * il * RL;
    show("battery power, watts", p_batt); show("sum of I^2 R over the four parts", p_parts);
    show("lamp power, watts", il * il * RL);
    show("power burned in the network, lamp aside", p_batt - il * il * RL);

    // ---- the equivalent seen by the lamp, three ways ----
    let (p, f) = circuit(VS, R1, R2, R3, 0.0);
    let voc = nodal(&p, &f, &none).0[&B];                     // lamp unclipped
    let (p, mut f) = circuit(VS, R1, R2, R3, 0.0); f.insert(B, 0.0);
    let isc = (nodal(&p, &f, &none).0[&A] - 0.0) / R3;         // lamp replaced by a wire
    let (p, f) = circuit(0.0, R1, R2, R3, 0.0);                // battery killed, 1 A pushed into B
    let v_test = nodal(&p, &f, &BTreeMap::from([(B, 1.0)])).0[&B];
    let vth_rule = VS * R2 / (R1 + R2);
    let rth_rule = R1 * R2 / (R1 + R2) + R3;
    show("open-circuit voltage V_th", voc); show("short-circuit current I_N", isc);
    show("R_th = V_th / I_N", voc / isc); show("R_th by 1 A test current, battery killed", v_test);
    show("R1 || R2 = 2 x 6/(2+6)", R1 * R2 / (R1 + R2));
    show("V_th by the divider 12 x 6/(2+6)", vth_rule); show("R_th by rules (2 || 6) + 1.5", rth_rule);
    show("lamp current, Thevenin 9/(3+6)", voc / (rth_rule + RL));
    show("lamp current, Norton 3 x 3/(3+6)", isc * rth_rule / (rth_rule + RL));
    let i_eq = voc / (rth_rule + RL);
    show("power in the Thevenin 3 ohms at 1 A", i_eq * i_eq * rth_rule);

    // ---- swap the lamp: Thevenin formula against a fresh nodal solve ----
    println!("lamp ohms   amps, Thevenin   amps, full solve   lamp watts");
    let mut sweep_pts = Vec::new();
    for rl in [1.0_f64, 2.0, 3.0, 4.0, 6.0, 8.0, 12.0] {
        let i_th = voc / (rth_rule + rl);
        let (p, f) = circuit(VS, R1, R2, R3, rl);
        let i_full = nodal(&p, &f, &none).0[&B] / rl;
        sweep_pts.push((i_th, i_full));
        println!("{:9.1} {:16.6} {:18.6} {:12.6}", rl, i_th, i_full, i_th * i_th * rl);
    }

    // ---- what breaks ----
    let bad = solve(&[vec![g1 + g2 - g3, g3], vec![-g3, g3 + gl]], &[g1 * VS, 0.0]);   // R3 signed backwards at A
    show("wrong: R3 signed backwards at A, lamp amps", bad[1] / RL);
    show("wrong: R1 + R2 taken in series, ohms", R1 + R2);
    show("wrong: R_th = 2 + 6 + 1.5, lamp amps", voc / (R1 + R2 + R3 + RL));
    show("wrong: R_th, battery a gap: 6 + 1.5", R2 + R3);
    show("wrong: battery killed as a gap, lamp amps", voc / (R2 + R3 + RL));
    show("wrong: V_th = 12 V, lamp amps", VS / (rth_rule + RL)); let (p, f) = circuit(VS, R1, R2, R3, 0.6); show("cold lamp at switch-on, 0.6 ohm: amps", nodal(&p, &f, &none).0[&B] / 0.6);

    // ---- try changing ----
    show("try: battery 24 V, lamp amps", lamp_amps(24.0, R2));
    show("try: R2 = 3 ohms, lamp amps", lamp_amps(VS, 3.0));
    show("try: R2 removed, lamp amps", lamp_amps(VS, 0.0));
    let (p, f) = circuit(VS, R1, 0.0, R3, 0.0); show("try: R2 removed, V_th", nodal(&p, &f, &none).0[&B]);
    let (p, f) = circuit(0.0, R1, 0.0, R3, 0.0); show("try: R2 removed, R_th by 1 A test", nodal(&p, &f, &BTreeMap::from([(B, 1.0)])).0[&B]);

    assert!((vb - 6.0).abs() < 1e-12 && (va - 7.5).abs() < 1e-12, "nodal road vs the hand answer 7.5 V, 6 V");
    assert!((j[1] - il).abs() < 1e-12 && (j[0] - i1).abs() < 1e-12, "loop-current road vs node-voltage road");
    assert!((rb - vb).abs() < 1e-9, "relaxation vs elimination");
    assert!((i1 - i2 - i3).abs() < 1e-12, "KCL at A, on the node road");
    assert!((VS - j[0] * R1 - (j[0] - j[1]) * R2).abs() < 1e-12, "KVL round the left loop, on the loop road");
    assert!((p_batt - p_parts).abs() < 1e-9, "power in equals power burned");
    assert!((voc - vth_rule).abs() < 1e-12 && (voc / isc - rth_rule).abs() < 1e-12, "open/short tests vs hand rules");
    assert!((v_test - rth_rule).abs() < 1e-12, "test-current R_th vs hand rules");
    assert!(sweep_pts.iter().all(|(a, b)| (a - b).abs() < 1e-12), "Thevenin vs full solve for every lamp");
    println!("ALL CHECKS PASS");
}
