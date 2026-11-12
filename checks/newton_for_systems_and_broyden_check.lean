-- Newton in several unknowns, and Broyden when a Jacobian is too expensive: Newton's method for a system converges with order 2 from a close start, Broyden's update is the smallest change that fits the newest step, and the Sherman–Morrison formula inverts a rank-one change.
import Mathlib.Analysis.Calculus.FDeriv.Basic
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Topology.Algebra.Module.ContinuousLinearMap.Invertible
import Mathlib.LinearAlgebra.Matrix.NonsingularInverse
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.Calculus.MeanValue
import Mathlib.Analysis.Calculus.Deriv.Pow
import Mathlib.Analysis.SpecificLimits.Basic
import Mathlib.Topology.Algebra.Module.FiniteDimension
import Mathlib.LinearAlgebra.Matrix.DotProduct

open Filter Topology Metric Matrix

/-- Helper: the first-order Taylor remainder is at most `(L/2) ‖y - x*‖²`. -/
theorem newton_taylor_bound {n : ℕ}
    (F : EuclideanSpace ℝ (Fin n) → EuclideanSpace ℝ (Fin n))
    (J : EuclideanSpace ℝ (Fin n) → (EuclideanSpace ℝ (Fin n) →L[ℝ] EuclideanSpace ℝ (Fin n)))
    (xstar : EuclideanSpace ℝ (Fin n)) (r L : ℝ)
    (hderiv : ∀ x ∈ closedBall xstar r, HasFDerivAt F (J x) x)
    (hLip : ∀ a ∈ closedBall xstar r, ∀ b ∈ closedBall xstar r, ‖J a - J b‖ ≤ L * ‖a - b‖)
    (y : EuclideanSpace ℝ (Fin n)) (hy : ‖y - xstar‖ ≤ r) :
    ‖F y - F xstar - J y (y - xstar)‖ ≤ L / 2 * ‖y - xstar‖ ^ 2 := by
  obtain ⟨e, rfl⟩ : ∃ e, y = xstar + e := ⟨y - xstar, by abel⟩
  rw [add_sub_cancel_left] at hy ⊢
  have hmem : ∀ t ∈ Set.Icc (0:ℝ) 1, xstar + t • e ∈ closedBall xstar r := by
    intro t ht
    rw [mem_closedBall, dist_eq_norm, add_sub_cancel_left, norm_smul, Real.norm_eq_abs,
      abs_of_nonneg ht.1]
    calc t * ‖e‖ ≤ 1 * ‖e‖ := mul_le_mul_of_nonneg_right ht.2 (norm_nonneg _)
      _ = ‖e‖ := one_mul _
      _ ≤ r := hy
  have hyball : xstar + e ∈ closedBall xstar r := by
    rw [mem_closedBall, dist_eq_norm, add_sub_cancel_left]; exact hy
  let f : ℝ → EuclideanSpace ℝ (Fin n) := fun t => F (xstar + t • e) - F xstar - t • J (xstar + e) e
  let f' : ℝ → EuclideanSpace ℝ (Fin n) := fun t => J (xstar + t • e) e - J (xstar + e) e
  have hd : ∀ t ∈ Set.Icc (0:ℝ) 1, HasDerivAt f (f' t) t := by
    intro t ht
    have h1 : HasDerivAt (fun t : ℝ => xstar + t • e) e t := by
      simpa using ((hasDerivAt_id t).smul_const e).const_add xstar
    have h2 := (hderiv _ (hmem t ht)).comp_hasDerivAt t h1
    have h3 := (h2.sub_const (F xstar)).sub ((hasDerivAt_id t).smul_const (J (xstar + e) e))
    convert h3 using 1
    · rfl
    · simp only [f', one_smul]
  have hB : ∀ t, HasDerivAt (fun t : ℝ => L * ‖e‖ ^ 2 * (t - t ^ 2 / 2))
      (L * ‖e‖ ^ 2 * (1 - t)) t := by
    intro t
    have := ((hasDerivAt_id t).sub ((hasDerivAt_pow 2 t).div_const 2)).const_mul (L * ‖e‖ ^ 2)
    convert this using 1
    simp; ring
  have bound : ∀ t ∈ Set.Ico (0:ℝ) 1, ‖f' t‖ ≤ L * ‖e‖ ^ 2 * (1 - t) := by
    intro t ht
    have hta : xstar + t • e ∈ closedBall xstar r := hmem t (Set.Ico_subset_Icc_self ht)
    have hdist : xstar + t • e - (xstar + e) = (t - 1) • e := by
      rw [sub_smul, one_smul]; abel
    calc ‖f' t‖ = ‖(J (xstar + t • e) - J (xstar + e)) e‖ := by simp [f']
      _ ≤ ‖J (xstar + t • e) - J (xstar + e)‖ * ‖e‖ := ContinuousLinearMap.le_opNorm _ _
      _ ≤ L * ‖xstar + t • e - (xstar + e)‖ * ‖e‖ :=
          mul_le_mul_of_nonneg_right (hLip _ hta _ hyball) (norm_nonneg _)
      _ = L * ‖e‖ ^ 2 * (1 - t) := by
        rw [hdist, norm_smul, Real.norm_eq_abs, abs_of_nonpos (by linarith [ht.2])]; ring
  have key := image_norm_le_of_norm_deriv_right_le_deriv_boundary (f := f) (a := 0) (b := 1)
    (f' := f')
    (fun t ht => (hd t ht).continuousAt.continuousWithinAt)
    (fun t ht => (hd t (Set.Ico_subset_Icc_self ht)).hasDerivWithinAt)
    (by simp [f]) hB bound (Set.right_mem_Icc.mpr zero_le_one)
  have hf1 : f 1 = F (xstar + e) - F xstar - J (xstar + e) e := by simp [f]
  rw [hf1] at key
  calc _ ≤ _ := key
    _ = _ := by ring

#print axioms newton_taylor_bound

/-- Helper: one Newton step from a point close enough to the root. -/
theorem newton_one_step {n : ℕ}
    (F : EuclideanSpace ℝ (Fin n) → EuclideanSpace ℝ (Fin n))
    (J : EuclideanSpace ℝ (Fin n) → (EuclideanSpace ℝ (Fin n) →L[ℝ] EuclideanSpace ℝ (Fin n)))
    (xstar : EuclideanSpace ℝ (Fin n)) (r L : ℝ)
    (hderiv : ∀ x ∈ closedBall xstar r, HasFDerivAt F (J x) x)
    (hLip : ∀ a ∈ closedBall xstar r, ∀ b ∈ closedBall xstar r, ‖J a - J b‖ ≤ L * ‖a - b‖)
    (hroot : F xstar = 0) (hinv : (J xstar).IsInvertible)
    (y : EuclideanSpace ℝ (Fin n)) (hyr : ‖y - xstar‖ ≤ r)
    (hsmall : L * ‖(J xstar).inverse‖ * ‖y - xstar‖ ≤ 1 / 2) :
    (J y).IsInvertible ∧
      ‖y - (J y).inverse (F y) - xstar‖ ≤ L / 2 * ‖(J y).inverse‖ * ‖y - xstar‖ ^ 2 ∧
      ‖y - (J y).inverse (F y) - xstar‖ ≤ L * ‖(J xstar).inverse‖ * ‖y - xstar‖ ^ 2 ∧
      ‖y - (J y).inverse (F y) - xstar‖ ≤ ‖y - xstar‖ / 2 := by
  have hM0 : 0 ≤ ‖(J xstar).inverse‖ := norm_nonneg _
  have he0 : 0 ≤ ‖y - xstar‖ := norm_nonneg _
  have hyball : y ∈ closedBall xstar r := by rw [mem_closedBall, dist_eq_norm]; exact hyr
  have hxball : xstar ∈ closedBall xstar r := mem_closedBall_self (le_trans he0 hyr)
  have hJ : ‖J y - J xstar‖ ≤ L * ‖y - xstar‖ := hLip y hyball xstar hxball
  have hLe : 0 ≤ L * ‖y - xstar‖ := le_trans (norm_nonneg _) hJ
  have hlow : ∀ v, ‖v‖ ≤ 2 * ‖(J xstar).inverse‖ * ‖J y v‖ := by
    intro v
    have h1 : ‖v‖ ≤ ‖(J xstar).inverse‖ * ‖J xstar v‖ := by
      calc ‖v‖ = ‖(J xstar).inverse (J xstar v)‖ := by rw [hinv.inverse_apply_self]
        _ ≤ ‖(J xstar).inverse‖ * ‖J xstar v‖ := ContinuousLinearMap.le_opNorm _ _
    have h2 : ‖J xstar v‖ ≤ ‖J y v‖ + L * ‖y - xstar‖ * ‖v‖ := by
      calc ‖J xstar v‖ = ‖J y v - (J y - J xstar) v‖ := by simp
        _ ≤ ‖J y v‖ + ‖(J y - J xstar) v‖ := norm_sub_le _ _
        _ ≤ ‖J y v‖ + ‖J y - J xstar‖ * ‖v‖ := by
            gcongr; exact ContinuousLinearMap.le_opNorm _ _
        _ ≤ ‖J y v‖ + L * ‖y - xstar‖ * ‖v‖ := by gcongr
    have hv0 := norm_nonneg v
    have h3 : ‖(J xstar).inverse‖ * (L * ‖y - xstar‖ * ‖v‖) ≤ ‖v‖ / 2 := by
      have : ‖(J xstar).inverse‖ * (L * ‖y - xstar‖ * ‖v‖) =
          (L * ‖(J xstar).inverse‖ * ‖y - xstar‖) * ‖v‖ := by ring
      rw [this]; nlinarith
    nlinarith [mul_le_mul_of_nonneg_left h2 hM0]
  have hinj : Function.Injective (J y) := by
    intro v w hvw
    have := hlow (v - w)
    rw [map_sub, hvw, sub_self, norm_zero, mul_zero] at this
    exact sub_eq_zero.mp (norm_le_zero_iff.mp this)
  have hJy : (J y).IsInvertible := by
    let g := LinearEquiv.ofInjectiveEndo
      (J y : EuclideanSpace ℝ (Fin n) →ₗ[ℝ] EuclideanSpace ℝ (Fin n)) hinj
    refine ⟨g.toContinuousLinearEquiv, ?_⟩
    ext v
    rfl
  have hinvnorm : ‖(J y).inverse‖ ≤ 2 * ‖(J xstar).inverse‖ := by
    refine ContinuousLinearMap.opNorm_le_bound _ (by positivity) fun w => ?_
    have := hlow ((J y).inverse w)
    rwa [hJy.self_apply_inverse] at this
  have htay := newton_taylor_bound F J xstar r L hderiv hLip y hyr
  rw [hroot, sub_zero] at htay
  have herr : y - (J y).inverse (F y) - xstar = -((J y).inverse (F y - J y (y - xstar))) := by
    rw [map_sub, hJy.inverse_apply_self]; abel
  have hb1 : ‖y - (J y).inverse (F y) - xstar‖ ≤ L / 2 * ‖(J y).inverse‖ * ‖y - xstar‖ ^ 2 := by
    rw [herr, norm_neg]
    calc _ ≤ ‖(J y).inverse‖ * ‖F y - J y (y - xstar)‖ := ContinuousLinearMap.le_opNorm _ _
      _ ≤ ‖(J y).inverse‖ * (L / 2 * ‖y - xstar‖ ^ 2) :=
          mul_le_mul_of_nonneg_left htay (norm_nonneg _)
      _ = _ := by ring
  have hb2 : L / 2 * ‖(J y).inverse‖ * ‖y - xstar‖ ^ 2 ≤
      L * ‖(J xstar).inverse‖ * ‖y - xstar‖ ^ 2 := by
    nlinarith [mul_le_mul_of_nonneg_left hinvnorm (mul_nonneg hLe he0)]
  have hb3 : L * ‖(J xstar).inverse‖ * ‖y - xstar‖ ^ 2 ≤ ‖y - xstar‖ / 2 := by
    nlinarith [mul_le_mul_of_nonneg_right hsmall he0]
  exact ⟨hJy, hb1, hb1.trans hb2, (hb1.trans hb2).trans hb3⟩

#print axioms newton_one_step

/-- Newton's method in several unknowns converges with order 2.
Let `F` map `n` unknowns to `n` values, with Jacobian `J x` at each point near a root `x*`,
where `F x* = 0`. Suppose the Jacobian changes smoothly there, `‖J a - J b‖ ≤ L ‖a - b‖`, and
`J x*` is invertible, with `M = ‖J(x*)⁻¹‖`. Start within `1 / (2 L M)` of `x*` (and inside the
region where the hypotheses hold) and take Newton steps `x_{k+1} = x_k - J(x_k)⁻¹ F(x_k)`.
Then every step is defined (`J x_k` is invertible), the error obeys
`‖e_{k+1}‖ ≤ (L/2) ‖J(x_k)⁻¹‖ ‖e_k‖²` and `‖e_{k+1}‖ ≤ L M ‖e_k‖²`, it at least halves each step,
and the iterates converge to `x*`. -/
theorem newton_converges_quadratically {n : ℕ}
    (F : EuclideanSpace ℝ (Fin n) → EuclideanSpace ℝ (Fin n))
    (J : EuclideanSpace ℝ (Fin n) → (EuclideanSpace ℝ (Fin n) →L[ℝ] EuclideanSpace ℝ (Fin n)))
    (xstar : EuclideanSpace ℝ (Fin n)) (r L : ℝ)
    (hderiv : ∀ x ∈ closedBall xstar r, HasFDerivAt F (J x) x)
    (hLip : ∀ a ∈ closedBall xstar r, ∀ b ∈ closedBall xstar r, ‖J a - J b‖ ≤ L * ‖a - b‖)
    (hroot : F xstar = 0)
    (hinv : (J xstar).IsInvertible)
    (x : ℕ → EuclideanSpace ℝ (Fin n))
    (hx0r : ‖x 0 - xstar‖ ≤ r)
    (hx0 : ‖x 0 - xstar‖ ≤ 1 / (2 * L * ‖(J xstar).inverse‖))
    (hstep : ∀ k, x (k + 1) = x k - (J (x k)).inverse (F (x k))) :
    (∀ k, (J (x k)).IsInvertible ∧
      ‖x (k + 1) - xstar‖ ≤ L / 2 * ‖(J (x k)).inverse‖ * ‖x k - xstar‖ ^ 2 ∧
      ‖x (k + 1) - xstar‖ ≤ L * ‖(J xstar).inverse‖ * ‖x k - xstar‖ ^ 2 ∧
      ‖x (k + 1) - xstar‖ ≤ ‖x k - xstar‖ / 2) ∧
    Tendsto x atTop (𝓝 xstar) := by
  have hM0 := norm_nonneg ((J xstar).inverse)
  have hr0 : 0 ≤ r := le_trans (norm_nonneg _) hx0r
  have hxball : xstar ∈ closedBall xstar r := mem_closedBall_self hr0
  have hLM : 0 ≤ L → L * ‖(J xstar).inverse‖ * ‖x 0 - xstar‖ ≤ 1 / 2 := by
    intro hL
    rcases eq_or_lt_of_le (mul_nonneg (mul_nonneg zero_le_two hL) hM0) with h | h
    · have : L * ‖(J xstar).inverse‖ = 0 := by linarith
      rw [this, zero_mul]; norm_num
    · have := (le_div_iff₀ h).mp hx0
      nlinarith
  have hsmall : ∀ y, ‖y - xstar‖ ≤ r → ‖y - xstar‖ ≤ ‖x 0 - xstar‖ →
      L * ‖(J xstar).inverse‖ * ‖y - xstar‖ ≤ 1 / 2 := by
    intro y hyr hy0
    have hyball : y ∈ closedBall xstar r := by rw [mem_closedBall, dist_eq_norm]; exact hyr
    have hLe : 0 ≤ L * ‖y - xstar‖ := le_trans (norm_nonneg _) (hLip y hyball xstar hxball)
    rcases le_or_gt 0 L with hL | hL
    · have h1 := hLM hL
      have h2 : L * ‖(J xstar).inverse‖ * ‖y - xstar‖ ≤
          L * ‖(J xstar).inverse‖ * ‖x 0 - xstar‖ :=
        mul_le_mul_of_nonneg_left hy0 (mul_nonneg hL hM0)
      linarith
    · have : ‖y - xstar‖ = 0 := by nlinarith [norm_nonneg (y - xstar)]
      rw [this, mul_zero]; norm_num
  have hbound : ∀ k, ‖x k - xstar‖ ≤ ‖x 0 - xstar‖ * (1 / 2) ^ k := by
    intro k
    induction k with
    | zero => simp
    | succ k ih =>
      have hk0 : ‖x k - xstar‖ ≤ ‖x 0 - xstar‖ :=
        ih.trans (mul_le_of_le_one_right (norm_nonneg _) (pow_le_one₀ (by norm_num) (by norm_num)))
      have hkr := hk0.trans hx0r
      have := (newton_one_step F J xstar r L hderiv hLip hroot hinv (x k) hkr
        (hsmall _ hkr hk0)).2.2.2
      rw [hstep k, pow_succ]
      linarith
  refine ⟨fun k => ?_, ?_⟩
  · have hk0 : ‖x k - xstar‖ ≤ ‖x 0 - xstar‖ :=
      (hbound k).trans
        (mul_le_of_le_one_right (norm_nonneg _) (pow_le_one₀ (by norm_num) (by norm_num)))
    have hkr := hk0.trans hx0r
    rw [hstep k]
    exact newton_one_step F J xstar r L hderiv hLip hroot hinv (x k) hkr (hsmall _ hkr hk0)
  · rw [tendsto_iff_norm_sub_tendsto_zero]
    refine squeeze_zero (fun k => norm_nonneg _) hbound ?_
    have := (tendsto_pow_atTop_nhds_zero_of_lt_one (by norm_num : (0:ℝ) ≤ 1 / 2)
      (by norm_num)).const_mul ‖x 0 - xstar‖
    rwa [mul_zero] at this

/-- Helper: a rank-one matrix times a vector. -/
theorem vecMulVec_mulVec_eq_smul {n : ℕ} (u v w : Fin n → ℝ) :
    vecMulVec u v *ᵥ w = (v ⬝ᵥ w) • u := by
  ext i
  simp [mulVec, dotProduct, vecMulVec_apply, Finset.sum_mul]
  refine Finset.sum_congr rfl fun j _ => by ring

#print axioms vecMulVec_mulVec_eq_smul

/-- Broyden's update is the smallest change that fits the newest step.
For a step `s ≠ 0` and observed change `y`, Broyden's new table
`B₁ = B₀ + (y - B₀ s) sᵀ / (sᵀ s)` satisfies the secant condition `B₁ s = y`, leaves every
direction `w` at right angles to `s` unchanged (`B₁ w = B₀ w`), and among all matrices `B`
with `B s = y` it is the unique closest one to `B₀` in the Frobenius size (the square root of
the sum of squared entries; compared here through the squares). -/
theorem broyden_update_least_change {n : ℕ} (B₀ B₁ : Matrix (Fin n) (Fin n) ℝ)
    (s y : Fin n → ℝ) (hs : s ≠ 0)
    (hB₁ : B₁ = B₀ + (s ⬝ᵥ s)⁻¹ • vecMulVec (y - B₀ *ᵥ s) s) :
    B₁ *ᵥ s = y ∧
    (∀ w : Fin n → ℝ, s ⬝ᵥ w = 0 → B₁ *ᵥ w = B₀ *ᵥ w) ∧
    (∀ B : Matrix (Fin n) (Fin n) ℝ, B *ᵥ s = y →
      ∑ i, ∑ j, (B₁ - B₀) i j ^ 2 ≤ ∑ i, ∑ j, (B - B₀) i j ^ 2 ∧
      (∑ i, ∑ j, (B₁ - B₀) i j ^ 2 = ∑ i, ∑ j, (B - B₀) i j ^ 2 → B = B₁)) := by
  have hc : s ⬝ᵥ s ≠ 0 := fun h => hs (dotProduct_self_eq_zero.mp h)
  set c := s ⬝ᵥ s with hcdef
  set u := y - B₀ *ᵥ s with hu
  have hB₁s : B₁ *ᵥ s = y := by
    rw [hB₁, add_mulVec, smul_mulVec, vecMulVec_mulVec_eq_smul, ← hcdef, smul_smul,
      inv_mul_cancel₀ hc, one_smul, hu]
    abel
  refine ⟨hB₁s, ?_, ?_⟩
  · intro w hw
    rw [hB₁, add_mulVec, smul_mulVec, vecMulVec_mulVec_eq_smul, hw, zero_smul, smul_zero,
      add_zero]
  · intro B hB
    set R := B - B₁ with hRdef
    have hR : R *ᵥ s = 0 := by rw [hRdef, sub_mulVec, hB, hB₁s, sub_self]
    have hE : ∀ i j, (B₁ - B₀) i j = c⁻¹ * (u i * s j) := by
      intro i j
      rw [hB₁]
      simp [vecMulVec_apply]
    have hD : ∀ i j, (B - B₀) i j = c⁻¹ * (u i * s j) + R i j := by
      intro i j
      rw [← hE, hRdef]
      simp
    have hcross : ∑ i, ∑ j, c⁻¹ * (u i * s j) * R i j = 0 := by
      have h1 : ∀ i, ∑ j, c⁻¹ * (u i * s j) * R i j = c⁻¹ * u i * (R *ᵥ s) i := by
        intro i
        simp only [mulVec, dotProduct, Finset.mul_sum]
        exact Finset.sum_congr rfl fun j _ => by ring
      simp [h1, hR]
    have key : ∑ i, ∑ j, (B - B₀) i j ^ 2 =
        ∑ i, ∑ j, (B₁ - B₀) i j ^ 2 + ∑ i, ∑ j, R i j ^ 2 := by
      calc ∑ i, ∑ j, (B - B₀) i j ^ 2
          = ∑ i, ∑ j, ((B₁ - B₀) i j ^ 2 + R i j ^ 2 + 2 * (c⁻¹ * (u i * s j) * R i j)) :=
            Finset.sum_congr rfl fun i _ => Finset.sum_congr rfl fun j _ => by
              rw [hD, hE]; ring
        _ = ∑ i, ∑ j, (B₁ - B₀) i j ^ 2 + ∑ i, ∑ j, R i j ^ 2 +
              2 * ∑ i, ∑ j, c⁻¹ * (u i * s j) * R i j := by
            simp only [Finset.sum_add_distrib, Finset.mul_sum]
        _ = _ := by rw [hcross]; ring
    have hRnn : 0 ≤ ∑ i, ∑ j, R i j ^ 2 :=
      Finset.sum_nonneg fun i _ => Finset.sum_nonneg fun j _ => sq_nonneg _
    refine ⟨by linarith, fun heq => ?_⟩
    have h0 : ∑ i, ∑ j, R i j ^ 2 = 0 := by linarith
    have hR0 : R = 0 := by
      ext i j
      have hi := (Finset.sum_eq_zero_iff_of_nonneg (fun i _ =>
        Finset.sum_nonneg fun j _ => sq_nonneg (R i j))).mp h0 i (Finset.mem_univ _)
      have hij := (Finset.sum_eq_zero_iff_of_nonneg (fun j _ => sq_nonneg (R i j))).mp hi j
        (Finset.mem_univ _)
      simpa using hij
    rw [hRdef] at hR0
    exact sub_eq_zero.mp hR0

/-- The Sherman–Morrison formula: if `A` is invertible and `1 + bᵀ A⁻¹ a ≠ 0`, then
`(A + a bᵀ)⁻¹ = A⁻¹ - A⁻¹ a bᵀ A⁻¹ / (1 + bᵀ A⁻¹ a)`. -/
theorem sherman_morrison {n : ℕ} (A : Matrix (Fin n) (Fin n) ℝ) (a b : Fin n → ℝ)
    (hA : IsUnit A) (hθ : 1 + b ⬝ᵥ (A⁻¹ *ᵥ a) ≠ 0) :
    (A + vecMulVec a b)⁻¹ =
      A⁻¹ - (1 + b ⬝ᵥ (A⁻¹ *ᵥ a))⁻¹ • vecMulVec (A⁻¹ *ᵥ a) (b ᵥ* A⁻¹) := by
  apply Matrix.inv_eq_right_inv
  have hdet : IsUnit A.det := (Matrix.isUnit_iff_isUnit_det A).mp hA
  set c := b ⬝ᵥ (A⁻¹ *ᵥ a) with hc
  set V := vecMulVec a (b ᵥ* A⁻¹) with hV
  have hAA : A *ᵥ (A⁻¹ *ᵥ a) = a := by
    rw [mulVec_mulVec, mul_nonsing_inv _ hdet, one_mulVec]
  rw [add_mul, Matrix.mul_sub, Matrix.mul_sub, Matrix.mul_smul, Matrix.mul_smul, mul_vecMulVec,
    mul_vecMulVec, mul_nonsing_inv _ hdet, vecMulVec_mul, hAA, vecMulVec_mulVec_eq_smul, ← hc,
    smul_vecMulVec, ← hV]
  have key : (1 + c)⁻¹ • V + (1 + c)⁻¹ • c • V = V := by
    rw [smul_smul, ← add_smul]
    have : (1 + c)⁻¹ + (1 + c)⁻¹ * c = 1 := by
      calc (1 + c)⁻¹ + (1 + c)⁻¹ * c = (1 + c)⁻¹ * (1 + c) := by ring
        _ = 1 := inv_mul_cancel₀ hθ
    rw [this, one_smul]
  calc 1 - (1 + c)⁻¹ • V + (V - (1 + c)⁻¹ • c • V)
      = 1 + (V - ((1 + c)⁻¹ • V + (1 + c)⁻¹ • c • V)) := by abel
    _ = 1 := by rw [key, sub_self, add_zero]

-- The tanks: c₀ = 10, c₁ = 4, c₂ = 5/2, γ = 1/500, β₁ = 4, β₂ = 40, flows (p, q), total u = p + q.
-- Yesterday's flows (2, 6): the balances are (-14.048, -0.8) mg/s.
example : (10 : ℚ) * 2 - 4 * (2 + 6) * (1 + 1 / 500 * 4 * (2 + 6)) = -1756 / 125 := by norm_num
example : (4 : ℚ) * (2 + 6) - 5 / 2 * (2 + 6) * (1 + 1 / 500 * 40 * (2 + 6)) = -4 / 5 := by norm_num
-- The answer (3.18, 4.32), total 7.5, makes both balances zero.
example : (10 : ℚ) * (159 / 50) - 4 * (159 / 50 + 108 / 25) * (1 + 1 / 500 * 4 * (159 / 50 + 108 / 25)) = 0 := by
  norm_num
example : (4 : ℚ) * (159 / 50 + 108 / 25) - 5 / 2 * (159 / 50 + 108 / 25) * (1 + 1 / 500 * 40 * (159 / 50 + 108 / 25)) = 0 := by
  norm_num
-- det J = c₀ g: -17 at yesterday's total 8, -15 at the answer's total 15/2, and 0 at total 15/4.
example : (10 : ℚ) * (4 - 5 / 2 * (1 + 2 * (1 / 500) * 40 * 8)) = -17 := by norm_num
example : (10 : ℚ) * (4 - 5 / 2 * (1 + 2 * (1 / 500) * 40 * (15 / 2))) = -15 := by norm_num
example : (10 : ℚ) * (4 - 5 / 2 * (1 + 2 * (1 / 500) * 40 * (15 / 4))) = 0 := by norm_num
-- J(x₀) top row: h = 4.512, so (10 - h, -h) = (5.488, -4.512).
example : (4 : ℚ) * (1 + 2 * (1 / 500) * 4 * 8) = 564 / 125 := by norm_num
-- Try: tank 2 at 2 mg/L gives total 12.5, p = 5.5, q = 7.
example : (10 : ℚ) * (11 / 2) - 4 * (25 / 2) * (1 + 1 / 500 * 4 * (25 / 2)) = 0 ∧
    (4 : ℚ) * (25 / 2) - 2 * (25 / 2) * (1 + 1 / 500 * 40 * (25 / 2)) = 0 := by norm_num
-- Try: decay halved gives total 15, p = 6.36, q = 8.64.
example : (10 : ℚ) * (159 / 25) - 4 * 15 * (1 + 1 / 1000 * 4 * 15) = 0 ∧
    (4 : ℚ) * 15 - 5 / 2 * 15 * (1 + 1 / 1000 * 40 * 15) = 0 ∧ (159 : ℚ) / 25 + 216 / 25 = 15 := by
  norm_num
-- Broyden's cost per step at n = 500: about 8 n² = 2,000,000 flops.
example : 8 * 500 ^ 2 = 2000000 := by norm_num

#print axioms newton_converges_quadratically
#print axioms broyden_update_least_change
#print axioms sherman_morrison
