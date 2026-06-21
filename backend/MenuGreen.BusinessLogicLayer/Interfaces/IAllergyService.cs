using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Requests;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;

namespace MenuGreen.BusinessLogicLayer.Interfaces
{
    public interface IAllergyService
    {
        Task<IEnumerable<AllergyResponse>> GetAllAsync(Guid userId);
        Task<AllergyResponse> CreateAsync(Guid userId, AllergyUpsertRequest request);
        Task<AllergyResponse> UpdateAsync(Guid userId, Guid allergyId, AllergyUpsertRequest request);
        Task DeleteAsync(Guid userId, Guid allergyId);
        Task<IEnumerable<AllergyResponse>> UpdateProfileAsync(Guid userId, List<AllergenProfileItem> allergens);
        Task<IEnumerable<AllergyCatalogResponse>> GetCatalogAsync();
    }
}
