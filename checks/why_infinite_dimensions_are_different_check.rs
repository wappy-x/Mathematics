// Infinite dimensions -- the same check as the Python, in Rust.  No crates.
// A spike e_n is a price record that is 1 GBP/MWh at hour n and 0 at every
// other hour.  Every infinite object here is a truncation: a record cut to N
// hours, shown at several N.  Only the proofs on the card cover N = infinity.

fn norm(v: &[f64], p: i32) -> f64 {           // l1, l2 or sup size of a finite list
    if p == 0 {                                // p = 0 stands for the sup size here
        return v.iter().fold(0.0, |m: f64, a| m.max(a.abs()));
    }
    v.iter().map(|a| a.abs().powi(p)).sum::<f64>().powf(1.0 / p as f64)
}

fn spike(n: usize, size: usize) -> Vec<f64> {  // e_n cut to `size` hours, n counts from 1
    (1..=size).map(|k| if k == n { 1.0 } else { 0.0 }).collect()
}

fn minus(u: &[f64], v: &[f64]) -> Vec<f64> {
    u.iter().zip(v).map(|(a, b)| a - b).collect()
}

fn dist_to_line(v: (f64, f64)) -> (f64, f64) { // road one: search t on a grid of 0.0001
    let (mut best, mut best_t) = (9.0_f64, 0.0_f64);
    for k in -30000..=30000 {
        let t = k as f64 / 10000.0;
        let size = (v.0 - t).abs().max((v.1 - t).abs());
        if size < best { best = size; best_t = t; }
    }
    (best, best_t)
}

fn main() {
    // 1. Two spikes, three size rules.
    let (a, b) = (spike(3, 10), spike(7, 10));
    let (d1, d2, dsup) = (norm(&minus(&a, &b), 1), norm(&minus(&a, &b), 2), norm(&minus(&a, &b), 0));
    println!("distance from e_3 to e_7: l1 {:.6}, l2 {:.6}, sup {:.6}", d1, d2, dsup);
    assert!((d1 - 2.0).abs() < 1e-12 && (d2 - 2f64.sqrt()).abs() < 1e-12 && (dsup - 1.0).abs() < 1e-12);

    // 2. Spikes at every hour of a record of N hours: closest pair, and a greedy
    //    cover by balls of radius 1/2 (a ball holds a spike within 1/2 of its centre).
    for size in [10usize, 100, 168] {
        let spikes: Vec<Vec<f64>> = (1..=size).map(|n| spike(n, size)).collect();
        let mut closest = f64::INFINITY;
        for i in 0..size {
            for j in i + 1..size { closest = closest.min(norm(&minus(&spikes[i], &spikes[j]), 2)); }
        }
        let mut centres: Vec<&Vec<f64>> = Vec::new();
        for s in &spikes {
            if centres.iter().all(|c| norm(&minus(s, c), 2) > 0.5) { centres.push(s); }
        }
        println!("N = {:3} hours: closest pair of spikes {:.6}, balls of radius 1/2 needed {}",
                 size, closest, centres.len());
        assert!((closest - 2f64.sqrt()).abs() < 1e-12 && centres.len() == size);
    }
    let week: Vec<Vec<f64>> = (1..170usize).map(|k| spike((k - 1) % 168 + 1, 168)).collect();
    println!("spike number 169 in a 168-hour week sits at hour {}; distance to spike 1: {:.6}",
             (169 - 1) % 168 + 1, norm(&minus(&week[168], &week[0]), 2));
    println!("volume bound on points of the 168-hour ball that are sqrt 2 apart: 10^{:.2}",
             168.0 * (1.0 + 2f64.sqrt()).log10());

    // 3. Riesz's recipe in the plane under the sup size.  M = all multiples t(1, 1).
    let z = (1.0_f64, 0.0_f64);
    let (dz, tz) = dist_to_line(z);
    let w = (z.0 - tz, z.1 - tz);
    let wsize = w.0.abs().max(w.1.abs());
    let x = (w.0 / wsize, w.1 / wsize);
    let (dx, tx) = dist_to_line(x);
    println!("z = ({:.4}, {:.4}): distance to M {:.4}, nearest point t = {:.4}", z.0, z.1, dz, tz);
    println!("x = (z - m0) / size = ({:.4}, {:.4}): size {:.4}, distance to M {:.4}, nearest t = {:.4}",
             x.0, x.1, x.0.abs().max(x.1.abs()), dx, tx);
    for (v, dv) in [(z, dz), (x, dx)] {        // road two: the closed form |a - b| / 2
        assert!((dv - (v.0 - v.1).abs() / 2.0).abs() < 1e-9);
    }

    // 4. y = (1, 1/2, 1/3, ...) written in the spikes.  Error after N terms is the
    //    tail sqrt(sum over n > N of 1/n^2).  Road A: pi^2/6 minus the partial sum.
    //    Road B: sum the tail up to 10^6 directly, plus the Euler-Maclaurin rest.
    let total = std::f64::consts::PI.powi(2) / 6.0;
    println!("size of y squared, pi^2/6 = {:.6}; size of y {:.6}", total, total.sqrt());
    let big: u64 = 1_000_000;
    let bf = big as f64;
    let rest = 1.0 / bf - 1.0 / (2.0 * bf * bf) + 1.0 / (6.0 * bf * bf * bf);
    for n_terms in [1u64, 10, 100, 1000, 10000] {
        let partial: f64 = (1..=n_terms).map(|n| 1.0 / (n as f64).powi(2)).sum();
        let road_a = (total - partial).sqrt();
        let tail: f64 = (n_terms + 1..=big).rev().map(|n| 1.0 / (n as f64).powi(2)).sum();
        let road_b = (tail + rest).sqrt();
        println!("N = {:5}: error {:.7} (direct tail {:.7}), log10 N {:.0}, log10 error {:.3}",
                 n_terms, road_a, road_b, (n_terms as f64).log10(), road_a.log10());
        assert!((road_a - road_b).abs() < 1e-9);
        let nf = n_terms as f64;
        assert!(1.0 / (nf + 1.0) < road_a * road_a && road_a * road_a < 1.0 / nf);
    }
    println!("the coefficient of e_n is y_n: y_1 = {:.4}, y_10 = {:.4}, y_100 = {:.4}, y_1000 = {:.4}",
             1.0, 1.0 / 10.0, 1.0 / 100.0, 1.0 / 1000.0);

    // 5. The sup size.  Partial sums of spikes never close in on the all-ones record,
    //    and the records of 0s and 1s are 2^N points, every two exactly 1 apart.
    for n_terms in [10usize, 100, 1000] {
        let ones = vec![1.0; 2 * n_terms];
        let partial: Vec<f64> = (1..=2 * n_terms).map(|k| if k <= n_terms { 1.0 } else { 0.0 }).collect();
        let gap = norm(&minus(&ones, &partial), 0);
        println!("all-ones record, sup size, N = {:4}: error {:.6}", n_terms, gap);
        assert!(gap == 1.0);
    }
    for size in [4usize, 8, 10] {               // greedy cover by balls of radius 1/2, as in 2.
        let records: Vec<Vec<f64>> = (0..1usize << size)
            .map(|k| (0..size).map(|h| ((k >> h) & 1) as f64).collect()).collect();
        let (mut centres, mut closest): (Vec<&Vec<f64>>, f64) = (Vec::new(), 9.0);
        for r in &records {
            let gaps: Vec<f64> = centres.iter().map(|c| norm(&minus(r, c), 0)).collect();
            closest = gaps.iter().fold(closest, |m, &g| m.min(g));
            if gaps.iter().all(|&g| g > 0.5) { centres.push(r); }
        }
        println!("N = {:2} hours: {:4} records of 0s and 1s, closest pair {:.6} (sup size), balls of radius 1/2 needed {}",
                 size, records.len(), closest, centres.len());
        assert!(closest == 1.0 && centres.len() == 1 << size);
    }

    // 6. Buy 1 MWh, split over hours, at 50 + 10/n GBP/MWh in hour n (illustrative).
    //    Road one: search every hour.  Road two: the last hour is cheapest.  A plan
    //    spread evenly over the hours costs the average price, more than the best.
    for size in [168usize, 1000, 10000] {
        let prices: Vec<f64> = (1..=size).map(|n| 50.0 + 10.0 / n as f64).collect();
        let best = (0..size).fold(0, |b, k| if prices[k] < prices[b] { k } else { b });
        println!("buy 1 MWh within N = {:5} hours: best hour {}, cost {:.6} GBP", size, best + 1, prices[best]);
        let spread = prices.iter().sum::<f64>() / size as f64;
        assert!(best + 1 == size && spread > prices[best] && prices[best] > 50.0);
    }
    println!("ALL CHECKS PASS");
}
