-- Recovery assumptions: in the flat-hazard credit default swap model one quoted spread fixes exactly one hazard for each assumed recovery, the hazards rise with recovery and without bound, a known hazard fixes exactly one recovery, and a bond priced beside the swap separates hazard from recovery under face or treasury recovery but not under market-value recovery.
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Analysis.Convex.SpecificFunctions.Basic
import Mathlib.Analysis.Calculus.DSlope
import Mathlib.Analysis.SpecialFunctions.ExpDeriv

open Real Filter Topology

namespace RecoveryAssumptions

/-- The timing factor for premiums paid at each period's end (The formula): `F = (e^x - 1) / x`.
At `x = 0` the formula has a hole; it is filled with its limit 1, the credit-triangle value. -/
noncomputable def timingFactor (x : ℝ) : ℝ :=
  if x = 0 then 1 else (exp x - 1) / x

/-- The fair (par) spread of the swap in the flat-hazard model (The formula; Why it works,
Step 1): `(1 - R) lam F` with `F` taken at `x = (r + lam) δ`, for a riskless rate `r`, a flat
hazard `lam`, a recovery `R` and a premium period of `δ` years. -/
noncomputable def parSpread (r δ lam R : ℝ) : ℝ :=
  (1 - R) * lam * timingFactor ((r + lam) * δ)

/-- A zero-coupon bond paying 1 at year `T`, price today under recovery of face (Step 5):
`e^(-kT) + R lam (1 - e^(-kT)) / k` with `k = r + lam`. -/
noncomputable def faceBond (r lam R T : ℝ) : ℝ :=
  exp (-((r + lam) * T)) + R * lam * (1 - exp (-((r + lam) * T))) / (r + lam)

/-- The same bond under recovery of treasury (Step 5): `e^(-rT) [R + (1 - R) e^(-lam T)]`. -/
noncomputable def treasuryBond (r lam R T : ℝ) : ℝ :=
  exp (-(r * T)) * (R + (1 - R) * exp (-(lam * T)))

/-- The same bond under recovery of market value (Step 5): `e^(-(r + lam (1 - R)) T)`. -/
noncomputable def marketValueBond (r lam R T : ℝ) : ℝ :=
  exp (-((r + lam * (1 - R)) * T))

lemma timingFactor_of_ne {x : ℝ} (hx : x ≠ 0) : timingFactor x = (exp x - 1) / x := by simp [timingFactor, hx]

lemma timingFactor_eq_dslope : timingFactor = dslope exp 0 := by
  funext x
  by_cases hx : x = 0
  · subst hx
    simp [timingFactor, dslope_same, Real.deriv_exp]
  · rw [timingFactor_of_ne hx, dslope_of_ne _ hx, slope_def_field]
    simp

lemma timingFactor_continuous : Continuous timingFactor := by
  rw [timingFactor_eq_dslope, continuous_iff_continuousAt]
  intro x
  by_cases hx : x = 0
  · subst hx
    exact continuousAt_dslope_same.2 (Real.differentiable_exp 0)
  · exact (continuousAt_dslope_of_ne hx).2 Real.continuous_exp.continuousAt

lemma timingFactor_pos (x : ℝ) : 0 < timingFactor x := by
  rcases lt_trichotomy x 0 with hx | hx | hx
  · rw [timingFactor_of_ne hx.ne]
    exact div_pos_of_neg_of_neg (by linarith [Real.exp_lt_one_iff.2 hx]) hx
  · simp [timingFactor, hx]
  · rw [timingFactor_of_ne hx.ne']
    exact div_pos (by linarith [Real.one_lt_exp_iff.2 hx]) hx

lemma timingFactor_strictMono : StrictMono timingFactor := by
  intro x y hxy
  by_cases hx : x = 0
  · subst hx
    rw [timingFactor_of_ne hxy.ne']
    simp only [timingFactor, ite_true]
    rw [lt_div_iff₀ hxy]
    linarith [Real.add_one_lt_exp hxy.ne']
  by_cases hy : y = 0
  · subst hy
    rw [timingFactor_of_ne hx]
    simp only [timingFactor, ite_true]
    rw [div_lt_iff_of_neg hxy]
    linarith [Real.add_one_lt_exp hx]
  rw [timingFactor_of_ne hx, timingFactor_of_ne hy]
  have := strictConvexOn_exp.secant_strict_mono (Set.mem_univ 0) (Set.mem_univ x)
    (Set.mem_univ y) hx hy hxy
  simpa using this

lemma timingFactor_one_le {x : ℝ} (hx : 0 ≤ x) : 1 ≤ timingFactor x := by
  have h0 : timingFactor 0 = 1 := by simp [timingFactor]
  rw [← h0]; exact timingFactor_strictMono.monotone hx

/-- `g lam = lam F((r+lam)δ)` -/
lemma g_strictMonoOn (r δ : ℝ) (hδ : 0 < δ) :
    StrictMonoOn (fun lam => lam * timingFactor ((r + lam) * δ)) (Set.Ici 0) := by
  intro a ha b hb hab
  simp only [Set.mem_Ici] at ha hb
  have h1 : timingFactor ((r + a) * δ) < timingFactor ((r + b) * δ) :=
    timingFactor_strictMono (by nlinarith)
  have h2 := timingFactor_pos ((r + b) * δ)
  show a * timingFactor ((r + a) * δ) < b * timingFactor ((r + b) * δ)
  nlinarith

lemma g_continuous (r δ : ℝ) :
    Continuous (fun lam => lam * timingFactor ((r + lam) * δ)) := by
  exact continuous_id.mul (timingFactor_continuous.comp (by fun_prop))

#print axioms timingFactor_of_ne
#print axioms timingFactor_eq_dslope
#print axioms timingFactor_continuous
#print axioms timingFactor_pos
#print axioms timingFactor_strictMono
#print axioms timingFactor_one_le
#print axioms g_strictMonoOn
#print axioms g_continuous

/-- **One quote, many default probabilities** (the card's main claim; Why it works, Step 2 and
its detailed proof). Fix a positive quoted spread `s`, any riskless rate `r`, a premium period
`δ > 0` and a contract length `T > 0`, with one flat hazard and a fixed recovery paid on face at
default. Then:
* for every recovery `R` below 100% exactly one hazard `lam ≥ 0` prices the swap at `s`;
* a higher recovery forces a strictly higher hazard and a strictly higher chance
  `1 - e^(-lam T)` of default within `T` years, so the fitting pairs form one rising curve;
* as recovery nears 100% the hazard it forces exceeds any bound;
* at recovery 100% no hazard fits the quote. -/
theorem one_quote_fixes_hazard_only_given_recovery (s r δ T : ℝ)
    (hs : 0 < s) (hδ : 0 < δ) (hT : 0 < T) :
    (∀ R : ℝ, R < 1 → ∃! lam : ℝ, 0 ≤ lam ∧ parSpread r δ lam R = s) ∧
    (∀ R₁ R₂ lam₁ lam₂ : ℝ, R₁ < R₂ → R₂ < 1 → 0 ≤ lam₁ → 0 ≤ lam₂ →
        parSpread r δ lam₁ R₁ = s → parSpread r δ lam₂ R₂ = s →
        lam₁ < lam₂ ∧ 1 - exp (-(lam₁ * T)) < 1 - exp (-(lam₂ * T))) ∧
    (∀ M : ℝ, ∃ R₀ : ℝ, R₀ < 1 ∧ ∀ R lam : ℝ, R₀ ≤ R → R < 1 → 0 ≤ lam →
        parSpread r δ lam R = s → M < lam) ∧
    (∀ lam : ℝ, parSpread r δ lam 1 ≠ s) := by
  set g : ℝ → ℝ := fun lam => lam * timingFactor ((r + lam) * δ) with hg
  have hmono := g_strictMonoOn r δ hδ
  have hcont := g_continuous r δ
  have hps : ∀ lam R, parSpread r δ lam R = (1 - R) * g lam := by
    intro lam R; simp only [parSpread, hg]; ring
  have hg0 : g 0 = 0 := by simp [hg]
  have hgnn : ∀ lam, 0 ≤ lam → 0 ≤ g lam := by
    intro lam h; rw [← hg0]; exact hmono.monotoneOn (Set.mem_Ici.2 le_rfl) (Set.mem_Ici.2 h) h
  -- fitting equation solved for g
  have hfit : ∀ lam R, R < 1 → (parSpread r δ lam R = s ↔ g lam = s / (1 - R)) := by
    intro lam R hR
    have h1 : 0 < 1 - R := by linarith
    rw [hps, eq_div_iff h1.ne']; constructor <;> intro h <;> linarith
  refine ⟨?_, ?_, ?_, ?_⟩
  · intro R hR
    have h1 : 0 < 1 - R := by linarith
    set t := s / (1 - R) with ht
    have htpos : 0 < t := div_pos hs h1
    -- a point where g ≥ t
    set L := max t (max (-r) 0) with hL
    have hL0 : 0 ≤ L := le_trans (le_max_right _ _) (le_max_right _ _)
    have hgL : t ≤ g L := by
      have hx : 0 ≤ (r + L) * δ := by
        apply mul_nonneg _ hδ.le
        have := le_trans (le_max_left (-r) 0) (le_max_right t (max (-r) 0))
        linarith
      have := timingFactor_one_le hx
      simp only [hg]
      nlinarith [le_max_left t (max (-r) 0)]
    obtain ⟨lam, hlam, hglam⟩ : ∃ lam ∈ Set.Icc 0 L, g lam = t := by
      have := intermediate_value_Icc hL0 hcont.continuousOn
      exact this ⟨by show g 0 ≤ t; rw [hg0]; exact htpos.le, hgL⟩
    refine ⟨lam, ⟨hlam.1, (hfit lam R hR).2 hglam⟩, ?_⟩
    rintro μ ⟨hμ, hμfit⟩
    have hgμ := (hfit μ R hR).1 hμfit
    exact hmono.injOn (Set.mem_Ici.2 hμ) (Set.mem_Ici.2 hlam.1) (by show g μ = g lam; rw [hgμ, hglam])
  · intro R₁ R₂ lam₁ lam₂ h12 h2 hl1 hl2 hf1 hf2
    have hg1 := (hfit _ _ (by linarith)).1 hf1
    have hg2 := (hfit _ _ h2).1 hf2
    have hlt : g lam₁ < g lam₂ := by
      rw [hg1, hg2]
      exact div_lt_div_of_pos_left hs (by linarith) (by linarith)
    have hl : lam₁ < lam₂ := by
      by_contra hc
      rw [not_lt] at hc
      have := hmono.monotoneOn (Set.mem_Ici.2 hl2) (Set.mem_Ici.2 hl1) hc
      linarith
    refine ⟨hl, ?_⟩
    have : exp (-(lam₂ * T)) < exp (-(lam₁ * T)) := Real.exp_lt_exp.2 (by nlinarith)
    linarith
  · intro M
    set M' := max M 0 with hM'
    have hM'0 : 0 ≤ M' := le_max_right _ _
    have hgM' := hgnn M' hM'0
    refine ⟨1 - s / (g M' + 1), by have := div_pos hs (by linarith : (0:ℝ) < g M' + 1); linarith, ?_⟩
    intro R lam hR0 hR hlam hf
    have hglam := (hfit _ _ hR).1 hf
    by_contra hc
    rw [not_lt] at hc
    have hle : g lam ≤ g M' :=
      hmono.monotoneOn (Set.mem_Ici.2 hlam) (Set.mem_Ici.2 hM'0) (le_trans hc (le_max_left _ _))
    have h1 : 0 < 1 - R := by linarith
    have h2 : 1 - R ≤ s / (g M' + 1) := by linarith
    have h3 : s / (s / (g M' + 1)) ≤ s / (1 - R) := div_le_div_of_nonneg_left hs.le h1 h2
    have h4 : s / (s / (g M' + 1)) = g M' + 1 := by field_simp
    linarith
  · intro lam
    rw [hps]; simp; exact hs.ne

/-- **Recovery when the hazard is known** (Why it works, Step 4). With a positive quote `s`,
any rate `r`, a period `δ > 0` and a known hazard `lam > 0`, exactly one recovery prices the
swap at `s`, namely `R = 1 - s / (lam F)`; a recovery from 0 (included) up to 1 fits exactly
when `s ≤ lam F`. At hazard 0 no recovery fits a positive quote. -/
theorem known_hazard_fixes_unique_recovery (s r δ lam : ℝ)
    (hs : 0 < s) (hδ : 0 < δ) (hlam : 0 < lam) :
    (∀ R : ℝ, parSpread r δ lam R = s ↔ R = 1 - s / (lam * timingFactor ((r + lam) * δ))) ∧
    ((∃ R : ℝ, 0 ≤ R ∧ R < 1 ∧ parSpread r δ lam R = s) ↔
        s ≤ lam * timingFactor ((r + lam) * δ)) ∧
    (∀ R : ℝ, parSpread r δ 0 R ≠ s) := by
  set c := lam * timingFactor ((r + lam) * δ) with hc
  have hcpos : 0 < c := mul_pos hlam (timingFactor_pos _)
  have hps : ∀ R, parSpread r δ lam R = (1 - R) * c := by
    intro R; simp only [parSpread, hc]; ring
  have key : ∀ R, parSpread r δ lam R = s ↔ R = 1 - s / c := by
    intro R
    rw [hps]
    constructor
    · intro h; rw [← h]; field_simp; ring
    · intro h; rw [h]; field_simp; ring
  refine ⟨key, ?_, ?_⟩
  · constructor
    · rintro ⟨R, hR0, _, hR⟩
      rw [hps] at hR
      nlinarith
    · intro h
      refine ⟨1 - s / c, ?_, ?_, (key _).2 rfl⟩
      · have : s / c ≤ 1 := (div_le_one hcpos).2 h
        linarith
      · have : 0 < s / c := div_pos hs hcpos
        linarith
  · intro R
    simp [parSpread]
    exact hs.ne

/-- **A bond beside the swap: face and treasury recovery separate the pair, market value does
not** (Why it works, Step 6 and the face-bond proof). With continuous premiums every pair that
fits a quote `s > 0` is `(lam, 1 - s / lam)` with `lam ≥ s`. Along that curve, for a bond
maturity `T > 0` and a rate `r` with `r + s > 0` (any rate at or above zero qualifies):
* the market-value bond's price is `e^(-(r + s) T)` at every point, so it adds no information;
* the face bond's price rises strictly, equals `e^(-(r + s) T)` at `lam = s` and tends to 1 as
  the hazard grows, so each price in that range picks out one pair;
* the treasury bond's price also rises strictly along the curve. -/
theorem bond_beside_cds_identifies_only_under_face_or_treasury (s r T : ℝ)
    (hs : 0 < s) (hrs : 0 < r + s) (hT : 0 < T) :
    (∀ lam : ℝ, s ≤ lam → marketValueBond r lam (1 - s / lam) T = exp (-((r + s) * T))) ∧
    StrictMonoOn (fun lam => faceBond r lam (1 - s / lam) T) (Set.Ici s) ∧
    faceBond r s (1 - s / s) T = exp (-((r + s) * T)) ∧
    Tendsto (fun lam => faceBond r lam (1 - s / lam) T) atTop (𝓝 1) ∧
    StrictMonoOn (fun lam => treasuryBond r lam (1 - s / lam) T) (Set.Ici s) := by
  have faceEq : ∀ lam, s ≤ lam →
      faceBond r lam (1 - s / lam) T = 1 - (r + s) * T * timingFactor (-((r + lam) * T)) := by
    intro lam hl
    have hlam : 0 < lam := lt_of_lt_of_le hs hl
    have hk : 0 < r + lam := by linarith
    have hkT : -((r + lam) * T) ≠ 0 := by
      have := mul_pos hk hT; linarith
    rw [faceBond, timingFactor_of_ne hkT]
    field_simp
    ring
  have faceEq' : ∀ lam, s ≤ lam →
      faceBond r lam (1 - s / lam) T = 1 - (r + s) * ((1 - exp (-((r + lam) * T))) / (r + lam)) := by
    intro lam hl
    have hlam : 0 < lam := lt_of_lt_of_le hs hl
    have hk : 0 < r + lam := by linarith
    rw [faceBond]
    field_simp
    ring
  have treasEq : ∀ lam, s ≤ lam →
      treasuryBond r lam (1 - s / lam) T = exp (-(r * T)) * (1 - s * T * timingFactor (-(lam * T))) := by
    intro lam hl
    have hlam : 0 < lam := lt_of_lt_of_le hs hl
    have hkT : -(lam * T) ≠ 0 := by
      have := mul_pos hlam hT; linarith
    rw [treasuryBond, timingFactor_of_ne hkT]
    field_simp
    ring
  refine ⟨?_, ?_, ?_, ?_, ?_⟩
  · intro lam hl
    have hlam : 0 < lam := lt_of_lt_of_le hs hl
    rw [marketValueBond, show lam * (1 - (1 - s / lam)) = s by field_simp; ring]
  · intro a ha b hb hab
    simp only [Set.mem_Ici] at ha hb
    simp only
    rw [faceEq a ha, faceEq b hb]
    have h1 : timingFactor (-((r + b) * T)) < timingFactor (-((r + a) * T)) :=
      timingFactor_strictMono (by nlinarith)
    have h2 : 0 < (r + s) * T := mul_pos hrs hT
    nlinarith
  · rw [faceBond, div_self hs.ne']
    simp
  · have hden : Tendsto (fun lam : ℝ => r + lam) atTop atTop :=
      tendsto_atTop_add_const_left atTop r tendsto_id
    have hexp : Tendsto (fun lam : ℝ => exp (-((r + lam) * T))) atTop (𝓝 0) :=
      Real.tendsto_exp_atBot.comp (tendsto_neg_atTop_atBot.comp (hden.atTop_mul_const hT))
    have hnum : Tendsto (fun lam : ℝ => 1 - exp (-((r + lam) * T))) atTop (𝓝 (1 - 0)) :=
      tendsto_const_nhds.sub hexp
    have hq := hnum.div_atTop hden
    have hlim : Tendsto (fun lam : ℝ => 1 - (r + s) * ((1 - exp (-((r + lam) * T))) / (r + lam)))
        atTop (𝓝 (1 - (r + s) * 0)) :=
      tendsto_const_nhds.sub (tendsto_const_nhds.mul hq)
    rw [mul_zero, sub_zero] at hlim
    refine hlim.congr' ?_
    filter_upwards [eventually_ge_atTop s] with lam hl
    exact (faceEq' lam hl).symm
  · intro a ha b hb hab
    simp only [Set.mem_Ici] at ha hb
    simp only
    rw [treasEq a ha, treasEq b hb]
    have h1 : timingFactor (-(b * T)) < timingFactor (-(a * T)) :=
      timingFactor_strictMono (by nlinarith)
    have h2 : 0 < s * T := mul_pos hs hT
    have h3 : 0 < exp (-(r * T)) := exp_pos _
    have : 1 - s * T * timingFactor (-(a * T)) < 1 - s * T * timingFactor (-(b * T)) := by
      nlinarith
    exact mul_lt_mul_of_pos_left this h3

-- 300 bp on $10 million: a premium of $300,000 a year.
example : (300 / 10000 : ℚ) * 10000000 = 300000 := by norm_num
-- Loss on default at 40% recovery: 0.6 × $10 million = $6 million; at 70%, $3 million.
example : (1 - 2 / 5 : ℚ) * 10000000 = 6000000 ∧ (1 - 7 / 10 : ℚ) * 10000000 = 3000000 := by
  norm_num
-- The product 3% splits many ways: 5% × 0.6 = 10% × 0.3 = 3% × 1.
example : (5 / 100 : ℚ) * (6 / 10) = 3 / 100 ∧ (10 / 100 : ℚ) * (3 / 10) = 3 / 100 ∧
    (3 / 100 : ℚ) * 1 = 3 / 100 := by norm_num
-- Triangle seeds: 0.03 / 0.6 = 0.05, 0.03 / 0.3 = 0.10, 0.03 / 1 = 0.03.
example : (3 / 100 : ℚ) / (1 - 2 / 5) = 5 / 100 ∧ (3 / 100 : ℚ) / (1 - 7 / 10) = 10 / 100 ∧
    (3 / 100 : ℚ) / (1 - 0) = 3 / 100 := by norm_num
-- Triangle chart, upper line at 50%, 80% and 90% recovery: 6.00%, 15.00% and 30.00%.
example : (3 / 100 : ℚ) / (1 - 5 / 10) = 6 / 100 ∧ (3 / 100 : ℚ) / (1 - 8 / 10) = 15 / 100 ∧
    (3 / 100 : ℚ) / (1 - 9 / 10) = 30 / 100 := by norm_num
-- Timing term at the 40% seed: x = (0.05 + 0.05) × 0.25 = 0.025.
example : (5 / 100 + 5 / 100 : ℚ) * (1 / 4) = 25 / 1000 := by norm_num
-- Known hazard, triangle: 5% gives recovery 40%, 2.5% gives -20%.
example : 1 - (3 / 100 : ℚ) / (5 / 100) = 2 / 5 ∧ 1 - (3 / 100 : ℚ) / (25 / 1000) = -(1 / 5) := by
  norm_num
-- Halving the quote: 0.015 / 0.3 equals 0.03 / 0.6.
example : (15 / 1000 : ℚ) / (3 / 10) = (3 / 100) / (6 / 10) := by norm_num
-- Market-value recovery discounts at r + lam (1 - R) = 0.05 + 0.05 × 0.6 = 0.08 = r + s.
example : (5 / 100 : ℚ) + 5 / 100 * (1 - 2 / 5) = 5 / 100 + 3 / 100 := by norm_num
-- Recovery of face on default at year two: 40% of $100 = $40.
example : (2 / 5 : ℚ) * 100 = 40 := by norm_num
-- Face-bond slope pieces at hazard 5%: r + s = 0.08, k = 0.10, k² = 0.01, z = kT = 0.5.
example : (5 / 100 + 3 / 100 : ℚ) = 8 / 100 ∧ (5 / 100 + 5 / 100 : ℚ) ^ 2 = 1 / 100 ∧
    (5 / 100 + 5 / 100 : ℚ) * 5 = 1 / 2 := by norm_num
-- Upfront for a 100 bp coupon at a 300 bp quote: the gap is 200 bp, $200,000 a year on $10 million.
example : ((300 - 100) / 10000 : ℚ) * 10000000 = 200000 := by norm_num

#print axioms one_quote_fixes_hazard_only_given_recovery
#print axioms known_hazard_fixes_unique_recovery
#print axioms bond_beside_cds_identifies_only_under_face_or_treasury

end RecoveryAssumptions
