-- Level, slope and curvature: for any record of daily curve changes, no three perpendicular unit shapes capture more of the average squared movement than the top three eigenvectors of the covariance matrix, the eigenvalues add up to the total variance, and the leftover after the top three is the sum of the remaining eigenvalues.
import Mathlib.Data.Matrix.Mul
import Mathlib.LinearAlgebra.Matrix.Trace
import Mathlib.Algebra.Order.BigOperators.Group.Finset
import Mathlib.Data.Real.Basic
import Mathlib.LinearAlgebra.Matrix.NonsingularInverse
import Mathlib.Algebra.BigOperators.Field

open Matrix

namespace CurvePCA

variable {n m : ℕ}

/-- The average daily change, tenor by tenor, over a record of `n` days and `m` tenors. -/
noncomputable def meanChange (x : Fin n → Fin m → ℝ) : Fin m → ℝ :=
  fun i => (∑ t, x t i) / n

/-- Day `t`'s centred change: its change minus the average change. -/
noncomputable def centred (x : Fin n → Fin m → ℝ) (t : Fin n) : Fin m → ℝ :=
  x t - meanChange x

/-- The covariance matrix, equally weighted (divide by `n`): entry `(i, j)` averages the
product of tenor `i`'s and tenor `j`'s centred changes. -/
noncomputable def covMat (x : Fin n → Fin m → ℝ) : Matrix (Fin m) (Fin m) ℝ :=
  fun i j => (∑ t, centred x t i * centred x t j) / n

/-- The movement carried by a shape `w`: the average over the days of the squared score
`w ⬝ (x_t - x̄)`. -/
noncomputable def captured (x : Fin n → Fin m → ℝ) (w : Fin m → ℝ) : ℝ :=
  (∑ t, (w ⬝ᵥ centred x t) ^ 2) / n

/-- The average squared leftover when each day's centred change is replaced by its part along
the shapes `v 0, …, v (k-1)`: the squared distance from the centred change to
`∑ j, (v j ⬝ (x_t - x̄)) • v j`, averaged over the days. -/
noncomputable def leftover {k : ℕ} (x : Fin n → Fin m → ℝ) (v : Fin k → Fin m → ℝ) : ℝ :=
  (∑ t, ∑ i, (centred x t i - ∑ j, (v j ⬝ᵥ centred x t) * v j i) ^ 2) / n

/-- Columns of an orthonormal square family are orthonormal too. -/
theorem cols_orthonormal (u : Fin m → Fin m → ℝ)
    (hu : ∀ i j, u i ⬝ᵥ u j = if i = j then 1 else 0) (i j : Fin m) :
    ∑ k, u k i * u k j = if i = j then 1 else 0 := by
  have h1 : (Matrix.of u) * (Matrix.of u)ᵀ = 1 := by
    ext i j
    simp [Matrix.mul_apply, Matrix.one_apply, ← hu i j, dotProduct]
  have h2 : (Matrix.of u)ᵀ * (Matrix.of u) = 1 := mul_eq_one_comm.mp h1
  have := congrFun (congrFun h2 i) j
  simpa [Matrix.mul_apply, Matrix.one_apply] using this

/-- Every vector is the sum of its parts along a full orthonormal family. -/
theorem expand (u : Fin m → Fin m → ℝ)
    (hu : ∀ i j, u i ⬝ᵥ u j = if i = j then 1 else 0) (w : Fin m → ℝ) :
    w = ∑ k, (u k ⬝ᵥ w) • u k := by
  funext i
  simp only [Finset.sum_apply, Pi.smul_apply, smul_eq_mul, dotProduct]
  calc w i = ∑ j, w j * (if j = i then 1 else 0) := by simp
    _ = ∑ j, w j * ∑ k, u k j * u k i := by simp_rw [cols_orthonormal u hu]
    _ = ∑ j, ∑ k, u k j * w j * u k i := by
        refine Finset.sum_congr rfl fun j _ => ?_
        rw [Finset.mul_sum]
        refine Finset.sum_congr rfl fun k _ => ?_
        ring
    _ = ∑ k, (∑ j, u k j * w j) * u k i := by
        rw [Finset.sum_comm]
        refine Finset.sum_congr rfl fun k _ => ?_
        rw [Finset.sum_mul]

/-- Parseval for a full orthonormal family. -/
theorem parseval (u : Fin m → Fin m → ℝ)
    (hu : ∀ i j, u i ⬝ᵥ u j = if i = j then 1 else 0) (w : Fin m → ℝ) :
    ∑ k, (u k ⬝ᵥ w) ^ 2 = w ⬝ᵥ w := by
  nth_rw 2 [expand u hu w]
  rw [sum_dotProduct]
  refine Finset.sum_congr rfl fun k _ => ?_
  rw [smul_dotProduct, smul_eq_mul, sq]

/-- The quadratic form of `Σ` in eigen-coordinates. -/
theorem quad_form (x : Fin n → Fin m → ℝ) (u : Fin m → Fin m → ℝ) (lam : Fin m → ℝ)
    (hu : ∀ i j, u i ⬝ᵥ u j = if i = j then 1 else 0)
    (heig : ∀ k, covMat x *ᵥ u k = lam k • u k) (w : Fin m → ℝ) :
    w ⬝ᵥ (covMat x *ᵥ w) = ∑ k, lam k * (u k ⬝ᵥ w) ^ 2 := by
  nth_rw 2 [expand u hu w]
  rw [mulVec_sum, dotProduct_sum]
  refine Finset.sum_congr rfl fun k _ => ?_
  rw [mulVec_smul, heig, dotProduct_smul, dotProduct_smul, smul_eq_mul, smul_eq_mul,
    dotProduct_comm w (u k)]
  ring

/-- The captured movement is the quadratic form of the covariance matrix. -/
theorem captured_eq (x : Fin n → Fin m → ℝ) (w : Fin m → ℝ) :
    captured x w = w ⬝ᵥ (covMat x *ᵥ w) := by
  unfold captured covMat
  simp only [dotProduct, mulVec, sq, Finset.mul_sum, Finset.sum_div, Finset.sum_mul]
  rw [Finset.sum_comm]
  refine Finset.sum_congr rfl fun i _ => ?_
  rw [Finset.sum_comm]
  refine Finset.sum_congr rfl fun j _ => ?_
  refine Finset.sum_congr rfl fun t _ => ?_
  ring

/-- Projection identity (Pythagoras) for an orthonormal family. -/
theorem proj_sq {k : ℕ} (v : Fin k → Fin m → ℝ)
    (hv : ∀ i j, v i ⬝ᵥ v j = if i = j then 1 else 0) (w : Fin m → ℝ) :
    ∑ i, (w i - ∑ j, (v j ⬝ᵥ w) * v j i) ^ 2 = w ⬝ᵥ w - ∑ j, (v j ⬝ᵥ w) ^ 2 := by
  set p : Fin m → ℝ := ∑ j, (v j ⬝ᵥ w) • v j with hp
  have hpi : ∀ i, p i = ∑ j, (v j ⬝ᵥ w) * v j i := by
    intro i; simp [hp, Finset.sum_apply]
  have hwp : w ⬝ᵥ p = ∑ j, (v j ⬝ᵥ w) ^ 2 := by
    rw [hp, dotProduct_sum]
    simp [dotProduct_comm w, sq]
  have hpp : p ⬝ᵥ p = ∑ j, (v j ⬝ᵥ w) ^ 2 := by
    rw [hp, dotProduct_sum]
    refine Finset.sum_congr rfl fun j _ => ?_
    rw [dotProduct_smul, sum_dotProduct]
    simp [smul_dotProduct, hv, sq]
  have : ∑ i, (w i - ∑ j, (v j ⬝ᵥ w) * v j i) ^ 2 = w ⬝ᵥ w - 2 * (w ⬝ᵥ p) + p ⬝ᵥ p := by
    simp only [dotProduct, Finset.mul_sum, ← Finset.sum_sub_distrib, ← Finset.sum_add_distrib]
    refine Finset.sum_congr rfl fun i _ => ?_
    have h := hpi i
    simp only [dotProduct] at h
    rw [← h]
    ring
  rw [this, hwp, hpp]; ring

theorem trace_eq (x : Fin n → Fin m → ℝ) (u : Fin m → Fin m → ℝ) (lam : Fin m → ℝ)
    (hu : ∀ i j, u i ⬝ᵥ u j = if i = j then 1 else 0)
    (heig : ∀ k, covMat x *ᵥ u k = lam k • u k) :
    trace (covMat x) = ∑ k, lam k := by
  have h : ∀ i, covMat x i i = ∑ k, lam k * (u k i) ^ 2 := by
    intro i
    have := quad_form x u lam hu heig (Pi.single i 1)
    simpa [mulVec_single_one, single_one_dotProduct, dotProduct_comm _ (Pi.single i 1)] using this
  rw [trace]
  simp only [diag, h]
  rw [Finset.sum_comm]
  refine Finset.sum_congr rfl fun k _ => ?_
  rw [← Finset.mul_sum]
  have := hu k k
  simp [dotProduct, ← sq] at this
  rw [this, mul_one]

theorem sum_filter_lt_three (h3 : 3 ≤ m) (f : Fin m → ℝ) :
    ∑ i ∈ Finset.univ.filter (fun i : Fin m => (i : ℕ) < 3), f i
      = ∑ j : Fin 3, f (Fin.castLE h3 j) := by
  have : Finset.univ.filter (fun i : Fin m => (i : ℕ) < 3)
      = Finset.univ.map (Fin.castLEEmb h3) := by
    ext i
    simp only [Finset.mem_filter, Finset.mem_univ, true_and, Finset.mem_map, Fin.castLEEmb_apply]
    constructor
    · intro hi; exact ⟨⟨i, hi⟩, rfl⟩
    · rintro ⟨j, rfl⟩; simp
  rw [this, Finset.sum_map]
  rfl

#print axioms cols_orthonormal
#print axioms expand
#print axioms parseval
#print axioms quad_form
#print axioms captured_eq
#print axioms proj_sq
#print axioms trace_eq
#print axioms sum_filter_lt_three

/-- **No three shapes beat the top three eigenvectors.** Take any record of `n` days of curve
changes at `m` tenors, with covariance matrix `Σ`. Let `u 0, …, u (m-1)` be perpendicular unit
eigenvectors of `Σ` with eigenvalues `λ 0 ≥ λ 1 ≥ … ≥ λ (m-1)`. Then any three perpendicular unit
shapes `v 0, v 1, v 2` together carry at most `λ 0 + λ 1 + λ 2` of the movement. -/
theorem no_three_shapes_beat_top_three_eigenvectors
    (x : Fin n → Fin m → ℝ) (u : Fin m → Fin m → ℝ) (lam : Fin m → ℝ)
    (hu : ∀ i j, u i ⬝ᵥ u j = if i = j then 1 else 0)
    (heig : ∀ k, covMat x *ᵥ u k = lam k • u k)
    (hanti : Antitone lam)
    (v : Fin 3 → Fin m → ℝ)
    (hv : ∀ i j, v i ⬝ᵥ v j = if i = j then 1 else 0) :
    ∑ j, captured x (v j) ≤ ∑ i ∈ Finset.univ.filter (fun i : Fin m => (i : ℕ) < 3), lam i := by
  set p : Fin m → ℝ := fun k => ∑ j, (v j ⬝ᵥ u k) ^ 2 with hp
  have hp0 : ∀ k, 0 ≤ p k := fun k => Finset.sum_nonneg fun j _ => sq_nonneg _
  have hp1 : ∀ k, p k ≤ 1 := by
    intro k
    have h := proj_sq v hv (u k)
    have h0 : 0 ≤ ∑ i, (u k i - ∑ j, (v j ⬝ᵥ u k) * v j i) ^ 2 :=
      Finset.sum_nonneg fun i _ => sq_nonneg _
    have huk := hu k k
    simp only [↓reduceIte] at huk
    simp only [hp]
    linarith
  have hsum : ∑ k, p k = 3 := by
    simp only [hp]
    rw [Finset.sum_comm]
    simp_rw [dotProduct_comm (v _) (u _), parseval u hu, hv]
    simp
  have hcap : ∑ j, captured x (v j) = ∑ k, lam k * p k := by
    simp_rw [captured_eq, quad_form x u lam hu heig, hp, Finset.mul_sum]
    rw [Finset.sum_comm]
    simp_rw [dotProduct_comm (u _) (v _)]
  rw [hcap]
  by_cases h3 : 3 ≤ m
  · have hind : ∑ k : Fin m, (if (k : ℕ) < 3 then (1 : ℝ) else 0) = 3 := by
      rw [← Finset.sum_filter, sum_filter_lt_three h3]
      simp
    rw [Finset.sum_filter]
    set c := lam ⟨2, by omega⟩
    have key : ∀ k : Fin m, lam k * p k ≤
        (if (k : ℕ) < 3 then lam k else 0) + c * (p k - if (k : ℕ) < 3 then 1 else 0) := by
      intro k
      have h1 := hp0 k
      have h2 := hp1 k
      split_ifs with hk
      · have : c ≤ lam k := hanti (show k ≤ ⟨2, by omega⟩ from Fin.mk_le_mk.mpr (by omega))
        nlinarith
      · have : lam k ≤ c := hanti (show (⟨2, by omega⟩ : Fin m) ≤ k from
          Fin.mk_le_mk.mpr (by omega))
        nlinarith
    calc ∑ k, lam k * p k
        ≤ ∑ k : Fin m, ((if (k : ℕ) < 3 then lam k else 0)
            + c * (p k - if (k : ℕ) < 3 then 1 else 0)) := Finset.sum_le_sum fun k _ => key k
      _ = ∑ k : Fin m, (if (k : ℕ) < 3 then lam k else 0) := by
          rw [Finset.sum_add_distrib, ← Finset.mul_sum, Finset.sum_sub_distrib, hsum, hind]
          ring
  · exfalso
    have : ∑ k, p k ≤ ∑ _k : Fin m, (1 : ℝ) := Finset.sum_le_sum fun k _ => hp1 k
    simp only [Finset.sum_const, Finset.card_univ, Fintype.card_fin, nsmul_eq_mul, mul_one] at this
    have hm : (m : ℝ) < 3 := by exact_mod_cast (show m < 3 by omega)
    linarith

/-- **The eigenvalues add up to the total.** The total variance, the trace of `Σ` (the sum of
the variances on its diagonal), equals the sum of the eigenvalues of any full set of
perpendicular unit eigenvectors. So the shares `λ k / tr Σ` add up to one. -/
theorem eigenvalues_sum_to_total_variance
    (x : Fin n → Fin m → ℝ) (u : Fin m → Fin m → ℝ) (lam : Fin m → ℝ)
    (hu : ∀ i j, u i ⬝ᵥ u j = if i = j then 1 else 0)
    (heig : ∀ k, covMat x *ᵥ u k = lam k • u k) :
    trace (covMat x) = ∑ k, lam k := by
  exact trace_eq x u lam hu heig

/-- **The leftover is the tail.** Keep the top three eigenvectors `u 0, u 1, u 2` as the
shapes. Then the average squared leftover over the days is exactly the sum of the other
eigenvalues, `λ 3 + … + λ (m-1)`. -/
theorem leftover_of_top_three_eq_tail
    (x : Fin n → Fin m → ℝ) (u : Fin m → Fin m → ℝ) (lam : Fin m → ℝ)
    (hu : ∀ i j, u i ⬝ᵥ u j = if i = j then 1 else 0)
    (heig : ∀ k, covMat x *ᵥ u k = lam k • u k)
    (h3 : 3 ≤ m) :
    leftover x (fun j : Fin 3 => u (Fin.castLE h3 j))
      = ∑ i ∈ Finset.univ.filter (fun i : Fin m => 3 ≤ (i : ℕ)), lam i := by
  set v : Fin 3 → Fin m → ℝ := fun j => u (Fin.castLE h3 j) with hvdef
  have hv : ∀ i j, v i ⬝ᵥ v j = if i = j then 1 else 0 := by
    intro i j
    simp only [hvdef, hu, Fin.castLE_inj]
  have hcap : ∀ j, captured x (v j) = lam (Fin.castLE h3 j) := by
    intro j
    rw [captured_eq, hvdef]
    simp only
    rw [heig, dotProduct_smul, hu]
    simp only [↓reduceIte, smul_eq_mul, mul_one]
  have htr : (∑ t, centred x t ⬝ᵥ centred x t) / n = trace (covMat x) := by
    simp only [trace, diag, covMat, dotProduct]
    rw [← Finset.sum_div, Finset.sum_comm]
  have hleft : leftover x v
      = (∑ t, centred x t ⬝ᵥ centred x t) / n - ∑ j, captured x (v j) := by
    unfold leftover captured
    rw [Finset.sum_congr rfl fun t _ => proj_sq v hv (centred x t), Finset.sum_sub_distrib,
      sub_div, ← Finset.sum_div, Finset.sum_comm (f := fun t j => (v j ⬝ᵥ centred x t) ^ 2)]
  rw [hleft, htr, trace_eq x u lam hu heig]
  simp_rw [hcap]
  have hsplit := Finset.sum_filter_add_sum_filter_not Finset.univ
    (fun i : Fin m => (i : ℕ) < 3) lam
  simp only [not_lt] at hsplit
  rw [← hsplit, sum_filter_lt_three h3]
  ring

#print axioms no_three_shapes_beat_top_three_eigenvectors
#print axioms eigenvalues_sum_to_total_variance
#print axioms leftover_of_top_three_eq_tail

end CurvePCA
