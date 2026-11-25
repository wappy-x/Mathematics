-- Gelfond-Schneider: an algebraic number other than 0 and 1, raised to an algebraic power that is not a fraction, is transcendental, for every choice of logarithm; Siegel's lemma gives a small nonzero whole solution to any system with more unknowns than equations.
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.NumberTheory.SiegelsLemma
import Mathlib.RingTheory.Algebraic.Defs
import Mathlib.Analysis.Complex.AbsMax
import Mathlib.Analysis.Analytic.Order
import Mathlib.Analysis.Calculus.IteratedDeriv.Analytic
import Mathlib.Analysis.Calculus.IteratedDeriv.Lemmas
import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.NumberTheory.NumberField.House
import Mathlib.NumberTheory.Real.Irrational
import Mathlib.RingTheory.Algebraic.Denominator
import Mathlib.LinearAlgebra.Vandermonde
import Mathlib.LinearAlgebra.Complex.Module
import Mathlib.FieldTheory.IntermediateField.Adjoin.Basic

open Matrix

section GelfondSchneiderHelpers

open Complex Metric Set Filter Topology NumberField Matrix

lemma gs_exists_entire_div (F : ℂ → ℂ) (hF : ∀ z, AnalyticAt ℂ F z) (c : ℂ) (r : ℕ)
    (h : (r : ℕ∞) ≤ analyticOrderAt F c) :
    ∃ G : ℂ → ℂ, (∀ z, AnalyticAt ℂ G z) ∧ ∀ z, F z = (z - c) ^ r * G z := by
  classical
  obtain ⟨g, hg, hFg⟩ := (natCast_le_analyticOrderAt (hF c)).1 h
  refine ⟨fun z => if z = c then g c else F z / (z - c) ^ r, ?_, ?_⟩
  · intro z
    by_cases hz : z = c
    · subst hz
      refine hg.congr ?_
      filter_upwards [hFg] with w hw
      by_cases hw' : w = z
      · simp [hw']
      · have : (w - z) ^ r ≠ 0 := pow_ne_zero _ (sub_ne_zero.2 hw')
        simp only [hw', ite_false, hw, smul_eq_mul]
        field_simp
    · have hev : (fun w => F w / (w - c) ^ r) =ᶠ[𝓝 z]
          (fun w => if w = c then g c else F w / (w - c) ^ r) := by
        filter_upwards [isOpen_compl_singleton.mem_nhds (show z ∈ ({c}ᶜ : Set ℂ) from hz)]
          with w hw
        simp only [mem_compl_iff, mem_singleton_iff] at hw
        simp [hw]
      refine AnalyticAt.congr ?_ hev
      exact (hF z).div (by fun_prop) (pow_ne_zero _ (sub_ne_zero.2 hz))
  · intro z
    by_cases hz : z = c
    · subst hz
      have := hFg.self_of_nhds
      simpa using this
    · have : (z - c) ^ r ≠ 0 := pow_ne_zero _ (sub_ne_zero.2 hz)
      simp only [hz, ite_false]
      field_simp

#print axioms gs_exists_entire_div

lemma gs_exists_entire_div_prod (F : ℂ → ℂ) (hF : ∀ z, AnalyticAt ℂ F z) (s : Finset ℂ)
    (r : ℕ) (h : ∀ c ∈ s, (r : ℕ∞) ≤ analyticOrderAt F c) :
    ∃ G : ℂ → ℂ, (∀ z, AnalyticAt ℂ G z) ∧ ∀ z, F z = (∏ c ∈ s, (z - c) ^ r) * G z := by
  classical
  induction s using Finset.induction_on generalizing F with
  | empty => exact ⟨F, hF, fun z => by simp⟩
  | insert a s ha IH =>
    obtain ⟨G, hG, hFG⟩ := IH F hF (fun c hc => h c (Finset.mem_insert_of_mem hc))
    have hP : AnalyticAt ℂ (fun z => ∏ c ∈ s, (z - c) ^ r) a := by fun_prop
    have hPa : (fun z => ∏ c ∈ s, (z - c) ^ r) a ≠ 0 := by
      simp only
      rw [Finset.prod_ne_zero_iff]
      intro c hc
      exact pow_ne_zero _ (sub_ne_zero.2 (fun h' => ha (h' ▸ hc)))
    have hfun : F = (fun z => ∏ c ∈ s, (z - c) ^ r) * G := funext hFG
    have hord : (r : ℕ∞) ≤ analyticOrderAt G a := by
      have h1 := h a (Finset.mem_insert_self a s)
      rw [hfun, analyticOrderAt_mul hP (hG a), hP.analyticOrderAt_eq_zero.2 hPa, zero_add] at h1
      exact h1
    obtain ⟨G', hG', hGG'⟩ := gs_exists_entire_div G hG a r hord
    refine ⟨G', hG', fun z => ?_⟩
    rw [hFG z, hGG' z, Finset.prod_insert ha]
    ring

#print axioms gs_exists_entire_div_prod

/-- Schwarz-type bound for a derivative at a point where all lower derivatives vanish at all points
of `s`. -/

lemma gs_schwarz (F : ℂ → ℂ) (hF : ∀ z, AnalyticAt ℂ F z) (s : Finset ℂ) (r : ℕ) (c₀ : ℂ)
    (hc₀ : c₀ ∈ s) (h : ∀ c ∈ s, ∀ k < r, iteratedDeriv k F c = 0) (R : ℝ)
    (hR : ∀ c ∈ s, ‖c‖ < R) (M δ : ℝ) (hM : ∀ z, ‖z‖ = R → ‖F z‖ ≤ M) (hδ : 0 < δ)
    (hδ' : ∀ z, ‖z‖ = R → ∀ c ∈ s, δ ≤ ‖z - c‖) :
    ‖iteratedDeriv r F c₀‖ ≤
      r.factorial * (∏ c ∈ s.erase c₀, ‖c₀ - c‖ ^ r) * (M / δ ^ (r * s.card)) := by
  classical
  obtain ⟨G, hG, hFG⟩ := gs_exists_entire_div_prod F hF s r
    (fun c hc => (natCast_le_analyticOrderAt_iff_iteratedDeriv_eq_zero (hF c)).2 (h c hc))
  set Q : ℂ → ℂ := fun z => ∏ c ∈ s.erase c₀, (z - c) ^ r with hQ
  have hH : ∀ z, AnalyticAt ℂ (fun z => Q z * G z) z := fun z => by
    simp only [hQ]; exact (by fun_prop : AnalyticAt ℂ (fun z => ∏ c ∈ s.erase c₀, (z - c) ^ r) z).mul (hG z)
  have hFeq : ∀ z, F z = (z - c₀) ^ (r + 0) * (Q z * G z) := fun z => by
    rw [hFG z, ← Finset.mul_prod_erase s _ hc₀]
    simp only [hQ, add_zero]
    ring
  obtain ⟨R₂, -, hR₂⟩ := iteratedDeriv_mul_pow_sub_of_analytic hH hFeq
  have hval : iteratedDeriv r F c₀ = r.factorial * (Q c₀ * G c₀) := by
    rw [hR₂ c₀]; simp
  have hR0 : 0 < R := lt_of_le_of_lt (norm_nonneg _) (hR c₀ hc₀)
  -- maximum modulus for G
  have hGbound : ‖G c₀‖ ≤ M / δ ^ (r * s.card) := by
    have hdiff : Differentiable ℂ G := fun z => (hG z).differentiableAt
    refine Complex.norm_le_of_forall_mem_frontier_norm_le (U := ball (0 : ℂ) R)
      isBounded_ball hdiff.diffContOnCl ?_ ?_
    · intro z hz
      rw [frontier_ball (0 : ℂ) hR0.ne'] at hz
      have hzR : ‖z‖ = R := by simpa using hz
      have hP : δ ^ (r * s.card) ≤ ‖∏ c ∈ s, (z - c) ^ r‖ := by
        rw [norm_prod]
        calc δ ^ (r * s.card) = ∏ c ∈ s, δ ^ r := by
                rw [Finset.prod_const, ← pow_mul]
          _ ≤ ∏ c ∈ s, ‖(z - c) ^ r‖ := by
                gcongr with c hc
                rw [norm_pow]
                exact pow_le_pow_left₀ hδ.le (hδ' z hzR c hc) r
      have hPpos : 0 < ‖∏ c ∈ s, (z - c) ^ r‖ := lt_of_lt_of_le (by positivity) hP
      have hFz := hM z hzR
      rw [hFG z, norm_mul] at hFz
      rw [le_div_iff₀ (by positivity)]
      calc ‖G z‖ * δ ^ (r * s.card) ≤ ‖G z‖ * ‖∏ c ∈ s, (z - c) ^ r‖ := by gcongr
        _ = ‖∏ c ∈ s, (z - c) ^ r‖ * ‖G z‖ := by ring
        _ ≤ M := hFz
    · apply subset_closure
      simpa using hR c₀ hc₀
  rw [hval, norm_mul, norm_mul, Complex.norm_natCast, mul_assoc]
  gcongr
  · simp only [hQ, norm_prod, norm_pow]; exact le_rfl

#print axioms gs_schwarz

lemma gs_expsum_analytic {ι : Type*} [Fintype ι] (w μ : ι → ℂ) (z : ℂ) :
    AnalyticAt ℂ (fun z => ∑ j, w j * exp (μ j * z)) z := by
  fun_prop

#print axioms gs_expsum_analytic

lemma gs_iteratedDeriv_expsum {ι : Type*} [Fintype ι] (w μ : ι → ℂ) (k : ℕ) :
    iteratedDeriv k (fun z => ∑ j, w j * exp (μ j * z)) =
      fun z => ∑ j, w j * μ j ^ k * exp (μ j * z) := by
  induction k with
  | zero => simp
  | succ k IH =>
    rw [iteratedDeriv_succ, IH]
    funext z
    have hd : HasDerivAt (fun z => ∑ j, w j * μ j ^ k * exp (μ j * z))
        (∑ j, w j * μ j ^ k * (exp (μ j * z) * μ j)) z := by
      apply HasDerivAt.fun_sum
      intro j _
      apply HasDerivAt.const_mul
      have := ((hasDerivAt_id z).const_mul (μ j)).cexp
      simpa using this
    rw [hd.deriv]
    apply Finset.sum_congr rfl
    intro j _
    ring

#print axioms gs_iteratedDeriv_expsum

lemma gs_expsum_norm_le {ι : Type*} [Fintype ι] (w μ : ι → ℂ) (W B : ℝ)
    (hw : ∀ j, ‖w j‖ ≤ W) (hμ : ∀ j, ‖μ j‖ ≤ B) (z : ℂ) :
    ‖∑ j, w j * exp (μ j * z)‖ ≤ Fintype.card ι * (W * Real.exp (B * ‖z‖)) := by
  calc ‖∑ j, w j * exp (μ j * z)‖ ≤ ∑ j, ‖w j * exp (μ j * z)‖ := norm_sum_le _ _
    _ ≤ ∑ _j : ι, W * Real.exp (B * ‖z‖) := by
        apply Finset.sum_le_sum
        intro j _
        rw [norm_mul, Complex.norm_exp]
        have hW : 0 ≤ W := (norm_nonneg _).trans (hw j)
        gcongr
        · exact hw j
        · calc (μ j * z).re ≤ ‖μ j * z‖ := Complex.re_le_norm _
            _ = ‖μ j‖ * ‖z‖ := norm_mul _ _
            _ ≤ B * ‖z‖ := by gcongr; exact hμ j
    _ = Fintype.card ι * (W * Real.exp (B * ‖z‖)) := by
        rw [Finset.sum_const, Finset.card_univ, nsmul_eq_mul]

#print axioms gs_expsum_norm_le

lemma gs_expsum_deriv_ne_zero {ι : Type*} [Fintype ι] (w μ : ι → ℂ)
    (hμ : Function.Injective μ) (hw : w ≠ 0) (z₀ : ℂ) :
    ∃ k < Fintype.card ι, ∑ j, w j * μ j ^ k * exp (μ j * z₀) ≠ 0 := by
  classical
  by_contra hcon
  push Not at hcon
  set N := Fintype.card ι
  let e : ι ≃ Fin N := Fintype.equivFin ι
  let μ' : Fin N → ℂ := μ ∘ e.symm
  let v : Fin N → ℂ := fun i => w (e.symm i) * exp (μ' i * z₀)
  have hμ' : Function.Injective μ' := hμ.comp e.symm.injective
  have hdet : (Matrix.vandermonde μ').transpose.det ≠ 0 := by
    rw [Matrix.det_transpose]; exact Matrix.det_vandermonde_ne_zero_iff.2 hμ'
  have hmul : (Matrix.vandermonde μ').transpose.mulVec v = 0 := by
    funext k
    simp only [Matrix.mulVec, dotProduct, Matrix.transpose_apply, Matrix.vandermonde_apply,
      Pi.zero_apply]
    have := hcon k k.2
    rw [← e.symm.sum_comp] at this
    rw [← this]
    apply Finset.sum_congr rfl
    intro i _
    simp only [v, μ', Function.comp]
    ring
  have hv := Matrix.eq_zero_of_mulVec_eq_zero hdet hmul
  apply hw
  funext j
  have := congrFun hv (e j)
  simp only [v, μ', Function.comp, Equiv.symm_apply_apply, Pi.zero_apply] at this
  simpa [Complex.exp_ne_zero] using this

#print axioms gs_expsum_deriv_ne_zero

lemma gs_liouville {K : Type*} [Field K] [NumberField K] (σ : K →+* ℂ) (x : K)
    (hx : IsIntegral ℤ x) (hx0 : x ≠ 0) :
    1 ≤ ‖σ x‖ * house x ^ (Module.finrank ℚ K - 1) := by
  refine le_trans ?_ (norm_norm_le_norm_mul_house_pow x σ)
  let y : 𝓞 K := ⟨x, hx⟩
  have hy0 : y ≠ 0 := by
    intro h; apply hx0
    calc x = (y : K) := rfl
      _ = 0 := by rw [h]; simp
  have hN : Algebra.norm ℤ y ≠ 0 := Algebra.norm_ne_zero_iff.2 hy0
  have hcoe := Algebra.coe_norm_int y
  have : (y : K) = x := rfl
  rw [this] at hcoe
  rw [← hcoe]
  have h1 : (1 : ℝ) ≤ |((Algebra.norm ℤ y : ℤ) : ℝ)| := by
    have : (1 : ℤ) ≤ |Algebra.norm ℤ y| := Int.one_le_abs hN
    exact_mod_cast this
  simpa [Int.norm_eq_abs] using h1

#print axioms gs_liouville

lemma gs_siegel_const (K : Type*) [Field K] [NumberField K] :
    ∃ c₁ : ℝ, ∀ (α β : Type) [Fintype α] [Fintype β] (a : Matrix α β (𝓞 K)), a ≠ 0 →
      ∀ A : ℝ, (∀ k l, house (algebraMap (𝓞 K) K (a k l)) ≤ A) →
      0 < Fintype.card α → Fintype.card α < Fintype.card β →
      ∃ ξ : β → 𝓞 K, ξ ≠ 0 ∧ a *ᵥ ξ = 0 ∧ ∀ l, house (algebraMap (𝓞 K) K (ξ l)) ≤
        c₁ * (c₁ * Fintype.card β * A) ^
          ((Fintype.card α : ℝ) / ((Fintype.card β : ℝ) - Fintype.card α)) := by
  classical
  exact ⟨_, fun α β _ _ a ha A habs h0 hpq =>
    house.exists_ne_zero_int_vec_house_le K a ha h0 hpq rfl habs rfl⟩

#print axioms gs_siegel_const

lemma gs_house_natCast {K : Type*} [Field K] [NumberField K] (c : ℕ) :
    house (c : K) = c := by
  have := house_intCast (K := K) (c : ℤ)
  simpa using this

#print axioms gs_house_natCast

lemma gs_E_eq {K : Type*} [Field K] (α β γ : K) (c : ℕ) (L k m j1 j2 : ℕ) (hj1 : j1 < L)
    (hj2 : j2 < L) :
    ∃ a b : ℕ, (c : K) ^ (k + 2 * (L - 1) * m) * (((j1 : K) + (j2 : K) * β) ^ k *
      α ^ (j1 * m) * γ ^ (j2 * m)) =
      ((c : K) * ((j1 : K) + j2 * β)) ^ k * ((c * α) ^ j1 * (c : K) ^ a) ^ m *
        ((c * γ) ^ j2 * (c : K) ^ b) ^ m := by
  refine ⟨L - 1 - j1, L - 1 - j2, ?_⟩
  have ha' : L - 1 = j1 + (L - 1 - j1) := by omega
  have hb' : L - 1 = j2 + (L - 1 - j2) := by omega
  have hk : k + 2 * (L - 1) * m = k + (j1 + (L - 1 - j1)) * m + (j2 + (L - 1 - j2)) * m := by
    rw [← ha', ← hb']; ring
  rw [hk, mul_pow]
  ring

#print axioms gs_E_eq

lemma gs_E_integral {K : Type*} [Field K] (α β γ : K) (c : ℕ)
    (hα : IsIntegral ℤ ((c : K) * α)) (hβ : IsIntegral ℤ ((c : K) * β))
    (hγ : IsIntegral ℤ ((c : K) * γ)) (L k m j1 j2 : ℕ) (hj1 : j1 < L) (hj2 : j2 < L) :
    IsIntegral ℤ ((c : K) ^ (k + 2 * (L - 1) * m) * (((j1 : K) + (j2 : K) * β) ^ k *
      α ^ (j1 * m) * γ ^ (j2 * m))) := by
  obtain ⟨a, b, he⟩ := gs_E_eq α β γ c L k m j1 j2 hj1 hj2
  rw [he]
  have hcast : ∀ t : ℕ, IsIntegral ℤ (t : K) := fun t => by
    simpa using (isIntegral_algebraMap (R := ℤ) (A := K) (x := (t : ℤ)))
  have hc := hcast c
  have hX : IsIntegral ℤ ((c : K) * ((j1 : K) + j2 * β)) := by
    rw [show (c : K) * ((j1 : K) + j2 * β) = j1 * c + j2 * (c * β) by ring]
    exact ((hcast j1).mul hc).add ((hcast j2).mul hβ)
  refine (((hX).pow k).mul
    (((hα.pow j1).mul (hc.pow a)).pow m)).mul (((hγ.pow j2).mul (hc.pow b)).pow m)

#print axioms gs_E_integral

lemma gs_E_house {K : Type*} [Field K] [NumberField K] (α β γ : K) (c : ℕ) (C : ℝ)
    (hC1 : 1 ≤ C) (hc : (c : ℝ) ≤ C) (hα : house α ≤ C) (hβ : house β ≤ C) (hγ : house γ ≤ C)
    (L k m j1 j2 : ℕ) (hj1 : j1 < L) (hj2 : j2 < L) :
    house ((c : K) ^ (k + 2 * (L - 1) * m) * (((j1 : K) + (j2 : K) * β) ^ k *
      α ^ (j1 * m) * γ ^ (j2 * m))) ≤ (2 * L * C ^ 2) ^ k * C ^ (4 * L * m) := by
  have hC0 : 0 ≤ C := by linarith
  have hX : house ((j1 : K) + (j2 : K) * β) ≤ 2 * L * C := by
    calc house ((j1 : K) + (j2 : K) * β) ≤ house (j1 : K) + house ((j2 : K) * β) :=
          house_add_le _ _
      _ = j1 + j2 * house β := by rw [gs_house_natCast, house_nat_mul]
      _ ≤ L * C + L * C := by
          have h1 : (j1 : ℝ) ≤ L := by exact_mod_cast hj1.le
          have h2 : (j2 : ℝ) ≤ L := by exact_mod_cast hj2.le
          have hL0 : (0 : ℝ) ≤ L := by positivity
          have : (j1 : ℝ) ≤ L * C := by nlinarith
          have : (j2 : ℝ) * house β ≤ L * C := by
            have := house_nonneg β
            have : (0 : ℝ) ≤ j2 := by positivity
            nlinarith
          linarith
      _ = 2 * L * C := by ring
  have hpowC : ∀ a b : ℕ, a ≤ b → C ^ a ≤ C ^ b := fun a b hab => pow_le_pow_right₀ hC1 hab
  set N := k + 2 * (L - 1) * m
  have e1 : house ((c : K) ^ N) ≤ C ^ (k + 2 * L * m) := by
    rw [house_pow, gs_house_natCast]
    refine (pow_le_pow_left₀ (Nat.cast_nonneg _) hc N).trans (hpowC _ _ ?_)
    exact Nat.add_le_add_left (Nat.mul_le_mul_right m (Nat.mul_le_mul_left 2 (Nat.sub_le L 1))) k
  have e2 : house (((j1 : K) + (j2 : K) * β) ^ k) ≤ (2 * L * C) ^ k :=
    (house_pow _ _).le.trans (pow_le_pow_left₀ (house_nonneg _) hX k)
  have e3 : house (α ^ (j1 * m)) ≤ C ^ (L * m) :=
    (house_pow _ _).le.trans ((pow_le_pow_left₀ (house_nonneg _) hα _).trans
      (hpowC _ _ (Nat.mul_le_mul_right _ hj1.le)))
  have e4 : house (γ ^ (j2 * m)) ≤ C ^ (L * m) :=
    (house_pow _ _).le.trans ((pow_le_pow_left₀ (house_nonneg _) hγ _).trans
      (hpowC _ _ (Nat.mul_le_mul_right _ hj2.le)))
  have r3 := mul_le_mul (mul_le_mul e2 e3 (house_nonneg _) (by positivity)) e4 (house_nonneg _)
    (by positivity)
  have r4 := mul_le_mul e1 r3
    (mul_nonneg (mul_nonneg (house_nonneg _) (house_nonneg _)) (house_nonneg _)) (by positivity)
  calc house ((c : K) ^ N * (((j1 : K) + (j2 : K) * β) ^ k * α ^ (j1 * m) * γ ^ (j2 * m)))
      ≤ house ((c : K) ^ N) * (house (((j1 : K) + (j2 : K) * β) ^ k) *
          house (α ^ (j1 * m)) * house (γ ^ (j2 * m))) := by
        refine (house_mul_le _ _).trans ?_
        apply mul_le_mul_of_nonneg_left _ (house_nonneg _)
        refine (house_mul_le _ _).trans ?_
        apply mul_le_mul_of_nonneg_right _ (house_nonneg _)
        exact house_mul_le _ _
    _ ≤ C ^ (k + 2 * L * m) * ((2 * L * C) ^ k * C ^ (L * m) * C ^ (L * m)) := r4
    _ = (2 * L * C ^ 2) ^ k * C ^ (4 * L * m) := by ring

#print axioms gs_E_house

lemma gs_exponent_ineq (d h s L n r : ℕ) (hd : 1 ≤ d) (hh : h = 8 * d + 8) (hL : L = 2 * h * s)
    (hn : n = 2 * h * s ^ 2) (hs1 : 16 * d * h ≤ s) (hr1 : n ≤ r) :
    (r + 2 * L * h) + r + 4 * r + (4 + (6 + 4 * n + 4 * L * h) + h * s ^ 2) +
      (4 + 4 * r + 4 * L * h + (6 + 4 * n + 4 * L * h)) * (d - 1) < r * h := by
  obtain ⟨e, rfl⟩ : ∃ e, d = e + 1 := ⟨d - 1, by omega⟩
  simp only [Nat.add_sub_cancel]
  subst hh hL hn
  -- r * (8e+16) vs the rest; isolate r
  have h1 : (2 * (8 * (e + 1) + 8) * s ^ 2) * (4 * e + 10) ≤ r * (4 * e + 10) :=
    Nat.mul_le_mul_right _ hr1
  have h2 : 16 * (e + 1) * (8 * (e + 1) + 8) * s ≤ s * s := Nat.mul_le_mul_right _ hs1
  have hs0 : 1 ≤ s := by nlinarith
  nlinarith [h1, h2, hs0, Nat.zero_le e, Nat.zero_le r, Nat.zero_le s]

#print axioms gs_exponent_ineq

lemma gs_final_ineq (d h s L n r : ℕ) (T : ℝ) (hd : 1 ≤ d) (hh : h = 8 * d + 8)
    (hL : L = 2 * h * s) (hn : n = 2 * h * s ^ 2) (hs1 : 16 * d * h ≤ s) (hT1 : 1 ≤ T)
    (hTs : T ≤ s) (hexp : Real.exp (4 * h * T) ≤ s) (hr1 : n ≤ r) (hr2 : r ≤ L ^ 2) :
    T ^ (r + 2 * L * h) * T ^ r * (r.factorial : ℝ) *
      ((L : ℝ) ^ 2 * (T ^ 2 * (L : ℝ) ^ 2 * ((2 * L * T ^ 2) ^ n * T ^ (4 * L * h))) *
        Real.exp (L * T * (h * (s + 1)))) / (s : ℝ) ^ (r * h) *
      ((L : ℝ) ^ 2 * (2 * L * T ^ 2) ^ r * T ^ (4 * L * h) *
        (T ^ 2 * (L : ℝ) ^ 2 * ((2 * L * T ^ 2) ^ n * T ^ (4 * L * h)))) ^ (d - 1) < 1 := by
  set S : ℝ := (s : ℝ) with hSdef
  have hh1 : 16 ≤ h := by omega
  have hs256 : 256 ≤ s := by nlinarith
  have hS1 : (1 : ℝ) < S := by simp only [hSdef]; exact_mod_cast (by omega : 1 < s)
  have hS0 : (0 : ℝ) ≤ S := by positivity
  have hT0 : (0 : ℝ) ≤ T := by linarith
  -- basic size facts
  have hLs : (L : ℝ) ≤ S ^ 2 := by
    have : L ≤ s ^ 2 := by
      rw [hL, sq]; exact Nat.mul_le_mul_right _ (by nlinarith)
    rw [hSdef]; exact_mod_cast this
  have h2L : (2 * L : ℝ) ≤ S ^ 2 := by
    have : 2 * L ≤ s ^ 2 := by
      rw [hL, sq]; nlinarith
    rw [hSdef]; exact_mod_cast this
  have hL2 : (L : ℝ) ^ 2 ≤ S ^ 4 := by
    calc (L : ℝ) ^ 2 ≤ (S ^ 2) ^ 2 := by gcongr
      _ = S ^ 4 := by ring
  have h2LT : (2 * L * T ^ 2 : ℝ) ≤ S ^ 4 := by
    calc (2 * L * T ^ 2 : ℝ) ≤ S ^ 2 * S ^ 2 := by gcongr
      _ = S ^ 4 := by ring
  have hfact : (r.factorial : ℝ) ≤ S ^ (4 * r) := by
    have h1 : r.factorial ≤ r ^ r := Nat.factorial_le_pow r
    have h2 : r ^ r ≤ (s ^ 4) ^ r := by
      apply Nat.pow_le_pow_left
      calc r ≤ L ^ 2 := hr2
        _ ≤ (s ^ 2) ^ 2 := by
          apply Nat.pow_le_pow_left
          rw [hL, sq]; exact Nat.mul_le_mul_right _ (by nlinarith)
        _ = s ^ 4 := by ring
    have : r.factorial ≤ s ^ (4 * r) := by
      calc r.factorial ≤ (s ^ 4) ^ r := h1.trans h2
        _ = s ^ (4 * r) := by rw [← pow_mul]
    rw [hSdef]; exact_mod_cast this
  have hTpow : ∀ k : ℕ, T ^ k ≤ S ^ k := fun k => pow_le_pow_left₀ hT0 hTs k
  have hHη : T ^ 2 * (L : ℝ) ^ 2 * ((2 * L * T ^ 2) ^ n * T ^ (4 * L * h)) ≤
      S ^ (6 + 4 * n + 4 * L * h) := by
    calc T ^ 2 * (L : ℝ) ^ 2 * ((2 * L * T ^ 2) ^ n * T ^ (4 * L * h))
        ≤ S ^ 2 * S ^ 4 * ((S ^ 4) ^ n * S ^ (4 * L * h)) := by
          gcongr
      _ = S ^ (6 + 4 * n + 4 * L * h) := by
          rw [← pow_mul]; ring
  have hexpb : Real.exp (L * T * (h * (s + 1))) ≤ S ^ (h * s ^ 2) := by
    have hlog : 4 * h * T ≤ Real.log S := by
      have := Real.log_le_log (Real.exp_pos _) hexp
      rwa [Real.log_exp] at this
    have hkey : (L : ℝ) * T * (h * (s + 1)) ≤ ((h * s ^ 2 : ℕ) : ℝ) * Real.log S := by
      have hLr : (L : ℝ) = 2 * h * s := by rw [hL]; push_cast; ring
      rw [hLr]
      push_cast
      have hs1' : (s : ℝ) + 1 ≤ 2 * s := by
        have : (1 : ℝ) ≤ s := by exact_mod_cast (by omega : 1 ≤ s)
        linarith
      have hh0 : (0 : ℝ) ≤ h := by positivity
      have hs0' : (0 : ℝ) ≤ s := by positivity
      calc 2 * (h : ℝ) * s * T * (h * (s + 1)) ≤ 2 * (h : ℝ) * s * T * (h * (2 * s)) := by
            gcongr
        _ = (h : ℝ) * s ^ 2 * (4 * h * T) := by ring
        _ ≤ (h : ℝ) * s ^ 2 * Real.log S := by gcongr
    calc Real.exp (L * T * (h * (s + 1))) ≤ Real.exp (((h * s ^ 2 : ℕ) : ℝ) * Real.log S) :=
          Real.exp_le_exp.2 hkey
      _ = S ^ (h * s ^ 2) := by
          rw [Real.exp_nat_mul, Real.exp_log (by linarith)]
  have hhouse : (L : ℝ) ^ 2 * (2 * L * T ^ 2) ^ r * T ^ (4 * L * h) *
      (T ^ 2 * (L : ℝ) ^ 2 * ((2 * L * T ^ 2) ^ n * T ^ (4 * L * h))) ≤
      S ^ (4 + 4 * r + 4 * L * h + (6 + 4 * n + 4 * L * h)) := by
    calc (L : ℝ) ^ 2 * (2 * L * T ^ 2) ^ r * T ^ (4 * L * h) *
          (T ^ 2 * (L : ℝ) ^ 2 * ((2 * L * T ^ 2) ^ n * T ^ (4 * L * h)))
        ≤ S ^ 4 * (S ^ 4) ^ r * S ^ (4 * L * h) * S ^ (6 + 4 * n + 4 * L * h) := by
          gcongr
      _ = S ^ (4 + 4 * r + 4 * L * h + (6 + 4 * n + 4 * L * h)) := by
          rw [← pow_mul]; ring
  have hE := gs_exponent_ineq d h s L n r hd hh hL hn hs1 hr1
  have hSpos : (0 : ℝ) < S ^ (r * h) := by positivity
  calc T ^ (r + 2 * L * h) * T ^ r * (r.factorial : ℝ) *
      ((L : ℝ) ^ 2 * (T ^ 2 * (L : ℝ) ^ 2 * ((2 * L * T ^ 2) ^ n * T ^ (4 * L * h))) *
        Real.exp (L * T * (h * (s + 1)))) / (s : ℝ) ^ (r * h) *
      ((L : ℝ) ^ 2 * (2 * L * T ^ 2) ^ r * T ^ (4 * L * h) *
        (T ^ 2 * (L : ℝ) ^ 2 * ((2 * L * T ^ 2) ^ n * T ^ (4 * L * h)))) ^ (d - 1)
      ≤ S ^ (r + 2 * L * h) * S ^ r * S ^ (4 * r) *
      (S ^ 4 * S ^ (6 + 4 * n + 4 * L * h) * S ^ (h * s ^ 2)) / S ^ (r * h) *
      (S ^ (4 + 4 * r + 4 * L * h + (6 + 4 * n + 4 * L * h))) ^ (d - 1) := by
        gcongr
    _ = S ^ ((r + 2 * L * h) + r + 4 * r + (4 + (6 + 4 * n + 4 * L * h) + h * s ^ 2) +
      (4 + 4 * r + 4 * L * h + (6 + 4 * n + 4 * L * h)) * (d - 1)) / S ^ (r * h) := by
        rw [div_mul_eq_mul_div, ← pow_mul]; ring
    _ < 1 := by
        rw [div_lt_one hSpos]
        exact pow_lt_pow_right₀ hS1 hE

#print axioms gs_final_ineq

set_option maxHeartbeats 1000000 in
theorem gs_main {K : Type*} [Field K] [NumberField K] (σ : K →+* ℂ) (α β γ : K) (l : ℂ)
    (hl0 : l ≠ 0) (hα : σ α = exp l) (hγ : σ γ = exp (σ β * l)) (hβ : ∀ q : ℚ, σ β ≠ q) :
    False := by
  classical
  set d := Module.finrank ℚ K with hd_def
  have hd : 1 ≤ d := Module.finrank_pos
  set b := σ β with hb_def
  -- denominators
  have halg : ∀ x : K, IsAlgebraic ℤ x := fun x =>
    (IsFractionRing.isAlgebraic_iff ℤ ℚ K).mpr (.of_finite ℚ x)
  set c : ℕ := Algebra.natDenominator α * Algebra.natDenominator β * Algebra.natDenominator γ
    with hc_def
  have hc0 : c ≠ 0 := by
    simp only [hc_def]
    exact mul_ne_zero (mul_ne_zero ((halg α).natDenominator_ne_zero)
      ((halg β).natDenominator_ne_zero)) ((halg γ).natDenominator_ne_zero)
  have hcast : ∀ t : ℕ, IsIntegral ℤ (t : K) := fun t => by
    simpa using (isIntegral_algebraMap (R := ℤ) (A := K) (x := (t : ℤ)))
  have hden : ∀ x : K, IsIntegral ℤ ((Algebra.natDenominator x : K) * x) := fun x => by
    have := Algebra.isIntegral_natDenominator_smul x
    rwa [nsmul_eq_mul] at this
  have hcα : IsIntegral ℤ ((c : K) * α) := by
    have : (c : K) * α = ((Algebra.natDenominator β * Algebra.natDenominator γ : ℕ) : K) *
        ((Algebra.natDenominator α : K) * α) := by simp only [hc_def]; push_cast; ring
    rw [this]; exact (hcast _).mul (hden α)
  have hcβ : IsIntegral ℤ ((c : K) * β) := by
    have : (c : K) * β = ((Algebra.natDenominator α * Algebra.natDenominator γ : ℕ) : K) *
        ((Algebra.natDenominator β : K) * β) := by simp only [hc_def]; push_cast; ring
    rw [this]; exact (hcast _).mul (hden β)
  have hcγ : IsIntegral ℤ ((c : K) * γ) := by
    have : (c : K) * γ = ((Algebra.natDenominator α * Algebra.natDenominator β : ℕ) : K) *
        ((Algebra.natDenominator γ : K) * γ) := by simp only [hc_def]; push_cast; ring
    rw [this]; exact (hcast _).mul (hden γ)
  -- the constant
  obtain ⟨c1, hc1⟩ := gs_siegel_const K
  set T : ℝ := max (max (max 1 (c : ℝ)) (max (house α) (max (house β) (house γ))))
    (max |c1| (max ‖l‖⁻¹ ((1 + ‖b‖) * ‖l‖))) with hT_def
  have hT1 : 1 ≤ T := by simp [T]
  have hTc : (c : ℝ) ≤ T := by simp [T]
  have hTα : house α ≤ T := by simp [T]
  have hTβ : house β ≤ T := by simp [T]
  have hTγ : house γ ≤ T := by simp [T]
  have hTc1 : |c1| ≤ T := by simp [T]
  have hTl : ‖l‖⁻¹ ≤ T := by simp [T]
  have hTb : (1 + ‖b‖) * ‖l‖ ≤ T := by simp [T]
  have hT0 : 0 ≤ T := by linarith
  -- parameters
  set h : ℕ := 8 * d + 8 with hh_def
  set s : ℕ := ⌈Real.exp (4 * h * T)⌉₊ + 16 * d * h with hs_def
  set L : ℕ := 2 * h * s with hL_def
  set n : ℕ := 2 * h * s ^ 2 with hn_def
  have hh0 : 0 < h := by omega
  have hs16 : 16 * d * h ≤ s := by omega
  have hexps : Real.exp (4 * h * T) ≤ s := by
    have := Nat.le_ceil (Real.exp (4 * h * T))
    have h2 : ((⌈Real.exp (4 * h * T)⌉₊ : ℕ) : ℝ) ≤ s := by
      simp only [hs_def]; push_cast; linarith [(by positivity : (0:ℝ) ≤ 16 * d * h)]
    linarith
  have hTs : T ≤ s := by
    have h1 : T ≤ Real.exp T := by linarith [Real.add_one_le_exp T]
    have h2 : Real.exp T ≤ Real.exp (4 * h * T) := by
      apply Real.exp_le_exp.2
      have : (1 : ℝ) ≤ h := by exact_mod_cast hh0
      nlinarith
    linarith
  have hs0 : 0 < s := by nlinarith
  have hL0 : 0 < L := by positivity
  have hn0 : 0 < n := by positivity
  have hLn : L * L = 2 * (n * h) := by simp only [hL_def, hn_def]; ring
  -- the matrix of the linear system
  let E : ℕ → ℕ → Fin L × Fin L → K := fun k m j =>
    (c : K) ^ (k + 2 * (L - 1) * m) * ((((j.1 : ℕ) : K) + ((j.2 : ℕ) : K) * β) ^ k *
      α ^ ((j.1 : ℕ) * m) * γ ^ ((j.2 : ℕ) * m))
  have hEint : ∀ k m j, IsIntegral ℤ (E k m j) := fun k m j =>
    gs_E_integral α β γ c hcα hcβ hcγ L k m j.1 j.2 j.1.2 j.2.2
  have hEhouse : ∀ k m j, house (E k m j) ≤ (2 * L * T ^ 2) ^ k * T ^ (4 * L * m) :=
    fun k m j => gs_E_house α β γ c T hT1 hTc hTα hTβ hTγ L k m j.1 j.2 j.1.2 j.2.2
  let a : Matrix (Fin n × Fin h) (Fin L × Fin L) (𝓞 K) := fun i j =>
    ⟨E i.1 ((i.2 : ℕ) + 1) j, hEint _ _ _⟩
  have ha0 : a ≠ 0 := by
    intro h0
    have h1 := congrFun (congrFun h0 (⟨0, hn0⟩, ⟨0, hh0⟩)) (⟨0, hL0⟩, ⟨0, hL0⟩)
    have h2 : E 0 1 (⟨0, hL0⟩, ⟨0, hL0⟩) = 0 := by
      have := congrArg (fun t : 𝓞 K => (t : K)) h1
      exact this
    simp [E, hc0] at h2
  have hcardι : Fintype.card (Fin n × Fin h) = n * h := by simp
  have hcardκ : Fintype.card (Fin L × Fin L) = L * L := by simp
  set A : ℝ := (2 * L * T ^ 2) ^ n * T ^ (4 * L * h) with hA_def
  have h2LT : 1 ≤ (2 * L * T ^ 2 : ℝ) := by
    have : (1 : ℝ) ≤ L := by exact_mod_cast hL0
    have : (1 : ℝ) ≤ T ^ 2 := one_le_pow₀ hT1
    nlinarith
  have habs : ∀ i j, house (algebraMap (𝓞 K) K (a i j)) ≤ A := by
    intro i j
    refine (hEhouse i.1 ((i.2 : ℕ) + 1) j).trans ?_
    have hi1 : (i.1 : ℕ) ≤ n := i.1.2.le
    have hi2 : (i.2 : ℕ) + 1 ≤ h := i.2.2
    rw [hA_def]
    exact mul_le_mul (pow_le_pow_right₀ h2LT hi1)
      (pow_le_pow_right₀ hT1 (Nat.mul_le_mul_left _ hi2)) (by positivity) (by positivity)
  obtain ⟨ξ, hξ0, hξa, hξh⟩ := hc1 _ _ a ha0 A habs (by rw [hcardι]; positivity)
    (by rw [hcardι, hcardκ]; nlinarith)
  rw [hcardι, hcardκ] at hξh
  have hexp1 : ((n * h : ℕ) : ℝ) / (((L * L : ℕ) : ℝ) - ((n * h : ℕ) : ℝ)) = 1 := by
    rw [hLn]; push_cast
    have : (0 : ℝ) < n * h := by positivity
    field_simp
    ring
  rw [hexp1, Real.rpow_one] at hξh
  set Hη : ℝ := T ^ 2 * (L : ℝ) ^ 2 * ((2 * L * T ^ 2) ^ n * T ^ (4 * L * h)) with hHη_def
  have hA0 : 0 ≤ A := by positivity
  have hηb : ∀ j, house (ξ j : K) ≤ Hη := by
    intro j
    refine (hξh j).trans ?_
    have hc1sq : c1 * c1 ≤ T ^ 2 := by
      have : c1 * c1 = |c1| ^ 2 := by rw [sq_abs]; ring
      rw [this]; exact pow_le_pow_left₀ (abs_nonneg _) hTc1 2
    calc c1 * (c1 * ((L * L : ℕ) : ℝ) * A) = (c1 * c1) * (((L * L : ℕ) : ℝ) * A) := by ring
      _ ≤ T ^ 2 * (((L * L : ℕ) : ℝ) * A) := by gcongr
      _ = Hη := by simp only [hHη_def, hA_def]; push_cast; ring
  -- the auxiliary function
  let η : Fin L × Fin L → K := fun j => (ξ j : K)
  let w : Fin L × Fin L → ℂ := fun j => σ (η j)
  let μ : Fin L × Fin L → ℂ := fun j => (((j.1 : ℕ) : ℂ) + ((j.2 : ℕ) : ℂ) * b) * l
  let F : ℂ → ℂ := fun z => ∑ j, w j * exp (μ j * z)
  let Sv : ℕ → ℕ → K := fun k m => ∑ j, η j * ((((j.1 : ℕ) : K) + ((j.2 : ℕ) : K) * β) ^ k *
      α ^ ((j.1 : ℕ) * m) * γ ^ ((j.2 : ℕ) * m))
  have hFan : ∀ z, AnalyticAt ℂ F z := gs_expsum_analytic w μ
  have hderiv : ∀ k m : ℕ, iteratedDeriv k F (m : ℂ) = l ^ k * σ (Sv k m) := by
    intro k m
    rw [gs_iteratedDeriv_expsum w μ k]
    simp only [Sv, map_sum, Finset.mul_sum]
    apply Finset.sum_congr rfl
    intro j _
    have hμk : μ j ^ k = l ^ k * (((j.1 : ℕ) : ℂ) + ((j.2 : ℕ) : ℂ) * b) ^ k := by
      simp only [μ]; rw [mul_pow]; ring
    have hexp : μ j * (m : ℂ) =
        (((j.1 : ℕ) * m : ℕ) : ℂ) * l + (((j.2 : ℕ) * m : ℕ) : ℂ) * (b * l) := by
      simp only [μ]; push_cast; ring
    rw [hμk, hexp, Complex.exp_add, Complex.exp_nat_mul, Complex.exp_nat_mul]
    simp only [w, map_mul, map_pow, map_add, map_natCast, hα, hγ, hb_def]
    ring
  have hrow : ∀ k m, (c : K) ^ (k + 2 * (L - 1) * m) * Sv k m = ∑ j, E k m j * η j := by
    intro k m
    simp only [Sv, E, Finset.mul_sum]
    apply Finset.sum_congr rfl
    intro j _
    ring
  have hvanish : ∀ k < n, ∀ m < h, Sv k (m + 1) = 0 := by
    intro k hk m hm
    have h1 := congrArg (algebraMap (𝓞 K) K) (congrFun hξa (⟨k, hk⟩, ⟨m, hm⟩))
    have h2 : ∑ j, E k (m + 1) j * η j = 0 := by
      simp only [Matrix.mulVec, dotProduct, map_sum, map_mul, map_zero, Pi.zero_apply] at h1
      exact h1
    rw [← hrow] at h2
    exact (mul_eq_zero.1 h2).resolve_left (pow_ne_zero _ (Nat.cast_ne_zero.2 hc0))
  let pts : Finset ℂ := (Finset.range h).image (fun m : ℕ => (((m + 1 : ℕ)) : ℂ))
  have hpts : ∀ p ∈ pts, ∃ m < h, p = (((m + 1 : ℕ)) : ℂ) := by
    intro p hp
    obtain ⟨m, hm, rfl⟩ := Finset.mem_image.1 hp
    exact ⟨m, Finset.mem_range.1 hm, rfl⟩
  have hvanF : ∀ k < n, ∀ p ∈ pts, iteratedDeriv k F p = 0 := by
    intro k hk p hp
    obtain ⟨m, hm, rfl⟩ := hpts p hp
    rw [hderiv, hvanish k hk m hm, map_zero, mul_zero]
  -- the exponents are distinct
  have hμ : Function.Injective μ := by
    intro j j' hjj
    simp only [μ] at hjj
    have h1 := mul_right_cancel₀ hl0 hjj
    by_cases h2 : (j.2 : ℕ) = (j'.2 : ℕ)
    · rw [h2] at h1
      have h3 : ((j.1 : ℕ) : ℂ) = ((j'.1 : ℕ) : ℂ) := by linear_combination h1
      have h4 : (j.1 : ℕ) = (j'.1 : ℕ) := by exact_mod_cast h3
      exact Prod.ext (Fin.ext h4) (Fin.ext h2)
    · exfalso
      apply hβ (((j'.1 : ℕ) - (j.1 : ℕ) : ℚ) / ((j.2 : ℕ) - (j'.2 : ℕ) : ℚ))
      have h5 : ((j.2 : ℕ) : ℂ) - ((j'.2 : ℕ) : ℂ) ≠ 0 := by
        rw [sub_ne_zero]; exact_mod_cast h2
      push_cast
      rw [eq_div_iff h5]
      linear_combination h1
  have hw : w ≠ 0 := by
    intro hw0
    apply hξ0
    funext j
    have h1 : σ (η j) = 0 := congrFun hw0 j
    have h2 : η j = 0 := by simpa using h1
    exact RingOfIntegers.ext (by simpa [η] using h2)
  obtain ⟨k₀, hk₀, hk₀ne⟩ := gs_expsum_deriv_ne_zero w μ hμ hw 1
  have h1pts : (1 : ℂ) ∈ pts := Finset.mem_image.2 ⟨0, Finset.mem_range.2 hh0, by simp⟩
  have hex : ∃ k, ∃ p ∈ pts, iteratedDeriv k F p ≠ 0 := by
    refine ⟨k₀, 1, h1pts, ?_⟩
    rw [gs_iteratedDeriv_expsum w μ k₀]
    exact hk₀ne
  set r := Nat.find hex with hr_def
  have hrk₀ : r ≤ k₀ := Nat.find_min' hex ⟨1, h1pts, by rw [gs_iteratedDeriv_expsum w μ k₀]; exact hk₀ne⟩
  have hrL : r ≤ L ^ 2 := by rw [hcardκ] at hk₀; rw [sq]; omega
  have hrmin : ∀ p ∈ pts, ∀ k < r, iteratedDeriv k F p = 0 := by
    intro p hp k hk
    have := Nat.find_min hex hk
    push Not at this
    exact this p hp
  obtain ⟨p₀, hp₀, hp₀ne⟩ := Nat.find_spec hex
  have hrn : n ≤ r := by
    by_contra hcon
    exact hp₀ne (hvanF r (by omega) p₀ hp₀)
  obtain ⟨m₀, hm₀, rfl⟩ := hpts p₀ hp₀
  set M₀ : ℕ := m₀ + 1 with hM₀_def
  have hM₀h : M₀ ≤ h := by omega
  -- upper bound from the Schwarz lemma
  have hcardpts : pts.card = h := by
    rw [Finset.card_image_of_injective _ (fun x y hxy => by
      have : ((x + 1 : ℕ) : ℂ) = ((y + 1 : ℕ) : ℂ) := hxy
      have := Nat.cast_injective this
      omega)]
    simp
  have hptsnorm : ∀ p ∈ pts, ‖p‖ ≤ h := by
    intro p hp
    obtain ⟨m, hm, rfl⟩ := hpts p hp
    rw [Complex.norm_natCast]
    exact_mod_cast (by omega : m + 1 ≤ h)
  set R : ℝ := h * (s + 1) with hR_def
  set δ : ℝ := h * s with hδ_def
  have hhR : (1 : ℝ) ≤ h := by exact_mod_cast hh0
  have hsR : (1 : ℝ) ≤ s := by exact_mod_cast hs0
  have hR : ∀ p ∈ pts, ‖p‖ < R := by
    intro p hp
    refine lt_of_le_of_lt (hptsnorm p hp) ?_
    simp only [hR_def]; nlinarith
  have hδpos : 0 < δ := by positivity
  have hδ' : ∀ z : ℂ, ‖z‖ = R → ∀ p ∈ pts, δ ≤ ‖z - p‖ := by
    intro z hz p hp
    have h1 := norm_sub_norm_le z p
    have h2 := hptsnorm p hp
    simp only [hδ_def]
    rw [hz, hR_def] at h1
    nlinarith
  have hwle : ∀ j, ‖w j‖ ≤ Hη := fun j =>
    (norm_embedding_le_house (η j) σ).trans (hηb j)
  have hμle : ∀ j, ‖μ j‖ ≤ L * T := by
    intro j
    simp only [μ]
    rw [norm_mul]
    have h1 : ‖((j.1 : ℕ) : ℂ) + ((j.2 : ℕ) : ℂ) * b‖ ≤ L * (1 + ‖b‖) := by
      refine (norm_add_le _ _).trans ?_
      rw [norm_mul, Complex.norm_natCast, Complex.norm_natCast]
      have hj1 : ((j.1 : ℕ) : ℝ) ≤ L := by exact_mod_cast j.1.2.le
      have hj2 : ((j.2 : ℕ) : ℝ) ≤ L := by exact_mod_cast j.2.2.le
      have := norm_nonneg b
      nlinarith
    calc ‖((j.1 : ℕ) : ℂ) + ((j.2 : ℕ) : ℂ) * b‖ * ‖l‖ ≤ (L * (1 + ‖b‖)) * ‖l‖ := by
          gcongr
      _ = L * ((1 + ‖b‖) * ‖l‖) := by ring
      _ ≤ L * T := by gcongr
  set Mb : ℝ := (L : ℝ) ^ 2 * Hη * Real.exp (L * T * (h * (s + 1))) with hMb_def
  have hM : ∀ z : ℂ, ‖z‖ = R → ‖F z‖ ≤ Mb := by
    intro z hz
    have := gs_expsum_norm_le w μ Hη (L * T) hwle hμle z
    rw [hcardκ, hz] at this
    refine this.trans (le_of_eq ?_)
    simp only [hMb_def, hR_def]; push_cast; ring
  have hS := gs_schwarz F hFan pts r _ hp₀ hrmin R hR Mb δ hM hδpos hδ'
  rw [hcardpts] at hS
  have hprod : ∏ p ∈ pts.erase ((M₀ : ℕ) : ℂ), ‖((M₀ : ℕ) : ℂ) - p‖ ^ r ≤ (h : ℝ) ^ (r * h) := by
    calc ∏ p ∈ pts.erase ((M₀ : ℕ) : ℂ), ‖((M₀ : ℕ) : ℂ) - p‖ ^ r
        ≤ ∏ p ∈ pts.erase ((M₀ : ℕ) : ℂ), (h : ℝ) ^ r := by
          gcongr with p hp
          obtain ⟨m, hm, rfl⟩ := hpts p (Finset.mem_of_mem_erase hp)
          have he : ((M₀ : ℕ) : ℂ) - ((m + 1 : ℕ) : ℂ) =
              (((M₀ : ℝ) - ((m + 1 : ℕ) : ℝ) : ℝ) : ℂ) := by push_cast; ring
          rw [he, Complex.norm_real, Real.norm_eq_abs, abs_le]
          have h1 : (M₀ : ℝ) ≤ h := by exact_mod_cast hM₀h
          have h2 : ((m + 1 : ℕ) : ℝ) ≤ h := by exact_mod_cast (by omega : m + 1 ≤ h)
          have h3 : (0 : ℝ) ≤ M₀ := by positivity
          have h4 : (0 : ℝ) ≤ ((m + 1 : ℕ) : ℝ) := by positivity
          constructor <;> linarith
      _ = ((h : ℝ) ^ r) ^ (h - 1) := by
          rw [Finset.prod_const, Finset.card_erase_of_mem hp₀, hcardpts]
      _ ≤ ((h : ℝ) ^ r) ^ h := pow_le_pow_right₀ (one_le_pow₀ hhR) (Nat.sub_le h 1)
      _ = (h : ℝ) ^ (r * h) := by rw [← pow_mul]
  have hupper : ‖iteratedDeriv r F ((M₀ : ℕ) : ℂ)‖ ≤ r.factorial * Mb / (s : ℝ) ^ (r * h) := by
    refine hS.trans ?_
    have hMb0 : 0 ≤ Mb := by positivity
    calc (r.factorial : ℝ) * (∏ p ∈ pts.erase ((M₀ : ℕ) : ℂ), ‖((M₀ : ℕ) : ℂ) - p‖ ^ r) *
          (Mb / δ ^ (r * h))
        ≤ (r.factorial : ℝ) * (h : ℝ) ^ (r * h) * (Mb / δ ^ (r * h)) := by gcongr
      _ = r.factorial * Mb / (s : ℝ) ^ (r * h) := by
          simp only [hδ_def]
          rw [mul_pow]
          field_simp
  -- lower bound from the norm (Liouville)
  set ρ : K := (c : K) ^ (r + 2 * (L - 1) * M₀) * Sv r M₀ with hρ_def
  have hρint : IsIntegral ℤ ρ := by
    rw [hρ_def, hrow]
    exact IsIntegral.sum _ (fun j _ => (hEint r M₀ j).mul (ξ j).isIntegral_coe)
  have hderivM := hderiv r M₀
  have hSv0 : Sv r M₀ ≠ 0 := by
    intro h0
    apply hp₀ne
    rw [hderivM, h0, map_zero, mul_zero]
  have hρ0 : ρ ≠ 0 := mul_ne_zero (pow_ne_zero _ (Nat.cast_ne_zero.2 hc0)) hSv0
  have hli := gs_liouville σ ρ hρint hρ0
  have hl0' : 0 < ‖l‖ := norm_pos_iff.2 hl0
  have hσρ : ‖σ ρ‖ ≤ T ^ (r + 2 * L * h) * T ^ r * (r.factorial : ℝ) * Mb / (s : ℝ) ^ (r * h) := by
    have hσS : ‖σ (Sv r M₀)‖ = ‖iteratedDeriv r F ((M₀ : ℕ) : ℂ)‖ * (‖l‖⁻¹) ^ r := by
      rw [hderivM, norm_mul, norm_pow, inv_pow]
      field_simp
    have hcT : (c : ℝ) ^ (r + 2 * (L - 1) * M₀) ≤ T ^ (r + 2 * L * h) := by
      refine (pow_le_pow_left₀ (Nat.cast_nonneg _) hTc _).trans (pow_le_pow_right₀ hT1 ?_)
      have h1 : (L - 1) * M₀ ≤ L * h := Nat.mul_le_mul (Nat.sub_le L 1) hM₀h
      have h2 : 2 * (L - 1) * M₀ ≤ 2 * L * h := by
        rw [mul_assoc, mul_assoc]; exact Nat.mul_le_mul_left 2 h1
      omega
    have hlT : (‖l‖⁻¹) ^ r ≤ T ^ r := pow_le_pow_left₀ (by positivity) hTl r
    rw [hρ_def, map_mul, map_pow, map_natCast, norm_mul, norm_pow, Complex.norm_natCast, hσS]
    calc (c : ℝ) ^ (r + 2 * (L - 1) * M₀) * (‖iteratedDeriv r F ((M₀ : ℕ) : ℂ)‖ * (‖l‖⁻¹) ^ r)
        ≤ T ^ (r + 2 * L * h) * ((r.factorial * Mb / (s : ℝ) ^ (r * h)) * T ^ r) := by
          gcongr
      _ = T ^ (r + 2 * L * h) * T ^ r * (r.factorial : ℝ) * Mb / (s : ℝ) ^ (r * h) := by ring
  have hhouseρ : house ρ ≤ (L : ℝ) ^ 2 * (2 * L * T ^ 2) ^ r * T ^ (4 * L * h) * Hη := by
    rw [hρ_def, hrow]
    refine (house_sum_le_sum_house _ _).trans ?_
    calc ∑ j, house (E r M₀ j * η j) ≤ ∑ _j : Fin L × Fin L,
          (2 * L * T ^ 2) ^ r * T ^ (4 * L * h) * Hη := by
          apply Finset.sum_le_sum
          intro j _
          refine (house_mul_le _ _).trans ?_
          apply mul_le_mul _ (hηb j) (house_nonneg _) (by positivity)
          refine (hEhouse r M₀ j).trans ?_
          gcongr
      _ = (L : ℝ) ^ 2 * (2 * L * T ^ 2) ^ r * T ^ (4 * L * h) * Hη := by
          rw [Finset.sum_const, Finset.card_univ, hcardκ, nsmul_eq_mul]; push_cast; ring
  have hfin := gs_final_ineq d h s L n r T hd hh_def hL_def hn_def hs16 hT1 hTs hexps hrn hrL
  have hX1 : 0 ≤ T ^ (r + 2 * L * h) * T ^ r * (r.factorial : ℝ) * Mb / (s : ℝ) ^ (r * h) := by
    positivity
  have := calc (1 : ℝ) ≤ ‖σ ρ‖ * house ρ ^ (d - 1) := hli
    _ ≤ (T ^ (r + 2 * L * h) * T ^ r * (r.factorial : ℝ) * Mb / (s : ℝ) ^ (r * h)) *
        ((L : ℝ) ^ 2 * (2 * L * T ^ 2) ^ r * T ^ (4 * L * h) * Hη) ^ (d - 1) := by
        apply mul_le_mul hσρ (pow_le_pow_left₀ (house_nonneg _) hhouseρ _)
          (pow_nonneg (house_nonneg _) _) hX1
  linarith

#print axioms gs_main

end GelfondSchneiderHelpers

/-- The Gelfond-Schneider theorem (1934): let `a` and `b` be algebraic numbers, with `a` not 0
or 1 and `b` not a fraction. Then every value of `a ^ b = exp (b * log a)` is transcendental:
for every complex number `l` whose exponential is `a`, the number `exp (b * l)` is a root of no
nonzero polynomial with rational (equivalently, whole-number) coefficients. -/
theorem gelfond_schneider_transcendental (a b : ℂ)
    (ha : IsAlgebraic ℚ a) (ha0 : a ≠ 0) (ha1 : a ≠ 1)
    (hb : IsAlgebraic ℚ b) (hbq : ∀ q : ℚ, b ≠ (q : ℂ))
    (l : ℂ) (hl : Complex.exp l = a) :
    Transcendental ℚ (Complex.exp (b * l)) := by
  intro hγ
  set γ := Complex.exp (b * l) with hγ_def
  let K := IntermediateField.adjoin ℚ ({a, b, γ} : Set ℂ)
  have hfin : FiniteDimensional ℚ K := by
    apply IntermediateField.finiteDimensional_adjoin
    intro x hx
    simp only [Set.mem_insert_iff, Set.mem_singleton_iff] at hx
    rcases hx with rfl | rfl | rfl
    · exact ha.isIntegral
    · exact hb.isIntegral
    · exact hγ.isIntegral
  have : NumberField K := { to_charZero := inferInstance, to_finiteDimensional := hfin }
  let σ : K →+* ℂ := (IntermediateField.val K : K →ₐ[ℚ] ℂ)
  let α' : K := ⟨a, IntermediateField.subset_adjoin ℚ _ (by simp)⟩
  let β' : K := ⟨b, IntermediateField.subset_adjoin ℚ _ (by simp)⟩
  let γ' : K := ⟨γ, IntermediateField.subset_adjoin ℚ _ (by simp)⟩
  have hl0 : l ≠ 0 := by
    rintro rfl
    apply ha1
    rw [← hl, Complex.exp_zero]
  exact gs_main σ α' β' γ' l hl0 hl.symm rfl hbq

/-- Siegel's lemma: take `M` linear equations in `N` unknowns, with `N > M`, whose whole-number
coefficients `a i j` all have size at most `A`, where `A ≥ 1`. Then the system has a nonzero
whole-number solution `x` whose every entry has size at most `(N * A) ^ (M / (N - M))`. -/
theorem siegel_lemma_small_whole_solution (M N : ℕ) (hNM : M < N)
    (a : Matrix (Fin M) (Fin N) ℤ) (A : ℝ) (hA : 1 ≤ A)
    (haA : ∀ i j, (|a i j| : ℝ) ≤ A) :
    ∃ x : Fin N → ℤ, x ≠ 0 ∧ a *ᵥ x = 0 ∧
      ∀ j, (|x j| : ℝ) ≤ ((N : ℝ) * A) ^ ((M : ℝ) / ((N : ℝ) - M)) := by
  rcases Nat.eq_zero_or_pos M with rfl | hM
  · refine ⟨fun _ => 1, ?_, ?_, ?_⟩
    · intro h
      have := congrFun h ⟨0, hNM⟩
      simp at this
    · ext i; exact i.elim0
    · intro j; simp
  · let _ := Matrix.seminormedAddCommGroup (m := Fin M) (n := Fin N) (α := ℤ)
    have hn : Fintype.card (Fin M) < Fintype.card (Fin N) := by simpa using hNM
    have hm : 0 < Fintype.card (Fin M) := by simpa using hM
    obtain ⟨x, hx0, hax, hxn⟩ := Int.Matrix.exists_ne_zero_int_vec_norm_le a hn hm
    simp only [Fintype.card_fin] at hxn
    have hnorm : ‖a‖ ≤ A := by
      rw [Matrix.norm_le_iff (by linarith)]
      intro i j
      simpa [Int.norm_eq_abs] using haA i j
    have hexp : 0 ≤ (M : ℝ) / ((N : ℝ) - M) := by
      apply div_nonneg (by positivity)
      have : (M : ℝ) < N := by exact_mod_cast hNM
      linarith
    refine ⟨x, hx0, hax, fun j => ?_⟩
    calc (|x j| : ℝ) = ‖x j‖ := by simp [Int.norm_eq_abs]
      _ ≤ ‖x‖ := norm_le_pi_norm x j
      _ ≤ _ := hxn
      _ ≤ _ := by
        apply Real.rpow_le_rpow (by positivity) _ hexp
        gcongr
        exact max_le hA hnorm

/-- Hilbert's first test case: `2 ^ √2` (the real number 2.665144143...) is transcendental. -/
theorem two_rpow_sqrt_two_transcendental :
    Transcendental ℚ ((2 : ℝ) ^ Real.sqrt 2) := by
  intro hx
  have h2 : IsAlgebraic ℚ (2 : ℂ) := by
    simpa using (isAlgebraic_algebraMap (R := ℚ) (A := ℂ) (2 : ℚ))
  have hs : IsAlgebraic ℚ ((Real.sqrt 2 : ℝ) : ℂ) := by
    have hsq : ((Real.sqrt 2 : ℝ) : ℂ) ^ 2 = 2 := by
      rw [← Complex.ofReal_pow, Real.sq_sqrt (by norm_num)]; simp
    have : IsIntegral ℚ (((Real.sqrt 2 : ℝ) : ℂ) ^ 2) := by rw [hsq]; exact h2.isIntegral
    exact (IsIntegral.of_pow two_pos this).isAlgebraic
  have hq : ∀ q : ℚ, ((Real.sqrt 2 : ℝ) : ℂ) ≠ (q : ℂ) := by
    intro q hq
    rw [← Complex.ofReal_ratCast, Complex.ofReal_inj] at hq
    exact irrational_sqrt_two ⟨q, hq.symm⟩
  have hl : Complex.exp ((Real.log 2 : ℝ) : ℂ) = 2 := by
    rw [← Complex.ofReal_exp, Real.exp_log (by norm_num)]; simp
  have hGS := gelfond_schneider_transcendental 2 _ h2 two_ne_zero
    (by norm_num) hs hq _ hl
  apply hGS
  have heq : Complex.exp (((Real.sqrt 2 : ℝ) : ℂ) * ((Real.log 2 : ℝ) : ℂ)) =
      Complex.ofRealAm (((2 : ℝ) ^ Real.sqrt 2 : ℝ)) := by
    rw [Complex.ofRealAm_coe, Real.rpow_def_of_pos (by norm_num), Complex.ofReal_exp]
    push_cast; ring_nf
  rw [heq]
  exact hx.algHom (Complex.ofRealAm.restrictScalars ℚ)

-- The card's system: 10x₁ + 7x₂ + x₃ + 7x₄ = 0 and 7x₁ + 6x₂ + 8x₃ − 10x₄ = 0.
-- The pigeonhole difference (2, 5, −13, −6) solves it, with height 13.
example : !![(10 : ℤ), 7, 1, 7; 7, 6, 8, -10] *ᵥ ![2, 5, -13, -6] = 0 := by decide
-- The smallest solution (−10, 8, 9, 5), height 10.
example : !![(10 : ℤ), 7, 1, 7; 7, 6, 8, -10] *ᵥ ![-10, 8, 9, 5] = 0 := by decide
-- The two colliding vectors (0, 0, 13, 6) and (2, 5, 0, 0) both give the output (55, 44).
example : !![(10 : ℤ), 7, 1, 7; 7, 6, 8, -10] *ᵥ ![0, 0, 13, 6] = ![55, 44] ∧
    !![(10 : ℤ), 7, 1, 7; 7, 6, 8, -10] *ᵥ ![2, 5, 0, 0] = ![55, 44] := by decide
-- Siegel's bound (4 × 10)^(2/2) = 40; 41^4 = 2,825,761 vectors outnumber 1601^2 = 2,563,201 outputs.
example : (4 * 10 : ℕ) ^ (2 / (4 - 2)) = 40 := by norm_num
example : (41 : ℕ) ^ 4 = 2825761 ∧ (4 * 10 * 40 + 1 : ℕ) ^ 2 = 2563201 ∧
    (2563201 : ℕ) < 2825761 := by norm_num
-- The square system in the first two unknowns has determinant 11.
example : !![(10 : ℤ), 7; 7, 6].det = 11 := by decide
-- Three unknowns: (50, −73, 11) solves the first three columns, height 73 above the naive bound 30.
example : !![(10 : ℤ), 7, 1; 7, 6, 8] *ᵥ ![50, -73, 11] = 0 := by decide
-- The squeeze in miniature: x = 1393, y = 985 solve x² − 2y² = −1.
example : (1393 : ℤ) ^ 2 - 2 * 985 ^ 2 = -1 := by norm_num

#print axioms gelfond_schneider_transcendental
#print axioms siegel_lemma_small_whole_solution
#print axioms two_rpow_sqrt_two_transcendental
