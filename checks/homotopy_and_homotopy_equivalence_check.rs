// Homotopy and homotopy equivalence -- the same check as the Python, in Rust.  No crates.
// A lamp post is the disc of radius 0.1 m round (0, 0); the owner stands at (2, 0).
// A walk is a loop s -> point, s in [0, 1]; a homotopy H(s, t) is one walk per frame t.
use std::collections::{HashMap, HashSet, VecDeque};
use std::f64::consts::PI;

const N: usize = 360;
const POST: f64 = 0.1;
type P = (f64, f64);

fn wound(k: f64, s: f64) -> P { (2.0 * (2.0 * PI * k * s).cos(), 2.0 * (2.0 * PI * k * s).sin()) }
fn bench(s: f64) -> P { (3.0 - (2.0 * PI * s).cos(), -(2.0 * PI * s).sin()) }
fn phi(s: f64) -> f64 { if s <= 0.5 { 2.0 * s } else { 2.0 - 2.0 * s } }
fn there_back(s: f64) -> P { wound(1.0, phi(s)) }
fn pts(f: &dyn Fn(f64) -> P) -> Vec<P> { (0..N).map(|j| f(j as f64 / N as f64)).collect() }
fn closest(p: &[P]) -> f64 { p.iter().map(|&(x, y)| (x * x + y * y).sqrt()).fold(f64::INFINITY, f64::min) }
fn wind_angle(p: &[P]) -> i64 {               // road 1: add the turns between neighbours
    let mut tot = 0.0;
    for i in 0..p.len() {
        let ((x0, y0), (x1, y1)) = (p[i], p[(i + 1) % p.len()]);
        tot += (x0 * y1 - y0 * x1).atan2(x0 * x1 + y0 * y1);
    }
    (tot / (2.0 * PI)).round() as i64
}
fn wind_ray(p: &[P]) -> i64 {                 // road 2: signed crossings of a ray from the post
    let u = (1.0f64.cos(), 1.0f64.sin());
    let mut n = 0;
    for i in 0..p.len() {
        let ((x0, y0), (x1, y1)) = (p[i], p[(i + 1) % p.len()]);
        let (c0, c1) = (u.0 * y0 - u.1 * x0, u.0 * y1 - u.1 * x1);
        if (c0 < 0.0) != (c1 < 0.0) {
            let a = c0 / (c0 - c1);
            if (x0 + a * (x1 - x0)) * u.0 + (y0 + a * (y1 - y0)) * u.1 > 0.0 { n += if c0 < 0.0 { 1 } else { -1 } }
        }
    }
    n
}
fn frame(h: &dyn Fn(f64, f64) -> P, t: f64) -> Vec<P> { pts(&|s| h(s, t)) }
fn straight(f: &dyn Fn(f64) -> P, s: f64, t: f64) -> P { let p = f(s); ((1.0 - t) * p.0 + 2.0 * t, (1.0 - t) * p.1) }
fn report(h: &dyn Fn(f64, f64) -> P) -> Vec<(f64, Option<i64>, Option<i64>)> {
    (0..11).map(|j| {
        let p = frame(h, j as f64 / 10.0);
        let d = closest(&p);
        if d <= POST { (d, None, None) } else { (d, Some(wind_angle(&p)), Some(wind_ray(&p))) }
    }).collect()
}
fn w(v: Option<i64>) -> String { match v { None => "hits post".to_string(), Some(k) => format!("winding {:2}", k) } }
fn frac(n: i64, d: i64) -> String {          // a fraction in lowest terms
    let (mut a, mut b) = (n.abs(), d);
    while b != 0 { (a, b) = (b, a % b) }
    if d / a == 1 { format!("{}", n / a) } else { format!("{}/{}", n / a, d / a) }
}
fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }
fn windings(r: &[(f64, Option<i64>, Option<i64>)]) -> Vec<i64> { r.iter().map(|x| x.1.unwrap()).collect() }
fn pieces_bfs<T: Copy + Eq + std::hash::Hash>(nodes: &HashSet<T>, order: &[T], nbrs: &dyn Fn(T) -> Vec<T>) -> usize {
    let (mut seen, mut n) = (HashSet::new(), 0);
    for &v in order {
        if seen.insert(v) {
            n += 1;
            let mut todo = VecDeque::from([v]);
            while let Some(x) = todo.pop_front() {
                for u in nbrs(x) { if nodes.contains(&u) && seen.insert(u) { todo.push_back(u) } }
            }
        }
    }
    n
}
fn pieces_uf<T: Copy + Eq + std::hash::Hash>(nodes: &HashSet<T>, order: &[T], nbrs: &dyn Fn(T) -> Vec<T>) -> usize {
    let mut par: HashMap<T, T> = order.iter().map(|&v| (v, v)).collect();
    fn root<T: Copy + Eq + std::hash::Hash>(par: &HashMap<T, T>, mut v: T) -> T { while par[&v] != v { v = par[&v] } v }
    for &v in order {
        for u in nbrs(v) {
            if nodes.contains(&u) { let (ru, rv) = (root(&par, u), root(&par, v)); par.insert(ru, rv); }
        }
    }
    order.iter().map(|&v| root(&par, v)).collect::<HashSet<T>>().len()
}

fn main() {
    let walks: Vec<(&str, Box<dyn Fn(f64) -> P>)> = vec![
        ("wound once", Box::new(|s| wound(1.0, s))), ("wound the other way", Box::new(|s| wound(-1.0, s))),
        ("round the bench", Box::new(bench)), ("round, then back", Box::new(there_back))];
    println!("post radius {} m at (0, 0); owner at (2, 0); {} samples per walk", POST, N);
    let mut wind = Vec::new();
    for (name, f) in &walks {
        let p = pts(f.as_ref());
        wind.push((wind_angle(&p), wind_ray(&p)));
        let k = wind.last().unwrap();
        println!("{:<20} closest {:.6} m, winding by angle sum {:2}, by ray {:2}", name, closest(&p), k.0, k.1);
    }
    let sb = report(&|s, t| straight(&bench, s, t));
    let sw = report(&|s, t| straight(&|s| wound(1.0, s), s, t));
    println!("straight slide to the owner, frame by frame:");
    for j in 0..11 {
        println!("t={:.1}  bench {:.6} m {}  |  wound once {:.6} m {}", j as f64 / 10.0, sb[j].0, w(sb[j].1), sw[j].0, w(sw[j].1));
    }
    let mid = straight(&|s| wound(1.0, s), 0.5, 0.5);
    println!("wound once, gamma(1/2) = ({:.6}, {:.6}); H(1/2, 1/2) = ({:.6}, {:.6}): the straight slide crosses the post", wound(1.0, 0.5).0, wound(1.0, 0.5).1.abs(), mid.0.abs(), mid.1.abs());
    let tight = report(&|s, t| { let p = wound(1.0, s); ((1.0 - 0.75 * t) * p.0, (1.0 - 0.75 * t) * p.1) });
    println!("pull the wound lead tight, radius 2 -> 0.5 m: windings {:?}, closest at t=1 {:.6} m", windings(&tight), tight[10].0);
    let unwind = |s: f64, t: f64| wound(1.0, (1.0 - t) * phi(s));
    let undo = report(&unwind);
    println!("round-then-back, unwind the angle: windings {:?}, closest {:.6} m", windings(&undo), undo.iter().map(|r| r.0).fold(f64::INFINITY, f64::min));
    let end = frame(&unwind, 1.0);
    println!("  last frame stays at the owner: {}", yn(end.iter().map(|&(x, y)| (x - 2.0).abs() + y.abs()).fold(0.0, f64::max) < 1e-12));
    let jump: Vec<i64> = (0..11).map(|j| wind_angle(&frame(&|s, t| if t < 0.5 { wound(1.0, s) } else { (2.0, 0.0) }, j as f64 / 10.0))).collect();
    println!("mistake, frames that jump at t=0.5: windings {:?}, never nearer the post than 2 m", jump);
    // The lawn: a disc of radius 5 m.  Squash it to its centre with H(x, t) = (1 - t) x, exactly in integers.
    let lawn: Vec<(i64, i64)> = (-5..6).flat_map(|a| (-5..6).map(move |b| (a, b))).filter(|&(a, b)| a * a + b * b <= 25).collect();
    let inside = lawn.iter().all(|&(a, b)| (0..11i64).all(|j| (10 - j) * (10 - j) * (a * a + b * b) <= 2500));
    println!("lawn grid: {} points; every frame inside the lawn: {}; (3, 4) at t=1/2 -> ({}, {}); at t=1 all at (0, 0)", lawn.len(), yn(inside), frac(3, 2), frac(4, 2));
    // The ground: the lawn minus the post.  Retract it onto the 2 m ring: H(x, t) = (1 - t) x + t * 2x/|x|.
    let mut ground: Vec<P> = Vec::new();
    for a in -50..51i64 { for b in -50..51i64 { if 1 < a * a + b * b && a * a + b * b <= 2500 { ground.push((a as f64 / 10.0, b as f64 / 10.0)) } } }
    let (mut worst, mut low) = (0.0f64, 9.0f64);
    for &(x, y) in &ground {
        let r = (x * x + y * y).sqrt();
        for j in 0..11 {
            let t = j as f64 / 10.0;
            let (hx, hy) = ((1.0 - t) * x + t * 2.0 * x / r, (1.0 - t) * y + t * 2.0 * y / r);
            let d = (hx * hx + hy * hy).sqrt();
            worst = worst.max((d - ((1.0 - t) * r + 2.0 * t)).abs());
            low = low.min(d);
        }
    }
    let ring: Vec<P> = ground.iter().copied().filter(|&(x, y)| (x * x + y * y - 4.0).abs() < 1e-9).collect();
    let fixed = ring.iter().all(|&(x, y)| { let r = (x * x + y * y).sqrt(); (2.0 * x / r - x).abs() + (2.0 * y / r - y).abs() < 1e-12 });
    let (hx, hy) = (0.5 * 0.3 + 0.5 * 2.0 * 0.3 / 0.5, 0.5 * 0.4 + 0.5 * 2.0 * 0.4 / 0.5);
    println!("ground grid: {} points, 0.1 m apart; closest any frame comes to the post {:.6} m", ground.len(), low);
    println!("  distance (1-t)|x| + 2t by formula and directly agree to 1e-12: {}", yn(worst < 1e-12));
    println!("  (0.3, 0.4), |x| = {:.6}, at t=1/2 -> ({:.6}, {:.6}); at t=1 -> ({:.6}, {:.6})", (0.3f64 * 0.3 + 0.4 * 0.4).sqrt(), hx, hy, 2.0 * 0.3 / 0.5, 2.0 * 0.4 / 0.5);
    println!("  {} grid points on the ring, all left where they are: {}", ring.len(), yn(fixed));
    // Cut test: a homeomorphism keeps the number of pieces left after removing two points.
    let r_order: Vec<i64> = (0..12).filter(|v| *v != 0 && *v != 6).collect();
    let ring12: HashSet<i64> = r_order.iter().copied().collect();
    let step12 = |v: i64| vec![(v + 1).rem_euclid(12), (v - 1).rem_euclid(12)];
    let g_order: Vec<(i64, i64)> = (-5..6i64).flat_map(|a| (-5..6i64).map(move |b| (a, b)))
        .filter(|&(a, b)| 4 <= a * a + b * b && a * a + b * b <= 25 && (a, b) != (3, 0) && (a, b) != (-3, 0)).collect();
    let grid: HashSet<(i64, i64)> = g_order.iter().copied().collect();
    let step4 = |v: (i64, i64)| vec![(v.0 + 1, v.1), (v.0 - 1, v.1), (v.0, v.1 + 1), (v.0, v.1 - 1)];
    let rc = (pieces_bfs(&ring12, &r_order, &step12), pieces_uf(&ring12, &r_order, &step12));
    let gc = (pieces_bfs(&grid, &g_order, &step4), pieces_uf(&grid, &g_order, &step4));
    println!("cut two opposite points: ring of 12 -> {} pieces (union-find {}); ground model of {} -> {} piece (union-find {})", rc.0, rc.1, grid.len() + 2, gc.0, gc.1);
    println!("mistake, one round trip: point -> ring -> point is the identity; ring -> point -> ring winds {}, the identity loop {}", wind_angle(&pts(&|_| (2.0, 0.0))), wind[0].0);
    println!("figure,post r=0.1,ring c=(0,0) r=2,frame c=(1,0) r=1,bench c=(3,0) r=1,frame c=(2.5,0) r=0.5");
    assert!(wind == vec![(1, 1), (-1, -1), (0, 0), (0, 0)]);                         // two roads agree
    assert!((0..11).all(|j| (sw[j].0 - (2.0 - 0.4 * j as f64).abs()).abs() < 1e-9)); // sampled = exact |2 - 4t|
    assert!(sw.iter().map(|r| r.1).collect::<Vec<_>>() == [vec![Some(1); 5], vec![None], vec![Some(0); 5]].concat());
    assert!(sb.iter().all(|r| r.1 == Some(0)));
    assert!(sb.iter().all(|r| (r.0 - 2.0).abs() < 1e-9));                          // bench: 2 m in every frame
    assert!(windings(&tight) == vec![1; 11] && (tight[10].0 - 0.5).abs() < 1e-12 && windings(&undo) == vec![0; 11]);
    assert!(inside && lawn.len() == 81 && worst < 1e-12 && fixed && ring.len() == 12);
    assert!(rc == (2, 2) && gc == (1, 1) && jump == [vec![1; 5], vec![0; 6]].concat());
    println!("ALL CHECKS PASS");
}
