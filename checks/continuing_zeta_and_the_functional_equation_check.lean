-- Continuing zeta: the alternating series eta converges to (1 - 2^(1-s)) ζ(s) for every s with positive real part except 1, ζ has a simple pole at 1 with residue 1, and ζ(s) = 2^s π^(s-1) sin(πs/2) Γ(1-s) ζ(1-s) away from s = 0, 1, 2, ….
import Mathlib.NumberTheory.LSeries.RiemannZeta
import Mathlib.NumberTheory.LSeries.HurwitzZetaValues
import Mathlib.NumberTheory.Harmonic.ZetaAsymp

set_option autoImplicit false

open Complex Filter Topology Real

lemma eta_aux_cpow_diff_le (x : ℝ) (hx : 1 ≤ x) (s : ℂ) (hs : 0 ≤ s.re) :
    ‖(x : ℂ) ^ (-s) - ((x + 1 : ℝ) : ℂ) ^ (-s)‖ ≤ ‖s‖ * x ^ (-(s.re + 1)) := by
  rcases eq_or_ne s 0 with rfl | hs0
  · simp
  have hneg : -s ≠ 0 := neg_ne_zero.mpr hs0
  have hderiv : ∀ t ∈ Set.Icc x (x + 1), HasDerivWithinAt (fun y : ℝ => (y : ℂ) ^ (-s))
      (-s * (t : ℂ) ^ (-s - 1)) (Set.Icc x (x + 1)) t := by
    intro t ht
    have ht0 : t ≠ 0 := by linarith [ht.1]
    exact (hasDerivAt_ofReal_cpow_const ht0 hneg).hasDerivWithinAt
  have hbound : ∀ t ∈ Set.Ico x (x + 1), ‖-s * (t : ℂ) ^ (-s - 1)‖ ≤ ‖s‖ * x ^ (-(s.re + 1)) := by
    intro t ht
    have ht0 : 0 < t := by linarith [ht.1]
    rw [norm_mul, norm_neg, norm_cpow_eq_rpow_re_of_pos ht0]
    gcongr
    have : (-s - 1).re = -(s.re + 1) := by simp; ring
    rw [this]
    exact Real.rpow_le_rpow_of_nonpos (by linarith) ht.1 (by linarith)
  have := norm_image_sub_le_of_norm_deriv_le_segment' hderiv hbound (x + 1)
    ⟨by linarith, le_rfl⟩
  rw [norm_sub_rev] at this
  simpa using this

#print axioms eta_aux_cpow_diff_le

lemma eta_aux_pair (k : ℕ) (s : ℂ) :
    (-1 : ℂ) ^ (2 * k) / (((2 * k : ℕ) : ℂ) + 1) ^ s
      + (-1 : ℂ) ^ (2 * k + 1) / (((2 * k + 1 : ℕ) : ℂ) + 1) ^ s
      = (((2 * k + 1 : ℝ)) : ℂ) ^ (-s) - (((2 * k + 1 : ℝ) + 1 : ℝ) : ℂ) ^ (-s) := by
  simp only [pow_succ, pow_mul, mul_neg, mul_one, cpow_neg]
  push_cast
  ring_nf

#print axioms eta_aux_pair

lemma eta_aux_pair_bound (k : ℕ) (s : ℂ) {δ : ℝ} (hδ : 0 ≤ δ) (hs : δ ≤ s.re) :
    ‖(-1 : ℂ) ^ (2 * k) / (((2 * k : ℕ) : ℂ) + 1) ^ s
      + (-1 : ℂ) ^ (2 * k + 1) / (((2 * k + 1 : ℕ) : ℂ) + 1) ^ s‖
      ≤ ‖s‖ * ((k : ℝ) + 1) ^ (-(δ + 1)) := by
  rw [eta_aux_pair]
  have hk : (1 : ℝ) ≤ 2 * k + 1 := by have := k.cast_nonneg (α := ℝ); linarith
  refine (eta_aux_cpow_diff_le _ hk s (hδ.trans hs)).trans ?_
  gcongr
  calc ((2 * k + 1 : ℝ)) ^ (-(s.re + 1)) ≤ ((k : ℝ) + 1) ^ (-(s.re + 1)) :=
        Real.rpow_le_rpow_of_nonpos (by positivity) (by linarith) (by linarith)
    _ ≤ ((k : ℝ) + 1) ^ (-(δ + 1)) :=
        Real.rpow_le_rpow_of_exponent_le (by linarith) (by linarith)

#print axioms eta_aux_pair_bound

lemma eta_aux_summable_rpow {δ : ℝ} (hδ : 0 < δ) :
    Summable (fun k : ℕ => ((k : ℝ) + 1) ^ (-(δ + 1))) := by
  have := (summable_nat_add_iff 1).mpr (Real.summable_nat_rpow.mpr (by linarith : -(δ + 1) < -1))
  simpa using this

#print axioms eta_aux_summable_rpow

lemma eta_aux_summable_pair (s : ℂ) (hs : 0 < s.re) :
    Summable (fun k : ℕ => (-1 : ℂ) ^ (2 * k) / (((2 * k : ℕ) : ℂ) + 1) ^ s
      + (-1 : ℂ) ^ (2 * k + 1) / (((2 * k + 1 : ℕ) : ℂ) + 1) ^ s) :=
  Summable.of_norm_bounded ((eta_aux_summable_rpow hs).mul_left ‖s‖)
    (fun k => eta_aux_pair_bound k s hs.le le_rfl)

#print axioms eta_aux_summable_pair

lemma eta_aux_differentiableOn :
    DifferentiableOn ℂ (fun s : ℂ => ∑' k : ℕ, ((-1 : ℂ) ^ (2 * k) / (((2 * k : ℕ) : ℂ) + 1) ^ s
      + (-1 : ℂ) ^ (2 * k + 1) / (((2 * k + 1 : ℕ) : ℂ) + 1) ^ s)) {s : ℂ | 0 < s.re} := by
  intro s0 hs0
  have hs0' : 0 < s0.re := hs0
  set δ : ℝ := s0.re / 2 with hδ
  set R : ℝ := ‖s0‖ + 1 with hR
  set W : Set ℂ := {s : ℂ | δ < s.re} ∩ {s : ℂ | ‖s‖ < R} with hW
  have hWo : IsOpen W :=
    (isOpen_lt continuous_const continuous_re).inter (isOpen_lt continuous_norm continuous_const)
  have hδpos : 0 < δ := by positivity
  have hdiff : DifferentiableOn ℂ (fun s : ℂ => ∑' k : ℕ, ((-1 : ℂ) ^ (2 * k) / (((2 * k : ℕ) : ℂ) + 1) ^ s
      + (-1 : ℂ) ^ (2 * k + 1) / (((2 * k + 1 : ℕ) : ℂ) + 1) ^ s)) W := by
    refine Complex.differentiableOn_tsum_of_summable_norm
      (F := fun k s => (-1 : ℂ) ^ (2 * k) / (((2 * k : ℕ) : ℂ) + 1) ^ s
        + (-1 : ℂ) ^ (2 * k + 1) / (((2 * k + 1 : ℕ) : ℂ) + 1) ^ s)
      (u := fun k : ℕ => R * ((k : ℝ) + 1) ^ (-(δ + 1)))
      ((eta_aux_summable_rpow hδpos).mul_left R) ?_ hWo ?_
    · intro k w _
      simp only [eta_aux_pair]
      apply DifferentiableAt.differentiableWithinAt
      apply DifferentiableAt.sub
      · exact DifferentiableAt.const_cpow differentiableAt_id.neg
          (Or.inl (by exact_mod_cast (by positivity : (2 * k + 1 : ℝ) ≠ 0)))
      · exact DifferentiableAt.const_cpow differentiableAt_id.neg
          (Or.inl (by exact_mod_cast (by positivity : (2 * k + 1 + 1 : ℝ) ≠ 0)))
    · intro k w hw
      refine (eta_aux_pair_bound k w hδpos.le hw.1.le).trans ?_
      gcongr
      exact hw.2.le
  have hmem : W ∈ 𝓝 s0 := hWo.mem_nhds ⟨by simp only [Set.mem_ofPred_eq]; linarith,
    by simp only [Set.mem_ofPred_eq]; linarith⟩
  exact (hdiff.differentiableAt hmem).differentiableWithinAt

#print axioms eta_aux_differentiableOn

lemma eta_aux_gt_one (s : ℂ) (hs : 1 < s.re) :
    ∑' k : ℕ, ((-1 : ℂ) ^ (2 * k) / (((2 * k : ℕ) : ℂ) + 1) ^ s
      + (-1 : ℂ) ^ (2 * k + 1) / (((2 * k + 1 : ℕ) : ℂ) + 1) ^ s)
      = (1 - (2 : ℂ) ^ (1 - s)) * riemannZeta s := by
  set f : ℕ → ℂ := fun n => 1 / ((n : ℂ) + 1) ^ s with hf_def
  have hf : Summable f := by
    have := (summable_nat_add_iff 1).mpr (Complex.summable_one_div_nat_cpow.mpr hs)
    simpa [f] using this
  have hz : riemannZeta s = ∑' n, f n := zeta_eq_tsum_one_div_nat_add_one_cpow hs
  have he : HasSum (fun k => f (2 * k)) (∑' k, f (2 * k)) :=
    (hf.comp_injective (mul_right_injective₀ (two_ne_zero' ℕ))).hasSum
  have ho : HasSum (fun k => f (2 * k + 1)) (∑' k, f (2 * k + 1)) :=
    (hf.comp_injective ((add_left_injective 1).comp (mul_right_injective₀ (two_ne_zero' ℕ)))).hasSum
  have hsum : riemannZeta s = ∑' k, f (2 * k) + ∑' k, f (2 * k + 1) := by
    rw [hz]; exact (he.even_add_odd ho).tsum_eq
  have hodd : ∑' k, f (2 * k + 1) = (2 : ℂ) ^ (-s) * riemannZeta s := by
    rw [hz, ← tsum_mul_left]
    congr 1 with k
    simp only [f]
    have : ((2 * k + 1 : ℕ) : ℂ) + 1 = (2 : ℕ) * ((k + 1 : ℕ) : ℂ) := by push_cast; ring
    rw [this, natCast_mul_natCast_cpow, cpow_neg]
    push_cast
    field_simp
  have hpair : (fun k : ℕ => (-1 : ℂ) ^ (2 * k) / (((2 * k : ℕ) : ℂ) + 1) ^ s
      + (-1 : ℂ) ^ (2 * k + 1) / (((2 * k + 1 : ℕ) : ℂ) + 1) ^ s)
      = fun k => f (2 * k) - f (2 * k + 1) := by
    funext k
    simp only [f, pow_succ, pow_mul]
    push_cast
    ring
  rw [hpair, (he.sub ho).tsum_eq]
  have h2 : (2 : ℂ) ^ (1 - s) = 2 * (2 : ℂ) ^ (-s) := by
    rw [sub_eq_add_neg, cpow_add _ _ two_ne_zero, cpow_one]
  rw [h2]
  linear_combination -hsum - 2 * hodd

#print axioms eta_aux_gt_one

lemma eta_aux_eq (s : ℂ) (hs : 0 < s.re) (hs1 : s ≠ 1) :
    ∑' k : ℕ, ((-1 : ℂ) ^ (2 * k) / (((2 * k : ℕ) : ℂ) + 1) ^ s
      + (-1 : ℂ) ^ (2 * k + 1) / (((2 * k + 1 : ℕ) : ℂ) + 1) ^ s)
      = (1 - (2 : ℂ) ^ (1 - s)) * riemannZeta s := by
  set U : Set ℂ := {s : ℂ | 0 < s.re} with hU
  have hUo : IsOpen U := isOpen_lt continuous_const continuous_re
  have hUc : IsPreconnected U := (convex_halfSpace_re_gt 0).isPreconnected
  set F : ℂ → ℂ := fun s : ℂ => ∑' k : ℕ, ((-1 : ℂ) ^ (2 * k) / (((2 * k : ℕ) : ℂ) + 1) ^ s
      + (-1 : ℂ) ^ (2 * k + 1) / (((2 * k + 1 : ℕ) : ℂ) + 1) ^ s) with hF
  have hH : AnalyticOnNhd ℂ (fun s => (s - 1) * F s) U :=
    ((differentiableOn_id.sub_const 1).mul eta_aux_differentiableOn).analyticOnNhd hUo
  have hG : AnalyticOnNhd ℂ (fun s => (1 - (2 : ℂ) ^ (1 - s)) * riemannZeta₁ s) U := by
    refine (Differentiable.differentiableOn ?_).analyticOnNhd hUo
    refine Differentiable.mul ?_ differentiable_riemannZeta₁
    refine (differentiable_const _).sub ?_
    exact fun w => ((differentiableAt_const _).sub differentiableAt_id).const_cpow
      (Or.inl two_ne_zero)
  have heq : (fun s => (s - 1) * F s) =ᶠ[𝓝 2]
      (fun s => (1 - (2 : ℂ) ^ (1 - s)) * riemannZeta₁ s) := by
    filter_upwards [(isOpen_lt continuous_const continuous_re).mem_nhds
      (show (1 : ℝ) < (2 : ℂ).re by norm_num)] with w hw
    have hw1 : w ≠ 1 := by rintro rfl; norm_num at hw
    have hw1' : w - 1 ≠ 0 := sub_ne_zero.mpr hw1
    simp only [hF]
    rw [eta_aux_gt_one w hw, riemannZeta_eq_inv_sub_mul hw1]
    field_simp
  have := hH.eqOn_of_preconnected_of_eventuallyEq hG hUc (show (2 : ℂ) ∈ U by simp [U]) heq hs
  have hs1' : s - 1 ≠ 0 := sub_ne_zero.mpr hs1
  simp only at this
  rw [riemannZeta_eq_inv_sub_mul hs1]
  have h' : F s = (s - 1)⁻¹ * ((1 - (2 : ℂ) ^ (1 - s)) * riemannZeta₁ s) := by
    rw [← this]; field_simp
  rw [show (∑' k : ℕ, ((-1 : ℂ) ^ (2 * k) / (((2 * k : ℕ) : ℂ) + 1) ^ s
      + (-1 : ℂ) ^ (2 * k + 1) / (((2 * k + 1 : ℕ) : ℂ) + 1) ^ s)) = F s from rfl, h']
  ring

#print axioms eta_aux_eq

/-- The alternating series continues zeta: for every complex `s` with `Re s > 0` and `s ≠ 1`,
the partial sums of `η(s) = 1 - 1/2^s + 1/3^s - …` converge, and their limit is
`(1 - 2^(1-s)) ζ(s)`. So `ζ(s) = η(s) / (1 - 2^(1-s))` wherever the divisor is not 0, and at the
divisor's other zeros `1 + 2πik / ln 2` (`k ≠ 0`) eta vanishes while zeta stays finite. -/
theorem eta_partial_sums_tendsto_one_sub_two_cpow_mul_riemannZeta
    (s : ℂ) (hs : 0 < s.re) (hs1 : s ≠ 1) :
    Tendsto (fun N : ℕ => ∑ n ∈ Finset.range N, (-1 : ℂ) ^ n / ((n : ℂ) + 1) ^ s) atTop
      (𝓝 ((1 - (2 : ℂ) ^ (1 - s)) * riemannZeta s)) := by
  rw [← eta_aux_eq s hs hs1]
  set b : ℕ → ℂ := fun n => (-1 : ℂ) ^ n / ((n : ℂ) + 1) ^ s with hb
  set T : ℕ → ℂ := fun K => ∑ k ∈ Finset.range K, ((-1 : ℂ) ^ (2 * k) / (((2 * k : ℕ) : ℂ) + 1) ^ s
      + (-1 : ℂ) ^ (2 * k + 1) / (((2 * k + 1 : ℕ) : ℂ) + 1) ^ s) with hT
  have hTt := (eta_aux_summable_pair s hs).hasSum.tendsto_sum_nat
  have hS2 : ∀ K, ∑ n ∈ Finset.range (2 * K), b n = T K := by
    intro K
    induction K with
    | zero => simp [T]
    | succ K ih =>
      rw [show 2 * (K + 1) = 2 * K + 1 + 1 by ring, Finset.sum_range_succ, Finset.sum_range_succ,
        ih]
      simp only [T, b, Finset.sum_range_succ, add_assoc]
  have hb0 : Tendsto (fun n => ‖b n‖) atTop (𝓝 0) := by
    have hnorm : ∀ n : ℕ, ‖b n‖ = ((n : ℝ) + 1) ^ (-s.re) := by
      intro n
      have hpos : (0 : ℝ) < (n : ℝ) + 1 := by positivity
      simp only [b, norm_div, norm_pow, norm_neg, norm_one, one_pow]
      rw [show ((n : ℂ) + 1) = (((n : ℝ) + 1 : ℝ) : ℂ) by push_cast; ring,
        norm_cpow_eq_rpow_re_of_pos hpos, Real.rpow_neg hpos.le, one_div]
    simp only [hnorm]
    exact (tendsto_rpow_neg_atTop hs).comp
      (tendsto_atTop_add_const_right _ 1 tendsto_natCast_atTop_atTop)
  have hdiv : Tendsto (fun N : ℕ => N / 2) atTop atTop :=
    tendsto_atTop_atTop.mpr fun B => ⟨2 * B, fun N hN => by omega⟩
  have hdiv2 : Tendsto (fun N : ℕ => 2 * (N / 2)) atTop atTop :=
    tendsto_atTop_atTop.mpr fun B => ⟨2 * B, fun N hN => by omega⟩
  have hrest : Tendsto (fun N => ∑ n ∈ Finset.range N, b n - T (N / 2)) atTop (𝓝 0) := by
    refine squeeze_zero_norm (fun N => ?_) (hb0.comp hdiv2)
    simp only [Function.comp_apply]
    rcases Nat.even_or_odd' N with ⟨K, rfl | rfl⟩
    · rw [show 2 * K / 2 = K by omega, hS2, sub_self, norm_zero]
      exact norm_nonneg _
    · rw [show (2 * K + 1) / 2 = K by omega, Finset.sum_range_succ, hS2, add_sub_cancel_left]
  have := (hTt.comp hdiv).add hrest
  rw [add_zero] at this
  refine this.congr fun N => ?_
  simp only [Function.comp_apply, b, T]
  ring

/-- Zeta has a simple pole at `s = 1` with residue 1: `(s - 1) ζ(s)` tends to 1 as `s → 1`. -/
theorem riemannZeta_pole_at_one_residue_one :
    Tendsto (fun s : ℂ => (s - 1) * riemannZeta s) (𝓝[≠] 1) (𝓝 1) := by
  exact riemannZeta_residue_one

/-- The functional equation, the mirror that sends `s` to `1 - s`:
`ζ(s) = 2^s π^(s-1) sin(πs/2) Γ(1-s) ζ(1-s)`, with `π` the real number pi.
The card notes that at `s = 2, 4, …` the zero of the sine and the pole of `Γ(1 - s)` must be
cancelled against each other, at `s = 3, 5, …` that pole meets a trivial zero of `ζ(1 - s)`,
and at `s = 0` the zero of the sine meets the pole of `ζ(1 - s)`; so the identity holds as
written, factor by factor, exactly at the points where no such pole occurs: every `s` that is
not a natural number `0, 1, 2, …`. -/
theorem riemannZeta_eq_mirror (s : ℂ) (hs : ∀ n : ℕ, s ≠ n) :
    riemannZeta s = 2 ^ s * (π : ℂ) ^ (s - 1) * Complex.sin (π * s / 2) * Gamma (1 - s)
      * riemannZeta (1 - s) := by
  have h1 : ∀ n : ℕ, 1 - s ≠ -n := by
    intro n h
    apply hs (n + 1)
    push_cast
    linear_combination -h
  have h2 : 1 - s ≠ 1 := by
    intro h
    apply hs 0
    push_cast
    linear_combination -h
  have key := riemannZeta_one_sub h1 h2
  rw [sub_sub_cancel] at key
  rw [key]
  have hc : Complex.cos (π * (1 - s) / 2) = Complex.sin (π * s / 2) := by
    rw [← Complex.sin_pi_div_two_sub]
    congr 1
    ring
  have hp : (2 * (π : ℂ)) ^ (-(1 - s)) = 2 ^ (s - 1) * (π : ℂ) ^ (s - 1) := by
    rw [neg_sub]
    have := mul_cpow_ofReal_nonneg (a := 2) (b := π) (by norm_num) Real.pi_pos.le (s - 1)
    push_cast at this
    exact this
  have h2s : (2 : ℂ) ^ s = 2 * 2 ^ (s - 1) := by
    rw [cpow_sub _ _ two_ne_zero, cpow_one]
    field_simp
  rw [hc, hp, h2s]
  ring

-- Worked values on the card: ζ(0) = -1/2, ζ(-1) = -1/12, ζ(2) = π^2/6, and the trivial zero at -2.
example : riemannZeta 0 = -1 / 2 := by exact riemannZeta_zero
example : riemannZeta (-1) = -1 / 12 := by
  have := riemannZeta_neg_nat_eq_bernoulli 1
  rw [bernoulli_eq_bernoulli'_of_ne_one (by decide : 2 ≠ 1), bernoulli'_two] at this
  push_cast at this
  rw [this]
  norm_num
example : riemannZeta 2 = (π : ℂ) ^ 2 / 6 := by exact riemannZeta_two
example : riemannZeta (-2) = 0 := by
  have := riemannZeta_neg_two_mul_nat_add_one 0
  push_cast at this
  simpa using this

-- Whole-number arithmetic on the card.
-- 1 + 2 + … + 100 = 5050, not -1/12.
example : ∑ i ∈ Finset.range 101, i = 5050 := by decide
-- Road two at s = -1, N = 30: the head 1 + 2 + … + 29 is 435, and 435 - 450 + 15 = 0,
-- leaving only the end term -1/12.
example : ∑ i ∈ Finset.range 30, i = 435 := by decide
example : (435 : ℤ) - 450 + 15 = 0 := by norm_num
-- The mirror at s = -1: (-1/(2π^2)) × (π^2/6) = -1/12.
example : -1 / (2 * π ^ 2) * (π ^ 2 / 6) = -1 / 12 := by
  have : π ≠ 0 := Real.pi_ne_zero
  field_simp
  ring

#print axioms eta_partial_sums_tendsto_one_sub_two_cpow_mul_riemannZeta
#print axioms riemannZeta_pole_at_one_residue_one
#print axioms riemannZeta_eq_mirror
