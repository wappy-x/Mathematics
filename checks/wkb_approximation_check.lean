-- WKB: the WKB wave q^(-1/4) sin(λ S) solves y'' + λ² q y = 0 exactly up to the dropped term ((5/16)(q'/q)² − (1/4) q''/q) y, it fits both fixed ends exactly when λ S(1) = nπ, and the wound string has phase length 3/2 and mean dropped term −3/16.
import Mathlib.Analysis.SpecialFunctions.Pow.Deriv
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.Tactic.NormNum

open Real

/-! The mode equation is `y'' + λ² q(x) y = 0` on `[0, 1]` with `y(0) = y(1) = 0`; `λ` is written
`lam`. The card's conditions "no sudden jumps" and "the coefficient stays positive" are taken as:
`q` is twice continuously differentiable and positive on an open interval `(a, b)` that contains
`[0, 1]`. The phase integral is `S(x) = ∫₀ˣ √q`, and the WKB wave is `y = q^(-1/4) sin(λ S)`.
"Slowly changing" and "large eigenvalue" are what make the dropped term small; they are not
needed for the exact statements below, and the size of the error itself stays numeric. -/

lemma wkb_phase_hasDerivAt (q : ℝ → ℝ) (a b : ℝ) (ha : a < 0) (hb : 1 < b)
    (hc : ContinuousOn q (Set.Ioo a b)) (x : ℝ) (hx : x ∈ Set.Ioo a b) :
    HasDerivAt (fun x => ∫ t in (0 : ℝ)..x, √(q t)) (√(q x)) x := by
  have hc' : ContinuousOn (fun t => √(q t)) (Set.Ioo a b) := hc.sqrt
  apply intervalIntegral.integral_hasDerivAt_right
  · apply (hc'.mono _).intervalIntegrable
    intro t ht
    rw [Set.mem_uIcc] at ht
    constructor <;> rcases ht with ⟨h1, h2⟩ | ⟨h1, h2⟩ <;> linarith [hx.1, hx.2]
  · exact hc'.stronglyMeasurableAtFilter isOpen_Ioo x hx
  · exact hc'.continuousAt (isOpen_Ioo.mem_nhds hx)

#print axioms wkb_phase_hasDerivAt

/-- Steps 1 and 3, the WKB wave and the term it drops. Let `q` be twice continuously
differentiable and positive on an open interval `(a, b)` containing `[0, 1]`. Put
`S(x) = ∫₀ˣ √q(t) dt` (the phase integral) and `y(x) = q(x)^(-1/4) sin(λ S(x))` (the WKB wave:
phase from the eikonal equation `S'² = q`, amplitude from the transport equation, `A²√q`
constant). Then on `(a, b)` the WKB wave solves the mode equation exactly except for one
leftover term: `y'' + λ² q y = ((5/16)(q'/q)² − (1/4) q''/q) y`. The leftover has no `λ` in
front, so beside the kept term `λ² q y` it is of the size of the slowness ratio squared,
`r² = (q'/(λ q^(3/2)))²`: everything WKB gets wrong comes from it. -/
theorem wkb_wave_solves_up_to_dropped_term (q : ℝ → ℝ) (a b lam : ℝ)
    (ha : a < 0) (hb : 1 < b)
    (hq : ContDiffOn ℝ 2 q (Set.Ioo a b))
    (hpos : ∀ x ∈ Set.Ioo a b, 0 < q x)
    (S y : ℝ → ℝ)
    (hS : S = fun x => ∫ t in (0 : ℝ)..x, √(q t))
    (hy : y = fun x => q x ^ (-(1 / 4 : ℝ)) * sin (lam * S x)) :
    ∀ x ∈ Set.Ioo a b,
      deriv (deriv y) x + lam ^ 2 * q x * y x =
        (5 / 16 * (deriv q x / q x) ^ 2 - 1 / 4 * deriv (deriv q) x / q x) * y x := by
  intro x hx
  have hopen : IsOpen (Set.Ioo a b) := isOpen_Ioo
  have h11 : ContDiffOn ℝ (1 + 1) q (Set.Ioo a b) := by rw [one_add_one_eq_two]; exact hq
  obtain ⟨hdq, -, hdq2⟩ := (contDiffOn_succ_iff_deriv_of_isOpen hopen).1 h11
  have hdq2' : DifferentiableOn ℝ (deriv q) (Set.Ioo a b) := hdq2.differentiableOn one_ne_zero
  have hSd : ∀ t ∈ Set.Ioo a b, HasDerivAt S (√(q t)) t := by
    intro t ht
    rw [hS]
    exact wkb_phase_hasDerivAt q a b ha hb hdq.continuousOn t ht
  have hy1 : ∀ t ∈ Set.Ioo a b, HasDerivAt y (q t ^ (-(1/4:ℝ)) *
      (-(1/4) * deriv q t / q t * sin (lam * S t) + lam * √(q t) * cos (lam * S t))) t := by
    intro t ht
    have hqt := hpos t ht
    have h1 : HasDerivAt q (deriv q t) t :=
      ((hdq t ht).differentiableAt (hopen.mem_nhds ht)).hasDerivAt
    have hg := h1.rpow_const (p := -(1/4:ℝ)) (Or.inl hqt.ne')
    have := hg.mul (((hSd t ht).const_mul lam).sin)
    rw [hy]
    convert this using 1
    rw [Real.rpow_sub_one hqt.ne']
    field_simp
  have hev : deriv y =ᶠ[nhds x] (fun t => q t ^ (-(1/4:ℝ)) *
      (-(1/4) * deriv q t / q t * sin (lam * S t) + lam * √(q t) * cos (lam * S t))) :=
    Filter.eventually_of_mem (hopen.mem_nhds hx) (fun t ht => (hy1 t ht).deriv)
  rw [hev.deriv_eq]
  have hqx := hpos x hx
  have h1 : HasDerivAt q (deriv q x) x :=
    ((hdq x hx).differentiableAt (hopen.mem_nhds hx)).hasDerivAt
  have h2 : HasDerivAt (deriv q) (deriv (deriv q) x) x :=
    ((hdq2' x hx).differentiableAt (hopen.mem_nhds hx)).hasDerivAt
  have hG := h1.rpow_const (p := -(1/4:ℝ)) (Or.inl hqx.ne')
  have hA := ((h2.const_mul (-(1/4:ℝ))).div h1 hqx.ne').mul (((hSd x hx).const_mul lam).sin)
  have hB := ((h1.sqrt hqx.ne').const_mul lam).mul (((hSd x hx).const_mul lam).cos)
  have hall : HasDerivAt (fun t => q t ^ (-(1/4:ℝ)) *
      (-(1/4) * deriv q t / q t * sin (lam * S t) + lam * √(q t) * cos (lam * S t))) _ x :=
    hG.mul (hA.add hB)
  rw [hall.deriv, hy]
  simp only [Pi.div_apply]
  rw [Real.rpow_sub_one hqx.ne']
  have hr : √(q x) * √(q x) = q x := Real.mul_self_sqrt hqx.le
  have hr0 : √(q x) ≠ 0 := (Real.sqrt_pos.2 hqx).ne'
  generalize q x ^ (-(1/4:ℝ)) = G
  generalize √(q x) = r at hr hr0 ⊢
  generalize q x = Q at hr hqx ⊢
  subst hr
  field_simp
  ring

/-- Step 2, the eigenvalue rule. With `q` as above and `λ > 0`, the WKB wave
`y = q^(-1/4) sin(λ S)` always vanishes at the left end, and it vanishes at the right end
exactly when the string holds a whole number of half waves in its phase length:
`y(1) = 0` if and only if `λ = nπ / S(1)` for some mode number `n ≥ 1`. -/
theorem wkb_eigenvalue_rule (q : ℝ → ℝ) (a b lam : ℝ)
    (ha : a < 0) (hb : 1 < b)
    (hq : ContDiffOn ℝ 2 q (Set.Ioo a b))
    (hpos : ∀ x ∈ Set.Ioo a b, 0 < q x)
    (hlam : 0 < lam)
    (S y : ℝ → ℝ)
    (hS : S = fun x => ∫ t in (0 : ℝ)..x, √(q t))
    (hy : y = fun x => q x ^ (-(1 / 4 : ℝ)) * sin (lam * S x)) :
    y 0 = 0 ∧ (y 1 = 0 ↔ ∃ n : ℕ, 0 < n ∧ lam = n * π / S 1) := by
  have hS1 : 0 < S 1 := by
    rw [hS]
    have hc : ContinuousOn (fun t => √(q t)) (Set.Ioo a b) := hq.continuousOn.sqrt
    apply intervalIntegral.intervalIntegral_pos_of_pos_on
    · apply (hc.mono _).intervalIntegrable
      intro t ht
      rw [Set.uIcc_of_le zero_le_one] at ht
      exact ⟨by linarith [ht.1], by linarith [ht.2]⟩
    · intro t ht
      exact Real.sqrt_pos.2 (hpos t ⟨by linarith [ht.1], by linarith [ht.2]⟩)
    · norm_num
  have hq1 : 0 < q 1 ^ (-(1/4:ℝ)) := Real.rpow_pos_of_pos (hpos 1 ⟨by linarith, hb⟩) _
  refine ⟨?_, ?_⟩
  · rw [hy, hS]
    simp
  · rw [hy]
    simp only
    rw [mul_eq_zero, or_iff_right hq1.ne', Real.sin_eq_zero_iff]
    constructor
    · rintro ⟨k, hk⟩
      have hprod : 0 < (k : ℝ) * π := by rw [hk]; exact mul_pos hlam hS1
      have hkpos : 0 < (k : ℝ) := by
        by_contra h
        push Not at h
        nlinarith [pi_pos]
      have hk0 : 0 < k := by exact_mod_cast hkpos
      refine ⟨k.toNat, by omega, ?_⟩
      have hcast : ((k.toNat : ℕ) : ℝ) = (k : ℝ) := by exact_mod_cast Int.toNat_of_nonneg hk0.le
      rw [hcast, hk]
      field_simp
    · rintro ⟨n, -, hn⟩
      refine ⟨n, ?_⟩
      rw [hn]
      push_cast
      field_simp

/-- The wound string, `q(x) = (1 + x)²`. Its phase length is `S(1) = ∫₀¹ (1 + x) dx = 3/2`, so
WKB gives `λ_n ≈ nπ/1.5`. Its dropped term, written in the phase variable, is
`Q = −(3/4)(1 + x)^(-4)`, and its mean along the phase length,
`(1/S(1)) ∫₀¹ Q(x) √q(x) dx`, is `−3/16`: the first correction `λ_n² ≈ (nπ/1.5)² − 3/16`. -/
theorem wound_string_phase_length_and_mean_dropped_term :
    (∫ x in (0 : ℝ)..1, √((1 + x) ^ 2)) = 3 / 2 ∧
      1 / (3 / 2 : ℝ) * (∫ x in (0 : ℝ)..1, -(3 / 4) / (1 + x) ^ 4 * √((1 + x) ^ 2)) = -3 / 16 := by
  have hpos : ∀ x ∈ Set.uIcc (0:ℝ) 1, 0 < 1 + x := by
    intro x hx
    rw [Set.uIcc_of_le zero_le_one] at hx
    linarith [hx.1]
  have hcong : Set.EqOn (fun x : ℝ => √((1 + x) ^ 2)) (fun x => 1 + x) (Set.uIcc 0 1) := by
    intro x hx
    exact Real.sqrt_sq (hpos x hx).le
  have hcong2 : Set.EqOn (fun x : ℝ => -(3 / 4) / (1 + x) ^ 4 * √((1 + x) ^ 2))
      (fun x => -(3 / 4) / (1 + x) ^ 3) (Set.uIcc 0 1) := by
    intro x hx
    have h := hpos x hx
    simp only
    rw [Real.sqrt_sq h.le]
    field_simp
  constructor
  · rw [intervalIntegral.integral_congr hcong]
    rw [intervalIntegral.integral_add intervalIntegrable_const intervalIntegral.intervalIntegrable_id]
    simp
    norm_num
  · rw [intervalIntegral.integral_congr hcong2]
    have hderiv : ∀ x ∈ Set.uIcc (0:ℝ) 1,
        HasDerivAt (fun x : ℝ => 3 / 8 * ((1 + x) ^ 2)⁻¹) (-(3 / 4) / (1 + x) ^ 3) x := by
      intro x hx
      have h := hpos x hx
      have h1 : HasDerivAt (fun y : ℝ => 3 / 8 * ((1 + y) ^ 2)⁻¹) _ x :=
        ((((hasDerivAt_id x).const_add 1).pow 2).inv
          (by simp only [Pi.pow_apply, id]; positivity)).const_mul (3 / 8 : ℝ)
      convert h1 using 1
      simp only [Pi.pow_apply, id]
      field_simp
      ring
    have hint : IntervalIntegrable (fun x : ℝ => -(3 / 4) / (1 + x) ^ 3) MeasureTheory.volume 0 1 := by
      apply ContinuousOn.intervalIntegrable
      apply ContinuousOn.div continuousOn_const (by fun_prop)
      intro x hx
      exact (pow_pos (hpos x hx) 3).ne'
    rw [intervalIntegral.integral_eq_sub_of_hasDerivAt hderiv hint]
    norm_num

-- Phase length of the wound string by hand: ∫₀¹ (1 + x) dx = 1 + 1/2 = 3/2.
example : (1 : ℚ) + 1 / 2 = 3 / 2 := by norm_num
-- Mean of Q: (1/1.5) · (−3/4) · (3/8) = −3/16, with ∫₀¹ (1 + x)^(-3) dx = 1/2 − 1/8 = 3/8.
example : (1 : ℚ) / 2 - 1 / 8 = 3 / 8 ∧ 1 / (3 / 2 : ℚ) * (-3 / 4) * (3 / 8) = -3 / 16 := by norm_num
-- The WKB overshoot: λ ≈ nπ/S − (3/16) S/(2nπ), and (3/16) · 1.5 / 2 = 9/64, so the error is 9/(64 nπ).
example : (3 / 16 : ℚ) * (3 / 2) / 2 = 9 / 64 := by norm_num
-- The residual coefficient for q = (1 + x)²: (5/16)·4 − (1/4)·2 = 3/4, so g''/g = (3/4)/(1 + x)²,
-- and Q = −q^(-1) · g''/g = −(3/4)(1 + x)^(-4).
example : (5 / 16 : ℚ) * 4 - 1 / 4 * 2 = 3 / 4 := by norm_num

#print axioms wkb_wave_solves_up_to_dropped_term
#print axioms wkb_eigenvalue_rule
#print axioms wound_string_phase_length_and_mean_dropped_term
