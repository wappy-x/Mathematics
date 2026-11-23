// Percolation on the square grid: the check behind the card. std only.
// Roads: (1) exact enumeration of every open/closed pattern on a small box,
// (2) the duality count a_k + a_(E-k) = C(E, k), (3) simulation with a written-out
// generator (SplitMix64, seed 2026), held against the exact numbers.

struct SplitMix64 { s: u64 }
impl SplitMix64 {
    // a uniform number in [0, 1), exact in both languages
    fn unit(&mut self) -> f64 {
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
}
// Channels of a box of pores, w columns by h rows. Vertical channels in the
// first and last column cannot help a left-to-right crossing: kept only if sides.
fn boxe(w: usize, h: usize, sides: bool) -> Vec<(usize, usize)> {
    let mut e = Vec::new();
    for y in 0..h {
        for x in 0..w - 1 {
            e.push((y * w + x, y * w + x + 1));
        }
    }
    let (x0, x1) = if sides { (0, w) } else { (1, w - 1) };
    for y in 0..h - 1 {
        for x in x0..x1 {
            e.push((y * w + x, (y + 1) * w + x));
        }
    }
    e
}
fn find(par: &mut Vec<usize>, mut a: usize) -> usize {
    while par[a] != a {
        par[a] = par[par[a]];
        a = par[a];
    }
    a
}
fn join(par: &mut Vec<usize>, u: usize, v: usize) {
    let (ru, rv) = (find(par, u), find(par, v));
    par[ru] = rv;
}
fn crosses(w: usize, h: usize, par: &mut Vec<usize>) -> bool {
    let left: Vec<usize> = (0..h).map(|y| find(par, y * w)).collect();
    (0..h).any(|y| left.contains(&find(par, y * w + w - 1)))
}
// is the centre pore of a w-by-w square joined to its rim?
fn reaches(w: usize, _h: usize, par: &mut Vec<usize>) -> bool {
    let c = find(par, w * w / 2);
    (0..w * w).filter(|i| i % w == 0 || i % w == w - 1 || i / w == 0 || i / w == w - 1).any(|i| find(par, i) == c)
}
// a[k] = how many patterns with k open channels pass ok (water crossing left to right, or reaching the rim)
fn exact_counts(w: usize, h: usize, sides: bool, ok: &dyn Fn(usize, usize, &mut Vec<usize>) -> bool) -> Vec<u64> {
    let e = boxe(w, h, sides);
    let mut a = vec![0u64; e.len() + 1];
    for mask in 0u64..(1u64 << e.len()) {
        let mut par: Vec<usize> = (0..w * h).collect();
        for (i, &(u, v)) in e.iter().enumerate() {
            if mask >> i & 1 == 1 {
                join(&mut par, u, v);
            }
        }
        if ok(w, h, &mut par) {
            a[mask.count_ones() as usize] += 1;
        }
    }
    a
}
// crossing chance at p = num/den, as (top, bottom) integers
fn exact_f(a: &[u64], num: u128, den: u128) -> (u128, u128) {
    let n = a.len() - 1;
    let top = (0..=n).map(|k| a[k] as u128 * num.pow(k as u32) * (den - num).pow((n - k) as u32)).sum();
    (top, den.pow(n as u32))
}
// top/bot rounded to 4 decimals, in integers
fn dec((top, bot): (u128, u128)) -> String {
    let q = (2 * top * 10000 + bot) / (2 * bot);
    format!("{}.{:04}", q / 10000, q % 10000)
}
fn sim_cross(w: usize, h: usize, p: f64, trials: usize, rng: &mut SplitMix64) -> usize {
    let (e, mut hits) = (boxe(w, h, false), 0);
    for _ in 0..trials {
        let mut par: Vec<usize> = (0..w * h).collect();
        for &(u, v) in &e {
            if rng.unit() < p {
                join(&mut par, u, v);
            }
        }
        hits += crosses(w, h, &mut par) as usize;
    }
    hits
}
fn sim_reach(r: usize, p: f64, trials: usize, rng: &mut SplitMix64) -> usize {
    let (w, mut hits) = (2 * r + 1, 0);
    let e = boxe(w, w, true);
    for _ in 0..trials {
        let mut par: Vec<usize> = (0..w * w).collect();
        for &(u, v) in &e {
            if rng.unit() < p {
                join(&mut par, u, v);
            }
        }
        hits += reaches(w, w, &mut par) as usize;
    }
    hits
}
fn main() {
    let (mut rng, t) = (SplitMix64 { s: 2026 }, 400usize);
    let tf = t as f64;
    let a = exact_counts(4, 3, false, &crosses);
    let n = a.len() - 1;
    println!("Exact: the 4-by-3 box, {} channels, {} patterns; a_k = {:?}", n, 1u64 << n, a);
    let comb = |n: u64, k: u64| (0..k).fold(1u64, |c, i| c * (n - i) / (i + 1));
    assert!((0..=n).all(|k| a[k] + a[n - k] == comb(n as u64, k as u64))); // duality, every k
    println!("duality a_k + a_(13-k) = C(13,k): checked for k = 0..{}", n);
    let nh = boxe(4, 3, false).iter().filter(|&&(u, v)| v == u + 1).count();
    println!("by hand: {} across + {} up-down; a_3 + a_10 = {} = C(13,3); a_6 + a_7 = {} = C(13,6)", nh, n - nh, a[3] + a[10], a[6] + a[7]);
    let (half, f40, f60) = (exact_f(&a, 50, 100), exact_f(&a, 40, 100), exact_f(&a, 60, 100));
    assert!(half.0 * 2 == half.1); // f(1/2) = 1/2 exactly, as duality predicts
    assert!(f40.0 + f60.0 == f40.1); // f(p) + f(1-p) = 1
    println!("crossing patterns: {} of {}, so f(0.50) = {} exactly", a.iter().sum::<u64>(), 1u64 << n, dec(half));
    println!("f(0.40) = {}, f(0.60) = {}, sum 1 exactly", dec(f40), dec(f60));
    let sq = exact_counts(3, 3, false, &crosses);
    let sqh = exact_f(&sq, 50, 100);
    assert!(2 * sqh.0 != sqh.1); // the wrong shape is not fair
    println!("wrong shape, 3-by-3 box ({} channels): f(0.50) = {}/{} = {}", sq.len() - 1, sq.iter().sum::<u64>(), 1u64 << (sq.len() - 1), dec(sqh));
    let hit = sim_cross(4, 3, 0.6, t, &mut rng);
    println!("simulated 4-by-3 box at p = 0.60: {}/{} = {:.4} against exact {}", hit, t, hit as f64 / tf, dec(f60));
    assert!((hit as f64 / tf - f60.0 as f64 / f60.1 as f64).abs() < 4.0 * (0.6 * 0.4 / tf).sqrt());
    println!("Crossing chance: p, exact 4x3, simulated 9x8, simulated 33x32 (400 runs each)");
    let mut curve = std::collections::HashMap::new();
    for k in (30..71).step_by(5) {
        let p = k as f64 / 100.0;
        let c = (sim_cross(9, 8, p, t, &mut rng), sim_cross(33, 32, p, t, &mut rng));
        curve.insert(k, c);
        println!("p=0.{}  {}  {:.4}  {:.4}", k, dec(exact_f(&a, k as u128, 100)), c.0 as f64 / tf, c.1 as f64 / tf);
    }
    assert!((curve[&50].1 as f64 / tf - 0.5).abs() < 4.0 * (0.25 / tf).sqrt()); // fair at p = 1/2
    assert!(curve[&40].1 < curve[&40].0 && curve[&60].1 > curve[&60].0); // the switch sharpens
    println!("Reach: chance the centre joins the rim at distance r (400 runs each)");
    let mut reach = Vec::new();
    for p in [0.5, 0.6] {
        let row: Vec<f64> = [2, 4, 8, 16, 32].iter().map(|&r| sim_reach(r, p, t, &mut rng) as f64 / tf).collect();
        let s: Vec<String> = row.iter().map(|x| format!("{:.4}", x)).collect();
        println!("p={:.2}  r=2,4,8,16,32: {}", p, s.join("  "));
        reach.push(row);
    }
    assert!(reach[0][0] - reach[0][4] > 6.0 * (0.5 / tf).sqrt()); // dying out at p = 1/2
    assert!(reach[1][4] > reach[0][4] + 6.0 * (0.5 / tf).sqrt()); // but not at p = 0.60
    let r1 = exact_counts(3, 3, true, &reaches); // second road for reach: all 4096 patterns at r = 1
    assert!(r1.iter().sum::<u64>() == 4096 - 256 && exact_f(&r1, 60, 100).0 == (100u128.pow(4) - 40u128.pow(4)) * 100u128.pow(8)); // 1 - (1-p)^4
    println!("reach at r = 1, exact over all 4096 patterns: {} at p = 0.50, {} at p = 0.60, both 1 - (1-p)^4", dec(exact_f(&r1, 50, 100)), dec(exact_f(&r1, 60, 100)));
    let (mean, tree) = (sim_cross(33, 32, 0.25, t, &mut rng), sim_cross(33, 32, 1.0 / 3.0, t, &mut rng));
    println!("mean-degree rule p=0.25: 33x32 crossing {}/{}; tree rule p=0.3333: {}/{}", mean, t, tree, t);
    assert!(mean == 0 && tree < 4);
    let (mut fig, mut par, mut opened) = (SplitMix64 { s: 2 }, (0..72).collect::<Vec<usize>>(), 0); // the drawn sample
    for (u, v) in boxe(9, 8, false) {
        if fig.unit() < 0.5 {
            join(&mut par, u, v);
            opened += 1;
        }
    }
    let left: Vec<usize> = (0..8).map(|y| find(&mut par, 9 * y)).collect();
    let wet = (0..72).filter(|&i| left.contains(&find(&mut par, i))).count();
    let cr = if crosses(9, 8, &mut par) { "yes" } else { "no" };
    println!("figure, seed 2: {} of 113 channels open, {} of 72 pores wet, crosses: {}", opened, wet, cr);
    println!("ALL CHECKS PASS");
}
