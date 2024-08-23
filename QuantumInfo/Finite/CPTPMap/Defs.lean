import QuantumInfo.Finite.CPTPMap.CPMap

/- Building on `MatrixMap`s, this defines `PTPMap` and `CPTPMap`, which describe important classes
of quantum operations: `IsPositive` and `IsTracePreserving`, or `IsCompletelyPositive` and `IsTracePreserving`,
respectively.
-/

variable (dIn dOut dOut₂ : Type*) [Fintype dIn] [Fintype dOut] [Fintype dOut₂]

/-- Positive trace-preserving linear maps. These includes all channels, but aren't
  necessarily *completely* positive, see `CPTPMap`. -/
structure PTPMap where
  map : MatrixMap dIn dOut ℂ
  pos : map.IsPositive
  trace_preserving : map.IsTracePreserving

/-- Quantum channels, aka CPTP maps: completely positive trace preserving linear maps. See
`CPTPMap.mk` for a constructor that doesn't require going through PTPMap. -/
structure CPTPMap [DecidableEq dIn] extends PTPMap dIn dOut where
  mk' ::
    completely_pos : map.IsCompletelyPositive
    pos := completely_pos.IsPositive

variable {dIn dOut dOut₂}

namespace PTPMap
noncomputable section
open ComplexOrder

@[ext]
theorem ext {Λ₁ Λ₂ : PTPMap dIn dOut} (h : Λ₁.map = Λ₂.map) : Λ₁ = Λ₂ :=
  PTPMap.mk.injEq Λ₁.map _ _ _ _ _ ▸ h

theorem apply_PosSemidef (Λ : PTPMap dIn dOut) (hρ : ρ.PosSemidef) : (Λ.map ρ).PosSemidef :=
  Λ.pos hρ

/-- Simp lemma: the trace of the image of a PTPMap is the same as the original trace. -/
@[simp]
theorem apply_trace (Λ : PTPMap dIn dOut) (ρ : Matrix dIn dIn ℂ) : (Λ.map ρ).trace = ρ.trace :=
  Λ.trace_preserving ρ

instance instFunLike : FunLike (PTPMap dIn dOut) (MState dIn) (MState dOut) where
  coe Λ := fun ρ ↦ MState.mk (Λ.map ρ.m) (Λ.apply_PosSemidef ρ.pos) (ρ.tr ▸ Λ.apply_trace ρ.m)
  coe_injective' _ _ h := sorry --Requires the fact the action on MStates determines action on all matrices

--If we have a PTPMap, the input and output dimensions are always both nonempty (otherwise
--we can't preserve trace) - or they're both empty. So `[Nonempty dIn]` will always suffice.
-- This would be nice as an `instance` but that would leave `dIn` as a metavariable.
theorem nonemptyOut (Λ : PTPMap dIn dOut) [hIn : Nonempty dIn] [DecidableEq dIn] : Nonempty dOut := by
  by_contra h
  simp only [not_nonempty_iff] at h
  let M := (1 : Matrix dIn dIn ℂ)
  have := calc (Finset.univ.card (α := dIn) : ℂ)
    _ = M.trace := by simp [Matrix.trace, M]
    _ = (Λ.map M).trace := (Λ.trace_preserving M).symm
    _ = 0 := by simp only [Matrix.trace_eq_zero_of_isEmpty]
  norm_num [Finset.univ_eq_empty_iff] at this

end
end PTPMap

namespace CPTPMap
noncomputable section
open scoped Matrix ComplexOrder

variable [DecidableEq dIn]

/-- Construct a CPTPMap from the facts that it IsTracePreserving and IsCompletelyPositive. -/
def mk (map : MatrixMap dIn dOut ℂ) (tp : map.IsTracePreserving) (cp : map.IsCompletelyPositive) : CPTPMap dIn dOut where
  map := map
  trace_preserving := tp
  completely_pos := cp

@[simp]
theorem map_mk (map : MatrixMap dIn dOut ℂ) (h₁) (h₂) : (CPTPMap.mk map h₁ h₂).map = map :=
  rfl

variable {dM : Type*} [Fintype dM] [DecidableEq dM]
variable {dM₂ : Type*} [Fintype dM₂] [DecidableEq dM₂]

/-- The Choi matrix of a CPTPMap. -/
@[reducible]
def choi (Λ : CPTPMap dIn dOut) := Λ.map.choi_matrix

/-- Two CPTPMaps are equal if their projection to PTPMaps are equal. -/
theorem PTP_ext {Λ₁ Λ₂ : CPTPMap dIn dOut} (h : Λ₁.toPTPMap = Λ₂.toPTPMap) : Λ₁ = Λ₂ :=
  CPTPMap.mk'.injEq Λ₁.toPTPMap _ _ _ ▸ h

/-- Two CPTPMaps are equal if their MatrixMaps are equal. -/
theorem map_ext {Λ₁ Λ₂ : CPTPMap dIn dOut} (h : Λ₁.map = Λ₂.map) : Λ₁ = Λ₂ :=
  PTP_ext (PTPMap.ext h)

/-- Two CPTPMaps are equal if their Choi matrices are equal. -/
theorem choi_ext {Λ₁ Λ₂ : CPTPMap dIn dOut} (h : Λ₁.choi = Λ₂.choi) : Λ₁ = Λ₂ :=
  PTP_ext (PTPMap.ext (MatrixMap.choi_matrix_inj h))

/-- The Choi matrix of a channel is PSD. -/
theorem choi_PSD_of_CPTP (Λ : CPTPMap dIn dOut) : Λ.map.choi_matrix.PosSemidef :=
  Λ.map.choi_PSD_iff_CP_map.1 Λ.completely_pos

/-- The trace of a Choi matrix of a CPTP map is the cardinality of the input space. -/
@[simp]
theorem Tr_of_choi_of_CPTP (Λ : CPTPMap dIn dOut) : Λ.choi.trace =
    (Finset.univ (α := dIn)).card :=
  Λ.trace_preserving.trace_choi

/-- Construct a CPTP map from a PSD Choi matrix with correct partial trace. -/
def CPTP_of_choi_PSD_Tr {M : Matrix (dIn × dOut) (dIn × dOut) ℂ} (h₁ : M.PosSemidef)
    (h₂ : M.trace_right = 1) : CPTPMap dIn dOut := CPTPMap.mk
  (map := MatrixMap.of_choi_matrix M)
  (tp := (MatrixMap.of_choi_matrix M).IsTracePreserving_iff_trace_choi.2
    ((MatrixMap.map_choi_inv M).symm ▸ h₂))
  (cp := (MatrixMap.choi_PSD_iff_CP_map _).2 ((MatrixMap.map_choi_inv M).symm ▸ h₁))

@[simp]
theorem choi_of_CPTP_of_choi (M : Matrix (dIn × dOut) (dIn × dOut) ℂ) {h₁} {h₂} :
    (CPTP_of_choi_PSD_Tr (M := M) h₁ h₂).choi = M := by
  simp only [choi, CPTP_of_choi_PSD_Tr, map_mk, MatrixMap.map_choi_inv]

/-- CPTPMaps are functions from MStates to MStates. -/
instance instFunLike : FunLike (CPTPMap dIn dOut) (MState dIn) (MState dOut) where
  coe Λ := fun ρ ↦ MState.mk (Λ.map ρ.m) (Λ.apply_PosSemidef ρ.pos) (ρ.tr ▸ Λ.apply_trace ρ.m)
  coe_injective' _ _ h := by
    apply PTP_ext
    apply DFunLike.coe_injective'
    funext ρ
    convert congrFun h ρ

theorem mat_coe_eq_apply_mat (Λ : CPTPMap dIn dOut) (ρ : MState dIn) : (Λ ρ).m = Λ.map ρ.m :=
  rfl

@[ext]
theorem ext {Λ₁ Λ₂ : CPTPMap dIn dOut} (h : ∀ ρ, Λ₁ ρ = Λ₂ ρ) : Λ₁ = Λ₂ := by
  apply DFunLike.coe_injective'
  funext
  exact (h _)

/-- The composition of CPTPMaps, as a CPTPMap. -/
def compose (Λ₂ : CPTPMap dM dOut) (Λ₁ : CPTPMap dIn dM) : CPTPMap dIn dOut :=
  CPTPMap.mk (Λ₂.map ∘ₗ Λ₁.map)
  (Λ₁.trace_preserving.comp Λ₂.trace_preserving)
  (Λ₁.completely_pos.comp Λ₂.completely_pos)

/-- Composition of CPTPMaps by `CPTPMap.compose` is compatible with the `instFunLike` action. -/
@[simp]
theorem compose_eq {Λ₁ : CPTPMap dIn dM} {Λ₂ : CPTPMap dM dOut} : ∀ρ, (Λ₂.compose Λ₁) ρ = Λ₂ (Λ₁ ρ) :=
  fun _ ↦ rfl

/-- Composition of CPTPMaps is associative. -/
theorem compose_assoc  (Λ₃ : CPTPMap dM₂ dOut) (Λ₂ : CPTPMap dM dM₂) (Λ₁ : CPTPMap dIn dM) :
    (Λ₃.compose Λ₂).compose Λ₁ = Λ₃.compose (Λ₂.compose Λ₁) := by
  ext1 ρ
  simp

/-- The identity channel, which leaves the input unchanged. -/
def id : CPTPMap dIn dIn :=
  CPTPMap.mk LinearMap.id MatrixMap.IsTracePreserving.id MatrixMap.IsCompletelyPositive.id

/-- The map `CPTPMap.id` leaves any matrix unchanged. -/
@[simp]
theorem id_fun_id (M : Matrix dIn dIn ℂ) : id.map M = M := by
  ext
  simp [id]

/-- The map `CPTPMap.id` leaves the input state unchanged. -/
@[simp]
theorem id_MState (ρ : MState dIn) : CPTPMap.id ρ = ρ := by
  ext1
  rw [mat_coe_eq_apply_mat]
  exact id_fun_id ρ.m

/-- The map `CPTPMap.id` composed with any map is the same map. -/
@[simp]
theorem id_compose [DecidableEq dOut] (Λ : CPTPMap dIn dOut) : id.compose Λ = Λ := by
  simp only [CPTPMap.ext_iff, compose_eq, id_MState, implies_true]

/-- Any map composed with `CPTPMap.id` is the same map. -/
@[simp]
theorem compose_id (Λ : CPTPMap dIn dOut) : Λ.compose CPTPMap.id = Λ := by
  simp only [CPTPMap.ext_iff, compose_eq, id_MState, implies_true]

/-- There is a CPTP map that takes a system of any (nonzero) dimension and outputs the
trivial Hilbert space, 1-dimensional, indexed by any `Unique` type. -/
def destroy [Nonempty dIn] [Unique dOut] : CPTPMap dIn dOut :=
  CPTP_of_choi_PSD_Tr Matrix.PosSemidef.one
    (by ext i j;  simp [Matrix.trace_right, Matrix.one_apply])

/-- Two CPTP maps into the same one-dimensional output space must be equal -/
theorem eq_if_output_unique [Unique dOut] (Λ₁ Λ₂ : CPTPMap dIn dOut) : Λ₁ = Λ₂ :=
  ext fun _ ↦ (Unique.eq_default _).trans (Unique.eq_default _).symm

/-- There is exactly one CPTPMap to a 1-dimensional space. -/
instance instUnique [Nonempty dIn] [Unique dOut] : Unique (CPTPMap dIn dOut) where
  default := destroy
  uniq := fun _ ↦ eq_if_output_unique _ _

/-- A state can be viewed as a CPTP map from the trivial Hilbert space (indexed by `Unit`)
 that outputs exactly that state. -/
def const_state (ρ : MState dOut) : CPTPMap Unit dOut where
  map := MatrixMap.of_choi_matrix (Matrix.of fun (_,i) (_,j) ↦ ρ.m i j)
  trace_preserving x := by
    have := ρ.tr
    unfold Matrix.trace at this
    simpa [MatrixMap.of_choi_matrix, Matrix.trace, ← Finset.mul_sum] using this ▸ mul_one _
  completely_pos := sorry

/-- The output of `const_state ρ` is always that `ρ`. -/
@[simp]
theorem const_state_apply (ρ : MState dOut) (ρ₀ : MState Unit) : (const_state ρ) ρ₀ = ρ := by
  sorry

/--The replacement channel that maps all inputs to a given state. -/
def replacement [Nonempty dIn] (ρ : MState dOut) : CPTPMap dIn dOut :=
  (const_state ρ).compose destroy

/-- The output of `replacement ρ` is always that `ρ`. -/
@[simp]
theorem replacement_apply (ρ : MState dOut) (ρ₀ : MState Unit) : (replacement ρ) ρ₀ = ρ := by
  simp only [replacement, compose_eq, const_state_apply]

section prod
open Kronecker

variable {dI₁ dI₂ dO₁ dO₂ : Type*} [Fintype dI₁] [Fintype dI₂] [Fintype dO₁] [Fintype dO₂]
variable [DecidableEq dI₁] [DecidableEq dI₂] [DecidableEq dO₁] [DecidableEq dO₂]

/-- The tensor product of two CPTPMaps. -/
def prod (Λ₁ : CPTPMap dI₁ dO₁) (Λ₂ : CPTPMap dI₂ dO₂) : CPTPMap (dI₁ × dI₂) (dO₁ × dO₂) :=
  CPTPMap.mk
    (MatrixMap.kron Λ₁.map Λ₂.map)
    (Λ₁.trace_preserving.kron Λ₂.trace_preserving)
    (Λ₁.completely_pos.kron Λ₂.completely_pos)

notation ρL "⊗" ρR => prod ρL ρR

end prod

section finprod
section

variable {k : ℕ}
variable {dI : Fin k → Type v} [∀(i : Fin k), Fintype (dI i)] [∀(i : Fin k), DecidableEq (dI i)]
variable {dO : Fin k → Type w} [∀(i : Fin k), Fintype (dO i)] [∀(i : Fin k), DecidableEq (dO i)]

/-- Finitely-indexed tensor products of CPTPMaps, when the indices are Fin n.  -/
def fin_n_prod (Λi : (i : Fin k) → CPTPMap (dI i) (dO i)) : CPTPMap ((i:Fin k) → (dI i)) ((i:Fin k) → (dO i)) :=
  sorry

theorem fin_n_prod_1 {dI : Fin 1 → Type v} [Fintype (dI 0)] [DecidableEq (dI 0)] {dO : Fin 1 → Type w} [Fintype (dO 0)] [DecidableEq (dO 0)] (Λi : (i : Fin 1) → CPTPMap (dI 0) (dO 0)) :
    fin_n_prod Λi = CPTPMap.compose sorry ((Λi 1).compose sorry) :=
  sorry --TODO: permutations

end
section

variable {ι : Type u} [DecidableEq ι] [Fintype ι]
variable {dI : ι → Type v} [∀(i :ι), Fintype (dI i)] [∀(i :ι), DecidableEq (dI i)]
variable {dO : ι → Type w} [∀(i :ι), Fintype (dO i)] [∀(i :ι), DecidableEq (dO i)]

/-- Finitely-indexed tensor products of CPTPMaps.  -/
def fintype_prod (Λi : ι → CPTPMap (dI i) (dO i)) : CPTPMap ((i:ι) → dI i) ((i:ι) → dO i) :=
  sorry

end
end finprod

section trace
variable {d₁ d₂ : Type*} [Fintype d₁] [Fintype d₂] [DecidableEq d₁] [DecidableEq d₂]

/-- Partial tracing out the left, as a CPTP map. -/
def trace_left : CPTPMap (d₁ × d₂) d₂ :=
  sorry

/-- Partial tracing out the right, as a CPTP map. -/
def trace_right : CPTPMap (d₁ × d₂) d₁ :=
  sorry

theorem trace_left_eq_MState_trace_left (ρ : MState (d₁ × d₂)) : trace_left ρ = ρ.trace_left :=
  sorry

theorem trace_right_eq_MState_trace_right (ρ : MState (d₁ × d₂)) : trace_right ρ = ρ.trace_right :=
  sorry

end trace

section equiv
variable [DecidableEq dOut]

/-- Given a equivalence (a bijection) between the types d₁ and d₂, that is, if they're
 the same dimension, then there's a CPTP channel for this. This is what we need for
 defining e.g. the SWAP channel, which is 'unitary' but takes heterogeneous input
 and outputs types (d₁ × d₂) and (d₂ × d₁). -/
def of_equiv (σ : dIn ≃ dOut) : CPTPMap dIn dOut :=
  sorry

theorem equiv_inverse (σ : dIn ≃ dOut)  : (of_equiv σ) ∘ (of_equiv σ.symm) = id :=
  sorry

variable {d₁ d₂ d₃ : Type*} [Fintype d₁] [Fintype d₂] [Fintype d₃]
variable [DecidableEq d₁] [DecidableEq d₂] [DecidableEq d₃]

--TODO: of_equiv (id) = id
--(of_equiv σ).compose (of_equiv τ) = of_equiv (σ ∘ τ)

/-- The SWAP operation, as a channel. -/
def SWAP : CPTPMap (d₁ × d₂) (d₂ × d₁) :=
  of_equiv (Equiv.prodComm d₁ d₂)

/-- The associator, as a channel. -/
def assoc : CPTPMap ((d₁ × d₂) × d₃) (d₁ × d₂ × d₃) :=
  of_equiv (Equiv.prodAssoc d₁ d₂ d₃)

/-- The inverse associator, as a channel. -/
def assoc' : CPTPMap (d₁ × d₂ × d₃) ((d₁ × d₂) × d₃) :=
  of_equiv (Equiv.prodAssoc d₁ d₂ d₃).symm

theorem assoc_assoc' : (assoc (d₁ := d₁) (d₂ := d₂) (d₃ := d₃)).compose assoc' = id :=
  sorry

end equiv

section unitary

/-- Conjugating density matrices by a unitary as a channel, standard unitary evolution. -/
def of_unitary (U : 𝐔[dIn]) : CPTPMap dIn dIn :=
  CPTP_of_choi_PSD_Tr (M := sorry) --v v†
    (sorry)
    (sorry)

/-- The unitary channel U conjugated by U. -/
theorem of_unitary_eq_conj (U : 𝐔[dIn]) (ρ : MState dIn) :
    (of_unitary U) ρ = ρ.U_conj U :=
  sorry

/-- A channel is unitary iff it is `of_unitary U`. -/
def IsUnitary (Λ : CPTPMap dIn dIn) : Prop :=
  ∃ U, Λ = of_unitary U

/-- A channel is unitary iff it can be written as conjugation by a unitary. -/
theorem IsUnitary_iff_U_conj (Λ : CPTPMap dIn dIn) : IsUnitary Λ ↔ ∃ U, ∀ ρ, Λ ρ = ρ.U_conj U := by
  simp_rw [IsUnitary, ← of_unitary_eq_conj, CPTPMap.ext_iff]

theorem IsUnitary_equiv (σ : dIn ≃ dIn) : IsUnitary (of_equiv σ) :=
  sorry

end unitary

/-- A channel is *entanglement breaking* iff its product with the identity channel
  only outputs separable states. -/
def EntanglementBreaking (Λ : CPTPMap dIn dOut) : Prop :=
  ∀ (dR : Type u_1) [Fintype dR] [DecidableEq dR], ∀ (ρ : MState (dR × dIn)),
    ((id ⊗ Λ) ρ).IsSeparable

--TODO:
--Theorem: entanglement breaking iff it holds for all channels, not just id.
--Theorem: entanglement break iff it breaks a Bell pair (Wilde Exercise 4.6.2)
--Theorem: entanglement break if c-q or q-c, e.g. measurements
--Theorem: eb iff Kraus operators can be written as all unit rank (Wilde Theorem 4.6.1)

section purify
variable [DecidableEq dOut] [Inhabited dOut]

/-- Every channel can be written as a unitary channel on a larger system. In general, if
 the original channel was A→B, we may need to go as big as dilating the output system (the
 environment) by a factor of A*B. One way of stating this would be that it forms an
 isometry from A to (B×A×B). So that we can instead talk about the cleaner unitaries, we
 say that this is a unitary on (A×B×B). The defining properties that this is a valid
 purification comes are `purify_IsUnitary` and `purify_trace`. This means the environment
 always has type `dIn × dOut`.

 Furthermore, since we need a canonical "0" state on B in order to add with the input,
 we require a typeclass instance [Inhabited dOut]. -/
def purify (Λ : CPTPMap dIn dOut) : CPTPMap (dIn × dOut × dOut) (dIn × dOut × dOut) :=
  sorry

--TODO: Constructing this will probably need Kraus operators first.

theorem purify_IsUnitary (Λ : CPTPMap dIn dOut) : Λ.purify.IsUnitary :=
  sorry

/-- With a channel Λ : A → B, a valid purification (A×B×B)→(A×B×B) is such that:
 * Preparing the default ∣0⟩ state on two copies of B
 * Appending these to the input
 * Applying the purified unitary channel
 * Tracing out the two left parts of the output
is equivalent to the original channel. -/
theorem purify_trace (Λ : CPTPMap dIn dOut) : Λ = (
  let zero_prep : CPTPMap Unit (dOut × dOut) := const_state (MState.pure (Ket.basis default))
  let prep := (id ⊗ zero_prep)
  let append : CPTPMap dIn (dIn × Unit) := CPTPMap.of_equiv (Equiv.prodPUnit dIn).symm
  CPTPMap.trace_left.compose $ CPTPMap.trace_left.compose $ Λ.purify.compose $ prep.compose append
  ) :=
  sorry

--TODO Theorem: `purify` is unique up to unitary equivalence.

--TODO: Best to rewrite the "zero_prep / prep / append" as one CPTPMap.append channel when we
-- define that.

/-- The complementary channel comes from tracing out the other half of the purified channel. -/
def complementary (Λ : CPTPMap dIn dOut) : CPTPMap dIn (dIn × dOut) :=
  let zero_prep : CPTPMap Unit (dOut × dOut) := const_state (MState.pure (Ket.basis default))
  let prep := (id ⊗ zero_prep)
  let append : CPTPMap dIn (dIn × Unit) := CPTPMap.of_equiv (Equiv.prodPUnit dIn).symm
  CPTPMap.trace_right.compose $ CPTPMap.assoc'.compose $ Λ.purify.compose $ prep.compose append

end purify

section degradable
variable [DecidableEq dOut] [Inhabited dOut] [DecidableEq dOut₂] [Inhabited dOut₂]

/-- A channel is *degradable to* another, if the other can be written as a composition of
  a _degrading_ channel D with the original channel. -/
def IsDegradableTo (Λ : CPTPMap dIn dOut) (Λ₂ : CPTPMap dIn dOut₂) : Prop :=
  ∃ (D : CPTPMap dOut (dOut₂)), D.compose Λ = Λ₂

/-- A channel is *antidegradable to* another, if the other `IsDegradableTo` this one. -/
@[reducible]
def IsAntidegradableTo (Λ : CPTPMap dIn dOut) (Λ₂ : CPTPMap dIn dOut₂) : Prop :=
  IsDegradableTo Λ₂ Λ

/-- A channel is *degradable* if it `IsDegradableTo` its complementary channel. -/
def IsDegradable (Λ : CPTPMap dIn dOut) : Prop :=
  IsDegradableTo Λ Λ.complementary

/-- A channel is *antidegradable* if it `IsAntidegradableTo` its complementary channel. -/
@[reducible]
def IsAntidegradable (Λ : CPTPMap dIn dOut) : Prop :=
  IsAntidegradableTo Λ Λ.complementary

--Theorem (Wilde Exercise 13.5.7): Entanglement breaking channels are antidegradable.
end degradable

end
end CPTPMap
