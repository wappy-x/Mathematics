// Integer programs and branch and bound -- the check behind the card.  std only, no crates.
// Choose 3 depot sites out of 12 to save the most van costs inside a lease budget.
const NAMES: &[u8] = b"ABCDEFGHIJKL";
const LEASE: [f64; 12] = [60., 40., 110., 70., 60., 40., 60., 50., 90., 60., 110., 70.]; // a_i, £k a year (synthetic)
const SAVE: [f64; 12] = [145., 40., 240., 140., 115., 70., 70., 80., 125., 115., 110., 125.]; // s_i, £k a year (synthetic)
const N: usize = 12; const P: usize = 3; const EPS: f64 = 1e-9;
type Plan = Vec<(usize, f64)>; // (site, share open), ascending by site

// Best fractional plan, by checking every corner. fix[i] is -1 (free), 0 or 1.
fn relax(fix: &[i32; N], budget: f64) -> (Option<(f64, Plan)>, usize) {
    let free: Vec<usize> = (0..N).filter(|&i| fix[i] < 0).collect();
    let ones: Vec<usize> = (0..N).filter(|&i| fix[i] == 1).collect();
    let (mut best, mut corners): (Option<(f64, Plan)>, usize) = (None, 0);
    for mask in 0u32..(1u32 << free.len()) {
        let on: Vec<usize> = (0..free.len()).filter(|&k| mask >> k & 1 == 1).map(|k| free[k]).collect();
        if ones.len() + on.len() > P { continue; }
        let r = (P - ones.len() - on.len()) as f64; // depots still to place
        let rest: Vec<usize> = free.iter().cloned().filter(|i| !on.contains(i)).collect();
        let both: Vec<usize> = ones.iter().chain(on.iter()).cloned().collect();
        let left = budget - both.iter().map(|&i| LEASE[i]).sum::<f64>();
        let base: f64 = both.iter().map(|&i| SAVE[i]).sum();
        let mut pts: Vec<Plan> = if r == 0.0 && left >= 0.0 { vec![vec![]] } else { vec![] };
        for u in 0..rest.len() {
            for w in u + 1..rest.len() { // two sites share the last r depots
                let (i, j) = (rest[u], rest[w]);
                if r > 0.0 && LEASE[i] != LEASE[j] {
                    let xi = (left - LEASE[j] * r) / (LEASE[i] - LEASE[j]);
                    if -EPS < xi && xi < 1.0 + EPS && -EPS < r - xi && r - xi < 1.0 + EPS {
                        pts.push(vec![(i, xi), (j, r - xi)]);
                    }
                }
            }
        }
        for pt in pts {
            corners += 1;
            let v = base + pt.iter().map(|&(i, x)| SAVE[i] * x).sum::<f64>();
            if best.as_ref().map_or(true, |b| v > b.0 + EPS) {
                let mut x: Plan = both.iter().map(|&i| (i, 1.0)).collect();
                x.extend(pt.iter().cloned().filter(|p| p.1 > EPS));
                x.sort_by_key(|p| p.0);
                best = Some((v, x));
            }
        }
    }
    (best, corners)
}

fn frac(x: &Plan) -> Option<usize> { // most fractional site, or None
    let mut pick: Option<(usize, f64)> = None;
    for &(i, v) in x {
        let d = v.min(1.0 - v);
        if v > EPS && v < 1.0 - EPS && pick.map_or(true, |p| d > p.1) { pick = Some((i, d)); }
    }
    pick.map(|p| p.0)
}

fn show(x: &Plan) -> String {
    x.iter().map(|&(i, v)| format!("{}={}", NAMES[i] as char, v)).collect::<Vec<_>>().join(" ")
}

// Branch and bound. "best" opens the highest bound first; "depth" dives, open-the-site first.
fn search(order: &str, log: &mut Vec<String>) -> ((f64, Plan), usize) {
    let mut open: Vec<(Vec<(usize, i32)>, f64)> = vec![(vec![], f64::INFINITY)];
    let (mut inc, mut lps): ((f64, Plan), usize) = ((-1.0, vec![]), 0);
    while !open.is_empty() {
        let mut k = if order == "best" { 0 } else { open.len() - 1 };
        if order == "best" { for t in 1..open.len() { if open[t].1 > open[k].1 { k = t; } } }
        let (path, _) = open.remove(k);
        let mut fix = [-1i32; N]; for &(i, b) in &path { fix[i] = b; }
        let (res, _) = relax(&fix, 200.0); lps += 1;
        let tag: Vec<String> = path.iter().map(|&(i, b)| format!("{}={}", NAMES[i] as char, b)).collect();
        let tag = if tag.is_empty() { "root".to_string() } else { tag.join(" ") };
        let Some((v, x)) = res else { log.push(format!("{:<5} {:<8} no plan fits: pruned", order, tag)); continue };
        if v <= inc.0 + EPS { log.push(format!("{:<5} {:<8} bound {:.1} <= best {:.0}: pruned", order, tag, v, inc.0)); continue; }
        match frac(&x) {
            None => { log.push(format!("{:<5} {:<8} bound {:.1} all whole: new best {}", order, tag, v, show(&x))); inc = (v, x); }
            Some(i) => {
                log.push(format!("{:<5} {:<8} bound {:.1} {} -> branch on {}", order, tag, v, show(&x), NAMES[i] as char));
                for b in [0, 1] { let mut p = path.clone(); p.push((i, b)); open.push((p, v)); }
            }
        }
    }
    (inc, lps)
}

fn brute(budget: f64, pair_loss: f64) -> ((f64, String), usize) {
    let (mut best, mut fits) = ((-1.0, String::new()), 0);
    for i in 0..N {
        for j in i + 1..N {
            for k in j + 1..N {
                if LEASE[i] + LEASE[j] + LEASE[k] <= budget {
                    fits += 1;
                    let pen = if i == 0 && j == 3 { pair_loss } else { 0.0 };
                    let v = SAVE[i] + SAVE[j] + SAVE[k] - pen;
                    let name: String = [i, j, k].iter().map(|&t| NAMES[t] as char).collect();
                    if v > best.0 || (v == best.0 && name > best.1) { best = (v, name); }
                }
            }
        }
    }
    (best, fits)
}

fn names(v: &[usize]) -> String { v.iter().map(|&i| NAMES[i] as char).collect() }
fn terms(x: &Plan, row: &[f64; 12]) -> String {
    let t: Vec<String> = x.iter().map(|&(i, v)| format!("{}", row[i] * v)).collect();
    format!("{} = {}", t.join(" + "), x.iter().map(|&(i, v)| row[i] * v).sum::<f64>())
}

fn main() {
    println!("site   {}", NAMES.iter().map(|&c| format!("{:>3}", c as char)).collect::<Vec<_>>().join(" "));
    println!("lease  {}", LEASE.iter().map(|a| format!("{:>3}", a)).collect::<Vec<_>>().join(" "));
    println!("saving {}", SAVE.iter().map(|a| format!("{:>3}", a)).collect::<Vec<_>>().join(" "));
    // ---- road 1: the relaxation, every corner checked ----
    let (root, corners) = relax(&[-1; N], 200.0);
    let (z_lp, x_lp) = root.unwrap();
    println!("relaxation: {} corners checked, best {:.1} at {}", corners, z_lp, show(&x_lp));
    for (tag, site, b) in [("root", 0, -1), ("C=0", 2, 0), ("C=1", 2, 1)] {
        let mut fix = [-1; N]; fix[site] = b;
        let x = relax(&fix, 200.0).0.unwrap().1;
        println!("{:<4} lease {}; saving {}", tag, terms(&x, &LEASE), terms(&x, &SAVE));
    }
    // ---- road 2: a price certificate, y1 per depot and y2 per £k of lease (weak duality) ----
    let split: Vec<usize> = x_lp.iter().filter(|p| p.1 > EPS && p.1 < 1.0 - EPS).map(|p| p.0).collect();
    let (c, d) = (split[0], split[1]); // the two split sites
    let y2 = (SAVE[c] - SAVE[d]) / (LEASE[c] - LEASE[d]);
    let y1 = SAVE[c] - y2 * LEASE[c];
    let extra: Vec<(usize, f64)> = (0..N).map(|i| (i, SAVE[i] - y1 - y2 * LEASE[i])).filter(|p| p.1 > EPS).collect();
    let cert = P as f64 * y1 + 200.0 * y2 + extra.iter().map(|p| p.1).sum::<f64>();
    let left: Vec<String> = extra.iter().map(|&(i, e)| format!("{} {}", NAMES[i] as char, e)).collect();
    println!("price certificate: y1 = {}, y2 = {}; 3*y1 = {}, 200*y2 = {}, leftovers {}; bound {:.1}",
             y1, y2, P as f64 * y1, 200.0 * y2, left.join(" "), cert);
    // ---- road 3: every triple, against two search orders ----
    let ((z_ip, trio), fits) = brute(200.0, 0.0);
    let mut log = vec![];
    let ((z_bb, _), lps) = search("best", &mut log);
    let ((z_df, _), lps_df) = search("depth", &mut log);
    for line in &log { println!("{}", line); }
    println!("relaxations solved: best-first {}, depth-first {}", lps, lps_df);
    println!("brute force: {} of {} triples fit the budget, best {} = {}", fits, N * (N - 1) * (N - 2) / 6, trio, z_ip);
    let gap = z_lp - z_ip;
    println!("integrality gap: {:.0} - {} = {:.0}, {:.2}% of the integer best", z_lp, z_ip, gap, 100.0 * gap / z_ip);
    // ---- what breaks ----
    let near: Vec<usize> = x_lp.iter().filter(|p| p.1 >= 0.5).map(|p| p.0).collect();
    let down: Vec<usize> = x_lp.iter().filter(|p| p.1 > 1.0 - EPS).map(|p| p.0).collect();
    let sum = |v: &[usize], a: &[f64; 12]| v.iter().map(|&i| a[i]).sum::<f64>();
    println!("round to nearest: {} lease {} save {}", names(&near), sum(&near, &LEASE), sum(&near, &SAVE));
    println!("round down: {} depots {} save {}", names(&down), down.len(), sum(&down, &SAVE));
    let mut order: Vec<usize> = (0..N).collect();
    order.sort_by(|&a, &b| (SAVE[b] / LEASE[b]).partial_cmp(&(SAVE[a] / LEASE[a])).unwrap());
    let (mut greedy, mut spent) = (vec![], 0.0);
    for i in order {
        if greedy.len() < P && spent + LEASE[i] <= 200.0 { greedy.push(i); spent += LEASE[i]; }
    }
    println!("greedy by saving per £: {} lease {} save {}", names(&greedy), spent, sum(&greedy, &SAVE));
    let ((z_ov, trio_ov), _) = brute(200.0, 50.0);
    println!("A and D overlap (-50): ADL really {}, true best {} = {}", z_ip - 50.0, trio_ov, z_ov);
    // ---- try changing ----
    for bud in [190.0, 210.0, 240.0] {
        let ((zb, tb), _) = brute(bud, 0.0);
        println!("budget {}: relaxation {:.1}, integer best {} = {}", bud, relax(&[-1; N], bud).0.unwrap().0, tb, zb);
    }
    assert!(y2 >= 0.0); // a negative budget price gives no ceiling
    assert!((z_lp - cert).abs() < 1e-9); // corners and prices agree on the bound
    assert!(z_ip == z_bb && z_bb == z_df); // tree search meets brute force
    assert!(z_lp >= z_ip && gap > 0.0); // relaxation bounds the integer best from above
    assert!(sum(&near, &LEASE) > 200.0 && down.len() < P); // both roundings break a rule
    assert!(lps < fits); // the tree solved fewer problems than brute force checked
    println!("ALL CHECKS PASS");
}
