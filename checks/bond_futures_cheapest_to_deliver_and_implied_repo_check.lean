-- Treasury bond futures: the implied repo rate turns the net basis into cash times time times the gap to repo so the cheapest bond is the one with the highest implied repo, every bond's price per conversion factor is exactly 100 at a 6% yield, and a choice of bonds can only lower the futures price.
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Algebra.Order.BigOperators.Group.Finset
import Mathlib.Data.Finset.Lattice.Fold
import Mathlib.Basic.Real.Basic
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.Positivity
import Mathlib.Tactic.Ring

open Finset

/-- Clean price per 100 of face, on a coupon date, of a bond paying coupon `c` percent a year in
two halves with `n` half-years left, at a flat yield `y` compounded twice a year: every coupon
`c / 2` and the face `100` discounted at `y / 2` a half-year. -/
noncomputable def bondPrice (c : ℝ) (n : ℕ) (y : ℝ) : ℝ :=
  ∑ k ∈ range n, c / 2 * (1 + y / 2)⁻¹ ^ (k + 1) + 100 * (1 + y / 2)⁻¹ ^ n

/-- The conversion factor: the bond's price at a 6% yield, per 1 of face. -/
noncomputable def convFactor (c : ℝ) (n : ℕ) : ℝ :=
  bondPrice c n (6 / 100) / 100

/-- The implied repo rate: cash back at delivery (invoice `F · CF + AI_D` plus coupon `C`) over
cash paid today (`P₀ + AI₀`), less one, per year over `t` years. -/
noncomputable def impliedRepo (F CF AID C P₀ AI₀ t : ℝ) : ℝ :=
  ((F * CF + AID + C) / (P₀ + AI₀) - 1) / t

/-- The net basis at repo rate `r`: gross basis `P₀ - F · CF` minus carry
`C + AI_D - AI₀ - (P₀ + AI₀) r t`. -/
def netBasis (F CF AID C P₀ AI₀ r t : ℝ) : ℝ :=
  (P₀ - F * CF) - (C + AID - AI₀ - (P₀ + AI₀) * r * t)

/-- The implied repo and net-basis identity, and the cheapest-to-deliver rule it gives.
Take a basket of bonds `i`, each with clean price `P₀ i`, accrued today `AI₀ i`, accrued at
delivery `AID i`, coupon cash before delivery `C i` and conversion factor `CF i`, one futures
price `F`, one repo rate `r`, and `t` years to delivery. Suppose the cash paid today
`P₀ i + AI₀ i` and the time `t` are positive. Then each bond's net basis equals
`(P₀ + AI₀) · t · (r - r_imp)`, and so one bond has a net basis per dollar of cash paid no larger
than another's exactly when its implied repo rate is no smaller: the bond with the highest
implied repo rate is the cheapest to deliver. -/
theorem net_basis_eq_cash_times_repo_gap {B : Type*} (P₀ AI₀ AID C CF : B → ℝ) (F r t : ℝ)
    (hD : ∀ i, 0 < P₀ i + AI₀ i) (ht : 0 < t) :
    (∀ i, netBasis F (CF i) (AID i) (C i) (P₀ i) (AI₀ i) r t
        = (P₀ i + AI₀ i) * t * (r - impliedRepo F (CF i) (AID i) (C i) (P₀ i) (AI₀ i) t)) ∧
    (∀ i j, netBasis F (CF i) (AID i) (C i) (P₀ i) (AI₀ i) r t / (P₀ i + AI₀ i)
          ≤ netBasis F (CF j) (AID j) (C j) (P₀ j) (AI₀ j) r t / (P₀ j + AI₀ j) ↔
        impliedRepo F (CF j) (AID j) (C j) (P₀ j) (AI₀ j) t
          ≤ impliedRepo F (CF i) (AID i) (C i) (P₀ i) (AI₀ i) t) := by
  have key : ∀ i, netBasis F (CF i) (AID i) (C i) (P₀ i) (AI₀ i) r t
      = (P₀ i + AI₀ i) * t * (r - impliedRepo F (CF i) (AID i) (C i) (P₀ i) (AI₀ i) t) := by
    intro i
    have hDi := (hD i).ne'
    unfold netBasis impliedRepo
    field_simp
    ring
  refine ⟨key, fun i j => ?_⟩
  rw [key i, key j]
  rw [mul_assoc, mul_div_cancel_left₀ _ (hD i).ne', mul_assoc,
    mul_div_cancel_left₀ _ (hD j).ne']
  rw [mul_le_mul_iff_of_pos_left ht]
  constructor <;> intro h <;> linarith

/-- The 6% tie. For any bond with a coupon of zero or more, its price at a 6% yield divided by
its conversion factor is exactly 100: at 6% every bond in the basket is equally good to
deliver. -/
theorem price_per_factor_at_six_percent (c : ℝ) (n : ℕ) (hc : 0 ≤ c) :
    bondPrice c n (6 / 100) / convFactor c n = 100 := by
  have hpos : 0 < bondPrice c n (6 / 100) := by
    unfold bondPrice
    have h1 : 0 ≤ ∑ k ∈ range n, c / 2 * (1 + (6 / 100 : ℝ) / 2)⁻¹ ^ (k + 1) :=
      Finset.sum_nonneg (fun k _ => by positivity)
    have h2 : 0 < 100 * (1 + (6 / 100 : ℝ) / 2)⁻¹ ^ n := by positivity
    linarith
  unfold convFactor
  field_simp

/-- A choice of bonds can only lower the futures price. Take finitely many delivery-day outcomes
`s` with weights `p s` of zero or more, and `X s i`, bond `i`'s price per factor in outcome `s`.
Then the weighted average of the cheapest bond's price per factor is at most the smallest of
the bonds' weighted averages: `E[min_i X_i] ≤ min_i E[X_i]`. -/
theorem average_of_cheapest_le_cheapest_average {S B : Type*} [Fintype S] [Fintype B]
    [Nonempty B] (p : S → ℝ) (hp : ∀ s, 0 ≤ p s) (X : S → B → ℝ) :
    ∑ s, p s * univ.inf' univ_nonempty (X s)
      ≤ univ.inf' univ_nonempty (fun i => ∑ s, p s * X s i) := by
  refine Finset.le_inf' _ _ (fun i _ => ?_)
  refine Finset.sum_le_sum (fun s _ => ?_)
  exact mul_le_mul_of_nonneg_left (Finset.inf'_le _ (Finset.mem_univ i)) (hp s)

-- The quote 108-04 is 108 and 4/32, that is 108.125 = 865/8 per 100 of face.
example : (108 : ℚ) + 4 / 32 = 865 / 8 := by norm_num

-- The three factors on the card round to 0.851225, 0.901998 and 1.064324.
example : (8512245 : ℝ) / 10 ^ 7 ≤ convFactor 4 20 ∧ convFactor 4 20 < 8512255 / 10 ^ 7 := by
  norm_num [convFactor, bondPrice, Finset.sum_range_succ]

example : (9019975 : ℝ) / 10 ^ 7 ≤ convFactor 5 30 ∧ convFactor 5 30 < 9019985 / 10 ^ 7 := by
  norm_num [convFactor, bondPrice, Finset.sum_range_succ]

example : (10643235 : ℝ) / 10 ^ 7 ≤ convFactor (13 / 2) 50 ∧
    convFactor (13 / 2) 50 < 10643245 / 10 ^ 7 := by
  norm_num [convFactor, bondPrice, Finset.sum_range_succ]

#print axioms net_basis_eq_cash_times_repo_gap
#print axioms price_per_factor_at_six_percent
#print axioms average_of_cheapest_le_cheapest_average
