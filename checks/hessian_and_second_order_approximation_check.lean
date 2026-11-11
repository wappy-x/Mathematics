-- Hessian: when the second partial derivatives of a two-input function are continuous near a point, value plus gradient times step plus half the Hessian's quadratic form misses by less than any multiple of the step squared, mixed partials continuous at the point agree, xy(x^2 - y^2)/(x^2 + y^2) gives -1 and +1 without that continuity, and the card's house numbers come out exactly.
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.Asymptotics.Defs
import Mathlib.Analysis.Calculus.MeanValue
import Mathlib.Analysis.Calculus.Deriv.MeanValue
import Mathlib.Analysis.Calculus.Deriv.Mul
import Mathlib.Analysis.Calculus.Deriv.Pow
import Mathlib.Analysis.Calculus.Deriv.Inv

open Filter Topology Asymptotics

lemma hsoa_first_order (φ φ' : ℝ → ℝ) (x0 r c ε : ℝ)
    (hd : ∀ x, |x - x0| < r → HasDerivAt φ (φ' x) x)
    (hb : ∀ x, |x - x0| < r → |φ' x - c| ≤ ε) (y : ℝ) (hy : |y - x0| < r) :
    |φ y - φ x0 - c * (y - x0)| ≤ ε * |y - x0| := by
  have hx0 : x0 ∈ Metric.ball x0 r := by
    rw [Metric.mem_ball, dist_self]; exact lt_of_le_of_lt (abs_nonneg _) hy
  have hy' : y ∈ Metric.ball x0 r := by rw [Metric.mem_ball, Real.dist_eq]; exact hy
  have key := Convex.norm_image_sub_le_of_norm_hasDerivWithin_le
    (f := fun x => φ x - c * x) (f' := fun x => φ' x - c) (C := ε) (s := Metric.ball x0 r)
    (fun x hx => by
      rw [Metric.mem_ball, Real.dist_eq] at hx
      have := (hd x hx).sub ((hasDerivAt_id x).const_mul c)
      have h4 : HasDerivAt (fun x => φ x - c * x) (φ' x - c) x := by
        convert this using 1
        · funext z; simp only [Pi.sub_apply, id]
        · ring
      exact h4.hasDerivWithinAt)
    (fun x hx => by
      rw [Metric.mem_ball, Real.dist_eq] at hx
      rw [Real.norm_eq_abs]; exact hb x hx)
    (convex_ball x0 r) hx0 hy'
  simp only [Real.norm_eq_abs] at key
  have he : φ y - c * y - (φ x0 - c * x0) = φ y - φ x0 - c * (y - x0) := by ring
  rw [he] at key
  exact key

lemma hsoa_second_order (φ φ' φ'' : ℝ → ℝ) (x0 r c ε : ℝ)
    (hd1 : ∀ x, |x - x0| < r → HasDerivAt φ (φ' x) x)
    (hd2 : ∀ x, |x - x0| < r → HasDerivAt φ' (φ'' x) x)
    (hb : ∀ x, |x - x0| < r → |φ'' x - c| ≤ ε) (y : ℝ) (hy : |y - x0| < r) :
    |φ y - φ x0 - φ' x0 * (y - x0) - c / 2 * (y - x0) ^ 2| ≤ ε * (y - x0) ^ 2 := by
  have hr0 : 0 < r := lt_of_le_of_lt (abs_nonneg _) hy
  have hε : 0 ≤ ε := le_trans (abs_nonneg _) (hb x0 (by simpa using hr0))
  set d := |y - x0| with hd
  have hsub : ∀ x ∈ Metric.closedBall x0 d, |x - x0| ≤ d := by
    intro x hx; rw [Metric.mem_closedBall, Real.dist_eq] at hx; exact hx
  have hx0 : x0 ∈ Metric.closedBall x0 d := Metric.mem_closedBall_self (abs_nonneg _)
  have hy' : y ∈ Metric.closedBall x0 d := by
    rw [Metric.mem_closedBall, Real.dist_eq]
  have key := Convex.norm_image_sub_le_of_norm_hasDerivWithin_le
    (f := fun x => φ x - φ' x0 * x - c / 2 * ((x - x0) * (x - x0)))
    (f' := fun x => φ' x - φ' x0 - c * (x - x0)) (C := ε * d) (s := Metric.closedBall x0 d)
    (fun x hx => by
      have hx' : |x - x0| < r := lt_of_le_of_lt (hsub x hx) hy
      have h1 := (hd1 x hx').sub ((hasDerivAt_id x).const_mul (φ' x0))
      have h2 := (((hasDerivAt_id x).sub_const x0).mul ((hasDerivAt_id x).sub_const x0)).const_mul
        (c / 2)
      have h3 := h1.sub h2
      have h4 : HasDerivAt (fun x => φ x - φ' x0 * x - c / 2 * ((x - x0) * (x - x0)))
          (φ' x - φ' x0 - c * (x - x0)) x := by
        convert h3 using 1
        · funext z; simp only [Pi.sub_apply, Pi.mul_apply, id]
        · simp only [id]; ring
      exact h4.hasDerivWithinAt)
    (fun x hx => by
      have hx' := hsub x hx
      rw [Real.norm_eq_abs]
      have := hsoa_first_order φ' φ'' x0 r c ε hd2 hb x (lt_of_le_of_lt hx' hy)
      calc |φ' x - φ' x0 - c * (x - x0)| ≤ ε * |x - x0| := this
        _ ≤ ε * d := mul_le_mul_of_nonneg_left hx' hε)
    (convex_closedBall x0 d) hx0 hy'
  simp only [Real.norm_eq_abs] at key
  have he : φ y - φ' x0 * y - c / 2 * ((y - x0) * (y - x0)) -
      (φ x0 - φ' x0 * x0 - c / 2 * ((x0 - x0) * (x0 - x0))) =
      φ y - φ x0 - φ' x0 * (y - x0) - c / 2 * (y - x0) ^ 2 := by ring
  rw [he] at key
  calc _ ≤ ε * d * |y - x0| := key
    _ = ε * (y - x0) ^ 2 := by rw [hd, mul_assoc, abs_mul_abs_self, sq]

lemma hsoa_rational_deriv (y : ℝ) (hy : y ≠ 0) :
    HasDerivAt (fun x : ℝ => x * y * (x ^ 2 - y ^ 2) / (x ^ 2 + y ^ 2)) (-y) 0 := by
  have hd : (0 : ℝ) ^ 2 + y ^ 2 ≠ 0 := by positivity
  have h1 := ((((hasDerivAt_id' (0 : ℝ)).mul_const y).mul
    ((hasDerivAt_pow 2 (0 : ℝ)).sub_const (y ^ 2))).div
    ((hasDerivAt_pow 2 (0 : ℝ)).add_const (y ^ 2)) hd)
  convert h1 using 1
  field_simp
  ring

#print axioms hsoa_first_order
#print axioms hsoa_second_order
#print axioms hsoa_rational_deriv

/-- The second-order model. Let `Q` be a function of two inputs `(t, A)` and `p` a point. Near `p`,
suppose the first partials `Qt` (rate in `t`, `A` frozen) and `QA` (rate in `A`, `t` frozen) exist,
the four second partials `Qtt`, `QtA` (`t` first, then `A`), `QAt` (`A` first, then `t`) and `QAA`
exist, and the second partials are continuous. Then for a step `h = (h_t, h_A)` the model
`Q(p) + Qt h_t + QA h_A + ½ Qtt h_t² + QtA h_t h_A + ½ QAA h_A²`, everything read at `p`, misses
`Q(p + h)` by a remainder that is small beside the step squared: the remainder divided by
`h_t² + h_A²` heads for 0 as the step shrinks. -/
theorem second_order_model_error_is_little_o_of_step_squared
    (Q Qt QA Qtt QtA QAt QAA : ℝ × ℝ → ℝ) (p : ℝ × ℝ)
    (hfirst : ∀ᶠ q in 𝓝 p,
      HasDerivAt (fun t => Q (t, q.2)) (Qt q) q.1 ∧ HasDerivAt (fun A => Q (q.1, A)) (QA q) q.2)
    (hsecond : ∀ᶠ q in 𝓝 p,
      HasDerivAt (fun t => Qt (t, q.2)) (Qtt q) q.1 ∧ HasDerivAt (fun A => Qt (q.1, A)) (QtA q) q.2 ∧
      HasDerivAt (fun t => QA (t, q.2)) (QAt q) q.1 ∧ HasDerivAt (fun A => QA (q.1, A)) (QAA q) q.2)
    (hcont : ∀ᶠ q in 𝓝 p,
      ContinuousAt Qtt q ∧ ContinuousAt QtA q ∧ ContinuousAt QAt q ∧ ContinuousAt QAA q) :
    (fun h : ℝ × ℝ => Q (p + h) -
        (Q p + (Qt p * h.1 + QA p * h.2) +
          (1 / 2 * Qtt p * h.1 ^ 2 + QtA p * h.1 * h.2 + 1 / 2 * QAA p * h.2 ^ 2)))
      =o[𝓝 0] (fun h : ℝ × ℝ => h.1 ^ 2 + h.2 ^ 2) := by
  obtain ⟨p1, p2⟩ := p
  rw [isLittleO_iff]
  intro ε hε
  have he : (0 : ℝ) < ε / 2 := by positivity
  have hc := hcont.self_of_nhds
  have c1 := Metric.tendsto_nhds.mp hc.1 (ε / 2) he
  have c2 := Metric.tendsto_nhds.mp hc.2.1 (ε / 2) he
  have c3 := Metric.tendsto_nhds.mp hc.2.2.2 (ε / 2) he
  obtain ⟨δ, hδ, hP⟩ := Metric.eventually_nhds_iff.mp
    (hfirst.and (hsecond.and (c1.and (c2.and c3))))
  have key : ∀ x y : ℝ, |x - p1| < δ → |y - p2| < δ → _ := fun x y hx hy =>
    hP (y := (x, y)) (by simp only [Prod.dist_eq, Real.dist_eq]; exact max_lt hx hy)
  filter_upwards [Metric.ball_mem_nhds (0 : ℝ × ℝ) hδ] with h hh
  obtain ⟨h1, h2⟩ := h
  rw [Metric.mem_ball, Prod.dist_eq, max_lt_iff] at hh
  simp only [Real.dist_eq] at hh
  obtain ⟨hh1, hh2⟩ := hh
  have hp1 : |p1 - p1| < δ := by simpa using hδ
  have hA := hsoa_second_order (fun A => Q (p1, A)) (fun A => QA (p1, A)) (fun A => QAA (p1, A))
    p2 δ (QAA (p1, p2)) (ε / 2)
    (fun x hx => (key p1 x hp1 hx).1.2) (fun x hx => (key p1 x hp1 hx).2.1.2.2.2)
    (fun x hx => by
      have := (key p1 x hp1 hx).2.2.2.2
      rw [Real.dist_eq] at this; exact this.le)
    (p2 + h2) (by simpa using hh2)
  have hy2 : |p2 + h2 - p2| < δ := by simpa using hh2
  have hB := hsoa_second_order (fun t => Q (t, p2 + h2)) (fun t => Qt (t, p2 + h2))
    (fun t => Qtt (t, p2 + h2)) p1 δ (Qtt (p1, p2)) (ε / 2)
    (fun x hx => (key x (p2 + h2) hx hy2).1.1) (fun x hx => (key x (p2 + h2) hx hy2).2.1.1)
    (fun x hx => by
      have := (key x (p2 + h2) hx hy2).2.2.1
      rw [Real.dist_eq] at this; exact this.le)
    (p1 + h1) (by simpa using hh1)
  have hC := hsoa_first_order (fun A => Qt (p1, A)) (fun A => QtA (p1, A)) p2 δ (QtA (p1, p2))
    (ε / 2) (fun x hx => (key p1 x hp1 hx).2.1.2.1)
    (fun x hx => by
      have := (key p1 x hp1 hx).2.2.2.1
      rw [Real.dist_eq] at this; exact this.le)
    (p2 + h2) (by simpa using hh2)
  simp only [add_sub_cancel_left] at hA hB hC
  simp only [Prod.mk_add_mk, Real.norm_eq_abs]
  set A := Q (p1, p2 + h2) - Q (p1, p2) - QA (p1, p2) * h2 - QAA (p1, p2) / 2 * h2 ^ 2
  set B := Q (p1 + h1, p2 + h2) - Q (p1, p2 + h2) - Qt (p1, p2 + h2) * h1 -
    Qtt (p1, p2) / 2 * h1 ^ 2
  set C := Qt (p1, p2 + h2) - Qt (p1, p2) - QtA (p1, p2) * h2
  have hR : Q (p1 + h1, p2 + h2) - (Q (p1, p2) + (Qt (p1, p2) * h1 + QA (p1, p2) * h2) +
      (1 / 2 * Qtt (p1, p2) * h1 ^ 2 + QtA (p1, p2) * h1 * h2 + 1 / 2 * QAA (p1, p2) * h2 ^ 2))
      = B + A + h1 * C := by
    simp only [A, B, C]; ring
  rw [hR, abs_of_nonneg (by positivity : (0 : ℝ) ≤ h1 ^ 2 + h2 ^ 2)]
  have hm : |h1 * C| ≤ ε / 2 * (|h1| * |h2|) := by
    rw [abs_mul]
    calc |h1| * |C| ≤ |h1| * (ε / 2 * |h2|) := mul_le_mul_of_nonneg_left hC (abs_nonneg _)
      _ = ε / 2 * (|h1| * |h2|) := by ring
  have hq : |h1| * |h2| ≤ h1 ^ 2 + h2 ^ 2 := by
    have := sq_nonneg (|h1| - |h2|)
    have e1 := sq_abs h1
    have e2 := sq_abs h2
    nlinarith [abs_nonneg h1, abs_nonneg h2]
  calc |B + A + h1 * C| ≤ |B| + |A| + |h1 * C| := by
        have := abs_add_le (B + A) (h1 * C)
        have := abs_add_le B A
        linarith
    _ ≤ ε / 2 * h1 ^ 2 + ε / 2 * h2 ^ 2 + ε / 2 * (h1 ^ 2 + h2 ^ 2) := by
        have := mul_le_mul_of_nonneg_left hq he.le
        linarith
    _ = ε * (h1 ^ 2 + h2 ^ 2) := by ring

/-- The Hessian is symmetric. Let `Q` be a function of two inputs `(t, A)`. Near the point `(a, b)`,
suppose the first partials `Qt` and `QA` exist and the mixed partials `QtA` (the `t`-rate, then its
rate in `A`) and `QAt` (the `A`-rate, then its rate in `t`) exist, and suppose both mixed partials
are continuous at `(a, b)`. Then the two mixed partials are equal at `(a, b)`. -/
theorem hessian_mixed_partials_agree (Q Qt QA QtA QAt : ℝ × ℝ → ℝ) (a b : ℝ)
    (hfirst : ∀ᶠ q in 𝓝 (a, b),
      HasDerivAt (fun t => Q (t, q.2)) (Qt q) q.1 ∧ HasDerivAt (fun A => Q (q.1, A)) (QA q) q.2)
    (hmixed : ∀ᶠ q in 𝓝 (a, b),
      HasDerivAt (fun A => Qt (q.1, A)) (QtA q) q.2 ∧ HasDerivAt (fun t => QA (t, q.2)) (QAt q) q.1)
    (hcont : ContinuousAt QtA (a, b) ∧ ContinuousAt QAt (a, b)) :
    QtA (a, b) = QAt (a, b) := by
  apply eq_of_forall_dist_le
  intro ε hε
  have he : (0 : ℝ) < ε / 2 := by positivity
  have c1 := Metric.tendsto_nhds.mp hcont.1 (ε / 2) he
  have c2 := Metric.tendsto_nhds.mp hcont.2 (ε / 2) he
  obtain ⟨δ, hδ, hP⟩ := Metric.eventually_nhds_iff.mp (hfirst.and (hmixed.and (c1.and c2)))
  have key : ∀ x y : ℝ, |x - a| < δ → |y - b| < δ → _ := fun x y hx hy =>
    hP (y := (x, y)) (by simp only [Prod.dist_eq, Real.dist_eq]; exact max_lt hx hy)
  set h := δ / 2 with hh
  have hpos : 0 < h := by positivity
  have hlt : h < δ := by linarith
  have inI : ∀ u x : ℝ, x ∈ Set.Icc u (u + h) → |x - u| < δ := by
    intro u x hx
    rw [abs_lt]; constructor <;> linarith [hx.1, hx.2]
  have hu0 : |a - a| < δ := by simpa using hδ
  have hv0 : |b - b| < δ := by simpa using hδ
  have hbh : |b + h - b| < δ := by rw [add_sub_cancel_left, abs_of_pos hpos]; exact hlt
  have hah : |a + h - a| < δ := by rw [add_sub_cancel_left, abs_of_pos hpos]; exact hlt
  -- first route: t-difference, then A-difference
  have hu : ∀ x ∈ Set.Icc a (a + h),
      HasDerivAt (fun t => Q (t, b + h) - Q (t, b)) (Qt (x, b + h) - Qt (x, b)) x := by
    intro x hx
    exact (key x (b + h) (inI a x hx) hbh).1.1.sub (key x b (inI a x hx) hv0).1.1
  obtain ⟨ξ, hξ, hξe⟩ := exists_hasDerivAt_eq_slope (fun t => Q (t, b + h) - Q (t, b))
    (fun x => Qt (x, b + h) - Qt (x, b)) (by linarith)
    (fun x hx => (hu x hx).continuousAt.continuousWithinAt)
    (fun x hx => hu x (Set.Ioo_subset_Icc_self hx))
  have hξI : |ξ - a| < δ := inI a ξ (Set.Ioo_subset_Icc_self hξ)
  have hw : ∀ y ∈ Set.Icc b (b + h), HasDerivAt (fun A => Qt (ξ, A)) (QtA (ξ, y)) y := by
    intro y hy
    exact (key ξ y hξI (inI b y hy)).2.1.1
  obtain ⟨η, hη, hηe⟩ := exists_hasDerivAt_eq_slope (fun A => Qt (ξ, A))
    (fun y => QtA (ξ, y)) (by linarith)
    (fun y hy => (hw y hy).continuousAt.continuousWithinAt)
    (fun y hy => hw y (Set.Ioo_subset_Icc_self hy))
  have hηI : |η - b| < δ := inI b η (Set.Ioo_subset_Icc_self hη)
  -- second route: A-difference, then t-difference
  have hv : ∀ y ∈ Set.Icc b (b + h),
      HasDerivAt (fun A => Q (a + h, A) - Q (a, A)) (QA (a + h, y) - QA (a, y)) y := by
    intro y hy
    exact (key (a + h) y hah (inI b y hy)).1.2.sub (key a y hu0 (inI b y hy)).1.2
  obtain ⟨η', hη', hη'e⟩ := exists_hasDerivAt_eq_slope (fun A => Q (a + h, A) - Q (a, A))
    (fun y => QA (a + h, y) - QA (a, y)) (by linarith)
    (fun y hy => (hv y hy).continuousAt.continuousWithinAt)
    (fun y hy => hv y (Set.Ioo_subset_Icc_self hy))
  have hη'I : |η' - b| < δ := inI b η' (Set.Ioo_subset_Icc_self hη')
  have hz : ∀ x ∈ Set.Icc a (a + h), HasDerivAt (fun t => QA (t, η')) (QAt (x, η')) x := by
    intro x hx
    exact (key x η' (inI a x hx) hη'I).2.1.2
  obtain ⟨ξ', hξ', hξ'e⟩ := exists_hasDerivAt_eq_slope (fun t => QA (t, η'))
    (fun x => QAt (x, η')) (by linarith)
    (fun x hx => (hz x hx).continuousAt.continuousWithinAt)
    (fun x hx => hz x (Set.Ioo_subset_Icc_self hx))
  have hξ'I : |ξ' - a| < δ := inI a ξ' (Set.Ioo_subset_Icc_self hξ')
  -- the two routes give the same number
  have hne : (b + h - b) ≠ 0 := by rw [add_sub_cancel_left]; exact hpos.ne'
  have hne' : (a + h - a) ≠ 0 := by rw [add_sub_cancel_left]; exact hpos.ne'
  have heq : QtA (ξ, η) = QAt (ξ', η') := by
    rw [hηe, hξ'e]
    simp only [add_sub_cancel_left] at hξe hη'e ⊢
    rw [hξe, hη'e]
    field_simp
    ring
  have d1 := (key ξ η hξI hηI).2.2.1
  have d2 := (key ξ' η' hξ'I hη'I).2.2.2
  rw [Real.dist_eq] at d1 d2 ⊢
  rw [heq] at d1
  calc |QtA (a, b) - QAt (a, b)|
      = |(QAt (ξ', η') - QAt (a, b)) - (QAt (ξ', η') - QtA (a, b))| := by ring_nf
    _ ≤ |QAt (ξ', η') - QAt (a, b)| + |QAt (ξ', η') - QtA (a, b)| := abs_sub _ _
    _ ≤ ε := by linarith

/-- Without continuity the order matters. Take `G(x, y) = xy(x² - y²)/(x² + y²)`, with `G = 0` at
the origin. At the origin the mixed partial is `-1` taking `x` first, then `y`, and `+1` taking `y`
first, then `x`. -/
theorem mixed_partials_disagree_without_continuity :
    let G : ℝ × ℝ → ℝ := fun q =>
      if q = (0, 0) then 0 else q.1 * q.2 * (q.1 ^ 2 - q.2 ^ 2) / (q.1 ^ 2 + q.2 ^ 2)
    HasDerivAt (fun y => deriv (fun x => G (x, y)) 0) (-1) 0 ∧
      HasDerivAt (fun x => deriv (fun y => G (x, y)) 0) 1 0 := by
  intro G
  constructor
  · have hfun : (fun y => deriv (fun x => G (x, y)) 0) = fun y => -y := by
      funext y
      by_cases hy : y = 0
      · subst hy
        have : (fun x => G (x, 0)) = fun _ => 0 := by
          funext x; simp [G]
        rw [this, deriv_const]; simp
      · have : (fun x => G (x, y)) = fun x => x * y * (x ^ 2 - y ^ 2) / (x ^ 2 + y ^ 2) := by
          funext x; simp [G, hy]
        rw [this]
        exact (hsoa_rational_deriv y hy).deriv
    rw [hfun]
    exact (hasDerivAt_id (0 : ℝ)).neg
  · have hfun : (fun x => deriv (fun y => G (x, y)) 0) = fun x => x := by
      funext x
      by_cases hx : x = 0
      · subst hx
        have : (fun y => G (0, y)) = fun _ => 0 := by
          funext y; simp [G]
        rw [this, deriv_const]
      · have : (fun y => G (x, y)) =
            fun y => -(y * x * (y ^ 2 - x ^ 2) / (y ^ 2 + x ^ 2)) := by
          funext y; simp only [G, Prod.mk.injEq, hx, false_and, ite_false]; ring
        rw [this]
        have := (hsoa_rational_deriv x hx).neg
        simpa using this.deriv
    rw [hfun]
    exact hasDerivAt_id 0

/-- The card's house: heat loss in watts with `t` cm of insulation and `A` m² of glass,
`Q(t, A) = 20 ((100 - A)/(0.5 + t/4) + 2.8 A)`. -/
noncomputable def heatQ (t A : ℝ) : ℝ := 20 * ((100 - A) / (1 / 2 + t / 4) + 14 / 5 * A)

/-! The card's worked numbers, checked with exact fractions. -/

-- heat loss now, Q(10, 20) = 4960/3 (1653.333 W), and at the new design, Q(11, 22) = 1712 W
example : heatQ 10 20 = 4960 / 3 := by norm_num [heatQ]
example : heatQ 11 22 = 1712 := by norm_num [heatQ]
-- slopes: Q_t = -5 × 80 / 9 = -400/9 (-44.444), Q_A = 20 (2.8 - 1/3) = 148/3 (49.333)
example : -(5 : ℚ) * 80 / 9 = -400 / 9 ∧ (20 : ℚ) * (14 / 5 - 1 / 3) = 148 / 3 := by norm_num
-- bends: Q_tt = 2.5 × 80 / 27 = 200/27 (7.4074), mixed 5/9 (0.5556)
example : (5 / 2 : ℚ) * 80 / 27 = 200 / 27 ∧ (5 : ℚ) / 3 ^ 2 = 5 / 9 := by norm_num
-- tangent plane: 1653.333 - 44.444 × 1 + 49.333 × 2 = 15368/9 (1707.556 W)
example : (4960 / 3 : ℚ) + (-400 / 9) * 1 + 148 / 3 * 2 = 15368 / 9 := by norm_num
-- Hessian correction: ½ × 200/27 × 1 + 5/9 × 1 × 2 + 0 = 100/27 + 30/27 = 130/27 (4.815 W)
example : (1 / 2 : ℚ) * (200 / 27) * 1 ^ 2 + 5 / 9 * 1 * 2 + 1 / 2 * 0 * 2 ^ 2 = 130 / 27 := by
  norm_num
-- quadratic model 46234/27 (1712.370 W); remainder 1712 - 46234/27 = -10/27 (-0.3704 W)
example : (15368 / 9 : ℚ) + 130 / 27 = 46234 / 27 := by norm_num
example : heatQ 11 22 - 46234 / 27 = -10 / 27 := by norm_num [heatQ]
-- the bend along the path: h^T H h = 200/27 + 2 × 5/9 × 1 × 2 + 0 = 260/27 (9.6296)
example : (200 / 27 : ℚ) * 1 ^ 2 + 2 * (5 / 9) * 1 * 2 + 0 * 2 ^ 2 = 260 / 27 := by norm_num
-- the rectangle of 1 cm by 2 m²: double difference over the area is 20/39 (0.5128)
example : (heatQ 11 22 - heatQ 11 20 - heatQ 10 22 + heatQ 10 20) / (1 * 2) = 20 / 39 := by
  norm_num [heatQ]
-- Lagrange window: phi'''/6 = -195/(6 u^4) for u from 3 to 13/4, from -65/162 (-0.4012) to
-- -640/2197 (-0.2913); the true remainder -10/27 lies inside
example : (-195 : ℚ) / (6 * 3 ^ 4) = -65 / 162 ∧ (-195 : ℚ) / (6 * (13 / 4) ^ 4) = -640 / 2197 := by
  norm_num
example : (-65 / 162 : ℚ) ≤ -10 / 27 ∧ (-10 / 27 : ℚ) ≤ -640 / 2197 := by norm_num
-- mistakes: no one-half gives 46364/27 (1717.185 W); no mixed term gives 46204/27 (1711.259 W)
example : (15368 / 9 : ℚ) + 260 / 27 = 46364 / 27 := by norm_num
example : (15368 / 9 : ℚ) + 100 / 27 = 46204 / 27 := by norm_num

#print axioms second_order_model_error_is_little_o_of_step_squared
#print axioms hessian_mixed_partials_agree
#print axioms mixed_partials_disagree_without_continuity
