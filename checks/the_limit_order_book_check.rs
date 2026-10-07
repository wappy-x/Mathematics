// The order book -- the same check as the_limit_order_book_check.py, in Rust.
// Standard library only, no crates.  Prices are whole cents, sizes are shares.
// Compile: rustc --edition 2021 -O the_limit_order_book_check.rs -o /tmp/lob_check
use std::collections::BTreeMap;

type Order = (usize, bool, Option<i64>, i64);            // id, is it a buy, limit (None = market), shares
type Fill = (usize, usize, i64, i64);                    // taker id, maker id, price, shares
type Side = Vec<(i64, Vec<(usize, i64)>)>;               // price levels, each a queue of (id, shares)
type Snap = (Side, Side);                                // bids best first, asks best first
fn canon(entries: &[(bool, i64, usize, i64)]) -> Snap {   // (is bid, price, id, shares), queue order kept
    let (mut b, mut a): (BTreeMap<i64, Vec<(usize, i64)>>, BTreeMap<i64, Vec<(usize, i64)>>) = (BTreeMap::new(), BTreeMap::new());
    for &(bid, px, id, q) in entries { if bid { &mut b } else { &mut a }.entry(px).or_default().push((id, q)); }
    (b.into_iter().rev().collect(), a.into_iter().collect())
}
fn engine_a(orders: &[Order], newest_first: bool) -> (Vec<Fill>, Vec<Snap>) {
    // Road 1: one queue per price level, oldest order at the front.
    let mut book: [BTreeMap<i64, Vec<(usize, i64)>>; 2] = [BTreeMap::new(), BTreeMap::new()]; // [bids, asks]
    let (mut tape, mut snaps) = (vec![], vec![]);
    for &(id, buy, px, mut qty) in orders {
        let opp = &mut book[if buy { 1 } else { 0 }];
        while qty > 0 && !opp.is_empty() {
            let best = if buy { *opp.keys().next().unwrap() } else { *opp.keys().next_back().unwrap() };
            if let Some(p) = px { if if buy { best > p } else { best < p } { break; } }
            let lv = opp.get_mut(&best).unwrap();
            let i = if newest_first { lv.len() - 1 } else { 0 };
            let fill = qty.min(lv[i].1); lv[i].1 -= fill; qty -= fill;
            tape.push((id, lv[i].0, best, fill));
            if lv[i].1 == 0 { lv.remove(i); }
            if lv.is_empty() { opp.remove(&best); }
        }
        if let (true, Some(p)) = (qty > 0, px) { book[if buy { 0 } else { 1 }].entry(p).or_default().push((id, qty)); }
        let mut e = vec![];
        for (k, bid) in [(0, true), (1, false)] { for (&p, lv) in &book[k] { for &(o, q) in lv { e.push((bid, p, o, q)); } } }
        snaps.push(canon(&e));
    }
    (tape, snaps)
}
fn engine_b(orders: &[Order]) -> (Vec<Fill>, Vec<Snap>) {
    // Road 2: no levels.  One flat list, sorted by (price, arrival) for every incoming order.
    let mut rest: Vec<(usize, usize, bool, i64, i64)> = vec![];   // seq, id, is buy, price, shares
    let (mut tape, mut snaps) = (vec![], vec![]);
    for (seq, &(id, buy, px, mut qty)) in orders.iter().enumerate() {
        let sgn = if buy { 1 } else { -1 };
        let mut c: Vec<usize> = (0..rest.len())
            .filter(|&i| rest[i].2 != buy && px.map_or(true, |p| sgn * (p - rest[i].3) >= 0)).collect();
        c.sort_by_key(|&i| (sgn * rest[i].3, rest[i].0));
        for i in c {
            if qty == 0 { break; }
            let fill = qty.min(rest[i].4); rest[i].4 -= fill; qty -= fill;
            tape.push((id, rest[i].1, rest[i].3, fill));
        }
        rest.retain(|r| r.4 > 0);
        if let (true, Some(p)) = (qty > 0, px) { rest.push((seq, id, buy, p, qty)); }
        snaps.push(canon(&rest.iter().map(|r| (r.2, r.3, r.1, r.4)).collect::<Vec<_>>()));
    }
    (tape, snaps)
}
fn tops(s: &Snap) -> Option<(i64, i64, i64, i64, i64, i64)> {   // best bid, shares, best ask, shares, depths
    if s.0.is_empty() || s.1.is_empty() { return None; }
    let qs = |lv: &(i64, Vec<(usize, i64)>)| lv.1.iter().map(|x| x.1).sum::<i64>();
    let dep = |side: &Side| side.iter().take(3).map(|lv| qs(lv)).sum::<i64>();
    Some((s.0[0].0, qs(&s.0[0]), s.1[0].0, qs(&s.1[0]), dep(&s.0), dep(&s.1)))
}
fn ofi_book(p: (i64, i64, i64, i64, i64, i64), c: (i64, i64, i64, i64, i64, i64)) -> i64 {  // OFI road A
    (if c.0 >= p.0 { c.1 } else { 0 }) - (if c.0 <= p.0 { p.1 } else { 0 })
        - (if c.2 <= p.2 { c.3 } else { 0 }) + (if c.2 >= p.2 { p.3 } else { 0 })
}
fn ofi_order(o: &Order, p: (i64, i64, i64, i64, i64, i64), tape: &[Fill]) -> i64 {         // OFI road B
    let (id, buy, px, qty) = *o;
    let fills: Vec<&Fill> = tape.iter().filter(|f| f.0 == id).collect();
    let rested = if px.is_some() { qty - fills.iter().map(|f| f.3).sum::<i64>() } else { 0 };
    let at = |lvl: i64| fills.iter().filter(|f| f.2 == lvl).map(|f| f.3).sum::<i64>();
    if buy { at(p.2) + if rested > 0 && px.unwrap() >= p.0 { rested } else { 0 } }
    else { -at(p.0) - if rested > 0 && px.unwrap() <= p.2 { rested } else { 0 } }
}
fn audit(orders: &[Order], tape: &[Fill], snaps: &[Snap]) -> (i64, i64, usize) {
    let (mut ta, mut tb, mut crossed) = (0, 0, 0);
    for n in 1..orders.len() {
        let (p, c) = (tops(&snaps[n - 1]), tops(&snaps[n]));
        if let Some(c) = c { if c.0 >= c.2 { crossed += 1; } }
        if let (Some(p), Some(c)) = (p, c) { ta += ofi_book(p, c); tb += ofi_order(&orders[n], p, tape); }
    }
    (ta, tb, crossed)
}
fn d(c: i64) -> String { format!("{:.2}", c as f64 / 100.0) }
fn side_str(s: &Side) -> String {
    s.iter().map(|(p, lv)| format!("{}:{}", d(*p), lv.iter().map(|x| x.1.to_string()).collect::<Vec<_>>().join("+")))
        .collect::<Vec<_>>().join("  ")
}
fn main() {
    let ten: Vec<Order> = vec![(1, true, Some(9998), 300), (2, false, Some(10002), 200), (3, true, Some(9999), 100),
        (4, false, Some(10001), 300), (5, true, Some(9999), 200), (6, false, Some(10001), 100), (7, false, Some(10003), 400),
        (8, true, None, 350), (9, false, Some(9998), 100), (10, true, Some(10000), 200)];
    let ((tape, snaps), (tape_b, snaps_b)) = (engine_a(&ten, false), engine_b(&ten));
    println!("event  order          bid     ask  spread      mid  Qbid  Qask  imbal   OFI-A OFI-B");
    for (n, o) in ten.iter().enumerate() {
        let what = format!("{} {} x{}", if o.1 { "B" } else { "S" }, o.2.map_or("mkt".to_string(), d), o.3);
        let t = match tops(&snaps[n]) { Some(t) => t, None => { println!("{:>5}  {:<14}   (one side empty)", n + 1, what); continue; } };
        let (fa, fb) = match if n > 0 { tops(&snaps[n - 1]) } else { None } {
            Some(p) => (ofi_book(p, t).to_string(), ofi_order(o, p, &tape).to_string()), None => ("-".into(), "-".into()) };
        println!("{:>5}  {:<14} {:>6} {:>7} {:>7} {:8.3} {:>5} {:>5} {:6.3} {:>7} {:>5}", n + 1, what, d(t.0), d(t.2), d(t.2 - t.0),
            (t.0 + t.2) as f64 / 200.0, t.1, t.3, (t.1 - t.3) as f64 / (t.1 + t.3) as f64, fa, fb);
    }
    for f in &tape { println!("trade: order {} takes {} shares from order {} at {}", f.0, f.3, f.1, d(f.2)); }
    for (label, n) in [("after order 7:", 6), ("after order 10:", 9)] { println!("{:<16}asks {}  |  bids {}", label, side_str(&snaps[n].1), side_str(&snaps[n].0)); }
    let (b, qb, a, qa, db, da) = tops(&snaps[9]).unwrap();
    let (imb, s, m) = ((qb - qa) as f64 / (qb + qa) as f64, (a - b) as f64 / 100.0, (a + b) as f64 / 200.0);
    let wmid_w = (a * qb + b * qa) as f64 / (qb + qa) as f64 / 100.0;   // weight each price by the OTHER queue
    let wmid_i = m + imb * s / 2.0;                                      // mid plus imbalance times half-spread
    let mut left: BTreeMap<usize, i64> = ten.iter().map(|o| (o.0, o.3)).collect();   // Road 3: rebuild from tape
    for f in &tape { *left.get_mut(&f.0).unwrap() -= f.3; *left.get_mut(&f.1).unwrap() -= f.3; }
    let mut rebuilt: BTreeMap<(bool, i64), i64> = BTreeMap::new();
    for o in &ten { if let (Some(p), true) = (o.2, left[&o.0] > 0) { *rebuilt.entry((o.1, p)).or_default() += left[&o.0]; } }
    let engine_lv: BTreeMap<(bool, i64), i64> = [(true, &snaps[9].0), (false, &snaps[9].1)].iter()
        .flat_map(|(bid, side)| side.iter().map(move |(p, lv)| ((*bid, *p), lv.iter().map(|x| x.1).sum::<i64>()))).collect();
    let (ofi_a, ofi_b, _) = audit(&ten, &tape, &snaps);
    let t2 = tops(&snaps[1]).unwrap(); let m2 = (t2.0 + t2.2) as f64 / 200.0;
    println!("spread {:.2}   mid {:.3}   top imbalance {:.3}   depth, 3 levels: bids {} asks {}   depth imbalance {:.3}",
        s, m, imb, db, da, (db - da) as f64 / (db + da) as f64);
    println!("weighted mid, by weights {:.3}   by mid + I*s/2 {:.3}", wmid_w, wmid_i);
    println!("OFI orders 3-10: road A {}   road B {}   mid moved {:+.3} since order 2", ofi_a, ofi_b, m - m2);
    let agree = tape == tape_b && snaps == snaps_b;
    println!("book rebuilt from tape equals engine book: {}   engines agree: {}", if rebuilt == engine_lv { "True" } else { "False" }, if agree { "True" } else { "False" });
    let traded: i64 = tape.iter().map(|f| f.3).sum();
    println!("shares: submitted {} = resting {} + 2 x traded {}", ten.iter().map(|o| o.3).sum::<i64>(), engine_lv.values().sum::<i64>(), traded);
    println!("wrong: newest first at a level, order 9 fills order {} (right: order {})", engine_a(&ten, true).0[2].1, tape[2].1);
    let f9: Vec<&Fill> = tape.iter().filter(|f| f.0 == 9).collect();
    println!("wrong: order 9 priced at its own limit ${} (right: ${})", d(f9.iter().map(|f| f.3).sum::<i64>() * 9998),
        d(f9.iter().map(|f| f.2 * f.3).sum::<i64>()));
    println!("wrong: spread from last two trade prices {:.2} (right: {:.2})", (tape[1].2 - tape[2].2).abs() as f64 / 100.0, s);
    println!("wrong: weight each price by its own queue {:.3} (right: {:.3})", (b * qb + a * qa) as f64 / (qb + qa) as f64 / 100.0, wmid_w);
    let swap: Vec<Order> = [0, 1, 4, 3, 2, 5, 6, 7, 8, 9].iter().map(|&i| ten[i]).collect();
    let mut big = ten.clone(); big[7] = (8, true, None, 450);
    let mut up = ten.clone(); up[9] = (10, true, Some(10001), 200);
    for (label, ords) in [("try: order 5 before order 3", swap), ("try: market buy of 450", big), ("try: order 10 bids 100.01", up)] {
        let (tp, sn) = engine_a(&ords, false); let t = tops(sn.last().unwrap()).unwrap();
        println!("{}: {} trades, order 9 fills order {}, bid {} x{}, ask {} x{}, spread {}", label, tp.len(),
            tp.iter().find(|f| f.0 == 9).unwrap().1, d(t.0), t.1, d(t.2), t.3, d(t.2 - t.0));
    }

    let mut x: u64 = 20260928;                                     // Road 4: a random stress test, own generator
    let mut rnd = move || { x = x.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407); (x >> 11) as f64 / (1u64 << 53) as f64 };
    let (mut orders, mut counts): (Vec<Order>, Vec<f64>) = (vec![], vec![]);
    for _sec in 0..500 {                                           // orders per second ~ Poisson(4), Knuth's method
        let (mut k, mut p) = (0, rnd());
        while p > (-4.0f64).exp() { k += 1; p *= rnd(); }
        counts.push(k as f64);
        for _ in 0..k {
            let buy = rnd() < 0.5;
            let px = if rnd() < 0.2 { None } else { Some(9995 + (rnd() * 11.0) as i64) };
            let id = orders.len() + 1; orders.push((id, buy, px, 100 * (1 + (rnd() * 5.0) as i64)));
        }
    }
    let mean = counts.iter().sum::<f64>() / counts.len() as f64; let var = counts.iter().map(|c| (c - mean) * (c - mean)).sum::<f64>() / counts.len() as f64;
    let ((ta, sa), (tb, sb)) = (engine_a(&orders, false), engine_b(&orders)); let (ra, rb, crossed) = audit(&orders, &ta, &sa);
    println!("random: {} orders in 500 s, per second mean {:.3} variance {:.3}", orders.len(), mean, var);
    println!("random: {} trades, {} shares, engines agree: {}, crossed books {}", ta.len(), ta.iter().map(|f| f.3).sum::<i64>(),
        if ta == tb && sa == sb { "True" } else { "False" }, crossed);
    println!("random: OFI road A {}   road B {}", ra, rb);
    assert!(tape == tape_b && snaps == snaps_b, "two engines, same ten orders");
    assert!((tape.iter().map(|f| (f.2, f.3)).collect::<Vec<_>>(), tops(&snaps[9]), ofi_a) == (vec![(10001, 300), (10001, 50), (9999, 100)],
        Some((10000, 200, 10001, 50, 700, 650)), 350), "the hand-worked tape, top of book, depths and OFI");
    assert!(rebuilt == engine_lv, "book rebuilt from the tape must equal the engine's book");
    assert!((wmid_w - wmid_i).abs() < 1e-9, "weighted mid = mid + imbalance x half-spread");
    assert!(ofi_a == ofi_b, "order flow imbalance, snapshot road vs order road");
    assert!(ta == tb && sa == sb, "random stress test: two engines, same trades, same books");
    assert!(ra == rb, "random stress test: OFI by snapshots vs by orders");
    assert!(crossed == 0, "random stress test: best bid always below best ask");
    println!("ALL CHECKS PASS");
}
