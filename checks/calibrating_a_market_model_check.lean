-- Calibrating a market model: the caplet multiplier exists, is positive, is unique and reprices its caplet exactly; scaling a, b and d leaves every volatility unchanged; and exp(-β|Tᵢ - Tⱼ|) is a genuine correlation matrix for every β ≥ 0.
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.LinearAlgebra.Matrix.PosDef

open Real

/-- The card's "abcd" shape in time-to-fixing `τ`: `g(τ) = (a + b τ) e^{-c τ} + d`. -/
noncomputable def abcd (a b c d : ℝ) (τ : ℝ) : ℝ :=
  (a + b * τ) * Real.exp (-c * τ) + d

/-- The card's caplet multiplier `k = v √(T / ∫₀ᵀ g(T - t)² dt)`. -/
noncomputable def capletMultiplier (g : ℝ → ℝ) (v T : ℝ) : ℝ :=
  v * Real.sqrt (T / ∫ t in (0 : ℝ)..T, g (T - t) ^ 2)

lemma integral_const_mul_sq (g : ℝ → ℝ) (k T : ℝ) :
    (∫ t in (0 : ℝ)..T, (k * g (T - t)) ^ 2) = k ^ 2 * ∫ t in (0 : ℝ)..T, g (T - t) ^ 2 := by
  simp_rw [mul_pow]
  exact intervalIntegral.integral_const_mul _ _

/-- Caplets are matched exactly: for every positive caplet quote `v`, every fixing date
`T > 0` and every abcd shape `g` that is positive up to fixing, the multiplier
`k = v √(T / ∫₀ᵀ g(T - t)² dt)` is positive, makes the forward's total variance
`∫₀ᵀ (k g(T - t))² dt` equal the Black variance `v² T`, and is the only positive number
that does so. -/
theorem caplet_multiplier_exists_unique_and_exact (a b c d v T : ℝ) (hT : 0 < T) (hv : 0 < v)
    (hg : ∀ τ ∈ Set.Icc (0 : ℝ) T, 0 < abcd a b c d τ) :
    0 < capletMultiplier (abcd a b c d) v T ∧
    (∫ t in (0 : ℝ)..T, (capletMultiplier (abcd a b c d) v T * abcd a b c d (T - t)) ^ 2)
        = v ^ 2 * T ∧
    ∀ k : ℝ, 0 < k → (∫ t in (0 : ℝ)..T, (k * abcd a b c d (T - t)) ^ 2) = v ^ 2 * T →
        k = capletMultiplier (abcd a b c d) v T := by
  have hcont : Continuous (fun t => abcd a b c d (T - t) ^ 2) := by
    unfold abcd; fun_prop
  have hI : 0 < ∫ t in (0 : ℝ)..T, abcd a b c d (T - t) ^ 2 := by
    refine intervalIntegral.intervalIntegral_pos_of_pos_on
      (hcont.intervalIntegrable _ _) (fun t ht => ?_) hT
    have := hg (T - t) ⟨by linarith [ht.2], by linarith [ht.1]⟩
    positivity
  set I := ∫ t in (0 : ℝ)..T, abcd a b c d (T - t) ^ 2 with hIdef
  have hcm : 0 < capletMultiplier (abcd a b c d) v T := by
    unfold capletMultiplier
    rw [← hIdef]
    have : 0 < T / I := div_pos hT hI
    positivity
  have hsq : capletMultiplier (abcd a b c d) v T ^ 2 * I = v ^ 2 * T := by
    unfold capletMultiplier
    rw [← hIdef, mul_pow, Real.sq_sqrt (div_pos hT hI).le]
    field_simp
  refine ⟨hcm, ?_, ?_⟩
  · rw [integral_const_mul_sq, ← hIdef, hsq]
  · intro k hk hkI
    rw [integral_const_mul_sq, ← hIdef, ← hsq] at hkI
    have h2 : k ^ 2 = capletMultiplier (abcd a b c d) v T ^ 2 :=
      mul_right_cancel₀ hI.ne' hkI
    exact (pow_left_inj₀ hk.le hcm.le two_ne_zero).mp h2

/-- The overall size of the shape cancels: multiplying `a`, `b` and `d` by the same
positive number `λ` leaves the forward's actual volatility `σ(t) = k g(T - t)` unchanged
at every time `t`, because the multiplier shrinks by exactly `λ`. -/
theorem scaling_abcd_leaves_volatility_unchanged (a b c d v T lam : ℝ) (hlam : 0 < lam)
    (t : ℝ) :
    capletMultiplier (abcd (lam * a) (lam * b) c (lam * d)) v T
        * abcd (lam * a) (lam * b) c (lam * d) (T - t)
      = capletMultiplier (abcd a b c d) v T * abcd a b c d (T - t) := by
  have hscale : ∀ τ, abcd (lam * a) (lam * b) c (lam * d) τ = lam * abcd a b c d τ := by
    intro τ; unfold abcd; ring
  unfold capletMultiplier
  simp_rw [hscale]
  rw [integral_const_mul_sq, div_mul_eq_div_div_swap, Real.sqrt_div' _ (sq_nonneg lam),
    Real.sqrt_sq hlam.le]
  field_simp

lemma minKernel_quadForm_nonneg {ι : Type*} [DecidableEq ι] (T : ι → ℝ) (s : Finset ι) :
    ∀ f : ℝ → ℝ, Monotone f → (∀ i ∈ s, 0 ≤ f (T i)) → ∀ x : ι → ℝ,
      0 ≤ ∑ i ∈ s, ∑ j ∈ s, x i * x j * f (min (T i) (T j)) := by
  induction s using Finset.induction_on_min_value T with
  | empty => intro f _ _ x; simp
  | insert a s ha hmin ih =>
    intro f hf hpos x
    have hfa : 0 ≤ f (T a) := hpos a (Finset.mem_insert_self a s)
    set g : ℝ → ℝ := fun u => f u - f (T a) with hg
    have hgm : Monotone g := fun u w huw => by simp only [hg]; linarith [hf huw]
    have hgpos : ∀ i ∈ s, 0 ≤ g (T i) := fun i hi => by
      simp only [hg]; linarith [hf (hmin i hi)]
    have IH := ih g hgm hgpos x
    have h1 : ∀ j ∈ s, min (T a) (T j) = T a := fun j hj => min_eq_left (hmin j hj)
    have h2 : ∀ j ∈ s, min (T j) (T a) = T a := fun j hj => min_eq_right (hmin j hj)
    have key : ∑ i ∈ insert a s, ∑ j ∈ insert a s, x i * x j * f (min (T i) (T j))
        = f (T a) * (x a + ∑ j ∈ s, x j) ^ 2
          + ∑ i ∈ s, ∑ j ∈ s, x i * x j * g (min (T i) (T j)) := by
      have A : ∑ j ∈ s, x a * x j * f (min (T a) (T j)) = x a * f (T a) * ∑ j ∈ s, x j := by
        rw [Finset.mul_sum]
        exact Finset.sum_congr rfl fun j hj => by rw [h1 j hj]; ring
      have B : ∑ i ∈ s, x i * x a * f (min (T i) (T a)) = x a * f (T a) * ∑ j ∈ s, x j := by
        rw [Finset.mul_sum]
        exact Finset.sum_congr rfl fun j hj => by rw [h2 j hj]; ring
      have C : ∑ i ∈ s, ∑ j ∈ s, x i * x j * f (min (T i) (T j))
          = ∑ i ∈ s, ∑ j ∈ s, x i * x j * g (min (T i) (T j))
            + f (T a) * (∑ j ∈ s, x j) ^ 2 := by
        rw [sq, Finset.sum_mul_sum, Finset.mul_sum, ← Finset.sum_add_distrib]
        refine Finset.sum_congr rfl fun i _ => ?_
        rw [Finset.mul_sum, ← Finset.sum_add_distrib]
        refine Finset.sum_congr rfl fun j _ => ?_
        simp only [hg]; ring
      rw [Finset.sum_insert ha, Finset.sum_insert ha]
      simp only [Finset.sum_insert ha]
      rw [Finset.sum_add_distrib, A, B, C, min_self]
      ring
    rw [key]
    positivity

lemma exp_neg_abs_split (β a b : ℝ) :
    Real.exp (-β * |a - b|) = Real.exp (-β * a) * Real.exp (-β * b) * Real.exp (2 * β * min a b) := by
  rw [← Real.exp_add, ← Real.exp_add]
  congr 1
  rcases le_total a b with h | h
  · rw [abs_of_nonpos (by linarith), min_eq_left h]; ring
  · rw [abs_of_nonneg (by linarith), min_eq_right h]; ring

/-- For every `β ≥ 0` and any reset dates `T₀, …, Tₙ₋₁`, the matrix
`ρᵢⱼ = e^{-β |Tᵢ - Tⱼ|}` is a genuine correlation matrix: positive semidefinite with
ones on the diagonal, so every trial `β` gives a real model. -/
theorem exp_abs_decay_is_correlation_matrix (n : ℕ) (T : Fin n → ℝ) (β : ℝ) (hβ : 0 ≤ β) :
    (Matrix.of fun i j => Real.exp (-β * |T i - T j|)).PosSemidef ∧
    ∀ i, (Matrix.of fun i j => Real.exp (-β * |T i - T j|)) i i = 1 := by
  refine ⟨Matrix.PosSemidef.of_dotProduct_mulVec_nonneg ?_ ?_, ?_⟩
  · ext i j
    simp [Matrix.conjTranspose_apply, abs_sub_comm]
  · intro x
    have hf : Monotone (fun u : ℝ => Real.exp (2 * β * u)) := fun u w h => by
      apply Real.exp_le_exp.mpr
      nlinarith
    have H := minKernel_quadForm_nonneg T Finset.univ (fun u => Real.exp (2 * β * u)) hf
      (fun i _ => (Real.exp_pos _).le) (fun i => x i * Real.exp (-β * T i))
    convert H using 1
    simp only [dotProduct, Matrix.mulVec, Matrix.of_apply, star_trivial, Finset.mul_sum]
    refine Finset.sum_congr rfl fun i _ => Finset.sum_congr rfl fun j _ => ?_
    rw [exp_neg_abs_split]
    ring
  · intro i; simp

#print axioms caplet_multiplier_exists_unique_and_exact
#print axioms scaling_abcd_leaves_volatility_unchanged
#print axioms exp_abs_decay_is_correlation_matrix
#print axioms integral_const_mul_sq
#print axioms minKernel_quadForm_nonneg
#print axioms exp_neg_abs_split
