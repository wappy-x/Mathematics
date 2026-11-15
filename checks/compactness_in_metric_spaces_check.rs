// Compactness three ways -- the same check as the Python, in Rust.  No crates.
// The plot is 40 m by 30 m, fence included, held in whole centimetres so the
// distances compare as integers.  Finite runs illustrate; only the exhaustive
// check of the 1023 finite subfamilies is a proof, of that finite claim.
use std::f64::consts::PI;

const W: i64 = 4000;
const H: i64 = 3000;
const DIAG: i64 = 5000; // the plot and its diagonal, in cm

fn cm(v: i64) -> String { format!("{}.{:02}", v / 100, v % 100) } // whole cm as metres

fn m(v: f64) -> String { // an exact metre value, zeros trimmed
    let s = format!("{:.5}", v);
    s.trim_end_matches('0').trim_end_matches('.').to_string()
}

fn gcd(a: i64, b: i64) -> i64 { if b == 0 { a } else { gcd(b, a % b) } }

fn frac(n: i64, d: i64) -> String { let g = gcd(n, d); format!("{}/{}", n / g, d / g) }

fn sq(p: (i64, i64), q: (i64, i64)) -> i64 { (p.0 - q.0).pow(2) + (p.1 - q.1).pow(2) }

fn isqrt(n: i64) -> i64 { let mut r = (n as f64).sqrt() as i64; while r * r > n { r -= 1 } while (r + 1) * (r + 1) <= n { r += 1 } r }

struct SplitMix(u64);
impl SplitMix { // SplitMix64, written out
    fn next(&mut self) -> u64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    }
}

fn cell(p: (i64, i64), j: u32) -> (i64, i64) { // which of the 2^j by 2^j boxes holds p
    let n = 1i64 << j;
    ((p.0 * n / W).min(n - 1), (p.1 * n / H).min(n - 1))
}

// a hub with streets of 100 m: (street, metres out); across streets d = s + t
fn hub(p: (i64, i64), q: (i64, i64)) -> i64 {
    if p.0 == q.0 || p.1 == 0 || q.1 == 0 { (p.1 - q.1).abs() } else { p.1 + q.1 }
}

fn main() {
    // ---- the plot's three distances, corner to corner ----
    println!("corner to corner: walk {} m, straight {} m, worst-case {} m",
             cm(W + H), cm(isqrt(W * W + H * H)), cm(W.max(H)));

    // ---- road one to total boundedness: squares, each inside one open ball ----
    let mut test: Vec<(i64, i64)> = Vec::new();
    for x in (0..=W).step_by(25) { for y in (0..=H).step_by(25) { test.push((x, y)) } }
    for eps in [1000i64, 500, 100] {
        let (nx, ny) = ((W + eps - 1) / eps, (H + eps - 1) / eps);
        let mut worst = 0;
        for &(x, y) in &test { // the centre of the square holding (x, y)
            let c = ((x / eps).min(nx - 1) * eps + eps / 2, (y / eps).min(ny - 1) * eps + eps / 2);
            worst = worst.max(sq((x, y), c));
        }
        println!("net, radius {} m: {} x {} = {} balls; farthest test point {:.2} m from its centre",
                 cm(eps), nx, ny, nx * ny, (worst as f64).sqrt() / 100.0);
        assert!(worst < eps * eps); // strictly inside: open balls cover
        if eps == 1000 { // room left inside a disc: a Lebesgue number
            println!("any ball of radius below {:.4} m lies inside one of the 12 discs", 10.0 - (worst as f64).sqrt() / 100.0);
        }
    }
    println!("test points: every 0.25 m, {} of them, fence included", test.len());

    // ---- road two: a greedy net, built from the test points themselves ----
    let eps = 500i64;
    let mut greedy: Vec<(i64, i64)> = Vec::new();
    for &p in &test {
        if greedy.iter().all(|&c| sq(p, c) >= eps * eps) { greedy.push(p) }
    }
    let ceiling = (((W + eps) * (H + eps)) as f64 / (PI * eps as f64 * eps as f64 / 4.0)) as usize;
    let floor_area = (PI * eps as f64 * eps as f64) as i64;
    let floor = ((W * H + floor_area - 1) / floor_area) as usize; // the plot's area over one disc's area
    println!("greedy net, radius {} m: {} balls; centres pairwise at least {} m apart; area floor {}, packing ceiling {}",
             cm(eps), greedy.len(), eps / 100, floor, ceiling);
    assert!(test.iter().all(|&p| greedy.iter().any(|&c| sq(p, c) < eps * eps)));
    assert!(floor <= greedy.len() && greedy.len() <= ceiling);

    // ---- a wandering list of stakes, and a settling subsequence by quartering ----
    let mut gen = SplitMix(2026);
    let stakes: Vec<(i64, i64)> = (0..50000).map(|_| {
        let r = gen.next();
        (((r & 0xFFFFFFFF) % (W as u64 + 1)) as i64, ((r >> 32) % (H as u64 + 1)) as i64)
    }).collect();
    let (mut alive, mut picks, mut bx): (Vec<usize>, Vec<usize>, (i64, i64)) = ((0..stakes.len()).collect(), vec![], (0, 0));
    let mut boxes: Vec<String> = Vec::new();
    for j in 0..7u32 {
        if j > 0 { // keep the quarter with the most later stakes
            let last = *picks.last().unwrap();
            let kids: Vec<(i64, i64)> = [(0, 0), (1, 0), (0, 1), (1, 1)].iter().map(|&(a, b)| (2 * bx.0 + a, 2 * bx.1 + b)).collect();
            let counts: Vec<usize> = kids.iter().map(|&k| alive.iter().filter(|&&i| i > last && cell(stakes[i], j) == k).count()).collect();
            let best = *counts.iter().max().unwrap();
            bx = kids[counts.iter().position(|&c| c == best).unwrap()];
            alive.retain(|&i| cell(stakes[i], j) == bx);
        }
        let later: Vec<usize> = alive.iter().copied().filter(|&i| picks.is_empty() || i > *picks.last().unwrap()).collect();
        picks.push(later[0]);
        let d = (100i64 << j) as f64; // cm per metre, times the halvings
        boxes.push(format!("{} {} {} {}", m((bx.0 * W) as f64 / d), m((bx.1 * H) as f64 / d), m(W as f64 / d), m(H as f64 / d)));
        let p = stakes[later[0]];
        println!("level {}: box x {}..{}, y {}..{} m, diagonal {} m; {} later stakes; pick #{} at ({}, {})",
                 j, m((bx.0 * W) as f64 / d), m(((bx.0 + 1) * W) as f64 / d), m((bx.1 * H) as f64 / d),
                 m(((bx.1 + 1) * H) as f64 / d), m(DIAG as f64 / d), later.len(), later[0], cm(p.0), cm(p.1));
    }
    for j in 0..picks.len() { // each later pick sits in every earlier box
        for k in j + 1..picks.len() {
            assert!(sq(stakes[picks[j]], stakes[picks[k]]) * (1i64 << (2 * j)) <= DIAG * DIAG);
        }
    }
    assert!(picks.windows(2).all(|w| w[0] < w[1]));
    let gap = (sq(stakes[picks[5]], stakes[picks[6]]) as f64).sqrt() / 100.0;
    println!("picks 5 and 6 are {:.2} m apart, inside the level-5 diagonal {} m", gap, m(DIAG as f64 / 3200.0));
    let mut close = i64::MAX;
    for a in 0..49 { for b in 0..a { close = close.min(sq(stakes[a], stakes[b])) } }
    println!("pigeonhole: of the first 49 stakes, the closest two are {:.2} m apart (at most {:.2} m guaranteed)",
             (close as f64).sqrt() / 100.0, ((2 * 500 * 500) as f64).sqrt() / 100.0);
    assert!(close <= 2 * 500 * 500);

    // ---- what breaks 1: the fence line without its end posts, (0, 40) ----
    // Stake k sits at 40/2^k m; cover set U_m is the open stretch (40/2^m, 40).
    // Compare 40/2^m < 40/2^k exactly, as 2^k < 2^m.
    let mut uncovered = 0;
    for mask in 1u32..1 << 10 { // every finite subfamily of U_1 .. U_10
        let chosen: Vec<u32> = (1..=10).filter(|mm| mask >> (mm - 1) & 1 == 1).collect();
        if (1..12u32).any(|k| chosen.iter().all(|&mm| !((1u64 << k) < (1u64 << mm)))) {
            uncovered += 1; // some stake k lies in none of the chosen sets
        }
    }
    println!("open fence (0, 40): U_1..U_10 reach down to {} m; stake 11 at {} m is outside; subfamilies leaving a stake out: {} of 1023",
             frac(40, 1 << 10), frac(40, 1 << 11), uncovered);
    assert!(uncovered == (1 << 10) - 1);
    println!("stakes 10 and 11 differ by {} m; the list heads for 0, not in (0, 40)", frac(40, 1 << 11));

    // ---- what breaks 2: a road with no end, stakes every 40 m ----
    let road: Vec<i64> = (0..100).map(|k| 40 * k).collect();
    println!("endless road: closest two of 100 stakes {} m apart", road.windows(2).map(|w| w[1] - w[0]).min().unwrap());
    let mut far_road = i64::MAX;
    for &a in &road { for &b in &road { if a != b { far_road = far_road.min((a - b).abs()) } } }
    assert!(far_road == 40);

    // ---- what breaks 3: a hub with n streets, each 100 m ----
    for n in [3i64, 12, 48] {
        let ends: Vec<(i64, i64)> = (0..n).map(|i| (i, 100)).collect();
        let mut most = 0;
        for i in 0..n { for t in 0..=100 {
            most = most.max(ends.iter().filter(|&&e| hub((i, t), e) < 100).count());
        } }
        let mut far = i64::MAX;
        for &a in &ends { for &b in &ends { if a != b { far = far.min(hub(a, b)) } } }
        println!("hub, {} streets: all within 100 m of the hub; ends {} m apart; one open 100 m ball holds at most {} end, so {} balls needed",
                 n, far, most, n);
        assert!(most == 1 && far == 200);
    }

    // ---- what breaks 4: covering by single points, which are closed, not open ----
    println!("one-point cover: whole-centimetre points alone need {} sets", (W + 1) * (H + 1));
    let pk: Vec<String> = picks[..4].iter().map(|&i| format!("{} {}", cm(stakes[i].0), cm(stakes[i].1))).collect();
    println!("figure, plot 0 0 40 30; net centres x 5 15 25 35, y 5 15 25, radius 10; boxes x y w h {}; picks {}",
             boxes[..4].join("; "), pk.join("; "));
    println!("ALL CHECKS PASS");
}
