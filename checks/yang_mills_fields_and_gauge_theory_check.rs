// Yang-Mills on one lattice site -- the check behind the card.  std only, no crates.
// An SU(2) element is a unit quaternion (w, x, y, z).  An su(2) element F = f1 T1 + f2 T2 + f3 T3 is
// the 3-vector f, with T_k = -i sigma_k / 2: then [T_a, T_b] = T_c is the cross product, |F|^2 = -2 tr(F F) = |f|^2,
// and Re tr U = 2w.  Nothing used knows any gauge theory.
type Q = [f64; 4];
type V = [f64; 3];

fn qmul(p: Q, q: Q) -> Q {
    let [a, b, c, d] = p;
    let [e, f, g, h] = q;
    [a * e - b * f - c * g - d * h, a * f + b * e + c * h - d * g, a * g - b * h + c * e + d * f, a * h + b * g - c * f + d * e]
}
fn conj(q: Q) -> Q { [q[0], -q[1], -q[2], -q[3]] }
fn exp_t(v: V) -> Q { // exp(v1 T1 + v2 T2 + v3 T3) in closed form: half angle, unit axis
    let n = (v[0].powi(2) + v[1].powi(2) + v[2].powi(2)).sqrt();
    if n == 0.0 { return [1.0, 0.0, 0.0, 0.0]; }
    [(n / 2.0).cos(), (n / 2.0).sin() * v[0] / n, (n / 2.0).sin() * v[1] / n, (n / 2.0).sin() * v[2] / n]
}
fn cross(a: V, b: V) -> V { [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]] }
fn dot(a: V, b: V) -> f64 { a[0] * b[0] + a[1] * b[1] + a[2] * b[2] }
fn plaquette(ux: Q, uy: Q) -> Q { qmul(qmul(ux, uy), qmul(conj(ux), conj(uy))) } // x, y, back x, back y
fn wilson(beta: f64, n: f64, up: Q) -> f64 { beta * (1.0 - 2.0 * up[0] / n) } // beta (1 - Re tr U_p / N)
fn energy(ax: V, ay: V, g2: f64) -> f64 { let f = cross(ax, ay); dot(f, f) / (2.0 * g2) }
fn f6(v: f64) -> String { format!("{:.6}", v) }
fn vec(v: &[f64]) -> String { format!("({})", v.iter().map(|c| f6(*c)).collect::<Vec<_>>().join(", ")) }
fn scale(v: V, s: f64) -> V { [v[0] * s, v[1] * s, v[2] * s] }

fn main() {
    let (beta, n) = (2.4, 2.0);
    let g2 = 2.0 * n / beta; // coupling squared g^2, from beta = 2N / g^2
    let (alpha, a) = (5.0, 0.1); // field size in 1/fm, lattice spacing in fm
    let (ax, ay): (V, V) = ([alpha, 0.0, 0.0], [0.0, alpha, 0.0]);
    let f = cross(ax, ay);
    let e = energy(ax, ay, g2);
    println!("g^2 = {}   A_x = {}   A_y = {}   per fm", f6(g2), vec(&ax), vec(&ay));
    println!("F_xy = [A_x, A_y] = {} per fm^2   |F_xy| = {}   |F_xy|^2 = {}", vec(&f), f6(dot(f, f).sqrt()), f6(dot(f, f)));
    println!("continuum energy density |F|^2/(2 g^2) = {} per fm^4", f6(e));

    // road 1: the lattice.  Links U = exp(a A), plaquette product, Wilson action, at two spacings
    let (mut err, mut ang) = (vec![], vec![]);
    for sp in [a, a / 2.0] {
        let th = sp * alpha;
        let up = plaquette(exp_t([th, 0.0, 0.0]), exp_t([0.0, th, 0.0]));
        let s = wilson(beta, n, up);
        let closed = 2.0 * beta * (th / 2.0).sin().powi(4); // by hand: Re of the commutator is 1 - 2 sin^4
        let phi = 2.0 * up[0].acos(); // turning angle of the plaquette
        println!("a = {:.3} fm  theta = {:.3}  U_p = ({}, {}, {}, {})", sp, th, f6(up[0]), f6(up[1]), f6(up[2]), f6(up[3]));
        println!("   Wilson S_p = {:.8}  closed form 2 beta sin^4(theta/2) = {:.8}  continuum a^4 E = {:.8}", s, closed, sp.powi(4) * e);
        println!("   S_p / a^4 = {} per fm^4  error {}   plaquette angle {} rad = {:.4} deg, a^2 |F| = {}",
            f6(s / sp.powi(4)), f6(e - s / sp.powi(4)), f6(phi), phi * 180.0 / std::f64::consts::PI, f6(sp * sp * dot(f, f).sqrt()));
        assert!((s - closed).abs() < 1e-12);
        err.push(e - s / sp.powi(4));
        ang.push(phi);
    }
    println!("error ratio, a halved: {}", f6(err[0] / err[1]));
    assert!(3.8 < err[0] / err[1] && err[0] / err[1] < 4.1); // second-order: halve a, quarter the error
    assert!((ang[1] - (a / 2.0).powi(2) * 25.0).abs() < (ang[0] - a * a * 25.0).abs() / 10.0);

    // road 2: gauge invariance.  A gauge change h at the site turns every link U into h U h^-1
    let (ux, uy) = (exp_t([0.5, 0.0, 0.0]), exp_t([0.0, 0.5, 0.0]));
    let h = exp_t([0.7, 0.2, -1.1]);
    let (ux2, uy2) = (qmul(qmul(h, ux), conj(h)), qmul(qmul(h, uy), conj(h)));
    let (p1, p2) = (plaquette(ux, uy), plaquette(ux2, uy2));
    println!("gauge: U_x = {} -> {}", vec(&ux), vec(&ux2));
    println!("gauge: Re tr U_p = {} -> {}   Wilson {} -> {}", f6(2.0 * p1[0]), f6(2.0 * p2[0]), f6(wilson(beta, n, p1)), f6(wilson(beta, n, p2)));
    assert!((0..4).map(|i| (ux[i] - ux2[i]).abs()).fold(0.0, f64::max) > 0.1);
    assert!((p1[0] - p2[0]).abs() < 1e-12);

    // road 3: the field equations.  dE/dA_x = (1/g^2) [A_y, F_xy] = -(1/g^2) D_mu F_mu,x, against finite differences
    let grads = |ax: V, ay: V| -> (V, V) { let f = cross(ax, ay); (scale(cross(ay, f), 1.0 / g2), scale(cross(f, ax), 1.0 / g2)) };
    let numgrad = |ax: V, ay: V| -> [V; 2] {
        let eps = 1e-5;
        let mut out = [[0.0; 3]; 2];
        for which in 0..2 {
            for k in 0..3 {
                let (mut up, mut dn) = ([ax, ay], [ax, ay]);
                up[which][k] += eps;
                dn[which][k] -= eps;
                out[which][k] = (energy(up[0], up[1], g2) - energy(dn[0], dn[1], g2)) / (2.0 * eps);
            }
        }
        out
    };
    let c = cross(ay, f);
    let df: V = [0.0 - c[0], 0.0 - c[1], 0.0 - c[2]]; // D_mu F_mu,x = [A_y, F_yx] = -[A_y, F_xy]
    println!("D_mu F_mu,x = {} per fm^3  (zero for a solution)", vec(&df));
    let (gx, gy) = grads(ax, ay);
    println!("dE/dA_x = {}   dE/dA_y = {}", vec(&gx), vec(&gy));
    let (b1, b2): (V, V) = ([0.3, -1.1, 0.8], [0.9, 0.4, -0.5]); // a lopsided field, to test every component
    let (ga, na) = (grads(b1, b2), numgrad(b1, b2));
    let gav = [ga.0, ga.1];
    let mut gap: f64 = 0.0;
    for i in 0..2 { for k in 0..3 { gap = gap.max((gav[i][k] - na[i][k]).abs()); } }
    println!("lopsided field: dE/dA_x = {}  finite differences = {}", vec(&ga.0), vec(&na[0]));
    assert!(gap < 1e-8);
    let step: V = [ax[0] - 0.001 * gx[0], ax[1] - 0.001 * gx[1], ax[2] - 0.001 * gx[2]];
    let e_down = energy(step, ay, g2);
    println!("one downhill step of 0.001: energy {} -> {}", f6(e), f6(e_down));
    assert!(e_down < e - 0.1);

    // what breaks, and the special cases
    let uc = exp_t([0.0, 0.0, 0.5]); // commuting links: U(1) inside SU(2)
    let pc = plaquette(uc, uc);
    println!("U(1): U_p = {} + ...  Wilson {}   bracket dropped: F_xy = 0, energy {}", vec(&pc[..3]), f6(wilson(beta, n, pc)), f6(0.0));
    println!("commuting fields A_x = (0,0,5), A_y = (0,0,3): energy {}", f6(energy([0.0, 0.0, 5.0], [0.0, 0.0, 3.0], g2)));
    assert!(wilson(beta, n, pc).abs() < 1e-12 && energy([0.0, 0.0, 5.0], [0.0, 0.0, 3.0], g2) == 0.0);
    println!("wrong: forgot 1/N: {}   wrong: beta = 1/g^2: {} per plaquette, {} per fm^4",
        f6(beta * (1.0 - 2.0 * p1[0])), f6(0.6 * (1.0 - p1[0])), f6(0.6 * (1.0 - p1[0]) / a.powi(4)));
    println!("non-compact SL(2,R), X = diag(1,-1): -2 tr(X X) = {}", f6(-2.0 * (1.0 + 1.0)));

    // try changing
    let ut = plaquette(exp_t([1.0, 0.0, 0.0]), exp_t([0.0, 1.0, 0.0]));
    println!("try: a = 0.2 fm  S_p / a^4 = {}   A_y = (3,4,0): energy {}   A_y = (0,0,5): energy {}",
        f6(wilson(beta, n, ut) / 0.2f64.powi(4)), f6(energy(ax, [3.0, 4.0, 0.0], g2)), f6(energy(ax, [0.0, 0.0, 5.0], g2)));
    println!("figure, square side 220 px = a 0.1 fm, corners (100,60) (320,60) (320,280) (100,280)");
    println!("ALL CHECKS PASS");
}
