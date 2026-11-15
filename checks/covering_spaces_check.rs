// Covering spaces -- the same check as the Python, in Rust.  No crates.
// The plan of a spiral car park is the circle; the ramp above it is the line.
// Positions are whole degrees: a plan angle is taken mod 360, a ramp position
// is not.  One circuit = 360 degrees = one floor, 3 m up; 24 bays a circuit.
const READ: [i64; 10] = [0, 100, 200, 300, 40, 140, 240, 340, 80, 180]; // every 30 s

fn step(a: i64, b: i64) -> i64 { (b - a + 179).rem_euclid(360) - 179 } // road one

fn lift(angles: &[i64], start: i64) -> Vec<i64> {   // follow the readings up the ramp
    let mut out = vec![start];
    for w in angles.windows(2) { let last = *out.last().unwrap(); out.push(last + step(w[0], w[1])) }
    out
}

fn lift_by_search(angles: &[i64]) -> Vec<i64> {     // road two: search the stack above each reading
    let mut out = vec![0];
    for &b in &angles[1..] {
        let last = *out.last().unwrap();
        let near: Vec<i64> = (-20..=20).map(|m| b + 360 * m).filter(|p| (p - last).abs() < 180).collect();
        assert!(near.len() == 1);                    // one copy in reach: the lift is unique
        out.push(near[0]);
    }
    out
}

fn turns_by_arrows(angles: &[i64]) -> f64 {         // road three: add the turning angles
    let mut tot = 0.0;
    for w in angles.windows(2) {
        let (a, b) = ((w[0] as f64).to_radians(), (w[1] as f64).to_radians());
        let (x1, y1, x2, y2) = (a.cos(), a.sin(), b.cos(), b.sin());
        tot += (x1 * y2 - y1 * x2).atan2(x1 * x2 + y1 * y2).to_degrees();
    }
    tot / 360.0
}

fn floor_of(pos: i64) -> i64 { pos.div_euclid(360) }

fn lp(k: i64) -> Vec<i64> { (0..=12).map(|j| (30 * k * j).rem_euclid(360)).collect() } // z -> z^k

fn lift_mod(angles: &[i64], n: i64) -> Vec<i64> { lift(angles, 0).iter().map(|p| p.rem_euclid(360 * n)).collect() }

fn gcd(a: i64, b: i64) -> i64 { if b == 0 { a.abs() } else { gcd(b, a % b) } }

fn frac(p: i64, q: i64) -> String {
    let g = gcd(p, q);
    if q / g == 1 { format!("{}", p / g) } else { format!("{}/{}", p / g, q / g) }
}

fn yn(c: bool) -> &'static str { if c { "yes" } else { "no" } }

fn main() {
    let up = lift(&READ, 0);
    let end = *up.last().unwrap();
    println!("readings (deg): {:?}", READ);
    println!("lift, step by step (deg): {:?}", up);
    let cands: Vec<i64> = (0..4).map(|m| 80 + 360 * m).collect();   // the stack over 80 deg, floors 0 to 3
    let near: Vec<i64> = cands.iter().copied().filter(|c| (c - up[7]).abs() < 180).collect();
    println!("step 340 -> 80 from ramp {}: candidates {:?}; within 180 of {}: {:?}", up[7], cands, up[7], near);
    println!("end of lift: {} deg = {} turns; floor {}, bay {}, height {} m",
             end, frac(end, 360), floor_of(end), end.rem_euclid(360) / 15, end as f64 / 360.0 * 3.0);
    println!("same lift by searching the stack over each reading: {}", yn(lift_by_search(&READ) == up));
    println!("turns by adding plan-arrow angles: {:.6}", turns_by_arrows(&READ));
    let shifted: Vec<i64> = lift(&READ, 360).iter().zip(&up).map(|(a, b)| a - b).collect();
    println!("lift started on floor 1 = first lift + 360 everywhere: {}", yn(shifted.iter().all(|&d| d == 360)));
    let mut back = READ.to_vec();
    back.extend(READ[..9].iter().rev());
    let bend = *lift(&back, 0).last().unwrap();
    println!("drive up and back down: lift ends at {} deg, floor {}", bend, floor_of(bend));
    let mut lead: Vec<i64> = (0..13).map(|j| (90 * j) % 360).collect();
    lead.extend((0..12).rev().map(|j| (90 * j) % 360));
    let lend = *lift(&lead, 0).last().unwrap();
    println!("lead wound 3 times, then unwound: lift ends at {} deg", lend);
    let mut two = lp(2);
    two.extend(&lp(-1)[1..]);
    let tend = *lift(&two, 0).last().unwrap();
    println!("loop of 2 turns then loop of -1: lift ends at {} turn", tend / 360);
    let iend = *lift(&lp(1), 0).last().unwrap();
    println!("identity map, a ramp point above each plan spot: lift of one circuit ends at {} deg, not 0, so no such rule", iend);
    println!("lifting criterion, maps z^k through the n-fold cover: lift closes?");
    let (mut agree, mut cases) = (0, 0);
    for n in 1..5i64 {
        let mut row: Vec<&str> = Vec::new();
        for k in -3..4i64 {
            let closes = *lift_mod(&lp(k), n).last().unwrap() == 0;
            let sub: Vec<i64> = if k == 0 { vec![0] } else { (-10..=10).map(|j| k * j).collect() };
            let in_sub = sub.iter().all(|x| x.rem_euclid(n) == 0 && x.abs() <= 120 * n);
            if closes == in_sub { agree += 1 }
            cases += 1;
            row.push(if closes { "Y" } else { "." });
        }
        println!("  n = {}, k = -3..3: {}", n, row.join(" "));
    }
    println!("criterion k Z inside n Z agrees with the lift: {} of {} cases", agree, cases);
    let sheets: Vec<i64> = (0..6).map(|k| *lift_mod(&lp(k), 3).last().unwrap() / 360).collect();
    println!("loop of k turns lifted into the 3-fold cover ends on sheet: {:?}", sheets);
    let mut fibre: Vec<i64> = (-9..10i64).map(|j| (360 * j).rem_euclid(1080)).collect();
    fibre.sort();
    fibre.dedup();
    let mut cosets: Vec<Vec<i64>> = Vec::new();
    for g in -9..10i64 {
        let c: Vec<i64> = (-9..10).filter(|x: &i64| (x - g).rem_euclid(3) == 0).collect();
        if !cosets.contains(&c) { cosets.push(c) }
    }
    println!("3-fold cover: fibre over 0 = {:?}; cosets of 3Z in Z: {}", fibre, cosets.len());
    let decks: Vec<i64> = (0..721).filter(|m| (-720..721).all(|x: i64| (x + m).rem_euclid(360) == x.rem_euclid(360))).collect();
    println!("shifts m in 0..720 that keep every plan spot: {:?}", decks);
    let coarse: Vec<i64> = READ.iter().step_by(2).copied().collect();
    let bad = *lift(&coarse, 0).last().unwrap();
    println!("mistake, readings every 60 s {:?}: lift ends at {} deg = {:.2} turns, floor {}",
             coarse, bad, bad as f64 / 360.0, floor_of(bad));
    println!("mistake, last reading alone: {} deg, floor 0, bay {}", READ[9], READ[9] / 15);
    println!("mistake, [0, 1) as the cover: 340 deg -> {} turn, 80 deg -> {} turn, a jump of {} turn",
             frac(340, 360), frac(80, 360), frac(80 - 340, 360));
    let odd = *lift_mod(&lp(3), 2).last().unwrap();
    println!("mistake, z^3 through the double cover: lift ends at {} deg, sheet {}, not closed", odd, odd / 360);
    let stack: Vec<String> = (0..3).map(|m| format!("(50, {:.1})", 290.0 - 75.0 * (m as f64 + 0.5))).collect();
    println!("figure, start (370, 290); end (50, {:.1}); stack over 180 deg: {}; plan spot (50, 350)",
             290.0 - 75.0 * end as f64 / 360.0, stack.join(", "));
    assert!(lift_by_search(&READ) == up && end == 900);                // two roads, one lift
    assert!((turns_by_arrows(&READ) - end as f64 / 360.0).abs() < 1e-9); // third road
    assert!(bend == 0 && lend == 0 && tend == 360);
    assert!(agree == cases && iend == 360);                             // criterion vs lift
    assert!(sheets == (0..6).map(|k| k % 3).collect::<Vec<i64>>() && fibre.len() == cosets.len()); // sheets match cosets
    assert!(decks == vec![0, 360, 720]);                               // shifts by whole floors only
    assert!((floor_of(end), floor_of(bad), bad, odd) == (2, -2, -640, 360)); // hand values
    assert!(near == vec![up[8]]);                                      // the one copy in reach
    println!("ALL CHECKS PASS");
}
