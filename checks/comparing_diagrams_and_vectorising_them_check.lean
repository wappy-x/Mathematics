-- Comparing diagrams: every landscape level of two persistence diagrams differs by at most their bottleneck distance at every scale, the bottleneck distance obeys the triangle inequality, and the card's calm and stormy months are 0.10% apart.
import Mathlib.Algebra.Order.Archimedean.Real.Basic
import Mathlib.Data.Fintype.Option
import Mathlib.Data.Fintype.Pi
import Mathlib.Data.List.Sort
import Mathlib.Data.Fin.VecNotation
import Mathlib.Tactic.NormNum
import Mathlib.Data.Fintype.Order
import Mathlib.Tactic.FinCases
import Mathlib.Tactic.Linarith

namespace ComparingDiagrams

variable {m n l : ℕ}

/-- A persistence diagram with `m` dots: dot `i` is the bar `[b, d)`, stored as `(b, d)`. -/
abbrev Diagram (m : ℕ) := Fin m → ℝ × ℝ

/-- The worst-coordinate distance between two dots: the larger of the two coordinate gaps. -/
noncomputable def supDist (p q : ℝ × ℝ) : ℝ := max |p.1 - q.1| |p.2 - q.2|

/-- The cost of retiring a dot `(b, d)` to the diagonal: half its lifetime, `(d - b) / 2`. -/
noncomputable def halfLife (p : ℝ × ℝ) : ℝ := (p.2 - p.1) / 2

/-- A matching from `A` (with `m` dots) to `B` (with `n` dots): each dot of `A` goes to a dot of
`B` (`some j`) or to the diagonal (`none`), and no dot of `B` is used twice. Dots of `B` that no
dot of `A` reaches go to the diagonal. -/
def IsMatching (γ : Fin m → Option (Fin n)) : Prop :=
  ∀ i i' j, γ i = some j → γ i' = some j → i = i'

/-- The move of dot `i` of `A` under `γ`: to its partner in `B`, or to the diagonal. -/
noncomputable def moveA (A : Diagram m) (B : Diagram n) (γ : Fin m → Option (Fin n))
    (i : Fin m) : ℝ :=
  match γ i with
  | some j => supDist (A i) (B j)
  | none => halfLife (A i)

open Classical in
/-- The move of dot `j` of `B` under `γ`: nothing extra if some dot of `A` is paired with it
(that move is counted on the `A` side), otherwise its retirement to the diagonal. -/
noncomputable def moveB (B : Diagram n) (γ : Fin m → Option (Fin n)) (j : Fin n) : ℝ :=
  if ∃ i, γ i = some j then 0 else halfLife (B j)

/-- The worst single move of a matching (`0` when there is nothing to move). -/
noncomputable def worstMove (A : Diagram m) (B : Diagram n) (γ : Fin m → Option (Fin n)) : ℝ :=
  max 0 (max (⨆ i, moveA A B γ i) (⨆ j, moveB B γ j))

/-- The bottleneck distance `d_B(A, B)`: over every matching, the smallest worst move. -/
noncomputable def bottleneck (A : Diagram m) (B : Diagram n) : ℝ :=
  ⨅ γ : {γ : Fin m → Option (Fin n) // IsMatching γ}, worstMove A B γ.1

/-- A bar's tent at scale `t`: `max(0, min(t - b, d - t))`, slope one up from the birth `b`
and down to the death `d`. -/
noncomputable def tent (p : ℝ × ℝ) (t : ℝ) : ℝ := max 0 (min (t - p.1) (p.2 - t))

/-- The `k`-th landscape `λ_k(t)` (counting from `k = 1`): the `k`-th largest of the tents at
scale `t`, read as `0` when there are fewer than `k` bars (the list is padded with zeros). -/
noncomputable def landscape (D : Diagram m) (k : ℕ) (t : ℝ) : ℝ :=
  ((List.ofFn fun i => tent (D i) t).mergeSort (fun a b => decide (b ≤ a))).getD (k - 1) 0

/-! Helper lemmas for the proofs below. -/

open Finset

lemma supDist_comm (p q : ℝ × ℝ) : supDist p q = supDist q p := by
  simp [supDist, abs_sub_comm]
#print axioms supDist_comm

lemma supDist_triangle (p q r : ℝ × ℝ) : supDist p r ≤ supDist p q + supDist q r := by
  unfold supDist
  have h1 := abs_sub_le p.1 q.1 r.1
  have h2 := abs_sub_le p.2 q.2 r.2
  apply max_le
  · linarith [le_max_left |p.1 - q.1| |p.2 - q.2|, le_max_left |q.1 - r.1| |q.2 - r.2|]
  · linarith [le_max_right |p.1 - q.1| |p.2 - q.2|, le_max_right |q.1 - r.1| |q.2 - r.2|]
#print axioms supDist_triangle

lemma halfLife_le (p q : ℝ × ℝ) : halfLife p ≤ halfLife q + supDist p q := by
  unfold halfLife supDist
  have h1 := le_max_left |p.1 - q.1| |p.2 - q.2|
  have h2 := le_max_right |p.1 - q.1| |p.2 - q.2|
  have h3 := neg_abs_le (p.1 - q.1)
  have h4 := le_abs_self (p.2 - q.2)
  linarith
#print axioms halfLife_le

lemma tent_le_halfLife (p : ℝ × ℝ) (t : ℝ) : tent p t ≤ max 0 (halfLife p) := by
  unfold tent halfLife
  apply max_le_max le_rfl
  have := min_le_left (t - p.1) (p.2 - t)
  have := min_le_right (t - p.1) (p.2 - t)
  linarith
#print axioms tent_le_halfLife

lemma tent_le_of_halfLife_le {p : ℝ × ℝ} {ε : ℝ} (t : ℝ) (hε : 0 ≤ ε) (h : halfLife p ≤ ε) :
    tent p t ≤ ε :=
  (tent_le_halfLife p t).trans (max_le hε h)
#print axioms tent_le_of_halfLife_le

lemma abs_tent_sub_le (p q : ℝ × ℝ) (t : ℝ) : |tent p t - tent q t| ≤ supDist p q := by
  unfold tent supDist
  calc |max 0 (min (t - p.1) (p.2 - t)) - max 0 (min (t - q.1) (q.2 - t))|
      = |max (min (t - p.1) (p.2 - t)) 0 - max (min (t - q.1) (q.2 - t)) 0| := by
        rw [max_comm 0, max_comm 0]
    _ ≤ |min (t - p.1) (p.2 - t) - min (t - q.1) (q.2 - t)| := abs_max_sub_max_le_abs _ _ _
    _ ≤ max |(t - p.1) - (t - q.1)| |(p.2 - t) - (q.2 - t)| := abs_min_sub_min_le_max _ _ _ _
    _ = max |p.1 - q.1| |p.2 - q.2| := by
        rw [show (t - p.1) - (t - q.1) = -(p.1 - q.1) by ring, abs_neg,
          show (p.2 - t) - (q.2 - t) = p.2 - q.2 by ring]
#print axioms abs_tent_sub_le

lemma tent_le_tent_add (p q : ℝ × ℝ) (t : ℝ) : tent p t ≤ tent q t + supDist p q := by
  have := abs_tent_sub_le p q t
  rw [abs_le] at this
  linarith
#print axioms tent_le_tent_add

lemma worstMove_nonneg (A : Diagram m) (B : Diagram n) (γ : Fin m → Option (Fin n)) :
    0 ≤ worstMove A B γ := le_max_left _ _
#print axioms worstMove_nonneg

lemma moveA_le_worstMove (A : Diagram m) (B : Diagram n) (γ : Fin m → Option (Fin n))
    (i : Fin m) : moveA A B γ i ≤ worstMove A B γ :=
  le_max_of_le_right (le_max_of_le_left (le_ciSup (Finite.bddAbove_range _) i))
#print axioms moveA_le_worstMove

lemma moveB_le_worstMove (A : Diagram m) (B : Diagram n) (γ : Fin m → Option (Fin n))
    (j : Fin n) : moveB B γ j ≤ worstMove A B γ :=
  le_max_of_le_right (le_max_of_le_right (le_ciSup (Finite.bddAbove_range _) j))
#print axioms moveB_le_worstMove

lemma worstMove_le (A : Diagram m) (B : Diagram n) (γ : Fin m → Option (Fin n)) {c : ℝ}
    (h0 : 0 ≤ c) (hA : ∀ i, moveA A B γ i ≤ c) (hB : ∀ j, moveB B γ j ≤ c) :
    worstMove A B γ ≤ c :=
  max_le h0 (max_le (Real.iSup_le hA h0) (Real.iSup_le hB h0))
#print axioms worstMove_le

lemma isMatching_none : IsMatching (fun _ : Fin m => (none : Option (Fin n))) := by
  intro i i' j h
  simp at h
#print axioms isMatching_none

lemma bottleneck_le (A : Diagram m) (B : Diagram n) (γ : Fin m → Option (Fin n))
    (hγ : IsMatching γ) : bottleneck A B ≤ worstMove A B γ :=
  ciInf_le ⟨0, by rintro _ ⟨g, rfl⟩; exact worstMove_nonneg A B g.1⟩ (⟨γ, hγ⟩ :
    {γ : Fin m → Option (Fin n) // IsMatching γ})
#print axioms bottleneck_le

lemma le_bottleneck (A : Diagram m) (B : Diagram n) {c : ℝ}
    (h : ∀ γ : Fin m → Option (Fin n), IsMatching γ → c ≤ worstMove A B γ) :
    c ≤ bottleneck A B := by
  have : Nonempty {γ : Fin m → Option (Fin n) // IsMatching γ} := ⟨⟨_, isMatching_none⟩⟩
  exact le_ciInf fun g => h g.1 g.2
#print axioms le_bottleneck

lemma pairwise_sorted (l : List ℝ) :
    (l.mergeSort (fun a b => decide (b ≤ a))).Pairwise (fun a b => b ≤ a) := by
  have := List.pairwise_mergeSort (le := fun a b : ℝ => decide (b ≤ a))
    (fun a b c hab hbc => by simp at *; linarith) (fun a b => by simpa using le_total b a) l
  simpa using this
#print axioms pairwise_sorted

lemma countP_sorted (f : Fin m → ℝ) (x : ℝ) :
    ((List.ofFn f).mergeSort (fun a b => decide (b ≤ a))).countP (fun a => decide (x ≤ a)) =
      (univ.filter (fun i => x ≤ f i)).card := by
  rw [(List.mergeSort_perm _ _).countP_eq]
  have h : (List.ofFn f).countP (fun a => decide (x ≤ a)) =
      Multiset.countP (fun a => x ≤ a) ((univ : Finset (Fin m)).val.map f) := by
    rw [Fin.univ_val_map, Multiset.coe_countP]
  rw [h, Multiset.countP_map]
  rfl
#print axioms countP_sorted

lemma getD_nonneg (l : List ℝ) (hl : ∀ a ∈ l, 0 ≤ a) (r : ℕ) : 0 ≤ l.getD r 0 := by
  induction l generalizing r with
  | nil => simp
  | cons a l ih =>
    cases r with
    | zero => simpa using hl a (by simp)
    | succ r => simpa using ih (fun b hb => hl b (by simp [hb])) r
#print axioms getD_nonneg

lemma le_getD_of_count (l : List ℝ) (hl : l.Pairwise (fun a b => b ≤ a)) (r : ℕ) (x : ℝ)
    (h : r + 1 ≤ l.countP (fun a => decide (x ≤ a))) : x ≤ l.getD r 0 := by
  induction l generalizing r with
  | nil => simp at h
  | cons a l ih =>
    rw [List.pairwise_cons] at hl
    cases r with
    | zero =>
      simp only [List.getD_cons_zero]
      obtain ⟨b, hb, hxb⟩ := List.countP_pos_iff.mp
        (by omega : 0 < (a :: l).countP (fun c => decide (x ≤ c)))
      simp only [decide_eq_true_eq] at hxb
      rcases List.mem_cons.mp hb with rfl | hb
      · exact hxb
      · exact hxb.trans (hl.1 b hb)
    | succ r =>
      simp only [List.getD_cons_succ]
      apply ih hl.2
      rw [List.countP_cons] at h
      split_ifs at h <;> omega
#print axioms le_getD_of_count

lemma count_of_le_getD (l : List ℝ) (hl : l.Pairwise (fun a b => b ≤ a)) (r : ℕ) (x : ℝ)
    (hx : 0 < x) (h : x ≤ l.getD r 0) : r + 1 ≤ l.countP (fun a => decide (x ≤ a)) := by
  induction l generalizing r with
  | nil => simp at h; linarith
  | cons a l ih =>
    rw [List.pairwise_cons] at hl
    rw [List.countP_cons]
    cases r with
    | zero =>
      simp only [List.getD_cons_zero] at h
      simp [h]
    | succ r =>
      simp only [List.getD_cons_succ] at h
      have h1 := ih hl.2 r h
      obtain ⟨b, hb, hxb⟩ := List.countP_pos_iff.mp
        (by omega : 0 < l.countP (fun c => decide (x ≤ c)))
      simp only [decide_eq_true_eq] at hxb
      have : x ≤ a := hxb.trans (hl.1 b hb)
      simp [this]
      omega
#print axioms count_of_le_getD

lemma landscape_nonneg (D : Diagram m) (k : ℕ) (t : ℝ) : 0 ≤ landscape D k t := by
  unfold landscape
  apply getD_nonneg
  intro a ha
  rw [(List.mergeSort_perm _ _).mem_iff, List.mem_ofFn] at ha
  obtain ⟨i, rfl⟩ := ha
  exact le_max_left _ _
#print axioms landscape_nonneg

/-- One side of the landscape comparison, from a counting inequality. -/
lemma landscape_le_of_card (D : Diagram m) (E : Diagram n) (k : ℕ) (t ε : ℝ) (hε : 0 ≤ ε)
    (h : ∀ x, ε < x → (univ.filter (fun i => x ≤ tent (D i) t)).card ≤
      (univ.filter (fun j => x - ε ≤ tent (E j) t)).card) :
    landscape D k t ≤ landscape E k t + ε := by
  by_contra hlt
  rw [not_le] at hlt
  have hE := landscape_nonneg E k t
  set x := landscape D k t with hx
  have hxε : ε < x := by linarith
  have h1 := count_of_le_getD _ (pairwise_sorted _) (k - 1) x (by linarith) le_rfl
  rw [countP_sorted] at h1
  have h2 := le_getD_of_count _ (pairwise_sorted (List.ofFn fun j => tent (E j) t)) (k - 1)
    (x - ε) (by rw [countP_sorted]; exact h1.trans (h x hxε))
  have : x - ε ≤ landscape E k t := h2
  linarith
#print axioms landscape_le_of_card

/-- Landscapes move no more than the bottleneck distance (Step 3): for every level `k` and
every scale `t`, `|λ_k^A(t) - λ_k^B(t)| ≤ d_B(A, B)`, so `sup_t |λ_k^A(t) - λ_k^B(t)| ≤ d_B(A, B)`. -/
theorem landscape_gap_le_bottleneck (A : Diagram m) (B : Diagram n) (k : ℕ) (t : ℝ) :
    |landscape A k t - landscape B k t| ≤ bottleneck A B := by
  refine le_bottleneck A B (fun γ hγ => ?_)
  set ε := worstMove A B γ with hεdef
  have hε : 0 ≤ ε := worstMove_nonneg A B γ
  rw [abs_sub_le_iff]
  constructor
  · have key := landscape_le_of_card A B k t ε hε (fun x hx => ?_)
    · linarith
    have hsome : ∀ i, x ≤ tent (A i) t → ∃ j, γ i = some j ∧ x - ε ≤ tent (B j) t := by
      intro i hi
      have h1 := moveA_le_worstMove A B γ i
      cases hγi : γ i with
      | none =>
        simp only [moveA, hγi] at h1
        have := tent_le_of_halfLife_le t hε h1
        linarith
      | some j =>
        simp only [moveA, hγi] at h1
        have := tent_le_tent_add (A i) (B j) t
        exact ⟨j, rfl, by linarith⟩
    calc (univ.filter (fun i => x ≤ tent (A i) t)).card
        ≤ ((univ.filter (fun j => x - ε ≤ tent (B j) t)).map Function.Embedding.some).card := by
          apply card_le_card_of_injOn γ
          · intro i hi
            simp only [coe_filter, mem_univ, true_and, Set.mem_ofPred_eq] at hi
            obtain ⟨j, hj, hjt⟩ := hsome i hi
            simp only [coe_map, Function.Embedding.some_apply, coe_filter, mem_univ, true_and,
              Set.mem_image, Set.mem_ofPred_eq, hj]
            exact ⟨j, hjt, rfl⟩
          · intro i hi i' hi' h
            simp only [coe_filter, mem_univ, true_and, Set.mem_ofPred_eq] at hi hi'
            obtain ⟨j, hj, -⟩ := hsome i hi
            exact hγ i i' j hj (h ▸ hj)
      _ = _ := card_map _
  · have key := landscape_le_of_card B A k t ε hε (fun x hx => ?_)
    · linarith
    have hsub : (univ.filter (fun j => x ≤ tent (B j) t)).map Function.Embedding.some ⊆
        (univ.filter (fun i => x - ε ≤ tent (A i) t)).image γ := by
      intro o ho
      simp only [mem_map, mem_filter, mem_univ, true_and, Function.Embedding.some_apply] at ho
      obtain ⟨j, hj, rfl⟩ := ho
      by_cases hex : ∃ i, γ i = some j
      · obtain ⟨i, hi⟩ := hex
        have h1 := moveA_le_worstMove A B γ i
        simp only [moveA, hi] at h1
        have := tent_le_tent_add (B j) (A i) t
        rw [supDist_comm] at this
        simp only [mem_image, mem_filter, mem_univ, true_and]
        exact ⟨i, by linarith, hi⟩
      · have h1 := moveB_le_worstMove A B γ j
        simp only [moveB, hex, ↓reduceIte] at h1
        have := tent_le_of_halfLife_le t hε h1
        linarith
    calc (univ.filter (fun j => x ≤ tent (B j) t)).card
        = ((univ.filter (fun j => x ≤ tent (B j) t)).map Function.Embedding.some).card :=
          (card_map _).symm
      _ ≤ _ := card_le_card hsub
      _ ≤ _ := card_image_le

/-- The bottleneck distance obeys the triangle inequality (Step 2):
`d_B(A, C) ≤ d_B(A, B) + d_B(B, C)`. -/
theorem bottleneck_triangle (A : Diagram m) (B : Diagram n) (C : Diagram l) :
    bottleneck A C ≤ bottleneck A B + bottleneck B C := by
  have key : ∀ γ : Fin m → Option (Fin n), IsMatching γ → ∀ δ : Fin n → Option (Fin l),
      IsMatching δ → bottleneck A C ≤ worstMove A B γ + worstMove B C δ := by
    intro γ hγ δ hδ
    have hcomp : IsMatching (fun i => (γ i).bind δ) := by
      intro i i' k h h'
      cases hi : γ i with
      | none => simp [hi] at h
      | some j =>
        cases hi' : γ i' with
        | none => simp [hi'] at h'
        | some j' =>
          simp only [hi, hi', Option.bind_some] at h h'
          exact hγ i i' j hi (by rw [hi', hδ j j' k h h'])
    have e1 := worstMove_nonneg A B γ
    have e2 := worstMove_nonneg B C δ
    refine (bottleneck_le A C _ hcomp).trans
      (worstMove_le A C _ (add_nonneg e1 e2) (fun i => ?_) (fun k => ?_))
    · have hA := moveA_le_worstMove A B γ i
      cases hi : γ i with
      | none =>
        simp only [moveA, hi, Option.bind_none] at hA ⊢
        linarith
      | some j =>
        have hB := moveA_le_worstMove B C δ j
        simp only [moveA, hi] at hA
        cases hj : δ j with
        | none =>
          simp only [moveA, hj] at hB
          simp only [moveA, hi, hj, Option.bind_some]
          have := halfLife_le (A i) (B j)
          linarith
        | some k =>
          simp only [moveA, hj] at hB
          simp only [moveA, hi, hj, Option.bind_some]
          have := supDist_triangle (A i) (B j) (C k)
          linarith
    · unfold moveB
      split_ifs with hk
      · linarith
      · by_cases hδk : ∃ j, δ j = some k
        · obtain ⟨j, hj⟩ := hδk
          have hγj : ¬ ∃ i, γ i = some j := by
            rintro ⟨i, hi⟩
            exact hk ⟨i, by simp [hi, hj]⟩
          have h1 := moveB_le_worstMove A B γ j
          simp only [moveB, hγj, ↓reduceIte] at h1
          have h2 := moveA_le_worstMove B C δ j
          simp only [moveA, hj] at h2
          have := halfLife_le (C k) (B j)
          rw [supDist_comm] at this
          linarith
        · have h1 := moveB_le_worstMove B C δ k
          simp only [moveB, hδk, ↓reduceIte] at h1
          linarith
  have h1 : ∀ δ : Fin n → Option (Fin l), IsMatching δ →
      bottleneck A C - worstMove B C δ ≤ bottleneck A B := by
    intro δ hδ
    apply le_bottleneck
    intro γ hγ
    linarith [key γ hγ δ hδ]
  have h2 : bottleneck A C - bottleneck A B ≤ bottleneck B C := by
    apply le_bottleneck
    intro δ hδ
    linarith [h1 δ hδ]
  linarith

/-! The card's worked numbers, in quarter basis points (one unit is 0.0025%, so 40 is 0.10%). -/

/-- The calm month's loops: A0 = (0.15, 0.165), A1 = (0.165, 0.17), A2 = (0.56, 0.61) percent. -/
def calm : Diagram 3 := ![((60 : ℝ), 66), ((66 : ℝ), 68), ((224 : ℝ), 244)]

/-- The stormy month's loops: B0 = (0.505, 0.71), B1 = (0.52, 0.71), B2 = (1.055, 1.20) percent. -/
def stormy : Diagram 3 := ![((202 : ℝ), 284), ((208 : ℝ), 284), ((422 : ℝ), 480)]

/-- The worked bottleneck distance: the calm and stormy months are 40 quarter basis points,
0.10%, apart. -/
theorem bottleneck_calm_stormy : bottleneck calm stormy = 40 := by
  apply le_antisymm
  · let γ0 : Fin 3 → Option (Fin 3) := ![none, none, some 0]
    have hγ0 : IsMatching γ0 := by
      intro i i' j h h'
      fin_cases i <;> fin_cases i' <;> simp [γ0] at h h' ⊢
    refine (bottleneck_le _ _ γ0 hγ0).trans (worstMove_le _ _ _ (by norm_num) ?_ ?_)
    · intro i
      fin_cases i <;> norm_num [moveA, γ0, calm, stormy, supDist, halfLife, abs_of_neg, abs_of_pos]
    · intro j
      fin_cases j <;> simp [moveB, γ0, stormy, halfLife, Fin.exists_fin_succ] <;> norm_num
  · apply le_bottleneck
    intro γ hγ
    by_cases h : ∃ i, γ i = some 0
    · obtain ⟨i, hi⟩ := h
      have := moveA_le_worstMove calm stormy γ i
      simp only [moveA, hi] at this
      refine le_trans ?_ this
      fin_cases i <;> norm_num [calm, stormy, supDist, abs_of_neg, abs_of_pos]
    · have := moveB_le_worstMove calm stormy γ 0
      simp only [moveB, h, ↓reduceIte] at this
      refine le_trans ?_ this
      norm_num [stormy, halfLife]

-- Half-lifetimes of the calm dots: 0.0075, 0.0025, 0.025 percent.
example : halfLife (60, 66) = 3 ∧ halfLife (66, 68) = 1 ∧ halfLife (224, 244) = 10 := by
  norm_num [halfLife]

-- Half-lifetimes of the stormy dots: 0.1025, 0.095, 0.0725 percent.
example : halfLife (202, 284) = 41 ∧ halfLife (208, 284) = 38 ∧ halfLife (422, 480) = 29 := by
  norm_num [halfLife]

-- Pairing A2 with B0 or B1 costs 0.10 percent; pairing A2 with B2 costs 0.59 percent.
example : supDist (224, 244) (202, 284) = 40 ∧ supDist (224, 244) (208, 284) = 40 ∧
    supDist (224, 244) (422, 480) = 236 := by
  norm_num [supDist, abs_of_neg, abs_of_pos]

-- The plan A2 ↔ B0, the rest retired: worst move 0.10 percent, total W_1 = 0.2775 percent.
example : max (max (max (max (3 : ℝ) 1) 40) 38) 29 = 40 ∧ (3 : ℝ) + 1 + 40 + 38 + 29 = 111 := by
  norm_num

-- Stormy tents at t = 0.60 percent: B0 stands 0.095, B1 stands 0.08, B2 is flat.
example : tent (202, 284) 240 = 38 ∧ tent (208, 284) 240 = 32 ∧ tent (422, 480) 240 = 0 := by
  norm_num [tent]

-- No feature: calm lifetimes 6, 2, 20 against 2c = 2 × 21; stormy 82, 76, 58 against 2 × 48.
example : (6 : ℤ) ≤ 2 * 21 ∧ (2 : ℤ) ≤ 2 * 21 ∧ (20 : ℤ) ≤ 2 * 21 ∧
    (82 : ℤ) ≤ 2 * 48 ∧ (76 : ℤ) ≤ 2 * 48 ∧ (58 : ℤ) ≤ 2 * 48 := by
  decide

-- The months compared: d_B = 40 against the combined band 21 + 48 = 69 (0.1725 percent).
example : (40 : ℤ) < 21 + 48 := by decide

#print axioms landscape_gap_le_bottleneck
#print axioms bottleneck_triangle
#print axioms bottleneck_calm_stormy

end ComparingDiagrams
