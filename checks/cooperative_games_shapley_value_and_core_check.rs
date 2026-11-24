// Sharing a joint cost: the Shapley value and the core -- the same check as the Python, in Rust.
// No crates.  Money is in whole pounds; a share is an exact fraction top/bottom.
// Game 1, the oven: three bakeries bake in turns in one oven sized for the biggest.  Alone they
// need ovens costing 1000, 2000 and 3000 pounds, so a group S pays the dearest: c(S) = max need.
// Game 2, the twins: a 1000-pound oven has two bakeries' shifts a night, so S pays 1000 per two.
// Shapley roads: (1) average extra cost over all n! orders, (2) the weighted sum over
// coalitions, (3) the airport rule: each step up in oven size split among those who need it.
// Core roads: (a) every coalition's limit checked directly, (b) a corner-checking LP solver.
const NAMES: [&str; 4] = ["Ash", "Birch", "Cedar", "Dock"];
type Game<'a> = &'a dyn Fn(usize) -> i64;

fn oven(needs: Vec<i64>) -> impl Fn(usize) -> i64 {
    move |s| (0..needs.len()).filter(|&i| s >> i & 1 == 1).map(|i| needs[i]).max().unwrap_or(0)
}
fn twins(s: usize) -> i64 { 1000 * ((s.count_ones() as i64 + 1) / 2) }
fn fact(k: i64) -> i64 { if k < 2 { 1 } else { k * fact(k - 1) } }
fn orders(items: &[usize]) -> Vec<Vec<usize>> { // every order of the items, written out
    if items.is_empty() { return vec![vec![]]; }
    items.iter().flat_map(|&x| {
        let rest: Vec<usize> = items.iter().copied().filter(|&y| y != x).collect();
        orders(&rest).into_iter().map(move |r| [vec![x], r].concat())
    }).collect()
}
fn commas(n: i64) -> String {
    let s = n.to_string();
    s.chars().enumerate().map(|(k, ch)| if k > 0 && (s.len() - k) % 3 == 0 { format!(",{}", ch) } else { ch.to_string() }).collect()
}
fn fmt(top: i64, bottom: i64) -> String { // pounds to 2 decimals, rounded half up, integers only
    let (sign, top) = if top < 0 { ("-", -top) } else { ("", top) };
    let cents = (200 * top + bottom) / (2 * bottom);
    format!("{}{}.{:02}", sign, commas(cents / 100), cents % 100)
}
fn join(v: &[i64], d: i64) -> String { v.iter().map(|&x| fmt(x, d)).collect::<Vec<_>>().join(", ") }

fn shapley_orders(c: Game, n: usize) -> Vec<i64> { // road 1: n! times each share
    let mut tot = vec![0; n];
    for order in orders(&(0..n).collect::<Vec<_>>()) {
        let mut s = 0;
        for &i in &order { tot[i] += c(s | 1 << i) - c(s); s |= 1 << i; }
    }
    tot
}
fn shapley_subsets(c: Game, n: usize) -> Vec<i64> { // road 2: |S|!(n-|S|-1)! weights, also over n!
    let mut tot = vec![0; n];
    for i in 0..n {
        for s in (0..(1usize << n)).filter(|s| s >> i & 1 == 0) {
            let k = s.count_ones() as i64;
            tot[i] += fact(k) * fact(n as i64 - k - 1) * (c(s | 1 << i) - c(s));
        }
    }
    tot
}
fn airport(needs: &[i64]) -> Vec<i64> { // road 3: n! times each share, smallest need first
    let n = needs.len();
    let mut idx: Vec<usize> = (0..n).collect();
    idx.sort_by_key(|&i| needs[i]);
    let (mut tot, mut acc, mut prev) = (vec![0; n], 0, 0);
    for (k, &i) in idx.iter().enumerate() {
        acc += (needs[i] - prev) * fact(n as i64) / (n - k) as i64;
        (tot[i], prev) = (acc, needs[i]);
    }
    tot
}

fn core_breaks(x: &[i64], bottom: i64, c: Game, n: usize) -> Vec<usize> { // road (a)
    (1..(1usize << n) - 1).filter(|&s| (0..n).filter(|&i| s >> i & 1 == 1).map(|i| x[i]).sum::<i64>() > c(s) * bottom).collect()
}
fn det3(m: &[[i64; 3]; 3]) -> i64 {
    m[0][0] * (m[1][1] * m[2][2] - m[1][2] * m[2][1]) - m[0][1] * (m[1][0] * m[2][2] - m[1][2] * m[2][0])
        + m[0][2] * (m[1][0] * m[2][1] - m[1][1] * m[2][0])
}
type Row = ([i64; 3], i64);
fn corners(rows: &[Row]) -> Vec<(Vec<i64>, i64)> { // road (b): 3 rows tight, Cramer, keep if all rows hold
    let mut found: Vec<(Vec<i64>, i64)> = Vec::new();
    let len = rows.len();
    for a in 0..len { for b in a + 1..len { for d in b + 1..len {
        let m = [rows[a].0, rows[b].0, rows[d].0];
        let r = [rows[a].1, rows[b].1, rows[d].1];
        let mut dd = det3(&m);
        if dd == 0 { continue; }
        let mut x: Vec<i64> = (0..3).map(|col| { let mut mm = m; for k in 0..3 { mm[k][col] = r[k]; } det3(&mm) }).collect();
        if dd < 0 { dd = -dd; x = x.iter().map(|v| -v).collect(); }
        let fits = rows.iter().all(|(row, lim)| (0..3).map(|j| row[j] * x[j]).sum::<i64>() <= lim * dd);
        if fits && found.iter().all(|(y, e)| (0..3).any(|j| x[j] * e != y[j] * dd)) { found.push((x, dd)); }
    }}}
    found
}
fn limits(c: Game) -> Vec<Row> {
    (1..7usize).map(|s| ([(s & 1) as i64, (s >> 1 & 1) as i64, (s >> 2 & 1) as i64], c(s))).collect()
}
fn lp_room(c: Game) -> (i64, i64) { // most the bakeries can be charged with no coalition overcharged
    let mut best = (0, 1);
    for (x, d) in corners(&limits(c)) {
        let t: i64 = x.iter().sum();
        if t * best.1 > best.0 * d { best = (t, d); }
    }
    best
}
fn members(s: usize) -> String {
    format!("{{{}}}", (0..4).filter(|&i| s >> i & 1 == 1).map(|i| NAMES[i]).collect::<Vec<_>>().join(", "))
}

fn main() {
    let (need, f) = (vec![1000i64, 2000, 3000], fact(3));
    let c = oven(need.clone());
    let (r1, r2, r3) = (shapley_orders(&c, 3), shapley_subsets(&c, 3), airport(&need));
    for s in 1..8 { println!("oven game, c({}) = {}", members(s), c(s)); }
    let mut marginal: Vec<(String, Vec<i64>)> = Vec::new();
    for order in orders(&[0, 1, 2]) {
        let (mut s, mut extra, mut v) = (0usize, Vec::new(), vec![0i64; 3]);
        for &i in &order {
            v[i] = c(s | 1 << i) - c(s);
            extra.push(format!("{} +{}", NAMES[i], v[i]));
            s |= 1 << i;
        }
        let key: Vec<String> = order.iter().map(|&i| NAMES[i][..1].to_string()).collect();
        println!("order {}: {}; in the core: {}", key.join("-"), extra.join(", "), if core_breaks(&v, 1, &c, 3).is_empty() { "yes" } else { "no" });
        marginal.push((key.concat(), v));
    }
    for (name, r) in [("road 1, all 6 orders", &r1), ("road 2, coalition weights", &r2), ("road 3, airport steps", &r3)] {
        println!("{}: 6 x shares = {:?}; shares {}", name, r, join(r, f));
    }
    let terms: Vec<(usize, i64, i64)> = [0usize, 1, 4, 5].iter().map(|&s| (s, fact(s.count_ones() as i64) * fact(2 - s.count_ones() as i64), c(s | 2) - c(s))).collect();
    println!("Birch's road-2 terms: {}; weights add to {}/6", terms.iter().map(|&(s, w, e)| format!("{} weight {}/6 adds {} -> {}", members(s), w, e, fmt(w * e, f))).collect::<Vec<_>>().join("; "), terms.iter().map(|t| t.1).sum::<i64>());
    let steps = { let mut v = need.clone(); v.sort(); v };
    println!("airport steps: {}", (0..3).map(|k| { let d = steps[k] - if k == 0 { 0 } else { steps[k - 1] }; format!("{} shared by {} -> {} each", d, 3 - k, fmt(d, 3 - k as i64)) }).collect::<Vec<_>>().join(", "));
    println!("efficiency: shares add to {} = c(all) = {}", fmt(r1.iter().sum(), f), c(7));
    let br = core_breaks(&r1, f, &c, 3);
    println!("Shapley shares break the core for coalitions: {}; pair totals {}", if br.is_empty() { "none".to_string() } else { format!("{:?}", br) }, [3usize, 5, 6].iter().map(|&s| format!("{} {} against {}", members(s), fmt((0..3).filter(|&i| s >> i & 1 == 1).map(|i| r1[i]).sum(), f), c(s))).collect::<Vec<_>>().join(", "));
    let save: Vec<i64> = (0..3).map(|i| need[i] * f - r1[i]).collect();
    println!("savings against going alone: {}; three ovens cost {}, one shared {}, saving {}", join(&save, f), need.iter().sum::<i64>(), c(7), need.iter().sum::<i64>() - c(7));
    let core = corners(&[limits(&c), vec![([1, 1, 1], c(7)), ([-1, -1, -1], -c(7))]].concat());
    let shown: Vec<String> = core.iter().map(|(x, d)| format!("({})", join(x, *d))).collect();
    println!("core corners (Ash, Birch, Cedar): {}", shown.join("; "));
    let room = lp_room(&c);
    println!("LP room: at most {} can be charged (pair limits add to {}), need {}: core {}", fmt(room.0, room.1), c(3) + c(5) + c(6), c(7), if room.0 >= c(7) * room.1 { "non-empty" } else { "empty" });

    let t1 = shapley_orders(&twins, 3);
    println!("twins game: shares {}; a pair pays {} against c(pair) = {}", join(&t1, f), fmt(t1[0] + t1[1], f), twins(3));
    let tb = core_breaks(&t1, f, &twins, 3);
    println!("twins game: Shapley breaks the core for coalitions: {}", tb.iter().map(|&s| members(s)).collect::<Vec<_>>().join(", "));
    let troom = lp_room(&twins);
    println!("twins LP room: at most {} can be charged (pair limits add to {}), need {}: core {}", fmt(troom.0, troom.1), twins(3) + twins(5) + twins(6), twins(7), if troom.0 >= twins(7) * troom.1 { "non-empty" } else { "empty" });
    let both = shapley_orders(&|s| c(s) + twins(s), 3);
    println!("additivity: oven + twins shares {}", join(&both, f));
    let d4 = shapley_orders(&oven(vec![1000, 2000, 3000, 0]), 4);
    println!("null player: with Dock (needs no oven) shares {}", join(&d4, fact(4)));

    let banz: Vec<i64> = (0..3).map(|i| (0..8usize).filter(|&s| s >> i & 1 == 0).map(|s| c(s | 1 << i) - c(s)).sum()).collect();
    let alone_ok = [500i64, 2000, 500];
    let get = |k: &str| marginal.iter().find(|(n, _)| n == k).unwrap().1.clone();
    println!("mistake, one order only: A-B-C charges {:?}, C-B-A charges {:?}", get("ABC"), get("CBA"));
    println!("mistake, average over coalitions not orders: {}; total {}, short by {}", join(&banz, 4), fmt(banz.iter().sum(), 4), fmt(c(7) * 4 - banz.iter().sum::<i64>(), 4));
    let ab = core_breaks(&alone_ok, 1, &c, 3);
    println!("mistake, check only bakeries alone: {:?} passes alone; coalitions broken: {} (Ash+Birch pay {})", alone_ok, ab.iter().map(|&s| members(s)).collect::<Vec<_>>().join(", "), alone_ok[0] + alone_ok[1]);
    let (xf, yf) = (|v: f64| 60.0 + 0.08 * v, |v: f64| 210.0 - 0.08 * v);
    let pts: Vec<String> = core.iter().map(|(x, d)| format!("({:.1}, {:.1})", xf(x[0] as f64 / *d as f64), yf(x[1] as f64 / *d as f64))).collect();
    println!("figure, core corners at {}; Shapley at ({:.1}, {:.1}); bad split at ({:.1}, {:.1})", pts.join(", "), xf(r1[0] as f64 / f as f64), yf(r1[1] as f64 / f as f64), xf(500.0), yf(2000.0));

    assert!(r1 == r2 && r2 == r3 && r1 == vec![2000, 5000, 11000]); // three roads agree
    assert!(r1.iter().sum::<i64>() == c(7) * f && t1.iter().sum::<i64>() == twins(7) * f); // efficiency
    assert!(br.is_empty() && tb == vec![3, 5, 6]);
    assert!(room.0 >= c(7) * room.1 && troom.0 < twins(7) * troom.1 && 2 * room.0 == (c(3) + c(5) + c(6)) * room.1 && 2 * troom.0 == (twins(3) + twins(5) + twins(6)) * troom.1); // Bondareva-Shapley by corners; LP optimum = pair bound
    assert!(core.len() == 4 && t1[0] == t1[1] && t1[1] == t1[2]); // core shape, symmetry
    assert!(core.iter().all(|(x, d)| *d == 1 && marginal.iter().any(|(_, v)| v == x)) && marginal.iter().all(|(_, v)| core.iter().any(|(x, _)| x == v))); // corners = orders
    assert!((0..3).all(|i| marginal.iter().map(|(_, v)| v[i]).sum::<i64>() == r3[i]) && terms.iter().map(|t| t.1 * t.2).sum::<i64>() == r3[1]);
    assert!((0..3).all(|i| both[i] == r1[i] + t1[i]) && d4 == vec![4 * r1[0], 4 * r1[1], 4 * r1[2], 0]); // additivity, null player
    assert!(banz.iter().sum::<i64>() != c(7) * 4 && ab == vec![3]);
    println!("ALL CHECKS PASS");
}
