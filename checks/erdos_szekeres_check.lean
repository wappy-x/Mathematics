-- Erdos-Szekeres: any list of more than (r - 1)(s - 1) different real numbers has r terms that rise or s terms that fall, in list order with gaps allowed, the longest rise times the longest fall is at least the list's length, and (r - 1)(s - 1) numbers are not enough, with the card's Harlow Cement closes checked in whole cents.
import Mathlib.Basic.Real.Basic
import Mathlib.Data.Fintype.Powerset
import Mathlib.Data.Fin.VecNotation
import Mathlib.Order.Monotone.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.Push
import Mathlib.Order.Interval.Finset.Nat

open Classical in
/-- Length of the longest rising run whose last position is `i`. -/
noncomputable def riseEnd {n : ℕ} (x : Fin n → ℝ) (i : Fin n) : ℕ :=
  ((Finset.univ : Finset (Finset (Fin n))).filter
    (fun t : Finset (Fin n) => StrictMonoOn x (t : Set (Fin n)) ∧ i ∈ t ∧ ∀ j ∈ t, j ≤ i)).sup Finset.card

lemma riseEnd_spec {n : ℕ} (x : Fin n → ℝ) (i : Fin n) :
    ∃ t : Finset (Fin n), StrictMonoOn x (t : Set (Fin n)) ∧ i ∈ t ∧ (∀ j ∈ t, j ≤ i) ∧
      t.card = riseEnd x i := by
  classical
  unfold riseEnd
  obtain ⟨t, ht, he⟩ := Finset.exists_mem_eq_sup
    ((Finset.univ : Finset (Finset (Fin n))).filter
      (fun t : Finset (Fin n) => StrictMonoOn x (t : Set (Fin n)) ∧ i ∈ t ∧ ∀ j ∈ t, j ≤ i))
    ⟨{i}, by simp⟩ Finset.card
  simp only [Finset.mem_filter, Finset.mem_univ, true_and] at ht
  refine ⟨t, ht.1, ht.2.1, ht.2.2, ?_⟩
  rw [he]

lemma le_riseEnd {n : ℕ} (x : Fin n → ℝ) (i : Fin n) (t : Finset (Fin n))
    (ht : StrictMonoOn x (t : Set (Fin n))) (hi : i ∈ t) (hle : ∀ j ∈ t, j ≤ i) :
    t.card ≤ riseEnd x i := by
  classical
  unfold riseEnd
  apply Finset.le_sup (f := Finset.card)
  simp only [Finset.mem_filter, Finset.mem_univ, true_and]
  exact ⟨ht, hi, hle⟩

lemma one_le_riseEnd {n : ℕ} (x : Fin n → ℝ) (i : Fin n) : 1 ≤ riseEnd x i := by
  have := le_riseEnd x i {i} (by simp) (by simp) (by simp)
  simpa using this

lemma riseEnd_le {n A : ℕ} (x : Fin n → ℝ)
    (hA : ∀ t : Finset (Fin n), StrictMonoOn x t → t.card ≤ A) (i : Fin n) :
    riseEnd x i ≤ A := by
  obtain ⟨t, ht, -, -, he⟩ := riseEnd_spec x i
  rw [← he]; exact hA t ht

lemma riseEnd_lt {n : ℕ} (x : Fin n → ℝ) (i j : Fin n) (hij : i < j) (hx : x i < x j) :
    riseEnd x i < riseEnd x j := by
  classical
  obtain ⟨t, ht, hi, hle, he⟩ := riseEnd_spec x i
  have hj : j ∉ t := fun h => absurd (hle j h) (not_le.2 hij)
  have hmono : StrictMonoOn x ((insert j t : Finset (Fin n)) : Set (Fin n)) := by
    intro a ha b hb hab
    simp only [Finset.coe_insert, Set.mem_insert_iff, Finset.mem_coe] at ha hb
    rcases ha with rfl | ha <;> rcases hb with rfl | hb
    · exact absurd hab (lt_irrefl _)
    · exact absurd (lt_of_lt_of_le hab (hle b hb)) (not_lt.2 hij.le)
    · rcases (hle a ha).lt_or_eq with h | h
      · exact (ht ha hi h).trans hx
      · rw [h]; exact hx
    · exact ht ha hb hab
  have := le_riseEnd x j (insert j t) hmono (Finset.mem_insert_self _ _) (by
    intro k hk
    rcases Finset.mem_insert.1 hk with rfl | hk
    · exact le_rfl
    · exact (hle k hk).trans hij.le)
  rw [Finset.card_insert_of_notMem hj, he] at this
  omega

#print axioms riseEnd_spec
#print axioms le_riseEnd
#print axioms one_le_riseEnd
#print axioms riseEnd_le
#print axioms riseEnd_lt

/-- The product bound, as a helper so the first theorem can use it. -/
lemma product_bound (n A B : ℕ) (x : Fin n → ℝ)
    (hx : Function.Injective x)
    (hA : ∀ t : Finset (Fin n), StrictMonoOn x t → t.card ≤ A)
    (hB : ∀ t : Finset (Fin n), StrictAntiOn x t → t.card ≤ B) :
    n ≤ A * B := by
  classical
  set y : Fin n → ℝ := fun i => -x i with hy
  have hB' : ∀ t : Finset (Fin n), StrictMonoOn y t → t.card ≤ B := by
    intro t ht
    apply hB t
    intro a ha b hb hab
    have := ht ha hb hab
    simp only [hy] at this
    linarith
  let g : Fin n → ℕ × ℕ := fun i => (riseEnd x i, riseEnd y i)
  have hcard := Finset.card_le_card_of_injOn g
    (s := (Finset.univ : Finset (Fin n))) (t := Finset.Icc 1 A ×ˢ Finset.Icc 1 B)
    (by
      intro i _
      simp only [Finset.coe_product, Finset.coe_Icc, Set.mem_prod, Set.mem_Icc, g]
      exact ⟨⟨one_le_riseEnd x i, riseEnd_le x hA i⟩, ⟨one_le_riseEnd y i, riseEnd_le y hB' i⟩⟩)
    (by
      have key : ∀ i j : Fin n, i < j → g i ≠ g j := by
        intro i j hij hg
        simp only [g, Prod.mk.injEq] at hg
        rcases lt_or_gt_of_ne (hx.ne hij.ne) with h | h
        · exact absurd hg.1 (riseEnd_lt x i j hij h).ne
        · have h' : y i < y j := by simp only [hy]; linarith
          exact absurd hg.2 (riseEnd_lt y i j hij h').ne
      intro i _ j _ hg
      by_contra hne
      rcases lt_or_gt_of_ne hne with h | h
      · exact key i j h hg
      · exact key j i h hg.symm)
  simpa using hcard

#print axioms product_bound

lemma block_order (m i j : ℕ) (hij : i < j) :
    (i / m = j / m ∧ i % m < j % m) ∨ i / m < j / m := by
  rcases (Nat.div_le_div_right (c := m) hij.le).lt_or_eq with h | h
  · exact Or.inr h
  · left
    refine ⟨h, ?_⟩
    have h1 := Nat.div_add_mod i m
    have h2 := Nat.div_add_mod j m
    rw [h] at h1
    generalize m * (j / m) = c at h1 h2
    omega

/-- The value at position `k` in the blocks list: block `k / m` sits above the earlier blocks,
and falls within itself. -/
def blockVal (m k : ℕ) : ℕ := (m + 1) * (k / m) + (m - k % m)

lemma blockVal_order (m i j : ℕ) (hm : 0 < m) (hij : i < j) :
    (i / m = j / m ∧ blockVal m j < blockVal m i) ∨
      (i / m < j / m ∧ blockVal m i < blockVal m j) := by
  have hi := Nat.mod_lt i hm
  have hj := Nat.mod_lt j hm
  rcases block_order m i j hij with ⟨h, h'⟩ | h
  · left
    refine ⟨h, ?_⟩
    unfold blockVal
    rw [h]
    omega
  · right
    refine ⟨h, ?_⟩
    unfold blockVal
    have : (m + 1) * (i / m + 1) ≤ (m + 1) * (j / m) := Nat.mul_le_mul_left _ h
    rw [mul_add] at this
    generalize (m + 1) * (i / m) = c at this ⊢
    generalize (m + 1) * (j / m) = d at this ⊢
    omega

#print axioms block_order
#print axioms blockVal_order

lemma blocks_list (p m : ℕ) :
    ∃ x : Fin (p * m) → ℝ, Function.Injective x ∧
      (∀ t : Finset (Fin (p * m)), StrictMonoOn x t → t.card ≤ p) ∧
      (∀ t : Finset (Fin (p * m)), StrictAntiOn x t → t.card ≤ m) := by
  -- positions exist only when `m > 0`
  have hm : ∀ k : Fin (p * m), 0 < m := by
    intro k
    have h0 : 0 < p * m := lt_of_le_of_lt (Nat.zero_le _) k.2
    rcases Nat.eq_zero_or_pos m with h | h
    · rw [h, mul_zero] at h0; exact absurd h0 (lt_irrefl 0)
    · exact h
  refine ⟨fun k => (blockVal m k.val : ℝ), ?_, ?_, ?_⟩
  · intro i j hij
    simp only [Nat.cast_inj] at hij
    by_contra hne
    rcases lt_or_gt_of_ne hne with h | h
    · rcases blockVal_order m i j (hm i) h with ⟨-, h'⟩ | ⟨-, h'⟩ <;> omega
    · rcases blockVal_order m j i (hm i) h with ⟨-, h'⟩ | ⟨-, h'⟩ <;> omega
  · intro t ht
    have : t.card ≤ (Finset.range p).card := by
      refine Finset.card_le_card_of_injOn (fun k => k.val / m) ?_ ?_
      · intro k _
        simp only [Finset.coe_range, Set.mem_Iio]
        exact (Nat.div_lt_iff_lt_mul (hm k)).2 k.2
      · intro i hi j hj hij
        simp only at hij
        by_contra hne
        rcases lt_or_gt_of_ne hne with h | h
        · have h2 := ht hi hj h
          simp only [Nat.cast_lt] at h2
          rcases blockVal_order m i j (hm i) h with ⟨-, h'⟩ | ⟨h', -⟩ <;> omega
        · have h2 := ht hj hi h
          simp only [Nat.cast_lt] at h2
          rcases blockVal_order m j i (hm i) h with ⟨-, h'⟩ | ⟨h', -⟩ <;> omega
    simpa using this
  · intro t ht
    have : t.card ≤ (Finset.range m).card := by
      refine Finset.card_le_card_of_injOn (fun k => k.val % m) ?_ ?_
      · intro k _
        simp only [Finset.coe_range, Set.mem_Iio]
        exact Nat.mod_lt _ (hm k)
      · intro i hi j hj hij
        simp only at hij
        by_contra hne
        rcases lt_or_gt_of_ne hne with h | h
        · have h2 := ht hi hj h
          simp only [Nat.cast_lt] at h2
          have h3 := Nat.div_add_mod i.val m
          have h4 := Nat.div_add_mod j.val m
          rcases blockVal_order m i j (hm i) h with ⟨h', -⟩ | ⟨-, h'⟩
          · rw [h', hij] at h3; exact hne (Fin.ext (by omega))
          · omega
        · have h2 := ht hj hi h
          simp only [Nat.cast_lt] at h2
          have h3 := Nat.div_add_mod i.val m
          have h4 := Nat.div_add_mod j.val m
          rcases blockVal_order m j i (hm i) h with ⟨h', -⟩ | ⟨-, h'⟩
          · rw [h', ← hij] at h4; exact hne (Fin.ext (by omega))
          · omega
    simpa using this

#print axioms blocks_list

/-! A list of `n` numbers is a function `x : Fin n → ℝ`, with `x i` the number in position `i`.
A run is a set `t` of positions, kept in list order with gaps allowed. It is a rising run when
`x` strictly increases along `t` (`StrictMonoOn x t`) and a falling run when `x` strictly
decreases along `t` (`StrictAntiOn x t`). Its length is `t.card`. -/

/-- Erdos-Szekeres: any list of more than `(r − 1)(s − 1)` numbers, all different, holds a
rising run of `r` terms or a falling run of `s` terms. With `r = s = 4`: any ten different
numbers hold four that rise or four that fall. -/
theorem erdos_szekeres_rising_or_falling_run (r s n : ℕ) (x : Fin n → ℝ)
    (hx : Function.Injective x) (hn : (r - 1) * (s - 1) < n) :
    (∃ t : Finset (Fin n), r ≤ t.card ∧ StrictMonoOn x t) ∨
      ∃ t : Finset (Fin n), s ≤ t.card ∧ StrictAntiOn x t := by
  by_contra h
  push Not at h
  obtain ⟨h1, h2⟩ := h
  have := product_bound n (r - 1) (s - 1) x hx
    (fun t ht => by
      by_contra hc
      exact h1 t (by omega) ht)
    (fun t ht => by
      by_contra hc
      exact h2 t (by omega) ht)
  omega

/-- The product bound `A × B ≥ n`: in a list of `n` different numbers, if every rising run has
at most `A` terms and every falling run has at most `B` terms, then `n ≤ A × B`. -/
theorem length_le_longest_rise_mul_longest_fall (n A B : ℕ) (x : Fin n → ℝ)
    (hx : Function.Injective x)
    (hA : ∀ t : Finset (Fin n), StrictMonoOn x t → t.card ≤ A)
    (hB : ∀ t : Finset (Fin n), StrictAntiOn x t → t.card ≤ B) :
    n ≤ A * B := by
  exact product_bound n A B x hx hA hB

/-- The threshold is exact: for run lengths `r, s ≥ 1` there is a list of `(r − 1)(s − 1)`
different numbers with no rising run of `r` terms and no falling run of `s` terms
(`r − 1` falling blocks of `s − 1` numbers, each block above the one before). -/
theorem exists_list_without_rising_or_falling_run (r s : ℕ) (hr : 1 ≤ r) (hs : 1 ≤ s) :
    ∃ x : Fin ((r - 1) * (s - 1)) → ℝ, Function.Injective x ∧
      (∀ t : Finset (Fin ((r - 1) * (s - 1))), StrictMonoOn x t → t.card < r) ∧
      (∀ t : Finset (Fin ((r - 1) * (s - 1))), StrictAntiOn x t → t.card < s) := by
  obtain ⟨x, hx, h1, h2⟩ := blocks_list (r - 1) (s - 1)
  exact ⟨x, hx, fun t ht => by have := h1 t ht; omega, fun t ht => by have := h2 t ht; omega⟩

-- The card's worked numbers, with each price written in whole cents (43.20 dollars is 4320).
-- Positions count from 0, so day 1 is position 0.
/-- Harlow Cement's ten closes, in cents. -/
def harlow : Fin 10 → ℕ := ![4320, 4210, 4460, 4165, 4395, 4630, 4288, 4515, 4705, 4570]
/-- The nine closes of Step 4, in cents: three falling blocks of three. -/
def nineDays : Fin 9 → ℕ := ![4590, 4430, 4310, 4870, 4720, 4640, 5150, 5010, 4930]

-- The shortest length that forces a run of four either way: 3 × 3 + 1 = 10.
example : (4 - 1) * (4 - 1) + 1 = 10 := by norm_num
-- Product bound for Harlow Cement: 4 × 3 = 12, at least 10.
example : 10 ≤ 4 * 3 := by norm_num
-- The ten closes are all different.
example : Function.Injective harlow := by decide
-- Days 1, 3, 6, 9 rise: 43.20 < 44.60 < 46.30 < 47.05.
example : ∀ i ∈ ({0, 2, 5, 8} : Finset (Fin 10)), ∀ j ∈ ({0, 2, 5, 8} : Finset (Fin 10)),
    i < j → harlow i < harlow j := by decide
-- Days 1, 2, 4 fall: 43.20 > 42.10 > 41.65.
example : ∀ i ∈ ({0, 1, 3} : Finset (Fin 10)), ∀ j ∈ ({0, 1, 3} : Finset (Fin 10)),
    i < j → harlow j < harlow i := by decide
-- Longest rising run is 4 and longest falling run is 3: every set of days checked.
example : ∀ t : Finset (Fin 10), (∀ i ∈ t, ∀ j ∈ t, i < j → harlow i < harlow j) → t.card ≤ 4 := by
  decide +kernel
example : ∀ t : Finset (Fin 10), (∀ i ∈ t, ∀ j ∈ t, i < j → harlow j < harlow i) → t.card ≤ 3 := by
  decide +kernel
-- Nine different closes with no rising run of 4 and no falling run of 4.
example : Function.Injective nineDays := by decide
example : ∀ t : Finset (Fin 9), (∀ i ∈ t, ∀ j ∈ t, i < j → nineDays i < nineDays j) → t.card ≤ 3 := by
  decide +kernel
example : ∀ t : Finset (Fin 9), (∀ i ∈ t, ∀ j ∈ t, i < j → nineDays j < nineDays i) → t.card ≤ 3 := by
  decide +kernel

#print axioms erdos_szekeres_rising_or_falling_run
#print axioms length_le_longest_rise_mul_longest_fall
#print axioms exists_list_without_rising_or_falling_run
