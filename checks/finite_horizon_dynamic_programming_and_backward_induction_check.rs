// Backward induction on a hydro reservoir -- the check behind the card.  std only, no crates.
// Water in units of 10 million m3, money in GBP thousand.  Months k = 0 (Jan) .. 11 (Dec); k = 12 is 31 Dec.
// Roads: (1) backward induction; (2) the read-off rule run forward over every rain outcome;
// (3) every storage-to-release rule for Oct-Dec listed and scored, the best compared with the table;
// (4) every one-month change to the rule, followed by the rule, scored by running forward: none may gain.
const MONTHS: [&str; 12] = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
const PRICE: [f64; 12] = [150.0, 140.0, 120.0, 100.0, 90.0, 80.0, 85.0, 90.0, 100.0, 115.0, 140.0, 150.0];
const WET: [f64; 3] = [0.2, 0.5, 0.3];
const DRY: [f64; 3] = [0.5, 0.4, 0.1];
const CAP: usize = 4;
const TURBINE: usize = 2;
const END_VALUE: f64 = 100.0;
const START: usize = 2;
type Rule = Vec<[usize; CAP + 1]>;
type Table = Vec<[f64; CAP + 1]>;

fn nxt(x: usize, u: usize, w: usize) -> usize { (x - u + w).min(CAP) }

fn backup(v1: &[f64; CAP + 1], k: usize, x: usize, u: usize, rain: &[[f64; 3]], price: &[f64]) -> f64 {
    let mut s = 0.0;
    for w in 0..3 { s += rain[k][w] * v1[nxt(x, u, w)]; }
    price[k] * u as f64 + s
}

fn solve(price: &[f64], rain: &[[f64; 3]], end: f64, turbine: usize, see_rain: bool) -> (Table, Rule) {
    let mut v: Table = vec![[0.0; CAP + 1]; 13];
    let mut rule: Rule = vec![[0; CAP + 1]; 12];
    for x in 0..=CAP { v[12][x] = end * x as f64; }
    for k in (0..12).rev() {
        for x in 0..=CAP {
            let top = x.min(turbine);
            if see_rain {
                let mut s = 0.0;
                for w in 0..3 {
                    let mut m = f64::NEG_INFINITY;
                    for u in 0..=top { m = m.max(price[k] * u as f64 + v[k + 1][nxt(x, u, w)]); }
                    s += rain[k][w] * m;
                }
                v[k][x] = s;
                continue;
            }
            let (mut best, mut best_u) = (-1.0, 0);
            for u in 0..=top {
                let q = backup(&v[k + 1], k, x, u, rain, price);
                if q > best + 1e-9 { best = q; best_u = u; }
            }
            v[k][x] = best;
            rule[k][x] = best_u;
        }
    }
    (v, rule)
}

fn run_forward(rule: &Rule, rain: &[[f64; 3]], x0: usize, first: usize, end: f64) -> f64 {
    let mut dist = [0.0; CAP + 1];
    dist[x0] = 1.0;
    let mut income = 0.0;
    for k in first..12 {
        let mut new = [0.0; CAP + 1];
        for x in 0..=CAP {
            let u = rule[k][x];
            income += dist[x] * PRICE[k] * u as f64;
            for w in 0..3 { new[nxt(x, u, w)] += dist[x] * rain[k][w]; }
        }
        dist = new;
    }
    let mut s = 0.0;
    for x in 0..=CAP { s += dist[x] * end * x as f64; }
    income + s
}

fn row(v: &[f64; CAP + 1]) -> String { v.iter().map(|a| format!("{:7.2}", a)).collect::<Vec<_>>().join(" ") }
fn ints(v: &[usize]) -> String { v.iter().map(|a| a.to_string()).collect::<Vec<_>>().join(" ") }

fn main() {
    let rain: Vec<[f64; 3]> = (0..12).map(|k| if k < 3 || k > 8 { WET } else { DRY }).collect();
    let (v, rule) = solve(&PRICE, &rain, END_VALUE, TURBINE, false);
    let qline = |v1: &[f64; CAP + 1], k: usize, x: usize| -> String {
        (0..=x.min(TURBINE)).map(|u| format!("u={}: {:6.2}", u, backup(v1, k, x, u, &rain, &PRICE)))
            .collect::<Vec<_>>().join("  ")
    };
    println!("December backups, 31 Dec water worth 100 a unit:");
    for x in 0..=CAP { println!("  x={}  {}", x, qline(&v[12], 11, x)); }
    println!("November, x=2  {}", qline(&v[11], 10, 2));
    println!("month price | release for x=0..4 | value V_k(x) for x=0..4");
    for k in 0..12 { println!("{} {:5} | {} | {}", MONTHS[k], PRICE[k] as i64, ints(&rule[k]), row(&v[k])); }
    println!("31 Dec      |           | {}", row(&v[12]));

    let best = v[0][START];
    let forward = run_forward(&rule, &rain, START, 0, END_VALUE);
    println!("road 1, backward induction, V_0(2)      {:9.2}", best);
    println!("road 2, rule run forward over the rain  {:9.2}", forward);
    assert!((best - forward).abs() < 1e-6);
    let mut gain = 0.0f64;                            // road 4: change one month's release, then follow the rule
    for k in 0..12 { for x in 0..=CAP { for u in 0..=x.min(TURBINE) {
        let mut s = 0.0;
        for w in 0..3 { s += rain[k][w] * run_forward(&rule, &rain, nxt(x, u, w), k + 1, END_VALUE); }
        gain = gain.max(PRICE[k] * u as f64 + s - run_forward(&rule, &rain, x, k, END_VALUE));
    } } }
    println!("road 4, largest gain, one-month change  {:9.4}", gain);
    assert!(gain < 1e-6);

    let mut tables: Vec<[usize; CAP + 1]> = Vec::new();
    for u1 in 0..=1 { for u2 in 0..=2 { for u3 in 0..=2 { for u4 in 0..=2 {   // x = 0 can only release 0
        tables.push([0, u1, u2, u3, u4]);
    } } } }
    let n = tables.len() as u128;
    println!("rules per month {}; whole-year rule tables {}", n, n.pow(12));
    let mut top = [-1.0f64; CAP + 1];
    for r9 in &tables { for r10 in &tables { for r11 in &tables {
        let mut w = [0.0; CAP + 1];
        for x in 0..=CAP { w[x] = END_VALUE * x as f64; }
        for (k, r) in [(11usize, r11), (10, r10), (9, r9)] {
            let mut nw = [0.0; CAP + 1];
            for x in 0..=CAP { nw[x] = backup(&w, k, x, r[x], &rain, &PRICE); }
            w = nw;
        }
        for x in 0..=CAP { top[x] = top[x].max(w[x]); }
    } } }
    println!("road 3, best of {} Oct-Dec tables: {}", n * n * n,
             top.iter().map(|a| format!("{:.2}", a)).collect::<Vec<_>>().join(" "));
    for x in 0..=CAP { assert!((top[x] - v[9][x]).abs() < 1e-6); }
    assert!((v[11][2] - (300.0 + 100.0 * (0.5 * 1.0 + 0.3 * 2.0))).abs() < 1e-9);
    assert!((backup(&v[12], 11, 4, 0, &rain, &PRICE) - 400.0).abs() < 1e-9);   // full, release 0: all rain spills

    let story_rain = [2usize, 1, 0, 0, 1, 0, 0, 0, 1, 1, 2, 2];
    let (mut x, mut income) = (START, 0i64);
    let (mut lx, mut lu) = (Vec::new(), Vec::new());
    for k in 0..12 {
        let u = rule[k][x];
        lx.push(x); lu.push(u); income += PRICE[k] as i64 * u as i64;
        x = nxt(x, u, story_rain[k]);
    }
    println!("story rain    {}", ints(&story_rain));
    println!("story storage {}  -> {} on 31 Dec", ints(&lx), x);
    println!("story release {}  income {}, plus {} in store", ints(&lu), income, END_VALUE as i64 * x as i64);

    let greedy_rule: Rule = (0..12).map(|_| { let mut t = [0; CAP + 1]; for x in 0..=CAP { t[x] = x.min(TURBINE); } t }).collect();
    let greedy = run_forward(&greedy_rule, &rain, START, 0, END_VALUE);
    let (see, _) = solve(&PRICE, &rain, END_VALUE, TURBINE, true);
    let (_, rule0) = solve(&PRICE, &rain, 0.0, TURBINE, false);
    let mode: Vec<[f64; 3]> = rain.iter().map(|r| {
        let mut m = 0;
        for w in 1..3 { if r[w] > r[m] { m = w; } }
        let mut t = [0.0; 3]; t[m] = 1.0; t
    }).collect();
    let (vm, rule_m) = solve(&PRICE, &mode, END_VALUE, TURBINE, false);
    let rows = [("wrong: release all the turbine takes", greedy),
                ("wrong: choose after seeing the rain", see[0][START]),
                ("wrong: water left on 31 Dec worth 0", run_forward(&rule0, &rain, START, 0, END_VALUE)),
                ("wrong: most likely rain, promised", vm[0][START]),
                ("wrong: most likely rain, delivered", run_forward(&rule_m, &rain, START, 0, END_VALUE))];
    for (name, val) in rows.iter() { println!("{:<40}{:9.2}", name, val); }
    assert!(greedy < best - 1.0);
    assert!(see[0][START] > best + 1.0);
    assert!(rows[2].1 < best - 1.0);
    assert!(rows[4].1 < best - 1.0);

    let mut july = PRICE;
    july[6] = 200.0;
    let wet: Vec<[f64; 3]> = vec![WET; 12];
    let tries = [("try: end value 0, plan and score", solve(&PRICE, &rain, 0.0, TURBINE, false).0[0][START]),
                 ("try: turbine 1 unit a month", solve(&PRICE, &rain, END_VALUE, 1, false).0[0][START]),
                 ("try: every month wet", solve(&PRICE, &wet, END_VALUE, TURBINE, false).0[0][START]),
                 ("try: July price 200", solve(&july, &rain, END_VALUE, TURBINE, false).0[0][START])];
    for (name, val) in tries.iter() { println!("{:<40}{:9.2}", name, val); }
    println!("end value 0, Sep and Oct release for x=0..4: {} | {}", ints(&rule0[8]), ints(&rule0[9]));
    println!("ALL CHECKS PASS");
}
