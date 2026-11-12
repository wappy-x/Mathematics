-- The pendulum: along every frictionless motion the energy stays fixed, so below energy 2 the motion is a periodic swing inside one well and above energy 2 it is a full rotation that repeats every turn.
import Mathlib
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.Order.Filter.AtTopBot.Basic

open Real Filter Topology

/-- The pendulum's energy in units of `m g l`: half the square of the angular speed `ω`,
plus the bob's height `1 - cos θ` in rod lengths. -/
noncomputable def pendulumEnergy (θ ω : ℝ) : ℝ := ω ^ 2 / 2 + 1 - Real.cos θ

lemma pend_energy_const (θ ω : ℝ → ℝ) (hθ : ∀ t, HasDerivAt θ (ω t) t)
    (hω : ∀ t, HasDerivAt ω (-Real.sin (θ t)) t) (t s : ℝ) :
    pendulumEnergy (θ t) (ω t) = pendulumEnergy (θ s) (ω s) := by
  have hd : ∀ x, HasDerivAt (fun x => pendulumEnergy (θ x) (ω x)) 0 x := by
    intro x
    have h1 := ((hω x).pow 2).div_const 2
    have h2 := (hθ x).cos
    have h3 := (h1.add_const 1).sub h2
    convert h3 using 1
    · funext y; simp [pendulumEnergy]
    · push_cast; ring
  exact is_const_of_deriv_eq_zero (fun x => (hd x).differentiableAt) (fun x => (hd x).deriv) t s

#print axioms pend_energy_const

lemma pend_unique (θ ω θ' ω' : ℝ → ℝ) (hθ : ∀ t, HasDerivAt θ (ω t) t)
    (hω : ∀ t, HasDerivAt ω (-Real.sin (θ t)) t) (hθ' : ∀ t, HasDerivAt θ' (ω' t) t)
    (hω' : ∀ t, HasDerivAt ω' (-Real.sin (θ' t)) t) (t₀ : ℝ)
    (h1 : θ t₀ = θ' t₀) (h2 : ω t₀ = ω' t₀) (t : ℝ) : θ t = θ' t ∧ ω t = ω' t := by
  let v : ℝ → ℝ × ℝ → ℝ × ℝ := fun _ p => (p.2, -Real.sin p.1)
  have hL : LipschitzWith 1 (fun p : ℝ × ℝ => (p.2, -Real.sin p.1)) := by
    have := (LipschitzWith.prod_snd (α := ℝ) (β := ℝ)).prodMk
      (Real.lipschitzWith_sin.comp (LipschitzWith.prod_fst (α := ℝ) (β := ℝ))).neg
    simpa using this
  have hf : ∀ s, HasDerivAt (fun s => (θ s, ω s)) (v s (θ s, ω s)) s :=
    fun s => (hθ s).prodMk (hω s)
  have hg : ∀ s, HasDerivAt (fun s => (θ' s, ω' s)) (v s (θ' s, ω' s)) s :=
    fun s => (hθ' s).prodMk (hω' s)
  have ht₀ : t₀ ∈ Set.Ioo (min t t₀ - 1) (max t t₀ + 1) :=
    ⟨by linarith [min_le_right t t₀], by linarith [le_max_right t t₀]⟩
  have ht : t ∈ Set.Ioo (min t t₀ - 1) (max t t₀ + 1) :=
    ⟨by linarith [min_le_left t t₀], by linarith [le_max_left t t₀]⟩
  have key := ODE_solution_unique_of_mem_Ioo (v := v) (s := fun _ => Set.univ) (K := 1)
    (fun _ _ => hL.lipschitzOnWith) ht₀
    (fun s _ => ⟨hf s, trivial⟩) (fun s _ => ⟨hg s, trivial⟩) (by simp [h1, h2]) ht
  simpa using key

#print axioms pend_unique

lemma pend_reflect (θ ω : ℝ → ℝ) (hθ : ∀ t, HasDerivAt θ (ω t) t)
    (hω : ∀ t, HasDerivAt ω (-Real.sin (θ t)) t) (t₀ : ℝ) (h0 : ω t₀ = 0) (t : ℝ) :
    θ (2 * t₀ - t) = θ t ∧ ω (2 * t₀ - t) = -ω t := by
  have hA : ∀ s, HasDerivAt (fun s => θ (2 * t₀ - s)) (-ω (2 * t₀ - s)) s := fun s =>
    (hθ (2 * t₀ - s)).comp_const_sub (2 * t₀) s
  have hB : ∀ s, HasDerivAt (fun s => -ω (2 * t₀ - s)) (-Real.sin (θ (2 * t₀ - s))) s :=
    fun s => by simpa using ((hω (2 * t₀ - s)).comp_const_sub (2 * t₀) s).fun_neg
  have he : 2 * t₀ - t₀ = t₀ := by ring
  obtain ⟨h1, h2⟩ := pend_unique (fun s => θ (2 * t₀ - s)) (fun s => -ω (2 * t₀ - s)) θ ω
    hA hB hθ hω t₀ (by simp only [he]) (by simp only [he, h0, neg_zero]) t
  exact ⟨h1, by linarith⟩

#print axioms pend_reflect

lemma pend_lin_lower (f f' : ℝ → ℝ) (hf : ∀ t, HasDerivAt f (f' t) t) (s C : ℝ)
    (h : ∀ t, s ≤ t → C ≤ f' t) (t : ℝ) (ht : s ≤ t) : f s + C * (t - s) ≤ f t := by
  have := (convex_Ici s).mul_sub_le_image_sub_of_le_deriv (f := f)
    (fun x _ => (hf x).continuousAt.continuousWithinAt)
    (fun x _ => (hf x).differentiableAt.differentiableWithinAt)
    (C := C) (fun x hx => by
      rw [interior_Ici] at hx
      rw [(hf x).deriv]
      exact h x (le_of_lt hx))
    s (Set.mem_Ici.2 le_rfl) t ht ht
  linarith

#print axioms pend_lin_lower

lemma pend_lin_upper (f f' : ℝ → ℝ) (hf : ∀ t, HasDerivAt f (f' t) t) (s C : ℝ)
    (h : ∀ t, s ≤ t → f' t ≤ C) (t : ℝ) (ht : s ≤ t) : f t ≤ f s + C * (t - s) := by
  have := pend_lin_lower (fun x => -f x) (fun x => -f' x) (fun x => (hf x).fun_neg) s (-C)
    (fun x hx => by linarith [h x hx]) t ht
  linarith

#print axioms pend_lin_upper

lemma pend_no_pos_forever (θ ω : ℝ → ℝ) (hθ : ∀ t, HasDerivAt θ (ω t) t)
    (hω : ∀ t, HasDerivAt ω (-Real.sin (θ t)) t) (hwell : ∀ t, |θ t| < π)
    (hE : pendulumEnergy (θ 0) (ω 0) < 2) (s : ℝ) (hpos : ∀ t, s ≤ t → 0 < ω t) : False := by
  set e := pendulumEnergy (θ 0) (ω 0) with he
  have hEt : ∀ t, ω t ^ 2 / 2 + 1 - Real.cos (θ t) = e := fun t =>
    pend_energy_const θ ω hθ hω t 0
  have hcos : ∀ t, 1 - e ≤ Real.cos (θ t) := fun t => by nlinarith [hEt t, sq_nonneg (ω t)]
  have hmono : ∀ a b, s ≤ a → a ≤ b → θ a ≤ θ b := fun a b ha hab => by
    have := pend_lin_lower θ ω hθ a 0 (fun t ht => (hpos t (ha.trans ht)).le) b hab
    linarith
  by_cases hcase : ∃ t₁, s ≤ t₁ ∧ 0 < θ t₁
  · obtain ⟨t₁, hs1, hp⟩ := hcase
    have hw1 := abs_lt.1 (hwell t₁)
    have hc1 : Real.cos (θ t₁) < 1 := by
      have := Real.cos_lt_cos_of_nonneg_of_le_pi le_rfl hw1.2.le hp
      simpa using this
    have hlo : -1 < 1 - e := by linarith [hcos t₁]
    set q := max (Real.cos (θ t₁) ^ 2) ((1 - e) ^ 2) with hq
    have hq1 : q < 1 := by
      apply max_lt
      · nlinarith [hcos t₁]
      · nlinarith [hcos t₁]
    have hder : ∀ t, t₁ ≤ t → -Real.sin (θ t) ≤ -(1 - q) := by
      intro t ht
      have hθt : θ t₁ ≤ θ t := hmono t₁ t hs1 ht
      have hwt := abs_lt.1 (hwell t)
      have hct : Real.cos (θ t) ≤ Real.cos (θ t₁) :=
        Real.cos_le_cos_of_nonneg_of_le_pi hp.le hwt.2.le hθt
      have hsq : Real.cos (θ t) ^ 2 ≤ q := by
        rcases le_total 0 (Real.cos (θ t)) with h | h
        · exact le_trans (by nlinarith) (le_max_left _ _)
        · exact le_trans (by nlinarith [hcos t]) (le_max_right _ _)
      have hsp : 0 < Real.sin (θ t) := Real.sin_pos_of_pos_of_lt_pi (by linarith) hwt.2
      have hs1' : Real.sin (θ t) ≤ 1 := Real.sin_le_one _
      have := Real.sin_sq_add_cos_sq (θ t)
      nlinarith
    have hup := pend_lin_upper ω (fun t => -Real.sin (θ t)) hω t₁ (-(1 - q)) hder
    set t := t₁ + ω t₁ / (1 - q) + 1 with htdef
    have hq0 : 0 < 1 - q := by linarith
    have ht1 : t₁ ≤ t := by
      have := (div_pos (hpos t₁ hs1) hq0).le
      linarith
    have h1 := hup t ht1
    have h2 : (1 - q) * (t - t₁) = ω t₁ + (1 - q) := by
      rw [htdef]; field_simp; ring
    have h3 := hpos t (hs1.trans ht1)
    nlinarith
  · push Not at hcase
    have hs := abs_lt.1 (hwell s)
    have hlow : ∀ t, s ≤ t → ω s ≤ ω t := by
      intro t ht
      have hθt : θ s ≤ θ t := hmono s t le_rfl ht
      have hθ0 : θ t ≤ 0 := hcase t ht
      have hc : Real.cos (θ s) ≤ Real.cos (θ t) := by
        rw [← Real.cos_neg (θ s), ← Real.cos_neg (θ t)]
        exact Real.cos_le_cos_of_nonneg_of_le_pi (by linarith) (by linarith) (by linarith)
      have h1 := hEt s
      have h2 := hEt t
      have := hpos s le_rfl
      have := hpos t ht
      nlinarith
    have hgrow := pend_lin_lower θ ω hθ s (ω s) hlow
    have hws := hpos s le_rfl
    set t := s + (-θ s) / ω s + 1 with htdef
    have ht1 : s ≤ t := by
      have : 0 ≤ (-θ s) / ω s := div_nonneg (by linarith [hcase s le_rfl]) hws.le
      linarith
    have h1 := hgrow t ht1
    have h2 : ω s * (t - s) = -θ s + ω s := by
      rw [htdef]; field_simp; ring
    have := hcase t ht1
    nlinarith

#print axioms pend_no_pos_forever

lemma pend_neg_sol (θ ω : ℝ → ℝ) (hθ : ∀ t, HasDerivAt θ (ω t) t)
    (hω : ∀ t, HasDerivAt ω (-Real.sin (θ t)) t) :
    (∀ t, HasDerivAt (fun t => -θ t) (-ω t) t) ∧
    (∀ t, HasDerivAt (fun t => -ω t) (-Real.sin (-θ t)) t) :=
  ⟨fun t => (hθ t).fun_neg, fun t => by simpa [Real.sin_neg] using (hω t).fun_neg⟩

#print axioms pend_neg_sol

lemma pend_zero_after (θ ω : ℝ → ℝ) (hθ : ∀ t, HasDerivAt θ (ω t) t)
    (hω : ∀ t, HasDerivAt ω (-Real.sin (θ t)) t) (hwell : ∀ t, |θ t| < π)
    (hE : pendulumEnergy (θ 0) (ω 0) < 2) (s : ℝ) : ∃ t, s ≤ t ∧ ω t = 0 := by
  by_contra hne
  push Not at hne
  have hcont : Continuous ω := continuous_iff_continuousAt.2 fun t => (hω t).continuousAt
  rcases lt_or_gt_of_ne (hne s le_rfl) with hneg | hpos
  · obtain ⟨hA, hB⟩ := pend_neg_sol θ ω hθ hω
    apply pend_no_pos_forever (fun t => -θ t) (fun t => -ω t) hA hB
      (fun t => by simpa [abs_neg] using hwell t)
      (by simpa [pendulumEnergy, Real.cos_neg] using hE) s
    intro t ht
    by_contra hc
    push Not at hc
    obtain ⟨c, hc1, hc2⟩ := intermediate_value_Icc ht hcont.continuousOn
      (show (0:ℝ) ∈ Set.Icc (ω s) (ω t) from ⟨hneg.le, by simp at hc; linarith⟩)
    exact hne c hc1.1 hc2
  · apply pend_no_pos_forever θ ω hθ hω hwell hE s
    intro t ht
    by_contra hc
    push Not at hc
    obtain ⟨c, hc1, hc2⟩ := intermediate_value_Icc' ht hcont.continuousOn
      (show (0:ℝ) ∈ Set.Icc (ω t) (ω s) from ⟨hc, hpos.le⟩)
    exact hne c hc1.1 hc2

#print axioms pend_zero_after

lemma pend_spin_pos (θ ω : ℝ → ℝ) (hθ : ∀ t, HasDerivAt θ (ω t) t)
    (hω : ∀ t, HasDerivAt ω (-Real.sin (θ t)) t)
    (hE : 2 < pendulumEnergy (θ 0) (ω 0)) (h0 : 0 < ω 0) :
    ∃ T > 0, ∀ t, 0 < ω t ∧ θ (t + T) = θ t + 2 * π ∧ ω (t + T) = ω t := by
  set e := pendulumEnergy (θ 0) (ω 0) with he
  have hEt : ∀ t, ω t ^ 2 / 2 + 1 - Real.cos (θ t) = e := fun t =>
    pend_energy_const θ ω hθ hω t 0
  have hsq : ∀ t, 2 * (e - 2) ≤ ω t ^ 2 := fun t => by
    nlinarith [hEt t, Real.neg_one_le_cos (θ t)]
  have hne : ∀ t, ω t ≠ 0 := fun t h => by
    have := hsq t
    rw [h] at this
    linarith
  have hcont : Continuous ω := continuous_iff_continuousAt.2 fun t => (hω t).continuousAt
  have hθc : Continuous θ := continuous_iff_continuousAt.2 fun t => (hθ t).continuousAt
  have hpos : ∀ t, 0 < ω t := by
    intro t
    by_contra hc
    push Not at hc
    rcases le_total 0 t with h | h
    · obtain ⟨c, _, hc2⟩ := intermediate_value_Icc' h hcont.continuousOn
        (show (0:ℝ) ∈ Set.Icc (ω t) (ω 0) from ⟨hc, h0.le⟩)
      exact hne c hc2
    · obtain ⟨c, _, hc2⟩ := intermediate_value_Icc h hcont.continuousOn
        (show (0:ℝ) ∈ Set.Icc (ω t) (ω 0) from ⟨hc, h0.le⟩)
      exact hne c hc2
  set c := Real.sqrt (2 * (e - 2)) with hcdef
  have hc : 0 < c := Real.sqrt_pos.2 (by linarith)
  have hlow : ∀ t, c ≤ ω t := fun t => by
    rw [show ω t = Real.sqrt (ω t ^ 2) from (Real.sqrt_sq (hpos t).le).symm]
    exact Real.sqrt_le_sqrt (hsq t)
  have hL : (0:ℝ) ≤ 2 * π / c := by positivity
  have hgrow := pend_lin_lower θ ω hθ 0 c (fun t _ => hlow t) (2 * π / c) hL
  have hcc : c * (2 * π / c - 0) = 2 * π := by rw [sub_zero]; field_simp
  obtain ⟨T, hT1, hT2⟩ := intermediate_value_Icc hL hθc.continuousOn
    (show θ 0 + 2 * π ∈ Set.Icc (θ 0) (θ (2 * π / c)) from
      ⟨by linarith [Real.pi_pos], by linarith⟩)
  have hTpos : 0 < T := by
    rcases eq_or_lt_of_le hT1.1 with h | h
    · rw [← h] at hT2
      linarith [Real.pi_pos]
    · exact h
  have hωT : ω T = ω 0 := by
    have h1 := hEt T
    have h2 := hEt 0
    have hcosT : Real.cos (θ T) = Real.cos (θ 0) := by rw [hT2]; exact Real.cos_add_two_pi _
    rw [hcosT] at h1
    have h3 : ω T ^ 2 = ω 0 ^ 2 := by linarith
    have := hpos T
    nlinarith
  refine ⟨T, hTpos, fun t => ⟨hpos t, ?_⟩⟩
  have hA : ∀ s, HasDerivAt (fun s => θ (s + T) - 2 * π) (ω (s + T)) s := fun s =>
    ((hθ (s + T)).comp_add_const s T).sub_const (2 * π)
  have hB : ∀ s, HasDerivAt (fun s => ω (s + T)) (-Real.sin (θ (s + T) - 2 * π)) s :=
    fun s => by simpa [Real.sin_sub_two_pi] using (hω (s + T)).comp_add_const s T
  obtain ⟨h1, h2⟩ := pend_unique _ _ θ ω hA hB hθ hω 0 (by simp [hT2]) (by simpa using hωT) t
  exact ⟨by linarith, h2⟩

#print axioms pend_spin_pos

lemma pend_cos_eq_neg_one (x : ℝ) (n : ℤ) (h : |x - 2 * π * n| = π) : Real.cos x = -1 := by
  rcases (abs_eq Real.pi_pos.le).1 h with h' | h'
  · have hx : x = π + n * (2 * π) := by linarith
    rw [hx, Real.cos_add_int_mul_two_pi, Real.cos_pi]
  · have hx : x = -π + n * (2 * π) := by linarith
    rw [hx, Real.cos_add_int_mul_two_pi, Real.cos_neg, Real.cos_pi]

#print axioms pend_cos_eq_neg_one

lemma pend_int_lower (k : ℝ) (hk0 : 0 < k) (hk1 : k < 1) :
    -Real.log (1 - k ^ 2) / 2 ≤
      ∫ φ in (0 : ℝ)..(π / 2), 1 / Real.sqrt (1 - k ^ 2 * Real.sin φ ^ 2) := by
  have hk2 : 0 < 1 - k ^ 2 := by nlinarith
  set s := Real.sqrt (1 - k ^ 2) with hs
  have hs0 : 0 < s := Real.sqrt_pos.2 hk2
  have hs2 : s ^ 2 = 1 - k ^ 2 := Real.sq_sqrt hk2.le
  have hpos : ∀ φ, 0 < 1 - k ^ 2 * Real.sin φ ^ 2 := fun φ => by
    have := Real.sin_sq_le_one φ
    nlinarith [sq_nonneg (Real.sin φ)]
  have hcont : Continuous (fun φ => 1 / Real.sqrt (1 - k ^ 2 * Real.sin φ ^ 2)) :=
    Continuous.div continuous_const (by fun_prop) (fun φ => (Real.sqrt_pos.2 (hpos φ)).ne')
  have hpi : (0:ℝ) ≤ π / 2 := by positivity
  have hmono : ∫ φ in (0:ℝ)..(π / 2), (s + π / 2 - φ)⁻¹ ≤
      ∫ φ in (0 : ℝ)..(π / 2), 1 / Real.sqrt (1 - k ^ 2 * Real.sin φ ^ 2) := by
    apply intervalIntegral.integral_mono_on hpi
    · apply ContinuousOn.intervalIntegrable
      apply ContinuousOn.inv₀ (by fun_prop)
      intro φ hφ
      rw [Set.uIcc_of_le hpi] at hφ
      have := hφ.2
      apply ne_of_gt
      linarith
    · exact hcont.intervalIntegrable _ _
    · intro φ hφ
      set x := π / 2 - φ with hxdef
      have hx0 : 0 ≤ x := by linarith [hφ.2]
      have hx1 : x ≤ π / 2 := by linarith [hφ.1]
      have hsin : Real.sin φ = Real.cos x := by rw [hxdef, Real.cos_pi_div_two_sub]
      have hsx : Real.sin x ≤ x := Real.sin_le hx0
      have hsx0 : 0 ≤ Real.sin x :=
        Real.sin_nonneg_of_nonneg_of_le_pi hx0 (by linarith [Real.pi_pos])
      have h1 : Real.sin x ^ 2 ≤ x ^ 2 := pow_le_pow_left₀ hsx0 hsx 2
      have h2 : k ^ 2 * Real.sin x ^ 2 ≤ Real.sin x ^ 2 := by nlinarith [sq_nonneg (Real.sin x)]
      have h3 : k ^ 2 * Real.cos x ^ 2 = k ^ 2 - k ^ 2 * Real.sin x ^ 2 := by
        rw [Real.cos_sq']; ring
      have hkey : 1 - k ^ 2 * Real.sin φ ^ 2 ≤ (s + x) ^ 2 := by
        rw [hsin]
        nlinarith [mul_nonneg hs0.le hx0]
      have hsq : Real.sqrt (1 - k ^ 2 * Real.sin φ ^ 2) ≤ s + x :=
        Real.sqrt_le_iff.2 ⟨by positivity, hkey⟩
      rw [inv_eq_one_div, show s + π / 2 - φ = s + x by rw [hxdef]; ring]
      exact one_div_le_one_div_of_le (Real.sqrt_pos.2 (hpos φ)) hsq
  have heval : ∫ φ in (0:ℝ)..(π / 2), (s + π / 2 - φ)⁻¹ = Real.log ((s + π / 2) / s) := by
    have := intervalIntegral.integral_comp_sub_left (a := 0) (b := π / 2)
      (f := fun x : ℝ => x⁻¹) (s + π / 2)
    rw [this, show s + π / 2 - π / 2 = s by ring, show s + π / 2 - 0 = s + π / 2 by ring]
    exact integral_inv_of_pos hs0 (by positivity)
  have hlog : -Real.log (1 - k ^ 2) / 2 ≤ Real.log ((s + π / 2) / s) := by
    have h1 : Real.log s = Real.log (1 - k ^ 2) / 2 := by rw [hs, Real.log_sqrt hk2.le]
    have h2 : Real.log (1 / s) ≤ Real.log ((s + π / 2) / s) := by
      apply Real.log_le_log (by positivity)
      gcongr
      linarith [Real.pi_gt_three]
    rw [one_div, Real.log_inv, h1] at h2
    linarith
  linarith

#print axioms pend_int_lower

/-- Without friction (`θ' = ω`, `ω' = -sin θ`, time in units of `√(l/g)`), the energy never
changes along a motion. Below energy 2, the energy of standing on end, the motion is a swing:
the angle stays inside one well, never reaching upside down, and the motion repeats with some
period. Above energy 2 it is a full rotation: the angular speed never reaches zero and keeps
one sign, and after some fixed time the angle has gained one full turn `2π` (or lost one) while
the speed is back where it was. -/
theorem pendulum_swing_below_two_spin_above_two (θ ω : ℝ → ℝ)
    (hθ : ∀ t, HasDerivAt θ (ω t) t)
    (hω : ∀ t, HasDerivAt ω (-Real.sin (θ t)) t) :
    (∀ t, pendulumEnergy (θ t) (ω t) = pendulumEnergy (θ 0) (ω 0)) ∧
    (pendulumEnergy (θ 0) (ω 0) < 2 →
      (∃ n : ℤ, ∀ t, |θ t - 2 * π * n| < π) ∧
      ∃ T > 0, ∀ t, θ (t + T) = θ t ∧ ω (t + T) = ω t) ∧
    (2 < pendulumEnergy (θ 0) (ω 0) →
      ∃ T > 0,
        (∀ t, 0 < ω t ∧ θ (t + T) = θ t + 2 * π ∧ ω (t + T) = ω t) ∨
        (∀ t, ω t < 0 ∧ θ (t + T) = θ t - 2 * π ∧ ω (t + T) = ω t)) := by
  have hEt : ∀ t, pendulumEnergy (θ t) (ω t) = pendulumEnergy (θ 0) (ω 0) := fun t =>
    pend_energy_const θ ω hθ hω t 0
  refine ⟨hEt, fun hE => ?_, fun hE => ?_⟩
  · have hcos : ∀ t, -1 < Real.cos (θ t) := fun t => by
      have := hEt t
      simp only [pendulumEnergy] at this hE
      nlinarith [sq_nonneg (ω t), sq_nonneg (ω 0)]
    set n : ℤ := round (θ 0 / (2 * π)) with hn
    have h0 : |θ 0 - 2 * π * n| < π := by
      have hr := abs_sub_round (θ 0 / (2 * π))
      have hle : |θ 0 - 2 * π * n| ≤ π := by
        have he : θ 0 - 2 * π * n = 2 * π * (θ 0 / (2 * π) - n) := by
          field_simp
        rw [he, abs_mul, abs_of_pos (by positivity)]
        nlinarith [Real.pi_pos]
      rcases lt_or_eq_of_le hle with h | h
      · exact h
      · exact absurd (pend_cos_eq_neg_one _ _ h) (ne_of_gt (hcos 0))
    have hθc : Continuous θ := continuous_iff_continuousAt.2 fun t => (hθ t).continuousAt
    have hwell : ∀ t, |θ t - 2 * π * n| < π := by
      intro t
      by_contra hc
      push Not at hc
      have hg : Continuous (fun t => |θ t - 2 * π * n|) := by fun_prop
      obtain ⟨c, _, hc2⟩ := intermediate_value_uIcc (a := 0) (b := t) hg.continuousOn
        (show π ∈ Set.uIcc |θ 0 - 2 * π * n| |θ t - 2 * π * n| from
          Set.mem_uIcc.2 (Or.inl ⟨h0.le, hc⟩))
      exact absurd (pend_cos_eq_neg_one _ _ hc2) (ne_of_gt (hcos c))
    refine ⟨⟨n, hwell⟩, ?_⟩
    have hA : ∀ t, HasDerivAt (fun t => θ t - 2 * π * n) (ω t) t := fun t =>
      (hθ t).sub_const _
    have hsn : ∀ x : ℝ, Real.sin (x - 2 * π * n) = Real.sin x := fun x => by
      rw [show 2 * π * (n : ℝ) = n * (2 * π) by ring, Real.sin_sub_int_mul_two_pi]
    have hB : ∀ t, HasDerivAt ω (-Real.sin (θ t - 2 * π * n)) t := fun t => by
      rw [hsn]; exact hω t
    have hE' : pendulumEnergy (θ 0 - 2 * π * n) (ω 0) < 2 := by
      have : Real.cos (θ 0 - 2 * π * n) = Real.cos (θ 0) := by
        rw [show 2 * π * (n : ℝ) = n * (2 * π) by ring, Real.cos_sub_int_mul_two_pi]
      simp only [pendulumEnergy, this] at hE ⊢
      exact hE
    obtain ⟨t₀, ht₀, hz₀⟩ := pend_zero_after _ ω hA hB hwell hE' 0
    obtain ⟨t₁, ht₁, hz₁⟩ := pend_zero_after _ ω hA hB hwell hE' (t₀ + 1)
    refine ⟨2 * (t₁ - t₀), by linarith, fun t => ?_⟩
    obtain ⟨a1, a2⟩ := pend_reflect θ ω hθ hω t₀ hz₀ t
    obtain ⟨b1, b2⟩ := pend_reflect θ ω hθ hω t₁ hz₁ (t + 2 * (t₁ - t₀))
    have he : 2 * t₁ - (t + 2 * (t₁ - t₀)) = 2 * t₀ - t := by ring
    rw [he] at b1 b2
    exact ⟨by rw [← b1, a1], by linarith⟩
  · have hw0 : ω 0 ≠ 0 := by
      intro h
      simp only [pendulumEnergy, h] at hE
      nlinarith [Real.neg_one_le_cos (θ 0)]
    rcases lt_or_gt_of_ne hw0 with hneg | hpos
    · obtain ⟨hA, hB⟩ := pend_neg_sol θ ω hθ hω
      obtain ⟨T, hT, h⟩ := pend_spin_pos (fun t => -θ t) (fun t => -ω t) hA hB
        (by simpa [pendulumEnergy, Real.cos_neg] using hE) (by simp; linarith)
      refine ⟨T, hT, Or.inr fun t => ?_⟩
      obtain ⟨h1, h2, h3⟩ := h t
      exact ⟨by linarith, by linarith, by linarith⟩
    · exact let ⟨T, hT, h⟩ := pend_spin_pos θ ω hθ hω hE hpos; ⟨T, hT, Or.inl h⟩

/-- At energy exactly 2 the motion runs along the separatrix `ω = ± 2 cos(θ/2)`, and a motion
on it that starts with nonzero speed never reaches zero speed: it creeps toward standing on
end and never arrives. -/
theorem pendulum_separatrix (θ ω : ℝ → ℝ)
    (hθ : ∀ t, HasDerivAt θ (ω t) t)
    (hω : ∀ t, HasDerivAt ω (-Real.sin (θ t)) t)
    (hE : pendulumEnergy (θ 0) (ω 0) = 2) :
    (∀ t, ω t = 2 * Real.cos (θ t / 2) ∨ ω t = -(2 * Real.cos (θ t / 2))) ∧
    (ω 0 ≠ 0 → ∀ t, ω t ≠ 0) := by
  have hEt : ∀ t, ω t ^ 2 / 2 + 1 - Real.cos (θ t) = 2 := fun t => by
    have h := pend_energy_const θ ω hθ hω t 0
    rw [hE] at h
    simp only [pendulumEnergy] at h
    linarith
  have hsq : ∀ t, ω t ^ 2 = (2 * Real.cos (θ t / 2)) ^ 2 := fun t => by
    have hc := Real.cos_two_mul (θ t / 2)
    rw [show 2 * (θ t / 2) = θ t by ring] at hc
    have := hEt t
    nlinarith
  refine ⟨fun t => sq_eq_sq_iff_eq_or_eq_neg.1 (hsq t), fun h0 t ht => h0 ?_⟩
  have hc2 : Real.cos (θ t / 2) = 0 := by
    have := hsq t
    rw [ht] at this
    nlinarith [sq_nonneg (Real.cos (θ t / 2))]
  have hc := Real.cos_two_mul (θ t / 2)
  rw [show 2 * (θ t / 2) = θ t by ring, hc2] at hc
  have hsin : Real.sin (θ t) = 0 := by
    have h := Real.sin_sq_add_cos_sq (θ t)
    rw [hc] at h
    have : Real.sin (θ t) ^ 2 = 0 := by nlinarith
    exact pow_eq_zero_iff (two_ne_zero) |>.1 this
  have hA : ∀ s : ℝ, HasDerivAt (fun _ : ℝ => θ t) ((fun _ : ℝ => (0:ℝ)) s) s := fun s =>
    hasDerivAt_const s (θ t)
  have hB : ∀ s : ℝ, HasDerivAt (fun _ : ℝ => (0:ℝ)) (-Real.sin ((fun _ : ℝ => θ t) s)) s :=
    fun s => by
      simp only [hsin, neg_zero]
      exact hasDerivAt_const s (0:ℝ)
  exact (pend_unique θ ω _ _ hθ hω hA hB t rfl ht 0).2

/-- The period integral `T(k) = 4 ∫₀^{π/2} dφ / √(1 - k² sin² φ)`: every real swing
(`0 < k < 1`) is slower than the small-angle period `2π`, and the period grows without bound
as `k` nears 1, the swing that reaches standing on end. -/
theorem pendulum_period_exceeds_small_angle :
    (∀ k : ℝ, 0 < k → k < 1 →
      2 * π < 4 * ∫ φ in (0 : ℝ)..(π / 2), 1 / Real.sqrt (1 - k ^ 2 * Real.sin φ ^ 2)) ∧
    Tendsto (fun k : ℝ => 4 * ∫ φ in (0 : ℝ)..(π / 2), 1 / Real.sqrt (1 - k ^ 2 * Real.sin φ ^ 2))
      (𝓝[<] 1) atTop := by
  refine ⟨fun k hk0 hk1 => ?_, ?_⟩
  · have hpos : ∀ φ, 0 < 1 - k ^ 2 * Real.sin φ ^ 2 := fun φ => by
      have := Real.sin_sq_le_one φ
      nlinarith [sq_nonneg (Real.sin φ)]
    have hcont : Continuous (fun φ => 1 / Real.sqrt (1 - k ^ 2 * Real.sin φ ^ 2)) :=
      Continuous.div continuous_const (by fun_prop) (fun φ => (Real.sqrt_pos.2 (hpos φ)).ne')
    have hlt := intervalIntegral.integral_lt_integral_of_continuousOn_of_le_of_exists_lt
      (f := fun _ => (1:ℝ)) (g := fun φ => 1 / Real.sqrt (1 - k ^ 2 * Real.sin φ ^ 2))
      (by positivity : (0:ℝ) < π / 2) continuousOn_const hcont.continuousOn
      (fun φ _ => by
        rw [le_div_iff₀ (Real.sqrt_pos.2 (hpos φ)), one_mul]
        apply Real.sqrt_le_one.mpr
        nlinarith [sq_nonneg (Real.sin φ), sq_nonneg k])
      ⟨π / 2, ⟨by positivity, le_rfl⟩, by
        simp only [Real.sin_pi_div_two, one_pow, mul_one]
        rw [lt_div_iff₀ (Real.sqrt_pos.2 (by nlinarith)), one_mul]
        exact (Real.sqrt_lt' one_pos).2 (by nlinarith)⟩
    simp only [intervalIntegral.integral_const, sub_zero, smul_eq_mul, mul_one] at hlt
    linarith
  · have h1 : Tendsto (fun k : ℝ => 1 - k ^ 2) (𝓝[<] 1) (𝓝[>] 0) := by
      apply tendsto_nhdsWithin_iff.2
      refine ⟨?_, ?_⟩
      · have : Tendsto (fun k : ℝ => 1 - k ^ 2) (𝓝 1) (𝓝 (1 - 1 ^ 2)) :=
          (continuous_const.sub (continuous_pow 2)).tendsto 1
        simpa using this.mono_left nhdsWithin_le_nhds
      · filter_upwards [Ioo_mem_nhdsLT (show (0:ℝ) < 1 by norm_num)] with k hk
        simp only [Set.mem_Ioi]
        nlinarith [hk.1, hk.2]
    have h2 : Tendsto (fun k : ℝ => -Real.log (1 - k ^ 2) / 2 * 4) (𝓝[<] 1) atTop := by
      apply Tendsto.atTop_mul_const (by norm_num)
      apply Tendsto.atTop_div_const (by norm_num)
      exact tendsto_neg_atBot_atTop.comp (Real.tendsto_log_nhdsGT_zero.comp h1)
    apply tendsto_atTop_mono' _ _ h2
    filter_upwards [Ioo_mem_nhdsLT (show (0:ℝ) < 1 by norm_num)] with k hk
    have := pend_int_lower k hk.1 hk.2
    linarith

-- Worked numbers. Released at rest from 60 degrees: energy 1/2.
example : pendulumEnergy (π / 3) 0 = 1 / 2 := by
  simp [pendulumEnergy, Real.cos_pi_div_three]; norm_num
-- Standing on end at rest: energy 2.
example : pendulumEnergy π 0 = 2 := by
  simp [pendulumEnergy]; norm_num
-- k = sin 30 degrees = 1/2, and k² = E / 2 = 1/4.
example : Real.sin (π / 6) = 1 / 2 ∧ (1 / 2 : ℝ) ^ 2 = (1 / 2) / 2 := by
  refine ⟨Real.sin_pi_div_six, by norm_num⟩
-- A push of 2 units at the bottom has energy 2: just enough to reach the top.
example : pendulumEnergy 0 2 = 2 := by
  simp [pendulumEnergy]; norm_num
-- A push of 5/2 units has energy 25/8, and speed 3/2 at the top: 2 (25/8 - 2) = (3/2)².
example : pendulumEnergy 0 (5 / 2) = 25 / 8 ∧ (2 : ℝ) * (25 / 8 - 2) = (3 / 2) ^ 2 := by
  refine ⟨?_, by norm_num⟩
  simp [pendulumEnergy]; norm_num
-- The mistake: a push of √2 units (aiming one rod length up) has energy 1, turning back at 90 degrees.
example : pendulumEnergy 0 (Real.sqrt 2) = 1 ∧ Real.cos (π / 2) = 1 - 1 := by
  refine ⟨?_, by simp⟩
  simp [pendulumEnergy]

#print axioms pendulum_swing_below_two_spin_above_two
#print axioms pendulum_separatrix
#print axioms pendulum_period_exceeds_small_angle
