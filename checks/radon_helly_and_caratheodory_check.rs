// Radon, Helly and Caratheodory in the plane, from one engine: weights on four points
// that add to 0 and balance to (0, 0).  No crates.  Each fact meets a brute force.
type Pt = (f64, f64);
fn turn(a: Pt, b: Pt, c: Pt) -> f64 { (b.0 - a.0) * (c.1 - a.1) - (b.1 - a.1) * (c.0 - a.0) } // twice the signed area
fn dep(p: &[Pt]) -> Vec<f64> { vec![turn(p[1], p[2], p[3]), -turn(p[0], p[2], p[3]), turn(p[0], p[1], p[3]), -turn(p[0], p[1], p[2])] } // by turns
fn in_tri(x: Pt, a: Pt, b: Pt, c: Pt) -> bool { let s = [turn(a, b, x), turn(b, c, x), turn(c, a, x)]; s.iter().all(|&v| v >= -1e-9) || s.iter().all(|&v| v <= 1e-9) }
fn cross(a: Pt, b: Pt, c: Pt, d: Pt) -> bool { turn(a, b, c) * turn(a, b, d) <= 0.0 && turn(c, d, a) * turn(c, d, b) <= 0.0 }
fn pt(p: Pt) -> String { format!("({}, {})", p.0, p.1) }
fn f(p: Pt) -> String { format!("({:.3}, {:.3})", p.0, p.1) }
fn list(v: &[f64]) -> String { format!("[{}]", v.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(", ")) }
fn show(p: &[Pt], g: &[usize]) -> String { // a split, written with the group holding p[0] first
    let h: Vec<usize> = (0..4).filter(|i| !g.contains(i)).collect();
    let (g, h) = if g.contains(&0) { (g.to_vec(), h) } else { (h, g.to_vec()) }; let j = |s: &[usize]| s.iter().map(|&i| pt(p[i])).collect::<Vec<_>>().join(" "); format!("{} | {}", j(&g), j(&h))
}
fn radon(p: &[Pt]) -> (Vec<f64>, String, Pt) { // road one: split by the signs of the dependence
    let lam = dep(p); let pos: Vec<usize> = (0..4).filter(|&i| lam[i] > 0.0).collect(); let s: f64 = pos.iter().map(|&i| lam[i]).sum();
    let r = (pos.iter().map(|&i| lam[i] * p[i].0).sum::<f64>() / s, pos.iter().map(|&i| lam[i] * p[i].1).sum::<f64>() / s); (lam, show(p, &pos), r)
}
fn splits(p: &[Pt]) -> Vec<String> { // road two: try all 7 splits, test the hulls
    let gs: [&[usize]; 7] = [&[1, 2, 3], &[0, 2, 3], &[0, 1, 3], &[0, 1, 2], &[0, 1], &[0, 2], &[0, 3]];
    gs.iter().filter(|g| { let h: Vec<usize> = (0..4).filter(|i| !g.contains(i)).collect();
        if g.len() == 2 { cross(p[g[0]], p[g[1]], p[h[0]], p[h[1]]) } else { in_tri(p[h[0]], p[g[0]], p[g[1]], p[g[2]]) } })
        .map(|g| show(p, g)).collect()
}
fn tf(b: bool) -> &'static str { if b { "True" } else { "False" } }
fn main() {
    let (p, q): (Vec<Pt>, Vec<Pt>) = (vec![(0.0, 0.0), (4.0, 0.0), (0.0, 4.0), (1.0, 1.0)], vec![(0.0, 0.0), (4.0, 0.0), (0.0, 4.0), (3.0, 3.0)]);
    let iv: [Pt; 4] = [(0.0, 5.0), (2.0, 7.0), (4.0, 9.0), (3.0, 6.0)];
    let ((lam, split, r), (lq, sq, rq), v) = (radon(&p), radon(&q), &p[..3]);
    let bal = (lam.iter().zip(&p).map(|(l, a)| l * a.0).sum::<f64>(), lam.iter().zip(&p).map(|(l, a)| l * a.1).sum::<f64>());
    println!("dependence on [{}]: weights {}; sum {}, balance {}", p.iter().map(|&a| pt(a)).collect::<Vec<_>>().join(", "), list(&lam), lam.iter().sum::<f64>(), pt(bal));
    println!("road one, by signs: {}; Radon point {}\nroad two, all 7 splits, hulls meeting: {}", split, f(r), splits(&p).join("; "));
    println!("(1, 1) moved to (3, 3): weights {}; by signs {}, point {}; brute force {}", list(&lq), sq, f(rq), splits(&q).join("; "));
    println!("three points only, a corner on the line through the other two: {} of 3", (0..3).filter(|&i| turn(v[(i + 1) % 3], v[(i + 2) % 3], v[i]) == 0.0).count());
    let pairs = (0..4).flat_map(|i| (i + 1..4).map(move |j| (i, j))).filter(|&(i, j)| iv[i].0.max(iv[j].0) <= iv[i].1.min(iv[j].1)).count();
    let (lo, hi) = (iv.iter().map(|a| a.0).fold(f64::MIN, f64::max), iv.iter().map(|a| a.1).fold(f64::MAX, f64::min));
    let scan: Vec<f64> = (0..37).map(|k| k as f64 / 4.0).filter(|&t| iv.iter().all(|a| a.0 <= t && t <= a.1)).collect();
    println!("Helly on a line: [{}]; pairs meeting {} of 6; common part [{}, {}]; quarter-hour scan {:?} to {:?}",
        iv.iter().map(|&a| pt(a)).collect::<Vec<_>>().join(", "), pairs, lo, hi, scan[0], scan[scan.len() - 1]);
    println!("[0, 5] cut to [0, 3]: largest left end {}, smallest right end {}: nothing common", lo, hi.min(3.0));
    let h: [(Pt, Pt); 4] = [((0.0, 0.0), (4.0, 0.0)), ((4.0, 0.0), (4.0, 4.0)), ((4.0, 4.0), (0.0, 4.0)), ((0.0, 4.0), (0.0, 0.0))]; // half-planes: left of each side of a square
    let pk: Vec<Pt> = (0..4).map(|j| (0..81).map(|k| ((k / 9 - 2) as f64, (k % 9 - 2) as f64)).find(|&g| turn(h[j].0, h[j].1, g) < 0.0 && (0..4).filter(|&i| i != j).all(|i| turn(h[i].0, h[i].1, g) > 0.0)).unwrap()).collect();
    let rh = radon(&pk).2; println!("Helly in the plane: 4 half-planes, inner sides of a 4 by 4 square; a grid point in each three, outside the fourth: [{}]; Radon point {} in all four: {}",
        pk.iter().map(|&a| pt(a)).collect::<Vec<_>>().join(", "), f(rh), tf(h.iter().all(|s| turn(s.0, s.1, rh) >= 0.0)));
    let side = |i: usize| (v[i], v[(i + 2) % 3]);
    let on: Vec<f64> = v.iter().map(|&c| (0..3).filter(|&i| { let (a, b) = side(i); turn(a, b, c) == 0.0 && a.0.min(b.0) <= c.0 && c.0 <= a.0.max(b.0) }).count() as f64).collect();
    let meet = (0..3).flat_map(|i| (0..i).map(move |j| (i, j))).filter(|&(i, j)| cross(side(i).0, side(i).1, side(j).0, side(j).1)).count();
    println!("the triangle's three sides: pairs meeting {} of 3; sides through each corner {}", meet, list(&on));
    let (nm, s, mut w): (Vec<char>, [Pt; 6], Vec<f64>) = ("ABCDEF".chars().collect(), [(2.0, 1.0), (10.0, 1.0), (11.0, 6.0), (7.0, 4.0), (5.0, 8.0), (2.0, 6.0)], vec![1.0 / 6.0; 6]);
    let x = (s.iter().zip(&w).map(|(a, wi)| wi * a.0).sum::<f64>(), s.iter().zip(&w).map(|(a, wi)| wi * a.1).sum::<f64>());
    println!("Caratheodory: x = average of the 6 survey corners = {}; in the notch C D E: {}", f(x), tf(in_tri(x, s[2], s[3], s[4])));
    let (mut drops, mut bad): (Vec<String>, Option<f64>) = (Vec::new(), None);
    let live = loop {
        let live: Vec<usize> = (0..6).filter(|&i| w[i] > 1e-12).collect();
        if live.len() <= 3 { break live }
        let qi = &live[..4]; let lam = dep(&qi.iter().map(|&i| s[i]).collect::<Vec<_>>());
        let ratios: Vec<(f64, usize)> = qi.iter().zip(&lam).filter(|(_, &l)| l > 0.0).map(|(&i, &l)| (w[i] / l, i)).collect();
        let (t, j) = ratios.iter().copied().fold((f64::MAX, 0), |m, z| if z < m { z } else { m }); let tmax = ratios.iter().map(|z| z.0).fold(f64::MIN, f64::max);
        if bad.is_none() { bad = Some(qi.iter().zip(&lam).map(|(&i, &l)| w[i] - tmax * l).fold(f64::MAX, f64::min)) }
        for (&i, &l) in qi.iter().zip(&lam) { w[i] -= t * l } w[j] = 0.0;
        drops.push(format!("drop {}: weights {} on {}, step {:.4}; now {}", nm[j], list(&lam), qi.iter().map(|&i| nm[i]).collect::<String>(), t, (0..6).map(|i| format!("{} {:.4}", nm[i], w[i])).collect::<Vec<_>>().join(" ")));
    };
    let (a, b, c) = (live[0], live[1], live[2]); let bary = [turn(x, s[b], s[c]), turn(s[a], x, s[c]), turn(s[a], s[b], x)]; let tot: f64 = bary.iter().sum();
    let mix = (w[a] * s[a].0 + w[b] * s[b].0 + w[c] * s[c].0, w[a] * s[a].1 + w[b] * s[b].1 + w[c] * s[c].1);
    let mut holds: Vec<String> = Vec::new(); for i in 0..6 { for j in i + 1..6 { for k in j + 1..6 { if in_tri(x, s[i], s[j], s[k]) { holds.push([nm[i], nm[j], nm[k]].iter().collect()) } } } }
    println!("{}\nleaves {}{}{}, weights {:.4}, {:.4}, {:.4}; mix {}", drops.join("\n"), nm[a], nm[b], nm[c], w[a], w[b], w[c], f(mix));
    println!("road two, weights as turn ratios: {:.4}, {:.4}, {:.4}\nbrute force, corner triangles holding x: {} of 20: {}", bary[0] / tot, bary[1] / tot, bary[2] / tot, holds.len(), holds.join(" "));
    println!("mistake, trimming by the largest ratio: smallest weight {:.4}", bad.unwrap());
    println!("figure, left 40 per unit from (40, 200): {}; right 22 per unit from (250, 215): {} x ({:.1}, {:.1})",
        p.iter().map(|a| pt((40.0 + 40.0 * a.0, 200.0 - 40.0 * a.1))).collect::<Vec<_>>().join(" "),
        s.iter().zip(&nm).map(|(a, n)| format!("{} {}", n, pt((250.0 + 22.0 * a.0, 215.0 - 22.0 * a.1)))).collect::<Vec<_>>().join(" "), 250.0 + 22.0 * x.0, 215.0 - 22.0 * x.1);
    assert!(splits(&p) == vec![split] && splits(&q) == vec![sq]);          // signs agree with brute force
    assert!(turn(q[0], q[3], rq) == 0.0 && turn(q[1], q[2], rq) == 0.0);    // (2, 2) is on both lines
    assert!(pairs == 6 && scan[0] == lo && scan[scan.len() - 1] == hi);     // formula agrees with the scan
    assert!(h.iter().all(|s| turn(s.0, s.1, rh) >= 0.0));                // Helly by Radon: in all four
    assert!(holds.contains(&[nm[a], nm[b], nm[c]].iter().collect::<String>()) && (0..3).all(|k| (bary[k] / tot - w[live[k]]).abs() < 1e-9));
    assert!((mix.0 - x.0).abs() < 1e-9 && (mix.1 - x.1).abs() < 1e-9 && bad.unwrap() < 0.0);
    println!("ALL CHECKS PASS");
}
