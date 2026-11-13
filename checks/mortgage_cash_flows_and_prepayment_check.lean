-- Mortgage pools: in the monthly pool ledger (interest, scheduled payment over the months left, prepayment of a fraction of what remains), the balance after month m is the original pool times the surviving fraction of loans times one loan's scheduled balance, the pool's payment shrinks with its survivors, it is fully repaid at the term, every dollar of principal comes back exactly once, and at the note rate the cash flows are worth exactly the starting balance at any speed.
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Algebra.Order.Field.Power
import Mathlib.Basic.Real.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Linarith
import Mathlib.Algebra.Order.BigOperators.Group.Finset

open Finset

/-! ## Setting

`i` is the monthly note rate and `N` the term in months. The pool starts at balance `L`.
The ledger runs month `m + 1` (for `m < N`) from the opening balance `B m`:

* interest `I (m + 1) = i * B m`;
* scheduled payment `P (m + 1) = B m / a_{N - m}(i)`, what is owed spread over the months left;
* scheduled principal `Q (m + 1) = P (m + 1) - I (m + 1)`;
* prepaid principal `U (m + 1) = s * (B m - Q (m + 1))`, the single monthly mortality `s`
  applied after scheduled principal;
* closing balance `B (m + 1) = B m - Q (m + 1) - U (m + 1)`.

The cash flow to the investor in month `m + 1` is `I (m + 1) + Q (m + 1) + U (m + 1)`. -/

/-- The annuity factor `a_n(i) = ∑_{k=1}^{n} (1 + i)^(-k)`: today's value of one dollar paid
at the end of each of `n` months. -/
noncomputable def annuityFactor (i : ℝ) (n : ℕ) : ℝ :=
  ∑ k ∈ Icc 1 n, (1 + i) ^ (-(k : ℤ))

/-- One month of the annuity factor: `(1 + i) a_{n+1}(i) = 1 + a_n(i)`. -/
theorem annuityFactor_succ_mul (i : ℝ) (hi : -1 < i) (n : ℕ) :
    (1 + i) * annuityFactor i (n + 1) = 1 + annuityFactor i n := by
  have h1 : (1 + i) ≠ 0 := by linarith
  induction n with
  | zero =>
    simp [annuityFactor]
    field_simp
  | succ n ih =>
    unfold annuityFactor at *
    rw [Finset.sum_Icc_succ_top (by omega), mul_add, ih, Finset.sum_Icc_succ_top (by omega)]
    have : (1 + i) * (1 + i) ^ (-((n + 1 + 1 : ℕ) : ℤ)) = (1 + i) ^ (-((n + 1 : ℕ) : ℤ)) := by
      rw [zpow_neg, zpow_neg, zpow_natCast, zpow_natCast, pow_succ (1 + i) (n + 1)]
      field_simp
    rw [this]; ring

/-- The annuity factor is positive for a term of at least one month. -/
theorem annuityFactor_pos (i : ℝ) (hi : -1 < i) (n : ℕ) (hn : 0 < n) :
    0 < annuityFactor i n := by
  unfold annuityFactor
  apply Finset.sum_pos
  · intro k _; exact zpow_pos (by linarith) _
  · exact ⟨1, Finset.mem_Icc.mpr ⟨le_refl _, hn⟩⟩

/-- The general closed form at varying speeds, with full repayment. -/
theorem pool_balance_general (i L : ℝ) (N : ℕ) (s B I P Q U : ℕ → ℝ)
    (hi : -1 < i) (hN : 0 < N)
    (hB0 : B 0 = L)
    (hI : ∀ m < N, I (m + 1) = i * B m)
    (hP : ∀ m < N, P (m + 1) = B m / annuityFactor i (N - m))
    (hQ : ∀ m < N, Q (m + 1) = P (m + 1) - I (m + 1))
    (hU : ∀ m < N, U (m + 1) = s (m + 1) * (B m - Q (m + 1)))
    (hB : ∀ m < N, B (m + 1) = B m - Q (m + 1) - U (m + 1)) :
    ∀ m ≤ N, B m = L * (∏ k ∈ Icc 1 m, (1 - s k)) *
      annuityFactor i (N - m) / annuityFactor i N := by
  have haN := annuityFactor_pos i hi N hN
  intro m hm
  induction m with
  | zero => simp [hB0]; field_simp
  | succ m ih =>
    have hmN : m < N := by omega
    have ih := ih (by omega)
    obtain ⟨n, hn⟩ : ∃ n, N - m = n + 1 := ⟨N - (m + 1), by omega⟩
    have hn' : N - (m + 1) = n := by omega
    have ha := annuityFactor_pos i hi (n + 1) (by omega)
    have hrec := annuityFactor_succ_mul i hi n
    rw [hn] at ih
    rw [hB m hmN, hU m hmN, hQ m hmN, hP m hmN, hI m hmN, Finset.prod_Icc_succ_top (by omega),
      hn', ih, hn]
    have : annuityFactor i n = (1 + i) * annuityFactor i (n + 1) - 1 := by linarith
    rw [this]
    field_simp
    ring

#print axioms annuityFactor_succ_mul
#print axioms annuityFactor_pos
#print axioms pool_balance_general

/-- **The pool's closed form.** Run the ledger at a constant single monthly mortality `s`,
with a monthly rate above −100% and a term of at least one month. Then the balance after
month `m` is the original pool, times the fraction of loans that survived `m` months,
times the fraction a single loan still owes on schedule:
`B_m = L (1 - s)^m a_{N-m}(i) / a_N(i)` for every `m` from `0` to `N`.
The pool's scheduled payment in month `m + 1` is the level payment `A = L / a_N(i)` times
the fraction of loans left, `(1 - s)^m A`. Each month's cash flow is the interest on last
month's balance plus however much the balance fell, `X = i B_{m} + (B_{m} - B_{m+1})`.
And the pool is fully repaid at the end of the term, whatever the speed: `B_N = 0`. -/
theorem pool_balance_closed_form (i L s : ℝ) (N : ℕ) (B I P Q U : ℕ → ℝ)
    (hi : -1 < i) (hN : 0 < N)
    (hB0 : B 0 = L)
    (hI : ∀ m < N, I (m + 1) = i * B m)
    (hP : ∀ m < N, P (m + 1) = B m / annuityFactor i (N - m))
    (hQ : ∀ m < N, Q (m + 1) = P (m + 1) - I (m + 1))
    (hU : ∀ m < N, U (m + 1) = s * (B m - Q (m + 1)))
    (hB : ∀ m < N, B (m + 1) = B m - Q (m + 1) - U (m + 1)) :
    (∀ m ≤ N, B m = L * (1 - s) ^ m * annuityFactor i (N - m) / annuityFactor i N) ∧
    (∀ m < N, P (m + 1) = (1 - s) ^ m * (L / annuityFactor i N)) ∧
    (∀ m < N, I (m + 1) + Q (m + 1) + U (m + 1) = i * B m + (B m - B (m + 1))) ∧
    B N = 0 := by
  have hgen := pool_balance_general i L N (fun _ => s) B I P Q U hi hN hB0 hI hP hQ hU hB
  have hprod : ∀ m, ∏ k ∈ Icc 1 m, (1 - (fun _ => s) k) = (1 - s) ^ m := by
    intro m; simp [Finset.prod_const]
  have haN := annuityFactor_pos i hi N hN
  have hBm : ∀ m ≤ N, B m = L * (1 - s) ^ m * annuityFactor i (N - m) / annuityFactor i N := by
    intro m hm; rw [hgen m hm, hprod]
  refine ⟨hBm, ?_, ?_, ?_⟩
  · intro m hm
    have ha := annuityFactor_pos i hi (N - m) (by omega)
    rw [hP m hm, hBm m hm.le]
    field_simp
  · intro m hm
    rw [hB m hm, hI m hm]; ring
  · rw [hBm N le_rfl, Nat.sub_self]
    simp [annuityFactor]

/-- **A speed that changes month by month.** Run the same ledger with the single monthly
mortality `s (m + 1)` in month `m + 1`, any speeds at all. Survival still multiplies month by
month, so the balance after month `m` is the original pool times the product of the monthly
survival fractions times one loan's scheduled fraction:
`B_m = L (1 - s_1)(1 - s_2)⋯(1 - s_m) a_{N-m}(i) / a_N(i)` for every `m` from `0` to `N`. -/
theorem pool_balance_varying_speed (i L : ℝ) (N : ℕ) (s B I P Q U : ℕ → ℝ)
    (hi : -1 < i) (hN : 0 < N)
    (hB0 : B 0 = L)
    (hI : ∀ m < N, I (m + 1) = i * B m)
    (hP : ∀ m < N, P (m + 1) = B m / annuityFactor i (N - m))
    (hQ : ∀ m < N, Q (m + 1) = P (m + 1) - I (m + 1))
    (hU : ∀ m < N, U (m + 1) = s (m + 1) * (B m - Q (m + 1)))
    (hB : ∀ m < N, B (m + 1) = B m - Q (m + 1) - U (m + 1)) :
    ∀ m ≤ N, B m = L * (∏ k ∈ Icc 1 m, (1 - s k)) *
      annuityFactor i (N - m) / annuityFactor i N := by
  exact pool_balance_general i L N s B I P Q U hi hN hB0 hI hP hQ hU hB

/-- **Every dollar comes back once, and at the note rate prepayment is worth nothing.**
For the same ledger at any speeds, even ones that change month to month: scheduled plus
prepaid principal over the whole life add up to exactly the starting balance `L`, and the
monthly cash flows `X_m = I_m + Q_m + U_m`, discounted at the note rate by `(1 + i)^m`,
are worth exactly `L` (par). -/
theorem pool_principal_returned_and_par_at_note_rate (i L : ℝ) (N : ℕ) (s B I P Q U : ℕ → ℝ)
    (hi : -1 < i) (hN : 0 < N)
    (hB0 : B 0 = L)
    (hI : ∀ m < N, I (m + 1) = i * B m)
    (hP : ∀ m < N, P (m + 1) = B m / annuityFactor i (N - m))
    (hQ : ∀ m < N, Q (m + 1) = P (m + 1) - I (m + 1))
    (hU : ∀ m < N, U (m + 1) = s (m + 1) * (B m - Q (m + 1)))
    (hB : ∀ m < N, B (m + 1) = B m - Q (m + 1) - U (m + 1)) :
    ∑ m ∈ range N, (Q (m + 1) + U (m + 1)) = L ∧
    ∑ m ∈ range N, (I (m + 1) + Q (m + 1) + U (m + 1)) * (1 + i) ^ (-((m + 1 : ℕ) : ℤ)) = L := by
  have hgen := pool_balance_general i L N s B I P Q U hi hN hB0 hI hP hQ hU hB
  have hBN : B N = 0 := by
    rw [hgen N le_rfl, Nat.sub_self]; simp [annuityFactor]
  have h1 : (1 + i) ≠ 0 := by linarith
  constructor
  · have : ∀ m ∈ range N, Q (m + 1) + U (m + 1) = B m - B (m + 1) := by
      intro m hm
      have hm := Finset.mem_range.mp hm
      rw [hB m hm]; ring
    rw [Finset.sum_congr rfl this, Finset.sum_range_sub', hB0, hBN, sub_zero]
  · have : ∀ m ∈ range N,
        (I (m + 1) + Q (m + 1) + U (m + 1)) * (1 + i) ^ (-((m + 1 : ℕ) : ℤ)) =
          B m * (1 + i) ^ (-((m : ℕ) : ℤ)) - B (m + 1) * (1 + i) ^ (-((m + 1 : ℕ) : ℤ)) := by
      intro m hm
      have hm := Finset.mem_range.mp hm
      rw [hB m hm, hI m hm, zpow_neg, zpow_neg, zpow_natCast, zpow_natCast, pow_succ]
      field_simp
      ring
    rw [Finset.sum_congr rfl this,
      Finset.sum_range_sub' (fun m => B m * (1 + i) ^ (-((m : ℕ) : ℤ))), hB0, hBN]
    simp

/-! ## The card's numbers, exactly

The pool: `L = 1,000,000`, `N = 360`, `i = 6% / 12 = 1/200`, so the discount factor is
`200/201` and `a_n(i) = (1 - (200/201)^n) / (1/200)`. Rounded figures are checked as lying
within half a unit of the last printed digit. -/

-- The monthly note rate: 6 percent a year over 12 months is 1/200.
example : (6 / 100 : ℚ) / 12 = 1 / 200 := by norm_num

-- The annuity factor a_360 rounds to 166.791614.
example : (333583227 / 2000000 : ℚ) ≤ (1 - (200 / 201 : ℚ) ^ 360) / (1 / 200) ∧
    (1 - (200 / 201 : ℚ) ^ 360) / (1 / 200) < 333583229 / 2000000 := by
  rw [show (360 : ℕ) = 180 * 2 from rfl, pow_mul]; norm_num

-- The level payment A = 1,000,000 / a_360 rounds to $5,995.51.
example : (1199101 / 200 : ℚ) ≤ 1000000 / ((1 - (200 / 201 : ℚ) ^ 360) / (1 / 200)) ∧
    1000000 / ((1 - (200 / 201 : ℚ) ^ 360) / (1 / 200)) < 1199103 / 200 := by
  rw [show (360 : ℕ) = 180 * 2 from rfl, pow_mul]; norm_num

-- Month 1 interest: 0.005 × 1,000,000 = $5,000.00.
example : (1 / 200 : ℚ) * 1000000 = 5000 := by norm_num

-- Month 1 scheduled principal A − 5,000 rounds to $995.51.
example : (199101 / 200 : ℚ) ≤ 1000000 / ((1 - (200 / 201 : ℚ) ^ 360) / (1 / 200)) - 5000 ∧
    1000000 / ((1 - (200 / 201 : ℚ) ^ 360) / (1 / 200)) - 5000 < 199103 / 200 := by
  rw [show (360 : ℕ) = 180 * 2 from rfl, pow_mul]; norm_num

-- With (1 − s)^12 = 0.92, the survivors after 10 years are (1 − s)^120 = 0.92^10.
example (x : ℝ) (h : x ^ 12 = 23 / 25) : x ^ 120 = (23 / 25) ^ 10 := by
  rw [show (120 : ℕ) = 12 * 10 from rfl, pow_mul, h]

-- 0.92^10 rounds to 0.434388.
example : (868775 / 2000000 : ℚ) ≤ (23 / 25) ^ 10 ∧ (23 / 25 : ℚ) ^ 10 < 868777 / 2000000 := by
  norm_num

-- The scheduled balance after 10 years, L a_240 / a_360, rounds to $836,857.25.
example : (167371449 / 200 : ℚ) ≤ 1000000 * (1 - (200 / 201 : ℚ) ^ 240) / (1 - (200 / 201) ^ 360) ∧
    1000000 * (1 - (200 / 201 : ℚ) ^ 240) / (1 - (200 / 201) ^ 360) < 167371451 / 200 := by
  rw [show (360 : ℕ) = 180 * 2 from rfl, pow_mul]; norm_num

-- The pool balance after 10 years at 8% CPR, L 0.92^10 a_240 / a_360, rounds to $363,521.13.
example : (72704225 / 200 : ℚ) ≤
      1000000 * (23 / 25) ^ 10 * (1 - (200 / 201 : ℚ) ^ 240) / (1 - (200 / 201) ^ 360) ∧
    1000000 * (23 / 25) ^ 10 * (1 - (200 / 201 : ℚ) ^ 240) / (1 - (200 / 201) ^ 360) <
      72704227 / 200 := by
  rw [show (360 : ℕ) = 180 * 2 from rfl, pow_mul]; norm_num

-- The wrong monthly speed CPR / 12: 8% / 12 = 1/150, about 0.666667%.
example : (8 / 100 : ℚ) / 12 = 1 / 150 := by norm_num

-- The rate rule c = min(30%, max(2%, 8% + 4 (6% − M))): 8% at M = 6%, 12% at 5%, 4% at 7%,
-- and 16% at 4%.
example : min (30 / 100 : ℚ) (max (2 / 100) (8 / 100 + 4 * (6 / 100 - 6 / 100))) = 8 / 100 := by
  norm_num
example : min (30 / 100 : ℚ) (max (2 / 100) (8 / 100 + 4 * (6 / 100 - 5 / 100))) = 12 / 100 := by
  norm_num
example : min (30 / 100 : ℚ) (max (2 / 100) (8 / 100 + 4 * (6 / 100 - 7 / 100))) = 4 / 100 := by
  norm_num
example : min (30 / 100 : ℚ) (max (2 / 100) (8 / 100 + 4 * (6 / 100 - 4 / 100))) = 16 / 100 := by
  norm_num

#print axioms pool_balance_closed_form
#print axioms pool_balance_varying_speed
#print axioms pool_principal_returned_and_par_at_note_rate
