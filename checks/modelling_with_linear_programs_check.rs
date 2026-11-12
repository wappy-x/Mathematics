// Linear programs: the check behind the card. std only, no crates.
// Two cake mixes, 4 ovens, limited flour: which plan earns the most margin?
// Three roads: (1) a corner solver that makes every pair of limits tight,
// (2) a grid of every plan in tenths of a batch, (3) a certificate: weights
// on the limits that cap the margin. Every number on the card is printed.
const BIG: f64 = 1e6; // a far fence: a best corner on it means the margin has no ceiling
const NAMES: [&str; 7] = ["oven", "flour", "demand", "x1>=0", "x2>=0", "fence", "fence"];

#[derive(Clone, Copy)]
struct Cand { i: usize, j: usize, x: (f64, f64), ok: bool, val: f64 }

fn solve(c: (f64, f64), a: &[(f64, f64)], b: &[f64]) -> (&'static str, Option<Cand>, Vec<Cand>) {
    let mut rows: Vec<(f64, f64, f64)> = a.iter().zip(b).map(|(r, v)| (r.0, r.1, *v)).collect();
    rows.extend([(-1.0, 0.0, 0.0), (0.0, -1.0, 0.0), (1.0, 0.0, BIG), (0.0, 1.0, BIG)]);
    let (mut cands, mut best): (Vec<Cand>, Option<Cand>) = (vec![], None);
    for i in 0..rows.len() {
        for j in i + 1..rows.len() {
            let ((a1, b1, r1), (a2, b2, r2)) = (rows[i], rows[j]);
            let det = a1 * b2 - a2 * b1;
            if det.abs() < 1e-12 { continue; } // parallel limits never meet
            let x = ((r1 * b2 - r2 * b1) / det, (a1 * r2 - a2 * r1) / det);
            let ok = rows.iter().all(|&(p, q, r)| p * x.0 + q * x.1 <= r + 1e-9);
            let k = Cand { i, j, x, ok, val: c.0 * x.0 + c.1 * x.1 };
            if j < a.len() + 2 { cands.push(k); }
            if ok && best.map_or(true, |bb| k.val > bb.val + 1e-9) { best = Some(k); }
        }
    }
    match best {
        None => ("infeasible", None, cands),
        Some(bb) if bb.j >= a.len() + 2 => ("unbounded", None, cands),
        Some(bb) => ("optimal", Some(bb), cands),
    }
}

fn f2(v: f64) -> String { format!("{:.2}", v + 0.0) }
fn pt(x: (f64, f64)) -> String { format!("({}, {})", f2(x.0), f2(x.1)) }
fn mv(c: (f64, f64), p: (f64, f64)) -> f64 { c.0 * p.0 + c.1 * p.1 }

fn fill(a: &[(f64, f64)], b: &[f64], order: [usize; 2]) -> (f64, f64) {
    let (mut x, mut left) = ([0.0f64; 2], b.to_vec()); // greedy: one cake first
    for k in order {
        let col = |r: usize| if k == 0 { a[r].0 } else { a[r].1 };
        x[k] = (0..3).filter(|&r| col(r) > 0.0).map(|r| left[r] / col(r)).fold(f64::INFINITY, f64::min);
        for r in 0..3 { left[r] -= col(r) * x[k]; }
    }
    (x[0], x[1])
}

fn comb(n: u128, k: u128) -> u128 { (0..k).fold(1, |o, t| o * (n - t) / (t + 1)) }

fn main() {
    let (c, a, b) = ((40.0, 60.0), vec![(2.0, 4.0), (20.0, 10.0), (0.0, 1.0)], vec![48.0, 300.0, 10.0]);
    println!("model, {} oven hours from 4 ovens x 12 h | max 40 x1 + 60 x2 | oven 2 x1 + 4 x2 <= 48 | flour 20 x1 + 10 x2 <= 300 | demand x2 <= 10", 4 * 12);
    let (status, best, cands) = solve(c, &a, &b);
    for k in &cands {
        let tag = if k.ok { "fits" } else { "breaks a limit" };
        println!("corner, {} + {}, {}, {}, margin {}", NAMES[k.i], NAMES[k.j], pt(k.x), tag, f2(k.val));
    }
    let fit = cands.iter().filter(|k| k.ok).count();
    println!("corners, {} candidates from 5 limits, {} fit", cands.len(), fit);
    let bb = best.unwrap();
    let (i, j, x, val) = (bb.i, bb.j, bb.x, bb.val);
    println!("solver, status {}, x1 {}, x2 {}, margin {}", status, f2(x.0), f2(x.1), f2(val));
    let (k0, k1) = (b[0] / a[0].0, a[0].1 / a[0].0); // by hand: substitute the oven line into flour
    let h2 = (a[1].0 * k0 - b[1]) / (a[1].0 * k1 - a[1].1);
    println!("hand, oven: x1 = {} - {} x2; flour: {} - {} x2 = {}; x2 {}, x1 {}", f2(k0), f2(k1), f2(a[1].0 * k0),
             f2(a[1].0 * k1 - a[1].1), f2(b[1]), f2(h2), f2(k0 - k1 * h2));
    assert!((h2 - x.1).abs() < 1e-9 && (k0 - k1 * h2 - x.0).abs() < 1e-9);
    let s: Vec<f64> = a.iter().zip(&b).map(|(r, v)| v - (r.0 * x.0 + r.1 * x.1)).collect();
    println!("slack, oven {} h, flour {} kg, demand {} batches", f2(s[0]), f2(s[1]), f2(s[2]));
    // road 2: every plan on a grid of tenths, in whole numbers so nothing rounds
    let (mut feasible, mut gbest, mut garg) = (0, -1i64, (0i64, 0i64));
    for u in 0..241i64 {
        for v in 0..121i64 {
            if 2 * u + 4 * v <= 480 && 20 * u + 10 * v <= 3000 && v <= 100 {
                feasible += 1;
                if 40 * u + 60 * v > gbest { gbest = 40 * u + 60 * v; garg = (u, v); }
            }
        }
    }
    let gx = (garg.0 as f64 / 10.0, garg.1 as f64 / 10.0);
    println!("grid, {} plans fit out of {}, best {} at {}", feasible, 241 * 121, f2(gbest as f64 / 10.0), pt(gx));
    assert!((gbest as f64 / 10.0 - val).abs() < 1e-9 && (gx.0 - x.0).abs() < 1e-9 && (gx.1 - x.1).abs() < 1e-9);
    // dual values: weights on the two tight limits whose rows add up to c
    let ((p1, q1), (p2, q2)) = (a[i], a[j]);
    let det = p1 * q2 - p2 * q1;
    let mut w = [0.0f64; 3];
    w[i] = (c.0 * q2 - p2 * c.1) / det;
    w[j] = (p1 * c.1 - q1 * c.0) / det;
    println!("dual, oven {} per h, flour {} per kg, demand {} per batch", f2(w[0]), f2(w[1]), f2(w[2]));
    // road 3: the certificate. Weights >= 0 whose rows cover c cap every plan
    let cap: f64 = w.iter().zip(&b).map(|(wk, bk)| wk * bk).sum();
    assert!(w.iter().all(|&v| v >= 0.0)); // a negative weight would flip its limit's inequality
    println!("certificate, {} x oven + {} x flour caps margin at {} + {} = {}", f2(w[0]), f2(w[1]), f2(w[0] * b[0]), f2(w[1] * b[1]), f2(cap));
    assert!((cap - gbest as f64 / 10.0).abs() < 1e-9);
    // along an edge the margin moves at a steady rate: the midpoint is the average
    let (e1, e2) = ((12.0, 6.0), (4.0, 10.0));
    let mid = ((e1.0 + e2.0) / 2.0, (e1.1 + e2.1) / 2.0);
    let avg = (mv(c, e1) + mv(c, e2)) / 2.0;
    println!("edge, midpoint {} margin {}, average of ends {}", pt(mid), f2(mv(c, mid)), f2(avg));
    assert!(mv(c, mid) < val);
    let (g1, g2) = (fill(&a, &b, [1, 0]), fill(&a, &b, [0, 1]));
    println!("breaks, fruit first {} margin {}", pt(g1), f2(mv(c, g1)));
    println!("breaks, best per oven hour (sponge {}, fruit {}) {} margin {}", f2(c.0 / a[0].0), f2(c.1 / a[0].1), pt(g2), f2(mv(c, g2)));
    assert!(mv(c, g1) < val && mv(c, g2) < val);
    let nb = solve(c, &[a[0], a[2]], &[b[0], b[2]]).1.unwrap();
    println!("breaks, no flour limit {} margin {}, needs {} kg flour", pt(nb.x), f2(nb.val), f2(20.0 * nb.x.0 + 10.0 * nb.x.1));
    let lp = solve(c, &a, &[48.0, 310.0, 10.0]).1.unwrap();
    let r = (lp.x.0.round() as i64, lp.x.1.round() as i64);
    let mi = |p: (i64, i64)| 40 * p.0 + 60 * p.1;
    println!("breaks, flour 310 kg: LP {} margin {}", pt(lp.x), f2(lp.val));
    println!("breaks, rounded ({}, {}) margin {}, oven over by {} h, flour over by {} kg", r.0, r.1, f2(mi(r) as f64),
             f2((2 * r.0 + 4 * r.1 - 48) as f64), f2((20 * r.0 + 10 * r.1 - 310) as f64));
    assert!(2 * r.0 + 4 * r.1 > 48 && 20 * r.0 + 10 * r.1 > 310);
    let mut wb = (0i64, 0i64);
    for p in 0..25i64 { for q in 0..11i64 {
        if 2 * p + 4 * q <= 48 && 20 * p + 10 * q <= 310 && mi((p, q)) > mi(wb) { wb = (p, q); }
    } }
    let dn = (lp.x.0 as i64, lp.x.1 as i64);
    println!("breaks, rounded down ({}, {}) margin {}; best whole plan ({}, {}) margin {}", dn.0, dn.1, f2(mi(dn) as f64), wb.0, wb.1, f2(mi(wb) as f64));
    assert!(mi(dn) < mi(wb) && mi(wb) as f64 <= lp.val);
    let mn = solve((-40.0, -60.0), &a, &b).1.unwrap();
    println!("trap, minimise by mistake {} margin {}", pt(mn.x), f2(-mn.val));
    let bag = solve(c, &a, &[48.0, 12.0, 10.0]).1.unwrap();
    println!("trap, flour limit in 25 kg bags (12) beside kg per batch: margin {}", f2(bag.val));
    let forms: [(&str, Vec<(f64, f64)>, Vec<f64>); 3] = [("at least 14 sponge as -x1 <= -14", vec![(-1.0, 0.0)], vec![-14.0]),
        ("exactly 8 fruit as x2 <= 8 and -x2 <= -8", vec![(0.0, 1.0), (0.0, -1.0)], vec![8.0, -8.0]),
        ("at least 20 sponge as -x1 <= -20", vec![(-1.0, 0.0)], vec![-20.0])];
    let mut st = "";
    for (label, ea, eb) in forms { // standard form: "at least" flips sign, "exactly" is two rows
        let (s2, sf, _) = solve(c, &[a.clone(), ea].concat(), &[b.clone(), eb].concat());
        let tail = sf.map_or(String::new(), |k| format!(", {} margin {}", pt(k.x), f2(k.val)));
        println!("standard form, {}: status {}{}", label, s2, tail);
        st = s2;
    }
    assert!(st == "infeasible");
    let tries: [(&str, (f64, f64), [f64; 3]); 3] = [("sponge margin 20", (20.0, 60.0), [48.0, 300.0, 10.0]),
        ("sponge margin 130", (130.0, 60.0), [48.0, 300.0, 10.0]), ("flour 400 kg", c, [48.0, 400.0, 10.0])];
    for (label, cc, bb) in tries {
        let t = solve(cc, &a, &bb).1.unwrap();
        println!("try, {}: {} margin {}", label, pt(t.x), f2(t.val));
    }
    st = solve(c, &[a[2]], &[b[2]]).0;
    println!("try, no oven and no flour limit: status {}", st);
    assert!(st == "unbounded");
    assert!(cands.len() as u128 == comb(5, 2) - 1); // one pair is parallel: demand and x2 >= 0
    let g: Vec<String> = [(2u128, 3u128), (10, 20), (20, 40)].iter()
        .map(|&(n, m)| format!("n {} m {}: {} candidates", n, m, comb(n + m, n))).collect();
    println!("growth, {}", g.join("; "));
    let fig: Vec<String> = [(0, 0), (15, 0), (12, 6), (4, 10), (0, 10)].iter()
        .map(|&(p, q)| format!("{},{}", 45 + 11 * p, 205 - 13 * q)).collect();
    println!("figure, corners px {}", fig.join(" "));
    println!("ALL CHECKS PASS");
}
