-- The perpetual American put: with a positive rate the pricing quadratic has exactly one negative root λ, and the card's price curve built from it (exercise at or below S* = Kλ/(λ − 1), the power (K − S*)(S/S*)^λ above) solves the time-free pricing equation, meets the payoff with slope −1 at S*, stays on or above the payoff, dies away at large prices, and S* is the best of all trigger levels.
import Mathlib.Analysis.SpecialFunctions.Pow.Asymptotics
import Mathlib.Analysis.SpecialFunctions.Pow.Deriv
import Mathlib.Analysis.SpecialFunctions.Sqrt

open Real Filter Topology

namespace PerpetualAmericanPut

/-! The model, as on the card. Strike `K`, riskless rate `r`, dividend yield `q`,
volatility `σ`, and `λ` the negative root of `½σ²λ² + (r − q − ½σ²)λ − r = 0`. -/

/-- The pricing quadratic `½σ²x² + (r − q − ½σ²)x − r`. -/
noncomputable def quad (r q σ x : ℝ) : ℝ := σ ^ 2 / 2 * x ^ 2 + (r - q - σ ^ 2 / 2) * x - r

/-- The trigger `S* = Kλ/(λ − 1)`. -/
noncomputable def trigger (K lam : ℝ) : ℝ := K * lam / (lam - 1)

/-- The perpetual put: `K − S` at or below the trigger, `(K − S*)(S/S*)^λ` above it. -/
noncomputable def perpPut (K lam S : ℝ) : ℝ :=
  if S ≤ trigger K lam then K - S
  else (K - trigger K lam) * (S / trigger K lam) ^ lam


lemma bernoulli_neg (lam u : ℝ) (hlam : lam < 0) (hu : 0 < u) :
    1 + lam * (u - 1) ≤ u ^ lam := by
  rw [Real.rpow_def_of_pos hu]
  have h1 := Real.add_one_le_exp (Real.log u * lam)
  have h2 := Real.log_le_sub_one_of_pos hu
  nlinarith

lemma bernoulli_neg_strict (lam u : ℝ) (hlam : lam < 0) (hu : 0 < u) (hu1 : u ≠ 1) :
    1 + lam * (u - 1) < u ^ lam := by
  rw [Real.rpow_def_of_pos hu]
  have h1 := Real.add_one_le_exp (Real.log u * lam)
  have h2 := Real.log_lt_sub_one_of_pos hu hu1
  nlinarith

lemma trigger_pos (K lam : ℝ) (hK : 0 < K) (hneg : lam < 0) : 0 < trigger K lam := by
  unfold trigger
  exact div_pos_of_neg_of_neg (by nlinarith) (by linarith)

lemma trigger_lt (K lam : ℝ) (hK : 0 < K) (hneg : lam < 0) : trigger K lam < K := by
  unfold trigger
  rw [div_lt_iff_of_neg (by linarith)]
  nlinarith

lemma trigger_key (K lam : ℝ) (hneg : lam < 0) :
    (K - trigger K lam) * lam = - trigger K lam := by
  unfold trigger
  have : lam - 1 ≠ 0 := by linarith
  field_simp
  ring

lemma hasDerivAt_powerPart (c T lam x : ℝ) (hT : 0 < T) (hx : 0 < x) :
    HasDerivAt (fun y => c * (y / T) ^ lam) (lam * (c * (x / T) ^ lam) / x) x := by
  have h1 : HasDerivAt (fun y : ℝ => y / T) (1 / T) x := (hasDerivAt_id' x).div_const T
  have hxT : 0 < x / T := div_pos hx hT
  have h2 := (h1.rpow_const (p := lam) (Or.inl hxT.ne')).const_mul c
  convert h2 using 1
  rw [Real.rpow_sub_one hxT.ne']
  field_simp

lemma perpPut_of_le (K lam x : ℝ) (h : x ≤ trigger K lam) : perpPut K lam x = K - x := by
  simp only [perpPut, h, ite_true]

lemma perpPut_of_lt (K lam x : ℝ) (h : trigger K lam < x) :
    perpPut K lam x = (K - trigger K lam) * (x / trigger K lam) ^ lam := by
  simp only [perpPut, not_le.mpr h, ite_false]

lemma neg_roots_eq (r q σ x y : ℝ) (hr : 0 < r) (hσ : 0 < σ) (hx : x < 0) (hy : y < 0)
    (hqx : quad r q σ x = 0) (hqy : quad r q σ y = 0) : x = y := by
  unfold quad at hqx hqy
  by_contra hne
  have hsub : x - y ≠ 0 := sub_ne_zero.mpr hne
  have h1 : (x - y) * (σ ^ 2 / 2 * (x + y) + (r - q - σ ^ 2 / 2)) = 0 := by linear_combination hqx - hqy
  have h2 : σ ^ 2 / 2 * (x + y) + (r - q - σ ^ 2 / 2) = 0 := by
    rcases mul_eq_zero.mp h1 with h | h
    · exact absurd h hsub
    · exact h
  have h3 : σ ^ 2 / 2 * (x * y) + r = 0 := by linear_combination x * h2 - hqx
  have h4 : 0 < x * y := mul_pos_of_neg_of_neg hx hy
  have h5 : 0 < σ ^ 2 / 2 := by positivity
  nlinarith [mul_pos h5 h4]

/-- **The perpetual put's price curve and its boundary** (The formula; Why it works, Steps 1–4;
the detailed proof). Take a strike `K > 0`, a rate `r > 0`, any dividend yield `q`, a
volatility `σ > 0`, and let `λ` be the negative root of the pricing quadratic. Then the
trigger `S* = Kλ/(λ − 1)` lies strictly between `0` and the strike, and the price curve
`P` (exercise value `K − S` at or below `S*`, `(K − S*)(S/S*)^λ` above it):
* has delta `λP/S` and gamma `λ(λ − 1)P/S²` at every share price above the trigger;
* solves the time-free pricing equation `½σ²S²P'' + (r − q)SP' − rP = 0` above the trigger;
* meets the payoff at the trigger in height and in slope: it is differentiable there with
  slope `−1` (value matching and smooth pasting);
* is never below the payoff `max(K − S, 0)`;
* falls to zero as the share price grows without limit. -/
theorem perpetual_put_formula_solves_and_pastes
    (K r q σ lam : ℝ) (hK : 0 < K) (hr : 0 < r) (hσ : 0 < σ)
    (hroot : quad r q σ lam = 0) (hneg : lam < 0) :
    (0 < trigger K lam ∧ trigger K lam < K) ∧
      (∀ S : ℝ, trigger K lam < S →
        HasDerivAt (perpPut K lam) (lam * perpPut K lam S / S) S ∧
          HasDerivAt (deriv (perpPut K lam)) (lam * (lam - 1) * perpPut K lam S / S ^ 2) S) ∧
      (∀ S : ℝ, trigger K lam < S →
        σ ^ 2 / 2 * S ^ 2 * deriv (deriv (perpPut K lam)) S +
            (r - q) * S * deriv (perpPut K lam) S - r * perpPut K lam S = 0) ∧
      HasDerivAt (perpPut K lam) (-1) (trigger K lam) ∧
      (∀ S : ℝ, max (K - S) 0 ≤ perpPut K lam S) ∧
      Tendsto (perpPut K lam) atTop (𝓝 0) := by
  have hT : 0 < trigger K lam := trigger_pos K lam hK hneg
  have hTK : trigger K lam < K := trigger_lt K lam hK hneg
  have hkey : (K - trigger K lam) * lam = - trigger K lam := trigger_key K lam hneg
  have hPf := perpPut_of_lt K lam
  have hPl := perpPut_of_le K lam
  set T := trigger K lam with hTdef
  have hderiv1 : ∀ x, T < x → HasDerivAt (perpPut K lam) (lam * perpPut K lam x / x) x := by
    intro x hx
    have hx0 : 0 < x := hT.trans hx
    have h := hasDerivAt_powerPart (K - T) T lam x hT hx0
    rw [hPf x hx]
    apply h.congr_of_eventuallyEq
    filter_upwards [Ioi_mem_nhds hx] with y hy
    exact hPf y hy
  have hderivEq : ∀ x, T < x → deriv (perpPut K lam) x = lam * perpPut K lam x / x :=
    fun x hx => (hderiv1 x hx).deriv
  have hderiv2 : ∀ x, T < x →
      HasDerivAt (deriv (perpPut K lam)) (lam * (lam - 1) * perpPut K lam x / x ^ 2) x := by
    intro x hx
    have hx0 : 0 < x := hT.trans hx
    have hg : HasDerivAt (fun y => lam * perpPut K lam y / y)
        ((lam * (lam * perpPut K lam x / x) * x - lam * perpPut K lam x * 1) / x ^ 2) x :=
      ((hderiv1 x hx).const_mul lam).div (hasDerivAt_id' x) hx0.ne'
    have he : (lam * (lam * perpPut K lam x / x) * x - lam * perpPut K lam x * 1) / x ^ 2
        = lam * (lam - 1) * perpPut K lam x / x ^ 2 := by
      field_simp
    rw [he] at hg
    apply hg.congr_of_eventuallyEq
    filter_upwards [Ioi_mem_nhds hx] with y hy
    exact hderivEq y hy
  have hleft : HasDerivWithinAt (perpPut K lam) (-1) (Set.Iic T) T := by
    have h : HasDerivAt (fun y => K - y) (-1) T := by
      simpa using (hasDerivAt_id' T).const_sub K
    apply h.hasDerivWithinAt.congr
    · intro y hy
      exact hPl y hy
    · exact hPl T le_rfl
  have hright : HasDerivWithinAt (perpPut K lam) (-1) (Set.Ici T) T := by
    have h := hasDerivAt_powerPart (K - T) T lam T hT hT
    have hval : lam * ((K - T) * (T / T) ^ lam) / T = -1 := by
      rw [div_self hT.ne', Real.one_rpow, mul_one, mul_comm, hkey]
      field_simp
    rw [hval] at h
    apply h.hasDerivWithinAt.congr
    · intro y hy
      rcases (Set.mem_Ici.mp hy).eq_or_lt with h' | h'
      · rw [← h', hPl T le_rfl, div_self hT.ne', Real.one_rpow, mul_one]
      · exact hPf y h'
    · rw [hPl T le_rfl, div_self hT.ne', Real.one_rpow, mul_one]
  have hpaste : HasDerivAt (perpPut K lam) (-1) T := by
    have := hleft.union hright
    rw [Set.Iic_union_Ici] at this
    exact hasDerivWithinAt_univ.mp this
  have hpay : ∀ S, max (K - S) 0 ≤ perpPut K lam S := by
    intro S
    rcases le_or_gt S T with h | h
    · rw [hPl S h]
      exact max_le le_rfl (by linarith)
    · rw [hPf S h]
      have hST : 0 < S / T := div_pos (hT.trans h) hT
      have hb := bernoulli_neg lam (S / T) hneg hST
      have hpos : 0 < (S / T) ^ lam := Real.rpow_pos_of_pos hST lam
      apply max_le
      · have he : K - S = (K - T) * (1 + lam * (S / T - 1)) := by
          have h' : (K - T) * (1 + lam * (S / T - 1)) = (K - T) + (K - T) * lam * (S / T - 1) := by
            ring
          rw [h', hkey]
          field_simp
          ring
        rw [he]
        exact mul_le_mul_of_nonneg_left hb (by linarith)
      · exact mul_nonneg (by linarith) hpos.le
  have hlim : Tendsto (perpPut K lam) atTop (𝓝 0) := by
    have h1 : Tendsto (fun x : ℝ => x / T) atTop atTop := tendsto_id.atTop_div_const hT
    have h2 : Tendsto (fun x : ℝ => (x / T) ^ lam) atTop (𝓝 0) := by
      have := (tendsto_rpow_neg_atTop (y := -lam) (by linarith)).comp h1
      simpa [Function.comp_def, neg_neg] using this
    have h3 := h2.const_mul (K - T)
    rw [mul_zero] at h3
    apply h3.congr'
    filter_upwards [eventually_gt_atTop T] with x hx
    exact (hPf x hx).symm
  refine ⟨⟨hT, hTK⟩, fun S hS => ⟨hderiv1 S hS, hderiv2 S hS⟩, ?_, hpaste, hpay, hlim⟩
  intro S hS
  have hS0 : 0 < S := hT.trans hS
  rw [(hderiv2 S hS).deriv, hderivEq S hS]
  have hq : σ ^ 2 / 2 * S ^ 2 * (lam * (lam - 1) * perpPut K lam S / S ^ 2) +
      (r - q) * S * (lam * perpPut K lam S / S) - r * perpPut K lam S
      = perpPut K lam S * quad r q σ lam := by
    unfold quad
    field_simp
    ring
  rw [hq, hroot, mul_zero]

/-- **A positive rate gives exactly one negative root** (When it holds). With a rate `r > 0`
and a volatility `σ > 0`, whatever the dividend yield `q`, the pricing quadratic
`½σ²x² + (r − q − ½σ²)x − r = 0` has exactly one negative root. -/
theorem pricing_quadratic_has_unique_negative_root
    (r q σ : ℝ) (hr : 0 < r) (hσ : 0 < σ) :
    ∃! lam : ℝ, lam < 0 ∧ quad r q σ lam = 0 := by
  have ha : 0 < σ ^ 2 := by positivity
  set b := r - q - σ ^ 2 / 2 with hb
  have hD : 0 < b ^ 2 + 4 * (σ ^ 2 / 2) * r := by positivity
  set s := Real.sqrt (b ^ 2 + 4 * (σ ^ 2 / 2) * r) with hsdef
  have hs2 : s ^ 2 = b ^ 2 + 4 * (σ ^ 2 / 2) * r := Real.sq_sqrt hD.le
  have hs0 : 0 ≤ s := Real.sqrt_nonneg _
  have hneg : -b - s < 0 := by nlinarith
  have hroot : quad r q σ ((-b - s) / σ ^ 2) = 0 := by
    unfold quad
    rw [← hb]
    field_simp
    linear_combination hs2
  refine ⟨(-b - s) / σ ^ 2, ⟨div_neg_of_neg_of_pos hneg ha, hroot⟩, ?_⟩
  rintro y ⟨hy, hyq⟩
  exact neg_roots_eq r q σ y _ hr hσ hy (div_neg_of_neg_of_pos hneg ha) hyq hroot

/-- **Smooth pasting picks the best trigger** (Step 5). With strike `K > 0`, rate `r > 0`,
volatility `σ > 0` and `λ` the negative root, for every share price `S > 0` the value
`(K − L)(S/L)^λ` of selling the first time the share touches a level `L` strictly between
`0` and the strike is largest at `L = S* = Kλ/(λ − 1)`, and strictly smaller at every
other such level. -/
theorem trigger_is_best_exercise_level
    (K r q σ lam : ℝ) (hK : 0 < K) (hr : 0 < r) (hσ : 0 < σ)
    (hroot : quad r q σ lam = 0) (hneg : lam < 0) (S : ℝ) (hS : 0 < S) :
    ∀ L ∈ Set.Ioo 0 K, L ≠ trigger K lam →
      (K - L) * (S / L) ^ lam < (K - trigger K lam) * (S / trigger K lam) ^ lam := by
  intro L hL hLT
  obtain ⟨hL0, hLK⟩ := hL
  have hT : 0 < trigger K lam := trigger_pos K lam hK hneg
  have hTK : trigger K lam < K := trigger_lt K lam hK hneg
  have hkey : (K - trigger K lam) * lam = - trigger K lam := trigger_key K lam hneg
  set T := trigger K lam with hTdef
  have hu : 0 < L / T := div_pos hL0 hT
  have hu1 : L / T ≠ 1 := fun h => hLT ((div_eq_one_iff_eq hT.ne').mp h)
  have hb := bernoulli_neg_strict lam (L / T) hneg hu hu1
  have hSL : 0 < S / L := div_pos hS hL0
  have hsplit : (S / T) ^ lam = (S / L) ^ lam * (L / T) ^ lam := by
    rw [← Real.mul_rpow hSL.le hu.le]
    congr 1
    field_simp
  have hpos : 0 < (S / L) ^ lam := Real.rpow_pos_of_pos hSL lam
  rw [hsplit]
  have he : K - L = (K - T) * (1 + lam * (L / T - 1)) := by
    have h' : (K - T) * (1 + lam * (L / T - 1)) = (K - T) + (K - T) * lam * (L / T - 1) := by
      ring
    rw [h', hkey]
    field_simp
    ring
  rw [he]
  have hKT : 0 < K - T := by linarith
  have h1 := mul_lt_mul_of_pos_left hb hKT
  nlinarith [mul_lt_mul_of_pos_right h1 hpos]

/-! The card's exact numbers. House market: `r = 5/100`, `q = 2/100`, `σ = 20/100`. -/

-- a = ½σ² = 0.02.
example : ((20 : ℚ) / 100) ^ 2 / 2 = 2 / 100 := by norm_num

-- b = r − q − ½σ² = 0.01.
example : (5 : ℚ) / 100 - 2 / 100 - (20 / 100) ^ 2 / 2 = 1 / 100 := by norm_num

-- The discriminant b² − 4ac = 0.0001 + 4 × 0.02 × 0.05 = 0.0041.
example : ((1 : ℚ) / 100) ^ 2 - 4 * (2 / 100) * (-(5 / 100)) = 41 / 10000 := by norm_num

-- Forgetting the dividend (q = 0): λ = −5/2 is the negative root of 0.02λ² + 0.03λ − 0.05 = 0 ...
example : quad (5 / 100) 0 (20 / 100) (-5 / 2) = 0 := by norm_num [quad]

-- ... and the trigger becomes 100 × (5/2)/(7/2) = 500/7 = $71.43.
example : trigger 100 (-5 / 2) = 500 / 7 := by norm_num [trigger]

-- Try r = 0.08: λ = −1 − √5 is the negative root of 0.02λ² + 0.04λ − 0.08 = 0 ...
example : quad (8 / 100) (2 / 100) (20 / 100) (-1 - √5) = 0 := by
  have h : √5 ^ 2 = 5 := Real.sq_sqrt (by norm_num)
  norm_num [quad]
  ring_nf
  rw [h]
  norm_num

-- ... and the trigger is 100(3 − √5) = $76.39.
example : trigger 100 (-1 - √5) = 100 * (3 - √5) := by
  have h : √5 ^ 2 = 5 := Real.sq_sqrt (by norm_num)
  have h2 : (-1 - √5 - 1 : ℝ) ≠ 0 := by nlinarith [Real.sqrt_nonneg 5]
  rw [trigger, div_eq_iff h2]
  ring_nf
  rw [h]
  ring

#print axioms bernoulli_neg
#print axioms bernoulli_neg_strict
#print axioms trigger_pos
#print axioms trigger_lt
#print axioms trigger_key
#print axioms hasDerivAt_powerPart
#print axioms perpPut_of_le
#print axioms perpPut_of_lt
#print axioms neg_roots_eq
#print axioms perpetual_put_formula_solves_and_pastes
#print axioms pricing_quadratic_has_unique_negative_root
#print axioms trigger_is_best_exercise_level

end PerpetualAmericanPut
