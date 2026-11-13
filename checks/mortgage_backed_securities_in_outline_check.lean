-- Mortgage-backed securities in outline: sequential tranches and the IO/PO pair always add up to the pool's value, a pass-through discounted at its own note rate is worth exactly its starting balance, and the IO is worth less when prepayment is faster.
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Algebra.Order.Field.Basic
import Mathlib.Data.Real.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic

open Finset

noncomputable section

/-! A pool's balance after month `k` is `B k`. Month `k ≥ 1` pays interest `i * B (k - 1)` and
principal `B (k - 1) - B k` (scheduled plus prepaid). The IO gets the interest, the PO gets
the principal, and the pass-through gets both. Three sequential tranches A, B, C, with balances
`t = (a, b, c)`, each earn interest at the note rate `i` on their own balance; the month's
principal goes to A until A is repaid, then to B, then to C. -/

/-- The pool's principal in month `k`: the drop in balance. -/
def principal (B : ℕ → ℝ) (k : ℕ) : ℝ := B (k - 1) - B k

/-- The sequential rule: principal `p` paid to A, then B, then C, given their balances `t`. -/
def seqPay (t : ℝ × ℝ × ℝ) (p : ℝ) : ℝ × ℝ × ℝ :=
  (min t.1 p, min t.2.1 (p - min t.1 p), min t.2.2 (p - min t.1 p - min t.2.1 (p - min t.1 p)))

/-- Tranche balances after month `k`, starting from `t0`, when the pool pays principal `Q k`. -/
def trBal (t0 : ℝ × ℝ × ℝ) (Q : ℕ → ℝ) : ℕ → ℝ × ℝ × ℝ
  | 0 => t0
  | k + 1 => trBal t0 Q k - seqPay (trBal t0 Q k) (Q (k + 1))

/-- Cash to the pass-through in month `k`: interest plus all principal. -/
def poolCash (i : ℝ) (B : ℕ → ℝ) (k : ℕ) : ℝ := i * B (k - 1) + principal B k

/-- Cash to the interest-only strip in month `k`. -/
def ioCash (i : ℝ) (B : ℕ → ℝ) (k : ℕ) : ℝ := i * B (k - 1)

/-- Cash to the principal-only strip in month `k`. -/
def poCash (B : ℕ → ℝ) (k : ℕ) : ℝ := principal B k

/-- Cash to tranche A in month `k`: interest on its balance plus its share of principal. -/
def cashA (i : ℝ) (t0 : ℝ × ℝ × ℝ) (B : ℕ → ℝ) (k : ℕ) : ℝ :=
  i * (trBal t0 (principal B) (k - 1)).1 + (seqPay (trBal t0 (principal B) (k - 1)) (principal B k)).1

/-- Cash to tranche B in month `k`. -/
def cashB (i : ℝ) (t0 : ℝ × ℝ × ℝ) (B : ℕ → ℝ) (k : ℕ) : ℝ :=
  i * (trBal t0 (principal B) (k - 1)).2.1 +
    (seqPay (trBal t0 (principal B) (k - 1)) (principal B k)).2.1

/-- Cash to tranche C in month `k`. -/
def cashC (i : ℝ) (t0 : ℝ × ℝ × ℝ) (B : ℕ → ℝ) (k : ℕ) : ℝ :=
  i * (trBal t0 (principal B) (k - 1)).2.2 +
    (seqPay (trBal t0 (principal B) (k - 1)) (principal B k)).2.2

/-- The value of a slice: over a finite set of rate paths with weights `w` (the average uses
`w ω = 1 / #paths`), the weighted sum of its monthly cash `X ω k` times the discount factor
`D ω k` along that path, for months `1` to `n`. -/
def sliceValue {Ω : Type*} (paths : Finset Ω) (w : Ω → ℝ) (D : Ω → ℕ → ℝ) (n : ℕ)
    (X : Ω → ℕ → ℝ) : ℝ :=
  ∑ ω ∈ paths, w ω * ∑ k ∈ Icc 1 n, D ω k * X ω k

/-- The sequential rule pays out exactly `p` and never more than a tranche's balance. -/
theorem seqPay_spec (x y z p : ℝ) (hx : 0 ≤ x) (hy : 0 ≤ y) (hz : 0 ≤ z) (hp : 0 ≤ p)
    (hpt : p ≤ x + y + z) :
    (seqPay (x, y, z) p).1 + (seqPay (x, y, z) p).2.1 + (seqPay (x, y, z) p).2.2 = p ∧
      (seqPay (x, y, z) p).1 ≤ x ∧ (seqPay (x, y, z) p).2.1 ≤ y ∧
      (seqPay (x, y, z) p).2.2 ≤ z := by
  simp only [seqPay]
  rcases le_total x p with h1 | h1
  · rw [min_eq_left h1]
    rcases le_total y (p - x) with h2 | h2
    · rw [min_eq_left h2, min_eq_right (by linarith : p - x - y ≤ z)]
      refine ⟨by ring, le_refl _, le_refl _, by linarith⟩
    · rw [min_eq_right h2, min_eq_right (by linarith : p - x - (p - x) ≤ z)]
      refine ⟨by ring, le_refl _, h2, by linarith⟩
  · rw [min_eq_right h1, sub_self, min_eq_right hy, sub_zero, min_eq_right hz]
    refine ⟨by ring, h1, hy, hz⟩

/-- The tranche balances stay nonnegative and add up to the pool's balance. -/
theorem trBal_spec (a b c : ℝ) (B : ℕ → ℝ) (n : ℕ) (ha : 0 ≤ a) (hb : 0 ≤ b) (hc : 0 ≤ c)
    (hstart : a + b + c = B 0) (hfall : ∀ k, k < n → B (k + 1) ≤ B k)
    (hnonneg : ∀ k, k ≤ n → 0 ≤ B k) :
    ∀ k, k ≤ n → 0 ≤ (trBal (a, b, c) (principal B) k).1 ∧
      0 ≤ (trBal (a, b, c) (principal B) k).2.1 ∧ 0 ≤ (trBal (a, b, c) (principal B) k).2.2 ∧
      (trBal (a, b, c) (principal B) k).1 + (trBal (a, b, c) (principal B) k).2.1 +
        (trBal (a, b, c) (principal B) k).2.2 = B k := by
  intro k
  induction k with
  | zero => intro _; exact ⟨ha, hb, hc, hstart⟩
  | succ k ih =>
    intro hk
    obtain ⟨h1, h2, h3, hs⟩ := ih (by omega)
    have hp0 : 0 ≤ principal B (k + 1) := by
      simp only [principal, Nat.add_sub_cancel]; linarith [hfall k (by omega)]
    have hpt : principal B (k + 1) ≤ (trBal (a, b, c) (principal B) k).1 +
        (trBal (a, b, c) (principal B) k).2.1 + (trBal (a, b, c) (principal B) k).2.2 := by
      rw [hs]; simp only [principal, Nat.add_sub_cancel]; linarith [hnonneg (k + 1) hk]
    have key := seqPay_spec _ _ _ _ h1 h2 h3 hp0 hpt
    simp only [Prod.mk.eta] at key
    obtain ⟨e, l1, l2, l3⟩ := key
    simp only [trBal, Prod.fst_sub, Prod.snd_sub]
    refine ⟨by linarith, by linarith, by linarith, ?_⟩
    have : principal B (k + 1) = B k - B (k + 1) := by simp [principal]
    linarith

/-- Values add when cash flows add. -/
theorem sliceValue_add {Ω : Type*} (paths : Finset Ω) (w : Ω → ℝ) (D : Ω → ℕ → ℝ) (n : ℕ)
    (X Y : Ω → ℕ → ℝ) :
    sliceValue paths w D n X + sliceValue paths w D n Y =
      sliceValue paths w D n (fun ω k => X ω k + Y ω k) := by
  simp only [sliceValue, mul_add, Finset.sum_add_distrib]

/-- Values agree when the cash flows agree in months `1` to `n` on every path. -/
theorem sliceValue_congr {Ω : Type*} (paths : Finset Ω) (w : Ω → ℝ) (D : Ω → ℕ → ℝ) (n : ℕ)
    (X Y : Ω → ℕ → ℝ) (h : ∀ ω ∈ paths, ∀ k ∈ Icc 1 n, X ω k = Y ω k) :
    sliceValue paths w D n X = sliceValue paths w D n Y := by
  unfold sliceValue
  refine Finset.sum_congr rfl (fun ω hω => ?_)
  congr 1
  exact Finset.sum_congr rfl (fun k hk => by rw [h ω hω k hk])

#print axioms seqPay_spec
#print axioms trBal_spec
#print axioms sliceValue_add
#print axioms sliceValue_congr

/-- Slicing creates nothing. On every path the pool's balance falls month by month and stays
at or above zero (principal is never negative and never more than what is owed), and the
tranches A, B, C start with nonnegative balances that add up to the pool's starting balance.
Then, for any discount factors and any weights on the paths, the three sequential tranches'
values add up to the pass-through's value, and so do the IO's and the PO's:
`V_A + V_B + V_C = V_pool` and `V_IO + V_PO = V_pool`. -/
theorem slices_add_up_to_pool {Ω : Type*} (paths : Finset Ω) (w : Ω → ℝ)
    (D : Ω → ℕ → ℝ) (n : ℕ) (i a b c : ℝ) (B : Ω → ℕ → ℝ)
    (ha : 0 ≤ a) (hb : 0 ≤ b) (hc : 0 ≤ c)
    (hstart : ∀ ω, a + b + c = B ω 0)
    (hfall : ∀ ω k, k < n → B ω (k + 1) ≤ B ω k)
    (hnonneg : ∀ ω k, k ≤ n → 0 ≤ B ω k) :
    sliceValue paths w D n (fun ω => cashA i (a, b, c) (B ω)) +
        sliceValue paths w D n (fun ω => cashB i (a, b, c) (B ω)) +
        sliceValue paths w D n (fun ω => cashC i (a, b, c) (B ω)) =
      sliceValue paths w D n (fun ω => poolCash i (B ω)) ∧
    sliceValue paths w D n (fun ω => ioCash i (B ω)) +
        sliceValue paths w D n (fun ω => poCash (B ω)) =
      sliceValue paths w D n (fun ω => poolCash i (B ω)) := by
  refine ⟨?_, ?_⟩
  · rw [sliceValue_add, sliceValue_add]
    apply sliceValue_congr
    intro ω _ k hk
    rw [Finset.mem_Icc] at hk
    obtain ⟨m, rfl⟩ : ∃ m, k = m + 1 := ⟨k - 1, by omega⟩
    have hspec := trBal_spec a b c (B ω) n ha hb hc (hstart ω) (fun k hk => hfall ω k hk)
      (fun k hk => hnonneg ω k hk) m (by omega)
    obtain ⟨h1, h2, h3, hs⟩ := hspec
    have hp0 : 0 ≤ principal (B ω) (m + 1) := by
      simp only [principal, Nat.add_sub_cancel]; linarith [hfall ω m (by omega)]
    have hpt : principal (B ω) (m + 1) ≤ (trBal (a, b, c) (principal (B ω)) m).1 +
        (trBal (a, b, c) (principal (B ω)) m).2.1 + (trBal (a, b, c) (principal (B ω)) m).2.2 := by
      rw [hs]; simp only [principal, Nat.add_sub_cancel]; linarith [hnonneg ω (m + 1) (by omega)]
    have key := seqPay_spec _ _ _ _ h1 h2 h3 hp0 hpt
    simp only [Prod.mk.eta] at key
    obtain ⟨e, -, -, -⟩ := key
    simp only [cashA, cashB, cashC, poolCash, Nat.add_sub_cancel]
    linear_combination i * hs + e
  · rw [sliceValue_add]
    apply sliceValue_congr
    intro ω _ k _
    simp only [ioCash, poCash, poolCash]

/-- A pass-through discounted at its own note rate is worth par. If the loans are fully
repaid by month `n` (`B n = 0`), then the pass-through's cash, interest `i * B (k - 1)` plus
principal `B (k - 1) - B k`, discounted one month at a time at `1 + i`, is worth exactly the
starting balance `B 0`, whatever the principal schedule, so at any prepayment speed. -/
theorem pass_through_at_note_rate_is_par (i : ℝ) (hi : 0 ≤ i) (n : ℕ) (B : ℕ → ℝ)
    (hBn : B n = 0) :
    ∑ k ∈ Icc 1 n, (i * B (k - 1) + (B (k - 1) - B k)) / (1 + i) ^ k = B 0 := by
  have h1 : (1 + i) ≠ 0 := by positivity
  have key : ∀ m, ∑ k ∈ Icc 1 m, (i * B (k - 1) + (B (k - 1) - B k)) / (1 + i) ^ k =
      B 0 - B m / (1 + i) ^ m := by
    intro m
    induction m with
    | zero => simp
    | succ m ih =>
      rw [Finset.sum_Icc_succ_top (by omega), ih, Nat.add_sub_cancel]
      field_simp
      ring
  rw [key, hBn]
  simp

/-- The fraction a level-payment loan of `n` months at monthly rate `i` still owes after `k`
months with no prepayment: `S_k = (1 - (1 + i)^(-(n - k))) / (1 - (1 + i)^(-n))`. -/
def schedFrac (i : ℝ) (n k : ℕ) : ℝ :=
  (1 - ((1 + i) ^ (n - k))⁻¹) / (1 - ((1 + i) ^ n)⁻¹)

/-- The IO's value per $100 on a flat path: monthly prepayment rate `s`, one-month discount
factor `v`, balance `B_{k-1} = 100 (1 - s)^(k-1) S_{k-1}`, so `V_IO = ∑ i B_{k-1} v^k`. -/
def ioValue (i s v : ℝ) (n : ℕ) : ℝ :=
  ∑ k ∈ Icc 1 n, i * (100 * (1 - s) ^ (k - 1) * schedFrac i n (k - 1)) * v ^ k

/-- The scheduled balance fraction is positive before the loan's last month. -/
theorem schedFrac_pos (i : ℝ) (n m : ℕ) (hi : 0 < i) (hm : m < n) : 0 < schedFrac i n m := by
  unfold schedFrac
  have hnum : ((1 + i) ^ (n - m))⁻¹ < 1 :=
    inv_lt_one_of_one_lt₀ (one_lt_pow₀ (by linarith : (1 : ℝ) < 1 + i) (by omega))
  have hden : ((1 + i) ^ n)⁻¹ < 1 :=
    inv_lt_one_of_one_lt₀ (one_lt_pow₀ (by linarith : (1 : ℝ) < 1 + i) (by omega))
  apply div_pos <;> linarith

#print axioms schedFrac_pos

/-- The IO shrinks when prepayment speeds up. For a positive note rate, a positive monthly
discount factor and a loan of at least two months, raising the monthly prepayment rate from
`s` to `s'` (both between 0 and 1) strictly lowers the IO's value on a flat path. -/
theorem io_value_falls_as_prepayment_rises (i v s s' : ℝ) (n : ℕ) (hi : 0 < i) (hv : 0 < v)
    (hs : 0 ≤ s) (hss' : s < s') (hs' : s' ≤ 1) (hn : 2 ≤ n) :
    ioValue i s' v n < ioValue i s v n := by
  unfold ioValue
  apply Finset.sum_lt_sum
  · intro k hk
    rw [Finset.mem_Icc] at hk
    have hS := schedFrac_pos i n (k - 1) hi (by omega)
    have hp : (1 - s') ^ (k - 1) ≤ (1 - s) ^ (k - 1) :=
      pow_le_pow_left₀ (by linarith) (by linarith) _
    have hc : 0 ≤ i * 100 * schedFrac i n (k - 1) * v ^ k := by positivity
    nlinarith
  · refine ⟨2, by simp only [Finset.mem_Icc]; omega, ?_⟩
    have hS := schedFrac_pos i n 1 hi (by omega)
    have hc : 0 < i * 100 * schedFrac i n 1 * v ^ 2 := by positivity
    simp only [show (2 : ℕ) - 1 = 1 from rfl, pow_one]
    nlinarith

end

/-! The card's whole-number and exact-fraction figures. -/

-- The three sequential tranches, $40, $35 and $25, share out the $100 pool exactly.
example : (40 : ℕ) + 35 + 25 = 100 := by decide

-- The note rate per month: 6 percent a year divided by 12 is 0.005.
example : (6 : ℚ) / 100 / 12 = 1 / 200 := by norm_num

-- A 30-year loan repaid monthly runs for 360 months.
example : (30 : ℕ) * 12 = 360 := by decide

-- First month interest on $100 at 0.005: the IO's cash is $0.50.
example : (100 : ℚ) * (1 / 200) = 1 / 2 := by norm_num

#print axioms slices_add_up_to_pool
#print axioms pass_through_at_note_rate_is_par
#print axioms io_value_falls_as_prepayment_rises
