-- An American option: the floor's push makes the variational inequality and the complementarity form the same problem, the perpetual put's tangent trigger is the one smooth-pasting trigger and the best one, and the push where the holder exercises is the carry rK - qS.
import Mathlib.MeasureTheory.Function.LocallyIntegrable
import Mathlib.MeasureTheory.Integral.Bochner.Basic
import Mathlib.MeasureTheory.Measure.Lebesgue.Basic
import Mathlib.Analysis.SpecialFunctions.Pow.Deriv
import Mathlib.Analysis.Calculus.ContDiff.Defs
import Mathlib.Analysis.Distribution.AEEqOfIntegralContDiff
import Mathlib.Analysis.Convex.SpecificFunctions.Basic

open MeasureTheory

open Filter Metric Function Set Topology in
/-- A locally integrable function whose integral against every smooth, compactly supported,
non-negative bump is non-negative has non-negative integral over every compact set. -/
theorem setIntegral_isCompact_nonneg_of_bump (P : ℝ → ℝ) (hP : LocallyIntegrable P volume)
    (h : ∀ g : ℝ → ℝ, ContDiff ℝ ((⊤ : ℕ∞) : WithTop ℕ∞) g → HasCompactSupport g →
      (∀ x, 0 ≤ g x) → 0 ≤ ∫ x, g x * P x)
    (s : Set ℝ) (hs : IsCompact s) : 0 ≤ ∫ x in s, P x := by
  obtain ⟨δ, δpos, hδ⟩ : ∃ δ, 0 < δ ∧ IsCompact (cthickening δ s) :=
    hs.exists_isCompact_cthickening
  obtain ⟨u, -, u_pos, u_lim⟩ : ∃ u, StrictAnti u ∧ (∀ (n : ℕ), u n ∈ Ioo 0 δ)
    ∧ Tendsto u atTop (𝓝 0) := exists_seq_strictAnti_tendsto' δpos
  let v : ℕ → Set ℝ := fun n ↦ thickening (u n) s
  obtain ⟨K, K_compact, vK⟩ : ∃ K, IsCompact K ∧ ∀ n, v n ⊆ K :=
    ⟨_, hδ, fun n ↦ thickening_subset_cthickening_of_le (u_pos n).2.le _⟩
  have : ∀ n, ∃ (g : ℝ → ℝ), support g = v n ∧ ContDiff ℝ ((⊤ : ℕ∞) : WithTop ℕ∞) g ∧
      Set.range g ⊆ Set.Icc 0 1 ∧ ∀ x ∈ s, g x = 1 := by
    intro n
    rcases exists_contDiff_support_eq_eq_one_iff (n := (⊤ : ℕ∞)) isOpen_thickening
      hs.isClosed (self_subset_thickening (u_pos n).1 s) with ⟨g, g_smooth, g_range, g_supp, hg⟩
    exact ⟨g, g_supp, g_smooth, g_range, fun x hx ↦ (hg x).1 hx⟩
  choose g g_supp g_diff g_range hg using this
  have L : Tendsto (fun n ↦ ∫ x, g n x * P x) atTop (𝓝 (∫ x in s, P x)) := by
    rw [← integral_indicator hs.measurableSet]
    let bound : ℝ → ℝ := K.indicator (fun x ↦ ‖P x‖)
    have A : ∀ n, AEStronglyMeasurable (fun x ↦ g n x * P x) volume :=
      fun n ↦ (g_diff n).continuous.aestronglyMeasurable.mul hP.aestronglyMeasurable
    have B : Integrable bound volume := by
      rw [integrable_indicator_iff K_compact.measurableSet]
      exact (hP.integrableOn_isCompact K_compact).norm
    have C : ∀ n, ∀ᵐ x ∂volume, ‖g n x * P x‖ ≤ bound x := by
      intro n
      filter_upwards with x
      rw [norm_mul]
      refine le_indicator_apply (fun _ ↦ ?_) (fun hxK ↦ ?_)
      · have : ‖g n x‖ ≤ 1 := by
          have := g_range n (mem_range_self (f := g n) x)
          rw [Real.norm_of_nonneg this.1]
          exact this.2
        exact mul_le_of_le_one_left (norm_nonneg _) this
      · have : g n x = 0 := by
          rw [← notMem_support, g_supp]; contrapose hxK; exact vK n hxK
        simp [this]
    have D : ∀ᵐ x ∂volume, Tendsto (fun n => g n x * P x) atTop (𝓝 (s.indicator P x)) := by
      filter_upwards with x
      by_cases hxs : x ∈ s
      · have : ∀ n, g n x = 1 := fun n ↦ hg n x hxs
        simp [this, indicator_of_mem hxs P]
      · simp_rw [indicator_of_notMem hxs P]
        apply tendsto_const_nhds.congr'
        suffices H : ∀ᶠ n in atTop, g n x = 0 by
          filter_upwards [H] with n hn using by simp [hn]
        obtain ⟨ε, εpos, hε⟩ : ∃ ε, 0 < ε ∧ x ∉ thickening ε s := by
          rw [← hs.isClosed.closure_eq, closure_eq_iInter_thickening s] at hxs
          simpa using hxs
        filter_upwards [(tendsto_order.1 u_lim).2 _ εpos] with n hn
        rw [← notMem_support, g_supp]
        contrapose hε
        exact thickening_mono hn.le s hε
    exact tendsto_integral_of_dominated_convergence bound A B C D
  have : ∀ n, 0 ≤ ∫ x, g n x * P x := by
    refine fun n ↦ h _ (g_diff n) ?_ (fun x ↦ (g_range n (mem_range_self x)).1)
    apply HasCompactSupport.of_support_subset_isCompact K_compact
    simpa [g_supp] using vK n
  exact ge_of_tendsto' L this

#print axioms setIntegral_isCompact_nonneg_of_bump

/-- A locally integrable function whose integral against every smooth, compactly supported,
non-negative bump is non-negative is non-negative almost everywhere. -/
theorem ae_nonneg_of_bump (P : ℝ → ℝ) (hP : LocallyIntegrable P volume)
    (h : ∀ g : ℝ → ℝ, ContDiff ℝ ((⊤ : ℕ∞) : WithTop ℕ∞) g → HasCompactSupport g →
      (∀ x, 0 ≤ g x) → 0 ≤ ∫ x, g x * P x) :
    ∀ᵐ x, 0 ≤ P x := by
  have hm := hP.aestronglyMeasurable
  set P' := hm.mk P with hP'
  have hPP' : P =ᵐ[volume] P' := hm.ae_eq_mk
  have hP'm : Measurable P' := hm.stronglyMeasurable_mk.measurable
  let A : Set ℝ := {x | P' x < 0}
  have hA : MeasurableSet A := measurableSet_lt hP'm measurable_const
  have hA0 : volume A = 0 := by
    by_contra hne
    have hpos : (0 : ENNReal) < volume A := pos_iff_ne_zero.mpr hne
    obtain ⟨Kc, KA, hKc, hKpos⟩ := hA.exists_lt_isCompact hpos
    have h1 := setIntegral_isCompact_nonneg_of_bump P hP h Kc hKc
    have hKP : ∫ x in Kc, P x = ∫ x in Kc, P' x := integral_congr_ae (ae_restrict_of_ae hPP')
    have h2 : 0 < ∫ x in Kc, -P' x := by
      have hint : IntegrableOn (fun x => -P' x) Kc volume :=
        ((hP.integrableOn_isCompact hKc).congr_fun_ae (ae_restrict_of_ae hPP')).neg
      rw [setIntegral_pos_iff_support_of_nonneg_ae _ hint]
      · refine lt_of_lt_of_le hKpos (measure_mono ?_)
        intro x hx
        refine ⟨?_, hx⟩
        have : P' x < 0 := KA hx
        simp only [Function.mem_support]
        linarith
      · refine (ae_restrict_iff' hKc.measurableSet).2 (Filter.Eventually.of_forall fun x hx => ?_)
        have : P' x < 0 := KA hx
        simp only [Pi.zero_apply]
        linarith
    rw [integral_neg, ← hKP] at h2
    linarith
  filter_upwards [hPP', measure_eq_zero_iff_ae_notMem.mp hA0] with x hx hxA
  rw [hx]
  simpa [A] using hxA

#print axioms ae_nonneg_of_bump

/-- The variational inequality and the complementarity form say the same thing.
At one date, let `V` be the value profile in log price, `ψ` the payoff floor with `V ≥ ψ`,
and `P = -(V_t + 𝓛V)` the floor's push, only locally integrable (it jumps on the boundary).
Nudging `V` by any compactly supported profile `φ` with one continuous slope that keeps
`V + φ` on or above the floor never makes `∫ P φ` negative, exactly when the push is
non-negative and is zero wherever the value sits above the floor. -/
theorem variational_inequality_iff_complementarity
    (V ψ P : ℝ → ℝ) (hV : Continuous V) (hψ : Continuous ψ) (hP : LocallyIntegrable P volume)
    (hVψ : ∀ x, ψ x ≤ V x) :
    (∀ φ : ℝ → ℝ, ContDiff ℝ 1 φ → HasCompactSupport φ → (∀ x, ψ x ≤ V x + φ x) →
        0 ≤ ∫ x, P x * φ x) ↔
      ((∀ᵐ x, 0 ≤ P x) ∧ (∀ᵐ x, P x * (V x - ψ x) = 0)) := by
  constructor
  · intro h
    have h1 : ∀ g : ℝ → ℝ, ContDiff ℝ ((⊤ : ℕ∞) : WithTop ℕ∞) g → ContDiff ℝ 1 g :=
      fun g hg => hg.of_le (by exact_mod_cast le_top)
    refine ⟨ae_nonneg_of_bump P hP fun g hg hgc hg0 => ?_, ?_⟩
    · have := h g (h1 g hg) hgc (fun x => by linarith [hVψ x, hg0 x])
      simpa only [mul_comm] using this
    · let U : Set ℝ := {x | ψ x < V x}
      have hU : IsOpen U := isOpen_lt hψ hV
      have hz := hU.ae_eq_zero_of_integral_contDiff_smul_eq_zero (hP.locallyIntegrableOn U)
        (fun g hg hgc hgU => ?_)
      · filter_upwards [hz] with x hx
        by_cases hxU : x ∈ U
        · rw [hx hxU, zero_mul]
        · have : V x - ψ x = 0 := by
            have := hVψ x
            simp only [U, Set.mem_ofPred_eq, not_lt] at hxU
            linarith
          rw [this, mul_zero]
      · -- `V - ψ` has a positive lower bound on the support of `g`
        obtain ⟨δ, δpos, hδ⟩ := hgc.isCompact.exists_forall_le' (a := 0)
          ((hV.sub hψ).continuousOn) (fun x hx => by
            have := hgU hx
            simp only [U, Set.mem_ofPred_eq] at this
            simp only [Pi.sub_apply]; linarith)
        obtain ⟨M, hM⟩ := hgc.exists_bound_of_continuous hg.continuous
        set ε := δ / (|M| + 1) with hε
        have hεpos : 0 < ε := div_pos δpos (by positivity)
        have hsmall : ∀ x, ε * |g x| ≤ V x - ψ x := by
          intro x
          by_cases hx : x ∈ tsupport g
          · have h1 : |g x| ≤ |M| := (hM x).trans (le_abs_self M)
            have h2 : ε * |g x| ≤ ε * (|M| + 1) :=
              mul_le_mul_of_nonneg_left (by linarith) hεpos.le
            have h3 : ε * (|M| + 1) = δ := by rw [hε]; field_simp
            have := hδ x hx
            simp only [Pi.sub_apply] at this
            linarith
          · rw [image_eq_zero_of_notMem_tsupport hx, abs_zero, mul_zero]
            linarith [hVψ x]
        have hc : ContDiff ℝ 1 g := h1 g hg
        have hp := h (fun x => ε * g x) (contDiff_const.mul hc) (hgc.mul_left)
          (fun x => by
            have := hsmall x
            have := neg_abs_le (g x)
            nlinarith)
        have hn := h (fun x => -ε * g x) (contDiff_const.mul hc) (hgc.mul_left)
          (fun x => by
            have := hsmall x
            have := le_abs_self (g x)
            nlinarith)
        have ep : ∫ x, P x * (ε * g x) = ε * ∫ x, g x • P x := by
          rw [← integral_const_mul]; congr 1; funext x; rw [smul_eq_mul]; ring
        have en : ∫ x, P x * (-ε * g x) = -ε * ∫ x, g x • P x := by
          rw [← integral_const_mul]; congr 1; funext x; rw [smul_eq_mul]; ring
        rw [ep] at hp
        rw [en] at hn
        have a1 : 0 ≤ ∫ x, g x • P x := nonneg_of_mul_nonneg_right hp hεpos
        have a2 : ∫ x, g x • P x ≤ 0 := by nlinarith
        linarith
  · rintro ⟨h0, hc⟩ φ _ _ hφ
    apply integral_nonneg_of_ae
    filter_upwards [h0, hc] with x hx0 hxc
    have := hφ x
    simp only [Pi.zero_apply]
    nlinarith

/-- Smooth pasting picks the perpetual put's boundary. Let `λ < 0` be the negative root of
`½σ²λ² + μλ - r = 0`, `μ = r - q - ½σ²`. Glue `(K - L)(S/L)^λ` to the payoff at a trial trigger
`L > 0`: its slope at `L` is the payoff's slope `-1` exactly when `L = Kλ/(λ - 1)`, and that
tangent trigger gives the highest value at every share price. -/
theorem perpetual_put_smooth_pasting_trigger
    (K r q σ lam : ℝ) (hK : 0 < K)
    (hquad : σ ^ 2 / 2 * lam ^ 2 + (r - q - σ ^ 2 / 2) * lam - r = 0) (hlam : lam < 0) :
    (∀ L : ℝ, 0 < L →
        (deriv (fun S : ℝ => (K - L) * (S / L) ^ lam) L = -1 ↔ L = K * lam / (lam - 1))) ∧
      (∀ L S : ℝ, 0 < L → 0 < S →
        (K - L) * (S / L) ^ lam ≤
          (K - K * lam / (lam - 1)) * (S / (K * lam / (lam - 1))) ^ lam) := by
  have hl1 : lam - 1 < 0 := by linarith
  constructor
  · intro L hL
    have hd : HasDerivAt (fun S : ℝ => (K - L) * (S / L) ^ lam)
        ((K - L) * ((1 / L) * lam * (L / L) ^ (lam - 1))) L := by
      apply HasDerivAt.const_mul
      apply HasDerivAt.rpow_const
      · exact (hasDerivAt_id L).div_const L |>.congr_deriv (by simp)
      · left; simp [hL.ne']
    rw [hd.deriv, div_self hL.ne', Real.one_rpow, eq_div_iff hl1.ne]
    have : (K - L) * (1 / L * lam * 1) = (K - L) * lam / L := by ring
    rw [this, div_eq_iff hL.ne']
    constructor <;> intro h <;> linarith
  · intro L S hL hS
    set Ls := K * lam / (lam - 1) with hLsdef
    have hLs : Ls * (lam - 1) = K * lam := by
      rw [hLsdef, div_mul_cancel₀ _ hl1.ne]
    have hLspos : 0 < Ls := by
      rw [hLsdef]; exact div_pos_of_neg_of_neg (by nlinarith) hl1
    set u := Ls / L with hudef
    have hu : 0 < u := div_pos hLspos hL
    have hLu : L * u = Ls := by rw [hudef]; field_simp
    have hsplit : S / L = S / Ls * u := by rw [hudef]; field_simp
    rw [hsplit, Real.mul_rpow (div_pos hS hLspos).le hu.le]
    set c := (S / Ls) ^ lam with hc
    have hcpos : 0 < c := Real.rpow_pos_of_pos (div_pos hS hLspos) _
    set w := u ^ lam with hw
    have hwpos : 0 < w := Real.rpow_pos_of_pos hu _
    have B := one_add_mul_self_le_rpow_one_add (s := u - 1) (by linarith) (p := 1 - lam)
      (by linarith)
    rw [show 1 + (u - 1) = u by ring, Real.rpow_sub hu, Real.rpow_one, ← hw] at B
    rw [le_div_iff₀ hwpos] at B
    have hKLs : (K - Ls) * (1 - lam) = K := by linarith
    have hKLs0 : 0 ≤ K - Ls := by nlinarith
    have key : (K - L) * u = (K - Ls) * (1 + (1 - lam) * (u - 1)) := by
      clear_value Ls u c w
      linear_combination (-1 : ℝ) * hLu - (u - 1) * hKLs
    have h2 : (K - L) * w * u ≤ (K - Ls) * u := by
      calc (K - L) * w * u = w * ((K - L) * u) := by ring
        _ = (K - Ls) * ((1 + (1 - lam) * (u - 1)) * w) := by rw [key]; ring
        _ ≤ (K - Ls) * u := mul_le_mul_of_nonneg_left B hKLs0
    have h3 : (K - L) * w ≤ K - Ls := le_of_mul_le_mul_right h2 hu
    calc (K - L) * (c * w) = c * ((K - L) * w) := by ring
      _ ≤ c * (K - Ls) := mul_le_mul_of_nonneg_left h3 hcpos.le
      _ = (K - Ls) * c := by ring

/-- Where the holder exercises, the value is the payoff `K - S`, and the floor's push
`-(½σ²S² V_SS + (r - q) S V_S - rV)` is the carry of exercising: `rK - qS`. -/
theorem push_on_exercise_region (K r q σ S : ℝ) :
    -(1 / 2 * σ ^ 2 * S ^ 2 * deriv (deriv fun s : ℝ => K - s) S
        + (r - q) * S * deriv (fun s : ℝ => K - s) S - r * (K - S)) = r * K - q * S := by
  have h1 : deriv (fun s : ℝ => K - s) = fun _ => -1 := by
    funext x
    rw [deriv_const_sub, deriv_id'']
  rw [h1]
  simp only [deriv_const]
  ring

-- The payoff floor max(100 - S, 0) at the chart's prices 70, 75, ..., 110.
example : [70, 75, 80, 85, 90, 95, 100, 105, 110].map (fun S : ℤ => max (100 - S) 0)
    = [30, 25, 20, 15, 10, 5, 0, 0, 0] := by decide

-- The drift of the log price at r = 5%, q = 2%, σ = 20%: μ = 1/100 a year.
example : (5 / 100 : ℚ) - 2 / 100 - 1 / 2 * (20 / 100) ^ 2 = 1 / 100 := by norm_num

-- The carry on the line B = $81.59: rK - qB = $3.3682 a year.
example : (5 / 100 : ℚ) * 100 - 2 / 100 * (8159 / 100) = 33682 / 10000 := by norm_num

-- The push at the grid node $70.03: rK - qS = $3.5994 a year.
example : (5 / 100 : ℚ) * 100 - 2 / 100 * (7003 / 100) = 35994 / 10000 := by norm_num

#print axioms variational_inequality_iff_complementarity
#print axioms perpetual_put_smooth_pasting_trigger
#print axioms push_on_exercise_region
