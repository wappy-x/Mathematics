-- k-means: taking turns between nearest-centre labels and group means never raises the total squared distance and stops after finitely many passes, the mean is the one best centre for a group, one more centre can always lower the score, and the card's six-order example is checked.
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Data.Fintype.Pi
import Mathlib.Data.Fintype.Powerset
import Mathlib.Tactic.NormNum

open Finset

namespace KMeansAndClustering

/-- The score `J`: the squared distance from every order `x i` to the centre `c (g i)` of its own
group, added up over all `n` orders. Each order is a list of `d` numbers. -/
noncomputable def score {n d k : ℕ} (x : Fin n → EuclideanSpace ℝ (Fin d)) (g : Fin n → Fin k)
    (c : Fin k → EuclideanSpace ℝ (Fin d)) : ℝ :=
  ∑ i, ‖x i - c (g i)‖ ^ 2

/-- One **pass** of k-means, from labels `g` and centres `c` to labels `g'` and centres `c'`.
Assign: every order gets a label whose centre is nearest (smallest squared distance), and an
order keeps its current label whenever that centre is among the nearest (the tie rule).
Update: every group that holds at least one order moves its centre to the mean of its orders;
an empty group keeps its old centre, as the card's code does. -/
def IsPass {n d k : ℕ} (x : Fin n → EuclideanSpace ℝ (Fin d)) (g : Fin n → Fin k)
    (c : Fin k → EuclideanSpace ℝ (Fin d)) (g' : Fin n → Fin k)
    (c' : Fin k → EuclideanSpace ℝ (Fin d)) : Prop :=
  (∀ i, (∀ j, ‖x i - c (g' i)‖ ^ 2 ≤ ‖x i - c j‖ ^ 2) ∧
    ((∀ j, ‖x i - c (g i)‖ ^ 2 ≤ ‖x i - c j‖ ^ 2) → g' i = g i)) ∧
  (∀ j, c' j = if (univ.filter (fun i => g' i = j)).card = 0 then c j
    else ((univ.filter (fun i => g' i = j)).card : ℝ)⁻¹ •
      ∑ i ∈ univ.filter (fun i => g' i = j), x i)

/-- Helper: the shift identity for a nonempty group. -/
theorem shift_identity_aux {ι : Type*} {d : ℕ} (s : Finset ι) (hs : s.Nonempty)
    (x : ι → EuclideanSpace ℝ (Fin d)) (c : EuclideanSpace ℝ (Fin d)) :
    ∑ i ∈ s, ‖x i - c‖ ^ 2 = ∑ i ∈ s, ‖x i - (s.card : ℝ)⁻¹ • ∑ i ∈ s, x i‖ ^ 2 +
      s.card * ‖(s.card : ℝ)⁻¹ • ∑ i ∈ s, x i - c‖ ^ 2 := by
  set xbar := (s.card : ℝ)⁻¹ • ∑ i ∈ s, x i with hxbar
  have hcard : (s.card : ℝ) ≠ 0 := by exact_mod_cast hs.card_pos.ne'
  have hsum : ∑ i ∈ s, (x i - xbar) = 0 := by
    rw [Finset.sum_sub_distrib, Finset.sum_const, hxbar, ← Nat.cast_smul_eq_nsmul ℝ, smul_smul,
      mul_inv_cancel₀ hcard, one_smul, sub_self]
  have h1 : ∀ i ∈ s, ‖x i - c‖ ^ 2 =
      ‖x i - xbar‖ ^ 2 + 2 * inner ℝ (x i - xbar) (xbar - c) + ‖xbar - c‖ ^ 2 := by
    intro i _
    rw [← norm_add_sq_real]
    congr 2
    abel
  rw [Finset.sum_congr rfl h1, Finset.sum_add_distrib, Finset.sum_add_distrib,
    ← Finset.mul_sum, ← sum_inner, hsum, inner_zero_left, mul_zero,
    add_zero, Finset.sum_const, nsmul_eq_mul]

/-- Helper: the total squared distance of a group to its mean is at most that to any centre. -/
theorem mean_le_aux {ι : Type*} {d : ℕ} (s : Finset ι) (hs : s.Nonempty)
    (x : ι → EuclideanSpace ℝ (Fin d)) (c : EuclideanSpace ℝ (Fin d)) :
    ∑ i ∈ s, ‖x i - (s.card : ℝ)⁻¹ • ∑ i ∈ s, x i‖ ^ 2 ≤ ∑ i ∈ s, ‖x i - c‖ ^ 2 := by
  rw [shift_identity_aux s hs x c]
  have : (0 : ℝ) ≤ s.card * ‖(s.card : ℝ)⁻¹ • ∑ i ∈ s, x i - c‖ ^ 2 := by positivity
  linarith

#print axioms shift_identity_aux
#print axioms mean_le_aux

/-- **Taking turns lowers the score and must stop** (Steps 1 to 3). Run k-means on `n` orders of
`d` numbers with `k` groups from any start: labels `g 0` and centres `c 0`, then pass after pass.
Then the score `J` never rises from one pass to the next; a pass that changes any label lowers
`J` strictly; and after finitely many passes nothing changes any more, neither labels nor
centres. -/
theorem kmeans_score_never_rises_and_stops {n d k : ℕ} (x : Fin n → EuclideanSpace ℝ (Fin d))
    (g : ℕ → Fin n → Fin k) (c : ℕ → Fin k → EuclideanSpace ℝ (Fin d))
    (hpass : ∀ t, IsPass x (g t) (c t) (g (t + 1)) (c (t + 1))) :
    (∀ t, score x (g (t + 1)) (c (t + 1)) ≤ score x (g t) (c t)) ∧
    (∀ t, g (t + 1) ≠ g t → score x (g (t + 1)) (c (t + 1)) < score x (g t) (c t)) ∧
    (∃ T, ∀ t, T ≤ t → g t = g T ∧ c t = c T) := by
  classical
  -- the mean centres of a labelling
  let m : (Fin n → Fin k) → Fin k → EuclideanSpace ℝ (Fin d) := fun h j =>
    ((univ.filter (fun i => h i = j)).card : ℝ)⁻¹ • ∑ i ∈ univ.filter (fun i => h i = j), x i
  let F : (Fin n → Fin k) → ℝ := fun h => score x h (m h)
  -- after a pass, the score is a function of the labels alone
  have hF : ∀ t, score x (g (t + 1)) (c (t + 1)) = F (g (t + 1)) := by
    intro t
    unfold F score
    refine Finset.sum_congr rfl fun i _ => ?_
    have hc := (hpass t).2 (g (t + 1) i)
    have hne : (univ.filter (fun i' => g (t + 1) i' = g (t + 1) i)).card ≠ 0 := by
      apply Finset.card_ne_zero.mpr
      exact ⟨i, by simp⟩
    rw [hc, if_neg hne]
  -- step (a)
  have hA : ∀ t, score x (g (t + 1)) (c (t + 1)) ≤ score x (g t) (c t) := by
    intro t
    have h1 : score x (g (t + 1)) (c (t + 1)) ≤ score x (g (t + 1)) (c t) := by
      unfold score
      rw [← Finset.sum_fiberwise univ (g (t + 1)) (fun i => ‖x i - c (t + 1) (g (t + 1) i)‖ ^ 2),
        ← Finset.sum_fiberwise univ (g (t + 1)) (fun i => ‖x i - c t (g (t + 1) i)‖ ^ 2)]
      refine Finset.sum_le_sum fun j _ => ?_
      have e1 : ∀ i ∈ univ.filter (fun i => g (t + 1) i = j),
          ‖x i - c (t + 1) (g (t + 1) i)‖ ^ 2 = ‖x i - c (t + 1) j‖ ^ 2 := by
        intro i hi
        rw [(Finset.mem_filter.mp hi).2]
      have e2 : ∀ i ∈ univ.filter (fun i => g (t + 1) i = j),
          ‖x i - c t (g (t + 1) i)‖ ^ 2 = ‖x i - c t j‖ ^ 2 := by
        intro i hi
        rw [(Finset.mem_filter.mp hi).2]
      rw [Finset.sum_congr rfl e1, Finset.sum_congr rfl e2, (hpass t).2 j]
      split_ifs with h0
      · exact le_refl _
      · exact mean_le_aux _ (Finset.card_ne_zero.mp h0) x (c t j)
    have h2 : score x (g (t + 1)) (c t) ≤ score x (g t) (c t) := by
      unfold score
      exact Finset.sum_le_sum fun i _ => ((hpass t).1 i).1 (g t i)
    exact h1.trans h2
  -- step (b)
  have hB : ∀ t, g (t + 1) ≠ g t → score x (g (t + 1)) (c (t + 1)) < score x (g t) (c t) := by
    intro t hne
    obtain ⟨i₀, hi₀⟩ := Function.ne_iff.mp hne
    have h1 : score x (g (t + 1)) (c (t + 1)) ≤ score x (g (t + 1)) (c t) := by
      unfold score
      rw [← Finset.sum_fiberwise univ (g (t + 1)) (fun i => ‖x i - c (t + 1) (g (t + 1) i)‖ ^ 2),
        ← Finset.sum_fiberwise univ (g (t + 1)) (fun i => ‖x i - c t (g (t + 1) i)‖ ^ 2)]
      refine Finset.sum_le_sum fun j _ => ?_
      have e1 : ∀ i ∈ univ.filter (fun i => g (t + 1) i = j),
          ‖x i - c (t + 1) (g (t + 1) i)‖ ^ 2 = ‖x i - c (t + 1) j‖ ^ 2 := by
        intro i hi
        rw [(Finset.mem_filter.mp hi).2]
      have e2 : ∀ i ∈ univ.filter (fun i => g (t + 1) i = j),
          ‖x i - c t (g (t + 1) i)‖ ^ 2 = ‖x i - c t j‖ ^ 2 := by
        intro i hi
        rw [(Finset.mem_filter.mp hi).2]
      rw [Finset.sum_congr rfl e1, Finset.sum_congr rfl e2, (hpass t).2 j]
      split_ifs with h0
      · exact le_refl _
      · exact mean_le_aux _ (Finset.card_ne_zero.mp h0) x (c t j)
    have h2 : score x (g (t + 1)) (c t) < score x (g t) (c t) := by
      unfold score
      refine Finset.sum_lt_sum (fun i _ => ((hpass t).1 i).1 (g t i)) ⟨i₀, mem_univ _, ?_⟩
      have hnot : ¬ ∀ j, ‖x i₀ - c t (g t i₀)‖ ^ 2 ≤ ‖x i₀ - c t j‖ ^ 2 :=
        fun h => hi₀ (((hpass t).1 i₀).2 h)
      push_neg at hnot
      obtain ⟨j, hj⟩ := hnot
      exact lt_of_le_of_lt (((hpass t).1 i₀).1 j) hj
    exact lt_of_le_of_lt h1 h2
  refine ⟨hA, hB, ?_⟩
  -- step (c)
  set s : ℕ → ℝ := fun t => score x (g t) (c t) with hs
  have hanti : Antitone s := antitone_nat_of_succ_le hA
  obtain ⟨h₀, hh₀, hmin⟩ := Set.exists_min_image (Set.range fun t => g (t + 1)) F
    (Set.toFinite _) (Set.range_nonempty _)
  obtain ⟨T0, rfl⟩ := hh₀
  have hconst : ∀ t, T0 + 1 ≤ t → s t = s (T0 + 1) := by
    intro t ht
    apply le_antisymm (hanti ht)
    obtain ⟨t', rfl⟩ : ∃ t', t = t' + 1 := ⟨t - 1, by omega⟩
    show score x (g (T0 + 1)) (c (T0 + 1)) ≤ score x (g (t' + 1)) (c (t' + 1))
    rw [hF, hF]
    exact hmin _ ⟨t', rfl⟩
  have hgstep : ∀ t, T0 + 1 ≤ t → g (t + 1) = g t := by
    intro t ht
    by_contra hne
    have := hB t hne
    have e1 := hconst t ht
    have e2 := hconst (t + 1) (by omega)
    simp only [hs] at e1 e2
    linarith
  have hg : ∀ t, T0 + 1 ≤ t → g t = g (T0 + 1) := by
    intro t ht
    induction t, ht using Nat.le_induction with
    | base => rfl
    | succ t ht ih => rw [hgstep t ht, ih]
  have hcstep : ∀ t, T0 + 1 ≤ t → c (t + 2) = c (t + 1) := by
    intro t ht
    funext j
    have hg2 : g (t + 2) = g (t + 1) := hgstep (t + 1) (by omega)
    rw [(hpass (t + 1)).2 j, (hpass t).2 j, hg2]
    split_ifs with h0
    · rfl
    · rfl
  have hc : ∀ t, T0 + 2 ≤ t → c t = c (T0 + 2) := by
    intro t ht
    induction t, ht using Nat.le_induction with
    | base => rfl
    | succ t ht ih =>
      obtain ⟨t', rfl⟩ : ∃ t', t = t' + 1 := ⟨t - 1, by omega⟩
      rw [hcstep t' (by omega), ih]
  refine ⟨T0 + 2, fun t ht => ⟨?_, hc t ht⟩⟩
  rw [hg t (by omega), hg (T0 + 2) (by omega)]

/-- **The mean is the one best centre** (Step 2, the shift identity). Take a group of `m ≥ 1`
orders with mean `x̄`. For any centre `c`, the total squared distance to `c` equals the total
squared distance to the mean plus `m` times the squared distance from the mean to `c`. So every
centre other than the mean scores strictly worse. -/
theorem mean_is_best_centre {ι : Type*} {d : ℕ} (s : Finset ι) (hs : s.Nonempty)
    (x : ι → EuclideanSpace ℝ (Fin d)) :
    let xbar := (s.card : ℝ)⁻¹ • ∑ i ∈ s, x i
    (∀ c, ∑ i ∈ s, ‖x i - c‖ ^ 2 = ∑ i ∈ s, ‖x i - xbar‖ ^ 2 + s.card * ‖xbar - c‖ ^ 2) ∧
    (∀ c, c ≠ xbar → ∑ i ∈ s, ‖x i - xbar‖ ^ 2 < ∑ i ∈ s, ‖x i - c‖ ^ 2) := by
  intro xbar
  have key : ∀ c, ∑ i ∈ s, ‖x i - c‖ ^ 2 = ∑ i ∈ s, ‖x i - xbar‖ ^ 2 + s.card * ‖xbar - c‖ ^ 2 :=
    fun c => shift_identity_aux s hs x c
  refine ⟨key, fun c hc => ?_⟩
  rw [key c]
  have hpos : (0 : ℝ) < s.card := by exact_mod_cast hs.card_pos
  have hn : 0 < ‖xbar - c‖ := norm_pos_iff.mpr (sub_ne_zero.mpr (Ne.symm hc))
  have : 0 < (s.card : ℝ) * ‖xbar - c‖ ^ 2 := by positivity
  linarith

/-- **One more centre never hurts** (Step 5). Any grouping of the orders into `k` groups can be
matched by a grouping into `k + 1` groups whose score is no higher, and strictly lower whenever
some order is not sitting on its own centre: put the new centre on top of that order. So the
lowest score always prefers the most groups allowed and cannot choose `k` by itself. -/
theorem more_centres_lower_score {n d k : ℕ} (x : Fin n → EuclideanSpace ℝ (Fin d))
    (g : Fin n → Fin k) (c : Fin k → EuclideanSpace ℝ (Fin d)) :
    ∃ (g' : Fin n → Fin (k + 1)) (c' : Fin (k + 1) → EuclideanSpace ℝ (Fin d)),
      score x g' c' ≤ score x g c ∧ (0 < score x g c → score x g' c' < score x g c) := by
  classical
  by_cases h : ∃ i₀, 0 < ‖x i₀ - c (g i₀)‖ ^ 2
  · obtain ⟨i₀, hi₀⟩ := h
    refine ⟨fun i => if i = i₀ then Fin.last k else (g i).castSucc,
      Fin.snoc (α := fun _ => EuclideanSpace ℝ (Fin d)) c (x i₀), ?_⟩
    have hlt : score x (fun i => if i = i₀ then Fin.last k else (g i).castSucc)
        (Fin.snoc (α := fun _ => EuclideanSpace ℝ (Fin d)) c (x i₀)) < score x g c := by
      unfold score
      refine Finset.sum_lt_sum (fun i _ => ?_) ⟨i₀, mem_univ _, ?_⟩
      · by_cases hi : i = i₀
        · subst hi
          simp only [if_true, Fin.snoc_last, sub_self, norm_zero]
          exact hi₀.le.trans' (by norm_num)
        · simp only [hi, if_false, Fin.snoc_castSucc]
          exact le_refl _
      · simpa using hi₀
    exact ⟨hlt.le, fun _ => hlt⟩
  · push_neg at h
    refine ⟨fun i => (g i).castSucc,
      Fin.snoc (α := fun _ => EuclideanSpace ℝ (Fin d)) c 0, ?_, ?_⟩
    · unfold score
      simp only [Fin.snoc_castSucc]
      exact le_refl _
    · intro hpos
      exfalso
      have : score x g c ≤ 0 := Finset.sum_nonpos fun i _ => h i
      linarith

/-! The card's six orders, by hand: A (0, 4), B (1, 3), C (0, 2), D (3, 0), E (4, 1), F (5, 0). -/

/-- The six orders, as (basket value, discount) pairs. -/
def six : Fin 6 → ℚ × ℚ := ![(0, 4), (1, 3), (0, 2), (3, 0), (4, 1), (5, 0)]

/-- Squared straight-line distance between two points of the plane. -/
def sq (p q : ℚ × ℚ) : ℚ := (p.1 - q.1) ^ 2 + (p.2 - q.2) ^ 2

/-- The score `J` of six orders for labels `g` and two centres `c`. -/
def J6 (g : Fin 6 → Fin 2) (c : Fin 2 → ℚ × ℚ) : ℚ := ∑ i, sq (six i) (c (g i))

/-- The mean of the orders labelled `j`. -/
def mean6 (g : Fin 6 → Fin 2) (j : Fin 2) : ℚ × ℚ :=
  let s := univ.filter (fun i => g i = j)
  ((∑ i ∈ s, (six i).1) / s.card, (∑ i ∈ s, (six i).2) / s.card)

-- Pass 1, assign, with centres at A and B: A goes to centre 1, B to F to centre 2; J = 53.
example : (∀ i j, sq (six i) (![(0, 4), (1, 3)] (![0, 1, 1, 1, 1, 1] i)) ≤
    sq (six i) (![(0, 4), (1, 3)] j)) ∧ J6 ![0, 1, 1, 1, 1, 1] ![(0, 4), (1, 3)] = 53 := by
  decide +kernel
-- Pass 1, update: centre 1 stays at (0, 4), centre 2 moves to (13/5, 6/5); J = 24.
example : mean6 ![0, 1, 1, 1, 1, 1] 0 = (0, 4) ∧ mean6 ![0, 1, 1, 1, 1, 1] 1 = (13 / 5, 6 / 5) ∧
    J6 ![0, 1, 1, 1, 1, 1] ![(0, 4), (13 / 5, 6 / 5)] = 24 := by
  decide +kernel
-- Pass 2, assign: B and C are now nearer (0, 4); J = 16.8.
example : (∀ i j, sq (six i) (![(0, 4), (13 / 5, 6 / 5)] (![0, 0, 0, 1, 1, 1] i)) ≤
    sq (six i) (![(0, 4), (13 / 5, 6 / 5)] j)) ∧
    J6 ![0, 0, 0, 1, 1, 1] ![(0, 4), (13 / 5, 6 / 5)] = 168 / 10 := by
  decide +kernel
-- Pass 2, update: centres (1/3, 3) and (4, 1/3); J = 16/3.
example : mean6 ![0, 0, 0, 1, 1, 1] 0 = (1 / 3, 3) ∧ mean6 ![0, 0, 0, 1, 1, 1] 1 = (4, 1 / 3) ∧
    J6 ![0, 0, 0, 1, 1, 1] ![(1 / 3, 3), (4, 1 / 3)] = 16 / 3 := by
  decide +kernel
-- Pass 3, assign: every order is already nearest its own centre, so no label changes.
example : ∀ i j, sq (six i) (![(1 / 3, 3), (4, 1 / 3)] (![0, 0, 0, 1, 1, 1] i)) ≤
    sq (six i) (![(1 / 3, 3), (4, 1 / 3)] j) := by
  decide +kernel
-- There are 31 ways to cut six orders into two groups: name each by the group holding A.
example : (univ.filter (fun s : Finset (Fin 6) => 0 ∈ s ∧ s ≠ univ)).card = 31 := by
  decide +kernel
-- Brute force over every labelling: with each centre at its group's mean, no split beats 16/3.
example : ∀ g : Fin 6 → Fin 2, 16 / 3 ≤ J6 g (mean6 g) := by
  decide +kernel
-- Shift identity on A, B, C with centre A: 6 = 8/3 + 3 × 10/9.
example : sq (0, 4) (0, 4) + sq (1, 3) (0, 4) + sq (0, 2) (0, 4) = 6 ∧
    sq (0, 4) (1 / 3, 3) + sq (1, 3) (1 / 3, 3) + sq (0, 2) (1 / 3, 3) = 8 / 3 ∧
    sq (1 / 3, 3) (0, 4) = 10 / 9 ∧ (6 : ℚ) = 8 / 3 + 3 * (10 / 9) := by
  norm_num [sq]
-- Silhouette by hand, orders at 0, 1 | 3, 4: (5/7 + 3/5 + 3/5 + 5/7) / 4 = 23/35.
example : ((7 / 2 - 1) / max 1 (7 / 2) + (5 / 2 - 1) / max 1 (5 / 2) +
    (5 / 2 - 1) / max 1 (5 / 2) + (7 / 2 - 1) / max 1 (7 / 2) : ℚ) / 4 = 23 / 35 := by
  norm_num

#print axioms kmeans_score_never_rises_and_stops
#print axioms mean_is_best_centre
#print axioms more_centres_lower_score

end KMeansAndClustering
