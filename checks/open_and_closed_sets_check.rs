// Open and closed sets -- the same check as the Python, in Rust.  No crates.
// A city grid measured in blocks, Central Station at (0, 0).  Zone 1 is every
// spot whose walking distance from Central is under 5 blocks.  Arithmetic is
// exact: every coordinate is a whole number of 1/32000ths of a block.
const U: i64 = 32000; // units per block
const R: i64 = 5 * U;
const C: (i64, i64) = (0, 0);
const LIB: (i64, i64) = (3 * U, 2 * U);
const PLACES: [(&str, (i64, i64)); 4] =
    [("Central", (0, 0)), ("Cafe", (2 * U, U)), ("Library", (3 * U, 2 * U)), ("Stadium", (4 * U, 3 * U))];

fn walk(p: (i64, i64), q: (i64, i64)) -> i64 { (p.0 - q.0).abs() + (p.1 - q.1).abs() } // d_1

fn line_sq(p: (i64, i64), q: (i64, i64)) -> i64 { // d_2 squared, in whole blocks squared
    let (a, b) = ((p.0 - q.0) / U, (p.1 - q.1) / U);
    a * a + b * b
}

fn grid_ball(x: (i64, i64), r: i64, step: i64) -> Vec<(i64, i64)> { // grid points within r of x
    let n = r / step + 1;
    let mut out = Vec::new();
    for i in -n..=n {
        for j in -n..=n {
            let p = (x.0 + i * step, x.1 + j * step);
            if walk(x, p) < r { out.push(p) }
        }
    }
    out
}

fn fmt(v: i64) -> String {
    if v % U == 0 { return format!("{}", v / U) }
    let s = format!("{:.6}", v as f64 / U as f64);
    s.trim_end_matches('0').trim_end_matches('.').to_string()
}

fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }

fn rule(i: usize, p: (i64, i64)) -> bool {
    match i { 0 => walk(C, p) < R, 1 => walk(C, p) <= R, 2 => walk(C, p) < R || p == LIB, 3 => true, _ => false }
}

fn has_room(i: usize, p: (i64, i64), side: bool) -> bool { // road one: a sampled ball stays on p's side
    for r in [U, U / 10, U / 100, U / 1000] {
        let h = r / 2;
        let pts = [p, (p.0 + h, p.1), (p.0 - h, p.1), (p.0, p.1 + h), (p.0, p.1 - h)];
        if pts.iter().all(|&q| rule(i, q) == side) { return true }
    }
    false
}

fn verdict(op: bool, cl: bool) -> &'static str {
    match (op, cl) { (true, false) => "open", (false, true) => "closed", (true, true) => "both", _ => "neither" }
}

fn room_dt(q: (i64, i64)) -> i64 { q.0.min(6 * U - q.0).min(q.1).min(4 * U - q.1) }

fn centres(k: u32) -> Vec<(i64, i64)> { // stage k: grid points 1/2^k apart, strictly inside
    let (n, s) = (1i64 << k, U >> k);
    let mut out = Vec::new();
    for i in 1..6 * n { for j in 1..4 * n { out.push((i * s, j * s)) } }
    out
}

fn first_stage(p: (i64, i64)) -> u32 {
    for k in 0..9 {
        let s = U >> k;
        let base = (p.0.div_euclid(s) * s, p.1.div_euclid(s) * s);
        for i in -3..4 {
            for j in -3..4 {
                let q = (base.0 + i * s, base.1 + j * s);
                if room_dt(q) > 0 && walk(p, q) < room_dt(q) { return k }
            }
        }
    }
    99
}

fn main() {
    println!("place: walking blocks from Central, straight-line blocks");
    for (name, p) in PLACES {
        println!("  {} ({}, {}): walk {}, straight {:.3}", name, p.0 / U, p.1 / U, fmt(walk(C, p)),
                 (line_sq(C, p) as f64).sqrt());
    }
    for (name, x, inside) in [("Cafe", (2 * U, U), true), ("Stadium", (4 * U, 3 * U), false)] {
        let room = if inside { R - walk(C, x) } else { walk(C, x) - R };
        let ball = grid_ball(x, room, U / 4);
        let far: Vec<i64> = ball.iter().map(|&p| walk(C, p)).collect();
        let ok = far.iter().all(|&d| if inside { d < R } else { d > R });
        let wider = grid_ball(x, room + U / 4, U / 4);
        let bad = wider.iter().filter(|&&p| if inside { walk(C, p) >= R } else { walk(C, p) <= R }).count();
        println!("{}: room {} by formula; {} grid points within {} all on the same side: {} (walking from Central {} to {}); radius {} crosses at {} points",
                 name, fmt(room), ball.len(), fmt(room), yn(ok), fmt(*far.iter().min().unwrap()),
                 fmt(*far.iter().max().unwrap()), fmt(room + U / 4), bad);
        assert!(ok && bad > 0 && room == 2 * U);
    }
    println!("Library on the rim: every ball holds a point inside and a point outside");
    for r in [U, U / 10, U / 100, U / 1000] {
        let (a, b) = ((LIB.0 - r / 2, LIB.1), (LIB.0 + r / 2, LIB.1));
        println!("  r = {}: ({}, 2) walks {}, ({}, 2) walks {}", fmt(r), fmt(a.0), fmt(walk(C, a)), fmt(b.0), fmt(walk(C, b)));
        assert!(walk(LIB, a) < r && walk(LIB, b) < r && walk(C, a) < R && R < walk(C, b));
    }
    let names = ["under 5 blocks", "at most 5 blocks", "under 5, plus the Library", "the whole city", "no zone at all"];
    let mut probes: Vec<(i64, i64)> = PLACES.iter().map(|&(_, p)| p).collect();
    probes.extend([(5 * U, 0), (0, -5 * U), (-5 * U / 2, 5 * U / 2), (U, -U), (-6 * U, 0)]);
    let expect = [(true, false), (false, true), (false, false), (true, true), (true, true)];
    println!("five fare rules, {} probe points, two roads", probes.len());
    for i in 0..5 {
        let op1 = probes.iter().filter(|&&p| rule(i, p)).all(|&p| has_room(i, p, true));
        let cl1 = probes.iter().filter(|&&p| !rule(i, p)).all(|&p| has_room(i, p, false));
        let rim: Vec<(i64, i64)> = if i < 3 { probes.iter().copied().filter(|&p| walk(C, p) == R).collect() } else { vec![] };
        let (op2, cl2) = (!rim.iter().any(|&p| rule(i, p)), rim.iter().all(|&p| rule(i, p))); // road two
        println!("  {}: sampled balls {}, rim rule {}", names[i], verdict(op1, cl1), verdict(op2, cl2));
        assert!((op1, cl1) == (op2, cl2) && (op1, cl1) == expect[i]);
    }
    let wl = walk(C, LIB);
    let ins = (1..=1000i64).all(|n| n * wl < (5 * n + 1) * U);
    let p2999 = 2999 * U / 1000 + 2 * U;
    let first = (1..=2000i64).find(|&n| n * p2999 <= (5 * n - 1) * U).unwrap();
    println!("Library in every zone 'under 5 + 1/n', n = 1 to 1000: {}; in 'under 5': {}", yn(ins), yn(wl < R));
    println!("(2.999, 2) first inside 'at most 5 - 1/n' at n = {}; the Library never", first);
    assert!(ins && first == 1000);

    let counts: Vec<usize> = (0..4).map(|k| centres(k).len()).collect();
    let spill = (0..4).flat_map(centres).filter(|&q| {
        let r = room_dt(q);
        !(0 <= q.0 - r && q.0 + r <= 6 * U && 0 <= q.1 - r && q.1 + r <= 4 * U)
    }).count();
    println!("Downtown: balls at stages 0 to 3: {:?}; balls poking out: {}", counts, spill);
    for p in [(3 * U, 2 * U), (U / 100, 2 * U), (U / 2, U / 2), (U / 100, U / 100)] {
        println!("  ({}, {}): room {}, first covered at stage {}", fmt(p.0), fmt(p.1), fmt(room_dt(p)), first_stage(p));
    }
    assert!(spill == 0 && first_stage((U / 100, U / 100)) == 6);

    let stops: Vec<(i64, i64)> = PLACES.iter().map(|&(_, p)| p).collect();
    let mut gap = i64::MAX;
    for a in 0..4 { for b in a + 1..4 { gap = gap.min(walk(stops[a], stops[b])) } }
    let ball = |p: (i64, i64)| -> u32 { (0..4).filter(|&j| 2 * walk(p, stops[j]) < gap).map(|j| 1u32 << j).sum() };
    let (mut both, mut unions) = (true, true);
    for a in 0u32..16 {
        let mut built = 0u32;
        for j in 0..4 {
            let b = ball(stops[j]);
            if a >> j & 1 == 1 { both &= b & !a == 0; built |= b } else { both &= b & a == 0 }
        }
        unions &= built == a;
    }
    println!("four stops only: closest pair {} blocks apart; all {} subsets open and closed: {}; each a union of one-stop balls: {}",
             fmt(gap), 16, yn(both), yn(unions));
    let pick = |t: &dyn Fn(i64) -> bool| -> Vec<&str> { PLACES.iter().filter(|&&(_, p)| t(walk(C, p))).map(|&(n, _)| n).collect() };
    let (o5, o6, c5) = (pick(&|d| d < 5 * U), pick(&|d| d < 6 * U), pick(&|d| d <= 5 * U));
    println!("  among stops: under 5 blocks {}; under 6 blocks {}; at most 5 blocks {}", o5.join(", "), o6.join(", "), c5.join(", "));
    assert!(both && unions && gap == 2 * U && o6 == c5 && o6 != o5);
    let fine: Vec<i64> = grid_ball((2 * U, U), 2 * U, U / 8).iter().map(|&p| walk(C, p)).collect();
    let cross = grid_ball((2 * U, U), 9 * U / 4, U / 8).iter().filter(|&&p| walk(C, p) >= R).count();
    println!("try: step 1/8: {} grid points within 2 of the Cafe, walking {} to {}; radius 2.25 crosses at {} points",
             fine.len(), fmt(*fine.iter().min().unwrap()), fmt(*fine.iter().max().unwrap()), cross);
    let room22 = R - walk(C, (2 * U, 2 * U));
    println!("try: Cafe at (2, 2): room {}, {} grid points; (0.1, 0.1) first covered at stage {}",
             fmt(room22), grid_ball((2 * U, 2 * U), room22, U / 4).len(), first_stage((U / 10, U / 10)));

    let far_pt = (2999 * U / 1000 + 1999 * U / 1000, 2 * U);
    println!("mistake, one room for the whole zone: the ball of radius 2 round (2.999, 2) holds ({}, 2), which walks {} blocks",
             fmt(far_pt.0), fmt(walk(C, far_pt)));
    println!("mistake, squared distance on a line: zone (-2, 2), point 1, room 4 - 1 = 3, ball reaches {:.3}", 1.0 + 3f64.sqrt());
    let mut px: Vec<String> = PLACES.iter().map(|&(n, p)| format!("{} ({}, {})", n, 180 + 30 * p.0 / U, 200 - 30 * p.1 / U)).collect();
    px.extend(["east tip (330, 200)".to_string(), format!("north tip ({}, {})", 180, 200 - 30 * 5)]);
    println!("figure, 30 px per block: {}", px.join(", "));
    println!("ALL CHECKS PASS");
}
