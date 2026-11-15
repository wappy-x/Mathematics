-- Closed surfaces classified: on gluing diagrams, the standard words for g handles and k crosscaps have V - E + F equal to 2 - 2g (two-sided) and 2 - k (one-sided), no two of them share both counts, and writing two closed words one after the other (connected sum) gives V - E + F equal to the two counts added minus 2.
import Mathlib.Combinatorics.SimpleGraph.Connectivity.Finite
import Mathlib

/-!
Mathlib has no connected sum of spaces, no orientation of a topological surface and no
triangulations, so the classification theorem itself cannot be stated here; the card also
gives its proof only as key steps. This file states the parts the card proves, on the card's
own gluing diagrams.

A gluing diagram is one polygon whose edges carry letters, read round the polygon as an
edge word. A letter is a whole number; `true` means its arrow runs with the walk, `false`
means against it (the card's minus-one power). The torus square `a b a⁻¹ b⁻¹` is
`[(0, true), (1, true), (0, false), (1, false)]`.
-/

/-- An edge word: the letters met going round the polygon, each with its arrow's direction
(`true` with the walk, `false` against it). -/
abbrev EdgeWord := List (ℕ × Bool)

namespace EdgeWord

/-- The corner after corner `i`, going round the polygon. Edge `i` runs from corner `i` to
this corner. -/
def next (w : EdgeWord) (i : Fin w.length) : Fin w.length :=
  ⟨(i.1 + 1) % w.length, Nat.mod_lt _ (Nat.lt_of_le_of_lt (Nat.zero_le _) i.2)⟩

/-- The corner where edge `i`'s arrow starts. -/
def startCorner (w : EdgeWord) (i : Fin w.length) : Fin w.length :=
  if (w.get i).2 then i else w.next i

/-- The corner where edge `i`'s arrow ends. -/
def endCorner (w : EdgeWord) (i : Fin w.length) : Fin w.length :=
  if (w.get i).2 then w.next i else i

/-- Gluing the corners (card, Step 1): two edges with the same letter glue start corner to
start corner and end corner to end corner. -/
def cornerGluing (w : EdgeWord) : SimpleGraph (Fin w.length) :=
  SimpleGraph.fromRel fun c d => ∃ i j : Fin w.length, i ≠ j ∧ (w.get i).1 = (w.get j).1 ∧
    ((c = w.startCorner i ∧ d = w.startCorner j) ∨ (c = w.endCorner i ∧ d = w.endCorner j))

instance (w : EdgeWord) : DecidableRel w.cornerGluing.Adj := by
  unfold cornerGluing; infer_instance

/-- `V`: the number of vertices after gluing, one for each group of glued corners. -/
def vertices (w : EdgeWord) : ℕ := Fintype.card w.cornerGluing.ConnectedComponent

/-- `E`: the number of edges after gluing, one for each letter. -/
def edges (w : EdgeWord) : ℕ := (w.map Prod.fst).toFinset.card

/-- The Euler characteristic `χ = V - E + F`, with `F = 1` face, the polygon. -/
def euler (w : EdgeWord) : ℤ := (w.vertices : ℤ) - w.edges + 1

/-- A closed diagram: every letter is on exactly two edges, so no edge is left as a rim. -/
def IsClosedDiagram (w : EdgeWord) : Prop :=
  ∀ p ∈ w, w.countP (fun q => q.1 = p.1) = 2

instance (w : EdgeWord) : Decidable w.IsClosedDiagram := by
  unfold IsClosedDiagram; infer_instance

/-- The card's two-sided test on a word (Step 2): every letter appears once plain and once
with the minus-one power. A letter appearing twice with the same power is a half-twisted
band, and the surface is one-sided. -/
def IsTwoSided (w : EdgeWord) : Prop :=
  ∀ p ∈ w, w.count (p.1, true) = 1 ∧ w.count (p.1, false) = 1

instance (w : EdgeWord) : Decidable w.IsTwoSided := by
  unfold IsTwoSided; infer_instance

/-- The standard word for the sphere with `g` handles: `a a⁻¹` for the sphere itself (`g = 0`),
and `a₁ b₁ a₁⁻¹ b₁⁻¹ ⋯ a_g b_g a_g⁻¹ b_g⁻¹` for `g ≥ 1`. -/
def handleForm : ℕ → EdgeWord
  | 0 => [(0, true), (0, false)]
  | g + 1 => (List.range (g + 1)).flatMap fun i =>
      [(2 * i, true), (2 * i + 1, true), (2 * i, false), (2 * i + 1, false)]

/-- The standard word for the sphere with `k` crosscaps: `a₁ a₁ a₂ a₂ ⋯ a_k a_k`. -/
def crosscapForm (k : ℕ) : EdgeWord :=
  (List.range k).flatMap fun i => [(i, true), (i, true)]

end EdgeWord

open EdgeWord

namespace SurfHelp

lemma flatMap_length {α} (f : ℕ → List α) (L : ℕ) (hf : ∀ i, (f i).length = L) (n : ℕ) :
    ((List.range n).flatMap f).length = L * n := by
  induction n with
  | zero => simp
  | succ n ih => simp [List.range_succ, List.flatMap_append, ih, hf]; ring

lemma flatMap_getElem {α} (f : ℕ → List α) (L : ℕ) (hf : ∀ i, (f i).length = L) (n i r : ℕ)
    (hi : i < n) (hr : r < L) (h : L * i + r < ((List.range n).flatMap f).length) :
    ((List.range n).flatMap f)[L * i + r] = (f i)[r]'(by rw [hf]; exact hr) := by
  induction n with
  | zero => omega
  | succ n ih =>
    simp only [List.range_succ, List.flatMap_append, List.flatMap_singleton]
    rw [List.getElem_append]
    have hl := flatMap_length f L hf n
    split_ifs with h1
    · rcases Nat.lt_succ_iff_lt_or_eq.mp hi with h2 | h2
      · exact ih h2 _
      · subst h2; rw [hl] at h1; nlinarith
    · rcases Nat.lt_succ_iff_lt_or_eq.mp hi with h2 | h2
      · rw [hl] at h1; exfalso; apply h1; nlinarith
      · subst h2; simp [hl]


def blkH (i : ℕ) : EdgeWord := [(2 * i, true), (2 * i + 1, true), (2 * i, false), (2 * i + 1, false)]
def blkC (i : ℕ) : EdgeWord := [(i, true), (i, true)]

lemma handle_eq (g : ℕ) : handleForm (g + 1) = (List.range (g + 1)).flatMap blkH := rfl
lemma crosscap_eq (k : ℕ) : crosscapForm k = (List.range k).flatMap blkC := rfl

lemma countP_H (n a : ℕ) : ((List.range n).flatMap blkH).countP (fun q => decide (q.1 = a)) =
    if a < 2 * n then 2 else 0 := by
  induction n with
  | zero => simp
  | succ n ih =>
    simp only [List.range_succ, List.flatMap_append, List.flatMap_singleton, List.countP_append,
      ih, blkH, List.countP_cons, List.countP_nil]
    split_ifs <;> simp_all <;> omega

lemma count_H (n a : ℕ) (b : Bool) : ((List.range n).flatMap blkH).count (a, b) =
    if a < 2 * n then 1 else 0 := by
  induction n with
  | zero => simp
  | succ n ih =>
    simp only [List.range_succ, List.flatMap_append, List.flatMap_singleton, List.count_append,
      ih, blkH, List.count_cons, List.count_nil]
    cases b <;> split_ifs <;> simp_all <;> omega

lemma countP_C (n a : ℕ) : ((List.range n).flatMap blkC).countP (fun q => decide (q.1 = a)) =
    if a < n then 2 else 0 := by
  induction n with
  | zero => simp
  | succ n ih =>
    simp only [List.range_succ, List.flatMap_append, List.flatMap_singleton, List.countP_append,
      ih, blkC, List.countP_cons, List.countP_nil]
    split_ifs <;> simp_all <;> omega

lemma mem_H (n : ℕ) (p : ℕ × Bool) (hp : p ∈ (List.range n).flatMap blkH) : p.1 < 2 * n := by
  simp only [List.mem_flatMap, List.mem_range, blkH, List.mem_cons, List.not_mem_nil] at hp
  obtain ⟨i, hi, h⟩ := hp
  rcases h with h | h | h | h | h <;> first | (subst h; simp; omega) | exact absurd h id

lemma mem_C (n : ℕ) (p : ℕ × Bool) (hp : p ∈ (List.range n).flatMap blkC) : p.1 < n := by
  simp only [List.mem_flatMap, List.mem_range, blkC, List.mem_cons, List.not_mem_nil] at hp
  obtain ⟨i, hi, h⟩ := hp
  rcases h with h | h | h <;> first | (subst h; simp; omega) | exact absurd h id

lemma edges_H (n : ℕ) : edges ((List.range n).flatMap blkH) = 2 * n := by
  unfold edges
  have : (((List.range n).flatMap blkH).map Prod.fst).toFinset = Finset.range (2 * n) := by
    ext a
    simp only [List.mem_toFinset, List.mem_map, Finset.mem_range]
    constructor
    · rintro ⟨p, hp, rfl⟩; exact mem_H n p hp
    · intro ha
      refine ⟨(a, true), ?_, rfl⟩
      simp only [List.mem_flatMap, List.mem_range, blkH, List.mem_cons, List.not_mem_nil]
      refine ⟨a / 2, by omega, ?_⟩
      rcases Nat.even_or_odd a with ⟨t, ht⟩ | ⟨t, ht⟩
      · left; simp; omega
      · right; left; simp; omega
  rw [this, Finset.card_range]

lemma edges_C (n : ℕ) : edges ((List.range n).flatMap blkC) = n := by
  unfold edges
  have : (((List.range n).flatMap blkC).map Prod.fst).toFinset = Finset.range n := by
    ext a
    simp only [List.mem_toFinset, List.mem_map, Finset.mem_range]
    constructor
    · rintro ⟨p, hp, rfl⟩; exact mem_C n p hp
    · intro ha
      refine ⟨(a, true), ?_, rfl⟩
      simp only [List.mem_flatMap, List.mem_range, blkC, List.mem_cons, List.not_mem_nil]
      exact ⟨a, ha, by simp⟩
  rw [this, Finset.card_range]


lemma reach_start (w : EdgeWord) (i j : Fin w.length) (h : (w.get i).1 = (w.get j).1) :
    w.cornerGluing.Reachable (w.startCorner i) (w.startCorner j) := by
  by_cases hij : i = j
  · subst hij; rfl
  by_cases hc : w.startCorner i = w.startCorner j
  · rw [hc]
  apply SimpleGraph.Adj.reachable
  simp only [cornerGluing, SimpleGraph.fromRel_adj]
  exact ⟨hc, Or.inl ⟨i, j, hij, h, Or.inl ⟨rfl, rfl⟩⟩⟩

lemma reach_end (w : EdgeWord) (i j : Fin w.length) (h : (w.get i).1 = (w.get j).1) :
    w.cornerGluing.Reachable (w.endCorner i) (w.endCorner j) := by
  by_cases hij : i = j
  · subst hij; rfl
  by_cases hc : w.endCorner i = w.endCorner j
  · rw [hc]
  apply SimpleGraph.Adj.reachable
  simp only [cornerGluing, SimpleGraph.fromRel_adj]
  exact ⟨hc, Or.inl ⟨i, j, hij, h, Or.inr ⟨rfl, rfl⟩⟩⟩

lemma start_val (w : EdgeWord) (i : Fin w.length) :
    (w.startCorner i).val = if (w.get i).2 then i.val else (i.val + 1) % w.length := by
  unfold startCorner next; split_ifs <;> rfl

lemma end_val (w : EdgeWord) (i : Fin w.length) :
    (w.endCorner i).val = if (w.get i).2 then (i.val + 1) % w.length else i.val := by
  unfold endCorner next; split_ifs <;> rfl

lemma vertices_one (w : EdgeWord) (hN : 0 < w.length)
    (h : ∀ c : Fin w.length, w.cornerGluing.Reachable ⟨0, hN⟩ c) : w.vertices = 1 := by
  unfold vertices
  rw [Fintype.card_eq_one_iff]
  refine ⟨w.cornerGluing.connectedComponentMk ⟨0, hN⟩, fun x => ?_⟩
  induction x using SimpleGraph.ConnectedComponent.ind with
  | h v => exact (SimpleGraph.ConnectedComponent.sound (h v)).symm

/-- Reachability between corners given by their numbers. -/
def R (w : EdgeWord) (a b : ℕ) : Prop :=
  ∀ (ha : a < w.length) (hb : b < w.length), w.cornerGluing.Reachable ⟨a, ha⟩ ⟨b, hb⟩

lemma R_symm {w : EdgeWord} {a b : ℕ} (h : R w a b) : R w b a := fun ha hb => (h hb ha).symm

lemma R_trans {w : EdgeWord} {a b c : ℕ} (hb : b < w.length) (h1 : R w a b) (h2 : R w b c) :
    R w a c := fun ha hc => (h1 ha hb).trans (h2 hb hc)

lemma R_start (w : EdgeWord) (i j : ℕ) (hi : i < w.length) (hj : j < w.length)
    (h : (w[i]).1 = (w[j]).1) (a b : ℕ)
    (ha : a = if (w[i]).2 then i else (i + 1) % w.length)
    (hb : b = if (w[j]).2 then j else (j + 1) % w.length) : R w a b := by
  intro ha' hb'
  have := reach_start w ⟨i, hi⟩ ⟨j, hj⟩ h
  convert this using 1 <;> apply Fin.ext <;> simp [start_val, ha, hb]

lemma R_end (w : EdgeWord) (i j : ℕ) (hi : i < w.length) (hj : j < w.length)
    (h : (w[i]).1 = (w[j]).1) (a b : ℕ)
    (ha : a = if (w[i]).2 then (i + 1) % w.length else i)
    (hb : b = if (w[j]).2 then (j + 1) % w.length else j) : R w a b := by
  intro ha' hb'
  have := reach_end w ⟨i, hi⟩ ⟨j, hj⟩ h
  convert this using 1 <;> apply Fin.ext <;> simp [end_val, ha, hb]

lemma handle_len (g : ℕ) : (handleForm (g + 1)).length = 4 * (g + 1) := by
  rw [handle_eq, flatMap_length blkH 4 (fun _ => rfl)]

lemma crosscap_len (k : ℕ) : (crosscapForm k).length = 2 * k := by
  rw [crosscap_eq, flatMap_length blkC 2 (fun _ => rfl)]

lemma handle_get (g i r : ℕ) (hi : i < g + 1) (hr : r < 4) (h : 4 * i + r < (handleForm (g + 1)).length) :
    (handleForm (g + 1))[4 * i + r] = (blkH i)[r]'(by simp [blkH]; omega) := by
  simp only [handle_eq]
  exact flatMap_getElem blkH 4 (fun _ => rfl) (g + 1) i r hi hr _

lemma crosscap_get (k i r : ℕ) (hi : i < k) (hr : r < 2) (h : 2 * i + r < (crosscapForm k).length) :
    (crosscapForm k)[2 * i + r] = (blkC i)[r]'(by simp [blkC]; omega) := by
  simp only [crosscap_eq]
  exact flatMap_getElem blkC 2 (fun _ => rfl) k i r hi hr _

lemma handle_step (g c : ℕ) (hc : c + 1 < 4 * (g + 1)) : R (handleForm (g + 1)) c (c + 1) := by
  have hL := handle_len g
  obtain ⟨i, r, hr, rfl⟩ : ∃ i r, r < 4 ∧ c = 4 * i + r := ⟨c / 4, c % 4, by omega, by omega⟩
  have hi : i < g + 1 := by omega
  have g0 := handle_get g i 0 hi (by norm_num) (by omega)
  have g1 := handle_get g i 1 hi (by norm_num) (by omega)
  have g2 := handle_get g i 2 hi (by norm_num) (by omega)
  have g3 := handle_get g i 3 hi (by norm_num) (by omega)
  simp only [blkH, add_zero, List.getElem_cons_zero, List.getElem_cons_succ] at g0 g1 g2 g3
  -- the four gluings of block i
  have A : R (handleForm (g + 1)) (4 * i) (4 * i + 3) := R_start (handleForm (g + 1)) (4 * i) (4 * i + 2) (by omega) (by omega)
    (by rw [g0, g2]) _ _ (by rw [g0]; simp) (by rw [g2]; simp [hL, Nat.mod_eq_of_lt (show 4 * i + 3 < 4 * (g + 1) by omega)])
  have B : R (handleForm (g + 1)) (4 * i + 1) (4 * i + 2) := R_end (handleForm (g + 1)) (4 * i) (4 * i + 2) (by omega) (by omega)
    (by rw [g0, g2]) _ _ (by rw [g0]; simp [hL, Nat.mod_eq_of_lt (show 4 * i + 1 < 4 * (g + 1) by omega)]) (by rw [g2]; simp)
  have C : R (handleForm (g + 1)) (4 * i + 2) (4 * i + 3) := R_end (handleForm (g + 1)) (4 * i + 1) (4 * i + 3) (by omega) (by omega)
    (by rw [g1, g3]) _ _ (by rw [g1]; simp [hL, Nat.mod_eq_of_lt (show 4 * i + 2 < 4 * (g + 1) by omega)]) (by rw [g3]; simp)
  have D : R (handleForm (g + 1)) (4 * i + 1) ((4 * i + 4) % (4 * (g + 1))) := R_start (handleForm (g + 1)) (4 * i + 1) (4 * i + 3)
    (by omega) (by omega) (by rw [g1, g3]) _ _ (by rw [g1]; simp) (by rw [g3]; simp [hL])
  interval_cases r
  · exact R_trans (b := 4 * i + 3) (by omega) A (R_trans (b := 4 * i + 2) (by omega) (R_symm C) (R_symm B))
  · exact B
  · exact C
  · have : (4 * i + 4) % (4 * (g + 1)) = 4 * i + 3 + 1 := Nat.mod_eq_of_lt (by omega)
    rw [this] at D
    exact R_trans (b := 4 * i + 2) (by omega) (R_symm C)
      (R_trans (b := 4 * i + 1) (by omega) (R_symm B) D)

lemma crosscap_step (k c : ℕ) (hc : c + 1 < 2 * k) : R (crosscapForm k) c (c + 1) := by
  have hL := crosscap_len k
  obtain ⟨i, r, hr, rfl⟩ : ∃ i r, r < 2 ∧ c = 2 * i + r := ⟨c / 2, c % 2, by omega, by omega⟩
  have hi : i < k := by omega
  have g0 := crosscap_get k i 0 hi (by norm_num) (by omega)
  have g1 := crosscap_get k i 1 hi (by norm_num) (by omega)
  simp only [blkC, add_zero, List.getElem_cons_zero, List.getElem_cons_succ] at g0 g1
  interval_cases r
  · exact R_start (crosscapForm k) (2 * i) (2 * i + 1) (by omega) (by omega) (by rw [g0, g1]) _ _
      (by rw [g0]; simp) (by rw [g1]; simp)
  · exact R_end (crosscapForm k) (2 * i) (2 * i + 1) (by omega) (by omega) (by rw [g0, g1]) _ _
      (by rw [g0]; simp [hL, Nat.mod_eq_of_lt (show 2 * i + 1 < 2 * k by omega)]) (by rw [g1]; simp [hL, Nat.mod_eq_of_lt (show 2 * i + 2 < 2 * k by omega)])

lemma R_chain (w : EdgeWord) (h : ∀ c, c + 1 < w.length → R w c (c + 1)) :
    ∀ c, c < w.length → R w 0 c := by
  intro c
  induction c with
  | zero => intro _ _ _; rfl
  | succ c ih => intro hc; exact R_trans (b := c) (by omega) (ih (by omega)) (h c hc)

lemma handle_vertices (g : ℕ) : (handleForm (g + 1)).vertices = 1 := by
  have hL := handle_len g
  refine vertices_one _ (by omega) (fun c => ?_)
  exact R_chain _ (fun c hc => handle_step g c (by omega)) c.1 c.2 _ _

lemma crosscap_vertices (k : ℕ) (hk : 1 ≤ k) : (crosscapForm k).vertices = 1 := by
  have hL := crosscap_len k
  refine vertices_one _ (by omega) (fun c => ?_)
  exact R_chain _ (fun c hc => crosscap_step k c (by omega)) c.1 c.2 _ _


lemma count_C (n a : ℕ) : ((List.range n).flatMap blkC).count (a, true) =
    if a < n then 2 else 0 := by
  induction n with
  | zero => simp
  | succ n ih =>
    simp only [List.range_succ, List.flatMap_append, List.flatMap_singleton, List.count_append,
      ih, blkC, List.count_cons, List.count_nil]
    split_ifs <;> simp_all <;> omega



lemma countP_eq_card {α} (p : α → Bool) (l : List α) :
    l.countP p = (Finset.univ.filter (fun j : Fin l.length => p (l.get j) = true)).card := by
  induction l with
  | nil => simp
  | cons a l ih =>
    rw [Finset.card_filter]
    refine Eq.trans ?_ (Fin.sum_univ_succ (n := l.length) _).symm
    rw [List.countP_cons, ih, Finset.card_filter]
    simp only [List.length_cons, List.get_eq_getElem, Fin.val_zero, List.getElem_cons_zero,
      Fin.val_succ, List.getElem_cons_succ]
    split_ifs <;> simp_all [add_comm]

lemma startL (w w' : EdgeWord) (hm : 0 < w'.length) (i : ℕ) (hi : i < w.length) :
    ((w ++ w').startCorner ⟨i, by simp; omega⟩).val = (w.startCorner ⟨i, hi⟩).val ∨
    (((w ++ w').startCorner ⟨i, by simp; omega⟩).val = w.length ∧
      (w.startCorner ⟨i, hi⟩).val = 0) := by
  rw [start_val, start_val]
  simp only [List.get_eq_getElem, List.getElem_append_left hi, List.length_append]
  split_ifs
  · left; rfl
  · rcases Nat.lt_or_ge (i + 1) w.length with h | h
    · left; rw [Nat.mod_eq_of_lt h, Nat.mod_eq_of_lt (by omega)]
    · right
      have : i + 1 = w.length := by omega
      rw [this, Nat.mod_self, Nat.mod_eq_of_lt (by omega)]; simp

lemma endL (w w' : EdgeWord) (hm : 0 < w'.length) (i : ℕ) (hi : i < w.length) :
    ((w ++ w').endCorner ⟨i, by simp; omega⟩).val = (w.endCorner ⟨i, hi⟩).val ∨
    (((w ++ w').endCorner ⟨i, by simp; omega⟩).val = w.length ∧
      (w.endCorner ⟨i, hi⟩).val = 0) := by
  rw [end_val, end_val]
  simp only [List.get_eq_getElem, List.getElem_append_left hi, List.length_append]
  split_ifs
  · rcases Nat.lt_or_ge (i + 1) w.length with h | h
    · left; rw [Nat.mod_eq_of_lt h, Nat.mod_eq_of_lt (by omega)]
    · right
      have : i + 1 = w.length := by omega
      rw [this, Nat.mod_self, Nat.mod_eq_of_lt (by omega)]; simp
  · left; rfl

lemma startR (w w' : EdgeWord) (i : ℕ) (hi : i < w'.length) :
    ((w ++ w').startCorner ⟨w.length + i, by simp; omega⟩).val =
      w.length + (w'.startCorner ⟨i, hi⟩).val ∨
    (((w ++ w').startCorner ⟨w.length + i, by simp; omega⟩).val = 0 ∧
      (w'.startCorner ⟨i, hi⟩).val = 0) := by
  rw [start_val, start_val]
  simp only [List.get_eq_getElem, List.getElem_append_right (Nat.le_add_right _ _),
    Nat.add_sub_cancel_left, List.length_append]
  split_ifs
  · left; rfl
  · rcases Nat.lt_or_ge (i + 1) w'.length with h | h
    · left; rw [Nat.mod_eq_of_lt h, Nat.mod_eq_of_lt (by omega)]; omega
    · right
      have : i + 1 = w'.length := by omega
      rw [this, Nat.mod_self, show w.length + i + 1 = w.length + w'.length by omega, Nat.mod_self]
      simp

lemma endR (w w' : EdgeWord) (i : ℕ) (hi : i < w'.length) :
    ((w ++ w').endCorner ⟨w.length + i, by simp; omega⟩).val =
      w.length + (w'.endCorner ⟨i, hi⟩).val ∨
    (((w ++ w').endCorner ⟨w.length + i, by simp; omega⟩).val = 0 ∧
      (w'.endCorner ⟨i, hi⟩).val = 0) := by
  rw [end_val, end_val]
  simp only [List.get_eq_getElem, List.getElem_append_right (Nat.le_add_right _ _),
    Nat.add_sub_cancel_left, List.length_append]
  split_ifs
  · rcases Nat.lt_or_ge (i + 1) w'.length with h | h
    · left; rw [Nat.mod_eq_of_lt h, Nat.mod_eq_of_lt (by omega)]; omega
    · right
      have : i + 1 = w'.length := by omega
      rw [this, Nat.mod_self, show w.length + i + 1 = w.length + w'.length by omega, Nat.mod_self]
      simp
  · left; rfl


lemma reach_zero_n (w w' : EdgeWord) (hw : w.IsClosedDiagram) (hn : 0 < w.length)
    (hm : 0 < w'.length) :
    (w ++ w').cornerGluing.Reachable ⟨0, by simp; omega⟩ ⟨w.length, by simp; omega⟩ := by
  classical
  by_contra hnot
  have hN : (w ++ w').length = w.length + w'.length := List.length_append
  let Q : ℕ → Prop := fun c => ∃ h : c < (w ++ w').length,
    (w ++ w').cornerGluing.Reachable ⟨0, by omega⟩ ⟨c, h⟩
  let f : ℕ → ℕ := fun c => if Q c then 1 else 0
  have hf : ∀ a b : Fin (w ++ w').length, (w ++ w').cornerGluing.Reachable a b →
      f a.val = f b.val := by
    intro a b hab
    have : Q a.val ↔ Q b.val :=
      ⟨fun ⟨_, r⟩ => ⟨b.2, r.trans hab⟩, fun ⟨_, r⟩ => ⟨a.2, r.trans hab.symm⟩⟩
    simp only [f, this]
  have hQ0 : Q 0 := ⟨by omega, SimpleGraph.Reachable.refl _⟩
  have hQn : ¬ Q w.length := fun ⟨_, r⟩ => hnot r
  have f0 : f 0 = 1 := by simp only [f, hQ0, ite_true]
  have fn : f w.length = 0 := by simp only [f, hQn, ite_false]
  let s : Fin w.length → ℕ := fun i =>
    f ((w ++ w').startCorner ⟨i, by omega⟩).val + f ((w ++ w').endCorner ⟨i, by omega⟩).val
  have hs : ∀ i : Fin w.length, s i = f i + f (i + 1) := by
    intro i
    simp only [s, start_val, end_val, hN]
    rw [Nat.mod_eq_of_lt (by omega)]
    split_ifs <;> ring
  have hodd : ∑ i, s i + 1 = 2 * ∑ i ∈ Finset.range w.length, f i := by
    rw [Finset.sum_congr rfl (fun i _ => hs i),
      Fin.sum_univ_eq_sum_range (fun i => f i + f (i + 1)) w.length, Finset.sum_add_distrib]
    have e1 := Finset.sum_range_succ f w.length
    have e2 := Finset.sum_range_succ' f w.length
    omega
  have heven : 2 ∣ ∑ i, s i := by
    rw [← Finset.sum_fiberwise_of_maps_to (s := Finset.univ)
      (t := Finset.univ.image (fun i : Fin w.length => (w.get i).1))
      (g := fun i => (w.get i).1) (fun i _ => Finset.mem_image_of_mem _ (Finset.mem_univ i))]
    apply Finset.dvd_sum
    intro a ha
    obtain ⟨i0, -, rfl⟩ := Finset.mem_image.mp ha
    rw [Finset.sum_const_nat (m := s i0) (fun j hj => ?_)]
    · have hc := hw (w.get i0) (List.get_mem _ _)
      rw [countP_eq_card] at hc
      simp only [decide_eq_true_eq] at hc
      rw [hc]
      exact dvd_mul_right 2 _
    · simp only [Finset.mem_filter, Finset.mem_univ, true_and] at hj
      have hWj : ((w ++ w').get ⟨j, by omega⟩).1 = ((w ++ w').get ⟨i0, by omega⟩).1 := by
        simp only [List.get_eq_getElem, List.getElem_append_left j.2,
          List.getElem_append_left i0.2]
        simpa using hj
      simp only [s]
      rw [hf _ _ (reach_start _ _ _ hWj), hf _ _ (reach_end _ _ _ hWj)]
  omega


open Classical in
/-- Where a corner of the second word goes: its own component, or the first word's component
of corner 0 when it is in the component of corner 0. -/
noncomputable def psiR (w w' : EdgeWord) (hn : 0 < w.length) (hm : 0 < w'.length)
    (c' : Fin w'.length) :
    w.cornerGluing.ConnectedComponent ⊕ w'.cornerGluing.ConnectedComponent :=
  if w'.cornerGluing.connectedComponentMk c' = w'.cornerGluing.connectedComponentMk ⟨0, hm⟩ then
    Sum.inl (w.cornerGluing.connectedComponentMk ⟨0, hn⟩)
  else Sum.inr (w'.cornerGluing.connectedComponentMk c')

/-- Where a corner of the joined word goes. -/
noncomputable def psi (w w' : EdgeWord) (hn : 0 < w.length) (hm : 0 < w'.length)
    (c : Fin (w ++ w').length) :
    w.cornerGluing.ConnectedComponent ⊕ w'.cornerGluing.ConnectedComponent :=
  if h : c.val < w.length then Sum.inl (w.cornerGluing.connectedComponentMk ⟨c.val, h⟩)
  else psiR w w' hn hm ⟨c.val - w.length, by have := c.2; simp at this; omega⟩

lemma psiR_zero (w w' : EdgeWord) (hn : 0 < w.length) (hm : 0 < w'.length) :
    psiR w w' hn hm ⟨0, hm⟩ = Sum.inl (w.cornerGluing.connectedComponentMk ⟨0, hn⟩) := by
  simp [psiR]

lemma psi_L (w w' : EdgeWord) (hn : 0 < w.length) (hm : 0 < w'.length)
    (c : Fin (w ++ w').length) (c0 : Fin w.length)
    (h : c.val = c0.val ∨ (c.val = w.length ∧ c0.val = 0)) :
    psi w w' hn hm c = Sum.inl (w.cornerGluing.connectedComponentMk c0) := by
  rcases h with h | ⟨h1, h2⟩
  · have hc : c.val < w.length := h ▸ c0.2
    simp only [psi, hc, ↓reduceDIte]
    congr 2; exact Fin.ext h
  · have hc : ¬ c.val < w.length := by omega
    simp only [psi, hc, ↓reduceDIte]
    have : (⟨c.val - w.length, by have := c.2; simp at this; omega⟩ : Fin w'.length) = ⟨0, hm⟩ :=
      Fin.ext (by simp; omega)
    rw [this, psiR_zero]
    congr 2; exact Fin.ext h2.symm

lemma psi_R (w w' : EdgeWord) (hn : 0 < w.length) (hm : 0 < w'.length)
    (c : Fin (w ++ w').length) (c0 : Fin w'.length)
    (h : c.val = w.length + c0.val ∨ (c.val = 0 ∧ c0.val = 0)) :
    psi w w' hn hm c = psiR w w' hn hm c0 := by
  rcases h with h | ⟨h1, h2⟩
  · have hc : ¬ c.val < w.length := by omega
    simp only [psi, hc, ↓reduceDIte]
    congr 1; exact Fin.ext (by simp; omega)
  · have hc : c.val < w.length := by omega
    simp only [psi, hc, ↓reduceDIte]
    have : c0 = ⟨0, hm⟩ := Fin.ext h2
    rw [this, psiR_zero]
    congr 2; exact Fin.ext h1

lemma psiR_reach (w w' : EdgeWord) (hn : 0 < w.length) (hm : 0 < w'.length)
    (a b : Fin w'.length) (h : w'.cornerGluing.Reachable a b) :
    psiR w w' hn hm a = psiR w w' hn hm b := by
  have e := SimpleGraph.ConnectedComponent.sound h
  unfold psiR
  split_ifs with h1 h2 h2
  · rfl
  · rw [e] at h1; exact absurd h1 h2
  · rw [e] at h1; exact absurd h2 h1
  · rw [e]

lemma side_eq (w w' : EdgeWord) (hdisj : ∀ p ∈ w, ∀ q ∈ w', p.1 ≠ q.1)
    (i j : Fin (w ++ w').length) (h : ((w ++ w').get i).1 = ((w ++ w').get j).1)
    (hi : i.val < w.length) : j.val < w.length := by
  by_contra hj
  push Not at hj
  have hjm : j.val - w.length < w'.length := by have := j.2; simp at this; omega
  simp only [List.get_eq_getElem, List.getElem_append_left hi, List.getElem_append_right hj] at h
  exact hdisj _ (List.getElem_mem _) _ (List.getElem_mem _) h

lemma side_eq' (w w' : EdgeWord) (hdisj : ∀ p ∈ w, ∀ q ∈ w', p.1 ≠ q.1)
    (i j : Fin (w ++ w').length) (h : ((w ++ w').get i).1 = ((w ++ w').get j).1)
    (hi : ¬ i.val < w.length) : ¬ j.val < w.length := fun hj =>
  hi (side_eq w w' hdisj j i h.symm hj)

lemma rel_psi (w w' : EdgeWord) (hn : 0 < w.length) (hm : 0 < w'.length)
    (hdisj : ∀ p ∈ w, ∀ q ∈ w', p.1 ≠ q.1) (c d : Fin (w ++ w').length)
    (i j : Fin (w ++ w').length) (hl : ((w ++ w').get i).1 = ((w ++ w').get j).1)
    (hcd : (c = (w ++ w').startCorner i ∧ d = (w ++ w').startCorner j) ∨
      (c = (w ++ w').endCorner i ∧ d = (w ++ w').endCorner j)) :
    psi w w' hn hm c = psi w w' hn hm d := by
  by_cases hi : i.val < w.length
  · have hj := side_eq w w' hdisj i j hl hi
    obtain ⟨i, hiN⟩ := i
    obtain ⟨j, hjN⟩ := j
    simp only at hi hj
    have hl' : (w.get ⟨i, hi⟩).1 = (w.get ⟨j, hj⟩).1 := by
      simpa [List.getElem_append_left hi, List.getElem_append_left hj] using hl
    rcases hcd with ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩
    · rw [psi_L w w' hn hm _ _ (startL w w' hm i hi), psi_L w w' hn hm _ _ (startL w w' hm j hj),
        SimpleGraph.ConnectedComponent.sound (reach_start w _ _ hl')]
    · rw [psi_L w w' hn hm _ _ (endL w w' hm i hi), psi_L w w' hn hm _ _ (endL w w' hm j hj),
        SimpleGraph.ConnectedComponent.sound (reach_end w _ _ hl')]
  · have hj := side_eq' w w' hdisj i j hl hi
    obtain ⟨i, hiN⟩ := i
    obtain ⟨j, hjN⟩ := j
    simp only [not_lt] at hi hj
    obtain ⟨i, rfl⟩ : ∃ i', i = w.length + i' := ⟨i - w.length, by omega⟩
    obtain ⟨j, rfl⟩ : ∃ j', j = w.length + j' := ⟨j - w.length, by omega⟩
    have hiN' : i < w'.length := by simp at hiN; omega
    have hjN' : j < w'.length := by simp at hjN; omega
    have hl' : (w'.get ⟨i, hiN'⟩).1 = (w'.get ⟨j, hjN'⟩).1 := by
      simpa [List.getElem_append_right] using hl
    rcases hcd with ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩
    · rw [psi_R w w' hn hm _ _ (startR w w' i hiN'), psi_R w w' hn hm _ _ (startR w w' j hjN'),
        psiR_reach w w' hn hm _ _ (reach_start w' _ _ hl')]
    · rw [psi_R w w' hn hm _ _ (endR w w' i hiN'), psi_R w w' hn hm _ _ (endR w w' j hjN'),
        psiR_reach w w' hn hm _ _ (reach_end w' _ _ hl')]

lemma psi_reach (w w' : EdgeWord) (hn : 0 < w.length) (hm : 0 < w'.length)
    (hdisj : ∀ p ∈ w, ∀ q ∈ w', p.1 ≠ q.1) (c d : Fin (w ++ w').length)
    (h : (w ++ w').cornerGluing.Reachable c d) : psi w w' hn hm c = psi w w' hn hm d := by
  obtain ⟨p⟩ := h
  induction p with
  | nil => rfl
  | cons hadj _ ih =>
    rw [← ih]
    simp only [cornerGluing, SimpleGraph.fromRel_adj] at hadj
    rcases hadj.2 with ⟨i, j, -, hl, hcd⟩ | ⟨i, j, -, hl, hcd⟩
    · exact rel_psi w w' hn hm hdisj _ _ i j hl hcd
    · exact (rel_psi w w' hn hm hdisj _ _ i j hl hcd).symm


lemma liftL (w w' : EdgeWord) (hn : 0 < w.length) (hm : 0 < w'.length)
    (hP : (w ++ w').cornerGluing.Reachable ⟨0, by simp only [List.length_append]; omega⟩ ⟨w.length, by simp only [List.length_append]; omega⟩)
    (u v : Fin w.length) (h : w.cornerGluing.Reachable u v) :
    (w ++ w').cornerGluing.Reachable ⟨u.val, by simp only [List.length_append]; omega⟩ ⟨v.val, by simp only [List.length_append]; omega⟩ := by
  -- two corners of the joined word standing for the same corner of `w` are joined
  have hrep : ∀ (x y : Fin (w ++ w').length) (u : Fin w.length),
      (x.val = u.val ∨ (x.val = w.length ∧ u.val = 0)) →
      (y.val = u.val ∨ (y.val = w.length ∧ u.val = 0)) →
      (w ++ w').cornerGluing.Reachable x y := by
    rintro ⟨x, hxN⟩ ⟨y, hyN⟩ u hx hy
    simp only at hx hy
    rcases hx with hx | ⟨hx, hu⟩ <;> rcases hy with hy | ⟨hy, hu'⟩
    · have hxy : x = y := hx.trans hy.symm
      subst hxy; rfl
    · have hx0 : x = 0 := by omega
      subst hx0 hy; exact hP
    · have hy0 : y = 0 := by omega
      subst hy0 hx; exact hP.symm
    · have hxy : x = y := hx.trans hy.symm
      subst hxy; rfl
  have hrel : ∀ (a b : Fin w.length) (i j : Fin w.length), (w.get i).1 = (w.get j).1 →
      ((a = w.startCorner i ∧ b = w.startCorner j) ∨ (a = w.endCorner i ∧ b = w.endCorner j)) →
      (w ++ w').cornerGluing.Reachable ⟨a.val, by simp only [List.length_append]; omega⟩ ⟨b.val, by simp only [List.length_append]; omega⟩ := by
    intro a b i j hl hab
    obtain ⟨i, hi⟩ := i
    obtain ⟨j, hj⟩ := j
    have hW : ((w ++ w').get ⟨i, by simp only [List.length_append]; omega⟩).1 = ((w ++ w').get ⟨j, by simp only [List.length_append]; omega⟩).1 := by
      simpa [List.getElem_append_left hi, List.getElem_append_left hj] using hl
    rcases hab with ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩
    · exact (hrep _ _ _ (Or.inl rfl) (startL w w' hm i hi)).trans
        ((reach_start _ _ _ hW).trans (hrep _ _ _ (startL w w' hm j hj) (Or.inl rfl)))
    · exact (hrep _ _ _ (Or.inl rfl) (endL w w' hm i hi)).trans
        ((reach_end _ _ _ hW).trans (hrep _ _ _ (endL w w' hm j hj) (Or.inl rfl)))
  obtain ⟨p⟩ := h
  induction p with
  | nil => rfl
  | cons hadj _ ih =>
    refine SimpleGraph.Reachable.trans ?_ ih
    simp only [cornerGluing, SimpleGraph.fromRel_adj] at hadj
    rcases hadj.2 with ⟨i, j, -, hl, hcd⟩ | ⟨i, j, -, hl, hcd⟩
    · exact hrel _ _ i j hl hcd
    · exact (hrel _ _ i j hl hcd).symm

lemma liftR (w w' : EdgeWord) (hn : 0 < w.length) (hm : 0 < w'.length)
    (hP : (w ++ w').cornerGluing.Reachable ⟨0, by simp only [List.length_append]; omega⟩ ⟨w.length, by simp only [List.length_append]; omega⟩)
    (u v : Fin w'.length) (h : w'.cornerGluing.Reachable u v) :
    (w ++ w').cornerGluing.Reachable ⟨w.length + u.val, by simp only [List.length_append]; omega⟩
      ⟨w.length + v.val, by simp only [List.length_append]; omega⟩ := by
  have hrep : ∀ (x y : Fin (w ++ w').length) (u : Fin w'.length),
      (x.val = w.length + u.val ∨ (x.val = 0 ∧ u.val = 0)) →
      (y.val = w.length + u.val ∨ (y.val = 0 ∧ u.val = 0)) →
      (w ++ w').cornerGluing.Reachable x y := by
    rintro ⟨x, hxN⟩ ⟨y, hyN⟩ u hx hy
    simp only at hx hy
    rcases hx with hx | ⟨hx, hu⟩ <;> rcases hy with hy | ⟨hy, hu'⟩
    · have hxy : x = y := hx.trans hy.symm
      subst hxy; rfl
    · have hxn : x = w.length := by omega
      subst hxn hy; exact hP.symm
    · have hyn : y = w.length := by omega
      subst hyn hx; exact hP
    · have hxy : x = y := hx.trans hy.symm
      subst hxy; rfl
  have hrel : ∀ (a b : Fin w'.length) (i j : Fin w'.length), (w'.get i).1 = (w'.get j).1 →
      ((a = w'.startCorner i ∧ b = w'.startCorner j) ∨
        (a = w'.endCorner i ∧ b = w'.endCorner j)) →
      (w ++ w').cornerGluing.Reachable ⟨w.length + a.val, by simp only [List.length_append]; omega⟩
        ⟨w.length + b.val, by simp only [List.length_append]; omega⟩ := by
    intro a b i j hl hab
    obtain ⟨i, hi⟩ := i
    obtain ⟨j, hj⟩ := j
    have hW : ((w ++ w').get ⟨w.length + i, by simp only [List.length_append]; omega⟩).1 =
        ((w ++ w').get ⟨w.length + j, by simp only [List.length_append]; omega⟩).1 := by
      simpa [List.getElem_append_right] using hl
    rcases hab with ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩
    · exact (hrep _ _ _ (Or.inl rfl) (startR w w' i hi)).trans
        ((reach_start _ _ _ hW).trans (hrep _ _ _ (startR w w' j hj) (Or.inl rfl)))
    · exact (hrep _ _ _ (Or.inl rfl) (endR w w' i hi)).trans
        ((reach_end _ _ _ hW).trans (hrep _ _ _ (endR w w' j hj) (Or.inl rfl)))
  obtain ⟨p⟩ := h
  induction p with
  | nil => rfl
  | cons hadj _ ih =>
    refine SimpleGraph.Reachable.trans ?_ ih
    simp only [cornerGluing, SimpleGraph.fromRel_adj] at hadj
    rcases hadj.2 with ⟨i, j, -, hl, hcd⟩ | ⟨i, j, -, hl, hcd⟩
    · exact hrel _ _ i j hl hcd
    · exact (hrel _ _ i j hl hcd).symm


lemma psi_inl (w w' : EdgeWord) (hn : 0 < w.length) (hm : 0 < w'.length)
    (hP : (w ++ w').cornerGluing.Reachable ⟨0, by simp only [List.length_append]; omega⟩
      ⟨w.length, by simp only [List.length_append]; omega⟩)
    (c : Fin (w ++ w').length) (x : w.cornerGluing.ConnectedComponent)
    (h : psi w w' hn hm c = Sum.inl x) :
    ∃ u : Fin w.length, x = w.cornerGluing.connectedComponentMk u ∧
      (w ++ w').cornerGluing.Reachable c ⟨u.val, by simp only [List.length_append]; omega⟩ := by
  by_cases hc : c.val < w.length
  · simp only [psi, hc, ↓reduceDIte, Sum.inl.injEq] at h
    exact ⟨⟨c.val, hc⟩, h.symm, SimpleGraph.Reachable.refl _⟩
  · simp only [psi, hc, ↓reduceDIte] at h
    unfold psiR at h
    split_ifs at h with h0
    · simp only [Sum.inl.injEq] at h
      refine ⟨⟨0, hn⟩, h.symm, ?_⟩
      have r := liftR w w' hn hm hP _ _ (SimpleGraph.ConnectedComponent.exact h0)
      have e1 : (⟨w.length + (c.val - w.length),
          by have := c.2; simp only [List.length_append] at this ⊢; omega⟩ :
          Fin (w ++ w').length) = c := Fin.ext (by simp only; omega)
      rw [e1] at r
      exact r.trans hP.symm

lemma psi_inr (w w' : EdgeWord) (hn : 0 < w.length) (hm : 0 < w'.length)
    (c : Fin (w ++ w').length) (y : w'.cornerGluing.ConnectedComponent)
    (h : psi w w' hn hm c = Sum.inr y) :
    ∃ u : Fin w'.length, y = w'.cornerGluing.connectedComponentMk u ∧
      w'.cornerGluing.connectedComponentMk u ≠ w'.cornerGluing.connectedComponentMk ⟨0, hm⟩ ∧
      (w ++ w').cornerGluing.Reachable c
        ⟨w.length + u.val, by simp only [List.length_append]; omega⟩ := by
  by_cases hc : c.val < w.length
  · simp [psi, hc] at h
  · simp only [psi, hc, ↓reduceDIte] at h
    unfold psiR at h
    split_ifs at h with h0
    simp only [Sum.inr.injEq] at h
    refine ⟨_, h.symm, h0, ?_⟩
    have e1 : (⟨w.length + (c.val - w.length),
        by have := c.2; simp only [List.length_append] at this ⊢; omega⟩ :
        Fin (w ++ w').length) = c := Fin.ext (by simp only; omega)
    rw [e1]

lemma psi_inj (w w' : EdgeWord) (hn : 0 < w.length) (hm : 0 < w'.length)
    (hP : (w ++ w').cornerGluing.Reachable ⟨0, by simp only [List.length_append]; omega⟩
      ⟨w.length, by simp only [List.length_append]; omega⟩)
    (c d : Fin (w ++ w').length) (h : psi w w' hn hm c = psi w w' hn hm d) :
    (w ++ w').cornerGluing.Reachable c d := by
  rcases hz : psi w w' hn hm c with x | y
  · obtain ⟨u, hu, ru⟩ := psi_inl w w' hn hm hP c x hz
    obtain ⟨v, hv, rv⟩ := psi_inl w w' hn hm hP d x (h ▸ hz)
    have huv := SimpleGraph.ConnectedComponent.exact (hu.symm.trans hv)
    exact ru.trans ((liftL w w' hn hm hP u v huv).trans rv.symm)
  · obtain ⟨u, hu, -, ru⟩ := psi_inr w w' hn hm c y hz
    obtain ⟨v, hv, -, rv⟩ := psi_inr w w' hn hm d y (h ▸ hz)
    have huv := SimpleGraph.ConnectedComponent.exact (hu.symm.trans hv)
    exact ru.trans ((liftR w w' hn hm hP u v huv).trans rv.symm)

lemma vertices_append (w w' : EdgeWord) (hw : w.IsClosedDiagram) (hn : 0 < w.length)
    (hm : 0 < w'.length) (hdisj : ∀ p ∈ w, ∀ q ∈ w', p.1 ≠ q.1) :
    (w ++ w').vertices + 1 = w.vertices + w'.vertices := by
  classical
  have hP := reach_zero_n w w' hw hn hm
  let Ψ : (w ++ w').cornerGluing.ConnectedComponent →
      w.cornerGluing.ConnectedComponent ⊕ w'.cornerGluing.ConnectedComponent :=
    SimpleGraph.ConnectedComponent.lift (psi w w' hn hm)
      (fun v u p _ => psi_reach w w' hn hm hdisj v u ⟨p⟩)
  have hΨ : ∀ c, Ψ ((w ++ w').cornerGluing.connectedComponentMk c) = psi w w' hn hm c :=
    fun c => rfl
  have hinj : Function.Injective Ψ := by
    intro a b hab
    induction a using SimpleGraph.ConnectedComponent.ind with
    | h a =>
    induction b using SimpleGraph.ConnectedComponent.ind with
    | h b =>
    rw [hΨ, hΨ] at hab
    exact SimpleGraph.ConnectedComponent.sound (psi_inj w w' hn hm hP a b hab)
  have himg : Finset.univ.image Ψ =
      Finset.univ.erase (Sum.inr (w'.cornerGluing.connectedComponentMk ⟨0, hm⟩)) := by
    ext z
    simp only [Finset.mem_image, Finset.mem_univ, true_and, Finset.mem_erase, and_true]
    constructor
    · rintro ⟨a, rfl⟩
      induction a using SimpleGraph.ConnectedComponent.ind with
      | h a =>
      intro hz
      rw [hΨ] at hz
      obtain ⟨u, h1, h2, -⟩ := psi_inr w w' hn hm a _ hz
      exact h2 h1.symm
    · intro hz
      rcases z with x | y
      · induction x using SimpleGraph.ConnectedComponent.ind with
        | h u =>
        exact ⟨(w ++ w').cornerGluing.connectedComponentMk
          ⟨u.val, by simp only [List.length_append]; omega⟩,
          by rw [hΨ]; exact psi_L w w' hn hm _ u (Or.inl rfl)⟩
      · induction y using SimpleGraph.ConnectedComponent.ind with
        | h u =>
        refine ⟨(w ++ w').cornerGluing.connectedComponentMk
          ⟨w.length + u.val, by simp only [List.length_append]; omega⟩, ?_⟩
        rw [hΨ, psi_R w w' hn hm _ u (Or.inl rfl)]
        unfold psiR
        split_ifs with h0
        · exact absurd (by rw [h0]) hz
        · rfl
  have hcard := Finset.card_image_of_injective Finset.univ hinj
  rw [himg, Finset.card_erase_of_mem (Finset.mem_univ _), Finset.card_univ, Finset.card_univ,
    Fintype.card_sum] at hcard
  have h1 : 0 < Fintype.card w.cornerGluing.ConnectedComponent := by
    have : Nonempty (Fin w.length) := ⟨⟨0, hn⟩⟩
    exact Fintype.card_pos
  unfold vertices
  omega

lemma edges_append (w w' : EdgeWord) (hdisj : ∀ p ∈ w, ∀ q ∈ w', p.1 ≠ q.1) :
    (w ++ w').edges = w.edges + w'.edges := by
  classical
  unfold edges
  rw [List.map_append, List.toFinset_append, Finset.card_union_of_disjoint]
  rw [Finset.disjoint_left]
  intro a ha hb
  simp only [List.mem_toFinset, List.mem_map] at ha hb
  obtain ⟨p, hp, rfl⟩ := ha
  obtain ⟨q, hq, hq'⟩ := hb
  exact hdisj p hp q hq hq'.symm

end SurfHelp

open SurfHelp

/-- The list's counts (card, Step 5). The sphere with `g` handles is a closed, two-sided
diagram with `V - E + F = 2 - 2g`; the sphere with `k ≥ 1` crosscaps is a closed, one-sided
diagram with `V - E + F = 2 - k`. -/
theorem standard_forms_euler_characteristic_and_sides :
    (∀ g : ℕ, (handleForm g).IsClosedDiagram ∧ (handleForm g).IsTwoSided ∧
      (handleForm g).euler = 2 - 2 * (g : ℤ)) ∧
    (∀ k : ℕ, 1 ≤ k → (crosscapForm k).IsClosedDiagram ∧ ¬ (crosscapForm k).IsTwoSided ∧
      (crosscapForm k).euler = 2 - (k : ℤ)) := by
  refine ⟨fun g => ?_, fun k hk => ?_⟩
  · rcases g with _ | g
    · refine ⟨by decide, by decide, ?_⟩
      simp only [CharP.cast_eq_zero, mul_zero, sub_zero]
      decide
    · refine ⟨?_, ?_, ?_⟩
      · intro p hp
        rw [handle_eq] at hp ⊢
        have := mem_H _ p hp
        rw [countP_H]; simp [this]
      · intro p hp
        rw [handle_eq] at hp ⊢
        have := mem_H _ p hp
        simp [count_H, this]
      · unfold euler
        rw [handle_vertices, handle_eq, edges_H]
        push_cast; ring
  · refine ⟨?_, ?_, ?_⟩
    · intro p hp
      rw [crosscap_eq] at hp ⊢
      have := mem_C _ p hp
      rw [countP_C]; simp [this]
    · intro h
      have hm : ((0 : ℕ), true) ∈ crosscapForm k := by
        rw [crosscap_eq]
        simp only [List.mem_flatMap, List.mem_range, blkC, List.mem_cons]
        exact ⟨0, by omega, Or.inl rfl⟩
      have := (h _ hm).1
      rw [crosscap_eq, count_C] at this
      have hk0 : 0 < k := hk
      simp [hk0] at this
    · unfold euler
      rw [crosscap_vertices k hk, crosscap_eq, edges_C]
      push_cast; ring

/-- The list has no repeats (card, Step 5). Two handle forms with the same `V - E + F` have
the same number of handles, two crosscap forms with the same `V - E + F` have the same number
of crosscaps, and a handle form and a crosscap form always differ in sidedness. -/
theorem standard_list_has_no_repeats (g g' k k' : ℕ) (hk : 1 ≤ k) (hk' : 1 ≤ k') :
    ((handleForm g).euler = (handleForm g').euler → g = g') ∧
    ((crosscapForm k).euler = (crosscapForm k').euler → k = k') ∧
    ¬ ((handleForm g).IsTwoSided ↔ (crosscapForm k).IsTwoSided) := by
  obtain ⟨hH, hC⟩ := standard_forms_euler_characteristic_and_sides
  refine ⟨fun h => ?_, fun h => ?_, fun h => ?_⟩
  · rw [(hH g).2.2, (hH g').2.2] at h; omega
  · rw [(hC k hk).2.2, (hC k' hk').2.2] at h; omega
  · exact (hC k hk).2.1 (h.1 (hH g).2.1)

/-- Connected sum on gluing diagrams (card, Step 3). Write two closed edge words with no
letter in common one after the other; the result's `V - E + F` is the two counts added,
minus 2: `χ(M # N) = χ(M) + χ(N) - 2`. -/
theorem euler_connected_sum (w w' : EdgeWord) (hw : w.IsClosedDiagram)
    (hw' : w'.IsClosedDiagram) (hne : w ≠ []) (hne' : w' ≠ [])
    (hdisj : ∀ p ∈ w, ∀ q ∈ w', p.1 ≠ q.1) :
    (w ++ w').euler = w.euler + w'.euler - 2 := by
  have hn : 0 < w.length := List.length_pos_iff.mpr hne
  have hm : 0 < w'.length := List.length_pos_iff.mpr hne'
  have hV := vertices_append w w' hw hn hm hdisj
  have hE := edges_append w w' hdisj
  have hV' : ((w ++ w').vertices : ℤ) + 1 = w.vertices + w'.vertices := by exact_mod_cast hV
  unfold euler
  rw [hE]
  push_cast
  linarith

-- The card's worked numbers. Letters a, b, c, d are 0, 1, 2, 3.
-- Inner tube, a b a⁻¹ b⁻¹: χ = 1 - 2 + 1 = 0, two-sided, genus 1.
example : euler [(0, true), (1, true), (0, false), (1, false)] = 0 ∧
    IsTwoSided [(0, true), (1, true), (0, false), (1, false)] := by decide
-- Klein bottle, a b a⁻¹ b: χ = 0, one-sided.
example : euler [(0, true), (1, true), (0, false), (1, true)] = 0 ∧
    ¬ IsTwoSided [(0, true), (1, true), (0, false), (1, true)] := by decide
-- Sphere, a a⁻¹ b b⁻¹: corners in 3 groups, χ = 3 - 2 + 1 = 2, two-sided.
example : vertices [(0, true), (0, false), (1, true), (1, false)] = 3 ∧
    euler [(0, true), (0, false), (1, true), (1, false)] = 2 := by decide
-- Torus # torus, a b a⁻¹ b⁻¹ c d c⁻¹ d⁻¹: χ = 1 - 4 + 1 = -2, genus 2.
example : euler [(0, true), (1, true), (0, false), (1, false),
    (2, true), (3, true), (2, false), (3, false)] = -2 := by decide
-- Torus # projective plane, a b a⁻¹ b⁻¹ c c: χ = 1 - 3 + 1 = -1, one-sided.
example : euler [(0, true), (1, true), (0, false), (1, false), (2, true), (2, true)] = -1 ∧
    ¬ IsTwoSided [(0, true), (1, true), (0, false), (1, false), (2, true), (2, true)] := by
  decide
-- Three crosscaps, a a b b c c: χ = -1 (Dyck's rule: the same count as the line above).
example : euler (crosscapForm 3) = -1 := by decide
-- Two crosscaps, a a b b: χ = 0, one-sided, like the Klein bottle.
example : euler (crosscapForm 2) = 0 ∧ ¬ IsTwoSided (crosscapForm 2) := by decide
-- Mistake 2: the inner tube with every arrow dropped is a b a b, the projective plane.
example : euler [(0, true), (1, true), (0, true), (1, true)] = 1 ∧
    ¬ IsTwoSided [(0, true), (1, true), (0, true), (1, true)] := by decide
-- The connected sum count: 0 + 0 - 2 = -2 and 0 + 1 - 2 = -1.
example : (0 : ℤ) + 0 - 2 = -2 ∧ (0 : ℤ) + 1 - 2 = -1 := by decide
-- The geodesic dome: 42 - 120 + 80 = 2, a sphere, genus 0.
example : (42 : ℤ) - 120 + 80 = 2 := by decide
-- Mistake 1: the inner tube's 4 corners left unglued give 4 - 2 + 1 = 3, above the maximum 2.
example : (4 : ℤ) - 2 + 1 = 3 := by decide
-- Read backwards: χ = -2 and two-sided gives g = (2 - χ)/2 = 2; χ = -1 one-sided gives k = 3.
example : (2 - (-2 : ℤ)) / 2 = 2 ∧ 2 - (-1 : ℤ) = 3 := by decide

#print axioms standard_forms_euler_characteristic_and_sides
#print axioms standard_list_has_no_repeats
#print axioms euler_connected_sum
#print axioms flatMap_length
#print axioms flatMap_getElem
#print axioms blkH
#print axioms blkC
#print axioms handle_eq
#print axioms crosscap_eq
#print axioms countP_H
#print axioms count_H
#print axioms countP_C
#print axioms mem_H
#print axioms mem_C
#print axioms edges_H
#print axioms edges_C
#print axioms reach_start
#print axioms reach_end
#print axioms start_val
#print axioms end_val
#print axioms vertices_one
#print axioms R
#print axioms R_symm
#print axioms R_trans
#print axioms R_start
#print axioms R_end
#print axioms handle_len
#print axioms crosscap_len
#print axioms handle_get
#print axioms crosscap_get
#print axioms handle_step
#print axioms crosscap_step
#print axioms R_chain
#print axioms handle_vertices
#print axioms crosscap_vertices
#print axioms count_C
#print axioms countP_eq_card
#print axioms startL
#print axioms endL
#print axioms startR
#print axioms endR
#print axioms reach_zero_n
#print axioms psiR
#print axioms psi
#print axioms psiR_zero
#print axioms psi_L
#print axioms psi_R
#print axioms psiR_reach
#print axioms side_eq
#print axioms side_eq'
#print axioms rel_psi
#print axioms psi_reach
#print axioms liftL
#print axioms liftR
#print axioms psi_inl
#print axioms psi_inr
#print axioms psi_inj
#print axioms vertices_append
#print axioms edges_append
