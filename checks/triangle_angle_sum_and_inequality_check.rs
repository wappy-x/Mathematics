// Triangles: the angle sum and the two-sides-beat-the-third test, in Rust, no
// crates.  Fence panels 3, 4 and 8 m, then 3, 4 and 5 m.  Two roads: the rule on
// the card, and the panels placed on a grid and swung round.
use std::f64::consts::PI;

fn rule(p: [f64; 3]) -> bool {                   // road one: the two shorter against the longest
    let mut s = p;
    s.sort_by(|x, y| x.partial_cmp(y).unwrap());
    s[0] + s[1] > s[2]
}

fn gap(b: f64, a: f64, c: f64, t: f64) -> f64 {  // b hinged at A = (0, 0), turned t up from the
    let (x, y) = (b * t.cos(), b * t.sin());     // long panel A to B = (c, 0); a hinged at B:
    (x - c).hypot(y) - a                         // how far the tip of b sits beyond a's reach
}

fn swing(b: f64, a: f64, c: f64) -> (bool, f64, f64) { // road two: every position of the swing
    let n = 3600;
    let g: Vec<f64> = (0..=n).map(|k| gap(b, a, c, PI * k as f64 / n as f64)).collect();
    let lo = g.iter().cloned().fold(f64::INFINITY, f64::min);
    let hi = g.iter().cloned().fold(f64::NEG_INFINITY, f64::max);
    (lo < 0.0 && 0.0 < hi, lo, hi)
}

fn angle(p: (f64, f64), q: (f64, f64), r: (f64, f64)) -> f64 { // angle at p, from the dot product
    let (u, v) = ((q.0 - p.0, q.1 - p.1), (r.0 - p.0, r.1 - p.1));
    let cos = (u.0 * v.0 + u.1 * v.1) / (u.0.hypot(u.1) * v.0.hypot(v.1));
    cos.max(-1.0).min(1.0).acos() * 180.0 / PI
}

fn yn(v: bool) -> &'static str { if v { "yes" } else { "no" } }

fn main() {
    let by_rule: Vec<bool> = (1..=8).map(|c| rule([3.0, 4.0, c as f64])).collect();
    let by_swing: Vec<bool> = (1..=8).map(|c| swing(3.0, 4.0, c as f64).0).collect();
    let (s5, s8, closest7) = (swing(3.0, 4.0, 5.0), swing(3.0, 4.0, 8.0), swing(3.0, 4.0, 7.0).1);
    let closest8 = s8.1;
    let (mut lo, mut hi) = (0.0_f64, PI);        // bisect for where the 3 m tip meets the 4 m panel
    for _ in 0..100 {
        let mid = (lo + hi) / 2.0;
        if gap(3.0, 4.0, 5.0, mid) < 0.0 { lo = mid } else { hi = mid }
    }
    let (a, b, c) = ((0.0, 0.0), (5.0, 0.0), (3.0 * lo.cos(), 3.0 * lo.sin()));
    let (ang_a, ang_b, ang_c) = (angle(a, b, c), angle(b, c, a), angle(c, a, b));
    let missing = 180.0 - ang_c - ang_b;         // the rule: the third corner from the other two
    let (mut s, mut worst, mut pts): (u64, f64, Vec<f64>) = (2026, 0.0, Vec::new());
    for _ in 0..6000 {                           // second case: 1000 triangles from our own LCG
        s = (1103515245 * s + 12345) % (1 << 31);
        pts.push(10.0 * s as f64 / (1u64 << 31) as f64);
    }
    for i in (0..6000).step_by(6) {
        let (p, q, r) = ((pts[i], pts[i + 1]), (pts[i + 2], pts[i + 3]), (pts[i + 4], pts[i + 5]));
        worst = worst.max((angle(p, q, r) + angle(q, r, p) + angle(r, p, q) - 180.0).abs());
    }
    let words = |v: &Vec<bool>| v.iter().map(|&x| yn(x)).collect::<Vec<_>>().join(" ");
    let swing_a = lo * 180.0 / PI;
    println!("panels [3, 4, 8]: two shorter end to end {} m vs longest 8 m -> triangle: {}", 3 + 4, yn(rule([3.0, 4.0, 8.0])));
    println!("swing the 3 m panel through a half-turn: closest the loose ends get {:.3} m", closest8);
    println!("3 m tip to B over the swing: {:.3} to {:.3} m with the 5 m panel, {:.3} to {:.3} m with the 8 m", s5.1 + 4.0, s5.2 + 4.0, s8.1 + 4.0, s8.2 + 4.0);
    println!("third panel with 3 m and 4 m, c = 1..8, by the rule:  {}", words(&by_rule));
    println!("third panel with 3 m and 4 m, c = 1..8, by the swing: {}", words(&by_swing));
    println!("so the third panel must lie strictly between {} m and {} m", 4 - 3, 4 + 3);
    println!("panels [3, 4, 5]: swing closes at A = {:.2} deg, C at ({:.3}, {:.3})", swing_a, c.0, c.1);
    println!("grid angles by dot product: A {:.2}, B {:.2}, C {:.2}, sum {:.2}", ang_a, ang_b, ang_c, ang_a + ang_b + ang_c);
    println!("missing angle by the rule: 180 - {:.2} - {:.2} = {:.2}", ang_c, ang_b, missing);
    println!("exterior angle at B: 180 - {:.2} = {:.2} = A + C", ang_b, 180.0 - ang_b);
    println!("1000 random triangles: angle sum within 1e-9 deg of 180 every time: {}", yn(worst < 1e-9));
    println!("mistake 1, order 8, 3, 4, first two against the third: {} > 4 says {}", 8 + 3, yn(8 + 3 > 4));
    println!("mistake 2, panels [3, 4, 7]: closest the loose ends get {:.3} m, only lying flat", closest7);
    println!("mistake 3, 360 - {:.2} - {:.2} = {:.2}, more than a half-turn", ang_c, ang_b, 360.0 - ang_c - ang_b);
    println!("figure 1, 1 m = 40 units: 8 m panel x 20 to {}, 3 m panel ends x {}, 4 m panel starts x {}", 20 + 8 * 40, 20 + 3 * 40, 340 - 4 * 40);
    println!("figure 2, 1 m = 50 units: A (55, 200), B ({}, 200), C ({:.0}, {:.0})", 55 + 5 * 50, 55.0 + 50.0 * c.0, 200.0 - 50.0 * c.1);
    assert!(by_rule == by_swing);                // two roads agree on every third panel, 1 m to 8 m
    assert!((closest8 - (8.0 - (3.0 + 4.0))).abs() < 1e-12); // the swing's closest approach is the shortfall
    assert!((missing - swing_a).abs() < 1e-9 && ((c.0 - 5.0).hypot(c.1) - 4.0).abs() < 1e-9); // closed on the 4 m panel, at the rule's corner
    assert!(worst < 1e-9);                       // the sum holds on triangles nobody chose
    println!("ALL CHECKS PASS");
}
