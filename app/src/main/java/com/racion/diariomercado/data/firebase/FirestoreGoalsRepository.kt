package com.racion.diariomercado.data.firebase

import com.racion.diariomercado.core.AppResult
import com.racion.diariomercado.domain.model.NutritionGoals
import com.racion.diariomercado.domain.repository.GoalsRepository
import kotlinx.coroutines.flow.Flow

/**
 * [GoalsRepository] backed by Cloud Firestore.
 *
 * ## Expected document layout (FF-5)
 * ```
 * users/{uid}/goals   -> { targetWeightKg, currentWeightKg, kcalPerDay,
 *                          activeDays: [string], macroSplit: { carbsPct, proteinPct, fatPct } }
 * ```
 * One document, no subcollections. `activeDays` is stored as the list of enum **names**
 * (`"MONDAY"`, ...), never the one-letter `DayOfWeek.short` labels — the labels are
 * presentation and a copy change must not invalidate stored data.
 *
 * ## Why a separate document from `profile` (FF-6)
 * The goals screen and the profile screen write independently and at very different
 * frequencies. Sharing a document means a "save goals" write can silently overwrite a newer
 * weight the user just typed on the profile, because Firestore's last-write-wins operates on
 * the whole document, not per field.
 *
 * TODO(FF-5): implement with a `DocumentReference` snapshot listener converted to a `Flow`.
 */
internal class FirestoreGoalsRepository : GoalsRepository {

    /**
     * TODO(FF-5): snap to `users/{uid}/goals` and emit [NutritionGoals]. An absent document
     * must emit `NutritionGoals()` defaults, not `null` — the screen has no empty state and
     * the type is non-nullable for that reason.
     */
    override fun observeGoals(): Flow<NutritionGoals> =
        // TODO(FF-5): implement. Note this throws NotImplementedError (an Error, NOT an Exception):
        // the documented "no method may throw" contract applies to REAL implementations, and callers
        // writing `catch (e: Exception)` will not catch this stub. Remove this method body entirely
        // when the implementation lands.
        throw NotImplementedError(
            "FirestoreGoalsRepository.observeGoals is not implemented yet (FF-5)"
        )

    /**
     * TODO(FF-5): `set` the whole document. Last-write-wins is acceptable here: the screen
     * always emits the full object it loaded, so there is no partial-overwrite hazard.
     */
    override suspend fun saveGoals(goals: NutritionGoals): AppResult<Unit> =
        // TODO(FF-5): implement. Note this throws NotImplementedError (an Error, NOT an Exception):
        // the documented "no method may throw" contract applies to REAL implementations, and callers
        // writing `catch (e: Exception)` will not catch this stub. Remove this method body entirely
        // when the implementation lands.
        throw NotImplementedError(
            "FirestoreGoalsRepository.saveGoals is not implemented yet (FF-5)"
        )
}
