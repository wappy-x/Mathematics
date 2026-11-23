-- Sunflowers and union-closed families: more than w! (p - 1)^w distinct w-sets always contain a p-petal sunflower, a union-closed family with a one-point set {x} has x in at least half its sets, Gilmer's entropy barrier is (3 - sqrt 5)/2, and the card's whole-number examples are exact.
import Mathlib.Data.Finset.Powerset
import Mathlib.Data.Nat.Factorial.Basic
import Mathlib.Analysis.SpecialFunctions.BinaryEntropy
import Mathlib.Analysis.SpecialFunctions.Sqrt

open Real

/-- A family `S` of sets is a sunflower when every two different members overlap in one and
the same set `K`, the core. -/
def IsSunflower {α : Type*} [DecidableEq α] (S : Finset (Finset α)) : Prop :=
  ∃ K : Finset α, ∀ A ∈ S, ∀ B ∈ S, A ≠ B → A ∩ B = K

lemma binEntropy_eq_cases (x y : ℝ) (hx0 : 0 ≤ x) (hx1 : x ≤ 1) (hy0 : 0 ≤ y) (hy1 : y ≤ 1)
    (h : binEntropy x = binEntropy y) : x = y ∨ x = 1 - y := by
  rcases le_or_gt x 2⁻¹ with hx | hx <;> rcases le_or_gt y 2⁻¹ with hy | hy
  · left
    exact binEntropy_strictMonoOn.injOn ⟨hx0, hx⟩ ⟨hy0, hy⟩ h
  · right
    rw [← binEntropy_one_sub y] at h
    exact binEntropy_strictMonoOn.injOn ⟨hx0, hx⟩ ⟨by linarith, by linarith⟩ h
  · right
    rw [← binEntropy_one_sub x] at h
    have := binEntropy_strictMonoOn.injOn (⟨by linarith, by linarith⟩ : 1 - x ∈ Set.Icc (0:ℝ) 2⁻¹)
      ⟨hy0, hy⟩ h
    linarith
  · left
    exact binEntropy_strictAntiOn.injOn ⟨hx.le, hx1⟩ ⟨hy.le, hy1⟩ h

#print axioms binEntropy_eq_cases

/-- Helper: induction for Erdős–Rado. -/
lemma erdos_rado_aux {α : Type*} [DecidableEq α] (p : ℕ) :
    ∀ (w : ℕ) (F : Finset (Finset α)), (∀ A ∈ F, A.card = w) →
      w.factorial * (p - 1) ^ w < F.card → ∃ S ⊆ F, S.card = p ∧ IsSunflower S := by
  intro w
  induction w with
  | zero =>
    intro F hw hbig
    exfalso
    have : F ⊆ {∅} := by
      intro A hA
      simpa [Finset.card_eq_zero] using hw A hA
    have := Finset.card_le_card this
    simp at hbig this
    omega
  | succ w ih =>
    intro F hw hbig
    classical
    let D := F.powerset.filter (fun M => ∀ A ∈ M, ∀ B ∈ M, A ≠ B → Disjoint A B)
    have hDne : D.Nonempty := ⟨∅, by simp [D]⟩
    obtain ⟨M, hMD, hMmax⟩ := Finset.exists_max_image D Finset.card hDne
    simp only [D, Finset.mem_filter, Finset.mem_powerset] at hMD
    obtain ⟨hMF, hMdisj⟩ := hMD
    by_cases hMp : p ≤ M.card
    · obtain ⟨S, hSM, hSc⟩ := Finset.exists_subset_card_eq hMp
      refine ⟨S, hSM.trans hMF, hSc, ∅, ?_⟩
      intro A hA B hB hAB
      exact Finset.disjoint_iff_inter_eq_empty.mp (hMdisj A (hSM hA) B (hSM hB) hAB)
    · push Not at hMp
      let U := M.biUnion id
      -- every member of F meets U
      have hmeet : ∀ A ∈ F, ∃ x ∈ U, x ∈ A := by
        intro A hA
        by_contra hcon
        push Not at hcon
        have hAM : A ∉ M := by
          intro hAM
          have hpos : 0 < A.card := by rw [hw A hA]; omega
          obtain ⟨y, hy⟩ := Finset.card_pos.mp hpos
          exact hcon y (Finset.mem_biUnion.mpr ⟨A, hAM, hy⟩) hy
        have hin : insert A M ∈ D := by
          simp only [D, Finset.mem_filter, Finset.mem_powerset]
          refine ⟨Finset.insert_subset hA hMF, ?_⟩
          have hdA : ∀ B ∈ M, Disjoint A B := by
            intro B hB
            rw [Finset.disjoint_left]
            intro y hyA hyB
            exact hcon y (Finset.mem_biUnion.mpr ⟨B, hB, hyB⟩) hyA
          intro B hB C hC hBC
          rw [Finset.mem_insert] at hB hC
          rcases hB with rfl | hB <;> rcases hC with rfl | hC
          · exact absurd rfl hBC
          · exact hdA C hC
          · exact (hdA B hB).symm
          · exact hMdisj B hB C hC hBC
        have := hMmax _ hin
        rw [Finset.card_insert_of_notMem hAM] at this
        omega
      have hFsub : F ⊆ U.biUnion (fun x => F.filter (fun A => x ∈ A)) := by
        intro A hA
        obtain ⟨x, hxU, hxA⟩ := hmeet A hA
        exact Finset.mem_biUnion.mpr ⟨x, hxU, Finset.mem_filter.mpr ⟨hA, hxA⟩⟩
      have hUcard : U.card ≤ (p - 1) * (w + 1) := by
        calc U.card ≤ ∑ A ∈ M, (id A).card := Finset.card_biUnion_le
          _ = ∑ A ∈ M, (w + 1) := Finset.sum_congr rfl (fun A hA => hw A (hMF hA))
          _ = M.card * (w + 1) := by simp
          _ ≤ (p - 1) * (w + 1) := Nat.mul_le_mul_right _ (by omega)
      -- some point lies in many sets
      have hx : ∃ x ∈ U, w.factorial * (p - 1) ^ w < (F.filter (fun A => x ∈ A)).card := by
        by_contra hcon
        push Not at hcon
        have h1 := Finset.card_le_card hFsub
        have h2 : (U.biUnion (fun x => F.filter (fun A => x ∈ A))).card
            ≤ U.card * (w.factorial * (p - 1) ^ w) :=
          Finset.card_biUnion_le_card_mul _ _ _ hcon
        have h3 : U.card * (w.factorial * (p - 1) ^ w)
            ≤ (p - 1) * (w + 1) * (w.factorial * (p - 1) ^ w) := Nat.mul_le_mul_right _ hUcard
        have h4 : (p - 1) * (w + 1) * (w.factorial * (p - 1) ^ w)
            = (w + 1).factorial * (p - 1) ^ (w + 1) := by
          rw [Nat.factorial_succ, pow_succ]; ring
        omega
      obtain ⟨x, -, hxbig⟩ := hx
      let Fx := F.filter (fun A => x ∈ A)
      let G := Fx.image (fun A => A.erase x)
      have hGcard : G.card = Fx.card := by
        apply Finset.card_image_of_injOn
        intro A hA B hB hAB
        simp only [Fx, Finset.coe_filter, Set.mem_ofPred_eq] at hA hB
        have := congrArg (insert x) hAB
        simpa [Finset.insert_erase hA.2, Finset.insert_erase hB.2] using this
      have hGw : ∀ B ∈ G, B.card = w := by
        intro B hB
        obtain ⟨A, hA, rfl⟩ := Finset.mem_image.mp hB
        simp only [Fx, Finset.mem_filter] at hA
        rw [Finset.card_erase_of_mem hA.2, hw A hA.1]
        rfl
      have hGnx : ∀ B ∈ G, x ∉ B := by
        intro B hB
        obtain ⟨A, -, rfl⟩ := Finset.mem_image.mp hB
        exact Finset.notMem_erase x A
      obtain ⟨S', hS'G, hS'c, K, hK⟩ := ih G hGw (by rw [hGcard]; exact hxbig)
      refine ⟨S'.image (insert x), ?_, ?_, insert x K, ?_⟩
      · intro A hA
        obtain ⟨B, hB, rfl⟩ := Finset.mem_image.mp hA
        obtain ⟨A0, hA0, rfl⟩ := Finset.mem_image.mp (hS'G hB)
        simp only [Fx, Finset.mem_filter] at hA0
        rw [Finset.insert_erase hA0.2]
        exact hA0.1
      · rw [Finset.card_image_of_injOn, hS'c]
        intro B hB C hC hBC
        have hBx := hGnx B (hS'G hB)
        have hCx := hGnx C (hS'G hC)
        have := congrArg (fun D => D.erase x) hBC
        simpa [Finset.erase_insert hBx, Finset.erase_insert hCx] using this
      · intro A hA B hB hAB
        obtain ⟨A', hA', rfl⟩ := Finset.mem_image.mp hA
        obtain ⟨B', hB', rfl⟩ := Finset.mem_image.mp hB
        have hne : A' ≠ B' := fun h => hAB (h ▸ rfl)
        rw [← Finset.insert_inter_distrib, hK A' hA' B' hB' hne]

#print axioms erdos_rado_aux

/-- The Erdős–Rado sunflower lemma (1960): if a family of distinct sets, each with exactly
`w` points, has more than `w! · (p - 1)^w` members, then `p` of them form a sunflower. -/
theorem erdos_rado_sunflower_lemma {α : Type*} [DecidableEq α] (w p : ℕ)
    (F : Finset (Finset α)) (hw : ∀ A ∈ F, A.card = w)
    (hbig : w.factorial * (p - 1) ^ w < F.card) :
    ∃ S ⊆ F, S.card = p ∧ IsSunflower S := by
  exact erdos_rado_aux p w F hw hbig

/-- The singleton rule: if a family is union-closed (the union of any two members is a member)
and contains the one-point set `{x}`, then `x` lies in at least half of its sets. -/
theorem union_closed_singleton_in_half {α : Type*} [DecidableEq α]
    (F : Finset (Finset α)) (hU : ∀ A ∈ F, ∀ B ∈ F, A ∪ B ∈ F) (x : α) (hx : {x} ∈ F) :
    F.card ≤ 2 * (F.filter (fun A => x ∈ A)).card := by
  have hsplit := Finset.card_filter_add_card_filter_not (s := F) (fun A => x ∈ A)
  have hle : (F.filter (fun A => x ∉ A)).card ≤ (F.filter (fun A => x ∈ A)).card := by
    apply Finset.card_le_card_of_injOn (fun A => insert x A)
    · intro A hA
      simp only [Finset.coe_filter, Set.mem_ofPred_eq] at hA ⊢
      refine ⟨?_, Finset.mem_insert_self x A⟩
      have := hU A hA.1 {x} hx
      rwa [Finset.union_comm, ← Finset.insert_eq] at this
    · intro A hA B hB hAB
      simp only [Finset.coe_filter, Set.mem_ofPred_eq] at hA hB
      have := congrArg (fun C => C.erase x) hAB
      simpa [Finset.erase_insert hA.2, Finset.erase_insert hB.2] using this
  omega

/-- Gilmer's barrier: for a share `q` strictly between 0 and 1, the union of two independent
random sets (each point in with probability `q`, so in the union with probability `2q - q²`)
has the same binary entropy as one set exactly when `q = (3 - √5)/2 ≈ 0.381966`. -/
theorem gilmer_barrier_entropy_crossing (q : ℝ) (h0 : 0 < q) (h1 : q < 1) :
    binEntropy (2 * q - q ^ 2) = binEntropy q ↔ q = (3 - √5) / 2 := by
  have h5 : √5 ^ 2 = 5 := Real.sq_sqrt (by norm_num)
  have h5p : 0 < √5 := Real.sqrt_pos.mpr (by norm_num)
  constructor
  · intro h
    rcases binEntropy_eq_cases _ _ (by nlinarith) (by nlinarith) h0.le h1.le h with h' | h'
    · nlinarith
    · have hq : (q - (3 - √5) / 2) * (q - (3 + √5) / 2) = 0 := by nlinarith
      rcases mul_eq_zero.mp hq with h'' | h''
      · linarith
      · linarith
  · intro h
    have : 2 * q - q ^ 2 = 1 - q := by subst h; nlinarith
    rw [this, binEntropy_one_sub]

-- The three routes, 1 Central, 2 Market, 3 Airport, 4 Harbour, 5 Stadium:
-- every pair overlaps in exactly {Central, Market}.
example : ({1, 2, 3} ∩ {1, 2, 4} : Finset ℕ) = {1, 2} ∧ ({1, 2, 3} ∩ {1, 2, 5} : Finset ℕ) = {1, 2}
    ∧ ({1, 2, 4} ∩ {1, 2, 5} : Finset ℕ) = {1, 2} := by decide

-- The near miss {1,2,3}, {1,2,4}, {1,3,4}: overlaps {1,2}, {1,3}, {1,4}, all different.
example : ({1, 2, 3} ∩ {1, 2, 4} : Finset ℕ) = {1, 2} ∧ ({1, 2, 3} ∩ {1, 3, 4} : Finset ℕ) = {1, 3}
    ∧ ({1, 2, 4} ∩ {1, 3, 4} : Finset ℕ) = {1, 4} := by decide

-- The Erdős–Rado bound w! · 2^w for 3 petals, w = 1..4.
example : (Nat.factorial 1 * 2 ^ 1, Nat.factorial 2 * 2 ^ 2, Nat.factorial 3 * 2 ^ 3,
    Nat.factorial 4 * 2 ^ 4) = (2, 8, 48, 384) := by decide

-- Two triangles: 6 two-stop routes with no 3-petal sunflower.
example : ∀ A ∈ ({{1, 2}, {1, 3}, {2, 3}, {4, 5}, {4, 6}, {5, 6}} : Finset (Finset ℕ)),
    ∀ B ∈ ({{1, 2}, {1, 3}, {2, 3}, {4, 5}, {4, 6}, {5, 6}} : Finset (Finset ℕ)),
    ∀ C ∈ ({{1, 2}, {1, 3}, {2, 3}, {4, 5}, {4, 6}, {5, 6}} : Finset (Finset ℕ)),
    A ≠ B → A ≠ C → B ≠ C → ¬ (A ∩ B = A ∩ C ∧ A ∩ C = B ∩ C) := by decide

-- The route combinations: the unions of the non-empty selections of the 3 routes are 7 sets;
-- Central (1) is in all 7 and Airport (3) in 4.
example :
    let R : Finset (Finset ℕ) := {{1, 2, 3}, {1, 2, 4}, {1, 2, 5}}
    let U := (R.powerset.erase ∅).image (fun T => T.sup id)
    U.card = 7 ∧ (U.filter (fun A => 1 ∈ A)).card = 7 ∧ (U.filter (fun A => 3 ∈ A)).card = 4 := by
  decide

-- What breaks: {1}, {2}, {3} is not union-closed, and each point is in only 1 of the 3 sets.
example : ∀ x ∈ ({1, 2, 3} : Finset ℕ),
    ((({{1}, {2}, {3}} : Finset (Finset ℕ))).filter (fun A => x ∈ A)).card = 1 := by decide

-- Gilmer's barrier is the smaller root of q² - 3q + 1 = 0.
example : ((3 - √5) / 2) ^ 2 - 3 * ((3 - √5) / 2) + 1 = 0 := by
  linear_combination (1 / 4 : ℝ) * Real.sq_sqrt (show (0 : ℝ) ≤ 5 by norm_num)

#print axioms erdos_rado_sunflower_lemma
#print axioms union_closed_singleton_in_half
#print axioms gilmer_barrier_entropy_crossing
