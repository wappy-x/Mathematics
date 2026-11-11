// Network flows as linear programs -- the check behind the card. Rust std only, no crates.
// Two mills ship timber to three workshops; MINIMISE haulage cost. Roads: the transportation
// simplex (it only adds and subtracts); its prices as a certificate; every corner of the
// linear program in exact fractions; every whole-tonne plan listed.
const COST: [[i64; 3]; 2] = [[6, 7, 10], [7, 6, 7]]; // pounds per tonne, North and South mill to W1, W2, W3
const SUPPLY: [i64; 2] = [40, 30]; // tonnes a week
const DEMAND: [i64; 3] = [25, 20, 15];
const HOURS: [i64; 3] = [3, 2, 2]; // South lorry hours per tonne to W1, W2, W3
const BUDGET: i64 = 55; // hours a week
const NAMES: [&str; 4] = ["W1", "W2", "W3", "spare"];
type Cell = (usize, usize, i64);

fn lab(i: usize, j: usize) -> String { format!("{}-{}", ["N", "S"][i], NAMES[j]) }
fn gcd(a: i64, b: i64) -> i64 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn fr(n: i64, d: i64) -> String {
    let g = gcd(n, d).max(1);
    let (n, d) = (n / g * d.signum(), d.abs() / g);
    if d == 1 { format!("{}", n) } else { format!("{}/{}", n, d) }
}
fn list(x: &[Cell]) -> String { x.iter().map(|&(i, j, q)| format!("{} {}", lab(i, j), q)).collect::<Vec<_>>().join(", ") }

struct Out { x: Vec<Cell>, cost: i64, u: Vec<i64>, v: Vec<i64>, red: Vec<Cell>, k: usize }

fn transport(cost: [[i64; 3]; 2], supply: [i64; 2], demand: [i64; 3], log: bool) -> Out {
    let c: Vec<Vec<i64>> = cost.iter().map(|r| vec![r[0], r[1], r[2], 0]).collect(); // spare costs nothing
    let (mut a, mut b) = (supply.to_vec(), demand.to_vec());
    b.push(supply.iter().sum::<i64>() - demand.iter().sum::<i64>());
    let (m, n) = (2usize, 4usize);
    let (mut x, mut i, mut j): (Vec<Cell>, usize, usize) = (vec![], 0, 0); // northwest-corner start
    while i < m && j < n {
        let q = a[i].min(b[j]);
        x.push((i, j, q)); a[i] -= q; b[j] -= q;
        if a[i] == 0 && i < m - 1 { i += 1 } else { j += 1 }
    }
    let total = |x: &Vec<Cell>| x.iter().map(|&(i, j, q)| c[i][j] * q).sum::<i64>();
    if log { println!("northwest-corner start: {} | cost {}", list(&x), total(&x)); }
    let mut k = 0;
    loop {
        let (mut u, mut v) = (vec![None; m], vec![None; n]); // prices: u_i + v_j = c_ij on used routes
        v[n - 1] = Some(0i64);
        for _ in 0..m + n {
            for &(i, j, _) in &x {
                if u[i].is_none() { if let Some(vj) = v[j] { u[i] = Some(c[i][j] - vj); } }
                if v[j].is_none() { if let Some(ui) = u[i] { v[j] = Some(c[i][j] - ui); } }
            }
        }
        let (u, v): (Vec<i64>, Vec<i64>) = (u.iter().map(|p| p.unwrap()).collect(), v.iter().map(|p| p.unwrap()).collect());
        let mut red: Vec<Cell> = vec![];
        for i in 0..m { for j in 0..n {
            if !x.iter().any(|&(a, b, _)| a == i && b == j) { red.push((i, j, c[i][j] - u[i] - v[j])); }
        } }
        let mut e = red[0];
        for &r in &red { if r.2 < e.2 { e = r; } }
        if e.2 >= 0 { let cost = total(&x); return Out { x, cost, u, v, red, k }; }
        let mut adj: Vec<Vec<usize>> = vec![vec![]; m + n]; // the loop the new route closes
        for &(i, j, _) in &x { adj[i].push(m + j); adj[m + j].push(i); }
        let mut prev: Vec<Option<usize>> = vec![None; m + n];
        let (mut seen, mut stack) = (vec![false; m + n], vec![m + e.1]);
        seen[m + e.1] = true;
        while let Some(nd) = stack.pop() {
            for &nb in &adj[nd] { if !seen[nb] { seen[nb] = true; prev[nb] = Some(nd); stack.push(nb); } }
        }
        let mut path = vec![e.0];
        while let Some(p) = prev[*path.last().unwrap()] { path.push(p); }
        let cells: Vec<(usize, usize)> = path.windows(2).map(|w| if w[0] < m { (w[0], w[1] - m) } else { (w[1], w[0] - m) }).collect();
        let pos = |x: &Vec<Cell>, r: (usize, usize)| x.iter().position(|&(a, b, _)| (a, b) == r).unwrap();
        let (mut th, mut out) = (i64::MAX, (0, 0));
        for (t, &r) in cells.iter().enumerate() {
            let q = x[pos(&x, r)].2;
            if t % 2 == 0 && (q < th || (q == th && r < out)) { th = q; out = r; }
        }
        for (t, &r) in cells.iter().enumerate() { let p = pos(&x, r); x[p].2 += if t % 2 == 0 { -th } else { th }; }
        x.push((e.0, e.1, th));
        let p = pos(&x, out); x.remove(p); k += 1;
        if log { println!("pivot {}: enter {} (reduced cost {}), shift {} t, leave {}, cost {}", k, lab(e.0, e.1), e.2, th, lab(out.0, out.1), total(&x)); }
    }
}

fn det3(m: &[[i64; 3]; 3]) -> i64 {
    m[0][0] * (m[1][1] * m[2][2] - m[1][2] * m[2][1]) - m[0][1] * (m[1][0] * m[2][2] - m[1][2] * m[2][0])
        + m[0][2] * (m[1][0] * m[2][1] - m[1][1] * m[2][0])
}
// y = North's tonnes to W1..W3; South sends demand - y; each row g.y <= h
fn rows(sup: [i64; 2], dem: [i64; 3], budget: i64) -> Vec<([i64; 3], i64)> {
    let mut r = vec![];
    for j in 0..3 { let mut g = [0; 3]; g[j] = -1; r.push((g, 0)); }
    for j in 0..3 { let mut g = [0; 3]; g[j] = 1; r.push((g, dem[j])); }
    r.push(([1, 1, 1], sup[0]));
    r.push(([-1, -1, -1], sup[1] - dem.iter().sum::<i64>()));
    if budget > 0 { r.push(([-HOURS[0], -HOURS[1], -HOURS[2]], budget - (0..3).map(|j| HOURS[j] * dem[j]).sum::<i64>())); }
    r
}
fn plan_cost(y: [i64; 3], d: i64, dem: [i64; 3]) -> i64 { (0..3).map(|j| (COST[0][j] - COST[1][j]) * y[j] + d * COST[1][j] * dem[j]).sum() }
fn south_hours(y: [i64; 3]) -> i64 { (0..3).map(|j| HOURS[j] * (DEMAND[j] - y[j])).sum() }
fn show(y: [i64; 3], d: i64) -> String { format!("({}, {}, {})", fr(y[0], d), fr(y[1], d), fr(y[2], d)) }

// every corner: three rows tight, solved by Cramer's rule; s = units per tonne (2 for half tonnes)
fn corners(sup: [i64; 2], dem: [i64; 3], budget: i64, s: i64) -> (usize, usize, [i64; 3], i64, i64) {
    let r = rows(sup, dem, budget);
    let mut pts: Vec<([i64; 3], i64)> = vec![];
    for a in 0..r.len() { for b in a + 1..r.len() { for c in b + 1..r.len() {
        let t = [r[a], r[b], r[c]];
        let m = [t[0].0, t[1].0, t[2].0];
        let mut d = det3(&m);
        if d == 0 { continue; }
        let mut y = [0; 3];
        for col in 0..3 { let mut mk = m; for k in 0..3 { mk[k][col] = t[k].1; } y[col] = det3(&mk); }
        if d < 0 { d = -d; for q in y.iter_mut() { *q = -*q; } }
        if !r.iter().all(|(g, h)| g[0] * y[0] + g[1] * y[1] + g[2] * y[2] <= h * d) { continue; }
        let g = gcd(gcd(gcd(y[0], y[1]), y[2]), d);
        let p = ([y[0] / g, y[1] / g, y[2] / g], d / g);
        if !pts.contains(&p) { pts.push(p); }
    } } }
    let whole = pts.iter().filter(|p| p.1 == 1).count();
    let mut best = pts[0];
    for &p in &pts { if plan_cost(p.0, p.1, dem) * best.1 < plan_cost(best.0, best.1, dem) * p.1 { best = p; } }
    (pts.len(), whole, best.0, best.1 * s, plan_cost(best.0, best.1, dem))
}
fn whole_best(budget: i64) -> (usize, i64) {
    let r = rows(SUPPLY, DEMAND, budget);
    let (mut n, mut best) = (0, i64::MAX);
    for a in 0..=DEMAND[0] { for b in 0..=DEMAND[1] { for c in 0..=DEMAND[2] {
        if r.iter().all(|(g, h)| g[0] * a + g[1] * b + g[2] * c <= *h) { n += 1; best = best.min(plan_cost([a, b, c], 1, DEMAND)); }
    } } }
    (n, best)
}

fn main() {
    let o = transport(COST, SUPPLY, DEMAND, true);
    let mut xs = o.x.clone(); xs.sort();
    println!("best plan: {} | cost {}, pivots {}", list(&xs), o.cost, o.k);
    println!("prices: u North {}, South {}; v W1 {}, W2 {}, W3 {}, spare {}", o.u[0], o.u[1], o.v[0], o.v[1], o.v[2], o.v[3]);
    println!("reduced costs, unused routes: {}", list(&o.red));
    let amounts = [SUPPLY[0], SUPPLY[1], DEMAND[0], DEMAND[1], DEMAND[2], SUPPLY.iter().sum::<i64>() - DEMAND.iter().sum::<i64>()];
    let prices = [o.u[0], o.u[1], o.v[0], o.v[1], o.v[2], o.v[3]];
    let dual: i64 = (0..6).map(|k| amounts[k] * prices[k]).sum();
    println!("dual value: supplies times u plus demands times v = {}", dual);
    let (nc, nw, cb, cd, cn) = corners(SUPPLY, DEMAND, 0, 1);
    println!("corners {}, whole {}, best corner, North sends {}, cost {}", nc, nw, show(cb, cd), fr(cn, cd));
    let (np, wb) = whole_best(0);
    println!("whole plans {}, best {}; South lorry hours in best plan {}", np, wb, south_hours(cb));
    let (hc, hw, hb, hd, hn) = corners(SUPPLY, DEMAND, BUDGET, 1);
    let (hp, hwb) = whole_best(BUDGET);
    println!("break, hours <= {}: corners {}, whole {}, best: North sends {}, South-W2 {}, cost {} = {}", BUDGET, hc, hw, show(hb, hd), fr(DEMAND[1] * hd - hb[1], hd), fr(hn, hd), hn as f64 / hd as f64);
    println!("break, hours <= {}: whole plans {}, best whole plan {}", BUDGET, hp, hwb);
    let f = (0..3).find(|&j| hb[j] % hd != 0).unwrap(); // the route with a half tonne
    let (up, mut down) = ([hb[0] / hd, hb[1] / hd, hb[2] / hd], [hb[0] / hd, hb[1] / hd, hb[2] / hd]);
    down[f] += 1;
    println!("break, round South-{} up to {} t: hours {}; down to {} t: hours {}, cost {}", NAMES[f], DEMAND[f] - up[f], south_hours(up), DEMAND[f] - down[f], south_hours(down), plan_cost(down, 1, DEMAND));
    let (_, _, fb, fd, fnum) = corners([80, 61], [50, 40, 30], 0, 2); // South 30.5 t, in half tonnes
    println!("break, South 30.5 t: best: North sends {}, cost {} = {}", show(fb, fd), fr(fnum, fd), fnum as f64 / fd as f64);
    println!("break, supply as equality: supply {} t, demand {} t, no plan fits", SUPPLY.iter().sum::<i64>(), DEMAND.iter().sum::<i64>());
    let t1 = transport(COST, [40, 35], DEMAND, false).cost;
    let t2 = transport(COST, SUPPLY, [25, 21, 15], false).cost;
    let o3 = transport([[6, 7, 10], [4, 6, 7]], SUPPLY, DEMAND, false);
    let (_, _, _, t4d, t4n) = corners(SUPPLY, DEMAND, 56, 1);
    println!("try, South 35 t: {}; W2 needs 21 t: {}; hours <= 56: {}", t1, t2, fr(t4n, t4d));
    let mut x3 = o3.x; x3.sort();
    println!("try, S-W1 at 4: {} | cost {}", list(&x3), o3.cost);
    println!("figure, North (60 80) South (60 180) spare (290 35) W1 (290 95) W2 (290 155) W3 (290 215)");
    assert!(o.cost * cd == cn && o.cost == wb && wb == 380, "simplex, all corners and all whole plans must agree");
    assert!(dual == o.cost && o.red.iter().all(|r| r.2 >= 0), "prices certify the plan: no route undercuts them");
    let north: Vec<i64> = (0..3).map(|j| o.x.iter().find(|r| r.0 == 0 && r.1 == j).map_or(0, |r| r.2)).collect();
    assert!(nw == nc && cd == 1 && cb.to_vec() == north, "every corner whole; the best is the simplex plan");
    assert!(hd == 2 && hb[f] % 2 != 0 && hn < hwb * hd, "a non-network row lets a half tonne in, below the best whole plan");
    assert!(t1 == o.cost + 5 * o.u[1] && t2 == o.cost + o.v[1], "prices predict the cost of one more tonne");
    let s_w1 = o.red.iter().find(|r| r.0 == 1 && r.1 == 0).unwrap().2;
    assert!(o3.cost == o.cost + 15 * (s_w1 - 3), "S-W1 at 4: reduced cost 2 - 3 = -1 a tonne, over 15 t");
    println!("ALL CHECKS PASS");
}
