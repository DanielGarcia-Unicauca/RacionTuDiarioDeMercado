package com.racion.diariomercado.domain.repository

import com.racion.diariomercado.core.AppResult
import com.racion.diariomercado.domain.model.FoodProduct

/**
 * Read access to the packaged-food catalog. Backed by Open Food Facts in production.
 *
 * Contract:
 * - Every method is `suspend` and returns [AppResult]; no method may throw. Transport errors are
 *   mapped to an [com.racion.diariomercado.core.AppError] by the implementation.
 * - That no-throw rule binds **implementations, not the stubs**. The bodies currently in
 *   `data/` throw `NotImplementedError` on purpose: it is an [Error], not an [Exception], so
 *   `catch (e: Exception)` around a call will not contain it. That is deliberate — an unbuilt
 *   integration must fail loudly at the call site rather than be silently swallowed into a
 *   "no connection" message. Once a real implementation lands it must honour the no-throw
 *   contract, and the stub bodies disappear with it.
 * - Reads are not observable: Open Food Facts is a remote, append-only database with no push
 *   channel, so a `Flow` here would only ever re-emit on demand.
 *
 * Rate limits (verified against the OFF docs, see `docs/INTEGRATION.md`) are the reason the
 * search method takes explicit [page]/[pageSize] instead of fetching everything: 15 req/min for
 * product reads, 10 req/min for search.
 */
interface FoodCatalogRepository {

    /**
     * Looks up a single product by its barcode.
     *
     * A barcode that Open Food Facts does not know is **not** an error at the HTTP level: the
     * API answers `200 OK` with `status = 0` and `product = null`. The implementation must map
     * that specific body to [AppResult.Failure] with [com.racion.diariomercado.core.AppError.NotFound]
     * — checking only the HTTP status would surface an empty product as a success.
     */
    suspend fun productByBarcode(barcode: String): AppResult<FoodProduct>

    /**
     * Free-text search.
     *
     * IMPORTANT: Open Food Facts **v2 does not support free-text search**. Free text only works
     * on the legacy v1 `cgi/search.pl` endpoint, which is why the implementation talks to two
     * different endpoints. See `OpenFoodFactsService.searchV1`.
     *
     * Search is limited to 10 requests per minute and is explicitly forbidden as a
     * search-as-you-type flow; callers must debounce and require an explicit submit.
     */
    suspend fun search(
        query: String,
        page: Int = 1,
        pageSize: Int = 20
    ): AppResult<List<FoodProduct>>
}
