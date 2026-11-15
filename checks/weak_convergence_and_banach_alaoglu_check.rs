// Weak convergence and Banach-Alaoglu -- the check behind the card.  Rust std only.
// A pace profile x(t) is a 10 km race's pace minus the 240 s/km target, in s/km, at
// fraction t of the distance.  Profiles live in L2(0, 1) with the orthonormal cosines
// c_k(t) = sqrt2 cos(k pi t).  Race n (illustrative numbers):
//   x_n = 6 cos(n) c_1 + 4 sin(n sqrt2) c_2 + 6 c_(n+2)     (start term, middle term, swaps)
// The code holds coefficients and finite grids only: it checks instances and trends;
// the infinite-dimensional claims rest on the proofs on the card.
use std::f64::consts::PI;

const M: usize = 200000;

fn r2() -> f64 { 2f64.sqrt() }

// km-1 time lost by c_k, in s: 10 * integral of c_k over [0, 0.1]
fn split1(k: usize) -> f64 { 10.0 * r2() * (k as f64 * PI / 10.0).sin() / (k as f64 * PI) }

// midpoint rule for the integral of f over [a, b]
fn grid(f: &dyn Fn(f64) -> f64, a: f64, b: f64, g: usize) -> f64 {
    let h = (b - a) / g as f64;
    let mut s = 0.0;
    for i in 0..g { s += f(a + (i as f64 + 0.5) * h); }
    h * s
}

fn join_f(v: &[f64], d: usize) -> String {
    v.iter().map(|x| format!("{:.*}", d, x)).collect::<Vec<_>>().join(", ")
}

struct Races { start: Vec<f64>, middle: Vec<f64> }

impl Races {
    fn val(&self, c: usize, n: usize) -> f64 { if c == 0 { self.start[n - 1] } else { self.middle[n - 1] } }
    fn inside(&self, n: usize, bx: &[[f64; 2]; 2], upto: usize) -> bool {
        (0..=upto).all(|j| bx[j][0] <= self.val(j, n) && self.val(j, n) <= bx[j][1])
    }
    fn km1(&self, n: usize) -> f64 { self.start[n - 1] * split1(1) + self.middle[n - 1] * split1(2) + 6.0 * split1(n + 2) }
    fn rms(&self, n: usize) -> f64 { (self.start[n - 1].powi(2) + self.middle[n - 1].powi(2) + 36.0).sqrt() }
    fn diagonal(&self, depth: usize) -> ([[f64; 2]; 2], Vec<usize>, Vec<(usize, [f64; 2])>) {
        let (mut bx, mut last, mut picks, mut steps) = ([[-6.0, 6.0], [-4.0, 4.0]], 0usize, vec![], vec![]);
        for coord in 0..2 {
            for _ in 0..depth {
                let [lo, hi] = bx[coord];
                let mid = (lo + hi) / 2.0;
                let cand: Vec<usize> = (last + 1..=M).filter(|&n| self.inside(n, &bx, coord)).collect();
                let low = cand.iter().filter(|&&n| self.val(coord, n) < mid).count();
                bx[coord] = if low >= cand.len() - low { [lo, mid] } else { [mid, hi] };
                last = *cand.iter().find(|&&n| bx[coord][0] <= self.val(coord, n) && self.val(coord, n) <= bx[coord][1]).unwrap();
                picks.push(last);
                steps.push((coord, bx[coord]));
            }
        }
        (bx, picks, steps)
    }
}

fn main() {
    let r2 = r2();
    // 1. The picture: pure swap profiles 6 c_m.  Splits fade, size and peak stay.
    println!("swap profile 6 c_m: m | km-1 split s (formula, grid) | RMS s/km (grid) | peak | total");
    let mut chart = vec![];
    for m in [1usize, 2, 4, 8, 16, 32, 64] {
        let f = move |t: f64| 6.0 * r2 * (m as f64 * PI * t).cos();
        let (s_a, s_g) = (6.0 * split1(m), 10.0 * grid(&f, 0.0, 0.1, 10000));
        let rms = grid(&|t| f(t).powi(2), 0.0, 1.0, 20000).sqrt();
        let tot = 10.0 * grid(&f, 0.0, 1.0, 20000);
        chart.push(s_a);
        println!("  m={:2} | {:7.3} {:7.3} | {:.4} | {:.4} | {:.4}", m, s_a, s_g, rms, 6.0 * r2, tot.abs());
        assert!((s_a - s_g).abs() < 1e-6 && (rms - 6.0).abs() < 1e-9 && tot.abs() < 1e-6);
    }
    println!("  chart row: {}", join_f(&chart, 2));

    // 2. The races themselves: the start and middle terms jump about, so x_n has no weak limit.
    let rc = Races {
        start: (1..=M).map(|n| 6.0 * (n as f64).cos()).collect(),
        middle: (1..=M).map(|n| 4.0 * (n as f64 * r2).sin()).collect(),
    };
    println!("races 1-8: start  {}", join_f(&rc.start[..8], 2));
    println!("           middle {}", join_f(&rc.middle[..8], 2));
    println!("           km-1   {}", join_f(&(1..=8).map(|n| rc.km1(n)).collect::<Vec<_>>(), 2));
    let maxrms = (1..=M).map(|n| rc.rms(n)).fold(f64::MIN, f64::max);
    println!("  bound B = sqrt(36 + 16 + 36) = {:.4}; largest RMS seen {:.4}", 88f64.sqrt(), maxrms);

    // 3. The diagonal: halve the start term's range 6 times, then the middle term's inside it,
    //    each time keeping the half that holds more of the later races, and pick the next race.
    let (bx, picks, steps) = rc.diagonal(6);
    println!("picks n_k = {}", picks.iter().map(|n| n.to_string()).collect::<Vec<_>>().join(", "));
    println!("  start box [{:.4}, {:.4}], middle box [{:.4}, {:.4}]", bx[0][0], bx[0][1], bx[1][0], bx[1][1]);
    let (a1, a2) = ((bx[0][0] + bx[0][1]) / 2.0, (bx[1][0] + bx[1][1]) / 2.0);
    let inbox: Vec<usize> = (1..=M).filter(|&n| rc.inside(n, &bx, 1)).collect();
    let law = ((bx[0][0] / 6.0).acos() - (bx[0][1] / 6.0).acos()) / PI
        * ((bx[1][1] / 4.0).asin() - (bx[1][0] / 4.0).asin()) / PI;
    println!("  races n <= {} in both boxes: {}; equidistribution predicts {:.1}", M, inbox.len(), M as f64 * law);
    println!("  limit x = {:.4} c_1 {:+.4} c_2; km-1 split {:.4} s; RMS {:.4} s/km",
             a1, a2, a1 * split1(1) + a2 * split1(2), a1.hypot(a2));
    println!("  by hand: c_1 reads {:.4} s on km 1, c_2 {:.4}; {:.4} {:+.4}; RMS^2 {:.4} + {:.4} = {:.4}",
             split1(1), split1(2), a1 * split1(1), a2 * split1(2), a1 * a1, a2 * a2, a1 * a1 + a2 * a2);
    let sq: Vec<[f64; 2]> = bx.iter().map(|b| { let (u, v) = (b[0] * b[0], b[1] * b[1]); [u.min(v), u.max(v)] }).collect(); // squared coefficients allowed
    println!("  known only to the boxes: limit's km-1 split {:.4} to {:.4} s; any race in both boxes has RMS {:.4} to {:.4} s/km",
             bx[0][0] * split1(1) + bx[1][0] * split1(2), bx[0][1] * split1(1) + bx[1][1] * split1(2), (sq[0][0] + sq[1][0] + 36.0).sqrt(), (sq[0][1] + sq[1][1] + 36.0).sqrt());

    // 4. Along the subsequence every split settles; the size does not fall to the limit's.
    let (lim1, limrms) = (a1 * split1(1) + a2 * split1(2), a1.hypot(a2));
    let tail: Vec<usize> = inbox.iter().cloned().filter(|&n| n > *picks.last().unwrap()).collect();
    println!("tail j | race n | km-1 split | gap to limit | allowed gap | RMS");
    for j in [1usize, 10, 100, 1000] {
        let n = tail[j - 1];
        let gap = (rc.km1(n) - lim1).abs();
        let allow = 0.09375 * split1(1) + 0.0625 * split1(2).abs() + 60.0 * r2 / (PI * (n + 2) as f64);
        println!("  {:4} | {:6} | {:8.4} | {:.4} | {:.4} | {:.4}", j, n, rc.km1(n), gap, allow, rc.rms(n));
        assert!(gap <= allow + 1e-12);
    }
    let n0 = tail[0]; // a second road to the sizes: integrate the profiles squared on a grid
    let prof = |t: f64| r2 * (rc.start[n0 - 1] * (PI * t).cos() + rc.middle[n0 - 1] * (2.0 * PI * t).cos() + 6.0 * ((n0 + 2) as f64 * PI * t).cos());
    let (g_race, g_lim) = (grid(&|t| prof(t).powi(2), 0.0, 1.0, 20 * (n0 + 2)), grid(&|t| 2.0 * (a1 * (PI * t).cos() + a2 * (2.0 * PI * t).cos()).powi(2), 0.0, 1.0, 2000));
    println!("  RMS on a grid: race {} {:.4} (Pythagoras {:.4}), limit {:.4} (Pythagoras {:.4})", n0, g_race.sqrt(), rc.rms(n0), g_lim.sqrt(), limrms);
    assert!((g_race - rc.rms(n0).powi(2)).abs() < 1e-9 && (g_lim - limrms.powi(2)).abs() < 1e-9); // sizes, two roads
    let lost = rc.rms(tail[999]).powi(2) - limrms.powi(2);
    println!("  lost energy at tail 1000: {:.4} - {:.4} = {:.4} (s/km)^2; swap energy 6^2 = 36; peak of swaps {:.4}",
             rc.rms(tail[999]).powi(2), limrms.powi(2), lost, 6.0 * r2);

    // 5. Mazur: averages of the swap parts converge in norm.  RMS of (6/N)(c_3 + ... + c_(N+2)).
    println!("Mazur average of N swap parts: N | RMS by Parseval | RMS by grid");
    for nn in [1usize, 4, 16, 100] {
        let par = 6.0 / (nn as f64).sqrt();
        let avg = move |t: f64| {
            let mut s = 0.0;
            for k in 3..nn + 3 { s += r2 * (k as f64 * PI * t).cos(); }
            (6.0 / nn as f64 * s).powi(2)
        };
        let g = grid(&avg, 0.0, 1.0, 4000).sqrt();
        println!("  {:3} | {:.4} | {:.4}", nn, par, g);
        assert!((par - g).abs() < 1e-9);
    }

    // 6. Weak-star in the dual of C[0, 1]: averages over [0.4, 0.4 + 1/n] tend to the reading at 0.4.
    let p = move |t: f64| 240.0 + 6.0 * r2 * (PI * t).cos();
    let pp = move |t: f64| 240.0 * t + 6.0 * r2 * (PI * t).sin() / PI; // antiderivative of p
    println!("pace p(t) = 240 + 6 sqrt2 cos(pi t); reading at the 4 km mark p(0.4) = {:.4} s/km", p(0.4));
    for n in [10usize, 100, 1000] {
        let w = 1.0 / n as f64;
        let (exact, g) = (n as f64 * (pp(0.4 + w) - pp(0.4)), n as f64 * grid(&p, 0.4, 0.4 + w, 1000));
        println!("  window 1/{:<4} of the race: average {:.4} (grid {:.4}), gap {:.4}", n, exact, g, (exact - p(0.4)).abs());
        assert!((exact - g).abs() < 1e-8 && (exact - p(0.4)).abs() <= 6.0 * r2 * PI / (2.0 * n as f64));
    }

    // 7. No countable dense set: coordinate readings on l-infinity, against a list built
    //    to alternate on any chosen subsequence (here 2, 5, 9, 14, 20, 27).
    let chosen = [2usize, 5, 9, 14, 20, 27];
    let xinf: Vec<i32> = (0..chosen.len()).map(|k| if k % 2 == 0 { 1 } else { -1 }).collect();
    println!("l-infinity readings on the chosen subsequence: {}",
             xinf.iter().map(|v| v.to_string()).collect::<Vec<_>>().join(", "));

    let (b8, p8, _) = rc.diagonal(8);
    println!("try: 8 halvings each: last pick {}, limit {:.4} c_1 {:+.4} c_2, races in both boxes {}",
             p8.last().unwrap(), (b8[0][0] + b8[0][1]) / 2.0, (b8[1][0] + b8[1][1]) / 2.0,
             (1..=M).filter(|&n| rc.inside(n, &b8, 1)).count());
    println!("try: swap 6 c_m at m = 10, 20, 30: |km-1 split| {:.4}, {:.4}, {:.4}",
             (6.0 * split1(10)).abs(), (6.0 * split1(20)).abs(), (6.0 * split1(30)).abs());
    println!("try: unbounded start term 6m c_1, m = 1, 10, 100: km-1 split {:.3}, {:.3}, {:.3}",
             6.0 * split1(1), 60.0 * split1(1), 600.0 * split1(1));

    assert!((inbox.len() as f64 - M as f64 * law).abs() < 4.0 * (M as f64 * law).sqrt()); // two roads
    assert!(picks.iter().zip(&steps).all(|(&n, &(c, [lo, hi]))| lo <= rc.val(c, n) && rc.val(c, n) <= hi));
    assert!(picks.windows(2).all(|w| w[0] < w[1]));
    assert!((bx[0][1] - bx[0][0] - 12.0 / 64.0).abs() < 1e-12 && (bx[1][1] - bx[1][0] - 8.0 / 64.0).abs() < 1e-12);
    assert!((lost - 36.0).abs() < 1.0 && limrms < rc.rms(tail[999])); // energy lost, about the swaps' 36
    let s8 = &rc.start[..8];
    assert!(s8.iter().cloned().fold(f64::MIN, f64::max) - s8.iter().cloned().fold(f64::MAX, f64::min) > 10.0);
    println!("ALL CHECKS PASS");
}
