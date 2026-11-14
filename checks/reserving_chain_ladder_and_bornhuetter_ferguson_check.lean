-- Reserving: the chain-ladder completion of any run-off triangle matches every row and column total, the volume-weighted factor is the weighted least-squares fit, and Mack's process variance unrolls to its closed form.
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Algebra.Order.Field.Basic
import Mathlib.Order.Filter.Extr
import Mathlib.Basic.Real.Basic
import Mathlib.Tactic.NormNum
import Mathlib

open Finset

/-! Notation, as on the card.

* `n` is the number of accident years and of development ages. Years `i` and ages `k` run
  from `1` to `n`, oldest year first.
* `C i k` is the cumulative reported amount of accident year `i` at age `k`. The cell is on
  the triangle when `i + k ≤ n + 1`; year `i`'s latest age is `n + 1 - i`.
* `ageToAgeFactor C n k` is `f̂ₖ = (∑_{i=1}^{n-k} C i (k+1)) / (∑_{i=1}^{n-k} C i k)`.
* `factorToUltimate C n k` is `F^(k) = f̂ₖ ⋯ f̂_{n-1}`, the growth still to come from age `k`
  (empty product `1` at age `n`).
* `ultimate C n i` is the chain-ladder ultimate `Ûᵢ = C i (n+1-i) · F^(n+1-i)`.
* `reportedShare C n k` is `1 / F^(k)`, the share of the final cost on the books at age `k`,
  with share `0` at age `0`; `devShare C n k` is the share arriving during age `k`.
* `increment C i k` is what year `i` reported during age `k`: `C i k - C i (k-1)`, and all of
  `C i 1` at age `1`.
-/

/-- The age-to-age factor `f̂ₖ`: total at age `k+1` over total at age `k`, over the years
seen at both ages. -/
noncomputable def ageToAgeFactor (C : ℕ → ℕ → ℝ) (n k : ℕ) : ℝ :=
  (∑ i ∈ Icc 1 (n - k), C i (k + 1)) / (∑ i ∈ Icc 1 (n - k), C i k)

/-- The factor to ultimate from age `k`: `F^(k) = f̂ₖ f̂ₖ₊₁ ⋯ f̂_{n-1}`. -/
noncomputable def factorToUltimate (C : ℕ → ℕ → ℝ) (n k : ℕ) : ℝ :=
  ∏ j ∈ Ico k n, ageToAgeFactor C n j

/-- The chain-ladder ultimate of year `i`: its latest figure times the growth still to come. -/
noncomputable def ultimate (C : ℕ → ℕ → ℝ) (n i : ℕ) : ℝ :=
  C i (n + 1 - i) * factorToUltimate C n (n + 1 - i)

/-- The share of the final cost reported by age `k`, `1 / F^(k)`, and `0` before age `1`. -/
noncomputable def reportedShare (C : ℕ → ℕ → ℝ) (n k : ℕ) : ℝ :=
  if k = 0 then 0 else 1 / factorToUltimate C n k

/-- The share of any year's cost that arrives during age `k`: `yₖ = 1/F^(k) - 1/F^(k-1)`. -/
noncomputable def devShare (C : ℕ → ℕ → ℝ) (n k : ℕ) : ℝ :=
  reportedShare C n k - reportedShare C n (k - 1)

/-- What year `i` reported during age `k` (the increment): `C i k - C i (k-1)`, or `C i 1`
at age `1`. -/
def increment (C : ℕ → ℕ → ℝ) (i k : ℕ) : ℝ :=
  if k = 1 then C i 1 else C i k - C i (k - 1)

lemma colSum_pos (n : ℕ) (C : ℕ → ℕ → ℝ)
    (hC : ∀ i k, 1 ≤ i → 1 ≤ k → i + k ≤ n + 1 → 0 < C i k)
    (j k : ℕ) (hk : 1 ≤ k) (hj : 1 ≤ j) (hjk : j + k ≤ n + 1) :
    0 < ∑ i ∈ Icc 1 j, C i k := by
  apply Finset.sum_pos
  · intro i hi
    rw [Finset.mem_Icc] at hi
    exact hC i k hi.1 hk (by omega)
  · exact ⟨1, Finset.mem_Icc.mpr ⟨le_refl _, hj⟩⟩

lemma ageToAgeFactor_pos (n : ℕ) (C : ℕ → ℕ → ℝ)
    (hC : ∀ i k, 1 ≤ i → 1 ≤ k → i + k ≤ n + 1 → 0 < C i k)
    (j : ℕ) (hj1 : 1 ≤ j) (hjn : j < n) : 0 < ageToAgeFactor C n j := by
  unfold ageToAgeFactor
  exact div_pos (colSum_pos n C hC (n - j) (j + 1) (by omega) (by omega) (by omega))
    (colSum_pos n C hC (n - j) j hj1 (by omega) (by omega))

lemma factorToUltimate_pos (n : ℕ) (C : ℕ → ℕ → ℝ)
    (hC : ∀ i k, 1 ≤ i → 1 ≤ k → i + k ≤ n + 1 → 0 < C i k)
    (k : ℕ) (hk : 1 ≤ k) : 0 < factorToUltimate C n k := by
  unfold factorToUltimate
  apply Finset.prod_pos
  intro j hj
  rw [Finset.mem_Ico] at hj
  exact ageToAgeFactor_pos n C hC j (by omega) hj.2

lemma factorToUltimate_succ (n : ℕ) (C : ℕ → ℕ → ℝ) (k : ℕ) (hk : k < n) :
    factorToUltimate C n k = ageToAgeFactor C n k * factorToUltimate C n (k + 1) := by
  unfold factorToUltimate
  exact Finset.prod_eq_prod_Ico_succ_bot hk _

lemma factorToUltimate_self (n : ℕ) (C : ℕ → ℕ → ℝ) : factorToUltimate C n n = 1 := by
  simp [factorToUltimate]

lemma devShare_sum_Icc (n : ℕ) (C : ℕ → ℕ → ℝ) (m : ℕ) :
    ∑ k ∈ Icc 1 m, devShare C n k = reportedShare C n m := by
  induction m with
  | zero => simp [reportedShare]
  | succ m ih =>
    rw [Finset.sum_Icc_succ_top (by omega), ih]
    simp [devShare]

lemma devShare_sum_Ioc (n : ℕ) (C : ℕ → ℕ → ℝ) (a : ℕ) :
    ∀ b, a ≤ b → ∑ k ∈ Ioc a b, devShare C n k = reportedShare C n b - reportedShare C n a := by
  intro b hab
  induction b, hab using Nat.le_induction with
  | base => simp
  | succ b hab ih =>
    rw [Finset.sum_Ioc_succ_top hab, ih]
    simp [devShare]

lemma ultimate_sum (n : ℕ) (C : ℕ → ℕ → ℝ)
    (hC : ∀ i k, 1 ≤ i → 1 ≤ k → i + k ≤ n + 1 → 0 < C i k) :
    ∀ d, d < n → ∑ i ∈ Icc 1 (d + 1), ultimate C n i
      = factorToUltimate C n (n - d) * ∑ i ∈ Icc 1 (d + 1), C i (n - d) := by
  intro d
  induction d with
  | zero =>
    intro _
    simp [ultimate]
    ring
  | succ d ih =>
    intro h
    rw [Finset.sum_Icc_succ_top (a := 1) (b := d + 1) (by omega) (fun i => ultimate C n i),
      Finset.sum_Icc_succ_top (a := 1) (b := d + 1) (by omega) (fun i => C i (n - (d + 1))),
      ih (by omega)]
    have hF : factorToUltimate C n (n - (d + 1))
        = ageToAgeFactor C n (n - (d + 1)) * factorToUltimate C n (n - d) := by
      rw [factorToUltimate_succ n C _ (by omega)]
      have e : n - (d + 1) + 1 = n - d := by omega
      rw [e]
    have hfac : ageToAgeFactor C n (n - (d + 1)) * ∑ i ∈ Icc 1 (d + 1), C i (n - (d + 1))
        = ∑ i ∈ Icc 1 (d + 1), C i (n - d) := by
      unfold ageToAgeFactor
      have e1 : n - (n - (d + 1)) = d + 1 := by omega
      have e2 : n - (d + 1) + 1 = n - d := by omega
      rw [e1, e2]
      have hpos : 0 < ∑ i ∈ Icc 1 (d + 1), C i (n - (d + 1)) :=
        colSum_pos n C hC (d + 1) (n - (d + 1)) (by omega) (by omega) (by omega)
      field_simp
    have hU : ultimate C n (d + 1 + 1)
        = C (d + 1 + 1) (n - (d + 1)) * factorToUltimate C n (n - (d + 1)) := by
      unfold ultimate
      have e : n + 1 - (d + 1 + 1) = n - (d + 1) := by omega
      rw [e]
    rw [hU, hF]
    linear_combination (-factorToUltimate C n (n - d)) * hfac

/-- The card's Step 3 (marginal totals reproduce the chain ladder). Take any run-off triangle
of positive cumulative amounts. Fill it with increments `Ûᵢ · yₖ`: the chain-ladder ultimate
of each year times the share of cost arriving at each age. Then the shares add to one, every
year's fitted increments up to its latest age add to its reported total, every age's fitted
increments over the years seen at that age add to the observed increments, and the fitted
future cells of each year add to its chain-ladder reserve `Ûᵢ - C_{i,n+1-i}`. -/
theorem chain_ladder_completion_matches_row_and_column_totals
    (n : ℕ) (hn : 1 ≤ n) (C : ℕ → ℕ → ℝ)
    (hC : ∀ i k, 1 ≤ i → 1 ≤ k → i + k ≤ n + 1 → 0 < C i k) :
    (∑ k ∈ Icc 1 n, devShare C n k = 1) ∧
    (∀ i ∈ Icc 1 n,
      ∑ k ∈ Icc 1 (n + 1 - i), ultimate C n i * devShare C n k = C i (n + 1 - i)) ∧
    (∀ k ∈ Icc 1 n,
      ∑ i ∈ Icc 1 (n + 1 - k), ultimate C n i * devShare C n k
        = ∑ i ∈ Icc 1 (n + 1 - k), increment C i k) ∧
    (∀ i ∈ Icc 1 n,
      ∑ k ∈ Ioc (n + 1 - i) n, ultimate C n i * devShare C n k
        = ultimate C n i - C i (n + 1 - i)) := by
  have hFpos := factorToUltimate_pos n C hC
  have hRn : reportedShare C n n = 1 := by
    simp [reportedShare, factorToUltimate_self, show n ≠ 0 by omega]
  refine ⟨?_, ?_, ?_, ?_⟩
  · rw [devShare_sum_Icc, hRn]
  · intro i hi
    rw [Finset.mem_Icc] at hi
    rw [← Finset.mul_sum, devShare_sum_Icc]
    have hne : n + 1 - i ≠ 0 := by omega
    have hp := hFpos (n + 1 - i) (by omega)
    simp only [reportedShare, hne, ite_false, ultimate]
    field_simp
  · intro k hk
    rw [Finset.mem_Icc] at hk
    rw [← Finset.sum_mul]
    have hA := ultimate_sum n C hC (n - k) (by omega)
    have e1 : n - k + 1 = n + 1 - k := by omega
    have e2 : n - (n - k) = k := by omega
    rw [e1, e2] at hA
    rw [hA]
    have hpk := hFpos k hk.1
    rcases Nat.lt_or_ge k 2 with h1 | h2
    · have hk1 : k = 1 := by omega
      subst hk1
      simp [devShare, reportedShare, increment]
      field_simp
    · have hk0 : k ≠ 0 := by omega
      have hk10 : k - 1 ≠ 0 := by omega
      have hFk1 : factorToUltimate C n (k - 1)
          = ageToAgeFactor C n (k - 1) * factorToUltimate C n k := by
        rw [factorToUltimate_succ n C _ (by omega)]
        have e : k - 1 + 1 = k := by omega
        rw [e]
      have hinc : ∀ i, increment C i k = C i k - C i (k - 1) := by
        intro i
        simp [increment, show k ≠ 1 by omega]
      simp only [hinc]
      rw [Finset.sum_sub_distrib]
      have hS1 := colSum_pos n C hC (n + 1 - k) k (by omega) (by omega) (by omega)
      have hS0 := colSum_pos n C hC (n + 1 - k) (k - 1) (by omega) (by omega) (by omega)
      have hf : ageToAgeFactor C n (k - 1)
          = (∑ i ∈ Icc 1 (n + 1 - k), C i k) / (∑ i ∈ Icc 1 (n + 1 - k), C i (k - 1)) := by
        unfold ageToAgeFactor
        have e3 : n - (k - 1) = n + 1 - k := by omega
        have e4 : k - 1 + 1 = k := by omega
        rw [e3, e4]
      simp only [devShare, reportedShare, hk0, hk10, ite_false, hFk1, hf]
      field_simp
  · intro i hi
    rw [Finset.mem_Icc] at hi
    rw [← Finset.mul_sum, devShare_sum_Ioc n C _ n (by omega), hRn]
    have hne : n + 1 - i ≠ 0 := by omega
    have hp := hFpos (n + 1 - i) (by omega)
    simp only [reportedShare, hne, ite_false, ultimate]
    field_simp

/-- The card's Step 1: when each year's noise grows in proportion to its size, the
volume-weighted factor, total over total, is the weighted least-squares fit. Over the years
seen at ages `k` and `k+1`, with positive amounts at age `k`, no trial factor `g` makes the
size-weighted squared misses `∑ (C_{i,k+1} - g C_{i,k})² / C_{i,k}` smaller than `f̂ₖ` does. -/
theorem volume_weighted_factor_minimises_weighted_squared_misses
    (n k : ℕ) (C : ℕ → ℕ → ℝ) (hC : ∀ i ∈ Icc 1 (n - k), 0 < C i k) :
    IsMinOn (fun g : ℝ => ∑ i ∈ Icc 1 (n - k), (C i (k + 1) - g * C i k) ^ 2 / C i k)
      Set.univ (ageToAgeFactor C n k) := by
  rw [isMinOn_univ_iff]
  intro g
  rcases Nat.eq_zero_or_pos (n - k) with h0 | hpos
  · simp [h0]
  set gh := ageToAgeFactor C n k with hgh
  have hSx : 0 < ∑ i ∈ Icc 1 (n - k), C i k :=
    Finset.sum_pos (fun i hi => hC i hi) ⟨1, Finset.mem_Icc.mpr ⟨le_refl _, hpos⟩⟩
  have hcross : ∑ i ∈ Icc 1 (n - k), (C i (k + 1) - gh * C i k) = 0 := by
    rw [Finset.sum_sub_distrib, ← Finset.mul_sum, hgh]
    unfold ageToAgeFactor
    field_simp
    ring
  have hpt : ∀ i ∈ Icc 1 (n - k), (C i (k + 1) - g * C i k) ^ 2 / C i k
      = (C i (k + 1) - gh * C i k) ^ 2 / C i k + (g - gh) ^ 2 * C i k
        + 2 * (gh - g) * (C i (k + 1) - gh * C i k) := by
    intro i hi
    have := hC i hi
    field_simp
    ring
  rw [Finset.sum_congr rfl hpt, Finset.sum_add_distrib, Finset.sum_add_distrib,
    ← Finset.mul_sum, ← Finset.mul_sum, hcross]
  have : 0 ≤ (g - gh) ^ 2 * ∑ i ∈ Icc 1 (n - k), C i k := by positivity
  linarith

/-- The card's Step 5, process variance. Start a year at its latest age `a` with a known
positive figure (`m a > 0`, `v a = 0`). If the mean grows by the factor, `m (k+1) = fₖ m k`,
and the variance by `v (k+1) = σₖ² m k + fₖ² v k`, with positive factors, then at the last
age `N ≥ a` the variance is `m_N² ∑_{k=a}^{N-1} σₖ² / (fₖ² m k)`: the first term of Mack's
formula. -/
theorem process_variance_unrolls_to_mack_first_term
    (a N : ℕ) (haN : a ≤ N) (m v σsq f : ℕ → ℝ)
    (hma : 0 < m a) (hva : v a = 0)
    (hf : ∀ k, a ≤ k → k < N → 0 < f k)
    (hm : ∀ k, a ≤ k → k < N → m (k + 1) = f k * m k)
    (hv : ∀ k, a ≤ k → k < N → v (k + 1) = σsq k * m k + f k ^ 2 * v k) :
    v N = m N ^ 2 * ∑ k ∈ Ico a N, σsq k / (f k ^ 2 * m k) := by
  have key : ∀ j, a ≤ j → j ≤ N →
      0 < m j ∧ v j = m j ^ 2 * ∑ k ∈ Ico a j, σsq k / (f k ^ 2 * m k) := by
    intro j hj
    induction j, hj using Nat.le_induction with
    | base => intro _; simp [hma, hva]
    | succ j hj ih =>
      intro hjN
      obtain ⟨hmj, hvj⟩ := ih (by omega)
      have hfj := hf j hj (by omega)
      have hmj1 := hm j hj (by omega)
      refine ⟨by rw [hmj1]; positivity, ?_⟩
      rw [hv j hj (by omega), Finset.sum_Ico_succ_top hj, hmj1, hvj]
      field_simp
      ring
  exact (key N haN le_rfl).2

/-- The card's triangle, in thousands of dollars: accident years 2016 to 2025 down, ages
across. -/
def cardRows : List (List ℕ) :=
  [[3616, 6170, 6846, 7304, 7832, 8130, 8305, 8382, 8437, 8464],
   [3533, 4868, 5650, 6167, 6581, 6875, 7053, 7133, 7174],
   [3476, 4613, 5100, 5596, 5869, 6038, 6189, 6259],
   [3772, 5320, 5880, 6386, 6644, 6858, 7040],
   [3975, 5516, 6749, 7584, 8097, 8441],
   [4171, 6842, 7869, 8959, 9658],
   [3918, 6369, 7638, 8379],
   [4308, 6531, 8018],
   [4438, 7358],
   [4486]]

/-- `cardC i k` is the card's `C_{i,k}`, years and ages counted from `1`. -/
def cardC (i k : ℕ) : ℕ := (cardRows.getD (i - 1) []).getD (k - 1) 0

-- The table is a triangle: year i (2016 is year 1) has 10 + 1 - i ages on the books.
example : ∀ i ∈ Finset.Icc 1 10, (cardRows.getD (i - 1) []).length = 10 + 1 - i := by decide
-- Every cell on the triangle is positive.
example : ∀ i ∈ Finset.Icc 1 10, ∀ k ∈ Finset.Icc 1 (10 + 1 - i), 0 < cardC i k := by decide
-- 2025 (year 10) has only its age-1 figure, C_{10,1} = 4,486.
example : cardC 10 (10 + 1 - 10) = 4486 := by decide
-- f̂₁: the age-2 total of 2016-2024 is 53,587.
example : ∑ i ∈ Finset.Icc 1 (10 - 1), cardC i 2 = 53587 := by decide
-- f̂₁: the age-1 total of 2016-2024 is S₁ = 35,207.
example : ∑ i ∈ Finset.Icc 1 (10 - 1), cardC i 1 = 35207 := by decide
-- 2025's expected ultimate for BF: 70 percent of premium 15,500 is 10,850.
example : (70 : ℝ) / 100 * 15500 = 10850 := by norm_num

#print axioms colSum_pos
#print axioms ageToAgeFactor_pos
#print axioms factorToUltimate_pos
#print axioms factorToUltimate_succ
#print axioms factorToUltimate_self
#print axioms devShare_sum_Icc
#print axioms devShare_sum_Ioc
#print axioms ultimate_sum
#print axioms chain_ladder_completion_matches_row_and_column_totals
#print axioms volume_weighted_factor_minimises_weighted_squared_misses
#print axioms process_variance_unrolls_to_mack_first_term
