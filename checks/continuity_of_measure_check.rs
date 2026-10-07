// Continuity and subadditivity -- the same check as the Python, in Rust, no
// crates.  Exact arithmetic by hand: every length and area is a whole number
// of 2^-20 units (km or km^2), so nothing is rounded.
// Road 1: add disjoint layers, as the proof does.  Road 2: count grid cells
// 1/32 km on a side whose centres lie in the set; it never sees a layer.
// Road 3, for the flood and the reservoir: the closed-form geometric sums.
// The code checks finite stages exactly; only the proof covers every stage.
const D: i64 = 1 << 20; // one km, or one km^2, in 2^-20 units

fn show(x: i64) -> String {              // 5 not 5.0; exact dyadics as decimals
    if x % D == 0 { format!("{}", x / D) } else { format!("{}", x as f64 / D as f64) }
}

fn cells(inside: &dyn Fn(i64, i64) -> bool) -> i64 { // road 2: grid 2 km across, 5 km along
    let mut hits = 0;
    for i in 0..64 { for j in 0..160 { if inside(2 * i + 1, 2 * j + 1) { hits += 1 } } }
    hits * (D / 1024)                     // each cell is (1/32 km)^2
}

fn inr(r: (i64, i64, i64, i64), cx: i64, cy: i64) -> bool { // closed rectangle, centres in 1/64 km
    64 * r.0 <= cx * D && cx * D <= 64 * r.1 && 64 * r.2 <= cy * D && cy * D <= 64 * r.3
}

fn edge(n: u32) -> i64 { 2 * D - ((2 * D) >> n) } // flood edge after stage n, km from the bank
fn wet(n: u32) -> i64 { D + ((2 * D) >> n) }      // reservoir wet width on day n, km
fn dash(g: Option<i64>) -> String { g.map_or("-".to_string(), show) }

fn main() {
    println!("flood, stage n: edge km | area by layers | 10 - 10/2^n | by cells | short of 10");
    let mut flood = Vec::new();
    for n in 1..=10u32 {
        let by_layers: i64 = (1..=n).map(|j| 5 * (edge(j) - edge(j - 1))).sum();
        let closed = 10 * D - ((10 * D) >> n);
        let grid = if n <= 6 { Some(cells(&|cx, cy| inr((0, edge(n), 0, 5 * D), cx, cy))) } else { None };
        assert_eq!(by_layers, closed);                 // layers against the geometric sum
        assert!(grid.map_or(true, |g| g == by_layers)); // layers against counted cells
        flood.push(by_layers);
        println!("flood, stage {}: {} | {} | {} | {} | {}", n, show(edge(n)), show(by_layers),
                 show(closed), dash(grid), show(10 * D - by_layers));
    }
    let union = cells(&|cx, cy| (1..=20u32).any(|n| inr((0, edge(n), 0, 5 * D), cx, cy)));
    assert_eq!(union, 10 * D);                         // cells under some stage 1 to 20: the union
    assert!(100 * (10 * D - flood[9]) < D);            // stage 10 is within 0.01 of the union
    println!("flood, union of stages 1 to 20 (the strip short of 2 km), by cells: {}", show(union));

    let band = cells(&|cx, cy| inr((0, edge(3), 0, 5 * D), cx, cy) && !inr((0, edge(2), 0, 5 * D), cx, cy));
    assert_eq!(band, flood[2] - flood[1]);             // monotonicity: mu(B) = mu(A) + mu(B minus A)
    println!("monotone: stage 2 inside stage 3, {} <= {}; band between, by cells: {}",
             show(flood[1]), show(flood[2]), show(band));

    println!("survey, flight k: km along | patch area | new piece | union by pieces | union by cells | sum of areas");
    let (mut s, mut l, mut covered, mut by_pieces, mut total) = (0i64, 2 * D, 0i64, 0i64, 0i64);
    let mut rects: Vec<(i64, i64, i64, i64)> = Vec::new();
    for k in 1..=20u32 {
        rects.push((0, 2 * D, s, s + l));
        let new = 2 * (s + l - s.max(covered)).max(0);  // B_k: patch k minus all earlier patches
        covered = covered.max(s + l);
        by_pieces += new;
        total += 2 * l;
        assert!(by_pieces == 6 * D - ((4 * D) >> k) && total == 8 * D - ((8 * D) >> k));
        if k <= 6 {
            let grid = cells(&|cx, cy| rects.iter().any(|&r| inr(r, cx, cy)));
            assert_eq!(grid, by_pieces);               // new pieces against counted cells
            println!("survey, flight {}: {} to {} | {} | {} | {} | {} | {}", k, show(s), show(s + l),
                     show(2 * l), show(new), show(by_pieces), show(grid), show(total));
        }
        s += 3 * l / 4;
        l /= 2;
    }
    println!("survey, after 20 flights: union {}; sum {}; overlap {}", show(by_pieces), show(total),
             show(total - by_pieces));
    println!("survey, closed forms held for k = 1 to 20: union 6 - 4/2^k, limit 6; sum 8 - 8/2^k, limit 8; overlap 2");

    println!("reservoir, day n: wet width km | 6 - dried layers | 3 + 6/2^n | by cells | above 3");
    let mut res = Vec::new();
    for n in 1..=10u32 {
        let dried: i64 = (2..=n).map(|j| 3 * (wet(j - 1) - wet(j))).sum(); // F_1 minus F_n, by layers
        let closed = 3 * D + ((6 * D) >> n);
        let grid = if n <= 6 { Some(cells(&|cx, cy| inr((0, wet(n), 0, 3 * D), cx, cy))) } else { None };
        assert_eq!(6 * D - dried, closed);
        assert!(grid.map_or(true, |g| g == closed));
        res.push(closed);
        println!("reservoir, day {}: {} | {} | {} | {} | {}", n, show(wet(n)), show(6 * D - dried),
                 show(closed), dash(grid), show(closed - 3 * D));
    }
    let pool = cells(&|cx, cy| (1..=20u32).all(|n| inr((0, wet(n), 0, 3 * D), cx, cy)));
    assert_eq!(pool, 3 * D);
    println!("reservoir, wet on every day 1 to 20 (the pool that never dries), by cells: {}", show(pool));

    for big_n in [1000i64, 100000] {
        let counts: Vec<i64> = [1i64, 10, 100].iter().map(|&n| (1..=big_n).filter(|&m| m >= n).count() as i64).collect();
        assert_eq!(counts, vec![big_n, big_n - 9, big_n - 99]);
        println!("tails, counting measure of {{n, n+1, ...}} seen up to {}: n=1: {}, n=10: {}, n=100: {}",
                 big_n, counts[0], counts[1], counts[2]);
        let lengths: Vec<i64> = [1i64, 10, 100].iter().map(|&n| (n..big_n).count() as i64).collect(); // unit pieces
        assert_eq!(lengths, vec![big_n - 1, big_n - 10, big_n - 100]);
        println!("tails, length of [n, {}] from unit pieces: n=1: {}, n=10: {}, n=100: {}",
                 big_n, lengths[0], lengths[1], lengths[2]);
    }
    let survivors: Vec<i64> = (1..=1000i64).filter(|&m| (1..=1001i64).all(|n| m >= n)).collect();
    assert!(survivors.is_empty());
    println!("tails, numbers 1 to 1000 lying in every tail: {}", survivors.len());

    let (near, far) = ((0, D, 0, 5 * D), (D, 2 * D, 0, 5 * D)); // bands 0 to 1 km and 1 to 2 km from the bank
    let halves = [cells(&|cx, cy| inr(near, cx, cy)), cells(&|cx, cy| inr(far, cx, cy)),
                  cells(&|cx, cy| inr(near, cx, cy) || inr(far, cx, cy)),
                  cells(&|cx, cy| inr(near, cx, cy) && inr(far, cx, cy))];
    assert_eq!(halves, [5 * D, 5 * D, 10 * D, 0]);
    println!("not nested, band 0 to 1 km then band 1 to 2 km from the bank: each {} and {}; union {}; common part {}",
             show(halves[0]), show(halves[1]), show(halves[2]), show(halves[3]));

    let px: Vec<String> = (1..=4u32).map(|n| show(200 * D - 60 * edge(n))).collect();
    println!("figure, flood edge y-pixels, stages 1-4: {} | limit 80 | bank 200 | plain x 30 to 330", px.join(" "));
    let f2 = |v: &[i64]| v[..8].iter().map(|&a| format!("{:.2}", a as f64 / D as f64)).collect::<Vec<_>>().join(" ");
    println!("chart, flooded area km^2: {}", f2(&flood));
    println!("chart, reservoir wet area km^2: {}", f2(&res));
    println!("ALL CHECKS PASS");
}
