-- Deciding under uncertainty: a perfect forecast is worth the expected regret of the best plan, every forecast is worth between zero and that, and the market stall's numbers come out exactly.
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Algebra.Order.BigOperators.Group.Finset
import Mathlib.Data.Real.Basic
import Mathlib.Data.Fintype.Basic
import Mathlib.Order.Fin.Basic
import Mathlib.Tactic

open Finset

namespace DecisionTheory

variable {A S M : Type*} [Fintype A] [Nonempty A] [Fintype S] [Fintype M]

/-- The best plan without information: the largest expected profit `max_a E[x(a, S)]`,
for prior chances `p` on the states and profits `x a s`. -/
noncomputable def bestPlan (p : S → ℝ) (x : A → S → ℝ) : ℝ :=
  univ.sup' univ_nonempty (fun a => ∑ s, p s * x a s)

/-- The plan with a perfect forecast: `E[max_a x(a, S)]`. -/
noncomputable def withPerfect (p : S → ℝ) (x : A → S → ℝ) : ℝ :=
  ∑ s, p s * univ.sup' univ_nonempty (fun a => x a s)

/-- Expected value of perfect information: `E[max_a x(a, S)] - max_a E[x(a, S)]`. -/
noncomputable def evpi (p : S → ℝ) (x : A → S → ℝ) : ℝ :=
  withPerfect p x - bestPlan p x

/-- Chance `P(m)` that the forecast says `m`, when `L s m` is the chance it says `m` in state `s`. -/
def msgProb (p : S → ℝ) (L : S → M → ℝ) (m : M) : ℝ :=
  ∑ s, p s * L s m

/-- Bayes' rule: the chance `P(s | m)` of state `s` after the forecast says `m`. -/
noncomputable def postProb (p : S → ℝ) (L : S → M → ℝ) (m : M) (s : S) : ℝ :=
  p s * L s m / msgProb p L m

/-- The plan with the forecast: `∑_m P(m) max_a ∑_s P(s | m) x(a, s)`. -/
noncomputable def withForecast (p : S → ℝ) (L : S → M → ℝ) (x : A → S → ℝ) : ℝ :=
  ∑ m, msgProb p L m * univ.sup' univ_nonempty (fun a => ∑ s, postProb p L m s * x a s)

/-- Expected value of sample information:
`∑_m P(m) max_a ∑_s P(s | m) x(a, s) - max_a E[x(a, S)]`. -/
noncomputable def evsi (p : S → ℝ) (L : S → M → ℝ) (x : A → S → ℝ) : ℝ :=
  withForecast p L x - bestPlan p x

lemma mul_sup'_eq_aux {ι : Type*} (t : Finset ι) (h : t.Nonempty) (f : ι → ℝ) (c : ℝ)
    (hc : 0 ≤ c) : c * t.sup' h f = t.sup' h (fun i => c * f i) := by
  obtain ⟨i, hi, he⟩ := exists_mem_eq_sup' h f
  apply le_antisymm
  · rw [he]; exact le_sup' (fun i => c * f i) hi
  · exact sup'_le _ _ fun j hj => mul_le_mul_of_nonneg_left (le_sup' f hj) hc

lemma msgProb_mul_postProb (p : S → ℝ) (hp : ∀ s, 0 ≤ p s) (L : S → M → ℝ)
    (hL : ∀ s m, 0 ≤ L s m) (m : M) (s : S) :
    msgProb p L m * postProb p L m s = p s * L s m := by
  by_cases h : msgProb p L m = 0
  · have h2 : p s * L s m = 0 :=
      (Finset.sum_eq_zero_iff_of_nonneg (fun i _ => mul_nonneg (hp i) (hL i m))).1 h s
        (mem_univ s)
    rw [h, h2, zero_mul]
  · unfold postProb
    field_simp

lemma withForecast_eq_aux (p : S → ℝ) (hp : ∀ s, 0 ≤ p s) (L : S → M → ℝ)
    (hL : ∀ s m, 0 ≤ L s m) (x : A → S → ℝ) :
    withForecast p L x = ∑ m, univ.sup' univ_nonempty (fun a => ∑ s, p s * L s m * x a s) := by
  unfold withForecast
  refine sum_congr rfl fun m _ => ?_
  rw [mul_sup'_eq_aux _ _ _ (msgProb p L m) (sum_nonneg fun s _ => mul_nonneg (hp s) (hL s m))]
  congr 1
  funext a
  rw [mul_sum]
  refine sum_congr rfl fun s _ => ?_
  rw [← mul_assoc, msgProb_mul_postProb p hp L hL]

lemma sup'_bool_aux (h : (univ : Finset Bool).Nonempty) (f : Bool → ℝ) :
    univ.sup' h f = max (f true) (f false) := by
  apply le_antisymm
  · exact sup'_le _ _ fun b _ => by cases b <;> simp
  · exact max_le (le_sup' f (mem_univ _)) (le_sup' f (mem_univ _))

#print axioms mul_sup'_eq_aux
#print axioms msgProb_mul_postProb
#print axioms withForecast_eq_aux
#print axioms sup'_bool_aux

/-- Any forecast's value lies between zero and the value of a perfect forecast:
with known chances on the states, known profits for each action and state, and a forecast whose
chance of each message in each state is known, `0 ≤ EVSI ≤ EVPI`. -/
theorem evsi_nonneg_and_le_evpi (p : S → ℝ) (hp : ∀ s, 0 ≤ p s) (hp1 : ∑ s, p s = 1)
    (L : S → M → ℝ) (hL : ∀ s m, 0 ≤ L s m) (hL1 : ∀ s, ∑ m, L s m = 1)
    (x : A → S → ℝ) :
    0 ≤ evsi p L x ∧ evsi p L x ≤ evpi p x := by
  constructor
  · unfold evsi bestPlan
    rw [sub_nonneg, withForecast_eq_aux p hp L hL]
    obtain ⟨a, _, ha⟩ := exists_mem_eq_sup' univ_nonempty (fun a => ∑ s, p s * x a s)
    rw [ha]
    calc ∑ s, p s * x a s = ∑ s, ∑ m, p s * L s m * x a s := by
          refine sum_congr rfl fun s _ => ?_
          rw [← sum_mul, ← mul_sum, hL1, mul_one]
      _ = ∑ m, ∑ s, p s * L s m * x a s := sum_comm
      _ ≤ _ := sum_le_sum fun m _ =>
          le_sup' (fun a => ∑ s, p s * L s m * x a s) (mem_univ a)
  · unfold evsi evpi withPerfect
    rw [sub_le_sub_iff_right, withForecast_eq_aux p hp L hL]
    calc ∑ m, univ.sup' univ_nonempty (fun a => ∑ s, p s * L s m * x a s)
        ≤ ∑ m, ∑ s, p s * L s m * univ.sup' univ_nonempty (fun a => x a s) :=
          sum_le_sum fun m _ => sup'_le _ _ fun a _ => sum_le_sum fun s _ =>
            mul_le_mul_of_nonneg_left (le_sup' (fun a => x a s) (mem_univ a))
              (mul_nonneg (hp s) (hL s m))
      _ = ∑ s, ∑ m, p s * L s m * univ.sup' univ_nonempty (fun a => x a s) := sum_comm
      _ = _ := sum_congr rfl fun s _ => by rw [← sum_mul, ← mul_sum, hL1, mul_one]

/-- A perfect forecast's value equals the expected regret of the best plan made without it:
if `a₀` has the largest expected profit, then
`EVPI = E[max_a x(a, S) - x(a₀, S)]`. -/
theorem evpi_eq_expected_regret (p : S → ℝ) (hp : ∀ s, 0 ≤ p s) (hp1 : ∑ s, p s = 1)
    (x : A → S → ℝ) (a₀ : A) (ha₀ : ∀ a, ∑ s, p s * x a s ≤ ∑ s, p s * x a₀ s) :
    evpi p x = ∑ s, p s * (univ.sup' univ_nonempty (fun a => x a s) - x a₀ s) := by
  have hb : bestPlan p x = ∑ s, p s * x a₀ s :=
    le_antisymm (sup'_le _ _ fun a _ => ha₀ a) (le_sup' (fun a => ∑ s, p s * x a s) (mem_univ a₀))
  unfold evpi withPerfect
  rw [hb]
  simp only [mul_sub, sum_sub_distrib]

/-! The market stall. States: `true` = sun, `false` = rain. Actions: `true` = big order,
`false` = small order. Messages: `true` = "says sun", `false` = "says rain". -/

/-- Chance of sun 0.6. -/
noncomputable def stallPrior (s : Bool) : ℝ := if s then 3 / 5 else 2 / 5

/-- Big order: £600 in sun, −£300 in rain. Small order: £250 in sun, £50 in rain. -/
def stallProfit (a s : Bool) : ℝ :=
  if a then (if s then 600 else -300) else (if s then 250 else 50)

/-- A forecast right with chance `q` in either weather. -/
def stallForecast (q : ℝ) (s m : Bool) : ℝ := if m = s then q else 1 - q

/-- The stall: a perfect forecast is worth £140, and a forecast of accuracy `q` between 0.5 and 1
is worth `max 0 (350q - 210)` pounds: nothing up to 0.6, and £70 at 0.8. -/
theorem stall_evpi_and_evsi (q : ℝ) (hq : 1 / 2 ≤ q) (hq1 : q ≤ 1) :
    evpi stallPrior stallProfit = 140 ∧
      evsi stallPrior (stallForecast q) stallProfit = max 0 (350 * q - 210) := by
  have hp : ∀ s, 0 ≤ stallPrior s := fun s => by cases s <;> norm_num [stallPrior]
  have hL : ∀ s m, 0 ≤ stallForecast q s m := fun s m => by
    unfold stallForecast; split_ifs <;> linarith
  constructor
  · unfold evpi withPerfect bestPlan
    simp only [Fintype.sum_bool, sup'_bool_aux, stallPrior, stallProfit]
    norm_num
  · unfold evsi bestPlan
    rw [withForecast_eq_aux _ hp _ hL]
    simp only [Fintype.sum_bool, sup'_bool_aux, stallPrior, stallProfit, stallForecast]
    simp only [ite_true, Bool.false_eq_true, ite_false, reduceCtorEq]
    simp only [max_def]
    split_ifs <;> linarith


-- Folding back the tree without a forecast: big £240, small £170.
example : (3 / 5 : ℚ) * 600 + 2 / 5 * (-300) = 240 := by norm_num
example : (3 / 5 : ℚ) * 250 + 2 / 5 * 50 = 170 := by norm_num
-- Perfect forecast: £380, so EVPI = £140, and the regret of big in rain gives the same £140.
example : (3 / 5 : ℚ) * 600 + 2 / 5 * 50 = 380 := by norm_num
example : (380 : ℚ) - 240 = 140 := by norm_num
example : (2 / 5 : ℚ) * (50 - (-300)) = 140 := by norm_num
-- 1,000 Saturdays: the forecast says "sun" on 560 and "rain" on 440.
example : 480 + 80 = 560 ∧ 120 + 320 = 440 := by decide
-- Total profit over 1,000 Saturdays: always big £240,000; big after "sun", small after "rain" £310,000.
example : (600 * 600 - 400 * 300 : ℤ) = 240000 := by norm_num
example : (480 * 600 - 80 * 300 + 120 * 250 + 320 * 50 : ℤ) = 310000 := by norm_num
-- EVSI = 310 − 240 = £70 = 350 × 0.8 − 210, and at a £50 fee the manager is £20 ahead.
example : (310 : ℚ) - 240 = 70 ∧ 350 * (4 / 5 : ℚ) - 210 = 70 ∧ (70 : ℚ) - 50 = 20 := by norm_num

#print axioms evsi_nonneg_and_le_evpi
#print axioms evpi_eq_expected_regret
#print axioms stall_evpi_and_evsi

end DecisionTheory
