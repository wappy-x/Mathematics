// Two goals at once: Pareto optimality and the frontier of trade-offs -- the check behind the card.
// std only. Five funds, treated as uncorrelated, no short sales.
// Risk is the variance in percent squared; return is in percent a year.
const NAME: [&str; 5] = ["gilt", "corp bond", "property", "UK equity", "emerging"];
const MU: [f64; 5] = [3.0, 4.0, 5.0, 6.5, 9.0];
const SD: [f64; 5] = [5.0, 8.0, 14.0, 16.0, 25.0];
const N: usize = 5;

fn var() -> [f64; 5] { let mut v = [0.0; 5]; for i in 0..N { v[i] = SD[i] * SD[i]; } v }

fn stats(x: &[f64; 5]) -> (f64, f64) {
    let v = var();
    let (mut a, mut b) = (0.0, 0.0);
    for i in 0..N { a += v[i] * x[i] * x[i]; }
    for i in 0..N { b += MU[i] * x[i]; }
    (a, b)
}

// Road 1: minimise variance - tau * return over every set of funds held (31 sets);
// keep the one whose KKT conditions hold: weights >= 0 and no fund left out wants in.
fn weighted(tau: f64, longonly: bool) -> ([f64; 5], f64, [f64; 5]) {
    let v = var();
    for mask in 1..(1usize << N) {
        let on: Vec<usize> = (0..N).filter(|i| mask >> i & 1 == 1).collect();
        if !longonly && on.len() < N { continue; }
        let (mut top, mut bot) = (0.0, 0.0);
        for &i in &on { top += tau * MU[i] / (2.0 * v[i]); }
        for &i in &on { bot += 1.0 / (2.0 * v[i]); }
        let nu = (top - 1.0) / bot;
        let (mut x, mut lam) = ([0.0; 5], [0.0; 5]);
        for i in 0..N {
            if on.contains(&i) { x[i] = (tau * MU[i] - nu) / (2.0 * v[i]); } else { lam[i] = nu - tau * MU[i]; }
        }
        let ok = x.iter().all(|&a| a >= -1e-12) && lam.iter().all(|&a| a >= -1e-12);
        if !longonly || ok { return (x, nu, lam); }
    }
    unreachable!()
}

fn pct(x: &[f64; 5]) -> String { x.iter().map(|a| format!("{:6.2}", 100.0 * a)).collect::<Vec<_>>().join(" ") }

fn for_return(m: f64) -> f64 { // bisection on tau until the weighted answer returns m
    let (mut lo, mut hi) = (0.0, 500.0);
    for _ in 0..100 {
        let mid = (lo + hi) / 2.0;
        if stats(&weighted(mid, true).0).1 < m { lo = mid; } else { hi = mid; }
    }
    lo
}

fn main() {
    let v = var();
    // ---- eleven frontier portfolios, tau = 0, 10, ..., 100 ----
    let mut front = Vec::new();
    println!("tau  weights % (gilt corp prop UKeq emer)   return  var     sd");
    for k in 0..11 {
        let t = 10.0 * k as f64;
        let (x, nu, lam) = weighted(t, true);
        let (fv, fr) = stats(&x);
        println!("{:3} {}  {:6.3} {:7.2} {:6.3}", 10 * k, pct(&x), fr, fv, fv.sqrt());
        let sc = |i: usize, s: f64| { let mut z = x; z[i] += s; let (a, b) = stats(&z); a - t * b };
        let resid = (0..N).map(|i| ((sc(i, 1e-4) - sc(i, -1e-4)) / 2e-4 + nu - lam[i]).abs()).fold(0.0, f64::max); // score's slope, measured
        assert!(resid < 1e-6 && lam.iter().all(|&a| a >= -1e-12)); // KKT certificate: slopes balance, no fund left out wants in
        front.push((t, x, fv, fr, nu, lam));
    }
    let (_, _, fv, fr, nu, lam) = front[5];
    let (mut top, mut bot) = (0.0, 0.0);
    for i in 1..N { top += 50.0 * MU[i] / (2.0 * v[i]); }
    for i in 1..N { bot += 1.0 / (2.0 * v[i]); }
    println!("tau 50 by hand: sums {:.4} and {:.6}, nu {:.2}, gilt multiplier {:.2}, objective {:.3}", top, bot, nu, lam[0], fv - 50.0 * fr);

    // ---- road 2: every portfolio on a 2% grid (316,251 of them) ----
    let mut grid = Vec::new();
    for a in 0..51 { for b in 0..51 { for c in 0..51 { for d in 0..51 {
        let s = a + b + c + d;
        if s <= 50 {
            let x = [a as f64 / 50.0, b as f64 / 50.0, c as f64 / 50.0, d as f64 / 50.0, (50 - s) as f64 / 50.0];
            grid.push(stats(&x));
        }
    }}}}
    let (mut worst_gap, mut dominators) = (0.0f64, 0usize);
    for &(t, _, fv, fr, _, _) in &front {
        let best = grid.iter().map(|&(gv, gr)| gv - t * gr).fold(f64::INFINITY, f64::min);
        assert!(best >= fv - t * fr - 1e-9); // no grid portfolio beats the exact answer
        worst_gap = worst_gap.max(best - (fv - t * fr));
        dominators += grid.iter().filter(|&&(gv, gr)| gv <= fv && gr >= fr && (gv < fv || gr > fr)).count();
    }
    println!("grid portfolios {}, worst grid shortfall {:.4}, grid portfolios dominating a frontier one {}", grid.len(), worst_gap, dominators);
    assert!(grid.len() == 316251 && dominators == 0 && worst_gap < 0.5);
    let top_tau = 2.0 * v[4] / (MU[4] - MU[3]); // from here on, all in emerging markets
    println!("sets of funds tried per solve {}; all emerging from tau {:.1}; tau values in the one-fund sweep 10001", (1 << N) - 1, top_tau);
    assert!((weighted(top_tau, true).0[4] - 1.0).abs() < 1e-12 && weighted(top_tau - 1.0, true).0[4] < 0.999);

    // ---- the weight is the slope: target 6% return by bisection on tau ----
    let t6 = for_return(6.0);
    let (v6, _) = stats(&weighted(t6, true).0);
    let h = 1e-3;
    let slope = (stats(&weighted(for_return(6.0 + h), true).0).0 - stats(&weighted(for_return(6.0 - h), true).0).0) / (2.0 * h);
    let g6 = grid.iter().filter(|p| p.1 >= 6.0).map(|p| p.0).fold(f64::INFINITY, f64::min);
    println!("6% target: tau {:.3}, variance {:.3}, sd {:.3}; frontier slope {:.3}; best 2% grid variance {:.3}", t6, v6, v6.sqrt(), slope, g6);
    assert!((slope - t6).abs() < 1e-3 && v6 <= g6 + 1e-9);

    // ---- the one-fund rule: a dented frontier ----
    let score = |i: usize, t: f64| v[i] - t * MU[i];
    let (mut winners, mut gap, mut at): (Vec<(usize, f64)>, f64, f64) = (Vec::new(), 1e9, 0.0);
    for k in 0..10001 { // tau from 0 to 1000 in steps of 0.1
        let t = k as f64 / 10.0;
        let mut w = 0;
        for i in 1..N { if score(i, t) < score(w, t) { w = i; } }
        if winners.last().map_or(true, |p| p.0 != w) { winners.push((w, t)); }
        let d = score(2, t) - (0..N).filter(|&i| i != 2).map(|i| score(i, t)).fold(f64::INFINITY, f64::min);
        if d < gap { gap = d; at = t; }
    }
    println!("one fund, weighted-sum winners as tau rises: {}", winners.iter().map(|p| NAME[p.0]).collect::<Vec<_>>().join(", "));
    let cuts: Vec<f64> = [(0, 1), (1, 3), (3, 4)].iter().map(|&(a, b)| (v[b] - v[a]) / (MU[b] - MU[a])).collect();
    let th = (MU[3] - MU[2]) / (MU[3] - MU[1]); // average of two funds' points, returning 5%
    let mixv = th * v[1] + (1.0 - th) * v[3];
    println!("switch points {:.1} {:.1} {:.1}; property never wins; closest at tau {:.1}, loses by {:.2}", cuts[0], cuts[1], cuts[2], at, gap);
    println!("{:.0}/{:.0} average of corp bond and UK equity points: return {:.2}, variance {:.2} vs property {:.2}", 100.0 * th, 100.0 * (1.0 - th), MU[2], mixv, v[2]);
    assert!(winners.iter().map(|p| p.0).collect::<Vec<_>>() == vec![0, 1, 3, 4] && (gap - (v[2] - mixv)).abs() < 1e-9);
    assert!(winners[1..].iter().zip(&cuts).all(|(p, c)| (p.1 - c).abs() <= 0.1 + 1e-9));
    let pareto: Vec<usize> = (0..N).filter(|&i| !(0..N).any(|j| v[j] <= v[i] && MU[j] >= MU[i] && j != i)).collect();
    let eps: Vec<usize> = MU.iter().map(|&e| {
        let mut best = (f64::INFINITY, 0);
        for i in 0..N { if MU[i] >= e && v[i] < best.0 { best = (v[i], i); } }
        best.1
    }).collect();
    let names = |s: &Vec<usize>| s.iter().map(|&i| NAME[i]).collect::<Vec<_>>().join(", ");
    println!("Pareto-optimal funds: {} | epsilon-constraint picks: {}", names(&pareto), names(&eps));
    assert!(pareto == eps && pareto == vec![0, 1, 2, 3, 4]);

    // ---- what breaks ----
    let (vb, rb) = stats(&weighted(-10.0, true).0);
    println!("tau -10: return {:.3}, var {:.2}; tau 0 has return {:.3}, var {:.2}", rb, vb, front[0].3, front[0].2);
    assert!(rb < front[0].3 && vb > front[0].2);
    let x = weighted(100.0, false).0;
    println!("shorts allowed, tau 100: {}, return {:.3}, var {:.2}", pct(&x), stats(&x).1, stats(&x).0);
    assert!(x[0] < 0.0);
    let pts: Vec<String> = (0..N).map(|i| format!("({:.0},{:.1})", v[i], MU[i])).collect();
    println!("figure, funds {}, average ({:.1},{:.1})", pts.join(" "), mixv, MU[2]);
    println!("ALL CHECKS PASS");
}
