// What compactness and connectedness buy -- the same check as the Python, in
// Rust.  No crates.  Part 1 is exhaustive: every topology on three points and
// every map between two of them, so its counts are proofs for three-point spaces.
// Part 2 is the drone: a closed loop of radius 500 m round the launch point, with
// altitude 120 + 15E + 20N metres at the loop point E radii east, N radii north.
// Loop points are exact fractions; the code illustrates the theorems there.
// A set of points is a 3-bit mask; a topology is an 8-bit mask over those sets.
use std::cmp::Ordering;

#[derive(Clone, Copy, PartialEq, Eq, Debug)]
struct Q { n: i128, d: i128 }                       // an exact fraction, lowest terms
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i128, d: i128) -> Q { let g = gcd(n, d) * d.signum(); Q { n: n / g, d: d / g } }
fn add(a: Q, b: Q) -> Q { q(a.n * b.d + b.n * a.d, a.d * b.d) }
fn sub(a: Q, b: Q) -> Q { q(a.n * b.d - b.n * a.d, a.d * b.d) }
fn mul(a: Q, b: Q) -> Q { q(a.n * b.n, a.d * b.d) }
fn div(a: Q, b: Q) -> Q { q(a.n * b.d, a.d * b.n) }
fn cmpq(a: Q, b: Q) -> Ordering { (a.n * b.d).cmp(&(b.n * a.d)) }
fn wq(a: i128) -> Q { q(a, 1) }
fn show(a: Q) -> String { if a.d == 1 { format!("{}", a.n) } else { format!("{}/{}", a.n, a.d) } }
fn dec(x: Q, k: u32) -> String {                   // a fraction to k decimal places, cut not rounded
    let p = 10i128.pow(k);
    let w = x.n.abs() * p / x.d;
    format!("{}{}.{:0w$}", if x.n < 0 { "-" } else { "" }, w / p, w % p, w = k as usize)
}
fn yn(claim: bool) -> &'static str { if claim { "yes" } else { "no" } }

const EVERY: u8 = 7;
fn has(t: u16, s: u8) -> bool { t >> s & 1 == 1 }
fn opens(t: u16) -> Vec<u8> { (0..8u8).filter(|&s| has(t, s)).collect() }
fn is_topology(t: u16) -> bool {
    let o = opens(t);
    has(t, 0) && has(t, EVERY) && o.iter().all(|&u| o.iter().all(|&v| has(t, u | v) && has(t, u & v)))
}
fn pre(f: &[u8; 3], v: u8) -> u8 { (0..3).filter(|&x| v >> f[x] & 1 == 1).fold(0, |a, x| a | 1 << x) }
fn continuous(f: &[u8; 3], t1: u16, t2: u16) -> bool { opens(t2).iter().all(|&v| has(t1, pre(f, v))) }
fn connected(s: u8, t: u16) -> bool {               // no split of s into two open pieces
    let pieces: Vec<u8> = opens(t).iter().map(|&u| u & s).collect();
    !pieces.iter().any(|&a| a != 0 && s & !a != 0 && pieces.contains(&(s & !a)))
}
fn hausdorff(t: u16) -> bool {                       // distinct points sit in disjoint open sets
    let o = opens(t);
    (0..3).all(|x| (0..3).all(|y| x == y || o.iter().any(|&u| o.iter().any(|&v|
        u >> x & 1 == 1 && v >> y & 1 == 1 && u & v == 0))))
}
fn alt(e: Q, n: Q) -> Q { add(wq(120), add(mul(wq(15), e), mul(wq(20), n))) }
fn point(t: Q) -> (Q, Q) {                           // exact loop point for slope t
    let one = wq(1);
    let s = add(one, mul(t, t));
    (div(sub(one, mul(t, t)), s), div(mul(wq(2), t), s))
}

fn main() {
    let tops: Vec<u16> = (0..256u16).filter(|&t| is_topology(t)).collect();
    let maps: Vec<[u8; 3]> = (0..27u8).map(|m| [m / 9, m / 3 % 3, m % 3]).collect();
    let (mut cont, mut conn, mut jumpy, mut images_ok) = (0, 0, 0, true);
    let mut counts = [[0u32; 2]; 2];                 // [target Hausdorff?] -> [bijections, homeomorphisms]
    for &t1 in &tops {
        for &t2 in &tops {
            for f in &maps {
                let img = f.iter().fold(0u8, |a, &y| a | 1 << y);
                if continuous(f, t1, t2) {
                    cont += 1;
                    if connected(EVERY, t1) { conn += 1; images_ok = images_ok && connected(img, t2); }
                    if img == EVERY {
                        let mut inv = [0u8; 3];
                        for x in 0..3 { inv[f[x] as usize] = x as u8; }
                        let hd = hausdorff(t2) as usize;
                        counts[hd][0] += 1;
                        counts[hd][1] += continuous(&inv, t2, t1) as u32;
                    }
                } else if connected(EVERY, t1) && !connected(img, t2) { jumpy += 1; }
            }
        }
    }
    let (discrete, indiscrete, id) = (255u16, 1u16 | 1 << 7, [0u8, 1, 2]);
    println!("Part 1: every topology on three points, every map between two of them");
    println!("topologies on 3 points: {}; Hausdorff ones: {}; connected ones: {}", tops.len(),
             tops.iter().filter(|&&t| hausdorff(t)).count(), tops.iter().filter(|&&t| connected(EVERY, t)).count());
    println!("continuous maps: {}; from a connected space: {}; image connected every time: {}", cont, conn, yn(images_ok));
    println!("discontinuous maps from a connected space with a disconnected image: {}", jumpy);
    let (hb, nb) = (counts[1], counts[0]);
    println!("continuous bijections onto a Hausdorff space: {}; homeomorphisms among them: {}", hb[0], hb[1]);
    println!("continuous bijections onto a non-Hausdorff space: {}; homeomorphisms among them: {}", nb[0], nb[1]);
    println!("identity, discrete onto indiscrete: continuous {}, inverse continuous {}",
             yn(continuous(&id, discrete, indiscrete)), yn(continuous(&id, indiscrete, discrete)));

    let mut lp: Vec<(Q, Q)> = (-64..=64).map(|k| point(q(k, 8))).collect();
    lp.push((wq(-1), wq(0)));
    let alts: Vec<Q> = lp.iter().map(|&(e, n)| alt(e, n)).collect();
    let mut ih = 0; let mut il = 0;
    for i in 0..alts.len() {
        if cmpq(alts[i], alts[ih]) == Ordering::Greater { ih = i; }
        if cmpq(alts[i], alts[il]) == Ordering::Less { il = i; }
    }
    let (hi, lo, top, bottom) = (alts[ih], alts[il], lp[ih], lp[il]);
    let ident = lp.iter().all(|&(e, n)| {
        let (a, b) = (add(mul(wq(15), e), mul(wq(20), n)), sub(mul(wq(20), e), mul(wq(15), n)));
        add(mul(a, a), mul(b, b)) == wq(625)
    });
    let half = |p: (Q, Q)| format!("({}, {})", show(mul(p.0, wq(500))), show(mul(p.1, wq(500))));
    println!("Part 2: the drone's loop, radius 500 m, altitude 120 + 15E + 20N metres");
    println!("checked on {} exact loop points: highest {} m at {} m; lowest {} m at {} m",
             lp.len(), show(hi), half(top), show(lo), half(bottom));
    println!("identity (15E + 20N)^2 + (20E - 15N)^2 = 625 at all {} points: {}", lp.len(), yn(ident));
    let compass = [("north", 0, 1), ("east", 1, 0), ("south", 0, -1), ("west", -1, 0)];
    let ca: Vec<i128> = compass.iter().map(|&(_, e, n)| 120 + 15 * e + 20 * n).collect();
    println!("compass points only: {}; best {} m", compass.iter().zip(&ca).map(|(c, a)| format!("{} {} m", c.0, a))
             .collect::<Vec<_>>().join(", "), ca.iter().max().unwrap());
    println!("chart, altitude in m at bearings 0, 30, ..., 360 degrees: {}", (0..=12).map(|i| {
        let r = ((30 * i) as f64).to_radians();
        format!("{:.1}", 120.0 + 15.0 * r.sin() + 20.0 * r.cos())
    }).collect::<Vec<_>>().join(" "));
    let (mut a, mut b) = (wq(-2), q(1, 2));
    let g = |t: Q| add(mul(wq(15), sub(wq(1), mul(t, t))), mul(wq(40), t));
    for _ in 0..40 {
        let m = div(add(a, b), wq(2));
        if g(m).n < 0 { a = m } else { b = m }
    }
    println!("bisection for 120 m, 40 halvings: slope t in [{}, {}]; algebra: t = -1/3 or t = 3", dec(a, 12), dec(b, 12));
    for t in [q(-1, 3), wq(3)] {
        let p = point(t);
        println!("  t = {}: point {} m, altitude {} m", show(t), half(p), show(alt(p.0, p.1)));
    }
    let crossings: Vec<(i128, usize)> = [110, 130, 150].iter().map(|&y| {
        let s: Vec<bool> = alts.iter().map(|&v| cmpq(v, wq(y)) == Ordering::Greater).collect();
        (y, (0..s.len()).filter(|&i| s[i] != s[(i + s.len() - 1) % s.len()]).count())
    }).collect();
    println!("crossings of one lap, sampled: {}", crossings.iter().map(|(y, c)| format!("{} m: {}", y, c)).collect::<Vec<_>>().join(", "));
    let near: Vec<String> = [2u32, 3, 4].iter().map(|&k| {
        let p = point(add(q(1, 2), q(1, 10i128.pow(k))));
        dec(alt(p.0, p.1), 9)
    }).collect();
    println!("open loop, top point removed: altitudes {}; 145 never reached", near.join(", "));
    let flown = alts.iter().any(|&v| v == wq(150) || add(v, wq(60)) == wq(150));
    println!("two separate loops, the second 60 m higher: altitudes {} to {} and {} to {}; 150 m flown: {}",
             show(lo), show(hi), show(add(lo, wq(60))), show(add(hi, wq(60))), yn(flown));
    let chord = 1000.0 * (std::f64::consts::PI / 1000.0).sin();
    let w = 2.0 * std::f64::consts::PI * 0.999;
    let dist = ((500.0 - 500.0 * w.cos()).powi(2) + (500.0 * w.sin()).powi(2)).sqrt();
    let glued = if cmpq(q(999, 1000), q(1, 1000)) == Ordering::Less { q(999, 1000) } else { q(1, 1000) };
    println!("unglued lap clock [0, 1): lap fractions 0.999 and 0 sit {:.4} m apart on the loop, but 0.999 apart on the clock; glued, {} apart",
             chord, show(glued));
    println!("closed set, image not closed: 1/(1 + x^2) at x = 10, 100, 1000: {}; 0 never reached",
             [10i128, 100, 1000].iter().map(|&x| show(q(1, 1 + x * x))).collect::<Vec<_>>().join(", "));
    assert!(tops.len() == 29 && tops.iter().filter(|&&t| hausdorff(t)).count() == 1); // Evans-Harary-Lynn count
    assert!(tops.iter().filter(|&&t| connected(EVERY, t)).count() == 29 - 10);    // 10 split ones, by hand
    assert!(images_ok && jumpy > 0 && conn > 0);                      // theorem holds, test can fail
    assert!(hb[0] == hb[1] && hb[0] > 0 && nb[1] < nb[0]);            // compact to Hausdorff only
    assert!(hb[1] + nb[1] == 6 * tops.len() as u32);   // one homeomorphism per topology and permutation
    assert!(hi == wq(145) && top == (q(3, 5), q(4, 5)) && lo == wq(95) && bottom == (q(-3, 5), q(-4, 5)) && ident);
    assert!(cmpq(a, q(-1, 3)) == Ordering::Less && cmpq(q(-1, 3), b) == Ordering::Less
            && sub(b, a) == q(5, 2 << 40));                           // bisection meets the algebra
    assert!(crossings.iter().all(|&(y, c)| c == if (y - 120).abs() < 25 { 2 } else { 0 }));
    assert!((dist - chord).abs() < 1e-9);                             // cross-check of the chord
    println!("ALL CHECKS PASS");
}
