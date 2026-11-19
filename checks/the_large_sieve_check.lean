-- The large sieve: for any complex weights on N whole numbers in a row, the wave energy at all reduced fractions a/q with q ≤ Q is at most (N − 1 + Q²) times the weights' energy, and so a set that misses k_p classes mod each prime p ≤ Q has at most (N − 1 + Q²)/L members.
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.Complex.Basic
import Mathlib.NumberTheory.ArithmeticFunction.Moebius
import Mathlib.Data.Nat.PrimeFin
import Mathlib.Tactic.NormNum
import Mathlib

open Complex Finset
open Real (pi)

/-- The cosecant kernel `1 / sin (π (x r - x s))`, zero on the diagonal. -/
noncomputable def lsC {ι : Type*} [DecidableEq ι] (x : ι → ℝ) (r s : ι) : ℝ :=
  if r = s then 0 else 1 / Real.sin (pi * (x r - x s))

/-- The cotangent kernel `cos / sin` at `π (x r - x s)`, zero on the diagonal. -/
noncomputable def lsK {ι : Type*} [DecidableEq ι] (x : ι → ℝ) (r s : ι) : ℝ :=
  if r = s then 0 else Real.cos (pi * (x r - x s)) / Real.sin (pi * (x r - x s))

lemma lsC_antisymm {ι : Type*} [DecidableEq ι] (x : ι → ℝ) (r s : ι) :
    lsC x s r = - lsC x r s := by
  unfold lsC
  by_cases h : r = s
  · subst h; simp
  · rw [ite_eq_right (Ne.symm h), ite_eq_right h]
    have : pi * (x s - x r) = -(pi * (x r - x s)) := by ring
    rw [this, Real.sin_neg, div_neg]

lemma lsK_antisymm {ι : Type*} [DecidableEq ι] (x : ι → ℝ) (r s : ι) :
    lsK x s r = - lsK x r s := by
  unfold lsK
  by_cases h : r = s
  · subst h; simp
  · rw [ite_eq_right (Ne.symm h), ite_eq_right h]
    have : pi * (x s - x r) = -(pi * (x r - x s)) := by ring
    rw [this, Real.sin_neg, Real.cos_neg, div_neg]

lemma lsK_abs_le {ι : Type*} [DecidableEq ι] (x : ι → ℝ) (r s : ι) :
    |lsK x r s| ≤ |lsC x r s| := by
  unfold lsK lsC
  split_ifs
  · simp
  · rw [abs_div, abs_div, abs_one]
    exact div_le_div_of_nonneg_right (Real.abs_cos_le_one _) (abs_nonneg _)

lemma lsC_mul_lsC {ι : Type*} [DecidableEq ι] (x : ι → ℝ)
    (hsin : ∀ r s, r ≠ s → Real.sin (pi * (x r - x s)) ≠ 0) (r s t : ι) :
    lsC x r s * lsC x r t = lsC x t s * (lsK x r t - lsK x r s)
      + (if s = t then lsC x r s ^ 2 else 0) - (if r = s then lsC x t r * lsK x r t else 0)
      + (if r = t then lsC x r s * lsK x r s else 0) := by
  by_cases hrs : r = s
  · subst hrs
    by_cases hrt : r = t
    · subst hrt; simp [lsC, lsK]
    · simp [lsC, lsK, hrt, Ne.symm hrt]
  by_cases hrt : r = t
  · subst hrt
    simp [lsC, lsK, hrs, Ne.symm hrs]
  by_cases hst : s = t
  · subst hst
    simp [lsC, lsK, hrs]
    ring
  simp only [lsC, lsK, ite_eq_right hrs, ite_eq_right hrt, ite_eq_right hst, ite_eq_right (Ne.symm hst)]
  have ha := hsin r s hrs
  have hb := hsin r t hrt
  have hab := hsin t s (Ne.symm hst)
  have e : pi * (x t - x s) = pi * (x r - x s) - pi * (x r - x t) := by ring
  rw [e] at hab ⊢
  rw [Real.sin_sub] at hab ⊢
  generalize Real.sin (pi * (x r - x s)) = sa at *
  generalize Real.sin (pi * (x r - x t)) = sb at *
  generalize Real.cos (pi * (x r - x s)) = ca at *
  generalize Real.cos (pi * (x r - x t)) = cb at *
  simp only [add_zero, sub_zero]
  have hab' : sa * cb - sb * ca ≠ 0 := by rwa [mul_comm sb ca]
  field_simp

lemma ls_energy_identity {ι : Type*} [Fintype ι] [DecidableEq ι] (x : ι → ℝ)
    (hsin : ∀ r s, r ≠ s → Real.sin (pi * (x r - x s)) ≠ 0) (v : ι → ℂ) (μ : ℂ)
    (hμ : μ + (starRingEnd ℂ) μ = 0) (hv : ∀ r, ∑ s, (lsC x r s : ℂ) * v s = μ * v r) :
    ∑ r, (∑ s, (lsC x r s : ℂ) * v s) * (starRingEnd ℂ) (∑ t, (lsC x r t : ℂ) * v t)
      = ∑ s, (v s * (starRingEnd ℂ) (v s)) * ∑ r, (lsC x r s : ℂ) ^ 2
        - 2 * ∑ r, ∑ t, (lsC x t r : ℂ) * (lsK x r t : ℂ) * (v r * (starRingEnd ℂ) (v t)) := by
  set c : ι → ι → ℂ := fun r s => (lsC x r s : ℂ) with hc
  set k : ι → ι → ℂ := fun r s => (lsK x r s : ℂ) with hk
  have hpt : ∀ r s t, c r s * c r t = c t s * (k r t - k r s)
      + (if s = t then c r s ^ 2 else 0) - (if r = s then c t r * k r t else 0)
      + (if r = t then c r s * k r s else 0) := by
    intro r s t
    have h := lsC_mul_lsC x hsin r s t
    simp only [hc, hk]
    split_ifs at h ⊢ <;> exact_mod_cast h
  have hcanti : ∀ r s, c s r = - c r s := fun r s => by
    simp only [hc, lsC_antisymm x r s]; push_cast; ring
  have hkanti : ∀ r s, k s r = - k r s := fun r s => by
    simp only [hk, lsK_antisymm x r s]; push_cast; ring
  have hcconj : ∀ r s, (starRingEnd ℂ) (c r s) = c r s := fun r s => Complex.conj_ofReal _
  -- expand the left side into a triple sum
  have hL : ∑ r, (∑ s, c r s * v s) * (starRingEnd ℂ) (∑ t, c r t * v t)
      = ∑ r, ∑ s, ∑ t, (c r s * c r t) * (v s * (starRingEnd ℂ) (v t)) := by
    refine Finset.sum_congr rfl fun r _ => ?_
    rw [map_sum, Finset.sum_mul_sum]
    refine Finset.sum_congr rfl fun s _ => Finset.sum_congr rfl fun t _ => ?_
    rw [map_mul, hcconj]; ring
  show ∑ r, (∑ s, c r s * v s) * (starRingEnd ℂ) (∑ t, c r t * v t)
      = ∑ s, (v s * (starRingEnd ℂ) (v s)) * ∑ r, c r s ^ 2
        - 2 * ∑ r, ∑ t, c t r * k r t * (v r * (starRingEnd ℂ) (v t))
  rw [hL]
  simp_rw [hpt]
  simp only [add_mul, sub_mul, Finset.sum_add_distrib, Finset.sum_sub_distrib]
  -- the cotangent-sum part vanishes
  have hA : ∑ r, ∑ s, ∑ t, c t s * (k r t - k r s) * (v s * (starRingEnd ℂ) (v t)) = 0 := by
    set C : ι → ℂ := fun t => ∑ r, k r t with hC
    have e1 : ∑ r, ∑ s, ∑ t, c t s * (k r t - k r s) * (v s * (starRingEnd ℂ) (v t))
        = ∑ s, ∑ t, c t s * (v s * (starRingEnd ℂ) (v t)) * C t
          - ∑ s, ∑ t, c t s * (v s * (starRingEnd ℂ) (v t)) * C s := by
      rw [Finset.sum_comm, ← Finset.sum_sub_distrib]
      refine Finset.sum_congr rfl fun s _ => ?_
      rw [Finset.sum_comm, ← Finset.sum_sub_distrib]
      refine Finset.sum_congr rfl fun t _ => ?_
      simp only [hC, Finset.mul_sum, ← Finset.sum_sub_distrib]
      refine Finset.sum_congr rfl fun r _ => ?_
      ring
    have e2 : ∑ s, ∑ t, c t s * (v s * (starRingEnd ℂ) (v t)) * C t
        = μ * ∑ t, (v t * (starRingEnd ℂ) (v t)) * C t := by
      rw [Finset.sum_comm, Finset.mul_sum]
      refine Finset.sum_congr rfl fun t _ => ?_
      have := hv t
      calc ∑ s, c t s * (v s * (starRingEnd ℂ) (v t)) * C t
          = (∑ s, c t s * v s) * ((starRingEnd ℂ) (v t) * C t) := by
            rw [Finset.sum_mul]; refine Finset.sum_congr rfl fun s _ => ?_; ring
        _ = μ * (v t * (starRingEnd ℂ) (v t) * C t) := by
            rw [show (∑ s, c t s * v s) = μ * v t from this]; ring
    have e3 : ∑ s, ∑ t, c t s * (v s * (starRingEnd ℂ) (v t)) * C s
        = - (starRingEnd ℂ) μ * ∑ s, (v s * (starRingEnd ℂ) (v s)) * C s := by
      rw [Finset.mul_sum]
      refine Finset.sum_congr rfl fun s _ => ?_
      have h1 : ∑ t, c s t * v t = μ * v s := hv s
      have h2 : ∑ t, c t s * (starRingEnd ℂ) (v t) = - (starRingEnd ℂ) (μ * v s) := by
        rw [← h1, map_sum, ← Finset.sum_neg_distrib]
        refine Finset.sum_congr rfl fun t _ => ?_
        rw [map_mul, hcconj, hcanti s t]; ring
      calc ∑ t, c t s * (v s * (starRingEnd ℂ) (v t)) * C s
          = (∑ t, c t s * (starRingEnd ℂ) (v t)) * (v s * C s) := by
            rw [Finset.sum_mul]; refine Finset.sum_congr rfl fun t _ => ?_; ring
        _ = _ := by rw [h2, map_mul]; ring
    rw [e1, e2, e3, neg_mul, sub_neg_eq_add, ← add_mul, hμ, zero_mul]
  have hB : ∑ r, ∑ s, ∑ t, (if s = t then c r s ^ 2 else 0) * (v s * (starRingEnd ℂ) (v t))
      = ∑ s, (v s * (starRingEnd ℂ) (v s)) * ∑ r, c r s ^ 2 := by
    simp only [ite_mul, zero_mul, Finset.sum_ite_eq, Finset.mem_univ, ite_true]
    rw [Finset.sum_comm]
    refine Finset.sum_congr rfl fun s _ => ?_
    rw [Finset.mul_sum]; refine Finset.sum_congr rfl fun r _ => ?_; ring
  have hC : ∑ r, ∑ s, ∑ t, (if r = s then c t r * k r t else 0) * (v s * (starRingEnd ℂ) (v t))
      = ∑ r, ∑ t, c t r * k r t * (v r * (starRingEnd ℂ) (v t)) := by
    simp only [ite_mul, zero_mul]
    refine Finset.sum_congr rfl fun r _ => ?_
    rw [Finset.sum_comm]
    simp only [Finset.sum_ite_eq, Finset.mem_univ, ite_true]
  have hD : ∑ r, ∑ s, ∑ t, (if r = t then c r s * k r s else 0) * (v s * (starRingEnd ℂ) (v t))
      = - ∑ r, ∑ t, c t r * k r t * (v r * (starRingEnd ℂ) (v t)) := by
    simp only [ite_mul, zero_mul, Finset.sum_ite_eq, Finset.mem_univ, ite_true]
    rw [Finset.sum_comm, ← Finset.sum_neg_distrib]
    refine Finset.sum_congr rfl fun r _ => ?_
    rw [← Finset.sum_neg_distrib]
    refine Finset.sum_congr rfl fun t _ => ?_
    rw [hkanti t r]; ring
  rw [hA, hB, hC, hD]
  ring

lemma ls_eig_bound {ι : Type*} [Fintype ι] [DecidableEq ι] (x : ι → ℝ)
    (hsin : ∀ r s, r ≠ s → Real.sin (pi * (x r - x s)) ≠ 0) (B : ℝ)
    (hB : ∀ s, ∑ r, lsC x r s ^ 2 ≤ B) (v : ι → ℂ) (hv0 : 0 < ∑ r, ‖v r‖ ^ 2) (μ : ℂ)
    (hμ : μ + (starRingEnd ℂ) μ = 0) (hv : ∀ r, ∑ s, (lsC x r s : ℂ) * v s = μ * v r) :
    ‖μ‖ ^ 2 ≤ 3 * B := by
  have hid := ls_energy_identity x hsin v μ hμ hv
  set X := ∑ r, ‖v r‖ ^ 2 with hX
  set P := ∑ s, ‖v s‖ ^ 2 * ∑ r, lsC x r s ^ 2 with hP
  have hvv : ∀ z : ℂ, z * (starRingEnd ℂ) z = ((‖z‖ ^ 2 : ℝ) : ℂ) := fun z => by
    rw [Complex.mul_conj, Complex.normSq_eq_norm_sq]
  have hlhs : ‖∑ r, (∑ s, (lsC x r s : ℂ) * v s) * (starRingEnd ℂ) (∑ t, (lsC x r t : ℂ) * v t)‖
      = ‖μ‖ ^ 2 * X := by
    simp_rw [hv, hvv, norm_mul]
    rw [← ofReal_sum, Complex.norm_real, Real.norm_eq_abs, abs_of_nonneg
      (Finset.sum_nonneg fun r _ => sq_nonneg _), hX, Finset.mul_sum]
    exact Finset.sum_congr rfl fun i _ => by ring
  have hT2 : ‖∑ s, (v s * (starRingEnd ℂ) (v s)) * ∑ r, (lsC x r s : ℂ) ^ 2‖ ≤ P := by
    refine (norm_sum_le _ _).trans (le_of_eq (Finset.sum_congr rfl fun s _ => ?_))
    rw [hvv, norm_mul, Complex.norm_real, Real.norm_eq_abs,
      abs_of_nonneg (sq_nonneg _)]
    congr 1
    simp_rw [← ofReal_pow]
    rw [← ofReal_sum, Complex.norm_real, Real.norm_eq_abs,
      abs_of_nonneg (Finset.sum_nonneg fun r _ => sq_nonneg _)]
  have hT3 : ‖∑ r, ∑ t, (lsC x t r : ℂ) * (lsK x r t : ℂ) * (v r * (starRingEnd ℂ) (v t))‖
      ≤ P := by
    have step : ∀ r t, ‖(lsC x t r : ℂ) * (lsK x r t : ℂ) * (v r * (starRingEnd ℂ) (v t))‖
        ≤ lsC x t r ^ 2 * ‖v r‖ ^ 2 / 2 + lsC x r t ^ 2 * ‖v t‖ ^ 2 / 2 := by
      intro r t
      rw [norm_mul, norm_mul, norm_mul, Complex.norm_conj, Complex.norm_real,
        Complex.norm_real, Real.norm_eq_abs, Real.norm_eq_abs]
      have h1 : |lsK x r t| ≤ |lsC x t r| := by
        rw [lsC_antisymm x r t, abs_neg]; exact lsK_abs_le x r t
      have h2 : lsC x r t ^ 2 = lsC x t r ^ 2 := by rw [lsC_antisymm x r t]; ring
      rw [h2]
      have h3 : |lsC x t r| * |lsK x r t| ≤ lsC x t r ^ 2 := by
        rw [← sq_abs (lsC x t r), sq]
        exact mul_le_mul_of_nonneg_left h1 (abs_nonneg _)
      have h4 : ‖v r‖ * ‖v t‖ ≤ ‖v r‖ ^ 2 / 2 + ‖v t‖ ^ 2 / 2 := by
        nlinarith [sq_nonneg (‖v r‖ - ‖v t‖)]
      calc |lsC x t r| * |lsK x r t| * (‖v r‖ * ‖v t‖)
          ≤ lsC x t r ^ 2 * (‖v r‖ ^ 2 / 2 + ‖v t‖ ^ 2 / 2) :=
            mul_le_mul h3 h4 (by positivity) (sq_nonneg _)
        _ = _ := by ring
    refine (norm_sum_le _ _).trans ?_
    refine (Finset.sum_le_sum fun r _ => norm_sum_le _ _).trans ?_
    refine (Finset.sum_le_sum fun r _ => Finset.sum_le_sum fun t _ => step r t).trans ?_
    simp only [Finset.sum_add_distrib]
    have e1 : ∑ r, ∑ t, lsC x t r ^ 2 * ‖v r‖ ^ 2 / 2 = P / 2 := by
      rw [hP, Finset.sum_div]
      refine Finset.sum_congr rfl fun r _ => ?_
      rw [Finset.mul_sum, Finset.sum_div]
      refine Finset.sum_congr rfl fun t _ => ?_
      ring
    have e2 : ∑ r, ∑ t, lsC x r t ^ 2 * ‖v t‖ ^ 2 / 2 = P / 2 := by
      rw [Finset.sum_comm, hP, Finset.sum_div]
      refine Finset.sum_congr rfl fun t _ => ?_
      rw [Finset.mul_sum, Finset.sum_div]
      refine Finset.sum_congr rfl fun r _ => ?_
      ring
    rw [e1, e2]; ring_nf; exact le_refl _
  have hPB : P ≤ B * X := by
    rw [hP, hX, Finset.mul_sum]
    refine Finset.sum_le_sum fun s _ => ?_
    rw [mul_comm B]
    exact mul_le_mul_of_nonneg_left (hB s) (sq_nonneg _)
  have key : ‖μ‖ ^ 2 * X ≤ 3 * B * X := by
    rw [← hlhs, hid]
    calc _ ≤ ‖∑ s, (v s * (starRingEnd ℂ) (v s)) * ∑ r, (lsC x r s : ℂ) ^ 2‖
          + ‖2 * ∑ r, ∑ t, (lsC x t r : ℂ) * (lsK x r t : ℂ) * (v r * (starRingEnd ℂ) (v t))‖ :=
          norm_sub_le _ _
      _ ≤ P + 2 * P := by
          rw [norm_mul, show ‖(2:ℂ)‖ = 2 by norm_num]
          linarith
      _ ≤ 3 * B * X := by linarith
  exact le_of_mul_le_mul_right key hv0

open Matrix in
lemma ls_quad_le {ι : Type*} [Fintype ι] [DecidableEq ι] (H : Matrix ι ι ℂ)
    (hH : H.IsHermitian) (c : ℝ) (hc : ∀ j, |hH.eigenvalues j| ≤ c) (w : ι → ℂ) :
    ‖star w ⬝ᵥ H *ᵥ w‖ ≤ c * ∑ i, ‖w i‖ ^ 2 := by
  set U : Matrix ι ι ℂ := (hH.eigenvectorUnitary : Matrix ι ι ℂ) with hU
  have hspec : H = U * Matrix.diagonal (RCLike.ofReal ∘ hH.eigenvalues) * star U := by
    have := hH.spectral_theorem
    rw [Unitary.conjStarAlgAut_apply] at this
    exact this
  set y := star U *ᵥ w with hy
  have h1 : star w ⬝ᵥ H *ᵥ w = ∑ j, star (y j) * ((hH.eigenvalues j : ℂ) * y j) := by
    conv_lhs => rw [hspec]
    rw [← Matrix.mulVec_mulVec, ← Matrix.mulVec_mulVec, Matrix.dotProduct_mulVec, ← hy]
    have : star w ᵥ* U = star y := by
      rw [hy, Matrix.star_mulVec, star_eq_conjTranspose, conjTranspose_conjTranspose]
    rw [this]
    simp [dotProduct, Matrix.mulVec_diagonal]
  have e : ∀ z : ι → ℂ, star z ⬝ᵥ z = ((∑ j, ‖z j‖ ^ 2 : ℝ) : ℂ) := by
    intro z
    simp only [dotProduct, Pi.star_apply, ofReal_sum]
    refine Finset.sum_congr rfl fun j _ => ?_
    rw [RCLike.star_def, mul_comm, Complex.mul_conj, Complex.normSq_eq_norm_sq]
  have h2 : ∑ j, ‖y j‖ ^ 2 = ∑ i, ‖w i‖ ^ 2 := by
    have hu : U * star U = 1 := Unitary.coe_mul_star_self _
    have : star y ⬝ᵥ y = star w ⬝ᵥ w := by
      rw [hy, Matrix.star_mulVec, star_eq_conjTranspose, conjTranspose_conjTranspose,
        ← Matrix.dotProduct_mulVec, Matrix.mulVec_mulVec, ← star_eq_conjTranspose, hu,
        Matrix.one_mulVec]
    rw [e, e] at this
    exact_mod_cast this
  rw [h1, ← h2, Finset.mul_sum]
  refine (norm_sum_le _ _).trans (Finset.sum_le_sum fun j _ => ?_)
  rw [norm_mul, norm_mul, norm_star]
  have : ‖(hH.eigenvalues j : ℂ)‖ = |hH.eigenvalues j| := by simp
  rw [this]
  have := hc j
  nlinarith [norm_nonneg (y j), abs_nonneg (hH.eigenvalues j)]

open Matrix in
lemma ls_hilbert {ι : Type*} [Fintype ι] [DecidableEq ι] (x : ι → ℝ)
    (hsin : ∀ r s, r ≠ s → Real.sin (pi * (x r - x s)) ≠ 0) (B : ℝ)
    (hB : ∀ s, ∑ r, lsC x r s ^ 2 ≤ B) (w : ι → ℂ) :
    ‖∑ r, ∑ s, w r * (starRingEnd ℂ) (w s) * (lsC x r s : ℂ)‖
      ≤ Real.sqrt (3 * B) * ∑ r, ‖w r‖ ^ 2 := by
  set H : Matrix ι ι ℂ := Matrix.of fun r s => I * (lsC x r s : ℂ) with hHdef
  have hH : H.IsHermitian := by
    ext r s
    simp only [hHdef, conjTranspose_apply, of_apply, star_mul', RCLike.star_def,
      Complex.conj_I, Complex.conj_ofReal, lsC_antisymm x s r]
    push_cast; ring
  have heig : ∀ j, |hH.eigenvalues j| ≤ Real.sqrt (3 * B) := by
    intro j
    set v : ι → ℂ := ⇑(hH.eigenvectorBasis j) with hvdef
    have hmul := hH.mulVec_eigenvectorBasis j
    have hv : ∀ r, ∑ s, (lsC x r s : ℂ) * v s = (-I * (hH.eigenvalues j : ℂ)) * v r := by
      intro r
      have := congrFun hmul r
      have hentry : ∀ r s, H r s = I * (lsC x r s : ℂ) := fun r s => rfl
      simp only [mulVec, dotProduct, hentry, Pi.smul_apply, Complex.real_smul] at this
      have e : ∑ s, (lsC x r s : ℂ) * v s = -I * ∑ s, I * (lsC x r s : ℂ) * v s := by
        rw [Finset.mul_sum]; refine Finset.sum_congr rfl fun s _ => ?_
        rw [← mul_assoc, ← mul_assoc, neg_mul, Complex.I_mul_I]; ring
      rw [e, this, hvdef]; ring
    have hv0 : 0 < ∑ r, ‖v r‖ ^ 2 := by
      have h1 : ‖hH.eigenvectorBasis j‖ = 1 := (hH.eigenvectorBasis.orthonormal.1 j)
      rw [EuclideanSpace.norm_eq] at h1
      have : ∑ r, ‖v r‖ ^ 2 = 1 := by
        rw [hvdef]
        have := Real.sqrt_eq_one.mp h1
        exact this
      rw [this]; norm_num
    have hμ : (-I * (hH.eigenvalues j : ℂ)) + (starRingEnd ℂ) (-I * (hH.eigenvalues j : ℂ)) = 0 := by
      simp [map_mul, Complex.conj_I, Complex.conj_ofReal]
    have := ls_eig_bound x hsin B hB v hv0 _ hμ hv
    have hn : ‖(-I * (hH.eigenvalues j : ℂ))‖ = |hH.eigenvalues j| := by simp
    rw [hn] at this
    rw [← Real.sqrt_sq_eq_abs]
    exact Real.sqrt_le_sqrt (by rw [sq_abs] at this; exact this)
  have hq := ls_quad_le H hH _ heig w
  have hrel : ∑ r, ∑ s, w r * (starRingEnd ℂ) (w s) * (lsC x r s : ℂ) = I * (star w ⬝ᵥ H *ᵥ w) := by
    simp only [dotProduct, mulVec, hHdef, of_apply, Pi.star_apply, RCLike.star_def, Finset.mul_sum]
    rw [Finset.sum_comm]
    refine Finset.sum_congr rfl fun s _ => Finset.sum_congr rfl fun r _ => ?_
    rw [lsC_antisymm x r s]
    push_cast
    ring_nf
    rw [Complex.I_sq]; ring
  rw [hrel, norm_mul, Complex.norm_I, one_mul]
  exact hq


lemma ls_geom (θ : ℂ) (M N : ℕ) :
    (∑ n ∈ Ioc M (M + N), Complex.exp (2 * pi * I * ((n : ℂ) * θ)))
      * (Complex.exp (pi * I * θ) - Complex.exp (-(pi * I * θ)))
      = Complex.exp (2 * pi * I * ((((M + N : ℕ) : ℂ) + 1 / 2) * θ))
        - Complex.exp (2 * pi * I * (((M : ℂ) + 1 / 2) * θ)) := by
  induction N with
  | zero => simp
  | succ N ih =>
    rw [show M + (N + 1) = (M + N) + 1 by ring, Finset.sum_Ioc_succ_top (by omega), add_mul, ih,
      mul_sub, ← Complex.exp_add, ← Complex.exp_add]
    have e1 : 2 * (pi : ℂ) * I * ((((M + N + 1 : ℕ) : ℂ) * θ)) + pi * I * θ
        = 2 * pi * I * ((((M + N + 1 : ℕ) : ℂ) + 1 / 2) * θ) := by ring
    have e2 : 2 * (pi : ℂ) * I * ((((M + N + 1 : ℕ) : ℂ) * θ)) + -(pi * I * θ)
        = 2 * pi * I * ((((M + N : ℕ) : ℂ) + 1 / 2) * θ) := by push_cast; ring
    rw [e1, e2]; ring

lemma ls_two_I_sin (t : ℝ) :
    Complex.exp (pi * I * (t : ℂ)) - Complex.exp (-(pi * I * (t : ℂ)))
      = 2 * I * (Real.sin (pi * t) : ℂ) := by
  rw [Complex.ofReal_sin, Complex.sin]
  have e1 : (pi : ℂ) * I * t = ((pi * t : ℝ) : ℂ) * I := by push_cast; ring
  have e2 : -(((pi * t : ℝ) : ℂ) * I) = -((pi * t : ℝ) : ℂ) * I := by ring
  rw [e1, e2]
  generalize Complex.exp (((pi * t : ℝ) : ℂ) * I) = a
  generalize Complex.exp (-((pi * t : ℝ) : ℂ) * I) = b
  linear_combination (a - b) * Complex.I_sq

lemma ls_dual {ι : Type*} [Fintype ι] [DecidableEq ι] (x : ι → ℝ)
    (hsin : ∀ r s, r ≠ s → Real.sin (pi * (x r - x s)) ≠ 0) (B : ℝ)
    (hB : ∀ s, ∑ r, lsC x r s ^ 2 ≤ B) (M N : ℕ) (y : ι → ℂ) :
    ∑ n ∈ Ioc M (M + N), ‖∑ r, y r * Complex.exp (2 * pi * I * ((n : ℂ) * (x r : ℂ)))‖ ^ 2
      ≤ ((N : ℝ) + Real.sqrt (3 * B)) * ∑ r, ‖y r‖ ^ 2 := by
  set e : ℂ → ℂ := fun t => Complex.exp (2 * pi * I * t) with he
  set E : ι → ℂ := fun r => e ((((M + N : ℕ) : ℂ) + 1 / 2) * (x r : ℂ)) with hE
  set E' : ι → ℂ := fun r => e (((M : ℂ) + 1 / 2) * (x r : ℂ)) with hE'
  have hconj : ∀ t : ℝ, (starRingEnd ℂ) (e (t : ℂ)) = e (-(t : ℂ)) := fun t => by
    simp only [he, ← Complex.exp_conj, map_mul, Complex.conj_ofReal, Complex.conj_I]
    congr 1
    rw [map_ofNat]; ring
  have hnormE : ∀ t : ℝ, ‖e (t : ℂ)‖ = 1 := fun t => by
    simp only [he]
    rw [show 2 * (pi : ℂ) * I * t = ((2 * pi * t : ℝ) : ℂ) * I by push_cast; ring]
    exact Complex.norm_exp_ofReal_mul_I _
  have hmul : ∀ a b : ℂ, e a * e b = e (a + b) := fun a b => by
    simp only [he, ← Complex.exp_add]; ring_nf
  -- the kernel identity
  have hker : ∀ r s, (∑ n ∈ Ioc M (M + N), e ((n : ℂ) * ((x r - x s : ℝ) : ℂ)))
      = (if r = s then (N : ℂ) else 0)
        + (E r * (starRingEnd ℂ) (E s) - E' r * (starRingEnd ℂ) (E' s)) * (lsC x r s : ℂ)
          / (2 * I) := by
    intro r s
    by_cases hrs : r = s
    · subst hrs
      simp [lsC, he]
    · have hs := hsin r s hrs
      rw [ite_eq_right hrs, zero_add]
      have hg := ls_geom ((x r - x s : ℝ) : ℂ) M N
      rw [ls_two_I_sin] at hg
      have hEE : E r * (starRingEnd ℂ) (E s) - E' r * (starRingEnd ℂ) (E' s)
          = e ((((M + N : ℕ) : ℂ) + 1 / 2) * ((x r - x s : ℝ) : ℂ))
            - e (((M : ℂ) + 1 / 2) * ((x r - x s : ℝ) : ℂ)) := by
        simp only [hE, hE']
        rw [show (((M + N : ℕ) : ℂ) + 1 / 2) * (x s : ℂ) = (((M + N + 1 / 2 : ℝ)) * x s : ℝ) by
          push_cast; ring]
        rw [show ((M : ℂ) + 1 / 2) * (x s : ℂ) = (((M + 1 / 2 : ℝ)) * x s : ℝ) by push_cast; ring]
        rw [hconj, hconj, hmul, hmul]
        congr 2 <;> push_cast <;> ring
      rw [hEE]
      simp only [he]
      rw [← hg]
      generalize (∑ n ∈ Ioc M (M + N),
        Complex.exp (2 * pi * I * ((n : ℂ) * ((x r - x s : ℝ) : ℂ)))) = G
      simp only [lsC, ite_eq_right hrs]
      have h2 : (2 : ℂ) * I ≠ 0 := by simp
      have h3 : ((Real.sin (pi * (x r - x s)) : ℝ) : ℂ) ≠ 0 := by exact_mod_cast hs
      rw [Complex.ofReal_div, Complex.ofReal_one]
      field_simp
  -- expand the left side
  have hexp : ((∑ n ∈ Ioc M (M + N), ‖∑ r, y r * e ((n : ℂ) * (x r : ℂ))‖ ^ 2 : ℝ) : ℂ)
      = (N : ℂ) * ((∑ r, ‖y r‖ ^ 2 : ℝ) : ℂ)
        + (∑ r, ∑ s, (y r * E r) * (starRingEnd ℂ) (y s * E s) * (lsC x r s : ℂ)
          - ∑ r, ∑ s, (y r * E' r) * (starRingEnd ℂ) (y s * E' s) * (lsC x r s : ℂ)) / (2 * I) := by
    push_cast
    have step1 : ∀ n : ℕ, ((‖∑ r, y r * e ((n : ℂ) * (x r : ℂ))‖ : ℝ) : ℂ) ^ 2
        = ∑ r, ∑ s, y r * (starRingEnd ℂ) (y s) * e ((n : ℂ) * ((x r - x s : ℝ) : ℂ)) := by
      intro n
      rw [← Complex.mul_conj', map_sum, Finset.sum_mul_sum]
      refine Finset.sum_congr rfl fun r _ => Finset.sum_congr rfl fun s _ => ?_
      rw [map_mul, show (n : ℂ) * (x s : ℂ) = ((n * x s : ℝ) : ℂ) by push_cast; ring, hconj,
        show (n : ℂ) * ((x r : ℝ) : ℂ) = ((n * x r : ℝ) : ℂ) by push_cast; ring]
      rw [show y r * e (((n * x r : ℝ) : ℂ)) * ((starRingEnd ℂ) (y s) * e (-((n * x s : ℝ) : ℂ)))
          = y r * (starRingEnd ℂ) (y s) * (e (((n * x r : ℝ) : ℂ)) * e (-((n * x s : ℝ) : ℂ))) by
          ring, hmul]
      congr 2; push_cast; ring
    simp_rw [step1]
    rw [Finset.sum_comm]
    have step2 : ∀ r, ∑ n ∈ Ioc M (M + N), ∑ s, y r * (starRingEnd ℂ) (y s)
        * e ((n : ℂ) * ((x r - x s : ℝ) : ℂ))
        = ∑ s, y r * (starRingEnd ℂ) (y s) * ∑ n ∈ Ioc M (M + N), e ((n : ℂ) * ((x r - x s : ℝ) : ℂ)) := by
      intro r
      rw [Finset.sum_comm]
      exact Finset.sum_congr rfl fun s _ => by rw [Finset.mul_sum]
    simp_rw [step2, hker]
    simp only [mul_add, Finset.sum_add_distrib, mul_ite, mul_zero, Finset.sum_ite_eq,
      Finset.mem_univ, ite_true]
    congr 1
    · rw [Finset.mul_sum]
      refine Finset.sum_congr rfl fun r _ => ?_
      rw [Complex.mul_conj', ← Complex.ofReal_pow]; push_cast; ring
    · rw [sub_div, Finset.sum_div, Finset.sum_div, ← Finset.sum_sub_distrib]
      refine Finset.sum_congr rfl fun r _ => ?_
      rw [Finset.sum_div, Finset.sum_div, ← Finset.sum_sub_distrib]
      refine Finset.sum_congr rfl fun s _ => ?_
      simp only [map_mul]
      ring
  have hnE : ∀ r, ‖y r * E r‖ = ‖y r‖ := fun r => by
    rw [norm_mul, hE]
    simp only
    rw [show (((M + N : ℕ) : ℂ) + 1 / 2) * (x r : ℂ) = (((M + N + 1 / 2 : ℝ)) * x r : ℝ) by
      push_cast; ring, hnormE, mul_one]
  have hnE' : ∀ r, ‖y r * E' r‖ = ‖y r‖ := fun r => by
    rw [norm_mul, hE']
    simp only
    rw [show ((M : ℂ) + 1 / 2) * (x r : ℂ) = (((M + 1 / 2 : ℝ)) * x r : ℝ) by
      push_cast; ring, hnormE, mul_one]
  have h1 := ls_hilbert x hsin B hB (fun r => y r * E r)
  have h2 := ls_hilbert x hsin B hB (fun r => y r * E' r)
  simp only [hnE, hnE'] at h1 h2
  have hL : ∑ n ∈ Ioc M (M + N), ‖∑ r, y r * Complex.exp (2 * pi * I * ((n : ℂ) * (x r : ℂ)))‖ ^ 2
      = ‖((∑ n ∈ Ioc M (M + N), ‖∑ r, y r * e ((n : ℂ) * (x r : ℂ))‖ ^ 2 : ℝ) : ℂ)‖ := by
    rw [Complex.norm_real, Real.norm_eq_abs, abs_of_nonneg (Finset.sum_nonneg fun n _ => sq_nonneg _)]
  rw [hL, hexp]
  refine (norm_add_le _ _).trans ?_
  rw [norm_mul, Complex.norm_natCast, Complex.norm_real, Real.norm_eq_abs,
    abs_of_nonneg (Finset.sum_nonneg fun n _ => sq_nonneg _), norm_div, norm_mul,
    Complex.norm_I, show ‖(2 : ℂ)‖ = 2 by norm_num, mul_one, add_mul]
  gcongr
  rw [div_le_iff₀ (by norm_num : (0:ℝ) < 2)]
  refine (norm_sub_le _ _).trans ?_
  linarith


lemma ls_primal {ι : Type*} [Fintype ι] [DecidableEq ι] (x : ι → ℝ)
    (hsin : ∀ r s, r ≠ s → Real.sin (pi * (x r - x s)) ≠ 0) (B : ℝ)
    (hB : ∀ s, ∑ r, lsC x r s ^ 2 ≤ B) (a : ℕ → ℂ) (M N : ℕ) :
    ∑ r, ‖∑ n ∈ Ioc M (M + N), a n * Complex.exp (2 * Real.pi * I * ((n : ℂ) * (x r : ℂ)))‖ ^ 2
      ≤ ((N : ℝ) + Real.sqrt (3 * B)) * ∑ n ∈ Ioc M (M + N), ‖a n‖ ^ 2 := by
  set Δ : ℝ := (N : ℝ) + Real.sqrt (3 * B) with hΔ
  have hΔ0 : 0 ≤ Δ := by positivity
  set e : ℕ → ι → ℂ := fun n r => Complex.exp (2 * Real.pi * I * ((n : ℂ) * (x r : ℂ))) with he
  set S : ι → ℂ := fun r => ∑ n ∈ Ioc M (M + N), a n * e n r with hS
  set X : ℝ := ∑ r, ‖S r‖ ^ 2 with hX
  set A : ℝ := ∑ n ∈ Ioc M (M + N), ‖a n‖ ^ 2 with hA
  set T : ℕ → ℂ := fun n => ∑ r, (starRingEnd ℂ) (S r) * e n r with hT
  have hdual := ls_dual x hsin B hB M N (fun r => (starRingEnd ℂ) (S r))
  have hdual' : ∑ n ∈ Ioc M (M + N), ‖T n‖ ^ 2 ≤ Δ * X := by
    simp only [Complex.norm_conj] at hdual
    exact hdual
  have hXeq : ((X : ℝ) : ℂ) = ∑ n ∈ Ioc M (M + N), a n * T n := by
    simp only [hX, hT, Finset.mul_sum]
    push_cast
    rw [Finset.sum_comm]
    refine Finset.sum_congr rfl fun r _ => ?_
    rw [← Complex.mul_conj', hS, Finset.sum_mul]
    refine Finset.sum_congr rfl fun n _ => ?_
    ring
  have hX0 : 0 ≤ X := Finset.sum_nonneg fun r _ => sq_nonneg _
  have hXle : X ≤ ∑ n ∈ Ioc M (M + N), ‖a n‖ * ‖T n‖ := by
    have : X = ‖((X : ℝ) : ℂ)‖ := by rw [Complex.norm_real, Real.norm_eq_abs, abs_of_nonneg hX0]
    rw [this, hXeq]
    refine (norm_sum_le _ _).trans (le_of_eq ?_)
    exact Finset.sum_congr rfl fun n _ => norm_mul _ _
  have hCS := Finset.sum_mul_sq_le_sq_mul_sq (Ioc M (M + N)) (fun n => ‖a n‖) (fun n => ‖T n‖)
  have hX2 : X ^ 2 ≤ A * (Δ * X) := by
    calc X ^ 2 ≤ (∑ n ∈ Ioc M (M + N), ‖a n‖ * ‖T n‖) ^ 2 := pow_le_pow_left₀ hX0 hXle 2
      _ ≤ A * ∑ n ∈ Ioc M (M + N), ‖T n‖ ^ 2 := hCS
      _ ≤ A * (Δ * X) := mul_le_mul_of_nonneg_left hdual'
          (Finset.sum_nonneg fun n _ => sq_nonneg _)
  show X ≤ Δ * A
  rcases hX0.lt_or_eq with hpos | hzero
  · nlinarith
  · rw [← hzero]; exact mul_nonneg hΔ0 (Finset.sum_nonneg fun n _ => sq_nonneg _)


lemma ls_sin_sq_fract (d : ℝ) :
    Real.sin (Real.pi * d) ^ 2 = Real.sin (Real.pi * Int.fract d) ^ 2 := by
  have : Real.pi * d = Real.pi * Int.fract d + (⌊d⌋ : ℤ) * Real.pi := by
    rw [Int.fract]; ring
  rw [this, Real.sin_add_int_mul_pi, mul_pow, ← zpow_natCast, ← zpow_mul]
  rw [show ((⌊d⌋ : ℤ) * ((2 : ℕ) : ℤ)) = 2 * ⌊d⌋ by push_cast; ring, zpow_mul]
  norm_num

lemma ls_csc_sum {ι : Type*} [Fintype ι] [DecidableEq ι] (x : ι → ℝ) (D : ℝ) (hD : 0 < D)
    (hsep : ∀ r s, r ≠ s → ∀ m : ℤ, 1 / D ≤ |x r - x s - m|) (s : ι) :
    ∑ r, lsC x r s ^ 2 ≤ 2 * ∑ k ∈ Icc 1 ⌊D / 2⌋₊, 1 / Real.sin (Real.pi * k / D) ^ 2 := by
  set y : ι → ℝ := fun r => Int.fract (x r - x s) with hy
  set u : ι → ℝ := fun r => min (y r) (1 - y r) with hu
  set φ : ι → ℕ × Bool := fun r => (⌊u r * D⌋₊, decide (y r ≤ 1 / 2)) with hφ
  set g : ℕ × Bool → ℝ := fun p => 1 / Real.sin (Real.pi * p.1 / D) ^ 2 with hg
  have hy_lo : ∀ r, r ≠ s → 1 / D ≤ y r := by
    intro r hr
    have := hsep r s hr ⌊x r - x s⌋
    rwa [show x r - x s - (⌊x r - x s⌋ : ℝ) = Int.fract (x r - x s) by rw [Int.fract],
      abs_of_nonneg (Int.fract_nonneg _)] at this
  have hy_hi : ∀ r, r ≠ s → 1 / D ≤ 1 - y r := by
    intro r hr
    have := hsep r s hr (⌊x r - x s⌋ + 1)
    rwa [show x r - x s - ((⌊x r - x s⌋ + 1 : ℤ) : ℝ) = Int.fract (x r - x s) - 1 by
      rw [Int.fract]; push_cast; ring, abs_sub_comm,
      abs_of_nonneg (by linarith [Int.fract_lt_one (x r - x s)])] at this
  have hu_lo : ∀ r, r ≠ s → 1 / D ≤ u r := fun r hr => le_min (hy_lo r hr) (hy_hi r hr)
  have hu_hi : ∀ r, u r ≤ 1 / 2 := by
    intro r; simp only [hu]
    rcases le_total (y r) (1 - y r) with h | h
    · rw [min_eq_left h]; linarith
    · rw [min_eq_right h]; linarith
  have hsin_u : ∀ r, Real.sin (Real.pi * (x r - x s)) ^ 2 = Real.sin (Real.pi * u r) ^ 2 := by
    intro r
    rw [ls_sin_sq_fract]
    simp only [hu]
    rcases le_total (y r) (1 - y r) with h | h
    · rw [min_eq_left h]
    · rw [min_eq_right h, show Real.pi * (1 - y r) = Real.pi - Real.pi * y r by ring,
        Real.sin_pi_sub]
  -- each term is at most g (φ r)
  have hterm : ∀ r ∈ univ.erase s, lsC x r s ^ 2 ≤ g (φ r) := by
    intro r hr
    have hrs : r ≠ s := Finset.ne_of_mem_erase hr
    simp only [lsC, ite_eq_right hrs, hg, hφ]
    rw [div_pow, one_pow, hsin_u r]
    have huD : 1 ≤ u r * D := by
      have := hu_lo r hrs; rw [div_le_iff₀ hD] at this; linarith
    have hk1 : 1 ≤ ⌊u r * D⌋₊ := Nat.le_floor (by exact_mod_cast huD)
    have hkle : (⌊u r * D⌋₊ : ℝ) ≤ u r * D := Nat.floor_le (by linarith)
    have hk0 : (0 : ℝ) < ⌊u r * D⌋₊ := by exact_mod_cast hk1
    have ha : 0 < Real.pi * (⌊u r * D⌋₊ : ℝ) / D := by positivity
    have hab : Real.pi * (⌊u r * D⌋₊ : ℝ) / D ≤ Real.pi * u r := by
      rw [div_le_iff₀ hD]; nlinarith [Real.pi_pos]
    have hb : Real.pi * u r ≤ Real.pi / 2 := by nlinarith [Real.pi_pos, hu_hi r]
    have hsa : 0 < Real.sin (Real.pi * (⌊u r * D⌋₊ : ℝ) / D) :=
      Real.sin_pos_of_pos_of_lt_pi ha (by linarith [Real.pi_pos])
    have hsab : Real.sin (Real.pi * (⌊u r * D⌋₊ : ℝ) / D) ≤ Real.sin (Real.pi * u r) :=
      Real.sin_le_sin_of_le_of_le_pi_div_two (by linarith) hb hab
    apply one_div_le_one_div_of_le (by positivity)
    exact pow_le_pow_left₀ hsa.le hsab 2
  -- φ is injective off s
  have hinj : Set.InjOn φ (univ.erase s : Finset ι) := by
    intro r hr r' hr' heq
    by_contra hne
    have hrs : r ≠ s := Finset.ne_of_mem_erase hr
    have hr's : r' ≠ s := Finset.ne_of_mem_erase hr'
    simp only [hφ, Prod.mk.injEq] at heq
    obtain ⟨hk, hside⟩ := heq
    have hclose : |u r - u r'| < 1 / D := by
      have h1 := Nat.floor_le (show 0 ≤ u r * D by nlinarith [hu_lo r hrs, hD, one_div_pos.2 hD])
      have h2 := Nat.lt_floor_add_one (u r * D)
      have h3 := Nat.floor_le (show 0 ≤ u r' * D by nlinarith [hu_lo r' hr's, hD, one_div_pos.2 hD])
      have h4 := Nat.lt_floor_add_one (u r' * D)
      rw [hk] at h1 h2
      have hlt : |u r * D - u r' * D| < 1 := by rw [abs_lt]; constructor <;> linarith
      rw [← sub_mul, abs_mul, abs_of_pos hD] at hlt
      rwa [lt_div_iff₀ hD]
    have hyy : |y r - y r'| < 1 / D := by
      simp only [hu] at hclose
      by_cases h : y r ≤ 1 / 2
      · have h' : y r' ≤ 1 / 2 := by
          have := hside; simp only [decide_eq_decide] at this; exact this.mp h
        rwa [min_eq_left (by linarith), min_eq_left (by linarith)] at hclose
      · have h' : ¬ y r' ≤ 1 / 2 := by
          have := hside; simp only [decide_eq_decide] at this; exact fun h2 => h (this.mpr h2)
        rw [min_eq_right (by linarith), min_eq_right (by linarith)] at hclose
        rwa [show 1 - y r - (1 - y r') = -(y r - y r') by ring, abs_neg] at hclose
    have := hsep r r' hne (⌊x r - x s⌋ - ⌊x r' - x s⌋)
    have e : x r - x r' - ((⌊x r - x s⌋ - ⌊x r' - x s⌋ : ℤ) : ℝ) = y r - y r' := by
      simp only [hy, Int.fract]; push_cast; ring
    rw [e] at this
    linarith
  -- assemble
  have hss : ∑ r, lsC x r s ^ 2 = ∑ r ∈ univ.erase s, lsC x r s ^ 2 := by
    rw [Finset.sum_erase]; simp [lsC]
  rw [hss]
  calc ∑ r ∈ univ.erase s, lsC x r s ^ 2 ≤ ∑ r ∈ univ.erase s, g (φ r) := Finset.sum_le_sum hterm
    _ = ∑ p ∈ (univ.erase s).image φ, g p := (Finset.sum_image hinj).symm
    _ ≤ ∑ p ∈ Icc 1 ⌊D / 2⌋₊ ×ˢ (univ : Finset Bool), g p := by
        apply Finset.sum_le_sum_of_subset_of_nonneg
        · intro p hp
          obtain ⟨r, hr, rfl⟩ := Finset.mem_image.mp hp
          have hrs : r ≠ s := Finset.ne_of_mem_erase hr
          simp only [Finset.mem_product, Finset.mem_Icc, Finset.mem_univ, and_true, hφ]
          have huD : 1 ≤ u r * D := by
            have := hu_lo r hrs; rw [div_le_iff₀ hD] at this; linarith
          refine ⟨Nat.le_floor (by exact_mod_cast huD), Nat.floor_le_floor ?_⟩
          nlinarith [hu_hi r]
        · intro p _ _
          simp only [hg]; positivity
    _ = 2 * ∑ k ∈ Icc 1 ⌊D / 2⌋₊, 1 / Real.sin (Real.pi * k / D) ^ 2 := by
        rw [Finset.sum_product, Finset.mul_sum]
        refine Finset.sum_congr rfl fun k _ => ?_
        simp [hg]


lemma ls_inv_sin_sq_le (y : ℝ) (h0 : 0 < y) (h1 : y ≤ Real.pi / 2) :
    1 / Real.sin y ^ 2 ≤ 1 / y ^ 2 + 1 := by
  have hpi := Real.pi_lt_d2
  have hy2 : y ^ 2 ≤ 3 := by nlinarith
  set t := y - y ^ 3 / 6 with ht
  have htpos : 0 < t := by
    rw [ht]; have : y ^ 3 / 6 < y := by nlinarith
    linarith
  have hst : t ≤ Real.sin y := Real.sin_ge_sub_cube h0.le
  have hkey : y ^ 2 ≤ t ^ 2 * (1 + y ^ 2) := by
    rw [ht]
    have hu : 0 ≤ (3 - y ^ 2) * (8 - y ^ 2) := mul_nonneg (by linarith) (by linarith)
    have : t ^ 2 * (1 + y ^ 2) - y ^ 2 = y ^ 4 * ((3 - y ^ 2) * (8 - y ^ 2)) / 36 := by
      rw [ht]; ring
    rw [← ht]
    nlinarith [pow_nonneg (sq_nonneg y) 2, this]
  calc 1 / Real.sin y ^ 2 ≤ 1 / t ^ 2 :=
        one_div_le_one_div_of_le (by positivity) (pow_le_pow_left₀ htpos.le hst 2)
    _ ≤ 1 / y ^ 2 + 1 := by
        rw [div_add_one (by positivity), div_le_div_iff₀ (by positivity) (by positivity)]
        linarith

lemma ls_csc_numeric (D : ℝ) (hD : 0 < D) :
    ∑ k ∈ Icc 1 ⌊D / 2⌋₊, 1 / Real.sin (Real.pi * k / D) ^ 2
      ≤ D ^ 2 / 6 + (⌊D / 2⌋₊ : ℝ) := by
  have hterm : ∀ k ∈ Icc 1 ⌊D / 2⌋₊, 1 / Real.sin (Real.pi * k / D) ^ 2
      ≤ D ^ 2 / Real.pi ^ 2 * (1 / (k : ℝ) ^ 2) + 1 := by
    intro k hk
    rw [Finset.mem_Icc] at hk
    have hk0 : (0 : ℝ) < k := by exact_mod_cast hk.1
    have hkD : (k : ℝ) ≤ D / 2 := by
      have := Nat.cast_le (α := ℝ) |>.mpr hk.2
      exact this.trans (Nat.floor_le (by positivity))
    have h := ls_inv_sin_sq_le (Real.pi * k / D) (by positivity) (by
      rw [div_le_div_iff₀ hD (by norm_num)]; nlinarith [Real.pi_pos])
    calc _ ≤ 1 / (Real.pi * k / D) ^ 2 + 1 := h
      _ = _ := by field_simp
  have hz : ∑ k ∈ Icc 1 ⌊D / 2⌋₊, 1 / (k : ℝ) ^ 2 ≤ Real.pi ^ 2 / 6 :=
    sum_le_hasSum _ (fun n _ => by positivity) hasSum_zeta_two
  calc _ ≤ ∑ k ∈ Icc 1 ⌊D / 2⌋₊, (D ^ 2 / Real.pi ^ 2 * (1 / (k : ℝ) ^ 2) + 1) :=
        Finset.sum_le_sum hterm
    _ = D ^ 2 / Real.pi ^ 2 * ∑ k ∈ Icc 1 ⌊D / 2⌋₊, 1 / (k : ℝ) ^ 2 + (⌊D / 2⌋₊ : ℝ) := by
        rw [Finset.sum_add_distrib, ← Finset.mul_sum]; simp
    _ ≤ D ^ 2 / Real.pi ^ 2 * (Real.pi ^ 2 / 6) + (⌊D / 2⌋₊ : ℝ) := by
        gcongr
    _ = D ^ 2 / 6 + (⌊D / 2⌋₊ : ℝ) := by
        have := Real.pi_pos
        field_simp


lemma ls_farey_sep (Q q b q' b' : ℕ) (hQ : 2 ≤ Q) (hq : 1 ≤ q) (hqQ : q ≤ Q) (hb : b < q)
    (hc : Nat.Coprime b q) (hq' : 1 ≤ q') (hq'Q : q' ≤ Q) (hb' : b' < q')
    (hc' : Nat.Coprime b' q') (hne : ¬ (q = q' ∧ b = b')) (m : ℤ) :
    1 / ((Q : ℝ) * (Q - 1)) ≤ |(b : ℝ) / q - (b' : ℝ) / q' - m| := by
  set z : ℤ := b * q' - b' * q - m * q * q' with hzdef
  have hqr : (0 : ℝ) < q := by exact_mod_cast hq
  have hq'r : (0 : ℝ) < q' := by exact_mod_cast hq'
  have hz : (b : ℝ) / q - (b' : ℝ) / q' - m = (z : ℝ) / (q * q') := by
    rw [hzdef]; push_cast; field_simp
  have hz0 : z ≠ 0 := by
    intro hz0
    have h1 : (b : ℤ) * q' < q * q' := by
      have : b * q' < q * q' := Nat.mul_lt_mul_of_pos_right hb (by omega)
      exact_mod_cast this
    have h2 : (b' : ℤ) * q < q' * q := by
      have : b' * q < q' * q := Nat.mul_lt_mul_of_pos_right hb' (by omega)
      exact_mod_cast this
    have hb0 : (0 : ℤ) ≤ b * q' := by positivity
    have hb0' : (0 : ℤ) ≤ b' * q := by positivity
    have hqq : (0 : ℤ) < q * q' := by positivity
    have hm : m = 0 := by
      by_contra hm
      rcases lt_or_gt_of_ne hm with h | h
      · have : m ≤ -1 := by omega
        nlinarith
      · have : 1 ≤ m := by omega
        nlinarith
    rw [hzdef, hm] at hz0
    have hnat : b * q' = b' * q := by
      have : (b : ℤ) * q' = b' * q := by linarith
      exact_mod_cast this
    have hd1 : q ∣ q' := Nat.Coprime.dvd_of_dvd_mul_left hc.symm
      (by rw [hnat]; exact dvd_mul_left _ _)
    have hd2 : q' ∣ q := Nat.Coprime.dvd_of_dvd_mul_left hc'.symm
      (by rw [← hnat]; exact dvd_mul_left _ _)
    have hqe : q = q' := Nat.dvd_antisymm hd1 hd2
    subst hqe
    exact hne ⟨rfl, Nat.eq_of_mul_eq_mul_right (by omega) hnat⟩
  have key : (q : ℤ) * q' ≤ |z| * ((Q : ℤ) * ((Q : ℤ) - 1)) := by
    have hQ1 : (1 : ℤ) ≤ (Q : ℤ) - 1 := by omega
    have hQQ : (Q : ℤ) ≤ Q * (Q - 1) := by nlinarith
    have hQQ0 : (0 : ℤ) ≤ Q * (Q - 1) := by nlinarith
    by_cases hqq : q = q'
    · subst hqq
      have hz' : z = q * (b - b' - m * q) := by rw [hzdef]; ring
      have hin : (b : ℤ) - b' - m * q ≠ 0 := by
        intro h; apply hz0; rw [hz', h, mul_zero]
      have h1 : 1 ≤ |(b : ℤ) - b' - m * q| := Int.one_le_abs hin
      rw [hz', abs_mul, abs_of_nonneg (by positivity : (0 : ℤ) ≤ q)]
      have hqQ' : (q : ℤ) ≤ Q := by exact_mod_cast hqQ
      have h2 := mul_le_mul_of_nonneg_right h1 hQQ0
      have : (q : ℤ) ≤ |(b : ℤ) - b' - m * q| * (Q * (Q - 1)) := by linarith
      have hq0 : (0 : ℤ) ≤ q := by positivity
      have := mul_le_mul_of_nonneg_left this hq0
      linarith
    · have h1 : 1 ≤ |z| := Int.one_le_abs hz0
      have hqQ' : (q : ℤ) ≤ Q := by exact_mod_cast hqQ
      have hq'Q' : (q' : ℤ) ≤ Q := by exact_mod_cast hq'Q
      have hprod : (q : ℤ) * q' ≤ Q * (Q - 1) := by
        rcases lt_or_gt_of_ne hqq with h | h
        · have : (q : ℤ) ≤ Q - 1 := by omega
          nlinarith
        · have : (q' : ℤ) ≤ Q - 1 := by omega
          nlinarith
      have h2 := mul_le_mul_of_nonneg_right h1 hQQ0
      linarith
  have keyR : (q : ℝ) * q' ≤ |(z : ℝ)| * ((Q : ℝ) * ((Q : ℝ) - 1)) := by
    have := key
    exact_mod_cast this
  have hQr : (0 : ℝ) < (Q : ℝ) * ((Q : ℝ) - 1) := by
    have : (2 : ℝ) ≤ Q := by exact_mod_cast hQ
    nlinarith
  rw [hz, abs_div, abs_of_pos (by positivity : (0 : ℝ) < q * q'),
    div_le_div_iff₀ hQr (by positivity)]
  linarith

lemma ls_sin_ne_of_sep {ι : Type*} (x : ι → ℝ) (D : ℝ) (hD : 0 < D)
    (hsep : ∀ r s, r ≠ s → ∀ m : ℤ, 1 / D ≤ |x r - x s - m|) :
    ∀ r s, r ≠ s → Real.sin (Real.pi * (x r - x s)) ≠ 0 := by
  intro r s hrs h
  obtain ⟨n, hn⟩ := Real.sin_eq_zero_iff.mp h
  have hx : x r - x s = n := by
    have := Real.pi_pos
    field_simp at hn
    linarith
  have := hsep r s hrs n
  rw [hx, sub_self, abs_zero] at this
  have : 0 < 1 / D := one_div_pos.2 hD
  linarith


lemma ls_char_sum (q n m : ℕ) (hq : 0 < q) :
    ∑ b ∈ range q, Complex.exp (2 * Real.pi * I * (((n : ℂ) - m) * ((b : ℂ) / q)))
      = if n % q = m % q then (q : ℂ) else 0 := by
  have hqC : (q : ℂ) ≠ 0 := by exact_mod_cast hq.ne'
  set ω := Complex.exp (2 * Real.pi * I * (((n : ℂ) - m) / q)) with hω
  have hpow : ∀ b : ℕ, Complex.exp (2 * Real.pi * I * (((n : ℂ) - m) * ((b : ℂ) / q))) = ω ^ b := by
    intro b
    rw [hω, ← Complex.exp_nat_mul]; congr 1; ring
  simp_rw [hpow]
  have hiff : ω = 1 ↔ n % q = m % q := by
    rw [hω, Complex.exp_eq_one_iff]
    constructor
    · rintro ⟨j, hj⟩
      have hj' : ((n : ℂ) - m) = j * q := by
        field_simp at hj; linear_combination hj
      have hz : ((n : ℤ) - m) = j * q := by exact_mod_cast hj'
      have : (n : ℤ) % q = (m : ℤ) % q := by
        rw [show (n : ℤ) = m + j * q by linarith, Int.add_mul_emod_self_right]
      exact_mod_cast this
    · intro h
      have hd : (q : ℤ) ∣ (n : ℤ) - m := by
        have := (Nat.modEq_iff_dvd (n := q) (a := m) (b := n)).mp h.symm
        exact this
      obtain ⟨j, hj⟩ := hd
      refine ⟨j, ?_⟩
      have : ((n : ℂ) - m) = q * j := by exact_mod_cast hj
      rw [this]; field_simp
  split_ifs with h
  · rw [hiff.mpr h]; simp
  · have hne : ω ≠ 1 := fun h' => h (hiff.mp h')
    rw [geom_sum_eq hne]
    have : ω ^ q = 1 := by
      rw [hω, ← Complex.exp_nat_mul, Complex.exp_eq_one_iff]
      refine ⟨(n : ℤ) - m, ?_⟩
      push_cast; field_simp
    rw [this, sub_self, zero_div]

lemma ls_parseval (q : ℕ) (hq : 0 < q) (A : Finset ℕ) (a : ℕ → ℂ) :
    ∑ b ∈ range q, ‖∑ n ∈ A, a n * Complex.exp (2 * Real.pi * I * ((n : ℂ) * ((b : ℂ) / q)))‖ ^ 2
      = q * ∑ c ∈ range q, ‖∑ n ∈ A with n % q = c, a n‖ ^ 2 := by
  apply Complex.ofReal_injective
  push_cast
  have hsq : ∀ z : ℂ, ((‖z‖ : ℝ) : ℂ) ^ 2 = z * (starRingEnd ℂ) z := fun z => by
    rw [Complex.mul_conj']
  simp_rw [hsq]
  have hconj : ∀ (n : ℕ) (b : ℕ), (starRingEnd ℂ) (Complex.exp (2 * Real.pi * I * ((n : ℂ) * ((b : ℂ) / q))))
      = Complex.exp (-(2 * Real.pi * I * ((n : ℂ) * ((b : ℂ) / q)))) := by
    intro n b
    rw [← Complex.exp_conj]; congr 1
    simp [map_mul, Complex.conj_ofReal, Complex.conj_I, map_div₀, map_natCast, map_ofNat]
  -- left side
  have hL : ∀ b ∈ range q,
      (∑ n ∈ A, a n * Complex.exp (2 * Real.pi * I * ((n : ℂ) * ((b : ℂ) / q))))
        * (starRingEnd ℂ) (∑ n ∈ A, a n * Complex.exp (2 * Real.pi * I * ((n : ℂ) * ((b : ℂ) / q))))
      = ∑ n ∈ A, ∑ m ∈ A, a n * (starRingEnd ℂ) (a m)
          * Complex.exp (2 * Real.pi * I * (((n : ℂ) - m) * ((b : ℂ) / q))) := by
    intro b _
    rw [map_sum, Finset.sum_mul_sum]
    refine Finset.sum_congr rfl fun n _ => Finset.sum_congr rfl fun m _ => ?_
    rw [map_mul, hconj, show a n * Complex.exp (2 * Real.pi * I * ((n : ℂ) * ((b : ℂ) / q)))
        * ((starRingEnd ℂ) (a m) * Complex.exp (-(2 * Real.pi * I * ((m : ℂ) * ((b : ℂ) / q)))))
        = a n * (starRingEnd ℂ) (a m) * (Complex.exp (2 * Real.pi * I * ((n : ℂ) * ((b : ℂ) / q)))
          * Complex.exp (-(2 * Real.pi * I * ((m : ℂ) * ((b : ℂ) / q))))) by ring,
      ← Complex.exp_add]
    congr 2; ring
  rw [Finset.sum_congr rfl hL, Finset.sum_comm]
  simp_rw [Finset.sum_comm (s := range q), ← Finset.mul_sum, ls_char_sum q _ _ hq]
  -- right side
  have hR : ∀ c ∈ range q, (∑ n ∈ A with n % q = c, a n) * (starRingEnd ℂ) (∑ n ∈ A with n % q = c, a n)
      = ∑ n ∈ A with n % q = c, ∑ m ∈ A with m % q = n % q, a n * (starRingEnd ℂ) (a m) := by
    intro c _
    rw [map_sum, Finset.sum_mul_sum]
    refine Finset.sum_congr rfl fun n hn => ?_
    rw [(Finset.mem_filter.mp hn).2]
  rw [Finset.sum_congr rfl hR, Finset.sum_fiberwise_of_maps_to (g := fun n => n % q)
    (fun n _ => Finset.mem_range.mpr (Nat.mod_lt _ hq)), Finset.mul_sum]
  refine Finset.sum_congr rfl fun n _ => ?_
  rw [Finset.sum_filter, Finset.mul_sum]
  refine Finset.sum_congr rfl fun m _ => ?_
  by_cases h : n % q = m % q
  · have h' : m % q = n % q := h.symm
    rw [ite_eq_left h, ite_eq_left h']; ring
  · have h' : ¬ m % q = n % q := fun e => h e.symm
    rw [ite_eq_right h, ite_eq_right h']; ring


lemma ls_floor_prime (p : ℕ) (hp : p.Prime) (A : Finset ℕ) (kp : ℕ)
    (hk : ((range p).filter (fun b => ∀ n ∈ A, n % p ≠ b)).card = kp) (a : ℕ → ℂ) :
    ‖∑ n ∈ A, a n‖ ^ 2 * ((kp : ℝ) / ((p : ℝ) - kp))
      ≤ ∑ b ∈ (range p).filter (fun b => Nat.Coprime b p),
          ‖∑ n ∈ A, a n * Complex.exp (2 * Real.pi * I * ((n : ℂ) * ((b : ℂ) / p)))‖ ^ 2 := by
  classical
  set Miss := (range p).filter (fun b => ∀ n ∈ A, n % p ≠ b) with hMiss
  set Z : ℕ → ℂ := fun c => ∑ n ∈ A with n % p = c, a n with hZ
  set X : ℝ := ∑ c ∈ range p, ‖Z c‖ ^ 2 with hX
  set s0 : ℝ := ‖∑ n ∈ A, a n‖ ^ 2 with hs0
  set S : ℕ → ℝ := fun b =>
    ‖∑ n ∈ A, a n * Complex.exp (2 * Real.pi * I * ((n : ℂ) * ((b : ℂ) / p)))‖ ^ 2 with hS
  have hpar : ∑ b ∈ range p, S b = p * X := ls_parseval p hp.pos A a
  have hR : (range p).filter (fun b => Nat.Coprime b p) = (range p).erase 0 := by
    ext b
    simp only [Finset.mem_filter, Finset.mem_range, Finset.mem_erase]
    constructor
    · rintro ⟨hb, hc⟩
      refine ⟨?_, hb⟩
      rintro rfl
      rw [Nat.coprime_zero_left] at hc
      exact hp.one_lt.ne' hc
    · rintro ⟨hb0, hb⟩
      refine ⟨hb, ?_⟩
      rw [Nat.coprime_comm, hp.coprime_iff_not_dvd]
      intro hd
      exact hb0 (Nat.eq_zero_of_dvd_of_lt hd hb)
  have hS0 : S 0 = s0 := by simp [hS, hs0]
  have hsplit : ∑ b ∈ range p, S b = s0 + ∑ b ∈ (range p).filter (fun b => Nat.Coprime b p), S b := by
    rw [hR, ← hS0, Finset.add_sum_erase _ _ (Finset.mem_range.mpr hp.pos)]
  have hfib : ∑ c ∈ range p, Z c = ∑ n ∈ A, a n :=
    Finset.sum_fiberwise_of_maps_to (g := fun n => n % p)
      (fun n _ => Finset.mem_range.mpr (Nat.mod_lt _ hp.pos)) a
  have hmissZ : ∀ c ∈ Miss, Z c = 0 := by
    intro c hc
    rw [hMiss, Finset.mem_filter] at hc
    apply Finset.sum_eq_zero
    intro n hn
    rw [Finset.mem_filter] at hn
    exact absurd hn.2 (hc.2 n hn.1)
  have hsub : Miss ⊆ range p := Finset.filter_subset _ _
  have hkp : kp ≤ p := by rw [← hk]; simpa using Finset.card_filter_le (range p) _
  have hcardT : ((range p \ Miss).card : ℝ) = (p : ℝ) - kp := by
    rw [Finset.card_sdiff_of_subset hsub, Finset.card_range, hk]
    push_cast [hkp]; ring
  have hCS : s0 ≤ ((p : ℝ) - kp) * X := by
    have hsumT : ∑ c ∈ range p, Z c = ∑ c ∈ range p \ Miss, Z c := by
      rw [← Finset.sum_sdiff hsub, Finset.sum_eq_zero hmissZ, add_zero]
    have h1 : s0 ≤ (∑ c ∈ range p \ Miss, ‖Z c‖) ^ 2 := by
      rw [hs0, ← hfib, hsumT]
      exact pow_le_pow_left₀ (norm_nonneg _) (norm_sum_le _ _) 2
    have h2 := Finset.sum_mul_sq_le_sq_mul_sq (range p \ Miss) (fun _ => (1 : ℝ)) (fun c => ‖Z c‖)
    simp only [one_mul, one_pow, Finset.sum_const, nsmul_eq_mul, mul_one] at h2
    have h3 : ∑ c ∈ range p \ Miss, ‖Z c‖ ^ 2 ≤ X :=
      Finset.sum_le_sum_of_subset_of_nonneg Finset.sdiff_subset (fun c _ _ => sq_nonneg _)
    rw [hcardT] at h2
    have hpk : 0 ≤ (p : ℝ) - kp := by
      have : (kp : ℝ) ≤ p := by exact_mod_cast hkp
      linarith
    calc s0 ≤ _ := h1
      _ ≤ ((p : ℝ) - kp) * ∑ c ∈ range p \ Miss, ‖Z c‖ ^ 2 := h2
      _ ≤ ((p : ℝ) - kp) * X := mul_le_mul_of_nonneg_left h3 hpk
  have hs0nn : 0 ≤ s0 := sq_nonneg _
  have hX0 : 0 ≤ X := Finset.sum_nonneg fun c _ => sq_nonneg _
  show s0 * ((kp : ℝ) / ((p : ℝ) - kp)) ≤ ∑ b ∈ (range p).filter (fun b => Nat.Coprime b p), S b
  have hgoal : ∑ b ∈ (range p).filter (fun b => Nat.Coprime b p), S b = p * X - s0 := by
    linarith [hsplit, hpar]
  rw [hgoal]
  have hkpR : (kp : ℝ) ≤ p := by exact_mod_cast hkp
  rcases (show (0 : ℝ) ≤ (p : ℝ) - kp by linarith).lt_or_eq with hpos | hzero
  · rw [mul_div_assoc', div_le_iff₀ hpos]
    nlinarith
  · rw [← hzero, div_zero, mul_zero]
    rw [← hzero, zero_mul] at hCS
    have : (0 : ℝ) ≤ p := by positivity
    nlinarith


lemma ls_exp_mod (n c Q : ℕ) (hQ : 0 < Q) :
    Complex.exp (2 * Real.pi * I * ((n : ℂ) * (((c % Q : ℕ) : ℂ) / (Q : ℂ))))
      = Complex.exp (2 * Real.pi * I * ((n : ℂ) * ((c : ℂ) / (Q : ℂ)))) := by
  have hQC : (Q : ℂ) ≠ 0 := by exact_mod_cast hQ.ne'
  have hc : (c : ℂ) = Q * ((c / Q : ℕ) : ℂ) + ((c % Q : ℕ) : ℂ) := by
    exact_mod_cast (Nat.div_add_mod c Q).symm
  rw [hc, show 2 * (Real.pi : ℂ) * I * ((n : ℂ) * ((Q * ((c / Q : ℕ) : ℂ) + ((c % Q : ℕ) : ℂ)) / Q))
      = 2 * Real.pi * I * ((n : ℂ) * (((c % Q : ℕ) : ℂ) / Q)) + ((n * (c / Q) : ℕ) : ℂ) * (2 * Real.pi * I) by
      push_cast; field_simp; ring, Complex.exp_add, Complex.exp_nat_mul_two_pi_mul_I, mul_one]

lemma ls_coprime_mod (c m : ℕ) : Nat.Coprime (c % m) m ↔ Nat.Coprime c m := by
  unfold Nat.Coprime
  rw [← Nat.gcd_rec, Nat.gcd_comm]

lemma ls_crt (q1 q2 : ℕ) (h1 : 0 < q1) (h2 : 0 < q2) (hc : Nat.Coprime q1 q2)
    (A : Finset ℕ) (a : ℕ → ℂ) :
    ∑ b ∈ (range (q1 * q2)).filter (fun b => Nat.Coprime b (q1 * q2)),
        ‖∑ n ∈ A, a n * Complex.exp (2 * Real.pi * I * ((n : ℂ) * ((b : ℂ) / ((q1 * q2 : ℕ) : ℂ))))‖ ^ 2
      = ∑ b1 ∈ (range q1).filter (fun b => Nat.Coprime b q1),
          ∑ b2 ∈ (range q2).filter (fun b => Nat.Coprime b q2),
            ‖∑ n ∈ A, (a n * Complex.exp (2 * Real.pi * I * ((n : ℂ) * ((b1 : ℂ) / q1))))
              * Complex.exp (2 * Real.pi * I * ((n : ℂ) * ((b2 : ℂ) / q2)))‖ ^ 2 := by
  classical
  set R1 := (range q1).filter (fun b => Nat.Coprime b q1) with hR1
  set R2 := (range q2).filter (fun b => Nat.Coprime b q2) with hR2
  set R := (range (q1 * q2)).filter (fun b => Nat.Coprime b (q1 * q2)) with hR
  set F : ℕ → ℝ := fun b =>
    ‖∑ n ∈ A, a n * Complex.exp (2 * Real.pi * I * ((n : ℂ) * ((b : ℂ) / ((q1 * q2 : ℕ) : ℂ))))‖ ^ 2
    with hF
  set φ : ℕ × ℕ → ℕ := fun p => (p.1 * q2 + p.2 * q1) % (q1 * q2) with hφ
  have hQ : 0 < q1 * q2 := Nat.mul_pos h1 h2
  have hq1C : (q1 : ℂ) ≠ 0 := by exact_mod_cast h1.ne'
  have hq2C : (q2 : ℂ) ≠ 0 := by exact_mod_cast h2.ne'
  -- each pair term equals F (φ p)
  have hpair : ∀ b1 b2 : ℕ,
      ‖∑ n ∈ A, (a n * Complex.exp (2 * Real.pi * I * ((n : ℂ) * ((b1 : ℂ) / q1))))
        * Complex.exp (2 * Real.pi * I * ((n : ℂ) * ((b2 : ℂ) / q2)))‖ ^ 2 = F (φ (b1, b2)) := by
    intro b1 b2
    simp only [hF, hφ]
    congr 2
    refine Finset.sum_congr rfl fun n _ => ?_
    rw [ls_exp_mod n _ _ hQ, mul_assoc, ← Complex.exp_add]
    congr 2
    push_cast
    field_simp
  simp_rw [hpair]
  rw [← Finset.sum_product' (f := fun b1 b2 => F (φ (b1, b2)))]
  -- φ is injective on R1 × R2 and its image is R
  have hmod1 : ∀ p : ℕ × ℕ, φ p % q1 = (p.1 * q2) % q1 := by
    intro p
    simp only [hφ]
    rw [Nat.mod_mod_of_dvd _ (dvd_mul_right q1 q2), Nat.add_mul_mod_self_right]
  have hmod2 : ∀ p : ℕ × ℕ, φ p % q2 = (p.2 * q1) % q2 := by
    intro p
    simp only [hφ]
    rw [Nat.mod_mod_of_dvd _ (dvd_mul_left q2 q1), add_comm, Nat.add_mul_mod_self_right]
  have hinj : Set.InjOn φ (R1 ×ˢ R2 : Finset (ℕ × ℕ)) := by
    intro p hp p' hp' heq
    simp only [Finset.coe_product, Set.mem_prod, Finset.mem_coe, hR1, hR2, Finset.mem_filter,
      Finset.mem_range] at hp hp'
    have e1 : (p.1 * q2) % q1 = (p'.1 * q2) % q1 := by rw [← hmod1, ← hmod1, heq]
    have e2 : (p.2 * q1) % q2 = (p'.2 * q1) % q2 := by rw [← hmod2, ← hmod2, heq]
    have m1 : p.1 ≡ p'.1 [MOD q1] := Nat.ModEq.cancel_right_of_coprime hc e1
    have m2 : p.2 ≡ p'.2 [MOD q2] := Nat.ModEq.cancel_right_of_coprime hc.symm e2
    unfold Nat.ModEq at m1 m2
    rw [Nat.mod_eq_of_lt hp.1.1, Nat.mod_eq_of_lt hp'.1.1] at m1
    rw [Nat.mod_eq_of_lt hp.2.1, Nat.mod_eq_of_lt hp'.2.1] at m2
    exact Prod.ext m1 m2
  have hmaps : ∀ p ∈ R1 ×ˢ R2, φ p ∈ R := by
    intro p hp
    simp only [Finset.mem_product, hR1, hR2, Finset.mem_filter, Finset.mem_range] at hp
    simp only [hR, Finset.mem_filter, Finset.mem_range]
    refine ⟨Nat.mod_lt _ hQ, ?_⟩
    simp only [hφ]
    rw [ls_coprime_mod]
    apply Nat.Coprime.mul_right
    · rw [← ls_coprime_mod, Nat.add_mul_mod_self_right, ls_coprime_mod]
      exact Nat.coprime_mul_iff_left.mpr ⟨hp.1.2, hc.symm⟩
    · rw [← ls_coprime_mod, add_comm, Nat.add_mul_mod_self_right, ls_coprime_mod]
      exact Nat.coprime_mul_iff_left.mpr ⟨hp.2.2, hc⟩
  have hcardR : ∀ q, ((range q).filter (fun b => Nat.Coprime b q)).card = Nat.totient q := by
    intro q
    rw [Nat.totient_eq_card_coprime]
    congr 1
    ext b
    simp [Nat.coprime_comm]
  have himage : (R1 ×ˢ R2).image φ = R := by
    apply Finset.eq_of_subset_of_card_le
    · intro b hb
      obtain ⟨p, hp, rfl⟩ := Finset.mem_image.mp hb
      exact hmaps p hp
    · rw [Finset.card_image_of_injOn hinj, Finset.card_product, hR, hR1, hR2, hcardR, hcardR,
        hcardR, Nat.totient_mul hc]
  rw [← himage, Finset.sum_image hinj]


lemma ls_floor_gen (A : Finset ℕ) (k : ℕ → ℕ) (q : ℕ) :
    Squarefree q → (∀ p ∈ q.primeFactors,
      ((range p).filter (fun b => ∀ n ∈ A, n % p ≠ b)).card = k p) → ∀ w : ℕ → ℂ,
    ‖∑ n ∈ A, w n‖ ^ 2 * ∏ p ∈ q.primeFactors, ((k p : ℝ) / ((p : ℝ) - k p))
      ≤ ∑ b ∈ (range q).filter (fun b => Nat.Coprime b q),
          ‖∑ n ∈ A, w n * Complex.exp (2 * Real.pi * I * ((n : ℂ) * ((b : ℂ) / q)))‖ ^ 2 := by
  induction q using Nat.recOnPosPrimePosCoprime with
  | prime_pow p n hp hn =>
    intro hsq hk w
    have hn1 : n = 1 := ((Nat.squarefree_pow_iff hp.ne_one hn.ne').mp hsq).2
    subst hn1
    rw [pow_one] at hk ⊢
    rw [hp.primeFactors, Finset.prod_singleton]
    exact ls_floor_prime p hp A (k p) (hk p (by rw [hp.primeFactors]; exact Finset.mem_singleton_self p)) w
  | zero => intro hsq; exact absurd hsq not_squarefree_zero
  | one =>
    intro _ _ w
    rw [Nat.primeFactors_one, Finset.prod_empty, mul_one]
    have : (range 1).filter (fun b => Nat.Coprime b 1) = {0} := by decide
    rw [this, Finset.sum_singleton]
    simp
  | coprime q1 q2 hq1 hq2 hc ih1 ih2 =>
    intro hsq hk w
    have hs1 : Squarefree q1 := hsq.of_mul_left
    have hs2 : Squarefree q2 := hsq.of_mul_right
    have hpf := Nat.Coprime.primeFactors_mul hc
    have hk1 : ∀ p ∈ q1.primeFactors, ((range p).filter (fun b => ∀ n ∈ A, n % p ≠ b)).card = k p :=
      fun p hp => hk p (by rw [hpf]; exact Finset.mem_union_left _ hp)
    have hk2 : ∀ p ∈ q2.primeFactors, ((range p).filter (fun b => ∀ n ∈ A, n % p ≠ b)).card = k p :=
      fun p hp => hk p (by rw [hpf]; exact Finset.mem_union_right _ hp)
    have hfac0 : ∀ p ∈ (q1 * q2).primeFactors, 0 ≤ (k p : ℝ) / ((p : ℝ) - k p) := by
      intro p hp
      have hkp : k p ≤ p := by
        rw [← hk p hp]; simpa using Finset.card_filter_le (range p) _
      have : (k p : ℝ) ≤ p := by exact_mod_cast hkp
      apply div_nonneg (by positivity) (by linarith)
    have h20 : 0 ≤ ∏ p ∈ q2.primeFactors, ((k p : ℝ) / ((p : ℝ) - k p)) :=
      Finset.prod_nonneg fun p hp => hfac0 p (by rw [hpf]; exact Finset.mem_union_right _ hp)
    rw [hpf, Finset.prod_union (Nat.Coprime.disjoint_primeFactors hc)]
    rw [ls_crt q1 q2 (by omega) (by omega) hc A w]
    set h1 := ∏ p ∈ q1.primeFactors, ((k p : ℝ) / ((p : ℝ) - k p))
    set h2 := ∏ p ∈ q2.primeFactors, ((k p : ℝ) / ((p : ℝ) - k p))
    calc ‖∑ n ∈ A, w n‖ ^ 2 * (h1 * h2) = h2 * (‖∑ n ∈ A, w n‖ ^ 2 * h1) := by ring
      _ ≤ h2 * ∑ b1 ∈ (range q1).filter (fun b => Nat.Coprime b q1),
            ‖∑ n ∈ A, w n * Complex.exp (2 * Real.pi * I * ((n : ℂ) * ((b1 : ℂ) / q1)))‖ ^ 2 :=
          mul_le_mul_of_nonneg_left (ih1 hs1 hk1 w) h20
      _ = ∑ b1 ∈ (range q1).filter (fun b => Nat.Coprime b q1),
            ‖∑ n ∈ A, w n * Complex.exp (2 * Real.pi * I * ((n : ℂ) * ((b1 : ℂ) / q1)))‖ ^ 2 * h2 := by
          rw [Finset.mul_sum]; exact Finset.sum_congr rfl fun _ _ => by ring
      _ ≤ _ := Finset.sum_le_sum fun b1 _ => ih2 hs2 hk2 _

/-- **The large sieve inequality.** Take N whole numbers in a row, M + 1 to M + N, with any start
M, and any complex weight a_n on each. Let S(α) = ∑ a_n e(nα), with e(x) = e^(2πix). Add the
squared size |S(a/q)|² over every reduced fraction a/q, 0 ≤ a < q, gcd(a, q) = 1, with
denominator q from 1 to Q. That total is at most (N − 1 + Q²) times ∑ |a_n|². -/
theorem large_sieve_inequality (a : ℕ → ℂ) (M N Q : ℕ) :
    ∑ q ∈ Icc 1 Q, ∑ b ∈ (range q).filter (fun b => Nat.Coprime b q),
        ‖∑ n ∈ Ioc M (M + N), a n * Complex.exp (2 * pi * I * ((n : ℂ) * ((b : ℂ) / q)))‖ ^ 2
      ≤ ((N : ℝ) - 1 + (Q : ℝ) ^ 2) * ∑ n ∈ Ioc M (M + N), ‖a n‖ ^ 2 := by
  classical
  set F : Finset (Σ _ : ℕ, ℕ) :=
    (Icc 1 Q).sigma (fun q => (range q).filter (fun b => Nat.Coprime b q)) with hF
  set x : F → ℝ := fun p => (p.1.2 : ℝ) / p.1.1 with hx
  have hLHS : (∑ q ∈ Icc 1 Q, ∑ b ∈ (range q).filter (fun b => Nat.Coprime b q),
        ‖∑ n ∈ Ioc M (M + N), a n * Complex.exp (2 * pi * I * ((n : ℂ) * ((b : ℂ) / q)))‖ ^ 2)
      = ∑ p : F, ‖∑ n ∈ Ioc M (M + N),
          a n * Complex.exp (2 * Real.pi * I * ((n : ℂ) * (x p : ℂ)))‖ ^ 2 := by
    rw [Finset.sum_coe_sort F (fun p => ‖∑ n ∈ Ioc M (M + N),
          a n * Complex.exp (2 * Real.pi * I * ((n : ℂ) * (((p.2 : ℝ) / p.1 : ℝ) : ℂ)))‖ ^ 2),
      hF, Finset.sum_sigma]
    push_cast
    rfl
  have mem : ∀ p : F, 1 ≤ p.1.1 ∧ p.1.1 ≤ Q ∧ p.1.2 < p.1.1 ∧ Nat.Coprime p.1.2 p.1.1 := by
    intro p
    have := p.2
    simp only [hF, Finset.mem_sigma, Finset.mem_Icc, Finset.mem_filter, Finset.mem_range] at this
    tauto
  have hsum0 : 0 ≤ ∑ n ∈ Ioc M (M + N), ‖a n‖ ^ 2 := Finset.sum_nonneg fun n _ => sq_nonneg _
  rw [hLHS]
  rcases Nat.lt_or_ge Q 2 with hQ | hQ
  · interval_cases Q
    · have : IsEmpty F := ⟨fun p => by have := mem p; omega⟩
      rw [Finset.univ_eq_empty, Finset.sum_empty]
      rcases Nat.eq_zero_or_pos N with hN | hN
      · subst hN; simp
      · have : (1 : ℝ) ≤ N := by exact_mod_cast hN
        apply mul_nonneg _ hsum0
        push_cast; linarith
    · have hsub : ∀ r s : F, r = s := by
        intro r s
        have hr := mem r
        have hs := mem s
        apply Subtype.ext
        apply Sigma.ext (by omega)
        exact heq_of_eq (by omega)
      have hB : ∀ s, ∑ r, lsC x r s ^ 2 ≤ 0 := by
        intro s
        apply le_of_eq
        apply Finset.sum_eq_zero
        intro r _
        simp [lsC, hsub r s]
      have := ls_primal x (fun r s h => absurd (hsub r s) h) 0 hB a M N
      simpa using this
  · set D : ℝ := (Q : ℝ) * ((Q : ℝ) - 1) with hDdef
    have hQr : (2 : ℝ) ≤ Q := by exact_mod_cast hQ
    have hD : 0 < D := by rw [hDdef]; nlinarith
    have hsep : ∀ r s : F, r ≠ s → ∀ m : ℤ, 1 / D ≤ |x r - x s - m| := by
      intro r s hrs m
      obtain ⟨h1, h2, h3, h4⟩ := mem r
      obtain ⟨h1', h2', h3', h4'⟩ := mem s
      exact ls_farey_sep Q _ _ _ _ hQ h1 h2 h3 h4 h1' h2' h3' h4'
        (fun ⟨e1, e2⟩ => hrs (Subtype.ext (Sigma.ext e1 (heq_of_eq e2)))) m
    have hsin := ls_sin_ne_of_sep x D hD hsep
    set B : ℝ := 2 * ∑ k ∈ Icc 1 ⌊D / 2⌋₊, 1 / Real.sin (Real.pi * k / D) ^ 2 with hBdef
    have hB : ∀ s, ∑ r, lsC x r s ^ 2 ≤ B := ls_csc_sum x D hD hsep
    have hmain := ls_primal x hsin B hB a M N
    have hroot : Real.sqrt (3 * B) ≤ (Q : ℝ) ^ 2 - 1 := by
      have hQ1 : 0 ≤ (Q : ℝ) ^ 2 - 1 := by nlinarith
      rw [← Real.sqrt_sq hQ1]
      apply Real.sqrt_le_sqrt
      rcases Nat.eq_or_lt_of_le hQ with h2 | h3
      · subst h2
        have hD2 : D = 2 := by rw [hDdef]; norm_num
        have hfl : ⌊D / 2⌋₊ = 1 := by rw [hD2]; norm_num
        rw [hBdef, hfl, hD2]
        norm_num
      · have hQ3 : (3 : ℝ) ≤ Q := by exact_mod_cast h3
        have hnum := ls_csc_numeric D hD
        have hfl : (⌊D / 2⌋₊ : ℝ) ≤ D / 2 := Nat.floor_le (by positivity)
        have h3B : 3 * B ≤ D ^ 2 + 3 * D := by rw [hBdef]; nlinarith
        have : D ^ 2 + 3 * D ≤ ((Q : ℝ) ^ 2 - 1) ^ 2 := by
          rw [hDdef]; nlinarith [mul_nonneg (by linarith : (0:ℝ) ≤ (Q:ℝ) - 3) (by linarith : (0:ℝ) ≤ (Q:ℝ) - 1)]
        linarith
    calc _ ≤ ((N : ℝ) + Real.sqrt (3 * B)) * ∑ n ∈ Ioc M (M + N), ‖a n‖ ^ 2 := hmain
      _ ≤ ((N : ℝ) - 1 + (Q : ℝ) ^ 2) * ∑ n ∈ Ioc M (M + N), ‖a n‖ ^ 2 := by
          apply mul_le_mul_of_nonneg_right _ hsum0
          linarith

/-- **The large sieve bound on a set.** Let A be a set of whole numbers in the range M + 1 to
M + N, and let Q be the largest denominator used (at least 1, so the term q = 1 is present).
Suppose that for each prime p ≤ Q the set misses exactly k_p of the p classes mod p. Put
L = ∑_{q ≤ Q} μ²(q) ∏_{p ∣ q} k_p/(p − k_p). Then A has at most (N − 1 + Q²)/L members. -/
theorem large_sieve_set_bound (A : Finset ℕ) (M N Q : ℕ) (k : ℕ → ℕ)
    (hA : A ⊆ Ioc M (M + N)) (hQ : 1 ≤ Q)
    (hk : ∀ p, p.Prime → p ≤ Q → ((range p).filter (fun b => ∀ n ∈ A, n % p ≠ b)).card = k p) :
    (A.card : ℝ) ≤ ((N : ℝ) - 1 + (Q : ℝ) ^ 2) /
      ∑ q ∈ Icc 1 Q, ((ArithmeticFunction.moebius q : ℤ) : ℝ) ^ 2 *
        ∏ p ∈ q.primeFactors, ((k p : ℝ) / ((p : ℝ) - k p)) := by
  classical
  set L := ∑ q ∈ Icc 1 Q, ((ArithmeticFunction.moebius q : ℤ) : ℝ) ^ 2 *
        ∏ p ∈ q.primeFactors, ((k p : ℝ) / ((p : ℝ) - k p)) with hL
  have hkq : ∀ q ∈ Icc 1 Q, ∀ p ∈ q.primeFactors,
      ((range p).filter (fun b => ∀ n ∈ A, n % p ≠ b)).card = k p :=
    fun q hq p hp => hk p (Nat.prime_of_mem_primeFactors hp)
      ((Nat.le_of_mem_primeFactors hp).trans (Finset.mem_Icc.mp hq).2)
  have hfac0 : ∀ q ∈ Icc 1 Q, 0 ≤ ∏ p ∈ q.primeFactors, ((k p : ℝ) / ((p : ℝ) - k p)) := by
    intro q hq
    apply Finset.prod_nonneg
    intro p hp
    have hkp : k p ≤ p := by
      rw [← hkq q hq p hp]; simpa using Finset.card_filter_le (range p) _
    have : (k p : ℝ) ≤ p := by exact_mod_cast hkp
    exact div_nonneg (by positivity) (by linarith)
  have hterm0 : ∀ q ∈ Icc 1 Q, 0 ≤ ((ArithmeticFunction.moebius q : ℤ) : ℝ) ^ 2 *
      ∏ p ∈ q.primeFactors, ((k p : ℝ) / ((p : ℝ) - k p)) :=
    fun q hq => mul_nonneg (sq_nonneg _) (hfac0 q hq)
  have hL1 : 1 ≤ L := by
    have h1mem : 1 ∈ Icc 1 Q := Finset.mem_Icc.mpr ⟨le_refl 1, hQ⟩
    calc (1 : ℝ) = ((ArithmeticFunction.moebius 1 : ℤ) : ℝ) ^ 2 *
          ∏ p ∈ (1 : ℕ).primeFactors, ((k p : ℝ) / ((p : ℝ) - k p)) := by simp
      _ ≤ L := Finset.single_le_sum hterm0 h1mem
  set E := ∑ q ∈ Icc 1 Q, ∑ b ∈ (range q).filter (fun b => Nat.Coprime b q),
      ‖∑ n ∈ A, Complex.exp (2 * Real.pi * I * ((n : ℂ) * ((b : ℂ) / q)))‖ ^ 2 with hE
  have hlow : (A.card : ℝ) ^ 2 * L ≤ E := by
    rw [hL, Finset.mul_sum]
    apply Finset.sum_le_sum
    intro q hq
    by_cases hsq : Squarefree q
    · have hmu : ((ArithmeticFunction.moebius q : ℤ) : ℝ) ^ 2 = 1 := by
        have := ArithmeticFunction.moebius_sq_eq_one_of_squarefree hsq
        exact_mod_cast this
      rw [hmu, one_mul]
      have := ls_floor_gen A k q hsq (hkq q hq) (fun _ => 1)
      simpa using this
    · rw [ArithmeticFunction.moebius_eq_zero_of_not_squarefree hsq]
      simp only [Int.cast_zero, ne_eq, OfNat.ofNat_ne_zero, not_false_eq_true, zero_pow,
        zero_mul, mul_zero]
      exact Finset.sum_nonneg fun b _ => sq_nonneg _
  have hup : E ≤ ((N : ℝ) - 1 + (Q : ℝ) ^ 2) * A.card := by
    have h := large_sieve_inequality (fun n => if n ∈ A then 1 else 0) M N Q
    have hS : ∀ t : ℂ, ∑ n ∈ Ioc M (M + N),
        (if n ∈ A then (1 : ℂ) else 0) * Complex.exp (2 * Real.pi * I * ((n : ℂ) * t))
        = ∑ n ∈ A, Complex.exp (2 * Real.pi * I * ((n : ℂ) * t)) := by
      intro t
      simp only [ite_mul, one_mul, zero_mul]
      rw [Finset.sum_ite_mem, Finset.inter_eq_right.mpr hA]
    have hN : ∑ n ∈ Ioc M (M + N), ‖(if n ∈ A then (1 : ℂ) else 0)‖ ^ 2 = A.card := by
      have : ∀ n, ‖(if n ∈ A then (1 : ℂ) else 0)‖ ^ 2 = if n ∈ A then (1 : ℝ) else 0 := by
        intro n; split_ifs <;> simp
      simp only [this]
      rw [Finset.sum_ite_mem, Finset.inter_eq_right.mpr hA]
      simp
    simp only [hS, hN] at h
    exact h
  have hL0 : 0 < L := by linarith
  have hQr : (1 : ℝ) ≤ Q := by exact_mod_cast hQ
  have hnum : 0 ≤ (N : ℝ) - 1 + (Q : ℝ) ^ 2 := by
    have : (0 : ℝ) ≤ N := by positivity
    nlinarith
  rcases Nat.eq_zero_or_pos A.card with h0 | hpos
  · rw [h0, Nat.cast_zero]
    exact div_nonneg hnum hL0.le
  · rw [le_div_iff₀ hL0]
    have hc : (0 : ℝ) < A.card := by exact_mod_cast hpos
    have h2 : (A.card : ℝ) * ((A.card : ℝ) * L) ≤ (A.card : ℝ) * ((N : ℝ) - 1 + (Q : ℝ) ^ 2) := by
      nlinarith [hlow, hup]
    exact le_of_mul_le_mul_left h2 hc

/-- **Missing classes force energy (Steps 2 and 3).** Let A be a finite set of whole numbers
and q a squarefree modulus. Suppose that for each prime p dividing q the set misses exactly k_p
of the p classes mod p. Then the wave energy of A at the reduced fractions a/q is at least
|A|² times the product, over the primes p of q, of the odds k_p/(p − k_p). -/
theorem large_sieve_energy_floor (A : Finset ℕ) (q : ℕ) (k : ℕ → ℕ) (hq : Squarefree q)
    (hk : ∀ p ∈ q.primeFactors,
      ((range p).filter (fun b => ∀ n ∈ A, n % p ≠ b)).card = k p) :
    (A.card : ℝ) ^ 2 * ∏ p ∈ q.primeFactors, ((k p : ℝ) / ((p : ℝ) - k p))
      ≤ ∑ b ∈ (range q).filter (fun b => Nat.Coprime b q),
          ‖∑ n ∈ A, Complex.exp (2 * pi * I * ((n : ℂ) * ((b : ℂ) / q)))‖ ^ 2 := by
  have := ls_floor_gen A k q hq hk (fun _ => 1)
  simpa using this

-- Mod 7 the squares land only in the classes 0, 1, 2 and 4, so they miss 3, 5 and 6.
example : (range 7).image (fun n => n ^ 2 % 7) = {0, 1, 2, 4} := by decide

-- The 100 squares 1², …, 100² leave remainders 0, 1, 2 mod 3 exactly 33, 67 and 0 times.
example : ((Icc 1 100).filter (fun m => m ^ 2 % 3 = 0)).card = 33 := by decide
example : ((Icc 1 100).filter (fun m => m ^ 2 % 3 = 1)).card = 67 := by decide
example : ((Icc 1 100).filter (fun m => m ^ 2 % 3 = 2)).card = 0 := by decide

-- By hand mod 3: |S(1/3)|² = 33² + 67² − 33 × 67 = 3,367, and Parseval: 3 × (33² + 67²) = 10,000 + 2 × 3,367.
example : 33 ^ 2 + 67 ^ 2 - 33 * 67 = 3367 := by norm_num
example : 3 * (33 ^ 2 + 67 ^ 2) = 16734 ∧ 16734 = 100 ^ 2 + 2 * 3367 := by norm_num

-- The floor from Step 2 mod 3: 100² × 1/(3 − 1) = 5,000, below the true energy 6,734.
example : (100 : ℚ) ^ 2 * (1 / (3 - 1)) = 5000 ∧ (5000 : ℚ) ≤ 6734 := by norm_num

-- L to q = 15 for the squares: 1 + 1/2 + 2/3 + 3/4 + 5/6 + 6/7 + (1/2)(2/3) = 415/84.
example : (1 : ℚ) + 1 / 2 + 2 / 3 + 3 / 4 + 5 / 6 + 6 / 7 + (1 / 2) * (2 / 3) = 415 / 84 := by
  norm_num

-- The budget for N = 10,000 and Q = 100: N − 1 + Q² = 19,999, times |A| = 100 gives 1,999,900.
example : 10000 - 1 + 100 ^ 2 = 19999 ∧ 19999 * 100 = 1999900 := by norm_num

-- There are 3,044 reduced fractions a/q with q ≤ 100, and the closest pair, 1/100 and 1/99, is 1/9,900 apart.
example : ∑ q ∈ Icc 1 100, ((range q).filter (fun b => Nat.Coprime b q)).card = 3044 := by
  decide +kernel
example : (1 : ℚ) / 99 - 1 / 100 = 1 / 9900 := by norm_num

-- What breaks: 3,044 points all at 0 give 3,044 × 100² = 30,440,000, far above the budget 1,999,900.
example : 3044 * 100 ^ 2 = 30440000 ∧ 1999900 < 30440000 := by norm_num

#print axioms lsC_antisymm
#print axioms lsK_antisymm
#print axioms lsK_abs_le
#print axioms lsC_mul_lsC
#print axioms ls_energy_identity
#print axioms ls_eig_bound
#print axioms ls_quad_le
#print axioms ls_hilbert
#print axioms ls_geom
#print axioms ls_two_I_sin
#print axioms ls_dual
#print axioms ls_primal
#print axioms ls_sin_sq_fract
#print axioms ls_csc_sum
#print axioms ls_inv_sin_sq_le
#print axioms ls_csc_numeric
#print axioms ls_farey_sep
#print axioms ls_sin_ne_of_sep
#print axioms ls_char_sum
#print axioms ls_parseval
#print axioms ls_floor_prime
#print axioms ls_exp_mod
#print axioms ls_coprime_mod
#print axioms ls_crt
#print axioms ls_floor_gen
#print axioms large_sieve_inequality
#print axioms large_sieve_set_bound
#print axioms large_sieve_energy_floor
