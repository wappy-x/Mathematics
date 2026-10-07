// Callable swap = plain swap + Bermudan swaption -- the check behind the card.
// Rust std only: the tree, its fitting, the root finder and the path
// enumeration are all written out here.  Money in dollars, rates as decimals.
const N: f64 = 10_000_000.0;
const K0: f64 = 0.05;
const Y: f64 = 0.05;
const SIG: f64 = 0.20;
const YEARS: usize = 10;
fn is_call(i: usize) -> bool { (2..10).contains(&i) } // cancel just after the coupon of years 2..9

fn bisect(f: &dyn Fn(f64) -> f64, mut lo: f64, mut hi: f64) -> f64 {
    let flo = f(lo);
    for _ in 0..200 {
        let mid = 0.5 * (lo + hi);
        if (f(mid) > 0.0) == (flo > 0.0) { lo = mid } else { hi = mid }
    }
    0.5 * (lo + hi)
}

// Black-Derman-Toy: one-year rate at year i, node j is a_i*exp(2*sig*j); a_i reprices (1+y)^-(i+1).
fn tree(y: f64, sig: f64) -> Vec<Vec<f64>> {
    let (mut r, mut q): (Vec<Vec<f64>>, Vec<f64>) = (vec![], vec![1.0]);
    for i in 0..YEARS {
        let target = (1.0 + y).powf(-((i + 1) as f64));
        let qc = q.clone();
        let f = move |a: f64| qc.iter().enumerate().map(|(j, x)| x / (1.0 + a * (2.0 * sig * j as f64).exp())).sum::<f64>() - target;
        let a = bisect(&f, 1e-6, 1.0);
        r.push((0..=i).map(|j| a * (2.0 * sig * j as f64).exp()).collect());
        let mut nq = vec![0.0; i + 2];
        for (j, x) in q.iter().enumerate() {
            nq[j] += 0.5 * x / (1.0 + r[i][j]);
            nq[j + 1] += 0.5 * x / (1.0 + r[i][j]);
        }
        q = nq;
    }
    r
}

fn marks(r: &[Vec<f64>], k: f64) -> Vec<Vec<f64>> {
    let mut m = vec![vec![0.0; YEARS + 1]; YEARS + 1];
    for i in (0..YEARS).rev() {
        m[i] = (0..=i).map(|j| (N * (r[i][j] - k) + 0.5 * (m[i + 1][j] + m[i + 1][j + 1])) / (1.0 + r[i][j])).collect();
    }
    m
}

fn bermudan(r: &[Vec<f64>], m: &[Vec<f64>], sign: f64, dates: &dyn Fn(usize) -> bool) -> (f64, Vec<Vec<bool>>) {
    let mut b = vec![0.0; YEARS + 1];
    let mut stop = vec![vec![false; YEARS + 1]; YEARS + 1];
    for i in (0..YEARS).rev() {
        let mut new = vec![];
        for j in 0..=i {
            let cont = 0.5 * (b[j] + b[j + 1]) / (1.0 + r[i][j]);
            let reward = if dates(i) { (sign * m[i][j]).max(0.0) } else { 0.0 };
            stop[i][j] = reward > cont;
            new.push(reward.max(cont));
        }
        b = new;
    }
    (b[0], stop)
}

fn direct(r: &[Vec<f64>], k: f64, side: f64) -> f64 {
    let mut w = vec![0.0; YEARS + 1];
    for i in (0..YEARS).rev() {
        w = (0..=i).map(|j| {
            let x = (N * (r[i][j] - k) + 0.5 * (w[j] + w[j + 1])) / (1.0 + r[i][j]);
            if !is_call(i) { x } else if side > 0.0 { x.max(0.0) } else { x.min(0.0) }
        }).collect();
    }
    w[0]
}

fn ledger(r: &[Vec<f64>], k: f64, stop: &dyn Fn(usize, usize) -> bool) -> (f64, Vec<f64>) {
    let (mut total, mut when) = (0.0, vec![0.0; YEARS + 1]);
    for bits in 0..(1usize << 9) {
        let (mut j, mut df, mut pv) = (0usize, 1.0, 0.0);
        for y in 1..=YEARS {
            df /= 1.0 + r[y - 1][j];
            pv += N * (r[y - 1][j] - k) * df;
            if y < YEARS { j += (bits >> (y - 1)) & 1; }
            if is_call(y) && stop(y, j) { when[y] += 1.0 / 512.0; break; }
        }
        total += pv / 512.0;
    }
    (total, when)
}

fn closed_swap(y: f64, k: f64, n: usize) -> f64 {
    let p: Vec<f64> = (1..=n).map(|t| (1.0 + y).powf(-(t as f64))).collect();
    N * (1.0 - p[n - 1] - k * p.iter().sum::<f64>())
}

fn c2(x: f64) -> f64 { if x.abs() < 0.005 { 0.0 } else { x } }

fn price(y: f64, sig: f64, k: f64) -> (Vec<Vec<f64>>, Vec<Vec<f64>>, f64, (f64, Vec<Vec<bool>>), (f64, Vec<Vec<bool>>)) {
    let r = tree(y, sig);
    let m = marks(&r, k);
    let (br, bp) = (bermudan(&r, &m, -1.0, &is_call), bermudan(&r, &m, 1.0, &is_call));
    let s = m[0][0];
    (r, m, s, br, bp)
}

fn main() {
    let (r, m, swap, (b_r, stop_r), (b_p, _)) = price(Y, SIG, K0);
    let (holder, bank) = (direct(&r, K0, 1.0), direct(&r, K0, -1.0));
    let (path_holder, when) = ledger(&r, K0, &|y, j| stop_r[y][j]);
    let (path_greedy, _) = ledger(&r, K0, &|y, j| m[y][j] < 0.0);
    let euro: Vec<f64> = (2..10).map(|e| bermudan(&r, &m, -1.0, &move |i| i == e).0).collect();
    let k_hold = bisect(&|k| direct(&tree(Y, SIG), k, 1.0), 0.05, 0.08);
    let k_bank = bisect(&|k| direct(&tree(Y, SIG), k, -1.0), 0.02, 0.05);
    let rk = tree(Y, SIG);
    let (up, dn) = (price(Y + 1e-4, SIG, K0), price(Y - 1e-4, SIG, K0));
    let (d_swap, d_rec) = ((up.2 - dn.2) / 2.0, ((up.3).0 - (dn.3).0) / 2.0);
    let vega = ((price(Y, SIG + 0.01, K0).3).0 - (price(Y, SIG - 0.01, K0).3).0) / 2.0;
    let ann: f64 = (1..=YEARS).map(|t| (1.0 + Y).powf(-(t as f64))).sum(); // $1 a year for 10 years, today
    let k_naive = K0 + b_r / (N * ann); // premium spread evenly over the annuity
    let emax = euro.iter().cloned().fold(f64::MIN, f64::max);
    let esum: f64 = euro.iter().sum();
    let swap_k = marks(&rk, k_hold)[0][0];
    let rows: Vec<(&str, f64)> = vec![
        ("tree rate year 0 %", 100.0 * r[0][0]), ("tree rate year 2, lowest node %", 100.0 * r[2][0]), ("tree rate year 2, highest node %", 100.0 * r[2][2]),
        ("curve: 1 - P(0,10)", 1.0 - (1.0 + Y).powf(-(YEARS as f64))), ("curve: annuity", ann),
        ("year 2 low node: remaining swap", m[2][0]),
        ("1 plain swap, tree", c2(swap)), ("1 plain swap, curve", c2(closed_swap(Y, K0, YEARS))),
        ("1 receiver Bermudan B_R", b_r), ("1 swap + B_R", swap + b_r),
        ("2 callable, rolled directly", holder), ("3 callable, 512 paths", path_holder),
        ("1 payer Bermudan B_P", b_p), ("1 swap - B_P", swap - b_p), ("2 bank-cancellable, rolled", bank),
        ("max European (one date)", emax), ("sum of Europeans", esum),
        ("wrong: European year 2 only", euro[0]), ("wrong: cancel when mark < 0", path_greedy),
        ("breakeven fixed, holder cancels %", 100.0 * k_hold), ("breakeven fixed, bank cancels %", 100.0 * k_bank),
        ("naive breakeven, premium / annuity %", 100.0 * k_naive), ("callable at naive breakeven", direct(&rk, k_naive, 1.0)),
        ("swap at holder breakeven, tree", swap_k), ("swap at holder breakeven, curve", closed_swap(Y, k_hold, YEARS)),
        ("rate delta per bp: swap", d_swap), ("rate delta per bp: B_R", d_rec), ("rate delta per bp: callable", d_swap + d_rec),
        ("vega per vol point: B_R = callable", vega),
    ];
    for (name, v) in &rows { println!("{:<36} {:>16.4}", name, v); }
    println!("\nyear  European B_R  cancel at rates up to %  chance cancelled then");
    for (idx, e) in (2..10).enumerate() {
        let edge = (0..=e).filter(|&j| stop_r[e][j]).map(|j| r[e][j]).fold(0.0, f64::max);
        println!("{:>4} {:>14.2} {:>18.4} {:>21.4}", e, euro[idx], 100.0 * edge, when[e]);
    }
    println!("never cancelled {:.4}", 1.0 - when.iter().sum::<f64>());
    println!("\npayoff at year 2, $ thousands: flat rate %, remaining swap, with cancel right");
    for yy in 2..9 {
        let mm = c2(closed_swap(yy as f64 / 100.0, K0, 8) / 1000.0);
        println!("{:>4} {:>14.2} {:>14.2}", yy, mm, mm.max(0.0));
    }
    assert!((holder - (swap + b_r)).abs() < 1e-6 * N, "decomposition, holder side");
    assert!((bank - (swap - b_p)).abs() < 1e-6 * N, "decomposition, bank side");
    assert!((path_holder - holder).abs() < 1e-6 * N, "path ledger vs rollback");
    assert!((swap_k - closed_swap(Y, k_hold, YEARS)).abs() < 1e-4, "tree vs curve");
    assert!(emax <= b_r && b_r <= esum, "Bermudan between best European and all Europeans");
    assert!(path_greedy < holder, "greedy exercise must lose value");
    assert!(direct(&rk, k_hold, 1.0).abs() < 1e-2, "holder break-even is a root");
    assert!(direct(&rk, k_bank, -1.0).abs() < 1e-2, "bank break-even is a root");
    println!("all checks passed");
}
