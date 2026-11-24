-- Compressible flow: for an ideal gas with fixed γ > 1, the area a nozzle needs shrinks with Mach number below Mach 1 and grows above it, with its smallest value A* at exactly Mach 1, and the three conservation laws across a normal shock give either no change or the card's jump, which takes supersonic flow to subsonic, compresses it and loses stagnation pressure.
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Order.Monotone.Defs
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib.Tactic.Linarith
import Mathlib.Analysis.SpecialFunctions.Pow.Deriv
import Mathlib.Analysis.SpecialFunctions.Log.Deriv
import Mathlib.Analysis.Calculus.Deriv.MeanValue
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.LinearCombination
import Mathlib.Tactic.Positivity

open Real

/-- The temperature ratio T0/T = 1 + ((γ - 1)/2) M² at Mach number M. -/
noncomputable def stagTempRatio (γ M : ℝ) : ℝ := 1 + (γ - 1) / 2 * M ^ 2

/-- The area rule: A/A* = (1/M) · [(2/(γ + 1)) (1 + ((γ - 1)/2) M²)]^((γ + 1)/(2(γ - 1))),
the flow area needed at Mach number M compared with the area A* where the flow is at Mach 1. -/
noncomputable def areaRatio (γ M : ℝ) : ℝ :=
  1 / M * (2 / (γ + 1) * stagTempRatio γ M) ^ ((γ + 1) / (2 * (γ - 1)))

/-- The Mach number squared just after a normal shock:
M₂² = (1 + ((γ - 1)/2) M₁²) / (γ M₁² - (γ - 1)/2). -/
noncomputable def shockMach2Sq (γ M₁ : ℝ) : ℝ :=
  (1 + (γ - 1) / 2 * M₁ ^ 2) / (γ * M₁ ^ 2 - (γ - 1) / 2)

/-- The static pressure ratio across a normal shock: p₂/p₁ = 1 + (2γ/(γ + 1)) (M₁² - 1). -/
noncomputable def shockPressureRatio (γ M₁ : ℝ) : ℝ := 1 + 2 * γ / (γ + 1) * (M₁ ^ 2 - 1)

/-- The density ratio across a normal shock: ρ₂/ρ₁ = (γ + 1) M₁² / ((γ - 1) M₁² + 2). -/
noncomputable def shockDensityRatio (γ M₁ : ℝ) : ℝ := (γ + 1) * M₁ ^ 2 / ((γ - 1) * M₁ ^ 2 + 2)

/-- The share of stagnation pressure a normal shock keeps, p₀₂/p₀₁. The stagnation temperature is
the same on both sides, so p₀₂/p₀₁ = (p₂/p₁) · ((T₀/T₂)/(T₀/T₁))^(γ/(γ - 1))
= (p₂/p₁) · (stagTempRatio γ M₂ / stagTempRatio γ M₁)^(γ/(γ - 1)). -/
noncomputable def shockStagPressureKept (γ M₁ : ℝ) : ℝ :=
  shockPressureRatio γ M₁ *
    ((1 + (γ - 1) / 2 * shockMach2Sq γ M₁) / stagTempRatio γ M₁) ^ (γ / (γ - 1))

lemma areaRatio_hasDerivAt (γ M : ℝ) (hγ : 1 < γ) (hM : 0 < M) :
    HasDerivAt (areaRatio γ)
      ((2 / (γ + 1) * stagTempRatio γ M) ^ ((γ + 1) / (2 * (γ - 1)) - 1) * (2 / (γ + 1)) *
        ((M ^ 2 - 1) / M ^ 2)) M := by
  have hY : HasDerivAt (fun x => 2 / (γ + 1) * stagTempRatio γ x)
      (2 / (γ + 1) * ((γ - 1) / 2 * (2 * M))) M := by
    unfold stagTempRatio
    have := (((hasDerivAt_pow 2 M).const_mul ((γ - 1) / 2)).const_add 1).const_mul (2 / (γ + 1))
    convert this using 1
    push_cast; ring
  have hk : 0 < (γ - 1) / 2 := by linarith
  have hc : 0 < 2 / (γ + 1) := by positivity
  have hYpos : 0 < 2 / (γ + 1) * stagTempRatio γ M := by
    unfold stagTempRatio; positivity
  have hR := hY.rpow_const (p := (γ + 1) / (2 * (γ - 1))) (Or.inl hYpos.ne')
  have hP := (hasDerivAt_inv hM.ne').mul hR
  have heq : areaRatio γ = fun y => y⁻¹ * (2 / (γ + 1) * stagTempRatio γ y) ^ ((γ + 1) / (2 * (γ - 1))) := by
    funext y; simp [areaRatio, one_div]
  rw [heq]
  convert hP using 1
  rw [Real.rpow_sub_one hYpos.ne']
  generalize (2 / (γ + 1) * stagTempRatio γ M) ^ ((γ + 1) / (2 * (γ - 1))) = Z
  have hγ1 : γ - 1 ≠ 0 := by linarith
  have hγ2 : γ + 1 ≠ 0 := by linarith
  unfold stagTempRatio at hYpos ⊢
  field_simp
  ring

#print axioms areaRatio_hasDerivAt

lemma areaRatio_deriv_factor_pos (γ M : ℝ) (hγ : 1 < γ) (hM : 0 < M) :
    0 < (2 / (γ + 1) * stagTempRatio γ M) ^ ((γ + 1) / (2 * (γ - 1)) - 1) * (2 / (γ + 1)) := by
  have hk : 0 < (γ - 1) / 2 := by linarith
  have hc : 0 < 2 / (γ + 1) := by positivity
  have hYpos : 0 < 2 / (γ + 1) * stagTempRatio γ M := by
    unfold stagTempRatio; positivity
  exact mul_pos (Real.rpow_pos_of_pos hYpos _) hc

#print axioms areaRatio_deriv_factor_pos

lemma shock_entropy_pos (γ m : ℝ) (hγ : 1 < γ) (hm : 1 < m) :
    γ * Real.log ((γ + 1) * m) - γ * Real.log ((γ - 1) * m + 2) <
      Real.log (1 + 2 * γ / (γ + 1) * (m - 1)) := by
  have hγ0 : 0 < γ := by linarith
  have hγ1 : 0 < γ - 1 := by linarith
  have hderiv : ∀ x : ℝ, 1 ≤ x → HasDerivAt
      (fun x : ℝ => Real.log (1 + 2 * γ / (γ + 1) * (x - 1)) - γ * Real.log ((γ + 1) * x) +
        γ * Real.log ((γ - 1) * x + 2))
      (2 * γ * (γ - 1) * (x - 1) ^ 2 /
        ((2 * γ * x - γ + 1) * x * ((γ - 1) * x + 2))) x := by
    intro x hx
    have hP : 0 < 1 + 2 * γ / (γ + 1) * (x - 1) := by
      have : 0 ≤ 2 * γ / (γ + 1) * (x - 1) := mul_nonneg (by positivity) (by linarith)
      linarith
    have hA : 0 < (γ + 1) * x := by nlinarith
    have hB : 0 < (γ - 1) * x + 2 := by nlinarith
    have h1 : HasDerivAt (fun x : ℝ => 1 + 2 * γ / (γ + 1) * (x - 1)) (2 * γ / (γ + 1) * 1) x :=
      (((hasDerivAt_id x).sub_const 1).const_mul (2 * γ / (γ + 1))).const_add 1
    have h2 : HasDerivAt (fun x : ℝ => (γ + 1) * x) ((γ + 1) * 1) x :=
      (hasDerivAt_id x).const_mul (γ + 1)
    have h3 : HasDerivAt (fun x : ℝ => (γ - 1) * x + 2) ((γ - 1) * 1) x :=
      ((hasDerivAt_id x).const_mul (γ - 1)).add_const 2
    have h := ((h1.log hP.ne').sub ((h2.log hA.ne').const_mul γ)).add ((h3.log hB.ne').const_mul γ)
    convert h using 1
    have hx0 : 0 < x := by linarith
    have hQ : 0 < 2 * γ * x - γ + 1 := by nlinarith
    have hPeq : 1 + 2 * γ / (γ + 1) * (x - 1) = (2 * γ * x - γ + 1) / (γ + 1) := by
      field_simp; ring
    rw [hPeq]
    have hQ' : 2 * γ * x - γ + 1 ≠ 0 := hQ.ne'
    have hA' : γ + 1 ≠ 0 := by linarith
    rw [div_div_eq_mul_div, mul_one, mul_one, mul_one]
    have hx' : x ≠ 0 := hx0.ne'
    have hB' : (γ - 1) * x + 2 ≠ 0 := hB.ne'
    rw [div_mul_cancel₀ (2 * γ) hA', show (γ + 1) / ((γ + 1) * x) = 1 / x by field_simp,
      mul_one_div, ← mul_div_assoc, div_sub_div _ _ hQ' hx',
      div_add_div _ _ (mul_ne_zero hQ' hx') hB',
      div_eq_div_iff (mul_ne_zero (mul_ne_zero hQ' hx') hB') (mul_ne_zero (mul_ne_zero hQ' hx') hB')]
    ring
  have hmono : StrictMonoOn
      (fun x : ℝ => Real.log (1 + 2 * γ / (γ + 1) * (x - 1)) - γ * Real.log ((γ + 1) * x) +
        γ * Real.log ((γ - 1) * x + 2)) (Set.Ici 1) := by
    apply strictMonoOn_of_deriv_pos (convex_Ici 1)
    · intro x hx
      exact (hderiv x hx).continuousAt.continuousWithinAt
    · intro x hx
      rw [interior_Ici] at hx
      have hx1 : 1 < x := hx
      rw [(hderiv x hx1.le).deriv]
      have hQ : 0 < 2 * γ * x - γ + 1 := by nlinarith
      have hB : 0 < (γ - 1) * x + 2 := by nlinarith
      have hx0 : 0 < x := by linarith
      have : 0 < (x - 1) ^ 2 := by nlinarith
      positivity
  have h := hmono (Set.mem_Ici.mpr (le_refl 1)) (Set.mem_Ici.mpr hm.le) hm
  simp only at h
  rw [show (γ - 1) * 1 + 2 = (γ + 1) * 1 by ring] at h
  simp at h
  linarith

#print axioms shock_entropy_pos

/-- Past Mach 1 a nozzle must widen. For an ideal gas with fixed ratio of heat capacities γ > 1,
in one-dimensional isentropic flow, the area ratio A/A* is 1 at Mach 1; below Mach 1 a faster flow
needs a smaller area (A/A* falls as M rises on 0 < M ≤ 1); above Mach 1 a faster flow needs a
larger area (A/A* rises as M rises on M ≥ 1); so no section is smaller than the sonic throat A*,
which is why the throat runs at exactly Mach 1 and caps the mass flow. -/
theorem supersonic_nozzle_must_widen (γ : ℝ) (hγ : 1 < γ) :
    areaRatio γ 1 = 1 ∧
    StrictAntiOn (areaRatio γ) (Set.Ioc 0 1) ∧
    StrictMonoOn (areaRatio γ) (Set.Ici 1) ∧
    ∀ M : ℝ, 0 < M → 1 ≤ areaRatio γ M := by
  have h1 : areaRatio γ 1 = 1 := by
    have : 2 / (γ + 1) * stagTempRatio γ 1 = 1 := by
      unfold stagTempRatio
      field_simp
      ring
    rw [areaRatio, this, Real.one_rpow]
    norm_num
  have hanti : StrictAntiOn (areaRatio γ) (Set.Ioc 0 1) := by
    apply strictAntiOn_of_deriv_neg (convex_Ioc 0 1)
    · intro M hM
      exact (areaRatio_hasDerivAt γ M hγ hM.1).continuousAt.continuousWithinAt
    · intro M hM
      rw [interior_Ioc] at hM
      rw [(areaRatio_hasDerivAt γ M hγ hM.1).deriv]
      apply mul_neg_of_pos_of_neg (areaRatio_deriv_factor_pos γ M hγ hM.1)
      apply div_neg_of_neg_of_pos
      · nlinarith [hM.1, hM.2]
      · nlinarith [hM.1]
  have hmono : StrictMonoOn (areaRatio γ) (Set.Ici 1) := by
    apply strictMonoOn_of_deriv_pos (convex_Ici 1)
    · intro M hM
      exact (areaRatio_hasDerivAt γ M hγ (lt_of_lt_of_le one_pos hM)).continuousAt.continuousWithinAt
    · intro M hM
      rw [interior_Ici] at hM
      have hM0 : 0 < M := lt_trans one_pos hM
      rw [(areaRatio_hasDerivAt γ M hγ hM0).deriv]
      apply mul_pos (areaRatio_deriv_factor_pos γ M hγ hM0)
      apply div_pos
      · have hM1 : 1 < M := hM
        nlinarith [hM1]
      · positivity
  refine ⟨h1, hanti, hmono, ?_⟩
  intro M hM
  rcases le_total M 1 with h | h
  · rw [← h1]
    exact hanti.antitoneOn ⟨hM, h⟩ ⟨one_pos, le_refl 1⟩ h
  · rw [← h1]
    exact hmono.monotoneOn (Set.mem_Ici.mpr (le_refl 1)) h h

/-- A shock keeps mass, momentum and energy, and that forces the jump. Take an ideal gas,
p = ρ R T with R > 0, fixed γ > 1 and c_p = γR/(γ - 1), flowing at speeds V₁, V₂ > 0 with
densities ρ₁, ρ₂ > 0 and temperatures T₁, T₂ > 0 on the two sides of a thin, steady shock. If
ρ₁V₁ = ρ₂V₂, p₁ + ρ₁V₁² = p₂ + ρ₂V₂² and c_p T₁ + V₁²/2 = c_p T₂ + V₂²/2, then either nothing
happens (V₁ = V₂), or V₁V₂ = a*² (Prandtl's relation, with a*² the sound speed squared where the
flow would be sonic, from a²/(γ - 1) + V²/2 = ((γ + 1)/(2(γ - 1))) a*²) and, with Mach numbers
M = V/√(γRT), the card's jump relations hold: M₂² = (1 + ((γ - 1)/2)M₁²)/(γM₁² - (γ - 1)/2),
p₂/p₁ = 1 + (2γ/(γ + 1))(M₁² - 1) and ρ₂/ρ₁ = (γ + 1)M₁²/((γ - 1)M₁² + 2). -/
theorem normal_shock_jump_from_conservation_laws
    (γ R ρ₁ ρ₂ V₁ V₂ T₁ T₂ p₁ p₂ : ℝ) (hγ : 1 < γ) (hR : 0 < R)
    (hρ₁ : 0 < ρ₁) (hρ₂ : 0 < ρ₂) (hV₁ : 0 < V₁) (hV₂ : 0 < V₂) (hT₁ : 0 < T₁) (hT₂ : 0 < T₂)
    (hp₁ : p₁ = ρ₁ * R * T₁) (hp₂ : p₂ = ρ₂ * R * T₂)
    (hmass : ρ₁ * V₁ = ρ₂ * V₂)
    (hmom : p₁ + ρ₁ * V₁ ^ 2 = p₂ + ρ₂ * V₂ ^ 2)
    (henergy : γ * R / (γ - 1) * T₁ + V₁ ^ 2 / 2 = γ * R / (γ - 1) * T₂ + V₂ ^ 2 / 2) :
    let aStarSq := 2 * (γ - 1) / (γ + 1) * (γ * R * T₁ / (γ - 1) + V₁ ^ 2 / 2)
    let M₁ := V₁ / Real.sqrt (γ * R * T₁)
    let M₂ := V₂ / Real.sqrt (γ * R * T₂)
    V₁ = V₂ ∨
      (V₁ * V₂ = aStarSq ∧
        M₂ ^ 2 = shockMach2Sq γ M₁ ∧
        p₂ / p₁ = shockPressureRatio γ M₁ ∧
        ρ₂ / ρ₁ = shockDensityRatio γ M₁) := by
  intro aStarSq M₁ M₂
  have _hρ₂ := hρ₂
  have hγ1 : γ - 1 ≠ 0 := by linarith
  have hγ0 : 0 < γ := by linarith
  have hs : 0 < γ * R * T₁ := by positivity
  have ht : 0 < γ * R * T₂ := by positivity
  -- momentum, divided by the mass flux
  have hMo : V₂ * (R * T₁ + V₁ ^ 2) = V₁ * (R * T₂ + V₂ ^ 2) := by
    have h1 : ρ₁ * (R * T₁ + V₁ ^ 2) = ρ₂ * (R * T₂ + V₂ ^ 2) := by
      rw [hp₁, hp₂] at hmom; linarith
    have h : ρ₁ * ((R * T₁ + V₁ ^ 2) * V₂ - V₁ * (R * T₂ + V₂ ^ 2)) = 0 := by
      linear_combination V₂ * h1 - (R * T₂ + V₂ ^ 2) * hmass
    rcases mul_eq_zero.mp h with h0 | h0
    · exact absurd h0 hρ₁.ne'
    · linarith
  -- energy, cleared of fractions
  have hEn : 2 * (γ * R * T₁) + (γ - 1) * V₁ ^ 2 = 2 * (γ * R * T₂) + (γ - 1) * V₂ ^ 2 := by
    field_simp at henergy
    linear_combination henergy
  have hfac : (V₂ - V₁) * (2 * (γ * R * T₁) + (γ - 1) * V₁ ^ 2 - (γ + 1) * V₁ * V₂) = 0 := by
    linear_combination (2 * γ) * hMo - V₁ * hEn
  rcases mul_eq_zero.mp hfac with h | hP
  · left; linarith
  right
  have hPr : (γ + 1) * V₁ * V₂ = 2 * (γ * R * T₁) + (γ - 1) * V₁ ^ 2 := by linarith
  have hM1 : M₁ ^ 2 = V₁ ^ 2 / (γ * R * T₁) := by
    simp only [M₁]; rw [div_pow, Real.sq_sqrt hs.le]
  have hM2 : M₂ ^ 2 = V₂ ^ 2 / (γ * R * T₂) := by
    simp only [M₂]; rw [div_pow, Real.sq_sqrt ht.le]
  -- the key identity behind M₂²
  have hkey : V₂ * (2 * γ * V₁ ^ 2 - (γ - 1) * (γ * R * T₁)) = (γ + 1) * V₁ * (γ * R * T₂) := by
    linear_combination (γ + 1) * V₁ / 2 * hEn + ((γ - 1) * V₂ + (γ + 1) * V₁) / 2 * hPr
  have hden : 0 < 2 * γ * V₁ ^ 2 - (γ - 1) * (γ * R * T₁) := by
    have h := hkey
    have : 0 < (γ + 1) * V₁ * (γ * R * T₂) := by positivity
    rw [← h] at this
    exact pos_of_mul_pos_right this hV₂.le
  refine ⟨?_, ?_, ?_, ?_⟩
  · simp only [aStarSq]
    field_simp
    linear_combination hPr
  · rw [hM2, shockMach2Sq, hM1]
    have hn2 : 1 + (γ - 1) / 2 * (V₁ ^ 2 / (γ * R * T₁)) =
        (2 * (γ * R * T₁) + (γ - 1) * V₁ ^ 2) / (2 * (γ * R * T₁)) := by
      field_simp
    have hd2 : γ * (V₁ ^ 2 / (γ * R * T₁)) - (γ - 1) / 2 =
        (2 * γ * V₁ ^ 2 - (γ - 1) * (γ * R * T₁)) / (2 * (γ * R * T₁)) := by
      field_simp
    rw [hn2, hd2, div_div_div_cancel_right₀ (by positivity)]
    rw [div_eq_div_iff ht.ne' hden.ne']
    linear_combination V₂ * hkey + (γ * R * T₂) * hPr
  · rw [shockPressureRatio, hM1]
    have hp1 : 0 < p₁ := by rw [hp₁]; positivity
    have hG : p₂ * ((γ + 1) * (γ * R * T₁)) = ((γ + 1) * (γ * R * T₁) + 2 * γ * (V₁ ^ 2 - γ * R * T₁)) * p₁ := by
      subst hp₁ hp₂
      linear_combination (-(γ * R * T₁ * ρ₁)) * hPr + ((γ + 1) * (γ * R * T₁) * V₂) * hmass - ((γ + 1) * (γ * R * T₁)) * hmom
    have hr : 1 + 2 * γ / (γ + 1) * (V₁ ^ 2 / (γ * R * T₁) - 1) =
        ((γ + 1) * (γ * R * T₁) + 2 * γ * (V₁ ^ 2 - γ * R * T₁)) / ((γ + 1) * (γ * R * T₁)) := by
      field_simp
    rw [hr, div_eq_div_iff hp1.ne' (by positivity)]
    linear_combination hG
  · rw [shockDensityRatio, hM1]
    have hr : (γ + 1) * (V₁ ^ 2 / (γ * R * T₁)) / ((γ - 1) * (V₁ ^ 2 / (γ * R * T₁)) + 2) =
        (γ + 1) * V₁ ^ 2 / ((γ - 1) * V₁ ^ 2 + 2 * (γ * R * T₁)) := by
      field_simp
    have hd : 0 < (γ - 1) * V₁ ^ 2 + 2 * (γ * R * T₁) := by
      have : 0 < (γ - 1) * V₁ ^ 2 := mul_pos (by linarith) (by positivity)
      linarith
    rw [hr, div_eq_div_iff hρ₁.ne' hd.ne']
    linear_combination (-(γ + 1) * V₁) * hmass - ρ₂ * hPr

/-- A shock is the one abrupt way back from supersonic to subsonic, and it charges for it. For
fixed γ > 1 and a flow arriving at Mach M₁ > 1, the jump relations give a subsonic flow after the
shock (0 < M₂² < 1), a rise in static pressure (p₂/p₁ > 1) and in density (ρ₂/ρ₁ > 1), and a loss
of stagnation pressure (p₀₂/p₀₁ < 1). -/
theorem normal_shock_slows_compresses_and_loses_stagnation_pressure
    (γ M₁ : ℝ) (hγ : 1 < γ) (hM₁ : 1 < M₁) :
    0 < shockMach2Sq γ M₁ ∧ shockMach2Sq γ M₁ < 1 ∧
    1 < shockPressureRatio γ M₁ ∧ 1 < shockDensityRatio γ M₁ ∧
    shockStagPressureKept γ M₁ < 1 := by
  have hγ0 : 0 < γ := by linarith
  have hγ1 : 0 < γ - 1 := by linarith
  have hk : 0 < (γ - 1) / 2 := by linarith
  have hm : 1 < M₁ ^ 2 := by nlinarith
  have hden : 0 < γ * M₁ ^ 2 - (γ - 1) / 2 := by nlinarith
  have hnum : 0 < 1 + (γ - 1) / 2 * M₁ ^ 2 := by
    have := mul_pos hk (by positivity : 0 < M₁ ^ 2); linarith
  have hDden : 0 < (γ - 1) * M₁ ^ 2 + 2 := by
    have := mul_pos hγ1 (by positivity : 0 < M₁ ^ 2); linarith
  have hP : 1 < shockPressureRatio γ M₁ := by
    unfold shockPressureRatio
    have : 0 < 2 * γ / (γ + 1) * (M₁ ^ 2 - 1) := mul_pos (by positivity) (by linarith)
    linarith
  have hD : 1 < shockDensityRatio γ M₁ := by
    unfold shockDensityRatio
    rw [one_lt_div hDden]
    nlinarith
  refine ⟨div_pos hnum hden, (div_lt_one hden).mpr (by nlinarith), hP, hD, ?_⟩
  have hP0 : 0 < shockPressureRatio γ M₁ := by linarith
  have hD0 : 0 < shockDensityRatio γ M₁ := by linarith
  -- the temperature ratio T₁/T₂ is (ρ₂/ρ₁)/(p₂/p₁)
  have hr : (1 + (γ - 1) / 2 * shockMach2Sq γ M₁) / stagTempRatio γ M₁ =
      shockDensityRatio γ M₁ / shockPressureRatio γ M₁ := by
    have hPeq : shockPressureRatio γ M₁ = (2 * γ * M₁ ^ 2 - γ + 1) / (γ + 1) := by
      unfold shockPressureRatio; field_simp; ring
    have hQ : 0 < 2 * γ * M₁ ^ 2 - γ + 1 := by nlinarith
    have hB : 0 < stagTempRatio γ M₁ := hnum
    have hS : shockMach2Sq γ M₁ = 2 * (1 + (γ - 1) / 2 * M₁ ^ 2) / (2 * γ * M₁ ^ 2 - γ + 1) := by
      rw [shockMach2Sq, div_eq_div_iff hden.ne' hQ.ne']; ring
    have hA : 1 + (γ - 1) / 2 * shockMach2Sq γ M₁ =
        (γ + 1) ^ 2 * M₁ ^ 2 / (2 * (2 * γ * M₁ ^ 2 - γ + 1)) := by
      rw [hS, eq_div_iff (by positivity)]
      have hc := div_mul_cancel₀ (2 * (1 + (γ - 1) / 2 * M₁ ^ 2)) hQ.ne'
      linear_combination (γ - 1) * hc
    rw [hA, hPeq, div_eq_div_iff hB.ne' (by positivity), shockDensityRatio, stagTempRatio]
    rw [div_mul_div_comm, div_mul_eq_mul_div, div_eq_div_iff (by positivity) (by positivity)]
    ring
  have hkept : 0 < shockStagPressureKept γ M₁ := by
    unfold shockStagPressureKept
    rw [hr]
    exact mul_pos hP0 (Real.rpow_pos_of_pos (div_pos hD0 hP0) _)
  have hent := shock_entropy_pos γ (M₁ ^ 2) hγ hm
  have hlogD : Real.log (shockDensityRatio γ M₁) =
      Real.log ((γ + 1) * M₁ ^ 2) - Real.log ((γ - 1) * M₁ ^ 2 + 2) := by
    unfold shockDensityRatio
    exact Real.log_div (by positivity) hDden.ne'
  have hlog : Real.log (shockStagPressureKept γ M₁) =
      (γ * Real.log ((γ + 1) * M₁ ^ 2) - γ * Real.log ((γ - 1) * M₁ ^ 2 + 2) -
        Real.log (shockPressureRatio γ M₁)) / (γ - 1) := by
    unfold shockStagPressureKept
    rw [hr, Real.log_mul hP0.ne' (Real.rpow_pos_of_pos (div_pos hD0 hP0) _).ne',
      Real.log_rpow (div_pos hD0 hP0), Real.log_div hD0.ne' hP0.ne', hlogD]
    field_simp
    ring
  rw [← Real.log_neg_iff hkept, hlog]
  apply div_neg_of_neg_of_pos _ hγ1
  unfold shockPressureRatio
  linarith

-- Air, γ = 7/5, at Mach 2: T0/T = 1 + 0.2 × 4 = 9/5 = 1.8.
example : stagTempRatio (7 / 5) 2 = 9 / 5 := by
  norm_num [stagTempRatio]

-- Air at Mach 2: the power (γ + 1)/(2(γ - 1)) is 3 and A/A* = (1/2) × 1.5³ = 27/16 = 1.6875.
example : areaRatio (7 / 5) 2 = 27 / 16 := by
  have h : ((7 / 5 : ℝ) + 1) / (2 * (7 / 5 - 1)) = ((3 : ℕ) : ℝ) := by norm_num
  rw [areaRatio, h, Real.rpow_natCast]
  norm_num [stagTempRatio]

-- Air at Mach 3: A/A* = (1/3) × (7/3)³ = 343/81, so a 100 cm² test section needs a
-- 100 × 81/343 cm² throat, about 23.62 cm².
example : areaRatio (7 / 5) 3 = 343 / 81 := by
  have h : ((7 / 5 : ℝ) + 1) / (2 * (7 / 5 - 1)) = ((3 : ℕ) : ℝ) := by norm_num
  rw [areaRatio, h, Real.rpow_natCast]
  norm_num [stagTempRatio]

-- Helium, γ = 5/3, at Mach 2: the power is 2 and A/A* = (1/2) × (7/4)² = 49/32 = 1.53125.
example : areaRatio (5 / 3) 2 = 49 / 32 := by
  have h : ((5 / 3 : ℝ) + 1) / (2 * (5 / 3 - 1)) = ((2 : ℕ) : ℝ) := by norm_num
  rw [areaRatio, h, Real.rpow_natCast]
  norm_num [stagTempRatio]

-- Step 2's area-velocity rule at Mach 0.5 and Mach 2: M² - 1 is -3/4 and 3.
example : (1 / 2 : ℚ) ^ 2 - 1 = -3 / 4 ∧ (2 : ℚ) ^ 2 - 1 = 3 := by norm_num

-- A normal shock in air at Mach 2: M₂² = 1.8/5.4 = 1/3, p₂/p₁ = 9/2, ρ₂/ρ₁ = 8/3,
-- and T₂/T₁ = (9/2)/(8/3) = 27/16.
example : shockMach2Sq (7 / 5) 2 = 1 / 3 ∧ shockPressureRatio (7 / 5) 2 = 9 / 2 ∧
    shockDensityRatio (7 / 5) 2 = 8 / 3 ∧
    shockPressureRatio (7 / 5) 2 / shockDensityRatio (7 / 5) 2 = 27 / 16 := by
  norm_num [shockMach2Sq, shockPressureRatio, shockDensityRatio]

-- The stagnation pressure kept at Mach 2 is 4.5 × ((1 + 0.2/3)/1.8)^3.5: the base is 16/27.
example : (1 + (7 / 5 - 1) / 2 * shockMach2Sq (7 / 5) 2) / stagTempRatio (7 / 5) 2 = 16 / 27 ∧
    (7 / 5 : ℝ) / (7 / 5 - 1) = 7 / 2 := by
  norm_num [shockMach2Sq, stagTempRatio]

#print axioms supersonic_nozzle_must_widen
#print axioms normal_shock_jump_from_conservation_laws
#print axioms normal_shock_slows_compresses_and_loses_stagnation_pressure
