-- Hamiltonian cycles: a simple network on three or more vertices whose every degree is at least half the vertex count has a round through every vertex once (Dirac), a two-sided network with unequal sides has none, the cube warehouse has one below Dirac's bar, and the card's warehouse and depot numbers check out.
import Mathlib.Combinatorics.SimpleGraph.Hamiltonian
import Mathlib.Combinatorics.SimpleGraph.Finite
import Mathlib.Data.Nat.Factorial.Basic
import Mathlib.Data.Rat.Cast.Order
import Mathlib.Tactic

namespace HamiltonianCycles

open SimpleGraph

lemma hc_mod_one {n a b : ℕ} (ha : a < n) (hb : b < n) (h : (n - b + a) % n = 1) :
    a = b + 1 ∨ (a = 0 ∧ b = n - 1) := by
  by_cases hab : b ≤ a
  · rw [show n - b + a = (a - b) + n by omega, Nat.add_mod_right,
      Nat.mod_eq_of_lt (by omega)] at h
    omega
  · rw [Nat.mod_eq_of_lt (by omega)] at h
    omega

lemma hc_of_cyclic {V : Type*} [Fintype V] [DecidableEq V] (G : SimpleGraph V) (N : ℕ)
    (hN : Fintype.card V = N) (h3 : 3 ≤ N) (g : ℕ → V)
    (hinj : ∀ i j, i < N → j < N → g i = g j → i = j)
    (hadj : ∀ i, i + 1 < N → G.Adj (g i) (g (i + 1)))
    (hclose : G.Adj (g (N - 1)) (g 0)) :
    ∃ a : V, ∃ p : G.Walk a a, p.IsHamiltonianCycle := by
  subst hN
  have hc : cycleGraph (Fintype.card V) ⊑ G := by
    refine ⟨⟨⟨fun i => g i.val, ?_⟩, ?_⟩⟩
    · intro a b hab
      have ha := a.isLt
      have hb := b.isLt
      rw [cycleGraph_adj', Fin.val_sub, Fin.val_sub] at hab
      rcases hab with h | h
      · rcases hc_mod_one ha hb h with h1 | ⟨h1, h2⟩
        · have := hadj b.val (by omega)
          rw [← h1] at this
          exact this.symm
        · have := hclose
          rw [← h2, ← h1] at this
          exact this.symm
      · rcases hc_mod_one hb ha h with h1 | ⟨h1, h2⟩
        · have := hadj a.val (by omega)
          rw [← h1] at this
          exact this
        · have := hclose
          rw [← h2, ← h1] at this
          exact this
    · intro a b h
      exact Fin.ext (hinj _ _ a.isLt b.isLt h)
  exact (isHamiltonian_iff_cycleGraph_isContained h3).mpr hc (by omega)

lemma hc_support_eq_cons {V : Type*} {G : SimpleGraph V} {b c : V} (q : G.Walk b c) :
    q.support = b :: q.support.tail := by
  cases q <;> rfl

lemma hc_alt_count {V : Type*} [DecidableEq V] (G : SimpleGraph V) (S : Finset V)
    (hcross : ∀ u v, G.Adj u v → (u ∈ S ↔ v ∉ S)) {u v : V} (p : G.Walk u v) :
    (p.support.tail.countP (fun x => decide (x ∈ S)) : ℤ) -
      (p.support.tail.countP (fun x => decide (x ∉ S)) : ℤ) =
      (if v ∈ S then 1 else 0) - (if u ∈ S then 1 else 0) := by
  induction p with
  | nil => simp
  | cons h q ih =>
    rename_i a b c
    rw [Walk.support_cons, List.tail_cons, hc_support_eq_cons q, List.countP_cons,
      List.countP_cons]
    rw [hc_support_eq_cons q, List.tail_cons] at ih
    have := hcross _ _ h
    by_cases hb : b ∈ S <;> by_cases ha : a ∈ S <;> simp_all <;> omega

/-- A path given by a function: `f 0, …, f (m - 1)` are distinct and consecutive ones adjacent. -/
def HcPathFn {V : Type*} (G : SimpleGraph V) (f : ℕ → V) (m : ℕ) : Prop :=
  (∀ i j, i < m → j < m → f i = f j → i = j) ∧ ∀ i, i + 1 < m → G.Adj (f i) (f (i + 1))

lemma hc_pathFn_le {V : Type*} [Fintype V] {G : SimpleGraph V} {f : ℕ → V} {m : ℕ}
    (h : HcPathFn G f m) : m ≤ Fintype.card V := by
  have := Finset.card_le_card_of_injOn f (s := Finset.range m) (t := Finset.univ)
    (fun _ _ => Finset.mem_coe.mpr (Finset.mem_univ _))
    (fun i hi j hj hij => h.1 i j (by simpa using hi) (by simpa using hj) hij)
  simpa using this

#print axioms hc_mod_one
#print axioms hc_of_cyclic
#print axioms hc_support_eq_cons
#print axioms hc_alt_count
#print axioms HcPathFn
#print axioms hc_pathFn_le

/-- Dirac's theorem (1952). A simple network on `n ≥ 3` vertices in which every vertex has degree
at least `n / 2` (half as a fraction, not rounded down) has a Hamiltonian cycle: a closed route
through every vertex exactly once. -/
theorem dirac_min_degree_half_gives_hamiltonian_cycle {V : Type*} [Fintype V] [DecidableEq V]
    (G : SimpleGraph V) [DecidableRel G.Adj]
    (hn : 3 ≤ Fintype.card V) (hδ : (Fintype.card V : ℚ) / 2 ≤ G.minDegree) :
    ∃ a : V, ∃ p : G.Walk a a, p.IsHamiltonianCycle := by
  classical
  obtain ⟨n, hnV⟩ : ∃ n, Fintype.card V = n := ⟨_, rfl⟩
  rw [hnV] at hn hδ
  have hδ' : n ≤ 2 * G.minDegree := by
    rw [div_le_iff₀ (by norm_num)] at hδ
    exact_mod_cast (by linarith : (n : ℚ) ≤ 2 * G.minDegree)
  have hdeg : ∀ v, n ≤ 2 * G.degree v := fun v => by
    have := G.minDegree_le_degree v
    omega
  obtain ⟨v0⟩ : Nonempty V := Fintype.card_pos_iff.mp (by omega)
  let P : ℕ → Prop := fun m => ∃ f : ℕ → V, HcPathFn G f m
  have hP1 : P 1 := ⟨fun _ => v0, fun i j hi hj _ => by omega, fun i hi => by omega⟩
  have hspec := Nat.findGreatest_spec (P := P) (m := 1) (n := n) (by omega) hP1
  have hm1 := Nat.le_findGreatest (P := P) (m := 1) (n := n) (by omega) hP1
  set m := Nat.findGreatest P n with hm_def
  have hmax : ∀ (g : ℕ → V) k, m < k → ¬ HcPathFn G g k := fun g k hk hg =>
    Nat.findGreatest_is_greatest hk (hnV ▸ hc_pathFn_le hg) ⟨g, hg⟩
  obtain ⟨f, hfinj, hfadj⟩ := hspec
  have hmn : m ≤ n := hnV ▸ hc_pathFn_le ⟨hfinj, hfadj⟩
  -- every neighbour of the first vertex lies on the path
  have hN0 : ∀ u, G.Adj (f 0) u → ∃ j, j < m ∧ f j = u := by
    intro u hu
    by_contra hcon
    push Not at hcon
    apply hmax (fun j => if j = 0 then u else f (j - 1)) (m + 1) (by omega)
    refine ⟨?_, ?_⟩
    · intro i j hi hj hij
      by_cases hi0 : i = 0 <;> by_cases hj0 : j = 0
      · omega
      · simp only [hi0, hj0, ite_true, ite_false] at hij
        exact absurd hij.symm (hcon _ (by omega))
      · simp only [hi0, hj0, ite_true, ite_false] at hij
        exact absurd hij (hcon _ (by omega))
      · simp only [hi0, hj0, ite_false] at hij
        have := hfinj _ _ (by omega) (by omega) hij
        omega
    · intro i hi
      by_cases hi0 : i = 0
      · subst hi0
        simp only [ite_true, show (0 + 1 = 0) = False by simp, ite_false]
        exact hu.symm
      · simp only [hi0, show (i + 1 = 0) = False by simp, ite_false, Nat.add_sub_cancel]
        have := hfadj (i - 1) (by omega)
        rwa [show i - 1 + 1 = i by omega] at this
  -- every neighbour of the last vertex lies on the path
  have hNk : ∀ u, G.Adj (f (m - 1)) u → ∃ j, j < m ∧ f j = u := by
    intro u hu
    by_contra hcon
    push Not at hcon
    apply hmax (fun j => if j < m then f j else u) (m + 1) (by omega)
    refine ⟨?_, ?_⟩
    · intro i j hi hj hij
      by_cases hi0 : i < m <;> by_cases hj0 : j < m
      · simp only [hi0, hj0, ite_true] at hij
        exact hfinj _ _ hi0 hj0 hij
      · simp only [hi0, hj0, ite_true, ite_false] at hij
        exact absurd hij (hcon _ hi0)
      · simp only [hi0, hj0, ite_true, ite_false] at hij
        exact absurd hij.symm (hcon _ hj0)
      · omega
    · intro i hi
      by_cases him : i + 1 < m
      · simp only [him, show i < m by omega, ite_true]
        exact hfadj i him
      · simp only [him, show i < m by omega, ite_true, ite_false]
        rw [show i = m - 1 by omega]
        exact hu
  -- the two index sets of Pósa's argument
  obtain ⟨A, hA_def⟩ : ∃ A : Finset ℕ,
      A = (Finset.range (m - 1)).filter (fun i => G.Adj (f 0) (f (i + 1))) := ⟨_, rfl⟩
  obtain ⟨B, hB_def⟩ : ∃ B : Finset ℕ,
      B = (Finset.range (m - 1)).filter (fun i => G.Adj (f i) (f (m - 1))) := ⟨_, rfl⟩
  have hA : G.degree (f 0) ≤ A.card := by
    rw [← G.card_neighborFinset_eq_degree]
    refine le_trans (Finset.card_le_card ?_) (Finset.card_image_le (f := fun i => f (i + 1)))
    intro u hu
    rw [mem_neighborFinset] at hu
    obtain ⟨j, hj, rfl⟩ := hN0 u hu
    have hj0 : j ≠ 0 := by
      rintro rfl
      exact hu.ne rfl
    rw [Finset.mem_image]
    refine ⟨j - 1, ?_, by simp only [show j - 1 + 1 = j by omega]⟩
    rw [hA_def, Finset.mem_filter, Finset.mem_range]
    refine ⟨by omega, ?_⟩
    rwa [show j - 1 + 1 = j by omega]
  have hB : G.degree (f (m - 1)) ≤ B.card := by
    rw [← G.card_neighborFinset_eq_degree]
    refine le_trans (Finset.card_le_card ?_) (Finset.card_image_le (f := f))
    intro u hu
    rw [mem_neighborFinset] at hu
    obtain ⟨j, hj, rfl⟩ := hNk u hu
    have hjk : j ≠ m - 1 := by
      rintro rfl
      exact hu.ne rfl
    rw [Finset.mem_image]
    refine ⟨j, ?_, rfl⟩
    rw [hB_def, Finset.mem_filter, Finset.mem_range]
    exact ⟨by omega, hu.symm⟩
  have hAm : A.card ≤ m - 1 := by
    have := Finset.card_filter_le (Finset.range (m - 1)) (fun i => G.Adj (f 0) (f (i + 1)))
    rw [hA_def]
    simpa using this
  have hd0 := hdeg (f 0)
  have hdk := hdeg (f (m - 1))
  obtain ⟨i, hi⟩ := Finset.inter_nonempty_of_card_lt_card_add_card
    (hA_def ▸ Finset.filter_subset _ _ : A ⊆ Finset.range (m - 1))
    (hB_def ▸ Finset.filter_subset _ _ : B ⊆ Finset.range (m - 1))
    (by rw [Finset.card_range]; omega)
  rw [Finset.mem_inter, hA_def, hB_def, Finset.mem_filter, Finset.mem_filter,
    Finset.mem_range] at hi
  obtain ⟨⟨him, hi0⟩, -, hik⟩ := hi
  -- the cycle through all vertices of the path
  set g : ℕ → V := fun j => if j ≤ i then f j else f (m + i - j) with hg_def
  have hginj : ∀ a b, a < m → b < m → g a = g b → a = b := by
    intro a b ha hb hab
    simp only [hg_def] at hab
    by_cases hai : a ≤ i <;> by_cases hbi : b ≤ i
    · simp only [hai, hbi, ite_true] at hab
      exact hfinj _ _ ha hb hab
    · simp only [hai, hbi, ite_true, ite_false] at hab
      have := hfinj _ _ ha (by omega) hab
      omega
    · simp only [hai, hbi, ite_true, ite_false] at hab
      have := hfinj _ _ (by omega) hb hab
      omega
    · simp only [hai, hbi, ite_false] at hab
      have := hfinj _ _ (by omega) (by omega) hab
      omega
  have hgadj : ∀ a, a + 1 < m → G.Adj (g a) (g (a + 1)) := by
    intro a ha
    simp only [hg_def]
    by_cases h1 : a + 1 ≤ i
    · simp only [h1, show a ≤ i by omega, ite_true]
      exact hfadj a (by omega)
    · by_cases h2 : a = i
      · subst h2
        simp only [le_refl, ite_true, h1, ite_false]
        rwa [show m + a - (a + 1) = m - 1 by omega]
      · simp only [h1, show ¬ a ≤ i by omega, ite_false]
        have := hfadj (m + i - (a + 1)) (by omega)
        rw [show m + i - (a + 1) + 1 = m + i - a by omega] at this
        exact this.symm
  have hgclose : G.Adj (g (m - 1)) (g 0) := by
    simp only [hg_def, Nat.zero_le, ite_true, show ¬ m - 1 ≤ i by omega, ite_false]
    rw [show m + i - (m - 1) = i + 1 by omega]
    exact hi0.symm
  -- the path already covers every vertex
  have hmeq : m = n := by
    by_contra hne
    have hlt : m < n := lt_of_le_of_ne hmn hne
    have himg : ((Finset.range m).image g).card = m := by
      rw [Finset.card_image_of_injOn (fun a ha b hb hab => hginj a b
        (by simpa using ha) (by simpa using hb) hab), Finset.card_range]
    obtain ⟨w, -, hw⟩ := Finset.exists_mem_notMem_of_card_lt_card
      (s := (Finset.range m).image g) (t := Finset.univ)
      (by rw [himg, Finset.card_univ, hnV]; exact hlt)
    have hw' : ∀ c, c < m → g c ≠ w := fun c hc h =>
      hw (Finset.mem_image.mpr ⟨c, Finset.mem_range.mpr hc, h⟩)
    by_cases hconn : ∃ c, c < m ∧ G.Adj (g c) w
    · obtain ⟨c, hc, hcw⟩ := hconn
      let r : ℕ → ℕ := fun j => if c + 1 + j < m then c + 1 + j else c + 1 + j - m
      apply hmax (fun j => if j < m then g (r j) else w) (m + 1) (by omega)
      refine ⟨?_, ?_⟩
      · intro a b ha hb hab
        by_cases ham : a < m <;> by_cases hbm : b < m
        · simp only [ham, hbm, ite_true] at hab
          have hra : r a < m := by simp only [r]; split_ifs <;> omega
          have hrb : r b < m := by simp only [r]; split_ifs <;> omega
          have := hginj _ _ hra hrb hab
          simp only [r] at this
          split_ifs at this <;> omega
        · simp only [ham, hbm, ite_true, ite_false] at hab
          exact absurd hab (hw' _ (by simp only [r]; split_ifs <;> omega))
        · simp only [ham, hbm, ite_true, ite_false] at hab
          exact absurd hab.symm (hw' _ (by simp only [r]; split_ifs <;> omega))
        · omega
      · intro a ha
        by_cases ham : a + 1 < m
        · simp only [ham, show a < m by omega, ite_true]
          simp only [r]
          by_cases h1 : c + 1 + (a + 1) < m
          · simp only [h1, show c + 1 + a < m by omega, ite_true]
            rw [show c + 1 + (a + 1) = c + 1 + a + 1 by omega]
            exact hgadj _ (by omega)
          · by_cases h2 : c + 1 + a < m
            · simp only [h1, h2, ite_true, ite_false]
              rw [show c + 1 + a = m - 1 by omega, show c + 1 + (a + 1) - m = 0 by omega]
              exact hgclose
            · simp only [h1, h2, ite_false]
              rw [show c + 1 + (a + 1) - m = c + 1 + a - m + 1 by omega]
              exact hgadj _ (by omega)
        · simp only [ham, show a < m by omega, ite_true, ite_false]
          simp only [r]
          simp only [show ¬ (c + 1 + a < m) by omega, ite_false]
          rw [show c + 1 + a - m = c by omega]
          exact hcw
    · push Not at hconn
      have hsub : G.neighborFinset w ⊆ (insert w ((Finset.range m).image g))ᶜ := by
        intro u hu
        rw [mem_neighborFinset] at hu
        rw [Finset.mem_compl, Finset.mem_insert, Finset.mem_image]
        rintro (rfl | ⟨c, hc, rfl⟩)
        · exact hu.ne rfl
        · exact hconn c (Finset.mem_range.mp hc) hu.symm
      have hcard := Finset.card_le_card hsub
      rw [card_neighborFinset_eq_degree, Finset.card_compl,
        Finset.card_insert_of_notMem hw, himg, hnV] at hcard
      have hdw := hdeg w
      have := hA
      omega
  exact hc_of_cyclic G m (hnV.trans hmeq.symm) (by omega) g hginj hgadj hgclose

/-- A cheap "no". If every edge joins one side `S` to the other side, and the two sides hold
different numbers of vertices, the network has no Hamiltonian cycle: a round alternates sides. -/
theorem no_hamiltonian_cycle_of_unequal_sides {V : Type*} [Fintype V] [DecidableEq V]
    (G : SimpleGraph V) (S : Finset V)
    (hcross : ∀ u v, G.Adj u v → (u ∈ S ↔ v ∉ S)) (hsides : S.card ≠ Sᶜ.card) :
    ¬ ∃ a : V, ∃ p : G.Walk a a, p.IsHamiltonianCycle := by
  rintro ⟨a, p, hp⟩
  have h := hc_alt_count G S hcross p
  simp only [sub_self] at h
  have hcount := (Walk.isHamiltonianCycle_iff_isCycle_and_support_count_tail_eq_one.mp hp).2
  have hval : (p.support.tail : Multiset V) = (Finset.univ : Finset V).val := by
    ext x
    rw [Multiset.coe_count, hcount x,
      Multiset.count_eq_one_of_mem Finset.univ.nodup (Finset.mem_univ x)]
  have hS : p.support.tail.countP (fun x => decide (x ∈ S)) = S.card := by
    rw [← Multiset.coe_countP, hval, Multiset.countP_eq_card_filter]
    rw [← Finset.filter_val, Finset.card_val]
    congr 1
    ext x; simp
  have hT : p.support.tail.countP (fun x => decide (x ∉ S)) = Sᶜ.card := by
    rw [← Multiset.coe_countP, hval, Multiset.countP_eq_card_filter]
    rw [← Finset.filter_val, Finset.card_val]
    congr 1
    ext x; simp
  rw [hS, hT] at h
  omega

/-! The networks on the card. -/

/-- The cube warehouse: corners `0`–`7` in three binary digits, joined when the codes differ in
exactly one digit. -/
def cube : SimpleGraph (Fin 8) where
  Adj x y := x.val ^^^ y.val = 1 ∨ x.val ^^^ y.val = 2 ∨ x.val ^^^ y.val = 4
  symm := ⟨by decide⟩
  loopless := ⟨by decide⟩

instance : DecidableRel cube.Adj := fun _ _ =>
  inferInstanceAs (Decidable (_ ∨ _ ∨ _))

/-- The cube plus four gangways, each joining a corner `x` to the opposite corner `7 - x`. -/
def cubeGangways : SimpleGraph (Fin 8) where
  Adj x y := cube.Adj x y ∨ x.val + y.val = 7
  symm := ⟨by decide⟩
  loopless := ⟨by decide⟩

instance : DecidableRel cubeGangways.Adj := fun _ _ =>
  inferInstanceAs (Decidable (_ ∨ _))

/-- The links of the Petersen network of ten depots: an outer five-cycle, five spokes, and an
inner five-pointed star. -/
def petersenLinks : List (Fin 10 × Fin 10) :=
  [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0),
   (0, 5), (1, 6), (2, 7), (3, 8), (4, 9),
   (5, 7), (6, 8), (7, 9), (8, 5), (9, 6)]

/-- The Petersen network of ten depots. -/
def petersen : SimpleGraph (Fin 10) where
  Adj x y := (x, y) ∈ petersenLinks ∨ (y, x) ∈ petersenLinks
  symm := ⟨fun _ _ h => h.symm⟩
  loopless := ⟨by decide⟩

instance : DecidableRel petersen.Adj := fun _ _ =>
  inferInstanceAs (Decidable (_ ∨ _))

/-- Dirac's bar is sufficient, never necessary. The cube warehouse's smallest degree, 3, is
below its bar of 8 / 2 = 4, and still it has a Hamiltonian cycle. -/
theorem cube_has_hamiltonian_cycle_below_dirac_bar :
    (cube.minDegree : ℚ) < 8 / 2 ∧ ∃ a : Fin 8, ∃ p : cube.Walk a a, p.IsHamiltonianCycle := by
  refine ⟨?_, ?_⟩
  · have h : cube.minDegree = 3 := by decide
    have h' : (cube.minDegree : ℚ) = 3 := by rw [h]; norm_num
    rw [h', lt_div_iff₀ (by norm_num)]; norm_num
  · refine hc_of_cyclic cube 8 (by simp) (by norm_num)
      (fun i => ([0, 1, 3, 2, 6, 7, 5, 4] : List (Fin 8)).getD i 0) ?_ ?_ ?_
    · have key : ∀ i < 8, ∀ j < 8, ([0, 1, 3, 2, 6, 7, 5, 4] : List (Fin 8)).getD i 0 =
          ([0, 1, 3, 2, 6, 7, 5, 4] : List (Fin 8)).getD j 0 → i = j := by decide
      exact fun i j hi hj => key i hi j hj
    · have key : ∀ i < 7, cube.Adj (([0, 1, 3, 2, 6, 7, 5, 4] : List (Fin 8)).getD i 0)
          (([0, 1, 3, 2, 6, 7, 5, 4] : List (Fin 8)).getD (i + 1) 0) := by decide
      exact fun i hi => key i (by omega)
    · decide

/-! The card's worked numbers. -/

-- The cube: 12 walkways, every corner of degree 3, bar 8 / 2 = 4, so Dirac is silent.
example : cube.edgeFinset.card = 12 := by decide
example : ∀ v, cube.degree v = 3 := by decide
example : cube.minDegree = 3 ∧ 2 * 3 < 8 := by decide

-- The round 0, 1, 3, 2, 6, 7, 5, 4, back to 0: every step a walkway, every corner once.
example : List.IsChain cube.Adj [0, 1, 3, 2, 6, 7, 5, 4, 0] ∧
    ([0, 1, 3, 2, 6, 7, 5, 4] : List (Fin 8)).Nodup := by decide

-- A blind sift faces (8 - 1)! / 2 = 2520 orders.
example : Nat.factorial (8 - 1) / 2 = 2520 := by decide

-- Four gangways: every degree 3 + 1 = 4, meeting the bar 8 / 2 exactly; 16 links in all.
example : ∀ v, cubeGangways.degree v = 4 := by decide
example : cubeGangways.minDegree = 4 ∧ 8 ≤ 2 * 4 := by decide
example : cubeGangways.edgeFinset.card = 16 := by decide

-- The gangway network is K(4, 4): every corner is joined to exactly the four corners whose
-- count of 1s has the other parity; its rounds number 4! × 3! / 2 = 72.
example : ∀ x y : Fin 8, cubeGangways.Adj x y ↔
    (x.val % 2 + x.val / 2 % 2 + x.val / 4) % 2 ≠ (y.val % 2 + y.val / 2 % 2 + y.val / 4) % 2 := by decide
example : Nat.factorial 4 * Nat.factorial 3 / 2 = 72 := by decide

-- The depots: 15 links, three at each, against a bar of 10 / 2 = 5, so Dirac is silent.
example : petersen.edgeFinset.card = 15 := by decide
example : ∀ v, petersen.degree v = 3 := by decide
example : petersen.minDegree = 3 ∧ 2 * 3 < 10 := by decide

-- The route 0-1-2-3-4-9-6-8-5-7 touches all ten depots, but its ends 7 and 0 are not joined.
example : List.IsChain petersen.Adj [0, 1, 2, 3, 4, 9, 6, 8, 5, 7] ∧
    ([0, 1, 2, 3, 4, 9, 6, 8, 5, 7] : List (Fin 10)).Nodup ∧ ¬ petersen.Adj 7 0 := by decide

-- A blind sift of ten depots faces (10 - 1)! / 2 = 181440 orders.
example : Nat.factorial (10 - 1) / 2 = 181440 := by decide

#print axioms dirac_min_degree_half_gives_hamiltonian_cycle
#print axioms no_hamiltonian_cycle_of_unequal_sides
#print axioms cube_has_hamiltonian_cycle_below_dirac_bar

end HamiltonianCycles
