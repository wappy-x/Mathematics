-- Differentiating under the integral: if a function and its rate in the parameter are continuous on a closed rectangle, the derivative of its integral over a fixed interval is the integral of that rate, moving ends add height times speed at the right and subtract it at the left, and the area under x^n e^(-tx) from 0 to infinity is n!/t^(n+1).
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.Calculus.ParametricIntervalIntegral
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Analysis.SpecialFunctions.Gamma.Basic
import Mathlib.Data.Nat.Factorial.Basic
import Mathlib.Tactic.NormNum

open Set Real MeasureTheory

/-- **Fixed ends: the derivative goes inside.** Let f(s, x) be a height that depends on a
parameter s and a position x, and let f'(s, x) be its rate in s with x held still (the
partial derivative in s, taken within the closed parameter interval [p, q]). Suppose f and
f' are both continuous on the closed rectangle where s runs over [p, q] and x runs between
a and b. Then for every t strictly between p and q, the total F(s) = ∫ from a to b of
f(s, x) dx has derivative at t equal to ∫ from a to b of f'(t, x) dx: the rate of the
total is the total of the rates. -/
theorem deriv_integral_eq_integral_partial_deriv
    {f f' : ℝ → ℝ → ℝ} {p q a b t : ℝ}
    (hf : ContinuousOn (Function.uncurry f) (Icc p q ×ˢ uIcc a b))
    (hf' : ContinuousOn (Function.uncurry f') (Icc p q ×ˢ uIcc a b))
    (hderiv : ∀ x ∈ uIcc a b, ∀ s ∈ Icc p q,
      HasDerivWithinAt (fun s => f s x) (f' s x) (Icc p q) s)
    (ht : t ∈ Ioo p q) :
    HasDerivAt (fun s => ∫ x in a..b, f s x) (∫ x in a..b, f' t x) t := by
  have hK : IsCompact (Icc p q ×ˢ uIcc a b) := isCompact_Icc.prod isCompact_uIcc
  obtain ⟨M, hM⟩ := hK.exists_bound_of_continuousOn hf'
  have hsl : ∀ s ∈ Icc p q, ContinuousOn (f s) (uIcc a b) := fun s hs =>
    hf.comp (continuousOn_const.prodMk continuousOn_id) (fun x hx => ⟨hs, hx⟩)
  have hsl' : ∀ s ∈ Icc p q, ContinuousOn (f' s) (uIcc a b) := fun s hs =>
    hf'.comp (continuousOn_const.prodMk continuousOn_id) (fun x hx => ⟨hs, hx⟩)
  have htI : t ∈ Icc p q := Ioo_subset_Icc_self ht
  refine (intervalIntegral.hasDerivAt_integral_of_dominated_loc_of_deriv_le
    (bound := fun _ => M) (Ioo_mem_nhds ht.1 ht.2) ?_ ?_ ?_ ?_ ?_ ?_).2
  · filter_upwards [Ioo_mem_nhds ht.1 ht.2] with s hs
    exact ((hsl s (Ioo_subset_Icc_self hs)).mono uIoc_subset_uIcc).aestronglyMeasurable
      measurableSet_uIoc
  · exact (hsl t htI).intervalIntegrable
  · exact ((hsl' t htI).mono uIoc_subset_uIcc).aestronglyMeasurable measurableSet_uIoc
  · exact Filter.Eventually.of_forall fun x hx s hs =>
      hM (s, x) ⟨Ioo_subset_Icc_self hs, uIoc_subset_uIcc hx⟩
  · exact intervalIntegrable_const
  · exact Filter.Eventually.of_forall fun x hx s hs =>
      (hderiv x (uIoc_subset_uIcc hx) s (Ioo_subset_Icc_self hs)).hasDerivAt
        (Icc_mem_nhds hs.1 hs.2)

lemma leibniz_endpoint_aux {f f' : ℝ → ℝ → ℝ} {e : ℝ → ℝ} {e' p q c d t : ℝ}
    (hf : ContinuousOn (Function.uncurry f) (Icc p q ×ˢ Icc c d))
    (hf' : ContinuousOn (Function.uncurry f') (Icc p q ×ˢ Icc c d))
    (hderiv : ∀ x ∈ Icc c d, ∀ s ∈ Icc p q,
      HasDerivWithinAt (fun s => f s x) (f' s x) (Icc p q) s)
    (he_mem : ∀ s ∈ Icc p q, e s ∈ Icc c d)
    (he : HasDerivAt e e' t) (ht : t ∈ Ioo p q) :
    HasDerivAt (fun s => ∫ x in e t..e s, f s x) (f t (e t) * e') t := by
  have htI : t ∈ Icc p q := Ioo_subset_Icc_self ht
  have hcd : c ≤ d := (he_mem t htI).1.trans (he_mem t htI).2
  obtain ⟨M, hM⟩ := (isCompact_Icc.prod isCompact_Icc).exists_bound_of_continuousOn hf'
  have hsl : ∀ s ∈ Icc p q, ContinuousOn (f s) (Icc c d) := fun s hs =>
    hf.comp (continuousOn_const.prodMk continuousOn_id) (fun x hx => ⟨hs, hx⟩)
  have hsub : ∀ s ∈ Icc p q, uIcc (e t) (e s) ⊆ Icc c d := fun s hs =>
    uIcc_subset_Icc (he_mem t htI) (he_mem s hs)
  let g : ℝ → ℝ := fun x => f t (max c (min x d))
  have hclamp : ∀ x, max c (min x d) ∈ Icc c d := fun x =>
    ⟨le_max_left _ _, max_le hcd (min_le_right _ _)⟩
  have hgc : Continuous g :=
    (hsl t htI).comp_continuous (continuous_const.max (continuous_id.min continuous_const)) hclamp
  have hgeq : ∀ x ∈ Icc c d, g x = f t x := fun x hx => by
    simp only [g, min_eq_left hx.2, max_eq_right hx.1]
  have hL : HasDerivAt (fun s => ∫ x in e t..e s, g x) (f t (e t) * e') t := by
    have := (hgc.integral_hasStrictDerivAt (e t) (e t)).hasDerivAt.comp t he
    rw [hgeq _ (he_mem t htI)] at this
    exact this
  have hR : HasDerivAt (fun s => ∫ x in e t..e s, (f s x - f t x)) 0 t := by
    rw [hasDerivAt_iff_isLittleO]
    have hbound : ∀ᶠ s in nhds t,
        ‖∫ x in e t..e s, (f s x - f t x)‖ ≤ M * ‖(s - t) * (e s - e t)‖ := by
      filter_upwards [Icc_mem_nhds ht.1 ht.2] with s hs
      have key : ∀ x ∈ uIoc (e t) (e s), ‖f s x - f t x‖ ≤ M * |s - t| := by
        intro x hx
        have hx' : x ∈ Icc c d := hsub s hs (uIoc_subset_uIcc hx)
        have := Convex.norm_image_sub_le_of_norm_hasDerivWithin_le (f := fun s => f s x)
          (f' := fun s => f' s x) (fun s hs => hderiv x hx' s hs)
          (fun s hs => hM (s, x) ⟨hs, hx'⟩) (convex_Icc p q) htI hs
        simpa [Real.norm_eq_abs] using this
      have := intervalIntegral.norm_integral_le_of_norm_le_const key
      calc _ ≤ _ := this
        _ = _ := by rw [norm_mul, Real.norm_eq_abs, Real.norm_eq_abs]; ring
    have h0 : (fun s => e s - e t) =o[nhds t] (fun _ => (1:ℝ)) := by
      rw [Asymptotics.isLittleO_one_iff]
      simpa using he.continuousAt.tendsto.sub_const (e t)
    have h2 : (fun s => (s - t) * (e s - e t)) =o[nhds t] (fun s => (s - t) * 1) :=
      (Asymptotics.isBigO_refl _ _).mul_isLittleO h0
    simp only [mul_one] at h2
    have h3 : (fun s => ∫ x in e t..e s, (f s x - f t x)) =O[nhds t]
        (fun s => (s - t) * (e s - e t)) := Asymptotics.IsBigO.of_bound M hbound
    simpa using h3.trans_isLittleO h2
  refine (hL.add hR).congr_of_eventuallyEq ?_ |>.congr_deriv (add_zero _)
  filter_upwards [Icc_mem_nhds ht.1 ht.2] with s hs
  simp only [Pi.add_apply]
  have i1 : IntervalIntegrable (f s) volume (e t) (e s) :=
    ((hsl s hs).mono (hsub s hs)).intervalIntegrable
  have i2 : IntervalIntegrable (f t) volume (e t) (e s) :=
    ((hsl t htI).mono (hsub s hs)).intervalIntegrable
  rw [intervalIntegral.integral_sub i1 i2,
    intervalIntegral.integral_congr (g := f t) (fun x hx => hgeq x (hsub s hs hx))]
  ring

#print axioms leibniz_endpoint_aux

/-- **Moving ends: the Leibniz integral rule.** Let f and its rate f' in the parameter s be
continuous on the closed rectangle where s runs over [p, q] and x runs over [c, d], with f'
the partial derivative of f in s there. Let the ends a(s) and b(s) sit inside [c, d] for
every s in [p, q], so f is continuous where the ends sit, and let them have speeds a' and
b' at a parameter value t strictly between p and q. Then the total
J(s) = ∫ from a(s) to b(s) of f(s, x) dx has derivative at t equal to
∫ from a(t) to b(t) of f'(t, x) dx + f(t, b(t)) · b' − f(t, a(t)) · a': the heights inside
change, the right end adds its height times its speed, and the left end subtracts it. -/
theorem leibniz_integral_rule
    {f f' : ℝ → ℝ → ℝ} {a b : ℝ → ℝ} {a' b' p q c d t : ℝ}
    (hf : ContinuousOn (Function.uncurry f) (Icc p q ×ˢ Icc c d))
    (hf' : ContinuousOn (Function.uncurry f') (Icc p q ×ˢ Icc c d))
    (hderiv : ∀ x ∈ Icc c d, ∀ s ∈ Icc p q,
      HasDerivWithinAt (fun s => f s x) (f' s x) (Icc p q) s)
    (ha_mem : ∀ s ∈ Icc p q, a s ∈ Icc c d) (hb_mem : ∀ s ∈ Icc p q, b s ∈ Icc c d)
    (ha : HasDerivAt a a' t) (hb : HasDerivAt b b' t)
    (ht : t ∈ Ioo p q) :
    HasDerivAt (fun s => ∫ x in a s..b s, f s x)
      ((∫ x in a t..b t, f' t x) + f t (b t) * b' - f t (a t) * a') t := by
  have htI : t ∈ Icc p q := Ioo_subset_Icc_self ht
  have hsl : ∀ s ∈ Icc p q, ContinuousOn (f s) (Icc c d) := fun s hs =>
    hf.comp (continuousOn_const.prodMk continuousOn_id) (fun x hx => ⟨hs, hx⟩)
  have hint : ∀ s ∈ Icc p q, ∀ u ∈ Icc c d, ∀ v ∈ Icc c d,
      IntervalIntegrable (f s) volume u v := fun s hs u hu v hv =>
    ((hsl s hs).mono (uIcc_subset_Icc hu hv)).intervalIntegrable
  have hsub : uIcc (a t) (b t) ⊆ Icc c d := uIcc_subset_Icc (ha_mem t htI) (hb_mem t htI)
  have hmid : HasDerivAt (fun s => ∫ x in a t..b t, f s x) (∫ x in a t..b t, f' t x) t :=
    deriv_integral_eq_integral_partial_deriv (hf.mono (prod_mono subset_rfl hsub))
      (hf'.mono (prod_mono subset_rfl hsub)) (fun x hx s hs => hderiv x (hsub hx) s hs) ht
  have hB := leibniz_endpoint_aux hf hf' hderiv hb_mem hb ht
  have hA := leibniz_endpoint_aux hf hf' hderiv ha_mem ha ht
  refine ((hmid.add hB).sub hA).congr_of_eventuallyEq ?_
  filter_upwards [Icc_mem_nhds ht.1 ht.2] with s hs
  have h1 := intervalIntegral.integral_add_adjacent_intervals
    (hint s hs _ (ha_mem s hs) _ (ha_mem t htI)) (hint s hs _ (ha_mem t htI) _ (hb_mem s hs))
  have h2 := intervalIntegral.integral_add_adjacent_intervals
    (hint s hs _ (ha_mem t htI) _ (hb_mem t htI)) (hint s hs _ (hb_mem t htI) _ (hb_mem s hs))
  have h3 := intervalIntegral.integral_symm (f := f s) (μ := volume) (a s) (a t)
  simp only [Pi.add_apply, Pi.sub_apply]
  linarith

/-- **The hard integral.** For every whole number n and every decay rate t > 0, the area
under x^n e^(-tx) for x from 0 out to infinity is n!/t^(n+1). At t = 1 the area is n!. -/
theorem integral_pow_mul_exp_neg_mul_eq_factorial_div (n : ℕ) {t : ℝ} (ht : 0 < t) :
    ∫ x in Ioi (0 : ℝ), x ^ n * exp (-(t * x)) = (n.factorial : ℝ) / t ^ (n + 1) := by
  have h := Real.integral_rpow_mul_exp_neg_mul_Ioi (a := (n : ℝ) + 1) (by positivity) ht
  have h2 : ((n : ℝ) + 1 - 1) = (n : ℝ) := by ring
  rw [h2, Real.Gamma_nat_eq_factorial] at h
  have h3 : ∫ x in Ioi (0 : ℝ), x ^ n * exp (-(t * x)) =
      ∫ x in Ioi (0 : ℝ), x ^ (n : ℝ) * exp (-(t * x)) :=
    setIntegral_congr_fun measurableSet_Ioi (fun x _ => by simp only [Real.rpow_natCast])
  rw [h3, h, div_rpow zero_le_one ht.le, one_rpow]
  have h4 : t ^ ((n : ℝ) + 1) = t ^ (n + 1) := by
    rw [← Real.rpow_natCast]; push_cast; rfl
  rw [h4]
  field_simp

-- The areas at t = 1 for n = 0, 1, 2, 3, 4 are the factorials 1, 1, 2, 6, 24.
example : (Nat.factorial 0, Nat.factorial 1, Nat.factorial 2, Nat.factorial 3,
    Nat.factorial 4) = (1, 1, 2, 6, 24) := by decide
-- The curve x^3 e^(-x) has area 3! = 6; with a fourth power the area is 4! = 24.
example : Nat.factorial 3 = 6 ∧ Nat.factorial 4 = 24 := by decide
-- Differentiating 1/t three times brings down -1, -2, -3: the coefficient is -6, and the sign
-- flip gives 6/t^4.
example : ((-1 : ℤ) * (-2) * (-3)) = -6 := by norm_num
-- At t = 2 the n = 3 area is 3!/2^4 = 6/16 = 3/8 (the card's 0.375).
example : (Nat.factorial 3 : ℚ) / 2 ^ 4 = 3 / 8 := by norm_num [Nat.factorial]
-- Doubling the decay rate cuts the area sixteenfold: each of the four factors of 1/t halves it.
example : ((Nat.factorial 3 : ℚ) / 1 ^ 4) / ((Nat.factorial 3 : ℚ) / 2 ^ 4) = 16 := by
  norm_num [Nat.factorial]

#print axioms deriv_integral_eq_integral_partial_deriv
#print axioms leibniz_integral_rule
#print axioms integral_pow_mul_exp_neg_mul_eq_factorial_div
