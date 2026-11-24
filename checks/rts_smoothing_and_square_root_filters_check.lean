-- Smoothing and square roots: the RTS backward pass never makes a covariance larger than the filter's, and a covariance carried as a factor times its own transpose, updated by rotations, is never negative and gives the Kalman gain and corrected covariance.
import Mathlib.LinearAlgebra.Matrix.PosDef
import Mathlib.LinearAlgebra.Matrix.NonsingularInverse
import Mathlib.Data.Matrix.Block
import Mathlib.Algebra.Order.Star.Real

open Matrix

namespace RTSSmoothing

variable {n m : Type*} [Fintype n] [DecidableEq n] [Fintype m] [DecidableEq m]

/-- The predicted covariance `P⁻ = F P Fᵀ + Q`. -/
noncomputable def predCov (F Q P : Matrix n n ℝ) : Matrix n n ℝ := F * P * Fᵀ + Q

/-- The plain Kalman correction `P = P⁻ - K H P⁻`, with `S = H P⁻ Hᵀ + R` and `K = P⁻ Hᵀ S⁻¹`. -/
noncomputable def corrCov (H : Matrix m n ℝ) (R : Matrix m m ℝ) (Pm : Matrix n n ℝ) : Matrix n n ℝ :=
  Pm - (Pm * Hᵀ * (H * Pm * Hᵀ + R)⁻¹) * H * Pm

/-- The forward filter's covariance after reading `k`; step 0 is the start `P₀`. -/
noncomputable def filtCov (F Q : Matrix n n ℝ) (H : Matrix m n ℝ) (R : Matrix m m ℝ)
    (P₀ : Matrix n n ℝ) : ℕ → Matrix n n ℝ
  | 0 => P₀
  | k + 1 => corrCov H R (predCov F Q (filtCov F Q H R P₀ k))

/-- The smoother gain `C_k = P_k Fᵀ (P⁻_{k+1})⁻¹`. -/
noncomputable def gain (F Q : Matrix n n ℝ) (H : Matrix m n ℝ) (R : Matrix m m ℝ)
    (P₀ : Matrix n n ℝ) (k : ℕ) : Matrix n n ℝ :=
  filtCov F Q H R P₀ k * Fᵀ * (predCov F Q (filtCov F Q H R P₀ k))⁻¹

/-- The RTS backward pass, `j` steps back from the last step `N`:
`P^s_N = P_N` and `P^s_k = P_k + C_k (P^s_{k+1} - P⁻_{k+1}) C_kᵀ`. -/
noncomputable def smoothBack (F Q : Matrix n n ℝ) (H : Matrix m n ℝ) (R : Matrix m m ℝ)
    (P₀ : Matrix n n ℝ) (N : ℕ) : ℕ → Matrix n n ℝ
  | 0 => filtCov F Q H R P₀ N
  | j + 1 =>
    filtCov F Q H R P₀ (N - (j + 1)) +
      gain F Q H R P₀ (N - (j + 1)) *
        (smoothBack F Q H R P₀ N j - predCov F Q (filtCov F Q H R P₀ (N - (j + 1)))) *
        (gain F Q H R P₀ (N - (j + 1)))ᵀ

/-- The smoothed covariance `P^s_k` at step `k` of a record of `N` readings. -/
noncomputable def smoothCov (F Q : Matrix n n ℝ) (H : Matrix m n ℝ) (R : Matrix m m ℝ)
    (P₀ : Matrix n n ℝ) (N k : ℕ) : Matrix n n ℝ :=
  smoothBack F Q H R P₀ N (N - k)

omit [Fintype n] [DecidableEq n] in
/-- Over the reals, a positive semidefinite matrix equals its transpose. -/
theorem psd_transpose_eq {P : Matrix n n ℝ} (hP : P.PosSemidef) : Pᵀ = P := by
  have h := hP.isHermitian.eq
  rwa [conjTranspose_eq_transpose_of_trivial] at h

/-- The Joseph form of the Kalman correction. -/
theorem corrCov_joseph (H : Matrix m n ℝ) (R : Matrix m m ℝ) (Pm : Matrix n n ℝ)
    (hP : Pmᵀ = Pm) (hS : IsUnit (H * Pm * Hᵀ + R).det)
    (hSt : (H * Pm * Hᵀ + R)ᵀ = H * Pm * Hᵀ + R) :
    corrCov H R Pm =
      (1 - Pm * Hᵀ * (H * Pm * Hᵀ + R)⁻¹ * H) * Pm * (1 - Pm * Hᵀ * (H * Pm * Hᵀ + R)⁻¹ * H)ᵀ +
        (Pm * Hᵀ * (H * Pm * Hᵀ + R)⁻¹) * R * (Pm * Hᵀ * (H * Pm * Hᵀ + R)⁻¹)ᵀ := by
  unfold corrCov
  set S := H * Pm * Hᵀ + R with hSdef
  have hSi : S⁻¹ᵀ = S⁻¹ := by rw [transpose_nonsing_inv, hSt]
  have key : Pm * Hᵀ * S⁻¹ * (H * Pm * Hᵀ) * S⁻¹ * H * Pm + Pm * Hᵀ * S⁻¹ * R * S⁻¹ * H * Pm
      = Pm * Hᵀ * S⁻¹ * H * Pm := by
    have : Pm * Hᵀ * S⁻¹ * S * S⁻¹ * H * Pm = Pm * Hᵀ * S⁻¹ * H * Pm := by
      rw [Matrix.mul_assoc (Pm * Hᵀ * S⁻¹) S S⁻¹, mul_nonsing_inv S hS, Matrix.mul_one]
    rw [← this, hSdef]
    simp only [Matrix.mul_add, Matrix.add_mul]
  simp only [transpose_sub, transpose_one, transpose_mul, transpose_transpose, hSi, hP, sub_mul,
    mul_sub, Matrix.one_mul, Matrix.mul_one] at key ⊢
  simp only [Matrix.mul_assoc] at key ⊢
  generalize Pm * (Hᵀ * (S⁻¹ * (H * (Pm * (Hᵀ * (S⁻¹ * (H * Pm))))))) = B at key ⊢
  generalize Pm * (Hᵀ * (S⁻¹ * (R * (S⁻¹ * (H * Pm))))) = C at key ⊢
  rw [← key]
  abel

#print axioms psd_transpose_eq
#print axioms corrCov_joseph

/-- The correction keeps the covariance positive semidefinite and never makes it larger. -/
theorem corrCov_facts (H : Matrix m n ℝ) (R : Matrix m m ℝ) (Pm : Matrix n n ℝ)
    (hP : Pm.PosSemidef) (hR : R.PosDef) :
    (corrCov H R Pm).PosSemidef ∧ (Pm - corrCov H R Pm).PosSemidef := by
  have hPt := psd_transpose_eq hP
  have hHPH : (H * Pm * Hᵀ).PosSemidef := by
    have := hP.mul_mul_conjTranspose_same H
    rwa [conjTranspose_eq_transpose_of_trivial] at this
  have hSpd : (H * Pm * Hᵀ + R).PosDef := Matrix.PosDef.posSemidef_add hHPH hR
  have hSu : IsUnit (H * Pm * Hᵀ + R).det := (isUnit_iff_isUnit_det _).mp hSpd.isUnit
  have hSt : (H * Pm * Hᵀ + R)ᵀ = H * Pm * Hᵀ + R := psd_transpose_eq hSpd.posSemidef
  constructor
  · rw [corrCov_joseph H R Pm hPt hSu hSt]
    refine PosSemidef.add ?_ ?_
    · have := hP.mul_mul_conjTranspose_same (1 - Pm * Hᵀ * (H * Pm * Hᵀ + R)⁻¹ * H)
      rwa [conjTranspose_eq_transpose_of_trivial] at this
    · have := hR.posSemidef.mul_mul_conjTranspose_same (Pm * Hᵀ * (H * Pm * Hᵀ + R)⁻¹)
      rwa [conjTranspose_eq_transpose_of_trivial] at this
  · have hEq : Pm - corrCov H R Pm = (H * Pm)ᵀ * (H * Pm * Hᵀ + R)⁻¹ * (H * Pm) := by
      unfold corrCov
      rw [sub_sub_cancel, transpose_mul, hPt]
      simp only [Matrix.mul_assoc]
    rw [hEq]
    have := hSpd.inv.posSemidef.conjTranspose_mul_mul_same (H * Pm)
    rwa [conjTranspose_eq_transpose_of_trivial] at this

omit [DecidableEq n] in
/-- The predicted covariance is positive semidefinite. -/
theorem predCov_psd (F Q P : Matrix n n ℝ) (hP : P.PosSemidef) (hQ : Q.PosSemidef) :
    (predCov F Q P).PosSemidef := by
  have := hP.mul_mul_conjTranspose_same F
  rw [conjTranspose_eq_transpose_of_trivial] at this
  exact this.add hQ

/-- Every filtered covariance is positive semidefinite. -/
theorem filtCov_psd (F Q : Matrix n n ℝ) (H : Matrix m n ℝ) (R : Matrix m m ℝ)
    (P₀ : Matrix n n ℝ) (hP₀ : P₀.PosSemidef) (hQ : Q.PosSemidef) (hR : R.PosDef) (k : ℕ) :
    (filtCov F Q H R P₀ k).PosSemidef := by
  induction k with
  | zero => exact hP₀
  | succ k ih => exact (corrCov_facts H R _ (predCov_psd F Q _ ih hQ) hR).1

/-- The backward pass, `j` steps back, stays below the filter. -/
theorem smoothBack_le (F Q : Matrix n n ℝ) (H : Matrix m n ℝ) (R : Matrix m m ℝ)
    (P₀ : Matrix n n ℝ) (hP₀ : P₀.PosSemidef) (hQ : Q.PosSemidef) (hR : R.PosDef) (N : ℕ) :
    ∀ j, j ≤ N → (filtCov F Q H R P₀ (N - j) - smoothBack F Q H R P₀ N j).PosSemidef := by
  intro j
  induction j with
  | zero =>
    intro _
    simp only [Nat.sub_zero, smoothBack, sub_self]
    exact PosSemidef.zero
  | succ j ih =>
    intro hj
    have ih' := ih (by omega)
    have hk1 : N - j = N - (j + 1) + 1 := by omega
    rw [hk1] at ih'
    set k := N - (j + 1)
    set Pk := filtCov F Q H R P₀ k
    set Pm := predCov F Q Pk
    set C := gain F Q H R P₀ k
    set X := smoothBack F Q H R P₀ N j
    have hstep : filtCov F Q H R P₀ (k + 1) = corrCov H R Pm := rfl
    have hgoal : filtCov F Q H R P₀ k - smoothBack F Q H R P₀ N (j + 1) = C * (Pm - X) * Cᵀ := by
      show Pk - (Pk + C * (X - Pm) * Cᵀ) = C * (Pm - X) * Cᵀ
      rw [sub_add_cancel_left, ← neg_sub Pm X, Matrix.mul_neg, Matrix.neg_mul, neg_neg]
    rw [hgoal]
    have hPmX : (Pm - X).PosSemidef := by
      have hsplit : Pm - X = (Pm - corrCov H R Pm) + (filtCov F Q H R P₀ (k + 1) - X) := by
        rw [hstep]; abel
      rw [hsplit]
      exact (corrCov_facts H R Pm
        (predCov_psd F Q Pk (filtCov_psd F Q H R P₀ hP₀ hQ hR k) hQ) hR).2.add ih'
    have := hPmX.mul_mul_conjTranspose_same C
    rwa [conjTranspose_eq_transpose_of_trivial] at this

#print axioms corrCov_facts
#print axioms predCov_psd
#print axioms filtCov_psd
#print axioms smoothBack_le

/-- **The smoothed covariance is never larger.** Run the Kalman filter forward from a start
covariance `P₀`, with push covariance `Q` and reading-noise covariance `R > 0`, then run the RTS
backward pass. At every step `k` of the record, `P^s_k ≤ P_k`: the filtered covariance minus the
smoothed one is positive semidefinite. (Lean's matrix inverse is total, so the card's condition that
`P⁻_{k+1}` be invertible is not needed for this inequality; it only makes `C_k` the regression gain.) -/
theorem rts_smoothed_covariance_le_filtered (F Q : Matrix n n ℝ) (H : Matrix m n ℝ)
    (R : Matrix m m ℝ) (P₀ : Matrix n n ℝ) (hP₀ : P₀.PosSemidef) (hQ : Q.PosSemidef)
    (hR : R.PosDef) (N k : ℕ) (hk : k ≤ N) :
    (filtCov F Q H R P₀ k - smoothCov F Q H R P₀ N k).PosSemidef := by
  have h := smoothBack_le F Q H R P₀ hP₀ hQ hR N (N - k) (Nat.sub_le N k)
  rwa [Nat.sub_sub_self hk] at h

/-- **A matrix times its own transpose is never negative, and a rotation does not change it.**
For any block `M` and any orthogonal `Θ` (`Θ Θᵀ = I`), `(M Θ)(M Θ)ᵀ = M Mᵀ`, and this product is
positive semidefinite. So the square-root filter's covariance `L Lᵀ` has no negative eigenvalue,
whatever the entries of `L` are. -/
theorem rotated_factor_product_posSemidef {k : Type*} [Fintype k] [DecidableEq k]
    (M : Matrix n k ℝ) (Θ : Matrix k k ℝ) (hΘ : Θ * Θᵀ = 1) :
    (M * Θ) * (M * Θ)ᵀ = M * Mᵀ ∧ ((M * Θ) * (M * Θ)ᵀ).PosSemidef := by
  constructor
  · rw [transpose_mul, Matrix.mul_assoc M Θ, ← Matrix.mul_assoc Θ, hΘ, Matrix.one_mul]
  · have := posSemidef_self_mul_conjTranspose (M * Θ)
    rwa [conjTranspose_eq_transpose_of_trivial] at this

/-- **The square-root correction reads off the Kalman update.** Rotate the block
`[[√R, H L⁻], [0, L⁻]]` by an orthogonal `Θ` into a lower block-triangle `[[s, 0], [K̄, L]]`.
With `P⁻ = L⁻ L⁻ᵀ` and `S = R + H P⁻ Hᵀ`, where `R = √R √Rᵀ` is invertible: `s sᵀ = S`,
so `s` is the surprise's square root `√S`; `K̄ = P⁻ Hᵀ (sᵀ)⁻¹`, the gain times `√S`; and the
new factor gives the Kalman filter's corrected covariance, `L Lᵀ = P⁻ - P⁻ Hᵀ S⁻¹ H P⁻`. -/
theorem sqrt_correction_gives_kalman_update (sR : Matrix m m ℝ) (H : Matrix m n ℝ)
    (Lm : Matrix n n ℝ) (s : Matrix m m ℝ) (Kbar : Matrix n m ℝ) (L : Matrix n n ℝ)
    (Θ : Matrix (m ⊕ n) (m ⊕ n) ℝ) (hR : IsUnit sR.det) (hΘ : Θ * Θᵀ = 1)
    (hrot : fromBlocks sR (H * Lm) 0 Lm * Θ = fromBlocks s 0 Kbar L) :
    s * sᵀ = sR * sRᵀ + H * (Lm * Lmᵀ) * Hᵀ ∧
      Kbar = (Lm * Lmᵀ) * Hᵀ * (sᵀ)⁻¹ ∧
      L * Lᵀ = Lm * Lmᵀ - (Lm * Lmᵀ) * Hᵀ * (sR * sRᵀ + H * (Lm * Lmᵀ) * Hᵀ)⁻¹ * H * (Lm * Lmᵀ) := by
  have hBB : fromBlocks s 0 Kbar L * (fromBlocks s 0 Kbar L)ᵀ =
      fromBlocks sR (H * Lm) 0 Lm * (fromBlocks sR (H * Lm) 0 Lm)ᵀ := by
    rw [← hrot, transpose_mul, Matrix.mul_assoc, ← Matrix.mul_assoc Θ, hΘ, Matrix.one_mul]
  simp only [fromBlocks_transpose, fromBlocks_multiply, transpose_zero, Matrix.mul_zero,
    Matrix.zero_mul, add_zero, zero_add, transpose_mul] at hBB
  obtain ⟨h11, h12, h21, h22⟩ := fromBlocks_inj.mp hBB
  have hPt : (Lm * Lmᵀ)ᵀ = Lm * Lmᵀ := by rw [transpose_mul, transpose_transpose]
  have h11' : s * sᵀ = sR * sRᵀ + H * (Lm * Lmᵀ) * Hᵀ := by
    rw [h11]; simp only [Matrix.mul_assoc]
  have hsR : (sR * sRᵀ).PosDef := by
    have := PosDef.mul_conjTranspose_self sR
      (vecMul_injective_iff_isUnit.mpr ((isUnit_iff_isUnit_det sR).mpr hR))
    rwa [conjTranspose_eq_transpose_of_trivial] at this
  have hHPH : (H * (Lm * Lmᵀ) * Hᵀ).PosSemidef := by
    have h1 := posSemidef_self_mul_conjTranspose Lm
    rw [conjTranspose_eq_transpose_of_trivial] at h1
    have := h1.mul_mul_conjTranspose_same H
    rwa [conjTranspose_eq_transpose_of_trivial] at this
  have hS : (sR * sRᵀ + H * (Lm * Lmᵀ) * Hᵀ).PosDef := hsR.add_posSemidef hHPH
  have hdet : (s * sᵀ).det ≠ 0 := by rw [h11']; exact hS.det_pos.ne'
  rw [det_mul, det_transpose] at hdet
  have hs : IsUnit s.det := isUnit_iff_ne_zero.mpr (left_ne_zero_of_mul hdet)
  have hst : IsUnit sᵀ.det := by rw [det_transpose]; exact hs
  have hK : Kbar = (Lm * Lmᵀ) * Hᵀ * (sᵀ)⁻¹ := by
    calc Kbar = Kbar * sᵀ * (sᵀ)⁻¹ := (mul_nonsing_inv_cancel_right _ _ hst).symm
      _ = (Lm * Lmᵀ) * Hᵀ * (sᵀ)⁻¹ := by rw [h21]; simp only [Matrix.mul_assoc]
  refine ⟨h11', hK, ?_⟩
  have hL : L * Lᵀ = Lm * Lmᵀ - Kbar * Kbarᵀ := eq_sub_of_add_eq' h22
  rw [hL, ← h11', Matrix.mul_inv_rev, hK, transpose_mul, transpose_mul, transpose_nonsing_inv,
    transpose_transpose, transpose_transpose, hPt]
  simp only [Matrix.mul_assoc]

-- The card's hand computation of the smoothed rate variance at step 49, in units of 10⁻¹² (rad/s)²:
-- 987.587423 − 3.555038 − 32.823182 − 75.762996 = 875.446207 (× 10⁻⁶).
example : (987587423 : ℤ) - 3555038 - 32823182 - 75762996 = 875446207 := by norm_num

#print axioms rts_smoothed_covariance_le_filtered
#print axioms rotated_factor_product_posSemidef
#print axioms sqrt_correction_gives_kalman_update

end RTSSmoothing
