-- Digital inverses: under Black-Scholes a cash digital's quote strictly between 0 and the discount factor names exactly one strike, given by a closed form, while the number of volatilities it implies is one, two or none according to where the strike sits against the forward.
import Mathlib.Probability.CDF
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Data.Set.Card

open Real ProbabilityTheory

/-- The standard normal distribution function `N(x)`: the area under the bell curve left of `x`. -/
local notation "Φ" => cdf (gaussianReal 0 1)

/-- Black-Scholes price of a cash-or-nothing digital call paying 1 at expiry `T` above strike `K`:
`D * N(d₂)` with `D = e^{-rT}`, `F = S e^{(r-q)T}`, `w = σ √T`, `d₂ = (ln(F/K) - w²/2) / w`. -/
noncomputable def cashDigital (S r q T K σ : ℝ) : ℝ :=
  exp (-r * T) *
    Φ ((log (S * exp ((r - q) * T) / K) - (σ * √T) ^ 2 / 2) / (σ * √T))



section digInvHelpers

open MeasureTheory Set Filter Topology

lemma digInv_Phi_strictMono : StrictMono Φ := by
  intro x y hxy
  have h1 : (cdf (gaussianReal 0 1)).measure (Ioc x y) = ENNReal.ofReal (Φ y - Φ x) :=
    (cdf (gaussianReal 0 1)).measure_Ioc x y
  rw [measure_cdf] at h1
  have h2 : gaussianReal 0 1 (Ioc x y) ≠ 0 := by
    intro h
    have := gaussianReal_absolutelyContinuous' (0:ℝ) (v := 1) one_ne_zero h
    rw [Real.volume_Ioc] at this
    simp [ENNReal.ofReal_eq_zero] at this
    linarith
  rw [h1] at h2
  simp [ENNReal.ofReal_eq_zero] at h2
  linarith

lemma digInv_Phi_continuous : Continuous Φ := by
  rw [continuous_iff_continuousAt]
  intro a
  have := nullSingletonClass_gaussianReal (μ := 0) (v := 1) one_ne_zero
  rw [continuousAt_iff_continuous_left'_right']
  constructor
  · rw [(cdf (gaussianReal 0 1)).mono.continuousWithinAt_Iio_iff_leftLim_eq]
    have h := (cdf (gaussianReal 0 1)).measure_singleton a
    rw [measure_cdf, measure_singleton, eq_comm, ENNReal.ofReal_eq_zero] at h
    have := (cdf (gaussianReal 0 1)).mono.leftLim_le (le_refl a)
    linarith
  · exact (continuousWithinAt_Ioi_iff_Ici).2 ((cdf (gaussianReal 0 1)).right_continuous a)

lemma digInv_Phi_surj (p : ℝ) (h0 : 0 < p) (h1 : p < 1) : ∃ z, Φ z = p := by
  have ha : ∀ᶠ x in atBot, Φ x < p :=
    (tendsto_cdf_atBot (μ := gaussianReal 0 1)).eventually (gt_mem_nhds h0)
  have hb : ∀ᶠ x in atTop, p < Φ x :=
    (tendsto_cdf_atTop (μ := gaussianReal 0 1)).eventually (lt_mem_nhds h1)
  obtain ⟨a, ha⟩ := ha.exists
  obtain ⟨b, hb⟩ := hb.exists
  exact intermediate_value_univ a b digInv_Phi_continuous ⟨ha.le, hb.le⟩

lemma digInv_Phi_zero : Φ 0 = 1 / 2 := by
  have := nullSingletonClass_gaussianReal (μ := 0) (v := 1) one_ne_zero
  set μ := gaussianReal 0 1
  have hsym : μ.real (Ici 0) = μ.real (Iic 0) := by
    have : μ = μ.map (fun x ↦ -x) := by
      rw [gaussianReal_map_neg]; simp [μ]
    conv_rhs => rw [this]
    rw [map_measureReal_apply (by fun_prop) measurableSet_Iic]
    congr 1
    ext x; simp
  have hcompl : μ.real (Iic 0) + μ.real (Ioi 0) = 1 := by
    rw [← compl_Iic, measureReal_add_measureReal_compl measurableSet_Iic]
    simp
  have hIoi : μ.real (Ioi 0) = μ.real (Ici 0) := measureReal_congr Ioi_ae_eq_Ici
  rw [cdf_eq_real]
  linarith


lemma digInv_set_single (sT w0 : ℝ) (Q : ℝ → Prop) (hsT : 0 < sT) (hw0 : 0 < w0)
    (hQ : ∀ w, 0 < w → (Q w ↔ w = w0)) :
    {σ : ℝ | 0 < σ ∧ Q (σ * sT)} = {w0 / sT} := by
  ext σ
  simp only [mem_ofPred_eq, mem_singleton_iff]
  constructor
  · rintro ⟨hσ, hq⟩
    have := (hQ _ (mul_pos hσ hsT)).1 hq
    rw [eq_div_iff hsT.ne']; exact this
  · rintro rfl
    refine ⟨div_pos hw0 hsT, ?_⟩
    rw [div_mul_cancel₀ _ hsT.ne']
    exact (hQ _ hw0).2 rfl

lemma digInv_set_pair (sT w1 w2 : ℝ) (Q : ℝ → Prop) (hsT : 0 < sT) (hw1 : 0 < w1)
    (hw2 : 0 < w2) (hQ : ∀ w, 0 < w → (Q w ↔ w = w1 ∨ w = w2)) :
    {σ : ℝ | 0 < σ ∧ Q (σ * sT)} = {w1 / sT, w2 / sT} := by
  ext σ
  simp only [mem_ofPred_eq, mem_insert_iff, mem_singleton_iff]
  constructor
  · rintro ⟨hσ, hq⟩
    rcases (hQ _ (mul_pos hσ hsT)).1 hq with h | h
    · left; rw [eq_div_iff hsT.ne']; exact h
    · right; rw [eq_div_iff hsT.ne']; exact h
  · rintro (rfl | rfl)
    · refine ⟨div_pos hw1 hsT, ?_⟩
      rw [div_mul_cancel₀ _ hsT.ne']
      exact (hQ _ hw1).2 (Or.inl rfl)
    · refine ⟨div_pos hw2 hsT, ?_⟩
      rw [div_mul_cancel₀ _ hsT.ne']
      exact (hQ _ hw2).2 (Or.inr rfl)

lemma digInv_set_empty (sT : ℝ) (Q : ℝ → Prop) (hsT : 0 < sT)
    (hQ : ∀ w, 0 < w → ¬ Q w) :
    {σ : ℝ | 0 < σ ∧ Q (σ * sT)} = ∅ := by
  ext σ
  simp only [mem_ofPred_eq, mem_empty_iff_false, iff_false, not_and]
  intro hσ
  exact hQ _ (mul_pos hσ hsT)

lemma digInv_quad (m z w : ℝ) (hw : 0 < w) :
    m / w - w / 2 = z ↔ w ^ 2 + 2 * z * w - 2 * m = 0 := by
  constructor
  · intro h
    rw [← h]; field_simp; ring
  · intro h
    field_simp
    linarith

end digInvHelpers

#print axioms digInv_Phi_strictMono
#print axioms digInv_Phi_continuous
#print axioms digInv_Phi_surj
#print axioms digInv_Phi_zero
#print axioms digInv_set_single
#print axioms digInv_set_pair
#print axioms digInv_set_empty
#print axioms digInv_quad

/-- The volatility inverse. Fix spot, rates, expiry and strike, and take a quote strictly between
0 and the discount factor `D`. With `m = ln(F/K)`, the positive volatilities that reprice the quote
number: exactly one when the strike is below the forward (`m > 0`); exactly one for quotes below
`D/2` and none otherwise when the strike is at the forward (`m = 0`); and, when the strike is above
the forward (`m < 0`) with `k = √(-2m)`, two for quotes below `D N(-k)`, the single volatility
`k/√T` for the quote `D N(-k)` itself, and none above it. -/
theorem digital_implied_vol_count_by_moneyness (S r q T K V : ℝ)
    (hS : 0 < S) (hT : 0 < T) (hK : 0 < K)
    (hV0 : 0 < V) (hVD : V < exp (-r * T)) :
    let D := exp (-r * T)
    let m := log (S * exp ((r - q) * T) / K)
    let k := √(-2 * m)
    let A := {σ : ℝ | 0 < σ ∧ cashDigital S r q T K σ = V}
    (0 < m → A.ncard = 1) ∧
    (m = 0 → (V < D / 2 → A.ncard = 1) ∧ (D / 2 ≤ V → A = ∅)) ∧
    (m < 0 →
      (V < D * Φ (-k) → A.ncard = 2) ∧
      (V = D * Φ (-k) → A = {k / √T}) ∧
      (D * Φ (-k) < V → A = ∅)) := by
  intro D m k A
  have hD : 0 < D := exp_pos _
  have hsT : 0 < √T := Real.sqrt_pos.2 hT
  obtain ⟨z, hz⟩ := digInv_Phi_surj (V / D) (div_pos hV0 hD) ((div_lt_one hD).2 hVD)
  have hzV : D * Φ z = V := by rw [hz]; field_simp
  have hiff : ∀ x, D * Φ x = V ↔ x = z := by
    intro x
    rw [← hzV, mul_right_inj' hD.ne', digInv_Phi_strictMono.injective.eq_iff]
  have hlt : ∀ c, V < D * Φ c ↔ z < c := by
    intro c
    rw [← hzV, mul_lt_mul_iff_right₀ hD, digInv_Phi_strictMono.lt_iff_lt]
  have hgt : ∀ c, D * Φ c < V ↔ c < z := by
    intro c
    rw [← hzV, mul_lt_mul_iff_right₀ hD, digInv_Phi_strictMono.lt_iff_lt]
  have heq : ∀ c, V = D * Φ c ↔ z = c := by
    intro c
    rw [eq_comm, hiff, eq_comm]
  have hprice : ∀ σ, 0 < σ →
      (cashDigital S r q T K σ = V ↔ (σ * √T) ^ 2 + 2 * z * (σ * √T) - 2 * m = 0) := by
    intro σ hσ
    have hw := mul_pos hσ hsT
    rw [← digInv_quad m z _ hw]
    change D * Φ ((m - (σ * √T) ^ 2 / 2) / (σ * √T)) = V ↔ _
    have e : (m - (σ * √T) ^ 2 / 2) / (σ * √T) = m / (σ * √T) - σ * √T / 2 := by
      field_simp
    rw [hiff, e]
  have hA : A = {σ : ℝ | 0 < σ ∧ (σ * √T) ^ 2 + 2 * z * (σ * √T) - 2 * m = 0} := by
    ext σ
    constructor
    · rintro ⟨hσ, hc⟩
      exact ⟨hσ, (hprice σ hσ).1 hc⟩
    · rintro ⟨hσ, hc⟩
      exact ⟨hσ, (hprice σ hσ).2 hc⟩
  refine ⟨fun hm => ?_, fun hm => ⟨fun hV => ?_, fun hV => ?_⟩,
    fun hm => ⟨fun hV => ?_, fun hV => ?_, fun hV => ?_⟩⟩
  · -- m > 0
    have hnn : 0 ≤ z ^ 2 + 2 * m := by positivity
    set s := √(z ^ 2 + 2 * m) with hs
    have hs2 : s ^ 2 = z ^ 2 + 2 * m := Real.sq_sqrt hnn
    have hs0 : 0 ≤ s := Real.sqrt_nonneg _
    have hw0 : 0 < -z + s := by nlinarith
    rw [hA, digInv_set_single (√T) (-z + s) (fun w => w ^ 2 + 2 * z * w - 2 * m = 0) hsT hw0 ?_, Set.ncard_singleton]
    intro w hw
    constructor
    · intro h
      have h' : (w + z - s) * (w + z + s) = 0 := by linear_combination h - hs2
      rcases mul_eq_zero.1 h' with h1 | h1
      · linarith
      · nlinarith
    · intro h
      rw [h]
      linear_combination hs2
  · -- m = 0, quote below D/2
    have hz0 : z < 0 := (hlt 0).1 (by rw [digInv_Phi_zero]; linarith)
    have hw0 : 0 < -2 * z := by linarith
    rw [hA, digInv_set_single (√T) (-2 * z) (fun w => w ^ 2 + 2 * z * w - 2 * m = 0) hsT hw0 ?_, Set.ncard_singleton]
    intro w hw
    constructor
    · intro h
      have h' : w * (w + 2 * z) = 0 := by rw [hm] at h; linear_combination h
      rcases mul_eq_zero.1 h' with h1 | h1
      · linarith
      · linarith
    · intro h
      rw [h, hm]
      ring
  · -- m = 0, quote at or above D/2
    have hz0 : 0 ≤ z := by
      by_contra hc
      push Not at hc
      have := (hlt 0).2 hc
      rw [digInv_Phi_zero] at this
      linarith
    rw [hA]
    refine digInv_set_empty (√T) (fun w => w ^ 2 + 2 * z * w - 2 * m = 0) hsT ?_
    intro w hw h
    rw [hm] at h
    nlinarith
  · -- m < 0, quote below D N(-k)
    have hk2 : k ^ 2 = -2 * m := Real.sq_sqrt (by linarith)
    have hk : 0 < k := Real.sqrt_pos.2 (by linarith)
    have hzk : z < -k := (hlt (-k)).1 hV
    have hpos : 0 < z ^ 2 - k ^ 2 := by nlinarith
    set t := √(z ^ 2 - k ^ 2) with ht
    have ht2 : t ^ 2 = z ^ 2 - k ^ 2 := Real.sq_sqrt hpos.le
    have ht0 : 0 < t := Real.sqrt_pos.2 hpos
    have htz : t < -z := by nlinarith
    have hw1 : 0 < -z - t := by linarith
    have hw2 : 0 < -z + t := by linarith
    rw [hA, digInv_set_pair (√T) (-z - t) (-z + t) (fun w => w ^ 2 + 2 * z * w - 2 * m = 0) hsT hw1 hw2 ?_]
    · rw [Set.ncard_pair]
      intro h
      rw [div_left_inj' hsT.ne'] at h
      linarith
    intro w hw
    constructor
    · intro h
      have h' : (w + z + t) * (w + z - t) = 0 := by linear_combination h - ht2 + hk2
      rcases mul_eq_zero.1 h' with h1 | h1
      · left; linarith
      · right; linarith
    · rintro (h | h)
      · rw [h]; linear_combination ht2 - hk2
      · rw [h]; linear_combination ht2 - hk2
  · -- m < 0, quote equal to D N(-k)
    have hk2 : k ^ 2 = -2 * m := Real.sq_sqrt (by linarith)
    have hk : 0 < k := Real.sqrt_pos.2 (by linarith)
    have hzk : z = -k := (heq (-k)).1 hV
    rw [hA, digInv_set_single (√T) k (fun w => w ^ 2 + 2 * z * w - 2 * m = 0) hsT hk ?_]
    intro w hw
    constructor
    · intro h
      have h' : (w - k) ^ 2 = 0 := by rw [hzk] at h; linear_combination h + hk2
      have := pow_eq_zero_iff (n := 2) (by norm_num) |>.1 h'
      linarith
    · intro h
      rw [h, hzk]
      linear_combination -hk2
  · -- m < 0, quote above D N(-k)
    have hk2 : k ^ 2 = -2 * m := Real.sq_sqrt (by linarith)
    have hzk : -k < z := (hgt (-k)).1 hV
    rw [hA]
    refine digInv_set_empty (√T) (fun w => w ^ 2 + 2 * z * w - 2 * m = 0) hsT ?_
    intro w hw h
    nlinarith [sq_nonneg (w - k), mul_pos hw (show 0 < z + k by linarith)]

/-- The strike inverse. Fix spot, rates, expiry and a positive volatility, and take a quote strictly
between 0 and the discount factor `D`. Then there is a bell-curve point `z` with `D N(z)` equal to
the quote, and the strikes that reprice the quote are exactly the one strike
`K = F exp(-w z - w²/2)`, with `F = S e^{(r-q)T}` and `w = σ √T`. -/
theorem digital_strike_unique_closed_form (S r q T σ V : ℝ)
    (hS : 0 < S) (hT : 0 < T) (hσ : 0 < σ)
    (hV0 : 0 < V) (hVD : V < exp (-r * T)) :
    ∃ z : ℝ, exp (-r * T) * Φ z = V ∧
      ∀ K : ℝ, (0 < K ∧ cashDigital S r q T K σ = V) ↔
        K = S * exp ((r - q) * T) * exp (-(σ * √T) * z - (σ * √T) ^ 2 / 2) := by
  have hD : 0 < exp (-r * T) := exp_pos _
  have hsT : 0 < √T := Real.sqrt_pos.2 hT
  have hw : 0 < σ * √T := mul_pos hσ hsT
  have hF : 0 < S * exp ((r - q) * T) := mul_pos hS (exp_pos _)
  obtain ⟨z, hz⟩ := digInv_Phi_surj (V / exp (-r * T)) (div_pos hV0 hD) ((div_lt_one hD).2 hVD)
  have hzV : exp (-r * T) * Φ z = V := by rw [hz]; field_simp
  have hiff : ∀ x, exp (-r * T) * Φ x = V ↔ x = z := by
    intro x
    rw [← hzV, mul_right_inj' hD.ne', digInv_Phi_strictMono.injective.eq_iff]
  refine ⟨z, hzV, ?_⟩
  intro K
  simp only [cashDigital]
  rw [hiff]
  set w := σ * √T with hwdef
  set F := S * exp ((r - q) * T) with hFdef
  constructor
  · rintro ⟨hK, hc⟩
    have hlog : log (F / K) = w * z + w ^ 2 / 2 := by
      rw [div_eq_iff hw.ne'] at hc
      linarith
    have hFK : F / K = exp (w * z + w ^ 2 / 2) := by rw [← hlog, exp_log (div_pos hF hK)]
    rw [show -w * z - w ^ 2 / 2 = -(w * z + w ^ 2 / 2) by ring, exp_neg, ← hFK]
    field_simp
  · intro hK
    have hKpos : 0 < K := by rw [hK]; positivity
    refine ⟨hKpos, ?_⟩
    have hFK : F / K = exp (w * z + w ^ 2 / 2) := by
      rw [hK, show -w * z - w ^ 2 / 2 = -(w * z + w ^ 2 / 2) by ring, exp_neg]
      field_simp
    rw [hFK, log_exp]
    field_simp
    ring

/-- The quadratic. For a positive total volatility `w`, the price equation `m/w - w/2 = z`
holds exactly when `w² + 2 z w - 2m = 0`; so the volatilities are the positive roots
of that quadratic. -/
theorem digital_vol_equation_iff_quadratic (m z w : ℝ) (hw : 0 < w) :
    m / w - w / 2 = z ↔ w ^ 2 + 2 * z * w - 2 * m = 0 := by
  exact digInv_quad m z w hw

/-! Worked numbers from the card, house quote at strike 100: `z = 1/20`, `m = 3/100`, `w = 1/5`. -/

-- The total volatility 1/5 solves `m/w - w/2 = z`.
example : (3 / 100 : ℚ) / (1 / 5) - (1 / 5) / 2 = 1 / 20 := by norm_num

-- The quadratic `w² + w/10 - 3/50 = 0` has roots 1/5 and -3/10.
example : (1 / 5 : ℚ) ^ 2 + 2 * (1 / 20) * (1 / 5) - 2 * (3 / 100) = 0 := by norm_num
example : (-3 / 10 : ℚ) ^ 2 + 2 * (1 / 20) * (-3 / 10) - 2 * (3 / 100) = 0 := by norm_num

-- The roots multiply to `-2m = -3/50` and add to `-2z = -1/10`.
example : (1 / 5 : ℚ) * (-3 / 10) = -2 * (3 / 100) ∧ (1 / 5 : ℚ) + (-3 / 10) = -2 * (1 / 20) := by
  norm_num

-- The strike the other way: `ln(K/F) = -w z - w²/2 = -1/100 - 2/100 = -3/100 = -m`.
example : -(1 / 5 : ℚ) * (1 / 20) - (1 / 5) ^ 2 / 2 = -(3 / 100) := by norm_num

#print axioms digital_implied_vol_count_by_moneyness
#print axioms digital_strike_unique_closed_form
#print axioms digital_vol_equation_iff_quadratic
