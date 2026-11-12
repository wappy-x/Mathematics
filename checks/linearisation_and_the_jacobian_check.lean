-- Linearisation: a rest of a smooth system whose Jacobian has every eigenvalue with negative real part is stable and attracts every nearby path, the swing's leftover u - sin u is at most |u|^3/6 in size, and with air drag the swing's energy falls at rate k|ω|^3.
import Mathlib.Analysis.Calculus.ContDiff.Defs
import Mathlib.Analysis.Calculus.FDeriv.Basic
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.Complex.Basic
import Mathlib.LinearAlgebra.Matrix.ToLin
import Mathlib.LinearAlgebra.Matrix.Charpoly.Basic
import Mathlib.LinearAlgebra.Matrix.Trace
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Tactic.NormNum
import Mathlib

open Filter Topology
open scoped ContDiff

section Helpers
open scoped RealInnerProductSpace NNReal ENNReal Matrix

/-- Helper: a quadratic Lyapunov form that strictly decreases along the linear part makes the rest
stable, with paths near the rest decaying at an exponential rate. -/
theorem lyap_core {E F : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    [NormedAddCommGroup F] [InnerProductSpace ℝ F]
    {f : E → E} {A : E →L[ℝ] E} {x₀ : E} (hfA : HasFDerivAt f A x₀) (hrest : f x₀ = 0)
    (s : Finset ℕ) (Φ : ℕ → E →L[ℝ] F) {c : ℝ} (hc : 0 < c)
    (hlow : ∀ y, ‖y‖ ^ 2 ≤ ∑ j ∈ s, ‖Φ j y‖ ^ 2)
    (hdiss : ∀ y, ∑ j ∈ s, ⟪Φ j y, Φ j (A y)⟫ ≤ -c * ∑ j ∈ s, ‖Φ j y‖ ^ 2) :
    ∀ ε > 0, ∃ δ > 0, ∃ C : ℝ, ∀ x : ℝ → E,
      (∀ t ≥ 0, HasDerivWithinAt x (f (x t)) (Set.Ici 0) t) →
      ‖x 0 - x₀‖ < δ → ∀ t ≥ 0, ‖x t - x₀‖ < ε ∧ ‖x t - x₀‖ ^ 2 ≤ C * Real.exp (-(c / 2) * t) := by
  intro ε hε
  set K : ℝ := ∑ j ∈ s, ‖Φ j‖ ^ 2 with hK
  have hK0 : 0 ≤ K := Finset.sum_nonneg (fun j _ => by positivity)
  have hup : ∀ y, ∑ j ∈ s, ‖Φ j y‖ ^ 2 ≤ K * ‖y‖ ^ 2 := by
    intro y
    rw [hK, Finset.sum_mul]
    refine Finset.sum_le_sum (fun j _ => ?_)
    rw [← mul_pow]
    exact pow_le_pow_left₀ (norm_nonneg _) ((Φ j).le_opNorm y) 2
  set η : ℝ := c / (2 * (K + 1)) with hη
  have hηpos : 0 < η := by positivity
  obtain ⟨ρ, hρ, hρf⟩ := Metric.eventually_nhds_iff.1 (hfA.isLittleO.def hηpos)
  set ρ' : ℝ := min ε ρ with hρ'
  have hρ'pos : 0 < ρ' := lt_min hε hρ
  set β : ℝ := ρ' ^ 2 / 2 with hβ
  have hβpos : 0 < β := by positivity
  refine ⟨min 1 (β / (K + 1)), by positivity, β, ?_⟩
  intro x hx hx0
  set V : ℝ → ℝ := fun t => ∑ j ∈ s, ‖Φ j (x t - x₀)‖ ^ 2 with hV
  set V' : ℝ → ℝ := fun t => ∑ j ∈ s, 2 * ⟪Φ j (x t - x₀), Φ j (f (x t))⟫ with hV'
  have hVd : ∀ t ≥ 0, HasDerivWithinAt V (V' t) (Set.Ici 0) t := by
    intro t ht
    have hy := (hx t ht).sub_const x₀
    have := HasDerivWithinAt.sum (u := s) (fun j _ =>
      (((Φ j).hasFDerivAt.comp_hasDerivWithinAt t hy).norm_sq))
    rw [show V = ∑ j ∈ s, fun u => ‖Φ j (x u - x₀)‖ ^ 2 by ext u; simp [hV, Finset.sum_apply]]
    exact this
  have hVcont : ContinuousOn V (Set.Ici 0) := fun t ht => (hVd t ht).continuousWithinAt
  -- the barrier
  set Bf : ℝ → ℝ := fun t => β * Real.exp (-(c / 2) * t) with hBf
  have hBd : ∀ t, HasDerivAt Bf (-(c / 2) * Bf t) t := by
    intro t
    have := ((hasDerivAt_id t).const_mul (-(c / 2))).exp.const_mul β
    refine this.congr_deriv ?_
    show _ = -(c / 2) * (β * Real.exp (-(c / 2) * t))
    simp only [id]; ring
  have hV0 : V 0 ≤ Bf 0 := by
    have h1 := hup (x 0 - x₀)
    have hn := norm_nonneg (x 0 - x₀)
    have hd1 : ‖x 0 - x₀‖ < 1 := lt_of_lt_of_le hx0 (min_le_left _ _)
    have hd2 : ‖x 0 - x₀‖ < β / (K + 1) := lt_of_lt_of_le hx0 (min_le_right _ _)
    have : ‖x 0 - x₀‖ ^ 2 ≤ ‖x 0 - x₀‖ := by nlinarith
    have h3 : (K + 1) * ‖x 0 - x₀‖ ≤ β := by
      rw [lt_div_iff₀ (by positivity)] at hd2; nlinarith
    simp only [hBf, mul_zero, Real.exp_zero, mul_one]
    nlinarith
  have key : ∀ T ≥ 0, V T ≤ Bf T := by
    intro T hT
    refine image_le_of_deriv_right_lt_deriv_boundary' (a := 0) (b := T)
      (hVcont.mono Set.Icc_subset_Ici_self)
      (fun t ht => (hVd t ht.1).mono (Set.Ici_subset_Ici.2 ht.1)) hV0
      (fun t _ => (hBd t).continuousAt.continuousWithinAt)
      (fun t _ => (hBd t).hasDerivWithinAt) ?_ ⟨hT, le_rfl⟩
    intro t ht hVB
    have ht0 : 0 ≤ t := ht.1
    set y := x t - x₀ with hy
    have hBpos : 0 < Bf t := by positivity
    have hBle : Bf t ≤ β := by
      have : Real.exp (-(c / 2) * t) ≤ 1 := Real.exp_le_one_iff.2 (by nlinarith)
      simp only [hBf]; nlinarith
    have hyV : ‖y‖ ^ 2 ≤ V t := hlow y
    have hyρ : ‖y‖ < ρ := by
      have h1 : ‖y‖ ^ 2 < ρ' ^ 2 := by
        have : ‖y‖ ^ 2 ≤ β := by linarith
        have : β < ρ' ^ 2 := by rw [hβ]; nlinarith
        linarith
      have h2 : ‖y‖ < ρ' := by
        exact lt_of_pow_lt_pow_left₀ 2 hρ'pos.le h1
      exact lt_of_lt_of_le h2 (min_le_right _ _)
    have hr := hρf (y := x t) (by rw [dist_eq_norm]; exact hyρ)
    rw [hrest, sub_zero] at hr
    set r := f (x t) - A y with hrdef
    have hfx : f (x t) = A y + r := by rw [hrdef]; abel
    -- estimate V'
    have hsplit : V' t = 2 * ∑ j ∈ s, ⟪Φ j y, Φ j (A y)⟫ + 2 * ∑ j ∈ s, ⟪Φ j y, Φ j r⟫ := by
      show ∑ j ∈ s, 2 * ⟪Φ j y, Φ j (f (x t))⟫ = _
      simp only [hfx, map_add, inner_add_right, mul_add, Finset.sum_add_distrib,
        Finset.mul_sum]
    have hrem : ∑ j ∈ s, ⟪Φ j y, Φ j r⟫ ≤ K * (‖y‖ * ‖r‖) := by
      rw [hK, Finset.sum_mul]
      refine Finset.sum_le_sum (fun j _ => ?_)
      calc ⟪Φ j y, Φ j r⟫ ≤ ‖Φ j y‖ * ‖Φ j r‖ := real_inner_le_norm _ _
        _ ≤ (‖Φ j‖ * ‖y‖) * (‖Φ j‖ * ‖r‖) :=
          mul_le_mul ((Φ j).le_opNorm y) ((Φ j).le_opNorm r) (norm_nonneg _)
            (by positivity)
        _ = ‖Φ j‖ ^ 2 * (‖y‖ * ‖r‖) := by ring
    have hr' : ‖y‖ * ‖r‖ ≤ η * ‖y‖ ^ 2 := by
      have := mul_le_mul_of_nonneg_left hr (norm_nonneg y); nlinarith
    have hKη : K * η ≤ c / 2 := by
      rw [hη, mul_div_assoc']
      rw [div_le_div_iff₀ (by positivity) (by norm_num)]
      nlinarith
    have hdi := hdiss y
    have hVt : V t = ∑ j ∈ s, ‖Φ j y‖ ^ 2 := rfl
    have : V' t ≤ -c * V t := by
      rw [hsplit, hVt]
      have h1 : K * (‖y‖ * ‖r‖) ≤ K * (η * ‖y‖ ^ 2) := mul_le_mul_of_nonneg_left hr' hK0
      have h2 : K * (η * ‖y‖ ^ 2) ≤ (c / 2) * ‖y‖ ^ 2 := by
        rw [← mul_assoc]; exact mul_le_mul_of_nonneg_right hKη (by positivity)
      rw [hVt] at hyV
      nlinarith
    rw [hVB] at this
    nlinarith
  intro t ht
  have hVt := key t ht
  have hyV : ‖x t - x₀‖ ^ 2 ≤ V t := hlow _
  refine ⟨?_, le_trans hyV hVt⟩
  have hBle : Bf t ≤ β := by
    have : Real.exp (-(c / 2) * t) ≤ 1 := Real.exp_le_one_iff.2 (by nlinarith)
    simp only [hBf]; nlinarith
  have h1 : ‖x t - x₀‖ ^ 2 < ρ' ^ 2 := by
    have : β < ρ' ^ 2 := by rw [hβ]; nlinarith
    linarith
  exact lt_of_lt_of_le (lt_of_pow_lt_pow_left₀ 2 hρ'pos.le h1) (min_le_left _ _)

#print axioms lyap_core

set_option synthInstance.maxHeartbeats 200000 in
/-- Helper: a real matrix whose eigenvalues all have negative real part has a sum-of-squares
quadratic form that strictly decreases along `y' = M y`. -/
theorem hurwitz_dissipative_form {n : ℕ} (M : Matrix (Fin n) (Fin n) ℝ)
    (heig : ∀ μ : ℂ, Polynomial.aeval μ M.charpoly = 0 → μ.re < 0) :
    ∃ (k : ℕ) (Φ : ℕ → (Fin n → ℝ) →L[ℝ] EuclideanSpace ℂ (Fin n)) (c : ℝ), 0 < c ∧
      (∀ y, ‖y‖ ^ 2 ≤ ∑ j ∈ Finset.range k, ‖Φ j y‖ ^ 2) ∧
      (∀ y, ∑ j ∈ Finset.range k, ⟪Φ j y, Φ j (M *ᵥ y)⟫ ≤
        -c * ∑ j ∈ Finset.range k, ‖Φ j y‖ ^ 2) := by
  set AC : Matrix (Fin n) (Fin n) ℂ := M.map (algebraMap ℝ ℂ) with hAC
  set T : EuclideanSpace ℂ (Fin n) →L[ℂ] EuclideanSpace ℂ (Fin n) :=
    Matrix.toEuclideanCLM (𝕜 := ℂ) (n := Fin n) AC with hT
  have hspecT : spectrum ℂ T = spectrum ℂ AC := AlgEquiv.spectrum_eq _ AC
  have hreT : ∀ μ ∈ spectrum ℂ T, μ.re < 0 := by
    intro μ hμ
    rw [hspecT, Matrix.mem_spectrum_iff_isRoot_charpoly, hAC, Matrix.charpoly_map,
      Polynomial.IsRoot, Polynomial.eval_map_algebraMap] at hμ
    exact heig μ hμ
  have hfin : (spectrum ℂ T).Finite := by rw [hspecT]; exact Matrix.finite_spectrum AC
  -- a step size h making every |1 + h μ| < 1
  have hev : ∀ μ ∈ spectrum ℂ T, ∀ᶠ h : ℝ in 𝓝[>] (0 : ℝ), ‖1 + (h : ℂ) * μ‖ < 1 := by
    intro μ hμ
    have hre := hreT μ hμ
    have hb : 0 < -μ.re / (‖μ‖ ^ 2 + 1) := div_pos (by linarith) (by positivity)
    filter_upwards [Ioo_mem_nhdsGT hb] with h hh
    obtain ⟨hh0, hh1⟩ := hh
    rw [lt_div_iff₀ (by positivity)] at hh1
    have hn : ‖μ‖ ^ 2 = μ.re ^ 2 + μ.im ^ 2 := by
      rw [Complex.sq_norm, Complex.normSq_apply]; ring
    have h1 : ‖1 + (h : ℂ) * μ‖ ^ 2 = (1 + h * μ.re) ^ 2 + (h * μ.im) ^ 2 := by
      rw [Complex.sq_norm, Complex.normSq_apply]; simp; ring
    have h2 : ‖1 + (h : ℂ) * μ‖ ^ 2 < 1 := by
      rw [h1]; rw [hn] at hh1; nlinarith
    have h3 := norm_nonneg (1 + (h : ℂ) * μ)
    nlinarith
  obtain ⟨h, hhμ, hh⟩ := (((Filter.eventually_all_finite hfin).2 hev).and
    self_mem_nhdsWithin).exists
  replace hh : (0 : ℝ) < h := hh
  set B : EuclideanSpace ℂ (Fin n) →L[ℂ] EuclideanSpace ℂ (Fin n) := 1 + (h : ℂ) • T with hB
  have hspecB : ∀ z ∈ spectrum ℂ B, ‖z‖ < 1 := by
    intro z hz
    set μ : ℂ := (z - 1) / h with hμ
    have hhC : (h : ℂ) ≠ 0 := by exact_mod_cast hh.ne'
    have hzμ : z = 1 + (h : ℂ) * μ := by rw [hμ]; field_simp; ring
    by_cases hμs : μ ∈ spectrum ℂ T
    · rw [hzμ]; exact hhμ μ hμs
    · exfalso
      rw [spectrum.mem_iff] at hz hμs
      apply hz
      have hu : IsUnit (algebraMap ℂ _ (h : ℂ) * (algebraMap ℂ _ μ - T)) :=
        (IsUnit.map _ (isUnit_iff_ne_zero.2 hhC)).mul (not_not.1 hμs)
      convert hu using 1
      rw [mul_sub, ← map_mul, ← Algebra.smul_def, hB, hzμ, map_add, map_one]
      abel
  have hρ : spectralRadius ℂ B < 1 := by
    by_cases hne : (spectrum ℂ B).Nonempty
    · have := spectrum.spectralRadius_lt_of_forall_lt_of_nonempty (r := 1) hne
        (fun z hz => by
          have := hspecB z hz
          rw [← NNReal.coe_lt_coe, coe_nnnorm, NNReal.coe_one]; exact this)
      simpa using this
    · rw [Set.not_nonempty_iff_eq_empty] at hne
      rw [spectralRadius_eq_of_unital]; simp [hne]
  have hG := spectrum.pow_nnnorm_pow_one_div_tendsto_nhds_spectralRadius B
  obtain ⟨k, hk, hk1⟩ := ((hG.eventually_lt_const hρ).and (eventually_ge_atTop 1)).exists
  have hq : ‖B ^ k‖ < 1 := by
    by_contra hge
    push Not at hge
    have h1 : (1 : ℝ≥0∞) ≤ (‖B ^ k‖₊ : ℝ≥0∞) := by
      rw [← ENNReal.coe_one, ENNReal.coe_le_coe, ← NNReal.coe_le_coe]; simpa using hge
    have := ENNReal.one_le_rpow h1 (by positivity : (0 : ℝ) < 1 / (k : ℝ))
    exact absurd hk (not_lt.2 this)
  set q : ℝ := ‖B ^ k‖ with hqdef
  have hq0 : 0 ≤ q := norm_nonneg _
  -- the embedding of real vectors
  let ιl : (Fin n → ℝ) →ₗ[ℝ] EuclideanSpace ℂ (Fin n) :=
    { toFun := fun y => WithLp.toLp 2 (fun i => algebraMap ℝ ℂ (y i))
      map_add' := by intro a b; ext i; simp
      map_smul' := by intro r a; ext i; simp }
  let ι : (Fin n → ℝ) →L[ℝ] EuclideanSpace ℂ (Fin n) := LinearMap.toContinuousLinearMap ιl
  have hι : ∀ y, ι y = WithLp.toLp 2 (fun i => algebraMap ℝ ℂ (y i)) := fun y => rfl
  have hιM : ∀ y, ι (M *ᵥ y) = T (ι y) := by
    intro y
    rw [hι, hι, hT, Matrix.toEuclideanCLM_toLp]
    congr 1
    funext i
    exact RingHom.map_mulVec (algebraMap ℝ ℂ) M y i
  have hιnorm : ∀ y, ‖y‖ ≤ ‖ι y‖ := by
    intro y
    refine (pi_norm_le_iff_of_nonneg (norm_nonneg _)).2 (fun i => ?_)
    have := PiLp.norm_apply_le (ι y) i
    simpa [hι] using this
  -- the quadratic form on complex vectors
  set K' : ℝ := ∑ j ∈ Finset.range k, ‖B ^ j‖ ^ 2 with hK'
  have hK'0 : 0 ≤ K' := Finset.sum_nonneg (fun j _ => by positivity)
  have hPup : ∀ w, ∑ j ∈ Finset.range k, ‖(B ^ j) w‖ ^ 2 ≤ K' * ‖w‖ ^ 2 := by
    intro w
    rw [hK', Finset.sum_mul]
    refine Finset.sum_le_sum (fun j _ => ?_)
    rw [← mul_pow]
    exact pow_le_pow_left₀ (norm_nonneg _) ((B ^ j).le_opNorm w) 2
  have hBw : ∀ w, B w = w + h • T w := by
    intro w
    rw [hB, ContinuousLinearMap.add_apply, ContinuousLinearMap.smul_apply,
      ContinuousLinearMap.one_apply, RCLike.real_smul_eq_coe_smul (K := ℂ)]
    rfl
  have htel : ∀ w, ∑ j ∈ Finset.range k, ‖(B ^ j) (B w)‖ ^ 2 + ‖w‖ ^ 2 =
      ∑ j ∈ Finset.range k, ‖(B ^ j) w‖ ^ 2 + ‖(B ^ k) w‖ ^ 2 := by
    intro w
    have e1 := Finset.sum_range_succ' (fun j => ‖(B ^ j) w‖ ^ 2) k
    have e2 := Finset.sum_range_succ (fun j => ‖(B ^ j) w‖ ^ 2) k
    simp only [pow_zero, ContinuousLinearMap.one_apply] at e1
    have e3 : ∀ j, (B ^ (j + 1)) w = (B ^ j) (B w) := by
      intro j; rw [pow_succ, ContinuousLinearMap.mul_apply]
    simp only [e3] at e1
    linarith
  have hexp : ∀ w, ∑ j ∈ Finset.range k, ‖(B ^ j) (B w)‖ ^ 2 =
      ∑ j ∈ Finset.range k, ‖(B ^ j) w‖ ^ 2 +
        2 * h * ∑ j ∈ Finset.range k, ⟪(B ^ j) w, (B ^ j) (T w)⟫ +
        h ^ 2 * ∑ j ∈ Finset.range k, ‖(B ^ j) (T w)‖ ^ 2 := by
    intro w
    rw [Finset.mul_sum, Finset.mul_sum, ← Finset.sum_add_distrib, ← Finset.sum_add_distrib]
    refine Finset.sum_congr rfl (fun j _ => ?_)
    rw [hBw, map_add, ContinuousLinearMap.map_smul_of_tower]
    rw [norm_add_sq_real, real_inner_smul_right, norm_smul, mul_pow, Real.norm_eq_abs, sq_abs]
    ring
  set c : ℝ := (1 - q ^ 2) / (2 * h * (K' + 1)) with hc
  have hcpos : 0 < c := by
    have : q ^ 2 < 1 := by nlinarith
    exact div_pos (by linarith) (by positivity)
  have hdissC : ∀ w, ∑ j ∈ Finset.range k, ⟪(B ^ j) w, (B ^ j) (T w)⟫ ≤
      -c * ∑ j ∈ Finset.range k, ‖(B ^ j) w‖ ^ 2 := by
    intro w
    have h1 := htel w
    rw [hexp w] at h1
    have h2 : ‖(B ^ k) w‖ ≤ q * ‖w‖ := (B ^ k).le_opNorm w
    have h3 : ‖(B ^ k) w‖ ^ 2 ≤ q ^ 2 * ‖w‖ ^ 2 := by
      rw [← mul_pow]; exact pow_le_pow_left₀ (norm_nonneg _) h2 2
    have h4 : 0 ≤ ∑ j ∈ Finset.range k, ‖(B ^ j) (T w)‖ ^ 2 :=
      Finset.sum_nonneg (fun j _ => by positivity)
    set D := ∑ j ∈ Finset.range k, ⟪(B ^ j) w, (B ^ j) (T w)⟫
    set P := ∑ j ∈ Finset.range k, ‖(B ^ j) w‖ ^ 2
    have h5 := hPup w
    have h6 : 2 * h * D ≤ (q ^ 2 - 1) * ‖w‖ ^ 2 := by nlinarith
    have hq2 : q ^ 2 < 1 := by nlinarith
    have hc2 : c * (2 * h * (K' + 1)) = 1 - q ^ 2 := by
      rw [hc]; field_simp
    have h7 : c * P * (2 * h * (K' + 1)) ≤ (1 - q ^ 2) * ‖w‖ ^ 2 * (K' + 1) := by
      have : c * P * (2 * h * (K' + 1)) = (1 - q ^ 2) * P := by rw [← hc2]; ring
      rw [this]
      have : (1 - q ^ 2) * P ≤ (1 - q ^ 2) * (K' * ‖w‖ ^ 2) :=
        mul_le_mul_of_nonneg_left h5 (by linarith)
      nlinarith [sq_nonneg ‖w‖]
    have h8 : c * P * (2 * h) ≤ (1 - q ^ 2) * ‖w‖ ^ 2 := by
      have hK1 : 0 < K' + 1 := by positivity
      have : c * P * (2 * h) * (K' + 1) ≤ (1 - q ^ 2) * ‖w‖ ^ 2 * (K' + 1) := by
        have e : c * P * (2 * h) * (K' + 1) = c * P * (2 * h * (K' + 1)) := by ring
        rw [e]; exact h7
      exact le_of_mul_le_mul_right this hK1
    have h9 : 2 * h * D ≤ 2 * h * (-c * P) := by nlinarith
    exact le_of_mul_le_mul_left h9 (by positivity)
  refine ⟨k, fun j => ((B ^ j).restrictScalars ℝ).comp ι, c, hcpos, ?_, ?_⟩
  · intro y
    have h0 : (0 : ℕ) ∈ Finset.range k := Finset.mem_range.2 (by omega)
    have := Finset.single_le_sum (f := fun j => ‖(((B ^ j).restrictScalars ℝ).comp ι) y‖ ^ 2)
      (fun j _ => by positivity) h0
    simp only [pow_zero, ContinuousLinearMap.comp_apply, ContinuousLinearMap.coe_restrictScalars',
      ContinuousLinearMap.one_apply] at this ⊢
    have h1 := hιnorm y
    nlinarith [norm_nonneg y]
  · intro y
    simp only [ContinuousLinearMap.comp_apply, ContinuousLinearMap.coe_restrictScalars', hιM]
    exact hdissC (ι y)

#print axioms hurwitz_dissipative_form

end Helpers

/-- **Linearisation, the attracting case.** Let `x' = f x` be a system with smooth rates
`f` on `ℝⁿ`, and let `x₀` be a real rest (`f x₀ = 0`). Let `J` be the Jacobian of `f`
at `x₀` (the matrix of slopes, `fderiv ℝ f x₀` written as a matrix). If every eigenvalue
`μ` of `J` (every complex root of its characteristic polynomial) has real part below
zero, then the rest attracts, exactly as the linear system `x' = J x` does:
* it is stable: a path that starts close enough to `x₀` stays within any chosen distance
  `ε` of it for all later times, and
* paths that start close enough to `x₀` tend to `x₀` as time runs on.
A path here is any `x : ℝ → ℝⁿ` with `x' (t) = f (x t)` for every time `t ≥ 0`. -/
theorem rest_attracts_of_jacobian_eigenvalues_re_neg {n : ℕ}
    {f : (Fin n → ℝ) → (Fin n → ℝ)} (hf : ContDiff ℝ ∞ f)
    {x₀ : Fin n → ℝ} (hrest : f x₀ = 0)
    (heig : ∀ μ : ℂ,
      Polynomial.aeval μ
        (LinearMap.toMatrix' (fderiv ℝ f x₀ : (Fin n → ℝ) →ₗ[ℝ] (Fin n → ℝ))).charpoly = 0 →
      μ.re < 0) :
    (∀ ε > 0, ∃ δ > 0, ∀ x : ℝ → (Fin n → ℝ),
        (∀ t ≥ 0, HasDerivWithinAt x (f (x t)) (Set.Ici 0) t) →
        ‖x 0 - x₀‖ < δ → ∀ t ≥ 0, ‖x t - x₀‖ < ε) ∧
    (∃ δ > 0, ∀ x : ℝ → (Fin n → ℝ),
        (∀ t ≥ 0, HasDerivWithinAt x (f (x t)) (Set.Ici 0) t) →
        ‖x 0 - x₀‖ < δ → Tendsto x atTop (𝓝 x₀)) := by
  have hd : Differentiable ℝ f := hf.differentiable (by simp)
  have hfA : HasFDerivAt f (fderiv ℝ f x₀) x₀ := (hd x₀).hasFDerivAt
  obtain ⟨k, Φ, c, hc, hlow, hdiss⟩ := hurwitz_dissipative_form
    (LinearMap.toMatrix' (fderiv ℝ f x₀ : (Fin n → ℝ) →ₗ[ℝ] (Fin n → ℝ))) heig
  have hdiss' : ∀ y, ∑ j ∈ Finset.range k, inner ℝ (Φ j y) (Φ j (fderiv ℝ f x₀ y)) ≤
      -c * ∑ j ∈ Finset.range k, ‖Φ j y‖ ^ 2 := by
    intro y
    have := hdiss y
    rwa [LinearMap.toMatrix'_mulVec] at this
  have core := lyap_core hfA hrest (Finset.range k) Φ hc hlow hdiss'
  refine ⟨fun ε hε => ?_, ?_⟩
  · obtain ⟨δ, hδ, C, hC⟩ := core ε hε
    exact ⟨δ, hδ, fun x hx hx0 t ht => (hC x hx hx0 t ht).1⟩
  · obtain ⟨δ, hδ, C, hC⟩ := core 1 one_pos
    refine ⟨δ, hδ, fun x hx hx0 => ?_⟩
    rw [tendsto_iff_norm_sub_tendsto_zero]
    have hlim : Tendsto (fun t => Real.sqrt (C * Real.exp (-(c / 2) * t))) atTop (𝓝 0) := by
      have h1 : Tendsto (fun t : ℝ => -(c / 2) * t) atTop atBot :=
        tendsto_id.const_mul_atTop_of_neg (by linarith)
      have h2 := (Real.tendsto_exp_atBot.comp h1).const_mul C
      rw [mul_zero] at h2
      have := (Real.continuous_sqrt.tendsto 0).comp h2
      rw [Real.sqrt_zero] at this
      exact this
    refine squeeze_zero' (Eventually.of_forall fun t => norm_nonneg _) ?_ hlim
    filter_upwards [eventually_ge_atTop 0] with t ht
    have := Real.abs_le_sqrt (hC x hx hx0 t ht).2
    simpa using this

/-- **The swing's leftover is small.** Near a rest the swing's rate `-sin u` is the straight
line `-u` plus a leftover `u - sin u`, and that leftover is at most the cube of `u` over 6
in size, for every angle offset `u`. -/
theorem abs_sub_sin_le_cube_div_six (u : ℝ) : |u - Real.sin u| ≤ |u| ^ 3 / 6 := by
  exact Real.abs_sub_sin_le u

/-- **At a centre the drag decides.** For the swing with air drag `k w|w|` (`w` is the angular speed ω),
`θ' = w`, `w' = -sin θ - k w|w|`, the energy `E = w²/2 + 1 - cos θ` changes at the rate
`E' = -k|w|³`, for every drag strength `k` (positive, zero or negative). -/
theorem drag_swing_energy_hasDerivAt (k : ℝ) {θ w : ℝ → ℝ} {t : ℝ}
    (hθ : HasDerivAt θ (w t) t)
    (hw : HasDerivAt w (-Real.sin (θ t) - k * w t * |w t|) t) :
    HasDerivAt (fun s => w s ^ 2 / 2 + 1 - Real.cos (θ s)) (-k * |w t| ^ 3) t := by
  have h1 := (((hw.pow 2).div_const 2).add_const 1).sub hθ.cos
  refine h1.congr_deriv ?_
  have : |w t| ^ 3 = w t ^ 2 * |w t| := by rw [pow_succ, sq_abs]
  rw [this]; push_cast; ring

-- The swing's Jacobian entry -cos θₑ at the hanging rest (θₑ = 0) and the inverted rest (θₑ = π).
example : -Real.cos 0 = -1 := by norm_num
example : -Real.cos Real.pi = 1 := by norm_num

-- Hanging rest: J = [[0, 1], [-1, -1/2]], trace -1/2, determinant 1, discriminant -15/4 (= -3.75).
example : Matrix.trace !![(0 : ℝ), 1; -1, -1/2] = -1/2 := by
  norm_num [Matrix.trace_fin_two_of]
example : Matrix.det !![(0 : ℝ), 1; -1, -1/2] = 1 := by
  norm_num [Matrix.det_fin_two_of]
example : (Matrix.trace !![(0 : ℝ), 1; -1, -1/2]) ^ 2 - 4 * Matrix.det !![(0 : ℝ), 1; -1, -1/2]
    = -15/4 := by
  norm_num [Matrix.trace_fin_two_of, Matrix.det_fin_two_of]

-- Inverted rest: J = [[0, 1], [1, -1/2]], determinant -1 (a saddle), discriminant 17/4 (= 4.25).
example : Matrix.det !![(0 : ℝ), 1; 1, -1/2] = -1 := by
  norm_num [Matrix.det_fin_two_of]
example : (Matrix.trace !![(0 : ℝ), 1; 1, -1/2]) ^ 2 - 4 * Matrix.det !![(0 : ℝ), 1; 1, -1/2]
    = 17/4 := by
  norm_num [Matrix.trace_fin_two_of, Matrix.det_fin_two_of]

-- Centre case with air drag: J = [[0, 1], [-1, 0]], trace 0, determinant 1.
example : Matrix.trace !![(0 : ℝ), 1; -1, 0] = 0 := by
  norm_num [Matrix.trace_fin_two_of]
example : Matrix.det !![(0 : ℝ), 1; -1, 0] = 1 := by
  norm_num [Matrix.det_fin_two_of]

-- Not a rest: at (π/2, 0) the rates are 0 and -1.
example : -Real.sin (Real.pi / 2) - 1/2 * (0 : ℝ) = -1 := by norm_num

#print axioms rest_attracts_of_jacobian_eigenvalues_re_neg
#print axioms abs_sub_sin_le_cube_div_six
#print axioms drag_swing_energy_hasDerivAt
