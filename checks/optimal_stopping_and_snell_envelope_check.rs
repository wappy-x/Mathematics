// Optimal stopping and the Snell envelope -- the check behind the card.  Rust std only.
// Selling a house: one offer a month for 3 months, 380,000, 400,000 or 430,000 dollars with
// chances 0.3, 0.5, 0.2, independent month to month.  Holding the house costs 3,000 dollars a
// month; the month-3 offer must be taken.  Three roads to the best average result: backward
// induction on the tree (the Snell envelope), brute force over every stopping rule, simulation.
use std::collections::HashMap;

const X: [i64; 3] = [380000, 400000, 430000];
const WT: [i64; 3] = [3, 5, 2]; // chances in tenths
const COST: i64 = 3000;
const N: usize = 3;
type H = Vec<usize>;

fn splitmix(s: &mut u64) -> u64 {
    *s = s.wrapping_add(0x9E3779B97F4A7C15);
    let mut z = (*s ^ (*s >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    z ^ (z >> 31)
}
fn nodes(n: usize) -> Vec<H> {
    let mut out: Vec<H> = vec![vec![]];
    for _ in 0..n {
        out = out.iter().flat_map(|h| (0..3).map(move |i| { let mut g = h.clone(); g.push(i); g })).collect();
    }
    out
}
fn z(h: &[usize]) -> i64 { X[h[h.len() - 1]] - COST * h.len() as i64 } // offer minus costs
fn ext(h: &[usize], i: usize) -> H { let mut g = h.to_vec(); g.push(i); g }
fn wsum(v: &HashMap<H, i64>, h: &[usize]) -> i64 { (0..3).map(|i| WT[i] * v[&ext(h, i)]).sum() }
fn is_envelope_above(v: &HashMap<H, i64>) -> bool {
    let dom = (1..=N).all(|n| nodes(n).iter().all(|h| v[h] >= z(h)));
    let sup = (0..N).all(|n| nodes(n).iter().all(|h| 10 * v[h] >= wsum(v, h)));
    dom && sup
}
fn weight(p: &[usize]) -> i64 { p.iter().map(|&i| WT[i]).product() }
fn stop_month(p: &[usize], stop: &dyn Fn(&[usize]) -> bool) -> usize {
    (1..=N).find(|&k| k == N || stop(&p[..k])).unwrap()
}
fn value(paths: &[H], stop: &dyn Fn(&[usize]) -> bool) -> i64 { // 1000 x expected reward
    paths.iter().map(|p| weight(p) * z(&p[..stop_month(p, stop)])).sum()
}

fn main() {
    // Road 1: the Snell envelope, backward from month 3.  C = value of waiting one more month.
    let (mut u, mut c): (HashMap<H, i64>, HashMap<H, i64>) = (HashMap::new(), HashMap::new());
    for n in (0..=N).rev() {
        for h in nodes(n) {
            if n < N { let t = wsum(&u, &h); assert!(t % 10 == 0); c.insert(h.clone(), t / 10); }
            let val = if n == N { z(&h) } else if n == 0 { c[&h] } else { z(&h).max(c[&h]) };
            u.insert(h, val);
        }
    }
    let paths = nodes(N);
    let snell_rule = |h: &[usize]| u[h] == z(h);
    // Road 2: every stopping rule.  For each month-1 offer: sell (0), or wait and choose, for each
    // month-2 offer, sell or wait (1 + 3-bit mask).  9 choices for each of 3 offers: 729 rules.
    let (mut best, mut nbest, mut count, mut snell_seen) = (i64::MIN, 0, 0, 0);
    for code in 0..729usize {
        let ch: Vec<usize> = (0..3).map(|i| (code / 9usize.pow(i)) % 9).collect();
        let stop = |h: &[usize]| if h.len() == 1 { ch[h[0]] == 0 } else { ch[h[0]] > 0 && ((ch[h[0]] - 1) >> h[1]) & 1 == 1 || ch[h[0]] == 0 };
        let v = value(&paths, &stop);
        count += 1;
        if v > best { best = v; nbest = 0; }
        if v == best { nbest += 1; }
        let same = (1..=2).all(|n| nodes(n).iter().filter(|h| n == 1 || !snell_rule(&h[..1])).all(|h| stop(h) == snell_rule(h)));
        if same { snell_seen = v; }
    }
    assert!(best == 1000 * u[&vec![]]); // road 1 = road 2, exact dollars
    assert!(nbest == 1); // exactly one rule attains the best value ...
    assert!(snell_seen == best); // ... and it is the envelope's rule
    assert!(is_envelope_above(&u));
    let mut lowered = 0;
    for n in 0..=N {
        for h in nodes(n) { let mut v = u.clone(); *v.get_mut(&h).unwrap() -= 1; if !is_envelope_above(&v) { lowered += 1; } }
    }
    assert!(lowered == 40); // lower U by 1 dollar anywhere and it fails
    let mut prophet: HashMap<H, i64> = HashMap::new();
    for n in 0..=N {
        for h in nodes(n) {
            let t: i64 = paths.iter().filter(|p| p[..n] == h[..])
                .map(|p| weight(&p[n..]) * (n.max(1)..=N).map(|k| z(&p[..k])).max().unwrap()).sum();
            prophet.insert(h, t / 10i64.pow((N - n) as u32));
        }
    }
    assert!(is_envelope_above(&prophet)); // another supermartingale above Z ...
    assert!(prophet.iter().all(|(h, v)| *v >= u[h])); // ... sits above U at every node
    let root: H = vec![];
    println!("house: offers {} / {} / {} dollars, chances {} / {} / {}, cost {} a month", X[0], X[1], X[2],
        WT[0] as f64 / 10.0, WT[1] as f64 / 10.0, WT[2] as f64 / 10.0, COST);
    println!("Snell value U_0, backward induction    {}", u[&root]);
    println!("best of {} stopping rules, brute force {}  (rules attaining it: {})", count, best / 1000, nbest);
    for n in 1..=3usize {
        let h: H = vec![0; n - 1];
        let row: Vec<String> = (0..3).map(|i| format!("{}->{} U={}", X[i], if snell_rule(&ext(&h, i)) { "sell" } else { "wait" }, u[&ext(&h, i)])).collect();
        let wait = if n < N { c[&ext(&h, 0)].to_string() } else { "-".to_string() };
        println!("month {}: wait value {}  {}", n, wait, row.join("  "));
    }
    println!("supermartingale and above Z at all nodes: {}; lowered by 1 dollar and broken at {} of 40 nodes",
        if is_envelope_above(&u) { "True" } else { "False" }, lowered);
    println!("prophet's process (sees all offers) at month 0: {}, at least U at all 40 nodes", prophet[&root]);
    let rules: Vec<(&str, Box<dyn Fn(&[usize]) -> bool>)> = vec![
        ("Snell rule", Box::new(|h: &[usize]| snell_rule(h))),
        ("myopic: sell if Z_n >= E[Z_n+1]", Box::new(|h: &[usize]| z(h) >= (0..3).map(|i| WT[i] * X[i]).sum::<i64>() / 10 - COST * (h.len() as i64 + 1))),
        ("hold out for 430000", Box::new(|h: &[usize]| h[h.len() - 1] == 2)),
        ("take the first offer", Box::new(|_h: &[usize]| true)),
    ];
    for (name, r) in &rules {
        let v = value(&paths, r.as_ref());
        println!("rule value  {:<34} {}  chart {:.2}", name, v / 1000, v as f64 / 1e6);
    }
    println!("rule value  {:<34} {}  chart {:.2}", "prophet (not a stopping time)", prophet[&root], prophet[&root] as f64 / 1000.0);
    let when: Vec<i64> = (1..=3).map(|m| paths.iter().filter(|p| stop_month(p, &snell_rule) == m).map(|p| weight(p)).sum()).collect();
    let etau: i64 = (0..3).map(|m| (m as i64 + 1) * when[m]).sum(); // 1000 x E[tau]
    let price: i64 = paths.iter().map(|p| weight(p) * X[p[stop_month(p, &snell_rule) - 1]]).sum();
    assert!(price == 1000 * u[&root] + COST * etau); // price = net value + costs paid
    println!("Snell rule sells in month 1/2/3 with chance {:.2} / {:.2} / {:.2}; E[tau] {:.2} months; E[price] {}",
        when[0] as f64 / 1000.0, when[1] as f64 / 1000.0, when[2] as f64 / 1000.0, etau as f64 / 1000.0, price / 1000);

    let zs: Vec<String> = (1..=3i64).map(|n| (0..3).map(|i| (X[i] - COST * n).to_string()).collect::<Vec<_>>().join(" ")).collect();
    println!("rewards Z_n = offer - {} n, months 1/2/3: {}", COST, zs.join("; "));
    println!("gaps: waiting on 400000 in month 1 beats selling by {}; prophet minus Snell {}; average costs paid {}",
        u[&vec![1]] - z(&[1]), prophet[&root] - u[&root], COST * etau / 1000);

    // Road 3: simulation of sellers using the envelope's rule.
    let (p_n, seed) = (100000i64, 20260930u64);
    let mut s = seed;
    let (mut tot, mut tot2, mut ntau, mut ntau2, mut nprice, mut nprice2) = (0i64, 0i128, 0i64, 0i64, 0i64, 0i128);
    for _ in 0..p_n {
        let mut h: H = vec![];
        loop {
            let u01 = (splitmix(&mut s) >> 11) as f64 / 9007199254740992.0;
            h.push(if u01 < WT[0] as f64 / 10.0 { 0 } else if u01 < (WT[0] + WT[1]) as f64 / 10.0 { 1 } else { 2 });
            if h.len() == N || snell_rule(&h) { break; }
        }
        let r = z(&h);
        tot += r; tot2 += (r as i128) * (r as i128); ntau += h.len() as i64; nprice += X[h[h.len() - 1]];
        ntau2 += (h.len() * h.len()) as i64; nprice2 += (X[h[h.len() - 1]] as i128) * (X[h[h.len() - 1]] as i128);
    }
    let pf = p_n as f64;
    let m = tot as f64 / pf;
    let se = ((tot2 as f64 / pf - m * m) / pf).sqrt();
    let (mt, mp) = (ntau as f64 / pf, nprice as f64 / pf);
    let (se_t, se_p) = (((ntau2 as f64 / pf - mt * mt) / pf).sqrt(), ((nprice2 as f64 / pf - mp * mp) / pf).sqrt());
    assert!((m - u[&root] as f64).abs() < 4.0 * se);
    println!("simulation, {} sellers, seed {}: mean {:.2}  se {:.2}  mean month {:.4}  se {:.4}  mean price {:.2}  se {:.2}",
        p_n, seed, m, se, mt, se_t, mp, se_p);

    // The deadline: V_k = best value with k offers to come (iid shortcut), then the limit with none.
    let mut vk = 0.0f64;
    let mut vks: Vec<f64> = vec![];
    for k in 1..=60 {
        vk = if k == 1 { (0..3).map(|i| WT[i] as f64 / 10.0 * X[i] as f64).sum::<f64>() - COST as f64 }
            else { (0..3).map(|i| WT[i] as f64 / 10.0 * (X[i] as f64).max(vk)).sum::<f64>() - COST as f64 };
        vks.push(vk);
    }
    assert!((vks[2] - u[&root] as f64).abs() < 1e-6); // iid shortcut = full tree
    let lim = (WT[2] as f64 / 10.0 * X[2] as f64 - COST as f64) / (1.0 - (WT[0] + WT[1]) as f64 / 10.0);
    assert!(X[1] as f64 <= lim && lim <= X[2] as f64);
    assert!((vks[59] - lim).abs() < 1.0);
    let ks: Vec<String> = (1..=12).map(|k| format!("{:7}", k)).collect();
    let vs: Vec<String> = (1..=12).map(|k| format!("{:7.2}", vks[k - 1] / 1000.0)).collect();
    println!("chart, deadline months  {}", ks.join(" "));
    println!("chart, value (thousand) {}", vs.join(" "));
    println!("deadline 24: {:.2}  deadline 60: {:.2}  no deadline (fixed point): {:.2}", vks[23], vks[59], lim);
    let bids: Vec<String> = [1i64, 2, 3, 4, 12, 100].iter().map(|n| format!("n={}:{}", n, 430000 - 30000 / n)).collect();
    println!("no deadline, no cost, bids 430000 - 30000/n: {}; sup 430000, never reached", bids.join(" "));
    let fy = |x: f64| 210.0 - (x - 370000.0) / 400.0;
    let ny: Vec<String> = X.iter().map(|&x| format!("{:.1}", fy(x as f64))).collect();
    println!("figure, node x 80 180 280; node y {}; bar y {:.2} {:.2}", ny.join(" "), fy(vks[1]), fy(vks[0]));
}
