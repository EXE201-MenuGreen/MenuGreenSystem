using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using MenuGreen.BusinessLogicLayer.DTOs.Responses;

namespace MenuGreen.BusinessLogicLayer.Interfaces
{
    public interface IMicroLearningService
    {
        Task<IEnumerable<MicroLearningCardResponse>> GetRecommendedCardsAsync(Guid userId);
        Task<MicroLearningCardResponse> GetCardByIdAsync(Guid id, Guid userId);
        Task<IEnumerable<MicroLearningCategoryResponse>> GetCategoriesAsync();
        Task<bool> RecordCardActionAsync(Guid userId, Guid cardId, string action);
        Task<IEnumerable<MicroLearningCardResponse>> GetSavedCardsAsync(Guid userId);
        Task<QuizSubmitResponse> SubmitQuizAnswerAsync(Guid userId, Guid cardId, int selectedOptionIndex);
    }
}
