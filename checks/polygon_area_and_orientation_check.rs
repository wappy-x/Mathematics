// Shoelace formula: the check behind the card. std only.
// The survey polygon, corners A to F in hundreds of metres from a survey peg,
// so one grid square is one hectare. Road one is the shoelace sum of cross
// products. Road two slices the field into thin upright strips and adds their
// heights; it never forms a cross product.
type P = (i64, i64);
const POLY: [P; 6] = [(2, 1), (10, 1), (11, 6), (7, 4), (5, 8), (2, 6)]; // A B C D E F

fn cross(p: P, q: P) -> i64 { p.0 * q.1 - p.1 * q.0 }
fn terms(p: &[P]) -> Vec<i64> { (0..p.len()).map(|i| cross(p[i], p[(i + 1) % p.len()])).collect() }
fn shoelace(p: &[P]) -> f64 { terms(p).iter().sum::<i64>() as f64 / 2.0 }
fn turn(a: P, b: P, c: P) -> i64 { cross((b.0 - a.0, b.1 - a.1), (c.0 - a.0, c.1 - a.1)) }

fn slices(p: &[P], n: usize) -> f64 { // road two: n strips across x = 2..11
    let lo = p.iter().map(|q| q.0).min().unwrap() as f64;
    let hi = p.iter().map(|q| q.0).max().unwrap() as f64;
    let (w, mut total) = ((hi - lo) / n as f64, 0.0);
    for k in 0..n {
        let x = lo + (k as f64 + 0.5) * w; // the strip's middle line
        let mut ys: Vec<f64> = Vec::new();
        for i in 0..p.len() {
            let ((x1, y1), (x2, y2)) = (p[i], p[(i + 1) % p.len()]);
            let (x1, y1, x2, y2) = (x1 as f64, y1 as f64, x2 as f64, y2 as f64);
            if (x1 <= x && x < x2) || (x2 <= x && x < x1) {
                ys.push(y1 + (y2 - y1) * (x - x1) / (x2 - x1));
            }
        }
        ys.sort_by(|a, b| a.partial_cmp(b).unwrap()); // boundary crossings, bottom to top
        total += w * (0..ys.len()).step_by(2).map(|j| ys[j + 1] - ys[j]).sum::<f64>();
    }
    total
}

fn join(v: &[i64]) -> String { v.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(", ") }

fn main() {
    let names = ["A", "B", "C", "D", "E", "F"];
    let t = terms(&POLY);
    let (area, strip) = (shoelace(&POLY), slices(&POLY, 9000));
    let rev: Vec<P> = POLY.iter().rev().copied().collect();
    let back = shoelace(&rev);
    let turns: Vec<i64> = (0..6).map(|i| turn(POLY[(i + 5) % 6], POLY[i], POLY[(i + 1) % 6])).collect();
    let no_d: Vec<P> = vec![POLY[0], POLY[1], POLY[2], POLY[4], POLY[5]]; // cut the notch off at D
    let notch = slices(&no_d, 9000) - strip;
    let moved: Vec<P> = POLY.iter().map(|&(x, y)| (x - 2, y - 1)).collect(); // peg moved onto corner A
    let swapped: Vec<P> = [0, 2, 1, 3, 4, 5].iter().map(|&i| POLY[i]).collect(); // B and C copied in the wrong order
    let fig: Vec<String> = (0..6).map(|i| format!("{} ({}, {})", names[i], 30 + 26 * POLY[i].0, 222 - 26 * POLY[i].1)).collect();
    let cs: Vec<String> = (0..6).map(|i| format!("{} ({}, {})", names[i], POLY[i].0, POLY[i].1)).collect();
    println!("corners: {}", cs.join(", "));
    let pr: Vec<String> = (0..6).map(|i| { let (p, q) = (POLY[i], POLY[(i + 1) % 6]); format!("{} - {}", p.0 * q.1, p.1 * q.0) }).collect();
    println!("edge products: {}", pr.join(", "));
    println!("figure, 1 unit = 26 svg units: peg (30, 222), {}", fig.join(", "));
    let sum: i64 = t.iter().sum();
    println!("edge terms AB BC CD DE EF FA: {} ; sum {}", join(&t), sum);
    let m2 = (area * 10000.0) as i64;
    println!("road one, shoelace: {:.1} ha = {},{:03} m^2", area, m2 / 1000, m2 % 1000);
    println!("road two, 9000 upright strips: {:.6} ha", strip);
    println!("walked backwards, A F E D C B: {:.1} ha", back);
    println!("turn test at A B C D E F: {}", join(&turns));
    let fan: Vec<String> = [4, 5, 0, 1].iter().map(|&k| format!("{:.1}", turn(POLY[3], POLY[k], POLY[(k + 1) % 6]) as f64 / 2.0)).collect(); // D with EF, FA, AB, BC
    println!("fan from D, triangles DEF DFA DAB DBC: {} ha", fan.join(", "));
    println!("cut the notch at D, by strips: {:.6} ha more; half of -(turn at D): {:.1}", notch, -turns[3] as f64 / 2.0);
    println!("peg moved onto A: terms {}; area {:.1} ha", join(&terms(&moved)), shoelace(&moved));
    println!("what breaks: closing edge FA left out: {:.1} ha", t[..5].iter().sum::<i64>() as f64 / 2.0);
    println!("what breaks: no halving: {:.1}", sum as f64);
    println!("what breaks: each term made positive: {:.1} ha", t.iter().map(|v| v.abs()).sum::<i64>() as f64 / 2.0);
    println!("what breaks: B and C swapped: shoelace {:.1} ha, ground covered {:.2} ha", shoelace(&swapped), slices(&swapped, 9000));
    assert!((area - strip).abs() < 1e-6); // two roads, one area
    assert!(back == -area && shoelace(&moved) == area); // direction flips the sign; the peg does not matter
    assert!(turns.iter().map(|&v| v < 0).collect::<Vec<_>>() == vec![false, false, false, true, false, false]);
    assert!((notch - (-turns[3] as f64 / 2.0)).abs() < 1e-6); // the right turn's triangle is the notch
}
