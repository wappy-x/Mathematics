-- Counting coin-flip paths: of the n-flip paths scored +1 per head and −1 per tail, those ending at height h number C(n, (n + h)/2), and of the 2m-flip paths ending at zero, Cat(m) never dip below zero and Cat(m − 1) stay strictly above zero in between, with the card's ten-flip numbers checked.
import Mathlib.Combinatorics.Enumerative.Catalan.Basic
import Mathlib.Combinatorics.Enumerative.DyckWord
import Mathlib.Data.Finset.Powerset
import Mathlib.SetTheory.Cardinal.Finite
import Mathlib.Data.Fintype.Pi
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Algebra.Order.Group.Unbundled.Abs
import Mathlib.Algebra.Group.Int.Even
import Mathlib.Tactic.NormNum

/-- One flip scored: a head (`true`) is worth `+1`, a tail (`false`) is worth `−1`. -/
def flipStep (b : Bool) : ℤ := if b then 1 else -1

/-- The running total of the path `f` (a run of `n` flips, `f i = true` meaning flip `i` came up
heads) after its first `k` flips. After all `n` flips it is the height the path ends at. -/
def heightAfter {n : ℕ} (f : Fin n → Bool) (k : ℕ) : ℤ :=
  ∑ i ∈ Finset.univ.filter (fun i : Fin n => (i : ℕ) < k), flipStep (f i)

open DyckStep

/-- A head becomes an up step, a tail a down step. -/
def boolToStep (b : Bool) : DyckStep := if b then U else D

lemma heightAfter_succ {n : ℕ} (f : Fin n → Bool) (k : ℕ) :
    heightAfter f (k + 1) = heightAfter f k + (if h : k < n then flipStep (f ⟨k, h⟩) else 0) := by
  unfold heightAfter
  split_ifs with hk
  · have : Finset.univ.filter (fun i : Fin n => (i : ℕ) < k + 1) =
        insert ⟨k, hk⟩ (Finset.univ.filter (fun i : Fin n => (i : ℕ) < k)) := by
      ext i; simp [Fin.ext_iff]; omega
    rw [this, Finset.sum_insert (by simp), add_comm]
  · have : Finset.univ.filter (fun i : Fin n => (i : ℕ) < k + 1) =
        Finset.univ.filter (fun i : Fin n => (i : ℕ) < k) := by
      ext i; have := i.2; simp; omega
    rw [this, add_zero]

lemma heightAfter_eq_list {n : ℕ} (f : Fin n → Bool) (k : ℕ) :
    heightAfter f k = (((List.ofFn f).take k).map flipStep).sum := by
  induction k with
  | zero => simp [heightAfter]
  | succ k ih =>
    rw [heightAfter_succ, ih, List.take_add_one]
    split_ifs with hk
    · simp [hk]
    · simp [hk]

lemma sum_map_flipStep (l : List Bool) :
    (l.map flipStep).sum = ((l.map boolToStep).count U : ℤ) - (l.map boolToStep).count D := by
  induction l with
  | nil => simp
  | cons b l ih =>
    cases b <;> simp [flipStep, boolToStep, ih] <;> ring

/-- The path as a list of up and down steps. -/
def stepWord {n : ℕ} (f : Fin n → Bool) : List DyckStep := (List.ofFn f).map boolToStep

@[simp] lemma length_stepWord {n : ℕ} (f : Fin n → Bool) : (stepWord f).length = n := by
  simp [stepWord]

lemma heightAfter_eq_count {n : ℕ} (f : Fin n → Bool) (k : ℕ) :
    heightAfter f k = (((stepWord f).take k).count U : ℤ) - ((stepWord f).take k).count D := by
  rw [heightAfter_eq_list, sum_map_flipStep, stepWord, List.map_take]

lemma count_U_add_count_D (l : List DyckStep) : l.count U + l.count D = l.length := by
  induction l with
  | nil => simp
  | cons s l ih => cases s <;> simp <;> omega

/-- Read a word of steps back as a run of flips. -/
def ofStepWord {n : ℕ} (l : List DyckStep) (hl : l.length = n) : Fin n → Bool :=
  fun i => decide (l[(i : ℕ)]'(by rw [hl]; exact i.2) = U)

lemma stepWord_ofStepWord {n : ℕ} (l : List DyckStep) (hl : l.length = n) :
    stepWord (ofStepWord l hl) = l := by
  apply List.ext_getElem (by simp [hl])
  intro i h1 h2
  simp only [stepWord, ofStepWord, List.getElem_map, List.getElem_ofFn, boolToStep]
  cases l[i] <;> simp

lemma ofStepWord_stepWord {n : ℕ} (f : Fin n → Bool) :
    ofStepWord (stepWord f) (length_stepWord f) = f := by
  funext i
  simp only [stepWord, ofStepWord, List.getElem_map, List.getElem_ofFn, boolToStep]
  cases f i <;> simp

/-- Paths that never dip below zero and end at zero match Dyck words. -/
def pathDyckEquiv (m : ℕ) :
    {f : Fin (2 * m) → Bool //
      heightAfter f (2 * m) = 0 ∧ ∀ k : ℕ, k ≤ 2 * m → 0 ≤ heightAfter f k} ≃
    {p : DyckWord // p.semilength = m} where
  toFun f := ⟨⟨stepWord f.1, by
      have h := f.2.1
      rw [heightAfter_eq_count, List.take_of_length_le (by simp)] at h
      omega, by
      intro i
      by_cases hi : i ≤ 2 * m
      · have h := f.2.2 i hi
        rw [heightAfter_eq_count] at h
        omega
      · have h := f.2.2 (2 * m) le_rfl
        rw [heightAfter_eq_count, List.take_of_length_le (by simp)] at h
        rw [List.take_of_length_le (by simp; omega)]
        omega⟩, by
      have h := f.2.1
      rw [heightAfter_eq_count, List.take_of_length_le (by simp)] at h
      have h2 := count_U_add_count_D (stepWord f.1)
      simp only [length_stepWord] at h2
      show (stepWord f.1).count U = m
      omega⟩
  invFun p := ⟨ofStepWord p.1.toList (by rw [← p.1.two_mul_semilength_eq_length, p.2]), by
      constructor
      · rw [heightAfter_eq_count, stepWord_ofStepWord,
          List.take_of_length_le (by rw [← p.1.two_mul_semilength_eq_length, p.2]),
          p.1.count_U_eq_count_D]
        simp
      · intro k _
        rw [heightAfter_eq_count, stepWord_ofStepWord]
        have := p.1.count_D_le_count_U k
        omega⟩
  left_inv f := by
    apply Subtype.ext
    exact ofStepWord_stepWord f.1
  right_inv p := by
    apply Subtype.ext
    apply DyckWord.ext
    exact stepWord_ofStepWord p.1.toList (by rw [← p.1.two_mul_semilength_eq_length, p.2])

lemma pathDyckEquiv_toList (m : ℕ) (f) : ((pathDyckEquiv m f).1.toList) = stepWord f.1 := rfl

/-- Wrapping a Dyck word in one outer pair of brackets, and unwrapping it. -/
def nestEquiv (m : ℕ) :
    {p : {p : DyckWord // p.semilength = m + 1} // p.1.IsNested} ≃
    {q : DyckWord // q.semilength = m} where
  toFun p := ⟨p.1.1.denest p.2, by
    have h := congrArg DyckWord.semilength (p.1.1.nest_denest p.2)
    rw [DyckWord.semilength_nest, p.1.2] at h
    omega⟩
  invFun q := ⟨⟨q.1.nest, by rw [DyckWord.semilength_nest, q.2]⟩, DyckWord.IsNested.nest⟩
  left_inv p := by
    apply Subtype.ext; apply Subtype.ext; exact p.1.1.nest_denest p.2
  right_inv q := by
    apply Subtype.ext; exact q.1.denest_nest

/-- The card's main formula. Every flip moves the total by one, up or down. If the flip count `n`
and the ending height `h` are both even or both odd, and `h` lies between `−n` and `n`, then the
paths of `n` flips that end at height `h` number `C(n, (n + h)/2)`. -/
theorem paths_ending_at_height_eq_choose (n : ℕ) (h : ℤ) (hpar : Even ((n : ℤ) + h))
    (hrange : |h| ≤ n) :
    (Finset.univ.filter (fun f : Fin n → Bool => heightAfter f n = h)).card =
      n.choose ((n + h) / 2).toNat := by
  obtain ⟨t, ht⟩ := hpar
  obtain ⟨h1, h2⟩ := abs_le.mp hrange
  have hdiv : ((n : ℤ) + h) / 2 = t := by omega
  have ht0 : 0 ≤ t := by omega
  have key : ∀ f : Fin n → Bool,
      heightAfter f n = 2 * ((Finset.univ.filter (fun i => f i = true)).card : ℤ) - n := by
    intro f
    have hf : ∀ b : Bool, flipStep b = 2 * (if b = true then (1 : ℤ) else 0) - 1 := by
      intro b; cases b <;> simp [flipStep]
    unfold heightAfter
    rw [Finset.filter_true_of_mem (fun i _ => i.2)]
    simp_rw [hf]
    rw [Finset.sum_sub_distrib, ← Finset.mul_sum, Finset.sum_boole]
    simp
  rw [hdiv, show n.choose t.toNat = (Finset.powersetCard t.toNat (Finset.univ : Finset (Fin n))).card
    by simp [Finset.card_powersetCard]]
  apply Finset.card_nbij' (fun f => Finset.univ.filter (fun i => f i = true))
    (fun s => fun i => decide (i ∈ s))
  · intro f hf
    simp only [Finset.coe_filter, Finset.mem_univ, true_and, Set.mem_ofPred_eq] at hf
    simp only [Finset.mem_coe, Finset.mem_powersetCard, Finset.subset_univ, true_and]
    rw [key] at hf
    omega
  · intro s hs
    simp only [Finset.mem_coe, Finset.mem_powersetCard, Finset.subset_univ, true_and] at hs
    simp only [Finset.coe_filter, Finset.mem_univ, true_and, Set.mem_ofPred_eq]
    rw [key]
    have : Finset.univ.filter (fun i => decide (i ∈ s) = true) = s := by ext; simp
    rw [this, hs]
    omega
  · intro f _
    funext i
    simp
  · intro s _
    ext; simp

/-- Of the paths of `2m` flips that end back at zero, the ones whose running total never dips
below zero number the Catalan number `Cat(m) = C(2m, m)/(m + 1)`. -/
theorem never_below_zero_returns_eq_catalan (m : ℕ) :
    (Finset.univ.filter (fun f : Fin (2 * m) → Bool =>
      heightAfter f (2 * m) = 0 ∧ ∀ k : ℕ, k ≤ 2 * m → 0 ≤ heightAfter f k)).card = catalan m := by
  rw [← Fintype.card_subtype, ← Nat.card_eq_fintype_card, Nat.card_congr (pathDyckEquiv m),
    Nat.card_eq_fintype_card, DyckWord.card_dyckWord_semilength_eq_catalan]

/-- Of the paths of `2m` flips that end back at zero, the ones whose running total stays strictly
above zero after every flip from the first to the one before last number `Cat(m − 1)`. -/
theorem strictly_above_zero_returns_eq_catalan_pred (m : ℕ) :
    (Finset.univ.filter (fun f : Fin (2 * m) → Bool =>
      heightAfter f (2 * m) = 0 ∧ ∀ k : ℕ, k < 2 * m → 0 < k → 0 < heightAfter f k)).card =
      catalan (m - 1) := by
  cases m with
  | zero => simp [heightAfter]
  | succ m =>
    rw [← Fintype.card_subtype, ← Nat.card_eq_fintype_card]
    have hQP : ∀ {f : Fin (2 * (m + 1)) → Bool},
        (heightAfter f (2 * (m + 1)) = 0 ∧
          ∀ k : ℕ, k < 2 * (m + 1) → 0 < k → 0 < heightAfter f k) →
        (heightAfter f (2 * (m + 1)) = 0 ∧
          ∀ k : ℕ, k ≤ 2 * (m + 1) → 0 ≤ heightAfter f k) := by
      intro f hf
      refine ⟨hf.1, fun k hk => ?_⟩
      rcases Nat.eq_zero_or_pos k with h0 | h0
      · subst h0; simp [heightAfter]
      · rcases Nat.lt_or_ge k (2 * (m + 1)) with h1 | h1
        · exact (hf.2 k h1 h0).le
        · rw [show k = 2 * (m + 1) by omega, hf.1]
    have e := (Equiv.subtypeSubtypeEquivSubtype hQP).symm.trans
      ((Equiv.subtypeEquiv (q := fun p => p.1.IsNested) (pathDyckEquiv (m + 1)) (by
        intro x
        simp only [DyckWord.IsNested, pathDyckEquiv_toList, length_stepWord]
        constructor
        · intro h
          refine ⟨?_, ?_⟩
          · intro h0
            have := congrArg (fun p => p.toList.length) h0
            simp [pathDyckEquiv_toList] at this
          · intro i hi1 hi2
            have := h.2 i hi2 hi1
            rw [heightAfter_eq_count] at this
            omega
        · rintro ⟨-, h⟩
          refine ⟨x.2.1, fun k hk1 hk2 => ?_⟩
          rw [heightAfter_eq_count]
          have := h hk2 hk1
          omega)).trans (nestEquiv m))
    rw [Nat.card_congr e, Nat.card_eq_fintype_card, DyckWord.card_dyckWord_semilength_eq_catalan]
    rfl

-- Ten flips: 2^10 = 1024 runs in all.
example : Fintype.card (Fin 10 → Bool) = 1024 := by simp
-- Heads needed: (10 + 0)/2 = 5 to end level, (10 + 2)/2 = 6 to end at +2.
example : (10 + 0) / 2 = 5 ∧ (10 + 2) / 2 = 6 := by decide
-- 252 paths end level, 210 end at +2, 42 never dip below zero, 14 stay strictly above.
example : Nat.choose 10 5 = 252 ∧ Nat.choose 10 6 = 210 := by decide
example : catalan 5 = 42 ∧ 252 / 6 = 42 ∧ 252 = 6 * 42 := by
  rw [catalan_eq_centralBinom_div, Nat.centralBinom_eq_two_mul_choose]; decide
example : catalan 4 = 14 ∧ Nat.choose 8 4 = 70 ∧ 70 / 5 = 14 ∧ 70 = 5 * 14 := by
  rw [catalan_eq_centralBinom_div, Nat.centralBinom_eq_two_mul_choose]; decide
-- The reflection count: 210 paths end at −2, leaving 252 − 210 = 42.
example : Nat.choose 10 4 = 210 ∧ 252 - 210 = 42 := by decide
-- The whole ten-flip row of the chart: 1, 10, 45, 120, 210, 252, 210, 120, 45, 10, 1.
example : (List.range 11).map (Nat.choose 10) = [1, 10, 45, 120, 210, 252, 210, 120, 45, 10, 1] := by
  decide
-- The same ten-flip counts, made path by path from the definitions above.
example : (Finset.univ.filter (fun f : Fin 10 → Bool => heightAfter f 10 = 0)).card = 252 := by
  decide +kernel
example : (Finset.univ.filter (fun f : Fin 10 → Bool => heightAfter f 10 = 2)).card = 210 := by
  decide +kernel
example : (Finset.univ.filter (fun f : Fin 10 → Bool =>
    heightAfter f 10 = 0 ∧ ∀ k : ℕ, k ≤ 10 → 0 ≤ heightAfter f k)).card = 42 := by
  decide +kernel
example : (Finset.univ.filter (fun f : Fin 10 → Bool =>
    heightAfter f 10 = 0 ∧ ∀ k : ℕ, k < 10 → 0 < k → 0 < heightAfter f k)).card = 14 := by
  decide +kernel
-- Parity: ten flips cannot end at +1, so no path does.
example : (Finset.univ.filter (fun f : Fin 10 → Bool => heightAfter f 10 = 1)).card = 0 := by
  decide +kernel
-- The card's run H T T H H H T H T T (heads at flips 1, 4, 5, 6, 8) ends level.
example : heightAfter ![true, false, false, true, true, true, false, true, false, false] 10 = 0 := by
  decide +kernel
-- The four-flip warm-up, counted path by path: 16 runs, 6 end level, 2 never below zero, 1 strictly above.
example : (Finset.univ.filter (fun f : Fin 4 → Bool => heightAfter f 4 = 0)).card = 6 := by
  decide +kernel
example : (Finset.univ.filter (fun f : Fin 4 → Bool =>
    heightAfter f 4 = 0 ∧ ∀ k : ℕ, k ≤ 4 → 0 ≤ heightAfter f k)).card = 2 := by
  decide +kernel
example : (Finset.univ.filter (fun f : Fin 4 → Bool =>
    heightAfter f 4 = 0 ∧ ∀ k : ℕ, k < 4 → 0 < k → 0 < heightAfter f k)).card = 1 := by
  decide +kernel
-- The mistakes: C(10, 2) = 45 is not 210; and 252/5 is not whole (252 = 5 · 50 + 2).
example : Nat.choose 10 2 = 45 ∧ 252 % 5 = 2 := by decide

#print axioms boolToStep
#print axioms heightAfter_succ
#print axioms heightAfter_eq_list
#print axioms sum_map_flipStep
#print axioms stepWord
#print axioms length_stepWord
#print axioms heightAfter_eq_count
#print axioms count_U_add_count_D
#print axioms ofStepWord
#print axioms stepWord_ofStepWord
#print axioms ofStepWord_stepWord
#print axioms pathDyckEquiv
#print axioms pathDyckEquiv_toList
#print axioms nestEquiv
#print axioms paths_ending_at_height_eq_choose
#print axioms never_below_zero_returns_eq_catalan
#print axioms strictly_above_zero_returns_eq_catalan_pred
