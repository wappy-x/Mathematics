// Total search problems and PPAD -- the same check as the Python, in Rust.  No crates.
// A Sperner triangle cut into 16 small triangles is walked door by door and scanned;
// every legal colouring is counted; a staff-hours collision and a shift-swap game follow.
use std::collections::HashMap;
type P = (i64, i64);
type T = [P; 3];
type Col = HashMap<P, i64>;
const M: i64 = 4; // each side of the big triangle has 4 steps

fn verts() -> Vec<P> { // a: steps right, b: rows up
    let mut v = vec![];
    for b in 0..=M { for a in 0..=M - b { v.push((a, b)); } }
    v
}
fn tris() -> (Vec<T>, Vec<T>) { // corners listed anticlockwise
    let (mut up, mut down) = (vec![], vec![]);
    for b in 0..M { for a in 0..M - b { up.push([(a, b), (a + 1, b), (a, b + 1)]); } }
    for b in 0..M - 1 { for a in 0..M - 1 - b { down.push([(a + 1, b), (a + 1, b + 1), (a, b + 1)]); } }
    (up, down)
}
fn allowed(a: i64, b: i64) -> Vec<i64> { // Sperner's rule: a side uses only its corners' colours
    if (a, b) == (0, 0) { vec![1] } else if (a, b) == (M, 0) { vec![2] } else if (a, b) == (0, M) { vec![3] }
    else if b == 0 { vec![1, 2] } else if a == 0 { vec![1, 3] } else if a + b == M { vec![2, 3] } else { vec![1, 2, 3] }
}
fn scan(all: &[T], col: &Col) -> Vec<(T, i64)> { // road one: look at all 16 triangles
    let mut found = vec![];
    for t in all {
        let cs: Vec<i64> = t.iter().map(|v| col[v]).collect();
        let mut s = cs.clone(); s.sort();
        if s == vec![1, 2, 3] {
            let anti = cs == vec![1, 2, 3] || cs == vec![2, 3, 1] || cs == vec![3, 1, 2];
            found.push((*t, if anti { 1 } else { -1 }));
        }
    }
    found
}
fn exit_door(t: &T, col: &Col) -> Option<(P, P)> { // colours running 2 then 1 anticlockwise
    for i in 0..3 { if (col[&t[i]], col[&t[(i + 1) % 3]]) == (2, 1) { return Some((t[i], t[(i + 1) % 3])); } }
    None
}
fn walk(all: &[T], col: &Col, start: T) -> (Vec<T>, &'static str) { // road two: follow doors
    let mut path = vec![start];
    loop {
        let last = *path.last().unwrap();
        let door = match exit_door(&last, col) { None => return (path, "inside"), Some(d) => d };
        let nxt: Vec<T> = all.iter().filter(|t| **t != last && t.contains(&door.0) && t.contains(&door.1)).cloned().collect();
        if nxt.is_empty() { return (path, "outside"); }
        path.push(nxt[0]);
    }
}
fn tl(t: &T) -> String { format!("[{}]", t.iter().map(|p| format!("({}, {})", p.0, p.1)).collect::<Vec<_>>().join(", ")) }
fn il(v: &[i64]) -> String { format!("[{}]", v.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(", ")) }
fn commas(n: u64) -> String {
    let s = n.to_string(); let mut out = String::new();
    for (i, ch) in s.chars().enumerate() { if i > 0 && (s.len() - i) % 3 == 0 { out.push(','); } out.push(ch); }
    out
}
fn report(up: &[T], all: &[T], col: &Col, name: &str) -> (Vec<T>, &'static str) {
    let doors: Vec<i64> = (0..M).filter(|&a| { let (x, y) = (col[&(a, 0)], col[&(a + 1, 0)]); x != y && x + y == 3 }).collect();
    let entry = *up.iter().find(|t| t[0] == (doors[0], 0)).unwrap();
    let (path, how) = walk(all, col, entry);
    println!("{}: bottom-side doors {}, first at a = {} to {}", name, doors.len(), doors[0], doors[0] + 1);
    println!("{}: walk visits {} triangles, ends {}, last {}", name, path.len(), how, tl(path.last().unwrap()));
    let cs: Vec<String> = path.iter().map(|t| t.iter().map(|v| col[v].to_string()).collect::<String>()).collect();
    println!("{}: colours along the walk {}", name, cs.join(" "));
    (path, how)
}
fn every(v: &[P], opts: &[Vec<i64>], mut f: impl FnMut(&Col)) { // road three: every colouring
    let mut idx = vec![0usize; opts.len()];
    loop {
        let col: Col = v.iter().zip(opts).zip(&idx).map(|((p, o), &i)| (*p, o[i])).collect();
        f(&col);
        let mut k = 0;
        while k < idx.len() && idx[k] == opts[k].len() - 1 { idx[k] = 0; k += 1; }
        if k == idx.len() { return; }
        idx[k] += 1;
    }
}
fn main() {
    let v = verts();
    let base = [1, 2, 2, 2, 2, 1, 1, 1, 2, 3, 2, 2, 1, 3, 3]; // the card's colouring
    let colr: Col = v.iter().cloned().zip(base.iter().cloned()).collect();
    let (up, down) = tris();
    let all: Vec<T> = up.iter().chain(down.iter()).cloned().collect();
    let (path, how) = report(&up, &all, &colr, "card");
    let found = scan(&all, &colr);
    let signs: Vec<i64> = found.iter().map(|f| f.1).collect();
    println!("scan of 16 triangles: {} three-coloured, signs {}, sum {}", found.len(), il(&signs), signs.iter().sum::<i64>());
    for (t, s) in &found { println!("  three-coloured {} sign {:+}", tl(t), s); }
    let src = found.iter().find(|f| f.1 == -1).unwrap().0;
    let (p2, how2) = walk(&all, &colr, src);
    println!("walk from the inside source ends {} after {} triangles at {}", how2, p2.len(), tl(p2.last().unwrap()));
    assert!(how == "inside" && found.iter().any(|f| f.0 == *path.last().unwrap()));
    assert!(how2 == "inside" && p2.last() != path.last());
    assert!(v.iter().all(|p| allowed(p.0, p.1).contains(&colr[p])) && found.len() == 3 && signs.iter().sum::<i64>() == 1);
    let opts: Vec<Vec<i64>> = v.iter().map(|p| allowed(p.0, p.1)).collect();
    let mut tally: HashMap<usize, u64> = HashMap::new();
    let (mut total, mut signed_ok) = (0u64, true);
    every(&v, &opts, |c| { let f = scan(&all, c); *tally.entry(f.len()).or_insert(0) += 1; total += 1;
        signed_ok = signed_ok && f.iter().map(|x| x.1).sum::<i64>() == 1; });
    let mut keys: Vec<usize> = tally.keys().cloned().collect(); keys.sort();
    let parts: Vec<String> = keys.iter().map(|k| format!("{}: {}", k, tally[k])).collect();
    println!("legal colourings {}; three-coloured counts {}", total, parts.join(", "));
    let odd = keys.iter().all(|k| k % 2 == 1);
    println!("every legal colouring: count odd {}, signed sum 1 {}", if odd { "yes" } else { "no" }, if signed_ok { "yes" } else { "no" });
    assert!(total == 512 * 27 && odd && signed_ok);
    let bad: Vec<Vec<i64>> = v.iter().zip(&opts).map(|(p, o)| if *p == (0, M) { vec![2] } else { o.clone() }).collect();
    let (mut none, mut nbad) = (0u64, 0u64);
    every(&v, &bad, |c| { nbad += 1; if scan(&all, c).is_empty() { none += 1; } });
    let mut broken = colr.clone(); broken.insert((0, M), 2);
    println!("top corner coloured 2: {} of {} colourings have none; the card's colouring then has {}", none, nbad, scan(&all, &broken).len());
    let mut three = colr.clone(); three.insert((2, 0), 1); // bottom 1,2,1,2,2: three doors
    let (_p3, how3) = report(&up, &all, &three, "three doors");
    assert!(none > 0 && nbad == total && how3 == "outside");

    for n in [8u32, 12, 16] { // a line of 2^n nodes named by n bits (Gray code)
        let (mut node, mut steps) = (0u64, 0u64);
        loop {
            let (mut i, mut g) = (node, node >> 1);
            while g > 0 { i ^= g; g >>= 1; } // decode the Gray name to a position
            if i == (1u64 << n) - 1 { break; }
            node = (i + 1) ^ ((i + 1) >> 1); // successor: next position, re-encoded
            steps += 1;
        }
        println!("line of {}-bit nodes walked: {} steps; 2^{} - 1 = {}", n, steps, n, (1u64 << n) - 1);
        assert!(steps == (1u64 << n) - 1);
    }
    println!("a 40-bit line: up to {} steps", commas((1u64 << 40) - 1));

    let hours: [i64; 10] = [38, 12, 25, 40, 16, 33, 21, 45, 8, 29]; // weekly hours, each at most 48
    let mut seen: HashMap<i64, usize> = HashMap::new();
    let mut pair = (0usize, 0usize);
    for mask in 0..1usize << 10 {
        let s: i64 = (0..10).filter(|j| mask >> j & 1 == 1).map(|j| hours[j]).sum();
        if let Some(&m0) = seen.get(&s) { pair = (m0, mask); break; }
        seen.insert(s, mask);
    }
    let common = pair.0 & pair.1;
    let grp = |m: usize| -> Vec<i64> { (0..10).filter(|j| (m & !common) >> j & 1 == 1).map(|j| hours[j]).collect() };
    let (g1, g2) = (grp(pair.0), grp(pair.1));
    println!("staff groups {}; hours each at most 48, so totals 0 to {}: {} values; after {} groups: {} and {}, both {} hours", 1 << 10, 10 * 48, 10 * 48 + 1, pair.1 + 1, il(&g1), il(&g2), g1.iter().sum::<i64>());
    assert!(g1.iter().sum::<i64>() == g2.iter().sum::<i64>() && g1.iter().all(|h| !g2.contains(h)) && g1 != g2);

    let a = |s: usize, t: usize| [[2i64, 0], [0, 1]][s][t]; // rows: A's shift (0 Early, 1 Late)
    let b = |s: usize, t: usize| [[1i64, 0], [0, 2]][s][t]; // cols: B's shift
    let (pn, pd) = (b(1, 1) - b(1, 0), b(0, 0) - b(1, 0) - b(0, 1) + b(1, 1));
    let (rn, rd) = (a(1, 1) - a(0, 1), a(0, 0) - a(0, 1) - a(1, 0) + a(1, 1));
    println!("formula: A takes Early with chance {}/{}, B takes Early with chance {}/{}, Late {}/{}", pn, pd, rn, rd, rd - rn, rd);
    let mut eqs = vec![];
    for k in 0..=60i64 { // road two: every pair of chances in steps of 1/60
        for l in 0..=60i64 {
            let (pr, pc) = ([k, 60 - k], [l, 60 - l]);
            let ua: Vec<i64> = (0..2).map(|s| (0..2).map(|t| a(s, t) * pc[t]).sum()).collect();
            let ub: Vec<i64> = (0..2).map(|t| (0..2).map(|s| b(s, t) * pr[s]).sum()).collect();
            let (xa, xb) = (k * ua[0] + (60 - k) * ua[1], l * ub[0] + (60 - l) * ub[1]);
            if xa == 60 * ua[0].max(ua[1]) && xb == 60 * ub[0].max(ub[1]) { eqs.push((k, l, xa, xb)); }
        }
    }
    for (k, l, x, y) in &eqs {
        println!("equilibrium: A Early {}/60, B Early {}/60; payoffs A {:.4}, B {:.4}", k, l, *x as f64 / 3600.0, *y as f64 / 3600.0);
    }
    println!("equilibria found by search: {} (odd)", eqs.len());
    let kl: Vec<(i64, i64)> = eqs.iter().map(|e| (e.0, e.1)).collect();
    assert!(kl == vec![(0, 0), (40, 20), (60, 60)]);
    assert!(eqs[1].0 * pd == 60 * pn && eqs[1].1 * rd == 60 * rn); // formula meets search
    let own = (a(1, 1) - a(1, 0), a(0, 0) - a(1, 0) - a(0, 1) + a(1, 1));
    println!("wrong: A's mix from A's own payoffs, Early {}/{}; B then gets Early {}/{}, Late {}/{}", own.0, own.1, b(0, 0) * own.0, own.1, b(1, 1) * (own.1 - own.0), own.1);
    println!("figure, side 320 px, corners (40, 330) (360, 330) (200, {:.2}); walk {} triangles", 330.0 - 160.0 * 3f64.sqrt(), path.len());
    println!("ALL CHECKS PASS");
}
