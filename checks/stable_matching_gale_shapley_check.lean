-- Stable matching: with n doctors and n hospitals who each rank the whole other side strictly, some placement has no blocking pair, and one such placement gives every doctor her best stable partner and every hospital its worst.
import Mathlib.Logic.Equiv.Fintype
import Mathlib.Data.Fintype.Perm
import Mathlib.Order.Fin.Basic
import Mathlib.Data.Fin.VecNotation
import Mathlib.Algebra.BigOperators.Fin

/-! Doctors and hospitals are both numbered `0, …, n - 1` (`Fin n`).

* A placement `M` is a one-to-one pairing, `M : Equiv.Perm (Fin n)`: doctor `d` gets hospital
  `M d`, and hospital `h` gets doctor `M.symm h`. Nobody is in two pairs, and everyone is placed
  (full lists, equal numbers, one post each).
* A strict ranking is a one-to-one numbering of the other side, best first: doctor `d` puts
  hospital `h` in place `dr d h` (0 is her first choice), and hospital `h` puts doctor `d` in
  place `hr h d`. Being one-to-one means no ties. Smaller place means preferred. -/

namespace StableMatching

variable {n : ℕ}

/-- Doctor `d` and hospital `h` block `M` when each prefers the other to the partner `M` gives
them. (A pair already together never blocks, since nobody prefers their partner to themselves.) -/
def Blocks (dr hr : Fin n → Equiv.Perm (Fin n)) (M : Equiv.Perm (Fin n)) (d h : Fin n) : Prop :=
  dr d h < dr d (M d) ∧ hr h d < hr h (M.symm h)

/-- A placement is stable when no doctor and hospital block it. -/
def IsStable (dr hr : Fin n → Equiv.Perm (Fin n)) (M : Equiv.Perm (Fin n)) : Prop :=
  ∀ d h, ¬ Blocks dr hr M d h

instance (dr hr : Fin n → Equiv.Perm (Fin n)) (M : Equiv.Perm (Fin n)) (d h : Fin n) :
    Decidable (Blocks dr hr M d h) := by
  unfold Blocks; infer_instance

instance (dr hr : Fin n → Equiv.Perm (Fin n)) : DecidablePred (IsStable dr hr) := fun M => by
  unfold IsStable; infer_instance

/-! Helpers for the proof: the doctors' propose-and-hold process, run one rejection at a time.
`R` is the set of pairs `(d, h)` where hospital `h` has already turned doctor `d` down. -/

/-- Doctor `d` currently proposes to `h`: her best hospital that has not turned her down. -/
def Pr (dr : Fin n → Equiv.Perm (Fin n)) (R : Finset (Fin n × Fin n)) (d h : Fin n) : Prop :=
  (d, h) ∉ R ∧ ∀ h', (d, h') ∉ R → dr d h ≤ dr d h'

theorem pr_unique (dr : Fin n → Equiv.Perm (Fin n)) (R : Finset (Fin n × Fin n)) {d h h' : Fin n}
    (p : Pr dr R d h) (p' : Pr dr R d h') : h = h' :=
  (dr d).injective (le_antisymm (p.2 h' p'.1) (p'.2 h p.1))

#print axioms pr_unique

theorem pr_exists (dr : Fin n → Equiv.Perm (Fin n)) (R : Finset (Fin n × Fin n)) (d : Fin n)
    (hd : ∃ h, (d, h) ∉ R) : ∃ h, Pr dr R d h := by
  classical
  obtain ⟨h0, hh0⟩ := hd
  obtain ⟨h, hmem, hmin⟩ := Finset.exists_min_image (Finset.univ.filter fun h => (d, h) ∉ R)
    (fun h => dr d h) ⟨h0, by simpa using hh0⟩
  refine ⟨h, by simpa using hmem, fun h' hh' => hmin h' (by simpa using hh')⟩

#print axioms pr_exists

/-- Every hospital that has turned someone down currently holds a proposal from a doctor it
prefers. -/
def Inv2 (dr hr : Fin n → Equiv.Perm (Fin n)) (R : Finset (Fin n × Fin n)) : Prop :=
  ∀ x k, (x, k) ∈ R → ∃ y, Pr dr R y k ∧ hr k y < hr k x

/-- No doctor has been turned down by a stable partner. -/
def Inv1 (dr hr : Fin n → Equiv.Perm (Fin n)) (R : Finset (Fin n × Fin n)) : Prop :=
  ∀ M : Equiv.Perm (Fin n), IsStable dr hr M → ∀ d, (d, M d) ∉ R

theorem not_all_rejected (dr hr : Fin n → Equiv.Perm (Fin n)) (R : Finset (Fin n × Fin n))
    (h2 : Inv2 dr hr R) (d : Fin n) : ∃ h, (d, h) ∉ R := by
  by_contra hall
  push Not at hall
  have hg : ∀ h, ∃ y, Pr dr R y h ∧ hr h y < hr h d := fun h => h2 d h (hall h)
  choose g hgP hglt using hg
  have ginj : Function.Injective g := by
    intro a b hab
    have hb := hgP b
    rw [← hab] at hb
    exact pr_unique dr R (hgP a) hb
  obtain ⟨h, hh⟩ := (Finite.injective_iff_surjective.mp ginj) d
  have := hglt h
  rw [hh] at this
  exact lt_irrefl _ this

#print axioms not_all_rejected

theorem pr_insert (dr : Fin n → Equiv.Perm (Fin n)) (R : Finset (Fin n × Fin n)) {y k : Fin n}
    (a : Fin n × Fin n) (p : Pr dr R y k) (hne : (y, k) ≠ a) : Pr dr (insert a R) y k := by
  refine ⟨?_, fun h' hh' => p.2 h' (fun hm => hh' (Finset.mem_insert_of_mem hm))⟩
  intro hm
  rcases Finset.mem_insert.mp hm with e | e
  · exact hne e
  · exact p.1 e

#print axioms pr_insert

theorem step_inv (dr hr : Fin n → Equiv.Perm (Fin n)) (R : Finset (Fin n × Fin n))
    (h1 : Inv1 dr hr R) (h2 : Inv2 dr hr R) {d d' h : Fin n} (hdd : d ≠ d')
    (pd : Pr dr R d h) (pd' : Pr dr R d' h) (hlt : hr h d < hr h d') :
    Inv1 dr hr (insert (d', h) R) ∧ Inv2 dr hr (insert (d', h) R) := by
  have hne_d : (d, h) ≠ (d', h) := fun e => hdd (Prod.mk.inj e).1
  have pdR : Pr dr (insert (d', h) R) d h := pr_insert dr R _ pd hne_d
  constructor
  · intro M hM d0 hm
    rcases Finset.mem_insert.mp hm with e | e
    · obtain ⟨rfl, hMd⟩ := Prod.mk.inj e
      have hMd' : M d ≠ h := by
        intro e2
        exact hdd (M.injective (e2.trans hMd.symm))
      have hnR : (d, M d) ∉ R := h1 M hM d
      have hle : dr d h ≤ dr d (M d) := pd.2 _ hnR
      have hne : dr d h ≠ dr d (M d) := fun e3 => hMd' ((dr d).injective e3).symm
      have hsymm : M.symm h = d0 := by rw [Equiv.symm_apply_eq]; exact hMd.symm
      exact hM d h ⟨lt_of_le_of_ne hle hne, by rw [hsymm]; exact hlt⟩
    · exact h1 M hM d0 e
  · intro x k hm
    rcases Finset.mem_insert.mp hm with e | e
    · obtain ⟨rfl, rfl⟩ := Prod.mk.inj e
      exact ⟨d, pdR, hlt⟩
    · obtain ⟨y, py, hy⟩ := h2 x k e
      by_cases hy' : y = d'
      · subst hy'
        have hk : k = h := pr_unique dr R py pd'
        subst hk
        exact ⟨d, pdR, lt_trans hlt hy⟩
      · exact ⟨y, pr_insert dr R _ py (fun e2 => hy' (Prod.mk.inj e2).1), hy⟩

#print axioms step_inv

theorem hosp_worst_aux
    (dr hr : Fin n → Equiv.Perm (Fin n)) (M₀ : Equiv.Perm (Fin n))
    (hbest : ∀ M : Equiv.Perm (Fin n), IsStable dr hr M → ∀ d, dr d (M₀ d) ≤ dr d (M d))
    (M : Equiv.Perm (Fin n)) (hM : IsStable dr hr M) (h : Fin n) :
    hr h (M.symm h) ≤ hr h (M₀.symm h) := by
  by_contra hcon
  push Not at hcon
  set d := M₀.symm h with hd
  have hM₀d : M₀ d = h := by simp [hd]
  have hle : dr d h ≤ dr d (M d) := by rw [← hM₀d]; exact hbest M hM d
  have hMd : M d ≠ h := by
    intro e
    have : M.symm h = d := by rw [Equiv.symm_apply_eq]; exact e.symm
    rw [this] at hcon
    exact lt_irrefl _ hcon
  have hne : dr d h ≠ dr d (M d) := fun e => hMd ((dr d).injective e).symm
  exact hM d h ⟨lt_of_le_of_ne hle hne, hcon⟩

#print axioms hosp_worst_aux

theorem gs_aux (dr hr : Fin n → Equiv.Perm (Fin n)) :
    ∀ (k : ℕ) (R : Finset (Fin n × Fin n)), Rᶜ.card = k → Inv1 dr hr R → Inv2 dr hr R →
    ∃ M₀ : Equiv.Perm (Fin n), IsStable dr hr M₀ ∧
      ∀ M : Equiv.Perm (Fin n), IsStable dr hr M →
        (∀ d, dr d (M₀ d) ≤ dr d (M d)) ∧ (∀ h, hr h (M.symm h) ≤ hr h (M₀.symm h)) := by
  intro k
  induction k using Nat.strong_induction_on with
  | _ k ih =>
  intro R hk h1 h2
  by_cases hc : ∃ d d' h, d ≠ d' ∧ Pr dr R d h ∧ Pr dr R d' h
  · obtain ⟨d, d', h, hdd, pd, pd'⟩ := hc
    have hne : hr h d ≠ hr h d' := fun e => hdd ((hr h).injective e)
    -- the hospital turns down whichever of the two it likes less
    have key : ∀ a b : Fin n, a ≠ b → Pr dr R a h → Pr dr R b h → hr h a < hr h b →
        ∃ M₀ : Equiv.Perm (Fin n), IsStable dr hr M₀ ∧
          ∀ M : Equiv.Perm (Fin n), IsStable dr hr M →
            (∀ d, dr d (M₀ d) ≤ dr d (M d)) ∧ (∀ h, hr h (M.symm h) ≤ hr h (M₀.symm h)) := by
      intro a b hab pa pb hlt
      obtain ⟨i1, i2⟩ := step_inv dr hr R h1 h2 hab pa pb hlt
      have hlt' : (insert (b, h) R)ᶜ.card < k := by
        rw [← hk]
        apply Finset.card_lt_card
        rw [Finset.compl_insert]
        exact Finset.erase_ssubset (Finset.mem_compl.mpr pb.1)
      exact ih _ hlt' _ rfl i1 i2
    rcases lt_or_gt_of_ne hne with hl | hl
    · exact key d d' hdd pd pd' hl
    · exact key d' d (Ne.symm hdd) pd' pd hl
  · push Not at hc
    have hex : ∀ d, ∃ h, Pr dr R d h := fun d => pr_exists dr R d (not_all_rejected dr hr R h2 d)
    choose f hf using hex
    have finj : Function.Injective f := by
      intro a b hab
      by_contra hne
      have hb := hf b
      rw [← hab] at hb
      exact hc a b (f a) hne (hf a) hb
    let M₀ : Equiv.Perm (Fin n) :=
      Equiv.ofBijective f ⟨finj, Finite.injective_iff_surjective.mp finj⟩
    have hM₀ : ∀ d, M₀ d = f d := fun d => rfl
    have best : ∀ M : Equiv.Perm (Fin n), IsStable dr hr M → ∀ d, dr d (M₀ d) ≤ dr d (M d) := by
      intro M hM d
      rw [hM₀]
      exact (hf d).2 _ (h1 M hM d)
    refine ⟨M₀, ?_, fun M hM => ⟨best M hM, hosp_worst_aux dr hr M₀ best M hM⟩⟩
    intro d h hb
    obtain ⟨hb1, hb2⟩ := hb
    have hR : (d, h) ∈ R := by
      by_contra hn
      have := (hf d).2 h hn
      rw [hM₀] at hb1
      exact absurd hb1 (not_lt.mpr this)
    obtain ⟨y, py, hy⟩ := h2 d h hR
    have hfy : f y = h := pr_unique dr R (hf y) py
    have hs : M₀.symm h = y := by rw [Equiv.symm_apply_eq, hM₀]; exact hfy.symm
    rw [hs] at hb2
    exact lt_irrefl _ (lt_trans hy hb2)

#print axioms gs_aux

/-- The card's main claim. With strict rankings on both sides, a placement that no doctor and
hospital would both abandon always exists, and there is one (the doctors' propose-and-hold
result) that is best for the doctors and worst for the hospitals: against any stable placement
`M`, every doctor does at least as well and every hospital at least as badly. -/
theorem stable_matching_exists_best_for_proposers_worst_for_receivers
    (dr hr : Fin n → Equiv.Perm (Fin n)) :
    ∃ M₀ : Equiv.Perm (Fin n), IsStable dr hr M₀ ∧
      ∀ M : Equiv.Perm (Fin n), IsStable dr hr M →
        (∀ d, dr d (M₀ d) ≤ dr d (M d)) ∧ (∀ h, hr h (M.symm h) ≤ hr h (M₀.symm h)) := by
  exact gs_aux dr hr _ ∅ rfl (fun _ _ _ => Finset.notMem_empty _) (fun _ _ hm => absurd hm (Finset.notMem_empty _))

/-- Step 4, "hospitals get their worst": if a stable placement gives every doctor her best stable
partner, then it gives every hospital its worst one. If some hospital liked its partner under it
more than under a stable `M`, that partner and that hospital would block `M`. -/
theorem doctor_best_stable_is_hospital_worst
    (dr hr : Fin n → Equiv.Perm (Fin n)) (M₀ : Equiv.Perm (Fin n))
    (hbest : ∀ M : Equiv.Perm (Fin n), IsStable dr hr M → ∀ d, dr d (M₀ d) ≤ dr d (M d))
    (M : Equiv.Perm (Fin n)) (hM : IsStable dr hr M) (h : Fin n) :
    hr h (M.symm h) ≤ hr h (M₀.symm h) := by
  exact hosp_worst_aux dr hr M₀ hbest M hM h

/-! The card's example. Doctors: Asha 0, Ben 1, Carys 2. Hospitals: Northgate 0, Riverside 1,
Southbank 2. Each list below gives the place (0 = first choice) of hospitals 0, 1, 2 for a doctor,
or of doctors 0, 1, 2 for a hospital. -/

/-- A permutation of `{0, 1, 2}` from its table and its inverse's table. -/
def perm3 (f g : Fin 3 → Fin 3) (hgf : ∀ i, g (f i) = i := by decide)
    (hfg : ∀ i, f (g i) = i := by decide) : Equiv.Perm (Fin 3) := ⟨f, g, hgf, hfg⟩

/-- Doctors' places. Asha: Northgate, Riverside, Southbank. Ben: Northgate, Southbank, Riverside.
Carys: Riverside, Southbank, Northgate. -/
def DR : Fin 3 → Equiv.Perm (Fin 3) :=
  ![perm3 ![0, 1, 2] ![0, 1, 2], perm3 ![0, 2, 1] ![0, 2, 1], perm3 ![2, 0, 1] ![1, 2, 0]]

/-- Hospitals' places. Northgate: Carys, Ben, Asha. Riverside: Ben, Asha, Carys.
Southbank: Asha, Carys, Ben. -/
def HR : Fin 3 → Equiv.Perm (Fin 3) :=
  ![perm3 ![2, 1, 0] ![2, 1, 0], perm3 ![1, 0, 2] ![1, 0, 2], perm3 ![0, 2, 1] ![0, 2, 1]]

/-- Doctors proposing: Asha-Riverside, Ben-Northgate, Carys-Southbank. -/
def MD : Equiv.Perm (Fin 3) := perm3 ![1, 0, 2] ![1, 0, 2]
/-- Hospitals proposing: Asha-Southbank, Ben-Riverside, Carys-Northgate. -/
def MH : Equiv.Perm (Fin 3) := perm3 ![2, 1, 0] ![2, 1, 0]
/-- Mistake 1, accepting for good: Asha-Southbank, Ben-Northgate, Carys-Riverside. -/
def M1 : Equiv.Perm (Fin 3) := perm3 ![2, 0, 1] ![1, 2, 0]
/-- Mistake 2, most doctor happiness: Asha-Northgate, Ben-Southbank, Carys-Riverside. -/
def M2 : Equiv.Perm (Fin 3) := perm3 ![0, 2, 1] ![0, 2, 1]

-- 3! = 6 placements; exactly 2 are stable, the doctors' and the hospitals' proposing results.
example : Fintype.card (Equiv.Perm (Fin 3)) = 6 := by decide
example : (Finset.univ.filter (IsStable DR HR)).card = 2 := by decide
example : IsStable DR HR MD ∧ IsStable DR HR MH := by decide
-- Doctors proposing is best for every doctor and worst for every hospital among stable placements.
example : ∀ M, IsStable DR HR M → ∀ d, DR d (MD d) ≤ DR d (M d) := by decide
example : ∀ M, IsStable DR HR M → ∀ h, HR h (M.symm h) ≤ HR h (MD.symm h) := by decide
-- Ranks (1 = first choice). Doctors proposing: doctors 2nd, 1st, 2nd; hospitals 2nd, 2nd, 2nd.
example : (List.ofFn fun d => (DR d (MD d) : ℕ) + 1) = [2, 1, 2] ∧
    (List.ofFn fun h => (HR h (MD.symm h) : ℕ) + 1) = [2, 2, 2] := by decide
-- Hospitals proposing: doctors 3rd, 3rd, 3rd; hospitals 1st, 1st, 1st.
example : (List.ofFn fun d => (DR d (MH d) : ℕ) + 1) = [3, 3, 3] ∧
    (List.ofFn fun h => (HR h (MH.symm h) : ℕ) + 1) = [1, 1, 1] := by decide
-- Mistake 1 is blocked by Asha and Riverside.
example : Blocks DR HR M1 0 1 := by decide
-- Mistake 2 has the lowest doctor rank total, 4, and is blocked by Ben and Northgate.
example : (∑ d, ((DR d (M2 d) : ℕ) + 1)) = 4 := by decide
example : ∀ M : Equiv.Perm (Fin 3), 4 ≤ ∑ d, ((DR d (M d) : ℕ) + 1) := by decide
example : Blocks DR HR M2 1 0 := by decide
-- Mistake 3: under the doctors' result 2 doctors miss their first choice, yet no pair blocks.
example : (Finset.univ.filter fun d => DR d (MD d) ≠ 0).card = 2 ∧
    ∀ d h, ¬ Blocks DR HR MD d h := by decide

#print axioms stable_matching_exists_best_for_proposers_worst_for_receivers
#print axioms doctor_best_stable_is_hospital_worst

end StableMatching
