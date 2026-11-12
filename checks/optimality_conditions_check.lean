-- Optimality conditions: at a local minimum of a function with continuous second derivatives the gradient is zero and every curvature is zero or above, a zero gradient with every curvature above zero gives a strict local minimum, and the banana valley's only flat spot is (1, 1), its lowest point.
import Mathlib.Analysis.Calculus.LocalExtr.Basic
import Mathlib.Analysis.Calculus.ContDiff.Defs
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Tactic
import Mathlib.Analysis.Calculus.MeanValue
import Mathlib.Analysis.Calculus.ContDiff.Comp
import Mathlib.Analysis.Calculus.Deriv.Pow
import Mathlib.Analysis.Calculus.Deriv.Comp
import Mathlib.Analysis.Calculus.FDeriv.Pow

open Filter Topology

/-- Second-order Taylor bound: near `x`, `f` differs from its quadratic model by at most
`ε ‖y - x‖²`. -/
lemma taylor2_bound {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E] (f : E → ℝ) (x : E)
    (hd : ∀ᶠ y in 𝓝 x, DifferentiableAt ℝ f y)
    (hd2 : DifferentiableAt ℝ (fderiv ℝ f) x) {ε : ℝ} (hε : 0 < ε) :
    ∀ᶠ y in 𝓝 x, |f y - f x - fderiv ℝ f x (y - x)
        - (1 / 2) * fderiv ℝ (fderiv ℝ f) x (y - x) (y - x)| ≤ ε * ‖y - x‖ ^ 2 := by
  have ho := hd2.hasFDerivAt.isLittleO
  rw [Asymptotics.isLittleO_iff] at ho
  have hb := ho hε
  obtain ⟨δ, hδ, hball⟩ := Metric.eventually_nhds_iff_ball.1 (hb.and hd)
  rw [Metric.eventually_nhds_iff_ball]
  refine ⟨δ, hδ, fun y hy => ?_⟩
  set h := y - x with hh
  set L := fderiv ℝ (fderiv ℝ f) x
  have hyx : ‖h‖ < δ := by rw [Metric.mem_ball, dist_eq_norm] at hy; exact hy
  have hseg : ∀ t ∈ Set.Icc (0:ℝ) 1, x + t • h ∈ Metric.ball x δ := by
    intro t ht
    rw [Metric.mem_ball, dist_eq_norm, add_sub_cancel_left, norm_smul, Real.norm_eq_abs,
      abs_of_nonneg ht.1]
    calc t * ‖h‖ ≤ 1 * ‖h‖ := by gcongr; exact ht.2
      _ < δ := by simpa using hyx
  let φ : ℝ → ℝ := fun t => f (x + t • h) - t * fderiv ℝ f x h - (1/2) * t^2 * L h h
  let φ' : ℝ → ℝ := fun t => fderiv ℝ f (x + t • h) h - fderiv ℝ f x h - t * L h h
  have hderiv : ∀ t ∈ Set.Icc (0:ℝ) 1, HasDerivWithinAt φ (φ' t) (Set.Icc 0 1) t := by
    intro t ht
    have h1 : HasDerivAt (fun t : ℝ => x + t • h) h t := by
      simpa using ((hasDerivAt_id t).smul_const h).const_add x
    have hf' : HasFDerivAt f (fderiv ℝ f (x + t • h)) (x + t • h) :=
      ((hball _ (hseg t ht)).2).hasFDerivAt
    have h2 := hf'.comp_hasDerivAt t h1
    have h3 := ((h2.sub ((hasDerivAt_id t).mul_const (fderiv ℝ f x h))).sub
      (((hasDerivAt_pow 2 t).const_mul (1/2 : ℝ)).mul_const (L h h)))
    convert h3.hasDerivWithinAt using 1
    · funext s
      simp only [φ, Pi.sub_apply, Function.comp_apply, id]
    · simp only [φ']
      norm_num
      left
      ring
  have hbound : ∀ t ∈ Set.Ico (0:ℝ) 1, ‖φ' t‖ ≤ ε * ‖h‖^2 := by
    intro t ht
    have hmem := (hball _ (hseg t (Set.Ico_subset_Icc_self ht))).1
    simp only [add_sub_cancel_left] at hmem
    have e : φ' t = (fderiv ℝ f (x + t • h) - fderiv ℝ f x - L (t • h)) h := by
      simp [φ']
    rw [e]
    have hn : ‖t • h‖ ≤ ‖h‖ := by
      rw [norm_smul, Real.norm_eq_abs, abs_of_nonneg ht.1]
      nlinarith [ht.2, norm_nonneg h]
    calc _ ≤ ‖fderiv ℝ f (x + t • h) - fderiv ℝ f x - L (t • h)‖ * ‖h‖ :=
          ContinuousLinearMap.le_opNorm _ _
      _ ≤ ε * ‖t • h‖ * ‖h‖ := by gcongr
      _ ≤ ε * ‖h‖ * ‖h‖ := by gcongr
      _ = ε * ‖h‖ ^ 2 := by ring
  have key := norm_image_sub_le_of_norm_deriv_le_segment_01' hderiv hbound
  simp only [φ, one_smul, zero_smul, add_zero, Real.norm_eq_abs] at key
  rw [hh, add_sub_cancel] at key
  convert key using 2
  ring

#print axioms taylor2_bound

/-- The two optimality conditions. Let `f` be a function of `n` inputs with continuous second
derivatives near the point `x`. Its gradient there is `fderiv ℝ f x`, and its curvature along a
direction `d` is `fderiv ℝ (fderiv ℝ f) x d d`, the number `dᵀ ∇²f(x) d`.
* Necessary: if `x` is a local minimiser, the gradient is zero and the curvature is zero or
  above in every direction (the Hessian is positive semidefinite).
* Sufficient: if the gradient is zero and the curvature is above zero in every nonzero direction
  (the Hessian is positive definite), then `x` is a strict local minimiser: every other point
  close enough is strictly higher. -/
theorem optimality_conditions {n : ℕ} (f : EuclideanSpace ℝ (Fin n) → ℝ)
    (x : EuclideanSpace ℝ (Fin n)) (hf : ContDiffAt ℝ 2 f x) :
    (IsLocalMin f x →
      fderiv ℝ f x = 0 ∧ ∀ d, 0 ≤ fderiv ℝ (fderiv ℝ f) x d d) ∧
    (fderiv ℝ f x = 0 → (∀ d, d ≠ 0 → 0 < fderiv ℝ (fderiv ℝ f) x d d) →
      ∀ᶠ y in 𝓝[≠] x, f x < f y) := by
  have hd : ∀ᶠ y in 𝓝 x, DifferentiableAt ℝ f y :=
    (hf.eventually (by simp)).mono fun y hy => hy.differentiableAt (by simp)
  have hd2 : DifferentiableAt ℝ (fderiv ℝ f) x :=
    (hf.fderiv_right (m := 1) (by norm_num)).differentiableAt (by simp)
  refine ⟨fun hmin => ?_, fun hg hpos => ?_⟩
  · have hg := hmin.fderiv_eq_zero
    refine ⟨hg, fun d => ?_⟩
    by_contra hneg
    push Not at hneg
    set Q := fderiv ℝ (fderiv ℝ f) x d d with hQ
    have hd0 : d ≠ 0 := by rintro rfl; simp [Q] at hneg
    have hdpos : 0 < ‖d‖ := norm_pos_iff.2 hd0
    have hε : 0 < -Q / (4 * ‖d‖^2) := div_pos (by linarith) (by positivity)
    have hT := taylor2_bound f x hd hd2 hε
    have hev := hT.and (hmin : ∀ᶠ y in 𝓝 x, f x ≤ f y)
    have htend : Tendsto (fun t : ℝ => x + t • d) (𝓝[>] 0) (𝓝 x) := by
      have : Tendsto (fun t : ℝ => x + t • d) (𝓝 0) (𝓝 (x + (0:ℝ) • d)) :=
        (continuous_const.add (continuous_id.smul continuous_const)).tendsto 0
      simpa using this.mono_left nhdsWithin_le_nhds
    obtain ⟨t, ⟨hb, hle⟩, ht⟩ := ((htend.eventually hev).and self_mem_nhdsWithin).exists
    simp only [add_sub_cancel_left, hg, ContinuousLinearMap.zero_apply, sub_zero, map_smul,
      ContinuousLinearMap.smul_apply, smul_eq_mul, norm_smul, Real.norm_eq_abs] at hb
    rw [← hQ] at hb
    have ht' : (0:ℝ) < t := ht
    rw [abs_of_pos ht'] at hb
    have h1 := (abs_le.1 hb).2
    have h2 : -Q / (4 * ‖d‖ ^ 2) * (t * ‖d‖) ^ 2 = -Q * t ^ 2 / 4 := by
      field_simp
    rw [h2] at h1
    nlinarith [mul_pos ht' ht']
  · obtain ⟨c, hc, hcQ⟩ : ∃ c > 0, ∀ d, c * ‖d‖^2 ≤ fderiv ℝ (fderiv ℝ f) x d d := by
      set L := fderiv ℝ (fderiv ℝ f) x
      have hcont : Continuous fun d => L d d := by fun_prop
      by_cases hs : (Metric.sphere (0 : EuclideanSpace ℝ (Fin n)) 1).Nonempty
      · obtain ⟨u, hu, hmin⟩ :=
          (isCompact_sphere (0 : EuclideanSpace ℝ (Fin n)) 1).exists_isMinOn hs hcont.continuousOn
        have hu0 : u ≠ 0 := by rintro rfl; simp at hu
        refine ⟨L u u, hpos u hu0, fun d => ?_⟩
        rcases eq_or_ne d 0 with rfl | hd0
        · simp
        · have hn : 0 < ‖d‖ := norm_pos_iff.2 hd0
          have hmem : ‖d‖⁻¹ • d ∈ Metric.sphere (0 : EuclideanSpace ℝ (Fin n)) 1 := by
            simp [norm_smul, hd0]
          have := hmin hmem
          simp only [Set.mem_setOf_eq, map_smul, ContinuousLinearMap.smul_apply, smul_eq_mul] at this
          have e : ‖d‖⁻¹ * (‖d‖⁻¹ * L d d) * ‖d‖ ^ 2 = L d d := by field_simp
          calc L u u * ‖d‖ ^ 2 ≤ ‖d‖⁻¹ * (‖d‖⁻¹ * L d d) * ‖d‖ ^ 2 := by gcongr
            _ = L d d := e
      · refine ⟨1, one_pos, fun d => ?_⟩
        have : d = 0 := by
          by_contra hd0
          exact hs ⟨‖d‖⁻¹ • d, by simp [norm_smul, hd0]⟩
        simp [this]
    have hT := taylor2_bound f x hd hd2 (by positivity : 0 < c / 4)
    filter_upwards [nhdsWithin_le_nhds hT, self_mem_nhdsWithin] with y hy hne
    rw [hg] at hy
    simp only [ContinuousLinearMap.zero_apply, sub_zero] at hy
    have hne' : y ≠ x := hne
    have h1 := hcQ (y - x)
    have h2 : 0 < ‖y - x‖ := norm_pos_iff.2 (sub_ne_zero.2 hne')
    have h3 := (abs_le.1 hy).1
    nlinarith [mul_pos h2 h2]

/-- The banana valley `f(x, y) = (1 - x)² + 100 (y - x²)²` has exactly one flat spot in the
whole plane: its gradient is zero at `(1, 1)` and nowhere else. -/
theorem banana_only_flat_spot (p : ℝ × ℝ) :
    fderiv ℝ (fun q : ℝ × ℝ => (1 - q.1) ^ 2 + 100 * (q.2 - q.1 ^ 2) ^ 2) p = 0 ↔
      p = (1, 1) := by
  have hD : HasFDerivAt (fun q : ℝ × ℝ => (1 - q.1) ^ 2 + 100 * (q.2 - q.1 ^ 2) ^ 2)
      ((-2 * (1 - p.1) - 400 * p.1 * (p.2 - p.1 ^ 2)) • ContinuousLinearMap.fst ℝ ℝ ℝ +
        (200 * (p.2 - p.1 ^ 2)) • ContinuousLinearMap.snd ℝ ℝ ℝ) p := by
    have hfst : HasFDerivAt (fun q : ℝ × ℝ => q.1) (ContinuousLinearMap.fst ℝ ℝ ℝ) p :=
      hasFDerivAt_fst
    have hsnd : HasFDerivAt (fun q : ℝ × ℝ => q.2) (ContinuousLinearMap.snd ℝ ℝ ℝ) p :=
      hasFDerivAt_snd
    have := (((hasFDerivAt_const (1:ℝ) p).sub hfst).pow 2).add
      (((hsnd.sub (hfst.pow 2)).pow 2).const_mul 100)
    convert this using 1
    ext v <;> simp <;> ring
  rw [hD.fderiv]
  constructor
  · intro h
    have e1 := congrArg (fun L : ℝ × ℝ →L[ℝ] ℝ => L (1, 0)) h
    have e2 := congrArg (fun L : ℝ × ℝ →L[ℝ] ℝ => L (0, 1)) h
    simp at e1 e2
    have hp2 : p.2 = p.1 ^ 2 := by linarith
    rw [hp2, sub_self] at e1
    have hp1 : p.1 = 1 := by linarith
    ext
    · exact hp1
    · rw [hp2, hp1]; norm_num
  · rintro rfl
    ext v <;> simp

/-- The banana's flat spot is its global minimum: `f(1, 1) = 0`, and every other point of the
plane is strictly higher. -/
theorem banana_global_minimum :
    (fun q : ℝ × ℝ => (1 - q.1) ^ 2 + 100 * (q.2 - q.1 ^ 2) ^ 2) (1, 1) = 0 ∧
      ∀ p : ℝ × ℝ, p ≠ (1, 1) → 0 < (1 - p.1) ^ 2 + 100 * (p.2 - p.1 ^ 2) ^ 2 := by
  refine ⟨by norm_num, fun p hp => ?_⟩
  by_contra hle
  push Not at hle
  have ha : (1 - p.1) ^ 2 = 0 := by nlinarith [sq_nonneg (1 - p.1), sq_nonneg (p.2 - p.1 ^ 2)]
  have hb : (p.2 - p.1 ^ 2) ^ 2 = 0 := by nlinarith [sq_nonneg (1 - p.1), sq_nonneg (p.2 - p.1 ^ 2)]
  have h1 : p.1 = 1 := by nlinarith [pow_eq_zero_iff (n := 2) (a := 1 - p.1) two_ne_zero |>.1 ha]
  have h2 : p.2 = p.1 ^ 2 := by nlinarith [pow_eq_zero_iff (n := 2) (a := p.2 - p.1 ^ 2) two_ne_zero |>.1 hb]
  apply hp
  ext
  · exact h1
  · rw [h2, h1]; norm_num

-- The classic start (-1.2, 1) = (-6/5, 1) sits at height 24.2 = 121/5.
example : (1 - (-6 / 5 : ℚ)) ^ 2 + 100 * (1 - (-6 / 5 : ℚ) ^ 2) ^ 2 = 121 / 5 := by norm_num
-- At (1, 1): slope in y is 200(1 - 1²) = 0, slope in x is -2(1 - 1) - 400·1·(1 - 1²) = 0, height 0.
example : (200 : ℤ) * (1 - 1 ^ 2) = 0 ∧ -2 * (1 - 1) - 400 * 1 * (1 - 1 ^ 2) = (0 : ℤ) := by decide
example : (1 - 1 : ℤ) ^ 2 + 100 * (1 - 1 ^ 2) ^ 2 = 0 := by decide
-- Hessian entries at (1, 1): 1200x² - 400y + 2 = 802, -400x = -400, 2·100 = 200.
example : (1200 : ℤ) * 1 ^ 2 - 400 * 1 + 2 = 802 ∧ (-400 : ℤ) * 1 = -400 ∧ (2 : ℤ) * 100 = 200 := by
  decide
-- Trace 1002 and determinant 802·200 - 400² = 400.
example : (802 : ℤ) + 200 = 1002 ∧ (802 : ℤ) * 200 - 400 ^ 2 = 400 := by decide
-- Pivots 802 and 200 - 400²/802 = 400/802, both above zero.
example : (200 : ℚ) - 400 ^ 2 / 802 = 400 / 802 ∧ (0 : ℚ) < 802 ∧ (0 : ℚ) < 400 / 802 := by norm_num
-- Pivot form: 802·u₁² + (400/802)·u₂² with u = Lᵀd, L = [[1, 0], [-400/802, 1]], equals dᵀHd.
example (d₁ d₂ : ℚ) :
    802 * (d₁ - 400 / 802 * d₂) ^ 2 + 400 / 802 * d₂ ^ 2 =
      802 * d₁ ^ 2 + 2 * (-400) * d₁ * d₂ + 200 * d₂ ^ 2 := by ring
-- Eigenvalues are roots of λ² - 1002λ + 400; the discriminant 1002² - 4·400 is positive.
example : (1002 : ℤ) ^ 2 - 4 * 400 = 1002404 ∧ (0 : ℤ) < 1002404 := by decide
-- x² - y⁴ at (0, 1/10): height -1/10000, below the height 0 at the origin.
example : (0 : ℚ) ^ 2 - (1 / 10) ^ 4 = -1 / 10000 := by norm_num
-- x² - y² - z²: Hessian diag(2, -2, -2) has determinant 8 and top-left entry 2, yet pivots 2, -2, -2.
example : (2 : ℤ) * (-2) * (-2) = 8 := by decide
example : (0 : ℚ) ^ 2 - (1 / 10) ^ 2 - 0 ^ 2 = -1 / 100 := by norm_num
-- With wall steepness b the Hessian entries are 12b·x² - 4b·y + 2, -4b·x and 2b; at b = 1 and
-- (1, 1) they are 10, -4 and 2, with trace 12 and determinant 10·2 - 4² = 4.
example : (12 : ℤ) * 1 * 1 ^ 2 - 4 * 1 * 1 + 2 = 10 ∧ (-4 : ℤ) * 1 * 1 = -4 ∧ (2 : ℤ) * 1 = 2 := by
  decide
example : (10 : ℤ) + 2 = 12 ∧ (10 : ℤ) * 2 - 4 ^ 2 = 4 := by decide

#print axioms optimality_conditions
#print axioms banana_only_flat_spot
#print axioms banana_global_minimum
