-- Communities: for every finite simple graph and every split of its nodes into groups, joining two groups changes the modularity by the share of lines between them minus d_a d_b / 2m^2, the pair form of modularity equals the group form, one big group scores 0, and the card's league numbers check out.
import Mathlib.Combinatorics.SimpleGraph.AdjMatrix
import Mathlib.Combinatorics.SimpleGraph.DegreeSum
import Mathlib.Combinatorics.Enumerative.Bell
import Mathlib.Data.Rat.Defs
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Ring

namespace CommunityDetection

open SimpleGraph Finset

variable {V ι : Type*} [Fintype V] [DecidableEq V] [DecidableEq ι]

/-- Modularity `Q` of the split `c` (node `i` goes to group `c i`), by the card's pair form:
`Q = (1 / 2m) · Σ_{i,j} [A_ij - k_i k_j / 2m] · δ(c_i, c_j)`, where `A` is the adjacency
matrix, `k_i` the degree of `i`, and `m` the number of lines. -/
def modularity (G : SimpleGraph V) [DecidableRel G.Adj] (c : V → ι) : ℚ :=
  let m : ℚ := G.edgeFinset.card
  (1 / (2 * m)) * ∑ i, ∑ j,
    if c i = c j then G.adjMatrix ℚ i j - (G.degree i : ℚ) * G.degree j / (2 * m) else 0

/-- `L_g`: the lines with both ends in group `g`. -/
def insideLines (G : SimpleGraph V) [DecidableRel G.Adj] (c : V → ι) (g : ι) : ℕ :=
  (G.edgeFinset.filter (fun e => e.map c = s(g, g))).card

/-- `d_g`: the total degree of the nodes in group `g`. -/
def groupDegree (G : SimpleGraph V) [DecidableRel G.Adj] (c : V → ι) (g : ι) : ℕ :=
  ∑ v ∈ univ.filter (fun v => c v = g), G.degree v

/-- `l_ab`: the lines with one end in group `a` and the other in group `b`. -/
def linesBetween (G : SimpleGraph V) [DecidableRel G.Adj] (c : V → ι) (a b : ι) : ℕ :=
  (G.edgeFinset.filter (fun e => e.map c = s(a, b))).card

/-- The split after joining group `b` into group `a`: every node of `b` moves to `a`. -/
def mergeGroups (c : V → ι) (a b : ι) : V → ι :=
  fun v => if c v = b then a else c v

/-- Summing over ordered pairs of adjacent nodes counts each line twice. -/
theorem sum_adj_sym2 (G : SimpleGraph V) [DecidableRel G.Adj] (f : Sym2 V → ℚ) :
    ∑ i, ∑ j, (if G.Adj i j then f s(i, j) else 0) = 2 * ∑ e ∈ G.edgeFinset, f e := by
  have h1 : ∑ i, ∑ j, (if G.Adj i j then f s(i, j) else 0) = ∑ d : G.Dart, f d.edge := by
    rw [← Finset.sum_product', ← Finset.sum_filter]
    refine Finset.sum_bij' (fun p hp => ⟨p, (mem_filter.1 hp).2⟩) (fun d _ => d.toProd)
      ?_ ?_ ?_ ?_ ?_ <;> simp
  rw [h1, ← Finset.sum_fiberwise_of_maps_to (g := Dart.edge) (t := G.edgeFinset)
    (fun d _ => by simp), Finset.mul_sum]
  refine Finset.sum_congr rfl fun e he => ?_
  rw [Finset.sum_congr rfl (g := fun _ => f e) (fun d hd => by rw [(mem_filter.1 hd).2]),
    sum_const, nsmul_eq_mul, G.dart_edge_fiber_card e (by simpa using he)]
  norm_num

/-- The ordered pairs of adjacent nodes whose groups are `{a, b}` number `2 l_ab`. -/
theorem sum_adj_pair_groups (G : SimpleGraph V) [DecidableRel G.Adj] (c : V → ι) (a b : ι) :
    ∑ i, ∑ j, (if s(c i, c j) = s(a, b) then (if G.Adj i j then (1 : ℚ) else 0) else 0) =
      2 * (linesBetween G c a b : ℚ) := by
  have := sum_adj_sym2 G (fun e => if e.map c = s(a, b) then (1 : ℚ) else 0)
  simp only [Sym2.map_mk] at this
  refine Eq.trans ?_ (this.trans ?_)
  · refine Finset.sum_congr rfl fun i _ => Finset.sum_congr rfl fun j _ => ?_
    split_ifs <;> simp_all
  rw [linesBetween, Finset.sum_ite, sum_const_zero, add_zero, sum_const, nsmul_eq_mul,
    mul_one]

omit [DecidableEq V] in
/-- The degree products over ordered pairs from groups `a` and `b` add up to `d_a d_b`. -/
theorem sum_deg_pair_groups (G : SimpleGraph V) [DecidableRel G.Adj] (c : V → ι) (a b : ι) :
    ∑ i, ∑ j, (if c i = a ∧ c j = b then (G.degree i : ℚ) * G.degree j else 0) =
      (groupDegree G c a : ℚ) * groupDegree G c b := by
  simp only [groupDegree, Nat.cast_sum, Finset.sum_filter, Finset.sum_mul_sum]
  refine Finset.sum_congr rfl fun i _ => Finset.sum_congr rfl fun j _ => ?_
  split_ifs <;> simp_all

/-- The card's merge formula. In any finite network of plain lines (a simple graph with `m`
lines), for any split into groups and any two different groups `a` and `b`, joining them changes
the modularity by `ΔQ_ab = l_ab / m - d_a d_b / (2 m^2)`: the share of lines running between them,
minus what chance would run between them anyway. -/
theorem merge_gain_eq (G : SimpleGraph V) [DecidableRel G.Adj] (c : V → ι) (a b : ι)
    (hab : a ≠ b) :
    modularity G (mergeGroups c a b) - modularity G c =
      (linesBetween G c a b : ℚ) / G.edgeFinset.card -
        (groupDegree G c a : ℚ) * groupDegree G c b / (2 * (G.edgeFinset.card : ℚ) ^ 2) := by
  simp only [modularity, adjMatrix_apply]
  generalize (G.edgeFinset.card : ℚ) = M
  have key : ∀ i j, (if mergeGroups c a b i = mergeGroups c a b j then
      (if G.Adj i j then (1 : ℚ) else 0) - (G.degree i : ℚ) * G.degree j / (2 * M) else 0) =
      (if c i = c j then (if G.Adj i j then (1 : ℚ) else 0) - (G.degree i : ℚ) * G.degree j / (2 * M) else 0) +
      ((if s(c i, c j) = s(a, b) then (if G.Adj i j then (1 : ℚ) else 0) else 0) -
        (1 / (2 * M)) * ((if c i = a ∧ c j = b then (G.degree i : ℚ) * G.degree j else 0) +
          (if c i = b ∧ c j = a then (G.degree i : ℚ) * G.degree j else 0))) := by
    intro i j
    unfold mergeGroups
    by_cases hi : c i = b <;> by_cases hj : c j = b <;> by_cases hi' : c i = a <;>
      by_cases hj' : c j = a <;> simp_all [eq_comm] <;> ring
  simp_rw [key, Finset.sum_add_distrib, Finset.sum_sub_distrib, ← Finset.mul_sum,
    Finset.sum_add_distrib, sum_adj_pair_groups, sum_deg_pair_groups]
  ring

/-- The two forms of modularity agree: the pair sum equals the sum over groups of
`L_c / m - (d_c / 2m)^2`, the share of lines inside each group minus the share chance would put
there. -/
theorem modularity_eq_sum_over_groups (G : SimpleGraph V) [DecidableRel G.Adj] (c : V → ι) :
    modularity G c =
      ∑ g ∈ univ.image c,
        ((insideLines G c g : ℚ) / G.edgeFinset.card -
          ((groupDegree G c g : ℚ) / (2 * G.edgeFinset.card)) ^ 2) := by
  simp only [modularity, insideLines, adjMatrix_apply]
  generalize (G.edgeFinset.card : ℚ) = M
  have key : ∀ i j, (if c i = c j then
      (if G.Adj i j then (1 : ℚ) else 0) - (G.degree i : ℚ) * G.degree j / (2 * M) else 0) =
      ∑ g ∈ univ.image c, ((if s(c i, c j) = s(g, g) then (if G.Adj i j then (1 : ℚ) else 0) else 0) -
        (1 / (2 * M)) * (if c i = g ∧ c j = g then (G.degree i : ℚ) * G.degree j else 0)) := by
    intro i j
    rw [Finset.sum_eq_single (c i)]
    · by_cases h : c i = c j <;> simp [h, eq_comm]; ring
    · intro g _ hg
      have : ¬ (c i = g) := fun h => hg h.symm
      simp [this]
    · intro h
      exact absurd (mem_image_of_mem c (mem_univ i)) h
  simp_rw [key]
  rw [Finset.sum_comm]
  simp_rw [Finset.sum_comm (s := univ) (t := univ.image c)]
  rw [Finset.mul_sum]
  refine Finset.sum_congr rfl fun g _ => ?_
  rw [Finset.sum_comm]
  simp_rw [Finset.sum_sub_distrib, ← Finset.mul_sum]
  rw [sum_adj_pair_groups, sum_deg_pair_groups, linesBetween]
  ring

/-- Step 0 of the card: put every node in one big group and the score is 0. Every line is
inside, but chance would put every line inside too. -/
theorem modularity_one_group_eq_zero (G : SimpleGraph V) [DecidableRel G.Adj] (g : ι) :
    modularity G (fun _ : V => g) = 0 := by
  have h := sum_adj_sym2 G (fun _ => 1)
  simp only [sum_const, nsmul_eq_mul, mul_one] at h
  have hd : ∑ i, (G.degree i : ℚ) = 2 * G.edgeFinset.card := by
    rw [← Nat.cast_sum, G.sum_degrees_eq_twice_card_edges]
    push_cast; ring
  simp only [modularity, adjMatrix_apply, ite_true]
  generalize (G.edgeFinset.card : ℚ) = M at h hd
  have hr : ∀ i j, (if G.Adj i j then (1 : ℚ) else 0) - (G.degree i : ℚ) * G.degree j / (2 * M) =
      (if G.Adj i j then (1 : ℚ) else 0) - (1 / (2 * M)) * ((G.degree i : ℚ) * G.degree j) := by
    intro i j; ring
  simp_rw [hr, Finset.sum_sub_distrib, ← Finset.mul_sum]
  simp only [h, hd, ← Finset.sum_mul]
  by_cases hm : M = 0
  · simp [hm]
  · field_simp
    ring

/-! The card's league: clubs A1 to A6 are `0` to `5`, B1 to B6 are `6` to `11`, C1 to C6 are
`12` to `17`, D1 to D6 are `18` to `23`. Club `i` is in division `i / 6`. -/

/-- The 16 cup ties: A6-D2 C3-D1 A4-B4 B1-C2 A3-D3 B3-C2 A2-C6 C5-D3 B5-D3 A1-C5 C1-D5 C6-D6
B6-C6 B3-C3 B1-D5 A6-B3. -/
def cupTies : List (Fin 24 × Fin 24) :=
  [(5, 19), (14, 18), (3, 9), (6, 13), (2, 20), (8, 13), (1, 17), (16, 20), (10, 20), (0, 16),
   (12, 22), (17, 23), (11, 17), (8, 14), (6, 22), (5, 8)]

/-- The league: every pair of clubs in one division played, plus the cup ties. -/
def league : SimpleGraph (Fin 24) where
  Adj x y := x ≠ y ∧ (x.val / 6 = y.val / 6 ∨ (x, y) ∈ cupTies ∨ (y, x) ∈ cupTies)
  symm := ⟨fun _ _ h => ⟨h.1.symm, h.2.elim (fun e => Or.inl e.symm)
    (fun h' => Or.inr h'.symm)⟩⟩
  loopless := ⟨fun _ h => h.1 rfl⟩

instance : DecidableRel league.Adj := fun _ _ => inferInstanceAs (Decidable (_ ∧ _))

/-- The divisions as a split: club `i` goes to group `i / 6`. -/
def division (i : Fin 24) : ℕ := i.val / 6

-- 15 fixtures per division, 76 fixtures in all, and the total degree 152 is 2m.
example : Nat.choose 6 2 = 15 ∧ 4 * 15 + 16 = 76 := by decide
example : league.edgeFinset.card = 76 := by decide
example : (List.range 4).map (insideLines league division) = [15, 15, 15, 15] := by decide
example : (List.range 4).map (groupDegree league division) = [36, 38, 40, 38] := by decide
example : 36 + 38 + 40 + 38 = 152 ∧ 152 = 2 * 76 := by norm_num
-- Q of the divisions: 60/76 - 5784/23104 = 1557/2888 (0.5391).
example : 36 ^ 2 + 38 ^ 2 + 40 ^ 2 + 38 ^ 2 = 5784 ∧ 152 ^ 2 = 23104 := by norm_num
example : (60 : ℚ) / 76 - 5784 / 23104 = 1557 / 2888 := by norm_num
-- Every club alone: Q = -Σ k_i^2 / 152^2 = -982/23104 (-0.0425).
example : ∑ i, league.degree i ^ 2 = 982 := by decide
-- The first join, A1 + A5: they met once, degrees 6 and 5, gain 1/76 - 30/(2·76^2) = 61/5776.
example : league.Adj 0 4 ∧ league.degree 0 = 6 ∧ league.degree 4 = 5 := by decide
example : (1 : ℚ) / 76 - 6 * 5 / (2 * 76 ^ 2) = 61 / 5776 := by norm_num
-- What breaks: the chance term k_i k_j / m instead of / 2m gives (2·76·60 - 5784)/(2·76^2) (0.2888).
example : ((2 * 76 * 60 - 5784 : ℚ)) / (2 * 76 ^ 2) = 417 / 1444 := by norm_num
-- The mini league of 9 clubs has 21147 splits into groups (the Bell number of 9).
example : Nat.bell 9 = 21147 := by
  norm_num [Nat.bell_succ', Finset.Nat.antidiagonal_succ, Nat.choose]
-- Resolution limit, ring of 30 five-club cliques (m = 330): in pairs beats each clique alone.
example : (30 : ℚ) * (10 / 330 - (22 / 660) ^ 2) < 15 * (21 / 330 - (44 / 660) ^ 2) := by norm_num
-- Ring of 20 (m = 220): now each clique alone wins.
example : (10 : ℚ) * (21 / 220 - (44 / 440) ^ 2) < 20 * (10 / 220 - (22 / 440) ^ 2) := by norm_num
-- A 6-cycle split into its two sides: no line inside, each side has degree 6, Q = -1/2.
example : (2 : ℚ) * (0 / 6 - (6 / 12) ^ 2) = -1 / 2 := by norm_num

#print axioms sum_adj_sym2
#print axioms sum_adj_pair_groups
#print axioms sum_deg_pair_groups
#print axioms merge_gain_eq
#print axioms modularity_eq_sum_over_groups
#print axioms modularity_one_group_eq_zero

end CommunityDetection
