-- Filtering: the Kalman-Bucy error variance is the closed-form solution of the Riccati equation, it settles at the positive root, no other gain gives a smaller error variance, and the best fixed gain is lambda - a.
import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.Calculus.Deriv.Inv
import Mathlib.Analysis.Calculus.Deriv.MeanValue

open Set Filter Topology

/-- The forgetting rate `λ = √(a² + σ²/ρ²)`. -/
noncomputable def kbLam (a σ ρ : ℝ) : ℝ := Real.sqrt (a ^ 2 + σ ^ 2 / ρ ^ 2)

/-- The upper root `P₊ = ρ² (λ - a)` of the Riccati right side. -/
noncomputable def kbPplus (a σ ρ : ℝ) : ℝ := ρ ^ 2 * (kbLam a σ ρ - a)

/-- The lower root `P₋ = ρ² (-λ - a)` of the Riccati right side. -/
noncomputable def kbPminus (a σ ρ : ℝ) : ℝ := ρ ^ 2 * (-kbLam a σ ρ - a)

/-- The card's closed form `P_t = (P₊ - P₋ c e^{-2λt}) / (1 - c e^{-2λt})`,
with `c = (P₀ - P₊) / (P₀ - P₋)`. -/
noncomputable def kbP (a σ ρ P₀ t : ℝ) : ℝ :=
  let c := (P₀ - kbPplus a σ ρ) / (P₀ - kbPminus a σ ρ)
  (kbPplus a σ ρ - kbPminus a σ ρ * c * Real.exp (-2 * kbLam a σ ρ * t)) /
    (1 - c * Real.exp (-2 * kbLam a σ ρ * t))

/-- Basic facts about `λ`: it exceeds `|a|`, and `σ² = ρ² (λ² - a²)`. -/
lemma kbLam_facts (a σ ρ : ℝ) (hσ : 0 < σ) (hρ : 0 < ρ) :
    a < kbLam a σ ρ ∧ -a < kbLam a σ ρ ∧ σ ^ 2 = ρ ^ 2 * (kbLam a σ ρ ^ 2 - a ^ 2) := by
  have hρ2 : 0 < ρ ^ 2 := by positivity
  have hq : 0 < σ ^ 2 / ρ ^ 2 := by positivity
  have hsq : kbLam a σ ρ ^ 2 = a ^ 2 + σ ^ 2 / ρ ^ 2 := by
    unfold kbLam; rw [Real.sq_sqrt (by positivity)]
  have hnn : 0 ≤ kbLam a σ ρ := Real.sqrt_nonneg _
  refine ⟨?_, ?_, ?_⟩
  · nlinarith
  · nlinarith
  · rw [hsq]; field_simp; ring

/-- The closed form, cleared of the inner fraction. -/
lemma kbP_eq (a σ ρ P₀ t : ℝ) (hC : P₀ - kbPminus a σ ρ ≠ 0) :
    kbP a σ ρ P₀ t =
      (kbPplus a σ ρ * (P₀ - kbPminus a σ ρ) -
          kbPminus a σ ρ * (P₀ - kbPplus a σ ρ) * Real.exp (-2 * kbLam a σ ρ * t)) /
        ((P₀ - kbPminus a σ ρ) - (P₀ - kbPplus a σ ρ) * Real.exp (-2 * kbLam a σ ρ * t)) := by
  unfold kbP
  simp only
  rw [← mul_div_mul_right _ _ hC]
  congr 1
  · field_simp
  · field_simp

/-- The cleared denominator is positive for `t ≥ 0`, and `P₀ - P₋ > 0`. -/
lemma kb_den_pos (a σ ρ P₀ t : ℝ) (hσ : 0 < σ) (hρ : 0 < ρ) (hP₀ : 0 ≤ P₀) (ht : 0 ≤ t) :
    0 < P₀ - kbPminus a σ ρ ∧
    0 < (P₀ - kbPminus a σ ρ) - (P₀ - kbPplus a σ ρ) * Real.exp (-2 * kbLam a σ ρ * t) := by
  obtain ⟨h1, h2, -⟩ := kbLam_facts a σ ρ hσ hρ
  have hρ2 : 0 < ρ ^ 2 := by positivity
  have hm : kbPminus a σ ρ < 0 := by
    unfold kbPminus; nlinarith
  have hpm : kbPminus a σ ρ < kbPplus a σ ρ := by
    unfold kbPminus kbPplus; nlinarith
  have hE0 : 0 < Real.exp (-2 * kbLam a σ ρ * t) := Real.exp_pos _
  have hE1 : Real.exp (-2 * kbLam a σ ρ * t) ≤ 1 := by
    rw [Real.exp_le_one_iff]; nlinarith
  refine ⟨by linarith, ?_⟩
  rcases le_or_gt (P₀ - kbPplus a σ ρ) 0 with h | h
  · nlinarith
  · nlinarith

/-- The closed form solves the Riccati equation at every `t ≥ 0`. -/
lemma kbP_hasDerivAt (a σ ρ P₀ t : ℝ) (hσ : 0 < σ) (hρ : 0 < ρ) (hP₀ : 0 ≤ P₀) (ht : 0 ≤ t) :
    HasDerivAt (kbP a σ ρ P₀)
      (-2 * a * kbP a σ ρ P₀ t + σ ^ 2 - kbP a σ ρ P₀ t ^ 2 / ρ ^ 2) t := by
  obtain ⟨hC, hD⟩ := kb_den_pos a σ ρ P₀ t hσ hρ hP₀ ht
  obtain ⟨-, -, hσ2⟩ := kbLam_facts a σ ρ hσ hρ
  have hfun : kbP a σ ρ P₀ = fun s =>
      (kbPplus a σ ρ * (P₀ - kbPminus a σ ρ) -
          kbPminus a σ ρ * (P₀ - kbPplus a σ ρ) * Real.exp (-2 * kbLam a σ ρ * s)) /
        ((P₀ - kbPminus a σ ρ) - (P₀ - kbPplus a σ ρ) * Real.exp (-2 * kbLam a σ ρ * s)) := by
    funext s; exact kbP_eq a σ ρ P₀ s hC.ne'
  rw [hfun]; beta_reduce
  have hE : HasDerivAt (fun s => Real.exp (-2 * kbLam a σ ρ * s))
      (Real.exp (-2 * kbLam a σ ρ * t) * (-2 * kbLam a σ ρ)) t := by
    have := ((hasDerivAt_id t).const_mul (-2 * kbLam a σ ρ)).exp
    simpa using this
  have hN := (hE.const_mul (kbPminus a σ ρ * (P₀ - kbPplus a σ ρ))).const_sub
    (kbPplus a σ ρ * (P₀ - kbPminus a σ ρ))
  have hDd := (hE.const_mul (P₀ - kbPplus a σ ρ)).const_sub (P₀ - kbPminus a σ ρ)
  have h := HasDerivAt.div hN hDd hD.ne'
  refine h.congr_deriv ?_
  rw [hσ2]
  have hD' := hD.ne'
  have hρ0 : ρ ≠ 0 := hρ.ne'
  generalize Real.exp (-2 * kbLam a σ ρ * t) = E at hD' ⊢
  simp only [kbPplus, kbPminus] at hD' ⊢
  generalize kbLam a σ ρ = L at hD' ⊢
  field_simp
  ring

/-- The closed form tends to `P₊`. -/
lemma kbP_tendsto (a σ ρ P₀ : ℝ) (hσ : 0 < σ) (hρ : 0 < ρ) (hP₀ : 0 ≤ P₀) :
    Tendsto (kbP a σ ρ P₀) atTop (𝓝 (kbPplus a σ ρ)) := by
  obtain ⟨hC, -⟩ := kb_den_pos a σ ρ P₀ 0 hσ hρ hP₀ le_rfl
  obtain ⟨h1, h2, -⟩ := kbLam_facts a σ ρ hσ hρ
  have hL : 0 < kbLam a σ ρ := by linarith
  have hfun : kbP a σ ρ P₀ = fun s =>
      (kbPplus a σ ρ * (P₀ - kbPminus a σ ρ) -
          kbPminus a σ ρ * (P₀ - kbPplus a σ ρ) * Real.exp (-2 * kbLam a σ ρ * s)) /
        ((P₀ - kbPminus a σ ρ) - (P₀ - kbPplus a σ ρ) * Real.exp (-2 * kbLam a σ ρ * s)) := by
    funext s; exact kbP_eq a σ ρ P₀ s hC.ne'
  rw [hfun]
  have hlin : Tendsto (fun s : ℝ => -2 * kbLam a σ ρ * s) atTop atBot :=
    tendsto_id.const_mul_atTop_of_neg (by linarith)
  have hE : Tendsto (fun s : ℝ => Real.exp (-2 * kbLam a σ ρ * s)) atTop (𝓝 0) :=
    Real.tendsto_exp_atBot.comp hlin
  have hN := (hE.const_mul (kbPminus a σ ρ * (P₀ - kbPplus a σ ρ))).const_sub
    (kbPplus a σ ρ * (P₀ - kbPminus a σ ρ))
  have hDd := (hE.const_mul (P₀ - kbPplus a σ ρ)).const_sub (P₀ - kbPminus a σ ρ)
  have h := hN.div hDd (by simpa using hC.ne')
  have hC' : P₀ - kbPminus a σ ρ ≠ 0 := hC.ne'
  convert h using 2
  simp only [mul_zero, sub_zero]
  field_simp

/-- A one-sided fence: a function that starts at `≥ 0` and, while negative, grows at least
like `M d`, stays `≥ 0`. Only interior derivatives are used. -/
lemma kb_fence (d d' : ℝ → ℝ) (M T : ℝ) (hc : ContinuousOn d (Icc 0 T)) (h0 : 0 ≤ d 0)
    (hd : ∀ t ∈ Ioo 0 T, HasDerivAt d (d' t) t)
    (hneg : ∀ t ∈ Ioo 0 T, d t < 0 → M * d t ≤ d' t) :
    ∀ t ∈ Icc 0 T, 0 ≤ d t := by
  intro t₁ ht₁
  by_contra hlt'
  have hlt : d t₁ < 0 := not_le.mp hlt'
  have hc1 : ContinuousOn d (Icc 0 t₁) := hc.mono (Icc_subset_Icc_right ht₁.2)
  have hcl : IsClosed (Icc 0 t₁ ∩ d ⁻¹' Ici 0) :=
    hc1.preimage_isClosed_of_isClosed isClosed_Icc isClosed_Ici
  have hcpt : IsCompact (Icc 0 t₁ ∩ d ⁻¹' Ici 0) :=
    isCompact_Icc.of_isClosed_subset hcl inter_subset_left
  have hne : (Icc 0 t₁ ∩ d ⁻¹' Ici 0).Nonempty := ⟨0, ⟨le_rfl, ht₁.1⟩, h0⟩
  obtain ⟨t₀, ⟨ht₀I, ht₀d⟩, ht₀max⟩ := hcpt.exists_isGreatest hne
  have ht₀d' : 0 ≤ d t₀ := ht₀d
  have hlt01 : t₀ < t₁ := by
    rcases lt_or_eq_of_le ht₀I.2 with h | h
    · exact h
    · rw [h] at ht₀d'; linarith
  have hnegs : ∀ s ∈ Ioo t₀ t₁, d s < 0 := by
    intro s hs
    by_contra hns'
    have hns : 0 ≤ d s := not_lt.mp hns'
    have : s ≤ t₀ := ht₀max ⟨⟨by linarith [ht₀I.1, hs.1], hs.2.le⟩, hns⟩
    linarith [hs.1]
  have hsub : Icc t₀ t₁ ⊆ Icc 0 T := Icc_subset_Icc ht₀I.1 ht₁.2
  have hIoo : ∀ s ∈ Ioo t₀ t₁, s ∈ Ioo 0 T := fun s hs =>
    ⟨lt_of_le_of_lt ht₀I.1 hs.1, lt_of_lt_of_le hs.2 ht₁.2⟩
  let h : ℝ → ℝ := fun s => d s * Real.exp (-M * s)
  have hderiv : ∀ s ∈ Ioo t₀ t₁, HasDerivAt h
      (d' s * Real.exp (-M * s) + d s * (Real.exp (-M * s) * (-M))) s := by
    intro s hs
    have he : HasDerivAt (fun s => Real.exp (-M * s)) (Real.exp (-M * s) * (-M)) s := by
      have := ((hasDerivAt_id s).const_mul (-M)).exp
      simpa using this
    exact (hd s (hIoo s hs)).mul he
  have hmono : MonotoneOn h (Icc t₀ t₁) := by
    apply monotoneOn_of_deriv_nonneg (convex_Icc t₀ t₁)
    · exact (hc.mono hsub).mul (Real.continuous_exp.comp (continuous_const.mul continuous_id)).continuousOn
    · rw [interior_Icc]
      intro s hs
      exact (hderiv s hs).differentiableAt.differentiableWithinAt
    · rw [interior_Icc]
      intro s hs
      rw [(hderiv s hs).deriv]
      have h1 := hneg s (hIoo s hs) (hnegs s hs)
      have hpos := Real.exp_pos (-M * s)
      nlinarith
  have := hmono ⟨le_rfl, hlt01.le⟩ ⟨hlt01.le, le_rfl⟩ hlt01.le
  simp only [h] at this
  have hp0 := Real.exp_pos (-M * t₀)
  have hp1 := Real.exp_pos (-M * t₁)
  nlinarith [mul_nonneg ht₀d' hp0.le, mul_neg_of_neg_of_pos hlt hp1]

/-- Comparison for the Riccati equation: a solution `Q` stays below any `v` that obeys the
same equation plus a nonnegative forcing term `s`, starting no lower. -/
lemma kb_compare (a σ ρ : ℝ) (hρ : 0 < ρ) (Q v s : ℝ → ℝ)
    (hQc : ContinuousOn Q (Ici 0)) (hvc : ContinuousOn v (Ici 0)) (h0 : Q 0 ≤ v 0)
    (hQ : ∀ t, 0 < t → HasDerivAt Q (-2 * a * Q t + σ ^ 2 - Q t ^ 2 / ρ ^ 2) t)
    (hv : ∀ t, 0 < t → HasDerivAt v (-2 * a * v t + σ ^ 2 - v t ^ 2 / ρ ^ 2 + s t) t)
    (hs : ∀ t, 0 < t → 0 ≤ s t) :
    ∀ t, 0 ≤ t → Q t ≤ v t := by
  intro T hT
  have hQc' : ContinuousOn Q (Icc 0 T) := hQc.mono Icc_subset_Ici_self
  have hvc' : ContinuousOn v (Icc 0 T) := hvc.mono Icc_subset_Ici_self
  obtain ⟨CQ, hCQ⟩ := isCompact_Icc.exists_bound_of_continuousOn hQc'
  obtain ⟨Cv, hCv⟩ := isCompact_Icc.exists_bound_of_continuousOn hvc'
  have hρ2 : 0 < ρ ^ 2 := by positivity
  set M : ℝ := 2 * |a| + (CQ + Cv) / ρ ^ 2 with hM
  have key := kb_fence (fun t => v t - Q t)
    (fun t => (-2 * a * v t + σ ^ 2 - v t ^ 2 / ρ ^ 2 + s t) -
      (-2 * a * Q t + σ ^ 2 - Q t ^ 2 / ρ ^ 2)) M T (hvc'.sub hQc') (by simpa using h0)
    (fun t ht => (hv t ht.1).sub (hQ t ht.1)) ?_ T ⟨hT, le_rfl⟩
  · simpa using key
  intro t ht hdn
  have htI : t ∈ Icc 0 T := Ioo_subset_Icc_self ht
  have bQ : |Q t| ≤ CQ := by simpa [Real.norm_eq_abs] using hCQ t htI
  have bv : |v t| ≤ Cv := by simpa [Real.norm_eq_abs] using hCv t htI
  have hst := hs t ht.1
  set g : ℝ := -2 * a - (v t + Q t) / ρ ^ 2 with hg
  have hgM : g ≤ M := by
    have h1 : -2 * a ≤ 2 * |a| := by linarith [neg_abs_le a]
    have h2 : -(v t + Q t) ≤ CQ + Cv := by
      linarith [neg_abs_le (v t), neg_abs_le (Q t)]
    have h3 : -(v t + Q t) / ρ ^ 2 ≤ (CQ + Cv) / ρ ^ 2 :=
      div_le_div_of_nonneg_right h2 hρ2.le
    rw [hg, hM]
    have : -2 * a - (v t + Q t) / ρ ^ 2 = -2 * a + (-(v t + Q t)) / ρ ^ 2 := by ring
    linarith
  have hid : (-2 * a * v t + σ ^ 2 - v t ^ 2 / ρ ^ 2 + s t) -
      (-2 * a * Q t + σ ^ 2 - Q t ^ 2 / ρ ^ 2) = g * (v t - Q t) + s t := by
    rw [hg]; ring
  rw [hid]
  nlinarith [mul_le_mul_of_nonpos_right hgM hdn.le]

/-- The closed form starts at `P₀`. -/
lemma kbP_zero (a σ ρ P₀ : ℝ) (hσ : 0 < σ) (hρ : 0 < ρ) (hP₀ : 0 ≤ P₀) :
    kbP a σ ρ P₀ 0 = P₀ := by
  have hC := (kb_den_pos a σ ρ P₀ 0 hσ hρ hP₀ le_rfl).1
  obtain ⟨h1, h2, -⟩ := kbLam_facts a σ ρ hσ hρ
  have hρ2 : 0 < ρ ^ 2 := by positivity
  have hpm : kbPminus a σ ρ < kbPplus a σ ρ := by
    unfold kbPminus kbPplus; nlinarith
  rw [kbP_eq a σ ρ P₀ 0 hC.ne']
  simp only [mul_zero, Real.exp_zero, mul_one]
  rw [div_eq_iff (by intro h; linarith)]
  ring

#print axioms kbLam_facts
#print axioms kbP_eq
#print axioms kb_den_pos
#print axioms kbP_hasDerivAt
#print axioms kbP_tendsto
#print axioms kb_fence
#print axioms kb_compare
#print axioms kbP_zero

/-- The filter's error variance follows the Riccati equation `dP/dt = -2aP + σ² - P²/ρ²`,
fixed before any data arrives. With rate noise `σ > 0`, quote noise `ρ > 0` that never
vanishes, and a starting variance `P₀ ≥ 0`: the card's closed form starts at `P₀`, solves
the Riccati equation at every time `t ≥ 0`, is the only solution from `P₀` for `t ≥ 0`,
and settles at the upper root `P₊ = ρ² (λ - a)` as `t` grows. -/
theorem riccati_variance_closed_form_and_limit (a σ ρ P₀ : ℝ) (hσ : 0 < σ) (hρ : 0 < ρ)
    (hP₀ : 0 ≤ P₀) :
    kbP a σ ρ P₀ 0 = P₀ ∧
    (∀ t, 0 ≤ t → HasDerivAt (kbP a σ ρ P₀)
        (-2 * a * kbP a σ ρ P₀ t + σ ^ 2 - kbP a σ ρ P₀ t ^ 2 / ρ ^ 2) t) ∧
    (∀ P : ℝ → ℝ, P 0 = P₀ → ContinuousOn P (Ici 0) →
        (∀ t, 0 < t → HasDerivAt P (-2 * a * P t + σ ^ 2 - P t ^ 2 / ρ ^ 2) t) →
        ∀ t, 0 ≤ t → P t = kbP a σ ρ P₀ t) ∧
    Tendsto (kbP a σ ρ P₀) atTop (𝓝 (kbPplus a σ ρ)) := by
  have hQc : ContinuousOn (kbP a σ ρ P₀) (Ici 0) := fun x hx =>
    (kbP_hasDerivAt a σ ρ P₀ x hσ hρ hP₀ hx).continuousAt.continuousWithinAt
  have hQ' : ∀ t, 0 < t → HasDerivAt (kbP a σ ρ P₀)
      (-2 * a * kbP a σ ρ P₀ t + σ ^ 2 - kbP a σ ρ P₀ t ^ 2 / ρ ^ 2) t := fun t ht =>
    kbP_hasDerivAt a σ ρ P₀ t hσ hρ hP₀ ht.le
  have h0 := kbP_zero a σ ρ P₀ hσ hρ hP₀
  refine ⟨h0, fun t ht => kbP_hasDerivAt a σ ρ P₀ t hσ hρ hP₀ ht, ?_,
    kbP_tendsto a σ ρ P₀ hσ hρ hP₀⟩
  intro P hP0 hPc hP t ht
  exact le_antisymm
    (kb_compare a σ ρ hρ P (kbP a σ ρ P₀) (fun _ => 0) hPc hQc (by rw [hP0, h0])
      hP (fun t ht => by simpa using hQ' t ht) (fun _ _ => le_rfl) t ht)
    (kb_compare a σ ρ hρ (kbP a σ ρ P₀) P (fun _ => 0) hQc hPc (by rw [hP0, h0])
      hQ' (fun t ht => by simpa using hP t ht) (fun _ _ => le_rfl) t ht)

/-- Step 5: no gain beats the Kalman-Bucy gain. Take any filter of the same shape with any
gain `K t`. Its error variance `v` starts at `P₀` and obeys
`dv/dt = -2(a + K) v + σ² + K² ρ²`. Then at every time `t ≥ 0` it is at least the
Kalman-Bucy variance `P_t`. -/
theorem no_gain_beats_kalman_bucy (a σ ρ P₀ : ℝ) (hσ : 0 < σ) (hρ : 0 < ρ) (hP₀ : 0 ≤ P₀)
    (K v : ℝ → ℝ) (hv0 : v 0 = P₀) (hvc : ContinuousOn v (Ici 0))
    (hv : ∀ t, 0 < t → HasDerivAt v (-2 * (a + K t) * v t + σ ^ 2 + K t ^ 2 * ρ ^ 2) t) :
    ∀ t, 0 ≤ t → kbP a σ ρ P₀ t ≤ v t := by
  have hQc : ContinuousOn (kbP a σ ρ P₀) (Ici 0) := fun x hx =>
    (kbP_hasDerivAt a σ ρ P₀ x hσ hρ hP₀ hx).continuousAt.continuousWithinAt
  have hQ' : ∀ t, 0 < t → HasDerivAt (kbP a σ ρ P₀)
      (-2 * a * kbP a σ ρ P₀ t + σ ^ 2 - kbP a σ ρ P₀ t ^ 2 / ρ ^ 2) t := fun t ht =>
    kbP_hasDerivAt a σ ρ P₀ t hσ hρ hP₀ ht.le
  have hρ0 : ρ ≠ 0 := hρ.ne'
  intro t ht
  exact kb_compare a σ ρ hρ (kbP a σ ρ P₀) v (fun t => (v t / ρ - K t * ρ) ^ 2) hQc hvc
    (by rw [kbP_zero a σ ρ P₀ hσ hρ hP₀, hv0])
    hQ' (fun t ht => (hv t ht).congr_deriv (by field_simp; ring)) (fun _ _ => sq_nonneg _) t ht

/-- Step 5, fixed gains: a fixed gain `K` with `a + K > 0` settles at the error variance
`(σ² + K² ρ²) / (2(a + K))`. That is never below `P₊`, and equals `P₊` exactly at the
gain `K = λ - a`, which itself satisfies `a + K > 0`. -/
theorem best_fixed_gain_is_lam_sub_a (a σ ρ : ℝ) (hσ : 0 < σ) (hρ : 0 < ρ) :
    0 < a + (kbLam a σ ρ - a) ∧
    ∀ K : ℝ, 0 < a + K →
      kbPplus a σ ρ ≤ (σ ^ 2 + K ^ 2 * ρ ^ 2) / (2 * (a + K)) ∧
      ((σ ^ 2 + K ^ 2 * ρ ^ 2) / (2 * (a + K)) = kbPplus a σ ρ ↔ K = kbLam a σ ρ - a) := by
  obtain ⟨h1, h2, hσ2⟩ := kbLam_facts a σ ρ hσ hρ
  refine ⟨by linarith, fun K hK => ?_⟩
  have hρ2 : 0 < ρ ^ 2 := by positivity
  have hK2 : (2 * (a + K)) ≠ 0 := by positivity
  have key : (σ ^ 2 + K ^ 2 * ρ ^ 2) / (2 * (a + K)) - kbPplus a σ ρ =
      ρ ^ 2 * (a + K - kbLam a σ ρ) ^ 2 / (2 * (a + K)) := by
    unfold kbPplus
    rw [hσ2]
    field_simp
    ring
  have hnn : 0 ≤ ρ ^ 2 * (a + K - kbLam a σ ρ) ^ 2 / (2 * (a + K)) := by positivity
  refine ⟨by linarith, ⟨fun heq => ?_, fun hKe => ?_⟩⟩
  · have hz : ρ ^ 2 * (a + K - kbLam a σ ρ) ^ 2 / (2 * (a + K)) = 0 := by linarith
    rw [div_eq_zero_iff] at hz
    rcases hz with hz | hz
    · rcases mul_eq_zero.mp hz with hz | hz
      · linarith
      · have := pow_eq_zero_iff (n := 2) (by norm_num) |>.mp hz
        linarith
    · exact absurd hz hK2
  · have hz : a + K - kbLam a σ ρ = 0 := by rw [hKe]; ring
    have : ρ ^ 2 * (a + K - kbLam a σ ρ) ^ 2 / (2 * (a + K)) = 0 := by rw [hz]; ring
    linarith

-- The card's numbers: a = 2, θ = 4, σ = 1, one day's quote error s = 1/2, one day Δ = 1/250.
-- ρ² = s² Δ = 1/1000.
example : ((1 : ℚ) / 2) ^ 2 * (1 / 250) = 1 / 1000 := by norm_num
-- Prior variance σ² / (2a) = 1/4.
example : (1 : ℚ) ^ 2 / (2 * 2) = 1 / 4 := by norm_num
-- σ²/ρ² = 1000 and a² + σ²/ρ² = 1004, so λ = √1004.
example : (1 : ℚ) ^ 2 / (1 / 1000) = 1000 := by norm_num
example : (2 : ℚ) ^ 2 + 1 ^ 2 / (1 / 1000) = 1004 := by norm_num
-- Gain at the start P₀/ρ² = 250 a year.
example : ((1 : ℚ) / 4) / (1 / 1000) = 250 := by norm_num
-- The roots' sum -2aρ² = -1/250 and product ρ⁴(a² - λ²) = -σ²ρ² = -1/1000.
example : -2 * (2 : ℚ) * (1 / 1000) = -1 / 250 := by norm_num
example : ((1 : ℚ) / 1000) ^ 2 * (2 ^ 2 - 1004) = -(1 ^ 2 * (1 / 1000)) := by norm_num
-- Fixed gains, (σ² + K²ρ²)/(2(a + K)): gain 0 gives 1/4, gain 10 gives 11/240,
-- gain 100 gives 11/204, gain 1000 gives 1001/2004.
example : ((1 : ℚ) + 0 ^ 2 * (1 / 1000)) / (2 * (2 + 0)) = 1 / 4 := by norm_num
example : ((1 : ℚ) + 10 ^ 2 * (1 / 1000)) / (2 * (2 + 10)) = 11 / 240 := by norm_num
example : ((1 : ℚ) + 100 ^ 2 * (1 / 1000)) / (2 * (2 + 100)) = 11 / 204 := by norm_num
example : ((1 : ℚ) + 1000 ^ 2 * (1 / 1000)) / (2 * (2 + 1000)) = 1001 / 2004 := by norm_num
-- Latest daily quote: s² + σ² Δ / 3 = 1/4 + 1/750 = 377/1500.
example : ((1 : ℚ) / 2) ^ 2 + 1 ^ 2 * (1 / 250) / 3 = 377 / 1500 := by norm_num

#print axioms riccati_variance_closed_form_and_limit
#print axioms no_gain_beats_kalman_bucy
#print axioms best_fixed_gain_is_lam_sub_a
