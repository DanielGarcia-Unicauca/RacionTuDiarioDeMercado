package com.racion.diariomercado.data.openfood

import com.racion.diariomercado.core.AppResult
import com.racion.diariomercado.data.openfood.dto.OffProductDto
import com.racion.diariomercado.domain.model.FoodProduct
import com.racion.diariomercado.domain.model.Nutrition
import com.racion.diariomercado.domain.repository.FoodCatalogRepository

/**
 * [FoodCatalogRepository] backed by the Open Food Facts API.
 *
 * `internal` on purpose: nothing outside `data/` may depend on Open Food Facts. Screens talk to
 * the [FoodCatalogRepository] interface, so the backend can be swapped (or replaced with a
 * curated local catalog) without a single UI change.
 *
 * ## Constraints this implementation MUST honour
 *
 * **1. The `User-Agent` header is mandatory (OFF-1).**
 * Open Food Facts blocks generic user agents. Requests with no `User-Agent`, or with a default
 * library one, are treated as bot traffic and blocked. The header must have the shape
 * `AppName/Version (contact)`, e.g. `RacionTuDiarioDeMercado/1.0 (contact@example.com)`.
 * The value is wired in `AppContainer` from `BuildConfig.OPEN_FOOD_FACTS_USER_AGENT`.
 * Getting this wrong is not a soft failure: you get HTTP 403/503 and empty results.
 *
 * **2. Rate limits (OFF-4).**
 * 15 requests/min for product reads, 10 requests/min for search. Breaching the limit returns
 * HTTP 503, which must be mapped to [com.racion.diariomercado.core.AppError.RateLimited] and
 * not surfaced as a generic server error. Consequence: search must NOT be search-as-you-type —
 * each keystroke would burn a request against a budget shared by the whole user's session. The
 * UI must debounce and require an explicit submit.
 *
 * **3. A missing product is HTTP 200, not 404 (OFF-2).**
 * An unknown barcode returns `200 OK` with `status = 0` and `product = null`. Only the body
 * tells you the product is missing. Code that checks `response.isSuccessful` and then
 * dereferences `response.body()!!.product!!` will crash on the most common real-world case.
 */
internal class OpenFoodFactsCatalogRepository(
    private val service: OpenFoodFactsService
) : FoodCatalogRepository {

    /**
     * TODO(OFF-2): call [OpenFoodFactsService.productByBarcode], then check the body:
     * `status != 1 || product == null` -> `AppResult.Failure(AppError.NotFound)`.
     * Map `UnknownHostException`/`SocketTimeoutException` -> `AppError.Network`, HTTP 429/503 ->
     * `AppError.RateLimited`, any other non-2xx -> `AppError.Server(code, message)`, and
     * anything else -> `AppError.Unknown(it)`.
     */
    override suspend fun productByBarcode(barcode: String): AppResult<FoodProduct> =
        // TODO(OFF-2): implement. Note this throws NotImplementedError (an Error, NOT an Exception):
        // the documented "no method may throw" contract applies to REAL implementations, and callers
        // writing `catch (e: Exception)` will not catch this stub. Remove this method body entirely
        // when the implementation lands.
        throw NotImplementedError(
            "FoodCatalogRepository.productByBarcode is not implemented yet (OFF-2)"
        )

    /**
     * TODO(OFF-3): call [OpenFoodFactsService.searchV1] (v2 has no free text), map each
     * [OffProductDto] with [toFoodProduct], drop entries without a usable name, and cap the
     * result at [pageSize]. Also enforce OFF-4: this must only ever be reached from an
     * explicit submit or a debounced query, never per keystroke.
     */
    override suspend fun search(query: String, page: Int, pageSize: Int): AppResult<List<FoodProduct>> =
        // TODO(OFF-3): implement. Note this throws NotImplementedError (an Error, NOT an Exception):
        // the documented "no method may throw" contract applies to REAL implementations, and callers
        // writing `catch (e: Exception)` will not catch this stub. Remove this method body entirely
        // when the implementation lands.
        throw NotImplementedError(
            "FoodCatalogRepository.search is not implemented yet (OFF-3)"
        )

    /**
     * DTO -> domain mapping (OFF-3).
     *
     * TODO: return `null` when there is no usable product name — the catalog is
     * crowd-sourced and unnamed rows exist. Normalise [OffProductDto.nutritionGrades] to lower
     * case, split [OffProductDto.categories] on commas, and take the first brand when
     * [OffProductDto.brands] contains several.
     */
    private fun OffProductDto.toFoodProduct(): FoodProduct? =
        // TODO(OFF-3): implement. Note this throws NotImplementedError (an Error, NOT an Exception):
        // the documented "no method may throw" contract applies to REAL implementations, and callers
        // writing `catch (e: Exception)` will not catch this stub. Remove this method body entirely
        // when the implementation lands.
        throw NotImplementedError(
            "OffProductDto.toFoodProduct is not implemented yet (OFF-3)"
        )

    /**
     * TODO: map the `nutriments` sub-object into [Nutrition], rounding [Nutrition.kcal].
     * A product with no `nutriments` at all maps to `Nutrition()` rather than being dropped,
     * so the user can still log a manually-typed product.
     */
    private fun OffProductDto.toNutrition(): Nutrition =
        // TODO(OFF-3): implement. Note this throws NotImplementedError (an Error, NOT an Exception):
        // the documented "no method may throw" contract applies to REAL implementations, and callers
        // writing `catch (e: Exception)` will not catch this stub. Remove this method body entirely
        // when the implementation lands.
        throw NotImplementedError(
            "OffProductDto.toNutrition is not implemented yet (OFF-3)"
        )
}
