// Shadow prices and sensitivity -- the check behind the card.  Rust std only.
// A bakery's daily plan: x1 batches of sponge (30 pounds margin), x2 batches of loaf
// cake (27 pounds).  Limits: oven hours, flour (kg), van loads.  No solver is used:
// every LP here is solved by visiting every corner.  Three roads to the shadow prices:
// (1) solve the binding rows, (2) re-solve with one more unit, (3) solve the dual LP.
fn gauss(m: &[Vec<f64>], v: &[f64]) -> Option<Vec<f64>> { // solve M z = v; None if singular
    let n = v.len();
    let mut a: Vec<Vec<f64>> = (0..n).map(|i| { let mut r = m[i].clone(); r.push(v[i]); r }).collect();
    for k in 0..n {
        let mut p = k;
        for i in k + 1..n { if a[i][k].abs() > a[p][k].abs() { p = i; } }
        if a[p][k].abs() < 1e-12 { return None; }
        a.swap(k, p);
        for i in 0..n {
            if i != k {
                let f = a[i][k] / a[k][k];
                for j in 0..=n { a[i][j] -= f * a[k][j]; }
            }
        }
    }
    Some((0..n).map(|i| a[i][n] / a[i][i]).collect())
}

fn best_corner(c: &[f64], g: &[Vec<f64>], h: &[f64]) -> (f64, Vec<f64>) { // max c.z, G z <= h
    let n = c.len();
    let mut best: Option<(f64, Vec<f64>)> = None;
    for mask in 0..(1usize << g.len()) {
        let rows: Vec<usize> = (0..g.len()).filter(|i| mask >> i & 1 == 1).collect();
        if rows.len() != n { continue; }
        let gm: Vec<Vec<f64>> = rows.iter().map(|&i| g[i].clone()).collect();
        let hv: Vec<f64> = rows.iter().map(|&i| h[i]).collect();
        let z = match gauss(&gm, &hv) { Some(z) => z, None => continue };
        if (0..g.len()).any(|i| (0..n).map(|j| g[i][j] * z[j]).sum::<f64>() > h[i] + 1e-9) { continue; }
        let val: f64 = (0..n).map(|j| c[j] * z[j]).sum();
        if best.as_ref().map_or(true, |b| val > b.0 + 1e-9) { best = Some((val, z)); }
    }
    best.unwrap()
}

const NAMES: [&str; 3] = ["oven", "flour", "vans"];
const VAR: [&str; 2] = ["sponge", "loaf"];
const A: [[f64; 2]; 3] = [[2.0, 1.0], [10.0, 15.0], [0.6, 0.6]]; // per batch
const B0: [f64; 3] = [60.0, 600.0, 30.0];
const C0: [f64; 2] = [30.0, 27.0];

fn plan_c(b: [f64; 3], c: [f64; 2]) -> (f64, Vec<f64>) { // x1, x2 >= 0 as two more rows
    let mut g: Vec<Vec<f64>> = A.iter().map(|r| r.to_vec()).collect();
    g.push(vec![-1.0, 0.0]); g.push(vec![0.0, -1.0]);
    best_corner(&c, &g, &[b[0], b[1], b[2], 0.0, 0.0])
}
fn plan(b: [f64; 3]) -> f64 { plan_c(b, C0).0 }
fn bump(i: usize, t: f64) -> [f64; 3] { let mut b = B0; b[i] += t; b }
fn prices(b: [f64; 3], c: [f64; 2]) -> (f64, Vec<f64>, Vec<f64>) { // road 1: solve binding rows
    let (p, x) = plan_c(b, c);
    let mut g: Vec<Vec<f64>> = A.iter().map(|r| r.to_vec()).collect();
    g.push(vec![-1.0, 0.0]); g.push(vec![0.0, -1.0]); let h = [b[0], b[1], b[2], 0.0, 0.0];
    let bind: Vec<usize> = (0..5).filter(|&i| h[i] - g[i][0] * x[0] - g[i][1] * x[1] < 1e-9).collect();
    let gt: Vec<Vec<f64>> = (0..2).map(|j| bind.iter().map(|&i| g[i][j]).collect()).collect();
    let yb = gauss(&gt, &c).unwrap(); // needs exactly 2 binding rows
    let y = (0..3).map(|i| bind.iter().position(|&k| k == i).map_or(0.0, |q| yb[q] + 0.0)).collect();
    (p, x, y)
}
fn px(u: f64, v: f64) -> String { format!("({:.1}, {:.1})", 110.0 + 3.3 * u, 215.0 - 3.3 * v) }

fn main() {
    println!("setting: 4 ovens x 15 h = {} oven hours; per batch sponge 2 h, 10 kg, 0.6 van load; loaf 1 h, 15 kg, 0.6 van load; 30 vans", 4 * 15);
    let (p, x, y) = prices(B0, C0);
    let used: Vec<f64> = (0..3).map(|i| A[i][0] * x[0] + A[i][1] * x[1]).collect();
    println!("plan: sponge {:.2} batches, loaf {:.2} batches, profit {:.2}", x[0], x[1], p);
    for i in 0..3 { println!("{:5}: limit {:7.2}, used {:7.2}, slack {:6.2}", NAMES[i], B0[i], used[i], B0[i] - used[i]); }
    let bind: Vec<usize> = (0..3).filter(|&i| B0[i] - used[i] < 1e-9).collect();
    let yb: Vec<f64> = bind.iter().map(|&i| y[i]).collect();
    for i in 0..3 {
        let (up, down) = (plan(bump(i, 1.0)) - p, p - plan(bump(i, -1.0))); // road 2
        println!("{:5}: shadow price {:.2}; re-solve +1 gains {:.2}, -1 loses {:.2}", NAMES[i], y[i], up, down);
        assert!((up - y[i]).abs() < 1e-9 && (down - y[i]).abs() < 1e-9);
    }
    let mut g: Vec<Vec<f64>> = (0..2).map(|j| (0..3).map(|i| -A[i][j]).collect()).collect();
    for i in 0..3 { g.push((0..3).map(|k| if k == i { -1.0 } else { 0.0 }).collect()); }
    let (d, yd) = best_corner(&[-B0[0], -B0[1], -B0[2]], &g, &[-C0[0], -C0[1], 0.0, 0.0, 0.0]);
    println!("dual LP by its corners: prices {:.2}, {:.2}, {:.2}; cost {:.2}", yd[0] + 0.0, yd[1] + 0.0, yd[2] + 0.0, -d);
    assert!((0..3).all(|i| (yd[i] - y[i]).abs() < 1e-9) && (-d - p).abs() < 1e-9); // road 3
    println!("profit = 60 x {:.2} + 600 x {:.2} + 30 x {:.2} = {:.2}", y[0], y[1], y[2],
             (0..3).map(|i| B0[i] * y[i]).sum::<f64>());
    let rc = |j: usize| ((C0[j] - (0..3).map(|i| y[i] * A[i][j]).sum::<f64>()) * 1e9).round() / 1e9 + 0.0; // margin minus value used
    println!("reduced cost: {} {:.2}, {} {:.2}", VAR[0], rc(0), VAR[1], rc(1));
    for i in 0..3 { // ranging by formula: keep the same rows binding
        let rng: (f64, f64);
        if bind.contains(&i) {
            let ab: Vec<Vec<f64>> = bind.iter().map(|&k| A[k].to_vec()).collect();
            let e: Vec<f64> = bind.iter().map(|&k| if k == i { 1.0 } else { 0.0 }).collect();
            let dd = gauss(&ab, &e).unwrap();
            let mut moves: Vec<(f64, String)> = Vec::new();
            for j in 0..2 { if dd[j].abs() > 1e-12 { moves.push((-x[j] / dd[j], format!("{} hits 0", VAR[j]))); } }
            for k in 0..3 {
                let r = A[k][0] * dd[0] + A[k][1] * dd[1];
                if !bind.contains(&k) && r.abs() > 1e-12 { moves.push(((B0[k] - used[k]) / r, format!("{} binds", NAMES[k]))); }
            }
            let (mut lo, mut hi): (Option<&(f64, String)>, Option<&(f64, String)>) = (None, None);
            for m in &moves {
                if m.0 < 0.0 && lo.map_or(true, |l| m.0 > l.0) { lo = Some(m); }
                if m.0 > 0.0 && hi.map_or(true, |h| m.0 < h.0) { hi = Some(m); }
            }
            let (lo, hi) = (lo.unwrap(), hi.unwrap());
            rng = (B0[i] + lo.0, B0[i] + hi.0);
            println!("{:5}: price {:.2} holds from {:.2} ({}) to {:.2} ({}); allowable increase {:.2}, decrease {:.2}",
                     NAMES[i], y[i], rng.0, lo.1, rng.1, hi.1, hi.0, -lo.0);
            println!("{:5}: each extra unit moves sponge by {:+.2}, loaf by {:+.2} batches, van loads by {:+.2}", NAMES[i], dd[0], dd[1], 0.6 * (dd[0] + dd[1]));
        } else {
            rng = (used[i], f64::INFINITY);
            println!("{:5}: price 0.00 holds from {:.2} up, with no upper end; allowable decrease {:.2}", NAMES[i], used[i], B0[i] - used[i]);
        }
        let (mut t_up, mut t_dn) = (0.0f64, 0.0f64); // ranging by scanning, one unit at a time
        while t_up < 3.0 * B0[i] && (plan(bump(i, t_up + 1.0)) - plan(bump(i, t_up)) - y[i]).abs() < 1e-9 { t_up += 1.0; }
        while (plan(bump(i, t_dn - 1.0)) - plan(bump(i, t_dn)) + y[i]).abs() < 1e-9 { t_dn -= 1.0; }
        let end = if t_up >= 3.0 * B0[i] { "no end".to_string() } else { format!("{:.2}", B0[i] + t_up) };
        println!("{:5}: scan agrees, price constant from {:.2} to {}", NAMES[i], B0[i] + t_dn, end);
        assert!((B0[i] + t_dn - rng.0).abs() < 1e-6 && (t_up >= 3.0 * B0[i] || (B0[i] + t_up - rng.1).abs() < 1e-6));
    }
    for j in 0..2 { // margin ranges: the prices must stay >= 0
        let ab: Vec<Vec<f64>> = bind.iter().map(|&i| A[i].to_vec()).collect();
        let at2: Vec<Vec<f64>> = (0..2).map(|k| ab.iter().map(|r| r[k]).collect()).collect();
        let dy = gauss(&at2, &[if j == 0 { 1.0 } else { 0.0 }, if j == 1 { 1.0 } else { 0.0 }]).unwrap();
        let lo = (0..2).filter(|&k| dy[k] > 0.0).map(|k| -yb[k] / dy[k]).fold(f64::NEG_INFINITY, f64::max);
        let hi = (0..2).filter(|&k| dy[k] < 0.0).map(|k| -yb[k] / dy[k]).fold(f64::INFINITY, f64::min);
        let (cl, ch) = (C0[j] + lo, C0[j] + hi);
        println!("{:6} margin: plan unchanged from {:.2} to {:.2} pounds; increase {:.2}, decrease {:.2}", VAR[j], cl, ch, hi, -lo);
        for (cc, same) in [(cl + 0.5, true), (cl - 0.5, false), (ch - 0.5, true), (ch + 0.5, false)] {
            let mut c = C0; c[j] = cc;
            let xx = plan_c(B0, c).1;
            assert!(((xx[0] - x[0]).abs() + (xx[1] - x[1]).abs() < 1e-9) == same);
        }
    }
    // what breaks: prices used outside their range, added together, or replaced by averages
    println!("flour +200 kg: price predicts {:.2}, re-solve gives {:.2}", p + 200.0 * y[1], plan(bump(1, 200.0)));
    let both = plan([80.0, 700.0, 30.0]);
    println!("oven +20 and flour +100: prices predict {:.2}, re-solve gives {:.2}", p + 20.0 * y[0] + 100.0 * y[1], both);
    println!("average flour value {:.2} per kg predicts +{:.2} for 100 kg; true +{:.2}", p / 600.0, 100.0 * p / 600.0,
             plan(bump(1, 100.0)) - p);
    println!("average van value {:.2} per load; a 31st load truly adds {:.2}", p / 30.0, plan(bump(2, 1.0)) - p);
    assert!(plan(bump(1, 200.0)) < p + 200.0 * y[1] - 1.0 && both < p + 20.0 * y[0] + 100.0 * y[1] - 1.0);
    println!("flour already costs 0.50 per kg inside the margins: most to pay for an extra kg {:.2}", 0.50 + y[1]);
    let (oven_net, flour_net) = (20.0 * (y[0] - 5.0), 100.0 * (y[1] - 0.80));
    println!("decision: 20 overtime hours at 5.00 net {:.2}; 100 kg at 0.80 extra net {:.2}; both net {:.2}",
             oven_net, flour_net, both - p - 100.0 - 80.0);
    let p80 = plan([80.0, 600.0, 30.0]);
    println!("at 80 oven hours: profit {:.2}; hour 81 adds {:.2}, 1 more kg flour adds {:.2}, 1 fewer loses {:.2}", p80,
             plan([81.0, 600.0, 30.0]) - p80, plan([80.0, 601.0, 30.0]) - p80, p80 - plan([80.0, 599.0, 30.0]));
    let pts: Vec<f64> = (0..13).map(|k| plan([10.0 * k as f64, 600.0, 30.0])).collect();
    let s: Vec<String> = pts.iter().map(|v| format!("{:.0}", v)).collect();
    println!("chart, profit at oven hours 0, 10, ..., 120: {}", s.join(", "));
    assert!((pts[4] - 1080.0).abs() < 1e-9 && (pts[8] - 1440.0).abs() < 1e-9 && (pts[12] - pts[10]).abs() < 1e-9);
    for h in [40.0, 80.0, 100.0] {
        let xh = plan_c([h, 600.0, 30.0], C0).1;
        println!("at {:.0} oven hours: sponge {:.2}, loaf {:.2}", h, xh[0] + 0.0, xh[1] + 0.0);
    }
    let st: Vec<String> = [("0-40 h", 0), ("40-80 h", 4), ("80-100 h", 8), ("past 100 h", 10)].iter()
        .map(|&(lab, k)| format!("{} {:.2}", lab, (pts[k + 1] - pts[k]) / 10.0)).collect();
    println!("oven hour worth by stretch: {}", st.join(", "));
    for (label, b, c) in [("flour 750", [60.0, 750.0, 30.0], C0), ("sponge margin 55", B0, [55.0, 27.0]),
                          ("vans 26", [60.0, 600.0, 26.0], C0)] {
        let (pt, xt, yt) = prices(b, c);
        println!("try {}: plan {:.2}, {:.2}; profit {:.2}; prices {:.2}, {:.2}, {:.2}", label, xt[0] + 0.0, xt[1] + 0.0, pt, yt[0], yt[1], yt[2]);
    }
    let corners: Vec<String> = [(0.0, 0.0), (30.0, 0.0), (15.0, 30.0), (0.0, 40.0)].iter().map(|&(u, v)| px(u, v)).collect();
    println!("figure, 3.3 px per batch, origin (110, 215): corners {}", corners.join(" "));
    println!("figure, line ends: oven {} {} flour {} {} flour 700 {} {} vans {} {}", px(0.0, 60.0), px(30.0, 0.0),
             px(0.0, 40.0), px(60.0, 0.0), px(0.0, 700.0 / 15.0), px(60.0, 20.0 / 3.0), px(0.0, 50.0), px(50.0, 0.0));
    println!("ALL CHECKS PASS");
}
