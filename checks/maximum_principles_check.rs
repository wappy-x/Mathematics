// Maximum principles on a 1 m square steel plate, temperatures as rises above the 20 C room (K).
// Scene 1: top bar 80 K, other bars 0 K, faces cooled (c = 40 per m^2) or insulated (c = 0).
// Scene 2: rim 0 K, heater inside f = 100 K per m^2, bounded by comparison with barriers.
// Roads: sine series, a grid swept to its neighbour average, symmetry, and hand barriers.
use std::f64::consts::PI;
const F: f64 = 5000.0 / 50.0; // f = heat / conductivity
const C: f64 = 2.0 * 10.0 / (50.0 * 0.01); // c = 2 air / (k t)
const TOP: f64 = 80.0;
const N: usize = 40;

fn rim(x: f64, y: f64, c: f64, top: f64) -> f64 { // top bar `top`, others 0: sin(n pi x) sinh(b y)/sinh(b)
    (1..800).step_by(2).map(|n| { let a = n as f64 * PI; let b = (a * a + c).sqrt();
        4.0 * top / a * (a * x).sin() * ((b * (y - 1.0)).exp() - (-b * (y + 1.0)).exp()) / (1.0 - (-2.0 * b).exp())
    }).sum()
}
fn heated(x: f64, y: f64, c: f64) -> f64 { // rim 0, source F: each sine mode in x solved exactly in y
    (1..400).step_by(2).map(|m| { let a = m as f64 * PI; let k = (a * a + c).sqrt();
        4.0 * F / a / (k * k) * (a * x).sin() * (1.0 - ((k * (y - 1.0)).exp() + (-k * y).exp()) / (1.0 + (-k).exp()))
    }).sum()
}
fn cube(nn: usize) -> f64 { // unit cube, rim 0, source F: double sine series at the centre
    let mut s = 0.0;
    for m in (1..nn).step_by(2) { for n in (1..nn).step_by(2) {
        let k = PI * ((m * m + n * n) as f64).sqrt();
        let sign = if ((m + n) / 2 - 1) % 2 == 0 { 1.0 } else { -1.0 };
        s += 16.0 * F / (PI * PI * (m * n) as f64 * k * k) * (1.0 - 2.0 * (-k / 2.0).exp() / (1.0 + (-k).exp())) * sign;
    } }
    s
}
fn relax(n: usize, top: f64, src: f64, c: f64) -> Vec<Vec<f64>> { // u = (neighbours + h^2 src)/(4 + h^2 c)
    let (h, w) = (1.0 / n as f64, 2.0 / (1.0 + (PI / n as f64).sin()));
    let mut u = vec![vec![0.0; n + 1]; n + 1]; // u[i][j] at x = i h, y = j h
    for i in 0..=n { u[i][n] = top; }
    loop {
        let mut big: f64 = 0.0;
        for i in 1..n { for j in 1..n {
            let new = (u[i + 1][j] + u[i - 1][j] + u[i][j + 1] + u[i][j - 1] + h * h * src) / (4.0 + h * h * c);
            big = big.max((new - u[i][j]).abs());
            u[i][j] += w * (new - u[i][j]);
        } }
        if big < 1e-11 { return u; }
    }
}
fn relax3(n: usize) -> f64 { // the cube on a grid: six neighbours
    let (h, w) = (1.0 / n as f64, 2.0 / (1.0 + (PI / n as f64).sin()));
    let mut u = vec![vec![vec![0.0; n + 1]; n + 1]; n + 1];
    loop {
        let mut big: f64 = 0.0;
        for i in 1..n { for j in 1..n { for k in 1..n {
            let new = (u[i + 1][j][k] + u[i - 1][j][k] + u[i][j + 1][k] + u[i][j - 1][k]
                + u[i][j][k + 1] + u[i][j][k - 1] + h * h * F) / 6.0;
            big = big.max((new - u[i][j][k]).abs());
            u[i][j][k] += w * (new - u[i][j][k]);
        } } }
        if big < 1e-11 { return u[n / 2][n / 2][n / 2]; }
    }
}
fn f2(v: &[f64]) -> String { v.iter().map(|t| format!("{:.2}", t)).collect::<Vec<_>>().join(", ") }
fn low(x: f64, y: f64) -> f64 { (F * (0.25 - (x - 0.5).powi(2) - (y - 0.5).powi(2)) / 4.0).max(0.0) } // inner-disc bowl
fn upp(x: f64, _y: f64) -> f64 { F * x * (1.0 - x) / 2.0 } // strip barrier
fn s(x: f64, y: f64) -> f64 { 10.0 * (PI * x).sin() * (PI * y).sin() }

fn main() {
    let (g0, gc, gh) = (relax(N, TOP, 0.0, 0.0), relax(N, TOP, 0.0, C), relax(N, 0.0, F, 0.0));
    let pts: Vec<(usize, usize)> = (1..N).flat_map(|i| (1..N).map(move |j| (i, j))).collect();
    let k10: Vec<f64> = (0..11).map(|k| k as f64 / 10.0).collect();
    println!("setup: c = 2*10/(50*0.01) = {:.2} per m^2; f = 5000/50 = {:.2} K per m^2", C, F);
    println!("scene 1 centre, insulated: four turns 80/4 = {:.4}, series {:.4}, grid {:.4}", TOP / 4.0, rim(0.5, 0.5, 0.0, TOP), g0[20][20]);
    println!("scene 1 centre, cooled c=40: series {:.4}, grid {:.4}", rim(0.5, 0.5, C, TOP), gc[20][20]);
    let line = |c: f64| -> Vec<f64> { (0..11).map(|k| if k < 10 { rim(0.5, k10[k], c, TOP) } else { TOP }).collect() };
    println!("midline x=0.5, y=0,0.1..1, insulated series: {}", f2(&line(0.0)));
    println!("midline x=0.5, y=0,0.1..1, cooled series:    {}", f2(&line(C)));
    println!("midline x=0.5, y=0,0.1..1, cooled grid:      {}", f2(&(0..11).map(|k| gc[20][4 * k]).collect::<Vec<_>>()));
    for (name, g) in [("insulated", &g0), ("cooled", &gc)] {
        let mut b = pts[0];
        for &p in &pts { if g[p.0][p.1] > g[b.0][b.1] { b = p; } }
        let mn = pts.iter().map(|&(i, j)| g[i][j]).fold(f64::MAX, f64::min);
        println!("{} grid: interior max {:.4} at ({:.3}, {:.3}), min {:.4}; rim 0 to 80", name, g[b.0][b.1], b.0 as f64 / N as f64, b.1 as f64 / N as f64, mn);
    }
    let gap = pts.iter().map(|&(i, j)| g0[i][j] - gc[i][j]).fold(f64::MAX, f64::min);
    println!("comparison: insulated minus cooled at every grid point >= 0: {}", if gap >= 0.0 { "yes" } else { "no" });
    let d0 = rim(0.5, 0.5, 0.0, 80.5) - rim(0.5, 0.5, 0.0, TOP);
    let dc = rim(0.5, 0.5, C, 80.5) - rim(0.5, 0.5, C, TOP);
    println!("stability: top bar 80 -> 80.5 moves the centre {:.4} (insulated), {:.4} (cooled), cap 0.5", d0, dc);
    let (p20, p40, pex) = (relax(20, 0.0, F, 0.0)[10][10], gh[20][20], heated(0.5, 0.5, 0.0));
    println!("scene 2 centre: series {:.4}, grid h=1/20 {:.4}, h=1/40 {:.4}, error ratio {:.2}", pex, p20, p40, (pex - p20) / (pex - p40));
    println!("scene 2 first omitted series term at the centre: {:.7}", 4.0 * F / (401.0 * PI).powi(3));
    println!("barriers at the centre: strip 100*0.5*0.5/2 = {:.4}, outer disc 100*(1/2)/4 = {:.4}, inner disc 100*0.25/4 = {:.4}",
             upp(0.5, 0.5), F * 0.5 / 4.0, low(0.5, 0.5));
    println!("midline y=0.5, x=0,0.1..1, lower bowl: {}", f2(&k10.iter().map(|&x| low(x, 0.5)).collect::<Vec<_>>()));
    println!("midline y=0.5, x=0,0.1..1, series:     {}", f2(&k10.iter().map(|&x| heated(x, 0.5, 0.0)).collect::<Vec<_>>()));
    println!("midline y=0.5, x=0,0.1..1, strip:      {}", f2(&k10.iter().map(|&x| upp(x, 0.5)).collect::<Vec<_>>()));
    let nf = N as f64;
    let ok = pts.iter().all(|&(i, j)| low(i as f64 / nf, j as f64 / nf) <= gh[i][j] && gh[i][j] <= upp(i as f64 / nf, j as f64 / nf));
    let ghmax = pts.iter().map(|&(i, j)| gh[i][j]).fold(f64::MIN, f64::max);
    println!("sandwich bowl <= u <= strip at all {} grid points: {}; grid max {:.4}", pts.len(), if ok { "yes" } else { "no" }, ghmax);
    let pc = heated(0.5, 0.5, C);
    println!("scene 2 cooled c=40: centre {:.4}, below the insulated {:.4}", pc, pex);
    let (c100, c200, g10, g20) = (cube(100), cube(200), relax3(10), relax3(20));
    println!("d=1 rod: bowl 100/8 = {:.4}, exact {:.4}, strip {:.4}", F / 8.0, F * 0.25 / 2.0, F / 8.0);
    println!("d=2 plate: bowl 100/16 = {:.4}, exact {:.4}, strip {:.4}", F / 16.0, pex, F / 8.0);
    println!("d=3 cube: bowl 100/24 = {:.4}, exact {:.4}, strip {:.4}", F / 24.0, c200, F / 8.0);
    println!("cube centre: series N=100 {:.6}, N=200 {:.6}; grid h=1/10 {:.4}, h=1/20 {:.4}, error ratio {:.2}",
             c100, c200, g10, g20, (c200 - g10) / (c200 - g20));
    let (zs, zg) = (10.0 * C / F * heated(0.5, 0.5, C), relax(N, 0.0, 10.0 * C, C)[20][20]); // u = -10 + z
    println!("cold frame at -10 K, cooled: centre series {:.4}, grid {:.4}; rim -10, room 0", zs - 10.0, zg - 10.0);
    println!("in C, room 20: scene 1 centre {:.2}, series 2.5 cm below the hot bar {:.2}; scene 2 {:.2} <= {:.2} <= {:.2}; cold frame {:.2}; heat 5000*0.01 = {:.0} W",
             20.0 + rim(0.5, 0.5, C, TOP), 20.0 + rim(0.5, 0.975, C, TOP), 20.0 + F / 16.0, 20.0 + pex, 20.0 + F / 8.0, 30.0 + zs - 20.0, 50.0);
    let mut res = vec![];
    for e in [0.01, 0.005] {
        let dxx = (s(0.3 + e, 0.6) - 2.0 * s(0.3, 0.6) + s(0.3 - e, 0.6)) / (e * e);
        let dyy = (s(0.3, 0.6 + e) - 2.0 * s(0.3, 0.6) + s(0.3, 0.6 - e)) / (e * e);
        res.push((dxx - dyy).abs());
        res.push((-dxx - dyy - 2.0 * PI * PI * s(0.3, 0.6)).abs());
        println!("breaks residuals at (0.3, 0.6), step {}: u_xx - u_yy {:.6}, -u_xx - u_yy - 2 pi^2 u {:.6}", e, res[res.len() - 2], res[res.len() - 1]);
    }
    println!("breaks 1-2, u = 10 sin(pi x) sin(pi y): rim 0, centre {:.4} K, above every rim point", s(0.5, 0.5));
    let ghmin = pts.iter().map(|&(i, j)| gh[i][j]).fold(f64::MAX, f64::min);
    println!("breaks 3, heater inside: centre {:.4} K above a 0 K rim; grid min {:.4}", pex, ghmin);
    println!("breaks 4, inner bowl without the max(0, .) at a corner: {:.4} K, below the rim's 0 K", F * (0.25 - 0.5) / 4.0);
    assert!((rim(0.5, 0.5, 0.0, TOP) - TOP / 4.0).abs() < 1e-9 && (g0[20][20] - TOP / 4.0).abs() < 1e-6); // three roads
    let cl = line(C);
    assert!((0..10).map(|k| (cl[k] - gc[20][4 * k]).abs()).fold(0.0, f64::max) < 0.1); // two roads, cooled
    let gcmax = pts.iter().map(|&(i, j)| gc[i][j]).fold(f64::MIN, f64::max);
    let gcmin = pts.iter().map(|&(i, j)| gc[i][j]).fold(f64::MAX, f64::min);
    assert!(gap >= 0.0 && gcmax < TOP && gcmin > 0.0);
    let r = (pex - p20) / (pex - p40);
    assert!(3.8 < r && r < 4.2 && ok && F / 16.0 < pex && pex < F / 8.0 && pc < pex);
    let r3 = (c200 - g10) / (c200 - g20);
    assert!((c200 - g20).abs() < 0.03 && 3.8 < r3 && r3 < 4.2 && F / 24.0 < c200 && c200 < F / 8.0);
    assert!((zs - zg).abs() < 0.01 && -10.0 < zs - 10.0 && zs - 10.0 < 0.0);
    assert!(0.0 < d0 && d0 <= 0.5 && 0.0 < dc && dc < d0 && res[0] < 1e-6 && 3.9 < res[1] / res[3] && res[1] / res[3] < 4.1);
    println!("ALL CHECKS PASS");
}
