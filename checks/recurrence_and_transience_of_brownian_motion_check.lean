-- Brownian motion in d dimensions: the radial function phi (log of the distance in the plane, the distance to the power 2 - d above) is harmonic away from the centre, it fixes the chance of the small sphere first, and that chance tends to 1 in the plane and to (r/s)^(d-2) in three or more dimensions as the far sphere recedes.
import Mathlib.Analysis.InnerProductSpace.Harmonic.Basic
import Mathlib.Analysis.InnerProductSpace.Calculus
import Mathlib.Analysis.SpecialFunctions.Pow.Deriv
import Mathlib.Analysis.SpecialFunctions.Log.Deriv
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Order.Filter.AtTopBot.Basic

open Filter Topology InnerProductSpace

/-- The card's radial function: `φ(ρ) = ln ρ` in the plane (`d = 2`) and `φ(ρ) = ρ ^ (2 - d)`
in `d ≥ 3` dimensions. -/
noncomputable def phi (d : ℕ) (ρ : ℝ) : ℝ :=
  if d = 2 then Real.log ρ else ρ ^ ((2 : ℤ) - d)

open Laplacian in
/-- Laplacian of `z ↦ h (‖z‖ ^ 2)` away from the origin. -/
lemma lap_aux {E : Type*} [NormedAddCommGroup E] [InnerProductSpace ℝ E] [FiniteDimensional ℝ E]
    (h h' h'' : ℝ → ℝ) (hh : ∀ t, 0 < t → HasDerivAt h (h' t) t)
    (hh' : ∀ t, 0 < t → HasDerivAt h' (h'' t) t) (y : E) (hy : y ≠ 0) :
    Δ (fun z : E => h (‖z‖ ^ 2)) y =
      4 * h'' (‖y‖ ^ 2) * ‖y‖ ^ 2 + 2 * (Module.finrank ℝ E) * h' (‖y‖ ^ 2) := by
  obtain ⟨L, hL⟩ : ∃ L : E →L[ℝ] E →L[ℝ] ℝ, ∀ u v, L u v = inner ℝ u v :=
    ⟨innerSL ℝ, fun _ _ => rfl⟩
  set f := fun z : E => h (‖z‖ ^ 2) with hfdef
  set G : E → E →L[ℝ] ℝ := fun z => h' (‖z‖ ^ 2) • ((2 : ℝ) • L z) with hGdef
  have hN : ∀ z : E, HasFDerivAt (fun z : E => ‖z‖ ^ 2) ((2 : ℝ) • L z) z := by
    intro z
    have := (hasStrictFDerivAt_norm_sq z).hasFDerivAt
    convert this using 1
    ext v; simp [hL]
  have hf : ∀ z : E, z ≠ 0 → HasFDerivAt f (G z) z := by
    intro z hz
    have hz' : 0 < ‖z‖ ^ 2 := by positivity
    exact (hh _ hz').comp_hasFDerivAt z (hN z)
  have hG : HasFDerivAt G
      (h' (‖y‖ ^ 2) • ((2 : ℝ) • L)
        + (h'' (‖y‖ ^ 2) • ((2 : ℝ) • L y)).smulRight ((2 : ℝ) • L y)) y := by
    have hy' : 0 < ‖y‖ ^ 2 := by positivity
    have h1 := (hh' _ hy').comp_hasFDerivAt y (hN y)
    have h2 : HasFDerivAt (fun z : E => (2 : ℝ) • L z) ((2 : ℝ) • L) y :=
      ((2 : ℝ) • L).hasFDerivAt
    exact h1.smul h2
  have hD : fderiv ℝ (fderiv ℝ f) y = h' (‖y‖ ^ 2) • ((2 : ℝ) • L)
        + (h'' (‖y‖ ^ 2) • ((2 : ℝ) • L y)).smulRight ((2 : ℝ) • L y) := by
    have heq : fderiv ℝ f =ᶠ[𝓝 y] G := by
      filter_upwards [isOpen_ne.mem_nhds hy] with z hz
      exact (hf z hz).fderiv
    rw [heq.fderiv_eq]
    exact hG.fderiv
  rw [laplacian_eq_iteratedFDeriv_stdOrthonormalBasis]
  simp only [iteratedFDeriv_two_apply, Matrix.cons_val_zero, Matrix.cons_val_one, hD]
  set b := stdOrthonormalBasis ℝ E
  simp only [add_apply, smul_apply,
    ContinuousLinearMap.smulRight_apply, hL, smul_eq_mul, b.inner_eq_ite, ite_true]
  have hs : ∑ i, ⟪y, b i⟫_ℝ * ⟪y, b i⟫_ℝ = ‖y‖ ^ 2 := by
    have := b.sum_inner_mul_inner y y
    simp_rw [real_inner_comm y (b _)] at this ⊢
    rw [this, real_inner_self_eq_norm_sq]
  have h2 : ∑ i, h'' (‖y‖ ^ 2) * (2 * ⟪y, b i⟫_ℝ) * (2 * ⟪y, b i⟫_ℝ)
      = 4 * h'' (‖y‖ ^ 2) * ∑ i, ⟪y, b i⟫_ℝ * ⟪y, b i⟫_ℝ := by
    rw [Finset.mul_sum]; exact Finset.sum_congr rfl (fun i _ => by ring)
  rw [Finset.sum_add_distrib, h2, hs]
  simp only [Finset.sum_const, Finset.card_univ, Fintype.card_fin, nsmul_eq_mul]
  ring

/-- In `d ≥ 3` dimensions, `φ(ρ) = 1 / ρ ^ (d - 2)`. -/
lemma phi_eq_inv_pow (d : ℕ) (hd : 2 < d) (ρ : ℝ) : phi d ρ = (ρ ^ (d - 2))⁻¹ := by
  have hd2 : d ≠ 2 := by omega
  simp only [phi, hd2, ↓reduceIte]
  rw [show (2 : ℤ) - d = -((d - 2 : ℕ) : ℤ) by omega, zpow_neg, zpow_natCast]

/-- `φ` takes different values at two different positive radii. -/
lemma phi_ne_of_lt (d : ℕ) (hd : 2 ≤ d) (r R : ℝ) (hr : 0 < r) (hrR : r < R) :
    phi d R ≠ phi d r := by
  rcases eq_or_lt_of_le hd with h2 | h3
  · subst h2
    simp only [phi, ↓reduceIte]
    exact (Real.log_lt_log hr hrR).ne'
  · rw [phi_eq_inv_pow d h3, phi_eq_inv_pow d h3]
    have hk : d - 2 ≠ 0 := by omega
    have : r ^ (d - 2) < R ^ (d - 2) := pow_lt_pow_left₀ hrR hr.le hk
    exact (inv_strictAnti₀ (by positivity) this).ne

/-- Step 2 of the card: in `d ≥ 2` dimensions the function `x ↦ φ(|x|)` (the logarithm of the
distance in the plane, the distance to the power `2 - d` above) is harmonic at every point
other than the centre: it is twice continuously differentiable there and its Laplacian is 0
near that point. This is what makes `φ(|B_t|)` a fair game between the two spheres. -/
theorem radial_phi_harmonic (d : ℕ) (hd : 2 ≤ d) (x : EuclideanSpace ℝ (Fin d)) (hx : x ≠ 0) :
    HarmonicAt (fun y : EuclideanSpace ℝ (Fin d) => phi d ‖y‖) x := by
  rcases eq_or_lt_of_le hd with h2 | h3
  · subst h2
    have hfeq : (fun y : EuclideanSpace ℝ (Fin 2) => phi 2 ‖y‖) =
        fun y => Real.log (‖y‖ ^ 2) / 2 := by
      funext y; simp only [phi, ↓reduceIte, Real.log_pow]; push_cast; ring
    rw [hfeq]
    refine ⟨?_, ?_⟩
    · have : ‖x‖ ^ 2 ≠ 0 := by positivity
      exact ((Real.contDiffAt_log.2 this).comp x (contDiff_norm_sq ℝ).contDiffAt).div_const 2
    · filter_upwards [isOpen_ne.mem_nhds hx] with y hy
      have hy2 : 0 < ‖y‖ ^ 2 := by positivity
      have key := lap_aux (fun t => Real.log t / 2) (fun t => t⁻¹ / 2) (fun t => -(t ^ 2)⁻¹ / 2)
        (fun t ht => (Real.hasDerivAt_log ht.ne').div_const 2)
        (fun t ht => (hasDerivAt_inv ht.ne').div_const 2) y hy
      beta_reduce at key
      rw [key]
      simp only [finrank_euclideanSpace_fin, Pi.zero_apply]
      field_simp
      ring
  · have hd2 : d ≠ 2 := by omega
    set a : ℝ := (2 - d) / 2 with ha
    have hfeq : (fun y : EuclideanSpace ℝ (Fin d) => phi d ‖y‖) =
        fun y => (‖y‖ ^ 2) ^ a := by
      funext y
      simp only [phi, hd2, ↓reduceIte]
      rw [← Real.rpow_natCast ‖y‖ 2, ← Real.rpow_mul (norm_nonneg _),
        show ((2 : ℕ) : ℝ) * a = (((2 : ℤ) - d : ℤ) : ℝ) by rw [ha]; push_cast; ring,
        Real.rpow_intCast]
    rw [hfeq]
    refine ⟨?_, ?_⟩
    · have : ‖x‖ ^ 2 ≠ 0 := by positivity
      exact (Real.contDiffAt_rpow_const_of_ne this).comp x (contDiff_norm_sq ℝ).contDiffAt
    · filter_upwards [isOpen_ne.mem_nhds hx] with y hy
      have hy2 : 0 < ‖y‖ ^ 2 := by positivity
      have key := lap_aux (fun t => t ^ a) (fun t => a * t ^ (a - 1))
        (fun t => a * ((a - 1) * t ^ (a - 1 - 1)))
        (fun t ht => Real.hasDerivAt_rpow_const (Or.inl ht.ne'))
        (fun t ht => (Real.hasDerivAt_rpow_const (p := a - 1) (Or.inl ht.ne')).const_mul a) y hy
      beta_reduce at key
      rw [key]
      simp only [finrank_euclideanSpace_fin, Pi.zero_apply]
      rw [Real.rpow_sub_one hy2.ne' (a - 1)]
      field_simp
      rw [ha]
      ring

/-- Step 4 of the card: for a start distance `s` strictly between the target radius `r` and the
far radius `R`, the balance equation `p φ(r) + (1 - p) φ(R) = φ(s)` holds exactly when
`p = (φ(R) - φ(s)) / (φ(R) - φ(r))`, the chance of reaching the small sphere first. -/
theorem hitting_chance_balance (d : ℕ) (hd : 2 ≤ d) (r s R p : ℝ)
    (hr : 0 < r) (hrs : r < s) (hsR : s < R) :
    p * phi d r + (1 - p) * phi d R = phi d s ↔
      p = (phi d R - phi d s) / (phi d R - phi d r) := by
  have hne : phi d R - phi d r ≠ 0 := sub_ne_zero.2 (phi_ne_of_lt d hd r R hr (hrs.trans hsR))
  rw [eq_div_iff hne]
  constructor <;> intro h <;> linear_combination -h

/-- Steps 5 and 6 of the card: let the far sphere recede, `R → ∞`. The chance of reaching
radius `r` first, from distance `s > r`, tends to 1 in the plane (recurrence) and to
`(r / s) ^ (d - 2)`, which is below 1, in `d ≥ 3` dimensions (transience). -/
theorem hitting_chance_tendsto (d : ℕ) (hd : 2 ≤ d) (r s : ℝ) (hr : 0 < r) (hrs : r < s) :
    Tendsto (fun R : ℝ => (phi d R - phi d s) / (phi d R - phi d r)) atTop
      (𝓝 (if d = 2 then 1 else (r / s) ^ (d - 2))) := by
  rcases eq_or_lt_of_le hd with h2 | h3
  · subst h2
    simp only [phi, ↓reduceIte]
    have hL : Tendsto (fun R : ℝ => Real.log R - Real.log r) atTop atTop :=
      tendsto_atTop_add_const_right _ _ Real.tendsto_log_atTop
    have h0 : Tendsto (fun R : ℝ => (Real.log r - Real.log s) / (Real.log R - Real.log r)) atTop
        (𝓝 0) := tendsto_const_nhds.div_atTop hL
    have h1 := h0.const_add 1
    rw [add_zero] at h1
    refine h1.congr' ?_
    filter_upwards [hL.eventually_gt_atTop 0] with R hR
    field_simp
    ring
  · have hd2 : d ≠ 2 := by omega
    simp only [phi_eq_inv_pow d h3, hd2, ↓reduceIte]
    have hk : d - 2 ≠ 0 := by omega
    have hR : Tendsto (fun R : ℝ => (R ^ (d - 2))⁻¹) atTop (𝓝 0) :=
      tendsto_inv_atTop_zero.comp (tendsto_pow_atTop hk)
    have hs : 0 < s := hr.trans hrs
    have hrk : (0 : ℝ) - (r ^ (d - 2))⁻¹ ≠ 0 := by
      have : 0 < r ^ (d - 2) := by positivity
      simp [this.ne']
    have := (hR.sub_const ((s ^ (d - 2))⁻¹)).div (hR.sub_const ((r ^ (d - 2))⁻¹)) hrk
    have e : (r / s) ^ (d - 2) = (0 - (s ^ (d - 2))⁻¹) / (0 - (r ^ (d - 2))⁻¹) := by
      rw [zero_sub, zero_sub, neg_div_neg_eq, inv_div_inv, div_pow]
    rw [e]
    exact this

-- The card's whole-number examples, from distance 2 to a ball of radius 1 with no far sphere.
-- Space: (1/2)^(3-2) = 1/2.
example : ((1 : ℝ) / 2) ^ (3 - 2) = 1 / 2 := by norm_num
-- Four dimensions: (1/2)^(4-2) = 1/4.
example : ((1 : ℝ) / 2) ^ (4 - 2) = 1 / 4 := by norm_num
-- Space, start at 10: (1/10)^(3-2) = 1/10.
example : ((1 : ℝ) / 10) ^ (3 - 2) = 1 / 10 := by norm_num
-- In space phi is one over the distance: phi 3 2 = 1/2.
example : phi 3 2 = 1 / 2 := by norm_num [phi]

#print axioms lap_aux
#print axioms phi_eq_inv_pow
#print axioms phi_ne_of_lt
#print axioms radial_phi_harmonic
#print axioms hitting_chance_balance
#print axioms hitting_chance_tendsto
