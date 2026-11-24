-- Ramsey theory on the whole numbers: colour enough consecutive whole numbers with finitely many colours and one colour must hold a sum x + y = z (Schur) and a progression of any chosen length (van der Waerden), with Schur's run bounded by the triangle Ramsey threshold, the Hales-Jewett theorem, and the two-colour values S(2) = 4 and W(3; 2) = 9 checked.
import Mathlib.Combinatorics.HalesJewett
import Mathlib.Data.Fintype.Pi
import Mathlib.Data.Fin.VecNotation
import Mathlib.Data.Finset.Max
import Mathlib.Combinatorics.Pigeonhole
import Mathlib.Algebra.Order.BigOperators.Group.Finset

/-- Helper: triangle Ramsey for any number of colours, on any large enough set of naturals. -/
theorem svdw_tri_ramsey {κ : Type*} [DecidableEq κ] (r : ℕ) :
    ∃ N : ℕ, ∀ V : Finset ℕ, N ≤ V.card → ∀ T : Finset κ, T.card ≤ r →
      ∀ c : ℕ → ℕ → κ, (∀ i ∈ V, ∀ j ∈ V, i < j → c i j ∈ T) →
        ∃ i ∈ V, ∃ j ∈ V, ∃ l ∈ V, i < j ∧ j < l ∧ c i j = c i l ∧ c j l = c i l := by
  induction r with
  | zero =>
    refine ⟨2, fun V hV T hT c hc => ?_⟩
    have hT0 : T = ∅ := Finset.card_eq_zero.1 (by omega)
    obtain ⟨a, ha, b, hb, hab⟩ := Finset.one_lt_card.1 (by omega : 1 < V.card)
    exfalso
    rcases lt_or_gt_of_ne hab with h | h
    · simpa [hT0] using hc a ha b hb h
    · simpa [hT0] using hc b hb a ha h
  | succ r ih =>
    obtain ⟨N, hN⟩ := ih
    refine ⟨(r + 1) * N + 2, fun V hV T hT c hc => ?_⟩
    have hVne : V.Nonempty := Finset.card_pos.1 (by omega)
    set v := V.min' hVne with hv
    have hvV : v ∈ V := V.min'_mem hVne
    set V' := V.erase v with hV'
    have hV'card : V'.card = V.card - 1 := Finset.card_erase_of_mem hvV
    have hlt : ∀ j ∈ V', v < j := by
      intro j hj
      rw [Finset.mem_erase] at hj
      exact lt_of_le_of_ne (V.min'_le j hj.2) (Ne.symm hj.1)
    have hmaps : ∀ j ∈ V', c v j ∈ T := fun j hj =>
      hc v hvV j (Finset.mem_of_mem_erase hj) (hlt j hj)
    obtain ⟨j0, hj0⟩ : V'.Nonempty := Finset.card_pos.1 (by omega)
    have hTne : T.Nonempty := ⟨_, hmaps j0 hj0⟩
    obtain ⟨t, htT, hW⟩ := Finset.exists_le_card_fiber_of_mul_le_card_of_maps_to hmaps hTne
      (n := N) (by
        calc T.card * N ≤ (r + 1) * N := Nat.mul_le_mul_right _ hT
          _ ≤ V'.card := by omega)
    set W := V'.filter (fun j => c v j = t) with hWdef
    have hWV : ∀ j ∈ W, j ∈ V ∧ v < j ∧ c v j = t := by
      intro j hj
      rw [hWdef, Finset.mem_filter] at hj
      exact ⟨Finset.mem_of_mem_erase hj.1, hlt j hj.1, hj.2⟩
    by_cases h : ∃ j ∈ W, ∃ l ∈ W, j < l ∧ c j l = t
    · obtain ⟨j, hj, l, hl, hjl, hc'⟩ := h
      obtain ⟨hjV, hvj, hcj⟩ := hWV j hj
      obtain ⟨hlV, hvl, hcl⟩ := hWV l hl
      exact ⟨v, hvV, j, hjV, l, hlV, hvj, hjl, by rw [hcj, hcl], by rw [hc', hcl]⟩
    · push Not at h
      obtain ⟨i, hi, j, hj, l, hl, h1, h2, h3, h4⟩ := hN W hW (T.erase t)
        (by rw [Finset.card_erase_of_mem htT]; omega) c
        (fun i hi j hj hij => Finset.mem_erase.2
          ⟨h i hi j hj hij, hc i (hWV i hi).1 j (hWV j hj).1 hij⟩)
      exact ⟨i, (hWV i hi).1, j, (hWV j hj).1, l, (hWV l hl).1, h1, h2, h3, h4⟩

#print axioms svdw_tri_ramsey

/-- Helper: Schur from triangles (same statement as `schur_from_triangles`). -/
theorem svdw_schur_from_triangles {κ : Type*} (M : ℕ)
    (hR : ∀ c : ℕ → ℕ → κ, ∃ i j l : ℕ,
        i < j ∧ j < l ∧ l < M ∧ c i j = c i l ∧ c j l = c i l) :
    ∀ C : ℕ → κ, ∃ x y z : ℕ,
        1 ≤ x ∧ 1 ≤ y ∧ x + y = z ∧ z ≤ M - 1 ∧ C x = C z ∧ C y = C z := by
  intro C
  obtain ⟨i, j, l, hij, hjl, hlM, h1, h2⟩ := hR (fun i j => C (j - i))
  refine ⟨j - i, l - j, l - i, by omega, by omega, by omega, by omega, h1, h2⟩

#print axioms svdw_schur_from_triangles

/-- Helper: Hales-Jewett with dimension `Fin n` (same statement as `hales_jewett`). -/
theorem svdw_hales_jewett (m r : ℕ) :
    ∃ n : ℕ, ∀ C : (Fin n → Fin m) → Fin r,
      ∃ l : Combinatorics.Line (Fin m) (Fin n), l.IsMono C := by
  obtain ⟨ι, ιfin, hι⟩ := Combinatorics.Line.exists_mono_in_high_dimension (Fin m) (Fin r)
  refine ⟨Fintype.card ι, fun C => ?_⟩
  obtain ⟨l, c, cl⟩ := hι fun v => C (v ∘ (Fintype.equivFin ι).symm)
  refine ⟨⟨l.idxFun ∘ (Fintype.equivFin ι).symm, ?_⟩, c, fun x => ?_⟩
  · obtain ⟨i, hi⟩ := l.proper
    exact ⟨Fintype.equivFin ι i, by simpa using hi⟩
  · rw [← cl x]
    rfl

#print axioms svdw_hales_jewett

/-- Helper: van der Waerden with a finite bound, from Hales-Jewett. -/
theorem svdw_vdw (r k : ℕ) : ∃ N : ℕ, ∀ C : ℕ → Fin r, ∃ a d : ℕ,
        1 ≤ a ∧ 1 ≤ d ∧ a + (k - 1) * d ≤ N ∧ ∀ i < k, C (a + i * d) = C a := by
  classical
  rcases Nat.eq_zero_or_pos k with hk | hk
  · subst hk
    exact ⟨1, fun C => ⟨1, 1, le_rfl, le_rfl, by simp, fun i hi => absurd hi (Nat.not_lt_zero _)⟩⟩
  obtain ⟨n, hn⟩ := svdw_hales_jewett k r
  refine ⟨1 + n * (k - 1), fun C => ?_⟩
  obtain ⟨l, c, hl⟩ := hn fun w => C (1 + ∑ i, (w i).val)
  set d := (Finset.univ.filter (fun i => l.idxFun i = none)).card with hd
  set A := ∑ i, ((l.idxFun i).map Fin.val).getD 0 with hA
  have key : ∀ x : Fin k, ∑ i, (l x i).val = A + x.val * d := by
    intro x
    have hpt : ∀ i, (l x i).val =
        ((l.idxFun i).map Fin.val).getD 0 + (if l.idxFun i = none then x.val else 0) := by
      intro i
      rw [Combinatorics.Line.coe_apply]
      cases l.idxFun i <;> simp
    rw [Finset.sum_congr rfl (fun i _ => hpt i), Finset.sum_add_distrib, ← Finset.sum_filter,
      Finset.sum_const, smul_eq_mul, hA, hd, Nat.mul_comm]
  have hdpos : 1 ≤ d := by
    obtain ⟨i, hi⟩ := l.proper
    exact Finset.card_pos.2 ⟨i, by simp [hi]⟩
  have hval : ∀ i < k, C (1 + A + i * d) = c := by
    intro i hi
    have := hl ⟨i, hi⟩
    simp only at this
    rw [key] at this
    simpa [Nat.add_assoc] using this
  refine ⟨1 + A, d, by omega, hdpos, ?_, fun i hi => by rw [hval i hi, ← hval 0 hk]; simp⟩
  have h1 := key ⟨k - 1, by omega⟩
  have h2 : ∑ i, (l ⟨k - 1, by omega⟩ i).val ≤ ∑ _i : Fin n, (k - 1) :=
    Finset.sum_le_sum fun i _ => by have := (l ⟨k - 1, by omega⟩ i).isLt; omega
  simp only [Finset.sum_const, Finset.card_univ, Fintype.card_fin, smul_eq_mul] at h2
  simp only at h1
  have h3 : (k - 1) * d + A ≤ n * (k - 1) := by rw [Nat.add_comm, ← h1]; exact h2
  omega

#print axioms svdw_vdw

/-- **Schur and van der Waerden.** Fix a finite number `r` of colours.
Schur: there is a run `1, …, N` such that every colouring of it holds a single-coloured sum
`x + y = z`, with `x = y` allowed.
Van der Waerden: for every length `k` there is a run `1, …, N` such that every colouring of it
holds a single-coloured progression `a, a + d, …, a + (k - 1) d` with gap `d ≥ 1`.
A colouring is a map `C : ℕ → Fin r`; only its values on `1, …, N` are used. -/
theorem schur_and_van_der_waerden (r : ℕ) :
    (∃ N : ℕ, ∀ C : ℕ → Fin r, ∃ x y z : ℕ,
        1 ≤ x ∧ 1 ≤ y ∧ x + y = z ∧ z ≤ N ∧ C x = C z ∧ C y = C z) ∧
    (∀ k : ℕ, ∃ N : ℕ, ∀ C : ℕ → Fin r, ∃ a d : ℕ,
        1 ≤ a ∧ 1 ≤ d ∧ a + (k - 1) * d ≤ N ∧ ∀ i < k, C (a + i * d) = C a) := by
  classical
  refine ⟨?_, svdw_vdw r⟩
  obtain ⟨N, hN⟩ := svdw_tri_ramsey (κ := Fin r) r
  refine ⟨N, fun C => ?_⟩
  obtain ⟨x, y, z, h1, h2, h3, h4, h5, h6⟩ := svdw_schur_from_triangles N (fun c => by
    obtain ⟨i, -, j, -, l, hl, hij, hjl, e1, e2⟩ := hN (Finset.range N) (by simp)
      Finset.univ (by simp) c (by simp)
    exact ⟨i, j, l, hij, hjl, Finset.mem_range.1 hl, e1, e2⟩) C
  exact ⟨x, y, z, h1, h2, h3, by omega, h5, h6⟩

/-- **Schur from triangles** (the card's `S(r) ≤ R_r(3) - 2`). If `M` points `0, …, M - 1` are
enough that every colouring of the links between them holds a single-coloured triangle, then
every colouring of `1, …, M - 1` holds a single-coloured sum `x + y = z`: colour the link
`i < j` by the colour of the gap `j - i`, and a triangle `i < j < l` gives
`(j - i) + (l - j) = l - i`. -/
theorem schur_from_triangles {κ : Type*} (M : ℕ)
    (hR : ∀ c : ℕ → ℕ → κ, ∃ i j l : ℕ,
        i < j ∧ j < l ∧ l < M ∧ c i j = c i l ∧ c j l = c i l) :
    ∀ C : ℕ → κ, ∃ x y z : ℕ,
        1 ≤ x ∧ 1 ≤ y ∧ x + y = z ∧ z ≤ M - 1 ∧ C x = C z ∧ C y = C z := by
  exact svdw_schur_from_triangles M hR

/-- **The Hales-Jewett theorem.** For any alphabet size `m` and any number of colours `r`, a
board `{0, …, m - 1}^n` of high enough dimension `n` forces a single-coloured Hales-Jewett
(combinatorial) line under every colouring of its cells. -/
theorem hales_jewett (m r : ℕ) :
    ∃ n : ℕ, ∀ C : (Fin n → Fin m) → Fin r,
      ∃ l : Combinatorics.Line (Fin m) (Fin n), l.IsMono C := by
  exact svdw_hales_jewett m r

/-! Worked examples from the card. In the `Fin` examples, index `i` stands for the number `i + 1`;
`true` is blue and `false` is red. -/

-- Schur dodge on 1 to 4: red 1, 4 and blue 2, 3 hold no single-coloured x + y = z.
example : ∀ x y : Fin 4, x.val + y.val + 1 < 4 →
    ¬ (![false, true, true, false] x = ![false, true, true, false] (x + y + 1) ∧
       ![false, true, true, false] y = ![false, true, true, false] (x + y + 1)) := by
  decide

-- Exactly 2 two-colourings of 1 to 4 dodge x + y = z.
example : (Finset.univ.filter (fun c : Fin 4 → Bool =>
    ∀ x y : Fin 4, x.val + y.val + 1 < 4 → ¬ (c x = c (x + y + 1) ∧ c y = c (x + y + 1)))).card = 2 := by
  decide

-- S(2) = 4: every two-colouring of 1 to 5 holds a single-coloured x + y = z.
example : ∀ c : Fin 5 → Bool, ∃ x y : Fin 5,
    x.val + y.val + 1 < 5 ∧ c x = c (x + y + 1) ∧ c y = c (x + y + 1) := by
  decide

-- Progression dodge on 1 to 8: red 1, 2, 5, 6 and blue 3, 4, 7, 8 hold no single-coloured a, a+d, a+2d.
example : ∀ a d : Fin 8, 0 < d.val → a.val + 2 * d.val < 8 →
    ¬ (![false, false, true, true, false, false, true, true] a =
         ![false, false, true, true, false, false, true, true] (a + d) ∧
       ![false, false, true, true, false, false, true, true] a =
         ![false, false, true, true, false, false, true, true] (a + d + d)) := by
  decide

-- Exactly 6 two-colourings of 1 to 8 dodge three-term progressions.
example : (Finset.univ.filter (fun c : Fin 8 → Bool =>
    ∀ a d : Fin 8, 0 < d.val → a.val + 2 * d.val < 8 → ¬ (c a = c (a + d) ∧ c a = c (a + d + d)))).card = 6 := by
  decide

-- W(3; 2) = 9: every two-colouring of 1 to 9 holds a single-coloured a, a+d, a+2d.
example : ∀ c : Fin 9 → Bool, ∃ a d : Fin 9,
    0 < d.val ∧ a.val + 2 * d.val < 9 ∧ c a = c (a + d) ∧ c a = c (a + d + d) := by
  decide +kernel

#print axioms schur_and_van_der_waerden
#print axioms schur_from_triangles
#print axioms hales_jewett
