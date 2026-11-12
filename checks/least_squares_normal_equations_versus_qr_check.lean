-- Least squares two ways: multiplying a matrix by its transpose squares its condition number, a QR factor with orthonormal columns keeps it, and in exact arithmetic the normal equations and QR pick the same fit.
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.LinearAlgebra.Matrix.NonsingularInverse
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Analysis.InnerProductSpace.Rayleigh
import Mathlib.Analysis.Matrix.Hermitian

open Matrix

variable {m n : ℕ}

/-- The largest stretch of `A`: the largest length `‖A v‖` over unit vectors `v`, with the
ordinary (Euclidean) length on both sides. -/
noncomputable def maxStretch (A : Matrix (Fin m) (Fin n) ℝ) : ℝ :=
  ⨆ v : Metric.sphere (0 : EuclideanSpace ℝ (Fin n)) 1, ‖toEuclideanLin A v‖

/-- The smallest stretch of `A`: the smallest length `‖A v‖` over unit vectors `v`. -/
noncomputable def minStretch (A : Matrix (Fin m) (Fin n) ℝ) : ℝ :=
  ⨅ v : Metric.sphere (0 : EuclideanSpace ℝ (Fin n)) 1, ‖toEuclideanLin A v‖

/-- The condition number κ(A): the largest stretch of `A` divided by the smallest. -/
noncomputable def condNum (A : Matrix (Fin m) (Fin n) ℝ) : ℝ :=
  maxStretch A / minStretch A

/-- Helper: `⟪AᵀA x, y⟫ = ⟪A x, A y⟫`. -/
lemma inner_transpose_mul_self_apply (A : Matrix (Fin m) (Fin n) ℝ)
    (x y : EuclideanSpace ℝ (Fin n)) :
    inner ℝ (toEuclideanLin (Aᵀ * A) x) y = inner ℝ (toEuclideanLin A x) (toEuclideanLin A y) := by
  simp only [EuclideanSpace.inner_eq_star_dotProduct, toLpLin_apply, star_trivial, ← mulVec_mulVec, dotProduct_mulVec, vecMul_transpose]

/-- Helper: `‖A v‖² = ⟪AᵀA v, v⟫`. -/
lemma norm_sq_eq_inner_transpose_mul_self (A : Matrix (Fin m) (Fin n) ℝ)
    (v : EuclideanSpace ℝ (Fin n)) :
    ‖toEuclideanLin A v‖ ^ 2 = inner ℝ (toEuclideanLin (Aᵀ * A) v) v := by
  rw [inner_transpose_mul_self_apply, real_inner_self_eq_norm_sq]

/-- Helper: the stretches of `A` over the unit sphere are bounded above. -/
lemma bddAbove_stretch (A : Matrix (Fin m) (Fin n) ℝ) :
    BddAbove (Set.range fun v : Metric.sphere (0 : EuclideanSpace ℝ (Fin n)) 1 =>
      ‖toEuclideanLin A v‖) := by
  refine ⟨‖LinearMap.toContinuousLinearMap (toEuclideanLin A)‖, ?_⟩
  rintro _ ⟨v, rfl⟩
  have hv : ‖(v : EuclideanSpace ℝ (Fin n))‖ = 1 := by simp
  have := (LinearMap.toContinuousLinearMap (toEuclideanLin A)).le_opNorm v
  simpa [hv] using this

/-- Helper: the stretches of `A` over the unit sphere are bounded below. -/
lemma bddBelow_stretch (A : Matrix (Fin m) (Fin n) ℝ) :
    BddBelow (Set.range fun v : Metric.sphere (0 : EuclideanSpace ℝ (Fin n)) 1 =>
      ‖toEuclideanLin A v‖) :=
  ⟨0, by rintro _ ⟨v, rfl⟩; exact norm_nonneg _⟩

lemma maxStretch_nonneg (A : Matrix (Fin m) (Fin n) ℝ) : 0 ≤ maxStretch A :=
  Real.iSup_nonneg fun _ => norm_nonneg _

lemma minStretch_nonneg (A : Matrix (Fin m) (Fin n) ℝ) : 0 ≤ minStretch A :=
  Real.iInf_nonneg fun _ => norm_nonneg _

/-- Helper: `‖A w‖ ≤ maxStretch A * ‖w‖`. -/
lemma norm_le_maxStretch_mul (A : Matrix (Fin m) (Fin n) ℝ) (w : EuclideanSpace ℝ (Fin n)) :
    ‖toEuclideanLin A w‖ ≤ maxStretch A * ‖w‖ := by
  by_cases hw : w = 0
  · simp [hw]
  have hpos : 0 < ‖w‖ := norm_pos_iff.mpr hw
  set u : EuclideanSpace ℝ (Fin n) := ‖w‖⁻¹ • w with hu
  have hu1 : u ∈ Metric.sphere (0 : EuclideanSpace ℝ (Fin n)) 1 := by
    simp [hu, norm_smul, hpos.ne']
  have h1 : ‖toEuclideanLin A u‖ ≤ maxStretch A :=
    le_ciSup (bddAbove_stretch A) ⟨u, hu1⟩
  have h2 : ‖toEuclideanLin A u‖ = ‖w‖⁻¹ * ‖toEuclideanLin A w‖ := by
    rw [hu, map_smul, norm_smul, norm_inv, norm_norm]
  rw [h2] at h1
  have := mul_le_mul_of_nonneg_left h1 hpos.le
  rwa [← mul_assoc, mul_inv_cancel₀ hpos.ne', one_mul, mul_comm] at this

/-- Helper: forming `AᵀA` squares the largest stretch. -/
lemma maxStretch_transpose_mul_self (A : Matrix (Fin m) (Fin n) ℝ) :
    maxStretch (Aᵀ * A) = maxStretch A ^ 2 := by
  rcases isEmpty_or_nonempty (Metric.sphere (0 : EuclideanSpace ℝ (Fin n)) 1) with h | h
  · simp [maxStretch]
  apply le_antisymm
  · refine ciSup_le fun v => ?_
    have hv : ‖(v : EuclideanSpace ℝ (Fin n))‖ = 1 := by simp
    set T := toEuclideanLin (Aᵀ * A)
    set t := ‖T v‖ with ht
    have ht0 : 0 ≤ t := norm_nonneg _
    have hM := maxStretch_nonneg A
    have key : t ^ 2 ≤ maxStretch A ^ 2 * t := by
      calc t ^ 2 = inner ℝ (T v) (T v) := (real_inner_self_eq_norm_sq _).symm
        _ = inner ℝ (toEuclideanLin A v) (toEuclideanLin A (T v)) :=
          inner_transpose_mul_self_apply A _ _
        _ ≤ ‖toEuclideanLin A v‖ * ‖toEuclideanLin A (T v)‖ := real_inner_le_norm _ _
        _ ≤ (maxStretch A * 1) * (maxStretch A * t) := by
          have h1 := norm_le_maxStretch_mul A v
          have h2 := norm_le_maxStretch_mul A (T v)
          rw [hv] at h1
          exact mul_le_mul h1 h2 (norm_nonneg _) (by positivity)
        _ = maxStretch A ^ 2 * t := by ring
    rcases ht0.lt_or_eq with htp | hte
    · nlinarith
    · rw [← hte]; positivity
  · have hS := maxStretch_nonneg (Aᵀ * A)
    have hle : maxStretch A ≤ √(maxStretch (Aᵀ * A)) := by
      refine ciSup_le fun v => ?_
      have hv : ‖(v : EuclideanSpace ℝ (Fin n))‖ = 1 := by simp
      rw [Real.le_sqrt (norm_nonneg _) hS, norm_sq_eq_inner_transpose_mul_self]
      calc inner ℝ (toEuclideanLin (Aᵀ * A) v) v
          ≤ ‖toEuclideanLin (Aᵀ * A) v‖ * ‖(v : EuclideanSpace ℝ (Fin n))‖ :=
            real_inner_le_norm _ _
        _ = ‖toEuclideanLin (Aᵀ * A) v‖ := by rw [hv, mul_one]
        _ ≤ maxStretch (Aᵀ * A) := le_ciSup (bddAbove_stretch _) v
    exact (Real.le_sqrt (maxStretch_nonneg A) hS).mp hle

/-- Helper: forming `AᵀA` squares the smallest stretch. -/
lemma minStretch_transpose_mul_self (A : Matrix (Fin m) (Fin n) ℝ) :
    minStretch (Aᵀ * A) = minStretch A ^ 2 := by
  rcases isEmpty_or_nonempty (Metric.sphere (0 : EuclideanSpace ℝ (Fin n)) 1) with h | h
  · simp [minStretch]
  obtain ⟨v₀⟩ := id h
  have hv₀ : ‖(v₀ : EuclideanSpace ℝ (Fin n))‖ = 1 := by simp
  set T := toEuclideanLin (Aᵀ * A) with hTdef
  have hm := minStretch_nonneg A
  apply le_antisymm
  · -- an eigenvector for the bottom of the Rayleigh quotient
    have : Nontrivial (EuclideanSpace ℝ (Fin n)) :=
      nontrivial_of_ne (v₀ : EuclideanSpace ℝ (Fin n)) 0 (by
        intro h0; rw [h0, norm_zero] at hv₀; exact zero_ne_one hv₀)
    have hT : T.IsSymmetric := by
      intro x y
      calc inner ℝ (T x) y = inner ℝ (toEuclideanLin A x) (toEuclideanLin A y) :=
            inner_transpose_mul_self_apply A x y
        _ = inner ℝ (toEuclideanLin A y) (toEuclideanLin A x) := real_inner_comm _ _
        _ = inner ℝ (T y) x := (inner_transpose_mul_self_apply A y x).symm
        _ = inner ℝ x (T y) := real_inner_comm _ _
    have hev := hT.hasEigenvalue_iInf_of_finiteDimensional
    set μ := (⨅ x : { x : EuclideanSpace ℝ (Fin n) // x ≠ 0 },
      RCLike.re (inner ℝ (T x) x) / ‖(x : EuclideanSpace ℝ (Fin n))‖ ^ 2 : ℝ) with hμ
    have hbdd : BddBelow (Set.range fun x : { x : EuclideanSpace ℝ (Fin n) // x ≠ 0 } =>
        RCLike.re (inner ℝ (T x) x) / ‖(x : EuclideanSpace ℝ (Fin n))‖ ^ 2) := by
      refine ⟨0, ?_⟩
      rintro _ ⟨x, rfl⟩
      simp only [RCLike.re_to_real]
      rw [hTdef, ← norm_sq_eq_inner_transpose_mul_self]
      positivity
    obtain ⟨w, hw⟩ := hev.exists_hasEigenvector
    have hTw := hw.apply_eq_smul
    have hw0 : w ≠ 0 := hw.2
    have hwpos : 0 < ‖w‖ := norm_pos_iff.mpr hw0
    set u : EuclideanSpace ℝ (Fin n) := ‖w‖⁻¹ • w with hu
    have hu1 : ‖u‖ = 1 := by simp [hu, norm_smul, hwpos.ne']
    have hTu : T u = μ • u := by
      rw [hu, map_smul, hTw, smul_comm]
      rfl
    have hμu : μ = ‖toEuclideanLin A u‖ ^ 2 := by
      rw [norm_sq_eq_inner_transpose_mul_self, ← hTdef, hTu, real_inner_smul_left,
        real_inner_self_eq_norm_sq, hu1]
      ring
    -- `‖A u‖` is at most every stretch of `A`
    have hAu : ‖toEuclideanLin A u‖ ≤ minStretch A := by
      refine le_ciInf fun v => ?_
      have hv : ‖(v : EuclideanSpace ℝ (Fin n))‖ = 1 := by simp
      have hv0 : (v : EuclideanSpace ℝ (Fin n)) ≠ 0 := by
        intro h0; rw [h0, norm_zero] at hv; exact zero_ne_one hv
      have h1 : μ ≤ _ := ciInf_le hbdd ⟨v, hv0⟩
      simp only [RCLike.re_to_real, hv, one_pow, div_one] at h1
      rw [hTdef, ← norm_sq_eq_inner_transpose_mul_self, hμu] at h1
      exact (pow_le_pow_iff_left₀ (norm_nonneg _) (norm_nonneg _) two_ne_zero).mp h1
    calc minStretch (Aᵀ * A) ≤ ‖T u‖ :=
          ciInf_le (bddBelow_stretch _) ⟨u, by simpa using hu1⟩
      _ = ‖toEuclideanLin A u‖ ^ 2 := by
          rw [hTu, norm_smul, hu1, mul_one, Real.norm_eq_abs, abs_of_nonneg (by rw [hμu]; positivity),
            hμu]
      _ ≤ minStretch A ^ 2 := pow_le_pow_left₀ (norm_nonneg _) hAu 2
  · refine le_ciInf fun v => ?_
    have hv : ‖(v : EuclideanSpace ℝ (Fin n))‖ = 1 := by simp
    have h1 : minStretch A ≤ ‖toEuclideanLin A v‖ := ciInf_le (bddBelow_stretch A) v
    calc minStretch A ^ 2 ≤ ‖toEuclideanLin A v‖ ^ 2 := pow_le_pow_left₀ hm h1 2
      _ = inner ℝ (T v) v := norm_sq_eq_inner_transpose_mul_self A v
      _ ≤ ‖T v‖ * ‖(v : EuclideanSpace ℝ (Fin n))‖ := real_inner_le_norm _ _
      _ = ‖T v‖ := by rw [hv, mul_one]

/-- Helper: a matrix with `Qᵀ Q = 1` keeps lengths. -/
lemma norm_toEuclideanLin_of_transpose_mul_self_eq_one (Q : Matrix (Fin m) (Fin n) ℝ)
    (hQ : Qᵀ * Q = 1) (w : EuclideanSpace ℝ (Fin n)) :
    ‖toEuclideanLin Q w‖ = ‖w‖ := by
  have h : ‖toEuclideanLin Q w‖ ^ 2 = ‖w‖ ^ 2 := by
    rw [norm_sq_eq_inner_transpose_mul_self, hQ, toLpLin_one, LinearMap.id_apply,
      real_inner_self_eq_norm_sq]
  exact (sq_eq_sq₀ (norm_nonneg _) (norm_nonneg _)).mp h

#print axioms inner_transpose_mul_self_apply
#print axioms norm_sq_eq_inner_transpose_mul_self
#print axioms bddAbove_stretch
#print axioms bddBelow_stretch
#print axioms maxStretch_nonneg
#print axioms minStretch_nonneg
#print axioms norm_le_maxStretch_mul
#print axioms maxStretch_transpose_mul_self
#print axioms minStretch_transpose_mul_self
#print axioms norm_toEuclideanLin_of_transpose_mul_self_eq_one

/-- Forming AᵀA squares the condition number: when the columns of `A` are independent,
κ(AᵀA) = κ(A)². -/
theorem condNum_transpose_mul_self_eq_sq (A : Matrix (Fin m) (Fin n) ℝ)
    (hA : LinearIndependent ℝ Aᵀ) :
    condNum (Aᵀ * A) = condNum A ^ 2 := by
  rw [condNum, condNum, maxStretch_transpose_mul_self, minStretch_transpose_mul_self, div_pow]

/-- QR keeps the condition number: if `A = Q R` and the columns of `Q` are at right angles,
each of length 1 (`Qᵀ Q = 1`), then `R` has the same condition number as `A`. -/
theorem condNum_R_eq_of_qr (A Q : Matrix (Fin m) (Fin n) ℝ) (R : Matrix (Fin n) (Fin n) ℝ)
    (hQ : Qᵀ * Q = 1) (hQR : A = Q * R) :
    condNum R = condNum A := by
  have h : ∀ v : EuclideanSpace ℝ (Fin n),
      ‖toEuclideanLin A v‖ = ‖toEuclideanLin R v‖ := by
    intro v
    rw [hQR, toLpLin_mul_same, LinearMap.comp_apply,
      norm_toEuclideanLin_of_transpose_mul_self_eq_one Q hQ]
  simp only [condNum, maxStretch, minStretch, h]

/-- In exact arithmetic the two routes give the same fit: if the columns of `A` are
independent and `A = Q R` with `Qᵀ Q = 1`, then `x` solves the normal equations
AᵀA x = Aᵀb exactly when it solves the triangle R x = Qᵀb. -/
theorem normal_equations_iff_qr (A Q : Matrix (Fin m) (Fin n) ℝ) (R : Matrix (Fin n) (Fin n) ℝ)
    (hA : LinearIndependent ℝ Aᵀ) (hQ : Qᵀ * Q = 1) (hQR : A = Q * R)
    (x : Fin n → ℝ) (b : Fin m → ℝ) :
    (Aᵀ * A) *ᵥ x = Aᵀ *ᵥ b ↔ R *ᵥ x = Qᵀ *ᵥ b := by
  have hAinj : Function.Injective A.mulVec := Matrix.mulVec_injective_iff.mpr hA
  have hRinj : Function.Injective R.mulVec := by
    intro x y hxy
    apply hAinj
    simp only [hQR, ← mulVec_mulVec, hxy]
  have hRt : Function.Injective Rᵀ.mulVec :=
    mulVec_injective_iff_isUnit.mpr ((isUnit_transpose R).mpr (mulVec_injective_iff_isUnit.mp hRinj))
  have h1 : Aᵀ * A = Rᵀ * R := by
    rw [hQR, transpose_mul, Matrix.mul_assoc, ← Matrix.mul_assoc Qᵀ, hQ, Matrix.one_mul]
  have h2 : Aᵀ = Rᵀ * Qᵀ := by rw [hQR, transpose_mul]
  rw [h1, h2, ← mulVec_mulVec, ← mulVec_mulVec]
  exact hRt.eq_iff

/-! The card's whole-number facts. -/

-- Every entry of AᵀA for laps 301 to 320 is a whole number below 2^53, so it is stored
-- exactly; the largest entry is the sum of lap⁴.
example : (∑ i ∈ Finset.range 20, (301 + i) ^ 4) < 2 ^ 53 := by
  decide

-- Flops for m = 20 rows, n = 3 unknowns: normal equations m n² + n³/3 = 189,
-- Householder QR 2 m n² − 2 n³/3 = 342.
example : 20 * 3 ^ 2 + 3 ^ 3 / 3 = 189 := by norm_num
example : 2 * 20 * 3 ^ 2 - 2 * 3 ^ 3 / 3 = 342 := by norm_num

-- Flops for a million rows and 3 unknowns: 9,000,009 against 17,999,982.
example : 1000000 * 3 ^ 2 + 3 ^ 3 / 3 = 9000009 := by norm_num
example : 2 * 1000000 * 3 ^ 2 - 2 * 3 ^ 3 / 3 = 17999982 := by norm_num

#print axioms condNum_transpose_mul_self_eq_sq
#print axioms condNum_R_eq_of_qr
#print axioms normal_equations_iff_qr
