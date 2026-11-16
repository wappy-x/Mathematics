// Calderon-Zygmund decomposition of a 32-day rainfall record (illustrative numbers).
// Road 1: start from the whole record and halve each box, stopping at the first
//         box whose average rain is above the level ALPHA.
// Road 2: list every dyadic box with average above ALPHA, keep the largest ones.
// Road 3: the dyadic maximal function, day by day; its level set must be the same days.
// Rain is whole mm per day, so every average is an exact fraction with a power-of-two
// denominator; dec() prints it exactly. Logs appear only in the far-field table.
use std::collections::BTreeMap;
use std::f64::consts::PI;

const RAIN: [i64; 32] = [0, 2, 0, 14, 4, 0, 1, 0, 3, 0, 0, 25, 30, 2, 0, 0,
                         0, 0, 6, 8, 9, 7, 0, 0, 0, 0, 0, 0, 0, 48, 0, 0]; // mm on each day
const ALPHA: i64 = 10; // level, mm per day

fn dec(n: i64, d: i64) -> String { // exact decimal of n/d, d a power of two
    let s = if n < 0 { "-" } else { "" };
    let (q, mut r) = (n.abs() / d, n.abs() % d);
    let mut out = format!("{}{}{}", s, q, if r != 0 { "." } else { "" });
    while r != 0 {
        r *= 10;
        out += &(r / d).to_string();
        r %= d;
    }
    out
}

fn show(bx: &[(usize, usize)], shift: usize) -> String {
    bx.iter().map(|&(a, n)| format!("[{},{})", a - shift, a - shift + n)).collect::<Vec<_>>().join(" ")
}

fn tot(rain: &[i64], a: usize, n: usize) -> i64 { rain[a..a + n].iter().sum() }

// road 1, the stopping time
fn halve(rain: &[i64], alpha: i64, a: usize, n: usize, out: &mut Vec<(usize, usize)>, seen: &mut BTreeMap<usize, usize>) {
    *seen.entry(n).or_insert(0) += 1;
    if tot(rain, a, n) > alpha * n as i64 {
        out.push((a, n));
    } else if n > 1 { // a one-day box is constant inside: halving it never stops
        halve(rain, alpha, a, n / 2, out, seen);
        halve(rain, alpha, a + n / 2, n / 2, out, seen);
    }
}

fn run(rain: &[i64], alpha: i64) -> Vec<(usize, usize)> {
    let mut out = Vec::new();
    halve(rain, alpha, 0, rain.len(), &mut out, &mut BTreeMap::new());
    out
}

fn largest(rain: &[i64], alpha: i64) -> Vec<(usize, usize)> { // road 2, bottom up
    let (mut hot, mut n) = (Vec::new(), 1);
    while n <= rain.len() {
        for a in (0..rain.len()).step_by(n) {
            if tot(rain, a, n) > alpha * n as i64 { hot.push((a, n)); }
        }
        n *= 2;
    }
    let inside = |b: (usize, usize), c: (usize, usize)| c != b && c.0 <= b.0 && b.0 + b.1 <= c.0 + c.1;
    let mut keep: Vec<_> = hot.iter().cloned().filter(|&b| !hot.iter().any(|&c| inside(b, c))).collect();
    keep.sort();
    keep
}

fn pull(vals: &[f64], a: i64, x: i64) -> f64 { // Hilbert transform at x of a day-by-day step function
    let mut s = 0.0;
    for (i, v) in vals.iter().enumerate() {
        let d = a + i as i64;
        s += v * (((x - d).abs() as f64).ln() - ((x - d - 1).abs() as f64).ln());
    }
    s / PI
}

fn main() {
    let (l, f1) = (RAIN.len(), RAIN.iter().sum::<i64>());
    println!("record: {} days, total {} mm, level ALPHA = {} mm/day, 2 ALPHA = {}", l, f1, ALPHA, 2 * ALPHA);
    println!("start box [0,{}): average {} mm/day, not above {}", l, dec(f1, l as i64), ALPHA);
    let (mut boxes, mut seen) = (Vec::new(), BTreeMap::new());
    halve(&RAIN, ALPHA, 0, l, &mut boxes, &mut seen);
    for (n, c) in seen.iter().rev() {
        println!("  boxes of length {:>2} looked at: {:>2}, stopped: {}", n, c, boxes.iter().filter(|b| b.1 == *n).count());
    }
    for &(a, n) in &boxes {
        let t = tot(&RAIN, a, n);
        let path: Vec<String> = [32usize, 16, 8, 4, 2].iter().filter(|&&m| m > n)
            .map(|&m| { let s = a - a % m; format!("[{},{}) {}/{} = {}", s, s + m, tot(&RAIN, s, m), m, dec(tot(&RAIN, s, m), m as i64)) }).collect();
        println!("stopped [{},{}): length {}, {} mm, average {}; above it: {}", a, a + n, n, t, dec(t, n as i64), path.join(", "));
    }
    assert!(boxes == vec![(3, 1), (10, 2), (12, 2), (28, 4)], "the hand-worked halving");
    assert!(boxes == largest(&RAIN, ALPHA), "road 2: largest hot boxes");
    for &(a, n) in &boxes {
        let t = tot(&RAIN, a, n);
        assert!(ALPHA * (n as i64) < t && t <= 2 * ALPHA * n as i64, "average between ALPHA and 2 ALPHA");
    }
    let bad_days: Vec<usize> = boxes.iter().flat_map(|&(a, n)| a..a + n).collect();
    let md_hot: Vec<usize> = (0..l).filter(|&d| [1usize, 2, 4, 8, 16, 32].iter()
        .any(|&n| tot(&RAIN, d - d % n, n) > ALPHA * n as i64)).collect();
    assert!(md_hot == bad_days, "road 3: dyadic maximal function above ALPHA on exactly the boxes");
    println!("road 2, largest hot boxes: {}", show(&largest(&RAIN, ALPHA), 0));
    println!("road 3, days with dyadic maximal function above {}: {:?}", ALPHA, md_hot);
    let inbox: i64 = boxes.iter().map(|&(a, n)| tot(&RAIN, a, n)).sum();
    println!("length of boxes {} days < rain in boxes {} mm / ALPHA = {} <= total / ALPHA = {}", bad_days.len(), inbox, dec(inbox, ALPHA), dec(f1, ALPHA));
    assert!((bad_days.len() as i64) * ALPHA < inbox && inbox <= f1, "length bound");
    assert!((0..l).filter(|d| !bad_days.contains(d)).all(|d| RAIN[d] <= ALPHA), "outside the boxes, rain <= ALPHA");

    let mut g32: Vec<i64> = RAIN.iter().map(|r| 32 * r).collect(); // good part times 32
    for &(a, n) in &boxes {
        for d in a..a + n { g32[d] = 32 * tot(&RAIN, a, n) / n as i64; }
    }
    let b32: Vec<i64> = RAIN.iter().zip(&g32).map(|(r, g)| 32 * r - g).collect();
    for &(a, n) in &boxes {
        let s: i64 = b32[a..a + n].iter().sum();
        let parts: Vec<String> = b32[a..a + n].iter().map(|&x| dec(x, 32)).collect();
        let size: i64 = b32[a..a + n].iter().map(|x| x.abs()).sum();
        println!("  bad part on [{},{}): {}, sum {}, size {}", a, a + n, parts.join(" "), dec(s, 32), dec(size, 32));
        assert!(s == 0, "bad part nets to zero on each box");
    }
    let e_g: i64 = g32.iter().map(|x| x * x).sum();
    let e_f: i64 = 1024 * RAIN.iter().map(|r| r * r).sum::<i64>();
    let gmax = *g32.iter().max().unwrap();
    println!("good part: largest {} mm/day, total {} mm, energy {}", dec(gmax, 32), dec(g32.iter().sum(), 32), dec(e_g, 1024));
    println!("rain energy {}; bound on good energy 2 ALPHA x total = {}", dec(e_f, 1024), 2 * ALPHA * f1);
    println!("bad part: total size {} mm <= 2 x rain in boxes = {}", dec(b32.iter().map(|x| x.abs()).sum(), 32), 2 * inbox);
    assert!(gmax <= 64 * ALPHA && g32.iter().sum::<i64>() == 32 * f1 && e_g <= 1024 * 2 * ALPHA * f1 && 1024 * 2 * ALPHA * f1 < e_f);

    let bvals: Vec<f64> = b32[28..32].iter().map(|&x| x as f64 / 32.0).collect();
    let cut: Vec<f64> = RAIN[28..32].iter().map(|&r| (r - ALPHA).max(0) as f64).collect(); // truncation remainder
    println!("far field of [28,32): distance, bad part, cut-at-level remainder, ratio");
    let (mut ratios, mut hb, mut hc) = (Vec::new(), 0.0, 0.0);
    for dist in [8i64, 16, 32, 64] {
        hb = pull(&bvals, 28, 30 - dist);
        hc = pull(&cut, 28, 30 - dist);
        ratios.push((hb / hc).abs());
        println!("  {:>3} days  {:>10.6}  {:>10.6}  {:.6}", dist, hb, hc, ratios[ratios.len() - 1]);
    }
    assert!(ratios.windows(2).all(|w| w[1] < 0.65 * w[0]), "bad part fades faster");
    let m1: f64 = (28..32).map(|d| b32[d] as f64 / 32.0 * (d as f64 + 0.5 - 30.0)).sum(); // first moment, -24
    println!("at 64 days, bad part x distance^2 = {:.6}; first moment {:.1} mm x days, / pi = {:.6}", hb * 4096.0, m1, m1 / PI);
    println!("at 64 days, remainder x distance = {:.6}; -38 / pi = {:.6}", hc * 64.0, -38.0 / PI);
    assert!((hb * 4096.0 / (m1 / PI) - 1.0).abs() < 0.05 && (hc * 64.0 / (-38.0 / PI) - 1.0).abs() < 0.05, "far-field laws");

    let trunc: Vec<i64> = RAIN.iter().map(|&r| (r - ALPHA).max(0)).collect();
    let tdays: Vec<usize> = (0..l).filter(|&d| trunc[d] != 0).collect();
    println!("wrong: cut at the level, remainder total {} mm, on days {:?}", trunc.iter().sum::<i64>(), tdays);
    println!("wrong: start at single days, largest box average {} > 2 ALPHA = {}", RAIN.iter().max().unwrap(), 2 * ALPHA);
    println!("wrong: good part <= ALPHA, but it reaches {}", dec(gmax, 32));
    let drizzle: Vec<String> = [5u32, 10, 20].iter().map(|&n| dec(12 * 2i64.pow(n), 2i64.pow(n))).collect();
    println!("fails: 12 mm/day forever, average over 2^n days for n = 5, 10, 20: {}", drizzle.join(", "));
    let mut shift = vec![0i64];
    shift.extend_from_slice(&RAIN);
    shift.extend_from_slice(&[0; 31]);
    let sb = run(&shift, ALPHA);
    println!("grid moved one day: boxes {}, length {} days", show(&sb, 1), sb.iter().map(|b| b.1).sum::<usize>());
    let mut heavy = RAIN.to_vec();
    heavy[29] = 96;
    for (label, rain, alpha) in [("try: ALPHA = 5", RAIN.to_vec(), 5), ("try: ALPHA = 20", RAIN.to_vec(), 20),
                                 ("try: day 29 = 96 mm", heavy, ALPHA)] {
        let bx = run(&rain, alpha);
        assert!(bx == largest(&rain, alpha));
        println!("{}: boxes {}, length {} days", label, show(&bx, 0), bx.iter().map(|b| b.1).sum::<usize>());
    }
    println!("chart, rain      {}", RAIN.iter().map(|r| r.to_string()).collect::<Vec<_>>().join(" "));
    println!("chart, good part {}", g32.iter().map(|&g| dec(g, 32)).collect::<Vec<_>>().join(" "));
    println!("figure, x = 40 + 18 x day px, bar height 3 px per mm from y = 190, ALPHA line y = 160, 2 ALPHA line y = 130");
    println!("figure, stopped boxes px {}", boxes.iter().map(|&(a, n)| format!("{}-{}", 40 + 18 * a, 40 + 18 * (a + n)))
             .collect::<Vec<_>>().join(", "));
    println!("ALL CHECKS PASS");
}
